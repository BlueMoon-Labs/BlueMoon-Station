/datum/unit_test/proc/antag_training_hub_find(datum/antag_training_hub/hub, find_type, area_type, find_name)
	for(var/turf/tile as anything in hub.turfs)
		if(area_type && !istype(tile.loc, area_type))
			continue
		for(var/atom/movable/thing as anything in tile)
			if(istype(thing, find_type) && (!find_name || thing.name == find_name))
				return thing

/// Вестибюль хаба грузится с ареной, мини-станция и площадки - когда входит игрок; новички появляются в вестибюле, простой и общий сброс хаб не трогают, закрытие арены убирает.
/datum/unit_test/antag_training_hub_load/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	var/list/before = antag_training_global_snapshot()
	var/real_started = REALTIMEOFDAY
	var/world_started = world.time
	TEST_ASSERT(session.prepare(), "Полигон готовится.")
	log_test("\tПостройка арены с хабом: [(REALTIMEOFDAY - real_started) / (1 SECONDS)] с реального времени, [(world.time - world_started) / (1 SECONDS)] с мирового.")
	var/datum/antag_training_arena/arena = session.arena
	var/datum/antag_training_hub/hub = arena.hub
	TEST_ASSERT(hub?.ready, "Хаб грузится вместе с ареной.")
	TEST_ASSERT(!(hub in arena.sectors), "Хаб - не сектор.")
	TEST_ASSERT_EQUAL(arena.entry_turf, hub.landmark_turf("hub_arrival"), "Вход на полигон - прибытие хаба.")
	TEST_ASSERT(istype(get_area(arena.entry_turf), /area/antag_training/hub/lobby), "Прибытие - в вестибюле.")
	TEST_ASSERT_EQUAL(get_turf(session.current_body), arena.entry_turf, "Новичок появляется в вестибюле.")
	TEST_ASSERT(arena.owns_area(get_area(arena.entry_turf)), "Вестибюль принадлежит арене.")
	TEST_ASSERT_EQUAL(hub.station_state, ANTAG_TRAINING_SECTOR_UNLOADED, "Мини-станция не грузится при сборке арены.")
	session.current_body.forceMove(arena.zones["melee"]["spawn"])
	real_started = REALTIMEOFDAY
	world_started = world.time
	hub.release()
	TEST_ASSERT(!hub.ready && isspaceturf(arena.entry_turf), "Снятый вестибюль освобождает клетки.")
	TEST_ASSERT(hub.load(), "Вестибюль грузится заново.")
	log_test("	Снятие и загрузка вестибюля хаба: [(REALTIMEOFDAY - real_started) / (1 SECONDS)] с реального времени, [(world.time - world_started) / (1 SECONDS)] с мирового.")
	TEST_ASSERT_EQUAL(hub.landmark_turf("hub_arrival"), arena.entry_turf, "Повторная загрузка ставит прибытие на прежнее место.")
	session.current_body.forceMove(arena.entry_turf)
	var/mob/dead/observer/observer = allocate(/mob/dead/observer, run_loc_floor_bottom_left)
	real_started = REALTIMEOFDAY
	world_started = world.time
	TEST_ASSERT(session.connect(observer), "Игрок входит на полигон.")
	var/list/budget = new_wait_budget(1 MINUTES, "мини-станция хаба")
	while(hub.station_state != ANTAG_TRAINING_SECTOR_READY && wait_budget_tick(budget))
		continue
	TEST_ASSERT_EQUAL(hub.station_state, ANTAG_TRAINING_SECTOR_READY, "Вход игрока загружает мини-станцию.")
	for(var/index in 1 to 4)
		var/turf/pad = hub.landmark_turf("hub_pad_[index]")
		TEST_ASSERT(istype(get_area(pad), /area/antag_training/hub/pad), "Площадка [index] загружается вместе с мини-станцией.")
	log_test("	Загрузка мини-станции хаба: [(REALTIMEOFDAY - real_started) / (1 SECONDS)] с реального времени, [(world.time - world_started) / (1 SECONDS)] с мирового.")
	for(var/mark in list("hub_board", "hub_tribune", "hub_ai_core"))
		TEST_ASSERT_NOTNULL(hub.landmark_turf(mark), "В хабе есть метка [mark].")
	for(var/department_id in hub.departments)
		var/datum/antag_training_hub_department/department = hub.departments[department_id]
		var/datum/map_template/part = antag_training_map_template(department.map_path(), department.name)
		TEST_ASSERT(length(department.turfs), "У отсека [department_id] есть клетки.")
		var/turf/origin = department.origin_turf()
		for(var/turf/tile as anything in department.turfs)
			TEST_ASSERT(tile.x >= origin.x && tile.y >= origin.y && tile.x < origin.x + part.width && tile.y < origin.y + part.height, "Отсек [department_id] умещается в свой кусок карты.")
	var/list/loaded = antag_training_global_snapshot()
	for(var/key in list("nuke", "poi", "gps", "spawners", "ai_cores", "start_landmarks", "shuttle_callers", "consoles", "casters", "rnd_servers", "mechs", "station_cameras", "ai_shells"))
		TEST_ASSERT_EQUAL(loaded[key], before[key], "Хаб не добавляет [key] в реестры раунда.")
	var/list/shared_wiring = list()
	for(var/turf/tile as anything in hub.turfs)
		for(var/obj/thing in tile)
			TEST_ASSERT(thing.training_origin?.resolve() == arena, "[thing.type] с карты хаба принадлежит арене.")
		for(var/obj/thing as anything in tile.GetAllContents(/obj))
			for(var/wire_key in GLOB.wire_color_directory)
				if(thing.wires?.colors == GLOB.wire_color_directory[wire_key])
					shared_wiring |= thing.type
			var/obj/machinery/camera/camera = thing
			if(istype(camera))
				TEST_ASSERT(length(camera.network) == 1 && camera.network[1] == "training", "Камера хаба [camera.c_tag] только в учебной сети.")
	TEST_ASSERT(!length(shared_wiring), "Раскладка проводов раунда у [shared_wiring.Join(", ")].")
	var/obj/structure/antag_training_wardrobe/wardrobe = antag_training_hub_find(hub, /obj/structure/antag_training_wardrobe)
	TEST_ASSERT_NOTNULL(wardrobe, "В раздевалке есть шкафы.")
	for(var/department_id in hub.departments)
		var/datum/antag_training_hub_department/department = hub.departments[department_id]
		department.last_occupied_at = world.time - ANTAG_TRAINING_HUB_DEPARTMENT_IDLE - 1 SECONDS
	hub.check_departments()
	for(var/department_id in hub.departments)
		TEST_ASSERT(!hub.departments[department_id].resetting, "Нетронутый отсек [department_id] простой не сбрасывает.")
	TEST_ASSERT(arena.reset_zone("all"), "Общий сброс проходит.")
	TEST_ASSERT(hub.ready && !QDELETED(wardrobe), "Общий сброс не трогает хаб.")
	session.current_body.forceMove(arena.zones["melee"]["spawn"])
	var/datum/tgui/ui = allocate(/datum/tgui, session.current_body, session, "AntagTraining")
	TEST_ASSERT(session.ui_data(session.current_body)["hub"], "Пульт знает, что хаб готов.")
	antag_training_console_act(session, ui, "hub", list())
	TEST_ASSERT_EQUAL(get_turf(session.current_body), arena.entry_turf, "Кнопка «В хаб» переносит в вестибюль.")
	var/turf/hub_spot = arena.entry_turf
	real_started = REALTIMEOFDAY
	world_started = world.time
	qdel(session)
	TEST_ASSERT(wait_for_qdeleted(arena, 1 MINUTES), "Полигон закрывается.")
	log_test("	Закрытие арены с хабом: [(REALTIMEOFDAY - real_started) / (1 SECONDS)] с реального времени, [(world.time - world_started) / (1 SECONDS)] с мирового.")
	TEST_ASSERT(isspaceturf(hub_spot), "Закрытие арены убирает хаб.")
	var/list/after = antag_training_global_snapshot()
	// Бюджет науки растёт сам по себе со временем, остальные реестры обязаны вернуться.
	for(var/key in before - "science_budget")
		TEST_ASSERT_EQUAL(after[key], before[key], "Закрытие арены с хабом возвращает [key].")

