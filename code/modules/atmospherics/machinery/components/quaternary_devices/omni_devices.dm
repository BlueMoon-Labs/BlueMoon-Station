/// Four independent cardinal pipe ports. Port roles are software-configured;
/// changing a role does not rebuild any pipenet.
/obj/machinery/atmospherics/components/quaternary
	icon = 'icons/obj/atmospherics/components/omni_devices.dmi'
	icon_state = "base"
	initialize_directions = NORTH|SOUTH|EAST|WEST
	device_type = QUATERNARY
	density = FALSE
	use_power = IDLE_POWER_USE
	layer = GAS_FILTER_LAYER
	pipe_flags = PIPING_ONE_PER_TURF
	can_unwrench = TRUE
	construction_type = /obj/item/pipe/quaternary
	/// Overlay drawn at the device center ("filter"/"mixer"), plus "_glow" when
	/// powered. Port overlays follow the same rule: cyan collector arrows for
	/// filter roles, green for plain in/out, all dark while the device is off.
	var/center_glyph
	/// Port index -> role string; indices follow port_names/getNodeConnects order.
	var/list/port_roles
	var/static/list/port_names = list("North", "South", "East", "West")
	/// Same order as port_names: per-port overlay state prefixes in omni_devices.dmi.
	var/static/list/port_overlay_sides = list("north", "south", "east", "west")

/obj/machinery/atmospherics/components/quaternary/getNodeConnects()
	return list(NORTH, SOUTH, EAST, WEST)

/obj/machinery/atmospherics/components/quaternary/SetInitDirections()
	initialize_directions = NORTH|SOUTH|EAST|WEST

/// Composes the omni sprite: static base plate, center glyph, and one overlay
/// per configured port so input/output/filter roles are readable on the map.
/obj/machinery/atmospherics/components/quaternary/update_icon_nopipes()
	icon_state = "base"
	cut_overlays()
	// Destroy() drops the role config before the node-disconnect chain calls
	// back into update_icon; a dying device keeps its bare plate.
	if(!port_roles)
		return
	var/glow = (on && is_operational) ? "_glow" : ""
	var/list/overlay_states = list("[center_glyph][glow]")
	for(var/i in 1 to QUATERNARY)
		switch(port_roles[i])
			if("input")
				overlay_states += "[port_overlay_sides[i]]_in[glow]"
			if("output")
				overlay_states += "[port_overlay_sides[i]]_out[glow]"
			if("filter")
				overlay_states += "[port_overlay_sides[i]]_filter[glow]"
	add_overlay(overlay_states)

/obj/machinery/atmospherics/components/quaternary/can_unwrench(mob/user)
	. = ..()
	if(. && on && is_operational)
		to_chat(user, "<span class='warning'>Сначала выключите [src]!</span>")
		return FALSE

/// A four-port filter. Exactly one port is intake and one is clean output; each
/// remaining port may independently collect one gas or remain unused.
/obj/machinery/atmospherics/components/quaternary/omni_filter
	name = "omni gas filter"
	desc = "A four-port filter with a configurable role for every side."
	icon_state = "map_filter"
	center_glyph = "filter"
	pipe_state = "omni_filter"
	var/transfer_rate = MAX_TRANSFER_RATE
	var/list/filter_gases
	var/list/filter_gas_lists
	var/datum/gas_mixture/rejected_air

/obj/machinery/atmospherics/components/quaternary/omni_filter/New()
	port_roles = list("input", "output", "filter", "disabled")
	filter_gases = list(null, null, GAS_PLASMA, null)
	filter_gas_lists = list(null, null, list(GAS_PLASMA), null)
	rejected_air = new(200)
	return ..()

/obj/machinery/atmospherics/components/quaternary/omni_filter/Destroy()
	QDEL_NULL(rejected_air)
	port_roles = null
	filter_gases = null
	filter_gas_lists = null
	return ..()

/obj/machinery/atmospherics/components/quaternary/omni_filter/process_atmos()
	if(atmos_idle_until > world.time)
		return
	if(!on || !is_operational)
		atmos_consider_idle()
		return
	var/input_index = port_roles.Find("input")
	var/output_index = port_roles.Find("output")
	if(!input_index || !nodes[input_index])
		atmos_consider_idle()
		return
	var/datum/gas_mixture/input_air = airs[input_index]
	var/input_volume = input_air.return_volume()
	if(input_volume <= 0 || input_air.total_moles() <= 0)
		atmos_consider_idle()
		return
	var/datum/gas_mixture/removed = input_air.remove_ratio(min(1, transfer_rate / input_volume))
	if(!removed?.total_moles())
		atmos_consider_idle()
		return
	var/did_work = FALSE
	for(var/i in 1 to QUATERNARY)
		if(port_roles[i] != "filter" || !filter_gases[i] || !nodes[i])
			continue
		var/datum/gas_mixture/filter_air = airs[i]
		var/moles_before = removed.total_moles()
		if(filter_air.return_pressure() < MAX_OUTPUT_PRESSURE)
			removed.scrub_into(filter_air, 1, filter_gas_lists[i])
		else
			// Keep a blocked contaminant out of the clean output.
			removed.scrub_into(rejected_air, 1, filter_gas_lists[i])
		if(removed.total_moles() < moles_before)
			did_work = TRUE
	if(rejected_air.total_moles())
		input_air.merge(rejected_air)
		// merge() copies without draining the giver; an uncleared buffer would
		// re-add the same moles to the input every tick.
		rejected_air.clear()
	if(removed.total_moles())
		if(output_index && nodes[output_index] && airs[output_index].return_pressure() < MAX_OUTPUT_PRESSURE)
			airs[output_index].merge(removed)
			did_work = TRUE
		else
			input_air.merge(removed)
	if(did_work)
		use_power(200)
		update_parents()
		atmos_idle_streak = 0
	else
		atmos_consider_idle()

