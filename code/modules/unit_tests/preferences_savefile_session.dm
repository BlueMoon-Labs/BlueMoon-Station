/**
 * Savefile живого игрока держится открытым на пачку обращений, одиночные ключи уходят в журнал.
 *
 * Открытие savefile на линуксовом DreamDaemon - около 5 мс заморозки всего процесса при любом
 * размере файла, запись в открытый файл - десятки микросекунд. Тесты ниже проверяют, что данные
 * от этого не теряются: запись -> перечитывание другим датумом -> закрытие -> повторное открытие,
 * журнал после падения, устаревшие и оборванные блоки журнала.
 */

/datum/preferences/savefile_session_test
	session_savefile = TRUE

/datum/preferences/savefile_session_test/New(test_path)
	..(null)
	path = test_path
	vr_path = "[GLOB.log_directory]/savefile_session_vore"

/datum/preferences/savefile_session_test/Destroy(force)
	var/test_path = path
	. = ..()
	if(test_path)
		fdel(test_path)
		fdel("[test_path].journal")

/// Путь тестового сейва без остатков прошлого прогона.
/proc/savefile_session_test_path(name)
	var/test_path = "[GLOB.log_directory]/savefile_session_[name].sav"
	fdel(test_path)
	fdel("[test_path].journal")
	return test_path

/// Значение прямо с диска, отдельным хэндлом мимо открытых.
/proc/savefile_session_test_read(test_path, key, dir = "/")
	var/savefile/raw = new /savefile(test_path)
	raw.cd = dir
	var/value
	READ_FILE(raw[key], value)
	return value

/// Как читает файл следующий вход: новый датум без клиента.
/proc/savefile_session_test_reader(test_path)
	var/datum/preferences/reader = new
	reader.path = test_path
	reader.load_preferences(bypass_cooldown = TRUE)
	return reader

/// Падение сервера: префы пропали без слияния журнала, а следующий мир ничего не знает о файле.
/proc/savefile_session_test_crash(datum/preferences/prefs)
	var/test_path = prefs.path
	release_player_savefile(test_path, "тест")
	prefs.path = null
	qdel(prefs)
	GLOB.player_savefile_journal_bases -= test_path
	GLOB.player_savefile_journal_started -= test_path

/// Сколько вызовов такого вида детектор спайков записал в учёт блокирующих.
/proc/savefile_session_test_blocking_count(kind)
	var/list/bucket = SStick_spikes?.blocking_by_kind?[kind]
	return bucket ? bucket["count"] : 0

/// Пачка обращений одного игрока открывает файл один раз, а записанное видно всем и переживает закрытие.
/datum/unit_test/preferences_savefile_session_burst_opens_once

/datum/unit_test/preferences_savefile_session_burst_opens_once/Run()
	var/test_path = savefile_session_test_path("burst")
	var/datum/preferences/savefile_session_test/prefs = new(test_path)
	var/opens_before = GLOB.player_savefile_opens

	prefs.save_preferences(bypass_cooldown = TRUE, silent = TRUE)
	prefs.real_name = "Пачка Один"
	prefs.save_character(bypass_cooldown = TRUE, silent = TRUE, update_active_preset = FALSE)
	prefs.load_character(1, bypass_cooldown = TRUE)
	prefs.slot_names_cache = null
	prefs.get_slot_names()
	prefs.tgui_panel_theme = "dark"
	prefs.save_single_pref("tgui_panel_theme", prefs.tgui_panel_theme)
	prefs.flush_single_prefs()

	var/burst_opens = GLOB.player_savefile_opens - opens_before
	var/held_during_burst = !!GLOB.held_player_savefiles[test_path]
	var/journal_during_burst = fexists("[test_path].journal")
	var/other_theme = savefile_session_test_read(test_path, "tgui_panel_theme")
	var/other_name = savefile_session_test_read(test_path, "real_name", "/character1")

	prefs.release_savefile()
	var/held_after_release = !!GLOB.held_player_savefiles[test_path]
	var/datum/preferences/reader = savefile_session_test_reader(test_path)
	reader.load_character(1, bypass_cooldown = TRUE)
	var/reader_theme = reader.tgui_panel_theme
	var/reader_name = reader.real_name
	var/reader_held = !!GLOB.held_player_savefiles[test_path]
	qdel(reader)

	prefs.save_preferences(bypass_cooldown = TRUE, silent = TRUE)
	var/held_before_destroy = !!GLOB.held_player_savefiles[test_path]
	qdel(prefs)
	var/held_after_destroy = !!GLOB.held_player_savefiles[test_path]

	TEST_ASSERT_EQUAL(burst_opens, 1, "пачка из полной записи, персонажа, загрузки, имён слотов и сброса открыла файл не один раз")
	TEST_ASSERT(held_during_burst, "файл живого игрока закрылся посреди пачки")
	TEST_ASSERT(!journal_during_burst, "сброс в открытый файл ушёл в журнал")
	TEST_ASSERT_EQUAL(other_theme, "dark", "запись в открытый файл не видна другому хэндлу")
	TEST_ASSERT_EQUAL(other_name, "Пачка Один", "персонаж из открытого файла не виден другому хэндлу")
	TEST_ASSERT(!held_after_release, "release_savefile не закрыл файл")
	TEST_ASSERT_EQUAL(reader_theme, "dark", "одиночный ключ не пережил закрытие файла")
	TEST_ASSERT_EQUAL(reader_name, "Пачка Один", "персонаж не пережил закрытие файла")
	TEST_ASSERT(!reader_held, "файл держит открытым датум без клиента")
	TEST_ASSERT(held_before_destroy, "повторная запись не открыла файл снова")
	TEST_ASSERT(!held_after_destroy, "снос префов оставил файл открытым")

/// Открытыми остаются не больше PLAYER_SAVEFILE_HOLD_MAX файлов, простаивающие закрываются.
/datum/unit_test/preferences_savefile_session_hold_is_bounded

