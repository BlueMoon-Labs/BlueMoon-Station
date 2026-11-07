/datum/unit_test/proc/training_scenario_squad(count)
	var/list/sessions = training_squad_sessions(count)
	if(length(sessions) != count)
		return null
	var/datum/antag_training_session/leader = sessions[1]
	training_squad_act(leader, "squad_create", list("open" = TRUE))
	for(var/index in 2 to count)
		var/datum/antag_training_session/member = sessions[index]
		training_squad_act(member, "squad_join", list("id" = REF(leader.squad)))
	return sessions

/// Лидер выбирает шаблон через пульт; ответ - сценарий, когда его сектор занят группой и загружен.
/datum/unit_test/proc/training_scenario_pick(datum/antag_training_session/leader, template_id, sector_id)
	training_squad_act(leader, "scenario_pick", list("id" = template_id, "sector" = sector_id))
	var/datum/antag_training_scenario/scenario = leader.squad?.scenario
	if(!scenario)
		return null
	var/list/budget = new_wait_budget(1 MINUTES, "сектор сценария [template_id] занят и загружен")
	while(!QDELETED(scenario) && !(scenario.venue.held_by(leader.squad) && scenario.venue.ready()) && wait_budget_tick(budget))
		continue
	return QDELETED(scenario) ? null : scenario

/datum/unit_test/proc/training_scenario_slot(datum/antag_training_scenario/scenario, label)
	for(var/datum/antag_training_scenario_slot/slot as anything in scenario.slots)
		if(slot.label == label)
			return slot
	return null

/datum/unit_test/proc/training_scenario_wait(datum/antag_training_scenario/scenario, phase, max_wait = 2 MINUTES)
	var/list/budget = new_wait_budget(max_wait, "сценарий в фазе [phase]")
	while(!QDELETED(scenario) && scenario.phase != phase && wait_budget_tick(budget))
		continue
	return !QDELETED(scenario) && scenario.phase == phase

/// Группа из count участников, лидер раздаёт обязательные слоты по порядку и жмёт «Старт».
/datum/unit_test/proc/training_scenario_launch(template_id, count)
	var/list/sessions = training_scenario_squad(count)
	if(!sessions)
		return null
	var/datum/antag_training_session/leader = sessions[1]
	var/datum/antag_training_scenario/scenario = training_scenario_pick(leader, template_id)
	if(!scenario)
		return null
	var/index = 0
	for(var/datum/antag_training_scenario_slot/slot as anything in scenario.slots)
		if(slot.required && index < length(sessions))
			index++
			training_squad_act(leader, "scenario_assign", list("slot" = REF(slot), "member" = REF(sessions[index])))
	training_squad_act(leader, "scenario_start")
	return training_scenario_wait(scenario, ANTAG_TRAINING_SCENARIO_RUNNING) ? scenario : null

/datum/unit_test/proc/training_scenario_member(datum/antag_training_scenario/scenario, side_id)
	var/list/members = scenario.side_members(side_id)
	return length(members) ? members[1] : null

/// Партия дошла до итога с этим победителем; null - без победителя.
/datum/unit_test/proc/training_scenario_ended(datum/antag_training_scenario/scenario, winner)
	return training_scenario_wait(scenario, ANTAG_TRAINING_SCENARIO_SUMMARY, 10 SECONDS) && scenario.summary["winner"] == winner

/datum/unit_test/proc/training_scenario_state(datum/antag_training_scenario/scenario)
	return QDELETED(scenario) ? "сценарий удалён" : "фаза [scenario.phase], итог [json_encode(scenario.summary)], цели [json_encode(scenario.objectives_entries())]"

/datum/unit_test/proc/training_scenario_near_mark(datum/antag_training_scenario/scenario, mob/body, side_key)
	for(var/turf/mark as anything in scenario.venue.side_turfs(side_key))
		if(get_dist(body, mark) <= ANTAG_TRAINING_SPAWN_RADIUS)
			return TRUE
	return FALSE

/datum/unit_test/proc/training_scenario_cuff(mob/living/carbon/prisoner)
	prisoner.handcuffed = new /obj/item/restraints/handcuffs(prisoner)
	prisoner.update_handcuffed()

