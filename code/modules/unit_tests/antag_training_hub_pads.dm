/// count участников без групп на одном полигоне с загруженной мини-станцией и площадками.
/datum/unit_test/proc/training_pad_sessions(count)
	var/list/sessions = training_squad_sessions(count)
	if(length(sessions) != count)
		return null
	var/datum/antag_training_session/first = sessions[1]
	if(!first.arena.hub?.load_station())
		return null
	return sessions

/datum/unit_test/proc/training_pad(datum/antag_training_session/session, index)
	return session.arena.hub.pad_by_id(index)

/datum/unit_test/proc/training_pad_act(datum/antag_training_session/session, action, datum/antag_training_hub_pad/pad, list/params = list())
	params["id"] = pad.id
	training_squad_act(session, action, params)

/datum/unit_test/proc/training_pad_settled(datum/antag_training_hub_pad/pad, preset_id, max_wait = 1 MINUTES)
	var/list/budget = new_wait_budget(max_wait, "[pad.name]: пресет [preset_id]")
	while(!QDELETED(pad) && (pad.loading || pad.preset_id != preset_id) && wait_budget_tick(budget))
		continue
	return !QDELETED(pad) && !pad.loading && pad.preset_id == preset_id

/datum/unit_test/proc/training_pad_count(datum/antag_training_hub_pad/pad, find_type)
	. = 0
	for(var/turf/tile as anything in pad.turfs)
		for(var/atom/movable/thing as anything in tile)
			if(istype(thing, find_type))
				.++

/datum/unit_test/proc/training_pad_find(datum/antag_training_hub_pad/pad, find_type)
	for(var/turf/tile as anything in pad.turfs)
		var/atom/movable/thing = locate(find_type) in tile
		if(thing)
			return thing
	return null

/// Свободную площадку занимает любой участник; вторую ему и его группе не дают, чужую - тоже.
/datum/unit_test/antag_training_hub_pad_claim/Run()
	var/list/sessions = training_pad_sessions(4)
	TEST_ASSERT(length(sessions) == 4, "Четыре участника на полигоне с площадками.")
	var/datum/antag_training_session/first = sessions[1]
	var/datum/antag_training_session/second = sessions[2]
	var/datum/antag_training_session/leader = sessions[3]
	var/datum/antag_training_session/mate = sessions[4]
	var/datum/antag_training_hub/hub = first.arena.hub
	TEST_ASSERT_EQUAL(length(hub.pads), ANTAG_TRAINING_HUB_PADS, "В хабе [ANTAG_TRAINING_HUB_PADS] площадки.")
	var/datum/antag_training_hub_pad/pad_one = training_pad(first, 1)
	var/datum/antag_training_hub_pad/pad_two = training_pad(first, 2)
	var/datum/antag_training_hub_pad/pad_three = training_pad(first, 3)
	var/datum/antag_training_hub_pad/pad_four = training_pad(first, 4)
	TEST_ASSERT(pad_one.ready() && length(pad_one.turfs) == 15 * 15, "Площадка 15x15 готова: [length(pad_one.turfs)] клеток.")
	training_pad_act(first, "pad_claim", pad_one)
	TEST_ASSERT_EQUAL(pad_one.owner, first, "Участник без группы занимает площадку.")
	training_pad_act(first, "pad_claim", pad_two)
	TEST_ASSERT(!pad_two.owner && findtext(first.last_feedback, "уже есть"), "Вторую площадку не дают: [first.last_feedback].")
	training_pad_act(second, "pad_claim", pad_one)
	TEST_ASSERT(pad_one.owner == first && findtext(second.last_feedback, "занята"), "Чужую площадку не занять: [second.last_feedback].")
	training_pad_act(second, "pad_claim", pad_two)
	TEST_ASSERT_EQUAL(pad_two.owner, second, "Второй участник занимает свободную.")
	training_squad_act(leader, "squad_create", list("open" = TRUE))
	training_squad_act(mate, "squad_join", list("id" = REF(leader.squad)))
	TEST_ASSERT(leader.squad && mate.squad == leader.squad, "Группа из двух.")
	training_pad_act(mate, "pad_claim", pad_three)
	TEST_ASSERT_EQUAL(pad_three.owner_squad, leader.squad, "Участник группы занимает площадку для группы.")
	TEST_ASSERT(pad_three.manages(leader) && hub.pad_of(leader) == pad_three, "Площадка группы - и лидера.")
	training_pad_act(leader, "pad_claim", pad_four)
	TEST_ASSERT(!pad_four.owner && !pad_four.owner_squad, "Группе вторую площадку не дают.")
	var/list/data = first.ui_data(first.current_body)
	TEST_ASSERT_EQUAL(data["pad_mine"], pad_one.id, "Пульт знает свою площадку.")
	TEST_ASSERT_EQUAL(length(data["pads"]), ANTAG_TRAINING_HUB_PADS, "Пульт показывает все площадки.")
	TEST_ASSERT(data["pads"][1]["mine"] && !data["pads"][2]["mine"], "Своя площадка отмечена.")
	var/obj/structure/antag_training_pad_panel/panel = antag_training_hub_find(hub, /obj/structure/antag_training_pad_panel/three)
	TEST_ASSERT_NOTNULL(panel, "У входа на площадку 3 есть пульт.")
	TEST_ASSERT(panel in pad_three.panels, "Пульт знает свою площадку.")
	var/examined = jointext(panel.examine(first.current_body), " ")
	TEST_ASSERT(findtext(examined, "группа «[leader.squad.name]»") && findtext(examined, "открыта для всех") && findtext(examined, "освободится через"), "Пульт у входа называет владельца, вход и срок: [examined]")
	var/list/panel_data = panel.ui_data(first.current_body)
	TEST_ASSERT(panel_data["focus"] == pad_three.id && length(panel_data["pads"]) == ANTAG_TRAINING_HUB_PADS, "Окно пульта у входа открыто на своей площадке.")

