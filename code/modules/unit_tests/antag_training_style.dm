/datum/antag_training_session/unit_test_style
	var/list/sounds = list()
	var/opened = 0

/datum/antag_training_session/unit_test_style/play_training_sound(soundin)
	sounds += soundin
	return ..()

/datum/antag_training_session/unit_test_style/ui_interact(mob/user, datum/tgui/ui)
	opened++

/datum/antag_training_exercise/unit_test_style
	id = "unit_test_style"
	name = "Учебные шаги"
	desc = "Два шага по площадке."
	sector = "melee"
	steps = list(/datum/antag_training_exercise_step/unit_test_style_walk, /datum/antag_training_exercise_step/unit_test_style_walk)

/datum/antag_training_exercise/unit_test_style/dark
	id = "unit_test_style_dark"
	name = "Учебные шаги в темноте"
	sector = "dark"

/datum/antag_training_exercise/unit_test_style/timed
	id = "unit_test_style_timed"
	time_limit = 1 SECONDS

/datum/antag_training_exercise_step/unit_test_style_walk
	name = "Сделайте шаг"
	hint = "Перейдите на соседнюю клетку."

/datum/antag_training_exercise_step/unit_test_style_walk/attach(datum/antag_training_exercise_run/owner)
	. = ..()
	RegisterSignal(participant(), COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))

/datum/antag_training_exercise_step/unit_test_style_walk/proc/on_moved(mob/living/source)
	SIGNAL_HANDLER
	complete()

/datum/unit_test/proc/allocate_style_session()
	wait_for_closing_training_arenas()
	var/datum/antag_training_session/unit_test_style/session = new /datum/antag_training_session/unit_test_style(/datum/antag_training_program/free)
	allocated += session
	return session

/datum/unit_test/proc/antag_training_boards_in(datum/antag_training_arena/arena, list/bounds)
	. = list()
	for(var/turf/tile as anything in block(locate(bounds[1], bounds[3], arena.private_level.z_value), locate(bounds[2], bounds[4], arena.private_level.z_value)))
		for(var/obj/structure/sign/antag_training_board/board in tile)
			. += board

/datum/unit_test/proc/antag_training_frame_count(turf/tile)
	. = 0
	for(var/mutable_appearance/overlay as anything in tile.overlays)
		if(overlay.icon_state == "shieldwall")
			.++

/datum/unit_test/proc/antag_training_sweeps_in(datum/antag_training_sector/sector)
	. = list()
	for(var/turf/tile as anything in sector.turfs)
		for(var/obj/effect/antag_training_sweep/sweep in tile)
			. += sweep

