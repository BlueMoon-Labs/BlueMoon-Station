/// Observe repeat admission without opening a UI, sending packets or advancing real timers.
/datum/netrun_scheduler_reuse_subject
	var/repeats = 256
	var/repeat_priority = NETRUN_TASK_NORMAL
	var/repeat_interactive = FALSE
	var/cancel_during_run = FALSE
	var/delete_during_run = FALSE
	var/list/observations = list("calls" = 0, "tasks" = list(), "priorities" = list())

/datum/netrun_task/scheduler_reuse_probe
	kind = "scheduler_reuse_probe"

/datum/netrun_task/scheduler_reuse_probe/execute(datum/controller/subsystem/netrun/worker, datum/netrun_execution_limits/limits)
	var/datum/netrun_scheduler_reuse_subject/subject = target()
	var/list/observations = subject.observations
	var/list/tasks = observations["tasks"]
	var/list/priorities = observations["priorities"]
	tasks += src
	priorities += priority
	observations["calls"]++
	if(observations["calls"] != 1)
		return TRUE
	var/datum/netrun_task_scheduler/scheduler = worker.get_task_scheduler()
	for(var/repeat in 1 to subject.repeats)
		scheduler.enqueue(kind, subject, subject.repeat_priority, subject.repeat_interactive)
	observations["pending_during_run"] = scheduler.pending()
	observations["running_task"] = scheduler.running_by_key[key]
	observations["priority_after_repeat"] = priority
	observations["interactive_after_repeat"] = interactive
	observations["ready_during_run"] = scheduler.ready_deliveries
	if(subject.cancel_during_run)
		observations["cancelled"] = scheduler.cancel(kind, subject)
		observations["deleted_by_cancel"] = QDELETED(src)
	if(subject.delete_during_run)
		qdel(subject)
	return TRUE

/datum/netrun_task/scheduler_reuse_delivery_probe
	parent_type = /datum/netrun_task/scheduler_reuse_probe
	kind = "scheduler_reuse_delivery_probe"
	delivery = TRUE

/datum/unit_test/proc/netrun_scheduler_reuse_worker()
	var/datum/controller/subsystem/netrun/netrun_execution_test/worker = allocate(/datum/controller/subsystem/netrun/netrun_execution_test)
	worker.task_adaptive_budget = FALSE
	worker.task_budget_ms = NETRUN_EXECUTION_MAX_BUDGET_MS
	worker.task_max_per_pass = 1
	worker.next_task_population = INFINITY
	return worker

/// A waiting storm refreshes one retained task without disguising its age or moving its FIFO slot.
/datum/unit_test/netrun_scheduler_reuse_waiting_storm/Run()
	var/datum/netrun_task_scheduler/scheduler = netrun_scheduler_fixture()
	var/datum/first = allocate(/datum)
	var/datum/second = allocate(/datum)
	scheduler.enqueue("probe", first, NETRUN_TASK_BACKGROUND)
	scheduler.enqueue("probe", second, NETRUN_TASK_BACKGROUND)
	var/key = "probe:[REF(first)]"
	var/datum/netrun_task/original = scheduler.by_key[key]
	var/first_requested = world.time - 30 SECONDS
	original.enqueued_at = first_requested
	original.last_requested_at = first_requested
	for(var/repeat in 1 to 256)
		scheduler.enqueue("probe", first, NETRUN_TASK_BACKGROUND)
	TEST_ASSERT_EQUAL(scheduler.pending(), 2, "A repeated producer cannot multiply its pending task")
	TEST_ASSERT_EQUAL(scheduler.counts[NETRUN_TASK_BACKGROUND], 2, "Repeat admission must not inflate queue accounting")
	TEST_ASSERT_EQUAL(scheduler.by_key[key], original, "The pending task must retain its identity across every repeat")
	TEST_ASSERT_EQUAL(original.last_requested_at, world.time, "The retained task records the latest request instead of allocating a replacement")
	TEST_ASSERT_EQUAL(original.enqueued_at, first_requested, "Refreshing work must not hide its original waiting time")
	var/datum/netrun_task/task = scheduler.take()
	TEST_ASSERT_EQUAL(task, original, "Repeated work must retain its original FIFO position")
	qdel(task)
	task = scheduler.take()
	TEST_ASSERT_EQUAL(task.target(), second, "An unrelated waiting task must remain reachable after the refreshed task")
	qdel(task)
	TEST_ASSERT_EQUAL(scheduler.pending(), 0, "The finite waiting queue must drain")
	TEST_ASSERT_EQUAL(length(scheduler.running_by_key), 0, "Manual disposal after take must release running ownership")

