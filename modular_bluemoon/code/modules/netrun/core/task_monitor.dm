/// A manual, read-only snapshot. No monitor datum, timer or client subscription is retained.
/client/proc/show_netrun_task_statistics()
	set category = "Debug.1) Logs"
	set name = "Netrun Task Statistics"
	set desc = "Show Netrun task costs, coalescing and pending work by type."
	if(!check_rights(R_DEBUG))
		return
	SSnetrun.show_task_statistics(src)

/datum/controller/subsystem/netrun/proc/show_task_statistics(client/viewer, sort_by = "total_ms")
	if(usr?.client != viewer || !check_rights_for(viewer, R_DEBUG))
		return FALSE
	if(QDELETED(task_scheduler))
		to_chat(viewer, span_notice("Планировщик Netrun ещё не запущен."))
		return FALSE
	var/list/report = task_scheduler.statistics()
	var/href_base = "?src=[REF(src)];[HrefToken()]"
	var/datum/browser/popup = new(viewer, "netrun_task_statistics", "Netrun Task Statistics", 1400, 850)
	popup.set_content(netrun_task_statistics_html(report, sort_by, href_base))
	popup.open(FALSE)
	qdel(popup)
	return TRUE

/datum/controller/subsystem/netrun/Topic(href, href_list)
	. = ..()
	if(. || !href_list["netrun_statistics_sort"])
		return
	if(!check_rights(R_DEBUG, FALSE) || !usr.client.holder.CheckAdminHref(href, href_list))
		return
	show_task_statistics(usr.client, href_list["netrun_statistics_sort"])

