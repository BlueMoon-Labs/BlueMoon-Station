GLOBAL_LIST_INIT(antag_training_exercises, init_antag_training_exercises())
/// ckey -> (id упражнения -> лучший результат): лучший результат переживает выход и новый вход в том же раунде; сеанс без ckey хранит записи у себя.
GLOBAL_LIST_EMPTY(antag_training_exercise_records)
GLOBAL_LIST_INIT(antag_training_practice_exercises, list(
	"combat" = list("name" = "Довести цель до крита", "goal" = "Доведите цель до крита", "zone" = "range", "difficulty" = 1, "desc" = "Урон по неподвижной цели: оружие, приёмы своего пути и время до крита."),
	"medicine" = list("name" = "Вылечить пациента", "goal" = "Полностью вылечите пациента", "zone" = "laboratory", "difficulty" = 1, "desc" = "Осмотр анализатором и лечение ушибов и ожогов обычными средствами."),
	"hunt" = list("name" = "Первое подношение", "goal" = "Принесите учебную цель в жертву", "zone" = "laboratory", "difficulty" = 2, "desc" = "Цель охоты, живое сердце и обряд подношения на учебной цели."),
	"dance" = list("name" = "Урок Пляски", "zone" = "range", "difficulty" = 2, "desc" = "Пошаговый урок пути Пляски: такт, Вальс, смена стиля, Приглашение и спасение партнёра."),
	"spirit" = list("name" = "Урок Духа", "zone" = "range", "difficulty" = 2, "desc" = "Пошаговый урок пути Духа: Разлучение, притяжение и удержание души, обол.")
))

/proc/init_antag_training_exercises()
	var/list/exercises = list()
	for(var/datum/antag_training_exercise/exercise_type as anything in subtypesof(/datum/antag_training_exercise))
		if(initial(exercise_type.id))
			var/datum/antag_training_exercise/exercise = new exercise_type
			exercises[exercise.id] = exercise
	return sortTim(exercises, GLOBAL_PROC_REF(cmp_antag_training_exercises), TRUE)

/proc/cmp_antag_training_exercises(datum/antag_training_exercise/first, datum/antag_training_exercise/second)
	return first.difficulty - second.difficulty || sorttext(second.name, first.name)

/// Описание упражнения, одно на тип; ход прохождения хранит /datum/antag_training_exercise_run.
/datum/antag_training_exercise
	var/id
	var/name
	var/desc
	/// id сектора или зоны ядра.
	var/sector
	/// Тип программы вместе с подтипами; null - для всех программ.
	var/program
	/// Типы /datum/antag_training_exercise_step по порядку.
	var/list/steps = list()
	var/difficulty = 1
	var/par_time = 1 MINUTES
	/// 0 - без ограничения времени.
	var/time_limit = 0

/datum/antag_training_exercise/proc/available(datum/antag_training_session/session)
	return !program || istype(session.program, program)

/// Готовит цели и реквизит через session.exercise_run.add_prop(); FALSE или текст причины - упражнение сейчас не подготовить.
/datum/antag_training_exercise/proc/setup(datum/antag_training_session/session)
	SHOULD_NOT_SLEEP(TRUE)
	return TRUE

/// Возвращает обстановку, которую setup() менял, кроме реквизита: его удаляет прогон.
/datum/antag_training_exercise/proc/teardown(datum/antag_training_session/session)
	SHOULD_NOT_SLEEP(TRUE)
	return

/datum/antag_training_exercise/proc/score(time, hints)
	var/overtime = max(0, round((time - par_time) / (1 SECONDS)))
	return clamp(ANTAG_TRAINING_EXERCISE_SCORE_MAX - hints * ANTAG_TRAINING_EXERCISE_HINT_PENALTY - overtime * ANTAG_TRAINING_EXERCISE_SECOND_PENALTY, ANTAG_TRAINING_EXERCISE_SCORE_MIN, ANTAG_TRAINING_EXERCISE_SCORE_MAX)

/datum/antag_training_exercise/proc/score_rule()
	. = "Оценка: [ANTAG_TRAINING_EXERCISE_SCORE_MAX] баллов, минус [ANTAG_TRAINING_EXERCISE_HINT_PENALTY] за каждую подсказку и [ANTAG_TRAINING_EXERCISE_SECOND_PENALTY] за каждую секунду сверх [par_time / (1 SECONDS)] с, но не меньше [ANTAG_TRAINING_EXERCISE_SCORE_MIN]."
	if(time_limit)
		. += " На всё упражнение [time_limit / (1 SECONDS)] с."

/datum/antag_training_exercise_step
	var/name
	var/hint
	var/datum/antag_training_exercise_run/run
	var/done = FALSE
	var/hint_shown = FALSE

