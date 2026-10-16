/// Резервный z не станционный: цели подставляются списком, а director их не регистрирует (typepath = null).
/datum/round_event_control/station_incident/radiation_leak/test_targets
	typepath = null
	var/list/test_targets = list()

/datum/round_event_control/station_incident/radiation_leak/test_targets/valid_location(atom/target)
	return TRUE

/datum/round_event_control/station_incident/radiation_leak/test_targets/get_candidates(first_only = FALSE)
	var/list/result = list()
	for(var/atom/target as anything in test_targets)
		if(valid_target(target))
			result += target
	return result

/datum/round_event_control/station_incident/gravity_failure/test_targets
	typepath = null
	var/list/test_targets = list()

/datum/round_event_control/station_incident/gravity_failure/test_targets/valid_location(atom/target)
	return TRUE

/datum/round_event_control/station_incident/gravity_failure/test_targets/get_candidates(first_only = FALSE)
	var/list/result = list()
	for(var/atom/target as anything in test_targets)
		if(valid_target(target))
			result += target
	return result

/datum/round_event_control/station_incident/bot_glitch/test_targets
	typepath = null
	var/list/test_targets = list()

/datum/round_event_control/station_incident/bot_glitch/test_targets/valid_location(atom/target)
	return TRUE

/datum/round_event_control/station_incident/bot_glitch/test_targets/get_candidates(first_only = FALSE)
	var/list/result = list()
	for(var/atom/target as anything in test_targets)
		if(valid_target(target))
			result += target
	return result

/// Киборги тестов без игроков: здесь клиент не обязателен.
/datum/round_event_control/silicon_firmware_patch/test_targets
	typepath = null

/datum/round_event_control/silicon_firmware_patch/test_targets/is_recipient(mob/living/silicon/silicon, require_client = TRUE)
	return ..(silicon, FALSE)

/datum/round_event_control/silicon_firmware_patch/no_recipients
	typepath = null

/datum/round_event_control/silicon_firmware_patch/no_recipients/get_recipients(require_client = TRUE)
	return list()

/// Компенсатор на клетках вокруг себя: весь резервный z - одна зона, и на неё целиком он не нужен.
/obj/structure/gravity_compensator/test_block

/obj/structure/gravity_compensator/test_block/collect_turfs()
	var/list/result = list()
	for(var/turf/open/floor/floor in RANGE_TURFS(1, src))
		result += floor
	return result

/datum/unit_test/minor_incidents_engineering

/datum/unit_test/minor_incidents_engineering/Run()
	check_radiation_leak()
	check_radiation_dose()
	check_radiation_leak_cleanup()
	var/area/test_area = get_area(run_loc_floor_bottom_left)
	var/old_gravity = test_area.has_gravity
	test_area.has_gravity = STANDARD_GRAVITY
	check_gravity_failure()
	test_area.has_gravity = old_gravity
	check_bot_glitch()
	check_bot_glitch_choices()
	check_firmware_patch()
	check_firmware_flash()
	check_ai_patch()

/datum/unit_test/minor_incidents_engineering/proc/make_event(event_path)
	var/datum/round_event/event = allocate(event_path, FALSE)
	SSdirector.running -= event
	return event

/datum/unit_test/minor_incidents_engineering/proc/examine_text(atom/target, mob/user)
	return jointext(target.examine(user), " ")

/datum/unit_test/minor_incidents_engineering/proc/tool_for(step)
	switch(step)
		if(TOOL_WRENCH)
			return allocate(/obj/item/wrench)
		if(TOOL_WELDER)
			return allocate(/obj/item/weldingtool)
		if(TOOL_SCREWDRIVER)
			return allocate(/obj/item/screwdriver)
		if(TOOL_MULTITOOL)
			return allocate(/obj/item/multitool)
	return allocate(/obj/item/stack/cable_coil)

/// Инструмент шага ремонта так, как его применяет игрок: сигналом инструмента или кабеля.
/datum/unit_test/minor_incidents_engineering/proc/apply_tool(obj/machinery/machine, mob/living/user, obj/item/tool)
	if(tool.tool_behaviour)
		return SEND_SIGNAL(machine, COMSIG_ATOM_TOOL_ACT(tool.tool_behaviour), user, tool, list())
	return SEND_SIGNAL(machine, COMSIG_ATOM_ITEM_INTERACTION, user, tool, null)

