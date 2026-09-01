PROCESSING_SUBSYSTEM_DEF(projectiles)
	name = "Projectiles"
	priority = FIRE_PRIORITY_PROJECTILES
	wait = 1
	stat_tag = "PP"
	flags = SS_NO_INIT|SS_TICKER
	var/global_pixel_increment_amount = 4
	var/global_projectile_speed_multiplier = 1
	/// Projectile-heavy NPC patterns begin spacing their shots after this many
	/// live queue entries. No shots are discarded; producers slow down so the
	/// collision tracer can catch up instead of filling the map with stale fire.
	var/pattern_soft_limit = 300
	/// Opted-in NPC patterns shed their remaining burst at this many live entries.
	/// Player weapons and ordinary projectiles are never rejected by this gate.
	var/pattern_hard_limit = 400
	/// Each additional block adds one decisecond to an opted-in pattern delay.
	var/pattern_delay_step = 50
	var/pattern_max_delay = 20
	/// Bound one projectile's synchronous collision trace to one turf. Remaining
	/// distance is carried into the next fair round instead of monopolizing the
	/// current MC pass.
	var/max_pixels_per_process = TILES_TO_PIXELS(1)

	/// Projectiles do not use the generic processing snapshot. A snapshot can
	/// take many ticks to drain and prevents newly fired projectiles from ever
	/// entering the active run. Instead, every fire is an epoch: old projectiles
	/// and newly admitted projectiles are interleaved, then moved to the next
	/// epoch after one time-based simulation pass.
	var/list/projectile_queue = list()
	/// Projectiles which still have elapsed movement debt after one bounded trace.
	/// This is kept separate for diagnostics until the round finishes, then merged
	/// with caught-up shots so neither group can starve the other.
	var/list/projectile_debt_queue = list()
	var/list/projectile_next_queue = list()
	var/list/projectile_new_queue = list()
	var/projectile_epoch_active = FALSE
	var/projectiles_processed_this_epoch = 0

/datum/controller/subsystem/processing/projectiles/stat_entry(msg)
	var/projectile_count = active_projectile_count()
	msg = "P:[projectile_count] D:[length(projectile_debt_queue)] G:[length(processing)] E:[projectiles_processed_this_epoch]"
	if(can_fire && !(SS_NO_FIRE & flags))
		return "[round(cost,1)]ms|[round(tick_usage,1)]%([round(tick_overrun,1)]%)|[round(ticks,0.1)]\t[msg]"
	return "OFFLINE\t[msg]"

/datum/controller/subsystem/processing/projectiles/proc/active_projectile_count()
	return length(projectile_queue) + length(projectile_debt_queue) + length(projectile_next_queue) + length(projectile_new_queue)

/// Give opted-in high-volume attack patterns a graceful overload cadence.
/// The normal delay is unchanged below the soft limit and every projectile is
/// still fired until the separate emergency hard limit is reached.
/datum/controller/subsystem/processing/projectiles/proc/recommended_pattern_delay(normal_delay)
	var/active_count = active_projectile_count()
	if(active_count <= pattern_soft_limit)
		return normal_delay
	var/extra_delay = CEILING((active_count - pattern_soft_limit) / max(pattern_delay_step, 1), 1)
	return max(normal_delay, min(pattern_max_delay, normal_delay + extra_delay))

/datum/controller/subsystem/processing/projectiles/proc/pattern_at_capacity()
	return active_projectile_count() >= pattern_hard_limit

/// Register a fired projectile in the real-time queue. New shots created while
/// an epoch is paused are kept separately so fire() can interleave them with
/// the old backlog instead of waiting for the entire snapshot to drain.
/datum/controller/subsystem/processing/projectiles/proc/start_projectile(obj/item/projectile/projectile)
	if(QDELETED(projectile) || (projectile.datum_flags & DF_ISPROCESSING))
		return FALSE
	projectile.datum_flags |= DF_ISPROCESSING
	var/datum/weakref/projectile_ref = WEAKREF(projectile)
	if(projectile_epoch_active)
		projectile_new_queue += projectile_ref
	else
		projectile_queue += projectile_ref
	return TRUE

/datum/controller/subsystem/processing/projectiles/proc/stop_projectile(obj/item/projectile/projectile)
	if(!projectile)
		return
	projectile.datum_flags &= ~DF_ISPROCESSING
	// Queues contain weakrefs, so deletion is O(1) and a stale slot cannot keep
	// the projectile alive. It is discarded naturally when its turn arrives.

