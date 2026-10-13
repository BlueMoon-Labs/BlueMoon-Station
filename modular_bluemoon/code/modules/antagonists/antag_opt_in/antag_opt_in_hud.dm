/datum/atom_hud/data/human/antag_opt_in
	hud_icons = list(ANTAG_OPT_IN_HUD)

/mob/living/carbon/human/proc/update_antag_opt_in_hud()
	var/image/holder = hud_list?[ANTAG_OPT_IN_HUD]
	if(!holder)
		return
	holder.icon = 'modular_bluemoon/icons/mob/antag_opt_in_hud.dmi'
	if(icon)
		holder.pixel_y = get_hud_pixel_offset(icon, icon_state, dir)
	holder.icon_state = mind ? "opt_in_[mind.get_effective_antag_opt_in_level()]" : null

/datum/mind/proc/update_antag_opt_in_hud()
	var/mob/living/carbon/human/body = current
	if(istype(body))
		body.update_antag_opt_in_hud()

/datum/mind/transfer_to(mob/new_character, force_key_move = 0)
	var/mob/living/carbon/human/old_body = current
	. = ..()
	if(istype(old_body) && old_body.mind != src)
		old_body.update_antag_opt_in_hud()
	update_antag_opt_in_hud()

/mob/living/carbon/human/Login()
	. = ..()
	update_antag_opt_in_hud()
