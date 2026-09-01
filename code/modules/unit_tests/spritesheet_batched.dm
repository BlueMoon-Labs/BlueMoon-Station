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
	sprites = list()
	oversized_classes = null
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
	cache_mismatch_reason = null
	generation_in_progress = FALSE
	generation_error = null
	fully_generated = FALSE
	unread_dmi_paths = list()
	unread_retries_left = initial(unread_retries_left)

/**
 * Сносит с диска всё, что оставил после себя лист: шарды, метаданные и css.
 *
 * Зовётся в начале теста, а не в конце: любой TEST_ASSERT прерывает Run(), и
 * завершающая уборка до себя не доживает - следующий прогон в этом же каталоге
 * начинал бы с чужого кэша и первый заход оказался бы попаданием.
 */
/proc/drop_spritesheet_artifacts(datum/asset/spritesheet_batched/sheet)
	for(var/existing_file in flist(SPRITESHEET_CACHE_DIR))
		if(findtextEx(existing_file, "[sheet.name]_part") == 1 && copytext(existing_file, -4) == ".png")
			fdel("[SPRITESHEET_CACHE_DIR][existing_file]")
	fdel(sheet.cache_meta_path())
	fdel("[SPRITESHEET_CACHE_DIR]spritesheet_[sheet.name].css")

/datum/unit_test/spritesheet_batched_smart_cache

/datum/unit_test/spritesheet_batched_smart_cache/Run()
	var/datum/asset/spritesheet_batched/test_batched/sheet = new()
	var/meta_path = sheet.cache_meta_path()
	// Датум создан на чистом кэше: сносим следы прошлых прогонов и собираем заново.
	sheet.reset_state()
	drop_spritesheet_artifacts(sheet)
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

/**
 * Карта размеров для интерфейсов: списки производства ужимают по ней крупный
 * спрайт до тайла, а спрайту ровно в тайл размер не шлётся вовсе.
 */
/datum/unit_test/spritesheet_batched_oversized_classes

/datum/unit_test/spritesheet_batched_oversized_classes/Run()
	var/datum/asset/spritesheet_batched/test_batched/sheet = new()
	sheet.reset_state()
	drop_spritesheet_artifacts(sheet)
	sheet.register()
	TEST_ASSERT(sheet.fully_generated, "лист не собрался")

	var/list/oversized = sheet.oversized_icon_classes()
	TEST_ASSERT_EQUAL(oversized["composed"], "test_batched128x64", "спрайт 128x64 не попал в карту размеров: [json_encode(oversized)]")
	for(var/item in sheet.items)
		var/sprite_id = sheet.sprite_id_for(item)
		TEST_ASSERT_NULL(oversized[sprite_id], "спрайт [sprite_id] ростом в тайл попал в карту размеров - это лишняя статика")

	// Пересборка обязана сбросить кэш карты, иначе интерфейс продолжит ужимать
	// иконки по прошлой раскладке.
	sheet.reset_state()
	sheet.register()
	TEST_ASSERT_EQUAL(json_encode(sheet.oversized_icon_classes()), json_encode(oversized), "карта размеров после пересборки разошлась с исходной")

/**
 * Тот же лист, но по отложенному пути (yield = TRUE) - так его собирает
 * SSasset_loading в лобби. Под UNIT_TESTS отложенная сборка выключена, поэтому в
 * раунде работает путь, который иначе не проверялся бы ничем.
 *
 * Имя своё: тесты делят каталог кэша, и общий лист они бы затирали друг у друга.
 */
/datum/asset/spritesheet_batched/test_batched/deferred
	_abstract = /datum/asset/spritesheet_batched/test_batched/deferred
	name = "test_batched_deferred"

/datum/unit_test/spritesheet_batched_deferred

