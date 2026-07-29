/**
 * Ресурс спрайтшита обязан быть слепком, а не ссылкой на путь.
 *
 * Имя, под которым ассет уезжает клиенту, несёт хэш содержимого и считается один
 * раз - при регистрации. Если /datum/asset_cache_item держит ленивую ссылку на
 * файл в data/, то любая перезапись этого файла (второй мир из того же чекаута,
 * правка руками) доедет до клиента под старым именем: css уйдёт как
 * asset.<старый хэш>.css, но внутри будет ссылаться на asset.<новый хэш>.png,
 * которого никто не отправлял, и вендомат откроется без иконок.
 */
/datum/unit_test/spritesheet_asset_survives_disk_clobber

/datum/unit_test/spritesheet_asset_survives_disk_clobber/Run()
	var/datum/asset/spritesheet/sheet = get_asset_datum(/datum/asset/spritesheet/simple/pills)
	TEST_ASSERT_NOTNULL(sheet, "не удалось получить спрайтшит /datum/asset/spritesheet/simple/pills")
	TEST_ASSERT(length(sheet.sizes), "спрайтшит [sheet.name] не содержит ни одного размера")

	var/list/asset_paths = list()
	asset_paths["spritesheet_[sheet.name].css"] = "[SPRITESHEET_CACHE_DIR]spritesheet_[sheet.name].css"
	for(var/size_id in sheet.sizes)
		asset_paths["[sheet.name]_[size_id].png"] = "[SPRITESHEET_CACHE_DIR][sheet.name]_[size_id].png"

	for(var/asset_name in asset_paths)
		var/datum/asset_cache_item/item = SSassets.cache[asset_name]
		TEST_ASSERT_NOTNULL(item, "ассет [asset_name] не зарегистрирован в SSassets.cache")

		var/path = asset_paths[asset_name]
		TEST_ASSERT(fexists(path), "файл кэша [path] отсутствует")

		// Ровно то, что делает второй мир, пишущий в тот же каталог.
		fdel(path)
		text2file("clobbered by [type]", path)

		// Вердикт снимаем до уборки, а объявляем после: провалиться прямо здесь значило бы бросить
		// испорченный файл в data/ до конца прогона - следующие тесты и следующий мир прочитали бы мусор.
		var/snapshot_hash = md5asfile(item.resource)

		// Возвращаем файл из слепка: заодно проверяем, что в слепке лежат исходные байты.
		fdel(path)
		fcopy(item.resource, path)

		if(snapshot_hash != item.hash)
			TEST_FAIL("содержимое ассета [asset_name] поехало вслед за файлом на диске - клиент получит чужие байты под именем asset.[item.hash]")
			return

		TEST_ASSERT_EQUAL(md5asfile(fcopy_rsc(file(path))), item.hash, \
			"восстановленный из слепка [path] не совпал с исходным содержимым ассета [asset_name]")
