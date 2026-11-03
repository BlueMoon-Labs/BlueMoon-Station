/// C# Core is the only network engine; native effects retain gameplay authority.
/datum/controller/subsystem/netrun
	/// Последовательный владелец экспортируемых фактов и native bridge.
	var/datum/netrun_external_core/external_core
	/// Единственный поддерживаемый режим; устаревшие значения конфигурации отклоняются.
	var/external_mode = "external"
	/// Mode выбирается до node initialization; IPC и token читаются позднее в обычном fire.
	var/external_mode_checked = FALSE
	/// Первый config attempt уже выполнен; mode фиксируется отдельно, а token перечитывается при recovery.
	var/external_configuration_checked = FALSE
	/// Короткий безопасный код startup-отказа, без token или содержимого файла.
	var/external_error
	/// Физический backoff следующего отказа в ds: 1,2,4,8,16,30 секунд, независимо от game clock.
	var/external_retry_delay = 10
	/// Один scheduled retry не ускоряется повторными close/abort callbacks того же binding.
	var/external_retry_scheduled = FALSE
	var/external_retry_started = 0
	var/external_retry_wait = 0
	/// Shutdown запрещает reentrant callbacks повторно открыть Host во время завершения мира.
	var/external_shutting_down = FALSE

/// Master закрывает IPC до выгрузки native libraries; обычный fire никогда не ждёт worker.
/datum/controller/subsystem/netrun/Shutdown()
	shutdown_external_core()
	return ..()

/// Только shutdown допускает bounded yield: close ABI остаётся неблокирующим, worker получает время освободить socket.
/datum/controller/subsystem/netrun/proc/shutdown_external_core()
	external_shutting_down = TRUE
	external_retry_scheduled = FALSE
	if(QDELETED(external_core))
		return TRUE
	external_core.close("world_shutdown")
	if(!external_core.library_path)
		return TRUE
	for(var/attempt in 1 to 20)
		var/list/result = external_core.native_call("netrun_close", list())
		if(result?["state"] == "closed")
			return TRUE
		sleep(1)
	log_world("NETRUN bridge shutdown timeout")
	return FALSE

/// Точка подмены только для hermetic tests; production читает строго именованные env настройки.
/datum/controller/subsystem/netrun/proc/external_setting(name)
	return world.GetConfig("env", name)

/// Ранние node/routing guards читают только mode, не открывая библиотеку, socket или secret file.
/datum/controller/subsystem/netrun/proc/ensure_external_mode()
	if(external_mode_checked)
		return external_mode
	external_mode_checked = TRUE
	var/mode = external_setting("NETRUN_CORE_MODE")
	mode = istext(mode) && length(mode) ? lowertext(mode) : "external"
	if(mode != "external")
		external_error = "invalid_mode"
		return external_mode
	external_mode = mode
	return external_mode

/// Dependency seam физического clock для hermetic recovery tests; один суточный rollover покрывает backoff.
/datum/controller/subsystem/netrun/proc/external_now()
	return world.timeofday

/// Повторный close не создаёт новую попытку и не сбрасывает экспоненциальную задержку.
/datum/controller/subsystem/netrun/proc/schedule_external_retry(reason)
	if(external_shutting_down || external_retry_scheduled)
		return
	external_error = reason
	log_world("NETRUN_CORE_RETRY [netrun_external_safe_code(reason)]")
	external_retry_started = external_now()
	external_retry_wait = external_retry_delay
	external_retry_delay = min(300, external_retry_delay * 2)
	external_retry_scheduled = TRUE

/// Только bounded filesystem read при due attempt; значение token не выводится и не сохраняется в diagnostics.
/datum/controller/subsystem/netrun/proc/read_external_token(token_file)
	if(!istext(token_file) || !length(token_file) || !fexists(token_file))
		return null
	try
		if(length(file(token_file)) < 1 || length(file(token_file)) > 1024)
			return null
		var/token = file2text(token_file)
		return istext(token) && length(token) <= 1024 ? trim(token) : null
	catch
		return null

/// Новый client создаётся один раз; recovery сохраняет effects и старые executing contexts до их возврата.
/datum/controller/subsystem/netrun/proc/create_external_client()
	var/datum/netrun_external_core/client = new(src)
	client.effects = new /datum/netrun_external_effects/machines/queries(src)
	return client

/// Вызывается каждым SS.fire: active connection не читает config, recovery сохраняет world epoch и меняет binding.
/datum/controller/subsystem/netrun/proc/ensure_external_core()
	if(external_shutting_down)
		return null
	external_configuration_checked = TRUE
	ensure_external_mode()
	if(!QDELETED(external_core) && external_core.state != "closed" && external_core.state != "resync_required")
		if(external_core.ready)
			external_retry_delay = 10
			external_retry_wait = 0
			external_retry_scheduled = FALSE
			external_error = null
		return external_core
	if(external_retry_scheduled)
		var/elapsed = external_now() - external_retry_started
		if(elapsed < 0)
			elapsed += 864000
		if(elapsed < external_retry_wait)
			return external_core
	external_retry_scheduled = FALSE
	if(external_error == "invalid_mode")
		schedule_external_retry("invalid_mode")
		return null
	var/port = external_setting("NETRUN_CORE_PORT") || "18462"
	var/library = external_setting("NETRUN_CORE_LIBRARY") || (world.system_type == UNIX ? "./libnetrun_bridge.so" : "netrun_bridge.dll")
	var/token_file = external_setting("NETRUN_CORE_TOKEN_FILE")
	if(!netrun_external_valid_decimal(port) || netrun_external_decimal_compare(port, "65535") > 0 || !istext(library) || !length(library) || !istext(token_file) || !length(token_file))
		schedule_external_retry("invalid_configuration")
		return null
	var/token = read_external_token(token_file)
	if(!istext(token))
		schedule_external_retry("invalid_token_file")
		return null
	if(QDELETED(external_core))
		external_core = create_external_client()
	if(!external_core.open(library, port, token))
		schedule_external_retry(external_core.last_error || "external_open_failed")
		return null
	external_error = null
	return external_core

