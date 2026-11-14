/datum/unit_test/proc/antag_training_ninja_action(obj/item/item, action_type)
	for(var/datum/action/action as anything in item.actions)
		if(istype(action, action_type))
			return action
	return null

/datum/unit_test/proc/antag_training_ninja_find(datum/antag_training_sector/sector, machine_type)
	for(var/turf/tile as anything in sector.turfs)
		var/obj/machinery/machine = locate(machine_type) in tile
		if(machine)
			return machine
	return null

/datum/unit_test/proc/antag_training_ninja_in_mockup(datum/antag_training_session/session)
	var/datum/antag_training_sector/station = session.arena.sectors["station"]
	TEST_ASSERT(wait_for_var(station, "state", ANTAG_TRAINING_SECTOR_READY, 30 SECONDS), "Станционный макет загружается.")
	var/area/mockup = get_area(station.landmark_turf("vault"))
	var/list/budget = new_wait_budget(10 SECONDS, "участник в станционном макете")
	while(get_area(session.current_body) != mockup)
		if(!wait_budget_tick(budget))
			break
	TEST_ASSERT_EQUAL(get_area(session.current_body), mockup, "Программа ставит участника в станционный макет.")
	return station

/datum/unit_test/proc/antag_training_ninja_stand_by(mob/living/body, atom/target)
	for(var/direction in GLOB.cardinals)
		var/turf/spot = get_step(target, direction)
		if(spot && !spot.is_blocked_turf(TRUE))
			body.forceMove(spot)
			return TRUE
	return FALSE

/datum/unit_test/proc/antag_training_ninja_touch(mob/living/carbon/human/body, obj/item/clothing/gloves/space_ninja/gloves, atom/target, max_wait)
	TEST_ASSERT(antag_training_ninja_stand_by(body, target), "Рядом с [target] есть свободная клетка.")
	INVOKE_ASYNC(body, TYPE_PROC_REF(/mob/living/carbon/human, UnarmedAttack), target, TRUE)
	TEST_ASSERT(gloves.draining, "Касание перчатками начинает дрейн [target].")
	TEST_ASSERT(wait_for_var(gloves, "draining", FALSE, max_wait), "Дрейн [target] завершается.")

/// Путь выбирается в пульте до выдачи роли и перевыдаёт снаряжение пути: без вопросов игроку, без микробомбы, с паучьим зарядом полигона.
/datum/unit_test/antag_training_ninja_paths/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/ninja)
	TEST_ASSERT(session.prepare(), "Полигон готовит ниндзя.")
	var/datum/antag_training_program/antag/ninja/program = session.program
	var/mob/living/carbon/human/body = session.current_body
	var/datum/antagonist/ninja/training/role = program.role(session)
	TEST_ASSERT(istype(role), "Кукла получает учебного ниндзя.")
	TEST_ASSERT_EQUAL(role.training, session, "Роль знает свою сессию.")
	TEST_ASSERT(!length(role.objectives), "У учебного ниндзя нет заданий раунда.")
	TEST_ASSERT_EQUAL(body.wear_suit?.type, /obj/item/clothing/suit/space/space_ninja, "Классический путь даёт костюм Клана Паука.")
	TEST_ASSERT(istype(body.belt, /obj/item/energy_katana), "Классический путь даёт энергокатану.")
	TEST_ASSERT_NULL(locate(/obj/item/implant/explosive) in body.implants, "Микробомбы на полигоне нет.")
	TEST_ASSERT(istype(body.l_store, /obj/item/grenade/plastic/c4/ninja/training), "Паучий заряд в кармане - учебный.")
	TEST_ASSERT(findtext(role.briefing(), "Моя роль"), "Приветствие называет кнопки пульта.")

	var/list/data = session.ui_data(body)
	for(var/option in program.options)
		TEST_ASSERT(length(data["option_hints"][option]), "У кнопки «[option]» есть подсказка.")

	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")
	antag_training_console_act(session, console, "program_option", list("option" = program.choice_option("ronin")))
	var/datum/antagonist/ninja/training/ronin = program.role(session)
	TEST_ASSERT(ronin && ronin != role, "Смена пути перевыдаёт роль.")
	TEST_ASSERT(istype(body.wear_suit, /obj/item/clothing/suit/space/space_ninja/ronin), "Путь «Ронин» даёт костюм ронина.")
	TEST_ASSERT(istype(body.belt, /obj/item/energy_naginata), "Путь «Ронин» даёт энергонагинату.")
	TEST_ASSERT_NULL(locate(/obj/item/energy_katana) in body.GetAllContents(), "Катана прежнего пути убрана.")

	antag_training_console_act(session, console, "program_option", list("option" = program.choice_option("wisdom")))
	TEST_ASSERT(istype(body.wear_suit, /obj/item/clothing/suit/space/space_ninja/wisdom), "Путь «Мудрость» даёт костюм мудрости.")
	TEST_ASSERT(istype(body.mind.martial_art, /datum/martial_art/the_sleeping_carp), "Путь «Мудрость» учит спящему карпу.")
	antag_training_console_act(session, console, "program_option", list("option" = program.choice_option("classic")))
	TEST_ASSERT_EQUAL(body.wear_suit?.type, /obj/item/clothing/suit/space/space_ninja, "Возврат к классическому пути возвращает его костюм.")
	TEST_ASSERT(!istype(body.mind.martial_art, /datum/martial_art/the_sleeping_carp), "Смена пути снимает спящего карпа.")
	TEST_ASSERT_NULL(locate(/obj/item/implant/explosive) in body.implants, "Перевыдача не вживляет микробомбу.")

