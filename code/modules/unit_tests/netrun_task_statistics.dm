/// Reports may contain nested value lists, but never a scheduler, task, weakref or target.
/datum/unit_test/proc/netrun_statistics_values_only(value)
	if(!islist(value))
		return isnull(value) || istext(value) || isnum(value)
	var/list/values = value
	for(var/key in values)
		if(islist(key))
			if(!netrun_statistics_values_only(key))
				return FALSE
		else if(!istext(key) && !isnum(key) && !isnull(key))
			return FALSE
		else if(!isnum(key) && !netrun_statistics_values_only(values[key]))
			return FALSE
	return TRUE

/datum/unit_test/proc/netrun_statistics_kind(list/report, kind)
	for(var/list/entry as anything in report["types"])
		if(entry["kind"] == kind)
			return entry
	return null

/// Newly pending kinds are visible before execution, and reports cannot mutate live objects.
/datum/unit_test/netrun_task_statistics_values_and_pending/Run()
	var/datum/netrun_task_scheduler/scheduler = netrun_scheduler_fixture()
	var/list/empty = scheduler.statistics()
	TEST_ASSERT_EQUAL(empty["pending"], 0, "An empty report must have no pending work")
	TEST_ASSERT_EQUAL(empty["running"], 0, "An empty report must have no running work")
	TEST_ASSERT_EQUAL(length(empty["types"]), 0, "Reading an empty report must not create profiles")
	var/datum/subject = allocate(/datum)
	var/kind = "statistics-pending"
	scheduler.enqueue(kind, subject, NETRUN_TASK_BACKGROUND)
	scheduler.enqueue(kind, subject, NETRUN_TASK_BACKGROUND)
	var/key = "[kind]:[REF(subject)]"
	var/datum/netrun_task/original = scheduler.by_key[key]
	var/list/report = scheduler.statistics()
	var/list/entry = netrun_statistics_kind(report, kind)
	TEST_ASSERT_NOTNULL(entry, "A new task kind must be observable before its first execution")
	TEST_ASSERT_EQUAL(entry["requests"], 2, "Every original and merged request must be counted")
	TEST_ASSERT_EQUAL(entry["created"], 1, "A waiting merge must not count as a created task")
	TEST_ASSERT_EQUAL(entry["merged"], 1, "A waiting repeat must be visible as a merge")
	TEST_ASSERT_EQUAL(entry["calls"], 0, "Admission cannot count as execution")
	TEST_ASSERT_EQUAL(entry["pending"], 1, "The new kind must report its pending task")
	TEST_ASSERT_EQUAL(report["pending"], 1, "The total pending count must match the kind's actual queue")
	TEST_ASSERT_EQUAL(report["started_at"], scheduler.statistics_started_at, "The report must retain the scheduler's statistics origin")
	TEST_ASSERT(netrun_statistics_values_only(report), "A report must contain values rather than references to live work")
	var/list/tasks = report["tasks"]
	var/list/sample = tasks[1]
	TEST_ASSERT_EQUAL(sample["target_type"], "/datum", "A live target must be identified only by its type text")
	entry["requests"] = 999
	sample["target_type"] = "changed in snapshot"
	tasks.Cut()
	report["pending"] = 999
	var/list/fresh = scheduler.statistics()
	var/list/fresh_entry = netrun_statistics_kind(fresh, kind)
	var/list/fresh_tasks = fresh["tasks"]
	var/list/fresh_sample = fresh_tasks[1]
	TEST_ASSERT_EQUAL(fresh_entry["requests"], 2, "Mutating a report cannot alter source counters")
	TEST_ASSERT_EQUAL(fresh["pending"], 1, "Mutating a total cannot alter queue ownership")
	TEST_ASSERT_EQUAL(fresh_sample["target_type"], "/datum", "Task samples must be independent between reports")
	TEST_ASSERT_EQUAL(scheduler.by_key[key], original, "Inspecting statistics cannot replace the actual task")
	var/datum/netrun_task_profile/source_profile = scheduler.profiles[kind]
	TEST_ASSERT_EQUAL(source_profile.calls, 0, "Inspection cannot produce an execution sample")
	qdel(subject)
	var/list/deleted = scheduler.statistics()
	var/list/deleted_tasks = deleted["tasks"]
	var/list/deleted_sample = deleted_tasks[1]
	TEST_ASSERT_EQUAL(deleted_sample["target_type"], "удалён", "A deleted weak target must be represented as text")
	TEST_ASSERT(netrun_statistics_values_only(deleted), "A deleted target cannot leak its weakref into a report")

