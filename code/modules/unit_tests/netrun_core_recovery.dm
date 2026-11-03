/// Fake clock/config исключают реальные ENV, secret files, native bridge и background workers из recovery cases.
/datum/controller/subsystem/netrun/recovery_fixture
	flags = SS_NO_INIT | SS_NO_FIRE
	/// Только публичный fixture token; production reader в этом subtype не вызывается.
	var/token_text = "fixture-token-not-a-production-secret-1234"
	var/list/settings = list("NETRUN_CORE_MODE" = "external", "NETRUN_CORE_PORT" = "18462", "NETRUN_CORE_LIBRARY" = "fixture-bridge", "NETRUN_CORE_TOKEN_FILE" = "fixture-file")
	var/config_reads = 0
	var/token_reads = 0
	var/clients_created = 0
	/// Виртуальный timeofday задаётся тестом, не меняя game clock или глобальные world настройки.
	var/now = 1000
	var/allow_open = TRUE

/// Fixture subsystem не регистрируется в Master.
/datum/controller/subsystem/netrun/recovery_fixture/New()
	return

/// Assertion failure также освобождает fixture client/effects, не оставляя signal subscriptions между cases.
/datum/controller/subsystem/netrun/recovery_fixture/Destroy()
	if(!QDELETED(external_core))
		external_core.close("fixture_cleanup")
		qdel(external_core.effects)
		qdel(external_core)
	external_core = null
	return ..()

/// Config lookup остаётся явным и подсчитываемым.
/datum/controller/subsystem/netrun/recovery_fixture/external_setting(name)
	config_reads++
	return settings[name]

/// Физический backoff проверяется без sleep.
/datum/controller/subsystem/netrun/recovery_fixture/external_now()
	return now

/// File I/O заменён только в test seam.
/datum/controller/subsystem/netrun/recovery_fixture/read_external_token(token_file)
	token_reads++
	return token_text

/// Реальный machine lifecycle сохраняется, а C ABI полностью заменён fake client.
/datum/controller/subsystem/netrun/recovery_fixture/create_external_client()
	clients_created++
	var/datum/netrun_external_core/recovery_fixture/client = new(src)
	client.effects = new /datum/netrun_external_effects/machines/recovery_fixture(src)
	return client

/// Считает disconnect callbacks настоящего machines executor, не заменяя его ownership cleanup.
/datum/netrun_external_effects/machines/recovery_fixture
	var/disconnect_count = 0
	var/list/observed_fact_prefixes = list()
	var/list/observed_infrastructure = list()

/// Close/abort одной сессии не должен повторять native callbacks.
/datum/netrun_external_effects/machines/recovery_fixture/disconnected(datum/netrun_external_core/client, reason)
	disconnect_count++
	return ..()

/// Только fixture-kind проверяет порядок fact ACK и effect dispatch настоящего output decoder.
/datum/netrun_external_effects/machines/recovery_fixture/process_result(datum/netrun_external_core/client, list/result)
	if(result["kind"] == "fixture_effect")
		observed_fact_prefixes += client.fact_acknowledged
		observed_infrastructure += client.infrastructure_facts_ready()
		return TRUE
	return ..()

/// Fake open меняет только session metadata; snapshots и sector bookkeeping остаются production кодом.
/datum/netrun_external_core/recovery_fixture
	var/open_count = 0
	var/native_calls = 0
	var/list/levels = list(10)

/// Переоткрытие сохраняет world epoch, создаёт новый binding и никогда не вызывает DLL.
/datum/netrun_external_core/recovery_fixture/open(bridge_library, port, token, world_id = null)
	open_count++
	var/datum/controller/subsystem/netrun/recovery_fixture/worker = owner
	if(!worker.allow_open)
		last_error = "fixture_open_failed"
		return FALSE
	world_epoch = world_id || world_epoch || "recovery-world"
	binding_epoch = "recovery-[open_count]"
	engine_epoch = null
	id_serial = "0"
	input_sequence = "0"
	sent_input_sequence = "0"
	ack_output_sequence = "0"
	last_applied_sequence = "0"
	journal_sequence = "0"
	fact_tail = "0"
	fact_consumed = "0"
	fact_acknowledged = "0"
	infrastructure_barrier = "0"
	effects_disconnected = FALSE
	library_path = bridge_library
	state = "connecting"
	ready = FALSE
	return TRUE

/// Даже close в fixture не обращается к native API.
/datum/netrun_external_core/recovery_fixture/native_call(export_name, list/arguments)
	native_calls++
	return list("state" = "closed", "code" = "closed", "frames" = list())

/// Poll cadence exercises the real tick/enqueue path without socket I/O or wall-clock sleeps.
/datum/netrun_external_core/recovery_fixture/polling
	var/list/responses = list()
	var/list/accepted_bodies = list()
	var/list/attempted_bodies = list()
	var/list/poll_frame_limits = list()
	var/reject_enqueues = FALSE

/datum/netrun_external_core/recovery_fixture/polling/native_call(export_name, list/arguments)
	native_calls++
	var/list/frames = list()
	if(export_name == "netrun_poll")
		var/limit = text2num(arguments[1])
		poll_frame_limits += limit
		var/count = min(length(responses), limit)
		frames = responses.Copy(1, count + 1)
		responses.Cut(1, count + 1)
	if(export_name == "netrun_try_enqueue")
		attempted_bodies += arguments[1]
		if(reject_enqueues)
			return list("state" = "connected", "code" = "would_block", "frames" = frames)
		accepted_bodies += arguments[1]
	return list("state" = "connected", "code" = export_name == "netrun_try_enqueue" ? "accepted" : "ok", "frames" = frames)

/// Один owned fake peer с настоящими enqueue/ledger/decoder, без DLL или отдельного Host.
/datum/controller/subsystem/netrun/recovery_fixture/proc/polling_client()
	var/datum/netrun_external_core/recovery_fixture/polling/client = new(src)
	external_core = client
	client.effects = new /datum/netrun_external_effects/machines/recovery_fixture(src)
	client.world_epoch = "poll-world"
	client.engine_epoch = "poll-engine"
	client.binding_epoch = "poll-binding"
	client.state = "ready"
	client.ready = TRUE
	return client

