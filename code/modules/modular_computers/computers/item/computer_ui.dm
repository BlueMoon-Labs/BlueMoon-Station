/obj/item/modular_computer/attack_self(mob/user)
	. = ..()
	ui_interact(user)

// Operates TGUI
/obj/item/modular_computer/ui_interact(mob/user, datum/tgui/ui)
	if(!enabled)
		if(ui)
			ui.close()
		return
	if(!use_power())
		if(ui)
			ui.close()
		return

	if(honkvirus_amount > 0)
		honkvirus_amount--
		playsound(src, 'sound/items/bikehorn.ogg', 30, TRUE)

	// if(HAS_TRAIT(user, TRAIT_CHUNKYFINGERS))
	// 	to_chat(user, span_warning("Your fingers are too big to use this right now!"))
	// 	return
	if(HAS_TRAIT(user, TRAIT_CHUNKYFINGERS))
		to_chat(user, span_warning("Кнопки слишком маленькие для твоих пальцев!"))
		return

	// Robots don't really need to see the screen, their wireless connection works as long as computer is on.
	if(!screen_on && !issilicon(user))
		if(ui)
			ui.close()
		return

	// If we have an active program switch to it now.
	if(active_program)
		if(ui) // This is the main laptop screen. Since we are switching to program's UI close it for now.
			ui.close()
		active_program.ui_interact(user)
		return

	// We are still here, that means there is no program loaded. Load the BIOS/ROM/OS/whatever you want to call it.
	// This screen simply lists available programs and user may select them.
	var/list/files = get_all_files()
	if(!length(files))
		to_chat(user, span_danger("\The [src] beeps three times, it's screen displaying a \"DISK ERROR\" warning."))
		return // No HDD/stored files. Something is very broken.

	ui = SStgui.try_update_ui(user, src, ui)
	if (!ui)
		ui = new(user, src, "NtosMain")
		ui.set_autoupdate(TRUE)
		if(ui.open())
			ui.send_asset(get_asset_datum(/datum/asset/simple/headers))


/obj/item/modular_computer/ui_data(mob/user)
	var/list/data = get_header_data()
	data["device_theme"] = device_theme

	data["login"] = list()
	var/obj/item/computer_hardware/card_slot/cardholder = all_components[MC_CARD]
	data["cardholder"] = FALSE
	if(cardholder)
		data["cardholder"] = TRUE
		var/obj/item/card/id/stored_card = cardholder.GetID()
		if(stored_card)
			var/stored_name = stored_card.registered_name
			var/stored_title = stored_card.get_assignment_name()
			if(!stored_name)
				stored_name = "Unknown"
			if(!stored_title)
				stored_title = "Unknown"
			data["login"] = list(
				IDName = stored_name,
				IDJob = stored_title,
			)
	// PDA stores ID directly, not via card_slot hardware
	if(istype(src, /obj/item/modular_computer/pda))
		var/obj/item/modular_computer/pda/pda = src
		if(pda.stored_id)
			var/stored_name = pda.stored_id.registered_name
			var/stored_title = pda.stored_id.get_assignment_name()
			if(!stored_name)
				stored_name = "Unknown"
			if(!stored_title)
				stored_title = "Unknown"
			data["login"] = list(
				IDName = stored_name,
				IDJob = stored_title,
			)
			data["cardholder"] = TRUE

	data["removable_media"] = list()
	if(all_components[MC_SDD])
		data["removable_media"] += "removable storage disk"
	var/obj/item/computer_hardware/ai_slot/intelliholder = all_components[MC_AI]
	if(intelliholder?.stored_card)
		data["removable_media"] += "intelliCard"
	var/obj/item/computer_hardware/card_slot/secondarycardholder = all_components[MC_CARD2]
	if(secondarycardholder?.stored_card)
		data["removable_media"] += "secondary RFID card"

	data["programs"] = list()
	var/list/all_files = get_all_files()
	for(var/datum/computer_file/program/P in all_files)
		var/running = FALSE
		if(P in idle_threads)
			running = TRUE

		data["programs"] += list(list("name" = P.filename, "desc" = P.filedesc, "running" = running, "icon" = P.program_icon, "alert" = P.alert_pending))

	data["has_light"] = has_light
	data["light_on"] = light_on
	data["comp_light_color"] = comp_light_color
	if(isnull(pda_color) && istype(user?.client?.prefs))
		pda_color = user.client.prefs.pda_color
	data["pda_color"] = pda_color
	data["pda_style"] = user?.client?.prefs?.pda_style || "Monospaced"
	data["battery_percent"] = get_battery_percent()
	data["available_themes"] = list()
	for(var/theme_name in GLOB.pda_name_to_theme)
		data["available_themes"] += list(list("name" = theme_name, "id" = GLOB.pda_name_to_theme[theme_name]))

	data["security_level"] = NUM2SECLEVEL(GLOB.security_level)
	data["security_level_color"] = get_security_level_color()

	if(istype(inserted_disk, /obj/item/cartridge))
		data["cartridge_name"] = inserted_disk.name
		data["has_cartridge"] = TRUE
	return data


