/// Real native machines and permissions consume explicit imported fixture rows.
/area/engineering/netrun_route_test
	area_flags = NONE
	requires_power = FALSE

/area/medical/netrun_route_test
	area_flags = NONE
	requires_power = FALSE

/area/netrun_route_test
	area_flags = NONE
	requires_power = FALSE

/// Own the topology before its areas, and restore shared world state even after an assertion fails.
/datum/netrun_route_scene
	var/list/owned = list()
	var/list/rooms = list()
	var/list/original_areas = list()
	var/list/original_turfs = list()
	var/list/original_traits = list()
	var/list/applied_traits = list()
	var/list/original_generators = list()
	var/original_disabled
	/// Isolated imported read-model; its expected star shape is a fixture declaration, not a solve.
	var/use_imported_fixture = TRUE
	var/datum/netrun_topology/import_fixture/fixture_graph
	var/datum/netrun_topology/previous_topology
	/// Supplied remote events exercise native adapters without a second physical solver.
	var/datum/netrun_external_fixture/scene_bus/bus
	var/datum/component/netrun_node/fixture_anchor
	var/list/fixture_endpoints = list()
	/// Each area declares its own supplied anchor; there is no geometric nearest-APC search.
	var/list/fixture_anchors = list()

/datum/netrun_route_scene/New(z)
	original_disabled = SSnetworks.station_network.setting_disabled
	mark_station(z)
	if(use_imported_fixture)
		previous_topology = SSnetrun.topology
		fixture_graph = new(src)
		SSnetrun.topology = fixture_graph
		bus = new(src)

/datum/netrun_route_scene/proc/mark_station(z)
	var/key = "[z]"
	if(key in original_traits)
		return
	var/datum/space_level/level = SSmapping.z_list[z]
	original_traits[key] = level.traits
	var/list/generators = GLOB.gravity_generators[key]
	original_generators[key] = generators?.Copy()
	level.traits = level.traits.Copy()
	level.traits[ZTRAIT_STATION] = TRUE
	applied_traits[key] = level.traits

/datum/netrun_route_scene/proc/room(area_type)
	var/area/result = new area_type
	rooms += result
	return result

/datum/netrun_route_scene/proc/take(turf/spot, area/room, make_floor = FALSE)
	if(!(spot in original_areas))
		original_areas[spot] = spot.loc
	if(make_floor && !isfloorturf(spot))
		original_turfs[spot] = spot.type
		spot = spot.ChangeTurf(/turf/open/floor/plasteel)
	room.contents += spot
	return spot

/datum/netrun_route_scene/proc/machine(machine_type, turf/spot)
	var/obj/machinery/result = new machine_type(spot)
	owned += result
	result.set_machine_stat(0)
	return result

/datum/netrun_route_scene/Destroy()
	QDEL_NULL(bus)
	var/restore_globals = !fixture_graph || SSnetrun.topology == fixture_graph
	var/list/deferred_spots = list()
	if(fixture_graph)
		if(SSnetrun.topology == fixture_graph)
			SSnetrun.topology = previous_topology
		else
			var/datum/netrun_topology/import_fixture/current = SSnetrun.topology
			for(var/depth in 1 to 64)
				if(!istype(current))
					break
				var/datum/netrun_route_scene/inner = current.scene_ref?.resolve()
				if(!inner)
					break
				for(var/turf/spot as anything in inner.original_areas)
					if(inner.original_areas[spot] in rooms)
						inner.original_areas[spot] = original_areas[spot]
						inner.original_turfs[spot] ||= original_turfs[spot]
						deferred_spots[spot] = TRUE
				for(var/key in inner.original_traits)
					if(inner.original_traits[key] == applied_traits[key])
						inner.original_traits[key] = original_traits[key]
						inner.original_generators[key] = original_generators[key]
				if(inner.previous_topology == fixture_graph)
					inner.previous_topology = previous_topology
					inner.original_disabled = original_disabled
					break
				current = inner.previous_topology
		QDEL_NULL(fixture_graph)
	previous_topology = null
	fixture_anchor = null
	fixture_endpoints.Cut()
	fixture_anchors.Cut()
	QDEL_LIST(owned)
	for(var/turf/spot as anything in original_areas)
		if(deferred_spots[spot])
			continue
		var/area/previous = original_areas[spot]
		previous.contents += spot
		if(original_turfs[spot])
			spot.ChangeTurf(original_turfs[spot])
	original_areas.Cut()
	original_turfs.Cut()
	QDEL_LIST(rooms)
	for(var/key in original_traits)
		var/z = text2num(key)
		var/datum/space_level/level = SSmapping.z_list[z]
		if(level.traits != applied_traits[key])
			continue
		level.traits = original_traits[key]
		GLOB.gravity_generators[key] = original_generators[key]
		SSmapping.calculate_z_level_gravity(z)
	original_traits.Cut()
	applied_traits.Cut()
	original_generators.Cut()
	if(restore_globals)
		SSnetworks.station_network.setting_disabled = original_disabled
	return ..()

