#define CREW_CRIT_CHECK_PERIOD (10 SECONDS)

/obj/machinery/computer/crew
	name = "crew monitoring console"
	desc = "Used to monitor active health sensors built into most of the crew's uniforms."
	icon_screen = "crew"
	icon_keyboard = "med_key"
	use_power = IDLE_POWER_USE
	idle_power_usage = 250
	active_power_usage = 500
	circuit = /obj/item/circuitboard/computer/crew
	light_color = LIGHT_COLOR_BLUE
	var/obj/item/radio/headset/radio = /obj/item/radio/headset/headset_med

/obj/machinery/computer/crew/Initialize()
	. = ..()
	if(radio)
		radio = new radio(src)
	GLOB.crew_sensor_monitors += src

/obj/machinery/computer/crew/Destroy()
	GLOB.crew_sensor_monitors -= src
	QDEL_NULL(radio)
	return ..()

/obj/machinery/computer/crew/proc/radioAnnounce(message)
	radio?.talk_into(src, message, MODE_DEPARTMENT)

// Данные собираются по запросу интерфейса; неиспользуемая консоль не будит SSmachines.

/obj/machinery/computer/crew/syndie
	icon_keyboard = "syndie_key"
	radio = null

/obj/machinery/computer/crew/ui_interact(mob/user, datum/tgui/ui)
	GLOB.crewmonitor.show(user,src)

GLOBAL_DATUM_INIT(crewmonitor, /datum/crewmonitor, new)
GLOBAL_DATUM_INIT(crewmonitor_security, /datum/crewmonitor/security, new)
GLOBAL_DATUM_INIT(crewmonitor_command, /datum/crewmonitor/command, new)
GLOBAL_DATUM_INIT(crewmonitor_siege, /datum/crewmonitor/siege, new)

/datum/crewmonitor
	var/list/ui_sources = list() //List of user -> ui source
	var/list/jobs
	var/list/data_by_z = list()
	var/list/last_update = list()
	var/selected_jobs = -1
	var/static/list/next_crit_alert = list()
	var/const/crit_check_cd_time = 120 SECONDS
	var/static/list/last_crit_check_by_z = list()
	var/list/maps_by_z = list()
	var/datum/minimap_group/cached_map_group

/datum/crewmonitor/New()
	. = ..()

	var/list/jobs = new/list()
	// Command
	jobs["Captain"] = 00
	jobs["Blueshield"] = 01
	jobs["Bridge Officer"] = 03
	// Security
	jobs["Head of Security"] = 10
	jobs["Warden"] = 11
	jobs["Security Officer"] = 12
	jobs["Detective"] = 13
	jobs["Brig Physician"] = 14
	jobs["Peacekeeper"] = 15
	jobs["Internal Affairs Agent"] = 16
	jobs["NanoTrasen Representative"] = 17
	// Medical
	jobs["Chief Medical Officer"] = 20
	jobs["Chemist"] = 21
	jobs["Geneticist"] = 22
	jobs["Virologist"] = 23
	jobs["Medical Doctor"] = 24
	jobs["Paramedic"] = 25
	// Science
	jobs["Research Director"] = 30
	jobs["Scientist"] = 31
	jobs["Roboticist"] = 32
	jobs["Vanguard Operative"] = 33 //BlueMoon edit
	// Engineering
	jobs["Chief Engineer"] = 40
	jobs["Station Engineer"] = 41
	jobs["Atmospheric Technician"] = 42
	// Cargo
	jobs["Quartermaster"] = 50
	jobs["Shaft Miner"] = 51
	jobs["Cargo Technician"] = 52
	// Service
	jobs["Head of Personnel"] = 60
	jobs["Bartender"] = 61
	jobs["Cook"] = 62
	jobs["Botanist"] = 63
	jobs["Curator"] = 64
	jobs["Chaplain"] = 65
	jobs["Clown"] = 66
	jobs["Mime"] = 67
	jobs["Janitor"] = 68
	jobs["Psychologist"] = 71
	jobs["Bouncer"] = 73
	jobs["Entertainer"] = 74 // BLUEMOON ADD
	// Central Command
	jobs["Admiral"] = 200
	jobs["CentCom Commander"] = 210
	jobs["Custodian"] = 211
	jobs["Medical Officer"] = 212
	jobs["Research Officer"] = 213
	jobs["Emergency Response Team Commander"] = 220
	jobs["Security Response Officer"] = 221
	jobs["Engineer Response Officer"] = 222
	jobs["Medical Response Officer"] = 223
	// Miscellaneous
	jobs["Assistant"] = 999 //Unknowns/custom jobs should appear after civilians, and before assistants

	src.jobs = jobs

