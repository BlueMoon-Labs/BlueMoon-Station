/**
 * Склейка одиночных записей в савфайл префов.
 *
 * Запись savefile синхронная: она морозит весь процесс, а не только вызывающего.
 * Раунд 10137 дал 6230 таких заморозок на 32.8 секунды - 30-34% всего дрифта спайков;
 * после того как панель tgui и прогресс лоадаута перевели с полного save_preferences
 * (~124 WRITE_FILE) на запись одного ключа, раунд 10146 дал 3712 на 21.1 секунды, то
 * есть 23% дрифта. Записей стало вдвое меньше, а средняя цена ОДНОЙ выросла с 5.3 до
 * 5.7 мс: значит платим не за WRITE_FILE, а за ОТКРЫТИЕ файла, и резать надо число
 * открытий. Отсюда буфер склейки - поток правок копится в памяти и уходит на диск
 * одним открытием.
 *
 * Тесты гоняют чистые функции решения и ту половину save_single_pref, которая на диск
 * не ходит вовсе: буфер и таймер. Живой мир и савфайл им не нужны.
 */

/**
 * Буфер обязан схлопывать повтор ключа и копить разные ключи.
 *
 * Швабра (mop.dm) дёргает прогресс лоадаута на КАЖДУЮ отмытую плитку, панель tgui шлёт
 * состояние чата раз в три секунды. Оба потока - это один и тот же ключ снова и снова:
 * на диск обязана уходить только последняя версия.
 */
/datum/unit_test/preferences_single_pref_absorb

/datum/unit_test/preferences_single_pref_absorb/Run()
	var/list/pending = list()

	TEST_ASSERT(!pref_pending_absorb(pending, "tgui_panel_state", "{\"v\":1}"), "первая запись ключа не может считаться склейкой")
	TEST_ASSERT_EQUAL(length(pending), 1, "первая запись не попала в буфер")

	TEST_ASSERT(pref_pending_absorb(pending, "tgui_panel_state", "{\"v\":2}"), "повтор ключа обязан отчитаться о склейке")
	TEST_ASSERT_EQUAL(length(pending), 1, "повтор ключа раздул буфер вместо склейки")
	TEST_ASSERT_EQUAL(pending["tgui_panel_state"], "{\"v\":2}", "склейка обязана оставить последнее значение, а не первое")

	TEST_ASSERT(!pref_pending_absorb(pending, "tgui_panel_theme", "dark"), "другой ключ не является склейкой")
	TEST_ASSERT_EQUAL(length(pending), 2, "разные ключи обязаны копиться в одном буфере: это одно открытие файла на оба")

	// Наличие проверяется по КЛЮЧУ, а не по значению: null в DM не равен нулю и не
	// отличим от отсутствующего ключа, если смотреть на pending[key].
	TEST_ASSERT(!pref_pending_absorb(pending, "ticket_nickname", null), "новый ключ со значением null принят за уже лежащий в буфере")
	TEST_ASSERT_EQUAL(length(pending), 3, "ключ со значением null не попал в буфер")
	TEST_ASSERT(pref_pending_absorb(pending, "ticket_nickname", null), "повтор ключа со значением null не опознан как склейка")
	TEST_ASSERT_EQUAL(length(pending), 3, "повтор ключа со значением null раздул буфер")

	// Мусор на входе не должен ронять запись префов.
	TEST_ASSERT(!pref_pending_absorb(null, "tgui_panel_state", "x"), "отсутствие буфера обязано вернуть FALSE, а не рантайм")
	TEST_ASSERT(!pref_pending_absorb(pending, null, "x"), "пустой ключ обязан вернуть FALSE")
	TEST_ASSERT_EQUAL(length(pending), 3, "пустой ключ попал в буфер")

