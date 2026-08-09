/// Сколько ровных тиков прогонять перед синтетическим спайком. Фоновое окно для дельт cpu и
/// map_cpu - тики с -10 по -3 относительно спайка, то есть замеров нужно не меньше одиннадцати.
#define TICK_SPIKE_TEST_FLAT_TICKS 12

/// Тесты детектора тик-спайков (SStick_spikes): расчёт дрифта, кольца, классификация, отчёт.
/// Всё через прямую подачу синтетических замеров в sample_tick - без реальных таймингов,
/// чтобы не флачить в CI (реальные busy-wait проверки делаются вербом Simulate Tick Spike).
/datum/unit_test/tick_spike_recorder

/**
 * Прогоняет через рекордер базовый замер и TICK_SPIKE_TEST_FLAT_TICKS ровных тиков без
 * дрифта, чтобы классификатору было из чего считать фон.
 *
 * Шаг - ровно один тик (0.5дс игрового, 50мс реального), поэтому дрифт каждого замера
 * точный ноль и ложных спайков не возникает. После вызова последний замер лежит в
 * recorder.last_ms / recorder.last_world - синтетический спайк удобно строить от них.
 */
/datum/unit_test/tick_spike_recorder/proc/feed_flat_ticks(datum/controller/subsystem/tick_spikes/recorder, start_ms, start_world, cpu, map_cpu)
	recorder.sample_tick(start_ms, start_world, 2, cpu, map_cpu)
	var/at_ms = start_ms
	var/at_world = start_world
	for(var/i in 1 to TICK_SPIKE_TEST_FLAT_TICKS)
		at_ms += 50
		at_world += 0.5
		recorder.sample_tick(at_ms, at_world, 2, cpu, map_cpu)