/datum/crewmonitor/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if (!ui)
		var/list/map_assets = list()
		for(var/datum/minimap/floor_map as anything in SSminimaps.station_minimaps)
			map_assets += "minimap-[floor_map.id].png"
			if(floor_map.department_map_icon)
				map_assets += "minimap-[floor_map.id]-departments.png"
		SSassets.transport.send_assets(user, map_assets)
		ui = new(user, src, "CrewConsole")
		ui.open()

/datum/crewmonitor/proc/show(mob/M, source)
	ui_sources[M] = source
	ui_interact(M)

/datum/crewmonitor/ui_host(mob/user)
	return ui_sources[user]

/datum/crewmonitor/ui_close(mob/user)
	//запись живёт с show() до закрытия UI; без чистки глобальный синглтон
	//вечно держит и юзера, и источник (ИИ открывает консоль сам на себя)
	ui_sources -= user
	return ..()

/datum/crewmonitor/ui_data(mob/user)
	var/turf/user_turf = get_turf(ui_host(user)) || get_turf(user)
	. = list("sensors" = list(), "maps" = list(), "link_allowed" = isAI(user))
	if(!user_turf)
		return
	if(!is_hilbert_hotel_area(get_area(user_turf)))
		.["position"] = list("x" = user_turf.x, "y" = user_turf.y, "z" = user_turf.z)
	// Координаты общие для зрителей; направление вычисляет клиент без копий снимка.
	.["sensors"] = update_data(user_turf.z)
	check_critical_alerts(user_turf.z)
	.["z"] = user_turf.z
	var/list/monitored_levels = SSmapping.get_connected_levels(user_turf.z)
	.["maps"] = get_map_data(user_turf.z, monitored_levels)
	.["levels"] = monitored_levels

/datum/crewmonitor/proc/get_map_data(z, list/monitored_levels)
	if(cached_map_group != SSminimaps.station_minimap)
		cached_map_group = SSminimaps.station_minimap
		maps_by_z = list()
	if(maps_by_z["[z]"])
		return maps_by_z["[z]"]
	var/list/maps = list()
	for(var/datum/minimap/floor_map as anything in SSminimaps.station_minimaps)
		if(!(floor_map.z_level in monitored_levels))
			continue
		maps += list(floor_map.get_ui_data(monitored_levels.Find(floor_map.z_level)))
	for(var/level in monitored_levels)
		maps_by_z["[level]"] = maps
	return maps

