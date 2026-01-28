/datum/accent

/datum/accent/proc/modify_speech(list/speech_args, datum/source, mob/living/carbon/owner) //transforms the message in some way
	return speech_args

/datum/accent/proc/applyAccent(message,list/replacements)
	for (var/to_replace in replacements)
		var/replacement = replacements[to_replace]
		if (islist(replacement))
			replacement = pick(replacement)
		message = replacetextEx(message, to_replace, replacement)
	message = trim(message)
	return message

/datum/accent/lizard
	var/static/list/replacements = list(
		new /regex("s+", "g") = "sss",
		new /regex("S+", "g") = "SSS",
		new /regex(@"(\w)x", "g") = "$1kss",
		new /regex(@"\bx([\-|r|R]|\b)", "g") = "ecks$1",
		new /regex(@"\bX([\-|r|R]|\b)", "g") = "ECKS$1",
		new /regex(@"(\w)x", "g") = "$1kss",
		new /regex(@"\bx([\-|r|R]|\b)", "g") = "ecks$1",
		new /regex(@"\bX([\-|r|R]|\b)", "g") = "ECKS$1",
		new /regex("с+", "g") = "ссс",
		new /regex("С+", "g") = "ССС",
		"з" = "с",
		"З" = "С",
		"ж" = "ш",
		"Ж" = "Ш",
		)

/datum/accent/lizard/modify_speech(list/speech_args)
	var/message = speech_args[SPEECH_MESSAGE]
	if(message[1] != "*" && message[1] != "!")
		speech_args[SPEECH_MESSAGE] = applyAccent(message,replacements)
	return speech_args

/datum/accent/canine
	var/static/list/replacements = list(
		new /regex("r+", "g") = "rrr",
		new /regex("R+", "g") = "RRR",
		new /regex("р+", "g") = "ррр",
		new /regex("Р+", "g") = "РРР",
		)

/datum/accent/canine/modify_speech(list/speech_args)
	var/message = speech_args[SPEECH_MESSAGE]
	if(message[1] != "*" && message[1] != "!")
		speech_args[SPEECH_MESSAGE] = applyAccent(message,replacements)
	return speech_args

/datum/accent/feline
	var/static/list/replacements = list(
		new /regex("r+", "g") = "rrr",
		new /regex("R+", "g") = "RRR",
		new /regex("р+", "g") = "ррр",
		new /regex("Р+", "g") = "РРР",
		new /regex("с+", "g") = "ссс",
		new /regex("С+", "g") = "ССС",
		)

/datum/accent/feline/modify_speech(list/speech_args)
	var/message = speech_args[SPEECH_MESSAGE]
	if(message[1] != "*" && message[1] != "!")
		speech_args[SPEECH_MESSAGE] = applyAccent(message,replacements)
	return speech_args

/datum/accent/bird
	var/static/list/replacements = list(
		new /regex("k+", "g") = "kik",
		new /regex("K+", "g") = "Kik",
		new /regex("ч+", "g") = "чич",
		new /regex("Ч+", "g") = "Чич",
		new /regex("к+", "g") = "кик",
		new /regex("К+", "g") = "Кик",
		)

/datum/accent/bird/modify_speech(list/speech_args)
	var/message = speech_args[SPEECH_MESSAGE]
	if(message[1] != "*" && message[1] != "!")\
		speech_args[SPEECH_MESSAGE] = applyAccent(message,replacements)
	return speech_args

/datum/accent/fly
	var/static/list/replacements = list(
		new /regex("z+", "g") = "zzz",
		new /regex("Z+", "g") = "ZZZ",
		new /regex("з+", "g") = "ззз",
		new /regex("З+", "g") = "ЗЗЗ",
		new /regex("ж+", "g") = "жжж",
		new /regex("Ж+", "g") = "ЖЖЖ",
		)

/datum/accent/fly/modify_speech(list/speech_args)
	var/message = speech_args[SPEECH_MESSAGE]
	if(message[1] != "*" && message[1] != "!")
		speech_args[SPEECH_MESSAGE] = applyAccent(message,replacements)
	return speech_args

/datum/accent/abductor/modify_speech(list/speech_args, datum/source)
	var/message = speech_args[SPEECH_MESSAGE]
	var/mob/living/carbon/user = source
	var/obj/item/organ/tongue/abductor/A = user.getorgan(/obj/item/organ/tongue/abductor)
	var/rendered = "<span class='abductor'><b>[user.name]:</b> [message]</span>"
	user.log_talk(message, LOG_SAY, tag="abductor")
	for(var/mob/living/carbon/C in GLOB.alive_mob_list)
		var/obj/item/organ/tongue/abductor/T = C.getorgan(/obj/item/organ/tongue/abductor)
		if(!T || T.mothership != A.mothership)
			continue
		to_chat(C, rendered)
	for(var/mob/M in GLOB.dead_mob_list)
		var/link = FOLLOW_LINK(M, user)
		to_chat(M, "[link] [rendered]")
	speech_args[SPEECH_MESSAGE] = ""
	return speech_args

/datum/accent/zombie/modify_speech(list/speech_args)
	var/message = speech_args[SPEECH_MESSAGE]
	var/list/message_list = splittext(message, " ")
	var/maxchanges = max(round(message_list.len / 1.5), 2)

	for(var/i = rand(maxchanges / 2, maxchanges), i > 0, i--)
		var/insertpos = rand(1, message_list.len - 1)
		var/inserttext = message_list[insertpos]

		if(!(copytext(inserttext, -3) == "..."))//3 == length("...")
			message_list[insertpos] = inserttext + "..."

		if(prob(20) && message_list.len > 3)
			message_list.Insert(insertpos, "[pick("МОЗГИ", "Мозги", "Мооозгиии", "МООЗГИИИ")]...")

	speech_args[SPEECH_MESSAGE] = jointext(message_list, " ")
	return speech_args

/datum/accent/alien/modify_speech(list/speech_args, datum/source)
	playsound(source, "hiss", 25, 1, 1)
	return speech_args

/datum/accent/fluffy
	var/static/list/replacements = list(
		"ne" = "ney",
		"nu" = "nyu",
		"na" = "nya",
		"no" = "nyo",
		"ove" = "uv",
		"l" = "w",
		"r" = "w",
		"не" = "ня",
		"ну" = "ню",
		"на" = "ня",
		"но" = "ню",
		"ов" = "ув",
		"р" = "ря",
		"мо" = "мя",
		)

/datum/accent/fluffy/modify_speech(list/speech_args)
	var/message = speech_args[SPEECH_MESSAGE]
	if(message[1] != "*" && message[1] != "!")
		speech_args[SPEECH_MESSAGE] = applyAccent(message,replacements)
	return speech_args

/datum/accent/span
	var/span_flag

/datum/accent/span/modify_speech(list/speech_args)
	speech_args[SPEECH_SPANS] |= span_flag
	return speech_args

//bone tongues either have the sans accent or the papyrus accent
/datum/accent/span/sans
	span_flag = SPAN_SANS

/datum/accent/span/papyrus
	span_flag = SPAN_PAPYRUS

/datum/accent/span/robot
	span_flag = SPAN_ROBOT

/datum/accent/dullahan/modify_speech(list/speech_args, datum/source, mob/living/carbon/owner)
	if(owner)
		var/datum/component/dullahan/dullahan = owner.GetComponent(/datum/component/dullahan)
		if(dullahan)
			if(dullahan.dullahan_head)
				dullahan.dullahan_head.say(speech_args[SPEECH_MESSAGE])
	speech_args[SPEECH_MESSAGE] = ""
	return speech_args
