/// Replacing an autopilot route during cooldown must cancel the old callback and wait.
/datum/unit_test/netrun_navigation_replace_and_cancel/Run()
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
	entity.next_hop = world.time + 5 SECONDS
	TEST_ASSERT(entity.travel_to(target_node), "Starting a route during cooldown should succeed")
	var/datum/netrun_entity_navigation/navigation = entity.navigation
	TEST_ASSERT(navigation.is_active() && navigation.timer, "The route must wait on a cancellable timer")
	TEST_ASSERT_EQUAL(entity.host_node, source_node, "Cooldown must still prevent movement")
	var/old_generation = navigation.generation
	var/old_timer = navigation.timer
	TEST_ASSERT(entity.travel_to(target_node), "Replacing a waiting route should succeed")
	TEST_ASSERT_NOTEQUAL(navigation.timer, old_timer, "The old route timer must be replaced")
	var/current_timer = navigation.timer
	navigation.advance_route(old_generation)
	TEST_ASSERT_EQUAL(navigation.timer, current_timer, "An already-dispatched stale callback must not modify the new route")
	TEST_ASSERT_EQUAL(entity.host_node, source_node, "A stale callback must never move the entity")
	entity.next_hop = world.time
	TEST_ASSERT(entity.hop(source_node.bound_apc), "A manual hop should still work")
	TEST_ASSERT(!navigation.is_active() && !navigation.timer, "Manual movement must cancel autopilot and its timer")

/// Each step revalidates the live link; a deleted or offline next hop cancels the route.
/datum/unit_test/netrun_navigation_revalidates_next_hop/Run()
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
	TEST_ASSERT(entity.travel_to(target_node), "A valid route must start")
	var/datum/netrun_entity_navigation/navigation = entity.navigation
	TEST_ASSERT(navigation.is_active() && navigation.timer, "The second hop must wait for cooldown")
	var/datum/component/netrun_node/current = entity.host_node
	target.set_machine_stat(BROKEN)
	entity.next_hop = world.time
	// Simulate the actual scheduled callback without leaving another timer behind.
	deltimer(navigation.timer)
	navigation.advance_route(navigation.generation)
	TEST_ASSERT_EQUAL(entity.host_node, current, "An offline destination must not be entered")
	TEST_ASSERT(!navigation.is_active() && !navigation.timer, "A failed route must release its timer and queue")
	TEST_ASSERT_NULL(navigation.ui_payload(), "Finished/cancelled navigation must clear the HUD")

/// One contact lock follows the moving process by real hops, preserving manual combat.
/datum/unit_test/netrun_navigation_pursuit/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/hunter = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	var/mob/camera/netrun_entity/target = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	hunter.console.operator = hunter
	TEST_ASSERT(hunter.console.store_file(scene.key_file()), "The hunter has the same traversal key a player needs")
	TEST_ASSERT(hunter.console.start_pursuit(REF(target)), "An actual local combat contact can be locked")
	var/datum/netrun_entity_navigation/navigation = hunter.navigation
	TEST_ASSERT(!navigation.is_active() && !navigation.timer, "A stationary contact needs no polling timer")
	var/list/lock = navigation.pursuit_payload()
	TEST_ASSERT_EQUAL(lock["target_ref"], REF(target), "Combat retains the identity of the selected process")
	var/before = target.integrity
	target.enter_node(scene.node_b)
	TEST_ASSERT(navigation.timer, "A target movement signal schedules one owned follow-up")
	deltimer(navigation.timer)
	navigation.advance_route(navigation.generation)
	TEST_ASSERT_EQUAL(hunter.host_node, scene.apc_node, "The first step crosses the real APC instead of teleporting to the target")
	TEST_ASSERT_EQUAL(target.integrity, before, "Pursuit never fires a combat program automatically")
	target.enter_node(scene.node_a)
	hunter.next_hop = world.time
	deltimer(navigation.timer)
	navigation.advance_route(navigation.generation)
	TEST_ASSERT_EQUAL(hunter.host_node, scene.node_a, "The next step replans to the target's new node")
	TEST_ASSERT_NOTNULL(navigation.pursuit_payload(), "Meeting the target preserves the combat lock")
	TEST_ASSERT(!navigation.timer, "A caught stationary target does not keep scheduling route scans")
	var/datum/netrun_file/weapon = netrun_program_file("strike")
	TEST_ASSERT(hunter.console.store_file(weapon), "The player's ordinary attack program fits")
	TEST_ASSERT(hunter.console.program_use(weapon.uid, REF(target)), "The same selected target can be attacked after following")
	TEST_ASSERT(target.integrity < before, "Combat still uses the actual attack program")
	hunter.console.stop_pursuit()
	TEST_ASSERT_NULL(navigation.pursuit_payload(), "Stopping removes the lock")
	target.enter_node(scene.node_b)
	TEST_ASSERT(!navigation.timer, "A stopped lock releases the target movement subscription")

