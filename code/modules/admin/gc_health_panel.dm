// GC Health Panel — live admin dashboard for the garbage collection subsystem.
// Provides queue depth trends, per-type failure drilldown, and suspension management.

/proc/gc_health_event_text(level, hint)
	switch (level)
		if (GC_QUEUE_SOFTCHECK)
			if (hint == QDEL_HINT_SLOWDESTROY)
				return "Softcheck miss (expected)"
			if (hint == QDEL_HINT_SOFTFAIL_ALERT)
				return "Softcheck miss (alert)"
			return "Softcheck miss"
		if (GC_QUEUE_WARNFAIL)
			return "Warnfail leak"
		if (GC_QUEUE_HARDDELETE)
			return "Hard delete"
	return "Unknown"

/proc/gc_health_hint_text(hint)
	switch (hint)
		if (QDEL_HINT_SOFTFAIL_ALERT)
			return "SOFTFAIL_ALERT"
		if (QDEL_HINT_SLOWDESTROY)
			return "SLOWDESTROY"
		if (QDEL_HINT_HARDDEL)
			return "HARDDEL"
		if (QDEL_HINT_HARDDEL_NOW)
			return "HARDDEL_NOW"
		if (QDEL_HINT_IWILLGC)
			return "IWILLGC"
		if (QDEL_HINT_LETMELIVE)
			return "LETMELIVE"
		if (QDEL_HINT_QUEUE)
			return "QUEUE"
		if (QDEL_HINT_QUEUE_THEN_HARDDEL)
			return "QUEUE_THEN_HARDDEL"
		#ifdef REFERENCE_TRACKING
		if (QDEL_HINT_FINDREFERENCE)
			return "FINDREFERENCE"
		if (QDEL_HINT_IFFAIL_FINDREFERENCE)
			return "IFFAIL_FINDREFERENCE"
		#endif
	if (isnull(hint))
		return "-"
	return "[hint]"

