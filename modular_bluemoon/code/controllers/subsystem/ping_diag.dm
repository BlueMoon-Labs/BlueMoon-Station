/**
 * Диагностика пинга: закрывает рассылки пинга и делит лишнее на наше и игроков,
 * гоняет ускоренный замер для открытых окон, раз в 10 с ставит вердикты и подсказывает в чат.
 * Логи: ping-events (общие всплески, сразу), раз в минуту ping-clients, ping-host и ping-samples,
 * ping-summary перезаписью раз в минуту и на выключении.
 */
SUBSYSTEM_DEF(ping_diag)
	name = "Ping Diagnostics"
	wait = PING_DIAG_FAST_PROBE_DS
	flags = SS_BACKGROUND
	runlevels = RUNLEVEL_LOBBY | RUNLEVELS_DEFAULT
	var/batch_counter = 0
	var/list/datum/ping_batch/open_batches = list()
	/// Номера последних пачек, на которых молчали почти все: поздний ответ на них - общая доля.
	var/list/mass_batches = list()
	/// Общая доля последней закрытой пачки: ей поправляются ускоренные замеры. null - неизвестна.
	var/recent_shared
	/// Клиенты, чьё окно диагностики открыто.
	var/list/client/watched = list()
	var/list/currentrun = list()
	var/list/events = list()
	/// ckey -> TRUE: подсказка раз за раунд, даже после перезахода.
	var/list/hinted_ckeys = list()
	/// Проход вердиктов растянут на PING_DIAG_VERDICT_EVERY_DS: с какого момента идёт, сколько клиентов в нём и сколько уже пересчитано.
	var/verdict_started_at = -INFINITY
	var/verdict_total = 0
	var/verdict_done = 0
	var/next_csv_at = 0
	/// Резюмнутый фаер идёт каждый тик: ускоренный замер не чаще PING_DIAG_FAST_PROBE_DS.
	var/next_probe_at = 0
	var/server_base_median = 0
	var/server_rtt_median = 0
	var/ours_ms_total = 0
	var/yours_ms_total = 0
	var/list/verdict_tally = list()
	var/list/event_tally = list()
	/// Источник всплеска без чисел -> сколько раз.
	var/list/event_sources = list()
	var/clients_log
	var/events_log
	var/summary_path
	var/host_log
	var/samples_log
	var/datum/ping_host_net/host_net
	/// Счётчики текущей минуты для строки ping-host.
	var/minute_events = 0
	var/minute_ours_ms = 0
	var/minute_yours_ms = 0
	/// Цена самой подсистемы за минуту, мкс: последние колонки ping-host.
	var/minute_fires = 0
	var/minute_fire_us = 0
	var/minute_fire_max_us = 0
	var/minute_proc_us = 0
	var/minute_log_us = 0
	var/minute_rows_us = 0
	/// Расчёт строк по этапам, мкс, и сколько фаеров заняла минутная запись: хвост ping-host.
	var/minute_rows_slices = 0
	var/minute_rows_snapshot_us = 0
	var/minute_rows_csv_us = 0
	var/minute_rows_raw_us = 0
	var/minute_rows_lines_us = 0
	var/minute_rows_join_us = 0
	var/minute_rows_free_us = 0
	var/minute_rows_client_max_us = 0
	/// Минутная запись идёт кусками по фаерам: шаг, срез клиентов на её начало и что уже посчитано.
	var/rows_step = PING_DIAG_ROWS_IDLE
	/// Срез: по клиенту list(ckey, датум, x, y, z, mob_kind, view), z - null без турфа.
	var/list/rows_entries
	var/rows_next = 0
	/// Одна метка времени на все строки минуты.
	var/rows_stamp
	var/rows_world_time = 0
	var/rows_clients = 0
	var/rows_now = 0
	/// Сетка "людей рядом" и число клиентов по z на момент среза.
	var/list/rows_cells
	var/list/rows_z_counts
	var/list/rows_csv
	var/list/rows_raw
	/// Склеенный текст, который ждёт записи.
	var/rows_text