/datum/unit_test/spritesheet_batched_deferred/Run()
	var/datum/asset/spritesheet_batched/test_batched/deferred/sheet = new()
	sheet.reset_state()
	drop_spritesheet_artifacts(sheet)

	// register() собрал бы лист синхронно, поэтому описание и сборку зовём врозь.
	sheet.create_spritesheets()
	sheet.realize_spritesheets(yield = TRUE)

	TEST_ASSERT(sheet.fully_generated, "лист не собрался по отложенному пути")
	TEST_ASSERT(sheet.cache_result, "кэш признан валидным, хотя метаданные только что удалили")
	TEST_ASSERT(length(sheet.sheet_files) > 1, "лист не нарезался на шарды: [json_encode(sheet.sheet_files)]")
	for(var/png_name in sheet.sheet_files)
		TEST_ASSERT_NOTNULL(SSassets.cache[png_name], "png [png_name] не зарегистрирован в транспорте")

	var/list/first_sprites = sheet.sprites.Copy()
	var/list/first_files = sheet.sheet_files.Copy()

	// Второй заход - подъём из кэша тем же асинхронным путём.
	sheet.reset_state()
	sheet.create_spritesheets()
	sheet.realize_spritesheets(yield = TRUE)

	TEST_ASSERT(sheet.fully_generated, "лист не поднялся из кэша по отложенному пути")
	TEST_ASSERT(!sheet.cache_result, "кэш признан невалидным, хотя вход не менялся")
	TEST_ASSERT_EQUAL(json_encode(sheet.sprites), json_encode(first_sprites), "раскладка спрайтов из кэша не совпала с собранной")
	TEST_ASSERT_EQUAL(json_encode(sheet.sheet_files), json_encode(first_files), "набор png из кэша не совпал с собранным")

/**
 * Каждый батчёвый лист обязан быть собран к концу инициализации.
 *
 * Под UNIT_TESTS отложенная сборка выключена (DO_NOT_DEFER_ASSETS), поэтому после
 * SSassets готовы все листы. Тест ловит лист, который молча не зарегистрировался или
 * не собрался: в логе такое не видно, а на проде это пустая витрина у интерфейса.
 */
/datum/unit_test/spritesheet_batched_all_generated

/datum/unit_test/spritesheet_batched_all_generated/Run()
	for(var/sheet_type in subtypesof(/datum/asset/spritesheet_batched))
		var/datum/asset/spritesheet_batched/sheet = sheet_type
		if(sheet_type == initial(sheet._abstract))
			continue
		var/datum/asset/spritesheet_batched/loaded = GLOB.asset_datums[sheet_type]
		// Через TEST_FAIL, а не TEST_ASSERT: assert выходит из Run() на первом же
		// битом листе, а знать надо про все сразу - иначе чинить их придётся по одному
		// за прогон.
		if(isnull(loaded))
			TEST_FAIL("лист [sheet_type] не зарегистрирован в SSassets")
			continue
		if(!loaded.fully_generated)
			TEST_FAIL("лист [loaded.name] ([sheet_type]) не собран после инициализации")
		if(!length(loaded.sheet_files))
			TEST_FAIL("у листа [loaded.name] ([sheet_type]) нет ни одного png")
		if(!length(loaded.sprites))
			TEST_FAIL("у листа [loaded.name] ([sheet_type]) нет ни одного спрайта")

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
	var/base_operations = length(base.transform.transforms)
	var/datum/universal_icon/copied = base.copy()
	copied.blend_color("#0000ff", ICON_MULTIPLY)
	TEST_ASSERT_EQUAL(length(base.transform.transforms), base_operations, "правка копии дописала операцию в оригинал")
	TEST_ASSERT_EQUAL(length(copied.transform.transforms), base_operations + 1, "в копии оказалась не одна новая операция, а другая цепочка целиком")
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

/**
 * Лист на три декали для проверки прозрачности превью.
 *
 * Имя и _abstract свои: боевой floor_tile_decals отпускает описание спрайтов сразу
 * после сборки (см. finish_generation), а проверять надо именно его - поэтому
 * снимаем копию прямо в create_spritesheets().
 */
/datum/asset/spritesheet_batched/decals/tiles/test_alpha
	_abstract = /datum/asset/spritesheet_batched/decals/tiles/test_alpha
	name = "test_decals_alpha"
	/// Цвет декали -> альфа, которую обязано показать её превью.
	var/list/expected_alphas
	/// Описание спрайтов до того, как его отпустит finish_generation().
	var/list/captured_entries

