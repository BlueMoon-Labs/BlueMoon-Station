/// Advance fixtures through real passes, never by editing AP or bypassing admission.
/// A prepared action must resolve/cancel before any participant may yield.
/proc/netrun_test_yield_to(datum/actor, fresh_turn = FALSE)
	var/datum/netrun_combat_encounter/encounter = netrun_turn_encounter(actor)
	var/datum/netrun_turn_participant/participant = encounter?.member(actor)
	if(!participant || !encounter.active)
		return FALSE
	var/initial_turn = participant.own_turn
	for(var/attempt in 1 to length(encounter.participants) * 2 + 1)
		if(encounter.has_turn(actor) && (!fresh_turn || participant.own_turn > initial_turn))
			return TRUE
		if(encounter.deferred || !encounter.pass(encounter.current()?.actor()))
			return FALSE
		if(QDELETED(encounter))
			return FALSE
		if(QDELETED(participant))
			return FALSE
	return FALSE

/// USER prevents unsolicited combat, but attacking a guard remains a provocation.
/datum/unit_test/netrun_ice_target_authority/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/component/netrun_node/node = host.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL, list(), 2, list(ACCESS_RD))
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity)
	entity.enter_node(node)
	var/datum/netrun_ice/ice = allocate(/datum/netrun_ice, node)
	var/datum/netrun_program/strike = SSnetrun.get_program("strike")
	TEST_ASSERT(ice.is_intruder(entity, node), "An unauthorized resident must be identifiable before combat starts")
	entity.console.access_session.node_access[node.address] = NETRUN_ACCESS_USER
	TEST_ASSERT(!ice.is_intruder(entity, node), "A legal resident must not be labeled as an intruder")
	TEST_ASSERT(!ice.begin_program(strike, entity), "Direct casting must not bypass a resident's USER access")
	ice.apply_damage(1, "test provocation", entity.console)
	TEST_ASSERT(ice.is_intruder(entity, node), "Attacking a guard must provoke it even with USER access")
	TEST_ASSERT(ice.begin_program(strike, entity), "A provoked guard must be able to retaliate against a legal resident")
	ice.cancel_program()
	ice.program_cd.Cut()
	ice.enemy_ref = null
	entity.console.access_session.node_access -= node.address
	TEST_ASSERT(netrun_test_yield_to(ice, TRUE), "The next warning waits for a fresh guard turn after cancellation")
	TEST_ASSERT(ice.begin_program(strike, entity), "An unauthorized resident must receive a normal warning")
	entity.console.access_session.node_access[node.address] = NETRUN_ACCESS_USER
	var/initial_integrity = entity.integrity
	ice.attack_at = world.time
	ice.resolve_program()
	TEST_ASSERT_NULL(ice.pending_program, "An unprovoked resident authorized during windup must lose the hostile lock")
	TEST_ASSERT_EQUAL(entity.integrity, initial_integrity, "A stale unauthorized lock must not hit after USER is obtained")
	entity.console.access_session.node_access -= node.address
	entity.combat_ignore_until = world.time + NETRUN_DISENGAGE_GRACE
	TEST_ASSERT(!ice.is_intruder(entity, node), "Disengagement must hide an unauthorized resident for its grace period")
	ice.program_cd.Cut()
	TEST_ASSERT(netrun_test_yield_to(ice, TRUE), "The grace denial is checked with a fresh affordable guard turn")
	TEST_ASSERT(!ice.begin_program(strike, entity), "A direct cast must not bypass disengagement grace")