// Handles user's GUI input
/obj/item/modular_computer/ui_act(action, params)
	. = ..()
	if(.)
		return

	switch(action)
		if("PC_exit")
			playsound(src, 'sound/machines/terminal_eject_disc.ogg', 25, TRUE)
			kill_program()
			return TRUE
		if("PC_shutdown")
			shutdown_computer()
			return TRUE
		if("PC_minimize")
			var/mob/user = usr
			if(!active_program)
				return

			idle_threads.Add(active_program)
			active_program.program_state = PROGRAM_STATE_BACKGROUND // Should close any existing UIs

			active_program = null
			update_appearance()
			if(user && istype(user))
				ui_interact(user) // Re-open the UI on this computer. It should show the main screen now.
			return TRUE

		if("PC_killprogram")
			var/prog = params["name"]
			var/datum/computer_file/program/P = find_file_by_name(prog)
			var/mob/user = usr

			if(!istype(P) || P.program_state == PROGRAM_STATE_KILLED)
				return

			P.kill_program(forced = TRUE)
			playsound(src, 'sound/machines/terminal_prompt_deny.ogg', 25, FALSE)
			to_chat(user, span_notice("Program [P.filename].[P.filetype] with PID [rand(100,999)] has been killed."))

		if("PC_runprogram")
			var/prog = params["name"]
			var/datum/computer_file/program/P = find_file_by_name(prog)
			var/mob/user = usr

			if(!P || !istype(P)) // Program not found or it's not executable program.
				to_chat(user, span_danger("\The [src]'s screen shows \"I/O ERROR - Unable to run program\" warning."))
				return

			P.computer = src

			if(!P.is_supported_by_hardware(hardware_flag, 1, user))
				return

			// The program is already running. Resume it.
			if(P in idle_threads)
				P.program_state = PROGRAM_STATE_ACTIVE
				active_program = P
				P.alert_pending = FALSE
				idle_threads.Remove(P)
				update_appearance()
				playsound(src, 'sound/machines/terminal_select.ogg', 25, FALSE)
				return

			var/obj/item/computer_hardware/processor_unit/PU = all_components[MC_CPU]
			var/max_idle = PU ? PU.max_idle_programs : max_idle_programs

			if(idle_threads.len > max_idle)
				to_chat(user, span_danger("\The [src] displays a \"Maximal CPU load reached. Unable to run another program.\" error."))
				return

			if(P.requires_ntnet && !get_ntnet_status(P.requires_ntnet_feature)) // The program requires NTNet connection, but we are not connected to NTNet.
				to_chat(user, span_danger("\The [src]'s screen shows \"Unable to connect to NTNet. Please retry. If problem persists contact your system administrator.\" warning."))
				return
			if(P.run_program(user))
				active_program = P
				P.alert_pending = FALSE
				update_appearance()
				playsound(src, 'sound/machines/terminal_select.ogg', 25, FALSE)
			return TRUE

		if("PDA_ejectDisk")
			var/obj/item/ejected_disk = inserted_disk
			if(!ejected_disk)
				return FALSE
			if(istype(ejected_disk, /obj/item/cartridge))
				var/obj/item/modular_computer/pda/pda = src
				if(istype(pda))
					pda.uninstall_cartridge_programs()
			inserted_disk = null
			usr.put_in_hands(ejected_disk)
			to_chat(usr, span_notice("Вы извлекли [ejected_disk] из [src]."))
			playsound(src, 'sound/machines/terminal_eject_disc.ogg', 50, TRUE)
			return TRUE

		if("PC_toggle_light")
			. = toggle_flashlight()
			if(.)
				playsound(src, 'sound/machines/terminal_button01.ogg', 25, TRUE)
			return .

		if("PC_light_color")
			var/mob/user = usr
			var/new_color
			while(!new_color)
				new_color = input(user, "Choose a new color for [src]'s flashlight.", "Light Color",light_color) as color|null
				if(!new_color)
					return
				if(color_hex2num(new_color) < 200) //Colors too dark are rejected
					to_chat(user, span_warning("That color is too dark! Choose a lighter one."))
					new_color = null
			return set_flashlight_color(new_color)

		if("PC_Eject_Disk")
			var/param = params["name"]
			var/mob/user = usr
			switch(param)
				if("removable storage disk")
					var/obj/item/computer_hardware/hard_drive/portable/portable_drive = all_components[MC_SDD]
					if(!portable_drive)
						return
					if(uninstall_component(portable_drive, usr))
						user.put_in_hands(portable_drive)
						playsound(src, 'sound/machines/card_slide.ogg', 50)
				if("intelliCard")
					var/obj/item/computer_hardware/ai_slot/intelliholder = all_components[MC_AI]
					if(!intelliholder)
						return
					if(intelliholder.try_eject(user))
						playsound(src, 'sound/machines/card_slide.ogg', 50)
				if("ID")
					var/obj/item/computer_hardware/card_slot/cardholder = all_components[MC_CARD]
					if(!cardholder)
						return
					cardholder.try_eject(user)
				if("secondary RFID card")
					var/obj/item/computer_hardware/card_slot/cardholder = all_components[MC_CARD2]
					if(!cardholder)
						return
					cardholder.try_eject(user)
		if("set_theme")
			var/mob/user = usr
			var/new_theme = params["theme"]
			if(!new_theme || !user?.client?.prefs)
				return
			device_theme = new_theme
			user.client.prefs.pda_theme = new_theme
			user.client.prefs.save_character()
			playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 25, FALSE)
			return TRUE

		if("set_pda_color")
			var/mob/user = usr
			var/new_color = params["color"]
			if(!new_color || !user?.client?.prefs)
				return
			user.client.prefs.pda_color = new_color
			user.client.prefs.save_character()
			pda_color = new_color
			return TRUE

		else
			return

/obj/item/modular_computer/ui_host()
	if(physical)
		return physical
	return src

/// Returns a hex color string for the current station security level.
/obj/item/modular_computer/proc/get_security_level_color()
	switch(GLOB.security_level)
		if(SEC_LEVEL_GREEN)
			return "#b2ff59"
		if(SEC_LEVEL_BLUE)
			return "#99ccff"
		if(SEC_LEVEL_ORANGE)
			return "#fc7d15"
		if(SEC_LEVEL_VIOLET)
			return "#a059fe"
		if(SEC_LEVEL_AMBER)
			return "#ffae42"
		if(SEC_LEVEL_RED)
			return "#ff3f34"
		if(SEC_LEVEL_LAMBDA)
			return "#ffae42"
		if(SEC_LEVEL_GAMMA)
			return "#7f7f7f"
		if(SEC_LEVEL_EPSILON)
			return "#ffffff"
		if(SEC_LEVEL_DELTA)
			return "#aa00ff"
	return "#ffffff"
