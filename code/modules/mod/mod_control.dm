/obj/item/mod
	name = "Base MOD"
	desc = "Вы не должны это видеть, кричите на кодера!"
	icon = 'modular_bluemoon/icons/obj/clothing/modsuit/mod_clothing.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/modsuit/mod_clothing.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/clothing/modsuit/mod_clothing_anthro.dmi'
	var/mod_flags
	icon_state = "standard-control"
	item_state = "standard-control"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/mod/control
	name = "MOD control unit"
	desc = "Управляющий блок Модульного Внешнего Устройства — питаемый костюм на спине, защищающий от различных условий окружающей среды."
	icon_state = "control"
	item_state = "control"
	w_class = WEIGHT_CLASS_BULKY
	slot_flags = ITEM_SLOT_BACK
	strip_delay = 10 SECONDS
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 100, FIRE = 25, ACID = 25, WOUND = 10, RAD = 0)
	actions_types = list(
		/datum/action/item_action/mod/deploy,
		/datum/action/item_action/mod/activate,
		/datum/action/item_action/mod/module,
		/datum/action/item_action/mod/panel,
		/datum/action/item_action/mod/deploy/ai,
		/datum/action/item_action/mod/activate/ai,
		/datum/action/item_action/mod/module/ai,
		/datum/action/item_action/mod/panel/ai,
		/datum/action/item_action/mod/hardlight_deploy,
		/datum/action/item_action/mod/hardlight_deploy/chooce_color,
	)
	resistance_flags = NONE
	max_heat_protection_temperature = SPACE_SUIT_MAX_TEMP_PROTECT
	min_cold_protection_temperature = SPACE_SUIT_MIN_TEMP_PROTECT
	permeability_coefficient = 0.01
	siemens_coefficient = 0.5
	alternate_worn_layer = BODY_FRONT_LAYER
	var/status_flags
	var/datum/mod_theme/theme = /datum/mod_theme

	/// Looks of the MOD.		//]
	var/skin = "standard"		//]
	/// Theme of the MOD TGUI	//] <-- перенести в mod_theme
	var/ui_theme = "ntos"		//]

	var/seconds_electrified = MACHINE_NOT_ELECTRIFIED
	var/interface_break = FALSE
	var/complexity_max = DEFAULT_MAX_COMPLEXITY
	var/complexity = 0
	var/cell_drain = DEFAULT_CHARGE_DRAIN
	var/slowdown_inactive = 2
	var/slowdown_active = 1
	var/extended_desc
	var/activation_step_time = MOD_ACTIVATION_STEP_TIME
	var/list/need_to_conseal = list()
	var/datum/overlay_effect/hardlight_effect
	var/alist/mod_parts = alist(
		MOD_PART_HEAD = /obj/item/clothing/mod_part/head,
		MOD_PART_CHEST = /obj/item/clothing/mod_part/suit,
		MOD_PART_GLOVES = /obj/item/clothing/mod_part/gloves,
		MOD_PART_FEET = /obj/item/clothing/mod_part/shoes,
		MOD_PART_CELL = null,
	)

	var/list/initial_modules = list()
	var/list/modules = list()
	var/obj/item/mod/module/selected_module
	var/mob/living/silicon/ai
	var/movedelay = 0
	COOLDOWN_DECLARE(cooldown_mod_move)
	var/mob/living/carbon/human/wearer
	var/can_install_pai = FALSE
	var/current_armor_module_installed = 0
	var/max_armor_module_count = 2
	var/allowed_genital_overlays = FALSE

/obj/item/mod/control/proc/get_mod_part_by_index(index)
	return mod_parts[index]

/obj/item/mod/control/proc/get_helmet()
	return mod_parts[MOD_PART_HEAD]

/obj/item/mod/control/proc/get_chestplate()
	return mod_parts[MOD_PART_CHEST]

/obj/item/mod/control/proc/get_gauntlets()
	return mod_parts[MOD_PART_GLOVES]

/obj/item/mod/control/proc/get_boots()
	return mod_parts[MOD_PART_FEET]

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