/datum/unit_test/netrun_core_recovery_idle_poll/Run()
	var/datum/controller/subsystem/netrun/recovery_fixture/worker = allocate(/datum/controller/subsystem/netrun/recovery_fixture)
	var/datum/netrun_external_core/recovery_fixture/polling/client = worker.polling_client()
	client.tick()
	TEST_ASSERT_EQUAL(client.sent_frames, 1, "One ACK-only heartbeat is admitted without a logical input")
	var/list/heartbeat = json_decode(client.accepted_bodies[1])
	TEST_ASSERT_EQUAL(heartbeat["kind"], "poll", "The heartbeat carries the cumulative output ACK")
	TEST_ASSERT_EQUAL(heartbeat["max_events"], 0, "ACK-only does not ask Host for an empty response")
	TEST_ASSERT_EQUAL(client.input_sequence, "0", "A heartbeat never advances the causal input clock")
	TEST_ASSERT_EQUAL(length(client.inflight_frames), 0, "ACK-only consumes no input-window credit")
	TEST_ASSERT(client.needs_fast_tick(), "The active duplex receiver consumes unsolicited output at tick cadence")
	client.tick()
	TEST_ASSERT_EQUAL(client.sent_frames, 1, "No Host reply means no empty output/ACK ping-pong")
	client.responses += client.output_body("0")
	client.tick()
	TEST_ASSERT_EQUAL(client.ack_output_sequence, "1", "Unsolicited output is processed without an outstanding poll request")
	TEST_ASSERT_EQUAL(client.sent_frames, 2, "The processed output releases Host credit with one independent ACK")
	client.tick()
	TEST_ASSERT_EQUAL(client.sent_frames, 2, "The ACK does not require another response")
	client.last_poll_at = world.timeofday - NETRUN_DEFAULT_FIRE_INTERVAL
	if(client.last_poll_at < 0)
		client.last_poll_at += 864000
	client.tick()
	TEST_ASSERT_EQUAL(client.sent_frames, 3, "The physical maintenance deadline admits another response-free heartbeat")
	client.close("fixture_cleanup")
	TEST_ASSERT_NULL(client.last_poll_at, "A new binding does not inherit the previous heartbeat deadline")
	TEST_ASSERT(!client.needs_fast_tick(), "A closed connection stops its receiver cadence")

/datum/unit_test/netrun_core_recovery_host_error/Run()
	var/datum/controller/subsystem/netrun/recovery_fixture/worker = allocate(/datum/controller/subsystem/netrun/recovery_fixture)
	var/datum/netrun_external_core/recovery_fixture/client = worker.journal_client()
	TEST_ASSERT(!client.process_frame(json_encode(list("kind" = "error", "code" = "authentication_failed"))), "Host refusal closes the binding")
	TEST_ASSERT_EQUAL(client.last_error, "authentication_failed", "The actual safe refusal code survives diagnosis")
	worker.now += worker.external_retry_wait
	client = worker.journal_client()
	TEST_ASSERT(!client.process_frame(json_encode(list("kind" = "error", "code" = "untrusted payload text"))), "Malformed diagnostics are still rejected")
	TEST_ASSERT_EQUAL(client.last_error, "host_rejected", "Arbitrary text is never copied into diagnostics")

/// Геометрия задаётся как raw native connected levels, без глобального mapping или graph solver.
/datum/netrun_external_core/recovery_fixture/sector_levels(z)
	return levels

/// Только journal cases имитируют уже завершённый handshake; transport/socket остаётся fake.
/datum/controller/subsystem/netrun/recovery_fixture/proc/journal_client()
	var/datum/netrun_external_core/recovery_fixture/client = ensure_external_core()
	client.state = "ready"
	client.ready = TRUE
	client.engine_epoch = "journal-engine"
	return client

/// Формирует output для конкретного принятого prefix; не подменяет настоящий decoder.
/datum/netrun_external_core/recovery_fixture/proc/output_body(through = null, raw_results = "\[\]", output_counter = null)
	return netrun_external_json_object(list("kind" = json_encode("output"), "world_epoch" = json_encode(world_epoch), "engine_epoch" = json_encode(engine_epoch), "binding_epoch" = json_encode(binding_epoch), "output_sequence" = json_encode(output_counter || netrun_external_decimal_next(ack_output_sequence)), "applied_sequence" = json_encode(isnull(through) ? sent_input_sequence : through), "results" = raw_results))

/// Bridge accepted и Host applied являются разными шагами, даже когда fixture делает оба подряд.
/datum/netrun_external_core/recovery_fixture/proc/ack_pending(through = null, raw_results = "\[\]")
	if(pending_frame && !mark_pending_accepted())
		return FALSE
	return process_frame(output_body(through, raw_results))

/// Duplex receive не зависит от наличия ожидаемого request/reply и прекращается только при close.
/datum/unit_test/netrun_core_recovery_pending_cadence/Run()
	var/datum/controller/subsystem/netrun/recovery_fixture/worker = allocate(/datum/controller/subsystem/netrun/recovery_fixture)
	var/datum/netrun_external_core/recovery_fixture/client = worker.journal_client()
	worker.next_node_deadline = INFINITY
	worker.refresh_delivery_interval()
	TEST_ASSERT_EQUAL(worker.wait, world.tick_lag, "A ready idle connection still receives asynchronous Host events")
	TEST_ASSERT(client.enqueue("\[\]", 0), "An empty clock input can be the last pending frame")
	worker.refresh_delivery_interval()
	TEST_ASSERT_EQUAL(worker.wait, world.tick_lag, "A pending application ACK keeps the worker at tick cadence")
	TEST_ASSERT(client.ack_pending(), "Host acknowledges the last input")
	worker.refresh_delivery_interval()
	TEST_ASSERT_EQUAL(worker.wait, world.tick_lag, "Draining input credit preserves permanent push reception")
	client.close("fixture_cleanup")
	worker.refresh_delivery_interval()
	TEST_ASSERT_EQUAL(worker.wait, NETRUN_DEFAULT_FIRE_INTERVAL, "Closing duplex restores the quiet subsystem interval")

