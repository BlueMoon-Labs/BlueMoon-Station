/datum/netrun_console/netrun_interaction_test
	var/pushes = 0
	var/actions = 0

/datum/netrun_console/netrun_interaction_test/push_ui_update()
	pushes++
	// A nested signal/update must not re-enter serialization while this push owns it.
	ui_dirty = TRUE
	flush_ui(TRUE)

/datum/netrun_console/netrun_interaction_test/handle_ui_action(action, list/params, datum/tgui/ui)
	actions++
	return FALSE

/datum/unit_test/netrun_interaction_flush_and_receipt/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/netrun_console/netrun_interaction_test/console = allocate(/datum/netrun_console/netrun_interaction_test, host)
	var/mob/living/user = allocate(/mob/living)
	var/datum/tgui/ui = allocate(/datum/tgui, user, console, "NetrunTerminal")
	ui.status = UI_INTERACTIVE
	console.note_ui_activity()
	console.flush_ui()
	TEST_ASSERT_EQUAL(console.pushes, 0, "Periodic polling must retain background refresh coalescing")
	console.ui_act("denied_domain_action", list("_netrun_action" = "receipt-1"), ui)
	TEST_ASSERT_EQUAL(console.input_ack, "receipt-1", "A processed domain denial still acknowledges server receipt")
	TEST_ASSERT_EQUAL(console.actions, 1, "The admitted action must dispatch exactly once")
	TEST_ASSERT_EQUAL(console.pushes, 1, "Input must flush immediately, without waiting one second or re-entering a nested flush")
	var/list/payload = console.ui_data(null)
	TEST_ASSERT_EQUAL(payload["input_ack"], "receipt-1", "The normal serialized response must carry the input correlation token")
	console.ui_act("denied_domain_action", list("_netrun_action" = list("forged")), ui)
	TEST_ASSERT_EQUAL(console.input_ack, "receipt-1", "A list payload cannot be echoed as a receipt token")
	console.ui_act("denied_domain_action", list("_netrun_action" = repeat_string(NETRUN_INPUT_ACK_MAX_LENGTH + 1, "x")), ui)
	TEST_ASSERT_EQUAL(console.input_ack, "receipt-1", "An oversized nonce cannot grow the server response")
	ui.status = UI_CLOSE
	console.ui_act("denied_domain_action", list("_netrun_action" = "forged-ui"), ui)
	TEST_ASSERT_EQUAL(console.actions, 3, "An inadmissible UI must never reach domain dispatch")
	TEST_ASSERT_EQUAL(console.input_ack, "receipt-1", "Receipt metadata must not bypass native UI admission")
	TEST_ASSERT_EQUAL(length(console.access_session.node_access), 0, "Acknowledgement must grant no node privileges")
	console.ui_serializing = TRUE
	var/before = console.pushes
	console.flush_ui(TRUE)
	TEST_ASSERT_EQUAL(console.pushes, before, "Explicit input must retain the serialization reentrancy guard")
	console.ui_serializing = FALSE

/datum/unit_test/netrun_interaction_poll_vs_intent/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/netrun_console/console = allocate(/datum/netrun_console, host)
	var/datum/netrun_task_scheduler/scheduler = SSnetrun.get_task_scheduler()
	var/key = "console:[REF(console)]"
	scheduler.cancel("console", console)
	console.note_ui_activity()
	TEST_ASSERT_NULL(scheduler.by_key[key], "A periodic UI poll must not promote itself into the input lane")
	console.note_user_action()
	var/datum/netrun_task/task = scheduler.by_key[key]
	TEST_ASSERT_NOTNULL(task, "Explicit input must queue processing before the next population pass")
	TEST_ASSERT(task.interactive && task.priority == NETRUN_TASK_CRITICAL, "Explicit input must own the highest-priority task lane")
	console.note_user_action()
	TEST_ASSERT_EQUAL(scheduler.by_key[key], task, "Repeated input before processing must coalesce")