/// Existing optical tests need real connectivity while retaining their public guest access setup.
/datum/unit_test/proc/netrun_connected_test_area()
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, run_loc_floor_bottom_left.z)
	var/area/room = scene.room(/area/netrun_route_test)
	for(var/turf/spot as anything in block(run_loc_floor_bottom_left, run_loc_floor_top_right))
		scene.take(spot, room)
	scene.machine(/obj/machinery/power/apc, run_loc_floor_bottom_left)
	return scene


/// A fixture supplies exact bindings and cumulative route costs; it never examines geometry or searches paths.
/datum/netrun_topology/import_fixture
	/// Declared scene scope prevents unrelated station machines entering the fixture.
	var/datum/weakref/scene_ref
	/// Source address -> expected immutable table.
	var/list/tables = list()

/datum/netrun_topology/import_fixture/New(datum/netrun_route_scene/scene)
	dirty = FALSE
	scene_ref = WEAKREF(scene)
	RegisterSignal(SSnetrun, COMSIG_NETRUN_NODE_REGISTERED, PROC_REF(on_node_registered))
	RegisterSignal(SSnetrun, COMSIG_NETRUN_NODE_UNREGISTERED, PROC_REF(on_node_unregistered))
	RegisterSignal(SSnetrun, COMSIG_NETRUN_NODE_MOVED, PROC_REF(on_node_moved))

/// Строки fixture уже заданы сценой; native signals не запускают ожидание отсутствующего remote graph.
/datum/netrun_topology/import_fixture/invalidate()
	return

/// Native registration declares area-owned stars; every edge has the fixture's supplied unit cost.
/datum/netrun_topology/import_fixture/on_node_registered(datum/source, datum/component/netrun_node/node)
	var/datum/netrun_route_scene/scene = scene_ref?.resolve()
	if(!scene || !(node.physical_turf() in scene.original_areas))
		return
	if(node.node_type == NETRUN_NODE_APC)
		if(!scene.fixture_anchor)
			scene.fixture_anchor = node
		scene.fixture_anchors[REF(apc_area(node))] = node
	if(node != scene.fixture_anchor)
		scene.fixture_endpoints |= node
	if(node.node_type == NETRUN_NODE_APC)
		scene.import_star()
		return
	clear_tables()
	var/datum/component/netrun_node/anchor = declared_anchor(node)
	import_binding(node, anchor, anchor ? SSnetrun.get_apc_network(anchor) : null)
	if(anchor)
		import_edge(anchor, node, 1)
	revision++

/datum/netrun_topology/import_fixture/on_node_unregistered(datum/source, datum/component/netrun_node/node)
	var/datum/netrun_route_scene/scene = scene_ref?.resolve()
	if(!scene || !node || nodes[node.address] != node)
		return
	scene.fixture_endpoints -= node
	for(var/area_key in scene.fixture_anchors.Copy())
		if(scene.fixture_anchors[area_key] == node)
			scene.fixture_anchors -= area_key
	if(scene.fixture_anchor == node)
		scene.fixture_anchor = null
	clear_tables()
	nodes -= node.address
	adjacency -= node.address
	var/list/center = adjacency[scene.fixture_anchor?.address]
	if(center)
		center -= node.address
	registered_apcs -= node.address
	registered_relays -= node.address
	relay_addresses -= node.address
	revision++

