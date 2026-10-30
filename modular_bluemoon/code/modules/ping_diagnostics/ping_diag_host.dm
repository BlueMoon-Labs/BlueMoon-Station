/// TCP-счётчики хоста из /proc/net/snmp или null.
/proc/ping_diag_parse_snmp(text)
	var/list/lines = splittext(text, "\n")
	for(var/i in 1 to length(lines) - 1)
		if(copytext(lines[i], 1, 5) != "Tcp:" || copytext(lines[i + 1], 1, 5) != "Tcp:")
			continue
		var/list/names = splittext(lines[i], " ")
		var/list/values = splittext(lines[i + 1], " ")
		var/out_index = names.Find("OutSegs")
		var/retrans_index = names.Find("RetransSegs")
		if(!out_index || !retrans_index || length(values) < max(out_index, retrans_index))
			return null
		return list("out" = text2num(values[out_index]), "retrans" = text2num(values[retrans_index]))
	return null

/// Байты физических интерфейсов из /proc/net/dev или null. lo и мосты контейнеров дублируют трафик.
/proc/ping_diag_parse_netdev(text)
	var/static/regex/virtual_name = regex(@"^(lo$|docker|veth|br-|virbr)")
	var/rx = 0
	var/tx = 0
	var/found = FALSE
	for(var/line in splittext(text, "\n"))
		var/colon = findtext(line, ":")
		if(!colon)
			continue
		var/name = trim(copytext(line, 1, colon))
		if(!length(name) || findtext(name, "|") || virtual_name.Find(name))
			continue
		var/list/fields = splittext(trim(copytext(line, colon + 1)), regex(@"\s+"))
		if(length(fields) < 9)
			continue
		rx += text2num(fields[1])
		tx += text2num(fields[9])
		found = TRUE
	return found ? list("rx" = rx, "tx" = tx) : null

/**
 * Сеть хоста по минутам: сколько отдали и сколько TCP-сегментов пришлось повторить.
 * Счётчики общие на хост, соседние процессы в них тоже.
 */
/datum/ping_host_net
	var/available
	var/list/last_snmp
	var/list/last_dev
	var/last_at = 0
	var/tx_kbps = 0
	var/rx_kbps = 0
	var/retrans_per_min = 0
	var/retrans_pct = 0
	/// Скорости посчитаны хотя бы раз: по одному замеру их нет.
	var/rated = FALSE

/datum/ping_host_net/proc/sample(now)
	if(isnull(available))
		available = world.system_type == UNIX && rustg_file_exists("/proc/net/snmp") && rustg_file_exists("/proc/net/dev")
	if(!available)
		return FALSE
	return update(now, ping_diag_parse_snmp(rustg_file_read("/proc/net/snmp")), ping_diag_parse_netdev(rustg_file_read("/proc/net/dev")))

/// Первый замер только запоминает счётчики: скорость по одному замеру не считается.
/datum/ping_host_net/proc/update(now, list/snmp, list/dev)
	if(!snmp || !dev)
		return FALSE
	if(last_snmp && now > last_at)
		var/seconds = (now - last_at) / 10
		tx_kbps = round(max(dev["tx"] - last_dev["tx"], 0) * 8 / 1000 / seconds, 0.1)
		rx_kbps = round(max(dev["rx"] - last_dev["rx"], 0) * 8 / 1000 / seconds, 0.1)
		var/out_delta = max(snmp["out"] - last_snmp["out"], 0)
		var/retrans_delta = max(snmp["retrans"] - last_snmp["retrans"], 0)
		retrans_per_min = round(retrans_delta / (seconds / 60), 0.1)
		retrans_pct = out_delta ? round(retrans_delta / out_delta * 100, 0.01) : 0
		rated = TRUE
	last_snmp = snmp
	last_dev = dev
	last_at = now
	return TRUE
