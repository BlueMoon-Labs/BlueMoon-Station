/obj/machinery/negotiations_radio/alarm
	name = "alarm radio"
	desc = "A field radio wired to a local alarm."
	icon_state = "radiohecu"
	can_skip_dialogue = FALSE

	var/alarm_sequence_active = FALSE
	var/alarm_doors_retry = FALSE
	var/alarm_wave_index = 0
	var/list/alarm_timer_ids = list()

	var/alarm_wave_count = 3
	var/alarm_wave_duration = 30 SECONDS
	var/alarm_spawn_interval = 5 SECONDS
	var/alarm_spawn_count = 6
	var/alarm_pulse_base = 5
	var/alarm_pulse_growth = 3
	var/alarm_breath_delay = 5 SECONDS

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
	if(!user || !src)
		return
	if(alarm_doors_retry)
		if(doors_ready_or_warn(user))
			alarm_doors_retry = FALSE
			dialogue_completed = TRUE
			to_chat(user, span_notice("Шлюзы открыты."))
		return
	if(alarm_sequence_active)
		to_chat(user, span_warning("Сигнализация уже активна."))
		return
	if(dialogue_completed)
		to_chat(user, span_warning("Радио больше не отвечает."))
		return
	// Один клик - и дальше радио говорит само, как distress radio вертолёта.
	// dialogue_completed глушит ambient-болтовню и детект игроков в process(),
	// пока идёт монолог и волны.
	alarm_sequence_active = TRUE
	dialogue_completed = TRUE
	INVOKE_ASYNC(src, PROC_REF(alarm_monologue))

/obj/machinery/negotiations_radio/alarm/proc/alarm_monologue()
	if(QDELETED(src))
		return
	icon_state = "radiohecu_talking"
	var/datum/language/lang = null
	if(/datum/language/modular_sand/solcommon in GLOB.language_datum_instances)
		lang = /datum/language/modular_sand/solcommon
	for(var/i in 1 to alarm_dialogue_lines.len)
		if(QDELETED(src) || !alarm_sequence_active)
			return
		say(alarm_dialogue_lines[i], language = lang)
		playsound(src, 'sound/machines/chime.ogg', 70, FALSE, 7, 3)
		sleep(i == alarm_dialogue_lines.len ? 50 : 40)
	if(QDELETED(src) || !alarm_sequence_active)
		return
	addtimer(CALLBACK(src, PROC_REF(reset_icon)), 10)
	start_alarm_wave(1)

/obj/machinery/negotiations_radio/alarm/proc/start_alarm_wave(wave_index)
	if(!src || !alarm_sequence_active)
		return
	if(wave_index < 1 || wave_index > alarm_wave_count)
		schedule_alarm_callback(CALLBACK(src, PROC_REF(alarm_open_doors)), alarm_breath_delay)
		return
	alarm_wave_index = wave_index
	// Сигнализация играет один раз на 30-секундную волну, без loop.
	playsound(src, 'modular_bluemoon/sound/creatures/mesa/madsci/alarm.ogg', 80, FALSE, 10)
	// Заражённые прибегают каждые 5 секунд с самого старта волны; орды растут
	// от волны к волне (5/8/11 за пульс при текущих настройках).
	var/pulse_size = alarm_pulse_base + (wave_index - 1) * alarm_pulse_growth
	for(var/pulse in 0 to alarm_spawn_count - 1)
		schedule_alarm_callback(CALLBACK(src, PROC_REF(alarm_spawn_pulse), wave_index, pulse_size), pulse * alarm_spawn_interval)
	schedule_alarm_callback(CALLBACK(src, PROC_REF(alarm_wave_elapsed), wave_index), alarm_wave_duration)

/obj/machinery/negotiations_radio/alarm/proc/alarm_spawn_pulse(wave_index, pulse_size)
	if(!src || !alarm_sequence_active || wave_index != alarm_wave_index)
		return
	var/datum/ai_director/zombie_mission/director = GLOB.zombie_director
	if(!director)
		log_world("[src] Alarm wave [wave_index]: zombie director is not initialized.")
		return
	if(!director.spawn_horde_pulse(src, pulse_size))
		log_world("[src] Alarm wave [wave_index]: no infected spawned (no valid targets or spawn turfs).")

/obj/machinery/negotiations_radio/alarm/proc/alarm_wave_elapsed(wave_index)
	if(!src || !alarm_sequence_active || wave_index != alarm_wave_index)
		return
	if(wave_index <= alarm_post_wave_lines.len)
		alarm_play_line(alarm_post_wave_lines[wave_index])
	// Пауза на передышку, после которой либо новая волна, либо открытие шлюзов.
	if(wave_index >= alarm_wave_count)
		schedule_alarm_callback(CALLBACK(src, PROC_REF(alarm_open_doors)), alarm_breath_delay)
	else
		schedule_alarm_callback(CALLBACK(src, PROC_REF(start_alarm_wave), wave_index + 1), alarm_breath_delay)

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
