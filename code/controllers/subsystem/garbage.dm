/*!
## Debugging GC issues

In order to debug `qdel()` failures, there are several tools available.
To enable these tools, define `TESTING` in [_compile_options.dm](https://github.com/tgstation/-tg-station/blob/master/code/_compile_options.dm).

First is a verb called "Find References", which lists **every** refererence to an object in the world. This allows you to track down any indirect or obfuscated references that you might have missed.

Complementing this is another verb, "qdel() then Find References".
This does exactly what you'd expect; it calls `qdel()` on the object and then it finds all references remaining.
This is great, because it means that `Destroy()` will have been called before it starts to find references,
so the only references you'll find will be the ones preventing the object from `qdel()`ing gracefully.

If you have a datum or something you are not destroying directly (say via the singulo),
the next tool is `QDEL_HINT_FINDREFERENCE`. You can return this in `Destroy()` (where you would normally `return ..()`),
to print a list of references once it enters the GC queue.

Finally is a verb, "Show qdel() Log", which shows the deletion log that the garbage subsystem keeps. This is helpful if you are having race conditions or need to review the order of deletions.

Note that for any of these tools to work `TESTING` must be defined.
By using these methods of finding references, you can make your life far, far easier when dealing with `qdel()` failures.
*/

SUBSYSTEM_DEF(garbage)
	name = "Garbage"
	priority = FIRE_PRIORITY_GARBAGE
	wait = 1 SECONDS
	flags = SS_POST_FIRE_TIMING|SS_BACKGROUND|SS_NO_INIT
	runlevels = RUNLEVELS_DEFAULT | RUNLEVEL_LOBBY
	init_order = INIT_ORDER_GARBAGE

	/// Deciseconds to wait before promoting an entry to the next queue level.
	var/list/collection_timeout = list(GC_SOFTCHECK_TIMEOUT, GC_WARNFAIL_TIMEOUT, GC_HARDDEL_TIMEOUT)

	// Stat tracking
	var/delslasttick = 0 // number of del()'s we've done this tick
	var/gcedlasttick = 0 // number of things that gc'ed last tick
	var/totaldels = 0
	var/totalgcs = 0

	var/highest_del_ms = 0
	var/highest_del_type_string = ""

	var/list/pass_counts
	var/list/fail_counts

	/// Per-type qdel statistics datums, keyed by type path.
	var/list/items = list()

	// EMA stat tracking
	/// Exponential moving average: confirmed warnfail leaks per minute.
	var/leak_rate_avg = 0
	/// Exponential moving average: milliseconds spent hard-deleting per fire.
	var/harddel_ms_avg = 0
	/// Fires since last leak_rate update (denominator).
	var/leak_rate_fires = 0
	/// Confirmed warnfail leaks accumulated since last leak_rate update.
	var/leak_rate_fail_accumulator = 0

	/// Peak live queue depth per level seen this round.
	var/list/peak_queue_depths
	/// Effective hard-delete budget used on the last hard-delete pass.
	var/last_hd_budget_ms = GC_HARDDEL_BUDGET_MIN_MS
	/// Effective hard-delete cap used on the last hard-delete pass.
	var/last_hd_cap = GC_HARDDEL_MAX_PER_FIRE
	/// Effective hard-delete mode used on the last hard-delete pass.
	var/last_hd_mode = GC_HARDDEL_MODE_HOLD
	/// Whether overflow hard-delete mode was active on the last hard-delete pass.
	var/last_hd_overflow_mode = FALSE
	/// Whether garbage is currently scheduled as a background subsystem.
	var/last_hd_background_scheduling = TRUE
	/// Wall-clock time spent in the most recent hard-delete pass.
	var/last_hd_pass_ms = 0
	/// Rolling ratio of hard-delete passes that yielded early.
	var/last_hd_yield_ratio = 0
	/// TRUE when the rolling yield ratio is high despite the pass staying under its local budget.
	var/last_hd_mc_clipped = FALSE
	/// Recent harddelete queue growth over the last sampled interval.
	var/last_q3_depth_delta = 0
	/// Recent harddelete queue growth rate in entries per second.
	var/last_q3_depth_delta_per_second = 0
	/// Recent /datum/gas_mixture qdel rate in qdel()s per second.
	var/gas_mixture_qdel_rate_per_second = 0
	/// Recent /datum/gas_mixture hard-delete rate in deletes per second.
	var/gas_mixture_harddel_rate_per_second = 0
	/// World-time delta covered by the last queue-health sample window.
	var/last_queue_health_window_ds = 0
	/// Last world.time at which queue-health rates were sampled.
	var/last_queue_health_sample_time = 0
	/// Last sampled harddelete queue depth.
	var/last_q3_depth_sample = 0
	/// Last sampled /datum/gas_mixture qdel count.
	var/last_gas_mixture_qdel_sample = 0
	/// Last sampled /datum/gas_mixture hard-delete count.
	var/last_gas_mixture_harddel_sample = 0
	/// TRUE when the most recent queue-health sample qualifies for HOLD mode.
	var/last_hd_hold_sample_eligible = FALSE
	/// Consecutive HOLD-eligible queue-health samples.
	var/hd_hold_eligibility_streak = 0
	/// Rolling history of hard-delete pass yields.
	var/list/harddel_yield_history = list()
	/// Sum of the rolling hard-delete yield history.
	var/harddel_yield_total = 0
	/// Transient per-fire flag: did this fire reach the hard-delete stage?
	var/tmp/last_fire_hd_reached = FALSE
	/// Transient per-fire flag: did this fire yield during the hard-delete stage?
	var/tmp/last_fire_hd_yield = FALSE

	// Ring buffers — bounded size, O(1) cost per event.
	/// Last GC_FAILURE_RING_SIZE softcheck/warnfail events. Each entry: list(world.time, type_string, queue_level, qdel_hint).
	var/list/recent_failures = list()
	/// Last GC_HARDDEL_RING_SIZE hard deletes. Each entry: list(world.time, type_string, ms_cost).
	var/list/recent_hard_deletes = list()
	/// Periodic queue depth snapshots. Each entry: list(world.time, depth1, depth2, depth3).
	var/list/queue_depth_history = list()
	/// Counter for depth sampling — sample every GC_DEPTH_SAMPLE_INTERVAL fires.
	var/queue_depth_sample_counter = 0


	// Parallel array queue storage.
	// queue_origin_times[level] = list of world.time numerics when each datum first entered GC.
	// queue_times[level] = list of world.time numerics when each entry was queued.
	// queue_refs[level]  = list of "\ref[D]" strings.
	// queue_hints[level] = list of qdel_hint values (or null).
	// queue_types[level] = list of "[D.type]" strings (preserved after GC for diagnostics).
	// queue_heads[level] = integer index of the first unprocessed slot.
	// Slots are tombstoned (set to null) when processed, compacted when head > GC_COMPACT_THRESHOLD.
	var/list/queue_origin_times
	var/list/queue_times
	var/list/queue_refs
	var/list/queue_hints
	var/list/queue_types
	var/list/queue_heads

	#ifdef REFERENCE_TRACKING
	var/list/reference_find_on_fail = list()
	#ifdef UNIT_TESTS
	/// Test hook: skip async ref scans while still exercising GC control flow.
	var/test_ref_scan_skip_async = FALSE
	#endif
	#ifdef REFERENCE_TRACKING_DEBUG
	/// Should we save found refs — used for unit testing.
	var/should_save_refs = FALSE
	#endif
	#endif

	#ifdef GC_PROFILER
	/// Total fire() invocations this round — used for per-minute type dump cadence.
	var/profiler_fire_count = 0
	// Per-fire slot counters — reset at the top of each fire().
	var/profiler_sc_checked = 0  // non-tombstoned softcheck slots examined
	var/profiler_sc_tomb = 0     // tombstoned softcheck slots skipped
	var/profiler_wf_checked = 0
	var/profiler_wf_tomb = 0
	var/profiler_hd_checked = 0
	var/profiler_hd_tomb = 0
	// TRUE if MC_TICK_CHECK fired (early return) at that level this fire.
	var/profiler_sc_yield = FALSE
	var/profiler_wf_yield = FALSE
	var/profiler_hd_yield = FALSE
	var/profiler_hd_budget_ms = 0
	var/profiler_hd_cap = 0
	var/profiler_hd_mode = GC_HARDDEL_MODE_HOLD
	var/profiler_hd_background = TRUE
	var/profiler_hd_yield_ratio = 0
	var/profiler_hd_mc_clipped = FALSE
	var/profiler_hd_overflow_mode = FALSE
	/// MaybeCompact() invocations that actually ran this fire.
	var/profiler_compact_events = 0
	#endif


