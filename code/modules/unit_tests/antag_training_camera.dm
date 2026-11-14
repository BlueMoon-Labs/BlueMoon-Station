/mob/camera/antag_training_test
	name = "training camera"

/datum/antagonist/antag_training_camera_test
	name = "Учебная камера"
	show_in_roundend = FALSE
	show_in_antagpanel = FALSE
	show_in_check_antagonists = FALSE
	show_to_ghosts = FALSE
	soft_antag = TRUE
	prevent_roundtype_conversion = FALSE
	replace_banned = FALSE
	reminded_times_left = 0
	var/datum/antag_training_session/training

/datum/antagonist/antag_training_camera_test/attach_training(datum/antag_training_session/session)
	training = session
	return TRUE

/datum/antagonist/antag_training_camera_test/threat()
	return 0

/datum/antagonist/antag_training_camera_test/Destroy()
	training = null
	return ..()

/datum/antag_training_program/creature/camera_test
	name = "Камера-моб"
	category = "Существа"
	desc = "Тело роли без здоровья."
	icon = "video"
	color = "grey"
	learn = "Тело без здоровья|Восстановление на месте|Граница полигона"
	difficulty = 1
	antag_type = /datum/antagonist/antag_training_camera_test
	choices = list(/mob/camera/antag_training_test = "камера")

/// Камера-моб как тело сеанса: пульт открывается, здоровье и защита центра не трогаются, восстановление пересоздаёт камеру на месте, граница полигона держит её, выход возвращает призрака.
/datum/unit_test/antag_training_camera_body/Run()
	wait_for_closing_training_arenas()
	var/mob/dead/observer/observer = allocate(/mob/dead/observer, run_loc_floor_bottom_left)
	var/datum/antag_training_session/session = start_antag_training(observer, /datum/antag_training_program/creature/camera_test, FALSE)
	TEST_ASSERT_NOTNULL(session, "Призрак входит в программу с камерой.")
	allocated += session
	var/datum/antag_training_arena/arena = session.arena
	var/mob/camera/antag_training_test/body = session.current_body
	TEST_ASSERT(istype(body), "Тело сеанса - камера-моб.")
	TEST_ASSERT_EQUAL(body.mind, session.avatar_mind, "Разум участника в камере.")
	TEST_ASSERT_EQUAL(body.training_origin?.resolve(), arena, "Камера принадлежит полигону.")
	TEST_ASSERT(locate(/datum/action/antag_training_controls) in body.actions, "У камеры есть пульт полигона.")
	TEST_ASSERT(session.controls.Trigger(), "Пульт открывается из камеры.")
	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")
	var/list/data = session.ui_data(body)
	TEST_ASSERT(isnull(data["health"]) && isnull(data["max_health"]), "Пульт не показывает здоровье камеры.")
	for(var/list/member as anything in data["members"])
		if(member["self"])
			TEST_ASSERT(isnull(member["health"]), "В списке участников у камеры нет здоровья.")

	TEST_ASSERT(!body.alerts["antag_training_safe"] && !HAS_TRAIT_FROM(body, TRAIT_PACIFISM, REF(session)), "Защита центра не ставится камере.")
	var/turf/melee_spawn = arena.zones["melee"]["spawn"]
	TEST_ASSERT(body.forceMove(melee_spawn), "Камера ходит по полигону.")
	TEST_ASSERT(body.status_flags & GODMODE, "Сеанс не снимает с камеры неуязвимость.")
	body.forceMove(run_loc_floor_bottom_left)
	TEST_ASSERT_EQUAL(get_turf(body), melee_spawn, "Камера не выходит с полигона на станцию.")

	var/datum/antag_training_program/creature/camera_test/program = session.program
	program.rebuilding = TRUE
	GLOB.unit_test_chat_capture = list()
	antag_training_console_act(session, console, "heal", list())
	var/refusal_heard = antag_training_chat_heard(body, "Это тело восстановить нельзя")
	GLOB.unit_test_chat_capture = null
	program.rebuilding = FALSE
	TEST_ASSERT(refusal_heard && session.current_body == body, "Неудачное пересоздание объясняется участнику и оставляет прежнее тело.")
	session.next_heal_at = 0
	antag_training_console_act(session, console, "heal", list())
	var/mob/camera/antag_training_test/rebuilt = session.current_body
	TEST_ASSERT(!session.finished, "Восстановление не закрывает сеанс.")
	TEST_ASSERT(istype(rebuilt) && rebuilt != body, "Восстановление пересоздаёт камеру.")
	TEST_ASSERT(QDELETED(body), "Прежняя камера убрана.")
	TEST_ASSERT_EQUAL(rebuilt.mind, session.avatar_mind, "Новая камера получает разум участника.")
	TEST_ASSERT_EQUAL(get_turf(rebuilt), melee_spawn, "Новая камера появляется на месте прежней.")
	TEST_ASSERT(locate(/datum/action/antag_training_controls) in rebuilt.actions, "Пульт переходит в новую камеру.")

	session.exit_prompt_type = /datum/tgui_alert/async/antag_training_exit/unit_test
	rebuilt.key = "unit_test_training_camera_exit"
	TEST_ASSERT(session.exit_action.Trigger(), "Кнопка выхода нажимается из камеры.")
	TEST_ASSERT(answer_training_exit(session, ANTAG_TRAINING_EXIT_GHOST), "Выход спрашивает, куда вернуться.")
	var/closed = wait_for_qdeleted(session, 2 SECONDS)
	var/mob/dead/observer/returned = find_training_player("unit_test_training_camera_exit", /mob/dead/observer)
	if(returned)
		allocated += returned
		returned.key = null
	TEST_ASSERT(closed, "«В призрака» закрывает сеанс.")
	TEST_ASSERT_NOTNULL(returned, "Игрок возвращается из камеры призраком.")
	TEST_ASSERT(QDELETED(rebuilt), "Камера убирается с сеансом.")

