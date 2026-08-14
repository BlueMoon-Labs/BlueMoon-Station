/// Правки префов от живого клиента обязаны склеиваться в одну запись на диск.
///
/// Запись savefile синхронная: она морозит ВЕСЬ процесс, а не вызывающего. Замер по
/// 16 прод-раундам (2026-08-12/13): 79 280 таких записей на 443 секунды заморозки,
/// то есть 15-32% суммарного дрифта спайков по аттрибуции самого сервера. Замер в
/// DM показал, что одна WRITE_FILE стоит 0.016 мс - платим за поход на диск, а не за
/// две сотни полей, поэтому лечится только число походов.
///
/// Прежний гейт откладывал ТОЛЬКО попадание в двухсекундный кулдаун, а игрок в меню
/// создания персонажа щёлкает медленнее двух секунд: почти каждый клик уходил в
/// отдельную запись.
///
/// Живой /client в юнит-тесте не создать, поэтому решение "откладывать" вынесено в
/// should_defer_saves() и здесь подменяется.
/datum/preferences/unit_test_debounce
	/// Сколько раз реально дошли до записи на диск.
	var/disk_writes = 0

/datum/preferences/unit_test_debounce/should_defer_saves()
	return TRUE

/datum/preferences/unit_test_debounce/save_preferences(bypass_cooldown = FALSE, silent = FALSE)
	if(bypass_cooldown)
		disk_writes++
		// До настоящего savefile не доводим: тест про то, СКОЛЬКО раз сюда дошли.
		if(pref_queue)
			deltimer(pref_queue)
		pref_queue = null
		pref_queue_deadline = 0
		return TRUE
	return ..()

/datum/unit_test/preferences_save_debounce

/datum/unit_test/preferences_save_debounce/Run()
	var/datum/preferences/unit_test_debounce/prefs = new
	prefs.load_path("unit_test_save_debounce")

	// Пачка правок подряд - ровно то, что делает игрок в меню настроек.
	for(var/i in 1 to 10)
		prefs.save_preferences()

	TEST_ASSERT_EQUAL(prefs.disk_writes, 0, "правка от клиента ушла на диск сразу, вместо дебаунса")
	TEST_ASSERT_NOTNULL(prefs.pref_queue, "пачка правок не зарядила отложенную запись")
	var/deadline = prefs.pref_queue_deadline
	TEST_ASSERT(deadline > world.time, "крайний срок отложенной записи не выставлен")

	// Ещё пачка: таймер переносится, но крайний срок НЕ уезжает - иначе игрок,
	// который щёлкает чаще кулдауна, не сохранится до самого логаута.
	for(var/i in 1 to 10)
		prefs.save_preferences()
	TEST_ASSERT_EQUAL(prefs.disk_writes, 0, "вторая пачка правок пробила дебаунс")
	TEST_ASSERT_EQUAL(prefs.pref_queue_deadline, deadline, "перенос сдвинул крайний срок записи")

	// Логаут обязан довести отложенное до диска: ребут мира таймеры не доигрывает.
	prefs.flush_pending_saves()
	TEST_ASSERT_EQUAL(prefs.disk_writes, 1, "сброс на логауте не довёл отложенную запись до диска")
	TEST_ASSERT_NULL(prefs.pref_queue, "сброс не снял отложенный таймер")

	// Двадцать правок сложились в одну запись - это и есть предмет теста.
	prefs.pref_queue = null
	prefs.char_queue = null
	qdel(prefs)
