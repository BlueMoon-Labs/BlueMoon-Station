/// This worker never registers as SSnetrun or populates real station work.
/datum/controller/subsystem/netrun/netrun_execution_test
	// Master instantiates subsystem subtypes even when New() skips its parent.
	// This fixture is driven explicitly by run_pass(), never by the live MC.
	flags = SS_NO_INIT | SS_NO_FIRE
	var/probe_calls = 0
	var/probe_populations = 0

/datum/controller/subsystem/netrun/netrun_execution_test/New()
	return

/datum/controller/subsystem/netrun/netrun_execution_test/Destroy()
	QDEL_NULL(task_scheduler)
	QDEL_NULL(execution_limits)
	QDEL_NULL(topology)
	return ..()

/datum/controller/subsystem/netrun/netrun_execution_test/populate_tasks()
	probe_populations++

/// Direct fixture calls bypass MC dispatch, so supply its running state and restore globals.
/datum/controller/subsystem/netrun/netrun_execution_test/proc/run_pass()
	var/previous_state = state
	var/previous_ticklimit = Master.current_ticklimit
	state = SS_RUNNING
	Master.current_ticklimit = INFINITY
	fire()
	Master.current_ticklimit = previous_ticklimit
	state = previous_state

/datum/netrun_task/execution_probe
	kind = "execution_probe"

/datum/netrun_task/execution_probe/execute(datum/controller/subsystem/netrun/netrun_execution_test/worker, datum/netrun_execution_limits/limits)
	worker.probe_calls++
	return TRUE

/// The shared continuation, used by bootstrap/prebuild/publication, owns repeat dispatch.
/datum/netrun_task/continuation_probe
	parent_type = /datum/netrun_task/continuation
	kind = "continuation_probe"

/datum/netrun_task/continuation_probe/advance(datum/controller/subsystem/netrun/netrun_execution_test/worker, datum/netrun_execution_limits/limits)
	return ++worker.probe_calls >= 3

/datum/unit_test/netrun_execution_continuation/Run()
	var/datum/controller/subsystem/netrun/netrun_execution_test/worker = allocate(/datum/controller/subsystem/netrun/netrun_execution_test)
	worker.task_adaptive_budget = FALSE
	worker.task_budget_ms = NETRUN_EXECUTION_MAX_BUDGET_MS
	worker.task_max_per_pass = 1
	worker.next_task_population = INFINITY
	var/datum/work = allocate(/datum)
	var/datum/netrun_task_scheduler/scheduler = worker.get_task_scheduler()
	scheduler.enqueue("continuation_probe", work, NETRUN_TASK_BACKGROUND)
	for(var/pass in 1 to 3)
		worker.run_pass()
		TEST_ASSERT_EQUAL(worker.probe_calls, pass, "A continuation may advance only one slice per dispatch")
		TEST_ASSERT_EQUAL(scheduler.pending(), pass < 3 ? 1 : 0, "An incomplete slice must retain exactly one continuation, then drain")
	TEST_ASSERT_EQUAL(scheduler.counts[NETRUN_TASK_BACKGROUND], 0, "Continuation completion must release priority accounting")
	worker.probe_calls = 0
	scheduler.enqueue("continuation_probe", work, NETRUN_TASK_BACKGROUND)
	worker.run_pass()
	scheduler.cancel("continuation_probe", work)
	worker.run_pass()
	TEST_ASSERT_EQUAL(worker.probe_calls, 1, "Cancelling a continuation must stop subsequent slices")

/// Only begin dispatch is replaced; the real timer/continuation/scheduler own wakeup.
/datum/netrun_machine_resolution/netrun_wake_probe
	var/datum/netrun_machine_transport/wake_transport
	var/list/observations
	var/probe_id

/datum/netrun_machine_resolution/netrun_wake_probe/New(datum/netrun_machine_transport/transport, list/samples, id)
	wake_transport = transport
	observations = samples
	probe_id = id

/datum/netrun_machine_resolution/netrun_wake_probe/begin()
	observations["begun"]++
	observations["[probe_id]"]++
	wake_transport.waiting_resolutions -= src

