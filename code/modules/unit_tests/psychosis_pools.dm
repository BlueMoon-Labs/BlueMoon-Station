// Тесты инвариантов psychosis-tier-системы.
// Запуск: node tools/build/build.js dm-test, проверка data/logs/ci/clean_run.lk.

/// Все типы из psychosis_hallucination_list имеют валидный severity (1..3).
/datum/unit_test/psychosis_severity_in_range/Run()
	for(var/type in GLOB.psychosis_hallucination_list)
		var/datum/hallucination/psychosis/proto = type
		var/sev = initial(proto.severity)
		TEST_ASSERT(sev >= PSYCHOSIS_TIER_MILD && sev <= PSYCHOSIS_TIER_SEVERE, "Тип [type] имеет severity=[sev], ожидалось [PSYCHOSIS_TIER_MILD]..[PSYCHOSIS_TIER_SEVERE]")

/// build_psychosis_tier_pools раскладывает все типы по 3 пулам без потерь.
/datum/unit_test/psychosis_pool_build_complete/Run()
	build_psychosis_tier_pools()
	TEST_ASSERT_EQUAL(length(GLOB.psychosis_pool_by_tier), 3, "Ожидалось 3 пула")
	var/total = 0
	for(var/i in 1 to 3)
		total += length(GLOB.psychosis_pool_by_tier[i])
	TEST_ASSERT_EQUAL(total, length(GLOB.psychosis_hallucination_list), "Сумма по пулам != количество типов в master-листе")

/// Все строки в themes у каждого типа должны быть в GLOB.psychosis_themes.
/datum/unit_test/psychosis_themes_known/Run()
	for(var/type in GLOB.psychosis_hallucination_list)
		var/datum/hallucination/psychosis/proto = type
		var/list/type_themes = initial(proto.themes)
		if(!type_themes)
			continue
		for(var/theme in type_themes)
			TEST_ASSERT(theme in GLOB.psychosis_themes, "Тип [type] имеет неизвестную тему [theme]")

/// Picker не выдаёт MODERATE/SEVERE до достижения соответствующих порогов.
/datum/unit_test/psychosis_picker_respects_tier/Run()
	var/mob/living/carbon/human/H = allocate(/mob/living/carbon/human)
	H.apply_psychosis(5 MINUTES)
	var/datum/status_effect/psychosis/eff = H.has_status_effect(/datum/status_effect/psychosis)
	TEST_ASSERT_NOTNULL(eff, "Status effect не применился")
	eff.state_started = world.time  // только что начался: только MILD
	for(var/i in 1 to 100)
		var/picked = eff.pick_hallucination()
		TEST_ASSERT_NOTNULL(picked, "Picker вернул null")
		var/datum/hallucination/psychosis/proto = picked
		TEST_ASSERT_EQUAL(initial(proto.severity), PSYCHOSIS_TIER_MILD, "Picker выдал не-MILD ([picked]) при elapsed=0")

/// distort_message не должна менять строку, в которой нет известных токенов.
/datum/unit_test/psychosis_distort_unknown_unchanged/Run()
	var/result = distort_message("foo bar baz")
	TEST_ASSERT_EQUAL(result, "foo bar baz", "distort_message испортила строку без известных токенов")

/// distort_message подменяет известный токен на одну из заявленных опций.
/datum/unit_test/psychosis_distort_known_replaces/Run()
	var/result = distort_message("hello world")
	var/list/valid = list("hello world", "help world", "behind world")
	TEST_ASSERT(result in valid, "distort_message вернула неожиданный результат '[result]'")
	var/changed = FALSE
	for(var/i in 1 to 50)
		if(distort_message("hello world") != "hello world")
			changed = TRUE
			break
	TEST_ASSERT(changed, "distort_message ни разу не подменила за 50 попыток")

/// distort_message должна находить токен независимо от регистра и реально
/// заменять его в исходной строке (защита от регрессии: раньше lookup был
/// case-insensitive, а replacetextEx - case-sensitive, "Hello" не менялся).
/datum/unit_test/psychosis_distort_case_insensitive/Run()
	var/changed = FALSE
	for(var/i in 1 to 50)
		var/result = distort_message("Hello world")
		if(result != "Hello world")
			changed = TRUE
			break
	TEST_ASSERT(changed, "distort_message не заменила 'Hello' за 50 попыток (case-sensitivity регрессия)")

