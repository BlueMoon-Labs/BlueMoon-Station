/obj/item/mod/control/proc/update_hardlight()
	if(is_active() && all_parts_deployed())
		wearer.apply_bodypart_overlays(need_to_conseal, update = TRUE, effect_datum = hardlight_effect)

/obj/item/mod/control/proc/remove_hardlight(var/index, need_update)
	if(index)
		need_to_conseal -= index
		wearer.remove_overlay_by_bodypart_key(index, need_update)
		return TRUE
	wearer.clear_bodypart_overlays(update = TRUE)

/datum/action/item_action/mod/hardlight_deploy/chooce_color
	name = "Choice hardlight color"
	button_icon_state = "color"
	var/modsuit_color

/datum/action/item_action/mod/hardlight_deploy/chooce_color/Trigger(trigger_flags)
	var/chosen_colour = input(mod.wearer, "", "Choose Color", modsuit_color) as color|null
	if(chosen_colour)
		mod.hardlight_effect.apply_color(chosen_colour)
		mod.remove_hardlight(need_update = FALSE)
		mod.update_hardlight() //обновится тут

/datum/action/item_action/mod/hardlight_deploy
	name = "Activate Hardlight field"
	icon_icon = 'modular_bluemoon/icons/mob/actions/mod_radial.dmi'
	button_icon_state = "open"
	var/list/radial_menu_choises //по-сути кэш изображений, чтобы не генерить их постоянно.
	var/list/standart_overlay_choices = list()
	var/list/genital_overlay_choices = list()

/datum/action/item_action/mod/hardlight_deploy/Grant(mob/user)
	. = ..()
	standart_overlay_choices = list(
			"ears" = new /image(icon_icon, "ears"),
			"snout" = new /image(icon_icon, "snout"),
			"tail" = new /image(icon_icon, "tail"),
			"taur" = new /image(icon_icon, "taur"),
			"horns" = new /image(icon_icon, "horns"),
			"insect_wings" = new /image(icon_icon, "deco_wings"),
			"insect_wings" = new /image(icon_icon, "some_wings"),
			"ipc_antenna" = new /image(icon_icon, "ipc_antenna"),
			"xenodorsal" = new /image(icon_icon, "xenodorsal"),
			"spines" = new /image(icon_icon, "spines"),
		)

	genital_overlay_choices = list(
			"breasts" = new /image(icon_icon, "ears"),
			"penis" = new /image(icon_icon, "ears"),
			"testicles" = new /image(icon_icon, "ears"),
			"vagina"= new /image(icon_icon, "ears"),
			"butt"= new /image(icon_icon, "ears"),
			"belly"= new /image(icon_icon, "ears"),
		)

/datum/action/item_action/mod/hardlight_deploy/Trigger(trigger_flags)
	. = ..()

	if(!radial_menu_choises)
		radial_menu_choises = standart_overlay_choices
		if(mod.allowed_genital_overlays)
			radial_menu_choises += genital_overlay_choices

	if(genital_overlay_choices in radial_menu_choises && !mod.allowed_genital_overlays)
		radial_menu_choises -= genital_overlay_choices

	var/choice = show_radial_menu(mod.wearer, mod.wearer, radial_menu_choises)
	if(!choice)
		return
	if(choice in mod.need_to_conseal)
		mod.remove_hardlight(choice, TRUE)
		mod.wearer.balloon_alert(mod.wearer, "Защитный слой успешно убран!")
	else
		mod.need_to_conseal += choice
		if(!mod.is_active())
			mod.wearer.balloon_alert(mod.wearer, "Защитный слой активируется вместе с костюмом!")
			return
		mod.update_hardlight()