/// Выбор, слоты, старт, задержание, итог, повтор, время, смена сторон, «Завершить» с прежними ролями и снятой бронью.
/datum/unit_test/antag_training_scenario_lifecycle/Run()
	var/list/sessions = training_scenario_squad(3)
	TEST_ASSERT(length(sessions) == 3, "Группа из трёх участников.")
	var/datum/antag_training_session/leader = sessions[1]
	var/datum/antag_training_session/first = sessions[2]
	var/datum/antag_training_session/second = sessions[3]
	var/datum/antag_training_arena/arena = leader.arena
	var/datum/antag_training_sector/station = arena.sectors["station"]
	training_squad_act(first, "scenario_pick", list("id" = "traitor_security"))
	TEST_ASSERT_NULL(leader.squad.scenario, "Сценарий выбирает только лидер.")
	var/datum/antag_training_scenario/scenario = training_scenario_pick(leader, "traitor_security")
	TEST_ASSERT_NOTNULL(scenario, "Лидер выбирает шаблон, сектор занимается и грузится.")
	TEST_ASSERT_EQUAL(station.booked_by, leader.squad, "Сектор шаблона забронирован группой.")
	var/list/data = first.ui_data(first.current_body)
	TEST_ASSERT(length(data["scenario_templates"]) >= 9, "Пульт показывает восемь шаблонов и пустой лист.")
	TEST_ASSERT_EQUAL(data["scenario"]?["phase"], ANTAG_TRAINING_SCENARIO_SETUP, "Участник видит лист слотов.")
	var/datum/antag_training_scenario_slot/traitor_slot = training_scenario_slot(scenario, "Предатель")
	var/datum/antag_training_scenario_slot/officer_slot = training_scenario_slot(scenario, "Офицер СБ")
	training_squad_act(leader, "scenario_start")
	TEST_ASSERT_EQUAL(scenario.phase, ANTAG_TRAINING_SCENARIO_SETUP, "С пустым обязательным слотом старта нет.")
	TEST_ASSERT(findtext(leader.last_feedback, "Обязательный слот"), "Отказ называет пустой слот: [leader.last_feedback].")
	training_squad_act(first, "scenario_take", list("slot" = REF(traitor_slot)))
	training_squad_act(first, "scenario_assign", list("slot" = REF(officer_slot), "member" = REF(second)))
	TEST_ASSERT(!(second in officer_slot.occupants), "Назначает только лидер.")
	training_squad_act(leader, "scenario_assign", list("slot" = REF(officer_slot), "member" = REF(second)))
	TEST_ASSERT(first in traitor_slot.occupants, "Участник сам занимает слот.")
	TEST_ASSERT(second in officer_slot.occupants, "Лидер ставит участника в слот.")
	training_squad_act(leader, "scenario_start")
	TEST_ASSERT(training_scenario_wait(scenario, ANTAG_TRAINING_SCENARIO_RUNNING), "Партия начинается.")
	TEST_ASSERT_EQUAL(first.program.type, /datum/antag_training_program/antag/traitor, "Слот пересобирает тело программой слота.")
	TEST_ASSERT_EQUAL(first.role.id, "crew:Assistant", "Слот задаёт должность.")
	TEST_ASSERT_EQUAL(second.role.id, "crew:Security Officer", "Офицер получает должность СБ.")
	TEST_ASSERT_EQUAL(leader.program.type, /datum/antag_training_program/free, "Лидер вне слотов остаётся при своём.")
	TEST_ASSERT(training_scenario_near_mark(scenario, first.current_body, "medbay"), "Предатель стоит у меток своей стороны.")
	TEST_ASSERT(training_scenario_near_mark(scenario, second.current_body, "security"), "Офицер стоит у меток СБ.")
	training_squad_act(first, "restart", list("program" = "[/datum/antag_training_program/free]"))
	TEST_ASSERT_EQUAL(first.program.type, /datum/antag_training_program/antag/traitor, "Во время партии программу задаёт слот.")
	data = second.ui_data(second.current_body)
	var/list/live = data["scenario"]
	TEST_ASSERT_EQUAL(length(live["objectives"]), 2, "Цели видны всем участникам.")
	TEST_ASSERT(live["remaining"] > 0, "Таймер идёт.")
	first.current_body.forceMove(scenario.venue.mark_turf("brig"))
	training_scenario_cuff(first.current_body)
	TEST_ASSERT(training_scenario_ended(scenario, "security"), "Предатель в наручниках в бриге: итог с победителем security, а [training_scenario_state(scenario)].")
	TEST_ASSERT(scenario.summary["time"] >= 0 && length(scenario.summary["objectives"]) == 2, "Итог с временем и целями.")
	var/mob/living/carbon/old_body = first.current_body
	training_squad_act(leader, "scenario_replay")
	TEST_ASSERT(training_scenario_wait(scenario, ANTAG_TRAINING_SCENARIO_RUNNING), "Повтор запускает партию заново.")
	var/mob/living/carbon/replayed = first.current_body
	TEST_ASSERT(replayed != old_body && !replayed.handcuffed, "Повтор собирает тело заново.")
	TEST_ASSERT_EQUAL(scenario.runs, 2, "Вторая партия.")
	scenario.started_at = world.time - scenario.time_limit
	TEST_ASSERT(training_scenario_ended(scenario, "security"), "Время вышло: итог с победителем security, а [training_scenario_state(scenario)].")
	TEST_ASSERT_EQUAL(scenario.summary["reason"], "Время вышло.", "Итог называет причину.")
	training_squad_act(leader, "scenario_swap")
	TEST_ASSERT(training_scenario_wait(scenario, ANTAG_TRAINING_SCENARIO_RUNNING), "Смена сторон запускает партию.")
	TEST_ASSERT(second in traitor_slot.occupants, "Офицер стал предателем.")
	TEST_ASSERT(first in officer_slot.occupants, "Предатель стал офицером.")
	TEST_ASSERT_EQUAL(second.program.type, /datum/antag_training_program/antag/traitor, "Новая программа после смены сторон.")
	TEST_ASSERT_EQUAL(first.role.id, "crew:Security Officer", "Новая должность после смены сторон.")
	training_squad_act(leader, "scenario_end")
	TEST_ASSERT(training_scenario_ended(scenario, null), "Лидер остановил партию: итог с победителем null, а [training_scenario_state(scenario)].")
	var/datum/antag_training_scenario_objective/steal/steal = locate() in scenario.objectives
	var/obj/item/documents = steal?.item_ref?.resolve()
	TEST_ASSERT_NOTNULL(documents, "Документы лежат до конца сценария.")
	training_squad_act(leader, "scenario_finish")
	TEST_ASSERT(QDELETED(scenario), "«Завершить» закрывает сценарий.")
	TEST_ASSERT_NULL(leader.squad.scenario, "У группы нет сценария.")
	TEST_ASSERT_NULL(station.booked_by, "«Завершить» снимает бронь.")
	TEST_ASSERT(QDELETED(documents), "Реквизит сценария убран.")
	TEST_ASSERT(wait_for_var(second, "role", antag_training_role(ANTAG_TRAINING_ROLE_DEFAULT), 10 SECONDS), "Прежняя роль вернулась.")
	TEST_ASSERT(wait_for_var(first, "role", antag_training_role(ANTAG_TRAINING_ROLE_DEFAULT), 10 SECONDS), "Прежняя роль вернулась и второму.")
	TEST_ASSERT_EQUAL(second.program.type, /datum/antag_training_program/free, "Прежняя программа вернулась.")
	TEST_ASSERT_EQUAL(get_turf(second.current_body), arena.hub_arrival(), "Все в вестибюле хаба.")

/// Пустой лист: слоты правит только лидер, несовместимую пару роль-программа не принять, без целей партия идёт до ручного итога.
/datum/unit_test/antag_training_scenario_custom/Run()
	var/list/sessions = training_scenario_squad(2)
	TEST_ASSERT(length(sessions) == 2, "Группа из двух участников.")
	var/datum/antag_training_session/leader = sessions[1]
	var/datum/antag_training_session/member = sessions[2]
	var/datum/antag_training_scenario/scenario = training_scenario_pick(leader, "custom", "dark")
	TEST_ASSERT_NOTNULL(scenario, "Пустой лист в выбранном секторе.")
	TEST_ASSERT_EQUAL(scenario.venue.id(), "dark", "Своя сборка идёт в выбранном секторе.")
	TEST_ASSERT(!length(scenario.slots), "Лист пуст.")
	training_squad_act(member, "scenario_slot_add", list("side" = "a", "role" = "crew:Security Officer"))
	TEST_ASSERT(!length(scenario.slots), "Слоты добавляет только лидер.")
	training_squad_act(leader, "scenario_slot_add", list("side" = "a", "role" = "crew:Security Officer", "program" = ""))
	TEST_ASSERT_EQUAL(length(scenario.slots), 1, "Лидер добавляет слот.")
	training_squad_act(leader, "scenario_slot_add", list("side" = "b", "role" = "silicon:cyborg", "program" = "[/datum/antag_training_program/antag/traitor]"))
	TEST_ASSERT_EQUAL(length(scenario.slots), 1, "Киборг-предатель не принимается.")
	TEST_ASSERT(findtext(leader.last_feedback, "человеческое тело"), "Отказ объясняет несовместимость: [leader.last_feedback].")
	training_squad_act(leader, "scenario_slot_add", list("side" = "b", "role" = ANTAG_TRAINING_ROLE_DEFAULT, "program" = "[/datum/antag_training_program/creature/xeno]", "count" = 2))
	TEST_ASSERT_EQUAL(length(scenario.slots), 2, "Ксеноморф на второй стороне.")
	var/datum/antag_training_scenario_slot/officer = scenario.slots[1]
	var/datum/antag_training_scenario_slot/xeno = scenario.slots[2]
	TEST_ASSERT_EQUAL(xeno.count, 2, "Число мест задаётся при добавлении.")
	training_squad_act(leader, "scenario_slot_edit", list("slot" = REF(officer), "field" = "program", "value" = "[/datum/antag_training_program/antag/traitor]"))
	TEST_ASSERT_EQUAL(officer.program_type, /datum/antag_training_program/antag/traitor, "Программа слота меняется.")
	training_squad_act(leader, "scenario_slot_edit", list("slot" = REF(officer), "field" = "role", "value" = "silicon:cyborg"))
	TEST_ASSERT_EQUAL(officer.role_id, "crew:Security Officer", "Роль, несовместимая с программой слота, не ставится.")
	training_squad_act(leader, "scenario_slot_edit", list("slot" = REF(officer), "field" = "side", "value" = "c"))
	TEST_ASSERT_EQUAL(officer.side, "c", "Сторона слота меняется.")
	training_squad_act(leader, "scenario_slot_edit", list("slot" = REF(officer), "field" = "side", "value" = "z"))
	TEST_ASSERT_EQUAL(officer.side, "c", "Несуществующую сторону не поставить.")
	training_squad_act(leader, "scenario_slot_edit", list("slot" = REF(officer), "field" = "count", "value" = 99))
	TEST_ASSERT_EQUAL(officer.count, ANTAG_TRAINING_SCENARIO_SLOT_SEATS, "Мест не больше предела.")
	training_squad_act(leader, "scenario_slot_add", list("side" = "d"))
	TEST_ASSERT_EQUAL(length(scenario.slots), 3, "Третий слот.")
	training_squad_act(member, "scenario_slot_remove", list("slot" = REF(scenario.slots[3])))
	TEST_ASSERT_EQUAL(length(scenario.slots), 3, "Убирает слот только лидер.")
	training_squad_act(leader, "scenario_slot_remove", list("slot" = REF(scenario.slots[3])))
	TEST_ASSERT_EQUAL(length(scenario.slots), 2, "Лидер убирает слот.")
	training_squad_act(leader, "scenario_take", list("slot" = REF(officer)))
	training_squad_act(member, "scenario_take", list("slot" = REF(xeno)))
	training_squad_act(leader, "scenario_start")
	TEST_ASSERT(training_scenario_wait(scenario, ANTAG_TRAINING_SCENARIO_RUNNING), "Своя сборка начинается.")
	TEST_ASSERT_EQUAL(member.program.type, /datum/antag_training_program/creature/xeno, "Ксеноморф собран.")
	TEST_ASSERT_EQUAL(leader.program.type, /datum/antag_training_program/antag/traitor, "Предатель-офицер собран.")
	TEST_ASSERT(scenario.venue.contains(member.current_body), "Ксеноморф в секторе.")
	TEST_ASSERT(!length(scenario.objectives), "Без целей - свободная игра.")
	sleep(ANTAG_TRAINING_SCENARIO_CHECK * 2)
	TEST_ASSERT_EQUAL(scenario.phase, ANTAG_TRAINING_SCENARIO_RUNNING, "Без целей партия сама не кончается.")
	training_squad_act(member, "scenario_end")
	TEST_ASSERT_EQUAL(scenario.phase, ANTAG_TRAINING_SCENARIO_RUNNING, "Итог подводит лидер.")
	training_squad_act(leader, "scenario_end")
	TEST_ASSERT(training_scenario_ended(scenario, null), "Свободная игра: итог с победителем null, а [training_scenario_state(scenario)].")
	training_squad_act(leader, "scenario_finish")
	TEST_ASSERT(QDELETED(scenario), "Своя сборка закрыта.")

