/*
 	Miauw's big Say() rewrite.
	This file has the basic atom/movable level speech procs.
	And the base of the send_speech() proc, which is the core of saycode.
*/
// Ключи оформления тега должности из get_radio_job_style().
#define RADIO_JOB_STYLE_CLASSES "classes"
#define RADIO_JOB_STYLE_LEGACY "legacy"
#define RADIO_JOB_STYLE_ICON "icon"

GLOBAL_LIST_INIT(freqtospan, list(
	"[FREQ_SCIENCE]" = "sciradio",
	"[FREQ_MEDICAL]" = "medradio",
	"[FREQ_ENGINEERING]" = "engradio",
	"[FREQ_SUPPLY]" = "suppradio",
	"[FREQ_SERVICE]" = "servradio",
	"[FREQ_SECURITY]" = "secradio",
	"[FREQ_COMMAND]" = "comradio",
	"[FREQ_HOTEL]" = "servradio", //SPLURT EDIT ADDITION
	"[FREQ_AI_PRIVATE]" = "aiprivradio",
	"[FREQ_SYNDICATE]" = "syndradio",
	"[FREQ_CENTCOM]" = "centcomradio",
	"[FREQ_DS1]" = "syndradio", //BLUEMOON EDIT ADDITION - MAPPING
	"[FREQ_DS2]" = "syndradio", //BLUEMOON EDIT ADDITION - MAPPING
	"[FREQ_PIRATE]" = "syndradio", //BLUEMOON EDIT ADDITION - MAPPING
	"[FREQ_INTEQ]" = "inteqradio", //BLUEMOON EDIT ADDITION - MAPPING
	"[FREQ_GHOST_INTEQ]" = "inteqradio", //BLUEMOON EDIT ADDITION - MAPPING
	"[FREQ_TARKOFF]" = "engradio", //BLUEMOON EDIT ADDITION - MAPPING
	"[FREQ_SOL]" = "blueteamradio", //BlueMoon Kovac Added
	"[FREQ_LAW]" = "lawradio", //BlueMoon Fink Added
	"[FREQ_NRI]" = "redteamradio",
	"[FREQ_CTF_RED]" = "redteamradio",
	"[FREQ_CTF_BLUE]" = "blueteamradio"
	))

/atom/movable/proc/say(message, bubble_type, var/list/spans = list(), sanitize = TRUE, datum/language/language = null, ignore_spam = FALSE, forced = null)
	if(!can_speak())
		return
	if(message == "" || !message || QDELING(src))
		return
	spans |= speech_span
	if(!language)
		language = get_selected_language()
	send_speech(message, 7, src, , spans, message_language=language)

/atom/movable/proc/Hear(message, atom/movable/speaker, message_language, raw_message, radio_freq, list/spans, message_mode, atom/movable/source)
	SEND_SIGNAL(src, COMSIG_MOVABLE_HEAR, args)

/atom/movable/proc/bark(list/hearers, distance, volume, pitch, queue_time)
	if(queue_time && vocal_current_bark != queue_time)
		return
	if(SEND_SIGNAL(src, COMSIG_MOVABLE_BARK, hearers, distance, volume, pitch))
		return //bark interception. this probably counts as some flavor of BDSM
	if(!vocal_bark)
		if(!vocal_bark_id || !set_bark(vocal_bark_id)) //just-in-time bark generation
			return
	volume = min(volume, 100)
	var/turf/T = get_turf(src)
	for(var/mob/M in hearers)
		var/bark_vol = round((M.client?.prefs?.get_sound_volume("bark")) * volume / 100)
		M.playsound_local(T, vol = bark_vol, vary = TRUE, frequency = pitch, max_distance = distance, falloff_distance = 0, falloff_exponent = BARK_SOUND_FALLOFF_EXPONENT(distance), S = vocal_bark, distance_multiplier = 1)

/atom/movable/proc/can_speak()
	return TRUE

