/datum/unit_test/player_save_json
	var/test_path
	var/datum/player_save_json/storage
	var/datum/preferences/owned_preferences

/datum/unit_test/player_save_json/Run()
	var/savefile/empty = prepare()
	TEST_ASSERT_NOTNULL(empty, "не удалось открыть новое хранилище")
	TEST_ASSERT(!storage.exists(), "чтение нового хранилища создало файл на диске")
	TEST_ASSERT_EQUAL(length(empty.dir), 0, "новое хранилище содержит посторонние поля")

/datum/unit_test/player_save_json/proc/prepare()
	test_path = "data/player_save_tests/[md5("[type]")].sav"
	for(var/suffix in list("", ".json", ".json.recovery", ".json.import"))
		fdel("[test_path][suffix]")
	fdel("[test_path].json.d/")
	storage = new(test_path)
	return storage.open()

/datum/unit_test/player_save_json/Destroy()
	if(owned_preferences)
		owned_preferences.path = null
	for(var/suffix in list("", ".json", ".json.recovery", ".json.import"))
		fdel("[test_path][suffix]")
	fdel("[test_path].json.d/")
	storage = null
	return ..()

/datum/unit_test/player_save_json/proc/new_preferences()
	owned_preferences = new
	allocated += owned_preferences
	owned_preferences.path = test_path
	return owned_preferences

/// Сравниваем содержимое узлов, не завися от порядка полей JSON-объекта.
/datum/unit_test/player_save_json/proc/patch_difference(list/expected, list/actual)
	for(var/key in expected)
		var/list/wanted = expected[key]
		var/list/found = actual[key]
		if(!found || json_encode(wanted["value"]) != json_encode(found["value"]))
			return key
		var/nested = patch_difference(wanted["children"], found["children"])
		if(nested)
			return "[key]/[nested]"
	return null
/datum/unit_test/player_save_json/roundtrip/Run()
	var/savefile/source = prepare()
	var/list/mixed = list("повтор", "ключ" = 0, "повтор", null, 0, 1.23456789, /obj/item)
	mixed += list(list("вложенный" = list(1, null, 3)))
	source["version"] << 80
	source["mixed"] << mixed
	source["empty"] << list()
	source["null"] << null
	source["formatted"] << "\proper Тест %ff %15 %25"
	source.cd = "/character128/retired_module"
	source["текст"] << "Кириллица\n\"кавычки\" \\ слеш"
	TEST_ASSERT(storage.commit(source), "JSON не записан: [storage.error]")
	TEST_ASSERT_EQUAL(source.cd, "/character128/retired_module", "запись изменила текущую директорию загрузчика")
	var/datum/player_save_json/reopened = new(test_path)
	var/savefile/restored = reopened.open()
	TEST_ASSERT_NOTNULL(restored, "JSON не открылся повторно")
	var/list/read_mixed
	restored["mixed"] >> read_mixed
	TEST_ASSERT_EQUAL(read_mixed.len, mixed.len, "изменилось число элементов смешанного списка")
	TEST_ASSERT_EQUAL(read_mixed[1], read_mixed[3], "потерян повтор элемента")
	TEST_ASSERT_EQUAL(read_mixed["ключ"], 0, "нулевое ассоциативное значение потеряно")
	TEST_ASSERT_NULL(read_mixed[4], "null превратился в ноль")
	TEST_ASSERT_EQUAL(read_mixed[6], mixed[6], "JSON округлил дробное число")
	TEST_ASSERT_EQUAL(read_mixed[7], /obj/item, "путь типа превратился в строку")
	var/list/empty
	restored["empty"] >> empty
	TEST_ASSERT(islist(empty) && !empty.len, "пустой список превратился в null")
	var/formatted
	restored["formatted"] >> formatted
	TEST_ASSERT_EQUAL(formatted, "\proper Тест %ff %15 %25", "изменились служебные маркеры или знак процента")
	restored.cd = "/character128/retired_module"
	var/read_text
	restored["текст"] >> read_text
	TEST_ASSERT_EQUAL(read_text, "Кириллица\n\"кавычки\" \\ слеш", "потеряно неизвестное вложенное поле")

/datum/unit_test/player_save_json/legacy_untouched/Run()
	prepare()
	var/savefile/legacy = new(test_path)
	legacy["version"] << 79
	legacy["unknown"] << "старое поле"
	legacy.cd = "/character99"
	legacy["version"] << 71
	legacy["real_name"] << "Legacy Character"
	legacy.Flush()
	legacy = null
	var/before = rustg_hash_file(RUSTG_HASH_MD5, test_path)
	var/savefile/source = storage.open()
	TEST_ASSERT_NOTNULL(source, "старый сейв не открылся")
	source["new"] << 42
	TEST_ASSERT(storage.commit(source), "миграция не записалась")
	TEST_ASSERT_EQUAL(rustg_hash_file(RUSTG_HASH_MD5, test_path), before, "миграция изменила исходный .sav")
	var/savefile/restored = storage.open()
	var/unknown
	restored["unknown"] >> unknown
	TEST_ASSERT_EQUAL(unknown, "старое поле", "миграция отбросила неизвестный ключ")
	restored.cd = "/character99"
	var/name
	restored["real_name"] >> name
	TEST_ASSERT_EQUAL(name, "Legacy Character", "миграция потеряла слот вне текущего лимита")

/datum/unit_test/player_save_json/recovery/Run()
	var/savefile/source = prepare()
	source["version"] << 80
	source["marker"] << "первое"
	TEST_ASSERT(storage.commit(source), "не записано первое поколение")
	source["marker"] << "второе"
	TEST_ASSERT(storage.commit(source), "не записано второе поколение")
	fdel(storage.active_path)
	text2file("{оборванный JSON", storage.active_path)
	var/savefile/restored = storage.open()
	TEST_ASSERT_NOTNULL(restored, "исправное поколение не восстановлено")
	TEST_ASSERT(storage.recovered, "ошибка поколения не отмечена")
	var/marker
	restored["marker"] >> marker
	TEST_ASSERT_EQUAL(marker, "первое", "восстановлено неверное поколение")
	restored["marker"] << "после восстановления"
	TEST_ASSERT(storage.commit(restored), "запись после восстановления не работает")
	var/datum/player_save_json/reopened = new(test_path)
	restored = reopened.open()
	restored["marker"] >> marker
	TEST_ASSERT_EQUAL(marker, "после восстановления", "после перезапуска выбран старый JSON")

/datum/unit_test/player_save_json/corrupt_blocks_legacy_fallback/Run()
	var/savefile/source = prepare()
	source["version"] << 80
	TEST_ASSERT(storage.commit(source), "не записан JSON")
	var/savefile/legacy = new(test_path)
	legacy["version"] << 80
	legacy.Flush()
	legacy = null
	fdel(storage.json_path)
	text2file("{", storage.json_path)
	TEST_ASSERT_NULL(storage.open(), "повреждённый JSON незаметно откатился к устаревшему .sav")
	TEST_ASSERT(!storage.commit(source), "повреждённый JSON перезаписан настройками по умолчанию")
	TEST_ASSERT_EQUAL(file2text(storage.json_path), "{\n", "повреждённый файл изменён")

/datum/unit_test/player_save_json/future_version_blocks/Run()
	var/savefile/source = prepare()
	source["version"] << 80
	TEST_ASSERT(storage.commit(source), "не записано первое поколение")
	TEST_ASSERT(storage.commit(source), "не записано второе поколение")
	var/list/document = json_decode(file2text(storage.active_path))
	document["version"] = 999
	fdel(storage.active_path)
	text2file(json_encode(document), storage.active_path)
	TEST_ASSERT_NULL(storage.open(), "будущий формат заменён предыдущим поколением")
	TEST_ASSERT(!storage.commit(source), "будущий формат разрешено перезаписать")

/datum/unit_test/player_save_json/preferences_modules_and_delete/Run()
	prepare()
	var/datum/preferences/prefs = new
	allocated += prefs
	prefs.path = test_path
	prefs.bm_disclaimer_accepted = TRUE
	prefs.favorite_tracks = list("проверочный трек")
	prefs.interaction_effect = FALSE
	TEST_ASSERT(prefs.save_preferences(TRUE, TRUE), "не записаны настройки")
	prefs.real_name = "First Character"
	TEST_ASSERT(prefs.save_character(TRUE, TRUE), "не записан первый персонаж")
	prefs.default_slot = 2
	prefs.real_name = "Second Character"
	TEST_ASSERT(prefs.save_character(TRUE, TRUE), "не записан второй персонаж")
	TEST_ASSERT(prefs.delete_character(1), "не удалён первый слот")
	var/savefile/readback = prefs.open_player_save()
	TEST_ASSERT(!("character1" in readback.dir), "удалённый слот вернулся при следующей записи")
	var/disclaimer
	var/list/tracks
	readback["bm_disclaimer_accepted"] >> disclaimer
	readback["favorite_tracks"] >> tracks
	TEST_ASSERT_EQUAL(disclaimer, TRUE, "потеряно поле лобби после модульного ..()")
	TEST_ASSERT_EQUAL(tracks[1], "проверочный трек", "потеряно поле Sand после модульного ..()")
	readback.cd = "/character2"
	var/name
	readback["real_name"] >> name
	TEST_ASSERT_EQUAL(name, "Second Character", "удаление первого слота затронуло второй")
	TEST_ASSERT(!fexists(test_path), "новому игроку создан двоичный .sav")
	prefs.path = null

/datum/unit_test/player_save_json/migration_after_modules/Run()
	prepare()
	var/savefile/legacy = new(test_path)
	legacy["version"] << 79
	legacy["default_slot"] << 1
	legacy["favorite_tracks"] << list("сохранённый трек")
	legacy["bm_disclaimer_accepted"] << TRUE
	legacy["custom_verb_consent"] << FALSE
	legacy.Flush()
	legacy = null
	var/datum/preferences/prefs = new
	allocated += prefs
	prefs.path = test_path
	TEST_ASSERT(prefs.load_preferences(TRUE), "миграция настроек не завершилась")
	var/savefile/readback = prefs.open_player_save()
	var/list/tracks
	var/disclaimer
	var/consent
	readback["favorite_tracks"] >> tracks
	readback["bm_disclaimer_accepted"] >> disclaimer
	readback["custom_verb_consent"] >> consent
	TEST_ASSERT_EQUAL(tracks[1], "сохранённый трек", "миграция записала пустое значение до загрузки модуля")
	TEST_ASSERT_EQUAL(disclaimer, TRUE, "миграция стёрла настройку лобби")
	TEST_ASSERT_EQUAL(consent, FALSE, "миграция стёрла дополнительную настройку Sand")
	prefs.path = null