/// distort_message не должна подменять ключи внутри более длинных слов
/// (регрессия: findtext ловил "ok" в "broken", "да" в "дать", "yes" в "yesterday").
/datum/unit_test/psychosis_distort_word_boundary/Run()
	var/list/should_not_match = list(
		"broken token okay",         // "ok" как подстрока broken/okay
		"yesterday was eyes",        // "yes" внутри yesterday/eyes
		"эта дача дать удар",        // "да" внутри дача/дать/удар
		"привета не было",           // "привет" с суффиксом "а"
	)
	for(var/sample in should_not_match)
		for(var/i in 1 to 30)
			var/result = distort_message(sample)
			TEST_ASSERT_EQUAL(result, sample, "distort_message подменила что-то в '[sample]' (получено '[result]') - сработал substring match вместо token")

/// apply_psychosis(-1) должен ставить бесконечную длительность, а не дефолтные
/// 5 минут (регрессия: on_creation отфильтровывал -1 проверкой set_duration > 0).
/datum/unit_test/psychosis_apply_infinite_duration/Run()
	var/mob/living/carbon/human/H = allocate(/mob/living/carbon/human)
	H.apply_psychosis(-1)
	var/datum/status_effect/psychosis/eff = H.has_status_effect(/datum/status_effect/psychosis)
	TEST_ASSERT_NOTNULL(eff, "apply_psychosis(-1) не применил эффект")
	TEST_ASSERT_EQUAL(eff.duration, -1, "apply_psychosis(-1) дал duration=[eff.duration], ожидался -1 (бесконечная)")
	// Refresh с -1 на уже существующем эффекте тоже должен дать -1.
	H.apply_psychosis(-1)
	var/datum/status_effect/psychosis/refreshed = H.has_status_effect(/datum/status_effect/psychosis)
	TEST_ASSERT_EQUAL(refreshed.duration, -1, "refresh(-1) дал duration=[refreshed.duration], ожидался -1")

/// apply_psychosis на уже активном эффекте должен обновить duration/theme
/// (раньше базовый refresh() игнорировал аргументы и сбрасывал длительность
/// на initial(duration) = 5 минут, теряя данные повторной psi-волны).
/datum/unit_test/psychosis_refresh_updates_duration_theme/Run()
	var/mob/living/carbon/human/H = allocate(/mob/living/carbon/human)
	H.apply_psychosis(2 MINUTES, PSYCHOSIS_THEME_MASSACRE)
	var/datum/status_effect/psychosis/eff = H.has_status_effect(/datum/status_effect/psychosis)
	TEST_ASSERT_NOTNULL(eff, "Первичный apply_psychosis не сработал")
	TEST_ASSERT_EQUAL(eff.current_theme, PSYCHOSIS_THEME_MASSACRE, "Первичная тема не установилась")
	var/expected_after_first = world.time + (2 MINUTES)
	var/delta_first = abs(eff.duration - expected_after_first)
	TEST_ASSERT(delta_first <= 5, "Первичный duration вне допуска: [eff.duration] vs ~[expected_after_first]")
	H.apply_psychosis(45 SECONDS, PSYCHOSIS_THEME_STALKER)
	var/datum/status_effect/psychosis/refreshed = H.has_status_effect(/datum/status_effect/psychosis)
	TEST_ASSERT_EQUAL(refreshed, eff, "После refresh подменился сам датум, ожидался тот же объект")
	TEST_ASSERT_EQUAL(refreshed.current_theme, PSYCHOSIS_THEME_STALKER, "Refresh не обновил тему")
	var/expected_after_refresh = world.time + (45 SECONDS)
	var/delta_refresh = abs(refreshed.duration - expected_after_refresh)
	TEST_ASSERT(delta_refresh <= 5, "Refresh duration вне допуска: [refreshed.duration] vs ~[expected_after_refresh]")

/// refresh() должен снимать HEAR-listener вместе со сбросом state_started.
/// Регрессия: раньше после повторной волны игрок мгновенно откатывался на
/// MILD-пул эффектов, но mishearing/wrong_voice продолжали срабатывать,
/// потому что подписка на COMSIG_MOVABLE_HEAR оставалась с прошлого тира.
/datum/unit_test/psychosis_refresh_resets_hear_listener/Run()
	var/mob/living/carbon/human/H = allocate(/mob/living/carbon/human)
	H.apply_psychosis(2 MINUTES)
	var/datum/status_effect/psychosis/eff = H.has_status_effect(/datum/status_effect/psychosis)
	TEST_ASSERT_NOTNULL(eff, "apply_psychosis не сработал")
	eff.register_passive_listeners()
	TEST_ASSERT(eff.hear_listener_active, "register_passive_listeners не выставил флаг")
	H.apply_psychosis(45 SECONDS)
	TEST_ASSERT(!eff.hear_listener_active, "refresh не сбросил hear_listener_active")
