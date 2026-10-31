/// Statistics contain values only. Building a report never dispatches or reorders work.
/datum/netrun_task_scheduler/proc/statistics()
	var/list/types = list()
	var/list/by_kind = list()
	for(var/kind in profiles)
		var/datum/netrun_task_profile/profile = profiles[kind]
		var/list/entry = list(
			"kind" = kind,
			"requests" = profile.requests,
			"created" = profile.created,
			"merged" = profile.merged,
			"renewed" = profile.renewed,
			"cancelled" = profile.cancelled,
			"calls" = profile.calls,
			"total_ms" = profile.total_ms,
			"average_ms" = profile.average_ms,
			"peak_ms" = profile.peak_ms,
			"total_wait_ds" = profile.total_wait_ds,
			"peak_wait_ds" = profile.peak_wait_ds,
			"overdue" = profile.overdue,
			"task_overruns" = profile.task_overruns,
			"pending" = 0,
			"running" = 0,
			"oldest_wait_ds" = 0,
		)
		types += list(entry)
		by_kind[kind] = entry
	var/list/tasks = list()
	// Running tasks are always shown first; the remaining sample contains the
	// oldest pending entries. The sample never owns a reference to a game object.
	for(var/key in running_by_key)
		var/datum/netrun_task/task = running_by_key[key]
		var/list/entry = by_kind[task.kind]
		entry["running"]++
		if(length(tasks) < 32)
			tasks += list(task.statistics_entry(TRUE))
	var/running_samples = length(tasks)
	for(var/key in by_key)
		var/datum/netrun_task/task = by_key[key]
		var/list/entry = by_kind[task.kind]
		entry["pending"]++
		var/wait_ds = max(0, world.time - task.enqueued_at)
		entry["oldest_wait_ds"] = max(entry["oldest_wait_ds"], wait_ds)
		var/position = running_samples + 1
		while(position <= length(tasks))
			var/list/sample = tasks[position]
			if(wait_ds > sample["wait_ds"])
				break
			position++
		if(position <= 32)
			tasks.Insert(position, list(task.statistics_entry(FALSE)))
			if(length(tasks) > 32)
				tasks.Cut(33)
	return list(
		"sampled_at" = world.time,
		"started_at" = statistics_started_at,
		"pending" = length(by_key),
		"running" = length(running_by_key),
		"peak_pending" = peak_pending,
		"completed" = completed,
		"merged" = merged,
		"cancelled" = cancelled,
		"last_budget_ms" = last_budget_ms,
		"last_execution_ms" = last_execution_ms,
		"budget_overruns" = budget_overruns,
		"task_overruns" = task_overruns,
		"types" = types,
		"tasks" = tasks,
	)

/datum/netrun_task/proc/statistics_entry(running)
	var/datum/subject = target()
	return list(
		"key" = key,
		"kind" = kind,
		"target_type" = subject ? "[subject.type]" : (target_ref ? "удалён" : "global"),
		"priority" = priority,
		"interactive" = interactive,
		"state" = running ? "running" : "pending",
		"wait_ds" = max(0, world.time - (running ? started_at : enqueued_at)),
		"last_request_age_ds" = max(0, world.time - last_requested_at),
		"rerun" = rerun_requested,
	)
