/obj/structure/frame
	name = "frame"
	icon = 'icons/obj/stock_parts.dmi'
	icon_state = "box_0"
	density = TRUE
	max_integrity = 250
	var/obj/item/circuitboard/machine/circuit = null
	var/state = 1

/obj/structure/frame/examine(user)
	. = ..()
	if(circuit)
		. += "It has \a [circuit] installed."


/obj/structure/frame/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		new /obj/item/stack/sheet/metal(loc, 5)
		if(circuit)
			circuit.forceMove(loc)
			circuit = null
	qdel(src)

//callback proc used on stacks use_tool to stop unnecessary amounts being wasted from spam clicking.
/obj/structure/frame/proc/check_state(target_state)
	if(state == target_state)
		return TRUE
	return FALSE

/obj/structure/frame/machine
	name = "machine frame"
	var/list/components = null
	var/list/req_components = null
	var/list/req_component_names = null // user-friendly names of components

/obj/structure/frame/machine/examine(user)
	. = ..()
	if(state == 3 && req_components && req_component_names)
		var/hasContent = FALSE
		var/requires = "It requires"

		for(var/i = 1 to req_components.len)
			var/tname = req_components[i]
			var/amt = req_components[tname]
			if(amt == 0)
				continue
			var/use_and = i == req_components.len
			requires += "[(hasContent ? (use_and ? ", and" : ",") : "")] [amt] [amt == 1 ? req_component_names[tname] : "[req_component_names[tname]]\s"]"
			hasContent = TRUE

		if(hasContent)
			. +=  "[requires]."
		else
			. += "It does not require any more components."
	if(anchored)
		. += span_notice("It's bolted to the floor.")

/obj/structure/frame/machine/proc/update_namelist()
	if(!req_components)
		return

	req_component_names = new()
	for(var/tname in req_components)
		if(ispath(tname, /obj/item/stack))
			var/obj/item/stack/S = tname
			var/singular_name = initial(S.singular_name)
			if(singular_name)
				req_component_names[tname] = singular_name
			else
				req_component_names[tname] = initial(S.name)
		else
			var/obj/O = tname
			req_component_names[tname] = initial(O.name)

/obj/structure/frame/machine/proc/get_req_components_amt()
	var/amt = 0
	for(var/path in req_components)
		amt += req_components[path]
	return amt

