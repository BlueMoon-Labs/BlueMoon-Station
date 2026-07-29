// =============================================================================
// NEGOTIATIONS RADIO
// Radio system for dialogue interactions with players
// =============================================================================

/obj/machinery/negotiations_radio
	name = "negotiations radio"
	desc = "An old radio."
	icon = 'modular_bluemoon/icons/obj/urbanism/urbanism.dmi'
	icon_state = "radiohecu"
	anchored = TRUE
	density = TRUE
	var/list/negotiation_sounds = list(
		'modular_bluemoon/sound/creatures/mesa/hecuchatter/chatter1.ogg',
		'modular_bluemoon/sound/creatures/mesa/hecuchatter/chatter2.ogg',
		'modular_bluemoon/sound/creatures/mesa/hecuchatter/chatter3.ogg',
		'modular_bluemoon/sound/creatures/mesa/hecuchatter/chatter4.ogg',
		'modular_bluemoon/sound/creatures/mesa/hecuchatter/chatter6.ogg',
		'modular_bluemoon/sound/creatures/mesa/hecuchatter/chatter7.ogg',
		'modular_bluemoon/sound/creatures/mesa/hecuchatter/chatter8.ogg',
		'modular_bluemoon/sound/creatures/mesa/hecuchatter/chatter9.ogg'
	)
	var/next_play_time = 0
	var/detection_range = 7
	var/next_detection_time = 0
	var/detection_cooldown = 30 SECONDS
	var/dialogue_active = FALSE
	var/dialogue_step = 0
	var/current_interactor = null
	var/blastdoor_id = null
	var/next_interaction_time = 0
	var/dialogue_completed = FALSE
	var/list/dialogue_lines = list(
		"НАКОНЕЦ-ТО! Я устал ждать помощи.",
		"Если не будете брыкаться, помогу. Проблема следующая:",
		"Я не могу добраться до комнаты управления из-за туррелей и ставней...",
		"..Но хорошая новость",
		"Доступ к шлюзам перед вами у меня есть. Но вот к проходу дальше, увы, туррели расстреляют",
		"Но если вы попадете в основную комнату управления и отключите туррели - я открою ставни и отключу их",
		"...И делайте это скорее, у меня тут... Скажем так, образовалась пробелма ввиде моего коллеги"
	)
	var/list/alert_phrases = list(
		"ЭЙ!? ЕСТЬ ТУТ КТО?",
		"Я ВАС ЧЕРЕЗ КАМЕРУ ВИЖУ, ОТВЕТЬТЕ!",
		"КТО-ТО ЕСТЬ? ЭТО ВЫ?",
		"ОТВЕЧАЙТЕ! Я ЗНАЮ ЧТО ВЫ ТАМ!",
		"НЕ ПРЯЧЬТЕСЬ, Я ВАС ВИЖУ!"
	)

/obj/machinery/negotiations_radio/Initialize()
	. = ..()
	next_detection_time = world.time + detection_cooldown
	next_interaction_time = 0
	START_PROCESSING(SSobj, src)

/obj/machinery/negotiations_radio/process()
	if(dialogue_active || dialogue_completed)
		return

	if(world.time >= next_detection_time)
		detect_players()

	if(world.time >= next_play_time && !dialogue_active)
		icon_state = "radiohecu_talking"
		var/sound_to_play = pick(negotiation_sounds)
		playsound(src, sound_to_play, 70, FALSE, 7, 3)
		addtimer(CALLBACK(src, .proc/reset_icon), 2 SECONDS)
		next_play_time = world.time + rand(10 SECONDS, 25 SECONDS)

/obj/machinery/negotiations_radio/proc/detect_players()
	if(!src)
		return

	if(world.time < next_detection_time)
		return

	var/turf/T = get_turf(src)
	if(!T)
		return

	for(var/mob/living/M in range(detection_range, T))
		if(!M)
			continue
		if(iscarbon(M) || ishuman(M))
			play_alert_phrase()
			next_detection_time = world.time + detection_cooldown
			return

