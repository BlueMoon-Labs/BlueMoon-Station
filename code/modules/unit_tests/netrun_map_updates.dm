/// Full-map projection revisions describe actual composition and status changes.
/datum/unit_test/netrun_map_full_projection_updates/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, origin.z)
	var/area/room = scene.room(/area/netrun_route_test)
	for(var/turf/spot as anything in block(origin, locate(origin.x + 10, origin.y + 1, origin.z)))
		scene.take(spot, room)
	for(var/i in 1 to 6)
		scene.machine(/obj/machinery/power/apc, locate(origin.x + (i - 1) * 2, origin.y + 1, origin.z))
	var/obj/machinery/computer/netrun_terminal/source = scene.machine(/obj/machinery/computer/netrun_terminal, origin)
	var/obj/machinery/computer/netrun_terminal/target = scene.machine(/obj/machinery/computer/netrun_terminal, locate(origin.x + 10, origin.y, origin.z))
	var/datum/component/netrun_node/target_node = target.GetComponent(/datum/component/netrun_node)
	SSnetrun.ensure_topology()
	source.console.workspace_view = "map"
	var/list/payload = source.console.ui_data(null)
	TEST_ASSERT(netrun_map_has_node(payload, target_node.address), "The complete permitted graph must include endpoints beyond four edges")
	var/list/map = payload["map"]
	var/structural = map["structure_revision"]
	var/state = map["state_revision"]
	payload = source.console.ui_data(null)
	map = payload["map"]
	TEST_ASSERT_EQUAL(map["structure_revision"], structural, "A repeated poll must reuse the structural generation")
	TEST_ASSERT_EQUAL(map["state_revision"], state, "A repeated unchanged poll must reuse the state generation")
	target.set_machine_stat(BROKEN)
	target_node.reconcile_state()
	payload = source.console.ui_data(null)
	map = payload["map"]
	TEST_ASSERT(netrun_map_has_node(payload, target_node.address), "An offline leaf remains a discoverable endpoint")
	TEST_ASSERT_EQUAL(map["structure_revision"], structural, "An offline leaf must not trigger a new layout generation")
	TEST_ASSERT(map["state_revision"] > state, "Native availability changes must publish a new status generation")
	var/old_address = target_node.address
	qdel(target)
	payload = source.console.ui_data(null)
	map = payload["map"]
	TEST_ASSERT(!netrun_map_has_node(payload, old_address), "Deleting a node must remove it on the next update without reopening UI")
	TEST_ASSERT(map["structure_revision"] > structural, "Removing a visible node must advance the projection generation")
	for(var/list/edge as anything in map["edges"])
		TEST_ASSERT(edge["from"] != old_address && edge["to"] != old_address, "Deleted endpoints must not leave dangling map edges")

/// Work counters verify that live overlays do not rebuild the stationary projection.
/datum/netrun_map_view/netrun_performance_test
	var/rebuilds = 0
	var/serialized_nodes = 0
	var/list/projected_by_address = list()

/datum/netrun_map_view/netrun_performance_test/rebuild(datum/netrun_topology/graph)
	rebuilds++
	return ..()

/datum/netrun_map_view/netrun_performance_test/project_entry(datum/component/netrun_node/node, neighbor_count)
	serialized_nodes++
	projected_by_address[node.address]++
	return ..()

/// Navigation must retain the station projection and update only route disclosure/APC shape.
/datum/unit_test/netrun_map_navigation_work/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, origin.z)
	var/area/room = scene.room(/area/netrun_route_test)
	for(var/turf/spot as anything in block(origin, locate(origin.x + 8, origin.y + 2, origin.z)))
		scene.take(spot, room)
	var/obj/machinery/power/apc/apc = scene.machine(/obj/machinery/power/apc, get_step(origin, NORTH))
	var/obj/machinery/computer/netrun_terminal/source = scene.machine(/obj/machinery/computer/netrun_terminal, origin)
	var/list/fixtures = list(apc.GetComponent(/datum/component/netrun_node), source.GetComponent(/datum/component/netrun_node))
	var/list/targets = list()
	for(var/i in 1 to 100)
		var/obj/item/device = allocate(/obj/item, locate(origin.x + i % 8, origin.y + 2, origin.z))
		var/datum/component/netrun_node/node = device.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
		fixtures += node
		targets += node
	SSnetrun.ensure_topology()
	for(var/datum/component/netrun_node/node as anything in fixtures)
		node.join_network()
		node.reconcile_state()
		node.publish_changes()
	var/datum/netrun_console/console = source.console
	qdel(console.map_view)
	var/datum/netrun_map_view/netrun_performance_test/view = new(console)
	console.map_view = view
	console.workspace_view = "map"
	console.ui_data(null)
	var/builds = view.rebuilds
	var/datum/component/netrun_node/unchanged = targets[100]
	var/projected = view.projected_by_address[unchanged.address]
	var/datum/component/netrun_node/first = targets[1]
	var/datum/component/netrun_node/second = targets[2]
	view.selected_address = first.address
	console.ui_data(null)
	view.waypoint_address = second.address
	console.ui_data(null)
	view.waypoint_address = null
	var/datum/component/netrun_node/apc_node = apc.GetComponent(/datum/component/netrun_node)
	view.selected_address = apc_node.address
	var/list/map = console.ui_data(null)["map"]
	var/list/zones = map["apc_zones"]
	TEST_ASSERT_EQUAL(length(zones), 1, "Selecting an APC must add its native shape without a whole map rebuild")
	TEST_ASSERT_EQUAL(zones[1]["address"], apc_node.address, "The selected APC owns the displayed shape")
	view.selected_address = first.address
	map = console.ui_data(null)["map"]
	TEST_ASSERT_EQUAL(length(map["apc_zones"]), 0, "Selecting an ordinary device must remove the previous APC shape")
	TEST_ASSERT_EQUAL(view.rebuilds, builds, "Selection and waypoint changes must retain the full permitted projection")
	TEST_ASSERT_EQUAL(view.projected_by_address[unchanged.address], projected, "Navigation must not serialize unrelated stationary devices")