/// The final check protects movement, disengagement, disabled hosts, and late stun state.
/datum/unit_test/netrun_ice_cast_revalidation/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/component/netrun_node/node = host.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL, list(), 2, list(ACCESS_RD))
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity)
	entity.enter_node(node)
	var/datum/netrun_ice/ice = allocate(/datum/netrun_ice, node)
	var/datum/netrun_program/strike = SSnetrun.get_program("strike")
	var/initial_integrity = entity.integrity
	TEST_ASSERT(ice.begin_program(strike, entity), "The initial unauthorized target must be attackable")
	entity.combat_ignore_until = world.time + NETRUN_DISENGAGE_GRACE
	ice.attack_at = world.time
	ice.resolve_program()
	TEST_ASSERT_NULL(ice.pending_program, "Grace acquired during preparation must cancel the lock")
	TEST_ASSERT_EQUAL(entity.integrity, initial_integrity, "A stale lock must not bypass grace")
	entity.combat_ignore_until = 0
	ice.program_cd.Cut()
	TEST_ASSERT(netrun_test_yield_to(ice, TRUE), "A cancelled windup retains its AP cost until the guard's next turn")
	TEST_ASSERT(ice.begin_program(strike, entity), "An expired grace period must allow a fresh warning")
	node.offline_until = world.time + 5 SECONDS
	ice.attack_at = world.time
	ice.resolve_program()
	TEST_ASSERT_NULL(ice.pending_program, "A disabled host must not finish a previously queued attack")
	TEST_ASSERT_EQUAL(entity.integrity, initial_integrity, "Offline ICE must not deal delayed damage")
	node.offline_until = 0
	ice.program_cd.Cut()
	TEST_ASSERT(netrun_test_yield_to(ice, TRUE), "Restored power does not refund the cancelled attack's turn budget")
	TEST_ASSERT(ice.begin_program(strike, entity), "Restoring the host must allow a fresh warning")
	ice.combat_stun_until = world.time + 5 SECONDS
	ice.attack_at = world.time
	ice.resolve_program()
	TEST_ASSERT_NULL(ice.pending_program, "A direct resolution call must still respect the ICE's stun state")
	TEST_ASSERT_EQUAL(entity.integrity, initial_integrity, "Stunned ICE must not deal delayed damage")
	ice.combat_stun_until = 0
	ice.program_cd.Cut()
	TEST_ASSERT(netrun_test_yield_to(ice, TRUE), "Recovering from a native stun still waits for a fresh guard turn")
	TEST_ASSERT(ice.begin_program(strike, entity), "Recovering from stun must allow a fresh warning")
	entity.leave_node()
	ice.attack_at = world.time
	ice.resolve_program()
	TEST_ASSERT_NULL(ice.pending_program, "Leaving the node must invalidate the pending target")
	TEST_ASSERT_EQUAL(entity.integrity, initial_integrity, "An attack must not follow a target out of its node")

/// The warning's displayed damage and countdown must describe the actual ICE cast.
/datum/unit_test/netrun_ice_telegraph_payload/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/component/netrun_node/node = host.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL, list(), 2, list(ACCESS_RD))
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity)
	entity.enter_node(node)
	var/datum/netrun_ice/ice = allocate(/datum/netrun_ice, node, NETRUN_ICE_HUNTER)
	var/datum/netrun_program/strike = allocate(/datum/netrun_program/attack/strike)
	strike.windup = 0.5 SECONDS
	TEST_ASSERT(ice.begin_program(strike, entity), "The first attack must enter the shared turn encounter")
	var/list/casting = ice.casting_payload()
	TEST_ASSERT_EQUAL(casting["remaining"], NETRUN_ICE_MIN_TELEGRAPH / (1 SECONDS), "The opening attack must retain a full escape window")
	TEST_ASSERT_EQUAL(casting["power"], round(strike.power * ice.damage_factor), "The warning must show the ICE's damage before the victim's shield")
	var/list/last_log = entity.console.log[length(entity.console.log)]
	TEST_ASSERT(findtext(last_log["text"], "через [NETRUN_ICE_MIN_TELEGRAPH / (1 SECONDS)] с"), "The console warning must describe the opening escape window")
	ice.cancel_program()
	var/datum/netrun_program/blackout = SSnetrun.get_program("blackout")
	TEST_ASSERT(netrun_test_yield_to(ice, TRUE), "Changing programs cannot reuse the AP spent on the cancelled preparation")
	TEST_ASSERT(ice.begin_program(blackout, entity), "A hunter must be able to prepare its stun")
	casting = ice.casting_payload()
	TEST_ASSERT_EQUAL(casting["remaining"], NETRUN_ICE_COMBAT_TELEGRAPH / (1 SECONDS), "A later cast within the active encounter uses the short noninteractive preparation")
	TEST_ASSERT_EQUAL(casting["power"], blackout.power, "Damage scaling must never shorten a displayed stun duration")