/obj/item/mod/control/proc/is_malfunctioning()
	return CHECK_BITFIELD(status_flags, MOD_MALFUNCTION) ? TRUE : FALSE

/obj/item/mod/control/proc/is_active()
	return CHECK_BITFIELD(status_flags, MOD_ACTIVE) ? TRUE : FALSE

/obj/item/mod/control/proc/is_activating()
	return CHECK_BITFIELD(status_flags, MOD_ACTIVATING) ? TRUE : FALSE

/obj/item/mod/control/proc/is_open()
	return CHECK_BITFIELD(status_flags, MOD_OPEN) ? TRUE : FALSE

/obj/item/mod/control/proc/toggle_state(flag)
	TOGGLE_BITFIELD(status_flags, flag)

/obj/item/mod/control/Initialize(mapload, new_theme, new_skin, list/parts)
	. = ..()
	if(new_theme)
		theme = new_theme
	theme = GLOB.mod_themes[theme]
	set_wires(new /datum/wires/mod(src))
	if(ispath(MOD_CELL))
		var/cell_type = mod_parts[MOD_PART_CELL]
		mod_parts[MOD_PART_CELL] = new cell_type
	for(var/index in mod_parts)
		if(!ispath(mod_parts[index]) || index == MOD_PART_CELL)
			continue
		var/part_type = mod_parts[index]
		var/obj/item/clothing/mod_part/part = new part_type
		mod_parts[index] = part
		part.mod = src
	theme.setup_theme(src, new_skin)
	update_flags()
	update_speed()
	for(var/obj/item/mod/module/module as anything in initial_modules)
		module = new module
		install(module)
	RegisterSignal(src, COMSIG_ATOM_EXITED, PROC_REF(on_exit))
	movedelay = CONFIG_GET(number/movedelay/run_delay)

/obj/item/mod/control/Destroy()
	if(is_active())
		STOP_PROCESSING(SSobj, src)
	//unset_wearer звали только из equipped/dropped, а крио уносит надетый МОД
	//forceMove'ом мимо dropped: костюм держал тело и две подписки на нём до конца смены
	if(wearer)
		unset_wearer()
	var/atom/deleting_atom
	for(var/index in mod_parts)
		var/obj/item/clothing/mod_part/part = mod_parts[index]
		if(!QDELETED(part))
			deleting_atom = part
			if(index != MOD_PART_CELL)
				part.mod = null
			mod_parts -= deleting_atom
			qdel(deleting_atom)
	for(var/obj/item/mod/module/module as anything in modules)
		module.mod = null
		modules -= module
		qdel(module)
	QDEL_NULL(ai)
	QDEL_NULL(wires)
	QDEL_NULL(MOD_CELL)
	return ..()

/obj/item/mod/control/examine_more(mob/user)
	. = ..()
	. += extended_desc

/obj/item/mod/control/process(delta_time)
	var/obj/item/stock_parts/cell/cell = get_cell()
	if(seconds_electrified > MACHINE_NOT_ELECTRIFIED)
		seconds_electrified--
	if((!cell || !cell.charge) && is_active())
		power_off()
		return PROCESS_KILL
	if(cell.cell_is_radioactive)
		AddComponent(/datum/component/radioactive, 0, src, 0)
	var/malfunctioning_charge_drain = 0
	if(is_malfunctioning())
		malfunctioning_charge_drain = rand(1,20)
	cell.charge = max(0, cell.charge - (cell_drain + malfunctioning_charge_drain)*delta_time)
	update_cell_alert()
	for(var/obj/item/mod/module/module as anything in modules)
		if(is_malfunctioning() && module.active && DT_PROB(5, delta_time))
			module.on_deactivation()
		module.on_process(delta_time)

/obj/item/mod/control/equipped(mob/user, slot)
	..()
	if(slot == ITEM_SLOT_BACK || slot == ITEM_SLOT_BELT)
		set_wearer(user)
	else if(wearer)
		unset_wearer()

/obj/item/mod/control/dropped(mob/user)
	. = ..()
	if(wearer)
		unset_wearer()

/obj/item/mod/control/item_action_slot_check(slot)
	if(slot == slot_flags)
		return TRUE