/datum/crewmonitor/proc/update_data(z)
	if(data_by_z["[z]"] && world.time == last_update["[z]"])
		return data_by_z["[z]"]

	var/list/results_damaged = list()
	var/list/results_undamaged = list()

	var/obj/item/clothing/under/U
	var/obj/item/card/id/I
	var/turf/pos
	var/ijob
	var/name
	var/assignment
	var/oxydam
	var/toxdam
	var/burndam
	var/brutedam
	var/totaldam
	var/area
	var/pos_x
	var/pos_y
	var/pos_z
	var/life_status
	var/list/monitored_levels = SSmapping.get_connected_levels(z)

	for(var/mob/living/carbon/human/H as anything in GLOB.human_list)
		var/nanite_sensors = FALSE
		if(H in SSnanites.nanite_monitored_mobs)
			nanite_sensors = TRUE
		// Check if their z-level is correct and if they are wearing a uniform.
		// Accept H.z==0 as well in case the mob is inside an object.
		if ((H.z == 0 || (H.z in monitored_levels)) && istype(H.w_uniform, /obj/item/clothing/under) || nanite_sensors)
			U = H.w_uniform

			// Are the suit sensors on?
			if (nanite_sensors || ((U.has_sensor > 0) && U.sensor_mode))
				pos = H.z == 0 || (nanite_sensors || U.sensor_mode == SENSOR_COORDS) ? get_turf(H) : null

				// Special case: If the mob is inside an object confirm the z-level on turf level.
				if (H.z == 0 && (!pos || !(pos.z in monitored_levels)))
					continue

				var/hidden_location = is_hilbert_hotel_area(get_area(H))

				I = H.wear_id ? H.wear_id.GetID() : null
				if(!I)
					I = H.wear_neck ? H.wear_neck.GetID() : null

				if(I)
					assignment = I.get_assignment_name()
					ijob = jobs[GetJobName(I.assignment)]
				else
					assignment = ""
					ijob = 80

				name = I?.registered_name || H.name || "Unknown"

				if (selected_jobs != -1 && round(ijob / 10) - selected_jobs != 0)
					continue

				if (nanite_sensors || U.sensor_mode >= SENSOR_LIVING)
					life_status = H.stat != DEAD
				else
					life_status = null

				if (nanite_sensors || U.sensor_mode >= SENSOR_VITALS)
					oxydam = round(H.getOxyLoss(),1)
					toxdam = round(H.getToxLoss(),1)
					burndam = round(H.getFireLoss(),1)
					brutedam = round(H.getBruteLoss(),1)
					totaldam = oxydam + toxdam + burndam + brutedam
				else
					oxydam = null
					toxdam = null
					burndam = null
					brutedam = null
					totaldam = 0

				if (nanite_sensors || U.sensor_mode >= SENSOR_COORDS)
					if (!pos)
						pos = get_turf(H)
					if(hidden_location)
						area = "Hilbert Hotel"
					else
						area = get_area_name(H, TRUE)
					// Координаты отеля не отправляются клиенту, включая нанитные датчики.
					pos_x = hidden_location ? null : pos.x
					pos_y = hidden_location ? null : pos.y
					pos_z = hidden_location ? null : pos.z
				else
					area = null
					pos_x = null
					pos_y = null
					pos_z = null

				var/total_list = list("id" = H.UID(), "name" = name, "assignment" = assignment, "ijob" = ijob, "life_status" = life_status, "oxydam" = oxydam, "toxdam" = toxdam, "burndam" = burndam, "brutedam" = brutedam, "totaldam" = totaldam, "area" = area, "pos_x" = pos_x, "pos_y" = pos_y, "pos_z" = pos_z, "floor" = pos_z ? (monitored_levels.Find(pos_z) || SSmapping.get_connected_levels(pos_z).Find(pos_z)) : null, "can_track" = !hidden_location && H.can_track(null))

				if(totaldam)
					results_damaged[++results_damaged.len] = total_list
				else
					results_undamaged[++results_undamaged.len] = total_list

	var/list/returning = sortTim(results_damaged,GLOBAL_PROC_REF(damage_compare)) + sortTim(results_undamaged,GLOBAL_PROC_REF(ijob_compare))

	// Один снимок на текущий тик для всей связки этажей.
	for(var/level in monitored_levels)
		data_by_z["[level]"] = returning
		last_update["[level]"] = world.time

	return returning

/proc/ijob_compare(list/a,list/b)
	return a["ijob"] - b["ijob"]

