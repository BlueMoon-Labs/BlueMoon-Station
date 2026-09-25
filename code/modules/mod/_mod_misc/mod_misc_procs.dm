/obj/item/mod/control/proc/get_helmet()
	return mod_parts[MOD_PART_HEAD]

/obj/item/mod/control/proc/get_chestplate()
	return mod_parts[MOD_PART_CHEST]

/obj/item/mod/control/proc/get_gauntlets()
	return mod_parts[MOD_PART_GLOVES]

/obj/item/mod/control/proc/get_boots()
	return mod_parts[MOD_PART_FEET]

/obj/item/mod/control/get_cell()
	return mod_parts[MOD_PART_CELL]

/obj/item/mod/control/proc/is_malfunctioning()
	return CHECK_BITFIELD(status_flags, MOD_MALFUNCTION) ? TRUE : FALSE

/obj/item/mod/control/proc/is_active()
	return CHECK_BITFIELD(status_flags, MOD_ACTIVE) ? TRUE : FALSE

/obj/item/mod/control/proc/is_activating()
	return CHECK_BITFIELD(status_flags, MOD_ACTIVATING) ? TRUE : FALSE

/obj/item/mod/control/proc/is_open()
	return CHECK_BITFIELD(status_flags, MOD_OPEN) ? TRUE : FALSE

/obj/item/mod/control/proc/is_welded()
	return CHECK_BITFIELD(status_flags, MOD_WELDED) ? TRUE : FALSE

/obj/item/mod/control/proc/is_dna_locked()
	return CHECK_BITFIELD(status_flags, MOD_DNA_LOCKED) ? TRUE : FALSE

/obj/item/mod/control/proc/toggle_state(flag)
	TOGGLE_BITFIELD(status_flags, flag)

/obj/item/mod/control/proc/check_welded_or_locked()
	if(!is_welded())
		return TRUE
	balloon_alert(wearer, "Заварено!")

/obj/item/mod/control/proc/can_activate()
	if(theme?.can_activate_without_deploy_all_parts)
		return TRUE
	return all_parts_deployed() //результат прока.

/obj/item/mod/control/proc/get_mod_part_by_index(index)
	return mod_parts[index]

/obj/item/mod/control/proc/is_mod_part(obj/item/part)
	if(isnull(part))
		return FALSE
	for(var/index in mod_parts)
		if(mod_parts[index] == part)
			return TRUE
	return FALSE

/obj/item/mod/control/proc/clear_mod_part(obj/item/part)
	if(isnull(part))
		return FALSE
	var/found_index
	for(var/index in mod_parts)
		if(mod_parts[index] == part)
			found_index = index
			break
	if(isnull(found_index))
		return FALSE
	mod_parts -= found_index
	return TRUE

/obj/item/mod/control/proc/get_mod_parts(include_cell = TRUE, include_mod = FALSE)
	var/list/parts = list()
	for(var/index in mod_parts)
		if(!include_cell && index == MOD_PART_CELL)
			continue
		if(!include_mod && index == MOD_PART_SELF)
			continue
		var/obj/item/part = mod_parts[index]
		if(isnull(part))
			continue
		parts += part
	return parts

//Проверяет, надет ли этот элемент одежды, а так же включён ли МОД
/obj/item/mod/control/proc/check_module_ready_by_mod_index(mod_index)
	var/obj/item/clothing/mod_part/part = get_mod_part_by_index(mod_index)
	return part?.check_module_ready()

/obj/item/mod/control/proc/all_parts_deployed()
	if(!wearer)
		return FALSE
	for(var/obj/item/clothing/mod_part/part in get_mod_parts(include_cell = FALSE))
		if(part.loc != wearer)
			return FALSE
	return TRUE

/obj/item/mod/control/proc/one_of_parts_deployed()
	if(!wearer)
		return FALSE
	for(var/obj/item/clothing/mod_part/part in get_mod_parts(include_cell = FALSE))
		if(part.loc == wearer)
			return TRUE
	return FALSE

/obj/item/mod/control/proc/check_can_conseal_to_overslot(obj/item/clothing/mod_part/piece)
	if(piece.conseal_to_overslot()) //скрывает одежду внутрь переменной элемента МОДа
		return TRUE
	balloon_alert(wearer, "ОШИБКА")
	return to_chat(wearer, span_alertwarning("У вас не получилось развернуть поверх вашей текущей одежды элемент МОДа."))

/obj/item/mod/control/proc/equip_suit_store_item_if_it_possible(obj/item/clothing/mod_part/piece, obj/item/target_item)
	if(piece.slot_flags == ITEM_SLOT_OCLOTHING && target_item)
		wearer.equip_to_slot_if_possible(target_item, ITEM_SLOT_SUITSTORE)

