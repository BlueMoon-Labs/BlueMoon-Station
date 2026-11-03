/// Hermetic subsystem не регистрируется в MC и никогда не читает реальные ENV/secret настройки.
/datum/controller/subsystem/netrun/external_fixture
	flags = SS_NO_INIT | SS_NO_FIRE
	var/list/settings = list("NETRUN_CORE_MODE" = "external")
	var/list/settings_read = list()
/datum/controller/subsystem/netrun/external_fixture/New()
	return
/datum/controller/subsystem/netrun/external_fixture/external_setting(name)
	settings_read += name
	return settings[name]

/// Подменён только IPC: ID registry, causal journal gate и output обработчик остаются настоящими.
/datum/netrun_external_core/fixture
	var/list/sent_entries = list()
	var/native_calls = 0
/datum/netrun_external_core/fixture/native_call(export_name, list/arguments)
	native_calls++
	return list("state" = "closed", "code" = "closed", "frames" = list())
/datum/netrun_external_core/fixture/enqueue(entries_json, record_count = 1, command_count = 1)
	if(pending_frame)
		return FALSE
	for(var/index in 1 to command_count)
		input_sequence = netrun_external_decimal_next(input_sequence)
	pending_sequence = input_sequence
	pending_frame = entries_json
	last_simulation_time = max(0, round(world.time))
	sent_entries += entries_json
	return TRUE

/// Native receiver сообщает вызовы отдельно от terminal callbacks message.
/datum/netrun_machine_service/external_fixture
	service_id = "transport.external_fixture"
	var/native_calls = 0
	var/native_tag = "fixture-tag"
	var/native_delay = 0
	var/throw_after_effect = FALSE
	/// Только fixture: yield до native receive проверяет повторную authority проверку после accepts.
	var/accepts_delay = 0
/datum/netrun_machine_service/external_fixture/accepts(datum/netrun_machine_message/message)
	if(accepts_delay)
		sleep(accepts_delay)
	return ..()
/datum/netrun_machine_service/external_fixture/service_tag()
	return native_tag
/datum/netrun_machine_service/external_fixture/receive(datum/netrun_machine_message/message)
	native_calls++
	if(native_delay)
		sleep(native_delay)
	if(throw_after_effect)
		CRASH("Synthetic external native handler exception")
	return TRUE

/// Fixture владеет executor/client; настоящие physical nodes берёт у обычного transport scene.
/datum/netrun_external_fixture
	var/datum/controller/subsystem/netrun/external_fixture/worker
	var/datum/netrun_external_core/fixture/client
	var/datum/netrun_external_effects/machines/executor
	var/datum/netrun_machine_service/source
	var/datum/netrun_machine_service/external_fixture/destination
/datum/netrun_external_fixture/New(datum/netrun_transport_scene/scene)
	worker = new
	worker.external_configuration_checked = TRUE
	worker.external_mode_checked = TRUE
	worker.external_mode = "external"
	client = new(worker)
	worker.external_core = client
	client.world_epoch = "fixture-world"
	client.engine_epoch = "fixture-engine"
	client.binding_epoch = "fixture-binding"
	client.state = "ready"
	client.ready = TRUE
	executor = new(worker)
	client.effects = executor
	source = scene.source
	destination = new(scene.target.resolve_node(), scene.receiver)
/datum/netrun_external_fixture/Destroy()
	client?.close("fixture_cleanup")
	QDEL_NULL(client)
	QDEL_NULL(executor)
	QDEL_NULL(destination)
	worker.external_core = null
	QDEL_NULL(worker)
	source = null
	return ..()

/// Эмулирует prior admission и создаёт wire event без REF/address aliases или произвольного proc name.
/datum/netrun_external_fixture/proc/invocation(datum/netrun_external_request_context/context)
	if(context.stage == "queued" || context.stage == "submitting")
		context.stage = "accepted"
	return list("kind" = "service_invocation", "binding_epoch" = context.binding_epoch, "request_id" = context.request_id,
		"invocation_id" = "[context.binding_epoch]/[context.request_id]", "source_service" = wire_key(context.source_service, "service_id"),
		"destination_service" = wire_key(context.destination_service, "service_id"), "source_node" = wire_key(context.source_node, "node_id"),
		"destination_node" = wire_key(context.destination_node, "node_id"), "captured_tag" = context.captured_tag,
		"source_node_revision" = client.node_revision(context.source_node), "destination_node_revision" = client.node_revision(context.destination_node),
		"infra_stamp" = executor.latest_infra_stamp, "av_infra_stamp" = executor.latest_av_infra_stamp,
		"communication_revision" = context.communications ? executor.latest_communication_revision : null,
		"operation_id" = context.operation_id, "payload" = json_decode(context.payload_json), "deadline_ds" = null,
		"authorization_context" = context.context_id, "native_context" = context.context_id)
