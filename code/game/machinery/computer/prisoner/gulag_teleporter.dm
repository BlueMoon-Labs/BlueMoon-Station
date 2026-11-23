//computer that handle the points and teleports the prisoner
/obj/machinery/computer/prisoner/gulag_teleporter_computer
	name = "labor camp teleporter console"
	desc = "Консоль, используемая для отправки преступников в Лагерь принудительных работ."
	icon_screen = "explosive"
	icon_keyboard = "security_key"
	req_access = list(ACCESS_BRIG) // Доступ Брига
	circuit = /obj/item/circuitboard/computer/gulag_teleporter_console

	var/default_goal = 200
	var/obj/machinery/gulag_teleporter/teleporter = null
	var/obj/structure/gulag_beacon/beacon = null
	var/mob/living/carbon/human/prisoner = null
	var/datum/data/record/temporary_record = null

	light_color = LIGHT_COLOR_RED

/obj/machinery/computer/prisoner/gulag_teleporter_computer/Initialize(mapload)
	. = ..()
	scan_machinery()

/obj/machinery/computer/prisoner/gulag_teleporter_computer/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "GulagTeleporterConsole", name)
		ui.open()

/obj/machinery/computer/prisoner/gulag_teleporter_computer/ui_data(mob/user)
	var/list/data = list()

	var/list/prisoner_list = list()
	var/can_teleport = FALSE

	if(teleporter && (teleporter.occupant && ishuman(teleporter.occupant)))
		prisoner = teleporter.occupant
		prisoner_list["name"] = prisoner.real_name
		if(contained_id)
			can_teleport = TRUE
		if(!isnull(GLOB.data_core.security))
			for(var/r in GLOB.data_core.security)
				var/datum/data/record/R = r
				if(R.fields["name"] == prisoner_list["name"])
					temporary_record = R
					prisoner_list["crimstat"] = temporary_record.fields["criminal"]

	data["prisoner"] = prisoner_list

	if(teleporter)
		data["teleporter"] = teleporter
		data["teleporter_location"] = "([teleporter.x], [teleporter.y], [teleporter.z])"
		data["teleporter_lock"] = teleporter.locked
		data["teleporter_state_open"] = teleporter.state_open
	else
		data["teleporter"] = null
	if(beacon)
		data["beacon"] = beacon
		data["beacon_location"] = "([beacon.x], [beacon.y], [beacon.z])"
	else
		data["beacon"] = null
	if(contained_id)
		data["id"] = contained_id
		data["id_name"] = contained_id.registered_name
		data["goal"] = contained_id.goal
	else
		data["id"] = null
	data["can_teleport"] = can_teleport

	return data

/obj/machinery/computer/prisoner/gulag_teleporter_computer/ui_act(action, list/params)
	if(isliving(usr))
		playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 50, FALSE)
	if(..())
		return
	if(!allowed(usr))
		to_chat(usr, "<span class='warning'>Доступ запрещён.</span>")
		return
	switch(action)
		if("scan_teleporter")
			teleporter = findteleporter()
			return TRUE
		if("scan_beacon")
			beacon = findbeacon()
			return TRUE
		if("handle_id")
			if(contained_id)
				id_eject(usr)
			else
				id_insert(usr)
			return TRUE
		if("set_goal")
			if(!contained_id)
				return
			var/new_goal = text2num(params["value"])
			if(!isnum(new_goal))
				return
			if(!new_goal)
				new_goal = default_goal
			contained_id.goal = clamp(new_goal, 0, 10000)
			return TRUE
		if("toggle_open")
			if(!teleporter)
				return
			if(teleporter.locked)
				to_chat(usr, "<span class='alert'>Сначала телепорт должен быть разблокирован.</span>")
				return
			teleporter.toggle_open(usr)
			return TRUE
		if("teleporter_lock")
			if(!teleporter)
				return
			if(teleporter.state_open)
				to_chat(usr, "<span class='alert'>Сначала телепорт должен быть закрыт.</span>")
				return
			teleporter.locked = !teleporter.locked
			return TRUE
		if("teleport")
			if(!teleporter || !beacon)
				return
			addtimer(CALLBACK(src, PROC_REF(teleport), usr), 5)
			return TRUE

/obj/machinery/computer/prisoner/gulag_teleporter_computer/proc/scan_machinery()
	teleporter = findteleporter()
	beacon = findbeacon()

/obj/machinery/computer/prisoner/gulag_teleporter_computer/proc/findteleporter()
	for(var/obj/machinery/gulag_teleporter/T in range(1, src))
		if(T.is_operational())
			return T
	return null

/obj/machinery/computer/prisoner/gulag_teleporter_computer/proc/findbeacon()
	return locate(/obj/structure/gulag_beacon)

/obj/machinery/computer/prisoner/gulag_teleporter_computer/proc/teleport(mob/user)
	if(!contained_id)
		say("Внимание: Невозможно отправить заключенного без действительной ID-карты!")
		return
	if(!teleporter || !beacon) // Проверка на уничтожение
		say("Внимание: Связь с телепортом или маяком потеряна!")
		return
	if(!teleporter.is_operational())
		say("Внимание: Телепорт неисправен!")
		return

	if(!teleporter.occupant || !ishuman(teleporter.occupant))
		say("Внимание: В телепорте не обнаружен заключенный!")
		return

	prisoner = teleporter.occupant

	temporary_record = null
	if(!isnull(GLOB.data_core.security))
		for(var/r in GLOB.data_core.security)
			var/datum/data/record/R = r
			if(R.fields["name"] == prisoner.real_name)
				temporary_record = R
				break

	if(temporary_record)
		temporary_record.set_security_status(SEC_RECORD_STATUS_INCARCERATED)

	var/id_goal_not_set
	if(!contained_id.goal)
		id_goal_not_set = TRUE
		contained_id.goal = default_goal
		say("Цель ID-карты [contained_id] по умолчанию установлена на [contained_id.goal] очков.")

	log_game("[key_name(user)] teleported [key_name(prisoner)] to the Labor Camp [COORD(beacon)] for [id_goal_not_set ? "default goal of ":""][contained_id.goal] points.")

	teleporter.handle_prisoner(contained_id, temporary_record)
	playsound(src, 'sound/weapons/emitter.ogg', 50, TRUE)

	prisoner.forceMove(get_turf(beacon))
	prisoner.Stun(40)
	to_chat(prisoner, "<span class='warning'>Телепортация вызывает у вас легкое головокружение.</span>")
	new /obj/effect/particle_effect/sparks(get_turf(prisoner))
	playsound(src, "sparks", 50, TRUE)

	if(teleporter.locked)
		teleporter.locked = FALSE
	teleporter.toggle_open()
	contained_id = null
	temporary_record = null