/datum/controller/subsystem/garbage/PreInit()
	InitQueues()
	last_hd_budget_ms = GetConfiguredHardDeleteBudgetMinMs()
	last_hd_cap = GetConfiguredHardDeleteHoldMaxPerFire()
	last_hd_mode = GC_HARDDEL_MODE_HOLD
	last_hd_background_scheduling = TRUE
	#ifdef GC_PROFILER
	rustg_log_write("data/logs/gc_profiler.csv", "world_time,fire_num,q1_depth,q2_depth,q3_depth,sc_ms,sc_checked,sc_tomb,sc_passed,sc_failed,sc_yield,wf_ms,wf_checked,wf_tomb,wf_passed,wf_failed,wf_yield,hd_ms,hd_checked,hd_tomb,hd_passed,hd_failed,hd_yield,total_ms,leak_rate_ema,harddel_ms_ema,hd_budget_ms,hd_cap,hd_overflow_mode,compact_events,hd_mode,hd_background,hd_yield_ratio,hd_mc_clipped\n", "false")
	rustg_log_write("data/logs/gc_profiler_types.csv", "world_time,type_path,qdels,failures,warnfails,hard_deletes,hard_delete_time_ms,hard_delete_max_ms,destroy_time_ms,slept_destroy,no_hint,softfail_alert_fails\n", "false")
	rustg_log_write("data/logs/gc_profiler_compact.csv", "world_time,level,head,old_len,compact_ms\n", "false")
	#endif

/datum/controller/subsystem/garbage/stat_entry(msg)
	var/list/depths = list()
	for (var/i in 1 to GC_QUEUE_COUNT)
		depths += GetQueueDepth(i)
	msg += "Q:[depths.Join(",")]|D:[delslasttick]|G:[gcedlasttick]|"
	msg += "GR:"
	if (!(delslasttick + gcedlasttick))
		msg += "n/a|"
	else
		msg += "[round((gcedlasttick / (delslasttick + gcedlasttick)) * 100, 0.01)]%|"
	msg += "TD:[totaldels]|TG:[totalgcs]|"
	if (!(totaldels + totalgcs))
		msg += "n/a|"
	else
		msg += "TGR:[round((totalgcs / (totaldels + totalgcs)) * 100, 0.01)]%"
	msg += "|LR:[round(leak_rate_avg, 0.01)]/мин"
	msg += "|HD:[round(harddel_ms_avg, 0.1)]мс"
	msg += " P:[pass_counts.Join(",")]"
	msg += "|F:[fail_counts.Join(",")]"
	return ..()

/datum/controller/subsystem/garbage/Shutdown()
	var/list/dellog = list()

	sortTim(items, cmp=GLOBAL_PROC_REF(cmp_qdel_item_time), associative = TRUE)
	for (var/path in items)
		var/datum/qdel_item/I = items[path]
		dellog += "Path: [path]"
		if (I.qdel_flags & QDEL_ITEM_SUSPENDED_FOR_LAG)
			dellog += "\tSUSPENDED FOR LAG"
		if (I.failures)
			dellog += "\tFailures: [I.failures]"
		if (I.warnfail_count)
			dellog += "\tWarnfail: [I.warnfail_count]"
		if (I.softfail_alert_failures)
			dellog += "\tSoftfail alerts: [I.softfail_alert_failures]"
		dellog += "\tqdel() Count: [I.qdels]"
		dellog += "\tDestroy() Cost: [I.destroy_time]ms"
		if (I.hard_deletes)
			dellog += "\tTotal Hard Deletes: [I.hard_deletes]"
			dellog += "\tTime Spent Hard Deleting: [I.hard_delete_time]ms"
			dellog += "\tHighest Time Spent Hard Deleting: [I.hard_delete_max]ms"
			if (I.hard_deletes_over_threshold)
				dellog += "\tHard Deletes Over Threshold: [I.hard_deletes_over_threshold]"
		if (I.slept_destroy)
			dellog += "\tSleeps: [I.slept_destroy]"
		if (I.no_respect_force)
			dellog += "\tIgnored force: [I.no_respect_force] times"
		if (I.no_hint)
			dellog += "\tNo hint: [I.no_hint] times"
	log_qdel(dellog.Join("\n"))

/datum/controller/subsystem/garbage/fire()
	#ifdef GC_PROFILER
	profiler_fire_count++
	var/profiler_fire_start = TICK_USAGE
	var/profiler_q1 = GetQueueDepth(GC_QUEUE_SOFTCHECK)
	var/profiler_q2 = GetQueueDepth(GC_QUEUE_WARNFAIL)
	var/profiler_q3 = GetQueueDepth(GC_QUEUE_HARDDELETE)
	profiler_sc_checked = 0; profiler_sc_tomb = 0; profiler_sc_yield = FALSE
	profiler_wf_checked = 0; profiler_wf_tomb = 0; profiler_wf_yield = FALSE
	profiler_hd_checked = 0; profiler_hd_tomb = 0; profiler_hd_yield = FALSE
	profiler_hd_budget_ms = 0; profiler_hd_cap = 0; profiler_hd_overflow_mode = FALSE
	profiler_hd_mode = last_hd_mode
	profiler_hd_background = last_hd_background_scheduling
	profiler_hd_yield_ratio = last_hd_yield_ratio
	profiler_hd_mc_clipped = last_hd_mc_clipped
	profiler_compact_events = 0
	var/list/profiler_pass_snap = pass_counts.Copy()
	var/list/profiler_fail_snap = fail_counts.Copy()
	#endif

	// Reset per-tick counters at the start of softcheck processing.
	delslasttick = 0
	gcedlasttick = 0
	last_hd_pass_ms = 0
	last_hd_mc_clipped = FALSE
	last_fire_hd_reached = FALSE
	last_fire_hd_yield = FALSE
	#ifdef GC_PROFILER
	profiler_hd_mc_clipped = FALSE
	#endif

	#ifdef GC_PROFILER
	var/profiler_t_sc = TICK_USAGE
	#endif
	var/stop_after_level = HandleLevel(GC_QUEUE_SOFTCHECK)
	#ifdef GC_PROFILER
	var/profiler_sc_ms = TICK_USAGE_TO_MS(profiler_t_sc)
	#endif
	if (state != SS_RUNNING || stop_after_level)
		#ifdef GC_PROFILER
		GCProfilerWriteFire(profiler_q1, profiler_q2, profiler_q3, profiler_sc_ms, -1, -1, profiler_fire_start, profiler_pass_snap, profiler_fail_snap)
		#endif
		FinalizeFireMetrics()
		return

	#ifdef GC_PROFILER
	var/profiler_t_wf = TICK_USAGE
	#endif
	stop_after_level = HandleLevel(GC_QUEUE_WARNFAIL)
	#ifdef GC_PROFILER
	var/profiler_wf_ms = TICK_USAGE_TO_MS(profiler_t_wf)
	#endif
	if (state != SS_RUNNING || stop_after_level)
		#ifdef GC_PROFILER
		GCProfilerWriteFire(profiler_q1, profiler_q2, profiler_q3, profiler_sc_ms, profiler_wf_ms, -1, profiler_fire_start, profiler_pass_snap, profiler_fail_snap)
		#endif
		FinalizeFireMetrics()
		return

	var/hd_fire_start = TICK_USAGE
	stop_after_level = HandleLevel(GC_QUEUE_HARDDELETE)
	last_fire_hd_reached = TRUE
	var/hd_fire_ms = TICK_USAGE_TO_MS(hd_fire_start)
	#ifdef GC_PROFILER
	var/profiler_hd_ms = hd_fire_ms
	#endif
	FinalizeHardDeleteFireMetrics(hd_fire_ms)
	#ifdef GC_PROFILER
	GCProfilerWriteFire(profiler_q1, profiler_q2, profiler_q3, profiler_sc_ms, profiler_wf_ms, profiler_hd_ms, profiler_fire_start, profiler_pass_snap, profiler_fail_snap)
	if (profiler_fire_count % 60 == 0)
		GCProfilerWriteTypes()
	#endif
	if (stop_after_level)
		FinalizeFireMetrics()
		return
	if (state == SS_PAUSED)
		state = SS_RUNNING
		FinalizeFireMetrics()
		return
	// If paused by hard-delete lag, let fire() be re-called next tick normally.
	FinalizeFireMetrics()

