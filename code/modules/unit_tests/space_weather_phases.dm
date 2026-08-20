/**
 * Тесты каркаса фазового явления.
 *
 * Фазы и интенсивность - не хронометраж, а единственный вход всего остального: от них
 * считается и картинка в иллюминаторе, и воздействие на станцию. Ошибка здесь тихая -
 * событие отыграет объявления и ничего не сделает, - поэтому проверяется расписание,
 * непрерывность кривой и то, что явление обязательно прибирает за собой сцену.
 */

/// Ниже этого порога должен оставаться шаг интенсивности между соседними тиками.
/// Настоящий разрыв на стыке фаз дал бы не меньше 0.3, поэтому запас втрое.
#define SPACE_WEATHER_MAX_INTENSITY_STEP 0.1

/**
 * Собирает явление для проверки, не оставляя его в реестре директора.
 *
 * /datum/round_event/New() безусловно кладёт себя в SSdirector.running, и брошенный там
 * экземпляр продолжил бы тикать в фоне следующих тестов, дёргая живую сцену.
 */
/proc/unit_test_detached_phenomenon(event_type)
	RETURN_TYPE(/datum/round_event/space_weather)
	var/datum/round_event/space_weather/phenomenon = new event_type(FALSE)
	SSdirector.running -= phenomenon
	return phenomenon

/// Расписание фаз: end_when выводится из их суммы, все три фазы встречаются, назад не откатываются.
/datum/unit_test/space_weather_phase_schedule/Run()
	var/checked = 0
	for(var/datum/round_event/space_weather/event_type as anything in subtypesof(/datum/round_event/space_weather))
		if(!initial(event_type.token))
			continue // абстрактная середина ветки
		checked++
		var/datum/round_event/space_weather/phenomenon = unit_test_detached_phenomenon(event_type)

		TEST_ASSERT(phenomenon.approach_ticks > 0, "[event_type]: нулевая фаза подхода - готовиться будет не к чему")
		TEST_ASSERT(phenomenon.peak_ticks > 0, "[event_type]: нулевой пик - у явления нет момента, ради которого оно происходит")
		TEST_ASSERT(phenomenon.departure_ticks > 0, "[event_type]: нулевой уход - сцена снимется рывком с полной интенсивности")

		var/expected_end = phenomenon.start_when + phenomenon.approach_ticks + phenomenon.peak_ticks + phenomenon.departure_ticks
		TEST_ASSERT_EQUAL(phenomenon.end_when, expected_end, "[event_type]: end_when [phenomenon.end_when] разошёлся с суммой фаз [expected_end] - последняя фаза оборвётся на середине")

		TEST_ASSERT_NOTNULL(phenomenon.peak_token, "[event_type]: пиковый токен не выведен из токена события")
		TEST_ASSERT_NOTEQUAL(phenomenon.peak_token, phenomenon.token, "[event_type]: пиковый слой лёг бы на токен события и заменил бы собой его профиль")

		var/list/seen_phases = list()
		var/previous_phase = PHENOMENON_PHASE_APPROACH
		var/total = phenomenon.approach_ticks + phenomenon.peak_ticks + phenomenon.departure_ticks
		for(var/elapsed in 0 to total - 1)
			var/current_phase = phenomenon.phase_for_elapsed(elapsed)
			TEST_ASSERT(current_phase >= previous_phase, "[event_type]: фаза откатилась с [previous_phase] на [current_phase] на тике [elapsed]")
			previous_phase = current_phase
			seen_phases |= current_phase
		TEST_ASSERT_EQUAL(length(seen_phases), 3, "[event_type]: за явление встретилось [length(seen_phases)] фаз из трёх")

		qdel(phenomenon)
	TEST_ASSERT(checked >= 5, "Явлений космической погоды нашлось всего [checked] - тест ничего не проверяет")

