/// Пол теста в своей зоне с питанием (на резервном z его нет); при удалении пол возвращается в старую зону.
/datum/hk_factory_test_floor
	var/turf/floor
	var/area/original_area
	var/area/powered_area

/datum/hk_factory_test_floor/New(turf/floor, area_type = /area)
	// BYOND не собирает зоны: удалённая зона уходит в харддел, поэтому зона одна на тип за весь прогон.
	var/static/list/shared_areas = list()
	powered_area = shared_areas[area_type]
	if(!powered_area)
		var/area/displaced_unique = GLOB.areas_by_type[area_type]
		powered_area = new area_type
		GLOB.areas_by_type[area_type] = displaced_unique
		shared_areas[area_type] = powered_area
	src.floor = floor
	original_area = get_area(floor)
	powered_area.contents.Add(floor)

/datum/hk_factory_test_floor/Destroy()
	original_area.contents.Add(floor)
	var/area/ruin/space/has_grav/hk_factory/plant = powered_area
	if(istype(plant))
		hk_factory_test_reset(plant)
	floor = null
	original_area = null
	powered_area = null
	return ..()

/// Вернуть цех в состояние до теста: зона переживает тест.
/proc/hk_factory_test_reset(area/ruin/space/has_grav/hk_factory/plant)
	deltimer(plant.ambush_timer)
	plant.ambush_timer = null
	plant.fall_asleep()
	plant.ambush_sprung = FALSE
	plant.production_active = TRUE
	plant.protocol_active = FALSE
	plant.protocol_turf = null
	plant.protocol_culprit_ref = null
	plant.had_power = plant.power_equip

/// Конвейер собирает HK-50 до лимита фабрики, дроид знает свой конвейер, остановленный или обесточенный конвейер не собирает.
/datum/unit_test/hk_factory_line

/datum/unit_test/hk_factory_line/Run()
	var/datum/hk_factory_test_floor/factory = allocate(/datum/hk_factory_test_floor, run_loc_floor_bottom_left)
	var/obj/machinery/hk_assembly_line/line = allocate(/obj/machinery/hk_assembly_line)
	var/list/made = list()
	for(var/i in 1 to HK_FACTORY_MAX_DROIDS + 2)
		var/mob/living/simple_animal/hostile/hk50/droid = line.try_assemble()
		if(droid)
			made += droid
			allocated += droid
	TEST_ASSERT_EQUAL(length(made), HK_FACTORY_MAX_DROIDS, "Конвейер не остановился на лимите фабрики")
	var/mob/living/simple_animal/hostile/hk50/first = made[1]
	TEST_ASSERT_EQUAL(first.factory_ref?.resolve(), line, "Собранный HK-50 не знает свой конвейер")

	line.set_active(FALSE)
	TEST_ASSERT_NULL(line.assembly_timer, "Остановленный конвейер держит таймер сборки")
	first.death()
	TEST_ASSERT_EQUAL(line.factory_droid_count(), HK_FACTORY_MAX_DROIDS - 1, "Погибший HK-50 остался на учёте конвейера")
	TEST_ASSERT_NULL(line.assembly_timer, "Остановленный конвейер завёл сборку после потери")
	TEST_ASSERT_NULL(line.try_assemble(), "Остановленный конвейер собрал HK-50")
	line.set_active(TRUE)
	TEST_ASSERT_NOTNULL(line.assembly_timer, "Запущенный конвейер ниже штата не завёл сборку")

	factory.powered_area.power_equip = FALSE
	factory.powered_area.power_change()
	TEST_ASSERT_NULL(line.assembly_timer, "Обесточенный конвейер держит таймер сборки")
	TEST_ASSERT_NULL(line.try_assemble(), "Обесточенный конвейер собрал HK-50")
	TEST_ASSERT_EQUAL(line.icon_state, "assembly_line_off", "Обесточенный конвейер выглядит работающим")
	factory.powered_area.power_equip = TRUE
	factory.powered_area.power_change()

	var/mob/living/simple_animal/hostile/hk50/replacement = line.try_assemble()
	TEST_ASSERT_NOTNULL(replacement, "Конвейер с питанием не собрал замену ниже лимита")
	allocated += replacement
	line.set_active(FALSE)
	line.set_active(TRUE)
	TEST_ASSERT_NULL(line.assembly_timer, "При полном штате конвейер завёл сборку")
	qdel(replacement)
	TEST_ASSERT_NOTNULL(line.assembly_timer, "Потеря дроида не запустила сборку замены")