/// An event storm inside execute reuses the running object for exactly one subsequent dispatch.
/datum/unit_test/netrun_scheduler_reuse_running_storm/Run()
	var/datum/controller/subsystem/netrun/netrun_execution_test/worker = netrun_scheduler_reuse_worker()
	var/datum/netrun_scheduler_reuse_subject/subject = allocate(/datum/netrun_scheduler_reuse_subject)
	var/datum/netrun_task_scheduler/scheduler = worker.get_task_scheduler()
	scheduler.enqueue("scheduler_reuse_probe", subject, NETRUN_TASK_NORMAL)
	var/key = "scheduler_reuse_probe:[REF(subject)]"
	var/datum/netrun_task/original = scheduler.by_key[key]
	original.enqueued_at = world.time - 8 SECONDS
	worker.run_pass()
	TEST_ASSERT_EQUAL(subject.observations["calls"], 1, "A bounded pass executes one slice despite a repeat storm")
	TEST_ASSERT_EQUAL(subject.observations["pending_during_run"], 0, "A running repeat must not allocate a second pending task")
	TEST_ASSERT_EQUAL(subject.observations["running_task"], original, "The running key must retain the original task throughout execution")
	TEST_ASSERT_EQUAL(scheduler.by_key[key], original, "The same object becomes the sole follow-up when execution finishes")
	TEST_ASSERT(!QDELETED(original), "A refreshed running task must survive until its next dispatch")
	TEST_ASSERT_EQUAL(scheduler.pending(), 1, "Any number of running repeats requires only one follow-up")
	TEST_ASSERT_EQUAL(scheduler.counts[NETRUN_TASK_NORMAL], 1, "The retained follow-up must be counted once")
	TEST_ASSERT_EQUAL(length(scheduler.running_by_key), 0, "A finished slice must leave no running entry")
	var/datum/netrun_task_profile/profile = scheduler.profiles["scheduler_reuse_probe"]
	TEST_ASSERT_EQUAL(profile.peak_wait_ds, 8 SECONDS, "Refreshing during execution must not erase the first dispatch's waiting time")
	worker.run_pass()
	var/list/tasks = subject.observations["tasks"]
	TEST_ASSERT_EQUAL(subject.observations["calls"], 2, "The storm must become exactly one later execution")
	TEST_ASSERT_EQUAL(tasks[1], tasks[2], "Both dispatches must reuse the same task object")
	TEST_ASSERT(QDELETED(original), "The retained object must be disposed when no new work arrives")
	TEST_ASSERT_EQUAL(scheduler.completed, 2, "Each actual dispatch must produce one execution sample")
	TEST_ASSERT_EQUAL(scheduler.pending(), 0, "The drained producer must leave no queued work")
	TEST_ASSERT_EQUAL(scheduler.counts[NETRUN_TASK_NORMAL], 0, "Draining must release all priority capacity")
	TEST_ASSERT_EQUAL(length(scheduler.running_by_key), 0, "Draining must release running ownership")

/// Priority/interaction arriving mid-execution belongs to the next run, preserving current accounting.
/datum/unit_test/netrun_scheduler_reuse_running_promotion/Run()
	var/datum/controller/subsystem/netrun/netrun_execution_test/worker = netrun_scheduler_reuse_worker()
	var/datum/netrun_scheduler_reuse_subject/subject = allocate(/datum/netrun_scheduler_reuse_subject)
	subject.repeat_priority = NETRUN_TASK_CRITICAL
	subject.repeat_interactive = TRUE
	var/datum/netrun_task_scheduler/scheduler = worker.get_task_scheduler()
	scheduler.enqueue("scheduler_reuse_probe", subject, NETRUN_TASK_BACKGROUND)
	var/key = "scheduler_reuse_probe:[REF(subject)]"
	var/datum/netrun_task/original = scheduler.by_key[key]
	worker.run_pass()
	TEST_ASSERT_EQUAL(subject.observations["priority_after_repeat"], NETRUN_TASK_BACKGROUND, "Running admission cannot rewrite the executing slice's priority")
	TEST_ASSERT(!subject.observations["interactive_after_repeat"], "An event cannot retroactively make the running slice interactive")
	TEST_ASSERT_EQUAL(scheduler.executed_by_priority[NETRUN_TASK_BACKGROUND], 1, "The first dispatch retains its actual background accounting")
	TEST_ASSERT_EQUAL(scheduler.executed_by_priority[NETRUN_TASK_CRITICAL], 0, "Promotion cannot count a critical execution before it happens")
	TEST_ASSERT_EQUAL(scheduler.by_key[key], original, "Promotion must retain the running object's identity")
	TEST_ASSERT_EQUAL(original.priority, NETRUN_TASK_CRITICAL, "The follow-up must receive the strongest requested priority")
	TEST_ASSERT(original.interactive && scheduler.interactive_queue.first == original, "The follow-up must enter the interactive queue")
	TEST_ASSERT_EQUAL(scheduler.counts[NETRUN_TASK_BACKGROUND], 0, "Promotion must not retain old queue capacity")
	TEST_ASSERT_EQUAL(scheduler.counts[NETRUN_TASK_CRITICAL], 1, "Interactive promotion must count one follow-up")
	worker.run_pass()
	TEST_ASSERT_EQUAL(subject.observations["calls"], 2, "The promoted follow-up executes once")
	TEST_ASSERT_EQUAL(scheduler.executed_by_priority[NETRUN_TASK_CRITICAL], 1, "Only the actual follow-up is recorded as critical")
	TEST_ASSERT_EQUAL(scheduler.pending(), 0, "The promoted follow-up must drain normally")

