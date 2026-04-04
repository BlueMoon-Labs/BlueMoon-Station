/proc/priority_announcement_style(title = "", type, sender_override)
	var/list/data = list(
		"theme" = "centcom",
		"badge" = "CENTCOM",
		"header" = "[command_name()] Объявляет",
		"subtitle" = title,
	)

	switch(type)
		if("Priority")
			data["theme"] = "priority"
			data["badge"] = "PRIORITY"
			data["header"] = "Приоритетное Объявление"
		if("Captain", "CommunicationsConsole")
			data["theme"] = "communications"
			data["badge"] = "COMMS"
			data["header"] = "Консоль Связи"
		if("RequestsConsole")
			data["theme"] = "requests"
			data["badge"] = "REQUESTS"
			data["header"] = "Консоль Запросов"
		if("Syndicate")
			data["theme"] = "syndicate"
			data["badge"] = "SYNDICATE"
			data["header"] = "Синдикат Объявляет"
		if("AI", "Silicon")
			data["theme"] = "silicon"
			data["badge"] = "SILICON"
			data["header"] = "Силиконовое Объявление"
		else
			if(sender_override)
				var/sender_lower = lowertext("[sender_override]")
				var/command_lower = lowertext(command_name())
				data["theme"] = "custom"
				data["badge"] = "NOTICE"
				data["header"] = sender_override

				if(findtext(sender_lower, "центральное командование") || findtext(sender_lower, "central command") || findtext(sender_lower, "centcom") || findtext(sender_lower, command_lower))
					data["theme"] = "centcom"
					data["badge"] = "CENTCOM"

	return data

/proc/build_priority_announcement(text, title = "", type, sender_override, has_important_message)
	var/list/style = priority_announcement_style(title, type, sender_override)
	var/theme = style["theme"]
	var/header_text = style["header"]
	var/subtitle_text = style["subtitle"]
	var/badge_text = style["badge"]
	var/list/classes = list(
		"priority_announcement",
		"priority_announcement--[theme]",
	)

	if(has_important_message)
		classes += "priority_announcement--important"

	var/class_string = jointext(classes, " ")
	var/header = html_encode(header_text)
	var/subtitle = html_encode(subtitle_text)
	var/badge = html_encode(badge_text)
	var/body

	if(SSstation.announcer.custom_alert_message && !has_important_message)
		body = "<span class='priority_announcement__body priority_announcement__body--custom'>[SSstation.announcer.custom_alert_message]</span>"
	else
		body = "<span class='priority_announcement__body'>[html_encode(text)]</span>"

	var/announcement = "<span class='[class_string]'>"
	announcement += "<span class='priority_announcement__badge'>[badge]</span>"
	announcement += "<span class='priority_announcement__header'>"
	announcement += "<span class='priority_announcement__source'>[header]</span>"

	if(length(subtitle_text))
		announcement += "<span class='priority_announcement__title'>[subtitle]</span>"

	announcement += "</span>"
	announcement += body
	announcement += "</span>"

	return announcement

/proc/priority_announce(text, title = "", sound, type , sender_override, has_important_message)
	if(!text)
		return

	var/announcement
	if(!sound)
		sound = SSstation.announcer.get_rand_alert_sound()
	else if(SSstation.announcer.event_sounds[sound])
		sound = pick(SSstation.announcer.event_sounds[sound])

	if(type == "Captain" || type == "CommunicationsConsole")
		var/announcement_title = title
		if(!length(announcement_title))
			announcement_title = "Станционное Объявление"
		GLOB.news_network.SubmitArticle(html_encode(text), announcement_title, "Станционные Объявления", null)
	else if(type == "Syndicate")
		GLOB.news_network.SubmitArticle(html_encode(text), "Синдикат Объявляет", "Станционные Объявления", null)
	else if(type != "Priority" && type != "RequestsConsole" && type != "AI" && type != "Silicon")
		if(!sender_override)
			if(title == "")
				GLOB.news_network.SubmitArticle(text, "Центральное Командование Объявляет", "Станционные Объявления", null)
			else
				GLOB.news_network.SubmitArticle(title + "<br><br>" + text, "Центральное Командование Объявляет", "Станционные Объявления", null)

	announcement = build_priority_announcement(text, title, type, sender_override, has_important_message)

	var/s = sound(sound)
	for(var/mob/M in GLOB.player_list)
		if(!isnewplayer(M) && M.can_hear())
			to_chat(M, announcement)
			if(M.client.prefs.toggles & SOUND_ANNOUNCEMENTS)
				SEND_SOUND(M, s)

/**
 * Summon the crew for an emergency meeting
 *
 * Teleports the crew to a specified area, and tells everyone (via an announcement) who called the meeting. Should only be used during april fools!
 * Arguments:
 * * user - Mob who called the meeting
 * * button_zone - Area where the meeting was called and where everyone will get teleported to
 */
/proc/call_emergency_meeting(mob/living/user, area/button_zone)
	var/meeting_sound = sound('sound/misc/emergency_meeting.ogg')
	var/announcement
	announcement += "<h1 class='alert'>ТРЕВОГА!!!</h1>"
	announcement += "<br>[span_alert("[user] устраивает экстренный сбор!")]<br><br>"

	for(var/mob/mob_to_teleport in GLOB.player_list) //gotta make sure the whole crew's here!
		if(isnewplayer(mob_to_teleport) || iscameramob(mob_to_teleport))
			continue

		to_chat(mob_to_teleport, announcement)
		SEND_SOUND(mob_to_teleport, meeting_sound) //no preferences here, you must hear the funny sound
		mob_to_teleport.overlay_fullscreen("emergency_meeting", /atom/movable/screen/fullscreen/scaled/emergency_meeting, 1)
		addtimer(CALLBACK(mob_to_teleport, TYPE_PROC_REF(/mob, clear_fullscreen), "emergency_meeting"), 3 SECONDS)

		if (is_station_level(mob_to_teleport.z)) //teleport the mob to the crew meeting
			var/turf/target
			var/list/turf_list = get_area_turfs(button_zone)
			while (!target && turf_list.len)
				target = pick_n_take(turf_list)
				if (isclosedturf(target))
					target = null
					continue
				mob_to_teleport.forceMove(target)

/proc/print_command_report(text = "", title = null, announce=TRUE)
	if(!title)
		title = "Секретно: [command_name()]"

	if(announce)
		priority_announce("Отчет был загружен и распечатан на всех коммуникационных консолях.", "Входящее Секретное Сообщение", 'modular_bluemoon/kovac_shitcode/sound/ambience/enc/morse.ogg', has_important_message = TRUE)

	var/datum/comm_message/M  = new
	M.title = title
	M.content =  text

	SScommunications.send_message(M)

/proc/minor_announce(message, title = "Внимание!", alert, html_encode = TRUE)
	if(!message)
		return

	if (html_encode)
		title = html_encode(title)
		message = html_encode(message)

	for(var/mob/M in GLOB.player_list)
		if(!isnewplayer(M) && M.can_hear())
			to_chat(M, "[span_minorannounce("<font color = red>[title]</font color><BR>[message]")]<BR>")
			if(M.client.prefs.toggles & SOUND_ANNOUNCEMENTS)
				if(alert)
					SEND_SOUND(M, sound('sound/misc/notice1.ogg'))
				else
					SEND_SOUND(M, sound('sound/misc/notice2.ogg'))
