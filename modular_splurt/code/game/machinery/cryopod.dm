GLOBAL_VAR_INIT(cryo_next_admin_warning, 0) // The last time we told admins about a mapping / coding error because no cryo computer was found

/proc/cryo_find_control_computer(obj/machinery/cryopod/pod = null, urgent = FALSE)

	for(var/cryo_console as anything in GLOB.cryopod_computers)
		var/obj/machinery/computer/cryopod/console = cryo_console

		if(!pod) // No cryopod passed in, we will try to find the standard crew cryo computer instead.
			var/turf/console_turf = get_turf(console)
			// Не z == 2: станционный z-уровень зависит от набора карт (на Delta это 5), и
			// хардкод не находил экипажную крио-консоль вообще - авто-крио каждые пять минут
			// сыпало в админ-лог "could not find control computer!".
			if(console_turf && is_station_level(console_turf.z) && (!istype(get_area(console), /area/security/prison))) // NOT the prison cryo computer. Should get the standard crew cryo computer.
				return WEAKREF(console)
		else
			if(get_area(console) == get_area(pod))
				return WEAKREF(console)

	// Don't send messages unless we *need* the computer, and less than five minutes have passed since last time we messaged
	if(urgent && (world.time > GLOB.cryo_next_admin_warning))
		// Без pod оба поля пустые, и в логе оставалось "  in  could not find control computer!"
		var/pod_description = pod ? "\The [pod] in [get_area(pod)]" : "экипажная крио-консоль"
		log_admin("[pod_description] could not find control computer!")
		message_admins("[pod_description] could not find control computer!")
		GLOB.cryo_next_admin_warning = world.time + 5 MINUTES