/datum/unit_test/minor_incidents_engineering/proc/make_roboticist(turf/spot)
	var/mob/living/carbon/human/roboticist = allocate(/mob/living/carbon/human, spot)
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	card.access = list(ACCESS_ROBOTICS)
	roboticist.equip_to_slot(card, ITEM_SLOT_ID)
	return roboticist

/datum/unit_test/minor_incidents_engineering/proc/check_radiation_leak()
	var/datum/round_event_control/station_incident/radiation_leak/test_targets/controller = allocate(/datum/round_event_control/station_incident/radiation_leak/test_targets)
	TEST_ASSERT(!controller.director_preflight(), "Без машин утечка не должна тратить бюджет директора")
	TEST_ASSERT_NOTNULL(controller.director_preflight_failure, "Провал preflight утечки объясняется директору")
	var/obj/machinery/autolathe/lathe = allocate(/obj/machinery/autolathe, run_loc_floor_bottom_left)
	lathe.machine_stat = NONE
	var/obj/machinery/recharge_station/charger = allocate(/obj/machinery/recharge_station, run_loc_floor_top_right)
	charger.machine_stat = NONE
	TEST_ASSERT(controller.valid_target(lathe), "Рабочий автолат подходит для утечки")
	TEST_ASSERT(!controller.valid_target(charger), "Зарядная станция не входит в список фонящих машин")
	lathe.machine_stat |= BROKEN
	TEST_ASSERT(!controller.valid_target(lathe), "Сломанная машина не фонит")
	lathe.machine_stat = NONE
	controller.test_targets = list(lathe, charger)
	TEST_ASSERT(controller.director_preflight(), "С рабочей машиной preflight должен проходить")
	TEST_ASSERT_NULL(controller.director_preflight_failure, "Успешный preflight не держит старую причину провала")

	var/datum/round_event/station_incident/radiation_leak/event = make_event(/datum/round_event/station_incident/radiation_leak)
	event.control = controller
	event.start()
	TEST_ASSERT_EQUAL(event.affected_count, 1, "Утечка затрагивает ровно одну машину")
	var/datum/component/radiation_leak/leak = lathe.GetComponent(/datum/component/radiation_leak)
	TEST_ASSERT_NOTNULL(leak, "Утечка должна появиться на выбранной машине")
	TEST_ASSERT(!controller.valid_target(lathe), "Вторая утечка на той же машине не нужна")
	TEST_ASSERT_NOTNULL(lathe.get_filter("radiation_leak_glow"), "Машина должна мерцать зелёным")
	var/obj/effect/minor_incident_overlay/glow = leak.glow
	TEST_ASSERT(glow in lathe.vis_contents, "Частицы привязаны к самой машине")
	TEST_ASSERT_NOTNULL(glow.particles, "У утечки должны быть клиентские частицы")
	TEST_ASSERT_EQUAL(length(leak.repair_steps), 2, "Ремонт состоит из двух шагов")
	TEST_ASSERT_NOTEQUAL(leak.repair_steps[1], leak.repair_steps[2], "Шаги ремонта должны требовать разные инструменты")

	var/mob/living/carbon/human/engineer = allocate(/mob/living/carbon/human, get_step(lathe, EAST))
	var/text = examine_text(lathe, engineer)
	for(var/step in leak.repair_steps)
		TEST_ASSERT(findtext(text, leak.step_instruction(step)), "При осмотре должен быть виден шаг ремонта: [step]")

	var/first_step = leak.repair_steps[1]
	var/second_step = leak.repair_steps[2]
	TEST_ASSERT_EQUAL(apply_tool(lathe, engineer, tool_for(second_step)), NONE, "Неподходящий инструмент работает с машиной как обычно")
	leak.busy = TRUE
	TEST_ASSERT_EQUAL(apply_tool(lathe, engineer, tool_for(first_step)), TOOL_ACT_MELEE_CHAIN_BLOCKING, "Подходящий инструмент берётся за ремонт, а не за машину")
	leak.busy = FALSE
	TEST_ASSERT(!leak.complete_step(engineer, second_step), "Шаги ремонта идут по порядку")
	TEST_ASSERT(leak.complete_step(engineer, first_step), "Первый шаг должен засчитываться")
	TEST_ASSERT(!QDELETED(leak), "После одного шага утечка продолжается")
	TEST_ASSERT(leak.complete_step(engineer, second_step), "Второй шаг должен засчитываться")
	TEST_ASSERT(QDELETED(leak), "Ремонт должен устранять утечку")
	TEST_ASSERT_NULL(lathe.GetComponent(/datum/component/radiation_leak), "На машине не должно остаться утечки")
	TEST_ASSERT_NULL(lathe.get_filter("radiation_leak_glow"), "После ремонта мерцание гаснет")
	TEST_ASSERT(QDELETED(glow) && !(glow in lathe.vis_contents), "После ремонта частицы убираются")