/// Кривая интенсивности: не выходит за 0..1, доходит до единицы, гаснет в ноль и нигде не рвётся.
/datum/unit_test/space_weather_intensity_curve/Run()
	for(var/datum/round_event/space_weather/event_type as anything in subtypesof(/datum/round_event/space_weather))
		if(!initial(event_type.token))
			continue
		var/datum/round_event/space_weather/phenomenon = unit_test_detached_phenomenon(event_type)
		var/total = phenomenon.approach_ticks + phenomenon.peak_ticks + phenomenon.departure_ticks

		var/previous = phenomenon.intensity_for_elapsed(0)
		TEST_ASSERT_EQUAL(previous, 0, "[event_type]: явление начинается с интенсивности [previous], а не с нуля")

		var/highest = previous
		for(var/elapsed in 1 to total)
			var/current = phenomenon.intensity_for_elapsed(elapsed)
			TEST_ASSERT(current >= 0 && current <= 1, "[event_type]: интенсивность [current] вне 0..1 на тике [elapsed]")
			var/step = abs(current - previous)
			TEST_ASSERT(step <= SPACE_WEATHER_MAX_INTENSITY_STEP, "[event_type]: интенсивность прыгнула на [step] на тике [elapsed] - разрыв кривой даст рывок картинки и скачок воздействия в один тик")
			highest = max(highest, current)
			previous = current

		TEST_ASSERT_EQUAL(highest, 1, "[event_type]: интенсивность дошла только до [highest] - пика фактически нет")
		TEST_ASSERT_EQUAL(phenomenon.intensity_for_elapsed(total), 0, "[event_type]: на последнем тике явление всё ещё идёт")
		qdel(phenomenon)

/**
 * Уборка сцены обязана быть идемпотентной и случаться в обоих выходах.
 *
 * Админская отмена в secrets.dm зовёт kill() НАПРЯМУЮ, минуя end(). Токен модификатора
 * знает только сам экземпляр события, поэтому пропущенная уборка означает залипшую
 * сцену до конца раунда без единого способа её снять.
 */
/datum/unit_test/space_weather_cleanup/Run()
	var/datum/round_event/space_weather/phenomenon = unit_test_detached_phenomenon(/datum/round_event/space_weather/graveyard)
	phenomenon.affected_z += 1
	phenomenon.cleanup()
	TEST_ASSERT(phenomenon.cleaned_up, "cleanup() не отметил уборку и повторится")
	TEST_ASSERT_EQUAL(length(phenomenon.affected_z), 0, "После уборки за событием остались затронутые z")
	phenomenon.cleanup() // второй раз обязан молча ничего не делать
	qdel(phenomenon)

	var/datum/round_event/space_weather/killed = unit_test_detached_phenomenon(/datum/round_event/space_weather/interphase)
	killed.affected_z += 1
	killed.kill()
	TEST_ASSERT(killed.cleaned_up, "kill() мимо end() оставил профиль события на сцене до конца раунда")
	qdel(killed)

/**
 * Пиковый слой ложится ОТДЕЛЬНЫМ модификатором поверх профиля события.
 *
 * Повторный add_modifier с тем же токеном заменяет запись, поэтому пиковый слой на
 * токене события снёс бы сам профиль: на пике сцена показала бы базовый космос.
 */
/datum/unit_test/space_weather_peak_layer/Run()
	var/datum/parallax_profile/original = SSparallax.get_base_profile(1)
	SSparallax.set_base_profile(1, "unit_test_scene")

	var/datum/round_event/space_weather/phenomenon = unit_test_detached_phenomenon(/datum/round_event/space_weather/graveyard)
	phenomenon.peak_layer = /atom/movable/screen/parallax_layer/space/random/asteroids
	phenomenon.affected_z += 1
	SSparallax.set_profile(1, phenomenon.profile_id, phenomenon.token, PARALLAX_PRIORITY_EVENT)
	var/baseline = length(SSparallax.get_parallax_template(1).objects)

	phenomenon.apply_peak_layer()
	var/datum/parallax_modifier/profile_modifier = SSparallax.find_modifier(1, phenomenon.token)
	var/datum/parallax_modifier/peak_modifier = SSparallax.find_modifier(1, phenomenon.peak_token)
	TEST_ASSERT_NOTNULL(profile_modifier, "Пиковый слой снёс модификатор профиля события")
	TEST_ASSERT_NOTNULL(peak_modifier, "Пиковый слой не лёг на сцену")
	TEST_ASSERT(peak_modifier.priority > profile_modifier.priority, "Пиковый слой лёг под профилем события и остался невидимым")
	TEST_ASSERT_EQUAL(SSparallax.get_parallax_template(1).profile_id, phenomenon.profile_id, "Пиковый слой подменил профиль события")
	TEST_ASSERT_EQUAL(length(SSparallax.get_parallax_template(1).objects), baseline + 1, "Пиковый слой не добавился в сцену")

	phenomenon.cleanup()
	TEST_ASSERT_NULL(SSparallax.find_modifier(1, phenomenon.peak_token), "Уборка не сняла пиковый слой")
	TEST_ASSERT_NULL(SSparallax.find_modifier(1, phenomenon.token), "Уборка не сняла профиль события")
	qdel(phenomenon)

	SSparallax.base_profile_by_z["1"] = original
	SSparallax.invalidate_z(1)

