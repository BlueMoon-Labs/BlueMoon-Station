// MARK: Серверы РнД как узлы сети
//
// Сервер исследований становится узлом: можно снять сводку (сеть, очки, число открытых узлов),
// слить часть очков исследований себе в хранилище (кража) и временно обрушить его доход.

/obj/machinery/rnd/server/LateInitialize()
	. = ..()
	AddComponent(/datum/component/netrun_node, NETRUN_NODE_SERVER, list("rnd_report", "rnd_nodes", "rnd_siphon", "rnd_restore", "rnd_grab", "rnd_push", "rnd_choke"), 3, list(ACCESS_RD))

/obj/machinery/rnd/server/netrun_online(remote = TRUE)
	return working && !(machine_stat & (NOPOWER | BROKEN))

/obj/machinery/rnd/server/proc/netrun_research_network_label()
	var/network_label = research_network_id()
	switch(network_label)
		if(RND_NETWORK_STATION)
			network_label = "Научная сеть Нанотрейзен ([RND_NETWORK_STATION])"
		if(RND_NETWORK_SYNDICATE)
			network_label = "Научная сеть Синдиката ([RND_NETWORK_SYNDICATE])"
		if(RND_NETWORK_TARKON)
			network_label = "Научная сеть Тарков ([RND_NETWORK_TARKON])"
		if(RND_NETWORK_INTEQ)
			network_label = "Научная сеть ИнтекЮ ([RND_NETWORK_INTEQ])"
		if(RND_NETWORK_AUTO)
			network_label = "Автономная сеть [server_id]"
	return network_label

/obj/machinery/rnd/server/netrun_status()
	. = list()
	. += "Состояние: [working ? "работает" : "простой"]"
	. += "Сеть РнД: [netrun_research_network_label()]"
	if(stored_research)
		var/total = 0
		for(var/point_type in stored_research.research_points)
			total += stored_research.research_points[point_type]
		. += "Очки в банке: [round(total)]"

/datum/netrun_command/rnd_report
	id = "rnd_report"
	read_only = TRUE
	name = "Сводка исследований"
	desc = "Показать сеть, запас очков и число открытых узлов техвеба."
	access = NETRUN_ACCESS_USER
	icon = "flask"
	trace = 3
	works_offline = TRUE

/datum/netrun_command/rnd_report/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	var/obj/machinery/rnd/server/server = node.parent
	if(!server.stored_research)
		return "Техвеб не подключён."
	var/list/lines = list("Сеть: [server.netrun_research_network_label()]", "Открыто узлов: [length(server.stored_research.researched_nodes)]")
	for(var/point_type in server.stored_research.research_points)
		lines += "[point_type]: [round(server.stored_research.research_points[point_type])]"
	return jointext(lines, "\n")

/datum/netrun_command/rnd_siphon
	id = "rnd_siphon"
	name = "Слить данные"
	desc = "Изъять часть очков исследований в файл для одноразовой загрузки командой rnd_restore."
	access = NETRUN_ACCESS_ROOT
	icon = "download"
	trace = 10
	danger = TRUE

/datum/netrun_command/rnd_siphon/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	var/obj/machinery/rnd/server/server = node.parent
	if(!server.stored_research)
		return "Техвеб не подключён."
	var/list/stolen = list()
	var/total = 0
	for(var/point_type in server.stored_research.research_points)
		var/amount = round(server.stored_research.research_points[point_type] * 0.25)
		if(amount <= 0)
			continue
		stolen[point_type] = amount
		total += amount
	if(!total)
		return "В банке сети нечего сливать."
	var/list/report = list()
	for(var/point_type in stolen)
		report += "[point_type]: [stolen[point_type]]"
	var/datum/netrun_file/research_points/file = new("rnd_[server.server_id].dat", NETRUN_FILE_TEXT, "Выгрузка исследований с сервера [server.netrun_research_network_label()]:\n[jointext(report, "\n")]\nВыберите этот файл и выполните rnd_restore на сервере-получателе. Все копии используют один запас очков.", 2)
	file.payload = new(stolen)
	console.stamp_data_export(file, node, "research", stolen)
	if(!console.store_file(file))
		qdel(file)
		return "Нет места в хранилище. Очки не списаны."
	server.stored_research.remove_point_list(stolen)
	console.inventory.selected_file_uid = file.uid
	return "Слито очков: [total]. Данные записаны в хранилище."

/// Copies share one authoritative balance. Duplicating or editing a report cannot mint points.
/datum/netrun_research_payload
	var/list/points

/datum/netrun_research_payload/New(list/stolen)
	points = stolen.Copy()

/datum/netrun_research_payload/proc/consume()
	. = points
	points = null

/datum/netrun_file/research_points
	var/datum/netrun_research_payload/payload

/datum/netrun_file/research_points/copy()
	var/datum/netrun_file/research_points/result = new(name, kind, content, size, network_id)
	result.payload = payload
	result.data_receipt = data_receipt
	return result

/datum/netrun_file/research_points/ui_metadata_stable()
	return FALSE

/datum/netrun_file/research_points/ui_entry(selected_uid)
	. = ..()
	.["preview"] = length(payload?.points) ? "Очки исследований: выберите файл и выполните rnd_restore на сервере." : "Очки исследований уже загружены; все копии выгрузки погашены."

