// ═══════════════════════════════════════════════════════════════════════
//  Поддержка эмоутов через звёздочку от льва
// ═══════════════════════════════════════════════════════════════════════
//
// ПРОБЛЕМА: Стандартная система BlueMoon использует звёздочку для custom say,
//           но не разделяет эмоут и речь, что приводит к дублированию акцентов.
//
// РЕШЕНИЕ:  Используем существующую систему say_mod(), но с правильной
//           поддержкой кириллицы через findtext_char() вместо findtext().
//
// ФОРМАТ:   "улыбается* привет" → "Персонаж улыбается, "Привет""
//           ";кивает* понял" → "[Common] Персонаж кивает, "Понял""
//
// ═══════════════════════════════════════════════════════════════════════
//  АНЕКДОТ ДНЯ:
//  Заходит программист в бар. Заказывает 1 пиво. Заказывает 0 пива.
//  Заказывает 999999999 пива. Заказывает -1 пиво. Заказывает ящерицу.
//  Бармен говорит: "Всё работает отлично!"
//  Заходит обычный посетитель и спрашивает где туалет.
//  Бар загорается.
// ═══════════════════════════════════════════════════════════════════════

//Speech verbs.
// the _keybind verbs uses "as text" versus "as text|null" to force a popup when pressed by a keybind.
/mob/verb/say_typing_indicator()
	set name = "say_indicator"
	set hidden = TRUE
	set category = "Say"
	client?.last_activity = world.time
	display_typing_indicator(isSay = TRUE)
	var/message = input(usr, "", "say") as text|null
	// If they don't type anything just drop the message.
	clear_typing_indicator()		// clear it immediately!
	if(!length(message))
		return
	return say_verb(message)

/mob/verb/say_verb(message as text)
	set name = "say"
	set category = "Say"
	if(!length(message))
		return
	if(GLOB.say_disabled)	//This is here to try to identify lag problems
		to_chat(usr, "<span class='danger'>Speech is currently admin-disabled.</span>")
		return
	clear_typing_indicator()		// clear it immediately!

	client?.last_activity = world.time

	say(message)

/mob/verb/me_typing_indicator()
	set name = "me_indicator"
	set hidden = TRUE
	set category = "Say"
	client?.last_activity = world.time
	display_typing_indicator(isMe = TRUE)
	var/message = input(usr, "", "me") as message|null
	// If they don't type anything just drop the message.
	clear_typing_indicator()		// clear it immediately!
	if(!length(message))
		return
	return me_verb(message)

/mob/verb/me_verb(message as message)
	set name = "me"
	set category = "Say"
	if(!length(message))
		return
	if(GLOB.say_disabled)	//This is here to try to identify lag problems
		to_chat(usr, "<span class='danger'>Speech is currently admin-disabled.</span>")
		return

	if(length(message) > MAX_MESSAGE_LEN)
		to_chat(usr, message)
		to_chat(usr, "<span class='danger'>^^^----- The preceeding message has been DISCARDED for being over the maximum length of [MAX_MESSAGE_LEN]. It has NOT been sent! -----^^^</span>")
		return

	message = trim(html_encode(message), MAX_MESSAGE_LEN)
	clear_typing_indicator()		// clear it immediately!

	client?.last_activity = world.time

	usr.emote("me",1,message,TRUE)

// ═══════════════════════════════════════════════════════════════════════
//  say_mod() - определяет глагол для речи
// ═══════════════════════════════════════════════════════════════════════
// Эта функция вызывается системой чтобы определить КАК говорит персонаж.
// ВАЖНОЕ ИСПРАВЛЕНИЕ: Используем findtext_char() вместо findtext() для
// правильной работы с кириллицей (UTF-8), где 1 символ = 2 байта.

/mob/say_mod(input, message_mode)
	if(message_mode == MODE_WHISPER_CRIT)
		return ..()
	
	// Обработка восклицательного знака для custom say
	if((input[1] == "!") && (length_char(input) > 1))
		message_mode = MODE_CUSTOM_SAY
		return copytext_char(input, 2)
	
	// ИСПРАВЛЕНИЕ: findtext_char() вместо findtext() для кириллицы
	// findtext() возвращает позицию в БАЙТАХ (неправильно для UTF-8)
	// findtext_char() возвращает позицию в СИМВОЛАХ (правильно!)
	var/customsayverb = findtext_char(input, "*")
	if(customsayverb)
		message_mode = MODE_CUSTOM_SAY
		// Возвращаем только эмоут (текст до звёздочки)
		return lowertext(copytext_char(input, 1, customsayverb))
	
	return ..()

