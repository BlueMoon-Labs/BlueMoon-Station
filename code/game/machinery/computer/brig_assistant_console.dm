/**
 * Brig Assistant Tasks Console
 * TGUI console for assistants to take tasks - primarily hanging wanted posters.
 * Tasks have 5 min cooldown per criminal, max 3 identical tasks per assistant.
 * When criminal is caught (status changed), new task: remove their posters.
 */

GLOBAL_LIST_EMPTY(brig_assistant_remove_tasks) // ckey -> list of criminal_ids (active remove poster tasks)

#define WANTED_POSTER_COOLDOWN (5 MINUTES)
#define WANTED_POSTER_MAX_PER_ASSISTANT 3
#define WANTED_POSTER_MAX_PER_AREA 2
/// Только статусы «обработан в СБ» — иначе в списке окажется весь экипаж с «Ничего» раундстартом
#define BRIG_ASSISTANT_REMOVE_POSTER_STATUSES list(SEC_RECORD_STATUS_INCARCERATED, SEC_RECORD_STATUS_RELEASED, SEC_RECORD_STATUS_PAROLLED, SEC_RECORD_STATUS_DISCHARGED, SEC_RECORD_STATUS_DEMOTE)

/obj/machinery/computer/brig_assistant_console
	name = "Консоль заданий брига"
	desc = "Консоль для выдачи заданий. В первую очередь - развешивание плакатов с разыскиваемыми."
	icon_screen = "security"
	icon_keyboard = "security_key"
	circuit = /obj/item/circuitboard/computer/brig_assistant_console
	req_access = list() // В бриге, доступ для ассистентов (у них обычно нет ACCESS_BRIG)
	light_color = LIGHT_COLOR_RED

	/// ckey -> criminal_id -> list of take timestamps (hang poster tasks)
	var/static/list/assistant_task_takes = list()

/obj/machinery/computer/brig_assistant_console/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	add_fingerprint(user)
	ui_interact(user)

/obj/machinery/computer/brig_assistant_console/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "BrigAssistantConsole", name)
		ui.open()

/obj/machinery/computer/brig_assistant_console/ui_data(mob/user)
	var/list/data = list()
	var/list/wanted_list = list()

	for(var/datum/data/record/S in GLOB.data_core.security)
		var/status = S.fields["criminal"]
		if(!(status in list(SEC_RECORD_STATUS_ARREST, SEC_RECORD_STATUS_SEARCH, SEC_RECORD_STATUS_EXECUTE)))
			continue

		var/datum/data/record/G = find_record("name", S.fields["name"], GLOB.data_core.general)
		if(!G)
			continue

		var/criminal_id = S.fields["id"]
		var/ckey = user?.ckey
		var/can_take = FALSE
		var/reason = ""
		var/takes_count = 0

		if(!ckey)
			reason = "Требуется авторизация"
		else
			var/list/takes = assistant_task_takes[ckey]
			if(!takes)
				takes = list()
				assistant_task_takes[ckey] = takes

			var/list/criminal_takes = takes[criminal_id]
			if(!criminal_takes)
				criminal_takes = list()
				takes[criminal_id] = criminal_takes

			// Remove old entries (older than cooldown)
			for(var/i in criminal_takes.len to 1 step -1)
				if(world.time - criminal_takes[i] > WANTED_POSTER_COOLDOWN)
					criminal_takes.Cut(i, i + 1)

			takes_count = criminal_takes.len

			if(criminal_takes.len >= WANTED_POSTER_MAX_PER_ASSISTANT)
				reason = "Достигнут лимит ([WANTED_POSTER_MAX_PER_ASSISTANT] на человека)"
			else if(criminal_takes.len > 0)
				var/last_take = criminal_takes[criminal_takes.len]
				var/time_left = (last_take + WANTED_POSTER_COOLDOWN) - world.time
				if(time_left > 0)
					reason = "КД: [round(time_left / 10)] сек"
				else
					can_take = TRUE
			else
				can_take = TRUE

		var/has_photo = (G.fields["photo_front"] || G.fields["photo_side"]) ? TRUE : FALSE

		wanted_list += list(list(
			"id" = criminal_id,
			"name" = S.fields["name"],
			"status" = status,
			"can_take" = can_take,
			"reason" = reason,
			"has_photo" = has_photo,
			"takes_count" = takes_count,
		))

	data["wanted"] = wanted_list

	// Снятие плакатов — только после смены статуса в консоли СБ (не «Ничего» и не «Наблюдать»)
	var/list/remove_list = list()
	for(var/datum/data/record/S in GLOB.data_core.security)
		var/status = S.fields["criminal"]
		if(!(status in BRIG_ASSISTANT_REMOVE_POSTER_STATUSES))
			continue
		var/criminal_id = S.fields["id"]
		var/ckey = user?.ckey
		var/has_remove_task = FALSE
		if(ckey)
			var/list/remove_tasks = GLOB.brig_assistant_remove_tasks[ckey]
			has_remove_task = remove_tasks && (criminal_id in remove_tasks)

		remove_list += list(list(
			"id" = criminal_id,
			"name" = S.fields["name"],
			"status" = status,
			"has_task" = has_remove_task,
		))

	data["remove"] = remove_list
	return data