/datum/asset/spritesheet_batched/decals/tiles/test_alpha/create_spritesheets()
	var/obj/item/airlock_painter/decal/tile/tile_painter = painter_type
	expected_alphas = list(
		"#ff0000" = initial(tile_painter.default_alpha), // без RGBA-хвоста альфу даёт пейнтер
		"#ff000000" = 0,
		"#ff0000ff" = 255,
	)
	for(var/color in expected_alphas)
		insert_state("tile_corner", SOUTH, color)
	captured_entries = entries.Copy()

/**
 * Превью декали обязано быть той же прозрачности, с какой декаль ложится на пол.
 *
 * Альфа приходит в 0..255, а change_opacity() ждёт долю 0..1. Пока переводом был
 * множитель 0.008, превью выходило вдвое плотнее декали, и заметить это можно было
 * только рядом с покрашенным полом.
 */
/datum/unit_test/decal_preview_alpha

/datum/unit_test/decal_preview_alpha/Run()
	var/datum/asset/spritesheet_batched/decals/tiles/test_alpha/sheet = new()
	drop_spritesheet_artifacts(sheet)

	// Описывает лист само создание датума (New -> register -> create_spritesheets).
	// Проверяем это явно: пустое описание превратило бы цикл ниже в тест, который
	// проходит вхолостую, ничего не проверив.
	TEST_ASSERT(length(sheet.expected_alphas), "лист не описал себя при создании - перебирать нечего")
	TEST_ASSERT_EQUAL(length(sheet.captured_entries), length(sheet.expected_alphas), "описание спрайтов снялось не целиком")

	for(var/color in sheet.expected_alphas)
		var/expected_alpha = sheet.expected_alphas[color]
		var/sprite_name = "tile_corner_[SOUTH]_[replacetext(color, "#", "")]"
		var/list/entry = sheet.captured_entries[sprite_name]
		TEST_ASSERT_NOTNULL(entry, "в описании листа нет спрайта [sprite_name]")
		// Декаль подмешана вложенной иконкой поверх превью-пола, а прозрачность ей
		// задаёт первая же операция её цепочки (см. insert_state).
		var/list/decal_icon
		for(var/list/operation as anything in entry["transform"])
			if(operation["type"] == RUSTG_ICONFORGE_BLEND_ICON)
				decal_icon = operation["icon"]
				break
		TEST_ASSERT_NOTNULL(decal_icon, "спрайт [sprite_name] не подмешал декаль к превью-полу")
		var/list/decal_operations = decal_icon["transform"]
		TEST_ASSERT(length(decal_operations), "у декали в спрайте [sprite_name] нет ни одной операции - прозрачность не задана вовсе")
		var/list/opacity_operation = decal_operations[1]
		var/rendered_alpha = hex2num(copytext(opacity_operation["color"], -2))
		// Допуск в единицу - это округление доли обратно в 0..255 внутри change_opacity.
		TEST_ASSERT(abs(rendered_alpha - expected_alpha) <= 1, "превью [sprite_name] нарисовано с альфой [rendered_alpha] вместо [expected_alpha]")

/**
 * Лист с DMI, которого нет на диске в момент сборки.
 *
 * Прод-сценарий раунда 9954: сторож запускает мир по появлению dmb, пока деплой ещё
 * копирует дерево иконок. rust молча не читает недоехавшие файлы - их спрайты пропадают
 * с листа до конца раунда, а кэш пишется с неполными хэшами и не сходится никогда.
 * Лечится возвратом листа в очередь сборки; здесь таймер не ждём, а зовём пересборку
 * руками - ровно то, что сделал бы SSasset_loading, когда таймер вернёт лист в очередь.
 */
/datum/asset/spritesheet_batched/test_batched/transient
	_abstract = /datum/asset/spritesheet_batched/test_batched/transient
	name = "test_batched_transient"

/datum/asset/spritesheet_batched/test_batched/transient/proc/transient_dmi_path()
	return "[SPRITESHEET_CACHE_DIR]test_transient.dmi"

