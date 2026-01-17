GLOBAL_LIST_INIT(department_radio_prefixes, list(":", "."))

GLOBAL_LIST_INIT(department_radio_keys, list(
	// Location
	MODE_KEY_R_HAND = MODE_R_HAND,
	MODE_KEY_L_HAND = MODE_L_HAND,
	MODE_KEY_INTERCOM = MODE_INTERCOM,

	// Department
	MODE_KEY_DEPARTMENT = MODE_DEPARTMENT,
	RADIO_KEY_COMMAND = RADIO_CHANNEL_COMMAND,
	RADIO_KEY_SCIENCE = RADIO_CHANNEL_SCIENCE,
	RADIO_KEY_MEDICAL = RADIO_CHANNEL_MEDICAL,
	RADIO_KEY_ENGINEERING = RADIO_CHANNEL_ENGINEERING,
	RADIO_KEY_SECURITY = RADIO_CHANNEL_SECURITY,
	RADIO_KEY_SUPPLY = RADIO_CHANNEL_SUPPLY,
	RADIO_KEY_SERVICE = RADIO_CHANNEL_SERVICE,
	RADIO_KEY_LAW = RADIO_CHANNEL_LAW,
	// Faction
	RADIO_KEY_SYNDICATE = RADIO_CHANNEL_SYNDICATE,
	RADIO_KEY_CENTCOM = RADIO_CHANNEL_CENTCOM,
	RADIO_KEY_HOTEL = RADIO_CHANNEL_HOTEL, //SPLURT EDIT ADDITION
	RADIO_KEY_PIRATE = RADIO_CHANNEL_PIRATE,
	RADIO_KEY_INTEQ = RADIO_CHANNEL_INTEQ,

	// Ghost-Roles
	RADIO_KEY_DS1 = RADIO_CHANNEL_DS1,
	RADIO_KEY_DS2 = RADIO_CHANNEL_DS2,
	RADIO_KEY_TARKOFF = RADIO_CHANNEL_TARKOFF,

	// Admin
	MODE_KEY_ADMIN = MODE_ADMIN,
	MODE_KEY_DEADMIN = MODE_DEADMIN,

	// Misc
	RADIO_KEY_AI_PRIVATE = RADIO_CHANNEL_AI_PRIVATE, // AI Upload channel
	MODE_KEY_VOCALCORDS = MODE_VOCALCORDS,		// vocal cords, used by Voice of God


	//kinda localization -- rastaf0
	//same keys as above, but on russian keyboard layout.
	// Location
	"к" = MODE_R_HAND,
	"л" = MODE_L_HAND,
	"ш" = MODE_INTERCOM,

	// Department
	"р" = MODE_DEPARTMENT,
	"с" = RADIO_CHANNEL_COMMAND,
	"т" = RADIO_CHANNEL_SCIENCE,
	"ь" = RADIO_CHANNEL_MEDICAL,
	"у" = RADIO_CHANNEL_ENGINEERING,
	"ы" = RADIO_CHANNEL_SECURITY,
	"г" = RADIO_CHANNEL_SUPPLY,
	"м" = RADIO_CHANNEL_SERVICE,
	"д" = RADIO_CHANNEL_LAW,
	// Faction
	"е" = RADIO_CHANNEL_SYNDICATE,
	"н" = RADIO_CHANNEL_CENTCOM,
	// Ghostrole
	"й" = RADIO_CHANNEL_DS1,
	"ц" = RADIO_CHANNEL_DS2,

	// Admin
	"з" = MODE_ADMIN,
	"в" = MODE_KEY_DEADMIN,

	// Misc
	"щ" = RADIO_CHANNEL_AI_PRIVATE,
	"ч" = MODE_VOCALCORDS
))
/proc/auto_capitalize(text)
	if(!text || text == "")
		return text

	text = trim_left(text)

	// если строка начинается с префикса языка (например ",r") — не трогаем его
	if(copytext_char(text, 1, 1) == "," && length_char(text) >= 2)
		var/prefix = copytext_char(text, 1, 2)
		var/body = copytext_char(text, 3)
		return prefix + auto_capitalize(body)

	var/result = ""
	var/next_cap = TRUE
	var/i = 1
	var/len = length_char(text)

	while(i <= len)
		var/ch = copytext_char(text, i, i+1)
		var/nextch = (i < len) ? copytext_char(text, i+1, i+2) : ""
		var/nextnext = (i+1 < len) ? copytext_char(text, i+2, i+3) : ""
		var/prevch = (i > 1) ? copytext_char(text, i-1, i) : ""

		// Если ожидается заглавная и это буква — делаем кап
		if(next_cap && lowertext(ch) != uppertext(ch))
			// проверяем контекст — не капаем, если предыдущий символ не разделитель
			if(i > 1 && !(prevch == " " || prevch == "\t" || prevch == "\n" || prevch == "." || prevch == "!" || prevch == "?" || prevch == "\"" || prevch == "«" || prevch == "“" || prevch == "," || prevch == ";"))
				result += ch
				next_cap = FALSE
				i += 1
				continue

			result += uppertext(ch)
			next_cap = FALSE
		else
			result += ch

		// Проверяем на конец предложения, но игнорируем ...
		if(ch == "." || ch == "!" || ch == "?")
			// Если три точки подряд — не конец предложения
			if(!(ch == "." && nextch == "." && nextnext == "."))
				next_cap = TRUE

				// Если после .!? нет пробела — добавляем
				if(i < len)
					if(nextch != " " && nextch != "." && nextch != "!" && nextch != "?" && nextch != "\t" && nextch != "\n")
						// если после идёт цифра (3.14), то не вставляем пробел
						if(!isnum(text2num(nextch)))
							result += " "

		// Не включаем капитализацию после - или % или других "связующих" знаков
		if(ch == "-" || ch == "%" || ch == "*" || ch == ":" || ch == ";" || ch == "'" || ch == ")" || ch == "]" || ch == "°")
			next_cap = FALSE

		// Если встретили кавычку — ожидаем заглавную после неё
		if(ch == "\"" || ch == "«" || ch == "“")
			next_cap = TRUE
			// Убираем лишний пробел сразу после кавычки
			if(i < len)
				var/nextch2 = copytext_char(text, i+1, i+2)
				if(nextch2 == " ")
					i += 1 // пропускаем его

		// Теперь сбрасываем next_cap ТОЛЬКО если текущий символ не является
		// разделителем/пунктуацией/кавычкой/пробелом — тогда следующая буква не должна капитализироваться.
		if(ch != " " && ch != "\t" && ch != "\n" && ch != "." && ch != "!" && ch != "?" && ch != "\"" && ch != "«" && ch != "“")
			next_cap = FALSE

		i += 1

	return result






