/// Выбор движка фиксируется при startup; explicit diagnostic dm не читает secret и не открывает IPC.
/datum/controller/subsystem/netrun
	/// Последовательный владелец экспортируемых фактов и native bridge.
	var/datum/netrun_external_core/external_core
	/// dm/shadow/external; переключение живого раунда этой настройкой не реализовано.
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
	if(!(mode in list("dm", "shadow", "external")))
		external_error = "invalid_mode"
		return external_mode
	external_mode = mode
	return external_mode

/// Dependency seam физического clock для hermetic recovery tests; один суточный rollover покрывает backoff.
/datum/controller/subsystem/netrun/proc/external_now()
	return world.timeofday

/// Повторный close не создаёт новую попытку и не сбрасывает экспоненциальную задержку.
/datum/controller/subsystem/netrun/proc/schedule_external_retry(reason)
	if(external_shutting_down || external_retry_scheduled || external_mode == "dm")
		return
	external_error = reason
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
	client.effects = external_mode == "shadow" ? new /datum/netrun_external_effects/machines/shadow(src) : new /datum/netrun_external_effects/machines/queries(src)
	return client

/// Вызывается каждым SS.fire: active connection не читает config, recovery сохраняет world epoch и меняет binding.
/datum/controller/subsystem/netrun/proc/ensure_external_core()
	if(external_shutting_down)
		return null
	external_configuration_checked = TRUE
	var/mode = ensure_external_mode()
	if(mode == "dm")
		return null
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
	/// Native radio policy имеет отдельную ревизию, обычные машинные запросы её не используют.
	var/communications = FALSE
	/// Локальные стадии отличаются от статуса очереди Host; native callback может yield.
	var/stage = "queued"
	var/executing = FALSE
	var/native_started = FALSE
	var/native_success = FALSE
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
	var/stage = "executing"
	/// Известный результат можно повторно отправить, но native effect повторять нельзя.
	var/result_json
	var/result_queued = FALSE

/// Одна bounded логическая команда. raw_json не меняется при новом outer sequence после would_block.
/datum/netrun_external_command
	var/kind
	var/raw_json
	var/datum/netrun_external_request_context/context
	var/datum/netrun_external_invocation/invocation
	/// Последний native fact, причинно предшествующий этой immutable команде.
	var/fact_barrier = "0"

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
	/// Native contexts, команды и журнал имеют независимые фиксированные пределы.
	var/context_limit = 2048
	var/command_limit = 2048
	var/invocation_limit = 4096
	var/list/pending = list()
	var/list/request_commands = list()
	var/list/control_commands = list()
	var/list/inflight_commands = list()
	var/list/invocations = list()
	/// Terminal fingerprints нужны только для идемпотентного ACK, не разрешают повтор effect.
	var/list/terminal_hashes = list()
	var/list/terminal_order = list()
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
	if(length(pending) >= context_limit || length(invocations) >= invocation_limit || queued_commands() >= command_limit)
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
	if(!isnull(frequency) && (!isnum(frequency) || frequency <= 0 || frequency >= 2147483648 || round(frequency) != frequency))
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
	context.communications = communications
	message.source = source
	message.recipient = destination
	message.correlation_id ||= context.request_id
	pending[context.request_id] = context
	var/datum/netrun_external_command/command = new
	command.kind = "request_submit"
	command.fact_barrier = client.capture_fact_barrier()
	if(isnull(command.fact_barrier))
		qdel(command)
		return FALSE
	command.context = context
	command.raw_json = netrun_external_json_object(list("kind" = json_encode("request_submit"), "request_id" = json_encode(context.request_id), "source" = service_json(source_key), "destination" = service_json(destination_key), "operation_id" = json_encode("message"), "payload" = raw_payload, "deadline_ds" = "null", "coalescing_key" = "null", "state_revision" = "null", "authorization_context" = json_encode(context.context_id), "native_context" = json_encode(context.context_id), "traffic_class" = json_encode(communications ? "communications" : "ordinary"), "frequency" = json_encode(frequency)))
	request_commands += command
	return TRUE

/// Явный отказ сохраняет старый ownership-контракт packet.send: callback один раз, затем qdel message.
/datum/netrun_external_effects/machines/proc/reject_message(datum/netrun_machine_message/message, reason)
	message.failed(reason)
	qdel(message)
	return FALSE

/// O(1) admission проверяет суммарное число queued/inflight команд без сканирования payload.
/datum/netrun_external_effects/machines/proc/queued_commands()
	return length(request_commands) + length(control_commands) + length(inflight_commands)

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
		if(length(pending) && client.journal_head > length(client.journal) && max(0, round(world.time)) > client.last_simulation_time)
			return client.enqueue("\[\]", 0)
		return FALSE
	var/datum/netrun_external_command/command = queue[1]
	if(!client.command_facts_ready(command.fact_barrier))
		return FALSE
	if(command.context && pending[command.context.request_id] != command.context)
		queue.Cut(1, 2)
		qdel(command)
		return FALSE
	if(!client.enqueue(netrun_external_json_array(list(command.raw_json))))
		return FALSE
	queue.Cut(1, 2)
	inflight_commands[client.pending_sequence] = command
	if(command.kind == "request_submit")
		command.context.stage = "submitting"
	return TRUE

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
			request_commands.Insert(1, command)
			return
		if(admission?["status"] == "accepted" || admission?["status"] == "duplicate")
			context.stage = "accepted"
		else
			finish_context(context, FALSE, admission?["code"] || "request_rejected")
	else if(action?["would_block"])
		control_commands.Insert(1, command)
		return
	if(command.invocation)
		var/datum/netrun_external_invocation/invocation = command.invocation
		command.invocation = null
		invocation.result_queued = FALSE
		try_retire_invocation(invocation)
	qdel(command)