/// Несколько independently sequenced кадров принимаются до первого ACK; credit возвращается по целому prefix.
/datum/unit_test/netrun_core_recovery_pipeline_window/Run()
	var/datum/controller/subsystem/netrun/recovery_fixture/worker = allocate(/datum/controller/subsystem/netrun/recovery_fixture)
	var/datum/netrun_external_core/recovery_fixture/client = worker.journal_client()
	client.max_inflight_frames = 8
	for(var/index in 1 to 8)
		TEST_ASSERT(client.enqueue("\[\]", 0), "Another frame can stage without waiting for earlier application ACK")
		TEST_ASSERT(client.mark_pending_accepted(), "Bridge accepts each independently sequenced frame")
		TEST_ASSERT_NULL(client.pending_frame, "Accepted ledger never retains the serialized JSON body")
	TEST_ASSERT_EQUAL(length(client.inflight_frames), 8, "The configured sliding window bounds outstanding frames")
	TEST_ASSERT_EQUAL(client.sent_input_sequence, "8", "Only bridge-accepted frames extend the ACK upper bound")
	TEST_ASSERT(!client.can_enqueue(), "A full sender window stops only further enqueue")
	TEST_ASSERT(!client.enqueue("\[\]", 0), "No hidden ninth frame is staged beyond credit")
	TEST_ASSERT_EQUAL(client.input_sequence, "8", "Refused enqueue consumes no sequence")
	var/partial = client.output_body("3")
	TEST_ASSERT(client.process_frame(partial), "A cumulative ACK releases its complete prefix")
	TEST_ASSERT_EQUAL(length(client.inflight_frames), 5, "Only the first three frame credits return")
	TEST_ASSERT_EQUAL(client.inflight_frames[1], "4", "Unacknowledged tail remains in FIFO order")
	TEST_ASSERT(client.process_frame(partial), "Exact output replay remains idempotent")
	TEST_ASSERT_EQUAL(length(client.inflight_frames), 5, "Duplicate output does not release credit twice")
	TEST_ASSERT(client.can_enqueue(), "Processing ACK permits more work without draining every request")
	TEST_ASSERT(client.enqueue("\[\]", 0), "The sender refills released credit")
	TEST_ASSERT(client.mark_pending_accepted(), "The later frame follows the retained tail")
	TEST_ASSERT_EQUAL(client.sent_input_sequence, "9", "Refill preserves monotonically increasing sequence")
	TEST_ASSERT(client.ack_pending(), "One cumulative output can acknowledge the remaining mixed-age tail")
	TEST_ASSERT_EQUAL(length(client.inflight_frames), 0, "All acknowledged ledger entries are released")
	TEST_ASSERT_EQUAL(client.inflight_frame_bytes, 0, "Byte credit returns exactly once")

/// Fact-prefix ACK обновляет authority до dispatch любого native result в том же выходном кадре.
/datum/unit_test/netrun_core_recovery_pipeline_fact_ack_order/Run()
	var/datum/controller/subsystem/netrun/recovery_fixture/worker = allocate(/datum/controller/subsystem/netrun/recovery_fixture)
	var/datum/netrun_external_core/recovery_fixture/client = worker.journal_client()
	var/datum/netrun_external_effects/machines/recovery_fixture/executor = client.effects
	for(var/index in 1 to 3)
		TEST_ASSERT(client.queue_fact("{}", index != 2), "Each raw fact occupies its own causal prefix")
		TEST_ASSERT(client.send_journal(1, FALSE), "A later journal frame can follow an unacknowledged one")
		TEST_ASSERT(client.mark_pending_accepted(), "The fact frame enters the ordered bridge stream")
	TEST_ASSERT_EQUAL(client.fact_consumed, "3", "All facts have been handed to the ordered stream")
	TEST_ASSERT_EQUAL(client.fact_acknowledged, "0", "Bridge acceptance alone never grants native authority")
	var/effect = netrun_external_json_array(list("{\"kind\":\"fixture_effect\"}"))
	TEST_ASSERT(client.ack_pending("1", effect), "A partial cumulative ACK dispatches its correlated result")
	TEST_ASSERT_EQUAL(executor.observed_fact_prefixes[1], "1", "Effect dispatch sees the prefix applied by this output")
	TEST_ASSERT_EQUAL(executor.observed_infrastructure[1], FALSE, "A later known infrastructure change remains fenced")
	TEST_ASSERT_EQUAL(length(client.inflight_frames), 2, "Unapplied fact frames retain their own metadata")
	TEST_ASSERT(client.ack_pending("3", effect), "A later output acknowledges multiple fact frames together")
	TEST_ASSERT_EQUAL(executor.observed_fact_prefixes[2], "3", "All cumulatively applied fact prefixes precede effect dispatch")
	TEST_ASSERT_EQUAL(executor.observed_infrastructure[2], TRUE, "The current infrastructure proof opens only after its actual ACK")
	TEST_ASSERT_EQUAL(length(client.inflight_frames), 0, "Fact metadata is removed after cumulative application")

/// Native backpressure сохраняет только один immutable staged body; повтор не меняет порядок или accounting.
/datum/unit_test/netrun_core_recovery_pipeline_bridge_backpressure/Run()
	var/datum/controller/subsystem/netrun/recovery_fixture/worker = allocate(/datum/controller/subsystem/netrun/recovery_fixture)
	var/datum/netrun_external_core/recovery_fixture/polling/client = worker.polling_client()
	TEST_ASSERT(client.enqueue("\[\]", 0), "The first logical frame stages independently")
	var/first_body = client.pending_frame
	var/first_bytes = client.pending_frame_bytes
	client.reject_enqueues = TRUE
	TEST_ASSERT(!client.flush_pending(), "Bridge pressure defers submission without blocking")
	TEST_ASSERT(!client.flush_pending(), "The same immutable frame can retry native enqueue")
	TEST_ASSERT_EQUAL(client.pending_frame, first_body, "Backpressure never reserializes the frame")
	TEST_ASSERT_EQUAL(client.input_sequence, "1", "Repeated bridge attempts consume no new logical sequence")
	TEST_ASSERT_EQUAL(client.sent_input_sequence, "0", "An unsent frame cannot be acknowledged by Host")
	TEST_ASSERT_EQUAL(length(client.inflight_frames), 0, "Unaccepted staging consumes no accepted-frame credit")
	TEST_ASSERT(!client.enqueue("\[\]", 0), "A later frame cannot overtake unaccepted staging")
	client.reject_enqueues = FALSE
	TEST_ASSERT(client.flush_pending(), "Native acceptance transfers staging into compact metadata")
	TEST_ASSERT_EQUAL(client.accepted_bodies[1], first_body, "The exact earlier body is sent first")
	TEST_ASSERT_NULL(client.pending_frame, "The bridge owns the accepted JSON body")
	TEST_ASSERT(client.enqueue("\[\]", 0), "A second frame stages before the first application ACK")
	var/second_body = client.pending_frame
	var/second_bytes = client.pending_frame_bytes
	TEST_ASSERT(client.flush_pending(), "The next independently sequenced body enters the bridge")
	TEST_ASSERT_EQUAL(client.accepted_bodies[2], second_body, "Native acceptance preserves FIFO across retries")
	TEST_ASSERT_EQUAL(client.inflight_frame_bytes, first_bytes + second_bytes, "Only accepted reservations contribute to window bytes")
	client.close("fixture_cleanup")
	TEST_ASSERT_EQUAL(length(client.inflight_frames), 0, "Close releases every accepted frame entry")
	TEST_ASSERT_EQUAL(client.inflight_frame_bytes, 0, "Close releases accepted byte reservations")
	TEST_ASSERT_EQUAL(client.pending_frame_bytes, 0, "Close releases staging bytes")
	TEST_ASSERT_EQUAL(client.sent_input_sequence, "0", "A fresh binding cannot inherit the old accepted sequence")

