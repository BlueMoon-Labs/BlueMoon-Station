/// Visitors begin without residency rights, home-LAN GUEST, or a key file.
/datum/unit_test/netrun_visitor_spawn_clearance/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	for(var/id in list(NETRUN_BOT_RAIDER, "scavenger", "redshift_raider", "redshift_hacker", "collective_guard", "archive_collector"))
		var/mob/camera/netrun_entity/bot/bot = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, id)
		TEST_ASSERT(!length(bot.console.access_session.node_access) && !length(bot.console.access_session.network_access), "Visitors receive no direct starting grants")
		TEST_ASSERT_EQUAL(bot.console.node_level(scene.node_a), NETRUN_ACCESS_NONE, "Even spawn residency does not confer machine authority")
		TEST_ASSERT_EQUAL(bot.console.network_level(scene.node_a.network), NETRUN_ACCESS_NONE, "Presence does not give a free home-LAN entry")
		TEST_ASSERT(!bot.console.has_key(scene.node_a.network, TRUE), "No pre-issued LAN key is hidden in the loadout")
		TEST_ASSERT_NOTNULL(bot.entity_modules["hacking"], "A real installed tool supplies hacking capability")
		TEST_ASSERT(!bot.can_enter(scene.apc_node), "A closed neighbouring machine cannot be entered before hacking")

/// Ordinary native breaches acquire each frontier, not a blanket traversal exception.
/datum/unit_test/netrun_visitor_hacked_frontiers/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/bot/bot = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, "scavenger")
	bot.brain.clear_goals()
	bot.brain.push_goal(new /datum/netrun_bot_goal/hack(bot.brain, scene.node_b))
	var/datum/netrun_bot_goal/hack/goal = bot.brain.current_goal()
	var/node_breaches = 0
	for(var/index in 1 to 14)
		bot.next_hop = world.time
		TEST_ASSERT(goal.advance() != NETRUN_BOT_GOAL_FAILED, "The closed but physical route remains hackable")
		var/datum/netrun_breach/npc/breach = bot.console.intrusion.breach
		if(breach)
			if(breach.target_kind == "node")
				node_breaches++
			TEST_ASSERT(netrun_complete_npc_breach(bot.console), "The visitor solves its native frontier puzzle through legal delayed inputs")
		else if(bot.host_node == scene.node_b)
			break
	TEST_ASSERT(node_breaches >= 2, "The visitor independently hacks APC and destination after opening the LAN")
	TEST_ASSERT_EQUAL(bot.host_node, scene.node_b, "Every traversed edge used the normal authorized hop")
	TEST_ASSERT_EQUAL(bot.console.node_level(scene.node_b), NETRUN_ACCESS_ROOT, "The visitor earns the same native puzzle reward as a player")
	scene.apc_node.raise_firewall()
	bot.console.access_session.process_events()
	TEST_ASSERT(!bot.can_enter(scene.apc_node), "A firewall revokes the learned entry despite the retained LAN grant")

/// An interrupted warning cannot mature later, including a fast APC disconnect/reconnect.
/datum/unit_test/netrun_invasion_isolation_counterplay/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/previous_global = SSnetrun.next_station_invasion
	SSnetrun.next_station_invasion = 0
	var/mob/camera/netrun_entity/bot/bot = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.apc_node, "redshift_hacker")
	bot.brain.clear_goals()
	bot.console.access_session.grant_node(scene.apc_node, NETRUN_ACCESS_USER)
	var/datum/netrun_bot_goal/station_invasion/goal = new(bot.brain, scene.apc_node)
	bot.brain.push_goal(goal)
	var/result = goal.advance()
	SSnetrun.next_station_invasion = previous_global
	TEST_ASSERT_EQUAL(result, NETRUN_BOT_GOAL_CONTINUE, "A warning starts before any physical effect")
	TEST_ASSERT_EQUAL(scene.apc.failure_timer, 0, "The warning itself does not disrupt equipment")
	TEST_ASSERT(goal.disrupt_at >= world.time + 30 SECONDS, "The crew has a full response window")
	scene.apc.set_netrun_isolated(TRUE)
	scene.apc.set_netrun_isolated(FALSE)
	goal.disrupt_at = world.time
	TEST_ASSERT_EQUAL(goal.advance(), NETRUN_BOT_GOAL_FAILED, "Even brief physical isolation permanently interrupts this hold")
	TEST_ASSERT_EQUAL(scene.apc.failure_timer, 0, "A reconnected APC cannot receive a delayed cancelled attack")
	bot.brain.clear_goals()
	TEST_ASSERT_NULL(scene.apc_node.station_invasion_ref, "Goal cleanup releases the node's active raid")