/mob/living/proc/Ellipsis(original_msg, chance = 50, keep_words)
	if(chance <= 0)
		return "..."
	if(chance >= 100)
		return original_msg

	var/list/words = splittext(original_msg," ")
	var/list/new_words = list()

	var/new_msg = ""

	for(var/w in words)
		if(prob(chance))
			new_words += "..."
			if(!keep_words)
				continue
		new_words += w

	new_msg = jointext(new_words," ")

	return new_msg

/mob/living/say(message, bubble_type,var/list/spans = list(), sanitize = TRUE, datum/language/language = null, ignore_spam = FALSE, forced = null)
	set waitfor = FALSE
	// Данные режимы обходят проверку на крит и не превращаются в разговор "на последнем вздохе"
	var/static/list/special_crit_modes = list(MODE_CHANGELING = TRUE, MODE_ALIEN = TRUE)  // BLUEMOON EDIT - правки last breath'а
	var/static/list/unconscious_allowed_modes = list(MODE_CHANGELING = TRUE, MODE_ALIEN = TRUE)
	var/talk_key = get_key(message)

	var/static/list/one_character_prefix = list(MODE_HEADSET = TRUE, MODE_ROBOT = TRUE, MODE_WHISPER = TRUE, MODE_SING = TRUE)

	var/ic_blocked = FALSE

	if(!isclownjob(src))
		if(!(src?.onCentCom()))
			if(client && !forced && CHAT_FILTER_CHECK(message))
				ic_blocked = TRUE


	if(sanitize)
		message = trim(copytext_char(sanitize(message), 1, MAX_MESSAGE_LEN))
	if(!message || message == "")
		return

	if(ic_blocked)
		var/matched_word = find_any_whole_word(message, config.ic_filter_regex)
		SSblackbox.record_feedback("tally", "ic_blocked_words", 1, lowertext(matched_word))
		to_chat(src, "<span class='warning'>Вы сказали:\n<span replaceRegex='show_filtered_ic_chat'>\"[lowertext(matched_word)]\".</span> Это плохое слово. Вы будете за это наказаны повреждением мозга.</span>")
		log_admin("[ADMIN_LOOKUPFLW(usr)] сказал плохое слово: [lowertext(matched_word)].")
		message_admins("[ADMIN_LOOKUPFLW(usr)] сказал плохое слово: [lowertext(matched_word)].")
		src.adjustOrganLoss(ORGAN_SLOT_BRAIN, 25, 175)

	var/datum/saymode/saymode = SSradio.saymodes[talk_key]
	var/message_mode = get_message_mode(message)
	var/original_message = message
	var/in_critical = InCritical()
	var/fullcrit = InFullCritical() // BLUEMOON EDIT - правки last breath'а

	if(one_character_prefix[message_mode])
		message = copytext_char(message, 2)
	else if(message_mode || saymode)
		message = copytext_char(message, 3)
	message = trim_left(message)
	if(copytext_char(message, 1, 2) == " ")
		message = copytext_char(message, 2)
	if(!message)
		return
	if(message_mode == MODE_ADMIN)
		if(client)
			client.cmd_admin_say(message)
		return

	if(message_mode == MODE_DEADMIN)
		if(client)
			client.dsay(message)
		return

	if(stat == DEAD)
		say_dead(original_message)
		return

	if(check_emote(original_message) || !can_speak_basic(original_message, ignore_spam))
		return

	else if(stat == UNCONSCIOUS && !fullcrit) // BLUEMOON EDIT - правки last breath'а
		if(!(unconscious_allowed_modes[message_mode]))
			return

	// language comma detection.
	var/datum/language/message_language = get_message_language(message)
	if(message_language)
		// No, you cannot speak in xenocommon just because you know the key
		if(can_speak_language(message_language))
			language = message_language
		message = copytext_char(message, 3)

		// Trim the space if they said ",0 I LOVE LANGUAGES"
		message = trim_left(message)

	if(!language)
		language = get_selected_language()

	// Detection of language needs to be before inherent channels, because
	// AIs use inherent channels for the holopad. Most inherent channels
	// ignore the language argument however.

	if(saymode && !saymode.handle_message(src, message, language))
		return

	if(!can_speak_vocal(message))
		to_chat(src, "<span class='warning'>Вы не можете говорить!</span>")
		return

	var/message_range = 7

	var/succumbed = FALSE

	// BLUEMOON EDIT START - правки last breath'а
	if(in_critical && !special_crit_modes[message_mode])
		message_range = 2
		message_mode = MODE_WHISPER
		src.log_talk(message, LOG_WHISPER)
		if(fullcrit)
			var/confirm = alert(src, "You are in full crit and can't talk, but you can whisper it in your last breath and succumb to death. Proceed?", "Last Breath", "Yes", "Cancel")
			if(!confirm || confirm == "Cancel")
				return
			var/health_diff = round(-HEALTH_THRESHOLD_DEAD + health)
			// If we cut our message short, abruptly end it with a-..
			var/message_len = length_char(message)
			message = copytext_char(message, 1, health_diff) + "[message_len > health_diff ? "-.." : "..."]"
			message = Ellipsis(message, 10, 1)
			message_mode = MODE_WHISPER_CRIT
			succumbed = TRUE
	// BLUEMOON EDIT END
	else if(message_mode == MODE_WHISPER)
		message_range = 1
		message_mode = MODE_WHISPER
		src.log_talk(message, LOG_WHISPER)
	else
		src.log_talk(message, LOG_SAY, forced_by=forced)

	if(message[1] != "!")
		message = treat_message(message) // unfortunately we still need this
	var/sigreturn = SEND_SIGNAL(src, COMSIG_MOB_SAY, args)
	if (sigreturn & COMPONENT_UPPERCASE_SPEECH)
		message = uppertext(message)
	if(!message)
		return

	last_words = message

	spans |= speech_span

	if(language)
		var/datum/language/L = GLOB.language_datum_instances[language]
		spans |= L.spans

