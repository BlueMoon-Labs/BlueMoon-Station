/// Пачка закрывается по сроку, раздаёт общую долю и отдаёт её ускоренным замерам.
/datum/unit_test/ping_diag_subsystem_batches/Run()
	var/list/saved = ping_diag_save_state()
	SSping_diag.open_batches = list()
	var/id = SSping_diag.open_batch()
	var/datum/ping_batch/batch = SSping_diag.open_batches[1]
	TEST_ASSERT_EQUAL(batch.opened_world, world.time, "пачка помнит world.time открытия")
	var/list/diags = list()
	for(var/excess in list(30, 30, 30, 30, 30, 90))
		var/datum/ping_diagnostics/diag = new("tester")
		diag.record_sample(1, 40, 0, 0, 0)
		SSping_diag.find_batch(id).expect(diag)
		SSping_diag.note_reply(diag, diag.record_sample(2, 40 + excess, 0, id, 0), id, batch.opened_at + 5)
		diags += diag
	var/datum/ping_diagnostics/stranger = new("stranger")
	stranger.record_sample(1, 40, 0, 0, 0)
	for(var/i in 1 to 10)
		SSping_diag.note_reply(stranger, stranger.record_sample(2 + i, 500, 0, id, 0), id, batch.opened_at + 5)
	SSping_diag.close_due_batches(batch.opened_at + PING_DIAG_BATCH_CLOSE_DS - 1)
	TEST_ASSERT_EQUAL(length(SSping_diag.open_batches), 1, "до срока пачка открыта")
	SSping_diag.close_due_batches(batch.opened_at + PING_DIAG_BATCH_CLOSE_DS)
	TEST_ASSERT_EQUAL(length(SSping_diag.open_batches), 1, "без тика после открытия очередь ответов не разобрана - пачка открыта")
	batch.opened_world = world.time - 1
	SSping_diag.close_due_batches(batch.opened_at + PING_DIAG_BATCH_CLOSE_DS)
	TEST_ASSERT_EQUAL(length(SSping_diag.open_batches), 0, "по сроку закрыта")
	TEST_ASSERT_EQUAL(SSping_diag.recent_shared, 30, "общая доля ушла ускоренным замерам, ответы без рассылки не в счёт")
	var/datum/ping_diagnostics/last = diags[6]
	TEST_ASSERT_EQUAL(last.sample_personal[2], 60, "личное у выбивающегося")
	ping_diag_restore_state(saved)

/datum/unit_test/ping_diag_subsystem_rows/Run()
	TEST_ASSERT(islist(SSping_diag.round_summary()), "итог раунда собирается без клиентов")
	TEST_ASSERT(islist(SSping_diag.client_rows()), "таблица собирается без клиентов")
	TEST_ASSERT_EQUAL(SSping_diag.rtt_percentile_of(50), 0, "без клиентов процентиль 0")

/// Источник всплеска берётся только из окна пачки.
/datum/unit_test/ping_diag_spike_source/Run()
	var/list/times = list(100, 105, 110, null)
	var/list/names = list("Air", "Lighting", "Mobs", null)
	var/list/usages = list(90, 60, 70, null)
	TEST_ASSERT_EQUAL(ping_diag_heaviest_run(times, names, usages, 104, 112), "Mobs (70% тика)", "самый тяжёлый в окне, а не за всё кольцо")
	TEST_ASSERT_NULL(ping_diag_heaviest_run(times, names, usages, 111, 130), "в окне прогонов нет")
	TEST_ASSERT_EQUAL(ping_diag_pick_source("МК: Air (90% тика)", 106, "Mobs (70% тика)", 104, 112), "МК: Air (90% тика)", "спайк в окне - первым")
	TEST_ASSERT_EQUAL(ping_diag_pick_source("МК: Air (90% тика)", 50, "Mobs (70% тика)", 104, 112), "тяжелее всех: Mobs (70% тика)", "старый спайк не в счёт")
	TEST_ASSERT_EQUAL(ping_diag_pick_source("МК: Air (90% тика)", 50, null, 104, 112), "-", "нет данных - прочерк")
	TEST_ASSERT_EQUAL(ping_diag_source_key("МК: Air (90% тика), Mobs (45% тика) - объясняют лишь ~50мс из 300мс, остальное вне МК"), "МК: Air", "ключ источника без чисел")
	TEST_ASSERT_EQUAL(ping_diag_source_key("DM внутри тика (cpu до 95%, фон неизвестен (мало замеров))"), "DM внутри тика", "вложенные скобки не оставляют хвоста")
	TEST_ASSERT_EQUAL(ping_diag_source_key("блокирующий вызов - верб: Topic, 300мс из 400мс"), "блокирующий вызов", "хвост после тире отрезан")
	TEST_ASSERT_EQUAL(ping_diag_source_key("тяжелее всех: Mobs (70% тика)"), "тяжелее всех: Mobs", "запасной источник")
	TEST_ASSERT_NULL(ping_diag_source_key("-"), "прочерк не считается")