/client/proc/cmd_gc_health_panel()
	set category = "Debug.1) Logs"
	set name = "GC Health Panel"
	set desc = "Live dashboard for the garbage collection subsystem."

	if (!check_rights(R_DEBUG))
		return

	var/list/output = list()
	output += "<b>Панель здоровья GC</b>"
	output += " — <A href='byond://?src=[REF(holder)];[HrefToken()];gc_health_refresh=1'>Обновить</A>"
	var/notify_label = src.gc_leak_notify ? "<b style='color:lime'>Уведомления: ВКЛ</b>" : "<span style='color:gray'>Уведомления: ВЫКЛ</span>"
	output += " — <A href='byond://?src=[REF(holder)];[HrefToken()];gc_toggle_notify=1'>[notify_label]</A>"
	output += " — <A href='byond://?src=[REF(holder)];[HrefToken()];gc_health_help=1'>Справочник</A>"
	output += "<br><br>"

	// --- Summary stats ---
	var/total_rate = SSgarbage.totaldels + SSgarbage.totalgcs
	var/gc_pct = total_rate ? "[round(SSgarbage.totalgcs / total_rate * 100, 0.1)]%" : "n/a"
	output += "<div style='font-family:monospace; background:#111; padding:8px; border:1px solid #333'>"
	output += "<b>Итого:</b> Del=[SSgarbage.totaldels] GC=[SSgarbage.totalgcs] GC%=[gc_pct]<br>"
	output += "<b>Этот тик:</b> Del=[SSgarbage.delslasttick] GC=[SSgarbage.gcedlasttick]<br>"
	output += "<b>Подтверждённые утечки (ср):</b> [round(SSgarbage.leak_rate_avg, 0.01)]/мин"
	output += " | <b>Hard-del (ср):</b> [round(SSgarbage.harddel_ms_avg, 0.1)]мс<br>"
	output += "<b>Hard-del режим:</b> [SSgarbage.GetHardDeleteModeText()]"
	output += " | <b>Scheduling:</b> [SSgarbage.last_hd_background_scheduling ? "background" : "foreground"]"
	output += " | <b>Yield ratio:</b> [round(SSgarbage.last_hd_yield_ratio * 100, 0.1)]%"
	output += " | <b>MC-clipped:</b> [SSgarbage.last_hd_mc_clipped ? "<span style='color:#ff6666'>YES</span>" : "no"]<br>"
	output += "<b>Hard-del бюджет:</b> [round(SSgarbage.last_hd_budget_ms, 0.1)]мс"
	output += " | <b>Hard-del cap:</b> [SSgarbage.last_hd_cap]"
	output += " | <b>Hard-del pass:</b> [round(SSgarbage.last_hd_pass_ms, 0.1)]мс"
	output += " | <b>Overflow:</b> [SSgarbage.last_hd_overflow_mode ? "ON" : "off"]<br>"
	if (SSgarbage.last_queue_health_window_ds)
		var/q3_delta = SSgarbage.last_q3_depth_delta
		var/q3_delta_text = "[q3_delta]"
		if (q3_delta > 0)
			q3_delta_text = "+[q3_delta]"
		output += "<b>Q3 дельта (~[round(SSgarbage.last_queue_health_window_ds / 10, 0.1)]с):</b> [q3_delta_text]"
		output += " | <b>Q3 скорость:</b> [round(SSgarbage.last_q3_depth_delta_per_second, 0.01)]/с<br>"
		output += "<b>/datum/gas_mixture:</b> qdel=[round(SSgarbage.gas_mixture_qdel_rate_per_second, 0.01)]/с"
		output += " | hard-del=[round(SSgarbage.gas_mixture_harddel_rate_per_second, 0.01)]/с<br>"
		if (SSgarbage.last_hd_overflow_mode && SSgarbage.last_q3_depth_delta > 0)
			output += "<span style='color:#ff6666'><b>Предупреждение:</b> очередь hard delete продолжает расти даже при активном overflow-режиме.</span><br>"
	if (SSgarbage.last_hd_mc_clipped)
		output += "<span style='color:#ff6666'><b>MC-clipped:</b> hard delete часто уступает MC раньше, чем расходует локальный GC-бюджет.</span><br>"
	if (SSgarbage.highest_del_ms)
		output += "<b>Рекорд hard-del:</b> [SSgarbage.highest_del_ms]мс — [SSgarbage.highest_del_type_string]<br>"
	output += "</div><br>"
	#ifdef REFERENCE_TRACKING
	output += "<div style='color:#ffcc66'><b>Внимание:</b> FAST-REFTRACK запускает поиск ссылок на каждый softcheck miss и может заметно тормозить GC. Включайте его только временно для диагностики.</div><br>"
	#else
	output += "<div style='color:#aaaaaa'><b>Примечание:</b> REFERENCE_TRACKING не включён — кнопки FAST-REF и SKIP-REFSCAN неактивны. Это нормально для продакшена. Для отладки утечек на dev-сервере: раскомментируйте <code>#define REFERENCE_TRACKING</code> в <code>code/_compile_options.dm</code>.</div><br>"
	#endif

	// --- Queue levels ---
	var/list/level_names = list("Softcheck", "Warnfail", "HardDel")
	output += "<table border='1' cellpadding='4' style='border-collapse:collapse'>"
	output += "<tr><th>Уровень</th><th>Тайм-аут</th><th>Ожидают</th><th>Обработано</th><th>Пик</th><th>Пройдено</th><th>Не прошло</th></tr>"
	var/list/timeouts = list(GC_SOFTCHECK_TIMEOUT, GC_WARNFAIL_TIMEOUT, GC_HARDDEL_TIMEOUT)
	for (var/i in 1 to GC_QUEUE_COUNT)
		var/pending = SSgarbage.GetQueueDepth(i)
		var/processed = SSgarbage.GetProcessedQueueSlots(i)
		output += "<tr>"
		output += "<td>[level_names[i]]</td>"
		output += "<td>[timeouts[i] / 10]с</td>"
		output += "<td>[pending]</td>"
		output += "<td>[processed]</td>"
		output += "<td>[SSgarbage.peak_queue_depths[i]]</td>"
		output += "<td>[SSgarbage.pass_counts[i]]</td>"
		output += "<td>[SSgarbage.fail_counts[i]]</td>"
		output += "</tr>"
	output += "</table><br>"

	// --- Top failing types ---
	output += "<b>Топ типов по подтверждённым утечкам (warnfail):</b><ol>"
	var/list/fail_scores = list()
	for (var/path in SSgarbage.items)
		var/datum/qdel_item/I = SSgarbage.items[path]
		var/score = I.warnfail_count * 1000 + I.hard_deletes
		if (I.warnfail_count > 0)
			fail_scores["[path]"] = score
	sortTim(fail_scores, cmp = GLOBAL_PROC_REF(cmp_numeric_dsc), associative = TRUE)
	var/shown = 0
	for (var/path in fail_scores)
		var/datum/qdel_item/I = SSgarbage.items[path]
		var/flags_str = ""
		if (I.qdel_flags & QDEL_ITEM_SUSPENDED_FOR_LAG)
			flags_str += " <b style='color:red'>\[SUSPENDED\]</b>"
		if (I.qdel_flags & QDEL_ITEM_FAST_REFTRACK)
			flags_str += " <span style='color:yellow'>\[FAST-REF\]</span>"
		if (I.qdel_flags & QDEL_ITEM_SOFTFAIL_ALERT)
			flags_str += " <span style='color:cyan'>\[SOFTFAIL-ALERT-SEEN\]</span>"
		if (I.qdel_flags & QDEL_ITEM_SLOWDESTROY)
			flags_str += " <span style='color:#9fd'>\[SLOWDESTROY-SEEN\]</span>"
		if (I.qdel_flags & QDEL_ITEM_SKIP_REFSCAN)
			flags_str += " <span style='color:#aaa'>\[SKIP-REF\]</span>"
		output += "<li>[path][flags_str]"
		output += " — Fails: [I.failures] | Warnfail: [I.warnfail_count] | HardDel: [I.hard_deletes]"
		output += " | <A href='byond://?src=[REF(holder)];[HrefToken()];gc_type_detail=[url_encode(path)]'>Подробнее</A>"
		#ifdef REFERENCE_TRACKING
		output += " | <A href='byond://?src=[REF(holder)];[HrefToken()];gc_fast_reftrack=[url_encode(path)];gc_return=health'>[I.qdel_flags & QDEL_ITEM_FAST_REFTRACK ? "Откл. fast-ref" : "Вкл. fast-ref"]</A>"
		output += " | <A href='byond://?src=[REF(holder)];[HrefToken()];gc_skip_refscan=[url_encode(path)];gc_return=health'>[I.qdel_flags & QDEL_ITEM_SKIP_REFSCAN ? "Вкл. ref-scan" : "Откл. ref-scan"]</A>"
		#endif
		if (I.qdel_flags & QDEL_ITEM_SUSPENDED_FOR_LAG)
			output += " | <A href='byond://?src=[REF(holder)];[HrefToken()];gc_unsuspend=[url_encode(path)];gc_return=health'>Снять суспенд</A>"
		output += "</li>"
		shown++
		if (shown >= 20)
			output += "<li><i>...и ещё [length(fail_scores) - 20] типов</i></li>"
			break
	if (!shown)
		output += "<li><i>Подтверждённых утечек не обнаружено</i></li>"
	output += "</ol>"

	// --- Queue depth sparkline ---
	var/history = SSgarbage.queue_depth_history
	if (length(history))
		output += "<b>График глубины очередей (последние [length(history) * GC_DEPTH_SAMPLE_INTERVAL]с, сэмпл [GC_DEPTH_SAMPLE_INTERVAL]с):</b><br>"
		output += "<div style='font-family:monospace; background:#111; padding:6px; border:1px solid #333; white-space:pre'>"
		var/list/spark_chars = list("&#9601;","&#9602;","&#9603;","&#9604;","&#9605;","&#9606;","&#9607;","&#9608;")
		var/list/level_names2 = list("Softcheck","Warnfail ","HardDel  ")
		for (var/lvl in 1 to GC_QUEUE_COUNT)
			var/max_d = 1
			for (var/entry in history)
				var/list/s = entry
				if (s[lvl + 1] > max_d)
					max_d = s[lvl + 1]
			var/spark = ""
			for (var/entry in history)
				var/list/s = entry
				var/d = s[lvl + 1]
				var/idx = max(1, min(8, round(d / max_d * 8)))
				spark += spark_chars[idx]
			output += "[level_names2[lvl]]: [spark] (max [max_d])\n"
		output += "</div><br>"

	// --- Recent failures ---
	var/recent_fails = SSgarbage.recent_failures
	if (length(recent_fails))
		output += "<b>Последние события GC (последние [length(recent_fails)]):</b>"
		output += "<table border='1' cellpadding='3' style='border-collapse:collapse; font-family:monospace; font-size:0.9em'>"
		output += "<tr><th>Тип</th><th>Событие</th><th>Hint</th><th>Тому назад</th></tr>"
		for (var/i = length(recent_fails), i >= 1, i--)
			var/list/entry = recent_fails[i]
			var/ago = round((world.time - entry[1]) / 10, 0.1)
			output += "<tr><td>[entry[2]]</td><td>[gc_health_event_text(entry[3], entry[4])]</td><td>[gc_health_hint_text(entry[4])]</td><td>[ago]с</td></tr>"
		output += "</table><br>"

	// --- Recent hard deletes ---
	var/recent_hd = SSgarbage.recent_hard_deletes
	if (length(recent_hd))
		output += "<b>Последние hard delete'ы (последние [length(recent_hd)]):</b>"
		output += "<table border='1' cellpadding='3' style='border-collapse:collapse; font-family:monospace; font-size:0.9em'>"
		output += "<tr><th>Тип</th><th>Стоимость</th><th>Тому назад</th></tr>"
		for (var/i = length(recent_hd), i >= 1, i--)
			var/list/entry = recent_hd[i]
			var/ago = round((world.time - entry[1]) / 10, 0.1)
			output += "<tr><td>[entry[2]]</td><td>[entry[3]]мс</td><td>[ago]с</td></tr>"
		output += "</table><br>"

	// --- Top by hard_delete_time ---
	output += "<details><summary><b>Топ по суммарному времени hard delete</b></summary>"
	var/list/hd_time_scores = list()
	for (var/path in SSgarbage.items)
		var/datum/qdel_item/I = SSgarbage.items[path]
		if (I.hard_delete_time > 0)
			hd_time_scores["[path]"] = I.hard_delete_time
	if (length(hd_time_scores))
		sortTim(hd_time_scores, cmp = GLOBAL_PROC_REF(cmp_numeric_dsc), associative = TRUE)
		output += "<ol>"
		var/n = 0
		for (var/path in hd_time_scores)
			var/datum/qdel_item/I = SSgarbage.items[path]
			output += "<li>[path] — [I.hard_delete_time]мс суммарно | [I.hard_deletes] раз | макс [I.hard_delete_max]мс</li>"
			if (++n >= 15)
				break
		output += "</ol>"
	else
		output += "<i>Нет данных</i>"
	output += "</details>"

	// --- Types that sleep in Destroy() ---
	output += "<details><summary><b>Типы, засыпающие в Destroy() — блокируют тик</b></summary>"
	var/list/sleep_scores = list()
	for (var/path in SSgarbage.items)
		var/datum/qdel_item/I = SSgarbage.items[path]
		if (I.slept_destroy > 0)
			sleep_scores["[path]"] = I.slept_destroy
	if (length(sleep_scores))
		sortTim(sleep_scores, cmp = GLOBAL_PROC_REF(cmp_numeric_dsc), associative = TRUE)
		output += "<ol>"
		var/n = 0
		for (var/path in sleep_scores)
			var/datum/qdel_item/I = SSgarbage.items[path]
			output += "<li>[path] — [I.slept_destroy] раз из [I.qdels] вызовов</li>"
			if (++n >= 15)
				break
		output += "</ol>"
	else
		output += "<i>Нет данных</i>"
	output += "</details>"

	// --- Types with no_hint or no_respect_force ---
	var/list/bad_types = list()
	for (var/path in SSgarbage.items)
		var/datum/qdel_item/I = SSgarbage.items[path]
		if (I.no_hint || I.no_respect_force)
			bad_types["[path]"] = I.no_hint + I.no_respect_force * 2
	if (length(bad_types))
		sortTim(bad_types, cmp = GLOBAL_PROC_REF(cmp_numeric_dsc), associative = TRUE)
		output += "<details><summary><b>Проблемные Destroy() (нет hint / игнор force)</b></summary><ol>"
		var/n = 0
		for (var/path in bad_types)
			var/datum/qdel_item/I = SSgarbage.items[path]
			var/problems = ""
			if (I.no_hint)
				problems += "нет hint: [I.no_hint] "
			if (I.no_respect_force)
				problems += "игнор force: [I.no_respect_force] "
			output += "<li>[path] — [problems]</li>"
			if (++n >= 15)
				break
		output += "</ol></details>"

	// --- Config ---
	output += "<details><summary><b>Конфиг GC</b></summary>"
	output += "<div style='font-family:monospace; background:#111; padding:6px; border:1px solid #333'>"
	var/threshold = CONFIG_GET(number/hard_deletes_overrun_threshold)
	var/overrun_limit = CONFIG_GET(number/hard_deletes_overrun_limit)
	var/hd_budget_min = SSgarbage.GetConfiguredHardDeleteBudgetMinMs()
	var/hd_budget_max = SSgarbage.GetConfiguredHardDeleteBudgetMaxMs(hd_budget_min)
	var/hd_hold_cap = SSgarbage.GetConfiguredHardDeleteHoldMaxPerFire()
	var/hd_cap = SSgarbage.GetConfiguredHardDeleteMaxPerFire()
	var/hd_recover_threshold = SSgarbage.GetConfiguredHardDeleteRecoverThreshold()
	var/hd_target_q3_delta = SSgarbage.GetConfiguredHardDeleteTargetQ3DeltaPerSecond()
	var/hd_hysteresis = SSgarbage.GetConfiguredHardDeleteModeHysteresisSamples()
	var/hd_overflow_threshold = SSgarbage.GetConfiguredHardDeleteOverflowThreshold()
	var/hd_overflow_budget_max = SSgarbage.GetConfiguredHardDeleteOverflowBudgetMaxMs(hd_budget_max)
	var/hd_overflow_cap = SSgarbage.GetConfiguredHardDeleteOverflowMaxPerFire(hd_cap)
	var/hd_lobby_budget = SSgarbage.GetConfiguredHardDeleteLobbyBudgetMs()
	var/hd_lobby_cap = SSgarbage.GetConfiguredHardDeleteLobbyMaxPerFire()
	output += "hard_deletes_overrun_threshold: [threshold ? "[threshold]с" : "выключен"]<br>"
	output += "hard_deletes_overrun_limit: [overrun_limit ? "[overrun_limit]" : "выключен"]<br>"
	output += "GC_SOFTCHECK_TIMEOUT: [GC_SOFTCHECK_TIMEOUT / 10]с<br>"
	output += "GC_WARNFAIL_TIMEOUT: [GC_WARNFAIL_TIMEOUT / 10]с<br>"
	output += "GC_HARDDEL_TIMEOUT: [GC_HARDDEL_TIMEOUT / 10]с<br>"
	output += "GC_COMPACT_THRESHOLD: [GC_COMPACT_THRESHOLD]<br>"
	output += "gc_harddel_budget_min_ms: [hd_budget_min]мс<br>"
	output += "gc_harddel_budget_max_ms: [hd_budget_max]мс<br>"
	output += "gc_harddel_hold_max_per_fire: [hd_hold_cap]<br>"
	output += "gc_harddel_max_per_fire: [hd_cap]<br>"
	output += "gc_harddel_recover_threshold: [hd_recover_threshold]<br>"
	output += "gc_harddel_target_q3_delta_per_second: [round(hd_target_q3_delta, 0.01)]<br>"
	output += "gc_harddel_mode_hysteresis_samples: [hd_hysteresis]<br>"
	output += "gc_harddel_overflow_threshold: [hd_overflow_threshold]<br>"
	output += "gc_harddel_overflow_budget_max_ms: [hd_overflow_budget_max]мс<br>"
	output += "gc_harddel_overflow_max_per_fire: [hd_overflow_cap]<br>"
	output += "gc_harddel_lobby_budget_ms: [hd_lobby_budget]мс<br>"
	output += "gc_harddel_lobby_max_per_fire: [hd_lobby_cap]<br>"
	output += "Depth sample interval: [GC_DEPTH_SAMPLE_INTERVAL]с<br>"
	output += "</div></details><br>"

	var/datum/browser/popup = new(usr, "gc_health", "GC Health Panel", 900, 700)
	popup.set_content(output.Join())
	popup.open()

