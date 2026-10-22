//DO NOT ADD MECHA PARTS TO THE GAME WITH THE DEFAULT "SPRITE ME" SPRITE!
//I'm annoyed I even have to tell you this! SPRITE FIRST, then commit.

/obj/item/mecha_parts/mecha_equipment
	name = "mecha equipment"
	icon = 'icons/mecha/mecha_equipment.dmi'
	icon_state = "mecha_equip"
	force = 5
	max_integrity = 300
	var/equip_cooldown = 0
	var/equip_ready = TRUE //whether the equipment is ready for use. (or deactivated/activated for static stuff)
	var/energy_drain = 0
	var/obj/vehicle/sealed/mecha/chassis = null
	///Bitflag. Determines the range of the equipment.
	var/range = MECHA_MELEE
	/// Bitflag. Used by exosuit fabricator to assign sub-categories based on which exosuits can equip this.
	var/mech_flags = NONE
	var/salvageable = 1
	var/detachable = TRUE // Set to FALSE for built-in equipment that cannot be removed
	var/selectable = 1	// Set to 0 for passive equipment such as mining scanner or armor plates
	var/harmful = FALSE //Controls if equipment can be used to attack by a pacifist.
	var/destroy_sound = 'sound/mecha/critdestr.ogg'
	var/mecha_subcategory_flags // BLUEMOON ADD
	// Действие для модулей, которые включаются без выбора цели.
	var/ui_toggle_action
	var/list/pilot_actions = list()
	var/ui_icon
	// Допустимые категории шасси; NONE разрешает установку на любой мех.
	var/compatible_mecha_types = NONE

/obj/item/mecha_parts/mecha_equipment/proc/update_chassis_page()
	if(chassis)
		SStgui.update_uis(chassis)
		return TRUE
	return

/obj/item/mecha_parts/mecha_equipment/proc/update_equip_info()
	if(chassis)
		chassis.update_equipment_buttons()
		SStgui.update_uis(chassis)
		return TRUE
	return

/obj/item/mecha_parts/mecha_equipment/Destroy()
	QDEL_LIST_ASSOC_VAL(pilot_actions)
	if(chassis)
		LAZYREMOVE(chassis.equipment, src)
		if(chassis.selected == src)
			chassis.selected = null
		if(chassis.selected_right == src)
			chassis.selected_right = null
		update_chassis_page()
		log_message("[src] уничтожен.", LOG_MECHA)
		if(!LAZYLEN(chassis?.occupants))
			to_chat(chassis.occupants, "[icon2html(src, chassis.occupants)][span_danger("[src] уничтожен!")]")
			playsound(chassis, destroy_sound, 50)
		if(!detachable) //If we're a built-in nondetachable equipment, let's lock up the slot that we were in.
			chassis.max_equip--
		chassis = null
	return ..()

/obj/item/mecha_parts/mecha_equipment/try_attach_part(mob/user, obj/vehicle/sealed/mecha/M)
	if(can_attach(M))
		if(!user.temporarilyRemoveItemFromInventory(src))
			return FALSE
		attach(M)
		user.visible_message(span_notice("[user] устанавливает [src] на [M]."), span_notice("Вы устанавливаете [src] на [M]."))
		return TRUE
	to_chat(user, span_warning("Не удаётся установить [src] на [M]!"))
	return FALSE

/obj/item/mecha_parts/mecha_equipment/proc/action_checks(atom/target)
	if(!target)
		return FALSE
	if(!chassis)
		return FALSE
	if(!equip_ready)
		return FALSE
	if(energy_drain && !chassis.has_charge(energy_drain))
		return FALSE
	if(chassis.is_currently_ejecting)
		return FALSE
	if(chassis.equipment_disabled)
		to_chat(chassis.occupants, span_warning("Ошибка: блок управления оборудованием не отвечает."))
		return FALSE
	if(TIMER_COOLDOWN_CHECK(chassis, COOLDOWN_MECHA_EQUIPMENT))
		return FALSE
	return TRUE

