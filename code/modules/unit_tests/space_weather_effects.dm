/**
 * Тесты воздействия явлений на станцию.
 *
 * Главная проверяемая вещь - ВОЗВРАТ подменённых глобальных величин. Явление, которое
 * ушло, не сняв свой множитель выработки, ломает энергетику станции до конца раунда, и
 * заметить это по логам нельзя: сеть просто ведёт себя не так, как должна.
 */

/**
 * Ионная буря поднимает выработку панелей, поле микрообломков её сажает, и оба обязаны
 * вернуть множитель в единицу - в том числе если событие убили мимо end().
 *
 * Замеры уходят в локальные переменные, а проверки идут ПОСЛЕ возврата глобальной
 * величины: TEST_ASSERT обрывает прок, и проверка посреди теста оставила бы подменённый
 * множитель выработки всем следующим тестам прогона.
 */
/datum/unit_test/space_weather_solar_multiplier/Run()
	var/original = GLOB.solar_output_multiplier

	var/datum/round_event/space_weather/ion_blizzard/blizzard = unit_test_detached_phenomenon(/datum/round_event/space_weather/ion_blizzard)
	blizzard.apply_intensity(1)
	var/blizzard_at_peak = GLOB.solar_output_multiplier
	blizzard.cleanup()
	var/blizzard_after_cleanup = GLOB.solar_output_multiplier
	qdel(blizzard)

	var/datum/round_event/space_weather/micro_debris/debris = unit_test_detached_phenomenon(/datum/round_event/space_weather/micro_debris)
	debris.apply_intensity(1)
	var/debris_at_peak = GLOB.solar_output_multiplier
	// Админская отмена ходит мимо end(): множитель обязан вернуться и на этом пути.
	debris.kill()
	var/debris_after_kill = GLOB.solar_output_multiplier
	qdel(debris)

	GLOB.solar_output_multiplier = original

	TEST_ASSERT(blizzard_at_peak > 1, "Ионная буря на пике не подняла выработку панелей ([blizzard_at_peak]) - награды за подготовку нет")
	TEST_ASSERT_EQUAL(blizzard_after_cleanup, 1, "Ионная буря ушла, оставив множитель выработки [blizzard_after_cleanup]")
	TEST_ASSERT(debris_at_peak < 1, "Поле микрообломков на пике не посадило выработку ([debris_at_peak]) - осевшая пыль ни на что не влияет")
	TEST_ASSERT_EQUAL(debris_after_kill, 1, "Убитое поле микрообломков оставило множитель выработки [debris_after_kill] до конца раунда")

/// Интенсивность обязана менять силу воздействия, а не только картинку.
/datum/unit_test/space_weather_intensity_scales_effect/Run()
	var/original = GLOB.solar_output_multiplier
	var/datum/round_event/space_weather/ion_blizzard/blizzard = unit_test_detached_phenomenon(/datum/round_event/space_weather/ion_blizzard)

	blizzard.apply_intensity(PHENOMENON_APPROACH_TOP)
	var/at_approach = GLOB.solar_output_multiplier
	blizzard.apply_intensity(1)
	var/at_peak = GLOB.solar_output_multiplier

	blizzard.cleanup()
	qdel(blizzard)
	GLOB.solar_output_multiplier = original

	TEST_ASSERT(at_peak > at_approach, "Выработка на пике ([at_peak]) не выше, чем на подходе ([at_approach]) - фазы ни на что не влияют")

/// Наросты на корпусе учитываются самим объектом: соскребают их игроки, и событие не
/// должно держать ссылки на то, что удаляет кто-то другой.
/datum/unit_test/space_weather_crust_bookkeeping/Run()
	var/obj/structure/loot_pile/debris_crust/crust = allocate(/obj/structure/loot_pile/debris_crust, run_loc_floor_bottom_left)
	TEST_ASSERT(crust in GLOB.debris_crusts, "Нарост не встал в глобальный список - уход явления его не сдует")
	TEST_ASSERT(!crust.density, "Нарост на обшивке плотный - он перегородит выход за борт")
	TEST_ASSERT(!crust.can_use_hands, "Нарост соскабливается голыми руками, хотя лежит снаружи")
	TEST_ASSERT(length(crust.loot) > 0, "У нароста пустой стол лута - соскабливать его незачем")

	qdel(crust)
	TEST_ASSERT(!(crust in GLOB.debris_crusts), "Удалённый нарост остался в глобальном списке - это держатель удалённого объекта")

/**
 * Блюспейс-глушилки обязаны сниматься на обоих выходах.
 *
 * Залипший GLOB.bluespace_teleport_blocked оставляет станцию без телепортации до конца
 * раунда, и найти причину по логам нельзя: телепорт просто молча возвращает FALSE.
 */