/obj/item/mod/control/proc/has_wearer()
	return wearer

/obj/item/mod/control/proc/check_compatible_theme_with_armor(mob/user)
	if(theme.compatible_with_armor_modules)
		return TRUE
	if(user)
		balloon_alert(user, "Несовместимо!")

/obj/item/mod/module/armor/proc/check_unfinished_armor_state(mob/user)
	if(armor_module_type)
		return TRUE
	if(user)
		balloon_alert(user, "Модуль не завершен!")
		to_chat(user, span_alertwarning("Для завершения модуля брони вам нужно добавить в него материал. Для просмотра рецепта осмотрите сам модуль дважды"))

/obj/item/mod/control/proc/check_max_count_armor(armor_by_type_num, obj/item/mod/module/armor/armor_module, user)
	if(armor_by_type_num >= max_armor_module_count)
		if(user)
			balloon_alert(user, "Превышен лимит модулей брони [armor_module.armor_module_type] типа!")
			playsound(src, 'sound/machines/scanbuzz.ogg', 25, TRUE, SILENCED_SOUND_EXTRARANGE)
		return FALSE
	return TRUE

/obj/item/mod/module/proc/is_armor_module()
	if(module_type == MODULE_ARMOR)
		return TRUE

/obj/item/mod/control/proc/check_modules_in_restricted_list(obj/item/mod/module/old_module, obj/item/mod/module/new_module, obj/item/mod/module/module, user)
	if(is_type_in_list(new_module, old_module.incompatible_modules) || is_type_in_list(old_module, new_module.incompatible_modules) || is_type_in_list(module, theme.module_blacklist))
		if(user)
			balloon_alert(user, "[new_module] несовместим с [old_module]!")
			playsound(src, 'sound/machines/scanbuzz.ogg', 25, TRUE, SILENCED_SOUND_EXTRARANGE)
		return FALSE
	return TRUE

/obj/item/mod/control/proc/handle_pre_install(obj/item/mod/module/new_module)
	new_module.moveToNullspace()
	modules += new_module
	complexity += new_module.complexity
	new_module.mod = src

/obj/item/mod/control/proc/check_new_complexity(obj/item/mod/module/new_module, user)
	var/complexity_with_module = complexity
	complexity_with_module += new_module.complexity
	if(complexity_with_module > complexity_max)
		if(user)
			balloon_alert(user, "[new_module] превышает вместимость [src]!")
			playsound(src, 'sound/machines/scanbuzz.ogg', 25, TRUE, SILENCED_SOUND_EXTRARANGE)
			return FALSE
	return TRUE

/obj/item/mod/control/proc/handle_attack_cell(obj/item/stock_parts/cell/new_cell, obj/item/stock_parts/cell/cell, mob/user)
	if(cell)
		if(!do_after(user, 1 SECONDS, target = src))
			balloon_alert(user, "прервано!")
			return FALSE
		playsound(src, 'sound/machines/click.ogg', 50, TRUE, SILENCED_SOUND_EXTRARANGE)
		cell.forceMove(drop_location())
		user.put_in_hands(cell)
	new_cell.moveToNullspace()
	mod_parts[MOD_PART_CELL] = new_cell
	playsound(src, 'sound/machines/click.ogg', 50, TRUE, SILENCED_SOUND_EXTRARANGE)
	update_cell_alert()
	return TRUE

/obj/item/mod/control/proc/handle_module_inserting(obj/item/mod/module, mob/user)
	install(module, user)
	return TRUE

/obj/item/mod/control/proc/handle_slimepotion_effect(obj/item/slimepotion/potion, mob/user)
	for(var/obj/item/piece as anything in get_mod_parts(include_cell = FALSE))
		potion.afterattack(piece, user)
	return TRUE

/obj/item/mod/control/proc/handle_paicard_insertion(obj/item/paicard, mob/user)
	if(can_install_pai)
		insert_pai(user, paicard)
		return TRUE

/obj/item/mod/control/proc/handle_change_access(obj/item/attacking_item, mob/user)
	update_access(user, attacking_item)
	return TRUE

/mob/living/carbon/human/proc/is_wearing_mod()
	for(var/slot in GLOB.possible_modsuit_slot)
		if(istype(get_item_by_slot(slot), /obj/item/mod/control))
			return get_item_by_slot(slot)

/obj/item/mod/control/proc/do_charge_by_inducer(obj/item/inducer/charger, mob/user)
	charger.recharge(src, user)

/mob/living/carbon/human/attackby(obj/item/I, mob/user, params)
	. = ..()
	var/obj/item/mod/control/target_mod = is_wearing_mod()
	if(istype(I, /obj/item/inducer) && target_mod)
		target_mod.do_charge_by_inducer(I, user)
