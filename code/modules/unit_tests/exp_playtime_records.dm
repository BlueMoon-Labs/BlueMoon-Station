/// Регресс-тест на свёртку старых названий ролей из role_time к актуальным.
/// Иначе часы за "Expeditor"/"Vanguard operative" не отображаются в TrackedPlaytime
/// (там перебираются только текущие названия из SSjob.name_occupations).

/datum/unit_test/exp_records_legacy_role_names/Run()
	var/list/records = list(
		"Expeditor" = 120,
		"Vanguard operative" = 30,
		"Vanguard Operative" = 60,
		"Living" = 999,
		"Ghost Role" = 15,
	)

	records = normalize_exp_records(records)

	TEST_ASSERT_NULL(records["Expeditor"], "Старое название роли должно быть поглощено")
	TEST_ASSERT_NULL(records["Vanguard operative"], "Вариант с неправильным регистром должен быть поглощён")
	TEST_ASSERT_EQUAL(records["Vanguard Operative"], 210, "Минуты по всем вариантам названия должны суммироваться")
	TEST_ASSERT_EQUAL(records["Living"], 999, "Каноничные ключи не должны меняться")
	TEST_ASSERT_EQUAL(records["Ghost Role"], 15, "Спецроли не должны меняться")

// Неизвестные названия (например, ещё не добавленные в алиасы переименования)
// обязаны сохраняться, а не теряться при нормализации.
/datum/unit_test/exp_records_unknown_role_names/Run()
	var/list/records = list(
		"Some Removed Job" = 45,
		"Vanguard Operative" = 5,
	)

	records = normalize_exp_records(records)

	TEST_ASSERT_EQUAL(records["Some Removed Job"], 45, "Неизвестное название не должно теряться")
	TEST_ASSERT_EQUAL(records["Vanguard Operative"], 5, "Каноничные ключи не должны меняться")

// Пустой список и список без мусора должны возвращаться как есть.
/datum/unit_test/exp_records_empty_input/Run()
	var/list/empty_records = normalize_exp_records(list())
	TEST_ASSERT(!length(empty_records), "Пустой список должен остаться пустым")

	var/list/clean_records = list("Vanguard Operative" = 10)
	clean_records = normalize_exp_records(clean_records)
	TEST_ASSERT_EQUAL(clean_records["Vanguard Operative"], 10, "Чистый список должен вернуться без изменений")
