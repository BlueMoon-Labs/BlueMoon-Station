/obj/item/mod/module
	name = "MOD module"
	icon = 'icons/obj/clothing/modsuit/mod_modules.dmi'
	icon_state = "module"
	/// If it can be removed
	var/removable = TRUE
	/// If it's passive, togglable, usable or active
	var/module_type = MODULE_PASSIVE
	/// Is the module active
	var/active = FALSE
	/// How much space it takes up in the MOD
	var/complexity = 0
	/// Power use when idle
	var/idle_power_cost = DEFAULT_CHARGE_DRAIN * 0
	/// Power use when active
	var/active_power_cost = DEFAULT_CHARGE_DRAIN * 0
	/// Power use when used, we call it manually
	var/use_power_cost = DEFAULT_CHARGE_DRAIN * 0
	/// ID used by their TGUI
	var/tgui_id
	/// Linked MODsuit
	var/obj/item/mod/control/mod
	/// If we're an active module, what item are we?
	var/obj/item/device
	/// Overlay given to the user when the module is inactive
	var/overlay_state_inactive
	/// Overlay given to the user when the module is active
	var/overlay_state_active
	/// Overlay given to the user when the module is used, lasts until cooldown finishes
	var/overlay_state_use
	/// Icon file for the overlay.
	var/overlay_icon_file = 'icons/mob/clothing/modsuit/mod_modules.dmi'
	/// Does the overlay use the control unit's colors?
	var/use_mod_colors = FALSE
	/// What modules are we incompatible with?
	var/list/incompatible_modules = list()
	/// Cooldown after use
	var/cooldown_time = 0
	/// The mouse button needed to use this module
	var/used_signal
	/// If we're allowed to use this module while phased out.
	var/allowed_in_phaseout = FALSE
	/// If we're allowed to use this module while the suit is disabled.
	var/allowed_inactive = FALSE
	var/allowed_incapacitated = FALSE
	var/hands_free_use = FALSE
	/// Timer for the cooldown
	COOLDOWN_DECLARE(cooldown_current_timer)
	/// BLUEMOON ADD Bitflag for exosuit fabricator sub-categories
	var/mod_module_flags
	/// Нужно для выдвижных модулей
	var/my_retract_sound = 'sound/mecha/mechmove03.ogg'
	///Быстрая ссылка на компонент втягиваемости
	var/datum/component/mod_retractable/my_retract_component
	var/obj/item/clothing/mod_part/required_modpart
	var/required_modpart_index
	var/startup_with_suit = FALSE
	var/saved_state
	var/need_full_deploy = FALSE
	var/minimum_cell_charge
	var/have_shortcut_activation = FALSE
	var/obj/item/internal_device

/obj/item/mod/module/Initialize(mapload)
	. = ..()
	if(module_type != MODULE_ACTIVE)
		return
	if(ispath(device))
		device = new device(src)

/obj/item/mod/module/Destroy()
	mod?.uninstall(src, deleting = TRUE)
	QDEL_NULL(my_retract_component)
	QDEL_NULL(internal_device)
	if(device)
		UnregisterSignal(device, COMSIG_PARENT_PREQDELETED)
		QDEL_NULL(device)
	return ..()

/obj/item/mod/module/examine(mob/user)
	. = ..()
	if(user.client && user.hud_list[DIAG_HUD] && user.client.images & user.hud_list[DIAG_HUD])
		. += span_notice("Использовано места: [complexity]")
	. += span_notice("Видно <a href='?src=[REF(src)];mod_specification=1'>шильдик</a> технической спецификации")

/obj/item/mod/module/Topic(href, list/href_list)
	. = ..()
	if(href_list["mod_specification"] && usr)
		to_chat(usr, examine_block(get_specification()))

/obj/item/mod/module/proc/get_specification()
	var/list/parameters = list(
		"Вместимость (complexity)" = complexity,
		"Расход в ожидании, ед. заряда/с" = idle_power_cost,
		"Расход при работе, ед. заряда/с" = active_power_cost,
		"Расход за применение, ед. заряда" = use_power_cost,
		"Перезарядка, с" = cooldown_time / (1 SECONDS),
	)
	var/list/readout = list(span_notice("<b>Техническая спецификация: [html_encode(name)]</b>"), "<table>")
	for(var/parameter in parameters)
		readout += "<tr><td>[parameter]</td><td>[parameters[parameter]]</td></tr>"
	readout += "</table>"
	return readout.Join()

/obj/item/mod/module/proc/check_required_modpart()
	if(!mod || !mod?.wearer)
		return FALSE
	if(!required_modpart)
		return TRUE
	return required_modpart.check_module_ready()

/obj/item/mod/module/proc/handle_emp_act(source, severity)
	SIGNAL_HANDLER
	return

