/// Public subsystem tuning. Changes are normalized at the start of the next fire().
/datum/controller/subsystem/netrun
	var/task_adaptive_budget = TRUE
	var/task_budget_ms = NETRUN_DEFAULT_TASK_BUDGET_MS
	var/task_min_budget_ms = NETRUN_DEFAULT_TASK_MIN_BUDGET_MS
	var/task_pressure_tick_usage = NETRUN_DEFAULT_TASK_PRESSURE_TICK_USAGE
	var/task_min_per_pass = NETRUN_DEFAULT_TASK_MIN_PER_PASS
	var/task_max_per_pass = NETRUN_DEFAULT_TASK_MAX_PER_PASS
	var/task_interactive_burst = NETRUN_DEFAULT_INTERACTIVE_BURST
	var/task_interactive_priority = NETRUN_DEFAULT_INTERACTIVE_PRIORITY
	var/ui_interactive_flush = NETRUN_DEFAULT_INTERACTIVE_FLUSH
	var/task_cost_floor_ms = NETRUN_DEFAULT_TASK_COST_FLOOR_MS
	var/task_initial_cost_ms = NETRUN_DEFAULT_TASK_INITIAL_COST_MS
	var/task_cost_smoothing = NETRUN_DEFAULT_TASK_COST_SMOOTHING
	var/task_population_interval = NETRUN_DEFAULT_TASK_POPULATION_INTERVAL
	var/apc_prebuild_operations = NETRUN_DEFAULT_APC_PREBUILD_OPERATIONS
	var/route_refresh_interval = NETRUN_DEFAULT_ROUTE_REFRESH_INTERVAL
	var/route_expiry_interval = NETRUN_DEFAULT_ROUTE_EXPIRY_INTERVAL
	var/ui_refresh_interval = NETRUN_DEFAULT_UI_REFRESH_INTERVAL
	var/ui_activity_lease = NETRUN_DEFAULT_UI_ACTIVITY_LEASE
	var/node_activity_duration = NETRUN_DEFAULT_NODE_ACTIVITY_DURATION
	var/node_poll_interval = NETRUN_DEFAULT_NODE_POLL_INTERVAL
	var/node_idle_poll_interval = NETRUN_DEFAULT_NODE_IDLE_POLL_INTERVAL
	var/node_update_interval = NETRUN_DEFAULT_NODE_UPDATE_INTERVAL
	var/task_critical_late_after = NETRUN_DEFAULT_TASK_CRITICAL_LATE_AFTER
	var/task_normal_late_after = NETRUN_DEFAULT_TASK_NORMAL_LATE_AFTER
	var/task_background_late_after = NETRUN_DEFAULT_TASK_BACKGROUND_LATE_AFTER
	var/list/task_priority_rotation = NETRUN_DEFAULT_TASK_PRIORITY_ROTATION
	/// One normalized configuration object, shared read-only by this worker's tasks.
	var/datum/netrun_execution_limits/execution_limits

/datum/controller/subsystem/netrun/proc/get_execution_limits(refresh = FALSE)
	RETURN_TYPE(/datum/netrun_execution_limits)
	if(!execution_limits)
		execution_limits = new
		refresh = TRUE
	if(refresh && !execution_limits.matches(src))
		execution_limits.configure(src)
	return execution_limits