/// Native ownership одного запроса. Переданный message не сериализуется как ссылка и живёт до безопасного завершения.
/datum/netrun_external_request_context
	/// Opaque context/request identity и последовательность producer dm.
	var/context_id
	var/request_id
	var/producer_sequence
	var/binding_epoch
	/// Message принадлежит контексту; endpoints и пользователь удерживаются weakrefs.
	var/datum/netrun_machine_message/message
	var/datum/weakref/source_ref
	var/datum/weakref/destination_ref
	var/datum/weakref/user_ref
	/// Снимки protocol IDs/поколений служат финальному сравнению перед native receive.
	var/list/source_service
	var/list/destination_service
	var/list/source_node
	var/list/destination_node
	var/captured_tag
	/// Immutable JSON и checksum payload не меняются при semantic admission retry.
	var/payload_json
	var/payload_hash
	/// Frozen operation contract проверяется вместе с payload при native handoff.
	var/operation_id = "message"
	/// Native журнал и ROOT capture представляют запрос; маршрут и задержку они не вычисляют.
	var/datum/netrun_packet_context/operation
	/// Native radio policy имеет отдельную ревизию, обычные машинные запросы её не используют.
	var/communications = FALSE
	/// Локальные стадии отличаются от статуса очереди Host; native callback может yield.
	var/stage = "queued"
	var/executing = FALSE
	var/native_started = FALSE
	var/native_success = FALSE
	var/cancel_requested = FALSE
	var/disconnected = FALSE
	var/terminal_received = FALSE
	var/terminal_success = FALSE
	var/terminal_reason
	var/callback_done = FALSE
	/// Последняя invocation принадлежит ровно этому контексту и binding.
	var/datum/netrun_external_invocation/invocation

/// Не освобождает message из-под yield native callback: владельцы вызывают Destroy только после его возврата.
/datum/netrun_external_request_context/Destroy()
	QDEL_NULL(message)
	QDEL_NULL(operation)
	source_ref = null
	destination_ref = null
	user_ref = null
	invocation = null
	return ..()

/// Dedup journal конкретного native вызова; executing записывается ДО проверок/receive и до output ACK.
/datum/netrun_external_invocation
	var/invocation_id
	var/request_id
	var/binding_epoch
	var/fingerprint
	var/stage = "queued"
	/// Только scalar authority proof; ingress не удерживает полное wire body или payload.
	var/list/native_proof
	var/queued_at = 0
	/// Известный результат можно повторно отправить, но native effect повторять нельзя.
	var/result_json
	var/result_queued = FALSE

/datum/netrun_external_invocation/Destroy()
	native_proof = null
	result_json = null
	return ..()

/// Одна bounded логическая команда. raw_json не меняется при новом outer sequence после would_block.
/datum/netrun_external_command
	var/kind
	var/raw_json
	var/datum/netrun_external_request_context/context
	var/datum/netrun_external_invocation/invocation
	/// Последний native fact, причинно предшествующий этой immutable команде.
	var/fact_barrier = "0"
	/// Корреляция logical ACK и порядок sibling retries одного транспортного кадра.
	var/sent_sequence
	var/sent_frame_end
	var/first_attempt_sequence
	var/retry_queued = FALSE

/// Отменённые commands не удерживают native contexts после unlink из очереди.
/datum/netrun_external_command/Destroy()
	context = null
	invocation = null
	raw_json = null
	return ..()

/// Единственный исполнитель allowlisted machine-message операции; routing и transport остаются у C#.
/datum/netrun_external_effects/machines
	/// Владелец выбирает external заранее; ready не разрешает изменять режим живого раунда.
	var/datum/controller/subsystem/netrun/owner
	/// Producer serial никогда не переводится в DM number и не сбрасывается при переподключении.
	var/request_serial = "0"
	var/retired_sequence = "0"
	var/active_binding
	/// Последние подтверждённые C# infrastructure stamps; leaf churn не отзывает уже допустимый native handoff.
	var/latest_infra_stamp = "0"
	var/latest_av_infra_stamp = "0"
	var/latest_communication_revision = "0"
	/// Новая engine/binding сессия имеет собственный stamp namespace, независимо от ещё завершающегося old callback.
	var/latest_stamp_binding
	/// Ноль отключает performance-квоту работы; wire size и retention history имеют отдельные ограничения.
	var/context_limit = 0
	var/command_limit = 0
	var/invocation_limit = 0
	var/terminal_invocation_limit = 4096
	var/list/pending = list()
	/// Old disconnected callbacks retain ownership but never drive the new Host clock.
	var/pending_current_count = 0
	var/list/request_commands = list()
	var/list/control_commands = list()
	var/list/inflight_commands = list()
	var/list/invocations = list()
	/// FIFO хранит только invocation IDs; consumed slots очищаются до вызова игрового handler.
	var/list/native_invocation_queue = list()
	var/native_invocation_cursor = 1
	/// Настраиваемый bounded slice: ноль отключает соответствующий предел для отдельного замера.
	var/native_start_limit = 0
	var/native_budget_ms = 0
	var/native_advancing = FALSE
	var/native_advancing_binding
	var/native_last_slice_ms = 0
	var/native_started_count = 0
	var/native_max_queue_wait_ms = 0
	/// Terminal fingerprints нужны только для идемпотентного ACK, не разрешают повтор effect.
	var/list/terminal_hashes = list()
	var/list/terminal_order = list()
	var/terminal_cursor = 1
	/// Завершённые invocation fingerprints подтверждают поздний повтор без native effect и без удержания result/context.
	var/list/terminal_invocations = list()
	var/list/terminal_invocation_order = list()
	/// Кольцевой FIFO заменяет один slot без Cut/сдвига всего списка на каждом завершении.
	var/terminal_invocation_cursor = 1
	var/closed = FALSE

/// Composition не открывает IPC и не создаёт источники игровых эффектов.
/datum/netrun_external_effects/machines/New(datum/controller/subsystem/netrun/source_owner)
	owner = source_owner
	return ..()

/// Потеря executor не запускает DM fallback. Executing callbacks удерживают собственный src до возврата.
/datum/netrun_external_effects/machines/Destroy()
	closed = TRUE
	disconnected(owner?.external_core, "executor_destroyed")
	owner = null
	return ..()