/datum/netrun_command/rnd_restore
	id = "rnd_restore"
	name = "Загрузить очки"
	desc = "Перенести изъятые очки из выбранного файла .dat в техвеб этого сервера."
	help = "Выберите выгрузку rnd_siphon в памяти или на шарде. Запас очков общий для всех копий и расходуется один раз; повторная загрузка ничего не добавляет."
	access = NETRUN_ACCESS_ROOT
	icon = "upload"
	trace = 10
	danger = TRUE

/datum/netrun_command/rnd_restore/execute(datum/component/netrun_node/node, datum/netrun_console/console, arg, datum/netrun_request/request)
	var/obj/machinery/rnd/server/server = node.parent
	if(!server.stored_research)
		return "Техвеб не подключён. Очки сохранены в файле."
	var/datum/netrun_file/research_points/source = console.selected_local_file(NETRUN_FILE_TEXT, request)
	if(!istype(source))
		return "Выберите выгрузку очков rnd_siphon в памяти или на шарде."
	var/list/points = source.payload?.consume()
	if(!length(points))
		return "Очки из этой выгрузки уже загружены. Все копии используют один запас."
	server.stored_research.add_point_list(points, income = FALSE)
	var/total = 0
	for(var/point_type in points)
		total += points[point_type]
	return "В техвеб сервера загружено очков: [total]. Выгрузка и все её копии погашены."

/datum/netrun_command/rnd_choke
	id = "rnd_choke"
	name = "Заглушить сервер"
	desc = "Сбить сервер исследований в простой на 30 секунд - он перестаёт приносить доход."
	access = NETRUN_ACCESS_ROOT
	icon = "hourglass-half"
	trace = 8
	danger = TRUE

/datum/netrun_command/rnd_choke/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	var/obj/machinery/rnd/server/server = node.parent
	if(!server.working)
		return "Сервер и так в простое."
	server.working = FALSE
	addtimer(CALLBACK(server, TYPE_PROC_REF(/obj/machinery/rnd/server, refresh_working)), 30 SECONDS)
	return "Сервер заглушён на 30 секунд."

// MARK: Кража и выгрузка узлов techweb

/datum/netrun_command/rnd_nodes
	id = "rnd_nodes"
	read_only = TRUE
	name = "Список технологий"
	desc = "Показать открытые узлы техвеба сервера."
	access = NETRUN_ACCESS_USER
	icon = "sitemap"
	trace = 3
	works_offline = TRUE

/datum/netrun_command/rnd_nodes/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	var/obj/machinery/rnd/server/server = node.parent
	if(!server.stored_research)
		return "Техвеб не подключён."
	var/list/names = list()
	var/count = 0
	for(var/node_id in server.stored_research.researched_nodes)
		count++
		if(count > 14)
			continue
		var/datum/techweb_node/tnode = SSresearch.techweb_nodes[node_id]
		if(tnode)
			names += tnode.display_name
	return "Открыто узлов: [length(server.stored_research.researched_nodes)]\n[jointext(names, "\n")][count > 14 ? "\n…" : ""]"

/datum/netrun_command/rnd_grab
	id = "rnd_grab"
	name = "Скопировать техвеб"
	desc = "Снять дамп всех открытых узлов техвеба в файл хранилища."
	access = NETRUN_ACCESS_ROOT
	icon = "download"
	trace = 9
	danger = TRUE

/datum/netrun_command/rnd_grab/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	var/obj/machinery/rnd/server/server = node.parent
	if(!server.stored_research || !length(server.stored_research.researched_nodes))
		return "Нечего копировать."
	var/list/ids = list()
	for(var/node_id in server.stored_research.researched_nodes)
		ids += node_id
	var/datum/netrun_file/file = new("techweb_[server.server_id].web", NETRUN_FILE_TECHWEB, jointext(ids, ";"), max(1, round(length(ids) / 20)))
	console.stamp_data_export(file, node, "technology", ids)
	if(!console.store_file(file))
		qdel(file)
		return "Нет места в хранилище."
	console.inventory.selected_file_uid = file.uid
	return "Снят дамп техвеба: [length(ids)] узлов в [file.name]."

/datum/netrun_command/rnd_push
	id = "rnd_push"
	name = "Залить техвеб"
	desc = "Разблокировать на этом сервере узлы из сохранённого дампа техвеба."
	help = "Сначала выберите файл дампа техвеба в памяти или на шарде. Импорт добавляет ещё неизвестные технологии в текущую сеть сервера; файл остаётся на носителе. Файл привязки .link используется отдельной командой «Привязать из файла»."
	access = NETRUN_ACCESS_ROOT
	icon = "upload"
	trace = 11
	danger = TRUE

/datum/netrun_command/rnd_push/execute(datum/component/netrun_node/node, datum/netrun_console/console, arg, datum/netrun_request/request)
	var/obj/machinery/rnd/server/server = node.parent
	if(!server.stored_research)
		return "Техвеб не подключён."
	var/datum/netrun_file/source = console.selected_local_file(NETRUN_FILE_TECHWEB, request)
	if(!source)
		return "Выберите дамп техвеба в памяти или на шарде."
	var/count = 0
	for(var/node_id in splittext(source.content, ";"))
		if(!SSresearch.techweb_nodes[node_id])
			continue
		if(server.stored_research.researched_nodes[node_id])
			continue
		if(server.stored_research.research_node_id(node_id, force = TRUE, auto_update_points = FALSE))
			count++
	return "Залито узлов техвеба: [count]."