/datum/unit_test/preferences_savefile_session_hold_is_bounded/Run()
	var/list/sessions = list()
	for(var/index in 1 to PLAYER_SAVEFILE_HOLD_MAX + 2)
		var/datum/preferences/savefile_session_test/prefs = new(savefile_session_test_path("bounded_[index]"))
		prefs.save_preferences(bypass_cooldown = TRUE, silent = TRUE)
		sessions += prefs
	var/list/held_flags = list()
	for(var/datum/preferences/prefs as anything in sessions)
		held_flags += !!GLOB.held_player_savefiles[prefs.path]
	for(var/datum/preferences/prefs as anything in sessions)
		if(GLOB.held_player_savefile_used[prefs.path])
			// С запасом в тик: world.time дробный, и ровно срок простоя мог бы не дотянуть из-за округления.
			GLOB.held_player_savefile_used[prefs.path] = world.time - PLAYER_SAVEFILE_HOLD_IDLE - 1
	prune_held_player_savefiles()
	var/held_after_idle = 0
	for(var/datum/preferences/prefs as anything in sessions)
		if(GLOB.held_player_savefiles[prefs.path])
			held_after_idle++
	QDEL_LIST(sessions)

	TEST_ASSERT(!held_flags[1] && !held_flags[2], "сверх предела закрылись не самые давние файлы")
	var/held_total = 0
	for(var/flag in held_flags)
		held_total += flag
	TEST_ASSERT_EQUAL(held_total, PLAYER_SAVEFILE_HOLD_MAX, "открытых файлов больше предела")
	TEST_ASSERT(held_flags[length(held_flags)], "последний открытый файл закрыт")
	TEST_ASSERT_EQUAL(held_after_idle, 0, "простаивающие файлы не закрылись")

/**
 * Одиночные ключи закрытого файла уходят в журнал без открытия savefile и доезжают до
 * следующего входа в точности, даже если сервер упал до слияния журнала.
 */
/datum/unit_test/preferences_single_pref_journal_survives_crash

/datum/unit_test/preferences_single_pref_journal_survives_crash/Run()
	var/test_path = savefile_session_test_path("journal")
	var/datum/preferences/savefile_session_test/prefs = new(test_path)
	prefs.save_preferences(bypass_cooldown = TRUE, silent = TRUE)
	prefs.release_savefile()

	var/state = "{\"tabs\":\[1,2\],\"name\":\"Чат «главный» с \\\"кавычками\\\"\"}"
	var/heart = world.realtime + 24 HOURS
	var/list/layouts = list("/obj/machinery/vending/cola" = "list")
	var/list/zoom = list("chat" = 1.25, "Окно" = 0.75)
	prefs.tgui_panel_state = state
	prefs.save_single_pref("tgui_panel_state", state)
	prefs.hearted_until = heart
	prefs.save_pref_var("hearted_until")
	prefs.save_single_pref("vending_layouts", layouts.Copy())
	prefs.save_single_pref("ui_zoom_preferences", zoom.Copy())
	prefs.ticket_nickname = null
	prefs.save_pref_var("ticket_nickname")
	prefs.metadollar_minute_pool = 37
	prefs.save_single_pref("metadollar_minute_pool", 37, lazy = TRUE)

	var/opens_before = GLOB.player_savefile_opens
	prefs.flush_single_prefs()
	var/flush_opens = GLOB.player_savefile_opens - opens_before
	var/journal_written = fexists("[test_path].journal")
	var/on_disk_before_merge = savefile_session_test_read(test_path, "tgui_panel_state")
	// Падение сервера: журнал не слит, файл никто не трогал.
	prefs.path = null
	qdel(prefs)

	var/datum/preferences/reader = savefile_session_test_reader(test_path)
	var/reader_pool = reader.metadollar_minute_pool
	var/reader_heart = reader.hearted_until
	qdel(reader)
	var/merged_state = savefile_session_test_read(test_path, "tgui_panel_state")
	var/merged_heart = savefile_session_test_read(test_path, "hearted_until")
	var/merged_layouts = savefile_session_test_read(test_path, "vending_layouts")
	var/merged_zoom = savefile_session_test_read(test_path, "ui_zoom_preferences")
	var/merged_nickname = savefile_session_test_read(test_path, "ticket_nickname")
	var/merged_epoch = savefile_session_test_read(test_path, PREF_JOURNAL_EPOCH_SAVE_KEY)
	var/journal_left = fexists("[test_path].journal")
	fdel(test_path)
	fdel("[test_path].journal")

	TEST_ASSERT_EQUAL(flush_opens, 0, "сброс одиночных ключей закрытого файла открыл savefile")
	TEST_ASSERT(journal_written, "сброс одиночных ключей не записал журнал")
	TEST_ASSERT_NOTEQUAL(on_disk_before_merge, state, "ключ попал в savefile мимо журнала")
	TEST_ASSERT_EQUAL(reader_pool, 37, "ленивый ключ из журнала не дошёл до следующего входа")
	TEST_ASSERT_EQUAL(reader_heart, heart, "большое число из журнала округлилось")
	TEST_ASSERT_EQUAL(merged_state, state, "текст с кириллицей и кавычками из журнала изменился")
	TEST_ASSERT_EQUAL(merged_heart, heart, "большое число из журнала легло в savefile неточно")
	TEST_ASSERT_EQUAL(json_encode(merged_layouts), json_encode(layouts), "список раскладок из журнала изменился")
	TEST_ASSERT_EQUAL(json_encode(merged_zoom), json_encode(zoom), "список масштабов из журнала изменился")
	TEST_ASSERT_NULL(merged_nickname, "null из журнала подменён")
	TEST_ASSERT_EQUAL(merged_epoch, 1, "слияние журнала не подняло его поколение")
	TEST_ASSERT(!journal_left, "слитый журнал не удалён")

/**
 * Блок журнала, уже слитого в savefile, не перекрывает более новую запись: падение между
 * подъёмом поколения и удалением журнала не откатывает настройку.
 */
/datum/unit_test/preferences_single_pref_journal_skips_merged_epoch

/datum/unit_test/preferences_single_pref_journal_skips_merged_epoch/Run()
	var/test_path = savefile_session_test_path("journal_epoch")
	var/datum/preferences/savefile_session_test/prefs = new(test_path)
	prefs.save_preferences(bypass_cooldown = TRUE, silent = TRUE)
	prefs.release_savefile()

	prefs.tgui_panel_theme = "light"
	prefs.save_single_pref("tgui_panel_theme", "light")
	prefs.flush_single_prefs()
	var/merged_journal = file2text("[test_path].journal")
	prefs.tgui_panel_theme = "dark"
	prefs.save_preferences(bypass_cooldown = TRUE, silent = TRUE)
	prefs.release_savefile()
	text2file(merged_journal, "[test_path].journal")
	prefs.path = null
	qdel(prefs)

	var/datum/preferences/reader = savefile_session_test_reader(test_path)
	var/reader_theme = reader.tgui_panel_theme
	qdel(reader)
	var/journal_left = fexists("[test_path].journal")
	fdel(test_path)
	fdel("[test_path].journal")

	TEST_ASSERT(length(merged_journal), "сброс не записал журнал")
	TEST_ASSERT_EQUAL(reader_theme, "dark", "блок уже слитого журнала перекрыл более новую полную запись")
	TEST_ASSERT(!journal_left, "устаревший журнал не удалён")

