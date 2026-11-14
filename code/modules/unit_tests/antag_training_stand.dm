/datum/unit_test/proc/grant_stand_rights(datum/antag_training_session/session, rights = NONE, mentor = FALSE)
	var/datum/client_interface/player = new
	if(rights)
		var/datum/admins/holder = new(null, null, FALSE, FALSE, TRUE)
		holder.rank = new /datum/admin_rank("training stand", rights)
		player.holder = holder
		allocated += holder
		allocated += holder.rank
	if(mentor)
		player.mentor_datum = new /datum/mentors("trainingstandmentor")
		allocated += player.mentor_datum
	session.current_body.mock_client = player
	return player

/datum/unit_test/proc/allocate_stand_ui(datum/antag_training_session/session)
	var/datum/tgui/ui = allocate(/datum/tgui, session.current_body, session, "AntagTraining")
	ui.status = UI_INTERACTIVE
	return ui

/datum/unit_test/proc/last_admin_log()
	return length(GLOB.admin_log_entries) ? GLOB.admin_log_entries[length(GLOB.admin_log_entries)] : ""

/// Без прав стенда нет ни в пульте, ни в действиях; кодер и ментор получают стенд со стоп-листом, админ - полный.
/datum/unit_test/antag_training_stand_access/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон подготовлен.")
	var/datum/tgui/ui = allocate_stand_ui(session)
	var/mob/body = session.current_body
	TEST_ASSERT_NULL(session.ui_data(body)["stand"], "Без прав пульт не показывает стенд.")
	antag_training_console_act(session, ui, "stand_toggle", list())
	TEST_ASSERT(!session.stand_mode, "Без прав стенд не включается.")
	antag_training_console_act(session, ui, "stand_spawn", list("path" = "/obj/item/crowbar"))
	TEST_ASSERT_NULL(locate(/obj/item/crowbar) in session.stand_spawn_turf(), "Без прав ничего не создаётся.")
	grant_stand_rights(session, mentor = TRUE)
	TEST_ASSERT_EQUAL(session.stand_access(), ANTAG_TRAINING_STAND_LIMITED, "Ментор получает стенд со стоп-листом.")
	grant_stand_rights(session, R_SPAWN)
	TEST_ASSERT_EQUAL(session.stand_access(), ANTAG_TRAINING_STAND_LIMITED, "Кодер с R_SPAWN получает стенд со стоп-листом.")
	grant_stand_rights(session, R_DEBUG)
	var/list/stand = session.ui_data(body)["stand"]
	TEST_ASSERT(stand && !stand["enabled"] && !stand["full"], "Кодер видит выключенный стенд без полных прав.")
	antag_training_console_act(session, ui, "stand_toggle", list())
	TEST_ASSERT(session.stand_mode, "Кодер включает стенд.")
	TEST_ASSERT(findtext(last_admin_log(), "стенд полигона: включил режим стенда"), "Включение стенда записано в лог администрации.")
	grant_stand_rights(session, R_ADMIN)
	TEST_ASSERT(session.ui_data(body)["stand"]["full"], "Админ получает полный стенд.")
	body.mock_client = null
	TEST_ASSERT_NULL(session.ui_data(body)["stand"], "Потеря прав прячет стенд.")
	TEST_ASSERT(!session.stand_mode, "Потеря прав выключает стенд.")