/atom/movable/proc/send_speech(message, range = 7, atom/movable/source = src, bubble_type, list/spans, datum/language/message_language = null, message_mode)
	var/rendered = compose_message(src, message_language, message, , spans, message_mode, source)
	var/list/hearers = get_hearers_in_view(range, source)
	for(var/_AM in hearers)
		var/atom/movable/AM = _AM
		AM.Hear(rendered, src, message_language, message, , spans, message_mode, source)
	if(message_language && initial(message_language.visual_language)) //визуальный язык не звучит
		return
	if(SEND_SIGNAL(src, COMSIG_MOVABLE_QUEUE_BARK, hearers, args) || vocal_bark || vocal_bark_id)
		// Барк-таймеры ставим только ради слушателей с клиентом и включённым SOUND_BARK:
		// анонс по всем ньюскастерам станции ставил 500+ таймеров одним тиком в пустые
		// комнаты (TIMER BURST раунда 9746), а bark() всё равно играет звук только клиентам.
		var/list/bark_hearers = list()
		for(var/mob/M in hearers)
			if(!M.client)
				continue
			if(!(M.client.prefs.toggles & SOUND_BARK))
				continue
			bark_hearers += M
		if(!length(bark_hearers))
			return
		var/barks = min(round((LAZYLEN(message) / vocal_speed)) + 1, BARK_MAX_BARKS)
		var/total_delay
		vocal_current_bark = world.time //this is juuuuust random enough to reliably be unique every time send_speech() is called, in most scenarios
		for(var/i in 1 to barks)
			if(total_delay > BARK_MAX_TIME)
				break
			addtimer(CALLBACK(src, PROC_REF(bark), bark_hearers, range, vocal_volume, BARK_DO_VARY(vocal_pitch, vocal_pitch_range), vocal_current_bark), total_delay)
			total_delay += rand(DS2TICKS(vocal_speed / BARK_SPEED_BASELINE), DS2TICKS(vocal_speed / BARK_SPEED_BASELINE) + DS2TICKS(vocal_speed / BARK_SPEED_BASELINE)) TICKS

/atom/movable/proc/compose_message(atom/movable/speaker, datum/language/message_language, raw_message, radio_freq, list/spans, message_mode, face_name = FALSE, atom/movable/source)
	if(!source)
		source = speaker
	//This proc uses text() because it is faster than appending strings. Thanks BYOND.
	//Basic span
	var/spanpart1 = "<span class='[radio_freq ? get_radio_span(radio_freq) : "game say"]'>"
	//Start name span.
	var/spanpart2 = "<span class='name'>"
	//Radio freq/name display
	var/freqpart = radio_freq ? "\[[get_radio_name(radio_freq)]\] " : ""
	var/jobpart = ""
	var/list/job_style
	if(radio_freq)
		var/speaker_job = speaker.GetJob()
		var/lower_job = speaker_job ? lowertext(trimtext(speaker_job)) : ""
		if(lower_job != "" && lower_job != "unknown" && lower_job != "no id" && lower_job != "machine")
			if(speaker.GetVoice() != "Unknown")
				job_style = speaker.GetJobStyle() || get_radio_job_style(null, speaker_job)
				var/job_icon = job_style[RADIO_JOB_STYLE_ICON]
				// Класс старого вывода первым: его красит client/script, остальные классы - чат tgui.
				// Пробел внутри тега: скрытый тег не оставляет двойного пробела.
				jobpart = "[job_icon ? "<span class='radiojob-icon [job_icon]'></span>" : ""]<span class='radiojob-legacy-[job_style[RADIO_JOB_STYLE_LEGACY]] radiojob [job_style[RADIO_JOB_STYLE_CLASSES]]'>\[[speaker_job]\] </span>"
	//Speaker name
	var/namepart = "[speaker.GetVoice()][speaker.get_alt_name()]"
	if(face_name && ishuman(speaker))
		var/mob/living/carbon/human/H = speaker
		namepart = "[H.get_face_name()]" //So "fake" speaking like in hallucinations does not give the speaker away if disguised
	// Старый вывод имя не красил, прежняя раскраска имени - отдельный класс только для tgui.
	var/shown_name = job_style ? "<span class='radiojob-name [job_style[RADIO_JOB_STYLE_CLASSES]] radiojob-name-legacy-[job_style[RADIO_JOB_STYLE_LEGACY]]'>[namepart]</span>" : namepart
	//End name span.
	var/endspanpart = "</span>"

	//Message
	var/messagepart = " <span class='message'>[lang_treat(speaker, message_language, raw_message, spans, message_mode)]</span></span>"

	var/languageicon = ""
	var/datum/language/D = GLOB.language_datum_instances[message_language]
	if(istype(D) && D.display_icon(src))
		languageicon = "[D.get_icon()] "

	return "[spanpart1][spanpart2][freqpart][jobpart][languageicon][compose_track_href(speaker, namepart)][shown_name][compose_job(speaker, message_language, raw_message, radio_freq)][endspanpart][messagepart]"

