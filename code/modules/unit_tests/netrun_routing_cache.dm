/// A real two-APC network keeps cache tests independent of artificial graph fixtures.
/datum/netrun_routing_cache_scene
	parent_type = /datum/netrun_transport_scene
	var/area/remote_room
	var/remote_area_type = /area/netrun_route_test
	var/turf/remote_spot
	var/obj/machinery/power/apc/remote_apc
	var/original_cache_limit
	var/original_infrastructure_limit

/datum/netrun_routing_cache_scene/New(turf/origin)
	..(origin)
	original_cache_limit = SSnetrun.get_machine_transport().route_cache_limit
	original_infrastructure_limit = SSnetrun.get_topology().infrastructure_route_limit
	remote_room = room(remote_area_type)
	remote_spot = take(locate(origin.x + 4, origin.y + 2, origin.z), remote_room)
	var/turf/power_spot = take(get_step(remote_spot, SOUTH), remote_room)
	remote_apc = machine(/obj/machinery/power/apc, power_spot)
	receiver.forceMove(remote_spot)
	SSnetrun.ensure_topology()

/datum/netrun_routing_cache_scene/Destroy()
	SSnetrun.get_machine_transport().route_cache_limit = original_cache_limit
	SSnetrun.get_topology().infrastructure_route_limit = original_infrastructure_limit
	remote_apc = null
	remote_spot = null
	remote_room = null
	return ..()

/datum/netrun_routing_cache_scene/department
	remote_area_type = /area/science/research

/// Discovery, boolean reachability and owned delivery routes reuse one materialized path.
/datum/unit_test/netrun_routing_cache_repeated_path/Run()
	var/datum/netrun_routing_cache_scene/scene = allocate(/datum/netrun_routing_cache_scene, run_loc_floor_bottom_left)
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	TEST_ASSERT(transport.borrowed_path(scene.source, scene.target), "The real machines must have a physical path")
	var/built = transport.path_builds
	var/trees = SSnetrun.get_topology().infrastructure_tree_builds
	var/hits = transport.path_cache_hits
	for(var/i in 1 to 40)
		TEST_ASSERT(transport.reachable(scene.source, scene.target), "A warm reachability lookup must remain usable")
		var/datum/netrun_route/owned = transport.route(scene.source, scene.target)
		TEST_ASSERT(owned, "Packet delivery must receive an owned route from the same warm path")
		qdel(owned)
	TEST_ASSERT_EQUAL(transport.path_builds, built, "Repeated discovery and delivery must not reconstruct the same physical path")
	TEST_ASSERT_EQUAL(SSnetrun.get_topology().infrastructure_tree_builds, trees, "Repeated queries must not solve another shortest-path tree")
	TEST_ASSERT(transport.path_cache_hits >= hits + 80, "Both reachability and route acquisition must hit the warm cache")

/// Machine routing trees retain only forwarding infrastructure, not every destination device.
/datum/unit_test/netrun_routing_cache_infrastructure_tree/Run()
	var/datum/netrun_routing_cache_scene/scene = allocate(/datum/netrun_routing_cache_scene, run_loc_floor_bottom_left)
	for(var/i in 1 to 20)
		scene.machine(/obj/machinery/netrun_server/transport_fixture, scene.source_spot)
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	TEST_ASSERT(transport.borrowed_path(scene.source, scene.target), "The two physical APCs must communicate")
	var/datum/component/netrun_node/source_apc = scene.apc.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/target_apc = scene.remote_apc.GetComponent(/datum/component/netrun_node)
	var/datum/netrun_path_tree/tree = SSnetrun.get_topology().infrastructure_route_trees[source_apc.address]
	TEST_ASSERT(tree, "The source APC must retain its reusable infrastructure tree")
	TEST_ASSERT(tree.reached[target_apc.address], "The infrastructure tree must include the destination APC")
	TEST_ASSERT(!tree.reached[scene.source.node.address] && !tree.reached[scene.target.node.address], "Ordinary endpoints must not occupy every APC's retained tree")
	var/datum/component/netrun_node/legacy_node = scene.dns.GetComponent(/datum/component/netrun_node)
	TEST_ASSERT(!tree.reached[legacy_node.address], "A legacy information endpoint is a destination, not forwarding infrastructure")
	TEST_ASSERT_EQUAL(tree.neighbor_visits, 2, "Solving two APCs must visit only their two directed edges, regardless of endpoint population")

/// Separate transport consumers borrow one physical graph cache without owning it.
/datum/unit_test/netrun_routing_cache_physical_owner/Run()
	var/datum/netrun_routing_cache_scene/scene = allocate(/datum/netrun_routing_cache_scene, run_loc_floor_bottom_left)
	var/datum/netrun_machine_transport/primary = SSnetrun.get_machine_transport()
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	var/datum/component/netrun_node/root = scene.apc.GetComponent(/datum/component/netrun_node)
	var/datum/netrun_path_tree/tree = primary.path_tree(graph, root)
	TEST_ASSERT_EQUAL(graph.infrastructure_route_trees[root.address], tree, "The physical graph must own the borrowed tree")
	var/builds = graph.infrastructure_tree_builds
	var/datum/netrun_machine_transport/other = allocate(/datum/netrun_machine_transport)
	TEST_ASSERT_EQUAL(other.path_tree(graph, root), tree, "A second transport must borrow the identical physical tree")
	TEST_ASSERT_EQUAL(graph.infrastructure_tree_builds, builds, "A second consumer must not solve or copy another infrastructure tree")
	TEST_ASSERT_EQUAL(other.tree_builds, 0, "The adapter diagnostic must count only solves caused by its own calls")
	qdel(other)
	TEST_ASSERT(!QDELETED(tree), "Destroying a transport consumer must not delete the graph's shared cache")
	TEST_ASSERT_EQUAL(graph.infrastructure_route_trees[root.address], tree, "The physical owner must retain the tree after consumer teardown")
	qdel(scene.apc)
	TEST_ASSERT(QDELETED(tree), "Deleting the physical root must immediately release its graph-owned routing tree")
	TEST_ASSERT_NULL(graph.infrastructure_route_trees[root.address], "A deleted physical root must not remain in the shared cache")

