/obj/effect/proc_holder/spell/pointed
	name = "pointed spell"
	ranged_mousepointer = 'icons/effects/mouse_pointers/throw_target.dmi'
	action_icon_state = "projectile"
	/// Message showing to the spell owner upon deactivating pointed spell.
	var/deactive_msg = "You dispel the magic..."
	/// Message showing to the spell owner upon activating pointed spell.
	var/active_msg = "You prepare to use the spell on a target..."
	/// Variable dictating if the user is allowed to cast a spell on himself.
	var/self_castable = FALSE
	/// Variable dictating if the spell will use turf based aim assist
	var/aim_assist = TRUE
	/// A rejected click falls back to the nearest valid living target within this many tiles of the clicked turf
	var/aim_assist_radius = 0
	/// A rejected click on a movable falls back to the turf under it
	var/aim_assist_turf = FALSE

/obj/effect/proc_holder/spell/pointed/Trigger(mob/user, skip_can_cast = TRUE)
	if(!istype(user))
		return
	var/msg
	if(!can_cast(user))
		msg = "<span class='warning'>You can no longer cast [name]!</span>"
		remove_ranged_ability(msg)
		return
	if(active)
		msg = "<span class='notice'>[deactive_msg]</span>"
		remove_ranged_ability(msg)
	else
		msg = "<span class='notice'>[active_msg] <B>Left-click to activate spell on a target!</B></span>"
		add_ranged_ability(user, msg, TRUE)
		on_activation(user)

/obj/effect/proc_holder/spell/pointed/on_lose(mob/living/user)
	remove_ranged_ability()

/obj/effect/proc_holder/spell/pointed/remove_ranged_ability(msg)
	. = ..()
	on_deactivation(ranged_ability_user)

/obj/effect/proc_holder/spell/pointed/add_ranged_ability(mob/living/user, msg, forced)
	. = ..()
	on_activation(user)

/**
  * on_activation: What happens upon pointed spell activation.
  *
  * Arguments:
  * * user The mob interacting owning the spell.
  */
/obj/effect/proc_holder/spell/pointed/proc/on_activation(mob/user)
	return

/**
  * on_activation: What happens upon pointed spell deactivation.
  *
  * Arguments:
  * * user The mob interacting owning the spell.
  */
/obj/effect/proc_holder/spell/pointed/proc/on_deactivation(mob/user)
	return

/obj/effect/proc_holder/spell/pointed/update_icon()
	. = ..()
	if(!action)
		return
	if(active)
		action.button_icon_state = "[action_icon_state]1"
	else
		action.button_icon_state = "[action_icon_state]"
	action.UpdateButtons()

/obj/effect/proc_holder/spell/pointed/InterceptClickOn(mob/living/caller, params, atom/target)
	if(..())
		return TRUE
	if(aim_assist && isturf(target))
		var/list/possible_targets = list()
		for(var/A in target)
			if(intercept_check(caller, A, TRUE))
				possible_targets += A
		if(possible_targets.len == 1)
			target = possible_targets[1]
	target = assisted_target(caller, target)
	if(!intercept_check(caller, target))
		return TRUE
	if(!cast_check(FALSE, caller))
		return TRUE
	perform(list(target), user = caller)
	remove_ranged_ability()
	return TRUE // Do not do any underlying actions after the spell cast

/**
  * assisted_target: Forgiving target resolution for a click that missed.
  *
  * Returns the clicked atom when it is valid, otherwise the turf under it (if aim_assist_turf)
  * or the nearest valid living mob around the clicked turf (if aim_assist_radius), falling back to the clicked atom.
  */
/obj/effect/proc_holder/spell/pointed/proc/assisted_target(mob/user, atom/target)
	if((!aim_assist_radius && !aim_assist_turf) || intercept_check(user, target, TRUE))
		return target
	var/turf/clicked_turf = get_turf(target)
	if(!clicked_turf)
		return target
	if(aim_assist_turf && clicked_turf != target && intercept_check(user, clicked_turf, TRUE))
		return clicked_turf
	var/mob/living/best_target
	var/best_distance
	for(var/mob/living/candidate in range(aim_assist_radius, clicked_turf))
		var/distance = get_dist(candidate, clicked_turf)
		if(best_target && distance >= best_distance)
			continue
		if(!intercept_check(user, candidate, TRUE))
			continue
		best_target = candidate
		best_distance = distance
	return best_target || target

/**
  * intercept_check: Specific spell checks for InterceptClickOn() targets.
  *
  * Arguments:
  * * user The mob using the ranged spell via intercept.
  * * target The atom that is being targeted by the spell via intercept.
  * * silent If the checks should produce not any feedback messages for the user.
  */
/obj/effect/proc_holder/spell/pointed/proc/intercept_check(mob/user, atom/target, silent = FALSE)
	if(!self_castable && target == user)
		if(!silent)
			to_chat(user, "<span class='warning'>You cannot cast the spell on yourself!</span>")
		return FALSE
	if(!(target in view_or_range(range, user, selection_type)))
		if(!silent)
			to_chat(user, "<span class='warning'>[target.ru_who(TRUE)] too far away!</span>")
		return FALSE
	if(!can_target(target, user, silent))
		return FALSE
	return TRUE
