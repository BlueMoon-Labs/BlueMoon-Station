/// Initial attachment prefers the APC actually serving the native area, then remains stable.
/datum/unit_test/netrun_geographic_native_apc/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, origin.z)
	var/area/local_room = scene.room(/area/medical/netrun_route_test)
	var/area/foreign_room = scene.room(/area/engineering/netrun_route_test)
	scene.take(origin, local_room)
	var/turf/close_spot = scene.take(get_step(origin, NORTH), foreign_room)
	var/turf/native_spot = scene.take(locate(origin.x + 8, origin.y, origin.z), local_room)
	scene.machine(/obj/machinery/power/apc, close_spot)
	var/obj/machinery/power/apc/native = scene.machine(/obj/machinery/power/apc, native_spot)
	var/obj/machinery/computer/netrun_terminal/terminal = scene.machine(/obj/machinery/computer/netrun_terminal, origin)
	var/datum/component/netrun_node/node = terminal.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/native_node = native.GetComponent(/datum/component/netrun_node)
	SSnetrun.ensure_topology()
	TEST_ASSERT_EQUAL(node.bound_apc, native_node, "A native-area APC must beat a physically closer foreign-area APC")
	scene.machine(/obj/machinery/power/apc, scene.take(get_step(origin, EAST), local_room))
	SSnetrun.ensure_topology()
	TEST_ASSERT_EQUAL(node.bound_apc, native_node, "A newly installed closer APC must preserve an established attachment")

/// Native lookup scales with the supplied room, with the same deterministic fallback.
/datum/unit_test/netrun_geographic_native_apc_index/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, origin.z)
	var/area/local_room = scene.room(/area/medical/netrun_route_test)
	var/area/foreign_room = scene.room(/area/engineering/netrun_route_test)
	scene.take(origin, local_room)
	var/turf/close_spot = scene.take(get_step(origin, NORTH), foreign_room)
	var/obj/machinery/power/apc/foreign = scene.machine(/obj/machinery/power/apc, close_spot)
	for(var/i in 1 to 48)
		scene.machine(/obj/machinery/power/apc, scene.take(locate(origin.x + 4, origin.y + 4, origin.z), foreign_room))
	// APCs can be physically mounted outside the area they actually supply.
	var/obj/machinery/power/apc/first = scene.machine(/obj/machinery/power/apc, scene.take(locate(origin.x + 8, origin.y, origin.z), foreign_room))
	var/obj/machinery/power/apc/second = scene.machine(/obj/machinery/power/apc, scene.take(locate(origin.x, origin.y + 8, origin.z), foreign_room))
	first.area = local_room
	second.area = local_room
	var/datum/component/netrun_node/first_node = first.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/second_node = second.GetComponent(/datum/component/netrun_node)
	var/list/ordered = sort_list(list(first_node.address, second_node.address))
	var/datum/netrun_topology/graph = allocate(/datum/netrun_topology)
	var/visits = graph.nearest_apc_visits
	TEST_ASSERT_EQUAL(graph.nearest_apc(origin), SSnetrun.nodes_by_address[ordered[1]], "Equal native distances must retain the address tie-break")
	TEST_ASSERT_EQUAL(graph.nearest_apc_visits - visits, 2, "A native room lookup must inspect only its two APCs, not all sector APCs")
	visits = graph.nearest_apc_visits
	graph.nearest_apc(origin)
	TEST_ASSERT_EQUAL(graph.nearest_apc_visits, visits, "A repeated turf lookup must use the existing nearest cache")
	var/turf/near_first = scene.take(get_step(origin, EAST), local_room)
	TEST_ASSERT_EQUAL(graph.nearest_apc(near_first), first_node, "Different native distances must still select the physically nearest native APC")
	qdel(first)
	TEST_ASSERT_EQUAL(graph.nearest_apc(near_first), second_node, "Removing a native APC must invalidate the index and cached winner")
	qdel(second)
	var/datum/component/netrun_node/foreign_node = foreign.GetComponent(/datum/component/netrun_node)
	TEST_ASSERT_EQUAL(graph.nearest_apc(origin), foreign_node, "Losing every native APC must restore the nearest foreign-sector fallback")

