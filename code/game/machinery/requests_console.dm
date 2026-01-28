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
	armor = list(MELEE = 70, BULLET = 30, LASER = 30, ENERGY = 30, BOMB = 0, BIO = 0, RAD = 0, FIRE = 90, ACID = 90)

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

/obj/machinery/requests_console/ui_interact(mob/user)
	. = ..()
	if(open) //no.
		return

	var/dat = ""
	switch(screen)
		if(1)	//req. assistance
			dat += "Из какого отдела вам нужна помощь?<br><br>"
			dat += "<table width='100%'>"
			for(var/dpt in GLOB.req_console_assistance)
				if(dpt == department)
					continue
				dat += "<tr>"
				dat += "<td width='55%'>[dpt]</td>"
				dat += "<td width='45%'>"
				dat += "<a href='?src=[REF(src)];write=[ckey(dpt)];priority=1'>Обычный</a>"
				dat += "<a href='?src=[REF(src)];write=[ckey(dpt)];priority=2'>Высокий</a>"
				if(hackState)
					dat += "<a href='?src=[REF(src)];write=[ckey(dpt)];priority=3'>ЭКСТРЕМАЛЬНЫЙ</a>"
				dat += "</td>"
				dat += "</tr>"
			dat += "</table>"
			dat += "<br><A href='?src=[REF(src)];setScreen=0'><< Назад</A><br>"

		if(2)	//req. supplies
			dat += "Из какого отдела вам нужны припасы?<br><br>"
			dat += "<table width='100%'>"
			for(var/dpt in GLOB.req_console_supplies)
				if(dpt == department)
					continue

				dat += "<tr>"
				dat += "<td width='55%'>[dpt]</td>"
				dat += "<td width='45%'>"
				dat += "<a href='?src=[REF(src)];write=[ckey(dpt)];priority=1'>Обычный</a>"
				dat += "<a href='?src=[REF(src)];write=[ckey(dpt)];priority=2'>Высокий</a>"
				if(hackState)
					dat += "<a href='?src=[REF(src)];write=[ckey(dpt)];priority=3'>ЭКСТРЕМАЛЬНЫЙ</a>"
				dat += "</td>"
				dat += "</tr>"
			dat += "</table>"
			dat += "<br><A href='?src=[REF(src)];setScreen=0'><< Назад</A><br>"

		if(3)	//relay information
			dat += "В какой отдел вы хотите отправить информацию?<br><br>"
			dat += "<table width='100%'>"
			for(var/dpt in GLOB.req_console_information)
				if(dpt == department)
					continue
				dat += "<tr>"
				dat += "<td width='55%'>[dpt]</td>"
				dat += "<td width='45%'>"
				dat += "<a href='?src=[REF(src)];write=[ckey(dpt)];priority=1'>Обычный</a>"
				dat += "<a href='?src=[REF(src)];write=[ckey(dpt)];priority=2'>Высокий</a>"
				if(hackState)
					dat += "<a href='?src=[REF(src)];write=[ckey(dpt)];priority=3'>ЭКСТРЕМАЛЬНЫЙ</a>"
				dat += "</td>"
				dat += "</tr>"
			dat += "</table>"
			dat += "<br><a href='?src=[REF(src)];setScreen=0'><< Назад</a><br>"

		if(6)	//sent successfully
			dat += "<span class='good'>Сообщение отправлено.</span><br><br>"
			dat += "<a href='?src=[REF(src)];setScreen=0'>Продолжить</a><br>"

		if(7)	//unsuccessful; not sent
			dat += "<span class='bad'>Произошла ошибка.</span><br><br>"
			dat += "<a href='?src=[REF(src)];setScreen=0'>Продолжить</a><br>"

		if(8)	//view messages
			for(var/obj/machinery/requests_console/Console in GLOB.allConsoles)
				if(Console.department == department)
					Console.newmessagepriority = NO_NEW_MESSAGE
					Console.update_icon()

			newmessagepriority = NO_NEW_MESSAGE
			update_icon()
			var/messageComposite = ""
			for(var/msg in messages) // This puts more recent messages at the *top*, where they belong.
				messageComposite = "<div class='block'>[msg]</div>" + messageComposite
			dat += messageComposite
			dat += "<br><a href='?src=[REF(src)];setScreen=0'><< Вернуться в главное меню</a><br>"

		if(9)	//authentication before sending
			dat += "<b>Авторизация сообщения</b> <br><br>"
			dat += "<b>Сообщение для [dpt]:</b> [message] <br><br>"
			dat += "<div class='notice'>Вы можете подтвердить подлинность сообщения, отсканировав свою карту или печать.</div> <br>"

			dat += "<b>Утверждено:</b> [msgVerified ? "<span class='good'><b>[msgVerified]</b></span>" : "<i>Не прошло утверждение</i>"] <br>"
			dat += "<b>Печать выставлена:</b> [msgStamped ? "<span class='boldnotice'>[msgStamped]</span>" : "<i>Не проставлена печать</i>"] <br><br>"

			dat += "<a href='?src=[REF(src)];department=[dpt]'>Отправить сообщение</a> <br><br>"
			dat += "<a href='?src=[REF(src)];setScreen=0'><< Очистить сообщение</a> <br>"

		if(10)	//send announcement
			dat += "<h3>Станционное объявление</h3>"
			if(announceAuth)
				dat += "<div class='notice'>Авторизация пройдена</div><br>"
			else
				dat += "<div class='notice'>Проведите картой для авторизации</div> <br>"
			dat += "<b>Сообщение: </b>[message ? message : "<i>Отсутствует</i>"] <br>"
			dat += "<a href='?src=[REF(src)];writeAnnouncement=1'>[message ? "Отредактировать" : "Написать"] сообщение</a> <br><br>"
			if((announceAuth || IsAdminGhost(user)) && message)
				dat += "<a href='?src=[REF(src)];sendAnnouncement=1'>Сделать объявление</a> <br>"
			else
				dat += "<span class='linkOff'>Сделать объявление</span> <br>"
			dat += "<br><a href='?src=[REF(src)];setScreen=0'><< Назад</a> <br>"

		else	//main menu
			screen = 0
			announceAuth = FALSE
			if(newmessagepriority == NORMAL_MESSAGE_PRIORITY)
				dat += "<div class='notice'>Имеются новые сообщения</div><br>"
			if(newmessagepriority == HIGH_MESSAGE_PRIORITY)
				dat += "<div class='notice'>Имеются новые сообщения <b>особой важности.</b></div><br>"
			if(newmessagepriority == EXTREME_MESSAGE_PRIORITY)
				dat += "<div class='notice'>Имеются новые сообщения <b>ЭКСТРЕМАЛЬНОЙ ВАЖНОСТИ</b>.</div><br>"

			dat += "<a href='?src=[REF(src)];setScreen=8'>Посмотреть сообщения</a> <br><br>"

			dat += "<a href='?src=[REF(src)];setScreen=1'>Запросить помощь</a> <br>"
			dat += "<a href='?src=[REF(src)];setScreen=2'>Запросить припасы</a> <br>"
			dat += "<a href='?src=[REF(src)];setScreen=3'>Передача анонимной информации</a> <br><br>"

			if(!emergency)
				dat += "<a href='?src=[REF(src)];emergency=1'>Охранная тревога</a> <br>"
				dat += "<a href='?src=[REF(src)];emergency=2'>Инженерная тревога</a> <br>"
				dat += "<a href='?src=[REF(src)];emergency=3'>Медицинская тревога</a> <br><br>"
			else
				dat += "<b><div class='bad'>[emergency] ТРЕВОГА НА ДАННОМ МЕСТОПОЛОЖЕНИИ!</div></b> <br><br>"

			if(announcementConsole)
				dat += "<a href='?src=[REF(src)];setScreen=10'>Отправить станционное объявление</a> <br><br>"
			if(silent)
				dat += "Динамик <a href='?src=[REF(src)];setSilent=0'>ВЫКЛ</a>"
			else
				dat += "Динамик <a href='?src=[REF(src)];setSilent=1'>ВКЛ</a>"

	var/datum/browser/popup = new(user, "req_console", "Консоль запросов", 450, 440)
	popup.set_content(dat)
	popup.open()

