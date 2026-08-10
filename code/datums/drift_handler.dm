/**
 * Drives space drift with a smooth move loop (SSnewtonian_movement). Ported from tg/SPLURT-style newtonian drift.
 */
/datum/drift_handler
	var/atom/movable/parent
	var/atom/inertia_last_loc
	/// Facing to restore after a drift step (keeps you “sideways” while gliding)
	var/old_dir
	var/datum/move_loop/smooth_move/drifting_loop
	/// Skip one glide_size echo from the moveloop (postprocess ordering)
	var/ignore_next_glide = FALSE
	/// We deliberately paused; skip glide_to_halt
	var/delayed = FALSE
	/// How much force is behind this drift (used for impulse math and braking)
	var/drift_force = 1

/datum/drift_handler/New(atom/movable/parent, inertia_angle, instant = FALSE, start_delay = 0, drift_force = 1)
	. = ..()
	src.parent = parent
	src.parent.drift_handler = src
	src.drift_force = drift_force
	var/flags = MOVEMENT_LOOP_OUTSIDE_CONTROL
	if(instant)
		flags |= MOVEMENT_LOOP_START_FAST
	var/loop_delay = get_loop_delay(parent)
	drifting_loop = SSmove_manager.smooth_move(
		moving = parent,
		angle = inertia_angle,
		delay = loop_delay,
		timeout = INFINITY,
		subsystem = SSnewtonian_movement,
		priority = MOVEMENT_SPACE_PRIORITY,
		flags = flags,
		extra_info = null,
	)
	if(!drifting_loop)
		qdel(src)
		return
	RegisterSignal(drifting_loop, COMSIG_MOVELOOP_START, PROC_REF(moveloop_began))
	RegisterSignal(drifting_loop, COMSIG_MOVELOOP_STOP, PROC_REF(moveloop_ended))
	RegisterSignal(drifting_loop, COMSIG_MOVELOOP_PREPROCESS_CHECK, PROC_REF(before_move))
	RegisterSignal(drifting_loop, COMSIG_MOVELOOP_POSTPROCESS, PROC_REF(after_move))
	RegisterSignal(drifting_loop, COMSIG_PARENT_QDELETING, PROC_REF(loop_death))
	if(drifting_loop.running)
		moveloop_began()

	var/visual_delay = loop_delay
	if(!instant && start_delay)
		drifting_loop.pause_for(start_delay)
		visual_delay = start_delay

	apply_initial_visuals(visual_delay)
	if(drifting_loop.timer <= world.time)
		var/rate_loop_delay = get_loop_delay(parent)
		var/next_allowed_move = parent.last_drift_time + rate_loop_delay
		if(world.time < next_allowed_move)
			var/pause_time = next_allowed_move - world.time
			drifting_loop.pause_for(pause_time)
		else
			SSnewtonian_movement.fire_moveloop(drifting_loop)

/datum/drift_handler/Destroy()
	// Never qdel the move_loop synchronously: Destroy can run from the loop's process/signals.
	if(drifting_loop)
		var/datum/move_loop/loop_ref = drifting_loop
		drifting_loop = null
		if(!QDELETED(loop_ref))
			QDEL_IN(loop_ref, 0)
	inertia_last_loc = null
	if(parent)
		if(parent.drift_handler == src)
			parent.drift_handler = null
		parent.inertia_moving = FALSE
	return ..()

/datum/drift_handler/proc/apply_initial_visuals(visual_delay)
	if(SEND_SIGNAL(parent, COMSIG_MOVABLE_DRIFT_VISUAL_ATTEMPT) & DRIFT_VISUAL_FAILED)
		return
	ignore_next_glide = TRUE
	parent.set_glide_size(MOVEMENT_ADJUSTED_GLIDE_SIZE(visual_delay, SSnewtonian_movement.visual_delay), FALSE)