/// Вестибюль - безопасная зона, мини-станция - нет; снаряд из мини-станции не пролетает через барьер.
/datum/unit_test/antag_training_hub_safety/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон готовится.")
	var/datum/antag_training_arena/arena = session.arena
	var/datum/antag_training_hub/hub = arena.hub
	TEST_ASSERT(hub.load_station(), "Мини-станция загружается.")
	var/mob/living/carbon/human/body = session.current_body
	session.update_safety()
	TEST_ASSERT((body.status_flags & GODMODE) && HAS_TRAIT_FROM(body, TRAIT_PACIFISM, REF(session)), "В вестибюле урон и драки отключены.")
	TEST_ASSERT_EQUAL(arena.match_zone(body), "hub", "Вестибюль - та же безопасная зона, что центр.")
	var/obj/structure/antag_training_barrier/hub/border
	for(var/turf/tile as anything in hub.turfs)
		var/obj/structure/antag_training_barrier/hub/barrier = locate() in tile
		if(barrier && istype(get_area(get_step(barrier, EAST)), /area/antag_training/hub/station))
			border = barrier
			break
	TEST_ASSERT_NOTNULL(border, "Вестибюль отделён от мини-станции барьером.")
	TEST_ASSERT_EQUAL(border.arena, arena, "Барьер с карты знает свою арену.")
	body.forceMove(get_step(border, WEST))
	TEST_ASSERT(body.Move(get_turf(border), EAST), "Участник проходит через барьер.")
	TEST_ASSERT(body.Move(get_step(border, EAST), EAST), "Участник выходит в мини-станцию.")
	TEST_ASSERT(istype(get_area(body), /area/antag_training/hub/station), "Участник в мини-станции.")
	TEST_ASSERT(!(body.status_flags & GODMODE) && !HAS_TRAIT_FROM(body, TRAIT_PACIFISM, REF(session)), "В мини-станции урон включён.")
	var/datum/antag_training_hub_department/entered = hub.department_at(get_turf(body))
	TEST_ASSERT(entered?.used, "Отсек, куда зашёл участник, отмечен тронутым.")
	body.forceMove(arena.zones["melee"]["spawn"])
	var/turf/lobby_spot = get_step(get_step(border, WEST), WEST)
	var/mob/living/carbon/human/dummy = allocate(/mob/living/carbon/human, lobby_spot)
	var/turf/start = get_step(get_step(border, EAST), NORTH)
	if(!istype(get_area(start), /area/antag_training/hub/station))
		start = get_step(get_step(border, EAST), SOUTH)
	var/obj/item/projectile/beam/laser/shot = new(start)
	shot.preparePixelProjectile(dummy, start)
	shot.fire()
	var/list/budget = new_wait_budget(5 SECONDS, "снаряд у барьера")
	while(!QDELETED(shot) && wait_budget_tick(budget))
		continue
	TEST_ASSERT(QDELETED(shot), "Снаряд останавливается.")
	TEST_ASSERT_EQUAL(dummy.getFireLoss(), 0, "Снаряд из мини-станции не пролетает в вестибюль.")

