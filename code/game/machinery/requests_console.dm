/******************** Requests Console ********************/
/** Originally written by errorage, updated by: Carn, needs more work though. I just added some security fixes */

GLOBAL_LIST_EMPTY(req_console_assistance)
GLOBAL_LIST_EMPTY(req_console_supplies)
GLOBAL_LIST_EMPTY(req_console_information)
GLOBAL_LIST_EMPTY(allConsoles)

#define NO_NEW_MESSAGE				0
#define NORMAL_MESSAGE_PRIORITY 	1
#define HIGH_MESSAGE_PRIORITY		2
#define EXTREME_MESSAGE_PRIORITY	3 // is implimented, does require hacking. everything needs to have a hidden feature in this game.

/obj/machinery/requests_console
	name = "requests console"
	desc = "A console intended to send requests to different departments on the station."
	icon = 'icons/obj/terminals.dmi'
	icon_state = "req_comp0"
	plane = ABOVE_WALL_PLANE
	var/department = "Unknown" //The list of all departments on the station (Determined from this variable on each unit) Set this to the same thing if you want several consoles in one department
	var/list/messages = list() //List of all messages
	var/departmentType = 0
		// 0 = none (not listed, can only replied to)
		// 1 = assistance
		// 2 = supplies
		// 3 = info
		// 4 = ass + sup //Erro goddamn you just HAD to shorten "assistance" down to "ass"
		// 5 = ass + info
		// 6 = sup + info
		// 7 = ass + sup + info
	var/newmessagepriority = NO_NEW_MESSAGE
	var/screen = 0
		// 0 = main menu,
		// 1 = req. assistance,
		// 2 = req. supplies
		// 3 = relay information
		// 4 = write msg - not used
		// 5 = choose priority - not used
		// 6 = sent successfully
		// 7 = sent unsuccessfully
		// 8 = view messages
		// 9 = authentication before sending
		// 10 = send announcement
	var/silent = FALSE // set to 1 for it not to beep all the time
	var/hackState = FALSE
	var/announcementConsole = FALSE // FALSE = This console cannot be used to send department announcements, TRUE = This console can send department announcements
	var/open = FALSE // TRUE if open
	var/announceAuth = FALSE //Will be set to 1 when you authenticate yourself for announcements
	var/msgVerified = "" //Will contain the name of the person who verified it
	var/msgStamped = "" //If a message is stamped, this will contain the stamp name
	var/message = ""
	var/dpt = "" //the department which will be receiving the message
	var/priority = NORMAL_MESSAGE_PRIORITY //Priority of the message being sent. why is the default -1??
	var/obj/item/radio/Radio
	var/emergency //If an emergency has been called by this device. Acts as both a cooldown and lets the responder know where it the emergency was triggered from
	var/receive_ore_updates = FALSE //If ore redemption machines will send an update when it receives new ores.
	max_integrity = 300
	armor_type = /datum/armor/requests_console

/obj/machinery/requests_console/power_change()
	..()
	update_icon()

/obj/machinery/requests_console/update_icon_state()
	if((machine_stat & NOPOWER))
		set_light(0)
	else
		set_light(1.4, 0.7, "#34D352")//green light

	if(open)
		if(!hackState)
			icon_state="req_comp_open"
		else
			icon_state="req_comp_rewired"
	else if((machine_stat & NOPOWER))
		if(icon_state != "req_comp_off")
			icon_state = "req_comp_off"
	else
		if(emergency || (newmessagepriority == EXTREME_MESSAGE_PRIORITY))
			icon_state = "req_comp3"
		else if(newmessagepriority == HIGH_MESSAGE_PRIORITY)
			icon_state = "req_comp2"
		else if(newmessagepriority == NORMAL_MESSAGE_PRIORITY)
			icon_state = "req_comp1"
		else
			icon_state = "req_comp0"

/obj/machinery/requests_console/Initialize(mapload)
	. = ..()
	name = "\improper [department] requests console"
	GLOB.allConsoles += src
	switch(departmentType)
		if(1)
			if(!("[department]" in GLOB.req_console_assistance))
				GLOB.req_console_assistance += department
		if(2)
			if(!("[department]" in GLOB.req_console_supplies))
				GLOB.req_console_supplies += department
		if(3)
			if(!("[department]" in GLOB.req_console_information))
				GLOB.req_console_information += department
		if(4)
			if(!("[department]" in GLOB.req_console_assistance))
				GLOB.req_console_assistance += department
			if(!("[department]" in GLOB.req_console_supplies))
				GLOB.req_console_supplies += department
		if(5)
			if(!("[department]" in GLOB.req_console_assistance))
				GLOB.req_console_assistance += department
			if(!("[department]" in GLOB.req_console_information))
				GLOB.req_console_information += department
		if(6)
			if(!("[department]" in GLOB.req_console_supplies))
				GLOB.req_console_supplies += department
			if(!("[department]" in GLOB.req_console_information))
				GLOB.req_console_information += department
		if(7)
			if(!("[department]" in GLOB.req_console_assistance))
				GLOB.req_console_assistance += department
			if(!("[department]" in GLOB.req_console_supplies))
				GLOB.req_console_supplies += department
			if(!("[department]" in GLOB.req_console_information))
				GLOB.req_console_information += department

	Radio = new /obj/item/radio(src)
	Radio.listening = FALSE

