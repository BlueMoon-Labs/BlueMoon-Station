#define MOD_ACTIVATION_STEP_FLAGS IGNORE_USER_LOC_CHANGE|IGNORE_TARGET_LOC_CHANGE|IGNORE_HELD_ITEM|IGNORE_INCAPACITATED

/// Creates a radial menu from which the user chooses parts of the suit to deploy/retract. Repeats until all parts are extended or retracted.
/obj/item/mod/control/proc/choose_deploy(mob/user)
	var/list/display_names = list()
	var/list/items = list()
	for(var/slot in mod_parts)
		if(slot == MOD_PART_CELL)
			continue
		var/obj/item/piece = mod_parts[slot]
		display_names[piece.name] = piece
		var/image/piece_image = image(
			icon = piece.icon,
			icon_state = piece.icon_state
		)
		items[piece.name] = piece_image
	var/pick = show_radial_menu(user, src, items, custom_check = FALSE, require_near = TRUE, tooltips = TRUE)
	if(!pick)
		return
	var/obj/item/part = display_names[pick]

	if(!istype(part) || user.incapacitated())
		return
	var/parts_to_check = mod_parts - part
	if(part.loc != user)
		deploy(user, part)
		for(var/slot in parts_to_check)
			if(slot == MOD_PART_CELL)
				continue
			var/obj/item/piece = mod_parts[slot]
			if(piece.loc == user)
				continue
			choose_deploy(user)
			break
	else
		conceal(user, part)
		for(var/slot in parts_to_check)
			if(slot == MOD_PART_CELL)
				continue
			var/obj/item/piece = mod_parts[slot]
			if(piece.loc != user)
				continue
			choose_deploy(user)
			break