/// Оборванные при записи куски журнала не читаются, целые блоки между ними доезжают.
/datum/unit_test/preferences_single_pref_journal_ignores_torn_blocks

/datum/unit_test/preferences_single_pref_journal_ignores_torn_blocks/Run()
	var/test_path = savefile_session_test_path("journal_tail")
	var/datum/preferences/savefile_session_test/prefs = new(test_path)
	prefs.save_preferences(bypass_cooldown = TRUE, silent = TRUE)
	prefs.release_savefile()

	prefs.tgui_panel_theme = "light"
	prefs.save_single_pref("tgui_panel_theme", "light")
	prefs.flush_single_prefs()
	// Обрывки нужного поколения и отпечатка вокруг целого блока: от чтения их спасают только метки начала и конца.
	var/whole_block = file2text("[test_path].journal")
	var/torn_head = "[PREF_JOURNAL_BLOCK_BEGIN]\n[PREF_JOURNAL_EPOCH_KEY] = 0\n[PREF_JOURNAL_BASE_KEY] = \"[GLOB.player_savefile_journal_bases[test_path]]\"\ntgui_panel_theme = \"default\"\nmax_chat_length = 7\n"
	fdel("[test_path].journal")
	text2file("[torn_head][whole_block][PREF_JOURNAL_BLOCK_BEGIN]\n[PREF_JOURNAL_EPOCH_KEY] = 0\nmax_chat_length = 9", "[test_path].journal")
	prefs.path = null
	qdel(prefs)

	var/datum/preferences/reader = savefile_session_test_reader(test_path)
	var/reader_theme = reader.tgui_panel_theme
	qdel(reader)
	var/torn_length = savefile_session_test_read(test_path, "max_chat_length")
	fdel(test_path)
	fdel("[test_path].journal")

	TEST_ASSERT_EQUAL(reader_theme, "light", "целый блок журнала между обрывками не доехал")
	TEST_ASSERT(torn_length != 7 && torn_length != 9, "оборванный блок журнала прочитан")

/// Значение, которое ExportText изменил бы, пишется в сам savefile, а не в журнал.
/datum/unit_test/preferences_single_pref_journal_rejects_unsafe_value

/datum/unit_test/preferences_single_pref_journal_rejects_unsafe_value/Run()
	var/test_path = savefile_session_test_path("journal_unsafe")
	var/datum/preferences/savefile_session_test/prefs = new(test_path)
	prefs.save_preferences(bypass_cooldown = TRUE, silent = TRUE)
	prefs.release_savefile()

	var/nickname = "\proper Ник"
	prefs.ticket_nickname = nickname
	prefs.save_pref_var("ticket_nickname")
	prefs.flush_single_prefs()
	var/journal_written = fexists("[test_path].journal")
	prefs.release_savefile()
	var/on_disk = savefile_session_test_read(test_path, "ticket_nickname")
	qdel(prefs)

	TEST_ASSERT(!pref_journal_safe(nickname), "текст с \\proper сочтён безопасным для журнала")
	TEST_ASSERT(!pref_journal_safe(list("state" = "x[PREF_JOURNAL_BLOCK_END][PREF_JOURNAL_BLOCK_BEGIN]metadollar_minute_pool = 500")), "текст с метками блоков журнала сочтён безопасным: он режет журнал и становится ключами")
	TEST_ASSERT(pref_journal_safe(list("a" = list(1, "б"), /obj/item = "x")), "обычный вложенный список сочтён небезопасным")
	TEST_ASSERT(!journal_written, "небезопасное значение ушло в журнал")
	TEST_ASSERT_EQUAL(on_disk, nickname, "небезопасное значение не записано в savefile")

/// Запись персонажа сливает журнал, и более новый ключ из буфера перекрывает журнальный.
/datum/unit_test/preferences_save_character_merges_journal

/datum/unit_test/preferences_save_character_merges_journal/Run()
	var/test_path = savefile_session_test_path("journal_character")
	var/datum/preferences/savefile_session_test/prefs = new(test_path)
	prefs.save_preferences(bypass_cooldown = TRUE, silent = TRUE)
	prefs.release_savefile()

	prefs.tgui_panel_theme = "light"
	prefs.save_single_pref("tgui_panel_theme", "light")
	prefs.max_chat_length = 222
	prefs.save_pref_var("max_chat_length")
	prefs.flush_single_prefs()
	prefs.tgui_panel_theme = "dark"
	prefs.save_single_pref("tgui_panel_theme", "dark")
	prefs.save_character(bypass_cooldown = TRUE, silent = TRUE, update_active_preset = FALSE)
	var/journal_left = fexists("[test_path].journal")
	var/on_disk_theme = savefile_session_test_read(test_path, "tgui_panel_theme")
	var/on_disk_length = savefile_session_test_read(test_path, "max_chat_length")
	prefs.release_savefile()
	var/datum/preferences/reader = savefile_session_test_reader(test_path)
	var/reader_theme = reader.tgui_panel_theme
	qdel(reader)
	qdel(prefs)

	TEST_ASSERT(!journal_left, "запись персонажа не слила журнал")
	TEST_ASSERT_EQUAL(on_disk_length, 222, "ключ журнала не доехал с записью персонажа")
	TEST_ASSERT_EQUAL(on_disk_theme, "dark", "журнальный ключ перекрыл более новый из буфера")
	TEST_ASSERT_EQUAL(reader_theme, "dark", "следующий вход прочитал устаревший ключ")

/// Ребут сливает журналы всех префов раунда: сборка без журнала после отката ничего не теряет.
/datum/unit_test/preferences_reboot_flush_merges_journal

/datum/unit_test/preferences_reboot_flush_merges_journal/Run()
	var/test_path = savefile_session_test_path("journal_reboot")
	var/datum/preferences/savefile_session_test/prefs = new(test_path)
	prefs.save_preferences(bypass_cooldown = TRUE, silent = TRUE)
	prefs.release_savefile()
	prefs.tgui_panel_theme = "light"
	prefs.save_single_pref("tgui_panel_theme", "light")
	prefs.flush_single_prefs()
	prefs.tgui_panel_theme = "dark"
	prefs.save_single_pref("tgui_panel_theme", "dark")
	var/journal_before = fexists("[test_path].journal")

	var/registry_key = "savefilesessiontestckey"
	GLOB.preferences_datums[registry_key] = prefs
	flush_pending_single_prefs()
	GLOB.preferences_datums -= registry_key
	var/journal_after = fexists("[test_path].journal")
	var/pending_after = length(prefs.pending_single_prefs)
	var/on_disk_theme = savefile_session_test_read(test_path, "tgui_panel_theme")
	qdel(prefs)

	TEST_ASSERT(journal_before, "сброс не записал журнал")
	TEST_ASSERT(!journal_after, "ребут не слил журнал в savefile")
	TEST_ASSERT_EQUAL(pending_after, 0, "ребут оставил буфер одиночных ключей")
	TEST_ASSERT_EQUAL(on_disk_theme, "dark", "ребут записал не последнее значение")

