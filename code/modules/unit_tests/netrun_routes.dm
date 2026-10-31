/// Real areas and machinery exercise structural nearest-APC binding and security profiles.
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
	var/list/original_generators = list()
	var/original_disabled

/datum/netrun_route_scene/New(z)
	original_disabled = SSnetworks.station_network.setting_disabled
	mark_station(z)

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
	QDEL_LIST(owned)
	for(var/turf/spot as anything in original_areas)
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
		level.traits = original_traits[key]
		GLOB.gravity_generators[key] = original_generators[key]
		SSmapping.calculate_z_level_gravity(z)
	original_traits.Cut()
	original_generators.Cut()
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

/// Nearby machines behind one real APC communicate without visiting either LAN gateway or NTnet.
/datum/unit_test/netrun_route_same_apc/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, origin.z)
	var/area/room = scene.room(/area/engineering/netrun_route_test)
	scene.take(origin, room)
	var/turf/target_spot = scene.take(get_step(origin, EAST), room)
	var/turf/apc_spot = scene.take(get_step(origin, NORTH), room)
	var/obj/machinery/power/apc/apc = scene.machine(/obj/machinery/power/apc, apc_spot)
	var/obj/machinery/computer/netrun_terminal/source = scene.machine(/obj/machinery/computer/netrun_terminal, origin)
	var/obj/machinery/computer/netrun_terminal/target = scene.machine(/obj/machinery/computer/netrun_terminal, target_spot)
	SSnetrun.ensure_topology()
	var/datum/component/netrun_node/source_node = source.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/target_node = target.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/apc_node = apc.GetComponent(/datum/component/netrun_node)
	TEST_ASSERT_EQUAL(source_node.uplink_node(), apc_node, "The source must use its actual room APC")
	TEST_ASSERT_EQUAL(target_node.uplink_node(), apc_node, "The target must share that actual APC")
	SSnetworks.station_network.setting_disabled = TRUE
	TEST_ASSERT(source.console.can_route(target_node), "A shared physical LAN must work without NTnet relays")
	var/datum/netrun_route/route = source.console.route_to(target_node)
	allocated += route
	var/list/expected = list(
		list("kind" = "node", "ref" = source_node.address),
		list("kind" = "node", "ref" = apc_node.address),
		list("kind" = "node", "ref" = target_node.address),
	)
	TEST_ASSERT_EQUAL(json_encode(route.hops), json_encode(expected), "The common APC must trim both gateway branches and the relay hub")
	TEST_ASSERT_EQUAL(source.console.latency_to(target_node), route.latency, "Command latency must use the same topology as the visible route")
	var/datum/netrun_command/ping/command = SSnetrun.get_command("ping")
	command.execute(target_node, source.console)
	TEST_ASSERT_EQUAL(json_encode(source.console.map_view.ping_route), json_encode(expected), "Ping highlighting must use the same APC route")

