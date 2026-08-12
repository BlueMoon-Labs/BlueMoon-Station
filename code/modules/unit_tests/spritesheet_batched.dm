/**
 * Батчёвые спрайтшиты (IconForge): описание иконок, генерация в rust, нарезка на
 * шарды и кросс-раундовый кэш.
 *
 * Лист для тестов: _abstract равен собственному типу, поэтому SSassets его на
 * инициализации не поднимает - им распоряжается только тест. sprites_per_shard = 2,
 * чтобы четыре спрайта дали несколько шардов и раскладка проверялась по-настоящему.
 */
/datum/asset/spritesheet_batched/test_batched
	_abstract = /datum/asset/spritesheet_batched/test_batched
	name = "test_batched"
	load_immediately = TRUE
	sprites_per_shard = 2
	var/static/list/items = list(/obj/item/binoculars, /obj/item/camera, /obj/item/clothing/under/color/black)

/datum/asset/spritesheet_batched/test_batched/create_spritesheets()
	for(var/atom/item as anything in items)
		insert_icon(sprite_id_for(item), get_display_icon_for(item))

	// Заодно прогоняем операции трансформера.
	var/datum/universal_icon/composed = get_display_icon_for(/obj/item/camera)
	composed.blend_icon(get_display_icon_for(/obj/item/binoculars), ICON_OVERLAY)
	composed.blend_color("#ff0000", ICON_MULTIPLY)
	composed.change_opacity(0.5)
	composed.scale(64, 64)
	composed.crop(1, 1, 128, 64) // размер листа проверяем ниже
	insert_icon("composed", composed)

/datum/asset/spritesheet_batched/test_batched/proc/sprite_id_for(atom/item)
	return replacetext(replacetext("[item]", "/obj/item/", ""), "/", "-")

/// Сбрасывает лист в состояние "ещё не собран", сохраняя тип и имя.
/datum/asset/spritesheet_batched/test_batched/proc/reset_state()
	unregister()
	entries = list()
	entries_json = null
	sprites = list()
	sizes = list()
	sheet_files = list()
	job_id = null
	cache_job_id = null
	cache_result = null
	cache_data = null
	cache_sizes_data = null
	cache_sprites_data = null
	cache_sheet_files_data = null
	cache_png_hashes_data = null
	cache_shards_data = null
	generation_in_progress = FALSE
	generation_error = null
	fully_generated = FALSE

/datum/unit_test/spritesheet_batched_smart_cache

/datum/unit_test/spritesheet_batched_smart_cache/Run()
	var/datum/asset/spritesheet_batched/test_batched/sheet = new()
	var/meta_path = sheet.cache_meta_path()
	var/css_path = "[SPRITESHEET_CACHE_DIR]spritesheet_test_batched.css"
	// Датум создан на чистом кэше: сносим метаданные и собираем заново, иначе
	// прошлый прогон в этом же каталоге сделал бы первый заход попаданием.
	sheet.reset_state()
	fdel(meta_path)
	fdel(css_path)
	sheet.register()

	TEST_ASSERT(sheet.fully_generated, "лист не собрался")
	// cache_result: TRUE = кэш был невалиден. Первый прогон обязан быть промахом.
	TEST_ASSERT(sheet.cache_result, "кэш признан валидным, хотя метаданные только что удалили")

	for(var/item in sheet.items)
		var/sprite_id = sheet.sprite_id_for(item)
		TEST_ASSERT(sprite_id in sheet.sprites, "спрайта [sprite_id] нет в результате генерации")
	TEST_ASSERT("composed" in sheet.sprites, "спрайта composed нет в результате генерации")
	TEST_ASSERT("128x64" in sheet.sizes, "иконка с scale+crop не дала размер 128x64, размеры: [json_encode(sheet.sizes)]")

	// Нарезка: четыре спрайта по два на шард обязаны дать больше одного png.
	TEST_ASSERT(length(sheet.sheet_files) > 1, "лист не нарезался на шарды: [json_encode(sheet.sheet_files)]")
	for(var/png_name in sheet.sheet_files)
		TEST_ASSERT(fexists("[SPRITESHEET_CACHE_DIR][png_name]"), "png [png_name] не записался на диск")
		TEST_ASSERT_NOTNULL(SSassets.cache[png_name], "png [png_name] не зарегистрирован в транспорте")
	var/list/composed_sprite = sheet.sprites["composed"]
	TEST_ASSERT_EQUAL(composed_sprite["file"], "test_batched_part2_128x64.png", "спрайт composed указывает не на свой шард: [composed_sprite["file"]]")

	// css обязан описать и размер, и картинку с позицией каждого спрайта, иначе
	// клиент покажет пустоту.
	var/css = sheet.generate_css()
	TEST_ASSERT(findtext(css, ".test_batched128x64{"), "в css нет класса размера для 128x64")
	TEST_ASSERT(findtext(css, ".composed{background-image:"), "в css нет картинки для спрайта composed")
	TEST_ASSERT(findtext(css, "background-position:-0px 0;"), "в css нет позиции первого спрайта шарда")

	TEST_ASSERT(fexists(meta_path), "метаданные кэша не записались")

	// Второй заход с тем же входом обязан подняться из кэша, ничего не рисуя.
	var/list/first_sprites = sheet.sprites.Copy()
	var/list/first_files = sheet.sheet_files.Copy()
	sheet.reset_state()
	sheet.register()

	TEST_ASSERT(sheet.fully_generated, "лист не поднялся из кэша")
	TEST_ASSERT(!sheet.cache_result, "кэш признан невалидным, хотя вход не менялся")
	TEST_ASSERT_EQUAL(json_encode(sheet.sprites), json_encode(first_sprites), "раскладка спрайтов из кэша не совпала с собранной")
	TEST_ASSERT_EQUAL(json_encode(sheet.sheet_files), json_encode(first_files), "набор png из кэша не совпал с собранным")

	// Порча png на диске обязана привести к пересборке, а не к отдаче клиенту чужих
	// байт. Проверка входа в rust этого не поймает - она смотрит только на DMI и
	// описание спрайтов, - ловит сверка хэшей файлов в read_from_cache().
	var/png_name = first_files[1]
	var/clobbered_png = "[SPRITESHEET_CACHE_DIR][png_name]"
	sheet.reset_state()
	fdel(clobbered_png)
	text2file("clobbered by [type]", clobbered_png)
	var/clobbered_hash = md5asfile(file(clobbered_png))
	sheet.register()
	TEST_ASSERT(sheet.fully_generated, "лист не пересобрался после порчи png")
	TEST_ASSERT(md5asfile(file(clobbered_png)) != clobbered_hash, "испорченный png не пересобрали - клиент получил бы мусор")
	var/datum/asset_cache_item/reforged = SSassets.cache[png_name]
	TEST_ASSERT_NOTNULL(reforged, "png не зарегистрирован после пересборки")
	TEST_ASSERT_EQUAL(md5asfile(reforged.resource), md5asfile(file(clobbered_png)), "зарегистрированный слепок не совпал с пересобранным png")

	// Уборка: следующий прогон в этом каталоге должен начинать с чистого листа.
	var/list/files_to_drop = sheet.sheet_files.Copy()
	sheet.unregister()
	for(var/leftover in files_to_drop)
		fdel("[SPRITESHEET_CACHE_DIR][leftover]")
	fdel(meta_path)
	fdel(css_path)