/// Стенд стоит в каждой зоне ядра и у входа в каждый сектор, рамка и волна не мешают проходу и уходят с сектором.
/datum/unit_test/antag_training_style_boards/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_arena/arena = session.arena
	for(var/zone_id in list("hub", "melee", "range", "pve", "laboratory"))
		var/list/core_boards = antag_training_boards_in(arena, arena.zones[zone_id]["bounds"])
		TEST_ASSERT_EQUAL(length(core_boards), 1, "[zone_id]: в зоне ядра один стенд.")
		var/obj/structure/sign/antag_training_board/core_board = core_boards[1]
		TEST_ASSERT(!core_board.light_range, "[zone_id]: в светлом ядре стенд без своего света.")
	var/obj/structure/sign/antag_training_board/old_board = antag_training_boards_in(arena, arena.zones["melee"]["bounds"])[1]
	TEST_ASSERT(arena.reset_zone("melee"), "Зона ядра сбрасывается.")
	TEST_ASSERT(QDELETED(old_board), "Сброс убирает прежний стенд.")
	TEST_ASSERT_EQUAL(length(antag_training_boards_in(arena, arena.zones["melee"]["bounds"])), 1, "После сброса в зоне снова один стенд.")
	var/mob/living/body = session.current_body
	for(var/sector_id in arena.sectors)
		var/datum/antag_training_sector/sector = arena.sectors[sector_id]
		TEST_ASSERT(sector.load(), "[sector_id]: сектор загружается.")
		var/list/boards = antag_training_boards_in(arena, sector.bounds)
		TEST_ASSERT_EQUAL(length(boards), 1, "[sector_id]: в секторе один стенд.")
		var/obj/structure/sign/antag_training_board/board = boards[1]
		TEST_ASSERT(get_dist(board, sector.spawn_turf()) <= 2, "[sector_id]: стенд у точки входа.")
		TEST_ASSERT(!(locate(/obj/effect/landmark) in get_turf(board)), "[sector_id]: стенд не встаёт на метку шаблона.")
		var/list/exits = list()
		for(var/turf/tile as anything in sector.turfs)
			for(var/obj/structure/antag_training_exit/found in tile)
				exits += found
		TEST_ASSERT_EQUAL(length(exits), 1, "[sector_id]: в секторе одна платформа возврата.")
		var/obj/structure/antag_training_exit/exit = exits[1]
		TEST_ASSERT(get_dist(exit, sector.spawn_turf()) <= 2 && get_turf(exit) != sector.spawn_turf() && get_turf(exit) != get_turf(board), "[sector_id]: платформа возврата у точки входа, не на ней и не под стендом.")
		TEST_ASSERT(!(locate(/obj/effect/landmark) in get_turf(exit)), "[sector_id]: платформа не встаёт на метку шаблона.")
		var/area/sector_area = get_area(board)
		TEST_ASSERT_EQUAL(!!board.light_range, sector_area.dynamic_lighting != DYNAMIC_LIGHTING_DISABLED, "[sector_id]: свой свет у стенда только там, где бывает темно.")
		if(sector_id == "dark")
			TEST_ASSERT(board.light_range, "Стенд тёмного сектора светится сам.")
		var/list/sweeps = antag_training_sweeps_in(sector)
		TEST_ASSERT_EQUAL(length(sweeps), 2, "[sector_id]: волна загрузки - два эффекта на сектор.")
		var/list/sides = sector.edge_tiles()
		var/list/edge = list()
		for(var/side in sides)
			edge |= sides[side]
		var/framed = 0
		for(var/turf/tile as anything in edge)
			framed += antag_training_frame_count(tile)
		var/width = sector.bounds[2] - sector.bounds[1] + 1
		var/height = sector.bounds[4] - sector.bounds[3] + 1
		TEST_ASSERT_EQUAL(framed, 2 * (width + height), "[sector_id]: по одному оверлею рамки на каждую сторону клетки края, без свечения.")
		body.forceMove(get_turf(board))
		var/turf/start = get_turf(body)
		var/moved = FALSE
		for(var/direction in GLOB.cardinals)
			var/turf/open/next = get_step(start, direction)
			if(istype(next) && !next.is_blocked_turf(exclude_mobs = FALSE) && body.Move(next, direction))
				moved = TRUE
				break
		TEST_ASSERT(moved, "[sector_id]: со стенда можно сойти.")
		TEST_ASSERT(body.Move(start, get_dir(body, start)), "[sector_id]: на стенд можно встать.")
		for(var/obj/effect/antag_training_sweep/sweep as anything in sweeps)
			TEST_ASSERT(!sweep.density && sweep.mouse_opacity == MOUSE_OPACITY_TRANSPARENT, "[sector_id]: волна не мешает проходу и кликам.")
			TEST_ASSERT(wait_for_qdeleted(sweep, 5 SECONDS), "[sector_id]: волна загрузки исчезает.")
		body.forceMove(arena.entry_turf)
		sector.unload()
		TEST_ASSERT(QDELETED(board) && QDELETED(exit), "[sector_id]: стенд и платформа возврата уходят с сектором.")
		for(var/turf/tile as anything in edge)
			TEST_ASSERT(!antag_training_frame_count(tile), "[sector_id]: рамка уходит с сектором.")

/// Нажатие на платформу возврата в секторе переносит участника в зал прибытия хаба.
/datum/unit_test/antag_training_style_exit/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_arena/arena = session.arena
	var/mob/living/carbon/human/user = session.current_body
	user.a_intent = INTENT_HELP
	var/datum/tgui/ui = allocate(/datum/tgui, user, session, "AntagTraining")
	antag_training_console_act(session, ui, "sector_enter", list("id" = "dark"))
	var/datum/antag_training_sector/sector = arena.sectors["dark"]
	var/list/budget = new_wait_budget(30 SECONDS, "участник в секторе")
	while(!(sector.bounds && arena.inside_bounds(get_turf(user), sector.bounds)) && wait_budget_tick(budget))
		continue
	TEST_ASSERT(sector.bounds && arena.inside_bounds(get_turf(user), sector.bounds), "Участник в секторе.")
	var/obj/structure/antag_training_exit/exit
	for(var/turf/tile as anything in sector.turfs)
		exit = locate() in tile
		if(exit)
			break
	TEST_ASSERT_NOTNULL(exit, "У входа в сектор есть платформа возврата.")
	user.forceMove(get_step(exit, get_dir(exit, sector.spawn_turf())))
	exit.attack_hand(user)
	TEST_ASSERT_EQUAL(get_turf(user), arena.hub_arrival(), "Платформа переносит в зал прибытия хаба.")