/// Глаз ИИ, созданного на полигоне, принадлежит той же арене, встаёт рядом с ядром и не выходит на станцию.
/datum/unit_test/antag_training_ai_eye/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_arena/arena = session.arena
	var/mob/living/carbon/human/occupant = allocate(/mob/living/carbon/human)
	var/mob/living/silicon/ai/core = new(arena.zones["melee"]["spawn"], null, occupant)
	allocated += core
	TEST_ASSERT_EQUAL(core.training_origin?.resolve(), arena, "ИИ принадлежит полигону.")
	var/mob/camera/aiEye/eye = core.eyeobj
	TEST_ASSERT_NOTNULL(eye, "У ИИ есть глаз.")
	TEST_ASSERT_EQUAL(eye.training_origin?.resolve(), arena, "Глаз ИИ принадлежит тому же полигону.")
	TEST_ASSERT_EQUAL(get_turf(eye), get_turf(core), "Глаз встаёт у ядра на полигоне.")
	eye.setLoc(run_loc_floor_bottom_left)
	TEST_ASSERT_EQUAL(get_turf(eye), get_turf(core), "Глаз ИИ полигона не выходит на станцию.")
	var/mob/camera/aiEye/stranger = allocate(/mob/camera/aiEye, run_loc_floor_bottom_left)
	stranger.forceMove(arena.entry_turf)
	TEST_ASSERT_EQUAL(get_turf(stranger), run_loc_floor_bottom_left, "Чужой глаз без ИИ полигона не входит на полигон.")

/// Учебный взрыв бомбы при участнике-камере доходит до всех участников без рантайма и возвращает бомбу.
/datum/unit_test/antag_training_camera_nuke/Run()
	var/datum/antag_training_session/watcher = allocate_training_session(/datum/antag_training_program/creature/camera_test)
	TEST_ASSERT(watcher.prepare(), "Полигон готовит камеру.")
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/nukeop)
	TEST_ASSERT(session.prepare(watcher.arena), "Оперативник входит на тот же полигон.")
	TEST_ASSERT(antag_training_nukeop_kit(session), "Учебные бомба и диск появляются.")
	var/datum/antag_training_program/antag/nukeop/program = session.program
	var/obj/machinery/nuclearbomb/training/bomb = program.training_bomb()
	bomb.safety = FALSE
	bomb.timing = TRUE
	bomb.detonation_timer = world.time - 1
	GLOB.unit_test_chat_capture = list()
	bomb.process()
	var/camera_heard = antag_training_chat_heard(watcher.current_body, "Учебная бомба взорвана")
	var/operative_heard = antag_training_chat_heard(session.current_body, "Учебная бомба взорвана")
	GLOB.unit_test_chat_capture = null
	TEST_ASSERT(camera_heard && operative_heard, "Сообщение об учебном взрыве получают и камера, и оперативник.")
	TEST_ASSERT(program.detonation_objective.completed, "Учебная задача засчитана.")
	TEST_ASSERT(!bomb.timing && !bomb.exploding && bomb.safety, "После взрыва бомба выключена, а не застряла во взрыве.")

/datum/unit_test/antag_training_camera_nuke/Destroy()
	GLOB.unit_test_chat_capture = null
	return ..()

/datum/unit_test/antag_training_camera_body/Destroy()
	GLOB.unit_test_chat_capture = null
	return ..()