/// Same-department APCs share one clustered LAN while their sector still routes without NTnet.
/datum/unit_test/netrun_route_different_apcs/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, origin.z)
	var/area/first_room = scene.room(/area/engineering/netrun_route_test)
	var/area/second_room = scene.room(/area/engineering/netrun_route_test)
	scene.take(origin, first_room)
	var/turf/first_apc_spot = scene.take(get_step(origin, NORTH), first_room)
	var/turf/target_spot = scene.take(locate(origin.x + 4, origin.y, origin.z), second_room)
	var/turf/second_apc_spot = scene.take(get_step(target_spot, NORTH), second_room)
	var/obj/machinery/power/apc/first_apc = scene.machine(/obj/machinery/power/apc, first_apc_spot)
	var/obj/machinery/power/apc/second_apc = scene.machine(/obj/machinery/power/apc, second_apc_spot)
	var/obj/machinery/computer/netrun_terminal/source = scene.machine(/obj/machinery/computer/netrun_terminal, origin)
	var/obj/machinery/computer/netrun_terminal/target = scene.machine(/obj/machinery/computer/netrun_terminal, target_spot)
	SSnetrun.ensure_topology()
	var/datum/component/netrun_node/source_node = source.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/target_node = target.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/first_apc_node = first_apc.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/second_apc_node = second_apc.GetComponent(/datum/component/netrun_node)
	TEST_ASSERT_EQUAL(source_node.network, target_node.network, "APCs of the same department in one sector must share a single clustered LAN")
	TEST_ASSERT_EQUAL(source_node.uplink_node(), first_apc_node, "The source must bind its nearest APC")
	TEST_ASSERT_EQUAL(target_node.uplink_node(), second_apc_node, "The target must bind its nearest APC")
	SSnetworks.station_network.setting_disabled = TRUE
	var/datum/netrun_route/route = source.console.route_to(target_node)
	allocated += route
	var/list/expected = list(
		list("kind" = "node", "ref" = source_node.address),
		list("kind" = "node", "ref" = first_apc_node.address),
		list("kind" = "node", "ref" = second_apc_node.address),
		list("kind" = "node", "ref" = target_node.address),
	)
	TEST_ASSERT_EQUAL(json_encode(route.hops), json_encode(expected), "Same-sector traffic must follow the actual APC edge without synthetic gateways or a relay")
	TEST_ASSERT(source.console.can_route(target_node), "Neighboring APC security domains must remain physically reachable with NTnet disabled")
	first_apc.set_machine_stat(BROKEN)
	TEST_ASSERT(!source.console.can_route(target_node), "A failed intermediate APC must cut its endpoint off from the other APC")
	TEST_ASSERT_EQUAL(source_node.uplink_node(), first_apc_node, "An offline APC must not cause an endpoint to escape to another APC")

/// Crossing sectors requires the actual relays at both ends, including their APC attachments.
/datum/unit_test/netrun_route_different_lans/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, origin.z)
	var/area/engineering = scene.room(/area/engineering/netrun_route_test)
	var/area/medical = scene.room(/area/medical/netrun_route_test)
	var/list/levels = multiz_gravity_test_levels()
	scene.mark_station(levels[1])
	scene.take(origin, engineering)
	var/turf/first_apc_spot = scene.take(get_step(origin, NORTH), engineering)
	var/turf/relay_spot = scene.take(get_step(first_apc_spot, NORTH), engineering)
	var/turf/target_spot = scene.take(locate(80, 80, levels[1]), medical, TRUE)
	var/turf/second_apc_spot = scene.take(locate(81, 80, levels[1]), medical, TRUE)
	var/turf/second_relay_spot = scene.take(locate(82, 80, levels[1]), medical, TRUE)
	var/obj/machinery/power/apc/first_apc = scene.machine(/obj/machinery/power/apc, first_apc_spot)
	var/obj/machinery/power/apc/second_apc = scene.machine(/obj/machinery/power/apc, second_apc_spot)
	var/obj/machinery/computer/netrun_terminal/source = scene.machine(/obj/machinery/computer/netrun_terminal, origin)
	var/obj/machinery/computer/netrun_terminal/target = scene.machine(/obj/machinery/computer/netrun_terminal, target_spot)
	var/obj/machinery/ntnet_relay/relay = scene.machine(/obj/machinery/ntnet_relay, relay_spot)
	var/obj/machinery/ntnet_relay/second_relay = scene.machine(/obj/machinery/ntnet_relay, second_relay_spot)
	SSnetrun.ensure_topology()
	var/datum/component/netrun_node/source_node = source.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/target_node = target.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/first_apc_node = first_apc.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/second_apc_node = second_apc.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/relay_node = relay.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/second_relay_node = second_relay.GetComponent(/datum/component/netrun_node)
	TEST_ASSERT_NOTEQUAL(source_node.network, target_node.network, "Engineering and medical must be distinct live LANs")
	SSnetworks.station_network.setting_disabled = FALSE
	TEST_ASSERT(relay.is_operational() && source.console.has_uplink(), "The actual relay fixture must provide NTnet on this Z")
	var/datum/netrun_route/route = source.console.route_to(target_node)
	allocated += route
	var/list/expected = list(
		list("kind" = "node", "ref" = source_node.address),
		list("kind" = "node", "ref" = first_apc_node.address),
		list("kind" = "node", "ref" = relay_node.address),
		list("kind" = "node", "ref" = second_relay_node.address),
		list("kind" = "node", "ref" = second_apc_node.address),
		list("kind" = "node", "ref" = target_node.address),
	)
	TEST_ASSERT_EQUAL(json_encode(route.hops), json_encode(expected), "A cross-sector route must contain both real relay nodes and no abstract hub")
	TEST_ASSERT(route.latency > 0, "Remote communication must include relay latency")
	var/datum/netrun_topology/topology = SSnetrun.ensure_topology()
	var/previous_revision = topology.revision
	second_relay.enabled = FALSE
	TEST_ASSERT(!source.console.can_route(target_node), "A working relay only at the source must not reach a disconnected target sector")
	TEST_ASSERT_EQUAL(topology.revision, previous_revision, "A dynamic relay failure must invalidate live routing without rebuilding structural edges")
	second_relay.enabled = TRUE
	relay.enabled = FALSE
	TEST_ASSERT(!source.console.can_route(target_node), "A working relay only at the destination must not reach a disconnected source sector")
	relay.enabled = TRUE
	SSnetworks.station_network.setting_disabled = TRUE
	TEST_ASSERT(!source.console.can_route(target_node), "Disabling NTnet must remove the remote LAN route")
	var/datum/netrun_route/unreachable = source.console.route_to(target_node)
	allocated += unreachable
	TEST_ASSERT_EQUAL(length(unreachable.hops), 0, "An unavailable remote route must not draw a fictitious hub path")

