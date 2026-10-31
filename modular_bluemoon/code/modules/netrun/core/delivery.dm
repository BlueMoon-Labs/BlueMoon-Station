/// Shared asynchronous admission for user requests and machine packets. Domain
/// owners retain routing, authorization, outcomes and their in-flight registries.
/datum/netrun_delivery
	var/delivery_kind
	var/timer_id
	var/delivery_queued = FALSE
	var/ready_at

/datum/netrun_delivery/Destroy()
	cancel_delivery()
	return ..()

/datum/netrun_delivery/proc/can_queue_delivery()
	return TRUE

/datum/netrun_delivery/proc/delivery_priority()
	return NETRUN_TASK_NORMAL

/datum/netrun_delivery/proc/delivery_interactive()
	return FALSE

/datum/netrun_delivery/proc/schedule_delivery(delay = 0)
	if(QDELETED(src) || timer_id || delivery_queued || !can_queue_delivery())
		return FALSE
	if(delay <= 0)
		return queue_delivery()
	timer_id = addtimer(CALLBACK(src, PROC_REF(queue_delivery)), delay, TIMER_STOPPABLE | TIMER_DELETE_ME)
	return TRUE

/// A timer only admits work. Native handling always runs through the MC budget.
/datum/netrun_delivery/proc/queue_delivery()
	if(QDELETED(src))
		return FALSE
	if(timer_id)
		deltimer(timer_id)
		timer_id = null
	if(delivery_queued || !can_queue_delivery())
		return FALSE
	delivery_queued = TRUE
	ready_at = world.time
	SSnetrun.get_task_scheduler().enqueue(delivery_kind, src, delivery_priority(), delivery_interactive())
	SSnetrun.wake_ready_delivery()
	return TRUE

/// Direct early dispatch and destruction use the same timer/queue teardown.
/datum/netrun_delivery/proc/cancel_delivery()
	SSnetrun.task_scheduler?.cancel(delivery_kind, src)
	delivery_queued = FALSE
	if(timer_id)
		deltimer(timer_id)
		timer_id = null

/datum/netrun_delivery/proc/deliver()
	return FALSE