/// Лимит общий на цех: два конвейера, стража с карты и спящие стойки вместе не превышают штат.
/datum/unit_test/hk_factory_shared_cap

/datum/unit_test/hk_factory_shared_cap/Run()
	allocate(/datum/hk_factory_test_floor, run_loc_floor_bottom_left)
	var/obj/machinery/hk_assembly_line/first_line = allocate(/obj/machinery/hk_assembly_line)
	var/obj/machinery/hk_assembly_line/second_line = allocate(/obj/machinery/hk_assembly_line)
	var/mob/living/simple_animal/hostile/hk50/factory_guard/guard = allocate(/mob/living/simple_animal/hostile/hk50/factory_guard)
	var/obj/structure/hk50_rack/dormant/rack = allocate(/obj/structure/hk50_rack/dormant)
	TEST_ASSERT_NOTNULL(guard.factory_ref?.resolve(), "Страж фабрики не встал на учёт конвейера")
	var/made = 0
	for(var/i in 1 to HK_FACTORY_MAX_DROIDS)
		for(var/obj/machinery/hk_assembly_line/line as anything in list(first_line, second_line))
			var/mob/living/simple_animal/hostile/hk50/droid = line.try_assemble()
			if(droid)
				allocated += droid
				made++
	TEST_ASSERT_EQUAL(made, HK_FACTORY_MAX_DROIDS - 2, "Цех собрал больше штата, не считая стражу и спящую стойку")

	var/mob/living/simple_animal/hostile/hk50/woken = rack.wake(null)
	allocated += woken
	TEST_ASSERT_NOTNULL(woken?.factory_ref?.resolve(), "Проснувшийся HK-50 не встал на учёт конвейера")
	TEST_ASSERT_EQUAL(first_line.factory_droid_count(), HK_FACTORY_MAX_DROIDS, "Пробуждение стойки изменило штат цеха")

	var/mob/living/simple_animal/hostile/hk50/orphan = pick(first_line.droids)
	qdel(first_line)
	TEST_ASSERT_EQUAL(orphan.factory_ref?.resolve(), second_line, "Дроиды разломанного конвейера не перешли к соседнему")
	TEST_ASSERT_NULL(second_line.try_assemble(), "После потери конвейера цех собрал дроида сверх штата")

/// Пульт переключает конвейеры и турели только своей зоны.
/datum/unit_test/hk_factory_console

/datum/unit_test/hk_factory_console/Run()
	allocate(/datum/hk_factory_test_floor, run_loc_floor_bottom_left)
	var/obj/machinery/computer/hk_factory_console/console = allocate(/obj/machinery/computer/hk_factory_console)
	var/obj/machinery/hk_assembly_line/first_line = allocate(/obj/machinery/hk_assembly_line)
	var/obj/machinery/hk_assembly_line/second_line = allocate(/obj/machinery/hk_assembly_line)
	var/obj/machinery/porta_turret/syndicate/energy/hk_factory/turret = allocate(/obj/machinery/porta_turret/syndicate/energy/hk_factory)
	var/obj/machinery/hk_assembly_line/elsewhere = allocate(/obj/machinery/hk_assembly_line, run_loc_floor_top_right)
	var/mob/living/carbon/human/operator = allocate(/mob/living/carbon/human)

	console.interact(operator)
	TEST_ASSERT(!first_line.active && !second_line.active, "Пульт не остановил конвейеры своего цеха")
	TEST_ASSERT(!turret.on, "Пульт не выключил турель цеха")
	TEST_ASSERT(elsewhere.active, "Пульт остановил конвейер в другой зоне")
	TEST_ASSERT_EQUAL(console.icon_state, "factory_console_off", "Пульт не показывает остановку")
	TEST_ASSERT_EQUAL(first_line.icon_state, "assembly_line_off", "Остановленный конвейер выглядит работающим")

	console.interact(operator)
	TEST_ASSERT(first_line.active && second_line.active, "Пульт не запустил конвейеры снова")
	TEST_ASSERT(turret.on, "Пульт не включил турель снова")
	TEST_ASSERT_EQUAL(console.icon_state, "factory_console", "Пульт не показывает запуск")

/// Удар по спящей стойке поднимает засаду цеха: стойки мигают, а дроиды сходят только после телеграфа.
/datum/unit_test/hk_factory_rack_alarm