/// Большие кадры ограничены byte credit раньше frame count; ledger не удерживает их raw bodies.
/datum/unit_test/netrun_core_recovery_pipeline_byte_window/Run()
	var/datum/controller/subsystem/netrun/recovery_fixture/worker = allocate(/datum/controller/subsystem/netrun/recovery_fixture)
	var/datum/netrun_external_core/recovery_fixture/client = worker.journal_client()
	client.max_inflight_frames = 8
	client.max_inflight_bytes = 4194304
	var/text = "x"
	for(var/index in 1 to 17)
		text += text
	var/entries = netrun_external_json_array(list("{\"opaque\":[json_encode(text)]}"))
	while(client.can_enqueue())
		TEST_ASSERT(client.enqueue(entries), "A serialized test entry fits the per-frame reservation")
		TEST_ASSERT(client.mark_pending_accepted(), "Accepted bytes enter the bounded window")
	TEST_ASSERT(length(client.inflight_frames) < client.max_inflight_frames, "Byte capacity can stop a burst before the frame-count limit")
	TEST_ASSERT(client.inflight_frame_bytes <= 4194304, "Accepted reservations never exceed four MiB")
	TEST_ASSERT(client.ack_pending(), "Cumulative application releases the byte-limited window")
	TEST_ASSERT_EQUAL(client.inflight_frame_bytes, 0, "No serialized payload remains in accepted-frame metadata")

/// Watchdog учитывает input ACK, а не произвольную активность Host; queued ACK обрабатывается до deadline check.
/datum/unit_test/netrun_core_recovery_pipeline_ack_watchdog/Run()
	var/datum/controller/subsystem/netrun/recovery_fixture/worker = allocate(/datum/controller/subsystem/netrun/recovery_fixture)
	var/datum/netrun_external_core/recovery_fixture/polling/client = worker.polling_client()
	client.ack_timeout = 100
	TEST_ASSERT(client.enqueue("\[\]", 0), "One logical input is staged")
	TEST_ASSERT(client.flush_pending(), "The input starts its application watchdog")
	client.last_input_progress_at = world.timeofday - 101
	if(client.last_input_progress_at < 0)
		client.last_input_progress_at += 864000
	var/stalled_at = client.last_input_progress_at
	TEST_ASSERT(client.process_frame(client.output_body("0")), "Unsolicited push can arrive while the input is still pending")
	TEST_ASSERT_EQUAL(client.last_input_progress_at, stalled_at, "Unrelated push never refreshes input progress")
	client.responses += client.output_body("1")
	client.tick()
	while(client.output_pump_binding)
		sleep(world.tick_lag)
	TEST_ASSERT_EQUAL(client.state, "ready", "A queued valid ACK survives a delayed MC pass")
	TEST_ASSERT_EQUAL(client.last_applied_sequence, "1", "The pending input is acknowledged before watchdog evaluation")
	TEST_ASSERT_EQUAL(client.poll_frame_limits[length(client.poll_frame_limits)], 128, "The ABI read batch does not throttle permanent receive processing")
	TEST_ASSERT(client.enqueue("\[\]", 0), "Another input can use the released credit")
	TEST_ASSERT(client.flush_pending(), "The later input starts an independent progress deadline")
	client.last_input_progress_at = world.timeofday - 101
	if(client.last_input_progress_at < 0)
		client.last_input_progress_at += 864000
	client.responses += client.output_body("1")
	client.tick()
	var/timeout_deadline = world.time + 2 SECONDS
	while(client.state == "ready" && world.time < timeout_deadline)
		sleep(world.tick_lag)
		client.tick()
	TEST_ASSERT_EQUAL(client.last_error, "host_ack_timeout", "A stream of push without input progress cannot hide a stalled request")
	TEST_ASSERT_EQUAL(client.state, "resync_required", "Expired input ownership closes the old binding safely")

/// Host не может подтвердить staged sequence, который native bridge ещё не принял.
/datum/unit_test/netrun_core_recovery_pipeline_reject_unsent_ack/Run()
	var/datum/controller/subsystem/netrun/recovery_fixture/worker = allocate(/datum/controller/subsystem/netrun/recovery_fixture)
	var/datum/netrun_external_core/recovery_fixture/client = worker.journal_client()
	TEST_ASSERT(client.enqueue("\[\]", 0), "The first frame receives an allocated sequence")
	TEST_ASSERT(!client.process_frame(client.output_body(client.input_sequence)), "An unsent input is outside the cumulative ACK bound")
	TEST_ASSERT_EQUAL(client.last_error, "invalid_output_sequence", "The protocol violation has a safe diagnostic")
	TEST_ASSERT_NULL(client.pending_frame, "Resync drops unaccepted staging ownership")

