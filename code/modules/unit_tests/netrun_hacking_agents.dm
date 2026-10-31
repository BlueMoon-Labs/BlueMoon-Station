/// A daemon is an executable capability, not an invisible flag attached to an archetype.
/datum/unit_test/netrun_hacking_agent_extension_lifecycle/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/bot/agent = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, NETRUN_BOT_SENTINEL)
	TEST_ASSERT_NULL(agent.entity_modules["hacking"], "A normal sentinel has no hidden hacking capability")
	var/datum/netrun_file/tool = netrun_daemon_file("autobreach")
	TEST_ASSERT(agent.console.store_file(tool), "An actual executable can be uploaded into the agent's memory")
	var/datum/netrun_entity_module/hacking/module = agent.entity_modules["hacking"]
	TEST_ASSERT(istype(module) && module.installed, "The inventory fact installs its declared capability")
	var/advertised = FALSE
	for(var/list/order as anything in agent.agent_orders())
		if(order["id"] == "hack")
			advertised = TRUE
	TEST_ASSERT(advertised, "The installed capability contributes its own order")
	var/datum/netrun_bot_goal/hack/goal = new(agent.brain, scene.node_b)
	agent.brain.push_goal(goal)
	TEST_ASSERT_EQUAL(goal.advance(), NETRUN_BOT_GOAL_CONTINUE, "The first inaccessible frontier starts ordinary work")
	var/datum/netrun_breach/npc/breach = agent.console.intrusion.breach
	TEST_ASSERT(istype(breach), "The module starts an ordinary puzzle with delayed autonomous input")
	TEST_ASSERT(goal.waits_for_signal(), "The brain sleeps until the owned breach emits its completion fact")
	agent.console.intrusion.trace = 7
	TEST_ASSERT(agent.console.inventory.local_store.remove(tool), "Removing the real file revokes the capability")
	TEST_ASSERT_NULL(agent.entity_modules["hacking"], "The manager removes a capability whose source file left")
	TEST_ASSERT(QDELETED(module) && QDELETED(breach), "Uninstall releases both the reacting module and its active breach")
	TEST_ASSERT_NULL(agent.console.intrusion.breach, "Revoked automatic work cannot finish later")
	TEST_ASSERT_EQUAL(agent.console.intrusion.trace, 7, "Cancelling retains the native accumulated trace")
	TEST_ASSERT(agent.console.node_level(scene.apc_node) < NETRUN_ACCESS_USER, "Revocation awards no frontier access")
	TEST_ASSERT_EQUAL(goal.advance(), NETRUN_BOT_GOAL_FAILED, "The pending goal reports capability loss")
	qdel(tool)

/// The owner request crosses the normal delivery boundary; each frontier uses a real breach/hop.
/datum/unit_test/netrun_hacking_agent_delivered_goal/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/owner = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	owner.console.operator = owner
	var/datum/netrun_file/template = netrun_bot_file("hacker")
	TEST_ASSERT(owner.console.store_file(template), "The owner has a real launchable hacker template")
	TEST_ASSERT(owner.console.launch_bot_file(template.uid), "The hacker starts through ordinary file launch")
	var/list/agents = owner.console.agents()
	var/mob/camera/netrun_entity/bot/agent = agents[1]
	TEST_ASSERT_NOTNULL(agent.entity_modules["hacking"], "The profile's actual daemon loadout installs hacking")
	TEST_ASSERT(owner.console.agent_order(REF(agent), "hack", scene.node_b.address, list("command" = "scan")), "An installed capability admits its routed owner order")
	TEST_ASSERT_NULL(agent.brain.current_goal(), "Admission cannot inject a goal before packet delivery")
	var/datum/netrun_request/agent_control/control = netrun_operation_packet(owner.console, /datum/netrun_request/agent_control)
	TEST_ASSERT_NOTNULL(control, "The control is a real queued packet")
	control.deliver()
	var/datum/netrun_bot_goal/hack/goal = agent.brain.current_goal()
	TEST_ASSERT(istype(goal), "The authenticated delivery invokes the capability's goal handler")
	var/breaches = 0
	for(var/index in 1 to 12)
		agent.next_hop = world.time
		var/result = goal.advance()
		TEST_ASSERT(result != NETRUN_BOT_GOAL_FAILED, "A reachable physical frontier remains usable")
		var/datum/netrun_breach/npc/breach = agent.console.intrusion.breach
		if(breach)
			breaches++
			var/datum/component/netrun_node/frontier = SSnetrun.find_node(breach.target_id)
			if(breach.target_kind == "node")
				TEST_ASSERT(agent.console.node_level(frontier) < NETRUN_ACCESS_USER, "Starting a timer does not grant frontier USER")
			TEST_ASSERT(netrun_complete_npc_breach(agent.console), "The agent completes the real puzzle one legal input at a time")
			TEST_ASSERT(!goal.waiting, "Native breach destruction wakes the waiting goal")
		else if(agent.host_node == scene.node_b)
			break
	TEST_ASSERT(breaches >= 2, "The agent cracks the APC and the destination independently")
	TEST_ASSERT_EQUAL(agent.host_node, scene.node_b, "The agent traverses A → APC → B with ordinary authorized hops")
	TEST_ASSERT_EQUAL(agent.console.node_level(scene.node_b), NETRUN_ACCESS_ROOT, "Solving the ordinary puzzle earns its real ROOT reward")
	TEST_ASSERT(owner.console.node_level(scene.node_b) < NETRUN_ACCESS_USER, "The agent's acquired access is not granted to its master")
	TEST_ASSERT_EQUAL(goal.advance(), NETRUN_BOT_GOAL_CONTINUE, "The post-breach command still awaits its own delivery")
	var/datum/netrun_request/command/packet = netrun_operation_packet(agent.console, /datum/netrun_request/command)
	TEST_ASSERT_NOTNULL(packet, "The final scan uses the ordinary routed command pipeline")
	packet.deliver()
	TEST_ASSERT_EQUAL(goal.advance(), NETRUN_BOT_GOAL_DONE, "Only the delivered command completes the composed goal")