/atom/movable/proc/compose_track_href(atom/movable/speaker, message_langs, raw_message, radio_freq)
	return ""

/atom/movable/proc/compose_job(atom/movable/speaker, message_langs, raw_message, radio_freq)
	return ""

/atom/movable/proc/say_mod(input, message_mode)
	var/ending = copytext_char(input, -1)
	if(copytext_char(input, -2) == "!!")
		return verb_yell
	else if(ending == "?")
		return verb_ask
	else if(ending == "!")
		return verb_exclaim
	else
		return verb_say

/atom/movable/proc/say_quote(input, list/spans=list(speech_span), message_mode)
	if(!input)
		input = "..."

	if(copytext_char(input, -2) == "!!")
		spans |= SPAN_YELL

	var/spanned = attach_spans(input, spans)
	return "[say_mod(input, message_mode)][spanned ? ", \"[spanned]\"" : ""]"
	// Citadel edit [spanned ? ", \"[spanned]\"" : ""]"

/// Replaces one delimiter pair (e.g. |...|) with HTML. No regex — avoids Replace_char crash (illegal operation).
/atom/movable/proc/_emphasis_replace(input, chr, html_tag)
	var/zwsp = "&#8203;"
	var/pos = 1
	while(pos <= length(input))
		var/open_pos = findtext(input, chr, pos)
		if(!open_pos)
			break
		if(open_pos > 1 && copytext(input, open_pos - 1, open_pos) == "\\")
			pos = open_pos + 1
			continue
		var/close_pos = findtext(input, chr, open_pos + 1)
		if(!close_pos)
			break
		if(close_pos > open_pos + 1 && copytext(input, close_pos - 1, close_pos) == "\\")
			pos = close_pos + 1
			continue
		var/inner = copytext(input, open_pos + 1, close_pos)
		input = copytext(input, 1, open_pos) + "<[html_tag]>" + inner + "</[html_tag]>" + zwsp + copytext(input, close_pos + 1)
		pos = open_pos + 1
	return input

/// Removes backslash before |, +, _. No regex.
/atom/movable/proc/_emphasis_unescape(input)
	var/pos = 1
	while(pos < length(input))
		pos = findtext(input, "\\", pos)
		if(!pos)
			break
		if(pos + 1 <= length(input))
			var/next = copytext(input, pos + 1, pos + 2)
			if(next == "|" || next == "+" || next == "_")
				input = copytext(input, 1, pos) + copytext(input, pos + 1)
				pos++
				continue
		pos++
	return input

/// Scans the input sentence for speech emphasis modifiers: |italics|, +bold+, _underline_.
/// Uses manual parsing instead of regex to avoid Replace_char illegal operation crash.
/atom/movable/proc/say_emphasis(input)
	if(length_char(input) > MAX_SAY_EMPHASIS_LEN)
		input = copytext_char(input, 1, MAX_SAY_EMPHASIS_LEN + 1)
	input = _emphasis_replace(input, "|", "i")
	input = _emphasis_replace(input, "+", "b")
	input = _emphasis_replace(input, "_", "u")
	input = _emphasis_unescape(input)
	return input

/// Quirky citadel proc for our custom sayverbs to strip the verb out. Snowflakey as hell, say rewrite 3.0 when?
/atom/movable/proc/quoteless_say_quote(input, list/spans = list(speech_span), message_mode)
	if(!length(input))
		return ""
	if((input[1] == "!") && (length_char(input) > 1))
		return ""
	var/pos = findtext(input, "*")
	return pos? copytext(input, pos + 1) : input

