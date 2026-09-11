/obj/item/clothing/mod_part
	name = "Часть МОД костюма"
	desc = "Это базовый класс любого носимого на теле МОД костюма. \
			Раньше они не имели наследования и друг от друга, а брали родителя от типа \
			своего слота, т.е шлемов, ботинок и т.д. Вы не представляете, как же много макаронного кода \
			это порождало."
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	var/obj/item/mod/control/mod
	var/obj/item/clothing/overslot
	var/list/seal_message = list(
		"затягивается и герметизируется на вас",
		)
	var/list/unseal_message = list(
		"расслабляется и открывается",
		)
	var/list/overslot_blacklist = list(
		/obj/item/clothing/suit/space,
		/obj/item/clothing/head/helmet/space,
		/obj/item/clothing/mod_part,
		//Сюда вписываем то, поверх чего должно быть невозможно развернуть элемент МОДа!
	)
	var/list/linked_modules = list()
	var/theme_category

/obj/item/clothing/mod_part/proc/restore_normal_features()
	return mod.wearer.get_item_by_slot(slot_flags)

/obj/item/clothing/mod_part/proc/notify_user(conceal, user)
	if(!user)
		return
	if(conceal)
		visible_message(span_notice("[user] [src] задвигается назад в [src] с механическим шипением."),
			span_notice("[src] задвигается обратно в [src] с механическим шипением."),
			span_hear("Вы слышите механическое шипение."))
	else
		visible_message(span_notice("[user] [src] разворачивает с механическим шипением."),
			span_notice("[src] разворачивается с механическим шипением."),
			span_hear("Вы слышите механическое шипение."))

	playsound(src, 'sound/mecha/mechmove03.ogg', 25, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)

/obj/item/clothing/mod_part/equipped(mob/user, slot)
	. = ..()
	if(!mod?.wearer)
		return
	ADD_TRAIT(src, TRAIT_NODROP, MOD_TRAIT)
	toggle_all_linked_modules(MODPART_DEPLOYED)
	if(mod.need_to_conseal && mod.is_active() && mod.all_parts_deployed())
		mod.update_hardlight()
	// override: повторный equipped на том же носителе (смена слота, повторное
	// развёртывание) иначе ловит stack_trace "already registered".
	use_clothing_features_through_overslot()
	RegisterSignal(mod.wearer, COMSIG_MOB_UNEQUIPPED_ITEM, PROC_REF(on_dropped), override = TRUE)

/obj/item/clothing/mod_part/proc/on_dropped(mob/source, obj/item, force, new_location)
	SIGNAL_HANDLER
	if(!istype(item, /obj/item/clothing/mod_part))
		return
	if(!mod?.wearer)
		return
	UnregisterSignal(mod.wearer, COMSIG_MOB_UNEQUIPPED_ITEM)
	if(new_location == null)//чтобы не путать со штатным свертыванием
		return
	INVOKE_ASYNC(mod, TYPE_PROC_REF(/obj/item/mod/control, conceal), null, item, TRUE)
	INVOKE_ASYNC(mod, TYPE_PROC_REF(/obj/item/mod/control, remove_hardlight))

/obj/item/clothing/mod_part/proc/link_modpart_with_module(module)
	if(istype(module, /obj/item/mod/module) && (module in linked_modules))
		return FALSE
	linked_modules += module
	return TRUE

/obj/item/clothing/mod_part/proc/toggle_all_linked_modules(state)
	if(!linked_modules)
		return FALSE

	if(state == MODPART_CONSEALED)
		for(var/obj/item/mod/module/module in linked_modules)
			module.saved_state = module.active
			if(module.module_type == MODULE_PASSIVE)
				module.on_suit_deactivation()
				continue
			if(module.active)
				module.on_deactivation()
		return TRUE
	else
		for(var/obj/item/mod/module/module in linked_modules)
			if(module.module_type == MODULE_PASSIVE)
				module.on_suit_activation()
				continue

			if(!module.saved_state)
				continue

			module.on_activation()

/obj/item/clothing/mod_part/proc/check_module_ready()
	if(!mod?.wearer)
		return FALSE
	return mod.is_active() && mod.wearer.get_item_by_slot(src.slot_flags) == src

/obj/item/clothing/mod_part/proc/update_flags(list/used_skin)
	var/list/category = used_skin[theme_category]
	clothing_flags = category[UNSEALED_CLOTHING] || NONE
	visor_flags = category[SEALED_CLOTHING] || NONE
	flags_inv = category[UNSEALED_INVISIBILITY] || NONE
	visor_flags_inv = category[SEALED_INVISIBILITY] || NONE
	flags_cover = category[UNSEALED_COVER] || NONE
	visor_flags_cover = category[SEALED_COVER] || NONE

/obj/item/clothing/mod_part/proc/conseal_to_overslot()
	if(!mod?.wearer)
		return FALSE
	var/obj/item/clothing/item = mod.wearer.get_item_by_slot(slot_flags)
	if(!item)
		return TRUE
	overslot = item

	for(var/type in overslot_blacklist)
		if(istype(item, type))
			return FALSE
	return mod.wearer.transferItemToLoc(overslot, item, force = TRUE)

/obj/item/clothing/mod_part/proc/use_clothing_features_through_overslot()
	return

/obj/item/clothing/mod_part/proc/seal_part(seal)
	if(seal)
		clothing_flags |= visor_flags
		flags_inv |= visor_flags_inv
		flags_cover |= visor_flags_cover
		heat_protection = initial(heat_protection)
		cold_protection = initial(cold_protection)
	else
		flags_cover &= ~visor_flags_cover
		flags_inv &= ~visor_flags_inv
		clothing_flags &= ~visor_flags
		heat_protection = NONE
		cold_protection = NONE
	if(!mod)
		return
	icon_state = "[mod.skin]-[initial(icon_state)][seal ? "-sealed" : ""]"
	item_state = "[mod.skin]-[initial(item_state)][seal ? "-sealed" : ""]"

/obj/item/clothing/mod_part/proc/equip_item_from_overslot()
	REMOVE_TRAIT(src, TRAIT_NODROP, MOD_TRAIT)
	if(!overslot)
		return
	if(!mod?.wearer)
		return
	if(!mod.wearer.equip_to_slot_if_possible(overslot, overslot.slot_flags, qdel_on_fail = FALSE, disable_warning = TRUE))//Экипировать элемент одежды с оверслота обратно
		mod.wearer.dropItemToGround(overslot, force = TRUE)//если условие выше не удалось, то дропать на землю
	overslot = null

/obj/item/clothing/mod_part/Destroy()
	// linked_modules и overslot держали ссылки до конца раунда: part -> module ->
	// module.mod -> control -> mod_parts -> part это замкнутый цикл рефкаунтов,
	// а его BYOND не собирает никогда.
	linked_modules = null
	overslot = null
	if(!QDELETED(mod))
		// mod_parts это alist: вычитание идёт по КЛЮЧУ, поэтому `mod_parts -= src`
		// не удаляло ничего и костюм продолжал держать удалённую часть.
		mod.clear_mod_part(src)
		QDEL_NULL(mod)
	mod = null
	return ..()