/obj/item/mecha_parts/mecha_equipment/proc/action(mob/source, atom/target, params)
	TIMER_COOLDOWN_START(chassis, COOLDOWN_MECHA_EQUIPMENT, equip_cooldown)//Cooldown is on the MECH so people dont bypass it by switching equipment
	SStgui.update_uis(chassis)
	chassis.use_power(energy_drain)
	return TRUE

/obj/item/mecha_parts/mecha_equipment/proc/do_after_cooldown(atom/target, mob/user)
	if(!chassis)
		return FALSE
	chassis.use_power(energy_drain)
	return do_after(user, equip_cooldown, target, extra_checks = CALLBACK(src, PROC_REF(do_after_checks), target))

/obj/item/mecha_parts/mecha_equipment/proc/do_after_mecha(atom/target, mob/user, delay)
	return do_after(user, delay, target, extra_checks = CALLBACK(src, PROC_REF(do_after_checks), target))

/// do after checks for the mecha equipment do afters
/obj/item/mecha_parts/mecha_equipment/proc/do_after_checks(atom/target)
	return chassis && (get_dir(chassis, target) & chassis.dir)

/obj/item/mecha_parts/mecha_equipment/proc/can_attach(obj/vehicle/sealed/mecha/M)
	if(!istype(M))
		return FALSE
	// Комплект заменяет шасси, не занимая слот: емаг не отменяет требования к переоборудованию.
	if(istype(src, /obj/item/mecha_parts/mecha_equipment/ripleyupgrade))
		if(M.type != /obj/vehicle/sealed/mecha/working/ripley)
			to_chat(loc, span_warning("Этот комплект переоборудования подходит только для моделей APLU MK-I."))
			return FALSE
		var/obj/vehicle/sealed/mecha/working/ripley/ripley = M
		if(length(ripley.cargo))
			to_chat(loc, span_warning("Перед переоборудованием необходимо освободить грузовой отсек [M]."))
			return FALSE
		if(!(M.mecha_flags & ADDING_MAINT_ACCESS_POSSIBLE))
			to_chat(loc, span_warning("Для переоборудования [M] необходимо разрешить техобслуживание."))
			return FALSE
		if(LAZYLEN(M.occupants))
			to_chat(loc, span_warning("Перед переоборудованием все пассажиры должны покинуть [M]."))
			return FALSE
		if(!M.cell)
			to_chat(loc, span_warning("Для переоборудования необходима установленная батарея."))
			return FALSE
		return TRUE
	if(LAZYLEN(M.equipment) >= M.max_equip)
		return FALSE
	if(M.is_emagged() || !compatible_mecha_types || (compatible_mecha_types & M.mecha_type))
		return TRUE
	// Скрытый отсек разрешает одно обычное оружие, сохраняя ограничения специальных моделей.
	if((compatible_mecha_types & MECHA_TYPE_COMBAT) && istype(src, /obj/item/mecha_parts/mecha_equipment/weapon))
		return (locate(/obj/item/mecha_parts/concealed_weapon_bay) in M.contents) && !(locate(/obj/item/mecha_parts/mecha_equipment/weapon) in M.equipment)
	return FALSE

/obj/item/mecha_parts/mecha_equipment/proc/attach(obj/vehicle/sealed/mecha/M)
	LAZYADD(M.equipment, src)
	chassis = M
	forceMove(M)
	for(var/mob/pilot as anything in M.occupants)
		grant_pilot_action(pilot)
	log_message("[src] подключён.", LOG_MECHA)
	update_chassis_page()
	return