/// Шаг на врата сектора переносит участника в этот сектор, незагруженный сектор подгружается; в чужую бронь врата не пускают.
/datum/unit_test/antag_training_hub_gate/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон готовится.")
	var/datum/antag_training_arena/arena = session.arena
	var/datum/antag_training_sector/sector = arena.sectors["dark"]
	TEST_ASSERT_EQUAL(sector.state, ANTAG_TRAINING_SECTOR_UNLOADED, "Сектор ещё не загружен.")
	var/obj/structure/antag_training_gate/gate = antag_training_hub_find(arena.hub, /obj/structure/antag_training_gate/dark)
	TEST_ASSERT_NOTNULL(gate, "В зале есть врата тёмного сектора.")
	var/mob/living/carbon/human/body = session.current_body
	var/datum/antag_training_session/owner = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(owner.prepare(arena), "Второй участник входит.")
	var/datum/antag_training_squad/team = arena.create_squad(owner, "Альфа")
	TEST_ASSERT(team?.book(owner, sector), "Группа второго участника бронирует сектор.")
	body.forceMove(get_step(gate, SOUTH))
	TEST_ASSERT(body.Move(get_turf(gate), NORTH), "Участник шагает на врата.")
	TEST_ASSERT_EQUAL(get_turf(body), get_turf(gate), "Чужая бронь: врата не переносят.")
	team.release("Проверка врат.")
	body.forceMove(get_step(gate, SOUTH))
	TEST_ASSERT(body.Move(get_turf(gate), NORTH), "Участник шагает на врата.")
	var/list/budget = new_wait_budget(30 SECONDS, "участник в секторе")
	while(!(sector.bounds && arena.inside_bounds(get_turf(body), sector.bounds)) && wait_budget_tick(budget))
		continue
	TEST_ASSERT(sector.bounds && arena.inside_bounds(get_turf(body), sector.bounds), "Врата переносят в сектор.")
	TEST_ASSERT_EQUAL(sector.state, ANTAG_TRAINING_SECTOR_READY, "Сектор загружен.")