/// Тридцать импульсов (десять минут утечки) не доводят соседа до вредной дозы, а дальних не задевают.
/datum/unit_test/minor_incidents_engineering/proc/check_radiation_dose()
	var/obj/machinery/autolathe/lathe = allocate(/obj/machinery/autolathe, run_loc_floor_bottom_left)
	var/datum/component/radiation_leak/leak = lathe.AddComponent(/datum/component/radiation_leak)
	var/mob/living/carbon/human/chemist = allocate(/mob/living/carbon/human, get_step(lathe, NORTH))
	var/mob/living/carbon/human/passerby = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	for(var/pulse_number in 1 to 30)
		leak.pulse()
	TEST_ASSERT(chemist.radiation > 0, "Стоящий рядом человек получает дозу")
	TEST_ASSERT(chemist.radiation < RAD_MOB_SAFE, "Десять минут у фонящей машины не доводят до вредной дозы ([chemist.radiation])")
	TEST_ASSERT_EQUAL(passerby.radiation, 0, "Утечка не достаёт дальше двух клеток")
	TEST_ASSERT_NULL(chemist.GetComponent(/datum/component/radioactive), "Человек не должен становиться радиоактивным")

/datum/unit_test/minor_incidents_engineering/proc/check_radiation_leak_cleanup()
	var/obj/machinery/autolathe/expiring = allocate(/obj/machinery/autolathe, run_loc_floor_bottom_left)
	var/datum/component/radiation_leak/leak = expiring.AddComponent(/datum/component/radiation_leak)
	leak.expire()
	TEST_ASSERT(QDELETED(leak), "Через срок утечка затихает сама")
	TEST_ASSERT_NULL(expiring.get_filter("radiation_leak_glow"), "Истёкшая утечка не оставляет мерцания")
	var/obj/machinery/autolathe/scrapped = allocate(/obj/machinery/autolathe, run_loc_floor_top_right)
	leak = scrapped.AddComponent(/datum/component/radiation_leak)
	var/obj/effect/minor_incident_overlay/glow = leak.glow
	qdel(scrapped)
	TEST_ASSERT(QDELETED(leak) && QDELETED(glow), "Разобранная машина уносит утечку с собой")

	var/obj/machinery/autolathe/dragged = allocate(/obj/machinery/autolathe, run_loc_floor_bottom_left)
	leak = dragged.AddComponent(/datum/component/radiation_leak)
	dragged.forceMove(run_loc_floor_top_right)
	TEST_ASSERT(QDELETED(leak), "Утечка не едет вместе с машиной к чужому рабочему месту")
	var/obj/machinery/autolathe/unbolted = allocate(/obj/machinery/autolathe, run_loc_floor_bottom_left)
	leak = unbolted.AddComponent(/datum/component/radiation_leak)
	unbolted.set_anchored(FALSE)
	leak.pulse()
	TEST_ASSERT(QDELETED(leak), "Откреплённая машина перестаёт фонить")

