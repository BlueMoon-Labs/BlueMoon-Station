/obj/machinery/computer/prisoner/management
	name = "Prisoner Management Console"
	idle_sleeps = FALSE // собственная периодическая работа в process(): не должен засыпать через родительский индикатор набора текста
	desc = "Используется для управления имплантами слежения, вживлёнными в преступников."
	icon_screen = "explosive"
	icon_keyboard = "security_key"
	req_access = list(ACCESS_BRIG)
	var/id = 0
	var/temp = null
	var/status = 0
	var/timeleft = 60
	var/stop = 0
	var/screen = 0 // 0 - доступ запрещён, 1 - доступ разрешён
	circuit = /obj/item/circuitboard/computer/prisoner

	light_color = LIGHT_COLOR_RED

/obj/machinery/computer/prisoner/management/New()
	GLOB.prisoncomputer_list += src
	return ..()

/obj/machinery/computer/prisoner/management/Destroy()
	GLOB.prisoncomputer_list -= src
	return ..()

/obj/machinery/computer/prisoner/management/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PrisonerManagementConsole", name)
		if(isliving(user))
			playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 50, FALSE)
		ui.open()

/obj/machinery/computer/prisoner/management/ui_data(mob/user)
	var/list/data = list()
	data["logged_in"] = screen

	if(!screen)
		data["has_id"] = FALSE
		data["id_name"] = null
		data["id_points"] = 0
		data["id_goal"] = 0
		data["chem_implants"] = list()
		data["tracking_implants"] = list()
		return data

	if(contained_id)
		data["has_id"] = TRUE
		data["id_name"] = "[contained_id]"
		data["id_points"] = contained_id.points
		data["id_goal"] = contained_id.goal
	else
		data["has_id"] = FALSE
		data["id_name"] = null
		data["id_points"] = 0
		data["id_goal"] = 0

	var/turf/Tr = null
	var/list/chem_implants = list()
	for(var/obj/item/implant/chem/C in GLOB.tracked_chem_implants)
		if(!C.imp_in)
			continue
		Tr = get_turf(C.imp_in)
		if(Tr && Tr.z != z)
			continue
		chem_implants += list(list(
			"ref" = REF(C),
			"name" = C.imp_in.name,
			"units" = C.reagents.total_volume,
		))
	data["chem_implants"] = chem_implants

	var/list/tracking_implants = list()
	for(var/obj/item/implant/tracking/T in GLOB.tracked_implants)
		if(!T.imp_in || !isliving(T.imp_in))
			continue
		Tr = get_turf(T.imp_in)
		if(!Tr || Tr.z != z)
			continue
		var/loc_display = "Неизвестно"
		var/mob/living/M = T.imp_in
		if(is_station_level(Tr.z) && !isspaceturf(M.loc))
			var/turf/mob_loc = get_turf(M)
			loc_display = "[mob_loc.loc]"
		tracking_implants += list(list(
			"ref" = REF(T),
			"name" = M.name,
			"location" = loc_display,
		))
	data["tracking_implants"] = tracking_implants

	return data

/obj/machinery/computer/prisoner/management/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	var/mob/user = usr

	switch(action)
		if("login")
			if(screen)
				return
			if(!allowed(user))
				to_chat(user, "<span class='danger'>Доступ запрещён.</span>")
				return
			screen = TRUE
			playsound(src, 'sound/machines/terminal_on.ogg', 50, FALSE)
			return TRUE
		if("logout")
			if(!screen)
				return
			screen = FALSE
			playsound(src, 'sound/machines/terminal_on.ogg', 50, FALSE)
			return TRUE

	if(!screen)
		return

	if(isliving(user))
		playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 50, FALSE)

	switch(action)
		if("id_insert")
			if(contained_id)
				return
			var/obj/item/card/id/inserted_id = user.get_active_held_item()
			if(!istype(inserted_id, /obj/item/card/id/prisoner))
				to_chat(user, "<span class='warning'>Для вставки нужно держать ID заключённого в руке.</span>")
				return
			id_insert(user, inserted_id)
			return TRUE
		if("id_eject")
			if(!contained_id)
				return
			id_eject(user)
			return TRUE
		if("id_reset")
			if(!contained_id)
				return
			contained_id.points = 0
			return TRUE
		if("id_setgoal")
			if(!contained_id)
				return
			var/num = tgui_input_number(user, "Выберите цель заключённого:", "Введите целое число", contained_id.goal, max_value = 1000, min_value = 0, round_value = TRUE)
			if(!isnull(num))
				contained_id.goal = num
			return TRUE
		if("inject")
			var/obj/item/implant/chem/chem_implant = locate(params["ref"]) in GLOB.tracked_chem_implants
			if(!istype(chem_implant))
				return
			var/amount = text2num(params["amount"])
			if(!amount || amount <= 0)
				return
			chem_implant.activate(amount)
			return TRUE
		if("warn")
			var/warning = tgui_input_text(user, "Сообщение:", "Введите сообщение", max_length = MAX_MESSAGE_LEN, encode = TRUE)
			if(!warning)
				return
			var/obj/item/implant/track_implant = locate(params["ref"]) in GLOB.tracked_implants
			if(!istype(track_implant) || !track_implant.imp_in)
				return
			var/mob/living/R = track_implant.imp_in
			to_chat(R, "<span class='italics'>Вы слышите голос в голове: '[warning]'</span>")
			log_directed_talk(user, R, warning, LOG_SAY, "сообщение через имплант")
			return TRUE

/obj/machinery/computer/prisoner/management/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/card/id))
		if(screen)
			id_insert(user, I)
		else
			to_chat(user, "<span class='danger'>Доступ запрещён.</span>")
		return
	return ..()

/obj/machinery/computer/prisoner/management/process()
	. = ..()
	SStgui.update_uis(src)
	return