/// Всё, что тесты трогают в живом SSping_diag, и пути логов, чтобы ничего не писать в логи раунда.
/proc/ping_diag_save_state()
	var/list/saved = list(
		"open_batches" = SSping_diag.open_batches,
		"recent_shared" = SSping_diag.recent_shared,
		"mass_batches" = SSping_diag.mass_batches,
		"currentrun" = SSping_diag.currentrun,
		"watched" = SSping_diag.watched,
		"next_probe_at" = SSping_diag.next_probe_at,
		"events" = SSping_diag.events,
		"event_tally" = SSping_diag.event_tally,
		"event_sources" = SSping_diag.event_sources,
		"ours_ms_total" = SSping_diag.ours_ms_total,
		"yours_ms_total" = SSping_diag.yours_ms_total,
		"minute_events" = SSping_diag.minute_events,
		"minute_ours_ms" = SSping_diag.minute_ours_ms,
		"minute_yours_ms" = SSping_diag.minute_yours_ms,
		"host_net" = SSping_diag.host_net,
		"clients_log" = SSping_diag.clients_log,
		"events_log" = SSping_diag.events_log,
		"host_log" = SSping_diag.host_log,
		"samples_log" = SSping_diag.samples_log,
	)
	SSping_diag.open_batches = list()
	SSping_diag.mass_batches = list()
	SSping_diag.events = list()
	SSping_diag.event_tally = list()
	SSping_diag.event_sources = list()
	SSping_diag.clients_log = null
	SSping_diag.events_log = null
	SSping_diag.host_log = null
	SSping_diag.samples_log = null
	return saved

/proc/ping_diag_restore_state(list/saved)
	for(var/name in saved)
		SSping_diag.vars[name] = saved[name]

/// Молчат почти все: одно общее событие, подвисаний у игроков нет, поздний ответ - общая доля.
/datum/unit_test/ping_diag_subsystem_mass_freeze/Run()
	var/list/saved = ping_diag_save_state()
	var/id = SSping_diag.open_batch()
	var/datum/ping_batch/batch = SSping_diag.find_batch(id)
	batch.opened_world = world.time - 1
	var/list/diags = list()
	for(var/i in 1 to 6)
		var/datum/ping_diagnostics/diag = new("tester")
		diag.record_sample(batch.opened_at - 10, 40, 0, 0, 0)
		diag.note_sent(batch.opened_at, id)
		batch.expect(diag)
		diags += diag
	SSping_diag.close_due_batches(batch.opened_at + PING_DIAG_BATCH_CLOSE_DS)
	TEST_ASSERT_EQUAL(length(SSping_diag.events), 1, "массовое молчание - общее событие")
	var/list/event = SSping_diag.events[1]
	TEST_ASSERT_EQUAL(event["type"], PING_EVENT_MASS_FREEZE, "тип события")
	var/datum/ping_diagnostics/late = diags[1]
	var/slot = late.record_sample(batch.opened_at + 50, 120, 0, id, 0)
	SSping_diag.note_reply(late, slot, id)
	TEST_ASSERT_EQUAL(late.sample_personal[slot], 0, "поздний ответ на такую пачку - не личное")
	TEST_ASSERT_EQUAL(late.sample_shared[slot], 80, "а общая доля")
	TEST_ASSERT_EQUAL(length(late.freeze_times), 0, "и не подвисание")
	ping_diag_restore_state(saved)