/// Нажатие участником на стенд открывает пульт с упражнениями этой зоны, осмотр называет тему зоны и упражнения.
/datum/unit_test/antag_training_style_board_click/Run()
	var/datum/antag_training_session/unit_test_style/session = allocate_style_session()
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_arena/arena = session.arena
	var/mob/living/carbon/human/user = session.current_body
	user.a_intent = INTENT_HELP
	var/datum/tgui/ui = allocate(/datum/tgui, user, session, "AntagTraining")
	antag_training_console_act(session, ui, "move", list("zone" = "melee"))
	var/obj/structure/sign/antag_training_board/board = antag_training_boards_in(arena, arena.zones["melee"]["bounds"])[1]
	var/examined = jointext(board.examine(user), "\n")
	TEST_ASSERT(findtext(examined, arena.zones["melee"]["name"]) && findtext(examined, arena.zones["melee"]["desc"]), "Осмотр называет зону и что в ней тренировать.")
	TEST_ASSERT(findtext(examined, "Учебные шаги (сложность 1)"), "Осмотр перечисляет упражнения зоны.")
	TEST_ASSERT(!findtext(examined, "Учебные шаги в темноте"), "Осмотр не перечисляет упражнения других зон.")
	board.attack_hand(user)
	TEST_ASSERT_EQUAL(session.opened, 1, "Нажатие на стенд открывает пульт участника.")
	TEST_ASSERT_NOTNULL(antag_training_exercise_entry(session, "unit_test_style"), "Пульт показывает упражнения зоны стенда.")
	var/datum/antag_training_sector/sector = arena.sectors["dark"]
	antag_training_console_act(session, ui, "sector_enter", list("id" = "dark"))
	var/list/budget = new_wait_budget(30 SECONDS, "участник в секторе")
	while(!(sector.bounds && arena.inside_bounds(get_turf(user), sector.bounds)) && wait_budget_tick(budget))
		continue
	TEST_ASSERT(sector.bounds && arena.inside_bounds(get_turf(user), sector.bounds), "Участник в секторе.")
	TEST_ASSERT(ANTAG_TRAINING_SOUND_SECTOR_LOAD in session.sounds, "Загрузка сектора звучит вошедшему.")
	board = antag_training_boards_in(arena, sector.bounds)[1]
	board.attack_hand(user)
	TEST_ASSERT_EQUAL(session.opened, 2, "Стенд сектора открывает пульт.")
	TEST_ASSERT_NOTNULL(antag_training_exercise_entry(session, "unit_test_style_dark"), "Пульт показывает упражнения сектора.")
	TEST_ASSERT_NULL(antag_training_exercise_entry(session, "unit_test_style"), "Пульт не показывает упражнения ядра в секторе.")
	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human, get_turf(board))
	board.attack_hand(stranger)
	TEST_ASSERT_EQUAL(session.opened, 2, "Чужой не открывает пульт участника.")
	session.sounds.Cut()
	arena.reset_zone("dark")
	TEST_ASSERT(ANTAG_TRAINING_SOUND_SECTOR_UNLOAD in session.sounds, "Сброс сектора звучит тому, кто в нём стоял.")
	TEST_ASSERT_EQUAL(sector.state, ANTAG_TRAINING_SECTOR_READY, "Сектор пересобран.")

/// Вход, восстановление, шаг и итог упражнения звучат участнику.
/datum/unit_test/antag_training_style_sounds/Run()
	var/datum/antag_training_session/unit_test_style/session = allocate_style_session()
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/mob/dead/observer/observer = allocate(/mob/dead/observer, run_loc_floor_bottom_left)
	TEST_ASSERT(session.connect(observer), "Призрак входит на полигон.")
	TEST_ASSERT(length(session.sounds) == 1 && session.sounds[1] == ANTAG_TRAINING_SOUND_ENTER, "Вход звучит участнику.")
	var/mob/living/carbon/human/user = session.current_body
	var/datum/tgui/ui = allocate(/datum/tgui, user, session, "AntagTraining")
	antag_training_console_act(session, ui, "move", list("zone" = "melee"))
	user.death()
	var/list/budget = new_wait_budget(10 SECONDS, "восстановление")
	while(user.stat == DEAD && wait_budget_tick(budget))
		continue
	TEST_ASSERT(ANTAG_TRAINING_SOUND_RECOVER in session.sounds, "Восстановление после смерти звучит участнику.")
	antag_training_console_act(session, ui, "move", list("zone" = "melee"))
	session.sounds.Cut()
	antag_training_console_act(session, ui, "exercise_start", list("id" = "unit_test_style"))
	var/datum/antag_training_exercise_run/run = session.exercise_run
	TEST_ASSERT_NOTNULL(run, "Упражнение стартует.")
	for(var/attempt in 1 to 2)
		if(run.ended)
			break
		var/turf/open/next = antag_training_free_step(user)
		user.Move(next, get_dir(user, next))
	TEST_ASSERT(run.ended && run.success, "Шаги выполнены.")
	TEST_ASSERT(ANTAG_TRAINING_SOUND_STEP in session.sounds, "Выполненный шаг звучит.")
	TEST_ASSERT(ANTAG_TRAINING_SOUND_SUCCESS in session.sounds, "Выполненное упражнение звучит.")
	TEST_ASSERT(!(ANTAG_TRAINING_SOUND_FAIL in session.sounds), "Успех не звучит провалом.")
	session.sounds.Cut()
	antag_training_console_act(session, ui, "exercise_start", list("id" = "unit_test_style_timed"))
	run = session.exercise_run
	TEST_ASSERT(wait_for_var(run, "ended", TRUE, 5 SECONDS), "Время упражнения выходит.")
	TEST_ASSERT(length(session.sounds) == 1 && session.sounds[1] == ANTAG_TRAINING_SOUND_FAIL, "Проваленное упражнение звучит.")
	allocated += session.finish()