/// В selected+ready режиме принимает ownership message, включая явный admission-отказ; до ready ownership у caller.
/datum/netrun_external_effects/machines/proc/dispatch(datum/netrun_machine_service/source, datum/netrun_machine_service/destination, datum/netrun_machine_message/message)
	var/datum/netrun_external_core/client = owner?.external_core
	if(closed || owner?.external_mode != "external" || !client?.ready)
		return FALSE
	if(QDELETED(message))
		return FALSE
	if(active_binding && active_binding != client.binding_epoch && length(pending))
		return reject_message(message, "предыдущий native вызов ещё завершается")
	if(active_binding != client.binding_epoch)
		retire_if_idle()
		active_binding = client.binding_epoch
	if((context_limit > 0 && length(pending) >= context_limit) || (invocation_limit > 0 && length(invocations) >= invocation_limit) || (command_limit > 0 && queued_commands() >= command_limit))
		return reject_message(message, "очередь внешнего транспорта переполнена")
	if(QDELETED(source) || QDELETED(destination))
		return reject_message(message, "источник или получатель удалён")
	var/list/source_key = client.service_key(source)
	var/list/destination_key = client.service_key(destination)
	var/list/source_node_key = client.node_key(source.resolve_node())
	var/list/destination_node_key = client.node_key(destination.resolve_node())
	if(!source_key || !destination_key || !source_node_key || !destination_node_key)
		return reject_message(message, "сетевой компонент недоступен")
	var/next_serial = netrun_external_decimal_next(request_serial)
	if(!next_serial)
		return reject_message(message, "исчерпан счётчик запросов")
	var/raw_payload
	try
		raw_payload = json_encode(message.payload)
	catch
		return reject_message(message, "payload не может быть передан")
	// Host проверяет форму и бюджет payload как отказ отдельного request.
	// DM проверяет размер сериализованного тела без второго JSON parser в игровом потоке.
	if(!istext(raw_payload) || !length(raw_payload) || length(raw_payload) > 131072)
		return reject_message(message, "payload превышает предел внешнего транспорта")
	// Native machine packet разрешает overlay только этим типам и allowlisted service families.
	var/communications = netrun_communication_policy(source, destination.service_id) && (istype(message, /datum/netrun_machine_message/telecomms) || istype(message, /datum/netrun_machine_message/communications))
	var/datum/netrun_machine_message/telecomms/telecomms = message
	var/frequency = communications && istype(telecomms) ? telecomms.signal?.frequency : null
	if(!isnull(frequency) && (!isnum(frequency) || frequency <= 0 || frequency >= 2.147483648e9 || round(frequency) != frequency))
		return reject_message(message, "частота внешнего транспорта недопустима")
	request_serial = next_serial
	var/datum/netrun_external_request_context/context = new
	context.context_id = "c[request_serial]"
	context.request_id = "dm:[request_serial]"
	context.producer_sequence = request_serial
	context.binding_epoch = client.binding_epoch
	context.message = message
	context.source_ref = WEAKREF(source)
	context.destination_ref = WEAKREF(destination)
	context.user_ref = message.user_ref
	context.source_service = source_key.Copy()
	context.destination_service = destination_key.Copy()
	context.source_node = source_node_key.Copy()
	context.destination_node = destination_node_key.Copy()
	context.captured_tag = destination.service_tag()
	context.payload_json = raw_payload
	context.payload_hash = rustg_hash_string(RUSTG_HASH_SHA256, raw_payload)
	context.operation_id = message.transport_operation()
	context.communications = communications
	message.source = source
	message.recipient = destination
	message.correlation_id ||= context.request_id
	pending[context.request_id] = context
	pending_current_count++
	var/datum/netrun_external_command/command = new
	command.kind = "request_submit"
	command.fact_barrier = client.capture_fact_barrier()
	if(isnull(command.fact_barrier))
		qdel(command)
		return FALSE
	command.context = context
	command.raw_json = netrun_external_json_object(list("kind" = json_encode("request_submit"), "request_id" = json_encode(context.request_id), "source" = service_json(source_key), "destination" = service_json(destination_key), "operation_id" = json_encode(context.operation_id), "payload" = raw_payload, "deadline_ds" = "null", "coalescing_key" = json_encode(message.coalescing_key()), "state_revision" = json_encode(message.transport_revision()), "authorization_context" = json_encode(context.context_id), "native_context" = json_encode(context.context_id), "traffic_class" = json_encode(communications ? "communications" : "ordinary"), "frequency" = json_encode(frequency)))
	request_commands += command
	context.operation = new("machine", "Обмен между машинами", source.resolve_node()?.address, destination.resolve_node()?.address, destination.service_id, operation_id = message.correlation_id)
	context.operation.capture(message.payload)
	context.operation.queued(list(), 0, FALSE)
	return TRUE

/// Явный отказ сохраняет старый ownership-контракт packet.send: callback один раз, затем qdel message.
/datum/netrun_external_effects/machines/proc/reject_message(datum/netrun_machine_message/message, reason)
	message.failed(reason)
	qdel(message)
	return FALSE

/// O(1) admission проверяет суммарное число queued/inflight команд без сканирования payload.
/datum/netrun_external_effects/machines/proc/queued_commands()
	return length(request_commands) + length(control_commands) + length(inflight_commands)

/datum/netrun_external_effects/machines/has_pending_work()
	return pending_current_count || queued_commands()

/// Сервисная ссылка содержит ID и поколение, а не сетевой адрес или proc name.
/datum/netrun_external_effects/machines/proc/service_json(list/key)
	return netrun_external_json_object(list("service_id" = json_encode(key["id"]), "generation" = json_encode(key["generation"])))

/// Только после всех source facts. Invocation results/cancel имеют приоритет перед admission retry, освобождая capacity.
/datum/netrun_external_effects/machines/prepare_input(datum/netrun_external_core/client)
	if(closed || !client.ready || client.pending_frame || client.snapshot_phase)
		return FALSE
	var/list/queue = length(control_commands) ? control_commands : request_commands
	if(!length(queue))
		// Игровые due/deadline не зависят от физического heartbeat; clock идёт только от BYOND.
		if(pending_current_count && client.journal_head > length(client.journal) && max(0, round(world.time)) > client.last_simulation_time)
			return client.enqueue("\[\]", 0)
		return FALSE
	return send_input_queue(client, queue)

