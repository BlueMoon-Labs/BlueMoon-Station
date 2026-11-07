/datum/unit_test/proc/training_squad_sessions(count)
	var/datum/antag_training_session/first = allocate_training_session(/datum/antag_training_program/free)
	if(!first.prepare())
		return null
	. = list(first)
	for(var/index in 2 to count)
		var/datum/antag_training_session/next = allocate_training_session(/datum/antag_training_program/free)
		if(!next.prepare(first.arena))
			return null
		. += next

/datum/unit_test/proc/training_squad_act(datum/antag_training_session/session, action, list/params = list())
	var/datum/tgui/ui = allocate(/datum/tgui, session.current_body, session, "AntagTraining")
	antag_training_console_act(session, ui, action, params)

/datum/unit_test/proc/training_squad_book(datum/antag_training_session/leader, sector_id)
	training_squad_act(leader, "booking_book", list("id" = sector_id))
	var/datum/antag_training_sector/sector = leader.arena.sectors[sector_id]
	return sector.booked_by && wait_for_var(sector, "state", ANTAG_TRAINING_SECTOR_READY, 30 SECONDS)

/// Группа по приглашению: принять за 30 секунд, после срока приглашение не действует, закрытая группа без приглашения не пускает.
/datum/unit_test/antag_training_squad_invite/Run()
	var/list/sessions = training_squad_sessions(3)
	TEST_ASSERT(length(sessions) == 3, "Три участника на полигоне.")
	var/datum/antag_training_session/leader = sessions[1]
	var/datum/antag_training_session/guest = sessions[2]
	var/datum/antag_training_session/late = sessions[3]
	training_squad_act(leader, "squad_create", list("name" = "<b>Альфа</b>", "open" = FALSE))
	var/datum/antag_training_squad/squad = leader.squad
	TEST_ASSERT_NOTNULL(squad, "Пульт собирает группу.")
	TEST_ASSERT_EQUAL(squad.leader, leader, "Основатель - лидер.")
	TEST_ASSERT(!findtext(squad.name, "<"), "Имя группы без разметки: [squad.name].")
	TEST_ASSERT(!squad.open, "Группа по приглашениям.")
	training_squad_act(late, "squad_join", list("id" = REF(squad)))
	TEST_ASSERT_NULL(late.squad, "В закрытую группу без приглашения не войти.")
	training_squad_act(guest, "squad_invite", list("id" = REF(leader)))
	TEST_ASSERT(!length(squad.invites), "Приглашает только лидер.")
	training_squad_act(leader, "squad_invite", list("id" = REF(guest)))
	var/list/data = guest.ui_data(guest.current_body)
	var/list/invites = data["squad_invites"]
	TEST_ASSERT_EQUAL(length(invites), 1, "Приглашённый видит приглашение в пульте.")
	TEST_ASSERT(abs(invites[1]["remaining"] - ANTAG_TRAINING_SQUAD_INVITE / (1 SECONDS)) <= 1, "На ответ [ANTAG_TRAINING_SQUAD_INVITE / (1 SECONDS)] секунд, а не [invites[1]["remaining"]].")
	training_squad_act(guest, "squad_accept", list("id" = REF(squad)))
	TEST_ASSERT_EQUAL(guest.squad, squad, "Приглашённый принимает приглашение.")
	TEST_ASSERT(!(guest in squad.invites), "Принятое приглашение снято.")
	training_squad_act(leader, "squad_invite", list("id" = REF(late)))
	squad.invites[late] = world.time
	training_squad_act(late, "squad_accept", list("id" = REF(squad)))
	TEST_ASSERT_NULL(late.squad, "Просроченное приглашение не принять.")
	TEST_ASSERT(!(late in squad.invites), "Просроченное приглашение убрано.")
	training_squad_act(late, "squad_create", list("open" = TRUE))
	TEST_ASSERT_NOTNULL(late.squad, "Третий собирает свою группу.")
	TEST_ASSERT_NOTEQUAL(late.squad.name, squad.name, "У групп разные имена по умолчанию.")
	training_squad_act(leader, "squad_invite", list("id" = REF(late)))
	TEST_ASSERT(!(late in squad.invites), "Участника чужой группы не пригласить.")

