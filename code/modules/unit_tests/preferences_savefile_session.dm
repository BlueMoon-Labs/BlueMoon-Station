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

	// Обрывки нужного поколения: от чтения их спасают только метки начала и конца блока.
	text2file("[PREF_JOURNAL_BLOCK_BEGIN]\n[PREF_JOURNAL_EPOCH_KEY] = 0\ntgui_panel_theme = \"default\"\nmax_chat_length = 7\n", "[test_path].journal")
	prefs.tgui_panel_theme = "light"
	prefs.save_single_pref("tgui_panel_theme", "light")
	prefs.flush_single_prefs()
	text2file("[PREF_JOURNAL_BLOCK_BEGIN]\n[PREF_JOURNAL_EPOCH_KEY] = 0\nmax_chat_length = 9", "[test_path].journal")
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