/// A sustained hostile hold has a bounded native effect and cannot immediately repeat.
/datum/unit_test/netrun_invasion_bounded_effect/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	scene.apc.area.requires_power = TRUE
	if(!scene.apc.cell)
		scene.apc.cell = allocate(/obj/item/stock_parts/cell/high, scene.apc)
	scene.apc.cell.charge = scene.apc.cell.maxcharge
	scene.apc.update()
	TEST_ASSERT(scene.apc.area.power_equip, "The real APC powers equipment before the attack")
	var/previous_global = SSnetrun.next_station_invasion
	SSnetrun.next_station_invasion = 0
	var/mob/camera/netrun_entity/bot/bot = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.apc_node, "redshift_hacker")
	bot.brain.clear_goals()
	bot.console.access_session.grant_node(scene.apc_node, NETRUN_ACCESS_USER)
	var/datum/netrun_bot_goal/station_invasion/goal = new(bot.brain, scene.apc_node)
	bot.brain.push_goal(goal)
	goal.advance()
	SSnetrun.next_station_invasion = previous_global
	goal.disrupt_at = world.time
	TEST_ASSERT_EQUAL(goal.advance(), NETRUN_BOT_GOAL_DONE, "An uninterrupted warning matures into one effect")
	TEST_ASSERT(!scene.apc.area.power_equip, "The native failure actually cuts the area's equipment power")
	scene.apc.process()
	TEST_ASSERT_EQUAL(scene.apc.failure_timer, 0, "One native machine fire exhausts the failure countdown")
	TEST_ASSERT(!scene.apc.area.power_equip, "Native APC recovery waits for the following fire")
	scene.apc.process()
	TEST_ASSERT(scene.apc.area.power_equip, "The following native machine fire restores the area's equipment power")
	TEST_ASSERT(2 * SSmachines.wait <= 5 SECONDS, "The native recovery takes at most five seconds at the configured machine cadence")
	TEST_ASSERT(!scene.apc.netrun_isolated, "The attack never permanently switches the physical interface")
	TEST_ASSERT(scene.apc_node.station_invasion_ready_at >= world.time + 2 MINUTES, "A sector cooldown prevents continuous disruption")
	bot.brain.clear_goals()
	TEST_ASSERT(!bot.brain.node_can_be_raided(scene.apc_node), "A fresh goal cannot bypass the cooldown")

/// Neutral visitors and owned agents cannot activate this autonomous threat policy.
/datum/unit_test/netrun_invasion_faction_policy/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/bot/neutral = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.apc_node, "collective_guard")
	neutral.brain.clear_goals()
	var/datum/netrun_bot_goal/station_invasion/goal = allocate(/datum/netrun_bot_goal/station_invasion, neutral.brain, scene.apc_node)
	TEST_ASSERT_EQUAL(goal.advance(), NETRUN_BOT_GOAL_FAILED, "A neutral faction does not sabotage station equipment")

