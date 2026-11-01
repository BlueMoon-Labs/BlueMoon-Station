/// A station AI owns an ordinary session attached to its existing core, never to its eye.
/datum/unit_test/netrun_ai_client_identity/Run()
	netrun_connected_test_area()
	var/turf/origin = run_loc_floor_bottom_left
	var/mob/living/carbon/human/donor = allocate(/mob/living/carbon/human)
	var/mob/living/silicon/ai/ai = allocate(/mob/living/silicon/ai, origin, null, donor)
	var/datum/netrun_console/ai/console = ai.netrun_console
	var/datum/component/netrun_node/node = ai.GetComponent(/datum/component/netrun_node)
	TEST_ASSERT_NOTNULL(console, "The station AI must have a network client")
	TEST_ASSERT_NOTNULL(ai.network_action, "The station AI must have a visible network action")
	TEST_ASSERT_EQUAL(ai.network_action.owner, ai, "The network action must belong to the AI")
	TEST_ASSERT(/mob/living/silicon/ai/proc/open_netrun_network in ai.verbs, "The network client must also be discoverable in AI Commands")
	TEST_ASSERT_EQUAL(console.origin, NETRUN_ORIGIN_AI, "The AI client must retain its own origin")
	TEST_ASSERT_EQUAL(console.host, ai, "The physical client must be the AI")
	TEST_ASSERT_EQUAL(console.operator, ai, "Native requests must execute as the actual AI")
	TEST_ASSERT_EQUAL(node.node_type, NETRUN_NODE_AI, "Creating the client must not replace the existing AI target node")
	TEST_ASSERT_EQUAL(console.physical_route_source(), node, "The client must route from the AI's real core node")
	TEST_ASSERT_EQUAL(console.ui_status(ai, console.ui_state(ai)), UI_INTERACTIVE, "A powered conscious AI must be able to use its own network client")
	TEST_ASSERT("ai_jam" in node.command_ids, "Adding a client must preserve incoming AI interactions")
	TEST_ASSERT("session_status" in node.command_ids, "Other network clients must be able to inspect the AI session")
	TEST_ASSERT("session_sever" in node.command_ids, "The AI session must remain subject to network counterplay")

	ai.eyeobj.setLoc(get_step(origin, EAST))
	TEST_ASSERT_EQUAL(console.physical_route_source(), node, "Moving the AI eye must not impersonate a remote machine or APC")
	ai.initialize_netrun_access()
	TEST_ASSERT_EQUAL(ai.netrun_console, console, "Repeated client initialization must retain the same session")
	TEST_ASSERT_EQUAL(ai.GetComponent(/datum/component/netrun_node), node, "Repeated client initialization must not create another AI endpoint")

	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human, origin)
	TEST_ASSERT_EQUAL(console.ui_status(stranger, console.ui_state(stranger)), UI_CLOSE, "A second user must not operate another AI's client")
	TEST_ASSERT_EQUAL(length(console.ui_data(stranger)), 0, "A foreign UI data request must not disclose the session")
	TEST_ASSERT_EQUAL(length(console.ui_static_data(stranger)), 0, "A foreign static catalog request must not disclose the session")
	console.ui_interact(stranger)
	TEST_ASSERT_EQUAL(console.operator, ai, "Foreign UI entry points must not replace the actual operator")
	TEST_ASSERT_EQUAL(ai.netrun_owner_access(console), NETRUN_ACCESS_ROOT, "The AI must administer its own endpoint")
	var/datum/netrun_console/foreign_console = allocate(/datum/netrun_console, stranger)
	foreign_console.operator = stranger
	TEST_ASSERT_EQUAL(ai.netrun_owner_access(foreign_console), NETRUN_ACCESS_NONE, "Owning one AI client must not grant other users access to that core")

