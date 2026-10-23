/obj/machinery/atmospherics/components/unary/thermomachine
	icon = 'icons/obj/atmospherics/components/thermomachine.dmi'
	icon_state = "thermo_base"

	name = "thermomachine"
	desc = "Нагревает или охлаждает газ в подсоединённой системе труб."

	density = TRUE
	max_integrity = 300
	armor_type = /datum/armor/thermal_devices
	layer = OBJ_LAYER
	plane = GAME_PLANE
	circuit = /obj/item/circuitboard/machine/thermomachine
	move_resist = 1000

	pipe_flags = PIPING_ONE_PER_TURF

	var/icon_state_off = "thermo_base"
	var/icon_state_on = "thermo_base_1"
	var/icon_state_open = "thermo_base-o"

	var/base_cooling = 170
	var/base_heating = 140
	var/min_temperature = 170
	var/max_temperature = 140
	var/target_temperature = T20C
	var/heat_capacity = 0
	var/interactive = TRUE // So mapmakers can disable interaction.

/obj/machinery/atmospherics/components/unary/thermomachine/Initialize(mapload)
	. = ..()
	initialize_directions = dir

/obj/machinery/atmospherics/components/unary/thermomachine/on_construction()
	var/obj/item/circuitboard/machine/thermomachine/board = circuit
	if(board)
		piping_layer = board.pipe_layer
	..(dir, piping_layer)

/obj/machinery/atmospherics/components/unary/thermomachine/RefreshParts()
	var/B = 0
	var/L = 0
	for(var/obj/item/stock_parts/matter_bin/M in component_parts)
		B += M.rating
	for(var/obj/item/stock_parts/micro_laser/M in component_parts)
		L += M.rating
	heat_capacity = 5000 * ((B - 1) ** 2)
	min_temperature = max(T0C - (base_cooling + L * 15), TCMB)
	max_temperature = T20C + (base_heating * L)

/obj/machinery/atmospherics/components/unary/thermomachine/update_icon()
	cut_overlays()

	if(panel_open)
		icon_state = icon_state_open
	else if(on && is_operational)
		icon_state = icon_state_on
	else
		icon_state = icon_state_off

	add_overlay(getpipeimage(icon, "pipe", dir, , piping_layer))

	var/colors_to_use
	switch(target_temperature)
		if(700 to INFINITY)
			colors_to_use = "#FF0000"
		if(460 to 700)
			colors_to_use = "#FF9900"
		if(340 to 460)
			colors_to_use = "#FFFF00"
		if(270 to 340)
			colors_to_use = "#00FF00"
		if(200 to 270)
			colors_to_use = "#00FFFF"
		if(120 to 200)
			colors_to_use = "#0000FF"
		else
			colors_to_use = "#AA55FF"

	var/meter_state = "temp_meter"
	if(panel_open)
		meter_state = "temp_meter-o"
	else if(on && is_operational)
		meter_state = "temp_meter_1"
	var/image/meter = image(icon, meter_state)
	meter.color = colors_to_use
	add_overlay(meter)

/obj/machinery/atmospherics/components/unary/thermomachine/update_icon_nopipes()
	cut_overlays()
	if(showpipe)
		add_overlay(getpipeimage(icon, "scrub_cap", initialize_directions))

/obj/machinery/atmospherics/components/unary/thermomachine/examine(mob/user)
	. = ..()
	. += span_notice("<b>При закрытой панели:</b>")
	. += span_notice(" -<b>AltClick</b> меняет настройку температуры.")
	. += span_notice(" -<b>CtrlClick</b> включает/выключает машину.")
	. += span_notice("<b>При открытой панели:</b>")
	. += span_notice(" -<b>Мультитул</b> переключает слой входной трубы.")
	. += span_notice(" -<b>Ключ</b> вращает входную трубу.")
	. += span_notice(" -<b>Ключ (disarm)</b> откручивает машину от пола.")
	. += span_notice("Термостат настроен на <b>[target_temperature]K ([target_temperature-T0C]C)</b>.")

/obj/machinery/atmospherics/components/unary/thermomachine/examine_display_content(mob/user)
	. += "\
	– Теплоёмкость работы с газами: <b>[heat_capacity] J/K</b>. \n\
	– Диапазон T: <b>[min_temperature]K - [max_temperature]K ([min_temperature-T0C]C - [max_temperature-T0C]C)</b>."

/obj/machinery/atmospherics/components/unary/thermomachine/process_atmos()
	..()
	if(!on || !nodes[1])
		return
	var/datum/gas_mixture/air_contents = airs[1]

	var/air_heat_capacity = air_contents.heat_capacity()
	var/combined_heat_capacity = heat_capacity + air_heat_capacity
	var/old_temperature = air_contents.return_temperature()

	if(combined_heat_capacity > 0)
		var/combined_energy = heat_capacity * target_temperature + air_heat_capacity * air_contents.return_temperature()
		air_contents.set_temperature(combined_energy/combined_heat_capacity)

	var/temperature_delta = abs(old_temperature - air_contents.return_temperature())
	if(temperature_delta > 1)
		active_power_usage = (heat_capacity * temperature_delta) / 10 + idle_power_usage
		update_parents()
	else
		active_power_usage = idle_power_usage
	return TRUE

/obj/machinery/atmospherics/components/unary/thermomachine/power_change()
	..()
	update_icon()

