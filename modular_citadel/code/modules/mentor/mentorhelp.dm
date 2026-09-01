/client/var/mentorhelptimerid = 0

/client/proc/give_mentorhelp_verb()
	add_verb(src, /client/verb/mentorhelp)
	deltimer(mentorhelptimerid)
	mentorhelptimerid = 0

/client/verb/mentorhelp(msg as text|null)
	set category = "Mentor"
	set name = "Mentorhelp"

	if(GLOB.say_disabled)
		to_chat(usr, "<span class='danger'>Речь отключена администратором.</span>")
		return

	if(msg)
		msg = sanitize(copytext_char(msg, 1, MAX_MESSAGE_LEN))
		if(!msg || !mob)
			return
		if(GLOB.mentor_tickets?.CKey2Ticket(ckey))
			to_chat(src, "<span class='warning'>У вас уже есть открытый ментор-тикет.</span>")
			return
		new /datum/mentor_ticket(msg, src, FALSE)
		return

	if(prefs.muted & MUTE_ADMINHELP)
		to_chat(src, "<span class='danger'>Вы не можете отправлять менторхелпы (Мут).</span>")
		return

	var/datum/player_ticket_panel/panel = new(src)
	panel.ui_interact(usr)

/proc/get_mentor_counts()
	. = list("total" = 0, "afk" = 0, "present" = 0)
	for(var/X in GLOB.mentors)
		var/client/C = X
		.["total"]++
		if(C.is_afk())
			.["afk"]++
		else
			.["present"]++

/proc/key_name_mentor(whom, include_link = null, include_follow = TRUE, char_name_only = TRUE)
	var/mob/M
	var/client/C
	var/key
	var/ckey

	if(!whom)	return "*null*"
	if(istype(whom, /client))
		C = whom
		M = C.mob
		key = C.key
		ckey = C.ckey
	else if(ismob(whom))
		M = whom
		C = M.client
		key = M.key
		ckey = M.ckey
	else if(istext(whom))
		key = whom
		ckey = ckey(whom)
		C = GLOB.directory[ckey]
		if(C)
			M = C.mob
	else
		return "*invalid*"

	. = ""

	if(!ckey)
		include_link = 0

	if(key)
		if(include_link)
			var/link = CONFIG_GET(flag/mentors_mobname_only) ? REF(M) : ckey
			. += "<a href='?_src_=mentor;mentor_msg=[link];[MentorHrefToken(TRUE)]'>"

		if(C?.holder?.fakekey)
			. += "Administrator"
		else if (char_name_only && CONFIG_GET(flag/mentors_mobname_only))
			if(istype(C?.mob,/mob/dead/new_player)) //If they're in the lobby, display their ckey
				. += key
			else if(C?.mob) //If they're playing/in the round, only show the mob name
				. += C.mob.name
			else //If for some reason neither of those are applicable and they're mentorhelping, show ckey
				. += key
		else
			. += key
		if(!C)
			. += "\[DC\]"

		if(include_link)
			. += "</a>"
	else
		. += "*no key*"

	if(include_follow)
		. += " (<a href='?_src_=mentor;mentor_follow=[REF(M)];[MentorHrefToken(TRUE)]'>F</a>)"

	return .
