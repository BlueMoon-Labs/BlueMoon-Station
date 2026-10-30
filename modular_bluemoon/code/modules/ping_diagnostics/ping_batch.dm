/// Одна рассылка пинга всем клиентам. Живёт PING_DIAG_BATCH_CLOSE_DS, потом раздаёт общую долю.
/datum/ping_batch
	var/id
	var/opened_at
	/// world.time открытия: окно, в котором ищется источник всплеска.
	var/opened_world = 0
	var/closed_at = 0
	/// Датумы, которым пачка ушла и которые ещё не ответили: один ответ на датум.
	var/list/expected = list()
	var/list/diags = list()
	var/list/slots = list()
	var/list/excesses = list()
	var/list/stalls = list()
	/// Сумма лишнего по ответившим после закрытия, мс.
	var/ours_ms = 0
	var/yours_ms = 0
	/// Сколько ожидавших промолчало до закрытия, если молчали почти все, иначе 0.
	var/mass_silent = 0

/datum/ping_batch/New(id, opened_at, opened_world = 0)
	src.id = id
	src.opened_at = opened_at
	src.opened_world = opened_world

/datum/ping_batch/proc/expect(datum/ping_diagnostics/diag)
	expected[diag] = TRUE

/// Ответ в открытой пачке не может быть старше самой пачки: лишнее с простоем обрезается её возрастом.
/datum/ping_batch/proc/add_reply(datum/ping_diagnostics/diag, slot, now = REALTIMEOFDAY)
	if(!expected[diag])
		return FALSE
	expected -= diag
	var/limit = max((now - opened_at) * 100, 0)
	var/stall = min(diag.sample_stall[slot], limit)
	diags += diag
	slots += slot
	excesses += clamp(diag.sample_excess[slot], 0, limit - stall)
	stalls += stall
	return TRUE

/// Кольцо датума выросло, пока пачка была открыта: слоты его ответа переехали.
/datum/ping_batch/proc/remap_slots(datum/ping_diagnostics/diag, list/remap)
	for(var/i in 1 to length(diags))
		if(diags[i] == diag && remap[slots[i]])
			slots[i] = remap[slots[i]]

/datum/ping_batch/proc/close(now = REALTIMEOFDAY)
	closed_at = now
	var/silent = length(expected)
	if(silent >= max(PING_DIAG_SHARED_MIN_CLIENTS, PING_DIAG_SHARED_EVENT_FRACTION * (silent + length(diags))))
		mass_silent = silent
	for(var/datum/ping_diagnostics/diag as anything in expected)
		if(mass_silent)
			diag.note_shared_silence()
		else
			diag.note_personal_silence()
	var/shared = length(excesses) >= PING_DIAG_SHARED_MIN_CLIENTS ? ping_diag_shared_excess(excesses) : null
	for(var/i in 1 to length(diags))
		var/datum/ping_diagnostics/diag = diags[i]
		diag.apply_batch_shared(slots[i], id, shared)
		var/personal = isnull(shared) ? excesses[i] : max(excesses[i] - shared, 0)
		ours_ms += stalls[i] + excesses[i] - personal
		yours_ms += personal
	diags.Cut()
	expected.Cut()
	return shared

/datum/ping_batch/proc/detect_event(cpu, map_cpu = 0)
	if(mass_silent)
		var/total = mass_silent + length(excesses)
		// Молчавшие не ответили за всё время жизни пачки: прибавка у них не меньше её возраста.
		return list(
			"at" = opened_at,
			"clients" = total,
			"fraction" = round(mass_silent / total, 0.01),
			"extra_ms" = round((closed_at - opened_at) * 100, 1),
			"stall_ms" = round(ping_diag_median(stalls), 1),
			"type" = PING_EVENT_MASS_FREEZE,
		)
	var/count = length(excesses)
	if(count < PING_DIAG_SHARED_MIN_CLIENTS)
		return null
	var/list/extras = list()
	var/hit = 0
	for(var/i in 1 to count)
		var/extra = excesses[i] + stalls[i]
		extras += extra
		if(extra >= PING_DIAG_SHARED_EVENT_MS)
			hit++
	if(hit / count < PING_DIAG_SHARED_EVENT_FRACTION)
		return null
	var/stall = ping_diag_median(stalls)
	return list(
		"at" = opened_at,
		"clients" = count,
		"fraction" = round(hit / count, 0.01),
		"extra_ms" = round(ping_diag_median(extras), 1),
		"stall_ms" = round(stall, 1),
		"type" = ping_diag_classify_event(stall, cpu, map_cpu),
	)