/datum/controller/subsystem/ping_diag/Initialize(start_timeofday)
	. = ..()
	// После Recover() логи уже открыты: шапки второй раз не пишем.
	if(!clients_log)
		var/suffix = "[GLOB.round_id || "NULL"]-[SSmapping.config?.map_name]"
		clients_log = "[GLOB.log_directory]/ping-clients-[suffix].csv"
		events_log = "[GLOB.log_directory]/ping-events-[suffix].log"
		summary_path = "[GLOB.log_directory]/ping-summary-[suffix].json"
		host_log = "[GLOB.log_directory]/ping-host-[suffix].csv"
		samples_log = "[GLOB.log_directory]/ping-samples-[suffix].log"
		WRITE_LOG_NO_FORMAT(clients_log, "[PING_DIAG_CSV_HEADER]\n")
		WRITE_LOG_NO_FORMAT(host_log, "[PING_DIAG_HOST_CSV_HEADER]\n")
	if(!host_net)
		host_net = new

/datum/controller/subsystem/ping_diag/Recover()
	batch_counter = SSping_diag.batch_counter
	hinted_ckeys = SSping_diag.hinted_ckeys
	ours_ms_total = SSping_diag.ours_ms_total
	yours_ms_total = SSping_diag.yours_ms_total
	verdict_tally = SSping_diag.verdict_tally
	event_tally = SSping_diag.event_tally
	event_sources = SSping_diag.event_sources
	events = SSping_diag.events
	mass_batches = SSping_diag.mass_batches
	watched = SSping_diag.watched
	clients_log = SSping_diag.clients_log
	events_log = SSping_diag.events_log
	summary_path = SSping_diag.summary_path
	host_log = SSping_diag.host_log
	samples_log = SSping_diag.samples_log
	host_net = SSping_diag.host_net

/datum/controller/subsystem/ping_diag/Shutdown()
	// Начатая минута дописывается целиком, её последний шаг - итог раунда.
	if(rows_step != PING_DIAG_ROWS_IDLE)
		continue_minute_rows(INFINITY)
		return
	write_summary()

/// Итог раунда перезаписью: раз в минуту и на выключении, чтобы снятый посреди игры сервер оставил итог.
/datum/controller/subsystem/ping_diag/proc/write_summary()
	if(!summary_path)
		return
	var/text = json_encode(round_summary())
	rustg_time_reset(PING_DIAG_IO_TIMER)
	rustg_file_write(text, summary_path)
	minute_log_us += rustg_time_microseconds(PING_DIAG_IO_TIMER)

/datum/controller/subsystem/ping_diag/fire(resumed)
	rustg_time_reset(PING_DIAG_FIRE_TIMER)
	run_fire(resumed)
	var/spent = rustg_time_microseconds(PING_DIAG_FIRE_TIMER)
	minute_fires++
	minute_fire_us += spent
	minute_fire_max_us = max(minute_fire_max_us, spent)

/datum/controller/subsystem/ping_diag/proc/run_fire(resumed)
	var/now = REALTIMEOFDAY
	if(probe_due(resumed))
		next_probe_at = world.time + PING_DIAG_FAST_PROBE_DS
		send_fast_probes()
	close_due_batches(now)
	if(rows_step == PING_DIAG_ROWS_IDLE && world.time >= next_csv_at)
		next_csv_at = world.time + PING_DIAG_CSV_EVERY_DS
		start_minute_rows()
	// Минутная запись и вердикты не делят один перегруженный тик.
	if(rows_step != PING_DIAG_ROWS_IDLE && !continue_minute_rows())
		return
	if(!resumed && !length(currentrun) && world.time >= verdict_started_at + PING_DIAG_VERDICT_EVERY_DS)
		start_verdict_pass()
	var/list/run = currentrun
	var/quota = verdict_quota()
	while(length(run) && verdict_done < quota)
		var/client/target = run[length(run)]
		run.len--
		verdict_done++
		if(target?.ping_diag)
			recompute_client(target, now)
		if(MC_TICK_CHECK)
			return

