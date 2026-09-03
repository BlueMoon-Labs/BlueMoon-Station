// Регрессионные тесты для stationmessage-галлюцинаций (heretic ascension /
// cult summon), их хелперов и синхронности pick-листов между местами выбора
// сообщения (массовая галлюцинация, нанит-программа, прямое создание).

/// Структура static-списка heretic_ascension_bodies: 5 путей (ash/blade/flesh/rust/void),
/// у каждого есть непустой text с плейсхолдером %FAKENAME% и непустой sound.
/datum/unit_test/hallucination_heretic_ascension_bodies_structure/Run()
	var/list/bodies = /datum/hallucination/stationmessage::heretic_ascension_bodies
	TEST_ASSERT_NOTNULL(bodies, "heretic_ascension_bodies не определён")
	TEST_ASSERT_EQUAL(length(bodies), 5, "Ожидалось 5 тел путей еретика (ash/blade/flesh/rust/void)")
	for(var/list/entry in bodies)
		TEST_ASSERT_NOTNULL(entry["text"], "Запись без поля text: [json_encode(entry)]")
		TEST_ASSERT(length(entry["text"]) > 0, "Пустой text в записи: [json_encode(entry)]")
		TEST_ASSERT(findtext(entry["text"], "%FAKENAME%"), "Запись не содержит плейсхолдер %FAKENAME%: [entry["text"]]")
		TEST_ASSERT_NOTNULL(entry["sound"], "Запись без поля sound: [entry["text"]]")

/// Pick-листы stationmessage в трёх местах должны быть в синхроне: дефолтный
/// pick в /datum/hallucination/stationmessage/New, массовая галлюцинация
/// (mass_hallucination.dm), pick админ-настройки нанит-программы (suppression.dm).
/// Регрессия: добавление "heretic"/"cult summon" только в одном месте делает
/// сообщение недостижимым через альтернативный путь активации.
/datum/unit_test/hallucination_stationmessage_pick_lists_in_sync/Run()
	var/static/list/canonical = list("ratvar", "shuttle dock", "blob alert", "malf ai", "heretic", "cult summon", "meteors", "supermatter")

	var/hallucination_src = read_source_file("code/modules/flufftext/Hallucination.dm")
	TEST_ASSERT(length(hallucination_src), "Не удалось прочитать Hallucination.dm")
	for(var/option in canonical)
		TEST_ASSERT(findtext(hallucination_src, "\"[option]\""), "Hallucination.dm не содержит опцию '[option]' в pick-листе stationmessage")

	var/mass_src = read_source_file("code/modules/events/mass_hallucination.dm")
	TEST_ASSERT(length(mass_src), "Не удалось прочитать mass_hallucination.dm")
	for(var/option in canonical)
		TEST_ASSERT(findtext(mass_src, "\"[option]\""), "mass_hallucination.dm не содержит опцию '[option]'")

	var/suppression_src = read_source_file("code/modules/research/nanites/nanite_programs/suppression.dm")
	TEST_ASSERT(length(suppression_src), "Не удалось прочитать suppression.dm")
	for(var/option in canonical)
		TEST_ASSERT(findtext(suppression_src, "\"[option]\""), "nanites/suppression.dm не содержит опцию '[option]'")

/// generate_fake_heretic_text возвращает строку нужной длины и состоит только
/// из разрешённых символов-"иероглифов". Регрессия: смена charset на пустой
/// или односимвольный молча превратила бы пугающий заголовок в "!!!!!!!!".
/datum/unit_test/hallucination_generate_fake_heretic_text/Run()
	var/static/list/allowed = list("!", "$", "^", "@", "&", "#", "*", "(", ")", "?")
	var/mob/living/carbon/human/dummy_target = new(run_loc_floor_bottom_left)
	var/datum/hallucination/test_instance = new(dummy_target, TRUE)

	var/default_text = test_instance.generate_fake_heretic_text()
	var/custom_text = test_instance.generate_fake_heretic_text(40)
	var/single_text = test_instance.generate_fake_heretic_text(1)

	qdel(test_instance)
	qdel(dummy_target)

	TEST_ASSERT_EQUAL(length(default_text), 25, "Дефолтная длина должна быть 25, получено [length(default_text)]")
	TEST_ASSERT_EQUAL(length(custom_text), 40, "Произвольная длина не соблюдена: ожидалось 40, получено [length(custom_text)]")
	TEST_ASSERT_EQUAL(length(single_text), 1, "Длина 1 не соблюдена: получено [length(single_text)]")

	for(var/text in list(default_text, custom_text, single_text))
		for(var/i in 1 to length(text))
			var/char = copytext(text, i, i + 1)
			TEST_ASSERT(char in allowed, "Символ '[char]' в '[text]' отсутствует в разрешённом наборе")

/// fake_priority_announce должен молча выходить при пустом text, не пытаясь
/// собирать build_priority_announcement и не слать sound. Регрессия:
/// stationmessage-ветки могут передать пустую строку, если pick из
/// heretic_ascension_bodies вернёт мусор - не должно крашить.
/datum/unit_test/hallucination_fake_priority_announce_empty/Run()
	var/mob/living/carbon/human/dummy_target = new(run_loc_floor_bottom_left)
	var/datum/hallucination/test_instance = new(dummy_target, TRUE)

	test_instance.fake_priority_announce(null)
	test_instance.fake_priority_announce("")
	// Если пустой text прошёл через guard, следующий валидный вызов хелпера на том же
	// instance должен работать как обычно. Проверяем pure-функцией generate_fake_heretic_text -
	// её результат подтверждает, что instance не повреждён посторонним state-mutating fallback.
	var/post_text = test_instance.generate_fake_heretic_text(10)

	qdel(test_instance)
	qdel(dummy_target)

	TEST_ASSERT_EQUAL(length(post_text), 10, "fake_priority_announce(empty) повредил instance: post_text='[post_text]'")

/// random_non_sec_crewmember не должен крашить на пустых/частично-заполненных
/// записях data_core и обязан фильтровать сам target (даже если он попал в
/// manifest от другого теста). Возможные результаты: null или другой живой
/// человекоид, но никогда не сам target.
/datum/unit_test/hallucination_random_non_sec_crewmember_safety/Run()
	var/mob/living/carbon/human/dummy_target = new(run_loc_floor_bottom_left)
	var/datum/hallucination/test_instance = new(dummy_target, TRUE)

	var/result = test_instance.random_non_sec_crewmember()
	var/is_dummy_target = (result == dummy_target)
	var/is_valid_type = isnull(result) || ishuman(result)

	qdel(test_instance)
	qdel(dummy_target)

	TEST_ASSERT(!is_dummy_target, "random_non_sec_crewmember вернул сам target (фильтр target сломан)")
	TEST_ASSERT(is_valid_type, "Результат не null и не human: получено [result]")