/// Подписывается на сигналы шага; обработчик засчитывает шаг через complete().
/datum/antag_training_exercise_step/proc/attach(datum/antag_training_exercise_run/owner)
	SHOULD_CALL_PARENT(TRUE)
	SHOULD_NOT_SLEEP(TRUE)
	run = owner

/datum/antag_training_exercise_step/proc/detach()
	SHOULD_CALL_PARENT(TRUE)
	for(var/target in signal_procs)
		UnregisterSignal(target, signal_procs[target])

/datum/antag_training_exercise_step/proc/complete()
	SHOULD_NOT_SLEEP(TRUE)
	if(done || run?.current_step() != src)
		return FALSE
	done = TRUE
	run.advance()
	return TRUE

/datum/antag_training_exercise_step/proc/participant()
	return run?.session?.current_body

/datum/antag_training_exercise_step/Destroy()
	run = null
	return ..()

/// Шаг с check(): проверка сразу после подключения, затем раз в ANTAG_TRAINING_EXERCISE_CHECK_INTERVAL, если polling; события зовут recheck().
/datum/antag_training_exercise_step/checked
	var/check_timer
	var/polling = TRUE

/datum/antag_training_exercise_step/checked/attach(datum/antag_training_exercise_run/owner)
	. = ..()
	deltimer(check_timer)
	check_timer = addtimer(CALLBACK(src, PROC_REF(recheck)), 0, TIMER_STOPPABLE)

/datum/antag_training_exercise_step/checked/detach()
	deltimer(check_timer)
	check_timer = null
	return ..()

/datum/antag_training_exercise_step/checked/Destroy()
	deltimer(check_timer)
	check_timer = null
	return ..()

/datum/antag_training_exercise_step/checked/proc/schedule_check()
	deltimer(check_timer)
	check_timer = addtimer(CALLBACK(src, PROC_REF(recheck)), ANTAG_TRAINING_EXERCISE_CHECK_INTERVAL, TIMER_STOPPABLE)

/datum/antag_training_exercise_step/checked/proc/recheck()
	SIGNAL_HANDLER
	if(done || !run || run.ended || run.current_step() != src)
		return
	if(check())
		complete()
	else if(polling && !done && !run.ended && run.current_step() == src)
		schedule_check()

/datum/antag_training_exercise_step/checked/proc/check()
	SHOULD_NOT_SLEEP(TRUE)
	return FALSE

/datum/antag_training_exercise_run
	var/datum/antag_training_session/session
	var/datum/antag_training_exercise/exercise
	var/list/datum/antag_training_exercise_step/steps = list()
	var/step_index = 0
	var/started_at
	var/ended_at
	var/ended = FALSE
	var/success = FALSE
	var/hints = 0
	var/score
	var/new_best = FALSE
	var/result_text
	var/list/atom/movable/props = list()
	var/limit_timer

/datum/antag_training_exercise_run/New(datum/antag_training_session/owner, datum/antag_training_exercise/selected)
	session = owner
	exercise = selected
	for(var/step_type in exercise.steps)
		steps += new step_type

/// required = FALSE - расходник или деталь, уходящая в результат: её удаление не проваливает прогон, остаток удаляется вместе с прогоном.
/datum/antag_training_exercise_run/proc/add_prop(atom/movable/prop, required = TRUE)
	if(QDELETED(prop))
		return null
	props += prop
	RegisterSignal(prop, COMSIG_PARENT_QDELETING, required ? PROC_REF(on_prop_deleted) : PROC_REF(on_spare_deleted))
	return prop

/datum/antag_training_exercise_run/proc/on_prop_deleted(atom/movable/prop)
	SIGNAL_HANDLER
	props -= prop
	finish(FALSE, "реквизит упражнения пропал")

/datum/antag_training_exercise_run/proc/on_spare_deleted(atom/movable/prop)
	SIGNAL_HANDLER
	props -= prop

/// number-й по порядку добавления реквизит типа prop_type.
/datum/antag_training_exercise_run/proc/find_prop(prop_type, number = 1)
	var/found = 0
	for(var/atom/movable/prop as anything in props)
		if(istype(prop, prop_type) && ++found == number)
			return prop

/datum/antag_training_exercise_run/proc/current_step()
	if(step_index >= 1 && step_index <= length(steps))
		return steps[step_index]

/datum/antag_training_exercise_run/proc/elapsed()
	return (ended ? ended_at : world.time) - started_at

/datum/antag_training_exercise_run/proc/begin()
	started_at = world.time
	if(ended)
		return
	if(exercise.time_limit)
		limit_timer = addtimer(CALLBACK(src, PROC_REF(finish), FALSE, "время вышло"), exercise.time_limit, TIMER_STOPPABLE)
	to_chat(session.current_body, span_boldnotice("Упражнение «[exercise.name]» началось. Шагов: [length(steps)]. Каждая подсказка в пульте снимает [ANTAG_TRAINING_EXERCISE_HINT_PENALTY] баллов."))
	advance()