/// Graph-owned cache bounds and access order apply even to requests in the same tick.
/datum/unit_test/netrun_routing_cache_infrastructure_bound/Run()
	var/datum/netrun_routing_cache_scene/scene = allocate(/datum/netrun_routing_cache_scene, run_loc_floor_bottom_left)
	var/obj/machinery/power/apc/third = scene.machine(/obj/machinery/power/apc, scene.target_spot)
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	graph.infrastructure_route_limit = 2
	var/datum/component/netrun_node/first_root = scene.apc.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/second_root = scene.remote_apc.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/third_root = third.GetComponent(/datum/component/netrun_node)
	var/datum/netrun_path_tree/first = graph.borrow_infrastructure_tree(first_root)
	var/datum/netrun_path_tree/second = graph.borrow_infrastructure_tree(second_root)
	TEST_ASSERT_EQUAL(graph.borrow_infrastructure_tree(first_root), first, "A hit must retain and refresh the first physical tree")
	var/datum/netrun_path_tree/newest = graph.borrow_infrastructure_tree(third_root)
	TEST_ASSERT_EQUAL(length(graph.infrastructure_route_trees), 2, "The shared graph cache must respect its configured root bound")
	TEST_ASSERT(QDELETED(second) && !QDELETED(first) && !QDELETED(newest), "The least recently used root must be evicted even when all accesses share world.time")
	graph.infrastructure_route_limit = 1
	TEST_ASSERT_EQUAL(graph.borrow_infrastructure_tree(first_root), first, "Lowering the bound must preserve the root being borrowed")
	TEST_ASSERT_EQUAL(length(graph.infrastructure_route_trees), 1, "A cache hit must also apply a lowered physical cache bound")
	TEST_ASSERT(QDELETED(newest), "Trimming a lowered bound must release evicted tree datums")

/// Rebinding a remote leaf cannot invent reachability of the LAN it just left.
/datum/unit_test/netrun_routing_cache_rebind_network_index/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, origin.z)
	var/area/local_room = scene.room(/area/medical/netrun_route_test)
	var/area/remote_room = scene.room(/area/engineering/netrun_route_test)
	var/turf/local_spot = scene.take(origin, local_room)
	var/turf/local_power = scene.take(get_step(origin, NORTH), local_room)
	var/list/levels = multiz_gravity_test_levels()
	scene.mark_station(levels[1])
	var/turf/remote_spot = scene.take(locate(80, 80, levels[1]), remote_room, TRUE)
	var/turf/remote_power = scene.take(locate(81, 80, levels[1]), remote_room, TRUE)
	scene.machine(/obj/machinery/power/apc, local_power)
	scene.machine(/obj/machinery/power/apc, remote_power)
	var/obj/machinery/computer/netrun_terminal/terminal = scene.machine(/obj/machinery/computer/netrun_terminal, local_spot)
	var/obj/machinery/computer/netrun_terminal/mobile = scene.machine(/obj/machinery/computer/netrun_terminal, remote_spot)
	SSnetworks.station_network.setting_disabled = TRUE
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	var/datum/component/netrun_node/source = terminal.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/leaf = mobile.GetComponent(/datum/component/netrun_node)
	var/datum/netrun_network/old_network = leaf.network
	var/datum/netrun_path_tree/retained = graph.route_snapshot(source, TRUE)
	TEST_ASSERT(!retained.reached_networks[old_network.id] && !retained.reached[leaf.address], "The original remote LAN and its endpoint must be physically unreachable")
	mobile.forceMove(local_spot)
	leaf.join_network()
	TEST_ASSERT(leaf.network != old_network, "The relocated endpoint must actually leave the old LAN")
	TEST_ASSERT_EQUAL(graph.route_tables[source.address], retained, "A remote leaf's rebind must preserve the source's warm tree")
	TEST_ASSERT(retained.reached[leaf.address], "The relocated endpoint must join the reachable local tree")
	TEST_ASSERT(!retained.reached_networks[old_network.id], "The old unreachable LAN must not be added through the leaf's stale pre-join network field")
	TEST_ASSERT(!terminal.console.can_reach(old_network, retained), "Network authorization must not observe phantom old-LAN reachability")

