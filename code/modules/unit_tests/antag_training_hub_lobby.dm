/datum/unit_test/proc/training_lobby_act(datum/target, mob/user, action, list/params = list())
	var/datum/antag_training_arena/arena = antag_training_area_arena(user)
	var/datum/antag_training_session/session = arena?.session_of(user)
	if(session)
		session.next_action_at = 0
	var/datum/tgui/ui = allocate(/datum/tgui, user, target, "AntagTrainingBoard")
	usr = user
	. = target.ui_act(action, params, ui)
	usr = null

/// Доска групп стоит на метке вестибюля и принадлежит арене; её кнопки собирают группу, вводят в неё и выбирают сценарий; призрак только смотрит.
/datum/unit_test/antag_training_hub_lobby_board/Run()
	var/list/sessions = training_squad_sessions(2)
	TEST_ASSERT(length(sessions) == 2, "Два участника на полигоне.")
	var/datum/antag_training_session/leader = sessions[1]
	var/datum/antag_training_session/guest = sessions[2]
	var/datum/antag_training_arena/arena = leader.arena
	var/turf/spot = arena.hub.landmark_turf("hub_board")
	var/obj/structure/sign/antag_training_board/squads/board = locate() in spot
	TEST_ASSERT_NOTNULL(board, "Доска групп стоит на метке hub_board.")
	TEST_ASSERT_EQUAL(board.training_origin?.resolve(), arena, "Доска - атом полигона.")
	TEST_ASSERT(istype(get_area(board), /area/antag_training/hub/lobby), "Доска в вестибюле.")
	training_lobby_act(board, leader.current_body, "squad_create", list("name" = "Борт", "open" = TRUE))
	var/datum/antag_training_squad/squad = leader.squad
	TEST_ASSERT_NOTNULL(squad, "Доска собирает группу.")
	TEST_ASSERT_EQUAL(squad.name, "Борт", "Группа получает имя с доски.")
	training_lobby_act(board, guest.current_body, "squad_join", list("id" = REF(squad)))
	TEST_ASSERT_EQUAL(guest.squad, squad, "Через доску входят в открытую группу.")
	var/list/data = board.ui_data(leader.current_body)
	TEST_ASSERT(data["participant"] && data["squad"] == REF(squad), "Участник видит на доске свою группу.")
	TEST_ASSERT(length(data["members"]) == 2 && length(data["scenario_templates"]), "Доска отдаёт участников и шаблоны сценариев.")
	training_lobby_act(board, guest.current_body, "scenario_pick", list("id" = "custom", "sector" = "dark"))
	TEST_ASSERT_NULL(squad.scenario, "Сценарий с доски выбирает только лидер.")
	training_lobby_act(board, leader.current_body, "scenario_pick", list("id" = "custom", "sector" = "dark"))
	TEST_ASSERT_NOTNULL(squad.scenario, "Лидер выбирает сценарий с доски.")
	var/datum/antag_training_sector/dark = arena.sectors["dark"]
	TEST_ASSERT(wait_for_var(dark, "state", ANTAG_TRAINING_SECTOR_READY, 30 SECONDS), "Сектор сценария загружается.")

	var/mob/dead/observer/ghost = allocate(/mob/dead/observer, spot)
	var/obj/structure/sign/antag_training_board/squads/probe/probe = allocate(/obj/structure/sign/antag_training_board/squads/probe, spot)
	probe.attack_ghost(ghost)
	TEST_ASSERT_EQUAL(probe.opened_by, ghost, "Нажатие призрака открывает доску.")
	TEST_ASSERT_EQUAL(board.ui_status(ghost), UI_UPDATE, "Призраку доска только для просмотра.")
	var/list/ghost_data = board.ui_data(ghost)
	TEST_ASSERT(!ghost_data["participant"] && length(ghost_data["board"]) == 1, "Призрак видит группы на доске.")
	TEST_ASSERT_EQUAL(ghost_data["board"][1]["scenario"]?["name"], squad.scenario.name, "Призрак видит сценарий группы.")
	TEST_ASSERT(!training_lobby_act(board, ghost, "squad_leave"), "Призрак ничего не меняет на доске.")
	TEST_ASSERT_EQUAL(leader.squad, squad, "Действие призрака не трогает группу.")