/// Import the scene's declared area attachment; no geometric or availability selection occurs.
/datum/netrun_topology/import_fixture/proc/declared_anchor(datum/component/netrun_node/node)
	var/datum/netrun_route_scene/scene = scene_ref?.resolve()
	if(!scene || !(node.physical_turf() in scene.original_areas))
		return null
	if(node.node_type == NETRUN_NODE_APC)
		return node
	var/datum/component/netrun_node/declared = scene.fixture_anchors[REF(get_base_area(node.physical_turf()))]
	return !QDELETED(declared) ? declared : (QDELETED(scene.fixture_anchor) ? null : scene.fixture_anchor)

/datum/netrun_topology/import_fixture/on_node_moved(datum/source, datum/component/netrun_node/node, turf/old_turf, turf/new_turf)
	if(nodes[node.address] != node || node.netrun_projection_fixture_owner?.resolve())
		return
	var/datum/component/netrun_node/previous_anchor = node.bound_apc
	var/datum/component/netrun_node/anchor = declared_anchor(node)
	if(previous_anchor != anchor)
		clear_tables()
	if(!QDELETED(previous_anchor) && previous_anchor != anchor)
		var/key = "[previous_anchor.address]>[node.address]"
		var/list/old_edge = edge_lookup[key]
		edges -= list(old_edge)
		edge_lookup -= key
		edge_lookup -= "[node.address]>[previous_anchor.address]"
		var/list/old_neighbors = adjacency[previous_anchor.address]
		if(old_neighbors)
			old_neighbors -= node.address
		var/list/node_neighbors = adjacency[node.address]
		if(node_neighbors)
			node_neighbors -= previous_anchor.address
	import_binding(node, anchor, anchor ? SSnetrun.get_apc_network(anchor) : null)
	if(anchor && node != anchor)
		import_edge(anchor, node, 1)
	if(previous_anchor != anchor)
		weight_revision++
		node.notify_changed(NETRUN_CHANGED_BINDING)
	node.observe_location()
	node.queue_presentation(NETRUN_CHANGED_STATE)

/// Install declared native LAN facts just as a successful external publication does.
/datum/netrun_topology/import_fixture/proc/import_binding(datum/component/netrun_node/node, datum/component/netrun_node/anchor, datum/netrun_network/network)
	if(node.network != network)
		node.leave_network(FALSE)
		node.network = network
		if(network)
			network.nodes |= node
	node.bound_apc = node == anchor ? null : anchor
	node.binding_checked = TRUE
	node.binding_infra_revision = infrastructure_revision
	node.topology_turf = node.physical_turf()
	node.binding_area = get_base_area(node.topology_turf)
	node.binding_sector = netrun_sector_for(node.topology_turf)
	node.pending_physical_update = FALSE
	nodes[node.address] = node
	if(node.node_type == NETRUN_NODE_APC)
		registered_apcs[node.address] = node
	if(is_relay(node))
		registered_relays[node.address] = node
		relay_addresses |= node.address

/// Paths and costs are supplied by the test; this adapter only imports their predecessor/edge rows.
/datum/netrun_topology/import_fixture/proc/import_path(list/path, list/cumulative_costs)
	var/datum/component/netrun_node/source = path[1]
	var/datum/netrun_path_tree/table = tables[source.address]
	if(!table)
		table = new(src, source)
		table.retained = TRUE
		table.network_index_ready = TRUE
		tables[source.address] = table
	for(var/index in 1 to length(path))
		var/datum/component/netrun_node/node = path[index]
		table.reached[node.address] = TRUE
		table.costs[node.address] = cumulative_costs[index]
		if(node.network)
			table.reached_networks[node.network.id] = node.address
		if(index == 1)
			continue
		var/datum/component/netrun_node/parent = path[index - 1]
		table.previous[node.address] = parent.address
		import_edge(parent, node, cumulative_costs[index] - cumulative_costs[index - 1])

