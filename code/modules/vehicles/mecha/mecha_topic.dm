// У внешней панели свой владелец TGUI, чтобы она не подменяла интерфейс пилота.
/obj/vehicle/sealed/mecha/proc/open_maintenance_panel(obj/item/id_source, mob/user)
	if(!user.canUseTopic(src, be_close = TRUE, no_tk = TRUE))
		return
	if(!(mecha_flags & (ADDING_ACCESS_POSSIBLE | ADDING_MAINT_ACCESS_POSSIBLE)))
		to_chat(user, span_warning("Оператор запретил изменение доступа и техобслуживание."))
		return
	if(!id_source?.GetID() || !user.contains(id_source))
		to_chat(user, span_warning("Для открытия панели нужна ID-карта в руке или надетая на вас."))
		return
	if(!internals_access_allowed(user))
		to_chat(user, span_warning("Недостаточно прав для обслуживания меха."))
		return
	if(!maintenance_panel)
		maintenance_panel = new(src)
	maintenance_panel.id_sources[user] = WEAKREF(id_source)
	maintenance_panel.ui_interact(user)

/datum/mecha_maintenance
	var/obj/vehicle/sealed/mecha/chassis
	// Карта берётся из предъявленного предмета заново, в том числе из КПК.
	var/list/id_sources = list()

/datum/mecha_maintenance/New(obj/vehicle/sealed/mecha/chassis)
	src.chassis = chassis
	return ..()

/datum/mecha_maintenance/Destroy()
	SStgui.close_uis(src)
	id_sources.Cut()
	chassis = null
	return ..()

/datum/mecha_maintenance/proc/get_id_card(mob/user)
	var/datum/weakref/id_source_ref = id_sources[user]
	var/obj/item/id_source = id_source_ref?.resolve()
	if(QDELETED(id_source) || !user.contains(id_source))
		return null
	return id_source.GetID()

/datum/mecha_maintenance/ui_host(mob/user)
	return chassis

/datum/mecha_maintenance/ui_state(mob/user)
	return GLOB.physical_state

/datum/mecha_maintenance/ui_status(mob/user, datum/ui_state/state)
	if(QDELETED(chassis) || !user.Adjacent(chassis) || !get_id_card(user) || !chassis.internals_access_allowed(user))
		return UI_CLOSE
	if(!(chassis.mecha_flags & (ADDING_ACCESS_POSSIBLE | ADDING_MAINT_ACCESS_POSSIBLE)))
		return UI_CLOSE
	return ..()

/datum/mecha_maintenance/ui_close(mob/user)
	id_sources -= user

/datum/mecha_maintenance/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "MechaMaintenance", "Обслуживание меха")
		if(!ui.open())
			id_sources -= user
			qdel(ui)

/datum/mecha_maintenance/ui_data(mob/user)
	var/obj/item/card/id/id_card = get_id_card(user)
	if(QDELETED(chassis) || !id_card)
		return list("accesses" = list())
	var/list/accesses = list()
	for(var/access in (chassis.operation_req_access | id_card.access))
		accesses += list(list(
			"id" = access,
			"name" = get_access_desc(access),
			"required" = (access in chassis.operation_req_access),
			"on_card" = (access in id_card.access),
		))
	var/state_name
	var/state_hint
	switch(chassis.construction_state)
		if(MECHA_LOCKED)
			state_name = "Отключено"
			state_hint = "Начните техобслуживание, чтобы получить доступ к крепёжным болтам."
		if(MECHA_SECURE_BOLTS)
			state_name = "Болты закреплены"
			state_hint = "Ослабьте болты гаечным ключом, чтобы открыть люк."
		if(MECHA_LOOSE_BOLTS)
			state_name = "Болты ослаблены"
			state_hint = "Откройте люк ломом или затяните болты гаечным ключом."
		if(MECHA_OPEN_HATCH)
			state_name = "Люк открыт"
			state_hint = "Можно извлекать компоненты. Перед завершением закройте люк ломом и затяните болты гаечным ключом."
	return list(
		"name" = format_text(chassis.name),
		"card_name" = id_card.registered_name || format_text(id_card.name),
		"card_assignment" = id_card.get_assignment_name(),
		"maintenance_allowed" = !!(chassis.mecha_flags & ADDING_MAINT_ACCESS_POSSIBLE),
		"access_edit_allowed" = !!(chassis.mecha_flags & ADDING_ACCESS_POSSIBLE),
		"one_access" = chassis.operation_one_access,
		"maintenance_active" = chassis.construction_state != MECHA_LOCKED,
		"can_toggle_maintenance" = chassis.construction_state <= MECHA_SECURE_BOLTS,
		"hatch_open" = chassis.construction_state == MECHA_OPEN_HATCH,
		"state_name" = state_name,
		"state_hint" = state_hint,
		"has_tank" = !!chassis.internal_tank,
		"pressure" = chassis.internal_tank_valve,
		"cabin_pressure" = round(chassis.return_pressure(), 0.1),
		"cell" = chassis.cell ? "[format_text(chassis.cell.name)] (Tier [chassis.cell.rating])" : null,
		"scanmod" = chassis.scanmod ? "Уровень [chassis.scanmod.rating]" : null,
		"capacitor" = chassis.capacitor ? "Уровень [chassis.capacitor.rating]" : null,
		"accesses" = accesses,
	)

