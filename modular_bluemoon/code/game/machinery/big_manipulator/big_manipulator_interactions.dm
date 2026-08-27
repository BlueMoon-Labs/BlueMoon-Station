/// We have no tasks to execute for some reason. Waits for a turf signal to retry.
/obj/machinery/big_manipulator/proc/nothing_ever_happens()
	if(stopping)
		complete_stopping_task()
		return FALSE

	current_task = null
	waiting_for_signal = TRUE
	register_task_turf_signals()

	return FALSE

/// A signal ran or some settings changed; checking if we can run the tasks now.
/obj/machinery/big_manipulator/proc/something_happened()
	next_cycle_scheduled = FALSE
	step_tasks()

/// Runs the next task. Or doesn't.
/obj/machinery/big_manipulator/proc/step_tasks()
	if(!on || stopping)
		return
	next_cycle_scheduled = FALSE
	if(waiting_for_signal)
		unregister_task_turf_signals()
		waiting_for_signal = FALSE
	if(!length(tasks))
		nothing_ever_happens()
		return
	var/datum/manipulator_task/next_task = master_tasking.get_next_task(tasks, src)
	if(!next_task)
		nothing_ever_happens()
		return
	current_task = next_task
	SStgui.update_uis(src)
	next_task.run_task(src)

/// Attempts to launch the work cycle. Should only be ran on pressing the "Run" button.
/obj/machinery/big_manipulator/proc/try_kickstart(mob/user)
	if(!on || !anchored || stopping || current_task != null)
		return FALSE

	if(!powered())
		on = FALSE
		balloon_alert_to_viewers("not enough power!")
		return FALSE

	use_power(active_power_usage)

	next_cycle_scheduled = FALSE
	step_tasks()

/// Safely schedules the next step to prevent overlapping.
/obj/machinery/big_manipulator/proc/schedule_next_cycle(time_seconds = BASE_INTERACTION_TIME)
	if(next_cycle_scheduled || stopping)
		return

	next_cycle_scheduled = TRUE
	addtimer(CALLBACK(src, PROC_REF(step_tasks)), time_seconds)

/// Rotates the manipulator arm to face the target task's turf.
/obj/machinery/big_manipulator/proc/rotate_to_point(datum/manipulator_task/cargo/target_task, callback_object, callback)
	if(stopping)
		return

	if(!target_task)
		return FALSE

	var/target_dir = get_dir(get_turf(src), target_task.interaction_turf)
	var/target_angle = dir2angle(target_dir)
	var/current_angle = manipulator_arm.arm_angle
	var/angle_diff = closer_angle_difference(current_angle, target_angle)

	var/num_rotations = round(abs(angle_diff) / 45)

	if(!num_rotations)
		var/datum/callback/cb = CALLBACK(callback_object, callback, src)
		cb.Invoke()
		return TRUE

	var/rotation_step = 45 * sign(angle_diff)
	do_step_rotation(target_task, callback_object, callback, current_angle, target_angle, rotation_step)
	return TRUE

/// Does a 45 degree step, animating the claw
/obj/machinery/big_manipulator/proc/do_step_rotation(datum/manipulator_task/cargo/target_task, callback_object, callback, current_angle, target_angle, rotation_step)
	if(stopping)
		return

	var/angle_diff = closer_angle_difference(current_angle, target_angle)
	if(abs(angle_diff) < abs(rotation_step))
		var/matrix/final_matrix = matrix()
		final_matrix.Turn(target_angle)
		animate(manipulator_arm, transform = final_matrix, time = BASE_INTERACTION_TIME / speed_multiplier)
		addtimer(CALLBACK(callback_object, callback, src), BASE_INTERACTION_TIME / speed_multiplier)
		manipulator_arm.arm_angle = target_angle
		return

	var/next_angle = current_angle + rotation_step
	var/matrix/next_matrix = matrix()
	next_matrix.Turn(next_angle)
	animate(manipulator_arm, transform = next_matrix, time = BASE_INTERACTION_TIME / speed_multiplier)

	manipulator_arm.arm_angle = next_angle
	addtimer(CALLBACK(src, PROC_REF(do_step_rotation), target_task, callback_object, callback, next_angle, target_angle, rotation_step), BASE_INTERACTION_TIME / speed_multiplier)