// Проверка рации не задерживает данные интерфейса и общая для всех мониторов связки.
/datum/crewmonitor/proc/check_critical_alerts(z)
	var/list/monitored_levels = SSmapping.get_connected_levels(z)
	var/check_key = "[monitored_levels[1]]"
	if(!isnull(last_crit_check_by_z[check_key]) && world.time < last_crit_check_by_z[check_key] + CREW_CRIT_CHECK_PERIOD)
		return
	last_crit_check_by_z[check_key] = world.time
	for(var/datum/weakref/patient_ref as anything in next_crit_alert)
		if(!patient_ref.resolve())
			next_crit_alert -= patient_ref
	var/list/terminals = list()
	var/obj/machinery/computer/crew/radio_terminal
	for(var/obj/machinery/computer/crew/terminal as anything in GLOB.crew_sensor_monitors)
		if(!(terminal.z in monitored_levels) || !terminal.is_operational())
			continue
		terminals += terminal
		if(!radio_terminal && terminal.radio)
			radio_terminal = terminal
	if(!length(terminals))
		return
	for(var/mob/living/carbon/human/patient as anything in GLOB.human_list)
		var/obj/item/clothing/under/uniform = patient.w_uniform
		var/nanite_sensors = (patient in SSnanites.nanite_monitored_mobs)
		if(!nanite_sensors && (!istype(uniform) || uniform.has_sensor <= 0 || uniform.sensor_mode < SENSOR_VITALS))
			continue
		var/turf/position = get_turf(patient)
		if(!position || !(position.z in monitored_levels))
			continue
		var/datum/weakref/patient_ref = WEAKREF(patient)
		if(next_crit_alert[patient_ref] > world.time)
			continue
		var/total_damage = round(patient.getOxyLoss(), 1) + round(patient.getToxLoss(), 1) + round(patient.getFireLoss(), 1) + round(patient.getBruteLoss(), 1)
		if(total_damage <= 75)
			continue
		next_crit_alert[patient_ref] = world.time + crit_check_cd_time + rand(0, 15) SECONDS
		for(var/obj/machinery/computer/crew/terminal as anything in terminals)
			playsound(terminal, 'sound/machines/twobeep.ogg', 80, FALSE)
			terminal.say("Обнаружен пациент в критическом состоянии!")
		if(!radio_terminal)
			continue
		var/obj/item/card/id/card = patient.wear_id?.GetID() || patient.wear_neck?.GetID()
		var/patient_name = card?.registered_name || patient.name
		var/assignment = card ? card.get_assignment_name() : "Неизвестно"
		// Рация тоже не раскрывает конкретную комнату отеля.
		var/area_name = is_hilbert_hotel_area(get_area(position)) ? "Hilbert Hotel" : get_area_name(patient, TRUE)
		var/area_message = (nanite_sensors || uniform.sensor_mode >= SENSOR_COORDS) ? " в [area_name]" : ""
		radio_terminal.radioAnnounce("КРИТИЧЕСКОЕ СОСТОЯНИЕ: [patient_name] ([assignment])[area_message]")

/proc/damage_compare(list/a,list/b)
	return b["totaldam"] - a["totaldam"]

/datum/crewmonitor/ui_act(action,params)
	. = ..()
	if(.)
		return
	var/mob/living/silicon/ai/AI = usr
	if(!istype(AI))
		return
	switch (action)
		if ("select_person")
			var/turf/position = get_turf(ui_host(AI)) || get_turf(AI)
			if(!position)
				return
			for(var/list/sensor as anything in update_data(position.z))
				if(sensor["id"] == params["id"] && sensor["can_track"])
					var/mob/living/carbon/human/target = locateUID(sensor["id"])
					if(istype(target) && !is_hilbert_hotel_area(get_area(target)))
						AI.ai_actual_track(target)
					break

/datum/crewmonitor/security
	selected_jobs = 1

/datum/crewmonitor/command
	selected_jobs = 6

