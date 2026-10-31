/// Actual MOD controllers, modules, wearer slots and APC routes; no replacement service implementation.
/datum/netrun_mod_scene
	parent_type = /datum/netrun_route_scene
	var/mob/living/carbon/human/user
	var/obj/item/mod/control/pre_equipped/standard/suit
	var/obj/machinery/computer/netrun_terminal/source
	var/datum/component/netrun_node/node
	var/datum/netrun_console/console
	var/datum/netrun_provider/provider
	var/turf/far_spot

/datum/netrun_mod_scene/New(turf/origin)
	..(origin.z)
	var/area/room = room(/area/engineering/netrun_route_test)
	for(var/turf/spot as anything in block(origin, locate(origin.x + 5, origin.y + 2, origin.z)))
		take(spot, room)
	far_spot = locate(origin.x + 5, origin.y, origin.z)
	machine(/obj/machinery/power/apc, get_step(origin, NORTH))
	source = machine(/obj/machinery/computer/netrun_terminal, origin)
	user = new(get_step(origin, EAST))
	owned += user
	suit = new(get_turf(user))
	owned += suit
	user.equip_to_slot_if_possible(suit, ITEM_SLOT_BACK, disable_warning = TRUE)
	node = suit.GetComponent(/datum/component/netrun_node)
	console = source.console
	console.operator = user
	provider = SSnetrun.get_provider(suit)
	SSnetrun.ensure_topology()

/datum/netrun_mod_scene/Destroy()
	owned -= suit
	QDEL_NULL(suit)
	return ..()

/datum/netrun_mod_scene/proc/ready()
	suit.deploy(user, suit.get_helmet())
	suit.finish_activation(TRUE)

/datum/netrun_mod_scene/proc/deliver(action, list/arguments)
	return console.do_remote_request(node, provider, action, arguments || list(), node.network, console.operator)

/datum/unit_test/netrun_mod_endpoint_ownership/Run()
	var/datum/netrun_mod_scene/scene = allocate(/datum/netrun_mod_scene, run_loc_floor_bottom_left)
	TEST_ASSERT_EQUAL(scene.suit.wearer, scene.user, "The real MOD must recognize its equipped wearer")
	TEST_ASSERT_NOTNULL(scene.node, "A MOD controller must create an addressable endpoint")
	TEST_ASSERT_EQUAL(scene.node.node_type, NETRUN_NODE_MODSUIT, "The endpoint must advertise a MOD rather than a generic machine")
	TEST_ASSERT(scene.node.is_online(), "A charged folded MOD must retain its network controller")
	TEST_ASSERT_EQUAL(scene.node.physical_turf(), get_turf(scene.user), "The worn controller must use its actual wearer's position")
	TEST_ASSERT_EQUAL(scene.node.physical_carrier, scene.user, "The endpoint must subscribe to its wearer for reactive movement")
	TEST_ASSERT(scene.console.can_route(scene.node), "A MOD must use its room's real APC route")
	TEST_ASSERT_EQUAL(scene.console.node_level(scene.node), NETRUN_ACCESS_ROOT, "Only the actual wearer must administer its own controller")
	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human)
	scene.console.operator = stranger
	TEST_ASSERT_EQUAL(scene.suit.netrun_owner_access(scene.console), NETRUN_ACCESS_NONE, "A different console operator must not inherit MOD ownership")
	TEST_ASSERT_NULL(scene.provider.payload(scene.suit, scene.console, scene.node), "Closed LANs must conceal MOD diagnostics and module inventory")

