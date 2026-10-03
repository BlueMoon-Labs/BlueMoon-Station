#define PLATE_INTACT 0
#define PLATE_BOLTS_LOOSENED 1
#define PLATE_CUT 2

/// RCD-proof plating for multi-z maps: protects the room below from being dug into from above.
/turf/open/floor/plating/reinforced
	name = "reinforced plating"
	desc = "Толстый настил из нескольких слоёв металла. Защищает помещение этажом ниже."
	icon = 'modular_bluemoon/icons/turf/reinforced_plating.dmi'
	icon_state = "r_plate-0"
	base_icon_state = "r_plate"
	thermal_conductivity = 0.025
	heat_capacity = INFINITY
	baseturfs = /turf/open/floor/plating
	attachment_holes = FALSE
	var/deconstruction_state = PLATE_INTACT

/turf/open/floor/plating/reinforced/airless
	initial_gas_mix = AIRLESS_ATMOS

/turf/open/floor/plating/reinforced/examine(mob/user)
	. = ..()
	switch(deconstruction_state)
		if(PLATE_INTACT)
			. += span_notice("Усиление настила надёжно <b>закручено</b> болтами.")
		if(PLATE_BOLTS_LOOSENED)
			. += span_notice("Болты усиления <i>выкручены</i>, но оно всё ещё <b>приварено</b> к настилу.")
		if(PLATE_CUT)
			. += span_notice("Усиление <i>прорезано</i> и держится <b>неплотно</b>.")

/turf/open/floor/plating/reinforced/update_icon_state()
	. = ..()
	icon_state = "[base_icon_state]-[deconstruction_state]"

/turf/open/floor/plating/reinforced/break_tile()
	return

/turf/open/floor/plating/reinforced/burn_tile()
	return

/turf/open/floor/plating/reinforced/rcd_vals(mob/user, obj/item/construction/rcd/the_rcd)
	if(the_rcd.mode == RCD_DECONSTRUCT)
		return FALSE
	return ..()

/turf/open/floor/plating/reinforced/wrench_act(mob/living/user, obj/item/tool)
	if(deconstruction_state != PLATE_INTACT)
		return FALSE
	balloon_alert(user, "откручиваю болты...")
	if(!tool.use_tool(src, user, 10 SECONDS, volume = 100) || deconstruction_state != PLATE_INTACT)
		return TRUE
	set_deconstruction_state(PLATE_BOLTS_LOOSENED)
	drop_screws()
	balloon_alert(user, "болты выкручены")
	return TRUE

/turf/open/floor/plating/reinforced/screwdriver_act(mob/living/user, obj/item/tool)
	if(deconstruction_state != PLATE_BOLTS_LOOSENED)
		return FALSE
	balloon_alert(user, "закручиваю болты...")
	if(!tool.use_tool(src, user, 15 SECONDS, volume = 100) || deconstruction_state != PLATE_BOLTS_LOOSENED)
		return TRUE
	set_deconstruction_state(PLATE_INTACT)
	balloon_alert(user, "закреплено")
	return TRUE

/turf/open/floor/plating/reinforced/welder_act(mob/living/user, obj/item/tool)
	var/target_state
	switch(deconstruction_state)
		if(PLATE_BOLTS_LOOSENED)
			target_state = PLATE_CUT
		if(PLATE_CUT)
			target_state = PLATE_BOLTS_LOOSENED
		else
			return ..()
	if(!tool.tool_start_check(user, amount = 3))
		return TRUE
	var/start_state = deconstruction_state
	balloon_alert(user, target_state == PLATE_CUT ? "прорезаю..." : "привариваю обратно...")
	if(!tool.use_tool(src, user, 15 SECONDS, amount = 3, volume = 100) || deconstruction_state != start_state)
		return TRUE
	set_deconstruction_state(target_state)
	balloon_alert(user, target_state == PLATE_CUT ? "прорезано" : "приварено")
	return TRUE

/turf/open/floor/plating/reinforced/crowbar_act(mob/living/user, obj/item/tool)
	if(deconstruction_state != PLATE_CUT)
		return TRUE
	balloon_alert(user, "отдираю...")
	if(!tool.use_tool(src, user, 20 SECONDS, volume = 100) || deconstruction_state != PLATE_CUT)
		return TRUE
	balloon_alert(user, "оторвано")
	new /obj/item/stack/sheet/plasteel(src, 2)
	ScrapeAway(flags = CHANGETURF_INHERIT_AIR)
	return TRUE

/turf/open/floor/plating/reinforced/proc/set_deconstruction_state(new_state)
	deconstruction_state = new_state
	update_appearance(UPDATE_ICON)

/// Loosened bolts fall to the floor below as a warning to whoever is there.
/turf/open/floor/plating/reinforced/proc/drop_screws()
	var/turf/below_turf = get_step_multiz(src, DOWN)
	while(istype(below_turf, /turf/open/openspace))
		below_turf = get_step_multiz(below_turf, DOWN)
	if(isnull(below_turf) || isspaceturf(below_turf))
		return
	new /obj/effect/decal/cleanable/glass/plastitanium/screws(below_turf)
	playsound(below_turf, 'sound/effects/pop.ogg', 100, TRUE)

/obj/effect/decal/cleanable/glass/plastitanium/screws
	name = "pile of screws"
	desc = "Похоже, они упали с потолка."

/// Puts `roof` into the baseturfs right above `floor`, if `floor` is there.
/turf/proc/stack_ontop_of_baseturf(floor, roof)
	var/list/new_baseturfs = islist(baseturfs) ? baseturfs.Copy() : list(baseturfs)
	var/floor_position = new_baseturfs.Find(floor)
	if(!floor_position)
		return
	new_baseturfs.Insert(floor_position + 1, roof)
	baseturfs = new_baseturfs

/obj/effect/baseturf_helper/reinforced_plating
	name = "reinforced plating baseturf editor"
	baseturf = /turf/open/floor/plating/reinforced
	baseturf_to_replace = list(/turf/open/floor/plating)

/obj/effect/baseturf_helper/reinforced_plating/replace_baseturf(turf/thing)
	if(istype(thing, /turf/open/floor/plating))
		return
	thing.stack_ontop_of_baseturf(/turf/open/floor/plating, baseturf)

/// Reinforces the floor of the deck above every turf of the area it is placed in.
/obj/effect/baseturf_helper/reinforced_plating/ceiling
	name = "reinforced ceiling plating baseturf editor"

/obj/effect/baseturf_helper/reinforced_plating/ceiling/replace_baseturf(turf/thing)
	var/turf/ceiling = get_step_multiz(thing, UP)
	if(isnull(ceiling) || isspaceturf(ceiling) || istype(ceiling, /turf/open/openspace))
		return
	return ..(ceiling)

#undef PLATE_INTACT
#undef PLATE_BOLTS_LOOSENED
#undef PLATE_CUT