/obj/machinery/atmospherics/components/quaternary/omni_filter/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "AtmosOmni", name)
		ui.open()

/obj/machinery/atmospherics/components/quaternary/omni_filter/ui_static_data(mob/user)
	// The gas registry is immutable after init; one serialization per client
	// open instead of one list rebuild per SStgui tick.
	var/list/data = list("filter_types" = list())
	for(var/gas_id in GLOB.gas_data.ids)
		data["filter_types"] += list(list("id" = gas_id, "name" = GLOB.gas_data.names[gas_id]))
	return data

/obj/machinery/atmospherics/components/quaternary/omni_filter/ui_data()
	var/list/data = list(
		"kind" = "filter",
		"on" = on,
		"setting" = round(transfer_rate),
		"setting_max" = round(MAX_TRANSFER_RATE),
		"setting_label" = "Скорость переноса",
		"setting_unit" = "л/с",
		"ports" = list(),
	)
	for(var/i in 1 to QUATERNARY)
		var/datum/gas_mixture/port_air = airs[i]
		data["ports"] += list(list(
			"index" = i,
			"name" = port_names[i],
			"role" = port_roles[i],
			"gas" = filter_gases[i],
			"connected" = !isnull(nodes[i]),
			"pressure" = port_air ? round(port_air.return_pressure(), 0.01) : 0,
			"temperature" = port_air ? round(port_air.return_temperature(), 0.01) : 0,
		))
	return data

/obj/machinery/atmospherics/components/quaternary/omni_filter/ui_act(action, params)
	if(..())
		return
	var/index = clamp(text2num(params["index"]), 1, QUATERNARY)
	switch(action)
		if("power")
			on = !on
			. = TRUE
		if("setting")
			var/new_rate = params["value"] == "max" ? MAX_TRANSFER_RATE : text2num(params["value"])
			if(!isnull(new_rate))
				transfer_rate = clamp(new_rate, 0, MAX_TRANSFER_RATE)
				. = TRUE
		if("role")
			var/new_role = params["role"]
			if(new_role == "input" || new_role == "output")
				var/old_index = port_roles.Find(new_role)
				var/old_role = port_roles[index]
				port_roles[index] = new_role
				port_roles[old_index] = old_role
				. = TRUE
			else if((new_role == "filter" || new_role == "disabled") && port_roles[index] != "input" && port_roles[index] != "output")
				port_roles[index] = new_role
				. = TRUE
		if("gas")
			var/gas_id = params["gas"]
			if(port_roles[index] == "filter" && GLOB.gas_data.names[gas_id])
				filter_gases[index] = gas_id
				filter_gas_lists[index] = list(gas_id)
				. = TRUE
	if(.)
		atmos_wake()
		update_icon()

/// A four-port mixer. One side is the output; every other side may be an input
/// with an adjustable fraction or may be disabled.
/obj/machinery/atmospherics/components/quaternary/omni_mixer
	name = "omni gas mixer"
	desc = "A four-port mixer with configurable inputs, output, and blend ratios."
	icon_state = "map_mixer"
	center_glyph = "mixer"
	pipe_state = "omni_mixer"
	var/target_pressure = ONE_ATMOSPHERE
	var/list/concentrations

/obj/machinery/atmospherics/components/quaternary/omni_mixer/New()
	port_roles = list("input", "input", "input", "output")
	concentrations = list(1 / 3, 1 / 3, 1 / 3, 0)
	. = ..()
	airs[4].set_volume(300)

/obj/machinery/atmospherics/components/quaternary/omni_mixer/Destroy()
	port_roles = null
	concentrations = null
	return ..()

/obj/machinery/atmospherics/components/quaternary/omni_mixer/proc/normalize_inputs(preferred_index = 0, preferred_value = null)
	var/list/input_indices = list()
	for(var/i in 1 to QUATERNARY)
		if(port_roles[i] == "input")
			input_indices += i
	if(!length(input_indices))
		return
	// The parentheses are load-bearing: "in" binds looser than "&&".
	if((preferred_index in input_indices) && !isnull(preferred_value) && length(input_indices) > 1)
		var/clamped_value = clamp(preferred_value, 0, 1)
		var/remainder = (1 - clamped_value) / (length(input_indices) - 1)
		for(var/i in input_indices)
			concentrations[i] = i == preferred_index ? clamped_value : remainder
	else
		var/even_share = 1 / length(input_indices)
		for(var/i in input_indices)
			concentrations[i] = even_share
	for(var/i in 1 to QUATERNARY)
		if(port_roles[i] != "input")
			concentrations[i] = 0