/datum/netrun_external_fixture/proc/wire_key(list/key, id_name)
	var/list/result = list("generation" = key["generation"])
	result[id_name] = key["id"]
	return result

/// Terminal события подаются отдельно от invocation, как в реальном output stream.
/datum/netrun_external_fixture/proc/completion(request_id, state = "completed", code = "completed")
	return list("kind" = "request_completed", "binding_epoch" = client.binding_epoch, "request_id" = request_id, "state" = state, "code" = code, "payload" = null)
/datum/netrun_external_fixture/proc/first_context()
	return length(executor.pending) ? executor.pending[executor.pending[1]] : null

/// Тест явно выполняет две фазы: decode/ownership и отдельный bounded native execution slice.
/datum/netrun_external_fixture/proc/receive_result(list/result)
	. = executor.process_result(client, result)
	if(.)
		pump_native(result["invocation_id"])

/// Только fixture ждёт старта отдельной cooperative фазы, не превращая production decode в синхронный handler.
/datum/netrun_external_fixture/proc/pump_native(invocation_id)
	executor.advance_native_invocations(client)
	var/deadline = world.time + 2 SECONDS
	var/datum/netrun_external_invocation/invocation = executor.invocations[invocation_id]
	while(!QDELETED(invocation) && invocation.stage == "queued" && world.time < deadline)
		sleep(world.tick_lag)
		executor.advance_native_invocations(client)

/// Bounded IPC burst сохраняет logical ACK, FIFO retries и captured fact prefix.
/datum/unit_test/netrun_external_core_bounded_batch_retry/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_external_fixture/fixture = allocate(/datum/netrun_external_fixture, scene)
	fixture.client.max_input_commands = 16
	fixture.client.input_sequence = "16777216"
	var/list/original = list()
	for(var/index in 1 to 19)
		TEST_ASSERT(fixture.executor.dispatch(fixture.source, fixture.destination, new /datum/netrun_machine_message/transport_fixture(list("value" = index), list())), "Each message has independent native ownership")
		original += fixture.executor.request_commands[length(fixture.executor.request_commands)]
	fixture.client.queue_fact("{}")
	TEST_ASSERT(fixture.executor.dispatch(fixture.source, fixture.destination, new /datum/netrun_machine_message/transport_fixture(list("value" = 20), list())), "Newer command captures its own causal barrier")
	TEST_ASSERT(fixture.executor.prepare_input(fixture.client), "A negotiated frame sends a bounded ready prefix")
	TEST_ASSERT_EQUAL(fixture.client.pending_sequence, "16777232", "Each logical command advances an exact decimal sequence")
	TEST_ASSERT_EQUAL(length(fixture.executor.inflight_commands), 16, "One wire frame retains sixteen independent ACK correlations")
	var/list/entries = json_decode(fixture.client.pending_frame)
	TEST_ASSERT_EQUAL(length(entries), 16, "The burst is bounded by the negotiated capability")
	for(var/index in 1 to 16)
		var/datum/netrun_external_command/command = original[index]
		fixture.executor.observe_result(fixture.client, list("input_sequence" = command.sent_sequence, "admission" = list("status" = "would_block")))
	for(var/index in 1 to 19)
		TEST_ASSERT_EQUAL(fixture.executor.request_commands[index], original[index], "Sibling retries preserve FIFO before the unsent tail")
	fixture.client.pending_frame = null
	TEST_ASSERT(fixture.executor.prepare_input(fixture.client), "The unchanged request identities can retry as another bounded frame")
	for(var/index in 1 to 16)
		var/datum/netrun_external_command/command = original[index]
		fixture.executor.observe_result(fixture.client, list("input_sequence" = command.sent_sequence, "admission" = list("status" = "accepted")))
	fixture.client.pending_frame = null
	TEST_ASSERT(fixture.executor.prepare_input(fixture.client), "Older work progresses before a newer unconsumed fact")
	entries = json_decode(fixture.client.pending_frame)
	TEST_ASSERT_EQUAL(length(entries), 3, "Batch stops exactly at the first command whose facts are not ready")
	TEST_ASSERT_EQUAL(length(fixture.executor.request_commands), 1, "The fenced tail remains queued")
	TEST_ASSERT_EQUAL(fixture.client.native_calls, 0, "Hermetic batching never loads the real bridge")