/**
 * Ступени директора у явлений заданы осознанно и совпадают с задуманной лестницей.
 *
 * Ступень - не украшение: её читает /datum/round_event_control/New(), а из неё следуют
 * цена, нагрузка и лимит одновременных. Урок, ради которого тест и написан: с категорией
 * ANOMALIES четыре явления из пяти уезжали в ступень "крупное" к метеорным волнам и
 * портальным штормам, где их насмерть держал лимит одновременных крупных. Теперь ступени
 * проставлены руками, и таблица ниже - единственное место, где эта развесовка записана.
 */
/datum/unit_test/space_weather_director_tier/Run()
	var/static/list/expected_tiers = list(
		/datum/round_event_control/space_weather/graveyard = DIRECTOR_SEVERITY_MODERATE,
		/datum/round_event_control/space_weather/micro_debris = DIRECTOR_SEVERITY_MODERATE,
		/datum/round_event_control/space_weather/ion_blizzard = DIRECTOR_SEVERITY_MODERATE,
		/datum/round_event_control/space_weather/bluespace_storm = DIRECTOR_SEVERITY_MODERATE,
		/datum/round_event_control/space_weather/interphase = DIRECTOR_SEVERITY_MINOR,
		/datum/round_event_control/space_weather/photon_vortex = DIRECTOR_SEVERITY_MAJOR,
	)

	var/checked = 0
	var/major_count = 0
	for(var/datum/round_event_control/space_weather/control in SSdirector.event_controls())
		if(control.type == /datum/round_event_control/space_weather)
			// Шаблон ветки: без profile_id его start() падает, поэтому он выключен,
			// а каждый конкретный подтип включает себя явно.
			TEST_ASSERT(!control.enabled, "Шаблонная база космической погоды включена - её запуск падает без профиля")
			continue
		checked++
		TEST_ASSERT(control.enabled, "[control.name]: подтип не включил себя явно, а база ветки выключена")
		TEST_ASSERT(control.weight > 0, "[control.name]: нулевой вес - событие не выпадет никогда")
		TEST_ASSERT_EQUAL(control.family, "space_weather", "[control.name]: вне семейства - анти-повторы обойдёт поодиночке")

		var/expected = expected_tiers[control.type]
		TEST_ASSERT_NOTNULL(expected, "[control.name]: явление не записано в таблицу ступеней - развесовка ветки стала неизвестной")
		TEST_ASSERT_EQUAL(control.severity, expected, "[control.name]: ступень '[control.severity]' вместо задуманной '[expected]'")
		TEST_ASSERT(control.cost > 0, "[control.name]: событие с механикой стоит ноль из бюджета директора")
		if(control.severity == DIRECTOR_SEVERITY_MAJOR)
			major_count++

	TEST_ASSERT_EQUAL(checked, length(expected_tiers), "Явлений в реестре директора [checked], а в таблице ступеней [length(expected_tiers)]")
	// Тяжёлое явление в ветке ровно одно. Второе делило бы с ним лимит одновременных
	// крупных, и оба выпадали бы вдвое реже, чем задумано.
	TEST_ASSERT_EQUAL(major_count, 1, "Крупных явлений в ветке [major_count], а должно быть ровно одно")

#undef SPACE_WEATHER_MAX_INTENSITY_STEP