/// Снимает только ready FIFO prefix: bounded burst не обгоняет facts и не копирует всю очередь.
/datum/netrun_external_effects/machines/proc/send_input_queue(datum/netrun_external_core/client, list/queue)
	var/list/commands = list()
	var/list/bodies = list()
	var/characters = 0
	var/index = 1
	var/scanned = 0
	while(index <= length(queue) && length(commands) < client.max_input_commands && scanned++ < 32)
		var/datum/netrun_external_command/command = queue[index]
		if(!input_command_current(command))
			queue.Cut(index, index + 1)
			discard_input_command(command)
			continue
		if(!client.command_facts_ready(command.fact_barrier))
			break
		// UTF-8 занимает до четырёх bytes на символ. Большой legacy command передаётся отдельно.
		if(length(commands) && characters + length(command.raw_json) > 131072)
			break
		commands += command
		bodies += command.raw_json
		characters += length(command.raw_json)
		index++
	if(!length(commands))
		return FALSE
	var/sequence = client.input_sequence
	if(!client.enqueue(netrun_external_json_array(bodies), length(commands), length(commands)))
		return FALSE
	queue.Cut(1, length(commands) + 1)
	for(var/datum/netrun_external_command/command as anything in commands)
		sequence = netrun_external_decimal_next(sequence)
		command.sent_sequence = sequence
		command.sent_frame_end = client.pending_sequence
		command.first_attempt_sequence ||= sequence
		command.retry_queued = FALSE
		track_input_command(command, sequence)
	return TRUE

/// Удалённый context не остаётся strong reference в immutable queued command.
/datum/netrun_external_effects/machines/proc/input_command_current(datum/netrun_external_command/command)
	return !command.context || (pending[command.context.request_id] == command.context && (command.kind != "request_submit" || !command.context.cancel_requested))

/datum/netrun_external_effects/machines/proc/discard_input_command(datum/netrun_external_command/command)
	qdel(command)

/datum/netrun_external_effects/machines/proc/track_input_command(datum/netrun_external_command/command, sequence)
	inflight_commands[sequence] = command
	if(command.kind == "request_submit")
		command.context.stage = "submitting"

/// Immutable first-attempt order сохраняет общий retry prefix, в том числе между разными кадрами.
/datum/netrun_external_effects/machines/proc/prepend_retry(list/queue, datum/netrun_external_command/command)
	var/index = 1
	while(index <= length(queue))
		var/datum/netrun_external_command/earlier = queue[index]
		if(!earlier.retry_queued || !command.first_attempt_sequence || !earlier.first_attempt_sequence || netrun_external_decimal_compare(earlier.first_attempt_sequence, command.first_attempt_sequence) >= 0)
			break
		index++
	command.retry_queued = TRUE
	queue.Insert(index, command)

/// Semantic would_block потребляет outer sequence, но сохраняет request identity и неизменяемую команду.
/datum/netrun_external_effects/machines/observe_result(datum/netrun_external_core/client, list/result)
	if(latest_stamp_binding != client.binding_epoch)
		latest_stamp_binding = client.binding_epoch
		latest_infra_stamp = "0"
		latest_av_infra_stamp = "0"
		latest_communication_revision = "0"
	var/infra = result["infra_stamp"]
	var/availability_infra = result["av_infra_stamp"]
	if(netrun_external_valid_decimal(infra, TRUE) && netrun_external_decimal_compare(infra, latest_infra_stamp) >= 0)
		latest_infra_stamp = infra
	if(netrun_external_valid_decimal(availability_infra, TRUE) && netrun_external_decimal_compare(availability_infra, latest_av_infra_stamp) >= 0)
		latest_av_infra_stamp = availability_infra
	var/communication = result["communication_revision"]
	if(netrun_external_valid_decimal(communication, TRUE) && netrun_external_decimal_compare(communication, latest_communication_revision) >= 0)
		latest_communication_revision = communication
	var/sequence = result["input_sequence"]
	var/datum/netrun_external_command/command = inflight_commands[sequence]
	if(!command)
		return
	inflight_commands -= sequence
	var/list/admission = result["admission"]
	var/list/action = result["action"]
	if(command.kind == "request_submit")
		var/datum/netrun_external_request_context/context = command.context
		if(admission?["status"] == "would_block")
			context.stage = "queued"
			if(context.cancel_requested)
				qdel(command)
				return
			prepend_retry(request_commands, command)
			return
		if(admission?["status"] == "coalesced" || (admission?["status"] == "duplicate" && admission?["coalesced_into"]))
			if(!accept_coalesced(context, admission["coalesced_into"]))
				client.abort_session("invalid_coalesced_context")
		else if(admission?["status"] == "accepted" || admission?["status"] == "duplicate")
			context.stage = "accepted"
		else
			finish_context(context, FALSE, admission?["code"] || "request_rejected")
	else if(action?["would_block"])
		prepend_retry(control_commands, command)
		return
	else if(command.kind == "request_cancel" && command.context?.cancel_requested && action?["code"] == "request_unknown")
		finish_context(command.context, FALSE, "cancelled")
	if(command.invocation)
		var/datum/netrun_external_invocation/invocation = command.invocation
		command.invocation = null
		invocation.result_queued = FALSE
		try_retire_invocation(invocation)
	qdel(command)

/// C# сохраняет первый request ID и срок доставки, заменяя только ещё не исполняемое состояние.
/// Новый запрос ждёт своего superseded terminal без message; старый владеет ровно одним актуальным message.
/datum/netrun_external_effects/machines/proc/accept_coalesced(datum/netrun_external_request_context/context, retained_id)
	var/datum/netrun_external_request_context/retained = pending[retained_id]
	if(!context || context == retained || !retained || retained.stage != "accepted" || retained.executing || retained.binding_epoch != context.binding_epoch || retained.operation_id != "state" || context.operation_id != "state" || retained.source_ref?.resolve() != context.source_ref?.resolve() || retained.destination_ref?.resolve() != context.destination_ref?.resolve() || retained.captured_tag != context.captured_tag || QDELETED(retained.message) || QDELETED(context.message) || isnull(context.message.coalescing_key()) || retained.message.coalescing_key() != context.message.coalescing_key())
		return FALSE
	if(context.message.can_replace(retained.message))
		QDEL_NULL(retained.message)
		retained.message = context.message
		context.message = null
		retained.context_id = context.context_id
		retained.user_ref = context.user_ref
		retained.payload_json = context.payload_json
		retained.payload_hash = context.payload_hash
		if(retained.operation)
			retained.message.correlation_id = retained.operation.operation_id
			retained.operation.capture(retained.message.payload)
	else
		QDEL_NULL(context.message)
	context.stage = "accepted"
	return TRUE