/// Осмотр врат до загрузки сектора называет его упражнения, сценарии и программы, которые в нём начинают.
/datum/unit_test/antag_training_hub_gate_guide/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон готовится.")
	var/datum/antag_training_arena/arena = session.arena
	var/obj/structure/antag_training_gate/gate = antag_training_hub_find(arena.hub, /obj/structure/antag_training_gate/dark)
	TEST_ASSERT_NOTNULL(gate, "В зале есть врата тёмного сектора.")
	var/examined = jointext(gate.examine(session.current_body), "\n")
	for(var/exercise_id in GLOB.antag_training_exercises)
		var/datum/antag_training_exercise/exercise = GLOB.antag_training_exercises[exercise_id]
		if(exercise.sector == "dark")
			TEST_ASSERT(findtext(examined, exercise.name), "Врата называют упражнение «[exercise.name]»: [examined]")
	var/datum/antag_training_scenario/xeno = antag_training_scenarios()["xeno"]
	TEST_ASSERT(findtext(examined, xeno.name), "Врата называют сценарий сектора: [examined]")
	var/datum/antag_training_program/bloodsucker = /datum/antag_training_program/antag/bloodsucker
	TEST_ASSERT(findtext(examined, initial(bloodsucker.name)), "Врата называют программу, которая начинает в секторе: [examined]")
	var/datum/antag_training_sector/dark = arena.sectors["dark"]
	TEST_ASSERT_EQUAL(dark.state, ANTAG_TRAINING_SECTOR_UNLOADED, "Осмотр врат не грузит сектор.")
	var/obj/structure/antag_training_gate/station_gate = antag_training_hub_find(arena.hub, /obj/structure/antag_training_gate/station)
	var/station_text = jointext(station_gate.examine(session.current_body), "\n")
	var/station_exercises = 0
	for(var/exercise_id in GLOB.antag_training_exercises)
		var/datum/antag_training_exercise/exercise = GLOB.antag_training_exercises[exercise_id]
		if(exercise.sector == "station")
			station_exercises++
			TEST_ASSERT(findtext(station_text, exercise.name), "Врата станции называют упражнение «[exercise.name]»: [station_text]")
	if(!station_exercises)
		TEST_ASSERT(findtext(station_text, "Готовых упражнений здесь нет"), "Врата сектора без упражнений так и говорят: [station_text]")
	TEST_ASSERT(findtext(station_text, "Задержание") && findtext(station_text, "не для вашей роли"), "Врата макета называют упражнения СБ и что они не для этой роли: [station_text]")

/// Шкаф раздевалки выдаёт должность своего отдела и не выдаёт чужую.
/datum/unit_test/antag_training_hub_wardrobe/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон готовится.")
	var/obj/structure/antag_training_wardrobe/wardrobe = antag_training_hub_find(session.arena.hub, /obj/structure/antag_training_wardrobe/engineering)
	TEST_ASSERT_NOTNULL(wardrobe, "В раздевалке есть шкаф инженерии.")
	var/mob/living/carbon/human/body = session.current_body
	body.forceMove(get_step(wardrobe, EAST))
	var/list/data = wardrobe.ui_data(body)
	var/list/offered = list()
	for(var/list/entry as anything in data["roles"])
		offered += entry["id"]
	TEST_ASSERT(("crew:Station Engineer" in offered) && !("crew:Security Officer" in offered), "Шкаф предлагает только должности своего отдела: [offered.Join(", ")].")
	var/datum/tgui/ui = allocate(/datum/tgui, body, wardrobe, "AntagTrainingWardrobe")
	ui.status = UI_INTERACTIVE
	usr = body
	wardrobe.ui_act("set_role", list("role" = "crew:Security Officer"), ui)
	usr = null
	TEST_ASSERT_EQUAL(session.role.id, ANTAG_TRAINING_ROLE_DEFAULT, "Чужая должность через шкаф не выдаётся.")
	usr = body
	wardrobe.ui_act("set_role", list("role" = "crew:Station Engineer"), ui)
	usr = null
	TEST_ASSERT_EQUAL(session.role.id, "crew:Station Engineer", "Шкаф выдаёт должность отдела.")
	var/mob/living/carbon/human/engineer = session.current_body
	var/obj/item/card/id/card = engineer.get_idcard()
	TEST_ASSERT_EQUAL(card?.assignment, "Station Engineer", "ID получает должность.")

