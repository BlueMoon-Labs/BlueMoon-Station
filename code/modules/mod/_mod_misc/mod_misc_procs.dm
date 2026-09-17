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

/obj/item/mod/control/proc/can_activate()
	if(theme?.can_activate_without_deploy_all_parts)
		return TRUE
	return all_parts_deployed() //результат прока.

//Проверяет, надет ли этот элемент одежды, а так же включён ли МОД
/obj/item/mod/control/proc/check_module_ready_by_mod_index(mod_index)
	var/obj/item/clothing/mod_part/part = get_mod_part_by_index(mod_index)
	return part?.check_module_ready()

/obj/item/mod/control/proc/all_parts_deployed()
	if(!wearer)
		return FALSE

	for(var/index in mod_parts)
		if(index == MOD_PART_CELL)
			continue
		var/obj/item/clothing/mod_part/part = mod_parts[index]
		if(part.loc != wearer)
			return FALSE

	return TRUE

/obj/item/mod/control/proc/one_of_parts_deployed()
	if(!wearer)
		return FALSE

	for(var/index in mod_parts)
		if(index == MOD_PART_CELL)
			continue
		var/obj/item/clothing/mod_part/part = mod_parts[index]
		if(part.loc == wearer)
			return TRUE

	return FALSE

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