/datum/unit_test/player_save_json/partial_write_preserves_hidden_slots/Run()
	var/savefile/source = prepare()
	source["version"] << 80
	source["unknown_root"] << "неизвестное поле"
	source.cd = "/character128/retired"
	source["value"] << 1.23456789
	TEST_ASSERT(storage.commit(source), "не записано начальное состояние")
	var/datum/preferences/prefs = new
	allocated += prefs
	prefs.path = test_path
	prefs.buffer_single_pref("tgui_panel_state", "новое состояние")
	TEST_ASSERT(prefs.flush_single_prefs(), "одиночная запись не завершилась")
	TEST_ASSERT(prefs.save_preferences(TRUE, TRUE), "полная запись настроек не завершилась")
	prefs.real_name = "New Character"
	TEST_ASSERT(prefs.save_character(TRUE, TRUE), "не записан новый персонаж")
	var/datum/player_save_json/account/account = new(test_path)
	var/savefile/readback = account.open()
	var/unknown
	readback["unknown_root"] >> unknown
	TEST_ASSERT_EQUAL(unknown, "неизвестное поле", "частичная запись потеряла неизвестный ключ корня")
	readback.cd = "/character128/retired"
	var/value
	readback["value"] >> value
	TEST_ASSERT_EQUAL(value, 1.23456789, "запись другого слота затронула скрытый слот")
	prefs.path = null

/datum/unit_test/player_save_json/unsupported_legacy_blocks/Run()
	prepare()
	var/savefile/legacy = new(test_path)
	legacy["version"] << 17
	legacy["real_name"] << "Do Not Erase"
	legacy.Flush()
	legacy = null
	var/before = rustg_hash_file(RUSTG_HASH_MD5, test_path)
	var/datum/preferences/prefs = new
	allocated += prefs
	prefs.path = test_path
	TEST_ASSERT(!prefs.load_preferences(TRUE), "неподдерживаемое сохранение принято")
	TEST_ASSERT(!prefs.save_preferences(TRUE, TRUE), "старое сохранение заменено настройками по умолчанию")
	TEST_ASSERT(!prefs.save_character(TRUE, TRUE), "старое сохранение заменено случайным персонажем")
	TEST_ASSERT_EQUAL(rustg_hash_file(RUSTG_HASH_MD5, test_path), before, "неподдерживаемый .sav изменён")
	TEST_ASSERT(!fexists("[test_path].json"), "для неподдерживаемого .sav создан JSON с пустыми настройками")
	prefs.path = null

/datum/player_save_json/account/reject_root
	var/reject_write = FALSE

/datum/player_save_json/account/reject_root/write_document(destination, encoded)
	if(reject_write)
		return FALSE
	return ..()

/datum/unit_test/player_save_json/unpublished_character_is_invisible/Run()
	prepare()
	var/datum/player_save_json/account/reject_root/account = new(test_path)
	var/savefile/source = account.open()
	source["version"] << 80
	source.cd = "/character1"
	source["real_name"] << "Before Failure"
	TEST_ASSERT(account.commit(source), "не записано начальное состояние аккаунта")
	source = account.open("/character1")
	source.cd = "/character1"
	source["real_name"] << "Unpublished"
	account.reject_write = TRUE
	TEST_ASSERT(!account.commit(source, "/character1"), "запись корня не была отклонена")
	var/datum/player_save_json/account/reopened = new(test_path)
	var/savefile/restored = reopened.open()
	TEST_ASSERT_NOTNULL(restored, "сбой публикации сделал старое поколение нечитаемым")
	restored.cd = "/character1"
	var/name
	restored["real_name"] >> name
	TEST_ASSERT_EQUAL(name, "Before Failure", "неопубликованный раздел стал виден игроку")
	// Повторная попытка обязана перезаписать сиротское поколение, сохранив опубликованное.
	restored["real_name"] << "After Retry"
	TEST_ASSERT(reopened.commit(restored, "/character1"), "не удалось повторить запись после сбоя")
	restored = reopened.open()
	restored.cd = "/character1"
	restored["real_name"] >> name
	TEST_ASSERT_EQUAL(name, "After Retry", "повторная запись не опубликована")

/datum/unit_test/player_save_json/account_root_recovery/Run()
	prepare()
	var/datum/player_save_json/account/account = new(test_path)
	var/savefile/source = account.open()
	source["version"] << 80
	source.cd = "/character1"
	source["real_name"] << "First Generation"
	TEST_ASSERT(account.commit(source), "не записано первое поколение")
	source = account.open("/character1")
	source.cd = "/character1"
	source["real_name"] << "Second Generation"
	TEST_ASSERT(account.commit(source, "/character1"), "не записано второе поколение")
	fdel(account.active_path)
	text2file("{", account.active_path)
	var/datum/player_save_json/account/reopened = new(test_path)
	source = reopened.open()
	TEST_ASSERT_NOTNULL(source, "не восстановлен предыдущий каталог")
	source.cd = "/character1"
	var/name
	source["real_name"] >> name
	TEST_ASSERT_EQUAL(name, "First Generation", "старый корень прочитал новое поколение персонажа")

/datum/unit_test/player_save_json/root_cache_invalidation/Run()
	prepare()
	var/datum/player_save_json/account/first = new(test_path)
	var/savefile/source = first.open()
	source["version"] << 80
	source["marker"] << "initial"
	TEST_ASSERT(first.commit(source), "не создан корень")
	var/datum/player_save_json/account/second = new(test_path)
	second.open("/")
	source = first.open("/")
	source["marker"] << "changed"
	TEST_ASSERT(first.commit(source, "/"), "не изменён корень")
	source = second.open("/")
	var/marker
	source["marker"] >> marker
	TEST_ASSERT_EQUAL(marker, "changed", "второй датум прочитал устаревший кэш")
	source["another"] << TRUE
	TEST_ASSERT(second.commit(source, "/"), "не записана настройка второго датума")
	source = first.open("/")
	source["another"] >> marker
	TEST_ASSERT_EQUAL(marker, TRUE, "первый датум не увидел запись второго")

/datum/unit_test/player_save_json/custom_interactions_marker/Run()
	prepare()
	var/datum/preferences/prefs = new
	allocated += prefs
	prefs.path = test_path
	TEST_ASSERT(prefs.save_preferences(TRUE, TRUE), "не создан аккаунт")
	var/savefile/source = prefs.open_player_save()
	var/datum/interaction/custom/custom = new
	custom.name = "Test Interaction"
	custom.message = "Test message."
	source["custom_interactions"] << list(custom)
	TEST_ASSERT(prefs.commit_player_save(source), "не записаны старые взаимодействия")
	source = prefs.open_player_save()
	source.cd = "/character1"
	TEST_ASSERT(prefs.sand_character_pref_load(source), "не перенесены старые взаимодействия")
	TEST_ASSERT_EQUAL(length(prefs.custom_interactions), 1, "старый список не загружен")
	source = prefs.open_player_save()
	var/migrated
	source["custom_interactions_migrated"] >> migrated
	TEST_ASSERT_EQUAL(migrated, TRUE, "маркер миграции не зафиксирован вместе со слотом")
	source.cd = "/character2"
	TEST_ASSERT(prefs.sand_character_pref_load(source), "не загружен новый слот")
	TEST_ASSERT_EQUAL(length(prefs.custom_interactions), 0, "старые взаимодействия повторно скопированы в другой слот")
	prefs.path = null

/datum/unit_test/player_save_json/portable_character/Run()
	prepare()
	var/datum/preferences/prefs = new
	allocated += prefs
	prefs.path = test_path
	prefs.real_name = "Portable Character"
	prefs.belly_prefs = list(list("name" = "Portable setting"))
	var/savefile/exported = prefs.save_character(TRUE, TRUE, TRUE)
	TEST_ASSERT_NOTNULL(exported, "персонаж не экспортирован")
	TEST_ASSERT(!storage.exists(), "экспорт записал данные аккаунта")
	var/datum/preferences/imported = new
	allocated += imported
	TEST_ASSERT(imported.load_character(null, TRUE, exported), "импорт потребовал существующий сейв аккаунта")
	TEST_ASSERT_EQUAL(imported.real_name, "Portable Character", "импорт изменил имя")
	var/list/belly = imported.belly_prefs[1]
	TEST_ASSERT_EQUAL(belly["name"], "Portable setting", "экспорт потерял настройку из бывшего отдельного JSON")
	prefs.path = null


/datum/unit_test/player_save_json/public_transfer/Run()
	prepare()
	var/datum/preferences/prefs = new
	allocated += prefs
	prefs.path = test_path
	prefs.real_name = "Public Character"
	prefs.modified_limbs = list(BODY_ZONE_L_ARM = list(LOADOUT_LIMB_PROSTHETIC, "prosthetic"))
	prefs.features["ooc_notes"] = "PRIVATE_OOC"
	prefs.features["headshot_links"] = list("https://private.invalid/image")
	prefs.tcg_cards = list("protected card" = 4)
	prefs.unlockable_loadout_data = list("protected entitlement" = 8)
	prefs.metadollar_minute_pool = 123
	var/datum/interaction/custom/custom = new
	custom.name = "Public Action"
	custom.message = "Public message."
	prefs.custom_interactions = list(custom)
	prefs.queue_save_char(1000, TRUE)
	var/queued = prefs.char_queue
	var/exported = prefs.export_character_json()
	TEST_ASSERT_EQUAL(prefs.char_queue, queued, "экспорт отменил отложенное сохранение")
	TEST_ASSERT_NOTNULL(exported, "экспорт не выполнен: [prefs.player_transfer_error]")
	TEST_ASSERT(!findtext(exported, "PRIVATE_OOC") && !findtext(exported, "private.invalid") && !findtext(exported, "protected card") && !findtext(exported, "protected entitlement"), "экспорт раскрыл закрытые данные")
	TEST_ASSERT(!storage.exists(), "экспорт изменил диск")
	TEST_ASSERT(prefs.save_preferences(TRUE, TRUE), "не создан корень")
	TEST_ASSERT(prefs.save_character(TRUE, TRUE), "не создан слот")
	var/savefile/root = prefs.open_player_save("/")
	root["metadollars"] << 9876
	root["future_private"] << "preserve"
	TEST_ASSERT(prefs.commit_player_save(root, "/"), "не записаны защищённые поля")
	prefs.tcg_cards["protected card"] = 5 // ещё не записанная награда тоже должна сохраниться
	var/list/document = json_decode(exported)
	var/list/fields = document["fields"]
	fields["real_name"] = "Imported Character"
	TEST_ASSERT(prefs.import_character_json(json_encode(document)), "импорт не выполнен: [prefs.player_transfer_error]")
	TEST_ASSERT_EQUAL(prefs.real_name, "Imported Character", "имя не перенесено")
	TEST_ASSERT_EQUAL(prefs.modified_limbs[BODY_ZONE_L_ARM][1], LOADOUT_LIMB_PROSTHETIC, "не перенесён протез")
	TEST_ASSERT_EQUAL(prefs.tcg_cards["protected card"], 5, "импорт изменил коллекцию")
	TEST_ASSERT_EQUAL(prefs.metadollar_minute_pool, 123, "импорт изменил выплату")
	TEST_ASSERT_EQUAL(prefs.features["ooc_notes"], "PRIVATE_OOC", "импорт изменил закрытые заметки")
	TEST_ASSERT_EQUAL(length(prefs.custom_interactions), 1, "не перенесено пользовательское действие")
	root = prefs.open_player_save("/")
	var/balance
	root["metadollars"] >> balance
	TEST_ASSERT_EQUAL(balance, 9876, "импорт изменил серверный баланс")
	root["future_private"] >> balance
	TEST_ASSERT_EQUAL(balance, "preserve", "импорт потерял неизвестное закрытое поле")
	prefs.path = null

