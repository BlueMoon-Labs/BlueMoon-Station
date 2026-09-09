/// Запись savefile синхронная: она морозит весь процесс, а не только вызывающего.
/// Поэтому пачку правок склеивают в одну отложенную запись. Перенос обязан быть
/// ограниченным - без крайнего срока игрок, который щёлкает настройки чаще
/// кулдауна, перевзводит таймер бесконечно и не сохраняется до самого логаута.
/datum/unit_test/preferences_save_deferral

/datum/unit_test/preferences_save_deferral/Run()
	var/datum/preferences/prefs = new
	prefs.load_path("unit_test_save_deferral")

	prefs.queue_save_pref(PREF_SAVE_COOLDOWN, TRUE)
	TEST_ASSERT_NOTNULL(prefs.pref_queue, "первая постановка в очередь не зарядила таймер записи префов")
	var/first_pref_timer = prefs.pref_queue
	var/first_pref_deadline = prefs.pref_queue_deadline
	TEST_ASSERT(first_pref_deadline > world.time, "крайний срок отложенной записи префов не выставлен")

	prefs.queue_save_pref(PREF_SAVE_COOLDOWN, TRUE)
	TEST_ASSERT_NOTEQUAL(prefs.pref_queue, first_pref_timer, "правка до крайнего срока не перенесла запись префов")
	TEST_ASSERT_EQUAL(prefs.pref_queue_deadline, first_pref_deadline, "перенос сдвинул крайний срок записи префов")

	// Крайний срок наступил: заряженный таймер обязан доработать как есть.
	prefs.pref_queue_deadline = world.time - 1
	var/pinned_pref_timer = prefs.pref_queue
	prefs.queue_save_pref(PREF_SAVE_COOLDOWN, TRUE)
	TEST_ASSERT_EQUAL(prefs.pref_queue, pinned_pref_timer, "запись префов перенесли после крайнего срока")

	prefs.queue_save_char(PREF_SAVE_COOLDOWN, TRUE)
	TEST_ASSERT_NOTNULL(prefs.char_queue, "первая постановка в очередь не зарядила таймер записи персонажа")
	var/first_char_timer = prefs.char_queue
	var/first_char_deadline = prefs.char_queue_deadline
	TEST_ASSERT(first_char_deadline > world.time, "крайний срок отложенной записи персонажа не выставлен")

	prefs.queue_save_char(PREF_SAVE_COOLDOWN, TRUE)
	TEST_ASSERT_NOTEQUAL(prefs.char_queue, first_char_timer, "правка до крайнего срока не перенесла запись персонажа")

	prefs.char_queue_deadline = world.time - 1
	var/pinned_char_timer = prefs.char_queue
	prefs.queue_save_char(PREF_SAVE_COOLDOWN, TRUE)
	TEST_ASSERT_EQUAL(prefs.char_queue, pinned_char_timer, "запись персонажа перенесли после крайнего срока")

	// Тест не должен оставлять за собой запись на диск.
	deltimer(prefs.pref_queue)
	deltimer(prefs.char_queue)
	prefs.pref_queue = null
	prefs.char_queue = null
	qdel(prefs)