/// Alternating viewers of one physical terminal retain isolated ownership projections.
/datum/unit_test/netrun_map_multiple_operators/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, origin.z)
	var/area/room = scene.room(/area/netrun_route_test)
	var/area/medical = scene.room(/area/medical/netrun_route_test)
	for(var/turf/spot as anything in block(origin, locate(origin.x + 3, origin.y + 2, origin.z)))
		scene.take(spot, room)
	var/turf/remote = scene.take(locate(origin.x + 6, origin.y, origin.z), medical)
	var/obj/machinery/power/apc/local_apc = scene.machine(/obj/machinery/power/apc, get_step(origin, NORTH))
	var/obj/machinery/power/apc/remote_apc = scene.machine(/obj/machinery/power/apc, scene.take(get_step(remote, NORTH), medical))
	var/obj/machinery/computer/netrun_terminal/source = scene.machine(/obj/machinery/computer/netrun_terminal, origin)
	var/mob/living/carbon/human/first_operator = allocate(/mob/living/carbon/human, remote)
	var/mob/living/carbon/human/second_operator = allocate(/mob/living/carbon/human, origin)
	var/obj/item/netrun_deck/private_deck = allocate(/obj/item/netrun_deck, first_operator)
	var/datum/component/netrun_node/private_node = private_deck.GetComponent(/datum/component/netrun_node)
	var/obj/item/private_device = allocate(/obj/item, remote)
	var/datum/component/netrun_node/grant_node = private_device.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
	var/list/fixtures = list(local_apc.GetComponent(/datum/component/netrun_node), remote_apc.GetComponent(/datum/component/netrun_node),
		source.GetComponent(/datum/component/netrun_node), private_node, grant_node)
	for(var/i in 1 to 100)
		var/obj/item/device = allocate(/obj/item, locate(origin.x + i % 3, origin.y + 2, origin.z))
		fixtures += device.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
	SSnetrun.ensure_topology()
	for(var/datum/component/netrun_node/node as anything in fixtures)
		node.join_network()
		node.reconcile_state()
		node.publish_changes()
	var/datum/netrun_console/console = source.console
	qdel(console.map_view)
	var/datum/netrun_map_view/netrun_performance_test/view = new(console)
	console.map_view = view
	console.workspace_view = "map"
	var/list/first_session = list("id" = 1)
	var/list/second_session = list("id" = 2)
	console.operator = first_operator
	var/list/first_map = console.ui_data(null)["map"]
	var/list/first_baseline = view.encode_wire(first_map, first_session)
	TEST_ASSERT(netrun_map_has_node(list("map" = first_map), private_node.address), "The owner's view must disclose their carried deck in a protected LAN")
	console.operator = second_operator
	var/list/second_map = console.ui_data(null)["map"]
	var/list/second_baseline = view.encode_wire(second_map, second_session)
	TEST_ASSERT(!netrun_map_has_node(list("map" = second_map), private_node.address), "Another viewer must not inherit the owner's private device")
	var/builds = view.rebuilds
	var/entries = view.serialized_nodes
	for(var/i in 1 to 5)
		console.operator = first_operator
		first_map = console.ui_data(null)["map"]
		var/list/first_delta = view.encode_wire(first_map, first_session)
		TEST_ASSERT(!first_delta["full"] && first_delta["epoch"] == first_baseline["epoch"], "Returning to the owner must keep their existing wire baseline")
		TEST_ASSERT(netrun_map_has_node(list("map" = first_map), private_node.address), "The owner must retain private ownership access after another viewer")
		console.operator = second_operator
		second_map = console.ui_data(null)["map"]
		var/list/second_delta = view.encode_wire(second_map, second_session)
		TEST_ASSERT(!second_delta["full"] && second_delta["epoch"] == second_baseline["epoch"], "The other viewer must keep an independent wire baseline")
		TEST_ASSERT(!netrun_map_has_node(list("map" = second_map), private_node.address), "Alternation must never disclose another operator's device")
	TEST_ASSERT_EQUAL(view.rebuilds, builds, "Two established viewers must not rebuild the station projection when alternating")
	TEST_ASSERT_EQUAL(view.serialized_nodes, entries, "Quiet alternating viewers must serialize zero stationary nodes")
	private_deck.burnt_until = world.time + 20 SECONDS
	view.on_node_changed(SSnetrun, private_node, NETRUN_CHANGED_STATE)
	console.operator = first_operator
	first_map = console.ui_data(null)["map"]
	var/list/activity = view.encode_wire(first_map, first_session)
	TEST_ASSERT(!activity["full"] && length(activity["nodes"]) == 1, "A parked owner's visible node must still receive its pending status delta")
	TEST_ASSERT(!activity["nodes"][1]["online"], "The restored projection must contain the node's current native status")
	console.access_session.node_access[grant_node.address] = NETRUN_ACCESS_ROOT
	view.invalidate_node_access(grant_node.address)
	first_map = console.ui_data(null)["map"]
	view.encode_wire(first_map, first_session)
	console.operator = second_operator
	second_map = console.ui_data(null)["map"]
	view.encode_wire(second_map, second_session)
	TEST_ASSERT(netrun_map_has_node(list("map" = second_map), grant_node.address), "A shared command-session grant must reach both operator projections")
	console.access_session.node_access -= grant_node.address
	view.invalidate_node_access(grant_node.address)
	console.operator = first_operator
	first_map = console.ui_data(null)["map"]
	var/list/revoked = view.encode_wire(first_map, first_session)
	TEST_ASSERT(!revoked["full"] && (grant_node.address in revoked["removed_nodes"]), "A parked projection must revoke its delivered node by delta")
	TEST_ASSERT(!netrun_map_has_node(list("map" = first_map), grant_node.address), "Restoring a projection must never restore a revoked grant")
	TEST_ASSERT_EQUAL(view.rebuilds, builds, "Node status and grants must reconcile without rebuilding either established projection")
	for(var/i in 1 to 9)
		console.operator = allocate(/mob/living, origin)
		view.select_operator_projection()
	TEST_ASSERT(length(view.operator_projections) <= 8, "A physical console must retain at most eight operator projections")
	console.operator = first_operator
	first_map = console.ui_data(null)["map"]
	var/list/reopened = view.encode_wire(first_map, first_session)
	TEST_ASSERT(reopened["full"] && reopened["epoch"] != first_baseline["epoch"], "An evicted viewer must receive a new complete baseline")
	view.suspend()
	TEST_ASSERT_EQUAL(length(view.operator_projections), 0, "Suspending the map must release every parked operator projection")

/// A hidden ordinary endpoint's packets/occupants cannot alter another viewer's map.
/datum/unit_test/netrun_map_hidden_activity_sleep/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/netrun_console/console = allocate(/datum/netrun_console, host)
	var/obj/item/device = allocate(/obj/item)
	var/datum/component/netrun_node/node = device.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
	var/datum/netrun_map_view/view = console.map_view
	view.snapshot = list()
	console.ui_dirty = FALSE
	view.on_node_changed(SSnetrun, node, NETRUN_CHANGED_OCCUPANTS)
	TEST_ASSERT(!console.ui_dirty && !length(view.dirty_nodes), "An unseen leaf's occupants must not wake an unrelated map")
	view.on_node_changed(SSnetrun, node, NETRUN_CHANGED_STATE)
	TEST_ASSERT(!console.ui_dirty && !length(view.dirty_nodes), "An unseen leaf's activity must not wake an unrelated map")
	view.shown_addresses[node.address] = TRUE
	view.on_node_changed(SSnetrun, node, NETRUN_CHANGED_STATE)
	TEST_ASSERT(console.ui_dirty && view.dirty_nodes[node.address], "A visible endpoint must still invalidate its own marker")
	view.dirty_nodes.Cut()
	view.shown_addresses.Cut()
	console.ui_dirty = FALSE
	view.on_node_changed(SSnetrun, node, NETRUN_CHANGED_BINDING)
	TEST_ASSERT(console.ui_dirty && view.dirty_nodes[node.address], "A binding change must still reconcile newly reachable endpoints")

/datum/netrun_map_geometry/netrun_performance_test
	var/builds = 0

/datum/netrun_map_geometry/netrun_performance_test/build_area_runs(area/room, z)
	builds++
	return ..()

/// Simultaneous viewers share area compression while expired native geometry is refreshed.
/datum/unit_test/netrun_map_shared_area_geometry/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, origin.z)
	var/area/room = scene.room(/area/netrun_route_test)
	scene.take(origin, room)
	scene.take(locate(origin.x + 2, origin.y, origin.z), room)
	// Area contents also enumerate occupants; only turfs define the room shape.
	allocate(/obj/item, origin)
	allocate(/mob, locate(origin.x + 2, origin.y, origin.z))
	var/datum/netrun_map_geometry/netrun_performance_test/first = allocate(/datum/netrun_map_geometry/netrun_performance_test)
	var/datum/netrun_map_geometry/netrun_performance_test/second = allocate(/datum/netrun_map_geometry/netrun_performance_test)
	var/key = "[REF(room)]:[origin.z]"
	first.area_run_cache -= key
	var/list/runs = first.area_runs(room, origin.z)
	TEST_ASSERT_EQUAL(length(runs), 2, "Native area compression must preserve the gap between disconnected tiles")
	TEST_ASSERT_EQUAL(second.area_runs(room, origin.z), runs, "Two viewers must share the same immutable compressed shape")
	TEST_ASSERT_EQUAL(first.builds + second.builds, 1, "Opening another viewer must not scan the same native area again")
	scene.take(get_step(origin, EAST), room)
	first.area_run_cache[key]["expires"] = world.time - 1
	var/list/refreshed = second.area_runs(room, origin.z)
	TEST_ASSERT_EQUAL(length(refreshed), 1, "Expired area geometry must reconcile native turf changes")
	TEST_ASSERT_EQUAL(refreshed[1]["width"], 3, "The reconciled shape must include the newly connected turf")
	TEST_ASSERT_EQUAL(first.builds + second.builds, 2, "Refreshing an expired shape scans it exactly once")
	first.area_run_cache -= key

/// A fixture where one endpoint is private until a node-specific grant is held.
/datum/netrun_console/netrun_visibility_test
	var/private_address

/datum/netrun_console/netrun_visibility_test/node_visible(datum/component/netrun_node/node)
	if(node.address == private_address)
		return node_level(node) >= NETRUN_ACCESS_ROOT
	return ..()

