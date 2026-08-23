/datum/manipulator_task
	var/name = "task"

/datum/manipulator_task/proc/can_run(obj/machinery/big_manipulator/manipulator)
	return FALSE

/datum/manipulator_task/proc/run_task(obj/machinery/big_manipulator/manipulator)
	return

/// Renamed from `serialize` to avoid clashing with the global datum serializer used by persistence.
/datum/manipulator_task/proc/serialize_task()
	return list("type" = type)

// ===== WAIT =====

/datum/manipulator_task/simple/wait
	name = "wait"
	var/time_seconds = 1

/datum/manipulator_task/simple/wait/can_run(obj/machinery/big_manipulator/manipulator)
	for(var/datum/manipulator_task/cargo/task in manipulator.tasks)
		if(task.can_run(manipulator))
			return TRUE
	return FALSE

/datum/manipulator_task/simple/wait/run_task(obj/machinery/big_manipulator/manipulator)
	manipulator.schedule_next_cycle(time_seconds SECONDS)

/datum/manipulator_task/simple/wait/serialize_task()
	var/list/data = ..()
	data["time_seconds"] = time_seconds
	return data

/datum/manipulator_task/simple/wait/New(..., serialized_data)
	..()
	if(serialized_data)
		time_seconds = serialized_data["time_seconds"]
	return

// ===== BASE CARGO =====

/datum/manipulator_task/cargo
	var/turf/interaction_turf
	var/offset_dx
	var/offset_dy

/datum/manipulator_task/cargo/New(turf/new_turf, manipulator_tier, serialized_data)
	if(serialized_data)
		var/list/offset = serialized_data["offset"]
		if(islist(offset))
			offset_dx = offset["dx"]
			offset_dy = offset["dy"]
		interaction_turf = new_turf
		return ..()

	if(!new_turf)
		stack_trace("New manipulator task created with no valid turf reference passed.")
		qdel(src)
		return

	if(isclosedturf(new_turf))
		qdel(src)
		return

	interaction_turf = new_turf
	return ..()

/datum/manipulator_task/cargo/proc/is_valid()
	if(!interaction_turf)
		return FALSE
	return !isclosedturf(interaction_turf)

/datum/manipulator_task/cargo/can_run(obj/machinery/big_manipulator/manipulator)
	return is_valid()

/datum/manipulator_task/cargo/serialize_task()
	var/list/data = ..()
	data["offset"] = list(
		"dx" = offset_dx,
		"dy" = offset_dy,
	)
	return data

/datum/manipulator_task/cargo/Destroy()
	interaction_turf = null
	return ..()

// ===== PICKUP =====

/datum/manipulator_task/cargo/pickup
	name = "pickup"
	var/pickup_eagerness = PICKUP_CAN_WAIT

/datum/manipulator_task/cargo/pickup/can_run(obj/machinery/big_manipulator/manipulator)
	if(!..())
		return FALSE
	if(manipulator.held_object)
		return FALSE
	for(var/atom/movable/candidate as anything in interaction_turf.contents)
		if(!is_valid_candidate(manipulator, candidate))
			continue
		if(pickup_eagerness == PICKUP_EAGER)
			return TRUE
		for(var/datum/manipulator_task/cargo/dropoff_base/dest in manipulator.tasks)
			if(dest.can_accept(candidate))
				return TRUE
	return FALSE

/// Returns TRUE if the candidate is something we are allowed and able to grab.
/datum/manipulator_task/cargo/proc/is_valid_candidate(obj/machinery/big_manipulator/manipulator, atom/movable/candidate)
	if(candidate.anchored || HAS_TRAIT(candidate, TRAIT_NODROP))
		return FALSE
	if(isitem(candidate))
		var/obj/item/candidate_item = candidate
		if(candidate_item.item_flags & (ABSTRACT|DROPDEL))
			return FALSE
	if(isliving(candidate) && !(manipulator.obj_flags & EMAGGED))
		return FALSE
	return TRUE

/datum/manipulator_task/cargo/pickup/run_task(obj/machinery/big_manipulator/manipulator)
	manipulator.rotate_to_point(src, src, PROC_REF(try_pickup))

/datum/manipulator_task/cargo/pickup/proc/try_pickup(obj/machinery/big_manipulator/manipulator)
	var/atom/movable/selected = find_pickup_candidate(manipulator)
	if(!selected)
		manipulator.nothing_ever_happens()
		return

	// Show in claw FIRST (vis_contents preserves full visual), then move into machine.
	manipulator.manipulator_arm.show_item(selected)
	manipulator.held_object = WEAKREF(selected)
	selected.forceMove(manipulator)
	manipulator.schedule_next_cycle()

/datum/manipulator_task/cargo/pickup/serialize_task()
	var/list/data = ..()
	data["pickup_eagerness"] = pickup_eagerness
	return data