/datum/unit_test/hk_factory_rack_alarm/Run()
	var/datum/hk_factory_test_floor/floor = allocate(/datum/hk_factory_test_floor, run_loc_floor_bottom_left, /area/ruin/space/has_grav/hk_factory)
	var/area/ruin/space/has_grav/hk_factory/factory = floor.powered_area
	var/obj/structure/hk50_rack/dormant/shot_rack = allocate(/obj/structure/hk50_rack/dormant)
	var/obj/structure/hk50_rack/dormant/other_rack = allocate(/obj/structure/hk50_rack/dormant)
	shot_rack.take_damage(10, BRUTE, MELEE, FALSE)
	TEST_ASSERT(factory.ambush_sprung, "Удар по спящей стойке не поднял засаду")
	TEST_ASSERT(other_rack.waking && other_rack.icon_state == "hk50_rack_alert", "Соседняя стойка не мигает перед засадой")
	TEST_ASSERT_EQUAL(length(hk_factory_members(GLOB.hk50_dormant_racks, factory)), 2, "Дроиды сошли со стоек без телеграфа")
	TEST_ASSERT_NOTNULL(factory.ambush_timer, "У засады нет отсчёта телеграфа")
	deltimer(factory.ambush_timer)
	var/list/woken = factory.release_ambush(null)
	allocated += woken
	TEST_ASSERT_EQUAL(length(woken), 2, "После телеграфа сошли не все дроиды")
	for(var/mob/living/simple_animal/hostile/hk50/droid as anything in woken)
		TEST_ASSERT_NULL(droid.target, "Дроид без нарушителя взял цель")
	for(var/obj/structure/hk50_rack/empty/husk in floor.floor)
		allocated += husk

/// Датчик засады видит чужака в шкафу и в мехе, а HK серии и пустой шкаф - нет.
/datum/unit_test/hk_factory_intruder_inside

/datum/unit_test/hk_factory_intruder_inside/Run()
	var/mob/living/carbon/human/visitor = allocate(/mob/living/carbon/human)
	visitor.ckey = "hk_factory_stowaway"
	var/obj/structure/closet/locker = allocate(/obj/structure/closet)
	TEST_ASSERT_NULL(hk_factory_intruder(locker), "Пустой шкаф стал нарушителем")
	visitor.forceMove(locker)
	TEST_ASSERT_EQUAL(hk_factory_intruder(locker), visitor, "Чужак в шкафу прошёл мимо датчика")
	var/mob/living/carbon/human/kin = allocate(/mob/living/carbon/human)
	kin.ckey = "hk_factory_kin"
	kin.set_species(/datum/species/ipc/hk/hk51)
	TEST_ASSERT_NULL(hk_factory_intruder(kin), "Шасси HK стало нарушителем")
	visitor.forceMove(run_loc_floor_bottom_left)

/// Патрульный страж ходит по самому длинному проходу и разворачивается у конца.
/datum/unit_test/hk_factory_patrol

/datum/unit_test/hk_factory_patrol/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/list/ends = hk50_patrol_ends(origin)
	TEST_ASSERT_EQUAL(length(ends), 2, "У маршрута нет двух концов")
	var/turf/first = ends[1]
	var/turf/second = ends[2]
	TEST_ASSERT(get_dist(first, second) >= 2, "Маршрут патруля короче двух клеток")
	var/mob/living/simple_animal/hostile/hk50/factory_guard/patrol/guard = allocate(/mob/living/simple_animal/hostile/hk50/factory_guard/patrol, first)
	var/datum/ai_controller/controller = guard.ai_controller
	TEST_ASSERT(istype(controller, /datum/ai_controller/hostile_adapter/ranged_skirmisher/hk50_patrol), "Патрульный без патрульного ИИ")
	controller.blackboard[BB_HK50_PATROL_ENDS] = ends
	var/datum/idle_behavior/idle_random_walk/hk50_patrol/patrol = controller.idle_behavior
	TEST_ASSERT_EQUAL(patrol.pick_idle_direction(guard, controller), get_dir(first, second), "Патрульный не идёт ко второму концу")
	guard.forceMove(second)
	TEST_ASSERT_EQUAL(patrol.pick_idle_direction(guard, controller), get_dir(second, first), "Патрульный не развернулся у конца")

/// Чип лояльности с фабрики перепрошивает только обездвиженного HK и выгорает.
/datum/unit_test/hk_loyalty_chip