/// Один explicit cancel не отменяет уже начатый native effect и не вызывает повтор receive.
/datum/netrun_external_effects/machines/proc/cancel(request_id)
	var/datum/netrun_external_request_context/context = pending[request_id]
	if(!context || closed || queued_commands() >= command_limit)
		return FALSE
	var/datum/netrun_external_command/command = new
	command.kind = "request_cancel"
	command.fact_barrier = owner.external_core?.capture_fact_barrier()
	if(isnull(command.fact_barrier))
		qdel(command)
		return FALSE
	command.context = context
	command.raw_json = netrun_external_json_object(list("kind" = json_encode("request_cancel"), "request_id" = json_encode(request_id)))
	control_commands += command
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
		return previous.stage == "executing" || queue_invocation_result(client, previous)
	var/datum/netrun_external_request_context/context = pending[result["request_id"]]
	if(!context || context.stage != "accepted" || context.binding_epoch != client.binding_epoch || context.disconnected || result["native_context"] != context.context_id || result["authorization_context"] != context.context_id || result["operation_id"] != "message" || id != "[context.binding_epoch]/[context.request_id]" || length(invocations) >= invocation_limit)
		return FALSE
	if(!same_key(result["source_service"], context.source_service, "service_id") || !same_key(result["destination_service"], context.destination_service, "service_id") || !same_key(result["source_node"], context.source_node, "node_id") || !same_key(result["destination_node"], context.destination_node, "node_id") || result["captured_tag"] != context.captured_tag)
		return FALSE
	if(rustg_hash_string(RUSTG_HASH_SHA256, json_encode(result["payload"])) != context.payload_hash)
		return FALSE
	var/datum/netrun_external_invocation/invocation = new
	invocation.invocation_id = id
	invocation.request_id = context.request_id
	invocation.binding_epoch = client.binding_epoch
	invocation.fingerprint = fingerprint
	invocations[id] = invocation
	context.invocation = invocation
	context.stage = "invoking"
	context.executing = TRUE
	run_invocation(client, context, result)
	return TRUE

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
	var/code = "native_stale"
	var/datum/netrun_machine_service/source = context.source_ref?.resolve()
	var/datum/netrun_machine_service/destination = context.destination_ref?.resolve()
	var/datum/netrun_machine_message/message = context.message
	try
		if(!QDELETED(message) && !QDELETED(source) && !QDELETED(destination) && client.resolve_service(context.source_service["id"], context.source_service["generation"]) == source && client.resolve_service(context.destination_service["id"], context.destination_service["generation"]) == destination && client.resolve_node(context.source_node["id"], context.source_node["generation"]) == source.resolve_node() && client.resolve_node(context.destination_node["id"], context.destination_node["generation"]) == destination.resolve_node())
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
					if(!native_network_ready(client, result, context))
						code = "native_topology_pending"
					else if(!isnull(deadline) && round(world.time) >= deadline)
						code = "native_deadline"
					else
						context.native_started = TRUE
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
	if(!invocation.result_json || invocation.binding_epoch != client.binding_epoch || queued_commands() >= command_limit)
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
	terminal_hashes[id] = fingerprint
	terminal_order += id
	if(length(terminal_order) > invocation_limit)
		terminal_hashes -= terminal_order[1]
		terminal_order.Cut(1, 2)
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
	pending -= context.request_id
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
	if(QDELETED(invocation) || invocation.stage == "executing" || invocation.result_queued || pending[invocation.request_id] || invocations[invocation.invocation_id] != invocation)
		return FALSE
	var/id = invocation.invocation_id
	if(length(terminal_invocation_order) < invocation_limit)
		terminal_invocation_order += id
	else
		terminal_invocations -= terminal_invocation_order[terminal_invocation_cursor]
		terminal_invocation_order[terminal_invocation_cursor] = id
		terminal_invocation_cursor = terminal_invocation_cursor % invocation_limit + 1
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

/// Shadow никогда не вызывает native handlers, даже если Host ошибочно выдаёт service_invocation.
/datum/netrun_external_effects/machines/shadow/process_result(datum/netrun_external_core/client, list/result)
	if(result["binding_epoch"] != client.binding_epoch)
		return FALSE
	if(result["kind"] == "request_completed")
		return TRUE
	if(result["kind"] != "service_invocation" || !istext(result["invocation_id"]))
		return FALSE
	var/id = result["invocation_id"]
	var/fingerprint = rustg_hash_string(RUSTG_HASH_SHA256, json_encode(result))
	var/list/terminal = terminal_invocations[id]
	if(terminal)
		return terminal["binding"] == client.binding_epoch && terminal["fingerprint"] == fingerprint
	var/datum/netrun_external_invocation/invocation = invocations[id]
	if(invocation)
		return invocation.fingerprint == fingerprint && queue_invocation_result(client, invocation)
	if(length(invocations) >= invocation_limit)
		return FALSE
	invocation = new
	invocation.invocation_id = id
	invocation.request_id = result["request_id"]
	invocation.binding_epoch = client.binding_epoch
	invocation.fingerprint = fingerprint
	invocation.stage = "finished"
	invocation.result_json = netrun_external_json_object(list("kind" = json_encode("invocation_result"), "binding_epoch" = json_encode(client.binding_epoch), "invocation_id" = json_encode(id), "success" = "false", "payload" = "null", "code" = json_encode("shadow_only")))
	invocations[id] = invocation
	return queue_invocation_result(client, invocation)

/// Production dispatcher дополняется отдельными query/projection adapters; isolated harness использует inherited lifecycle.
/datum/netrun_external_effects/machines/queries
