#define STAIR_TERMINATOR_AUTOMATIC 0
#define STAIR_TERMINATOR_NO 1
#define STAIR_TERMINATOR_YES 2

// dir determines the direction of travel to go upwards (due to lack of sprites, currently only 1 and 2 make sense)
// stairs require /turf/open/openspace as the tile above them to work
// multiple stair objects can be chained together; the Z level transition will happen on the final stair object in the chain

/obj/structure/stairs
	name = "stairs"
	desc = "Ступеньки на этаж выше. Шевроны показывают, в какую сторону подниматься."
	icon = 'icons/obj/stairs.dmi'
	icon_state = "stairs"
	anchored = TRUE

	var/force_open_above = FALSE // replaces the turf above this stair obj with /turf/open/openspace
	var/terminator_mode = STAIR_TERMINATOR_AUTOMATIC
	var/turf/listeningTo

/obj/structure/stairs/north
	dir = NORTH

/obj/structure/stairs/south
	dir = SOUTH

/obj/structure/stairs/east
	dir = EAST

/obj/structure/stairs/west
	dir = WEST

/obj/structure/stairs/Initialize(mapload)
	GLOB.stairs += src
	if(force_open_above)
		force_open_above()
		build_signal_listener()
	update_surrounding()
	return ..()

/obj/structure/stairs/Destroy()
	GLOB.stairs -= src
	listeningTo = null
	return ..()

/obj/structure/stairs/Move()			//Look this should never happen but...
	. = ..()
	if(force_open_above)
		build_signal_listener()
	update_surrounding()

/obj/structure/stairs/proc/update_surrounding()
	update_icon()
	for(var/i in GLOB.cardinals)
		var/turf/T = get_step(get_turf(src), i)
		var/obj/structure/stairs/S = locate() in T
		if(S)
			S.update_icon()

/obj/structure/stairs/Uncross(atom/movable/AM, turf/newloc)
	if(!newloc || !AM)
		return ..()
	if(!isobserver(AM) && isTerminator() && (get_dir(src, newloc) == dir))
		//Приоритет выше CURRENTLY_Z_FALLING, иначе поднимающегося перехватит openspace на целевом турфе.
		AM.set_currently_z_moving(CURRENTLY_Z_ASCENDING)
		stair_ascend(AM)
		AM.set_currently_z_moving(FALSE, TRUE)
		return FALSE
	return ..()

/obj/structure/stairs/Cross(atom/movable/AM)
	if(isTerminator() && (get_dir(src, AM) == dir))
		return FALSE
	return ..()

/obj/structure/stairs/update_icon_state()
	if(isTerminator())
		icon_state = "stairs_t"
	else
		icon_state = "stairs"

/obj/structure/stairs/update_overlays()
	. = ..()
	//Без своих слоя и плоскости: оверлей наследует их у ступенек, а голая константа увела бы шевроны на этаж выше.
	var/mutable_appearance/ascent_arrows = mutable_appearance('icons/turf/decals.dmi', "arrows")
	ascent_arrows.dir = dir
	. += ascent_arrows

/// Шевроны нарисованы под dir, поэтому поворот ступенек обязан их перерисовать.
/obj/structure/stairs/setDir(newdir, ismousemovement = FALSE)
	if(dir == newdir)
		return ..()
	. = ..()
	update_icon(UPDATE_OVERLAYS)

/obj/structure/stairs/examine(mob/user)
	. = ..()
	. += span_notice("Подниматься на [dir2text_ru(dir) || "непонятно куда"].")

	var/turf/source = get_turf(src)
	var/turf/landing = source ? get_step_multiz(source, (dir|UP)) : null
	if(!landing)
		. += span_warning("Наверху ничего нет: подняться отсюда не выйдет.")
		return
	if(!isTerminator())
		. += span_notice("Это середина марша - подъём случится на верхней ступеньке.")
		return
	. += span_notice("Наверху: [get_area_name(landing) || "неизвестно что"].")

/obj/structure/stairs/proc/stair_ascend(atom/movable/climber)
	var/turf/source = get_turf(src)
	var/turf/checking = GET_TURF_ABOVE(source)
	if(!istype(checking))
		return
	// Интересует только то, что проход не перекрыт: долетит климбер или нет, решит zMove.
	if(!climber.can_z_move(UP, source, checking, ZMOVE_ALLOW_BUCKLED))
		return
	var/turf/target = get_step_multiz(source, (dir|UP))
	if(!istype(target))
		return
	//Don't throw them into a tile that will just dump them back down.
	if(climber.can_z_move(DOWN, target, null, ZMOVE_FALL_FLAGS))
		return
	climber.zMove(null, target, ZMOVE_STAIRS_FLAGS|ZMOVE_INCLUDE_PULLED)

/obj/structure/stairs/vv_edit_var(var_name, var_value)
	. = ..()
	if(!.)
		return
	if(var_name != NAMEOF(src, force_open_above))
		return
	if(!var_value)
		if(listeningTo)
			UnregisterSignal(listeningTo, COMSIG_TURF_MULTIZ_NEW)
			listeningTo = null
	else
		build_signal_listener()
		force_open_above()

/obj/structure/stairs/proc/build_signal_listener()
	if(listeningTo)
		UnregisterSignal(listeningTo, COMSIG_TURF_MULTIZ_NEW)
	var/turf/open/openspace/T = get_step_multiz(get_turf(src), UP)
	RegisterSignal(T, COMSIG_TURF_MULTIZ_NEW, PROC_REF(on_multiz_new))
	listeningTo = T

/obj/structure/stairs/proc/force_open_above()
	var/turf/open/openspace/T = get_step_multiz(get_turf(src), UP)
	if(T && !istype(T))
		T.ChangeTurf(/turf/open/openspace, flags = CHANGETURF_INHERIT_AIR)

/obj/structure/stairs/proc/on_multiz_new(turf/source, dir)
	//SIGNAL_HANDLER
	SHOULD_NOT_SLEEP(TRUE) //the same thing.

	if(dir == UP)
		var/turf/open/openspace/T = get_step_multiz(get_turf(src), UP)
		if(T && !istype(T))
			T.ChangeTurf(/turf/open/openspace, flags = CHANGETURF_INHERIT_AIR)

/obj/structure/stairs/intercept_zImpact(list/falling_movables, levels = 1)
	. = ..()
	if(isTerminator())
		. |= FALL_INTERCEPTED | FALL_NO_MESSAGE | FALL_RETAIN_PULL

/obj/structure/stairs/proc/isTerminator()			//If this is the last stair in a chain and should move mobs up
	if(terminator_mode != STAIR_TERMINATOR_AUTOMATIC)
		return (terminator_mode == STAIR_TERMINATOR_YES)
	var/turf/T = get_turf(src)
	if(!T)
		return FALSE
	var/turf/them = get_step(T, dir)
	if(!them)
		return FALSE
	for(var/obj/structure/stairs/S in them)
		if(S.dir == dir)
			return FALSE
	return TRUE
