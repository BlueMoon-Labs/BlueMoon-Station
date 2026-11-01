/// Explicit intent is separate from periodic polling and background invalidation.
/datum/netrun_interaction
	var/datum/netrun_console/owner
	var/dispatching = FALSE

/datum/netrun_interaction/New(datum/netrun_console/owner)
	src.owner = owner

/datum/netrun_interaction/Destroy()
	owner = null
	return ..()

/datum/netrun_interaction/proc/wake()
	if(QDELETED(owner))
		return
	owner.note_ui_activity()
	SSnetrun.collect_console_node_interest(owner)
	owner.invalidate_ui()
	var/datum/netrun_execution_limits/limits = SSnetrun.get_execution_limits()
	SSnetrun.get_task_scheduler().enqueue("console", owner, limits.interactive_priority, TRUE)

/datum/netrun_interaction/proc/finish(datum/component/netrun_node/node)
	if(dispatching || QDELETED(owner))
		return
	dispatching = TRUE
	wake()
	if(!QDELETED(node))
		// Machine state reacts now; topology and packet latency keep their existing owners.
		node.reconcile_state()
		node.wake_defenses()
	owner.flush_ui(TRUE)
	dispatching = FALSE

/datum/netrun_console/proc/note_user_action()
	interaction?.wake()

/datum/netrun_console/proc/finish_user_action(datum/component/netrun_node/node)
	interaction?.finish(node)