/obj/item/mod/control/allow_attack_hand_drop(mob/user)
	var/mob/living/carbon/carbon_user = user
	if(!istype(carbon_user) || src != carbon_user.back)
		return ..()
	for(var/obj/item/part in mod_parts)
		if(part.loc != src)
			balloon_alert(carbon_user, "выдвиньте элементы МОДа!")
			playsound(src, 'sound/machines/scanbuzz.ogg', 25, FALSE, SILENCED_SOUND_EXTRARANGE)
			return FALSE
	return ..()

/obj/item/mod/control/MouseDrop(atom/over_object)
	var/obj/item/target_object = wearer?.get_item_by_slot(src.slot_flags)
	if(src != target_object || !istype(over_object, /atom/movable/screen/inventory/hand))
		return ..()
	if(is_active())
		balloon_alert(wearer, "Отключите МОД!")
		return playsound(src, 'sound/machines/scanbuzz.ogg', 25, FALSE, SILENCED_SOUND_EXTRARANGE)
	for(var/index in mod_parts)
		var/obj/item/clothing/mod_part/part = mod_parts[index]
		if(part.loc != null)
			balloon_alert(wearer, "выдвиньте элементы МОДа!")
			playsound(src, 'sound/machines/scanbuzz.ogg', 25, FALSE, SILENCED_SOUND_EXTRARANGE)
			return
	if(!wearer.incapacitated())
		var/atom/movable/screen/inventory/hand/ui_hand = over_object
		if(wearer.putItemFromInventoryInHandIfPossible(src, ui_hand.held_index))
			add_fingerprint(usr)
			return ..()

/obj/item/mod/control/attack_hand(mob/user)
	var/obj/item/stock_parts/cell/cell = get_cell()
	if(seconds_electrified && cell?.charge)
		if(shock(user))
			return
	if(is_open() && loc == user)
		if(!cell)
			balloon_alert(user, "нет батареи!")
			return
		balloon_alert(user, "изъятие батареи...")
		if(!do_after(user, 1 SECONDS, target = src))
			balloon_alert(user, "прервано!")
			return
		playsound(src, 'sound/machines/click.ogg', 50, TRUE, SILENCED_SOUND_EXTRARANGE)
		if(!user.put_in_hands(cell))
			cell.forceMove(drop_location())
		mod_parts[MOD_PART_CELL] = null
		update_cell_alert()
		return
	return ..()

/obj/item/mod/control/AltClick(mob/user)
	var/obj/item/stock_parts/cell/cell = get_cell()
	if(seconds_electrified && cell?.charge)
		if(shock(user))
			return

	. = ..()

/obj/item/mod/control/screwdriver_act(mob/living/user, obj/item/screwdriver)
	. = ..()
	if(.)
		return TRUE
	if(is_active() || is_activating())
		balloon_alert(user, "сначала отключите костюм!")
		playsound(src, 'sound/machines/scanbuzz.ogg', 25, TRUE, SILENCED_SOUND_EXTRARANGE)
		return FALSE
	balloon_alert(user, "[is_open() ? "закрытие" : "открытие"] панели...")
	if(screwdriver.use_tool(src, user, 0.5 SECONDS))
		if(is_active() || is_activating())
			balloon_alert(user, "сначала отключите костюм!")
			return FALSE
		screwdriver.play_tool_sound(src, 100)
		toggle_state(MOD_OPEN)
	else
		balloon_alert(user, "прервано!")
	return TRUE

/obj/item/mod/control/crowbar_act(mob/living/user, obj/item/crowbar)
	. = ..()
	if(!is_open())
		balloon_alert(user, "сначала откройте панель!")
		playsound(src, 'sound/machines/scanbuzz.ogg', 25, TRUE, SILENCED_SOUND_EXTRARANGE)
		return FALSE
	if(!allowed(user))
		balloon_alert(user, "недостаточный доступ!")
		playsound(src, 'sound/machines/scanbuzz.ogg', 25, TRUE, SILENCED_SOUND_EXTRARANGE)
		return
	if(length(modules))
		var/list/removable_modules = list()
		for(var/obj/item/mod/module/module as anything in modules)
			if(!module.removable)
				continue
			removable_modules += module
		var/obj/item/mod/module/module_to_remove = tgui_input_list(user, "Какой модуль вы хотите снять?", "Снять модули", removable_modules)
		if(!module_to_remove?.mod)
			return FALSE
		uninstall(module_to_remove)
		module_to_remove.forceMove(drop_location())
		crowbar.play_tool_sound(src, 100)
		return TRUE
	balloon_alert(user, "нет модулей!")
	playsound(src, 'sound/machines/scanbuzz.ogg', 25, TRUE, SILENCED_SOUND_EXTRARANGE)
	return FALSE