/// Участник партии у шкафа с должностью, несовместимой с его программой, слышит только отказ партии, а не совет сменить программу.
/datum/unit_test/antag_training_hub_wardrobe_scenario_lock/Run()
	var/datum/antag_training_scenario/scenario = training_scenario_launch("traitor_security", 2)
	TEST_ASSERT_NOTNULL(scenario, "«Предатель против СБ» начинается.")
	var/datum/antag_training_session/traitor = training_scenario_member(scenario, "traitor")
	var/obj/structure/antag_training_wardrobe/silicon/wardrobe = antag_training_hub_find(traitor.arena.hub, /obj/structure/antag_training_wardrobe/silicon)
	TEST_ASSERT_NOTNULL(wardrobe, "В раздевалке есть шкаф синтетиков.")
	var/datum/antag_training_role/cyborg = antag_training_role("silicon:cyborg")
	TEST_ASSERT(wardrobe.offers(cyborg) && !antag_training_role_compatible(traitor.program.type, cyborg), "Шкаф предлагает киборга, а программа предателя с ним не работает.")
	var/mob/living/carbon/human/body = traitor.current_body
	body.forceMove(get_step(wardrobe, EAST))
	var/datum/tgui/ui = allocate(/datum/tgui, body, wardrobe, "AntagTrainingWardrobe")
	ui.status = UI_INTERACTIVE
	usr = body
	GLOB.unit_test_chat_capture = list()
	wardrobe.ui_act("set_role", list("role" = "silicon:cyborg"), ui)
	var/list/told = list()
	for(var/list/entry as anything in GLOB.unit_test_chat_capture)
		if(entry[1] == body || entry[1] == body.client)
			told += entry[2]
	GLOB.unit_test_chat_capture = null
	usr = null
	TEST_ASSERT(traitor.role?.id != "silicon:cyborg", "Шкаф не меняет должность участнику партии.")
	TEST_ASSERT(length(told) == 1 && findtext(told[1], "Идёт сценарий"), "Отказ шкафа - одно сообщение о сценарии: [json_encode(told)].")

/datum/unit_test/antag_training_hub_wardrobe_scenario_lock/Destroy()
	GLOB.unit_test_chat_capture = null
	return ..()

/// ID инженера открывает двери инженерного отсека мини-станции и не открывает бриг.
/datum/unit_test/antag_training_hub_access/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон готовится.")
	TEST_ASSERT(session.set_role("crew:Station Engineer"), "Участник становится инженером.")
	var/datum/antag_training_hub/hub = session.arena.hub
	TEST_ASSERT(hub.load_station(), "Мини-станция загружается.")
	var/obj/machinery/door/airlock/engineering = antag_training_hub_find(hub, /obj/machinery/door/airlock, /area/antag_training/hub/station/engineering, "Engineering")
	var/obj/machinery/door/airlock/power = antag_training_hub_find(hub, /obj/machinery/door/airlock, /area/antag_training/hub/station/engineering, "Power Room")
	var/obj/machinery/door/airlock/brig = antag_training_hub_find(hub, /obj/machinery/door/airlock, /area/antag_training/hub/station/brig, "Brig")
	var/obj/machinery/door/airlock/bar = antag_training_hub_find(hub, /obj/machinery/door/airlock, /area/antag_training/hub/station/bar, "Bar")
	TEST_ASSERT(engineering && power && brig && bar, "Двери отсеков на месте.")
	var/mob/living/carbon/human/body = session.current_body
	TEST_ASSERT(engineering.allowed(body) && power.allowed(body), "ID инженера открывает инженерный отсек.")
	TEST_ASSERT(!brig.allowed(body), "ID инженера не открывает бриг.")
	TEST_ASSERT(bar.allowed(body), "Бар открыт всем.")

