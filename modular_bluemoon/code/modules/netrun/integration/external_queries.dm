/// Одна immutable auxiliary команда; consumer не удерживает удалённого игрового владельца.
/datum/netrun_external_query_command
	parent_type = /datum/netrun_external_command
	/// Корреляция и weak continuation для discovery/projection, отдельно от machine contexts.
	var/request_id
	var/datum/weakref/consumer
	/// Управляющая отмена должна отправиться даже после удаления consumer.
	var/control = FALSE

/// Одна смена native NTnet backbone; значение фиксируется до application ACK.
/datum/netrun_external_backbone_command
	parent_type = /datum/netrun_external_command
	var/enabled

/// Общий bounded dispatcher read-only запросов; все вычисления остаются у Host.
/datum/netrun_external_effects/machines/queries
	/// Три фиксированных producer не создают неограниченного количества watermarks в C#.
	var/list/query_serials = list("discovery" = "0", "projection" = "0", "anchor" = "0")
	/// Нулевые application quotas не ограничивают обработку; continuations всегда weak.
	var/query_limit = 0
	var/query_command_limit = 0
	var/list/query_consumers = list()
	var/list/query_commands = list()
	var/list/query_inflight = list()
	/// Idle graph subscription не требует busy polling, в отличие от незавершённого one-shot запроса.
	var/list/query_persistent = list()
	/// Чередование machine и auxiliary очередей не позволяет карте вытеснять сообщения.
	var/query_turn = TRUE
	var/query_disconnecting = FALSE
	/// Состояние подтверждено Host отдельно от физического наличия его listener.
	var/backbone_applied
	var/backbone_pending = FALSE

/// Native setter будит обычный worker; запросы не вычисляют маршрут в DM.
/datum/controller/subsystem/netrun/proc/external_backbone_changed()
	if(ensure_external_mode() != "external")
		return
	var/datum/netrun_external_effects/machines/queries/executor = external_core?.effects
	if(istype(executor))
		executor.prepare_backbone(external_core)
	wake_ready_delivery()

/// Initial и changed backbone проходят тот же ACK/fact-prefix gate перед admission новых запросов.
/datum/netrun_external_effects/machines/queries/proc/prepare_backbone(datum/netrun_external_core/client)
	if(closed || query_disconnecting || !client?.ready || backbone_pending)
		return FALSE
	var/enabled = SSnetworks.station_network && !SSnetworks.station_network.setting_disabled
	if(!isnull(backbone_applied) && backbone_applied == enabled)
		return FALSE
	if(command_limit > 0 && queued_commands() >= command_limit)
		return client.abort_session("backbone_command_pressure")
	var/datum/netrun_external_backbone_command/command = new
	command.kind = "backbone_configure"
	command.enabled = enabled
	command.fact_barrier = client.capture_fact_barrier()
	if(isnull(command.fact_barrier))
		qdel(command)
		return FALSE
	command.raw_json = netrun_external_json_object(list("kind" = json_encode(command.kind), "enabled" = netrun_external_json_bool(enabled)))
	control_commands.Insert(1, command)
	backbone_pending = TRUE
	owner.wake_ready_delivery()
	return TRUE

/// Неподтверждённая native смена backbone запрещает stale effects даже до очередного fire/poll.
/datum/netrun_external_effects/machines/queries/native_network_ready(datum/netrun_external_core/client, list/result, datum/netrun_external_request_context/context)
	var/enabled = SSnetworks.station_network && !SSnetworks.station_network.setting_disabled
	return !backbone_pending && !isnull(backbone_applied) && backbone_applied == enabled && ..()

/// ID не зависит от DM float, адреса объекта или повторного outer sequence.
/datum/netrun_external_effects/machines/queries/proc/new_query_id(producer)
	if(!(producer in query_serials) || closed || query_disconnecting)
		return null
	var/next = netrun_external_decimal_next(query_serials[producer])
	if(!next)
		return null
	query_serials[producer] = next
	return "[producer]:[next]"

/// Проверяет только locally allocated ID; поздняя read-only страница после cancel не исполняет callbacks.
/datum/netrun_external_effects/machines/queries/proc/known_query_id(request_id)
	if(!istext(request_id))
		return FALSE
	var/separator = findtext(request_id, ":")
	if(!separator)
		return FALSE
	var/producer = copytext(request_id, 1, separator)
	var/sequence = copytext(request_id, separator + 1)
	return (producer in query_serials) && netrun_external_valid_decimal(sequence) && netrun_external_decimal_compare(sequence, query_serials[producer]) <= 0

