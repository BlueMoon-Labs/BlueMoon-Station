/// Клетка, куда блоб гарантированно растёт кликом: открытая дверь или пожарная заслонка от удара блоба становится плотной рамой и перекрывает проход.
/datum/unit_test/proc/antag_training_blob_open_floor(turf/open/tile)
	return istype(tile) && !isspaceturf(tile) && !tile.is_blocked_turf(exclude_mobs = FALSE) && !(locate(/obj/machinery/door) in tile)

/// Клетки макета без дверей и препятствий, связные с start, в порядке обхода в ширину.
/datum/unit_test/proc/antag_training_blob_region(turf/start, datum/antag_training_sector/sector, limit)
	var/list/region = list(start)
	var/index = 1
	while(index <= length(region) && length(region) < limit)
		var/turf/current = region[index++]
		for(var/direction in GLOB.cardinals)
			var/turf/open/next = get_step(current, direction)
			if(!(next in region) && (next in sector.turfs) && antag_training_blob_open_floor(next))
				region += next
	return region

/// Клетка макета, от которой блоб дорастает до size клеток без дверей.
/datum/unit_test/proc/antag_training_blob_room(datum/antag_training_sector/sector, size)
	var/list/checked = list()
	for(var/turf/open/floor in sector.turfs)
		if((floor in checked) || !antag_training_blob_open_floor(floor))
			continue
		var/list/region = antag_training_blob_region(floor, sector, size)
		if(length(region) >= size)
			return floor
		checked += region

/// Разум учебного блоба в загруженном станционном макете.
/datum/unit_test/proc/antag_training_blob_session()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/creature/blob)
	if(!session.prepare())
		return null
	var/datum/antag_training_sector/sector = session.arena.sectors["station"]
	if(!wait_for_var(sector, "state", ANTAG_TRAINING_SECTOR_READY, 30 SECONDS))
		return null
	var/list/budget = new_wait_budget(10 SECONDS, "разум блоба в макете")
	while(!session.arena.inside_bounds(get_turf(session.current_body), sector.bounds) && wait_budget_tick(budget))
		continue
	return session