/// A validated snapshot separates tuning from task behavior and never mutates public settings.
/datum/netrun_execution_limits
	/// Stable raw tuning avoids rebuilding normalized lists on every packet drain.
	var/configuration_revision = 0
	var/list/source_values
	var/source_rotation
	var/list/source_rotation_values
	var/static/list/source_fields = list(
		"task_adaptive_budget", "task_budget_ms", "task_min_budget_ms", "task_pressure_tick_usage",
		"task_min_per_pass", "task_max_per_pass", "task_interactive_burst", "task_interactive_priority",
		"ui_interactive_flush", "task_cost_floor_ms", "task_initial_cost_ms", "task_cost_smoothing",
		"task_population_interval", "apc_prebuild_operations", "route_refresh_interval", "route_expiry_interval",
		"ui_refresh_interval", "ui_activity_lease", "node_activity_duration", "node_poll_interval",
		"node_idle_poll_interval", "node_update_interval", "task_critical_late_after",
		"task_normal_late_after", "task_background_late_after")
	var/adaptive_budget = TRUE
	var/budget_ms = NETRUN_DEFAULT_TASK_BUDGET_MS
	var/min_budget_ms = NETRUN_DEFAULT_TASK_MIN_BUDGET_MS
	var/pressure_tick_usage = NETRUN_DEFAULT_TASK_PRESSURE_TICK_USAGE
	var/min_per_pass = NETRUN_DEFAULT_TASK_MIN_PER_PASS
	var/max_per_pass = NETRUN_DEFAULT_TASK_MAX_PER_PASS
	var/interactive_burst = NETRUN_DEFAULT_INTERACTIVE_BURST
	var/interactive_priority = NETRUN_DEFAULT_INTERACTIVE_PRIORITY
	var/interactive_flush = NETRUN_DEFAULT_INTERACTIVE_FLUSH
	var/cost_floor_ms = NETRUN_DEFAULT_TASK_COST_FLOOR_MS
	var/initial_cost_ms = NETRUN_DEFAULT_TASK_INITIAL_COST_MS
	var/cost_smoothing = NETRUN_DEFAULT_TASK_COST_SMOOTHING
	var/population_interval = NETRUN_DEFAULT_TASK_POPULATION_INTERVAL
	var/apc_operations = NETRUN_DEFAULT_APC_PREBUILD_OPERATIONS
	var/route_refresh_interval = NETRUN_DEFAULT_ROUTE_REFRESH_INTERVAL
	var/route_expiry_interval = NETRUN_DEFAULT_ROUTE_EXPIRY_INTERVAL
	var/ui_refresh_interval = NETRUN_DEFAULT_UI_REFRESH_INTERVAL
	var/ui_activity_lease = NETRUN_DEFAULT_UI_ACTIVITY_LEASE
	var/node_activity_duration = NETRUN_DEFAULT_NODE_ACTIVITY_DURATION
	var/node_poll_interval = NETRUN_DEFAULT_NODE_POLL_INTERVAL
	var/node_idle_poll_interval = NETRUN_DEFAULT_NODE_IDLE_POLL_INTERVAL
	var/node_update_interval = NETRUN_DEFAULT_NODE_UPDATE_INTERVAL
	var/list/priority_rotation = NETRUN_DEFAULT_TASK_PRIORITY_ROTATION
	var/list/late_after = list(NETRUN_DEFAULT_TASK_CRITICAL_LATE_AFTER, NETRUN_DEFAULT_TASK_NORMAL_LATE_AFTER, NETRUN_DEFAULT_TASK_BACKGROUND_LATE_AFTER)

/datum/netrun_execution_limits/proc/bounded(value, fallback, minimum, maximum, integer = FALSE)
	if(!IS_FINITE(value))
		value = fallback
	return clamp(integer ? round(value) : value, minimum, maximum)

/datum/netrun_execution_limits/proc/interval(value, fallback)
	return bounded(value, fallback, NETRUN_EXECUTION_MIN_INTERVAL, NETRUN_EXECUTION_MAX_INTERVAL)

/// Compare scalars without allocating a fresh signature. The rotation also checks
/// its saved values, so admin edits in place apply on the very next worker pass.
/datum/netrun_execution_limits/proc/matches(datum/controller/subsystem/netrun/worker)
	if(!source_values)
		return FALSE
	for(var/field in source_fields)
		if(source_values[field] != worker.vars[field])
			return FALSE
	var/list/requested = worker.task_priority_rotation
	if(!islist(requested))
		return requested == source_rotation
	if(!source_rotation_values || length(requested) != length(source_rotation_values))
		return FALSE
	for(var/index in 1 to length(requested))
		if(requested[index] != source_rotation_values[index])
			return FALSE
	return TRUE

