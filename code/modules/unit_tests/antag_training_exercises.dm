/datum/antag_training_exercise/unit_test_sample
	id = "unit_test_sample"
	name = "Учебный пример"
	desc = "Взять ручку и положить её на стол."
	sector = "melee"
	steps = list(/datum/antag_training_exercise_step/unit_test_pickup, /datum/antag_training_exercise_step/unit_test_table)

/datum/antag_training_exercise/unit_test_sample/setup(datum/antag_training_session/session)
	var/turf/start = get_turf(session.current_body)
	var/turf/table_spot
	for(var/direction in GLOB.cardinals)
		var/turf/open/spot = get_step(start, direction)
		if(istype(spot) && !spot.is_blocked_turf())
			table_spot = spot
			break
	if(!table_spot)
		return FALSE
	var/obj/item/pen/pen = session.arena.issue_item(/obj/item/pen, start, 1, session)
	return session.exercise_run.add_prop(pen) && session.exercise_run.add_prop(new /obj/structure/table(table_spot))

/datum/antag_training_exercise/unit_test_sample/heretic
	id = "unit_test_heretic"
	program = /datum/antag_training_program/heretic

/datum/antag_training_exercise/unit_test_sample/timed
	id = "unit_test_timed"
	time_limit = 1 SECONDS

/datum/antag_training_exercise/unit_test_sample/dark
	id = "unit_test_dark"
	sector = "dark"

/datum/antag_training_exercise/unit_test_body
	id = "unit_test_body"
	name = "Учебный шаг"
	desc = "Сделать шаг в своём текущем теле."
	sector = "melee"
	steps = list(/datum/antag_training_exercise_step/unit_test_walk)

/datum/antag_training_exercise_step/unit_test_walk
	name = "Сделайте шаг"
	hint = "Перейдите на соседнюю клетку."

/datum/antag_training_exercise_step/unit_test_walk/attach(datum/antag_training_exercise_run/owner)
	. = ..()
	RegisterSignal(participant(), COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))

/datum/antag_training_exercise_step/unit_test_walk/proc/on_moved(mob/living/source)
	SIGNAL_HANDLER
	if(source == participant())
		complete()

/datum/antag_training_exercise_step/unit_test_pickup
	name = "Возьмите ручку"
	hint = "Нажмите на ручку пустой рукой."

/datum/antag_training_exercise_step/unit_test_pickup/attach(datum/antag_training_exercise_run/owner)
	. = ..()
	RegisterSignal(owner.props[1], COMSIG_ITEM_PICKUP, PROC_REF(on_pickup))

/datum/antag_training_exercise_step/unit_test_pickup/proc/on_pickup(obj/item/source, mob/taker)
	SIGNAL_HANDLER
	if(taker == participant())
		complete()

/datum/antag_training_exercise_step/unit_test_table
	name = "Положите ручку на стол"
	hint = "Нажмите ручкой в руке на стол."

/datum/antag_training_exercise_step/unit_test_table/attach(datum/antag_training_exercise_run/owner)
	. = ..()
	RegisterSignal(owner.props[1], COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))

/datum/antag_training_exercise_step/unit_test_table/proc/on_moved(obj/item/source)
	SIGNAL_HANDLER
	if(isturf(source.loc) && (locate(/obj/structure/table) in source.loc))
		complete()

/datum/unit_test/proc/antag_training_exercise_entry(datum/antag_training_session/session, exercise_id)
	var/list/data = session.ui_data(session.current_body)
	for(var/list/entry as anything in data["exercises"])
		if(entry["id"] == exercise_id)
			return entry