/// Admission, renewal, cancellation and execution cost retain distinct meanings across one lifecycle.
/datum/unit_test/netrun_task_statistics_lifecycle/Run()
	var/datum/netrun_task_scheduler/scheduler = netrun_scheduler_fixture()
	var/datum/subject = allocate(/datum)
	var/kind = "statistics-lifecycle"
	scheduler.enqueue(kind, subject)
	scheduler.enqueue(kind, subject)
	scheduler.enqueue(kind, subject)
	var/datum/netrun_task/task = scheduler.take()
	task.enqueued_at = world.time - 8 SECONDS
	task.started_at = world.time - 2 SECONDS
	scheduler.enqueue(kind, subject, NETRUN_TASK_CRITICAL)
	var/list/running = scheduler.statistics()
	var/list/entry = netrun_statistics_kind(running, kind)
	TEST_ASSERT_EQUAL(running["pending"], 0, "A running merged task is not a second queued object")
	TEST_ASSERT_EQUAL(running["running"], 1, "The active object must remain observable")
	TEST_ASSERT_EQUAL(entry["pending"], 0, "Per-kind pending counts must exclude its running object")
	TEST_ASSERT_EQUAL(entry["running"], 1, "Per-kind running counts must match active ownership")
	var/list/samples = running["tasks"]
	var/list/sample = samples[1]
	TEST_ASSERT_EQUAL(sample["state"], "running", "The active task sample must identify its current state")
	TEST_ASSERT_EQUAL(sample["wait_ds"], 2 SECONDS, "The active sample must measure elapsed execution rather than its old queue delay")
	TEST_ASSERT(sample["rerun"], "Merged follow-up demand must be visible on the active task")
	scheduler.note_execution(task, 1.25, world.time, 1)
	TEST_ASSERT(scheduler.finish(task), "The running merge must renew the original object")
	var/list/renewed = scheduler.statistics()
	entry = netrun_statistics_kind(renewed, kind)
	TEST_ASSERT_EQUAL(renewed["pending"], 1, "Renewal must create one pending dispatch")
	TEST_ASSERT_EQUAL(renewed["running"], 0, "Completed execution must release active ownership")
	TEST_ASSERT_EQUAL(entry["requests"], 4, "Renewal itself must not manufacture another producer request")
	TEST_ASSERT_EQUAL(entry["created"], 1, "The renewed object must not count as another allocation")
	TEST_ASSERT_EQUAL(entry["merged"], 3, "Waiting and running merges must share the same demand counter")
	TEST_ASSERT_EQUAL(entry["renewed"], 1, "The single retained follow-up must count once")
	TEST_ASSERT_EQUAL(entry["calls"], 1, "The first dispatch must produce one CPU sample")
	TEST_ASSERT_EQUAL(entry["total_ms"], 1.25, "Actual CPU samples must feed the total")
	TEST_ASSERT_EQUAL(entry["average_ms"], 1.25, "A first CPU sample must also be the average")
	TEST_ASSERT_EQUAL(entry["peak_ms"], 1.25, "A first CPU sample must also be the peak")
	TEST_ASSERT_EQUAL(entry["total_wait_ds"], 8 SECONDS, "CPU profiling must preserve the original queue delay")
	TEST_ASSERT_EQUAL(entry["overdue"], 1, "The delayed first dispatch must count as overdue")
	TEST_ASSERT_EQUAL(entry["task_overruns"], 1, "A CPU sample above its supplied budget must count as an overrun")
	TEST_ASSERT(scheduler.cancel(kind, subject), "The renewed pending dispatch must remain cancellable")
	scheduler.enqueue(kind, subject)
	task = scheduler.take()
	task.enqueued_at = world.time - 2 SECONDS
	scheduler.note_execution(task, 0.75, world.time, 1)
	scheduler.finish(task)
	var/list/finished = scheduler.statistics()
	entry = netrun_statistics_kind(finished, kind)
	TEST_ASSERT_EQUAL(finished["pending"] + finished["running"], 0, "The completed lifecycle must leave no task ownership")
	TEST_ASSERT_EQUAL(finished["completed"], 2, "Only actual dispatch samples count as completed work")
	TEST_ASSERT_EQUAL(finished["merged"], 3, "Global merge totals must agree with the only admitted kind")
	TEST_ASSERT_EQUAL(finished["cancelled"], 1, "Explicit cancellation must remain visible in the total")
	TEST_ASSERT_EQUAL(entry["requests"], 5, "Fresh admission after cancellation adds one request")
	TEST_ASSERT_EQUAL(entry["created"], 2, "Fresh admission after cancellation allocates a new object")
	TEST_ASSERT_EQUAL(entry["cancelled"], 1, "Per-kind cancellation must match its actual queue operation")
	TEST_ASSERT_EQUAL(entry["calls"], 2, "Two executed slices must produce two samples")
	TEST_ASSERT_EQUAL(entry["total_ms"], 2, "CPU totals must accumulate both slices")
	TEST_ASSERT_EQUAL(entry["average_ms"], 1, "CPU average must derive from actual sample count")
	TEST_ASSERT_EQUAL(entry["peak_ms"], 1.25, "A later cheaper slice must not erase the peak")
	TEST_ASSERT_EQUAL(entry["total_wait_ds"], 10 SECONDS, "Queue delays must accumulate independently of runtime")
	TEST_ASSERT_EQUAL(entry["peak_wait_ds"], 8 SECONDS, "The first longer queue delay must remain the peak")
	TEST_ASSERT_EQUAL(entry["overdue"], 1, "A later timely slice must not add another overdue count")
	TEST_ASSERT_EQUAL(entry["task_overruns"], 1, "A cheaper slice below budget must not add another CPU overrun")