/// The indexed relay check must preserve native reachability and backbone semantics.
/datum/unit_test/netrun_uplink_relay_index/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, origin.z)
	var/area/local_room = scene.room(/area/engineering/netrun_route_test)
	var/area/remote_room = scene.room(/area/medical/netrun_route_test)
	var/list/levels = multiz_gravity_test_levels()
	scene.mark_station(levels[1])
	scene.take(origin, local_room)
	scene.machine(/obj/machinery/power/apc, scene.take(get_step(origin, NORTH), local_room))
	var/obj/machinery/computer/netrun_terminal/source = scene.machine(/obj/machinery/computer/netrun_terminal, origin)
	var/turf/remote_apc = scene.take(locate(81, 80, levels[1]), remote_room, TRUE)
	var/turf/remote_spot = scene.take(locate(82, 80, levels[1]), remote_room, TRUE)
	scene.machine(/obj/machinery/power/apc, remote_apc)
	var/obj/machinery/ntnet_relay/remote_relay = scene.machine(/obj/machinery/ntnet_relay, remote_spot)
	SSnetworks.station_network.setting_disabled = FALSE
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	var/datum/component/netrun_node/remote_node = remote_relay.GetComponent(/datum/component/netrun_node)
	TEST_ASSERT(remote_relay.is_operational(), "The remote relay must be online")
	TEST_ASSERT(!source.console.can_route(remote_node), "A relay in the disconnected sector must be unreachable")
	TEST_ASSERT(!source.console.has_uplink(), "An online but unreachable relay must not provide an uplink")
	var/turf/local_spot = scene.take(locate(origin.x + 1, origin.y, origin.z), local_room)
	var/obj/machinery/ntnet_relay/local_relay = scene.machine(/obj/machinery/ntnet_relay, local_spot)
	graph = SSnetrun.ensure_topology()
	var/datum/component/netrun_node/source_node = source.GetComponent(/datum/component/netrun_node)
	TEST_ASSERT(source.console.has_uplink(), "A reachable operational local relay must provide an uplink")
	var/datum/netrun_path_tree/cached = graph.route_tables[source_node.address]
	TEST_ASSERT_NOTNULL(cached, "The native route table must be cached")
	TEST_ASSERT(source.console.has_uplink(), "A repeated lookup must preserve the operational result")
	TEST_ASSERT_EQUAL(graph.route_tables[source_node.address], cached, "Repeated checks must reuse the cached route table")
	local_relay.enabled = FALSE
	TEST_ASSERT(!source.console.has_uplink(), "Disabling the only local relay must disconnect the uplink")
	local_relay.enabled = TRUE
	SSnetworks.station_network.setting_disabled = TRUE
	TEST_ASSERT(!source.console.has_uplink(), "Disabling the backbone must override a reachable relay")
	SSnetworks.station_network.setting_disabled = FALSE
	TEST_ASSERT(source.console.has_uplink(), "The uplink must recover when the backbone is restored")