/datum/unit_test/minor_incidents_engineering/proc/check_gravity_failure()
	var/turf/open/floor/center = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	var/turf/open/floor/outside = run_loc_floor_bottom_left
	TEST_ASSERT(center.has_gravity(), "Перед сбоем на клетке должна быть гравитация")
	var/datum/round_event_control/station_incident/gravity_failure/test_targets/controller = allocate(/datum/round_event_control/station_incident/gravity_failure/test_targets)
	TEST_ASSERT(!controller.director_preflight(), "Без подходящего отсека сбой не запускается")
	controller.test_targets = list(center)
	TEST_ASSERT(controller.director_preflight(), "Свободный пол с гравитацией подходит для сбоя")

	var/mob/living/carbon/human/floater = allocate(/mob/living/carbon/human, get_step(center, NORTH))
	floater.refresh_gravity()
	var/obj/structure/gravity_compensator/test_block/compensator = allocate(/obj/structure/gravity_compensator/test_block, center)
	TEST_ASSERT(compensator.failing, "Компенсатор должен запускать сбой")
	TEST_ASSERT(compensator.restore_at - world.time >= 4 MINUTES, "Без инженера сбой длится не меньше четырёх минут")
	TEST_ASSERT(!controller.valid_target(center), "Второй компенсатор на той же клетке не нужен")
	TEST_ASSERT(!center.has_gravity(), "Сбой начинается с провала поля")
	TEST_ASSERT(outside.has_gravity(), "Невесомость не выходит за пределы отсека")
	TEST_ASSERT(!floater.cached_gravity_value, "Стоящий человек сразу оказывается в невесомости")
	TEST_ASSERT(compensator.hold_field(), "После провала поле на время возвращается")
	TEST_ASSERT(center.has_gravity(), "Между провалами гравитация есть")
	TEST_ASSERT(floater.cached_gravity_value, "Между провалами человек стоит на полу")
	TEST_ASSERT(compensator.drop_field(), "Поле снова проваливается")
	TEST_ASSERT(!center.has_gravity(), "Во время провала гравитации нет")
	TEST_ASSERT(findtext(examine_text(compensator, floater), "мультитулом"), "При осмотре видно, чем перезапустить блок")

	var/mob/living/carbon/human/engineer = allocate(/mob/living/carbon/human, outside)
	TEST_ASSERT(compensator.restore_field(engineer), "Перезапуск должен возвращать поле")
	TEST_ASSERT(center.has_gravity(), "После перезапуска гравитация возвращается")
	TEST_ASSERT(floater.cached_gravity_value, "Стоящий человек сразу встаёт на пол")
	TEST_ASSERT(!compensator.restore_field(engineer), "Повторный перезапуск ничего не делает")
	TEST_ASSERT(!compensator.drop_field(), "Перезапущенный блок больше не проваливает поле")
	compensator.retract()
	TEST_ASSERT(QDELETED(compensator), "После перезапуска блок уходит под палубу")

	var/obj/structure/gravity_compensator/test_block/expiring = allocate(/obj/structure/gravity_compensator/test_block, center)
	TEST_ASSERT(!center.has_gravity(), "Новый сбой снова отключает гравитацию")
	TEST_ASSERT(expiring.restore_field(), "Поле возвращается по истечении срока без инженера")
	TEST_ASSERT(center.has_gravity(), "Истёкший сбой возвращает гравитацию")
	qdel(expiring)

	var/obj/structure/gravity_compensator/test_block/deleted = allocate(/obj/structure/gravity_compensator/test_block, center)
	TEST_ASSERT(!center.has_gravity(), "Третий сбой снова отключает гравитацию")
	qdel(deleted)
	TEST_ASSERT(center.has_gravity(), "Удаление блока гарантированно возвращает гравитацию")
	TEST_ASSERT(floater.cached_gravity_value, "Удаление блока сразу ставит людей на пол")