/// Новый проход: последние вошедшие клиенты в конце списка и пересчитываются первыми.
/datum/controller/subsystem/ping_diag/proc/start_verdict_pass()
	refresh_server_medians()
	currentrun = GLOB.clients.Copy()
	verdict_started_at = world.time
	verdict_total = length(currentrun)
	verdict_done = 0

/// Сколько клиентов прохода пора пересчитать к этому фаеру: доля прошедшего срока на шаг вперёд, весь проход - за шаг до срока.
/datum/controller/subsystem/ping_diag/proc/verdict_quota()
	var/elapsed = world.time - verdict_started_at + wait
	return min(verdict_total, CEILING(verdict_total * elapsed / PING_DIAG_VERDICT_EVERY_DS, 1))

/// Плановый фаер шлёт пробу всегда, резюмнутый идёт каждый тик - ему не чаще шага.
/datum/controller/subsystem/ping_diag/proc/probe_due(resumed)
	return !resumed || world.time >= next_probe_at

/datum/controller/subsystem/ping_diag/proc/open_batch()
	batch_counter++
	open_batches += new /datum/ping_batch(batch_counter, REALTIMEOFDAY, world.time)
	while(length(open_batches) > PING_DIAG_MAX_OPEN_BATCHES)
		close_batch(open_batches[1], REALTIMEOFDAY)
	return batch_counter

/// Номер пачки от клиента: только выданный нами.
/datum/controller/subsystem/ping_diag/proc/valid_batch(batch)
	return isnum(batch) && batch >= 1 && batch <= batch_counter && batch == round(batch, 1)

/datum/controller/subsystem/ping_diag/proc/find_batch(batch_id)
	RETURN_TYPE(/datum/ping_batch)
	for(var/i in length(open_batches) to 1 step -1)
		var/datum/ping_batch/batch = open_batches[i]
		if(batch.id == batch_id)
			return batch

/datum/controller/subsystem/ping_diag/proc/note_sent(client/target, batch_id)
	var/datum/ping_diagnostics/diag = target.get_ping_diag()
	diag.note_sent(REALTIMEOFDAY, batch_id)
	find_batch(batch_id)?.expect(diag)

/datum/controller/subsystem/ping_diag/proc/note_reply(datum/ping_diagnostics/diag, slot, batch_id, now = REALTIMEOFDAY)
	var/datum/ping_batch/batch = find_batch(batch_id)
	if(batch)
		batch.add_reply(diag, slot, now)
	else if(batch_id in mass_batches)
		diag.apply_batch_shared(slot, batch_id, diag.sample_excess[slot])

/// Пачка закрывается, когда прошёл срок и хотя бы тик: после долгого простоя ответы ещё в очереди вербов.
/datum/controller/subsystem/ping_diag/proc/close_due_batches(now)
	while(length(open_batches))
		var/datum/ping_batch/batch = open_batches[1]
		if(now - batch.opened_at < PING_DIAG_BATCH_CLOSE_DS || world.time <= batch.opened_world)
			return
		close_batch(batch, now)

/datum/controller/subsystem/ping_diag/proc/close_batch(datum/ping_batch/batch, now)
	open_batches -= batch
	recent_shared = batch.close(now)
	ours_ms_total += batch.ours_ms
	yours_ms_total += batch.yours_ms
	minute_ours_ms += batch.ours_ms
	minute_yours_ms += batch.yours_ms
	if(batch.mass_silent)
		mass_batches += batch.id
		if(length(mass_batches) > PING_DIAG_MAX_MASS_BATCHES)
			mass_batches.Cut(1, 2)
	var/list/load = batch_load(batch.opened_world, world.time)
	var/list/event = batch.detect_event(load[1], load[2], load[3])
	if(event)
		record_event(event, spike_source(batch.opened_world, world.time))