// Skyrat edits
	if(message_mode == MODE_SING)
	#if DM_VERSION < 513
		var/randomnote = "~"
	#else
		var/randomnote = pick("\u2669", "\u266A", "\u266B")
	#endif
		spans |= SPAN_SINGING
		message = "[randomnote] [message] [randomnote]"
// End of Skyrat edits

	var/radio_return = radio(message, message_mode, spans, language)
	if(radio_return & ITALICS)
		spans |= SPAN_ITALICS
	if(radio_return & REDUCE_RANGE)
		message_range = 1
	if(radio_return & NOPASS)
		return TRUE

	//No screams in space, unless you're next to someone.
	var/turf/T = get_turf(src)
	var/datum/gas_mixture/environment = T.return_air()
	var/pressure = (environment)? environment.return_pressure() : 0
	if(pressure < SOUND_MINIMUM_PRESSURE)
		message_range = 1

	if(pressure < ONE_ATMOSPHERE*0.4) //Thin air, let's italicise the message
		spans |= SPAN_ITALICS
	if(src?.client?.prefs.auto_capitalize_enabled)
		message=auto_capitalize(message)
	send_speech(message, message_range, src, bubble_type, spans, language, message_mode)

	if(succumbed)
		succumb()
		to_chat(src, compose_message(src, language, message, null, spans, message_mode))

	return TRUE