/datum/unit_test/player_save_json/public_transfer_rejects/Run()
	var/list/forbidden = list("metadollars", "metadollar_pending_items", "tcg_cards", "unlockable_loadout", "default_slot", "version", "../character2", "headshot", "belly_prefs", "new_unreviewed_field")
	for(var/key in forbidden)
		var/rejected = FALSE
		var/list/fields = list("real_name" = "Bad")
		fields[key] = 999
		try
			player_transfer_parse(json_encode(list("format" = "bluemoon-character", "version" = 1, "fields" = fields)))
		catch
			rejected = TRUE
		TEST_ASSERT(rejected, "разрешено защищённое поле [key]")
	for(var/tag in list("byond", "path", "matrix"))
		var/rejected = FALSE
		var/list/injected = list("type" = tag, "value" = "/obj/item", "text" = "malicious")
		var/list/nested = list("type" = "list", "items" = list(injected), "associations" = list(null))
		try
			player_transfer_parse(json_encode(list("format" = "bluemoon-character", "version" = 1, "fields" = list("custom_emote_panel" = nested))))
		catch
			rejected = TRUE
		TEST_ASSERT(rejected, "разрешён вложенный тип [tag]")

/datum/unit_test/player_save_json/public_transfer_failure/Run()
	prepare()
	var/datum/preferences/prefs = new
	allocated += prefs
	prefs.path = test_path
	prefs.real_name = "Before Import"
	TEST_ASSERT(prefs.save_preferences(TRUE, TRUE), "не создан корень")
	TEST_ASSERT(prefs.save_character(TRUE, TRUE), "не создан слот")
	var/datum/player_save_json/account/reject_root/rejecting = new(test_path)
	prefs.player_save_storage = rejecting
	TEST_ASSERT_NOTNULL(rejecting.open(), "не прочитан исходный слот")
	var/document = json_encode(list("format" = "bluemoon-character", "version" = 1, "fields" = list("real_name" = "After Import")))
	rejecting.reject_write = TRUE
	TEST_ASSERT(!prefs.import_character_json(document), "ошибка диска показана как успех")
	TEST_ASSERT_EQUAL(prefs.real_name, "Before Import", "ошибка записи изменила живые настройки")
	var/datum/player_save_json/account/reopened = new(test_path)
	var/savefile/source = reopened.open()
	source.cd = "/character1"
	var/name
	source["real_name"] >> name
	TEST_ASSERT_EQUAL(name, "Before Import", "ошибка импорта изменила опубликованный слот")
	prefs.path = null

/datum/unit_test/player_save_json/public_transfer_invalid_unchanged/Run()
	prepare()
	var/datum/preferences/prefs = new
	allocated += prefs
	prefs.path = test_path
	prefs.real_name = "Unchanged Character"
	TEST_ASSERT(prefs.save_preferences(TRUE, TRUE), "не создан корень")
	TEST_ASSERT(prefs.save_character(TRUE, TRUE), "не создан слот")
	var/generation = prefs.player_save_storage.generation
	for(var/bad in list("{", "[]", json_encode(list("format" = "bluemoon-character", "version" = 99, "fields" = list("real_name" = "Bad"))), json_encode(list("format" = "bluemoon-character", "version" = 1, "fields" = list("real_name" = list("type" = "list", "items" = list(), "associations" = list()))))))
		TEST_ASSERT(!prefs.import_character_json(bad), "принят неверный файл")
		TEST_ASSERT_EQUAL(prefs.real_name, "Unchanged Character", "неверный файл изменил имя")
		TEST_ASSERT_EQUAL(prefs.player_save_storage.generation, generation, "неверный файл записал поколение")
	TEST_ASSERT(!prefs.player_save_blocked, "неверный файл заблокировал обычное сохранение")
	prefs.path = null

/datum/unit_test/player_save_json/name_cache/Run()
	prepare()
	var/datum/player_save_json/account/account = new(test_path)
	var/savefile/source = account.open()
	source["version"] << 80
	source.cd = "/character1"
	source["real_name"] << "First Name"
	source.cd = "/character128"
	source["real_name"] << "Hidden Name"
	TEST_ASSERT(account.commit(source), "не созданы слоты")
	var/list/names = account.character_names(2)
	TEST_ASSERT_EQUAL(names["character1"], "First Name", "нет имени первого слота")
	TEST_ASSERT(!("character128" in names), "меню прочитало скрытый слот")
	source = account.open("/character1")
	source.cd = "/character1"
	source["real_name"] << "Renamed Character"
	TEST_ASSERT(account.commit(source, "/character1"), "не переименован слот")
	names = account.character_names(2)
	TEST_ASSERT_EQUAL(names["character1"], "Renamed Character", "кэш не обновил имя")
	source = account.open("/")
	source["ui_setting"] << 1
	TEST_ASSERT(account.commit(source, "/"), "не записана настройка корня")
	names = account.character_names(2)
	TEST_ASSERT_EQUAL(names["character1"], "Renamed Character", "настройка корня испортила кэш")


/datum/unit_test/player_save_json/unchanged_save/Run()
	prepare()
	var/datum/player_save_json/account/account = new(test_path)
	var/savefile/source = account.open()
	source["version"] << 80
	source.cd = "/character1"
	source["real_name"] << "Unchanged"
	TEST_ASSERT(account.commit(source), "не записан исходный аккаунт")
	var/root_generation = account.generation
	var/character_generation = account.directories["character1"]
	source = account.open("/character1")
	TEST_ASSERT(account.commit(source, "/character1"), "повторная запись завершилась ошибкой")
	TEST_ASSERT_EQUAL(account.generation, root_generation, "неизменившийся корень записан повторно")
	TEST_ASSERT_EQUAL(account.directories["character1"], character_generation, "неизменившийся слот записан повторно")
	source.cd = "/character1"
	source["real_name"] << "Changed"
	TEST_ASSERT(account.commit(source, "/character1"), "изменение не записано")
	TEST_ASSERT_EQUAL(account.generation, root_generation + 1, "изменённый корень не записан")
	TEST_ASSERT_EQUAL(account.directories["character1"], character_generation + 1, "изменённый слот не записан")

/datum/unit_test/player_save_json/public_transfer_limits/Run()
	var/list/deep = list("end")
	for(var/i in 1 to 20)
		deep = list(deep)
	var/rejected = FALSE
	try
		player_transfer_parse(json_encode(list("format" = "bluemoon-character", "version" = 1, "fields" = list("custom_emote_panel" = player_save_encode_value(deep)))))
	catch
		rejected = TRUE
	TEST_ASSERT(rejected, "не ограничена глубина вложенности")
	rejected = FALSE
	try
		player_transfer_parse(json_encode(list("format" = "bluemoon-character", "version" = 1, "fields" = list("loadout" = json_encode(list("SAVE_1" = list(list(LOADOUT_ITEM = "/obj/item"))))))))
	catch
		rejected = TRUE
	TEST_ASSERT(rejected, "в экипировке принят произвольный тип объекта")
	var/list/safe = player_transfer_parse(json_encode(list("format" = "bluemoon-character", "version" = 1, "fields" = list("medical_records" = "<script>bad</script> &amp; text"))))
	TEST_ASSERT(!findtext(safe["medical_records"], "<"), "импорт оставил активный HTML")
	TEST_ASSERT(!findtext(safe["medical_records"], "&amp;amp;"), "импорт повторно экранировал существующие сущности")

/datum/unit_test/player_save_json/public_transfer_access/Run()
	prepare()
	var/datum/preferences/prefs = new
	allocated += prefs
	prefs.path = test_path
	prefs.real_name = "Protected Character"
	TEST_ASSERT(prefs.save_preferences(TRUE, TRUE), "не создан аккаунт")
	TEST_ASSERT(prefs.save_character(TRUE, TRUE), "не создан слот")
	var/rejected = json_encode(list("format" = "bluemoon-character", "version" = 1, "fields" = list("all_quirks" = player_save_encode_value(list("Nonexistent Quirk")))))
	TEST_ASSERT(!prefs.import_character_json(rejected), "принят несуществующий квирк")
	var/datum/gear/locked
	for(var/category in GLOB.loadout_items)
		var/list/subcategories = GLOB.loadout_items[category]
		for(var/subcategory in subcategories)
			var/list/items = subcategories[subcategory]
			for(var/name in items)
				var/datum/gear/gear = items[name]
				if(gear.donoritem)
					locked = gear
					break
	TEST_ASSERT_NOTNULL(locked, "в фикстуре нет закрытого предмета")
	var/list/loadout = list("SAVE_1" = list(list(LOADOUT_ITEM = "[locked.type]")))
	rejected = json_encode(list("format" = "bluemoon-character", "version" = 1, "fields" = list("loadout" = json_encode(loadout))))
	TEST_ASSERT(!prefs.import_character_json(rejected), "импорт открыл донатный предмет")
	TEST_ASSERT_EQUAL(prefs.real_name, "Protected Character", "отказ изменил персонажа")
	prefs.path = null


/datum/unit_test/player_save_json/name_cache_recovery/Run()
	prepare()
	var/datum/player_save_json/account/account = new(test_path)
	var/savefile/source = account.open()
	source["version"] << 80
	source.cd = "/character1"
	source["real_name"] << "Previous Name"
	TEST_ASSERT(account.commit(source), "не создан первый слот")
	source = account.open("/character1")
	source.cd = "/character1"
	source["real_name"] << "Current Name"
	TEST_ASSERT(account.commit(source, "/character1"), "не создан второй слот")
	var/datum/player_save_json/child = account.branch("character1")
	fdel(child.active_path)
	text2file("{", child.active_path)
	var/datum/player_save_json/account/reopened = new(test_path)
	var/list/names = reopened.character_names(2)
	TEST_ASSERT(islist(names), "меню заблокировало доступное предыдущее поколение")
	TEST_ASSERT_EQUAL(names["character1"], "Current Name", "меню не использовало опубликованное имя")
	TEST_ASSERT_NOTNULL(reopened.open("/character1"), "загрузка слота не восстановила предыдущий снимок")
	names = reopened.character_names(2)
	TEST_ASSERT_EQUAL(names["character1"], "Previous Name", "меню не восстановило согласованный снимок")