/// Стенд кодера и ментора удваивает лимиты своего сеанса, админа - снимает; другим участникам лимиты прежние.
/datum/unit_test/antag_training_stand_limits/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон подготовлен.")
	var/datum/tgui/ui = allocate_stand_ui(session)
	var/datum/antag_training_arena/arena = session.arena
	var/datum/antag_training_session/other = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(other.prepare(arena), "Второй участник вошёл.")
	for(var/index in 1 to ANTAG_TRAINING_TARGET_LIMIT)
		TEST_ASSERT(arena.spawn_creature("carp", "pve", FALSE, session), "Создана цель [index].")
	TEST_ASSERT_NULL(arena.spawn_creature("carp", "pve", FALSE, session), "Без стенда лимит целей действует.")
	grant_stand_rights(session, R_DEBUG)
	antag_training_console_act(session, ui, "stand_toggle", list())
	TEST_ASSERT_EQUAL(session.ui_data(session.current_body)["stand"]["limit_scale"], 2, "Пульт знает, что лимиты кодера удвоены.")
	for(var/index in ANTAG_TRAINING_TARGET_LIMIT + 1 to ANTAG_TRAINING_TARGET_LIMIT * 2)
		TEST_ASSERT(arena.spawn_creature("carp", "pve", FALSE, session), "Стенд кодера даёт цель [index].")
	TEST_ASSERT_NULL(arena.spawn_creature("carp", "pve", FALSE, session), "Стенд кодера не снимает лимит целей, а удваивает.")
	TEST_ASSERT_NULL(arena.spawn_creature("carp", "pve", FALSE, other), "Для других участников лимит остаётся.")
	var/limit_error = "Достигнут лимит объектов. Уберите ненужное или очистите свои объекты."
	var/turf/build_spot = get_turf(session.current_body)
	for(var/index in 1 to ANTAG_TRAINING_STRUCTURE_LIMIT)
		arena.placed_structures += WEAKREF(session.current_body)
	TEST_ASSERT_EQUAL(arena.construction_error(build_spot, other), limit_error, "Для других участников лимит построек остаётся.")
	TEST_ASSERT_NOTEQUAL(arena.construction_error(build_spot, session), limit_error, "Стенд кодера удваивает лимит построек.")
	for(var/index in 1 to ANTAG_TRAINING_STRUCTURE_LIMIT)
		arena.placed_structures += WEAKREF(session.current_body)
	TEST_ASSERT_EQUAL(arena.construction_error(build_spot, session), limit_error, "Удвоенный лимит построек тоже кончается.")
	grant_stand_rights(session, R_ADMIN)
	TEST_ASSERT_EQUAL(session.ui_data(session.current_body)["stand"]["limit_scale"], 0, "Пульт знает, что у админа лимитов нет.")
	TEST_ASSERT_NOTEQUAL(arena.construction_error(build_spot, session), limit_error, "Стенд админа снимает лимит построек.")
	TEST_ASSERT(arena.spawn_creature("carp", "pve", FALSE, session), "Стенд админа снимает лимит целей.")
	arena.placed_structures.Cut()
	session.current_body.mock_client = null

/// Стоп-лист кодера и ментора закрывает экономику, карго, записи, связь, гост-спавнеры и платы этих консолей.
/datum/unit_test/antag_training_stand_station_blacklist/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон подготовлен.")
	var/datum/tgui/ui = allocate_stand_ui(session)
	var/mob/body = session.current_body
	body.forceMove(session.arena.zones["pve"]["spawn"])
	grant_stand_rights(session, mentor = TRUE)
	antag_training_console_act(session, ui, "stand_toggle", list())
	var/list/station_types = list(
		/obj/machinery/computer/bank_machine,
		/obj/machinery/computer/cargo,
		/obj/machinery/computer/cargo/request,
		/obj/machinery/computer/bounty,
		/obj/machinery/computer/secure_data,
		/obj/machinery/computer/med_data,
		/obj/machinery/computer/prisoner,
		/obj/machinery/computer/message_monitor,
		/obj/machinery/computer/telecomms/monitor,
		/obj/machinery/telecomms/relay,
		/obj/machinery/computer/rdconsole,
		/obj/machinery/computer/apc_control,
		/obj/machinery/computer/crew,
		/obj/item/card/id/captains_spare,
		/obj/item/card/id/departmental_budget,
		/obj/item/station_charter,
		/obj/item/uplink,
		/obj/effect/mob_spawn,
		/obj/item/antag_spawner,
		/obj/item/slimepotion/slime/sentience,
		/obj/item/circuitboard/computer/cargo,
		/obj/item/circuitboard/computer/secure_data,
		/obj/item/circuitboard/computer/communications,
		/obj/item/circuitboard/machine/telecomms/relay,
	)
	for(var/path in station_types)
		antag_training_console_act(session, ui, "stand_search", list("query" = "[path]"))
		for(var/list/result as anything in session.ui_data(body)["stand"]["results"])
			TEST_ASSERT_NOTEQUAL(result["path"], "[path]", "Поиск стенда ментора не находит [path].")
	var/turf/spot = session.stand_spawn_turf()
	antag_training_console_act(session, ui, "stand_spawn", list("path" = "/obj/machinery/computer/cargo"))
	TEST_ASSERT_NULL(locate(/obj/machinery/computer/cargo) in spot, "Ментор не создаёт консоль карго.")
	TEST_ASSERT(findtext(last_admin_log(), "пытался создать запрещённый /obj/machinery/computer/cargo"), "Отказ записан в лог администрации.")
	grant_stand_rights(session, R_ADMIN)
	antag_training_console_act(session, ui, "stand_search", list("query" = "/obj/machinery/computer/cargo"))
	var/list/results = session.ui_data(body)["stand"]["results"]
	TEST_ASSERT(length(results) && results[1]["path"] == "/obj/machinery/computer/cargo", "Админ видит консоль карго.")
	body.mock_client = null