/// Нагрузка за окно пачки по кольцам SStick_spikes: максимум cpu и map_cpu (без замеров - текущие) и самый тяжёлый прогон подсистемы, % тика.
/datum/controller/subsystem/ping_diag/proc/batch_load(from_world, to_world)
	var/cpu = ping_diag_window_max(SStick_spikes?.ring_world_time, SStick_spikes?.ring_cpu, from_world, to_world)
	var/map_cpu = ping_diag_window_max(SStick_spikes?.ring_world_time, SStick_spikes?.ring_map_cpu, from_world, to_world)
	var/heavy_run = ping_diag_window_max(SStick_spikes?.heavy_time, SStick_spikes?.heavy_usage, from_world, to_world)
	return list(isnull(cpu) ? world.cpu : cpu, isnull(map_cpu) ? world.map_cpu : map_cpu, heavy_run || 0)

/datum/controller/subsystem/ping_diag/proc/record_event(list/event, source)
	event["time"] = time2text(world.timeofday, "hh:mm:ss")
	event["source"] = source
	event["world_time"] = world.time
	event["host_retrans_pct"] = host_net?.retrans_pct || 0
	minute_events++
	events += list(event)
	if(length(events) > PING_DIAG_MAX_EVENTS)
		events.Cut(1, 2)
	event_tally[event["type"]] = (event_tally[event["type"]] || 0) + 1
	var/mc_heaviest = (SStick_spikes && source == SStick_spikes.last_spike_class) ? SStick_spikes.last_spike_heaviest_name : null
	var/source_key = ping_diag_source_key(source, mc_heaviest)
	if(source_key)
		event_sources[source_key] = (event_sources[source_key] || 0) + 1
	if(events_log)
		write_log(events_log, "[ping_diag_event_line(event)]\n")

/// Запись в лог с замером: блокирующий ввод-вывод копится в minute_log_us.
/datum/controller/subsystem/ping_diag/proc/write_log(path, text)
	rustg_time_reset(PING_DIAG_IO_TIMER)
	WRITE_LOG_NO_FORMAT(path, text)
	minute_log_us += rustg_time_microseconds(PING_DIAG_IO_TIMER)

/// Что тормозило сервер, пока пачка была открыта, - по данным детектора тик-спайков.
/datum/controller/subsystem/ping_diag/proc/spike_source(from_world, to_world)
	if(!SStick_spikes)
		return "-"
	var/heaviest = ping_diag_heaviest_run(SStick_spikes.heavy_time, SStick_spikes.heavy_name, SStick_spikes.heavy_usage, from_world, to_world)
	return ping_diag_pick_source(SStick_spikes.last_spike_class, SStick_spikes.last_spike_world, heaviest, from_world, to_world)

/datum/controller/subsystem/ping_diag/proc/send_fast_probes()
	for(var/client/target as anything in watched)
		if(!target)
			watched -= target
			continue
		target.get_ping_diag().expect_probe()
		winset(target, null, ping_update_command(target.current_ping_tickstamp(), REALTIMEOFDAY, PING_DIAG_PROBE_BATCH))

/// Окно смотрит на клиента: ускоренный замер и кольцо побольше. Возвращает датум, на котором висит наблюдение.
/datum/controller/subsystem/ping_diag/proc/watch(client/target)
	var/datum/ping_diagnostics/diag = target.get_ping_diag()
	diag.watchers++
	var/list/remap = diag.grow_ring(PING_DIAG_MAX_SAMPLES)
	if(remap)
		for(var/datum/ping_batch/batch as anything in open_batches)
			batch.remap_slots(diag, remap)
	watched |= target
	return diag

/// Клиента из ускоренного замера убираем, только если он ещё в игре с тем же датумом.
/datum/controller/subsystem/ping_diag/proc/unwatch(datum/ping_diagnostics/diag)
	if(!diag)
		return
	diag.watchers = max(diag.watchers - 1, 0)
	if(diag.watchers)
		return
	var/client/target = GLOB.directory[diag.ckey]
	if(target?.ping_diag == diag)
		watched -= target

/// Из /client/Destroy: очереди подсистемы не держат ушедшего клиента.
/datum/controller/subsystem/ping_diag/proc/forget_client(client/target)
	if(!target)
		return
	currentrun -= target
	watched -= target

/datum/controller/subsystem/ping_diag/proc/warn_build_code()
	var/version = CONFIG_GET(number/client_warn_version)
	if(!version)
		return 0
	return version * 10000 + CONFIG_GET(number/client_warn_build)