/// Stale route tables and already queued commands must obey native power and wireless state.
/datum/unit_test/netrun_ai_control_limits/Run()
	var/datum/netrun_route_scene/scene = netrun_connected_test_area()
	var/turf/origin = run_loc_floor_bottom_left
	var/obj/machinery/camera/camera = scene.machine(/obj/machinery/camera, get_step(origin, EAST))
	var/datum/component/netrun_node/node = camera.GetComponent(/datum/component/netrun_node)
	var/mob/living/carbon/human/donor = allocate(/mob/living/carbon/human)
	var/mob/living/silicon/ai/ai = allocate(/mob/living/silicon/ai, origin, null, donor)
	var/datum/netrun_console/ai/console = ai.netrun_console
	var/datum/netrun_path_tree/tree = console.make_path_tree()
	allocated += tree
	TEST_ASSERT(console.can_route(node, tree), "The powered AI must begin with a real APC route")
	var/datum/netrun_command/command = SSnetrun.get_command("cam_toggle")
	var/datum/netrun_request/command/packet = allocate(/datum/netrun_request/command, console, node, command, command.id, node.network, ai)
	TEST_ASSERT(packet.send(10 SECONDS), "A valid AI command must be queued before the control port is disabled")
	ai.control_disabled = TRUE
	TEST_ASSERT(!console.can_route(node, tree), "A cached route must not bypass disabled AI wireless control")
	TEST_ASSERT_NULL(console.physical_route_source(), "Disabled remote control must stop supplying an AI route source")
	TEST_ASSERT_EQUAL(console.ui_status(ai, console.ui_state(ai)), UI_CLOSE, "Jamming or a disabled intelliCard port must close the network client")
	TEST_ASSERT(!packet.deliver(), "A command sent before the control port was disabled must fail at delivery")
	TEST_ASSERT(camera.status, "The cancelled AI command must leave the camera recording")
	ai.control_disabled = FALSE
	TEST_ASSERT(console.can_route(node, tree), "Restoring native control must restore access through a still-valid route")

	var/area/room = get_area(ai)
	room.requires_power = TRUE
	room.power_equip = FALSE
	TEST_ASSERT(ai.lacks_power(), "The native core must observe the test power outage")
	TEST_ASSERT(!console.can_route(node, tree), "Power loss must block AI commands immediately, before the next Life tick")
	TEST_ASSERT_EQUAL(console.ui_status(ai, console.ui_state(ai)), UI_CLOSE, "An unpowered core must not retain an interactive network window")
	room.power_equip = TRUE
	ai.aiRestorePowerRoutine = 1
	TEST_ASSERT(!console.can_route(node, tree), "The native power restoration routine must remain incapacitating")
	ai.aiRestorePowerRoutine = 0
	ai.stat = UNCONSCIOUS
	TEST_ASSERT(!console.can_route(node, tree), "An unconscious AI must not operate a retained route")
	ai.stat = DEAD
	TEST_ASSERT(!console.can_route(node, tree), "A dead AI must not operate a retained route")
	ai.stat = CONSCIOUS
	TEST_ASSERT(console.can_route(node, tree), "A recovered AI must regain its normal network route")