/// Сброс отсека: голосуют те, кто внутри; пустой тронутый отсек сбрасывается сам; вынесенная вещь возвращается на место.
/datum/unit_test/antag_training_hub_department_reset/Run()
	var/datum/antag_training_session/first = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(first.prepare(), "Полигон готовится.")
	var/datum/antag_training_session/second = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(second.prepare(first.arena), "Второй участник входит.")
	var/datum/antag_training_hub/hub = first.arena.hub
	TEST_ASSERT(hub.load_station(), "Мини-станция загружается.")
	var/datum/antag_training_hub_department/medbay = hub.departments["medbay"]
	var/obj/machinery/chem_dispenser/dispenser = antag_training_hub_find(hub, /obj/machinery/chem_dispenser, /area/antag_training/hub/station/medbay)
	var/obj/structure/antag_training_hub_reset/panel = antag_training_hub_find(hub, /obj/structure/antag_training_hub_reset, /area/antag_training/hub/station/medbay)
	TEST_ASSERT(dispenser && panel, "В медблоке есть химраздатчик и панель сброса.")
	var/turf/dispenser_spot = get_turf(dispenser)
	var/turf/hallway_spot = get_step(get_turf(antag_training_hub_find(hub, /obj/machinery/door/airlock, /area/antag_training/hub/station/medbay, "Medbay Lobby")), NORTH)
	dispenser.forceMove(hallway_spot)
	first.current_body.forceMove(get_turf(panel))
	second.current_body.forceMove(get_step(panel, WEST))
	panel.attack_hand(first.current_body)
	TEST_ASSERT(!medbay.resetting && world.time < medbay.vote_deadline, "Сброс ждёт согласия второго участника.")
	TEST_ASSERT(!(locate(/obj/machinery/chem_dispenser) in dispenser_spot), "Без согласия отсек не сброшен.")
	panel.attack_hand(second.current_body)
	var/list/budget = new_wait_budget(30 SECONDS, "сброс медблока голосованием")
	while(!(locate(/obj/machinery/chem_dispenser) in dispenser_spot) || medbay.resetting)
		if(!wait_budget_tick(budget))
			break
	TEST_ASSERT(locate(/obj/machinery/chem_dispenser) in dispenser_spot, "Сброс возвращает химраздатчик на место.")
	TEST_ASSERT(!QDELETED(dispenser) && get_turf(dispenser) == hallway_spot, "Вещь за пределами отсека сброс не трогает.")
	TEST_ASSERT(istype(get_area(first.current_body), /area/antag_training/hub/lobby) && istype(get_area(second.current_body), /area/antag_training/hub/lobby), "Участники из отсека переходят в вестибюль.")
	TEST_ASSERT(!medbay.used, "Сброшенный отсек снова нетронутый.")
	var/obj/machinery/chem_master/master = antag_training_hub_find(hub, /obj/machinery/chem_master, /area/antag_training/hub/station/medbay)
	var/turf/master_spot = get_turf(master)
	qdel(master)
	first.current_body.forceMove(master_spot)
	TEST_ASSERT(medbay.used, "Зашедший участник отмечает отсек тронутым.")
	medbay.last_occupied_at = world.time - ANTAG_TRAINING_HUB_DEPARTMENT_IDLE - 1 SECONDS
	hub.check_departments()
	TEST_ASSERT(!medbay.resetting && !(locate(/obj/machinery/chem_master) in master_spot), "Занятый отсек сам не сбрасывается.")
	first.current_body.forceMove(first.arena.entry_turf)
	medbay.last_occupied_at = world.time - ANTAG_TRAINING_HUB_DEPARTMENT_IDLE - 1 SECONDS
	hub.check_departments()
	budget = new_wait_budget(30 SECONDS, "сброс медблока по простою")
	while(!(locate(/obj/machinery/chem_master) in master_spot) || medbay.resetting)
		if(!wait_budget_tick(budget))
			break
	TEST_ASSERT(locate(/obj/machinery/chem_master) in master_spot, "Пустой тронутый отсек сбрасывается после простоя.")

/// Все отсеки мини-станции, коридор тоже, держат давление после входа игрока.
/datum/unit_test/antag_training_hub_station_air/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон готовится.")
	var/datum/antag_training_hub/hub = session.arena.hub
	var/mob/dead/observer/observer = allocate(/mob/dead/observer, run_loc_floor_bottom_left)
	TEST_ASSERT(session.connect(observer), "Игрок входит на полигон.")
	var/list/budget = new_wait_budget(1 MINUTES, "мини-станция хаба")
	while(hub.station_state != ANTAG_TRAINING_SECTOR_READY && wait_budget_tick(budget))
		continue
	TEST_ASSERT_EQUAL(hub.station_state, ANTAG_TRAINING_SECTOR_READY, "Вход игрока загружает мини-станцию.")
	budget = new_wait_budget(5 SECONDS, "воздух мини-станции")
	while(wait_budget_tick(budget))
		continue
	for(var/department_id in hub.departments)
		var/datum/antag_training_hub_department/department = hub.departments[department_id]
		var/turf/open/thinnest
		for(var/turf/open/tile in department.turfs)
			if(!thinnest || tile.air.return_pressure() < thinnest.air.return_pressure())
				thinnest = tile
		TEST_ASSERT(thinnest.air.return_pressure() > 95, "Отсек [department_id]: [round(thinnest.air.return_pressure(), 1)] кПа на [thinnest.x - hub.origin_x], [thinnest.y - hub.origin_y].")

/// Пустая арена ждёт возвращения: вход в это время попадает на тот же полигон, без входа арена закрывается.
/datum/unit_test/antag_training_empty_grace/Run()
	var/datum/antag_training_session/first = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(first.prepare(), "Полигон готовится.")
	var/datum/antag_training_arena/arena = first.arena
	arena.empty_grace = 3 SECONDS
	qdel(first)
	TEST_ASSERT(!arena.finished, "Пустая арена не закрывается сразу.")
	var/datum/antag_training_session/second = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(second.prepare(), "Вернувшийся входит.")
	TEST_ASSERT(second.arena == arena, "Вход во время ожидания попадает на тот же полигон.")
	var/list/budget = new_wait_budget(5 SECONDS, "ожидание пустой арены")
	while(wait_budget_tick(budget))
		continue
	TEST_ASSERT(!arena.finished, "Вход отменяет закрытие.")
	qdel(second)
	TEST_ASSERT(wait_for_qdeleted(arena, 1 MINUTES), "Без входа арена закрывается после ожидания.")