/// Deploys a part of the suit onto the user.
/obj/item/mod/control/proc/deploy(mob/user, part)
	if(is_welded())
		return balloon_alert(user, "Заварено!")
	var/obj/item/clothing/mod_part/piece = part
	var/obj/item/item_in_slot
	if(piece.slot_flags == ITEM_SLOT_OCLOTHING)
		item_in_slot = wearer.s_store
	if(!piece.conseal_to_overslot()) //скрывает одежду внутрь переменной элемента МОДа
		balloon_alert(wearer, "ОШИБКА")
		return to_chat(wearer, span_alertwarning("У вас не получилось развернуть поверх вашей текущей одежды элемент МОДа."))

	if(wearer.equip_to_slot_if_possible(piece, piece.slot_flags, qdel_on_fail = FALSE, disable_warning = TRUE))
		ADD_TRAIT(piece, TRAIT_NODROP, MOD_TRAIT)
		if(!user)
			piece.toggle_all_linked_modules(MODPART_DEPLOYED)
			return TRUE
		wearer.visible_message(span_notice("[wearer]'s [piece] deploy[piece.p_s()] with a mechanical hiss."),
			span_notice("[piece] разворачивается[piece.p_s()] с механическим шипением."),
			span_hear("Вы слышите механическое шипение."))
		playsound(src, 'sound/mecha/mechmove03.ogg', 25, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
		if(item_in_slot)
			wearer.equip_to_slot_if_possible(item_in_slot, ITEM_SLOT_SUITSTORE)
		if(need_to_conseal && is_active() && all_parts_deployed())
			update_hardlight()
		piece.toggle_all_linked_modules(MODPART_DEPLOYED)
		return TRUE
	else if(piece.loc != src)
		if(!user)
			return FALSE
		balloon_alert(user, "[piece] already deployed!")
		playsound(src, 'sound/machines/scanbuzz.ogg', 25, TRUE, SILENCED_SOUND_EXTRARANGE)
	else
		if(!user)
			return FALSE
		balloon_alert(user, "bodypart clothed!")
		playsound(src, 'sound/machines/scanbuzz.ogg', 25, TRUE, SILENCED_SOUND_EXTRARANGE)
	return FALSE

/obj/item/mod/control/proc/conceal(mob/user, part, force = FALSE)
	if(is_welded() && !force)
		return balloon_alert(user, "Заварено!")
	var/obj/item/clothing/mod_part/piece = part
	wearer.transferItemToLoc(piece, null, TRUE)
	piece.equip_item_from_overslot()
	if(!user)
		return
	wearer.visible_message(span_notice("[wearer]'s [piece] retract[piece.p_s()] back into [src] with a mechanical hiss."),
		span_notice("[piece] retract[piece.p_s()] back into [src] with a mechanical hiss."),
		span_hear("You hear a mechanical hiss."))
	remove_hardlight()
	piece.toggle_all_linked_modules(MODPART_CONSEALED)
	playsound(src, 'sound/mecha/mechmove03.ogg', 25, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)

/obj/item/mod/control/proc/toggle_activate(mob/user, force_deactivate = FALSE)
	var/obj/item/stock_parts/cell/cell = get_cell()
	if(!wearer)
		if(!force_deactivate)
			balloon_alert(user, "put suit on back!")
			playsound(src, 'sound/machines/scanbuzz.ogg', 25, TRUE, SILENCED_SOUND_EXTRARANGE)
		return FALSE
	if(!force_deactivate && (SEND_SIGNAL(src, COMSIG_MOD_ACTIVATE, user) & MOD_CANCEL_ACTIVATE))
		playsound(src, 'sound/machines/scanbuzz.ogg', 25, TRUE, SILENCED_SOUND_EXTRARANGE)
		return FALSE
	if(!cell?.charge && !force_deactivate)
		balloon_alert(user, "suit not powered!")
		playsound(src, 'sound/machines/scanbuzz.ogg', 25, TRUE, SILENCED_SOUND_EXTRARANGE)
		return FALSE
	if(is_open() && !force_deactivate)
		balloon_alert(user, "close the suit panel!")
		playsound(src, 'sound/machines/scanbuzz.ogg', 25, TRUE, SILENCED_SOUND_EXTRARANGE)
		return FALSE
	if(is_activating())
		if(!force_deactivate)
			balloon_alert(user, "suit already [is_active() ? "shutting down" : "starting up"]!")
			playsound(src, 'sound/machines/scanbuzz.ogg', 25, TRUE, SILENCED_SOUND_EXTRARANGE)
		return FALSE
	for(var/obj/item/mod/module/module as anything in modules)
		if(!module.active || module.allowed_inactive)
			continue
		module.on_deactivation()
	ENABLE_BITFIELD(status_flags, MOD_ACTIVATING)
	if(is_active())
		remove_hardlight()
	to_chat(wearer, span_notice("MODsuit [is_active() ? "shutting down" : "starting up"]."))
	if(ai)
		to_chat(ai, span_notice("MODsuit [is_active() ? "shutting down" : "starting up"]."))

	if(force_deactivate)
		for(var/index in mod_parts)
			if(index == MOD_PART_CELL)
				continue
			var/obj/item/clothing/mod_part/MOD_PART = get_mod_part_by_index(index)
			MOD_PART.seal_part(seal = FALSE)
			conceal(user, MOD_PART)
		finish_activation(on = FALSE)
		DISABLE_BITFIELD(status_flags, MOD_ACTIVATING)
		send_modsuit_message(wearer, "ОТКЛЮЧЕНИЕ", "Systems shut down. Parts unsealed. Goodbye, [wearer].")
		if(ai)
			send_modsuit_message(ai, "ОТКЛЮЧЕНИЕ", "<b>СИСТЕМЫ ДЕАКТИВИРОВАНЫ. ПРОЩАЙТЕ: \"[ai]\"</b>")
		playsound(src, 'sound/machines/synth_no.ogg', 50, TRUE, SHORT_RANGE_SOUND_EXTRARANGE, frequency = 6000)
		return TRUE
	for(var/index in mod_parts)
		if(index == MOD_PART_CELL)
			continue
		var/obj/item/clothing/mod_part/MOD_PART = get_mod_part_by_index(index)
		if(do_after(wearer, activation_step_time, wearer, MOD_ACTIVATION_STEP_FLAGS, extra_checks = CALLBACK(src, PROC_REF(has_wearer))))
			to_chat(wearer, span_notice("[MOD_PART.name] [is_active() ? pick(MOD_PART.unseal_message) : pick(MOD_PART.seal_message)]."))
			playsound(src, 'sound/mecha/mechmove03.ogg', 25, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
			MOD_PART.seal_part(seal = !is_active())
		else
			return toggle_activate_fail()
	if(do_after(wearer, activation_step_time, wearer, MOD_ACTIVATION_STEP_FLAGS, extra_checks = CALLBACK(src, PROC_REF(has_wearer))))
		send_modsuit_message(wearer, "СИСТЕМНОЕ ОПОВЕЩЕНИЕ", "Systems [is_active() ? "shut down. Parts unsealed. Goodbye" : "started up. Parts sealed. Welcome"], [wearer].")
		if(ai)
			to_chat(ai, span_notice("<b>SYSTEMS [is_active() ? "DEACTIVATED. GOODBYE" : "ACTIVATED. WELCOME"]: \"[ai]\"</b>"))
		finish_activation(on = !is_active())
		if(is_active())
			playsound(src, 'sound/machines/synth_yes.ogg', 50, TRUE, SHORT_RANGE_SOUND_EXTRARANGE, frequency = 6000)
			SEND_SOUND(wearer, sound('sound/mecha/nominal.ogg',volume=50))
		else
			playsound(src, 'sound/machines/synth_no.ogg', 50, TRUE, SHORT_RANGE_SOUND_EXTRARANGE, frequency = 6000)
	else
		return toggle_activate_fail()
	DISABLE_BITFIELD(status_flags, MOD_ACTIVATING)
	return TRUE

/obj/item/mod/control/proc/toggle_activate_fail()
	for(var/index in mod_parts)
		if(index == MOD_PART_CELL)
			continue
		var/obj/item/clothing/mod_part/MOD_PART = get_mod_part_by_index(index)
		MOD_PART.seal_part(TRUE)
	to_chat(wearer, span_warning("[is_active() ? "Shut down" : "Start up"] cancelled."))
	finish_activation(on = is_active())
	DISABLE_BITFIELD(status_flags, MOD_ACTIVATING)
	return FALSE

/obj/item/mod/control/proc/finish_activation(on)
	if(on == TRUE)
		ENABLE_BITFIELD(status_flags, MOD_ACTIVE)
	else
		DISABLE_BITFIELD(status_flags, MOD_ACTIVE)
	if(is_active())
		for(var/obj/item/mod/module/module as anything in modules)
			module.on_suit_activation()
		START_PROCESSING(SSobj, src)
	else
		for(var/obj/item/mod/module/module as anything in modules)
			module.on_suit_deactivation()
		STOP_PROCESSING(SSobj, src)
	if(on == TRUE && all_parts_deployed())
		update_hardlight()
	update_speed()
	update_icon_state()

	wearer.update_inv_back()

/obj/item/mod/control/update_icon_state()
	icon_state = "[skin]-control[is_active() ? "-sealed" : ""]"
	return ..()

/obj/item/mod/control/proc/quick_activation()
	var/seal = TRUE
	for(var/obj/item/part as anything in mod_parts)
		if(!deploy(null, part))
			seal = FALSE
	if(!seal)
		return
	for(var/index in mod_parts)
		var/obj/item/clothing/mod_part/MOD_PART = get_mod_part_by_index(index)
		MOD_PART.seal_part(TRUE)
	finish_activation(on = TRUE)

/obj/item/mod/control/proc/has_wearer()
	return wearer