/// Ушёл лидер - лидирует следующий; пустая группа распускается; выход с полигона убирает из группы.
/datum/unit_test/antag_training_squad_leader/Run()
	var/list/sessions = training_squad_sessions(3)
	TEST_ASSERT(length(sessions) == 3, "Три участника на полигоне.")
	var/datum/antag_training_session/first = sessions[1]
	var/datum/antag_training_session/second = sessions[2]
	var/datum/antag_training_session/third = sessions[3]
	var/datum/antag_training_arena/arena = first.arena
	training_squad_act(first, "squad_create", list("open" = TRUE))
	var/datum/antag_training_squad/squad = first.squad
	training_squad_act(second, "squad_join", list("id" = REF(squad)))
	training_squad_act(third, "squad_join", list("id" = REF(squad)))
	TEST_ASSERT_EQUAL(length(squad.members), 3, "В открытую группу входят сами.")
	training_squad_act(first, "squad_leave")
	TEST_ASSERT_NULL(first.squad, "Лидер вышел.")
	TEST_ASSERT_EQUAL(squad.leader, second, "Лидером стал следующий участник.")
	training_squad_act(third, "squad_kick", list("id" = REF(second)))
	TEST_ASSERT_EQUAL(second.squad, squad, "Не лидер не исключает.")
	training_squad_act(second, "squad_leader", list("id" = REF(third)))
	TEST_ASSERT_EQUAL(squad.leader, third, "Лидер передаёт главенство.")
	training_squad_act(third, "squad_kick", list("id" = REF(second)))
	TEST_ASSERT_NULL(second.squad, "Лидер исключает участника.")
	training_squad_act(third, "squad_leave")
	TEST_ASSERT(QDELETED(squad), "Пустая группа распущена.")
	TEST_ASSERT(!length(arena.squads), "Распущенной группы нет в списке.")
	training_squad_act(first, "squad_create", list("open" = TRUE))
	var/datum/antag_training_squad/next_squad = first.squad
	training_squad_act(second, "squad_join", list("id" = REF(next_squad)))
	first.finish()
	TEST_ASSERT(!QDELETED(next_squad), "Группа с оставшимся участником живёт.")
	TEST_ASSERT_EQUAL(next_squad.leader, second, "Выход лидера с полигона передаёт главенство.")
	TEST_ASSERT(!(first in next_squad.members), "Вышедший с полигона не в группе.")
	second.finish()
	TEST_ASSERT(QDELETED(next_squad), "Последний вышел с полигона - группа распущена.")