/atom/movable/proc/lang_treat(atom/movable/speaker, datum/language/language, raw_message, list/spans, message_mode, no_quote = FALSE)
	if(has_language(language))
		var/atom/movable/AM = speaker.GetSource()
		raw_message = say_emphasis(raw_message)
		if(AM) //Basically means "if the speaker is virtual"
			return no_quote ? AM.quoteless_say_quote(raw_message, spans, message_mode) : AM.say_quote(raw_message, spans, message_mode)
		else
			return no_quote ? speaker.quoteless_say_quote(raw_message, spans, message_mode) : speaker.say_quote(raw_message, spans, message_mode)
	else if(language)
		var/atom/movable/AM = speaker.GetSource()
		var/datum/language/D = GLOB.language_datum_instances[language]
		raw_message = D.scramble(raw_message)
		if(AM)
			return no_quote ? AM.quoteless_say_quote(raw_message, spans, message_mode) : AM.say_quote(raw_message, spans, message_mode)
		else
			return no_quote ? speaker.quoteless_say_quote(raw_message, spans, message_mode) : speaker.say_quote(raw_message, spans, message_mode)
	else
		return "makes a strange sound."

/proc/get_radio_span(freq)
	var/returntext = GLOB.freqtospan["[freq]"]
	if(returntext)
		return returntext
	return "radio"

/proc/get_radio_name(freq)
	var/returntext = GLOB.reverseradiochannels["[freq]"]
	if(returntext)
		return returntext
	return "[copytext_char("[freq]", 1, 4)].[copytext_char("[freq]", 4, 5)]"

/// Оформление тега должности: классы отдела, фракции и главы для чата, id прежней раскраски и значок. Цвета задаёт чат.
/// Отдел, глава и значок - по показанному названию shown_job (custom_job карты), свободный текст - отдел профессии карты base_job без метки главы и значка.
/// Без карты (КПК) префикс наклейки снимается только перед точным названием профессии: "Syndicate Admiral" не капитан.
/proc/get_radio_job_style(base_job, display_job, shown_job)
	var/centcom_card = base_job && !SSjob.GetJob(base_job) && GetJobName(base_job) == "Centcom"
	var/datum/job/card_job = (base_job && !centcom_card) ? (SSjob.GetJob(base_job) || get_radio_shown_job(base_job, null)) : null
	var/shown = shown_job || base_job || display_job
	var/datum/job/job = (centcom_card && shown == base_job) ? null : get_radio_shown_job(shown, card_job)
	if(!job && !base_job)
		job = SSjob.GetJob(strip_radio_sticker_prefix(display_job))
	var/recognized = !!job
	if(!job)
		job = card_job
	var/centcom = !job && (centcom_card || GetJobName(shown) == "Centcom")
	var/faction = get_radio_job_faction(display_job || base_job)
	var/department
	if(job?.title == "Assistant")
		department = "asst"
	else if(job?.title == "Prisoner")
		department = "unk"
	else if(job)
		department = get_radio_job_department(job)
	else if(faction)
		department = faction
	else if(centcom)
		department = "centcom"
	else
		department = "unk"
	var/classes = "radiojob-[department]"
	if(faction)
		classes += " radiojob-f-[faction]"
	if(recognized && get_radio_head_jobs()[job.title])
		classes += " radiojob-head"
	// Неузнанное название: свой стейт роли вне SSjob, затем значок стороны.
	var/list/icon_states = recognized ? list(ckey(job.title)) : list(get_radio_role_icon(shown), get_radio_faction_icon(faction), centcom ? "centcom" : null)
	return radio_job_style(classes, faction || get_radio_job_legacy_class(job ? job.title : (centcom ? "Centcom" : "Unknown"), job), icon_states)

/// legacy - id прежней раскраски (radiojob-legacy-<id>), icon_states - стейт icons/ui_icons/tgui/jobs.dmi или список, берётся первый из листа.
/proc/radio_job_style(classes, legacy, icon_states)
	var/icon_class
	var/datum/asset/spritesheet_batched/chat/sheet = get_asset_datum(/datum/asset/spritesheet_batched/chat)
	for(var/icon_state in islist(icon_states) ? icon_states : list(icon_states))
		icon_class = icon_state && sheet.icon_class_name("job-[icon_state]")
		if(icon_class)
			break
	return list(RADIO_JOB_STYLE_CLASSES = classes, RADIO_JOB_STYLE_LEGACY = legacy, RADIO_JOB_STYLE_ICON = icon_class)