/datum/unit_test/ping_diag_subsystem_open_cap/Run()
	var/list/saved = ping_diag_save_state()
	for(var/i in 1 to PING_DIAG_MAX_OPEN_BATCHES + 5)
		SSping_diag.open_batch()
	TEST_ASSERT_EQUAL(length(SSping_diag.open_batches), PING_DIAG_MAX_OPEN_BATCHES, "старые пачки закрыты силой")
	ping_diag_restore_state(saved)

/datum/unit_test/ping_diag_subsystem_guards/Run()
	var/list/saved = ping_diag_save_state()
	var/id = SSping_diag.open_batch()
	TEST_ASSERT(SSping_diag.valid_batch(id), "номер открытой пачки")
	TEST_ASSERT(!SSping_diag.valid_batch(id + 1), "номер из будущего")
	TEST_ASSERT(!SSping_diag.valid_batch(0), "ноль - не пачка")
	TEST_ASSERT(!SSping_diag.valid_batch(PING_DIAG_PROBE_BATCH), "метка пробы - не пачка")
	TEST_ASSERT(!SSping_diag.valid_batch(id - 0.5), "дробный номер")
	TEST_ASSERT(!SSping_diag.valid_batch("1"), "текст")
	TEST_ASSERT(!SSping_diag.valid_batch(null), "пусто")

	SSping_diag.next_probe_at = world.time + 100
	TEST_ASSERT(SSping_diag.probe_due(FALSE), "плановый фаер шлёт пробу всегда")
	TEST_ASSERT(!SSping_diag.probe_due(TRUE), "резюмнутый - не чаще шага")
	SSping_diag.next_probe_at = world.time
	TEST_ASSERT(SSping_diag.probe_due(TRUE), "резюмнутый после шага")

	var/datum/stand_in = new
	SSping_diag.currentrun = list(stand_in)
	SSping_diag.watched = list(stand_in)
	SSping_diag.forget_client(null)
	TEST_ASSERT_EQUAL(length(SSping_diag.currentrun), 1, "null ничего не трогает")
	SSping_diag.forget_client(stand_in)
	TEST_ASSERT_EQUAL(length(SSping_diag.currentrun), 0, "ушедший клиент снят с очереди")
	TEST_ASSERT_EQUAL(length(SSping_diag.watched), 0, "и с ускоренного замера")
	ping_diag_restore_state(saved)

/// Без пачки команда рассылки та же, что до диагностики, а проба помечена однозначно.
/datum/unit_test/ping_diag_update_command/Run()
	TEST_ASSERT_EQUAL(ping_update_command(12.5, 3456.25, 0), "command=.update_ping+12.5+3456.25", "без пачки - два числа")
	TEST_ASSERT_EQUAL(ping_update_command(12.5, 3456.25, 7), "command=.update_ping+12.5+3456.25+7", "с пачкой - три")
	TEST_ASSERT_EQUAL(ping_update_command(12.5, 3456.25, PING_DIAG_PROBE_BATCH), "command=.update_ping+12.5+3456.25+-1", "проба")
	TEST_ASSERT(!ping_is_fast_probe(0), "явный ноль - не проба")
	TEST_ASSERT(!ping_is_fast_probe(null), "без третьего аргумента - не проба")
	TEST_ASSERT(!ping_is_fast_probe(7), "пачка - не проба")
	TEST_ASSERT(ping_is_fast_probe(PING_DIAG_PROBE_BATCH), "проба")

/datum/unit_test/ping_diag_event_load/Run()
	var/list/times = list(100, 105, 110, null)
	var/list/values = list(20, 95, 30, null)
	TEST_ASSERT_EQUAL(ping_diag_window_max(times, values, 104, 112), 95, "максимум за окно пачки")
	TEST_ASSERT_NULL(ping_diag_window_max(times, values, 111, 130), "в окне замеров нет")
	TEST_ASSERT_NULL(ping_diag_window_max(null, null, 0, 10), "колец нет")
	TEST_ASSERT_EQUAL(ping_diag_classify_event(0, 10, PING_DIAG_SERVER_LOAD_MAP_CPU), PING_EVENT_SERVER_LOAD, "рассылка карты съела тик")
	TEST_ASSERT_EQUAL(ping_diag_classify_event(0, 10, 5), PING_EVENT_HOST_NETWORK, "сервер свободен")