/obj/machinery/negotiations_radio/proc/play_alert_phrase()
	if(!src)
		return

	icon_state = "radiohecu_talking"
	var/phrase = pick(alert_phrases)
	say(phrase)
	playsound(src, 'sound/machines/chime.ogg', 70, FALSE, 7, 3)
	addtimer(CALLBACK(src, .proc/reset_icon), 3 SECONDS)

/obj/machinery/negotiations_radio/proc/reset_icon()
	icon_state = initial(icon_state)

/obj/machinery/negotiations_radio/attack_hand(mob/user)
	if(!user || !src)
		return

	if(dialogue_completed)
		to_chat(user, span_warning("Радио больше не отвечает."))
		return

	if(world.time < next_interaction_time)
		to_chat(user, span_warning("Подождите немного перед следующим взаимодействием."))
		return

	if(dialogue_active)
		if(current_interactor == user)
			if(dialogue_step == dialogue_lines.len)
				confirm_action(user)
			else
				advance_dialogue(user)
		else
			to_chat(user, span_warning("Радио уже занято другим разговором!"))
		return

	start_dialogue(user)

/obj/machinery/negotiations_radio/proc/start_dialogue(mob/user)
	if(!user || !src)
		return

	dialogue_active = TRUE
	dialogue_step = 0
	current_interactor = user
	next_interaction_time = world.time + 1 SECONDS
	to_chat(user, span_notice("Вы нажимаете на кнопку радио..."))
	advance_dialogue(user)

/obj/machinery/negotiations_radio/proc/advance_dialogue(mob/user)
	if(!user || !src)
		return

	if(dialogue_step < dialogue_lines.len)
		dialogue_step++
		next_interaction_time = world.time + 2 SECONDS
		var/line = dialogue_lines[dialogue_step]
		icon_state = "radiohecu_talking"
		say(line)
		playsound(src, 'sound/machines/chime.ogg', 70, FALSE, 7, 3)
		addtimer(CALLBACK(src, .proc/reset_icon), 3 SECONDS)

		if(dialogue_step == dialogue_lines.len)
			addtimer(CALLBACK(src, .proc/show_interaction_prompt, user), 4 SECONDS)
	else
		end_dialogue()

/obj/machinery/negotiations_radio/proc/show_interaction_prompt(mob/user)
	if(!user || !src)
		return

	user.visible_message(span_notice("[user] готов нажать на радио."), span_notice("Вы готовы нажать на радио."))
	to_chat(user, span_boldnotice("Нажмите на радио чтобы подтвердить действие."))

/obj/machinery/negotiations_radio/proc/end_dialogue()
	if(!src)
		return

	dialogue_active = FALSE
	dialogue_step = 0
	current_interactor = null

/obj/machinery/negotiations_radio/proc/confirm_action(mob/user)
	if(!user || !src)
		return

	if(!dialogue_active || current_interactor != user)
		return

	next_interaction_time = world.time + 2 SECONDS
	say("Шлюзы открыл! Деактивируете туррели - возвращаетесь к открывшемуся проходу и продолжаете путь")
	icon_state = "radiohecu_talking"
	playsound(src, 'sound/machines/chime.ogg', 70, FALSE, 7, 3)
	addtimer(CALLBACK(src, .proc/reset_icon), 3 SECONDS)

	open_blastdoors()
	dialogue_completed = TRUE
	end_dialogue()

/obj/machinery/negotiations_radio/proc/open_blastdoors()
	if(!src || !blastdoor_id)
		return

	var/doors_opened = 0

	for(var/obj/machinery/door/poddoor/D in GLOB.machines)
		if(D && D.id == blastdoor_id)
			D.open()
			doors_opened++

	for(var/obj/machinery/door/window/brigdoor/W in GLOB.machines)
		if(W && W.id == blastdoor_id)
			W.open()
			doors_opened++

	for(var/obj/machinery/door/airlock/A in GLOB.airlocks)
		if(A && A.id_tag == blastdoor_id)
			A.open()
			doors_opened++

	if(doors_opened > 0)
		visible_message(span_notice("Шлюзы с ID [blastdoor_id] открылись!"))
	else
		visible_message(span_warning("Не удалось найти шлюзы с ID [blastdoor_id]!"))