/// Костюм запирается на учебном ниндзя без гибели, перчатки тянут заряд из щитка макета, учебные консоли взламываются без действия на станцию, «Полный заряд» заполняет батарею.
/datum/unit_test/antag_training_ninja_drain
	var/datum/data/record/general_record
	var/datum/data/record/security_record
	var/list/added_players = list()

/datum/unit_test/antag_training_ninja_drain/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/ninja)
	var/datum/antag_training_program/antag/ninja/program = session.program
	program.choice = "ronin"
	TEST_ASSERT(session.prepare(), "Полигон готовит ниндзя.")
	var/mob/living/carbon/human/body = session.current_body
	var/obj/item/clothing/suit/space/space_ninja/ronin/suit = body.wear_suit
	TEST_ASSERT(istype(suit), "Выбранный до входа путь «Ронин» выдан сразу.")
	var/obj/item/clothing/gloves/space_ninja/gloves = body.gloves
	TEST_ASSERT(istype(gloves), "Перчатки ниндзя надеты.")
	var/datum/antag_training_sector/station = antag_training_ninja_in_mockup(session)

	var/datum/action/item_action/initialize_ninja_suit/boot = antag_training_ninja_action(suit, /datum/action/item_action/initialize_ninja_suit)
	boot.Trigger()
	TEST_ASSERT(wait_for_var(suit, "affecting", body, 15 SECONDS), "Костюм запирается на носителе.")
	TEST_ASSERT(!QDELETED(body) && body.stat != DEAD, "Костюм не убивает учебного ниндзя.")
	TEST_ASSERT(HAS_TRAIT_FROM(suit, TRAIT_NODROP, NINJA_SUIT_TRAIT), "Запертый костюм не снимается.")
	var/datum/action/item_action/toggle_glove/drain_mode = antag_training_ninja_action(gloves, /datum/action/item_action/toggle_glove)
	drain_mode.Trigger()
	TEST_ASSERT(gloves.candrain, "Кнопка перчаток включает дрейн.")

	var/obj/machinery/power/apc/apc = antag_training_ninja_find(station, /obj/machinery/power/apc)
	TEST_ASSERT(apc?.cell, "В щитовой макета есть щиток с батареей.")
	apc.cell.charge = apc.cell.maxcharge
	suit.cell.charge = suit.cell.maxcharge - 1500
	var/apc_before = apc.cell.charge
	antag_training_ninja_touch(body, gloves, apc, 30 SECONDS)
	TEST_ASSERT(suit.cell.charge > suit.cell.maxcharge - 50, "Дрейн щитка доводит батарею костюма до предела: [suit.cell.charge] из [suit.cell.maxcharge].")
	TEST_ASSERT(apc.cell.charge < apc_before - 1000, "Заряд взят из батареи щитка: было [apc_before], стало [apc.cell.charge].")

	general_record = new
	general_record.fields["name"] = "Ninja Drain Probe"
	general_record.fields["id"] = "ninja-probe"
	security_record = new
	security_record.fields["name"] = "Ninja Drain Probe"
	security_record.fields["id"] = "ninja-probe"
	security_record.fields["criminal"] = SEC_RECORD_STATUS_NONE
	GLOB.data_core.general += general_record
	GLOB.data_core.security += security_record
	added_players = list(body) - GLOB.player_list
	GLOB.player_list += added_players
	GLOB.unit_test_chat_capture = list()
	var/news_before = GLOB.news_network.lastAction

	var/obj/machinery/computer/antag_training_mockup/records = antag_training_ninja_find(station, /obj/machinery/computer/antag_training_mockup/records)
	var/obj/machinery/computer/antag_training_mockup/comms = antag_training_ninja_find(station, /obj/machinery/computer/antag_training_mockup/comms)
	TEST_ASSERT(records && comms, "В макете стоят учебные консоли записей и связи.")
	antag_training_ninja_touch(body, gloves, records, 30 SECONDS)
	TEST_ASSERT_EQUAL(security_record.fields["criminal"], SEC_RECORD_STATUS_NONE, "Учебный взлом записей не трогает записи охраны станции.")
	antag_training_ninja_touch(body, gloves, comms, 30 SECONDS)
	TEST_ASSERT_EQUAL(GLOB.news_network.lastAction, news_before, "Учебный взлом связи не публикует объявлений.")
	TEST_ASSERT(antag_training_heard(body, "Учебный взлом выполнен"), "Взлом сообщает, что он учебный.")
	TEST_ASSERT(!antag_training_heard(body, "Макет консоли"), "Взлом перчатками не показывает отказ макета.")
	TEST_ASSERT(!antag_training_heard(body, "Зарегистрирован сигнал коммуникаций"), "Учебный взлом связи не объявляет угрозу.")

	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")
	suit.cell.charge = 100
	suit.a_boost = FALSE
	antag_training_console_act(session, console, "program_option", list("option" = "Полный заряд"))
	TEST_ASSERT_EQUAL(round(suit.cell.charge, 1), suit.cell.maxcharge, "«Полный заряд» доводит батарею костюма до максимума.")
	TEST_ASSERT(suit.a_boost, "«Полный заряд» возвращает адреналин.")

