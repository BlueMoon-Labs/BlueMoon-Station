/// One-way valve controlled by the input gas temperature.
/obj/machinery/atmospherics/components/binary/temperature_gate
	icon_state = "tgate_map-3"
	name = "temperature gate"
	desc = "A one-way valve which opens when its input is on the configured side of a temperature threshold."
	can_unwrench = TRUE
	shift_underlay_only = FALSE
	construction_type = /obj/item/pipe/directional
	pipe_state = "tgate"
	use_power = NO_POWER_USE
	var/target_temperature = T0C
	var/minimum_temperature = TCMB
	var/max_temperature = 4500
	var/inverted = FALSE
	var/is_gas_flowing = FALSE

/obj/machinery/atmospherics/components/binary/temperature_gate/examine(mob/user)
	. = ..()
	. += "<span class='notice'>Открывается, пока температура на входе [inverted ? "выше" : "ниже"] [round(target_temperature)] К. Мультитул инвертирует сравнение.</span>"
	. += "<span class='notice'>Ctrl-клик переключает питание; Alt-клик выставляет порог на максимум.</span>"

/obj/machinery/atmospherics/components/binary/temperature_gate/CtrlClick(mob/user)
	if(can_interact(user))
		on = !on
		atmos_wake()
		investigate_log("was turned [on ? "on" : "off"] by [key_name(user)]", INVESTIGATE_ATMOS)
		update_icon()
	return ..()

/obj/machinery/atmospherics/components/binary/temperature_gate/AltClick(mob/user)
	if(can_interact(user))
		target_temperature = max_temperature
		atmos_wake()
		investigate_log("was set to [target_temperature] K by [key_name(user)]", INVESTIGATE_ATMOS)
		update_icon()
	return ..()

/obj/machinery/atmospherics/components/binary/temperature_gate/update_icon_nopipes()
	if(on && is_operational && is_gas_flowing)
		icon_state = "tgate_flow-[SENSOR_VALVE_BODY_OFFSET]"
	else if(on && is_operational)
		icon_state = "tgate_on-[SENSOR_VALVE_BODY_OFFSET]"
	else
		icon_state = "tgate_off-[SENSOR_VALVE_BODY_OFFSET]"

/obj/machinery/atmospherics/components/binary/temperature_gate/process_atmos()
	if(atmos_idle_until > world.time)
		return
	if(!on || !is_operational)
		is_gas_flowing = FALSE
		atmos_consider_idle()
		return
	var/datum/gas_mixture/input_air = airs[1]
	var/datum/gas_mixture/output_air = airs[2]
	var/temperature_allows_flow = inverted ? input_air.return_temperature() > target_temperature : input_air.return_temperature() < target_temperature
	if(temperature_allows_flow && release_gas_to(input_air, output_air, input_air.return_pressure()))
		update_parents()
		atmos_idle_streak = 0
		is_gas_flowing = TRUE
	else
		atmos_consider_idle()
		is_gas_flowing = FALSE
	update_icon_nopipes()

/obj/machinery/atmospherics/components/binary/temperature_gate/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "AtmosTempGate", name)
		ui.open()

/obj/machinery/atmospherics/components/binary/temperature_gate/ui_data()
	// Раньше панель показывала только уставку: ни текущей температуры, ни
	// направления сравнения, которое переключает мультитул.
	return list(
		"on" = on,
		"temperature" = round(target_temperature),
		"min_temperature" = round(minimum_temperature),
		"max_temperature" = round(max_temperature),
		"inverted" = inverted,
		"flowing" = is_gas_flowing,
		"ports" = ui_port_data(),
	)

