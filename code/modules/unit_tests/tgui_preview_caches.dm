// Кадры для tgui, которые раньше собирались на каждый ui_data: превью конструктора
// IPC (полный манекен + getFlatIcon + icon2base64, 130-250 мс), кадры Color Mate (два
// getFlatIcon + два icon2base64) и фото записей персонала (icon2base64 на каждую
// запись списка). Все три теперь живут в кэше с подписью входов; тесты проверяют
// сам контракт кэша: повторный запрос с теми же входами не пересобирает кадр, а смена
// входа - пересобирает. "Не пересобирает" доказывается подменой кэша сторожевым
// значением: пересборка его затёрла бы.

#define PREVIEW_CACHE_SENTINEL "sentinel-preview"

/// Конструктор IPC: та же подпись - кадр из кэша, другой размер тела - новый кадр.
/datum/unit_test/ipc_constructor_preview_cache/Run()
	var/obj/machinery/ipc_constructor/constructor = allocate(/obj/machinery/ipc_constructor, run_loc_floor_bottom_left)
	var/first = constructor.get_preview_icon_base64()
	TEST_ASSERT_NOTNULL(first, "первый запрос превью должен собрать кадр")
	TEST_ASSERT_NOTNULL(constructor.preview_cache_signature, "после сборки кэш должен запомнить подпись входов")

	constructor.preview_cache_base64 = PREVIEW_CACHE_SENTINEL
	TEST_ASSERT_EQUAL(constructor.get_preview_icon_base64(), PREVIEW_CACHE_SENTINEL, "повторный запрос с теми же входами должен отдавать кэш, а не пересобирать манекен")

	constructor.selected_body_size = constructor.selected_body_size + 0.25
	var/resized = constructor.get_preview_icon_base64()
	TEST_ASSERT_NOTEQUAL(resized, PREVIEW_CACHE_SENTINEL, "смена размера тела должна сбросить кэш и пересобрать кадр")
	TEST_ASSERT_NOTNULL(resized, "пересобранный кадр должен быть непустым")

	constructor.preview_cache_base64 = PREVIEW_CACHE_SENTINEL
	constructor.head_part = allocate(/obj/item/bodypart/head/robot/ipc)
	TEST_ASSERT_NOTEQUAL(constructor.get_preview_icon_base64(), PREVIEW_CACHE_SENTINEL, "установка конечности должна сбросить кэш")
	constructor.head_part = null

/// Color Mate: кадр предмета зависит от предмета и его цвета, кадр превью - ещё и от
/// параметров активного режима.
/datum/unit_test/colormate_preview_cache/Run()
	var/obj/machinery/gear_painter/painter = allocate(/obj/machinery/gear_painter, run_loc_floor_bottom_left)
	var/obj/item/clothing/under/color/red/jumpsuit = allocate(/obj/item/clothing/under/color/red)
	painter.inserted = jumpsuit

	TEST_ASSERT_NOTNULL(painter.get_sprite_base64(), "первый запрос кадра предмета должен собрать его")
	TEST_ASSERT_NOTNULL(painter.get_preview_base64(), "первый запрос превью должен собрать его")

	painter.sprite_cache_base64 = PREVIEW_CACHE_SENTINEL
	painter.preview_cache_base64 = PREVIEW_CACHE_SENTINEL
	TEST_ASSERT_EQUAL(painter.get_sprite_base64(), PREVIEW_CACHE_SENTINEL, "кадр предмета с теми же входами должен идти из кэша")
	TEST_ASSERT_EQUAL(painter.get_preview_base64(), PREVIEW_CACHE_SENTINEL, "превью с теми же входами должно идти из кэша")

	// Ползунок оттенка меняет только превью: кадр самого предмета остаётся прежним.
	painter.build_hue = painter.build_hue + 90
	TEST_ASSERT_EQUAL(painter.get_sprite_base64(), PREVIEW_CACHE_SENTINEL, "смена оттенка не должна трогать кадр самого предмета")
	TEST_ASSERT_NOTEQUAL(painter.get_preview_base64(), PREVIEW_CACHE_SENTINEL, "смена оттенка должна пересобрать превью")

	// Покраска меняет цвет предмета - и его кадр, и превью.
	painter.sprite_cache_base64 = PREVIEW_CACHE_SENTINEL
	painter.preview_cache_base64 = PREVIEW_CACHE_SENTINEL
	jumpsuit.add_atom_colour("#00FF00", FIXED_COLOUR_PRIORITY)
	TEST_ASSERT_NOTEQUAL(painter.get_sprite_base64(), PREVIEW_CACHE_SENTINEL, "смена цвета предмета должна пересобрать его кадр")
	TEST_ASSERT_NOTEQUAL(painter.get_preview_base64(), PREVIEW_CACHE_SENTINEL, "смена цвета предмета должна пересобрать превью")

	// Другой предмет - другая подпись даже при том же цвете.
	painter.sprite_cache_base64 = PREVIEW_CACHE_SENTINEL
	painter.inserted = allocate(/obj/item/clothing/under/color/red)
	TEST_ASSERT_NOTEQUAL(painter.get_sprite_base64(), PREVIEW_CACHE_SENTINEL, "смена предмета должна пересобрать кадр")
	painter.inserted = null

/// Фото записи: кодировка кэшируется на время жизни picture_image, подмена иконки сбрасывает кэш.
/datum/unit_test/picture_base64_cache/Run()
	var/datum/picture/picture = new
	TEST_ASSERT_NULL(picture.get_base64(), "картинка без изображения не должна ничего кодировать")

	picture.picture_image = icon('icons/effects/effects.dmi', "nothing")
	var/first = picture.get_base64()
	TEST_ASSERT_NOTNULL(first, "картинка с изображением должна кодироваться")

	picture.base64_cache = PREVIEW_CACHE_SENTINEL
	TEST_ASSERT_EQUAL(picture.get_base64(), PREVIEW_CACHE_SENTINEL, "повторный запрос с той же иконкой должен идти из кэша")

	picture.picture_image = icon('icons/effects/effects.dmi', "nothing")
	TEST_ASSERT_NOTEQUAL(picture.get_base64(), PREVIEW_CACHE_SENTINEL, "подмена иконки новым объектом должна сбросить кэш")
	qdel(picture)

#undef PREVIEW_CACHE_SENTINEL
