/// Имена слотов берутся из кэша без открытия сейвфайла, а сброшенный или устаревший по числу слотов кэш перечитывается
/datum/unit_test/preferences_slot_names_cache

/datum/unit_test/preferences_slot_names_cache/Run()
	var/datum/preferences/prefs = new
	prefs.load_path("unit_test_slot_names_cache")
	fdel(prefs.path)
	prefs.max_save_slots = 3

	prefs.slot_names_cache = list("Альфа", null, "Гамма")
	var/list/cached = prefs.get_slot_names()
	TEST_ASSERT_EQUAL(cached[1], "Альфа", "Кэш имён слотов должен отдаваться как есть")
	TEST_ASSERT(!fexists(prefs.path), "Попадание в кэш не должно открывать сейвфайл")

	prefs.max_save_slots = 4
	var/list/reread = prefs.get_slot_names()
	TEST_ASSERT_EQUAL(length(reread), 4, "Кэш под другое число слотов должен перечитываться")
	TEST_ASSERT_NULL(reread[1], "В пустом сейвфайле не должно быть имён")

	fdel(prefs.path)
	qdel(prefs)

/// Превью описания разбирает только начало текста и совпадает с разбором полного текста
/datum/unit_test/flavor_text_preview_head

/datum/unit_test/flavor_text_preview_head/Run()
	var/long_text = "**Высокий** <рыжий> & шумный\n[repeat_string(400, "очень длинное описание ")]"
	var/full_preview = replacetext(parsemarkdown_basic(html_encode(long_text), hyperlink = FALSE), "\n", " ")
	var/head_preview = flavor_text_preview(long_text)
	TEST_ASSERT_EQUAL(copytext_char(head_preview, 1, MAX_FLAVOR_PREVIEW_LEN), copytext_char(full_preview, 1, MAX_FLAVOR_PREVIEW_LEN), "Видимое начало превью должно совпадать с разбором полного текста")
	TEST_ASSERT(length_char(head_preview) < length_char(full_preview) / 10, "Превью не должно разбирать весь текст описания")
