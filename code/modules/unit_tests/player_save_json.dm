/datum/unit_test/player_save_json
	var/test_path
	var/datum/player_save_json/storage

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
	for(var/suffix in list("", ".json", ".json.recovery", ".json.import"))
		fdel("[test_path][suffix]")
	fdel("[test_path].json.d/")
	storage = null
	return ..()

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
