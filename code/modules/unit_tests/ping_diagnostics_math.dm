/datum/unit_test/ping_diag_percentile/Run()
	TEST_ASSERT_EQUAL(ping_diag_median(list()), 0, "пустой список")
	TEST_ASSERT_EQUAL(ping_diag_median(list(5, 1, 3)), 3, "медиана нечётного")
	TEST_ASSERT_EQUAL(ping_diag_median(list(4, 1, 3, 2)), 2, "медиана чётного - нижняя")
	TEST_ASSERT_EQUAL(ping_diag_percentile(list(1, 2, 3, 4, 5, 6, 7, 8, 9, 10), 95), 10, "p95")
	var/list/source = list(3, 1, 2)
	ping_diag_median(source)
	TEST_ASSERT_EQUAL(source[1], 3, "исходный список не сортируется на месте")

/datum/unit_test/ping_diag_spikes/Run()
	var/list/personal = list(5, 8, 6, 250, 7, 5, 300, 320, 6)
	var/list/spikes = ping_diag_find_spikes(personal)
	TEST_ASSERT_EQUAL(spikes.Join(","), "4,7,8", "спайки выше пола в 100 мс")
	TEST_ASSERT_EQUAL(ping_diag_count_loss_like(personal, spikes), 1, "одиночный высокий - потеря, два подряд - нет")
	// У шумной сети порог растёт вместе с медианой: 3 * 60 = 180.
	TEST_ASSERT_EQUAL(length(ping_diag_find_spikes(list(60, 70, 50, 65, 150, 55))), 0, "150 при медиане 60 не спайк")

/datum/unit_test/ping_diag_period/Run()
	TEST_ASSERT_EQUAL(ping_diag_spike_period(list(0, 600, 1200)), 0, "трёх эпизодов мало")
	TEST_ASSERT_EQUAL(ping_diag_spike_period(list(0, 600, 1210, 1800, 2405)), 600, "ровный ритм раз в минуту")
	TEST_ASSERT_EQUAL(ping_diag_spike_period(list(0, 100, 900, 1000, 2500)), 0, "рваные интервалы - не ритм")
	var/list/collapsed = ping_diag_collapse_bursts(list(0, 5, 600, 603, 1200), PING_DIAG_BURST_GAP_DS)
	TEST_ASSERT_EQUAL(collapsed.Join(","), "0,600,1200", "соседние спайки - один эпизод")

/datum/unit_test/ping_diag_shared_and_events/Run()
	TEST_ASSERT_EQUAL(ping_diag_shared_excess(list(10, 20, 30, 40)), 0, "четырёх ответивших мало")
	TEST_ASSERT_EQUAL(ping_diag_shared_excess(list(0, 10, 20, 30, 40, 200)), 20, "медиана лишнего")
	TEST_ASSERT_EQUAL(ping_diag_classify_event(120, 10), PING_EVENT_SERVER_STALL, "простой - сервер")
	TEST_ASSERT_EQUAL(ping_diag_classify_event(0, 95), PING_EVENT_SERVER_LOAD, "без простоя, но тик забит")
	TEST_ASSERT_EQUAL(ping_diag_classify_event(0, 30), PING_EVENT_HOST_NETWORK, "сервер свободен - канал хоста")
	TEST_ASSERT_EQUAL(ping_diag_classify_event(0, 30, 5, 65), PING_EVENT_SERVER_LOAD, "тяжёлый прогон подсистемы держит ответы - наша нагрузка")
	TEST_ASSERT_EQUAL(ping_diag_classify_event(0, 30, 5, PING_DIAG_SERVER_LOAD_RUN - 1), PING_EVENT_HOST_NETWORK, "лёгкие прогоны - канал хоста")

/datum/unit_test/ping_diag_verdicts/proc/stats(list/overrides)
	var/list/result = list(
		"samples" = 100,
		"extra_mean" = 5,
		"ours_fraction" = 0,
		"freezes" = 0,
		"loop_lag" = 5,
		"fps" = 60,
		"hidden" = 0,
		"loss_per_min" = 0,
		"period" = 0,
		"personal_median" = 5,
		"base" = 40,
		"server_base" = 40,
		"build" = 5161688,
		"warn_build" = 5161600,
	)
	for(var/key in overrides)
		result[key] = overrides[key]
	return result

