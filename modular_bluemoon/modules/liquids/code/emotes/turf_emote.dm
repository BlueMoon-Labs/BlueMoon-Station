// LIQUIDS ADD - simplified water_aspect emote (NovaSector *turf emote, water-only)
/mob/living
	var/obj/owned_turf

/obj/structure/mark_turf
	name = "turf"
	icon = 'modular_bluemoon/modules/liquids/icons/effects/turf_effects.dmi'
	desc = "It's turf." //Debug stuff, won't be seen
	layer = ABOVE_OBJ_LAYER
	anchored = TRUE
	density = FALSE
	max_integrity = 15

/obj/structure/mark_turf/Initialize(mapload, current_turf)
	. = ..()
	switch(current_turf)
		if("water")
			name = "puddle of water"
			desc = "It's a patch of water."
			icon_state = "water"
			src.add_overlay(image('modular_bluemoon/modules/liquids/icons/effects/turf_effects.dmi', "water_top", ABOVE_MOB_LAYER + 0.01))
			flick_overlay_static(image('modular_bluemoon/modules/liquids/icons/obj/effects/splash.dmi', "splash", ABOVE_MOB_LAYER + 0.01), 20)
			playsound(get_turf(src), 'modular_bluemoon/modules/liquids/sound/effects/watersplash.ogg', 25, TRUE)
		else
			return

/obj/structure/mark_turf/proc/turf_check(mob/living/user) //This gets called when a player leaves their turf
	QDEL_IN(src, 15 SECONDS)
	user.owned_turf = null

/datum/emote/sound/human/water
	name = "Вода"
	key = "water"
	key_third_person = "waters"
	message = "одним движением руки создаёт лужу чистой воды."
	emote_cooldown = 4 SECONDS
	mob_type_allowed_typecache = /mob/living/carbon/human //BLUEMOON FIX: звуковой базовый эмоут по умолчанию не разрешает людям -> теперь срабатывает для хуманов

/datum/emote/sound/human/water/run_emote(mob/user, params)
	. = ..()
	if(!.)
		return
	if(!HAS_TRAIT(user, TRAIT_WATER_ASPECT))
		return FALSE
	if(!isturf(user.loc))
		return FALSE

	var/mob/living/living_user = user
	living_user.owned_turf = new /obj/structure/mark_turf(get_turf(living_user), "water")
	living_user.owned_turf.dir = living_user.dir
	RegisterSignal(living_user, COMSIG_MOVABLE_MOVED, PROC_REF(turf_owner), override = TRUE)

/datum/emote/sound/human/water/proc/turf_owner(mob/living/user)
	SIGNAL_HANDLER
	UnregisterSignal(user, COMSIG_MOVABLE_MOVED)
	var/obj/owned_turf = user.owned_turf
	INVOKE_ASYNC(owned_turf, TYPE_PROC_REF(/obj/structure/mark_turf, turf_check), user)