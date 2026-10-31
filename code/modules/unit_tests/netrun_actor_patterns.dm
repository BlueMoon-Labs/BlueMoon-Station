/// Portable probes exercise the very same host with all three actor representations.
/datum/netrun_agent_behavior/pattern/actor_probe
	id = "actor_probe"
	priority = 5
	var/list/events = list()
	var/facts = 0

/datum/netrun_agent_behavior/pattern/actor_probe/on_install()
	return listen(owner, "netrun_actor_probe_fact", PROC_REF(on_fact))

/datum/netrun_agent_behavior/pattern/actor_probe/proc/on_fact(datum/source)
	SIGNAL_HANDLER
	facts++

/datum/netrun_agent_behavior/pattern/actor_probe/process_tick(delta)
	events += id

/datum/netrun_agent_behavior/pattern/actor_probe/on_remove()
	events += "remove:[id]"

/datum/netrun_agent_behavior/pattern/actor_probe/second
	id = "actor_probe_second"
	priority = 7

/datum/netrun_agent_behavior/pattern/actor_probe/late
	id = "actor_probe_late"
	priority = 6

/datum/netrun_agent_behavior/pattern/actor_probe/dependent
	id = "actor_probe_dependent"
	priority = 8
	requires = list("actor_probe")

/datum/netrun_agent_behavior/pattern/actor_probe/missing
	id = "actor_probe_missing"
	requires = list("actor_probe_absent")

/datum/netrun_agent_behavior/pattern/actor_probe/mutator
	id = "actor_probe_mutator"
	priority = 3
	var/mutated = FALSE

/datum/netrun_agent_behavior/pattern/actor_probe/mutator/process_tick(delta)
	..()
	if(mutated)
		return
	mutated = TRUE
	controller.remove_module("actor_probe_second")
	var/datum/netrun_agent_behavior/pattern/actor_probe/late/late = controller.install_module(/datum/netrun_agent_behavior/pattern/actor_probe/late)
	late.events = events

/// Dependency resolution, reverse removal and subscriptions belong to one common host.
/datum/unit_test/netrun_actor_shared_composition/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/player = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	var/mob/camera/netrun_entity/bot/bot = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, NETRUN_BOT_SENTINEL)
	var/datum/netrun_ice/ice = allocate(/datum/netrun_ice, scene.node_a)
	for(var/datum/actor as anything in list(player, bot, ice))
		var/datum/netrun_module_host/host = actor.netrun_actor_modules()
		TEST_ASSERT(istype(host), "Every actor supplies the common composition host")
		TEST_ASSERT_NULL(host.install_module(/datum/netrun_agent_behavior/pattern/actor_probe/missing), "A missing requirement is rejected for every representation")
		TEST_ASSERT(host.assemble_modules(list(/datum/netrun_agent_behavior/pattern/actor_probe/dependent, /datum/netrun_agent_behavior/pattern/actor_probe)), "Dependency assembly is independent of declaration order")
		var/datum/netrun_agent_behavior/pattern/actor_probe/probe = host.modules["actor_probe"]
		TEST_ASSERT_EQUAL(probe.bound_owner(), actor, "Portable capabilities bind the actual actor")
		TEST_ASSERT_EQUAL(probe.controller, host, "The shared host owns the installed capability")
		TEST_ASSERT(!host.remove_module("actor_probe"), "A live dependent prevents removing its requirement")
		SEND_SIGNAL(actor, "netrun_actor_probe_fact")
		TEST_ASSERT_EQUAL(probe.facts, 1, "A portable module owns one signal reaction")
		TEST_ASSERT(host.set_enabled("actor_probe", FALSE), "Capabilities can be disabled on any actor")
		TEST_ASSERT(!host.entity_module_current(probe), "Disabled capabilities leave action dispatch")
		TEST_ASSERT(host.set_enabled("actor_probe", TRUE), "The same capability can be enabled again")
		TEST_ASSERT(host.entity_module_current(probe), "Re-enabling restores the same installed capability")
		TEST_ASSERT(host.remove_module("actor_probe_dependent") && host.remove_module("actor_probe"), "Leaves and then their resources are removable")
		TEST_ASSERT(QDELETED(probe), "Removing a capability releases its datum")
		TEST_ASSERT(!length(probe.subscriptions), "Removal releases subscriptions for every representation")
		SEND_SIGNAL(actor, "netrun_actor_probe_fact")
		TEST_ASSERT_EQUAL(probe.facts, 1, "A removed capability no longer reacts")