/// Один explicit cancel не отменяет уже начатый native effect и не вызывает повтор receive.
/datum/netrun_external_effects/machines/proc/cancel(request_id)
	var/datum/netrun_external_request_context/context = pending[request_id]
	if(!context || closed || (invocation_limit > 0 && length(control_commands) + length(inflight_commands) >= invocation_limit))
		return FALSE
	if(context.cancel_requested)
		return TRUE
	var/datum/netrun_external_command/command = new
	command.kind = "request_cancel"
	command.fact_barrier = owner.external_core?.capture_fact_barrier()
	if(isnull(command.fact_barrier))
		qdel(command)
		return FALSE
	command.context = context
	context.cancel_requested = TRUE
	// Непереданный submit исчезает до terminal callback; in-flight ownership остаётся до отдельного ответа.
	for(var/datum/netrun_external_command/submission as anything in request_commands.Copy())
		if(submission.context == context)
			request_commands -= submission
			qdel(submission)
	command.raw_json = netrun_external_json_object(list("kind" = json_encode("request_cancel"), "request_id" = json_encode(request_id)))
	control_commands += command
	owner?.wake_ready_delivery()
	return TRUE

/// Неизвестные виды output не игнорируются. Native вызов и terminal outcome имеют отдельный lifecycle.
/datum/netrun_external_effects/machines/process_result(datum/netrun_external_core/client, list/result)
	if(result["binding_epoch"] != client.binding_epoch)
		return FALSE
	switch(result["kind"])
		if("service_invocation")
			return receive_invocation(client, result)
		if("request_completed")
			return receive_completion(client, result)
	return FALSE

/// Снимок только при protocol rejection: scalar сравнения объясняют отказ без payload, proof или native references.
/datum/netrun_external_effects/machines/rejected_output_details(datum/netrun_external_core/client, list/result)
	var/request_id = result["request_id"]
	var/invocation_id = result["invocation_id"]
	var/datum/netrun_external_request_context/context = istext(request_id) ? pending[request_id] : null
	var/datum/netrun_external_invocation/invocation = istext(invocation_id) ? invocations[invocation_id] : null
	var/list/terminal = istext(invocation_id) ? terminal_invocations[invocation_id] : null
	var/terminal_completion = istext(request_id) ? terminal_hashes[request_id] : null
	var/list/details = list(
		"machine_context_known" = !QDELETED(context),
		"invocation_known" = !QDELETED(invocation),
		"terminal_invocation_known" = islist(terminal),
		"terminal_completion_known" = !!terminal_completion,
		"machine_pending" = pending_current_count,
		"machine_inflight_commands" = length(inflight_commands)
	)
	if(context)
		details["context_stage"] = netrun_external_safe_code(context.stage, "unknown")
		details["context_binding_matches"] = context.binding_epoch == client.binding_epoch
		details["context_disconnected"] = !!context.disconnected
		details["context_cancel_requested"] = !!context.cancel_requested
		details["context_executing"] = !!context.executing
		details["context_native_started"] = !!context.native_started
		details["context_native_success"] = !!context.native_success
		details["context_terminal_received"] = !!context.terminal_received
		details["context_callback_done"] = !!context.callback_done
		details["context_message_deleted"] = QDELETED(context.message)
		details["context_invocation_matches"] = invocation && context.invocation == invocation
		details["native_context_matches"] = result["native_context"] == context.context_id
		details["authorization_context_matches"] = result["authorization_context"] == context.context_id
		details["operation_matches"] = result["operation_id"] == context.operation_id
		details["invocation_id_matches"] = invocation_id == "[context.binding_epoch]/[context.request_id]"
		details["captured_tag_matches"] = result["captured_tag"] == context.captured_tag
		details["source_service_matches"] = same_key(result["source_service"], context.source_service, "service_id")
		details["destination_service_matches"] = same_key(result["destination_service"], context.destination_service, "service_id")
		details["source_node_matches"] = same_key(result["source_node"], context.source_node, "node_id")
		details["destination_node_matches"] = same_key(result["destination_node"], context.destination_node, "node_id")
	if(invocation)
		details["invocation_stage"] = netrun_external_safe_code(invocation.stage, "unknown")
		details["invocation_binding_matches"] = invocation.binding_epoch == client.binding_epoch
		details["invocation_result_queued"] = !!invocation.result_queued
	try
		if(context && result["kind"] == "service_invocation")
			details["payload_matches"] = rustg_hash_string(RUSTG_HASH_SHA256, json_encode(result["payload"])) == context.payload_hash
		if(invocation || terminal || terminal_completion)
			var/fingerprint = rustg_hash_string(RUSTG_HASH_SHA256, json_encode(result))
			if(invocation)
				details["invocation_fingerprint_matches"] = fingerprint == invocation.fingerprint
			if(terminal)
				details["terminal_invocation_binding_matches"] = terminal["binding"] == client.binding_epoch
				details["terminal_invocation_fingerprint_matches"] = fingerprint == terminal["fingerprint"]
			if(terminal_completion)
				details["terminal_completion_fingerprint_matches"] = fingerprint == terminal_completion
	catch
		details["fingerprint_unavailable"] = TRUE
	return details