/datum/unit_test/player_save_json/public_transfer_account_limit/Run()
	prepare()
	var/datum/preferences/transfer_staging/prefs = new
	allocated += prefs
	var/base_limit = prefs.get_custom_interaction_limit()
	prefs.interaction_limit = base_limit + 5
	prefs.path = test_path
	prefs.real_name = "Account Limit"
	prefs.custom_interactions = list()
	for(var/i in 1 to base_limit + 1)
		var/datum/interaction/custom/custom = new
		custom.name = "Action [i]"
		custom.message = "Test action."
		prefs.custom_interactions += custom
	TEST_ASSERT(prefs.save_preferences(TRUE, TRUE), "не создан аккаунт")
	TEST_ASSERT(prefs.save_character(TRUE, TRUE), "не создан слот")
	var/exported = prefs.export_character_json()
	TEST_ASSERT_NOTNULL(exported, "не экспортированы действия подписчика")
	TEST_ASSERT(prefs.import_character_json(exported), "не учтён лимит принимающего аккаунта: [prefs.player_transfer_error]")
	TEST_ASSERT_EQUAL(length(prefs.custom_interactions), base_limit + 1, "пробный объект обрезал действия до бесплатного лимита")
	prefs.interaction_limit = base_limit
	TEST_ASSERT(!prefs.import_character_json(exported), "файл обошёл лимит принимающего аккаунта")
	prefs.path = null

/datum/unit_test/player_save_json/scalar_precision/Run()
	var/savefile/source = prepare()
	var/list/values = list(0, -1, 999999, -999999, 1000001, -1000001, 16777216, 0.1, -0.1, 1.23456789, 1e-20, 1e20, "", "Кириллица, emoji 😀, ÿ, %ff, %25, кавычки \" и \\", "\proper Имя", "\improper Имя")
	for(var/code in 1 to 31)
		values += "начало[ascii2text(code)]конец %ff %25"
	for(var/index in 1 to values.len)
		source["value_[index]"] << values[index]
	TEST_ASSERT(storage.commit(source), "не записаны скаляры: [storage.error]")
	var/savefile/restored = storage.open()
	TEST_ASSERT_NOTNULL(restored, "не прочитаны скаляры: [storage.error]")
	for(var/index in 1 to values.len)
		var/value
		restored["value_[index]"] >> value
		TEST_ASSERT_EQUAL(value, values[index], "изменилось значение скаляра [index]")

/datum/unit_test/player_save_json/v1_checksum/Run()
	prepare()
	// Старый писатель кодировал список целиком. Читатель должен принимать его файлы.
	var/list/tree = list("value" = list("value" = "Текст \" \\ \n", "children" = list()))
	var/list/document = list("format" = "bluemoon-player-save", "version" = 1, "generation" = 1, "tree" = tree, "directories" = null, "checksum" = md5(json_encode(list(1, tree, null))))
	text2file(json_encode(document), storage.json_path)
	var/savefile/source = storage.open()
	TEST_ASSERT_NOTNULL(source, "не прочитан старый формат v1")
	source["value"] << "Изменено"
	TEST_ASSERT(storage.commit(source), "не записан новый JSON")
	document = json_decode(file2text(storage.active_path))
	TEST_ASSERT_EQUAL(document["checksum"], md5(json_encode(list(document["generation"], document["tree"], document["directories"]))), "новая контрольная сумма несовместима с v1")
	// Повреждение остаётся валидным JSON, поэтому его должна заметить именно сумма.
	tree = document["tree"]
	var/list/node = tree["value"]
	node["value"] = "Повреждено"
	fdel(storage.active_path)
	text2file(json_encode(document), storage.active_path)
	source = storage.open()
	TEST_ASSERT_NOTNULL(source, "не восстановлено поколение после ошибки суммы")
	TEST_ASSERT(storage.recovered, "повреждение не замечено")
	var/value
	source["value"] >> value
	TEST_ASSERT_EQUAL(value, "Текст \" \\ \n", "прочитаны повреждённые данные")

/datum/unit_test/player_save_json/root_cache_isolation/Run()
	prepare()
	var/datum/player_save_json/account/account = new(test_path)
	var/savefile/source = account.open()
	source["marker"] << "Сохранено"
	TEST_ASSERT(account.commit(source), "не создан корень")
	for(var/iteration in 1 to 3)
		source = account.open("/")
		var/marker
		source["marker"] >> marker
		TEST_ASSERT_EQUAL(marker, "Сохранено", "несохранённые изменения попали в кэш")
		source["marker"] << "Не сохранено"
		source.cd = "/temporary"
		source["value"] << iteration

/datum/unit_test/player_save_json/document_isolation/Run()
	var/savefile/source = prepare()
	source["settings"] << list("nested" = list("value" = 1))
	TEST_ASSERT(storage.commit(source), "не создан снимок")
	var/datum/player_save_document/first = storage.snapshot()
	var/datum/player_save_document/second = storage.snapshot()
	var/list/values = first.read("settings")
	var/list/nested = values["nested"]
	nested["value"] = 2
	var/list/unchanged = second.read("settings")
	TEST_ASSERT_EQUAL(unchanged["nested"]["value"], 1, "чтение отдало общий изменяемый список")
	first.write("settings", values)
	nested["value"] = 3
	unchanged = second.read("settings")
	TEST_ASSERT_EQUAL(unchanged["nested"]["value"], 1, "подготовка записи изменила другой снимок")
	TEST_ASSERT(first.commit(), "не записан документ")
	var/datum/player_save_document/current = storage.snapshot()
	values = current.read("settings")
	TEST_ASSERT_EQUAL(values["nested"]["value"], 2, "запись сохранила ссылку на список вызывающего")
	var/generation = storage.generation
	TEST_ASSERT(!current.write("settings", values), "одинаковые данные отмечены изменёнными")
	TEST_ASSERT(current.commit(), "неизменённый документ не принят")
	TEST_ASSERT_EQUAL(storage.generation, generation, "повторный commit записал новое поколение")

/datum/unit_test/player_save_json/document_stale_writer/Run()
	var/savefile/source = prepare()
	source["marker"] << 1
	TEST_ASSERT(storage.commit(source), "не создан снимок")
	var/datum/player_save_document/stale = storage.snapshot()
	var/datum/player_save_json/other = new(test_path)
	var/datum/player_save_document/current = other.snapshot()
	current.write("marker", 2)
	TEST_ASSERT(current.commit(), "не записана конкурирующая правка")
	stale.write("marker", 3)
	TEST_ASSERT(!stale.commit(), "устаревший снимок затёр чужую запись")
	current = storage.snapshot()
	TEST_ASSERT_EQUAL(current.read("marker"), 2, "не прочитана актуальная ревизия")

/datum/unit_test/player_save_json/savefile_stale_writer/Run()
	var/savefile/source = prepare()
	source["marker"] << 1
	TEST_ASSERT(storage.commit(source), "не создан снимок")
	var/datum/player_save_json/other = new(test_path)
	var/datum/player_save_document/current = other.snapshot()
	current.write("marker", 2)
	TEST_ASSERT(current.commit(), "не записана конкурирующая правка")
	source["marker"] << 3
	TEST_ASSERT(!storage.commit(source), "устаревший savefile затёр чужую запись")
	current = storage.snapshot()
	TEST_ASSERT_EQUAL(current.read("marker"), 2, "не прочитана актуальная ревизия")

/datum/unit_test/player_save_json/account_savefile_stale_writer/Run()
	prepare()
	var/datum/player_save_json/account/account = new(test_path)
	var/savefile/source = account.open()
	source["marker"] << 1
	source.cd = "/character1"
	source["real_name"] << "Published"
	TEST_ASSERT(account.commit(source), "не создан аккаунт")
	source = account.open("/character1")
	var/datum/player_save_json/account/other = new(test_path)
	var/datum/player_save_document/current = other.snapshot()
	current.write("marker", 2)
	TEST_ASSERT(current.commit(), "не записана конкурирующая правка корня")
	var/datum/player_save_json/child = account.branch("character1")
	var/child_revision = player_save_revision(child.json_path)
	source.cd = "/character1"
	source["real_name"] << "Stale"
	TEST_ASSERT(!account.commit(source, "/character1"), "устаревшая анкета затёрла чужой корень")
	TEST_ASSERT_EQUAL(source.cd, "/character1", "ошибка записи изменила директорию источника")
	TEST_ASSERT_EQUAL(player_save_revision(child.json_path), child_revision, "устаревшая транзакция успела записать раздел")
	current = account.snapshot()
	TEST_ASSERT_EQUAL(current.read("marker"), 2, "потеряна чужая настройка корня")
	var/list/names = account.character_names(1)
	TEST_ASSERT_EQUAL(names["character1"], "Published", "неопубликованная анкета стала видимой")

/datum/unit_test/player_save_json/character_patch_preserves_unknown/Run()
	prepare()
	var/datum/preferences/prefs = new
	allocated += prefs
	prefs.path = test_path
	TEST_ASSERT(prefs.save_preferences(TRUE, TRUE), "не создан корень")
	TEST_ASSERT(prefs.save_character(TRUE, TRUE), "не создан персонаж")
	var/savefile/source = prefs.open_player_save("/character1")
	source["unknown_root"] << "Root"
	source.cd = "/character1/unknown_module"
	source["value"] << list("future" = 1.23456789)
	source.cd = "/character1/real_name/unknown_child"
	source["value"] << "Nested"
	TEST_ASSERT(prefs.commit_player_save(source, "/character1"), "не записаны неизвестные поля")
	prefs.real_name = "Patched Character"
	TEST_ASSERT(prefs.save_character(TRUE, TRUE), "не записана правка персонажа")
	TEST_ASSERT(prefs.save_preferences(TRUE, TRUE), "не записана правка корня")
	source = prefs.open_player_save("/character1")
	var/value
	source["unknown_root"] >> value
	TEST_ASSERT_EQUAL(value, "Root", "потеряно неизвестное поле корня")
	source.cd = "/character1"
	source["real_name"] >> value
	TEST_ASSERT_EQUAL(value, "Patched Character", "не изменено имя")
	source.cd = "/character1/real_name/unknown_child"
	source["value"] >> value
	TEST_ASSERT_EQUAL(value, "Nested", "правка значения удалила дочерний узел")
	source.cd = "/character1/unknown_module"
	var/list/numbers
	source["value"] >> numbers
	TEST_ASSERT_EQUAL(numbers["future"], 1.23456789, "потерян неизвестный раздел")
	prefs.path = null