/// Своя сборка с целями из библиотеки: лидер добавляет и убирает цели сторон с параметрами из мест сектора, партия доходит до итога по ним.
/datum/unit_test/antag_training_scenario_custom_objectives/Run()
	var/list/sessions = training_scenario_squad(2)
	TEST_ASSERT(length(sessions) == 2, "Группа из двух участников.")
	var/datum/antag_training_session/leader = sessions[1]
	var/datum/antag_training_session/member = sessions[2]
	var/datum/antag_training_scenario/scenario = training_scenario_pick(leader, "custom", "dark")
	TEST_ASSERT_NOTNULL(scenario, "Пустой лист в тёмном секторе.")
	var/list/entry = leader.ui_data(leader.current_body)["scenario"]
	var/list/kinds = list()
	var/list/zones
	for(var/list/kind as anything in entry["objective_library"])
		kinds += kind["id"]
		if(kind["id"] == "detain")
			for(var/list/param as anything in kind["params"])
				if(param["key"] == "zone")
					zones = param["options"]
	TEST_ASSERT(("survive" in kinds) && ("side_down" in kinds) && ("detain" in kinds), "Библиотека предлагает основные цели: [kinds.Join(", ")].")
	TEST_ASSERT(!("restore_pressure" in kinds), "Пробой предлагается только в атмос-секторе.")
	var/list/zone_ids = list()
	for(var/list/option as anything in zones)
		zone_ids += option["value"]
	TEST_ASSERT(("side:depths" in zone_ids) && !("brig" in zone_ids), "Места цели - метки этого сектора: [zone_ids.Join(", ")].")
	training_squad_act(member, "scenario_objective_add", list("kind" = "survive", "side" = "a", "minutes" = "1"))
	TEST_ASSERT(!length(scenario.objective_specs), "Цели добавляет только лидер.")
	training_squad_act(leader, "scenario_objective_add", list("kind" = "detain", "side" = "b", "target" = "a", "zone" = "brig"))
	TEST_ASSERT(!length(scenario.objective_specs), "Место из другого сектора не принимается.")
	TEST_ASSERT(findtext(leader.last_feedback, "Такого места нет"), "Отказ объясняет выбор места: [leader.last_feedback].")
	training_squad_act(leader, "scenario_objective_add", list("kind" = "side_down", "side" = "b", "target" = "b"))
	TEST_ASSERT(!length(scenario.objective_specs), "Свою сторону противником не выбрать.")
	training_squad_act(leader, "scenario_objective_add", list("kind" = "survive", "side" = "a", "minutes" = "1"))
	training_squad_act(leader, "scenario_objective_add", list("kind" = "side_down", "side" = "b", "target" = "a"))
	training_squad_act(leader, "scenario_objective_add", list("kind" = "detain", "side" = "b", "target" = "a", "zone" = "side:depths"))
	TEST_ASSERT_EQUAL(length(scenario.objective_specs), 3, "Лидер добавил три цели.")
	training_squad_act(leader, "scenario_objective_remove", list("index" = 3))
	TEST_ASSERT_EQUAL(length(scenario.objective_specs), 2, "Лидер убрал цель.")
	entry = member.ui_data(member.current_body)["scenario"]
	TEST_ASSERT(!entry["free_play"], "С целями партия не свободная.")
	var/list/specs = entry["objective_specs"]
	TEST_ASSERT(length(specs) == 2 && specs[1]["name"] == "Продержаться 1 мин" && specs[2]["side"] == "b", "Участники видят цели листа: [json_encode(specs)].")
	training_squad_act(leader, "scenario_slot_add", list("side" = "a", "role" = "crew:Security Officer"))
	training_squad_act(leader, "scenario_take", list("slot" = REF(scenario.slots[1])))
	training_squad_act(leader, "scenario_start")
	TEST_ASSERT_EQUAL(scenario.phase, ANTAG_TRAINING_SCENARIO_SETUP, "С целью пустой стороны старта нет.")
	TEST_ASSERT(findtext(leader.last_feedback, "Сторона Б"), "Отказ называет сторону без участников: [leader.last_feedback].")
	training_squad_act(leader, "scenario_slot_add", list("side" = "b", "role" = "crew:Assistant"))
	training_squad_act(member, "scenario_take", list("slot" = REF(scenario.slots[2])))
	training_squad_act(leader, "scenario_start")
	TEST_ASSERT(training_scenario_wait(scenario, ANTAG_TRAINING_SCENARIO_RUNNING), "Своя сборка с целями начинается.")
	TEST_ASSERT_EQUAL(length(scenario.objectives), 2, "Цели листа идут как цели шаблона.")
	sleep(ANTAG_TRAINING_SCENARIO_CHECK * 2)
	TEST_ASSERT_EQUAL(scenario.phase, ANTAG_TRAINING_SCENARIO_RUNNING, "Минута не прошла - партия идёт.")
	scenario.started_at = world.time - 1 MINUTES
	TEST_ASSERT(training_scenario_ended(scenario, "a"), "Сторона А продержалась минуту: итог с победителем a, а [training_scenario_state(scenario)].")
	training_squad_act(leader, "scenario_finish")
	TEST_ASSERT(QDELETED(scenario), "Своя сборка закрыта.")

