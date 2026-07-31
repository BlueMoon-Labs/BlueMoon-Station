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

	// 5a. Рассылка карты: cpu низкий, map_cpu выше порога - "SendMaps".
	// Класс существовал, но не проверялся, и порог был выставлен так, что в проде он
	// почти не достигался: вся стоимость SendMaps утекала в "внешний столл".
	recorder.reset_state()
	recorder.sample_tick(1000, 400, 2, 5, 35)
	recorder.sample_tick(1050, 400.5, 2, 5, 35)
	recorder.sample_tick(1600, 401, 2, 5, 35)
	TEST_ASSERT_EQUAL(recorder.session_spike_count, 1, "Спайк с высоким map_cpu не зафиксирован")
	TEST_ASSERT(findtext(recorder.spike_events[1], "SendMaps"), "Спайк с map_cpu выше порога не классифицирован как SendMaps")

	// 5b. Блокирующий вызов: cpu и map_cpu низкие, как у внешнего столла, но замер
	// вокруг примитива закрывает большую часть дрифта - виним его поимённо.
	// Половина спайков раунда 9838 была безымянными столлами именно из-за того,
	// что ожидание клиента и диска ничем не измерялось.
	recorder.reset_state()
	recorder.sample_tick(1000, 500, 2, 5, 3)
	recorder.sample_tick(1050, 500.5, 2, 5, 3)
	recorder.record_blocking_call("winget", "тестклиент: input.text", 480)
	recorder.sample_tick(1600, 501, 2, 5, 3)
	TEST_ASSERT_EQUAL(recorder.session_spike_count, 1, "Спайк с блокирующим вызовом не зафиксирован")
	TEST_ASSERT(findtext(recorder.spike_events[1], "блокирующий вызов"), "Спайк, закрытый блокирующим вызовом, не классифицирован как блокирующий")
	TEST_ASSERT(findtext(recorder.spike_events[1], "тестклиент: input.text"), "Описание блокирующего вызова не попало в событие")

	// 5c. Дешёвый блокирующий вызов не должен перехватывать классификацию:
	// он не покрывает дрифт, значит это совпадение, а не причина
	recorder.reset_state()
	recorder.sample_tick(1000, 600, 2, 5, 3)
	recorder.sample_tick(1050, 600.5, 2, 5, 3)
	recorder.record_blocking_call("winget", "тестклиент: input.text", 35)
	recorder.sample_tick(1600, 601, 2, 5, 3)
	TEST_ASSERT(findtext(recorder.spike_events[1], "внешний столл"), "Дешёвый блокирующий вызов перехватил классификацию столла")

	// 5d. Учёт блокирующих вызовов: считаются все, включая те, что ниже порога кольца
	recorder.reset_state()
	recorder.record_blocking_call("winget", "а", 5)
	recorder.record_blocking_call("winget", "б", 15)
	recorder.record_blocking_call("savefile (запись)", "в", 40)
	TEST_ASSERT_EQUAL(recorder.blocking_calls, 3, "Счётчик блокирующих вызовов разошёлся")
	TEST_ASSERT_EQUAL(recorder.blocking_total_ms, 60, "Сумма блокирующих вызовов посчитана неверно")
	var/list/winget_bucket = recorder.blocking_by_kind["winget"]
	TEST_ASSERT_EQUAL(winget_bucket["count"], 2, "Разбивка по типу вызова потеряла запись")
	TEST_ASSERT_EQUAL(winget_bucket["max"], 15, "Максимум по типу вызова посчитан неверно")
	var/blocking_summary = recorder.build_blocking_summary()
	TEST_ASSERT(findtext(blocking_summary, "winget"), "Итог по блокирующим вызовам не называет тип")
	// Отрицательная стоимость (часы переехали) не должна портить статистику
	recorder.record_blocking_call("winget", "г", -100)
	TEST_ASSERT_EQUAL(recorder.blocking_total_ms, 60, "Отрицательный замер попал в сумму")

	// 6. Метка синтетики цепляется к следующему событию и очищается
	recorder.reset_state()
	recorder.next_spike_tag = "ТЕСТОВАЯ МЕТКА"
	recorder.sample_tick(1000, 400, 5, 10, 5)
	recorder.sample_tick(1500, 400.5, 5, 10, 5)
	TEST_ASSERT(findtext(recorder.spike_events[1], "ТЕСТОВАЯ МЕТКА"), "Метка симуляции не попала в событие")
	TEST_ASSERT_NULL(recorder.next_spike_tag, "Метка симуляции не очистилась после события")

	// 6.1. Рейт-лимит полных блоков: второй спайк в окне пишется кратко, но копится в статистике.
	// Дрифт держим ниже TICK_SPIKES_FULL_EVENT_DRIFT_FLOOR, иначе крупный спайк обойдёт троттлинг.
	recorder.sample_tick(1700, 401, 5, 10, 5)
	TEST_ASSERT_EQUAL(recorder.session_spike_count, 2, "Спайк под рейт-лимитом не посчитался в статистике")
	TEST_ASSERT_EQUAL(length(recorder.spike_events), 1, "Спайк под рейт-лимитом создал полный блок")
	TEST_ASSERT_EQUAL(recorder.suppressed_event_count, 1, "Счётчик кратких записей не вырос")

	// 6.2. Крупный спайк обходит рейт-лимит: контекст по таким событиям терять нельзя
	recorder.sample_tick(2400, 401.5, 5, 10, 5)
	TEST_ASSERT_EQUAL(recorder.session_spike_count, 3, "Крупный спайк не посчитался в статистике")
	TEST_ASSERT_EQUAL(length(recorder.spike_events), 2, "Крупный спайк не получил полный блок вопреки рейт-лимиту")
	TEST_ASSERT_EQUAL(recorder.suppressed_event_count, 1, "Крупный спайк ошибочно записан кратко")

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
