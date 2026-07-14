/// Тесты детектора тик-спайков (SStick_spikes): расчёт дрифта, кольца, классификация, отчёт.
/// Всё через прямую подачу синтетических замеров в sample_tick - без реальных таймингов,
/// чтобы не флачить в CI (реальные busy-wait проверки делаются вербом Simulate Tick Spike).
/datum/unit_test/tick_spike_recorder

/datum/unit_test/tick_spike_recorder/Run()
	var/datum/controller/subsystem/tick_spikes/recorder = SStick_spikes
	TEST_ASSERT_NOTNULL(recorder, "SStick_spikes не существует")

	var/old_suppress = recorder.suppress_side_effects
	var/old_ignore_empty = recorder.ignore_empty_server
	recorder.suppress_side_effects = TRUE
	recorder.ignore_empty_server = TRUE
	recorder.reset_state()

	// 1. Ровная последовательность: 50мс реального времени на 0.5дс игрового - дрифта нет
	recorder.sample_tick(1000, 100, 5, 10, 5) // первый замер задаёт базу
	var/drift = recorder.sample_tick(1050, 100.5, 5, 10, 5)
	TEST_ASSERT_EQUAL(drift, 0, "Ровный тик дал ненулевой дрифт")
	recorder.sample_tick(1100, 101, 5, 10, 5)
	TEST_ASSERT_EQUAL(recorder.session_spike_count, 0, "Спайк зафиксирован на ровной последовательности")

	// 2. Тяжёлый прогон подсистемы попадает в кольцо и в контекст события
	recorder.record_heavy_run(recorder, 85)

	// 3. Фриз: +550мс реального времени на 0.5дс игрового = дрифт 500мс
	drift = recorder.sample_tick(1650, 101.5, 90, 95, 5)
	TEST_ASSERT_EQUAL(drift, 500, "Дрифт фриза посчитан неверно: [drift]")
	TEST_ASSERT_EQUAL(recorder.session_spike_count, 1, "Фриз 500мс не зафиксирован как спайк")
	TEST_ASSERT_EQUAL(length(recorder.spike_events), 1, "Событие спайка не сохранено")
	TEST_ASSERT(recorder.worst_drift_ms >= 500, "worst_drift_ms не обновился")
	TEST_ASSERT_EQUAL(recorder.drift_histogram[4], 1, "Дрифт 500мс не попал в корзину 300-1000")

	// Классификация: есть тяжёлый прогон - источник "подсистема МК", и он назван в событии
	var/event_text = recorder.spike_events[1]
	TEST_ASSERT(findtext(event_text, "подсистема МК"), "Спайк с тяжёлым прогоном не классифицирован как подсистема МК")
	TEST_ASSERT(findtext(event_text, "[recorder.name]: 85"), "Тяжёлый прогон (имя и usage) не попал в событие")

	// 4. Классификация без тяжёлых прогонов, но с высоким cpu - "DM вне МК"
	recorder.reset_state()
	recorder.sample_tick(1000, 200, 5, 10, 5)
	drift = recorder.sample_tick(1550, 200.5, 90, 95, 5)
	TEST_ASSERT_EQUAL(recorder.session_spike_count, 1, "Второй синтетический спайк не зафиксирован")
	TEST_ASSERT(findtext(recorder.spike_events[1], "DM вне МК"), "Спайк с высоким cpu без прогонов МК не классифицирован как DM вне МК")

	// 5. Классификация чистого столла: cpu и map_cpu низкие - "внешний столл"
	recorder.reset_state()
	recorder.sample_tick(1000, 300, 2, 5, 3)
	recorder.sample_tick(1050, 300.5, 2, 5, 3)
	recorder.sample_tick(1600, 301, 2, 5, 3)
	TEST_ASSERT_EQUAL(recorder.session_spike_count, 1, "Спайк-столл не зафиксирован")
	TEST_ASSERT(findtext(recorder.spike_events[1], "внешний столл"), "Столл без DM-нагрузки классифицирован неверно")

	// 6. Метка синтетики цепляется к следующему событию и очищается
	recorder.reset_state()
	recorder.next_spike_tag = "ТЕСТОВАЯ МЕТКА"
	recorder.sample_tick(1000, 400, 5, 10, 5)
	recorder.sample_tick(1500, 400.5, 5, 10, 5)
	TEST_ASSERT(findtext(recorder.spike_events[1], "ТЕСТОВАЯ МЕТКА"), "Метка симуляции не попала в событие")
	TEST_ASSERT_NULL(recorder.next_spike_tag, "Метка симуляции не очистилась после события")

	// 6.1. Рейт-лимит полных блоков: второй спайк в окне пишется кратко, но копится в статистике
	recorder.sample_tick(2100, 401, 5, 10, 5)
	TEST_ASSERT_EQUAL(recorder.session_spike_count, 2, "Спайк под рейт-лимитом не посчитался в статистике")
	TEST_ASSERT_EQUAL(length(recorder.spike_events), 1, "Спайк под рейт-лимитом создал полный блок")
	TEST_ASSERT_EQUAL(recorder.suppressed_event_count, 1, "Счётчик кратких записей не вырос")

	// 7. Отчёт собирается и содержит ключевые поля
	var/report = recorder.build_report()
	TEST_ASSERT(findtext(report, "SStick_spikes"), "Отчёт не содержит заголовка")
	TEST_ASSERT(findtext(report, "ТЕСТОВАЯ МЕТКА"), "Отчёт не содержит событий")

	// 8. Кольца не ломаются при переполнении (600+ замеров без спайков)
	recorder.reset_state()
	var/fake_ms = 1000
	var/fake_world = 500
	recorder.sample_tick(fake_ms, fake_world, 1, 1, 1)
	for(var/i in 1 to 650)
		fake_ms += 50
		fake_world += 0.5
		recorder.sample_tick(fake_ms, fake_world, 1, 1, 1)
	TEST_ASSERT_EQUAL(recorder.session_spike_count, 0, "Ложные спайки при прокрутке кольца")
	TEST_ASSERT_EQUAL(recorder.samples_collected, 650, "Счётчик замеров разошёлся: [recorder.samples_collected]")
	for(var/i in 1 to 200)
		recorder.record_heavy_run(recorder, 50)

	// Возврат живого состояния
	recorder.reset_state()
	recorder.suppress_side_effects = old_suppress
	recorder.ignore_empty_server = old_ignore_empty