/datum/unit_test/player_save_json/character_patch_publication_failure/Run()
	prepare()
	var/datum/player_save_json/account/reject_root/account = new(test_path)
	var/savefile/source = account.open()
	source["version"] << 80
	source.cd = "/character1"
	source["real_name"] << "Published"
	TEST_ASSERT(account.commit(source), "не создан аккаунт")
	var/datum/player_save_character_transaction/transaction = account.character_transaction("character1")
	source["real_name"] << "Unpublished"
	account.reject_write = TRUE
	TEST_ASSERT(!transaction.commit(source), "ошибка публикации проигнорирована")
	var/datum/player_save_json/account/reopened = new(test_path)
	var/list/names = reopened.character_names(1)
	TEST_ASSERT_EQUAL(names["character1"], "Published", "меню показало неопубликованное имя")
	transaction = reopened.character_transaction("character1")
	source["real_name"] << "Retried"
	TEST_ASSERT(transaction.commit(source), "не удалась повторная запись")
	names = reopened.character_names(1)
	TEST_ASSERT_EQUAL(names["character1"], "Retried", "повторная запись не опубликована")

/datum/unit_test/player_save_json/single_document_write_failure/Run()
	prepare()
	var/datum/preferences/prefs = new
	allocated += prefs
	prefs.path = test_path
	TEST_ASSERT(prefs.save_preferences(TRUE, TRUE), "не создан корень")
	var/datum/player_save_json/account/reject_root/rejecting = new(test_path)
	prefs.player_save_storage = rejecting
	rejecting.reject_write = TRUE
	prefs.buffer_single_pref("tgui_panel_state", "pending")
	TEST_ASSERT(!prefs.flush_single_prefs(), "не замечена ошибка записи")
	TEST_ASSERT_EQUAL(prefs.pending_single_prefs["tgui_panel_state"], "pending", "ошибка записи потеряла буфер")
	prefs.path = null

/datum/unit_test/player_save_json/character_patch_recovery/Run()
	prepare()
	var/datum/player_save_json/account/account = new(test_path)
	var/savefile/source = account.open()
	source["version"] << 80
	source.cd = "/character1"
	source["real_name"] << "Previous"
	TEST_ASSERT(account.commit(source), "не создано предыдущее поколение")
	var/datum/player_save_character_transaction/transaction = account.character_transaction("character1")
	source["real_name"] << "Current"
	TEST_ASSERT(transaction.commit(source), "не создано текущее поколение")
	var/datum/player_save_json/child = account.branch("character1")
	fdel(child.active_path)
	text2file("{", child.active_path)
	var/datum/player_save_json/account/reopened = new(test_path)
	transaction = reopened.character_transaction("character1")
	TEST_ASSERT_NOTNULL(transaction, "правка не смогла восстановить предыдущий снимок")
	TEST_ASSERT_EQUAL(transaction.character.read("real_name"), "Previous", "выбрано несогласованное поколение")
	source["real_name"] << "Recovered"
	TEST_ASSERT(transaction.commit(source), "не записано восстановленное состояние")
	var/list/names = reopened.character_names(1)
	TEST_ASSERT_EQUAL(names["character1"], "Recovered", "не опубликовано восстановление")

/datum/unit_test/player_save_json/character_patch_deleted_slot/Run()
	prepare()
	var/datum/player_save_json/account/account = new(test_path)
	var/savefile/source = account.open()
	source["version"] << 80
	source.cd = "/character1"
	source["old_private"] << "Old"
	TEST_ASSERT(account.commit(source), "не создан старый слот")
	var/savefile/without_character = new
	without_character["version"] << 80
	TEST_ASSERT(account.commit(without_character), "не удалён слот")
	var/datum/player_save_character_transaction/transaction = account.character_transaction("character1")
	TEST_ASSERT_NULL(transaction.character.read("old_private"), "новый слот унаследовал удалённые поля")
	var/savefile/patch = new
	patch.cd = "/character1"
	patch["real_name"] << "New"
	TEST_ASSERT(transaction.commit(patch), "не создан новый слот")
	var/datum/player_save_json/account/reopened = new(test_path)
	transaction = reopened.character_transaction("character1")
	TEST_ASSERT_NULL(transaction.character.read("old_private"), "удалённое поле вернулось с диска")
	TEST_ASSERT_EQUAL(transaction.character.read("real_name"), "New", "новое имя не записано")

/datum/unit_test/player_save_json/branch_cache_revision_and_limit/Run()
	prepare()
	var/datum/player_save_json/account/account = new(test_path)
	var/savefile/source = account.open()
	source["version"] << 80
	for(var/slot in 1 to 5)
		source.cd = "/character[slot]"
		source["real_name"] << "Character [slot]"
	TEST_ASSERT(account.commit(source), "не созданы слоты")
	for(var/slot in 1 to 5)
		TEST_ASSERT_NOTNULL(account.open("/character[slot]"), "не прочитан слот")
		TEST_ASSERT(length(account.branches) <= 2, "кэш удерживает все посещённые слоты")
	var/datum/player_save_json/account/other = new(test_path)
	var/datum/player_save_character_transaction/transaction = other.character_transaction("character5")
	var/savefile/patch = new
	patch.cd = "/character5"
	patch["real_name"] << "Changed elsewhere"
	TEST_ASSERT(transaction.commit(patch), "не записано изменение другим датумом")
	source = account.open("/character5")
	source.cd = "/character5"
	var/name
	source["real_name"] >> name
	TEST_ASSERT_EQUAL(name, "Changed elsewhere", "кэш раздела проигнорировал чужую запись")

/datum/unit_test/player_save_json/document_directory_recovery/Run()
	prepare()
	var/datum/player_save_json/account/account = new(test_path)
	var/savefile/source = account.open()
	source["marker"] << 1
	source.cd = "/character1"
	source["real_name"] << "Published"
	TEST_ASSERT(account.commit(source), "не создан аккаунт")
	var/datum/player_save_document/document = account.snapshot()
	document.write("marker", 2)
	TEST_ASSERT(document.commit(), "не создан второй корень")
	var/list/corrupted = json_decode(file2text(account.active_path))
	var/list/tree = corrupted["tree"]
	tree -= "character1"
	corrupted["checksum"] = md5(json_encode(list(corrupted["generation"], tree, corrupted["directories"])))
	fdel(account.active_path)
	text2file(json_encode(corrupted), account.active_path)
	var/datum/player_save_json/account/reopened = new(test_path)
	document = reopened.snapshot()
	TEST_ASSERT_NOTNULL(document, "прямое чтение не восстановило каталог")
	TEST_ASSERT(reopened.recovered, "ошибка каталога не отмечена")
	TEST_ASSERT_EQUAL(document.read("marker"), 1, "прочитан корень с отсутствующим разделом")
	TEST_ASSERT(document.commit(), "не записан исправленный каталог")
	var/list/names = reopened.character_names(1)
	TEST_ASSERT_EQUAL(names["character1"], "Published", "исправление каталога потеряло слот")

/// Счётчики обнаруживают повторное чтение без нестабильных порогов времени.
/datum/player_save_json/read_counted
	var/reads = 0

/datum/player_save_json/read_counted/read_document(source_path, source_text)
	reads++
	return ..()

/datum/player_save_json/account/read_counted/branch(key)
	if(!branches[key])
		branches[key] = new /datum/player_save_json/read_counted("[json_path].d/[md5(key)].sav")
	return ..()

/datum/unit_test/player_save_json/names_reuse_published_document/Run()
	prepare()
	var/datum/player_save_json/account/read_counted/account = new(test_path)
	var/savefile/source = account.open()
	for(var/slot in 1 to 5)
		source.cd = "/character[slot]"
		source["real_name"] << "Character [slot]"
	TEST_ASSERT(account.commit(source), "не созданы слоты")
	account.character_names(5)
	var/datum/player_save_character_transaction/transaction = account.character_transaction("character5")
	transaction.character.write("real_name", "Changed")
	var/savefile/patch = new
	TEST_ASSERT(transaction.commit(patch), "не сохранено новое имя")
	var/datum/player_save_json/read_counted/child = account.branch("character5")
	var/reads = child.reads
	var/list/names = account.character_names(5)
	TEST_ASSERT_EQUAL(names["character5"], "Changed", "меню вернуло старое имя")
	TEST_ASSERT_EQUAL(child.reads, reads, "меню перечитало только что сохранённый документ")
	var/datum/player_save_json/account/other = new(test_path)
	transaction = other.character_transaction("character5")
	transaction.character.write("real_name", "Foreign")
	TEST_ASSERT(transaction.commit(patch), "не записано чужое изменение")
	names = account.character_names(5)
	TEST_ASSERT_EQUAL(names["character5"], "Foreign", "кэш скрыл чужую запись")
	TEST_ASSERT_EQUAL(child.reads, reads, "меню прочитало анкету вместо обновлённого имени в корне")
	account.open("/character1")
	account.open("/character2")
	TEST_ASSERT(!("character5" in account.branches), "старый раздел не вытеснен")
	transaction = other.character_transaction("character5")
	transaction.character.write("real_name", "After eviction")
	TEST_ASSERT(transaction.commit(patch), "не записано изменение вытесненного раздела")
	names = account.character_names(5)
	TEST_ASSERT_EQUAL(names["character5"], "After eviction", "вытеснение оставило устаревшее имя")

/datum/unit_test/player_save_json/unchanged_patch_keeps_snapshot/Run()
	var/savefile/source = prepare()
	source["number"] << 1.23456789
	source["mixed"] << list(null, "key" = list(1, 2), /obj/item)
	source.cd = "/unknown/nested"
	source["marker"] << "retained"
	source.cd = "/"
	TEST_ASSERT(storage.commit(source), "не создан снимок")
	var/datum/player_save_document/document = storage.snapshot()
	var/list/original = document.tree
	var/generation = document.generation
	document.merge(source)
	TEST_ASSERT(!document.dirty, "равные значения пометили документ изменённым")
	TEST_ASSERT(document.tree == original, "равный patch скопировал дерево")
	TEST_ASSERT(document.commit(), "не принят неизменённый снимок")
	TEST_ASSERT_EQUAL(document.generation, generation, "неизменённый patch сменил поколение")
	var/savefile/patch = new
	patch.cd = "/unknown"
	patch["new"] << 42
	patch.cd = "/"
	document.merge(patch)
	TEST_ASSERT(document.dirty, "вложенная правка не отмечена")
	TEST_ASSERT(document.tree != original, "вложенная правка изменила общий снимок")
	TEST_ASSERT(document.commit(), "не записана вложенная правка")
	var/savefile/readback = storage.open()
	readback.cd = "/unknown/nested"
	var/marker
	readback["marker"] >> marker
	TEST_ASSERT_EQUAL(marker, "retained", "patch потерял неизвестную ветвь")
	readback.cd = "/unknown"
	readback["new"] >> marker
	TEST_ASSERT_EQUAL(marker, 42, "вложенная правка не сохранена")