/datum/controller/subsystem/garbage/proc/InitQueues()
	if (!isnull(queue_times))
		return // Already initialized (Recover path called us first)
	queue_origin_times = new(GC_QUEUE_COUNT)
	queue_times  = new(GC_QUEUE_COUNT)
	queue_refs   = new(GC_QUEUE_COUNT)
	queue_hints  = new(GC_QUEUE_COUNT)
	queue_types  = new(GC_QUEUE_COUNT)
	queue_heads  = new(GC_QUEUE_COUNT)
	pass_counts  = new(GC_QUEUE_COUNT)
	fail_counts  = new(GC_QUEUE_COUNT)
	peak_queue_depths = new(GC_QUEUE_COUNT)
	for (var/i in 1 to GC_QUEUE_COUNT)
		queue_origin_times[i] = list()
		queue_times[i]      = list()
		queue_refs[i]       = list()
		queue_hints[i]      = list()
		queue_types[i]      = list()
		queue_heads[i]      = 1
		pass_counts[i]      = 0
		fail_counts[i]      = 0
		peak_queue_depths[i] = 0

/datum/controller/subsystem/garbage/proc/SaveQueueLevel(level, list/origins, list/times, list/refs, list/hints, list/types)
	queue_origin_times[level] = origins
	queue_times[level] = times
	queue_refs[level] = refs
	queue_hints[level] = hints
	queue_types[level] = types

/datum/controller/subsystem/garbage/proc/GetQueueDepth(level)
	if (level < 1 || level > GC_QUEUE_COUNT)
		return 0
	return max(length(queue_times[level]) - queue_heads[level] + 1, 0)

/datum/controller/subsystem/garbage/proc/GetProcessedQueueSlots(level)
	if (level < 1 || level > GC_QUEUE_COUNT)
		return 0
	return max(queue_heads[level] - 1, 0)

/datum/controller/subsystem/garbage/proc/GetConfiguredHardDeleteBudgetMinMs()
	var/value = CONFIG_GET(number/gc_harddel_budget_min_ms)
	if (!isnum(value) || value <= 0)
		return GC_HARDDEL_BUDGET_MIN_MS
	return value

/datum/controller/subsystem/garbage/proc/GetConfiguredHardDeleteBudgetMaxMs(budget_min_ms = null)
	if (!isnum(budget_min_ms))
		budget_min_ms = GetConfiguredHardDeleteBudgetMinMs()
	var/value = CONFIG_GET(number/gc_harddel_budget_max_ms)
	if (!isnum(value) || value < budget_min_ms)
		return max(budget_min_ms, GC_HARDDEL_BUDGET_MAX_MS)
	return value

/datum/controller/subsystem/garbage/proc/GetConfiguredHardDeleteHoldMaxPerFire(base_cap = null)
	if (!isnum(base_cap))
		base_cap = GetConfiguredHardDeleteMaxPerFire()
	var/value = CONFIG_GET(number/gc_harddel_hold_max_per_fire)
	if (!isnum(value) || value < 1)
		return clamp(GC_HARDDEL_HOLD_MAX_PER_FIRE, 1, max(base_cap, 1))
	return clamp(round(value), 1, max(base_cap, 1))

/datum/controller/subsystem/garbage/proc/GetConfiguredHardDeleteMaxPerFire()
	var/value = CONFIG_GET(number/gc_harddel_max_per_fire)
	if (!isnum(value) || value < 1)
		return max(GC_HARDDEL_MAX_PER_FIRE, 1)
	return round(value)

/datum/controller/subsystem/garbage/proc/GetConfiguredHardDeleteRecoverThreshold()
	var/value = CONFIG_GET(number/gc_harddel_recover_threshold)
	if (!isnum(value) || value < 0)
		return GC_HARDDEL_RECOVER_THRESHOLD
	return round(value)

/datum/controller/subsystem/garbage/proc/GetConfiguredHardDeleteTargetQ3DeltaPerSecond()
	var/value = CONFIG_GET(number/gc_harddel_target_q3_delta_per_second)
	if (!isnum(value))
		return GC_HARDDEL_TARGET_Q3_DELTA_PER_SECOND
	return value

/datum/controller/subsystem/garbage/proc/GetConfiguredHardDeleteModeHysteresisSamples()
	var/value = CONFIG_GET(number/gc_harddel_mode_hysteresis_samples)
	if (!isnum(value) || value < 1)
		return GC_HARDDEL_MODE_HYSTERESIS_SAMPLES
	return round(value)

/datum/controller/subsystem/garbage/proc/GetConfiguredHardDeleteOverflowThreshold()
	var/value = CONFIG_GET(number/gc_harddel_overflow_threshold)
	if (!isnum(value) || value < 0)
		return GC_HARDDEL_OVERFLOW_THRESHOLD
	return round(value)

/datum/controller/subsystem/garbage/proc/GetConfiguredHardDeleteOverflowBudgetMaxMs(budget_max_ms = null)
	if (!isnum(budget_max_ms))
		budget_max_ms = GetConfiguredHardDeleteBudgetMaxMs()
	var/value = CONFIG_GET(number/gc_harddel_overflow_budget_max_ms)
	if (!isnum(value) || value < budget_max_ms)
		return max(budget_max_ms, GC_HARDDEL_OVERFLOW_BUDGET_MAX_MS)
	return value

/datum/controller/subsystem/garbage/proc/GetConfiguredHardDeleteOverflowMaxPerFire(base_cap = null)
	if (!isnum(base_cap))
		base_cap = GetConfiguredHardDeleteMaxPerFire()
	var/value = CONFIG_GET(number/gc_harddel_overflow_max_per_fire)
	if (!isnum(value) || value < base_cap)
		return max(base_cap, GC_HARDDEL_OVERFLOW_MAX_PER_FIRE)
	return round(value)

