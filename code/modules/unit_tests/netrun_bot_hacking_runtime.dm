/// Runtime diagnostics retain the actual clock, puzzle and goal state on failure.
/datum/unit_test/proc/netrun_bot_hacking_runtime_state(mob/camera/netrun_entity/bot/bot, datum/component/netrun_node/entry)
	if(QDELETED(bot))
		return "bot deleted"
	var/datum/netrun_bot_goal/hack/goal = bot.brain.current_goal()
	var/datum/netrun_breach/npc/breach = bot.console.intrusion.breach
	var/waiting = istype(goal) ? goal.waiting : null
	var/cursor = istype(breach) ? breach.solution_cursor : null
	return "state=[bot.brain.state], goal=[goal?.type], waiting=[waiting], host=[bot.host_node?.address], breach=[breach?.target_kind]:[breach?.target_id], cursor=[cursor], time_left=[breach?.time_left()], trace=[bot.console.intrusion.trace], entry_level=[bot.console.node_level(entry)], network_level=[bot.console.network_level(entry.network)]"

/// Initial relay entry is not replaced by a different goal or a pre-issued key.
/// Actual timer admissions and console tasks must finish the puzzles in real time.
/datum/unit_test/netrun_bot_hacking_runtime_relay/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, origin)
	var/turf/relay_spot = scene.take(get_step(get_step(origin, NORTH), NORTH), scene.apc.area)
	var/obj/machinery/ntnet_relay/relay = scene.machine(/obj/machinery/ntnet_relay, relay_spot)
	SSnetworks.station_network.setting_disabled = FALSE
	SSnetrun.ensure_topology()
	var/datum/component/netrun_node/entry = relay.GetComponent(/datum/component/netrun_node)
	TEST_ASSERT(relay.is_operational() && entry.is_online(), "The fixture provides an actual functioning station relay")
	TEST_ASSERT_EQUAL(entry.base_security, 4, "The real relay keeps its native base difficulty")
	TEST_ASSERT_EQUAL(entry.network, scene.apc_node.network, "The relay attaches to the native APC LAN")
	// This test isolates autonomous input and scheduling; separate ICE tests
	// cover defended breaches. Avoid injecting a guard into either frontier.
	entry.reactive_defense_seeded = TRUE
	scene.apc_node.reactive_defense_seeded = TRUE
	var/mob/camera/netrun_entity/bot/bot = allocate(/mob/camera/netrun_entity/bot, relay_spot, entry, "scavenger")
	var/datum/netrun_bot_goal/hack/initial_goal = bot.brain.current_goal()
	TEST_ASSERT(istype(initial_goal) && initial_goal.target_ref.resolve() == entry, "The visitor retains its real initial self-host hacking goal")
	TEST_ASSERT_EQUAL(bot.console.node_level(entry), NETRUN_ACCESS_NONE, "Relay presence does not pre-authorize the visiting process")
	var/datum/controller/subsystem/netrun/netrun_execution_test/worker = allocate(/datum/controller/subsystem/netrun/netrun_execution_test)
	worker.next_task_population = INFINITY
	var/datum/netrun_task_scheduler/scheduler = worker.get_task_scheduler()
	var/deadline = world.time + 45 SECONDS
	var/next_population = world.time
	var/saw_network_puzzle = FALSE
	var/saw_relay_puzzle = FALSE
	var/earned_relay = FALSE
	var/left_entry = FALSE
	while(!QDELETED(bot) && world.time < deadline)
		// The normal brain timer/completion signal admits to SSnetrun. Move
		// only this fixture's due work to the isolated worker, preserving its
		// real wakeup time and the native bot task's schedule_next() behavior.
		if(SSnetrun.task_scheduler?.by_key["bot:[REF(bot.brain)]"])
			SSnetrun.task_scheduler.cancel("bot", bot.brain)
			scheduler.enqueue("bot", bot.brain, NETRUN_TASK_NORMAL)
		if(world.time >= next_population)
			next_population = world.time + worker.get_execution_limits().population_interval
			if((bot.console in SSnetrun.active_consoles) && bot.console.needs_processing())
				scheduler.enqueue("console", bot.console, NETRUN_TASK_CRITICAL)
		worker.run_pass()
		var/datum/netrun_breach/breach = bot.console.intrusion.breach
		if(breach?.target_kind == "network")
			saw_network_puzzle = TRUE
		if(breach?.target_kind == "node" && breach.target_id == entry.address)
			saw_relay_puzzle = TRUE
		earned_relay ||= bot.console.access_session.acquired_node_level(entry) >= NETRUN_ACCESS_USER
		if(bot.host_node != entry)
			left_entry = TRUE
			break
		sleep(world.tick_lag)
	var/state = netrun_bot_hacking_runtime_state(bot, entry)
	for(var/datum/netrun_incident/incident as anything in SSnetrun.incidents)
		if(!QDELETED(bot) && (incident.suspect() == bot || incident.suspect() == bot.console))
			incident.close("fixture complete")
	TEST_ASSERT(!QDELETED(bot), "The isolated visitor survives its runtime scenario: [state]")
	TEST_ASSERT(saw_network_puzzle, "The unprivileged visitor actually starts its LAN bootstrap puzzle: [state]")
	TEST_ASSERT(saw_relay_puzzle && earned_relay, "Real elapsed time and console tasks acquire the relay itself: [state]")
	TEST_ASSERT(left_entry, "After acquiring entry, the ordinary brain moves toward its next reachable frontier: [state]")