/**
 * Решение о переносе отложенной записи.
 *
 * Перенос обязан быть ограниченным: без крайнего срока игрок, который правит настройки
 * чаще окна склейки, перевзводит таймер бесконечно и не сохраняется до самого логаута.
 * Незаряженный срок (0 или null) при этом НЕ считается истёкшим - иначе первая же
 * правка после зарядки таймера намертво прибивала бы сброс к старому таймеру.
 */
/datum/unit_test/preferences_single_pref_defer_decision

/datum/unit_test/preferences_single_pref_defer_decision/Run()
	TEST_ASSERT_EQUAL(pref_defer_decision(null, 0, 100), PREF_DEFER_ARM, "пустая очередь обязана заряжать таймер")
	TEST_ASSERT_EQUAL(pref_defer_decision("timer_id", 200, 100), PREF_DEFER_RESCHEDULE, "правка до крайнего срока обязана переносить сброс")
	TEST_ASSERT_EQUAL(pref_defer_decision("timer_id", 100, 100), PREF_DEFER_KEEP, "ровно на крайнем сроке перенос уже запрещён")
	TEST_ASSERT_EQUAL(pref_defer_decision("timer_id", 99, 100), PREF_DEFER_KEEP, "после крайнего срока перенос запрещён")
	TEST_ASSERT_EQUAL(pref_defer_decision("timer_id", 0, 100), PREF_DEFER_RESCHEDULE, "нулевой (незаряженный) срок нельзя считать истёкшим")
	TEST_ASSERT_EQUAL(pref_defer_decision("timer_id", null, 100), PREF_DEFER_RESCHEDULE, "null-срок нельзя считать истёкшим: null не равен нулю")

/**
 * Буферизация на живом датуме префов: склейка, перенос сброса и крайний срок.
 *
 * Гоняется buffer_single_pref - половина save_single_pref без единого похода на диск.
 * Путь до savefile проверять тут нечем и незачем: он отличается от старого только тем,
 * что открывает файл один раз на весь буфер.
 */
/datum/unit_test/preferences_single_pref_deferral

/datum/unit_test/preferences_single_pref_deferral/Run()
	var/datum/preferences/prefs = new

	prefs.buffer_single_pref("tgui_panel_state", "{\"v\":1}")
	TEST_ASSERT_NOTNULL(prefs.single_pref_queue, "первая одиночная запись не зарядила сброс буфера")
	TEST_ASSERT_EQUAL(length(prefs.pending_single_prefs), 1, "первая одиночная запись не попала в буфер")
	var/first_timer = prefs.single_pref_queue
	var/first_deadline = prefs.single_pref_queue_deadline
	TEST_ASSERT(first_deadline > world.time, "крайний срок сброса буфера не выставлен")

	prefs.buffer_single_pref("tgui_panel_state", "{\"v\":2}")
	TEST_ASSERT_EQUAL(length(prefs.pending_single_prefs), 1, "повтор того же ключа не схлопнулся в буфере")
	TEST_ASSERT_NOTEQUAL(prefs.single_pref_queue, first_timer, "правка до крайнего срока не перенесла сброс буфера")
	TEST_ASSERT_EQUAL(prefs.single_pref_queue_deadline, first_deadline, "перенос сдвинул крайний срок сброса буфера")

	prefs.buffer_single_pref("tgui_panel_theme", "dark")
	TEST_ASSERT_EQUAL(length(prefs.pending_single_prefs), 2, "разные ключи обязаны уехать на диск одним открытием файла")

	// Крайний срок наступил: заряженный таймер обязан доработать как есть.
	prefs.single_pref_queue_deadline = world.time - 1
	var/pinned_timer = prefs.single_pref_queue
	prefs.buffer_single_pref("tgui_panel_state", "{\"v\":3}")
	TEST_ASSERT_EQUAL(prefs.single_pref_queue, pinned_timer, "сброс буфера перенесли после крайнего срока")
	TEST_ASSERT_EQUAL(prefs.pending_single_prefs["tgui_panel_state"], "{\"v\":3}", "правка после крайнего срока не попала в буфер")

	// Тест не должен оставлять за собой запись на диск.
	deltimer(prefs.single_pref_queue)
	prefs.single_pref_queue = null
	prefs.pending_single_prefs = null
	qdel(prefs)

