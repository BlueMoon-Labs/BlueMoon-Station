// Так называемый cliff_falling, или же падение с горы, для домейна.
MOVEMENT_SUBSYSTEM_DEF(cliff_falling)
	name = "Cliff Falling"
	priority = 24
	flags = SS_NO_INIT | SS_TICKER
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME

	var/list/cliff_grinders = list()
	var/list/cliff_fall_distance = list()

/datum/controller/subsystem/movement/cliff_falling/proc/start_falling(atom/movable/faller, turf/open/cliff/cliff)
	var/mover = SSmove_manager.move(
		moving = faller,
		direction = cliff.fall_direction,
		delay = cliff.fall_speed,
		subsystem = src,
		priority = MOVEMENT_ABOVE_SPACE_PRIORITY,
		flags = MOVEMENT_LOOP_NO_DIR_UPDATE,
	)

	cliff_grinders[faller] = mover
	cliff_fall_distance[faller] = 1

	if(isliving(faller))
		var/mob/living/living = faller
		living.spin(2 SECONDS, 1)

	RegisterSignal(faller, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))
	RegisterSignal(faller, COMSIG_QDELETING, PROC_REF(clear_references))
	RegisterSignal(faller, COMSIG_MOVABLE_PRE_MOVE, PROC_REF(check_move))

/datum/controller/subsystem/movement/cliff_falling/proc/on_moved(atom/movable/mover, turf/old_loc)
	SIGNAL_HANDLER

	var/turf/open/cliff/new_cliff = mover.loc
	if(!iscliffturf(new_cliff))
		var/fall_distance = cliff_fall_distance[mover] || 0
		if(isliving(mover) && fall_distance > 0)
			var/mob/living/living = mover
			living.adjustBruteLoss(fall_distance * 5)
			living.Knockdown(max(1 SECONDS, fall_distance * 0.25 SECONDS))
			living.visible_message(
				span_danger("[living] врезается в землю!"),
				span_danger("Вы врезаетесь в землю!"),
			)

		var/datum/move_loop/move/falling = cliff_grinders[mover]
		clear_references(mover)
		qdel(falling)
		return

	cliff_fall_distance[mover] = (cliff_fall_distance[mover] || 1) + 1
	new_cliff.on_fall(mover)

	if(old_loc.type == new_cliff)
		return

	var/datum/move_loop/move/fall = cliff_grinders[mover]
	fall.set_delay(new_cliff.fall_speed)

/datum/controller/subsystem/movement/cliff_falling/proc/clear_references(atom/movable/deletee)
	SIGNAL_HANDLER

	cliff_grinders -= deletee
	cliff_fall_distance -= deletee
	UnregisterSignal(deletee, list(COMSIG_MOVABLE_MOVED, COMSIG_QDELETING, COMSIG_MOVABLE_PRE_MOVE))

/datum/controller/subsystem/movement/cliff_falling/proc/check_move(atom/movable/mover, turf/target)
	SIGNAL_HANDLER

	var/turf/open/cliff/cliff_turf = get_turf(mover)
	if(!iscliffturf(cliff_turf))
		clear_references(mover)
		return

	if(!cliff_turf.can_move(mover, target))
		return COMPONENT_MOVABLE_BLOCK_PRE_MOVE
