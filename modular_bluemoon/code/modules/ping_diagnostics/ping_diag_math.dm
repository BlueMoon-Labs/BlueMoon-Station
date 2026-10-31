/proc/ping_diag_median(list/values)
	return ping_diag_percentile(values, 50)

/// Перцентиль по ближайшему рангу. Выбирает по копии, у пустого списка 0.
/proc/ping_diag_percentile(list/values, percent)
	if(!length(values))
		return 0
	var/list/picked = ping_diag_percentiles(values.Copy(), list(percent))
	return picked[1]

/**
 * Несколько перцентилей по ближайшему рангу за один выбор, percents - по возрастанию.
 * Переставляет values на месте: снаружи передавать копию, если порядок нужен. У пустого списка нули.
 * Быстрый выбор без вызова процедуры на сравнение: sortTim с call() на каждое сравнение в разы дороже.
 */
/proc/ping_diag_percentiles(list/values, list/percents)
	. = list()
	var/count = length(values)
	var/low = 1
	for(var/percent in percents)
		if(!count)
			. += 0
			continue
		var/rank = clamp(CEILING(count * percent / 100, 1), 1, count)
		var/left = low
		var/right = count
		while(right - left > PING_DIAG_SELECT_INSERTION_MAX)
			var/first = values[left]
			var/middle = values[(left + right) >> 1]
			var/last = values[right]
			var/pivot = first < middle ? (middle < last ? middle : (first < last ? last : first)) : (first < last ? first : (middle < last ? last : middle))
			var/scan_up = left
			var/scan_down = right
			while(scan_up <= scan_down)
				while(values[scan_up] < pivot)
					scan_up++
				while(values[scan_down] > pivot)
					scan_down--
				if(scan_up <= scan_down)
					values.Swap(scan_up, scan_down)
					scan_up++
					scan_down--
			if(rank <= scan_down)
				right = scan_down
			else if(rank >= scan_up)
				left = scan_up
			else
				// Между scan_down и scan_up только равные опорному: ранг уже на месте.
				left = rank
				right = rank
		for(var/index in left + 1 to right)
			var/value = values[index]
			var/slot = index - 1
			while(slot >= left && values[slot] > value)
				values[slot + 1] = values[slot]
				slot--
			values[slot + 1] = value
		. += values[rank]
		// Правее ранга только не меньшие: следующий ранг ищется там же.
		low = rank

/// Индексы спайков личной доли: выше и абсолютного пола, и кратного медианы. Медиану можно передать готовой.
/proc/ping_diag_find_spikes(list/personal, median)
	. = list()
	if(isnull(median))
		median = ping_diag_median(personal)
	var/threshold = max(PING_DIAG_SPIKE_MIN_MS, PING_DIAG_SPIKE_MEDIAN_FACTOR * median)
	for(var/i in 1 to length(personal))
		if(personal[i] >= threshold)
			. += i

/// Сколько спайков похожи на повтор потерянного TCP-сегмента: высокие и одиночные.
/proc/ping_diag_count_loss_like(list/personal, list/spike_indices)
	. = 0
	var/count = length(personal)
	for(var/index in spike_indices)
		if(personal[index] < PING_DIAG_LOSS_MIN_MS)
			continue
		if(index > 1 && spike_indices.Find(index - 1))
			continue
		if(index < count && spike_indices.Find(index + 1))
			continue
		.++

/proc/ping_diag_collapse_bursts(list/times, gap)
	. = list()
	var/last
	for(var/time in times)
		if(isnull(last) || time - last > gap)
			. += time
		last = time

/// Период повторяющихся эпизодов в дс или 0, если ритма нет.
/proc/ping_diag_spike_period(list/times)
	var/count = length(times)
	if(count < PING_DIAG_PERIODIC_MIN_SPIKES)
		return 0
	var/list/intervals = list()
	var/mean = 0
	for(var/i in 2 to count)
		var/interval = times[i] - times[i - 1]
		intervals += interval
		mean += interval
	mean /= length(intervals)
	if(mean <= 0)
		return 0
	var/variance = 0
	for(var/interval in intervals)
		variance += (interval - mean) ** 2
	variance /= length(intervals)
	if(sqrt(variance) / mean > PING_DIAG_PERIODIC_MAX_CV)
		return 0
	return ping_diag_median(intervals)

/proc/ping_diag_shared_excess(list/excesses)
	if(length(excesses) < PING_DIAG_SHARED_MIN_CLIENTS)
		return 0
	return ping_diag_median(excesses)

/**
 * Чей общий всплеск: простой сервера, нагрузка внутри тика или канал хоста.
 * Нагрузка - cpu, рассылка карты или самый тяжёлый прогон подсистемы в окне пачки (heavy_run, % тика).
 */