/// Созданное стендом - атом этого полигона и личный объект участника; очистка своего его убирает. Стоп-лист - только для не-админов.
/datum/unit_test/antag_training_stand_spawn/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон подготовлен.")
	var/datum/tgui/ui = allocate_stand_ui(session)
	var/datum/antag_training_arena/arena = session.arena
	var/mob/body = session.current_body
	body.forceMove(arena.zones["pve"]["spawn"])
	var/turf/spot = session.stand_spawn_turf()
	TEST_ASSERT_NOTNULL(spot, "Рядом есть место для создания.")
	grant_stand_rights(session, R_DEBUG)
	antag_training_console_act(session, ui, "stand_toggle", list())
	antag_training_console_act(session, ui, "stand_search", list("query" = "item/crowbar"))
	var/list/results = session.ui_data(body)["stand"]["results"]
	TEST_ASSERT(length(results) && results[1]["path"] == "/obj/item/crowbar", "Поиск находит тип по пути.")
	antag_training_console_act(session, ui, "stand_spawn", list("path" = "/obj/item/crowbar"))
	var/obj/item/crowbar/crowbar = locate() in spot
	TEST_ASSERT_NOTNULL(crowbar, "Стенд создаёт предмет рядом с участником.")
	TEST_ASSERT(crowbar.training_origin?.resolve() == arena, "Предмет - атом полигона.")
	TEST_ASSERT(crowbar.training_owner?.resolve() == session, "Предмет записан за участником.")
	TEST_ASSERT(findtext(last_admin_log(), "стенд полигона: создал /obj/item/crowbar"), "Создание записано в лог администрации.")
	antag_training_console_act(session, ui, "stand_spawn", list("path" = "/mob/living/simple_animal/hostile/carp"))
	var/mob/living/simple_animal/hostile/carp/carp = locate() in spot
	TEST_ASSERT(carp && (carp in arena.targets), "Существо стенда - цель полигона.")
	TEST_ASSERT(session.clear_personal_entities(), "Очистка своего проходит.")
	TEST_ASSERT(QDELETED(crowbar) && QDELETED(carp), "Очистка своего убирает созданное стендом.")
	antag_training_console_act(session, ui, "stand_search", list("query" = "effect/landmark"))
	TEST_ASSERT(!length(session.ui_data(body)["stand"]["results"]), "Кодер не видит типов из стоп-листа.")
	antag_training_console_act(session, ui, "stand_spawn", list("path" = "/obj/effect/landmark"))
	TEST_ASSERT_NULL(locate(/obj/effect/landmark) in spot, "Кодер не создаёт тип из стоп-листа.")
	TEST_ASSERT(findtext(last_admin_log(), "пытался создать запрещённый /obj/effect/landmark"), "Отказ записан в лог администрации.")
	antag_training_console_act(session, ui, "stand_spawn", list("path" = "/turf/open/floor/plasteel"))
	TEST_ASSERT(findtext(last_admin_log(), "пытался создать запрещённый /turf/open/floor/plasteel"), "Турфы стенд не создаёт никому.")
	grant_stand_rights(session, R_ADMIN)
	antag_training_console_act(session, ui, "stand_search", list("query" = "effect/landmark"))
	TEST_ASSERT(length(session.ui_data(body)["stand"]["results"]), "Админ видит весь список.")
	antag_training_console_act(session, ui, "stand_spawn", list("path" = "/obj/effect/landmark"))
	var/obj/effect/landmark/landmark = locate() in spot
	TEST_ASSERT(landmark?.training_origin?.resolve() == arena, "Админ создаёт тип из стоп-листа, и он остаётся атомом полигона.")
	qdel(landmark)
	body.mock_client = null