/mob/living/compose_message(atom/movable/speaker, datum/language/message_language, raw_message, radio_freq, list/spans, message_mode, face_name = FALSE, atom/movable/source)
	. = ..()
	if(isliving(speaker))
		var/turf/sourceturf = get_turf(source)
		var/turf/T = get_turf(src)
		if(sourceturf && T && !(sourceturf in get_hear(5, T)))
			. = "<span class='small'>[.]</span>"

/mob/living/Hear(message, atom/movable/speaker, datum/language/message_language, raw_message, radio_freq, list/spans, message_mode, atom/movable/source)
	SEND_SIGNAL(src, COMSIG_MOVABLE_HEAR, args) //parent calls can't overwrite the current proc args.
	if(!client && !audiovisual_redirect)
		return
	var/deaf_message
	var/deaf_type
	if(speaker != src)
		if(!radio_freq) //These checks have to be seperate, else people talking on the radio will make "You can't hear yourself!" appear when hearing people over the radio while deaf.
			deaf_message = "<span class='name'>[speaker]</span> [speaker.verb_say] something but you cannot hear [speaker.ru_na()]."
			deaf_type = 1
	else
		deaf_message = "<span class='notice'>You can't hear yourself!</span>"
		deaf_type = 2 // Since you should be able to hear yourself without looking

	// Create map text prior to modifying message for goonchat
	if (client?.prefs.chat_on_map && stat != UNCONSCIOUS && (client.prefs.see_chat_non_mob || ismob(speaker)) && can_hear())
		create_chat_message(speaker, message_language, raw_message, spans, message_mode)

	// Recompose message for AI hrefs, language incomprehension.
	message = compose_message(speaker, message_language, raw_message, radio_freq, spans, message_mode, FALSE, source)

	show_message(message, MSG_AUDIBLE, deaf_message, deaf_type)
	return message