/datum/unit_test/ping_diag_verdicts/proc/main(list/overrides)
	var/list/verdicts = ping_diag_pick_verdicts(stats(overrides))
	return verdicts[1]

/datum/unit_test/ping_diag_verdicts/Run()
	TEST_ASSERT_EQUAL(main(list("samples" = 5)), PING_VERDICT_COLLECTING, "мало сэмплов")
	TEST_ASSERT_EQUAL(main(list()), PING_VERDICT_OK, "ровная связь")
	TEST_ASSERT_EQUAL(main(list("extra_mean" = 80, "ours_fraction" = 0.9)), PING_VERDICT_SERVER, "лишнее в основном наше")
	TEST_ASSERT_EQUAL(main(list("extra_mean" = 10, "ours_fraction" = 1)), PING_VERDICT_OK, "незаметное лишнее не повод винить сервер")
	TEST_ASSERT_EQUAL(main(list("freezes" = 2)), PING_VERDICT_FREEZE, "подвисания")
	TEST_ASSERT_EQUAL(main(list("loop_lag" = 120)), PING_VERDICT_PC, "лаг event loop")
	TEST_ASSERT_EQUAL(main(list("fps" = 12)), PING_VERDICT_PC, "мало кадров")
	TEST_ASSERT_EQUAL(main(list("loop_lag" = 120, "hidden" = 1)), PING_VERDICT_OK, "свёрнутое окно не судим")
	TEST_ASSERT_EQUAL(main(list("loop_lag" = null, "fps" = null)), PING_VERDICT_OK, "без данных браузера ПК не винится")
	TEST_ASSERT_EQUAL(main(list("chat_rate" = 40, "recent_personal_median" = 45)), PING_VERDICT_FLOOD, "поток чата и колебания за те же 30 с")
	TEST_ASSERT_EQUAL(main(list("chat_rate" = 40, "recent_freezes" = 1)), PING_VERDICT_FLOOD, "поток чата и свежее подвисание")
	TEST_ASSERT_EQUAL(main(list("chat_rate" = 40, "recent_rtt_p95" = 260, "base" = 40)), PING_VERDICT_FLOOD, "поток чата и p95 за 30 с выше базы на 220 мс")
	TEST_ASSERT_EQUAL(main(list("chat_rate" = 40, "recent_rtt_p95" = 200, "base" = 40)), PING_VERDICT_OK, "p95 выше базы на 160 мс - не очередь")
	TEST_ASSERT_EQUAL(main(list("chat_rate" = 400)), PING_VERDICT_OK, "большой поток без следов очереди - не беда")
	TEST_ASSERT_EQUAL(main(list("chat_rate" = 9.9, "personal_median" = 45, "recent_personal_median" = 45)), PING_VERDICT_JITTER, "поток ниже порога - судим сеть")
	TEST_ASSERT_EQUAL(main(list("chat_rate" = 12, "freezes" = 2, "recent_freezes" = 0)), PING_VERDICT_FREEZE, "давние подвисания при свежем потоке без следов очереди - свои")
	TEST_ASSERT_EQUAL(main(list("chat_rate" = 12, "personal_median" = 45, "rtt_p95" = 900)), PING_VERDICT_JITTER, "давние колебания и p95 за 5 минут поток не прячут")
	TEST_ASSERT_EQUAL(main(list("chat_rate" = null, "freezes" = 2)), PING_VERDICT_FREEZE, "поток неизвестен - подвисания свои")
	var/list/flooded = ping_diag_pick_verdicts(stats(list("chat_rate" = 40, "recent_freezes" = 1, "freezes" = 5, "period" = 600, "loss_per_min" = 3, "personal_median" = 80)))
	TEST_ASSERT_EQUAL(flooded.Join(","), PING_VERDICT_FLOOD, "при потоке подвисания, ритм, потери и колебания не ставятся")
	var/list/flood_and_pc = ping_diag_pick_verdicts(stats(list("chat_rate" = 40, "recent_freezes" = 1, "freezes" = 5, "loop_lag" = 120, "base" = 180)))
	TEST_ASSERT_EQUAL(flood_and_pc.Join(","), "[PING_VERDICT_FLOOD],[PING_VERDICT_PC],[PING_VERDICT_FAR]", "ПК и база остаются советами")
	var/list/server_and_flood = ping_diag_pick_verdicts(stats(list("extra_mean" = 80, "ours_fraction" = 0.9, "chat_rate" = 40, "recent_freezes" = 1, "freezes" = 5)))
	TEST_ASSERT_EQUAL(server_and_flood.Join(","), "[PING_VERDICT_SERVER],[PING_VERDICT_FLOOD]", "поток сразу после сервера")
	var/list/both = ping_diag_pick_verdicts(stats(list("period" = 600, "loss_per_min" = 1.2)))
	TEST_ASSERT_EQUAL(both.Join(","), "[PING_VERDICT_PERIODIC],[PING_VERDICT_LOSS]", "ритм важнее потерь, обе подсказки остаются")
	TEST_ASSERT_EQUAL(main(list("personal_median" = 45)), PING_VERDICT_JITTER, "джиттер")
	var/list/jitter_with_loss = ping_diag_pick_verdicts(stats(list("personal_median" = 45, "loss_per_min" = 2)))
	TEST_ASSERT(!(PING_VERDICT_JITTER in jitter_with_loss), "при потерях джиттер не дублируем")
	TEST_ASSERT_EQUAL(main(list("base" = 180)), PING_VERDICT_FAR, "высокая база")
	TEST_ASSERT_EQUAL(main(list("base" = 100, "server_base" = 40)), PING_VERDICT_FAR, "база вдвое выше серверной")
	TEST_ASSERT_EQUAL(main(list("base" = 70, "server_base" = 20)), PING_VERDICT_OK, "мелкая база не далеко, даже если втрое выше")
	var/list/old_build = ping_diag_pick_verdicts(stats(list("build" = 5141500)))
	TEST_ASSERT_EQUAL(old_build.Join(","), PING_VERDICT_OK, "старая сборка - не вердикт про пинг")
	TEST_ASSERT(ping_diag_old_build(stats(list("build" = 5141500))), "старая сборка - отдельный совет")
	TEST_ASSERT(!ping_diag_old_build(stats(list())), "свежая сборка - без совета")
	TEST_ASSERT(!ping_diag_old_build(stats(list("warn_build" = 0, "build" = 5141500))), "без конфига сборку не судим")
	TEST_ASSERT(!ping_diag_old_build(stats(list("build" = 0))), "сборка неизвестна - без совета")