/// Стенд меняет должность и программу другому участнику и сбрасывает зону без голосования.
/datum/unit_test/antag_training_stand_members/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон подготовлен.")
	var/datum/tgui/ui = allocate_stand_ui(session)
	var/datum/antag_training_arena/arena = session.arena
	var/datum/antag_training_session/other = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(other.prepare(arena), "Второй участник вошёл.")
	antag_training_console_act(session, ui, "stand_role", list("id" = REF(other), "role" = "crew:Station Engineer"))
	TEST_ASSERT_EQUAL(other.role.id, ANTAG_TRAINING_ROLE_DEFAULT, "Без стенда чужая должность не меняется.")
	grant_stand_rights(session, mentor = TRUE)
	antag_training_console_act(session, ui, "stand_toggle", list())
	var/list/stand = session.ui_data(session.current_body)["stand"]
	TEST_ASSERT_EQUAL(length(stand["members"]), 2, "Стенд перечисляет участников.")
	antag_training_console_act(session, ui, "stand_role", list("id" = REF(other), "role" = "crew:Station Engineer"))
	TEST_ASSERT_EQUAL(other.role.id, "crew:Station Engineer", "Стенд меняет должность другому участнику.")
	TEST_ASSERT(findtext(last_admin_log(), "сменил должность участнику"), "Смена должности записана в лог администрации.")
	antag_training_console_act(session, ui, "stand_program", list("id" = REF(other), "program" = "[/datum/antag_training_program/antag/traitor]"))
	TEST_ASSERT_EQUAL(other.program.type, /datum/antag_training_program/antag/traitor, "Стенд меняет программу другому участнику.")
	var/mob/living/carp = arena.spawn_creature("carp", "pve", FALSE, other)
	TEST_ASSERT_NOTNULL(carp, "В зоне есть цель.")
	antag_training_console_act(session, ui, "stand_reset", list("zone" = "pve"))
	TEST_ASSERT_NULL(arena.pending_reset_zone, "Сброс стенда не ждёт голосования.")
	wait_for_qdeleted(carp, 30 SECONDS)
	TEST_ASSERT(QDELETED(carp), "Зона сброшена без голосования.")
	TEST_ASSERT(findtext(last_admin_log(), "сбросил без голосования зону pve"), "Сброс записан в лог администрации.")
	session.current_body.mock_client = null

/// Стенд снимает чужую бронь сектора и распускает чужую группу; без стенда эти действия не проходят.
/datum/unit_test/antag_training_stand_force_release/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон подготовлен.")
	var/datum/tgui/ui = allocate_stand_ui(session)
	var/datum/antag_training_arena/arena = session.arena
	var/datum/antag_training_session/leader = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(leader.prepare(arena), "Лидер группы вошёл.")
	training_squad_act(leader, "squad_create", list("name" = "Альфа"))
	var/datum/antag_training_squad/squad = leader.squad
	TEST_ASSERT_NOTNULL(squad, "Группа собрана.")
	TEST_ASSERT(training_squad_book(leader, "dark"), "Группа заняла тёмный сектор.")
	var/datum/antag_training_sector/sector = arena.sectors["dark"]
	antag_training_console_act(session, ui, "stand_release", list("kind" = "booking", "id" = "dark"))
	TEST_ASSERT_EQUAL(sector.booked_by, squad, "Без стенда чужую бронь не снять.")
	grant_stand_rights(session, mentor = TRUE)
	antag_training_console_act(session, ui, "stand_toggle", list())
	var/list/squads = session.ui_data(session.current_body)["stand"]["squads"]
	TEST_ASSERT(length(squads) == 1 && squads[1]["sector_id"] == "dark", "Стенд видит группу и её бронь.")
	antag_training_console_act(session, ui, "stand_release", list("kind" = "booking", "id" = "dark"))
	TEST_ASSERT_NULL(sector.booked_by, "Стенд снимает чужую бронь.")
	TEST_ASSERT_NULL(squad.sector, "Группа больше не держит сектор.")
	TEST_ASSERT(findtext(last_admin_log(), "снял бронь сектора"), "Снятие брони записано в лог администрации.")
	antag_training_console_act(session, ui, "stand_release", list("kind" = "squad", "id" = REF(squad)))
	TEST_ASSERT(QDELETED(squad), "Стенд распускает чужую группу.")
	TEST_ASSERT_NULL(leader.squad, "Лидер больше не в группе.")
	TEST_ASSERT(findtext(last_admin_log(), "распустил группу «Альфа»"), "Роспуск записан в лог администрации.")
	session.current_body.mock_client = null