/// Регистрация consumer и команды атомарна: admission pressure не оставляет пустой slot.
/datum/netrun_external_effects/machines/queries/proc/enqueue_query(kind, raw_json, datum/consumer)
	if(closed || query_disconnecting || QDELETED(consumer) || (query_command_limit > 0 && length(query_commands) + length(query_inflight) >= query_command_limit) || !(kind in list("service_discover", "projection_query", "anchor_query", "graph_sync_start", "graph_sync_continue")))
		return FALSE
	var/list/body
	try
		body = json_decode(raw_json)
	catch
		return FALSE
	var/request_id = body?["request_id"]
	var/continuation = kind == "graph_sync_continue"
	if(body?["kind"] != kind || !known_query_id(request_id) || (continuation ? get_query_consumer(request_id) != consumer : !!query_consumers[request_id]) || (!continuation && query_limit > 0 && length(query_consumers) >= query_limit))
		return FALSE
	var/datum/netrun_external_query_command/command = new
	command.kind = kind
	command.fact_barrier = owner.external_core?.capture_fact_barrier()
	if(isnull(command.fact_barrier))
		qdel(command)
		return FALSE
	command.raw_json = raw_json
	command.request_id = request_id
	command.consumer = WEAKREF(consumer)
	query_consumers[request_id] = command.consumer
	if(kind == "graph_sync_start")
		query_persistent[request_id] = TRUE
	// Одна persistent Continue на query burst, после bounded prefix старых lookups.
	// Полный FIFO за сотнями discovery задерживает каждую страницу snapshot;
	// безусловный Insert(1) в legacy режиме, напротив, вытесняет сами lookups.
	if(continuation)
		var/slot = max(2, owner.external_core.max_input_commands)
		query_commands.Insert(min(length(query_commands) + 1, slot), command)
	else
		query_commands += command
	owner?.wake_ready_delivery()
	return TRUE

/// Никогда не возвращает strong reference на уже удалённого native consumer.
/datum/netrun_external_effects/machines/queries/proc/get_query_consumer(request_id)
	RETURN_TYPE(/datum)
	var/datum/weakref/reference = query_consumers[request_id]
	return reference?.resolve()

/// Локальные queued команды убираются сразу; отправленный запрос отменяется отдельной bounded командой.
/datum/netrun_external_effects/machines/queries/proc/forget_query(request_id, cancel_kind = null)
	if(!query_consumers[request_id])
		return
	query_consumers -= request_id
	query_persistent -= request_id
	var/never_sent = FALSE
	for(var/datum/netrun_external_query_command/command as anything in query_commands.Copy())
		if(command.request_id == request_id && !command.control)
			query_commands -= command
			never_sent = !command.first_attempt_sequence
			qdel(command)
	if(never_sent || !cancel_kind || closed || query_disconnecting)
		return
	if(!(cancel_kind in list("service_discovery_cancel", "projection_cancel", "graph_sync_cancel")) || (query_command_limit > 0 && length(query_commands) + length(query_inflight) >= query_command_limit))
		owner?.external_core?.abort_session("query_cancel_pressure")
		return
	var/datum/netrun_external_query_command/cancel = new
	cancel.kind = cancel_kind
	cancel.fact_barrier = owner.external_core?.capture_fact_barrier()
	if(isnull(cancel.fact_barrier))
		qdel(cancel)
		return FALSE
	cancel.request_id = request_id
	cancel.control = TRUE
	cancel.raw_json = netrun_external_json_object(list("kind" = json_encode(cancel_kind), "request_id" = json_encode(request_id)))
	query_commands.Insert(1, cancel)
	owner?.wake_ready_delivery()

/// Учитывает read-only работу в общем heartbeat без отдельного busy loop.
/datum/netrun_external_effects/machines/queries/queued_commands()
	return ..() + length(query_commands) + length(query_inflight) + length(query_consumers) - length(query_persistent)

/// Ready causal prefixes занимают свободные slots общего bounded duplex window.
/datum/netrun_external_effects/machines/queries/prepare_input(datum/netrun_external_core/client)
	if(closed || query_disconnecting || !client.ready || client.pending_frame || client.snapshot_phase)
		return FALSE
	prepare_backbone(client)
	prepare_projection(client)
	if(!query_turn && (length(control_commands) || length(request_commands)))
		query_turn = TRUE
		return ..()
	if(send_input_queue(client, query_commands))
		query_turn = FALSE
		return TRUE
	query_turn = TRUE
	return ..()