/obj/machinery/computer/brig_assistant_console/ui_act(action, params)
	. = ..()
	if(.)
		return

	var/mob/user = usr

	switch(action)
		if("take_task")
			var/criminal_id = params["id"]
			if(!criminal_id)
				return

			var/datum/data/record/S = find_security_record("id", criminal_id)
			if(!S || !(S.fields["criminal"] in list(SEC_RECORD_STATUS_ARREST, SEC_RECORD_STATUS_SEARCH, SEC_RECORD_STATUS_EXECUTE)))
				to_chat(user, span_warning("Запись не найдена или преступник больше не в розыске."))
				return

			var/datum/data/record/G = find_record("name", S.fields["name"], GLOB.data_core.general)
			if(!G)
				to_chat(user, span_warning("Общая запись не найдена."))
				return

			var/ckey = user.ckey
			if(!ckey)
				return

			var/list/takes = assistant_task_takes[ckey]
			if(!takes)
				takes = list()
				assistant_task_takes[ckey] = takes

			var/list/criminal_takes = takes[criminal_id]
			if(!criminal_takes)
				criminal_takes = list()
				takes[criminal_id] = criminal_takes

			// Remove expired
			for(var/i in criminal_takes.len to 1 step -1)
				if(world.time - criminal_takes[i] > WANTED_POSTER_COOLDOWN)
					criminal_takes.Cut(i, i + 1)

			if(criminal_takes.len >= WANTED_POSTER_MAX_PER_ASSISTANT)
				to_chat(user, span_warning("Вы уже взяли максимум заданий на этого преступника."))
				return

			if(criminal_takes.len > 0)
				var/last_take = criminal_takes[criminal_takes.len]
				if(world.time - last_take < WANTED_POSTER_COOLDOWN)
					to_chat(user, span_warning("Подождите ещё [round((last_take + WANTED_POSTER_COOLDOWN - world.time) / 10)] секунд."))
					return

			// Create poster
			var/obj/item/photo/photo = G.fields["photo_front"] || G.fields["photo_side"]
			var/icon/person_icon
			if(photo && photo.picture && photo.picture.picture_image)
				person_icon = photo.picture.picture_image
			else
				person_icon = icon('icons/mob/simple_human.dmi', "generic")

			var/wanted_name = S.fields["name"]
			var/default_description = "A poster declaring [wanted_name] to be a dangerous individual, wanted by Nanotrasen. Report any sightings to security immediately."
			var/list/major_crimes = S.fields["ma_crim"]
			var/list/minor_crimes = S.fields["mi_crim"]
			if(length(major_crimes) + length(minor_crimes))
				default_description += "\n[wanted_name] is wanted for the following crimes:\n"
			if(length(minor_crimes))
				default_description += "\nMinor Crimes:"
				for(var/datum/data/crime/c in minor_crimes)
					default_description += "\n[c.crimeName]\n[c.crimeDetails]\n"
			if(length(major_crimes))
				default_description += "\nMajor Crimes:"
				for(var/datum/data/crime/c in major_crimes)
					default_description += "\n[c.crimeName]\n[c.crimeDetails]\n"

			playsound(loc, 'sound/items/poster_being_created.ogg', 100, 1)
			var/obj/item/poster/wanted/P = new(loc, person_icon, wanted_name, default_description)
			P.poster_id = criminal_id
			if(P.poster_structure)
				P.poster_structure.poster_id = criminal_id
			user.put_in_hands(P)

			criminal_takes += world.time
			to_chat(user, span_notice("Вы взяли задание: развесить плакат по [wanted_name]. Не более [WANTED_POSTER_MAX_PER_AREA] плакатов в одной зоне."))
			return TRUE

		if("take_remove_task")
			var/criminal_id = params["id"]
			if(!criminal_id)
				return

			var/datum/data/record/S = find_security_record("id", criminal_id)
			if(!S)
				to_chat(user, span_warning("Запись не найдена."))
				return
			if(S.fields["criminal"] in list(SEC_RECORD_STATUS_ARREST, SEC_RECORD_STATUS_SEARCH, SEC_RECORD_STATUS_EXECUTE))
				to_chat(user, span_warning("Этот человек ещё в розыске - снимайте плакаты только после поимки."))
				return
			if(!(S.fields["criminal"] in BRIG_ASSISTANT_REMOVE_POSTER_STATUSES))
				to_chat(user, span_warning("Задание на снятие доступно только после смены статуса в консоли СБ (тюрьма, выпуск, УДО и т.п.)."))
				return

			var/ckey = user.ckey
			if(!ckey)
				return

			var/list/remove_tasks = GLOB.brig_assistant_remove_tasks[ckey]
			if(!remove_tasks)
				remove_tasks = list()
				GLOB.brig_assistant_remove_tasks[ckey] = remove_tasks

			if(criminal_id in remove_tasks)
				to_chat(user, span_warning("Вы уже взяли это задание."))
				return

			remove_tasks += criminal_id
			to_chat(user, span_notice("Вы взяли задание: снять плакаты с [S.fields["name"]]. Используйте кусачки на плакате для снятия. Награда: 75-100 кредитов."))
			return TRUE

	return FALSE