/**
 * Журнал, переживший падение сервера, не откатывает правку сборки без журнала (откат или тест-мерж
 * между раундами): та пишет в savefile напрямую, и следующий вход видит её значение.
 */
/datum/unit_test/preferences_single_pref_journal_skips_foreign_write

/datum/unit_test/preferences_single_pref_journal_skips_foreign_write/Run()
	var/test_path = savefile_session_test_path("journal_foreign")
	var/datum/preferences/savefile_session_test/prefs = new(test_path)
	prefs.save_preferences(bypass_cooldown = TRUE, silent = TRUE)
	prefs.release_savefile()

	// 1. Сброс уходит в журнал мимо savefile.
	prefs.tgui_panel_theme = "light"
	prefs.save_single_pref("tgui_panel_theme", "light")
	prefs.flush_single_prefs()
	var/journal_written = fexists("[test_path].journal")
	// 2. Сервер падает до слияния.
	savefile_session_test_crash(prefs)
	// 3. Раунд на сборке без журнала: она пишет в savefile напрямую и журнала не видит.
	var/savefile/old_build = new /savefile(test_path)
	old_build.cd = "/"
	WRITE_FILE(old_build["tgui_panel_theme"], "dark")
	old_build = null
	// 4. Вход на сборке с журналом.
	var/stale_before = GLOB.player_savefile_journal_stale_blocks
	var/merges_before = savefile_session_test_blocking_count("savefile (слияние журнала)")
	var/datum/preferences/reader = savefile_session_test_reader(test_path)
	var/reader_theme = reader.tgui_panel_theme
	qdel(reader)
	// 5. Что лежит в файле после входа.
	var/on_disk_theme = savefile_session_test_read(test_path, "tgui_panel_theme")
	var/journal_left = fexists("[test_path].journal")
	var/stale_blocks = GLOB.player_savefile_journal_stale_blocks - stale_before
	var/merges_measured = savefile_session_test_blocking_count("savefile (слияние журнала)") - merges_before
	var/summary = player_savefile_summary()
	fdel(test_path)
	fdel("[test_path].journal")

	TEST_ASSERT(journal_written, "сброс не записал журнал")
	TEST_ASSERT_EQUAL(reader_theme, "dark", "устаревший журнал перекрыл правку сборки без журнала")
	TEST_ASSERT_EQUAL(on_disk_theme, "dark", "устаревший журнал лёг в savefile поверх более новой записи")
	TEST_ASSERT(!journal_left, "устаревший журнал не удалён")
	TEST_ASSERT_EQUAL(stale_blocks, 1, "отброшенный блок журнала не посчитан")
	TEST_ASSERT_EQUAL(merges_measured, 1, "слияние журнала на входе не попало в учёт блокирующих вызовов")
	TEST_ASSERT(findtext(summary, "отброшено устаревших блоков [GLOB.player_savefile_journal_stale_blocks]"), "итог раунда не называет отброшенные блоки журнала")

/// Падение посреди слияния журнала не теряет его остаток: следующий вход доводит слияние по метке.
/datum/unit_test/preferences_single_pref_journal_survives_torn_merge

/datum/unit_test/preferences_single_pref_journal_survives_torn_merge/Run()
	var/test_path = savefile_session_test_path("journal_torn_merge")
	var/datum/preferences/savefile_session_test/prefs = new(test_path)
	prefs.save_preferences(bypass_cooldown = TRUE, silent = TRUE)
	prefs.release_savefile()

	prefs.tgui_panel_theme = "light"
	prefs.save_single_pref("tgui_panel_theme", "light")
	prefs.max_chat_length = 77
	prefs.save_pref_var("max_chat_length")
	prefs.flush_single_prefs()
	var/journal_written = fexists("[test_path].journal")
	savefile_session_test_crash(prefs)
	// Слияние успело поставить метку и записать первое значение, второе - нет.
	var/base = player_savefile_fingerprint(test_path)
	var/savefile/torn = new /savefile(test_path)
	torn.cd = "/"
	WRITE_FILE(torn[PREF_JOURNAL_MERGING_SAVE_KEY], base)
	WRITE_FILE(torn["tgui_panel_theme"], "light")
	torn = null

	var/stale_before = GLOB.player_savefile_journal_stale_blocks
	var/datum/preferences/reader = savefile_session_test_reader(test_path)
	var/reader_length = reader.max_chat_length
	var/reader_theme = reader.tgui_panel_theme
	qdel(reader)
	var/on_disk_length = savefile_session_test_read(test_path, "max_chat_length")
	var/marker_left = savefile_session_test_read(test_path, PREF_JOURNAL_MERGING_SAVE_KEY)
	var/journal_left = fexists("[test_path].journal")
	var/stale_blocks = GLOB.player_savefile_journal_stale_blocks - stale_before
	fdel(test_path)
	fdel("[test_path].journal")

	TEST_ASSERT(journal_written, "сброс не записал журнал")
	TEST_ASSERT_EQUAL(reader_length, 77, "остаток журнала после оборванного слияния не доехал до следующего входа")
	TEST_ASSERT_EQUAL(on_disk_length, 77, "остаток журнала после оборванного слияния не лёг в savefile")
	TEST_ASSERT_EQUAL(reader_theme, "light", "значение, слитое до обрыва, потерялось")
	TEST_ASSERT_EQUAL(stale_blocks, 0, "блоки оборванного слияния сочтены устаревшими")
	TEST_ASSERT_NULL(marker_left, "метка слияния осталась в savefile")
	TEST_ASSERT(!journal_left, "доведённый журнал не удалён")

/// Журнал, слитый другим процессом BYOND, не делает устаревшими блоки, которые этот мир пишет после.
/datum/unit_test/preferences_single_pref_journal_survives_foreign_merge