/datum/unit_test/antag_training_scenario_traitor/Run()
	var/datum/antag_training_scenario/scenario = training_scenario_launch("traitor_security", 2)
	TEST_ASSERT_NOTNULL(scenario, "«Предатель против СБ» начинается.")
	var/datum/antag_training_session/traitor = training_scenario_member(scenario, "traitor")
	var/datum/antag_training_scenario_objective/steal/steal = locate() in scenario.objectives
	var/obj/item/documents = steal.item_ref.resolve()
	TEST_ASSERT_NOTNULL(documents, "Документы лежат в кабинете главы.")
	TEST_ASSERT_EQUAL(get_turf(documents), scenario.venue.mark_turf("head_office"), "Документы у метки кабинета.")
	var/mob/living/carbon/human/body = traitor.current_body
	body.forceMove(scenario.venue.mark_turf("arrivals"))
	documents.forceMove(get_turf(body))
	sleep(ANTAG_TRAINING_SCENARIO_CHECK * 2)
	TEST_ASSERT_EQUAL(scenario.phase, ANTAG_TRAINING_SCENARIO_RUNNING, "Документы на полу в зоне не засчитываются.")
	body.put_in_hands(documents)
	TEST_ASSERT(training_scenario_ended(scenario, "traitor"), "Документы вынесены: итог с победителем traitor, а [training_scenario_state(scenario)].")

/datum/unit_test/antag_training_scenario_decompression/Run()
	var/datum/antag_training_scenario/scenario = training_scenario_launch("decompression", 1)
	TEST_ASSERT_NOTNULL(scenario, "«Разгерметизация» начинается.")
	var/datum/antag_training_sector/place = scenario.venue.sector()
	var/datum/antag_training_exercise/systems/breach/breach = GLOB.antag_training_exercises["atmos_breach"]
	TEST_ASSERT(!breach.pressure_restored(place), "На старте окно камеры выбито.")
	var/datum/antag_training_scenario_objective/heal/heal = locate() in scenario.objectives
	TEST_ASSERT_EQUAL(length(heal.patients), 3, "Трое пострадавших.")
	breach.restore(null, place)
	var/list/spot = breach.breach(place)
	for(var/obj/machinery/door/firedoor/closed in spot[1])
		INVOKE_ASYNC(closed, TYPE_PROC_REF(/obj/machinery/door, open))
	var/list/budget = new_wait_budget(5 SECONDS, "заслонка открыта")
	var/obj/machinery/door/firedoor/shutter = locate() in spot[1]
	while(shutter?.density && wait_budget_tick(budget))
		continue
	for(var/turf/open/floor in place.turfs)
		if(!isspaceturf(floor))
			floor.air.copy_from_turf(floor)
			floor.air_update_turf(FALSE, FALSE)
	sleep(ANTAG_TRAINING_SCENARIO_CHECK * 2)
	TEST_ASSERT_EQUAL(scenario.phase, ANTAG_TRAINING_SCENARIO_RUNNING, "Одного пробоя мало: пострадавшие не вылечены.")
	for(var/datum/weakref/patient_ref as anything in heal.patients)
		var/mob/living/patient = patient_ref.resolve()
		patient.revive(full_heal = TRUE, admin_revive = TRUE)
	TEST_ASSERT(training_scenario_ended(scenario, "crew"), "Пробой заделан, пострадавшие вылечены: итог с победителем crew, а [training_scenario_state(scenario)].")

/datum/unit_test/antag_training_scenario_blackout/Run()
	var/datum/antag_training_scenario/scenario = training_scenario_launch("blackout", 1)
	TEST_ASSERT_NOTNULL(scenario, "«Блэкаут» начинается.")
	var/area/place = scenario.venue.power_area()
	TEST_ASSERT(!place.powered(LIGHT), "На старте сектор обесточен.")
	var/obj/machinery/power/apc/board = locate() in place
	board.cell.charge = board.cell.maxcharge
	board.operating = TRUE
	board.lighting = board.setsubsystem(3)
	board.equipment = board.setsubsystem(3)
	board.environ = board.setsubsystem(3)
	board.update()
	TEST_ASSERT(training_scenario_ended(scenario, "engineers"), "Питание возвращено: итог с победителем engineers, а [training_scenario_state(scenario)].")

/datum/unit_test/antag_training_scenario_raid/Run()
	var/datum/antag_training_scenario/scenario = training_scenario_launch("raid", 2)
	TEST_ASSERT_NOTNULL(scenario, "«Налёт» начинается.")
	var/datum/antag_training_session/operative = training_scenario_member(scenario, "operatives")
	var/datum/antag_training_program/antag/nukeop/program = operative.program
	var/list/budget = new_wait_budget(10 SECONDS, "учебная бомба в хранилище")
	while(!program.training_bomb() && wait_budget_tick(budget))
		continue
	TEST_ASSERT_NOTNULL(program.training_bomb(), "Учебная бомба в хранилище.")
	TEST_ASSERT_NOTNULL(program.detonation_objective, "Задача взрыва выдана.")
	program.nuke_detonated(program.training_bomb())
	TEST_ASSERT(training_scenario_ended(scenario, "operatives"), "Учебная бомба взорвана: итог с победителем operatives, а [training_scenario_state(scenario)].")

/datum/unit_test/antag_training_scenario_revolution/Run()
	var/datum/antag_training_scenario/scenario = training_scenario_launch("revolution", 2)
	TEST_ASSERT_NOTNULL(scenario, "«Революция» начинается.")
	var/datum/antag_training_session/captain = training_scenario_member(scenario, "heads")
	TEST_ASSERT(HAS_TRAIT(captain.current_body, TRAIT_MINDSHIELD), "Глава с майндшилдом.")
	training_scenario_cuff(captain.current_body)
	TEST_ASSERT(training_scenario_ended(scenario, "revolution"), "Все главы закованы: итог с победителем revolution, а [training_scenario_state(scenario)].")

/datum/unit_test/antag_training_scenario_malf/Run()
	var/datum/antag_training_scenario/scenario = training_scenario_launch("malf", 2)
	TEST_ASSERT_NOTNULL(scenario, "«ИИ-сбой» начинается.")
	var/datum/antag_training_session/ai = training_scenario_member(scenario, "ai")
	var/mob/living/silicon/ai/core = ai.current_body
	TEST_ASSERT(istype(core), "Сбойный ИИ в ядре.")
	TEST_ASSERT(scenario.venue.contains(core), "Ядро в секторе.")
	core.death()
	TEST_ASSERT(training_scenario_ended(scenario, "crew"), "ИИ выведен из строя: итог с победителем crew, а [training_scenario_state(scenario)].")

/datum/unit_test/antag_training_scenario_xeno/Run()
	var/datum/antag_training_scenario/scenario = training_scenario_launch("xeno", 2)
	TEST_ASSERT_NOTNULL(scenario, "«Ксеноугроза» начинается.")
	var/datum/antag_training_session/xeno = training_scenario_member(scenario, "xeno")
	var/mob/living/carbon/alien/alien = xeno.current_body
	TEST_ASSERT(istype(alien), "Ксеноморф собран.")
	TEST_ASSERT(training_scenario_near_mark(scenario, alien, "depths"), "Ксеноморф выходит из дальних комнат.")
	alien.death()
	TEST_ASSERT(training_scenario_ended(scenario, "security"), "Ксеноморфы уничтожены: итог с победителем security, а [training_scenario_state(scenario)].")