/datum/mecha_maintenance/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/mob/user = ui.user
	if(ui_status(user, state) != UI_INTERACTIVE)
		return FALSE
	var/obj/item/card/id/id_card = get_id_card(user)
	switch(action)
		if("toggle_maintenance")
			if(!(chassis.mecha_flags & ADDING_MAINT_ACCESS_POSSIBLE))
				return FALSE
			if(chassis.construction_state == MECHA_LOCKED)
				chassis.construction_state = MECHA_SECURE_BOLTS
				to_chat(user, span_notice("Протокол техобслуживания активирован. Крепёжные болты доступны."))
			else if(chassis.construction_state == MECHA_SECURE_BOLTS)
				chassis.construction_state = MECHA_LOCKED
				to_chat(user, span_notice("Протокол техобслуживания отключён."))
			else
				return FALSE
		if("set_pressure")
			if(!chassis.internal_tank || chassis.construction_state == MECHA_LOCKED)
				return FALSE
			var/pressure = text2num(params["pressure"])
			if(isnull(pressure))
				return FALSE
			chassis.internal_tank_valve = max(0, pressure)
		if("eject_component")
			if(chassis.construction_state != MECHA_OPEN_HATCH)
				return FALSE
			var/obj/item/component
			switch(params["component"])
				if("cell")
					component = chassis.cell
					chassis.cell = null
				if("scanmod")
					component = chassis.scanmod
					chassis.scanmod = null
				if("capacitor")
					component = chassis.capacitor
					chassis.capacitor = null
			if(!component)
				return FALSE
			component.forceMove(get_turf(chassis))
			chassis.update_part_values()
		if("toggle_access")
			if(!(chassis.mecha_flags & ADDING_ACCESS_POSSIBLE))
				return FALSE
			var/access = params["access"]
			// Сохраняем строковые коды доступов, а числовые строки приводим к числам.
			if(istext(access) && !(access in chassis.operation_req_access) && !(access in id_card.access))
				access = text2num(access)
			if(isnull(access))
				return FALSE
			if(access in chassis.operation_req_access)
				chassis.operation_req_access -= access
			else if(access in id_card.access)
				chassis.operation_req_access |= access
			else
				return FALSE
		if("toggle_one_access")
			if(!(chassis.mecha_flags & ADDING_ACCESS_POSSIBLE))
				return FALSE
			chassis.operation_one_access = !chassis.operation_one_access
		if("lock_access")
			if(!(chassis.mecha_flags & ADDING_ACCESS_POSSIBLE))
				return FALSE
			chassis.mecha_flags &= ~ADDING_ACCESS_POSSIBLE
		else
			return FALSE
	SStgui.update_uis(chassis)
	return TRUE


// Калибровка сохраняет прежнее требование: мех должен оставаться на месте.
/obj/vehicle/sealed/mecha/proc/stationary_repair(location)
	if(location == loc)
		clearInternalDamage(MECHA_INT_CONTROL_LOST)
		to_chat(occupants, "[icon2html(src, occupants)][span_notice("Калибровка завершена успешно.")]")
		log_message("Калибровка системы координации завершена без ошибок.", LOG_MECHA)
	else
		to_chat(occupants, "[icon2html(src, occupants)][span_warning("Калибровка не удалась!")]")
		log_message("Калибровка системы координации завершилась с ошибкой.", LOG_MECHA, color="red")

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

/obj/vehicle/sealed/mecha/proc/get_default_ui_theme()
	var/list/accesses = operation_req_access | internals_req_access
	if((ACCESS_INTEQ in accesses) || (ACCESS_INTEQ_LEADER in accesses))
		return "inteq"
	if((ACCESS_SYNDICATE in accesses) || (ACCESS_SYNDICATE_LEADER in accesses))
		return "syndicate"
	if(ACCESS_CLOCKCULT in accesses)
		return "clockcult"
	if(initial(ui_theme))
		return initial(ui_theme)
	if(mecha_type & MECHA_TYPE_MEDICAL)
		return "medical"
	if(mecha_type & MECHA_TYPE_COMBAT)
		return "security"
	if(ACCESS_MINING in accesses)
		return "mining"
	if((mecha_type & MECHA_TYPE_WORKING) || (ACCESS_ENGINE in accesses))
		return "engineering"
	return "nanotrasen"