/datum/netrun_machine_resolution/netrun_wake_probe/Destroy()
	if(!QDELETED(wake_transport))
		wake_transport.waiting_resolutions -= src
	wake_transport = null
	observations = null
	return ..()

/// A readiness timer must never synchronously retry an entire station's service-discovery backlog.
/datum/unit_test/netrun_execution_discovery_wake_slices/Run()
	var/datum/netrun_machine_transport/transport = allocate(/datum/netrun_machine_transport)
	transport.bootstrap_complete = TRUE
	var/list/samples = list("begun" = 0)
	for(var/id in 1 to 17)
		transport.waiting_resolutions += allocate(/datum/netrun_machine_resolution/netrun_wake_probe, transport, samples, id)
	transport.resume_resolutions()
	TEST_ASSERT_EQUAL(samples["begun"], 0, "The readiness timer callback must only admit work, never call query.begin inline")
	var/key = "discovery_wake:[REF(transport)]"
	var/datum/netrun_task_scheduler/live = SSnetrun.get_task_scheduler()
	TEST_ASSERT(live.by_key[key], "Ready service-discovery work must enter the existing shared scheduler")
	for(var/notification in 1 to 32)
		transport.wake_resolutions()
	TEST_ASSERT(!transport.wake_timer, "Readiness notifications during an admitted wake must not create more timers")
	TEST_ASSERT(live.by_key[key], "Coalesced readiness notifications must retain one admitted continuation")
	// Use the ordinary execution fixture to dispatch exactly one common-worker slice.
	var/datum/controller/subsystem/netrun/netrun_execution_test/worker = allocate(/datum/controller/subsystem/netrun/netrun_execution_test)
	worker.task_adaptive_budget = FALSE
	worker.task_budget_ms = NETRUN_EXECUTION_MAX_BUDGET_MS
	worker.task_max_per_pass = 1
	worker.next_task_population = INFINITY
	live.cancel("discovery_wake", transport)
	var/datum/netrun_task_scheduler/scheduler = worker.get_task_scheduler()
	scheduler.enqueue("discovery_wake", transport, NETRUN_TASK_BACKGROUND)
	worker.run_pass()
	TEST_ASSERT_EQUAL(samples["begun"], 8, "The first readiness worker slice must begin at most eight queries")
	TEST_ASSERT_EQUAL(scheduler.pending(), 1, "An incomplete discovery wake must retain one continuation")
	transport.waiting_resolutions += allocate(/datum/netrun_machine_resolution/netrun_wake_probe, transport, samples, 18)
	for(var/notification in 1 to 32)
		transport.wake_resolutions()
	worker.run_pass()
	TEST_ASSERT_EQUAL(samples["begun"], 16, "The second readiness slice must observe the same eight-query bound")
	worker.run_pass()
	TEST_ASSERT_EQUAL(samples["begun"], 17, "Finishing the original snapshot must not inline a second full readiness wave")
	TEST_ASSERT_EQUAL(scheduler.pending(), 1, "A notification after a new waiter arrives must retain a follow-up continuation")
	worker.run_pass()
	TEST_ASSERT_EQUAL(samples["begun"], 18, "The follow-up snapshot must include a query that arrived after the original snapshot")
	TEST_ASSERT_EQUAL(scheduler.pending(), 0, "Finite readiness notifications and waiters must fully drain")
	TEST_ASSERT_EQUAL(length(transport.waiting_resolutions), 0, "Completed wakeup must release every resumed waiter")
	for(var/id in 1 to 18)
		TEST_ASSERT_EQUAL(samples["[id]"], 1, "Repeated readiness signals must not begin resumed query [id] twice")
	TEST_ASSERT(!live.by_key[key] && !transport.wake_timer, "Draining an isolated continuation must not leave hidden work in the live scheduler")