/datum/unit_test/hk_loyalty_chip/Run()
	var/mob/living/carbon/human/droid = allocate(/mob/living/carbon/human)
	droid.set_species(/datum/species/ipc/hk/hk51)
	var/mob/living/carbon/human/officer = allocate(/mob/living/carbon/human)
	officer.mind_initialize()
	allocated += officer.mind
	var/obj/item/hk_loyalty_chip/chip = allocate(/obj/item/hk_loyalty_chip)
	TEST_ASSERT(!chip.overwrite_loyalty(droid, officer, skip_delay = TRUE), "Чип записался в свободного HK")
	TEST_ASSERT(!QDELETED(chip), "Чип выгорел без записи")
	droid.Paralyze(10 SECONDS)
	TEST_ASSERT(chip.overwrite_loyalty(droid, officer, skip_delay = TRUE), "Чип не записался в обездвиженного HK")
	var/datum/component/hk_loyalty/loyalty = droid.GetComponent(/datum/component/hk_loyalty)
	TEST_ASSERT_EQUAL(loyalty?.get_master(), officer.mind, "Чип не сделал хозяином того, кто его приложил")
	TEST_ASSERT(QDELETED(chip), "Одноразовый чип не выгорел")

/// Чип лояльности лежит в слоте терминала серверной: рукой вынимается и без питания, а из разбитого терминала выпадает.
/datum/unit_test/hk_factory_server_chip

/datum/unit_test/hk_factory_server_chip/Run()
	var/obj/machinery/computer/hk_factory_server/server = allocate(/obj/machinery/computer/hk_factory_server)
	server.set_machine_stat(server.machine_stat | NOPOWER)
	var/mob/living/carbon/human/reader = allocate(/mob/living/carbon/human)
	server.attack_hand(reader)
	var/obj/item/hk_loyalty_chip/chip = locate() in reader.held_items
	TEST_ASSERT_NOTNULL(chip, "Из обесточенного терминала не вынуть чип")
	allocated += chip
	TEST_ASSERT_NULL(locate(/obj/item/paper/fluff/ruins/hk_factory/server_log) in reader.held_items, "Обесточенный терминал распечатал журнал")

	var/turf/wreck_spot = run_loc_floor_top_right
	var/obj/machinery/computer/hk_factory_server/wrecked = allocate(/obj/machinery/computer/hk_factory_server, wreck_spot)
	wrecked.take_damage(wrecked.max_integrity, BRUTE, MELEE, FALSE)
	TEST_ASSERT(QDELETED(wrecked), "Терминал не разбился")
	var/obj/item/hk_loyalty_chip/dropped = locate() in wreck_spot
	TEST_ASSERT_NOTNULL(dropped, "Разбитый терминал унёс чип с собой")
	allocated += dropped

/// Автономный протокол гонит стражу к щитовой на долгий розыск, но обычный розыск дроида не удлиняет.
/datum/unit_test/hk_factory_protocol_search

/datum/unit_test/hk_factory_protocol_search/Run()
	var/datum/hk_factory_test_floor/floor = allocate(/datum/hk_factory_test_floor, run_loc_floor_bottom_left, /area/ruin/space/has_grav/hk_factory)
	var/area/ruin/space/has_grav/hk_factory/factory = floor.powered_area
	var/mob/living/simple_animal/hostile/hk50/guard = allocate(/mob/living/simple_animal/hostile/hk50)
	var/datum/ai_controller/controller = guard.ai_controller
	TEST_ASSERT_NOTNULL(controller, "У стража нет ИИ")
	var/usual_search_time = controller.blackboard[BB_AI_SEARCH_TIME]
	factory.protocol_turf = run_loc_floor_top_right
	factory.rally_guards(list(guard))
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_LAST_KNOWN_POS], run_loc_floor_top_right, "Страж не пошёл к щитовой")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_SEARCH_UNTIL], world.time + HK_FACTORY_PROTOCOL_SEARCH_TIME, "Розыск у щитовой короче протокола")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_SEARCH_TIME], usual_search_time, "Протокол навсегда удлинил обычный розыск дроида")

/// Лазер HK-50 стреляет только в шасси серии HK.
/datum/unit_test/hk50_arm_laser

