// Файрлок судит о воздухе по температуре соседнего турфа. Беда в том, что
// "холодно" бывает трёх разных сортов: аварийно остывшая комната, улица планеты
// или вакуум (холодны по устройству и теплее не станут) и целая комната,
// которую морозят НАМЕРЕННО - телекомы разложены при 80 K, холодильник кухни при
// 259 K. Первый сорт когда-то отсекали дверью, а два других защёлкивали её
// намертво: тревога не могла сняться, а без снятия тревоги ветка переоткрытия не
// выполняется вообще. Игроки видели это как "шторки закрылись и не открываются".
//
// Разбор простой: холод дверь больше не закрывает вообще, только светит лампой,
// и лампа считается от проектной температуры самого турфа.

/datum/unit_test/firelock_alarm_environment

/datum/unit_test/firelock_alarm_environment/Run()
	var/turf/open/probe = run_loc_floor_bottom_left
	TEST_ASSERT(istype(probe), "тестовой зоне нужен открытый турф под пробу")

	var/obj/machinery/door/firedoor/door = allocate(/obj/machinery/door/firedoor, probe)
	var/saved_planetary = probe.planetary_atmos
	var/saved_gas_mix = probe.initial_gas_mix
	// Без этой предпосылки вакуумный случай ниже мог бы пройти вхолостую: если
	// турф тестовой зоны сам окажется планетарным, тревогу снимет уличный гард,
	// а не проверка давления, и подмену было бы не отличить от успеха.
	TEST_ASSERT(!saved_planetary, "тестовой зоне нужен обычный, не планетарный турф")

	// Комната под нормальным давлением: один атмосферный набор молей на ячейку.
	var/datum/gas_mixture/room = new(CELL_VOLUME)
	room.set_moles(GAS_O2, MOLES_O2STANDARD)
	room.set_moles(GAS_N2, MOLES_N2STANDARD)

	// Ветка классификации помнит прошлый вердикт по турфу ради гистерезиса, так
	// что каждый случай начинается с чистого листа - иначе порядок проверок
	// начинает влиять на результат.
	reset_alarm(door)
	room.set_temperature(T20C)
	door.process_atmos_alarm(probe, room, room.return_temperature())
	TEST_ASSERT_NULL(door.alarm_type, "предпосылка: жилая комната при 20C не должна поднимать тревогу")

	// --- Холод светит лампой, но дверью не хлопает ---
	reset_alarm(door)
	room.set_temperature(FIRELOCK_COLD_ALARM_TEMPERATURE - 20)
	TEST_ASSERT(room.return_pressure() > WARNING_LOW_PRESSURE, "предпосылка: остывшая комната должна остаться под давлением")
	door.process_atmos_alarm(probe, room, room.return_temperature())
	TEST_ASSERT_EQUAL(door.alarm_type, FIRELOCK_ALARM_TYPE_COLD, "остывшая комната под давлением обязана зажигать холодную лампу")
	TEST_ASSERT(!door.firelock_alarm_seals(FIRELOCK_ALARM_TYPE_COLD), "холод снова закрывает дверь")
	TEST_ASSERT(door.firelock_alarm_seals(FIRELOCK_ALARM_TYPE_HOT), "жар перестал закрывать дверь")
	TEST_ASSERT(door.firelock_alarm_seals(FIRELOCK_ALARM_TYPE_GENERIC), "тревога зоны перестала закрывать дверь")

	// --- Просто прохладная комната лампу не зажигает ---
	// 240 K это ниже старого порога по телу человека и выше нового: ровно та
	// полоса, в которой лампа горела без всякого повода.
	reset_alarm(door)
	room.set_temperature(BODYTEMP_COLD_DAMAGE_LIMIT - 20)
	door.process_atmos_alarm(probe, room, room.return_temperature())
	TEST_ASSERT_NULL(door.alarm_type, "прохладная комната не должна зажигать холодную лампу")

	// --- Комната, которую морозят по проекту, молчит на своей же температуре ---
	reset_alarm(door)
	probe.initial_gas_mix = TCOMMS_ATMOS
	var/list/tcomms_design = SSair.get_parsed_gas_string(TCOMMS_ATMOS)
	var/tcomms_temperature = tcomms_design[GAS_STRING_TEMP]
	TEST_ASSERT(tcomms_temperature < FIRELOCK_COLD_ALARM_TEMPERATURE, "предпосылка: телекомы должны быть холоднее общего порога")
	var/datum/gas_mixture/tcomms = new(CELL_VOLUME)
	tcomms.set_temperature(tcomms_temperature)
	// Моли считаются от целевого давления, а не берутся стандартным набором:
	// при 80 K стандартный набор даёт 28 кПа, то есть почти вакуум, и проверку
	// снял бы гард низкого давления, а не то, что тестируется.
	tcomms.set_moles(GAS_N2, ONE_ATMOSPHERE * CELL_VOLUME / (R_IDEAL_GAS_EQUATION * tcomms_temperature))
	TEST_ASSERT(tcomms.return_pressure() > WARNING_LOW_PRESSURE, "предпосылка: телекомы должны остаться под давлением")
	door.process_atmos_alarm(probe, tcomms, tcomms.return_temperature())
	TEST_ASSERT_NULL(door.alarm_type, "турф, разложенный холодным, не должен светить лампой на своей проектной температуре")

	// А вот холоднее собственного проекта - уже повод.
	reset_alarm(door)
	tcomms.set_temperature(tcomms_temperature - FIRELOCK_ALARM_TEMPERATURE_HYSTERESIS - 10)
	door.process_atmos_alarm(probe, tcomms, tcomms.return_temperature())
	TEST_ASSERT_EQUAL(door.alarm_type, FIRELOCK_ALARM_TYPE_COLD, "турф, остывший ниже собственного проекта, обязан зажечь лампу")
	probe.initial_gas_mix = saved_gas_mix

	// --- Улица планеты: снег ледяной луны живёт при 180 K и не согреется ---
	reset_alarm(door)
	probe.planetary_atmos = TRUE
	var/datum/gas_mixture/outdoors = new(CELL_VOLUME)
	outdoors.set_moles(GAS_O2, 21.78)
	outdoors.set_moles(GAS_N2, 82.36)
	outdoors.set_temperature(180)
	door.process_atmos_alarm(probe, outdoors, outdoors.return_temperature())
	TEST_ASSERT_NULL(door.alarm_type, "уличный турф планеты не должен защёлкивать файрлок")
	probe.planetary_atmos = saved_planetary

	// --- Вакуум: у разрежённого газа температура ничего не значит ---
	reset_alarm(door)
	var/datum/gas_mixture/vacuum = new(CELL_VOLUME)
	vacuum.set_temperature(TCMB)
	TEST_ASSERT(vacuum.return_pressure() < WARNING_LOW_PRESSURE, "предпосылка: пустая смесь должна быть ниже порога низкого давления")
	door.process_atmos_alarm(probe, vacuum, vacuum.return_temperature())
	TEST_ASSERT_NULL(door.alarm_type, "разваканный турф не должен защёлкивать файрлок")

	// --- Жар обязан ловиться и сниматься ---
	reset_alarm(door)
	room.set_temperature(ATMOS_HEAT_ALARM_TEMPERATURE + 20)
	door.process_atmos_alarm(probe, room, room.return_temperature())
	TEST_ASSERT_EQUAL(door.alarm_type, FIRELOCK_ALARM_TYPE_HOT, "нагретая комната обязана поднимать горячую тревогу")
	room.set_temperature(T20C)
	door.process_atmos_alarm(probe, room, room.return_temperature())
	TEST_ASSERT_NULL(door.alarm_type, "остывшая обратно комната обязана снимать тревогу")

	probe.planetary_atmos = saved_planetary
	probe.initial_gas_mix = saved_gas_mix

