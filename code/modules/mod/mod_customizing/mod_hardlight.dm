/obj/item/mod/control/proc/update_hardlight()
	if(!wearer || !hardlight_effect)
		return
	if(is_active() && theme.locked_hardlight)
		need_to_conseal |= GLOB.body_hardlight_layers
		need_to_conseal |= GLOB.mutant_overlay_layers
	var/list/visible_layers = list()
	if(is_active())
		for(var/key in need_to_conseal)
			var/obj/item/clothing/mod_part/part = get_hardlight_part(key)
			if(part?.check_module_ready())
				visible_layers += key
	var/list/changed_layers = wearer.layers_for_apply_effect.Copy() | visible_layers
	wearer.clear_bodypart_overlays(update = FALSE)
	wearer.apply_bodypart_overlays(visible_layers, update = FALSE, effect_datum = hardlight_effect)
	wearer.update_overlayed_parts(changed_layers)

/obj/item/mod/control/proc/get_hardlight_part(key)
	if((key in GLOB.body_hardlight_layers) && !theme.body_hardlight)
		return
	switch(key)
		if("ears", "snout", "horns", "ipc_antenna", "hair", BODY_ZONE_HEAD)
			return get_helmet()
		if("tail", "taur", "insect_wings", "deco_wings", "insect_fluff", "xenodorsal", "spines", "breasts", "penis", "testicles", "vagina", "butt", "belly", BODY_ZONE_CHEST)
			return get_chestplate()
		if(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM)
			return get_gauntlets()
		if(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
			return get_boots()

/obj/item/mod/control/proc/remove_hardlight(index, need_update = TRUE)
	if(!wearer)
		return FALSE
	if(!isnull(index) && is_active() && theme.locked_hardlight)
		return FALSE
	if(isnull(index))
		wearer.clear_bodypart_overlays(update = need_update)
		return TRUE
	need_to_conseal -= index
	wearer.remove_overlay_by_bodypart_key(index, need_update)
	return TRUE

//Хардлайт абилка

/datum/action/item_action/mod/hardlight_deploy/chooce_color
	parent_type = /datum/action/item_action/mod
	name = "Choice hardlight color"
	icon_icon = 'modular_bluemoon/icons/mob/actions/mod_radial.dmi'
	button_icon_state = "color"
	var/datum/mod_hardlight_editor/editor

/datum/action/item_action/mod/hardlight_deploy/chooce_color/Trigger(trigger_flags)
	if(!..() || !mod?.wearer)
		return FALSE
	if(!editor)
		editor = new(mod)
	editor.ui_interact(owner)
	return TRUE

/datum/action/item_action/mod/hardlight_deploy/chooce_color/Destroy()
	QDEL_NULL(editor)
	return ..()

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
	if(ishuman(user))
		var/mob/living/carbon/human/human = user
		var/image/hair_preview = image(null)
		hair_preview.overlays = human.overlays_standing[HAIR_LAYER]
		standart_overlay_choices["hair"] = hair_preview
		if(mod.theme.body_hardlight)
			for(var/obj/item/bodypart/part as anything in human.bodyparts)
				var/image/preview = image(null)
				preview.overlays = part.get_limb_icon()
				standart_overlay_choices[part.body_zone] = preview
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
	if(mod.is_active() && mod.theme.locked_hardlight)
		return FALSE
	var/mode = mod.need_to_conseal.len ? TRUE : FALSE //все добавить/всё удалить
	for(var/element in get_radial_menu_choices())
		if(!mode)
			deploy_hardlight(element, need_update = FALSE)
		else
			conseal_hardlight(element, need_update = FALSE)

	mod.update_hardlight() //за пределами цикла. Всё и разом.

/datum/action/item_action/mod/hardlight_deploy/proc/conseal_hardlight(name, need_update = TRUE)
	if(mod.is_active() && mod.theme.locked_hardlight)
		return FALSE
	if(name in mod.need_to_conseal)
		mod.remove_hardlight(name, TRUE)
		mod.wearer.balloon_alert(mod.wearer, "Защитный слой успешно убран!")
		if(need_update)
			mod.update_hardlight()

/datum/action/item_action/mod/hardlight_deploy/proc/deploy_hardlight(name, need_update = TRUE)
	if(name in mod.need_to_conseal)
		return
	mod.need_to_conseal += name
	if(need_update)
		mod.update_hardlight()

/datum/action/item_action/mod/hardlight_deploy/Trigger(trigger_flags)
	if(!..() || !mod?.wearer)
		return FALSE
	if(mod.is_active() && mod.theme.locked_hardlight)
		mod.balloon_alert(owner, "голограммы закреплены костюмом")
		return FALSE
	if(CHECK_BITFIELD(trigger_flags, TRIGGER_RIGHT_CLICK))
		toggle_all()
		return
	var/choice = show_radial_menu(mod.wearer, mod.wearer, get_radial_menu_choices(),)

	if(!choice || QDELETED(mod) || mod.wearer != owner)
		return FALSE
	if(choice in mod.need_to_conseal)
		return conseal_hardlight(choice)

	deploy_hardlight(choice)

/datum/action/item_action/mod/hardlight_deploy/Destroy()
	standart_overlay_choices = null
	genital_overlay_choices = null
	return ..()