/datum/controller/subsystem/ping_diag/proc/refresh_server_medians()
	var/list/bases = list()
	var/list/rtts = list()
	for(var/client/target as anything in GLOB.clients)
		var/list/summary = target?.ping_diag?.summary
		if(!summary || summary["samples"] < PING_DIAG_MIN_SAMPLES)
			continue
		bases += summary["base"]
		rtts += summary["rtt_median"]
	server_base_median = ping_diag_median(bases)
	server_rtt_median = ping_diag_median(rtts)

/datum/controller/subsystem/ping_diag/proc/recompute_client(client/target, now)
	var/datum/ping_diagnostics/diag = target.ping_diag
	var/list/verdicts = diag.recompute(now, server_base_median, warn_build_code())
	verdict_tally[verdicts[1]] = (verdict_tally[verdicts[1]] || 0) + 1
	var/hint_disabled = target.prefs?.chat_toggles & CHAT_NO_PING_HINT
	if(!diag.hint_due(now, hint_disabled, hinted_ckeys[target.ckey]))
		return
	hinted_ckeys[target.ckey] = TRUE
	var/text = ping_diag_hint_text(verdicts[1])
	to_chat(target, span_notice("Похоже, [text]. <a href='byond://winset?command=Ping-Diagnostics'>Подробнее</a>"))

/// Доля клиентов с медианой RTT ниже заданной, 0..100.
/datum/controller/subsystem/ping_diag/proc/rtt_percentile_of(rtt)
	var/total = 0
	var/below = 0
	for(var/client/target as anything in GLOB.clients)
		var/list/summary = target?.ping_diag?.summary
		if(!summary || summary["samples"] < PING_DIAG_MIN_SAMPLES)
			continue
		total++
		if(summary["rtt_median"] < rtt)
			below++
	return total ? round(below / total * 100, 1) : 0

/// Сколько клиентов с замерами за окно: от них считаются медианы и доля ниже.
/datum/controller/subsystem/ping_diag/proc/clients_with_data()
	. = 0
	for(var/client/target as anything in GLOB.clients)
		var/list/summary = target?.ping_diag?.summary
		if(summary && summary["samples"] >= PING_DIAG_MIN_SAMPLES)
			.++

/datum/controller/subsystem/ping_diag/proc/client_rows()
	. = list()
	for(var/client/target as anything in GLOB.clients)
		var/datum/ping_diagnostics/diag = target?.ping_diag
		if(diag)
			. += list(ping_diag_client_row(target.ckey, diag.summary, diag.verdicts[1]))

/datum/controller/subsystem/ping_diag/proc/round_summary()
	var/total = ours_ms_total + yours_ms_total
	return list(
		"round" = GLOB.round_id,
		"ours_ms" = round(ours_ms_total, 1),
		"yours_ms" = round(yours_ms_total, 1),
		"ours_fraction" = total ? round(ours_ms_total / total, 0.01) : 0,
		"verdicts" = verdict_tally,
		"events" = event_tally,
		"event_sources" = event_sources,
		"server_base_median" = round(server_base_median, 1),
		"server_rtt_median" = round(server_rtt_median, 1),
	)

/// Начало минутной записи: срез клиентов, метка времени и сетка соседей - одним куском, дальше строки по одному клиенту.
/datum/controller/subsystem/ping_diag/proc/start_minute_rows(list/clients = GLOB.clients)
	if(!clients_log)
		rows_step = PING_DIAG_ROWS_WRITE_SUMMARY
		return
	rows_step = PING_DIAG_ROWS_CLIENTS
	rustg_time_reset(PING_DIAG_ROWS_TIMER)
	rows_now = REALTIMEOFDAY
	rows_stamp = time2text(world.timeofday, "hh:mm:ss")
	rows_world_time = world.time
	rows_clients = length(clients)
	rows_entries = list()
	rows_cells = list()
	rows_z_counts = list()
	rows_csv = list()
	rows_raw = list()
	rows_next = 1
	for(var/client/target as anything in clients)
		var/turf/where = get_turf(target?.mob)
		if(where)
			var/z_key = "[where.z]"
			rows_z_counts[z_key] = (rows_z_counts[z_key] || 0) + 1
			ping_diag_grid_add(rows_cells, where.x, where.y, where.z, PING_DIAG_NEAR_RANGE)
		var/datum/ping_diagnostics/diag = target?.ping_diag
		if(!diag || !diag.summary["samples"])
			continue
		rows_entries += list(list(target.ckey, diag, where?.x, where?.y, where?.z, ping_diag_mob_kind(target.mob), target.view))
	var/spent = rustg_time_microseconds(PING_DIAG_ROWS_TIMER)
	minute_rows_snapshot_us += spent
	minute_rows_us += spent

