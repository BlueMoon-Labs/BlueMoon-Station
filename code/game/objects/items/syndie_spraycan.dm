#define SYNDIE_DRAW_TIME 3 SECONDS

/obj/item/traitor_spraycan
	name = "Syndicate spraycan"
	desc = "Этим баллончиком можно нанести узор областью 3х3. Краски хватает ровно на один финальный слой."
	icon = 'icons/obj/crayons.dmi'
	icon_state = "deathcan"
	item_state = "spraycan"
	lefthand_file = 'icons/mob/inhands/equipment/hydroponics_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/hydroponics_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL
	var/static/list/no_draw_turfs = typecacheof(list(/turf/open/space, /turf/open/openspace, /turf/open/lava, /turf/open/chasm))

	/// Are we currently drawing? Used to prevent spam clicks for do_while
	var/drawing_rune = FALSE
	/// Set to true if we finished drawing something, this spraycan is now useless
	var/expended = FALSE
	/// Тип руны, которую рисует этот баллончик.
	var/rune_type = /obj/effect/decal/traitor_rune

/obj/item/traitor_spraycan/inteq
	name = "InteQ spraycan"
	desc = "Этим баллончиком можно нанести узор областью 3х3. Краски хватает ровно на один финальный слой."
	icon_state = "deathcan"
	item_state = "spraycan"
	rune_type = /obj/effect/decal/traitor_rune/inteq_rune

/obj/item/traitor_spraycan/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	if (!isliving(user) || !proximity_flag)
		return
	if (expended)
		user.balloon_alert(user, "краска закончилась...")
		return
	if (drawing_rune)
		user.balloon_alert(user, "в процессе!")
		return
	if (isturf(target))
		try_draw_new_rune(user, target)
	else if (istype(target, /obj/effect/decal/traitor_rune))
		try_complete_rune(user, target)

/**
 * Attempt to draw a rune on [target_turf].
 * Shamelessly adapted from the heretic rune drawing process.
 *
 * Arguments
 * * user - the mob drawing the rune
 * * target_turf - the place the rune's being drawn
 */
/obj/item/traitor_spraycan/proc/try_draw_new_rune(mob/living/user, turf/target_turf)
	for(var/turf/nearby_turf as anything in RANGE_TURFS(1, target_turf))
		if (!isopenturf(nearby_turf) || is_type_in_typecache(nearby_turf, no_draw_turfs))
			user.balloon_alert(user, "нужна свободная область 3х3!")
			return

	draw_rune(user, target_turf)

/**
 * Draw your stage one rune on the ground and store it.
 *
 * Arguments
 * * user - the mob drawing the rune
 * * target_turf - the place the rune's being drawn
 */
/obj/item/traitor_spraycan/proc/draw_rune(mob/living/user, turf/target_turf)
	if (!try_draw_step("рисую контур...", user, target_turf))
		return
	try_complete_rune(user, new rune_type(target_turf))

/**
 * Holder for repeated code to do something after a message and a set amount of time.
 *
 * Arguments
 * * output - a string to show when you start the process
 * * user - the mob drawing the rune
 * * target - what they're trying to draw, or the place they are trying to draw on
 */
/obj/item/traitor_spraycan/proc/try_draw_step(start_output, mob/living/user, atom/target)
	drawing_rune = TRUE
	user.balloon_alert(user, "[start_output]")
	var/wait_time = SYNDIE_DRAW_TIME

	if(HAS_TRAIT(user, TRAIT_TAGGER))
		wait_time *= 0.5

	if(!do_after(user, wait_time, target, cog_icon = null, extra_checks = CALLBACK(src, PROC_REF(adjacency_check), user, target)))
		user.balloon_alert(user, "прервано!")
		drawing_rune = FALSE
		return FALSE

	playsound(src, 'sound/effects/spray.ogg', 5, TRUE, 5)
	drawing_rune = FALSE
	return TRUE

#define RUNE_STAGE_OUTLINE 0
#define RUNE_STAGE_COLOURED 1
#define RUNE_STAGE_COMPLETE 2
#define RUNE_STAGE_REMOVABLE 3

/**
 * Try to upgrade a floor rune to its next stage.
 *
 * Arguments
 * * user - the mob drawing the rune
 * * target_turf - the place the rune's being drawn
 */
/obj/item/traitor_spraycan/proc/try_complete_rune(mob/living/user, obj/effect/decal/traitor_rune/rune)
	switch(rune.drawn_stage)
		if (RUNE_STAGE_OUTLINE)
			if (!try_draw_step("прорисовываю узор...", user, rune))
				return
			if (!rune)
				user.balloon_alert(user, "граффити уничтожено!")
				return
			rune.set_stage(RUNE_STAGE_COLOURED)
			try_complete_rune(user, rune)

		if (RUNE_STAGE_COLOURED)
			if (!try_draw_step("наношу финальный слой...", user, rune))
				return
			if (!rune)
				user.balloon_alert(user, "граффити уничтожено!")
				return
			user.balloon_alert(user, "готово!")
			rune.set_stage(RUNE_STAGE_COMPLETE)
			expended = TRUE
			desc = "краска закончилась."

		if (RUNE_STAGE_COMPLETE, RUNE_STAGE_REMOVABLE)
			user.balloon_alert(user, "всё уже нарисовано!")

