/// Разделы справочника сверх газов и реакций: инструменты, методы,
/// безопасность.
///
/// Без теста раздел, который перестал собираться (опечатка в категории, пустой
/// init_body), просто исчезает из окна, и заметить это некому: справочник
/// открывают редко и никто не помнит, сколько в нём было разделов.
/datum/unit_test/atmos_handbook_topics

/datum/unit_test/atmos_handbook_topics/Run()
	atmos_handbooks_init()
	var/list/sections = GLOB.atmos_topic_handbook
	TEST_ASSERT(length(sections) > 0, "справочник не собрал ни одного раздела")

	var/list/seen_categories = list()
	var/list/all_paragraphs = list()
	for(var/list/section as anything in sections)
		var/category = section["category"]
		TEST_ASSERT(length(category) > 0, "у раздела справочника нет заголовка")
		seen_categories += category
		var/list/topics = section["topics"]
		TEST_ASSERT(length(topics) > 0, "раздел [category] пуст")
		for(var/list/topic as anything in topics)
			var/title = topic["title"]
			TEST_ASSERT(length(title) > 0, "в разделе [category] есть топик без заголовка")
			var/list/paragraphs = topic["paragraphs"]
			TEST_ASSERT(length(paragraphs) > 0, "у топика [title] нет текста")
			for(var/paragraph in paragraphs)
				// Порог грубый, но он ловит заглушки вида "Смотри вики".
				TEST_ASSERT(length(paragraph) > 60, "абзац топика [title] слишком короткий, чтобы что-то объяснить")
			all_paragraphs += paragraphs

	for(var/category in GLOB.atmos_handbook_categories)
		TEST_ASSERT(category in seen_categories, "раздел [category] объявлен в порядке разделов, но в справочник не попал")

	// Числа механики живут в дефайнах, и справочник обязан их подставлять, а не
	// повторять руками. Если кто-то заменит подстановку литералом, а потом
	// поправит дефайн, справочник начнёт врать - вот ровно это здесь и ловится.
	var/handbook_text = jointext(all_paragraphs, " ")
	TEST_ASSERT(findtext(handbook_text, "[GAS_RECIPE_HIGH_PRESSURE]"), "справочник не называет порог верхних рецептов кристаллизатора")
	TEST_ASSERT(findtext(handbook_text, "[VOLUME_PUMP_PRESSURE_CEILING]"), "справочник не называет потолок объёмного насоса")

	// Окно справочника отдаёт ровно то, что собрано: поле могло не пробросить.
	var/list/payload = GLOB.atmos_handbook.ui_static_data(null)
	TEST_ASSERT_NOTNULL(payload["topicInfo"], "окно справочника не отдаёт разделы")
	TEST_ASSERT_EQUAL(length(payload["topicInfo"]), length(sections), "окно справочника отдаёт не тот набор разделов")

	// Точки входа зовут прок и с мобов без клиента тоже, и это не должно быть
	// рантаймом.
	TEST_ASSERT(!open_atmos_handbook(null), "справочник попытался открыться без клиента")

/// Реакции в справочнике обязаны быть описаны по-русски.
///
/// Раньше весь текст реакций был английским, а у части реакций описания не было
/// вовсе. Без теста следующая добавленная реакция приедет туда же и точно так
/// же по-английски.
/datum/unit_test/atmos_handbook_reactions_russian

/datum/unit_test/atmos_handbook_reactions_russian/Run()
	atmos_handbooks_init()
	TEST_ASSERT(length(GLOB.reaction_handbook) > 20, "справочник реакций пуст")

	var/regex/cyrillic = regex(@"[А-ЯЁа-яё]")
	for(var/list/entry as anything in GLOB.reaction_handbook)
		var/reaction_id = entry["id"]
		var/name = entry["name"]
		var/description = entry["description"]
		TEST_ASSERT(length(name) > 0, "у реакции [reaction_id] нет названия")
		TEST_ASSERT(cyrillic.Find(name, 1), "название реакции [reaction_id] осталось английским: [name]")
		TEST_ASSERT(length(description) > 0, "у реакции [name] нет описания для справочника")
		TEST_ASSERT(cyrillic.Find(description, 1), "описание реакции [name] осталось английским")

		var/list/factors = entry["factors"]
		TEST_ASSERT(length(factors) > 0, "у реакции [name] нет ни одного фактора: игрок не узнает ни условий, ни продуктов")
		for(var/list/factor as anything in factors)
			var/factor_name = factor["factor_name"]
			var/factor_desc = factor["desc"]
			TEST_ASSERT(length(factor_desc) > 0, "у фактора [factor_name] реакции [name] нет описания")
			TEST_ASSERT(cyrillic.Find(factor_desc, 1), "фактор [factor_name] реакции [name] описан по-английски: [factor_desc]")