/// Installing or removing during a pass never executes a new capability in that pass.
/datum/unit_test/netrun_actor_shared_mutation/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/player = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	var/mob/camera/netrun_entity/bot/bot = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, NETRUN_BOT_SENTINEL)
	var/datum/netrun_ice/ice = allocate(/datum/netrun_ice, scene.node_a)
	for(var/datum/actor as anything in list(player, bot, ice))
		var/datum/netrun_module_host/host = actor.netrun_actor_modules()
		var/list/events = list()
		for(var/path in list(/datum/netrun_agent_behavior/pattern/actor_probe, /datum/netrun_agent_behavior/pattern/actor_probe/second, /datum/netrun_agent_behavior/pattern/actor_probe/mutator))
			var/datum/netrun_agent_behavior/pattern/actor_probe/probe = host.install_module(path)
			TEST_ASSERT_NOTNULL(probe, "A portable probe installs on every actor")
			probe.events = events
		var/list/before = host.ordered
		host.process_modules(0)
		TEST_ASSERT_EQUAL(jointext(events, ","), "actor_probe_mutator,remove:actor_probe_second,actor_probe", "The active snapshot skips a removed module and defers a newly installed module")
		TEST_ASSERT(before != host.ordered, "Mutation publishes a replacement order")
		events.Cut()
		host.process_modules(0)
		TEST_ASSERT_EQUAL(jointext(events, ","), "actor_probe_mutator,actor_probe,actor_probe_late", "The next pass executes the new capability in priority order")

/// Registry profiles are shared definitions; mutations are private, validated actor state.
/datum/unit_test/netrun_actor_temperament_mutation/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/bot/first = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, NETRUN_BOT_RAIDER)
	var/mob/camera/netrun_entity/bot/second = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, NETRUN_BOT_RAIDER)
	var/mob/camera/netrun_entity/bot/station = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, NETRUN_BOT_CUSTODIAN)
	var/datum/netrun_agent_behavior/pattern/temperament/first_policy = netrun_actor_temperament(first)
	var/datum/netrun_agent_behavior/pattern/temperament/second_policy = netrun_actor_temperament(second)
	TEST_ASSERT(first.program == second.program, "The fixture shares its immutable archetype definition")
	TEST_ASSERT(first_policy && second_policy && first_policy != second_policy, "Each actor owns its own mutable policy")
	var/original_caution = second_policy.caution
	var/original_flee = first.program.flee_ratio
	TEST_ASSERT(first.brain.proactive_enemy(station), "The native raider initially recognizes a station opponent")
	TEST_ASSERT(first.module_host.mutate_pattern("temperament", list("strategy" = "guard", "caution" = 85, "aggression" = 0, "cooperation" = FALSE)), "A live actor can atomically mutate its behavioral traits")
	TEST_ASSERT(!first.brain.proactive_enemy(station), "Zero aggression removes proactive targeting")
	TEST_ASSERT(first.module_host.mutate_pattern("temperament", list("aggression" = 25)), "An actor may choose a cautious engagement threshold")
	TEST_ASSERT(!first.brain.proactive_enemy(station), "Low aggression declines a healthy opponent above the actor's strength threshold")
	TEST_ASSERT(first.module_host.mutate_pattern("temperament", list("aggression" = 75)), "The same actor may choose a bolder engagement threshold")
	TEST_ASSERT(first.brain.proactive_enemy(station), "Higher aggression accepts that same opponent without a repeated random roll")
	TEST_ASSERT_EQUAL(second_policy.caution, original_caution, "Mutating one actor cannot change another actor")
	TEST_ASSERT_EQUAL(second_policy.strategy, "profile", "The other actor retains its strategy")
	TEST_ASSERT_EQUAL(first.program.flee_ratio, original_flee, "Mutation cannot write into the shared archetype")
	TEST_ASSERT(!first.module_host.mutate_pattern("temperament", list("caution" = 10, "strategy" = "unknown")), "An invalid trait rejects the complete mutation")
	TEST_ASSERT_EQUAL(first_policy.caution, 85, "A rejected mixed mutation leaves valid earlier fields untouched")
	TEST_ASSERT(!first.module_host.mutate_pattern("temperament", list("cooperation" = "yes")), "Non-boolean cooperation is rejected")
	first.brain.advance_goals()
	TEST_ASSERT(istype(first.brain.current_goal(), /datum/netrun_bot_goal/guard), "The mutated planning strategy creates its new modular goal")
	var/datum/netrun_ice/ice = allocate(/datum/netrun_ice, scene.node_a)
	TEST_ASSERT(ice.agent.mutate_pattern("temperament", list("strategy" = "guard", "aggression" = 0)), "ICE exposes the same pattern mutation API")
	TEST_ASSERT_EQUAL(netrun_actor_temperament(ice).strategy, "guard", "ICE stores the same portable strategy")
	TEST_ASSERT(ice.agent.set_enabled("temperament", FALSE), "ICE can disable a shared policy")
	TEST_ASSERT_NULL(netrun_actor_temperament(ice), "A disabled pattern cannot influence tactical policy")