/datum/unit_test/antag_training_scenario_cult/Run()
	var/datum/antag_training_scenario/scenario = training_scenario_launch("cult", 2)
	TEST_ASSERT_NOTNULL(scenario, "«Культ» начинается.")
	var/datum/antag_training_session/cultist = training_scenario_member(scenario, "cult")
	TEST_ASSERT(iscultist(cultist.current_body), "Культист собран.")
	var/mob/living/body = cultist.current_body
	body.death()
	TEST_ASSERT(training_scenario_ended(scenario, "crew"), "Культисты выведены из строя: итог с победителем crew, а [training_scenario_state(scenario)].")

/// «Война культов»: одна сторона без противника не стартует; культ Нар'Си и слуги Ратвара встают у своих меток, выбывший последний культист - победа слуг.
/datum/unit_test/antag_training_scenario_cult_war/Run()
	var/list/sessions = training_scenario_squad(2)
	TEST_ASSERT(length(sessions) == 2, "Группа из двух.")
	var/datum/antag_training_session/leader = sessions[1]
	var/datum/antag_training_session/other = sessions[2]
	var/datum/antag_training_scenario/scenario = training_scenario_pick(leader, "cult_war")
	TEST_ASSERT_NOTNULL(scenario, "«Война культов» выбрана.")
	var/datum/antag_training_scenario_slot/blood_slot = training_scenario_slot(scenario, "Культист Нар'Си")
	var/datum/antag_training_scenario_slot/clock_slot = training_scenario_slot(scenario, "Слуга Ратвара")
	training_squad_act(leader, "scenario_assign", list("slot" = REF(blood_slot), "member" = REF(leader)))
	training_squad_act(leader, "scenario_assign", list("slot" = REF(blood_slot), "member" = REF(other)))
	training_squad_act(leader, "scenario_start")
	TEST_ASSERT_EQUAL(scenario.phase, ANTAG_TRAINING_SCENARIO_SETUP, "Без слуг Ратвара партия не начинается.")
	TEST_ASSERT(findtext(leader.last_feedback, "Ратвара"), "Отказ называет пустую сторону: [leader.last_feedback].")
	TEST_ASSERT(findtext(scenario.objective_side_problem(), "Слуги Ратвара"), "Цель культа без противника - ошибка листа: [scenario.objective_side_problem()].")
	training_squad_act(leader, "scenario_assign", list("slot" = REF(clock_slot), "member" = REF(other)))
	TEST_ASSERT_NULL(scenario.objective_side_problem(), "Обе стороны заняты: проверка целей пропускает.")
	training_squad_act(leader, "scenario_start")
	TEST_ASSERT(training_scenario_wait(scenario, ANTAG_TRAINING_SCENARIO_RUNNING), "Партия начинается: [training_scenario_state(scenario)].")
	TEST_ASSERT(iscultist(leader.current_body), "Культист Нар'Си собран.")
	TEST_ASSERT(is_servant_of_ratvar(other.current_body), "Слуга Ратвара собран.")
	TEST_ASSERT(training_scenario_near_mark(scenario, leader.current_body, "ritual"), "Культ Нар'Си начинает в ритуальном зале.")
	TEST_ASSERT(training_scenario_near_mark(scenario, other.current_body, "command"), "Слуги Ратвара начинают на мостике.")
	var/mob/living/body = leader.current_body
	body.death()
	TEST_ASSERT(training_scenario_ended(scenario, "clock"), "Культ Нар'Си выведен из строя: итог с победителем clock, а [training_scenario_state(scenario)].")

/// Стенд закрывает чужой сценарий: прежние роли, снятая бронь, запись в логе администрации; без стенда - нет.
/datum/unit_test/antag_training_scenario_stand/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон подготовлен.")
	var/datum/tgui/ui = allocate_stand_ui(session)
	var/datum/antag_training_arena/arena = session.arena
	var/datum/antag_training_session/leader = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(leader.prepare(arena), "Лидер группы вошёл.")
	training_squad_act(leader, "squad_create", list("name" = "Альфа"))
	var/datum/antag_training_squad/squad = leader.squad
	var/datum/antag_training_scenario/scenario = training_scenario_pick(leader, "custom", "dark")
	TEST_ASSERT_NOTNULL(scenario, "Своя сборка в тёмном секторе.")
	training_squad_act(leader, "scenario_slot_add", list("side" = "a", "role" = "crew:Security Officer"))
	training_squad_act(leader, "scenario_take", list("slot" = REF(scenario.slots[1])))
	training_squad_act(leader, "scenario_start")
	TEST_ASSERT(training_scenario_wait(scenario, ANTAG_TRAINING_SCENARIO_RUNNING), "Партия идёт.")
	TEST_ASSERT_EQUAL(leader.role.id, "crew:Security Officer", "Лидер в роли слота.")
	antag_training_console_act(session, ui, "stand_release", list("kind" = "scenario", "id" = REF(squad)))
	TEST_ASSERT(!QDELETED(scenario), "Без стенда чужой сценарий не закрыть.")
	grant_stand_rights(session, mentor = TRUE)
	antag_training_console_act(session, ui, "stand_toggle", list())
	var/list/squads = session.ui_data(session.current_body)["stand"]["squads"]
	TEST_ASSERT(length(squads) == 1 && squads[1]["scenario"] == scenario.name, "Стенд видит сценарий группы.")
	antag_training_console_act(session, ui, "stand_release", list("kind" = "scenario", "id" = REF(squad)))
	TEST_ASSERT(QDELETED(scenario), "Стенд закрывает сценарий.")
	TEST_ASSERT_NULL(squad.scenario, "У группы нет сценария.")
	var/datum/antag_training_sector/dark = arena.sectors["dark"]
	TEST_ASSERT_NULL(dark.booked_by, "Бронь сценария снята.")
	TEST_ASSERT(findtext(last_admin_log(), "завершил сценарий «Своя сборка» группы «Альфа»"), "Закрытие записано в лог администрации: [last_admin_log()].")
	TEST_ASSERT(wait_for_var(leader, "role", antag_training_role(ANTAG_TRAINING_ROLE_DEFAULT), 10 SECONDS), "Лидеру вернулась прежняя роль.")
	session.current_body.mock_client = null

/// Участник идущей партии не лечится, не переходит, не ставит цели и не пополняет ресурсы пультом; снаряжение пульта выдаётся.
/datum/unit_test/antag_training_scenario_console_locks/Run()
	var/datum/antag_training_scenario/scenario = training_scenario_launch("traitor_security", 2)
	TEST_ASSERT_NOTNULL(scenario, "«Предатель против СБ» начинается.")
	var/datum/antag_training_session/traitor = training_scenario_member(scenario, "traitor")
	var/datum/antag_training_arena/arena = traitor.arena
	var/mob/living/carbon/human/body = traitor.current_body
	var/turf/brig = scenario.venue.mark_turf("brig")
	body.forceMove(brig)
	training_scenario_cuff(body)
	training_squad_act(traitor, "heal")
	TEST_ASSERT(body.handcuffed, "Пульт не снимает наручники участнику партии.")
	TEST_ASSERT(findtext(traitor.last_feedback, "Идёт сценарий"), "Отказ объясняет почему: [traitor.last_feedback].")
	training_squad_act(traitor, "hub")
	training_squad_act(traitor, "move", list("zone" = "melee"))
	training_squad_act(traitor, "kit", list("id" = "melee"))
	training_squad_act(traitor, "sector_enter", list("id" = "dark"))
	TEST_ASSERT_EQUAL(get_turf(body), brig, "Пульт не уводит закованного из брига.")
	var/targets = length(arena.targets)
	training_squad_act(traitor, "spawn", list("id" = "human", "zone" = "melee"))
	TEST_ASSERT_EQUAL(length(arena.targets), targets, "Участник партии не ставит учебные цели.")
	training_squad_act(traitor, "program_option", list("option" = "Пополнить ТК"))
	TEST_ASSERT(findtext(traitor.last_feedback, "Пополнить ТК"), "Пополнение ресурсов во время партии закрыто: [traitor.last_feedback].")
	training_squad_act(traitor, "equipment", list("id" = "baton"))
	TEST_ASSERT_NOTNULL(locate(/obj/item/melee/baton/loaded) in brig, "Снаряжение пульта выдаётся и во время партии.")
	TEST_ASSERT(body.handcuffed && get_turf(body) == brig && scenario.phase == ANTAG_TRAINING_SCENARIO_RUNNING, "Партия идёт, предатель всё ещё в бриге.")