/// A lock is not a tracker for unseen objects and cannot bypass later access loss.
/datum/unit_test/netrun_navigation_pursuit_access/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/hunter = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	var/mob/camera/netrun_entity/target = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_b)
	TEST_ASSERT(!hunter.console.start_pursuit(REF(target)), "A guessed REF to a non-contact process must not start a tracker")
	target.enter_node(scene.node_a)
	TEST_ASSERT(hunter.console.start_pursuit(REF(target)), "The process becomes lockable when it is an actual contact")
	target.enter_node(scene.node_b)
	var/list/lock = hunter.navigation.pursuit_payload()
	TEST_ASSERT_EQUAL(lock["node"], scene.node_a.address, "An unvalidated movement never discloses the hidden destination")
	deltimer(hunter.navigation.timer)
	hunter.navigation.advance_route(hunter.navigation.generation)
	TEST_ASSERT_EQUAL(hunter.host_node, scene.node_a, "The hunter cannot cross nodes without USER or a traversal key")
	TEST_ASSERT_NULL(hunter.navigation.pursuit_payload(), "No authorized route ends the pursuit instead of revealing the target")
	target.enter_node(scene.node_a)
	TEST_ASSERT(!hunter.navigation.timer, "Failed pursuit releases its timer and target subscription")
	TEST_ASSERT(hunter.console.start_pursuit(REF(target)), "A new visible encounter can be locked again")
	qdel(target)
	TEST_ASSERT_NULL(hunter.navigation.pursuit_payload(), "Deleting the target releases the weak lock immediately")
	TEST_ASSERT(!hunter.navigation.timer, "Target deletion cancels all follow callbacks")

/// A station can have hundreds of endpoints; discover a permitted destination after 200 leaves.
/datum/unit_test/netrun_navigation_large_network/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = netrun_connected_test_area()
	var/obj/machinery/computer/netrun_terminal/source = scene.machine(/obj/machinery/computer/netrun_terminal, origin)
	var/datum/component/netrun_node/source_node = source.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/target_node
	for(var/i in 1 to 205)
		var/obj/item/endpoint = new(origin)
		scene.owned += endpoint
		target_node = endpoint.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
	var/mob/camera/netrun_entity/entity = new(origin, source_node)
	scene.owned.Insert(1, entity)
	entity.console.operator = entity
	TEST_ASSERT(entity.console.store_file(new /datum/netrun_file("route.key", NETRUN_FILE_KEY, source_node.network.passcode, 1, source_node.network.id)), "Traversal key must fit")
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	var/copies = graph.route_snapshot_copies
	var/list/path = entity.enterable_path(target_node)
	TEST_ASSERT_EQUAL(length(path), 2, "The full authorized graph must be searched without the former 200-node cutoff")
	TEST_ASSERT_EQUAL(path[2], target_node.address, "The path must end at the requested endpoint")
	TEST_ASSERT_EQUAL(graph.route_snapshot_copies, copies, "A synchronous complete-path search must not copy the station's physical tree")
	var/datum/netrun_path_tree/retained = graph.route_tables[source_node.address]
	TEST_ASSERT(retained && !QDELETED(retained), "Releasing a navigation borrow must preserve the graph-owned authority tree")

/// A removed entity must not leave its navigation controller/timer alive.
/datum/unit_test/netrun_navigation_teardown/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = netrun_connected_test_area()
	var/obj/machinery/computer/netrun_terminal/source = scene.machine(/obj/machinery/computer/netrun_terminal, origin)
	var/datum/component/netrun_node/source_node = source.GetComponent(/datum/component/netrun_node)
	var/mob/camera/netrun_entity/entity = new(origin, source_node)
	scene.owned.Insert(1, entity)
	entity.console.operator = entity
	TEST_ASSERT(entity.console.store_file(new /datum/netrun_file("route.key", NETRUN_FILE_KEY, source_node.network.passcode, 1, source_node.network.id)), "Traversal key must fit")
	entity.next_hop = world.time + 10 SECONDS
	TEST_ASSERT(entity.travel_to(source_node.bound_apc), "Navigation fixture must start")
	var/datum/netrun_entity_navigation/navigation = entity.navigation
	qdel(entity)
	TEST_ASSERT(QDELETED(navigation), "Entity teardown must delete its navigation controller")
	TEST_ASSERT_NULL(navigation.timer, "Navigation teardown must cancel the pending callback")