/// Moving or rebooting an unrelated leaf must not invalidate the shared infrastructure work.
/datum/unit_test/netrun_routing_cache_unrelated_leaf/Run()
	var/datum/netrun_routing_cache_scene/scene = allocate(/datum/netrun_routing_cache_scene, run_loc_floor_bottom_left)
	var/obj/machinery/netrun_server/transport_fixture/unrelated = scene.machine(/obj/machinery/netrun_server/transport_fixture, scene.source_spot)
	var/area/local_room = get_area(scene.source_spot)
	var/offset = 2 * NETRUN_LINK_TILES_PER_DS
	var/x = scene.source_spot.x + offset <= world.maxx ? scene.source_spot.x + offset : scene.source_spot.x - offset
	var/turf/far_spot = scene.take(locate(x, scene.source_spot.y, scene.source_spot.z), local_room, TRUE)
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	TEST_ASSERT(transport.borrowed_path(scene.source, scene.target), "Warm the two-APC route after creating the unrelated endpoint")
	var/trees = SSnetrun.get_topology().infrastructure_tree_builds
	var/paths = transport.path_builds
	unrelated.set_machine_stat(BROKEN)
	TEST_ASSERT(transport.borrowed_path(scene.source, scene.target), "Another device's power loss must not cut the working route")
	TEST_ASSERT_EQUAL(SSnetrun.get_topology().infrastructure_tree_builds, trees, "Leaf availability must not rebuild infrastructure trees")
	unrelated.set_machine_stat(0)
	var/datum/netrun_topology/graph = SSnetrun.get_topology()
	var/weights = graph.weight_revision
	unrelated.forceMove(far_spot)
	TEST_ASSERT_EQUAL(graph.weight_revision, weights, "The movement signal must defer unrelated cable-weight work")
	var/datum/component/netrun_node/moved_node = unrelated.GetComponent(/datum/component/netrun_node)
	var/datum/netrun_task_scheduler/scheduler = SSnetrun.get_task_scheduler()
	var/datum/netrun_task/node/movement_task = scheduler.by_key["node:[REF(moved_node)]"]
	TEST_ASSERT_NOTNULL(movement_task, "The real move must enqueue its existing node worker")
	movement_task.execute(SSnetrun)
	scheduler.cancel("node", moved_node)
	TEST_ASSERT(graph.weight_revision > weights, "The deferred node worker must update the moved cable's routing cost")
	TEST_ASSERT(transport.borrowed_path(scene.source, scene.target), "The original pair must remain reachable after unrelated cable movement")
	TEST_ASSERT_EQUAL(SSnetrun.get_topology().infrastructure_tree_builds, trees, "An unrelated cable cost must not rerun infrastructure Dijkstra")
	TEST_ASSERT_EQUAL(transport.path_builds, paths, "An unchanged source/destination pair must retain its materialized path")

/// A carried device has no child MOVED signal; route lookup must refresh its actual attachment.
/datum/unit_test/netrun_routing_cache_carried_target/Run()
	var/datum/netrun_routing_cache_scene/scene = allocate(/datum/netrun_routing_cache_scene, run_loc_floor_bottom_left)
	var/obj/item/carrier = allocate(/obj/item, scene.source_spot)
	var/obj/item/modular_computer/pda/pda = allocate(/obj/item/modular_computer/pda, carrier)
	pda.enabled = TRUE
	var/datum/netrun_machine_service/target = pda.get_netrun_machine_service("pda.messenger")
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	TEST_ASSERT(transport.borrowed_path(scene.source, scene.target), "Warm the source APC's infrastructure tree")
	var/datum/netrun_route/before = transport.route(scene.source, target)
	allocated += before
	TEST_ASSERT(before, "The carried PDA must initially share the sender's APC")
	var/trees = SSnetrun.get_topology().infrastructure_tree_builds
	var/area/original_area = target.node.binding_area
	carrier.forceMove(scene.remote_spot)
	TEST_ASSERT_EQUAL(target.node.binding_area, original_area, "Moving only the carrier must not emit a child movement signal")
	var/datum/netrun_route/after = transport.route(scene.source, target)
	allocated += after
	TEST_ASSERT(after, "A carried target must remain routable after crossing into the other APC's area")
	var/datum/component/netrun_node/remote_node = scene.remote_apc.GetComponent(/datum/component/netrun_node)
	TEST_ASSERT_EQUAL(target.node.bound_apc, remote_node, "Lookup must discover the carried target's current physical attachment")
	TEST_ASSERT(remote_node.address in after.hops, "The new cached route must actually cross the destination APC")
	TEST_ASSERT_NOTEQUAL(json_encode(after.hops), json_encode(before.hops), "A previous pair-cache entry must not keep the old cable")
	TEST_ASSERT(after.latency > before.latency, "The new APC edge must contribute to the carried target's latency")
	TEST_ASSERT_EQUAL(SSnetrun.get_topology().infrastructure_tree_builds, trees, "Rebinding one leaf must not rebuild the unchanged infrastructure mesh")

/// Live availability checks must reject and recover within the same tick, including warm pairs.
/datum/unit_test/netrun_routing_cache_power_recovery/Run()
	var/datum/netrun_routing_cache_scene/scene = allocate(/datum/netrun_routing_cache_scene, run_loc_floor_bottom_left)
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	TEST_ASSERT(transport.borrowed_path(scene.source, scene.target), "Warm the path before breaking its forwarding APC")
	var/tick = world.time
	scene.remote_apc.set_machine_stat(BROKEN)
	TEST_ASSERT(!transport.borrowed_path(scene.source, scene.target), "A warm cache must immediately reject a broken forwarding APC")
	scene.remote_apc.set_machine_stat(0)
	TEST_ASSERT(transport.borrowed_path(scene.source, scene.target), "A negative result must not survive actual forwarding recovery")
	TEST_ASSERT_EQUAL(world.time, tick, "Outage and recovery checks must not wait for a poll or timer tick")