/// Реквизит партии (пострадавших) не лечат и не убирают пультом ни участники, ни зрители из группы.
/datum/unit_test/antag_training_scenario_props_locked/Run()
	var/datum/antag_training_scenario/scenario = training_scenario_launch("decompression", 2)
	TEST_ASSERT_NOTNULL(scenario, "«Разгерметизация» начинается.")
	var/datum/antag_training_session/medic = training_scenario_member(scenario, "crew")
	var/list/watchers = scenario.squad.members - scenario.assigned()
	TEST_ASSERT_EQUAL(length(watchers), 1, "Один из группы смотрит со стороны.")
	var/datum/antag_training_session/watcher = watchers[1]
	var/datum/antag_training_scenario_objective/heal/heal = locate() in scenario.objectives
	var/datum/weakref/patient_ref = heal.patients[1]
	var/mob/living/patient = patient_ref.resolve()
	TEST_ASSERT(patient.health < patient.maxHealth, "Пострадавший ранен.")
	training_squad_act(watcher, "target_heal", list("id" = REF(patient)))
	TEST_ASSERT(patient.health < patient.maxHealth, "Зритель не лечит пострадавшего пультом.")
	training_squad_act(medic, "target_heal", list("id" = REF(patient)))
	TEST_ASSERT(patient.health < patient.maxHealth, "Участник не лечит пострадавшего пультом.")
	training_squad_act(watcher, "target_delete", list("id" = REF(patient)))
	TEST_ASSERT(!QDELETED(patient), "Пострадавшего не убрать пультом.")
	training_squad_act(scenario.squad.leader, "clean_personal")
	sleep(1)
	TEST_ASSERT(!QDELETED(patient), "Очистка своих объектов не трогает реквизит партии.")

/// Шкаф раздевалки и стенд ментора не меняют роль участнику партии; админ стендом меняет, и это видно в логе.
/datum/unit_test/antag_training_scenario_role_lock/Run()
	var/datum/antag_training_scenario/scenario = training_scenario_launch("traitor_security", 2)
	TEST_ASSERT_NOTNULL(scenario, "«Предатель против СБ» начинается.")
	var/datum/antag_training_session/traitor = training_scenario_member(scenario, "traitor")
	var/obj/structure/antag_training_wardrobe/wardrobe = antag_training_hub_find(traitor.arena.hub, /obj/structure/antag_training_wardrobe/engineering)
	TEST_ASSERT_NOTNULL(wardrobe, "В раздевалке есть шкаф инженерии.")
	var/mob/living/carbon/human/body = traitor.current_body
	body.forceMove(get_step(wardrobe, EAST))
	var/datum/tgui/ui = allocate(/datum/tgui, body, wardrobe, "AntagTrainingWardrobe")
	ui.status = UI_INTERACTIVE
	traitor.next_restart_at = 0
	usr = body
	GLOB.unit_test_chat_capture = list()
	wardrobe.ui_act("set_role", list("role" = "crew:Station Engineer"), ui)
	var/list/told = list()
	for(var/list/entry as anything in GLOB.unit_test_chat_capture)
		if(entry[1] == body || entry[1] == body.client)
			told += entry[2]
	GLOB.unit_test_chat_capture = null
	usr = null
	TEST_ASSERT_EQUAL(traitor.role.id, "crew:Assistant", "Шкаф не меняет должность участнику партии.")
	TEST_ASSERT(length(told) == 1 && findtext(told[1], "Идёт сценарий"), "Отказ шкафа - одно сообщение о сценарии: [json_encode(told)].")
	TEST_ASSERT_EQUAL(traitor.current_body, body, "Тело участника не пересобрано.")
	var/datum/antag_training_session/operator = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(operator.prepare(traitor.arena), "Ментор вошёл на полигон.")
	var/datum/tgui/stand_ui = allocate_stand_ui(operator)
	grant_stand_rights(operator, mentor = TRUE)
	antag_training_console_act(operator, stand_ui, "stand_toggle", list())
	antag_training_console_act(operator, stand_ui, "stand_role", list("id" = REF(traitor), "role" = "crew:Station Engineer"))
	TEST_ASSERT_EQUAL(traitor.role.id, "crew:Assistant", "Стенд ментора не меняет должность участнику партии.")
	antag_training_console_act(operator, stand_ui, "stand_program", list("id" = REF(traitor), "program" = "[/datum/antag_training_program/free]"))
	TEST_ASSERT_EQUAL(traitor.program.type, /datum/antag_training_program/antag/traitor, "Стенд ментора не меняет программу участнику партии.")
	grant_stand_rights(operator, R_ADMIN)
	antag_training_console_act(operator, stand_ui, "stand_role", list("id" = REF(traitor), "role" = "crew:Station Engineer"))
	TEST_ASSERT_EQUAL(traitor.role.id, "crew:Station Engineer", "Админ стендом меняет должность и во время партии.")
	TEST_ASSERT(findtext(last_admin_log(), "сменил должность"), "Смена записана в лог администрации: [last_admin_log()].")
	operator.current_body.mock_client = null

/// Выбывший участник идущей партии не проходит врата её сектора: отказ сразу, а не вывод следующим тиком.
/datum/unit_test/antag_training_scenario_eliminated_gate/Run()
	var/list/sessions = training_scenario_squad(3)
	TEST_ASSERT(length(sessions) == 3, "Группа из трёх.")
	var/datum/antag_training_session/leader = sessions[1]
	var/datum/antag_training_scenario/scenario = training_scenario_pick(leader, "traitor_security")
	TEST_ASSERT_NOTNULL(scenario, "«Предатель против СБ» выбран.")
	training_squad_act(leader, "scenario_assign", list("slot" = REF(training_scenario_slot(scenario, "Предатель")), "member" = REF(leader)))
	for(var/index in 2 to 3)
		training_squad_act(leader, "scenario_assign", list("slot" = REF(training_scenario_slot(scenario, "Офицер СБ")), "member" = REF(sessions[index])))
	training_squad_act(leader, "scenario_start")
	TEST_ASSERT(training_scenario_wait(scenario, ANTAG_TRAINING_SCENARIO_RUNNING), "Партия начинается: [training_scenario_state(scenario)].")
	var/datum/antag_training_session/officer = sessions[2]
	var/mob/living/body = officer.current_body
	body.death()
	var/list/budget = new_wait_budget(30 SECONDS, "офицер выбыл и восстановлен в хабе")
	while(!(scenario.eliminated[officer] && body.stat != DEAD && !scenario.venue.contains(body)) && wait_budget_tick(budget))
		continue
	TEST_ASSERT(scenario.eliminated[officer] && body.stat != DEAD, "Офицер выбыл и восстановлен: [training_scenario_state(scenario)].")
	TEST_ASSERT_EQUAL(scenario.phase, ANTAG_TRAINING_SCENARIO_RUNNING, "Второй офицер держит партию.")
	var/obj/structure/antag_training_gate/gate = antag_training_hub_find(officer.arena.hub, /obj/structure/antag_training_gate/station)
	TEST_ASSERT_NOTNULL(gate, "В зале есть врата станционного макета.")
	GLOB.unit_test_chat_capture = list()
	body.forceMove(get_step(gate, SOUTH))
	body.Move(get_turf(gate), NORTH)
	var/list/told = list()
	for(var/list/entry as anything in GLOB.unit_test_chat_capture)
		if(entry[1] == body || entry[1] == body.client)
			told += entry[2]
	GLOB.unit_test_chat_capture = null
	TEST_ASSERT(length(told) && findtext(told[1], "выбыли"), "Врата сразу объясняют отказ: [json_encode(told)].")
	officer.try_enter_sector("station")
	TEST_ASSERT(findtext(officer.last_feedback, "выбыли"), "Вход в сектор партии отклонён и без врат: [officer.last_feedback].")
	TEST_ASSERT(!scenario.venue.contains(body), "Выбывший не попал на место партии.")