/// Real attacks produce bounded, local assistance; text messages never nominate an enemy.
/datum/unit_test/netrun_actor_allied_assistance/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/bot/victim = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, NETRUN_BOT_CUSTODIAN)
	var/mob/camera/netrun_entity/bot/ally = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, NETRUN_BOT_CUSTODIAN)
	var/mob/camera/netrun_entity/bot/attacker = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, NETRUN_BOT_RAIDER)
	var/datum/netrun_ice/ice = allocate(/datum/netrun_ice, scene.node_a)
	victim.apply_damage(1, "test attack", attacker.console)
	TEST_ASSERT(ally.brain.remembered_enemy(attacker), "An allied bot remembers a real local attacker")
	TEST_ASSERT_EQUAL(ice.enemy_ref?.resolve(), attacker, "An allied ICE reacts through the same portable communication capability")
	ally.brain.enemies.Cut()
	ice.enemy_ref = null
	TEST_ASSERT(ally.module_host.mutate_pattern("temperament", list("cooperation" = FALSE)), "Cooperation is independently mutable for a bot")
	TEST_ASSERT(ice.agent.mutate_pattern("temperament", list("cooperation" = FALSE)), "Cooperation is independently mutable for ICE")
	victim.apply_damage(1, "second attack", attacker.console)
	TEST_ASSERT(!ally.brain.remembered_enemy(attacker), "An uncooperative bot does not adopt an ally's target")
	TEST_ASSERT_NULL(ice.enemy_ref, "An uncooperative ICE does not adopt an ally's target")
	ally.module_host.mutate_pattern("temperament", list("cooperation" = TRUE))
	ally.enter_node(scene.node_b)
	victim.apply_damage(1, "remote attack", attacker.console)
	TEST_ASSERT(!ally.brain.remembered_enemy(attacker), "Assistance cannot disclose or adopt targets in a different node")

