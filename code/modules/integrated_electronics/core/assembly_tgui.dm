/// TGUI "IntegratedCircuit" backend for legacy Integrated Electronics (assemblies + loose chips).

GLOBAL_LIST_INIT(ie_integrated_circuit_ui_types, list("string", "number", "boolean", "char", "color", "dir", "index", "list", "entity", "signal", "any", "option"))

/proc/ie_ic_tgui_write_input(datum/integrated_io/io, ftype, new_val)
	if(!io)
		return
	switch(ftype)
		if("list", "signal")
			return
		if("number", "index")
			io.write_data_to_pin(text2num(new_val))
		if("boolean")
			if(new_val == TRUE || new_val == 1)
				io.write_data_to_pin(TRUE)
			else if(new_val == FALSE || new_val == 0)
				io.write_data_to_pin(FALSE)
			else if(istext(new_val))
				var/nt = lowertext(new_val)
				io.write_data_to_pin(nt == "true" || nt == "1" || nt == "yes")
			else
				io.write_data_to_pin(FALSE)
		if("dir")
			io.write_data_to_pin(text2num(new_val))
		if("char")
			var/t = istext(new_val) ? new_val : "[new_val]"
			if(length_char(t) > 1)
				t = copytext_char(t, 1, 2)
			io.write_data_to_pin(t)
		if("color", "string")
			io.write_data_to_pin(new_val)
		if("any")
			io.write_data_to_pin(new_val)
		else
			io.write_data_to_pin(new_val)

/// Prefer active hand: tool there → use as ref; else debugger in either hand.
/proc/ie_ic_get_debugger_from_hands(mob/M)
	if(!M)
		return null
	var/obj/item/active = M.get_active_held_item()
	if(istype(active, /obj/item/integrated_electronics/debugger))
		return active
	if(isliving(M))
		var/mob/living/living_user = M
		var/obj/item/inactive = living_user.get_inactive_held_item()
		if(istype(inactive, /obj/item/integrated_electronics/debugger))
			return inactive
	return null

/// TGUI upload: debugger (copy from pin / paste memory), held item ref, or varedit mark. Works for all data-channel pin types.
/proc/ie_ic_tgui_apply_marked_atom_or_debugger(mob/M, datum/integrated_io/io)
	if(!M || !io)
		return
	if(io.io_type != DATA_CHANNEL)
		to_chat(M, span_warning("Отладчик (upload) работает только с данными, не с импульсными пинами."))
		return
	var/ftype_mark = ie_ic_fundamental_type(io)
	var/atom/movable/held = M.get_active_held_item()
	var/obj/item/integrated_electronics/debugger/D = ie_ic_get_debugger_from_hands(M)

	// Prefer debugger in hands over "held item" when both could apply
	if(D)
		if(D.copy_values)
			D.data_to_write = io.data
			D.copy_values = FALSE
			to_chat(M, span_notice("Debugger copied the pin's current value into memory. Use upload on another pin to paste, or set string/number/ref on the debugger."))
			return
		if(D.accepting_refs)
			to_chat(M, span_warning("Finish ref scan on the debugger first (click a target in the world), or switch mode."))
			return
		// Вставка памяти — только во входы; с выходов можно только скопировать (режим Copy выше).
		if(ie_ic_is_output_side_pin(io))
			to_chat(M, span_warning("Вставьте память отладчика во вход (слева). С выхода значение можно только скопировать (режим Copy на кнопке upload)."))
			return
		switch(ftype_mark)
			if("entity")
				if(isnull(D.data_to_write) || isweakref(D.data_to_write))
					io.write_data_to_pin(D.data_to_write)
				else
					to_chat(M, span_warning("The debugger memory is not a reference. Use ref or null on the debugger, then upload again."))
			if("number", "index", "dir")
				if(isnull(D.data_to_write))
					io.write_data_to_pin(null)
				else if(isnum(D.data_to_write))
					io.write_data_to_pin(D.data_to_write)
				else if(istext(D.data_to_write))
					io.write_data_to_pin(text2num(D.data_to_write))
				else
					to_chat(M, span_warning("Debugger memory must be a number or null for this pin."))
			if("boolean")
				if(isnull(D.data_to_write))
					io.write_data_to_pin(null)
				else if(D.data_to_write == TRUE || D.data_to_write == FALSE)
					io.write_data_to_pin(D.data_to_write)
				else if(isnum(D.data_to_write))
					io.write_data_to_pin(!!D.data_to_write)
				else if(istext(D.data_to_write))
					var/nt = lowertext(D.data_to_write)
					io.write_data_to_pin(nt == "true" || nt == "1" || nt == "yes")
				else
					to_chat(M, span_warning("Debugger memory must be boolean-like or null."))
			if("char", "string", "color")
				if(isnull(D.data_to_write) || istext(D.data_to_write))
					io.write_data_to_pin(D.data_to_write)
				else
					to_chat(M, span_warning("Debugger memory must be text or null for this pin."))
			if("list")
				if(isnull(D.data_to_write) || islist(D.data_to_write))
					io.write_data_to_pin(D.data_to_write)
				else
					to_chat(M, span_warning("Debugger memory must be a list or null."))
			if("any")
				io.write_data_to_pin(D.data_to_write)
			else
				io.write_data_to_pin(D.data_to_write)
		return

	if(istype(held) && !istype(held, /obj/item/integrated_electronics/debugger))
		if(ftype_mark == "entity" || ftype_mark == "any")
			io.write_data_to_pin(WEAKREF(held))
		else
			to_chat(M, span_warning("Put a circuit debugger in hand to paste memory, or use this only on ref/any pins with an item in active hand."))
		return

	var/client/C = M.client
	if((ftype_mark == "entity" || ftype_mark == "any") && C?.holder?.marked_datum)
		io.write_data_to_pin(WEAKREF(C.holder.marked_datum))