/obj/machinery/requests_console/Destroy()
	QDEL_NULL(Radio)
	GLOB.allConsoles -= src
	return ..()

/obj/machinery/requests_console/ui_interact(mob/user, datum/tgui/ui)
	. = ..()
	if(open) // maintenance panel open
		return
	if(screen == 8) // просмотр сообщений сбрасывает индикатор новых
		set_screen(8)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "RequestsConsole", "Консоль запросов")
		ui.open()

/obj/machinery/requests_console/ui_data(mob/user)
	var/list/data = list()
	data["department"] = department
	data["departmentRu"] = get_ru_department()
	data["screen"] = screen
	data["hacked"] = hackState
	data["speakerOn"] = !silent
	data["emergency"] = emergency
	data["announcementConsole"] = announcementConsole
	data["announceAuth"] = announceAuth
	data["canAnnounce"] = announcementConsole && (announceAuth || IsAdminGhost(user))
	data["message"] = ui_message_text(message)
	data["recipient"] = dpt
	data["priority"] = priority
	data["verified"] = msgVerified
	data["stamped"] = msgStamped

	switch(newmessagepriority)
		if(HIGH_MESSAGE_PRIORITY)
			data["newMessages"] = "high"
		if(EXTREME_MESSAGE_PRIORITY)
			data["newMessages"] = "extreme"
		if(NORMAL_MESSAGE_PRIORITY)
			data["newMessages"] = "normal"
		else
			data["newMessages"] = "none"

	var/list/source = null
	switch(screen)
		if(1)
			source = GLOB.req_console_assistance
		if(2)
			source = GLOB.req_console_supplies
		if(3)
			source = GLOB.req_console_information
	var/list/departments = list()
	if(source)
		for(var/dpt in source)
			if(dpt == department)
				continue
			departments += list("name" = dpt, "ckey" = ckey(dpt))
	data["departments"] = departments
	data["messages"] = messages
	return data

/obj/machinery/requests_console/ui_act(action, params)
	if(..())
		return
	if(open)
		return
	if(!usr.canUseTopic(src, !hasSiliconAccessInArea(usr)))
		return
	add_fingerprint(usr)

	switch(action)
		if("navigate")
			. = set_screen(text2num(params["screen"]))
		if("compose")
			. = start_compose(params["department"], text2num(params["priority"]) || NORMAL_MESSAGE_PRIORITY)
		if("reply")
			. = start_compose(params["department"], NORMAL_MESSAGE_PRIORITY)
		if("writeAnnouncement")
			if(!announcementConsole)
				return
			var/new_message = reject_bad_text(tgui_input_text(usr, "Напишите сообщение:", "Ввод", ui_message_text(message), MAX_MESSAGE_LEN, TRUE, TRUE))
			if(!new_message)
				return
			message = new_message
			screen = 10
			. = TRUE
		if("sendAnnouncement")
			if(!announcementConsole || !(announceAuth || IsAdminGhost(usr)) || !message)
				return
			if(isliving(usr))
				var/mob/living/L = usr
				message = L.treat_message(message)
			priority_announce(message, "[get_ru_department()] Объявляет (— [usr.name])", 'sound/announcer/tonelow.ogg', "RequestsConsole", has_important_message = TRUE)
			GLOB.news_network.SubmitArticle(message, department, "Станционные Объявления", null)
			usr.log_talk(message, LOG_SAY, tag = "station announcement from [src]")
			message_admins("[ADMIN_LOOKUPFLW(usr)] has made a station announcement from [src] at [AREACOORD(usr)].")
			announceAuth = FALSE
			message = ""
			screen = 0
			. = TRUE
		if("alarm")
			if(emergency)
				return
			var/radio_freq
			switch(text2num(params["alarm"]))
				if(1)
					radio_freq = FREQ_SECURITY
					emergency = "ВНИМАНИЕ: СЛУЖБА БЕЗОПАСНОСТИ!"
				if(2)
					radio_freq = FREQ_ENGINEERING
					emergency = "ВНИМАНИЕ: ИНЖЕНЕРНЫЙ ОТДЕЛ!"
				if(3)
					radio_freq = FREQ_MEDICAL
					emergency = "ВНИМАНИЕ: МЕДИЦИНСКИЙ ОТДЕЛ!"
			if(radio_freq)
				Radio.set_frequency(radio_freq)
				Radio.talk_into(src, "[emergency] ТРЕВОГА В ЛОКАЦИИ: [department]!", radio_freq)
				update_icon()
				addtimer(CALLBACK(src, PROC_REF(clear_emergency)), 5 MINUTES)
				. = TRUE
		if("speaker")
			silent = !silent
			. = TRUE
		if("send")
			. = send_request()