/// A presence reply has a real input delay and cannot turn into an acknowledgement loop.
/datum/unit_test/netrun_actor_communication_delay/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/bot/sender = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, NETRUN_BOT_CUSTODIAN)
	var/mob/camera/netrun_entity/bot/recipient = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, NETRUN_BOT_CUSTODIAN)
	var/datum/netrun_agent_behavior/pattern/communication/pattern = recipient.entity_modules["communication"]
	SEND_SIGNAL(recipient, COMSIG_NETRUN_ACTOR_CONTACT, sender.console, "hello")
	TEST_ASSERT(IS_WEAKREF_OF(sender.console, pattern.sender_ref), "A message schedules a weakly owned reply")
	TEST_ASSERT(pattern.reply_at >= world.time + 1 SECONDS, "The autonomous reply waits a positive duration")
	TEST_ASSERT(!pattern.behavior_step(recipient.brain), "Early repeated behavior cannot send the reply")
	TEST_ASSERT_EQUAL(recipient.console.next_entity_signal, 0, "No packet or channel cooldown is spent before the delay")
	pattern.reply_at = world.time
	TEST_ASSERT(pattern.behavior_step(recipient.brain), "A due reply uses the ordinary routed presence packet")
	TEST_ASSERT_NULL(pattern.sender_ref, "The reply consumes its pending message once")
	SEND_SIGNAL(sender, COMSIG_NETRUN_ACTOR_CONTACT, recipient.console, null)
	var/datum/netrun_agent_behavior/pattern/communication/sender_pattern = sender.entity_modules["communication"]
	TEST_ASSERT_NULL(sender_pattern.sender_ref, "A presence acknowledgement cannot create another reply")
	TEST_ASSERT(recipient.remove_module("communication"), "Communication is an ordinary removable pattern")
	TEST_ASSERT_NULL(pattern.reply_timer, "Removing communication cancels its outstanding timer")

/// Actual owned executable files control admission, including one-shot program consumption.
/datum/unit_test/netrun_actor_ice_program_memory/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/player = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	var/datum/netrun_ice/ice = allocate(/datum/netrun_ice, scene.node_a, NETRUN_ICE_BLACK)
	var/datum/netrun_program/assault = SSnetrun.get_program("assault")
	var/datum/netrun_file/file = ice.agent.program_file("assault")
	TEST_ASSERT_NOTNULL(file, "The declared program occupies actual ICE memory")
	TEST_ASSERT(ice.agent.memory.remove(file), "An executable may leave ICE memory")
	TEST_ASSERT(!ice.begin_program(assault, player), "A profile ID alone cannot launch a removed executable")
	TEST_ASSERT_NULL(ice.pending_program, "Denied admission cannot leave a pending cast")
	TEST_ASSERT(ice.agent.memory.insert(file), "Returning the actual file restores the executable")
	var/datum/netrun_file/bomb = netrun_program_file("logic_bomb")
	TEST_ASSERT(ice.agent.memory.insert(bomb), "A new ordinary one-shot program consumes real ICE memory")
	TEST_ASSERT(ice.begin_program(SSnetrun.get_program("logic_bomb"), player), "A newly uploaded executable is available through native cast admission")
	TEST_ASSERT(QDELETED(bomb), "Successful admission consumes the one-shot file exactly once")
	TEST_ASSERT_NULL(ice.agent.program_file("logic_bomb"), "The consumed program cannot remain in the owned file index")
	TEST_ASSERT(ice.attack_at >= world.time + NETRUN_ICE_MIN_TELEGRAPH, "Program parity retains the first-contact warning")
	ice.cancel_program()
	TEST_ASSERT(!ice.begin_program(SSnetrun.get_program("logic_bomb"), player), "Cancelling cannot recreate the consumed program")