/// Called from MODsuit's install() proc, so when the module is installed.
/obj/item/mod/module/proc/on_install()
	if(module_type == MODULE_ACTIVE)
		if(!my_retract_component && device)
			my_retract_component = AddComponent(/datum/component/mod_retractable, device = device, modsuit = mod, retract_sound = my_retract_sound, stored_in = internal_device)

	if(required_modpart_index)
		required_modpart = mod.get_mod_part_by_index(required_modpart_index)
		required_modpart?.link_modpart_with_module(src)
		return

/// Called from MODsuit's uninstall() proc, so when the module is uninstalled.
/obj/item/mod/module/proc/on_uninstall(deleting = FALSE, user)
	if(my_retract_component)
		my_retract_component?.snap_back()
		QDEL_NULL(my_retract_component)
	required_modpart?.linked_modules?.Remove(src)
	required_modpart = null
	return

/// Called when the MODsuit is activated
/obj/item/mod/module/proc/on_suit_activation()
	return startup_with_suit ? on_activation() : FALSE

/// Called when the MODsuit is deactivated
/obj/item/mod/module/proc/on_suit_deactivation()
	return

/// Called when the MODsuit is equipped
/obj/item/mod/module/proc/on_equip()
	return

/// Called when the MODsuit is unequipped
/obj/item/mod/module/proc/on_unequip()
	return

//Сюда нужно прописывать новые варианты, если появятся МОДы, которые вешаются в другой слот.
/obj/item/mod/module/proc/update_modsuit_slot()
	switch(mod.slot_flags)
		if(ITEM_SLOT_BACK)
			mod.wearer.update_inv_back()
		if(ITEM_SLOT_BELT)
			mod.wearer.update_inv_belt()

/obj/item/mod/module/proc/check_minimum_cell_charge()
	if(!minimum_cell_charge)
		return TRUE
	if(!mod?.core?.charge_source())
		return FALSE
	if(mod.get_charge_percent() <= minimum_cell_charge)
		return FALSE
	return TRUE

/// Called when the module is selected from the TGUI
/obj/item/mod/module/proc/on_select()
	if(SEND_SIGNAL(src, COMSIG_MODULE_TRIGGERED, mod?.wearer) & MOD_ABORT_USE)
		return FALSE
	if(!mod?.wearer) //the control's TGUI is reachable on an unworn suit; every module action below needs a wearer
		return
	if(!COOLDOWN_FINISHED(src, cooldown_current_timer))
		mod.balloon_alert(mod.wearer, "на перезарядке!")
		return FALSE
	if(!check_minimum_cell_charge() && active)
		on_deactivation()
		return mod.balloon_alert(mod.wearer, "Низкий заряд батареи!")
	if(((!mod.is_active() || mod.is_activating()) && !allowed_inactive))
		mod.balloon_alert(mod.wearer, "Сначала активируйте костюм!")
		return
	if(!check_required_modpart())
		mod.balloon_alert(mod.wearer, "Выдвиньте [required_modpart.name]")
		return
	var/activated = FALSE
	if(module_type != MODULE_USABLE)
		if(active)
			on_deactivation()
		else
			on_activation()
			activated = active
	else
		activated = on_use()
	if(activated && module_type != MODULE_PASSIVE && module_type != MODULE_ARMOR)
		to_chat(mod.wearer, span_notice("Модуль \"[name]\" активирован"))
	SEND_SIGNAL(mod, COMSIG_MOD_MODULE_SELECTED, src)

/// Called when the module is activated
/obj/item/mod/module/proc/on_activation()
	if(SEND_SIGNAL(src, COMSIG_MODULE_TRIGGERED, mod?.wearer) & MOD_ABORT_USE)
		return FALSE
	if(need_full_deploy && !mod.all_parts_deployed())
		mod.balloon_alert(mod.wearer, "Разверните полностью!")
		return FALSE
	if((!mod.is_active() && !allowed_inactive) || !mod.get_charge() || !mod.check_charge(active_power_cost))
		mod.balloon_alert(mod.wearer, "обесточен!")
		return FALSE
	if(!allowed_in_phaseout && istype(mod.wearer.loc, /obj/effect/dummy/phased_mob))
		//specifically a to_chat because the user is phased out.
		to_chat(mod.wearer, span_warning("Вы не можете активировать это сейчас!"))
		return FALSE
	if(!check_required_modpart())
		mod.balloon_alert(mod.wearer, "Выдвиньте [required_modpart.name]")
		return
	if(module_type == MODULE_ACTIVE)
		if(mod.selected_module && !mod.selected_module.on_deactivation())
			return
		mod.selected_module = src
		if(my_retract_component)
			SEND_SIGNAL(my_retract_component, COMSIG_MODULE_ON_USE, src, mod.wearer)
		if(!device && have_shortcut_activation)
			update_signal()
			mod.balloon_alert(mod.wearer, "[src] активирован. Нажмите Alt+click по цели, чтобы использовать")
	active = TRUE
	COOLDOWN_START(src, cooldown_current_timer, cooldown_time)
	mod.wearer.update_inv_back()
	return TRUE