/obj/machinery/requests_console/Topic(href, href_list)
	if(..())
		return
	usr.set_machine(src)
	add_fingerprint(usr)

	if(href_list["write"])
		dpt = ckey(reject_bad_text(href_list["write"])) //write contains the string of the receiving department's name
		var/new_message = stripped_input(usr, "Напишите сообщение:", "Ввод", "", MAX_MESSAGE_LEN)
		if(new_message)
			message = new_message
			screen = 9
			priority = text2num(href_list["priority"])
		else
			dpt = "";
			msgVerified = ""
			msgStamped = ""
			screen = 0
			priority = NORMAL_MESSAGE_PRIORITY //:salt:

	if(href_list["writeAnnouncement"])
		var/new_message = reject_bad_text(stripped_input(usr, "Напишите сообщение:", "Ввод", "", MAX_MESSAGE_LEN))
		if(new_message)
			message = new_message
			priority = text2num(href_list["priority"])
		else
			message = ""
			announceAuth = FALSE
			screen = 0

//////////////
	var/ru_department = "" // Используется только в объявлениях
	if (department == "Head of Personnel's Desk")
		ru_department = "Глава Персонала"
	else if (department == "Research Director's Desk")
		ru_department = "Директор Отдела Исследований"
	else if (department == "Chief Engineer's Desk")
		ru_department = "Главный Инженер"
	else if (department == "Chief Medical Officer's Desk")
		ru_department = "Главный Врач"
	else if (department == "Head of Security's Desk")
		ru_department = "Глава Службы Безопасности"
	else if (department == "Quartermaster's Desk")
		ru_department = "Завхоз"
	else if (department == "Telecomms Admin")
		ru_department = "Администрация Телекоммуникаций"
	else if (department == "Bridge")
		ru_department = "Мостик"
	else if (department == "Cargo Bay")
		ru_department = "Складской отдел"
	else
		ru_department = "Неизвестный"