/datum/antag_training_exercise_run/proc/advance()
	SHOULD_NOT_SLEEP(TRUE)
	if(ended)
		return
	var/datum/antag_training_exercise_step/finished_step = current_step()
	if(finished_step)
		finished_step.detach()
		on_step_complete(finished_step)
	step_index++
	var/datum/antag_training_exercise_step/next_step = current_step()
	if(!next_step)
		finish(TRUE)
		return
	to_chat(session.current_body, span_notice("Шаг [step_index] из [length(steps)]: [next_step.name]."))
	next_step.attach(src)

/// Тело участника сменилось: текущий шаг подписывается заново, поэтому attach() шага должен быть повторяемым.
/datum/antag_training_exercise_run/proc/rebind()
	var/datum/antag_training_exercise_step/active = current_step()
	if(ended || !active)
		return
	active.detach()
	active.attach(src)

/datum/antag_training_exercise_run/proc/use_hint()
	var/datum/antag_training_exercise_step/active = current_step()
	if(ended || !active?.hint)
		return FALSE
	if(!active.hint_shown)
		active.hint_shown = TRUE
		hints++
	to_chat(session.current_body, span_notice("Подсказка: [active.hint]"))
	return TRUE

/datum/antag_training_exercise_run/proc/finish(succeeded, reason)
	SHOULD_NOT_SLEEP(TRUE)
	if(ended)
		return
	ended = TRUE
	success = succeeded
	ended_at = world.time
	deltimer(limit_timer)
	limit_timer = null
	var/datum/antag_training_exercise_step/active = current_step()
	active?.detach()
	var/seconds = round(elapsed() / (1 SECONDS), 0.1)
	if(success)
		score = exercise.score(elapsed(), hints)
		new_best = session.record_exercise(exercise.id, list("time" = seconds, "hints" = hints, "score" = score))
		result_text = "Выполнено за [seconds] с, подсказок: [hints], оценка [score].[new_best ? " Это ваш лучший результат." : ""]"
	else
		result_text = "Не выполнено: [reason]."
	on_finish(success)

/datum/antag_training_exercise_run/proc/on_step_complete(datum/antag_training_exercise_step/finished_step)
	if(step_index < length(steps))
		session.play_training_sound(ANTAG_TRAINING_SOUND_STEP)
	to_chat(session.current_body, span_notice("Шаг выполнен: [finished_step.name]."))

/datum/antag_training_exercise_run/proc/on_finish(succeeded)
	session.play_training_sound(succeeded ? ANTAG_TRAINING_SOUND_SUCCESS : ANTAG_TRAINING_SOUND_FAIL)
	if(succeeded)
		to_chat(session.current_body, span_boldnotice("Упражнение «[exercise.name]»: [result_text]"))
	else
		to_chat(session.current_body, span_warning("Упражнение «[exercise.name]»: [result_text]"))

/datum/antag_training_exercise_run/Destroy()
	if(!ended)
		ended = TRUE
		deltimer(limit_timer)
		limit_timer = null
		var/datum/antag_training_exercise_step/active = current_step()
		active?.detach()
	exercise.teardown(session)
	for(var/atom/movable/prop as anything in props)
		UnregisterSignal(prop, COMSIG_PARENT_QDELETING)
		if(isliving(prop))
			var/mob/living/body = prop
			QDEL_NULL(body.mind)
		qdel(prop)
	props.Cut()
	QDEL_LIST(steps)
	session = null
	exercise = null
	return ..()

/datum/antag_training_session
	var/datum/antag_training_exercise_run/exercise_run
	var/list/exercise_results

/datum/antag_training_session/proc/exercise_records()
	if(!isnull(exercise_results))
		return exercise_results
	exercise_results = list()
	if(player_key && player_key != REF(src))
		var/list/records = GLOB.antag_training_exercise_records[player_key]
		if(records)
			exercise_results = records
		else
			GLOB.antag_training_exercise_records[player_key] = exercise_results
	return exercise_results

/// Сохраняет результат, если он лучше прежнего: выше оценка, при равной - меньше время.
/datum/antag_training_session/proc/record_exercise(exercise_id, list/result)
	var/list/records = exercise_records()
	var/list/best = records[exercise_id]
	if(best && (best["score"] > result["score"] || (best["score"] == result["score"] && best["time"] <= result["time"])))
		return FALSE
	records[exercise_id] = result
	return TRUE

