/mob/living/silicon/ai/say(message, bubble_type,var/list/spans = list(), sanitize = TRUE, datum/language/language = null, ignore_spam = FALSE, forced = null)
	if(parent && istype(parent) && parent.stat != DEAD) //If there is a defined "parent" AI, it is actually an AI, and it is alive, anything the AI tries to say is said by the parent instead.
		parent.say(message, language)
		return
	..(message)

/mob/living/silicon/ai/compose_track_href(atom/movable/speaker, namepart)
	var/mob/M = speaker.GetSource()
	if(M)
		return "<a href='?src=[REF(src)];track=[html_encode(namepart)]'>"
	return ""

/mob/living/silicon/ai/compose_job(atom/movable/speaker, message_langs, raw_message, radio_freq)
	// BLUEMOON EDIT START
	if(radio_freq)
		return "[speaker.GetSource() ? "</a>" : ""]"
	return "[speaker.GetSource() ? "</a>" : ""]"
	// BLUEMOON EDIT END

/mob/living/silicon/ai/IsVocal()
	return !CONFIG_GET(flag/silent_ai)

/mob/living/silicon/ai/radio(message, message_mode, list/spans, language)
	if(incapacitated())
		return FALSE
	if(!radio_enabled) //AI cannot speak if radio is disabled (via intellicard) or depowered.
		to_chat(src, "<span class='danger'>Your radio transmitter is offline!</span>")
		return FALSE
	..()

/mob/living/silicon/ai/get_message_mode(message)
	var/static/regex/holopad_finder = regex(@"[:.#][hH]")
	if(holopad_finder.Find(message, 1, 1))
		return MODE_HOLOPAD
	else
		return ..()

//For holopads only. Usable by AI.
/mob/living/silicon/ai/proc/holopad_talk(message, language)
	message = trim(message)

	if (!message)
		return

	var/obj/machinery/holopad/T = current
	if(istype(T) && T.masters[src])//If there is a hologram and its master is the user.
		var/turf/padturf = get_turf(T)
		var/padloc
		if(padturf)
			padloc = AREACOORD(padturf)
		else
			padloc = "(UNKNOWN)"
		src.log_talk(message, LOG_SAY, tag="HOLOPAD in [padloc]")
		send_speech(message, 7, T, "robot", message_language = language)
		to_chat(src, "<i><span class='game say'>Holopad transmitted, <span class='name'>[real_name]</span> <span class='message robot'>\"[message]\"</span></span></i>")
	else
		to_chat(src, "No holopad connected.")


//For status displays only. Usable by AI.
/mob/living/silicon/ai/proc/statusdisplay_talk(message, language)
	message = trim(message)

	if (!message)
		return

	var/obj/machinery/status_display/T = controlled_display
	if(T)
		var/turf/padturf = get_turf(T)
		var/padloc
		if(padturf)
			padloc = AREACOORD(padturf)
		else
			padloc = "(UNKNOWN)"
		src.log_talk(message, LOG_SAY, tag="STATUS DISPLAY in [padloc]")
		send_speech(message, 7, T, "robot", message_language = language)
		to_chat(src, "<i><span class='game say'>Status Display message transmitted, <span class='name'>[real_name]</span> <span class='message robot'>\"[message]\"</span></span></i>")
	else
		to_chat(src, "No status display connected.")



// Make sure that the code compiles with AI_VOX undefined
#ifdef AI_VOX
#define VOX_DELAY 1 MINUTES
/// Сколько файлы слов едут слушателям до первого звука объявления.
#define VOX_PRELOAD_LEAD (1 SECONDS)
/mob/living/silicon/ai/proc/announcement(voxType = "Female", message)
	var/static/announcing_vox = 0 // Stores the time of the last announcement
	var/next_vox = training_origin ? training_vox_at : announcing_vox
	if(next_vox > world.time)
		to_chat(src, span_notice("Please wait [DisplayTimeText(next_vox - world.time)]."))
		return

	last_announcement = message

	if(!message || !GLOB.vox_types[voxType])
		return

	if(incapacitated())
		return

	if(control_disabled)
		to_chat(src, span_warning("Wireless interface disabled, unable to interact with announcement PA."))
		return

	var/list/words = splittext(trim(message), " ")
	var/list/incorrect_words = list()

	if(words.len > 30)
		words.len = 30

	for(var/word in words)
		word = lowertext(trim(word))
		if(!word)
			words -= word
			continue
		if(!GLOB.vox_types[voxType][word])
			incorrect_words += word

	if(incorrect_words.len)
		to_chat(src, span_notice("These words are not available on the announcement system: [english_list(incorrect_words)]."))
		return

	if(training_origin)
		training_vox_at = world.time + VOX_DELAY
	else
		announcing_vox = world.time + VOX_DELAY

	log_game("[key_name(src)] made a vocal announcement with the following message: [message].")

	return play_vox_announcement(words, src.z, voxType)

/// Файлы слов заранее уходят тем, кто услышит объявление, звук - через VOX_PRELOAD_LEAD: слово, которого нет
/// в кэше клиента, качается в момент проигрыша, и без предзагрузки слова наползают друг на друга. Возвращает id таймера.
/proc/play_vox_announcement(list/words, z_level, voxType = "Female")
	var/list/files = list()
	var/total_bytes = 0
	for(var/word in words)
		var/file = LAZYACCESSASSOC(GLOB.vox_types, voxType, lowertext(word))
		if(file && !(file in files))
			files += file
			total_bytes += vox_file_bytes(file)
	var/list/listeners = vox_listeners(z_level)
	for(var/mob/listener as anything in listeners)
		for(var/file in files)
			listener.client.Export("##action=load_rsc", file)
	note_nondatum_alloc(NONDATUM_LEDGER_RSC_BYTES, total_bytes * length(listeners))
	return addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(play_vox_words), words.Copy(), z_level, voxType), VOX_PRELOAD_LEAD, TIMER_STOPPABLE)

/proc/play_vox_words(list/words, z_level, voxType)
	for(var/word in words)
		play_vox_word(word, z_level, null, voxType)

/// Мобы с клиентом на z_level, которые сейчас услышат VOX.
/proc/vox_listeners(z_level)
	. = list()
	for(var/mob/player as anything in GLOB.player_list)
		if(!player.client || !(player.client.prefs.toggles & SOUND_ANNOUNCEMENTS) || !player.can_hear())
			continue
		var/turf/player_turf = get_turf(player)
		if(player_turf?.z == z_level)
			. += player

/proc/play_vox_word(word, z_level, mob/only_listener, voxType = "Female")

	word = lowertext(word)

	var/sound_file = LAZYACCESSASSOC(GLOB.vox_types, voxType, word)
	if(sound_file)
		var/sound/voice = sound(sound_file, wait = 1, channel = CHANNEL_VOX)
		voice.status = SOUND_STREAM

		if(!only_listener)
			for(var/mob/listener as anything in vox_listeners(z_level))
				voice.volume = listener.client.prefs.get_sound_volume("announcements")
				SEND_SOUND(listener, voice)
		else
			var/pref_vol = only_listener.client?.prefs?.get_sound_volume("announcements")
			voice.volume = pref_vol
			SEND_SOUND(only_listener, voice)
		return TRUE
	return FALSE

#undef VOX_DELAY
#undef VOX_PRELOAD_LEAD
#endif
