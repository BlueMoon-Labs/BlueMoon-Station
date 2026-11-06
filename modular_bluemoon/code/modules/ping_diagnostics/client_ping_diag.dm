/client/var/datum/ping_diagnostics/ping_diag
/client/var/datum/ping_diag_ui/ping_diag_ui

/client/proc/get_ping_diag()
	RETURN_TYPE(/datum/ping_diagnostics)
	if(!ping_diag)
		ping_diag = new(ckey)
		ping_diag.byond_build_code = byond_version * 10000 + byond_build
	return ping_diag

/// Ответ на рассылку с пачкой. Номер и числа приходят от клиента: чужой номер и нечисла не пишутся.
/client/proc/ping_diag_record(rtt, stall, batch)
	if(!SSping_diag?.valid_batch(batch))
		return
	var/datum/ping_diagnostics/diag = get_ping_diag()
	var/slot = diag.record_sample(REALTIMEOFDAY, rtt, stall, batch)
	if(slot)
		SSping_diag.note_reply(diag, slot, batch)

/client/proc/ping_diag_probe(rtt, stall)
	ping_diag?.record_probe(REALTIMEOFDAY, rtt, stall, SSping_diag?.recent_shared)

/// Метрики панели нужны только нам: из payload их убираем, чтобы pingReply не гнал их обратно.
/proc/ping_payload_take_metrics(list/payload)
	if(!islist(payload))
		return null
	. = payload["metrics"]
	payload -= "metrics"

/client/verb/ping_diagnostics()
	set name = "Ping Diagnostics"
	set category = "OOC"
	set desc = "Из чего складывается ваш пинг и что с ним можно сделать"
	open_ping_diagnostics()

/client/proc/open_ping_diagnostics()
	if(!ping_diag_ui)
		ping_diag_ui = new(src)
	ping_diag_ui.ui_interact(mob)