/datum/unit_test/hk50_arm_laser/Run()
	var/obj/item/organ/cyberimp/arm/gun/laser/hk50/implant = allocate(/obj/item/organ/cyberimp/arm/gun/laser/hk50)
	var/obj/item/gun/energy/laser/mounted/hk50/laser = locate() in implant
	TEST_ASSERT_NOTNULL(laser, "В импланте нет лазера HK-50")
	var/mob/living/carbon/human/droid = allocate(/mob/living/carbon/human)
	droid.set_species(/datum/species/ipc/hk/hk51)
	var/mob/living/carbon/human/crewman = allocate(/mob/living/carbon/human)
	TEST_ASSERT(laser.pin.pin_auth(droid), "Лазер HK-50 не стреляет у HK-51")
	TEST_ASSERT(!laser.pin.pin_auth(crewman), "Лазер HK-50 стреляет у человека")

/// Выдвинутый лазер HK-50 виден на любом заряде и в обеих руках.
/datum/unit_test/hk50_arm_laser_sprites

/datum/unit_test/hk50_arm_laser_sprites/Run()
	var/obj/item/gun/energy/laser/mounted/hk50/laser = allocate(/obj/item/gun/energy/laser/mounted/hk50)
	var/list/item_states = icon_states(laser.icon)
	TEST_ASSERT(laser.icon_state in item_states, "У лазера HK-50 нет иконки")
	TEST_ASSERT("[laser.icon_state]_empty" in item_states, "Разряженный лазер HK-50 без спрайта")
	for(var/level in 1 to laser.charge_sections)
		TEST_ASSERT("[laser.icon_state]_charge[level]" in item_states, "У лазера HK-50 нет полоски заряда [level]")
	TEST_ASSERT(laser.item_state in icon_states(laser.lefthand_file), "Лазер HK-50 не виден в левой руке")
	TEST_ASSERT(laser.item_state in icon_states(laser.righthand_file), "Лазер HK-50 не виден в правой руке")

/// Руина фабрики в своей зоне: цех с пультом и турелями, штат со спящими стойками, засада с телеграфом, ключ-карта, чип, рубильник с автономным протоколом.
/datum/unit_test/hk_factory_ruin
	var/datum/turf_reservation/placement
	var/area/ruin/space/has_grav/hk_factory/factory
	/// Фабрика раунда или её подмена: делит с фабрикой теста уникальную зону.
	var/datum/hk_factory_test_floor/round_factory_stand_in
	var/list/landmarks = list()