/datum/unit_test/antag_training_ninja_drain/Destroy()
	GLOB.unit_test_chat_capture = null
	GLOB.player_list -= added_players
	added_players.Cut()
	if(general_record)
		GLOB.data_core.general -= general_record
		QDEL_NULL(general_record)
	if(security_record)
		GLOB.data_core.security -= security_record
		QDEL_NULL(security_record)
	return ..()

/// Паучий заряд полигона срабатывает только по учебному заданию подрыва и засчитывает его взрывом в станционном макете.
/datum/unit_test/antag_training_ninja_bombing/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/ninja)
	TEST_ASSERT(session.prepare(), "Полигон готовит ниндзя.")
	var/datum/antag_training_program/antag/ninja/program = session.program
	var/mob/living/carbon/human/body = session.current_body
	var/datum/antagonist/ninja/training/role = program.role(session)
	var/datum/antag_training_sector/station = antag_training_ninja_in_mockup(session)
	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")
	body.drop_all_held_items()
	antag_training_console_act(session, console, "program_option", list("option" = "Новый паучий заряд"))
	var/obj/item/grenade/plastic/c4/ninja/training/charge = locate() in body.held_items
	TEST_ASSERT(charge, "Кнопка выдаёт паучий заряд в руки.")

	var/obj/structure/showcase/machinery/training_server/rack = locate() in range(2, station.landmark_turf("server"))
	TEST_ASSERT(rack, "В серверной макета есть стойка.")
	TEST_ASSERT(antag_training_ninja_stand_by(body, rack), "К стойке можно подойти.")
	charge.melee_attack_chain(body, rack)
	TEST_ASSERT(charge in body.held_items, "Без задания подрыва заряд не устанавливается.")

	antag_training_console_act(session, console, "program_option", list("option" = "Учебная цель: подрыв"))
	var/datum/objective/plant_explosive/antag_training/bombing = role.bomb_objective
	TEST_ASSERT(bombing && (bombing in role.objectives), "Кнопка назначает учебный подрыв.")
	TEST_ASSERT_EQUAL(bombing.detonation_location, get_area(rack), "Место подрыва - станционный макет.")
	charge.melee_attack_chain(body, rack)
	TEST_ASSERT(charge.target == rack, "Заряд установлен на стойку.")
	body.forceMove(session.arena.entry_turf)
	TEST_ASSERT(wait_for_qdeleted(charge, 30 SECONDS), "Заряд взрывается по таймеру.")
	TEST_ASSERT(bombing.completed, "Взрыв в макете засчитывает учебный подрыв.")
	TEST_ASSERT_EQUAL(SSmetadollars.potential_antag_metadollars(role.owner), 0, "Учебное задание не даёт метадолларов.")