/obj/machinery/atmospherics/components/binary/temperature_gate/ui_act(action, params)
	if(..())
		return
	atmos_wake()
	switch(action)
		if("power")
			on = !on
			investigate_log("was turned [on ? "on" : "off"] by [key_name(usr)]", INVESTIGATE_ATMOS)
			. = TRUE
		if("temperature")
			var/temperature = params["temperature"]
			if(temperature == "max")
				temperature = max_temperature
				. = TRUE
			else if(text2num(temperature) != null)
				temperature = text2num(temperature)
				. = TRUE
			if(.)
				target_temperature = clamp(temperature, minimum_temperature, max_temperature)
				investigate_log("was set to [target_temperature] K by [key_name(usr)]", INVESTIGATE_ATMOS)
	update_icon()

/obj/machinery/atmospherics/components/binary/temperature_gate/can_unwrench(mob/user)
	. = ..()
	if(. && on && is_operational)
		to_chat(user, "<span class='warning'>Сначала выключите [src]!</span>")
		return FALSE

/obj/machinery/atmospherics/components/binary/temperature_gate/multitool_act(mob/living/user, obj/item/multitool/I)
	. = ..()
	inverted = !inverted
	atmos_wake()
	to_chat(user, "<span class='notice'>Теперь затвор открывается, пока вход [inverted ? "выше" : "ниже"] порога.</span>")
	return TRUE

/obj/machinery/atmospherics/components/binary/temperature_gate/layer1
	piping_layer = 1
	icon_state = "tgate_map-1"

/obj/machinery/atmospherics/components/binary/temperature_gate/layer2
	piping_layer = 2
	icon_state = "tgate_map-2"

/obj/machinery/atmospherics/components/binary/temperature_gate/layer4
	piping_layer = 4
	icon_state = "tgate_map-4"

/obj/machinery/atmospherics/components/binary/temperature_gate/layer5
	piping_layer = 5
	icon_state = "tgate_map-5"

/// Heat exchanger that conserves energy and never moves matter between nets.
/obj/machinery/atmospherics/components/binary/temperature_pump
	icon_state = "tpump_map-3"
	name = "temperature pump"
	desc = "A powered heat pump which moves heat from its input pipeline to its output without moving gas."
	can_unwrench = TRUE
	shift_underlay_only = FALSE
	construction_type = /obj/item/pipe/directional
	pipe_state = "tpump"
	var/heat_transfer_rate = 0
	var/max_heat_transfer_rate = 100

/obj/machinery/atmospherics/components/binary/temperature_pump/examine(mob/user)
	. = ..()
	. += "<span class='notice'>Ctrl-клик переключает питание; Alt-клик выставляет теплоперенос на максимум.</span>"

/obj/machinery/atmospherics/components/binary/temperature_pump/CtrlClick(mob/user)
	if(can_interact(user))
		on = !on
		atmos_wake()
		update_icon()
	return ..()

/obj/machinery/atmospherics/components/binary/temperature_pump/AltClick(mob/user)
	if(can_interact(user))
		heat_transfer_rate = max_heat_transfer_rate
		atmos_wake()
		update_icon()
	return ..()

/obj/machinery/atmospherics/components/binary/temperature_pump/update_icon_nopipes()
	icon_state = "tpump_[on && is_operational ? "on" : "off"]-[SENSOR_VALVE_BODY_OFFSET]"

/obj/machinery/atmospherics/components/binary/temperature_pump/process_atmos()
	if(atmos_idle_until > world.time)
		return
	if(!on || !is_operational || heat_transfer_rate <= 0)
		atmos_consider_idle()
		return
	var/datum/gas_mixture/input_air = airs[1]
	var/datum/gas_mixture/output_air = airs[2]
	if(!QUANTIZE(input_air.total_moles()) || !QUANTIZE(output_air.total_moles()) || input_air.return_temperature() <= output_air.return_temperature())
		atmos_consider_idle()
		return
	var/input_capacity = input_air.heat_capacity()
	var/output_capacity = output_air.heat_capacity()
	if(input_capacity <= 0 || output_capacity <= 0)
		atmos_consider_idle()
		return
	var/delta = input_air.return_temperature() - output_air.return_temperature()
	var/energy = (heat_transfer_rate * 0.01) * delta * input_capacity * output_capacity / (input_capacity + output_capacity)
	input_air.set_temperature(max(input_air.return_temperature() - energy / input_capacity, TCMB))
	output_air.set_temperature(max(output_air.return_temperature() + energy / output_capacity, TCMB))
	use_power(200)
	update_parents()
	atmos_idle_streak = 0