/datum/unit_test/hk_factory_ruin/Run()
	var/datum/map_template/ruin/space/hk_factory/template
	for(var/name in SSmapping.space_ruins_templates)
		template = SSmapping.space_ruins_templates[name]
		if(istype(template))
			break
		template = null
	TEST_ASSERT_NOTNULL(template, "Шаблон фабрики HK не попал в пул космических руин")
	var/area/round_factory = GLOB.areas_by_type[/area/ruin/space/has_grav/hk_factory]
	if(!round_factory)
		round_factory_stand_in = new(run_loc_floor_top_right, /area/ruin/space/has_grav/hk_factory)
		round_factory = round_factory_stand_in.powered_area
		allocate(/obj/structure/hk50_rack/dormant, run_loc_floor_top_right)
	placement = SSmapping.RequestBlockReservation(template.width, template.height)
	TEST_ASSERT_NOTNULL(placement, "Нет места под шаблон фабрики")
	var/turf/bottom_left = TURF_FROM_COORDS_LIST(placement.bottom_left_coords)
	var/area/registered_factory = GLOB.areas_by_type[/area/ruin/space/has_grav/hk_factory]
	GLOB.areas_by_type -= /area/ruin/space/has_grav/hk_factory
	var/loaded = template.load(bottom_left)
	GLOB.areas_by_type[/area/ruin/space/has_grav/hk_factory] = registered_factory
	TEST_ASSERT(loaded, "Шаблон фабрики не загрузился")

	var/list/found = list()
	var/list/turf/triggers = list()
	for(var/turf/place as anything in template.get_affected_turfs(bottom_left))
		for(var/atom/movable/thing as anything in place.GetAllContents())
			for(var/kind in list(/obj/machinery/hk_assembly_line, /obj/machinery/computer/hk_factory_console, /mob/living/simple_animal/hostile/hk50,
					/obj/structure/hk50_rack/dormant, /obj/machinery/porta_turret/syndicate/energy/hk_factory, /obj/effect/landmark/hk51_part_spot/factory,
					/obj/item/card/id/away/hk_foreman, /obj/machinery/power/apc, /obj/machinery/conveyor/hk_factory, /obj/machinery/computer/hk_factory_server,
					/mob/living/simple_animal/hostile/hk50/factory_guard/patrol, /obj/item/organ/cyberimp/arm/gun/laser/hk50))
				if(istype(thing, kind))
					LAZYADD(found[kind], thing)
			if(istype(thing, /obj/effect/hk_factory_ambush_trigger))
				triggers += place
			if(istype(thing, /obj/effect/landmark))
				landmarks += thing
	var/list/lines = found[/obj/machinery/hk_assembly_line]
	var/list/consoles = found[/obj/machinery/computer/hk_factory_console]
	var/list/turrets = found[/obj/machinery/porta_turret/syndicate/energy/hk_factory]
	TEST_ASSERT_EQUAL(length(lines), 2, "На фабрике не два конвейера")
	TEST_ASSERT_EQUAL(length(consoles), 1, "На фабрике не один пульт")
	TEST_ASSERT(length(turrets) >= 2, "На фабрике меньше двух турелей")
	TEST_ASSERT(length(found[/obj/machinery/conveyor/hk_factory]) >= 4, "В цехе нет ленты")
	TEST_ASSERT(length(triggers) >= 2, "У цеха нет датчиков засады")
	var/obj/machinery/computer/hk_factory_console/console = consoles[1]
	factory = get_area(console)
	TEST_ASSERT(istype(factory), "Пульт стоит вне зоны фабрики")
	TEST_ASSERT(factory != round_factory, "Фабрика теста делит зону с фабрикой раунда")
	for(var/obj/machinery/hk_assembly_line/line as anything in lines)
		TEST_ASSERT_EQUAL(get_area(line), factory, "Конвейер вне цеха пульта")
		var/turf/exit = get_step(line, line.dir)
		TEST_ASSERT(exit && !exit.is_blocked_turf(TRUE), "Выход конвейера перекрыт")

	var/obj/machinery/hk_assembly_line/first_line = lines[1]
	var/list/dormant = found[/obj/structure/hk50_rack/dormant]
	var/awake_guards = length(found[/mob/living/simple_animal/hostile/hk50])
	TEST_ASSERT(length(dormant) >= 3, "В цехе меньше трёх спящих стоек")
	for(var/obj/structure/hk50_rack/dormant/rack as anything in dormant)
		var/turf/rack_exit = get_step(rack, rack.dir)
		TEST_ASSERT(rack.dir == SOUTH && rack_exit && !rack_exit.is_blocked_turf(TRUE), "Стойка в ([rack.x - bottom_left.x + 1],[rack.y - bottom_left.y + 1]) выпускает дроида не лицом к цеху")
	TEST_ASSERT_EQUAL(awake_guards + length(dormant), HK_FACTORY_MAX_DROIDS, "Стража и спящие стойки не равны штату фабрики")
	TEST_ASSERT_EQUAL(first_line.factory_droid_count(), HK_FACTORY_MAX_DROIDS, "Не вся стража фабрики на учёте конвейеров")
	var/mob/living/simple_animal/hostile/hk50/factory_guard/patrol/patrol = LAZYACCESS(found[/mob/living/simple_animal/hostile/hk50/factory_guard/patrol], 1)
	TEST_ASSERT_NOTNULL(patrol, "В коридоре нет патрульного")
	var/list/patrol_ends = patrol.ai_controller?.blackboard[BB_HK50_PATROL_ENDS]
	TEST_ASSERT(length(patrol_ends) == 2 && get_dist(patrol_ends[1], patrol_ends[2]) >= 10, "Маршрут патруля короче коридора")

	var/obj/item/card/id/away/hk_foreman/keycard = LAZYACCESS(found[/obj/item/card/id/away/hk_foreman], 1)
	TEST_ASSERT_NOTNULL(keycard, "На фабрике нет ключ-карты начальника смены")
	var/obj/effect/landmark/spot = LAZYACCESS(found[/obj/effect/landmark/hk51_part_spot/factory], 1)
	TEST_ASSERT_NOTNULL(spot, "На фабрике нет точки тайника HK-51")
	var/obj/structure/closet/secure_closet/locker = locate() in get_turf(spot)
	TEST_ASSERT_NOTNULL(locker, "Тайник HK-51 не в шкафу")
	TEST_ASSERT(locker.locked, "Шкаф с тайником HK-51 не заперт")
	TEST_ASSERT(locker.check_access(keycard), "Ключ-карта не открывает шкаф с тайником")
	TEST_ASSERT(!locker.check_access(null), "Шкаф с тайником открывается без карты")
	TEST_ASSERT_NOTNULL(locate(/obj/item/organ/cyberimp/arm/gun/laser/hk50) in locker, "В шкафу склада нет лазера HK-50")
	var/obj/machinery/door/airlock/storage_door
	for(var/obj/machinery/door/airlock/door in range(8, locker))
		if(!door.check_access(null))
			storage_door = door
			break
	TEST_ASSERT_NOTNULL(storage_door, "У склада нет двери с замком")
	TEST_ASSERT(storage_door.check_access(keycard), "Ключ-карта не открывает дверь склада")

	var/obj/machinery/computer/hk_factory_server/server = LAZYACCESS(found[/obj/machinery/computer/hk_factory_server], 1)
	TEST_ASSERT_NOTNULL(server, "На фабрике нет терминала серверной")
	var/mob/living/carbon/human/reader = allocate(/mob/living/carbon/human, get_turf(server))
	server.attack_hand(reader)
	var/obj/item/hk_loyalty_chip/chip = locate() in reader.held_items
	var/obj/item/paper/fluff/ruins/hk_factory/server_log/printout = locate() in reader.held_items
	TEST_ASSERT_NOTNULL(chip, "Терминал серверной не выдал чип лояльности")
	TEST_ASSERT_NOTNULL(printout, "Терминал серверной не распечатал журнал")
	allocated += list(chip, printout)
	server.attack_hand(reader)
	var/chips = 0
	for(var/obj/item/hk_loyalty_chip/extra_chip in get_turf(server))
		chips++
	TEST_ASSERT_EQUAL(chips, 0, "Терминал выдал второй чип")

	var/datum/hk51_part_scatter/stash_check = new
	var/list/stash_placed = stash_check.scatter(list(), get_turf(spot))
	TEST_ASSERT_EQUAL(stash_placed[/obj/item/hk51_part/motivator], locker, "Мотиватор HK-51 ляжет мимо запертого шкафа")
	var/stash_parts = 0
	for(var/obj/item/hk51_part/stashed in locker)
		stash_parts++
	TEST_ASSERT_EQUAL(stash_parts, 1, "В шкаф тайника легла не только деталь фабрики")
	qdel(stash_check)
	for(var/obj/item/hk51_part/stash_part in locker)
		qdel(stash_part)

	var/mob/living/carbon/human/operator = allocate(/mob/living/carbon/human, get_turf(console))
	console.interact(operator)
	for(var/obj/machinery/porta_turret/syndicate/energy/hk_factory/turret as anything in turrets)
		TEST_ASSERT(!turret.on, "Пульт фабрики не выключил турель")
	TEST_ASSERT(!first_line.active, "Пульт фабрики не остановил конвейер")
	factory.wake_up()
	var/obj/machinery/conveyor/belt = found[/obj/machinery/conveyor/hk_factory][1]
	TEST_ASSERT_EQUAL(belt.operating, CONVEYOR_OFF, "Лента едет при остановленном цехе")
	console.interact(operator)
	for(var/obj/machinery/porta_turret/syndicate/energy/hk_factory/turret as anything in turrets)
		TEST_ASSERT(turret.on, "Пульт фабрики не включил турель")
	TEST_ASSERT_EQUAL(belt.operating, CONVEYOR_FORWARD, "Лента не поехала, когда на фабрике люди и цех запущен")
	factory.fall_asleep()
	TEST_ASSERT_EQUAL(belt.operating, CONVEYOR_OFF, "Лента едет на пустой фабрике")

	var/mob/living/carbon/human/intruder = allocate(/mob/living/carbon/human, get_turf(console))
	intruder.ckey = "hk_factory_intruder"
	var/obj/structure/closet/crate = allocate(/obj/structure/closet, get_turf(console))
	intruder.forceMove(crate)
	crate.forceMove(triggers[1])
	TEST_ASSERT(factory.ambush_sprung, "Датчик цеха пропустил нарушителя в шкафу")
	TEST_ASSERT_EQUAL(length(hk_factory_members(GLOB.hk50_dormant_racks, factory)), length(dormant), "Стойки выпустили дроидов без телеграфа")
	for(var/obj/structure/hk50_rack/dormant/rack as anything in dormant)
		TEST_ASSERT_EQUAL(rack.icon_state, "hk50_rack_alert", "Стойка не мигает перед засадой")
	TEST_ASSERT_NOTNULL(factory.ambush_timer, "У засады нет отсчёта телеграфа")
	var/flickering_lights = 0
	for(var/obj/machinery/light/light in factory)
		if(light.flickering)
			flickering_lights++
	TEST_ASSERT(flickering_lights > 0, "Свет цеха не дёргается перед засадой")
	deltimer(factory.ambush_timer)
	factory.release_ambush(WEAKREF(intruder))
	TEST_ASSERT_EQUAL(length(hk_factory_members(GLOB.hk50_dormant_racks, factory)), 0, "Спящие стойки не проснулись")
	TEST_ASSERT_EQUAL(first_line.factory_droid_count(), HK_FACTORY_MAX_DROIDS, "Засада изменила штат фабрики")
	var/list/droids_after_ambush = hk_factory_droids(factory)
	TEST_ASSERT_EQUAL(length(droids_after_ambush), HK_FACTORY_MAX_DROIDS, "После засады на фабрике не весь штат")
	crate.forceMove(triggers[2])
	TEST_ASSERT_NULL(factory.ambush_timer, "Засада сработала второй раз")
	intruder.forceMove(get_turf(console))

	var/obj/machinery/power/apc/apc = found[/obj/machinery/power/apc][1]
	factory.wake_up()
	apc.toggle_breaker(operator)
	TEST_ASSERT(!first_line.is_running(), "Без питания конвейер работает")
	for(var/obj/machinery/porta_turret/syndicate/energy/hk_factory/turret as anything in turrets)
		TEST_ASSERT(turret.machine_stat & NOPOWER, "Без питания турель цеха работает")
	TEST_ASSERT_EQUAL(console.icon_state, "factory_console_nopower", "Пульт без питания светится")
	TEST_ASSERT(factory.protocol_active, "Рубильник при людях в цехе не включил автономный протокол")
	TEST_ASSERT_EQUAL(factory.protocol_turf, get_turf(apc), "Автономный протокол зовёт стражу не к щитовой")
	TEST_ASSERT_EQUAL(patrol.ai_controller.blackboard[BB_AI_LAST_KNOWN_POS], get_turf(apc), "Патрульный не пошёл к щитовой")
	apc.toggle_breaker(operator)
	TEST_ASSERT(first_line.is_running(), "Конвейер не ожил с питанием")

