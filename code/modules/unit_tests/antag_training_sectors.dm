/// Области секторов принадлежат арене наравне с ядром, перемещение участника между ними разрешено.
/datum/unit_test/antag_training_sector_areas/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_arena/arena = session.arena
	var/area/antag_training/sector/test_area = GLOB.areas_by_type[/area/antag_training/sector] || new /area/antag_training/sector
	var/turf/sector_tile = locate(ANTAG_TRAINING_SIZE + 10, 10, arena.private_level.z_value)
	var/area/previous_area = get_area(sector_tile)
	test_area.contents += sector_tile
	test_area.arena = arena
	TEST_ASSERT(arena.owns_area(arena.room), "Ядро принадлежит арене.")
	TEST_ASSERT(arena.owns_area(test_area), "Область сектора принадлежит арене.")
	TEST_ASSERT(!arena.owns_area(get_area(run_loc_floor_bottom_left)), "Станция не принадлежит арене.")
	TEST_ASSERT(session.current_body.forceMove(sector_tile), "Участник переходит в сектор.")
	TEST_ASSERT(session.can_control(session.current_body), "Пульт доступен в секторе.")
	session.current_body.forceMove(run_loc_floor_bottom_left)
	TEST_ASSERT_EQUAL(get_turf(session.current_body), sector_tile, "Из сектора на станцию не выйти.")
	session.current_body.forceMove(arena.entry_turf)
	test_area.arena = null
	previous_area.contents += sector_tile

/// Сектор грузится в свой слот, становится зоной арены и полностью исчезает при выгрузке.
/datum/unit_test/antag_training_sector_lifecycle/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_arena/arena = session.arena
	var/datum/antag_training_sector/sector = arena.sectors["dark"]
	TEST_ASSERT_NOTNULL(sector, "Арена знает тёмный сектор.")
	TEST_ASSERT_EQUAL(sector.state, ANTAG_TRAINING_SECTOR_UNLOADED, "Сектор не грузится вместе с ядром.")
	TEST_ASSERT_NULL(arena.zones["dark"], "Незагруженный сектор - не зона.")
	TEST_ASSERT(sector.load(), "Сектор загружается.")
	TEST_ASSERT(arena.zones["dark"], "Готовый сектор - зона арены.")
	arena.finished = TRUE
	var/handed_to_closing = sector.load()
	arena.finished = FALSE
	TEST_ASSERT(!handed_to_closing, "Закрывающийся полигон не отдаёт даже готовый сектор.")
	var/turf/inside = sector.spawn_turf()
	TEST_ASSERT(arena.owns_area(get_area(inside)), "Клетки сектора в области арены.")
	TEST_ASSERT(isopenturf(inside), "Точка входа - пол.")
	var/datum/gas_mixture/air = inside.return_air()
	var/pressure = air.return_pressure()
	TEST_ASSERT(pressure > WARNING_LOW_PRESSURE && pressure < WARNING_HIGH_PRESSURE, "В секторе нормальное давление, а не [pressure] кПа.")
	for(var/turf/tile as anything in sector.turfs)
		for(var/obj/thing in tile)
			TEST_ASSERT(thing.training_origin?.resolve() == arena, "[thing.type] с карты сектора принадлежит арене.")
	TEST_ASSERT(IS_DYNAMIC_LIGHTING(sector.sector_area) && inside.lighting_object, "В тёмном секторе работает динамический свет.")
	var/mob/living/target = arena.spawn_creature("human", "dark")
	TEST_ASSERT_NOTNULL(target, "В секторе создаются цели.")
	var/obj/item/pen/left_behind = new(inside)
	TEST_ASSERT(left_behind.training_origin, "Предметы сектора принадлежат арене.")
	session.current_body.forceMove(inside)
	sector.unload()
	TEST_ASSERT_EQUAL(sector.state, ANTAG_TRAINING_SECTOR_UNLOADED, "Сектор выгружен.")
	TEST_ASSERT_NULL(arena.zones["dark"], "Выгруженный сектор - не зона.")
	TEST_ASSERT(QDELETED(left_behind) && QDELETED(target), "Выгрузка удаляет содержимое.")
	var/list/leftovers = dirty_sector_slot(sector, arena)
	TEST_ASSERT(!length(leftovers), "После выгрузки в слоте осталось: [leftovers.Join(", ")].")
	TEST_ASSERT_EQUAL(get_turf(session.current_body), arena.entry_turf, "Участник выходит в центр.")
	TEST_ASSERT(sector.load(), "Сектор загружается повторно.")

/// Пустой сектор выгружается после простоя, занятый - нет; последний выход выгружает все сектора.
/datum/unit_test/antag_training_sector_idle/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_arena/arena = session.arena
	var/datum/antag_training_sector/sector = arena.sectors["dark"]
	TEST_ASSERT(sector.load(), "Сектор загружается.")
	session.current_body.forceMove(sector.spawn_turf())
	sector.last_occupied_at = world.time - ANTAG_TRAINING_SECTOR_IDLE - 1 SECONDS
	sector.check_idle()
	TEST_ASSERT_EQUAL(sector.state, ANTAG_TRAINING_SECTOR_READY, "Занятый сектор не выгружается.")
	session.current_body.forceMove(arena.entry_turf)
	sector.last_occupied_at = world.time - ANTAG_TRAINING_SECTOR_IDLE - 1 SECONDS
	sector.check_idle()
	TEST_ASSERT(wait_for_var(sector, "state", ANTAG_TRAINING_SECTOR_UNLOADED, 30 SECONDS), "Пустой сектор выгружается после простоя.")
	TEST_ASSERT(sector.load(), "Сектор загружается.")
	var/turf/slot = sector.spawn_turf()
	qdel(session)
	TEST_ASSERT(wait_for_qdeleted(arena, 1 MINUTES), "Полигон закрывается.")
	TEST_ASSERT(isspaceturf(slot), "Закрытие арены выгружает сектора.")
	TEST_ASSERT(QDELETED(sector), "Сектора удаляются с ареной.")
	TEST_ASSERT(isnull(sector.spawn_turf()) && isnull(sector.target_turf()), "Удалённый сектор не ищет клеток на чужом уровне.")

/// Закрытие полигона ждёт сектор, который ещё грузится, и не отдаёт уровень раньше него.
/datum/unit_test/antag_training_sector_close/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_arena/arena = session.arena
	var/datum/antag_training_sector/sector = arena.sectors["dark"]
	var/datum/space_level/level = arena.private_level
	sector.state = ANTAG_TRAINING_SECTOR_LOADING
	qdel(session)
	var/list/budget = new_wait_budget(2 SECONDS, "разбор полигона")
	while(!QDELETED(arena) && !isspaceturf(locate(1, 1, level.z_value)) && wait_budget_tick(budget))
		continue
	var/dismantled = QDELETED(arena) || isspaceturf(locate(1, 1, level.z_value)) || (level in GLOB.antag_training_free_levels)
	sector.state = ANTAG_TRAINING_SECTOR_UNLOADED
	TEST_ASSERT(!dismantled, "Полигон не разбирается, пока сектор грузится.")
	TEST_ASSERT(wait_for_qdeleted(arena, 1 MINUTES), "Полигон закрывается, когда сектор освободился.")
	TEST_ASSERT(level in GLOB.antag_training_free_levels, "Уровень освобождается после закрытия.")

/datum/antag_training_sector/dark/crash_after_load
	id = null

/datum/antag_training_sector/dark/crash_after_load/after_load(datum/antag_training_arena/owner)
	CRASH("Учебный сбой после загрузки шаблона")

/datum/antag_training_sector/dark/close_after_load
	id = null

/datum/antag_training_sector/dark/close_after_load/after_load(datum/antag_training_arena/owner)
	owner.begin_cleanup()
	return ..()

/// Остатки в слоте сектора: не космос или объекты.
/datum/unit_test/proc/dirty_sector_slot(datum/antag_training_sector/sector, datum/antag_training_arena/arena)
	var/datum/map_template/template = GLOB.antag_training_sector_templates[sector.map_path]
	var/level = arena.private_level.z_value
	. = list()
	for(var/turf/tile as anything in block(locate(sector.origin_x, sector.origin_y, level), locate(sector.origin_x + template.width - 1, sector.origin_y + template.height - 1, level)))
		if(!isspaceturf(tile))
			. |= "[tile.type]"
		for(var/obj/thing in tile)
			. |= "[thing.type]"