/// Приводит текст из BYOND-формата (HTML-entities и <br>) к обычному тексту для tgui.
/obj/machinery/requests_console/proc/ui_message_text(text)
	var/result = html_decode(text)
	result = replacetext(result, "<br>", "\n")
	result = replacetext(result, "<BR>", "\n")
	result = replacetext(result, "<br/>", "\n")
	result = replacetext(result, "<BR/>", "\n")
	return result

/obj/machinery/requests_console/proc/get_ru_department()
	switch(department)
		if("Head of Personnel's Desk")
			return "Глава Персонала"
		if("Research Director's Desk")
			return "Директор Отдела Исследований"
		if("Chief Engineer's Desk")
			return "Главный Инженер"
		if("Chief Medical Officer's Desk")
			return "Главный Врач"
		if("Head of Security's Desk")
			return "Глава Службы Безопасности"
		if("Quartermaster's Desk")
			return "Завхоз"
		if("Telecomms Admin")
			return "Администрация Телекоммуникаций"
		if("Bridge")
			return "Мостик"
		if("Cargo Bay")
			return "Складской отдел"
	return "Неизвестный"

/obj/machinery/requests_console/proc/set_screen(new_screen)
	switch(new_screen)
		if(1, 2, 3, 6, 7, 8, 9)
			screen = new_screen
		if(10)
			if(!announcementConsole)
				return FALSE
			screen = 10
		else
			dpt = ""
			msgVerified = ""
			msgStamped = ""
			message = ""
			priority = NORMAL_MESSAGE_PRIORITY
			announceAuth = FALSE
			screen = 0
	if(new_screen == 8)
		for(var/obj/machinery/requests_console/console in GLOB.allConsoles)
			if(console.department == department)
				console.newmessagepriority = NO_NEW_MESSAGE
				console.update_icon()
	return TRUE

/obj/machinery/requests_console/proc/start_compose(target_department, new_priority = NORMAL_MESSAGE_PRIORITY)
	var/clean_department = reject_bad_text(target_department)
	if(!clean_department)
		return FALSE
	if(new_priority == EXTREME_MESSAGE_PRIORITY && !hackState)
		return FALSE
	var/new_message = tgui_input_text(usr, "Напишите сообщение:", "Ввод", "", MAX_MESSAGE_LEN, FALSE, TRUE)
	if(!new_message)
		return FALSE
	message = new_message
	dpt = ckey(clean_department)
	priority = new_priority
	msgVerified = ""
	msgStamped = ""
	screen = 9
	return TRUE

/obj/machinery/requests_console/proc/send_request()
	if(!message || !dpt)
		return FALSE
	var/datum/data_rc_msg/log = new(dpt, department, message, msgStamped, msgVerified, priority)
	var/workingServer = FALSE
	for(var/obj/machinery/telecomms/message_server/MS in GLOB.telecomms_list)
		if(MS.on)
			LAZYADD(MS.rc_msgs, log)
			// Prevent unbounded memory growth
			if(length(MS.rc_msgs) > 500)
				var/trim_count = length(MS.rc_msgs) - 400
				MS.rc_msgs.Cut(1, trim_count + 1)
				MS.rc_msgs_trimmed += trim_count
			workingServer = TRUE
	if(!workingServer)
		screen = 7
		say("NOTICE: No server detected! Please contact your local engineering team.")
		return TRUE

	var/radio_freq = 0
	switch(dpt)
		if("bridge")
			radio_freq = FREQ_COMMAND
		if("medbay")
			radio_freq = FREQ_MEDICAL
		if("science")
			radio_freq = FREQ_SCIENCE
		if("engineering")
			radio_freq = FREQ_ENGINEERING
		if("security")
			radio_freq = FREQ_SECURITY
		if("cargobay", "mining")
			radio_freq = FREQ_SUPPLY
	Radio.set_frequency(radio_freq)

	var/alert = ""
	var/title = "Объявление"
	var/authenticated = (msgVerified || msgStamped) ? " (Authenticated)" : ""
	switch(priority)
		if(HIGH_MESSAGE_PRIORITY)
			alert = "ВНИМАНИЕ, ПРИОРИТЕТНОЕ ОБЪЯВЛЕНИЕ из [department][authenticated]"
			title = "Приоритетное объявление"
		if(EXTREME_MESSAGE_PRIORITY)
			alert = "ВНИМАНИЕ, ЭКСТРЕННО ПРИОРИТЕТНОЕ ОБЪЯВЛЕНИЕ из [department][authenticated]"
			title = "Экстремальное объявление"
		else
			alert = "Внимание, объявление из [department][authenticated]"

	for(var/obj/machinery/requests_console/console in GLOB.allConsoles)
		if(ckey(console.department) != dpt)
			continue
		console.createmessage(src, alert, message, priority, msgVerified, msgStamped)
		screen = 6

	if(radio_freq)
		Radio.talk_into(src, "[alert]: <i>[message]</i>", radio_freq)

	messages += list(
		"outgoing" = TRUE,
		"title" = title,
		"from" = department,
		"to" = dpt,
		"body" = ui_message_text(message),
		"priority" = priority,
		"verified" = msgVerified,
		"stamped" = msgStamped,
	)
	return TRUE