/// Add to or replace vector when you already have a handler (recoil, jet micro-thrust, etc.)
/datum/drift_handler/proc/newtonian_impulse(inertia_angle, start_delay, additional_force, controlled_cap, force_loop = TRUE)
	inertia_last_loc = parent.loc
	if(!drifting_loop)
		qdel(src)
		return FALSE

	var/applied_force = additional_force
	var/force_x = sin(drifting_loop.angle) * drift_force + sin(inertia_angle) * applied_force / parent.inertia_force_weight
	var/force_y = cos(drifting_loop.angle) * drift_force + cos(inertia_angle) * applied_force / parent.inertia_force_weight

	var/uncapped_force = sqrt(force_x * force_x + force_y * force_y)
	// controlled_cap (recoil/click sources) is a top-up ceiling: it can add drift up to the cap but must never clamp away
	// drift the parent already built from movement, otherwise firing would become a free brake / reverse exploit.
	var/effective_cap = isnull(controlled_cap) ? INERTIA_FORCE_CAP : max(drift_force, controlled_cap)
	drift_force = clamp(uncapped_force, 0, effective_cap)
	if(drift_force < 0.1)
		qdel(src)
		return TRUE

	drifting_loop.set_angle(delta_to_angle(force_x, force_y))
	var/rate_loop_delay = get_loop_delay(parent)
	drifting_loop.set_delay(rate_loop_delay)
	if(drifting_loop.timer <= world.time && force_loop)
		var/next_allowed_move = parent.last_drift_time + rate_loop_delay
		if(world.time < next_allowed_move)
			var/pause_time = next_allowed_move - world.time
			drifting_loop.pause_for(pause_time)
		else
			SSnewtonian_movement.fire_moveloop(drifting_loop)
	return TRUE

/datum/drift_handler/proc/moveloop_began()
	SIGNAL_HANDLER
	inertia_last_loc = parent.loc
	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(handle_move))
	RegisterSignal(parent, COMSIG_MOVABLE_UPDATE_GLIDE_SIZE, PROC_REF(handle_glidesize_update))

/datum/drift_handler/proc/moveloop_ended()
	SIGNAL_HANDLER
	if(!parent)
		return
	parent.inertia_moving = FALSE
	ignore_next_glide = FALSE
	UnregisterSignal(parent, list(
		COMSIG_MOVABLE_MOVED,
		COMSIG_MOVABLE_UPDATE_GLIDE_SIZE,
	))

/datum/drift_handler/proc/before_move(datum/source)
	SIGNAL_HANDLER
	if(!parent)
		return
	parent.inertia_moving = TRUE
	old_dir = parent.dir
	delayed = FALSE

/datum/drift_handler/proc/after_move(datum/source, result, visual_delay)
	SIGNAL_HANDLER
	if(!parent)
		return
	if(result == MOVELOOP_FAILURE)
		QDEL_IN(src, 0)
		return
	parent.last_drift_time = world.time
	parent.setDir(old_dir)
	parent.inertia_moving = FALSE
	if(!drifting_loop)
		return
	if(parent.Process_Spacemove(angle2dir(drifting_loop.angle), continuous_move = TRUE))
		glide_to_halt(visual_delay)
		return
	ignore_next_glide = TRUE

/datum/drift_handler/proc/loop_death(datum/source)
	SIGNAL_HANDLER
	drifting_loop = null

/datum/drift_handler/proc/handle_move(datum/source, atom/OldLoc, Dir, Forced = FALSE)
	SIGNAL_HANDLER
	if(QDELETED(src) || !parent)
		return
	if(!isturf(parent.loc))
		QDEL_IN(src, 0)
		return
	if(parent.inertia_moving)
		return
	if(!drifting_loop)
		return
	if(!parent.Process_Spacemove(angle2dir(drifting_loop.angle), TRUE))
		return
	QDEL_IN(src, 0)