/// Outside an encounter a real-time preparation retains the full reaction window.
/datum/unit_test/netrun_ice_realtime_telegraph/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/component/netrun_node/node = host.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
	var/datum/netrun_ice/ice = allocate(/datum/netrun_ice, node)
	var/datum/netrun_program/shield/barrier/program = allocate(/datum/netrun_program/shield/barrier)
	program.windup = 0.1 SECONDS
	TEST_ASSERT(ice.begin_program(program, ice), "An idle guard can prepare its self defense outside turn combat")
	TEST_ASSERT_NULL(ice.get_combat_encounter(), "Self defense alone does not invent a combat encounter")
	TEST_ASSERT_EQUAL(ice.attack_at, world.time + NETRUN_ICE_MIN_TELEGRAPH, "Real-time counterplay retains its full minimum window")

/// A damaged sentry spends a real preparation and cooldown on defense before attacking.
/datum/unit_test/netrun_ice_sentry_barrier_priority/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/component/netrun_node/node = host.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL, list(), 2, list(ACCESS_RD))
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity)
	entity.enter_node(node)
	var/datum/netrun_ice/ice = allocate(/datum/netrun_ice, node)
	ice.integrity = ice.max_integrity * 0.75
	ice.try_attack(entity)
	TEST_ASSERT_EQUAL(ice.pending_program?.id, "barrier", "A damaged sentry must prepare its available barrier before a strike")
	TEST_ASSERT(world.time < ice.attack_at && world.time >= ice.combat_shield_until, "The barrier must remain telegraphed rather than applying immediately")
	ice.attack_at = world.time
	ice.resolve_program()
	TEST_ASSERT(world.time < ice.combat_shield_until, "The prepared barrier must use the real shield dispatcher")
	TEST_ASSERT(ice.program_cd["barrier"] > world.time, "Preparing the shield must retain the program's normal cooldown")
	ice.next_attack = world.time
	ice.try_attack(entity)
	TEST_ASSERT_EQUAL(ice.pending_program?.id, "needle", "An active barrier leaves one AP for the sentry's owned light attack")
	TEST_ASSERT_EQUAL(ice.get_combat_encounter().remaining_ap(ice), 0, "Barrier and the affordable needle consume the same three-point turn")
	ice.cancel_program()
	ice.apply_shield(65, 5 SECONDS)
	var/strong_factor = ice.combat_shield_factor
	var/strong_until = ice.combat_shield_until
	ice.apply_shield(35, 10 SECONDS)
	TEST_ASSERT_EQUAL(ice.combat_shield_factor, strong_factor, "A weaker shield must not replace the stronger active shield")
	TEST_ASSERT_EQUAL(ice.combat_shield_until, strong_until, "A weaker shield must not extend the stronger shield's lifetime")

/// Delivery owns its access snapshot even when another UI request is suspended.
/datum/unit_test/netrun_ice_delivery_access_snapshot/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/component/netrun_node/node = host.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL, list(), 2, list(ACCESS_RD))
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity)
	entity.enter_node(node)
	var/datum/netrun_ice/ice = allocate(/datum/netrun_ice, node)
	var/datum/netrun_program/strike = SSnetrun.get_program("strike")
	TEST_ASSERT(ice.begin_program(strike, entity), "The unauthorized resident must receive a normal warning")
	entity.console.ui_node_levels = list()
	entity.console.ui_node_levels[node.address] = NETRUN_ACCESS_USER
	var/initial_integrity = entity.integrity
	ice.attack_at = world.time
	ice.resolve_program()
	TEST_ASSERT_EQUAL(entity.integrity, initial_integrity - round(strike.power * ice.damage_factor), "An old UI USER snapshot must not hide a currently unauthorized target from delivery")
	entity.console.ui_node_levels[node.address] = NETRUN_ACCESS_GUEST
	ice.program_cd.Cut()
	ice.next_attack = world.time
	TEST_ASSERT(netrun_test_yield_to(ice, TRUE), "A second delivery check starts on the next legal guard turn")
	TEST_ASSERT(ice.begin_program(strike, entity), "The actual unauthorized resident must remain attackable")
	entity.console.access_session.node_access[node.address] = NETRUN_ACCESS_USER
	initial_integrity = entity.integrity
	ice.attack_at = world.time
	ice.resolve_program()
	TEST_ASSERT_EQUAL(entity.integrity, initial_integrity, "An old UI GUEST snapshot must not override newly obtained USER at delivery")
	ice.program_cd.Cut()
	TEST_ASSERT(netrun_test_yield_to(ice, TRUE), "The USER denial is checked with a fresh affordable guard turn")
	TEST_ASSERT(!ice.begin_program(strike, entity), "Beginning a cast must also ignore an old unauthorized UI snapshot")
	entity.console.ui_node_levels = null

