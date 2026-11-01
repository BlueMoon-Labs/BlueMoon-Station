// MARK: Генерация файлов по содержимому узла
//
// Любой узел может «выгрузить» в хранилище консоли файлы, отражающие то, что в нём есть:
// журналы, данные сети, ключи доступа, дампы исследований и т.п. Машины дополняют список
// через netrun_generate_files().

/// Файлы, которые можно вытащить из узла. Возврат - список /datum/netrun_file.
/atom/proc/netrun_generate_files(datum/component/netrun_node/node, datum/netrun_console/console)
	. = list()
	// Журнал самого узла
	if(LAZYLEN(node.logs))
		. += new /datum/netrun_file(netrun_file_name("[node.address].log", "node.log"), NETRUN_FILE_TEXT, jointext(node.logs, "\n"))
	// Данные сети: код, защита, список узлов
	if(node.network)
		var/datum/netrun_network/net = node.network
		var/list/lines = list("Сеть: [net.name] ([net.code])", "Защита: [net.security]", "Узлов: [length(net.nodes)]", "")
		for(var/datum/component/netrun_node/other as anything in net.nodes)
			lines += "[other.address] [other.get_name()] ([other.node_type])"
		. += new /datum/netrun_file(netrun_file_name("[net.code].netdata", "network.netdata"), NETRUN_FILE_TEXT, jointext(lines, "\n"))

/datum/netrun_command/extract
	id = "extract"
	name = "Выгрузить данные"
	desc = "Собрать из узла доступные данные (журнал, карту сети, содержимое) файлами в память."
	access = NETRUN_ACCESS_USER
	icon = "file-export"
	trace = 4

/datum/netrun_command/extract/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	var/atom/A = node.parent
	var/list/files = A.netrun_generate_files(node, console)
	if(!length(files))
		return "В узле нет данных для выгрузки."
	var/stored = 0
	for(var/datum/netrun_file/file as anything in files)
		if(console.store_file(file))
			stored++
		else
			qdel(file)
	if(!stored)
		return "Нет места в памяти для выгрузки."
	var/illegal = console.legit_node_level(node) < NETRUN_ACCESS_USER
	if(illegal)
		console.add_trace(3 * node.get_security())
	return "Выгружено файлов: [stored]."

// MARK: Доп. данные конкретных машин

/obj/machinery/power/apc/netrun_generate_files(datum/component/netrun_node/node, datum/netrun_console/console)
	. = ..()
	var/list/lines = list(
		"APC: [area?.name]",
		"Рубильник: [operating ? "включён" : "выключен"]",
		"Ячейка: [cell ? "[round(cell.percent())]%" : "нет"]",
		"Каналы: свет [lighting >= 2 ? "вкл" : "выкл"], оборудование [equipment >= 2 ? "вкл" : "выкл"], среда [environ >= 2 ? "вкл" : "выкл"]",
	)
	. += new /datum/netrun_file(netrun_file_name("[node.address].powerlog", "power.log"), NETRUN_FILE_TEXT, jointext(lines, "\n"))

/obj/machinery/camera/netrun_generate_files(datum/component/netrun_node/node, datum/netrun_console/console)
	. = ..()
	var/turf/T = get_turf(src)
	var/list/lines = list("Камера: [c_tag]", "Сеть наблюдения: [english_list(network)]", "Положение: [T ? "[T.x],[T.y],[T.z]" : "?"]")
	. += new /datum/netrun_file(netrun_file_name("[node.address].feedlog", "feed.log"), NETRUN_FILE_TEXT, jointext(lines, "\n"))

/// Сервер отдаёт также копию ключа своей сети - находка для нетраннера
/obj/machinery/netrun_server/netrun_generate_files(datum/component/netrun_node/node, datum/netrun_console/console)
	. = ..()
	if(node.network)
		. += new /datum/netrun_file(netrun_file_name("[node.network.id].key", "lan.key"), NETRUN_FILE_KEY, node.network.passcode, 1, node.network.id)
