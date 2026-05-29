// Спрайты maid/maid_dead + alienspit: из SPLURT Station icons/mob/alien.dmi
// https://github.com/SPLURT-Station/S.P.L.U.R.T-Station-13 — файл скопирован в modular_bluemoon/icons/mob/alien_maid_splurt.dmi
// Остальные стейты — классические alienm_* в icons/mob/alien.dmi (как до TGMC)

/mob/living/carbon/alien/humanoid/drone/maid
	icon = 'modular_bluemoon/icons/mob/alien_maid_splurt.dmi'
	icon_state = "maid"

/mob/living/carbon/alien/humanoid/drone/maid/update_icons()
	cut_overlays()
	for(var/I in overlays_standing)
		add_overlay(I)

	var/asleep = IsSleeping()

	if(stat == DEAD)
		if(fireloss > 125)
			icon = 'icons/mob/alien.dmi'
			icon_state = "alienm_husked"
		else
			icon = 'modular_bluemoon/icons/mob/alien_maid_splurt.dmi'
			icon_state = "maid_dead"
	else if((stat == UNCONSCIOUS && !asleep) || stat == SOFT_CRIT || IsParalyzed())
		icon = 'icons/mob/alien.dmi'
		icon_state = "alienm_unconscious"
	else if(leap_on_click)
		icon = 'icons/mob/alien.dmi'
		icon_state = "alienm_s"
	else if(lying || !CHECK_MOBILITY(src, MOBILITY_STAND) || asleep)
		icon = 'icons/mob/alien.dmi'
		icon_state = "alienm_sleep"
	else if(m_intent == MOVE_INTENT_RUN)
		icon = 'icons/mob/alien.dmi'
		icon_state = "alienm_running"
		if(drooling)
			add_overlay(image(icon = 'modular_bluemoon/icons/mob/alien_maid_splurt.dmi', icon_state = "alienspit"))
	else
		icon = 'modular_bluemoon/icons/mob/alien_maid_splurt.dmi'
		icon_state = "maid"
		if(drooling)
			add_overlay("alienspit")

	if(leaping)
		if(alt_icon == initial(alt_icon))
			var/old_icon = icon
			icon = alt_icon
			alt_icon = old_icon
		icon = 'icons/mob/alienleap.dmi'
		icon_state = "aliend_leap"
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
