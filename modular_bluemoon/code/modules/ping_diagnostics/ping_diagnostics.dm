/**
 * Разбор пинга одного клиента: кольцо замеров за окно, база, метрики браузера, вердикт.
 *
 * Клиент сюда не ссылается, только его ckey: тесты собирают датум без клиента.
 * Время - дс по REALTIMEOFDAY, задержки - мс.
 */
/datum/ping_diagnostics
	var/ckey
	/// Ёмкость кольца: PING_DIAG_BASE_SAMPLES, у наблюдаемого окном - PING_DIAG_MAX_SAMPLES.
	var/capacity = PING_DIAG_BASE_SAMPLES
	var/list/sample_time
	var/list/sample_rtt
	var/list/sample_stall
	var/list/sample_batch
	/// rtt - stall - база.
	var/list/sample_excess
	/// null, пока общая доля неизвестна: пачка не закрыта или в ней мало ответивших.
	var/list/sample_shared
	var/list/sample_personal
	/// Замер пришёл, пока на клиента сыпался чат: в детекторы сети не идёт, его опоздание - очередь, а не подвисание.
	var/list/sample_flood
	var/next_slot = 1
	var/sample_count = 0
	/// Монотонная очередь минимумов rtt - stall, значения по возрастанию.
	var/list/base_time
	var/list/base_value
	var/list/browser_loop_lag
	var/list/browser_fps
	var/browser_hidden = FALSE
	var/browser_rtt
	var/chat_messages
	/// С какого момента SSchat шлёт этому клиенту сообщения, null - ещё не слал.
	var/chat_since
	/// Поток чата посекундно за PING_DIAG_FLOOD_WINDOW_DS: номер секунды и сколько сообщений в ней ушло.
	var/list/chat_second
	var/list/chat_count
	/// Самая старая пачка без ответа.
	var/awaiting_batch = 0
	var/awaiting_since = 0
	var/in_freeze = FALSE
	/// Текущее ожидание пришлось на молчание у всех: подвисанием игрока не считается.
	var/awaiting_shared = FALSE
	var/list/freeze_times
	/// Ушедшие ускоренные замеры без ответа: ответ без пробы не принимается.
	var/probes_expected = 0
	/// byond_version * 10000 + byond_build.
	var/byond_build_code = 0
	var/list/verdicts
	var/list/summary
	/// С какого момента главный вердикт на стороне игрока, 0 - не на его.
	var/yours_since = 0
	/// Сколько открытых окон смотрят на этот датум: им нужен ускоренный замер.
	var/watchers = 0
	/// До какого времени сырые замеры уже ушли в ping-samples.
	var/raw_dumped_until = 0

/datum/ping_diagnostics/New(ckey)
	src.ckey = ckey
	sample_time = new /list(capacity)
	sample_rtt = new /list(capacity)
	sample_stall = new /list(capacity)
	sample_batch = new /list(capacity)
	sample_excess = new /list(capacity)
	sample_shared = new /list(capacity)
	sample_personal = new /list(capacity)
	sample_flood = new /list(capacity)
	base_time = list()
	base_value = list()
	browser_loop_lag = list()
	browser_fps = list()
	freeze_times = list()
	verdicts = list(PING_VERDICT_COLLECTING)
	summary = list()

/**
 * Замер DS-пути. Пачка 0 - ускоренный замер: общую долю берёт из последней закрытой пачки.
 * Числа приходят командной строкой от клиента: нечисло отбрасывается (null), остальное зажимается.
 */
/datum/ping_diagnostics/proc/record_sample(now, rtt, stall, batch, shared_hint)
	if(!isnum(rtt) || rtt != rtt)
		return null
	rtt = clamp(rtt, 0, PING_DIAG_MAX_RTT_MS)
	stall = (isnum(stall) && stall == stall) ? clamp(stall, 0, rtt) : 0
	batch = batch || 0
	var/network = rtt - stall
	push_base(now, network)
	var/slot = next_slot
	sample_time[slot] = now
	sample_rtt[slot] = rtt
	sample_stall[slot] = stall
	sample_batch[slot] = batch
	sample_flood[slot] = flooded(now)
	sample_excess[slot] = network - base_value[1]
	if(batch || isnull(shared_hint))
		sample_shared[slot] = null
		sample_personal[slot] = sample_excess[slot]
	else
		apply_shared(slot, shared_hint)
	next_slot = slot % capacity + 1
	sample_count = min(sample_count + 1, capacity)
	note_reply(now, batch, stall)
	return slot

/datum/ping_diagnostics/proc/expect_probe()
	probes_expected = min(probes_expected + 1, PING_DIAG_MAX_PROBES_IN_FLIGHT)