/// Removed engine modes fail closed without opening IPC; decimal identities retain 64-bit precision.
/datum/unit_test/netrun_external_core_removed_modes_and_decimal/Run()
	var/datum/controller/subsystem/netrun/external_fixture/worker = allocate(/datum/controller/subsystem/netrun/external_fixture)
	worker.settings["NETRUN_CORE_MODE"] = "dm"
	TEST_ASSERT_NULL(worker.ensure_external_core(), "Removed native engine mode cannot create an IPC client")
	TEST_ASSERT_EQUAL(worker.external_error, "invalid_mode", "Removed native engine mode is an explicit configuration error")
	TEST_ASSERT_EQUAL(length(worker.settings_read), 1, "Rejected mode cannot read a token or native library")
	TEST_ASSERT_EQUAL(netrun_external_decimal_next("16777216"), "16777217", "Wire sequence does not round at DM float precision")
	TEST_ASSERT_EQUAL(netrun_external_decimal_next("9999999999999999999"), "10000000000000000000", "Carry propagates through decimal text")
	TEST_ASSERT_NULL(netrun_external_decimal_next("18446744073709551615"), "Counter overflow does not wrap")
	TEST_ASSERT(!netrun_external_valid_decimal("01"), "Noncanonical ID is rejected")

/// Команда не обгоняет known facts; would_block сохраняет request ID/payload при новом outer sequence.
/datum/unit_test/netrun_external_core_causal_retry_and_payload/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_external_fixture/fixture = allocate(/datum/netrun_external_fixture, scene)
	var/list/outcomes = list()
	var/list/payload = list("filters" = list(list("id" = "o2", "selected" = TRUE), list("id" = "n2", "selected" = FALSE)), "empty" = list())
	var/datum/netrun_machine_message/message = new /datum/netrun_machine_message/transport_fixture(payload, outcomes)
	fixture.client.queue_fact("{}")
	TEST_ASSERT(fixture.executor.dispatch(fixture.source, fixture.destination, message), "Selected ready executor owns the native message")
	var/datum/netrun_external_request_context/context = fixture.first_context()
	var/request_id = context.request_id
	var/datum/netrun_external_command/first = fixture.executor.request_commands[1]
	var/raw_command = first.raw_json
	var/list/decoded = json_decode(raw_command)
	TEST_ASSERT_EQUAL(json_encode(decoded["payload"]), json_encode(message.payload), "Nested positional filters and empty array keep their JSON shape")
	TEST_ASSERT_NULL(decoded["coalescing_key"], "Generic mutating messages cannot silently coalesce")
	TEST_ASSERT_EQUAL(decoded["traffic_class"], "ordinary", "An ordinary native message cannot opt into communications")
	TEST_ASSERT(!fixture.executor.prepare_input(fixture.client), "Commands wait for source facts")
	fixture.client.send_journal(1, FALSE)
	fixture.client.pending_frame = null
	TEST_ASSERT(fixture.executor.prepare_input(fixture.client), "Drained facts allow one logical command")
	var/first_sequence = fixture.client.pending_sequence
	fixture.executor.observe_result(fixture.client, list("input_sequence" = first_sequence, "admission" = list("status" = "would_block", "code" = "active_capacity")))
	fixture.client.pending_frame = null
	TEST_ASSERT(fixture.executor.prepare_input(fixture.client), "Semantic pressure retries with a new outer sequence")
	TEST_ASSERT(fixture.client.pending_sequence != first_sequence, "Outer sequence is independent from request identity")
	var/list/retry = json_decode(fixture.client.sent_entries[length(fixture.client.sent_entries)])
	var/list/entry = retry[1]
	TEST_ASSERT_EQUAL(entry["request_id"], request_id, "Retry retains producer identity")
	TEST_ASSERT_EQUAL(first.raw_json, raw_command, "Retry does not reserialize mutable payload")
	TEST_ASSERT_EQUAL(fixture.client.native_calls, 0, "The test never calls a real bridge")

/// Повтор invocation не повторяет effect; terminal callback также выполняется один раз.
/datum/unit_test/netrun_external_core_invocation_dedup/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_external_fixture/fixture = allocate(/datum/netrun_external_fixture, scene)
	var/list/outcomes = list()
	TEST_ASSERT(fixture.executor.dispatch(fixture.source, fixture.destination, new /datum/netrun_machine_message/transport_fixture(list("value" = 7), outcomes)), "Message is admitted locally")
	var/datum/netrun_external_request_context/context = fixture.first_context()
	var/request_id = context.request_id
	var/list/invocation = fixture.invocation(context)
	TEST_ASSERT(fixture.receive_result(invocation), "Native invocation passes exact identity checks")
	TEST_ASSERT(fixture.receive_result(invocation), "Duplicate reuses the journal result")
	TEST_ASSERT_EQUAL(fixture.destination.native_calls, 1, "Receive executes exactly once within this binding")
	TEST_ASSERT_EQUAL(length(fixture.executor.control_commands), 1, "A queued result is not duplicated")
	TEST_ASSERT(!outcomes["delivered"] && !outcomes["failed"], "Native receive is distinct from transport completion")
	var/list/completed = fixture.completion(request_id)
	TEST_ASSERT(fixture.receive_result(completed), "Transport terminal completes the original message")
	TEST_ASSERT(fixture.receive_result(completed), "Duplicate terminal is harmless")
	TEST_ASSERT_EQUAL(outcomes["delivered"], 1, "Delivered callback fires once")
	TEST_ASSERT(fixture.receive_result(invocation), "An exact terminal invocation reuses its known result without another effect")
	TEST_ASSERT_EQUAL(fixture.destination.native_calls, 1, "Watermark retirement never revives an old effect")