/obj/item/mod/control/attackby(obj/item/attacking_item, mob/living/user, params)
	var/obj/item/stock_parts/cell/cell = get_cell()
	if(istype(attacking_item, /obj/item/paicard))
		if(!is_open()) //mod must be open
			balloon_alert(user, "панель костюма должна быть открыта!")
			return FALSE
		if(can_install_pai)
			insert_pai(user, attacking_item)
			return TRUE
	if(istype(attacking_item, /obj/item/mod/module))
		if(!is_open())
			balloon_alert(user, "сначала откройте панель!")
			playsound(src, 'sound/machines/scanbuzz.ogg', 25, TRUE, SILENCED_SOUND_EXTRARANGE)
			return FALSE
		install(attacking_item, user)
		return TRUE
	else if(istype(attacking_item, /obj/item/stock_parts/cell))
		if(!is_open())
			balloon_alert(user, "сначала откройте панель!")
			playsound(src, 'sound/machines/scanbuzz.ogg', 25, TRUE, SILENCED_SOUND_EXTRARANGE)
			return FALSE
		if(cell)
			if(!do_after(user, 1 SECONDS, target = src))
				balloon_alert(user, "прервано!")
				return FALSE
			playsound(src, 'sound/machines/click.ogg', 50, TRUE, SILENCED_SOUND_EXTRARANGE)
			cell.forceMove(drop_location())
			user.put_in_hands(cell)
		attacking_item.moveToNullspace()
		mod_parts[MOD_PART_CELL] = attacking_item
		playsound(src, 'sound/machines/click.ogg', 50, TRUE, SILENCED_SOUND_EXTRARANGE)
		update_cell_alert()
		return TRUE
	else if(is_wire_tool(attacking_item) && is_open())
		wires.interact(user)
		return TRUE
	else if(is_open() && attacking_item.GetID())
		update_access(user, attacking_item)
		return TRUE
	return ..()

/obj/item/mod/control/get_cell()
	return mod_parts[MOD_PART_CELL]

/obj/item/mod/control/emp_act(severity)
	. = ..()
	to_chat(wearer, span_notice("Обнаружен [severity > 1 ? "слабый" : "сильный"] электромагнитный импульс!"))
	if(!is_active() || !wearer || . & EMP_PROTECT_CONTENTS)
		return
	selected_module = null
	wearer.apply_damage(severity*0.2, BURN, spread_damage=TRUE)
	to_chat(wearer, span_danger("Вы ощущаете как [src] нагревается из-за ЭМИ и обжигает вас!"))
	if (wearer.stat < UNCONSCIOUS && prob(10))
		wearer.emote("realagony")

/obj/item/mod/control/on_outfit_equip(mob/living/carbon/human/outfit_wearer, visuals_only, item_slot)
	if(visuals_only)
		set_wearer(outfit_wearer) //we need to set wearer manually since it doesnt call equipped
	quick_activation()

/obj/item/mod/control/doStrip(mob/stripper, mob/owner)
	if(wearer.infiltrator_active && wearer.stat == CONSCIOUS)
		balloon_alert(stripper, "Отказано!")
		return
	if(!toggle_activate(stripper, force_deactivate = TRUE))
		return
	for(var/obj/item/part in mod_parts)
		conceal(null, part)
		if(need_to_conseal)
			wearer.clear_bodypart_overlays(update = FALSE)
		remove_hardlight()
	return ..()