/// Telecom disruption uses native service availability and restores without toggling the machine.
/datum/unit_test/netrun_invasion_telecom_recovery/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/obj/machinery/telecomms/relay/machine = scene.machine(/obj/machinery/telecomms/relay, get_turf(scene.node_b.parent))
	machine.toggled = TRUE
	machine.update_power()
	var/datum/component/netrun_node/node = netrun_find_node(machine)
	var/previous_global = SSnetrun.next_station_invasion
	SSnetrun.next_station_invasion = 0
	var/mob/camera/netrun_entity/bot/bot = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, node, "redshift_hacker")
	bot.brain.clear_goals()
	bot.console.access_session.grant_node(node, NETRUN_ACCESS_USER)
	var/datum/netrun_bot_goal/station_invasion/goal = new(bot.brain, node)
	bot.brain.push_goal(goal)
	goal.advance()
	SSnetrun.next_station_invasion = previous_global
	TEST_ASSERT(goal.disrupt_at > world.time, "Telecom loss must also have a visible warning phase")
	goal.disrupt_at = world.time
	TEST_ASSERT_EQUAL(goal.advance(), NETRUN_BOT_GOAL_DONE, "A sustained telecom hold causes one bounded outage")
	TEST_ASSERT(!node.is_online(), "The actual communication service becomes unavailable")
	TEST_ASSERT_EQUAL(node.offline_until, world.time + 5 SECONDS, "The communication outage has a fixed recovery deadline")
	TEST_ASSERT(machine.toggled && machine.on, "The attack preserves the operator's native switch state")
	node.offline_until = world.time
	node.reconcile_state()
	TEST_ASSERT(node.is_online(), "The service returns when its transient deadline expires")
	bot.brain.clear_goals()

/// Defeating the holder releases the claimed raid and cannot retain a later physical mutation.
/datum/unit_test/netrun_invasion_holder_deletion/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/previous_global = SSnetrun.next_station_invasion
	SSnetrun.next_station_invasion = 0
	var/before = length(SSnetrun.active_station_invasions)
	var/mob/camera/netrun_entity/bot/bot = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.apc_node, "redshift_hacker")
	bot.brain.clear_goals()
	bot.console.access_session.grant_node(scene.apc_node, NETRUN_ACCESS_USER)
	var/datum/netrun_bot_goal/station_invasion/goal = new(bot.brain, scene.apc_node)
	bot.brain.push_goal(goal)
	goal.advance()
	SSnetrun.next_station_invasion = previous_global
	TEST_ASSERT_EQUAL(length(SSnetrun.active_station_invasions), before + 1, "A warned hold reserves one bounded global slot")
	qdel(bot)
	TEST_ASSERT(QDELETED(goal), "The brain owns and destroys its incomplete raid")
	TEST_ASSERT_EQUAL(length(SSnetrun.active_station_invasions), before, "Defeat releases the global slot")
	TEST_ASSERT_NULL(scene.apc_node.station_invasion_ref, "Defeat releases the physical node's claim")
	TEST_ASSERT_EQUAL(scene.apc.failure_timer, 0, "Defeat during warning cannot execute the physical attack")

/// Beginning a real encounter invalidates the whole hold, even if combat ends before its deadline.
/datum/unit_test/netrun_invasion_combat_counterplay/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/previous_global = SSnetrun.next_station_invasion
	SSnetrun.next_station_invasion = 0
	var/mob/camera/netrun_entity/bot/bot = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.apc_node, "redshift_hacker")
	bot.brain.clear_goals()
	bot.console.access_session.grant_node(scene.apc_node, NETRUN_ACCESS_USER)
	var/datum/netrun_bot_goal/station_invasion/goal = new(bot.brain, scene.apc_node)
	bot.brain.push_goal(goal)
	goal.advance()
	SSnetrun.next_station_invasion = previous_global
	var/mob/camera/netrun_entity/defender = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.apc_node)
	var/datum/netrun_combat_encounter/encounter = scene.apc_node.get_combat_encounter()
	TEST_ASSERT(encounter.admit(defender, 1, bot), "A real defending process can engage the holder")
	TEST_ASSERT(goal.interrupted, "Combat-start notifications interrupt the warning immediately")
	goal.disrupt_at = world.time
	TEST_ASSERT_EQUAL(goal.advance(), NETRUN_BOT_GOAL_FAILED, "A fight cannot count as uninterrupted station occupation")
	TEST_ASSERT_EQUAL(scene.apc.failure_timer, 0, "The interrupted warning has no physical side effect")
	bot.brain.clear_goals()