/// Station credentials authorize ordinary devices without overriding native service denials.
/datum/unit_test/netrun_ai_native_authorization/Run()
	var/datum/netrun_route_scene/scene = netrun_connected_test_area()
	var/turf/origin = run_loc_floor_bottom_left
	var/obj/machinery/netrun_native_status_test/target = scene.machine(/obj/machinery/netrun_native_status_test, get_step(origin, EAST))
	var/datum/component/netrun_node/node = target.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL, list(), 1, list(ACCESS_RD))
	var/mob/living/carbon/human/donor = allocate(/mob/living/carbon/human)
	var/mob/living/silicon/ai/ai = allocate(/mob/living/silicon/ai, origin, null, donor)
	var/datum/netrun_console/ai/console = ai.netrun_console
	var/datum/netrun_provider/provider = SSnetrun.get_provider(target)
	TEST_ASSERT(ACCESS_AI_UPLOAD in console.user_access(TRUE), "AI commands must use normal silicon station credentials")
	TEST_ASSERT(console.can_route(node), "The native service must be connected to the real AI core")
	TEST_ASSERT(console.do_remote_request(node, provider, "control", list(), node.network, ai), "An authorized AI must be able to use a published native device action")
	TEST_ASSERT_EQUAL(target.executions, 1, "The native device must receive the AI's legitimate request once")
	target.control_enabled = FALSE
	console.access_session.node_access[node.address] = NETRUN_ACCESS_ROOT
	TEST_ASSERT(!console.do_remote_request(node, provider, "control", list(), node.network, ai), "AI credentials and a retained ROOT grant must not override native ui_status")
	TEST_ASSERT_EQUAL(target.executions, 1, "A disabled native service must receive no further actions")
	node.required_access = list("netrun_non_station_private_access")
	TEST_ASSERT(console.compute_legit_node_level(node, TRUE) < NETRUN_ACCESS_USER, "The AI must not receive blanket authorization for credentials its station identity does not possess")

/// The map camera command uses the native eye and camera networks without moving the network source.
/datum/unit_test/netrun_ai_camera_jump/Run()
	var/datum/netrun_route_scene/scene = netrun_connected_test_area()
	var/turf/origin = run_loc_floor_bottom_left
	var/turf/camera_spot = get_step(origin, EAST)
	var/obj/machinery/camera/camera = scene.machine(/obj/machinery/camera, camera_spot)
	var/datum/component/netrun_node/node = camera.GetComponent(/datum/component/netrun_node)
	var/mob/living/carbon/human/donor = allocate(/mob/living/carbon/human)
	var/mob/living/silicon/ai/ai = allocate(/mob/living/silicon/ai, origin, null, donor)
	var/datum/netrun_console/ai/console = ai.netrun_console
	var/datum/component/netrun_node/core_node = console.physical_route_source()
	var/datum/netrun_command/command = SSnetrun.get_command("cam_ai_jump")
	ai.network = list("ss13")
	camera.network = list("ss13")
	TEST_ASSERT("cam_ai_jump" in node.all_command_ids(), "A camera must advertise the AI jump interaction")
	TEST_ASSERT(console.do_command(node, command, command.id, FALSE, node.network, ai), "A legitimate network command must move the native AI eye")
	TEST_ASSERT_EQUAL(get_turf(ai.eyeobj), camera_spot, "The command must use the real camera's viewpoint")
	TEST_ASSERT_EQUAL(console.physical_route_source(), core_node, "Jumping to a camera must leave routing anchored to the core")
	ai.eyeobj.setLoc(origin)
	camera.network = list("netrun_private_camera_network")
	TEST_ASSERT(!console.do_command(node, command, command.id, FALSE, node.network, ai), "A routable camera must still respect the native AI camera network selection")
	TEST_ASSERT_EQUAL(get_turf(ai.eyeobj), origin, "A foreign camera network must not move the AI eye")
	camera.network = list("ss13")
	camera.status = FALSE
	TEST_ASSERT(!console.do_command(node, command, command.id, FALSE, node.network, ai), "A switched-off camera must not be a valid AI viewpoint")
	camera.status = TRUE
	ai.network = "ss13"
	TEST_ASSERT_NULL(ai.netrun_camera_access_error(camera), "The native camera-network verb's scalar selection must work alongside the initial list")

	var/obj/item/aicard/card = allocate(/obj/item/aicard, origin)
	ai.forceMove(card)
	ai.control_disabled = TRUE
	TEST_ASSERT(!console.available_to(ai), "The intelliCard's disabled wireless port must block the AI client")
	ai.control_disabled = FALSE
	TEST_ASSERT(console.available_to(ai), "Enabling the native intelliCard port must restore its permitted network client")
	TEST_ASSERT_NOTNULL(ai.netrun_camera_access_error(camera), "A carded AI must not falsely report a camera jump when its native eye cannot move")
	ai.forceMove(origin)