/datum/unit_test/tick_spike_recorder/Run()
	var/datum/controller/subsystem/tick_spikes/recorder = SStick_spikes
	TEST_ASSERT_NOTNULL(recorder, "SStick_spikes не существует")

	// Синтетика ниже идёт шагами по 0.5дс игрового времени и 50мс реального - это ровно один
	// тик при штатных FPS 20. Классификация на это опирается: шаг игрового времени больше
	// world.tick_lag она считает пропущенными фаерами МК. Если сервер переедет на другой
	// tick_lag, тест должен упасть здесь с внятным текстом, а не в глубине классификатора.
	TEST_ASSERT_EQUAL(world.tick_lag, 0.5, "Тест написан под tick_lag 0.5 (FPS 20), а сейчас [world.tick_lag]")

	var/old_suppress = recorder.suppress_side_effects
	var/old_ignore_empty = recorder.ignore_empty_server
	// Метка собственного дампа живёт по РЕАЛЬНОМУ world.time и переживает reset_state().
	// Если профайлер дампился в этом же тике (периодическая сетка или авто-дамп по
	// внешнему столлу), classify_spike() коротит на "спайк вызван предыдущим дампом"
	// и синтетика ниже классифицируется мимо всего, что тест проверяет. Окно всего
	// 2 тика, поэтому падает редко и на случайной карте - CI multiz_debug, PR #3588.
	var/old_self_inflicted = recorder.self_inflicted_until
	recorder.suppress_side_effects = TRUE
	recorder.ignore_empty_server = TRUE
	recorder.self_inflicted_until = 0
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

	// 4. Классификация без тяжёлых прогонов, но с высоким cpu - "DM вне МК".
	// Фона тут всего один замер, дельту считать не из чего - срабатывает страховочный
	// абсолютный порог, ради которого он и оставлен.
	recorder.reset_state()
	recorder.sample_tick(1000, 200, 5, 10, 5)
	drift = recorder.sample_tick(1550, 200.5, 90, 95, 5)
	TEST_ASSERT_EQUAL(recorder.session_spike_count, 1, "Второй синтетический спайк не зафиксирован")
	TEST_ASSERT(findtext(recorder.spike_events[1], "DM вне МК"), "Спайк с высоким cpu без прогонов МК не классифицирован как DM вне МК")
	TEST_ASSERT(findtext(recorder.spike_events[1], "фон неизвестен"), "Классификация без набранного фона не сказала об этом в блоке")

	// 4a. Дельта cpu вместо абсолютного порога: фон 20%, в тике спайка 45% - абсолютного
	// порога 70 не хватает, но прирост +25 п.п. называет DM однозначно. Абсолютный порог
	// негоден по построению: фоновый world.cpu растёт по ходу раунда, и в раунде 9849 шесть
	// таких событий (914мс дрифта) уехали в "внешний столл" именно из-за него.
	recorder.reset_state()
	feed_flat_ticks(recorder, 1000, 700, 20, 5)
	TEST_ASSERT_EQUAL(recorder.session_spike_count, 0, "Ровный фон перед проверкой дельты дал ложный спайк")
	drift = recorder.sample_tick(recorder.last_ms + 350, recorder.last_world + 0.5, 40, 45, 5)
	TEST_ASSERT_EQUAL(drift, 300, "Дрифт спайка с приростом cpu посчитан неверно: [drift]")
	TEST_ASSERT_EQUAL(recorder.session_spike_count, 1, "Спайк с приростом cpu не зафиксирован")
	TEST_ASSERT(findtext(recorder.spike_events[1], "DM вне МК"), "Прирост cpu +25 п.п. над фоном 20% не классифицирован как DM вне МК")
	TEST_ASSERT(findtext(recorder.spike_events[1], "при фоне 20%"), "Фон cpu не назван в деталях классификации")

	// 4b. Обратная сторона той же монеты: cpu 62% высок сам по себе, но фон ровно такой же -
	// прироста нет, значит DM внутри тика не работал. Раньше такое отличалось от случая 4a
	// только абсолютным значением, и один из двух случаев обязательно был бы разобран неверно.
	recorder.reset_state()
	feed_flat_ticks(recorder, 1000, 800, 62, 4)
	drift = recorder.sample_tick(recorder.last_ms + 350, recorder.last_world + 0.5, 3, 62, 4)
	TEST_ASSERT(findtext(recorder.spike_events[1], "внешний столл"), "Высокий, но неизменный cpu ошибочно объявлен DM-работой")
	TEST_ASSERT(findtext(recorder.spike_events[1], "работы внутри тика НЕ БЫЛО"), "Блок не сказал словами, что работы в тике не было при нулевом приросте cpu")

	// 4c. Дельта map_cpu: фон 8%, в тике спайка 13% - до абсолютного порога 30 далеко,
	// но прирост +5 п.п. при шуме дельты меньше 2 п.п. однозначно указывает на рассылку карты
	recorder.reset_state()
	feed_flat_ticks(recorder, 1000, 900, 20, 8)
	drift = recorder.sample_tick(recorder.last_ms + 350, recorder.last_world + 0.5, 3, 21, 13)
	TEST_ASSERT(findtext(recorder.spike_events[1], "SendMaps"), "Прирост map_cpu +5 п.п. над фоном 8% не классифицирован как SendMaps")

	// 4d. Пропущенные фаеры МК: игрового времени прошло три тика вместо одного, cpu и
	// map_cpu не шелохнулись. Это не одиночный внешний столл, а дрифт, накопленный за
	// несколько тиков - в раунде 9849 таких событий было 7 на 2894мс, и все считались столлом
	recorder.reset_state()
	feed_flat_ticks(recorder, 1000, 1000, 20, 5)
	drift = recorder.sample_tick(recorder.last_ms + 350, recorder.last_world + 1.5, 2, 20, 5)
	TEST_ASSERT_EQUAL(drift, 200, "Дрифт при пропуске фаеров посчитан неверно: [drift]")
	TEST_ASSERT_EQUAL(recorder.missed_fires(), 2, "Число пропущенных фаеров посчитано неверно: [recorder.missed_fires()]")
	TEST_ASSERT(findtext(recorder.spike_events[1], "не давал детектору фаериться"), "Дрифт за несколько тиков не отделён от внешнего столла")
	TEST_ASSERT(findtext(recorder.spike_events[1], "накоплен за 3 тиков"), "Блок не назвал число тиков, за которые накоплен дрифт")

	// 4e. Ровный шаг детектора должен явно фиксироваться в блоке: без этой строки
	// "один растянутый промежуток" и "несколько пропущенных тиков" в логе неразличимы
	recorder.reset_state()
	feed_flat_ticks(recorder, 1000, 1100, 20, 5)
	drift = recorder.sample_tick(recorder.last_ms + 350, recorder.last_world + 0.5, 2, 20, 5)
	TEST_ASSERT_EQUAL(recorder.missed_fires(), 0, "Ровный шаг ошибочно посчитан пропуском фаеров")
	TEST_ASSERT(findtext(recorder.spike_events[1], "из одного межтикового промежутка"), "Блок не отметил, что дрифт из одного промежутка")

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

	// 5c2. Именованная DM-работа из кольца медленной работы забирает спайк себе.
	// Кольцо slow_work в классификации раньше не участвовало вообще - смотрели только
	// ПОСЛЕДНИЙ блокирующий вызов, и в раунде 9849 семь событий (784мс) с Topic'ом прямо
	// в окне спайка, покрывавшим весь дрифт, всё равно списались на внешний столл.
	// Времена привязаны к world.time: record_slow_work() штампует запись именно им,
	// и узкое окно классификации обязано с этой отметкой совпасть.
	recorder.reset_state()
	feed_flat_ticks(recorder, 1000, world.time - ((TICK_SPIKE_TEST_FLAT_TICKS + 1) * 0.5), 20, 5)
	recorder.record_slow_work("Topic (prefs)", "тестклиент: preference=gear", 180)
	recorder.sample_tick(recorder.last_ms + 300, recorder.last_world + 0.5, 3, 20, 5)
	TEST_ASSERT_EQUAL(recorder.session_spike_count, 1, "Спайк с именованной DM-работой не зафиксирован")
	TEST_ASSERT(findtext(recorder.spike_events[1], "DM вне МК"), "Именованная DM-работа в окне спайка не классифицирована как DM вне МК")
	TEST_ASSERT(findtext(recorder.spike_events[1], "Topic (prefs)"), "Имя виновной DM-работы не попало в вероятный источник")

	// 5c3. Усыпляющие виды (winget/winexists) кольцо тоже наполняют, но виновником спайка
	// быть не могут: пока прок спит в winget, мир тикает дальше. Без этого фильтра
	// классификатор винил бы любой проснувшийся winget во время ЧУЖОГО столла.
	recorder.reset_state()
	feed_flat_ticks(recorder, 1000, world.time - ((TICK_SPIKE_TEST_FLAT_TICKS + 1) * 0.5), 20, 5)
	recorder.record_slow_work("winget", "тестклиент: mapwindow.size", 400)
	recorder.sample_tick(recorder.last_ms + 300, recorder.last_world + 0.5, 3, 20, 5)
	TEST_ASSERT(findtext(recorder.spike_events[1], "внешний столл"), "Усыпляющий примитив из кольца перехватил классификацию столла")

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

	// 8a. Медиана фона переживает прокрутку кольца и не путается в его начале:
	// после 650 ровных замеров с cpu 1% фон обязан быть ровно 1%, а не нулём из пустых слотов
	var/cpu_baseline = recorder.ring_baseline_median(recorder.ring_cpu)
	TEST_ASSERT_EQUAL(cpu_baseline, 1, "Медиана фона после прокрутки кольца посчитана неверно: [cpu_baseline]")

	// Возврат живого состояния
	recorder.reset_state()
	recorder.suppress_side_effects = old_suppress
	recorder.ignore_empty_server = old_ignore_empty
	recorder.self_inflicted_until = old_self_inflicted

#undef TICK_SPIKE_TEST_FLAT_TICKS