/obj/machinery/atmospherics/components/quaternary/omni_mixer/proc/input_count()
	. = 0
	for(var/i in 1 to QUATERNARY)
		if(port_roles[i] == "input")
			.++

/obj/machinery/atmospherics/components/quaternary/omni_mixer/process_atmos()
	if(atmos_idle_until > world.time)
		return
	if(!on || !is_operational)
		atmos_consider_idle()
		return
	var/output_index = port_roles.Find("output")
	if(!output_index || !nodes[output_index])
		atmos_consider_idle()
		return
	var/datum/gas_mixture/output_air = airs[output_index]
	var/output_pressure = output_air.return_pressure()
	if(output_pressure >= target_pressure)
		atmos_consider_idle()
		return
	var/combined_heat_capacity = 0
	var/combined_energy = 0
	var/active_ratio = 0
	for(var/i in 1 to QUATERNARY)
		if(port_roles[i] != "input" || !nodes[i] || concentrations[i] <= 0)
			continue
		var/datum/gas_mixture/input_air = airs[i]
		combined_heat_capacity += input_air.heat_capacity()
		combined_energy += input_air.thermal_energy()
		active_ratio += concentrations[i]
	if(combined_heat_capacity <= 0 || active_ratio <= 0)
		atmos_consider_idle()
		return
	var/equalized_temperature = combined_energy / combined_heat_capacity
	if(equalized_temperature <= 0)
		atmos_consider_idle()
		return
	var/desired_total = (target_pressure - output_pressure) * output_air.return_volume() / (R_IDEAL_GAS_EQUATION * equalized_temperature)
	var/scale = 1
	for(var/i in 1 to QUATERNARY)
		if(port_roles[i] != "input" || !nodes[i] || concentrations[i] <= 0)
			continue
		var/desired = desired_total * concentrations[i] / active_ratio
		if(desired > 0)
			scale = min(scale, airs[i].total_moles() / desired)
	if(scale <= 0)
		atmos_consider_idle()
		return
	for(var/i in 1 to QUATERNARY)
		if(port_roles[i] == "input" && nodes[i] && concentrations[i] > 0)
			airs[i].transfer_to(output_air, desired_total * concentrations[i] / active_ratio * scale)
	use_power(200)
	update_parents()
	atmos_idle_streak = 0

/obj/machinery/atmospherics/components/quaternary/omni_mixer/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "AtmosOmni", name)
		ui.open()

/obj/machinery/atmospherics/components/quaternary/omni_mixer/ui_data()
	var/list/data = list(
		"kind" = "mixer",
		"on" = on,
		"setting" = round(target_pressure),
		"setting_max" = round(MAX_OUTPUT_PRESSURE),
		"setting_label" = "Давление на выходе",
		"setting_unit" = "кПа",
		"ports" = list(),
	)
	for(var/i in 1 to QUATERNARY)
		var/datum/gas_mixture/port_air = airs[i]
		data["ports"] += list(list(
			"index" = i,
			"name" = port_names[i],
			"role" = port_roles[i],
			"concentration" = round(concentrations[i] * 100, 0.1),
			"connected" = !isnull(nodes[i]),
			"pressure" = port_air ? round(port_air.return_pressure(), 0.01) : 0,
			"temperature" = port_air ? round(port_air.return_temperature(), 0.01) : 0,
		))
	return data

/obj/machinery/atmospherics/components/quaternary/omni_mixer/ui_act(action, params)
	if(..())
		return
	var/index = clamp(text2num(params["index"]), 1, QUATERNARY)
	switch(action)
		if("power")
			on = !on
			. = TRUE
		if("setting")
			var/new_pressure = params["value"] == "max" ? MAX_OUTPUT_PRESSURE : text2num(params["value"])
			if(!isnull(new_pressure))
				target_pressure = clamp(new_pressure, 0, MAX_OUTPUT_PRESSURE)
				. = TRUE
		if("role")
			var/new_role = params["role"]
			if(new_role == "output")
				var/old_output = port_roles.Find("output")
				var/old_role = port_roles[index]
				port_roles[index] = "output"
				port_roles[old_output] = old_role
				normalize_inputs()
				. = TRUE
			else if(new_role == "input" && port_roles[index] != "output")
				port_roles[index] = "input"
				normalize_inputs()
				. = TRUE
			else if(new_role == "disabled" && port_roles[index] == "input" && input_count() > 1)
				port_roles[index] = "disabled"
				normalize_inputs()
				. = TRUE
		if("concentration")
			if(port_roles[index] == "input")
				normalize_inputs(index, text2num(params["value"]) / 100)
				. = TRUE
	if(.)
		atmos_wake()
		update_icon()