/datum/unit_test/preferences_single_pref_journal_survives_foreign_merge/Run()
	var/test_path = savefile_session_test_path("journal_foreign_merge")
	var/datum/preferences/savefile_session_test/prefs = new(test_path)
	prefs.save_preferences(bypass_cooldown = TRUE, silent = TRUE)
	prefs.release_savefile()

	prefs.tgui_panel_theme = "light"
	prefs.save_single_pref("tgui_panel_theme", "light")
	prefs.flush_single_prefs()
	// Другой процесс сливает журнал: значение в файле, счётчик слияний поднят, журнал снят.
	var/savefile/other = new /savefile(test_path)
	other.cd = "/"
	var/other_epoch
	READ_FILE(other[PREF_JOURNAL_EPOCH_SAVE_KEY], other_epoch)
	WRITE_FILE(other["tgui_panel_theme"], "light")
	WRITE_FILE(other[PREF_JOURNAL_EPOCH_SAVE_KEY], (isnum(other_epoch) ? other_epoch : 0) + 1)
	other = null
	fdel("[test_path].journal")

	prefs.max_chat_length = 55
	prefs.save_pref_var("max_chat_length")
	prefs.flush_single_prefs()
	var/journal_rewritten = fexists("[test_path].journal")
	savefile_session_test_crash(prefs)

	var/datum/preferences/reader = savefile_session_test_reader(test_path)
	var/reader_length = reader.max_chat_length
	var/reader_theme = reader.tgui_panel_theme
	qdel(reader)
	fdel(test_path)
	fdel("[test_path].journal")

	TEST_ASSERT(journal_rewritten, "сброс после чужого слияния не записал журнал")
	TEST_ASSERT_EQUAL(reader_length, 55, "блок, записанный после чужого слияния, отброшен")
	TEST_ASSERT_EQUAL(reader_theme, "light", "значение, слитое другим процессом, потерялось")

/// Без отпечатка savefile (сбой хэша) журнал не трогается и доезжает со следующим открытием.
/datum/unit_test/preferences_single_pref_journal_kept_without_fingerprint

/datum/unit_test/preferences_single_pref_journal_kept_without_fingerprint/Run()
	var/test_path = savefile_session_test_path("journal_no_fingerprint")
	var/datum/preferences/savefile_session_test/prefs = new(test_path)
	prefs.save_preferences(bypass_cooldown = TRUE, silent = TRUE)
	prefs.release_savefile()

	prefs.tgui_panel_theme = "light"
	prefs.save_single_pref("tgui_panel_theme", "light")
	prefs.flush_single_prefs()
	savefile_session_test_crash(prefs)

	var/stale_before = GLOB.player_savefile_journal_stale_blocks
	var/savefile/opened = new /savefile(test_path)
	var/merged = merge_player_savefile_journal(test_path, opened, "")
	opened = null
	var/journal_kept = fexists("[test_path].journal")
	var/stale_blocks = GLOB.player_savefile_journal_stale_blocks - stale_before
	var/datum/preferences/reader = savefile_session_test_reader(test_path)
	var/reader_theme = reader.tgui_panel_theme
	qdel(reader)
	var/journal_left = fexists("[test_path].journal")
	fdel(test_path)
	fdel("[test_path].journal")

	TEST_ASSERT_NULL(merged, "слияние без отпечатка что-то записало")
	TEST_ASSERT(journal_kept, "журнал удалён, хотя отпечатка savefile не было")
	TEST_ASSERT_EQUAL(stale_blocks, 0, "блоки без отпечатка сочтены устаревшими")
	TEST_ASSERT_EQUAL(reader_theme, "light", "журнал не доехал со следующим открытием")
	TEST_ASSERT(!journal_left, "журнал не слит со следующим открытием")

/// Закрытие при вытеснении учитывается один раз: внутри замера записи - в записи, за замеренным открытием чтения - отдельно.
/datum/unit_test/preferences_savefile_eviction_measured_once

/datum/unit_test/preferences_savefile_eviction_measured_once/Run()
	var/list/sessions = list()
	for(var/index in 1 to PLAYER_SAVEFILE_HOLD_MAX)
		var/datum/preferences/savefile_session_test/filler = new(savefile_session_test_path("evict_[index]"))
		filler.save_preferences(bypass_cooldown = TRUE, silent = TRUE)
		sessions += filler
	var/datum/preferences/savefile_session_test/writer = new(savefile_session_test_path("evict_writer"))
	sessions += writer
	var/datum/preferences/savefile_session_test/reader = new(savefile_session_test_path("evict_reader"))
	sessions += reader
	reader.session_savefile = FALSE
	reader.save_preferences(bypass_cooldown = TRUE, silent = TRUE)
	reader.session_savefile = TRUE

	var/evictions_before = GLOB.player_savefile_evictions
	var/closes_before = savefile_session_test_blocking_count("savefile (закрытие)")
	var/writes_before = savefile_session_test_blocking_count("savefile (полные префы)")
	writer.save_preferences(bypass_cooldown = TRUE, silent = TRUE)
	var/write_evictions = GLOB.player_savefile_evictions - evictions_before
	var/write_closes = savefile_session_test_blocking_count("savefile (закрытие)") - closes_before
	var/writes_measured = savefile_session_test_blocking_count("savefile (полные префы)") - writes_before

	evictions_before = GLOB.player_savefile_evictions
	closes_before = savefile_session_test_blocking_count("savefile (закрытие)")
	reader.load_preferences(bypass_cooldown = TRUE)
	var/read_evictions = GLOB.player_savefile_evictions - evictions_before
	var/read_closes = savefile_session_test_blocking_count("savefile (закрытие)") - closes_before
	QDEL_LIST(sessions)

	TEST_ASSERT_EQUAL(write_evictions, 1, "запись сверх предела вытеснила не один файл")
	TEST_ASSERT_EQUAL(writes_measured, 1, "полная запись не попала в учёт")
	TEST_ASSERT_EQUAL(write_closes, 0, "закрытие при вытеснении посчитано и в записи, и отдельно")
	TEST_ASSERT_EQUAL(read_evictions, 1, "чтение сверх предела вытеснило не один файл")
	TEST_ASSERT_EQUAL(read_closes, 1, "закрытие при вытеснении за чтением не попало в учёт")

/// Журнал, начатый больше PREF_JOURNAL_MAX_AGE назад, не дописывается: сброс уходит в savefile и сливает его.
/datum/unit_test/preferences_single_pref_journal_age_limit