/// Ответ на ускоренный замер: принимается, только если проба ушла и ещё не отвечена.
/datum/ping_diagnostics/proc/record_probe(now, rtt, stall, shared_hint)
	if(probes_expected <= 0)
		return null
	probes_expected--
	return record_sample(now, rtt, stall, 0, shared_hint)

/datum/ping_diagnostics/proc/push_base(now, value)
	while(length(base_value) && base_value[length(base_value)] >= value)
		base_value.len--
		base_time.len--
	base_value += value
	base_time += now
	while(base_time[1] < now - PING_DIAG_WINDOW_DS || length(base_value) > capacity)
		base_time.Cut(1, 2)
		base_value.Cut(1, 2)

/datum/ping_diagnostics/proc/apply_shared(slot, shared)
	sample_shared[slot] = shared
	sample_personal[slot] = max(sample_excess[slot] - shared, 0)

/// Слот мог уйти под новый замер, пока пачка была открыта: тогда номер пачки не совпадёт.
/datum/ping_diagnostics/proc/apply_batch_shared(slot, batch, shared)
	if(sample_batch[slot] != batch)
		return
	if(isnull(shared))
		sample_shared[slot] = null
		sample_personal[slot] = sample_excess[slot]
		return
	apply_shared(slot, shared)

/**
 * Окно диагностики хочет ускоренный замер: кольцо растёт, замеры остаются по порядку.
 * Возвращает список старый слот -> новый для открытых пачек или null, если расти некуда.
 */
/datum/ping_diagnostics/proc/grow_ring(new_capacity)
	if(new_capacity <= capacity)
		return null
	var/list/order = ordered_slots()
	var/static/list/ring_vars = list("sample_time", "sample_rtt", "sample_stall", "sample_batch", "sample_excess", "sample_shared", "sample_personal", "sample_flood")
	for(var/name in ring_vars)
		var/list/old = vars[name]
		var/list/grown = new /list(new_capacity)
		for(var/i in 1 to length(order))
			grown[i] = old[order[i]]
		vars[name] = grown
	var/list/remap = new /list(capacity)
	for(var/i in 1 to length(order))
		remap[order[i]] = i
	capacity = new_capacity
	next_slot = length(order) % capacity + 1
	return remap

/datum/ping_diagnostics/proc/note_sent(now, batch)
	check_overdue(now)
	if(!awaiting_batch)
		awaiting_batch = batch
		awaiting_since = now

/// Опоздание, которое покрывает простой сервера (stall, мс), подвисанием игрока не считается.
/datum/ping_diagnostics/proc/note_reply(now, batch, stall)
	if(!batch || !awaiting_batch)
		return
	if(now - awaiting_since - (stall || 0) / 100 <= PING_DIAG_BATCH_CLOSE_DS || flooded(now))
		drop_episode_freeze()
	else
		check_overdue(now)
	awaiting_batch = 0
	in_freeze = FALSE
	awaiting_shared = FALSE

/datum/ping_diagnostics/proc/drop_episode_freeze()
	if(in_freeze && length(freeze_times) && freeze_times[length(freeze_times)] == awaiting_since)
		freeze_times.len--
	in_freeze = FALSE

/datum/ping_diagnostics/proc/check_overdue(now)
	if(awaiting_batch && !in_freeze && !awaiting_shared && now - awaiting_since > PING_DIAG_BATCH_CLOSE_DS && !flooded(now))
		in_freeze = TRUE
		freeze_times += awaiting_since

/// Пачка закрылась при молчании почти у всех: текущее ожидание - беда сервера или канала.
/datum/ping_diagnostics/proc/note_shared_silence()
	if(!awaiting_batch)
		return
	drop_episode_freeze()
	awaiting_shared = TRUE

/// Остальные ответили, а этот молчит дальше: ожидание снова его.
/datum/ping_diagnostics/proc/note_personal_silence()
	awaiting_shared = FALSE

/datum/ping_diagnostics/proc/record_browser(loop_lag, fps, hidden, rtt, messages)
	if(isnum(loop_lag))
		browser_loop_lag += clamp(loop_lag, 0, 60000)
		if(length(browser_loop_lag) > PING_DIAG_BROWSER_HISTORY)
			browser_loop_lag.Cut(1, 2)
	if(isnum(fps))
		browser_fps += clamp(fps, 0, 1000)
		if(length(browser_fps) > PING_DIAG_BROWSER_HISTORY)
			browser_fps.Cut(1, 2)
	browser_hidden = !!hidden
	browser_rtt = isnum(rtt) ? clamp(rtt, 0, 60000) : null
	chat_messages = (isnum(messages) && messages == messages) ? clamp(round(messages, 1), 0, PING_DIAG_CHAT_MAX_MESSAGES) : null