/// Бронь: отказ при чужих внутри, вход только группе, простой не выгружает, сброс голосует только группа.
/datum/unit_test/antag_training_squad_booking/Run()
	var/list/sessions = training_squad_sessions(3)
	TEST_ASSERT(length(sessions) == 3, "Три участника на полигоне.")
	var/datum/antag_training_session/leader = sessions[1]
	var/datum/antag_training_session/member = sessions[2]
	var/datum/antag_training_session/outsider = sessions[3]
	var/datum/antag_training_arena/arena = leader.arena
	var/datum/antag_training_sector/sector = arena.sectors["dark"]
	training_squad_act(leader, "squad_create", list("open" = TRUE))
	var/datum/antag_training_squad/squad = leader.squad
	training_squad_act(member, "squad_join", list("id" = REF(squad)))
	training_squad_act(member, "booking_book", list("id" = "dark"))
	TEST_ASSERT_NULL(sector.booked_by, "Бронирует только лидер.")
	TEST_ASSERT(sector.load(), "Сектор загружен.")
	outsider.current_body.forceMove(sector.spawn_turf())
	training_squad_act(leader, "booking_book", list("id" = "dark"))
	TEST_ASSERT_NULL(sector.booked_by, "Чужой внутри - отказ.")
	TEST_ASSERT(findtext(leader.last_feedback, outsider.squad_name()), "В отказе названо имя чужого: [leader.last_feedback].")
	outsider.current_body.forceMove(arena.entry_turf)
	TEST_ASSERT(training_squad_book(leader, "dark"), "Свободный сектор занят группой.")
	TEST_ASSERT_EQUAL(squad.sector, sector, "Группа знает свою бронь.")
	training_squad_act(outsider, "sector_enter", list("id" = "dark"))
	var/list/budget = new_wait_budget(2 SECONDS, "отказ во входе")
	while(!findtext(outsider.last_feedback, squad.name) && wait_budget_tick(budget))
		continue
	TEST_ASSERT(!arena.inside_bounds(get_turf(outsider.current_body), sector.bounds), "Чужой не входит в занятый сектор.")
	TEST_ASSERT(findtext(outsider.last_feedback, squad.name), "Чужому сказано, кто занял сектор: [outsider.last_feedback].")
	training_squad_act(member, "sector_enter", list("id" = "dark"))
	budget = new_wait_budget(30 SECONDS, "участник группы в секторе")
	while(!arena.inside_bounds(get_turf(member.current_body), sector.bounds) && wait_budget_tick(budget))
		continue
	TEST_ASSERT(arena.inside_bounds(get_turf(member.current_body), sector.bounds), "Участник группы входит.")
	member.current_body.forceMove(arena.entry_turf)
	sector.last_occupied_at = world.time - ANTAG_TRAINING_SECTOR_IDLE - 1 SECONDS
	sector.check_idle()
	TEST_ASSERT_EQUAL(sector.state, ANTAG_TRAINING_SECTOR_READY, "Занятый группой сектор не выгружается по простою.")
	training_squad_act(outsider, "reset_zone", list("zone" = "dark"))
	TEST_ASSERT_NULL(arena.pending_reset_zone, "Чужой не запрашивает сброс занятого сектора.")
	training_squad_act(member, "reset_zone", list("zone" = "dark"))
	TEST_ASSERT_NULL(arena.pending_reset_zone, "Сброс занятого сектора запускает лидер.")
	arena.next_reset_request_at = 0
	training_squad_act(leader, "reset_zone", list("zone" = "dark"))
	TEST_ASSERT_EQUAL(arena.pending_reset_zone, "dark", "Лидер запрашивает сброс.")
	TEST_ASSERT(!(outsider in arena.reset_votes), "Чужой не голосует.")
	var/list/outsider_data = outsider.ui_data(outsider.current_body)
	var/list/vote = outsider_data["reset_vote"]
	TEST_ASSERT_EQUAL(vote["total"], 2, "Пульт считает голоса только группы.")
	TEST_ASSERT(!vote["can_vote"] && !vote["can_cancel"], "Чужому пульт не даёт голосовать и отменять.")
	training_squad_act(outsider, "reset_cancel")
	TEST_ASSERT_EQUAL(arena.pending_reset_zone, "dark", "Чужой не отменяет сброс группы.")
	training_squad_act(member, "reset_approve")
	TEST_ASSERT_NULL(arena.pending_reset_zone, "Согласия группы хватает для сброса.")
	TEST_ASSERT(wait_for_var(arena, "resetting", FALSE, 30 SECONDS), "Сброс завершён.")
	TEST_ASSERT_EQUAL(sector.state, ANTAG_TRAINING_SECTOR_READY, "Сектор перезагружен.")
	TEST_ASSERT_EQUAL(sector.booked_by, squad, "Сброс не снимает бронь.")
	training_squad_act(member, "booking_release")
	TEST_ASSERT_EQUAL(sector.booked_by, squad, "Освобождает лидер.")
	training_squad_act(leader, "booking_release")
	TEST_ASSERT_NULL(sector.booked_by, "Лидер освободил сектор.")
	TEST_ASSERT_NULL(squad.sector, "У группы нет брони.")
	training_squad_act(outsider, "sector_enter", list("id" = "dark"))
	budget = new_wait_budget(30 SECONDS, "чужой в освобождённом секторе")
	while(!arena.inside_bounds(get_turf(outsider.current_body), sector.bounds) && wait_budget_tick(budget))
		continue
	TEST_ASSERT(arena.inside_bounds(get_turf(outsider.current_body), sector.bounds), "Освобождённый сектор открыт всем.")
	outsider.current_body.forceMove(arena.entry_turf)
	TEST_ASSERT(training_squad_book(leader, "dark"), "Группа снова занимает сектор.")
	training_squad_act(leader, "squad_leave")
	training_squad_act(member, "squad_leave")
	TEST_ASSERT(QDELETED(squad), "Группа распущена.")
	TEST_ASSERT_NULL(sector.booked_by, "Роспуск снимает бронь.")