/obj/item/mod/control/worn_overlays(isinhands = FALSE, icon_file)
	. = ..()
	if(!is_active())
		return
	for(var/obj/item/mod/module/module as anything in modules)
		var/list/module_icons = module.generate_worn_overlay()
		if(!length(module_icons))
			continue
		. += module_icons

/obj/item/mod/control/proc/set_wearer(mob/user)
	wearer = user
	RegisterSignal(wearer, COMSIG_ATOM_EXITED, PROC_REF(on_exit))
	RegisterSignal(wearer, COMSIG_PROCESS_BORGCHARGER_OCCUPANT, PROC_REF(on_borg_charge))
	//крио уносит надетый костюм forceMove'ом мимо dropped(), а коробка с ним живёт
	//в stored_packages до конца смены - без этой подписки МОД держал тело весь раунд
	RegisterSignal(wearer, COMSIG_PARENT_QDELETING, PROC_REF(on_wearer_deleted), override = TRUE)
	update_cell_alert()
	for(var/obj/item/mod/module/module as anything in modules)
		module.on_equip()

/obj/item/mod/control/proc/on_wearer_deleted(datum/source)
	SIGNAL_HANDLER
	unset_wearer()

/obj/item/mod/control/proc/unset_wearer()
	for(var/obj/item/mod/module/module as anything in modules)
		module.on_unequip()
	UnregisterSignal(wearer, list(COMSIG_ATOM_EXITED, COMSIG_PROCESS_BORGCHARGER_OCCUPANT, COMSIG_PARENT_QDELETING))
	wearer.clear_alert("mod_charge")
	wearer = null

/obj/item/mod/control/proc/update_flags()
	var/list/used_skin = theme.skins[skin]
	for(var/index in mod_parts)
		if(index == MOD_PART_CELL)
			continue
		var/obj/item/clothing/mod_part/part = mod_parts[index]
		part.update_flags(used_skin)

/obj/item/mod/control/proc/quick_module(mob/user)
	if(!length(modules))
		return
	var/list/display_names = list()
	var/list/items = list()
	for(var/obj/item/mod/module/module as anything in modules)
		if(module.module_type == MODULE_PASSIVE || module.module_type == MODULE_ARMOR)
			continue
		display_names[module.name] = REF(module)
		var/image/module_image = image(icon = module.icon, icon_state = module.icon_state)
		items += list(module.name = module_image)
	if(!length(items))
		return
	var/pick = show_radial_menu(user, src, items, custom_check = FALSE, require_near = TRUE)
	if(!pick)
		return
	var/module_reference = display_names[pick]
	var/obj/item/mod/module/selected_module = locate(module_reference) in modules
	if(!istype(selected_module) || user.incapacitated())
		return
	selected_module.on_select()

/obj/item/mod/control/proc/set_mod_color(new_color)
	var/list/all_parts = mod_parts
	for(var/index in all_parts)
		if(index == MOD_PART_CELL)
			continue
		var/obj/item/clothing/mod_part/part = all_parts[index]
		part.remove_atom_colour(WASHABLE_COLOUR_PRIORITY)
		part.add_atom_colour(new_color, FIXED_COLOUR_PRIORITY)
	src.remove_atom_colour(WASHABLE_COLOUR_PRIORITY)
	src.add_atom_colour(new_color, FIXED_COLOUR_PRIORITY)
	wearer?.regenerate_icons()

/obj/item/mod/control/proc/set_mod_skin(new_skin)
	if(is_active())
		CRASH("[src] tried to set skin while active!")
	skin = new_skin
	var/list/used_skin = theme.skins[new_skin]
	if(used_skin[CONTROL_LAYER])
		alternate_worn_layer = used_skin[CONTROL_LAYER]
	var/list/skin_updating = mod_parts.Copy()
	for(var/index in skin_updating)
		if(index == MOD_PART_CELL)
			continue
		var/obj/item/clothing/mod_part/piece = skin_updating[index]
		piece.icon_state = "[skin]-[initial(piece.icon_state)]"
	src.icon_state = "[skin]-[initial(src.icon_state)]"
	update_flags()
	wearer?.regenerate_icons()