/datum/crewmonitor/command/New()
	. = ..()

	var/list/jobs = new/list()
	// Command
	jobs["Captain"] = 60
	jobs["NanoTrasen Representative"] = 61
	jobs["Head of Personnel"] = 62
	jobs["Bridge Officer"] = 63
	jobs["Head of Security"] = 64
	jobs["Chief Medical Officer"] = 65
	jobs["Research Director"] = 66
	jobs["Chief Engineer"] = 67
	jobs["Quartermaster"] = 68
	jobs["Blueshield"] = 69

	src.jobs = jobs

/datum/crewmonitor/siege
	selected_jobs = -1

/datum/crewmonitor/siege/update_data(z)
	if(data_by_z["[z]"] && world.time == last_update["[z]"])
		return data_by_z["[z]"]

	var/list/results_damaged = list()
	var/list/results_undamaged = list()

	var/obj/item/clothing/under/U
	var/turf/pos
	var/name
	var/oxydam
	var/toxdam
	var/burndam
	var/brutedam
	var/totaldam
	var/area
	var/pos_x
	var/pos_y
	var/pos_z
	var/life_status
	var/list/monitored_levels = SSmapping.get_connected_levels(z)

	for(var/mob/living/carbon/human/H as anything in GLOB.human_list)
		if(!HAS_TRAIT(H, TRAIT_PACT_SIEGE_DEFENDER))
			continue
		if(H.z != 0 && !(H.z in monitored_levels))
			continue
		if(!istype(H.w_uniform, /obj/item/clothing/under))
			continue
		U = H.w_uniform
		if(U.has_sensor <= 0 || !U.sensor_mode)
			continue

		pos = U.sensor_mode == SENSOR_COORDS ? get_turf(H) : null
		if(H.z == 0 && (!pos || !(pos.z in monitored_levels)))
			continue

		var/hidden_location = is_hilbert_hotel_area(get_area(H))
		name = H.name || "Unknown"

		if(U.sensor_mode >= SENSOR_LIVING)
			life_status = H.stat != DEAD
		else
			life_status = null

		if(U.sensor_mode >= SENSOR_VITALS)
			oxydam = round(H.getOxyLoss(), 1)
			toxdam = round(H.getToxLoss(), 1)
			burndam = round(H.getFireLoss(), 1)
			brutedam = round(H.getBruteLoss(), 1)
			totaldam = oxydam + toxdam + burndam + brutedam
		else
			oxydam = null
			toxdam = null
			burndam = null
			brutedam = null
			totaldam = 0

		if(U.sensor_mode >= SENSOR_COORDS)
			if(!pos)
				pos = get_turf(H)
			area = hidden_location ? "Hilbert Hotel" : get_area_name(H, TRUE)
			pos_x = hidden_location ? null : pos.x
			pos_y = hidden_location ? null : pos.y
			pos_z = hidden_location ? null : pos.z
		else
			area = null
			pos_x = null
			pos_y = null
			pos_z = null

		var/total_list = list("id" = H.UID(), "name" = name, "assignment" = "Защитник", "ijob" = 0, "life_status" = life_status, "oxydam" = oxydam, "toxdam" = toxdam, "burndam" = burndam, "brutedam" = brutedam, "totaldam" = totaldam, "area" = area, "pos_x" = pos_x, "pos_y" = pos_y, "pos_z" = pos_z, "floor" = pos_z ? (monitored_levels.Find(pos_z) || SSmapping.get_connected_levels(pos_z).Find(pos_z)) : null, "can_track" = !hidden_location && H.can_track(null))

		if(totaldam)
			results_damaged[++results_damaged.len] = total_list
		else
			results_undamaged[++results_undamaged.len] = total_list

	var/list/returning = sortTim(results_damaged, GLOBAL_PROC_REF(damage_compare)) + sortTim(results_undamaged, GLOBAL_PROC_REF(ijob_compare))

	// Один снимок на текущий тик для всей связки этажей.
	for(var/level in monitored_levels)
		data_by_z["[level]"] = returning
		last_update["[level]"] = world.time

	return returning

GLOBAL_LIST_EMPTY(crew_sensor_monitors)

#undef CREW_CRIT_CHECK_PERIOD