/////////////////

	if(href_list["sendAnnouncement"])
		if(!announcementConsole)
			updateUsrDialog()
			return
		if(isliving(usr))
			var/mob/living/L = usr
			message = L.treat_message(message)
		//minor_announce(message, "[ru_department] объявляет:")
		priority_announce(message, "[ru_department] Объявляет (— [usr.name])", 'sound/announcer/tonelow.ogg', "Priority", has_important_message = TRUE)
		GLOB.news_network.SubmitArticle(message, department, "Станционные Объявления", null)
		usr.log_talk(message, LOG_SAY, tag = "station announcement from [src]")
		message_admins("[ADMIN_LOOKUPFLW(usr)] has made a station announcement from [src] at [AREACOORD(usr)].")
		announceAuth = FALSE
		message = ""
		screen = 0

	if(href_list["emergency"])
		if(emergency) //already has an emergency? do not continue
			updateUsrDialog()
			return

		var/radio_freq
		switch(text2num(href_list["emergency"]))
			if(1) //Security
				radio_freq = FREQ_SECURITY
				emergency = "BНИМАНИЕ: СЛУЖБА БЕЗОПАСНОСТИ!"
			if(2) //Engineering
				radio_freq = FREQ_ENGINEERING
				emergency = "BНИМАНИЕ: ИНЖЕНЕРНЫЙ ОТДЕЛ!"
			if(3) //Medical
				radio_freq = FREQ_MEDICAL
				emergency = "BНИМАНИЕ: МЕДИЦИНСКИЙ ОТДЕЛ!"
		if(radio_freq)
			Radio.set_frequency(radio_freq)
			Radio.talk_into(src, "[emergency] ТРЕВОГА В ЛОКАЦИИ: [department]!", radio_freq)
			update_icon()
			addtimer(CALLBACK(src, PROC_REF(clear_emergency)), 5 MINUTES)

	if(href_list["department"] && message)
		var/sending = message
		sending += "<br>"
		if(msgVerified)
			sending += "<span class='good'><b>[msgVerified]</b></span> <br>"
		if(msgStamped)
			sending += "<span class='boldnotice'>[msgStamped]</span> <br>"
		//so you're telling me is you cheated, by making fail happen, then quickly replacing it with 6

		var/workingServer = FALSE
		var/datum/data_rc_msg/log = new(href_list["department"], department, message, msgStamped, msgVerified, priority)
		for(var/obj/machinery/telecomms/message_server/MS in GLOB.telecomms_list)
			if(MS.on) //on does the calculations. why would this server still work even though the apc is off??
				LAZYADD(MS.rc_msgs, log)
				workingServer = TRUE

		if(!workingServer)
			screen = 7
			say("NOTICE: No server detected! Please contact your local engineering team.")
			updateUsrDialog()
			return

		var/radio_freq = 0
		switch(href_list["department"])
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

		var/authentic = ""
		if(msgVerified || msgStamped)
			authentic = " (Authenticated)"

		var/alert = ""
		for(var/obj/machinery/requests_console/C in GLOB.allConsoles)
			if(ckey(C.department) != ckey(href_list["department"]))
				continue
			switch(priority)
				if(HIGH_MESSAGE_PRIORITY)		//High priority
					alert = "BНИМАНИЕ, ПРИОРИТЕТНОЕ ОБЪЯBЛЕНИЕ из [department][authentic]"
					C.createmessage(src, alert, sending, HIGH_MESSAGE_PRIORITY)
				if(EXTREME_MESSAGE_PRIORITY)	// Extreme Priority
					alert = "BНИМАНИЕ, ЭКСТРИМАЛЬНО ПРИОРИТЕТНОЕ ОБЪЯBЛЕНИЕ из [department][authentic]"
					C.createmessage(src, alert, sending, EXTREME_MESSAGE_PRIORITY)
				else		// Normal priority
					alert = "Bнимание, объявление из [department][authentic]"
					C.createmessage(src, alert, sending, NORMAL_MESSAGE_PRIORITY)
			screen = 6 //if it ever gets here that means (c.department == href_ls["dept"])

		if(radio_freq)
			Radio.talk_into(src, "[alert]: <i>[message]</i>", radio_freq)
		//log to (this)
		switch(priority)
			if(HIGH_MESSAGE_PRIORITY)
				messages += "<span class='bad'>ПРИОРИТЕТНОЕ ОБЪЯBЛЕНИЕ</span><br><b>To:</b> [dpt]<br>[sending]"
			if(EXTREME_MESSAGE_PRIORITY)
				messages += "<span class='bad'>!!!ЭКСТРИМАЛЬНО ПРИОРИТЕТНОЕ ОБЪЯBЛЕНИЕ!!!</span><br><b>To:</b> [dpt]<br>[sending]"
			else
				messages += "<b>To:</b> [dpt]<br>[sending]"


	//Handle screen switching
	switch(text2num(href_list["setScreen"]))
		if(null)	//skip
			updateUsrDialog()
			return
		if(1)		//req. assistance
			screen = 1
		if(2)		//req. supplies
			screen = 2
		if(3)		//relay information
			screen = 3