/// Extension subscriber replaces a route synchronously while arrival is announced.
/datum/netrun_navigation_redirect
	var/mob/camera/netrun_entity/entity
	var/datum/component/netrun_node/destination

/datum/netrun_navigation_redirect/New(mob/camera/netrun_entity/entity, datum/component/netrun_node/destination)
	src.entity = entity
	src.destination = destination
	RegisterSignal(entity, COMSIG_NETRUN_ENTITY_NODE_CHANGED, PROC_REF(on_arrival))

/datum/netrun_navigation_redirect/proc/on_arrival(datum/source, datum/component/netrun_node/old, datum/component/netrun_node/next)
	SIGNAL_HANDLER
	if(!next)
		return
	UnregisterSignal(entity, COMSIG_NETRUN_ENTITY_NODE_CHANGED)
	entity.navigation.start(destination)

/datum/netrun_navigation_redirect/Destroy()
	if(entity)
		UnregisterSignal(entity, COMSIG_NETRUN_ENTITY_NODE_CHANGED)
	entity = null
	destination = null
	return ..()

/datum/unit_test/netrun_navigation_arrival_reentrancy/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = netrun_connected_test_area()
	var/obj/machinery/computer/netrun_terminal/source = scene.machine(/obj/machinery/computer/netrun_terminal, origin)
	var/obj/machinery/computer/netrun_terminal/target = scene.machine(/obj/machinery/computer/netrun_terminal, get_step(origin, EAST))
	var/obj/machinery/computer/netrun_terminal/replacement = scene.machine(/obj/machinery/computer/netrun_terminal, get_step(origin, NORTH))
	var/datum/component/netrun_node/source_node = source.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/target_node = target.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/replacement_node = replacement.GetComponent(/datum/component/netrun_node)
	var/mob/camera/netrun_entity/entity = new(origin, source_node)
	scene.owned.Insert(1, entity)
	entity.console.operator = entity
	TEST_ASSERT(entity.console.store_file(new /datum/netrun_file("route.key", NETRUN_FILE_KEY, source_node.network.passcode, 1, source_node.network.id)), "Traversal key must fit")
	allocate(/datum/netrun_navigation_redirect, entity, replacement_node)
	TEST_ASSERT(entity.travel_to(target_node), "The first route must start")
	TEST_ASSERT_EQUAL(entity.navigation.destination, replacement_node.address, "An arrival extension may replace the current route")
	TEST_ASSERT_EQUAL(length(entity.navigation.queue), 1, "The old callback must not consume the new route's next hop")
	TEST_ASSERT(entity.navigation.timer, "The replacement route must retain its own cooldown timer")