/proc/ie_ic_is_output_side_pin(datum/integrated_io/io)
	if(!io)
		return FALSE
	if(io.pin_type == IC_OUTPUT)
		return TRUE
	if(istype(io, /datum/integrated_io/activate/out))
		return TRUE
	return FALSE

/proc/ie_ic_fundamental_type(datum/integrated_io/io)
	if(!io)
		return "any"
	if(io.io_type == PULSE_CHANNEL)
		return "signal"
	if(istype(io, /datum/integrated_io/boolean))
		return "boolean"
	if(istype(io, /datum/integrated_io/number))
		return "number"
	if(istype(io, /datum/integrated_io/index))
		return "index"
	if(istype(io, /datum/integrated_io/char))
		return "char"
	if(istype(io, /datum/integrated_io/color))
		return "color"
	if(istype(io, /datum/integrated_io/dir))
		return "dir"
	if(istype(io, /datum/integrated_io/string))
		return "string"
	if(istype(io, /datum/integrated_io/lists))
		return "list"
	if(istype(io, /datum/integrated_io/ref) || istype(io, /datum/integrated_io/selfref))
		return "entity"
	return "any"

/// Цвет точки порта в TGUI (имена из `CSS_COLORS`); по возможности как у wiremod.
/proc/ie_ic_tgui_port_color(ftype)
	switch(ftype)
		if("signal")
			return "teal"
		if("boolean")
			return "yellow"
		if("number")
			return "green"
		if("index")
			return "violet"
		if("char")
			return "brown"
		if("color")
			return "pink"
		if("dir")
			return "olive"
		if("string")
			return "orange"
		if("list")
			return "white"
		if("entity")
			return "purple"
		if("option")
			return "average"
		else
			return "blue"

/proc/ie_ic_ui_examine_title(obj/item/integrated_circuit/C)
	if(!C)
		return null
	var/nn = C.displayed_name
	if(!istext(nn) || !length_char(nn))
		nn = C.name
	if(!istext(nn))
		nn = "circuit"
	return nn

/proc/ie_ic_ui_examine_desc(obj/item/integrated_circuit/C)
	if(!C)
		return null
	var/dd = C.desc
	var/ed = C.extended_desc
	if(!istext(dd))
		dd = ""
	if(!istext(ed))
		ed = ""
	return "[dd]\n[ed]"

/proc/ie_ic_ui_examine_notices(obj/item/integrated_circuit/C)
	var/list/out = list()
	if(!C)
		return out
	var/cx = isnum(C.complexity) ? C.complexity : 0
	var/sz = isnum(C.size) ? C.size : 0
	var/cd = isnum(C.cooldown_per_use) ? C.cooldown_per_use : 0
	var/ed = isnum(C.ext_cooldown) ? C.ext_cooldown : 0
	var/ext_txt = ed > 0 ? "[ed / 10] с" : "нет"
	out += list(list(
		"content" = "Размер: [sz] | Сложность: [cx] | КД: [cd / 10] с | Внеш. КД: [ext_txt]",
		"color" = "transparent",
		"icon" = "info",
	))
	return out

/proc/ie_ic_serialize_data(datum/integrated_io/io)
	var/data = io.data
	if(isnull(data))
		return null
	if(isweakref(data))
		var/datum/weakref/wr = data
		var/atom/A = wr.resolve()
		return A ? A.name : null
	if(islist(data))
		return "list([length(data)])"
	if(isnum(data) || istext(data))
		return data
	return "[data]"

/// JSON-friendly value for TGUI (nested lists, refs as names). Does not mutate pin data.
/proc/ie_ic_tgui_pack_pin_value(data, depth = 0)
	if(depth > 10)
		return "…"
	if(isnull(data))
		return null
	if(isweakref(data))
		var/datum/weakref/wr = data
		var/atom/A = wr.resolve()
		return A ? A.name : null
	if(islist(data))
		var/list/L = data
		var/list/out = list()
		var/maxn = min(L.len, 400)
		for(var/i = 1 to maxn)
			out.Add(ie_ic_tgui_pack_pin_value(L[i], depth + 1))
		if(L.len > maxn)
			out.Add("([L.len - maxn] more)")
		return out
	if(isnum(data) || istext(data))
		return data
	return "[data]"

