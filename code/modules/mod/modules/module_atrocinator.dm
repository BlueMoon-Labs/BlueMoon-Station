/obj/item/mod/module/atrocinator
	name = "MOD atrocinator module"
	desc = "Странный шар меняет направление гравитации для владельца МОДа."
	icon = 'icons/obj/clothing/modsuit/mod_modules_whitemoon.dmi'
	icon_state = "atrocinator"
	module_type = MODULE_TOGGLE
	complexity = 2
	active_power_cost = DEFAULT_CHARGE_DRAIN
	cooldown_time = 10 SECONDS
	incompatible_modules = list(/obj/item/mod/module/atrocinator, /obj/item/mod/module/magboot, /obj/item/mod/module/anomaly_locked/antigrav)
	overlay_icon_file = 'icons/mob/clothing/modsuit/mod_modules_whitemoon.dmi'
	overlay_state_inactive = "module_atrocinator"
	var/mob/living/carbon/human/inverted_user
	var/step_count = 0
	var/flying_away = FALSE

/obj/item/mod/module/atrocinator/on_activation()
	if(!mod?.wearer || !..())
		return FALSE
	inverted_user = mod.wearer
	if(inverted_user.buckled)
		inverted_user.buckled.unbuckle_mob(inverted_user, TRUE)
	inverted_user.unbuckle_all_mobs(TRUE)
	inverted_user.AddElement(/datum/element/forced_gravity, NEGATIVE_GRAVITY)
	ADD_TRAIT(inverted_user, TRAIT_SILENT_STEP, REF(src))
	ADD_TRAIT(inverted_user, TRAIT_MOD_INVERTED, REF(src))
	passtable_on(inverted_user, REF(src))
	RegisterSignal(inverted_user, COMSIG_MOVABLE_MOVED, PROC_REF(check_upstairs))
	RegisterSignal(inverted_user, COMSIG_MOB_SAY, PROC_REF(on_talk))
	RegisterSignal(inverted_user, COMSIG_PARENT_QDELETING, PROC_REF(on_user_deleted))
	playsound(src, 'sound/effects/curse/curseattack.ogg', MOD_ATROCINATOR_VOLUME)
	check_upstairs()
	return TRUE

/obj/item/mod/module/atrocinator/on_deactivation()
	var/was_active = active
	if(flying_away && inverted_user)
		to_chat(inverted_user, span_danger("Уже слишком поздно."))
	clear_effects()
	if(was_active)
		COOLDOWN_START(src, cooldown_current_timer, cooldown_time)
	if(mod?.wearer)
		return ..()
	active = FALSE
	return TRUE

/obj/item/mod/module/atrocinator/on_unequip()
	if(active)
		on_deactivation()
	else
		clear_effects()

/obj/item/mod/module/atrocinator/on_uninstall(deleting = FALSE, user)
	clear_effects()
	return ..()

/obj/item/mod/module/atrocinator/Destroy()
	clear_effects()
	return ..()

/obj/item/mod/module/atrocinator/proc/clear_effects()
	if(!inverted_user)
		return
	var/mob/living/carbon/human/user = inverted_user
	inverted_user = null
	UnregisterSignal(user, list(COMSIG_MOVABLE_MOVED, COMSIG_MOB_SAY, COMSIG_PARENT_QDELETING))
	user.RemoveElement(/datum/element/forced_gravity, NEGATIVE_GRAVITY)
	REMOVE_TRAIT(user, TRAIT_SILENT_STEP, REF(src))
	REMOVE_TRAIT(user, TRAIT_MOD_INVERTED, REF(src))
	passtable_off(user, REF(src))
	step_count = 0
	if(!flying_away && istype(get_turf(user), /turf/open/openspace))
		var/turf/open/openspace/space = get_turf(user)
		space.zFall(user, falling_from_move = TRUE)

/obj/item/mod/module/atrocinator/proc/check_upstairs(atom/movable/source, atom/oldloc, direction, forced)
	SIGNAL_HANDLER
	if(!inverted_user || flying_away || inverted_user.has_gravity() != NEGATIVE_GRAVITY)
		return
	var/turf/open/current = get_turf(inverted_user)
	if(!current)
		return
	var/turf/above = get_step_multiz(inverted_user, UP)
	if(istype(above, /turf/open/openspace))
		current.zFall(inverted_user)
		return
	if(!above && current.planetary_atmos)
		INVOKE_ASYNC(src, PROC_REF(fly_away))
		return
	if(forced || HAS_TRAIT_NOT_FROM(inverted_user, TRAIT_SILENT_STEP, REF(src)))
		return
	if(SSlag_switch.measures[DISABLE_FOOTSTEPS] && !HAS_TRAIT(inverted_user, TRAIT_BYPASS_MEASURES))
		return
	step_count++
	if(!(step_count % MOD_ATROCINATOR_STEP_INTERVAL))
		playsound(current, 'sound/items/modsuit/atrocinator_step.ogg', MOD_ATROCINATOR_VOLUME)

/obj/item/mod/module/atrocinator/proc/fly_away()
	if(flying_away || !inverted_user)
		return
	flying_away = TRUE
	var/mob/living/carbon/human/user = inverted_user
	playsound(user, 'sound/effects/whirthunk.ogg', MOD_ATROCINATOR_FLY_VOLUME)
	to_chat(user, span_userdanger("Вы взлетаете в небо!"))
	user.investigate_log("вылетел за пределы карты из-за [src].", INVESTIGATE_DEATHS)
	user.Stun(MOD_ATROCINATOR_FLY_TIME, ignore_canstun = TRUE)
	animate(user, MOD_ATROCINATOR_FLY_TIME, pixel_z = MOD_ATROCINATOR_FLY_HEIGHT, alpha = 0)
	QDEL_IN(user, MOD_ATROCINATOR_FLY_TIME)

/obj/item/mod/module/atrocinator/proc/on_talk(datum/source, list/speech_args)
	SIGNAL_HANDLER
	speech_args[SPEECH_SPANS] |= "upside_down"

/obj/item/mod/module/atrocinator/proc/on_user_deleted()
	SIGNAL_HANDLER
	clear_effects()
