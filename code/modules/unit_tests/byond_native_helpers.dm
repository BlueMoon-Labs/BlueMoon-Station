/// Проверяет веса по умолчанию, нулевые веса и различие числовых ключей list/alist.
/datum/unit_test/byond_native_pickweight/Run()
	TEST_ASSERT_NULL(pickweight(list()), "Пустой список должен вернуть null")
	TEST_ASSERT_NULL(pickweight(list("disabled" = 0)), "Нулевой вес нельзя выбрать")
	var/list/weights = list("disabled" = 0, "default")
	TEST_ASSERT_EQUAL(pickweight(weights), "default", "Незаданный вес должен считаться единицей")
	TEST_ASSERT_EQUAL(weights["default"], 1, "Вес по умолчанию должен сохраниться в исходном списке")
	TEST_ASSERT_EQUAL(weights["disabled"], 0, "Нулевой вес не должен меняться")
	TEST_ASSERT_EQUAL(pickweight(list(1, 1)), 1, "Числовой элемент обычного списка должен обращаться по позиции")
	var/alist/numeric_weights = alist()
	numeric_weights[42] = 1
	numeric_weights[7] = 0
	TEST_ASSERT_EQUAL(pickweight(numeric_weights), 42, "Числовой ключ alist не должен обращаться по позиции")
	var/datum/probe = allocate(/datum)
	var/list/datum_weights = list()
	datum_weights[probe] = 5
	datum_weights["disabled"] = 0
	TEST_ASSERT_EQUAL(pickweight(datum_weights), probe, "Ключ-датум должен сохраняться")
	var/list/list_key = list("probe")
	var/list/list_weights = list()
	list_weights[list_key] = 5
	list_weights["disabled"] = 0
	TEST_ASSERT_EQUAL(pickweight(list_weights), list_key, "Ключ-список должен сохраняться")

/// Проверяет знак координат и однократное вычисление аргумента.
/datum/unit_test/byond_native_sign/Run()
	for(var/value in list(-1e6, -1, -0.001, 0, 0.001, 1, 1e6))
		var/expected = value == 0 ? 0 : value / abs(value)
		TEST_ASSERT_EQUAL(SIGN(value), expected, "Знак [value] изменился")
	var/evaluations = 0
	TEST_ASSERT_EQUAL(SIGN(++evaluations), 1, "Знак положительного значения должен быть единицей")
	TEST_ASSERT_EQUAL(evaluations, 1, "Аргумент должен вычисляться один раз")

/// Проверяет именованный доступ после сортировки, замены, копирования и удаления фильтров.
/datum/unit_test/byond_named_filters/Run()
	var/obj/effect/filter_rebuild_probe/target = allocate(/obj/effect/filter_rebuild_probe)
	TEST_ASSERT_NULL(target.get_filter("missing"), "Отсутствующий фильтр должен вернуть null")
	target.add_filter("upper", 20, list("type" = "blur", "size" = 2))
	target.add_filter("lower", 10, list("type" = "blur", "size" = 1))
	target.add_filter("", 30, list("type" = "blur", "size" = 1))
	TEST_ASSERT_NOTNULL(target.get_filter(""), "Пустое имя из редактора фильтров должно сохранять доступ по позиции")
	target.remove_filter("")
	TEST_ASSERT_NOTNULL(target.filters["upper"], "Имя должно быть зарегистрировано в движке")
	TEST_ASSERT_NOTNULL(target.get_filter("lower"), "Фильтр потерян после сортировки")
	TEST_ASSERT_EQUAL(target.get_filter_index("lower"), 1, "Порядок приоритетов изменился")
	target.change_filter_priority("upper", 5)
	TEST_ASSERT_EQUAL(target.get_filter_index("upper"), 1, "Изменение приоритета должно менять порядок")
	TEST_ASSERT_NOTNULL(target.get_filter("upper"), "Фильтр потерян после изменения приоритета")
	target.add_filter("upper", 5, list("type" = "blur", "size" = 3))
	TEST_ASSERT_EQUAL(length(target.filters), 2, "Замена фильтра не должна создавать дубликат")
	target.transition_filter("upper", 0, list("size" = 4))
	TEST_ASSERT_EQUAL(target.filter_data["upper"]["size"], 4, "Параметры перехода должны сохраняться")
	var/obj/effect/filter_rebuild_probe/copy = allocate(/obj/effect/filter_rebuild_probe)
	copy.filters = target.filters
	copy.filter_data = target.filter_data.Copy()
	TEST_ASSERT_NOTNULL(copy.get_filter("upper"), "Копирование внешнего вида должно сохранять имена")
	target.remove_filter("upper")
	TEST_ASSERT_NULL(target.get_filter("upper"), "Удалённый фильтр остался доступен")
	TEST_ASSERT_NOTNULL(target.get_filter("lower"), "Удалён соседний фильтр")
	TEST_ASSERT_NOTNULL(copy.get_filter("upper"), "Изменение оригинала затронуло копию")
	target.filters = null
	TEST_ASSERT_NULL(target.get_filter("lower"), "Сброс внешнего вида не должен возвращать устаревший фильтр")
	target.clear_filters()
	TEST_ASSERT_NULL(target.filter_data, "Очистка должна удалить метаданные")
