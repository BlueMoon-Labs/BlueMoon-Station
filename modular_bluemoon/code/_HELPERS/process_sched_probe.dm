/**
 * Счётчики планировщика и хоста из /proc для блока тик-спайка.
 *
 * "Внешний столл" значит лишь, что DM в тике не работал. Изнутри BYOND не отличить:
 * процесс не получал процессор (соседи по хосту, steal, лимит cgroup), главный поток был
 * занят работой движка вне проков (её не видит world.cpu) или стоял в ожидании (диск,
 * подкачка, блокировка). Ядро считает всё это отдельно, и разность двух снимков вокруг
 * столла называет вариант.
 *
 * Счётчики накопительные и уходят за 2^24, где число DM теряет точность, поэтому хранятся
 * только младшие SCHED_PROBE_COUNTER_DIGITS цифр: разность двух снимков в окне спайка
 * много меньше модуля, и перенос через ноль восстанавливается однозначно.
 */

#define SCHED_PROBE_COUNTER_DIGITS 6
#define SCHED_PROBE_COUNTER_MOD 1000000
/// Доля дрифта, начиная с которой величина объявляется причиной столла
#define SCHED_PROBE_CAUSE_SHARE 0.4

/// Младшие цифры первого числа в тексте. drop_digits отбрасывает единицы измерения (нс -> мс = 6).
/proc/proc_counter_low(text, drop_digits = 0)
	if(!istext(text))
		return null
	var/digits = ""
	for(var/index in 1 to length(text))
		var/code = text2ascii(text, index)
		if(code >= 48 && code <= 57)
			digits += ascii2text(code)
		else if(length(digits))
			break
	if(!length(digits))
		return null
	if(drop_digits)
		if(length(digits) <= drop_digits)
			return 0
		digits = copytext(digits, 1, length(digits) - drop_digits + 1)
	if(length(digits) > SCHED_PROBE_COUNTER_DIGITS)
		digits = copytext(digits, length(digits) - SCHED_PROBE_COUNTER_DIGITS + 1)
	return text2num(digits)

/// Разность двух младших частей счётчика с учётом переноса через ноль.
/proc/proc_counter_delta(before, after)
	if(isnull(before) || isnull(after))
		return null
	var/delta = after - before
	if(delta < 0)
		delta += SCHED_PROBE_COUNTER_MOD
	return delta

/// Значение строки "ключ<разделитель>число" (status, cpu.stat), младшими цифрами.
/proc/proc_key_counter(text, key, drop_digits = 0)
	if(!istext(text))
		return null
	var/start = 0
	if(findtext(text, "[key]:") == 1 || findtext(text, "[key] ") == 1)
		start = 1
	else
		start = findtext(text, "\n[key]:") || findtext(text, "\n[key] ")
		if(start)
			start++
	if(!start)
		return null
	var/line_end = findtext(text, "\n", start)
	var/line = copytext(text, start + length(key), line_end || 0)
	return proc_counter_low(line, drop_digits)

/// /proc/self/stat: CPU всех потоков процесса (тики 1/100 с), page faults, блочный I/O.
/proc/parse_proc_self_stat(text)
	if(!istext(text))
		return null
	var/comm_end = findlasttext(text, ")")
	if(!comm_end)
		return null
	var/list/fields = splittext(trim(copytext(text, comm_end + 1)), " ")
	// fields[1] - поле 3 (state) из man proc, поле N лежит в fields[N - 2]
	if(length(fields) < 18)
		return null
	return list(
		"minflt" = proc_counter_low(fields[8]),
		"majflt" = proc_counter_low(fields[10]),
		"utime" = proc_counter_low(fields[12]),
		"stime" = proc_counter_low(fields[13]),
		"threads" = text2num(fields[18]),
		"blkio" = length(fields) >= 40 ? proc_counter_low(fields[40]) : null,
	)