/obj/item/mod/control/proc/shock(mob/living/user)
	var/obj/item/stock_parts/cell/cell = get_cell()
	if(!istype(user) || cell?.charge < 1)
		return FALSE
	do_sparks(5, TRUE, src)
	var/check_range = TRUE
	return electrocute_mob(user, cell, src, 0.7, check_range)

/obj/item/mod/control/proc/install(module, mob/user)
	var/obj/item/mod/module/new_module = module
	for(var/obj/item/mod/module/old_module as anything in modules)
		if(is_type_in_list(new_module, old_module.incompatible_modules) || is_type_in_list(old_module, new_module.incompatible_modules))
			if(user)
				balloon_alert(user, "[new_module] несовместим с [old_module]!")
				playsound(src, 'sound/machines/scanbuzz.ogg', 25, TRUE, SILENCED_SOUND_EXTRARANGE)
			return
		if(new_module.module_type == MODULE_ARMOR)
			var/obj/item/mod/module/armor/armor_module = module
			if(!armor_module.armor_type)
				balloon_alert(user, "Модуль не завершен!")
				to_chat(user, span_alertwarning("Для завершения модуля брони вам нужно добавить в него материал. Для просмотра рецепта осмотрите сам модуль дважды"))
				return
			var/armor_by_type_num = 0
			for(var/obj/item/mod/module/armor/also_module in modules)
				if(armor_module.armor_type != also_module.armor_type)
					continue
				armor_by_type_num += 1
			if(armor_by_type_num >= max_armor_module_count)
				balloon_alert(user, "Превышен лимит модулей брони [armor_module.armor_type] типа!")
				playsound(src, 'sound/machines/scanbuzz.ogg', 25, TRUE, SILENCED_SOUND_EXTRARANGE)
				return
	if(is_type_in_list(module, theme.module_blacklist))
		if(user)
			balloon_alert(user, "[src] не принимает [new_module]!")
			playsound(src, 'sound/machines/scanbuzz.ogg', 25, TRUE, SILENCED_SOUND_EXTRARANGE)
		return
	var/complexity_with_module = complexity
	complexity_with_module += new_module.complexity
	if(complexity_with_module > complexity_max)
		if(user)
			balloon_alert(user, "[new_module] превышает вместимость [src]!")
			playsound(src, 'sound/machines/scanbuzz.ogg', 25, TRUE, SILENCED_SOUND_EXTRARANGE)
		return
	new_module.moveToNullspace()
	modules += new_module
	complexity += new_module.complexity
	new_module.mod = src
	new_module.on_install()
	if(wearer)
		new_module.on_equip()
	if(user)
		balloon_alert(user, "[new_module] добавлен")
		playsound(src, 'sound/machines/click.ogg', 50, TRUE, SILENCED_SOUND_EXTRARANGE)

/obj/item/mod/control/proc/uninstall(module)
	var/obj/item/mod/module/old_module = module
	modules -= old_module
	complexity -= old_module.complexity
	if(is_active())
		old_module.on_suit_deactivation()
		if(old_module.active)
			old_module.on_deactivation()
	if(wearer)
		old_module.on_unequip()
	old_module.on_uninstall()
	old_module.mod = null

/obj/item/mod/control/proc/update_access(mob/user, obj/item/card/id/card)
	if(!allowed(user))
		balloon_alert(user, "недостаточный доступ!")
		playsound(src, 'sound/machines/scanbuzz.ogg', 25, TRUE, SILENCED_SOUND_EXTRARANGE)
		return
	req_access = card.access.Copy()
	balloon_alert(user, "access updated")

/obj/item/mod/control/proc/update_cell_alert()
	var/obj/item/stock_parts/cell/cell = get_cell()
	if(!wearer)
		return
	if(!cell)
		wearer.throw_alert("mod_charge", /atom/movable/screen/alert/nocell)
		return
	var/remaining_cell = cell.charge/cell.maxcharge
	switch(remaining_cell)
		if(0.75 to INFINITY)
			wearer.clear_alert("mod_charge")
		if(0.5 to 0.75)
			wearer.throw_alert("mod_charge", /atom/movable/screen/alert/lowcell, 1)
		if(0.25 to 0.5)
			wearer.throw_alert("mod_charge", /atom/movable/screen/alert/lowcell, 2)
		if(0.01 to 0.25)
			wearer.throw_alert("mod_charge", /atom/movable/screen/alert/lowcell, 3)
		else
			wearer.throw_alert("mod_charge", /atom/movable/screen/alert/emptycell)