/datum/unit_test/minor_incidents_engineering/proc/check_bot_glitch()
	var/datum/round_event_control/station_incident/bot_glitch/test_targets/controller = allocate(/datum/round_event_control/station_incident/bot_glitch/test_targets)
	TEST_ASSERT(!controller.director_preflight(), "Без ботов сбой не запускается")
	var/mob/living/simple_animal/bot/cleanbot/cleaner = allocate(/mob/living/simple_animal/bot/cleanbot, run_loc_floor_bottom_left)
	var/mob/living/simple_animal/bot/secbot/guard = allocate(/mob/living/simple_animal/bot/secbot, run_loc_floor_top_right)
	TEST_ASSERT(controller.valid_target(cleaner), "Уборщик подходит для сбоя прошивки")
	TEST_ASSERT(!controller.valid_target(guard), "Охранных ботов сбой не трогает")
	cleaner.on = FALSE
	TEST_ASSERT(!controller.valid_target(cleaner), "Выключенный бот не глючит")
	cleaner.on = TRUE
	controller.test_targets = list(cleaner, guard)
	TEST_ASSERT(controller.director_preflight(), "С рабочим ботом preflight проходит")

	var/original_ai = cleaner.AIStatus
	var/datum/round_event/station_incident/bot_glitch/event = make_event(/datum/round_event/station_incident/bot_glitch)
	event.control = controller
	event.start()
	var/datum/component/bot_firmware_glitch/glitch = cleaner.GetComponent(/datum/component/bot_firmware_glitch)
	TEST_ASSERT_NOTNULL(glitch, "Сбой должен поселиться в выбранном боте")
	TEST_ASSERT_NULL(guard.GetComponent(/datum/component/bot_firmware_glitch), "Охранный бот остаётся нетронутым")
	var/obj/effect/minor_incident_overlay/bot_glitch/static_overlay = glitch.static_overlay
	TEST_ASSERT(static_overlay in cleaner.vis_contents, "Помехи видны на самом боте")
	TEST_ASSERT_NOTNULL(cleaner.get_filter("bot_glitch_cyan"), "Силуэт бота двоится цветными тенями")
	var/mob/living/carbon/human/roboticist = make_roboticist(run_loc_floor_top_right)
	TEST_ASSERT(findtext(examine_text(cleaner, roboticist), "мультитулом"), "При осмотре видна подсказка для робототехников")

	var/turf/spot = get_turf(cleaner)
	glitch.glitch_speak()
	TEST_ASSERT(glitch.place_sign(), "Уборщик должен уметь поставить табличку")
	TEST_ASSERT_NOTNULL(locate(/obj/item/clothing/suit/caution) in spot, "Табличка должна стоять под ботом")
	TEST_ASSERT(glitch.leave_note(), "Бот должен уметь оставить записку")
	var/obj/item/paper/note = locate() in spot
	TEST_ASSERT(note && findtext(note.get_raw_text(), "робототехникам"), "Записка должна быть читаемой")
	TEST_ASSERT(!glitch.place_sign() && !glitch.leave_note(), "Сбой не должен заваливать станцию мусором")

	TEST_ASSERT(glitch.start_follow(roboticist), "Бот должен уметь ходить хвостом")
	TEST_ASSERT_EQUAL(cleaner.AIStatus, AI_OFF, "Пока бот идёт хвостом, его собственный AI на паузе")
	qdel(glitch.follow_loop)
	TEST_ASSERT_NULL(glitch.follow_loop, "Окончание хвоста должно забываться")
	TEST_ASSERT_EQUAL(cleaner.AIStatus, original_ai, "После хвоста бот возвращается к работе")

	TEST_ASSERT(glitch.start_follow(roboticist), "Хвост можно начать снова")
	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	var/obj/item/multitool/multitool = allocate(/obj/item/multitool)
	TEST_ASSERT_EQUAL(glitch.on_multitool(cleaner, stranger, multitool), TOOL_ACT_MELEE_CHAIN_BLOCKING, "Мультитул постороннего не превращается в удар по боту")
	TEST_ASSERT(!glitch.repairing, "Без доступа в робототехнику перепрошивка не начинается")
	TEST_ASSERT(!glitch.finish_repair(stranger, "Дамп прошивки"), "Посторонний не может выгрузить дамп прошивки")
	TEST_ASSERT(!QDELETED(glitch) && !(locate(/obj/item/disk/bot_firmware_dump) in stranger.held_items), "Без доступа сбой остаётся, а диск не выдаётся")
	glitch.finish_repair(roboticist)
	TEST_ASSERT(QDELETED(glitch), "Перепрошивка снимает сбой")
	TEST_ASSERT_NULL(cleaner.GetComponent(/datum/component/bot_firmware_glitch), "На боте не остаётся сбоя")
	TEST_ASSERT_NULL(cleaner.GetComponent(/datum/component/bot_personality), "Простой откат не оставляет личности")
	TEST_ASSERT(QDELETED(static_overlay) && !(static_overlay in cleaner.vis_contents), "Помехи снимаются при починке")
	TEST_ASSERT_NULL(cleaner.get_filter("bot_glitch_cyan"), "Цветные тени снимаются при починке")
	TEST_ASSERT_EQUAL(cleaner.AIStatus, original_ai, "Починка посреди хвоста возвращает боту AI")
	TEST_ASSERT(cleaner.on && cleaner.health == cleaner.maxHealth, "Бот после сбоя целый и включённый")

	var/datum/component/bot_firmware_glitch/expiring = cleaner.AddComponent(/datum/component/bot_firmware_glitch)
	expiring.expire()
	TEST_ASSERT(QDELETED(expiring), "Через срок сбой проходит сам")