/// Шаги минутной записи, пока фаер не потратил budget_ms или не кончился тик. TRUE - запись закончена.
/datum/controller/subsystem/ping_diag/proc/continue_minute_rows(budget_ms = PING_DIAG_ROWS_SLICE_MS)
	minute_rows_slices++
	while(rows_step != PING_DIAG_ROWS_IDLE)
		minute_rows_step()
		if(rows_step != PING_DIAG_ROWS_IDLE && rows_yield(budget_ms))
			return FALSE
	return TRUE

/datum/controller/subsystem/ping_diag/proc/rows_yield(budget_ms)
	if(budget_ms == INFINITY)
		return FALSE
	if(rustg_time_microseconds(PING_DIAG_FIRE_TIMER) >= budget_ms * 1000)
		pause()
		return TRUE
	return MC_TICK_CHECK

/datum/controller/subsystem/ping_diag/proc/minute_rows_step()
	switch(rows_step)
		if(PING_DIAG_ROWS_CLIENTS)
			if(rows_next <= length(rows_entries))
				minute_client_row(rows_entries[rows_next])
				rows_next++
				return
			rows_text = rows_join(rows_csv)
			rows_step = PING_DIAG_ROWS_WRITE_CLIENTS
		if(PING_DIAG_ROWS_WRITE_CLIENTS)
			if(rows_text)
				write_log(clients_log, rows_text)
			rows_free(TRUE)
			rows_step = PING_DIAG_ROWS_WRITE_SAMPLES
		if(PING_DIAG_ROWS_WRITE_SAMPLES)
			rows_text = rows_join(rows_raw)
			if(rows_text && samples_log)
				write_log(samples_log, rows_text)
			rows_free(FALSE)
			rows_step = PING_DIAG_ROWS_WRITE_SUMMARY
		if(PING_DIAG_ROWS_WRITE_SUMMARY)
			write_summary()
			rows_step = clients_log ? PING_DIAG_ROWS_WRITE_HOST : PING_DIAG_ROWS_IDLE
		if(PING_DIAG_ROWS_WRITE_HOST)
			write_host_row(rows_stamp, rows_now, rows_world_time, rows_clients)
			rows_entries = null
			rows_cells = null
			rows_z_counts = null
			rows_step = PING_DIAG_ROWS_IDLE
		else
			rows_step = PING_DIAG_ROWS_IDLE

/// Строка ping-clients и сырые замеры одного клиента из среза. Время и соседи - на момент среза.
/datum/controller/subsystem/ping_diag/proc/minute_client_row(list/entry)
	rustg_time_reset(PING_DIAG_ROWS_TIMER)
	var/datum/ping_diagnostics/diag = entry[2]
	var/z = entry[5]
	var/list/context = list(
		"mob_kind" = entry[6],
		"view" = entry[7],
		"z_clients" = z ? rows_z_counts["[z]"] : 0,
		"near_clients" = z ? ping_diag_grid_near(rows_cells, entry[3], entry[4], z, PING_DIAG_NEAR_RANGE) - 1 : 0,
	)
	rows_csv += ping_diag_csv_row(rows_stamp, rows_world_time, entry[1], diag.summary, diag.verdicts[1], context)
	var/csv_done = rustg_time_microseconds(PING_DIAG_ROWS_TIMER)
	var/list/raw = diag.raw_since(rows_now, diag.raw_dumped_until)
	var/raw_done = rustg_time_microseconds(PING_DIAG_ROWS_TIMER)
	if(length(raw["text"]))
		rows_raw += "wt=[num2text(rows_world_time, 10)] ckey=[entry[1]] t0=[num2text(raw["t0"], 10)] s=[raw["text"]]"
		diag.raw_dumped_until = raw["last"]
	var/spent = rustg_time_microseconds(PING_DIAG_ROWS_TIMER)
	minute_rows_csv_us += csv_done
	minute_rows_raw_us += raw_done - csv_done
	minute_rows_lines_us += spent - raw_done
	minute_rows_client_max_us = max(minute_rows_client_max_us, spent)
	minute_rows_us += spent