/obj/item/mod/control/proc/update_speed()
	for(var/index in mod_parts)
		if(index == MOD_PART_CELL)
			continue
		var/obj/item/clothing/mod_part/part = mod_parts[index]
		part.slowdown = (is_active() ? slowdown_active : slowdown_inactive) / length(mod_parts)
	wearer?.update_equipment_speed_mods()

/obj/item/mod/control/proc/power_off()
	balloon_alert(wearer, "обесточено!")
	toggle_activate(wearer, force_deactivate = TRUE)

/obj/item/mod/control/proc/on_exit(datum/source, atom/movable/part, direction)
	SIGNAL_HANDLER
	var/obj/item/stock_parts/cell/cell = get_cell()
	if(part.loc == src)
		return
	if(part == cell)
		cell = null
		update_cell_alert()
		return
	if(part.loc == wearer)
		return
	if(modules.Find(part))
		uninstall(part)
		return
	if(mod_parts.Find(part))
		conceal(wearer, part)
		if(is_active())
			INVOKE_ASYNC(src, PROC_REF(toggle_activate), wearer, TRUE)
		return

/obj/item/mod/control/proc/quick_toggle_parts(mob/user)
	var/on = is_active()
	if(!wearer || is_activating())
		return FALSE
	for(var/index in mod_parts)
		var/obj/item/clothing/mod_part/part = mod_parts[index]
		if(index == MOD_PART_CELL)
			continue

		ENABLE_BITFIELD(status_flags, MOD_ACTIVATING)

		if(part.loc == null)
			if(do_after(wearer, activation_step_time, wearer, MOD_ACTIVATION_STEP_FLAGS, extra_checks = CALLBACK(src, PROC_REF(has_wearer))))
				part.seal_part(seal = on)
				deploy(wearer, part)
		else
			if(do_after(wearer, activation_step_time, wearer, MOD_ACTIVATION_STEP_FLAGS, extra_checks = CALLBACK(src, PROC_REF(has_wearer))))
				part.seal_part(seal = on)
				conceal(wearer, part)

		DISABLE_BITFIELD(status_flags, MOD_ACTIVATING)
	return TRUE

/obj/item/mod/control/proc/on_borg_charge(datum/source, amount)
	SIGNAL_HANDLER
	var/obj/item/stock_parts/cell/cell = get_cell()

	if(!cell)
		return
	cell.give(amount)

/obj/item/mod/control/proc/send_modsuit_message(viewer, title, message)

	var/dat = "<style>"

	dat += ".background-box {background-color: #120101; border: 1px solid #d4cccc; padding: 0; font-family: 'Courier New', monospace; color: #b0b0b0; box-shadow: 0 0 15px rgb(255, 248, 248);}"

	dat += ".message-header {background-color: #120101; color: #f1f1f1; text-align: center; font-weight: bold; padding: 10px 0; margin: 0; text-transform: uppercase; border-bottom: 1px solid #910101; text-shadow: 0 0 8px #910101; letter-spacing: 2px; position: relative;}"

	dat += ".message-header::before { position: absolute; left: 15px; animation: retro-spin 1s linear infinite; color: #0d1735;}"
	dat += ".message-row {padding: 10px 15px; margin: 4px 0; line-height: 1.4; font-size: 12px; transition: all 0.1s; border-left: 2px solid transparent;}"
	dat += ".message-row:hover {background-color: #1b4b5a; color: #ffffff; border-left: 2px solid #15cffd;}"

	dat += ".message-row:nth-child(odd) {background-color: #080808;}"

	dat += "</style>"

	dat += "<div class='background-box'>"
	dat += "<div class='message-header'>[title]</div>"
	dat += "<div class='message-row'>[message]</div>"
	dat += "</div>"

	to_chat(viewer, dat)