/// Startup registration stays in the live snapshot until visited; later revisions remain journaled.
/datum/unit_test/netrun_core_recovery_snapshot_registration/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/controller/subsystem/netrun/recovery_fixture/worker = allocate(/datum/controller/subsystem/netrun/recovery_fixture)
	var/datum/netrun_external_core/recovery_fixture/client = worker.ensure_external_core()
	var/datum/component/netrun_node/node = scene.source.resolve_node()
	var/turf/position = node.physical_turf()
	client.levels = list(position.z)
	client.on_node_registered(worker, node)
	client.observe_service(scene.source)
	TEST_ASSERT_EQUAL(length(client.journal), 0, "Connecting state does not duplicate registration into a pre-snapshot journal")
	TEST_ASSERT_EQUAL(length(client.node_metadata), 0, "Connecting state does not allocate identities for unvisited records")
	client.engine_epoch = "snapshot-engine"
	client.state = "snapshotting"
	client.snapshot_phase = "nodes"
	client.on_node_changed(worker, node)
	client.observe_service(scene.source)
	TEST_ASSERT_EQUAL(length(client.journal), 0, "Unvisited live node and service will be sampled by their snapshot cursors")
	client.scanned_nodes[node] = TRUE
	client.export_node(node, TRUE)
	node.offline_until = world.time + 10 SECONDS
	client.on_node_changed(worker, node)
	TEST_ASSERT(length(client.journal), "A change after the snapshot visit is retained for catch-up")
	client.snapshot_phase = "services"
	client.scanned_services[scene.source] = TRUE
	client.observe_service(scene.source)
	TEST_ASSERT(client.service_metadata[scene.source], "A visited service receives a catch-up fact")
	var/tail = client.fact_tail
	client.on_node_changed(worker, node)
	client.observe_service(scene.source)
	TEST_ASSERT_EQUAL(client.fact_tail, tail, "Unchanged repeated signals do not append more facts")

/// Shutdown отзывает admission один раз и запрещает reconnect даже из позднего callback.
/datum/unit_test/netrun_core_recovery_shutdown/Run()
	var/datum/controller/subsystem/netrun/recovery_fixture/worker = allocate(/datum/controller/subsystem/netrun/recovery_fixture)
	var/datum/netrun_external_core/recovery_fixture/client = worker.ensure_external_core()
	var/datum/netrun_external_effects/machines/recovery_fixture/executor = client.effects
	TEST_ASSERT(worker.shutdown_external_core(), "Native shutdown finishes when the worker reports closed")
	TEST_ASSERT_EQUAL(client.state, "closed", "Shutdown revokes the active binding")
	TEST_ASSERT_EQUAL(executor.disconnect_count, 1, "Owned contexts are disconnected once")
	TEST_ASSERT(!worker.external_retry_scheduled, "Shutdown cannot schedule recovery")
	TEST_ASSERT_NULL(worker.ensure_external_core(), "Late callbacks cannot reopen the bridge")
	TEST_ASSERT_EQUAL(client.open_count, 1, "No fresh binding is created during shutdown")
	TEST_ASSERT(worker.shutdown_external_core(), "Repeated shutdown remains safe")
	TEST_ASSERT_EQUAL(executor.disconnect_count, 1, "Repeated shutdown does not repeat callbacks")

/// Removed modes fail closed; configuration retries only after the physical backoff deadline.
/datum/unit_test/netrun_core_recovery_configuration/Run()
	TEST_ASSERT_EQUAL(netrun_external_safe_code("node_capacity"), "node_capacity", "Safe Host code remains available for recovery diagnosis")
	TEST_ASSERT_EQUAL(netrun_external_safe_code("payload text with spaces"), "host_rejected", "Diagnostics never copy arbitrary input text")
	TEST_ASSERT_EQUAL(netrun_external_safe_code("код"), "host_rejected", "Only explicit ASCII code alphabet is accepted")
	var/datum/controller/subsystem/netrun/recovery_fixture/disabled = allocate(/datum/controller/subsystem/netrun/recovery_fixture)
	disabled.settings["NETRUN_CORE_MODE"] = "dm"
	TEST_ASSERT_NULL(disabled.ensure_external_core(), "Removed native mode cannot open IPC")
	TEST_ASSERT_EQUAL(disabled.token_reads, 0, "Invalid mode never reads a secret")
	TEST_ASSERT_EQUAL(disabled.clients_created, 0, "Invalid mode never creates a native client")
	var/datum/controller/subsystem/netrun/recovery_fixture/worker = allocate(/datum/controller/subsystem/netrun/recovery_fixture)
	worker.settings["NETRUN_CORE_PORT"] = "invalid"
	TEST_ASSERT_NULL(worker.ensure_external_core(), "Bad port fails closed")
	var/reads = worker.config_reads
	worker.now += 9
	worker.ensure_external_core()
	TEST_ASSERT_EQUAL(worker.config_reads, reads, "Fire before backoff deadline performs no new config read")
	worker.settings["NETRUN_CORE_PORT"] = "18462"
	worker.token_text = null
	worker.now++
	TEST_ASSERT_NULL(worker.ensure_external_core(), "Unavailable token remains a scheduled config failure")
	TEST_ASSERT_EQUAL(worker.external_retry_wait, 20, "Second failure waits two physical seconds")
	worker.token_text = "fixture-token-not-a-production-secret-1234"
	worker.now += 20
	var/datum/netrun_external_core/recovery_fixture/client = worker.ensure_external_core()
	TEST_ASSERT(client, "Corrected token/config starts the same selected external mode")
	TEST_ASSERT_EQUAL(worker.clients_created, 1, "Failures before client creation allocate no abandoned clients")
	var/token_reads = worker.token_reads
	worker.ensure_external_core()
	TEST_ASSERT_EQUAL(worker.token_reads, token_reads, "Connecting state does not reread config every fire")
	client.ready = TRUE
	client.state = "ready"
	worker.ensure_external_core()
	TEST_ASSERT_EQUAL(worker.external_retry_delay, 10, "Only full ready resets exponential backoff")
	client.close("fixture_cleanup")
	qdel(client.effects)
	qdel(client)
	worker.external_core = null