/datum/unit_test/ping_diag_spike_heaviest/Run()
	TEST_ASSERT_EQUAL(ping_diag_source_key("подсистема МК: Air (40% тика), Mobs (90% тика)", "Mobs"), "подсистема МК: Mobs", "ключ МК - самая тяжёлая подсистема")
	TEST_ASSERT_EQUAL(ping_diag_source_key("подсистема МК: Air (40% тика), Mobs (90% тика)", null), "подсистема МК: Air", "без имени - как раньше")
	TEST_ASSERT_EQUAL(ping_diag_source_key("тяжелее всех: Mobs (70% тика)", "Air"), "тяжелее всех: Mobs", "чужое имя не подменяет источник")
	var/datum/controller/subsystem/tick_spikes/recorder = SStick_spikes
	var/list/saved = list(
		"heavy_time" = recorder.heavy_time,
		"heavy_name" = recorder.heavy_name,
		"heavy_usage" = recorder.heavy_usage,
		"heavy_pos" = recorder.heavy_pos,
		"self_inflicted_until" = recorder.self_inflicted_until,
		"last_classify_detail" = recorder.last_classify_detail,
		"last_classify_heaviest" = recorder.last_classify_heaviest,
	)
	var/size = length(recorder.heavy_time)
	recorder.heavy_time = new /list(size)
	recorder.heavy_name = new /list(size)
	recorder.heavy_usage = new /list(size)
	var/list/names = list("Air", "Mobs", "Lighting")
	var/list/usages = list(40, 90, 60)
	for(var/i in 1 to 3)
		recorder.heavy_time[i] = world.time
		recorder.heavy_name[i] = names[i]
		recorder.heavy_usage[i] = usages[i]
	recorder.heavy_pos = 3
	recorder.self_inflicted_until = 0
	var/spike_class = recorder.classify_spike(world.time, 0)
	var/heaviest = recorder.last_classify_heaviest
	for(var/name in saved)
		recorder.vars[name] = saved[name]
	TEST_ASSERT(findtext(spike_class, "Air"), "класс МК со всеми прогонами: [spike_class]")
	TEST_ASSERT_EQUAL(heaviest, "Mobs", "самая тяжёлая, а не первая")

/datum/unit_test/ping_diag_panel_metrics/Run()
	var/list/payload = list("index" = 3, "metrics" = list("fps" = 60))
	var/list/metrics = ping_payload_take_metrics(payload)
	TEST_ASSERT_EQUAL(metrics["fps"], 60, "метрики отданы")
	TEST_ASSERT(!("metrics" in payload), "pingReply не несёт метрики обратно")
	TEST_ASSERT_EQUAL(payload["index"], 3, "номер пинга на месте")
	TEST_ASSERT_NULL(ping_payload_take_metrics("junk"), "не список - метрик нет")

/datum/unit_test/ping_diag_client_row/Run()
	var/list/quiet = ping_diag_client_row("calm", list("extra_mean" = 5, "ours_fraction" = 0.8), PING_VERDICT_OK)
	TEST_ASSERT_NULL(quiet["ours_fraction"], "лишнего почти нет - доля не показывается")
	var/list/loud = ping_diag_client_row("loud", list("extra_mean" = 50, "ours_fraction" = 0.4), PING_VERDICT_SERVER)
	TEST_ASSERT(abs(loud["ours_fraction"] - 0.4) < 0.001, "доля при заметном лишнем: [loud["ours_fraction"]]")
	TEST_ASSERT_EQUAL(loud["base"], 0, "пустые поля - нули")
	TEST_ASSERT_EQUAL(loud["verdict"], PING_VERDICT_SERVER, "вердикт")
	TEST_ASSERT_NULL(loud["chat_rate"], "поток неизвестен - null, а не 0")
	var/list/flooded = ping_diag_client_row("flooded", list("chat_rate" = 41.37), PING_VERDICT_FLOOD)
	TEST_ASSERT(abs(flooded["chat_rate"] - 41.4) < 0.001, "поток округлён до десятой: [flooded["chat_rate"]]")
