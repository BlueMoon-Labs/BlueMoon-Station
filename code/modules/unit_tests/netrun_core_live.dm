#ifdef NETRUN_CORE_LIVE_TEST
/// Отдельный opt-in smoke запускает настоящий station runtime с опубликованными Host/bridge, без IPC stubs.
/datum/unit_test/netrun_core_live/Run()
	TEST_ASSERT_EQUAL(world.GetConfig("env", "NETRUN_CORE_LIVE_TEST"), "1", "Live test must be selected by its dedicated managed runner")
	TEST_ASSERT_EQUAL(SSnetrun.ensure_external_mode(), "external", "Live smoke requires production external mode")
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	var/native_rebuilds = SSnetrun.topology_rebuilds
	var/native_prebuilds = SSnetrun.apc_prebuild_steps
	var/native_trees = transport.tree_builds
	log_world("NETRUN_CORE_LIVE_STAGE awaiting_ready")
	TEST_ASSERT(wait_core_ready(90 SECONDS), "Real Host must complete snapshot/catchup and publish its graph")
	var/datum/netrun_external_core/client = SSnetrun.external_core
	var/datum/netrun_external_effects/machines/queries/executor = client.effects
	TEST_ASSERT(istype(executor), "Production client must compose the real query/effect dispatcher")
	TEST_ASSERT(istype(SSnetrun.get_topology(), /datum/netrun_topology/external), "Native topology must be the imported read-only C# view")
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
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
	TEST_ASSERT_EQUAL(SSnetrun.topology_rebuilds, native_rebuilds, "Live flow never calls the native topology builder")
	TEST_ASSERT_EQUAL(SSnetrun.apc_prebuild_steps, native_prebuilds, "Live flow never runs native APC prebuild work")
	TEST_ASSERT_EQUAL(transport.tree_builds, native_trees, "Live flow never solves a native route tree")
	log_world("NETRUN_CORE_LIVE_PASS discovery native_once projection source_tree movement native_builders_unchanged")

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