/// Public delivery routes are caller-owned even when their backing path is retained.
/datum/unit_test/netrun_routing_cache_owned_copy/Run()
	var/datum/netrun_routing_cache_scene/scene = allocate(/datum/netrun_routing_cache_scene, run_loc_floor_bottom_left)
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	var/datum/netrun_route/first = transport.route(scene.source, scene.target)
	allocated += first
	TEST_ASSERT(first, "The first delivery must have an owned route")
	var/expected_path = json_encode(first.hops)
	var/expected_latency = first.latency
	first.hops.Cut()
	first.latency = -100
	qdel(first)
	var/datum/netrun_route/second = transport.route(scene.source, scene.target)
	allocated += second
	TEST_ASSERT(second, "Releasing one owned route must not delete the private cached route")
	TEST_ASSERT_EQUAL(json_encode(second.hops), expected_path, "Caller mutation must not corrupt the retained path")
	TEST_ASSERT_EQUAL(second.latency, expected_latency, "Caller mutation must not corrupt cached latency")

/// Lowering the cache bound must trim old traffic as well as cap new pairs.
/datum/unit_test/netrun_routing_cache_bounded/Run()
	var/datum/netrun_routing_cache_scene/scene = allocate(/datum/netrun_routing_cache_scene, run_loc_floor_bottom_left)
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	transport.route_cache_limit = 4
	var/list/targets = list()
	for(var/i in 1 to 8)
		var/obj/machinery/netrun_server/transport_fixture/machine = scene.machine(/obj/machinery/netrun_server/transport_fixture, scene.remote_spot)
		targets += machine.get_netrun_machine_service("transport.fixture")
	for(var/datum/netrun_machine_service/target as anything in targets)
		TEST_ASSERT(transport.borrowed_path(scene.source, target), "Every distinct physical pair must remain routable under eviction")
		TEST_ASSERT(length(transport.pair_routes) <= 4, "The pair cache must remain within its configured bound")
	var/paths = transport.path_builds
	TEST_ASSERT(transport.borrowed_path(scene.source, targets[length(targets)]), "The newest pair must remain usable")
	TEST_ASSERT_EQUAL(transport.path_builds, paths, "The most recently used pair must still be cached")

/// Count cache maintenance rather than relying on wall-clock benchmark thresholds.
/datum/netrun_machine_transport/netrun_cache_probe
	var/forgets = 0
	var/unlinks = 0
	var/touches = 0
	var/appends = 0

/datum/netrun_machine_transport/netrun_cache_probe/forget_pair_route(key)
	forgets++
	return ..()

/datum/netrun_machine_transport/netrun_cache_probe/unlink_pair_route(key)
	unlinks++
	return ..()

/datum/netrun_machine_transport/netrun_cache_probe/touch_pair_route(key)
	touches++
	return ..()

/datum/netrun_machine_transport/netrun_cache_probe/append_pair_route(key)
	appends++
	return ..()

/// A cold working set beyond capacity must unlink only the entries actually evicted.
/datum/unit_test/netrun_routing_cache_admission_work/Run()
	var/datum/netrun_machine_transport/netrun_cache_probe/transport = allocate(/datum/netrun_machine_transport/netrun_cache_probe)
	transport.route_cache_limit = 4
	for(var/index in 1 to 32)
		var/datum/netrun_machine_path/path = new
		transport.store_pair_route("route-[index]", path)
	TEST_ASSERT_EQUAL(length(transport.pair_routes), 4, "Cold traffic must retain only the configured working set")
	TEST_ASSERT_EQUAL(transport.forgets, 28, "New-key admission must forget only real capacity victims")
	TEST_ASSERT_EQUAL(transport.unlinks, 28, "A new key must never unlink an absent LRU entry")
	TEST_ASSERT_EQUAL(transport.touches, 0, "New-key admission must append directly instead of performing a cache hit")
	TEST_ASSERT_EQUAL(transport.appends, 32, "Each cold path must be appended exactly once")
	TEST_ASSERT_EQUAL(transport.pair_oldest, "route-29", "Cold admission must preserve FIFO order before any hits")
	TEST_ASSERT_EQUAL(transport.pair_newest, "route-32", "The most recent admission must be the MRU entry")
	var/serial = transport.pair_serial
	for(var/repeat in 1 to 16)
		transport.touch_pair_route("route-32")
	TEST_ASSERT_EQUAL(transport.unlinks, 28, "Repeated MRU hits must not mutate the LRU chain")
	TEST_ASSERT_EQUAL(transport.appends, 32, "An MRU hit must not append an already-linked entry")
	TEST_ASSERT_EQUAL(transport.pair_serial, serial + 16, "MRU hits must still advance the existing usage diagnostic")
	transport.forget_pair_route("absent")
	TEST_ASSERT_EQUAL(transport.unlinks, 28, "Forgetting a missing key must not perform link maintenance")
	TEST_ASSERT_EQUAL(length(transport.pair_routes), 4, "A missing-key forget must not disturb retained paths")