/// Cancelling one attempt severs its trace, even when the same target is breached again.
/datum/unit_test/netrun_ice_trace_breach_identity/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/component/netrun_node/node = host.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL, list(), 2, list(ACCESS_RD))
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity)
	entity.enter_node(node)
	var/datum/netrun_console/console = entity.console
	var/datum/netrun_ice/ice = allocate(/datum/netrun_ice, node)
	var/datum/netrun_program/trace = SSnetrun.get_program("trace")
	TEST_ASSERT(console.start_breach("node", node.address), "The resident must be able to begin its actual host breach")
	var/datum/netrun_breach/old_breach = console.intrusion.breach
	TEST_ASSERT(ice.begin_program(trace, console), "The first breach must receive its own incoming trace")
	old_breach.finish()
	TEST_ASSERT(console.start_breach("node", node.address), "Cancelling the first attempt must allow a distinct attempt on the same node")
	TEST_ASSERT_NOTEQUAL(console.intrusion.breach, old_breach, "The replacement must be a new breach object")
	var/before_trace = console.intrusion.trace
	ice.attack_at = world.time
	ice.resolve_program()
	TEST_ASSERT_NULL(ice.pending_program, "The previous attempt's incoming trace must be cancelled")
	TEST_ASSERT_NULL(ice.pending_breach_ref, "Cancelling a cast must release its old breach identity")
	TEST_ASSERT_EQUAL(console.intrusion.trace, before_trace, "The replacement attempt must not inherit the previous attempt's incoming trace")
	TEST_ASSERT(ice.program_cd[trace.id] > world.time, "Invalidating an old attempt must preserve the trace cooldown")
	ice.program_cd.Cut()
	TEST_ASSERT(netrun_test_yield_to(ice, TRUE), "A replacement breach cannot refund the previous trace's AP or own-turn cooldown")
	TEST_ASSERT(ice.begin_program(trace, console), "The replacement breach must still permit its own freshly announced trace")
	ice.attack_at = world.time
	ice.resolve_program()
	TEST_ASSERT_EQUAL(console.intrusion.trace, before_trace + trace.power, "A fresh trace bound to the replacement breach must still work normally")

/// A route can fail before the console's next periodic breach validation.
/datum/unit_test/netrun_ice_trace_route_revalidation/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, origin.z)
	var/area/room = scene.room(/area/engineering/netrun_route_test)
	scene.take(origin, room)
	var/turf/target_spot = scene.take(get_step(origin, EAST), room)
	var/turf/apc_spot = scene.take(get_step(origin, NORTH), room)
	var/obj/machinery/power/apc/apc = scene.machine(/obj/machinery/power/apc, apc_spot)
	var/obj/item/source_host = allocate(/obj/item, origin)
	source_host.AddComponent(/datum/component/netrun_node, NETRUN_NODE_DECK)
	var/obj/item/target_host = allocate(/obj/item, target_spot)
	var/datum/component/netrun_node/node = target_host.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
	var/datum/netrun_console/console = allocate(/datum/netrun_console, source_host, NETRUN_ORIGIN_DECK)
	SSnetrun.ensure_topology()
	TEST_ASSERT(console.start_breach("network", node.network.id), "The real APC route must permit the original LAN breach")
	var/datum/netrun_ice/ice = allocate(/datum/netrun_ice, node)
	TEST_ASSERT(ice.begin_program(SSnetrun.get_program("trace"), console), "Connected ICE must announce its real trace")
	var/datum/netrun_path_tree/stale_tree = console.make_path_tree()
	console.ui_routes = stale_tree
	apc.set_machine_stat(BROKEN)
	TEST_ASSERT_NOTNULL(console.intrusion.breach, "The regression must run before the console's periodic cancellation")
	var/before_trace = console.intrusion.trace
	ice.attack_at = world.time
	ice.resolve_program()
	TEST_ASSERT_NULL(ice.pending_program, "ICE delivery must cancel a trace whose physical route has failed")
	TEST_ASSERT_EQUAL(console.intrusion.trace, before_trace, "A disconnected attacker must not use the previous UI route to add trace")
	console.ui_routes = null
	qdel(stale_tree)
