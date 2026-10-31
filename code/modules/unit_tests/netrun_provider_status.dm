/// A native endpoint can reject a request in ui_status before ui_act is reached.
/obj/machinery/netrun_native_status_test
	req_access = list(ACCESS_RD)
	var/control_enabled = TRUE
	var/executions = 0
	var/atom/control_host

/obj/machinery/netrun_native_status_test/ui_host(mob/user)
	return control_host ? control_host : src

/obj/machinery/netrun_native_status_test/ui_status(mob/user)
	if(!control_enabled || !allowed(user))
		return UI_CLOSE
	return ..()

/obj/machinery/netrun_native_status_test/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return
	if(action == "control")
		executions++
		return TRUE

/datum/netrun_api/unit_test_status
	atom_type = /obj/machinery/netrun_native_status_test
	interface_name = "NativeStatusTest"
	actions = list("control" = list("name" = "Control", "access" = NETRUN_ACCESS_USER))

/// Isolate the atom-level proximity policy from client/window management.
/datum/ui_state/netrun_native_status_local/can_use_topic(src_object, mob/user)
	return UI_INTERACTIVE

/datum/unit_test/netrun_provider_native_status_policy/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, origin.z)
	var/area/room = scene.room(/area/netrun_route_test)
	scene.take(origin, room)
	var/turf/target_spot = scene.take(locate(origin.x + 4, origin.y, origin.z), room)
	var/turf/apc_spot = scene.take(get_step(origin, NORTH), room)
	scene.machine(/obj/machinery/power/apc, apc_spot)
	var/obj/machinery/computer/netrun_terminal/source = scene.machine(/obj/machinery/computer/netrun_terminal, origin)
	var/obj/machinery/netrun_native_status_test/target = scene.machine(/obj/machinery/netrun_native_status_test, target_spot)
	var/datum/component/netrun_node/node = target.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL, list(), 1, list(ACCESS_RD))
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, origin)
	var/obj/item/clothing/under/color/grey/uniform = allocate(/obj/item/clothing/under/color/grey)
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	card.access = list(ACCESS_RD)
	TEST_ASSERT(user.equip_to_slot_if_possible(uniform, ITEM_SLOT_ICLOTHING, disable_warning = TRUE), "The operator must wear the real uniform needed by its ID slot")
	TEST_ASSERT(user.equip_to_slot_if_possible(card, ITEM_SLOT_ID, disable_warning = TRUE), "Native machine policy must receive the operator's actual ID")
	var/datum/netrun_console/console = source.console
	console.operator = user
	console.connection.wireless = FALSE
	var/datum/netrun_provider/provider = SSnetrun.get_provider(target)
	var/datum/ui_state/local_state = allocate(/datum/ui_state/netrun_native_status_local)
	TEST_ASSERT(local_state.requires_physical_interaction, "Ordinary UI states must retain physical interaction checks")
	TEST_ASSERT(target.ui_status(user, local_state) < UI_INTERACTIVE, "A permissive local state must not remove the atom's physical proximity check")
	user.forceMove(target_spot)
	TEST_ASSERT_EQUAL(target.ui_status(user, local_state), UI_INTERACTIVE, "The same native panel must be usable beside the machine with the matching ID")
	user.forceMove(origin)
	TEST_ASSERT(console.can_route(node), "The far machine must have a genuine APC route")
	TEST_ASSERT(console.do_remote_request(node, provider, "control", list(), node.network, user), "Network reachability and native ID policy must permit a legitimate far request")
	TEST_ASSERT_EQUAL(target.executions, 1, "A native endpoint must execute the authorized remote action once")
	target.control_enabled = FALSE
	console.access_session.node_access[node.address] = NETRUN_ACCESS_ROOT
	TEST_ASSERT(!console.do_remote_request(node, provider, "control", list(), node.network, user), "ROOT must not bypass a native ui_status denial")
	TEST_ASSERT_EQUAL(target.executions, 1, "An explicitly disabled native service must never reach ui_act")
	target.control_enabled = TRUE
	card.access.Cut()
	TEST_ASSERT(!console.do_remote_request(node, provider, "control", list(), node.network, user), "A retained ROOT grant must not impersonate an ID required by native ui_status")
	TEST_ASSERT_EQUAL(target.executions, 1, "Revoking the actual ID must prevent the native side effect")