/// Сбой after_load() после загрузки шаблона не оставляет в слоте ни объектов, ни зоны.
/datum/unit_test/antag_training_sector_after_load_crash
	allowed_runtime_patterns = list("Учебный сбой после загрузки шаблона")

/datum/unit_test/antag_training_sector_after_load_crash/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_arena/arena = session.arena
	var/datum/antag_training_sector/dark_sector = arena.sectors["dark"]
	var/datum/antag_training_sector/crashing = new /datum/antag_training_sector/dark/crash_after_load(arena)
	crashing.id = dark_sector.id
	arena.sectors["dark"] = crashing
	var/loaded = crashing.load()
	var/state = crashing.state
	var/list/leftovers = dirty_sector_slot(crashing, arena)
	arena.sectors["dark"] = dark_sector
	qdel(crashing)
	TEST_ASSERT(!loaded, "Упавшая загрузка не отдаёт сектор.")
	TEST_ASSERT_EQUAL(state, ANTAG_TRAINING_SECTOR_UNLOADED, "Упавшая загрузка не оставляет сектор занятым.")
	TEST_ASSERT_NULL(arena.zones["dark"], "Упавший сектор - не зона.")
	TEST_ASSERT(!length(leftovers), "После сбоя в слоте осталось: [leftovers.Join(", ")].")
	TEST_ASSERT(dark_sector.load(), "После сбоя сектор грузится.")

/// Арена, закрытая посреди загрузки сектора, получает пустой слот раньше, чем уровень вернётся в общий пул.
/datum/unit_test/antag_training_sector_close_during_load/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_arena/arena = session.arena
	var/datum/space_level/level = arena.private_level
	var/datum/antag_training_sector/dark_sector = arena.sectors["dark"]
	var/datum/antag_training_sector/closing = new /datum/antag_training_sector/dark/close_after_load(arena)
	closing.id = dark_sector.id
	arena.sectors["dark"] = closing
	qdel(dark_sector)
	var/loaded = closing.load()
	var/list/leftovers = dirty_sector_slot(closing, arena)
	var/level_freed = (level in GLOB.antag_training_free_levels)
	TEST_ASSERT(!loaded, "Сектор закрывающейся арены не загружается.")
	TEST_ASSERT(!level_freed, "Уровень не уходит в пул, пока сектор грузится.")
	TEST_ASSERT(!length(leftovers), "К закрытию арены в слоте осталось: [leftovers.Join(", ")].")
	TEST_ASSERT(wait_for_qdeleted(arena, 1 MINUTES), "Полигон закрывается.")
	TEST_ASSERT(level in GLOB.antag_training_free_levels, "Уровень освобождается после закрытия.")

/// Сброс сектора голосованием перезагружает шаблон и не трогает ядро.
/datum/unit_test/antag_training_sector_reset/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_arena/arena = session.arena
	var/datum/antag_training_sector/sector = arena.sectors["dark"]
	TEST_ASSERT(sector.load(), "Сектор загружается.")
	var/obj/item/pen/sector_item = new(sector.spawn_turf())
	var/obj/item/pen/core_item = new(arena.zones["melee"]["spawn"])
	TEST_ASSERT(arena.request_reset(session, "dark"), "Сброс сектора запрашивается.")
	var/list/budget = new_wait_budget(1 MINUTES, "сектор перезагружен")
	while((arena.resetting || sector.state != ANTAG_TRAINING_SECTOR_READY || !QDELETED(sector_item)) && wait_budget_tick(budget))
		continue
	TEST_ASSERT(!arena.resetting && sector.state == ANTAG_TRAINING_SECTOR_READY && QDELETED(sector_item), "Сектор перезагружается.")
	TEST_ASSERT(!QDELETED(core_item), "Сброс сектора не трогает ядро.")