/// Упражнение стартует из пульта в своей зоне, шаги засчитываются игровыми действиями, итог даёт время и оценку, лучший результат хранится, повтор - новый прогон.
/datum/unit_test/antag_training_exercise_flow/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/mob/living/carbon/human/user = session.current_body
	user.a_intent = INTENT_HELP
	var/datum/tgui/ui = allocate(/datum/tgui, user, session, "AntagTraining")
	TEST_ASSERT_NULL(antag_training_exercise_entry(session, "unit_test_sample"), "В центре нет упражнений зоны ближнего боя.")
	antag_training_console_act(session, ui, "exercise_start", list("id" = "unit_test_sample"))
	TEST_ASSERT_NULL(session.exercise_run, "Упражнение не стартует вне своей зоны.")
	antag_training_console_act(session, ui, "move", list("zone" = "melee"))
	var/list/entry = antag_training_exercise_entry(session, "unit_test_sample")
	TEST_ASSERT_NOTNULL(entry, "Пульт показывает упражнение текущей зоны.")
	TEST_ASSERT_EQUAL(length(entry["steps"]), 2, "Пульт показывает шаги до старта.")
	TEST_ASSERT(findtext(entry["score_rule"], "минус [ANTAG_TRAINING_EXERCISE_HINT_PENALTY] за каждую подсказку"), "Описание объясняет оценку.")
	TEST_ASSERT_NULL(antag_training_exercise_entry(session, "unit_test_heretic"), "Упражнение другой программы скрыто.")
	antag_training_console_act(session, ui, "exercise_start", list("id" = "unit_test_heretic"))
	TEST_ASSERT_NULL(session.exercise_run, "Упражнение другой программы не стартует.")

	antag_training_console_act(session, ui, "exercise_start", list("id" = "unit_test_sample"))
	var/datum/antag_training_exercise_run/first_run = session.exercise_run
	TEST_ASSERT_NOTNULL(first_run, "Упражнение стартует из пульта.")
	var/obj/item/pen/pen = first_run.props[1]
	var/obj/structure/table/table = first_run.props[2]
	entry = antag_training_exercise_entry(session, "unit_test_sample")
	TEST_ASSERT(entry["steps"][1]["current"] && !entry["steps"][1]["done"] && !entry["steps"][2]["current"], "Активен первый шаг.")
	TEST_ASSERT_NULL(entry["steps"][1]["hint"], "Подсказка скрыта до запроса.")
	antag_training_console_act(session, ui, "exercise_hint", list())
	antag_training_console_act(session, ui, "exercise_hint", list())
	entry = antag_training_exercise_entry(session, "unit_test_sample")
	TEST_ASSERT_EQUAL(entry["run"]["hints"], 1, "Подсказка шага считается один раз.")
	TEST_ASSERT_EQUAL(entry["steps"][1]["hint"], "Нажмите на ручку пустой рукой.", "Пульт показывает открытую подсказку.")
	TEST_ASSERT_NULL(entry["steps"][2]["hint"], "Подсказка следующего шага скрыта.")

	pen.attack_hand(user)
	TEST_ASSERT_EQUAL(pen.loc, user, "Участник берёт ручку.")
	entry = antag_training_exercise_entry(session, "unit_test_sample")
	TEST_ASSERT(entry["steps"][1]["done"] && entry["steps"][2]["current"] && !entry["run"]["ended"], "Первый шаг засчитан, активен второй.")
	table.attackby(pen, user)
	TEST_ASSERT_EQUAL(get_turf(pen), get_turf(table), "Ручка лежит на столе.")
	TEST_ASSERT(first_run.ended && first_run.success, "Ручка на столе завершает упражнение.")
	TEST_ASSERT_EQUAL(first_run.score, ANTAG_TRAINING_EXERCISE_SCORE_MAX - ANTAG_TRAINING_EXERCISE_HINT_PENALTY, "Оценка в контрольное время снижена только за подсказку.")
	entry = antag_training_exercise_entry(session, "unit_test_sample")
	TEST_ASSERT(entry["run"]["ended"] && entry["run"]["success"] && entry["steps"][2]["done"], "Пульт показывает итог.")
	TEST_ASSERT(findtext(entry["run"]["result"], "оценка [first_run.score]"), "Итог называет оценку.")
	TEST_ASSERT_NOTNULL(entry["best"], "Пульт показывает лучший результат.")
	TEST_ASSERT_EQUAL(entry["best"]["score"], first_run.score, "Лучший результат хранит оценку.")
	TEST_ASSERT_EQUAL(entry["best"]["hints"], 1, "Лучший результат хранит подсказки.")
	TEST_ASSERT(abs(entry["best"]["time"] - first_run.elapsed() / (1 SECONDS)) < 0.1, "Лучший результат хранит время.")
	var/datum/antag_training_exercise_step/last_step = first_run.steps[2]
	TEST_ASSERT(!length(last_step.signal_procs), "Завершённый шаг снимает подписки.")

	antag_training_console_act(session, ui, "exercise_start", list("id" = "unit_test_sample"))
	var/datum/antag_training_exercise_run/second_run = session.exercise_run
	TEST_ASSERT(second_run && second_run != first_run, "Повтор создаёт новый прогон.")
	TEST_ASSERT(QDELETED(first_run) && QDELETED(pen) && QDELETED(table), "Повтор удаляет прежний прогон и его реквизит.")
	entry = antag_training_exercise_entry(session, "unit_test_sample")
	TEST_ASSERT(entry["steps"][1]["current"] && !entry["steps"][1]["done"] && !entry["run"]["hints"] && !entry["run"]["ended"], "Новый прогон начинается с первого шага без подсказок.")
	TEST_ASSERT_EQUAL(entry["best"]["score"], ANTAG_TRAINING_EXERCISE_SCORE_MAX - ANTAG_TRAINING_EXERCISE_HINT_PENALTY, "Повтор сохраняет лучший результат.")
	pen = second_run.props[1]
	table = second_run.props[2]
	antag_training_console_act(session, ui, "exercise_hint", list())
	pen.attack_hand(user)
	antag_training_console_act(session, ui, "exercise_hint", list())
	table.attackby(pen, user)
	TEST_ASSERT(second_run.ended && second_run.success, "Повтор выполняется.")
	TEST_ASSERT_EQUAL(second_run.score, ANTAG_TRAINING_EXERCISE_SCORE_MAX - 2 * ANTAG_TRAINING_EXERCISE_HINT_PENALTY, "Каждая подсказка снижает оценку.")
	TEST_ASSERT(!second_run.new_best, "Худший прогон не объявлен лучшим.")
	TEST_ASSERT_EQUAL(session.exercise_results["unit_test_sample"]["score"], ANTAG_TRAINING_EXERCISE_SCORE_MAX - ANTAG_TRAINING_EXERCISE_HINT_PENALTY, "Худший результат не заменяет лучший.")

	antag_training_console_act(session, ui, "exercise_stop", list())
	TEST_ASSERT(isnull(session.exercise_run) && QDELETED(second_run) && QDELETED(pen), "«Прекратить» снимает упражнение и реквизит.")
	TEST_ASSERT(!(REF(session) in GLOB.antag_training_exercise_records), "Записи сеанса без ckey не попадают в общий список.")
	entry = antag_training_exercise_entry(session, "unit_test_sample")
	TEST_ASSERT_NOTNULL(entry["best"], "Лучший результат остаётся после остановки.")