/// Метка главы в теге должности рации с аргументами get_radio_job_style().
/proc/is_radio_job_head(base_job, display_job, shown_job)
	var/list/style = get_radio_job_style(base_job, display_job, shown_job)
	return ("radiojob-head" in splittext(style[RADIO_JOB_STYLE_CLASSES], " "))

/// Стейт jobs.dmi роли вне SSjob по её названию. Только явный список: неточное название профессии ("Captain!", "A.I.") чужого значка не получает.
/proc/get_radio_role_icon(title)
	var/static/list/role_states = list(
		"deathcommando" = "deathcommando",
		"hotelmanager" = "hotelmanager",
		"hotelsecurity" = "hotelsecurity",
		"hotelstaff" = "hotelstaff",
		"hoteltourist" = "hoteltourist",
		"ds1communicationsofficer" = "ds1communicationsofficer",
		"ds1securityagent" = "ds1securityagent",
		"ds1bioweaponresearcher" = "ds1bioweaponresearcher",
		"ds1scientist" = "ds1scientist",
		"ds1nuclearspecialist" = "ds1nuclearspecialist",
		"ds1mime" = "ds1mime",
		"ds2admiral" = "ds2admiral",
		"ds2corporateliaison" = "ds2corporateliasion",
		"ds2corporateliasion" = "ds2corporateliasion",
		"ds2masteratarms" = "ds2masteratarms",
		"ds2brigofficer" = "ds2brigofficer",
		"ds2commsagent" = "ds2commsagent",
		"ds2medicalofficer" = "ds2medicalofficer",
		"ds2enginetechnician" = "ds2enginetechnician",
		"ds2researcher" = "ds2researcher",
		"ds2generalstaff" = "ds2generalstaff",
		"ds2hostage" = "ds2hostage",
	)
	return title && role_states[ckey(strip_radio_sticker_prefix(title))]

/proc/get_radio_faction_icon(faction)
	switch(faction)
		if("synd")
			return "syndicate"
		if("hotel")
			return "hotelstaff"
		if("inteq", "sol", "nri", "centcom")
			return faction
	return null

/// Профессия названия: профессия карты, если это её название или альт-название, иначе однозначная чужая, неоднозначное - свободный текст. GetJobName() тут не годится: в real_job_name общие альт-названия перезаписывают друг друга.
/proc/get_radio_shown_job(title, datum/job/card_job)
	if(!title)
		return null
	if(card_job && (title == card_job.title || (title in card_job.alt_titles)))
		return card_job
	var/datum/job/exact = SSjob.GetJob(title)
	if(exact)
		return exact
	var/datum/job/found
	for(var/datum/job/candidate as anything in SSjob.occupations)
		if(!(title in candidate.alt_titles))
			continue
		if(found)
			return null
		found = candidate
	return found

/proc/strip_radio_sticker_prefix(title)
	var/static/list/prefixes
	if(!prefixes)
		prefixes = list()
		for(var/obj/item/card_sticker/sticker_type as anything in subtypesof(/obj/item/card_sticker))
			var/prefix = initial(sticker_type.prefix)
			if(prefix)
				prefixes |= prefix
	if(!title)
		return title
	for(var/prefix in prefixes)
		if(findtextEx(title, "[prefix] ") == 1)
			return copytext(title, length(prefix) + 2)
	return title

/proc/get_radio_job_faction(shown_title)
	if(!shown_title)
		return null
	var/combined = lowertext(shown_title)
	if(findtext(combined, "syndicate") || findtext(combined, "syndicom") || findtext(combined, "синдикат") || findtext(combined, "ds-1") || findtext(combined, "ds-2") || findtext(combined, "ds1") || findtext(combined, "ds2"))
		return "synd"
	if(findtext(combined, "inteq") || findtext(combined, "интек") || findtext(combined, "vanguard") || findtext(combined, "авангард") || findtext(combined, "mercenary") || findtext(combined, "наемник") || findtext(combined, "наёмник"))
		return "inteq"
	if(findtext(combined, "tarkov") || findtext(combined, "tarkoff") || findtext(combined, "тарков") || findtext(combined, "таркон"))
		return "tarkon"
	if(findtext(combined, "pirate") || findtext(combined, "пират"))
		return "pirate"
	if(findtext(combined, "solfed") || findtext(combined, "sol fed") || findtext(combined, "sol federation"))
		return "sol"
	if(findtext(combined, "nri"))
		return "nri"
	if(findtext(combined, "hotel") || findtext(combined, "отель"))
		return "hotel"
	if(findtext(combined, "centcom") || findtext(combined, "central command") || findtext(combined, "emergency response") || findtext(combined, "death commando") || findtext(combined, "response officer") || findtext(combined, "health safety"))
		return "centcom"
	return null