/// Generic optical feeds must share the AI camera policy, including warm text summaries.
/datum/unit_test/netrun_ai_optical_policy/Run()
	var/datum/netrun_route_scene/scene = netrun_connected_test_area()
	var/turf/origin = run_loc_floor_bottom_left
	var/obj/machinery/camera/camera = scene.machine(/obj/machinery/camera, get_step(origin, EAST))
	var/datum/component/netrun_node/node = camera.GetComponent(/datum/component/netrun_node)
	var/mob/living/carbon/human/donor = allocate(/mob/living/carbon/human)
	var/mob/living/silicon/ai/ai = allocate(/mob/living/silicon/ai, origin, null, donor)
	var/mob/living/carbon/human/witness = allocate(/mob/living/carbon/human, get_turf(camera))
	witness.name = "AI optical policy witness"
	ai.network = list("ss13")
	camera.network = list("ss13")
	var/datum/netrun_console/ai/console = ai.netrun_console
	console.access_session.node_access[node.address] = NETRUN_ACCESS_ROOT
	console.remote_session.watch_viewer = ai
	console.remote_session.watch_node = node
	TEST_ASSERT_EQUAL(console.watch_target(), camera, "An AI's permitted camera must supply the ordinary live optical stream")
	var/list/feed = camera.netrun_window_feed(console, node)
	TEST_ASSERT(findtext(jointext(feed, "\n"), witness.name), "A permitted camera must initially cache a real visible entity")
	TEST_ASSERT_EQUAL(console.remote_session.feed_node, node, "The text-feed cache must be warm before the camera policy changes")
	var/scans = SSnetrun.camera_feed_scans

	camera.network = list("netrun_private_camera_network")
	TEST_ASSERT_NOTNULL(console.view_denial(node), "ROOT must not override a camera outside the AI's chosen native network")
	TEST_ASSERT_NULL(console.watch_target(), "The generic live stream must deny a foreign camera network even with ROOT")
	TEST_ASSERT_NULL(camera.netrun_window_feed(console, node), "A warm text summary must not reveal entities from a newly forbidden camera")
	TEST_ASSERT_NULL(console.remote_session.feed_node, "The denied text feed must invalidate its cached source")
	TEST_ASSERT_EQUAL(SSnetrun.camera_feed_scans, scans, "A denied camera must not scan living entities before reporting the denial")
	var/datum/netrun_console/ordinary_console = allocate(/datum/netrun_console, camera)
	ordinary_console.operator = ai
	ordinary_console.connection.wireless = FALSE
	ordinary_console.access_session.node_access[node.address] = NETRUN_ACCESS_ROOT
	ordinary_console.remote_session.watch_viewer = ai
	ordinary_console.remote_session.watch_node = node
	TEST_ASSERT_NOTNULL(ordinary_console.view_denial(node), "The AI's native camera policy must follow it into an ordinary terminal")
	TEST_ASSERT_NULL(ordinary_console.watch_target(), "An ordinary terminal must not let an AI watch a forbidden camera with ROOT")
	TEST_ASSERT_NULL(camera.netrun_window_feed(ordinary_console, node), "An ordinary terminal must not disclose a forbidden camera's text feed to an AI")
	var/datum/netrun_command/photo = SSnetrun.get_command("cam_photo")
	var/list/photo_entry = photo.ui_entry(node, ordinary_console, photo.id)
	TEST_ASSERT(!photo_entry["allowed"], "An ordinary AI-operated terminal must disable forbidden camera snapshots")
	var/files_before = length(ordinary_console.inventory.local_store.files)
	var/photo_cooldown = camera.netrun_next_photo
	TEST_ASSERT(!ordinary_console.do_command(node, photo, photo.id, FALSE, node.network, ai), "A forged photo command must recheck the AI's camera network at execution")
	TEST_ASSERT_EQUAL(length(ordinary_console.inventory.local_store.files), files_before, "A forbidden photo must not create a file containing the camera's image")
	TEST_ASSERT_EQUAL(camera.netrun_next_photo, photo_cooldown, "A denied photo must not start the camera's expensive capture operation")
	ordinary_console.operator = witness
	TEST_ASSERT_NULL(ordinary_console.view_denial(node), "AI camera-network rules must not remove an authorized human's ordinary network-camera abilities")
	console.remote_session.active_window = node.address
	var/list/window = console.window_payload()
	TEST_ASSERT_NULL(window["feed"], "Pinned camera windows must not disclose the forbidden text feed")
	for(var/list/entry as anything in window["extra"])
		if(entry["id"] == "view_watch")
			TEST_ASSERT(!entry["allowed"], "A pinned window must disable the same forbidden camera interaction")
	console.process_tick(1)
	TEST_ASSERT_NULL(console.remote_session.watch_node, "The next session tick must detach an already watched camera whose native network changed")

	camera.network = list("ss13")
	TEST_ASSERT_NULL(console.view_denial(node), "Restoring native camera membership must restore optical authorization")
	feed = camera.netrun_window_feed(console, node)
	TEST_ASSERT(findtext(jointext(feed, "\n"), witness.name), "Restoring authorization must obtain a fresh text summary")
	TEST_ASSERT_EQUAL(SSnetrun.camera_feed_scans, scans + 1, "A restored camera must rescan after its old cache was invalidated")