/// Роль ИИ встаёт в ядро мини-станции хаба, станционный макет для этого не грузится.
/datum/unit_test/antag_training_hub_ai_core/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон готовится.")
	var/datum/antag_training_arena/arena = session.arena
	TEST_ASSERT(session.set_role("silicon:ai"), "Участник становится ИИ.")
	TEST_ASSERT(istype(session.current_body, /mob/living/silicon/ai/training), "Тело - учебный ИИ.")
	TEST_ASSERT_EQUAL(get_turf(session.current_body), arena.hub.landmark_turf("hub_ai_core"), "ИИ стоит в ядре хаба.")
	TEST_ASSERT_EQUAL(arena.sectors["station"].state, ANTAG_TRAINING_SECTOR_UNLOADED, "Станционный макет для ИИ не грузится.")
	var/list/watched = list()
	for(var/turf/tile as anything in arena.hub.turfs)
		for(var/obj/machinery/camera/training/camera in tile)
			watched |= get_area(camera)
	for(var/department_id in arena.hub.departments)
		var/datum/antag_training_hub_department/department = arena.hub.departments[department_id]
		TEST_ASSERT(GLOB.areas_by_type[department.area_type] in watched, "Отсек [department_id] видят учебные камеры.")

/// Мини-станция и площадки хаба без наложений: те же проверки, что у секторов.
/datum/unit_test/antag_training_sector_layout/hub/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон готовится.")
	TEST_ASSERT(session.arena.hub.load_station(), "Мини-станция и площадки загружаются.")
	for(var/turf/place as anything in session.arena.hub.turfs)
		check_turf(place, "hub")

/// Смещение ЛКП в картах полигона совпадает с тем, что ставит APC/Initialize(): иначе каждая загрузка хаба пишет ошибки в map_errors.log (10598-10600).
/datum/unit_test/antag_training_map_apc_offsets/Run()
	var/static/list/side_dirs = list("north" = NORTH, "south" = SOUTH, "east" = EAST, "west" = WEST)
	var/regex/apc = regex(@"/obj/machinery/power/apc[\w/]*(\{[^}]*\})?", "g")
	var/regex/side = regex(@"/(north|south|east|west)\b")
	var/regex/dir_var = regex(@"\bdir = (\d+)")
	var/regex/shift = regex(@"\b(pixel_[xy]) = (-?\d+)", "g")
	var/list/folders = list("_maps/templates/antag_training/")
	var/checked = 0
	while(length(folders))
		var/folder = folders[length(folders)]
		folders.len--
		for(var/entry in flist(folder))
			if(copytext(entry, -1) == "/")
				folders += "[folder][entry]"
				continue
			if(copytext(entry, -4) != ".dmm")
				continue
			var/map_text = file2text("[folder][entry]")
			apc.next = 1
			while(apc.Find(map_text))
				var/block = apc.group[1]
				if(!block)
					continue
				checked++
				var/facing = SOUTH
				if(dir_var.Find(block))
					facing = text2num(dir_var.group[1])
				else if(side.Find(apc.match))
					facing = side_dirs[side.group[1]]
				var/list/expected = list("pixel_y" = 0, "pixel_x" = 0)
				switch(facing)
					if(NORTH)
						expected["pixel_y"] = 23
					if(SOUTH)
						expected["pixel_y"] = -23
					if(EAST)
						expected["pixel_x"] = 24
					if(WEST)
						expected["pixel_x"] = -25
				shift.next = 1
				while(shift.Find(block))
					var/axis = shift.group[1]
					var/value = text2num(shift.group[2])
					TEST_ASSERT(value == expected[axis], "[folder][entry]: у ЛКП [replacetext(replacetext(block, "\n", " "), "\t", "")] [axis] = [value], APC поставит [expected[axis]].")
	TEST_ASSERT(checked, "В картах полигона нашлись ЛКП с варедитами - иначе тест ничего не проверяет.")

/obj/structure/antag_training_wardrobe/silicon/probe
	var/mob/opened_by

/obj/structure/antag_training_wardrobe/silicon/probe/ui_interact(mob/user, datum/tgui/ui)
	opened_by = user

/obj/structure/antag_training_wardrobe/silicon/probe/Destroy()
	opened_by = null
	return ..()

