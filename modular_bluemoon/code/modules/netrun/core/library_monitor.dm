/// Окно живёт в штатном SStgui; monitor не удерживает клиентов, callbacks или игровые объекты.
/client/proc/show_netrun_library_monitor()
	set category = "Debug.1) Logs"
	set name = "NETRUN Library Monitor"
	set desc = "Monitor NETRUN Host, bridge, queues and processing progress."
	if(check_rights(R_DEBUG))
		SSnetrun.ui_interact(mob)

/datum/controller/subsystem/netrun/ui_state(mob/user)
	return GLOB.debug_state

/datum/controller/subsystem/netrun/ui_interact(mob/user, datum/tgui/ui)
	if(!check_rights_for(user?.client, R_DEBUG))
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "NetrunMonitor", "NETRUN Library Monitor")
		ui.open()

/datum/controller/subsystem/netrun/ui_data(mob/user)
	return library_monitor_snapshot()

/// Разрешённые поля телеметрии копируются по значению; неизвестный payload не сохраняется.
/datum/netrun_external_core
	var/monitoring_negotiated = FALSE
	var/monitor_sample_sequence = "0"
	var/last_host_monitor_at
	var/last_host_response_at
	var/list/host_metrics = list()
	/// Две минуты скалярной истории с периодом две секунды, независимо от числа открытых UI.
	var/list/library_monitor_history = list()
	var/monitor_last_sample_at
	var/monitor_last_sent_bytes = 0
	var/monitor_last_received_bytes = 0
	var/monitor_connections = 0
	var/monitor_disconnects = 0
	var/monitor_last_failure

/// Отдельная clock seam позволяет проверить stale/rates без sleep или настоящей библиотеки.
/datum/netrun_external_core/proc/monitor_now()
	return world.timeofday

/datum/netrun_external_core/proc/monitor_age(start)
	if(isnull(start))
		return null
	var/elapsed = monitor_now() - start
	return max(0, elapsed < 0 ? elapsed + 864000 : elapsed) / (1 SECONDS)

/// Не меняет causal counters: diagnostic heartbeat не является application output или ACK.
/datum/netrun_external_core/proc/process_monitor_frame(list/frame)
	if(!monitoring_negotiated || !engine_epoch || state == "closed" || state == "resync_required" || frame["world_epoch"] != world_epoch || frame["engine_epoch"] != engine_epoch || frame["binding_epoch"] != binding_epoch)
		return abort_session("monitor_epoch_mismatch")
	var/sequence = frame["sample_sequence"]
	if(!netrun_external_valid_decimal(sequence))
		return abort_session("invalid_monitor_sequence")
	if(netrun_external_decimal_compare(sequence, monitor_sample_sequence) <= 0)
		return TRUE
	var/list/metrics = frame["host_metrics"]
	if(!islist(metrics) || !istext(metrics["sync_state"]) || !netrun_external_valid_decimal(metrics["applied_sequence"], TRUE) || !isnum(metrics["uptime_ms"]) || !update_host_metrics(metrics))
		return abort_session("invalid_monitor_metrics")
	monitor_sample_sequence = sequence
	last_host_monitor_at = monitor_now()
	last_host_response_at = last_host_monitor_at
	return TRUE

/// Один whitelist для opportunistic output metrics и независимого idle heartbeat.
/datum/netrun_external_core/proc/update_host_metrics(list/metrics)
	if(!islist(metrics))
		return FALSE
	var/static/list/numeric_keys = list("apply_us", "pump_us", "max_apply_us", "max_pump_us", "processing_us", "max_processing_us", "received_messages", "push_outputs", "coalesced_fact_frames", "input_unacked", "output_unacked", "node_count", "service_count", "sector_count", "active_requests", "active_discovery", "active_projections", "pending_events", "output_journal_frames", "output_journal_bytes", "input_queue_frames", "input_queue_bytes", "output_queue_frames", "output_queue_bytes", "managed_bytes", "working_set_bytes", "process_cpu_ms", "uptime_ms", "gc_gen0", "gc_gen1", "gc_gen2", "simulation_time_ds")
	var/static/list/counter_keys = list("applied_sequence", "graph_version", "graph_input_sequence")
	var/static/list/code_keys = list("sync_state", "topology_error", "communication_error")
	var/list/accepted = list()
	for(var/key in numeric_keys)
		if(!(key in metrics))
			continue
		var/value = metrics[key]
		if(isnull(value))
			accepted[key] = null
			continue
		if(!isnum(value) || !IS_FINITE(value) || value < 0)
			return FALSE
		accepted[key] = value
	for(var/key in counter_keys)
		if(isnull(metrics[key]))
			continue
		if(!netrun_external_valid_decimal(metrics[key], TRUE))
			return FALSE
		accepted[key] = metrics[key]
	for(var/key in code_keys)
		if(!(key in metrics))
			continue
		if(isnull(metrics[key]))
			accepted[key] = null
		else
			var/value = netrun_external_safe_code(metrics[key], "")
			if(!length(value))
				return FALSE
			accepted[key] = value
	if(!isnull(metrics["topology_pending"]))
		if(metrics["topology_pending"] != TRUE && metrics["topology_pending"] != FALSE)
			return FALSE
		accepted["topology_pending"] = metrics["topology_pending"]
	if("uptime_ms" in accepted)
		var/elapsed_ms = accepted["uptime_ms"] - host_metrics["uptime_ms"]
		accepted["process_cpu_percent"] = !isnull(accepted["process_cpu_ms"]) && !isnull(host_metrics["process_cpu_ms"]) && elapsed_ms > 0 ? max(0, accepted["process_cpu_ms"] - host_metrics["process_cpu_ms"]) / elapsed_ms * 100 : null
	for(var/key in accepted)
		host_metrics[key] = accepted[key]
	host_apply_ms = (host_metrics["apply_us"] || 0) / 1000
	host_pump_ms = (host_metrics["pump_us"] || 0) / 1000
	host_input_unacked = host_metrics["input_unacked"] || 0
	host_output_unacked = host_metrics["output_unacked"] || 0
	return TRUE