/datum/asset/spritesheet_batched/test_batched/transient/create_spritesheets()
	var/obj/item/binoculars/donor = /obj/item/binoculars
	insert_icon("good", get_display_icon_for(donor))
	// Текстовый путь вместо фейрефа: файла на момент компиляции не существует,
	// он "доезжает" на диск прямо по ходу теста.
	insert_icon("transient", uni_icon(transient_dmi_path(), initial(donor.icon_state)))

/datum/unit_test/spritesheet_batched_transient_retry

/datum/unit_test/spritesheet_batched_transient_retry/Run()
	var/datum/asset/spritesheet_batched/test_batched/transient/sheet = new()
	var/transient_path = sheet.transient_dmi_path()
	var/obj/item/binoculars/donor = /obj/item/binoculars
	sheet.reset_state()
	drop_spritesheet_artifacts(sheet)
	fdel(transient_path)
	// rust держит разобранные DMI в памяти процесса и отдаёт их даже после удаления
	// файла с диска - "отсутствующий" файл обязан отсутствовать и там.
	rustg_iconforge_cleanup()

	// Первый заход: файла нет, лист обязан уйти на пересборку, а не уехать дырявым.
	sheet.create_spritesheets()
	sheet.realize_spritesheets(yield = TRUE)
	// Таймер снимаем сразу, до ассертов: упавший ассерт выходит из Run(), и через
	// 15 секунд таймер позвал бы queue_asset посреди чужого теста (под
	// DO_NOT_DEFER_ASSETS это ещё и stack_trace).
	var/timer_was_armed = !isnull(sheet.retry_timer_id)
	deltimer(sheet.retry_timer_id)
	sheet.retry_timer_id = null
	TEST_ASSERT(!sheet.fully_generated, "лист собрался, хотя один из его DMI не существует - спрайт молча пропал бы у игроков")
	TEST_ASSERT_EQUAL(sheet.unread_retries_left, initial(sheet.unread_retries_left) - 1, "попытка пересборки не списалась")
	TEST_ASSERT_EQUAL(length(sheet.unread_dmi_paths), 1, "в непрочитанных ожидался ровно один DMI: [json_encode(sheet.unread_dmi_paths)]")
	TEST_ASSERT_EQUAL(sheet.unread_dmi_paths[1], transient_path, "в непрочитанные попал не тот путь")
	TEST_ASSERT(timer_was_armed, "таймер пересборки не взведён")
	TEST_ASSERT(!length(sheet.sprites), "раскладка не сброшена перед пересборкой")

	// Файл "доехал" - пересборка обязана собрать лист целиком.
	fcopy(initial(donor.icon), transient_path)
	sheet.realize_spritesheets(yield = TRUE)
	TEST_ASSERT(sheet.fully_generated, "лист не собрался после того, как DMI появился на диске")
	TEST_ASSERT(!length(sheet.unread_dmi_paths), "после успешной пересборки остались непрочитанные DMI: [json_encode(sheet.unread_dmi_paths)]")
	TEST_ASSERT("good" in sheet.sprites, "спрайт good пропал после пересборки")
	TEST_ASSERT("transient" in sheet.sprites, "спрайт из доехавшего DMI не попал в лист")

	// Попытки кончились - лист уезжает как есть: с предупреждением и без спрайта,
	// но живой. Пустая витрина у всех лучше, чем ни одной витрины ни у кого.
	sheet.reset_state()
	drop_spritesheet_artifacts(sheet)
	fdel(transient_path)
	// Пересборка выше положила файл в память rust - без чистки спрайт "соберётся"
	// из кэша процесса даже после fdel, и тест проверит не то.
	rustg_iconforge_cleanup()
	sheet.create_spritesheets()
	sheet.unread_retries_left = 0
	sheet.realize_spritesheets(yield = TRUE)
	TEST_ASSERT(sheet.fully_generated, "лист без попыток пересборки обязан собраться как есть")
	TEST_ASSERT("good" in sheet.sprites, "читаемый спрайт пропал вместе с нечитаемым")
	TEST_ASSERT(!("transient" in sheet.sprites), "спрайт из несуществующего DMI мистическим образом собрался")
	TEST_ASSERT_EQUAL(length(sheet.unread_dmi_paths), 1, "непрочитанный DMI не попал в диагностику: [json_encode(sheet.unread_dmi_paths)]")
	TEST_ASSERT_NULL(sheet.retry_timer_id, "лист без попыток взвёл таймер пересборки")
	// Дырявый лист не имеет права записать кэш: в его dmi_hashes не хватает записей,
	// rust отвечает на такой кэш "more DMIs exist than DMI hashes provided", и лист
	// пересобирается КАЖДЫЙ следующий раунд. На панели спавна это 400-670 МБ за раунд.
	TEST_ASSERT(!fexists(sheet.cache_meta_path()), "лист с непрочитанными DMI записал кэш, который заведомо не сойдётся")