/datum/unit_test/space_weather_bluespace_restore/Run()
	var/original_noise = GLOB.bluespace_teleport_noise
	var/original_block = GLOB.bluespace_teleport_blocked

	var/datum/round_event/space_weather/bluespace_storm/storm = unit_test_detached_phenomenon(/datum/round_event/space_weather/bluespace_storm)
	storm.apply_intensity(1)
	var/noise_at_peak = GLOB.bluespace_teleport_noise
	storm.kill()
	var/noise_after_kill = GLOB.bluespace_teleport_noise
	qdel(storm)

	var/datum/round_event/space_weather/interphase/interphase = unit_test_detached_phenomenon(/datum/round_event/space_weather/interphase)
	interphase.on_phase_enter(PHENOMENON_PHASE_PEAK, PHENOMENON_PHASE_APPROACH)
	var/blocked_at_peak = GLOB.bluespace_teleport_blocked
	interphase.on_phase_enter(PHENOMENON_PHASE_DEPARTURE, PHENOMENON_PHASE_PEAK)
	var/blocked_after_peak = GLOB.bluespace_teleport_blocked

	// И тот же путь через админскую отмену, мимо end().
	interphase.on_phase_enter(PHENOMENON_PHASE_PEAK, PHENOMENON_PHASE_APPROACH)
	interphase.kill()
	var/blocked_after_kill = GLOB.bluespace_teleport_blocked
	qdel(interphase)

	// Возврат идёт ДО проверок: TEST_ASSERT обрывает прок, и залипшая глушилка досталась
	// бы всем следующим тестам прогона - там телепорт молча возвращал бы FALSE.
	GLOB.bluespace_teleport_noise = original_noise
	GLOB.bluespace_teleport_blocked = original_block

	TEST_ASSERT(noise_at_peak > 0, "Шторм на пике не расшатал точность телепортации - риска в событии нет")
	TEST_ASSERT_EQUAL(noise_after_kill, 0, "Убитый шторм оставил разброс телепортации [noise_after_kill] до конца раунда")
	TEST_ASSERT(blocked_at_peak, "Интерфаза на пике не заглушила блюспейс - событие ничего не делает")
	TEST_ASSERT(!blocked_after_peak, "Интерфаза держит блюспейс заглушенным и после пика")
	TEST_ASSERT(!blocked_after_kill, "Убитая интерфаза оставила станцию без телепортации до конца раунда")

/// Интерфаза не запускается при вызванной эвакуации: отрезать экипажу отход - это не
/// сложность, а тупик, и приходился бы он на самый неподходящий момент раунда.
/datum/unit_test/space_weather_interphase_evac_gate/Run()
	if(!SSshuttle.emergency)
		return // без шаттла проверять нечего
	var/datum/round_event_control/space_weather/interphase/control
	for(var/datum/round_event_control/space_weather/interphase/candidate in SSdirector.event_controls())
		control = candidate
		break
	TEST_ASSERT_NOTNULL(control, "Интерфазы нет в реестре директора - гейт эвакуации проверять не на чем")

	var/original_mode = SSshuttle.emergency.mode
	SSshuttle.emergency.mode = SHUTTLE_CALL
	// Сигналы не собираем: гейт эвакуации проверяется ДО базового контракта и до него
	// не доходит, а сбор сигналов ради заведомо ложной ветки - лишняя работа с побочными
	// эффектами в живом директоре.
	var/fired_during_evac = control.can_fire(null)
	// Режим возвращается ДО проверки: TEST_ASSERT обрывает прок, и оставленный SHUTTLE_CALL
	// достался бы всем шаттловым тестам прогона.
	SSshuttle.emergency.mode = original_mode
	TEST_ASSERT(!fired_during_evac, "Интерфаза согласилась запуститься при вызванном шаттле")

/// У каждого явления должна быть выкладка для сенсора: без неё разведка не даёт ничего,
/// и строить машину незачем.
/datum/unit_test/space_weather_sensor_readouts/Run()
	var/with_readout = 0
	for(var/datum/round_event/space_weather/event_type as anything in subtypesof(/datum/round_event/space_weather))
		if(!initial(event_type.token))
			continue
		var/datum/round_event/space_weather/phenomenon = unit_test_detached_phenomenon(event_type)
		TEST_ASSERT_NOTNULL(phenomenon.phenomenon_name, "[event_type]: у явления нет русского имени - сенсор покажет пустую строку")
		TEST_ASSERT(phenomenon.sensor_yield_mult > 0, "[event_type]: нулевой множитель выдачи - наблюдать явление бессмысленно")
		if(length(phenomenon.sensor_readout()))
			with_readout++
		qdel(phenomenon)
	TEST_ASSERT(with_readout >= 3, "Выкладку для сенсора имеют всего [with_readout] явления - разведка почти ничего не показывает")