/datum/unit_test/proc/antag_training_free_step(mob/living/body)
	for(var/direction in GLOB.cardinals)
		var/turf/open/spot = get_step(body, direction)
		if(istype(spot) && !spot.is_blocked_turf(exclude_mobs = FALSE))
			return spot

/datum/unit_test/proc/antag_training_active_entries(datum/antag_training_session/session)
	. = 0
	var/list/data = session.ui_data(session.current_body)
	for(var/list/entry as anything in data["exercises"])
		var/list/run = entry["run"]
		if(run && !run["ended"])
			.++

/// Старт упражнения прекращает практику роли, старт практики прекращает упражнение: в пульте активно одно.
/datum/unit_test/antag_training_exercise_single_active/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/tgui/ui = allocate(/datum/tgui, session.current_body, session, "AntagTraining")
	antag_training_console_act(session, ui, "move", list("zone" = "melee"))
	antag_training_console_act(session, ui, "exercise_start", list("id" = "unit_test_sample"))
	var/datum/antag_training_exercise_run/run = session.exercise_run
	TEST_ASSERT_NOTNULL(run, "Упражнение стартует.")
	antag_training_console_act(session, ui, "practice", list("id" = "combat"))
	TEST_ASSERT_EQUAL(session.practice_id, "combat", "Практика стартует.")
	TEST_ASSERT(isnull(session.exercise_run) && QDELETED(run), "Старт практики прекращает упражнение.")
	TEST_ASSERT_EQUAL(antag_training_active_entries(session), 1, "После старта практики в пульте одно активное.")
	antag_training_console_act(session, ui, "move", list("zone" = "melee"))
	antag_training_console_act(session, ui, "exercise_start", list("id" = "unit_test_sample"))
	TEST_ASSERT_NOTNULL(session.exercise_run, "Упражнение стартует после практики.")
	TEST_ASSERT_NULL(session.practice_id, "Старт упражнения прекращает практику.")
	TEST_ASSERT_EQUAL(antag_training_active_entries(session), 1, "После старта упражнения в пульте одно активное.")