/// Replacement owns one value while ordinary hits still determine the exact LRU victim.
/datum/unit_test/netrun_routing_cache_replacement_order/Run()
	var/datum/netrun_machine_transport/netrun_cache_probe/transport = allocate(/datum/netrun_machine_transport/netrun_cache_probe)
	transport.route_cache_limit = 3
	var/datum/netrun_machine_path/first = new
	var/datum/netrun_machine_path/second = new
	var/datum/netrun_machine_path/third = new
	transport.store_pair_route("first", first)
	transport.store_pair_route("second", second)
	transport.store_pair_route("third", third)
	var/datum/netrun_machine_path/replacement = new
	transport.store_pair_route("second", replacement)
	TEST_ASSERT(QDELETED(second), "Replacing a cached route must release its previous owned value")
	TEST_ASSERT(!QDELETED(first) && !QDELETED(third), "Replacement at capacity must not evict another pair")
	TEST_ASSERT_EQUAL(length(transport.pair_routes), 3, "Replacement must preserve cache cardinality")
	TEST_ASSERT_EQUAL(transport.pair_routes["second"], replacement, "The replacement must become the cached value")
	TEST_ASSERT_EQUAL(transport.forgets, 0, "Replacement must not remove and reinsert its dictionary key")
	TEST_ASSERT_EQUAL(transport.unlinks, 1, "Replacing an interior entry needs only one real LRU move")
	TEST_ASSERT_EQUAL(transport.pair_oldest, "first", "Replacement must retain unrelated entries' relative order")
	TEST_ASSERT_EQUAL(transport.pair_newest, "second", "A replaced route must become MRU")
	transport.touch_pair_route("first")
	var/datum/netrun_machine_path/fourth = new
	transport.store_pair_route("fourth", fourth)
	TEST_ASSERT(QDELETED(third), "Admission must evict the true LRU after replacement and a cache hit")
	TEST_ASSERT(!QDELETED(first) && !QDELETED(replacement), "Touched and replaced paths must survive the next eviction")
	TEST_ASSERT_EQUAL(transport.pair_oldest, "second", "Eviction must leave the remaining chain in access order")
	var/unlinks = transport.unlinks
	var/datum/netrun_machine_path/newest = new
	transport.store_pair_route("fourth", newest)
	TEST_ASSERT(QDELETED(fourth), "An MRU replacement must release its old value too")
	TEST_ASSERT_EQUAL(transport.unlinks, unlinks, "An MRU replacement must not unlink or relink its key")
	TEST_ASSERT_EQUAL(transport.pair_newest, "fourth", "An MRU replacement must retain its position")

/// Live limit reductions must also apply to replacement, and clearing must release all links.
/datum/unit_test/netrun_routing_cache_replacement_shrink/Run()
	var/datum/netrun_machine_transport/netrun_cache_probe/transport = allocate(/datum/netrun_machine_transport/netrun_cache_probe)
	transport.route_cache_limit = 4
	var/datum/netrun_machine_path/first = new
	var/datum/netrun_machine_path/second = new
	var/datum/netrun_machine_path/third = new
	var/datum/netrun_machine_path/fourth = new
	transport.store_pair_route("first", first)
	transport.store_pair_route("second", second)
	transport.store_pair_route("third", third)
	transport.store_pair_route("fourth", fourth)
	transport.route_cache_limit = 2
	var/datum/netrun_machine_path/replacement = new
	transport.store_pair_route("second", replacement)
	TEST_ASSERT(QDELETED(first) && QDELETED(second) && QDELETED(third), "Shrinking on replacement must release the old value and the oldest other entries")
	TEST_ASSERT(!QDELETED(fourth) && !QDELETED(replacement), "Shrinking must retain the replacement and the most recent other pair")
	TEST_ASSERT_EQUAL(length(transport.pair_routes), 2, "A replacement must enforce a lowered live cache limit")
	TEST_ASSERT_EQUAL(transport.pair_oldest, "fourth", "The surviving older entry must head the shortened chain")
	TEST_ASSERT_EQUAL(transport.pair_newest, "second", "The replacement must end the shortened chain")
	transport.route_cache_limit = 1
	var/datum/netrun_machine_path/only = new
	transport.store_pair_route("only", only)
	TEST_ASSERT(QDELETED(fourth) && QDELETED(replacement), "Shrinking on insertion must release every excess owned path")
	TEST_ASSERT_EQUAL(length(transport.pair_routes), 1, "An insertion must enforce a lowered live cache limit too")
	TEST_ASSERT_EQUAL(transport.pair_oldest, "only", "A singleton must be both ends of the LRU")
	TEST_ASSERT_EQUAL(transport.pair_newest, "only", "A singleton must remain reachable from the MRU end")
	TEST_ASSERT_NULL(transport.pair_previous["only"], "A singleton must not retain an evicted predecessor")
	TEST_ASSERT_NULL(transport.pair_next["only"], "A singleton must not retain an evicted successor")
	transport.clear_pair_routes()
	TEST_ASSERT(QDELETED(only), "Clearing the cache must release its last owned path")
	TEST_ASSERT_EQUAL(length(transport.pair_routes) + length(transport.pair_previous) + length(transport.pair_next) + length(transport.pair_used), 0, "Clearing must release all route and LRU metadata")
	TEST_ASSERT_NULL(transport.pair_oldest, "Clearing must reset the LRU head")
	TEST_ASSERT_NULL(transport.pair_newest, "Clearing must reset the LRU tail")