/// Вызывается существующим native metrics sampler, не создаёт нового таймера и не сканирует очереди.
/datum/netrun_external_core/proc/sample_library_monitor()
	var/elapsed = monitor_age(monitor_last_sample_at)
	if(!isnull(elapsed) && elapsed < 2)
		return
	var/datum/netrun_external_effects/machines/executor = effects
	var/pending = istype(executor) ? executor.pending_current_count : 0
	var/tx_rate = !isnull(elapsed) && elapsed > 0 ? max(0, sent_bytes - monitor_last_sent_bytes) / 1024 / elapsed : 0
	var/rx_rate = !isnull(elapsed) && elapsed > 0 ? max(0, received_bytes - monitor_last_received_bytes) / 1024 / elapsed : 0
	library_monitor_history += list(list("time" = world.time / (1 SECONDS), "tx_kib_s" = tx_rate, "rx_kib_s" = rx_rate, "input_frames" = length(inflight_frames), "pending" = pending, "ack_ms" = last_ack_ms, "host_ms" = host_apply_ms + host_pump_ms))
	if(length(library_monitor_history) > 60)
		library_monitor_history.Cut(1, length(library_monitor_history) - 59)
	monitor_last_sample_at = monitor_now()
	monitor_last_sent_bytes = sent_bytes
	monitor_last_received_bytes = received_bytes

/// Составные строки тоже различают неизвестное значение и реальный ноль.
/proc/netrun_library_monitor_format(value, divisor = 1)
	return isnull(value) ? "—" : (isnum(value) ? round(value / divisor, 0.001) : value)