/**
 * Полная запись префов уже в очереди - второй таймер заводить нельзя.
 *
 * Полный save_preferences открывает тот же самый савфайл и дописывает буфер в конце,
 * так что отдельный сброс был бы ВТОРЫМ открытием на того же игрока за те же секунды.
 */
/datum/unit_test/preferences_single_pref_reuses_full_save_queue

/datum/unit_test/preferences_single_pref_reuses_full_save_queue/Run()
	var/datum/preferences/prefs = new
	// Не настоящий таймер: buffer_single_pref обязан выйти раньше, чем дойдёт до
	// deltimer, а Destroy на мусорном id безопасен (deltimer не находит его и молчит).
	prefs.pref_queue = "фиктивный id полной записи"

	prefs.buffer_single_pref("tgui_panel_state", "{\"v\":1}")
	TEST_ASSERT_EQUAL(length(prefs.pending_single_prefs), 1, "правка не попала в буфер при заряженной полной записи")
	TEST_ASSERT_NULL(prefs.single_pref_queue, "при заряженной полной записи завели второй таймер - это второе открытие савфайла")
	TEST_ASSERT_EQUAL(prefs.single_pref_queue_deadline, 0, "при заряженной полной записи выставили крайний срок сброса буфера")

	prefs.pref_queue = null
	prefs.pending_single_prefs = null
	qdel(prefs)

/**
 * Сброс буфера обязан донести до диска КАЖДЫЙ накопленный ключ.
 *
 * Тут проверяется ровно то, ради чего склейка и затевалась: два ключа, одно открытие
 * савфайла, оба значения на месте. Ключ в WRITE_FILE(target[key], value) - переменная,
 * а не литерал; если бы индексирование савфайла переменной работало иначе, состояние
 * панели чата тихо перестало бы сохраняться, и заметили бы это только игроки.
 *
 * Единственный тест здесь, который трогает диск. Файл создаётся и удаляется до
 * ассертов: TEST_ASSERT делает return, и уборка после упавшего ассерта не выполнится.
 */
/datum/unit_test/preferences_single_pref_flush

/datum/unit_test/preferences_single_pref_flush/Run()
	var/datum/preferences/prefs = new
	prefs.load_path("unit_test_single_pref_flush")

	// Савфайл обязан существовать заранее: одиночная запись в новый файл создала бы
	// префы без "version", и загрузка приняла бы их за нулевую версию.
	var/savefile/seed = new /savefile(prefs.path)
	seed.cd = "/"
	WRITE_FILE(seed["version"], 0)
	seed = null

	prefs.buffer_single_pref("tgui_panel_theme", "dark")
	prefs.save_single_pref("tgui_panel_state", "{\"v\":7}", immediate = TRUE)

	var/leftover_keys = length(prefs.pending_single_prefs)
	var/leftover_timer = prefs.single_pref_queue

	var/savefile/readback = new /savefile(prefs.path)
	readback.cd = "/"
	var/written_theme
	var/written_state
	READ_FILE(readback["tgui_panel_theme"], written_theme)
	READ_FILE(readback["tgui_panel_state"], written_state)
	readback = null
	fdel(prefs.path)
	qdel(prefs)

	TEST_ASSERT_EQUAL(leftover_keys, 0, "сброс буфера не опустошил буфер: следующая запись ушла бы на диск повторно")
	TEST_ASSERT_NULL(leftover_timer, "сброс буфера не снял свой таймер")
	TEST_ASSERT_EQUAL(written_theme, "dark", "ключ, положенный в буфер первым, не доехал до диска")
	TEST_ASSERT_EQUAL(written_state, "{\"v\":7}", "ключ, положенный в буфер последним, не доехал до диска")