/// Лидер убрал слот стороны, против которой нацелена цель шаблона: старта нет.
/datum/unit_test/antag_training_scenario_template_sides/Run()
	var/list/sessions = training_scenario_squad(2)
	TEST_ASSERT(length(sessions) == 2, "Группа из двух.")
	var/datum/antag_training_session/leader = sessions[1]
	var/datum/antag_training_session/other = sessions[2]
	var/datum/antag_training_scenario/scenario = training_scenario_pick(leader, "traitor_security")
	TEST_ASSERT_NOTNULL(scenario, "«Предатель против СБ» выбран.")
	var/datum/antag_training_scenario_slot/officer_slot = training_scenario_slot(scenario, "Офицер СБ")
	training_squad_act(leader, "scenario_slot_remove", list("slot" = REF(training_scenario_slot(scenario, "Предатель"))))
	training_squad_act(leader, "scenario_assign", list("slot" = REF(officer_slot), "member" = REF(leader)))
	training_squad_act(leader, "scenario_assign", list("slot" = REF(officer_slot), "member" = REF(other)))
	training_squad_act(leader, "scenario_start")
	TEST_ASSERT_EQUAL(scenario.phase, ANTAG_TRAINING_SCENARIO_SETUP, "Без предателя партия не начинается: задерживать некого.")
	TEST_ASSERT(findtext(leader.last_feedback, "Предатель"), "Отказ называет пустую сторону: [leader.last_feedback].")

/// Убитый предатель выбыл из игры: задержание засчитано, победа СБ.
/datum/unit_test/antag_training_scenario_traitor_killed/Run()
	var/datum/antag_training_scenario/scenario = training_scenario_launch("traitor_security", 2)
	TEST_ASSERT_NOTNULL(scenario, "«Предатель против СБ» начинается.")
	var/datum/antag_training_session/traitor = training_scenario_member(scenario, "traitor")
	var/mob/living/body = traitor.current_body
	body.death()
	TEST_ASSERT(training_scenario_ended(scenario, "security"), "Убитый предатель - победа СБ, а [training_scenario_state(scenario)].")

/// Старт, упавший посреди сборки, через две минуты снимается: роль снова меняется, лист снова запускается.
/datum/unit_test/antag_training_scenario_stuck_start/Run()
	var/list/sessions = training_scenario_squad(2)
	TEST_ASSERT(length(sessions) == 2, "Группа из двух.")
	var/datum/antag_training_session/leader = sessions[1]
	var/datum/antag_training_session/member = sessions[2]
	var/datum/antag_training_scenario/scenario = training_scenario_pick(leader, "custom", "dark")
	TEST_ASSERT_NOTNULL(scenario, "Пустой лист в тёмном секторе.")
	training_squad_act(leader, "scenario_slot_add", list("side" = "a"))
	training_squad_act(member, "scenario_take", list("slot" = REF(scenario.slots[1])))
	scenario.phase = ANTAG_TRAINING_SCENARIO_STARTING
	scenario.starting_since = world.time
	member.next_restart_at = 0
	training_squad_act(member, "set_role", list("role" = "crew:Station Engineer"))
	TEST_ASSERT_EQUAL(member.role.id, ANTAG_TRAINING_ROLE_DEFAULT, "Пока старт свежий, роль задаёт слот.")
	scenario.starting_since = world.time - 2 MINUTES - 1 SECONDS
	var/list/entry = member.ui_data(member.current_body)["scenario"]
	TEST_ASSERT_EQUAL(entry["phase"], ANTAG_TRAINING_SCENARIO_SETUP, "Зависший старт снят: пульт снова показывает разбор слотов.")
	training_squad_act(member, "set_role", list("role" = "crew:Station Engineer"))
	TEST_ASSERT_EQUAL(member.role.id, "crew:Station Engineer", "После сорванного старта роль снова меняется.")
	training_squad_act(leader, "scenario_start")
	TEST_ASSERT(training_scenario_wait(scenario, ANTAG_TRAINING_SCENARIO_RUNNING), "Лист снова запускается: [training_scenario_state(scenario)].")

/// Число мест слота округляется, подпись теряет разметку и укорачивается.
/datum/unit_test/antag_training_scenario_slot_input/Run()
	var/list/sessions = training_scenario_squad(1)
	TEST_ASSERT(length(sessions) == 1, "Группа из одного.")
	var/datum/antag_training_session/leader = sessions[1]
	var/datum/antag_training_scenario/scenario = training_scenario_pick(leader, "custom", "dark")
	TEST_ASSERT_NOTNULL(scenario, "Пустой лист.")
	training_squad_act(leader, "scenario_slot_add", list("side" = "a", "count" = 2.6, "label" = "<b>Очень длинная подпись слота для проверки</b>"))
	TEST_ASSERT_EQUAL(length(scenario.slots), 1, "Слот добавлен.")
	var/datum/antag_training_scenario_slot/slot = scenario.slots[1]
	TEST_ASSERT_EQUAL(slot.count, 2, "Дробное число мест округляется вниз, как при правке слота.")
	TEST_ASSERT(!findtext(slot.label, "<") && length_char(slot.label) <= ANTAG_TRAINING_SCENARIO_LABEL_LENGTH, "Подпись без разметки и не длиннее предела: [slot.label].")

/// Своя сборка в тёмном секторе: лидер в единственном слоте, второй участник группы смотрит.
/datum/unit_test/proc/training_scenario_watched()
	var/list/sessions = training_scenario_squad(2)
	if(length(sessions) != 2)
		return null
	var/datum/antag_training_session/leader = sessions[1]
	var/datum/antag_training_scenario/scenario = training_scenario_pick(leader, "custom", "dark")
	if(!scenario)
		return null
	training_squad_act(leader, "scenario_slot_add", list("side" = "a", "role" = "crew:Assistant", "program" = ""))
	training_squad_act(leader, "scenario_take", list("slot" = REF(scenario.slots[1])))
	training_squad_act(leader, "scenario_start")
	return training_scenario_wait(scenario, ANTAG_TRAINING_SCENARIO_RUNNING) ? scenario : null

/datum/unit_test/proc/training_scenario_watcher(datum/antag_training_scenario/scenario)
	var/list/watchers = scenario.squad.members - scenario.assigned()
	return length(watchers) ? watchers[1] : null

