/// Real implanted organs and APC routes exercise admission independently of the map widget.
/datum/netrun_client_scene
	parent_type = /datum/netrun_route_scene
	var/mob/living/carbon/human/user
	var/obj/item/organ/cyberimp/brain/netlink/implant
	var/obj/machinery/computer/netrun_terminal/target
	var/obj/machinery/power/apc/apc
	var/datum/component/netrun_node/target_node
	var/turf/far_spot

/datum/netrun_client_scene/New(turf/origin)
	..(origin.z)
	var/area/room = room(/area/engineering/netrun_route_test)
	for(var/turf/spot as anything in block(origin, locate(origin.x + 4, origin.y + 2, origin.z)))
		take(spot, room)
	far_spot = locate(origin.x + 4, origin.y, origin.z)
	apc = machine(/obj/machinery/power/apc, get_step(origin, NORTH))
	target = machine(/obj/machinery/computer/netrun_terminal, get_step(origin, EAST))
	target_node = target.GetComponent(/datum/component/netrun_node)
	user = new(origin)
	owned += user
	user.mind_initialize()
	implant = new(origin)
	owned += implant
	implant.Insert(user)
	SSnetrun.ensure_topology()

/datum/netrun_client_scene/Destroy()
	if(!QDELETED(implant))
		implant.console.disconnect_client(TRUE)
	return ..()

/datum/netrun_client_scene/proc/authorize()
	implant.console.access_session.node_access[target_node.address] = NETRUN_ACCESS_USER
	implant.console.access_session.network_access[target_node.network.id] = NETRUN_ACCESS_GUEST

/datum/unit_test/netrun_implant_entry_selection/Run()
	var/datum/netrun_client_scene/scene = allocate(/datum/netrun_client_scene, run_loc_floor_bottom_left)
	var/datum/netrun_console/implant/console = scene.implant.console
	TEST_ASSERT_EQUAL(console.operator, scene.user, "Installing the implant must bind the owner before the first UI poll")
	TEST_ASSERT(console.available_to(scene.user), "The installed implant must admit its conscious owner")
	TEST_ASSERT(!console.select_entry(scene.target_node, scene.user), "Selecting an entry must not grant rights to a closed LAN")
	scene.authorize()
	var/list/choices = console.entry_choices()
	TEST_ASSERT_EQUAL(choices["[scene.target_node.get_name()] — [scene.target_node.address]"], scene.target_node, "The chooser must include reachable nodes with acquired user access")
	TEST_ASSERT(console.select_entry(scene.target_node, scene.user), "A reachable authorized node must be selectable outside the map workspace")
	TEST_ASSERT_EQUAL(console.selected_node(), scene.target_node, "The chooser must update the node used by the native dive action")
	TEST_ASSERT_EQUAL(console.workspace_view, "map", "Choosing an entry must reveal its card and dive action")
	TEST_ASSERT_NULL(console.dive_denial(scene.target_node), "A conscious mind with a valid route must be allowed to dive")
	var/list/data = console.ui_data(scene.user)
	var/list/selected = data["selected"]
	var/list/actions = selected?["interactions"]
	var/has_dive = FALSE
	for(var/list/entry as anything in actions)
		if(entry["id"] == "dive" && entry["enabled"])
			has_dive = TRUE
	TEST_ASSERT(has_dive, "The selected-node wire payload must expose the enabled dive action")

/datum/unit_test/netrun_implant_direct_connection/Run()
	var/datum/netrun_client_scene/scene = allocate(/datum/netrun_client_scene, run_loc_floor_bottom_left)
	var/datum/netrun_console/implant/console = scene.implant.console
	TEST_ASSERT_NULL(console.connection.connect_denial(scene.target_node, scene.user), "An adjacent service port must be available before LAN authorization")
	var/list/choices = console.local_connection_choices(scene.user)
	TEST_ASSERT_EQUAL(choices["[scene.target_node.get_name()] — [scene.target_node.address]"], scene.target_node, "A closed LAN must still expose the physically reachable service port in the chooser")
	TEST_ASSERT(console.connection.connect_node(scene.target_node, scene.user), "The implanted lead must establish a local physical connection")
	TEST_ASSERT_EQUAL(console.route_source(), scene.target_node, "Physical entry must use the selected machine rather than a fallback APC")
	TEST_ASSERT_EQUAL(console.selected_node(), scene.target_node, "Connecting must select the actual endpoint")
	TEST_ASSERT_EQUAL(console.node_level(scene.target_node), NETRUN_ACCESS_GUEST, "Plugging in must not create user or root machine privileges")
	scene.user.forceMove(scene.far_spot)
	TEST_ASSERT(!console.jack_valid(), "A short lead cannot remain attached after walking away")
	console.process_tick(1)
	TEST_ASSERT_NULL(console.connection.jack, "The physical disconnect must be processed without another UI click")
	TEST_ASSERT(!console.connection.connect_node(scene.target_node, scene.user), "A stale card must not reconnect to a distant port")