/obj/machinery/atmospherics/components/binary/temperature_pump/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "AtmosTempPump", name)
		ui.open()

/obj/machinery/atmospherics/components/binary/temperature_pump/ui_data()
	return list(
		"on" = on,
		"rate" = round(heat_transfer_rate),
		"max_heat_transfer_rate" = max_heat_transfer_rate,
		"ports" = ui_port_data(),
	)

/obj/machinery/atmospherics/components/binary/temperature_pump/ui_act(action, params)
	if(..())
		return
	atmos_wake()
	switch(action)
		if("power")
			on = !on
			. = TRUE
		if("rate")
			var/rate = params["rate"]
			if(rate == "max")
				rate = max_heat_transfer_rate
				. = TRUE
			else if(text2num(rate) != null)
				rate = text2num(rate)
				. = TRUE
			if(.)
				heat_transfer_rate = clamp(rate, 0, max_heat_transfer_rate)
	update_icon()

/obj/machinery/atmospherics/components/binary/temperature_pump/layer1
	piping_layer = 1
	icon_state = "tpump_map-1"

/obj/machinery/atmospherics/components/binary/temperature_pump/layer2
	piping_layer = 2
	icon_state = "tpump_map-2"

/obj/machinery/atmospherics/components/binary/temperature_pump/layer4
	piping_layer = 4
	icon_state = "tpump_map-4"

/obj/machinery/atmospherics/components/binary/temperature_pump/layer5
	piping_layer = 5
	icon_state = "tpump_map-5"

// Pre-enabled mapping variants: place a working heat pump without wiring a
// button or making engineering flip it every shift.
/obj/machinery/atmospherics/components/binary/temperature_pump/on
	on = TRUE
	icon_state = "tpump_on_map-3"

/obj/machinery/atmospherics/components/binary/temperature_pump/on/layer1
	piping_layer = 1
	icon_state = "tpump_on_map-1"

/obj/machinery/atmospherics/components/binary/temperature_pump/on/layer2
	piping_layer = 2
	icon_state = "tpump_on_map-2"

/obj/machinery/atmospherics/components/binary/temperature_pump/on/layer4
	piping_layer = 4
	icon_state = "tpump_on_map-4"

/obj/machinery/atmospherics/components/binary/temperature_pump/on/layer5
	piping_layer = 5
	icon_state = "tpump_on_map-5"

/// Passive one-way valve which opens above its configured input pressure.
/obj/machinery/atmospherics/components/binary/pressure_valve
	icon_state = "pvalve_map-3"
	name = "pressure valve"
	desc = "A passive one-way valve which opens when input pressure exceeds its threshold."
	can_unwrench = TRUE
	shift_underlay_only = FALSE
	construction_type = /obj/item/pipe/directional
	pipe_state = "pvalve"
	use_power = NO_POWER_USE
	var/target_pressure = ONE_ATMOSPHERE
	var/is_gas_flowing = FALSE

/obj/machinery/atmospherics/components/binary/pressure_valve/examine(mob/user)
	. = ..()
	. += "<span class='notice'>Ctrl-клик переключает клапан; Alt-клик выставляет порог давления на максимум.</span>"

/obj/machinery/atmospherics/components/binary/pressure_valve/CtrlClick(mob/user)
	if(can_interact(user))
		on = !on
		atmos_wake()
		update_icon()
	return ..()

/obj/machinery/atmospherics/components/binary/pressure_valve/AltClick(mob/user)
	if(can_interact(user))
		target_pressure = MAX_OUTPUT_PRESSURE
		atmos_wake()
		update_icon()
	return ..()