/// Cancellation while on the stack clears the follow-up without destroying the active object early.
/datum/unit_test/netrun_scheduler_reuse_cancel_running/Run()
	var/datum/controller/subsystem/netrun/netrun_execution_test/worker = netrun_scheduler_reuse_worker()
	var/datum/netrun_scheduler_reuse_subject/subject = allocate(/datum/netrun_scheduler_reuse_subject)
	subject.cancel_during_run = TRUE
	var/datum/netrun_task_scheduler/scheduler = worker.get_task_scheduler()
	scheduler.enqueue("scheduler_reuse_probe", subject)
	var/datum/netrun_task/original = scheduler.by_key["scheduler_reuse_probe:[REF(subject)]"]
	worker.run_pass()
	TEST_ASSERT(subject.observations["cancelled"], "Cancellation must find work even while it is executing")
	TEST_ASSERT(!subject.observations["deleted_by_cancel"], "Cancellation must not delete a task while its execute stack is live")
	TEST_ASSERT(QDELETED(original), "The cancelled task must be disposed when execution returns")
	TEST_ASSERT_EQUAL(scheduler.pending(), 0, "Cancellation must discard the merged follow-up")
	TEST_ASSERT_EQUAL(length(scheduler.running_by_key), 0, "Cancellation must leave no running entry after execution")
	worker.run_pass()
	TEST_ASSERT_EQUAL(subject.observations["calls"], 1, "Cancelled merged work must never replay")

/// Losing a weak target during execution suppresses the retained follow-up.
/datum/unit_test/netrun_scheduler_reuse_deleted_target/Run()
	var/datum/controller/subsystem/netrun/netrun_execution_test/worker = netrun_scheduler_reuse_worker()
	var/datum/netrun_scheduler_reuse_subject/subject = allocate(/datum/netrun_scheduler_reuse_subject)
	subject.delete_during_run = TRUE
	var/list/observations = subject.observations
	var/datum/netrun_task_scheduler/scheduler = worker.get_task_scheduler()
	scheduler.enqueue("scheduler_reuse_probe", subject)
	var/datum/netrun_task/original = scheduler.by_key["scheduler_reuse_probe:[REF(subject)]"]
	worker.run_pass()
	TEST_ASSERT(QDELETED(subject) && QDELETED(original), "A lost weak target must not retain a reusable task")
	TEST_ASSERT_EQUAL(scheduler.pending(), 0, "A deleted target cannot receive its merged follow-up")
	TEST_ASSERT_EQUAL(length(scheduler.running_by_key), 0, "Target removal must release running ownership")
	worker.run_pass()
	TEST_ASSERT_EQUAL(observations["calls"], 1, "A deleted target must never be executed a second time")