/obj/machinery/atmospherics/components/unary/thermomachine/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/wrench) && user.a_intent == INTENT_DISARM && !(flags_1 & NODECONSTRUCT_1) && panel_open)
		to_chat(user, span_notice("Вы [anchored ? "откручиваете" : "прикручиваете"] [src]..."))
		if(I.use_tool(src, user, 40, volume = 75))
			to_chat(user, span_notice("Вы [anchored ? "открутили" : "прикрутили"] [src]."))
			set_anchored(!anchored)
		return
	if(panel_open && !anchored && istype(I, /obj/item/screwdriver))
		balloon_alert(user, "Сначала прикрути ключом")
		return
	if(panel_open && istype(I, /obj/item/multitool))
		piping_layer = (piping_layer >= PIPING_LAYER_MAX) ? PIPING_LAYER_MIN : (piping_layer + 1)
		to_chat(user, span_notice("Входная труба переключёна на слой [piping_layer]."))
		if(anchored)
			reconnect_nodes()
		update_icon()
		return
	if(!on)
		if(default_deconstruction_screwdriver(user, icon_state_open, icon_state_off, I))
			return
	if(default_change_direction_wrench(user, I))
		return
	if(default_deconstruction_crowbar(I))
		return
	return ..()

/obj/machinery/atmospherics/components/unary/thermomachine/default_change_direction_wrench(mob/user, obj/item/I)
	if(!..())
		return FALSE
	SetInitDirections()
	var/obj/machinery/atmospherics/node = nodes[1]
	if(node)
		node.disconnect(src)
		nodes[1] = null
	if(parents[1])
		nullifyPipenet(parents[1])

	atmosinit()
	node = nodes[1]
	if(node)
		node.atmosinit()
		node.addMember(src)
	SSair.add_to_rebuild_queue(src)
	return TRUE

/obj/machinery/atmospherics/components/unary/thermomachine/ui_status(mob/user)
	if(interactive)
		return ..()
	return UI_CLOSE

/obj/machinery/atmospherics/components/unary/thermomachine/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ThermoMachine", name)
		ui.open()

/obj/machinery/atmospherics/components/unary/thermomachine/ui_data(mob/user)
	var/list/data = list()
	data["on"] = on

	data["min"] = min_temperature
	data["max"] = max_temperature
	data["target"] = target_temperature
	data["initial"] = initial(target_temperature)

	var/datum/gas_mixture/air1 = airs[1]
	data["temperature"] = air1.return_temperature()
	data["pressure"] = air1.return_pressure()
	return data

/obj/machinery/atmospherics/components/unary/thermomachine/ui_act(action, params)

	if(..())
		return

	switch(action)
		if("power")
			on = !on
			use_power = on ? ACTIVE_POWER_USE : IDLE_POWER_USE
			investigate_log("was turned [on ? "on" : "off"] by [key_name(usr)]", INVESTIGATE_ATMOS)
			. = TRUE
		if("target")
			var/target = params["target"]
			var/adjust = text2num(params["adjust"])
			if(target == "input")
				target = input("Задайте новое значение ([min_temperature]-[max_temperature] K):", name, target_temperature) as num|null
				if(!isnull(target))
					. = TRUE
			else if(adjust)
				target = target_temperature + adjust
				. = TRUE
			else if(text2num(target) != null)
				target = text2num(target)
				. = TRUE
			if(.)
				target_temperature = clamp(target, min_temperature, max_temperature)
				investigate_log("was set to [target_temperature] K by [key_name(usr)]", INVESTIGATE_ATMOS)

	update_icon()

/obj/machinery/atmospherics/components/unary/thermomachine/CtrlClick(mob/living/user)
	var/area/A = get_area(src)
	var/turf/T = get_turf(src)
	if(!istype(user) || !user.canUseTopic(src, BE_CLOSE))
		return
	if(!anchored)
		user.start_pulling(src)
		return
	if(panel_open)
		to_chat(user, span_warning("Сначала закройте панель обслуживания!"))
		return
	on = !on
	update_icon()
	balloon_alert(user, "[on ? "включено" : "выключено"]")
	investigate_log("was turned [on ? "on" : "off"] by [key_name(user)]", INVESTIGATE_ATMOS)
	message_admins("[src.name] was turned [on ? "on" : "off"] [ADMIN_LOOKUPFLW(usr)] at [ADMIN_COORDJMP(T)], [A]")

/obj/machinery/atmospherics/components/unary/thermomachine/AltClick(mob/living/user)
	if(!can_interact(user))
		return
	if(target_temperature == T20C)
		target_temperature = max_temperature
	else if(target_temperature == max_temperature)
		target_temperature = min_temperature
	else
		target_temperature = T20C
	investigate_log("was set to [target_temperature] K by [key_name(user)]", INVESTIGATE_ATMOS)
	balloon_alert(user, "целевая температура [target_temperature] K")
	update_icon()

/obj/machinery/atmospherics/components/unary/thermomachine/Move(atom/newloc, direct)
	var/old_dir = dir
	. = ..()
	dir = old_dir

// Пресеты. Различаются только стартовой целью

/obj/machinery/atmospherics/components/unary/thermomachine/freezer
	name = "freezer"
	base_cooling = 170
	base_heating = 140

/obj/machinery/atmospherics/components/unary/thermomachine/freezer/on
	on = TRUE
	icon_state = "thermo_base_1"

/obj/machinery/atmospherics/components/unary/thermomachine/freezer/on/Initialize(mapload)
	. = ..()
	if(target_temperature == initial(target_temperature))
		target_temperature = min_temperature

/obj/machinery/atmospherics/components/unary/thermomachine/freezer/on/coldroom
	name = "cold room freezer"

/obj/machinery/atmospherics/components/unary/thermomachine/freezer/on/coldroom/Initialize(mapload)
	. = ..()
	target_temperature = T0C - 80

/obj/machinery/atmospherics/components/unary/thermomachine/heater
	name = "heater"
	base_cooling = 170
	base_heating = 140

/obj/machinery/atmospherics/components/unary/thermomachine/heater/on
	on = TRUE
	icon_state = "thermo_base_1"