/// Two nearest-neighbor clusters receive only their shortest connecting bridge.
/datum/unit_test/netrun_geographic_apc_bridges/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, origin.z)
	var/datum/netrun_topology/graph = allocate(/datum/netrun_topology)
	var/area/room = scene.room(/area/netrun_route_test)
	var/list/addresses = list()
	var/list/ordered_nodes = list()
	var/component_size = max(2, NETRUN_APC_NEIGHBORS + 1)
	var/list/offsets = list()
	for(var/base in list(0, 20))
		for(var/i in 0 to component_size - 1)
			offsets += base + i
	for(var/offset in offsets)
		var/obj/machinery/power/apc/apc = scene.machine(/obj/machinery/power/apc, scene.take(locate(origin.x + offset, origin.y, origin.z), room))
		var/datum/component/netrun_node/node = apc.GetComponent(/datum/component/netrun_node)
		ordered_nodes += node
		addresses += node.address
		graph.nodes[node.address] = node
		graph.adjacency[node.address] = list()
	graph.connect_apcs(sort_list(addresses))
	var/datum/component/netrun_node/first_tip = ordered_nodes[component_size]
	var/datum/component/netrun_node/second_tip = ordered_nodes[component_size + 1]
	TEST_ASSERT_EQUAL(length(graph.edges), component_size * (component_size - 1) + 1, "Two fully connected nearest-neighbor clusters need exactly one additional bridge")
	TEST_ASSERT_NOTNULL(graph.edge_between(first_tip.address, second_tip.address), "The bridge must join the physically closest pair between disconnected clusters")
	var/datum/netrun_path_tree/tree = allocate(/datum/netrun_path_tree, graph, ordered_nodes[1])
	var/datum/component/netrun_node/last = ordered_nodes[2 * component_size]
	TEST_ASSERT(tree.reached[last.address], "The shortest bridge must make both neighbor clusters routable")

/// Weighted routing must prefer a three-edge cable chain to a longer two-edge detour.
/datum/unit_test/netrun_geographic_weighted_path/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_topology/graph = allocate(/datum/netrun_topology)
	var/list/nodes = list()
	for(var/offset in list(0, 1, 2, 3, 10))
		var/obj/item/host = allocate(/obj/item, locate(10 + offset * NETRUN_LINK_TILES_PER_DS, origin.y, origin.z))
		var/datum/component/netrun_node/node = host.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
		nodes += node
		graph.nodes[node.address] = node
		graph.adjacency[node.address] = list()
	var/datum/component/netrun_node/source = nodes[1]
	var/datum/component/netrun_node/near_first = nodes[2]
	var/datum/component/netrun_node/near_second = nodes[3]
	var/datum/component/netrun_node/target = nodes[4]
	var/datum/component/netrun_node/detour = nodes[5]
	graph.add_edge(source.address, detour.address, "apc")
	graph.add_edge(detour.address, target.address, "apc")
	graph.add_edge(source.address, near_first.address, "apc")
	graph.add_edge(near_first.address, near_second.address, "apc")
	graph.add_edge(near_second.address, target.address, "apc")
	var/datum/netrun_path_tree/tree = allocate(/datum/netrun_path_tree, graph, source)
	var/list/expected = list(source.address, near_first.address, near_second.address, target.address)
	TEST_ASSERT_EQUAL(tree.costs[target.address], 3, "Three links of NETRUN_LINK_TILES_PER_DS tiles must cost three deciseconds")
	TEST_ASSERT_EQUAL(json_encode(tree.addresses_to(target.address)), json_encode(expected), "Routing must minimize physical latency rather than edge count")

