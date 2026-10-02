/// Превью описания разбирает только начало текста и совпадает с разбором полного текста
/datum/unit_test/flavor_text_preview_head

/datum/unit_test/flavor_text_preview_head/Run()
	var/long_text = "**Высокий** <рыжий> & шумный\n[repeat_string(400, "очень длинное описание ")]"
	var/full_preview = replacetext(parsemarkdown_basic(html_encode(long_text), hyperlink = FALSE), "\n", " ")
	var/head_preview = flavor_text_preview(long_text)
	TEST_ASSERT_EQUAL(copytext_char(head_preview, 1, MAX_FLAVOR_PREVIEW_LEN), copytext_char(full_preview, 1, MAX_FLAVOR_PREVIEW_LEN), "Видимое начало превью должно совпадать с разбором полного текста")
	TEST_ASSERT(length_char(head_preview) < length_char(full_preview) / 10, "Превью не должно разбирать весь текст описания")