/datum/controller/subsystem/garbage/proc/GetConfiguredHardDeleteLobbyBudgetMs()
	var/value = CONFIG_GET(number/gc_harddel_lobby_budget_ms)
	if (!isnum(value) || value <= 0)
		return GC_HARDDEL_LOBBY_BUDGET_MS
	return value

/datum/controller/subsystem/garbage/proc/GetConfiguredHardDeleteLobbyMaxPerFire()
	var/value = CONFIG_GET(number/gc_harddel_lobby_max_per_fire)
	if (!isnum(value) || value < 1)
		return max(GC_HARDDEL_LOBBY_MAX_PER_FIRE, 1)
	return round(value)

/datum/controller/subsystem/garbage/proc/GetHardDeleteModeText(mode = null)
	if (!isnum(mode))
		mode = last_hd_mode
	switch (mode)
		if (GC_HARDDEL_MODE_HOLD)
			return "HOLD"
		if (GC_HARDDEL_MODE_RECOVER)
			return "RECOVER"
		if (GC_HARDDEL_MODE_OVERFLOW)
			return "OVERFLOW"
		if (GC_HARDDEL_MODE_LOBBY)
			return "LOBBY"
	return "UNKNOWN"

/datum/controller/subsystem/garbage/proc/GetHardDeleteMode(queue_depth)
	// During lobby, always use aggressive mode — there's tons of spare CPU.
	if (Master.current_runlevel == RUNLEVEL_LOBBY)
		return GC_HARDDEL_MODE_LOBBY

	var/overflow_threshold = GetConfiguredHardDeleteOverflowThreshold()
	if (queue_depth >= overflow_threshold)
		return GC_HARDDEL_MODE_OVERFLOW

	var/recover_threshold = GetConfiguredHardDeleteRecoverThreshold()
	if (queue_depth >= recover_threshold)
		return GC_HARDDEL_MODE_RECOVER

	if (queue_depth <= 0)
		return GC_HARDDEL_MODE_HOLD

	if (!last_queue_health_window_ds)
		return GC_HARDDEL_MODE_RECOVER

	if (last_hd_mode == GC_HARDDEL_MODE_HOLD)
		return last_hd_hold_sample_eligible ? GC_HARDDEL_MODE_HOLD : GC_HARDDEL_MODE_RECOVER

	if (hd_hold_eligibility_streak >= GetConfiguredHardDeleteModeHysteresisSamples())
		return GC_HARDDEL_MODE_HOLD

	return GC_HARDDEL_MODE_RECOVER

/datum/controller/subsystem/garbage/proc/ApplyHardDeleteMode(mode)
	last_hd_mode = mode
	last_hd_overflow_mode = (mode == GC_HARDDEL_MODE_OVERFLOW)
	last_hd_background_scheduling = (mode == GC_HARDDEL_MODE_HOLD)
	if (last_hd_background_scheduling)
		flags |= SS_BACKGROUND
	else
		flags &= ~SS_BACKGROUND

/datum/controller/subsystem/garbage/proc/FinalizeHardDeleteFireMetrics(hd_ms)
	last_hd_pass_ms = hd_ms
	if (!last_fire_hd_reached)
		last_hd_mc_clipped = FALSE
		return

	var/yielded = last_fire_hd_yield ? 1 : 0
	if (length(harddel_yield_history) >= GC_HARDDEL_YIELD_HISTORY_SIZE)
		harddel_yield_total -= harddel_yield_history[1]
		harddel_yield_history.Cut(1, 2)
	harddel_yield_history += yielded
	harddel_yield_total += yielded
	last_hd_yield_ratio = harddel_yield_total / max(length(harddel_yield_history), 1)
	last_hd_mc_clipped = (last_hd_yield_ratio >= 0.5) && (hd_ms > 0.1) && (hd_ms < last_hd_budget_ms * 0.9)

	#ifdef GC_PROFILER
	profiler_hd_mode = last_hd_mode
	profiler_hd_background = last_hd_background_scheduling
	profiler_hd_yield_ratio = last_hd_yield_ratio
	profiler_hd_mc_clipped = last_hd_mc_clipped
	#endif

/datum/controller/subsystem/garbage/proc/FinalizeFireMetrics()
	if (++queue_depth_sample_counter >= GC_DEPTH_SAMPLE_INTERVAL)
		queue_depth_sample_counter = 0
		var/list/sample = list(world.time)
		for (var/level in 1 to GC_QUEUE_COUNT)
			sample += GetQueueDepth(level)
		if (length(queue_depth_history) >= GC_DEPTH_HISTORY_SIZE)
			queue_depth_history.Cut(1, 2)
		queue_depth_history += list(sample)

		var/current_q3_depth = sample[GC_QUEUE_HARDDELETE + 1]
		var/datum/qdel_item/gas_item = GetItem(/datum/gas_mixture)
		var/current_gas_qdels = gas_item ? gas_item.qdels : 0
		var/current_gas_harddels = gas_item ? gas_item.hard_deletes : 0
		var/sample_window_ds = world.time - last_queue_health_sample_time
		if (last_queue_health_sample_time && sample_window_ds > 0)
			last_queue_health_window_ds = sample_window_ds
			last_q3_depth_delta = current_q3_depth - last_q3_depth_sample
			last_q3_depth_delta_per_second = last_q3_depth_delta / (sample_window_ds / 10)
			gas_mixture_qdel_rate_per_second = (current_gas_qdels - last_gas_mixture_qdel_sample) / (sample_window_ds / 10)
			gas_mixture_harddel_rate_per_second = (current_gas_harddels - last_gas_mixture_harddel_sample) / (sample_window_ds / 10)
			last_hd_hold_sample_eligible = \
				current_q3_depth < GetConfiguredHardDeleteRecoverThreshold() && \
				last_q3_depth_delta_per_second <= GetConfiguredHardDeleteTargetQ3DeltaPerSecond() && \
				(gas_mixture_qdel_rate_per_second <= 0 || gas_mixture_harddel_rate_per_second <= gas_mixture_qdel_rate_per_second)
			if (last_hd_hold_sample_eligible)
				hd_hold_eligibility_streak = min(hd_hold_eligibility_streak + 1, GetConfiguredHardDeleteModeHysteresisSamples())
			else
				hd_hold_eligibility_streak = 0
		last_queue_health_sample_time = world.time
		last_q3_depth_sample = current_q3_depth
		last_gas_mixture_qdel_sample = current_gas_qdels
		last_gas_mixture_harddel_sample = current_gas_harddels

	// Update confirmed leak EMA roughly every 60 seconds (60 fires at 1s interval).
	leak_rate_fires++
	if (leak_rate_fires >= 60)
		var/new_rate = leak_rate_fail_accumulator // failures per 60 fires ≈ per minute
		leak_rate_avg = leak_rate_avg * 0.7 + new_rate * 0.3
		leak_rate_fail_accumulator = 0
		leak_rate_fires = 0

/datum/controller/subsystem/garbage/proc/PushRecentFailure(type_path, level, hint)
	if (length(recent_failures) >= GC_FAILURE_RING_SIZE)
		recent_failures.Cut(1, 2)
	recent_failures += list(list(world.time, "[type_path]", level, hint))