/// Отдел профессии, а без своих битов отдела - отдел её начальника.
/proc/get_radio_job_department(datum/job/job)
	var/departments = job.departments
	if(!departments)
		for(var/head_title in job.department_head)
			var/datum/job/head = SSjob.GetJob(head_title)
			if(head?.departments)
				departments = head.departments
				break
	return get_radio_department_class(departments)

/proc/get_radio_department_class(departments)
	if(departments & DEPARTMENT_BITFLAG_SECURITY)
		return "sec"
	if(departments & DEPARTMENT_BITFLAG_ENGINEERING)
		return "eng"
	if(departments & DEPARTMENT_BITFLAG_MEDICAL)
		return "med"
	if(departments & DEPARTMENT_BITFLAG_SCIENCE)
		return "sci"
	if(departments & DEPARTMENT_BITFLAG_SUPPLY)
		return "cargo"
	if(departments & DEPARTMENT_BITFLAG_LAW)
		return "law"
	if(departments & DEPARTMENT_BITFLAG_SERVICE)
		return "srv"
	if(departments & DEPARTMENT_BITFLAG_SILICON)
		return "silicon"
	if(departments & DEPARTMENT_BITFLAG_COMMAND)
		return "cmd"
	return "unk"

/// Раскраска до разделения по отделам: настройка чата "По профессии (как раньше)".
/proc/get_radio_job_legacy_class(real, datum/job/job)
	switch(real)
		if("Clown")
			return "clown"
		if("Centcom")
			return "centcom"
		if("Bridge Officer", "NanoTrasen Representative", "Head of Personnel")
			return "cmd"
		if("Assistant")
			return "asst"
		if("Peacekeeper", "Detective")
			return "sec"
	return job ? get_radio_department_class(job.departments) : "unk"

/// Главы - профессии, которые другие профессии называют своим department_head.
/proc/get_radio_head_jobs()
	var/static/list/heads
	if(length(heads))
		return heads
	heads = list()
	for(var/datum/job/job as anything in SSjob.occupations)
		for(var/head_title in job.department_head)
			if(SSjob.GetJob(head_title))
				heads[head_title] = TRUE
	return heads

/atom/movable/proc/attach_spans(input, list/spans)
	if(!length(input))
		return
	if((input[1] == "!") && (length(input) > 2))
		return
	var/customsayverb = findtext(input, "*")
	if(customsayverb)
		input = capitalize(copytext(input, customsayverb + length(input[customsayverb])))
	if(input)
		return "[message_spans_start(spans)][input]</span>"
	else
		return

/proc/message_spans_start(list/spans)
	var/output = "<span class='"
	for(var/S in spans)
		output = "[output][S] "
	output = "[output]'>"
	return output

/proc/say_test(text)
	var/ending = copytext_char(text, -1)
	if (ending == "?")
		return "1"
	else if (ending == "!")
		return "2"
	return "0"

/atom/movable/proc/GetVoice()
	return "[src]"	//Returns the atom's name, prepended with 'The' if it's not a proper noun

/atom/movable/proc/IsVocal()
	return TRUE

/atom/movable/proc/get_alt_name()

//HACKY VIRTUALSPEAKER STUFF BEYOND THIS POINT
//these exist mostly to deal with the AIs hrefs and job stuff.

/atom/movable/proc/GetJob() //Get a job, you lazy butte

/// Оформление тега должности в рации из get_radio_job_style() или null.
/atom/movable/proc/GetJobStyle()

/atom/movable/proc/GetSource()

/atom/movable/proc/GetRadio()