/// Закрытая площадка пускает только владельцев, закрытие выводит гостей в галерею; выйти можно всегда.
/datum/unit_test/antag_training_hub_pad_access/Run()
	var/list/sessions = training_pad_sessions(2)
	TEST_ASSERT(length(sessions) == 2, "Два участника.")
	var/datum/antag_training_session/owner = sessions[1]
	var/datum/antag_training_session/guest = sessions[2]
	var/datum/antag_training_hub_pad/pad = training_pad(owner, 1)
	training_pad_act(owner, "pad_claim", pad)
	var/turf/door = pad.door_turf()
	var/turf/gallery = pad.gallery_turf()
	var/obj/structure/antag_training_barrier/hub/pad/barrier = locate() in door
	TEST_ASSERT_NOTNULL(barrier, "Вход на площадку - барьер площадки.")
	TEST_ASSERT_EQUAL(barrier.pad(), pad, "Барьер знает свою площадку.")
	var/mob/living/guest_body = guest.current_body
	guest_body.forceMove(gallery)
	TEST_ASSERT(guest_body.Move(door, NORTH), "В открытую площадку гость проходит.")
	guest_body.forceMove(gallery)
	training_pad_act(guest, "pad_open", pad)
	TEST_ASSERT(pad.open, "Гость вход не закрывает.")
	training_pad_act(owner, "pad_open", pad)
	TEST_ASSERT(!pad.open, "Владелец закрывает вход.")
	TEST_ASSERT_EQUAL(barrier.color, "#ff6a6a", "Закрытый вход подсвечен.")
	TEST_ASSERT(!guest_body.Move(door, NORTH), "В закрытую площадку гостя не пускают.")
	var/mob/living/owner_body = owner.current_body
	owner_body.forceMove(gallery)
	TEST_ASSERT(owner_body.Move(door, NORTH), "Владелец проходит в закрытую.")
	TEST_ASSERT(owner_body.Move(get_step(door, NORTH), NORTH), "Владелец заходит на площадку.")
	TEST_ASSERT(owner_body.Move(door, SOUTH), "Выйти можно всегда.")
	training_pad_act(owner, "pad_open", pad)
	guest_body.forceMove(pad.center_turf())
	training_pad_act(owner, "pad_open", pad)
	TEST_ASSERT_EQUAL(get_turf(guest_body), gallery, "Закрытие выводит гостя в галерею.")

/// Пресет грузится на площадку, его атомы - атомы полигона; перезагрузка возвращает сдвинутое и убирает принесённое, с гостем внутри ждёт его согласия.
/datum/unit_test/antag_training_hub_pad_preset/Run()
	var/list/sessions = training_pad_sessions(2)
	TEST_ASSERT(length(sessions) == 2, "Два участника.")
	var/datum/antag_training_session/owner = sessions[1]
	var/datum/antag_training_session/guest = sessions[2]
	var/datum/antag_training_arena/arena = owner.arena
	var/datum/antag_training_hub_pad/pad = training_pad(owner, 2)
	training_pad_act(guest, "pad_preset", pad, list("preset" = "bar"))
	TEST_ASSERT_EQUAL(pad.preset_id, ANTAG_TRAINING_HUB_PAD_BARE, "Без владельца пресет не меняется.")
	training_pad_act(owner, "pad_claim", pad)
	training_pad_act(owner, "pad_preset", pad, list("preset" = "bar"))
	TEST_ASSERT(training_pad_settled(pad, "bar"), "Владелец один - пресет грузится сразу.")
	var/obj/machinery/jukebox/jukebox = training_pad_find(pad, /obj/machinery/jukebox)
	TEST_ASSERT_NOTNULL(jukebox, "В баре есть музыкальный автомат.")
	TEST_ASSERT_EQUAL(jukebox.training_origin?.resolve(), arena, "Обстановка пресета - атомы полигона.")
	TEST_ASSERT(length(pad.side_offsets["hall"]), "Метки сторон пресета записаны площадкой.")
	TEST_ASSERT(!(locate(/obj/effect/landmark/antag_training) in pad.offset_turf(pad.side_offsets["hall"][1])), "Метки убраны с карты.")
	var/turf/jukebox_spot = get_turf(jukebox)
	var/turf/moved_to = pad.center_turf()
	jukebox.forceMove(moved_to)
	var/obj/item/crowbar/brought = new(moved_to)
	TEST_ASSERT_EQUAL(brought.training_origin?.resolve(), arena, "Принесённое на площадку - атом полигона.")
	guest.current_body.forceMove(get_step(moved_to, EAST))
	training_pad_act(owner, "pad_reload", pad)
	TEST_ASSERT(pad.pending_preset == "bar" && !pad.loading, "С гостем внутри перезагрузка ждёт согласия.")
	var/list/entry = guest.ui_data(guest.current_body)["pads"][2]
	TEST_ASSERT(entry["vote"]?["can_vote"] && !entry["vote"]["voted"], "Гость видит голосование.")
	training_pad_act(guest, "pad_vote", pad)
	TEST_ASSERT(training_pad_settled(pad, "bar"), "Согласие всех внутри перезагружает пресет.")
	TEST_ASSERT(wait_for_qdeleted(brought, 10 SECONDS), "Принесённое убрано перезагрузкой.")
	TEST_ASSERT_EQUAL(training_pad_count(pad, /obj/machinery/jukebox), 1, "Автомат один.")
	TEST_ASSERT_NOTNULL(locate(/obj/machinery/jukebox) in jukebox_spot, "Сдвинутый автомат снова на своём месте.")
	var/turf/guest_spot = get_turf(guest.current_body)
	var/turf/gallery = pad.gallery_turf()
	TEST_ASSERT(guest_spot == gallery, "Тех, кто был внутри, перезагрузка выводит в галерею: гость в [guest_spot?.x],[guest_spot?.y], галерея [gallery.x],[gallery.y], площадка [json_encode(pad.bounds)].")

