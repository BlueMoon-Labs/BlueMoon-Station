/**
 * Тесты астрометрического сенсора.
 *
 * Проверяются три вещи, каждая из которых ломается тихо: гейт обзора (сенсор в шкафу
 * должен молчать, а сенсор у иллюминатора работать), петля усиления против нагрева
 * (без неё сенсор ставят на максимум и уходят) и потолок выдачи за явление.
 */

/// Гейт места: сенсор работает только там, откуда видно космос.
/datum/unit_test/astro_sensor_space_view/Run()
	var/turf/sensor_turf = run_loc_floor_bottom_left
	var/obj/machinery/astro_sensor/sensor = allocate(/obj/machinery/astro_sensor, sensor_turf)
	sensor.setDir(EAST)
	// Резервация теста - блок 5 на 5, и снаружи она граничит с космосом резервного z.
	// Штатная дальность в восемь тайлов уходит за её край и находит этот космос, поэтому
	// тарелке укорачивается обзор: проверяем логику трассировки, а не размер полигона.
	sensor.view_range = 3
	TEST_ASSERT(!sensor.has_space_view(), "Сенсор посреди пола отчитался об открытом обзоре")

	var/turf/space_turf = locate(sensor_turf.x + 3, sensor_turf.y, sensor_turf.z)
	TEST_ASSERT_NOTNULL(space_turf, "Резервация оказалась уже трёх тайлов - тесту негде развернуться")
	space_turf.ChangeTurf(/turf/open/space)
	TEST_ASSERT(sensor.has_space_view(), "Сенсор не увидел космос в трёх тайлах прямо по направлению наводки")

	// На север внутри резервации космоса нет: наводка обязана решать, куда смотрит тарелка.
	// Запад и юг тут не годятся - сенсор стоит в углу блока, и снаружи сразу космос.
	sensor.setDir(NORTH)
	TEST_ASSERT(!sensor.has_space_view(), "Сенсор видит космос не в ту сторону - направление наводки ни на что не влияет")
	sensor.setDir(EAST)

	var/turf/blocker_turf = locate(sensor_turf.x + 1, sensor_turf.y, sensor_turf.z)
	blocker_turf.ChangeTurf(/turf/closed/wall)
	TEST_ASSERT(!sensor.has_space_view(), "Стена между сенсором и космосом не перекрыла обзор")
	blocker_turf.ChangeTurf(/turf/open/floor/plasteel)

	// Иллюминатор держит воздух, но не взгляд: сквозь него сенсор обязан видеть.
	allocate(/obj/structure/window/reinforced/fulltile, blocker_turf)
	TEST_ASSERT(sensor.has_space_view(), "Иллюминатор перекрыл обзор, хотя сквозь него видно")

	space_turf.ChangeTurf(/turf/open/floor/plasteel)

/**
 * Петля усиления: на пике полное усиление сжигает приёмник, равновесное - нет.
 *
 * Если сжечь нельзя, сенсор выкручивают на максимум один раз и уходят, и никакого
 * решения в событии не остаётся.
 */
/datum/unit_test/astro_sensor_gain_burnout/Run()
	var/obj/machinery/astro_sensor/greedy = allocate(/obj/machinery/astro_sensor, run_loc_floor_bottom_left)
	greedy.gain = 1
	for(var/step in 1 to 30) // минута пика по два секунды на тик
		greedy.update_heat(1, 2)
	TEST_ASSERT(greedy.machine_stat & BROKEN, "Полное усиление на полной интенсивности не сожгло приёмник за минуту")
	TEST_ASSERT_EQUAL(greedy.gain, 0, "Выгоревший приёмник остался с усилением [greedy.gain]")

	// Замена приёмника возвращает сенсор в строй целиком: остаточный нагрев сжёг бы его
	// повторно через несколько секунд после ремонта.
	greedy.heat = 0
	greedy.set_machine_stat(greedy.machine_stat & ~BROKEN)
	greedy.gain = 0.25
	greedy.update_heat(1, 2)
	TEST_ASSERT(!(greedy.machine_stat & BROKEN), "Отремонтированный сенсор сгорел снова - нагрев не сбросили вместе с поломкой")

	var/obj/machinery/astro_sensor/careful = allocate(/obj/machinery/astro_sensor, run_loc_floor_top_right)
	careful.gain = 0.25
	for(var/step in 1 to 60)
		careful.update_heat(1, 2)
	TEST_ASSERT(!(careful.machine_stat & BROKEN), "Усиление ниже равновесного всё равно сожгло приёмник - держать сенсор нельзя вообще")

	// На подходе греться нечему: интенсивность мала, остывание перекрывает нагрев.
	var/obj/machinery/astro_sensor/approaching = allocate(/obj/machinery/astro_sensor, run_loc_floor_bottom_left)
	approaching.gain = 1
	for(var/step in 1 to 30)
		approaching.update_heat(PHENOMENON_APPROACH_TOP, 2)
	TEST_ASSERT(!(approaching.machine_stat & BROKEN), "Полное усиление сожгло приёмник ещё на подходе - готовиться было бы нечем")

/// Выдача: пик дороже подхода, потолок за явление связывает бесконечное наблюдение.
/datum/unit_test/astro_sensor_yield/Run()
	var/datum/round_event/space_weather/phenomenon = unit_test_detached_phenomenon(/datum/round_event/space_weather/graveyard)
	var/points_before = SSresearch.science_tech.research_points[TECHWEB_POINT_TYPE_GENERIC] || 0

	var/obj/machinery/astro_sensor/at_peak = allocate(/obj/machinery/astro_sensor, run_loc_floor_bottom_left)
	at_peak.gain = 1
	at_peak.collect_data(phenomenon, 1, 2)
	var/obj/machinery/astro_sensor/at_approach = allocate(/obj/machinery/astro_sensor, run_loc_floor_top_right)
	at_approach.gain = 1
	at_approach.collect_data(phenomenon, PHENOMENON_APPROACH_TOP, 2)
	TEST_ASSERT(at_peak.collected > at_approach.collected, "Пик дал не больше подхода ([at_peak.collected] против [at_approach.collected]) - приходить вовремя незачем")

	// Долгое наблюдение на полной интенсивности упирается в потолок и не идёт дальше.
	for(var/step in 1 to 200)
		at_peak.collect_data(phenomenon, 1, 2)
	var/cap = at_peak.base_yield * phenomenon.sensor_yield_mult
	TEST_ASSERT_EQUAL(round(at_peak.yielded), round(cap), "Выдача за явление [round(at_peak.yielded)] разошлась с потолком [round(cap)]")

	var/points_after = SSresearch.science_tech.research_points[TECHWEB_POINT_TYPE_GENERIC] || 0
	TEST_ASSERT(points_after > points_before, "Собранные данные не доехали до техвеба")

	// Выгоревший приёмник не собирает ничего, даже если усиление осталось поднятым.
	var/obj/machinery/astro_sensor/burnt = allocate(/obj/machinery/astro_sensor, run_loc_floor_bottom_left)
	burnt.gain = 1
	burnt.obj_break()
	burnt.collect_data(phenomenon, 1, 2)
	TEST_ASSERT_EQUAL(burnt.collected, 0, "Сломанный сенсор всё равно собрал данные")

	// Тест не оставляет раунду подаренных очков.
	SSresearch.science_tech.remove_point_type(TECHWEB_POINT_TYPE_GENERIC, points_after - points_before)
	qdel(phenomenon)