/// Destroying a transport must cancel both readiness timers and already admitted waves.
/datum/unit_test/netrun_execution_discovery_wake_cleanup/Run()
	var/list/samples = list("begun" = 0)
	var/datum/netrun_machine_transport/delayed = allocate(/datum/netrun_machine_transport)
	delayed.waiting_resolutions += allocate(/datum/netrun_machine_resolution/netrun_wake_probe, delayed, samples, 1)
	delayed.wake_resolutions()
	TEST_ASSERT_NULL(delayed.wake_timer, "Discovery must remain suspended until network bootstrap completes")
	delayed.bootstrap_complete = TRUE
	delayed.wake_resolutions()
	var/timer = delayed.wake_timer
	TEST_ASSERT(timer, "A new readiness signal must own its deferred admission timer")
	qdel(delayed)
	TEST_ASSERT_NULL(SStimer.timer_id_dict[timer], "Destroying the transport must cancel its readiness timer")
	var/datum/netrun_machine_transport/ready = allocate(/datum/netrun_machine_transport)
	ready.waiting_resolutions += allocate(/datum/netrun_machine_resolution/netrun_wake_probe, ready, samples, 2)
	ready.resume_resolutions()
	var/key = "discovery_wake:[REF(ready)]"
	TEST_ASSERT(SSnetrun.get_task_scheduler().by_key[key], "The cleanup test needs a real admitted readiness continuation")
	qdel(ready)
	TEST_ASSERT_NULL(SSnetrun.task_scheduler.by_key[key], "Destroying the transport must cancel its readiness continuation")
	TEST_ASSERT_EQUAL(samples["begun"], 0, "Neither cancelled readiness path may execute native query handling")

/// A previous expensive task must not turn a cheap packet burst into two tasks per pass.
/datum/unit_test/netrun_execution_mixed_cost_drain/Run()
	var/datum/controller/subsystem/netrun/netrun_execution_test/worker = allocate(/datum/controller/subsystem/netrun/netrun_execution_test)
	worker.task_adaptive_budget = FALSE
	worker.task_budget_ms = NETRUN_EXECUTION_MAX_BUDGET_MS
	worker.task_max_per_pass = 32
	worker.next_task_population = INFINITY
	var/datum/netrun_task_scheduler/scheduler = worker.get_task_scheduler()
	var/datum/netrun_task/prior = allocate(/datum/netrun_task/execution_probe, "execution_probe", "prior-expensive", NETRUN_TASK_NORMAL)
	scheduler.note_execution(prior, NETRUN_EXECUTION_MAX_BUDGET_MS)
	for(var/i in 1 to 96)
		scheduler.enqueue("execution_probe", allocate(/datum), NETRUN_TASK_NORMAL)
	for(var/pass in 1 to 3)
		worker.run_pass()
		TEST_ASSERT_EQUAL(worker.probe_calls, pass * 32, "Cheap work must use the actual remaining CPU budget, independently of an old expensive task sample")
	TEST_ASSERT_EQUAL(scheduler.pending(), 0, "A finite burst must leave no pending task after its bounded worker passes")
	TEST_ASSERT_EQUAL(scheduler.counts[NETRUN_TASK_NORMAL], 0, "Draining must reconcile the per-priority counters")

/// Every kind of admitted backlog needs fast follow-up, including prewarm and node work.
/datum/unit_test/netrun_execution_backlog_cadence/Run()
	var/datum/controller/subsystem/netrun/netrun_execution_test/worker = allocate(/datum/controller/subsystem/netrun/netrun_execution_test)
	TEST_ASSERT_EQUAL(NETRUN_DEFAULT_FIRE_INTERVAL, 20, "Idle/background maintenance must use the requested twenty-decisecond cadence")
	worker.wait = NETRUN_DEFAULT_FIRE_INTERVAL
	worker.next_fire = world.time + NETRUN_DEFAULT_FIRE_INTERVAL
	worker.get_task_scheduler().enqueue("execution_probe", allocate(/datum), NETRUN_TASK_BACKGROUND)
	TEST_ASSERT(worker.next_fire <= world.time, "Admitting ready background I/O must interrupt the idle deadline immediately")
	worker.refresh_delivery_interval()
	TEST_ASSERT_EQUAL(worker.wait, world.tick_lag, "A pending non-delivery task must not wait for the idle subsystem interval")
	qdel(worker.task_scheduler.take())
	worker.refresh_delivery_interval()
	TEST_ASSERT_EQUAL(worker.wait, NETRUN_DEFAULT_FIRE_INTERVAL, "A drained queue must return to its idle cadence")
	var/datum/player = allocate(/datum)
	worker.get_task_scheduler().enqueue("execution_probe", player, NETRUN_TASK_BACKGROUND)
	worker.wait = NETRUN_DEFAULT_FIRE_INTERVAL
	worker.next_fire = world.time + NETRUN_DEFAULT_FIRE_INTERVAL
	worker.get_task_scheduler().enqueue("execution_probe", player, NETRUN_TASK_CRITICAL, TRUE)
	TEST_ASSERT_EQUAL(worker.wait, world.tick_lag, "Explicit input must restore the responsive cadence when promoting existing work")
	TEST_ASSERT(worker.next_fire <= world.time, "An input promotion must not wait for the next two-second maintenance pass")