/proc/ping_diag_classify_event(stall_ms, cpu, map_cpu = 0, heavy_run = 0)
	if(stall_ms >= PING_DIAG_SHARED_EVENT_MS / 2)
		return PING_EVENT_SERVER_STALL
	if(cpu >= PING_DIAG_SERVER_LOAD_CPU || map_cpu >= PING_DIAG_SERVER_LOAD_MAP_CPU || heavy_run >= PING_DIAG_SERVER_LOAD_RUN)
		return PING_EVENT_SERVER_LOAD
	return PING_EVENT_HOST_NETWORK

/**
 * Вердикты по сводке окна, по приоритету: первый - главный, остальные дают советы.
 * Ключи stats - как в /datum/ping_diagnostics/proc/recompute().
 */
/proc/ping_diag_pick_verdicts(list/stats)
	if(stats["samples"] < PING_DIAG_MIN_SAMPLES)
		return list(PING_VERDICT_COLLECTING)
	. = list()
	if(stats["extra_mean"] >= PING_DIAG_NOTICEABLE_EXTRA_MS && stats["ours_fraction"] > 0.5)
		. += PING_VERDICT_SERVER
	// DS-пинг стоит в той же очереди, что и чат: подвисания и колебания при потоке - не сеть игрока. Следы очереди - за те же 30 с, что и поток.
	var/queued = stats["recent_personal_median"] >= PING_DIAG_JITTER_MS || stats["recent_freezes"] >= 1 || stats["recent_rtt_p95"] - stats["base"] >= PING_DIAG_FLOOD_P95_EXTRA_MS
	var/flood = stats["chat_rate"] >= PING_DIAG_FLOOD_RATE && queued
	if(flood)
		. += PING_VERDICT_FLOOD
	if(!flood && stats["freezes"] >= PING_DIAG_FREEZE_MIN)
		. += PING_VERDICT_FREEZE
	if(!stats["hidden"] && (stats["loop_lag"] >= PING_DIAG_PC_LOOP_LAG_MS || (stats["fps"] && stats["fps"] < PING_DIAG_PC_MIN_FPS)))
		. += PING_VERDICT_PC
	if(!flood && stats["period"])
		. += PING_VERDICT_PERIODIC
	if(!flood && stats["loss_per_min"] >= PING_DIAG_LOSS_PER_MIN)
		. += PING_VERDICT_LOSS
	if(!flood && stats["personal_median"] > PING_DIAG_JITTER_MS && !(PING_VERDICT_PERIODIC in .) && !(PING_VERDICT_LOSS in .))
		. += PING_VERDICT_JITTER
	var/base = stats["base"]
	var/server_base = stats["server_base"]
	if(base > PING_DIAG_FAR_BASE_MS || (server_base && base > PING_DIAG_FAR_MIN_MS && base > server_base * 2))
		. += PING_VERDICT_FAR
	if(!length(.))
		. += PING_VERDICT_OK

/// Сборка клиента старше рекомендуемой в конфиге: совет обновиться, на пинг не влияет и в вердикт не идёт.
/proc/ping_diag_old_build(list/summary)
	return !!(summary["warn_build"] && summary["build"] && summary["build"] < summary["warn_build"])

/proc/ping_diag_is_yours(verdict)
	var/static/list/yours = list(PING_VERDICT_FLOOD, PING_VERDICT_FREEZE, PING_VERDICT_PC, PING_VERDICT_PERIODIC, PING_VERDICT_LOSS, PING_VERDICT_JITTER, PING_VERDICT_FAR)
	return verdict in yours

/proc/ping_diag_hint_text(verdict)
	switch(verdict)
		if(PING_VERDICT_FLOOD)
			return "на вас сыплется очень много сообщений, и клиент не успевает их обрабатывать - отсюда задержка"
		if(PING_VERDICT_FREEZE)
			return "соединение с сервером время от времени подвисает на несколько секунд"
		if(PING_VERDICT_PC)
			return "компьютер не успевает обрабатывать игру, и задержка растёт уже у вас"
		if(PING_VERDICT_PERIODIC)
			return "пинг скачет через ровные промежутки - так обычно мешает фоновая программа или поиск сетей Wi-Fi"
		if(PING_VERDICT_LOSS)
			return "по дороге до сервера теряются пакеты"
		if(PING_VERDICT_JITTER)
			return "сеть нестабильна, частая причина - Wi-Fi"
		if(PING_VERDICT_FAR)
			return "до сервера далеко или трафик идёт кружным путём, например через VPN"
	return ""