/// Import one explicitly supplied edge, without evaluating or selecting any physical connection.
/datum/netrun_topology/import_fixture/proc/import_edge(datum/component/netrun_node/parent, datum/component/netrun_node/node, latency)
	var/key = "[parent.address]>[node.address]"
	if(edge_lookup[key])
		return
	var/list/edge = list("id" = "fixture:[key]", "from" = parent.address, "to" = node.address, "kind" = "endpoint", "latency" = latency)
	edges += list(edge)
	edge_lookup[key] = edge
	edge_lookup["[node.address]>[parent.address]"] = edge
	var/list/from = adjacency[parent.address]
	if(!from)
		from = list()
		adjacency[parent.address] = from
	from |= node.address
	var/list/to_neighbors = adjacency[node.address]
	if(!to_neighbors)
		to_neighbors = list()
		adjacency[node.address] = to_neighbors
	to_neighbors |= parent.address

/// Release fixture snapshots only after a declared input row changes.
/datum/netrun_topology/import_fixture/proc/clear_tables()
	for(var/address in tables)
		qdel(tables[address])
	tables.Cut()

/datum/netrun_topology/import_fixture/route_snapshot(datum/component/netrun_node/start, borrow = FALSE)
	var/datum/netrun_route_scene/scene = scene_ref?.resolve()
	if(!scene || !start || nodes[start.address] != start)
		return new /datum/netrun_path_tree
	var/datum/netrun_path_tree/table = tables[start.address]
	if(!table)
		if(QDELETED(scene.fixture_anchor))
			return new /datum/netrun_path_tree
		import_path(list(start), list(0))
		import_declared_pair(start, scene.fixture_anchor)
		for(var/datum/component/netrun_node/destination as anything in scene.fixture_endpoints)
			if(!QDELETED(destination) && destination != start && destination.binding_sector == start.binding_sector)
				import_declared_pair(start, destination)
		table = tables[start.address]
	return borrow ? table : table.copy()

/// Exact paths for the declared fixture stars, with no graph search or runtime latency calculation.
/datum/netrun_topology/import_fixture/proc/import_declared_pair(datum/component/netrun_node/start, datum/component/netrun_node/destination)
	var/datum/component/netrun_node/first_anchor = declared_anchor(start)
	var/datum/component/netrun_node/last_anchor = declared_anchor(destination)
	if(!first_anchor || !last_anchor)
		return
	var/list/path = list(start)
	if(start != first_anchor)
		path += first_anchor
	if(first_anchor != last_anchor)
		var/datum/netrun_route_scene/scene = scene_ref.resolve()
		if(first_anchor != scene.fixture_anchor && last_anchor != scene.fixture_anchor)
			path += scene.fixture_anchor
		path += last_anchor
	if(destination != last_anchor)
		path += destination
	var/list/costs = list()
	for(var/index in 1 to length(path))
		costs += index - 1
	import_path(path, costs)

/datum/netrun_topology/import_fixture/Destroy()
	for(var/address in tables)
		qdel(tables[address])
	tables.Cut()
	scene_ref = null
	return ..()

/// This fixture has exactly one declared center and unit-cost cables; every expected path is supplied explicitly.
/datum/netrun_route_scene/proc/import_star()
	fixture_graph.clear_tables()
	fixture_graph.nodes = list()
	fixture_graph.adjacency = list()
	fixture_graph.edges = list()
	fixture_graph.edge_lookup = list()
	fixture_graph.registered_apcs = list()
	fixture_graph.registered_relays = list()
	fixture_graph.relay_addresses = list()
	fixture_graph.revision++
	if(QDELETED(fixture_anchor))
		return
	fixture_graph.import_binding(fixture_anchor, fixture_anchor, SSnetrun.get_apc_network(fixture_anchor))
	for(var/datum/component/netrun_node/node as anything in fixture_endpoints.Copy())
		if(QDELETED(node))
			fixture_endpoints -= node
			continue
		var/datum/component/netrun_node/anchor = fixture_graph.declared_anchor(node)
		fixture_graph.import_binding(node, anchor, anchor ? SSnetrun.get_apc_network(anchor) : null)
		if(node.node_type == NETRUN_NODE_APC)
			if(node.binding_sector == fixture_anchor.binding_sector)
				fixture_graph.import_edge(fixture_anchor, node, 1)
		else if(anchor)
			fixture_graph.import_edge(anchor, node, 1)