/datum/unit_test/player_save_json/direct_writers_match_compatibility/Run()
	prepare()
	var/datum/preferences/prefs = new_preferences()
	TEST_ASSERT(prefs.save_preferences(TRUE, TRUE), "не создан корень")
	prefs.real_name = "Direct Character"
	prefs.features["body_size"] = 1.23456789
	prefs.tgui_panel_state = "new"
	prefs.favorite_tracks = list("первый", "второй")
	prefs.menuoptions = list(/datum/verbs/menu/Settings = TRUE)
	prefs.buffer_single_pref("tgui_panel_state", "obsolete")
	TEST_ASSERT(prefs.save_preferences(TRUE, TRUE), "не записаны настройки напрямую")
	var/datum/player_save_document/document = prefs.open_player_document()
	TEST_ASSERT_EQUAL(document.read("tgui_panel_state"), "new", "буфер перекрыл актуальную переменную")
	var/savefile/compatibility = prefs.write_preferences(TRUE, TRUE)
	TEST_ASSERT_NULL(patch_difference(player_save_encode_tree(compatibility), document.tree), "прямой писатель настроек отличается от savefile")
	TEST_ASSERT(prefs.save_character(TRUE, TRUE), "не записан персонаж напрямую")
	var/datum/player_save_json/account/account = prefs.get_player_save_storage()
	var/datum/player_save_character_transaction/transaction = account.character_transaction("character1")
	compatibility = prefs.write_character(TRUE, TRUE, TRUE)
	TEST_ASSERT_NULL(patch_difference(player_save_encode_tree(compatibility), transaction.character.tree), "прямой писатель персонажа отличается от экспорта")
	var/root_generation = account.generation
	var/character_generation = transaction.character.generation
	TEST_ASSERT(prefs.save_preferences(TRUE, TRUE), "не приняты неизменённые настройки")
	TEST_ASSERT(prefs.save_character(TRUE, TRUE), "не принят неизменённый персонаж")
	TEST_ASSERT_EQUAL(account.generation, root_generation, "неизменённые префы сменили корневое поколение")
	transaction = account.character_transaction("character1")
	TEST_ASSERT_EQUAL(transaction.character.generation, character_generation, "неизменённый персонаж сменил поколение")

/datum/unit_test/player_save_json/direct_writer_failure_preserves_cache/Run()
	prepare()
	var/datum/preferences/prefs = new_preferences()
	TEST_ASSERT(prefs.save_preferences(TRUE, TRUE), "не создан корень")
	var/datum/player_save_document/before = prefs.open_player_document()
	var/old_theme = before.read("tgui_panel_theme")
	var/datum/player_save_json/account/reject_root/rejecting = new(test_path)
	prefs.player_save_storage = rejecting
	rejecting.reject_write = TRUE
	prefs.tgui_panel_theme = "must not persist"
	prefs.buffer_single_pref("tgui_panel_state", "pending")
	TEST_ASSERT(!prefs.save_preferences(TRUE, TRUE), "проигнорирован отказ записи")
	TEST_ASSERT_EQUAL(prefs.pending_single_prefs["tgui_panel_state"], "pending", "отказ полной записи потерял буфер")
	TEST_ASSERT_EQUAL(before.read("tgui_panel_theme"), old_theme, "подготовка изменила выданный снимок")
	var/datum/player_save_json/account/reopened = new(test_path)
	var/datum/player_save_document/after = reopened.snapshot()
	TEST_ASSERT_EQUAL(after.read("tgui_panel_theme"), old_theme, "неопубликованная настройка попала на диск")
	// Ошибка кодирования должна отбрасывать уже подготовленные поля и сохранять буфер.
	prefs.player_save_storage = reopened
	prefs.player_save_blocked = FALSE
	var/list/cycle = list()
	cycle += list(cycle)
	prefs.custom_colors = cycle
	var/saved_cycle = prefs.save_preferences(TRUE, TRUE)
	prefs.custom_colors = list()
	cycle.Cut()
	TEST_ASSERT(!saved_cycle, "циклический список не отклонил запись")
	TEST_ASSERT_EQUAL(prefs.pending_single_prefs["tgui_panel_state"], "pending", "ошибка кодирования потеряла буфер")
	after = reopened.snapshot()
	TEST_ASSERT_EQUAL(after.read("tgui_panel_theme"), old_theme, "ошибка кодирования изменила сохранённый кэш")

/datum/unit_test/player_save_json/delete_preserves_other_branches/Run()
	prepare()
	var/datum/preferences/prefs = new_preferences()
	TEST_ASSERT(prefs.save_preferences(TRUE, TRUE), "не создан корень")
	prefs.real_name = "First"
	TEST_ASSERT(prefs.save_character(TRUE, TRUE), "не создан первый слот")
	prefs.default_slot = 2
	prefs.real_name = "Second"
	TEST_ASSERT(prefs.save_character(TRUE, TRUE), "не создан второй слот")
	var/datum/player_save_json/account/account = prefs.get_player_save_storage()
	var/datum/player_save_document/before = account.snapshot()
	var/datum/player_save_json/child = account.branch("character2")
	var/child_generation = child.generation
	var/before_hash = rustg_hash_file(RUSTG_HASH_MD5, child.active_path)
	prefs.default_slot = 1
	TEST_ASSERT(prefs.delete_character(1), "не удалён первый слот")
	TEST_ASSERT_EQUAL(prefs.default_slot, 2, "удаление активного слота не выбрало оставшегося персонажа")
	TEST_ASSERT("character1" in before.tree, "удаление изменило старый снимок")
	TEST_ASSERT("character1" in before.directories, "удаление изменило старый каталог")
	TEST_ASSERT_EQUAL(child.generation, child_generation, "удаление перезаписало другую анкету")
	TEST_ASSERT_EQUAL(rustg_hash_file(RUSTG_HASH_MD5, child.active_path), before_hash, "изменён файл другой анкеты")
	var/datum/player_save_document/after = account.snapshot()
	TEST_ASSERT(!("character1" in after.tree), "узел не удалён из корня")
	TEST_ASSERT(!("character1" in after.directories), "раздел не удалён из каталога")
	TEST_ASSERT(prefs.delete_character(2), "не удалён последний активный слот")
	TEST_ASSERT_EQUAL(prefs.default_slot, 1, "удаление последнего слота не выбрало слот 1")
	TEST_ASSERT(!prefs.delete_character(2), "повторно удалён отсутствующий слот")

/datum/unit_test/player_save_json/deleted_document_recovery/Run()
	prepare()
	var/datum/player_save_json/account/account = new(test_path)
	var/savefile/source = account.open()
	source.cd = "/character1"
	source["real_name"] << "Recoverable"
	TEST_ASSERT(account.commit(source), "не создан слот")
	var/datum/player_save_document/root = account.snapshot()
	TEST_ASSERT(root.remove("character1"), "не удалён раздел")
	TEST_ASSERT(root.commit(), "удаление не опубликовано")
	fdel(account.active_path)
	text2file("{", account.active_path)
	var/datum/player_save_json/account/reopened = new(test_path)
	var/list/names = reopened.character_names(1)
	TEST_ASSERT_EQUAL(names["character1"], "Recoverable", "удаление уничтожило файлы для восстановления")

/datum/unit_test/player_save_json/cyrillic_text/Run()
	prepare()
	var/datum/player_save_document/document = storage.snapshot()
	var/text = "Я и я: юф, маяк, семья %ff %25"
	TEST_ASSERT_EQUAL(player_save_encode_value(text), text, "обычная кириллица записана объектом вместо строки")
	document.write("text", text)
	TEST_ASSERT(document.commit(), "не записана кириллица")
	var/generation = storage.generation
	TEST_ASSERT(!document.write("text", text), "неизменённая кириллица пометила документ изменённым")
	TEST_ASSERT(document.commit(), "не принят неизменённый документ")
	TEST_ASSERT_EQUAL(storage.generation, generation, "кириллица вызвала лишнюю запись")
	for(var/value in list("\proper Я %ff %25", "я\nю\tф", list("я" = "\proper Я")))
		TEST_ASSERT_EQUAL(json_encode(player_save_encode_value(player_save_decode_value(player_save_encode_value(value)))), json_encode(player_save_encode_value(value)), "служебные маркеры не прошли повторное кодирование")
	TEST_ASSERT_EQUAL(player_save_decode_value(list("type" = "text", "value" = "семья")), "семья", "старое экранирование кириллицы больше не читается")

/datum/unit_test/player_save_json/generation_selection/Run()
	var/savefile/source = prepare()
	source["marker"] << 1
	TEST_ASSERT(storage.commit(source), "не создано первое поколение")
	source["marker"] << 2
	TEST_ASSERT(storage.commit(source), "не создано второе поколение")
	var/datum/player_save_json/read_counted/reopened = new(test_path)
	var/datum/player_save_document/document = reopened.snapshot()
	TEST_ASSERT_EQUAL(document.read("marker"), 2, "не выбрано новое поколение")
	TEST_ASSERT_EQUAL(reopened.reads, 1, "разобраны оба исправных поколения")
	reopened.reads = 0
	document = reopened.snapshot(1, FALSE)
	TEST_ASSERT_EQUAL(document.read("marker"), 1, "не выбрано опубликованное поколение раздела")
	TEST_ASSERT_EQUAL(reopened.reads, 1, "разобрано лишнее поколение раздела")
	var/newest_path = storage.active_path
	var/corrupted = replacetext(file2text(newest_path), "\"checksum\":\"", "\"checksum\":\"broken")
	fdel(newest_path)
	text2file(corrupted, newest_path)
	reopened.reads = 0
	document = reopened.snapshot(null, FALSE)
	TEST_ASSERT_NOTNULL(document, "не восстановлен файл с повреждённой контрольной суммой")
	TEST_ASSERT_EQUAL(document.read("marker"), 1, "не выбран исправный снимок")
	TEST_ASSERT_EQUAL(reopened.reads, 2, "после сбоя не проверено второе поколение")
	TEST_ASSERT(reopened.recovered, "восстановление не отмечено")