/// Reused delivery work holds one ready slot, and direct task disposal releases every index.
/datum/unit_test/netrun_scheduler_reuse_delivery_accounting/Run()
	var/datum/controller/subsystem/netrun/netrun_execution_test/worker = netrun_scheduler_reuse_worker()
	var/datum/netrun_scheduler_reuse_subject/subject = allocate(/datum/netrun_scheduler_reuse_subject)
	var/datum/netrun_task_scheduler/scheduler = worker.get_task_scheduler()
	scheduler.enqueue("scheduler_reuse_delivery_probe", subject)
	var/key = "scheduler_reuse_delivery_probe:[REF(subject)]"
	var/datum/netrun_task/original = scheduler.by_key[key]
	TEST_ASSERT_EQUAL(scheduler.ready_deliveries, 1, "Initial delivery admission must hold one ready slot")
	worker.run_pass()
	TEST_ASSERT_EQUAL(subject.observations["ready_during_run"], 0, "Running repeats must not multiply ready delivery capacity")
	TEST_ASSERT_EQUAL(scheduler.ready_deliveries, 1, "The retained follow-up must acquire exactly one ready slot")
	TEST_ASSERT_EQUAL(scheduler.by_key[key], original, "Delivery work must also reuse its original task object")
	worker.run_pass()
	TEST_ASSERT_EQUAL(scheduler.ready_deliveries, 0, "Completed delivery work must release its ready slot")
	scheduler.enqueue("scheduler_reuse_delivery_probe", subject)
	var/datum/netrun_task/disposed = scheduler.by_key[key]
	qdel(disposed)
	TEST_ASSERT_NULL(scheduler.by_key[key], "External disposal must remove the task's admission index immediately")
	TEST_ASSERT_EQUAL(scheduler.pending(), 0, "External disposal must release pending capacity")
	TEST_ASSERT_EQUAL(scheduler.ready_deliveries, 0, "External disposal must release ready delivery capacity")
	TEST_ASSERT_EQUAL(scheduler.counts[NETRUN_TASK_NORMAL], 0, "External disposal must release priority capacity")
	TEST_ASSERT_NULL(scheduler.take(), "No dead queue link may remain after direct disposal")
	TEST_ASSERT(scheduler.enqueue("scheduler_reuse_delivery_probe", subject), "Direct disposal must permit later fresh admission for the same key")
	var/datum/netrun_task/replacement = scheduler.take()
	TEST_ASSERT(replacement != disposed, "A disposed task cannot be reused for fresh work")
	qdel(replacement)
	TEST_ASSERT_EQUAL(length(scheduler.running_by_key), 0, "Disposing a manually taken delivery must release its running key")
	TEST_ASSERT_EQUAL(scheduler.ready_deliveries, 0, "Manual take and disposal must not leave ready capacity")

/// Scheduler teardown detaches an in-flight stack and prevents later completion resurrecting it.
/datum/unit_test/netrun_scheduler_reuse_scheduler_teardown/Run()
	var/datum/netrun_task_scheduler/scheduler = netrun_scheduler_fixture()
	var/datum/subject = allocate(/datum)
	scheduler.enqueue("probe", subject)
	var/datum/netrun_task/task = scheduler.take()
	scheduler.enqueue("probe", subject)
	TEST_ASSERT(task.rerun_requested, "The in-flight task must first own a requested follow-up")
	qdel(scheduler)
	TEST_ASSERT(!QDELETED(task), "Scheduler teardown cannot delete an in-flight execution stack")
	TEST_ASSERT_NULL(task.scheduler, "The in-flight task must not retain its deleted scheduler")
	TEST_ASSERT(!task.rerun_requested, "Teardown must discard the retained follow-up")
	scheduler.finish(task)
	TEST_ASSERT(QDELETED(task), "Detached completion must dispose its original task")
	TEST_ASSERT_EQUAL(scheduler.pending(), 0, "Detached completion cannot recreate a queue on the deleted scheduler")
	TEST_ASSERT_EQUAL(length(scheduler.running_by_key), 0, "Teardown must release every running index")

/// A deletion callback may request fresh work before the old task unlinks itself.
/datum/unit_test/netrun_scheduler_reuse_reentrant_disposal
	var/datum/netrun_task_scheduler/test_scheduler
	var/datum/test_subject

/datum/unit_test/netrun_scheduler_reuse_reentrant_disposal/proc/request_replacement()
	SIGNAL_HANDLER
	test_scheduler.enqueue("scheduler_reuse_delivery_probe", test_subject)