/// Экраны трибуны показывают только забронированные сектора и занятые площадки, а станционную камеру не берут даже из учебной сети.
/datum/unit_test/antag_training_hub_lobby_tribune/Run()
	var/list/sessions = training_squad_sessions(2)
	TEST_ASSERT(length(sessions) == 2, "Два участника на полигоне.")
	var/datum/antag_training_session/leader = sessions[1]
	var/datum/antag_training_session/other = sessions[2]
	var/datum/antag_training_arena/arena = leader.arena
	var/datum/antag_training_hub/hub = arena.hub
	var/turf/tribune = hub.landmark_turf("hub_tribune")
	var/list/screens = list()
	for(var/obj/machinery/computer/security/telescreen/antag_training/screen in range(2, tribune))
		screens += screen
		TEST_ASSERT_EQUAL(screen.training_origin?.resolve(), arena, "Экран трибуны - атом полигона.")
	TEST_ASSERT_EQUAL(length(screens), 3, "На трибуне три экрана.")
	var/obj/machinery/computer/security/telescreen/antag_training/screen = locate() in tribune
	var/mob/dead/observer/ghost = allocate(/mob/dead/observer, tribune)
	TEST_ASSERT_EQUAL(screen.ui_status(ghost), UI_UPDATE, "Призрак смотрит экран трибуны, но не переключает его.")
	var/obj/machinery/computer/security/telescreen/antag_training/probe/probe = allocate(/obj/machinery/computer/security/telescreen/antag_training/probe, get_step(tribune, SOUTH))
	probe.attack_ghost(ghost)
	TEST_ASSERT_EQUAL(probe.opened_by, ghost, "Нажатие призрака открывает экран трибуны.")
	TEST_ASSERT(!length(screen.ui_data(ghost)["venues"]), "Пока ничего не занято, трибуне нечего показать.")
	var/mob/living/viewer = leader.current_body
	viewer.forceMove(locate(tribune.x, tribune.y - 5, tribune.z))

	training_squad_act(leader, "squad_create", list("open" = TRUE))
	TEST_ASSERT(training_squad_book(leader, "dark"), "Группа занимает тёмный сектор.")
	TEST_ASSERT(hub.load_station(), "Площадки загружаются.")
	training_squad_act(other, "pad_claim", list("id" = "pad_2"))
	var/datum/antag_training_hub_pad/pad = hub.pad_by_id("pad_2")
	TEST_ASSERT_EQUAL(pad.owner, other, "Участник занимает площадку.")
	var/list/venue_ids = list()
	for(var/list/venue as anything in screen.ui_data(ghost)["venues"])
		venue_ids += venue["id"]
	TEST_ASSERT_EQUAL(venue_ids.Join(","), "dark,pad_2", "Трибуна показывает только забронированный сектор и занятую площадку.")

	var/datum/antag_training_sector/dark = arena.sectors["dark"]
	TEST_ASSERT(training_lobby_act(screen, viewer, "select_venue", list("id" = "dark")), "Экран переключается на сектор.")
	var/list/cameras = screen.get_available_cameras()
	TEST_ASSERT(length(cameras), "У тёмного сектора есть камеры обзора.")
	for(var/tag in cameras)
		var/obj/machinery/camera/camera = cameras[tag]
		TEST_ASSERT(arena.inside_bounds(get_turf(camera), dark.bounds), "Камера [tag] внутри сектора.")
		TEST_ASSERT(length(camera.network) == 1 && camera.network[1] == "training", "Камера [tag] только в учебной сети.")
	TEST_ASSERT(screen.active_camera && cameras[screen.active_camera.c_tag] == screen.active_camera, "Экран сразу показывает камеру сектора.")
	TEST_ASSERT(!training_lobby_act(screen, viewer, "select_venue", list("id" = "eva")), "Незанятый сектор на трибуну не выводится.")
	TEST_ASSERT_EQUAL(screen.venue_id, "dark", "Отказ не сбивает выбранное место.")
	TEST_ASSERT(!training_lobby_act(screen, ghost, "select_venue", list("id" = "pad_2")), "Призрак не переключает экран живым зрителям.")
	TEST_ASSERT_EQUAL(screen.venue_id, "dark", "Действие призрака не сбивает место.")

	var/obj/machinery/camera/station_camera = allocate(/obj/machinery/camera, run_loc_floor_bottom_left)
	station_camera.network = list("training")
	station_camera.c_tag = "Станция: проба трибуны"
	GLOB.cameranet.invalidate_camera_cache()
	TEST_ASSERT(!training_lobby_act(screen, viewer, "switch_camera", list("name" = station_camera.c_tag)), "Станционную камеру трибуна не включает.")
	TEST_ASSERT_NOTEQUAL(screen.active_camera, station_camera, "На экране не станционная камера.")
	TEST_ASSERT(!screen.get_available_cameras()[station_camera.c_tag], "Станционной камеры нет в списке трибуны.")

	TEST_ASSERT(training_lobby_act(screen, viewer, "select_venue", list("id" = "pad_2")), "Экран переключается на площадку.")
	cameras = screen.get_available_cameras()
	TEST_ASSERT(length(cameras), "У площадки есть камеры обзора.")
	for(var/tag in cameras)
		TEST_ASSERT(pad.contains(cameras[tag]), "Камера [tag] внутри площадки.")
	var/obj/machinery/camera/shown = screen.active_camera
	TEST_ASSERT(pad.load_preset("maze"), "Пресет площадки грузится.")
	TEST_ASSERT(QDELETED(shown) && !screen.active_camera, "Перезагрузка площадки снимает старую камеру с экрана.")
	TEST_ASSERT(length(screen.get_available_cameras()), "После пресета у площадки снова есть камеры.")

	var/mob/living/body = leader.current_body
	body.forceMove(locate(tribune.x, tribune.y - 5, tribune.z))
	TEST_ASSERT_EQUAL(screen.ui_status(body), UI_INTERACTIVE, "Участник смотрит экран с дивана трибуны.")
	body.forceMove(arena.zones["melee"]["spawn"])
	TEST_ASSERT_EQUAL(screen.ui_status(body), UI_CLOSE, "Издалека экран не управляется.")