/// /proc/self/schedstat главного потока: время на CPU и в очереди (нс -> мс), число срезов.
/proc/parse_proc_schedstat(text)
	if(!istext(text))
		return null
	var/list/fields = splittext(trim(text), " ")
	if(length(fields) < 3)
		return null
	return list(
		"run_ms" = proc_counter_low(fields[1], 6),
		"wait_ms" = proc_counter_low(fields[2], 6),
		"slices" = proc_counter_low(fields[3]),
	)

/// Первая строка /proc/stat (сумма по всем CPU, тики 1/100 с) и число CPU.
/proc/parse_proc_stat_cpu(text)
	if(!istext(text) || findtext(text, "cpu ") != 1)
		return null
	var/line_end = findtext(text, "\n")
	var/static/regex/spaces = regex(" +")
	var/list/fields = splittext(trim(copytext(text, 5, line_end || 0)), spaces)
	if(length(fields) < 8)
		return null
	var/total = 0
	for(var/index in 1 to 8)
		total += proc_counter_low(fields[index])
	var/cpus = 0
	var/position = line_end
	while(position)
		position = findtext(text, "\ncpu", position)
		if(position)
			cpus++
			position++
	return list(
		"total" = total % SCHED_PROBE_COUNTER_MOD,
		"idle" = proc_counter_low(fields[4]),
		"iowait" = proc_counter_low(fields[5]),
		"steal" = proc_counter_low(fields[8]),
		"cpus" = cpus,
	)

/// /proc/pressure/*: накопленные total= строк some и full (мкс -> мс).
/proc/parse_proc_pressure(text)
	if(!istext(text))
		return null
	var/list/result = list()
	for(var/kind in list("some", "full"))
		var/start = findtext(text, kind)
		if(!start)
			continue
		var/total_at = findtext(text, "total=", start)
		var/line_end = findtext(text, "\n", start)
		if(!total_at || (line_end && total_at > line_end))
			continue
		result[kind] = proc_counter_low(copytext(text, total_at + 6, line_end || 0), 3)
	return length(result) ? result : null

/// cpu.stat cgroup: троттлинг. v2 считает в мкс (throttled_usec), v1 - в нс (throttled_time).
/proc/parse_cgroup_cpu_stat(text)
	if(!istext(text))
		return null
	var/throttled_ms = proc_key_counter(text, "throttled_usec", 3)
	if(isnull(throttled_ms))
		throttled_ms = proc_key_counter(text, "throttled_time", 6)
	var/throttled_count = proc_key_counter(text, "nr_throttled")
	if(isnull(throttled_ms) && isnull(throttled_count))
		return null
	return list("throttled_ms" = throttled_ms, "throttled_n" = throttled_count)

/// Кандидаты пути к cpu.stat своей cgroup: из /proc/self/cgroup, затем корни иерархий (так видно изнутри контейнера).
/proc/sched_probe_cgroup_candidates(cgroup_text)
	var/list/candidates = list()
	if(istext(cgroup_text))
		for(var/line in splittext(cgroup_text, "\n"))
			var/list/parts = splittext(line, ":")
			if(length(parts) < 3)
				continue
			var/relative = parts[3] == "/" ? "" : parts[3]
			if(parts[1] == "0" && parts[2] == "")
				candidates += "/sys/fs/cgroup[relative]/cpu.stat"
			else if(findtext(parts[2], "cpu"))
				candidates += "/sys/fs/cgroup/[parts[2]][relative]/cpu.stat"
	candidates += list("/sys/fs/cgroup/cpu.stat", "/sys/fs/cgroup/cpu,cpuacct/cpu.stat", "/sys/fs/cgroup/cpu/cpu.stat")
	return candidates

/**
 * Снимок всех счётчиков. Не Linux или /proc не читается - null, и тогда в блок спайка
 * ничего не пишется. Пути проверяются один раз за раунд: отсутствующий файл больше не трогаем.
 */