/datum/controller/subsystem/garbage/proc/PushWarnfailTime(datum/qdel_item/I)
	if (!I.failure_times)
		I.failure_times = list()
	if (length(I.failure_times) >= 10)
		I.failure_times.Cut(1, 2)
	I.failure_times += world.time

// ============================================================
// Queue engine
// ============================================================

/// Process all pending expired entries at the given queue level.
/// Uses tombstoning + head-pointer advancement — no static vars, safe across runtimes.
/datum/controller/subsystem/garbage/proc/HandleLevel(level)
	. = FALSE
	var/cut_off_time = world.time - collection_timeout[level]
	var/list/O = queue_origin_times[level]
	var/list/T = queue_times[level]
	var/list/R = queue_refs[level]
	var/list/H = queue_hints[level]
	var/list/Y = queue_types[level]
	var/head = queue_heads[level]
	var/qlen = length(T)
	// Hard-delete controller: fixed per-mode budgets/caps, with mode chosen from queue-health samples.
	var/hd_level_start = 0
	var/hd_budget = 0
	var/hd_count = 0
	var/hd_mode = GC_HARDDEL_MODE_HOLD
	var/hd_cap = GC_HARDDEL_MAX_PER_FIRE
	if (level == GC_QUEUE_HARDDELETE)
		var/hd_budget_min = GetConfiguredHardDeleteBudgetMinMs()
		var/hd_budget_max = GetConfiguredHardDeleteBudgetMaxMs(hd_budget_min)
		var/hd_overflow_budget_max = GetConfiguredHardDeleteOverflowBudgetMaxMs(hd_budget_max)
		hd_cap = GetConfiguredHardDeleteMaxPerFire()
		var/hd_hold_cap = GetConfiguredHardDeleteHoldMaxPerFire(hd_cap)
		var/hd_overflow_cap = GetConfiguredHardDeleteOverflowMaxPerFire(hd_cap)
		hd_level_start = TICK_USAGE
		var/queue_depth = max(qlen - head + 1, 0)
		hd_mode = GetHardDeleteMode(queue_depth)
		ApplyHardDeleteMode(hd_mode)
		switch (hd_mode)
			if (GC_HARDDEL_MODE_LOBBY)
				hd_budget = GetConfiguredHardDeleteLobbyBudgetMs()
				hd_cap = GetConfiguredHardDeleteLobbyMaxPerFire()
			if (GC_HARDDEL_MODE_HOLD)
				hd_budget = hd_budget_min
				hd_cap = hd_hold_cap
			if (GC_HARDDEL_MODE_RECOVER)
				hd_budget = hd_budget_max
			if (GC_HARDDEL_MODE_OVERFLOW)
				hd_budget = hd_overflow_budget_max
				hd_cap = hd_overflow_cap
		last_hd_budget_ms = hd_budget
		last_hd_cap = hd_cap
		#ifdef GC_PROFILER
		profiler_hd_budget_ms = hd_budget
		profiler_hd_cap = hd_cap
		profiler_hd_mode = hd_mode
		profiler_hd_background = last_hd_background_scheduling
		profiler_hd_overflow_mode = (hd_mode == GC_HARDDEL_MODE_OVERFLOW)
		#endif

	for (var/i in head to qlen)
		var/entry_time = T[i]
		if (isnull(entry_time)) // Tombstoned slot — already processed
			head = i + 1
			#ifdef GC_PROFILER
			switch (level)
				if (GC_QUEUE_SOFTCHECK)
					profiler_sc_tomb++
				if (GC_QUEUE_WARNFAIL)
					profiler_wf_tomb++
				if (GC_QUEUE_HARDDELETE)
					profiler_hd_tomb++
			#endif
			if (MC_TICK_CHECK || (hd_level_start && TICK_USAGE_TO_MS(hd_level_start) > hd_budget && pause()))
				SaveQueueLevel(level, O, T, R, H, Y)
				queue_heads[level] = head
				if (level == GC_QUEUE_HARDDELETE)
					last_fire_hd_yield = TRUE
				#ifdef GC_PROFILER
				switch (level)
					if (GC_QUEUE_SOFTCHECK)
						profiler_sc_yield = TRUE
					if (GC_QUEUE_WARNFAIL)
						profiler_wf_yield = TRUE
					if (GC_QUEUE_HARDDELETE)
						profiler_hd_yield = TRUE
				#endif
				return
			continue

		if (entry_time > cut_off_time)
			break // All remaining entries are newer; nothing more to do this fire

		var/origin_time = O[i]
		if (isnull(origin_time))
			origin_time = entry_time
		var/refID = R[i]
		var/queued_hint = H[i]

		// Pre-flight check for hard-delete: don't start an expensive del() if budget is tight.
		// Must happen BEFORE tombstoning — if we yield here, the entry stays intact for next fire.
		// We also resolve the datum early to avoid a second locate() call below.
		var/datum/D
		if (hd_level_start)
			D = locate(refID)
			if (D && D.gc_destroyed == entry_time)
				var/datum/qdel_item/harddel_item = GetOrCreateItem(D.type)
				var/type_avg_ms = harddel_item.hard_delete_avg_ms
				var/bootstrap_delete = (hd_count == 0) && ((type_avg_ms <= 0) || (hd_mode != GC_HARDDEL_MODE_HOLD))
				if (!bootstrap_delete)
					if (hd_count >= hd_cap)
						SaveQueueLevel(level, O, T, R, H, Y)
						queue_heads[level] = head
						MaybeCompact(level, head)
						return
					var/remaining = hd_budget - TICK_USAGE_TO_MS(hd_level_start)
					var/estimated_next_cost = (type_avg_ms > 0) ? type_avg_ms : max(harddel_ms_avg, 4)
					if (remaining < estimated_next_cost * 1.25)
						SaveQueueLevel(level, O, T, R, H, Y)
						queue_heads[level] = head
						MaybeCompact(level, head)
						return

		// Tombstone immediately so re-entrant qdels don't double-process this slot
		O[i] = null
		T[i] = null
		R[i] = null
		H[i] = null
		Y[i] = null
		head = i + 1

		#ifdef GC_PROFILER
		switch (level)
			if (GC_QUEUE_SOFTCHECK)
				profiler_sc_checked++
			if (GC_QUEUE_WARNFAIL)
				profiler_wf_checked++
			if (GC_QUEUE_HARDDELETE)
				profiler_hd_checked++
		#endif

		if (!hd_level_start)
			D = locate(refID)
		if (!D || D.gc_destroyed != entry_time)
			// GC succeeded — object was collected
			gcedlasttick++
			totalgcs++
			pass_counts[level]++
			#ifdef REFERENCE_TRACKING
			reference_find_on_fail -= refID
			#endif
		else
			if (hd_level_start)
				hd_count++
			fail_counts[level]++
			if (OnLevelFail(D, level, refID, origin_time, queued_hint))
				SaveQueueLevel(level, O, T, R, H, Y)
				queue_heads[level] = head
				MaybeCompact(level, head)
				return TRUE

		if (MC_TICK_CHECK || (hd_level_start && TICK_USAGE_TO_MS(hd_level_start) > hd_budget && pause()))
			SaveQueueLevel(level, O, T, R, H, Y)
			queue_heads[level] = head
			MaybeCompact(level, head)
			if (level == GC_QUEUE_HARDDELETE)
				last_fire_hd_yield = TRUE
			#ifdef GC_PROFILER
			switch (level)
				if (GC_QUEUE_SOFTCHECK)
					profiler_sc_yield = TRUE
				if (GC_QUEUE_WARNFAIL)
					profiler_wf_yield = TRUE
				if (GC_QUEUE_HARDDELETE)
					profiler_hd_yield = TRUE
			#endif
			return

	SaveQueueLevel(level, O, T, R, H, Y)
	queue_heads[level] = head
	MaybeCompact(level, head)