/// SSchat отправил клиенту пачку из count сообщений.
/datum/ping_diagnostics/proc/note_chat(count, now)
	if(!isnum(count) || count <= 0)
		return
	if(isnull(chat_since))
		chat_since = now
		chat_second = new /list(PING_DIAG_FLOOD_BUCKETS)
		chat_count = new /list(PING_DIAG_FLOOD_BUCKETS)
	var/second = FLOOR(now / (1 SECONDS), 1)
	var/slot = second % PING_DIAG_FLOOD_BUCKETS + 1
	if(chat_second[slot] != second)
		chat_second[slot] = second
		chat_count[slot] = 0
	chat_count[slot] += count

/// Сообщений в секунду за последние PING_DIAG_FLOOD_WINDOW_DS, null - SSchat этому клиенту ещё ничего не слал.
/datum/ping_diagnostics/proc/chat_rate(now)
	if(isnull(chat_since))
		return null
	var/second = FLOOR(now / (1 SECONDS), 1)
	var/total = 0
	for(var/slot in 1 to PING_DIAG_FLOOD_BUCKETS)
		var/bucket = chat_second[slot]
		if(!isnull(bucket) && bucket > second - PING_DIAG_FLOOD_BUCKETS && bucket <= second)
			total += chat_count[slot]
	return total / (clamp(now - chat_since, PING_DIAG_FLOOD_MIN_SPAN_DS, PING_DIAG_FLOOD_WINDOW_DS) / (1 SECONDS))

/datum/ping_diagnostics/proc/flooded(now)
	return chat_rate(now) >= PING_DIAG_FLOOD_RATE

/// Все занятые слоты от старого к новому.
/datum/ping_diagnostics/proc/ordered_slots()
	. = list()
	if(!sample_count)
		return
	var/start = sample_count < capacity ? 1 : next_slot
	for(var/i in 0 to sample_count - 1)
		. += (start + i - 1) % capacity + 1

/datum/ping_diagnostics/proc/window_slots(now)
	. = list()
	for(var/slot in ordered_slots())
		if(sample_time[slot] >= now - PING_DIAG_WINDOW_DS)
			. += slot

/datum/ping_diagnostics/proc/recompute(now, server_base, warn_build)
	var/list/rtts = list()
	var/stall_total = 0
	var/shared_total = 0
	var/personal_total = 0
	var/shared_known = 0
	var/network_min = INFINITY
	var/list/net_personal = list()
	var/list/net_times = list()
	var/recent_since = now - PING_DIAG_FLOOD_WINDOW_DS
	var/list/recent_rtts = list()
	var/list/recent_personal = list()
	var/window_start = now - PING_DIAG_WINDOW_DS
	var/first_time
	var/last_time
	var/list/ring_time = sample_time
	var/list/ring_rtt = sample_rtt
	var/list/ring_stall = sample_stall
	var/list/ring_personal = sample_personal
	// Тот же обход, что window_slots(), без промежуточных списков слотов.
	var/start = sample_count < capacity ? 1 : next_slot
	for(var/i in 0 to sample_count - 1)
		var/slot = (start + i - 1) % capacity + 1
		var/time = ring_time[slot]
		if(time < window_start)
			continue
		var/rtt = ring_rtt[slot]
		var/stall = ring_stall[slot]
		var/personal = ring_personal[slot]
		var/shared = 0
		if(!isnull(sample_shared[slot]))
			shared = sample_excess[slot] - personal
			shared_known++
		rtts += rtt
		if(isnull(first_time))
			first_time = time
		last_time = time
		stall_total += stall
		shared_total += shared
		personal_total += personal
		network_min = min(network_min, rtt - stall)
		if(!sample_flood[slot])
			net_personal += personal
			net_times += time
		if(time >= recent_since)
			recent_rtts += rtt
			recent_personal += personal
	while(length(freeze_times) && freeze_times[1] < now - PING_DIAG_WINDOW_DS)
		freeze_times.Cut(1, 2)
	var/count = length(rtts)
	if(!count)
		summary = list("samples" = 0)
		verdicts = list(PING_VERDICT_COLLECTING)
		update_yours_since(now)
		return verdicts
	var/rtt_now = rtts[count]
	// Каждый список проходит выбор один раз, все его ранги берутся оттуда же.
	var/list/rtt_ranks = ping_diag_percentiles(rtts, list(50, 95))
	var/personal_median = ping_diag_percentiles(net_personal.Copy(), list(50))[1]
	var/list/spikes = ping_diag_find_spikes(net_personal, personal_median)
	var/list/spike_times = list()
	for(var/index in spikes)
		spike_times += net_times[index]
	var/recent_freezes = awaiting_batch && !awaiting_shared && now - awaiting_since > PING_DIAG_BATCH_CLOSE_DS
	for(var/freeze_time in freeze_times)
		if(freeze_time >= recent_since)
			recent_freezes++
	var/list/episodes = ping_diag_collapse_bursts(spike_times, PING_DIAG_BURST_GAP_DS)
	var/window_minutes = max((last_time - first_time) / (1 MINUTES), 1)
	var/extra_total = stall_total + shared_total + personal_total
	summary = list(
		"samples" = count,
		"rtt_now" = rtt_now,
		"rtt_median" = rtt_ranks[1],
		"rtt_min" = min(rtts),
		"rtt_p95" = rtt_ranks[2],
		"base" = max(network_min, 0),
		"stall_mean" = stall_total / count,
		"shared_mean" = shared_total / count,
		"personal_mean" = personal_total / count,
		"extra_mean" = extra_total / count,
		"ours_fraction" = extra_total ? (stall_total + shared_total) / extra_total : 0,
		"shared_known" = shared_known / count,
		"personal_median" = personal_median,
		"recent_personal_median" = ping_diag_percentiles(recent_personal, list(50))[1],
		"recent_rtt_p95" = ping_diag_percentiles(recent_rtts, list(95))[1],
		"recent_freezes" = recent_freezes,
		"spikes_per_min" = length(episodes) / window_minutes,
		"loss_per_min" = ping_diag_count_loss_like(net_personal, spikes) / window_minutes,
		"period" = ping_diag_spike_period(episodes),
		"freezes" = length(freeze_times),
		"loop_lag" = (browser_hidden || !length(browser_loop_lag)) ? null : ping_diag_median(browser_loop_lag),
		"fps" = (browser_hidden || !length(browser_fps)) ? null : ping_diag_median(browser_fps),
		"hidden" = browser_hidden,
		"browser_rtt" = browser_rtt,
		"chat_rate" = chat_rate(now),
		"chat_messages" = chat_messages,
		"server_base" = server_base,
		"build" = byond_build_code,
		"warn_build" = warn_build,
	)
	verdicts = ping_diag_pick_verdicts(summary)
	update_yours_since(now)
	return verdicts