/// Dedup проверяется до native identity/permission callbacks, executing публикуется до возможного yield.
/datum/netrun_external_effects/machines/proc/receive_invocation(datum/netrun_external_core/client, list/result)
	var/id = result["invocation_id"]
	if(!istext(id) || !length(id) || length(id) > 256)
		return FALSE
	var/fingerprint = rustg_hash_string(RUSTG_HASH_SHA256, json_encode(result))
	var/list/terminal = terminal_invocations[id]
	if(terminal)
		return terminal["binding"] == client.binding_epoch && terminal["fingerprint"] == fingerprint
	var/datum/netrun_external_invocation/previous = invocations[id]
	if(previous)
		if(previous.binding_epoch != client.binding_epoch || previous.fingerprint != fingerprint)
			return FALSE
		return previous.stage == "queued" || previous.stage == "executing" || queue_invocation_result(client, previous)
	var/datum/netrun_external_request_context/context = pending[result["request_id"]]
	if(!context || context.stage != "accepted" || context.binding_epoch != client.binding_epoch || context.disconnected || result["native_context"] != context.context_id || result["authorization_context"] != context.context_id || result["operation_id"] != context.operation_id || id != "[context.binding_epoch]/[context.request_id]" || (invocation_limit > 0 && length(invocations) >= invocation_limit))
		return FALSE
	if(!same_key(result["source_service"], context.source_service, "service_id") || !same_key(result["destination_service"], context.destination_service, "service_id") || !same_key(result["source_node"], context.source_node, "node_id") || !same_key(result["destination_node"], context.destination_node, "node_id") || result["captured_tag"] != context.captured_tag)
		return FALSE
	if(rustg_hash_string(RUSTG_HASH_SHA256, json_encode(result["payload"])) != context.payload_hash)
		return FALSE
	if(!netrun_external_valid_decimal(result["source_node_revision"], TRUE) || !netrun_external_valid_decimal(result["destination_node_revision"], TRUE) || !netrun_external_valid_decimal(result["infra_stamp"], TRUE) || !netrun_external_valid_decimal(result["av_infra_stamp"], TRUE) || (!isnull(result["communication_revision"]) && !netrun_external_valid_decimal(result["communication_revision"], TRUE)))
		return FALSE
	var/deadline = result["deadline_ds"]
	if(!isnull(deadline) && (!isnum(deadline) || deadline < 0 || deadline != round(deadline) || deadline > 2147483647))
		return FALSE
	var/datum/netrun_external_invocation/invocation = new
	invocation.invocation_id = id
	invocation.request_id = context.request_id
	invocation.binding_epoch = client.binding_epoch
	invocation.fingerprint = fingerprint
	invocation.native_proof = list("deadline_ds" = result["deadline_ds"], "source_node_revision" = result["source_node_revision"], "destination_node_revision" = result["destination_node_revision"], "infra_stamp" = result["infra_stamp"], "av_infra_stamp" = result["av_infra_stamp"], "communication_revision" = result["communication_revision"])
	invocation.queued_at = world.time
	invocations[id] = invocation
	context.invocation = invocation
	context.stage = "native_queued"
	context.executing = TRUE
	native_invocation_queue += id
	owner?.wake_ready_delivery()
	return TRUE

/// Ingress только резервирует ownership; игровой CPU начинается отдельно после применения и ACK выходных кадров.
/datum/netrun_external_effects/machines/advance_native_invocations(datum/netrun_external_core/client)
	set waitfor = FALSE
	if(closed || !client?.ready || (native_advancing && native_advancing_binding == client.binding_epoch) || native_invocation_cursor > length(native_invocation_queue))
		return 0
	var/binding = client.binding_epoch
	native_advancing = TRUE
	native_advancing_binding = binding
	var/slice_started = TICK_USAGE_REAL
	var/slice_time = world.time
	// Новые reentrant invocations остаются следующему slice даже при отключённых measurement-пределах.
	var/stop = length(native_invocation_queue)
	var/start_cap = isnum(native_start_limit) && native_start_limit > 0 ? max(1, round(native_start_limit)) : stop - native_invocation_cursor + 1
	var/budget = isnum(native_budget_ms) ? max(0, native_budget_ms) : 0
	var/scanned = 0
	var/started = 0
	while(native_invocation_cursor <= stop && started < start_cap && scanned++ < start_cap * 2)
		CHECK_TICK
		if(closed || !client.ready || client.binding_epoch != binding || native_advancing_binding != binding)
			break
		if(world.time != slice_time)
			slice_started = TICK_USAGE_REAL
			slice_time = world.time
		var/id = native_invocation_queue[native_invocation_cursor]
		native_invocation_queue[native_invocation_cursor++] = null
		var/datum/netrun_external_invocation/invocation = invocations[id]
		if(QDELETED(invocation) || invocation.stage != "queued")
			continue
		var/list/proof = invocation.native_proof
		invocation.native_proof = null
		var/datum/netrun_external_request_context/context = pending[invocation.request_id]
		if(!context || context.invocation != invocation)
			invocation.stage = "abandoned"
			try_retire_invocation(invocation)
			continue
		if(context.disconnected || context.binding_epoch != binding)
			context.executing = FALSE
			invocation.stage = "abandoned"
			finish_context(context, FALSE, "connection_lost")
			continue
		invocation.stage = "executing"
		context.stage = "invoking"
		native_max_queue_wait_ms = max(native_max_queue_wait_ms, max(0, world.time - invocation.queued_at) * 100)
		started++
		native_started_count++
		run_invocation(client, context, proof)
		sleep(0)
		if(closed || !client.ready || client.binding_epoch != binding || native_advancing_binding != binding || (budget && TICK_DELTA_TO_MS(TICK_USAGE_REAL - slice_started) >= budget))
			break
	// Старый coroutine после CHECK_TICK не меняет очередь и guard уже переподключённого binding.
	if(native_advancing_binding != binding)
		return started
	if(native_invocation_cursor > length(native_invocation_queue))
		native_invocation_queue.Cut()
		native_invocation_cursor = 1
	else if(native_invocation_cursor > 64 && native_invocation_cursor > length(native_invocation_queue) / 2)
		native_invocation_queue = native_invocation_queue.Copy(native_invocation_cursor)
		native_invocation_cursor = 1
	native_last_slice_ms = max(0, TICK_DELTA_TO_MS(TICK_USAGE_REAL - slice_started))
	native_advancing = FALSE
	native_advancing_binding = null
	if(native_invocation_cursor <= length(native_invocation_queue))
		owner?.wake_ready_delivery()
	return started

/// Exact identity не подменяется адресом; null и неверные поколения отвергаются до обращения к объектам.
/datum/netrun_external_effects/machines/proc/same_key(list/received, list/expected, id_field)
	return islist(received) && islist(expected) && received[id_field] == expected["id"] && received["generation"] == expected["generation"]