/// Без владельцев на площадке и без действий с пульта 20 минут - площадка свободна и снова пуста.
/datum/unit_test/antag_training_hub_pad_idle/Run()
	var/list/sessions = training_pad_sessions(1)
	TEST_ASSERT(length(sessions) == 1, "Участник на полигоне.")
	var/datum/antag_training_session/owner = sessions[1]
	var/datum/antag_training_hub_pad/pad = training_pad(owner, 3)
	training_pad_act(owner, "pad_claim", pad)
	training_pad_act(owner, "pad_preset", pad, list("preset" = "brig"))
	TEST_ASSERT(training_pad_settled(pad, "brig"), "Бриг загружен.")
	owner.current_body.forceMove(pad.center_turf())
	pad.last_active_at = world.time - ANTAG_TRAINING_HUB_PAD_IDLE - 1 SECONDS
	pad.check_idle()
	TEST_ASSERT_EQUAL(pad.owner, owner, "Владелец на площадке - она не освобождается.")
	TEST_ASSERT(round(pad.last_active_at, 1) == round(world.time, 1), "Присутствие владельца продлевает срок.")
	owner.current_body.forceMove(owner.arena.hub_arrival())
	pad.last_active_at = world.time - ANTAG_TRAINING_HUB_PAD_IDLE + 1 MINUTES
	pad.check_idle()
	TEST_ASSERT_EQUAL(pad.owner, owner, "До срока площадка остаётся за владельцем.")
	pad.last_active_at = world.time - ANTAG_TRAINING_HUB_PAD_IDLE - 1 SECONDS
	pad.check_idle()
	TEST_ASSERT_NULL(pad.owner, "Через [ANTAG_TRAINING_HUB_PAD_IDLE / (1 MINUTES)] минут простоя площадка свободна.")
	TEST_ASSERT(training_pad_settled(pad, ANTAG_TRAINING_HUB_PAD_BARE), "Освобождённая площадка снова пуста.")

/// Владелец ушёл с полигона или его группа распущена - площадка свободна.
/datum/unit_test/antag_training_hub_pad_owner_leaves/Run()
	var/list/sessions = training_pad_sessions(3)
	TEST_ASSERT(length(sessions) == 3, "Три участника.")
	var/datum/antag_training_session/keeper = sessions[1]
	var/datum/antag_training_session/leaver = sessions[2]
	var/datum/antag_training_session/leader = sessions[3]
	var/datum/antag_training_hub_pad/pad_one = training_pad(keeper, 1)
	var/datum/antag_training_hub_pad/pad_two = training_pad(keeper, 2)
	training_pad_act(leaver, "pad_claim", pad_one)
	TEST_ASSERT_EQUAL(pad_one.owner, leaver, "Площадка занята.")
	qdel(leaver)
	TEST_ASSERT_NULL(pad_one.owner, "Владелец ушёл - площадка свободна.")
	training_squad_act(leader, "squad_create", list("open" = TRUE))
	var/datum/antag_training_squad/squad = leader.squad
	training_pad_act(leader, "pad_claim", pad_two)
	TEST_ASSERT_EQUAL(pad_two.owner_squad, squad, "Площадка у группы.")
	training_squad_act(leader, "squad_leave")
	TEST_ASSERT(QDELETED(squad), "Последний вышел - группа распущена.")
	TEST_ASSERT(!pad_two.owner_squad && !pad_two.owner, "Распущенная группа освобождает площадку.")
	training_pad_act(keeper, "pad_claim", pad_two)
	TEST_ASSERT_EQUAL(pad_two.owner, keeper, "Освобождённую площадку можно занять снова.")

/// Стенд освобождает чужую площадку, без стенда - нет; действие в логе администрации.
/datum/unit_test/antag_training_hub_pad_stand/Run()
	var/list/sessions = training_pad_sessions(2)
	TEST_ASSERT(length(sessions) == 2, "Два участника.")
	var/datum/antag_training_session/session = sessions[1]
	var/datum/antag_training_session/holder = sessions[2]
	var/datum/antag_training_hub_pad/pad = training_pad(session, 4)
	training_pad_act(holder, "pad_claim", pad)
	var/datum/tgui/ui = allocate_stand_ui(session)
	antag_training_console_act(session, ui, "stand_release", list("kind" = "pad", "id" = pad.id))
	TEST_ASSERT_EQUAL(pad.owner, holder, "Без стенда чужую площадку не освободить.")
	grant_stand_rights(session, mentor = TRUE)
	antag_training_console_act(session, ui, "stand_toggle", list())
	var/list/pads = session.ui_data(session.current_body)["stand"]["pads"]
	TEST_ASSERT(length(pads) == 1 && pads[1]["id"] == pad.id, "Стенд видит занятую площадку.")
	antag_training_console_act(session, ui, "stand_release", list("kind" = "pad", "id" = pad.id))
	TEST_ASSERT_NULL(pad.owner, "Стенд освобождает чужую площадку.")
	TEST_ASSERT(findtext(last_admin_log(), "освободил [pad.name]"), "Освобождение записано в лог администрации.")
	TEST_ASSERT_NULL(session.arena.stand_force_release("pad", 99), "Несуществующей площадки нет.")
	session.current_body.mock_client = null

/// Каждый пресет грузится на площадку и снимается; космос обломка не соседствует с полом вне площадки.
/datum/unit_test/antag_training_hub_pad_presets/Run()
	var/list/sessions = training_pad_sessions(1)
	TEST_ASSERT(length(sessions) == 1, "Участник на полигоне.")
	var/datum/antag_training_session/owner = sessions[1]
	var/datum/antag_training_hub_pad/pad = training_pad(owner, 1)
	for(var/preset_id in GLOB.antag_training_pad_presets + ANTAG_TRAINING_HUB_PAD_BARE)
		var/real_started = REALTIMEOFDAY
		TEST_ASSERT(pad.load_preset(preset_id), "Пресет [preset_id] грузится.")
		log_test("\tПресет площадки [preset_id]: [(REALTIMEOFDAY - real_started) / (1 SECONDS)] с.")
		TEST_ASSERT_EQUAL(pad.preset_id, preset_id, "Площадка помнит пресет [preset_id].")
		var/things = 0
		for(var/turf/tile as anything in pad.turfs)
			TEST_ASSERT(istype(tile.loc, /area/antag_training/hub/pad/one), "Пресет [preset_id] не меняет область площадки.")
			things += length(tile.contents)
			if(!isspaceturf(tile))
				continue
			for(var/direction in GLOB.cardinals)
				var/turf/near = get_step(tile, direction)
				TEST_ASSERT(pad.contains(near) || isclosedturf(near), "Космос [preset_id] в [tile.x],[tile.y] не граничит с полом вне площадки.")
		TEST_ASSERT(things > 0, "На площадке есть обстановка [preset_id].")
		TEST_ASSERT(length(pad.side_offsets), "У пресета [preset_id] есть метки сторон.")