/// Rendering only reads scalar snapshots. Sorting never touches the scheduler's FIFO.
/proc/netrun_task_statistics_html(list/report, sort_by = "total_ms", href_base = "")
	var/list/sorts = list("total_ms" = "CPU всего", "peak_ms" = "Пик CPU", "pending" = "Размер очереди", "oldest_wait_ds" = "Старейшая задача")
	if(!(sort_by in sorts))
		sort_by = "total_ms"
	var/list/output = list("<style>table.netrun-task-stats {border-collapse:collapse;width:100%;font-family:monospace;font-size:12px} .netrun-task-stats th,.netrun-task-stats td {padding:5px;border:1px solid #555;text-align:right} .netrun-task-stats th:first-child,.netrun-task-stats td:first-child {text-align:left} .netrun-task-stats th {background:#333;color:#eee} .netrun-task-stats tr:nth-child(even) {background:rgba(128,128,128,0.12)} .netrun-task-stats .identity {text-align:left;word-break:break-all} .netrun-task-scroll {overflow-x:auto}</style>")
	var/refresh_href = html_encode("[href_base];netrun_statistics_sort=[sort_by]")
	output += "<p><a href='[refresh_href]'>Обновить снимок</a> &middot; Сортировка: "
	for(var/key in sorts)
		var/label = sorts[key]
		var/sort_href = html_encode("[href_base];netrun_statistics_sort=[key]")
		output += "[key == sort_by ? "<b>[label]</b>" : "<a href='[sort_href]'>[label]</a>"] &nbsp; "
	var/elapsed = max(0, report["sampled_at"] - report["started_at"]) / (1 SECONDS)
	output += "</p><p>Накопительные счётчики с запуска планировщика: [round(elapsed, 0.1)] с. Частота вызовов усреднена за это время. Снимок world.time: [report["sampled_at"]]. Обновление только вручную.</p>"
	output += "<p><b>Очередь:</b> [report["pending"]] &middot; <b>Выполняется:</b> [report["running"]] &middot; <b>Пик очереди:</b> [report["peak_pending"]] &middot; <b>Выполнено проходов задач:</b> [report["completed"]] &middot; <b>Объединено запросов:</b> [report["merged"]] &middot; <b>Отменено:</b> [report["cancelled"]]</p>"
	output += "<p><b>Последний проход worker:</b> [round(report["last_execution_ms"], 0.01)] / [round(report["last_budget_ms"], 0.01)] мс &middot; <b>Превышений бюджета worker:</b> [report["budget_overruns"]] &middot; <b>Задач дороже бюджета:</b> [report["task_overruns"]]</p>"
	output += "<p>CPU учитывает только вызов execute() в worker. Работа асинхронного native callback после возврата waitfor=FALSE сюда не входит. Время ожидания и исполнения в списке задач — реальное прошедшее время, а не CPU.</p>"
	var/list/scores = list()
	var/list/by_kind = list()
	var/total_cpu_ms = 0
	for(var/list/entry as anything in report["types"])
		var/kind = entry["kind"]
		by_kind[kind] = entry
		scores[kind] = entry[sort_by]
		total_cpu_ms += entry["total_ms"]
	sortTim(scores, cmp = GLOBAL_PROC_REF(cmp_numeric_dsc), associative = TRUE)
	output += "<h3>Типы задач</h3><div class='netrun-task-scroll'><table class='netrun-task-stats'><tr><th>Тип</th><th>CPU всего, мс</th><th>Доля CPU</th><th>CPU среднее, мс</th><th>CPU пик, мс</th><th>Вызовов / в секунду</th><th>Запросов / создано</th><th>Объединено / продлено</th><th>Ожидает / выполняется</th><th>Старейшее ожидание, с</th><th>Ожидание среднее / пик, с</th><th>Опозданий</th><th>Отмен</th><th>Дороже бюджета</th></tr>"
	for(var/kind in scores)
		var/list/entry = by_kind[kind]
		var/calls = entry["calls"]
		var/average_wait = calls ? entry["total_wait_ds"] / calls / (1 SECONDS) : 0
		var/cpu_share = total_cpu_ms ? 100 * entry["total_ms"] / total_cpu_ms : 0
		var/calls_per_second = elapsed > 0 ? calls / elapsed : 0
		output += "<tr><td>[html_encode(kind)]</td><td>[round(entry["total_ms"], 0.01)]</td><td>[round(cpu_share, 0.1)]%</td><td>[round(entry["average_ms"], 0.01)]</td><td>[round(entry["peak_ms"], 0.01)]</td><td>[calls] / [round(calls_per_second, 0.01)]</td><td>[entry["requests"]] / [entry["created"]]</td><td>[entry["merged"]] / [entry["renewed"]]</td><td>[entry["pending"]] / [entry["running"]]</td><td>[round(entry["oldest_wait_ds"] / (1 SECONDS), 0.1)]</td><td>[round(average_wait, 0.1)] / [round(entry["peak_wait_ds"] / (1 SECONDS), 0.1)]</td><td>[entry["overdue"]]</td><td>[entry["cancelled"]]</td><td>[entry["task_overruns"]]</td></tr>"
	if(!length(scores))
		output += "<tr><td colspan='14'>Задачи ещё не поступали.</td></tr>"
	output += "</table></div>"
	var/list/tasks = report["tasks"]
	output += "<h3>Текущие задачи: [length(tasks)] из [report["pending"] + report["running"]]</h3><p>Показаны выполняющиеся задачи, затем самые старые ожидающие. «Возраст» — время текущего исполнения либо ожидания по состоянию строки; «последний запрос» — время с последнего объединённого запроса.</p>"
	output += "<div class='netrun-task-scroll'><table class='netrun-task-stats'><tr><th>Ключ</th><th>Тип</th><th>Тип цели</th><th>Состояние</th><th>Приоритет</th><th>Ввод игрока</th><th>Возраст, с</th><th>Последний запрос, с</th><th>Повтор запрошен</th></tr>"
	for(var/list/entry as anything in tasks)
		var/state = entry["state"] == "running" ? "выполняется" : "ожидает"
		output += "<tr><td class='identity'>[html_encode(entry["key"])]</td><td class='identity'>[html_encode(entry["kind"])]</td><td class='identity'>[html_encode(entry["target_type"])]</td><td>[state]</td><td>[entry["priority"]]</td><td>[entry["interactive"] ? "да" : "нет"]</td><td>[round(entry["wait_ds"] / (1 SECONDS), 0.1)]</td><td>[round(entry["last_request_age_ds"] / (1 SECONDS), 0.1)]</td><td>[entry["rerun"] ? "да" : "нет"]</td></tr>"
	if(!length(tasks))
		output += "<tr><td colspan='9'>Очередь пуста.</td></tr>"
	output += "</table></div>"
	return jointext(output, "")
