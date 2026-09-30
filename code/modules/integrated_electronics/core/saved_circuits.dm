// Helpers for saving/loading integrated circuits.


// Saves type, modified name and modified inputs (if any) to a list
// The list is converted to JSON down the line.
//"Special" is not verified at any point except for by the circuit itself.
/obj/item/integrated_circuit/proc/save()
	var/list/component_params = list()
	var/init_name = initial(name)

	// Save initial name used for differentiating assemblies
	component_params["type"] = init_name

	// Save the modified name.
	if(init_name != displayed_name)
		component_params["name"] = displayed_name

	// Saving input values
	if(length(inputs))
		var/list/saved_inputs = list()

		for(var/index in 1 to inputs.len)
			var/datum/integrated_io/input = inputs[index]

			// Don't waste space saving the default values
			if(input.data == inputs_default["[index]"])
				continue
			if(input.data == initial(input.data))
				continue

			var/list/input_value = list(index, FALSE, input.data)
			// Index, Type, Value
			// FALSE is default type used for num/text/list/null
			// TODO: support for special input types, such as internal refs and maybe typepaths

			if(islist(input.data) || isnum(input.data) || istext(input.data) || isnull(input.data))
				saved_inputs.Add(list(input_value))

		if(saved_inputs.len)
			component_params["inputs"] = saved_inputs

	var/special = save_special()
	if(!isnull(special))
		component_params["special"] = special

	/// TGUI canvas (always written so new saves skip legacy auto-layout).
	component_params["ui_x"] = ie_ui_rel_x
	component_params["ui_y"] = ie_ui_rel_y

	return component_params

/obj/item/integrated_circuit/proc/save_special()
	return

// Verifies a list of component parameters
// Returns null on success, error name on failure
/obj/item/integrated_circuit/proc/verify_save(list/component_params)
	var/init_name = initial(name)
	// Validate name
	if(component_params["name"] && !reject_bad_name(component_params["name"], TRUE))
		return "Bad component name at [init_name]."

	// Validate input values
	if(component_params["inputs"])
		var/list/loaded_inputs = component_params["inputs"]
		if(!islist(loaded_inputs))
			return "Malformed input values list at [init_name]."

		var/inputs_amt = length(inputs)

		// Too many inputs? Inputs for input-less component? This is not good.
		if(!inputs_amt || inputs_amt < length(loaded_inputs))
			return "Input values list out of bounds at [init_name]."

		for(var/list/input in loaded_inputs)
			if(input.len != 3)
				return "Malformed input data at [init_name]."

			var/input_id = input[1]
			var/input_type = input[2]
			//var/input_value = input[3]

			// No special type support yet.
			if(input_type)
				return "Unidentified input type at [init_name]!"
			// TODO: support for special input types, such as typepaths and internal refs

			// Input ID is a list index, make sure it's sane.
			if(!isnum(input_id) || input_id % 1 || input_id > inputs_amt || input_id < 1)
				return "Invalid input index at [init_name]."

	if(("ui_x" in component_params) && !isnum(component_params["ui_x"]))
		return "Invalid ui_x at [init_name]."
	if(("ui_y" in component_params) && !isnum(component_params["ui_y"]))
		return "Invalid ui_y at [init_name]."
	if(isnum(component_params["ui_x"]) && (component_params["ui_x"] > IE_TGUI_COMPONENT_COORD_LIMIT || component_params["ui_x"] < -IE_TGUI_COMPONENT_COORD_LIMIT))
		return "ui_x out of bounds at [init_name]."
	if(isnum(component_params["ui_y"]) && (component_params["ui_y"] > IE_TGUI_COMPONENT_COORD_LIMIT || component_params["ui_y"] < -IE_TGUI_COMPONENT_COORD_LIMIT))
		return "ui_y out of bounds at [init_name]."