/// Потолок брони - все сектора, кроме двух; незагруженный сектор при брони загружается.
/datum/unit_test/antag_training_squad_cap/Run()
	var/list/sessions = training_squad_sessions(2)
	TEST_ASSERT(length(sessions) == 2, "Два участника на полигоне.")
	var/datum/antag_training_session/first = sessions[1]
	var/datum/antag_training_session/second = sessions[2]
	var/datum/antag_training_arena/arena = first.arena
	TEST_ASSERT_EQUAL(arena.booking_limit(), length(arena.sectors) - ANTAG_TRAINING_BOOKING_FREE_SECTORS, "Свободными остаются [ANTAG_TRAINING_BOOKING_FREE_SECTORS] сектора.")
	var/list/all_sectors = arena.sectors.Copy()
	arena.sectors = list("dark" = all_sectors["dark"], "atmos" = all_sectors["atmos"], "eva" = all_sectors["eva"])
	training_squad_act(first, "squad_create", list("open" = TRUE))
	training_squad_act(second, "squad_create", list("open" = TRUE))
	var/datum/antag_training_sector/dark = arena.sectors["dark"]
	var/datum/antag_training_sector/atmos = arena.sectors["atmos"]
	TEST_ASSERT_EQUAL(dark.state, ANTAG_TRAINING_SECTOR_UNLOADED, "Сектор ещё не загружен.")
	var/booked = training_squad_book(first, "dark")
	training_squad_act(first, "booking_book", list("id" = "atmos"))
	var/second_booking = atmos.booked_by
	training_squad_act(second, "booking_book", list("id" = "atmos"))
	var/over_cap = atmos.booked_by
	var/list/data = second.ui_data(second.current_body)
	arena.sectors = all_sectors
	TEST_ASSERT(booked, "Бронь загружает незагруженный сектор.")
	TEST_ASSERT_NULL(second_booking, "У группы одна бронь.")
	TEST_ASSERT_NULL(over_cap, "Сверх потолка не бронируется.")
	TEST_ASSERT(findtext(second.last_feedback, "Занято секторов"), "Отказ объясняет потолок: [second.last_feedback].")
	TEST_ASSERT(data["booking_used"] == 1 && data["booking_max"] == 1, "Пульт показывает занятые и доступные брони.")
	var/list/bookings = data["bookings"]
	var/list/dark_entry = bookings["dark"]
	TEST_ASSERT_EQUAL(dark_entry["squad"], first.squad.name, "Пульт показывает, кто занял сектор.")

/// 40 минут брони, продление только без очереди, снятие по сроку и по простою группы.
/datum/unit_test/antag_training_squad_limits/Run()
	var/list/sessions = training_squad_sessions(2)
	TEST_ASSERT(length(sessions) == 2, "Два участника на полигоне.")
	var/datum/antag_training_session/leader = sessions[1]
	var/datum/antag_training_session/waiting = sessions[2]
	var/datum/antag_training_arena/arena = leader.arena
	var/datum/antag_training_sector/sector = arena.sectors["dark"]
	training_squad_act(leader, "squad_create", list("open" = FALSE))
	var/datum/antag_training_squad/squad = leader.squad
	training_squad_act(waiting, "waitlist_join", list("id" = "dark"))
	TEST_ASSERT(!length(sector.waitlist), "Очередь только к занятому сектору.")
	TEST_ASSERT(training_squad_book(leader, "dark"), "Сектор занят.")
	TEST_ASSERT(abs(sector.booked_until - world.time - ANTAG_TRAINING_BOOKING_LIMIT) < 1 SECONDS, "Бронь на [ANTAG_TRAINING_BOOKING_LIMIT / (1 MINUTES)] минут.")
	sector.booked_until = world.time + 1 MINUTES
	training_squad_act(leader, "booking_extend")
	TEST_ASSERT(abs(sector.booked_until - world.time - ANTAG_TRAINING_BOOKING_LIMIT) < 1 SECONDS, "Без очереди бронь продлевается.")
	training_squad_act(waiting, "waitlist_join", list("id" = "dark"))
	TEST_ASSERT(waiting in sector.waitlist, "Чужой встаёт в очередь.")
	var/list/waiting_data = waiting.ui_data(waiting.current_body)
	var/list/bookings = waiting_data["bookings"]
	var/list/entry = bookings["dark"]
	TEST_ASSERT(entry["on_waitlist"] && (waiting.squad_name() in entry["waitlist"]), "Очередь видна в пульте.")
	sector.booked_until = world.time + 1 MINUTES
	training_squad_act(leader, "booking_extend")
	TEST_ASSERT(abs(sector.booked_until - world.time - 1 MINUTES) < 1 SECONDS, "С очередью бронь не продлевается.")
	training_squad_act(waiting, "waitlist_leave", list("id" = "dark"))
	TEST_ASSERT(!length(sector.waitlist), "Из очереди можно выйти.")
	training_squad_act(waiting, "waitlist_join", list("id" = "dark"))
	leader.current_body.forceMove(sector.spawn_turf())
	sector.booked_until = world.time
	sector.check_booking()
	TEST_ASSERT_NULL(sector.booked_by, "Бронь снимается по сроку.")
	TEST_ASSERT(!length(sector.waitlist), "После снятия очередь оповещена и пуста.")
	leader.current_body.forceMove(arena.entry_turf)
	TEST_ASSERT(training_squad_book(leader, "dark"), "Сектор занят снова.")
	leader.current_body.forceMove(sector.spawn_turf())
	sector.booking_seen_at = world.time - ANTAG_TRAINING_BOOKING_IDLE - 1 SECONDS
	sector.check_booking()
	TEST_ASSERT_EQUAL(sector.booked_by, squad, "Группа в секторе - бронь держится.")
	TEST_ASSERT_EQUAL(sector.booking_seen_at, world.time, "Присутствие группы замечено.")
	leader.current_body.forceMove(arena.entry_turf)
	sector.booking_seen_at = world.time - ANTAG_TRAINING_BOOKING_IDLE - 1 SECONDS
	sector.check_booking()
	TEST_ASSERT_NULL(sector.booked_by, "Без группы [ANTAG_TRAINING_BOOKING_IDLE / (1 MINUTES)] минут бронь снимается.")

