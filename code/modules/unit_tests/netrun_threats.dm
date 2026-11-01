/// An authorized route must stop before newly arrived hostile ICE, without spending a hop.
/datum/unit_test/netrun_navigation_stops_before_threat/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = netrun_connected_test_area()
	var/obj/machinery/computer/netrun_terminal/source = scene.machine(/obj/machinery/computer/netrun_terminal, origin)
	var/obj/machinery/computer/netrun_terminal/target = scene.machine(/obj/machinery/computer/netrun_terminal, get_step(origin, EAST))
	var/datum/component/netrun_node/source_node = source.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/target_node = target.GetComponent(/datum/component/netrun_node)
	var/mob/camera/netrun_entity/entity = new(origin, source_node)
	scene.owned.Insert(1, entity)
	entity.console.operator = entity
	TEST_ASSERT(entity.console.store_file(new /datum/netrun_file("route.key", NETRUN_FILE_KEY, source_node.network.passcode, 1, source_node.network.id)), "Traversal key must fit")
	TEST_ASSERT(entity.travel_to(target_node), "The route must start through the empty APC")
	var/datum/netrun_entity_navigation/navigation = entity.navigation
	var/datum/component/netrun_node/safe_node = entity.host_node
	TEST_ASSERT(navigation.is_active() && navigation.timer, "The route must wait before its second hop")
	var/datum/netrun_ice/ice = allocate(/datum/netrun_ice, target_node, NETRUN_ICE_HUNTER)
	TEST_ASSERT(ice.is_intruder(entity, target_node), "A traversal key must not authorize safe passage past ICE")
	entity.console.ui_node_levels = list()
	entity.console.ui_node_levels[target_node.address] = NETRUN_ACCESS_USER
	entity.next_hop = world.time
	deltimer(navigation.timer)
	navigation.advance_route(navigation.generation)
	TEST_ASSERT_EQUAL(entity.host_node, safe_node, "Autopilot must stop before entering a newly occupied hostile node")
	TEST_ASSERT(!navigation.is_active() && !navigation.timer, "The safety stop must release the route and timer")
	TEST_ASSERT_EQUAL(entity.next_hop, world.time, "Discovering a threat must not spend movement cooldown")
	var/list/last_line = entity.console.log[length(entity.console.log)]
	TEST_ASSERT(findtext(last_line["text"], ice.name) && findtext(last_line["text"], target_node.address), "The safety stop must identify the threat and destination")
	TEST_ASSERT(entity.hop(target_node), "The player may deliberately enter combat with an ordinary manual hop")

/// Lawful visitors and a hidden trail may use autopilot; ICE absence must restore travel.
/datum/unit_test/netrun_navigation_safe_ice_passage/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = netrun_connected_test_area()
	var/obj/machinery/computer/netrun_terminal/source = scene.machine(/obj/machinery/computer/netrun_terminal, origin)
	var/datum/component/netrun_node/source_node = source.GetComponent(/datum/component/netrun_node)
	SSnetrun.ensure_topology()
	var/datum/component/netrun_node/destination = source_node.bound_apc
	var/mob/camera/netrun_entity/entity = new(origin, source_node)
	scene.owned.Insert(1, entity)
	entity.console.operator = entity
	TEST_ASSERT(entity.console.store_file(new /datum/netrun_file("route.key", NETRUN_FILE_KEY, source_node.network.passcode, 1, source_node.network.id)), "Traversal key must fit")
	var/datum/netrun_ice/ice = allocate(/datum/netrun_ice, destination)
	entity.console.access_session.node_access[destination.address] = NETRUN_ACCESS_USER
	TEST_ASSERT_NULL(entity.navigation.threat_at(destination), "ICE must allow a lawful visitor")
	TEST_ASSERT(entity.travel_to(destination), "USER access must allow automatic passage past a sentry")
	TEST_ASSERT_EQUAL(entity.host_node, destination, "A lawful visitor must arrive normally")
	entity.enter_node(source_node)
	entity.next_hop = world.time
	entity.console.access_session.node_access -= destination.address
	entity.console.access_cache = null
	entity.combat_ignore_until = world.time + 8 SECONDS
	TEST_ASSERT_NULL(entity.navigation.threat_at(destination), "Disengage grace must be useful for travel")
	entity.combat_ignore_until = 0
	TEST_ASSERT_EQUAL(entity.navigation.threat_at(destination), ice, "Expired grace must restore danger")
	qdel(ice)
	TEST_ASSERT(entity.travel_to(destination), "Removing the threat must make the same route usable again")
	TEST_ASSERT_EQUAL(entity.host_node, destination, "A cleared route must arrive normally")