// Loads component parameters from a list
// Doesn't verify any of the parameters it loads, this is the job of verify_save()
/obj/item/integrated_circuit/proc/load(list/component_params)
	// Load name
	if(component_params["name"])
		// NOTE: html_encode is intentionally kept. displayed_name is injected into
		// unescaped legacy-HTML sinks (assembly_legacy_ui.dm) and to_chat, and the
		// circuit-import path does NOT validate component names - dropping this encode
		// would allow a crafted clone-code JSON to inject raw HTML. The cosmetic
		// double-encode on repeated clone cycles is the lesser evil.
		displayed_name = html_encode(component_params["name"])

	// Load input values
	if(component_params["inputs"])
		var/list/loaded_inputs = component_params["inputs"]

		for(var/list/input in loaded_inputs)
			var/index = input[1]
			//var/input_type = input[2]
			var/input_value = input[3]

			var/datum/integrated_io/pin = inputs[index]
			// The pins themselves validate the data.
			pin.write_data_to_pin(istext(input_value)? html_encode(input_value) : input_value)
			// TODO: support for special input types, such as internal refs and maybe typepaths

	if(!isnull(component_params["special"]))
		load_special(component_params["special"])

	if(isnum(component_params["ui_x"]))
		ie_ui_rel_x = clamp(component_params["ui_x"], -IE_TGUI_COMPONENT_COORD_LIMIT, IE_TGUI_COMPONENT_COORD_LIMIT)
	if(isnum(component_params["ui_y"]))
		ie_ui_rel_y = clamp(component_params["ui_y"], -IE_TGUI_COMPONENT_COORD_LIMIT, IE_TGUI_COMPONENT_COORD_LIMIT)

/obj/item/integrated_circuit/proc/load_special(special_data)
	return

// Saves type and modified name (if any) to a list
// The list is converted to JSON down the line.
/obj/item/electronic_assembly/proc/save()
	var/list/assembly_params = list()

	// Save initial name used for differentiating assemblies
	assembly_params["type"] = initial(name)

	// Save modified name
	if(initial(name) != name)
		assembly_params["name"] = name

	// Save modified description
	if(initial(desc) != desc)
		assembly_params["desc"] = desc

	// Save modified color
	if(initial(detail_color) != detail_color)
		assembly_params["detail_color"] = detail_color

	return assembly_params


// Verifies a list of assembly parameters
// Returns null on success, error name on failure
/obj/item/electronic_assembly/proc/verify_save(list/assembly_params)
	// Validate name and color
	if(assembly_params["name"] && !reject_bad_name(assembly_params["name"], TRUE))
		return "Bad assembly name."
	if(assembly_params["desc"] && !reject_bad_text(assembly_params["desc"]))
		return "Bad assembly description."
	if(assembly_params["detail_color"] && !reject_bad_text(assembly_params["detail_color"], 7))
		return "Bad assembly color."

// Loads assembly parameters from a list
// Doesn't verify any of the parameters it loads, this is the job of verify_save()
/obj/item/electronic_assembly/proc/load(list/assembly_params)
	// NOTE: html_encode intentionally kept here too. name/desc are injected into
	// unescaped legacy-HTML sinks; even though verify_save() rejects </> in them,
	// keeping the encode is the consistent, injection-safe choice for this subsystem.
	if(assembly_params["name"])
		name = html_encode(assembly_params["name"])

	// Load modified description, if any.
	if(assembly_params["desc"])
		desc = html_encode(assembly_params["desc"])

	if(assembly_params["detail_color"])
		detail_color = assembly_params["detail_color"]

	update_icon()

// Attempts to save an assembly into a save file format.
// Returns null if assembly is not complete enough to be saved.
/datum/controller/subsystem/processing/circuit/proc/save_electronic_assembly(obj/item/electronic_assembly/assembly)
	// No components? Don't even try to save it.
	if(!length(assembly.assembly_components))
		return


	var/list/blocks = list()

	// Block 1. Assembly.
	blocks["assembly"] = assembly.save()
	// (implant assemblies are not yet supported)


	// Block 2. Components.
	var/list/components = list()
	for(var/c in assembly.assembly_components)
		var/obj/item/integrated_circuit/component = c
		components.Add(list(component.save()))
	blocks["components"] = components


	// Block 3. Wires.
	var/list/wires = list()
	var/list/saved_wires = list()

	for(var/c in assembly.assembly_components)
		var/obj/item/integrated_circuit/component = c
		var/list/all_pins = component.inputs + component.outputs + component.activators

		for(var/p in all_pins)
			var/datum/integrated_io/pin = p
			var/list/params = pin.get_pin_parameters()
			var/text_params = params.Join()

			for(var/p2 in pin.linked)
				var/datum/integrated_io/pin2 = p2
				var/list/params2 = pin2.get_pin_parameters()
				var/text_params2 = params2.Join()

				// Check if we already saved an opposite version of this wire
				// (do not save the same wire twice)
				if((text_params2 + "=" + text_params) in saved_wires)
					continue

				// If not, add a wire "hash" for future checks and save it
				saved_wires.Add(text_params + "=" + text_params2)
				wires.Add(list(list(params, params2)))

	if(wires.len)
		blocks["wires"] = wires

	return json_encode(blocks)