/// ACK native effect имеет отдельную bounded capacity и не сбрасывает карту при заполненном admission.
/datum/unit_test/netrun_external_core_result_pressure/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_external_fixture/fixture = allocate(/datum/netrun_external_fixture, scene)
	fixture.executor.command_limit = 1
	var/list/outcomes = list()
	TEST_ASSERT(fixture.executor.dispatch(fixture.source, fixture.destination, new /datum/netrun_machine_message/transport_fixture(list("value" = 9), outcomes)), "The request fills the admission budget")
	var/datum/netrun_external_request_context/context = fixture.first_context()
	var/list/invocation = fixture.invocation(context)
	TEST_ASSERT(fixture.receive_result(invocation), "Native output is processed while request capacity is full")
	TEST_ASSERT(fixture.client.ready, "A finished native result must not force binding recovery under admission pressure")
	TEST_ASSERT_EQUAL(length(fixture.executor.control_commands), 1, "Control result has bounded capacity independent from new requests")
	TEST_ASSERT(fixture.receive_result(invocation), "Repeated invocation reuses the queued result")
	TEST_ASSERT_EQUAL(fixture.destination.native_calls, 1, "Pressure cannot repeat the native effect")
	TEST_ASSERT(fixture.executor.prepare_input(fixture.client), "The result is sent ahead of the saturated request queue")
	var/list/sent = json_decode(fixture.client.pending_frame)
	var/list/result = sent[1]
	TEST_ASSERT_EQUAL(result["kind"], "invocation_result", "Capacity is released by the control path first")
	TEST_ASSERT(fixture.receive_result(fixture.completion(context.request_id)), "The final transport outcome still arrives once")
	TEST_ASSERT_EQUAL(outcomes["delivered"], 1, "The original sender receives one completion")

/// Поколение нельзя подменить адресом, а сменившийся native tag отзывает ранее допустимое обращение.
/datum/unit_test/netrun_external_core_native_identity_and_tag/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_external_fixture/fixture = allocate(/datum/netrun_external_fixture, scene)
	var/list/outcomes = list()
	fixture.executor.dispatch(fixture.source, fixture.destination, new /datum/netrun_machine_message/transport_fixture(list("value" = 1), outcomes))
	var/datum/netrun_external_request_context/context = fixture.first_context()
	var/list/invalid = fixture.invocation(context)
	var/list/destination = invalid["destination_service"]
	destination["generation"] = "2"
	TEST_ASSERT(!fixture.receive_result(invalid), "Wrong service generation gets no ACK or native call")
	TEST_ASSERT_EQUAL(fixture.destination.native_calls, 0, "Invalid identity has no effect")
	fixture.destination.native_tag = "changed-tag"
	TEST_ASSERT(fixture.receive_result(fixture.invocation(context)), "Known stale native target yields a typed failure result")
	TEST_ASSERT_EQUAL(fixture.destination.native_calls, 0, "Native tag is rechecked before receive")
	var/datum/netrun_external_command/result = fixture.executor.control_commands[1]
	var/list/decoded = json_decode(result.raw_json)
	TEST_ASSERT(!decoded["success"], "Stale identity cannot be reported as success")

/// Исключение после начала native handler классифицируется unknown, а не разрешением повторить действие.
/datum/unit_test/netrun_external_core_native_exception_unknown/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_external_fixture/fixture = allocate(/datum/netrun_external_fixture, scene)
	var/list/outcomes = list()
	fixture.destination.throw_after_effect = TRUE
	fixture.executor.dispatch(fixture.source, fixture.destination, new /datum/netrun_machine_message/transport_fixture(list("value" = 2), outcomes))
	var/datum/netrun_external_request_context/context = fixture.first_context()
	var/request_id = context.request_id
	var/list/event = fixture.invocation(context)
	TEST_ASSERT(fixture.receive_result(event), "The invocation is journaled before entering handler")
	TEST_ASSERT_EQUAL(fixture.destination.native_calls, 1, "Synthetic effect started once")
	var/datum/netrun_external_command/result = fixture.executor.control_commands[1]
	var/list/decoded = json_decode(result.raw_json)
	TEST_ASSERT_EQUAL(decoded["code"], "outcome_unknown", "Partial native effect is not called a known rejection")
	TEST_ASSERT(!decoded["success"], "An exception cannot claim native success")
	TEST_ASSERT(fixture.receive_result(fixture.completion(request_id, "outcome_unknown", "outcome_unknown")), "Unknown terminal reaches native sender")
	TEST_ASSERT_EQUAL(outcomes["failed"], 1, "Original message gets one terminal callback")
	TEST_ASSERT(!outcomes["delivered"], "Unknown is never successful delivery")

