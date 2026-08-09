// Пороги воздушной сигнализации получили нормальный интерфейс: модалку ввода
// вместо блокирующего input(), кнопку сброса к заводским и белый список полей.
// Заодно вскрылось, что regenerate_TLV() раздавал всем алярмам станции один и
// тот же /datum/tlv на газ - правка порога в одной комнате меняла его во всех.
// Эти тесты держат и то, и другое.

/datum/unit_test/airalarm_threshold_isolation/Run()
	var/obj/machinery/airalarm/first = allocate(/obj/machinery/airalarm)
	var/obj/machinery/airalarm/second = allocate(/obj/machinery/airalarm)

	var/datum/tlv/first_plasma = first.TLV[GAS_PLASMA]
	var/datum/tlv/second_plasma = second.TLV[GAS_PLASMA]
	TEST_ASSERT_NOTNULL(first_plasma, "у алярма нет порога плазмы")
	TEST_ASSERT_NOTNULL(second_plasma, "у второго алярма нет порога плазмы")
	TEST_ASSERT(first_plasma != second_plasma, "два алярма держат один и тот же /datum/tlv на плазму")

	var/original_max = second_plasma.max2
	first_plasma.max2 = original_max + 42
	TEST_ASSERT_EQUAL(second_plasma.max2, original_max, "правка порога на одном алярме уехала во второй")

/datum/unit_test/airalarm_threshold_defaults/Run()
	var/obj/machinery/airalarm/alarm = allocate(/obj/machinery/airalarm)
	var/datum/tlv/pressure = alarm.TLV["pressure"]
	TEST_ASSERT_NOTNULL(pressure, "у алярма нет порога давления")
	TEST_ASSERT(pressure.is_at_defaults(), "свежий алярм считает свои пороги изменёнными")

	var/factory_max = pressure.defaults["max2"]
	pressure.max2 = factory_max + 100
	TEST_ASSERT(!pressure.is_at_defaults(), "изменённый порог всё ещё считается заводским")

	TEST_ASSERT(pressure.reset_to_defaults(), "сброс порогов не сработал")
	TEST_ASSERT_EQUAL(pressure.max2, factory_max, "сброс не вернул заводское значение")
	TEST_ASSERT(pressure.is_at_defaults(), "после сброса порог не считается заводским")

	// Копия обязана быть независимой и по текущим значениям, и по заводским,
	// иначе un-sharing в regenerate_TLV() ничего не чинит.
	var/datum/tlv/clone = pressure.copy()
	clone.max2 = factory_max + 500
	TEST_ASSERT_EQUAL(pressure.max2, factory_max, "правка копии порога уехала в оригинал")
	TEST_ASSERT_EQUAL(clone.defaults["max2"], factory_max, "копия потеряла заводские значения")

/// Пороги температуры заданы по человеку, а половина комнат станции холодна по
/// проекту: телекомы разложены при 80 K. Алярм там горел красным с первой
/// секунды раунда и до конца - тревога, которую нельзя ни снять, ни исправить.
/// Полоса обязана сдвигаться под проект комнаты, но не разъезжаться вообще.
/datum/unit_test/airalarm_design_temperature/Run()
	var/turf/open/room = run_loc_floor_bottom_left
	TEST_ASSERT(istype(room), "тестовой зоне нужен открытый турф")
	var/saved_gas_mix = room.initial_gas_mix

	var/obj/machinery/airalarm/ordinary = allocate(/obj/machinery/airalarm, room)
	var/datum/tlv/ordinary_temperature = ordinary.TLV["temperature"]
	TEST_ASSERT_NOTNULL(ordinary_temperature, "у алярма нет порога температуры")

	room.initial_gas_mix = TCOMMS_ATMOS
	var/obj/machinery/airalarm/chilled = allocate(/obj/machinery/airalarm, room)
	room.initial_gas_mix = saved_gas_mix

	var/list/design = SSair.get_parsed_gas_string(TCOMMS_ATMOS)
	var/designed_temperature = design[GAS_STRING_TEMP]
	TEST_ASSERT(isnum(designed_temperature), "предпосылка: у телекомовской смеси должна быть температура")

	var/datum/tlv/chilled_temperature = chilled.TLV["temperature"]
	TEST_ASSERT_EQUAL(chilled_temperature.get_danger_level(designed_temperature), 0,
		"алярм считает аварией проектную температуру собственной комнаты")
	TEST_ASSERT(chilled_temperature.get_danger_level(designed_temperature - 100) > 0,
		"сдвинутая полоса перестала ловить переохлаждение")
	TEST_ASSERT(chilled_temperature.is_at_defaults(),
		"сдвинутая полоса считается изменённой, и кнопка сброса вернёт вечную тревогу")

	// Обычная комната не должна получить ни сантиметра этого сдвига.
	TEST_ASSERT(ordinary_temperature.min2 > chilled_temperature.min2,
		"алярм в обычной комнате уехал вместе с холодной")
	TEST_ASSERT_EQUAL(ordinary_temperature.get_danger_level(designed_temperature), 2,
		"алярм в обычной комнате перестал считать 80 K аварией")

/datum/unit_test/airalarm_threshold_write_guard/Run()
	var/obj/machinery/airalarm/alarm = allocate(/obj/machinery/airalarm)
	var/datum/tlv/pressure = alarm.TLV["pressure"]

	TEST_ASSERT(alarm.set_threshold("pressure", "max2", 250), "порог из интерфейса не применился")
	TEST_ASSERT_EQUAL(pressure.max2, 250, "порог из интерфейса записался неверно")

	// Отрицательное значение - это "порог отключён", ровно -1.
	TEST_ASSERT(alarm.set_threshold("pressure", "max2", -7), "отрицательное значение не приняли")
	TEST_ASSERT_EQUAL(pressure.max2, -1, "отрицательное значение не отключило порог")

	// params["var"] раньше уходил в tlv.vars[] без всякой проверки.
	var/original_tag = pressure.tag
	TEST_ASSERT(!alarm.set_threshold("pressure", "tag", 13), "интерфейсу позволили писать в произвольное поле")
	TEST_ASSERT_EQUAL(pressure.tag, original_tag, "интерфейс записал произвольную переменную датума")

	TEST_ASSERT(!alarm.set_threshold("не такой газ", "max2", 5), "запись в несуществующий параметр прошла")
	TEST_ASSERT(!alarm.set_threshold("pressure", "max2", null), "пустое значение приняли за порог")