/// Перенос разума в другое тело переподписывает текущий шаг: шаг засчитывается на новом теле и не слушает прежнее.
/datum/unit_test/antag_training_exercise_body_change/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/tgui/ui = allocate(/datum/tgui, session.current_body, session, "AntagTraining")
	antag_training_console_act(session, ui, "move", list("zone" = "melee"))
	var/mob/living/old_body = session.current_body
	var/mob/living/carbon/human/vessel = session.arena.spawn_creature("human", "melee", FALSE, session, get_turf(old_body))
	TEST_ASSERT_NOTNULL(vessel, "Создано второе тело.")
	antag_training_console_act(session, ui, "exercise_start", list("id" = "unit_test_body"))
	var/datum/antag_training_exercise_run/run = session.exercise_run
	TEST_ASSERT_NOTNULL(run, "Упражнение стартует.")
	session.avatar_mind.transfer_to(vessel)
	TEST_ASSERT_EQUAL(session.current_body, vessel, "Перенос разума меняет тело участника.")
	var/datum/antag_training_exercise_step/active = run.current_step()
	TEST_ASSERT(!(old_body in active.signal_procs) && (vessel in active.signal_procs), "Шаг переподписан с прежнего тела на новое.")
	var/turf/old_step = antag_training_free_step(old_body)
	TEST_ASSERT_NOTNULL(old_step, "Прежнему телу есть куда шагнуть.")
	old_body.Move(old_step, get_dir(old_body, old_step))
	TEST_ASSERT_EQUAL(get_turf(old_body), old_step, "Прежнее тело шагнуло.")
	TEST_ASSERT(!run.ended, "Шаг прежнего тела не засчитывается.")
	var/turf/new_step = antag_training_free_step(vessel)
	TEST_ASSERT_NOTNULL(new_step, "Новому телу есть куда шагнуть.")
	vessel.Move(new_step, get_dir(vessel, new_step))
	TEST_ASSERT_EQUAL(get_turf(vessel), new_step, "Новое тело шагнуло.")
	TEST_ASSERT(run.ended && run.success, "Шаг нового тела засчитывается.")