/proc/ie_ic_collect_input_ios(obj/item/integrated_circuit/chip)
	var/list/L = list()
	for(var/datum/integrated_io/io as anything in chip.inputs)
		L += io
	for(var/datum/integrated_io/io as anything in chip.activators)
		if(!istype(io, /datum/integrated_io/activate/out))
			L += io
	return L

/proc/ie_ic_collect_output_ios(obj/item/integrated_circuit/chip)
	var/list/L = list()
	for(var/datum/integrated_io/io as anything in chip.outputs)
		L += io
	for(var/datum/integrated_io/io as anything in chip.activators)
		if(istype(io, /datum/integrated_io/activate/out))
			L += io
	return L

/proc/ie_ic_input_connected_refs(datum/integrated_io/io)
	var/list/out = list()
	for(var/datum/integrated_io/other as anything in io.linked)
		if(ie_ic_is_output_side_pin(other))
			out += REF(other)
	return out

/// Входы, подключённые к этому выходу (порядок = порядок линий на схеме).
/proc/ie_ic_output_connected_input_refs(datum/integrated_io/io)
	var/list/out = list()
	for(var/datum/integrated_io/other as anything in io.linked)
		if(!ie_ic_is_output_side_pin(other))
			out += REF(other)
	return out

/proc/ie_ic_build_port_entry(datum/integrated_io/io)
	var/ftype = ie_ic_fundamental_type(io)
	return list(
		"name" = io.name,
		"type" = ftype,
		/// Same human labels as old HTML (\<TEXT\>, \<LIST\>, …); TGUI still uses `type` for widgets.
		"pin_type_label" = io.display_pin_type(),
		"ref" = REF(io),
		"color" = ie_ic_tgui_port_color(ftype),
		"current_data" = ie_ic_tgui_pack_pin_value(io.data),
		"datatype_data" = null,
		"connected_to" = ie_ic_input_connected_refs(io),
	)

/proc/ie_ic_component_payload(obj/item/integrated_circuit/chip)
	var/list/component_data = list()
	var/chip_accent = ic_tgui_ie_chip_accent_hex(chip)
	/// Append with `+= list(entry)` so json_encode emits JSON arrays (numeric `[i]=` can become objects on the wire).
	var/list/input_ports = list()
	for(var/datum/integrated_io/io as anything in ie_ic_collect_input_ios(chip))
		input_ports += list(ie_ic_build_port_entry(io))
	component_data["input_ports"] = input_ports
	var/list/output_ports = list()
	for(var/datum/integrated_io/io as anything in ie_ic_collect_output_ios(chip))
		var/list/out_entry = ie_ic_build_port_entry(io)
		out_entry["connected_to"] = ie_ic_output_connected_input_refs(io)
		output_ports += list(out_entry)
	component_data["output_ports"] = output_ports
	component_data["color"] = chip_accent
	component_data["name"] = chip.displayed_name || chip.name
	component_data["x"] = chip.ie_ui_rel_x
	component_data["y"] = chip.ie_ui_rel_y
	component_data["removable"] = chip.removable
	var/pulsing = FALSE
	var/obj/item/electronic_assembly/ea = chip.assembly
	if(ea)
		if(world.time < ea.ie_tgui_pulse_until && ea.ie_tgui_pulse_chip_weak?.resolve() == chip)
			pulsing = TRUE
	else if(world.time < chip.ie_tgui_solo_pulse_until)
		pulsing = TRUE
	component_data["recent_pulse"] = pulsing
	component_data["ie_size"] = chip.size
	component_data["ie_complexity"] = chip.complexity
	component_data["ie_cooldown_ds"] = chip.cooldown_per_use
	component_data["ie_ext_cooldown_ds"] = chip.ext_cooldown
	return component_data

/proc/ie_ic_get_input_io(obj/item/integrated_circuit/chip, port_id)
	var/list/L = ie_ic_collect_input_ios(chip)
	if(port_id < 1 || port_id > length(L))
		return null
	return L[port_id]

/proc/ie_ic_get_output_io(obj/item/integrated_circuit/chip, port_id)
	var/list/L = ie_ic_collect_output_ios(chip)
	if(port_id < 1 || port_id > length(L))
		return null
	return L[port_id]

/obj/item/electronic_assembly/proc/ie_tgui_register_data_pulse(datum/integrated_io/out_io, datum/integrated_io/in_io)
	if(!out_io || !in_io)
		return
	ie_tgui_pulse_until = world.time + 0.35 SECONDS
	ie_tgui_pulse_output_ref = REF(out_io)
	ie_tgui_pulse_input_ref = REF(in_io)
	ie_tgui_pulse_chip_weak = WEAKREF(in_io.holder)
	SStgui.update_uis(src)