/// Handles a GC failure at the given queue level — logs, notifies, and escalates.
/datum/controller/subsystem/garbage/proc/OnLevelFail(datum/D, level, refID, origin_time, hint)
	. = FALSE
	var/type = D.type
	var/datum/qdel_item/I = GetOrCreateItem(type)

	switch (level)
		if (GC_QUEUE_SOFTCHECK)
			I.failures++
			PushRecentFailure(type, GC_QUEUE_SOFTCHECK, hint)

			var/extra_name = ""
			if (isatom(D))
				var/atom/A = D
				extra_name = " \"[A.name]\""

			// SLOWDESTROY types are expected to miss softcheck — skip noisy testing output.
			#ifdef TESTING
			if (hint != QDEL_HINT_SLOWDESTROY && !(I.qdel_flags & QDEL_ITEM_SKIP_REFSCAN))
				for (var/c in GLOB.admins)
					var/client/admin = c
					if (!check_rights_for(admin, R_ADMIN))
						continue
					to_chat(admin, "## TESTING: GC: -- [ADMIN_VV(D)] | [type][extra_name] не собрался (softcheck) --")
			#endif

			// SOFTFAIL_ALERT types notify admins as soon as they miss the normal softcheck window.
			if (hint == QDEL_HINT_SOFTFAIL_ALERT)
				I.softfail_alert_failures++
				gc_notify_opted_admins("GC softcheck alert: [type][extra_name] не собрался за [GC_SOFTCHECK_TIMEOUT / 10]с")

			// Fast ref scan if admin-requested for this type
			#ifdef REFERENCE_TRACKING
			var/should_scan_refs = FALSE
			var/should_yield_for_scan = FALSE
			// Type-wide fast reftrack is a diagnostic aid; do not stall the whole GC pass for it.
			if (I.qdel_flags & QDEL_ITEM_FAST_REFTRACK)
				should_scan_refs = TRUE
			if (reference_find_on_fail[refID])
				should_scan_refs = TRUE
				should_yield_for_scan = TRUE
				reference_find_on_fail -= refID
			#ifdef GC_FAILURE_HARD_LOOKUP
			else
				should_scan_refs = TRUE
				should_yield_for_scan = TRUE
			#endif
			if (I.qdel_flags & QDEL_ITEM_SKIP_REFSCAN)
				should_scan_refs = FALSE
				should_yield_for_scan = FALSE
			if (should_scan_refs)
				ScheduleReferenceScan(D)
			#endif

			if (hint == QDEL_HINT_QUEUE_THEN_HARDDEL)
				// Skip warnfail stage — no log_world, no admin notifications, no gc_failure_cache.
				Queue(D, GC_QUEUE_HARDDELETE, hint, origin_time)
			else
				Queue(D, GC_QUEUE_WARNFAIL, hint, origin_time)

			#ifdef REFERENCE_TRACKING
			if (should_yield_for_scan)
				return TRUE
			#endif

		if (GC_QUEUE_WARNFAIL)
			I.warnfail_count++
			PushWarnfailTime(I)
			leak_rate_fail_accumulator++
			PushRecentFailure(type, GC_QUEUE_WARNFAIL, hint)
			var/extra_name = ""
			if (isatom(D))
				var/atom/A = D
				extra_name = " \"[A.name]\""
			log_world("## GC: -- \ref[D] | [type][extra_name] не собрался (warnfail, ~[round((GC_SOFTCHECK_TIMEOUT + GC_WARNFAIL_TIMEOUT) / 10)]с) --")
			gc_notify_opted_admins("GC утечка: [type][extra_name] — [refID] не собрался за ~[round((GC_SOFTCHECK_TIMEOUT + GC_WARNFAIL_TIMEOUT) / 10)]с")
			GLOB.gc_failure_cache.log_gc_failure(D, type, refID, origin_time, hint)
			Queue(D, GC_QUEUE_HARDDELETE, hint, origin_time)

		if (GC_QUEUE_HARDDELETE)
			if (I.qdel_flags & QDEL_ITEM_SUSPENDED_FOR_LAG)
				// Suspended types stay visible by renewing their harddelete-stage timer instead of deleting.
				// This creates one new live slot per timeout interval and leaves a tombstoned prefix behind,
				// but MaybeCompact() bounds that growth once the processed prefix gets large enough.
				Queue(D, GC_QUEUE_HARDDELETE, hint, origin_time)
				return
			HardDelete(D)

/// Compact the dead prefix of a queue level if enough tombstoned entries have accumulated.
/datum/controller/subsystem/garbage/proc/MaybeCompact(level, head)
	if (head <= GC_COMPACT_THRESHOLD)
		return
	#ifdef GC_PROFILER
	var/profiler_compact_start = TICK_USAGE
	#endif
	var/list/origins = queue_origin_times[level]
	var/list/times = queue_times[level]
	var/list/refs  = queue_refs[level]
	var/list/hints = queue_hints[level]
	var/list/types = queue_types[level]
	#ifdef GC_PROFILER
	var/profiler_old_len = length(times)
	#endif
	origins.Cut(1, head)
	times.Cut(1, head)
	refs.Cut(1, head)
	hints.Cut(1, head)
	types.Cut(1, head)
	SaveQueueLevel(level, origins, times, refs, hints, types)
	queue_heads[level] = 1
	#ifdef GC_PROFILER
	profiler_compact_events++
	rustg_log_write("data/logs/gc_profiler_compact.csv", "[world.time],[level],[head],[profiler_old_len],[round(TICK_USAGE_TO_MS(profiler_compact_start), 0.01)]\n", "false")
	#endif

/// Enqueue a datum for GC checking at the given level.
/datum/controller/subsystem/garbage/proc/Queue(datum/D, level = GC_QUEUE_SOFTCHECK, qdel_hint = null, origin_time = null, queued_at = null)
	if (isnull(D))
		return
	if (level > GC_QUEUE_COUNT)
		HardDelete(D)
		return
	if (isnull(queued_at))
		queued_at = world.time
	if (isnull(origin_time))
		origin_time = queued_at
	D.gc_destroyed = queued_at

	var/list/O = queue_origin_times[level]
	var/list/T = queue_times[level]
	var/list/R = queue_refs[level]
	var/list/H = queue_hints[level]
	var/list/Y = queue_types[level]
	O += origin_time
	T += queued_at
	R += REF(D)
	H += qdel_hint
	Y += "[D.type]"
	SaveQueueLevel(level, O, T, R, H, Y)

	// Track peak live depth
	var/depth = GetQueueDepth(level)
	if (depth > peak_queue_depths[level])
		peak_queue_depths[level] = depth

/// Returns the datum currently represented by the queue slot, or null if the slot is stale.
/datum/controller/subsystem/garbage/proc/GetQueuedDatum(level, index)
	if (level < 1 || level > GC_QUEUE_COUNT)
		return null
	var/list/refs = queue_refs[level]
	if (index < 1 || index > length(refs))
		return null
	var/refID = refs[index]
	if (isnull(refID))
		return null
	var/list/times = queue_times[level]
	var/queued_at = times[index]
	if (isnull(queued_at))
		return null
	var/datum/D = locate(refID)
	if (!D || D.gc_destroyed != queued_at)
		return null
	return D