/**
 * Промах кэша из-за нечитаемого файла - это гонка деплоя, а не изменение контента.
 *
 * Прод 25.08: сторож поднимает мир по появлению dmb, пока деплой ещё копирует дерево
 * иконок. rustg_iconforge_cache_valid не может открыть очередной DMI, отдаёт
 * "Error while hashing dmi_path ... No such file or directory", и лист уходит в полную
 * пересборку - хотя ни один спрайт не изменился и через полминуты файл уже на месте.
 * Промахи этого класса были в пяти раундах из шести.
 */
/datum/unit_test/spritesheet_batched_cache_miss_defers

/datum/unit_test/spritesheet_batched_cache_miss_defers/Run()
	var/datum/asset/spritesheet_batched/test_batched/transient/sheet = new()
	var/transient_path = sheet.transient_dmi_path()
	var/obj/item/binoculars/donor = /obj/item/binoculars
	sheet.reset_state()
	drop_spritesheet_artifacts(sheet)
	fdel(transient_path)
	rustg_iconforge_cleanup()

	// Сначала честный кэш: файл на месте, лист собирается и пишет метаданные.
	fcopy(initial(donor.icon), transient_path)
	sheet.create_spritesheets()
	sheet.realize_spritesheets(yield = TRUE)
	TEST_ASSERT(sheet.fully_generated, "лист не собрался на существующем DMI")
	TEST_ASSERT(fexists(sheet.cache_meta_path()), "полный лист не записал кэш")

	// А теперь тот же лист на "недоехавшем" диске: файла нет, значит проверка кэша
	// падает на чтении. Пересобирать по такой причине нельзя.
	sheet.reset_state()
	fdel(transient_path)
	rustg_iconforge_cleanup()
	sheet.create_spritesheets()
	sheet.realize_spritesheets(yield = TRUE)
	var/timer_was_armed = !isnull(sheet.retry_timer_id)
	deltimer(sheet.retry_timer_id)
	sheet.retry_timer_id = null

	TEST_ASSERT(!sheet.fully_generated, "лист пересобрался, хотя кэш промахнулся только из-за нечитаемого файла")
	TEST_ASSERT(timer_was_armed, "перепроверка кэша не запланирована")
	TEST_ASSERT_EQUAL(sheet.unread_retries_left, initial(sheet.unread_retries_left) - 1, "попытка не списалась")
	TEST_ASSERT(fexists(sheet.cache_meta_path()), "кэш снесли, хотя он валиден - файл просто не читался")
	TEST_ASSERT_NULL(sheet.cache_result, "результат проверки кэша не сброшен, повтор увидел бы устаревший вердикт")

	// Файл доехал - следующий заход обязан поднять лист ИЗ КЭША, а не собирать заново.
	fcopy(initial(donor.icon), transient_path)
	sheet.realize_spritesheets(yield = TRUE)
	TEST_ASSERT(sheet.fully_generated, "лист не поднялся после того, как DMI появился")
	TEST_ASSERT_EQUAL(sheet.cache_result, FALSE, "лист собрался заново вместо подъёма из кэша (cache_result: [sheet.cache_result])")

	drop_spritesheet_artifacts(sheet)
	fdel(transient_path)
	rustg_iconforge_cleanup()

/// Классификатор причин промаха и рост паузы между попытками - чистая арифметика,
/// но именно она решает, платим мы за лист сотни мегабайт или нет.
/datum/unit_test/spritesheet_batched_retry_policy
	requires_full_map = FALSE