/// Шаг на платформу врат; ответ - что врата сказали шагнувшему.
/datum/unit_test/proc/training_gate_step(mob/living/body, obj/structure/antag_training_gate/gate)
	GLOB.unit_test_chat_capture = list()
	body.forceMove(get_step(gate, SOUTH))
	body.Move(get_turf(gate), NORTH)
	. = list()
	for(var/list/entry as anything in GLOB.unit_test_chat_capture)
		if(entry[1] == body || entry[1] == body.client)
			. += entry[2]
	GLOB.unit_test_chat_capture = null

/datum/unit_test/proc/training_sector_find(datum/antag_training_sector/sector, find_type)
	var/list/bounds = sector.bounds
	var/level = sector.arena.private_level.z_value
	for(var/turf/tile as anything in block(locate(bounds[1], bounds[3], level), locate(bounds[2], bounds[4], level)))
		var/atom/movable/thing = locate(find_type) in tile
		if(thing)
			return thing
	return null

/// Участнику идущей партии закрыты кнопки всех программ, кроме их белого списка, и действия пульта вне списка партии; снаряжение пульта открыто.
/datum/unit_test/antag_training_scenario_option_whitelist/Run()
	var/datum/antag_training_scenario/scenario = training_scenario_launch("traitor_security", 2)
	TEST_ASSERT_NOTNULL(scenario, "«Предатель против СБ» начинается.")
	var/datum/antag_training_session/traitor = training_scenario_member(scenario, "traitor")
	var/datum/antag_training_program/own = traitor.program
	var/list/opened = list()
	for(var/option in own.options)
		traitor.last_feedback = null
		training_squad_act(traitor, "program_option", list("option" = option))
		if(!findtext(traitor.last_feedback, "Идёт сценарий") != !!(option in own.scenario_safe_options))
			opened += "[own.type]: [option]"
	for(var/program_type in subtypesof(/datum/antag_training_program))
		if(!antag_training_program_selectable(program_type))
			continue
		var/datum/antag_training_program/probe = new program_type
		traitor.program = probe
		for(var/option in probe.options)
			if(!traitor.scenario_refusal("program_option", list("option" = option)) != !!(option in probe.scenario_safe_options))
				opened += "[program_type]: [option]"
		traitor.program = own
		qdel(probe)
	TEST_ASSERT(!length(opened), "Кнопки программ вне белого списка закрыты участнику партии: [jointext(opened, "; ")].")
	for(var/action in list("prepare_path", "recipe", "build", "auto_recover", "reset_zone", "reset_approve", "practice", "exercise_start", "spawn", "target_hunt", "kit", "heal", "move"))
		TEST_ASSERT(traitor.scenario_refusal(action, list()), "Действие пульта «[action]» закрыто участнику партии.")
	TEST_ASSERT_NULL(traitor.scenario_refusal("equipment", list("id" = "baton")), "Снаряжение пульта открыто участнику партии.")

/// Зритель группы не входит в сектор партии ни пультом, ни вратами; админ стенда входит и в чужой; участник партии не уходит платформой и не возвращается вратами.
/datum/unit_test/antag_training_scenario_venue_entry/Run()
	var/datum/antag_training_scenario/scenario = training_scenario_watched()
	TEST_ASSERT_NOTNULL(scenario, "Партия в тёмном секторе идёт.")
	var/datum/antag_training_session/leader = scenario.squad.leader
	var/datum/antag_training_session/watcher = training_scenario_watcher(scenario)
	TEST_ASSERT_NOTNULL(watcher, "Второй участник группы смотрит.")
	var/datum/antag_training_arena/arena = leader.arena
	var/datum/antag_training_sector/sector = arena.sectors["dark"]
	var/mob/living/watcher_body = watcher.current_body
	training_squad_act(watcher, "sector_enter", list("id" = "dark"))
	TEST_ASSERT(!scenario.venue.contains(watcher_body), "Зритель группы не входит в сектор партии кнопкой пульта.")
	TEST_ASSERT(findtext(watcher.last_feedback, "только участников"), "Отказ объясняет, кого пускают: [watcher.last_feedback].")
	var/obj/structure/antag_training_gate/gate = antag_training_hub_find(arena.hub, /obj/structure/antag_training_gate/dark)
	TEST_ASSERT_NOTNULL(gate, "В зале есть врата тёмного сектора.")
	var/list/told = training_gate_step(watcher_body, gate)
	TEST_ASSERT(length(told) && findtext(told[1], "только участников"), "Врата отказывают зрителю: [json_encode(told)].")
	TEST_ASSERT(!scenario.venue.contains(watcher_body), "Зритель группы не проходит вратами.")

	var/datum/antag_training_session/admin = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(admin.prepare(arena), "Админ вошёл на полигон.")
	var/datum/tgui/stand_ui = allocate_stand_ui(admin)
	grant_stand_rights(admin, R_ADMIN)
	antag_training_console_act(admin, stand_ui, "stand_toggle", list())
	training_squad_act(admin, "sector_enter", list("id" = "dark"))
	var/admin_entered = scenario.venue.contains(admin.current_body)
	sleep(ANTAG_TRAINING_SCENARIO_CHECK * 2)
	var/admin_stayed = scenario.venue.contains(admin.current_body)
	admin.current_body.mock_client = null
	TEST_ASSERT(admin_entered, "Админ стенда входит в сектор чужой партии: [admin.last_feedback].")
	TEST_ASSERT(admin_stayed, "Админа стенда с места партии не выводят.")

	var/mob/living/leader_body = leader.current_body
	var/obj/structure/antag_training_exit/exit_pad = training_sector_find(sector, /obj/structure/antag_training_exit)
	TEST_ASSERT_NOTNULL(exit_pad, "В секторе есть платформа возврата.")
	leader_body.forceMove(get_turf(exit_pad))
	leader.last_feedback = null
	exit_pad.attack_hand(leader_body)
	TEST_ASSERT(scenario.venue.contains(leader_body), "Участник партии не уходит с места партии платформой возврата.")
	TEST_ASSERT(findtext(leader.last_feedback, "платформ"), "Отказ платформы объясняет почему: [leader.last_feedback].")
	leader_body.forceMove(arena.hub_arrival())
	told = training_gate_step(leader_body, gate)
	TEST_ASSERT(!scenario.venue.contains(leader_body), "Участник партии не возвращается вратами на точку появления.")
	TEST_ASSERT(length(told) && findtext(told[1], "платформ"), "Врата объясняют участнику партии отказ: [json_encode(told)].")

/// Пока идёт партия, зритель группы не ставит цели в её сектор; со стендом ставит.
/datum/unit_test/antag_training_scenario_watcher_targets/Run()
	var/datum/antag_training_scenario/scenario = training_scenario_watched()
	TEST_ASSERT_NOTNULL(scenario, "Партия в тёмном секторе идёт.")
	var/datum/antag_training_session/watcher = training_scenario_watcher(scenario)
	var/datum/antag_training_arena/arena = watcher.arena
	var/targets = length(arena.targets)
	training_squad_act(watcher, "spawn", list("id" = "carp", "zone" = "dark"))
	TEST_ASSERT_EQUAL(length(arena.targets), targets, "Зритель группы не ставит цели в сектор идущей партии.")
	TEST_ASSERT(findtext(watcher.last_feedback, "Идёт сценарий"), "Отказ называет партию: [watcher.last_feedback].")
	var/datum/tgui/stand_ui = allocate_stand_ui(watcher)
	grant_stand_rights(watcher, mentor = TRUE)
	antag_training_console_act(watcher, stand_ui, "stand_toggle", list())
	training_squad_act(watcher, "spawn", list("id" = "carp", "zone" = "dark"))
	watcher.current_body.mock_client = null
	TEST_ASSERT_EQUAL(length(arena.targets), targets + 1, "Стенд ставит цели и во время партии.")