/datum/drift_handler/proc/handle_glidesize_update(datum/source, glide_size)
	SIGNAL_HANDLER
	if(!drifting_loop || !parent)
		return
	if(parent.inertia_moving)
		return
	if(ignore_next_glide)
		ignore_next_glide = FALSE
		return
	// Defer the drift at most once per loop cycle. A held thrust/move key fires a glide update on every step
	// (vehicle_move's set_glide_size, plus Move()'s glide_size_override from step()); re-pausing on each one keeps
	// shoving the loop's next fire past the key-repeat interval, so the drift never advances and the mech "freezes"
	// in place until the key is released. before_move clears `delayed` on every real fire, so this self-resets.
	if(delayed)
		return
	var/glide_delay = round(world.icon_size / max(glide_size, 1), 1) * world.tick_lag
	drifting_loop.pause_for(glide_delay)
	delayed = TRUE

/datum/drift_handler/proc/glide_to_halt(glide_for)
	if(!ismob(parent))
		QDEL_IN(src, 0)
		return
	var/mob/mob_parent = parent
	if(!mob_parent.client || delayed)
		QDEL_IN(src, 0)
		return
	if(drifting_loop)
		var/datum/move_loop/L = drifting_loop
		drifting_loop = null
		QDEL_IN(L, 0)
	QDEL_IN(src, max(world.tick_lag, glide_for))

/// Bracing / scrubbing speed when something to push against is in range (see /mob/get_spacemove_backup)
/datum/drift_handler/proc/attempt_halt(movement_dir, continuous_move, atom/backup)
	if((backup.density || !backup.CanPass(parent, get_turf(parent))) && (get_dir(parent, backup) == movement_dir || parent.loc == backup.loc))
		return FALSE
	if(drift_force < INERTIA_FORCE_SPACEMOVE_GRAB || isnull(drifting_loop))
		return FALSE
	if(drift_force <= INERTIA_FORCE_SPACEMOVE_REDUCTION / parent.inertia_force_weight)
		glide_to_halt(get_loop_delay(parent))
		return TRUE
	drift_force -= INERTIA_FORCE_SPACEMOVE_REDUCTION / parent.inertia_force_weight
	drifting_loop.set_delay(get_loop_delay(parent))
	return TRUE

/datum/drift_handler/proc/get_loop_delay(atom/movable/movable)
	return (DEFAULT_INERTIA_SPEED / ((1 - INERTIA_SPEED_COEF) + drift_force * INERTIA_SPEED_COEF)) * movable.inertia_move_multiplier

/datum/drift_handler/proc/stabilize_drift(target_angle, target_force, stabilization_force)
	if(isnull(drifting_loop))
		return
	if(isnull(target_angle))
		var/halt_force = min(drift_force, stabilization_force)
		parent.newtonian_move(angle2dir(REVERSE_ANGLE(drifting_loop.angle)), drift_force = halt_force)
		return
	var/drift_projection = max(0, cos(target_angle - drifting_loop.angle)) * drift_force
	var/force_x = sin(target_angle) * target_force - sin(drifting_loop.angle) * drift_force
	var/force_y = cos(target_angle) * target_force - cos(drifting_loop.angle) * drift_force
	var/force_angle = delta_to_angle(force_x, force_y)
	var/applied_force = sqrt(force_x * force_x + force_y * force_y)
	var/force_projection = max(0, cos(target_angle - force_angle)) * applied_force
	force_x -= min(force_projection, drift_projection) * sin(target_angle)
	force_y -= min(force_projection, drift_projection) * cos(target_angle)
	applied_force = min(sqrt(force_x * force_x + force_y * force_y), stabilization_force)
	parent.newtonian_move(angle2dir(force_angle), instant = TRUE, drift_force = applied_force)

/datum/drift_handler/proc/remove_angle_force(target_angle)
	if(isnull(drifting_loop))
		return
	var/projected_force = max(0, cos(target_angle - drifting_loop.angle)) * drift_force
	if(projected_force > 0)
		parent.newtonian_move(angle2dir(REVERSE_ANGLE(target_angle)), drift_force = projected_force)