/datum/unit_test/netrun_mod_native_light_control/Run()
	var/datum/netrun_mod_scene/scene = allocate(/datum/netrun_mod_scene, run_loc_floor_bottom_left)
	var/obj/item/mod/module/flashlight/light = scene.suit.netrun_flashlight()
	TEST_ASSERT_NOTNULL(light, "The test must use the standard suit's actual installed flashlight")
	var/datum/netrun_command/command = SSnetrun.get_command("mod_lights")
	var/list/entry = command.ui_entry(scene.node, scene.console)
	TEST_ASSERT(!entry["allowed"] && entry["unavailable_reason"], "The command tooltip must explain native deployment requirements before dispatch")
	TEST_ASSERT(!scene.deliver("lights"), "A folded inactive suit must preserve native module deployment requirements")
	TEST_ASSERT(!light.active, "Rejected light control must not mutate module state")
	scene.ready()
	TEST_ASSERT(scene.deliver("lights"), "A powered suit with a deployed helmet must accept its actual flashlight interaction")
	TEST_ASSERT(light.active, "The native module must actually activate")
	TEST_ASSERT(scene.suit.is_active(), "A utility interaction must preserve the suit's active life-support state")
	TEST_ASSERT(scene.deliver("light_range", list("range" = 3)), "The flashlight must expose native range configuration")
	TEST_ASSERT_EQUAL(light.light_range, 3, "Configuration must reach the actual flashlight module")
	TEST_ASSERT(!scene.deliver("light_range", list("range" = 999)), "Out-of-schema range values must be rejected before native configure_edit")
	TEST_ASSERT_EQUAL(light.light_range, 3, "Invalid requests must preserve the previous light range")
	TEST_ASSERT(scene.deliver("module_stop"), "ROOT must be able to stop the explicit utility subset")
	TEST_ASSERT(!light.active && scene.suit.is_active(), "Stopping utility modules must leave suit systems powered")

/datum/unit_test/netrun_mod_module_reference_policy/Run()
	var/datum/netrun_mod_scene/scene = allocate(/datum/netrun_mod_scene, run_loc_floor_bottom_left)
	scene.ready()
	var/obj/item/mod/module/flashlight/uninstalled = allocate(/obj/item/mod/module/flashlight)
	TEST_ASSERT(!scene.deliver("select_module", list("module" = REF(uninstalled))), "A forged REF must not borrow another module's native callbacks")
	var/obj/item/mod/module/jetpack/jetpack = new
	scene.suit.install(jetpack)
	TEST_ASSERT(jetpack in scene.suit.modules, "The test must use a real installed propulsion module")
	TEST_ASSERT(!scene.deliver("select_module", list("module" = REF(jetpack))), "The utility service must not turn arbitrary propulsion or weapon modules into remote actions")
	TEST_ASSERT(!jetpack.active, "Rejected module selection must leave propulsion untouched")
	var/obj/item/mod/module/flashlight/light = scene.suit.netrun_flashlight()
	scene.suit.uninstall(light)
	TEST_ASSERT(!scene.deliver("select_module", list("module" = REF(light))), "A removed module must not remain remotely callable through a stale inventory row")
	qdel(light)

/datum/unit_test/netrun_mod_queued_power_revalidation/Run()
	var/datum/netrun_mod_scene/scene = allocate(/datum/netrun_mod_scene, run_loc_floor_bottom_left)
	scene.ready()
	var/obj/item/mod/module/flashlight/light = scene.suit.netrun_flashlight()
	var/datum/netrun_request/remote/packet = allocate(/datum/netrun_request/remote, scene.console, scene.node, scene.provider, "lights", list(), scene.node.network, scene.user)
	TEST_ASSERT(packet.send(10 SECONDS), "A valid MOD request must enter the real delivery queue")
	var/obj/item/stock_parts/cell/cell = scene.suit.get_cell()
	var/charge = cell.charge
	cell.charge = 0
	TEST_ASSERT(!scene.node.is_online(), "Losing charge must immediately take the network controller offline")
	TEST_ASSERT(!packet.deliver(), "A previously queued request must recheck charge at delivery")
	TEST_ASSERT(!light.active, "A dead controller must not run the queued module callback")
	cell.charge = charge
	TEST_ASSERT(scene.node.is_online(), "Restoring actual battery charge must restore the controller")
	scene.suit.interface_break = TRUE
	TEST_ASSERT(!scene.node.is_online(), "A broken native interface must also block network control")
	scene.suit.interface_break = FALSE
	scene.suit.status_flags |= MOD_MALFUNCTION
	TEST_ASSERT(!scene.node.is_online(), "Native EMP malfunction must disable remote control")
	scene.suit.status_flags &= ~MOD_MALFUNCTION

