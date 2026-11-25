/obj/machinery/negotiations_radio/alarm
	name = "alarm radio"
	desc = "A field radio wired to a local alarm."
	icon_state = "radiohecu"
	can_skip_dialogue = FALSE

	var/alarm_sequence_active = FALSE
	var/alarm_doors_retry = FALSE
	var/alarm_wave_index = 0
	var/list/alarm_timer_ids = list()

	var/alarm_charge_time = 30 SECONDS
	var/alarm_wave_count = 3
	var/alarm_wave_duration = 30 SECONDS
	var/alarm_wave_retry_delay = 5 SECONDS
	var/alarm_speech_delay = 3 SECONDS
	var/alarm_door_delay = 4 SECONDS

	var/list/alarm_dialogue_lines = list(
		"ХАХ... Ну что, твари",
		"Не ждали что дверь закрою ПРЯМО перед вами. ХА! Вкусите, черти!",
		"Я буду включать сигнализацию, пока вы не передохнете!"
	)
	var/list/alarm_alert_phrases = list(
		"А НУ СЮДА! ЖИВО ОТВЕТЬТЕ, УТЫРКИ!",
		"ЭЙ! СЮДА ПОДОЙДИ",
		"ХЭЙ ХЭЭЙ! Я ТУУУТ!"
	)
	var/list/alarm_post_wave_lines = list(
		"ХУХ! Чё.. Не умерли. Исправим сейчас",
		"БЛЯТЬ! ТУПЫЕ ИДИОТЫ! ВЫ МЕНЯ ОТВЛЕКЛИ! ТЕПЕРЬ ТУТ ПОЛЗАЮТ ЭТИ ТВАРИ! ПОЛУЧАЙТЕ!",
		"...Хррр..."
	)

/obj/machinery/negotiations_radio/alarm/Initialize()
	. = ..()
	dialogue_lines = alarm_dialogue_lines
	alert_phrases = alarm_alert_phrases

/obj/machinery/negotiations_radio/alarm/process()
	if(alarm_sequence_active || alarm_doors_retry)
		return
	..()

/obj/machinery/negotiations_radio/alarm/Destroy()
	clear_alarm_timers()
	return ..()

/obj/machinery/negotiations_radio/alarm/attack_hand(mob/user)
	if(alarm_doors_retry)
		if(doors_ready_or_warn(user))
			alarm_doors_retry = FALSE
			dialogue_completed = TRUE
			to_chat(user, span_notice("Шлюзы открыты."))
		return
	if(alarm_sequence_active)
		to_chat(user, span_warning("Сигнализация уже активна."))
		return
	..()

/obj/machinery/negotiations_radio/alarm/confirm_action(mob/user)
	if(!user || !src)
		return
	if(!dialogue_active || !is_current_interactor(user))
		return
	end_dialogue()
	start_alarm_sequence(user)

/obj/machinery/negotiations_radio/alarm/proc/start_alarm_sequence(mob/user)
	if(!src || !user || alarm_sequence_active)
		return
	alarm_sequence_active = TRUE
	alarm_wave_index = 0
	to_chat(user, span_notice("Вы взводите сигнализацию..."))
	if(do_after(user, alarm_charge_time, target = src, timed_action_flags = IGNORE_USER_LOC_CHANGE | IGNORE_HELD_ITEM | IGNORE_INCAPACITATED))
		schedule_alarm_callback(CALLBACK(src, PROC_REF(alarm_begin_waves)), 1 SECONDS)
	else
		alarm_sequence_active = FALSE
		to_chat(user, span_warning("Активация сигнализации прервана."))

/obj/machinery/negotiations_radio/alarm/proc/alarm_begin_waves()
	if(!src || !alarm_sequence_active)
		return
	start_alarm_wave(1)

/obj/machinery/negotiations_radio/alarm/proc/start_alarm_wave(wave_index)
	if(!src || !alarm_sequence_active)
		return
	if(wave_index < 1 || wave_index > alarm_wave_count)
		schedule_alarm_callback(CALLBACK(src, PROC_REF(alarm_open_doors)), alarm_door_delay)
		return
	alarm_wave_index = wave_index
	var/datum/ai_director/zombie_mission/director = GLOB.zombie_director
	if(!director)
		log_world("[src] Alarm radio cannot trigger infected waves: zombie director is not initialized.")
		schedule_alarm_callback(CALLBACK(src, PROC_REF(alarm_open_doors)), alarm_door_delay)
		return
	if(!director.trigger_horde(TRUE))
		schedule_alarm_callback(CALLBACK(src, PROC_REF(start_alarm_wave), wave_index), alarm_wave_retry_delay)
		return
	playsound(src, 'sound/machines/Alarm.ogg', 80, FALSE, 10)
	schedule_alarm_callback(CALLBACK(src, PROC_REF(alarm_wave_elapsed), wave_index), alarm_wave_duration)

/obj/machinery/negotiations_radio/alarm/proc/alarm_wave_elapsed(wave_index)
	if(!src || !alarm_sequence_active || wave_index != alarm_wave_index)
		return
	if(wave_index <= alarm_post_wave_lines.len)
		alarm_play_line(alarm_post_wave_lines[wave_index])
	if(wave_index >= alarm_wave_count)
		schedule_alarm_callback(CALLBACK(src, PROC_REF(alarm_open_doors)), alarm_door_delay)
	else
		schedule_alarm_callback(CALLBACK(src, PROC_REF(start_alarm_wave), wave_index + 1), alarm_speech_delay)

/obj/machinery/negotiations_radio/alarm/proc/alarm_open_doors()
	if(!src)
		return
	alarm_sequence_active = FALSE
	var/list/result = open_blastdoors()
	if(!blastdoor_id || !result[1] || result[2])
		dialogue_completed = TRUE
		alarm_doors_retry = FALSE
	else
		dialogue_completed = FALSE
		alarm_doors_retry = TRUE
	alarm_timer_ids.Cut()

/obj/machinery/negotiations_radio/alarm/proc/alarm_play_line(line)
	if(!src || !line)
		return
	say(line, language = /datum/language/modular_sand/solcommon)
	icon_state = "radiohecu_talking"
	playsound(src, 'sound/machines/chime.ogg', 70, FALSE, 7, 3)
	addtimer(CALLBACK(src, PROC_REF(reset_icon)), 3 SECONDS)

/obj/machinery/negotiations_radio/alarm/proc/schedule_alarm_callback(datum/callback/callback, delay)
	if(!src || QDELETED(src))
		return
	alarm_timer_ids += addtimer(callback, delay, TIMER_STOPPABLE)

/obj/machinery/negotiations_radio/alarm/proc/clear_alarm_timers()
	for(var/timer_id in alarm_timer_ids)
		deltimer(timer_id)
	alarm_timer_ids.Cut()