/// Grant and revoke one private endpoint without projecting the whole station.
/datum/unit_test/netrun_map_access_visibility_delta/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, origin.z)
	var/area/room = scene.room(/area/netrun_route_test)
	for(var/turf/spot as anything in block(origin, locate(origin.x + 8, origin.y + 2, origin.z)))
		scene.take(spot, room)
	scene.machine(/obj/machinery/power/apc, get_step(origin, NORTH))
	var/obj/machinery/computer/netrun_terminal/source = scene.machine(/obj/machinery/computer/netrun_terminal, origin)
	var/obj/machinery/computer/netrun_terminal/target = scene.machine(/obj/machinery/computer/netrun_terminal, get_step(origin, EAST))
	var/datum/component/netrun_node/target_node = target.GetComponent(/datum/component/netrun_node)
	var/list/fixture_nodes = list(target_node, source.GetComponent(/datum/component/netrun_node))
	for(var/i in 1 to 200)
		var/obj/item/device = allocate(/obj/item, locate(origin.x + i % 8, origin.y + 2, origin.z))
		fixture_nodes += device.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
	qdel(source.console)
	var/datum/netrun_console/netrun_visibility_test/console = new(source)
	source.console = console
	console.private_address = target_node.address
	qdel(console.map_view)
	var/datum/netrun_map_view/netrun_performance_test/view = new(console)
	console.map_view = view
	console.workspace_view = "map"
	SSnetrun.ensure_topology()
	for(var/datum/component/netrun_node/node as anything in fixture_nodes)
		node.join_network()
		node.reconcile_state()
		node.publish_changes()
	var/list/map = console.ui_data(null)["map"]
	TEST_ASSERT(!netrun_map_has_node(list("map" = map), target_node.address), "The private endpoint begins hidden")
	var/list/session = list("id" = 1)
	var/list/baseline = view.encode_wire(map, session)
	var/list/slow_session = session.Copy()
	var/builds = view.rebuilds
	var/projected = view.serialized_nodes
	console.access_session.node_access[target_node.address] = NETRUN_ACCESS_ROOT
	view.invalidate_node_access(target_node.address)
	map = console.ui_data(null)["map"]
	var/list/granted = view.encode_wire(map, session)
	TEST_ASSERT_EQUAL(view.rebuilds, builds, "Granting one node must not rebuild all 200 stationary endpoints")
	TEST_ASSERT_EQUAL(view.serialized_nodes, projected + 1, "Granting one node projects only the newly visible endpoint")
	TEST_ASSERT(!granted["full"] && length(granted["nodes"]) == 1, "Grant must transmit a single node delta")
	TEST_ASSERT_EQUAL(granted["epoch"], baseline["epoch"], "The same operator keeps its stream on a grant")
	TEST_ASSERT(netrun_map_has_node(list("map" = map), target_node.address), "Grant must disclose the private endpoint")
	view.selected_address = target_node.address
	map = console.ui_data(null)["map"]
	view.encode_wire(map, session)
	builds = view.rebuilds
	target_node.raise_firewall()
	map = console.ui_data(null)["map"]
	var/list/revoked = view.encode_wire(map, session)
	TEST_ASSERT_EQUAL(view.rebuilds, builds, "Firewall revocation must not rebuild the other endpoints")
	TEST_ASSERT(!revoked["full"] && (target_node.address in revoked["removed_nodes"]), "Revocation must remove the endpoint in the next wire delta")
	TEST_ASSERT_EQUAL(revoked["epoch"], baseline["epoch"], "Revocation remains on the same authenticated stream")
	TEST_ASSERT(!netrun_map_has_node(list("map" = map), target_node.address), "Revoked endpoint must leave the current projection")
	TEST_ASSERT(!(target_node.address in view.revealed_addresses), "A previously selected target must lose route disclosure when its access is revoked")
	var/list/catchup = view.encode_wire(map, slow_session)
	for(var/list/entry as anything in catchup["nodes"])
		TEST_ASSERT(entry["address"] != target_node.address, "A slow viewer must never receive a stale upsert after revocation")
	session["force_full"] = TRUE
	var/list/recovery = view.encode_wire(map, session)
	TEST_ASSERT(recovery["full"] && !netrun_map_has_node(list("map" = recovery), target_node.address), "Resync must never disclose the revoked endpoint")
	console.operator = allocate(/mob/living/carbon/human, origin)
	map = console.ui_data(null)["map"]
	var/list/replaced = view.encode_wire(map, session)
	TEST_ASSERT(replaced["full"] && replaced["epoch"] != baseline["epoch"], "A different operator must receive an isolated baseline")