/// Пресеты называют программы, под которые сделаны, и свои сценарии: в окне пульта площадки и при осмотре пульта у входа.
/datum/unit_test/antag_training_hub_pad_preset_programs/Run()
	for(var/preset_id in GLOB.antag_training_pad_presets)
		for(var/program_type in GLOB.antag_training_pad_presets[preset_id]["programs"])
			TEST_ASSERT(antag_training_program_selectable(program_type), "Пресет [preset_id] ссылается на выбираемую программу, а не на [program_type].")
	var/list/sessions = training_pad_sessions(1)
	TEST_ASSERT(length(sessions) == 1, "Участник на полигоне с площадками.")
	var/datum/antag_training_session/owner = sessions[1]
	var/datum/antag_training_hub_pad/pad = training_pad(owner, 1)
	var/obj/structure/antag_training_pad_panel/panel = antag_training_hub_find(owner.arena.hub, /obj/structure/antag_training_pad_panel/one)
	TEST_ASSERT_NOTNULL(panel, "У площадки 1 есть пульт.")
	var/datum/antag_training_program/morph = /datum/antag_training_program/creature/morph
	var/datum/antag_training_scenario/hunt = antag_training_scenarios()["morph_hunt"]
	var/list/panel_data = panel.ui_data(owner.current_body)
	var/list/maint
	for(var/list/entry as anything in panel_data["pad_presets"])
		if(entry["id"] == "maint")
			maint = entry
	TEST_ASSERT_NOTNULL(maint, "Окно пульта предлагает пресет «Техи».")
	TEST_ASSERT(initial(morph.name) in maint["programs"], "Пресет «Техи» называет программу морфа: [json_encode(maint["programs"])].")
	TEST_ASSERT(hunt.name in maint["scenarios"], "Пресет «Техи» называет свой сценарий: [json_encode(maint["scenarios"])].")
	training_pad_act(owner, "pad_claim", pad)
	training_pad_act(owner, "pad_preset", pad, list("preset" = "maint"))
	TEST_ASSERT(training_pad_settled(pad, "maint"), "Пресет «Техи» загружен.")
	var/examined = jointext(panel.examine(owner.current_body), "\n")
	TEST_ASSERT(findtext(examined, initial(morph.name)) && findtext(examined, hunt.name), "Пульт у входа говорит, кому и для какого сценария нужен загруженный пресет: [examined]")

/// Группа из count участников на полигоне с площадками; лидер выбирает быстрый сценарий, раздаёт обязательные слоты по порядку, с fill - остальных по свободным местам, и жмёт «Старт».
/datum/unit_test/proc/training_pad_scenario(template_id, count, fill = FALSE)
	var/list/sessions = training_scenario_squad(count)
	if(length(sessions) != count)
		return null
	var/datum/antag_training_session/leader = sessions[1]
	if(!leader.arena.hub?.load_station())
		return null
	var/datum/antag_training_scenario/scenario = training_scenario_pick(leader, template_id)
	if(!scenario)
		return null
	var/index = 0
	for(var/datum/antag_training_scenario_slot/slot as anything in scenario.slots)
		if(slot.required && index < length(sessions))
			index++
			training_squad_act(leader, "scenario_assign", list("slot" = REF(slot), "member" = REF(sessions[index])))
	for(var/datum/antag_training_session/member as anything in (fill ? sessions : list()))
		for(var/datum/antag_training_scenario_slot/slot as anything in scenario.slots)
			if(!scenario.slot_of(member) && slot.free_seats())
				training_squad_act(leader, "scenario_assign", list("slot" = REF(slot), "member" = REF(member)))
	training_squad_act(leader, "scenario_start")
	return training_scenario_wait(scenario, ANTAG_TRAINING_SCENARIO_RUNNING) ? scenario : null

/datum/unit_test/proc/training_pad_scenario_placed(datum/antag_training_scenario/scenario, preset_id)
	var/datum/antag_training_venue/pad/venue = scenario.venue
	if(!istype(venue) || venue.place.preset_id != preset_id || !venue.held_by(scenario.squad))
		return FALSE
	for(var/datum/antag_training_session/member as anything in scenario.assigned())
		if(!venue.contains(member.current_body))
			return FALSE
	return TRUE

/// Своя сборка на площадке: площадка занимается за группой, стороны встают на ней, цели ставятся в неё, «Завершить» освобождает площадку.
/datum/unit_test/antag_training_hub_pad_scenario_custom/Run()
	var/list/sessions = training_scenario_squad(2)
	TEST_ASSERT(length(sessions) == 2, "Группа из двух.")
	var/datum/antag_training_session/leader = sessions[1]
	var/datum/antag_training_session/other = sessions[2]
	var/datum/antag_training_arena/arena = leader.arena
	TEST_ASSERT(arena.hub.load_station(), "Площадки загружены.")
	var/datum/antag_training_hub_pad/pad = training_pad(leader, 2)
	var/datum/antag_training_scenario/scenario = training_scenario_pick(leader, "custom", pad.id)
	TEST_ASSERT_NOTNULL(scenario, "Своя сборка выбирается на площадке.")
	var/datum/antag_training_venue/pad/venue = scenario.venue
	TEST_ASSERT(istype(venue), "Место проведения - площадка.")
	TEST_ASSERT_EQUAL(pad.owner_squad, leader.squad, "Площадка занята за группой.")
	TEST_ASSERT(venue.id() == pad.id && venue.name() == pad.name && venue.area_bounds() == pad.bounds && !venue.sector(), "Площадка отвечает интерфейсу места.")
	TEST_ASSERT_EQUAL(venue.power_area(), GLOB.areas_by_type[pad.area_type], "Питание места - область площадки.")
	TEST_ASSERT_EQUAL(leader.ui_data(leader.current_body)["scenario"]["venue_kind"], "pad", "Пульт знает, что сценарий на площадке.")
	training_squad_act(leader, "scenario_slot_add", list("side" = "a"))
	training_squad_act(leader, "scenario_slot_add", list("side" = "b"))
	TEST_ASSERT_EQUAL(length(scenario.slots), 2, "Лидер собрал два слота.")
	training_squad_act(leader, "scenario_assign", list("slot" = REF(scenario.slots[1]), "member" = REF(leader)))
	training_squad_act(leader, "scenario_assign", list("slot" = REF(scenario.slots[2]), "member" = REF(other)))
	training_squad_act(leader, "scenario_start")
	TEST_ASSERT(training_scenario_wait(scenario, ANTAG_TRAINING_SCENARIO_RUNNING), "Партия на площадке началась: [training_scenario_state(scenario)].")
	TEST_ASSERT(training_pad_scenario_placed(scenario, ANTAG_TRAINING_HUB_PAD_BARE), "Стороны встают на площадке.")
	TEST_ASSERT(get_dist(leader.current_body, other.current_body) > 2, "Стороны расходятся по меткам площадки.")
	var/mob/living/target = arena.spawn_creature("human", venue.target_zone(), FALSE, leader)
	TEST_ASSERT(target && venue.contains(target), "Учебная цель ставится на площадку сценария.")
	training_pad_act(leader, "pad_release", pad)
	TEST_ASSERT_EQUAL(pad.owner_squad, leader.squad, "Пока идёт сценарий, площадку не освободить с пульта.")
	training_pad_act(leader, "pad_reload", pad)
	TEST_ASSERT(!pad.loading && !pad.pending_preset, "Пока идёт сценарий, пресет не перезагрузить с пульта.")
	training_squad_act(leader, "scenario_end")
	TEST_ASSERT(training_scenario_ended(scenario, null), "Лидер подвёл итог: [training_scenario_state(scenario)].")
	training_squad_act(leader, "scenario_finish")
	TEST_ASSERT(QDELETED(scenario), "«Завершить» закрывает сценарий.")
	TEST_ASSERT(!pad.owner_squad && !pad.owner, "Закрытый сценарий освобождает площадку.")