/// ЭМИ ниндзя у макета записей не трогает записи охраны станции, а макеты не числятся консолями раунда и не вызывают шаттл при удалении.
/datum/unit_test/antag_training_ninja_mockups
	var/list/probe_records = list()

/datum/unit_test/antag_training_ninja_mockups/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/ninja)
	TEST_ASSERT(session.prepare(), "Полигон готовит ниндзя.")
	var/mob/living/carbon/human/body = session.current_body
	var/obj/item/clothing/suit/space/space_ninja/suit = body.wear_suit
	var/datum/antag_training_sector/station = antag_training_ninja_in_mockup(session)
	var/obj/machinery/computer/records = antag_training_ninja_find(station, /obj/machinery/computer/antag_training_mockup/records)
	var/obj/machinery/computer/comms = antag_training_ninja_find(station, /obj/machinery/computer/antag_training_mockup/comms)
	TEST_ASSERT(records && comms, "В макете стоят учебные консоли записей и связи.")
	TEST_ASSERT(!(records in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/computer/secure_data)), "Макет записей не числится консолью записей раунда.")
	TEST_ASSERT(!(comms in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/computer/communications)), "Макет связи не числится консолью связи раунда.")

	for(var/index in 1 to 60)
		var/datum/data/record/probe = new
		probe.fields["name"] = "Ninja EMP Probe [index]"
		probe.fields["id"] = "ninja-emp-[index]"
		probe.fields["criminal"] = SEC_RECORD_STATUS_NONE
		probe.fields["age"] = 30
		probe_records += probe
	GLOB.data_core.security += probe_records
	var/datum/action/item_action/initialize_ninja_suit/boot = antag_training_ninja_action(suit, /datum/action/item_action/initialize_ninja_suit)
	boot.Trigger()
	TEST_ASSERT(wait_for_var(suit, "s_initialized", TRUE, 40 SECONDS), "Костюм включается.")
	TEST_ASSERT(antag_training_ninja_stand_by(body, records), "К макету записей можно подойти.")
	var/datum/action/item_action/ninjapulse/pulse = antag_training_ninja_action(suit, /datum/action/item_action/ninjapulse)
	var/charge_before = suit.cell.charge
	pulse.Trigger()
	TEST_ASSERT(suit.cell.charge < charge_before, "ЭМИ-импульс сработал рядом с макетом записей.")
	for(var/datum/data/record/probe as anything in probe_records)
		TEST_ASSERT(!QDELETED(probe) && (probe in GLOB.data_core.security), "Запись [probe.fields["id"]] на месте после ЭМИ.")
		TEST_ASSERT(findtext(probe.fields["name"], "Ninja EMP Probe") == 1 && probe.fields["criminal"] == SEC_RECORD_STATUS_NONE && probe.fields["age"] == 30, "ЭМИ у макета не меняет запись [probe.fields["id"]].")

	var/shuttle_mode = SSshuttle.emergency?.mode
	qdel(comms)
	TEST_ASSERT_EQUAL(SSshuttle.emergency?.mode, shuttle_mode, "Удаление макета связи не вызывает шаттл.")

/datum/unit_test/antag_training_ninja_mockups/Destroy()
	GLOB.data_core.security -= probe_records
	QDEL_LIST(probe_records)
	return ..()