///Checks if the user is still adjacent to the target (used for do_after extra_checks)
/obj/item/traitor_spraycan/proc/adjacency_check(mob/user, atom/target)
	if(!user.Adjacent(target))
		user.balloon_alert(user, "слишком далеко!")
		return FALSE
	return TRUE

/obj/effect/decal/traitor_rune
	name = "Syndicate graffiti"
	desc = "Похоже, это будет... логотип Синдиката?"
	icon = 'icons/effects/96x96.dmi'
	icon_state = "traitor_rune_outline"
	pixel_x = -32
	pixel_y = -32
	gender = NEUTER
	resistance_flags = FIRE_PROOF | UNACIDABLE | ACID_PROOF
	plane = FLOOR_PLANE
	layer = TURF_DECAL_LAYER + 0.6

	var/rune_outline_state = "traitor_rune_outline"
	var/rune_done_state = "traitor_rune_done"
	var/rune_sheen_state = "traitor_rune_sheen"
	var/desc_outline = "Похоже, это будет... логотип Синдиката?"
	var/desc_done = "Большое изображение логотипа Синдиката."
	var/desc_done_sheen = "Большое изображение логотипа Синдиката. Краска ещё блестит."

	var/spawns_demoraliser = FALSE
	var/drawn_stage = RUNE_STAGE_OUTLINE
	var/datum/proximity_monitor/advanced/demoraliser/demoraliser
	var/protected_timer

	var/slips_walkers = FALSE

/obj/effect/decal/traitor_rune/inteq_rune
	name = "InteQ graffiti"
	desc = "Похоже, это будет... логотип InteQ?"
	icon_state = "inteq_rune_outline"
	rune_outline_state = "inteq_rune_outline"
	rune_done_state = "inteq_rune_done"
	rune_sheen_state = "inteq_rune_sheen"
	desc_outline = "Похоже, это будет... логотип InteQ?"
	desc_done = "Большое изображение логотипа InteQ."
	desc_done_sheen = "Большое изображение логотипа InteQ. Краска ещё блестит."
	spawns_demoraliser = TRUE

	slips_walkers = TRUE

/obj/effect/decal/traitor_rune/inteq_rune/examine(mob/user)
	. = ..()
	switch(drawn_stage)
		if (RUNE_STAGE_COMPLETE)
			. = ..()
			. += span_notice("Убрать граффити не получится, краска лежит слишком плотно. Надо подождать.")
		if (RUNE_STAGE_REMOVABLE)
			. = ..()
			. += span_notice("Можно убрать <b>мылом</b>.")

/obj/effect/decal/traitor_rune/Destroy()
	STOP_PROCESSING(SSobj, src)
	deltimer(protected_timer)
	QDEL_NULL(demoraliser)
	for(var/turf/slip_turf in RANGE_TURFS(1, loc))
		var/datum/component/slippery/slip = slip_turf.GetComponent(/datum/component/slippery)
		if (slip)
			qdel(slip)
	return ..()

/obj/effect/decal/traitor_rune/process()
	if(!demoraliser)
		STOP_PROCESSING(SSobj, src)
		return
	if(!demoraliser.can_scan())
		return
	do_scare_scan()

/obj/effect/decal/traitor_rune/proc/do_scare_scan()
	demoraliser.do_scare_scan()

/**
 * Sets the "drawing stage" of the rune.
 * This affects the appearance, behaviour, and description of the effect.
 *
 * Arguments
 * * stage - new stage to apply
 */

/obj/effect/decal/traitor_rune/proc/set_stage(stage)
	drawn_stage = stage
	switch(drawn_stage)
		if (RUNE_STAGE_OUTLINE)
			icon_state = rune_outline_state
			desc = desc_outline

		if (RUNE_STAGE_COLOURED, RUNE_STAGE_REMOVABLE)
			icon_state = rune_done_state
			desc = desc_done
			clear_slip()

		if (RUNE_STAGE_COMPLETE)
			icon_state = rune_sheen_state
			desc = desc_done_sheen
			if (spawns_demoraliser)
				demoraliser = new(src, 7, TRUE)
				START_PROCESSING(SSobj, src)
			if (slips_walkers)
				for(var/turf/nearby_turf in RANGE_TURFS(1, loc))
					nearby_turf.AddComponent(/datum/component/slippery, 6 SECONDS, NO_SLIP_WHEN_WALKING)
			protected_timer = addtimer(CALLBACK(src, PROC_REF(set_stage), RUNE_STAGE_REMOVABLE), 5 MINUTES)

/obj/effect/decal/traitor_rune/proc/clear_slip()
	for(var/turf/slip_turf in RANGE_TURFS(1, loc))
		var/datum/component/slippery/slip = slip_turf.GetComponent(/datum/component/slippery)
		if (slip)
			qdel(slip)


/obj/effect/decal/traitor_rune/attackby(obj/item/W, mob/user, params)
	if (istype(W, /obj/item/soap))
		if (drawn_stage == RUNE_STAGE_COMPLETE)
			user.balloon_alert(user, "краска ещё не высохла!")
			return
		user.balloon_alert(user, "оттираю...")
		if (QDELETED(src))
			return
		user.balloon_alert(user, "стерто!")
		qdel(src)
		return
	return ..()

#undef SYNDIE_DRAW_TIME
#undef RUNE_STAGE_COLOURED
#undef RUNE_STAGE_COMPLETE
#undef RUNE_STAGE_OUTLINE
#undef RUNE_STAGE_REMOVABLE