/datum/unit_test/netrun_implant_entry_local_area/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_client_scene/scene = allocate(/datum/netrun_client_scene, origin)
	var/datum/netrun_console/implant/console = scene.implant.console
	var/area/local_room = get_base_area(scene.user)
	var/area/remote_room = scene.room(/area/engineering/netrun_route_test)
	scene.take(scene.far_spot, remote_room)
	scene.take(get_step(scene.far_spot, NORTH), remote_room)
	scene.machine(/obj/machinery/power/apc, get_step(scene.far_spot, NORTH))
	var/obj/machinery/computer/netrun_terminal/remote = scene.machine(/obj/machinery/computer/netrun_terminal, scene.far_spot)
	var/datum/component/netrun_node/remote_node = remote.GetComponent(/datum/component/netrun_node)
	SSnetrun.ensure_topology()
	scene.authorize()
	console.access_session.node_access[remote_node.address] = NETRUN_ACCESS_USER
	TEST_ASSERT_EQUAL(scene.target_node.network, remote_node.network, "The remote room must share the department LAN, otherwise this does not test the isolation boundary")
	TEST_ASSERT(console.can_route(remote_node), "The remote endpoint must remain reachable through the shared infrastructure")
	TEST_ASSERT(console.is_local_entry(scene.target_node, scene.user), "A node in the same room must be a local entrance")
	TEST_ASSERT(!console.is_local_entry(remote_node, scene.user), "A node in another room of the same LAN must not be a local entrance")
	var/list/choices = console.entry_choices()
	TEST_ASSERT_EQUAL(choices["[scene.target_node.get_name()] — [scene.target_node.address]"], scene.target_node, "An authorized local endpoint must be offered")
	TEST_ASSERT_NULL(choices["[remote_node.get_name()] — [remote_node.address]"], "A reachable remote room must not appear in the entry chooser")
	TEST_ASSERT(!console.select_entry(remote_node, scene.user), "A forged entry choice must reject the remote endpoint")
	TEST_ASSERT(console.dive_denial(remote_node, scene.user), "The direct dive action must reject the remote endpoint")
	TEST_ASSERT(console.select_entry(scene.target_node, scene.user), "The local endpoint must remain selectable")
	scene.user.forceMove(scene.far_spot)
	TEST_ASSERT(!console.is_local_entry(scene.target_node, scene.user), "Moving after selection must invalidate the former local entrance immediately")
	TEST_ASSERT(!scene.implant.complete_dive(scene.target_node, scene.user), "Final admission must revalidate the body's location after preparation")
	TEST_ASSERT_EQUAL(scene.user.mind.current, scene.user, "A denied entry must leave the mind in its body")
	scene.user.forceMove(origin)
	var/obj/item/storage/backpack/container = new(scene.user)
	scene.owned += container
	var/obj/item/nested = new(container)
	var/datum/component/netrun_node/nested_node = nested.AddComponent(/datum/component/netrun_node, NETRUN_NODE_IMPLANT)
	TEST_ASSERT(console.is_local_entry(nested_node, scene.user), "A node inside a worn container must follow the owner's physical position")
	var/area/subroom = scene.room(/area/engineering/netrun_route_test)
	local_room.sub_areas = list(subroom)
	subroom.base_area = local_room
	var/turf/subroom_spot = scene.take(locate(origin.x + 2, origin.y, origin.z), subroom)
	nested.forceMove(subroom_spot)
	TEST_ASSERT(console.is_local_entry(nested_node, scene.user), "Sub-areas of the same base area must remain local")
	nested.forceMove(scene.far_spot)
	TEST_ASSERT(!console.is_local_entry(nested_node, scene.user), "Moving the endpoint to another room must invalidate its stale selection")
	qdel(nested)
	scene.take(subroom_spot, local_room)
	scene.rooms -= subroom
	qdel(subroom)
	TEST_ASSERT_NULL(local_room.sub_areas, "Deleting a sub-area must unlink it from the base area without a runtime")

/// A completed gateway hack opens real traversal without inventing machine USER.
/datum/unit_test/netrun_navigation_gateway_grant/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	entity.console.operator = entity
	TEST_ASSERT(entity.console.store_file(netrun_daemon_file("autobreach")), "The test uses the actual gateway breach pipeline")
	TEST_ASSERT(entity.console.start_breach("network", scene.node_b.network.id, TRUE), "The ordinary automatic gateway hack starts")
	var/datum/netrun_breach/automatic/breach = entity.console.intrusion.breach
	breach.deadline = world.time
	breach.finish()
	TEST_ASSERT(!entity.console.has_key(scene.node_b.network, TRUE), "No ordinary passcode file was silently created")
	TEST_ASSERT_EQUAL(entity.console.node_level(scene.node_b), NETRUN_ACCESS_GUEST, "Gateway authority remains GUEST on the destination")
	TEST_ASSERT(entity.can_enter(scene.apc_node), "The acquired gateway permits the first physical hop")
	var/list/path = entity.enterable_path(scene.node_b)
	TEST_ASSERT_EQUAL(length(path), 2, "The destination still requires A → APC → B")
	var/datum/netrun_ice/guard = allocate(/datum/netrun_ice, scene.apc_node, NETRUN_ICE_SENTRY)
	TEST_ASSERT(guard.is_intruder(entity, scene.apc_node), "Traversal permission does not make the process safe from ICE")
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	var/copies = graph.route_snapshot_copies
	TEST_ASSERT_NOTNULL(entity.navigation.threat_at(scene.apc_node), "Autopilot still detects a hostile patrol on the next step")
	TEST_ASSERT_EQUAL(graph.route_snapshot_copies, copies, "A synchronous next-hop threat check must borrow without copying the full physical tree")
	qdel(guard)
	TEST_ASSERT(entity.hop(scene.apc_node), "An explicit first hop uses the normal movement operation")
	entity.next_hop = world.time
	TEST_ASSERT(entity.hop(scene.node_b), "The next actual edge reaches the destination")
	TEST_ASSERT_EQUAL(entity.console.node_level(scene.node_b), NETRUN_ACCESS_GUEST, "Arrival never grants implicit USER")
	TEST_ASSERT_EQUAL(length(entity.console.user_access(TRUE)), 0, "Gateway traversal never creates native station credentials")

