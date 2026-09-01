/datum/atom_hud/data/human/antagtarget
	hud_icons = list(ANTAGTARGET_HUD)

/***********************************************
 Mob's target prefs
************************************************/

/mob/living/carbon/human/proc/set_antag_target_indicator()
	var/image/holder = hud_list?[ANTAGTARGET_HUD]
	if(!holder)
		return

	var/icon/I = icon(icon, icon_state, dir)
	holder.pixel_y = I.Height() - world.icon_size

	if(!client?.prefs)
		holder.icon_state = null
		return

	if(!ishuman(client.mob))
		holder.icon_state = null
		return

	switch(client.prefs.nonconpref)
		if("No")
			holder.icon_state = "hudtarget-no"
		if("Yes")
			holder.icon_state = "hudtarget-yes"
		else
			holder.icon_state = "hudtarget-ask"