/datum/unit_test/ping_diag_texts/Run()
	for(var/verdict in list(PING_VERDICT_FLOOD, PING_VERDICT_FREEZE, PING_VERDICT_PC, PING_VERDICT_PERIODIC, PING_VERDICT_LOSS, PING_VERDICT_JITTER, PING_VERDICT_FAR))
		TEST_ASSERT(ping_diag_is_yours(verdict), "[verdict] - на стороне игрока")
		TEST_ASSERT(length(ping_diag_hint_text(verdict)), "у [verdict] есть текст подсказки")
	TEST_ASSERT(!ping_diag_is_yours(PING_VERDICT_SERVER), "сервер - не сторона игрока")

	var/list/summary = list("build" = 5161688, "samples" = 120, "base" = 41.6, "rtt_median" = 45, "rtt_p95" = 90, "personal_median" = 3, "spikes_per_min" = 0.4, "loss_per_min" = 0.2, "period" = 600, "freezes" = 1, "stall_mean" = 2, "shared_mean" = 1, "personal_mean" = 4, "loop_lag" = 8, "fps" = 60, "browser_rtt" = 50)
	var/list/context = list("mob_kind" = "ghost", "view" = "21x15", "z_clients" = 30, "near_clients" = 4)
	var/row = ping_diag_csv_row("12:00:00", 1234567, "somekey", summary, PING_VERDICT_OK, context)
	var/list/header = splittext(PING_DIAG_CSV_HEADER, ",")
	var/list/cells = splittext(row, ",")
	TEST_ASSERT_EQUAL(length(cells), length(header), "строка CSV совпадает с заголовком по числу колонок")
	TEST_ASSERT_EQUAL(cells[header.Find("world_time")], "1234567", "world.time без экспоненты")
	TEST_ASSERT_EQUAL(cells[header.Find("build")], "5161688", "сборка без экспоненты")
	TEST_ASSERT_EQUAL(cells[header.Find("base")], "42", "база округлена до ближайшего")
	TEST_ASSERT_EQUAL(cells[header.Find("period_s")], "60", "период в секундах")
	TEST_ASSERT_EQUAL(cells[header.Find("mob_kind")], "ghost", "тип моба")
	TEST_ASSERT_EQUAL(cells[header.Find("view")], "21x15", "обзор")
	TEST_ASSERT_EQUAL(cells[header.Find("near_clients")], "4", "людей рядом")
	TEST_ASSERT_EQUAL(header[length(header)], "old_build", "флаг старой сборки последней колонкой")
	TEST_ASSERT_EQUAL(cells[header.Find("old_build")], "0", "без конфига сборку не судим")
	TEST_ASSERT(!header.Find("chat_lag"), "задержки панели чата в заголовке больше нет")
	TEST_ASSERT_EQUAL(header.Find("chat_rate") + 1, header.Find("chat_messages"), "поток чата перед числом сообщений")
	TEST_ASSERT_EQUAL(cells[header.Find("browser_rtt")], "50", "браузерный RTT")
	TEST_ASSERT_EQUAL(cells[header.Find("chat_rate")], "", "неизвестный поток - пустая ячейка")
	TEST_ASSERT_EQUAL(cells[header.Find("chat_messages")], "", "неизвестное число сообщений - пустая ячейка")
	summary["browser_rtt"] = null
	summary["chat_rate"] = 12.34
	summary["chat_messages"] = 5000
	cells = splittext(ping_diag_csv_row("12:00:00", 1234567, "somekey", summary, PING_VERDICT_FLOOD, context), ",")
	TEST_ASSERT_EQUAL(length(cells), length(header), "с потоком чата колонок столько же")
	TEST_ASSERT_EQUAL(cells[header.Find("browser_rtt")], "", "неизвестный браузерный RTT - пустая ячейка, не 0")
	TEST_ASSERT_EQUAL(cells[header.Find("chat_rate")], "12.3", "поток с точностью до десятой")
	TEST_ASSERT_EQUAL(cells[header.Find("chat_messages")], "5000", "сообщений в чате")
	TEST_ASSERT_EQUAL(cells[header.Find("verdict")], PING_VERDICT_FLOOD, "вердикт")
	summary["build"] = 5141500
	summary["warn_build"] = 5161600
	cells = splittext(ping_diag_csv_row("12:00:00", 1234567, "somekey", summary, PING_VERDICT_OK, context), ",")
	TEST_ASSERT_EQUAL(cells[header.Find("verdict")], PING_VERDICT_OK, "старая сборка не в колонке вердикта")
	TEST_ASSERT_EQUAL(cells[header.Find("old_build")], "1", "а отдельным флагом")

	var/line = ping_diag_event_line(list("time" = "12:00:00", "world_time" = 1234567, "type" = PING_EVENT_HOST_NETWORK, "clients" = 40, "fraction" = 0.9, "extra_ms" = 150, "stall_ms" = 0, "host_retrans_pct" = 2.5, "source" = ""))
	TEST_ASSERT_EQUAL(line, "12:00:00 wt=1234567 тип=host_network клиентов=40 доля=0.9 прибавка=150мс простой=0мс повторы_хоста=2.5% источник=-", "формат строки события")