/datum/unit_test/spritesheet_batched_retry_policy/Run()
	var/datum/asset/spritesheet_batched/test_batched/sheet = new()

	TEST_ASSERT(sheet.looks_like_deploy_race("шард 1 - ERROR: Error while hashing dmi_path 'icons/obj/pda.dmi': No such file or directory (os error 2)"), "ошибка чтения DMI не опознана как гонка деплоя")
	TEST_ASSERT(sheet.looks_like_deploy_race("шард 3 - more DMIs exist than DMI hashes provided"), "нехватка хэшей на шард не опознана как гонка деплоя")
	TEST_ASSERT(!sheet.looks_like_deploy_race("шард 1 - Input hash did not match"), "изменение набора спрайтов принято за гонку деплоя - лист завис бы на устаревшей раскладке")
	TEST_ASSERT(!sheet.looks_like_deploy_race("шард 2 - Input hash matched, but dmi_hash was invalid DMI: dmi_path (stored hash: aaa, new hash: bbb)"), "изменение содержимого DMI принято за гонку деплоя")
	TEST_ASSERT(!sheet.looks_like_deploy_race(null), "null принят за гонку деплоя")

	// Пауза удваивается с каждой списанной попыткой и упирается в потолок.
	var/previous = 0
	for(var/attempts_left = sheet.unread_retries_left - 1, attempts_left >= 0, attempts_left--)
		sheet.unread_retries_left = attempts_left
		var/delay = sheet.retry_delay()
		TEST_ASSERT(delay >= previous, "пауза перед повтором не растёт: [previous] -> [delay]")
		TEST_ASSERT(delay <= 2 MINUTES, "пауза перед повтором превысила потолок: [delay]")
		previous = delay
	TEST_ASSERT(previous > 15 SECONDS, "пауза так и не выросла выше базовой")

/// Меню крафта не имеет права возить иконки внутри нагрузки. На инлайновом base64
/// статика меню весила 3.03 МБ (2.71 МБ из них - картинки), и каждое открытие просило
/// у 32-битного DreamDaemon непрерывный кусок такого размера. На нём процесс и умирал:
/// раунды 9941 и 9948, обвал ровно в tgui_window.dm на сборке сообщения.
/datum/unit_test/crafting_payload_size
	requires_full_map = FALSE

/// Со спрайтшитом нагрузка укладывается в ~350 КБ. Порог держим с запасом, но заведомо
/// ниже мегабайта - смысл проверки в том, чтобы иконки не вернулись в нагрузку.
#define CRAFTING_PAYLOAD_LIMIT (900 * 1024)

/datum/unit_test/crafting_payload_size/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/datum/component/personal_crafting/crafting = user.GetComponent(/datum/component/personal_crafting)
	TEST_ASSERT_NOTNULL(crafting, "у человека нет компонента крафта - проверять нечего")

	var/list/static_data = crafting.ui_static_data(user)
	var/encoded = json_encode(static_data)
	log_test("CRAFTING PAYLOAD: [num2text(length(encoded), 12)] Б json, [num2text(length(url_encode(encoded)), 12)] Б после url_encode")
	TEST_ASSERT(length(encoded) < CRAFTING_PAYLOAD_LIMIT, "статика меню крафта весит [num2text(length(encoded), 12)] Б при пороге [num2text(CRAFTING_PAYLOAD_LIMIT, 12)] Б")

	// Классы спрайтов обязаны доехать: иначе интерфейс молча покажет пустые рамки.
	var/checked_recipes = 0
	for(var/category in static_data["crafting_recipes"])
		var/list/entries = static_data["crafting_recipes"][category]
		for(var/entry in entries)
			if(!islist(entry))
				continue
			var/list/recipe_data = entry
			if(!recipe_data["name"])
				continue
			checked_recipes++
			if(recipe_data["icon"])
				TEST_ASSERT(findtext(recipe_data["icon"], "crafting"), "класс спрайта у рецепта [recipe_data["name"]] не от листа крафта: [recipe_data["icon"]]")
	TEST_ASSERT(checked_recipes > 0, "в статике меню крафта не оказалось ни одного рецепта")

#undef CRAFTING_PAYLOAD_LIMIT