/// Moving a still-bound endpoint changes both live latency and the next cached table.
/datum/unit_test/netrun_geographic_moving_cost/Run()
	var/turf/origin = locate(20, 30, run_loc_floor_bottom_left.z)
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, origin.z)
	var/area/room = scene.room(/area/netrun_route_test)
	scene.take(origin, room, TRUE)
	var/turf/apc_spot = scene.take(get_step(origin, NORTH), room, TRUE)
	var/turf/near_spot = scene.take(get_step(origin, EAST), room, TRUE)
	var/turf/far_spot = scene.take(locate(origin.x + 10 * NETRUN_LINK_TILES_PER_DS, origin.y, origin.z), room, TRUE)
	scene.machine(/obj/machinery/power/apc, apc_spot)
	var/obj/machinery/computer/netrun_terminal/source = scene.machine(/obj/machinery/computer/netrun_terminal, origin)
	var/obj/machinery/computer/netrun_terminal/target = scene.machine(/obj/machinery/computer/netrun_terminal, near_spot)
	source.console.connection.wireless = FALSE
	var/datum/component/netrun_node/node = target.GetComponent(/datum/component/netrun_node)
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	var/datum/component/netrun_node/apc = node.bound_apc
	var/revision = graph.revision
	var/datum/netrun_path_tree/before = source.console.make_path_tree(TRUE)
	allocated += before
	TEST_ASSERT_EQUAL(before.costs[node.address], 2, "Two adjacent physical cables must cost two deciseconds")
	var/builds = graph.route_revision
	target.forceMove(far_spot)
	var/datum/netrun_path_tree/after = source.console.make_path_tree(TRUE)
	allocated += after
	TEST_ASSERT_EQUAL(node.bound_apc, apc, "Moving inside the same native area must keep the original APC")
	TEST_ASSERT_EQUAL(graph.revision, revision, "A cable length change must not rebuild structural topology")
	TEST_ASSERT_EQUAL(before.costs[node.address], 2, "The old UI snapshot must remain immutable")
	TEST_ASSERT_EQUAL(after.costs[node.address], 11, "The next server snapshot must refresh a changed cable cost")
	TEST_ASSERT_EQUAL(source.console.latency_to(node), 11, "Live command and ping latency must use actual world distances")
	TEST_ASSERT(after.geometry_revision > before.geometry_revision, "A changed physical cost must advance the table's geometry generation")
	TEST_ASSERT_EQUAL(graph.route_revision, builds, "Moving a destination leaf must repair its cost without rebuilding any retained tree")
	var/turf/source_spot = scene.take(locate(origin.x + 4 * NETRUN_LINK_TILES_PER_DS, origin.y, origin.z), room, TRUE)
	source.forceMove(source_spot)
	var/datum/netrun_path_tree/moved_source = source.console.make_path_tree(TRUE)
	allocated += moved_source
	TEST_ASSERT_EQUAL(moved_source.costs[node.address], 14, "Moving the source leaf must adjust the shared prefix of its destination costs")
	var/datum/component/netrun_node/source_node = source.GetComponent(/datum/component/netrun_node)
	TEST_ASSERT_EQUAL(moved_source.costs[source_node.address], 0, "A shared prefix must never change a source's self cost")
	TEST_ASSERT_EQUAL(after.costs[node.address], 11, "A previously issued snapshot must not inherit a later source-prefix change")
	TEST_ASSERT_EQUAL(graph.route_revision, builds, "Moving the source leaf must not run Dijkstra again")