/// Освободившийся сектор придержан за первой группой из очереди: чужим отказ с причиной и сроком, неиспользованное окно уходит следующей группе.
/datum/unit_test/antag_training_squad_waitlist_priority/Run()
	var/list/sessions = training_squad_sessions(4)
	TEST_ASSERT(length(sessions) == 4, "Четыре участника на полигоне.")
	var/datum/antag_training_session/holder = sessions[1]
	var/datum/antag_training_session/first = sessions[2]
	var/datum/antag_training_session/second = sessions[3]
	var/datum/antag_training_session/loner = sessions[4]
	var/datum/antag_training_sector/sector = holder.arena.sectors["dark"]
	for(var/datum/antag_training_session/leader as anything in list(holder, first, second))
		training_squad_act(leader, "squad_create", list("open" = FALSE))
	TEST_ASSERT(training_squad_book(holder, "dark"), "Сектор занят.")
	for(var/datum/antag_training_session/waiting as anything in list(loner, first, second))
		training_squad_act(waiting, "waitlist_join", list("id" = "dark"))
	training_squad_act(holder, "booking_release")
	TEST_ASSERT_NULL(sector.booked_by, "Лидер освободил сектор.")
	var/list/entry = second.ui_data(second.current_body)["bookings"]["dark"]
	TEST_ASSERT_EQUAL(entry["priority"], first.squad.name, "Пульт называет группу, за которой придержан сектор.")
	TEST_ASSERT(abs(entry["priority_remaining"] - ANTAG_TRAINING_BOOKING_PRIORITY / (1 SECONDS)) <= 1, "Окно [ANTAG_TRAINING_BOOKING_PRIORITY / (1 SECONDS)] секунд, а не [entry["priority_remaining"]].")
	training_squad_act(second, "booking_book", list("id" = "dark"))
	TEST_ASSERT_NULL(sector.booked_by, "Вторая группа очереди не занимает сектор в окне первой.")
	TEST_ASSERT(findtext(second.last_feedback, first.squad.name) && (findtext(second.last_feedback, "1:00") || findtext(second.last_feedback, "0:59")), "Отказ называет группу и срок: [second.last_feedback].")
	sector.priority_until = world.time
	training_squad_act(second, "booking_book", list("id" = "dark"))
	TEST_ASSERT_EQUAL(sector.booked_by, second.squad, "Неиспользованное окно перешло к следующей группе очереди.")
	training_squad_act(holder, "waitlist_join", list("id" = "dark"))
	training_squad_act(first, "waitlist_join", list("id" = "dark"))
	training_squad_act(second, "booking_release")
	training_squad_act(first, "booking_book", list("id" = "dark"))
	TEST_ASSERT_NULL(sector.booked_by, "Окно у первой группы новой очереди, вторая ждёт.")
	training_squad_act(holder, "booking_book", list("id" = "dark"))
	TEST_ASSERT_EQUAL(sector.booked_by, holder.squad, "Первая группа очереди занимает сектор в своё окно.")
	TEST_ASSERT_NULL(sector.priority_squad, "Бронь закрывает окно.")
	TEST_ASSERT(first in sector.waitlist, "Группа, ждавшая следом, снова в очереди к сектору.")
	training_squad_act(holder, "booking_release")
	TEST_ASSERT_EQUAL(sector.priority_squad, first.squad, "Освободившийся сектор придержан за ней.")