/datum/unit_test/netrun_implant_owner_admission/Run()
	var/datum/netrun_client_scene/scene = allocate(/datum/netrun_client_scene, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/outsider = allocate(/mob/living/carbon/human)
	var/datum/netrun_console/implant/console = scene.implant.console
	scene.authorize()
	TEST_ASSERT_EQUAL(console.ui_status(outsider, GLOB.always_state), UI_CLOSE, "Conscious-only UI state must not expose an implant to another mob")
	TEST_ASSERT_EQUAL(length(console.ui_data(outsider)), 0, "A foreign UI read must not serialize the owner's network")
	TEST_ASSERT_EQUAL(length(console.ui_static_data(outsider)), 0, "A static UI read must not change implant identity")
	TEST_ASSERT_EQUAL(console.operator, scene.user, "Rejected UI access must preserve the actual operator")
	TEST_ASSERT(!console.select_entry(scene.target_node, outsider), "A forged entry selector must reject another character")
	TEST_ASSERT(!scene.implant.complete_dive(scene.target_node, outsider), "The final dive admission must reject a changed owner")
	scene.user.SetUnconscious(10 SECONDS)
	TEST_ASSERT(!console.available_to(scene.user), "An unconscious body must not operate its implant")
	TEST_ASSERT(!console.can_route(scene.target_node), "Queued actions must lose the implant route when the owner loses consciousness")
	TEST_ASSERT(console.dive_denial(scene.target_node), "The native dive action must observe the same consciousness restriction")

/datum/unit_test/netrun_implant_dive_lifecycle/Run()
	var/datum/netrun_client_scene/scene = allocate(/datum/netrun_client_scene, run_loc_floor_bottom_left)
	var/datum/netrun_console/implant/console = scene.implant.console
	scene.authorize()
	console.select_entry(scene.target_node, scene.user)
	var/datum/mind/mind = scene.user.mind
	TEST_ASSERT(scene.implant.complete_dive(scene.target_node, scene.user), "The final authorized admission must create a real resident process")
	var/mob/camera/netrun_entity/entity = console.dive_ref?.resolve()
	TEST_ASSERT_NOTNULL(entity, "The implant must track its actual resident rather than only a selected address")
	TEST_ASSERT_EQUAL(mind.current, entity, "The same mind must transfer into the selected network node")
	TEST_ASSERT_EQUAL(entity.host_node, scene.target_node, "The resident must start at the selected endpoint")
	TEST_ASSERT_EQUAL(entity.dive_link.body, scene.user, "The dive must retain its original body link")
	TEST_ASSERT_EQUAL(entity.console.access_session.node_access[scene.target_node.address], NETRUN_ACCESS_USER, "Acquired node rights must survive the dive")
	entity.console.access_session.node_access[scene.target_node.address] = NETRUN_ACCESS_ROOT
	TEST_ASSERT_EQUAL(console.access_session.node_access[scene.target_node.address], NETRUN_ACCESS_USER, "Resident and implant grants must not share mutable lists")
	scene.implant.Remove()
	TEST_ASSERT(QDELETED(entity), "Removing the implant must end its active dive")
	TEST_ASSERT_EQUAL(mind.current, scene.user, "Removing the implant must return the mind to its original body")
	TEST_ASSERT_NULL(console.operator, "An extracted implant must release its former operator")
	TEST_ASSERT_NULL(scene.implant.interface, "Extraction must also detach the implant's neural display source")
	TEST_ASSERT_EQUAL(length(console.access_session.node_access), 0, "An extracted implant must not retain acquired session access")

/datum/unit_test/netrun_implant_dive_revalidation/Run()
	var/datum/netrun_client_scene/scene = allocate(/datum/netrun_client_scene, run_loc_floor_bottom_left)
	var/datum/netrun_console/implant/console = scene.implant.console
	scene.authorize()
	console.diving = TRUE
	TEST_ASSERT(console.dive_denial(scene.target_node), "A second click must not start a simultaneous dive")
	console.diving = FALSE
	console.access_session.revoke_all()
	TEST_ASSERT(!scene.implant.complete_dive(scene.target_node, scene.user), "Revoked permissions during preparation must cancel the dive")
	scene.authorize()
	scene.apc.set_machine_stat(BROKEN)
	TEST_ASSERT(!scene.implant.complete_dive(scene.target_node, scene.user), "A route failure during preparation must cancel the dive")
	TEST_ASSERT_EQUAL(scene.user.mind.current, scene.user, "Failed preparation must leave the original mind in its body")

/datum/unit_test/netrun_implant_wired_dive/Run()
	var/datum/netrun_client_scene/scene = allocate(/datum/netrun_client_scene, run_loc_floor_bottom_left)
	var/datum/netrun_console/implant/console = scene.implant.console
	scene.authorize()
	TEST_ASSERT(console.connection.connect_node(scene.target_node, scene.user), "A wired dive must begin at a reachable physical port")
	TEST_ASSERT(scene.implant.complete_dive(scene.target_node, scene.user), "An authorized physical entry must admit the resident")
	var/mob/camera/netrun_entity/entity = console.dive_ref?.resolve()
	console.process_tick(1)
	TEST_ASSERT_EQUAL(console.connection.jack, scene.target_node, "The dive's normal unconscious body must not immediately unplug its own lead")
	TEST_ASSERT(entity.dive_link.link_intact(), "A plugged-in dive must retain its physical entrance")
	scene.target_node.offline_until = world.time + 10 SECONDS
	TEST_ASSERT(!entity.dive_link.link_intact(), "An offline entrance must sever the body link even while the resident occupies that same endpoint")
	scene.target_node.offline_until = 0
	TEST_ASSERT(entity.dive_link.link_intact(), "A recovered entrance must restore the still-attached return link")
	console.set_jack(null)
	TEST_ASSERT(QDELETED(entity), "Unplugging the original service lead must immediately end the resident's body link")
	TEST_ASSERT_EQUAL(scene.user.mind.current, scene.user, "The first physical disconnect must return the mind automatically")

/datum/unit_test/netrun_implant_self_entry/Run()
	var/datum/netrun_client_scene/scene = allocate(/datum/netrun_client_scene, run_loc_floor_bottom_left)
	var/datum/netrun_console/implant/console = scene.implant.console
	var/datum/component/netrun_node/entry = scene.implant.GetComponent(/datum/component/netrun_node)
	TEST_ASSERT_EQUAL(length(console.access_session.node_access), 0, "This dive must begin with native ownership rather than acquired grants")
	TEST_ASSERT(scene.implant.complete_dive(entry, scene.user), "The wearer's own neural endpoint must provide an initial network entrance")
	var/mob/camera/netrun_entity/entity = console.dive_ref?.resolve()
	TEST_ASSERT_EQUAL(entity.console.node_level(entry), NETRUN_ACCESS_ROOT, "A diver keeps native ownership of the body's own neural endpoint")
	entity.return_to_body()

/// Losing a physical lead returns the original mind once and cancels resident work.
/datum/unit_test/netrun_implant_emergency_unplug/Run()
	var/datum/netrun_client_scene/scene = allocate(/datum/netrun_client_scene, run_loc_floor_bottom_left)
	var/datum/netrun_console/implant/console = scene.implant.console
	scene.authorize()
	TEST_ASSERT(console.connection.connect_node(scene.target_node, scene.user), "The emergency fixture must attach its service lead")
	TEST_ASSERT(scene.implant.complete_dive(scene.target_node, scene.user), "The emergency fixture must admit its diver")
	var/mob/camera/netrun_entity/entity = console.dive_ref?.resolve()
	var/datum/mind/mind = entity.mind
	var/datum/netrun_request/command/packet = new(entity.console, scene.target_node, SSnetrun.get_command("scan"), "scan", scene.target_node.network, entity)
	TEST_ASSERT(packet.send(30 SECONDS), "A resident action must actually be pending before unplugging")
	var/brain_before = scene.user.getOrganLoss(ORGAN_SLOT_BRAIN)
	console.set_jack(null)
	TEST_ASSERT(QDELETED(entity), "Unplugging must immediately delete the neural resident")
	TEST_ASSERT_EQUAL(mind.current, scene.user, "Unplugging must return the same mind to the original body")
	TEST_ASSERT(!(entity in SSnetrun.entities) && !(entity in scene.target_node.entities), "An emergency return must remove all resident registry entries")
	TEST_ASSERT(QDELETED(packet), "An emergency return must cancel the resident's pending packet")
	TEST_ASSERT_EQUAL(scene.user.getOrganLoss(ORGAN_SLOT_BRAIN), brain_before + 20, "The emergency return must inflict one bounded brain injury")
	console.disconnect_client(TRUE)
	TEST_ASSERT_EQUAL(scene.user.getOrganLoss(ORGAN_SLOT_BRAIN), brain_before + 20, "A repeated disconnect must not injure the diver twice")

/// An external session sever must eject both wired and wireless divers before revoking their grants.
/datum/unit_test/proc/netrun_assert_session_sever_during_dive(wired)
	var/datum/netrun_client_scene/scene = allocate(/datum/netrun_client_scene, run_loc_floor_bottom_left)
	var/datum/netrun_console/implant/client = scene.implant.console
	var/datum/netrun_file/original = new("original.txt", NETRUN_FILE_TEXT, "original", 1)
	TEST_ASSERT(client.store_file(original), "The implant must own its existing data")
	scene.authorize()
	if(wired)
		TEST_ASSERT(client.connection.connect_node(scene.target_node, scene.user), "The fixture must attach the physical lead")
	TEST_ASSERT(scene.implant.complete_dive(scene.target_node, scene.user), "The session-sever fixture must enter the network")
	var/mob/camera/netrun_entity/entity = client.dive_ref?.resolve()
	var/datum/mind/mind = entity.mind
	var/datum/netrun_file/downloaded = new("downloaded.txt", NETRUN_FILE_TEXT, "download", 1)
	TEST_ASSERT(entity.console.store_file(downloaded), "The resident must write through to the implant")
	entity.console.access_session.node_access[scene.target_node.address] = NETRUN_ACCESS_ROOT
	entity.console.access_session.network_access[scene.target_node.network.id] = NETRUN_ACCESS_ROOT
	var/datum/netrun_request/command/packet = new(entity.console, scene.target_node, SSnetrun.get_command("scan"), "scan", scene.target_node.network, entity)
	TEST_ASSERT(packet.send(30 SECONDS), "The resident must have a pending packet before disconnection")
	var/datum/component/netrun_node/implant_node = scene.implant.GetComponent(/datum/component/netrun_node)
	var/datum/netrun_command/session_sever/sever = SSnetrun.get_command("session_sever")
	TEST_ASSERT(sever.execute(implant_node, scene.target.console), "The external session-sever command must succeed")
	TEST_ASSERT(QDELETED(entity), "Session sever must immediately remove the active resident")
	TEST_ASSERT_EQUAL(mind.current, scene.user, "Session sever must return the same mind to its body")
	TEST_ASSERT(!(entity in SSnetrun.entities) && !(entity in scene.target_node.entities), "No resident may remain registered in the network")
	TEST_ASSERT(QDELETED(packet), "Session sever must cancel the resident's pending packet")
	TEST_ASSERT_EQUAL(scene.user.getOrganLoss(ORGAN_SLOT_BRAIN), 20, "The forced return must inflict exactly one emergency injury")
	TEST_ASSERT_EQUAL(length(client.access_session.node_access), 0, "Resident node grants must not be restored after session sever")
	TEST_ASSERT_EQUAL(length(client.access_session.network_access), 0, "Resident network grants must not be restored after session sever")
	TEST_ASSERT(client.is_locked(), "The implant must remain locked after session sever")
	TEST_ASSERT_EQUAL(client.inventory.find_file(original.uid), original, "Session sever must preserve the original file")
	TEST_ASSERT_EQUAL(client.inventory.find_file(downloaded.uid), downloaded, "Session sever must preserve the resident's downloaded file")
	client.disconnect_client(TRUE)
	TEST_ASSERT_EQUAL(scene.user.getOrganLoss(ORGAN_SLOT_BRAIN), 20, "A repeated disconnect must not injure the wearer twice")

/datum/unit_test/netrun_implant_session_sever_wireless/Run()
	netrun_assert_session_sever_during_dive(FALSE)

/datum/unit_test/netrun_implant_session_sever_wired/Run()
	netrun_assert_session_sever_during_dive(TRUE)

/datum/unit_test/netrun_implant_emergency_route_loss/Run()
	var/datum/netrun_client_scene/scene = allocate(/datum/netrun_client_scene, run_loc_floor_bottom_left)
	scene.authorize()
	TEST_ASSERT(scene.implant.complete_dive(scene.target_node, scene.user), "The route-loss fixture must admit its diver")
	var/mob/camera/netrun_entity/entity = scene.implant.console.dive_ref?.resolve()
	var/obj/machinery/computer/netrun_terminal/remote = scene.machine(/obj/machinery/computer/netrun_terminal, get_step(scene.target, EAST))
	var/datum/component/netrun_node/remote_node = remote.GetComponent(/datum/component/netrun_node)
	entity.enter_node(remote_node)
	TEST_ASSERT(entity.dive_link.link_intact(), "The fixture must begin with an actual return route")
	scene.apc.set_machine_stat(BROKEN)
	if(!QDELETED(entity))
		entity.check_dive_link(1)
	TEST_ASSERT(QDELETED(entity), "The first failed route check must eject the diver without a grace period")
	TEST_ASSERT_EQUAL(scene.user.mind?.current, scene.user, "Route loss must restore the body instead of stranding a process")
	TEST_ASSERT_EQUAL(scene.user.getOrganLoss(ORGAN_SLOT_BRAIN), 20, "Route loss must cause a single native brain injury")

/// Transit deletion wakes a dedicated return-link check before ordinary resident/UI work.
/datum/unit_test/netrun_implant_emergency_transit_deletion/Run()
	var/datum/netrun_client_scene/scene = allocate(/datum/netrun_client_scene, run_loc_floor_bottom_left)
	scene.authorize()
	TEST_ASSERT(scene.implant.complete_dive(scene.target_node, scene.user), "The transit-deletion fixture must admit its diver")
	var/mob/camera/netrun_entity/entity = scene.implant.console.dive_ref?.resolve()
	var/datum/netrun_dive_link/link = entity.dive_link
	var/datum/mind/mind = entity.mind
	var/key = "dive_link:[REF(link)]"
	qdel(scene.apc)
	TEST_ASSERT(SSnetrun.get_task_scheduler().by_key[key], "Deleting a watched transit APC must queue an immediate coalesced return-link check")
	TEST_ASSERT(SSnetrun.next_fire <= world.time + world.tick_lag, "Return-link loss must wake the worker on its next tick")
	var/deadline = world.time + 1 SECONDS
	while(!QDELETED(entity) && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(QDELETED(entity), "A broken transit route must eject the diver without a manual link poll")
	TEST_ASSERT_EQUAL(mind.current, scene.user, "Transit deletion must return the original mind")
	TEST_ASSERT_EQUAL(scene.user.getOrganLoss(ORGAN_SLOT_BRAIN), 20, "Transit deletion must apply its emergency injury exactly once")
	TEST_ASSERT_NULL(SSnetrun.get_task_scheduler().by_key[key], "Returning must release the pending link check")

/// Several route events own one task, and a voluntary return cancels it safely.
/datum/unit_test/netrun_implant_link_check_coalescing/Run()
	var/datum/netrun_client_scene/scene = allocate(/datum/netrun_client_scene, run_loc_floor_bottom_left)
	scene.authorize()
	TEST_ASSERT(scene.implant.complete_dive(scene.target_node, scene.user), "The link-check fixture must admit its diver")
	var/mob/camera/netrun_entity/entity = scene.implant.console.dive_ref?.resolve()
	var/datum/netrun_dive_link/link = entity.dive_link
	var/key = "dive_link:[REF(link)]"
	var/datum/netrun_task/first
	for(var/i in 1 to 32)
		link.queue_link_check()
		var/datum/netrun_task/pending = SSnetrun.get_task_scheduler().by_key[key]
		if(!first)
			first = pending
		TEST_ASSERT_EQUAL(pending, first, "Repeated return-link events must retain a single pending task")
	entity.return_to_body()
	TEST_ASSERT_NULL(SSnetrun.get_task_scheduler().by_key[key], "A voluntary return must cancel its pending route check")
	TEST_ASSERT_EQUAL(scene.user.getOrganLoss(ORGAN_SLOT_BRAIN), 0, "Cancelled checks must not convert a voluntary exit into an emergency injury")

/datum/unit_test/netrun_implant_emergency_entry_deletion/Run()
	var/datum/netrun_client_scene/scene = allocate(/datum/netrun_client_scene, run_loc_floor_bottom_left)
	scene.authorize()
	TEST_ASSERT(scene.implant.complete_dive(scene.target_node, scene.user), "The deletion fixture must admit its diver")
	var/mob/camera/netrun_entity/entity = scene.implant.console.dive_ref?.resolve()
	var/datum/mind/mind = entity.mind
	qdel(scene.target_node)
	TEST_ASSERT(QDELETED(entity), "Deleting the entry must immediately remove its neural resident")
	TEST_ASSERT_EQUAL(mind.current, scene.user, "Entry deletion must return the mind rather than create a stranded process")
	TEST_ASSERT_EQUAL(scene.user.getOrganLoss(ORGAN_SLOT_BRAIN), 20, "Entry deletion must use the common emergency injury")

/datum/unit_test/netrun_implant_voluntary_exit_safe/Run()
	var/datum/netrun_client_scene/scene = allocate(/datum/netrun_client_scene, run_loc_floor_bottom_left)
	scene.authorize()
	TEST_ASSERT(scene.implant.complete_dive(scene.target_node, scene.user), "The voluntary-exit fixture must admit its diver")
	var/mob/camera/netrun_entity/entity = scene.implant.console.dive_ref?.resolve()
	entity.return_to_body()
	TEST_ASSERT(QDELETED(entity), "Voluntary exit must remove its resident")
	TEST_ASSERT_EQUAL(scene.user.mind?.current, scene.user, "Voluntary exit must return the mind")
	TEST_ASSERT_EQUAL(scene.user.getOrganLoss(ORGAN_SLOT_BRAIN), 0, "Voluntary exit must remain safe")

/datum/unit_test/netrun_implant_emergency_removal/Run()
	var/datum/netrun_client_scene/scene = allocate(/datum/netrun_client_scene, run_loc_floor_bottom_left)
	scene.authorize()
	TEST_ASSERT(scene.implant.complete_dive(scene.target_node, scene.user), "The removal fixture must admit its diver")
	var/mob/camera/netrun_entity/entity = scene.implant.console.dive_ref?.resolve()
	var/datum/mind/mind = entity.mind
	scene.implant.Remove()
	TEST_ASSERT(QDELETED(entity), "Implant removal must delete the resident")
	TEST_ASSERT_EQUAL(mind.current, scene.user, "Implant removal must return the same mind")
	TEST_ASSERT_EQUAL(scene.user.getOrganLoss(ORGAN_SLOT_BRAIN), 20, "Implant removal must use the common emergency injury")

/datum/unit_test/netrun_implant_emergency_carried_body/Run()
	var/datum/netrun_client_scene/scene = allocate(/datum/netrun_client_scene, run_loc_floor_bottom_left)
	scene.authorize()
	TEST_ASSERT(scene.implant.console.connection.connect_node(scene.target_node, scene.user), "The carried-body fixture must connect its lead")
	TEST_ASSERT(scene.implant.complete_dive(scene.target_node, scene.user), "The carried-body fixture must admit its diver")
	var/mob/camera/netrun_entity/entity = scene.implant.console.dive_ref?.resolve()
	var/datum/mind/mind = entity.mind
	scene.user.forceMove(scene.far_spot)
	TEST_ASSERT(QDELETED(entity), "Carrying the unconscious body beyond its lead must eject it in the movement event")
	TEST_ASSERT_EQUAL(mind.current, scene.user, "A carried body must receive its original mind")
	TEST_ASSERT_EQUAL(scene.user.getOrganLoss(ORGAN_SLOT_BRAIN), 20, "A cable broken by body movement must cause exactly one emergency injury")

/datum/unit_test/netrun_implant_emergency_harm_cap/Run()
	var/datum/netrun_client_scene/scene = allocate(/datum/netrun_client_scene, run_loc_floor_bottom_left)
	scene.authorize()
	scene.user.setOrganLoss(ORGAN_SLOT_BRAIN, 145)
	TEST_ASSERT(scene.implant.complete_dive(scene.target_node, scene.user), "An injured but conscious diver must be admitted")
	scene.implant.Remove()
	TEST_ASSERT_EQUAL(scene.user.getOrganLoss(ORGAN_SLOT_BRAIN), 150, "Emergency injury must stop at its native nonfatal brain-damage cap")
	TEST_ASSERT(scene.user.stat != DEAD, "The disconnect injury itself must not kill a badly injured diver")

/datum/unit_test/netrun_implant_wearer_movement/Run()
	var/datum/netrun_client_scene/scene = allocate(/datum/netrun_client_scene, run_loc_floor_bottom_left)
	var/datum/component/netrun_node/node = scene.implant.GetComponent(/datum/component/netrun_node)
	TEST_ASSERT_NULL(scene.implant.loc, "The real installed organ must remain in native nullspace")
	TEST_ASSERT_EQUAL(node.physical_turf(), get_turf(scene.user), "An implanted endpoint must resolve its wearer rather than nullspace")
	TEST_ASSERT_EQUAL(node.bound_apc, scene.apc.GetComponent(/datum/component/netrun_node), "The installed endpoint must join its wearer's physical LAN")
	var/area/destination = scene.room(/area/medical/netrun_route_test)
	scene.take(scene.far_spot, destination)
	var/turf/remote_apc_spot = scene.take(get_step(scene.far_spot, NORTH), destination)
	var/obj/machinery/power/apc/remote_apc = scene.machine(/obj/machinery/power/apc, remote_apc_spot)
	SSnetrun.ensure_topology()
	var/datum/component/netrun_node/previous_apc = node.bound_apc
	scene.user.forceMove(scene.far_spot)
	TEST_ASSERT_EQUAL(node.physical_turf(), scene.far_spot, "The implant must follow its wearer without moving the native organ")
	TEST_ASSERT_EQUAL(node.bound_apc, previous_apc, "The wearer's movement signal must defer expensive binding work")
	TEST_ASSERT(SSnetrun.get_task_scheduler().by_key["node:[REF(node)]"], "Wearer movement must queue its endpoint update")
	var/datum/netrun_console/implant/console = scene.implant.console
	console.workspace_view = "map"
	console.map_view.selected_address = node.address
	var/list/data = console.ui_data(scene.user)
	TEST_ASSERT_EQUAL(node.bound_apc, remote_apc.GetComponent(/datum/component/netrun_node), "The UI route consumer must reconcile the wearer's new APC before publishing access")
	var/list/selected = data["selected"]
	TEST_ASSERT_EQUAL(selected?["x"], scene.far_spot.x, "The selected card must publish actual wearer coordinates")
	TEST_ASSERT_EQUAL(selected?["y"], scene.far_spot.y, "The reactive map must not place internal organs at coordinate zero")
	scene.implant.Remove()
	TEST_ASSERT_NULL(node.physical_carrier, "Extraction must unsubscribe the previous wearer from endpoint movement")

/datum/unit_test/netrun_client_lead_ownership/Run()
	var/datum/netrun_client_scene/scene = allocate(/datum/netrun_client_scene, run_loc_floor_bottom_left)
	var/obj/item/netrun_deck/deck = allocate(/obj/item/netrun_deck)
	deck.forceMove(get_turf(scene.user))
	deck.console.operator = scene.user
	TEST_ASSERT(!deck.console.connection.connect_node(scene.target_node, scene.user), "A floor deck must not lend its lead to a previous UI operator")
	deck.forceMove(scene.user)
	TEST_ASSERT(deck.console.connection.connect_node(scene.target_node, scene.user), "A carried deck must share the same physical connection checks as the implant")
	deck.console.set_jack(null)
	deck.console.intrusion.lockout_until = world.time + 10 SECONDS
	TEST_ASSERT(!deck.console.connection.connect_node(scene.target_node, scene.user), "Lockout must also forbid connection through a stale chooser")

/datum/unit_test/netrun_client_device_shortcuts/Run()
	var/datum/netrun_client_scene/scene = allocate(/datum/netrun_client_scene, run_loc_floor_bottom_left)
	var/obj/item/netrun_deck/deck = allocate(/obj/item/netrun_deck, scene.user)
	var/datum/netrun_console/console = deck.console
	console.operator = scene.user
	var/obj/machinery/door/airlock/door = scene.machine(/obj/machinery/door/airlock, scene.far_spot)
	var/datum/component/netrun_node/door_node = door.GetComponent(/datum/component/netrun_node)
	SSnetrun.ensure_topology()
	TEST_ASSERT(!console.node_interact(door_node, "manage", scene.user), "An arbitrary device shortcut must not reveal a closed machine")
	console.access_session.network_access[door_node.network.id] = NETRUN_ACCESS_GUEST
	console.access_session.node_access[door_node.address] = NETRUN_ACCESS_USER
	TEST_ASSERT(console.node_interact(door_node, "manage", scene.user), "An authorized device shortcut must open its existing network provider UI")
	TEST_ASSERT_EQUAL(console.remote_session.active_window, door_node.address, "The shortcut must select the intended native device")
	TEST_ASSERT_EQUAL(console.workspace_view, "pinned", "Device management must navigate to its control workspace")
	TEST_ASSERT(!console.node_interact(door_node, "invented_action", scene.user), "An unadvertised shortcut must never dispatch an arbitrary action")

/// The body can prepare its entrance and local memory, but cannot issue network
/// actions by forging TGUI events or invoking the direct console entry points.
/datum/unit_test/netrun_implant_requires_dive/Run()
	var/datum/netrun_client_scene/scene = allocate(/datum/netrun_client_scene, run_loc_floor_bottom_left)
	var/datum/netrun_console/implant/console = scene.implant.console
	var/datum/tgui/ui = allocate(/datum/tgui, scene.user, console, "NetrunTerminal")
	ui.status = UI_INTERACTIVE
	scene.authorize()
	TEST_ASSERT(console.select_entry(scene.target_node, scene.user), "A local authorized entry must remain selectable")
	for(var/action in list("command", "cli", "remote_act", "window_open", "window_act", "program_use", "breach", "upload", "download", "delete_remote", "chat_send", "entity_signal", "entity_message", "workspace_view", "select"))
		TEST_ASSERT(!console.handle_ui_action(action, list("address" = scene.target_node.address, "text" = "scan", "page" = "map"), ui), "Pre-dive network action [action] must be refused on the server")
	TEST_ASSERT(!console.node_interact(scene.target_node, "manage", scene.user), "Direct device shortcuts must not bypass the pre-dive restriction")
	TEST_ASSERT(!console.run_command(scene.target_node, "scan"), "Direct packet commands must require a resident")
	TEST_ASSERT(!console.remote_request(scene.target_node.address, "test", list()), "Direct remote requests must require a resident")
	TEST_ASSERT(!console.open_window(scene.target_node.address), "A stale machine window must not open before diving")
	TEST_ASSERT(!console.window_act(scene.target_node.address, "test", list()), "A stale machine window must not execute before diving")
	TEST_ASSERT(!console.cli("scan"), "Direct CLI calls must not send network actions")
	TEST_ASSERT(!console.transfer_from_node("unknown", FALSE, scene.target_node), "A direct download must not bypass the restriction")
	TEST_ASSERT(!console.transfer_to_node("unknown", scene.target_node), "A direct upload must not bypass the restriction")
	TEST_ASSERT(!console.start_breach("node", scene.target_node.address), "A direct breach must not bypass the restriction")
	TEST_ASSERT(console.handle_ui_action("file_new", list("name" = "note.txt", "content" = "local"), ui), "Local memory must remain usable before diving")
	TEST_ASSERT_EQUAL(length(console.inventory.local_store.files), 1, "Creating a local file must not access the network")
	var/list/data = console.ui_data(scene.user)
	TEST_ASSERT_NULL(data["map"], "The body UI must not publish the full network map")
	TEST_ASSERT_NULL(data["window"], "The body UI must not publish remote windows")
	var/list/selected = data["selected"]
	var/list/interactions = selected["interactions"]
	TEST_ASSERT_EQUAL(length(interactions), 1, "The entrance card must expose only the dive action")
	var/list/dive_action = interactions[1]
	TEST_ASSERT_EQUAL(dive_action["id"], "dive", "The authorized entrance must still offer the native dive action")
	TEST_ASSERT(dive_action["enabled"], "The actual authorized dive must remain available")
	TEST_ASSERT(scene.implant.complete_dive(scene.target_node, scene.user), "The pre-dive restriction must not block the actual transfer of the mind")
	var/mob/camera/netrun_entity/entity = console.dive_ref?.resolve()
	TEST_ASSERT_NOTNULL(entity, "A successful dive must create the network process")
	TEST_ASSERT(entity.console.open_window(scene.target_node.address), "The resident may operate a reachable authorized machine after diving")
	entity.return_to_body()