/// Show detailed stats for a single type path.
/client/proc/cmd_gc_type_detail(path_string)
	if (!check_rights(R_DEBUG))
		return
	var/type_path = text2path(path_string)
	if (!type_path)
		to_chat(usr, "<span class='warning'>Неверный путь типа: [path_string]</span>")
		return
	var/datum/qdel_item/I = SSgarbage.GetItem(type_path)
	if (!I)
		to_chat(usr, "<span class='notice'>Нет данных для [path_string] — ни разу не проходил через qdel().</span>")
		return

	var/list/output = list()
	output += "<b>GC детали: [path_string]</b><br>"
	output += "<A href='byond://?src=[REF(holder)];[HrefToken()];gc_health_refresh=1'>&lt;&lt;&lt; Назад</A><br><br>"

	output += "<div style='font-family:monospace; background:#111; padding:8px; border:1px solid #333'>"
	output += "qdel() всего: [I.qdels]<br>"
	output += "Destroy() время: [I.destroy_time]мс (ср [round(I.destroy_time / max(I.qdels, 1), 0.01)]мс)<br>"
	output += "Softcheck miss: [I.failures]<br>"
	output += "Подтверждённые утечки (warnfail): [I.warnfail_count]<br>"
	output += "Hard deletes: [I.hard_deletes] ([I.hard_delete_time]мс, ср [round(I.hard_delete_avg_ms, 0.01)]мс, макс [I.hard_delete_max]мс)<br>"
	if (I.hard_deletes_over_threshold)
		output += "Сверх порога: [I.hard_deletes_over_threshold]<br>"
	if (I.slept_destroy)
		output += "Засыпал в Destroy(): [I.slept_destroy] раз<br>"
	if (I.no_respect_force)
		output += "Игнорировал force=TRUE: [I.no_respect_force] раз<br>"
	if (I.no_hint)
		output += "Не вернул hint: [I.no_hint] раз<br>"
	if (I.softfail_alert_failures)
		output += "SOFTFAIL_ALERT не прошёл softcheck: [I.softfail_alert_failures] раз<br>"

	// Flags
	output += "<br><b>Флаги:</b> "
	if (!I.qdel_flags)
		output += "нет"
	else
		if (I.qdel_flags & QDEL_ITEM_SUSPENDED_FOR_LAG)
			output += "<b style='color:red'>SUSPENDED</b> "
		if (I.qdel_flags & QDEL_ITEM_ADMINS_WARNED)
			output += "ADMINS_WARNED "
		if (I.qdel_flags & QDEL_ITEM_FAST_REFTRACK)
			output += "<span style='color:yellow'>FAST_REFTRACK</span> "
		if (I.qdel_flags & QDEL_ITEM_SOFTFAIL_ALERT)
			output += "<span style='color:cyan'>SOFTFAIL_ALERT_SEEN</span> "
		if (I.qdel_flags & QDEL_ITEM_SLOWDESTROY)
			output += "SLOWDESTROY_SEEN "
		if (I.qdel_flags & QDEL_ITEM_SKIP_REFSCAN)
			output += "<span style='color:#aaa'>SKIP_REFSCAN</span> "
	output += "<br>"

	// Actions
	output += "<br><b>Действия:</b> "
	if (I.qdel_flags & QDEL_ITEM_SUSPENDED_FOR_LAG)
		output += "<A href='byond://?src=[REF(holder)];[HrefToken()];gc_unsuspend=[url_encode(path_string)];gc_return=detail'>Снять суспенд</A> "
	#ifdef REFERENCE_TRACKING
	output += "<A href='byond://?src=[REF(holder)];[HrefToken()];gc_fast_reftrack=[url_encode(path_string)];gc_return=detail'>"
	output += "[I.qdel_flags & QDEL_ITEM_FAST_REFTRACK ? "Откл. fast-ref" : "Вкл. fast-ref"]</A> "
	output += "<A href='byond://?src=[REF(holder)];[HrefToken()];gc_skip_refscan=[url_encode(path_string)];gc_return=detail'>"
	output += "[I.qdel_flags & QDEL_ITEM_SKIP_REFSCAN ? "Вкл. ref-scan" : "Откл. ref-scan"]</A> "
	#endif
	output += "</div><br>"
	#ifdef REFERENCE_TRACKING
	output += "<span style='color:#ffcc66'>FAST-REFTRACK не должен быть постоянным режимом: он запускает поиск ссылок на каждый softcheck miss.</span><br><br>"
	#else
	output += "<span style='color:#aaaaaa'>REFERENCE_TRACKING не включён — поиск ссылок недоступен (это нормально для прода).</span><br><br>"
	#endif

	// Recent failure timestamps
	if (I.failure_times && length(I.failure_times))
		output += "<b>Последние подтверждённые утечки:</b><ul>"
		for (var/t in I.failure_times)
			var/ago = round((world.time - t) / 10, 0.1)
			output += "<li>[ago]с назад</li>"
		output += "</ul>"

	// Live and pending queued instances of this type
	output += "<b>Текущие объекты в очередях:</b><ul>"
	var/live_found = 0
	var/gcd_found = 0
	var/list/level_names = list("Softcheck", "Warnfail", "HardDel")
	for (var/lvl in 1 to GC_QUEUE_COUNT)
		var/list/refs  = SSgarbage.queue_refs[lvl]
		var/list/origins = SSgarbage.queue_origin_times[lvl]
		var/list/times = SSgarbage.queue_times[lvl]
		var/list/type_strings = SSgarbage.queue_types[lvl]
		var/head = SSgarbage.queue_heads[lvl]
		for (var/j in head to length(refs))
			if (isnull(refs[j]))
				continue
			var/datum/D = SSgarbage.GetQueuedDatum(lvl, j)
			if (D)
				if (D.type != type_path)
					continue
				live_found++
				var/total_age = round((world.time - origins[j]) / 10, 0.1)
				var/stage_age = round((world.time - times[j]) / 10, 0.1)
				output += "<li>[level_names[lvl]] — ref=[refs[j]] возраст=[total_age]с (этап [stage_age]с)"
				output += " [ADMIN_VV(D)]"
				output += "</li>"
				if (live_found >= 30)
					output += "<li><i>...показано 30 живых, остальные не отображены</i></li>"
					break
			else
				// Already GC'd — check stored type
				if (j <= length(type_strings) && type_strings[j] == path_string)
					gcd_found++
		if (live_found >= 30)
			break
	if (!live_found && !gcd_found)
		output += "<li><i>Нет объектов в очередях</i></li>"
	else if (!live_found)
		output += "<li><i>Нет живых объектов (ожидают обработки после GC: [gcd_found])</i></li>"
	else if (gcd_found)
		output += "<li><i>Также ожидают обработки после GC: [gcd_found]</i></li>"
	output += "</ul>"

	var/datum/browser/popup = new(usr, "gc_type_detail", "GC: [path_string]", 800, 600)
	popup.set_content(output.Join())
	popup.open()