/// Сбрасывает и накопленные вердикты по турфам, и текущий тип тревоги, чтобы
/// гистерезис прошлого случая не подменял пороги следующему.
/datum/unit_test/firelock_alarm_environment/proc/reset_alarm(obj/machinery/door/firedoor/door)
	door.issue_turfs = list()
	door.alarm_type = null

/// Провод детекции в пожарной сигнализации - единственный штатный способ снять
/// автоматику с комнаты, которую греют или морозят намеренно. Если он не доходит
/// до дверей, у экипажа не остаётся вообще никакого ответа на ложную тревогу.
/datum/unit_test/firelock_detection_wire

/datum/unit_test/firelock_detection_wire/Run()
	var/turf/open/probe = run_loc_floor_bottom_left

	// Сигнализация первой: зону берём ту, в которую записалась она сама, иначе
	// тест сверял бы флаг не с той зоной, что слушают двери.
	var/obj/machinery/firealarm/alarm = allocate(/obj/machinery/firealarm, probe)
	var/area/zone = alarm.myarea
	TEST_ASSERT_NOTNULL(zone, "сигнализация не нашла свою зону")
	var/obj/machinery/door/firedoor/door = allocate(/obj/machinery/door/firedoor, probe)
	TEST_ASSERT(alarm in zone.firealarms, "предпосылка: сигнализация должна числиться в зоне")
	TEST_ASSERT(zone in door.affecting_areas, "предпосылка: дверь должна слушать зону сигнализации")
	TEST_ASSERT(zone.fire_detect, "предпосылка: рабочая сигнализация обязана оставлять детекцию включённой")
	TEST_ASSERT(door.fire_detection, "предпосылка: дверь должна была снять включённую детекцию")

	var/datum/gas_mixture/blaze = new(CELL_VOLUME)
	blaze.set_moles(GAS_O2, MOLES_O2STANDARD)
	blaze.set_moles(GAS_N2, MOLES_N2STANDARD)
	blaze.set_temperature(ATMOS_HEAT_ALARM_TEMPERATURE + 50)

	door.issue_turfs = list()
	door.alarm_type = null
	door.process_atmos_alarm(probe, blaze, blaze.return_temperature())
	TEST_ASSERT_EQUAL(door.alarm_type, FIRELOCK_ALARM_TYPE_HOT, "предпосылка: с включённой детекцией жар обязан подниматься")

	// Провод перерезан: и зона, и дверь обязаны замолчать, причём УЖЕ поднятая
	// тревога должна сняться - иначе провод не отпускает закрытую дверь.
	alarm.set_detecting(FALSE)
	TEST_ASSERT(!zone.fire_detect, "перерезанный провод детекции не снял детекцию с зоны")
	TEST_ASSERT(!door.fire_detection, "перерезанный провод детекции не дошёл до двери")
	TEST_ASSERT_NULL(door.alarm_type, "перерезанный провод не снял уже поднятую тревогу")

	door.process_atmos_alarm(probe, blaze, blaze.return_temperature())
	TEST_ASSERT_NULL(door.alarm_type, "дверь с отключённой детекцией всё равно подняла тревогу")

	// И обратно: подключённый провод возвращает автоматику.
	alarm.set_detecting(TRUE)
	TEST_ASSERT(zone.fire_detect, "подключённый обратно провод не вернул детекцию зоне")
	TEST_ASSERT(door.fire_detection, "подключённый обратно провод не вернул детекцию двери")
	door.process_atmos_alarm(probe, blaze, blaze.return_temperature())
	TEST_ASSERT_EQUAL(door.alarm_type, FIRELOCK_ALARM_TYPE_HOT, "после возврата детекции жар перестал подниматься")

	door.issue_turfs = list()
	door.alarm_type = null