/datum/unit_test/player_save_json/cold_names_use_root/Run()
	prepare()
	var/datum/player_save_json/account/account = new(test_path)
	var/savefile/source = account.open()
	for(var/slot in 1 to 9)
		source.cd = "/character[slot]"
		source["real_name"] << "Character [slot]"
	TEST_ASSERT(account.commit(source), "не созданы слоты")
	var/datum/player_save_json/account/read_counted/reopened = new(test_path)
	var/list/names = reopened.character_names(9)
	TEST_ASSERT_EQUAL(length(names), 9, "меню потеряло слоты")
	TEST_ASSERT_EQUAL(names["character9"], "Character 9", "не прочитано имя из корня")
	TEST_ASSERT_EQUAL(length(reopened.branches), 0, "первое открытие меню загрузило анкеты")
	// В старом разделённом формате узел слота не содержал имя.
	var/datum/player_save_document/root = reopened.snapshot()
	for(var/slot in 2 to 9)
		root.write("character[slot]", null)
	TEST_ASSERT(root.commit(), "не создана фикстура старого индекса")
	var/root_generation = reopened.generation
	var/published_directories = json_encode(reopened.directories)
	var/datum/player_save_json/child = reopened.branch("character9")
	var/branch_hash = rustg_hash_file(RUSTG_HASH_MD5, "[child.json_path]")
	reopened = new(test_path)
	names = reopened.character_names(9)
	TEST_ASSERT_EQUAL(names["character9"], "Character 9", "старый формат потерял имя")
	TEST_ASSERT_EQUAL(reopened.generation, root_generation + 1, "имена не опубликованы одной записью корня")
	TEST_ASSERT_EQUAL(json_encode(reopened.directories), published_directories, "индекс изменил поколения анкет")
	TEST_ASSERT_EQUAL(rustg_hash_file(RUSTG_HASH_MD5, "[child.json_path]"), branch_hash, "индекс переписал файл анкеты")
	reopened = new(test_path)
	names = reopened.character_names(9)
	for(var/slot in 1 to 9)
		TEST_ASSERT_EQUAL(names["character[slot]"], "Character [slot]", "индекс потерял имя слота [slot]")
	TEST_ASSERT_EQUAL(length(reopened.branches), 0, "повторный вход снова загрузил анкеты")
	TEST_ASSERT_EQUAL(reopened.generation, root_generation + 1, "повторный вход снова записал корень")

/datum/unit_test/player_save_json/field_read_keeps_full_validation/Run()
	var/savefile/source = prepare()
	source["real_name"] << "Readable Name"
	source["unrelated"] << 1
	TEST_ASSERT(storage.commit(source), "не создан файл")
	var/list/document = json_decode(file2text(storage.active_path))
	var/list/tree = document["tree"]
	var/list/node = tree["unrelated"]
	node["value"] = list("type" = "unknown")
	document["checksum"] = md5(json_encode(list(document["generation"], tree, document["directories"])))
	fdel(storage.active_path)
	text2file(json_encode(document), storage.active_path)
	var/datum/player_save_json/reopened = new(test_path)
	TEST_ASSERT_EQUAL(reopened.read_field("real_name", 1), "Readable Name", "чтение одного поля декодировало посторонние значения")
	TEST_ASSERT_NULL(reopened.error, "корректное поле вызвало ошибку")
	TEST_ASSERT_NULL(reopened.snapshot(1), "непроверенная анкета попала в кэш полных снимков")
	TEST_ASSERT_NOTNULL(reopened.error, "полная проверка не обнаружила повреждённое поле")
	reopened = new(test_path)
	TEST_ASSERT_NULL(reopened.read_field("unrelated", 1), "повреждённое поле принято")
	TEST_ASSERT_NOTNULL(reopened.error, "ошибка нужного поля не отмечена")

/datum/unit_test/player_save_json/name_backfill_write_failure/Run()
	prepare()
	var/datum/player_save_json/account/reject_root/account = new(test_path)
	var/savefile/source = account.open()
	source.cd = "/character1"
	source["real_name"] << "Preserved Name"
	TEST_ASSERT(account.commit(source), "не создан слот")
	var/datum/player_save_document/root = account.snapshot()
	root.write("character1", null)
	TEST_ASSERT(root.commit(), "не создан старый индекс")
	var/published_generation = account.generation
	account.reject_write = TRUE
	TEST_ASSERT_NULL(account.character_names(1), "ошибка записи индекса проигнорирована")
	TEST_ASSERT_NOTNULL(account.error, "не передана ошибка записи")
	var/datum/player_save_json/account/reopened = new(test_path)
	root = reopened.snapshot()
	TEST_ASSERT_EQUAL(reopened.generation, published_generation, "ошибка записи изменила поколение")
	TEST_ASSERT_NULL(root.read("character1"), "неопубликованное имя попало на диск")
	var/list/names = reopened.character_names(1)
	TEST_ASSERT_EQUAL(names["character1"], "Preserved Name", "повторная попытка потеряла имя")
	TEST_ASSERT_EQUAL(reopened.generation, published_generation + 1, "повторная попытка не обновила индекс")

/datum/unit_test/player_save_json/future_version_in_pair/Run()
	var/savefile/source = prepare()
	source["marker"] << 1
	TEST_ASSERT(storage.commit(source), "не создано первое поколение")
	source["marker"] << 2
	TEST_ASSERT(storage.commit(source), "не создано второе поколение")
	var/list/future = json_decode(file2text(storage.json_path))
	future["version"] = 999
	fdel(storage.json_path)
	text2file(json_encode(future), storage.json_path)
	var/datum/player_save_json/reopened = new(test_path)
	TEST_ASSERT_NULL(reopened.snapshot(), "быстрый выбор поколения скрыл неизвестную версию формата")
	TEST_ASSERT(!reopened.commit(source), "неизвестная версия разрешила запись")

/datum/preferences/player_save_read_counted
	var/compatibility_reads = 0

/datum/preferences/player_save_read_counted/open_player_save(scope)
	compatibility_reads++
	return ..()

/datum/unit_test/player_save_json/direct_readers/Run()
	prepare()
	var/datum/preferences/player_save_read_counted/prefs = new
	owned_preferences = prefs
	allocated += prefs
	prefs.path = test_path
	prefs.real_name = "Direct Reader"
	prefs.bm_lobby_show_nsfw = TRUE
	prefs.metadollar_minute_pool = 37
	prefs.directory_ad = "Моя анкета"
	prefs.tattoos_string = "1^head^Моя татуировка"
	prefs.pda_color = "#abcdef"
	TEST_ASSERT(prefs.save_preferences(TRUE, TRUE), "не создан корень")
	TEST_ASSERT(prefs.save_character(TRUE, TRUE), "не создан слот")
	prefs.compatibility_reads = 0
	prefs.bm_lobby_show_nsfw = FALSE
	prefs.metadollar_minute_pool = 0
	prefs.real_name = "Reset"
	prefs.directory_ad = ""
	prefs.tattoos_string = ""
	prefs.pda_color = "#000000"
	TEST_ASSERT(istype(prefs.load_preferences(TRUE), /datum/player_save_document), "настройки загружены через savefile")
	TEST_ASSERT(istype(prefs.load_character(1, TRUE), /datum/player_save_document), "персонаж загружен через savefile")
	TEST_ASSERT_EQUAL(prefs.compatibility_reads, 0, "обычная загрузка собрала промежуточный savefile")
	TEST_ASSERT_EQUAL(prefs.real_name, "Direct Reader", "потеряно основное поле персонажа")
	TEST_ASSERT(prefs.bm_lobby_show_nsfw, "потеряно поле лобби")
	TEST_ASSERT_EQUAL(prefs.metadollar_minute_pool, 37, "потеряно модульное поле корня")
	TEST_ASSERT_EQUAL(prefs.directory_ad, "Моя анкета", "потеряно поле SPLURT")
	TEST_ASSERT_EQUAL(prefs.tattoos_string, "1^head^Моя татуировка", "потеряна татуировка")
	TEST_ASSERT_EQUAL(prefs.pda_color, "#abcdef", "потеряно поле BlueMoon")
	// Остатки удалённого слота не должны блокировать чтение свободного слота.
	var/datum/player_save_json/account/account = prefs.get_player_save_storage()
	var/datum/player_save_json/orphan = account.branch("character2")
	text2file("{", orphan.json_path)
	TEST_ASSERT(!prefs.load_character(2, TRUE), "свободный слот принят за сохранённого персонажа")
	TEST_ASSERT(!prefs.player_save_blocked, "повреждённый остаток удалённого слота заблокировал аккаунт")
	TEST_ASSERT_EQUAL(prefs.default_slot, 2, "выбор свободного слота не обновил default_slot")

/datum/unit_test/player_save_json/metadollar_migration
	var/balance_ckey = "unittestplayersavebalances"
	var/balance_directory

/datum/unit_test/player_save_json/metadollar_migration/Destroy()
	if(balance_directory)
		fdel(balance_directory)
		SSmetadollars.metadollar_amount_cache -= balance_ckey
	return ..()

/datum/unit_test/player_save_json/metadollar_migration/Run()
	prepare()
	balance_directory = "data/player_saves/u/[balance_ckey]/"
	fdel(balance_directory)
	SSmetadollars.metadollar_amount_cache -= balance_ckey
	var/prefs_path = "[balance_directory]preferences.sav"
	var/savefile/backup = new("[prefs_path].updatebac")
	backup["metadollars"] << 999
	backup.Flush()
	backup = null
	var/backup_hash = rustg_hash_file(RUSTG_HASH_MD5, "[prefs_path].updatebac")
	var/datum/player_save_json/account/account = new(prefs_path)
	var/savefile/source = new
	source["version"] << 80
	source["metadollars"] << 0
	TEST_ASSERT(account.commit(source), "не создан JSON с нулевым балансом")
	TEST_ASSERT_EQUAL(bm_read_legacy_metadollars_from_prefs_sav(balance_ckey), 0, "старый backup повысил баланс из JSON")
	TEST_ASSERT_EQUAL(SSmetadollars.read_metadollar_balance_from_save(balance_ckey, TRUE), 0, "нулевой баланс изменился при переносе")
	var/balance_path = bm_metadollar_json_path(balance_ckey)
	TEST_ASSERT(fexists(balance_path), "нулевой баланс не завершил перенос")
	TEST_ASSERT_EQUAL(rustg_hash_file(RUSTG_HASH_MD5, "[prefs_path].updatebac"), backup_hash, "чтение изменило backup")
	TEST_ASSERT(!fexists("[prefs_path].updatebac.json"), "backup импортирован в JSON")
	SSmetadollars.metadollar_amount_cache -= balance_ckey
	fdel(account.active_path)
	text2file("{", account.active_path)
	TEST_ASSERT_EQUAL(SSmetadollars.read_metadollar_balance_from_save(balance_ckey, TRUE), 0, "завершённый перенос снова читает preferences")
	fdel(balance_path)
	TEST_ASSERT_EQUAL(SSmetadollars.read_metadollar_balance_from_save(balance_ckey, TRUE), 0, "ошибка чтения вернула ненулевой баланс")
	TEST_ASSERT(!fexists(balance_path), "ошибка чтения закреплена как нулевой баланс")