// Checks assembly save and calculates some of the parameters.
// Returns assembly (type: list) if the save is valid.
// Returns error code (type: text) if loading has failed.
// The following parameters area calculated during validation and added to the returned save list:
// "requires_upgrades", "unsupported_circuit", "metal_cost", "complexity", "max_complexity", "used_space", "max_space"
/datum/controller/subsystem/processing/circuit/proc/validate_electronic_assembly(program)
	var/list/blocks
	try
		blocks = json_decode(program)
	catch
		return "Invalid program format."
	if(!blocks)
		return "Invalid program format."

	var/error


	// Block 1. Assembly.
	var/list/assembly_params = blocks["assembly"]

	if(!islist(assembly_params) || !length(assembly_params))
		return "Invalid assembly data."	// No assembly, damaged assembly or empty assembly

	// Validate type, get a temporary component
	var/assembly_path = all_assemblies[assembly_params["type"]]
	var/obj/item/electronic_assembly/assembly = cached_assemblies[assembly_path]
	if(!assembly)
		return "Invalid assembly type."

	// Check assembly save data for errors
	error = assembly.verify_save(assembly_params)
	if(error)
		return error


	// Read space & complexity limits and start keeping track of them
	blocks["complexity"] = 0
	blocks["max_complexity"] = assembly.max_complexity
	blocks["used_space"] = 0
	blocks["max_space"] = assembly.max_components

	// Start keeping track of total metal cost
	blocks["metal_cost"] = assembly.custom_materials[SSmaterials.GetMaterialRef(/datum/material/iron)]


	// Block 2. Components.
	if(!islist(blocks["components"]) || !length(blocks["components"]))
		return "Invalid components list."	// No components or damaged components list

	var/list/assembly_components = list()
	var/list/component_counts = list()
	for(var/C in blocks["components"])
		var/list/component_params = C

		if(!islist(component_params) || !length(component_params))
			return "Invalid component data."

		// Validate type, get a temporary component
		var/component_path = all_components[component_params["type"]]
		var/obj/item/integrated_circuit/component = cached_components[component_path]
		if(!component)
			return "Invalid component type."

		// Add temporary component to assembly_components list, to be used later when verifying the wires
		assembly_components.Add(component)

		// This part makes sure that limit_per_assemnly is respected for each circuit that utilizes this variable (not null, > 0)
		var/count = component_counts[component_path] || 0	// Circuit counter
		count++
		if(component.limit_per_assembly > 0 && count > component.limit_per_assembly)	//
			return "Too many '[component.name]' components for a single assembly. Maximum - [component.limit_per_assembly]"
		component_counts[component_path] = count

		// Check component save data for errors
		error = component.verify_save(component_params)
		if(error)
			return error

		// Update estimated assembly complexity, taken space and material cost
		blocks["complexity"] += component.complexity
		blocks["used_space"] += component.size
		blocks["metal_cost"] += component.custom_materials[SSmaterials.GetMaterialRef(/datum/material/iron)]

		// Check if the assembly requires printer upgrades
		if(!(component.spawn_flags & IC_SPAWN_DEFAULT))
			blocks["requires_upgrades"] = TRUE

		// Check if the assembly supports the circucit
		if((component.action_flags & assembly.allowed_circuit_action_flags) != component.action_flags)
			blocks["unsupported_circuit"] = TRUE


	// Check complexity and space limitations
	if(blocks["used_space"] > blocks["max_space"])
		return "Used space overflow."
	if(blocks["complexity"] > blocks["max_complexity"])
		return "Complexity overflow."


	// Block 3. Wires.
	if(blocks["wires"])
		if(!islist(blocks["wires"]))
			return "Invalid wiring list."	// Damaged wires list

		for(var/w in blocks["wires"])
			var/list/wire = w

			if(!islist(wire) || wire.len != 2)
				return "Invalid wire data."

			var/datum/integrated_io/IO = assembly.get_pin_ref_list(wire[1], assembly_components)
			var/datum/integrated_io/IO2 = assembly.get_pin_ref_list(wire[2], assembly_components)
			if(!IO || !IO2)
				return "Invalid wire data."

			if(initial(IO.io_type) != initial(IO2.io_type))
				return "Wire type mismatch."

	return blocks