/// Backoff ограничен30s и корректно пересекает midnight без зависимости от world.time.
/datum/unit_test/netrun_core_recovery_clock_and_cap/Run()
	var/datum/controller/subsystem/netrun/recovery_fixture/worker = allocate(/datum/controller/subsystem/netrun/recovery_fixture)
	worker.allow_open = FALSE
	worker.ensure_external_core()
	var/datum/netrun_external_core/recovery_fixture/client = worker.external_core
	for(var/wait in list(10, 20, 40, 80, 160, 300, 300))
		TEST_ASSERT_EQUAL(worker.external_retry_wait, wait, "Retry delay doubles and stops at thirty seconds")
		worker.now += wait
		worker.ensure_external_core()
	TEST_ASSERT_EQUAL(worker.clients_created, 1, "All failed opens reuse one client/effects object")
	client.close("fixture_cleanup")
	qdel(client.effects)
	qdel(client)
	worker.external_core = null
	var/datum/controller/subsystem/netrun/recovery_fixture/midnight = allocate(/datum/controller/subsystem/netrun/recovery_fixture)
	midnight.allow_open = FALSE
	midnight.now = 863995
	midnight.ensure_external_core()
	client = midnight.external_core
	midnight.now = 4
	midnight.ensure_external_core()
	TEST_ASSERT_EQUAL(client.open_count, 1, "Nine elapsed ds across midnight are not a deadline")
	midnight.now = 5
	midnight.ensure_external_core()
	TEST_ASSERT_EQUAL(client.open_count, 2, "Ten elapsed ds cross the same physical deadline")
	client.close("fixture_cleanup")
	qdel(client.effects)
	qdel(client)
	midnight.external_core = null

/// Fresh binding использует прежний world/executor, но не переносит queued mutating messages и старые lookup maps.
/datum/unit_test/netrun_core_recovery_client_reuse/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/controller/subsystem/netrun/recovery_fixture/worker = allocate(/datum/controller/subsystem/netrun/recovery_fixture)
	var/datum/netrun_external_core/recovery_fixture/client = worker.ensure_external_core()
	var/datum/netrun_external_effects/machines/recovery_fixture/executor = client.effects
	client.ready = TRUE
	client.state = "ready"
	worker.ensure_external_core()
	var/world_id = client.world_epoch
	var/binding = client.binding_epoch
	var/list/node_identity = client.node_key(scene.source.resolve_node())
	var/list/outcomes = list()
	var/datum/netrun_external_request_context/context = new
	context.request_id = "dm:1"
	context.binding_epoch = binding
	context.message = new /datum/netrun_machine_message/transport_fixture(list("value" = "not-replayed"), outcomes)
	executor.request_serial = "1"
	executor.pending[context.request_id] = context
	client.abort_session("fixture_disconnect")
	client.close("repeated_close")
	TEST_ASSERT_EQUAL(executor.disconnect_count, 1, "One binding invokes disconnect cleanup once")
	TEST_ASSERT_EQUAL(outcomes["failed"], 1, "Queued mutating message receives one known failure")
	TEST_ASSERT_NULL(client.service_key(scene.source), "Reentrant export cannot allocate identities in a closed client")
	TEST_ASSERT_EQUAL(length(client.node_metadata), 0, "Closed callbacks leave no metadata to collide with the next ID namespace")
	worker.now += worker.external_retry_wait
	TEST_ASSERT_EQUAL(worker.ensure_external_core(), client, "Recovery retains the client object")
	TEST_ASSERT_EQUAL(client.effects, executor, "Recovery retains the native executor and its old callback guards")
	TEST_ASSERT_EQUAL(client.world_epoch, world_id, "World epoch survives a protocol resync")
	TEST_ASSERT(client.binding_epoch != binding, "Every successful reopen has a new binding")
	TEST_ASSERT_NULL(client.resolve_node(node_identity["id"], node_identity["generation"]), "Old native lookups are absent until a fresh snapshot visits the registry")
	TEST_ASSERT_EQUAL(length(executor.pending), 0, "Old queued contexts never become new binding requests")
	TEST_ASSERT_EQUAL(length(executor.request_commands), 0, "Recovery never resends a mutating command")
	client.close("fixture_cleanup")
	qdel(executor)
	qdel(client)
	worker.external_core = null

/// Merge/split/order changes закрывают старый binding до экспорта overlapping sector facts.
/datum/unit_test/netrun_core_recovery_sector_geometry/Run()
	var/datum/controller/subsystem/netrun/recovery_fixture/worker = allocate(/datum/controller/subsystem/netrun/recovery_fixture)
	var/datum/netrun_external_core/recovery_fixture/client = worker.ensure_external_core()
	client.state = "ready"
	client.ready = TRUE
	client.levels = list(10, 11)
	TEST_ASSERT(client.export_sector_at_z(10, TRUE), "First connected stack exports raw levels")
	TEST_ASSERT_EQUAL(length(client.sector_by_z), 2, "Raw Z membership is bounded and indexed once")
	client.levels = list(11, 10)
	TEST_ASSERT_NULL(client.export_sector_at_z(10, FALSE), "Native floor reordering requires a full resync")
	TEST_ASSERT_EQUAL(client.state, "resync_required", "Known geometry cannot mutate an old binding in place")
	TEST_ASSERT_EQUAL(length(client.sector_metadata), 0, "Closing clears old sector records")
	TEST_ASSERT_EQUAL(length(client.sector_by_z), 0, "Closing clears old Z ownership")
	worker.now += worker.external_retry_wait
	worker.ensure_external_core()
	client.state = "ready"
	TEST_ASSERT(client.export_sector_at_z(10, TRUE), "Fresh binding accepts the new ordered geometry")
	client.levels = list(10)
	TEST_ASSERT_NULL(client.export_sector_at_z(10, FALSE), "A split cannot retain stale floors of the previous stack")
	worker.now += worker.external_retry_wait
	worker.ensure_external_core()
	client.state = "ready"
	client.levels = list(10, 11)
	client.export_sector_at_z(10, TRUE)
	client.levels = list(9, 10, 11)
	TEST_ASSERT_NULL(client.export_sector_at_z(10, FALSE), "A merged stack cannot overlap a retired sector ID")
	TEST_ASSERT_EQUAL(client.last_error, "sector_geometry_overlap", "Overlap has a safe stable diagnostic")
	client.close("fixture_cleanup")
	qdel(client.effects)
	qdel(client)
	worker.external_core = null