/// Учебный блоб ставит ядро штатно, растёт кликами только по макету до учебной критической массы и останавливается, не трогая тревогу, конец раунда, шаттл и станцию.
/datum/unit_test/antag_training_blob_critical_mass/Run()
	var/security_before = GLOB.security_level
	var/force_ending_before = SSticker.force_ending
	var/datum/antag_training_session/session = antag_training_blob_session()
	TEST_ASSERT_NOTNULL(session, "Полигон готовит разум блоба в станционном макете.")
	var/datum/antag_training_arena/arena = session.arena
	var/datum/antag_training_sector/sector = arena.sectors["station"]
	var/mob/camera/blob/training/overmind = session.current_body
	TEST_ASSERT(istype(overmind), "Тело сеанса - учебный разум блоба.")
	TEST_ASSERT_EQUAL(overmind.training_origin?.resolve(), arena, "Разум блоба принадлежит полигону.")
	TEST_ASSERT(!(overmind in SSshuttle.hostileEnvironments), "Учебный разум не держит эвакуационный шаттл.")
	TEST_ASSERT(arena.inside_bounds(get_turf(overmind), sector.bounds), "Программа ставит разум в станционный макет.")

	overmind.forceMove(arena.entry_turf)
	TEST_ASSERT(!overmind.place_blob_core(0) && !overmind.blob_core, "Вне макета ядро не ставится.")
	var/turf/core_turf = antag_training_blob_room(sector, ANTAG_TRAINING_BLOB_TILES + 5)
	TEST_ASSERT_NOTNULL(core_turf, "В макете есть место для роста до порога.")
	overmind.forceMove(core_turf)
	TEST_ASSERT(overmind.place_blob_core(0), "Ядро ставится в макете сразу.")
	var/obj/structure/blob/core/training/core = overmind.blob_core
	TEST_ASSERT(istype(core) && get_turf(core) == core_turf, "Ставится учебное ядро под разумом.")
	TEST_ASSERT_NULL(core.GetComponent(/datum/component/stationloving), "Учебное ядро не тянется на станцию.")
	TEST_ASSERT(!(overmind in overmind.blobs_legit), "Критическая масса считает только клетки блоба.")

	var/turf/hub_spot = get_step(arena.entry_turf, EAST)
	var/obj/structure/blob/normal/stray = new(arena.entry_turf, overmind)
	overmind.last_attack = 0
	overmind.ClickOn(hub_spot, "")
	TEST_ASSERT(!(locate(/obj/structure/blob) in hub_spot), "Блоб не захватывает клетки вне макета.")
	qdel(stray)

	var/list/region = antag_training_blob_region(core_turf, sector, ANTAG_TRAINING_BLOB_TILES + 5)
	var/datum/tgui/console = allocate(/datum/tgui, overmind, session, "AntagTraining")
	GLOB.unit_test_chat_capture = list()
	for(var/turf/spot as anything in region)
		if(length(overmind.blobs_legit) >= overmind.blobwincount)
			break
		if(overmind.blob_points < BLOB_SPREAD_COST)
			antag_training_console_act(session, console, "program_option", list("option" = "Ресурсы до максимума"))
		overmind.last_attack = 0
		overmind.ClickOn(spot, "")
	TEST_ASSERT(length(overmind.blobs_legit) >= ANTAG_TRAINING_BLOB_TILES, "Клики по соседним клеткам растят блоб до порога.")
	var/list/budget = new_wait_budget(10 SECONDS, "учебная критическая масса")
	while(!overmind.victory_in_progress && wait_budget_tick(budget))
		continue
	var/announced = antag_training_chat_heard(overmind, "Учебная критическая масса")
	GLOB.unit_test_chat_capture = null
	TEST_ASSERT(overmind.victory_in_progress && announced, "Разум блоба узнаёт об учебной критической массе.")
	var/datum/antag_training_program/creature/blob/program = session.program
	var/datum/antagonist/blob/training/role = program.role(session)
	var/datum/objective/blob_takeover/goal = locate() in role?.objectives
	TEST_ASSERT(goal?.completed, "Учебная цель засчитана.")

	TEST_ASSERT_EQUAL(GLOB.security_level, security_before, "Уровень тревоги станции не меняется.")
	TEST_ASSERT_EQUAL(SSticker.force_ending, force_ending_before, "Раунд не завершается.")
	TEST_ASSERT(SSticker.news_report != BLOB_WIN, "Победа станционного блоба не объявлена.")
	TEST_ASSERT(overmind.max_blob_points != INFINITY && overmind.blob_points != INFINITY, "Ресурсы не становятся бесконечными, как перед станционной победой.")
	for(var/obj/structure/blob/blob as anything in GLOB.blobs)
		TEST_ASSERT(!is_station_level(blob.z), "Блоб [blob] не появляется на станции.")
	for(var/obj/structure/blob/blob as anything in overmind.blobs_legit)
		TEST_ASSERT(overmind.is_valid_turf(get_turf(blob)), "Блоб [blob] остаётся в макете.")

	var/mass = length(overmind.blobs_legit)
	var/turf/frontier
	for(var/turf/spot as anything in region)
		if(!(locate(/obj/structure/blob) in spot))
			frontier = spot
			break
	TEST_ASSERT_NOTNULL(frontier, "За порогом остаются свободные клетки.")
	overmind.add_points(overmind.max_blob_points)
	overmind.last_attack = 0
	overmind.ClickOn(frontier, "")
	core.Pulse_Area(overmind, 12, 4, 3)
	TEST_ASSERT_EQUAL(length(overmind.blobs_legit), mass, "На учебной критической массе блоб больше не растёт.")

	var/obj/structure/blob/normal/trimmed = locate() in overmind.blobs_legit
	var/turf/trimmed_turf = get_turf(trimmed)
	GLOB.unit_test_chat_capture = list()
	overmind.add_points(-overmind.max_blob_points)
	overmind.AltClickOn(trimmed_turf)
	overmind.process()
	TEST_ASSERT(length(overmind.blobs_legit) < overmind.blobwincount, "Снятая клетка опускает блоб ниже порога.")
	overmind.add_points(overmind.max_blob_points)
	overmind.last_attack = 0
	overmind.ClickOn(trimmed_turf, "")
	overmind.process()
	var/repeats = 0
	for(var/list/entry as anything in GLOB.unit_test_chat_capture)
		if(findtext(entry[2], "Учебная критическая масса"))
			repeats++
	GLOB.unit_test_chat_capture = null
	TEST_ASSERT(length(overmind.blobs_legit) >= overmind.blobwincount && !repeats, "Повторный выход на порог не повторяет учебную победу.")

	qdel(session)
	TEST_ASSERT(wait_for_qdeleted(core, 10 SECONDS), "Ядро убирается вместе с сеансом.")