/// Revoked travel permission must not turn the safety warning into a resident scanner.
/datum/unit_test/netrun_navigation_threat_privacy/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = netrun_connected_test_area()
	var/obj/machinery/computer/netrun_terminal/source = scene.machine(/obj/machinery/computer/netrun_terminal, origin)
	var/obj/machinery/computer/netrun_terminal/target = scene.machine(/obj/machinery/computer/netrun_terminal, get_step(origin, EAST))
	var/datum/component/netrun_node/source_node = source.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/target_node = target.GetComponent(/datum/component/netrun_node)
	var/mob/camera/netrun_entity/entity = new(origin, source_node)
	scene.owned.Insert(1, entity)
	entity.console.operator = entity
	var/datum/netrun_file/key = new("route.key", NETRUN_FILE_KEY, source_node.network.passcode, 1, source_node.network.id)
	TEST_ASSERT(entity.console.store_file(key), "Traversal key must fit")
	TEST_ASSERT(entity.travel_to(target_node), "The route must start before credentials are revoked")
	var/datum/component/netrun_node/current = entity.host_node
	entity.console.delete_local_file(key)
	allocate(/datum/netrun_ice, target_node, NETRUN_ICE_HUNTER)
	entity.next_hop = world.time
	deltimer(entity.navigation.timer)
	entity.navigation.advance_route(entity.navigation.generation)
	TEST_ASSERT_EQUAL(entity.host_node, current, "Revoked authorization must stop travel")
	TEST_ASSERT(!entity.navigation.is_active(), "The unauthorized route must be released")
	var/list/last_line = entity.console.log[length(entity.console.log)]
	TEST_ASSERT(!findtext(last_line["text"], "ICE-HUNTER"), "The failure must not reveal ICE behind revoked entry permission")

/// The same authorized contact card explains patrol identity, permissions and provocation.
/datum/unit_test/netrun_ice_contact_threats/Run()
	var/datum/netrun_entity_contact_scene/scene = allocate(/datum/netrun_entity_contact_scene, run_loc_floor_bottom_left)
	var/datum/netrun_ice/ice = allocate(/datum/netrun_ice, scene.target_node, NETRUN_ICE_HUNTER)
	TEST_ASSERT_EQUAL(length(scene.console.entity_contacts(scene.target_node)), 0, "Reconnaissance must not reveal residents of a closed LAN")
	scene.authorize()
	var/list/contacts = scene.console.entity_contacts(scene.target_node)
	var/list/ice_entry = contacts[2]
	TEST_ASSERT_EQUAL(ice_entry["ice_kind"], NETRUN_ICE_HUNTER, "Reconnaissance must distinguish hunters from sentries")
	TEST_ASSERT(findtext(ice_entry["threat"], "Трассирует"), "A remote operator must learn about trace countermeasures")
	var/datum/netrun_console/console = scene.recipient.console
	TEST_ASSERT(findtext(console.ice_contact_threat(ice, scene.target_node), "позволяет пройти"), "USER access must be described as safe passage")
	var/list/targets = console.combat_targets()
	var/list/target_entry = targets[1]
	TEST_ASSERT(!target_entry["hostile"], "A lawful visitor's guard must not be presented as an automatic hostile target")
	console.access_session.node_access.Cut()
	console.access_cache = null
	TEST_ASSERT(findtext(console.ice_contact_threat(ice, scene.target_node), "Опасный вход"), "A process without USER must see the entry warning")
	scene.recipient.combat_ignore_until = world.time + 8 SECONDS
	TEST_ASSERT(findtext(console.ice_contact_threat(ice, scene.target_node), "След скрыт"), "Reconnaissance must explain temporary disengage protection")
	scene.recipient.combat_ignore_until = 0
	console.access_session.node_access[scene.target_node.address] = NETRUN_ACCESS_USER
	ice.register_enemy(console)
	TEST_ASSERT(findtext(console.ice_contact_threat(ice, scene.target_node), "считает вас противником"), "Provocation must explain why USER no longer protects this process")
	targets = console.combat_targets()
	target_entry = targets[1]
	TEST_ASSERT(target_entry["hostile"], "A provoked guard must become a hostile combat target")