/// Called when the module is deactivated
/obj/item/mod/module/proc/on_deactivation()
	active = FALSE
	if(module_type == MODULE_ACTIVE)
		if(mod.selected_module == src)
			mod.selected_module = null
		mod.balloon_alert(mod.wearer, "[src] деактивирован")

		if(device)
			my_retract_component?.snap_back()
		else
			UnregisterSignal(mod.wearer, used_signal)
			used_signal = null
	mod.wearer.update_inv_back()
	return TRUE

/// Called when the module is used
/obj/item/mod/module/proc/on_use()
	if(SEND_SIGNAL(src, COMSIG_MODULE_TRIGGERED, mod?.wearer) & MOD_ABORT_USE)
		return FALSE
	if(!mod.wearer)
		return
	if(!COOLDOWN_FINISHED(src, cooldown_current_timer))
		return FALSE
	if(!check_power(use_power_cost))
		return FALSE
	if(!allowed_in_phaseout && istype(mod.wearer.loc, /obj/effect/dummy/phased_mob))
		//specifically a to_chat because the user is phased out.
		to_chat(mod.wearer, span_warning("Вы не можете активировать это сейчас!"))
		return FALSE
	COOLDOWN_START(src, cooldown_current_timer, cooldown_time)
	addtimer(CALLBACK(mod.wearer, TYPE_PROC_REF(/mob, update_inv_back)), cooldown_time)
	mod.wearer.update_inv_back()
	return TRUE

/// Called when an activated module without a device is used
/obj/item/mod/module/proc/on_select_use(atom/target)
	if(SEND_SIGNAL(src, COMSIG_MODULE_TRIGGERED, mod?.wearer) & MOD_ABORT_USE)
		return FALSE
	if(!active || QDELETED(target) || !mod?.wearer || mod.selected_module != src)
		return FALSE
	if(mod.wearer.incapacitated(ignore_grab = TRUE))
		return FALSE
	if(mod.is_activating() || !mod.is_active() || !check_required_modpart())
		return FALSE
	mod.wearer.face_atom(target)
	return on_use()

/// Called when an activated module without a device is active and the user alt/middle-clicks
/obj/item/mod/module/proc/on_special_click(mob/source, atom/target)
	SIGNAL_HANDLER
	if(source != mod?.wearer || !active)
		return
	INVOKE_ASYNC(src, PROC_REF(use_on_target), source, target)
	return COMSIG_MOB_CANCEL_CLICKON

/obj/item/mod/module/proc/use_on_target(mob/user, atom/target)
	if(user != mod?.wearer)
		return FALSE
	return on_select_use(target)

/// Called on the MODsuit's process
/obj/item/mod/module/proc/on_process(delta_time)
	if(active)
		if(!drain_power(active_power_cost * delta_time))
			on_deactivation()
			return FALSE
		if(!check_minimum_cell_charge() && active)
			on_deactivation()
			return mod.balloon_alert(mod.wearer, "Низкий заряд батареи!")
		on_active_process(delta_time)
	else
		drain_power(idle_power_cost * delta_time)
	return TRUE

/// Called on the MODsuit's process if it is an active module
/obj/item/mod/module/proc/on_active_process(delta_time)
	return

/// Drains power from the suit cell
/obj/item/mod/module/proc/drain_power(amount)
	if(!check_power(amount))
		return FALSE
	return mod.subtract_charge(amount)

/obj/item/mod/module/proc/check_power(amount)
	return mod?.check_charge(amount)

/// Adds additional things to the MODsuit ui_data()
/obj/item/mod/module/proc/add_ui_data()
	return list()

/// Creates a list of configuring options for this module
/obj/item/mod/module/proc/get_configuration()
	return list()

/// Generates an element of the get_configuration list with a display name, type and value
/obj/item/mod/module/proc/add_ui_configuration(display_name, type, value, list/values)
	return list("display_name" = display_name, "type" = type, "value" = value, "values" = values)

/// Receives configure edits from the TGUI and edits the vars
/obj/item/mod/module/proc/configure_edit(key, value)
	return

/// Called when the device gets deleted on active modules
/obj/item/mod/module/proc/on_device_deletion(datum/source)
	SIGNAL_HANDLER

	if(source == device)
		device = null
		qdel(src)