/// Tearing down a client cancels packets and removes only client-owned session state.
/datum/unit_test/netrun_ai_client_lifecycle/Run()
	netrun_connected_test_area()
	var/turf/origin = run_loc_floor_bottom_left
	var/mob/living/carbon/human/donor = allocate(/mob/living/carbon/human)
	var/mob/living/silicon/ai/ai = allocate(/mob/living/silicon/ai, origin, null, donor)
	var/datum/netrun_console/ai/console = ai.netrun_console
	var/datum/action/innate/ai_netrun/action = ai.network_action
	var/datum/component/netrun_node/node = ai.GetComponent(/datum/component/netrun_node)
	var/datum/netrun_command/command = SSnetrun.get_command("scan")
	var/datum/netrun_request/command/packet = allocate(/datum/netrun_request/command, console, node, command, command.id, node.network, ai)
	TEST_ASSERT(packet.send(10 SECONDS), "The client must own a pending packet before teardown")
	ai.destroy_netrun_access()
	TEST_ASSERT(QDELETED(console), "Client teardown must delete the AI console")
	TEST_ASSERT(QDELETED(action), "Client teardown must delete the visible action")
	TEST_ASSERT(QDELETED(packet), "Client teardown must cancel its pending packets")
	TEST_ASSERT(!(console in SSnetrun.consoles), "The subsystem must release the AI session")
	TEST_ASSERT(!(/mob/living/silicon/ai/proc/open_netrun_network in ai.verbs), "Client teardown must unregister the network verb")
	TEST_ASSERT_EQUAL(ai.GetComponent(/datum/component/netrun_node), node, "Removing the client must preserve the actual AI target node")
	TEST_ASSERT("ai_jam" in node.command_ids, "Client teardown must preserve unrelated incoming AI commands")
	TEST_ASSERT(!("session_status" in node.command_ids), "Client teardown must remove its session adapter commands")
	ai.initialize_netrun_access()
	console = ai.netrun_console
	action = ai.network_action
	qdel(ai)
	TEST_ASSERT(QDELETED(console), "Deleting the native AI must tear down its client")
	TEST_ASSERT(QDELETED(action), "Deleting the native AI must tear down its network action")
	TEST_ASSERT(!(console in SSnetrun.consoles), "Deleting the native AI must release all session registrations")