/// Кнопки «Моей роли», восстановление ядра без потери блоба, споры и блобберноут в лимите целей, телепатия и переход к узлам только в пределах полигона.
/datum/unit_test/antag_training_blob_kit/Run()
	var/datum/antag_training_session/session = antag_training_blob_session()
	TEST_ASSERT_NOTNULL(session, "Полигон готовит разум блоба в станционном макете.")
	var/datum/antag_training_arena/arena = session.arena
	var/datum/antag_training_sector/sector = arena.sectors["station"]
	var/datum/antag_training_program/creature/blob/program = session.program
	var/mob/camera/blob/training/overmind = session.current_body
	for(var/option in program.options)
		TEST_ASSERT(length(program.option_hints[option]), "У кнопки «[option]» есть подсказка.")
	var/turf/core_turf = antag_training_blob_room(sector, 20)
	overmind.forceMove(core_turf)
	TEST_ASSERT(overmind.place_blob_core(0), "Ядро ставится в макете.")
	var/obj/structure/blob/core/training/core = overmind.blob_core
	var/datum/tgui/console = allocate(/datum/tgui, overmind, session, "AntagTraining")

	overmind.add_points(-overmind.max_blob_points)
	antag_training_console_act(session, console, "program_option", list("option" = "Ресурсы до максимума"))
	TEST_ASSERT_EQUAL(overmind.blob_points, overmind.max_blob_points, "Кнопка восполняет ресурсы до предела.")
	GLOB.unit_test_chat_capture = list()
	antag_training_console_act(session, console, "program_option", list("option" = "Учебная победа: показать порог"))
	TEST_ASSERT(antag_training_chat_heard(overmind, "из [ANTAG_TRAINING_BLOB_TILES] клеток"), "Кнопка порога называет счёт до учебной критической массы.")

	var/list/region = antag_training_blob_region(core_turf, sector, 20)
	for(var/turf/spot as anything in region)
		overmind.last_attack = 0
		overmind.ClickOn(spot, "")
	var/points = overmind.blob_points
	var/blob_mass = length(overmind.blobs_legit)
	core.take_damage(core.max_integrity / 2, BRUTE, 0, FALSE)
	session.next_heal_at = 0
	antag_training_console_act(session, console, "heal", list())
	TEST_ASSERT(session.current_body == overmind && overmind.blob_core == core, "Восстановление не пересоздаёт разум и не теряет ядро.")
	TEST_ASSERT(abs(core.obj_integrity - core.max_integrity) < 0.1, "Восстановление чинит ядро до полной прочности.")
	TEST_ASSERT(abs(overmind.blob_points - points) < 0.1 && length(overmind.blobs_legit) == blob_mass, "Ресурсы и клетки блоба после восстановления на месте.")

	overmind.set_strain(/datum/blobstrain/reagent/zombifying_pods)
	TEST_ASSERT(!istype(overmind.blobstrain, /datum/blobstrain/reagent/zombifying_pods), "Зомбирующих стручков у учебного блоба нет.")
	for(var/datum/blobstrain/strain as anything in antag_training_blob_strains())
		TEST_ASSERT(length(antag_training_blob_strain_name(strain)), "У штамма [strain] есть имя в выборе.")

	overmind.add_points(overmind.max_blob_points)
	var/obj/structure/blob/normal/factory_spot = locate() in orange(2, core)
	TEST_ASSERT_NOTNULL(factory_spot, "Рядом с ядром выросла обычная клетка.")
	var/turf/factory_turf = get_turf(factory_spot)
	overmind.forceMove(factory_turf)
	overmind.create_factory()
	var/obj/structure/blob/factory/training/factory = locate() in factory_turf
	TEST_ASSERT_NOTNULL(factory, "Разум ставит учебную фабрику.")
	factory.Be_Pulsed()
	var/mob/living/simple_animal/hostile/blob/blobspore/training/spore = locate() in factory.spores
	TEST_ASSERT(spore && (spore in arena.targets) && spore.training_owner?.resolve() == session && (spore in overmind.blob_mobs), "Фабрика выпускает учебную спору в лимите целей полигона.")

	overmind.create_blobbernaut()
	var/mob/living/simple_animal/hostile/blob/blobbernaut/blobber = factory.naut
	TEST_ASSERT(istype(blobber) && !blobber.key && (blobber in arena.targets) && (blobber in overmind.blob_mobs), "Блобберноут вырастает сразу, без опроса призраков, и встаёт в лимит целей.")
	TEST_ASSERT_EQUAL(blobber.training_origin?.resolve(), arena, "Блобберноут принадлежит полигону.")

	var/datum/antag_training_session/visitor = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(visitor.prepare(arena), "Второй участник входит на тот же полигон.")
	var/mob/living/carbon/human/visitor_body = visitor.current_body
	visitor_body.forceMove(get_turf(spore))
	spore.Zombify(visitor_body)
	TEST_ASSERT(!spore.is_zombie && get_turf(visitor_body) == get_turf(spore) && visitor_body.loc != spore, "Спора не забирает тело участника.")
	var/mob/living/carbon/human/corpse = arena.spawn_creature("corpse", "station", FALSE, session, get_turf(spore))
	TEST_ASSERT_NOTNULL(corpse, "Учебный труп появляется в макете.")
	spore.Zombify(corpse)
	TEST_ASSERT(spore.is_zombie && corpse.loc == spore, "Учебный труп спора поднимает.")

	var/mob/camera/blob/station_mind = allocate(/mob/camera/blob, run_loc_floor_bottom_left)
	var/obj/structure/blob/node/station_node = allocate(/obj/structure/blob/node, run_loc_floor_bottom_left)
	GLOB.unit_test_chat_capture = list()
	overmind.say("учебный зов")
	station_mind.say("станционный зов")
	var/own_heard = antag_training_chat_heard(overmind, "учебный зов")
	var/leaked_out = antag_training_chat_heard(station_mind, "учебный зов")
	var/leaked_in = antag_training_chat_heard(overmind, "станционный зов")
	GLOB.unit_test_chat_capture = null
	TEST_ASSERT(own_heard && !leaked_out && !leaked_in, "Телепатия блоба не связывает полигон со станцией.")
	var/obj/structure/blob/normal/node_spot = locate() in overmind.blobs_legit
	var/turf/node_turf = get_turf(node_spot)
	overmind.forceMove(node_turf)
	overmind.create_node()
	var/obj/structure/blob/node/training_node = locate() in node_turf
	TEST_ASSERT_NOTNULL(training_node, "Разум ставит узел.")
	var/list/own_nodes = overmind.node_choices()
	var/list/station_nodes = station_mind.node_choices()
	var/own_offered = FALSE
	for(var/node_name in own_nodes)
		if(own_nodes[node_name] == training_node)
			own_offered = TRUE
		TEST_ASSERT(own_nodes[node_name] != station_node, "Переход к узлам полигона не предлагает узел станции.")
	TEST_ASSERT(own_offered, "Переход к узлам предлагает свой узел.")
	for(var/node_name in station_nodes)
		TEST_ASSERT(station_nodes[node_name] != training_node, "Переход к узлам станции не предлагает узел полигона.")

	while(arena.has_target_room())
		if(!arena.spawn_creature("human", "melee", FALSE, session))
			break
	TEST_ASSERT(!arena.has_target_room(), "Лимит целей полигона заполнен.")
	qdel(spore)
	factory.spore_delay = 0
	factory.Be_Pulsed()
	TEST_ASSERT(!length(factory.spores), "При заполненном лимите целей фабрика спор не выпускает.")

	qdel(session)
	TEST_ASSERT(wait_for_qdeleted(core, 10 SECONDS), "Ядро убирается вместе с сеансом.")
	TEST_ASSERT(QDELETED(factory) && QDELETED(blobber) && QDELETED(training_node), "Фабрика, блобберноут и узел убираются вместе с разумом.")

