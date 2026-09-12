/datum/preferences/navigation_test
	var/save_calls = 0
	var/record_saves_only = TRUE
	var/preview_rebuilt = FALSE

/datum/preferences/navigation_test/New()
	..(null)

/datum/preferences/navigation_test/save_preferences(bypass_cooldown = FALSE, silent = FALSE)
	save_calls++
	if(record_saves_only)
		return TRUE
	return ..()

/datum/preferences/navigation_test/ShowChoices(mob/user, rebuild_preview = TRUE)
	preview_rebuilt = rebuild_preview

/datum/preferences/navigation_test/SetQuirks(mob/user)
	return

/datum/preferences/navigation_test/Destroy(force)
	var/test_path = path
	. = ..()
	if(test_path)
		fdel(test_path)

/// Чистая навигация меняет отображаемую вкладку без записи и пересборки превью.
/datum/unit_test/preferences_navigation_no_save/Run()
	var/datum/preferences/navigation_test/prefs = allocate(/datum/preferences/navigation_test)
	prefs.save_calls = 0
	prefs.saveprefcooldown = world.time + PREF_SAVE_COOLDOWN
	var/initial_cooldown = prefs.saveprefcooldown

	prefs.process_link(null, list("_src_" = "prefs", "preference" = "character_tab", "tab" = "[BACKGROUND_CHAR_TAB]"))
	TEST_ASSERT_EQUAL(prefs.character_settings_tab, BACKGROUND_CHAR_TAB, "Вкладка персонажа не переключилась")
	TEST_ASSERT(!prefs.preview_rebuilt, "Навигация пересобрала превью персонажа")

	prefs.process_link(null, list("_src_" = "prefs", "preference" = "preferences_tab", "tab" = "[CONTENT_PREFS_TAB]"))
	TEST_ASSERT_EQUAL(prefs.preferences_tab, CONTENT_PREFS_TAB, "Вкладка настроек не переключилась")

	prefs.process_link(null, list("_src_" = "prefs", "quirk_category" = QUIRK_NEGATIVE))
	TEST_ASSERT_EQUAL(prefs.quirk_category, QUIRK_NEGATIVE, "Категория причуд не переключилась")

	var/category = GLOB.loadout_categories[1]
	var/list/subcategories = GLOB.loadout_categories[category]
	TEST_ASSERT(length(subcategories), "Для проверки навигации нужна категория лодаута с подкатегориями")
	prefs.process_link(null, list("_src_" = "prefs", "preference" = "gear", "select_category" = url_encode(category)))
	TEST_ASSERT_EQUAL(prefs.gear_category, category, "Категория лодаута не переключилась")
	var/subcategory = prefs.gear_subcategory
	prefs.process_link(null, list("_src_" = "prefs", "preference" = "gear", "select_category" = url_encode(category), "select_subcategory" = url_encode(subcategory)))
	TEST_ASSERT_EQUAL(prefs.gear_subcategory, subcategory, "Подкатегория лодаута не сохранила выбор")
	prefs.process_link(null, list("_src_" = "prefs", "preference" = "gear", "select_subcategory" = url_encode(subcategory)))

	TEST_ASSERT_EQUAL(prefs.save_calls, 0, "Чистая навигация вызвала полное сохранение")
	TEST_ASSERT_EQUAL(prefs.saveprefcooldown, initial_cooldown, "Навигация сдвинула кулдаун сохранения")
	TEST_ASSERT_NULL(prefs.pref_queue, "Навигация поставила полную запись в очередь")
	TEST_ASSERT(!prefs.preview_rebuilt, "Навигация по лодауту пересобрала превью")