/// Чужую бронь не обойти ни кнопкой зоны пульта, ни целью в чужом секторе, ни свитком мага.
/datum/unit_test/antag_training_squad_booking_bypass/Run()
	var/list/sessions = training_squad_sessions(3)
	TEST_ASSERT(length(sessions) == 3, "Три участника на полигоне.")
	var/datum/antag_training_session/leader = sessions[1]
	var/datum/antag_training_session/mate = sessions[2]
	var/datum/antag_training_session/outsider = sessions[3]
	var/datum/antag_training_arena/arena = leader.arena
	var/datum/antag_training_sector/sector = arena.sectors["dark"]
	training_squad_act(leader, "squad_create", list("name" = "Броня", "open" = TRUE))
	training_squad_act(mate, "squad_join", list("id" = REF(leader.squad)))
	TEST_ASSERT(training_squad_book(leader, "dark"), "Группа занимает тёмный сектор.")
	var/mob/living/carbon/human/body = outsider.current_body
	training_squad_act(outsider, "move", list("zone" = "dark"))
	TEST_ASSERT(!arena.inside_bounds(get_turf(body), sector.bounds), "Кнопка зоны пульта не ведёт в чужой сектор.")
	TEST_ASSERT(findtext(outsider.last_feedback, "Броня"), "Отказ называет группу: [outsider.last_feedback].")
	training_squad_act(mate, "move", list("zone" = "dark"))
	TEST_ASSERT(arena.inside_bounds(get_turf(mate.current_body), sector.bounds), "Своя группа проходит по кнопке зоны.")
	mate.current_body.forceMove(arena.entry_turf)

	var/targets_before = length(arena.targets)
	training_squad_act(outsider, "spawn", list("id" = "carp", "zone" = "dark"))
	TEST_ASSERT_EQUAL(length(arena.targets), targets_before, "Чужой не создаёт цели в занятом секторе.")
	TEST_ASSERT(findtext(outsider.last_feedback, "Броня"), "Отказ в цели называет группу: [outsider.last_feedback].")
	training_squad_act(mate, "spawn", list("id" = "carp", "zone" = "dark"))
	TEST_ASSERT_EQUAL(length(arena.targets), targets_before + 1, "Группа создаёт цели в своём секторе.")

	body.drop_all_held_items()
	var/obj/item/teleportation_scroll/training/probe/scroll = allocate(/obj/item/teleportation_scroll/training/probe, get_turf(body))
	TEST_ASSERT(body.put_in_hands(scroll), "Чужой берёт учебный свиток.")
	scroll.answer = sector.name
	usr = body
	scroll.Topic("spell_teleport=1", list("spell_teleport" = "1"))
	usr = null
	TEST_ASSERT(!(sector.name in scroll.offered), "Свиток не предлагает чужой занятый сектор.")
	TEST_ASSERT(arena.zones["melee"]["name"] in scroll.offered, "Остальные зоны в списке свитка.")
	TEST_ASSERT(!arena.inside_bounds(get_turf(body), sector.bounds), "Свиток не переносит в чужой сектор.")

