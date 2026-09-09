/obj/item/radio/headset
	// Используем список для рандома
	var/radiosound = list(
		'modular_bluemoon/sound/radio/radio_broadband.ogg',
		'modular_bluemoon/sound/radio/radio_shortband.ogg',
		'modular_bluemoon/sound/radio/radio_other.ogg'
	)

/obj/item/radio/headset/syndicate
	radiosound = 'modular_sand/sound/radio/syndie.ogg'

/obj/item/radio/headset/headset_sec
	radiosound = 'modular_sand/sound/radio/security.ogg'

/obj/item/radio/headset/talk_into(mob/living/M, message, channel, list/spans, datum/language/language, list/message_mods, direct = TRUE)
	if(!listening)
		return ITALICS | REDUCE_RANGE

	// Щелчок гарнитуры звучал раньше, чем ..() успевал отбить передачу на визуальном языке:
	// текст никуда не уходил, а окружающие слышали, что человек "жмёт тангенту" - это и есть
	// жалоба "наушник вибрирует". Глухие щелчка не слышат, отсюда же "если ты оглох, то не слышишь".
	if(on && M && message && !wires.is_cut(WIRE_TX) && M.IsVocal() && !(language && initial(language.visual_language)))
		var/sound_to_play = islist(radiosound) ? pick(radiosound) : radiosound
		if(sound_to_play)
			playsound(M, sound_to_play, rand(20, 30), FALSE, FALSE, TRUE)

	return ..()