/// Native handoff требует ACK всех infrastructure facts и точные node revisions из C# invocation.
/datum/netrun_external_effects/machines/proc/native_network_ready(datum/netrun_external_core/client, list/result, datum/netrun_external_request_context/context)
	if(closed || context.disconnected || context.terminal_received || context.binding_epoch != client?.binding_epoch || !client?.ready || !client.infrastructure_facts_ready() || !netrun_external_valid_decimal(result["source_node_revision"], TRUE) || !netrun_external_valid_decimal(result["destination_node_revision"], TRUE) || !netrun_external_valid_decimal(result["infra_stamp"], TRUE) || !netrun_external_valid_decimal(result["av_infra_stamp"], TRUE) || result["infra_stamp"] != latest_infra_stamp || result["av_infra_stamp"] != latest_av_infra_stamp)
		return FALSE
	if(context.communications && (!netrun_external_valid_decimal(result["communication_revision"], TRUE) || result["communication_revision"] != latest_communication_revision))
		return FALSE
	var/datum/netrun_machine_service/source = context.source_ref?.resolve()
	var/datum/netrun_machine_service/destination = context.destination_ref?.resolve()
	return !QDELETED(source) && !QDELETED(destination) && client.resolve_service(context.source_service["id"], context.source_service["generation"]) == source && client.resolve_service(context.destination_service["id"], context.destination_service["generation"]) == destination && client.resolve_node(context.source_node["id"], context.source_node["generation"]) == source.resolve_node() && client.resolve_node(context.destination_node["id"], context.destination_node["generation"]) == destination.resolve_node() && client.node_revision(context.source_node) == result["source_node_revision"] && client.node_revision(context.destination_node) == result["destination_node_revision"]

/// Асинхронный native handler может yield; его message/context не освобождаются до возврата.
/datum/netrun_external_effects/machines/proc/run_invocation(datum/netrun_external_core/client, datum/netrun_external_request_context/context, list/result)
	set waitfor = FALSE
	var/success = FALSE
	var/code = context.cancel_requested ? "native_cancelled" : "native_stale"
	var/datum/netrun_machine_service/source = context.source_ref?.resolve()
	var/datum/netrun_machine_service/destination = context.destination_ref?.resolve()
	var/datum/netrun_machine_message/message = context.message
	try
		if(!context.cancel_requested && !QDELETED(message) && !QDELETED(source) && !QDELETED(destination) && client.resolve_service(context.source_service["id"], context.source_service["generation"]) == source && client.resolve_service(context.destination_service["id"], context.destination_service["generation"]) == destination && client.resolve_node(context.source_node["id"], context.source_node["generation"]) == source.resolve_node() && client.resolve_node(context.destination_node["id"], context.destination_node["generation"]) == destination.resolve_node())
			var/deadline = result["deadline_ds"]
			if(!isnull(deadline) && (!isnum(deadline) || round(world.time) >= deadline))
				code = "native_deadline"
			else if(rustg_hash_string(RUSTG_HASH_SHA256, json_encode(message.payload)) != context.payload_hash)
				code = "native_payload_changed"
			else if(!native_network_ready(client, result, context))
				code = "native_topology_pending"
			else
				message.user_ref = context.user_ref
				if(destination.service_tag() == context.captured_tag && destination.matches(source, context.captured_tag) && destination.accepts(message) && destination.service_tag() == context.captured_tag)
					// Native matches/accepts вправе yield; новые факты за это время немедленно отзывают разрешение.
					if(context.cancel_requested)
						code = "native_cancelled"
					else if(!native_network_ready(client, result, context))
						code = "native_topology_pending"
					else if(!isnull(deadline) && round(world.time) >= deadline)
						code = "native_deadline"
					else
						context.native_started = TRUE
						context.operation?.running()
						context.operation?.receive(list())
						success = destination.receive(message)
						code = success ? "native_completed" : "native_rejected"
	catch
		// Receive мог изменить мир перед исключением; unknown не превращается в безопасный known-failure retry.
		success = FALSE
		code = "outcome_unknown"
	context.executing = FALSE
	context.native_success = success
	context.invocation.stage = "finished"
	context.invocation.result_json = netrun_external_json_object(list("kind" = json_encode("invocation_result"), "binding_epoch" = json_encode(context.binding_epoch), "invocation_id" = json_encode(context.invocation.invocation_id), "success" = netrun_external_json_bool(success), "payload" = "null", "code" = json_encode(code)))
	if(context.disconnected || client.binding_epoch != context.binding_epoch || closed)
		finish_context(context, FALSE, context.native_started ? "outcome_unknown" : "connection_lost")
	else if(context.terminal_received)
		finish_context(context, context.terminal_success, context.terminal_reason)
	else if(!queue_invocation_result(client, context.invocation))
		client.abort_session("native_result_pressure")

/// Известный результат можно retransmit; invocation ledger исключает повтор произвольного native effect.
/datum/netrun_external_effects/machines/proc/queue_invocation_result(datum/netrun_external_core/client, datum/netrun_external_invocation/invocation)
	if(invocation.result_queued)
		return TRUE
	// Результат уже выполненного native effect должен освобождать transport capacity,
	// даже когда request admission заполнен. Его отдельный бюджет ограничен ledger.
	if(!invocation.result_json || invocation.binding_epoch != client.binding_epoch || (invocation_limit > 0 && length(control_commands) + length(inflight_commands) >= invocation_limit))
		return FALSE
	var/datum/netrun_external_command/command = new
	command.kind = "invocation_result"
	command.fact_barrier = client.capture_fact_barrier()
	if(isnull(command.fact_barrier))
		qdel(command)
		return FALSE
	command.raw_json = invocation.result_json
	command.invocation = invocation
	control_commands += command
	invocation.result_queued = TRUE
	return TRUE

/// Terminal duplicates не вызывают delivered/failed повторно; незавершённый native callback удерживает context.
/datum/netrun_external_effects/machines/proc/receive_completion(datum/netrun_external_core/client, list/result)
	var/id = result["request_id"]
	var/fingerprint = rustg_hash_string(RUSTG_HASH_SHA256, json_encode(result))
	if(terminal_hashes[id])
		return terminal_hashes[id] == fingerprint
	var/datum/netrun_external_request_context/context = pending[id]
	if(!context || context.binding_epoch != client.binding_epoch)
		return FALSE
	var/terminal_state = result["state"]
	if(!(terminal_state in list("completed", "failed", "cancelled", "timed_out", "outcome_unknown", "rejected", "superseded")))
		return FALSE
	if(terminal_state == "completed" && (!context.native_started || !context.native_success || context.executing))
		return FALSE
	var/history_limit = max(1, round(terminal_invocation_limit))
	if(length(terminal_order) > history_limit)
		terminal_hashes.Cut()
		terminal_order.Cut()
		terminal_cursor = 1
	if(length(terminal_order) < history_limit)
		terminal_order += id
	else
		terminal_hashes -= terminal_order[terminal_cursor]
		terminal_order[terminal_cursor] = id
		terminal_cursor = terminal_cursor % history_limit + 1
	terminal_hashes[id] = fingerprint
	finish_context(context, terminal_state == "completed", result["code"] || terminal_state)
	return TRUE