/datum/unit_test/netrun_scheduler_reuse_reentrant_disposal/Run()
	test_scheduler = netrun_scheduler_fixture()
	test_subject = allocate(/datum/netrun_scheduler_reuse_subject)
	test_scheduler.enqueue("scheduler_reuse_delivery_probe", test_subject)
	var/key = "scheduler_reuse_delivery_probe:[REF(test_subject)]"
	var/datum/netrun_task/original = test_scheduler.by_key[key]
	RegisterSignal(original, COMSIG_PARENT_QDELETING, PROC_REF(request_replacement))
	qdel(original)
	var/datum/netrun_task/replacement = test_scheduler.by_key[key]
	TEST_ASSERT(replacement && replacement != original, "A deletion callback may admit a fresh task for the same key")
	TEST_ASSERT_EQUAL(test_scheduler.pending(), 1, "Disposing the old task must preserve the replacement's index")
	TEST_ASSERT_EQUAL(test_scheduler.counts[NETRUN_TASK_NORMAL], 1, "The old queue link must release its own count even after key replacement")
	TEST_ASSERT_EQUAL(test_scheduler.ready_deliveries, 1, "Only the replacement may retain ready delivery capacity")
	TEST_ASSERT_EQUAL(test_scheduler.take(), replacement, "The old deletion must leave the replacement's FIFO link intact")
	qdel(replacement)
	TEST_ASSERT_EQUAL(test_scheduler.counts[NETRUN_TASK_NORMAL], 0, "The replacement must drain without orphaned queue accounting")
	TEST_ASSERT_EQUAL(test_scheduler.ready_deliveries, 0, "The replacement must drain without orphaned delivery accounting")

/// Reobserving pending state is not a new event or a reason to touch its FIFO entry.
/datum/unit_test/netrun_scheduler_ensure_pending_state/Run()
	var/datum/netrun_task_scheduler/scheduler = netrun_scheduler_fixture()
	var/datum/subject = allocate(/datum)
	TEST_ASSERT(scheduler.ensure_queued("probe", subject, NETRUN_TASK_BACKGROUND), "The first state observation must admit work")
	var/key = "probe:[REF(subject)]"
	var/datum/netrun_task/original = scheduler.by_key[key]
	var/datum/netrun_task_profile/profile = scheduler.profiles["probe"]
	original.enqueued_at = world.time - 8 SECONDS
	original.last_requested_at = original.enqueued_at
	for(var/repeat in 1 to 256)
		scheduler.ensure_queued("probe", subject, NETRUN_TASK_BACKGROUND)
	TEST_ASSERT_EQUAL(profile.requests, 1, "Repeated population must not manufacture producer requests")
	TEST_ASSERT_EQUAL(profile.merged, 0, "An unchanged pending state must not enter the event coalescing path")
	TEST_ASSERT_EQUAL(scheduler.by_key[key], original, "Passive population must retain the pending object")
	TEST_ASSERT_EQUAL(original.last_requested_at, original.enqueued_at, "Passive population must not refresh the last real request")
	scheduler.ensure_queued("probe", subject, NETRUN_TASK_NORMAL, TRUE)
	TEST_ASSERT(original.interactive && original.priority == NETRUN_TASK_NORMAL, "New urgency must still promote existing state work")
	TEST_ASSERT_EQUAL(original.enqueued_at, world.time - 8 SECONDS, "Promotion must retain the oldest waiting clock")
	TEST_ASSERT_EQUAL(profile.requests, 2, "A real priority change must pass through normal admission")
	TEST_ASSERT_EQUAL(scheduler.pending(), 1, "Repeated state and promotion must own one queue entry")
	TEST_ASSERT(scheduler.cancel("probe", subject), "Cancellation must find state admitted through ensure_queued")
	TEST_ASSERT(scheduler.ensure_queued("probe", subject), "Cancellation must permit later state to be admitted afresh")
	TEST_ASSERT_EQUAL(profile.created, 2, "Only cancellation and fresh demand may allocate a replacement")

/// A producer changing state during execution still requires one retained follow-up.
/datum/unit_test/netrun_scheduler_ensure_running_state/Run()
	var/datum/netrun_task_scheduler/scheduler = netrun_scheduler_fixture()
	var/datum/subject = allocate(/datum)
	scheduler.ensure_queued("probe", subject)
	var/datum/netrun_task/original = scheduler.take()
	for(var/repeat in 1 to 64)
		scheduler.ensure_queued("probe", subject)
	TEST_ASSERT(original.rerun_requested, "Changes after dispatch must not disappear behind a pending-only fast path")
	TEST_ASSERT_EQUAL(scheduler.pending(), 0, "The executing state owns its follow-up without a second task")
	TEST_ASSERT(scheduler.finish(original), "The running state must retain its requested next reconciliation")
	TEST_ASSERT_EQUAL(scheduler.take(), original, "The follow-up must reuse the original task")
	scheduler.finish(original)
	TEST_ASSERT_EQUAL(scheduler.pending(), 0, "The producer must drain once no further state arrives")