/// Imported tables retain read-only borrows and isolate mutable operation snapshots.
/datum/unit_test/netrun_imported_route_table_ownership/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_topology/graph = scene.fixture_graph
	var/datum/netrun_path_tree/borrowed = graph.route_snapshot(scene.source.node, TRUE)
	var/datum/netrun_path_tree/owned = graph.route_snapshot(scene.source.node)
	allocated += owned
	TEST_ASSERT(borrowed.retained, "Projection owns retained route tables")
	TEST_ASSERT_EQUAL(owned.cost_to(scene.target.node.address), 2, "The imported fixture cost is returned unchanged")
	owned.reached.Cut()
	TEST_ASSERT(borrowed.path_available(graph, scene.target.node.address), "Changing an operation copy cannot mutate the imported table")
	TEST_ASSERT(!owned.path_available(graph, scene.target.node.address), "An empty operation copy cannot grant reachability")

/// Native authorization validates live forwarders over an already supplied path; it never discovers a replacement.
/datum/unit_test/netrun_imported_route_live_forwarder/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_path_tree/table = scene.fixture_graph.route_snapshot(scene.source.node, TRUE)
	TEST_ASSERT(table.path_available(scene.fixture_graph, scene.target.node.address), "The declared imported path starts usable")
	scene.apc.failure_timer = 5
	TEST_ASSERT(!table.path_available(scene.fixture_graph, scene.target.node.address), "A native forwarding outage revokes the imported path immediately")
	scene.apc.failure_timer = 0
	TEST_ASSERT(table.path_available(scene.fixture_graph, scene.target.node.address), "Restoring a fixture forwarder permits the same supplied path")

/// Nested fixture allocations must restore the real outer world even when disposed in creation order.
/datum/unit_test/netrun_fixture_scope_out_of_order/Run()
	var/datum/netrun_topology/original_graph = SSnetrun.topology
	var/datum/netrun_external_core/original_client = SSnetrun.external_core
	var/area/original_area = get_area(run_loc_floor_bottom_left)
	var/datum/space_level/level = SSmapping.z_list[run_loc_floor_bottom_left.z]
	var/list/original_level_traits = level.traits
	var/datum/netrun_route_scene/first = allocate(/datum/netrun_route_scene, run_loc_floor_bottom_left.z)
	first.take(run_loc_floor_bottom_left, first.room(/area/netrun_route_test))
	var/datum/netrun_route_scene/second = allocate(/datum/netrun_route_scene, run_loc_floor_bottom_left.z)
	var/area/inner_room = second.room(/area/netrun_route_test)
	second.take(run_loc_floor_bottom_left, inner_room)
	qdel(first)
	TEST_ASSERT_EQUAL(get_area(run_loc_floor_bottom_left), inner_room, "Outer teardown leaves the inner arena intact")
	TEST_ASSERT_EQUAL(SSnetrun.external_core, second.bus.client, "Disposing the outer fixture preserves the active inner client")
	TEST_ASSERT_EQUAL(SSnetrun.topology, second.fixture_graph, "Disposing the outer fixture preserves the active inner graph")
	qdel(second)
	TEST_ASSERT_EQUAL(SSnetrun.external_core, original_client, "Final teardown restores the original live binding")
	TEST_ASSERT_EQUAL(SSnetrun.topology, original_graph, "Final teardown restores the original graph")
	TEST_ASSERT_EQUAL(get_area(run_loc_floor_bottom_left), original_area, "Final teardown restores the original arena area")
	TEST_ASSERT_EQUAL(level.traits, original_level_traits, "Final teardown restores the original level traits")