/// «Все против блоба»: медотсек на площадке, блоб ставит ядро, экипаж его уничтожает - победа экипажа.
/datum/unit_test/antag_training_hub_pad_scenario_blob/Run()
	var/datum/antag_training_scenario/scenario = training_pad_scenario("blob_rush", 2)
	TEST_ASSERT_NOTNULL(scenario, "«Все против блоба» начинается.")
	TEST_ASSERT(training_pad_scenario_placed(scenario, "medbay"), "Медотсек загружен, все на площадке группы.")
	var/datum/antag_training_session/blob = training_scenario_member(scenario, "blob")
	var/datum/antag_training_session/crew = training_scenario_member(scenario, "crew")
	TEST_ASSERT(training_scenario_near_mark(scenario, crew.current_body, "lobby"), "Экипаж стоит в приёмной.")
	var/mob/camera/blob/training/overmind = blob.current_body
	TEST_ASSERT(istype(overmind), "Блоб - разум блоба.")
	var/turf/spot = scenario.venue.free_spot(scenario.venue.side_turfs("ward")[1])
	overmind.forceMove(spot)
	TEST_ASSERT(overmind.place_blob_core(0), "Ядро блоба ставится на площадке.")
	var/datum/antag_training_scenario_objective/destroy_blob/goal = locate() in scenario.objectives
	var/list/budget = new_wait_budget(10 SECONDS, "цель видит ядро")
	while(!goal.cores[blob] && wait_budget_tick(budget))
		continue
	TEST_ASSERT(goal.cores[blob], "Цель экипажа заметила ядро.")
	qdel(overmind.blob_core)
	TEST_ASSERT(training_scenario_ended(scenario, "crew"), "Ядро уничтожено - победа экипажа, а [training_scenario_state(scenario)].")

/// «Королевская битва»: лабиринт, бойцы в разных углах, последний на ногах побеждает.
/datum/unit_test/antag_training_hub_pad_scenario_royale/Run()
	var/datum/antag_training_scenario/scenario = training_pad_scenario("royale", 2)
	TEST_ASSERT_NOTNULL(scenario, "«Королевская битва» начинается.")
	TEST_ASSERT(training_pad_scenario_placed(scenario, "maze"), "Лабиринт загружен, бойцы на площадке.")
	var/datum/antag_training_session/first = training_scenario_member(scenario, "first")
	var/datum/antag_training_session/second = training_scenario_member(scenario, "second")
	TEST_ASSERT(training_scenario_near_mark(scenario, first.current_body, "sw") && training_scenario_near_mark(scenario, second.current_body, "ne"), "Бойцы в разных углах.")
	var/mob/living/loser = second.current_body
	loser.death()
	TEST_ASSERT(training_scenario_ended(scenario, "first"), "Последний на ногах побеждает, а [training_scenario_state(scenario)].")

/// «Охота на морфа»: техи, морф убит - победа охотников.
/datum/unit_test/antag_training_hub_pad_scenario_morph/Run()
	var/datum/antag_training_scenario/scenario = training_pad_scenario("morph_hunt", 2)
	TEST_ASSERT_NOTNULL(scenario, "«Охота на морфа» начинается.")
	TEST_ASSERT(training_pad_scenario_placed(scenario, "maint"), "Техи загружены, все на площадке.")
	var/datum/antag_training_session/morph = training_scenario_member(scenario, "morph")
	var/mob/living/simple_animal/hostile/morph/body = morph.current_body
	TEST_ASSERT(istype(body), "Морф в теле морфа.")
	TEST_ASSERT(training_scenario_near_mark(scenario, body, "junk"), "Морф начинает на свалке.")
	body.death()
	TEST_ASSERT(training_scenario_ended(scenario, "hunters"), "Морф убит - победа охотников, а [training_scenario_state(scenario)].")

/// «Магическая дуэль 2x2»: пустая площадка, пары с разных краёв, выведенные соперники - победа.
/datum/unit_test/antag_training_hub_pad_scenario_wizard/Run()
	var/datum/antag_training_scenario/scenario = training_pad_scenario("wizard_duel", 2)
	TEST_ASSERT_NOTNULL(scenario, "«Магическая дуэль 2x2» начинается.")
	TEST_ASSERT(training_pad_scenario_placed(scenario, ANTAG_TRAINING_HUB_PAD_BARE), "Пустая площадка, волшебники на ней.")
	var/datum/antag_training_session/red = training_scenario_member(scenario, "red")
	var/datum/antag_training_session/blue = training_scenario_member(scenario, "blue")
	TEST_ASSERT(red.current_body.mind?.has_antag_datum(/datum/antagonist/wizard), "Слот даёт волшебника.")
	TEST_ASSERT(training_scenario_near_mark(scenario, red.current_body, "west") && training_scenario_near_mark(scenario, blue.current_body, "east"), "Пары у разных краёв.")
	var/mob/living/loser = blue.current_body
	loser.death()
	TEST_ASSERT(training_scenario_ended(scenario, "red"), "Синие выведены - победа красных, а [training_scenario_state(scenario)].")

