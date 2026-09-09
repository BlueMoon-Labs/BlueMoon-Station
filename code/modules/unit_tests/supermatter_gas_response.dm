// Регрессии кристалла: три правки в расчёте газовых модификаторов, каждая из
// которых годами меняла поведение движка молча.

/// Кристалл, снятый с обработки SSair (тест сам решает, когда крутить фаер) и с
/// выключенным уроном: ни один из этих тестов о делам-цикле не говорит, а
/// горячий газ иначе копил бы damage между проверками.
/datum/unit_test/proc/allocate_test_supermatter()
	var/obj/machinery/power/supermatter_crystal/shard/crystal = allocate(/obj/machinery/power/supermatter_crystal/shard)
	SSair.stop_processing_machine(crystal)
	crystal.takes_damage = FALSE
	return crystal

/// Заливает в турф теста смесь по долям и синхронизирует с ней лаговый снимок
/// композиции кристалла: gas_comp ползёт к факту со скоростью gas_change_rate,
/// и без синхронизации пришлось бы крутить два десятка фаеров ради одной цифры.
/datum/unit_test/proc/pin_supermatter_chamber(obj/machinery/power/supermatter_crystal/crystal, list/composition, temperature, total_moles = 200)
	var/turf/open/room = run_loc_floor_bottom_left
	room.air.clear()
	for(var/gas_id in composition)
		room.air.set_moles(gas_id, composition[gas_id] * total_moles)
	room.air.set_temperature(temperature)
	room.air_update_turf()
	crystal.gas_comp = composition.Copy()

/// Турф теста общий на весь прогон, а эти тесты держат в нём то плазму, то
/// пять тысяч кельвинов - воздух надо вернуть соседям в исходном виде.
/datum/unit_test/proc/restore_test_chamber(datum/gas_mixture/snapshot)
	var/turf/open/room = run_loc_floor_bottom_left
	room.air.copy_from(snapshot)
	room.air_update_turf()

/// Плюксиум обязан считаться как газ с отрицательным powermix, когда его в
/// камере хватает на порог. Скобка тернарника стояла внутри isnull(), поэтому
/// вклад схлопывался в ноль на обеих ветках порога сразу.
/datum/unit_test/supermatter_pluoxium_contribution/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/datum/gas_mixture/snapshot = new
	snapshot.copy_from(run_loc_floor_bottom_left.return_air())
	var/obj/machinery/power/supermatter_crystal/crystal = allocate_test_supermatter()

	// 30% плюксиума - выше порога в 15%, вклад засчитывается целиком:
	// 0.7 * 1 (плазма) + 0.3 * -1 (плюксиум).
	pin_supermatter_chamber(crystal, list(GAS_PLASMA = 0.7, GAS_PLUOXIUM = 0.3), T20C)
	crystal.process_atmos()
	var/above_threshold = round(crystal.gasmix_power_ratio, 0.001)

	// 10% - ниже порога: газ не считается вовсе, остаётся чистый вклад плазмы.
	pin_supermatter_chamber(crystal, list(GAS_PLASMA = 0.9, GAS_PLUOXIUM = 0.1), T20C)
	crystal.process_atmos()
	var/below_threshold = round(crystal.gasmix_power_ratio, 0.001)

	restore_test_chamber(snapshot)
	// Сравнение с допуском: доли композиции - плавучка, и TEST_ASSERT_EQUAL умеет
	// сообщить "Expected 0.9 to be equal to 0.9" на разнице в пятнадцатом знаке.
	TEST_ASSERT(abs(above_threshold - 0.4) < 0.001, "плюксиум выше порога не вычелся из gasmix_power_ratio: [above_threshold]")
	TEST_ASSERT(abs(below_threshold - 0.9) < 0.001, "порог в 15% перестал отсекать вклад плюксиума: [below_threshold]")

/// Множитель порога теплового урона - "value between 1 and 10", и единица тут
/// нижняя граница, а не начальное значение аккумулятора. Без клампа штатная
/// смесь (heat_resistance = 0 у N2/O2/CO2/плазмы) роняет порог с 313 K в ноль, и
/// кристалл начинает считать уроном любую абсолютную температуру камеры.
/datum/unit_test/supermatter_heat_resistance_floor/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/datum/gas_mixture/snapshot = new
	snapshot.copy_from(run_loc_floor_bottom_left.return_air())
	var/obj/machinery/power/supermatter_crystal/crystal = allocate_test_supermatter()

	pin_supermatter_chamber(crystal, list(GAS_N2 = 1), T20C)
	crystal.process_atmos()
	var/plain_mix = crystal.dynamic_heat_resistance

	// Газ со своим heat_resistance поднимает множитель над полом, а не заменяет
	// его: N2O даёт 6 за полную камеру, половина камеры - половину значения.
	pin_supermatter_chamber(crystal, list(GAS_NITROUS = 0.5, GAS_N2 = 0.5), T20C)
	crystal.process_atmos()
	var/resistant_mix = round(crystal.dynamic_heat_resistance, 0.001)

	restore_test_chamber(snapshot)
	TEST_ASSERT(abs(plain_mix - 1) < 0.001, "порог теплового урона на азоте схлопнулся ниже единицы: [plain_mix]")
	TEST_ASSERT(abs(resistant_mix - 3) < 0.001, "heat_resistance газа перестал поднимать порог над полом: [resistant_mix]")

/// Потолок ограничивает выброс тепла САМОГО кристалла. Пока set_temperature
/// стоял снаружи ветки нагрева, кристалл каждый фаер срезал вниз чужое тепло -
/// пожар в камере, эмиттеры, горячий теплоноситель - и работал холодильником
/// собственной камеры.
/datum/unit_test/supermatter_keeps_foreign_heat/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/room = run_loc_floor_bottom_left
	var/datum/gas_mixture/snapshot = new
	snapshot.copy_from(room.return_air())
	var/obj/machinery/power/supermatter_crystal/crystal = allocate_test_supermatter()

	// Азот держит gasmix_power_ratio в нуле, то есть мощность от нагрева не
	// растёт и потолок остаётся минимальным (2500 * 0.5) - ровно тот случай,
	// когда кристалл раньше срезал температуру камеры втрое за один вызов.
	pin_supermatter_chamber(crystal, list(GAS_N2 = 1), 5000)
	var/hot_before = room.air.return_temperature()
	crystal.process_atmos()
	var/hot_after = room.air.return_temperature()

	// Обратная половина инварианта: холодную камеру он по-прежнему обязан греть.
	crystal.power = 1000
	pin_supermatter_chamber(crystal, list(GAS_PLASMA = 0.5, GAS_O2 = 0.5), T20C)
	var/cold_before = room.air.return_temperature()
	crystal.process_atmos()
	var/cold_after = room.air.return_temperature()

	restore_test_chamber(snapshot)
	TEST_ASSERT(hot_after >= hot_before - 1, "кристалл охладил камеру с [round(hot_before)] K до [round(hot_after)] K")
	TEST_ASSERT(cold_after > cold_before, "кристалл перестал греть холодную камеру")