/datum/netrun_execution_limits/proc/configure(datum/controller/subsystem/netrun/worker)
	adaptive_budget = !!worker.task_adaptive_budget
	budget_ms = bounded(worker.task_budget_ms, NETRUN_DEFAULT_TASK_BUDGET_MS, NETRUN_EXECUTION_MIN_BUDGET_MS, NETRUN_EXECUTION_MAX_BUDGET_MS)
	min_budget_ms = bounded(worker.task_min_budget_ms, NETRUN_DEFAULT_TASK_MIN_BUDGET_MS, NETRUN_EXECUTION_MIN_BUDGET_MS, budget_ms)
	pressure_tick_usage = bounded(worker.task_pressure_tick_usage, NETRUN_DEFAULT_TASK_PRESSURE_TICK_USAGE, 1, NETRUN_EXECUTION_MAX_PRESSURE_TICK_USAGE)
	max_per_pass = bounded(worker.task_max_per_pass, NETRUN_DEFAULT_TASK_MAX_PER_PASS, 1, NETRUN_EXECUTION_MAX_TASKS_PER_PASS, TRUE)
	min_per_pass = bounded(worker.task_min_per_pass, NETRUN_DEFAULT_TASK_MIN_PER_PASS, 1, max_per_pass, TRUE)
	interactive_burst = bounded(worker.task_interactive_burst, NETRUN_DEFAULT_INTERACTIVE_BURST, 1, NETRUN_EXECUTION_MAX_TASKS_PER_PASS, TRUE)
	interactive_priority = bounded(worker.task_interactive_priority, NETRUN_DEFAULT_INTERACTIVE_PRIORITY, NETRUN_TASK_CRITICAL, NETRUN_TASK_BACKGROUND, TRUE)
	interactive_flush = !!worker.ui_interactive_flush
	cost_floor_ms = bounded(worker.task_cost_floor_ms, NETRUN_DEFAULT_TASK_COST_FLOOR_MS, NETRUN_EXECUTION_MIN_BUDGET_MS, NETRUN_EXECUTION_MAX_BUDGET_MS)
	initial_cost_ms = bounded(worker.task_initial_cost_ms, NETRUN_DEFAULT_TASK_INITIAL_COST_MS, cost_floor_ms, NETRUN_EXECUTION_MAX_BUDGET_MS)
	cost_smoothing = bounded(worker.task_cost_smoothing, NETRUN_DEFAULT_TASK_COST_SMOOTHING, 0, 1)
	population_interval = interval(worker.task_population_interval, NETRUN_DEFAULT_TASK_POPULATION_INTERVAL)
	apc_operations = bounded(worker.apc_prebuild_operations, NETRUN_DEFAULT_APC_PREBUILD_OPERATIONS, 1, NETRUN_EXECUTION_MAX_PREBUILD_OPERATIONS, TRUE)
	route_refresh_interval = interval(worker.route_refresh_interval, NETRUN_DEFAULT_ROUTE_REFRESH_INTERVAL)
	route_expiry_interval = interval(worker.route_expiry_interval, NETRUN_DEFAULT_ROUTE_EXPIRY_INTERVAL)
	ui_refresh_interval = interval(worker.ui_refresh_interval, NETRUN_DEFAULT_UI_REFRESH_INTERVAL)
	ui_activity_lease = max(ui_refresh_interval, interval(worker.ui_activity_lease, NETRUN_DEFAULT_UI_ACTIVITY_LEASE))
	node_activity_duration = interval(worker.node_activity_duration, NETRUN_DEFAULT_NODE_ACTIVITY_DURATION)
	node_poll_interval = interval(worker.node_poll_interval, NETRUN_DEFAULT_NODE_POLL_INTERVAL)
	node_update_interval = interval(worker.node_update_interval, NETRUN_DEFAULT_NODE_UPDATE_INTERVAL)
	node_idle_poll_interval = max(node_poll_interval, node_update_interval, interval(worker.node_idle_poll_interval, NETRUN_DEFAULT_NODE_IDLE_POLL_INTERVAL))
	late_after[NETRUN_TASK_CRITICAL] = interval(worker.task_critical_late_after, NETRUN_DEFAULT_TASK_CRITICAL_LATE_AFTER)
	late_after[NETRUN_TASK_NORMAL] = interval(worker.task_normal_late_after, NETRUN_DEFAULT_TASK_NORMAL_LATE_AFTER)
	late_after[NETRUN_TASK_BACKGROUND] = interval(worker.task_background_late_after, NETRUN_DEFAULT_TASK_BACKGROUND_LATE_AFTER)
	priority_rotation.Cut()
	var/list/requested = worker.task_priority_rotation
	if(!islist(requested) || !length(requested))
		requested = NETRUN_DEFAULT_TASK_PRIORITY_ROTATION
	// Reserve one slot per priority: even a malformed rotation cannot starve a work class.
	for(var/i in 1 to min(length(requested), NETRUN_EXECUTION_MAX_PRIORITY_ROTATION - NETRUN_TASK_BACKGROUND))
		var/priority = requested[i]
		if(IS_FINITE(priority) && priority == round(priority) && priority >= NETRUN_TASK_CRITICAL && priority <= NETRUN_TASK_BACKGROUND)
			priority_rotation += priority
	for(var/priority in NETRUN_TASK_CRITICAL to NETRUN_TASK_BACKGROUND)
		if(!(priority in priority_rotation))
			priority_rotation += priority
	source_values = list()
	for(var/field in source_fields)
		source_values[field] = worker.vars[field]
	source_rotation = worker.task_priority_rotation
	source_rotation_values = islist(source_rotation) ? worker.task_priority_rotation.Copy() : null
	configuration_revision++

/datum/netrun_execution_limits/proc/budget_for(tick_usage)
	var/pressure = adaptive_budget ? clamp(tick_usage / pressure_tick_usage, 0, 1) : 0
	return clamp(budget_ms * (1 - pressure), min_budget_ms, budget_ms)

/datum/netrun_execution_limits/proc/tasks_for(available_ms, average_ms)
	if(!IS_FINITE(average_ms))
		average_ms = initial_cost_ms
	return clamp(round(available_ms / max(average_ms, cost_floor_ms)), min_per_pass, max_per_pass)