/datum/unit_test/hk_factory_ruin/Destroy()
	if(factory)
		hk_factory_test_reset(factory)
	factory = null
	QDEL_LIST(landmarks)
	QDEL_NULL(placement)
	QDEL_NULL(round_factory_stand_in)
	return ..()

/// Голос HK-50: свой файл на каждую строку, одна строка на всю стаю уровня за кулдаун, обязательные звучат всегда.
/datum/unit_test/hk50_voice_lines

/datum/unit_test/hk50_voice_lines/Run()
	var/list/expected = list("hk50_selfdestruct", "hk50_photoreceptors", "hk50_foolish", "hk50_numbers_grow")
	var/mob/living/simple_animal/hostile/hk50/droid = allocate(/mob/living/simple_animal/hostile/hk50)
	TEST_ASSERT_EQUAL(length(droid.voice_lines), length(expected), "Число голосовых строк HK-50")
	for(var/key in expected)
		var/voice = droid.voice_lines[key]
		TEST_ASSERT(isfile(voice), "[key] без звука")
		TEST_ASSERT_EQUAL("[voice]", "modular_bluemoon/sound/hk_droids/[key].ogg", "[key] играет чужой файл")

	var/level = "[droid.z]"
	var/mob/living/simple_animal/hostile/hk50/packmate = allocate(/mob/living/simple_animal/hostile/hk50)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	GLOB.hk50_voice_quiet_until -= level
	droid.GiveTarget(victim)
	TEST_ASSERT(GLOB.hk50_voice_quiet_until[level] > world.time, "Захват цели HK-50 не озвучен")
	TEST_ASSERT(!packmate.hk50_voice("hk50_foolish"), "Стая HK-50 звучит хором")
	TEST_ASSERT(packmate.hk50_voice("hk50_photoreceptors", forced = TRUE), "Обязательная строка HK-50 упёрлась в кулдаун")
	GLOB.hk50_voice_quiet_until -= level
	TEST_ASSERT(packmate.hk50_voice("hk50_foolish"), "Голос HK-50 не вернулся после кулдауна")
	GLOB.hk50_voice_quiet_until -= level