/// «Оборона брига»: бриг на площадке, налётчики закованы - победа СБ.
/datum/unit_test/antag_training_hub_pad_scenario_brig/Run()
	var/datum/antag_training_scenario/scenario = training_pad_scenario("brig_defense", 2)
	TEST_ASSERT_NOTNULL(scenario, "«Оборона брига» начинается.")
	TEST_ASSERT(training_pad_scenario_placed(scenario, "brig"), "Бриг загружен, все на площадке.")
	var/datum/antag_training_session/officer = training_scenario_member(scenario, "security")
	var/datum/antag_training_session/raider = training_scenario_member(scenario, "raiders")
	TEST_ASSERT_EQUAL(officer.role.id, "crew:Security Officer", "Офицер с должностью СБ.")
	TEST_ASSERT(training_scenario_near_mark(scenario, officer.current_body, "corridor") && training_scenario_near_mark(scenario, raider.current_body, "lobby"), "СБ в коридоре брига, налётчики в приёмной.")
	training_scenario_cuff(raider.current_body)
	TEST_ASSERT(training_scenario_ended(scenario, "security"), "Налётчики закованы - победа СБ, а [training_scenario_state(scenario)].")

/// Вестибюль не стравливает воздух в пустые слоты площадок до их загрузки и в космос обломка после.
/datum/unit_test/antag_training_hub_pad_air/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон готовится.")
	var/datum/antag_training_hub/hub = session.arena.hub
	var/turf/open/gallery = locate(hub.origin_x + 9, hub.origin_y + 38, session.arena.private_level.z_value)
	TEST_ASSERT(istype(gallery) && istype(get_area(gallery), /area/antag_training/hub/lobby), "Клетка галереи у входа на площадку 1.")
	TEST_ASSERT(isspaceturf(get_step(get_step(gallery, NORTH), NORTH)), "Слот площадки пуст до входа игрока.")
	var/list/budget = new_wait_budget(5 SECONDS, "воздух галереи")
	while(wait_budget_tick(budget))
		continue
	TEST_ASSERT(gallery.air.return_pressure() > 95, "До загрузки площадок галерея держит давление: [round(gallery.air.return_pressure(), 1)] кПа.")
	TEST_ASSERT(hub.load_station(), "Площадки загружены.")
	var/datum/antag_training_hub_pad/pad = hub.pad_by_id(1)
	TEST_ASSERT(pad.load_preset("debris"), "Обломок в космосе загружен.")
	budget = new_wait_budget(5 SECONDS, "воздух галереи у обломка")
	while(wait_budget_tick(budget))
		continue
	TEST_ASSERT(gallery.air.return_pressure() > 95, "Космос обломка не стравливает галерею: [round(gallery.air.return_pressure(), 1)] кПа.")
	var/turf/open/vestibule = locate(pad.bounds[1] + 7, pad.bounds[3] + 1, gallery.z)
	TEST_ASSERT(vestibule.air.return_pressure() > 95, "Шлюзовой вестибюль обломка с воздухом: [round(vestibule.air.return_pressure(), 1)] кПа.")

/// Варианты параметра key цели kind в библиотеке своей сборки, как их видит пульт.
/datum/unit_test/proc/training_objective_options(datum/antag_training_session/session, kind, key)
	. = list()
	for(var/list/entry as anything in session.ui_data(session.current_body)["scenario"]["objective_library"])
		if(entry["id"] != kind)
			continue
		for(var/list/param as anything in entry["params"])
			if(param["key"] == key)
				for(var/list/option as anything in param["options"])
					. += option["value"]

/// Пока на площадке идёт сценарий, внутрь пускают только участников партии; выбывший не возвращается; после итога вход прежний.
/datum/unit_test/antag_training_hub_pad_scenario_entry/Run()
	var/datum/antag_training_scenario/scenario = training_pad_scenario("royale", 3, TRUE)
	TEST_ASSERT_NOTNULL(scenario, "«Королевская битва» на троих начинается.")
	TEST_ASSERT_EQUAL(length(scenario.assigned()), 3, "Трое бойцов в слотах.")
	var/datum/antag_training_venue/pad/venue = scenario.venue
	var/datum/antag_training_hub_pad/pad = venue.place
	var/datum/antag_training_arena/arena = scenario.squad.arena
	var/datum/antag_training_session/outsider = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(outsider.prepare(arena), "Посторонний вошёл на полигон.")
	var/turf/door = pad.door_turf()
	var/turf/gallery = pad.gallery_turf()
	var/mob/living/stranger = outsider.current_body
	stranger.forceMove(gallery)
	TEST_ASSERT(!stranger.Move(door, NORTH), "Постороннего на площадку идущей партии не пускают.")
	var/obj/structure/antag_training_barrier/hub/pad/barrier = locate() in door
	TEST_ASSERT_EQUAL(barrier?.color, "#ff6a6a", "Вход на площадку идущей партии подсвечен закрытым.")
	TEST_ASSERT_NULL(arena.spawn_creature("human", pad.id, FALSE, outsider), "Посторонний не ставит цели на площадку партии.")
	var/datum/antag_training_session/third = training_scenario_member(scenario, "third")
	var/mob/living/fallen = third.current_body
	fallen.death()
	var/list/budget = new_wait_budget(15 SECONDS, "выбывший восстановлен в вестибюле")
	while(!(scenario.eliminated[third] && third.current_body?.stat != DEAD) && wait_budget_tick(budget))
		continue
	TEST_ASSERT(scenario.eliminated[third] && third.current_body.stat != DEAD, "Третий выбыл и восстановлен.")
	TEST_ASSERT_EQUAL(scenario.phase, ANTAG_TRAINING_SCENARIO_RUNNING, "Двое на ногах - партия идёт.")
	var/mob/living/returned = third.current_body
	returned.forceMove(gallery)
	TEST_ASSERT(!returned.Move(door, NORTH), "Выбывшего обратно не пускают.")
	returned.forceMove(pad.center_turf())
	budget = new_wait_budget(5 SECONDS, "выбывший выведен с площадки")
	while(venue.contains(returned) && wait_budget_tick(budget))
		continue
	TEST_ASSERT(!venue.contains(returned), "Выбывшего, попавшего внутрь, выводят.")
	TEST_ASSERT(findtext(third.last_feedback, "выбыли"), "Выбывшему объясняют, где смотреть: [third.last_feedback].")
	var/datum/antag_training_session/second = training_scenario_member(scenario, "second")
	var/mob/living/loser = second.current_body
	loser.death()
	TEST_ASSERT(training_scenario_ended(scenario, "first"), "Последний на ногах побеждает, а [training_scenario_state(scenario)].")
	TEST_ASSERT_NULL(barrier.color, "После итога подсветка закрытого входа снята.")
	stranger.forceMove(gallery)
	TEST_ASSERT(stranger.Move(door, NORTH), "После итога вход прежний: площадка открыта.")

