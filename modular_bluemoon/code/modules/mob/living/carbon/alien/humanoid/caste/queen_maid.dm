// Xenomorph queen maid — restored from pre-2017 donor feature (Maidify action).

/datum/action/maid
	name = "Maidify"
	desc = "Permanently take on a maidly appearance. This cannot be undone."
	button_icon_state = "alien_queen_maidify"
	check_flags = AB_CHECK_RESTRAINED|AB_CHECK_STUN|AB_CHECK_LYING|AB_CHECK_CONSCIOUS
	background_icon_state = "bg_alien"

/datum/action/maid/Trigger()
	if(!..())
		return FALSE
	var/mob/living/carbon/alien/humanoid/royal/queen/A = owner
	if(!istype(A) || A.caste == "qmaid")
		return FALSE
	A.maidify()
	if(A.maidify_action)
		A.maidify_action.Remove(A)
		QDEL_NULL(A.maidify_action)
	return TRUE

/mob/living/carbon/alien/humanoid/royal/queen/proc/maidify()
	name = "alien queen maid"
	desc = "Lusty, Sexy"
	icon = 'icons/mob/alienqueen.dmi'
	alt_inhands_file = 'icons/mob/alienqueen.dmi'
	caste = "qmaid"
	update_icons()

/mob/living/carbon/alien/humanoid/royal/update_icons()
	if(caste == "qmaid")
		cut_overlays()
		for(var/I in overlays_standing)
			add_overlay(I)

		icon = 'icons/mob/alienqueen.dmi'
		var/asleep = IsSleeping()
		if(stat == DEAD)
			if(fireloss > 125)
				icon_state = "alienqmaid_husked"
			else
				icon_state = "alienqmaid_dead"
		else if((stat == UNCONSCIOUS && !asleep) || stat == SOFT_CRIT || IsParalyzed())
			icon_state = "alienqmaid_unconscious"
		else if(leap_on_click)
			icon_state = "alienqmaid"
		else if(lying || !CHECK_MOBILITY(src, MOBILITY_STAND) || asleep)
			icon_state = "alienqmaid_sleep"
		else if(m_intent == MOVE_INTENT_RUN)
			icon_state = "alienqmaid_running"
		else
			icon_state = "alienqmaid"

		if(leaping)
			if(alt_icon == initial(alt_icon))
				var/old_icon = icon
				icon = alt_icon
				alt_icon = old_icon
			icon_state = "alien[caste]_leap"
			pixel_x = -32
			pixel_y = -32
		else
			if(alt_icon != initial(alt_icon))
				var/old_icon = icon
				icon = alt_icon
				alt_icon = old_icon
			pixel_x = get_standard_pixel_x_offset(lying)
			pixel_y = get_standard_pixel_y_offset(lying)

		update_inv_hands()
		update_inv_handcuffed()
		return

	return ..()