/// Изменения, в том числе смешанные с навигацией, сохраняются и обновляют превью.
/datum/unit_test/preferences_navigation_mixed_links/Run()
	var/datum/preferences/navigation_test/prefs = allocate(/datum/preferences/navigation_test)
	prefs.save_calls = 0
	prefs.auto_capitalize_enabled = FALSE
	prefs.process_link(null, list("preference" = "auto_capitalize_enabled"))
	TEST_ASSERT(prefs.auto_capitalize_enabled, "Настройка не переключилась")
	TEST_ASSERT_EQUAL(prefs.save_calls, 1, "Изменение настройки не вызвало сохранение")

	prefs.process_link(null, list("quirk_category" = QUIRK_NEGATIVE, "preference" = "auto_capitalize_enabled"))
	TEST_ASSERT(!prefs.auto_capitalize_enabled, "Изменение настройки потерялось в смешанном запросе")
	TEST_ASSERT_EQUAL(prefs.save_calls, 2, "Категория причуд подавила запись изменения настройки")
	TEST_ASSERT(prefs.preview_rebuilt, "Смешанный запрос ошибочно признан безопасным для превью")

	var/category = GLOB.loadout_categories[1]
	prefs.loadout_slot = 1
	prefs.process_link(null, list("preference" = "gear", "select_category" = url_encode(category), "select_slot" = "2"))
	TEST_ASSERT_EQUAL(prefs.loadout_slot, 2, "Слот лодаута не переключился в смешанном запросе")
	TEST_ASSERT_EQUAL(prefs.save_calls, 3, "Категория лодаута подавила запись смены слота")
	TEST_ASSERT(prefs.preview_rebuilt, "Смена слота лодаута не обновила превью")

	prefs.process_link(null, list("preference" = "character_tab", "tab" = "[GENERAL_CHAR_TAB]", "unknown_action" = "1"))
	TEST_ASSERT_EQUAL(prefs.save_calls, 4, "Неизвестный параметр ошибочно признан чистой навигацией")

/// Навигация сохраняет очередь и буфер, а отложенная запись доносит последние значения до savefile.
/datum/unit_test/preferences_navigation_pending_save/Run()
	var/datum/preferences/navigation_test/prefs = allocate(/datum/preferences/navigation_test)
	prefs.load_path("unit_test_preferences_navigation")
	prefs.record_saves_only = FALSE
	prefs.auto_capitalize_enabled = FALSE
	prefs.save_preferences(bypass_cooldown = TRUE, silent = TRUE)
	prefs.saveprefcooldown = 0
	prefs.process_link(null, list("preference" = "auto_capitalize_enabled"))
	var/savefile/readback = new(prefs.path)
	var/initial_written
	READ_FILE(readback["auto_capitalize_enabled"], initial_written)
	readback = null
	TEST_ASSERT_EQUAL(initial_written, TRUE, "Изменение через process_link не записалось в savefile")

	prefs.queue_save_pref(PREF_SAVE_COOLDOWN, TRUE)
	prefs.process_link(null, list("preference" = "auto_capitalize_enabled"))
	prefs.tgui_panel_state = "{\"v\":7}"
	prefs.buffer_single_pref("tgui_panel_state", prefs.tgui_panel_state)
	var/pending_timer = prefs.pref_queue
	var/pending_deadline = prefs.pref_queue_deadline
	var/initial_save_calls = prefs.save_calls

	prefs.process_link(null, list("preference" = "character_tab", "tab" = "[BACKGROUND_CHAR_TAB]"))
	TEST_ASSERT_EQUAL(prefs.save_calls, initial_save_calls, "Навигация вызвала сохранение при заполненном буфере")
	TEST_ASSERT_EQUAL(prefs.pref_queue, pending_timer, "Навигация заменила таймер отложенной записи")
	TEST_ASSERT_EQUAL(prefs.pref_queue_deadline, pending_deadline, "Навигация сдвинула крайний срок записи")
	TEST_ASSERT_EQUAL(prefs.pending_single_prefs["tgui_panel_state"], prefs.tgui_panel_state, "Навигация потеряла одиночную правку")

	prefs.save_preferences(bypass_cooldown = TRUE, silent = TRUE)
	readback = new(prefs.path)
	var/final_written
	var/written_panel_state
	READ_FILE(readback["auto_capitalize_enabled"], final_written)
	READ_FILE(readback["tgui_panel_state"], written_panel_state)
	readback = null
	TEST_ASSERT_EQUAL(final_written, FALSE, "Последнее изменение перед навигацией не записалось")
	TEST_ASSERT_EQUAL(written_panel_state, prefs.tgui_panel_state, "Полная запись после навигации не сохранила буфер")
	TEST_ASSERT_NULL(prefs.pref_queue, "Полная запись не сняла свой таймер")
	TEST_ASSERT_EQUAL(length(prefs.pending_single_prefs), 0, "Полная запись не очистила буфер")
