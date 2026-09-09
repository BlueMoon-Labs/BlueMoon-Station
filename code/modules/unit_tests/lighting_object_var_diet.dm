/**
 * Диета блока переменных объекта освещения.
 *
 * Цена инстанса в BYOND 516 - ~44 Б заголовка плюс 16.2 Б на каждую ЗАПИСАННУЮ переменную,
 * ступенями по четыре слота (замерено стендом varcalib 22.08.2026). На проде живёт
 * 256 761 объект освещения (раунд 10119), поэтому одна ступень стоит 16.6 МБ, а три - 50.
 *
 * Двенадцать переменных prev_rr..prev_ab держали предыдущее значение каждого канала ради
 * гейта "ничего визуально не изменилось". Гейт сравнивал СУММУ двенадцати abs-дельт с
 * LIGHTING_ROUND_VALUE = 1/32, а значения углов и так лежат на сетке 1/32: любое настоящее
 * изменение хотя бы одного угла даёт сумму РОВНО 1/32 и гейт не срабатывает. Он ловил
 * только объекты, поставленные в очередь без изменения углов вовсе.
 *
 * Тест держит контракт: этих переменных на типе больше нет. `vars` отдаёт ОБЪЯВЛЕННЫЕ
 * переменные - для проверки "их не осталось" этого достаточно, для проверки цены нет
 * (объявление на инстансе бесплатно, платится за запись).
 */

/// Двенадцать поканальных prev_* сняты: их гейт не срабатывал, а стоили они три ступени.
/datum/unit_test/lighting_object_has_no_per_channel_prev_vars/Run()
	var/turf/test_turf = run_loc_floor_bottom_left
	var/atom/movable/lighting_object/test_lo = ensure_lighting_object(test_turf)

	var/list/leftovers = list()
	for(var/prev_name in list("prev_rr", "prev_rg", "prev_rb", "prev_gr", "prev_gg", "prev_gb", \
		"prev_br", "prev_bg", "prev_bb", "prev_ar", "prev_ag", "prev_ab"))
		if(prev_name in test_lo.vars)
			leftovers += prev_name

	TEST_ASSERT_EQUAL(length(leftovers), 0, "На объекте освещения остались поканальные prev_*: [leftovers.Join(", ")]")

/// Быстрый скип по темноте - другая переменная и другой гейт, он остаётся: он экономит ВСЕ
/// чтения углов, а не только сборку матрицы, и срабатывает на каждом тёмном турфе.
/datum/unit_test/lighting_object_keeps_dark_skip/Run()
	var/turf/test_turf = run_loc_floor_bottom_left
	var/atom/movable/lighting_object/test_lo = ensure_lighting_object(test_turf)

	TEST_ASSERT("prev_was_dark" in test_lo.vars, "Гейт по темноте снимать нельзя - он экономит все чтения углов")

/// Однородная окрестность - профиль зоны читается из самой зоны и на объекте НЕ хранится.
/// Четыре записи blended_* на четверть миллиона объектов стоят ещё одну ступень (16.6 МБ),
/// а личные значения нужны только на границе зон, где идёт усреднение.
/datum/unit_test/lighting_object_uniform_neighbourhood_stores_no_profile/Run()
	var/turf/test_turf = run_loc_floor_bottom_left
	var/atom/movable/lighting_object/test_lo = ensure_lighting_object(test_turf)

	test_lo.calculate_area_blend()

	TEST_ASSERT(!test_lo.blend_is_local, "В однородной окрестности личного профиля быть не должно")
	TEST_ASSERT_EQUAL(test_lo.blended_contrast, initial(test_lo.blended_contrast), "В однородной окрестности blended_* обязаны остаться нетронутыми")
	TEST_ASSERT_EQUAL(test_lo.blended_ambient, initial(test_lo.blended_ambient), "В однородной окрестности blended_* обязаны остаться нетронутыми")

/// ...и при этом апдейт обязан брать профиль ЗОНЫ, а не типовой дефолт объекта. Проверяем
/// сквозь картинку: тёплая температура зоны множит красный канал на (1 + temperature).
/// Личных blended_* у объекта нет вовсе, поэтому единственный способ увидеть подмену -
/// прочитать её из зоны. Сравниваем два прогона на одних и тех же углах, а не с константой:
/// освещённость тестового турфа задаёт резервация, и абсолютное число тут не наше.
/datum/unit_test/lighting_object_uniform_neighbourhood_reads_area_profile/Run()
	var/turf/test_turf = run_loc_floor_bottom_left
	var/atom/movable/lighting_object/test_lo = ensure_lighting_object(test_turf)
	var/area/test_area = test_turf.loc
	var/old_temperature = test_area.light_temperature

	// Свой источник обязателен: освещённость резервации от прогона к прогону не постоянна
	// (в двух подряд прогонах этот турф был то 0.72, то 0), а сравнивать надо два
	// одинаковых состояния углов. Мощность НЕ полная - у полностью освещённого турфа
	// update() отдаёт LIGHTING_BASE_MATRIX мимо профиля зоны вовсе.
	var/obj/effect/light_emitter/emitter = allocate(/obj/effect/light_emitter, test_turf)
	emitter.set_light(2, 0.4, COLOR_WHITE)
	process_nightshift_lighting_work()

	var/neutral_red = measure_lighting_red_channel(test_lo)
	test_area.light_temperature = 0.5
	test_lo.calculate_area_blend()
	var/warmed_red = measure_lighting_red_channel(test_lo)

	// Зону чиним ДО ассертов: она общая, а провалившийся ассерт делает return
	test_area.light_temperature = old_temperature
	test_lo.calculate_area_blend()
	measure_lighting_red_channel(test_lo)

	TEST_ASSERT(neutral_red > 0, "Тестовый источник обязан осветить турф, иначе сравнивать нечего (получено [neutral_red])")
	TEST_ASSERT_NOTEQUAL(warmed_red, neutral_red, "Смена температуры ЗОНЫ обязана изменить цвет: личных blended_* у объекта нет, и не прочитать профиль из зоны значит не заметить смену вовсе")

/// Прогнать полный апдейт (мимо быстрого скипа по темноте) и вернуть первый элемент
/// цветовой матрицы - красный канал левого нижнего угла.
/datum/unit_test/proc/measure_lighting_red_channel(atom/movable/lighting_object/target)
	target.prev_was_dark = FALSE
	target.update(use_animate = FALSE)
	var/list/produced = target.color
	return islist(produced) ? produced[1] : null

/// Снятие гейта не должно менять картинку: тёмный турф остаётся полностью тёмным, и
/// повторный апдейт с теми же углами даёт тот же цвет, а не застревает на прошлом.
/datum/unit_test/lighting_object_repeat_update_is_stable/Run()
	var/turf/test_turf = run_loc_floor_bottom_left
	var/atom/movable/lighting_object/test_lo = ensure_lighting_object(test_turf)

	test_lo.prev_was_dark = FALSE
	test_lo.update(use_animate = FALSE)
	var/first_pass = test_lo.color
	var/first_luminosity = test_turf.luminosity
	test_lo.update(use_animate = FALSE)
	var/second_pass = test_lo.color

	TEST_ASSERT_EQUAL("[first_pass]", "[second_pass]", "Повторный апдейт с теми же углами обязан дать тот же цвет")
	TEST_ASSERT_EQUAL(test_turf.luminosity, first_luminosity, "Повторный апдейт не должен менять luminosity турфа")