/// Crossing protected LANs must only reproject the LANs whose permissions changed.
/datum/unit_test/netrun_map_cross_lan_load/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, origin.z)
	var/area/engineering = scene.room(/area/engineering/netrun_route_test)
	var/area/medical = scene.room(/area/medical/netrun_route_test)
	var/area/general = scene.room(/area/netrun_route_test)
	var/turf/first = scene.take(origin, engineering)
	var/turf/second = scene.take(locate(origin.x + 4, origin.y, origin.z), medical)
	var/turf/other = scene.take(locate(origin.x + 8, origin.y, origin.z), general)
	scene.machine(/obj/machinery/power/apc, scene.take(get_step(first, NORTH), engineering))
	scene.machine(/obj/machinery/power/apc, scene.take(get_step(second, NORTH), medical))
	scene.machine(/obj/machinery/power/apc, scene.take(get_step(other, NORTH), general))
	var/obj/machinery/computer/netrun_terminal/source = scene.machine(/obj/machinery/computer/netrun_terminal, first)
	var/list/fixtures = list(source.GetComponent(/datum/component/netrun_node))
	var/list/other_nodes = list()
	var/datum/component/netrun_node/engineering_node
	var/datum/component/netrun_node/medical_node
	for(var/i in 1 to 20)
		var/obj/item/device = allocate(/obj/item, i <= 10 ? first : second)
		var/datum/component/netrun_node/node = device.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
		fixtures += node
		if(i == 1)
			engineering_node = node
		if(i == 11)
			medical_node = node
	for(var/i in 1 to 2000)
		var/obj/item/device = allocate(/obj/item, other)
		var/datum/component/netrun_node/node = device.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
		node.required_access = list(ACCESS_SECURITY)
		fixtures += node
		other_nodes += node
		if(!(i % 100))
			CHECK_TICK
	SSnetworks.station_network.setting_disabled = TRUE
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	var/settled = 0
	for(var/datum/component/netrun_node/node as anything in fixtures)
		node.join_network()
		node.reconcile_state()
		node.publish_changes()
		if(!((++settled) % 100))
			CHECK_TICK
	var/datum/component/netrun_node/source_node = source.GetComponent(/datum/component/netrun_node)
	var/datum/netrun_console/console = source.console
	qdel(console.map_view)
	var/datum/netrun_map_view/netrun_performance_test/view = new(console)
	console.map_view = view
	console.workspace_view = "map"
	var/list/map = console.ui_data(null)["map"]
	TEST_ASSERT(netrun_map_has_node(list("map" = map), engineering_node.address), "The original home LAN must be visible")
	TEST_ASSERT(!netrun_map_has_node(list("map" = map), medical_node.address), "The medical LAN begins protected")
	var/datum/component/netrun_node/first_other = other_nodes[1]
	TEST_ASSERT(netrun_map_has_node(list("map" = map), first_other.address), "The unrelated LAN must be visible in the load fixture")
	var/list/session = list("id" = 2)
	var/list/baseline = view.encode_wire(map, session)
	var/builds = view.rebuilds
	var/list/before = view.projected_by_address.Copy()
	var/revision = graph.revision
	for(var/step in 1 to 4)
		var/turf/destination = step % 2 ? second : first
		source.forceMove(destination)
		source_node.join_network()
		source_node.publish_changes()
		map = console.ui_data(null)["map"]
		var/list/delta = view.encode_wire(map, session)
		TEST_ASSERT(!delta["full"] && delta["epoch"] == baseline["epoch"], "Crossing LANs must retain the same UI stream")
		TEST_ASSERT_EQUAL(view.rebuilds, builds, "Crossing connected LANs must not rebuild the whole map")
		TEST_ASSERT_EQUAL(netrun_map_has_node(list("map" = map), engineering_node.address), !(step % 2), "Engineering visibility follows the current home LAN")
		TEST_ASSERT_EQUAL(netrun_map_has_node(list("map" = map), medical_node.address), !!(step % 2), "Medical visibility follows the current home LAN")
		TEST_ASSERT(length(delta["nodes"]) < 100 && length(delta["removed_nodes"]) < 100, "Each transition transmits only the affected LANs")
	TEST_ASSERT_EQUAL(graph.revision, revision, "Moving the source does not rebuild physical topology")
	for(var/datum/component/netrun_node/node as anything in other_nodes)
		TEST_ASSERT_EQUAL(view.projected_by_address[node.address], before[node.address], "Unchanged LAN nodes must never be projected again")
	var/network_id = medical_node.network.id
	console.access_session.network_access[network_id] = NETRUN_ACCESS_GUEST
	view.invalidate_network_access(network_id)
	map = console.ui_data(null)["map"]
	var/list/granted = view.encode_wire(map, session)
	TEST_ASSERT(!granted["full"] && netrun_map_has_node(list("map" = map), medical_node.address), "A network grant must disclose its devices by delta")
	console.access_session.network_access -= network_id
	view.invalidate_network_access(network_id)
	map = console.ui_data(null)["map"]
	var/list/revoked = view.encode_wire(map, session)
	TEST_ASSERT(!revoked["full"] && (medical_node.address in revoked["removed_nodes"]), "Revoking a network grant must remove its devices by delta")
	TEST_ASSERT_EQUAL(view.rebuilds, builds, "Network grants and revocations must retain the full projection")
	TEST_ASSERT(console.create_text_file("unrelated.txt", "text"), "The fixture can create a normal text file")
	map = console.ui_data(null)["map"]
	var/list/text_update = view.encode_wire(map, session)
	TEST_ASSERT(!text_update["full"] && !length(text_update["nodes"]), "A text file cannot force a new map")
	TEST_ASSERT_EQUAL(view.rebuilds, builds, "A normal text file must not rebuild the map")
	var/datum/netrun_network/medical_network = medical_node.network
	var/datum/netrun_file/key = new("medical.key", NETRUN_FILE_KEY, medical_network.passcode, 1, medical_network.id)
	TEST_ASSERT(console.store_file(key), "A valid network key fits in local storage")
	map = console.ui_data(null)["map"]
	var/list/key_grant = view.encode_wire(map, session)
	TEST_ASSERT(!key_grant["full"] && netrun_map_has_node(list("map" = map), medical_node.address), "Adding a network key discloses that LAN by delta")
	TEST_ASSERT(console.delete_local_file(key), "The network key can be removed")
	map = console.ui_data(null)["map"]
	var/list/key_revoke = view.encode_wire(map, session)
	TEST_ASSERT(!key_revoke["full"] && (medical_node.address in key_revoke["removed_nodes"]), "Removing the key revokes disclosure by delta")
	TEST_ASSERT_EQUAL(view.rebuilds, builds, "Key changes must not rebuild the entire projection")
	var/mob/living/carbon/human/operator = allocate(/mob/living/carbon/human, first)
	var/obj/item/clothing/under/color/grey/uniform = allocate(/obj/item/clothing/under/color/grey)
	TEST_ASSERT(operator.equip_to_slot_if_possible(uniform, ITEM_SLOT_ICLOTHING, disable_warning = TRUE), "The operator wears a real uniform for the ID slot")
	console.operator = operator
	map = console.ui_data(null)["map"]
	var/list/id_session = list("id" = 4)
	var/list/id_baseline = view.encode_wire(map, id_session)
	var/id_builds = view.rebuilds
	var/list/id_before = view.projected_by_address.Copy()
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	card.access = list(ACCESS_MEDICAL)
	TEST_ASSERT(operator.equip_to_slot_if_possible(card, ITEM_SLOT_ID, disable_warning = TRUE), "The operator equips the real medical ID")
	map = console.ui_data(null)["map"]
	var/list/id_grant = view.encode_wire(map, id_session)
	TEST_ASSERT(!id_grant["full"] && id_grant["epoch"] == id_baseline["epoch"], "Equipping an ID updates the existing stream")
	TEST_ASSERT(netrun_map_has_node(list("map" = map), medical_node.address), "The real medical ID discloses the medical LAN")
	TEST_ASSERT_EQUAL(view.rebuilds, id_builds, "Equipping the ID must not rebuild the map")
	TEST_ASSERT(operator.dropItemToGround(card), "The actual worn ID is removed")
	map = console.ui_data(null)["map"]
	var/list/id_revoke = view.encode_wire(map, id_session)
	TEST_ASSERT(!id_revoke["full"] && (medical_node.address in id_revoke["removed_nodes"]), "Removing the real ID revokes medical devices by delta")
	TEST_ASSERT_EQUAL(view.rebuilds, id_builds, "Removing the ID must not rebuild the map")
	for(var/datum/component/netrun_node/node as anything in other_nodes)
		TEST_ASSERT_EQUAL(view.projected_by_address[node.address], id_before[node.address], "An unrelated secured LAN must not be reprojected by the medical ID")
	// Exercise the actual resident's enter_node lifecycle, which changes both
	// route source and selection even when the operator/session stay the same.
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity)
	entity.enter_node(engineering_node)
	var/datum/netrun_console/entity/resident = entity.console
	qdel(resident.map_view)
	var/datum/netrun_map_view/netrun_performance_test/entity_view = new(resident)
	resident.map_view = entity_view
	entity_view.selected_address = engineering_node.address
	resident.workspace_view = "map"
	map = resident.ui_data(null)["map"]
	var/list/entity_session = list("id" = 3)
	var/list/entity_baseline = entity_view.encode_wire(map, entity_session)
	var/entity_builds = entity_view.rebuilds
	var/list/entity_before = entity_view.projected_by_address.Copy()
	entity.enter_node(engineering_node.bound_apc)
	var/entity_started = TICK_USAGE
	map = resident.ui_data(null)["map"]
	var/same_lan_ms = max(0, TICK_DELTA_TO_MS(TICK_USAGE - entity_started))
	var/list/same_lan = entity_view.encode_wire(map, entity_session)
	TEST_ASSERT(!same_lan["full"] && same_lan["epoch"] == entity_baseline["epoch"], "Resident movement between hosts must keep the same wire stream")
	TEST_ASSERT_EQUAL(entity_view.rebuilds, entity_builds, "Entering an APC must not rebuild the station map")
	TEST_ASSERT_EQUAL(length(map["apc_zones"]), 1, "Selecting the new APC must update its displayed zone")
	entity.enter_node(medical_node.bound_apc)
	entity_started = TICK_USAGE
	map = resident.ui_data(null)["map"]
	var/cross_lan_ms = max(0, TICK_DELTA_TO_MS(TICK_USAGE - entity_started))
	var/list/cross_lan = entity_view.encode_wire(map, entity_session)
	log_world("NETRUN LOAD resident hops: unrelated=2000 same_lan_cpu_ms=[round(same_lan_ms, 0.01)] same_nodes=[length(same_lan["nodes"])] same_edges=[length(same_lan["edges"])] cross_lan_cpu_ms=[round(cross_lan_ms, 0.01)] cross_nodes=[length(cross_lan["nodes"])] cross_edges=[length(cross_lan["edges"])] cross_removed_nodes=[length(cross_lan["removed_nodes"])] cross_removed_edges=[length(cross_lan["removed_edges"])].")
	TEST_ASSERT(!cross_lan["full"] && cross_lan["epoch"] == entity_baseline["epoch"], "Cross-LAN resident hops must publish deltas on the same UI stream")
	TEST_ASSERT_EQUAL(entity_view.rebuilds, entity_builds, "Cross-LAN resident hops must not rebuild the station map")
	TEST_ASSERT(!netrun_map_has_node(list("map" = map), engineering_node.address), "The former home LAN must be hidden after a resident leaves")
	TEST_ASSERT(netrun_map_has_node(list("map" = map), medical_node.address), "The resident's new home LAN must become visible")
	TEST_ASSERT(engineering_node.address in cross_lan["removed_nodes"], "The wire delta must revoke nodes from the old resident LAN")
	var/list/zones = map["apc_zones"]
	TEST_ASSERT_EQUAL(zones[1]["address"], medical_node.bound_apc.address, "The APC zone follows the new selected host")
	for(var/datum/component/netrun_node/node as anything in other_nodes)
		TEST_ASSERT_EQUAL(entity_view.projected_by_address[node.address], entity_before[node.address], "Resident hops cannot reproject the 2000 unrelated endpoints")