/obj/structure/frame/machine/attackby(obj/item/P, mob/living/user, params)
	switch(state)
		if(1)
			if(istype(P, /obj/item/circuitboard/machine))
				to_chat(user, "<span class='warning'>The frame needs wiring first!</span>")
				return
			else if(istype(P, /obj/item/circuitboard))
				to_chat(user, "<span class='warning'>This frame does not accept circuit boards of this type!</span>")
				return
			if(istype(P, /obj/item/stack/cable_coil))
				if(!P.tool_start_check(user, amount=5))
					return

				to_chat(user, "<span class='notice'>You start to add cables to the frame...</span>")
				if(P.use_tool(src, user, 20, volume=50, amount=5, extra_checks = CALLBACK(src, PROC_REF(check_state), 1)))
					to_chat(user, "<span class='notice'>You add cables to the frame.</span>")
					state = 2
					icon_state = "box_1"

				return
			if(P.tool_behaviour == TOOL_SCREWDRIVER && !anchored)
				user.visible_message("<span class='warning'>[user] disassembles the frame.</span>", \
									"<span class='notice'>You start to disassemble the frame...</span>", "<span class='hear'>You hear banging and clanking.</span>")
				if(P.use_tool(src, user, 40, volume=50, extra_checks = CALLBACK(src, PROC_REF(check_state), 1)))
					if(state == 1)
						to_chat(user, "<span class='notice'>You disassemble the frame.</span>")
						var/obj/item/stack/sheet/metal/M = new (loc, 5)
						M.add_fingerprint(user)
						qdel(src)
				return
			if(P.tool_behaviour == TOOL_WRENCH)
				to_chat(user, "<span class='notice'>You start [anchored ? "un" : ""]securing [src]...</span>")
				if(P.use_tool(src, user, 40, volume=75, extra_checks = CALLBACK(src, PROC_REF(check_state), 1)))
					if(state == 1)
						to_chat(user, "<span class='notice'>You [anchored ? "un" : ""]secure [src].</span>")
						set_anchored(!anchored)
				return

		if(2)
			if(P.tool_behaviour == TOOL_WRENCH)
				to_chat(user, "<span class='notice'>You start [anchored ? "un" : ""]securing [src]...</span>")
				if(P.use_tool(src, user, 40, volume=75, extra_checks = CALLBACK(src, PROC_REF(check_state), 2)))
					to_chat(user, "<span class='notice'>You [anchored ? "un" : ""]secure [src].</span>")
					set_anchored(!anchored)
				return
			if(P.tool_behaviour == TOOL_WIRECUTTER)
				P.play_tool_sound(src)
				to_chat(user, "<span class='notice'>You remove the cables.</span>")
				state = 1
				icon_state = "box_0"
				new /obj/item/stack/cable_coil(drop_location(), 5)
				return

			// installing circuitboard
			var/obj/item/circuitboard/machine/B = P
			var/obj/item/storage/part_replacer/replacer = istype(P, /obj/item/storage/part_replacer) && P

			if(replacer && replacer.contents.len)
				var/list/board_list = list()
				var/list/board_type_list = list()

				//Assemble a list of current unique circuitboard
				for(var/obj/item/circuitboard/machine/co in replacer)
					if(co.type in board_type_list)
						continue
					board_list += co
					board_type_list += co.type
				
				reverseList(board_list)

				if(board_list.len)
					var/const/max_radial_len = 8
					if(board_list.len == 1)
						B = board_list[1]		
					// Radial menu	
					else if(board_list.len <= max_radial_len)
						var/list/choices = list()
						for(var/obj/item/circuitboard/machine/co in board_list)
							var/machine_path = co.build_path
							if(!ispath(machine_path))
								continue
							var/mutable_appearance/app = new /mutable_appearance()
							app.icon = machine_path:icon
							app.icon_state = machine_path:icon_state
							app.name = co.name
							choices[co] = app
						var/radial_radius = 27 + min(max(choices.len - 5, 0), 3) * 3 // 6 = 30, 7 = 33, 8+ = 36
						B = show_radial_menu(user, src, choices, require_near = TRUE, radius = radial_radius)
					// TGUI menu
					else
						B = tgui_input_list(user, "Chose circuitboard", "Installing", board_list)

					if(QDELETED(src) || QDELETED(replacer) || (B && QDELETED(B)) || state != 2 || !Adjacent(user))
						return

			if(istype(B))
				if(!B.build_path)
					to_chat(user, "<span class='warning'>This circuitboard seems to be broken.</span>")
					return
				if(!anchored && B.needs_anchored)
					to_chat(user, "<span class='warning'>The frame needs to be secured first!</span>")
					return
				if(!user.transferItemToLoc(B, src))
					return
				playsound(src.loc, 'sound/items/deconstruct.ogg', 50, TRUE)
				to_chat(user, "<span class='notice'>You add [B] to the frame.</span>")
				circuit = B
				icon_state = "box_2"
				state = 3
				components = list()
				req_components = B.req_components.Copy()
				update_namelist()
				if(replacer)
					replacer_add_components(replacer, user)
				return
			else if(istype(P, /obj/item/circuitboard))
				to_chat(user, "<span class='warning'>This frame does not accept circuit boards of this type!</span>")
				return
		if(3)
			if(P.tool_behaviour == TOOL_CROWBAR)
				P.play_tool_sound(src)
				state = 2
				circuit.forceMove(drop_location())
				components.Remove(circuit)
				circuit = null
				if(components.len == 0)
					to_chat(user, "<span class='notice'>You remove the circuit board.</span>")
				else
					to_chat(user, "<span class='notice'>You remove the circuit board and other components.</span>")
					for(var/atom/movable/AM in components)
						AM.forceMove(drop_location())
				desc = initial(desc)
				req_components = null
				components = null
				icon_state = "box_1"
				return

			if(P.tool_behaviour == TOOL_WRENCH && !circuit.needs_anchored)
				to_chat(user, "<span class='notice'>You start [anchored ? "un" : ""]securing [src]...</span>")
				if(P.use_tool(src, user, 40, volume=75, extra_checks = CALLBACK(src, PROC_REF(check_state), 3)))
					to_chat(user, "<span class='notice'>You [anchored ? "un" : ""]secure [src].</span>")
					set_anchored(!anchored)
				return

			if(P.tool_behaviour == TOOL_SCREWDRIVER)
				var/component_check = TRUE
				for(var/R in req_components)
					if(req_components[R] > 0)
						component_check = FALSE
						break
				if(component_check)
					P.play_tool_sound(src)
					var/obj/machinery/new_machine = new circuit.build_path(loc)
					if(istype(new_machine))
						// Machines will init with a set of default components. Move to nullspace so we don't trigger handle_atom_del, then qdel.
						// Finally, replace with this frame's parts.
						if(new_machine.circuit)
							// Move to nullspace and delete.
							new_machine.circuit.moveToNullspace()
							QDEL_NULL(new_machine.circuit)
						for(var/obj/old_part in new_machine.component_parts)
							// Move to nullspace and delete.
							old_part.moveToNullspace()
							qdel(old_part)

						// Set anchor state and move the frame's parts over to the new machine.
						// Then refresh parts and call on_construction().

						new_machine.set_anchored(anchored)
						new_machine.component_parts = list()

						circuit.forceMove(new_machine)
						new_machine.component_parts += circuit
						new_machine.circuit = circuit

						for(var/obj/new_part in src)
							new_part.forceMove(new_machine)
							new_machine.component_parts += new_part
						new_machine.RefreshParts()

						new_machine.on_construction()
						// TODO: make sleepers not shit out parts PROPERLY THIS TIME.
						new_machine.circuit.moveToNullspace()
					qdel(src)
				return

			if(istype(P, /obj/item/storage/part_replacer) && P.contents.len && get_req_components_amt())
				replacer_add_components(P, user)
				
			if(isitem(P) && get_req_components_amt())
				for(var/I in req_components)
					if(istype(P, I) && (req_components[I] > 0))
						if(istype(P, /obj/item/stack))
							var/obj/item/stack/S = P
							var/used_amt = min(round(S.get_amount()), req_components[I])

							if(used_amt && S.use(used_amt))
								var/obj/item/stack/NS = locate(S.merge_type) in components

								if(!NS)
									NS = new S.merge_type(src, used_amt)
									components += NS
								else
									NS.add(used_amt)

								req_components[I] -= used_amt
								to_chat(user, "<span class='notice'>You add [icon2html(P, user)] [P] to [src].</span>")
							return
						if(!user.transferItemToLoc(P, src))
							break
						to_chat(user, "<span class='notice'>You add [icon2html(P, user)] [P] to [src].</span>")
						components += P
						req_components[I]--
						return TRUE
				to_chat(user, "<span class='warning'>You cannot add that to the machine!</span>")
				return FALSE
	if(user.a_intent == INTENT_HARM)
		return ..()