/// Учебный блоб с ядром в просторном месте макета и выросшими вокруг клетками.
/datum/unit_test/proc/antag_training_blob_grown(datum/antag_training_session/session, size)
	var/mob/camera/blob/training/overmind = session.current_body
	var/datum/antag_training_sector/sector = session.arena.sectors["station"]
	var/turf/core_turf = antag_training_blob_room(sector, size)
	overmind.forceMove(core_turf)
	if(!overmind.place_blob_core(0))
		return null
	for(var/turf/spot as anything in antag_training_blob_region(core_turf, sector, size))
		overmind.add_points(overmind.max_blob_points)
		overmind.last_attack = 0
		overmind.ClickOn(spot, "")
	return overmind.blob_core

/// Учебная фабрика рядом с ядром.
/datum/unit_test/proc/antag_training_blob_factory(mob/camera/blob/training/overmind)
	overmind.add_points(overmind.max_blob_points)
	var/obj/structure/blob/normal/factory_spot = locate() in orange(2, overmind.blob_core)
	var/turf/factory_turf = get_turf(factory_spot)
	overmind.forceMove(factory_turf)
	overmind.create_factory()
	return locate(/obj/structure/blob/factory/training) in factory_turf

/// Удаление блобберноута и удаление или лечение трупа внутри споры с пульта не оставляют ссылок на удалённое и живую цель внутри споры.
/datum/unit_test/antag_training_blob_console_targets/Run()
	var/datum/antag_training_session/session = antag_training_blob_session()
	TEST_ASSERT_NOTNULL(session, "Полигон готовит разум блоба в станционном макете.")
	var/datum/antag_training_arena/arena = session.arena
	var/mob/camera/blob/training/overmind = session.current_body
	TEST_ASSERT_NOTNULL(antag_training_blob_grown(session, 20), "Ядро стоит, блоб вырос.")
	var/obj/structure/blob/factory/training/factory = antag_training_blob_factory(overmind)
	TEST_ASSERT_NOTNULL(factory, "Разум ставит учебную фабрику.")
	var/datum/tgui/console = allocate(/datum/tgui, overmind, session, "AntagTraining")

	overmind.create_blobbernaut()
	var/mob/living/simple_animal/hostile/blob/blobbernaut/blobber = factory.naut
	TEST_ASSERT(istype(blobber) && factory.max_integrity < initial(factory.max_integrity), "Фабрика растит блобберноута и слабеет.")
	antag_training_console_act(session, console, "target_delete", list("id" = REF(blobber)))
	TEST_ASSERT(QDELETED(blobber), "Пульт удаляет блобберноута.")
	TEST_ASSERT(!factory.naut && factory.max_integrity == initial(factory.max_integrity), "Фабрика без удалённого блобберноута возвращает прочность и не держит его.")
	factory.Be_Pulsed()
	var/mob/living/simple_animal/hostile/blob/blobspore/training/spore = locate() in factory.spores
	TEST_ASSERT_NOTNULL(spore, "Освобождённая фабрика снова выпускает споры.")

	var/mob/living/carbon/human/corpse = arena.spawn_creature("corpse", "station", FALSE, session, get_turf(spore))
	TEST_ASSERT_NOTNULL(corpse, "Учебный труп появляется в макете.")
	spore.Zombify(corpse)
	TEST_ASSERT(corpse.loc == spore, "Спора поднимает учебный труп.")
	antag_training_console_act(session, console, "target_heal", list("id" = REF(corpse)))
	TEST_ASSERT(corpse.stat != DEAD && isturf(corpse.loc) && QDELETED(spore), "Вылеченная цель выходит из споры, спора распадается.")

	factory.spore_delay = 0
	factory.Be_Pulsed()
	var/mob/living/simple_animal/hostile/blob/blobspore/training/second_spore = locate() in factory.spores
	TEST_ASSERT_NOTNULL(second_spore, "Фабрика выпускает новую спору.")
	var/mob/living/carbon/human/second_corpse = arena.spawn_creature("corpse", "station", FALSE, session, get_turf(second_spore))
	TEST_ASSERT_NOTNULL(second_corpse, "Второй учебный труп появляется в макете.")
	second_spore.Zombify(second_corpse)
	TEST_ASSERT(second_corpse.loc == second_spore, "Спора поднимает второй труп.")
	antag_training_console_act(session, console, "target_delete", list("id" = REF(second_corpse)))
	TEST_ASSERT(QDELETED(second_corpse) && wait_for_qdeleted(second_spore) && !length(factory.spores), "Удалённый труп уносит с собой спору.")