/// Yield callback удерживает message, а потеря binding не отправляет поздний результат новому владельцу.
/datum/unit_test/netrun_external_core_disconnected_yield/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_external_fixture/fixture = allocate(/datum/netrun_external_fixture, scene)
	var/list/outcomes = list()
	var/datum/netrun_machine_message/message = new /datum/netrun_machine_message/transport_fixture(list("value" = 3), outcomes)
	fixture.destination.native_delay = 2 SECONDS
	fixture.executor.dispatch(fixture.source, fixture.destination, message)
	var/datum/netrun_external_request_context/context = fixture.first_context()
	TEST_ASSERT(fixture.receive_result(fixture.invocation(context)), "Async native execution is accepted without blocking output processing")
	TEST_ASSERT(context.executing, "Executing ledger is visible before handler returns")
	fixture.executor.disconnected(fixture.client, "test_disconnect")
	fixture.client.binding_epoch = "new-binding"
	TEST_ASSERT(!QDELETED(message), "Executing native callback retains its message")
	TEST_ASSERT_EQUAL(length(fixture.executor.pending), 1, "Disconnected execution retains its ownership context")
	TEST_ASSERT_EQUAL(fixture.executor.pending_current_count, 0, "Old callback does not count as transport work in a fresh binding")
	TEST_ASSERT(!fixture.executor.has_pending_work(), "Retained old execution does not keep the new IPC session busy")
	fixture.client.last_simulation_time = max(0, round(world.time) - 1)
	TEST_ASSERT(!fixture.executor.prepare_input(fixture.client), "Disconnected execution never emits a clock input into the new Host")
	var/deadline = world.time + 5 SECONDS
	while(length(fixture.executor.pending) && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT_EQUAL(length(fixture.executor.pending), 0, "Callback cleanup completes after its return")
	TEST_ASSERT_EQUAL(fixture.executor.pending_current_count, 0, "Old callback cleanup cannot decrement the fresh binding counter")
	TEST_ASSERT_EQUAL(length(fixture.executor.control_commands), 0, "Old result is never sent in the new binding")
	TEST_ASSERT_EQUAL(outcomes["failed"], 1, "Connection loss returns a single unknown outcome")
	TEST_ASSERT(!outcomes["delivered"], "Lost binding does not claim delivery")

/// Terminal/result ACK освобождает bounded native slot при непрерывной работе, сохраняя dedup и старый pending context.
/datum/unit_test/netrun_external_core_watermark_pressure/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_external_fixture/fixture = allocate(/datum/netrun_external_fixture, scene)
	fixture.executor.invocation_limit = 1
	fixture.executor.terminal_invocation_limit = 1
	fixture.executor.dispatch(fixture.source, fixture.destination, new /datum/netrun_machine_message/transport_fixture(list("value" = 1), list()))
	var/datum/netrun_external_request_context/old = fixture.first_context()
	for(var/index in 1 to 16)
		TEST_ASSERT(fixture.executor.dispatch(fixture.source, fixture.destination, new /datum/netrun_machine_message/transport_fixture(list("value" = index), list())), "Continuous traffic can reuse a completed native slot without global idle")
		var/datum/netrun_external_request_context/newer = fixture.executor.pending[fixture.executor.pending[2]]
		var/request_id = newer.request_id
		var/list/event = fixture.invocation(newer)
		TEST_ASSERT(fixture.receive_result(event), "New native operation executes once")
		TEST_ASSERT(fixture.receive_result(fixture.completion(request_id)), "Later completion is accepted")
		TEST_ASSERT_EQUAL(length(fixture.executor.invocations), 1, "An unacknowledged result still pins its exact record")
		TEST_ASSERT(fixture.executor.prepare_input(fixture.client), "Native result crosses logical input handoff")
		fixture.executor.observe_result(fixture.client, list("input_sequence" = fixture.client.pending_sequence, "action" = list("accepted" = TRUE)))
		fixture.client.pending_frame = null
		TEST_ASSERT_EQUAL(length(fixture.executor.invocations), 0, "Terminal plus result ACK frees its active slot")
		TEST_ASSERT(fixture.receive_result(event), "A late exact terminal invocation is acknowledged without executing it again")
		TEST_ASSERT_EQUAL(fixture.destination.native_calls, index, "Replay cannot repeat native effects")
		TEST_ASSERT_EQUAL(length(fixture.executor.terminal_invocations), 1, "Retired fingerprints remain bounded")
	TEST_ASSERT(fixture.receive_result(fixture.completion(old.request_id, "cancelled", "cancelled")), "Last old context closes the conservative watermark")
	TEST_ASSERT_EQUAL(length(fixture.executor.invocations), 0, "No ACKed active invocation survives idle")
	TEST_ASSERT_EQUAL(fixture.executor.retired_sequence, "17", "Watermark never skips a still pending older request")

/// Native узел не исполняет effect по пути, пока известный transit факт ещё не подтверждён Host.
/datum/unit_test/netrun_external_core_infrastructure_final_gate/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_external_fixture/fixture = allocate(/datum/netrun_external_fixture, scene)
	fixture.client.queue_fact("{}", TRUE)
	fixture.executor.dispatch(fixture.source, fixture.destination, new /datum/netrun_machine_message/transport_fixture(list(), list()))
	var/datum/netrun_external_request_context/context = fixture.first_context()
	TEST_ASSERT(fixture.receive_result(fixture.invocation(context)), "A valid invocation gets one known native result")
	TEST_ASSERT_EQUAL(fixture.destination.native_calls, 0, "Unacknowledged transit change cannot execute native effects")
	var/datum/netrun_external_command/command = fixture.executor.control_commands[1]
	var/list/body = json_decode(command.raw_json)
	TEST_ASSERT(!body["success"], "Pending transit authority is a known non-execution")

/// Уже сериализованный invocation не получает новую transit authority после прихода свежих hints.
/datum/unit_test/netrun_external_core_serialized_authority_proof/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_external_fixture/fixture = allocate(/datum/netrun_external_fixture, scene)
	fixture.executor.dispatch(fixture.source, fixture.destination, new /datum/netrun_machine_message/transport_fixture(list(), list()))
	var/datum/netrun_external_request_context/context = fixture.first_context()
	var/list/event = fixture.invocation(context)
	fixture.executor.latest_infra_stamp = "1"
	TEST_ASSERT(fixture.receive_result(event), "Stale serialized proof returns a known native refusal")
	TEST_ASSERT_EQUAL(fixture.destination.native_calls, 0, "Endpoint equality does not replace an old transit proof")

/// Yield в native accepts не переносит authority старого binding за границу actual receive.
/datum/unit_test/netrun_external_core_accepts_yield_final_gate/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_external_fixture/fixture = allocate(/datum/netrun_external_fixture, scene)
	fixture.destination.accepts_delay = world.tick_lag * 2
	fixture.executor.dispatch(fixture.source, fixture.destination, new /datum/netrun_machine_message/transport_fixture(list(), list()))
	var/datum/netrun_external_request_context/context = fixture.first_context()
	TEST_ASSERT(fixture.receive_result(fixture.invocation(context)), "Native acceptance is asynchronous")
	TEST_ASSERT(context.executing, "Acceptance is suspended before the effect")
	fixture.client.binding_epoch = "replacement-binding"
	var/deadline = world.time + 2 SECONDS
	while(!QDELETED(context) && context.executing && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT_EQUAL(fixture.destination.native_calls, 0, "A stale binding cannot execute after accepts returns")

/datum/unit_test/netrun_external_core_pending_clock_tick/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_external_fixture/fixture = allocate(/datum/netrun_external_fixture, scene)
	fixture.executor.dispatch(fixture.source, fixture.destination, new /datum/netrun_machine_message/transport_fixture(list(), list()))
	fixture.executor.prepare_input(fixture.client)
	fixture.executor.observe_result(fixture.client, list("input_sequence" = fixture.client.pending_sequence, "admission" = list("status" = "accepted", "code" = "accepted")))
	fixture.client.pending_frame = null
	fixture.client.last_simulation_time = max(0, round(world.time) - 1)
	TEST_ASSERT(fixture.executor.prepare_input(fixture.client), "Pending transport emits a BYOND-time tick even without changes")
	TEST_ASSERT_EQUAL(fixture.client.pending_frame, "\[\]", "Clock-only input contains no synthetic world mutation")

/// Размер проверяется дёшево локально; semantic отказ Host сохраняет binding остальных запросов.
/datum/unit_test/netrun_external_core_payload_limits/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_external_fixture/fixture = allocate(/datum/netrun_external_fixture, scene)
	var/list/outcomes = list()
	var/list/large = list("text" = repeat_string(131073, "A"))
	TEST_ASSERT(!fixture.executor.dispatch(fixture.source, fixture.destination, new /datum/netrun_machine_message/transport_fixture(large, outcomes)), "Wire size refuses only this message")
	TEST_ASSERT_EQUAL(length(fixture.executor.pending), 0, "Local size refusal has no native context")
	TEST_ASSERT_EQUAL(fixture.executor.request_serial, "0", "Local size refusal consumes no producer identity")
	TEST_ASSERT_EQUAL(outcomes["failed"], 1, "Size refusal reports one terminal callback")
	var/list/items = list()
	items.len = 1025
	outcomes = list()
	TEST_ASSERT(fixture.executor.dispatch(fixture.source, fixture.destination, new /datum/netrun_machine_message/transport_fixture(items, outcomes)), "DM does not rescan JSON containers in the game thread")
	TEST_ASSERT(fixture.executor.prepare_input(fixture.client), "Request reaches the Host admission boundary")
	fixture.executor.observe_result(fixture.client, list("input_sequence" = fixture.client.pending_sequence, "admission" = list("status" = "rejected", "code" = "invalid_payload")))
	TEST_ASSERT_EQUAL(outcomes["failed"], 1, "Host semantic refusal reports one terminal callback")
	TEST_ASSERT_EQUAL(length(fixture.executor.pending), 0, "Rejected payload releases its own context")
	TEST_ASSERT(fixture.client.ready, "Other requests keep the same live binding")
	fixture.client.pending_frame = null
	TEST_ASSERT(fixture.executor.dispatch(fixture.source, fixture.destination, new /datum/netrun_machine_message/transport_fixture(list("small" = TRUE), list())), "A following valid message uses the same binding")
	TEST_ASSERT_EQUAL(fixture.destination.native_calls, 0, "Rejected payload never reaches native receive")

/// Один runtime_result может сопровождать 64 events; только целый frame передвигает output ACK.
/datum/unit_test/netrun_external_core_output_65/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_external_fixture/fixture = allocate(/datum/netrun_external_fixture, scene)
	var/list/results = list()
	for(var/index in 1 to 65)
		results += "{\"kind\":\"diagnostics\"}"
	var/list/frame = list("kind" = json_encode("output"), "world_epoch" = json_encode(fixture.client.world_epoch), "engine_epoch" = json_encode(fixture.client.engine_epoch), "binding_epoch" = json_encode(fixture.client.binding_epoch), "output_sequence" = json_encode("1"), "applied_sequence" = json_encode("0"), "results" = netrun_external_json_array(results))
	TEST_ASSERT(fixture.client.process_frame(netrun_external_json_object(frame)), "Host's runtime_result plus 64 events fits the client envelope")
	TEST_ASSERT_EQUAL(fixture.client.ack_output_sequence, "1", "All 65 known entries advance one output ACK")
	results += "{\"kind\":\"diagnostics\"}"
	frame["output_sequence"] = json_encode("2")
	frame["results"] = netrun_external_json_array(results)
	TEST_ASSERT(!fixture.client.process_frame(netrun_external_json_object(frame)), "Larger output is rejected before dispatch")
	TEST_ASSERT_EQUAL(fixture.client.ack_output_sequence, "1", "Rejected oversized frame receives no ACK")

/// Native metadata сохраняет directed links и фильтры, а unsupported/oversized port снимает только capability.
/datum/unit_test/netrun_external_core_communication_facts/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_external_fixture/fixture = allocate(/datum/netrun_external_fixture, scene)
	var/obj/machinery/telecomms/hub/hub = scene.machine(/obj/machinery/telecomms/hub, scene.source_spot)
	var/obj/machinery/telecomms/relay/relay = scene.machine(/obj/machinery/telecomms/relay, scene.target_spot)
	hub.links = list(relay, relay)
	hub.freq_listening = list(1459, 1459, 1461)
	var/datum/netrun_machine_service/service = hub.get_netrun_machine_service("telecomms.relay")
	TEST_ASSERT(service, "Real hub advertises an existing native service")
	var/list/fact = json_decode(fixture.client.export_service(service, TRUE))
	var/list/port = fact["communication"]
	TEST_ASSERT_EQUAL(port?["kind"], "hub", "Only native hub/relay roles receive communication metadata")
	TEST_ASSERT_EQUAL(length(port["listening_frequencies"]), 2, "Native set duplicates do not duplicate filter entries")
	var/list/links = port["configured_links"]
	TEST_ASSERT_EQUAL(length(links), 1, "Directed native links are exported once")
	var/list/link = links[1]
	var/list/key = fixture.client.node_key(relay.GetComponent(/datum/component/netrun_node))
	TEST_ASSERT_EQUAL(link["node_id"], key["id"], "Link target is exact existing component identity")
	TEST_ASSERT(findtext(fixture.client.export_communication(service), "\"on\":true") || findtext(fixture.client.export_communication(service), "\"on\":false"), "Wire booleans are JSON booleans")
	hub.freq_listening = list(1459, 0)
	fact = json_decode(fixture.client.export_service(service, TRUE))
	TEST_ASSERT_NULL(fact["communication"], "Invalid filter cannot widen to the unrestricted empty set")
	TEST_ASSERT_EQUAL(fact["family"], "telecomms.relay", "Removing capability preserves the ordinary service")

/// Overlay opt-in требует одновременно native message type и allowlisted service families.
/datum/unit_test/netrun_external_core_communication_traffic/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_external_fixture/fixture = allocate(/datum/netrun_external_fixture, scene)
	fixture.source.service_id = "communications.gateway"
	fixture.destination.service_id = "communications.console"
	TEST_ASSERT(fixture.executor.dispatch(fixture.source, fixture.destination, new /datum/netrun_machine_message/communications(list("operation" = "fixture"))), "Allowlisted native communication message is locally queued")
	var/datum/netrun_external_command/command = fixture.executor.request_commands[1]
	var/list/request = json_decode(command.raw_json)
	TEST_ASSERT_EQUAL(request["traffic_class"], "communications", "Native communications can request the isolated overlay")
	TEST_ASSERT_NULL(request["frequency"], "Non-radio native messages carry an unrestricted control frequency")

/// Real admission responses retain the first request while transferring only newest native state.
/datum/unit_test/netrun_external_core_state_coalescing/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_external_fixture/fixture = allocate(/datum/netrun_external_fixture, scene)
	var/datum/netrun_machine_message/research/original = new(list("operation" = "snapshot", "binding" = "fixture", "generation" = 1, "revision" = 12))
	var/datum/netrun_external_request_context/retained = fixture.admit_pair(fixture.source, fixture.destination, original)
	retained.stage = "accepted"
	var/retained_id = retained.request_id
	for(var/revision in list(13, 11, 13))
		var/datum/netrun_machine_message/research/replacement = new(list("operation" = "snapshot", "binding" = "fixture", "generation" = 1, "revision" = revision))
		var/datum/netrun_external_request_context/incoming = fixture.admit_pair(fixture.source, fixture.destination, replacement)
		var/incoming_id = incoming.request_id
		var/datum/netrun_external_command/command = fixture.executor.request_commands[length(fixture.executor.request_commands)]
		var/list/wire = json_decode(command.raw_json)
		TEST_ASSERT_EQUAL(wire["operation_id"], "state", "Replaceable state has a distinct idempotent contract")
		TEST_ASSERT_EQUAL(wire["state_revision"], num2text(revision + 1, 20), "Native revision zero is representable by the positive wire contract")
		fixture.executor.request_commands -= command
		fixture.executor.inflight_commands["1"] = command
		fixture.executor.observe_result(fixture.client, list("input_sequence" = "1", "admission" = list("status" = "coalesced", "coalesced_into" = retained_id)))
		TEST_ASSERT_EQUAL(retained.request_id, retained_id, "Coalescing preserves the original wire request identity")
		TEST_ASSERT_EQUAL(retained.message.payload["revision"], 13, "A stale revision cannot replace the newest native payload")
		TEST_ASSERT_NULL(incoming.message, "Superseded request no longer owns the retained message")
		TEST_ASSERT(fixture.receive_result(fixture.completion(incoming_id, "superseded", "coalesced")), "Superseded terminal releases its own native slot")
	TEST_ASSERT(QDELETED(original), "Replaced state releases its original native message")
	var/list/invocation = fixture.invocation(retained)
	TEST_ASSERT(fixture.receive_result(invocation), "Original wire ID executes the newest exact payload and context")
	TEST_ASSERT_EQUAL(fixture.destination.native_calls, 1, "Only the final state executes")
	TEST_ASSERT(fixture.receive_result(fixture.completion(retained_id)), "Original terminal completes the retained state")
	TEST_ASSERT(fixture.receive_result(invocation), "Invocation replay cannot repeat the state effect")
	TEST_ASSERT_EQUAL(fixture.destination.native_calls, 1, "Coalescing preserves exactly once native execution")
	TEST_ASSERT_EQUAL(length(fixture.executor.pending), 0, "Both retained and superseded slots drain")
	TEST_ASSERT_EQUAL(fixture.executor.pending_current_count, 0, "Coalesced and original completion release their current binding slots once")