//		if(4)		//write message
//			screen = 4
		if(5)		//choose priority
			screen = 5
		if(6)		//sent successfully
			screen = 6
		if(7)		//unsuccessfull; not sent
			screen = 7
		if(8)		//view messages
			screen = 8
		if(9)		//authentication
			screen = 9
		if(10)		//send announcement
			if(!announcementConsole)
				return
			screen = 10
		else		//main menu
			dpt = ""
			msgVerified = ""
			msgStamped = ""
			message = ""
			priority = NORMAL_MESSAGE_PRIORITY // :salt:
			screen = 0

	//Handle silencing the console
	if(href_list["setSilent"] == "1")
		silent = TRUE
	else
		silent = FALSE

	updateUsrDialog()
	return

/obj/machinery/requests_console/say_mod(input, message_mode)
	if(spantext_char(input, "!", -3))
		return "blares"
	else
		. = ..()

/obj/machinery/requests_console/proc/clear_emergency()
	emergency = null
	update_icon()

/obj/machinery/requests_console/proc/createmessage(source, title, message, priority)
	var/linkedsender
	if(istype(source, /obj/machinery/requests_console))
		var/obj/machinery/requests_console/sender = source
		linkedsender = "<a href='?src=[REF(src)];write=[ckey(sender.department)]'>[sender.department]</a>"
	else
		capitalize(source)
		linkedsender = source
	capitalize(title)
	switch(priority)
		if(HIGH_MESSAGE_PRIORITY)		//High priority
			if(newmessagepriority < HIGH_MESSAGE_PRIORITY)
				newmessagepriority = HIGH_MESSAGE_PRIORITY
				update_icon()
			if(!silent)
				playsound(src, 'sound/machines/twobeep.ogg', 50, 1)
				say(title)
			messages += "<span class='bad'>Высокий приоритет</span><br><b>От:</b> [linkedsender]<br>[message]" //the fuck is this not being sent

		if(EXTREME_MESSAGE_PRIORITY)		// Extreme Priority
			if(newmessagepriority < EXTREME_MESSAGE_PRIORITY)
				newmessagepriority = EXTREME_MESSAGE_PRIORITY
				update_icon()
			//we ignore the silent option because this is !!!IMPORTANT!!!
			playsound(src, 'sound/machines/twobeep.ogg', 50, 1)
			say(title)
			messages += "<span class='bad'><b>!!!Экстремальный приоритет!!!</span></b><br><b>От:</b> [linkedsender]<br>[message]"

		else		// Normal priority
			if(newmessagepriority < NORMAL_MESSAGE_PRIORITY)
				newmessagepriority = NORMAL_MESSAGE_PRIORITY
				update_icon()
			if(!silent)
				playsound(src, 'sound/machines/twobeep.ogg', 50, 1)
				say(title)
			messages += "<b>От:</b> [linkedsender]<br>[message]"

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
			updateUsrDialog()
		if(screen == 10)
			if(ACCESS_RC_ANNOUNCE in ID.access)
				announceAuth = TRUE
				playsound(get_turf(user), 'sound/machines/auth.ogg', 75, 1, 1)
			else
				announceAuth = FALSE
				to_chat(user, "<span class='warning'>Вы не авторизованы для отправки объявлений!</span>")
			updateUsrDialog()
		return

	if(istype(O, /obj/item/stamp))
		if(screen == 9)
			var/obj/item/stamp/T = O
			msgStamped = "Проштамповано с помощью: [T.name]"
			updateUsrDialog()
		return
	return ..()

#undef NO_NEW_MESSAGE
#undef NORMAL_MESSAGE_PRIORITY
#undef HIGH_MESSAGE_PRIORITY
#undef EXTREME_MESSAGE_PRIORITY