/obj/item/mecha_parts/mecha_equipment/proc/detach(atom/moveto=null)
	moveto = moveto || get_turf(chassis)
	if(src.Move(moveto))
		QDEL_LIST_ASSOC_VAL(pilot_actions)
		LAZYREMOVE(chassis.equipment, src)
		if(chassis.selected == src)
			chassis.selected = null
		if(chassis.selected_right == src)
			chassis.selected_right = null
		update_chassis_page()
		log_message("[src] снят с меха.", LOG_MECHA)
		chassis = null
	return


/obj/item/mecha_parts/mecha_equipment/log_message(message, message_type=LOG_GAME, color=null, log_globally, atom/target = null)
	if(chassis)
		chassis.log_message("МОДУЛЬ: [src] [message]", message_type, color, log_globally, target = target)
	else
		..(message, message_type, color, log_globally, target)


//Used for reloading weapons/tools etc. that use some form of resource
/obj/item/mecha_parts/mecha_equipment/proc/rearm()
	return FALSE


/obj/item/mecha_parts/mecha_equipment/proc/needs_rearm()
	return FALSE

/obj/item/mecha_parts/mecha_equipment/proc/get_ui_data()
	if(!ui_icon)
		// Браузеру нужен один PNG-кадр, иначе он показывает всю сетку кадров DMI.
		ui_icon = icon2base64(icon(icon, icon_state, SOUTH, 1, FALSE))
	var/unavailable_reason
	if(chassis.equipment_disabled)
		unavailable_reason = "Блок управления оборудованием отключён."
	else if(selectable && !equip_ready)
		unavailable_reason = "Модуль занят."
	else if(selectable && chassis.construction_state != MECHA_LOCKED)
		unavailable_reason = "Активирован протокол техобслуживания."
	else if(energy_drain && !chassis.has_charge(energy_drain))
		unavailable_reason = "Недостаточно энергии."
	return list(
		"name" = name,
		"desc" = desc,
		"image" = ui_icon,
		"ref" = REF(src),
		"integrity" = obj_integrity / max_integrity,
		"detachable" = detachable,
		"can_be_triggered" = selectable,
		"can_be_toggled" = !!ui_toggle_action,
		"active" = is_ui_active(),
		"toggle_action" = ui_toggle_action,
		"selected_left" = chassis.selected == src,
		"selected_right" = chassis.selected_right == src,
		"equip_cooldown" = equip_cooldown && DisplayTimeText(equip_cooldown),
		"energy_per_use" = energy_drain,
		"unavailable_reason" = unavailable_reason,
		"detach_reason" = null,
		"snowflake" = null,
	)

/obj/item/mecha_parts/mecha_equipment/proc/handle_ui_act(action, list/params)
	if(action == "detach")
		if(!detachable)
			return FALSE
		detach()
		return TRUE
	return FALSE

/obj/item/mecha_parts/mecha_equipment/proc/is_ui_active()
	return ui_toggle_action && (datum_flags & DF_ISPROCESSING)

/obj/item/mecha_parts/mecha_equipment/proc/grant_pilot_action(mob/pilot)
	if((!selectable && !ui_toggle_action) || !(chassis.occupants[pilot] & VEHICLE_CONTROL_EQUIPMENT) || pilot_actions[pilot])
		return
	var/datum/action/vehicle/sealed/mecha/module/action = new(src)
	action.chassis = chassis
	action.equipment = src
	action.name = "[ui_toggle_action ? "Включить/выключить" : "Выбрать"] [name]"
	action.icon_icon = icon
	action.button_icon_state = icon_state
	pilot_actions[pilot] = action
	action.Grant(pilot)

/obj/item/mecha_parts/mecha_equipment/proc/remove_pilot_action(mob/pilot)
	var/datum/action/action = pilot_actions[pilot]
	pilot_actions -= pilot
	qdel(action)

/obj/vehicle/sealed/mecha/proc/update_equipment_buttons()
	for(var/obj/item/mecha_parts/mecha_equipment/module as anything in equipment)
		for(var/pilot in module.pilot_actions)
			var/datum/action/action = module.pilot_actions[pilot]
			action.UpdateButtons()