/obj/vehicle/sealed/mecha/ui_data(mob/user)
	var/image/front_view = new
	front_view.appearance = appearance
	front_view.dir = SOUTH
	front_view.transform = matrix()
	front_view.pixel_x = 0
	front_view.pixel_y = 0
	// Повороты и смещения шасси не меняют вид превью и не должны сбрасывать его кэш.
	var/normalized_appearance = front_view.appearance
	if(ui_preview_appearance != normalized_appearance)
		// Браузеру нужен отдельный PNG-кадр, а не многодирекционная DMI-иконка.
		var/icon/front_icon = getFlatIcon(front_view, defdir = SOUTH, no_anim = TRUE)
		ui_preview_icon = icon2base64(icon(front_icon, "", SOUTH, 1, FALSE))
		ui_preview_appearance = normalized_appearance
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
	var/datum/gas_mixture/internal_air_contents = internal_tank?.return_air()
	var/mob/living/carbon/carbon_user = user
	return list(
		"name" = name,
		"ui_theme" = ui_theme ? ui_theme : get_default_ui_theme(),
		"mech_image" = ui_preview_icon,
		"integrity" = round(obj_integrity),
		"integrity_max" = max_integrity,
		"power_level" = cell?.charge,
		"power_max" = cell?.maxcharge,
		"lights" = !!(mecha_flags & LIGHTS_ON),
		"has_lights" = !!(mecha_flags & HAS_LIGHTS),
		"has_tank" = !!internal_tank,
		"use_internal_tank" = use_internal_tank,
		"cabin_temp" = round(return_temperature() - T0C, 0.1),
		"cabin_pressure" = round(return_pressure(), 0.1),
		"tank_pressure" = internal_air_contents ? round(internal_air_contents.return_pressure(), 0.1) : null,
		"tank_temp" = internal_air_contents ? round(internal_air_contents.return_temperature() - T0C, 0.1) : null,
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
		"can_dna_lock" = istype(carbon_user) && !!carbon_user.dna,
		"has_port" = !!(locate(/obj/machinery/atmospherics/components/unary/portables_connector) in loc),
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
	if(action == "theme")
		var/static/list/themes = list(
			"По назначению меха" = "auto",
			"Нанотрейзен" = "nanotrasen",
			"Медицинская" = "medical",
			"Инженерная" = "engineering",
			"Шахтёрская" = "mining",
			"Научная" = "science",
			"Служба безопасности" = "security",
			"Syndicate" = "syndicate",
			"InteQ" = "inteq",
			"Пакт" = "pact",
			"Нейтральная" = "neutral",
			"НТОС" = "ntos",
			"НТОС: тёмная" = "ntos_darkmode",
			"НТОС: светлая" = "ntos_lightmode",
			"НТОС: синтетическая" = "ntos_synth",
			"НТОС: терминал" = "ntos_terminal",
			"НТОС: кошачья" = "ntos_cat",
			"Ретро" = "retro",
			"Хакерская" = "hackerman",
			"Розовая" = "hotpink",
			"Пришельцы" = "abductor",
			"Волшебник" = "wizard",
			"Культ Ратвара" = "clockcult",
			"Еретическая" = "heretic",
			"Сбой ИИ" = "malfunction",
			"Бумажная" = "paper",
			"Карточный стол" = "cardtable",
			"Предупреждение" = "disclaimer",
		)
		var/current_theme = "По назначению меха"
		for(var/theme_name in themes)
			if(themes[theme_name] == ui_theme)
				current_theme = theme_name
				break
		var/choice = tgui_input_list(user, "Выберите оформление панели управления.", "Тема меха", themes, current_theme)
		if(!choice || !(choice in themes) || !is_occupant(user) || user.incapacitated())
			return FALSE
		ui_theme = themes[choice] == "auto" ? null : themes[choice]
		return TRUE
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
			var/display_name = strip_html_tags(html_decode(format_text(name)))
			var/new_name = tgui_input_text(user, "Новое название экзокостюма", "Переименование", default = display_name, max_length = MAX_NAME_LEN, encode = TRUE)
			if(!new_name || !is_occupant(user) || user.incapacitated() || !(occupants[user] & VEHICLE_CONTROL_SETTINGS))
				return FALSE
			name = "\improper [new_name]"
		if("dna_lock")
			var/mob/living/carbon/carbon_user = user
			if(!istype(carbon_user) || !carbon_user.dna || dna_lock)
				return FALSE
			dna_lock = carbon_user.dna.unique_enzymes
			dna_lock_name = carbon_user.real_name
			to_chat(user, span_notice("Игла берёт образец вашей ДНК. ДНК-замок установлен."))
		if("reset_dna")
			dna_lock = null
			dna_lock_name = null
		if("repair_int_damage")
			if(!(internal_damage & MECHA_INT_CONTROL_LOST))
				return FALSE
			log_message("Начата калибровка системы координации.", LOG_MECHA)
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