/// Разрушенное ядро уносит прежний блоб, новый разум появляется в макете с одним верным сообщением, а выбор штамма не предлагает зомбирующих стручков.
/datum/unit_test/antag_training_blob_rebirth/Run()
	var/datum/antag_training_session/session = antag_training_blob_session()
	TEST_ASSERT_NOTNULL(session, "Полигон готовит разум блоба в станционном макете.")
	var/datum/antag_training_arena/arena = session.arena
	var/datum/antag_training_sector/sector = arena.sectors["station"]
	var/mob/camera/blob/training/overmind = session.current_body
	var/obj/structure/blob/core/training/core = antag_training_blob_grown(session, 12)
	TEST_ASSERT_NOTNULL(core, "Ядро стоит, блоб вырос.")
	var/list/old_blob = overmind.blobs_legit.Copy()
	TEST_ASSERT(length(old_blob) > 1, "У прежнего разума есть клетки блоба.")

	GLOB.unit_test_chat_capture = list()
	core.take_damage(core.max_integrity * 10, BRUTE, 0, FALSE)
	TEST_ASSERT(QDELETED(core), "Ядро разрушается уроном.")
	var/reborn = antag_training_wait_new_body(session, overmind, "новый разум блоба")
	var/list/messages = list()
	for(var/list/entry as anything in GLOB.unit_test_chat_capture)
		if(findtext(entry[2], "новым телом") || findtext(entry[2], "Новый разум"))
			messages += entry[2]
	GLOB.unit_test_chat_capture = null
	TEST_ASSERT(reborn, "После разрушения ядра появляется новый разум.")
	var/mob/camera/blob/training/fresh = session.current_body
	TEST_ASSERT(istype(fresh) && QDELETED(overmind) && fresh.mind == session.avatar_mind && !fresh.placed, "Новый разум без ядра получает разум участника.")
	TEST_ASSERT(arena.inside_bounds(get_turf(fresh), sector.bounds), "Новый разум появляется в станционном макете.")
	for(var/obj/structure/blob/remains as anything in old_blob)
		TEST_ASSERT(QDELETED(remains), "Клетка прежнего блоба [remains] убрана.")
	TEST_ASSERT(length(messages) == 1 && findtext(messages[1], "в станционном макете"), "Одно сообщение о новом разуме называет макет: [jointext(messages, " | ")]")

	for(var/attempt in 1 to 20)
		var/list/offered = fresh.strain_choices(4)
		TEST_ASSERT_EQUAL(length(offered), 4, "Смена штамма предлагает четыре штамма.")
		for(var/strain_name in offered)
			TEST_ASSERT(!ispath(offered[strain_name], /datum/blobstrain/reagent/zombifying_pods), "Смена штамма не предлагает зомбирующих стручков.")
	var/list/everything = fresh.strain_choices()
	TEST_ASSERT_EQUAL(length(everything), length(antag_training_blob_strains()), "Выбор в пульте называет каждый учебный штамм.")
	for(var/strain_name in everything)
		TEST_ASSERT(ispath(everything[strain_name], /datum/blobstrain) && !ispath(everything[strain_name], /datum/blobstrain/reagent/zombifying_pods), "Пункт «[strain_name]» ведёт к учебному штамму.")
	var/datum/tgui/console = allocate(/datum/tgui, fresh, session, "AntagTraining")
	antag_training_console_act(session, console, "program_option", list("option" = "Сменить штамм"))
	fresh.strain_reroll()
	TEST_ASSERT(!fresh.rerolling, "Без окна выбора смена штамма не зависает.")

/datum/unit_test/antag_training_blob_rebirth/Destroy()
	GLOB.unit_test_chat_capture = null
	return ..()

/datum/unit_test/antag_training_blob_critical_mass/Destroy()
	GLOB.unit_test_chat_capture = null
	return ..()

/datum/unit_test/antag_training_blob_kit/Destroy()
	GLOB.unit_test_chat_capture = null
	return ..()