/// A copied acquired key has the same traversal, but removal/rotation stops the next step.
/datum/unit_test/netrun_navigation_acquired_key_revocation/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/issuer = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	issuer.console.access_session.grant_network(scene.node_b.network, NETRUN_ACCESS_GUEST, NETRUN_ACCESS_GUEST)
	var/datum/netrun_file/acquired_key/key = issuer.console.export_acquired_key("traversal.grants")
	TEST_ASSERT_NOTNULL(key, "A proven gateway grant can be exported")
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	var/datum/netrun_file/acquired_key/copy = key.copy()
	TEST_ASSERT(entity.console.store_file(copy), "The recipient owns its actual source file")
	TEST_ASSERT(entity.navigation.move_to(scene.node_b), "A network-only acquired key admits ordinary autopilot")
	TEST_ASSERT_EQUAL(entity.host_node, scene.apc_node, "Admission performs one real edge, never a teleport")
	TEST_ASSERT(entity.navigation.timer, "The next edge waits on the normal cooldown")
	entity.console.delete_local_file(copy)
	entity.next_hop = world.time
	deltimer(entity.navigation.timer)
	entity.navigation.advance_route(entity.navigation.generation)
	TEST_ASSERT_EQUAL(entity.host_node, scene.apc_node, "Deleting the last key prevents the already-planned next step")
	TEST_ASSERT(!entity.navigation.is_active(), "Lost authority cancels the route instead of retrying it")
	copy = key.copy()
	TEST_ASSERT(entity.console.store_file(copy), "An independent still-valid copy may be mounted")
	entity.next_hop = world.time + 5 SECONDS
	TEST_ASSERT(entity.navigation.move_to(scene.node_b), "A neighbouring destination can wait through cooldown")
	var/previous_passcode = scene.node_b.network.passcode
	scene.node_b.network.passcode = "navigation-rotated-passcode"
	entity.next_hop = world.time
	deltimer(entity.navigation.timer)
	entity.navigation.advance_route(entity.navigation.generation)
	TEST_ASSERT_EQUAL(entity.host_node, scene.apc_node, "Rotating the gateway revokes a copied key before its next hop")
	TEST_ASSERT(!entity.navigation.is_active(), "A stale key leaves no scheduled movement behind")
	scene.node_b.network.passcode = previous_passcode
	entity.console.delete_local_file(copy)
	entity.console.access_session.grant_network(scene.node_b.network, NETRUN_ACCESS_GUEST, NETRUN_ACCESS_GUEST)
	entity.next_hop = world.time + 5 SECONDS
	TEST_ASSERT(entity.navigation.move_to(scene.node_b), "A directly reacquired gateway grant also permits traversal")
	entity.console.access_session.revoke_all()
	entity.next_hop = world.time
	deltimer(entity.navigation.timer)
	entity.navigation.advance_route(entity.navigation.generation)
	TEST_ASSERT_EQUAL(entity.host_node, scene.apc_node, "Revoking a direct gateway grant also blocks the planned next edge")

