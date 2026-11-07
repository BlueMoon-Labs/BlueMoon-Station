/// Ядро полигона - голограмма: пол центра, переходов и боевых зон не разбирается, но ржавеет, стены неразрушимые, пол лаборатории - плейтинг под кабель.
/datum/unit_test/antag_training_core_holo/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_arena/arena = session.arena
	var/level = arena.private_level.z_value
	TEST_ASSERT(istype(arena.zones["hub"]["spawn"], /turf/open/floor/holofloor), "Пол центра - голографический.")
	check_core_ground(arena, level)
	var/turf/open/floor/rusted = get_step(arena.zones["melee"]["spawn"], WEST)
	TEST_ASSERT(istype(rusted.rust_heretic_act(), /turf/open/floor/plating/rust), "Голографический пол ржавеет для практики пути Ржавчины.")
	TEST_ASSERT(arena.reset_zone("melee"), "Зона сбрасывается.")
	check_core_ground(arena, level)
	rusted = get_step(arena.zones["melee"]["spawn"], WEST)
	TEST_ASSERT_EQUAL(rusted.type, GLOB.antag_training_core_floors["melee"], "Сброс проецирует голографический пол на месте ржавчины.")

	var/mob/living/carbon/human/user = session.current_body
	var/turf/melee_floor = arena.zones["melee"]["spawn"]
	user.forceMove(melee_floor)
	var/obj/item/stack/cable_coil/coil = new(melee_floor)
	user.put_in_hands(coil)
	coil.melee_attack_chain(user, melee_floor)
	TEST_ASSERT_NULL(locate(/obj/structure/cable) in melee_floor, "На голографический пол кабель не ложится.")
	var/obj/item/crowbar/crowbar = new(melee_floor)
	user.dropItemToGround(coil)
	user.put_in_hands(crowbar)
	crowbar.melee_attack_chain(user, melee_floor)
	TEST_ASSERT_EQUAL(melee_floor.type, GLOB.antag_training_core_floors["melee"], "Голографический пол не разбирается ломом.")

	var/turf/laboratory_floor = arena.zones["laboratory"]["spawn"]
	user.forceMove(laboratory_floor)
	user.dropItemToGround(crowbar)
	user.put_in_hands(coil)
	coil.melee_attack_chain(user, laboratory_floor)
	TEST_ASSERT_NOTNULL(locate(/obj/structure/cable) in laboratory_floor, "В лаборатории кабель кладётся прямо на пол.")

/datum/unit_test/antag_training_core_holo/proc/check_core_ground(datum/antag_training_arena/arena, level)
	for(var/zone_id in list("hub", "melee", "range", "pve"))
		var/turf/spot = arena.zones[zone_id]["spawn"]
		TEST_ASSERT_EQUAL(spot.type, GLOB.antag_training_core_floors[zone_id], "Пол зоны [zone_id] - голограмма своего цвета.")
	var/turf/corridor = locate(28, 15, level)
	TEST_ASSERT_EQUAL(corridor.type, /turf/open/floor/holofloor/antag_training, "Пол перехода - голограмма.")
	var/list/melee_bounds = arena.zones["melee"]["bounds"]
	var/turf/door = locate(melee_bounds[2], round((melee_bounds[3] + melee_bounds[4]) / 2), level)
	TEST_ASSERT_EQUAL(door.type, /turf/open/floor/holofloor/antag_training, "Проход в зону - голограмма перехода.")
	var/turf/laboratory_floor = arena.zones["laboratory"]["spawn"]
	TEST_ASSERT(isplatingturf(laboratory_floor), "Пол лаборатории - плейтинг.")
	var/list/walls = list(locate(1, 1, level), locate(melee_bounds[1], melee_bounds[3] + 1, level), locate(40, 37, level))
	for(var/turf/wall as anything in walls)
		TEST_ASSERT_EQUAL(wall.type, /turf/closed/indestructible/antag_training, "Стена [wall.x],[wall.y] - голографическая и неразрушимая.")

/// Вкладка «Моя роль» знает, где тренировать программу: морфа - в сценарии и на пресете «Техи», «Снаряжение и бой» - в секторах механик.
/datum/unit_test/antag_training_console_route/Run()
	var/datum/antag_training_session/morph = allocate_training_session(/datum/antag_training_program/creature/morph)
	TEST_ASSERT(morph.prepare(), "Полигон готовится.")
	var/list/data = morph.ui_data(morph.current_body)
	var/list/route = data["route"]
	TEST_ASSERT(islist(route), "Пульт отдаёт маршрут программы.")
	var/list/scenario_ids = list()
	for(var/list/scenario as anything in route["scenarios"])
		scenario_ids += scenario["id"]
	TEST_ASSERT("morph_hunt" in scenario_ids, "Маршрут морфа ведёт в его сценарий: [json_encode(scenario_ids)].")
	var/list/preset_ids = list()
	for(var/list/preset as anything in route["presets"])
		preset_ids += preset["id"]
	TEST_ASSERT("maint" in preset_ids, "Маршрут морфа называет пресет «Техи»: [json_encode(preset_ids)].")
	TEST_ASSERT(!length(route["sectors"]), "У морфа нет своего сектора.")
	var/datum/antag_training_session/free = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(free.prepare(morph.arena), "Второй участник входит.")
	var/list/free_route = free.ui_data(free.current_body)["route"]
	var/list/sector_ids = list()
	for(var/list/sector as anything in free_route["sectors"])
		sector_ids += sector["id"]
	TEST_ASSERT_EQUAL(sector_ids.Join(","), GLOB.antag_training_mechanics_sectors.Join(","), "«Снаряжение и бой» ведут в сектора механик.")
	TEST_ASSERT(free_route["exercises_total"] > 0, "У «Снаряжения и боя» есть упражнения ядра.")
