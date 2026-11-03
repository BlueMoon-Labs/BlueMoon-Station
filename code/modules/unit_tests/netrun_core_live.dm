#ifdef NETRUN_CORE_LIVE_TEST
/datum/netrun_transport_scene/core_live
	use_imported_fixture = FALSE

/datum/netrun_client_scene/core_live
	use_imported_fixture = FALSE

#ifdef UNIT_TEST_PROFILE_FULL_MAP
/datum/unit_test/netrun_core_live
	requires_full_map = TRUE
#endif

/// Отдельный opt-in smoke запускает настоящий station runtime с опубликованными Host/bridge, без IPC stubs.
/datum/unit_test/netrun_core_live/Run()
	TEST_ASSERT_EQUAL(world.GetConfig("env", "NETRUN_CORE_LIVE_TEST"), "1", "Live test must be selected by its dedicated managed runner")
	TEST_ASSERT_EQUAL(SSnetrun.ensure_external_mode(), "external", "Live smoke requires production external mode")
	log_world("NETRUN_CORE_LIVE_STAGE awaiting_ready")
	TEST_ASSERT(wait_core_ready(90 SECONDS), "Real Host must complete snapshot/catchup and publish its graph")
	var/datum/netrun_external_core/client = SSnetrun.external_core
	var/datum/netrun_external_effects/machines/queries/executor = client.effects
	TEST_ASSERT(istype(executor), "Production client must compose the real query/effect dispatcher")
	TEST_ASSERT(istype(SSnetrun.get_topology(), /datum/netrun_topology/external), "Native topology must be the imported read-only C# view")
	log_world("NETRUN_CORE_LIVE_STAGE library_monitor")
	TEST_ASSERT(client.monitoring_negotiated, "Published Host must negotiate independent monitoring with the real DM client")
	var/monitor_deadline = world.time + 20 SECONDS
	while(world.time < monitor_deadline && (isnull(client.last_host_monitor_at) || client.host_metrics["sync_state"] != "ready" || !(client.host_metrics["node_count"] > 0 && client.host_metrics["service_count"] > 0)))
		sleep(world.tick_lag)
	TEST_ASSERT(!isnull(client.last_host_monitor_at), "Unsolicited Host telemetry must traverse the real x86 native bridge")
	TEST_ASSERT_EQUAL(client.host_metrics["sync_state"], "ready", "The monitor must observe the actual synchronized C# mirror")
	TEST_ASSERT(client.host_metrics["node_count"] > 0 && client.host_metrics["service_count"] > 0, "Real Host telemetry must expose station object and service counts")
	var/list/monitor_data = SSnetrun.library_monitor_snapshot()
	TEST_ASSERT(netrun_statistics_values_only(monitor_data), "The live monitor payload must contain no native object references")
	TEST_ASSERT(!findtext(json_encode(monitor_data), "session_token"), "The public monitor payload cannot expose a token field")
	rustg_file_write(json_encode(monitor_data), "data/netrun-core/live-monitor-ui.json")
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene/core_live, run_loc_floor_bottom_left)
	TEST_ASSERT(scene.source && scene.target, "Live fixture must register real native machine services")
	var/list/outcomes = list()
	log_world("NETRUN_CORE_LIVE_STAGE discovery_message")
	var/before_received = scene.target.received
	var/list/payload = list("value" = "live-core", "filters" = list(list("id" = "o2", "selected" = TRUE)), "empty" = list())
	TEST_ASSERT(scene.source.send("transport.fixture", new /datum/netrun_machine_message/transport_fixture(payload, outcomes), scene.target.service_tag()), "Native send must enqueue asynchronous C# service discovery")
	TEST_ASSERT(wait_outcome(outcomes, 90 SECONDS), "Discovery and transport must deliver the original native message")
	TEST_ASSERT_EQUAL(outcomes["delivered"], 1, "First message has one terminal delivered callback")
	TEST_ASSERT(!outcomes["failed"], "Successful native delivery has no failure callback")
	TEST_ASSERT_EQUAL(scene.target.received, before_received + 1, "Real native receive executes exactly once")
	TEST_ASSERT_EQUAL(scene.target.last_payload["value"], "live-core", "Transport preserves the immutable logical payload")
	log_world("NETRUN_CORE_LIVE_STAGE projection_tree")
	var/datum/netrun_path_tree/external/tree = wait_tree(scene.source.resolve_node(), scene.target.resolve_node(), 90 SECONDS)
	TEST_ASSERT(tree, "C# graph projection and source predecessor pages must import a usable tree")
	TEST_ASSERT(executor.projection_ready(client), "Published native view must match the complete current C# graph")
	TEST_ASSERT_EQUAL(scene.source.resolve_node().bound_apc, scene.apc.GetComponent(/datum/component/netrun_node), "C# projection assigns the native source APC binding")
	var/graph_before = executor.projection_graph_version
	var/datum/netrun_path_tree/external/old_tree = tree.copy()
	allocated += old_tree
	var/turf/moved_spot = locate(scene.source_spot.x + 3, scene.source_spot.y + 1, scene.source_spot.z)
	log_world("NETRUN_CORE_LIVE_STAGE movement")
	scene.receiver.forceMove(moved_spot)
	TEST_ASSERT(!old_tree.path_available(SSnetrun.get_topology(), scene.target.resolve_node().address), "Request-owned tree copy cannot authorize the old geometry")
	tree = wait_tree(scene.source.resolve_node(), scene.target.resolve_node(), 90 SECONDS)
	TEST_ASSERT(tree && executor.projection_graph_version != graph_before, "Movement delta must publish a new C# graph and recover the source tree")
	TEST_ASSERT_EQUAL(scene.target.resolve_node().topology_turf, moved_spot, "Imported node placement matches the native movement")
	var/list/after_movement = list()
	log_world("NETRUN_CORE_LIVE_STAGE recovered_message")
	TEST_ASSERT(scene.source.send_to(scene.target, new /datum/netrun_machine_message/transport_fixture(list("value" = "moved"), after_movement)), "Direct known destination uses the recovered external transport")
	TEST_ASSERT(wait_outcome(after_movement, 90 SECONDS), "Moved endpoint must receive a second distinct message")
	TEST_ASSERT_EQUAL(after_movement["delivered"], 1, "Second message receives one terminal callback")
	TEST_ASSERT(!after_movement["failed"], "Recovered transport has no failure callback")
	TEST_ASSERT_EQUAL(scene.target.received, before_received + 2, "Each logical message executes one native effect")
	var/list/state_outcomes = list()
	log_world("NETRUN_CORE_LIVE_STAGE replaceable_state")
	TEST_ASSERT(scene.source.send_to(scene.target, new /datum/netrun_machine_message/transport_fixture/queue_snapshot(list("value" = "state"), state_outcomes)), "Replaceable telemetry uses the separate declared state contract")
	TEST_ASSERT(wait_outcome(state_outcomes, 90 SECONDS), "The real Host admits and invokes idempotent state")
	TEST_ASSERT_EQUAL(state_outcomes["delivered"], 1, "State has one native terminal callback")
	TEST_ASSERT_EQUAL(scene.target.received, before_received + 3, "State executes exactly one native receive")
	log_world("NETRUN_CORE_LIVE_STAGE batch_burst")
	TEST_ASSERT_EQUAL(client.max_input_commands, 16, "Production hello negotiates bounded command batches")
	var/burst_start_frames = client.sent_frames
	var/burst_start_batches = client.sent_input_batches
	var/burst_start_commands = client.sent_batched_commands
	var/burst_start_time = world.time
	var/burst_received = scene.target.received
	var/list/burst_outcomes = list()
	for(var/index in 1 to 64)
		var/list/result = list()
		burst_outcomes += list(result)
		TEST_ASSERT(scene.source.send_to(scene.target, new /datum/netrun_machine_message/transport_fixture(list("value" = "burst-[index]"), result)), "Every burst message has a distinct native context")
	for(var/list/result as anything in burst_outcomes)
		TEST_ASSERT(wait_outcome(result, 90 SECONDS), "Every burst request completes through the real Host and bridge")
		TEST_ASSERT_EQUAL(result["delivered"], 1, "Each logical request receives exactly one terminal callback")
	TEST_ASSERT_EQUAL(scene.target.received, burst_received + 64, "Batching never duplicates or loses native effects")
	var/burst_frames = client.sent_frames - burst_start_frames
	TEST_ASSERT(client.sent_batched_commands - burst_start_commands >= 64, "Production traffic actually traverses negotiated multi-command frames")
	TEST_ASSERT(client.sent_input_batches > burst_start_batches, "The native bridge accepts real batch frames")
	// Production operation is ordered per destination: its next effect still waits for the prior result.
	log_world("NETRUN_CORE_LIVE_BURST requests=64 frames=[burst_frames] batches=[client.sent_input_batches - burst_start_batches] batched_commands=[client.sent_batched_commands - burst_start_commands] elapsed_ds=[world.time - burst_start_time]")
	log_world("NETRUN_CORE_LIVE_STAGE relay_guest_map")
	var/obj/machinery/ntnet_relay/guest_relay = scene.machine(/obj/machinery/ntnet_relay, get_step(scene.source_spot, SOUTH))
	var/datum/component/netrun_node/relay_node = guest_relay.GetComponent(/datum/component/netrun_node)
	TEST_ASSERT(wait_tree(relay_node, relay_node, 90 SECONDS), "The real relay must receive its C# source proof")
	var/mob/camera/netrun_entity/visitor/guest = guest_relay.netrun_visitor_spawner.create(null)
	TEST_ASSERT(guest && guest.host_node == relay_node, "The real ghost-role spawner must bind its resident to the relay")
	allocated += guest
	guest.console.workspace_view = "map"
	var/list/guest_data
	var/guest_deadline = world.time + 90 SECONDS
	while(world.time < guest_deadline)
		guest_data = guest.console.ui_data(guest)
		if(netrun_map_has_node(guest_data, relay_node.address))
			break
		sleep(world.tick_lag)
	TEST_ASSERT(netrun_map_has_node(guest_data, relay_node.address), "The NTnet relay guest must receive its actual topology through public ui_data")
	rustg_file_write(json_encode(list("address" = relay_node.address, "payload" = guest_data)), "data/netrun-core/live-relay-ui.json")
	log_world("NETRUN_CORE_LIVE_STAGE implant_map_entry")
	var/turf/entrance_spot = locate(run_loc_floor_bottom_left.x + 6, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/datum/netrun_client_scene/entrance = allocate(/datum/netrun_client_scene/core_live, entrance_spot)
	var/datum/netrun_console/implant/implant_console = entrance.implant.console
	implant_console.access_session.node_access[entrance.target_node.address] = NETRUN_ACCESS_USER
	var/list/entrance_data
	var/entrance_deadline = world.time + 90 SECONDS
	while(world.time < entrance_deadline)
		entrance_data = implant_console.ui_data(entrance.user)
		if(netrun_map_has_node(entrance_data, entrance.target_node.address))
			break
		sleep(world.tick_lag)
	TEST_ASSERT(netrun_map_has_node(entrance_data, entrance.target_node.address), "A cold real Core read must eventually populate the implant entrance map")
	var/entrance_label = "[entrance.target_node.get_name()] — [entrance.target_node.address]"
	TEST_ASSERT_EQUAL(implant_console.entry_choices()[entrance_label], entrance.target_node, "The real Core route must expose the authorized local entrance")
	TEST_ASSERT_EQUAL(implant_console.local_connection_choices(entrance.user)[entrance_label], entrance.target_node, "The physical chooser must expose the adjacent native service port")
	for(var/wired in list(FALSE, TRUE))
		if(wired)
			TEST_ASSERT(implant_console.connection.connect_node(entrance.target_node, entrance.user), "The real implant must attach to the selected native port")
		entrance_deadline = world.time + 90 SECONDS
		while(world.time < entrance_deadline && !implant_console.dive_return_ready(entrance.target_node))
			implant_console.ui_data(entrance.user)
			sleep(world.tick_lag)
		TEST_ASSERT(implant_console.select_entry(entrance.target_node, entrance.user), "A synchronized real Core entrance must remain selectable")
		TEST_ASSERT_NULL(implant_console.dive_denial(entrance.target_node, entrance.user), "The conscious wearer must pass final admission")
		TEST_ASSERT(implant_console.dive_return_ready(entrance.target_node), "Both return paths must be ready before creating the resident")
		TEST_ASSERT(entrance.implant.complete_dive(entrance.target_node, entrance.user), "The real Core admission must transfer the mind with wireless or wired return path")
		var/mob/camera/netrun_entity/diver = implant_console.dive_ref?.resolve()
		TEST_ASSERT(diver && diver.mind, "A successful real dive must retain its resident")
		diver.console.workspace_view = "map"
		var/list/resident_data = diver.console.ui_data(diver)
		TEST_ASSERT(netrun_map_has_node(resident_data, entrance.target_node.address), "A real resident must see its imported network map")
		diver.return_to_body()
	var/observe_seconds = text2num(world.GetConfig("env", "NETRUN_CORE_LIVE_OBSERVE_SECONDS"))
	if(isnum(observe_seconds) && observe_seconds > 0)
		log_world("NETRUN_CORE_LIVE_STAGE observing_health")
		var/observed_binding = client.binding_epoch
		var/first_sample = client.monitor_sample_sequence
		var/observe_started = world.time
		var/observe_until = observe_started + clamp(observe_seconds, 1, 300) SECONDS
		var/list/samples = list()
		while(world.time < observe_until)
			TEST_ASSERT(client.ready && client.binding_epoch == observed_binding, "Real Windows station must remain on the same ready Core binding during observation")
			var/list/metrics = client.host_metrics
			var/list/sample = list("elapsed_s" = (world.time - observe_started) / (1 SECONDS), "pending" = executor.pending_current_count, "request_commands" = length(executor.request_commands), "query_commands" = length(executor.query_commands), "query_inflight" = length(executor.query_inflight), "input_inflight" = length(client.inflight_frames), "bridge_in" = client.native_inbound_frames, "bridge_out" = client.native_outbound_frames, "host_input_queue" = metrics["input_queue_frames"], "host_output_queue" = metrics["output_queue_frames"], "host_journal_frames" = metrics["output_journal_frames"], "host_journal_bytes" = metrics["output_journal_bytes"], "host_managed_bytes" = metrics["managed_bytes"], "host_working_set_bytes" = metrics["working_set_bytes"], "host_cpu_percent" = metrics["process_cpu_percent"], "gc_gen2" = metrics["gc_gen2"], "monitor_age_s" = client.monitor_age(client.last_host_monitor_at), "sample_sequence" = client.monitor_sample_sequence, "applied_sequence" = client.last_applied_sequence, "graph_version" = executor.projection_graph_version)
			samples += list(sample)
			rustg_file_write(json_encode(samples), "data/netrun-core/live-monitor-steady.json")
			log_world("NETRUN_CORE_LIVE_HEALTH elapsed_s=[sample["elapsed_s"]] pending=[sample["pending"]] requests=[sample["request_commands"]] queries=[sample["query_commands"]] input=[sample["input_inflight"]] monitor_age_s=[sample["monitor_age_s"]]")
			sleep(5 SECONDS)
		TEST_ASSERT(netrun_external_decimal_compare(client.monitor_sample_sequence, first_sample) > 0, "Unsolicited telemetry must continue throughout the live observation")
	log_world("NETRUN_CORE_LIVE_PASS discovery native_once projection source_tree movement state external_only")

/// Готовность проверяется через настоящий subsystem fire; тест не вызывает client.tick вручную.
/datum/unit_test/netrun_core_live/proc/wait_core_ready(timeout)
	var/deadline = world.time + timeout
	while(world.time < deadline)
		if(SSnetrun.external_core?.ready)
			return TRUE
		if(SSnetrun.external_error || SSnetrun.external_core?.state == "resync_required")
			return FALSE
		sleep(world.tick_lag)
	return FALSE

/// Каждый message имеет собственные counters, поэтому unrelated station automation не создаёт ложный успех.
/datum/unit_test/netrun_core_live/proc/wait_outcome(list/outcomes, timeout)
	var/deadline = world.time + timeout
	while(!outcomes["delivered"] && !outcomes["failed"] && world.time < deadline)
		if(SSnetrun.external_core?.state == "resync_required")
			return FALSE
		sleep(world.tick_lag)
	return outcomes["delivered"] && !outcomes["failed"]

/// Пустой pending read-only tree освобождается сразу; retained таблица остаётся собственностью dispatcher cache.
/datum/unit_test/netrun_core_live/proc/wait_tree(datum/component/netrun_node/source, datum/component/netrun_node/destination, timeout)
	var/deadline = world.time + timeout
	while(world.time < deadline)
		var/datum/netrun_external_core/client = SSnetrun.external_core
		var/datum/netrun_external_effects/machines/queries/executor = client?.effects
		if(!istype(executor) || client.state == "resync_required")
			return null
		var/datum/netrun_path_tree/tree = executor.projection_tree(client, source, "machine")
		if(istype(tree, /datum/netrun_path_tree/external) && tree.retained && tree.path_available(SSnetrun.get_topology(), destination.address))
			return tree
		if(!tree.retained)
			qdel(tree)
		sleep(world.tick_lag)
	return null
#endif