/// Выбор робототехника: сохранить боту личность или выгрузить дамп прошивки для R&D.
/datum/unit_test/minor_incidents_engineering/proc/check_bot_glitch_choices()
	var/mob/living/simple_animal/bot/cleanbot/keeper = allocate(/mob/living/simple_animal/bot/cleanbot, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/roboticist = make_roboticist(run_loc_floor_top_right)
	var/datum/component/bot_firmware_glitch/glitch = keeper.AddComponent(/datum/component/bot_firmware_glitch)
	glitch.finish_repair(roboticist, "Сохранить личность")
	TEST_ASSERT(QDELETED(glitch), "Перепрошивка с сохранением личности снимает сбой")
	var/datum/component/bot_personality/personality = keeper.GetComponent(/datum/component/bot_personality)
	TEST_ASSERT_NOTNULL(personality, "Сохранённая личность остаётся в боте")
	TEST_ASSERT(findtext(examine_text(keeper, roboticist), "личность"), "Личность видна при осмотре")
	TEST_ASSERT_NULL(keeper.get_filter("bot_glitch_cyan"), "Личность не оставляет помех сбоя")
	personality.quip()

	var/mob/living/simple_animal/bot/medbot/dumped = allocate(/mob/living/simple_animal/bot/medbot, run_loc_floor_bottom_left)
	glitch = dumped.AddComponent(/datum/component/bot_firmware_glitch)
	glitch.finish_repair(roboticist, "Дамп прошивки")
	TEST_ASSERT(QDELETED(glitch), "Дамп прошивки снимает сбой")
	TEST_ASSERT_NULL(dumped.GetComponent(/datum/component/bot_personality), "После дампа личности не остаётся")
	var/obj/item/disk/bot_firmware_dump/dump = locate() in roboticist.held_items
	TEST_ASSERT_NOTNULL(dump, "Диск с дампом оказывается в руках робототехника")
	allocated += dump
	TEST_ASSERT(findtext(examine_text(dump, roboticist), "R&D"), "При осмотре диска видно, куда его нести")
	var/obj/machinery/computer/rdconsole/console = allocate(/obj/machinery/computer/rdconsole, run_loc_floor_bottom_left)
	console.machine_stat = NONE
	var/datum/techweb/research = console.stored_research || SSresearch.science_tech
	var/points_before = research.next_income[TECHWEB_POINT_TYPE_GENERIC]
	TEST_ASSERT(dump.upload(console, roboticist), "Консоль R&D принимает дамп")
	TEST_ASSERT_EQUAL(research.next_income[TECHWEB_POINT_TYPE_GENERIC], points_before + 1000, "Разбор дампа даёт 1000 очков исследований")
	TEST_ASSERT(QDELETED(dump), "Разобранный диск исчезает")

/datum/unit_test/minor_incidents_engineering/proc/check_firmware_patch()
	var/datum/round_event_control/silicon_firmware_patch/test_targets/controller = allocate(/datum/round_event_control/silicon_firmware_patch/test_targets)
	var/datum/round_event_control/silicon_firmware_patch/live_controller = allocate(/datum/round_event_control/silicon_firmware_patch)
	TEST_ASSERT_EQUAL(live_controller.get_disruption(), DIRECTOR_DISRUPTION_AMBIENT, "Патч прошивки - фоновое событие")
	var/mob/living/silicon/robot/borg = allocate(/mob/living/silicon/robot, run_loc_floor_bottom_left)
	TEST_ASSERT(!live_controller.is_recipient(borg), "Киборг без игрока не считается сменой")
	TEST_ASSERT(live_controller.is_recipient(borg, require_client = FALSE), "Станционный киборг получает рассылку")
	borg.scrambledcodes = TRUE
	TEST_ASSERT(!live_controller.is_recipient(borg, require_client = FALSE), "Киборги вне сети NanoTrasen рассылку не получают")
	borg.scrambledcodes = FALSE
	TEST_ASSERT(!live_controller.director_preflight(), "Без синтетиков на смене патч не рассылается")
	TEST_ASSERT_NOTNULL(live_controller.director_preflight_failure, "Провал preflight патча объясняется директору")

	var/datum/round_event/silicon_firmware_patch/silent = make_event(/datum/round_event/silicon_firmware_patch)
	silent.control = allocate(/datum/round_event_control/silicon_firmware_patch/no_recipients)
	silent.start()
	TEST_ASSERT_EQUAL(silent.recipient_count, 0, "Без адресатов рассылки нет, и объявлять нечего")

	var/obj/machinery/recharge_station/station = allocate(/obj/machinery/recharge_station, run_loc_floor_top_right)
	station.machine_stat = NONE
	var/obj/machinery/computer/robotics/console = allocate(/obj/machinery/computer/robotics, run_loc_floor_bottom_left)
	var/datum/round_event/silicon_firmware_patch/event = make_event(/datum/round_event/silicon_firmware_patch)
	event.control = controller
	event.start()
	TEST_ASSERT(event.recipient_count >= 1, "Киборг на смене получает рассылку")
	borg.forceMove(get_turf(station))
	station.close_machine(borg)
	TEST_ASSERT_EQUAL(borg.loc, station, "Киборг должен оказаться на зарядной станции")
	var/steps_needed = (20 SECONDS) / (2 SECONDS)
	for(var/tick_number in 1 to steps_needed)
		event.tick()
	TEST_ASSERT_NULL(borg.GetComponent(/datum/component/firmware_patched), "Неподписанный патч не ставится")
	TEST_ASSERT(!length(event.indicators), "Без подписи установка даже не начинается")

	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/item/multitool/multitool = allocate(/obj/item/multitool)
	TEST_ASSERT(!firmware_patch_is_roboticist(stranger), "Без доступа в робототехнику подписать нельзя")
	TEST_ASSERT_EQUAL(SEND_SIGNAL(console, COMSIG_ATOM_TOOL_ACT(TOOL_MULTITOOL), stranger, multitool, list()), TOOL_ACT_MELEE_CHAIN_BLOCKING, "Консоль робототехники отвечает на мультитул")
	TEST_ASSERT(!event.signed, "Посторонний патч не подписывает")
	var/mob/living/carbon/human/roboticist = make_roboticist(run_loc_floor_bottom_left)
	TEST_ASSERT(firmware_patch_is_roboticist(roboticist), "Робототехник может подписать патч")
	TEST_ASSERT(event.sign_patch(roboticist), "Робототехник подписывает патч")
	TEST_ASSERT(!event.sign_patch(roboticist), "Подписать можно один раз")

	for(var/tick_number in 1 to steps_needed - 1)
		event.tick()
	TEST_ASSERT_NULL(borg.GetComponent(/datum/component/firmware_patched), "Патч ставится не мгновенно")
	var/obj/effect/indicator = event.indicators[WEAKREF(borg)]
	TEST_ASSERT(indicator && (indicator in station.vis_contents), "Во время установки на станции виден индикатор")
	event.tick()
	TEST_ASSERT_NOTNULL(borg.GetComponent(/datum/component/firmware_patched), "Через двадцать секунд после подписи патч установлен")
	TEST_ASSERT(QDELETED(indicator), "Индикатор установки снимается после завершения")
	TEST_ASSERT_EQUAL(event.installed_count, 1, "Установка считается один раз")
	event.tick()
	TEST_ASSERT_EQUAL(event.installed_count, 1, "Повторно патч не ставится")

	borg.cell.charge = 0
	SEND_SIGNAL(borg, COMSIG_PROCESS_BORGCHARGER_OCCUPANT, 100, 0)
	TEST_ASSERT_EQUAL(borg.cell.charge, 125, "Обновлённый киборг заряжается на 25% быстрее")
	TEST_ASSERT(findtext(examine_text(borg, borg), "Прошивка обновлена"), "При осмотре видно обновлённую прошивку")
	station.open_machine()
	borg.cell.charge = 1000
	SEND_SIGNAL(borg, COMSIG_LIVING_LIFE, 2, 1)
	borg.cell.charge = 600
	SEND_SIGNAL(borg, COMSIG_LIVING_LIFE, 2, 2)
	TEST_ASSERT_EQUAL(borg.cell.charge, 700, "Обновлённый киборг тратит на 25% меньше энергии")

	var/mob/living/silicon/robot/restless = allocate(/mob/living/silicon/robot, run_loc_floor_bottom_left)
	var/obj/machinery/recharge_station/second_station = allocate(/obj/machinery/recharge_station, run_loc_floor_bottom_left)
	second_station.machine_stat = NONE
	second_station.close_machine(restless)
	event.tick()
	event.tick()
	var/obj/effect/second_indicator = event.indicators[WEAKREF(restless)]
	TEST_ASSERT_NOTNULL(second_indicator, "Второй киборг тоже начинает установку")
	second_station.open_machine()
	event.tick()
	TEST_ASSERT(!(WEAKREF(restless) in event.install_progress), "Ушедший со станции киборг теряет прогресс")
	TEST_ASSERT(QDELETED(second_indicator), "Прерванная установка убирает индикатор")

	second_station.close_machine(restless)
	event.tick()
	var/obj/effect/last_indicator = event.indicators[WEAKREF(restless)]
	event.control = null
	event.kill()
	TEST_ASSERT(event.window_closed, "Окно установки закрывается")
	TEST_ASSERT(QDELETED(last_indicator), "Закрытие окна установки убирает индикаторы")
	TEST_ASSERT_NULL(restless.GetComponent(/datum/component/firmware_patched), "Недоустановленный патч не даёт бонуса")
	TEST_ASSERT_EQUAL(SEND_SIGNAL(console, COMSIG_ATOM_TOOL_ACT(TOOL_MULTITOOL), roboticist, multitool, list()), NONE, "После закрытия окна консоль снова обычная")
	second_station.open_machine()

/// Робототехник прошивает киборга вручную, посторонний - нет.
/datum/unit_test/minor_incidents_engineering/proc/check_firmware_flash()
	var/datum/round_event_control/silicon_firmware_patch/test_targets/controller = allocate(/datum/round_event_control/silicon_firmware_patch/test_targets)
	var/mob/living/silicon/robot/borg = allocate(/mob/living/silicon/robot, run_loc_floor_top_right)
	var/datum/round_event/silicon_firmware_patch/event = make_event(/datum/round_event/silicon_firmware_patch)
	event.control = controller
	event.start()
	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/item/multitool/multitool = allocate(/obj/item/multitool)
	TEST_ASSERT_EQUAL(SEND_SIGNAL(borg, COMSIG_ATOM_TOOL_ACT(TOOL_MULTITOOL), stranger, multitool, list()), NONE, "Посторонний с мультитулом киборга не прошивает")
	var/mob/living/carbon/human/roboticist = make_roboticist(run_loc_floor_bottom_left)
	TEST_ASSERT(event.apply_patch(borg, borg, roboticist), "Робототехник прошивает киборга без подписи и зарядной станции")
	TEST_ASSERT_NOTNULL(borg.GetComponent(/datum/component/firmware_patched), "Прошитый вручную киборг получает бонус")
	TEST_ASSERT(!event.signed, "Ручная прошивка не подписывает патч для всех")
	TEST_ASSERT_EQUAL(SEND_SIGNAL(borg, COMSIG_ATOM_TOOL_ACT(TOOL_MULTITOOL), roboticist, multitool, list()), NONE, "Прошитого киборга повторно не прошивают")
	event.control = null
	event.kill()

/datum/unit_test/minor_incidents_engineering/proc/check_ai_patch()
	var/mob/living/carbon/human/donor = allocate(/mob/living/carbon/human)
	var/mob/living/silicon/ai/ai = allocate(/mob/living/silicon/ai, run_loc_floor_bottom_left, null, donor)
	var/datum/round_event/silicon_firmware_patch/event = make_event(/datum/round_event/silicon_firmware_patch)
	event.install_ai_patch(ai)
	var/obj/effect/minor_incident_overlay/ai_update_screen/screen = locate() in ai.vis_contents
	TEST_ASSERT_NOTNULL(screen, "ИИ показывает экран установки обновления")
	TEST_ASSERT(screen.lifetime > 0, "Экран установки временный")
	screen.expire()
	TEST_ASSERT(!(screen in ai.vis_contents), "По истечении экран установки снимается")