// ═══════════════════════════════════════════════════════════════════════
//  uncostumize_say() - убирает кастомный глагол из сообщения
// ═══════════════════════════════════════════════════════════════════════
// ИСПРАВЛЕНИЕ: Также используем findtext_char() для кириллицы

/proc/uncostumize_say(input, message_mode)
	. = input
	if(message_mode == MODE_CUSTOM_SAY)
		// ИСПРАВЛЕНИЕ: findtext_char() вместо findtext()
		var/customsayverb = findtext_char(input, "*")
		return lowertext(copytext_char(input, 1, customsayverb))

/*
//This proc is no longer used for a long time.
/mob/proc/whisper_keybind()
	client?.last_activity = world.time
	var/message = input(src, "", "whisper") as text|null
	if(!length(message))
		return
	return whisper_verb(message)
*/

/mob/verb/whisper_verb(message as text)
	set name = "Whisper"
	set category = "Say"
	if(!length(message))
		return
	if(GLOB.say_disabled)	//This is here to try to identify lag problems
		to_chat(usr, "<span class='danger'>Speech is currently admin-disabled.</span>")
		return
	whisper(message)

/mob/proc/whisper(message, datum/language/language=null)
	client?.last_activity = world.time
	say(message, language) //only living mobs actually whisper, everything else just talks

/mob/proc/say_dead(var/message)
	var/name = real_name
	var/alt_name = ""

	if(GLOB.say_disabled)	//This is here to try to identify lag problems
		to_chat(usr, "<span class='danger'>Speech is currently admin-disabled.</span>")
		return

	var/jb = jobban_isbanned(src, "OOC")
	if(QDELETED(src))
		return

	if(jb)
		to_chat(src, "<span class='danger'>You have been banned from deadchat.</span>")
		return



	if (src.client)
		if(src.client.prefs.muted & MUTE_DEADCHAT)
			to_chat(src, "<span class='danger'>You cannot talk in deadchat (muted).</span>")
			return

		if(src.client.handle_spam_prevention(message,MUTE_DEADCHAT))
			return

	var/mob/dead/observer/O = src
	if(isobserver(src) && O.deadchat_name)
		name = "[O.deadchat_name]"
	else
		if(mind && mind.name)
			name = "[mind.name]"
		else
			name = real_name
		if(name != real_name)
			alt_name = " (died as [real_name])"

	var/spanned = say_quote(say_emphasis(message))
	message = emoji_parse(message)
	var/source = "<span class='game'><span class='prefix'>DEAD:</span> <span class='name'>[name]</span>[alt_name]"
	var/rendered = " <span class='message'>[emoji_parse(spanned)]</span></span>"
	log_talk(message, LOG_SAY, tag="DEAD")
	client?.last_activity = world.time
	var/displayed_key = key
	if(client?.holder?.fakekey)
		displayed_key = null
	deadchat_broadcast(rendered, source, follow_target = src, speaker_key = displayed_key)

/mob/proc/check_emote(message)
	if(message[1] == "*")
		emote(copytext(message, length(message[1]) + 1), intentional = TRUE)
		return TRUE

/mob/proc/hivecheck()
	return FALSE

/mob/proc/lingcheck()
	return LINGHIVE_NONE

/mob/proc/get_message_mode(message)
	var/key = message[1]
	if(key == "#")
		return MODE_WHISPER
	else if(key == ";")
		return MODE_HEADSET
	// Skyrat edit
	else if(key == "%")
		return MODE_SING
	// End of Skyrat edit
	else if((length(message) > (length(key) + 1)) && (key in GLOB.department_radio_prefixes))
		var/key_symbol = lowertext(message[length(key) + 1])
		return GLOB.department_radio_keys[key_symbol]

// ═══════════════════════════════════════════════════════════════════════
//  ТЕХНИЧЕСКАЯ СПРАВКА
// ═══════════════════════════════════════════════════════════════════════
//
//  findtext() vs findtext_char():
//  - findtext("привет*", "*") вернёт ~14 (позиция в БАЙТАХ)
//  - findtext_char("привет*", "*") вернёт 7 (позиция в СИМВОЛАХ)
//  
//  Для английского текста разницы нет (1 символ = 1 байт)
//  Для русского текста критично использовать findtext_char()!
//
// ═══════════════════════════════════════════════════════════════════════
//  
//  КОНЕЦ КОДА. ИДИ РПшить, ЗВЕРЁК!
//
// ═══════════════════════════════════════════════════════════════════════
