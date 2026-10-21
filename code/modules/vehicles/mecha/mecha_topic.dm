/obj/vehicle/sealed/mecha/proc/output_access_dialog(obj/item/card/id/id_card, mob/user)
	if(!id_card || !user)
		return
	. = {"<html>
			<head>
				<meta http-equiv='Content-Type' content='text/html; charset=utf-8'>
				<style>
					h1 {font-size:15px;margin-bottom:4px;}
					body {color: #00ff00; background: #000000; font-family:"Courier New", Courier, monospace; font-size: 12px;}
					a {color:#0f0;}
				</style>
			</head>
			<body>
				<h1>Following keycodes are present in this system:</h1>"}
	for(var/a in operation_req_access)
		. += "[get_access_desc(a)] - <a href='?src=[REF(src)];del_req_access=[a];user=[REF(user)];id_card=[REF(id_card)]'>Delete</a><br>"
	. += "<hr><h1>Following keycodes were detected on portable device:</h1>"
	for(var/a in id_card.access)
		if(a in operation_req_access)
			continue
		var/a_name = get_access_desc(a)
		if(!a_name)
			continue //there's some strange access without a name
		. += "[a_name] - <a href='?src=[REF(src)];add_req_access=[a];user=[REF(user)];id_card=[REF(id_card)]'>Add</a><br>"
	. +={"<hr><a href='?src=[REF(src)];finish_req_access=1;user=[REF(user)]'>Lock ID panel</a><br>
		<span class='danger'>(Warning! The ID upload panel can be unlocked only through Exosuit Interface.)</span>"}
	var/datum/browser/popup = new(user, "exosuit_add_access", "Exosuit Access")
	popup.set_content(.)
	popup.open()


/obj/vehicle/sealed/mecha/proc/output_maintenance_dialog(obj/item/card/id/id_card,mob/user)
	if(!id_card || !user)
		return
	. = {"<html>
			<head>
				<meta http-equiv='Content-Type' content='text/html; charset=utf-8'>
				<style>
					body {color: #00ff00; background: #000000; font-family:"Courier New", Courier, monospace; font-size: 12px;}
					a {padding:2px 5px; background:#32CD32;color:#000;display:block;margin:2px;text-align:center;text-decoration:none;}
				</style>
			</head>
			<body>
				[(mecha_flags & ADDING_ACCESS_POSSIBLE)?"<a href='?src=[REF(src)];req_access=1;id_card=[REF(id_card)];user=[REF(user)]'>Edit operation keycodes</a>":null]
				[(mecha_flags & ADDING_MAINT_ACCESS_POSSIBLE)?"<a href='?src=[REF(src)];maint_access=1;id_card=[REF(id_card)];user=[REF(user)]'>[(construction_state > MECHA_LOCKED) ? "Terminate" : "Initiate"] maintenance protocol</a>":null]
				[(construction_state == MECHA_OPEN_HATCH) ?"--------------------</br>":null]
				[(construction_state == MECHA_OPEN_HATCH) ?"[cell?"<a href='?src=[REF(src)];drop_cell=1;id_card=[REF(id_card)];user=[REF(user)]'>Drop power cell</a>":"No cell installed</br>"]":null]
				[(construction_state == MECHA_OPEN_HATCH) ?"[scanmod?"<a href='?src=[REF(src)];drop_scanmod=1;id_card=[REF(id_card)];user=[REF(user)]'>Drop scanning module</a>":"No scanning module installed</br>"]":null]
				[(construction_state == MECHA_OPEN_HATCH) ?"[capacitor?"<a href='?src=[REF(src)];drop_cap=1;id_card=[REF(id_card)];user=[REF(user)]'>Drop capacitor</a>":"No capacitor installed</br>"]":null]
				[(construction_state == MECHA_OPEN_HATCH) ?"--------------------</br>":null]
				[(construction_state > MECHA_LOCKED) ?"<a href='?src=[REF(src)];set_internal_tank_valve=1;user=[REF(user)]'>Set Cabin Air Pressure</a>":null]
			</body>
		</html>"}
	user << browse(., "window=exosuit_maint_console")
	onclose(user, "exosuit_maint_console")




/////////////////
///// Topic /////
/////////////////

/obj/vehicle/sealed/mecha/Topic(href, href_list)
	..()
	if(!usr)
		return
	if(usr.incapacitated())
		return

	if(in_range(src, usr))
		//Start of ID requirements.
		if(href_list["id_card"])
			var/obj/item/card/id/id_card
			id_card = locate(href_list["id_card"])
			if(!istype(id_card))
				return

			if(href_list["req_access"])
				if(!(mecha_flags & ADDING_ACCESS_POSSIBLE))
					return
				output_access_dialog(id_card,usr)
				return

			if(href_list["maint_access"])
				if(!(mecha_flags & ADDING_MAINT_ACCESS_POSSIBLE))
					return
				if(construction_state == MECHA_LOCKED)
					construction_state = MECHA_SECURE_BOLTS
					to_chat(usr, "<span class='notice'>The securing bolts are now exposed.</span>")
				else if(construction_state == MECHA_SECURE_BOLTS)
					construction_state = MECHA_LOCKED
					to_chat(usr, "<span class='notice'>The securing bolts are now hidden.</span>")
				output_maintenance_dialog(id_card,usr)
				return
			if(href_list["drop_cell"])
				if(construction_state == MECHA_OPEN_HATCH)
					cell.forceMove(get_turf(src))
					cell = null
				output_maintenance_dialog(id_card,usr)
				return
			if(href_list["drop_scanmod"])
				if(construction_state == MECHA_OPEN_HATCH)
					scanmod.forceMove(get_turf(src))
					scanmod = null
				output_maintenance_dialog(id_card,usr)
				return
			if(href_list["drop_cap"])
				if(construction_state == MECHA_OPEN_HATCH)
					capacitor.forceMove(get_turf(src))
					capacitor = null
				output_maintenance_dialog(id_card,usr)
				return

			if(href_list["add_req_access"])
				if(!(mecha_flags & ADDING_ACCESS_POSSIBLE))
					return
				operation_req_access += text2num(href_list["add_req_access"])
				output_access_dialog(id_card,usr)
				return

			if(href_list["del_req_access"])
				if(!(mecha_flags & ADDING_ACCESS_POSSIBLE))
					return
				operation_req_access -= text2num(href_list["del_req_access"])
				output_access_dialog(id_card, usr)
				return
			return //Here end everything requiring an ID.

		//Here ID access stuff goes to die.
		if(href_list["finish_req_access"])
			mecha_flags &= ~ADDING_ACCESS_POSSIBLE
			usr << browse(null,"window=exosuit_add_access")
			return

		//Set pressure.
		if(href_list["set_internal_tank_valve"] && construction_state)
			var/new_pressure = input(usr,"Input new output pressure","Pressure setting",internal_tank_valve) as num|null
			if(isnull(new_pressure) || usr.incapacitated() || !construction_state)
				return
			internal_tank_valve = new_pressure
			to_chat(usr, "<span class='notice'>The internal pressure valve has been set to [internal_tank_valve]kPa.</span>")
			return


// Калибровка сохраняет прежнее требование: мех должен оставаться на месте.
/obj/vehicle/sealed/mecha/proc/stationary_repair(location)
	if(location == loc)
		clearInternalDamage(MECHA_INT_CONTROL_LOST)
		to_chat(occupants, "[icon2html(src, occupants)]<span class='notice'>Recalibration successful.</span>")
		log_message("Recalibration of coordination system finished with 0 errors.", LOG_MECHA)
	else
		to_chat(occupants, "[icon2html(src, occupants)]<span class='warning'>Recalibration failed!</span>")
		log_message("Recalibration of coordination system failed with 1 error.", LOG_MECHA, color="red")

// Панель Paradise использует наши флаги управления и общий список модулей.
/obj/vehicle/sealed/mecha/ui_status(mob/user, datum/ui_state/state)
	if(!is_occupant(user))
		return UI_CLOSE
	return user.shared_ui_interaction(src)

/obj/vehicle/sealed/mecha/ui_interact(mob/user, datum/tgui/ui)
	if(!is_occupant(user))
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Mecha", name)
		ui.open()

/obj/vehicle/sealed/mecha/ui_static_data(mob/user)
	return list(
		"cabin_pressure_warning_min" = WARNING_LOW_PRESSURE,
		"cabin_pressure_hazard_min" = HAZARD_LOW_PRESSURE,
		"cabin_pressure_warning_max" = WARNING_HIGH_PRESSURE,
		"cabin_pressure_hazard_max" = HAZARD_HIGH_PRESSURE,
		"cabin_temp_warning_min" = BODYTEMP_COLD_DAMAGE_LIMIT - T0C,
		"cabin_temp_warning_max" = BODYTEMP_HEAT_DAMAGE_LIMIT - T0C,
		"internal_damage_keys" = list(
			"MECHA_INT_FIRE" = MECHA_INT_FIRE,
			"MECHA_INT_TEMP_CONTROL" = MECHA_INT_TEMP_CONTROL,
			"MECHA_INT_TANK_BREACH" = MECHA_INT_TANK_BREACH,
			"MECHA_INT_CONTROL_LOST" = MECHA_INT_CONTROL_LOST,
			"MECHA_INT_SHORT_CIRCUIT" = MECHA_INT_SHORT_CIRCUIT,
		),
	)

/obj/vehicle/sealed/mecha/ui_data(mob/user)
	if(ui_preview_appearance != appearance)
		ui_preview_icon = icon2base64(getFlatIcon(src, no_anim = TRUE))
		ui_preview_appearance = appearance
	var/list/modules = list()
	for(var/obj/item/mecha_parts/mecha_equipment/module as anything in equipment)
		modules += list(module.get_ui_data())
	var/list/actions = list()
	var/list/user_actions = occupant_actions[user]
	for(var/action_type in user_actions)
		var/datum/action/action = user_actions[action_type]
		if(istype(action, /datum/action/vehicle/sealed/mecha/mech_view_stats))
			continue
		actions += list(list("name" = action.name, "ref" = REF(action)))
	var/list/accesses = list()
	for(var/access in operation_req_access)
		accesses += get_access_desc(access)
	return list(
		"name" = name,
		"mech_image" = ui_preview_icon,
		"integrity" = obj_integrity,
		"integrity_max" = max_integrity,
		"power_level" = cell?.charge,
		"power_max" = cell?.maxcharge,
		"lights" = !!(mecha_flags & LIGHTS_ON),
		"has_lights" = !!(mecha_flags & HAS_LIGHTS),
		"has_tank" = !!internal_tank,
		"use_internal_tank" = use_internal_tank,
		"cabin_temp" = round(return_temperature() - T0C, 0.1),
		"cabin_pressure" = round(return_pressure(), 0.1),
		"tank_pressure" = internal_tank ? round(internal_tank.return_air().return_pressure(), 0.1) : null,
		"tank_temp" = internal_tank ? round(internal_tank.return_air().return_temperature() - T0C, 0.1) : null,
		"port_connected" = !!internal_tank?.connected_port,
		"internal_damage" = internal_damage,
		"dna_lock" = dna_lock,
		"dna_lock_name" = dna_lock_name,
		"id_upload" = !!(mecha_flags & ADDING_ACCESS_POSSIBLE),
		"accesses" = accesses,
		"maint_access" = !!(mecha_flags & ADDING_MAINT_ACCESS_POSSIBLE),
		"maintenance" = construction_state != MECHA_LOCKED,
		"can_equipment" = !!(occupants[user] & VEHICLE_CONTROL_EQUIPMENT),
		"can_settings" = !!(occupants[user] & VEHICLE_CONTROL_SETTINGS),
		"modules" = modules,
		"max_equip" = max_equip,
		"actions" = actions,
		"cargo" = get_cargo_ui_data(),
		"ui_honked" = istype(src, /obj/vehicle/sealed/mecha/combat/honker),
		"radio_data" = radio ? list(
			"microphone" = radio.broadcasting,
			"speaker" = radio.listening,
			"frequency" = radio.frequency,
			"minFrequency" = radio.freerange ? MIN_FREE_FREQ : MIN_FREQ,
			"maxFrequency" = radio.freerange ? MAX_FREE_FREQ : MAX_FREQ,
		) : null,
	)

/obj/vehicle/sealed/mecha/proc/get_cargo_ui_data()
	return null

/obj/vehicle/sealed/mecha/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/mob/user = ui.user
	if(!is_occupant(user) || user.incapacitated())
		return FALSE
	if(action == "trigger_action")
		var/datum/action/vehicle/sealed/mecha/chosen = locate(params["ref"])
		var/list/user_actions = occupant_actions[user]
		if(!istype(chosen) || !user_actions || user_actions[chosen.type] != chosen || chosen.chassis != src || chosen.owner != user)
			return FALSE
		chosen.Trigger()
		return TRUE
	if(action == "select_module" || action == "equip_act")
		if(!(occupants[user] & VEHICLE_CONTROL_EQUIPMENT))
			return FALSE
		var/obj/item/mecha_parts/mecha_equipment/gear = locate(params["ref"])
		if(!istype(gear) || gear.chassis != src || !(gear in equipment))
			return FALSE
		if(action == "equip_act")
			return gear.handle_ui_act(params["gear_action"], params)
		if(!gear.selectable)
			return FALSE
		if(params["button"] == "right")
			selected_right = selected_right == gear ? null : gear
		else if(params["button"] == "left")
			selected = selected == gear ? null : gear
		else
			return FALSE
		gear.update_equip_info()
		return TRUE
	if(!(occupants[user] & VEHICLE_CONTROL_SETTINGS))
		return FALSE
	switch(action)
		if("toggle_lights", "toggle_internal_tank")
			var/action_type = action == "toggle_lights" ? /datum/action/vehicle/sealed/mecha/mech_toggle_lights : /datum/action/vehicle/sealed/mecha/mech_toggle_internals
			var/datum/action/control = LAZYACCESSASSOC(occupant_actions, user, action_type)
			control?.Trigger()
		if("toggle_microphone")
			if(radio)
				radio.broadcasting = !radio.broadcasting
		if("toggle_speaker")
			if(radio)
				radio.listening = !radio.listening
		if("set_frequency")
			var/frequency = text2num(params["new_frequency"])
			if(radio && !isnull(frequency))
				radio.set_frequency(sanitize_frequency(frequency, radio.freerange))
		if("toggle_id_upload")
			mecha_flags ^= ADDING_ACCESS_POSSIBLE
		if("toggle_maint_access")
			if(construction_state != MECHA_LOCKED)
				return FALSE
			mecha_flags ^= ADDING_MAINT_ACCESS_POSSIBLE
		if("changename")
			var/new_name = stripped_input(user, "Новое название экзокостюма", "Переименование", name, MAX_NAME_LEN)
			if(!new_name || !is_occupant(user) || user.incapacitated() || !(occupants[user] & VEHICLE_CONTROL_SETTINGS))
				return FALSE
			name = new_name
		if("dna_lock")
			var/mob/living/carbon/carbon_user = user
			if(!istype(carbon_user) || !carbon_user.dna || dna_lock)
				return FALSE
			dna_lock = carbon_user.dna.unique_enzymes
			dna_lock_name = user.name
			to_chat(user, span_notice("Игла берёт образец вашей ДНК. ДНК-замок установлен."))
		if("reset_dna")
			dna_lock = null
			dna_lock_name = null
		if("repair_int_damage")
			if(!(internal_damage & MECHA_INT_CONTROL_LOST))
				return FALSE
			log_message("Recalibration of coordination system started.", LOG_MECHA)
			addtimer(CALLBACK(src, PROC_REF(stationary_repair), loc), 10 SECONDS, TIMER_UNIQUE)
			to_chat(user, span_notice("Начата калибровка. Не двигайтесь 10 секунд."))
		if("toggle_port_connection")
			if(!internal_tank)
				return FALSE
			if(internal_tank.connected_port)
				internal_tank.disconnect()
			else
				var/obj/machinery/atmospherics/components/unary/portables_connector/port = locate() in loc
				if(!internal_tank.connect(port))
					to_chat(user, span_warning("Не удалось подключиться к газовому порту."))
		else
			return FALSE
	return TRUE