/// A bounded sample exposes running work and the oldest waits without changing FIFO or profiles.
/datum/unit_test/netrun_task_statistics_bounded_sample/Run()
	var/datum/netrun_task_scheduler/scheduler = netrun_scheduler_fixture()
	var/datum/active_subject = allocate(/datum)
	scheduler.enqueue("statistics-active", active_subject)
	var/datum/netrun_task/active = scheduler.take()
	active.started_at = world.time - 1 SECONDS
	var/list/subjects = list()
	for(var/index in 1 to 40)
		var/datum/subject = allocate(/datum)
		subjects += subject
		scheduler.enqueue("statistics-waiting", subject, NETRUN_TASK_BACKGROUND)
		var/datum/netrun_task/task = scheduler.by_key["statistics-waiting:[REF(subject)]"]
		task.enqueued_at = world.time - index * (1 SECONDS)
	var/datum/netrun_task_queue/queue = scheduler.queues[NETRUN_TASK_BACKGROUND]
	var/datum/netrun_task/first = queue.first
	var/datum/netrun_task/last = queue.last
	var/cursor = scheduler.dispatch_cursor
	var/merge_count = scheduler.merged
	var/list/report
	for(var/read in 1 to 3)
		report = scheduler.statistics()
	var/list/samples = report["tasks"]
	TEST_ASSERT_EQUAL(report["pending"], 40, "Sampling must retain the complete pending count beyond its display bound")
	TEST_ASSERT_EQUAL(report["running"], 1, "Sampling must retain the active count")
	TEST_ASSERT_EQUAL(length(samples), 32, "The task sample must remain bounded independently of queue size")
	var/list/running_sample = samples[1]
	TEST_ASSERT_EQUAL(running_sample["key"], active.key, "Running work must be included before waiting samples")
	TEST_ASSERT_EQUAL(running_sample["state"], "running", "Running work must retain its state in the sample")
	for(var/index in 2 to length(samples))
		var/list/sample = samples[index]
		var/expected_index = 42 - index
		var/datum/subject = subjects[expected_index]
		TEST_ASSERT_EQUAL(sample["key"], "statistics-waiting:[REF(subject)]", "The bounded waiting sample must contain the oldest pending tasks in descending age")
		TEST_ASSERT_EQUAL(sample["wait_ds"], expected_index * (1 SECONDS), "Each waiting sample must retain its actual queue age")
	var/list/waiting_kind = netrun_statistics_kind(report, "statistics-waiting")
	TEST_ASSERT_EQUAL(waiting_kind["pending"], 40, "Per-kind totals must include pending tasks outside the sample")
	TEST_ASSERT_EQUAL(waiting_kind["oldest_wait_ds"], 40 SECONDS, "Per-kind statistics must expose the maximum wait")
	TEST_ASSERT_EQUAL(waiting_kind["calls"], 0, "Repeated inspection cannot record execution")
	TEST_ASSERT_EQUAL(queue.first, first, "Sampling oldest tasks cannot reorder the real FIFO head")
	TEST_ASSERT_EQUAL(queue.last, last, "Sampling oldest tasks cannot reorder the real FIFO tail")
	TEST_ASSERT_EQUAL(scheduler.dispatch_cursor, cursor, "Inspection cannot advance weighted priority rotation")
	TEST_ASSERT_EQUAL(scheduler.merged, merge_count, "Inspection cannot act like a new producer request")
	TEST_ASSERT_EQUAL(scheduler.counts[NETRUN_TASK_BACKGROUND], 40, "Inspection cannot dequeue sampled work")
	TEST_ASSERT_EQUAL(length(scheduler.profiles), 2, "Inspection cannot create unrelated profile records")
	TEST_ASSERT(netrun_statistics_values_only(report), "A bounded task sample must still contain values only")
	qdel(active)
	var/datum/netrun_task/dispatched = scheduler.take()
	TEST_ASSERT_EQUAL(dispatched, first, "Actual dispatch after inspection must use original FIFO rather than report sorting")
	qdel(dispatched)