/// Native covers are valid only for the exact endpoint and host captured by this request.
/datum/unit_test/netrun_provider_native_host_binding/Run()
	var/obj/item/source = allocate(/obj/item)
	var/obj/machinery/netrun_native_status_test/target = allocate(/obj/machinery/netrun_native_status_test)
	target.set_machine_stat(0)
	var/datum/component/netrun_node/node = target.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL, list(), 1, list(ACCESS_RD))
	var/datum/netrun_console/console = allocate(/datum/netrun_console, source)
	console.operator = allocate(/mob)
	console.connection.wireless = FALSE
	console.set_jack(node)
	console.access_session.node_access[node.address] = NETRUN_ACCESS_ROOT
	var/datum/netrun_provider/provider = SSnetrun.get_provider(target)
	var/obj/item/cover = allocate(/obj/item)
	target.control_host = cover
	var/datum/ui_state/netrun_request/state = allocate(/datum/ui_state/netrun_request, console, node, provider, "control")
	TEST_ASSERT_EQUAL(state.can_use_topic(target, console.operator), UI_INTERACTIVE, "Direct endpoint checks must preserve their original target identity")
	TEST_ASSERT_EQUAL(state.can_use_topic(cover, console.operator), UI_INTERACTIVE, "The native resolved ui_host of that endpoint must also be accepted")
	var/obj/item/unrelated = allocate(/obj/item)
	TEST_ASSERT_EQUAL(state.can_use_topic(unrelated, console.operator), UI_CLOSE, "An arbitrary datum must not borrow another endpoint's network request state")
	target.control_host = unrelated
	TEST_ASSERT_EQUAL(state.can_use_topic(cover, console.operator), UI_CLOSE, "An obsolete native host must stop authorizing callbacks")
	TEST_ASSERT_EQUAL(state.can_use_topic(unrelated, console.operator), UI_CLOSE, "A new host must require a new request rather than inherit an old callback")

/// Exercise a real native restriction and the real turret/cover host chain.
/datum/unit_test/netrun_provider_lasertag_native_policy/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, origin.z)
	var/area/room = scene.room(/area/netrun_route_test)
	scene.take(origin, room)
	var/turf/target_spot = scene.take(locate(origin.x + 4, origin.y, origin.z), room)
	scene.machine(/obj/machinery/power/apc, scene.take(get_step(origin, NORTH), room))
	var/obj/machinery/computer/netrun_terminal/source = scene.machine(/obj/machinery/computer/netrun_terminal, origin)
	var/obj/machinery/porta_turret/lasertag/blue/turret = scene.machine(/obj/machinery/porta_turret/lasertag/blue, target_spot)
	var/datum/component/netrun_node/node = turret.GetComponent(/datum/component/netrun_node)
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, origin)
	var/obj/item/clothing/suit/redtag/opposing_suit = allocate(/obj/item/clothing/suit/redtag)
	TEST_ASSERT(user.equip_to_slot_if_possible(opposing_suit, ITEM_SLOT_OCLOTHING, disable_warning = TRUE), "The opposing team must wear its actual lasertag suit")
	var/datum/netrun_console/console = source.console
	console.operator = user
	console.connection.wireless = FALSE
	console.access_session.node_access[node.address] = NETRUN_ACCESS_ROOT
	var/datum/netrun_provider/provider = SSnetrun.get_provider(turret)
	var/previous_flags = turret.turret_flags
	TEST_ASSERT(!console.do_remote_request(node, provider, "authweapon", list(), node.network, user), "A ROOT request must honor the opposing-team denial in the real turret's ui_status")
	TEST_ASSERT_EQUAL(turret.turret_flags, previous_flags, "A denied native status must prevent the actual turret side effect")
	TEST_ASSERT(user.dropItemToGround(opposing_suit), "Removing the actual opposing uniform must change the native policy")
	TEST_ASSERT_NOTNULL(turret.cover, "The real turret must have its normal native cover")
	var/datum/ui_state/netrun_request/state = allocate(/datum/ui_state/netrun_request, console, node, provider, "authweapon")
	TEST_ASSERT_EQUAL(state.can_use_topic(turret.cover, user), UI_INTERACTIVE, "A covered turret's native host must resolve back to the authorized network endpoint")
	TEST_ASSERT_EQUAL(turret.ui_status(user, state), UI_INTERACTIVE, "An otherwise authorized turret must remain remotely usable through its native cover")
	TEST_ASSERT(console.do_remote_request(node, provider, "authweapon", list(), node.network, user), "Removing the native denial must restore the remote turret control")
	TEST_ASSERT_NOTEQUAL(turret.turret_flags, previous_flags, "An authorized native action must change the real turret state")