/// An offline destination remains a visible leaf; an offline source cannot expose onward routes.
/datum/unit_test/netrun_routing_cache_ui_availability/Run()
	var/datum/netrun_routing_cache_scene/scene = allocate(/datum/netrun_routing_cache_scene, run_loc_floor_bottom_left)
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	var/datum/netrun_path_tree/original = graph.route_snapshot(scene.source.node, TRUE)
	TEST_ASSERT(original.reached[scene.target.node.address], "The UI's original source must discover the remote destination")
	scene.receiver.set_machine_stat(BROKEN)
	var/datum/netrun_path_tree/destination_offline = graph.route_snapshot(scene.source.node, TRUE)
	TEST_ASSERT_EQUAL(destination_offline, original, "A destination leaf reboot must not replace a shared UI routing table")
	TEST_ASSERT(destination_offline.reached[scene.target.node.address], "An offline destination must retain its map position and cable")
	scene.sender.set_machine_stat(BROKEN)
	var/datum/netrun_path_tree/source_offline = graph.route_snapshot(scene.source.node, TRUE)
	TEST_ASSERT_NOTEQUAL(source_offline, original, "Source power changes must still invalidate its retained reachability")
	var/datum/component/netrun_node/apc_node = scene.apc.GetComponent(/datum/component/netrun_node)
	TEST_ASSERT(!source_offline.reached[apc_node.address], "An offline source must not retain an onward route to its APC")
	scene.sender.set_machine_stat(0)
	var/datum/netrun_path_tree/restored = graph.route_snapshot(scene.source.node, TRUE)
	TEST_ASSERT(restored.reached[apc_node.address], "Restoring the source must restore its onward UI reachability immediately")

/// Count native status reads without substituting the APC's availability policy.
/obj/machinery/power/apc/netrun_availability_probe
	var/online_checks = 0

/obj/machinery/power/apc/netrun_availability_probe/netrun_online(remote = TRUE)
	online_checks++
	return ..()

/// Quiet healthy APCs do not add native checks to every unrelated routing tick.
/datum/unit_test/netrun_routing_cache_recovery_poll_work/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/power/apc/netrun_availability_probe/apc = scene.machine(/obj/machinery/power/apc/netrun_availability_probe, scene.source_spot)
	var/datum/component/netrun_node/node = apc.GetComponent(/datum/component/netrun_node)
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	graph.reconcile_availability()
	var/checks = apc.online_checks
	for(var/i in 1 to 10)
		graph.forwarding_checked_at = -INFINITY
		graph.reconcile_availability()
	TEST_ASSERT_EQUAL(apc.online_checks, checks, "Routing reconciliation must not poll healthy APCs elsewhere on the station")
	apc.failure_timer = 5
	node.notify_changed()
	TEST_ASSERT_EQUAL(graph.unavailable_apcs[node.address], node, "An observed outage must retain its APC for unsigned countdown recovery")
	var/generation = graph.transit_availability_revision
	apc.failure_timer = 0
	graph.forwarding_checked_at = -INFINITY
	graph.reconcile_availability()
	TEST_ASSERT(node.last_online && graph.transit_availability_revision > generation, "Unsigned recovery must immediately invalidate negative routing trees on the next fallback pass")
	TEST_ASSERT_NULL(graph.unavailable_apcs[node.address], "Recovered APCs must leave the fallback polling set")
	apc.failure_timer = 5
	node.notify_changed()
	var/address = node.address
	qdel(apc)
	TEST_ASSERT_NULL(graph.unavailable_apcs[address], "Deleting an offline APC must release its recovery entry")

/// APC countdowns update native fields without a power/stat signal. A retained tree is not authority.
/datum/unit_test/netrun_routing_cache_unsigned_apc_state/Run()
	var/datum/netrun_routing_cache_scene/scene = allocate(/datum/netrun_routing_cache_scene, run_loc_floor_bottom_left)
	var/obj/machinery/computer/netrun_terminal/terminal = scene.machine(/obj/machinery/computer/netrun_terminal, scene.source_spot)
	TEST_ASSERT(terminal.console.can_route(scene.target.node), "The real terminal must first warm a working command path")
	var/tick = world.time
	scene.remote_apc.failure_timer = 5
	TEST_ASSERT(!terminal.console.can_route(scene.target.node), "Cached command reachability must inspect actual forwarding availability without waiting for a stat signal")
	TEST_ASSERT_EQUAL(world.time, tick, "A positive cached command path must be revoked without a subsystem poll")
	scene.remote_apc.failure_timer = 0
	sleep(world.tick_lag)
	TEST_ASSERT(terminal.console.can_route(scene.target.node), "An unsignalled APC countdown recovery must restore command routing")

