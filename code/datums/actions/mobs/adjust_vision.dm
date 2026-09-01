
/datum/action/adjust_vision
	name = "Adjust Vision"
	desc = "See better in the dark. Or don't. Your advanced vision allows either."
	icon_icon = 'icons/mob/actions/actions_animal.dmi'
	button_icon_state = "adjust_vision"
	background_icon_state = "bg_default"

/datum/action/adjust_vision/Grant(mob/living/grant_to)
	. = ..()
	grant_to.see_in_dark = NIGHTVISION_FOV_RANGE
	grant_to.lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_VISIBLE
	grant_to.lighting_cutoff = LIGHTING_CUTOFF_MEDIUM
	grant_to.update_sight()

/datum/action/adjust_vision/Remove(mob/living/remove_from)
	. = ..()
	remove_from.see_in_dark = initial(remove_from.see_in_dark)
	remove_from.lighting_alpha = initial(remove_from.lighting_alpha)
	remove_from.lighting_cutoff = initial(remove_from.lighting_cutoff)
	remove_from.lighting_color_cutoffs = initial(remove_from.lighting_color_cutoffs)
	remove_from.update_sight()

/datum/action/adjust_vision/Trigger(trigger_flags)
	. = ..()
	if(!.)
		return

	var/mob/living/living_owner = owner
	living_owner.sight = initial(living_owner.sight)
	switch(living_owner.lighting_alpha)
		if (LIGHTING_PLANE_ALPHA_VISIBLE)
			living_owner.lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_VISIBLE
			living_owner.lighting_cutoff = LIGHTING_CUTOFF_MEDIUM
			living_owner.lighting_color_cutoffs = list(15, 15, 15)
		if (LIGHTING_PLANE_ALPHA_MOSTLY_VISIBLE)
			living_owner.lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE
			living_owner.lighting_cutoff = LIGHTING_CUTOFF_HIGH
			living_owner.lighting_color_cutoffs = list(25, 25, 25)
		if (LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE)
			living_owner.lighting_alpha = LIGHTING_PLANE_ALPHA_INVISIBLE
			living_owner.lighting_cutoff = LIGHTING_CUTOFF_FULLBRIGHT
			living_owner.lighting_color_cutoffs = list(40, 40, 40)
		else
			living_owner.lighting_alpha = LIGHTING_PLANE_ALPHA_VISIBLE
			living_owner.lighting_cutoff = LIGHTING_CUTOFF_VISIBLE
			living_owner.lighting_color_cutoffs = null
			living_owner.sight &= ~SEE_BLACKNESS
	living_owner.update_sight()