/// Uniform relay gateways work within a sector without storing a quadratic clique.
/datum/unit_test/netrun_geographic_relay_bucket/Run()
	var/turf/origin = locate(20, 30, run_loc_floor_bottom_left.z)
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, origin.z)
	var/area/room = scene.room(/area/netrun_route_test)
	var/turf/first_spot = scene.take(origin, room, TRUE)
	var/turf/second_spot = scene.take(locate(origin.x + 12 * NETRUN_LINK_TILES_PER_DS, origin.y, origin.z), room, TRUE)
	scene.machine(/obj/machinery/power/apc, scene.take(get_step(first_spot, NORTH), room, TRUE))
	scene.machine(/obj/machinery/power/apc, scene.take(get_step(second_spot, NORTH), room, TRUE))
	var/obj/machinery/ntnet_relay/first = scene.machine(/obj/machinery/ntnet_relay, first_spot)
	var/obj/machinery/ntnet_relay/second = scene.machine(/obj/machinery/ntnet_relay, second_spot)
	var/datum/component/netrun_node/first_node = first.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/second_node = second.GetComponent(/datum/component/netrun_node)
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	SSnetworks.station_network.setting_disabled = FALSE
	TEST_ASSERT(second_node.address in graph.neighbors(first_node.address), "Relays in the same sector must expose a gateway transition")
	var/list/edge = graph.edge_between(first_node.address, second_node.address)
	TEST_ASSERT_EQUAL(edge["kind"], "relay", "A virtual gateway must retain a real relay edge identity")
	for(var/list/physical as anything in graph.edges)
		TEST_ASSERT(physical["kind"] != "relay", "Quantum links must not allocate a quadratic physical edge list")
	var/datum/netrun_path_tree/tree = allocate(/datum/netrun_path_tree, graph, first_node)
	TEST_ASSERT_EQUAL(tree.costs[second_node.address], NETRUN_RELAY_LATENCY, "A same-sector relay transition must cost three deciseconds")
	TEST_ASSERT(tree.remote[second_node.address], "The shortest path must identify its relay transition")
	SSnetworks.station_network.setting_disabled = TRUE
	TEST_ASSERT(!netrun_link_available(first_node, second_node), "NTnet shutdown must disable the quantum gateway")
	var/datum/netrun_path_tree/local = allocate(/datum/netrun_path_tree, graph, first_node)
	TEST_ASSERT(local.costs[second_node.address] > NETRUN_RELAY_LATENCY, "The remaining same-sector physical route must retain its geographic cost")

/// Relay movement keeps the existing lockout, cooldown and destination key requirements.
/datum/unit_test/netrun_geographic_entity_gateway/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, origin.z)
	var/area/first_room = scene.room(/area/engineering/netrun_route_test)
	var/area/second_room = scene.room(/area/medical/netrun_route_test)
	var/list/levels = multiz_gravity_test_levels()
	scene.mark_station(levels[1])
	var/turf/first_spot = scene.take(origin, first_room)
	var/turf/second_spot = scene.take(locate(80, 80, levels[1]), second_room, TRUE)
	scene.machine(/obj/machinery/power/apc, scene.take(get_step(first_spot, NORTH), first_room))
	scene.machine(/obj/machinery/power/apc, scene.take(get_step(second_spot, NORTH), second_room, TRUE))
	var/obj/machinery/ntnet_relay/first = scene.machine(/obj/machinery/ntnet_relay, first_spot)
	var/obj/machinery/ntnet_relay/second = scene.machine(/obj/machinery/ntnet_relay, second_spot)
	var/datum/component/netrun_node/first_node = first.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/second_node = second.GetComponent(/datum/component/netrun_node)
	SSnetrun.ensure_topology()
	SSnetworks.station_network.setting_disabled = FALSE
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity, origin, first_node)
	TEST_ASSERT(!entity.can_relay_hop(second_node), "An operational gateway must not grant entry into an unauthorized LAN")
	TEST_ASSERT(entity.console.store_file(new /datum/netrun_file("destination.key", NETRUN_FILE_KEY, second_node.network.passcode, 1, second_node.network.id)), "The destination key must occupy actual process memory")
	TEST_ASSERT(entity.console.store_file(new /datum/netrun_file("source.key", NETRUN_FILE_KEY, first_node.network.passcode, 1, first_node.network.id)), "A return key must make the reverse gateway independently authorized")
	TEST_ASSERT(entity.relay_hop(second_node), "A valid key and operational relay pair must permit a sector transition")
	TEST_ASSERT_EQUAL(entity.host_node, second_node, "A gateway transition must enter the real destination relay node")
	TEST_ASSERT_EQUAL(entity.console.node_level(second_node), NETRUN_ACCESS_GUEST, "Relay travel must not invent USER machine rights")
	TEST_ASSERT(entity.can_relay_hop(first_node), "The reverse gateway must otherwise be authorized before its cooldown is tested")
	TEST_ASSERT(!entity.relay_hop(first_node), "The standard hop cooldown must also gate relay transitions")
	entity.next_hop = world.time
	entity.console.intrusion.lockout_until = world.time + 10 SECONDS
	TEST_ASSERT(!entity.can_relay_hop(first_node), "A traced session must not use a relay gateway")