/mob/living/send_speech(message, message_range = 6, obj/source = src, bubble_type = bubble_icon, list/spans, datum/language/message_language=null, message_mode)
	var/static/list/eavesdropping_modes = list(MODE_WHISPER = TRUE, MODE_WHISPER_CRIT = TRUE)
	var/eavesdrop_range = 0
	if(eavesdropping_modes[message_mode])
		eavesdrop_range = EAVESDROP_EXTRA_RANGE
	var/list/listening = get_hearers_in_view(message_range+eavesdrop_range, source)

	// ТЕШАРИ - улучшенный слух (слышат шёпот на +2 клетки дальше)
	if(eavesdropping_modes[message_mode])
		for(var/mob/living/carbon/human/H in range(message_range + eavesdrop_range + 2, source))
			if(H in listening)
				continue
			if(!H.client)
				continue
			if(H.dna?.species?.id == SPECIES_TESHARI)
				listening += H

	var/list/the_dead = list()
	for(var/_M in GLOB.player_list)
		var/mob/M = _M
		if(M.stat != DEAD) //not dead, not important
			continue
		if(!M.client || !client) //client is so that ghosts don't have to listen to mice
			continue
		if(get_dist(M, source) > 7 || M.z != z) //they're out of range of normal hearing
			if(eavesdropping_modes[message_mode] && !(M.client.prefs && (M.client.prefs.chat_toggles & CHAT_GHOSTWHISPER))) //they're whispering and we have hearing whispers at any range off
				continue
			if(!(M.client.prefs && (M.client.prefs.chat_toggles & CHAT_GHOSTEARS))) //they're talking normally and we have hearing at any range off
				continue
		listening |= M
		the_dead[M] = TRUE

	var/eavesdropping
	var/eavesrendered
	if(eavesdrop_range)
		eavesdropping = stars(message)
		eavesrendered = compose_message(src, message_language, eavesdropping, null, spans, message_mode, FALSE, source)

	var/rendered = compose_message(src, message_language, message, null, spans, message_mode, FALSE, source)
	for(var/_AM in listening)
		var/atom/movable/AM = _AM
		// ПАТЧ ТЕШАРИ - проверяем дистанцию для чёткого слуха
		var/is_teshari_listener = FALSE
		if(ishuman(AM))
			var/mob/living/carbon/human/H = AM
			if(H.dna?.species?.id == SPECIES_TESHARI)
				is_teshari_listener = TRUE

		var/actual_dist = get_dist(source, AM)
		var/should_hear_clearly = (actual_dist <= message_range)

		// Тешари слышат шёпот ЧЁТКО на дистанции до 3 клеток (1 + 2 бонус)
		if(is_teshari_listener && eavesdropping_modes[message_mode])
			if(actual_dist <= (message_range + 2)) // 1 + 2 = 3 клетки чёткого слуха
				should_hear_clearly = TRUE

		if(eavesdrop_range && !should_hear_clearly && !(the_dead[AM]))
			AM.Hear(eavesrendered, src, message_language, eavesdropping, null, spans, message_mode, source)
		else
			AM.Hear(rendered, src, message_language, message, null, spans, message_mode, source)
	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_LIVING_SAY_SPECIAL, src, message)
// ====================================================================
// СТАРЫЙ КОД ДЛЯ СПРАВКИ
// ====================================================================
/*
	for(var/_AM in listening)
		var/atom/movable/AM = _AM
		if(eavesdrop_range && get_dist(source, AM) > message_range && !(the_dead[AM]))
			AM.Hear(eavesrendered, src, message_language, eavesdropping, null, spans, message_mode, source)
		else
			AM.Hear(rendered, src, message_language, message, null, spans, message_mode, source)
*/

	var/is_yell = (say_test(message) == "2")
	if(client && !eavesdrop_range && is_yell)	// Yell hook
		listening |= process_yelling(listening, rendered, src, message_language, message, spans, message_mode, source)

	//speech bubble
	var/list/speech_bubble_recipients = list()
	for(var/mob/M in listening)
		if(M.client && !M.client.prefs.chat_on_map)
			speech_bubble_recipients.Add(M.client)
	var/image/I = image('icons/mob/talk.dmi', src, "[bubble_type][say_test(message)]", FLY_LAYER)
	I.appearance_flags = APPEARANCE_UI_IGNORE_ALPHA
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(flick_overlay), I, speech_bubble_recipients, 30)

	//Listening gets trimmed here if a vocal bark's present. If anyone ever makes this proc return listening, make sure to instead initialize a copy of listening in here to avoid wonkiness
	if(SEND_SIGNAL(src, COMSIG_MOVABLE_QUEUE_BARK, listening, args) || vocal_bark || vocal_bark_id)
		for(var/mob/M in listening)
			if(!M.client)
				continue
			if(!(M.client.prefs.toggles & SOUND_BARK))
				listening -= M
		var/barks = min(round((LAZYLEN(message) / vocal_speed)) + 1, BARK_MAX_BARKS)
		var/total_delay
		vocal_current_bark = world.time
		for(var/i in 1 to barks)
			if(total_delay > BARK_MAX_TIME)
				break
			addtimer(CALLBACK(src, TYPE_PROC_REF(/atom/movable, bark), listening, (message_range * (is_yell ? 4 : 1)), (vocal_volume * (is_yell ? 1.5 : 1)), BARK_DO_VARY(vocal_pitch, vocal_pitch_range), vocal_current_bark), total_delay)
			total_delay += rand(DS2TICKS(vocal_speed / BARK_SPEED_BASELINE), DS2TICKS(vocal_speed / BARK_SPEED_BASELINE) + DS2TICKS((vocal_speed / BARK_SPEED_BASELINE) * (is_yell ? 0.5 : 1))) TICKS