/// Киборг и ИИ нажимают шкаф, доску групп, панель сброса отсека и платформу возврата; ядро ИИ платформа не двигает.
/datum/unit_test/antag_training_hub_silicon_buttons/Run()
	var/datum/antag_training_session/ai_session = allocate_training_session(/datum/antag_training_program/free)
	ai_session.role = antag_training_role("silicon:ai")
	TEST_ASSERT(ai_session.prepare(), "Полигон готовит ИИ.")
	var/datum/antag_training_arena/arena = ai_session.arena
	var/datum/antag_training_session/borg_session = allocate_training_session(/datum/antag_training_program/free)
	borg_session.role = antag_training_role("silicon:cyborg")
	TEST_ASSERT(borg_session.prepare(arena), "Полигон готовит киборга.")
	var/datum/antag_training_session/human = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(human.prepare(arena), "Человек входит.")
	var/mob/living/silicon/robot/borg = borg_session.current_body
	var/mob/living/silicon/ai/core = ai_session.current_body
	TEST_ASSERT(iscyborg(borg) && isAI(core), "Тела - киборг и ИИ.")
	var/turf/arrival = arena.hub_arrival()
	borg.forceMove(arrival)

	var/obj/structure/antag_training_wardrobe/silicon/probe/wardrobe = allocate(/obj/structure/antag_training_wardrobe/silicon/probe, get_step(arrival, EAST))
	wardrobe.attack_robot(borg)
	TEST_ASSERT_EQUAL(wardrobe.opened_by, borg, "Киборг открывает шкаф раздевалки.")
	wardrobe.attack_ai(core)
	TEST_ASSERT_EQUAL(wardrobe.opened_by, core, "ИИ открывает шкаф раздевалки.")
	var/obj/structure/sign/antag_training_board/squads/probe/board = allocate(/obj/structure/sign/antag_training_board/squads/probe, arrival)
	board.attack_robot(borg)
	TEST_ASSERT_EQUAL(board.opened_by, borg, "Киборг открывает доску групп.")
	board.attack_ai(core)
	TEST_ASSERT_EQUAL(board.opened_by, core, "ИИ открывает доску групп.")

	var/datum/antag_training_hub/hub = arena.hub
	TEST_ASSERT(hub.load_station(), "Мини-станция загружается.")
	var/datum/antag_training_hub_department/medbay = hub.departments["medbay"]
	var/obj/structure/antag_training_hub_reset/panel = antag_training_hub_find(hub, /obj/structure/antag_training_hub_reset, /area/antag_training/hub/station/medbay)
	TEST_ASSERT_NOTNULL(panel, "В медблоке есть панель сброса.")
	borg.forceMove(get_turf(panel))
	human.current_body.forceMove(get_step(panel, WEST))
	panel.attack_robot(borg)
	TEST_ASSERT(world.time < medbay.vote_deadline, "Киборг запрашивает сброс отсека.")

	var/turf/melee = arena.zones["melee"]["spawn"]
	borg.forceMove(melee)
	var/obj/structure/antag_training_exit/exit = allocate(/obj/structure/antag_training_exit, melee)
	exit.attack_robot(borg)
	TEST_ASSERT_EQUAL(get_turf(borg), arrival, "Платформа возврата переносит киборга в хаб.")
	var/turf/core_spot = get_turf(core)
	exit.attack_ai(core)
	TEST_ASSERT_EQUAL(get_turf(core), core_spot, "Платформа возврата не двигает ядро ИИ.")

/// Каждое оружие каталога снаряжения стреляет у участника без имплантов и особого доступа.
/datum/unit_test/antag_training_catalog_guns/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон готовится.")
	var/mob/living/carbon/human/body = session.current_body
	body.forceMove(session.arena.zones["range"]["spawn"])
	var/datum/tgui/ui = allocate(/datum/tgui, body, session, "AntagTraining")
	var/checked = 0
	var/list/silent = list()
	for(var/equipment_id in GLOB.antag_training_equipment)
		var/list/entry = GLOB.antag_training_equipment[equipment_id]
		if(!ispath(entry["type"], /obj/item/gun))
			continue
		session.next_supply_at = 0
		antag_training_console_act(session, ui, "equipment", list("id" = equipment_id))
		var/obj/item/gun/gun = locate(entry["type"]) in get_turf(body)
		TEST_ASSERT_NOTNULL(gun, "Выдано [equipment_id].")
		if(!gun.can_trigger_gun(body))
			silent += "[equipment_id] ([gun.type])"
		qdel(gun)
		checked++
	TEST_ASSERT(checked >= 10, "Проверено оружие каталога: [checked].")
	TEST_ASSERT(!length(silent), "Оружие каталога не стреляет у участника без имплантов: [silent.Join(", ")].")