/datum/manipulator_task/cargo/pickup/New(turf/new_turf, manipulator_tier, serialized_data)
	..(new_turf, manipulator_tier, serialized_data)
	if(serialized_data)
		pickup_eagerness = serialized_data["pickup_eagerness"]
	return

/datum/manipulator_task/cargo/pickup/proc/find_pickup_candidate(obj/machinery/big_manipulator/manipulator)
	var/list/candidates = list()

	for(var/atom/movable/candidate as anything in interaction_turf.contents)
		if(!is_valid_candidate(manipulator, candidate))
			continue
		if(pickup_eagerness == PICKUP_EAGER)
			candidates += candidate
			continue
		for(var/datum/manipulator_task/cargo/dropoff_base/dest in manipulator.tasks)
			if(dest.can_accept(candidate))
				candidates += candidate
				break

	if(!length(candidates))
		return null

	return manipulator.master_tasking.get_next_candidate(candidates)

// ===== BASE DROPOFF =====
// Base type for anything that accepts a `held_object`: drop, throw.
// Pickup iterates by this type to find a target point.

/datum/manipulator_task/cargo/dropoff_base
	name = "dropoff"

/datum/manipulator_task/cargo/dropoff_base/proc/can_accept(atom/movable/target)
	return is_valid()

/datum/manipulator_task/cargo/dropoff_base/run_task(obj/machinery/big_manipulator/manipulator)
	manipulator.rotate_to_point(src, src, PROC_REF(try_dropoff))

/datum/manipulator_task/cargo/dropoff_base/proc/try_dropoff(obj/machinery/big_manipulator/manipulator)
	var/obj/actual_held_object = manipulator.held_object?.resolve()
	if(!actual_held_object)
		manipulator.nothing_ever_happens()
		return FALSE
	do_dropoff(manipulator)
	return TRUE

/datum/manipulator_task/cargo/dropoff_base/proc/do_dropoff(obj/machinery/big_manipulator/manipulator)
	return

// ===== DROP =====

/datum/manipulator_task/cargo/dropoff_base/drop
	name = "drop"
	var/overflow_status = POINT_OVERFLOW_ALLOWED

/datum/manipulator_task/cargo/dropoff_base/drop/can_accept(atom/movable/target)
	if(!..())
		return FALSE

	var/list/atoms_on_the_turf = interaction_turf.contents
	switch(overflow_status)
		if(POINT_OVERFLOW_ALLOWED)
			return TRUE
		if(POINT_OVERFLOW_HELD)
			for(var/atom/movable/movable_atom as anything in atoms_on_the_turf)
				if(istype(movable_atom, target?.type))
					return FALSE
		if(POINT_OVERFLOW_FORBIDDEN)
			if(locate(/obj/item) in atoms_on_the_turf)
				return FALSE

	return TRUE

/datum/manipulator_task/cargo/dropoff_base/drop/serialize_task()
	var/list/data = ..()
	data["overflow_status"] = overflow_status
	return data

/datum/manipulator_task/cargo/dropoff_base/drop/New(turf/new_turf, manipulator_tier, serialized_data)
	..(new_turf, manipulator_tier, serialized_data)
	if(serialized_data)
		overflow_status = serialized_data["overflow_status"]
	return

/datum/manipulator_task/cargo/dropoff_base/drop/do_dropoff(obj/machinery/big_manipulator/manipulator)
	manipulator.try_drop_thing(src)

/datum/manipulator_task/cargo/dropoff_base/drop/proc/find_drop_endpoint()
	if(!is_valid())
		return null
	for(var/atom/movable/thing as anything in interaction_turf.contents)
		if(iscloset(thing))
			return thing
	for(var/atom/movable/thing as anything in interaction_turf.contents)
		if(istype(thing, /obj/machinery/smartfridge))
			return thing
	for(var/atom/movable/thing as anything in interaction_turf.contents)
		if(isitem(thing) && !isnull(thing.GetComponent(/datum/component/storage)))
			return thing
	return interaction_turf

// ===== THROW =====

/datum/manipulator_task/cargo/dropoff_base/throw
	name = "throw"
	var/throw_range = 1

/datum/manipulator_task/cargo/dropoff_base/throw/can_accept(atom/movable/target)
	return is_valid()

/datum/manipulator_task/cargo/dropoff_base/throw/serialize_task()
	var/list/data = ..()
	data["throw_range"] = throw_range
	return data

/datum/manipulator_task/cargo/dropoff_base/throw/New(turf/new_turf, manipulator_tier, serialized_data)
	..(new_turf, manipulator_tier, serialized_data)
	if(serialized_data)
		throw_range = serialized_data["throw_range"]
	return

/datum/manipulator_task/cargo/dropoff_base/throw/do_dropoff(obj/machinery/big_manipulator/manipulator)
	manipulator.throw_thing(src)