/atom/movable/proc/process_yelling(list/already_heard, rendered, atom/movable/speaker, datum/language/message_language, message, list/spans, message_mode, obj/source)
	if(last_yell > (world.time - 10))
		to_chat(src, "<span class='warning'>Your voice doesn't project as far as you try to yell in such quick succession.")		// yeah no, no spamming an expensive floodfill.
		return
	last_yell = world.time
	var/list/overhearing = list()
	var/list/overhearing_text = list()
	overhearing = yelling_wavefill(src, yell_power)
	if(!overhearing.len)
		overhearing_text = "none"
	else
		for(var/mob/M as anything in overhearing)
			overhearing_text += key_name(M)
		overhearing_text = english_list(overhearing_text)
	//log_say("YELL: [ismob(src)? key_name(src) : src] yelled [message] with overhearing mobs [overhearing_text]")
	// overhearing = get_hearers_in_view(35, src) | get_hearers_in_range(5, src)
	overhearing -= already_heard
	if(!overhearing.len)
		return
	// to_chat(world, "DEBUG: overhearing [english_list(overhearing)]")
	for(var/_AM in overhearing)
		var/atom/movable/AM = _AM
		AM.Hear(rendered, speaker, message_language, message, null, spans, message_mode, source)

	return overhearing

/mob/proc/binarycheck()
	return FALSE

/mob/living/can_speak(message) //For use outside of Say()
	if(can_speak_basic(message) && can_speak_vocal(message))
		return TRUE

/mob/living/proc/can_speak_basic(message, ignore_spam = FALSE) //Check BEFORE handling of xeno and ling channels
	if(client)
		if(client.prefs.muted & MUTE_IC)
			to_chat(src, "<span class='danger'>You cannot speak in IC (muted).</span>")
			return FALSE
		if(!ignore_spam && client.handle_spam_prevention(message,MUTE_IC))
			return FALSE

	return TRUE

/mob/living/proc/can_speak_vocal(message) //Check AFTER handling of xeno and ling channels
	var/obj/item/bodypart/leftarm = get_bodypart(BODY_ZONE_L_ARM)
	var/obj/item/bodypart/rightarm = get_bodypart(BODY_ZONE_R_ARM)
	if(HAS_TRAIT(src, TRAIT_MUTE) && get_selected_language() != /datum/language/signlanguage)
		return FALSE

	if (get_selected_language() == /datum/language/signlanguage)
		var/left_disabled = FALSE
		var/right_disabled = FALSE
		if (istype(leftarm)) // Need to check if the arms exist first before checking if they are disabled or else it will runtime
			if (leftarm.is_disabled())
				left_disabled = TRUE
		else
			left_disabled = TRUE
		if (istype(rightarm))
			if (rightarm.is_disabled())
				right_disabled = TRUE
		else
			right_disabled = TRUE
		if (left_disabled && right_disabled) // We want this to only return false if both arms are either missing or disabled since you could technically sign one-handed.
			return FALSE

	if(is_muzzled())
		return FALSE

	if(!IsVocal())
		return FALSE

	return TRUE

