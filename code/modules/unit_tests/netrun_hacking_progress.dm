/// Signal waits retain one cancellation-safe deadline, without polling the puzzle.
/datum/unit_test/netrun_hacking_wait_deadline/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/datum/netrun_console/master = allocate(/datum/netrun_console, allocate(/obj/item))
	var/mob/camera/netrun_entity/bot/agent = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, "hacker", master)
	var/datum/netrun_bot_brain/brain = agent.brain
	brain.clear_goals()
	var/datum/netrun_bot_goal/hack/goal = new(brain, scene.node_b)
	brain.push_goal(goal)
	TEST_ASSERT_EQUAL(goal.advance(), NETRUN_BOT_GOAL_CONTINUE, "The ordinary first frontier starts a real puzzle")
	TEST_ASSERT(goal.waits_for_signal(), "The live puzzle waits for its completion fact")
	var/deadline_timer = brain.goal_wait_timer_id
	TEST_ASSERT_NOTNULL(deadline_timer, "A signal-waiting goal owns one finite deadline")
	TEST_ASSERT(abs(timeleft(deadline_timer) - (goal.expires_at - world.time)) < 1, "The wake is scheduled at the goal deadline, not a busy polling interval")
	brain.clear_timer()
	brain.schedule_next()
	brain.schedule_next()
	TEST_ASSERT_EQUAL(brain.goal_wait_timer_id, deadline_timer, "Repeated scheduling retains the same one-shot wait deadline")
	TEST_ASSERT_NULL(brain.timer_id, "Waiting does not create an ordinary think polling timer")
	brain.schedule(0.5 SECONDS)
	TEST_ASSERT(brain.timer_id && brain.goal_wait_timer_id == deadline_timer, "Combat pacing can coexist with the independent wait deadline")
	brain.clear_goals()
	TEST_ASSERT_NULL(brain.goal_wait_timer_id, "Replacing the goal cancels its one-shot deadline")
	TEST_ASSERT_NULL(agent.console.intrusion.breach, "Goal replacement cancels its owned puzzle too")
	TEST_ASSERT(!brain.is_blacklisted(scene.node_b.address), "A deliberate cancellation does not mark the target as a failed frontier")

/// A timer only admits work; the normal budgeted bot task expires and replans.
/datum/unit_test/netrun_hacking_stalled_goal_timeout/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/datum/netrun_console/master = allocate(/datum/netrun_console, allocate(/obj/item))
	var/mob/camera/netrun_entity/bot/agent = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, "hacker", master)
	var/datum/netrun_bot_brain/brain = agent.brain
	brain.clear_goals()
	brain.order = "guard"
	var/datum/netrun_bot_goal/hack/goal = new(brain, scene.node_b)
	brain.push_goal(goal)
	TEST_ASSERT_EQUAL(goal.advance(), NETRUN_BOT_GOAL_CONTINUE, "The agent starts its native pending work")
	var/datum/netrun_breach/breach = agent.console.intrusion.breach
	TEST_ASSERT_NOTNULL(breach, "The stalled goal owns an actual unfinished puzzle")
	goal.expires_at = world.time
	brain.schedule_goal_wait(goal)
	var/datum/weakref/waiting = brain.waiting_goal_ref
	var/deadline = brain.goal_wait_deadline
	SSnetrun.get_task_scheduler().cancel("bot", brain)
	brain.on_goal_wait_timeout(waiting, deadline)
	TEST_ASSERT(!QDELETED(goal) && !QDELETED(breach), "The deadline callback cannot execute cancellation inline")
	TEST_ASSERT(SSnetrun.task_scheduler.by_key["bot:[REF(brain)]"], "The deadline admits the normal bot task")
	SSnetrun.task_scheduler.cancel("bot", brain)
	var/datum/controller/subsystem/netrun/netrun_execution_test/worker = allocate(/datum/controller/subsystem/netrun/netrun_execution_test)
	worker.next_task_population = INFINITY
	worker.get_task_scheduler().enqueue("bot", brain, NETRUN_TASK_NORMAL)
	worker.run_pass()
	TEST_ASSERT(QDELETED(goal) && QDELETED(breach), "Budgeted brain work expires the old goal and releases its puzzle")
	TEST_ASSERT_NULL(brain.goal_wait_timer_id, "No expired wait deadline survives replanning")
	TEST_ASSERT_NULL(agent.console.intrusion.breach, "Stalled work cannot finish after cancellation")
	TEST_ASSERT(istype(brain.current_goal(), /datum/netrun_bot_goal/guard), "The same worker step can resume the agent's ordinary standing policy")
	TEST_ASSERT(agent.console.node_level(scene.apc_node) < NETRUN_ACCESS_USER, "Expiring a wait does not fabricate frontier authority")