/obj/machinery/negotiations_radio/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

// =============================================================================
// NEGOTIATIONS RADIO WITH DOOR CONTROL
// Opens blastdoors after dialogue completion
// =============================================================================

/obj/machinery/negotiations_radio/door_control
	name = "door control radio"
	desc = "A radio connected to door control systems."
	blastdoor_id = "negotiations_door_1"

// =============================================================================
// BOMBARDMENT RADIO
// Radio for calling in airstrikes
// =============================================================================

/obj/machinery/negotiations_radio/bombardment
	name = "tactical radio"
	desc = "A military radio for calling in air support."
	icon_state = "radiohecu"
	var/console_enabled = FALSE
	var/obj/machinery/computer/camera_advanced/bombardment/linked_console = null
	var/list/bombardment_alert_phrases = list(
		"Чарли, приказ НЕМЕДЛЕННО выйти на связь",
		"Приём, Есть кто на связи?",
		"ЭЙ. Или ВЫ отвечаете или джет УЛЕТАЕТ обратно на базу"
	)
	var/list/bombardment_dialogue_lines = list(
		"Приём. Говорит Пеликан-1. Запрашиваю координаты для тактического удара",
		"Мы покидаем воздушное пространство черной мезы на дозаправку.",
		"...Сворачивайте удочки тоже, ситуация вышла из под контроля",
		"...Если вам всё ещё нужна помощь",
		"Я могу подсобить вам 500 килограмовым подарком для инопланетных ублюдков",
		"...Отметьте по очереди цели для последующей бомбардировки",
		"Имейте ввиду - топливо у меня НЕ бесконечное. Сея мероприятие займет время",
		"...Да спасёт нас демократия"
	)
	var/bombardment_active = FALSE

/obj/machinery/negotiations_radio/bombardment/Initialize()
	. = ..()
	dialogue_lines = bombardment_dialogue_lines
	alert_phrases = bombardment_alert_phrases

	// Auto-link to nearby console if not already linked
	if(!linked_console)
		for(var/obj/machinery/computer/camera_advanced/bombardment/console in range(10, src))
			if(!console.linked_radio)
				linked_console = console
				console.linked_radio = src
				break

/obj/machinery/negotiations_radio/bombardment/proc/enable_console()
	if(!src)
		return

	console_enabled = TRUE
	if(linked_console)
		linked_console.enabled = TRUE
		linked_console.linked_radio = src
		visible_message(span_notice("Консоль бомбардировки активирована!"))

/obj/machinery/negotiations_radio/bombardment/proc/trigger_bombardment(turf/target_turf)
	if(!src || !target_turf)
		return

	bombardment_active = TRUE

	say("Вижу цель. ОТОЙДИТЕ ОТ ВЗРЫВА!")
	icon_state = "radiohecu_talking"
	playsound(src, 'sound/machines/chime.ogg', 70, FALSE, 7, 3)
	addtimer(CALLBACK(src, .proc/reset_icon), 3 SECONDS)

	addtimer(CALLBACK(src, .proc/say_bombardment_start), 3 SECONDS)

	addtimer(CALLBACK(src, .proc/drop_bombs, target_turf), 6 SECONDS)

/obj/machinery/negotiations_radio/bombardment/proc/say_bombardment_start()
	if(!src)
		return

	say("Прикройте головы, начинаю бомбардировку")
	icon_state = "radiohecu_talking"
	playsound(src, 'sound/machines/chime.ogg', 70, FALSE, 7, 3)
	addtimer(CALLBACK(src, .proc/reset_icon), 3 SECONDS)

/obj/machinery/negotiations_radio/bombardment/proc/drop_bombs(turf/target_turf)
	if(!src || !target_turf)
		return

	var/bomb_count = rand(1, 2)
	var/list/target_turfs = list()
	for(var/turf/T in range(1, target_turf))
		target_turfs |= T

	for(var/i in 1 to bomb_count)
		if(target_turfs.len > 0)
			var/turf/drop_turf = pick(target_turfs)
			target_turfs -= drop_turf
			addtimer(CALLBACK(src, .proc/drop_single_bomb, drop_turf), (i - 1) * 2 SECONDS)

