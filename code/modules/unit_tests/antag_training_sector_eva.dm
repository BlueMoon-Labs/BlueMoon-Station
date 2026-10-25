#define EVA_TEST_LOCKERS 4
#define EVA_TEST_MIN_LANE 8
#define EVA_TEST_STILL_TICKS 5
#define EVA_TEST_AIRLOCKS 4
#define EVA_TEST_VACUUM_KPA 1

/// В секторе EVA нет гравитации и воздуха снаружи, шкафы с комплектами и мебель закреплены, шлюзы связаны, а брошенное тело дрейфует до стены сектора.
/datum/unit_test/antag_training_sector_eva/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_sector/sector = session.arena.sectors["eva"]
	TEST_ASSERT_NOTNULL(sector, "Арена знает сектор EVA.")
	TEST_ASSERT(sector.load(), "Сектор загружается.")
	var/mob/living/carbon/human/body = session.current_body
	TEST_ASSERT(body.has_gravity(), "В ядре есть гравитация.")
	var/list/bounds = sector.bounds
	for(var/turf/tile as anything in sector.turfs)
		if(tile.x == bounds[1] || tile.x == bounds[2] || tile.y == bounds[3] || tile.y == bounds[4])
			TEST_ASSERT(isclosedturf(tile), "Край сектора закрыт: [tile.x],[tile.y].")

	var/turf/entry = sector.spawn_turf()
	var/entry_pressure = entry.return_air().return_pressure()
	TEST_ASSERT(entry_pressure > WARNING_LOW_PRESSURE && entry_pressure < WARNING_HIGH_PRESSURE, "В комнате снаряжения нормальное давление, а не [entry_pressure] кПа.")
	body.forceMove(entry)
	TEST_ASSERT(!body.has_gravity(), "В комнате снаряжения нет гравитации.")
	var/turf/target = sector.target_turf()
	var/target_pressure = target.return_air().return_pressure()
	TEST_ASSERT(target_pressure > WARNING_LOW_PRESSURE && target_pressure < WARNING_HIGH_PRESSURE, "У точки целей есть воздух, а не [target_pressure] кПа.")

	var/lockers = 0
	var/airlocks = 0
	var/list/loose = list()
	for(var/turf/tile as anything in sector.turfs)
		for(var/obj/structure/closet/antag_training_eva/locker in tile)
			lockers++
			TEST_ASSERT(locker.anchored, "Шкаф EVA закреплён: в невесомости от него отталкиваются.")
			for(var/kit_part in list(/obj/item/clothing/suit/space, /obj/item/clothing/head/helmet/space, /obj/item/tank/jetpack/oxygen, /obj/item/clothing/shoes/magboots))
				TEST_ASSERT(locate(kit_part) in locker, "В шкафу EVA есть [kit_part].")
		for(var/obj/machinery/door/airlock/airlock in tile)
			airlocks++
			TEST_ASSERT(airlock.cyclelinkedairlock?.cyclelinkedairlock == airlock, "Шлюз [airlock.x],[airlock.y] связан со второй дверью камеры.")
		if(isfloorturf(tile) && !istype(tile, /turf/open/floor/plating/asteroid))
			for(var/obj/structure/thing in tile)
				if(thing.density && !thing.anchored)
					loose += "[thing.type] ([thing.x],[thing.y])"
	TEST_ASSERT_EQUAL(lockers, EVA_TEST_LOCKERS, "Шкафов EVA по числу комплектов.")
	TEST_ASSERT_EQUAL(airlocks, EVA_TEST_AIRLOCKS, "Двери двух шлюзовых камер на месте.")
	TEST_ASSERT(!length(loose), "Мебель на полу сектора закреплена: [loose.Join(", ")].")

	var/turf/open/space/start = eva_drift_start(sector)
	TEST_ASSERT_NOTNULL(start, "В секторе есть чистая полоса космоса до восточной стены.")
	TEST_ASSERT(start.return_air().return_pressure() < EVA_TEST_VACUUM_KPA, "В космосе сектора нет воздуха.")
	body.forceMove(start)
	TEST_ASSERT(!body.has_gravity(), "В космосе сектора нет гравитации.")
	TEST_ASSERT(!body.mob_negates_gravity(), "Тело без магнитных ботинок.")
	body.throw_at(locate(bounds[2], start.y, start.z), 1, 1)
	var/list/budget = new_wait_budget(20 SECONDS, "дрейф до стены сектора")
	var/still_ticks = 0
	while(still_ticks < EVA_TEST_STILL_TICKS && wait_budget_tick(budget))
		TEST_ASSERT(sector.arena.inside_bounds(get_turf(body), bounds), "Дрейф не выносит тело из сектора.")
		still_ticks = (body.throwing || body.inertia_dir || (body in SSspacedrift.processing)) ? 0 : still_ticks + 1
	TEST_ASSERT_EQUAL(still_ticks, EVA_TEST_STILL_TICKS, "Дрейф кончился.")
	TEST_ASSERT_EQUAL(body.y, start.y, "Тело летит по прямой.")
	TEST_ASSERT_EQUAL(body.x, bounds[2] - 1, "Брошенное на клетку тело долетает по инерции до стены сектора.")

/// Клетка, от которой до восточной стены сектора полоса в три ряда пустого космоса без опор.
/datum/unit_test/antag_training_sector_eva/proc/eva_drift_start(datum/antag_training_sector/sector)
	var/list/bounds = sector.bounds
	var/level = sector.arena.private_level.z_value
	for(var/lane_y in bounds[3] + 2 to bounds[4] - 2)
		var/clear = 0
		for(var/lane_x in bounds[2] - 1 to bounds[1] + 1 step -1)
			if(!eva_clear_column(lane_x, lane_y, level))
				break
			clear++
		if(clear >= EVA_TEST_MIN_LANE)
			return locate(bounds[2] - clear + 1, lane_y, level)

/datum/unit_test/antag_training_sector_eva/proc/eva_clear_column(lane_x, lane_y, level)
	for(var/offset in -1 to 1)
		var/turf/tile = locate(lane_x, lane_y + offset, level)
		if(!isspaceturf(tile) || (locate(/obj) in tile) || (locate(/mob) in tile))
			return FALSE
	return TRUE

#undef EVA_TEST_LOCKERS
#undef EVA_TEST_MIN_LANE
#undef EVA_TEST_STILL_TICKS
#undef EVA_TEST_AIRLOCKS
#undef EVA_TEST_VACUUM_KPA