/// Physical movement of a wireless deck does not grant its wearer's new LAN.
/datum/unit_test/netrun_map_wireless_cross_lan/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, origin.z)
	var/area/engineering = scene.room(/area/engineering/netrun_route_test)
	var/area/medical = scene.room(/area/medical/netrun_route_test)
	var/turf/first = scene.take(origin, engineering)
	var/turf/second = scene.take(locate(origin.x + 4, origin.y, origin.z), medical)
	scene.machine(/obj/machinery/power/apc, scene.take(get_step(first, NORTH), engineering))
	scene.machine(/obj/machinery/power/apc, scene.take(get_step(second, NORTH), medical))
	var/mob/living/carbon/human/carrier = allocate(/mob/living/carbon/human, first)
	var/obj/item/netrun_deck/deck = allocate(/obj/item/netrun_deck, carrier)
	var/obj/item/peer = allocate(/obj/item, second)
	var/datum/component/netrun_node/peer_node = peer.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
	var/datum/component/netrun_node/source_node = deck.GetComponent(/datum/component/netrun_node)
	SSnetrun.ensure_topology()
	var/datum/netrun_console/console = deck.console
	qdel(console.map_view)
	var/datum/netrun_map_view/netrun_performance_test/view = new(console)
	console.map_view = view
	console.workspace_view = "map"
	var/list/map = console.ui_data(null)["map"]
	TEST_ASSERT(console.connection.wireless, "A portable deck uses wireless connection rules")
	TEST_ASSERT(!netrun_map_has_node(list("map" = map), peer_node.address), "The remote protected LAN starts hidden")
	var/builds = view.rebuilds
	carrier.forceMove(second)
	source_node.join_network()
	source_node.publish_changes()
	map = console.ui_data(null)["map"]
	TEST_ASSERT(!netrun_map_has_node(list("map" = map), peer_node.address), "Walking into that LAN must not grant a wireless deck access")
	TEST_ASSERT_EQUAL(view.rebuilds, builds, "Wireless movement with unchanged grants must retain the map")

/// Walking a carried terminal must update its marker, not rebuild every permitted endpoint.
/datum/unit_test/netrun_map_carrier_motion_work/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, origin.z)
	var/area/room = scene.room(/area/netrun_route_test)
	for(var/turf/spot as anything in block(origin, locate(origin.x + 8, origin.y + 2, origin.z)))
		scene.take(spot, room)
	scene.machine(/obj/machinery/power/apc, get_step(origin, NORTH))
	var/mob/living/carbon/human/carrier = allocate(/mob/living/carbon/human, origin)
	var/obj/item/netrun_deck/deck = allocate(/obj/item/netrun_deck, carrier)
	for(var/i in 1 to 100)
		var/obj/item/device = allocate(/obj/item, locate(origin.x + i % 8, origin.y + 2, origin.z))
		device.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
	var/datum/netrun_console/console = deck.console
	qdel(console.map_view)
	var/datum/netrun_map_view/netrun_performance_test/view = new(console)
	console.map_view = view
	console.workspace_view = "map"
	console.ui_data(null)
	var/builds = view.rebuilds
	var/entries = view.serialized_nodes
	var/paint = view.static_revision
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	var/graph_revision = graph.revision
	var/datum/component/netrun_node/source = deck.GetComponent(/datum/component/netrun_node)
	var/datum/netrun_path_tree/table = graph.route_tables[source.address]
	var/started = TICK_USAGE
	for(var/i in 1 to 20)
		carrier.forceMove(locate(origin.x + i % 2, origin.y, origin.z))
		console.ui_data(null)
	world.log << "NETRUN_LOAD 100 endpoints, 20 carrier moves: [round(TICK_DELTA_TO_MS(TICK_USAGE - started), 0.01)]ms; map rebuilds [view.rebuilds - builds], projected [view.serialized_nodes - entries]."
	TEST_ASSERT_EQUAL(view.rebuilds, builds, "Twenty same-area carrier moves must not rebuild the full permitted map")
	TEST_ASSERT(view.serialized_nodes <= entries + 20, "Movement must project only the moving endpoint, independent of the other hundred nodes")
	TEST_ASSERT_EQUAL(view.static_revision, paint, "Carried endpoint movement must retain the stationary Pixi canvas")
	TEST_ASSERT_EQUAL(graph.revision, graph_revision, "A moving leaf must retain the structural topology")
	TEST_ASSERT_EQUAL(graph.route_tables[source.address], table, "Movement must reuse the retained source tree")

/// Many simultaneous moving viewers must keep stationary projection work out of the hot path.
/datum/unit_test/netrun_map_station_motion_load/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, origin.z)
	var/area/room = scene.room(/area/netrun_route_test)
	for(var/turf/spot as anything in block(origin, locate(origin.x + 8, origin.y + 2, origin.z)))
		scene.take(spot, room)
	var/obj/machinery/power/apc/apc = scene.machine(/obj/machinery/power/apc, get_step(origin, NORTH))
	var/list/fixture_nodes = list(apc.GetComponent(/datum/component/netrun_node))
	var/list/stationary_nodes = list()
	for(var/i in 1 to 2000)
		var/obj/item/device = allocate(/obj/item, locate(origin.x + i % 8, origin.y + 2, origin.z))
		var/datum/component/netrun_node/node = device.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
		fixture_nodes += node
		stationary_nodes += node
		if(!(i % 100))
			CHECK_TICK
	var/list/carriers = list()
	var/list/consoles = list()
	var/list/builds = list()
	var/list/entries = list()
	var/list/address_entries = list()
	for(var/i in 1 to 8)
		var/mob/living/carbon/human/carrier = allocate(/mob/living/carbon/human, origin)
		var/obj/item/netrun_deck/deck = allocate(/obj/item/netrun_deck, carrier)
		fixture_nodes += deck.GetComponent(/datum/component/netrun_node)
		carriers += carrier
		var/datum/netrun_console/console = deck.console
		qdel(console.map_view)
		var/datum/netrun_map_view/netrun_performance_test/view = new(console)
		console.map_view = view
		console.workspace_view = "map"
		consoles += console
	SSnetrun.ensure_topology()
	// Initialization queues the first native status reconciliation. Complete that
	// separate workload before measuring movement so a CHECK_TICK cannot make it
	// look as if the first motion changed every stationary fixture's occupancy.
	var/settle_ms = 0
	for(var/datum/component/netrun_node/node as anything in fixture_nodes)
		var/started = TICK_USAGE
		node.join_network()
		node.reconcile_state()
		node.publish_changes()
		settle_ms += max(0, TICK_DELTA_TO_MS(TICK_USAGE - started))
		CHECK_TICK
	var/warm_ms = 0
	for(var/datum/netrun_console/console as anything in consoles)
		var/started = TICK_USAGE
		console.ui_data(null)
		warm_ms += max(0, TICK_DELTA_TO_MS(TICK_USAGE - started))
		var/datum/netrun_map_view/netrun_performance_test/view = console.map_view
		builds[console] = view.rebuilds
		entries[console] = view.serialized_nodes
		address_entries[console] = view.projected_by_address.Copy()
		CHECK_TICK
	for(var/datum/netrun_console/console as anything in consoles)
		console.ui_data(null)
		var/datum/netrun_map_view/netrun_performance_test/view = console.map_view
		log_world("NETRUN LOAD movement warmup: viewer=[consoles.Find(console)] initial_projected=[entries[console]] quiet_projected=[view.serialized_nodes - entries[console]] rebuilds=[view.rebuilds - builds[console]] dirty=[length(view.dirty_nodes)]")
		TEST_ASSERT_EQUAL(view.serialized_nodes, entries[console], "A settled stationary fixture must have a quiet projection before measuring movement")
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	var/revision = graph.revision
	var/elapsed_ms = 0
	var/peak_poll_ms = 0
	var/move_ms = 0
	var/peak_move_ms = 0
	for(var/step in 1 to 24)
		var/move_started = TICK_USAGE
		for(var/mob/living/carbon/human/carrier as anything in carriers)
			carrier.forceMove(locate(origin.x + step % 2, origin.y, origin.z))
		var/move_cost_ms = max(0, TICK_DELTA_TO_MS(TICK_USAGE - move_started))
		move_ms += move_cost_ms
		peak_move_ms = max(peak_move_ms, move_cost_ms)
		for(var/datum/netrun_console/console as anything in consoles)
			var/started = TICK_USAGE
			console.ui_data(null)
			var/cost_ms = max(0, TICK_DELTA_TO_MS(TICK_USAGE - started))
			elapsed_ms += cost_ms
			peak_poll_ms = max(peak_poll_ms, cost_ms)
		CHECK_TICK
	var/projected = 0
	var/stationary_projected = 0
	for(var/datum/netrun_console/console as anything in consoles)
		var/datum/netrun_map_view/netrun_performance_test/view = console.map_view
		var/changed = view.serialized_nodes - entries[console]
		var/static_changed = 0
		var/list/baseline = address_entries[console]
		for(var/datum/component/netrun_node/node as anything in stationary_nodes)
			static_changed += view.projected_by_address[node.address] - baseline[node.address]
		log_world("NETRUN LOAD movement observations: viewer=[consoles.Find(console)] projected=[changed] stationary_projected=[static_changed] full_rebuilds=[view.rebuilds - builds[console]]")
		projected += changed
		stationary_projected += static_changed
	log_world("NETRUN LOAD movement: stationary=2000 carriers=8 steps=24 ui_polls=192 projected=[projected] stationary_projected=[stationary_projected] settle_cpu_ms=[round(settle_ms, 0.01)] warm_cpu_ms=[round(warm_ms, 0.01)] move_cpu_ms=[round(move_ms, 0.01)] peak_move_ms=[round(peak_move_ms, 0.01)] poll_cpu_ms=[round(elapsed_ms, 0.01)] peak_poll_ms=[round(peak_poll_ms, 0.01)]")
	for(var/datum/netrun_console/console as anything in consoles)
		var/datum/netrun_map_view/netrun_performance_test/view = console.map_view
		TEST_ASSERT_EQUAL(view.rebuilds, builds[console], "Concurrent carried endpoints must retain all eight complete map projections")
		TEST_ASSERT(view.serialized_nodes - entries[console] <= 8 * 24, "Projection work must depend on moving endpoints, not the two thousand stationary devices")
	TEST_ASSERT_EQUAL(stationary_projected, 0, "Repeated movement must never reproject the two thousand unchanged devices")
	TEST_ASSERT_EQUAL(graph.revision, revision, "Repeated same-area player movement must not rebuild station topology")