/// Повреждённый native levels list не попадает в checksum/journal и не расширяет Z namespace.
/datum/unit_test/netrun_core_recovery_invalid_geometry/Run()
	var/datum/controller/subsystem/netrun/recovery_fixture/worker = allocate(/datum/controller/subsystem/netrun/recovery_fixture)
	var/datum/netrun_external_core/recovery_fixture/client = worker.ensure_external_core()
	for(var/list/invalid in list(list(10, 10), list(10, 4097), list(11), list("10")))
		client.state = "ready"
		client.levels = invalid
		TEST_ASSERT_NULL(client.export_sector_at_z(10, FALSE), "Duplicate, out-of-range, missing or nonnumeric levels fail closed")
		TEST_ASSERT_EQUAL(length(client.sector_by_z), 0, "Invalid geometry leaves no partial Z map")
	var/list/oversized = list()
	oversized.len = 4097
	client.levels = oversized
	client.state = "ready"
	TEST_ASSERT_NULL(client.export_sector_at_z(10, FALSE), "List limit is checked before scanning entries")
	client.close("fixture_cleanup")
	qdel(client.effects)
	qdel(client)
	worker.external_core = null

/// До capture одинаковый full upsert занимает один slot; после capture прежний causal prefix неизменяем.
/datum/unit_test/netrun_core_recovery_fact_coalescing_epoch/Run()
	var/datum/controller/subsystem/netrun/recovery_fixture/worker = allocate(/datum/controller/subsystem/netrun/recovery_fixture)
	var/datum/netrun_external_core/recovery_fixture/client = worker.journal_client()
	TEST_ASSERT(client.queue_fact("{\"revision\":1}", FALSE, "node:n1"), "First unsent upsert is queued")
	TEST_ASSERT(client.queue_fact("{\"revision\":2}", FALSE, "node:n1"), "New full state replaces the same unsent epoch slot")
	TEST_ASSERT_EQUAL(length(client.journal), 1, "Moving actor state does not append one record per movement")
	TEST_ASSERT_EQUAL(client.fact_tail, "1", "Replacement consumes no fact serial")
	TEST_ASSERT_EQUAL(client.journal[1], "{\"revision\":2}", "Unsent slot contains the latest raw state")
	var/barrier = client.capture_fact_barrier()
	TEST_ASSERT_EQUAL(barrier, "1", "Logical command captures the exact current prefix")
	client.queue_fact("{\"revision\":3}", FALSE, "node:n1")
	TEST_ASSERT_EQUAL(length(client.journal), 2, "A newer epoch cannot replace facts already captured by a command")
	TEST_ASSERT_EQUAL(client.journal[1], "{\"revision\":2}", "Captured raw prefix remains immutable")
	TEST_ASSERT_EQUAL(client.fact_tail, "2", "New causal epoch appends a new serial")
	TEST_ASSERT(client.send_journal(1, FALSE), "First prefix enters one immutable pending frame")
	var/frame = client.pending_frame
	client.queue_fact("{\"revision\":4}", FALSE, "node:n1")
	TEST_ASSERT_EQUAL(client.pending_frame, frame, "Unaccepted staging never changes under later native state updates")
	TEST_ASSERT_EQUAL(client.fact_tail, "2", "Only the newer unsent slot coalesces while an older frame is pending")
	TEST_ASSERT(!client.command_facts_ready(barrier), "A command cannot overtake a fact frame not yet accepted by the bridge")
	TEST_ASSERT(client.mark_pending_accepted(), "Bridge acceptance fixes the fact prefix before the following command")
	TEST_ASSERT(client.command_facts_ready(barrier), "Ordered duplex permits the command without waiting for application ACK")
	TEST_ASSERT_EQUAL(client.fact_acknowledged, "0", "Native authority still waits for actual Host application")
	TEST_ASSERT(client.ack_pending(), "Output ACK applies the preceding facts")
	TEST_ASSERT(client.command_facts_ready(barrier), "The captured command is released without waiting for unrelated newer state")

/// Popped slot не coalesce-ится; tombstone инвалидирует mapping и сохраняет все необходимые revision boundaries.
/datum/unit_test/netrun_core_recovery_fact_tombstone_and_inflight/Run()
	var/datum/controller/subsystem/netrun/recovery_fixture/worker = allocate(/datum/controller/subsystem/netrun/recovery_fixture)
	var/datum/netrun_external_core/recovery_fixture/client = worker.journal_client()
	client.queue_fact("{\"upsert\":1}", FALSE, "node:n1")
	TEST_ASSERT(client.send_journal(128, FALSE), "First state moves out of the unsent index")
	var/frame = client.pending_frame
	client.queue_fact("{\"upsert\":2}", FALSE, "node:n1")
	TEST_ASSERT_EQUAL(client.fact_tail, "2", "Popped record cannot be replaced by a later update")
	TEST_ASSERT_EQUAL(client.pending_frame, frame, "Later changes preserve the transmitted frame")
	client.invalidate_fact_key("node:n1")
	client.queue_fact("{\"remove\":3}")
	client.queue_fact("{\"upsert\":4}", FALSE, "node:n1")
	TEST_ASSERT_EQUAL(client.fact_tail, "4", "Delete always occupies its own serial")
	TEST_ASSERT_EQUAL(length(client.journal) - client.journal_head + 1, 3, "Unsent pre-delete state, tombstone and replacement all survive")
	TEST_ASSERT_EQUAL(client.journal[client.journal_head], "{\"upsert\":2}", "New upsert never changes the state preceding deletion")
	TEST_ASSERT_EQUAL(client.journal[client.journal_head + 1], "{\"remove\":3}", "Tombstone is never dropped")