/datum/unit_test/preferences_single_pref_journal_age_limit/Run()
	var/test_path = savefile_session_test_path("journal_age")
	var/datum/preferences/savefile_session_test/prefs = new(test_path)
	prefs.save_preferences(bypass_cooldown = TRUE, silent = TRUE)
	prefs.release_savefile()

	prefs.tgui_panel_theme = "light"
	prefs.save_single_pref("tgui_panel_theme", "light")
	prefs.flush_single_prefs()
	var/journal_written = fexists("[test_path].journal")
	GLOB.player_savefile_journal_started[test_path] = world.time - PREF_JOURNAL_MAX_AGE - 1
	prefs.max_chat_length = 444
	prefs.save_pref_var("max_chat_length")
	var/opens_before = GLOB.player_savefile_opens
	prefs.flush_single_prefs()
	var/old_journal_flush_opens = GLOB.player_savefile_opens - opens_before
	var/journal_left = fexists("[test_path].journal")
	var/on_disk_theme = savefile_session_test_read(test_path, "tgui_panel_theme")
	var/on_disk_length = savefile_session_test_read(test_path, "max_chat_length")
	qdel(prefs)

	TEST_ASSERT(journal_written, "сброс не записал журнал")
	TEST_ASSERT_EQUAL(old_journal_flush_opens, 1, "сброс дописал журнал старше предела вместо записи в savefile")
	TEST_ASSERT(!journal_left, "журнал старше предела не слит")
	TEST_ASSERT_EQUAL(on_disk_theme, "light", "ключ старого журнала не доехал до savefile")
	TEST_ASSERT_EQUAL(on_disk_length, 444, "свежий ключ не доехал до savefile")

/// Миграция версии на входе идёт через один удерживаемый хэндл и обновляет все слоты, хотя load_character уводит его cd.
/datum/unit_test/preferences_savefile_session_migrates_held_file

/datum/unit_test/preferences_savefile_session_migrates_held_file/Run()
	var/test_path = savefile_session_test_path("migration")
	var/list/names = list("Мигрант Первый", "Мигрант Второй", "Мигрант Третий")
	var/datum/preferences/savefile_session_test/writer = new(test_path)
	writer.save_preferences(bypass_cooldown = TRUE, silent = TRUE)
	for(var/slot in 1 to length(names))
		writer.default_slot = slot
		writer.real_name = names[slot]
		writer.save_character(bypass_cooldown = TRUE, silent = TRUE, update_active_preset = FALSE)
	writer.default_slot = 2
	writer.save_preferences(bypass_cooldown = TRUE, silent = TRUE)
	writer.release_savefile()
	writer.path = null
	qdel(writer)
	var/current_version = savefile_session_test_read(test_path, "version")
	var/savefile/older = new /savefile(test_path)
	older.cd = "/"
	WRITE_FILE(older["version"], current_version - 1)
	for(var/slot in 1 to length(names))
		older.cd = "/character[slot]"
		WRITE_FILE(older["version"], current_version - 1)
	older = null

	var/datum/preferences/savefile_session_test/prefs = new(test_path)
	var/opens_before = GLOB.player_savefile_opens
	// Без ссылки на сам savefile: она держала бы файл открытым и после release_savefile.
	var/loaded = !!prefs.load_preferences(bypass_cooldown = TRUE)
	var/migration_opens = GLOB.player_savefile_opens - opens_before
	var/held_after = !!GLOB.held_player_savefiles[test_path]
	var/slot_after = prefs.default_slot
	prefs.load_character(null, bypass_cooldown = TRUE)
	var/loaded_name = prefs.real_name
	prefs.release_savefile()
	var/root_version = savefile_session_test_read(test_path, "version")
	var/list/slot_versions = list()
	var/list/slot_names = list()
	for(var/slot in 1 to length(names))
		slot_versions += savefile_session_test_read(test_path, "version", "/character[slot]")
		slot_names += savefile_session_test_read(test_path, "real_name", "/character[slot]")
	qdel(prefs)

	TEST_ASSERT(loaded, "сейв старой версии не прочитался")
	TEST_ASSERT_EQUAL(migration_opens, 1, "миграция открывала файл не один раз")
	TEST_ASSERT(held_after, "файл после миграции не удерживается")
	TEST_ASSERT_EQUAL(slot_after, 2, "миграция сбила выбранный слот")
	TEST_ASSERT_EQUAL(loaded_name, names[2], "после миграции загрузился не выбранный слот")
	TEST_ASSERT_EQUAL(root_version, current_version, "версия префов не поднята")
	for(var/slot in 1 to length(names))
		TEST_ASSERT_EQUAL(slot_versions[slot], current_version, "слот [slot] не промигрирован")
		TEST_ASSERT_EQUAL(slot_names[slot], names[slot], "миграция испортила имя в слоте [slot]")

/// Удерживаемый хэндл и второй хэндл того же файла видят записи друг друга, а закрытие ни одной не откатывает.
/datum/unit_test/preferences_savefile_session_second_handle

/datum/unit_test/preferences_savefile_session_second_handle/Run()
	var/test_path = savefile_session_test_path("second_handle")
	var/datum/preferences/savefile_session_test/prefs = new(test_path)
	prefs.save_preferences(bypass_cooldown = TRUE, silent = TRUE)
	prefs.real_name = "Первая Запись"
	prefs.save_character(bypass_cooldown = TRUE, silent = TRUE, update_active_preset = FALSE)
	prefs.tgui_panel_theme = "light"
	prefs.save_single_pref("tgui_panel_theme", "light", immediate = TRUE)

	var/savefile/second = new /savefile(test_path)
	second.cd = "/"
	var/second_theme_first
	READ_FILE(second["tgui_panel_theme"], second_theme_first)
	second.cd = "/character1"
	var/second_name_first
	READ_FILE(second["real_name"], second_name_first)

	prefs.real_name = "Вторая Запись"
	prefs.save_character(bypass_cooldown = TRUE, silent = TRUE, update_active_preset = FALSE)
	prefs.tgui_panel_theme = "dark"
	prefs.save_single_pref("tgui_panel_theme", "dark", immediate = TRUE)
	second.cd = "/"
	var/second_theme_second
	READ_FILE(second["tgui_panel_theme"], second_theme_second)
	second.cd = "/character1"
	var/second_name_second
	READ_FILE(second["real_name"], second_name_second)

	var/closes_before = savefile_session_test_blocking_count("savefile (закрытие)")
	prefs.release_savefile()
	var/closes_measured = savefile_session_test_blocking_count("savefile (закрытие)") - closes_before
	second = null
	var/datum/preferences/reader = savefile_session_test_reader(test_path)
	reader.load_character(1, bypass_cooldown = TRUE)
	var/reader_theme = reader.tgui_panel_theme
	var/reader_name = reader.real_name
	qdel(reader)
	qdel(prefs)

	TEST_ASSERT_EQUAL(second_theme_first, "light", "второй хэндл не видит ключ удерживаемого")
	TEST_ASSERT_EQUAL(second_name_first, "Первая Запись", "второй хэндл не видит персонажа удерживаемого")
	TEST_ASSERT_EQUAL(second_theme_second, "dark", "второй хэндл не видит повторную запись ключа")
	TEST_ASSERT_EQUAL(second_name_second, "Вторая Запись", "второй хэндл не видит повторную запись персонажа")
	TEST_ASSERT_EQUAL(closes_measured, 1, "закрытие удерживаемого файла не попало в учёт блокирующих вызовов")
	TEST_ASSERT_EQUAL(reader_theme, "dark", "закрытие хэндлов откатило ключ")
	TEST_ASSERT_EQUAL(reader_name, "Вторая Запись", "закрытие хэндлов откатило персонажа")