/// Смена программы, сброс зоны и выход прекращают упражнение, снимают подписки шага и удаляют реквизит.
/datum/unit_test/antag_training_exercise_cleanup/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_arena/arena = session.arena
	var/datum/tgui/ui = allocate(/datum/tgui, session.current_body, session, "AntagTraining")
	for(var/stage in list("Смена программы", "Сброс зоны", "Выход"))
		antag_training_console_act(session, ui, "move", list("zone" = "melee"))
		antag_training_console_act(session, ui, "exercise_start", list("id" = "unit_test_sample"))
		var/datum/antag_training_exercise_run/run = session.exercise_run
		TEST_ASSERT_NOTNULL(run, "[stage]: упражнение стартует.")
		var/datum/antag_training_exercise_step/active = run.current_step()
		var/obj/item/pen/pen = run.props[1]
		TEST_ASSERT(length(active.signal_procs), "[stage]: шаг подписан на реквизит.")
		switch(stage)
			if("Смена программы")
				antag_training_console_act(session, ui, "restart", list("program" = "[/datum/antag_training_program/free]"))
			if("Сброс зоны")
				antag_training_console_act(session, ui, "reset_zone", list("zone" = "melee"))
				TEST_ASSERT(wait_for_var(arena, "resetting", FALSE, 30 SECONDS), "Сброс зоны завершается.")
			if("Выход")
				session.exit_prompt_type = /datum/tgui_alert/async/antag_training_exit/unit_test
				antag_training_console_act(session, ui, "exit", list())
				var/list/budget = new_wait_budget(5 SECONDS, "вопрос выхода")
				while(!session.exit_prompt && wait_budget_tick(budget))
					continue
				TEST_ASSERT(answer_training_exit(session, ANTAG_TRAINING_EXIT_GHOST), "Пульт спрашивает, куда выйти.")
				TEST_ASSERT(wait_for_qdeleted(session, 5 SECONDS), "«В призрака» закрывает сеанс.")
		TEST_ASSERT(isnull(session.exercise_run) && QDELETED(run), "[stage]: упражнение прекращено.")
		TEST_ASSERT(QDELETED(active) && !length(active.signal_procs), "[stage]: подписки шага сняты.")
		TEST_ASSERT(QDELETED(pen), "[stage]: реквизит удалён.")
	TEST_ASSERT(wait_for_qdeleted(arena, 1 MINUTES), "Полигон закрывается после выхода.")

/// Сброс сектора и выгрузка простаивающего сектора прекращают упражнение этого сектора.
/datum/unit_test/antag_training_exercise_sector/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_arena/arena = session.arena
	var/datum/antag_training_sector/sector = arena.sectors["dark"]
	var/datum/tgui/ui = allocate(/datum/tgui, session.current_body, session, "AntagTraining")
	for(var/stage in list("Сброс сектора", "Выгрузка простаивающего сектора"))
		antag_training_console_act(session, ui, "sector_enter", list("id" = "dark"))
		var/list/budget = new_wait_budget(30 SECONDS, "участник в секторе")
		while(!(sector.state == ANTAG_TRAINING_SECTOR_READY && arena.inside_bounds(get_turf(session.current_body), sector.bounds)) && wait_budget_tick(budget))
			continue
		TEST_ASSERT_NOTNULL(antag_training_exercise_entry(session, "unit_test_dark"), "[stage]: пульт показывает упражнение сектора.")
		antag_training_console_act(session, ui, "exercise_start", list("id" = "unit_test_dark"))
		var/datum/antag_training_exercise_run/run = session.exercise_run
		TEST_ASSERT_NOTNULL(run, "[stage]: упражнение стартует в секторе.")
		var/datum/antag_training_exercise_step/active = run.current_step()
		if(stage == "Сброс сектора")
			antag_training_console_act(session, ui, "reset_zone", list("zone" = "dark"))
			TEST_ASSERT(wait_for_var(arena, "resetting", FALSE, 30 SECONDS), "Сброс сектора завершается.")
		else
			antag_training_console_act(session, ui, "move", list("zone" = "hub"))
			sector.last_occupied_at = world.time - ANTAG_TRAINING_SECTOR_IDLE - 1 SECONDS
			sector.check_idle()
			TEST_ASSERT(wait_for_var(sector, "state", ANTAG_TRAINING_SECTOR_UNLOADED, 30 SECONDS), "Простаивающий сектор выгружается.")
		TEST_ASSERT(isnull(session.exercise_run) && QDELETED(run) && QDELETED(active), "[stage]: упражнение прекращено.")

