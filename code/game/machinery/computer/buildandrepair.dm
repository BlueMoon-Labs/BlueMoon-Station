/obj/structure/frame/computer
	name = "computer frame"
	icon_state = "console_frame"
	state = 0
	base_icon_state = "console_frame"
	var/obj/item/stack/sheet/decon_material = /obj/item/stack/sheet/metal
	var/built_icon = 'icons/obj/computer.dmi'
	var/built_icon_state = "computer"
	var/deconpath = /obj/structure/frame/computer

/obj/structure/frame/computer/examine(user)
	. = ..()
	if(anchored)
		. += span_notice("It's bolted to the floor.")

/obj/structure/frame/computer/attackby(obj/item/P, mob/user, params)
	add_fingerprint(user)
	var/obj/item/storage/part_replacer/replacer = istype(P, /obj/item/storage/part_replacer) && P
	switch(state)
		if(0)
			if(P.tool_behaviour == TOOL_WRENCH)
				to_chat(user, "<span class='notice'>You start wrenching the frame into place...</span>")
				if(P.use_tool(src, user, 20, volume=50))
					to_chat(user, "<span class='notice'>You wrench the frame into place.</span>")
					set_anchored(TRUE)
					state = 1
					icon_state = "0"
				return
			if(P.tool_behaviour == TOOL_WELDER)
				if(!P.tool_start_check(user, amount=0))
					return

				to_chat(user, "<span class='notice'>You start deconstructing the frame...</span>")
				if(P.use_tool(src, user, 20, volume=50))
					to_chat(user, "<span class='notice'>You deconstruct the frame.</span>")

					var/obj/dropped_sheet = new decon_material(drop_location(), 5)
					dropped_sheet.add_fingerprint(user)
					qdel(src)
				return
		if(1)
			if(P.tool_behaviour == TOOL_WRENCH)
				to_chat(user, "<span class='notice'>You start to unfasten the frame...</span>")
				if(P.use_tool(src, user, 20, volume=50))
					to_chat(user, "<span class='notice'>You unfasten the frame.</span>")
					set_anchored(FALSE)
					state = 0
					icon_state = "0"
				return
			if(circuit)
				if(P.tool_behaviour == TOOL_SCREWDRIVER)
					P.play_tool_sound(src)
					to_chat(user, "<span class='notice'>You screw [circuit] into place.</span>")
					state = 2
					icon_state = "2"
					update_icon()
					return
				if(P.tool_behaviour == TOOL_CROWBAR)
					P.play_tool_sound(src)
					to_chat(user, "<span class='notice'>You remove [circuit].</span>")
					state = 1
					icon_state = "0"
					circuit.forceMove(drop_location())
					circuit.add_fingerprint(user)
					circuit = null
					update_icon()
					return
			else
				// installing circuitboard
				var/obj/item/circuitboard/computer/B = P

				if(replacer && replacer.contents.len)
					var/list/board_list = list()
					var/list/board_type_list = list()

					//Assemble a list of current unique circuitboard
					for(var/obj/item/circuitboard/computer/co in replacer)
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
							for(var/obj/item/circuitboard/computer/co in board_list)
								var/comp_path = co.build_path
								if(!ispath(comp_path, /obj/machinery/computer))
									continue
								var/icon_file = comp_path:icon
								var/mutable_appearance/app = new /mutable_appearance()
								app.icon = icon_file
								app.icon_state = comp_path:icon_state
								app.name = co.name

								if(!comp_path:unique_icon)
									// overlays
									var/mutable_appearance/ov = new /mutable_appearance()
									ov.icon = icon_file
									ov.icon_state = comp_path:icon_screen
									app.overlays += ov

									ov = new /mutable_appearance()
									ov.icon = icon_file
									ov.icon_state = comp_path:icon_keyboard
									app.overlays += ov

								choices[co] = app

							var/radial_radius = 27 + min(max(choices.len - 5, 0), 3) * 3 // 6 = 30, 7 = 33, 8+ = 36
							B = show_radial_menu(user, src, choices, require_near = TRUE, radius = radial_radius)
						// TGUI menu
						else
							B = tgui_input_list(user, "Chose circuitboard", "Installing", board_list)

						if(QDELETED(src) || QDELETED(replacer) || (B && QDELETED(B)) || state != 1 || !Adjacent(user))
							return

				if(istype(B))
					if(!user.transferItemToLoc(B, src))
						return
					playsound(src, 'sound/items/deconstruct.ogg', 50, TRUE)
					to_chat(user, "<span class='notice'>You place [B] inside the frame.</span>")
					circuit = B
					circuit.add_fingerprint(user)
					icon_state = "1"
					if(!replacer)
						update_icon()
						return
					state = 2
					icon_state = "2"
					var/obj/item/stack/cable_coil/c = locate(/obj/item/stack/cable_coil) in replacer.contents
					if(c && c.use_tool(src, user, 0, 5, 0, skill_gain_mult = 0.05))
						state = 3
						icon_state = "3"
						var/obj/item/stack/sheet/glass/g = locate(/obj/item/stack/sheet/glass) in replacer.contents
						if(g && g.use_tool(src, user, 0, 2, 0, skill_gain_mult = 0.05))
							state = 4
							icon_state = "4"
					update_icon()
					return
				else if(istype(P, /obj/item/circuitboard))
					to_chat(user, "<span class='warning'>This frame does not accept circuit boards of this type!</span>")
					return
		if(2)
			if(P.tool_behaviour == TOOL_SCREWDRIVER && circuit)
				P.play_tool_sound(src)
				to_chat(user, "<span class='notice'>You unfasten the circuit board.</span>")
				state = 1
				icon_state = "1"
				update_icon()
				return

			if(replacer)
				var/obj/item/stack/cable_coil/c = locate(/obj/item/stack/cable_coil) in replacer.contents
				if(c && c.use_tool(src, user, 0, 5, 50, skill_gain_mult = 0.05))
					state = 3
					icon_state = "3"
					var/obj/item/stack/sheet/glass/g = locate(/obj/item/stack/sheet/glass) in replacer.contents
					if(g && g.use_tool(src, user, 0, 2, 0, skill_gain_mult = 0.05))
						state = 4
						icon_state = "4"
				update_icon()
				return
			else if(istype(P, /obj/item/stack/cable_coil))
				if(!P.tool_start_check(user, amount=5))
					return
				to_chat(user, "<span class='notice'>You start adding cables to the frame...</span>")
				if(P.use_tool(src, user, 20, volume=50, amount=5))
					if(state != 2)
						return
					to_chat(user, "<span class='notice'>You add cables to the frame.</span>")
					state = 3
					icon_state = "3"
					update_icon()
				return
		if(3)
			if(P.tool_behaviour == TOOL_WIRECUTTER)
				P.play_tool_sound(src)
				to_chat(user, "<span class='notice'>You remove the cables.</span>")
				state = 2
				icon_state = "2"
				update_icon()
				var/obj/item/stack/cable_coil/A = new (drop_location(), 5)
				A.add_fingerprint(user)
				return

			if(replacer)
				var/obj/item/stack/sheet/glass/g = locate(/obj/item/stack/sheet/glass) in replacer.contents
				if(g && g.use_tool(src, user, 0, 2, skill_gain_mult = 0.05))
					playsound(src, 'sound/items/deconstruct.ogg', 50, TRUE)
					state = 4
					icon_state = "4"
					update_icon()
				return
			else if(istype(P, /obj/item/stack/sheet/glass))
				if(!P.tool_start_check(user, amount=2))
					return
				playsound(src, 'sound/items/deconstruct.ogg', 50, TRUE)
				to_chat(user, "<span class='notice'>You start to put in the glass panel...</span>")
				if(P.use_tool(src, user, 20, amount=2))
					if(state != 3)
						return
					to_chat(user, "<span class='notice'>You put in the glass panel.</span>")
					state = 4
					icon_state = "4"
					update_icon()
				return
		if(4)
			if(P.tool_behaviour == TOOL_CROWBAR)
				P.play_tool_sound(src)
				to_chat(user, "<span class='notice'>You remove the glass panel.</span>")
				state = 3
				icon_state = "3"
				update_icon()
				var/obj/item/stack/sheet/glass/G = new(drop_location(), 2)
				G.add_fingerprint(user)
				return
			if(P.tool_behaviour == TOOL_SCREWDRIVER)
				P.play_tool_sound(src)
				to_chat(user, "<span class='notice'>You connect the monitor.</span>")

				var/obj/machinery/new_machine = new circuit.build_path(loc)
				new_machine.setDir(dir)
				transfer_fingerprints_to(new_machine)

				if(istype(new_machine, /obj/machinery/computer))
					var/obj/machinery/computer/new_computer = new_machine

					// Machines will init with a set of default components.
					// Triggering handle_atom_del will make the machine realise it has lost a component_parts and then deconstruct.
					// Move to nullspace so we don't trigger handle_atom_del, then qdel.
					// Finally, replace new machine's parts with this frame's parts.
					if(new_computer.circuit)
						// Move to nullspace and delete.
						new_computer.circuit.moveToNullspace()
						QDEL_NULL(new_computer.circuit)
					for(var/old_part in new_computer.component_parts)
						var/atom/movable/movable_part = old_part
						// Move to nullspace and delete.
						movable_part.moveToNullspace()
						qdel(movable_part)

					// Set anchor state and move the frame's parts over to the new machine.
					// Then refresh parts and call on_construction().
					new_computer.set_anchored(anchored)
					new_computer.component_parts = list()

					circuit.forceMove(new_computer)
					new_computer.component_parts += circuit
					new_computer.circuit = circuit

					for(var/new_part in src)
						var/atom/movable/movable_part = new_part
						movable_part.forceMove(new_computer)
						new_computer.component_parts += movable_part

					new_computer.RefreshParts()
					new_computer.on_construction()
					new_computer.circuit.moveToNullspace()

					if(!new_computer.unique_icon)
						new_computer.icon = built_icon
						new_computer.icon_state = built_icon_state
					new_computer.deconpath = deconpath
					new_computer.update_icon()
					qdel(src)
					return
	if(user.a_intent == INTENT_HARM)
		return ..()

/obj/structure/frame/computer/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		if(state == 4)
			new /obj/item/shard(drop_location())
			new /obj/item/shard(drop_location())
		if(state >= 3)
			new /obj/item/stack/cable_coil(drop_location(), 5)
	..()

/obj/structure/frame/computer/AltClick(mob/user)
	..()
	if(!isliving(user) || !user.canUseTopic(src, BE_CLOSE, ismonkey(user)))
		return

	if(anchored)
		to_chat(usr, "<span class='warning'>You must unwrench [src] before rotating it!</span>")
		return

	setDir(turn(dir, -90))