/obj/machinery/requests_console/say_mod(input, message_mode)
	if(spantext_char(input, "!", -3))
		return "blares"
	else
		. = ..()

/obj/machinery/requests_console/proc/clear_emergency()
	emergency = null
	update_icon()

/obj/machinery/requests_console/proc/createmessage(source, title, message, priority, verified = "", stamped = "")
	var/sender_name
	if(istype(source, /obj/machinery/requests_console))
		var/obj/machinery/requests_console/sender = source
		sender_name = sender.department
	else
		sender_name = capitalize(source)
	var/message_title = capitalize(title)
	switch(priority)
		if(HIGH_MESSAGE_PRIORITY)
			if(newmessagepriority < HIGH_MESSAGE_PRIORITY)
				newmessagepriority = HIGH_MESSAGE_PRIORITY
				update_icon()
			if(!silent)
				playsound(src, 'sound/machines/twobeep.ogg', 50, 1)
				say(message_title)
		if(EXTREME_MESSAGE_PRIORITY)
			if(newmessagepriority < EXTREME_MESSAGE_PRIORITY)
				newmessagepriority = EXTREME_MESSAGE_PRIORITY
				update_icon()
			//we ignore the silent option because this is !!!IMPORTANT!!!
			playsound(src, 'sound/machines/twobeep.ogg', 50, 1)
			say(message_title)
		else
			if(newmessagepriority < NORMAL_MESSAGE_PRIORITY)
				newmessagepriority = NORMAL_MESSAGE_PRIORITY
				update_icon()
			if(!silent)
				playsound(src, 'sound/machines/twobeep.ogg', 50, 1)
				say(message_title)
	messages += list(
		"outgoing" = FALSE,
		"title" = message_title,
		"from" = sender_name,
		"body" = ui_message_text(message),
		"priority" = priority,
		"verified" = verified,
		"stamped" = stamped,
	)

/obj/machinery/requests_console/attackby(obj/item/O, mob/user, params)
	if(O.tool_behaviour == TOOL_CROWBAR)
		if(open)
			to_chat(user, "<span class='notice'>You close the maintenance panel.</span>")
			open = FALSE
		else
			to_chat(user, "<span class='notice'>You open the maintenance panel.</span>")
			open = TRUE
		update_icon()
		return
	if(O.tool_behaviour == TOOL_SCREWDRIVER)
		if(open)
			hackState = !hackState
			if(hackState)
				to_chat(user, "<span class='notice'>You modify the wiring.</span>")
			else
				to_chat(user, "<span class='notice'>You reset the wiring.</span>")
			update_icon()
		else
			to_chat(user, "<span class='warning'>You must open the maintenance panel first!</span>")
		return

	if(istype(O, /obj/item/card/id))
		var/obj/item/card/id/ID = O.GetID()
		if(!ID)
			return
		if(screen == 9)
			msgVerified = "Авторизовано с помощью карты: [ID.registered_name] ([ID.get_assignment_name()])"
			playsound(get_turf(user), 'sound/machines/auth.ogg', 75, 1, 1)
			SStgui.update_uis(src)
		if(screen == 10)
			if(ACCESS_RC_ANNOUNCE in ID.access)
				announceAuth = TRUE
				playsound(get_turf(user), 'sound/machines/auth.ogg', 75, 1, 1)
			else
				announceAuth = FALSE
				to_chat(user, "<span class='warning'>Вы не авторизованы для отправки объявлений!</span>")
			SStgui.update_uis(src)
		return

	if(istype(O, /obj/item/stamp))
		if(screen == 9)
			var/obj/item/stamp/T = O
			msgStamped = "Проштамповано с помощью: [T.name]"
			SStgui.update_uis(src)
		return
	return ..()

#undef NO_NEW_MESSAGE
#undef NORMAL_MESSAGE_PRIORITY
#undef HIGH_MESSAGE_PRIORITY
#undef EXTREME_MESSAGE_PRIORITY