/// Movable is a BYOND base type of anchored machines, not a map rendering policy.
/datum/unit_test/netrun_dynamic_rendering_classification/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, origin.z)
	var/area/room = scene.room(/area/netrun_route_test)
	scene.take(origin, room)
	var/obj/machinery/computer/netrun_terminal/terminal = scene.machine(/obj/machinery/computer/netrun_terminal, origin)
	var/datum/component/netrun_node/stationary = terminal.GetComponent(/datum/component/netrun_node)
	TEST_ASSERT(!stationary.is_dynamic(), "A turf-bound anchored terminal must be part of the cached canvas despite being a movable atom")
	var/obj/item/carrier = allocate(/obj/item, origin)
	var/obj/item/endpoint = allocate(/obj/item, carrier)
	endpoint.anchored = TRUE
	var/datum/component/netrun_node/carried = endpoint.AddComponent(/datum/component/netrun_node, NETRUN_NODE_DECK)
	TEST_ASSERT(carried.is_dynamic(), "An anchored endpoint inside a carrier still moves with that carrier and needs the reactive layer")
	endpoint.forceMove(origin)
	TEST_ASSERT(!carried.is_dynamic(), "A now turf-bound anchored endpoint must return to the static layer")
	endpoint.anchored = FALSE
	TEST_ASSERT(carried.is_dynamic(), "An unanchored endpoint must remain reactive even while standing on one turf")

/// A large fan-out of terminal endpoints does not belong in Dijkstra's heap.
/datum/unit_test/netrun_route_terminal_frontier/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, origin.z)
	var/area/room = scene.room(/area/netrun_route_test)
	scene.take(origin, room)
	var/obj/machinery/power/apc/apc = scene.machine(/obj/machinery/power/apc, origin)
	var/datum/component/netrun_node/center = apc.GetComponent(/datum/component/netrun_node)
	var/datum/netrun_topology/graph = allocate(/datum/netrun_topology)
	graph.nodes[center.address] = center
	graph.adjacency[center.address] = list()
	var/list/leaves = list()
	for(var/i in 1 to 48)
		var/obj/item/host = allocate(/obj/item, origin)
		var/datum/component/netrun_node/node = host.AddComponent(/datum/component/netrun_node, NETRUN_NODE_DECK)
		leaves += node
		graph.nodes[node.address] = node
		graph.adjacency[node.address] = list()
		graph.add_edge(center.address, node.address, "endpoint")
	var/datum/component/netrun_node/offline_leaf = leaves[48]
	offline_leaf.offline_until = world.time + 1 MINUTES
	var/datum/netrun_path_tree/from_center = allocate(/datum/netrun_path_tree, graph, center)
	TEST_ASSERT_EQUAL(length(from_center.reached), 49, "All terminal destinations, including an offline leaf, must retain physical discovery")
	TEST_ASSERT_EQUAL(from_center.frontier_insertions, 1, "Forty-eight terminal endpoints must add zero heap entries")
	TEST_ASSERT_EQUAL(from_center.costs[offline_leaf.address], 1, "Offline destinations retain their geographic cost without forwarding traffic")
	TEST_ASSERT(from_center.network_index_ready, "A real path tree must publish its reached-network index")
	TEST_ASSERT(from_center.reached_networks[center.network.id], "The network reachability index must include the source LAN")
	var/datum/component/netrun_node/source = leaves[1]
	var/datum/netrun_path_tree/from_leaf = allocate(/datum/netrun_path_tree, graph, source)
	TEST_ASSERT_EQUAL(from_leaf.frontier_insertions, 2, "A terminal source adds only itself and the APC to the heap")
	TEST_ASSERT_EQUAL(from_leaf.costs[offline_leaf.address], 2, "The optimized fan-out must preserve both source and target cable costs")