/obj/machinery/negotiations_radio/bombardment/proc/drop_single_bomb(turf/drop_turf)
	if(!src || !drop_turf)
		return

	playsound(drop_turf, 'sound/weapons/mortar_long_whistle.ogg', 80, TRUE)

	addtimer(CALLBACK(src, .proc/explode_bomb, drop_turf), 2 SECONDS)

/obj/machinery/negotiations_radio/bombardment/proc/explode_bomb(turf/drop_turf)
	if(!src || !drop_turf)
		return

	playsound(drop_turf, 'sound/effects/explosionfar.ogg', 100, TRUE)

	explosion(drop_turf, 0, 1, 2, 3)

	for(var/turf/T in range(2, drop_turf))
		for(var/obj/structure/barricade/wooden/W in T)
			if(W)
				W.take_damage(1000)
		for(var/obj/structure/barricade/wooden/crude/C in T)
			if(C)
				C.take_damage(1000)

	bombardment_active = FALSE

/obj/machinery/negotiations_radio/bombardment/proc/announce_out_of_fuel()
	if(!src)
		return

	say("Говорит пеликан-1. Топливо на критично низком уровне. Улетаю на базу")
	icon_state = "radiohecu_talking"
	playsound(src, 'sound/machines/chime.ogg', 70, FALSE, 7, 3)
	addtimer(CALLBACK(src, .proc/reset_icon), 3 SECONDS)

	if(linked_console)
		linked_console.enabled = FALSE
		visible_message(span_warning("Консоль бомбардировки отключена!"))

/obj/machinery/negotiations_radio/bombardment/confirm_action(mob/user)
	if(!user || !src)
		return

	if(!dialogue_active || current_interactor != user)
		return

	next_interaction_time = world.time + 2 SECONDS
	say("Координаты приняты. Консоль бомбардировки активирована.")
	icon_state = "radiohecu_talking"
	playsound(src, 'sound/machines/chime.ogg', 70, FALSE, 7, 3)
	addtimer(CALLBACK(src, .proc/reset_icon), 3 SECONDS)

	enable_console()
	dialogue_completed = TRUE
	end_dialogue()

// =============================================================================
// BOMBARDMENT CAMERA CONSOLE
// Camera console restricted to bombardment zone with target marking
// =============================================================================

/obj/machinery/computer/camera_advanced/bombardment
	name = "bombardment control console"
	desc = "A military console for designating airstrike targets."
	icon_screen = "tactical"
	icon_keyboard = "tech_key"
	light_color = LIGHT_COLOR_RED
	var/enabled = FALSE
	var/area/restricted_area = /area/awaymission/ihategordon/outsideofmesa/bombardment
	var/next_mark_time = 0
	var/mark_cooldown = 1 MINUTES
	var/datum/action/innate/bombardment_mark/mark_action = /datum/action/innate/bombardment_mark
	var/charges_remaining = 4
	var/obj/machinery/negotiations_radio/bombardment/linked_radio = null
	var/restricted_z = null

/obj/machinery/computer/camera_advanced/bombardment/Initialize()
	. = ..()
	if(mark_action)
		actions += new mark_action(src)

	// Auto-link to nearby radio if not already linked
	if(!linked_radio)
		for(var/obj/machinery/negotiations_radio/bombardment/radio in range(10, src))
			if(!radio.linked_console)
				linked_radio = radio
				radio.linked_console = src
				break

	// Set restricted z-level to current z
	restricted_z = z

/obj/machinery/computer/camera_advanced/bombardment/GrantActions(mob/living/user)
	..(user)
	if(mark_action && enabled)
		mark_action.target = src
		mark_action.Grant(user)
		actions += mark_action