/// Defending an ambient entry must not starve the same background input a player can start.
/datum/unit_test/netrun_bot_hacking_runtime_combat_bootstrap/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, origin)
	var/turf/relay_spot = scene.take(get_step(get_step(origin, NORTH), NORTH), scene.apc.area)
	var/obj/machinery/ntnet_relay/relay = scene.machine(/obj/machinery/ntnet_relay, relay_spot)
	SSnetworks.station_network.setting_disabled = FALSE
	SSnetrun.ensure_topology()
	var/datum/component/netrun_node/entry = relay.GetComponent(/datum/component/netrun_node)
	TEST_ASSERT(relay.is_operational() && entry.is_online(), "The protected fixture supplies an actual functioning relay")
	var/datum/controller/subsystem/netrun/netrun_execution_test/worker = allocate(/datum/controller/subsystem/netrun/netrun_execution_test)
	worker.next_task_population = INFINITY
	var/datum/netrun_task_scheduler/scheduler = worker.get_task_scheduler()
	for(var/id in list(NETRUN_BOT_RAIDER, "scavenger", "redshift_raider", "redshift_hacker", "collective_guard", "archive_collector"))
		var/mob/camera/netrun_entity/bot/bot = allocate(/mob/camera/netrun_entity/bot, relay_spot, entry, id)
		var/datum/netrun_bot_goal/initial_goal = bot.brain.current_goal()
		var/datum/netrun_ice/ice = allocate(/datum/netrun_ice, entry)
		TEST_ASSERT(ice.begin_program(SSnetrun.get_program("strike"), bot), "[id]: a real guard prepares its ordinary first attack")
		var/datum/netrun_combat_encounter/encounter = ice.get_combat_encounter()
		var/ap_before = encounter.remaining_ap(ice)
		var/datum/netrun_program/pending_before = ice.pending_program
		SSnetrun.get_task_scheduler().cancel("bot", bot.brain)
		scheduler.enqueue("bot", bot.brain, NETRUN_TASK_NORMAL)
		worker.run_pass()
		var/datum/netrun_breach/npc/breach = bot.console.intrusion.breach
		var/started_background = istype(breach) && breach.target_kind == "network"
		var/preserved_turn = encounter.has_turn(ice) && encounter.remaining_ap(ice) == ap_before && ice.pending_program == pending_before
		var/preserved_goal = bot.brain.current_goal() == initial_goal
		// Cancellation and passing are ordinary native combat events; no AP,
		// initiative index or decision deadline is edited to give the bot a turn.
		ice.cancel_program()
		if(encounter.has_turn(ice))
			encounter.pass(ice)
		var/received_turn = encounter.has_turn(bot)
		var/health_before = ice.integrity
		SSnetrun.get_task_scheduler().cancel("bot", bot.brain)
		scheduler.enqueue("bot", bot.brain, NETRUN_TASK_NORMAL)
		worker.run_pass()
		var/acted_in_combat = ice.integrity < health_before || ice.is_stunned()
		var/followup_armed = !encounter.has_turn(bot) || encounter.remaining_ap(bot) <= 0 || !!bot.brain.timer_id
		var/state = netrun_bot_hacking_runtime_state(bot, entry)
		// This fixture owns its breach/combat reports; later police tests must
		// not investigate the synthetic visitor after the actors are deleted.
		for(var/datum/netrun_incident/incident as anything in SSnetrun.incidents)
			if(incident.suspect() == bot || incident.suspect() == bot.console)
				incident.close("fixture complete")
		qdel(ice)
		qdel(bot)
		TEST_ASSERT(started_background, "[id]: native combat must not suppress the visitor's background LAN puzzle: [state]")
		TEST_ASSERT(preserved_turn && preserved_goal, "[id]: starting a background puzzle preserves the current actor, AP, prepared attack and hacking goal: [state]")
		TEST_ASSERT(received_turn && acted_in_combat, "[id]: the same native bot task still defends during its actual own turn: [state]")
		TEST_ASSERT(followup_armed, "[id]: a background puzzle cannot consume the remaining autonomous combat decision without its follow-up timer: [state]")

/// A successful local entry and explicit cleanup end stale ICE retaliation, not unrelated feuds.
/datum/unit_test/netrun_bot_hacking_runtime_disengage_memory/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/bot/bot = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, "collective_guard")
	var/mob/camera/netrun_entity/bot/other = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, "redshift_raider")
	var/datum/netrun_ice/ice = allocate(/datum/netrun_ice, scene.node_a)
	bot.brain.mark_enemy(ice)
	bot.brain.mark_enemy(other)
	ice.enemy_ref = WEAKREF(bot)
	TEST_ASSERT(bot.console.record_breach_grant("node", scene.node_a.address, NETRUN_ACCESS_USER), "The native acquired-key pipeline records the fixture's completed local entry")
	TEST_ASSERT(ice in bot.brain.hostiles(), "The setup contains remembered ICE retaliation even with newly acquired entry")
	bot.console.disengage_combat()
	// Check authority after the grace period too: temporary concealment alone
	// must not hide a still-retained retaliatory target from this assertion.
	bot.combat_ignore_until = world.time
	TEST_ASSERT(!bot.brain.remembered_enemy(ice), "Explicit cleanup forgets the guard that abandoned this actor")
	TEST_ASSERT(bot.brain.remembered_enemy(other), "Explicit ICE cleanup preserves an unrelated hostile process")
	TEST_ASSERT(!ice.is_intruder(bot, scene.node_a), "The guard respects the completed USER entry after cleanup")
	var/list/hostiles = bot.brain.hostiles()
	TEST_ASSERT(!(ice in hostiles) && (other in hostiles), "Native tactical selection stops stale guard combat while retaining the unrelated threat")