/// Imports queued entries while preserving both original qdel time and current stage time.
/datum/controller/subsystem/garbage/proc/RecoverQueueEntries(list/source_refs, list/source_times, list/source_origin_times, list/source_hints, list/source_heads)
	if (!islist(source_refs) || !islist(source_times) || !islist(source_hints) || !islist(source_heads))
		return
	for (var/i in 1 to min(length(source_refs), GC_QUEUE_COUNT))
		var/list/old_refs = source_refs[i]
		var/list/old_times = source_times[i]
		var/list/old_origins = islist(source_origin_times) && i <= length(source_origin_times) ? source_origin_times[i] : null
		var/list/old_hints = source_hints[i]
		var/old_head = source_heads[i]
		if (!islist(old_refs) || !islist(old_times) || !islist(old_hints))
			continue
		if (!isnum(old_head))
			old_head = 1
		for (var/j in old_head to length(old_refs))
			if (isnull(old_refs[j]) || isnull(old_times[j]))
				continue
			var/datum/D = locate(old_refs[j])
			if (D && D.gc_destroyed == old_times[j])
				var/origin_time = islist(old_origins) && j <= length(old_origins) && !isnull(old_origins[j]) ? old_origins[j] : old_times[j]
				Queue(D, i, old_hints[j], origin_time, old_times[j])

/// Force-delete an object that failed to GC gracefully.
/// Separated into its own proc for profiling clarity.
/datum/controller/subsystem/garbage/proc/HardDelete(datum/D)
	++delslasttick
	++totaldels
	var/type = D.type
	var/refID = "\ref[D]"

	var/tick_usage = TICK_USAGE
	del(D)
	tick_usage = TICK_USAGE_TO_MS(tick_usage)

	var/datum/qdel_item/I = GetOrCreateItem(type)
	I.hard_deletes++
	I.hard_delete_time += tick_usage
	I.hard_delete_avg_ms = I.hard_delete_time / max(I.hard_deletes, 1)
	if (tick_usage > I.hard_delete_max)
		I.hard_delete_max = tick_usage
	if (tick_usage > highest_del_ms)
		highest_del_ms = tick_usage
		highest_del_type_string = "[type]"

	// Update hard-del EMA (simple running average per fire cycle)
	if (harddel_ms_avg <= 0)
		harddel_ms_avg = tick_usage
	else
		harddel_ms_avg = harddel_ms_avg * 0.9 + tick_usage * 0.1

	// Recent hard deletes ring buffer
	if (length(recent_hard_deletes) >= GC_HARDDEL_RING_SIZE)
		recent_hard_deletes.Cut(1, 2)
	recent_hard_deletes += list(list(world.time, "[type]", round(tick_usage, 0.1)))

	var/time = MS2DS(tick_usage)
	if (time > 0.1 SECONDS)
		postpone(time)
	var/threshold = CONFIG_GET(number/hard_deletes_overrun_threshold)
	if (threshold && (time > threshold SECONDS))
		if (!(I.qdel_flags & QDEL_ITEM_ADMINS_WARNED))
			log_game("Error: [type]([refID]) took longer than [threshold] seconds to delete (took [round(time/10, 0.1)] seconds to delete)")
			message_admins("Error: [type]([refID]) took longer than [threshold] seconds to delete (took [round(time/10, 0.1)] seconds to delete).")
			I.qdel_flags |= QDEL_ITEM_ADMINS_WARNED
		I.hard_deletes_over_threshold++
		var/overrun_limit = CONFIG_GET(number/hard_deletes_overrun_limit)
		if (overrun_limit && I.hard_deletes_over_threshold >= overrun_limit)
			I.qdel_flags |= QDEL_ITEM_SUSPENDED_FOR_LAG

/// Sends a GC notification message only to admins who have opted into leak notifications.
/datum/controller/subsystem/garbage/proc/gc_notify_opted_admins(msg)
	for (var/c in GLOB.admins)
		var/client/admin = c
		if (!check_rights_for(admin, R_DEBUG))
			continue
		if (!admin.gc_leak_notify)
			continue
		to_chat(admin, "<span class='warning'>[msg]</span>")

/// Schedules a reference scan for a GC-failed datum.
#ifdef REFERENCE_TRACKING
/datum/controller/subsystem/garbage/proc/ScheduleReferenceScan(datum/D)
	#ifdef UNIT_TESTS
	if (test_ref_scan_skip_async)
		return
	#endif
	INVOKE_ASYNC(D, TYPE_PROC_REF(/datum, find_references))
#endif

/// Returns the qdel_item datum for a type path or type-path string, or null if none exists yet.
/datum/controller/subsystem/garbage/proc/GetItem(type_path)
	if (isnull(type_path))
		return null
	return items["[type_path]"]

/// Returns the qdel_item datum for a type, creating it if it doesn't exist yet.
/datum/controller/subsystem/garbage/proc/GetOrCreateItem(type_path)
	var/key = "[type_path]"
	var/datum/qdel_item/I = items[key]
	if (!I)
		I = new /datum/qdel_item(type_path)
		items[key] = I
		// Default skip-refscan for noisy high-volume types
		if (ispath(type_path, /datum/gas_mixture))
			I.qdel_flags |= QDEL_ITEM_SKIP_REFSCAN
	return I

/datum/controller/subsystem/garbage/Recover()
	InitQueues() // Create queues before recovering data

	// Recover pending entries from the old subsystem instance's parallel arrays
	RecoverQueueEntries(SSgarbage.queue_refs, SSgarbage.queue_times, SSgarbage.queue_origin_times, SSgarbage.queue_hints, SSgarbage.queue_heads)
	last_hd_budget_ms = GetConfiguredHardDeleteBudgetMinMs()
	last_hd_cap = GetConfiguredHardDeleteHoldMaxPerFire()
	last_hd_mode = GC_HARDDEL_MODE_HOLD
	last_hd_background_scheduling = TRUE
	last_hd_pass_ms = 0
	last_hd_yield_ratio = 0
	last_hd_mc_clipped = FALSE
	last_hd_hold_sample_eligible = FALSE
	hd_hold_eligibility_streak = 0
	harddel_yield_history = list()
	harddel_yield_total = 0
	flags |= SS_BACKGROUND


// ============================================================
// qdel statistics
// ============================================================

/// Qdel Item: Holds statistics on each type that passes through qdel().
/datum/qdel_item
	/// Type path as a string.
	var/name = ""
	/// Total number of times this type has passed through qdel().
	var/qdels = 0
	/// Total milliseconds spent in Destroy() for this type.
	var/destroy_time = 0
	/// Times an object of this type failed soft-delete (softcheck).
	var/failures = 0
	/// Times an object of this type reached the warnfail queue (confirmed leak).
	var/warnfail_count = 0
	/// Times an object of this type required a hard delete (includes QDEL_HINT_HARDDEL).
	var/hard_deletes = 0
	/// Total milliseconds spent hard-deleting this type.
	var/hard_delete_time = 0
	/// Average milliseconds spent hard-deleting this type.
	var/hard_delete_avg_ms = 0
	/// Peak milliseconds for a single hard delete of this type.
	var/hard_delete_max = 0
	/// Number of hard deletes that exceeded the configured overrun threshold.
	var/hard_deletes_over_threshold = 0
	/// Times Destroy() returned LETMELIVE despite force=TRUE.
	var/no_respect_force = 0
	/// Times Destroy() returned null (no hint).
	var/no_hint = 0
	/// Times Destroy() slept (blocked the tick).
	var/slept_destroy = 0
	/// Flags — see QDEL_ITEM_* defines.
	var/qdel_flags = 0
	/// Times a QDEL_HINT_SOFTFAIL_ALERT object failed to GC within the softcheck window.
	var/softfail_alert_failures = 0
	/// Ring buffer of the last 10 confirmed warnfail timestamps (world.time values).
	var/list/failure_times = null