/obj/effect/antag_training_lobby_entry
	var/datum/antag_training_session/started
	var/calls = 0

/obj/effect/antag_training_lobby_entry/proc/begin_training(mob/user, program_type, use_character, role_id)
	calls++
	started = start_antag_training(user, program_type, use_character, null, role_id)
	return started

/datum/unit_test/proc/training_lobby_slot_listed(list/data, datum/antag_training_squad/squad, datum/antag_training_scenario_slot/slot)
	for(var/list/entry as anything in data["squads"])
		if(entry["id"] != REF(squad))
			continue
		if(!slot)
			return TRUE
		for(var/list/slot_entry as anything in entry["scenario"]?["slots"])
			if(slot_entry["id"] == REF(slot))
				return slot_entry["joinable"]
	return FALSE

/// Призрак из каталога входит в свободный слот открытой группы: сеанс, группа и слот; занятый слот и закрытая группа отказывают до входа.
/datum/unit_test/antag_training_hub_lobby_catalog/Run()
	var/list/sessions = training_squad_sessions(1)
	TEST_ASSERT(length(sessions) == 1, "Лидер на полигоне.")
	var/datum/antag_training_session/leader = sessions[1]
	training_squad_act(leader, "squad_create", list("name" = "Сбор", "open" = TRUE))
	var/datum/antag_training_squad/squad = leader.squad
	var/datum/antag_training_scenario/scenario = training_scenario_pick(leader, "custom", "dark")
	TEST_ASSERT_NOTNULL(scenario, "Лидер выбирает свою сборку в тёмном секторе.")
	training_squad_act(leader, "scenario_slot_add", list("side" = "a", "role" = "crew:Detective", "label" = "Сыщик", "count" = 1))
	var/datum/antag_training_scenario_slot/slot = training_scenario_slot(scenario, "Сыщик")
	TEST_ASSERT_NOTNULL(slot, "В листе есть слот детектива.")

	var/obj/effect/antag_training_lobby_entry/entry = allocate(/obj/effect/antag_training_lobby_entry, run_loc_floor_bottom_left)
	var/mob/dead/observer/visitor = allocate(/mob/dead/observer, run_loc_floor_bottom_left)
	var/datum/antag_training_catalog/catalog = new(visitor, entry)
	allocated += catalog
	TEST_ASSERT(training_lobby_slot_listed(catalog.ui_data(visitor), squad, slot), "Каталог показывает свободный слот открытой группы.")
	var/datum/tgui/ui = allocate(/datum/tgui, visitor, catalog, "AntagTrainingCatalog")
	ui.status = UI_INTERACTIVE
	catalog.ui_act("join_squad", list("squad" = REF(squad), "slot" = REF(slot), "use_character" = FALSE), ui)
	TEST_ASSERT(QDELETED(catalog), "Вход закрывает каталог.")
	var/list/budget = new_wait_budget(1 MINUTES, "вход из каталога в слот")
	while(!entry.started?.squad && wait_budget_tick(budget))
		continue
	var/datum/antag_training_session/joined = entry.started
	TEST_ASSERT_NOTNULL(joined, "Вход из каталога создаёт сеанс.")
	allocated += joined
	TEST_ASSERT_EQUAL(joined.arena, leader.arena, "Вошедший на том же полигоне.")
	TEST_ASSERT_EQUAL(joined.squad, squad, "Вошедший в группе.")
	TEST_ASSERT(joined in slot.occupants, "Вошедший занял слот.")
	TEST_ASSERT_EQUAL(joined.role?.id, slot.role_id, "Роль входа - роль слота.")
	TEST_ASSERT(istype(joined.program, /datum/antag_training_program/free), "Программа слота придёт на старте, вход - со «Снаряжением и боем».")

	var/mob/dead/observer/late = allocate(/mob/dead/observer, run_loc_floor_bottom_left)
	var/datum/antag_training_catalog/late_catalog = new(late, entry)
	allocated += late_catalog
	var/datum/tgui/late_ui = allocate(/datum/tgui, late, late_catalog, "AntagTrainingCatalog")
	late_ui.status = UI_INTERACTIVE
	TEST_ASSERT(!training_lobby_slot_listed(late_catalog.ui_data(late), squad, slot), "Занятый слот в каталоге не предлагается.")
	late_catalog.ui_act("join_squad", list("squad" = REF(squad), "slot" = REF(slot)), late_ui)
	TEST_ASSERT(!QDELETED(late_catalog) && entry.calls == 1, "Занятый слот не запускает вход.")
	training_squad_act(leader, "squad_open")
	TEST_ASSERT(!squad.open, "Лидер закрывает группу.")
	TEST_ASSERT(!training_lobby_slot_listed(late_catalog.ui_data(late), squad, null), "Закрытой группы нет в каталоге.")
	late_catalog.ui_act("join_squad", list("squad" = REF(squad)), late_ui)
	TEST_ASSERT(!QDELETED(late_catalog) && entry.calls == 1, "Закрытая группа не запускает вход.")

	training_squad_act(leader, "squad_open")
	late_catalog.ui_act("join_squad", list("squad" = REF(squad), "role" = "crew:Assistant"), late_ui)
	budget = new_wait_budget(1 MINUTES, "вход из каталога в группу без слота")
	while(entry.started == joined && wait_budget_tick(budget))
		continue
	while(!entry.started?.squad && wait_budget_tick(budget))
		continue
	var/datum/antag_training_session/plain = entry.started
	TEST_ASSERT(plain && plain != joined, "Второй вход создаёт сеанс.")
	allocated += plain
	TEST_ASSERT_EQUAL(plain.squad, squad, "В открытую группу входят и без сценарного слота.")
	TEST_ASSERT_NULL(scenario.slot_of(plain), "Без слота вошедший слот не занимает.")
	TEST_ASSERT_EQUAL(plain.role?.id, "crew:Assistant", "Роль входа - выбранная в каталоге.")

