/// Правки префов от живого клиента обязаны склеиваться в одну запись на диск.
///
/// Запись savefile синхронная: она морозит ВЕСЬ процесс, а не вызывающего. Замер по
/// 16 прод-раундам (2026-08-12/13): 79 280 таких записей на 443 секунды заморозки,
/// то есть 15-32% суммарного дрифта спайков по аттрибуции самого сервера. Это
/// НАСТЕННОЕ время всего вызова целиком - открытие savefile, все поля, сброс на
/// диск, - то есть в среднем 5.6 мс на одну запись.
///
/// Отдельный замер в DM дал 0.016 мс на одну WRITE_FILE, и это только запись поля в
/// уже открытый savefile. Полей в save_preferences 122, в save_character 174, то
/// есть на них уходит около 2.4 мс из тех 5.6 - примерно половина, вторая половина
/// это открытие файла и сброс. Отсюда вывод: дешевле поля не сделать, и лечится
/// только ЧИСЛО вызовов - оно убирает обе половины разом.
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

/// Половина фичи - это очередь ПЕРСОНАЖА, и без этой подмены она не только не
/// проверялась, но и уходила в настоящую запись на диск прямо из юнит-теста.
/datum/preferences/unit_test_debounce/save_character(bypass_cooldown = FALSE, silent = FALSE, export = FALSE)
	if(bypass_cooldown)
		disk_writes++
		if(char_queue)
			deltimer(char_queue)
		char_queue = null
		char_queue_deadline = 0
		return TRUE
	return ..()

/// Сколько правок подряд имитирует одна пачка. Игрок в меню настроек щёлкает
/// именно так - подряд и чаще кулдауна.
#define PREF_DEBOUNCE_TEST_BATCH 10

/datum/unit_test/preferences_save_debounce

/datum/unit_test/preferences_save_debounce/Run()
	var/datum/preferences/unit_test_debounce/prefs = new
	prefs.load_path("unit_test_save_debounce")
	// New() закрепляет случайного персонажа на диске СРАЗУ (save_preferences(TRUE)
	// и save_character(TRUE)) - иначе следующий заход сгенерировал бы другого. Это
	// не дебаунс, а его штатное исключение, поэтому счётчик обнуляем.
	TEST_ASSERT_EQUAL(prefs.disk_writes, 2, "первичное создание префов перестало писать случайного персонажа на диск сразу")
	prefs.disk_writes = 0

	// Пачка правок подряд - ровно то, что делает игрок в меню настроек.
	for(var/i in 1 to PREF_DEBOUNCE_TEST_BATCH)
		prefs.save_preferences()

	TEST_ASSERT_EQUAL(prefs.disk_writes, 0, "правка от клиента ушла на диск сразу, вместо дебаунса")
	TEST_ASSERT_NOTNULL(prefs.pref_queue, "пачка правок не зарядила отложенную запись")
	var/deadline = prefs.pref_queue_deadline
	TEST_ASSERT(deadline > world.time, "крайний срок отложенной записи не выставлен")

	// Ещё пачка: таймер переносится, но крайний срок НЕ уезжает - иначе игрок,
	// который щёлкает чаще кулдауна, не сохранится до самого логаута.
	for(var/i in 1 to PREF_DEBOUNCE_TEST_BATCH)
		prefs.save_preferences()
	TEST_ASSERT_EQUAL(prefs.disk_writes, 0, "вторая пачка правок пробила дебаунс")
	TEST_ASSERT_EQUAL(prefs.pref_queue_deadline, deadline, "перенос сдвинул крайний срок записи")

	// Очередь ПЕРСОНАЖА - вторая половина фичи, со своим таймером и своим сроком.
	// Правки слота идут по ней, и в проде их не меньше, чем правок настроек.
	for(var/i in 1 to PREF_DEBOUNCE_TEST_BATCH)
		prefs.save_character()
	TEST_ASSERT_EQUAL(prefs.disk_writes, 0, "правка персонажа ушла на диск сразу, вместо дебаунса")
	TEST_ASSERT_NOTNULL(prefs.char_queue, "пачка правок персонажа не зарядила отложенную запись")
	var/char_deadline = prefs.char_queue_deadline
	TEST_ASSERT(char_deadline > world.time, "крайний срок отложенной записи персонажа не выставлен")
	for(var/i in 1 to PREF_DEBOUNCE_TEST_BATCH)
		prefs.save_character()
	TEST_ASSERT_EQUAL(prefs.disk_writes, 0, "вторая пачка правок персонажа пробила дебаунс")
	TEST_ASSERT_EQUAL(prefs.char_queue_deadline, char_deadline, "перенос сдвинул крайний срок записи персонажа")

	// Логаут обязан довести отложенное до диска: ребут мира таймеры не доигрывает.
	// Очередей две, значит и записей две.
	prefs.flush_pending_saves()
	TEST_ASSERT_EQUAL(prefs.disk_writes, 2, "сброс на логауте не довёл обе отложенные записи до диска")
	TEST_ASSERT_NULL(prefs.pref_queue, "сброс не снял отложенный таймер настроек")
	TEST_ASSERT_NULL(prefs.char_queue, "сброс не снял отложенный таймер персонажа")
	// Снятая очередь с невыставленным сроком - это протухший крайний срок: следующая
	// постановка сверится с ним и решит, что срок давно наступил.
	TEST_ASSERT_EQUAL(prefs.pref_queue_deadline, 0, "сброс снял очередь настроек, но оставил крайний срок")
	TEST_ASSERT_EQUAL(prefs.char_queue_deadline, 0, "сброс снял очередь персонажа, но оставил крайний срок")

	// Load обязан снять очередь БЕЗ записи, иначе колбэк затрёт прочитанный слот.
	prefs.save_preferences()
	prefs.save_character()
	TEST_ASSERT_NOTNULL(prefs.pref_queue, "правка после сброса не зарядила новую очередь настроек")
	TEST_ASSERT_NOTNULL(prefs.char_queue, "правка после сброса не зарядила новую очередь персонажа")
	prefs.cancel_pending_saves()
	TEST_ASSERT_NULL(prefs.pref_queue, "Load не снял отложенный таймер настроек")
	TEST_ASSERT_NULL(prefs.char_queue, "Load не снял отложенный таймер персонажа")
	TEST_ASSERT_EQUAL(prefs.pref_queue_deadline, 0, "отмена сняла очередь настроек, но оставила крайний срок")
	TEST_ASSERT_EQUAL(prefs.char_queue_deadline, 0, "отмена сняла очередь персонажа, но оставила крайний срок")
	TEST_ASSERT_EQUAL(prefs.disk_writes, 2, "отмена очереди не должна писать на диск")

	// Явный Save бьёт в диск сразу - обоими путями.
	prefs.save_preferences(TRUE)
	TEST_ASSERT_EQUAL(prefs.disk_writes, 3, "явный Save настроек не пробил дебаунс")
	prefs.save_character(TRUE)
	TEST_ASSERT_EQUAL(prefs.disk_writes, 4, "явный Save персонажа не пробил дебаунс")

	// Уборка: снимаем очереди штатным проком, пока датум ещё жив. Голое обнуление
	// полей оставило бы заряженные таймеры, которые потом сработают на удалённых
	// префах.
	prefs.cancel_pending_saves()
	qdel(prefs)

#undef PREF_DEBOUNCE_TEST_BATCH
