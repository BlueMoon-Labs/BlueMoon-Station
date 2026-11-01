// MARK: Привязка техвеба к машинам (через /datum/component/techweb_holder)
//
// Любая машина-узел с компонентом techweb_holder может быть источником (скопировать её
// исследовательскую сеть в файл) и приёмником (привязать к выбранному файлу). Так можно,
// например, увести станционный техвеб с РнД-консоли и подцепить к нему автономный сервер.

/// Команды появляются у любого узла, чей атом держит techweb_holder
/atom/proc/netrun_has_techweb()
	return !isnull(GetComponent(/datum/component/techweb_holder))

/atom/netrun_extra_commands()
	. = ..()
	if(netrun_has_techweb())
		. += list("web_copy", "web_bind")

/proc/netrun_atom_techweb(atom/A)
	var/datum/component/techweb_holder/holder = A.GetComponent(/datum/component/techweb_holder)
	return holder?.linked_techweb

/proc/netrun_node_techweb(datum/component/netrun_node/node)
	return netrun_atom_techweb(node.parent)

/datum/netrun_command/web_copy
	id = "web_copy"
	name = "Скопировать привязку"
	desc = "Сохранить доступ к исследовательской сети отдельным переносимым файлом."
	access = NETRUN_ACCESS_USER
	icon = "clone"
	trace = 5

/datum/netrun_command/web_copy/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	var/datum/techweb/web = netrun_node_techweb(node)
	if(!web)
		return "Машина не подключена к исследовательской сети."
	var/datum/netrun_file/file = new(netrun_file_name("[web.organization].link", "research.link"), NETRUN_FILE_TECHWEB_LINK, web.organization, 1)
	file.techweb_ref = WEAKREF(web)
	if(!console.store_file(file))
		qdel(file)
		return "Нет места для файла привязки."
	console.inventory.selected_file_uid = file.uid
	return "Привязка сохранена в [file.name]. Файл можно скопировать на шард и перенести."

/datum/netrun_command/web_bind
	id = "web_bind"
	name = "Привязать из файла"
	desc = "Подключить машину к сети из выбранного файла привязки в памяти или на шарде."
	access = NETRUN_ACCESS_ROOT
	icon = "link"
	trace = 10
	danger = TRUE

/datum/netrun_command/web_bind/execute(datum/component/netrun_node/node, datum/netrun_console/console, arg, datum/netrun_request/request)
	var/datum/netrun_file/file = console.selected_local_file(NETRUN_FILE_TECHWEB_LINK, request)
	if(!file)
		return "Выберите файл привязки исследовательской сети в памяти или на шарде."
	var/datum/techweb/web = file.techweb_ref?.resolve()
	if(!web)
		return "Сеть из выбранного файла больше не существует."
	var/atom/A = node.parent
	if(!A.netrun_has_techweb())
		return "Машина не поддерживает исследовательскую сеть."
	if(netrun_node_techweb(node) == web)
		return "Машина уже привязана к этой сети."
	SEND_SIGNAL(A, COMSIG_ATOM_SET_TECHWEB, web)
	if(netrun_node_techweb(node) != web)
		return "Машина не приняла привязку."
	return "Машина привязана к сети [web.organization]."

// MARK: Узлы у исследовательских машин

/obj/machinery/computer/rdconsole/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL, list(), 2, list(ACCESS_RD))

/obj/machinery/computer/rdconsole/netrun_status()
	var/datum/techweb/web = netrun_atom_techweb(src)
	return list("Исследовательская сеть: [web ? web.organization : "нет"]")

/obj/machinery/rnd/production/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/netrun_node, NETRUN_NODE_SERVER, list(), 2, list(ACCESS_RD))

/obj/machinery/rnd/production/netrun_status()
	var/datum/techweb/web = netrun_atom_techweb(src)
	return list("Исследовательская сеть: [web ? web.organization : "нет"]")
