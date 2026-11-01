/obj/item/mod/control/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "MODsuit", name)
		ui.open()

/obj/item/mod/control/ui_data(mob/user)
	var/data = list()
	var/obj/item/stock_parts/cell/cell = get_cell()
	data["interface_break"] = interface_break
	data["malfunctioning"] = is_malfunctioning()
	data["open"] = is_open()
	data["active"] = is_active()
	data["link_id"] = mod_link.id
	data["link_name"] = mod_link.get_display_name()
	data["link_freq"] = mod_link.frequency
	data["link_call"] = mod_link.get_other()?.id
	data["complexity"] = complexity
	data["selected_module"] = selected_module?.name
	data["wearer_name"] = wearer ? (wearer.get_authentification_name("Unknown") || "Unknown") : "No Occupant"
	data["wearer_job"] = wearer ? wearer.get_assignment("Unknown", "Unknown", FALSE) : "No Job"
	data["AI"] = ai?.name
	data["is_pAI"] = ai ? ispAI(ai) : FALSE
	data["is_user_AI"] = ai ? user == ai : FALSE
	data["cell"] = cell?.name || core?.charge_source()?.name
	data["charge"] = round(get_charge_percent(), 1)
	data["modules"] = list()
	for(var/obj/item/mod/module/module as anything in modules)
		var/list/module_data = list(
			name = module.name,
			description = module.desc,
			module_type = module.module_type,
			can_pin = (user == wearer || user == ai) && module.module_type != MODULE_PASSIVE && module.module_type != MODULE_ARMOR,
			active = module.active,
			idle_power = module.idle_power_cost,
			active_power = module.active_power_cost,
			use_power = module.use_power_cost,
			complexity = module.complexity,
			cooldown_time = module.cooldown_time,
			cooldown = round(COOLDOWN_TIMELEFT(module, cooldown_current_timer), 1 SECONDS),
			id = module.tgui_id,
			ref = REF(module),
			configuration_data = module.get_configuration()
		)
		module_data += module.add_ui_data()
		data["modules"] += list(module_data)
	return data

/obj/item/mod/control/ui_static_data(mob/user)
	var/data = list()
	var/obj/item/helmet = get_helmet()
	var/obj/item/chestplate = get_chestplate()
	var/obj/item/gauntlets = get_gauntlets()
	var/obj/item/boots = get_boots()
	data["ui_theme"] = ui_theme
	data["control"] = name
	data["complexity_max"] = complexity_max
	data["helmet"] = helmet?.name
	data["chestplate"] = chestplate?.name
	data["gauntlets"] = gauntlets?.name
	data["boots"] = boots?.name
	return data

/obj/item/mod/control/ui_act(action, params)
	. = ..()
	if(.)
		return
	return handle_ui_action(action, params, usr)

/obj/item/mod/control/proc/handle_ui_action(action, list/params, mob/user)
	if(is_malfunctioning() && prob(MOD_BUTTON_MALFUNCTION_CHANCE))
		balloon_alert(user, "button malfunctions!")
		return
	switch(action)
		if("call")
			if(user != wearer)
				return FALSE
			mod_link.choose_call(user)
		if("rename_link")
			return mod_link.rename(user)
		if("activate")
			toggle_activate(user)
		if("select")
			var/obj/item/mod/module/module = locate(params["ref"]) in modules
			if(!module)
				return
			module.on_select()
		if("pin")
			if(user != wearer && user != ai)
				return FALSE
			var/obj/item/mod/module/module = locate(params["ref"]) in modules
			if(!module)
				return FALSE
			return generate_ability_button(module, user)
		if("configure")
			var/obj/item/mod/module/module = locate(params["ref"]) in modules
			if(!module)
				return
			module.configure_edit(params["key"], params["value"])
		if("remove_pai")
			if(ishuman(user)) // Only the MODsuit's wearer should be removing the pAI.
				extract_pai(user)
	return TRUE