/obj/machinery/atmospherics/components/binary/pressure_valve/update_icon_nopipes()
	if(on && is_operational && is_gas_flowing)
		icon_state = "pvalve_flow-[SENSOR_VALVE_BODY_OFFSET]"
	else if(on && is_operational)
		icon_state = "pvalve_on-[SENSOR_VALVE_BODY_OFFSET]"
	else
		icon_state = "pvalve_off-[SENSOR_VALVE_BODY_OFFSET]"

/obj/machinery/atmospherics/components/binary/pressure_valve/process_atmos()
	if(atmos_idle_until > world.time)
		return
	if(!on || !is_operational)
		is_gas_flowing = FALSE
		atmos_consider_idle()
		return
	var/datum/gas_mixture/input_air = airs[1]
	var/datum/gas_mixture/output_air = airs[2]
	if(input_air.return_pressure() > target_pressure && release_gas_to(input_air, output_air, input_air.return_pressure()))
		update_parents()
		atmos_idle_streak = 0
		is_gas_flowing = TRUE
	else
		atmos_consider_idle()
		is_gas_flowing = FALSE
	update_icon_nopipes()

/obj/machinery/atmospherics/components/binary/pressure_valve/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "AtmosPump", name)
		ui.open()

/obj/machinery/atmospherics/components/binary/pressure_valve/ui_data()
	return list(
		"on" = on,
		"pressure" = round(target_pressure),
		"max_pressure" = round(MAX_OUTPUT_PRESSURE),
		"ports" = ui_port_data(),
	)

/obj/machinery/atmospherics/components/binary/pressure_valve/ui_act(action, params)
	if(..())
		return
	atmos_wake()
	switch(action)
		if("power")
			on = !on
			. = TRUE
		if("pressure")
			var/pressure = params["pressure"]
			if(pressure == "max")
				pressure = MAX_OUTPUT_PRESSURE
				. = TRUE
			else if(text2num(pressure) != null)
				pressure = text2num(pressure)
				. = TRUE
			if(.)
				target_pressure = clamp(pressure, 0, MAX_OUTPUT_PRESSURE)
	update_icon()

/obj/machinery/atmospherics/components/binary/pressure_valve/can_unwrench(mob/user)
	. = ..()
	if(. && on && is_operational)
		to_chat(user, "<span class='warning'>Сначала выключите [src]!</span>")
		return FALSE

/obj/machinery/atmospherics/components/binary/pressure_valve/layer1
	piping_layer = 1
	icon_state = "pvalve_map-1"

/obj/machinery/atmospherics/components/binary/pressure_valve/layer2
	piping_layer = 2
	icon_state = "pvalve_map-2"

/obj/machinery/atmospherics/components/binary/pressure_valve/layer4
	piping_layer = 4
	icon_state = "pvalve_map-4"

/obj/machinery/atmospherics/components/binary/pressure_valve/layer5
	piping_layer = 5
	icon_state = "pvalve_map-5"

// Pre-enabled mapping variants, mirroring tg's /on subtypes.
/obj/machinery/atmospherics/components/binary/pressure_valve/on
	on = TRUE
	icon_state = "pvalve_on_map-3"

/obj/machinery/atmospherics/components/binary/pressure_valve/on/layer1
	piping_layer = 1
	icon_state = "pvalve_on_map-1"

/obj/machinery/atmospherics/components/binary/pressure_valve/on/layer2
	piping_layer = 2
	icon_state = "pvalve_on_map-2"

/obj/machinery/atmospherics/components/binary/pressure_valve/on/layer4
	piping_layer = 4
	icon_state = "pvalve_on_map-4"

/obj/machinery/atmospherics/components/binary/pressure_valve/on/layer5
	piping_layer = 5
	icon_state = "pvalve_on_map-5"
