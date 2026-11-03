/// Native gameplay checks over imported fixture data; physical algorithms are tested in netrun-core.
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
	var/datum/netrun_network/remote_network = scene.fixture_graph.declared_network(scene.fixture_graph.declared_anchor(second_node))
	scene.fixture_graph.import_binding(second_node, second_node.bound_apc, remote_network)
	scene.fixture_graph.clear_tables()
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