#ifdef PLAYER_SAVE_BENCHMARK
/// Одинаковая фикстура для сравнения реализаций; время выводится без порога PASS/FAIL.
/datum/unit_test/player_save_json/benchmark/Run()
	prepare()
	var/savefile/legacy = new(test_path)
	for(var/index in 1 to 75)
		legacy["root_[index]"] << list("настройка", index, "enabled" = TRUE)
	for(var/slot in 1 to 5)
		legacy.cd = "/character[slot]"
		legacy["real_name"] << "Character [slot]"
		for(var/index in 1 to 239)
			legacy["field_[index]"] << list("Описание персонажа [index]", index / 7, "цвет" = "#aabbcc")
	legacy.cd = "/"
	legacy.Flush()
	var/datum/player_save_json/account/account = new(test_path)
	var/savefile/source = account.open()
	TEST_ASSERT(account.commit(source), "не создана фикстура замера")
	var/list/timings = list()
	var/repeats = 20
	var/started = TICK_USAGE_REAL
	for(var/iteration in 1 to repeats)
		var/savefile/opened = new(test_path)
		opened.cd = "/character1"
		for(var/key in opened.dir)
			var/value
			opened[key] >> value
	timings["binary_load"] = TICK_USAGE_TO_MS(started) / repeats
	timings["json_load_cold"] = 0
	timings["json_load_cold_with_root_copy"] = 0
	for(var/iteration in 1 to repeats)
		for(var/copy_root in (iteration % 2 ? list(TRUE, FALSE) : list(FALSE, TRUE)))
			account = new(test_path)
			started = TICK_USAGE_REAL
			source = account.open("/character1")
			TEST_ASSERT_NOTNULL(source, "не прочитан слот")
			if(copy_root)
				// Контрольный путь воспроизводит прежнее упреждающее копирование корня.
				account.root_snapshot(source)
				timings["json_load_cold_with_root_copy"] += TICK_USAGE_TO_MS(started) / repeats
			else
				timings["json_load_cold"] += TICK_USAGE_TO_MS(started) / repeats
	started = TICK_USAGE_REAL
	for(var/iteration in 1 to repeats)
		source = account.open("/character1")
		TEST_ASSERT(account.commit(source, "/character1"), "не сохранён неизменённый слот")
	timings["json_load_and_unchanged"] = TICK_USAGE_TO_MS(started) / repeats
	started = TICK_USAGE_REAL
	for(var/iteration in 1 to repeats)
		legacy.cd = "/character1"
		for(var/index in 1 to 239)
			legacy["field_[index]"] << list("Описание персонажа [index]", (index + iteration) / 7, "цвет" = "#aabbcc")
		legacy.Flush()
	timings["binary_save"] = TICK_USAGE_TO_MS(started) / repeats
	source = account.open("/character1")
	started = TICK_USAGE_REAL
	for(var/iteration in 1 to repeats)
		source.cd = "/character1"
		for(var/index in 1 to 239)
			source["field_[index]"] << list("Описание персонажа [index]", (index + iteration) / 7, "цвет" = "#aabbcc")
		TEST_ASSERT(account.commit(source, "/character1"), "не сохранён изменённый слот")
	timings["json_save"] = TICK_USAGE_TO_MS(started) / repeats
	started = TICK_USAGE_REAL
	for(var/iteration in 1 to repeats)
		TEST_ASSERT(account.commit(source, "/character1"), "не выполнен повторный commit")
	timings["json_unchanged"] = TICK_USAGE_TO_MS(started) / repeats
	started = TICK_USAGE_REAL
	for(var/iteration in 1 to repeats)
		source = account.open("/")
		source["root_1"] << iteration
		TEST_ASSERT(account.commit(source, "/"), "не сохранена настройка")
	timings["json_setting"] = TICK_USAGE_TO_MS(started) / repeats
	started = TICK_USAGE_REAL
	for(var/iteration in 1 to repeats)
		var/datum/player_save_document/document = account.snapshot()
		document.write("root_1", iteration)
		TEST_ASSERT(document.commit(), "не сохранена настройка через документ")
	timings["document_setting"] = TICK_USAGE_TO_MS(started) / repeats
	var/datum/player_save_document/unchanged_document = account.snapshot()
	started = TICK_USAGE_REAL
	for(var/iteration in 1 to repeats)
		TEST_ASSERT(unchanged_document.commit(), "не выполнен пустой commit документа")
	timings["document_unchanged"] = TICK_USAGE_TO_MS(started) / repeats
	started = TICK_USAGE_REAL
	for(var/iteration in 1 to repeats)
		var/datum/player_save_character_transaction/transaction = account.character_transaction("character1")
		var/savefile/patch = new
		patch.cd = "/character1"
		for(var/index in 1 to 239)
			patch["field_[index]"] << list("Описание персонажа [index]", (index + iteration) / 7, "цвет" = "#aabbcc")
		TEST_ASSERT(transaction.commit(patch), "не сохранена правка слота")
	timings["document_character_patch"] = TICK_USAGE_TO_MS(started) / repeats
	started = TICK_USAGE_REAL
	for(var/iteration in 1 to repeats)
		account = new(test_path)
		TEST_ASSERT_EQUAL(length(account.character_names(5)), 5, "не прочитаны имена")
	timings["json_names_cold"] = TICK_USAGE_TO_MS(started) / repeats
	started = TICK_USAGE_REAL
	for(var/iteration in 1 to repeats)
		account.character_names(5)
	timings["json_names_cached"] = TICK_USAGE_TO_MS(started) / repeats
	var/datum/preferences/prefs = new
	benchmark_prefs = prefs
	allocated += prefs
	prefs.path = "[test_path].prefs"
	TEST_ASSERT(prefs.save_preferences(TRUE, TRUE), "не создан корень префов")
	TEST_ASSERT(prefs.save_character(TRUE, TRUE), "не создан первый слот префов")
	// Чередуем порядок в каждой паре, чтобы колебания нагрузки не давали преимущество одному пути.
	timings["json_save_character_e2e"] = 0
	timings["json_save_character_compat_e2e"] = 0
	timings["json_save_preferences_e2e"] = 0
	timings["json_save_preferences_compat_e2e"] = 0
	for(var/iteration in 1 to repeats)
		for(var/use_document in (iteration % 2 ? list(TRUE, FALSE) : list(FALSE, TRUE)))
			prefs.real_name = "Benchmark Character [iteration] [use_document]"
			started = TICK_USAGE_REAL
			if(use_document)
				TEST_ASSERT(prefs.save_character(TRUE, TRUE), "не сохранены префы")
				timings["json_save_character_e2e"] += TICK_USAGE_TO_MS(started) / repeats
			else
				var/savefile/compatibility = prefs.write_character(TRUE, TRUE)
				TEST_ASSERT(compatibility && prefs.commit_player_save(compatibility, "/character1"), "не сохранён персонаж через совместимый путь")
				timings["json_save_character_compat_e2e"] += TICK_USAGE_TO_MS(started) / repeats
	for(var/iteration in 1 to repeats)
		for(var/use_document in (iteration % 2 ? list(TRUE, FALSE) : list(FALSE, TRUE)))
			prefs.tgui_panel_state = "[iteration] [use_document]"
			started = TICK_USAGE_REAL
			if(use_document)
				TEST_ASSERT(prefs.save_preferences(TRUE, TRUE), "не сохранены настройки целиком")
				timings["json_save_preferences_e2e"] += TICK_USAGE_TO_MS(started) / repeats
			else
				var/savefile/compatibility = prefs.write_preferences(TRUE, TRUE)
				TEST_ASSERT(compatibility && prefs.commit_player_save(compatibility, "/"), "не сохранены префы через совместимый путь")
				timings["json_save_preferences_compat_e2e"] += TICK_USAGE_TO_MS(started) / repeats
	started = TICK_USAGE_REAL
	for(var/iteration in 1 to repeats)
		prefs.buffer_single_pref("tgui_panel_state", "[iteration]")
		TEST_ASSERT(prefs.flush_single_prefs(), "не сброшена одиночная настройка")
	timings["json_single_pref_e2e"] = TICK_USAGE_TO_MS(started) / repeats
	TEST_ASSERT(prefs.save_preferences(TRUE, TRUE), "не подготовлены настройки для повторного сохранения")
	started = TICK_USAGE_REAL
	for(var/iteration in 1 to repeats)
		TEST_ASSERT(prefs.save_preferences(TRUE, TRUE), "не приняты неизменённые настройки")
	timings["json_preferences_unchanged_e2e"] = TICK_USAGE_TO_MS(started) / repeats
	started = TICK_USAGE_REAL
	for(var/iteration in 1 to repeats)
		TEST_ASSERT(prefs.save_character(TRUE, TRUE), "не принят неизменённый персонаж")
	timings["json_character_unchanged_e2e"] = TICK_USAGE_TO_MS(started) / repeats
	timings["json_names_after_save"] = 0
	for(var/iteration in 1 to repeats)
		prefs.real_name = "Menu Character [iteration]"
		TEST_ASSERT(prefs.save_character(TRUE, TRUE), "не сохранено имя перед открытием меню")
		started = TICK_USAGE_REAL
		var/list/names = prefs.player_character_names()
		timings["json_names_after_save"] += TICK_USAGE_TO_MS(started) / repeats
		TEST_ASSERT_EQUAL(names["character1"], prefs.real_name, "меню показало старое имя")
	started = TICK_USAGE_REAL
	for(var/iteration in 1 to repeats)
		TEST_ASSERT(prefs.load_preferences(TRUE), "не прочитаны настройки")
	timings["json_read_preferences_warm"] = TICK_USAGE_TO_MS(started) / repeats
	started = TICK_USAGE_REAL
	for(var/iteration in 1 to repeats)
		TEST_ASSERT(prefs.load_character(1, TRUE), "не прочитан персонаж")
	timings["json_load_character_warm"] = TICK_USAGE_TO_MS(started) / repeats
	started = TICK_USAGE_REAL
	for(var/iteration in 1 to repeats)
		prefs.player_save_storage = null
		TEST_ASSERT(prefs.load_preferences(TRUE), "не прочитаны настройки без кэша")
	timings["json_read_preferences_cold"] = TICK_USAGE_TO_MS(started) / repeats
	started = TICK_USAGE_REAL
	for(var/iteration in 1 to repeats)
		prefs.player_save_storage = null
		TEST_ASSERT(prefs.load_character(1, TRUE), "не прочитан персонаж без кэша")
	timings["json_load_character_cold"] = TICK_USAGE_TO_MS(started) / repeats
	started = TICK_USAGE_REAL
	for(var/iteration in 1 to repeats)
		bm_read_metadollars_from_savefile_path(prefs.path)
	timings["json_metadollars_cold"] = TICK_USAGE_TO_MS(started) / repeats
	prefs.path = null
	legacy = null
	log_world("PLAYER_SAVE_BENCHMARK [json_encode(timings)]")

/datum/unit_test/player_save_json/benchmark
	var/datum/preferences/benchmark_prefs

/datum/unit_test/player_save_json/benchmark/Destroy()
	if(benchmark_prefs)
		benchmark_prefs.path = null
	for(var/suffix in list(".json", ".json.recovery", ".json.d/"))
		fdel("[test_path].prefs[suffix]")
	return ..()

#endif