/datum/unit_test/netrun_mod_owner_only_sealing/Run()
	var/datum/netrun_mod_scene/scene = allocate(/datum/netrun_mod_scene, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human)
	scene.console.operator = stranger
	scene.console.access_session.network_access[scene.node.network.id] = NETRUN_ACCESS_GUEST
	scene.console.access_session.node_access[scene.node.address] = NETRUN_ACCESS_ROOT
	TEST_ASSERT(scene.provider.action_unavailable_reason(scene.suit, "toggle_power", scene.console, scene.node), "A stolen ROOT grant must not impersonate the wearer for suit sealing")
	TEST_ASSERT(!scene.deliver("toggle_power"), "The owner-only sealing policy must be checked at native delivery")
	TEST_ASSERT(!scene.deliver("firewall"), "An outsider must not impersonate the wearer to reset the defensive firewall")
	TEST_ASSERT(!scene.suit.is_active(), "Denied remote sealing must leave suit systems unchanged")
	scene.console.operator = scene.user
	TEST_ASSERT_NULL(scene.provider.action_unavailable_reason(scene.suit, "toggle_power", scene.console, scene.node), "The real wearer must retain its ordinary controller workflow")
	scene.suit.status_flags |= MOD_OPEN
	TEST_ASSERT(scene.provider.action_unavailable_reason(scene.suit, "toggle_power", scene.console, scene.node), "Even the owner must respect an open maintenance panel")
	scene.suit.status_flags &= ~MOD_OPEN

/datum/unit_test/netrun_mod_firewall_and_teardown/Run()
	var/datum/netrun_mod_scene/scene = allocate(/datum/netrun_mod_scene, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human)
	scene.console.operator = stranger
	scene.console.access_session.network_access[scene.node.network.id] = NETRUN_ACCESS_GUEST
	scene.console.access_session.node_access[scene.node.address] = NETRUN_ACCESS_ROOT
	TEST_ASSERT(scene.suit.netrun_raise_firewall(scene.user), "The wearer must have local counterplay even without its own network console")
	TEST_ASSERT(scene.console.node_level(scene.node) < NETRUN_ACCESS_USER, "A native defensive action must immediately revoke an external node grant")
	TEST_ASSERT(!scene.suit.netrun_raise_firewall(scene.user), "Repeated firewall clicks must respect its actual cooldown")
	var/address = scene.node.address
	var/datum/component/netrun_node/node = scene.node
	qdel(scene.suit)
	TEST_ASSERT(QDELETED(node), "Controller deletion must release its endpoint")
	TEST_ASSERT_NULL(SSnetrun.find_node(address), "A deleted MOD must no longer remain addressable")
	TEST_ASSERT_NULL(node.physical_carrier, "Deleting the endpoint must release its wearer movement subscription")

/datum/unit_test/netrun_mod_wearer_movement/Run()
	var/datum/netrun_mod_scene/scene = allocate(/datum/netrun_mod_scene, run_loc_floor_bottom_left)
	var/area/destination = scene.room(/area/medical/netrun_route_test)
	scene.take(scene.far_spot, destination)
	var/turf/apc_spot = scene.take(get_step(scene.far_spot, NORTH), destination)
	var/obj/machinery/power/apc/remote_apc = scene.machine(/obj/machinery/power/apc, apc_spot)
	SSnetrun.ensure_topology()
	var/datum/component/netrun_node/previous_apc = scene.node.bound_apc
	scene.user.forceMove(scene.far_spot)
	TEST_ASSERT_EQUAL(scene.node.physical_turf(), scene.far_spot, "The real worn MOD must follow its wearer")
	TEST_ASSERT_EQUAL(scene.node.bound_apc, previous_apc, "Wearer movement must defer binding work to the existing worker or route consumer")
	TEST_ASSERT(SSnetrun.get_task_scheduler().by_key["node:[REF(scene.node)]"], "The worn MOD must queue one endpoint update")
	TEST_ASSERT(scene.console.can_route(scene.node), "A real route query must still reach the wearer after crossing APC areas")
	TEST_ASSERT_EQUAL(scene.node.bound_apc, remote_apc.GetComponent(/datum/component/netrun_node), "The route query must refresh the worn MOD's new APC before authorization")
	TEST_ASSERT_EQUAL(scene.console.node_level(scene.node), NETRUN_ACCESS_ROOT, "A rebind must preserve the actual wearer's own controller rights")