/// A drained active clock honors its configured population instead of the idle interval.
/datum/unit_test/netrun_execution_active_cadence/Run()
	var/datum/controller/subsystem/netrun/netrun_execution_test/worker = allocate(/datum/controller/subsystem/netrun/netrun_execution_test)
	var/obj/item/host = allocate(/obj/item)
	var/datum/netrun_console/console = allocate(/datum/netrun_console, host)
	worker.active_consoles[console] = TRUE
	var/population_delay = max(world.tick_lag, 2)
	worker.next_task_population = world.time + population_delay
	worker.refresh_delivery_interval()
	TEST_ASSERT_EQUAL(worker.wait, population_delay, "A live console must preserve a short configured UI/gameplay population interval after its task drains")
	worker.active_consoles.Cut()
	worker.next_node_deadline = world.time + 5
	worker.refresh_delivery_interval()
	// Fractional world.time can round across a float boundary when five is added
	// and subtracted; the tolerance is far below one native scheduling tick.
	TEST_ASSERT(abs(worker.wait - max(world.tick_lag, 5)) < 0.001, "A known native deadline must shorten idle maintenance without scanning every node")
	worker.next_node_deadline = world.time - 1
	worker.refresh_delivery_interval()
	TEST_ASSERT_EQUAL(worker.wait, population_delay, "A stale cancelled native deadline must wait for one population rather than spin every tick")
	worker.next_node_deadline = INFINITY
	worker.refresh_delivery_interval()
	TEST_ASSERT_EQUAL(worker.wait, NETRUN_DEFAULT_FIRE_INTERVAL, "An empty worker must still return to the requested slow cadence")

/// Fast follow-up passes share normalized tuning; actual live edits still apply immediately.
/datum/unit_test/netrun_execution_limits_reuse/Run()
	var/datum/controller/subsystem/netrun/netrun_execution_test/worker = allocate(/datum/controller/subsystem/netrun/netrun_execution_test)
	var/datum/netrun_execution_limits/limits = worker.get_execution_limits(TRUE)
	var/revision = limits.configuration_revision
	var/list/rotation = limits.priority_rotation.Copy()
	for(var/pass in 1 to 8)
		worker.get_execution_limits(TRUE)
	TEST_ASSERT_EQUAL(limits.configuration_revision, revision, "An unchanged packet burst must not repeatedly normalize all tuning fields and rebuild the rotation")
	worker.task_max_per_pass = 7
	worker.get_execution_limits(TRUE)
	TEST_ASSERT_EQUAL(limits.max_per_pass, 7, "Changing scalar tuning in the same tick must be visible on the next refresh")
	TEST_ASSERT_EQUAL(limits.configuration_revision, revision + 1, "A real tuning edit must produce one new normalized revision")
	worker.task_priority_rotation[1] = NETRUN_TASK_BACKGROUND
	worker.get_execution_limits(TRUE)
	TEST_ASSERT_EQUAL(limits.priority_rotation[1], NETRUN_TASK_BACKGROUND, "An in-place priority rotation edit must not be hidden by reference equality")
	TEST_ASSERT_EQUAL(limits.configuration_revision, revision + 2, "An in-place list edit must normalize exactly once")
	TEST_ASSERT_EQUAL(rotation[1], NETRUN_TASK_CRITICAL, "The fixture must have started with the default critical-first rotation")

