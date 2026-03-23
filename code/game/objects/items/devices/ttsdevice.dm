/obj/item/ttsdevice
	name = "TTS device"
	desc = "Небольшое устройство с подключенной клавиатурой. Все, что вводится с клавиатуры, воспроизводится через динамик."
	icon = 'icons/obj/device.dmi'
	icon_state = "gangtool-purple"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL
	obj_flags = UNIQUE_RENAME
	vocal_bark_id = "synth" // BLUEMOON ADD
	vocal_pitch = 0.6 // BLUEMOON ADD
	vocal_volume = 40 // BLUEMOON ADD
	var/bark_copy = TRUE // BLUEMOON ADD

// BLUEMOON ADD START
/obj/item/ttsdevice/examine(mob/user)
	. = ..()
	. += span_notice("Ctrl-click позволяет издать звуковой сигнал.")
	. += span_notice("Ctrl-shift-click для переименования.")
	. += span_notice("Alt-click для <b>[bark_copy ? "Выключения" : "Включения"]</b> копирования голоса.")
// BLUEMOON ADD END

/obj/item/ttsdevice/attack_self(mob/user)
	user.balloon_alert_to_viewers("печатает...", "начинает печатать...")
	playsound(src, 'sound/items/tts/started_type.ogg', 50, TRUE)
	var/str = input(user, "", "Say Text") as text|null //tgui_input_text(user, "What would you like the device to say?", "Say Text", "", MAX_MESSAGE_LEN, encode = FALSE)
	if(QDELETED(src) || !user.canUseTopic(src))
		return
	if(!str)
		user.balloon_alert_to_viewers("прекращает печатать", "прекратил печатать")
		playsound(src, 'sound/items/tts/stopped_type.ogg', 50, TRUE)
		return
	// BLUEMOON ADD START
	if((!bark_copy && vocal_bark) || vocal_bark != user.vocal_bark) // Если мы выключили, но еще есть звук или если звук не сходится с владельцем
		var/static/list/bark_fields = list("vocal_bark_id", "vocal_pitch", "vocal_pitch_range", "vocal_speed", "vocal_volume")

		for(var/F in bark_fields)
			src.vars[F] = initial(src.vars[F])   // сброс

		vocal_bark = null

		if(bark_copy)
			for(var/F in bark_fields)
				if(user.vars[F])
					src.vars[F] = user.vars[F]

			if(user.vocal_bark)
				vocal_bark = user.vocal_bark
	// BLUEMOON ADD END
	src.say(str)
	str = null

/obj/item/ttsdevice/CtrlClick(mob/living/user)
	var/noisechoice = tgui_input_list(user, "Какой звук вы хотите воспроизвести?", "Робо-Звуки", list("BEEP","BZZZ","PING"))
	if(!noisechoice)
		return
	user.balloon_alert_to_viewers(noisechoice)
	switch(noisechoice)
		if("BEEP")
			playsound(user, 'sound/machines/twobeep.ogg', 50, 1, -1)
		if("BZZZ")
			playsound(user, 'sound/machines/buzz-sigh.ogg', 50, 1, -1)
		if("PING")
			playsound(user, 'sound/machines/ping.ogg', 50, 1, -1)

/obj/item/ttsdevice/CtrlShiftClick(mob/living/user)
	var/new_name = reject_bad_name(tgui_input_text(user, "Назовите свое Text-to-Speech устройство.", "Задать имя TTS устройству", user.real_name, MAX_NAME_LEN))
	if(new_name)
		name = "[new_name]'s [initial(name)]"
	else
		name = initial(name)

// BLUEMOON ADD START
/obj/item/ttsdevice/AltClick(mob/user)
	. = ..()
	if(user.canUseTopic(src, BE_CLOSE))
		bark_copy = !bark_copy
		balloon_alert(user, "Копирование голоса: [bark_copy ? "Включено" : "Выключено"]")
// BLUEMOON ADD END