/obj/item/integrated_circuit/proc/ie_tgui_register_solo_data_pulse(datum/integrated_io/out_io, datum/integrated_io/in_io)
	if(!out_io || !in_io)
		return
	ie_tgui_solo_pulse_until = world.time + 0.35 SECONDS
	ie_tgui_solo_pulse_out_ref = REF(out_io)
	ie_tgui_solo_pulse_in_ref = REF(in_io)
	SStgui.update_uis(src)

/proc/ie_ic_chip_from_index(atom/movable/host, component_id)
	if(istype(host, /obj/item/electronic_assembly))
		var/obj/item/electronic_assembly/ea = host
		if(component_id < 1 || component_id > length(ea.assembly_components))
			return null
		return ea.assembly_components[component_id]
	if(istype(host, /obj/item/integrated_circuit))
		if(component_id != 1)
			return null
		return host
	return null

/proc/ie_ic_shared_host(atom/movable/A, atom/movable/B)
	var/obj/item/electronic_assembly/ea = A?.loc
	if(istype(ea, /obj/item/electronic_assembly) && (B?.loc == ea))
		return ea
	return null

/obj/item/electronic_assembly/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/simple/circuit_assets)
	)

/obj/item/electronic_assembly/ui_state(mob/user)
	/// Было hands_state: окно требовало держать сборку в руках; на полу статус становился UI_CLOSE и TGUI не обновлялся / закрывался.
	return GLOB.default_state

/obj/item/electronic_assembly/ui_interact(mob/user, obj/item/integrated_circuit/circuit_pins)
	. = ..()
	if(!check_interactivity(user))
		return
	var/datum/tgui/ui = SStgui.try_update_ui(user, src, null)
	if(!ui)
		ui = new(user, src, "IntegratedCircuit", name)
		ui.open()
	ui.set_autoupdate(TRUE)

/obj/item/electronic_assembly/ui_static_data(mob/user)
	. = list()
	.["global_basic_types"] = GLOB.ie_integrated_circuit_ui_types
	.["screen_x"] = ie_tgui_screen_x
	.["screen_y"] = ie_tgui_screen_y

/obj/item/electronic_assembly/ui_data(mob/user)
	. = list()
	.["ie_circuit"] = TRUE
	/// "assembly" = копировать JSON всей сборки для принтера; см. `ie_copy_assembly_code`.
	.["ie_clone_copy_mode"] = "assembly"
	.["ie_debug_copy_ref"] = user.client && check_rights_for(user.client, R_DEBUG)
	.["ie_used_size"] = return_total_size()
	.["ie_max_size"] = max_components
	.["ie_used_complexity"] = return_total_complexity()
	.["ie_max_complexity"] = max_complexity
	.["circuit_on"] = TRUE
	.["is_admin"] = FALSE
	.["variables"] = list()
	.["display_name"] = name
	.["components"] = list()
	for(var/obj/item/integrated_circuit/part as anything in assembly_components)
		.["components"] += list(ie_ic_component_payload(part))
	.["screen_x"] = ie_tgui_screen_x
	.["screen_y"] = ie_tgui_screen_y
	.["ie_battery_percent"] = null
	if(battery)
		.["ie_battery_percent"] = round(100 * battery.charge / max(battery.maxcharge, 1), 0.1)
	var/obj/item/integrated_circuit/examined = ie_gui_examined_circuit?.resolve()
	if(examined && !(examined in assembly_components))
		examined = null
	.["examined_name"] = examined ? ie_ic_ui_examine_title(examined) : null
	.["examined_desc"] = examined ? ie_ic_ui_examine_desc(examined) : null
	.["examined_notices"] = examined ? ie_ic_ui_examine_notices(examined) : list()
	.["examined_rel_x"] = ie_gui_examined_x
	.["examined_rel_y"] = ie_gui_examined_y
	var/pulse_live = world.time < ie_tgui_pulse_until
	.["circuit_pulse_out_ref"] = pulse_live ? ie_tgui_pulse_output_ref : null
	.["circuit_pulse_in_ref"] = pulse_live ? ie_tgui_pulse_input_ref : null

