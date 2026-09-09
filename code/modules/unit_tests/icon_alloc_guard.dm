/**
 * Учёт провалившихся сборок иконок.
 *
 * Прибор написан по каскаду падений 23.08.2026 (раунды 10084-10090): мир умирал рантаймом
 * в `/icon/New()` при 2.5-3.0 ГБ, то есть с запасом больше гигабайта до потолка адресного
 * пространства, и ни лестница памяти, ни обработчик "Out of resources!" не срабатывали.
 * Самого отказа аллокации в тесте не воспроизвести, поэтому проверяется всё остальное:
 * счётчик, единственность тревоги и подменная иконка, которую вызывающий отдаёт наружу
 * вместо оборванного стека.
 */
/datum/unit_test/icon_alloc_guard/Run()
	var/cached_failures = GLOB.icon_alloc_failures
	var/cached_warned = GLOB.icon_alloc_admins_warned
	var/cached_note = Master.state_snapshot_note

	GLOB.icon_alloc_failures = 0
	GLOB.icon_alloc_admins_warned = FALSE
	Master.state_snapshot_note = null

	var/icon/first = note_icon_alloc_failure("юнит-тест: первый отказ")
	var/failures_after_first = GLOB.icon_alloc_failures
	var/warned_after_first = GLOB.icon_alloc_admins_warned
	var/note_after_first = Master.state_snapshot_note
	note_icon_alloc_failure("юнит-тест: второй отказ")
	var/failures_after_second = GLOB.icon_alloc_failures

	// Восстанавливается ДО проверок: упавший TEST_ASSERT возвращается из прока, и
	// оставленная отметка уехала бы в чёрный ящик всему остатку прогона.
	GLOB.icon_alloc_failures = cached_failures
	GLOB.icon_alloc_admins_warned = cached_warned
	Master.state_snapshot_note = cached_note

	TEST_ASSERT_EQUAL(failures_after_first, 1, "Первый провал не посчитан - колонка perf-лога останется пустой")
	TEST_ASSERT_EQUAL(failures_after_second, 2, "Провалы не накапливаются")
	TEST_ASSERT(warned_after_first, "Первый провал не поднял тревогу админам")
	TEST_ASSERT(isicon(first), "Вместо подменной иконки вызывающему вернулось [first || "ничего"]")
	// Подмена обязана быть заведена заранее: собирать иконку в обработчике неудавшейся
	// сборки иконки - это тот же запрос к той же куче в тот же момент.
	TEST_ASSERT(first == GLOB.icon_alloc_placeholder, "Подменная иконка собирается по месту отказа, а не берётся из готовой глобалки")
	// Мир после такого отказа живёт секунды, а буфер логов гибнет вместе с процессом:
	// отметка в чёрном ящике - единственное, что переживает смерть и доезжает до
	// лога следующего раунда.
	TEST_ASSERT_NOTNULL(note_after_first, "Провал не оставил отметки в чёрном ящике МК")
	TEST_ASSERT(findtext(note_after_first, "первый отказ"), "В отметке чёрного ящика нет описания провала: [note_after_first]")