/// «Все против блоба»: ресурсы блоба пультом не пополняются, ядро ставится только на площадке партии.
/datum/unit_test/antag_training_hub_pad_scenario_blob_bounds/Run()
	var/datum/antag_training_scenario/scenario = training_pad_scenario("blob_rush", 2)
	TEST_ASSERT_NOTNULL(scenario, "«Все против блоба» начинается.")
	var/datum/antag_training_session/blob = training_scenario_member(scenario, "blob")
	var/mob/camera/blob/training/overmind = blob.current_body
	TEST_ASSERT(istype(overmind), "Блоб - разум блоба.")
	overmind.blob_points = 0
	training_squad_act(blob, "program_option", list("option" = "Ресурсы до максимума"))
	TEST_ASSERT_EQUAL(round(overmind.blob_points), 0, "Во время партии ресурсы блоба пультом не пополняются.")
	var/datum/antag_training_venue/pad/venue = scenario.venue
	for(var/datum/antag_training_hub_pad/foreign as anything in blob.arena.hub.pads)
		if(foreign == venue.place)
			continue
		overmind.forceMove(foreign.center_turf())
		TEST_ASSERT(!overmind.place_blob_core(0), "Ядро не ставится на [foreign.name]: партия идёт на [venue.place.name].")
	var/datum/antag_training_sector/station = blob.arena.sectors["station"]
	TEST_ASSERT(station.load(), "Станционный макет загружен.")
	overmind.forceMove(station.spawn_turf())
	TEST_ASSERT(!overmind.place_blob_core(0), "Ядро не ставится в станционном макете: партия идёт на площадке.")
	overmind.forceMove(venue.free_spot(venue.side_turfs("ward")[1]))
	TEST_ASSERT(overmind.place_blob_core(0), "Ядро ставится на площадке партии.")

/// Без сценария блоб ставит ядро только на своей площадке, не на чужой и не на свободной.
/datum/unit_test/antag_training_hub_pad_blob_own_pad/Run()
	var/list/sessions = training_pad_sessions(2)
	TEST_ASSERT(length(sessions) == 2, "Два участника.")
	var/datum/antag_training_session/blob = sessions[1]
	var/datum/antag_training_session/other = sessions[2]
	training_squad_act(blob, "restart", list("program" = "[/datum/antag_training_program/creature/blob]"))
	var/mob/camera/blob/training/overmind = blob.current_body
	TEST_ASSERT(istype(overmind), "Участник стал блобом.")
	var/datum/antag_training_hub_pad/own = training_pad(blob, 1)
	var/datum/antag_training_hub_pad/foreign = training_pad(blob, 2)
	var/datum/antag_training_hub_pad/free = training_pad(blob, 3)
	training_pad_act(blob, "pad_claim", own)
	training_pad_act(other, "pad_claim", foreign)
	overmind.forceMove(foreign.center_turf())
	TEST_ASSERT(!overmind.place_blob_core(0), "Ядро не ставится на чужой площадке.")
	overmind.forceMove(free.center_turf())
	TEST_ASSERT(!overmind.place_blob_core(0), "Ядро не ставится на свободной площадке.")
	overmind.forceMove(own.center_turf())
	TEST_ASSERT(overmind.place_blob_core(0), "Ядро ставится на своей площадке.")