/// Query consumers остаются weak и не продлевают жизнь native UI/graph cursors.
/datum/netrun_external_effects/machines/queries/input_command_current(datum/netrun_external_command/command)
	if(!istype(command, /datum/netrun_external_query_command))
		return ..()
	var/datum/netrun_external_query_command/query = command
	return query.control || !QDELETED(get_query_consumer(query.request_id))

/datum/netrun_external_effects/machines/queries/discard_input_command(datum/netrun_external_command/command)
	if(istype(command, /datum/netrun_external_query_command))
		var/datum/netrun_external_query_command/query = command
		query_consumers -= query.request_id
		query_persistent -= query.request_id
	return ..()

/datum/netrun_external_effects/machines/queries/track_input_command(datum/netrun_external_command/command, sequence)
	if(!istype(command, /datum/netrun_external_query_command))
		return ..()
	query_inflight[sequence] = command

/// Hints инвалидируют read-only caches до callbacks; would_block повторяет ровно прежний domain ID/body.
/datum/netrun_external_effects/machines/queries/observe_result(datum/netrun_external_core/client, list/result)
	observe_projection(client, result, null)
	observe_discovery(client, result, null)
	var/sequence = result["input_sequence"]
	var/datum/netrun_external_query_command/command = query_inflight[sequence]
	if(!command)
		var/datum/netrun_external_backbone_command/backbone = inflight_commands[sequence]
		if(istype(backbone))
			var/list/result_action = result["action"]
			if(!result_action?["would_block"])
				backbone_pending = FALSE
				if(result_action?["accepted"])
					backbone_applied = backbone.enabled
		return ..()
	// Base executor обновляет captured native-effect stamps и для query ACK, где machine command отсутствует.
	..()
	query_inflight -= sequence
	var/list/admission = result["admission"]
	var/list/action = result["action"]
	if(admission?["status"] == "would_block" || action?["would_block"])
		if(command.control || !QDELETED(get_query_consumer(command.request_id)))
			prepend_retry(query_commands, command)
			return
	if(command.kind == "service_discover")
		observe_discovery(client, result, command)
	else if(command.kind == "projection_query" || command.kind == "anchor_query" || command.kind == "graph_sync_start" || command.kind == "graph_sync_continue")
		observe_projection(client, result, command)
	qdel(command)

/// Незнакомый output не получает ACK; известные отменённые read-only запросы не создают эффектов.
/datum/netrun_external_effects/machines/queries/process_result(datum/netrun_external_core/client, list/result)
	if(result["binding_epoch"] != client.binding_epoch)
		return FALSE
	if(result["kind"] == "discovery_page" || result["kind"] == "projection_page" || result["kind"] == "graph_sync_page")
		var/id = result["request_id"]
		if(!known_query_id(id))
			return FALSE
		if(QDELETED(get_query_consumer(id)))
			if(result["kind"] == "graph_sync_page")
				return acknowledge_retired_graph_page(client, result)
			return TRUE
		if(result["kind"] == "graph_sync_page")
			return process_graph_sync(client, result)
		return result["kind"] == "discovery_page" ? process_discovery(client, result) : process_projection(client, result)
	return ..()

/// Cancelled stream сохраняет один Core slot до page ACK; удалённый consumer не должен удерживать его навсегда.
/datum/netrun_external_effects/machines/queries/proc/acknowledge_retired_graph_page(datum/netrun_external_core/client, list/result)
	if(!netrun_external_valid_decimal(result["page_index"]) || closed || query_disconnecting || (command_limit > 0 && queued_commands() >= command_limit))
		return FALSE
	var/datum/netrun_external_command/command = new
	command.kind = "graph_sync_continue"
	command.fact_barrier = client.capture_fact_barrier()
	if(isnull(command.fact_barrier))
		qdel(command)
		return FALSE
	command.raw_json = netrun_external_json_object(list("kind" = json_encode(command.kind), "request_id" = json_encode(result["request_id"]), "page_index" = json_encode(result["page_index"])))
	control_commands += command
	owner?.wake_ready_delivery()
	return TRUE

/// Binding loss очищает read-only continuations до native contexts; автоматического retry эффектов нет.
/datum/netrun_external_effects/machines/queries/disconnected(datum/netrun_external_core/client, reason)
	query_disconnecting = TRUE
	disconnect_projection(client, reason)
	disconnect_discovery(client, reason)
	for(var/datum/netrun_external_query_command/command as anything in query_commands)
		qdel(command)
	for(var/sequence in query_inflight)
		qdel(query_inflight[sequence])
	query_commands.Cut()
	query_inflight.Cut()
	query_consumers.Cut()
	query_persistent.Cut()
	backbone_applied = null
	backbone_pending = FALSE
	..()
	query_disconnecting = FALSE