/proc/read_sched_probe(now_ms)
	var/static/list/available
	if(isnull(available))
		available = list()
		if(world.system_type == UNIX)
			for(var/path in list("/proc/self/stat", "/proc/self/schedstat", "/proc/self/status", "/proc/stat", "/proc/pressure/cpu", "/proc/pressure/io", "/proc/pressure/memory"))
				if(rustg_file_exists(path))
					available[path] = TRUE
			var/cgroup_text = rustg_file_exists("/proc/self/cgroup") ? rustg_file_read("/proc/self/cgroup") : null
			for(var/path in sched_probe_cgroup_candidates(cgroup_text))
				if(rustg_file_exists(path))
					available["cgroup"] = path
					break
	if(!available["/proc/self/stat"])
		return null
	var/list/self_stat = parse_proc_self_stat(rustg_file_read("/proc/self/stat"))
	if(!self_stat)
		return null
	var/list/snapshot = list("ms" = now_ms) + self_stat
	if(available["/proc/self/schedstat"])
		var/list/schedstat = parse_proc_schedstat(rustg_file_read("/proc/self/schedstat"))
		if(schedstat)
			snapshot += schedstat
	if(available["/proc/self/status"])
		var/status_text = rustg_file_read("/proc/self/status")
		snapshot["voluntary"] = proc_key_counter(status_text, "voluntary_ctxt_switches")
		snapshot["involuntary"] = proc_key_counter(status_text, "nonvoluntary_ctxt_switches")
	if(available["/proc/stat"])
		var/list/host = parse_proc_stat_cpu(rustg_file_read("/proc/stat"))
		for(var/key in host)
			snapshot["host_[key]"] = host[key]
	for(var/kind in list("cpu", "io", "memory"))
		if(!available["/proc/pressure/[kind]"])
			continue
		var/list/pressure = parse_proc_pressure(rustg_file_read("/proc/pressure/[kind]"))
		for(var/key in pressure)
			snapshot["psi_[kind]_[key]"] = pressure[key]
	if(available["cgroup"])
		var/list/cgroup = parse_cgroup_cpu_stat(rustg_file_read(available["cgroup"]))
		for(var/key in cgroup)
			snapshot["cg_[key]"] = cgroup[key]
	return snapshot

/// Разности всех общих ключей двух снимков; "ms" - длина окна по часам детектора.
/proc/sched_probe_delta(list/before, list/after)
	if(!before || !after)
		return null
	var/list/delta = list("ms" = after["ms"] - before["ms"])
	for(var/key in after)
		if(key == "ms" || key == "threads" || key == "host_cpus")
			continue
		var/value = proc_counter_delta(before[key], after[key])
		if(!isnull(value))
			delta[key] = value
	delta["threads"] = after["threads"]
	delta["host_cpus"] = after["host_cpus"]
	return delta

/// Сколько счётчика пришлось на столл: из окна вычитается фоновая скорость предыдущего спокойного окна.
/proc/sched_probe_excess(list/delta, list/background, key, calm_ms)
	if(isnull(delta[key]))
		return null
	var/expected = 0
	if(background && background["ms"] > 0 && !isnull(background[key]))
		expected = background[key] / background["ms"] * calm_ms
	return delta[key] - expected

/// Доля счётчика /proc/stat от всего процессорного времени хоста за окно, в процентах.
/proc/sched_probe_host_share(list/delta, key)
	if(!delta["host_total"] || isnull(delta[key]))
		return null
	return round(delta[key] / delta["host_total"] * 100, 0.1)