/// Своя сборка на площадке: место без замкнутой комнаты и пострадавшие сверх лимита не принимаются, сорванная цель отменяет старт до пересборки тел.
/datum/unit_test/antag_training_hub_pad_scenario_custom_zones/Run()
	var/list/sessions = training_scenario_squad(2)
	TEST_ASSERT(length(sessions) == 2, "Группа из двух.")
	var/datum/antag_training_session/leader = sessions[1]
	var/datum/antag_training_session/other = sessions[2]
	TEST_ASSERT(leader.arena.hub.load_station(), "Площадки загружены.")
	var/datum/antag_training_hub_pad/pad = training_pad(leader, 2)
	TEST_ASSERT(pad.load_preset(ANTAG_TRAINING_HUB_PAD_BARE), "Пустая площадка загружена с метками сторон.")
	var/datum/antag_training_scenario/scenario = training_scenario_pick(leader, "custom", pad.id)
	TEST_ASSERT_NOTNULL(scenario, "Своя сборка на пустой площадке.")
	training_squad_act(leader, "scenario_slot_add", list("side" = "a"))
	training_squad_act(leader, "scenario_slot_add", list("side" = "b"))
	training_squad_act(leader, "scenario_assign", list("slot" = REF(scenario.slots[1]), "member" = REF(leader)))
	training_squad_act(leader, "scenario_assign", list("slot" = REF(scenario.slots[2]), "member" = REF(other)))
	var/list/zones = training_objective_options(leader, "detain", "zone")
	TEST_ASSERT(!length(zones), "На пустой площадке нет замкнутых комнат для задержания: [zones.Join(", ")].")
	var/list/places = scenario.venue.place_ids()
	TEST_ASSERT(length(places), "У пустой площадки есть метки сторон.")
	training_squad_act(leader, "scenario_objective_add", list("kind" = "detain", "side" = "b", "target" = "a", "zone" = places[1]))
	TEST_ASSERT(!length(scenario.objective_specs), "Задержание без замкнутой комнаты не принимается.")
	for(var/index in 1 to 3)
		training_squad_act(leader, "scenario_objective_add", list("kind" = "heal", "side" = "a", "count" = "5", "zone" = places[1]))
	TEST_ASSERT_EQUAL(length(scenario.objective_specs), 2, "Пострадавших сверх лимита целей не добавить.")
	TEST_ASSERT(findtext(leader.last_feedback, "[ANTAG_TRAINING_TARGET_LIMIT]"), "Отказ называет лимит целей: [leader.last_feedback].")
	training_squad_act(leader, "scenario_objective_remove", list("index" = 1))
	training_squad_act(leader, "scenario_objective_remove", list("index" = 1))
	training_pad_act(leader, "pad_preset", pad, list("preset" = "brig"))
	TEST_ASSERT(training_pad_settled(pad, "brig"), "Бриг загружен.")
	zones = training_objective_options(leader, "detain", "zone")
	TEST_ASSERT(length(zones), "В бриге есть замкнутые комнаты.")
	for(var/zone_id in zones)
		TEST_ASSERT(length(scenario.venue.zone_turfs(zone_id)), "Предложенное место [zone_id] - замкнутая комната.")
	training_squad_act(leader, "scenario_objective_add", list("kind" = "detain", "side" = "b", "target" = "a", "zone" = zones[1]))
	TEST_ASSERT_EQUAL(length(scenario.objective_specs), 1, "Задержание в комнату брига принято: [leader.last_feedback].")
	training_pad_act(leader, "pad_preset", pad, list("preset" = "build"))
	TEST_ASSERT(training_pad_settled(pad, "build"), "Вместо брига - пустой зал.")
	var/mob/leader_body = leader.current_body
	var/mob/other_body = other.current_body
	training_squad_act(leader, "scenario_start")
	TEST_ASSERT(training_scenario_wait(scenario, ANTAG_TRAINING_SCENARIO_SETUP, 1 MINUTES), "Цель без комнаты срывает старт: [training_scenario_state(scenario)].")
	TEST_ASSERT(leader.current_body == leader_body && other.current_body == other_body, "Сорванный старт не пересобирает тела.")

/// Пока на площадке идёт партия, зритель группы не ставит на неё цели.
/datum/unit_test/antag_training_hub_pad_scenario_watcher_targets/Run()
	var/datum/antag_training_scenario/scenario = training_pad_scenario("royale", 3)
	TEST_ASSERT_NOTNULL(scenario, "«Королевская битва» на двоих при зрителе начинается.")
	var/list/watchers = scenario.squad.members - scenario.assigned()
	TEST_ASSERT_EQUAL(length(watchers), 1, "Один из группы смотрит.")
	var/datum/antag_training_session/watcher = watchers[1]
	var/datum/antag_training_venue/pad/venue = scenario.venue
	var/datum/antag_training_arena/arena = watcher.arena
	var/targets = length(arena.targets)
	training_squad_act(watcher, "spawn", list("id" = "carp", "zone" = venue.place.id))
	TEST_ASSERT_EQUAL(length(arena.targets), targets, "Зритель группы не ставит цели на площадку идущей партии.")

/// Зритель группы, попавший на площадку идущей партии, выводится с неё, как выбывший.
/datum/unit_test/antag_training_hub_pad_scenario_watcher_evict/Run()
	var/datum/antag_training_scenario/scenario = training_pad_scenario("royale", 3)
	TEST_ASSERT_NOTNULL(scenario, "«Королевская битва» на двоих при зрителе начинается.")
	var/datum/antag_training_session/watcher = training_scenario_watcher(scenario)
	TEST_ASSERT_NOTNULL(watcher, "Один из группы смотрит.")
	var/datum/antag_training_venue/pad/venue = scenario.venue
	var/mob/living/body = watcher.current_body
	body.forceMove(venue.place.center_turf())
	TEST_ASSERT(venue.contains(body), "Зритель попал на площадку.")
	var/list/budget = new_wait_budget(5 SECONDS, "зритель выведен с площадки партии")
	while(venue.contains(body) && wait_budget_tick(budget))
		continue
	TEST_ASSERT(!venue.contains(body), "Зритель группы выводится с площадки идущей партии.")
	TEST_ASSERT(findtext(watcher.last_feedback, "только участников"), "Выведенному объясняют, где смотреть: [watcher.last_feedback].")

/// Посторонний в эфирном прыжке не проходит на площадку идущей партии мимо её входа; удалённый прыжок выпускает тело.
/datum/unit_test/antag_training_hub_pad_scenario_jaunt/Run()
	var/datum/antag_training_scenario/scenario = training_pad_scenario("royale", 2)
	TEST_ASSERT_NOTNULL(scenario, "«Королевская битва» начинается.")
	var/datum/antag_training_venue/pad/venue = scenario.venue
	var/datum/antag_training_hub_pad/pad = venue.place
	var/datum/antag_training_session/outsider = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(outsider.prepare(scenario.squad.arena), "Посторонний вошёл на полигон.")
	var/mob/living/carbon/human/stranger = outsider.current_body
	stranger.forceMove(pad.gallery_turf())
	var/obj/effect/proc_holder/spell/targeted/ethereal_jaunt/jaunt = allocate(/obj/effect/proc_holder/spell/targeted/ethereal_jaunt)
	jaunt.cast(list(stranger), stranger)
	var/obj/effect/dummy/phased_mob/spell_jaunt/holder = stranger.loc
	TEST_ASSERT(istype(holder), "Посторонний ушёл в эфирный прыжок.")
	for(var/step in 1 to 3)
		holder.movedelay = 0
		holder.relaymove(stranger, NORTH)
	var/slipped_in = pad.contains(holder)
	qdel(holder)
	TEST_ASSERT(!slipped_in, "Эфирный прыжок не проходит на площадку идущей партии.")
	TEST_ASSERT(!QDELETED(stranger) && isturf(stranger.loc), "Удалённый прыжок выпускает тело.")