/// Выгрузка сектора по простою отменяет голосование за его сброс.
/datum/unit_test/antag_training_sector_vote/Run()
	var/datum/antag_training_session/first = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(first.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_session/second = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(second.prepare(), "Второй участник входит.")
	var/datum/antag_training_arena/arena = first.arena
	var/datum/antag_training_sector/sector = arena.sectors["dark"]
	TEST_ASSERT(sector.load(), "Сектор загружается.")
	TEST_ASSERT(arena.request_reset(first, "dark"), "Сброс сектора ждёт второго голоса.")
	sector.last_occupied_at = world.time - ANTAG_TRAINING_SECTOR_IDLE - 1 SECONDS
	sector.check_idle()
	TEST_ASSERT(wait_for_var(sector, "state", ANTAG_TRAINING_SECTOR_UNLOADED, 30 SECONDS), "Пустой сектор выгружается.")
	TEST_ASSERT_NULL(arena.pending_reset_zone, "Выгрузка отменяет голосование за сброс сектора.")
	TEST_ASSERT(!arena.approve_reset(second), "Голос за выгруженный сектор не принимается.")

/// У каждой программы есть раздел и описание для каталога, а сектор программы существует.
/datum/unit_test/antag_training_catalog_programs/Run()
	var/list/sector_ids = list()
	for(var/datum/antag_training_sector/sector_type as anything in subtypesof(/datum/antag_training_sector))
		sector_ids += initial(sector_type.id)
	for(var/datum/antag_training_program/program_type as anything in subtypesof(/datum/antag_training_program))
		if(!antag_training_program_selectable(program_type))
			continue
		TEST_ASSERT(initial(program_type.name), "[program_type]: есть имя.")
		TEST_ASSERT(initial(program_type.category), "[program_type]: есть раздел каталога.")
		TEST_ASSERT(initial(program_type.desc), "[program_type]: есть описание.")
		var/sector_id = initial(program_type.sector)
		TEST_ASSERT(!sector_id || (sector_id in sector_ids), "[program_type]: сектор [sector_id] существует.")

/// Программа с сектором ставит куклу в свой сектор.
/datum/unit_test/antag_training_program_sector/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	session.program.sector = "dark"
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_arena/arena = session.arena
	var/datum/antag_training_sector/sector = arena.sectors["dark"]
	TEST_ASSERT(wait_for_var(sector, "state", ANTAG_TRAINING_SECTOR_READY, 30 SECONDS), "Сектор программы загружается.")
	var/list/budget = new_wait_budget(10 SECONDS, "кукла в секторе программы")
	while(!arena.inside_bounds(get_turf(session.current_body), sector.bounds) && wait_budget_tick(budget))
		continue
	TEST_ASSERT(arena.inside_bounds(get_turf(session.current_body), sector.bounds), "Кукла переходит в сектор программы.")

/// Общий вход создаёт сессию выбранной программы и подключает призрака.
/datum/unit_test/antag_training_catalog_start/Run()
	wait_for_closing_training_arenas()
	var/mob/dead/observer/observer = allocate(/mob/dead/observer, run_loc_floor_bottom_left)
	var/datum/antag_training_session/session = start_antag_training(observer, /datum/antag_training_program/heretic, FALSE)
	TEST_ASSERT_NOTNULL(session, "Вход создаёт сессию.")
	allocated += session
	TEST_ASSERT(IS_HERETIC(session.current_body), "Выбранная программа выдаёт роль.")
	TEST_ASSERT(session.connected, "Призрак подключён.")
	TEST_ASSERT_NULL(start_antag_training(observer, /datum/antag_training_sector/dark, FALSE), "Тип не из программ полигона не запускается.")
	allocated += session.finish()

/obj/effect/antag_training_catalog_probe
	var/list/started

/obj/effect/antag_training_catalog_probe/proc/begin_training(mob/user, program_type, use_character)
	started = list(user, program_type, use_character)

/// Каталог отдаёт разделы программ, «Войти» зовёт вход выбранной программой и закрывает окно; чужой зритель ничего не запускает.
/datum/unit_test/antag_training_catalog_actions/Run()
	var/mob/dead/observer/viewer = allocate(/mob/dead/observer, run_loc_floor_bottom_left)
	var/mob/dead/observer/stranger = allocate(/mob/dead/observer, run_loc_floor_bottom_left)
	var/obj/effect/antag_training_catalog_probe/entry = allocate(/obj/effect/antag_training_catalog_probe, run_loc_floor_bottom_left)
	var/datum/antag_training_catalog/catalog = new(viewer, entry)
	allocated += catalog
	TEST_ASSERT_EQUAL(catalog.ui_status(viewer), UI_INTERACTIVE, "Каталог открыт своему зрителю.")
	TEST_ASSERT_EQUAL(catalog.ui_status(stranger), UI_CLOSE, "Чужому каталог закрыт.")
	var/list/static_data = catalog.ui_static_data(viewer)
	var/list/heretic_entry
	for(var/list/program_entry as anything in static_data["programs"])
		if(program_entry["id"] == "[/datum/antag_training_program/heretic]")
			heretic_entry = program_entry
	TEST_ASSERT_NOTNULL(heretic_entry, "Каталог показывает программу еретика.")
	TEST_ASSERT_EQUAL(heretic_entry["category"], "Культы и магия", "Программа приходит со своим разделом.")
	TEST_ASSERT(heretic_entry["desc"], "Программа приходит с описанием.")
	var/datum/tgui/stranger_ui = allocate(/datum/tgui, stranger, catalog, "AntagTrainingCatalog")
	stranger_ui.status = UI_INTERACTIVE
	catalog.ui_act("start", list("program" = "[/datum/antag_training_program/heretic]", "use_character" = TRUE), stranger_ui)
	TEST_ASSERT_NULL(entry.started, "Чужой зритель не запускает вход.")
	var/datum/tgui/ui = allocate(/datum/tgui, viewer, catalog, "AntagTrainingCatalog")
	ui.status = UI_INTERACTIVE
	catalog.ui_act("start", list("program" = "[/datum/antag_training_program]", "use_character" = TRUE), ui)
	TEST_ASSERT_NULL(entry.started, "Абстрактная программа не запускается.")
	catalog.ui_act("start", list("program" = "[/datum/antag_training_program/heretic]", "use_character" = TRUE), ui)
	TEST_ASSERT_NOTNULL(entry.started, "«Войти» зовёт вход.")
	TEST_ASSERT_EQUAL(entry.started[1], viewer, "Вход получает зрителя каталога.")
	TEST_ASSERT_EQUAL(entry.started[2], /datum/antag_training_program/heretic, "Вход получает тип выбранной программы.")
	TEST_ASSERT_EQUAL(entry.started[3], TRUE, "Вход получает выбор куклы.")
	TEST_ASSERT(QDELETED(catalog), "Вход закрывает каталог.")
	var/datum/antag_training_catalog/orphan = new(viewer, entry)
	allocated += orphan
	qdel(entry)
	TEST_ASSERT_EQUAL(orphan.ui_status(viewer), UI_CLOSE, "Каталог закрывается без входа.")

/// Каждая программа приходит в каталог с иконкой Font Awesome, цветом, сложностью и пунктами «что вы освоите», места в «С чего начать» не повторяются, прогресс берётся из лучших результатов игрока за раунд.
/datum/unit_test/antag_training_catalog_program_cards/Run()
	var/stylesheet = file2text('html/font-awesome/css/all.min.css')
	TEST_ASSERT(length(stylesheet), "Таблица иконок Font Awesome прочитана.")
	var/list/palette = list("red", "orange", "yellow", "olive", "green", "teal", "blue", "violet", "purple", "pink", "brown", "grey")
	var/list/orders = list()
	for(var/datum/antag_training_program/program_type as anything in subtypesof(/datum/antag_training_program))
		if(!antag_training_program_selectable(program_type))
			continue
		var/icon_name = initial(program_type.icon)
		TEST_ASSERT(icon_name && (findtext(stylesheet, ".fa-[icon_name]:") || findtext(stylesheet, ".fa-[icon_name],")), "[program_type]: иконка [icon_name] есть в Font Awesome.")
		TEST_ASSERT(initial(program_type.color) in palette, "[program_type]: цвет [initial(program_type.color)] из палитры tgui.")
		var/difficulty = initial(program_type.difficulty)
		TEST_ASSERT(difficulty >= 1 && difficulty <= 3, "[program_type]: сложность [difficulty] от 1 до 3.")
		var/list/learn = antag_training_program_learn(program_type)
		TEST_ASSERT(length(learn) >= 3 && length(learn) <= 5, "[program_type]: «что вы освоите» - от 3 до 5 пунктов, а не [length(learn)].")
		for(var/item in learn)
			TEST_ASSERT(length(trim(item)), "[program_type]: пустой пункт «что вы освоите».")
		var/order = initial(program_type.order)
		if(order)
			TEST_ASSERT(!(order in orders), "[program_type]: место [order] в «С чего начать» уже занято.")
			orders += order

	var/mob/dead/observer/viewer = allocate(/mob/dead/observer, run_loc_floor_bottom_left)
	viewer.ckey = "unit_test_catalog_cards"
	GLOB.antag_training_exercise_records[viewer.ckey] = list("range_targets" = list("time" = 10, "hints" = 0, "score" = ANTAG_TRAINING_EXERCISE_SCORE_MAX))
	var/obj/effect/antag_training_catalog_probe/entry = allocate(/obj/effect/antag_training_catalog_probe, run_loc_floor_bottom_left)
	var/datum/antag_training_catalog/catalog = new(viewer, entry)
	allocated += catalog
	var/list/static_data = catalog.ui_static_data(viewer)
	GLOB.antag_training_exercise_records -= viewer.ckey
	viewer.key = null
	var/list/cards = list()
	for(var/list/card as anything in static_data["programs"])
		cards[card["id"]] = card
		TEST_ASSERT(card["icon"] && length(card["learn"]) >= 3 && card["difficulty"] && !isnull(card["order"]), "[card["id"]]: карточка с иконкой, пунктами, сложностью и местом.")
		TEST_ASSERT(!isnull(card["exercises_done"]) && !isnull(card["exercises_total"]), "[card["id"]]: карточка с прогрессом упражнений.")
	var/list/free_card = cards["[/datum/antag_training_program/free]"]
	TEST_ASSERT_EQUAL(free_card["exercises_done"], 1, "Лучший результат игрока засчитан в прогресс «Снаряжения и боя».")
	TEST_ASSERT(free_card["exercises_total"] > 1, "У «Снаряжения и боя» есть упражнения ядра.")
	var/list/heretic_card = cards["[/datum/antag_training_program/heretic]"]
	TEST_ASSERT(heretic_card["exercises_total"] >= 1 && !heretic_card["exercises_done"], "Упражнение роли входит в прогресс своей программы, чужой результат - нет.")
	var/list/sector_names = antag_training_sector_names()
	var/list/revenant_ids = antag_training_program_exercises(/datum/antag_training_program/creature/revenant, sector_names)
	var/list/bloodsucker_ids = antag_training_program_exercises(/datum/antag_training_program/antag/bloodsucker, sector_names)
	var/list/demon_ids = antag_training_program_exercises(/datum/antag_training_program/creature/slaughter, sector_names)
	for(var/exercise_id in list("dark_find", "dark_ambush"))
		TEST_ASSERT(!(exercise_id in revenant_ids), "Бесплотный ревенант не касается манекена и не сбивает цель: [exercise_id] не в его счёте.")
		TEST_ASSERT(exercise_id in bloodsucker_ids, "Кровосос проходит [exercise_id] своего сектора.")
		TEST_ASSERT(exercise_id in demon_ids, "Демон во плоти натыкается на манекен и валит цель: [exercise_id] в его счёте.")
	for(var/exercise_id in revenant_ids)
		var/datum/antag_training_exercise/exercise = GLOB.antag_training_exercises[exercise_id]
		TEST_ASSERT(!istype(exercise, /datum/antag_training_exercise/drill), "У ревенанта в счёте нет упражнений с реквизитом: [exercise_id].")
	TEST_ASSERT_EQUAL(cards["[/datum/antag_training_program/creature/revenant]"]["exercises_total"], length(revenant_ids), "Карточка ревенанта считает только посильные упражнения.")
	TEST_ASSERT_EQUAL(cards["[/datum/antag_training_program/antag/bloodsucker]"]["exercises_total"], length(bloodsucker_ids), "Карточка кровососа считает упражнения тёмного сектора.")
	TEST_ASSERT(!("lab_patient" in antag_training_program_exercises(/datum/antag_training_program/free, sector_names, /mob/living/silicon/robot/training)), "Киборгу «Снаряжения и боя» не засчитаны упражнения для рук человека.")
	var/list/mechanics = static_data["mechanics"]
	TEST_ASSERT_EQUAL(mechanics["program"], "[/datum/antag_training_program/free]", "Механики проходят программой «Снаряжение и бой».")
	TEST_ASSERT(mechanics["exercises_total"] > 0 && !mechanics["exercises_done"], "Шаг механик считает упражнения секторов механик.")
	TEST_ASSERT(mechanics["order"] && !(mechanics["order"] in orders), "Механики занимают своё место в «С чего начать».")

/// Зоны и сектора в пульте показывают прогресс упражнений участника, стенд открывает пульт на вкладке упражнений.
/datum/unit_test/antag_training_console_exercise_progress/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/mob/living/carbon/human/user = session.current_body
	user.a_intent = INTENT_HELP
	var/datum/tgui/ui = allocate(/datum/tgui, user, session, "AntagTraining")
	antag_training_console_act(session, ui, "move", list("zone" = "melee"))
	var/list/melee = antag_training_zone_entry(session, "melee")
	TEST_ASSERT(melee["exercises_total"] > 0 && melee["exercises_done"] == 0, "До прохождения в ближнем бою ничего не пройдено.")
	antag_training_console_act(session, ui, "exercise_start", list("id" = "unit_test_body"))
	var/turf/next = antag_training_free_step(user)
	TEST_ASSERT_NOTNULL(next, "Есть куда шагнуть.")
	user.Move(next, get_dir(user, next))
	TEST_ASSERT(session.exercise_run?.success, "Упражнение пройдено.")
	var/list/after = antag_training_zone_entry(session, "melee")
	TEST_ASSERT_EQUAL(after["exercises_done"], 1, "Пройденное упражнение засчитано зоне.")
	TEST_ASSERT_EQUAL(after["exercises_total"], melee["exercises_total"], "Число упражнений зоны не меняется.")
	var/list/dark = antag_training_sector_entry(session, "dark")
	TEST_ASSERT(dark["exercises_total"] >= 2 && !dark["exercises_done"], "Незагруженный сектор показывает свои упражнения без чужих результатов.")
	TEST_ASSERT(antag_training_zone_entry(session, "range")["practice"] >= 1, "Тир показывает практику без оценки, доступную роли.")
	TEST_ASSERT_EQUAL(antag_training_zone_entry(session, "melee")["practice"], 0, "В ближнем бою практик нет.")
	var/list/static_data = session.ui_static_data(user)
	TEST_ASSERT_NULL(static_data["start_tab"], "Обычное открытие пульта - с первой вкладки.")
	var/list/first_card = static_data["programs"][1]
	TEST_ASSERT(first_card["icon"] && first_card["difficulty"], "Список программ пульта приходит с иконками и сложностью.")
	var/obj/structure/sign/antag_training_board/board = antag_training_boards_in(session.arena, session.arena.zones["melee"]["bounds"])[1]
	board.attack_hand(user)
	static_data = session.ui_static_data(user)
	TEST_ASSERT_EQUAL(static_data["start_tab"], "exercises", "Стенд открывает пульт на вкладке упражнений.")
	static_data = session.ui_static_data(user)
	TEST_ASSERT_NULL(static_data["start_tab"], "Следующее открытие пульта - снова с первой вкладки.")

/datum/unit_test/proc/antag_training_sector_entry(datum/antag_training_session/session, sector_id)
	var/list/data = session.ui_data(session.current_body)
	for(var/list/entry as anything in data["sectors"])
		if(entry["id"] == sector_id)
			return entry

/datum/unit_test/proc/antag_training_zone_entry(datum/antag_training_session/session, zone_id)
	var/list/data = session.ui_data(session.current_body)
	for(var/list/entry as anything in data["zones"])
		if(entry["id"] == zone_id)
			return entry

/datum/unit_test/proc/antag_training_console_act(datum/antag_training_session/session, datum/tgui/ui, action, list/params)
	session.next_action_at = 0
	session.arena.next_spawn_at = 0
	usr = session.current_body
	session.ui_act(action, params, ui)
	usr = null

/// Переход в незагруженный сектор через пульт загружает его и переносит участника.
/datum/unit_test/antag_training_sector_enter/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_arena/arena = session.arena
	var/datum/antag_training_sector/sector = arena.sectors["dark"]
	var/list/static_data = session.ui_static_data(session.current_body)
	TEST_ASSERT_EQUAL(static_data["sector_idle_minutes"], ANTAG_TRAINING_SECTOR_IDLE / (1 MINUTES), "Пульт берёт срок простоя из настройки.")
	var/list/dark_entry = antag_training_sector_entry(session, "dark")
	TEST_ASSERT_EQUAL(dark_entry?["state"], "unloaded", "Пульт показывает незагруженный сектор.")
	TEST_ASSERT_EQUAL(dark_entry["name"], sector.name, "Пульт показывает имя сектора.")
	TEST_ASSERT(!dark_entry["current"] && !dark_entry["members"], "Незагруженный сектор пуст.")
	var/datum/tgui/ui = allocate(/datum/tgui, session.current_body, session, "AntagTraining")
	antag_training_console_act(session, ui, "sector_enter", list("id" = "dark"))
	var/list/budget = new_wait_budget(30 SECONDS, "участник в секторе")
	while(!(sector.bounds && arena.inside_bounds(get_turf(session.current_body), sector.bounds)) && wait_budget_tick(budget))
		continue
	TEST_ASSERT(sector.bounds && arena.inside_bounds(get_turf(session.current_body), sector.bounds), "Участник в секторе.")
	dark_entry = antag_training_sector_entry(session, "dark")
	TEST_ASSERT_EQUAL(dark_entry["state"], "ready", "Пульт показывает готовый сектор.")
	TEST_ASSERT_EQUAL(dark_entry["members"], 1, "Пульт считает участников сектора.")
	TEST_ASSERT(dark_entry["current"], "Пульт отмечает сектор участника.")

/// Неизвестный сектор в пульте оставляет участника на месте и объясняет отказ.
/datum/unit_test/antag_training_sector_enter_failed/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/turf/start = get_turf(session.current_body)
	var/datum/tgui/ui = allocate(/datum/tgui, session.current_body, session, "AntagTraining")
	antag_training_console_act(session, ui, "sector_enter", list("id" = "missing"))
	var/list/budget = new_wait_budget(5 SECONDS, "сообщение об отказе")
	while(!session.last_feedback && wait_budget_tick(budget))
		continue
	var/list/data = session.ui_data(session.current_body)
	TEST_ASSERT(istext(data["last_feedback"]) && findtext(data["last_feedback"], "не удалось загрузить"), "Пульт сообщает об отказе.")
	TEST_ASSERT_EQUAL(get_turf(session.current_body), start, "Участник остаётся на месте.")

/// Если за время загрузки сектора тело сменилось, пульт не переносит новое тело и не пишет об отказе.
/datum/unit_test/antag_training_sector_enter_body_changed/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_sector/sector = session.arena.sectors["dark"]
	var/datum/tgui/ui = allocate(/datum/tgui, session.current_body, session, "AntagTraining")
	sector.state = ANTAG_TRAINING_SECTOR_LOADING
	antag_training_console_act(session, ui, "sector_enter", list("id" = "dark"))
	var/mob/living/old_body = session.current_body
	antag_training_console_act(session, ui, "restart", list("program" = "[/datum/antag_training_program/free]"))
	sector.state = ANTAG_TRAINING_SECTOR_UNLOADED
	TEST_ASSERT(session.current_body && session.current_body != old_body, "Смена персонажа даёт новое тело.")
	TEST_ASSERT(wait_for_var(sector, "state", ANTAG_TRAINING_SECTOR_READY, 30 SECONDS), "Сектор загружается.")
	TEST_ASSERT(!session.arena.inside_bounds(get_turf(session.current_body), sector.bounds), "Новое тело остаётся на месте.")
	TEST_ASSERT_NULL(session.last_feedback, "Готовый сектор - не отказ загрузки.")

/// Пульт отбрасывает нетекстовые id, зоны и повреждения: участник, сброс и цели не меняются.
/datum/unit_test/antag_training_console_params/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_arena/arena = session.arena
	var/turf/start = get_turf(session.current_body)
	var/datum/tgui/ui = allocate(/datum/tgui, session.current_body, session, "AntagTraining")
	for(var/action in list("sector_enter", "kit"))
		antag_training_console_act(session, ui, action, list("id" = 1))
	TEST_ASSERT_EQUAL(get_turf(session.current_body), start, "Нетекстовый id не переносит участника.")
	TEST_ASSERT_EQUAL(arena.supply_count, 0, "Нетекстовый id не выдаёт комплект.")
	for(var/action in list("move", "reset_zone", "spawn"))
		antag_training_console_act(session, ui, action, list("id" = "human", "zone" = 1))
	TEST_ASSERT_EQUAL(get_turf(session.current_body), start, "Нетекстовая зона не переносит участника.")
	TEST_ASSERT_NULL(arena.pending_reset_zone, "Нетекстовая зона не запускает сброс.")
	TEST_ASSERT(!length(arena.targets), "Нетекстовая зона не создаёт цель.")
	antag_training_console_act(session, ui, "spawn", list("id" = "human", "zone" = "pve"))
	TEST_ASSERT_EQUAL(length(arena.targets), 1, "Текстовая зона создаёт цель.")
	var/mob/living/target = arena.targets[1]
	antag_training_console_act(session, ui, "target_injure", list("id" = REF(target), "injury" = 1))
	TEST_ASSERT_EQUAL(target.getBruteLoss(), 0, "Нетекстовое повреждение не ранит цель.")
	antag_training_console_act(session, ui, "target_injure", list("id" = REF(target), "injury" = "brute"))
	TEST_ASSERT(target.getBruteLoss() > 0, "Текстовое повреждение ранит цель.")

/datum/unit_test/proc/allocate_pod_visitor(obj/machinery/antag_training_pod/pod)
	var/mob/living/carbon/human/visitor = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	visitor.mind_initialize()
	allocated += visitor.mind
	pod.close_machine(visitor)
	return visitor

/// Посетитель тренируется из капсулы: тело ждёт в ней и не рассыпается, капсула заперта, выход будит игрока в теле.
/datum/unit_test/antag_training_cafe_pod/Run()
	wait_for_closing_training_arenas()
	var/obj/machinery/antag_training_pod/pod = allocate(/obj/machinery/antag_training_pod, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/visitor = allocate_pod_visitor(pod)
	TEST_ASSERT_EQUAL(pod.occupant, visitor, "Посетитель ложится в капсулу.")
	var/datum/antag_training_session/session = start_antag_training(visitor, /datum/antag_training_program/free, FALSE, pod)
	TEST_ASSERT_NOTNULL(session, "Посетитель подключается из капсулы.")
	allocated += session
	TEST_ASSERT(session in pod.sessions, "Капсула держит сеанс.")
	TEST_ASSERT(HAS_TRAIT(visitor, TRAIT_TRAINING_DREAMER) && (visitor.status_flags & GODMODE), "Тело в капсуле помечено и неуязвимо.")
	TEST_ASSERT_EQUAL(session.exit_action.name, "Вернуться в тело", "Кнопка выхода ведёт в тело.")
	session.current_body.key = "unit_test_training_dreamer"
	var/mob/living/carbon/human/control = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	visitor.AddElement(/datum/element/dusts_on_catatonia)
	control.AddElement(/datum/element/dusts_on_catatonia)
	TEST_ASSERT(wait_for_qdeleted(control, 10 SECONDS), "Пустое тело вне капсулы рассыпается как раньше.")
	TEST_ASSERT(!QDELETED(visitor) && visitor.stat != DEAD, "Тело в капсуле не рассыпается.")
	pod.open_machine()
	pod.container_resist(visitor)
	pod.relaymove(visitor, NORTH)
	TEST_ASSERT_EQUAL(visitor.loc, pod, "Спящий не выходит из капсулы, пока идёт сеанс.")
	var/mob/returned = session.finish()
	TEST_ASSERT_EQUAL(returned, visitor, "Выход возвращает в тело в капсуле.")
	TEST_ASSERT_EQUAL(visitor.key, "unit_test_training_dreamer", "Игрок просыпается в теле.")
	visitor.RemoveElement(/datum/element/dusts_on_catatonia)
	visitor.key = null
	TEST_ASSERT(!HAS_TRAIT(visitor, TRAIT_TRAINING_DREAMER) && !(visitor.status_flags & GODMODE), "Защита капсулы снята.")
	TEST_ASSERT(pod.state_open && !pod.occupant && !length(pod.sessions), "Капсула открывается.")
	TEST_ASSERT_EQUAL(visitor.loc, run_loc_floor_bottom_left, "Тело выходит из капсулы.")

/// Потеря тела в капсуле возвращает игрока призраком к капсуле и освобождает её.
/datum/unit_test/antag_training_cafe_pod_lost_body/Run()
	wait_for_closing_training_arenas()
	var/obj/machinery/antag_training_pod/pod = allocate(/obj/machinery/antag_training_pod, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/visitor = allocate_pod_visitor(pod)
	var/datum/antag_training_session/session = start_antag_training(visitor, /datum/antag_training_program/free, FALSE, pod)
	TEST_ASSERT_NOTNULL(session, "Посетитель подключается из капсулы.")
	allocated += session
	qdel(visitor)
	var/mob/dead/observer/returned = session.finish()
	allocated += returned
	TEST_ASSERT(isobserver(returned), "Без тела игрок становится призраком.")
	TEST_ASSERT_EQUAL(get_turf(returned), get_turf(pod), "Призрак появляется у капсулы.")
	TEST_ASSERT(!returned.can_reenter_corpse, "Призрак не возвращается в потерянное тело.")
	TEST_ASSERT(pod.state_open && !length(pod.sessions), "Капсула освобождается.")

/// Капсула создаётся и удаляется; удаление во время сеанса будит игрока в теле рядом с ней.
/datum/unit_test/antag_training_cafe_pod_destroyed/Run()
	var/obj/machinery/antag_training_pod/empty = allocate(/obj/machinery/antag_training_pod, run_loc_floor_bottom_left)
	TEST_ASSERT(empty.state_open && empty.icon_state == "sleeper-open", "Новая капсула открыта.")
	qdel(empty)
	TEST_ASSERT(QDELETED(empty), "Пустая капсула удаляется.")
	wait_for_closing_training_arenas()
	var/obj/machinery/antag_training_pod/pod = allocate(/obj/machinery/antag_training_pod, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/visitor = allocate_pod_visitor(pod)
	var/datum/antag_training_session/session = start_antag_training(visitor, /datum/antag_training_program/free, FALSE, pod)
	TEST_ASSERT_NOTNULL(session, "Посетитель подключается из капсулы.")
	allocated += session
	session.current_body.key = "unit_test_training_pod_lost"
	qdel(pod)
	TEST_ASSERT(QDELETED(session), "Сеанс закрывается вместе с капсулой.")
	TEST_ASSERT_EQUAL(visitor.key, "unit_test_training_pod_lost", "Игрок просыпается в теле.")
	visitor.key = null
	TEST_ASSERT_EQUAL(visitor.loc, run_loc_floor_bottom_left, "Тело выпадает из удалённой капсулы.")
	TEST_ASSERT(!HAS_TRAIT(visitor, TRAIT_TRAINING_DREAMER) && !(visitor.status_flags & GODMODE), "Защита капсулы снята.")

/// Закрытый без входа каталог и отказ во входе выпускают посетителя из капсулы.
/datum/unit_test/antag_training_cafe_pod_catalog/Run()
	var/obj/machinery/antag_training_pod/pod = allocate(/obj/machinery/antag_training_pod, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/visitor = allocate_pod_visitor(pod)
	var/datum/antag_training_catalog/catalog = new(visitor, pod)
	allocated += catalog
	catalog.ui_close(visitor)
	TEST_ASSERT(QDELETED(catalog), "Каталог закрывается.")
	TEST_ASSERT(pod.state_open && !pod.occupant, "Закрытый без входа каталог открывает капсулу.")
	pod.close_machine(visitor)
	catalog = new(visitor, pod)
	allocated += catalog
	var/datum/tgui/ui = allocate(/datum/tgui, visitor, catalog, "AntagTrainingCatalog")
	ui.status = UI_INTERACTIVE
	catalog.ui_act("start", list("program" = "[/datum/antag_training_program/free]", "use_character" = FALSE), ui)
	TEST_ASSERT(QDELETED(catalog), "«Войти» закрывает каталог.")
	TEST_ASSERT(pod.state_open && !pod.occupant && !length(pod.sessions), "Без права входа сеанс не начинается и капсула открывается.")

/datum/unit_test/antag_training_cafe_pod_left
	var/datum/antag_training_session/started
	var/start_done = FALSE

/datum/unit_test/antag_training_cafe_pod_left/proc/start_from_pod(mob/living/user, obj/machinery/antag_training_pod/pod)
	started = start_antag_training(user, /datum/antag_training_program/free, FALSE, pod)
	start_done = TRUE

/// Вышедший из капсулы во время подготовки полигона не подключается, капсула его не держит.
/datum/unit_test/antag_training_cafe_pod_left/Run()
	wait_for_closing_training_arenas()
	var/obj/machinery/antag_training_pod/pod = allocate(/obj/machinery/antag_training_pod, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/visitor = allocate_pod_visitor(pod)
	INVOKE_ASYNC(src, PROC_REF(start_from_pod), visitor, pod)
	TEST_ASSERT(!start_done, "Полигон готовится несколько тиков.")
	pod.container_resist(visitor)
	TEST_ASSERT_EQUAL(visitor.loc, run_loc_floor_bottom_left, "До начала сеанса из капсулы можно выйти.")
	TEST_ASSERT(wait_for_var(src, "start_done", TRUE, 1 MINUTES), "Подготовка завершается.")
	if(started)
		allocated += started
	TEST_ASSERT_NULL(started, "Вышедший из капсулы не подключается.")
	TEST_ASSERT(!length(pod.sessions) && !HAS_TRAIT(visitor, TRAIT_TRAINING_DREAMER), "Капсула не держит вышедшего.")

/// Автокрио не забирает тело, которое ждёт игрока в капсуле, даже после долгого SSD.
/datum/unit_test/antag_training_cafe_pod_autocryo/Run()
	wait_for_closing_training_arenas()
	var/obj/machinery/antag_training_pod/pod = allocate(/obj/machinery/antag_training_pod, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/visitor = allocate_pod_visitor(pod)
	var/datum/antag_training_session/session = start_antag_training(visitor, /datum/antag_training_program/free, FALSE, pod)
	TEST_ASSERT_NOTNULL(session, "Посетитель подключается из капсулы.")
	allocated += session
	var/list/prev_config = auto_cryo_test_enable_config()
	var/list/prev_ssd_list = GLOB.ssd_mob_list.Copy()
	visitor.lastclienttime = world.time - CONFIG_GET(number/autocryo_time_trigger) - 1 SECONDS
	GLOB.ssd_mob_list |= visitor
	SSauto_cryo.currentrun_cryo = list()
	SSauto_cryo.next_scan = 0
	SSauto_cryo.fire()
	SSauto_cryo.fire()
	var/kept = !QDELETED(visitor) && visitor.loc == pod
	GLOB.ssd_mob_list = prev_ssd_list
	SSauto_cryo.currentrun_cryo = list()
	auto_cryo_test_restore_config(prev_config)
	TEST_ASSERT(kept, "Тело в капсуле не уходит в автокрио.")

/// Тело, вынутое из капсулы во время сеанса, всё равно принимает игрока и не рассыпается.
/datum/unit_test/antag_training_cafe_pod_moved_body/Run()
	wait_for_closing_training_arenas()
	var/obj/machinery/antag_training_pod/pod = allocate(/obj/machinery/antag_training_pod, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/visitor = allocate_pod_visitor(pod)
	var/datum/antag_training_session/session = start_antag_training(visitor, /datum/antag_training_program/free, FALSE, pod)
	TEST_ASSERT_NOTNULL(session, "Посетитель подключается из капсулы.")
	allocated += session
	session.current_body.key = "unit_test_training_moved"
	visitor.forceMove(run_loc_floor_top_right)
	visitor.AddElement(/datum/element/dusts_on_catatonia)
	var/mob/returned = session.finish()
	TEST_ASSERT_EQUAL(returned, visitor, "Игрок возвращается в вынутое из капсулы тело.")
	TEST_ASSERT_EQUAL(visitor.key, "unit_test_training_moved", "Ключ игрока в теле.")
	TEST_ASSERT(pod.state_open && !length(pod.sessions), "Капсула освобождается.")
	TEST_ASSERT(!HAS_TRAIT(visitor, TRAIT_TRAINING_DREAMER) && !(visitor.status_flags & GODMODE), "Защита капсулы снята.")
	var/mob/living/carbon/human/control = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	control.AddElement(/datum/element/dusts_on_catatonia)
	TEST_ASSERT(wait_for_qdeleted(control, 10 SECONDS), "Тик элемента прошёл.")
	TEST_ASSERT(!QDELETED(visitor) && visitor.stat != DEAD, "Тело с вернувшимся игроком не рассыпается.")
	visitor.RemoveElement(/datum/element/dusts_on_catatonia)
	visitor.key = null

/// В Гост-Кафе на карте ЦК ровно две свободные капсулы полигона рядом со спавнерами посетителей.
/datum/unit_test/antag_training_cafe_pods_on_centcom/Run()
	var/list/cafe_pods = list()
	for(var/obj/machinery/antag_training_pod/pod in GLOB.machines)
		var/area/pod_area = get_area(pod)
		if(pod_area?.type == /area/centcom/holding)
			cafe_pods += pod
	TEST_ASSERT_EQUAL(length(cafe_pods), 2, "В Гост-Кафе ровно две капсулы полигона.")
	for(var/obj/machinery/antag_training_pod/pod as anything in cafe_pods)
		var/turf/pod_turf = pod.loc
		TEST_ASSERT(isopenturf(pod_turf) && !pod_turf.is_blocked_turf(exclude_mobs = TRUE), "Капсула [AREACOORD(pod)] на свободном полу.")
		TEST_ASSERT(pod.state_open && !pod.occupant && !length(pod.sessions), "Капсула [AREACOORD(pod)] открыта и пуста.")
		TEST_ASSERT(locate(/obj/effect/mob_spawn/human/ghostcafe) in range(5, pod), "Капсула [AREACOORD(pod)] рядом со спавнерами посетителей.")

/datum/unit_test/proc/find_training_player(player_key, mob_type)
	for(var/mob/candidate as anything in GLOB.mob_list)
		if(istype(candidate, mob_type) && candidate.ckey == ckey(player_key))
			return candidate

/// Отвечает на открытый вопрос выхода так же, как кнопка окна.
/datum/unit_test/proc/answer_training_exit(datum/antag_training_session/session, choice)
	var/datum/tgui_alert/prompt = session.exit_prompt
	if(!prompt)
		return FALSE
	var/datum/tgui/ui = allocate(/datum/tgui, session.current_body, prompt, "AlertModal")
	ui.status = UI_INTERACTIVE
	prompt.ui_act("choose", list("choice" = choice), ui)
	return TRUE

/// Без клиента окно не открывается, поэтому тестовый вопрос регистрирует свой интерфейс открытым сам.
/datum/tgui_alert/async/antag_training_exit/unit_test

/datum/tgui_alert/async/antag_training_exit/unit_test/ui_interact(mob/user, datum/tgui/ui)
	SStgui.on_open(new /datum/tgui(user, src, "AlertModal"))

/datum/unit_test/antag_training_exit_to_cafe
	var/list/hidden_spawners = list()

/datum/unit_test/antag_training_exit_to_cafe/Destroy()
	GLOB.poi_list |= hidden_spawners
	hidden_spawners.Cut()
	return ..()

/// Выбор «В Гост-Кафе» делает вошедшего призраком посетителем кафе с ролью кафе; без ключа или без открытого спавнера игрок остаётся призраком.
/datum/unit_test/antag_training_exit_to_cafe/Run()
	for(var/obj/effect/mob_spawn/human/ghostcafe/other in GLOB.poi_list)
		hidden_spawners += other
	GLOB.poi_list -= hidden_spawners
	var/mob/dead/observer/probe = allocate(/mob/dead/observer, run_loc_floor_bottom_left)
	TEST_ASSERT(!antag_training_send_to_cafe(probe), "Призрак без ключа в кафе не уходит.")
	probe.key = "unit_test_training_cafe_probe"
	var/no_spawner_refused = !antag_training_send_to_cafe(probe)
	var/obj/effect/mob_spawn/human/ghostcafe/unit_test/spawner = allocate(/obj/effect/mob_spawn/human/ghostcafe/unit_test, run_loc_floor_top_right)
	spawner.ghost_usable = FALSE
	var/closed_spawner_refused = !antag_training_send_to_cafe(probe)
	spawner.ghost_usable = TRUE
	probe.key = null
	TEST_ASSERT(no_spawner_refused, "Без спавнера кафе игрок остаётся призраком.")
	TEST_ASSERT(closed_spawner_refused, "Закрытый для призраков спавнер кафе игрока не принимает.")
	wait_for_closing_training_arenas()
	var/mob/dead/observer/observer = allocate(/mob/dead/observer, run_loc_floor_bottom_left)
	var/datum/antag_training_session/session = start_antag_training(observer, /datum/antag_training_program/free, FALSE)
	TEST_ASSERT_NOTNULL(session, "Призрак подключается.")
	allocated += session
	session.exit_prompt_type = /datum/tgui_alert/async/antag_training_exit/unit_test
	session.current_body.key = "unit_test_training_cafe"
	TEST_ASSERT(session.exit_action.Trigger(), "Кнопка выхода нажимается.")
	TEST_ASSERT(answer_training_exit(session, ANTAG_TRAINING_EXIT_CAFE), "Кнопка выхода спрашивает, куда вернуться.")
	var/mob/living/carbon/human/visitor = find_training_player("unit_test_training_cafe", /mob/living/carbon/human)
	var/list/budget = new_wait_budget(5 SECONDS, "посетитель кафе")
	while(!visitor && wait_budget_tick(budget))
		visitor = find_training_player("unit_test_training_cafe", /mob/living/carbon/human)
	if(visitor)
		allocated += visitor
		allocated += visitor.mind
	TEST_ASSERT(QDELETED(session), "Выбор кафе закрывает сеанс.")
	TEST_ASSERT_NOTNULL(visitor, "Призрак становится посетителем кафе.")
	TEST_ASSERT_EQUAL(get_turf(visitor), get_turf(spawner), "Посетитель появляется у спавнера кафе.")
	TEST_ASSERT(visitor.mind?.has_antag_datum(/datum/antagonist/ghost_role/ghost_cafe), "Посетитель получает роль кафе.")
	visitor.key = null

/// Вошедший призраком выбирает выход в окне: неоткрывшееся окно не блокирует выход, повторное нажатие и пульт второго окна не открывают, «Остаться» и закрытое окно сеанс не закрывают, «В призрака» возвращает призраком; вошедшего из капсулы кнопка будит в теле без вопроса.
/datum/unit_test/antag_training_exit_button/Run()
	wait_for_closing_training_arenas()
	var/mob/dead/observer/observer = allocate(/mob/dead/observer, run_loc_floor_bottom_left)
	var/datum/antag_training_session/ghost = start_antag_training(observer, /datum/antag_training_program/free, FALSE)
	TEST_ASSERT_NOTNULL(ghost, "Призрак подключается.")
	allocated += ghost
	TEST_ASSERT_EQUAL(ghost.exit_action.name, "Выйти с полигона", "Кнопка вошедшего призраком ведёт с полигона.")
	var/list/ghost_data = ghost.ui_data(ghost.current_body)
	TEST_ASSERT(!ghost_data["return_to_body"], "Пульт вошедшего призраком предлагает выбор выхода.")
	TEST_ASSERT(ghost.exit_action.Trigger(), "Кнопка выхода нажимается.")
	TEST_ASSERT(!ghost.exit_prompt && !ghost.finished, "Неоткрывшееся окно не оставляет вопрос висеть и не закрывает сеанс.")
	ghost.exit_prompt_type = /datum/tgui_alert/async/antag_training_exit/unit_test
	TEST_ASSERT(ghost.exit_action.Trigger(), "Кнопка выхода нажимается снова.")
	var/datum/tgui_alert/prompt = ghost.exit_prompt
	TEST_ASSERT_NOTNULL(prompt, "Кнопка открывает вопрос, куда выйти.")
	TEST_ASSERT_EQUAL(prompt.buttons.Join("|"), "[ANTAG_TRAINING_EXIT_GHOST]|[ANTAG_TRAINING_EXIT_CAFE]|[ANTAG_TRAINING_EXIT_STAY]", "Вопрос предлагает призрака, кафе или остаться.")
	ghost.exit_action.Trigger()
	var/datum/tgui/console = allocate(/datum/tgui, ghost.current_body, ghost, "AntagTraining")
	antag_training_console_act(ghost, console, "exit", list())
	TEST_ASSERT_EQUAL(ghost.exit_prompt, prompt, "Повторное нажатие и пульт не открывают второй вопрос.")
	TEST_ASSERT(answer_training_exit(ghost, ANTAG_TRAINING_EXIT_STAY), "Вопрос принимает ответ.")
	TEST_ASSERT(!ghost.finished && !ghost.exit_prompt, "«Остаться» не закрывает сеанс и снимает вопрос.")
	ghost.exit_action.Trigger()
	prompt = ghost.exit_prompt
	TEST_ASSERT_NOTNULL(prompt, "После ответа кнопка снова спрашивает.")
	prompt.ui_close(ghost.current_body)
	TEST_ASSERT(!ghost.finished && !ghost.exit_prompt, "Закрытое окно не закрывает сеанс и снимает вопрос.")
	ghost.current_body.key = "unit_test_training_exit_ghost"
	antag_training_console_act(ghost, console, "exit", list())
	TEST_ASSERT(answer_training_exit(ghost, ANTAG_TRAINING_EXIT_GHOST), "Пульт спрашивает, куда выйти.")
	var/closed = wait_for_qdeleted(ghost, 2 SECONDS)
	var/mob/dead/observer/returned = find_training_player("unit_test_training_exit_ghost", /mob/dead/observer)
	if(returned)
		allocated += returned
		returned.key = null
	TEST_ASSERT(closed, "«В призрака» закрывает сеанс.")
	TEST_ASSERT_NOTNULL(returned, "Игрок возвращается призраком.")
	wait_for_closing_training_arenas()
	var/obj/machinery/antag_training_pod/pod = allocate(/obj/machinery/antag_training_pod, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/visitor = allocate_pod_visitor(pod)
	var/datum/antag_training_session/dreamer = start_antag_training(visitor, /datum/antag_training_program/free, FALSE, pod)
	TEST_ASSERT_NOTNULL(dreamer, "Посетитель подключается из капсулы.")
	allocated += dreamer
	var/list/dreamer_data = dreamer.ui_data(dreamer.current_body)
	TEST_ASSERT(dreamer_data["return_to_body"], "Пульт вошедшего из капсулы ведёт в тело.")
	dreamer.current_body.key = "unit_test_training_exit_button"
	TEST_ASSERT(dreamer.exit_action.Trigger(), "Кнопка выхода нажимается.")
	TEST_ASSERT(wait_for_qdeleted(dreamer, 2 SECONDS), "Вошедший из капсулы выходит без вопроса.")
	TEST_ASSERT_EQUAL(visitor.key, "unit_test_training_exit_button", "Игрок просыпается в теле.")
	visitor.key = null

/// Вопрос выхода, открытый к концу сеанса, закрывается вместе с ним и не держит ни сеанс, ни куклу.
/datum/unit_test/antag_training_exit_prompt_closed/Run()
	wait_for_closing_training_arenas()
	var/mob/dead/observer/observer = allocate(/mob/dead/observer, run_loc_floor_bottom_left)
	var/datum/antag_training_session/session = start_antag_training(observer, /datum/antag_training_program/free, FALSE)
	TEST_ASSERT_NOTNULL(session, "Призрак подключается.")
	allocated += session
	session.exit_prompt_type = /datum/tgui_alert/async/antag_training_exit/unit_test
	TEST_ASSERT(session.exit_action.Trigger(), "Кнопка выхода нажимается.")
	var/datum/tgui_alert/async/antag_training_exit/prompt = session.exit_prompt
	TEST_ASSERT_NOTNULL(prompt, "Кнопка открывает вопрос.")
	var/datum/weakref/answer_session = prompt.callback.arguments[1]
	var/datum/weakref/answer_body = prompt.callback.arguments[2]
	TEST_ASSERT(istype(answer_session) && istype(answer_body), "Ответ найдёт сеанс и куклу по слабым ссылкам.")
	session.disconnected_at = world.time - ANTAG_TRAINING_DISCONNECT_GRACE - 1
	session.process()
	TEST_ASSERT(QDELETED(session), "Отключение закрывает сеанс.")
	TEST_ASSERT(QDELETED(prompt), "Вопрос закрывается вместе с сеансом.")

/// Сеанс, закрытый по отключению, передаёт телу в капсуле и призраку настоящее время отключения, а не время входа.
/datum/unit_test/antag_training_disconnect_time/Run()
	wait_for_closing_training_arenas()
	var/obj/machinery/antag_training_pod/pod = allocate(/obj/machinery/antag_training_pod, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/visitor = allocate_pod_visitor(pod)
	var/datum/antag_training_session/dreamer = start_antag_training(visitor, /datum/antag_training_program/free, FALSE, pod)
	TEST_ASSERT_NOTNULL(dreamer, "Посетитель подключается из капсулы.")
	allocated += dreamer
	var/mob/dead/observer/observer = allocate(/mob/dead/observer, run_loc_floor_bottom_left)
	var/datum/antag_training_session/ghost = start_antag_training(observer, /datum/antag_training_program/free, FALSE)
	TEST_ASSERT_NOTNULL(ghost, "Призрак подключается.")
	allocated += ghost
	visitor.lastclienttime = world.time - 1 HOURS
	dreamer.current_body.key = "unit_test_training_dreamer_left"
	dreamer.avatar.lastclienttime = world.time - 2 SECONDS
	var/dreamer_left_at = dreamer.avatar.lastclienttime
	ghost.current_body.key = "unit_test_training_ghost_left"
	ghost.avatar.lastclienttime = world.time - 3 SECONDS
	var/ghost_left_at = ghost.avatar.lastclienttime
	for(var/datum/antag_training_session/session as anything in list(dreamer, ghost))
		session.disconnected_at = world.time - ANTAG_TRAINING_DISCONNECT_GRACE - 1
		session.process()
	var/mob/dead/observer/returned = find_training_player("unit_test_training_ghost_left", /mob/dead/observer)
	if(returned)
		allocated += returned
		returned.key = null
	TEST_ASSERT(QDELETED(dreamer) && QDELETED(ghost), "Истёкшее отключение закрывает сеансы.")
	TEST_ASSERT_EQUAL(visitor.key, "unit_test_training_dreamer_left", "Игрок возвращается в тело в капсуле.")
	visitor.key = null
	TEST_ASSERT_EQUAL(visitor.lastclienttime, dreamer_left_at, "Тело в капсуле получает время отключения от куклы.")
	TEST_ASSERT_NOTNULL(returned, "Вошедший призраком возвращается призраком.")
	TEST_ASSERT_EQUAL(returned.lastclienttime, ghost_left_at, "Призрак получает время отключения от куклы.")

/// Конец раунда закрывает все сеансы: посетитель кафе просыпается в капсуле, вошедший призраком становится призраком.
/datum/unit_test/antag_training_round_end/Run()
	wait_for_closing_training_arenas()
	var/obj/machinery/antag_training_pod/pod = allocate(/obj/machinery/antag_training_pod, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/visitor = allocate_pod_visitor(pod)
	var/datum/antag_training_session/dreamer = start_antag_training(visitor, /datum/antag_training_program/free, FALSE, pod)
	TEST_ASSERT_NOTNULL(dreamer, "Посетитель подключается из капсулы.")
	allocated += dreamer
	var/mob/dead/observer/observer = allocate(/mob/dead/observer, run_loc_floor_bottom_left)
	var/datum/antag_training_session/ghost = start_antag_training(observer, /datum/antag_training_program/free, FALSE)
	TEST_ASSERT_NOTNULL(ghost, "Призрак подключается.")
	allocated += ghost
	dreamer.current_body.key = "unit_test_training_round_end_pod"
	ghost.current_body.key = "unit_test_training_round_end_ghost"
	var/list/round_end_hooks = list()
	for(var/datum/callback/callback as anything in SSticker.round_end_events)
		if(callback.delegate == GLOBAL_PROC_REF(antag_training_round_end))
			round_end_hooks += callback
	TEST_ASSERT_EQUAL(length(round_end_hooks), 1, "Полигон один раз подписан на конец раунда.")
	var/datum/callback/round_end = round_end_hooks[1]
	round_end.InvokeAsync()
	var/closed = wait_for_qdeleted(dreamer, 5 SECONDS) && wait_for_qdeleted(ghost, 5 SECONDS)
	var/mob/dead/observer/returned = find_training_player("unit_test_training_round_end_ghost", /mob/dead/observer)
	if(returned)
		allocated += returned
		returned.key = null
	TEST_ASSERT(closed, "Конец раунда закрывает сеансы.")
	TEST_ASSERT_EQUAL(visitor.key, "unit_test_training_round_end_pod", "Посетитель кафе просыпается в теле.")
	visitor.key = null
	TEST_ASSERT(pod.state_open && !length(pod.sessions), "Капсула открывается.")
	TEST_ASSERT_NOTNULL(returned, "Вошедший призраком становится призраком.")

/datum/unit_test/antag_training_round_over_entry
	var/previous_ticker_state

/datum/unit_test/antag_training_round_over_entry/Destroy()
	if(!isnull(previous_ticker_state))
		SSticker.current_state = previous_ticker_state
	return ..()

/// После конца раунда на полигон не войти: ни через общий вход, ни подключением готовой куклы.
/datum/unit_test/antag_training_round_over_entry/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/mob/dead/observer/observer = allocate(/mob/dead/observer, run_loc_floor_bottom_left)
	previous_ticker_state = SSticker.current_state
	SSticker.current_state = GAME_STATE_FINISHED
	var/datum/antag_training_session/late = start_antag_training(observer, /datum/antag_training_program/free, FALSE)
	var/connected = session.connect(observer)
	SSticker.current_state = previous_ticker_state
	previous_ticker_state = null
	if(late)
		allocated += late
	TEST_ASSERT_NULL(late, "Общий вход закрыт после конца раунда.")
	TEST_ASSERT(!connected, "Готовая кукла не подключается после конца раунда.")

/// Капсула отпускает место, когда сеанс начался: второй посетитель ложится в ту же капсулу, открытие не высыпает спящих, каждый просыпается рядом.
/datum/unit_test/antag_training_cafe_pod_shared/Run()
	wait_for_closing_training_arenas()
	var/obj/machinery/antag_training_pod/pod = allocate(/obj/machinery/antag_training_pod, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/first = allocate_pod_visitor(pod)
	var/datum/antag_training_session/first_session = start_antag_training(first, /datum/antag_training_program/free, FALSE, pod)
	TEST_ASSERT_NOTNULL(first_session, "Первый посетитель подключается.")
	allocated += first_session
	TEST_ASSERT(pod.state_open && !pod.occupant, "После начала сеанса место в капсуле свободно.")
	TEST_ASSERT_EQUAL(first.loc, pod, "Тело первого спит в капсуле.")
	var/mob/living/carbon/human/second = allocate_pod_visitor(pod)
	TEST_ASSERT_EQUAL(pod.occupant, second, "Второй посетитель ложится в ту же капсулу.")
	var/datum/antag_training_session/second_session = start_antag_training(second, /datum/antag_training_program/free, FALSE, pod)
	TEST_ASSERT_NOTNULL(second_session, "Второй посетитель подключается.")
	allocated += second_session
	pod.open_machine()
	TEST_ASSERT(first.loc == pod && second.loc == pod, "Открытие капсулы не высыпает спящих.")
	first_session.finish()
	TEST_ASSERT_EQUAL(first.loc, run_loc_floor_bottom_left, "Первый просыпается рядом с капсулой.")
	TEST_ASSERT(!HAS_TRAIT(first, TRAIT_TRAINING_DREAMER) && !(first.status_flags & GODMODE), "Защита с первого снята.")
	TEST_ASSERT_EQUAL(second.loc, pod, "Второй спит дальше.")
	TEST_ASSERT(HAS_TRAIT(second, TRAIT_TRAINING_DREAMER) && (second.status_flags & GODMODE), "Второй под защитой капсулы.")
	second_session.finish()
	TEST_ASSERT_EQUAL(second.loc, run_loc_floor_bottom_left, "Второй просыпается рядом с капсулой.")
	TEST_ASSERT(pod.state_open && !pod.occupant, "Капсула пуста после выхода обоих.")