/// A cancelled deadline cannot wake or cancel a replacement goal's pending work.
/datum/unit_test/netrun_hacking_wait_replacement/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/datum/netrun_console/master = allocate(/datum/netrun_console, allocate(/obj/item))
	var/mob/camera/netrun_entity/bot/agent = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, "hacker", master)
	var/datum/netrun_bot_brain/brain = agent.brain
	brain.clear_goals()
	var/datum/netrun_bot_goal/hack/old_goal = new(brain, scene.node_b)
	brain.push_goal(old_goal)
	TEST_ASSERT_EQUAL(old_goal.advance(), NETRUN_BOT_GOAL_CONTINUE, "The original wait starts")
	var/datum/weakref/old_wait = brain.waiting_goal_ref
	var/old_deadline = brain.goal_wait_deadline
	brain.clear_goals()
	var/datum/netrun_bot_goal/hack/replacement = new(brain, scene.node_b)
	brain.push_goal(replacement)
	TEST_ASSERT_EQUAL(replacement.advance(), NETRUN_BOT_GOAL_CONTINUE, "A fresh goal can own an independent puzzle")
	var/new_timer = brain.goal_wait_timer_id
	var/datum/netrun_breach/new_breach = agent.console.intrusion.breach
	SSnetrun.get_task_scheduler().cancel("bot", brain)
	brain.on_goal_wait_timeout(old_wait, old_deadline)
	TEST_ASSERT_EQUAL(brain.goal_wait_timer_id, new_timer, "The stale callback cannot consume the replacement's deadline")
	TEST_ASSERT(!SSnetrun.task_scheduler.by_key["bot:[REF(brain)]"], "A cancelled wait cannot enqueue a new brain step")
	TEST_ASSERT(replacement.waiting && !QDELETED(new_breach), "The replacement keeps its own live native work")
	qdel(new_breach)
	TEST_ASSERT(!replacement.waiting && !brain.goal_wait_timer_id, "Ordinary completion/cancellation facts release the wait deadline")

/// Native admission failure backs off both the failed frontier and its destination.
/datum/unit_test/netrun_hacking_frontier_backoff/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/datum/netrun_console/master = allocate(/datum/netrun_console, allocate(/obj/item))
	var/mob/camera/netrun_entity/bot/agent = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, "hacker", master)
	var/datum/netrun_bot_brain/brain = agent.brain
	var/datum/netrun_entity_module/hacking/module = agent.entity_modules["hacking"]
	brain.clear_goals()
	var/datum/netrun_file_store/store = agent.console.inventory.local_store
	var/capacity = store.capacity
	store.capacity = store.used()
	var/datum/netrun_bot_goal/hack/goal = new(brain, scene.node_b)
	brain.push_goal(goal)
	TEST_ASSERT(module.can_hack(), "The agent still owns its real hacking tool")
	TEST_ASSERT_EQUAL(goal.advance(), NETRUN_BOT_GOAL_FAILED, "Native admission rejects a puzzle when no acquired-rights file can fit")
	TEST_ASSERT_NULL(agent.console.intrusion.breach, "Denied admission creates no hidden puzzle")
	TEST_ASSERT(brain.is_blacklisted(scene.apc_node.address), "The physically failing first frontier receives bounded backoff")
	TEST_ASSERT(brain.is_blacklisted(scene.node_b.address), "The unreachable destination is not immediately selected again")
	module.candidates = list(scene.node_b.address)
	module.candidate_cursor = 1
	TEST_ASSERT_NULL(module.pick_target(brain), "Automatic planning skips its failed destination during backoff")
	store.capacity = capacity
	brain.blacklist[scene.apc_node.address] = world.time
	brain.blacklist[scene.node_b.address] = world.time
	module.candidates = list(scene.node_b.address)
	module.candidate_cursor = 1
	TEST_ASSERT_EQUAL(module.pick_target(brain), scene.node_b, "The ordinary destination becomes eligible after the finite backoff")
	brain.finish_goal(goal)
	goal = new(brain, scene.node_b)
	brain.push_goal(goal)
	TEST_ASSERT_EQUAL(goal.advance(), NETRUN_BOT_GOAL_CONTINUE, "A recovered endpoint may start a new ordinary attempt")
	TEST_ASSERT_NOTNULL(agent.console.intrusion.breach, "Retry still owns an actual delayed puzzle")
	TEST_ASSERT(agent.console.node_level(scene.apc_node) < NETRUN_ACCESS_USER, "Admission and retry never substitute for solving the frontier")

/// A puzzle that ends without the required grant cannot loop on the same frontier.
/datum/unit_test/netrun_hacking_failed_completion_backoff/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/datum/netrun_console/master = allocate(/datum/netrun_console, allocate(/obj/item))
	var/mob/camera/netrun_entity/bot/agent = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, "hacker", master)
	var/datum/netrun_bot_brain/brain = agent.brain
	brain.clear_goals()
	var/datum/netrun_bot_goal/hack/goal = new(brain, scene.node_b)
	brain.push_goal(goal)
	TEST_ASSERT_EQUAL(goal.advance(), NETRUN_BOT_GOAL_CONTINUE, "The first actual puzzle starts")
	var/datum/netrun_breach/breach = agent.console.intrusion.breach
	breach.finish()
	TEST_ASSERT(!goal.waiting && !brain.goal_wait_timer_id, "Native failure wakes the goal and clears its wait deadline")
	TEST_ASSERT_EQUAL(goal.advance(), NETRUN_BOT_GOAL_FAILED, "An ended puzzle without USER cannot count as a completed frontier")
	TEST_ASSERT(brain.is_blacklisted(scene.apc_node.address) && brain.is_blacklisted(scene.node_b.address), "The failed frontier and dependent destination both back off")
	TEST_ASSERT(agent.console.node_level(scene.apc_node) < NETRUN_ACCESS_USER, "Failure never awards implicit access")
	TEST_ASSERT_NULL(agent.console.intrusion.breach, "Reevaluating failure cannot silently start another copy")