/// Generates an icon to be used for the suit's worn overlays
/obj/item/mod/module/proc/generate_worn_overlay()
	. = list()
	if(!mod.is_active())
		return
	var/used_overlay
	if(overlay_state_use && !COOLDOWN_FINISHED(src, cooldown_current_timer))
		used_overlay = overlay_state_use
	else if(overlay_state_active && active)
		used_overlay = overlay_state_active
	else if(overlay_state_inactive)
		used_overlay = overlay_state_inactive
	else
		return
	var/mutable_appearance/module_icon = mutable_appearance(overlay_icon_file, used_overlay)
	if(!use_mod_colors)
		module_icon.appearance_flags |= RESET_COLOR
	. += module_icon

/// Updates the signal used by active modules to be activated
/obj/item/mod/module/proc/update_signal()
	mod.selected_module.used_signal = COMSIG_MOB_ALTCLICKON
	RegisterSignal(mod.wearer, mod.selected_module.used_signal, TYPE_PROC_REF(/obj/item/mod/module, on_special_click), override = TRUE)

/obj/item/mod/module/anomaly_locked
	name = "MOD anomaly locked module"
	desc = "Форма модуля, требующая аномальное ядро для функционирования."
	incompatible_modules = list(/obj/item/mod/module/anomaly_locked)
	/// The core item the module runs off.
	var/obj/item/assembly/signaler/anomaly/core
	/// Accepted types of anomaly cores.
	var/list/accepted_anomalies = list(/obj/item/assembly/signaler/anomaly)
	/// If this one starts with a core in.
	var/prebuilt = FALSE
	var/core_removable = TRUE

/obj/item/mod/module/anomaly_locked/Initialize(mapload)
	. = ..()
	if(!prebuilt || !length(accepted_anomalies))
		return
	var/core_path = pick(accepted_anomalies)
	core = new core_path(src)
	update_icon_state()

/obj/item/mod/module/anomaly_locked/Destroy()
	QDEL_NULL(core)
	return ..()

/obj/item/mod/module/anomaly_locked/examine(mob/user)
	. = ..()
	if(!length(accepted_anomalies))
		return
	var/list/examine_text = .
	if(core)
		examine_text.Insert(length(examine_text), span_notice(core_removable ? "Установлено ядро [core.name]. Его можно извлечь отвёрткой." : "Ядро [core.name] встроено в модуль и не извлекается."))
	else
		var/list/core_list = list()
		for(var/path in accepted_anomalies)
			var/atom/core_path = path
			core_list += initial(core_path.name)
		examine_text.Insert(length(examine_text), span_notice("You need to insert \a [english_list(core_list, and_text = " or ")] for this module to function."))

/obj/item/mod/module/anomaly_locked/on_select()
	if(!core)
		mod.balloon_alert(mod.wearer, "нет ядра!")
		return
	return ..()

/obj/item/mod/module/anomaly_locked/on_activation()
	if(QDELETED(core))
		return FALSE
	return ..()

/obj/item/mod/module/anomaly_locked/on_process(delta_time)
	if(QDELETED(core))
		if(active)
			on_deactivation()
		return FALSE
	return ..()

/obj/item/mod/module/anomaly_locked/Exited(atom/movable/gone, direction)
	. = ..()
	if(gone != core)
		return
	core = null
	if(active)
		on_deactivation()
	update_icon_state()

/obj/item/mod/module/anomaly_locked/on_active_process(delta_time)
	if(!core)
		return FALSE
	return TRUE

/obj/item/mod/module/anomaly_locked/attackby(obj/item/item, mob/living/user, params)
	if(item.type in accepted_anomalies)
		if(core)
			mod?.balloon_alert(user, "ядро уже внутри!")
			return
		if(!user.transferItemToLoc(item, src))
			return
		core = item
		mod?.balloon_alert(user, "ядро установлено")
		playsound(src, 'sound/machines/click.ogg', 30, TRUE)
		update_icon_state()
	else
		return ..()

/obj/item/mod/module/anomaly_locked/screwdriver_act(mob/living/user, obj/item/tool)
	. = ..()
	if(!core_removable)
		balloon_alert(user, "ядро не извлекается")
		return TRUE
	if(!core)
		mod?.balloon_alert(user, "нет ядра!")
		return
	var/obj/item/assembly/signaler/anomaly/old_core = core
	mod?.balloon_alert(user, "изъятие ядра...")
	if(!do_after(user, 3 SECONDS, target = src) || QDELETED(old_core) || core != old_core)
		mod?.balloon_alert(user, "прервано!")
		return
	mod?.balloon_alert(user, "ядро изъято")
	old_core.forceMove(drop_location())
	if(Adjacent(user) && !issilicon(user))
		user.put_in_hands(old_core)

/obj/item/mod/module/anomaly_locked/update_icon_state()
	icon_state = initial(icon_state) + (core ? "-core" : "")
	return ..()

/obj/item/mod/module/proc/get_slowdown()
	return 0

/obj/item/mod/module/proc/can_install(obj/item/mod/control/suit, mob/user)
	return TRUE