/// Guards may fight other processes without changing their native turn identity.
/datum/unit_test/netrun_actor_ice_peer_combat/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/datum/netrun_ice/station = allocate(/datum/netrun_ice, scene.node_a)
	var/datum/netrun_ice/ally = allocate(/datum/netrun_ice, scene.node_a)
	var/datum/netrun_ice/black = allocate(/datum/netrun_ice, scene.node_a, NETRUN_ICE_BLACK)
	var/datum/netrun_program/strike = SSnetrun.get_program("strike")
	TEST_ASSERT(!station.hostile_actor(ally, scene.node_a), "Ordinary station guards recognize their shared faction")
	TEST_ASSERT(!station.begin_program(strike, ally), "A station guard cannot directly cast a hostile program at its ally")
	TEST_ASSERT(station.hostile_actor(black, scene.node_a), "A station guard recognizes a foreign BLACK ICE process as hostile")
	TEST_ASSERT(black.hostile_actor(station, scene.node_a), "Hostile peer contact is reciprocal")
	TEST_ASSERT_EQUAL(station.find_intruder(scene.node_a), black, "The local tactical search includes a hostile lightweight peer")
	TEST_ASSERT(station.begin_program(strike, black), "ICE-to-ICE combat uses the ordinary native program admission")
	TEST_ASSERT_EQUAL(station.pending_target(), black, "The announced target retains its stable ICE datum identity")
	TEST_ASSERT(station.attack_at >= world.time + NETRUN_ICE_MIN_TELEGRAPH, "Peer combat retains the complete first-contact escape window")
	var/datum/netrun_combat_encounter/encounter = station.get_combat_encounter()
	TEST_ASSERT(encounter?.active && encounter.has_turn(station), "The preparing guard owns its actual encounter turn")
	TEST_ASSERT(encounter.contains(black), "The peer participates with its native turn actor")
	TEST_ASSERT(!black.begin_program(SSnetrun.get_program("assault"), station), "A peer cannot retaliate while the other guard's turn is deferred")
	var/before = black.integrity
	station.resolve_program()
	TEST_ASSERT_EQUAL(black.integrity, before, "Repeated early resolution cannot bypass the peer telegraph")
	black.leave_node()
	station.attack_at = world.time
	station.resolve_program()
	TEST_ASSERT_NULL(station.pending_program, "Leaving the source node cancels a prepared peer attack")
	TEST_ASSERT_EQUAL(black.integrity, before, "A stale peer lock cannot deliver damage after departure")

/// A mutable social policy is rechecked when work is due, rather than only at receipt.
/datum/unit_test/netrun_actor_communication_mutation/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/bot/sender = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, NETRUN_BOT_CUSTODIAN)
	var/mob/camera/netrun_entity/bot/recipient = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, NETRUN_BOT_CUSTODIAN)
	var/datum/netrun_agent_behavior/pattern/communication/pattern = recipient.entity_modules["communication"]
	SEND_SIGNAL(recipient, COMSIG_NETRUN_ACTOR_CONTACT, sender.console, "hello")
	TEST_ASSERT_NOTNULL(pattern.sender_ref, "The cooperative recipient initially schedules its delayed reply")
	TEST_ASSERT(recipient.module_host.mutate_pattern("temperament", list("cooperation" = FALSE)), "Cooperation can change while the reply is pending")
	pattern.reply_at = world.time
	TEST_ASSERT(!pattern.behavior_step(recipient.brain), "A due reply obeys the actor's current cooperation policy")
	TEST_ASSERT_NULL(pattern.sender_ref, "The suppressed reply cannot reappear after another behavior wake")
	TEST_ASSERT_EQUAL(recipient.console.next_entity_signal, 0, "Suppressing a reply does not allocate a packet or spend a channel cooldown")