/// A movement signal must not measure cables, scan APCs or walk active route tables inline.
/datum/unit_test/netrun_movement_queues_binding/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, origin.z)
	var/area/room = scene.room(/area/netrun_route_test)
	scene.take(origin, room)
	var/turf/destination = scene.take(get_step(origin, EAST), room)
	scene.machine(/obj/machinery/power/apc, scene.take(get_step(origin, NORTH), room))
	var/obj/item/endpoint = allocate(/obj/item, origin)
	var/datum/component/netrun_node/node = endpoint.AddComponent(/datum/component/netrun_node, NETRUN_NODE_DECK)
	SSnetrun.ensure_topology()
	var/turf/previous = node.topology_turf
	endpoint.forceMove(destination)
	TEST_ASSERT_EQUAL(node.topology_turf, previous, "Movement must defer binding/weight work until the queued task or explicit route consumer")
	TEST_ASSERT(SSnetrun.get_task_scheduler().by_key["node:[REF(node)]"], "Movement must queue one bounded node update")
	var/datum/netrun_task/node/task = allocate(/datum/netrun_task/node, "node", "motion-test", NETRUN_TASK_NORMAL, node)
	task.execute(SSnetrun)
	TEST_ASSERT_EQUAL(node.topology_turf, destination, "The worker must reconcile the latest physical position")

/datum/unit_test/netrun_map_incremental_work/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, origin.z)
	var/area/room = scene.room(/area/netrun_route_test)
	scene.take(origin, room)
	var/turf/apc_spot = scene.take(get_step(origin, NORTH), room)
	var/turf/target_spot = scene.take(get_step(origin, EAST), room)
	scene.machine(/obj/machinery/power/apc, apc_spot)
	var/obj/machinery/computer/netrun_terminal/source = scene.machine(/obj/machinery/computer/netrun_terminal, origin)
	var/obj/machinery/computer/netrun_terminal/target = scene.machine(/obj/machinery/computer/netrun_terminal, target_spot)
	var/datum/component/netrun_node/node = target.GetComponent(/datum/component/netrun_node)
	var/datum/netrun_console/console = source.console
	qdel(console.map_view)
	var/datum/netrun_map_view/netrun_performance_test/view = new(console)
	console.map_view = view
	console.workspace_view = "map"
	SSnetrun.ensure_topology()
	var/list/payload = console.ui_data(null)
	var/list/map = payload["map"]
	var/paint = map["static_revision"]
	var/generation = map["state_revision"]
	var/builds = view.rebuilds
	var/entries = view.serialized_nodes
	console.process_tick(1)
	console.ui_data(null)
	TEST_ASSERT_EQUAL(view.rebuilds, builds, "An idle console tick must reuse its permitted map instead of rebuilding every node")
	TEST_ASSERT_EQUAL(view.serialized_nodes, entries, "A quiet UI request must serialize zero node entries")
	node.touch()
	payload = console.ui_data(null)
	map = payload["map"]
	TEST_ASSERT_EQUAL(view.rebuilds, builds, "Activity must update its indexed entry without rebuilding the full projection")
	TEST_ASSERT_EQUAL(view.serialized_nodes, entries + 1, "One activity invalidation must serialize exactly one indexed node")
	TEST_ASSERT(map["state_revision"] > generation, "The live overlay must receive activity changes")
	TEST_ASSERT_EQUAL(map["static_revision"], paint, "Activity must not invalidate the cached stationary canvas")
	entries = view.serialized_nodes
	target.set_machine_stat(BROKEN)
	node.reconcile_state()
	console.ui_data(null)
	TEST_ASSERT_EQUAL(view.rebuilds, builds, "An unavailable leaf must not rebuild the reachable network projection")
	TEST_ASSERT_EQUAL(view.serialized_nodes, entries + 1, "An unavailable leaf must serialize just itself and update its incident edge")
	console.workspace_view = "terminal"
	console.process_tick(1)
	TEST_ASSERT(!view.subscribed, "A hidden map must stop receiving global node-change broadcasts")
	node.touch()
	TEST_ASSERT_EQUAL(length(view.dirty_nodes), 0, "Hidden maps must not collect per-node update queues")
	console.workspace_view = "map"
	console.ui_data(null)
	TEST_ASSERT(view.subscribed && view.rebuilds > builds, "Returning to a suspended map must subscribe and reconcile changes once")