/// Help / reference guide for the GC Health Panel.
/client/proc/cmd_gc_health_help()
	if (!check_rights(R_DEBUG))
		return

	var/list/output = list()
	output += "<A href='byond://?src=[REF(holder)];[HrefToken()];gc_health_refresh=1'>&lt;&lt;&lt; Назад к панели</A><br><br>"
	output += "<h2>Справочник GC Health Panel</h2>"
	output += "<div style='font-family:sans-serif; line-height:1.5; max-width:850px'>"

	// ===== Общая идея =====
	output += "<h3>Что вообще такое GC и зачем эта панель?</h3>"
	output += "<p>Когда объект в игре больше не нужен (моб умер, предмет удалили, газ рассеялся), код вызывает <b>qdel()</b>. "
	output += "После этого объект попадает в систему сборки мусора (<b>SSgarbage</b>), которая пытается убедиться, что объект действительно удалился из памяти.</p>"
	output += "<p>Если объект не удалился — значит где-то осталась ссылка на него. Это <b>утечка памяти</b>. "
	output += "Со временем утечки накапливаются, сервер начинает тормозить и в итоге падает. "
	output += "Эта панель показывает, насколько здорова система сборки мусора и где искать проблемы.</p>"

	// ===== Конвейер очередей =====
	output += "<h3>Конвейер очередей: Softcheck → Warnfail → HardDel</h3>"
	output += "<p>Каждый удалённый объект проходит через конвейер из трёх этапов:</p>"
	output += "<ol>"
	output += "<li><b>Softcheck</b> (таймаут [GC_SOFTCHECK_TIMEOUT / 10]с) — первая проверка. Объект вызвал Destroy(), подождали [GC_SOFTCHECK_TIMEOUT / 10] секунд, проверяем: "
	output += "удалился ли он сам через встроенный GC BYOND? Если да — отлично, объект ушёл. Если нет — значит где-то осталась ссылка, и объект переходит на следующий уровень.</li>"
	output += "<li><b>Warnfail</b> (таймаут [GC_WARNFAIL_TIMEOUT / 10]с) — подтверждение утечки. Ждём ещё [GC_WARNFAIL_TIMEOUT / 10] секунд на случай, если ссылка была временной. "
	output += "Если объект всё ещё жив — это <b>подтверждённая утечка</b>. Объект переходит в очередь на принудительное удаление.</li>"
	output += "<li><b>HardDel</b> (таймаут [GC_HARDDEL_TIMEOUT / 10]с) — принудительное удаление. BYOND вызывает <code>del()</code> напрямую. "
	output += "Это дорогая операция — BYOND обходит ВСЮ память, ищет все ссылки на объект и обнуляет их. Может занять миллисекунды, а на больших объектах — десятки мс.</li>"
	output += "</ol>"

	// ===== Общие метрики =====
	output += "<h3>Блок «Итого» — общие метрики</h3>"
	output += "<table border='1' cellpadding='6' style='border-collapse:collapse; font-size:0.95em'>"
	output += "<tr><th>Метрика</th><th>Что значит</th><th>На что смотреть</th></tr>"
	output += "<tr><td><b>Del</b></td><td>Сколько объектов BYOND удалил принудительно (hard delete)</td><td>Чем больше — тем больше нагрузка. В идеале должно быть минимум.</td></tr>"
	output += "<tr><td><b>GC</b></td><td>Сколько объектов удалились сами через сборщик мусора BYOND</td><td>Это хорошие удаления. Чем выше процент GC — тем лучше.</td></tr>"
	output += "<tr><td><b>GC%</b></td><td>Процент объектов, которые удалились сами (GC) от общего числа</td><td><b>95%+</b> — отлично. <b>80-95%</b> — есть утечки, но терпимо. <b>&lt;80%</b> — проблема, много hard delete'ов.</td></tr>"
	output += "<tr><td><b>Подтверждённые утечки (ср)</b></td><td>Средняя скорость подтверждённых утечек в минуту</td><td><b>0</b> — идеал. <b>&lt;1/мин</b> — норма. <b>&gt;5/мин</b> — активная утечка, надо разбираться.</td></tr>"
	output += "<tr><td><b>Hard-del (ср)</b></td><td>Среднее время одного hard delete в миллисекундах</td><td><b>&lt;1мс</b> — норма. <b>&gt;5мс</b> — тяжёлые объекты. <b>&gt;20мс</b> — проблема, будет lag spike.</td></tr>"
	output += "<tr><td><b>Этот тик</b></td><td>Сколько Del и GC произошло за последний тик подсистемы</td><td>Показывает текущую активность. Всплески Del — повод посмотреть что удаляется.</td></tr>"
	output += "</table><br>"

	// ===== Hard-delete режимы =====
	output += "<h3>Режимы hard delete</h3>"
	output += "<p>SSgarbage динамически регулирует, сколько ресурсов тратить на принудительное удаление. Есть четыре режима:</p>"
	output += "<table border='1' cellpadding='6' style='border-collapse:collapse; font-size:0.95em'>"
	output += "<tr><th>Режим</th><th>Когда включается</th><th>Что делает</th></tr>"
	output += "<tr><td><b>LOBBY</b></td><td>Сервер в лобби (голосование, до старта раунда)</td>"
	output += "<td>Агрессивный бюджет ([SSgarbage.GetConfiguredHardDeleteLobbyBudgetMs()]мс), удаляет по [SSgarbage.GetConfiguredHardDeleteLobbyMaxPerFire()] объектов за тик. Использует свободное CPU время до старта раунда.</td></tr>"
	output += "<tr><td><b>HOLD</b></td><td>Очередь hard delete небольшая, всё под контролем</td>"
	output += "<td>Минимальный бюджет ([SSgarbage.GetConfiguredHardDeleteBudgetMinMs()]мс), удаляет по [SSgarbage.GetConfiguredHardDeleteMaxPerFire()] объектов за тик. Экономит ресурсы.</td></tr>"
	output += "<tr><td><b>RECOVER</b></td><td>Очередь растёт, Q3 дельта положительная несколько сэмплов подряд</td>"
	output += "<td>Увеличенный бюджет (до [SSgarbage.GetConfiguredHardDeleteBudgetMaxMs()]мс), пытается сократить очередь.</td></tr>"
	output += "<tr><td><b>OVERFLOW</b></td><td>Очередь превысила [SSgarbage.GetConfiguredHardDeleteOverflowThreshold()] объектов</td>"
	output += "<td>Максимальный бюджет ([SSgarbage.GetConfiguredHardDeleteOverflowBudgetMaxMs()]мс), удаляет по [SSgarbage.GetConfiguredHardDeleteOverflowMaxPerFire()] за тик. Аварийный режим.</td></tr>"
	output += "</table>"
	output += "<p><b>Если вы видите OVERFLOW</b> — сервер в беде. Очередь hard delete огромная, GC тратит кучу времени на удаление. "
	output += "Нужно срочно искать источник утечек (см. топ типов ниже).</p>"

	// ===== Бюджет и scheduling =====
	output += "<h3>Бюджет, cap, yield, MC-clipped</h3>"
	output += "<table border='1' cellpadding='6' style='border-collapse:collapse; font-size:0.95em'>"
	output += "<tr><th>Метрика</th><th>Что значит</th></tr>"
	output += "<tr><td><b>Hard-del бюджет</b></td><td>Сколько миллисекунд GC выделяет на hard delete'ы в этом тике. Зависит от режима (LOBBY/HOLD/RECOVER/OVERFLOW).</td></tr>"
	output += "<tr><td><b>Hard-del cap</b></td><td>Максимальное количество объектов, которые можно удалить за один тик. Даже если бюджет позволяет — больше cap не удалит.</td></tr>"
	output += "<tr><td><b>Hard-del pass</b></td><td>Сколько мс реально потратили на hard delete в последнем проходе.</td></tr>"
	output += "<tr><td><b>Yield ratio</b></td><td>Какой процент бюджета реально использовали. 100% — бюджет полностью израсходован (GC упёрся в лимит). Низкий % — очередь успевает обрабатываться.</td></tr>"
	output += "<tr><td><b>Scheduling</b></td><td><b>background</b> — GC работает в фоне, не мешает основному тику. <b>foreground</b> — GC работает в основном потоке (при высокой нагрузке).</td></tr>"
	output += "<tr><td><b>MC-clipped</b></td><td>Master Controller прервал работу GC до того, как GC израсходовал свой локальный бюджет. "
	output += "Если горит <b style='color:#ff6666'>YES</b> — MC забирает время у GC, и GC не успевает обрабатывать очередь. Это плохо при большой очереди.</td></tr>"
	output += "</table><br>"

	// ===== Q3 дельта =====
	output += "<h3>Q3 дельта — тренд очереди hard delete</h3>"
	output += "<p><b>Q3 дельта</b> — это изменение глубины очереди HardDel за последнее окно наблюдения. По сути — растёт очередь или сокращается.</p>"
	output += "<ul>"
	output += "<li><b>Отрицательная</b> (например -5) — очередь сокращается, GC справляется. Всё хорошо.</li>"
	output += "<li><b>Около нуля</b> — очередь стабильна. Нормально, но на пределе.</li>"
	output += "<li><b>Положительная</b> (например +10) — очередь растёт! GC не успевает удалять объекты. Если тренд сохраняется — переключится в RECOVER или OVERFLOW.</li>"
	output += "</ul>"
	output += "<p><b>Q3 скорость</b> — то же самое, но нормализовано в объекты/секунду. Целевое значение из конфига: [GC_HARDDEL_TARGET_Q3_DELTA_PER_SECOND]/с (должно быть отрицательным).</p>"

	// ===== gas_mixture =====
	output += "<h3>Строка /datum/gas_mixture</h3>"
	output += "<p>Gas mixture — самый массовый объект в атмосфере. Тысячи создаются и удаляются каждую секунду. "
	output += "Если <b>hard-del</b> скорость gas_mixture высокая — значит газовые смеси не проходят GC и удаляются принудительно. "
	output += "Это основная причина лага от GC у на БМе. Отдельная строка для него — чтобы сразу видеть, в нём ли проблема.</p>"

	// ===== Таблица очередей =====
	output += "<h3>Таблица уровней очередей</h3>"
	output += "<table border='1' cellpadding='6' style='border-collapse:collapse; font-size:0.95em'>"
	output += "<tr><th>Столбец</th><th>Что значит</th></tr>"
	output += "<tr><td><b>Ожидают</b></td><td>Сколько объектов сейчас ждут обработки на этом уровне. Большое число в Softcheck — нормально (объекты ждут таймаут). Большое число в HardDel — проблема.</td></tr>"
	output += "<tr><td><b>Обработано</b></td><td>Сколько слотов в очереди было обработано (включая успешные и неуспешные). Показывает общий объём работы.</td></tr>"
	output += "<tr><td><b>Пик</b></td><td>Максимальная глубина очереди за всё время. Если пик HardDel был >1000 — значит был момент сильной нагрузки.</td></tr>"
	output += "<tr><td><b>Пройдено</b></td><td>Сколько объектов прошли этот уровень успешно (удалились).</td></tr>"
	output += "<tr><td><b>Не прошло</b></td><td>Сколько объектов НЕ удалились на этом уровне и перешли на следующий.</td></tr>"
	output += "</table><br>"

	// ===== Топ утечек =====
	output += "<h3>Топ типов по утечкам — как читать и что делать</h3>"
	output += "<p>Это главная секция для диагностики. Показывает типы объектов, которые чаще всего не удаляются.</p>"
	output += "<ul>"
	output += "<li><b>Fails</b> — сколько раз объект не прошёл softcheck (первую проверку). Может быть ложным срабатыванием — иногда объекту просто нужно больше времени.</li>"
	output += "<li><b>Warnfail</b> — подтверждённые утечки. Объект не удалился даже после второй проверки. Это реальная проблема.</li>"
	output += "<li><b>HardDel</b> — сколько раз пришлось удалять принудительно. Каждый hard delete — это нагрузка на сервер.</li>"
	output += "</ul>"
	output += "<p><b>Что делать с проблемным типом:</b></p>"
	output += "<ol>"
	output += "<li><b>Нажмите «Подробнее»</b> — посмотрите детальную статистику и живые объекты в очередях.</li>"
	output += "<li><b>Включите fast-ref</b> — это запустит поиск ссылок при каждом softcheck miss. Покажет, КТО держит ссылку на объект. "
	output += "Но <b>осторожно</b>: это дорогая операция, включайте только временно для диагностики.</li>"
	output += "<li><b>Проверьте Destroy()</b> — убедитесь, что Destroy() объекта: очищает все ссылки (обнуляет переменные со ссылками на другие объекты), "
	output += "снимает регистрацию сигналов, удаляет себя из глобальных списков, вызывает <code>return ..() </code> (parent).</li>"
	output += "<li><b>Суспенд</b> (если тип помечен SUSPENDED) — GC автоматически приостановил hard delete для этого типа, потому что он слишком дорогой. "
	output += "Можно снять суспенд кнопкой «Снять суспенд», но лучше сначала пофиксить утечку.</li>"
	output += "</ol>"

	// ===== Спарклайн =====
	output += "<h3>График глубины очередей (спарклайн)</h3>"
	output += "<p>Три строки символов — по одной на каждую очередь. Каждый символ — один сэмпл (каждые [GC_DEPTH_SAMPLE_INTERVAL] секунд). "
	output += "Высота символа — глубина очереди относительно максимума.</p>"
	output += "<ul>"
	output += "<li><b>Softcheck</b> — обычно умеренно заполнена. Волны — это нормально (объекты приходят пачками).</li>"
	output += "<li><b>Warnfail</b> — должна быть почти пустой. Если растёт — есть активная утечка.</li>"
	output += "<li><b>HardDel</b> — должна быть почти пустой. Если растёт — GC не справляется с удалением. Смотрите на режим (LOBBY/HOLD/RECOVER/OVERFLOW).</li>"
	output += "</ul>"
	output += "<p>Тренд важнее абсолютных значений. Если линия <b>стабильно растёт вправо</b> — ситуация ухудшается.</p>"

	// ===== Флаги =====
	output += "<h3>Флаги типов</h3>"
	output += "<table border='1' cellpadding='6' style='border-collapse:collapse; font-size:0.95em'>"
	output += "<tr><th>Флаг</th><th>Что значит</th></tr>"
	output += "<tr><td><b style='color:red'>SUSPENDED</b></td><td>Hard delete для этого типа приостановлен. GC решил, что удалять его слишком дорого (занимает много мс). "
	output += "Объекты этого типа будут накапливаться в памяти, пока суспенд не снимут. Нужно фиксить Destroy() или снимать суспенд вручную.</td></tr>"
	output += "<tr><td><b style='color:yellow'>FAST_REFTRACK</b></td><td>Включён быстрый поиск ссылок. При каждом softcheck miss GC будет искать, кто держит ссылку. "
	output += "Полезно для диагностики, но тормозит. Выключайте после того, как нашли проблему. "
	output += "<b>Требует компиляции с <code>REFERENCE_TRACKING</code></b> (см. <code>code/_compile_options.dm</code>). Без этого флага кнопка не отображается и поиск ссылок не работает.</td></tr>"
	output += "<tr><td><b style='color:cyan'>SOFTFAIL_ALERT_SEEN</b></td><td>Тип вернул QDEL_HINT_SOFTFAIL_ALERT из Destroy(). Это значит: «я знаю, что могу не пройти softcheck, но предупредите если не пройду». "
	output += "Используется для типов, которые иногда задерживаются, но обычно удаляются.</td></tr>"
	output += "<tr><td><b style='color:#9fd'>SLOWDESTROY_SEEN</b></td><td>Тип вернул QDEL_HINT_SLOWDESTROY. Его Destroy() заведомо медленный (например, с анимациями или fade-out). "
	output += "GC не будет ругаться на softcheck miss для таких объектов — это ожидаемое поведение.</td></tr>"
	output += "<tr><td><b>ADMINS_WARNED</b></td><td>Администраторы уже были уведомлены об утечке этого типа. Повторное уведомление не придёт, пока флаг не сбросится.</td></tr>"
	output += "<tr><td><span style='color:#aaa'>SKIP_REFSCAN</span></td><td>Отключён поиск ссылок для этого типа. По умолчанию включён для /datum/gas_mixture — их слишком много и ref-scan на них неинформативен. Можно переключить кнопкой. Как и FAST_REFTRACK, требует компиляции с <code>REFERENCE_TRACKING</code>.</td></tr>"
	output += "</table><br>"

	// ===== QDEL hints =====
	output += "<h3>QDEL Hints — что возвращает Destroy()</h3>"
	output += "<p>Когда qdel() вызывает Destroy() объекта, тот возвращает «hint» — подсказку, что делать дальше:</p>"
	output += "<table border='1' cellpadding='6' style='border-collapse:collapse; font-size:0.95em'>"
	output += "<tr><th>Hint</th><th>Что значит</th></tr>"
	output += "<tr><td><b>QUEUE</b></td><td>Стандартный. Объект сделал cleanup, поставьте в очередь softcheck.</td></tr>"
	output += "<tr><td><b>LETMELIVE</b></td><td>Объект отказался умирать (например, моб передумал). Не удаляйте.</td></tr>"
	output += "<tr><td><b>IWILLGC</b></td><td>Объект гарантирует, что удалится сам. Не проверяйте (не ставьте в softcheck). Используйте осторожно — если объект соврал, утечка не будет обнаружена.</td></tr>"
	output += "<tr><td><b>HARDDEL</b></td><td>Объект знает, что не удалится сам. Сразу ставьте в очередь hard delete.</td></tr>"
	output += "<tr><td><b>HARDDEL_NOW</b></td><td>Удалите прямо сейчас, немедленно. Не ставьте в очередь.</td></tr>"
	output += "<tr><td><b>SOFTFAIL_ALERT</b></td><td>Как QUEUE, но если softcheck не пройдёт — алертните админов.</td></tr>"
	output += "<tr><td><b>SLOWDESTROY</b></td><td>Как QUEUE, но softcheck miss ожидаем и не считается проблемой.</td></tr>"
	output += "</table><br>"

	// ===== Проблемные Destroy() =====
	output += "<h3>Проблемные Destroy() — нет hint / игнор force</h3>"
	output += "<p><b>Нет hint</b> — Destroy() вернул null вместо одного из QDEL_HINT_*. Обычно это значит, что забыли <code>return ..() </code> в конце Destroy(). "
	output += "Без return parent не вызывается, а именно parent (в /datum) возвращает правильный hint. <b>Как фиксить:</b> добавьте <code>return ..() </code> в конец Destroy().</p>"
	output += "<p><b>Игнор force</b> — Destroy() вызвали с force=TRUE (принудительное удаление), но объект вернул LETMELIVE. "
	output += "Когда force=TRUE, объект ОБЯЗАН умереть. Он не имеет права отказываться. "
	output += "<b>Как фиксить:</b> в Destroy() проверяйте аргумент force и не возвращайте LETMELIVE, если force=TRUE.</p>"

	// ===== Sleep в Destroy() =====
	output += "<h3>Sleep в Destroy() — почему это плохо</h3>"
	output += "<p>Если Destroy() вызывает sleep() (или любой proc, который спит — например, do_after, animate, и т.д.), "
	output += "это <b>блокирует весь тик GC</b>. Пока один объект спит в Destroy(), остальные объекты в очереди не обрабатываются.</p>"
	output += "<p>Кроме того, после sleep() состояние объекта может измениться непредсказуемо — другой код может обратиться к полуудалённому объекту.</p>"
	output += "<p><b>Как фиксить:</b> вынесите асинхронную логику из Destroy(). Если нужна анимация перед удалением — запустите её ДО вызова qdel(), "
	output += "а в Destroy() делайте только синхронную очистку ссылок.</p>"

	// ===== Конфиг =====
	output += "<h3>Конфиг GC — что за параметры</h3>"
	output += "<table border='1' cellpadding='6' style='border-collapse:collapse; font-size:0.95em'>"
	output += "<tr><th>Параметр</th><th>Что значит</th></tr>"
	output += "<tr><td><b>hard_deletes_overrun_threshold</b></td><td>Если hard delete одного объекта занял больше этого времени — тип получает штрафное очко. При накоплении очков тип суспендится.</td></tr>"
	output += "<tr><td><b>hard_deletes_overrun_limit</b></td><td>Сколько штрафных очков нужно для суспенда типа.</td></tr>"
	output += "<tr><td><b>GC_SOFTCHECK_TIMEOUT</b></td><td>Сколько ждать перед первой проверкой (softcheck). Увеличение даёт объектам больше времени на самоудаление, но утечки обнаруживаются позже.</td></tr>"
	output += "<tr><td><b>GC_WARNFAIL_TIMEOUT</b></td><td>Сколько ждать перед подтверждением утечки (warnfail). Второй шанс для объекта.</td></tr>"
	output += "<tr><td><b>GC_HARDDEL_TIMEOUT</b></td><td>Сколько объект ждёт в очереди hard delete перед принудительным удалением.</td></tr>"
	output += "<tr><td><b>gc_harddel_budget_min/max_ms</b></td><td>Минимальный и максимальный бюджет времени на hard delete за тик (в мс). Min = HOLD режим, Max = RECOVER режим.</td></tr>"
	output += "<tr><td><b>gc_harddel_max_per_fire</b></td><td>Максимум объектов для hard delete за один тик (даже если бюджет позволяет больше).</td></tr>"
	output += "<tr><td><b>gc_harddel_lobby_budget_ms</b></td><td>Бюджет времени на hard delete в LOBBY режиме (в мс). Большое значение — в лобби мало что работает, можно тратить больше.</td></tr>"
	output += "<tr><td><b>gc_harddel_lobby_max_per_fire</b></td><td>Максимум объектов для hard delete за один тик в LOBBY режиме.</td></tr>"
	output += "<tr><td><b>gc_harddel_recover_threshold</b></td><td>При какой глубине очереди Q3 переключаться из HOLD в RECOVER (если тренд положительный).</td></tr>"
	output += "<tr><td><b>gc_harddel_overflow_threshold</b></td><td>При какой глубине очереди Q3 переключаться в аварийный OVERFLOW режим.</td></tr>"
	output += "<tr><td><b>gc_harddel_target_q3_delta_per_second</b></td><td>Целевая скорость сокращения очереди Q3 (отрицательное число). Если реальная скорость хуже — GC переключает режим.</td></tr>"
	output += "<tr><td><b>gc_harddel_mode_hysteresis_samples</b></td><td>Сколько сэмплов подряд тренд должен быть плохим, чтобы GC переключил режим. Защита от ложных срабатываний.</td></tr>"
	output += "<tr><td><b>GC_COMPACT_THRESHOLD</b></td><td>Порог для компактификации очередей (сдвига массива). Когда head уходит далеко вперёд — очередь сжимается.</td></tr>"
	output += "</table><br>"

	// ===== Пошаговая инструкция =====
	output += "<h3>Сервер лагает из-за GC — что делать? (пошагово)</h3>"
	output += "<ol>"
	output += "<li><b>Откройте панель</b> и посмотрите на GC%. Если он ниже 80% — у вас много hard delete'ов, это источник лага.</li>"
	output += "<li><b>Посмотрите на режим hard delete.</b> LOBBY — агрессивная очистка в лобби (норма). OVERFLOW — аварийная ситуация. RECOVER — GC борется. HOLD — всё спокойно.</li>"
	output += "<li><b>Проверьте Q3 дельту.</b> Если она положительная и растёт — проблема усугубляется.</li>"
	output += "<li><b>Посмотрите топ типов по утечкам.</b> Первые 3-5 типов — главные виновники.</li>"
	output += "<li><b>Для главного виновника:</b>"
	output += "<ul>"
	output += "<li>Нажмите «Подробнее» — посмотрите, сколько объектов в очередях и как долго они там.</li>"
	output += "<li>Если это /datum/gas_mixture — проблема в атмосфере. Ищите код, который создаёт газовые смеси и не удаляет их.</li>"
	output += "<li>Для других типов — включите fast-ref на пару минут, посмотрите логи (Ctrl+F «reference»), найдите кто держит ссылку.</li>"
	output += "<li>Почините Destroy(): обнулите все ссылки, вызовите parent, уберите sleep.</li>"
	output += "</ul></li>"
	output += "<li><b>Если тип суспенднут</b> и вы пофиксили утечку — снимите суспенд кнопкой. Если не пофиксили — оставьте суспенд, он защищает от лага.</li>"
	output += "<li><b>Обновляйте панель</b> каждые 30-60 секунд, чтобы видеть тренд. Если Q3 дельта стала отрицательной — фикс помогает.</li>"
	output += "</ol>"

	// ===== Детальная страница типа =====
	output += "<h3>Страница «Подробнее» по типу</h3>"
	output += "<p>Открывается по ссылке «Подробнее» для конкретного типа. Показывает:</p>"
	output += "<ul>"
	output += "<li><b>qdel() всего</b> — сколько раз вызывали qdel() для этого типа.</li>"
	output += "<li><b>Destroy() время</b> — суммарное и среднее время выполнения Destroy(). Если среднее >1мс — Destroy() слишком тяжёлый.</li>"
	output += "<li><b>Softcheck miss</b> — сколько раз объект не прошёл первую проверку. Не паникуйте — часть из них пройдёт warnfail.</li>"
	output += "<li><b>Подтверждённые утечки</b> — реальные утечки, прошедшие оба уровня проверки.</li>"
	output += "<li><b>Hard deletes</b> — принудительные удаления с временными метриками (среднее, максимум).</li>"
	output += "<li><b>Текущие объекты в очередях</b> — живые объекты этого типа, которые прямо сейчас ждут обработки. "
	output += "Можно кликнуть VV (View Variables) чтобы посмотреть состояние конкретного объекта и понять, почему он не удаляется.</li>"
	output += "</ul>"

	output += "<br><hr><p style='color:gray; font-size:0.85em'>GC Health Panel — инструмент для дебага утечек памяти в SS13. "
	output += "Если вы видите что-то непонятное — спросите у кодеров, они помогут разобраться.</p>"

	output += "</div>"

	var/datum/browser/popup = new(usr, "gc_health_help", "GC Health — Справочник", 900, 700)
	popup.set_content(output.Join())
	popup.open()