/mob/living/proc/get_key(message)
	var/key = message[1]
	if(key in GLOB.department_radio_prefixes)
		return lowertext(message[1 + length(key)])

/mob/living/proc/get_message_language(message)
	if(message[1] == ",")
		var/key = message[1 + length(message[1])]
		for(var/ld in GLOB.all_languages)
			var/datum/language/LD = ld
			if(initial(LD.key) == key)
				return LD
	return null

/mob/living/proc/treat_message(message)

	if(HAS_TRAIT(src, TRAIT_UNINTELLIGIBLE_SPEECH))
		message = unintelligize(message)

	if(HAS_TRAIT(src, TRAIT_ASIAT))
		message = asiatish(message)

	if(HAS_TRAIT(src, TRAIT_UKRAINE))
		message = ukraine(message)

	if(HAS_TRAIT(src, TRAIT_KARTAVII))
		message = kartavo(message)

	// BLUEMOON EDIT START - теперь синтетики заикаются более с%инт$тич!ески
	if(derpspeech)
		if (isrobotic(src))
			message = machine_slur(message, FALSE, stuttering)
		else
			message = derpspeech(message, stuttering)

	if(stuttering)
		if (isrobotic(src))
			message = machine_slur(message, FALSE, 30)
		else
			message = stutter(message)

	if(slurring)
		if (isrobotic(src))
			var/replace_characters = (slurring > 65)
			message = machine_slur(message, replace_characters, slurring * 1.5)
		else
			message = slur(message,slurring)
	// BLUEMOON EDIT END

	if(cultslurring)
		message = cultslur(message)

	if(clockcultslurring)
		message = CLOCK_CULT_SLUR(message)

	message = capitalize(message)

	return message

/mob/living/proc/radio(message, message_mode, list/spans, language)
	var/obj/item/implant/radio/imp = locate() in implants
	if(imp?.radio.on)
		if(message_mode == MODE_HEADSET)
			imp.radio.talk_into(src, message, , spans, language)
			return ITALICS | REDUCE_RANGE
		if(message_mode == MODE_DEPARTMENT || (message_mode in GLOB.radiochannels))
			if (imp.radio.channels[message_mode])
				imp.radio.talk_into(src, message, message_mode, spans, language)
				return ITALICS | REDUCE_RANGE

	switch(message_mode)
		if(MODE_WHISPER)
			return ITALICS
		if(MODE_R_HAND)
			for(var/obj/item/r_hand in get_held_items_for_side("r", all = TRUE))
				if (r_hand)
					return r_hand.talk_into(src, message, , spans, language)
				return ITALICS | REDUCE_RANGE
		if(MODE_L_HAND)
			for(var/obj/item/l_hand in get_held_items_for_side("l", all = TRUE))
				if (l_hand)
					return l_hand.talk_into(src, message, , spans, language)
				return ITALICS | REDUCE_RANGE

		if(MODE_INTERCOM)
			for (var/obj/item/radio/intercom/I in view(1, null))
				I.talk_into(src, message, , spans, language)
			return ITALICS | REDUCE_RANGE

		if(MODE_BINARY)
			return ITALICS | REDUCE_RANGE //Does not return FALSE since this is only reached by humans, not borgs or AIs.

	return FALSE

/mob/living/say_mod(input, message_mode)
	. = ..()
	if(message_mode == MODE_WHISPER_CRIT)
		. = "[verb_whisper] in [ru_ego()] last breath"
	else if(message_mode != MODE_CUSTOM_SAY)
		if(message_mode == MODE_WHISPER)
			. = verb_whisper
		else if(stuttering)
			. = "stammers"
		else if(derpspeech)
			. = "gibbers"
		// Skyrat edits
		else if(message_mode == MODE_SING)
			. = verb_sing
		// End of Skyrat edits
/mob/living/whisper(message, bubble_type, list/spans = list(), sanitize = TRUE, datum/language/language = null, ignore_spam = FALSE, forced = null)
	say("#[message]", bubble_type, spans, sanitize, language, ignore_spam, forced)