/// A carried endpoint remains directly attached to its APC when crossing other machines.
/datum/unit_test/netrun_topology_nested_host_rebind/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, origin.z)
	var/area/room = scene.room(/area/netrun_route_test)
	scene.take(origin, room)
	var/turf/peer_spot = scene.take(get_step(origin, EAST), room)
	var/turf/apc_spot = scene.take(get_step(origin, NORTH), room)
	scene.machine(/obj/machinery/power/apc, apc_spot)
	var/obj/machinery/computer/netrun_terminal/first = scene.machine(/obj/machinery/computer/netrun_terminal, origin)
	var/obj/machinery/computer/netrun_terminal/second = scene.machine(/obj/machinery/computer/netrun_terminal, peer_spot)
	var/obj/item/carrier = allocate(/obj/item, origin)
	var/obj/item/endpoint = allocate(/obj/item, carrier)
	var/datum/component/netrun_node/node = endpoint.AddComponent(/datum/component/netrun_node, NETRUN_NODE_DECK)
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	var/datum/component/netrun_node/first_node = first.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/second_node = second.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/apc = node.bound_apc
	TEST_ASSERT_EQUAL(node.uplink_node(), apc, "A personal endpoint must connect directly to its bound APC")
	TEST_ASSERT_NULL(graph.edge_between(node.address, first_node.address), "Co-location must not create a machine-intermediary edge")
	carrier.forceMove(peer_spot)
	// The subsystem's fallback calls join_network even when the child receives no MOVED.
	node.join_network()
	SSnetrun.ensure_topology()
	TEST_ASSERT_EQUAL(node.bound_apc, apc, "Movement within one root area must retain the existing APC binding")
	TEST_ASSERT_EQUAL(node.uplink_node(), apc, "Same-area movement must preserve the direct APC attachment")
	TEST_ASSERT_NULL(graph.edge_between(node.address, first_node.address), "The previous co-located machine must have no endpoint edge")
	TEST_ASSERT_NULL(graph.edge_between(node.address, second_node.address), "The new co-located machine must have no endpoint edge")
	TEST_ASSERT_NOTNULL(graph.edge_between(node.address, apc.address), "The physical cable must still terminate at the original APC")

/// A firewall notification revokes acquired rights before an immediate request can use them.
/datum/unit_test/netrun_firewall_signal_revocation/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/component/netrun_node/node = host.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity)
	entity.enter_node(node)
	entity.console.access_session.node_access[node.address] = NETRUN_ACCESS_ROOT
	TEST_ASSERT_EQUAL(entity.console.node_level(node), NETRUN_ACCESS_ROOT, "The fixture must begin with an acquired grant")
	node.raise_firewall()
	TEST_ASSERT(entity.console.node_level(node) < NETRUN_ACCESS_ROOT, "A permission read must drain pending firewall revocations immediately")
	TEST_ASSERT(!entity.console.access_session.node_access[node.address], "The access session must own and remove its revoked grant")

/// Transport work depends on changed entries, not the size of an already delivered map.
/datum/unit_test/netrun_map_wire_delta_size/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/netrun_console/console = allocate(/datum/netrun_console, host)
	var/datum/netrun_map_view/view = console.map_view
	var/list/list/nodes = list()
	for(var/i in 1 to 6000)
		nodes += list(list("address" = "N[i]", "name" = "Camera [i]", "type" = "camera", "x" = i % 80,
			"y" = round(i / 80), "z" = 1, "online" = TRUE, "access" = 1, "entities" = 0, "ice" = 0, "active" = FALSE))
	view.state_revision = 1
	var/list/full = list("nodes" = nodes, "edges" = list(), "gateways" = list(), "sectors" = list(), "apc_zones" = list(),
		"state_revision" = 1, "structure_revision" = 1, "static_revision" = 1, "revision" = 1)
	var/list/session = list("id" = 1)
	var/list/baseline = view.encode_wire(full, session)
	TEST_ASSERT(baseline["full"], "A new UI must receive its complete baseline")
	TEST_ASSERT_EQUAL(length(baseline["nodes"]), 6000, "The first snapshot must contain every permitted physical node")
	var/baseline_bytes = length(json_encode(baseline))
	var/list/quiet = view.encode_wire(full, session)
	TEST_ASSERT(!quiet["full"], "An already synchronized UI must receive a delta")
	TEST_ASSERT_EQUAL(length(quiet["nodes"]), 0, "A quiet poll must not encode any of its 6000 known nodes")
	TEST_ASSERT_EQUAL(length(quiet["edges"]), 0, "A quiet poll must not encode unchanged edges")
	TEST_ASSERT(length(json_encode(quiet)) < 2000, "A quiet map update must remain a small metadata packet")
	TEST_ASSERT(length(json_encode(quiet)) * 100 < baseline_bytes, "A quiet update must be below one percent of the large baseline")
	TEST_ASSERT(!("apc_zones" in quiet), "An unchanged APC shape must not be serialized again")

	var/list/changed = nodes[42].Copy()
	changed["entities"] = 2
	nodes[42] = changed
	full["state_revision"] = ++view.state_revision
	view.record_wire_delta(1, list(changed), list(), list(), list())
	var/list/delta = view.encode_wire(full, session)
	TEST_ASSERT(!delta["full"], "An individual live change must keep its baseline")
	TEST_ASSERT_EQUAL(length(delta["nodes"]), 1, "One changed node must produce one upsert")
	TEST_ASSERT_EQUAL(delta["base_revision"], 1, "The delta must name the exact baseline it extends")
	TEST_ASSERT_EQUAL(delta["state_revision"], 2, "The upsert must advance the client state generation")
	nodes.Cut(42, 43)
	full["state_revision"] = ++view.state_revision
	view.record_wire_delta(2, list(), list(), list("N42"), list())
	delta = view.encode_wire(full, session)
	TEST_ASSERT("N42" in delta["removed_nodes"], "Deletion must remove the client's previously delivered marker")
	TEST_ASSERT_EQUAL(length(delta["nodes"]), 0, "Deletion must not resend all surviving nodes")

	var/list/other_session = list("id" = 2)
	TEST_ASSERT(view.encode_wire(full, other_session)["full"], "A second UI must have an independent complete baseline")
	TEST_ASSERT(!view.encode_wire(full, session)["full"], "A second viewer must not reset the first viewer's cursor")
	view.wire_epoch++
	TEST_ASSERT(view.encode_wire(full, session)["full"], "An authorization epoch change must replace every previously known node set")
	var/list/slow_session = session.Copy()
	for(var/i in 1 to 34)
		var/previous = view.state_revision
		full["state_revision"] = ++view.state_revision
		view.record_wire_delta(previous, list(changed), list(), list(), list())
	TEST_ASSERT(view.encode_wire(full, slow_session)["full"], "A gap beyond bounded history must send a fresh baseline instead of an incomplete delta")

/// A missing or discarded TGUI update must not leave the client stuck with deltas.
/// The snapshot is repeated only for the recovering viewer until its receipt.
/datum/unit_test/netrun_map_resync_ack/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/netrun_console/console = allocate(/datum/netrun_console, host)
	var/datum/netrun_map_view/view = console.map_view
	var/mob/living/user = allocate(/mob/living)
	var/datum/tgui/ui = allocate(/datum/tgui, user, console, "NetrunTerminal")
	var/list/session = view.wire_session(user, console, ui)
	view.state_revision = 10
	var/list/full = list("state_revision" = 10, "structure_revision" = 1, "static_revision" = 1,
		"revision" = 1, "nodes" = list(), "edges" = list(), "gateways" = list(),
		"sectors" = list(), "apc_zones" = list())
	var/list/baseline = view.encode_wire(full, session)
	TEST_ASSERT(baseline["full"], "Initial viewer must receive a full baseline")
	TEST_ASSERT(!view.encode_wire(full, session)["full"], "An acknowledged ordinary cursor can receive deltas")
	view.resync(ui)
	TEST_ASSERT(view.encode_wire(full, session)["full"], "Resync must force a complete baseline")
	var/list/repeated = view.encode_wire(full, session)
	TEST_ASSERT(repeated["full"], "An unacknowledged full packet must be repeated if TGUI drops it")
	TEST_ASSERT(!view.ack_full(ui, "forged", 10), "A forged epoch must not release the recovery cursor")
	TEST_ASSERT(!view.ack_full(ui, repeated["epoch"], 9), "An out-of-date generation cannot release the cursor")
	TEST_ASSERT(view.encode_wire(full, session)["full"], "Rejected receipts must leave the full baseline active")
	TEST_ASSERT(view.ack_full(ui, repeated["epoch"], 10), "The matching UI can confirm the delivered baseline")
	TEST_ASSERT(!view.encode_wire(full, session)["full"], "After confirmation the lightweight delta stream resumes")