/obj/machinery/computer/camera_advanced/bombardment/remove_eye_control(mob/living/user)
	. = ..()
	if(mark_action)
		mark_action.Remove(user)

/obj/machinery/computer/camera_advanced/bombardment/can_use(mob/user)
	if(!enabled)
		to_chat(user, span_warning("Консоль не активирована. Свяжитесь с тактическим радио."))
		return FALSE
	return ..()

/obj/machinery/computer/camera_advanced/bombardment/CreateEye()
	eyeobj = new /mob/camera/aiEye/remote/bombardment(get_turf(src))
	eyeobj.origin = src
	eyeobj.use_static = USE_STATIC_NONE

/obj/machinery/computer/camera_advanced/bombardment/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	if(!enabled)
		to_chat(user, span_warning("Консоль не активирована. Свяжитесь с тактическим радио."))
		return
	..()

/mob/camera/aiEye/remote/bombardment
	name = "Bombardment Camera Eye"
	var/obj/machinery/computer/camera_advanced/bombardment/console_origin

/mob/camera/aiEye/remote/bombardment/relaymove(mob/user, direct)
	if(!console_origin || !console_origin.enabled)
		return
	var/turf/step = get_turf(get_step(src, direct))
	if(!step)
		return

	// Restrict to specific z-level
	if(console_origin.restricted_z && step.z != console_origin.restricted_z)
		to_chat(user, span_warning("Невозможно переместиться за пределы зоны бомбардировки."))
		return

	var/area/step_area = get_area(step)
	if(!istype(step_area, console_origin.restricted_area))
		to_chat(user, span_warning("Невозможно переместиться за пределы зоны бомбардировки."))
		return
	..()

/datum/action/innate/bombardment_mark
	name = "Mark Target"
	icon_icon = 'icons/mob/actions/actions_mecha.dmi'
	button_icon_state = "mech_zoom_off"
	var/obj/machinery/computer/camera_advanced/bombardment/target_console

/datum/action/innate/bombardment_mark/Activate()
	if(!owner || !isliving(owner))
		return
	var/mob/living/L = owner
	var/mob/camera/aiEye/remote/remote_eye = L.remote_control
	if(!istype(remote_eye, /mob/camera/aiEye/remote/bombardment))
		return
	var/mob/camera/aiEye/remote/bombardment/bombardment_eye = remote_eye
	target_console = bombardment_eye.console_origin

	if(!target_console)
		return

	if(target_console.charges_remaining <= 0)
		to_chat(owner, span_warning("Заряды израсходованы!"))
		return

	if(world.time < target_console.next_mark_time)
		var/remaining = (target_console.next_mark_time - world.time) / 10
		to_chat(owner, span_warning("Перезарядка: [remaining] секунд."))
		return

	var/turf/target_turf = get_turf(bombardment_eye)
	if(!target_turf)
		return

	var/area/target_area = get_area(target_turf)
	if(!istype(target_area, target_console.restricted_area))
		to_chat(owner, span_warning("Цель должна быть в зоне бомбардировки!"))
		return

	target_console.next_mark_time = world.time + target_console.mark_cooldown
	target_console.charges_remaining--

	to_chat(owner, span_notice("Transit location designated. Осталось зарядов: [target_console.charges_remaining]"))
	playsound(target_console, 'sound/machines/ping.ogg', 50, TRUE)

	new /obj/effect/temp_visual/target_marker(target_turf)

	if(target_console.linked_radio && !target_console.linked_radio.bombardment_active)
		target_console.linked_radio.trigger_bombardment(target_turf)

	if(target_console.charges_remaining <= 0)
		addtimer(CALLBACK(target_console.linked_radio, TYPE_PROC_REF(/obj/machinery/negotiations_radio/bombardment, announce_out_of_fuel)), 15 SECONDS)

// =============================================================================
// TARGET MARKER EFFECT
// Visual marker for bombardment targets
// =============================================================================

/obj/effect/temp_visual/target_marker
	name = "target marker"
	icon = 'icons/effects/effects.dmi'
	icon_state = "explosion"
	duration = 10 SECONDS
	color = COLOR_RED
