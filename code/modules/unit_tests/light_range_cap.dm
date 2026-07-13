// Кап дальности света LIGHTING_MAX_RANGE (8 тайлов) защищает перф движущихся источников,
// но молча резал статичные карточные/ивентовые лампы, которым нужен большой радиус.
// Флаг LIGHT_NO_RANGE_CAP снимает кап до LIGHTING_MAX_RANGE_STATIC, но только для
// корнер-системы (COMPLEX_LIGHT). Ассерты source-local (light_range атома и его
// light_source) - на reserved z тестовой зоны view() пуст, кросс-тайловую яркость не меряем.

/// Статичный источник с флагом превышает базовый кап (8) вплоть до статичного потолка.
/datum/unit_test/light_range_cap_static_bypass/Run()
	var/obj/effect/light_emitter/emitter = allocate(/obj/effect/light_emitter, run_loc_floor_bottom_left)
	TEST_ASSERT_EQUAL(emitter.light_system, COMPLEX_LIGHT, "light_emitter должен быть корнер-источником для этого теста")

	emitter.light_flags |= LIGHT_NO_RANGE_CAP
	emitter.set_light(20, 1, COLOR_WHITE)
	TEST_ASSERT_EQUAL(emitter.light_range, 20, "Флагнутая статика должна держать дальность 20, а не кап LIGHTING_MAX_RANGE")
	TEST_ASSERT_NOTNULL(emitter.light, "set_light должен создать живой источник света")
	TEST_ASSERT_EQUAL(emitter.light.light_range, 20, "Живой источник должен унаследовать дальность 20")

	// Сверх статичного потолка режется до LIGHTING_MAX_RANGE_STATIC, а не до базового капа.
	emitter.set_light(l_range = 40)
	TEST_ASSERT_EQUAL(emitter.light_range, LIGHTING_MAX_RANGE_STATIC, "Дальность сверх статичного потолка режется до LIGHTING_MAX_RANGE_STATIC")

/// Без флага базовый кап LIGHTING_MAX_RANGE по-прежнему режет дальность (защита перфа муверов).
/datum/unit_test/light_range_cap_default_clamp/Run()
	var/obj/effect/light_emitter/emitter = allocate(/obj/effect/light_emitter, run_loc_floor_bottom_left)
	emitter.set_light(20, 1, COLOR_WHITE)
	TEST_ASSERT_EQUAL(emitter.light_range, LIGHTING_MAX_RANGE, "Без флага дальность должна резаться до LIGHTING_MAX_RANGE")
	TEST_ASSERT_NOTNULL(emitter.light, "set_light должен создать живой источник света")
	TEST_ASSERT_EQUAL(emitter.light.light_range, LIGHTING_MAX_RANGE, "Живой источник без флага не превышает LIGHTING_MAX_RANGE")

/// Гранулярный сеттер set_light_range() уважает флаг так же, как set_light().
/datum/unit_test/light_range_cap_setter_bypass/Run()
	var/obj/effect/light_emitter/emitter = allocate(/obj/effect/light_emitter, run_loc_floor_bottom_left)
	emitter.light_flags |= LIGHT_NO_RANGE_CAP
	emitter.set_light_range(16)
	TEST_ASSERT_EQUAL(emitter.light_range, 16, "set_light_range на флагнутой статике должен держать 16")