/datum/unit_test/netrun_execution_live_limits/Run()
	var/datum/controller/subsystem/netrun/original = SSnetrun
	var/datum/controller/subsystem/netrun/netrun_execution_test/worker = allocate(/datum/controller/subsystem/netrun/netrun_execution_test)
	TEST_ASSERT_EQUAL(SSnetrun, original, "The fixture must not replace the running subsystem")
	worker.task_adaptive_budget = FALSE
	worker.task_budget_ms = NETRUN_EXECUTION_MAX_BUDGET_MS
	worker.task_max_per_pass = 3
	worker.task_min_per_pass = 3
	worker.task_population_interval = 17
	var/datum/netrun_task_scheduler/scheduler = worker.get_task_scheduler()
	for(var/i in 1 to 7)
		scheduler.enqueue("execution_probe", allocate(/datum), NETRUN_TASK_CRITICAL, TRUE)
	worker.run_pass()
	TEST_ASSERT_EQUAL(worker.probe_calls, 3, "Even interactive input must obey the configured per-fire task limit")
	TEST_ASSERT_EQUAL(worker.next_task_population, world.time + 17, "Population interval must come from subsystem tuning")
	worker.task_max_per_pass = 1
	worker.run_pass()
	TEST_ASSERT_EQUAL(worker.probe_calls, 4, "Changing the public maximum must apply on the next pass without rebuilding the scheduler")
	TEST_ASSERT_EQUAL(worker.probe_populations, 1, "Extra responsive passes must not repopulate all background work")
	worker.task_budget_ms = 4
	worker.task_min_budget_ms = 0.5
	worker.task_pressure_tick_usage = 80
	worker.task_adaptive_budget = TRUE
	var/datum/netrun_execution_limits/limits = worker.get_execution_limits(TRUE)
	TEST_ASSERT_EQUAL(limits.budget_for(40), 2, "Adaptive CPU budget must use the configured pressure threshold")
	TEST_ASSERT_EQUAL(limits.budget_for(160), 0.5, "CPU pressure must retain the configured bounded minimum")
	worker.task_adaptive_budget = FALSE
	limits = worker.get_execution_limits(TRUE)
	TEST_ASSERT_EQUAL(limits.budget_for(160), 4, "Fixed mode must retain the configured normal budget")

/datum/unit_test/netrun_execution_invalid_limits_and_fairness/Run()
	var/datum/controller/subsystem/netrun/netrun_execution_test/worker = allocate(/datum/controller/subsystem/netrun/netrun_execution_test)
	worker.task_budget_ms = "bad"
	worker.task_min_budget_ms = INFINITY
	worker.task_max_per_pass = -3
	worker.task_min_per_pass = 100000
	worker.apc_prebuild_operations = 100000
	worker.task_population_interval = -1
	worker.task_interactive_burst = 0
	worker.task_priority_rotation = list(NETRUN_TASK_CRITICAL, NETRUN_TASK_CRITICAL, "bad", 1.5)
	var/datum/netrun_execution_limits/limits = worker.get_execution_limits(TRUE)
	TEST_ASSERT_EQUAL(limits.budget_ms, NETRUN_DEFAULT_TASK_BUDGET_MS, "Invalid numeric input must fall back to a finite budget")
	TEST_ASSERT(limits.min_budget_ms > 0 && limits.min_budget_ms <= limits.budget_ms, "Minimum CPU budget must remain bounded")
	TEST_ASSERT_EQUAL(limits.max_per_pass, 1, "Negative task counts must retain progress through one bounded task")
	TEST_ASSERT_EQUAL(limits.min_per_pass, 1, "An inverted minimum cannot bypass the maximum")
	TEST_ASSERT_EQUAL(limits.apc_operations, NETRUN_EXECUTION_MAX_PREBUILD_OPERATIONS, "A topology slice must have a finite upper bound")
	TEST_ASSERT_EQUAL(limits.population_interval, NETRUN_EXECUTION_MIN_INTERVAL, "A negative interval cannot spin without advancing time")
	var/datum/netrun_task_scheduler/scheduler = allocate(/datum/netrun_task_scheduler, limits)
	for(var/priority in NETRUN_TASK_CRITICAL to NETRUN_TASK_BACKGROUND)
		scheduler.enqueue("probe", allocate(/datum), priority)
	var/list/seen = list()
	for(var/i in 1 to 3)
		var/datum/netrun_task/task = scheduler.take()
		TEST_ASSERT_NOTNULL(task, "Malformed rotation must still make pending work reachable")
		seen |= task.priority
		qdel(task)
	TEST_ASSERT_EQUAL(length(seen), 3, "Repairing a malformed rotation must preserve all priority classes")