/// A cached LAN entry must not authorize access through an unsigned failed forwarder.
/datum/unit_test/netrun_routing_cache_live_network_witness/Run()
	var/datum/netrun_routing_cache_scene/scene = allocate(/datum/netrun_routing_cache_scene/department, run_loc_floor_bottom_left)
	var/obj/machinery/computer/netrun_terminal/terminal = scene.machine(/obj/machinery/computer/netrun_terminal, scene.source_spot)
	var/datum/netrun_network/network = scene.target.node.network
	var/datum/component/netrun_node/source = terminal.console.route_source()
	TEST_ASSERT_NOTEQUAL(network, source.network, "The witness fixture must cross into another department")
	TEST_ASSERT(terminal.console.can_reach(network), "The remote LAN must initially be reachable")
	var/datum/netrun_topology/graph = SSnetrun.get_topology()
	var/datum/component/netrun_node/forwarder = scene.apc.GetComponent(/datum/component/netrun_node)
	var/tick = world.time
	scene.apc.failure_timer = 5
	TEST_ASSERT(!terminal.console.can_reach(network), "A retained LAN marker must not authorize a route through an unsigned offline intermediate APC")
	TEST_ASSERT_EQUAL(world.time, tick, "LAN authority must revoke access without waiting for a fallback tick")
	TEST_ASSERT_EQUAL(graph.unavailable_apcs[forwarder.address], forwarder, "A failed witness must retain its actual forwarding outage for recovery")
	TEST_ASSERT(!terminal.console.can_reach(network), "Rebuilding a negative tree must keep the cut LAN inaccessible")
	scene.apc.failure_timer = 0
	sleep(world.tick_lag)
	TEST_ASSERT(terminal.console.can_reach(network), "Unsigned countdown recovery must reopen the LAN through the same physical APC")

/// A new source can discover an unsigned APC outage after this tick's shared fallback.
/datum/unit_test/netrun_routing_cache_unsigned_cold_recovery/Run()
	var/datum/netrun_routing_cache_scene/scene = allocate(/datum/netrun_routing_cache_scene, run_loc_floor_bottom_left)
	var/obj/machinery/computer/netrun_terminal/terminal = scene.machine(/obj/machinery/computer/netrun_terminal, scene.source_spot)
	var/datum/component/netrun_node/source = terminal.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/remote = scene.remote_apc.GetComponent(/datum/component/netrun_node)
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	graph.reconcile_availability()
	scene.remote_apc.failure_timer = 5
	var/datum/netrun_path_tree/offline = graph.route_snapshot(source, TRUE)
	TEST_ASSERT(!offline.reached[scene.target.node.address], "The cold solve must honor the native outage without another whole-station scan")
	TEST_ASSERT(!remote.last_online, "A cold negative solve must retain its actual forwarding sample for recovery detection")
	scene.remote_apc.failure_timer = 0
	sleep(world.tick_lag)
	TEST_ASSERT(terminal.console.can_route(scene.target.node), "The next tick must invalidate the cold negative tree when the native countdown recovers")

/// More clients must add their source tables, not deep-copy every graph on every access read.
/datum/unit_test/netrun_routing_cache_console_reads/Run()
	var/datum/netrun_routing_cache_scene/scene = allocate(/datum/netrun_routing_cache_scene, run_loc_floor_bottom_left)
	var/obj/machinery/computer/netrun_terminal/first = scene.machine(/obj/machinery/computer/netrun_terminal, scene.source_spot)
	var/obj/machinery/computer/netrun_terminal/second = scene.machine(/obj/machinery/computer/netrun_terminal, scene.source_spot)
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	var/copies = graph.route_snapshot_copies
	for(var/obj/machinery/computer/netrun_terminal/terminal as anything in list(first, second))
		for(var/i in 1 to 40)
			TEST_ASSERT(terminal.console.can_route(scene.target.node), "Both sessions must retain physical access to the remote endpoint")
			TEST_ASSERT(terminal.console.can_reach(scene.target.node.network), "LAN discovery must use the same read-only physical table")
			terminal.console.node_level(scene.target.node)
			var/datum/netrun_route/route = terminal.console.route_to(scene.target.node)
			TEST_ASSERT(length(route.hops), "An owned delivery route must still contain the actual path")
			qdel(route)
		var/datum/component/netrun_node/source = terminal.GetComponent(/datum/component/netrun_node)
		var/datum/netrun_path_tree/borrowed = terminal.console.connection.read_path_tree()
		TEST_ASSERT_EQUAL(borrowed, graph.route_tables[source.address], "Synchronous reads must borrow their graph-owned table")
		terminal.console.release_path_tree(borrowed)
		TEST_ASSERT(!QDELETED(borrowed), "Releasing a synchronous borrow must preserve the graph's routing table")
	TEST_ASSERT_EQUAL(graph.route_snapshot_copies, copies, "Repeated multiplayer access checks and route serialization must make zero full-graph copies")
	var/datum/netrun_path_tree/owned = first.console.make_path_tree()
	allocated += owned
	TEST_ASSERT_EQUAL(graph.route_snapshot_copies, copies + 1, "An explicit execution snapshot must still get its own stable full tree")
	owned.reached.Cut()
	TEST_ASSERT(first.console.can_route(scene.target.node), "Mutating an owned execution tree must not corrupt either session's retained paths")
	first.console.ui_routes = owned
	TEST_ASSERT(!first.console.can_route(scene.target.node), "The fixture's stale UI tree must actually hide the target")
	var/datum/netrun_path_tree/fresh = first.console.connection.read_path_tree(TRUE)
	TEST_ASSERT(first.console.can_route(scene.target.node, fresh), "A synchronous authority read must bypass even an active stale UI snapshot")
	first.console.release_path_tree(fresh)
	first.console.ui_routes = null
	TEST_ASSERT_EQUAL(graph.route_snapshot_copies, copies + 1, "Fresh synchronous authority reads must also avoid full-graph copies")
	// A retained tree can also be the UI's tree. Outside serialization that
	// identity must never skip live forwarding checks on an explicit borrow.
	first.console.ui_routes = fresh
	scene.remote_apc.failure_timer = 5
	var/datum/netrun_path_tree/live = first.console.connection.read_path_tree(TRUE)
	TEST_ASSERT(!first.console.can_route(scene.target.node, live), "A fresh borrow shared with UI must still reject an unsignalled failed forwarding APC")
	first.console.release_path_tree(live)
	scene.remote_apc.failure_timer = 0
	first.console.ui_routes = null

