#define HK_PREFIX_BARK_VOLUME 45
#define HK_PREFIX_BARK_EXTRA_RANGE 1
#define HK_PREFIX_BARK_COOLDOWN (3 SECONDS)

/datum/species/ipc/hk
	COOLDOWN_DECLARE(prefix_bark_cooldown)
	/// До этого world.time звучит голосовая строка: барк префикса её не перебивает.
	var/voice_busy_until = 0

/// Голосовая строка дроида HK из уст speaker; private - слышит только он сам. TRUE, если строка прозвучала.
/proc/hk_voice_line(mob/living/speaker, voice, private = FALSE, volume = HK47_VOICE_VOLUME, extra_range = HK47_VOICE_EXTRA_RANGE)
	if(!voice || QDELETED(speaker))
		return FALSE
	var/turf/source_turf = get_turf(speaker)
	if(!source_turf)
		return FALSE
	if(private)
		speaker.playsound_local(source_turf, voice, volume, FALSE)
	else
		playsound(speaker, voice, volume, FALSE, extra_range)
	var/mob/living/carbon/human/chassis_owner = speaker
	var/datum/species/ipc/hk/chassis = istype(chassis_owner) ? chassis_owner.dna?.species : null
	if(istype(chassis))
		chassis.voice_busy_until = max(chassis.voice_busy_until, world.time + hk_voice_line_length(voice))
	return TRUE

/proc/hk_voice_line_length(voice)
	var/length = rustg_sound_length(voice)
	return length > 0 ? length : HK_VOICE_LINE_FALLBACK_LENGTH

/datum/species/ipc/hk/proc/on_send_speech(mob/living/carbon/human/source, message, message_range, atom/movable/speech_source, bubble_type, list/spans, datum/language/message_language, message_mode)
	SIGNAL_HANDLER
	hk_prefix_bark(source, message, message_mode, message_language)

/// Звук префикса, с которого начинается реплика, или null.
/datum/species/ipc/hk/proc/hk_prefix_bark_sound(message)
	var/static/list/prefix_sounds = list(
		HK_PREFIX_STATEMENT = 'modular_bluemoon/sound/hk_droids/hk47_prefix_statement.ogg',
		HK_PREFIX_QUERY = 'modular_bluemoon/sound/hk_droids/hk47_prefix_query.ogg',
		HK_PREFIX_EXCLAMATION = 'modular_bluemoon/sound/hk_droids/hk47_prefix_exclamation.ogg',
		HK_PREFIX_ANALYSIS = 'modular_bluemoon/sound/hk_droids/hk47_prefix_analysis.ogg',
	)
	for(var/prefix in prefix_sounds)
		if(findtext(message, prefix) == 1)
			return prefix_sounds[prefix]

/// Озвучивает префикс реплики у говорящего и возвращает сыгранный звук; шёпот, жесты, повтор за кулдаун и реплика поверх голосовой строки молчат.
/datum/species/ipc/hk/proc/hk_prefix_bark(mob/living/speaker, message, message_mode, datum/language/message_language)
	if(message_mode == MODE_WHISPER || message_mode == MODE_WHISPER_CRIT)
		return
	if(message_language && initial(message_language.visual_language))
		return
	if(!COOLDOWN_FINISHED(src, prefix_bark_cooldown) || world.time < voice_busy_until)
		return
	var/bark = hk_prefix_bark_sound(message)
	if(!bark)
		return
	COOLDOWN_START(src, prefix_bark_cooldown, HK_PREFIX_BARK_COOLDOWN)
	playsound(speaker, bark, HK_PREFIX_BARK_VOLUME, FALSE, HK_PREFIX_BARK_EXTRA_RANGE)
	return bark

#undef HK_PREFIX_BARK_VOLUME
#undef HK_PREFIX_BARK_EXTRA_RANGE
#undef HK_PREFIX_BARK_COOLDOWN
