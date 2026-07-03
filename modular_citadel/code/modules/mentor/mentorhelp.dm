/client/verb/mentorhelp(msg as text)
	set category = "Mentor"
	set name = "Mentorhelp"

	//clean the input msg
	if(!msg)
		return

	//remove out mentorhelp verb temporarily to prevent spamming of mentors.
	remove_verb(src, /client/verb/mentorhelp)
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(add_verb), src, /client/verb/mentorhelp), 30 SECONDS)

	msg = sanitize(copytext_char(msg, 1, MAX_MESSAGE_LEN))
	if(!msg || !mob)
		return

	var/mentor_msg = "<span class='mentornotice'><b><font color='purple'>MENTORHELP:</b> <b>[key_name_mentor(src, TRUE, FALSE, TRUE)]</b>: [msg]</font></span>"
	log_mentor("MENTORHELP: [key_name_mentor(src, FALSE, FALSE, FALSE)]: [msg]")

	for(var/client/X in GLOB.mentors | GLOB.admins)
		SEND_SOUND(X, 'sound/items/bikehorn.ogg')
		to_chat(X, mentor_msg)

	to_chat(src, "<span class='mentornotice'><font color='purple'>PM to-<b>Mentors</b>: [msg]</font></span>")
	return

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