/obj/item/electronic_assembly/ui_act(action, list/params)
	. = ..()
	if(.)
		return
	switch(action)
		if("ie_switch_classic_ui")
			if(!usr?.client?.prefs)
				return
			usr.client.prefs.ie_classic_circuit_ui = TRUE
			SStgui.close_uis(src)
			ie_legacy_ui_interact(usr, null)
			. = TRUE
		if("ie_eject_battery")
			if(!battery || !usr)
				return
			playsound(src, 'sound/items/Crowbar.ogg', 50, TRUE)
			if(!usr.put_in_hands(battery))
				battery.forceMove(drop_location())
			battery = null
			diag_hud_set_circuitstat()
			. = TRUE
		if("ie_place_hand_chip_at")
			var/rx = text2num(params["rel_x"])
			var/ry = text2num(params["rel_y"])
			if(!isnum(rx) || !isnum(ry) || !usr)
				return
			var/obj/item/integrated_circuit/chip = usr.get_active_held_item()
			if(!istype(chip))
				chip = usr.get_inactive_held_item()
			if(!istype(chip))
				return
			if(chip.assembly)
				return
			if(!try_add_component(chip, usr))
				return
			chip.ie_ui_rel_x = clamp(rx, -IE_TGUI_COMPONENT_COORD_LIMIT, IE_TGUI_COMPONENT_COORD_LIMIT)
			chip.ie_ui_rel_y = clamp(ry, -IE_TGUI_COMPONENT_COORD_LIMIT, IE_TGUI_COMPONENT_COORD_LIMIT)
			. = TRUE
		if("set_component_display_name")
			var/cid = text2num(params["component_id"])
			var/nn = params["display_name"]
			if(isnull(nn))
				return TRUE
			var/obj/item/integrated_circuit/chip = ie_ic_chip_from_index(src, cid)
			if(!chip || !(chip in assembly_components))
				return
			chip.displayed_name = reject_bad_name(strip_html(nn), TRUE) || chip.displayed_name
			add_allowed_scanner(usr.ckey)
			. = TRUE
		if("add_connection")
			var/ocid = text2num(params["output_component_id"])
			var/icid = text2num(params["input_component_id"])
			var/opid = text2num(params["output_port_id"])
			var/ipid = text2num(params["input_port_id"])
			var/obj/item/integrated_circuit/out_chip = ie_ic_chip_from_index(src, ocid)
			var/obj/item/integrated_circuit/in_chip = ie_ic_chip_from_index(src, icid)
			if(!out_chip || !in_chip)
				return
			var/datum/integrated_io/out_io = ie_ic_get_output_io(out_chip, opid)
			var/datum/integrated_io/in_io = ie_ic_get_input_io(in_chip, ipid)
			if(!out_io || !in_io)
				return
			if(out_io.io_type != in_io.io_type)
				return
			if(ie_ic_shared_host(out_chip, in_chip) != src)
				return
			out_io.connect_pin(in_io)
			. = TRUE
		if("remove_connection")
			var/cid = text2num(params["component_id"])
			var/port_id = text2num(params["port_id"])
			var/is_input = params["is_input"]
			var/obj/item/integrated_circuit/chip = ie_ic_chip_from_index(src, cid)
			if(!chip)
				return
			var/datum/integrated_io/io = is_input ? ie_ic_get_input_io(chip, port_id) : ie_ic_get_output_io(chip, port_id)
			if(!io)
				return
			io.disconnect_all()
			. = TRUE
		if("detach_component")
			var/cid = text2num(params["component_id"])
			var/obj/item/integrated_circuit/chip = ie_ic_chip_from_index(src, cid)
			if(!chip || !usr)
				return
			if(try_remove_component(chip, usr))
				. = TRUE
		if("set_component_coordinates")
			var/cid = text2num(params["component_id"])
			var/obj/item/integrated_circuit/chip = ie_ic_chip_from_index(src, cid)
			if(!chip)
				return
			chip.ie_ui_rel_x = clamp(text2num(params["rel_x"]), -IE_TGUI_COMPONENT_COORD_LIMIT, IE_TGUI_COMPONENT_COORD_LIMIT)
			chip.ie_ui_rel_y = clamp(text2num(params["rel_y"]), -IE_TGUI_COMPONENT_COORD_LIMIT, IE_TGUI_COMPONENT_COORD_LIMIT)
			. = TRUE
		if("set_component_input")
			var/cid = text2num(params["component_id"])
			var/pid = text2num(params["port_id"])
			var/obj/item/integrated_circuit/chip = ie_ic_chip_from_index(src, cid)
			if(!chip || !usr)
				return
			var/is_out = params["is_output"]
			var/datum/integrated_io/io = is_out ? ie_ic_get_output_io(chip, pid) : ie_ic_get_input_io(chip, pid)
			if(!io)
				return
			if(io.io_type == PULSE_CHANNEL)
				if(istype(io, /datum/integrated_io/activate/out))
					return TRUE
				chip.check_then_do_work(io.ord, ignore_power = TRUE)
				return TRUE
			if(params["set_null"])
				io.write_data_to_pin(null)
				return TRUE
			if(params["marked_atom"])
				ie_ic_tgui_apply_marked_atom_or_debugger(usr, io)
				return TRUE
			var/ftype = ie_ic_fundamental_type(io)
			ie_ic_tgui_write_input(io, ftype, params["input"])
			return TRUE
		if("ie_open_list_editor")
			var/cid = text2num(params["component_id"])
			var/pid = text2num(params["port_id"])
			var/obj/item/integrated_circuit/chip = ie_ic_chip_from_index(src, cid)
			if(!chip || !usr)
				return
			var/is_out = params["is_output"] ? TRUE : FALSE
			var/datum/integrated_io/io = is_out ? ie_ic_get_output_io(chip, pid) : ie_ic_get_input_io(chip, pid)
			if(istype(io, /datum/integrated_io/lists))
				var/datum/integrated_io/lists/L = io
				L.interact(usr)
				. = TRUE
		if("ie_open_data_inspector")
			var/cid = text2num(params["component_id"])
			var/pid = text2num(params["port_id"])
			var/obj/item/integrated_circuit/chip = ie_ic_chip_from_index(src, cid)
			if(!chip || !usr)
				return
			var/is_out = params["is_output"] ? TRUE : FALSE
			var/datum/integrated_io/io = is_out ? ie_ic_get_output_io(chip, pid) : ie_ic_get_input_io(chip, pid)
			if(!io)
				return
			var/datum/browser/popup = new(usr, "ie_pin_data_[REF(io)]", "[chip.displayed_name || chip.name]: [io.name]", 640, 520)
			popup.set_content("<div style='font-size:12px;word-break:break-word;'>[io.display_data(io.data)]</div>")
			popup.open()
			. = TRUE
		if("get_component_value")
			var/cid = text2num(params["component_id"])
			var/pid = text2num(params["port_id"])
			var/obj/item/integrated_circuit/chip = ie_ic_chip_from_index(src, cid)
			if(!chip || !usr)
				return
			var/datum/integrated_io/io = ie_ic_get_output_io(chip, pid)
			if(!io)
				return
			var/msg = copytext("[ie_ic_serialize_data(io)]", 1, 80)
			usr.balloon_alert(usr, "[io.name]: [msg]")
			. = TRUE
		if("set_display_name")
			var/nn = params["display_name"]
			if(isnull(nn))
				return TRUE
			name = reject_bad_name(strip_html(nn), TRUE) || initial(name)
			. = TRUE
		if("set_examined_component")
			var/cid = text2num(params["component_id"])
			var/obj/item/integrated_circuit/chip = ie_ic_chip_from_index(src, cid)
			if(!chip || !(chip in assembly_components))
				return
			ie_gui_examined_circuit = WEAKREF(chip)
			var/px = text2num(params["x"])
			var/py = text2num(params["y"])
			if(!isnum(px))
				px = 0
			if(!isnum(py))
				py = 0
			ie_gui_examined_x = clamp(px, 0, 4000)
			ie_gui_examined_y = clamp(py, 0, 4000)
			. = TRUE
		if("remove_examined_component")
			ie_gui_examined_circuit = null
			. = TRUE
		if("move_screen")
			ie_tgui_screen_x = text2num(params["screen_x"])
			ie_tgui_screen_y = text2num(params["screen_y"])
			. = TRUE
		if("swap_input_connection_order")
			var/cid = text2num(params["component_id"])
			var/pid = text2num(params["port_id"])
			var/lower = text2num(params["lower_index"])
			var/obj/item/integrated_circuit/chip = ie_ic_chip_from_index(src, cid)
			if(!chip)
				return
			var/datum/integrated_io/io = ie_ic_get_input_io(chip, pid)
			if(!io || length(io.linked) < lower + 1 || lower < 1)
				return
			io.linked.Swap(lower, lower + 1)
			. = TRUE
		if("swap_output_connection_order")
			var/cid = text2num(params["component_id"])
			var/pid = text2num(params["port_id"])
			var/lower = text2num(params["lower_index"])
			var/obj/item/integrated_circuit/chip = ie_ic_chip_from_index(src, cid)
			if(!chip)
				return
			var/datum/integrated_io/io = ie_ic_get_output_io(chip, pid)
			if(!io || !ie_ic_is_output_side_pin(io) || length(io.linked) < lower + 1 || lower < 1)
				return
			var/datum/integrated_io/a = io.linked[lower]
			var/datum/integrated_io/b = io.linked[lower + 1]
			if(ie_ic_is_output_side_pin(a) || ie_ic_is_output_side_pin(b))
				return
			io.linked.Swap(lower, lower + 1)
			. = TRUE
		if("ie_copy_assembly_code")
			if(!usr)
				return
			var/json = SScircuit.save_electronic_assembly(src)
			if(!json)
				to_chat(usr, "<span class='warning'>В корпусе нет микросхем — нечего сохранить для принтера.</span>")
				. = TRUE
				return
			var/datum/browser/popup = new(usr, "ie_asm_clone", "Код сборки для принтера", 720, 540)
			popup.set_content("Полный JSON этой сборки. Вставь в интегральный принтер при включённом клонировании (как при ghost scan или анализаторе).<br><br><code style='word-break:break-all;white-space:pre-wrap;font-size:11px'>[html_encode(json)]</code>")
			popup.open()
			. = TRUE
		if("ie_copy_component_ref")
			if(!usr || !check_rights_for(usr.client, R_DEBUG))
				return
			var/cid = text2num(params["component_id"])
			var/obj/item/integrated_circuit/chip = ie_ic_chip_from_index(src, cid)
			if(!chip || !(chip in assembly_components))
				return
			to_chat(usr, "<span class='notice'>Ref чипа: [REF(chip)] — [chip.type]</span>")
			. = TRUE
	if(action in list("add_variable", "remove_variable", "add_setter_or_getter", "save_circuit"))
		return TRUE