/// Count real membership work, including movement that occurs during a serialization pass.
/datum/component/netrun_node/routing_cache_test
	var/join_calls = 0

/datum/component/netrun_node/routing_cache_test/join_network()
	join_calls++
	return ..()

/datum/unit_test/netrun_routing_cache_ui_membership/Run()
	var/datum/netrun_routing_cache_scene/scene = allocate(/datum/netrun_routing_cache_scene, run_loc_floor_bottom_left)
	var/obj/machinery/computer/netrun_terminal/terminal = scene.machine(/obj/machinery/computer/netrun_terminal, scene.source_spot)
	var/obj/item/target = allocate(/obj/item, scene.remote_spot)
	var/datum/component/netrun_node/routing_cache_test/node = target.AddComponent(/datum/component/netrun_node/routing_cache_test, NETRUN_NODE_TERMINAL)
	SSnetrun.ensure_topology()
	var/datum/netrun_console/console = terminal.console
	console.ui_routes = console.acquire_ui_routes()
	console.ui_serializing = TRUE
	node.join_calls = 0
	for(var/i in 1 to 40)
		TEST_ASSERT(console.can_route(node), "All visibility reads in one UI pass must see the reachable endpoint")
	TEST_ASSERT_EQUAL(node.join_calls, 1, "One UI pass must reconcile a node's physical binding only once")
	target.forceMove(scene.source_spot)
	TEST_ASSERT(console.can_route(node), "A real move during the pass must still refresh the cached physical binding")
	TEST_ASSERT_EQUAL(node.join_calls, 2, "A pending physical update must bypass the per-pass membership cache")
	TEST_ASSERT_EQUAL(node.bound_apc, scene.apc.GetComponent(/datum/component/netrun_node), "The cached pass must observe the moved endpoint's actual APC")
	console.ui_serializing = FALSE
	console.ui_routes = null
	console.ui_routes_borrowed = FALSE
	console.connection.ui_refreshed_nodes = null

/// Device deletion must release its source tree without waiting for a scheduled expiry.
/datum/unit_test/netrun_routing_cache_deleted_source/Run()
	var/datum/netrun_routing_cache_scene/scene = allocate(/datum/netrun_routing_cache_scene, run_loc_floor_bottom_left)
	var/obj/machinery/computer/netrun_terminal/terminal = scene.machine(/obj/machinery/computer/netrun_terminal, scene.source_spot)
	var/datum/component/netrun_node/source = terminal.GetComponent(/datum/component/netrun_node)
	var/address = source.address
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	var/datum/netrun_path_tree/tree = terminal.console.connection.read_path_tree()
	TEST_ASSERT_EQUAL(graph.route_tables[address], tree, "The source must first own a retained routing table")
	TEST_ASSERT(!isnull(graph.route_used[address]), "The active source must be tracked for idle expiry")
	qdel(terminal)
	TEST_ASSERT(QDELETED(tree), "Deleting the actual source device must immediately delete its graph-owned tree")
	TEST_ASSERT_NULL(graph.route_tables[address], "A deleted source must not occupy the full-tree cache")
	TEST_ASSERT_NULL(graph.route_used[address], "A deleted source must not remain in idle-expiry bookkeeping")
	TEST_ASSERT_NULL(tree.source, "A released tree must not retain the deleted node through another UI reference")
	TEST_ASSERT_EQUAL(length(tree.reached), 0, "Releasing a retained tree must immediately free its destination arrays")

/// A firewall change must revoke actual grants without waking every unopened deck.
/datum/unit_test/netrun_routing_cache_firewall_interest/Run()
	var/datum/netrun_routing_cache_scene/scene = allocate(/datum/netrun_routing_cache_scene, run_loc_floor_bottom_left)
	var/obj/machinery/computer/netrun_terminal/granted = scene.machine(/obj/machinery/computer/netrun_terminal, scene.source_spot)
	var/obj/machinery/computer/netrun_terminal/unrelated = scene.machine(/obj/machinery/computer/netrun_terminal, scene.source_spot)
	granted.console.access_session.node_access[scene.target.node.address] = NETRUN_ACCESS_ROOT
	unrelated.console.ui_dirty = FALSE
	SSnetrun.active_consoles -= unrelated.console
	scene.target.node.raise_firewall()
	TEST_ASSERT_EQUAL(length(granted.console.access_session.pending_firewalls), 1, "The session with a compromised grant must receive its revocation")
	TEST_ASSERT_EQUAL(length(unrelated.console.access_session.pending_firewalls), 0, "Unrelated sessions must not allocate pending firewall work")
	TEST_ASSERT(!unrelated.console.ui_dirty && !SSnetrun.active_consoles[unrelated.console], "An unopened unrelated terminal must remain asleep after another node raises its firewall")
	granted.console.access_session.process_events()
	TEST_ASSERT_NULL(granted.console.access_session.node_access[scene.target.node.address], "Filtering unrelated listeners must not preserve the actual compromised grant")
