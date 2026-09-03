// Representative icons for each research design
/datum/asset/spritesheet_batched/research_designs
	name = "design"

/datum/asset/spritesheet_batched/research_designs/create_spritesheets()
	// Один DMI обслуживает десятки дизайнов, а компьютерам набор стейтов нужен
	// повторно - разобранные наборы держим при себе.
	var/list/states_by_file = list()

	for(var/datum/design/design_path as anything in subtypesof(/datum/design))
		var/icon_file
		var/icon_state
		var/datum/universal_icon/sprite

		if(initial(design_path.research_icon) && initial(design_path.research_icon_state)) //If the design has an icon replacement skip the rest
			icon_file = initial(design_path.research_icon)
			icon_state = initial(design_path.research_icon_state)
			if(!(icon_state in states_of(icon_file, states_by_file)))
				warning("design [design_path] with icon '[icon_file]' missing state '[icon_state]'")
				continue
			sprite = uni_icon(icon_file, icon_state, SOUTH)

		else
			// construct the icon and slap it into the resource cache
			var/atom/item = initial(design_path.build_path)
			if(!ispath(item, /atom))
				// biogenerator outputs to beakers by default
				if(initial(design_path.build_type) & BIOGENERATOR)
					item = /obj/item/reagent_containers/glass/beaker/large
				else
					continue  // shouldn't happen, but just in case

			// circuit boards become their resulting machines or computers
			if(ispath(item, /obj/item/circuitboard))
				var/obj/item/circuitboard/board = item
				var/machine = initial(board.build_path)
				if(machine)
					item = machine

			// Check for GAGS support where necessary
			// var/greyscale_config = initial(item.greyscale_config)
			// var/greyscale_colors = initial(item.greyscale_colors)
			// if (greyscale_config && greyscale_colors)
			// 	icon_file = SSgreyscale.GetColoredIconByType(greyscale_config, greyscale_colors)
			// else
			icon_file = initial(item.icon)

			icon_state = initial(item.icon_state)
			var/list/all_states = states_of(icon_file, states_by_file)
			if(!(icon_state in all_states))
				warning("design [design_path] with icon '[icon_file]' missing state '[icon_state]'")
				continue
			sprite = uni_icon(icon_file, icon_state, SOUTH)

			// computers (and snowflakes) get their screen and keyboard sprites
			if(ispath(item, /obj/machinery/computer) || ispath(item, /obj/machinery/power/solar_control))
				var/obj/machinery/computer/computer = item
				var/screen = initial(computer.icon_screen)
				var/keyboard = initial(computer.icon_keyboard)
				if(screen && (screen in all_states))
					sprite.blend_icon(uni_icon(icon_file, screen, SOUTH), ICON_OVERLAY)
				if(keyboard && (keyboard in all_states))
					sprite.blend_icon(uni_icon(icon_file, keyboard, SOUTH), ICON_OVERLAY)

		insert_icon(initial(design_path.id), sprite)

/// Набор стейтов DMI с запоминанием: один файл разбирается один раз за сборку листа.
/datum/asset/spritesheet_batched/research_designs/proc/states_of(icon_file, list/cache)
	RETURN_TYPE(/list)
	var/list/all_states = cache["[icon_file]"]
	if(isnull(all_states))
		all_states = icon_file ? icon_states(icon_file) : list()
		cache["[icon_file]"] = all_states
	return all_states