/// Ownership освобождается один раз. Callback выполняется отдельно и может yield без остановки output pipeline.
/datum/netrun_external_effects/machines/proc/finish_context(datum/netrun_external_request_context/context, success, reason)
	if(!context || context.callback_done)
		return
	if(context.executing)
		context.terminal_received = TRUE
		context.terminal_success = success
		context.terminal_reason = reason
		return
	context.callback_done = TRUE
	if(!context.disconnected)
		pending_current_count--
	pending -= context.request_id
	context.operation?.finish(success ? "completed" : "cancelled", success ? null : netrun_external_delivery_failure_text(reason))
	var/datum/netrun_external_invocation/invocation = context.invocation
	context.invocation = null
	try_retire_invocation(invocation)
	finalize_context(context, success, reason)
	retire_if_idle()

/// Технические protocol codes остаются в диагностике, а игрок получает понятную причину отказа.
/proc/netrun_external_delivery_failure_text(reason)
	switch(reason)
		if("outcome_unknown")
			return "Не удалось подтвердить выполнение команды устройством."
		if("connection_lost", "external_closed", "executor_destroyed")
			return "Соединение с сетью потеряно."
		if("native_topology_pending", "topology_pending", "source_unavailable", "destination_unavailable", "route_unavailable", "communication_route_unavailable")
			return "Сетевое соединение изменилось; сообщение не доставлено."
		if("native_deadline", "deadline_exceeded", "timed_out")
			return "Время ожидания доставки истекло."
		if("cancelled", "native_cancelled")
			return "Отправитель отменил сообщение."
		if("invalid_payload")
			return "Данные сообщения не поддерживаются сетевым транспортом."
		if("native_rejected", "native_stale", "operation_undeclared")
			return "Получатель отклонил сообщение."
	return "Сообщение не доставлено."

/// Message освобождается только после delivered/failed; исключение callback не вызывает второй callback.
/datum/netrun_external_effects/machines/proc/finalize_context(datum/netrun_external_request_context/context, success, reason)
	set waitfor = FALSE
	var/datum/netrun_machine_message/message = context.message
	try
		if(!QDELETED(message))
			if(success)
				message.delivered(context.destination_ref?.resolve())
			else
				message.failed(netrun_external_delivery_failure_text(reason))
	catch
		// Ошибка completion callback не делает игровой effect повторяемым.
		context.terminal_reason = "completion_callback_failed"
	qdel(context)

/// Terminal и ACK результата освобождают конкретный active slot, даже если более старый запрос ещё выполняется.
/datum/netrun_external_effects/machines/proc/try_retire_invocation(datum/netrun_external_invocation/invocation)
	if(QDELETED(invocation) || invocation.stage == "queued" || invocation.stage == "executing" || invocation.result_queued || pending[invocation.request_id] || invocations[invocation.invocation_id] != invocation)
		return FALSE
	var/id = invocation.invocation_id
	var/history_limit = max(1, round(terminal_invocation_limit))
	if(length(terminal_invocation_order) > history_limit)
		terminal_invocations.Cut()
		terminal_invocation_order.Cut()
		terminal_invocation_cursor = 1
	if(length(terminal_invocation_order) < history_limit)
		terminal_invocation_order += id
	else
		terminal_invocations -= terminal_invocation_order[terminal_invocation_cursor]
		terminal_invocation_order[terminal_invocation_cursor] = id
		terminal_invocation_cursor = terminal_invocation_cursor % history_limit + 1
	terminal_invocations[id] = list("binding" = invocation.binding_epoch, "fingerprint" = invocation.fingerprint)
	invocations -= id
	qdel(invocation)
	return TRUE

/// Producer watermark остаётся консервативным; unACKed result pointers не удаляются даже при idle.
/datum/netrun_external_effects/machines/proc/retire_if_idle()
	if(length(pending))
		return FALSE
	retired_sequence = request_serial
	for(var/id in invocations.Copy())
		try_retire_invocation(invocations[id])
	return TRUE

/// Потеря binding не порождает retry. Executing callback сохраняет context/message до своего возврата.
/datum/netrun_external_effects/machines/disconnected(datum/netrun_external_core/client, reason)
	pending_current_count = 0
	native_advancing = FALSE
	native_advancing_binding = null
	// Сначала убрать внешние queued references; running/yield callbacks сохраняют собственное ownership.
	for(var/index = native_invocation_cursor; index <= length(native_invocation_queue); index++)
		var/datum/netrun_external_invocation/invocation = invocations[native_invocation_queue[index]]
		if(QDELETED(invocation) || invocation.stage != "queued")
			continue
		invocation.native_proof = null
		invocation.stage = "abandoned"
		var/datum/netrun_external_request_context/context = pending[invocation.request_id]
		if(context?.invocation == invocation)
			context.executing = FALSE
	native_invocation_queue.Cut()
	native_invocation_cursor = 1
	for(var/datum/netrun_external_command/command as anything in request_commands)
		qdel(command)
	for(var/datum/netrun_external_command/command as anything in control_commands)
		if(command.invocation)
			command.invocation.result_queued = FALSE
			command.invocation = null
		qdel(command)
	for(var/sequence in inflight_commands)
		var/datum/netrun_external_command/command = inflight_commands[sequence]
		if(command.invocation)
			command.invocation.result_queued = FALSE
			command.invocation = null
		qdel(command)
	request_commands.Cut()
	control_commands.Cut()
	inflight_commands.Cut()
	for(var/id in pending.Copy())
		var/datum/netrun_external_request_context/context = pending[id]
		context.disconnected = TRUE
		if(!context.executing)
			finish_context(context, FALSE, context.native_started ? "outcome_unknown" : "connection_lost")
	retire_if_idle()



/datum/netrun_external_effects/machines/queries