/datum/antag_training_session/proc/start_exercise(exercise_id)
	var/datum/antag_training_exercise/exercise = istext(exercise_id) ? GLOB.antag_training_exercises[exercise_id] : null
	if(!exercise || !can_control(current_body) || preparing || arena.resetting)
		return FALSE
	if(!exercise.available(src))
		practice_message("Упражнение «[exercise.name]» вам недоступно: [exercise.unavailable_reason(src)].")
		return FALSE
	if(arena.match_zone(current_body) != exercise.sector)
		var/datum/antag_training_sector/sector = arena.sectors[exercise.sector]
		practice_message("Упражнение «[exercise.name]» проходит в зоне «[sector?.name || arena.zones[exercise.sector]?["name"]]». Перейдите туда во вкладке «Зоны».")
		return FALSE
	stop_exercise()
	var/datum/antag_training_exercise_run/run = new(src, exercise)
	exercise_run = run
	var/prepared = exercise.setup(src)
	if(!prepared || istext(prepared))
		stop_exercise()
		practice_message(istext(prepared) ? "Упражнение «[exercise.name]» не начато: [prepared]." : "Упражнение «[exercise.name]» сейчас не подготовить: освободите место в лимитах полигона или сбросьте зону.")
		return FALSE
	stop_practice()
	run.begin()
	return TRUE

/datum/antag_training_session/proc/stop_exercise(reason)
	if(!exercise_run)
		return FALSE
	if(reason && !exercise_run.ended)
		to_chat(current_body, span_warning(reason))
	QDEL_NULL(exercise_run)
	return TRUE

/datum/antag_training_session/proc/exercise_hint()
	return exercise_run?.use_hint()

/datum/antag_training_arena/proc/stop_zone_exercises(zone_id)
	for(var/datum/antag_training_session/member as anything in members)
		var/datum/antag_training_exercise_run/run = member.exercise_run
		if(run && (zone_id == "all" || run.exercise.sector == zone_id))
			member.stop_exercise("Упражнение «[run.exercise.name]» прекращено: его зону сбросили или выгрузили.")

/datum/antag_training_session/proc/exercise_data()
	. = list()
	var/zone_id = arena.match_zone(current_body)
	var/list/records = exercise_records()
	for(var/exercise_id in GLOB.antag_training_exercises)
		var/datum/antag_training_exercise/exercise = GLOB.antag_training_exercises[exercise_id]
		var/datum/antag_training_exercise_run/run = exercise_run?.exercise == exercise ? exercise_run : null
		if(!run && (exercise.sector != zone_id || !exercise.available(src)))
			continue
		var/list/steps = list()
		for(var/index in 1 to length(exercise.steps))
			var/datum/antag_training_exercise_step/step_type = exercise.steps[index]
			if(!run)
				steps += list(list("name" = initial(step_type.name), "done" = FALSE, "current" = FALSE, "hint" = null))
				continue
			var/datum/antag_training_exercise_step/run_step = run.steps[index]
			steps += list(list("name" = run_step.name, "done" = run_step.done, "current" = !run.ended && run.step_index == index, "hint" = run_step.hint_shown ? run_step.hint : null))
		var/datum/antag_training_sector/sector = arena.sectors[exercise.sector]
		var/list/run_data = run ? list("elapsed" = round(run.elapsed() / (1 SECONDS), 0.1), "hints" = run.hints, "ended" = run.ended, "success" = run.success, "score" = run.score, "result" = run.result_text) : null
		. += list(list("id" = exercise.id, "name" = exercise.name, "desc" = exercise.desc, "difficulty" = exercise.difficulty, "zone" = sector?.name || arena.zones[exercise.sector]?["name"], "practice" = FALSE, "score_rule" = exercise.score_rule(), "steps" = steps, "best" = records[exercise.id], "run" = run_data))
	for(var/practice_key in GLOB.antag_training_practice_exercises)
		var/list/practice = GLOB.antag_training_practice_exercises[practice_key]
		var/active = practice_id == practice_key
		if(!active && (practice["zone"] != zone_id || !practice_available(practice_key)))
			continue
		var/list/steps = active ? (dance_lesson?.steps() || spirit_lesson?.steps()) : null
		if(!steps)
			steps = list(list("name" = practice["goal"] || practice["name"], "done" = active && practice_complete, "current" = active && !practice_complete, "hint" = null))
		. += list(list("id" = practice_key, "name" = practice["name"], "desc" = practice["desc"], "difficulty" = practice["difficulty"], "zone" = arena.zones[practice["zone"]]["name"], "practice" = TRUE, "score_rule" = null, "steps" = steps, "best" = null, "run" = active ? list("ended" = practice_complete, "success" = practice_complete, "result" = practice_hint) : null))

/datum/antag_training_session/proc/practice_available(practice_key)
	switch(practice_key)
		if("hunt")
			return !!IS_HERETIC(current_body)
		if("dance")
			return !!dance_knowledge()
		if("spirit")
			return !!spirit_knowledge()
	return TRUE