/// Крайние значения доезжают через журнал в точности: пустой список, пустая строка, дробь, строка в 16 КБ, null в списке.
/datum/unit_test/preferences_single_pref_journal_value_edges

/datum/unit_test/preferences_single_pref_journal_value_edges/Run()
	var/test_path = savefile_session_test_path("journal_edges")
	var/datum/preferences/savefile_session_test/prefs = new(test_path)
	prefs.save_preferences(bypass_cooldown = TRUE, silent = TRUE)
	prefs.release_savefile()

	var/big = ""
	while(length(big) < 16 * 1024)
		big += "Чат «главный» \\ \"кавычки\" \[1\]; "
	var/list/values = list(
		"journal_edge_empty_list" = list(),
		"journal_edge_empty_text" = "",
		"journal_edge_fraction" = 1.1,
		"journal_edge_big_text" = big,
		"journal_edge_null_in_list" = list("а", null, "б"),
		"journal_edge_null_value" = list("ключ" = null, "число" = 2),
	)
	var/list/unsafe = list()
	for(var/key in values)
		var/value = values[key]
		if(!pref_journal_safe(value))
			unsafe += key
		var/list/as_list = value
		prefs.save_single_pref(key, islist(value) ? as_list.Copy() : value)
	var/opens_before = GLOB.player_savefile_opens
	prefs.flush_single_prefs()
	var/flush_opens = GLOB.player_savefile_opens - opens_before
	var/journal_written = fexists("[test_path].journal")
	savefile_session_test_crash(prefs)

	var/datum/preferences/reader = savefile_session_test_reader(test_path)
	qdel(reader)
	var/list/merged = list()
	for(var/key in values)
		merged[key] = savefile_session_test_read(test_path, key)
	fdel(test_path)
	fdel("[test_path].journal")

	TEST_ASSERT_EQUAL(length(unsafe), 0, "значения сочтены небезопасными для журнала: [jointext(unsafe, ", ")]")
	TEST_ASSERT_EQUAL(flush_opens, 0, "сброс крайних значений открыл savefile")
	TEST_ASSERT(journal_written, "сброс крайних значений не записал журнал")
	for(var/key in values)
		var/expected = values[key]
		var/got = merged[key]
		if(islist(expected))
			TEST_ASSERT(islist(got), "[key]: из журнала пришёл не список")
			TEST_ASSERT_EQUAL(length(got), length(expected), "[key]: длина списка изменилась")
			TEST_ASSERT_EQUAL(json_encode(got), json_encode(expected), "[key]: список изменился")
		else
			TEST_ASSERT(!isnull(got), "[key]: значение потерялось")
			TEST_ASSERT_EQUAL(got, expected, "[key]: значение изменилось")
	TEST_ASSERT(istext(merged["journal_edge_empty_text"]), "пустая строка стала не строкой")

/// С выключенным PLAYER_SAVEFILE_HOLD файл закрывается после каждого обращения, как до удержания, а журнал работает.
/datum/unit_test/preferences_savefile_hold_disabled
	var/old_hold

/datum/unit_test/preferences_savefile_hold_disabled/Run()
	old_hold = CONFIG_GET(flag/player_savefile_hold)
	CONFIG_SET(flag/player_savefile_hold, FALSE)
	var/test_path = savefile_session_test_path("hold_disabled")
	var/datum/preferences/savefile_session_test/prefs = new(test_path)

	var/opens_before = GLOB.player_savefile_opens
	prefs.save_preferences(bypass_cooldown = TRUE, silent = TRUE)
	var/held_after_save = !!GLOB.held_player_savefiles[test_path]
	prefs.real_name = "Без Удержания"
	prefs.save_character(bypass_cooldown = TRUE, silent = TRUE, update_active_preset = FALSE)
	prefs.load_character(1, bypass_cooldown = TRUE)
	prefs.slot_names_cache = null
	prefs.get_slot_names()
	var/access_opens = GLOB.player_savefile_opens - opens_before
	prefs.tgui_panel_theme = "light"
	prefs.save_single_pref("tgui_panel_theme", "light")
	opens_before = GLOB.player_savefile_opens
	prefs.flush_single_prefs()
	var/flush_opens = GLOB.player_savefile_opens - opens_before
	var/journal_written = fexists("[test_path].journal")
	var/held_after_flush = !!GLOB.held_player_savefiles[test_path]
	var/summary = player_savefile_summary()

	var/datum/preferences/savefile_session_test/reader = new(test_path)
	reader.load_preferences(bypass_cooldown = TRUE)
	reader.load_character(1, bypass_cooldown = TRUE)
	var/reader_theme = reader.tgui_panel_theme
	var/reader_name = reader.real_name
	var/held_after_reader = !!GLOB.held_player_savefiles[test_path]
	var/journal_left = fexists("[test_path].journal")
	reader.path = null
	qdel(reader)
	qdel(prefs)
	CONFIG_SET(flag/player_savefile_hold, old_hold)

	TEST_ASSERT(!held_after_save, "файл остался открытым при выключенном удержании")
	TEST_ASSERT_EQUAL(access_opens, 4, "запись, персонаж, загрузка и имена слотов открыли файл не по разу")
	TEST_ASSERT_EQUAL(flush_opens, 0, "одиночный ключ при выключенном удержании открыл savefile мимо журнала")
	TEST_ASSERT(journal_written, "журнал не работает при выключенном удержании")
	TEST_ASSERT(!held_after_flush && !held_after_reader, "файл остался открытым при выключенном удержании")
	TEST_ASSERT(findtext(summary, "удержание выключено"), "итог раунда не говорит, что удержание выключено")
	TEST_ASSERT_EQUAL(reader_theme, "light", "ключ из журнала не дошёл до следующего входа")
	TEST_ASSERT_EQUAL(reader_name, "Без Удержания", "персонаж не дошёл до следующего входа")
	TEST_ASSERT(!journal_left, "вход не слил журнал")