/obj/machinery/big_manipulator/proc/try_drop_thing(datum/manipulator_task/cargo/dropoff_base/drop/destination_task)
	var/drop_endpoint = destination_task.find_drop_endpoint()
	var/obj/actual_held_object = held_object?.resolve()

	if(isnull(drop_endpoint))
		return FALSE

	if(!actual_held_object)
		return FALSE

	// Hide from claw first, then move.
	hide_held_item()

	var/atom/drop_target = drop_endpoint


	if(iscloset(drop_target))
		var/obj/structure/closet/target_closet = drop_target
		if(target_closet.insert(actual_held_object))
			finish_manipulation()
			return TRUE

	// Try to insert into a smartfridge.
	else if(istype(drop_target, /obj/machinery/smartfridge))
		var/obj/machinery/smartfridge/target_fridge = drop_target
		if(isitem(actual_held_object) && target_fridge.accept_check(actual_held_object))
			if(target_fridge.load(actual_held_object))
				finish_manipulation()
				return TRUE

	// Try to insert into a storage item (backpacks, bags and so on).
	else if(isitem(actual_held_object))
		var/datum/component/storage/storage_component = drop_target.GetComponent(/datum/component/storage)
		if(storage_component && storage_component.handle_item_insertion(actual_held_object, TRUE))
			finish_manipulation()
			return TRUE

	// Default: move to drop point.
	actual_held_object.forceMove(drop_endpoint)
	finish_manipulation()
	return TRUE

/obj/machinery/big_manipulator/proc/throw_thing(datum/manipulator_task/cargo/dropoff_base/throw/throw_task)
	var/turf/drop_turf = throw_task.interaction_turf
	var/atom/movable/held_atom = held_object?.resolve()

	if(!held_atom)
		finish_manipulation()
		return FALSE

	held_atom.forceMove(drop_turf)
	do_attack_animation(drop_turf)
	manipulator_arm.do_attack_animation(drop_turf)

	if(isliving(held_atom) && !(obj_flags & EMAGGED))
		held_atom.dir = get_dir(get_turf(held_atom), get_turf(src))
		finish_manipulation()
		return TRUE

	held_atom.throw_at(get_edge_target_turf(get_turf(src), get_dir(get_turf(src), drop_turf)), throw_task.throw_range, 2)
	finish_manipulation()
	return TRUE

/// Completes the current manipulation action and schedules the next step.
/obj/machinery/big_manipulator/proc/finish_manipulation()
	held_object = null
	update_claw(null)
	current_task = null

	SStgui.update_uis(src)

	if(stopping)
		complete_stopping_task()
		return

	schedule_next_cycle()

/// Completes the stopping task and transitions to idle
/obj/machinery/big_manipulator/proc/complete_stopping_task()
	on = FALSE
	stopping = FALSE
	next_cycle_scheduled = FALSE
	current_task = null
	unregister_task_turf_signals()
	waiting_for_signal = FALSE
	SStgui.update_uis(src)

/// Registers enter/exit signals on all unique cargo task turfs.
/obj/machinery/big_manipulator/proc/register_task_turf_signals()
	unregister_task_turf_signals()
	for(var/datum/manipulator_task/cargo/task in tasks)
		if(!task.interaction_turf || (task.interaction_turf in signal_turfs))
			continue
		signal_turfs += task.interaction_turf
		RegisterSignals(task.interaction_turf, list(COMSIG_ATOM_ENTERED, COMSIG_ATOM_EXITED), PROC_REF(on_task_turf_changed))

/// Unregisters all previously registered turf signals.
/obj/machinery/big_manipulator/proc/unregister_task_turf_signals()
	for(var/turf/t as anything in signal_turfs)
		UnregisterSignal(t, list(COMSIG_ATOM_ENTERED, COMSIG_ATOM_EXITED))
	signal_turfs = list()

/// Fires when something enters or leaves a watched task turf.
/obj/machinery/big_manipulator/proc/on_task_turf_changed(datum/source)
	SIGNAL_HANDLER
	if(!on || stopping || !waiting_for_signal)
		return
	something_happened()

/// Drop the held atom.
/obj/machinery/big_manipulator/proc/drop_held_atom()
	if(isnull(held_object))
		return
	var/obj/obj_resolve = held_object?.resolve()
	if(obj_resolve)
		obj_resolve.forceMove(get_turf(obj_resolve))
	finish_manipulation()