/obj/item/integrated_circuit/ui_assets(mob/user)
	if(assembly)
		return assembly.ui_assets(user)
	return list(
		get_asset_datum(/datum/asset/simple/circuit_assets)
	)

/obj/item/integrated_circuit/ui_state(mob/user)
	if(assembly)
		return assembly.ui_state(user)
	return GLOB.hands_state

/obj/item/integrated_circuit/ui_static_data(mob/user)
	if(assembly)
		return assembly.ui_static_data(user)
	. = list()
	.["global_basic_types"] = GLOB.ie_integrated_circuit_ui_types
	.["screen_x"] = ie_tgui_screen_x
	.["screen_y"] = ie_tgui_screen_y

/obj/item/integrated_circuit/ui_data(mob/user)
	if(assembly)
		return assembly.ui_data(user)
	. = list()
	.["ie_circuit"] = TRUE
	.["ie_clone_copy_mode"] = "chip"
	.["ie_debug_copy_ref"] = FALSE
	.["ie_used_size"] = size
	.["ie_max_size"] = null
	.["ie_used_complexity"] = complexity
	.["ie_max_complexity"] = null
	.["circuit_on"] = TRUE
	.["is_admin"] = FALSE
	.["variables"] = list()
	.["display_name"] = displayed_name || name
	.["components"] = list()
	.["components"] += list(ie_ic_component_payload(src))
	.["screen_x"] = ie_tgui_screen_x
	.["screen_y"] = ie_tgui_screen_y
	var/obj/item/integrated_circuit/examined = ie_gui_examined_circuit?.resolve()
	if(examined != src)
		examined = null
	.["examined_name"] = examined ? ie_ic_ui_examine_title(examined) : null
	.["examined_desc"] = examined ? ie_ic_ui_examine_desc(examined) : null
	.["examined_notices"] = examined ? ie_ic_ui_examine_notices(examined) : list()
	.["examined_rel_x"] = ie_gui_examined_x
	.["examined_rel_y"] = ie_gui_examined_y
	var/solo_pulse = world.time < ie_tgui_solo_pulse_until
	.["circuit_pulse_out_ref"] = solo_pulse ? ie_tgui_solo_pulse_out_ref : null
	.["circuit_pulse_in_ref"] = solo_pulse ? ie_tgui_solo_pulse_in_ref : null