/proc/ping_diag_csv_row(time_text, world_time, ckey, list/summary, verdict, list/context)
	var/list/cells = list(
		time_text,
		num2text(world_time, 10),
		ckey,
		num2text(summary["build"] || 0, 8),
		context["mob_kind"],
		replacetext("[context["view"]]", ",", "x"),
		context["z_clients"] || 0,
		context["near_clients"] || 0,
		summary["samples"] || 0,
		round(summary["base"] || 0, 1),
		round(summary["rtt_median"] || 0, 1),
		round(summary["rtt_p95"] || 0, 1),
		round(summary["personal_median"] || 0, 1),
		round(summary["spikes_per_min"] || 0, 0.01),
		round(summary["loss_per_min"] || 0, 0.01),
		round((summary["period"] || 0) / 10, 1),
		summary["freezes"] || 0,
		round(summary["stall_mean"] || 0, 0.1),
		round(summary["shared_mean"] || 0, 0.1),
		round(summary["personal_mean"] || 0, 0.1),
		isnull(summary["loop_lag"]) ? "" : round(summary["loop_lag"], 1),
		isnull(summary["fps"]) ? "" : round(summary["fps"], 1),
		isnull(summary["browser_rtt"]) ? "" : round(summary["browser_rtt"], 1),
		isnull(summary["chat_rate"]) ? "" : round(summary["chat_rate"], 0.1),
		isnull(summary["chat_messages"]) ? "" : summary["chat_messages"],
		verdict,
		ping_diag_old_build(summary) ? 1 : 0,
	)
	return cells.Join(",")

/// Микросекунды в ячейку CSV: миллисекунды до десятой, без экспоненты.
/proc/ping_diag_us_to_ms(us)
	return num2text(round((us || 0) / 1000, 0.1), 7)

/proc/ping_diag_event_line(list/event)
	return "[event["time"]] wt=[num2text(event["world_time"] || 0, 10)] тип=[event["type"]] клиентов=[event["clients"]] доля=[event["fraction"]] прибавка=[event["extra_ms"]]мс простой=[event["stall_ms"]]мс повторы_хоста=[event["host_retrans_pct"] || 0]% источник=[event["source"] || "-"]"

/// Самый тяжёлый прогон из кольца SStick_spikes в окне [from_world, to_world] или null.
/proc/ping_diag_heaviest_run(list/times, list/names, list/usages, from_world, to_world)
	var/best = 0
	for(var/i in 1 to length(times))
		var/run_time = times[i]
		if(isnull(run_time) || run_time < from_world || run_time > to_world)
			continue
		if(!best || usages[i] > usages[best])
			best = i
	return best ? "[names[best]] ([round(usages[best], 0.1)]% тика)" : null

/// Источник всплеска: тик-спайк в окне пачки, иначе самый тяжёлый прогон в нём же, иначе "-".
/proc/ping_diag_pick_source(spike_class, spike_world, heaviest_run, from_world, to_world)
	if(spike_class && spike_world >= from_world && spike_world <= to_world)
		return spike_class
	if(heaviest_run)
		return "тяжелее всех: [heaviest_run]"
	return "-"

/**
 * Ключ для подсчёта источников в итоге раунда: текст до первой скобки или " - ", дальше идут числа.
 * У класса МК прогонов несколько, ключом идёт самая тяжёлая подсистема mc_heaviest, а не первая по времени.
 */
/proc/ping_diag_source_key(source, mc_heaviest)
	if(!length(source) || source == "-")
		return null
	if(mc_heaviest)
		var/colon = findtext(source, ": ")
		if(colon && findtext(source, "[mc_heaviest] (", colon))
			return "[copytext(source, 1, colon)]: [mc_heaviest]"
	var/static/regex/tail = regex(@"\(| - ")
	var/cut = tail.Find(source)
	if(cut)
		source = copytext(source, 1, cut)
	return trim(source) || null

/proc/ping_diag_mob_kind(mob/player_mob)
	if(isnewplayer(player_mob))
		return "lobby"
	if(isobserver(player_mob))
		return "ghost"
	if(isliving(player_mob))
		return "living"
	return "other"

/// Максимум values в окне [from_world, to_world] по меткам times или null, если замеров в окне нет.
/proc/ping_diag_window_max(list/times, list/values, from_world, to_world)
	for(var/i in 1 to length(times))
		var/at = times[i]
		if(isnull(at) || at < from_world || at > to_world || !isnum(values[i]))
			continue
		. = isnull(.) ? values[i] : max(., values[i])

/// Строка таблицы игроков. Долю нашего не отдаём, пока лишнего почти нет: проценты от шума врут.
/proc/ping_diag_client_row(ckey, list/summary, verdict)
	return list(
		"ckey" = ckey,
		"base" = round(summary["base"] || 0, 1),
		"rtt_median" = round(summary["rtt_median"] || 0, 1),
		"rtt_p95" = round(summary["rtt_p95"] || 0, 1),
		"personal_median" = round(summary["personal_median"] || 0, 1),
		"spikes_per_min" = round(summary["spikes_per_min"] || 0, 0.1),
		"freezes" = summary["freezes"] || 0,
		"chat_rate" = isnull(summary["chat_rate"]) ? null : round(summary["chat_rate"], 0.1),
		"ours_fraction" = summary["extra_mean"] >= PING_DIAG_NOTICEABLE_EXTRA_MS ? round(summary["ours_fraction"] || 0, 0.01) : null,
		"verdict" = verdict,
		"old_build" = ping_diag_old_build(summary),
	)