/datum/unit_test/netrun_execution_interactive_preemption/Run()
	var/datum/netrun_execution_limits/limits = allocate(/datum/netrun_execution_limits)
	limits.interactive_burst = 2
	var/datum/netrun_task_scheduler/scheduler = allocate(/datum/netrun_task_scheduler, limits)
	scheduler.dispatch_cursor = 3 // The weighted rotation would dispatch background next.
	var/datum/background = allocate(/datum)
	var/datum/player = allocate(/datum)
	scheduler.enqueue("probe", background, NETRUN_TASK_BACKGROUND)
	scheduler.enqueue("probe", player, NETRUN_TASK_BACKGROUND)
	scheduler.enqueue("probe", player, NETRUN_TASK_CRITICAL, TRUE)
	scheduler.enqueue("probe", player, NETRUN_TASK_CRITICAL, TRUE)
	scheduler.enqueue("probe", allocate(/datum), NETRUN_TASK_CRITICAL, TRUE)
	scheduler.enqueue("probe", allocate(/datum), NETRUN_TASK_CRITICAL, TRUE)
	TEST_ASSERT_EQUAL(scheduler.pending(), 4, "Repeated player input must promote and coalesce the existing work item")
	var/datum/netrun_task/task = scheduler.take()
	TEST_ASSERT_EQUAL(task.target(), player, "Input must preempt already queued background regardless of rotation cursor")
	qdel(task)
	task = scheduler.take()
	TEST_ASSERT(task.interactive, "A bounded input burst must retain highest service priority")
	qdel(task)
	task = scheduler.take()
	TEST_ASSERT_EQUAL(task.target(), background, "Sustained input must still allow maintenance after the configured burst")
	qdel(task)

/// Cooperative batches share the pass allowance and cannot reuse CPU from an old tick.
/datum/unit_test/netrun_execution_nested_batch_budget/Run()
	var/datum/controller/subsystem/netrun/netrun_execution_test/worker = allocate(/datum/controller/subsystem/netrun/netrun_execution_test)
	TEST_ASSERT_EQUAL(worker.remaining_task_budget_ms(1), 1, "Direct calls need a finite independent batch cap")
	worker.task_slice_budget_ms = 0
	worker.task_slice_start_usage = TICK_USAGE
	worker.task_slice_started_at = world.time
	TEST_ASSERT_EQUAL(worker.remaining_task_budget_ms(1), 0, "A nested batch cannot replenish an exhausted worker allowance")
	worker.task_slice_budget_ms = 1000
	TEST_ASSERT_EQUAL(worker.remaining_task_budget_ms(1), 1, "A batch cannot borrow more than its own cap from a large worker allowance")
	worker.task_slice_started_at = world.time - world.tick_lag
	TEST_ASSERT_EQUAL(worker.remaining_task_budget_ms(1), 0, "A callback resumed in another tick must yield before doing another batch")
	worker.task_slice_budget_ms = null
	worker.next_task_population = INFINITY
	worker.run_pass()
	TEST_ASSERT(isnull(worker.task_slice_budget_ms), "A completed worker pass must release its nested-batch context")