/// The runtime report sorts copied values and escapes task identities before HTML rendering.
/datum/unit_test/netrun_task_statistics_monitor/Run()
	var/datum/netrun_task_scheduler/scheduler = netrun_scheduler_fixture()
	var/datum/subject = allocate(/datum)
	scheduler.enqueue("cpu-heavy<script>", subject)
	var/datum/netrun_task/task = scheduler.take()
	scheduler.note_execution(task, 5)
	scheduler.finish(task)
	scheduler.enqueue("queue-heavy", allocate(/datum))
	scheduler.enqueue("queue-heavy", allocate(/datum))
	var/list/report = scheduler.statistics()
	var/list/types = report["types"]
	var/list/original_first = types[1]
	var/cpu_label = "<td>cpu-heavy&lt;script&gt;</td>"
	var/queue_label = "<td>queue-heavy</td>"
	var/html = netrun_task_statistics_html(report, "total_ms", "?src=fixture")
	TEST_ASSERT(findtext(html, cpu_label) && findtext(html, queue_label), "The monitor must render both completed and pending-only kinds")
	TEST_ASSERT(findtext(html, cpu_label) < findtext(html, queue_label), "The CPU sort must place the expensive kind first")
	TEST_ASSERT(!findtext(html, "<script>"), "A task identity must not inject raw HTML into the monitor")
	TEST_ASSERT(findtext(html, "netrun_statistics_sort="), "The monitor must offer an on-demand refresh without a timer")
	html = netrun_task_statistics_html(report, "pending", "?src=fixture")
	TEST_ASSERT(findtext(html, queue_label) < findtext(html, cpu_label), "The queue sort must place pending backlog first")
	TEST_ASSERT_EQUAL(types[1], original_first, "Sorting the report cannot reorder its original type snapshot")
	TEST_ASSERT_EQUAL(scheduler.pending(), 2, "Rendering cannot dispatch or cancel pending jobs")
	html = netrun_task_statistics_html(report, "unknown-sort", "?src=fixture")
	TEST_ASSERT(findtext(html, cpu_label) < findtext(html, queue_label), "An unknown sort must safely use the default CPU order")