// BLUEMOON ADD START
/obj/structure/frame/machine/proc/replacer_add_components(obj/item/storage/part_replacer/replacer, mob/living/user)
	if(QDELETED(src) || !replacer || QDELETED(replacer) || state != 3 || !Adjacent(user))
		return

	var/list/added_components = list()
	var/list/part_list = list()

	//Assemble a list of current parts, then sort them by their rating!
	for(var/obj/item/co in replacer)
		part_list += co
	//Sort the parts. This ensures that higher tier items are applied first.
	part_list = sortTim(part_list, GLOBAL_PROC_REF(cmp_rped_sort))

	for(var/path in req_components)
		while(req_components[path] > 0 && (locate(path) in part_list))
			var/obj/item/part = (locate(path) in part_list)
			part_list -= part
			if(istype(part,/obj/item/stack))
				var/obj/item/stack/S = part
				var/used_amt = min(round(S.get_amount()), req_components[path])
				if(!used_amt || !S.use(used_amt))
					continue
				var/NS = new S.merge_type(src, used_amt)
				added_components[NS] = path
				req_components[path] -= used_amt
			else
				added_components[part] = path
				if(SEND_SIGNAL(replacer, COMSIG_TRY_STORAGE_TAKE, part, src))
					req_components[path]--

	var/list/message_list = list()
	for(var/obj/item/part in added_components)
		if(istype(part,/obj/item/stack))
			var/obj/item/stack/incoming_stack = part
			for(var/obj/item/stack/merge_stack in components)
				if(incoming_stack.can_merge(merge_stack))
					incoming_stack.merge(merge_stack)
					if(QDELETED(incoming_stack))
						break
		if(!QDELETED(part)) //If we're a stack and we merged we might not exist anymore
			components += part
			part.forceMove(src)
		message_list += span_notice("[icon2html(part, user)] [part.name] applied.")
	if(message_list.len)
		var/message = jointext(message_list, "\n")
		to_chat(user, message)
	if(added_components.len)
		replacer.play_rped_sound()
	return TRUE
// BLUEMOON ADD END

/obj/structure/frame/machine/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		if(state >= 2)
			new /obj/item/stack/cable_coil(loc , 5)
		for(var/X in components)
			var/obj/item/I = X
			I.forceMove(loc)
	..()