/// Пока идёт партия группы в её секторе, бронь не снимается ни по сроку, ни по простою; после партии снимается.
/datum/unit_test/antag_training_squad_booking_scenario/Run()
	var/list/sessions = training_scenario_squad(2)
	TEST_ASSERT(length(sessions) == 2, "Группа из двух участников.")
	var/datum/antag_training_session/leader = sessions[1]
	var/datum/antag_training_session/member = sessions[2]
	var/datum/antag_training_arena/arena = leader.arena
	var/datum/antag_training_scenario/scenario = training_scenario_pick(leader, "custom", "dark")
	TEST_ASSERT_NOTNULL(scenario, "Своя сборка в тёмном секторе.")
	training_squad_act(leader, "scenario_slot_add", list("side" = "a", "role" = "crew:Assistant", "program" = ""))
	training_squad_act(leader, "scenario_slot_add", list("side" = "b", "role" = "crew:Assistant", "program" = ""))
	TEST_ASSERT_EQUAL(length(scenario.slots), 2, "Два слота.")
	training_squad_act(leader, "scenario_take", list("slot" = REF(scenario.slots[1])))
	training_squad_act(member, "scenario_take", list("slot" = REF(scenario.slots[2])))
	training_squad_act(leader, "scenario_start")
	TEST_ASSERT(training_scenario_wait(scenario, ANTAG_TRAINING_SCENARIO_RUNNING), "Партия идёт.")
	var/datum/antag_training_sector/sector = arena.sectors["dark"]
	for(var/datum/antag_training_session/player as anything in sessions)
		player.current_body.forceMove(arena.entry_turf)
	sector.booked_until = world.time
	sector.booking_seen_at = world.time - ANTAG_TRAINING_BOOKING_IDLE - 1 SECONDS
	sector.check_booking()
	TEST_ASSERT_EQUAL(sector.booked_by, leader.squad, "Идущая партия держит бронь сектора.")
	training_squad_act(leader, "scenario_end")
	TEST_ASSERT(training_scenario_wait(scenario, ANTAG_TRAINING_SCENARIO_SUMMARY, 10 SECONDS), "Партия подведена.")
	sector.check_booking()
	TEST_ASSERT_NULL(sector.booked_by, "После партии вышедший срок снимает бронь.")

/// Голоса за сброс сектора группы идут за составом: новичок голосует, ушедший не держит сброс.
/datum/unit_test/antag_training_squad_reset_votes/Run()
	var/list/sessions = training_squad_sessions(3)
	TEST_ASSERT(length(sessions) == 3, "Три участника на полигоне.")
	var/datum/antag_training_session/leader = sessions[1]
	var/datum/antag_training_session/quitter = sessions[2]
	var/datum/antag_training_session/newcomer = sessions[3]
	var/datum/antag_training_arena/arena = leader.arena
	training_squad_act(leader, "squad_create", list("open" = TRUE))
	var/datum/antag_training_squad/squad = leader.squad
	training_squad_act(quitter, "squad_join", list("id" = REF(squad)))
	TEST_ASSERT(training_squad_book(leader, "dark"), "Группа занимает сектор.")
	training_squad_act(leader, "reset_zone", list("zone" = "dark"))
	TEST_ASSERT_EQUAL(arena.pending_reset_zone, "dark", "Лидер запрашивает сброс.")
	training_squad_act(newcomer, "squad_join", list("id" = REF(squad)))
	training_squad_act(newcomer, "reset_approve")
	TEST_ASSERT(arena.reset_votes[newcomer], "Новичок группы голосует за сброс.")
	TEST_ASSERT_EQUAL(arena.pending_reset_zone, "dark", "Без голоса второго сброс ждёт.")
	training_squad_act(quitter, "squad_leave")
	TEST_ASSERT_NULL(arena.pending_reset_zone, "Ушедший из группы сброс не держит.")
	TEST_ASSERT(wait_for_var(arena, "resetting", FALSE, 30 SECONDS), "Сброс завершён.")

/datum/unit_test/antag_training_squad_name_filter
	var/list/previous_filter

/// Имя группы проходит фильтр слов; смена «Открытая группа» объявляется не чаще кулдауна.
/datum/unit_test/antag_training_squad_name_filter/Run()
	previous_filter = config.ic_filter_regex
	config.ic_filter_regex = list("запретка")
	var/list/sessions = training_squad_sessions(1)
	TEST_ASSERT(length(sessions) == 1, "Участник на полигоне.")
	var/datum/antag_training_session/leader = sessions[1]
	training_squad_act(leader, "squad_create", list("name" = "Отряд запретка", "open" = TRUE))
	TEST_ASSERT_NULL(leader.squad, "Имя с запрещённым словом не принимается.")
	TEST_ASSERT(findtext(leader.last_feedback, "запрещённое слово"), "Отказ объясняет причину: [leader.last_feedback].")
	training_squad_act(leader, "squad_create", list("name" = "Длинное имя группы, которое не влезает", "open" = TRUE))
	var/datum/antag_training_squad/squad = leader.squad
	TEST_ASSERT_NOTNULL(squad, "Группа с длинным именем собрана.")
	TEST_ASSERT(length_char(squad.name) <= ANTAG_TRAINING_SQUAD_NAME_LENGTH, "Имя обрезано до [ANTAG_TRAINING_SQUAD_NAME_LENGTH] символов: [squad.name].")
	GLOB.unit_test_chat_capture = list()
	training_squad_act(leader, "squad_open")
	training_squad_act(leader, "squad_open")
	var/notices = 0
	for(var/list/entry as anything in GLOB.unit_test_chat_capture)
		if(findtext(entry[2], "присоединиться может любой") || findtext(entry[2], "только по приглашениям"))
			notices++
	TEST_ASSERT(squad.open, "Две смены вернули группу открытой.")
	TEST_ASSERT_EQUAL(notices, 1, "Частые смены открытости не засыпают группу сообщениями.")