/// Описание иконки должно выживать сериализацию: именно в этом виде оно уезжает в rust.
/datum/unit_test/universal_icon_serialization

/datum/unit_test/universal_icon_serialization/Run()
	var/datum/universal_icon/base = get_display_icon_for(/obj/item/camera)
	TEST_ASSERT_NOTNULL(base, "get_display_icon_for не вернул иконку для /obj/item/camera")

	base.blend_icon(get_display_icon_for(/obj/item/binoculars), ICON_OVERLAY, 2, 3)
	base.scale(64, 64)
	base.blend_color("#00ff00", ICON_MULTIPLY)

	var/datum/universal_icon/restored = universal_icon_from_list(base.to_list())
	TEST_ASSERT_EQUAL(restored.to_json(), base.to_json(), "иконка не совпала сама с собой после to_list/from_list")

	// В to_list() вложенная иконка подменяется на список - но только в копии.
	base.to_list()
	var/list/blend_entry
	for(var/list/entry as anything in base.transform.transforms)
		if(entry["type"] == RUSTG_ICONFORGE_BLEND_ICON)
			blend_entry = entry
			break
	TEST_ASSERT_NOTNULL(blend_entry, "операция blend_icon потерялась из трансформера")
	TEST_ASSERT(istype(blend_entry["icon"], /datum/universal_icon), "to_list() испортил исходный трансформер, подменив вложенную иконку списком")

	// copy() обязан отвязать и цепочку, и вложенные иконки.
	var/datum/universal_icon/copied = base.copy()
	copied.blend_color("#0000ff", ICON_MULTIPLY)
	TEST_ASSERT(length(copied.transform.transforms) != length(base.transform.transforms), "правка копии дописала операцию в оригинал")
	var/datum/universal_icon/copied_nested
	for(var/list/entry as anything in copied.transform.transforms)
		if(entry["type"] == RUSTG_ICONFORGE_BLEND_ICON)
			copied_nested = entry["icon"]
			break
	TEST_ASSERT_NOTNULL(copied_nested, "в копии потерялась операция blend_icon")
	TEST_ASSERT(copied_nested != blend_entry["icon"], "copy() оставил вложенную иконку общей с оригиналом")

/// Мигрированный на rust лист обязан содержать те же спрайты, что собирал DM-путь.
/datum/unit_test/spritesheet_batched_parity

/datum/unit_test/spritesheet_batched_parity/Run()
	var/datum/asset/spritesheet_batched/mafia/sheet = get_asset_datum(/datum/asset/spritesheet_batched/mafia)
	TEST_ASSERT_NOTNULL(sheet, "не удалось получить лист mafia")
	TEST_ASSERT(sheet.fully_generated, "лист mafia не собран после get_asset_datum")

	for(var/icon_state_name in icon_states('icons/obj/mafia.dmi'))
		TEST_ASSERT(icon_state_name in sheet.sprites, "спрайт [icon_state_name] из icons/obj/mafia.dmi не попал в лист")

	// Каждый спрайт обязан знать свой размер и свой png, иначе css соберётся битым.
	for(var/sprite_name in sheet.sprites)
		var/list/sprite = sheet.sprites[sprite_name]
		TEST_ASSERT(sprite["size_id"] in sheet.sizes, "спрайт [sprite_name] ссылается на размер [sprite["size_id"]], которого нет в списке размеров листа")
		TEST_ASSERT(sprite["file"] in sheet.sheet_files, "спрайт [sprite_name] ссылается на png [sprite["file"]], которого нет в списке файлов листа")
