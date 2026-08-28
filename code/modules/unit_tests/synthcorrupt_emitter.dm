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

/**
 * overlay_fullscreen() не делает работы, когда обновлять нечего.
 *
 * Ранний возврат есть у апстрима и был потерян при переносе. Без него update_damage_hud()
 * прогоняет тело прока шесть раз за вызов - по разу на critvision, crit, oxy, brute,
 * synthcorrupt и кровопотерю, - и делает это на каждом updatehealth(), то есть на тике
 * Life() любого раненого моба и на каждом применении урона. Именно это сделало SetSeverity()
 * горячим и породило утечку эмиттеров, которую лечит тест выше.
 *
 * Тест проверяет не производительность, а инвариант: при неизменной тяжести повторный вызов
 * обязан вернуть ТОТ ЖЕ экранный объект и не тронуть ни его состояние, ни client.screen.
 */
/datum/unit_test/overlay_fullscreen_skips_no_op/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)

	var/atom/movable/screen/fullscreen/scaled/synthcorrupt/first = patient.overlay_fullscreen("synthcorrupt", /atom/movable/screen/fullscreen/scaled/synthcorrupt, 3)
	TEST_ASSERT_NOTNULL(first, "overlay_fullscreen не создал экранный объект")
	var/holder_after_first = first.holder
	TEST_ASSERT_NOTNULL(holder_after_first, "тяжесть 3 обязана завести эмиттер")

	// Тот же вызов ещё двадцать раз - ровно то, что делает update_damage_hud() у моба,
	// чей урон стоит на месте.
	for(var/repeat in 1 to 20)
		patient.overlay_fullscreen("synthcorrupt", /atom/movable/screen/fullscreen/scaled/synthcorrupt, 3)

	TEST_ASSERT(patient.fullscreens["synthcorrupt"] == first, "повторный вызов подменил экранный объект")
	TEST_ASSERT(first.holder == holder_after_first, "повторный вызов пересоздал эмиттер: ранний возврат не работает")
	TEST_ASSERT_EQUAL(length(first.vis_contents), 1, "после двадцати повторов эмиттеров стало [length(first.vis_contents)]")

	// Смена тяжести обязана пройти НАСКВОЗЬ: ранний возврат не должен глотать настоящее
	// обновление, иначе оверлей замрёт на первой попавшейся тяжести.
	patient.overlay_fullscreen("synthcorrupt", /atom/movable/screen/fullscreen/scaled/synthcorrupt, 5)
	TEST_ASSERT_EQUAL(first.severity, 5, "смена тяжести не доехала: ранний возврат съел настоящее обновление")

	// Нулевая тяжесть тоже обязана проходить: у нас это снятие эффекта, а не no-op.
	patient.overlay_fullscreen("synthcorrupt", /atom/movable/screen/fullscreen/scaled/synthcorrupt, 0)
	TEST_ASSERT_NULL(first.holder, "нулевая тяжесть не сняла эмиттер: ранний возврат съел снятие")

	patient.clear_fullscreen("synthcorrupt", 0)