/// Весь отчёт — новые списки скаляров. Чтение не открывает Core, не запрашивает topology и не запускает работу.
/datum/controller/subsystem/netrun/proc/library_monitor_snapshot()
	var/datum/netrun_external_core/core = external_core
	var/list/status = list("mode" = external_mode, "state" = core?.state || "unavailable", "ready" = core?.ready || FALSE, "health" = "offline", "label" = "Библиотека не подключена", "detail" = "Ожидание подключения к NETRUN Host.", "last_error" = core?.last_error || external_error, "telemetry_supported" = core?.monitoring_negotiated || FALSE, "telemetry_age_s" = core ? core.monitor_age(core.last_host_monitor_at) : null, "binding" = core?.binding_epoch)
	var/list/sections = list()
	var/list/history = list()
	var/retry_remaining = external_retry_scheduled ? max(0, external_retry_wait - ((external_now() - external_retry_started + 864000) % 864000)) / (1 SECONDS) : 0
	sections += list(list("title" = "Подключение", "rows" = list(
		list("label" = "Состояние DM", "value" = status["state"]),
		list("label" = "Последняя ошибка", "value" = status["last_error"]),
		list("label" = "Повторное подключение через", "value" = retry_remaining, "unit" = "с"),
		list("label" = "Подключений / отключений", "value" = "[core?.monitor_connections || 0] / [core?.monitor_disconnects || 0]"),
		list("label" = "Последний отказ", "value" = core?.monitor_last_failure),
		list("label" = "Отвергнутый ответ", "value" = length(core?.last_rejected_output) ? json_encode(core.last_rejected_output) : null)
	)))
	if(QDELETED(core))
		return list("status" = status, "sections" = sections, "history" = history)
	var/oldest_ack_age = 0
	if(length(core.inflight_frames))
		var/list/oldest = core.inflight_frames[core.inflight_frames[1]]
		oldest_ack_age = core.monitor_age(oldest["started_at"])
	if(core.state != "closed" && core.state != "resync_required")
		status["health"] = core.ready ? "ok" : "waiting"
		status["label"] = core.ready ? "Библиотека работает" : "Синхронизация"
		status["detail"] = core.ready ? "Core подключён; готовность графа подтверждена." : "[core.state], snapshot: [core.snapshot_phase || "завершён"]."
		if(core.monitoring_negotiated && core.monitor_age(isnull(core.last_host_response_at) ? core.opened_at : core.last_host_response_at) > 10)
			status["health"] = "stale"
			status["label"] = "Нет свежей телеметрии Host"
			status["detail"] = "Более 10 секунд без heartbeat или application output. Проверьте очереди и процесс Host; соединение автоматически не закрывается."
		else if(oldest_ack_age > 10)
			status["health"] = "waiting"
			status["label"] = "Ожидается обработка входных данных"
			status["detail"] = "Старейший неподтверждённый input ожидает [round(oldest_ack_age, 0.1)] с."
		else if(core.host_metrics["topology_error"] || core.host_metrics["communication_error"])
			status["health"] = "error"
			status["label"] = "Ошибка Core"
			status["detail"] = "[core.host_metrics["topology_error"] || core.host_metrics["communication_error"]]"
	else if(status["last_error"] && status["last_error"] != "closed" && status["last_error"] != "world_shutdown")
		status["health"] = "error"
		status["label"] = "Подключение потеряно"
		status["detail"] = "Причина: [status["last_error"]]. Следующая попытка через [round(retry_remaining, 0.1)] с."
	var/list/latest = length(core.library_monitor_history) ? core.library_monitor_history[length(core.library_monitor_history)] : list()
	sections += list(list("title" = "Обмен DM ↔ bridge ↔ Host", "rows" = list(
		list("label" = "TX / RX", "value" = "[round(core.sent_bytes / 1024, 0.1)] / [round(core.received_bytes / 1024, 0.1)]", "unit" = "KiB"),
		list("label" = "TX / RX кадров", "value" = "[core.sent_frames] / [core.received_frames]"),
		list("label" = "TX", "value" = latest["tx_kib_s"], "unit" = "KiB/с"),
		list("label" = "RX", "value" = latest["rx_kib_s"], "unit" = "KiB/с"),
		list("label" = "ACK последний / максимум", "value" = "[round(core.last_ack_ms, 0.1)] / [round(core.max_ack_ms, 0.1)]", "unit" = "мс"),
		list("label" = "Старейший input без ACK", "value" = oldest_ack_age, "unit" = "с"),
		list("label" = "Input в полёте / пик", "value" = "[length(core.inflight_frames)] / [core.peak_inflight_frames]"),
		list("label" = "Input reservation", "value" = core.inflight_frame_bytes / 1024, "unit" = "KiB"),
		list("label" = "Bridge inbound / outbound", "value" = "[core.native_inbound_frames] / [core.native_outbound_frames]", "unit" = "кадров"),
		list("label" = "Bridge inbound / outbound объём", "value" = "[round(core.native_inbound_bytes / 1024, 0.1)] / [round(core.native_outbound_bytes / 1024, 0.1)]", "unit" = "KiB"),
		list("label" = "Input sent / applied", "value" = "[core.sent_input_sequence] / [core.last_applied_sequence]"),
		list("label" = "Output ACK", "value" = core.ack_output_sequence)
	)))
	var/list/metrics = core.host_metrics
	sections += list(list("title" = "C# Core — последний снимок Host", "rows" = list(
		list("label" = "Mirror", "value" = metrics["sync_state"]),
		list("label" = "Topology pending", "value" = metrics["topology_pending"]),
		list("label" = "Topology / communications error", "value" = "[metrics["topology_error"] || "—"] / [metrics["communication_error"] || "—"]"),
		list("label" = "Nodes / services / sectors", "value" = "[netrun_library_monitor_format(metrics["node_count"])] / [netrun_library_monitor_format(metrics["service_count"])] / [netrun_library_monitor_format(metrics["sector_count"])]"),
		list("label" = "Graph version / input", "value" = "[metrics["graph_version"] || "—"] / [metrics["graph_input_sequence"] || "—"]"),
		list("label" = "Requests / discovery / projections", "value" = "[netrun_library_monitor_format(metrics["active_requests"])] / [netrun_library_monitor_format(metrics["active_discovery"])] / [netrun_library_monitor_format(metrics["active_projections"])]"),
		list("label" = "События к отправке", "value" = metrics["pending_events"]),
		list("label" = "Ingress очередь", "value" = metrics["input_queue_frames"], "unit" = "кадров"),
		list("label" = "Egress очередь", "value" = metrics["output_queue_frames"], "unit" = "кадров"),
		list("label" = "Ingress / egress объём", "value" = "[netrun_library_monitor_format(metrics["input_queue_bytes"], 1024)] / [netrun_library_monitor_format(metrics["output_queue_bytes"], 1024)]", "unit" = "KiB"),
		list("label" = "Output journal кадров", "value" = metrics["output_journal_frames"], "unit" = "кадров"),
		list("label" = "Output journal объём", "value" = isnull(metrics["output_journal_bytes"]) ? null : metrics["output_journal_bytes"] / 1024, "unit" = "KiB"),
		list("label" = "Apply / Pump", "value" = "[netrun_library_monitor_format(metrics["apply_us"], 1000)] / [netrun_library_monitor_format(metrics["pump_us"], 1000)]", "unit" = "мс"),
		list("label" = "Apply / Pump пик", "value" = "[netrun_library_monitor_format(metrics["max_apply_us"], 1000)] / [netrun_library_monitor_format(metrics["max_pump_us"], 1000)]", "unit" = "мс"),
		list("label" = "Объединено fact frames", "value" = metrics["coalesced_fact_frames"]),
		list("label" = "Managed memory", "value" = isnull(metrics["managed_bytes"]) ? null : metrics["managed_bytes"] / 1048576, "unit" = "MiB"),
		list("label" = "Process working set", "value" = isnull(metrics["working_set_bytes"]) ? null : metrics["working_set_bytes"] / 1048576, "unit" = "MiB"),
		list("label" = "Process CPU всего", "value" = metrics["process_cpu_ms"], "unit" = "мс"),
		list("label" = "Process CPU, 100% = одно ядро", "value" = metrics["process_cpu_percent"], "unit" = "%"),
		list("label" = "GC collections gen0 / gen1 / gen2", "value" = "[netrun_library_monitor_format(metrics["gc_gen0"])] / [netrun_library_monitor_format(metrics["gc_gen1"])] / [netrun_library_monitor_format(metrics["gc_gen2"])]"),
		list("label" = "Host uptime", "value" = isnull(metrics["uptime_ms"]) ? null : metrics["uptime_ms"] / 1000, "unit" = "с")
	)))
	var/datum/netrun_external_effects/machines/executor = core.effects
	if(istype(executor))
		sections += list(list("title" = "DM — применение результатов", "rows" = list(
			list("label" = "Facts в журнале", "value" = max(0, length(core.journal) - core.journal_head + 1)),
			list("label" = "Machine contexts", "value" = executor.pending_current_count),
			list("label" = "Request / control / inflight команды", "value" = "[length(executor.request_commands)] / [length(executor.control_commands)] / [length(executor.inflight_commands)]"),
			list("label" = "Invocations удерживается", "value" = length(executor.invocations)),
			list("label" = "Native очередь IDs", "value" = max(0, length(executor.native_invocation_queue) - executor.native_invocation_cursor + 1)),
			list("label" = "Native запущено", "value" = executor.native_started_count),
			list("label" = "Native ожидание максимум", "value" = executor.native_max_queue_wait_ms, "unit" = "мс")
		)))
	var/datum/netrun_external_effects/machines/queries/queries = executor
	if(istype(queries))
		var/datum/netrun_external_graph_cursor/sync = queries.projection_sync
		sections += list(list("title" = "Query / GraphSync → интерфейс", "rows" = list(
			list("label" = "Query queued / inflight / consumers", "value" = "[length(queries.query_commands)] / [length(queries.query_inflight)] / [length(queries.query_consumers)]"),
			list("label" = "Projection pending / demands", "value" = "[length(queries.projection_pending)] / [length(queries.projection_demands)]"),
			list("label" = "Уведомления UI", "value" = length(queries.projection_notifications)),
			list("label" = "GraphSync phase / next page", "value" = "[sync?.phase || "нет"] / [sync?.next_page || "—"]"),
			list("label" = "GraphSync batch / ACK pending", "value" = "[sync?.in_batch || FALSE] / [sync?.ack_pending || FALSE]"),
			list("label" = "Baseline / target version", "value" = "[sync?.baseline_version || "—"] / [sync?.target_version || "—"]"),
			list("label" = "Опубликованный graph / input", "value" = "[queries.projection_graph_version] / [queries.projection_input_sequence]")
		)))
	for(var/list/sample as anything in core.library_monitor_history)
		history += list(sample.Copy())
	return list("status" = status, "sections" = sections, "history" = history)
