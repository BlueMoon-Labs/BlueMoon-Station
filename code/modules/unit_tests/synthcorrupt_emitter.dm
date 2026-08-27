/**
 * Оверлей повреждения синтетика держит РОВНО один эмиттер частиц.
 *
 * ЗАЧЕМ ТЕСТ. overlay_fullscreen() переиспользует уже созданный экранный объект и зовёт
 * SetSeverity() на каждом обновлении здоровья - у отравленного моба это каждый тик
 * Life(). Прежняя версия на каждый вызов делала new() и LAZYADD в vis_contents, затирая
 * ссылку holder и не убирая предыдущий холдер ни из vis_contents, ни из contents; каждый
 * осиротевший холдер оставался живым эмиттером /particles на 960x960 с count до 300,
 * который рисует клиент.
 *
 * Раунд 10129 (27.08.2026): 32-битный Dream Seeker набирал 2.4 ГБ за восемь минут и падал
 * около 3400 МБ, а перед падением рисовал чужие спрайты вместо штатных.
 *
 * Тест держит инвариант с обеих сторон: повторный вызов с той же тяжестью не добавляет
 * ничего, смена тяжести заменяет эмиттер, а не копит, и нулевая тяжесть его снимает.
 */
/datum/unit_test/synthcorrupt_emitter_is_single/Run()
	var/atom/movable/screen/fullscreen/scaled/synthcorrupt/overlay = new

	overlay.SetSeverity(3)
	var/after_first = length(overlay.vis_contents)

	for(var/repeat in 1 to 20)
		overlay.SetSeverity(3)
	var/after_repeats = length(overlay.vis_contents)
	var/contents_after_repeats = length(overlay.contents)

	overlay.SetSeverity(5)
	var/after_change = length(overlay.vis_contents)
	var/contents_after_change = length(overlay.contents)

	overlay.SetSeverity(0)
	var/after_zero = length(overlay.vis_contents)
	var/contents_after_zero = length(overlay.contents)

	qdel(overlay)

	TEST_ASSERT_EQUAL(after_first, 1, "первый вызов обязан завести ровно один эмиттер")
	TEST_ASSERT_EQUAL(after_repeats, 1, "двадцать вызовов с той же тяжестью дали [after_repeats] эмиттеров вместо одного - холдер снова копится в vis_contents")
	TEST_ASSERT_EQUAL(contents_after_repeats, 1, "осиротевшие холдеры остались в contents: [contents_after_repeats] вместо одного")
	TEST_ASSERT_EQUAL(after_change, 1, "смена тяжести обязана заменять эмиттер, а не добавлять второй")
	// contents проверяется отдельно от vis_contents: loc холдера - сам экранный объект,
	// и прежняя версия роняла ссылку, не вынимая холдер НИ ОТКУДА. Чистый vis_contents при
	// забитом contents - это ровно та утечка, из-за которой клиент и рисовал эмиттеры.
	TEST_ASSERT_EQUAL(contents_after_change, 1, "смена тяжести оставила старый холдер в contents: [contents_after_change] вместо одного")
	TEST_ASSERT_EQUAL(after_zero, 0, "нулевая тяжесть обязана снимать эмиттер")
	TEST_ASSERT_EQUAL(contents_after_zero, 0, "нулевая тяжесть оставила холдер в contents: [contents_after_zero] вместо нуля")