/obj/item/integrated_circuit/ui_act(action, list/params)
	if(assembly)
		return assembly.ui_act(action, params)
	. = ..()
	if(.)
		return
	switch(action)
		if("ie_switch_classic_ui")
			if(!usr?.client?.prefs)
				return
			usr.client.prefs.ie_classic_circuit_ui = TRUE
			SStgui.close_uis(src)
			ie_legacy_ui_interact_chip(usr)
			. = TRUE
		if("set_component_display_name")
			var/nn = params["display_name"]
			if(isnull(nn))
				return TRUE
			displayed_name = reject_bad_name(strip_html(nn), TRUE) || displayed_name
			. = TRUE
		if("add_connection")
			var/ocid = text2num(params["output_component_id"])
			var/icid = text2num(params["input_component_id"])
			var/opid = text2num(params["output_port_id"])
			var/ipid = text2num(params["input_port_id"])
			var/obj/item/integrated_circuit/out_chip = ie_ic_chip_from_index(src, ocid)
			var/obj/item/integrated_circuit/in_chip = ie_ic_chip_from_index(src, icid)
			if(!out_chip || !in_chip || out_chip != src || in_chip != src)
				return
			var/datum/integrated_io/out_io = ie_ic_get_output_io(out_chip, opid)
			var/datum/integrated_io/in_io = ie_ic_get_input_io(in_chip, ipid)
			if(!out_io || !in_io)
				return
			if(out_io.io_type != in_io.io_type)
				return
			out_io.connect_pin(in_io)
			. = TRUE
		if("remove_connection")
			var/port_id = text2num(params["port_id"])
			var/is_input = params["is_input"]
			var/datum/integrated_io/io = is_input ? ie_ic_get_input_io(src, port_id) : ie_ic_get_output_io(src, port_id)
			if(io)
				io.disconnect_all()
				. = TRUE
		if("detach_component")
			. = TRUE
		if("set_component_coordinates")
			ie_ui_rel_x = clamp(text2num(params["rel_x"]), -IE_TGUI_COMPONENT_COORD_LIMIT, IE_TGUI_COMPONENT_COORD_LIMIT)
			ie_ui_rel_y = clamp(text2num(params["rel_y"]), -IE_TGUI_COMPONENT_COORD_LIMIT, IE_TGUI_COMPONENT_COORD_LIMIT)
			. = TRUE
		if("set_component_input")
			var/pid = text2num(params["port_id"])
			var/is_out = params["is_output"]
			var/datum/integrated_io/io = is_out ? ie_ic_get_output_io(src, pid) : ie_ic_get_input_io(src, pid)
			if(!io || !usr)
				return
			if(io.io_type == PULSE_CHANNEL)
				if(istype(io, /datum/integrated_io/activate/out))
					return TRUE
				check_then_do_work(io.ord, ignore_power = TRUE)
				return TRUE
			if(params["set_null"])
				io.write_data_to_pin(null)
				return TRUE
			if(params["marked_atom"])
				ie_ic_tgui_apply_marked_atom_or_debugger(usr, io)
				return TRUE
			var/ftype = ie_ic_fundamental_type(io)
			ie_ic_tgui_write_input(io, ftype, params["input"])
			return TRUE
		if("ie_open_list_editor")
			var/pid = text2num(params["port_id"])
			var/is_out = params["is_output"] ? TRUE : FALSE
			var/datum/integrated_io/io = is_out ? ie_ic_get_output_io(src, pid) : ie_ic_get_input_io(src, pid)
			if(istype(io, /datum/integrated_io/lists))
				var/datum/integrated_io/lists/L = io
				L.interact(usr)
				. = TRUE
		if("ie_open_data_inspector")
			var/pid = text2num(params["port_id"])
			var/is_out = params["is_output"] ? TRUE : FALSE
			var/datum/integrated_io/io = is_out ? ie_ic_get_output_io(src, pid) : ie_ic_get_input_io(src, pid)
			if(!io || !usr)
				return
			var/datum/browser/popup = new(usr, "ie_pin_data_[REF(io)]", "[src.displayed_name || src.name]: [io.name]", 640, 520)
			popup.set_content("<div style='font-size:12px;word-break:break-word;'>[io.display_data(io.data)]</div>")
			popup.open()
			. = TRUE
		if("get_component_value")
			var/pid = text2num(params["port_id"])
			var/datum/integrated_io/io = ie_ic_get_output_io(src, pid)
			if(!io || !usr)
				return
			usr.balloon_alert(usr, "[io.name]: [copytext("[ie_ic_serialize_data(io)]", 1, 80)]")
			. = TRUE
		if("set_display_name")
			var/nn = params["display_name"]
			if(!isnull(nn))
				displayed_name = reject_bad_name(strip_html(nn), TRUE) || displayed_name
			. = TRUE
		if("set_examined_component")
			ie_gui_examined_circuit = WEAKREF(src)
			var/px = text2num(params["x"])
			var/py = text2num(params["y"])
			if(!isnum(px))
				px = 0
			if(!isnum(py))
				py = 0
			ie_gui_examined_x = clamp(px, 0, 4000)
			ie_gui_examined_y = clamp(py, 0, 4000)
			. = TRUE
		if("remove_examined_component")
			ie_gui_examined_circuit = null
			. = TRUE
		if("move_screen")
			ie_tgui_screen_x = text2num(params["screen_x"])
			ie_tgui_screen_y = text2num(params["screen_y"])
			. = TRUE
		if("swap_input_connection_order")
			var/pid = text2num(params["port_id"])
			var/lower = text2num(params["lower_index"])
			var/datum/integrated_io/io = ie_ic_get_input_io(src, pid)
			if(!io || length(io.linked) < lower + 1 || lower < 1)
				return
			io.linked.Swap(lower, lower + 1)
			. = TRUE
		if("swap_output_connection_order")
			var/pid = text2num(params["port_id"])
			var/lower = text2num(params["lower_index"])
			var/datum/integrated_io/io = ie_ic_get_output_io(src, pid)
			if(!io || !ie_ic_is_output_side_pin(io) || length(io.linked) < lower + 1 || lower < 1)
				return
			var/datum/integrated_io/a = io.linked[lower]
			var/datum/integrated_io/b = io.linked[lower + 1]
			if(ie_ic_is_output_side_pin(a) || ie_ic_is_output_side_pin(b))
				return
			io.linked.Swap(lower, lower + 1)
			. = TRUE
		if("ie_copy_component_code")
			if(!usr)
				return
			var/list/chip_data = save()
			var/json = json_encode(chip_data)
			var/datum/browser/popup = new(usr, "ie_chip_save", "Параметры чипа (JSON)", 640, 440)
			popup.set_content("JSON одного чипа (имя, закреплённые входы и т.д.):<br><br><code style='word-break:break-all;white-space:pre-wrap;font-size:11px'>[html_encode(json)]</code>")
			popup.open()
			. = TRUE
	if(action in list("add_variable", "remove_variable", "add_setter_or_getter", "save_circuit"))
		return TRUE