/datum/unit_test/preferences_savefile_hold_disabled/Destroy()
	if(!isnull(old_hold))
		CONFIG_SET(flag/player_savefile_hold, old_hold)
	return ..()

/// Клиент-заглушка для временных префов: настоящие префы этого клиента - другой датум.
/datum/client_interface/savefile_session_test
	var/ckey = "savefilesessiontest"

/// Временные префы клиента (голоформа ИИ) читают чужой слот, не перезаписывая выбранный игроком.
/datum/unit_test/preferences_temporary_prefs_keep_default_slot

/datum/unit_test/preferences_temporary_prefs_keep_default_slot/Run()
	var/test_path = savefile_session_test_path("borrowed_slot")
	var/list/names = list("Хозяин Слота", "Голоформа Слота")
	var/datum/preferences/savefile_session_test/owner = new(test_path)
	owner.save_preferences(bypass_cooldown = TRUE, silent = TRUE)
	for(var/slot in 1 to length(names))
		owner.default_slot = slot
		owner.real_name = names[slot]
		owner.save_character(bypass_cooldown = TRUE, silent = TRUE, update_active_preset = FALSE)
	owner.default_slot = 1
	owner.save_preferences(bypass_cooldown = TRUE, silent = TRUE)

	var/datum/client_interface/savefile_session_test/fake_client = new
	fake_client.prefs = owner
	var/datum/preferences/savefile_session_test/borrowed = new(test_path)
	borrowed.parent = fake_client
	borrowed.load_character(2, bypass_cooldown = TRUE)
	var/borrowed_name = borrowed.real_name
	var/slot_after_borrow = savefile_session_test_read(test_path, "default_slot")
	borrowed.parent = null
	borrowed.path = null
	qdel(borrowed)
	fake_client.prefs = null
	qdel(fake_client)

	owner.load_character(2, bypass_cooldown = TRUE)
	var/slot_after_owner = savefile_session_test_read(test_path, "default_slot")
	qdel(owner)

	TEST_ASSERT_EQUAL(borrowed_name, names[2], "временные префы прочитали не тот слот")
	TEST_ASSERT_EQUAL(slot_after_borrow, 1, "временные префы перезаписали выбранный игроком слот")
	TEST_ASSERT_EQUAL(slot_after_owner, 2, "префы игрока не запомнили выбранный слот")

/datum/preferences/savefile_session_test/scar_counter
	var/character_saves = 0

/datum/preferences/savefile_session_test/scar_counter/save_character(bypass_cooldown = FALSE, silent = FALSE, export = FALSE, update_active_preset = TRUE)
	character_saves++
	return TRUE

/// Спавн с целыми постоянными шрамами персонажа не переписывает, а с битыми чистит набор и пишет один раз.
/datum/unit_test/preferences_persistent_scars_save_only_on_change

/datum/unit_test/preferences_persistent_scars_save_only_on_change/Run()
	var/datum/preferences/savefile_session_test/scar_counter/prefs = new(null)
	prefs.persistent_scars = TRUE
	prefs.scars_index = 1
	var/scar = "[SCAR_CURRENT_VERSION]|[BODY_ZONE_CHEST]|тонкий шрам|грудь|[WOUND_SEVERITY_MODERATE];"
	prefs.scars_list["1"] = scar
	var/mob/living/carbon/human/whole_body = allocate(/mob/living/carbon/human)
	var/saves_before = prefs.character_saves
	var/changed_whole = prefs.apply_persistent_scars(whole_body)
	var/saves_whole = prefs.character_saves - saves_before
	var/whole_scars = LAZYLEN(whole_body.all_scars)

	prefs.scars_list["1"] = "битый шрам;[scar]"
	var/mob/living/carbon/human/torn_body = allocate(/mob/living/carbon/human)
	var/changed_torn = prefs.apply_persistent_scars(torn_body)
	var/saves_torn = prefs.character_saves - saves_before - saves_whole
	var/kept = prefs.scars_list["1"]
	qdel(prefs)

	TEST_ASSERT(!changed_whole, "целый набор шрамов сочтён изменённым")
	TEST_ASSERT_EQUAL(saves_whole, 0, "спавн с целыми шрамами переписал персонажа")
	TEST_ASSERT_EQUAL(whole_scars, 1, "шрам не нанесён на тело")
	TEST_ASSERT(changed_torn, "битый шрам не выкинут из набора")
	TEST_ASSERT_EQUAL(saves_torn, 1, "очищенный набор шрамов не записан один раз")
	TEST_ASSERT_EQUAL(kept, scar, "из набора выкинут целый шрам")

/// Старый баланс metadollars читается из удерживаемого файла живого игрока без нового открытия.
/datum/unit_test/preferences_metadollars_legacy_read_uses_held_file

/datum/unit_test/preferences_metadollars_legacy_read_uses_held_file/Run()
	var/test_path = savefile_session_test_path("metadollars")
	var/datum/preferences/savefile_session_test/prefs = new(test_path)
	prefs.save_preferences(bypass_cooldown = TRUE, silent = TRUE)
	var/savefile/held = GLOB.held_player_savefiles[test_path]
	held.cd = "/"
	WRITE_FILE(held["metadollars"], 77)
	held = null

	var/opens_before = GLOB.player_savefile_opens
	var/held_amount = bm_read_metadollars_from_savefile_path(test_path)
	var/held_opens = GLOB.player_savefile_opens - opens_before
	prefs.release_savefile()
	opens_before = GLOB.player_savefile_opens
	var/closed_amount = bm_read_metadollars_from_savefile_path(test_path)
	var/closed_opens = GLOB.player_savefile_opens - opens_before
	var/held_after_read = !!GLOB.held_player_savefiles[test_path]
	qdel(prefs)

	TEST_ASSERT_EQUAL(held_amount, 77, "баланс из удерживаемого файла не прочитан")
	TEST_ASSERT_EQUAL(held_opens, 0, "чтение баланса открыло удерживаемый файл заново")
	TEST_ASSERT_EQUAL(closed_amount, 77, "баланс из закрытого файла не прочитан")
	TEST_ASSERT_EQUAL(closed_opens, 1, "чтение баланса из закрытого файла прошло мимо open_player_savefile")
	TEST_ASSERT(!held_after_read, "чтение баланса оставило файл открытым")