//VIRTUALSPEAKERS
/atom/movable/virtualspeaker
	var/job
	var/list/job_style
	var/atom/movable/source
	var/obj/item/radio/radio

INITIALIZE_IMMEDIATE(/atom/movable/virtualspeaker)
/atom/movable/virtualspeaker/Initialize(mapload, atom/movable/M, obj/item/radio/new_radio)
	. = ..()
	set_source(M)
	set_radio(new_radio)
	if (istype(M))
		name = M.GetVoice()
		verb_say = M.verb_say
		verb_ask = M.verb_ask
		verb_exclaim = M.verb_exclaim
		verb_yell = M.verb_yell

	// The mob's job identity
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		var/obj/item/card/id/idcard = H.wear_id?.GetID()
		if(!idcard)
			idcard = H.wear_neck?.GetID()
		if(!idcard && H.belt)
			idcard = H.belt?.GetID()
		if(idcard)
			job = idcard.get_assignment_name()
			if(!job || job == "")
				job = null
				job_style = null
			else
				job_style = get_radio_job_style(idcard.assignment, job, idcard.custom_job)
		else
			if(istype(H.wear_id, /obj/item/modular_computer/pda))
				var/obj/item/modular_computer/pda/worn_pda = H.wear_id
				if(worn_pda.ownjob && worn_pda.ownjob != "")
					job = worn_pda.ownjob
					job_style = get_radio_job_style(null, job)
				else
					job = null
					job_style = null
			else
				job = null
				job_style = null
	else if(iscarbon(M))  // Carbon nonhuman
		job = "No ID"
		job_style = null
	else if(isAI(M))  // AI
		job = "AI"
		job_style = radio_job_style("radiojob-silicon", "silicon", "ai")
	else if(iscyborg(M))  // Cyborg
		var/mob/living/silicon/robot/B = M
		job = "[B.designation] Cyborg"
		job_style = radio_job_style("radiojob-silicon", "silicon", "cyborg")
	else if(istype(M, /mob/living/silicon/pai))  // Personal AI (pAI)
		var/mob/living/silicon/pai/pai = M
		job = pai.GetJob()
		// С энкодером тег целиком как у показанной должности, иначе значок pAI выдаёт подделку.
		job_style = (pai.encoder_active && pai.encoder_job) ? get_radio_job_style(null, job) : radio_job_style("radiojob-silicon", "silicon", "pai")
	else if(isobj(M))  // Cold, emotionless machines
		job = "Machine"
		job_style = radio_job_style("radiojob-unk", "unk")
	else  // Unidentifiable mob
		job = "Unknown"
		job_style = null

/atom/movable/virtualspeaker/Destroy()
	set_source(null)
	set_radio(null)
	return ..()

/atom/movable/virtualspeaker/proc/set_source(atom/movable/new_source)
	if(source == new_source)
		return
	if(source)
		UnregisterSignal(source, COMSIG_PARENT_QDELETING)
	source = new_source
	if(source)
		RegisterSignal(source, COMSIG_PARENT_QDELETING, PROC_REF(on_source_qdeleting))

/atom/movable/virtualspeaker/proc/on_source_qdeleting(atom/movable/deleted_source)
	SIGNAL_HANDLER
	if(source == deleted_source)
		set_source(null)

/atom/movable/virtualspeaker/proc/set_radio(obj/item/radio/new_radio)
	if(radio == new_radio)
		return
	if(radio)
		UnregisterSignal(radio, COMSIG_PARENT_QDELETING)
	radio = new_radio
	if(radio)
		RegisterSignal(radio, COMSIG_PARENT_QDELETING, PROC_REF(on_radio_qdeleting))

/atom/movable/virtualspeaker/proc/on_radio_qdeleting(obj/item/radio/deleted_radio)
	SIGNAL_HANDLER
	if(radio == deleted_radio)
		set_radio(null)

/atom/movable/virtualspeaker/GetJob()
	return job

/atom/movable/virtualspeaker/GetJobStyle()
	return job_style

/atom/movable/virtualspeaker/GetSource()
	return source

/atom/movable/virtualspeaker/GetRadio()
	return radio

#undef RADIO_JOB_STYLE_CLASSES
#undef RADIO_JOB_STYLE_LEGACY
#undef RADIO_JOB_STYLE_ICON