/datum/unit_test/antag_training_squad_name_filter/Destroy()
	config.ic_filter_regex = previous_filter
	GLOB.unit_test_chat_capture = null
	return ..()

/// Участники группы управляют целями и вещами друг друга, чужие - нет.
/datum/unit_test/antag_training_squad_ownership/Run()
	var/list/sessions = training_squad_sessions(3)
	TEST_ASSERT(length(sessions) == 3, "Три участника на полигоне.")
	var/datum/antag_training_session/owner = sessions[1]
	var/datum/antag_training_session/mate = sessions[2]
	var/datum/antag_training_session/stranger = sessions[3]
	var/datum/antag_training_arena/arena = owner.arena
	var/mob/living/target = arena.spawn_creature("human", "pve", FALSE, owner)
	TEST_ASSERT_NOTNULL(target, "Цель создана.")
	var/obj/item/tool = arena.issue_item(/obj/item/crowbar, get_turf(target), 1, owner)
	TEST_ASSERT_NOTNULL(tool, "Вещь выдана.")
	TEST_ASSERT(!mate.can_manage_target(target), "До группы чужая цель недоступна.")
	TEST_ASSERT_NOTNULL(arena.foreign_part_refusal(tool, mate, mate.current_body), "До группы чужая вещь под защитой.")
	training_squad_act(owner, "squad_create", list("open" = TRUE))
	training_squad_act(mate, "squad_join", list("id" = REF(owner.squad)))
	TEST_ASSERT(mate.can_manage_target(target), "Участник группы управляет целью товарища.")
	TEST_ASSERT_NULL(arena.foreign_part_refusal(tool, mate, mate.current_body), "Вещь товарища по группе не защищена от своих.")
	TEST_ASSERT(!stranger.can_manage_target(target), "Чужой не управляет целью группы.")
	TEST_ASSERT_NOTNULL(arena.foreign_part_refusal(tool, stranger, stranger.current_body), "Вещь группы защищена от чужих.")
	var/health_before = target.health
	target.adjustBruteLoss(30)
	training_squad_act(mate, "target_heal", list("id" = REF(target)))
	TEST_ASSERT(abs(target.health - health_before) < 0.1, "Пульт товарища лечит цель группы.")

/// Последний участник группы ушёл во время голосования за сброс её сектора: голосовать некому, сектор не сбрасывается.
/datum/unit_test/antag_training_squad_reset_last_leaves/Run()
	var/list/sessions = training_squad_sessions(2)
	TEST_ASSERT(length(sessions) == 2, "Два участника на полигоне.")
	var/datum/antag_training_session/leader = sessions[1]
	var/datum/antag_training_session/mate = sessions[2]
	var/datum/antag_training_arena/arena = leader.arena
	training_squad_act(leader, "squad_create", list("open" = TRUE))
	training_squad_act(mate, "squad_join", list("id" = REF(leader.squad)))
	TEST_ASSERT(training_squad_book(leader, "dark"), "Группа занимает сектор.")
	training_squad_act(leader, "reset_zone", list("zone" = "dark"))
	TEST_ASSERT_EQUAL(arena.pending_reset_zone, "dark", "Лидер запрашивает сброс.")
	training_squad_act(leader, "squad_leave")
	TEST_ASSERT_EQUAL(arena.pending_reset_zone, "dark", "Без голоса оставшегося сброс ждёт.")
	var/reset_lock = arena.next_reset_at
	training_squad_act(mate, "squad_leave")
	TEST_ASSERT_NULL(arena.pending_reset_zone, "Голосование снято вместе с группой.")
	TEST_ASSERT_EQUAL(arena.next_reset_at, reset_lock, "Сектор без согласия не сбрасывается.")