// Loads assembly (in form of list) into an object and returns it.
/// Оценка высоты ноды на канвасе (пиксели) — для вертикальной раскладки слоя без наездов.
/proc/ie_tgui_estimate_node_height(obj/item/integrated_circuit/chip)
	if(!chip)
		return 120
	var/pulse_in = 0
	var/pulse_out = 0
	for(var/datum/integrated_io/io as anything in chip.activators)
		if(istype(io, /datum/integrated_io/activate/out))
			pulse_out++
		else
			pulse_in++
	var/data_rows = max(length(chip.inputs), length(chip.outputs))
	var/pulse_rows = max(pulse_in, pulse_out)
	. = 72 + data_rows * 27
	if(pulse_rows > 0)
		. += 22 + pulse_rows * 27
	return max(., 96)

/// Рекурсивно считает глубину узла (длина пути от истока) как колонку дерева.
/// Мемоизованная и устойчивая к циклам: обратные рёбра в процессе обхода не добавляют глубины.
/// `incoming` — список списков: incoming[i] = индексы компонентов, питающих i.
/proc/ie_tgui_layout_depth(idx, list/incoming, list/depth, list/state)
	if(state[idx] == 2)
		return depth[idx]
	if(state[idx] == 1)
		return 0
	state[idx] = 1
	var/best = 0
	var/list/up = incoming[idx]
	for(var/p in up)
		best = max(best, ie_tgui_layout_depth(p, incoming, depth, state) + 1)
	depth[idx] = best
	state[idx] = 2
	return best

/// Стабильная сортировка вставкой по весам `scores` (ассоциативный: индекс -> число).
/// При равных весах раньше идёт меньший индекс компонента — детерминированный порядок.
/proc/ie_tgui_stable_sort_by_score(list/items, list/scores)
	var/len = length(items)
	for(var/j in 2 to len)
		var/key = items[j]
		var/score = scores[key]
		var/k = j - 1
		while(k >= 1)
			var/prev = items[k]
			var/prev_score = scores[prev]
			if(prev_score > score || (prev_score == score && prev > key))
				items[k + 1] = prev
				k--
			else
				break
		items[k + 1] = key