/datum/qdel_item/New(mytype)
	name = "[mytype]"


/// Should be treated as a replacement for the 'del' keyword.
///
/// Datums passed to this will be given a chance to clean up references to allow the GC to collect them.
/proc/qdel(datum/D, force=FALSE, ...)
	if (isnull(D))
		return
	if (!istype(D))
		del(D)
		return

	var/datum/qdel_item/I = SSgarbage.GetOrCreateItem(D.type)
	I.qdels++

	if (isnull(D.gc_destroyed))
		if (SEND_SIGNAL(D, COMSIG_PARENT_PREQDELETED, force)) // Give components a chance to prevent deletion
			return
		D.gc_destroyed = GC_CURRENTLY_BEING_QDELETED
		var/start_time = world.time
		var/start_tick = world.tick_usage
		SEND_SIGNAL(D, COMSIG_PARENT_QDELETING, force) // Notify remaining components
		var/hint = D.Destroy(arglist(args.Copy(2)))
		if (world.time != start_time)
			I.slept_destroy++
		else
			I.destroy_time += TICK_USAGE_TO_MS(start_tick)
		if (!D)
			return
		switch (hint)
			if (QDEL_HINT_QUEUE)
				SSgarbage.Queue(D, qdel_hint = hint)
			if (QDEL_HINT_IWILLGC)
				D.gc_destroyed = world.time
				return
			if (QDEL_HINT_LETMELIVE)
				if (!force)
					D.gc_destroyed = null
					return
				#ifdef TESTING
				if (!I.no_respect_force)
					testing("WARNING: [D.type] has been force deleted, but is \
						returning an immortal QDEL_HINT, indicating it does \
						not respect the force flag for qdel(). It has been \
						placed in the queue, further instances of this type \
						will also be queued.")
				#endif
				I.no_respect_force++
				SSgarbage.Queue(D, qdel_hint = hint)
			if (QDEL_HINT_HARDDEL)
				SSgarbage.Queue(D, GC_QUEUE_HARDDELETE, qdel_hint = hint)
			if (QDEL_HINT_HARDDEL_NOW)
				SSgarbage.HardDelete(D)
			if (QDEL_HINT_SOFTFAIL_ALERT)
				I.qdel_flags |= QDEL_ITEM_SOFTFAIL_ALERT
				SSgarbage.Queue(D, GC_QUEUE_SOFTCHECK, qdel_hint = hint)
			if (QDEL_HINT_SLOWDESTROY)
				I.qdel_flags |= QDEL_ITEM_SLOWDESTROY
				SSgarbage.Queue(D, GC_QUEUE_SOFTCHECK, qdel_hint = hint)
			if (QDEL_HINT_QUEUE_THEN_HARDDEL)
				SSgarbage.Queue(D, qdel_hint = hint)
			#ifdef REFERENCE_TRACKING
			if (QDEL_HINT_FINDREFERENCE)
				SSgarbage.Queue(D, qdel_hint = hint)
				D.find_references()
			if (QDEL_HINT_IFFAIL_FINDREFERENCE)
				SSgarbage.Queue(D, qdel_hint = hint)
				SSgarbage.reference_find_on_fail[REF(D)] = TRUE
			#endif
			else
				#ifdef TESTING
				if (!I.no_hint)
					testing("WARNING: [D.type] is not returning a qdel hint. It is being placed in the queue. Further instances of this type will also be queued.")
				#endif
				I.no_hint++
				SSgarbage.Queue(D, qdel_hint = hint)
	else if (D.gc_destroyed == GC_CURRENTLY_BEING_QDELETED)
		CRASH("[D.type] destroy proc was called multiple times, likely due to a qdel loop in the Destroy logic")

// To remove objects from weak references
/proc/qdel_weakref_resolve(datum/thing, force=FALSE)
	if(isweakref(thing))
		var/datum/weakref/ref = thing
		thing = ref.resolve()
	if(thing)
		qdel(thing, force)

// ============================================================
// GC Profiler — compile-time instrumentation (GC_PROFILER only)
// ============================================================

#ifdef GC_PROFILER

/// Write one CSV row per fire() call to data/logs/gc_profiler.csv.
/// sc/wf/hd_ms are -1 if that level was never reached (early return from MC yield).
/// pass_snap/fail_snap are snapshots from fire() start — used to emit per-fire deltas.
/datum/controller/subsystem/garbage/proc/GCProfilerWriteFire(q1, q2, q3, sc_ms, wf_ms, hd_ms, fire_start, list/pass_snap, list/fail_snap)
	var/total_ms = TICK_USAGE_TO_MS(fire_start)
	var/row = "[world.time],[profiler_fire_count],"
	row += "[q1],[q2],[q3],"
	row += "[round(sc_ms, 0.01)],[profiler_sc_checked],[profiler_sc_tomb],[pass_counts[GC_QUEUE_SOFTCHECK] - pass_snap[GC_QUEUE_SOFTCHECK]],[fail_counts[GC_QUEUE_SOFTCHECK] - fail_snap[GC_QUEUE_SOFTCHECK]],[profiler_sc_yield ? 1 : 0],"
	row += "[round(wf_ms, 0.01)],[profiler_wf_checked],[profiler_wf_tomb],[pass_counts[GC_QUEUE_WARNFAIL] - pass_snap[GC_QUEUE_WARNFAIL]],[fail_counts[GC_QUEUE_WARNFAIL] - fail_snap[GC_QUEUE_WARNFAIL]],[profiler_wf_yield ? 1 : 0],"
	row += "[round(hd_ms, 0.01)],[profiler_hd_checked],[profiler_hd_tomb],[pass_counts[GC_QUEUE_HARDDELETE] - pass_snap[GC_QUEUE_HARDDELETE]],[fail_counts[GC_QUEUE_HARDDELETE] - fail_snap[GC_QUEUE_HARDDELETE]],[profiler_hd_yield ? 1 : 0],"
	row += "[round(total_ms, 0.01)],[round(leak_rate_avg, 0.01)],[round(harddel_ms_avg, 0.01)],[round(profiler_hd_budget_ms, 0.01)],[profiler_hd_cap],[profiler_hd_overflow_mode ? 1 : 0],[profiler_compact_events],"
	row += "[profiler_hd_mode],[profiler_hd_background ? 1 : 0],[round(profiler_hd_yield_ratio, 0.01)],[profiler_hd_mc_clipped ? 1 : 0]"
	rustg_log_write("data/logs/gc_profiler.csv", "[row]\n", "false")

/// Write per-type stats for all types with failures or hard deletes to gc_profiler_types.csv.
/// Called every 60 fires (~1 minute).
/datum/controller/subsystem/garbage/proc/GCProfilerWriteTypes()
	for (var/path in items)
		var/datum/qdel_item/I = items[path]
		if (!I.failures && !I.hard_deletes)
			continue
		var/row = "[world.time],[path],[I.qdels],[I.failures],[I.warnfail_count],"
		row += "[I.hard_deletes],[round(I.hard_delete_time, 0.01)],[round(I.hard_delete_max, 0.01)],"
		row += "[round(I.destroy_time, 0.01)],[I.slept_destroy],[I.no_hint],[I.softfail_alert_failures]"
		rustg_log_write("data/logs/gc_profiler_types.csv", "[row]\n", "false")

#endif // GC_PROFILER