/datum/controller/subsystem/ping_diag/proc/rows_join(list/lines)
	rustg_time_reset(PING_DIAG_ROWS_TIMER)
	. = length(lines) ? "[lines.Join("\n")]\n" : null
	var/spent = rustg_time_microseconds(PING_DIAG_ROWS_TIMER)
	minute_rows_join_us += spent
	minute_rows_us += spent

/// Записанный текст отпускается под замером: большой блок памяти - кандидат в редкие стопоры минутной записи.
/datum/controller/subsystem/ping_diag/proc/rows_free(csv)
	rustg_time_reset(PING_DIAG_ROWS_TIMER)
	rows_text = null
	if(csv)
		rows_csv = null
	else
		rows_raw = null
	minute_rows_free_us += rustg_time_microseconds(PING_DIAG_ROWS_TIMER)

/datum/controller/subsystem/ping_diag/proc/write_host_row(stamp, now, row_world_time = world.time, clients = length(GLOB.clients))
	var/total = minute_ours_ms + minute_yours_ms
	var/ours_fraction = total ? round(minute_ours_ms / total, 0.01) : 0
	rustg_time_reset(PING_DIAG_IO_TIMER)
	var/sampled = host_net?.sample(now) && host_net.rated
	minute_proc_us += rustg_time_microseconds(PING_DIAG_IO_TIMER)
	var/list/cells = list(
		stamp,
		num2text(row_world_time, 10),
		clients,
		sampled ? num2text(host_net.tx_kbps, 10) : "",
		sampled ? num2text(host_net.rx_kbps, 10) : "",
		sampled ? host_net.retrans_per_min : "",
		sampled ? host_net.retrans_pct : "",
		minute_events,
		ours_fraction,
		minute_fires,
		ping_diag_us_to_ms(minute_fire_us),
		ping_diag_us_to_ms(minute_fire_max_us),
		ping_diag_us_to_ms(minute_proc_us),
		ping_diag_us_to_ms(minute_log_us),
		ping_diag_us_to_ms(minute_rows_us),
		minute_rows_slices,
		ping_diag_us_to_ms(minute_rows_snapshot_us),
		ping_diag_us_to_ms(minute_rows_csv_us),
		ping_diag_us_to_ms(minute_rows_raw_us),
		ping_diag_us_to_ms(minute_rows_lines_us),
		ping_diag_us_to_ms(minute_rows_join_us),
		ping_diag_us_to_ms(minute_rows_free_us),
		ping_diag_us_to_ms(minute_rows_client_max_us),
	)
	minute_events = 0
	minute_ours_ms = 0
	minute_yours_ms = 0
	var/static/list/minute_costs = list("minute_fires", "minute_fire_us", "minute_fire_max_us", "minute_proc_us", "minute_log_us", "minute_rows_us", "minute_rows_slices", "minute_rows_snapshot_us", "minute_rows_csv_us", "minute_rows_raw_us", "minute_rows_lines_us", "minute_rows_join_us", "minute_rows_free_us", "minute_rows_client_max_us")
	for(var/name in minute_costs)
		vars[name] = 0
	. = cells.Join(",")
	// Запись этой строки и текущий фаер уходят в цену следующей минуты.
	if(host_log)
		write_log(host_log, "[.]\n")
