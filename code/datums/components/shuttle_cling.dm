/// State for [/datum/component/shuttle_cling/proc/is_holding_on]
#define SHUTTLE_CLING_SUPER_LOST 0
#define SHUTTLE_CLING_NOT_HOLDING 1
#define SHUTTLE_CLING_CLINGING 2
#define SHUTTLE_CLING_ALL_GOOD 3

/// tg-style hyperspace drift: pulls movables along the transit "flow" unless they cling to the shuttle hull or buckle.
/datum/component/shuttle_cling
	var/direction
	var/hyperspace_type = /turf/open/space/transit
	var/datum/move_loop/move/hyperloop
	var/clinging_move_delay = 1 SECONDS
	var/not_clinging_move_delay = 0.2 SECONDS

/datum/component/shuttle_cling/Initialize(direction)
	. = ..()
	if(!ismovable(parent))
		return COMPONENT_INCOMPATIBLE
	if(!direction)
		return COMPONENT_INCOMPATIBLE
	src.direction = direction
	ADD_TRAIT(parent, TRAIT_HYPERSPACED, REF(src))
	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(update_state))
	RegisterSignal(parent, COMSIG_MOVABLE_UNBUCKLE, PROC_REF(update_state))
	if(isitem(parent))
		RegisterSignal(parent, COMSIG_ITEM_PICKUP, PROC_REF(on_picked_up))
	if(!HAS_TRAIT(parent, TRAIT_FREE_HYPERSPACE_MOVEMENT) && !HAS_TRAIT(parent, TRAIT_FREE_HYPERSPACE_SOFTCORDON_MOVEMENT))
		start_or_refresh_loop()
	update_state()

/datum/component/shuttle_cling/proc/start_or_refresh_loop()
	if(hyperloop || !parent)
		return
	if(HAS_TRAIT(parent, TRAIT_FREE_HYPERSPACE_MOVEMENT) || HAS_TRAIT(parent, TRAIT_FREE_HYPERSPACE_SOFTCORDON_MOVEMENT))
		return
	if(!is_on_hyperspace())
		return
	hyperloop = SSmove_manager.move(
		parent,
		direction,
		not_clinging_move_delay,
		INFINITY,
		SSmovement,
		MOVEMENT_ABOVE_SPACE_PRIORITY,
		MOVEMENT_LOOP_START_FAST,
		null,
	)

/datum/component/shuttle_cling/proc/stop_loop()
	if(parent)
		SSmove_manager.stop_looping(parent, SSmovement)
	hyperloop = null

/datum/component/shuttle_cling/proc/update_state()
	SIGNAL_HANDLER
	if(!parent)
		return
	if(!is_on_hyperspace())
		qdel(src)
		return
	if(HAS_TRAIT(parent, TRAIT_FREE_HYPERSPACE_MOVEMENT) || HAS_TRAIT(parent, TRAIT_FREE_HYPERSPACE_SOFTCORDON_MOVEMENT))
		stop_loop()
		return
	if(!hyperloop)
		start_or_refresh_loop()
	if(!hyperloop)
		return

	var/state = is_holding_on()
	if(state == SHUTTLE_CLING_ALL_GOOD)
		stop_loop()
		return

	switch(state)
		if(SHUTTLE_CLING_SUPER_LOST)
			launch_very_hard(parent)
			hyperloop.set_delay(not_clinging_move_delay)
			hyperloop.direction = direction
		if(SHUTTLE_CLING_NOT_HOLDING)
			hyperloop.set_delay(not_clinging_move_delay)
			hyperloop.direction = direction
		if(SHUTTLE_CLING_CLINGING)
			hyperloop.set_delay(clinging_move_delay)
			update_drift_direction(parent)

/datum/component/shuttle_cling/proc/is_holding_on()
	var/atom/movable/movee = parent
	if(!movee)
		return SHUTTLE_CLING_SUPER_LOST
	if(movee.pulledby || !isturf(movee.loc))
		return SHUTTLE_CLING_ALL_GOOD
	if(HAS_TRAIT(movee, TRAIT_FREE_HYPERSPACE_MOVEMENT) || HAS_TRAIT(movee, TRAIT_FREE_HYPERSPACE_SOFTCORDON_MOVEMENT))
		return SHUTTLE_CLING_ALL_GOOD

	if(!isliving(movee))
		/// Декоративные сингулярности ивента: иначе открытый космос = SUPER_LOST → `launch_very_hard` к краю Z-левела (копна у границы, не поток с шаттлом).
		if(istype(movee, /obj/singularity/gravitational/shuttle_event))
			if(is_tile_solid(get_step(movee, direction)))
				return SHUTTLE_CLING_CLINGING
			return SHUTTLE_CLING_NOT_HOLDING
		if(is_tile_solid(get_step(movee, direction)))
			return SHUTTLE_CLING_CLINGING
		return SHUTTLE_CLING_SUPER_LOST

	var/mob/living/living = movee
	if(living.buckled)
		return SHUTTLE_CLING_ALL_GOOD
	if(living.stat != CONSCIOUS || living.incapacitated())
		return SHUTTLE_CLING_NOT_HOLDING

	var/turf/here = get_turf(living)
	for(var/turf/T in orange(1, here))
		if(isclosedturf(T))
			return SHUTTLE_CLING_CLINGING
	for(var/obj/O in orange(1, here))
		if(O.anchored && O.density)
			return SHUTTLE_CLING_CLINGING
	return SHUTTLE_CLING_NOT_HOLDING

/datum/component/shuttle_cling/proc/is_on_hyperspace()
	var/atom/movable/clinger = parent
	return istype(clinger?.loc, hyperspace_type)

/datum/component/shuttle_cling/proc/launch_very_hard(atom/movable/byebye)
	var/turf/target = get_edge_target_turf(byebye, direction)
	if(target)
		byebye.safe_throw_at(target, 200, 1, null, TRUE, FALSE, null, MOVE_FORCE_EXTREMELY_STRONG)

/datum/component/shuttle_cling/proc/update_drift_direction(atom/movable/clinger)
	if(!hyperloop)
		return
	var/turf/next_step = get_step(clinger, direction)
	if(!is_tile_solid(next_step))
		hyperloop.direction = direction
		return
	for(var/side_dir in list(turn(direction, 90), turn(direction, -90)))
		if(!is_tile_solid(get_step(clinger, side_dir)))
			hyperloop.direction = direction | side_dir
			return
	hyperloop.direction = direction

/datum/component/shuttle_cling/proc/is_tile_solid(turf/maybe_solid)
	if(!maybe_solid)
		return FALSE
	if(isclosedturf(maybe_solid))
		return TRUE
	for(var/obj/blocker in maybe_solid.contents)
		if(blocker.density)
			return TRUE
	return FALSE

/datum/component/shuttle_cling/proc/on_picked_up()
	SIGNAL_HANDLER
	qdel(src)

/datum/component/shuttle_cling/Destroy(force)
	REMOVE_TRAIT(parent, TRAIT_HYPERSPACED, REF(src))
	stop_loop()
	return ..()

#undef SHUTTLE_CLING_SUPER_LOST
#undef SHUTTLE_CLING_NOT_HOLDING
#undef SHUTTLE_CLING_CLINGING
#undef SHUTTLE_CLING_ALL_GOOD