/datum/unit_test/netrun_ice_reactive_wake/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/component/netrun_node/node = host.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
	var/datum/netrun_ice/ice = allocate(/datum/netrun_ice, node)
	var/datum/netrun_task_scheduler/scheduler = SSnetrun.get_task_scheduler()
	var/key = "ice:[REF(ice)]"
	TEST_ASSERT_NULL(scheduler.by_key[key], "An idle patrol must not enter the interactive lane on creation")
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity)
	entity.enter_node(node)
	var/datum/netrun_task/task = scheduler.by_key[key]
	TEST_ASSERT_NOTNULL(task, "Player arrival must wake local ICE without waiting for population")
	TEST_ASSERT(task.interactive && task.priority == NETRUN_TASK_CRITICAL, "The local world reaction must preempt background work")
	var/start_integrity = entity.integrity
	ice.reaction.wake()
	TEST_ASSERT_EQUAL(scheduler.by_key[key], task, "Repeated local events must coalesce one ICE task")
	scheduler.cancel("ice", ice)
	var/datum/netrun_task/ice/run = allocate(/datum/netrun_task/ice, "ice", key, NETRUN_TASK_CRITICAL, ice)
	run.execute(SSnetrun)
	TEST_ASSERT_NOTNULL(ice.pending_program, "The first reactive pass must announce the hostile program")
	TEST_ASSERT(ice.attack_at >= world.time + NETRUN_ICE_MIN_TELEGRAPH, "The first reactive attack retains its full escape window")
	var/deadline = ice.attack_at
	var/cooldown = ice.program_cd[ice.pending_program.id]
	run.execute(SSnetrun)
	TEST_ASSERT_EQUAL(ice.attack_at, deadline, "An extra same-tick wake must not restart or accelerate the cast")
	TEST_ASSERT_EQUAL(ice.program_cd[ice.pending_program.id], cooldown, "An extra wake must not change program cooldown")
	TEST_ASSERT_EQUAL(entity.integrity, start_integrity, "Repeated wakes before the deadline must not deal duplicate damage")
	TEST_ASSERT_NOTNULL(ice.reaction.timer_id, "An active cast must own a deadline wake independent of population")
	ice.apply_stun(2 SECONDS)
	TEST_ASSERT_NULL(ice.pending_program, "A player stun must interrupt the active cast immediately")
	TEST_ASSERT_NULL(ice.reaction.timer_id, "Interrupting a cast must cancel its stale deadline")

/// A new breach is immediately visible to reactive sentries, without charging pre-breach time.
/datum/unit_test/netrun_breach_reactive_trace_clock/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/component/netrun_node/node = host.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity)
	entity.enter_node(node)
	var/datum/netrun_console/console = entity.console
	var/datum/netrun_ice/ice = allocate(/datum/netrun_ice, node)
	var/datum/netrun_task_scheduler/scheduler = SSnetrun.get_task_scheduler()
	scheduler.cancel("ice", ice)
	TEST_ASSERT(console.start_breach("node", node.address), "A reachable local breach must start through real gameplay validation")
	TEST_ASSERT(console in SSnetrun.currentbreaches, "Reactive trace targeting must see the breach before the next registry population")
	var/datum/netrun_task/wake = scheduler.by_key["ice:[REF(ice)]"]
	TEST_ASSERT(wake?.interactive, "Beginning a player breach must immediately wake the guarded node")
	console.last_netrun_tick = world.time - 10 SECONDS
	var/datum/netrun_task/console/run = allocate(/datum/netrun_task/console, "console", "trace-clock", NETRUN_TASK_CRITICAL, console)
	var/initial_trace = console.intrusion.trace
	run.execute(SSnetrun)
	TEST_ASSERT_EQUAL(console.intrusion.trace, initial_trace, "Waking a just-started breach must not charge the previous session interval")
	console.last_netrun_tick = world.time - 2 SECONDS
	console.intrusion.last_breach_tick = world.time - 2 SECONDS
	run.execute(SSnetrun)
	var/charged_trace = console.intrusion.trace
	TEST_ASSERT(charged_trace > initial_trace, "A real elapsed breach interval must still produce trace")
	run.execute(SSnetrun)
	TEST_ASSERT_EQUAL(console.intrusion.trace, charged_trace, "A repeated same-tick input wake cannot charge breach trace twice")