/// Стенд хаба подсказывает программе участника, где её тренировать, и показывает сценарии групп.
/datum/unit_test/antag_training_hub_board_route/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/creature/morph)
	TEST_ASSERT(session.prepare(), "Полигон готовится.")
	var/datum/antag_training_arena/arena = session.arena
	var/obj/structure/sign/antag_training_board/hub/board = antag_training_hub_find(arena.hub, /obj/structure/sign/antag_training_board/hub)
	TEST_ASSERT_NOTNULL(board, "В хабе есть стенд.")
	var/datum/antag_training_scenario/hunt = antag_training_scenarios()["morph_hunt"]
	var/examined = jointext(board.examine(session.current_body), "\n")
	TEST_ASSERT(findtext(examined, "Ваша программа «[session.program.name]»") && findtext(examined, hunt.name) && findtext(examined, antag_training_pad_preset_name("maint")), "Стенд ведёт морфа к его сценарию и пресету: [examined]")
	var/datum/antag_training_session/leader = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(leader.prepare(arena), "Второй участник входит.")
	training_squad_act(leader, "squad_create", list("name" = "Борт", "open" = TRUE))
	TEST_ASSERT_NOTNULL(leader.squad, "Группа собрана.")
	training_squad_act(leader, "scenario_pick", list("id" = "xeno"))
	var/datum/antag_training_scenario/picked = leader.squad.scenario
	TEST_ASSERT_NOTNULL(picked, "Группа выбрала сценарий.")
	examined = jointext(board.examine(session.current_body), "\n")
	TEST_ASSERT(findtext(examined, "«[picked.name]» у группы «Борт»") && findtext(examined, "набор в слоты"), "Стенд показывает сценарий группы и его фазу: [examined]")

/obj/structure/sign/antag_training_board/squads/probe
	var/mob/opened_by

/obj/structure/sign/antag_training_board/squads/probe/ui_interact(mob/user, datum/tgui/ui)
	opened_by = user

/obj/structure/sign/antag_training_board/squads/probe/Destroy()
	opened_by = null
	return ..()

/obj/machinery/computer/security/telescreen/antag_training/probe
	var/mob/opened_by

/obj/machinery/computer/security/telescreen/antag_training/probe/ui_interact(mob/user, datum/tgui/ui)
	opened_by = user

/obj/machinery/computer/security/telescreen/antag_training/probe/Destroy()
	opened_by = null
	return ..()