/// Compaction переносит opaque slot index вместе с parallel keys; replacement корректно учитывает retained bytes.
/datum/unit_test/netrun_core_recovery_fact_compaction/Run()
	var/datum/controller/subsystem/netrun/recovery_fixture/worker = allocate(/datum/controller/subsystem/netrun/recovery_fixture)
	var/datum/netrun_external_core/recovery_fixture/client = worker.journal_client()
	for(var/index in 1 to 600)
		client.queue_fact("{\"v\":1}", FALSE, "node:n[index]")
	for(var/index in 1 to 4)
		TEST_ASSERT(client.send_journal(128, FALSE), "A bounded frame consumes 128 records")
		TEST_ASSERT(client.ack_pending(), "Application ACK releases the next bounded frame")
	TEST_ASSERT_EQUAL(client.fact_consumed, "512", "Compaction preserves logical fact serials")
	TEST_ASSERT_EQUAL(length(client.journal) - client.journal_head + 1, 88, "Only remaining records retain raw strings")
	TEST_ASSERT_EQUAL(length(client.journal_keys), length(client.journal), "Parallel keys preserve list alignment")
	var/characters = client.journal_characters
	var/replacement = "{\"v\":123456}"
	client.queue_fact(replacement, FALSE, "node:n600")
	TEST_ASSERT_EQUAL(client.fact_tail, "600", "Compacted last slot still coalesces in O(1)")
	TEST_ASSERT_EQUAL(client.journal[length(client.journal)], replacement, "Rebased slot points to the correct remaining raw record")
	TEST_ASSERT_EQUAL(client.journal_characters, characters - length("{\"v\":1}") + length(replacement), "Replacement adjusts byte accounting without retaining old raw text")

/// Record-count и pre-serialized budget ограничивают кадр до materialization большого JSON тела.
/datum/unit_test/netrun_core_recovery_fact_frame_budget/Run()
	var/datum/controller/subsystem/netrun/recovery_fixture/worker = allocate(/datum/controller/subsystem/netrun/recovery_fixture)
	var/datum/netrun_external_core/recovery_fixture/client = worker.journal_client()
	var/raw = "{\"text\":[json_encode(repeat_string(70000, "x"))]}"
	client.queue_fact(raw, FALSE, "node:n1")
	client.queue_fact(raw, FALSE, "node:n2")
	client.engine_epoch = null
	TEST_ASSERT(!client.send_journal(128, FALSE), "Rejected envelope enqueue cannot pop any source facts")
	TEST_ASSERT_EQUAL(client.fact_consumed, "0", "Failure before enqueue preserves all logical serials")
	TEST_ASSERT_EQUAL(client.journal_head, 1, "Failure before enqueue preserves the original raw prefix")
	client.engine_epoch = "journal-engine"
	TEST_ASSERT(client.send_journal(128, FALSE), "One large valid raw record fits the frame budget")
	TEST_ASSERT_EQUAL(client.fact_consumed, "1", "The next large record remains unsent instead of overgrowing the frame")
	TEST_ASSERT_EQUAL(client.journal_characters, length(raw), "Only the unsent raw record remains in journal bytes")
	var/through = client.fact_consumed
	TEST_ASSERT(!client.send_journal(128, FALSE), "Pending frame refuses a second send")
	TEST_ASSERT_EQUAL(client.fact_consumed, through, "Failed enqueue cannot consume any records")
	TEST_ASSERT(client.ack_pending(), "First frame is acknowledged")
	TEST_ASSERT(client.send_journal(128, FALSE), "Next record is eventually sent without loss")
	TEST_ASSERT(client.ack_pending(), "Second large frame is acknowledged")
	for(var/index in 1 to 129)
		client.queue_fact("{}")
	TEST_ASSERT(client.send_journal(1000, FALSE), "Caller record budget is clamped to protocol maximum")
	var/list/envelope = json_decode(client.pending_frame)
	TEST_ASSERT_EQUAL(length(envelope["entries"]), 128, "A live frame never contains more than128 records")

/// Coalescing не обходит общий retained-byte cap: oversized replacement закрывает binding без частичного продолжения.
/datum/unit_test/netrun_core_recovery_fact_replacement_bytes/Run()
	var/datum/controller/subsystem/netrun/recovery_fixture/worker = allocate(/datum/controller/subsystem/netrun/recovery_fixture)
	var/datum/netrun_external_core/recovery_fixture/client = worker.journal_client()
	client.journal_byte_limit = 1048576
	var/raw = repeat_string(70000, "x")
	for(var/index in 1 to 14)
		TEST_ASSERT(client.queue_fact(raw, FALSE, "node:n[index]"), "Retained raw records stay within one MiB")
	TEST_ASSERT(!client.queue_fact(raw + raw, FALSE, "node:n1"), "Replacement checks the new aggregate bytes before writing")
	TEST_ASSERT_EQUAL(client.last_error, "source_journal_overflow", "Byte pressure has a safe stable diagnostic")
	TEST_ASSERT_EQUAL(client.state, "resync_required", "Overflow cannot continue with missing source facts")
	TEST_ASSERT_EQUAL(length(client.journal_upserts), 0, "Resync releases all coalescing mappings")

/// Replacement сохраняет unACKed infrastructure serial и не понижает fence за более новым infrastructure fact.
/datum/unit_test/netrun_core_recovery_fact_infrastructure_ack/Run()
	var/datum/controller/subsystem/netrun/recovery_fixture/worker = allocate(/datum/controller/subsystem/netrun/recovery_fixture)
	var/datum/netrun_external_core/recovery_fixture/client = worker.journal_client()
	client.queue_fact("{\"revision\":1}", FALSE, "node:n1")
	client.queue_fact("{\"revision\":2}", TRUE, "node:n1")
	TEST_ASSERT_EQUAL(client.fact_tail, "1", "Infrastructure replacement keeps the unsent slot serial")
	TEST_ASSERT_EQUAL(client.infrastructure_barrier, "1", "Latest replacement is fenced until its actual application ACK")
	TEST_ASSERT(!client.infrastructure_facts_ready(), "Unsent infrastructure cannot authorize a native effect")
	TEST_ASSERT(client.send_journal(128, FALSE), "Infrastructure state is sent")
	TEST_ASSERT(!client.infrastructure_facts_ready(), "Pending wire body is not enough to release the fence")
	TEST_ASSERT(client.ack_pending(), "Host application ACK releases the exact replaced serial")
	TEST_ASSERT(client.infrastructure_facts_ready(), "The same serial safely represents the latest transmitted replacement")
	client.queue_fact("{\"node\":1}", FALSE, "node:n1")
	client.queue_fact("{\"node\":2}", TRUE, "node:n2")
	var/barrier = client.infrastructure_barrier
	client.queue_fact("{\"node\":3}", TRUE, "node:n1")
	TEST_ASSERT_EQUAL(client.infrastructure_barrier, barrier, "Replacing an earlier slot cannot lower a later infrastructure barrier")