/// Автораскладка компонентов без сохранённых координат: дерево по связям «от истоков к стокам»
/// (слева направо). Колонка = рекурсивно посчитанная глубина от истока; внутри колонки узлы
/// упорядочены по барицентру родителей и разложены вертикально без наездов; граф центрируется.
/proc/ie_tgui_apply_auto_layout(obj/item/electronic_assembly/assembly, list/blocks)
	if(!assembly || !blocks)
		return
	var/list/comp_blocks = blocks["components"]
	var/list/comps = assembly.assembly_components
	var/n = length(comps)
	if(n < 1 || !length(comp_blocks))
		return

	// 1. Кто нуждается в раскладке (нет полной сохранённой позиции ui_x/ui_y).
	var/list/needs_layout = new /list(n)
	var/any_needs_layout = FALSE
	for(var/i in 1 to n)
		var/list/cp = comp_blocks[i]
		var/has_pos = islist(cp) && isnum(cp["ui_x"]) && isnum(cp["ui_y"]) && (cp["ui_x"] != 0 || cp["ui_y"] != 0)
		needs_layout[i] = !has_pos
		if(!has_pos)
			any_needs_layout = TRUE
	if(!any_needs_layout)
		return

	// 2. Ориентированный граф по проводам (направление: output -> input, то есть «вниз по дереву»).
	//    Храним только incoming[i] = индексы компонентов, питающих i, — его достаточно для глубины
	//    и вертикального порядка по барицентру родителей.
	var/list/incoming = new /list(n)
	for(var/i in 1 to n)
		incoming[i] = list()

	if(blocks["wires"] && islist(blocks["wires"]))
		for(var/w in blocks["wires"])
			var/list/wire = w
			if(!islist(wire) || length(wire) != 2)
				continue
			var/datum/integrated_io/a = assembly.get_pin_ref_list(wire[1])
			var/datum/integrated_io/b = assembly.get_pin_ref_list(wire[2])
			if(!a || !b)
				continue
			var/datum/integrated_io/out_pin
			var/datum/integrated_io/in_pin
			if(ie_ic_is_output_side_pin(a))
				out_pin = a
				in_pin = b
			else
				out_pin = b
				in_pin = a
			var/oi = comps.Find(out_pin.holder)
			var/ii = comps.Find(in_pin.holder)
			if(!oi || !ii || oi == ii)
				continue
			var/list/up = incoming[ii]
			if(!(oi in up))
				up.Add(oi)

	// 3. Рекурсивная глубина (колонка): истоки слева, стоки справа.
	var/list/depth = new /list(n)
	var/list/state = new /list(n)
	for(var/i in 1 to n)
		ie_tgui_layout_depth(i, incoming, depth, state)

	var/max_depth = 0
	for(var/i in 1 to n)
		max_depth = max(max_depth, depth[i])

	// 4. Группируем узлы по колонкам; внутри колонки — порядок по барицентру родителей.
	var/list/columns = new /list(max_depth + 1)
	for(var/d in 0 to max_depth)
		columns[d + 1] = list()
	for(var/i in 1 to n)
		var/list/col = columns[depth[i] + 1]
		col.Add(i)

	var/list/row = new /list(n)
	var/list/ordered = new /list(max_depth + 1)
	for(var/d in 0 to max_depth)
		var/list/col = columns[d + 1]
		var/list/ord
		if(d == 0)
			// Истоки — в порядке индекса (колонка уже заполнялась по возрастанию i).
			ord = col.Copy()
		else
			var/list/scores = new /list(n)
			for(var/c in col)
				var/psum = 0
				var/pcnt = 0
				for(var/p in incoming[c])
					if(!isnull(row[p]))
						psum += row[p]
						pcnt++
				scores[c] = pcnt > 0 ? (psum / pcnt) : 0
			ord = col.Copy()
			ie_tgui_stable_sort_by_score(ord, scores)
		ordered[d + 1] = ord
		for(var/k in 1 to length(ord))
			row[ord[k]] = k

	// 5. Экранные координаты: x = колонка * шаг, y = накопленная высота нод в колонке.
	var/list/x_pos = new /list(n)
	var/list/y_pos = new /list(n)
	var/list/col_height = new /list(n)
	for(var/d in 0 to max_depth)
		var/list/ord = ordered[d + 1]
		var/cursor = 0
		for(var/k in 1 to length(ord))
			var/idx = ord[k]
			var/obj/item/integrated_circuit/chip = comps[idx]
			x_pos[idx] = d * IE_TGUI_LAYOUT_COL_GAP
			y_pos[idx] = cursor
			cursor += ie_tgui_estimate_node_height(chip) + IE_TGUI_LAYOUT_NODE_Y_PAD
		col_height[d + 1] = cursor

	// 6. Центрируем: середину горизонтального размаха и каждую колонку по вертикали — в 0.
	var/x_shift = -(max_depth * IE_TGUI_LAYOUT_COL_GAP) / 2
	for(var/i in 1 to n)
		if(!needs_layout[i])
			continue
		var/obj/item/integrated_circuit/chip = comps[i]
		var/d = depth[i]
		var/ch = col_height[d + 1]
		chip.ie_ui_rel_x = clamp(round(x_pos[i] + x_shift), -IE_TGUI_COMPONENT_COORD_LIMIT, IE_TGUI_COMPONENT_COORD_LIMIT)
		chip.ie_ui_rel_y = clamp(round(y_pos[i] - ch / 2), -IE_TGUI_COMPONENT_COORD_LIMIT, IE_TGUI_COMPONENT_COORD_LIMIT)

// No sanity checks are performed, save file is expected to be validated by validate_electronic_assembly
/datum/controller/subsystem/processing/circuit/proc/load_electronic_assembly(loc, list/blocks)

	// Block 1. Assembly.
	var/list/assembly_params = blocks["assembly"]
	var/obj/item/electronic_assembly/assembly_path = all_assemblies[assembly_params["type"]]
	var/obj/item/electronic_assembly/assembly = new assembly_path(null)
	assembly.load(assembly_params)



	// Block 2. Components.
	for(var/component_params in blocks["components"])
		var/obj/item/integrated_circuit/component_path = all_components[component_params["type"]]
		var/obj/item/integrated_circuit/component = new component_path(assembly)
		assembly.add_component(component)
		component.load(component_params)

	ie_tgui_apply_auto_layout(assembly, blocks)

	// Block 3. Wires.
	if(blocks["wires"])
		for(var/w in blocks["wires"])
			var/list/wire = w
			var/datum/integrated_io/IO = assembly.get_pin_ref_list(wire[1])
			var/datum/integrated_io/IO2 = assembly.get_pin_ref_list(wire[2])
			IO.connect_pin(IO2)

	assembly.forceMove(loc)
	return assembly