/// Planning and live hops agree on a closed fortress gate.
/datum/unit_test/netrun_navigation_gateway_gate/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	entity.console.access_session.grant_network(scene.node_b.network, NETRUN_ACCESS_GUEST)
	var/datum/netrun_fortress/fortress = new(scene.node_b, "Movement gate", NETRUN_FACTION_STATION)
	scene.node_b.fortress = fortress
	fortress.add_module(NETRUN_FORT_GATE, TRUE)
	TEST_ASSERT(!entity.console.can_traverse_node(scene.node_b), "Gateway GUEST does not pass a closed gate")
	TEST_ASSERT_EQUAL(length(entity.enterable_path(scene.node_b)), 0, "BFS rejects the gate before starting an unusable route")
	var/list/admission = entity.navigation.movement_payload(scene.node_b)
	TEST_ASSERT(!admission["allowed"] && findtext(admission["reason"], "Врата"), "The selected-node explanation names the gate")
	entity.console.access_session.grant_node(scene.node_b, NETRUN_ACCESS_USER)
	TEST_ASSERT(entity.console.can_traverse_node(scene.node_b), "Actual node USER passes the same gate")
	TEST_ASSERT_EQUAL(length(entity.enterable_path(scene.node_b)), 2, "The newly authorized route still follows both real edges")

/// UI admission is selected-only and cheap; the module resolves a full route on click.
/datum/unit_test/netrun_navigation_move_admission/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	entity.console.operator = entity
	entity.console.access_session.grant_node(scene.node_b, NETRUN_ACCESS_USER)
	var/datum/netrun_path_tree/tree = entity.console.connection.read_path_tree(TRUE)
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	var/copies_before = graph.route_snapshot_copies
	var/list/admission = entity.navigation.movement_payload(scene.node_b, tree)
	TEST_ASSERT(admission["allowed"] && admission["action"] == "travel", "A remote USER destination admits travel rather than falsely claiming direct adjacency")
	TEST_ASSERT_EQUAL(graph.route_snapshot_copies, copies_before, "Rendering one selected admission does not build an owned route/BFS snapshot")
	entity.console.release_path_tree(tree)
	TEST_ASSERT(entity.dispatch_module_action("move", list("address" = scene.node_b.address), entity), "The shared navigation module handles the real action")
	TEST_ASSERT_EQUAL(entity.host_node, scene.node_a, "A closed intermediate APC cannot be crossed just because the target has USER")
	TEST_ASSERT(!entity.navigation.is_active(), "Failed complete-path validation leaves no autopilot work")
	entity.console.ui_node_levels = list()
	entity.console.ui_node_levels[scene.apc_node.address] = NETRUN_ACCESS_GUEST
	entity.console.access_session.grant_node(scene.apc_node, NETRUN_ACCESS_USER)
	admission = entity.navigation.movement_payload(scene.apc_node)
	TEST_ASSERT(admission["allowed"] && admission["action"] == "hop", "Fresh adjacent USER overrides a previously cached GUEST result immediately")
	TEST_ASSERT(entity.dispatch_module_action("move", list("address" = scene.node_b.address), entity), "The same module action can now start the complete authorized route")
	TEST_ASSERT_EQUAL(entity.host_node, scene.apc_node, "The dispatch chooses an actual first hop through the APC")
	TEST_ASSERT(entity.navigation.timer, "The second edge retains the ordinary cooldown")
	entity.next_hop = world.time
	deltimer(entity.navigation.timer)
	entity.navigation.advance_route(entity.navigation.generation)
	TEST_ASSERT_EQUAL(entity.host_node, scene.node_b, "The second scheduled hop reaches the selected node")
	admission = entity.navigation.movement_payload(scene.node_b)
	TEST_ASSERT(!admission["allowed"], "The current host is never another movement destination")

/// Bot searches reuse traversal rights without granting police inspection authority.
/datum/unit_test/netrun_navigation_bot_gateway_search/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/bot/bot = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, "collector")
	bot.console.access_session.grant_network(scene.node_b.network, NETRUN_ACCESS_GUEST)
	scene.node_b.salvage += new /datum/netrun_file("reachable.txt", NETRUN_FILE_TEXT, "reachable")
	TEST_ASSERT_EQUAL(bot.brain.find_nearby_node(TYPE_PROC_REF(/datum/netrun_bot_brain, node_has_salvage)), scene.node_b, "A gateway-open bot can find actual salvage behind the APC")
	bot.brain.patrol_candidates = list(scene.node_b.address)
	bot.brain.patrol_cursor = 1
	TEST_ASSERT_EQUAL(bot.brain.patrol_destination(list(scene.node_b.network.id)), scene.node_b, "Ordinary patrol accepts the same traversal destination")
	bot.brain.patrol_candidates = list(scene.node_b.address)
	bot.brain.patrol_cursor = 1
	TEST_ASSERT_NULL(bot.brain.patrol_destination(list(scene.node_b.network.id), TRUE), "Police inspection still requires node USER in addition to traversal")