/// A service cable selects its actual endpoint as a zero-latency source, even across LANs.
/datum/unit_test/netrun_route_direct_and_loopback/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, origin.z)
	var/area/engineering = scene.room(/area/engineering/netrun_route_test)
	var/area/medical = scene.room(/area/medical/netrun_route_test)
	scene.take(origin, engineering)
	var/turf/target_spot = scene.take(get_step(origin, EAST), medical)
	var/obj/machinery/computer/netrun_terminal/source = scene.machine(/obj/machinery/computer/netrun_terminal, origin)
	var/obj/machinery/computer/netrun_terminal/target = scene.machine(/obj/machinery/computer/netrun_terminal, target_spot)
	SSnetrun.ensure_topology()
	var/datum/component/netrun_node/source_node = source.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/target_node = target.GetComponent(/datum/component/netrun_node)
	SSnetworks.station_network.setting_disabled = TRUE
	source.console.connection.wireless = TRUE
	TEST_ASSERT(!source.console.can_route(target_node), "Two orphan endpoints must not gain a fictitious path from sharing a fallback LAN")
	TEST_ASSERT(source.console.can_route(source_node), "A wireless client's own real endpoint must remain reachable without relays")
	TEST_ASSERT_EQUAL(source.console.latency_to(source_node), 0, "The actual source endpoint must have zero loopback latency")
	TEST_ASSERT_EQUAL(length(source.console.home_networks()), 0, "Loopback must not grant wireless access to the rest of the physical LAN")
	source.console.set_jack(target_node)
	TEST_ASSERT(source.console.jack_valid(), "The adjacent target must be a legitimate cable endpoint")
	var/datum/netrun_route/route = source.console.route_to(target_node)
	allocated += route
	TEST_ASSERT_EQUAL(route.latency, 0, "A direct cable must add no LAN or relay latency")
	TEST_ASSERT_EQUAL(length(route.hops), 1, "A direct endpoint must not include the source machine, gateways, APCs or a hub")
	var/list/endpoint = route.hops[1]
	TEST_ASSERT_EQUAL(endpoint["ref"], target_node.address, "The direct route must identify the cable target")

/// Linked floors form one sector and keep local graph connectivity with NTnet disabled.
/datum/unit_test/netrun_route_multiz_same_apc/Run()
	var/list/levels = multiz_gravity_test_levels()
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, levels[1])
	scene.mark_station(levels[2])
	var/area/room = scene.room(/area/engineering/netrun_route_test)
	var/turf/source_spot = scene.take(locate(80, 80, levels[1]), room, TRUE)
	var/turf/apc_spot = scene.take(locate(81, 80, levels[1]), room, TRUE)
	var/turf/target_spot = scene.take(locate(80, 80, levels[2]), room, TRUE)
	var/obj/machinery/power/apc/apc = scene.machine(/obj/machinery/power/apc, apc_spot)
	var/obj/machinery/computer/netrun_terminal/source = scene.machine(/obj/machinery/computer/netrun_terminal, source_spot)
	var/obj/machinery/computer/netrun_terminal/target = scene.machine(/obj/machinery/computer/netrun_terminal, target_spot)
	SSnetrun.ensure_topology()
	var/datum/component/netrun_node/source_node = source.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/target_node = target.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/apc_node = apc.GetComponent(/datum/component/netrun_node)
	TEST_ASSERT_EQUAL(source_node.network, target_node.network, "A bound APC security domain must retain its identity across linked station floors")
	TEST_ASSERT_EQUAL(target_node.uplink_node(), apc_node, "The upper room must use the same real APC")
	SSnetworks.station_network.setting_disabled = TRUE
	var/datum/netrun_route/route = source.console.route_to(target_node)
	allocated += route
	var/list/expected = list(
		list("kind" = "node", "ref" = source_node.address),
		list("kind" = "node", "ref" = apc_node.address),
		list("kind" = "node", "ref" = target_node.address),
	)
	TEST_ASSERT_EQUAL(json_encode(route.hops), json_encode(expected), "Z separation must not introduce gateway or relay detours into a shared APC route")
	TEST_ASSERT(route.latency > 0, "A local inter-floor connection must retain its nonzero physical latency")
	TEST_ASSERT(source.console.can_route(target_node), "Linked floors must remain connected through the same actual APC without NTnet")
