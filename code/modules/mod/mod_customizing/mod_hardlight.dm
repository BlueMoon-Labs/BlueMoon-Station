/obj/item/mod/control/proc/update_hardlight()
	if(!is_active() || !all_parts_deployed())
		return
	wearer.apply_bodypart_overlays(need_to_conseal, update = TRUE, effect_datum = hardlight_effect)

/obj/item/mod/control/proc/remove_hardlight(index, need_update = TRUE)
	if(isnull(index))
		wearer.clear_bodypart_overlays(update = need_update)
		return TRUE
	need_to_conseal -= index
	wearer.remove_overlay_by_bodypart_key(index, need_update)
	return TRUE

//Хардлайт абилка

/datum/action/item_action/mod/hardlight_deploy/chooce_color
	name = "Choice hardlight color"
	button_icon_state = "color"
	var/modsuit_color

/datum/action/item_action/mod/hardlight_deploy/chooce_color/Trigger(trigger_flags)
	var/chosen_colour = input(mod.wearer, "", "Choose Color", modsuit_color) as color|null
	if(!chosen_colour)
		return

	modsuit_color = chosen_colour
	mod.hardlight_effect.apply_color(chosen_colour)
	mod.remove_hardlight(need_update = FALSE)
	mod.update_hardlight()

/datum/action/item_action/mod/hardlight_deploy
	name = "Activate Hardlight field"
	icon_icon = 'modular_bluemoon/icons/mob/actions/mod_radial.dmi'
	button_icon_state = "open"
	button_block_right_click_context_menu = TRUE
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
		"insect_wings" = new /image(icon_icon, "some_wings"),
		"deco_wings" = new /image(icon_icon, "deco_wings"),
		"ipc_antenna" = new /image(icon_icon, "ipc_antenna"),
		"xenodorsal" = new /image(icon_icon, "xenodorsal"),
		"spines" = new /image(icon_icon, "spines"),
	)
	genital_overlay_choices = list(
		"breasts" = new /image(icon_icon, "breasts"),
		"penis" = new /image(icon_icon, "penis"),
		"testicles" = new /image(icon_icon, "testicles"),
		"vagina" = new /image(icon_icon, "vagina"),
		"butt" = new /image(icon_icon, "butt"),
		"belly" = new /image(icon_icon, "belly"),
	)

/datum/action/item_action/mod/hardlight_deploy/proc/get_radial_menu_choices()
	var/list/choices = standart_overlay_choices.Copy()
	if(mod.allowed_genital_overlays)
		for(var/key in genital_overlay_choices)
			choices[key] = genital_overlay_choices[key]
	return choices

/datum/action/item_action/mod/hardlight_deploy/proc/toggle_all()
	var/mode = mod.need_to_conseal.len ? TRUE : FALSE //все добавить/всё удалить
	for(var/element in get_radial_menu_choices())
		if(!mode)
			deploy_hardlight(element, need_update = FALSE)
		else
			conseal_hardlight(element, need_update = FALSE)

	mod.update_hardlight() //за пределами цикла. Всё и разом.

/datum/action/item_action/mod/hardlight_deploy/proc/conseal_hardlight(name, need_update = TRUE)
	if(name in mod.need_to_conseal)
		mod.remove_hardlight(name, TRUE)
		mod.wearer.balloon_alert(mod.wearer, "Защитный слой успешно убран!")
		if(need_update)
			mod.update_hardlight()

/datum/action/item_action/mod/hardlight_deploy/proc/deploy_hardlight(name, need_update = TRUE)
	if(name in mod.need_to_conseal)
		return
	mod.need_to_conseal += name
	if(!mod.is_active())
		mod.wearer.balloon_alert(mod.wearer, "Защитный слой активируется вместе с костюмом!")
		return
	if(need_update)
		mod.update_hardlight()

/datum/action/item_action/mod/hardlight_deploy/Trigger(trigger_flags)
	. = ..()
	if(CHECK_BITFIELD(trigger_flags, TRIGGER_RIGHT_CLICK))
		toggle_all()
		return
	var/choice = show_radial_menu(mod.wearer, mod.wearer, get_radial_menu_choices(),)

	if(choice in mod.need_to_conseal)
		return conseal_hardlight(choice)

	deploy_hardlight(choice)