/// Put a projectile through one elapsed-time simulation pass and queue it for
/// the next epoch if it survived. Collision work stays inside the projectile;
/// the MC budget is checked between projectiles for global fairness.
/datum/controller/subsystem/processing/projectiles/proc/process_projectile(datum/weakref/projectile_ref, profiling = FALSE)
	var/obj/item/projectile/projectile = projectile_ref?.resolve()
	if(QDELETED(projectile) || !(projectile.datum_flags & DF_ISPROCESSING))
		return
	projectiles_processed_this_epoch++
	var/item_type = projectile.type
	var/item_start_usage
	if(profiling)
		item_start_usage = TICK_USAGE
	var/process_result = projectile.process()
	if(profiling)
		profile_note(item_type, max(0, TICK_DELTA_TO_MS(TICK_USAGE - item_start_usage)))
	if(QDELETED(projectile))
		return
	if(process_result == PROCESS_KILL)
		stop_projectile(projectile)
		return
	if(projectile.datum_flags & DF_ISPROCESSING)
		if(!projectile.paused && isturf(projectile.loc) && projectile.fired && projectile.trajectory \
			&& projectile.pixels_per_second > 0 && projectile.pixel_increment_amount > 0 \
			&& projectile.pixels_tick_leftover >= projectile.pixel_increment_amount)
			projectile_debt_queue += projectile_ref
		else
			projectile_next_queue += projectile_ref

/// Recover all queues if the MC starts a fresh fire after an interrupted epoch.
/// A projectile may receive a zero-elapsed pass, but none can be stranded in a
/// stale queue owned by the abandoned fire.
/datum/controller/subsystem/processing/projectiles/proc/restart_projectile_epoch()
	if(projectile_epoch_active)
		projectile_queue |= projectile_next_queue
		projectile_queue |= projectile_debt_queue
		projectile_queue |= projectile_new_queue
		projectile_debt_queue = list()
		projectile_next_queue = list()
		projectile_new_queue = list()
	projectile_epoch_active = TRUE
	projectiles_processed_this_epoch = 0

/datum/controller/subsystem/processing/projectiles/fire(resumed = FALSE)
	var/slice_start_usage = TICK_USAGE
	if(!resumed)
		restart_projectile_epoch()
		currentrun = processing.Copy()
		current_pass_cost_ms = 0
	var/profiling = profile_armed

	while(length(projectile_queue) || length(currentrun))
		if(length(projectile_queue))
			var/datum/weakref/projectile_ref = projectile_queue[length(projectile_queue)]
			projectile_queue.len--
			process_projectile(projectile_ref, profiling)

			// Admit one shot created during this epoch for every old shot. This
			// guarantees progress for both groups even if combat keeps spawning.
			if(length(projectile_new_queue))
				var/datum/weakref/new_projectile_ref = projectile_new_queue[length(projectile_new_queue)]
				projectile_new_queue.len--
				process_projectile(new_projectile_ref, profiling)

		if(length(currentrun))
			var/datum/thing = currentrun[length(currentrun)]
			currentrun.len--
			if(QDELETED(thing))
				processing -= thing
			else if(profiling)
				var/item_type = thing.type
				var/item_start_usage = TICK_USAGE
				if(thing.process(wait * world.tick_lag * 0.1) == PROCESS_KILL)
					STOP_PROCESSING(src, thing)
				profile_note(item_type, max(0, TICK_DELTA_TO_MS(TICK_USAGE - item_start_usage)))
			else if(thing.process(wait * world.tick_lag * 0.1) == PROCESS_KILL)
				STOP_PROCESSING(src, thing)

		if(MC_TICK_CHECK)
			current_pass_cost_ms += max(0, TICK_DELTA_TO_MS(TICK_USAGE - slice_start_usage))
			return

	// Every surviving projectile joins one common next round. In particular,
	// movement debt must not receive repeated turns while caught-up projectiles
	// sit in projectile_next_queue: that made apparently stationary shots under
	// overload even though SSprojectiles was spending seconds on catch-up work.
	projectile_next_queue |= projectile_debt_queue
	projectile_next_queue |= projectile_new_queue
	projectile_queue = projectile_next_queue
	projectile_debt_queue = list()
	projectile_next_queue = list()
	projectile_new_queue = list()
	projectile_epoch_active = FALSE
	currentrun = list()
	current_pass_cost_ms += max(0, TICK_DELTA_TO_MS(TICK_USAGE - slice_start_usage))
	on_pass_finished(length(projectile_queue) + length(processing))

/datum/controller/subsystem/processing/projectiles/proc/set_pixel_speed(new_speed)
	global_pixel_increment_amount = new_speed
	for(var/list/queue as anything in list(projectile_queue, projectile_debt_queue, projectile_next_queue, projectile_new_queue))
		for(var/datum/weakref/projectile_ref as anything in queue)
			var/obj/item/projectile/projectile = projectile_ref.resolve()
			if(projectile)
				projectile.set_pixel_increment_amount(new_speed)

/datum/controller/subsystem/processing/projectiles/vv_edit_var(var_name, var_value)
	switch(var_name)
		if(NAMEOF(src, global_pixel_increment_amount))
			set_pixel_speed(var_value)
			return TRUE
		else
			return ..()