/// Live changes cannot make every valid recovery receipt perpetually out of date.
/datum/unit_test/netrun_map_resync_live_ack/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/netrun_console/console = allocate(/datum/netrun_console, host)
	var/datum/netrun_map_view/view = console.map_view
	var/mob/living/user = allocate(/mob/living)
	var/datum/tgui/ui = allocate(/datum/tgui, user, console, "NetrunTerminal")
	var/list/session = view.wire_session(user, console, ui)
	view.state_revision = 10
	var/list/full = list("state_revision" = 10, "structure_revision" = 1, "static_revision" = 1,
		"revision" = 1, "nodes" = list(), "edges" = list(), "gateways" = list(),
		"sectors" = list(), "apc_zones" = list())
	var/list/original = view.encode_wire(full, session)
	view.resync(ui)
	var/list/recovery = view.encode_wire(full, session)
	TEST_ASSERT(recovery["epoch"] != original["epoch"], "A recovery stream must reject receipts from its previous baseline")
	view.state_revision = 11
	full["state_revision"] = 11
	view.record_wire_delta(10, list(), list(), list(), list())
	var/list/newer = view.encode_wire(full, session)
	TEST_ASSERT(newer["full"], "An unacknowledged viewer still receives a complete recovery packet")
	TEST_ASSERT(!view.ack_full(ui, original["epoch"], 10), "A delayed receipt for the pre-recovery stream must not unlock it")
	TEST_ASSERT(!view.ack_full(ui, recovery["epoch"], 9), "A generation never sent in this stream cannot be acknowledged")
	view.resync(ui)
	TEST_ASSERT_EQUAL(view.encode_wire(full, session)["epoch"], recovery["epoch"], "A retry must retain the recovery epoch while receipts are in flight")
	TEST_ASSERT(view.ack_full(ui, recovery["epoch"], 10), "A delivered baseline must remain acknowledgeable after a newer full packet is sent")
	var/list/delta = view.encode_wire(full, session)
	TEST_ASSERT(!delta["full"] && delta["base_revision"] == 10 && delta["state_revision"] == 11, "Recovery must resume with changes after the actually acknowledged baseline")
	TEST_ASSERT("apc_zones" in delta, "Recovery must restore metadata even if only a later full packet contained its newest version")

/// Reopening and NTOS program ownership must never share a cursor by accident.
/datum/unit_test/netrun_map_wire_ui_sessions/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/netrun_console/console = allocate(/datum/netrun_console, host)
	var/mob/living/user = allocate(/mob/living)
	var/datum/tgui/first_ui = allocate(/datum/tgui, user, console, "NetrunTerminal")
	var/list/opening = console.map_view.wire_session(user, console, null)
	var/list/bound = console.map_view.wire_session(user, console, first_ui)
	TEST_ASSERT_EQUAL(opening, bound, "The first registered poll must bind its opening baseline without repeating it")
	var/datum/tgui/reopened = allocate(/datum/tgui, user, console, "NetrunTerminal")
	var/list/replacement = console.map_view.wire_session(user, console, reopened)
	TEST_ASSERT_NOTEQUAL(replacement["id"], bound["id"], "A reopened UI datum must start a new stream epoch")
	var/datum/computer_file/program/netrun/program = allocate(/datum/computer_file/program/netrun)
	var/datum/tgui/ntos_ui = allocate(/datum/tgui, user, program, "NtosNetrun")
	var/list/ntos_session = console.map_view.wire_session(user, program, ntos_ui)
	TEST_ASSERT_NOTEQUAL(ntos_session["id"], replacement["id"], "NTOS must bind its containing program rather than a hidden console UI")
	console.map_view.resync(ntos_ui)
	var/list/recovering = console.map_view.wire_session(user, program, ntos_ui)
	TEST_ASSERT_EQUAL(recovering, ntos_session, "Recovery must keep its viewer's cursor stable while waiting for an acknowledged baseline")
	TEST_ASSERT(recovering["force_full"] && isnull(recovering["revision"]), "Recovery must invalidate only the selected viewer's delta baseline")
	TEST_ASSERT_EQUAL(console.map_view.wire_session(user, console, reopened), replacement, "NTOS resync must preserve another valid viewer")

/// A terminal poll retains shared completion pools while storage changes invalidate disclosure.
/datum/unit_test/netrun_cli_wire_cache/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/netrun_console/console = allocate(/datum/netrun_console, host)
	var/list/session = list("id" = 1)
	var/list/data = list()
	console.append_cli_payload(data, TRUE, session)
	TEST_ASSERT_NOTNULL(data["cli"], "A terminal stream needs an initial completion baseline")
	var/revision = console.cli_cached_revision
	data = list()
	console.append_cli_payload(data, TRUE, session)
	TEST_ASSERT(!("cli" in data), "A quiet terminal poll must omit large completion pools preserved by TGUI")
	TEST_ASSERT_EQUAL(console.cli_cached_revision, revision, "Quiet polls must reuse their completion projection")
	console.map_view.invalidate()
	data = list()
	console.append_cli_payload(data, TRUE, session)
	TEST_ASSERT_NOTNULL(data["cli"], "An authorization invalidation must replace cached completions")
	TEST_ASSERT_NOTNULL(console.ui_static_data(null)["cli"], "Full refresh must always restore completions even with the same UI cursor")
	data = list()
	console.append_network_catalog(data, session)
	TEST_ASSERT_NOTNULL(data["networks"], "A new stream must receive its network catalog")
	data = list()
	console.append_network_catalog(data, session)
	TEST_ASSERT(!("networks" in data), "A quiet poll must not JSON-encode the same full LAN catalog")
	TEST_ASSERT_NOTNULL(console.ui_static_data(null)["networks"], "A refreshed browser must restore its network catalog baseline")


/// Only live map subscribers need network-event update notifications.
/datum/unit_test/netrun_map_event_signal_lifecycle/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/netrun_console/console = allocate(/datum/netrun_console, host)
	var/datum/netrun_map_view/view = console.map_view
	view.subscribe()
	console.ui_dirty = FALSE
	SSnetrun.post_event("trace", null, "test-event")
	TEST_ASSERT(console.ui_dirty, "Subscribed maps receive global network event signals")
	view.suspend()
	console.ui_dirty = FALSE
	SSnetrun.post_event("trace", null, "test-event")
	TEST_ASSERT(!console.ui_dirty, "Suspended maps do not receive network event signals")

/// Switching between APCs in one department must update one retained edge.
/datum/unit_test/netrun_map_apc_rebind_incremental/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, origin.z)
	var/area/first_room = scene.room(/area/engineering/netrun_route_test)
	var/area/second_room = scene.room(/area/engineering/netrun_route_test)
	var/turf/source_spot = scene.take(origin, first_room)
	var/turf/target_spot = scene.take(get_step(origin, EAST), first_room)
	var/turf/destination = scene.take(locate(origin.x + 4, origin.y, origin.z), second_room)
	var/turf/first_apc_spot = scene.take(get_step(origin, NORTH), first_room)
	var/turf/second_apc_spot = scene.take(locate(origin.x + 5, origin.y, origin.z), second_room)
	scene.machine(/obj/machinery/power/apc, first_apc_spot)
	var/obj/machinery/power/apc/second = scene.machine(/obj/machinery/power/apc, second_apc_spot)
	var/obj/machinery/computer/netrun_terminal/source = scene.machine(/obj/machinery/computer/netrun_terminal, source_spot)
	var/obj/machinery/computer/netrun_terminal/target = scene.machine(/obj/machinery/computer/netrun_terminal, target_spot)
	var/datum/netrun_console/console = source.console
	qdel(console.map_view)
	var/datum/netrun_map_view/netrun_performance_test/view = new(console)
	console.map_view = view
	console.workspace_view = "map"
	SSnetrun.ensure_topology()
	var/list/map = console.ui_data(null)["map"]
	var/builds = view.rebuilds
	var/datum/component/netrun_node/node = target.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/second_node = second.GetComponent(/datum/component/netrun_node)
	TEST_ASSERT(netrun_map_has_node(list("map" = map), node.address), "The target must be present before moving")
	target.forceMove(destination)
	node.join_network()
	TEST_ASSERT_EQUAL(node.bound_apc, second_node, "The leaf must change its APC")
	map = console.ui_data(null)["map"]
	TEST_ASSERT_EQUAL(view.rebuilds, builds, "An APC-to-APC move within one LAN must avoid rebuilding the entire viewer map")
	TEST_ASSERT(netrun_map_has_node(list("map" = map), node.address), "The moved leaf must remain visible")