/// Что делал главный поток во время столла. Окно от прошлого снимка шире столла, поэтому фон вычитается.
/proc/sched_probe_verdict(list/delta, drift_ms, list/background)
	if(!delta || drift_ms <= 0)
		return null
	var/calm_ms = max(delta["ms"] - drift_ms, 0)
	var/run_excess = sched_probe_excess(delta, background, "run_ms", calm_ms)
	var/wait_excess = sched_probe_excess(delta, background, "wait_ms", calm_ms)
	var/threshold = drift_ms * SCHED_PROBE_CAUSE_SHARE
	if(delta["cg_throttled_ms"] >= threshold)
		return "лимит CPU контейнера: cgroup троттлила процесс [delta["cg_throttled_ms"]]мс"
	if(!isnull(wait_excess) && wait_excess >= threshold)
		var/steal_note = sched_probe_host_share(delta, "host_steal") >= 5 ? ", на хосте steal - процессор забирал гипервизор" : ", процессор занимали соседи по хосту"
		return "главный поток был готов работать, но ~[round(wait_excess)]мс ждал процессор в очереди планировщика[steal_note]"
	if(!isnull(run_excess) && run_excess >= threshold)
		return "главный поток ~[round(run_excess)]мс был на процессоре: BYOND работал вне DM-проков (world.cpu этого не видит)"
	if(delta["majflt"] > 0 && (delta["psi_memory_some"] >= threshold || delta["blkio"] * 10 >= threshold))
		return "главный поток ждал подкачку страниц с диска (major faults +[delta["majflt"]])"
	if(delta["blkio"] * 10 >= threshold || delta["psi_io_some"] >= threshold)
		return "главный поток ждал диск (блочный I/O)"
	if(isnull(run_excess))
		return null
	return "главный поток не был ни на процессоре, ни в очереди: спал или ждал (сеть, блокировка, сон самого BYOND)"

/// Строки блока спайка. Пустой список - сравнивать нечего (Windows, первый снимок).
/proc/sched_probe_lines(list/delta, drift_ms, list/background)
	var/list/lines = list()
	if(!delta)
		return lines
	var/list/process_parts = list()
	if(!isnull(delta["run_ms"]))
		var/background_note = (background && background["ms"] > 0 && !isnull(background["run_ms"])) ? " (фон [round(background["run_ms"] / background["ms"] * 100)]%)" : ""
		process_parts += "главный поток на CPU +[delta["run_ms"]]мс[background_note], в очереди планировщика +[delta["wait_ms"]]мс, срезов +[delta["slices"]]"
	process_parts += "CPU всех [delta["threads"]] потоков +[(delta["utime"] + delta["stime"]) * 10]мс"
	if(!isnull(delta["voluntary"]))
		process_parts += "переключения добровольные +[delta["voluntary"]], принудительные +[delta["involuntary"]]"
	process_parts += "page faults major +[delta["majflt"]], minor +[delta["minflt"]]"
	if(!isnull(delta["blkio"]))
		process_parts += "ожидание блочного I/O +[delta["blkio"] * 10]мс"
	lines += "процесс (/proc) за [delta["ms"]]мс от прошлого снимка (в них столл [round(drift_ms)]мс): [process_parts.Join("; ")]"
	var/list/host_parts = list()
	if(delta["host_total"])
		host_parts += "CPU [delta["host_cpus"]] шт, steal [sched_probe_host_share(delta, "host_steal")]%, iowait [sched_probe_host_share(delta, "host_iowait")]%, простой [sched_probe_host_share(delta, "host_idle")]%"
	var/list/pressure_parts = list()
	for(var/kind in list("cpu", "io", "memory"))
		if(isnull(delta["psi_[kind]_some"]))
			continue
		var/full_note = isnull(delta["psi_[kind]_full"]) ? "" : "/full +[delta["psi_[kind]_full"]]"
		pressure_parts += "[kind] some +[delta["psi_[kind]_some"]][full_note]мс"
	if(length(pressure_parts))
		host_parts += "PSI [pressure_parts.Join(", ")]"
	if(!isnull(delta["cg_throttled_ms"]) || !isnull(delta["cg_throttled_n"]))
		host_parts += "cgroup троттлинг +[delta["cg_throttled_ms"] || 0]мс (+[delta["cg_throttled_n"] || 0] раз)"
	if(length(host_parts))
		lines += "хост (/proc) за то же окно: [host_parts.Join("; ")]"
	var/verdict = sched_probe_verdict(delta, drift_ms, background)
	if(verdict)
		lines += "вывод по /proc: [verdict]"
	return lines

#undef SCHED_PROBE_COUNTER_DIGITS
#undef SCHED_PROBE_COUNTER_MOD
#undef SCHED_PROBE_CAUSE_SHARE