/// Cancellation cannot leave a detached program, failed route or dead owner's timer running.
/datum/unit_test/netrun_hacking_agent_cancellation/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/datum/netrun_console/master = allocate(/datum/netrun_console, allocate(/obj/item))
	var/mob/camera/netrun_entity/bot/agent = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, "hacker", master)
	var/datum/netrun_bot_goal/hack/goal = new(agent.brain, scene.node_b)
	agent.brain.push_goal(goal)
	goal.advance()
	var/datum/netrun_breach/breach = agent.console.intrusion.breach
	TEST_ASSERT_NOTNULL(breach, "The owned agent has a live breach")
	agent.brain.clear_goals()
	TEST_ASSERT(QDELETED(breach) && !agent.console.intrusion.breach, "Replacing or recalling a goal cancels its owned breach")
	goal = new(agent.brain, scene.node_b)
	agent.brain.push_goal(goal)
	goal.advance()
	breach = agent.console.intrusion.breach
	TEST_ASSERT_NOTNULL(breach, "A new independent goal may try the frontier again")
	scene.apc_node.offline_until = world.time + 1 MINUTES
	agent.console.process_tick(0)
	TEST_ASSERT(QDELETED(breach), "The native breach pipeline rejects a lost physical frontier")
	TEST_ASSERT_EQUAL(goal.advance(), NETRUN_BOT_GOAL_FAILED, "The failed native attempt is not retried in a busy loop")
	scene.apc_node.offline_until = 0
	agent.brain.clear_goals()
	goal = new(agent.brain, scene.node_b)
	agent.brain.push_goal(goal)
	goal.advance()
	breach = agent.console.intrusion.breach
	qdel(master)
	agent.brain.think()
	TEST_ASSERT(QDELETED(agent), "Ordinary owner lifecycle terminates an orphaned hacking agent")
	TEST_ASSERT(QDELETED(breach), "Owner loss cannot leave its console's automatic breach alive")

/// Builder selection packs owned allowlisted daemon files and recalls them by their normal format.
/datum/unit_test/netrun_hacking_agent_builder_modules/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/owner = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	owner.console.operator = owner
	var/datum/netrun_file/template = netrun_bot_file(NETRUN_BOT_SENTINEL)
	var/datum/netrun_file/tool = netrun_daemon_file("autobreach")
	var/datum/netrun_file/assist = netrun_daemon_file("icepick")
	TEST_ASSERT(owner.console.store_file(template) && owner.console.store_file(tool) && owner.console.store_file(assist), "All builder inputs are owned disk files")
	var/list/options = list("uid" = template.uid, "include_defaults" = FALSE, "module_uids" = list(tool.uid, assist.uid))
	var/datum/netrun_file/bot/built = owner.console.create_agent_file(options, owner)
	TEST_ASSERT_NOTNULL(built, "A normal sentinel can receive the same modular hacking capability")
	TEST_ASSERT_EQUAL(built.size, SSnetrun.get_bot_program(NETRUN_BOT_SENTINEL).file_size + tool.size + assist.size, "Module files consume real package storage")
	TEST_ASSERT_EQUAL(length(built.stored_files), 2, "The package owns the selected executable tools")
	var/datum/netrun_file/copied_tool = built.stored_files[1]
	TEST_ASSERT(copied_tool != tool && copied_tool.kind == NETRUN_FILE_DAEMON && copied_tool.content == "autobreach", "The module is an independent ordinary daemon copy")
	TEST_ASSERT(owner.console.launch_bot_file(built.uid), "The package launches through the existing restoration path")
	var/list/agents = owner.console.agents()
	var/mob/camera/netrun_entity/bot/agent = agents[1]
	TEST_ASSERT_NOTNULL(agent.entity_modules["hacking"], "Restoring real files installs the same capability on another profile")
	TEST_ASSERT_EQUAL(agent.console.daemon_bonus("icepick"), 1, "Passive module effects use the native loadout rules")
	var/datum/netrun_file/foreign = allocate(/datum/netrun_file, "foreign.exe", NETRUN_FILE_DAEMON, "autobreach", 3)
	TEST_ASSERT_NULL(owner.console.create_agent_file(list("uid" = template.uid, "module_uids" = list(foreign.uid)), owner), "Foreign UIDs cannot inject a capability")
	TEST_ASSERT_NULL(owner.console.create_agent_file(list("uid" = template.uid, "module_uids" = list(tool.uid, tool.uid)), owner), "Duplicate module selections fail atomically")
	var/datum/netrun_file/unlisted = netrun_daemon_file("skeleton")
	TEST_ASSERT(owner.console.store_file(unlisted), "An unrelated executable can still be a normal owned file")
	TEST_ASSERT_NULL(owner.console.create_agent_file(list("uid" = template.uid, "module_uids" = list(unlisted.uid)), owner), "Owned data cannot name an unpublished agent capability")