/datum/ping_diagnostics/proc/update_yours_since(now)
	if(!ping_diag_is_yours(verdicts[1]))
		yours_since = 0
	else if(!yours_since)
		yours_since = now

/**
 * Решение без побочных эффектов: отметку "уже подсказали" ставит вызывающий.
 * Без общей доли сервер не отличить от сети игрока: при малом онлайне молчим.
 */
/datum/ping_diagnostics/proc/hint_due(now, hint_disabled, already_hinted)
	if(hint_disabled || already_hinted || !yours_since || now - yours_since < PING_DIAG_HINT_HOLD_DS)
		return FALSE
	return summary["shared_known"] >= PING_DIAG_SHARED_KNOWN_MIN

/// Сырые замеры новее after для пересчёта порогов офлайн: "dt/rtt/stall[p][f]", p - ускоренный замер, f - пришёл под потоком чата.
/datum/ping_diagnostics/proc/raw_since(now, after)
	var/list/parts = list()
	var/first
	var/previous
	// dt - разность округлённых смещений от t0: сумма dt не уплывает от реального времени.
	var/previous_offset = 0
	for(var/slot in window_slots(now))
		var/time = sample_time[slot]
		if(time <= after)
			continue
		if(isnull(first))
			first = time
		var/offset = round(time - first, 1)
		parts += "[offset - previous_offset]/[round(sample_rtt[slot], 1)]/[round(sample_stall[slot], 1)][sample_batch[slot] ? "" : "p"][sample_flood[slot] ? "f" : ""]"
		previous_offset = offset
		previous = time
	return list("t0" = first, "last" = previous, "text" = parts.Join(" "))

/// Точки графика за окно. В корзине прореживания берётся замер с наибольшим RTT, чтобы спайки не терялись.
/datum/ping_diagnostics/proc/graph_points(now)
	. = list()
	var/list/slots = window_slots(now)
	var/count = length(slots)
	if(!count)
		return
	var/spike_floor = max(PING_DIAG_SPIKE_MIN_MS, PING_DIAG_SPIKE_MEDIAN_FACTOR * (summary["personal_median"] || 0))
	var/bucket = max(1, CEILING(count / PING_DIAG_GRAPH_POINTS, 1))
	for(var/start in 1 to count step bucket)
		var/best = slots[start]
		for(var/i in start to min(start + bucket - 1, count))
			if(sample_rtt[slots[i]] > sample_rtt[best])
				best = slots[i]
		. += list(list(
			"t" = round((sample_time[best] - now) / 10, 0.1),
			"rtt" = round(sample_rtt[best], 1),
			"stall" = round(sample_stall[best], 1),
			"shared" = round(isnull(sample_shared[best]) ? 0 : sample_excess[best] - sample_personal[best], 1),
			"spike" = sample_personal[best] >= spike_floor,
		))