/// Social input cannot consume the combat action or leave an autonomous turn idle.
/datum/unit_test/netrun_actor_communication_combat/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/bot/sender = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, NETRUN_BOT_CUSTODIAN)
	var/mob/camera/netrun_entity/bot/recipient = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, NETRUN_BOT_CUSTODIAN)
	var/datum/netrun_agent_behavior/pattern/communication/pattern = recipient.entity_modules["communication"]
	SEND_SIGNAL(recipient, COMSIG_NETRUN_ACTOR_CONTACT, sender.console, "hello")
	TEST_ASSERT_NOTNULL(pattern.sender_ref, "A peaceful message schedules work before combat begins")
	pattern.reply_at = world.time
	var/mob/camera/netrun_entity/bot/enemy = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, NETRUN_BOT_RAIDER)
	var/datum/netrun_combat_encounter/encounter = scene.node_a.get_combat_encounter()
	TEST_ASSERT(encounter.admit(recipient.console, 1, enemy), "The recipient starts its actual native combat turn")
	var/initial_ap = encounter.remaining_ap(recipient.console)
	TEST_ASSERT(!pattern.behavior_step(recipient.brain), "A due reply declines to occupy an active combat step")
	TEST_ASSERT_NULL(pattern.sender_ref, "A reply queued before combat is discarded")
	TEST_ASSERT_EQUAL(encounter.remaining_ap(recipient.console), initial_ap, "Discarding social work leaves the real action budget intact")
	TEST_ASSERT(encounter.has_turn(recipient.console), "Discarding social work cannot pass the recipient's turn")
	SEND_SIGNAL(recipient, COMSIG_NETRUN_ACTOR_CONTACT, sender.console, "another hello")
	TEST_ASSERT_NULL(pattern.sender_ref, "Messages arriving in active combat cannot schedule a replacement reply")
	var/before = enemy.integrity
	TEST_ASSERT(recipient.process_behavior(recipient.brain), "The same shared behavior dispatcher can advance the combat action")
	TEST_ASSERT(enemy.integrity < before || enemy.is_stunned(), "An autonomous combat step attacks or controls its actual opponent")
	TEST_ASSERT_EQUAL(recipient.console.next_entity_signal, 0, "Combat priority does not send a presence packet instead of fighting")

	// The lightweight representation obeys the same active-encounter gate.
	sender.enter_node(scene.node_b)
	var/datum/netrun_ice/guard = allocate(/datum/netrun_ice, scene.node_b)
	var/datum/netrun_agent_behavior/pattern/communication/guard_pattern = guard.agent.modules["communication"]
	SEND_SIGNAL(guard, COMSIG_NETRUN_ACTOR_CONTACT, sender.console, "hello guard")
	TEST_ASSERT_NOTNULL(guard_pattern.sender_ref, "An idle guard also accepts delayed social work")
	var/datum/netrun_ice/black = allocate(/datum/netrun_ice, scene.node_b, NETRUN_ICE_BLACK)
	TEST_ASSERT(guard.begin_program(SSnetrun.get_program("strike"), black), "The lightweight guard starts an ordinary peer combat turn")
	var/datum/netrun_combat_encounter/guard_encounter = guard.get_combat_encounter()
	guard_pattern.reply_at = world.time
	TEST_ASSERT(!guard_pattern.behavior_step(null), "A guard's queued reply cannot replace its combat action")
	TEST_ASSERT(guard_encounter.has_turn(guard) && guard.pending_program, "Social cancellation preserves the guard's own turn and prepared program")
	TEST_ASSERT_NULL(guard.netrun_actor_console(FALSE), "Dropping a combat reply does not create an unused ICE session")

/// A contraband peer remains a LAN interest after its deploying entity has left.
/datum/unit_test/netrun_actor_ice_peer_patrol_interest/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/datum/netrun_ice/hunter = allocate(/datum/netrun_ice, scene.apc_node, NETRUN_ICE_HUNTER)
	hunter.persistent = TRUE
	SSnetrun.collect_defense_network_interest()
	TEST_ASSERT(!hunter.needs_netrun_tick(), "An otherwise empty LAN keeps a persistent patrol asleep")
	var/mob/camera/netrun_entity/deployer = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_b)
	var/datum/netrun_ice/black = allocate(/datum/netrun_ice, scene.node_b, NETRUN_ICE_BLACK)
	TEST_ASSERT(black in SSnetrun.illegal_ice, "The contraband peer enters its bounded interest index")
	qdel(deployer)
	TEST_ASSERT(!length(scene.node_b.entities), "The deployment's resident is actually gone")
	SSnetrun.collect_defense_network_interest()
	TEST_ASSERT(SSnetrun.active_defense_networks[scene.node_b.network.id], "A surviving illegal peer keeps its LAN active without an entity or breach")
	hunter.hop_cooldown = world.time
	TEST_ASSERT(hunter.needs_netrun_tick(), "The persistent hunter remains eligible for its budgeted patrol step")
	TEST_ASSERT(hunter.hunt(), "A native hunter can pursue the remaining hostile lightweight peer")
	TEST_ASSERT_EQUAL(hunter.node, scene.node_b, "The pursuit crosses the actual APC-to-endpoint edge")
	TEST_ASSERT_EQUAL(hunter.find_intruder(scene.node_b), black, "The peer remains a legitimate local target on arrival")
	qdel(black)
	TEST_ASSERT(!(black in SSnetrun.illegal_ice), "Deleting the contraband peer removes its bounded interest record")
	SSnetrun.collect_defense_network_interest()
	TEST_ASSERT(!hunter.needs_netrun_tick(), "Removing the final real threat lets the empty LAN sleep again")
