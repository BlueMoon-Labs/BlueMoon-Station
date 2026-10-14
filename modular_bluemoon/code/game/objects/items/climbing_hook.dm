/obj/item/climbing_hook
	name = "climbing hook"
	desc = "Крюк с верёвкой: зацепиться за край дыры и вылезти на этаж выше или спуститься на этаж ниже."
	icon = 'modular_bluemoon/icons/obj/climbing_hook.dmi'
	icon_state = "climbingrope"
	item_state = "crowbar_brass"
	lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
	force = 5
	throwforce = 10
	throw_range = 4
	w_class = WEIGHT_CLASS_SMALL
	attack_verb = list("whacked", "flailed", "bludgeoned")
	resistance_flags = FLAMMABLE
	var/climb_time = 2.5 SECONDS
	reach = 2

/obj/item/climbing_hook/examine(mob/user)
	. = ..()
	. += span_notice("Посмотрите вверх или вниз (по умолчанию P и ;) и кликните по твёрдому полу у края дыры на другом этаже.")

/obj/item/climbing_hook/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	var/turf/destination = get_turf(target)
	if(!destination || !isliving(user) || !isturf(user.loc) || destination.z == user.z)
		return
	climb(user, destination)

/obj/item/climbing_hook/proc/climb(mob/living/user, turf/destination)
	var/turf/user_turf = user.loc
	var/going_up = destination.z > user_turf.z
	var/turf/hole = going_up ? GET_TURF_ABOVE(user_turf) : GET_TURF_ABOVE(destination)
	if(!hole || hole.z != (going_up ? destination.z : user_turf.z))
		balloon_alert(user, "слишком далеко!")
		return
	if(flat_distance(destination, hole) > reach - 1 || (!going_up && flat_distance(user_turf, hole) > 1))
		balloon_alert(user, "слишком далеко!")
		return
	if(target_blocked(user, destination, hole))
		balloon_alert(user, "туда не забраться!")
		return

	var/turf/hole_level = going_up ? hole : GET_TURF_BELOW(hole)
	var/away_dir = get_dir(hole_level, destination)
	user.visible_message(span_notice("[user] начинает [going_up ? "подниматься" : "спускаться"] по [src]."), span_notice("Вы цепляете [src] и начинаете [going_up ? "подниматься" : "спускаться"]."))
	playsound(destination, 'sound/effects/picaxe1.ogg', 50)
	playsound(user_turf, 'sound/effects/picaxe1.ogg', 50)
	var/list/effects = list(new /obj/effect/temp_visual/climbing_hook(destination, away_dir), new /obj/effect/temp_visual/climbing_hook(user_turf, away_dir))
	if(do_after(user, climb_time, user) && !target_blocked(user, destination, hole))
		user.forceMove(destination)
	QDEL_LIST(effects)

/// Расстояние по клеткам в плоскости, без учёта этажа.
/obj/item/climbing_hook/proc/flat_distance(turf/first, turf/second)
	return max(abs(first.x - second.x), abs(first.y - second.y))

/// Пол назначения занят, с него упадёшь обратно, или дыра закрыта.
/obj/item/climbing_hook/proc/target_blocked(mob/living/user, turf/destination, turf/hole)
	if(destination.density || hole.density)
		return TRUE
	if(isopenspaceturf(destination) && destination.zPassOut(user, DOWN, GET_TURF_BELOW(destination)))
		return TRUE
	if(!isopenspaceturf(hole) || !hole.zPassOut(user, DOWN, GET_TURF_BELOW(hole)))
		return TRUE
	var/turf/hole_level = hole.z == destination.z ? hole : GET_TURF_BELOW(hole)
	var/hole_dir = get_dir(destination, hole_level)
	for(var/atom/movable/thing as anything in destination)
		if(isliving(thing) || HAS_TRAIT(thing, TRAIT_CLIMBABLE))
			continue
		if((thing.flags_1 & ON_BORDER_1) && thing.dir != hole_dir)
			continue
		if(thing.density)
			return TRUE
	return FALSE

/obj/item/climbing_hook/emergency
	name = "emergency climbing hook"
	desc = "Аварийный крюк с верёвкой, чтобы выбраться через дыру на соседний этаж. Лезть по нему дольше обычного."
	climb_time = 4 SECONDS

/obj/effect/temp_visual/climbing_hook
	icon = 'icons/mob/aibots.dmi'
	icon_state = "path_indicator"
	layer = BELOW_MOB_LAYER
	duration = 4 SECONDS
	randomdir = FALSE

/obj/effect/temp_visual/climbing_hook/Initialize(mapload, direction)
	. = ..()
	setDir(direction)