/// Каталог упражнений согласован, ограничение времени проваливает прогон без записи результата, практики роли видны в списке своей зоны.
/datum/unit_test/antag_training_exercise_catalog/Run()
	var/list/zone_ids = list("melee", "range", "pve", "laboratory")
	for(var/datum/antag_training_sector/sector_type as anything in subtypesof(/datum/antag_training_sector))
		if(initial(sector_type.id))
			zone_ids += initial(sector_type.id)
	var/defined = 0
	for(var/datum/antag_training_exercise/exercise_type as anything in subtypesof(/datum/antag_training_exercise))
		if(initial(exercise_type.id))
			defined++
	TEST_ASSERT_EQUAL(length(GLOB.antag_training_exercises), defined, "У каждого упражнения свой id.")
	for(var/exercise_id in GLOB.antag_training_exercises)
		var/datum/antag_training_exercise/exercise = GLOB.antag_training_exercises[exercise_id]
		TEST_ASSERT(exercise.name && exercise.desc, "[exercise.type]: есть название и описание.")
		TEST_ASSERT(exercise.sector in zone_ids, "[exercise.type]: сектор [exercise.sector] существует.")
		TEST_ASSERT(exercise.difficulty >= 1 && exercise.difficulty <= 3, "[exercise.type]: сложность от 1 до 3.")
		TEST_ASSERT(length(exercise.steps), "[exercise.type]: есть шаги.")
		for(var/datum/antag_training_exercise_step/step_type as anything in exercise.steps)
			TEST_ASSERT(initial(step_type.name) && initial(step_type.hint), "[exercise.type]: у шага [step_type] есть название и подсказка.")

	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/tgui/ui = allocate(/datum/tgui, session.current_body, session, "AntagTraining")
	antag_training_console_act(session, ui, "move", list("zone" = "melee"))
	antag_training_console_act(session, ui, "exercise_start", list("id" = "unit_test_timed"))
	var/datum/antag_training_exercise_run/run = session.exercise_run
	TEST_ASSERT_NOTNULL(run, "Упражнение с ограничением времени стартует.")
	var/datum/antag_training_exercise_step/active = run.current_step()
	TEST_ASSERT(wait_for_var(run, "ended", TRUE, 10 SECONDS), "Ограничение времени завершает прогон.")
	TEST_ASSERT(!run.success && findtext(run.result_text, "время вышло"), "Прогон по истечении времени провален.")
	TEST_ASSERT(!length(active.signal_procs), "Проваленный шаг снимает подписки.")
	var/list/records = session.exercise_records()
	TEST_ASSERT_NULL(records["unit_test_timed"], "Провал не записывается в лучший результат.")

	antag_training_console_act(session, ui, "move", list("zone" = "range"))
	var/list/combat = antag_training_exercise_entry(session, "combat")
	TEST_ASSERT(combat?["practice"], "Практика зоны показана среди упражнений.")
	TEST_ASSERT_NULL(antag_training_exercise_entry(session, "dance"), "Урок пути без знания скрыт.")
	TEST_ASSERT_NULL(antag_training_exercise_entry(session, "medicine"), "Практика другой зоны скрыта.")
	var/list/timed = antag_training_exercise_entry(session, "unit_test_timed")
	TEST_ASSERT(timed?["run"]?["ended"], "Итог последнего прогона виден и вне его зоны.")
	antag_training_console_act(session, ui, "practice", list("id" = "combat"))
	combat = antag_training_exercise_entry(session, "combat")
	TEST_ASSERT(combat["run"] && combat["steps"][1]["current"], "Начатая практика показана активной.")
	TEST_ASSERT_EQUAL(combat["run"]["result"], session.practice_hint, "Практика показывает свою подсказку.")
	antag_training_console_act(session, ui, "move", list("zone" = "hub"))
	TEST_ASSERT_NOTNULL(antag_training_exercise_entry(session, "combat"), "Активная практика видна вне своей зоны.")
	TEST_ASSERT_NULL(antag_training_exercise_entry(session, "hunt"), "Подношение скрыто вне программы еретика.")
