// MARK: Модульные компьютеры как узлы сети
//
// Консоли и ноутбуки становятся узлами: их видно в сети, можно снять состояние, посмотреть
// запущенные программы и, с достаточным доступом, закрыть программу или выключить машину.
// Карманные устройства тоже доступны как узлы; исключение — виртуальный КПК сущности.

/obj/item/modular_computer
	/// Регистрировать ли устройство как узел сети
	var/netrun_nodeable = TRUE

/obj/item/modular_computer/Initialize(mapload)
	. = ..()
	if(netrun_nodeable)
		AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL, list("pc_programs", "pc_print", "pc_terminate", "pc_shutdown"), 1, list())

/obj/item/modular_computer/netrun_online(remote = TRUE)
	return enabled

/obj/item/modular_computer/netrun_status()
	. = list()
	. += "Питание: [enabled ? "включено" : "выключено"]"
	if(active_program)
		. += "Активная программа: [active_program.filedesc]"
	if(LAZYLEN(idle_threads))
		var/list/bg = list()
		for(var/datum/computer_file/program/P as anything in idle_threads)
			bg += P.filedesc
		. += "Фоновые: [jointext(bg, ", ")]"
	var/obj/item/computer_hardware/card_slot/card = all_components[MC_CARD]
	var/obj/item/card/id/id = card?.GetID()
	if(id)
		. += "ID в слоте: [id.registered_name || "без имени"]"

// Ноутбуки - полноценные узлы
/obj/item/modular_computer/laptop
	netrun_nodeable = TRUE

// Плата консоли представляет корпус машины
/obj/item/modular_computer/processor
	netrun_nodeable = TRUE

/obj/item/modular_computer/processor/netrun_name()
	return physical ? physical.name : ..()

// Виртуальный КПК сущности узлом быть не должен
/obj/item/modular_computer/pda/netrun
	netrun_nodeable = FALSE

/obj/item/modular_computer/pda/silicon/pai
	netrun_nodeable = FALSE

// MARK: Команды

/datum/netrun_command/pc_programs
	id = "pc_programs"
	read_only = TRUE
	name = "Список программ"
	desc = "Показать установленные и запущенные программы."
	access = NETRUN_ACCESS_USER
	icon = "list"
	trace = 2
	works_offline = TRUE

/datum/netrun_command/pc_programs/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	var/obj/item/modular_computer/computer = node.parent
	var/list/lines = list()
	for(var/datum/computer_file/program/P in computer.get_all_files())
		var/state = (P == computer.active_program) ? " (активна)" : (P in computer.idle_threads) ? " (фон)" : ""
		lines += "[P.filedesc] ([P.filename])[state]"
	if(!length(lines))
		return "Программы не найдены."
	return "Программы [node.get_name()]:\n[jointext(lines, "\n")]"

/datum/netrun_command/pc_terminate
	id = "pc_terminate"
	name = "Закрыть программу"
	desc = "Принудительно закрыть активную программу на устройстве."
	access = NETRUN_ACCESS_ROOT
	icon = "window-close"
	trace = 5
	danger = TRUE

/datum/netrun_command/pc_terminate/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	var/obj/item/modular_computer/computer = node.parent
	if(!computer.active_program)
		return "Активных программ нет."
	var/closed = computer.active_program.filedesc
	computer.active_program.kill_program(forced = TRUE)
	computer.active_program = null
	computer.update_appearance()
	return "Программа «[closed]» закрыта."

/datum/netrun_command/pc_shutdown
	id = "pc_shutdown"
	name = "Выключить устройство"
	desc = "Завершить работу выбранного модульного компьютера и его программ."
	help = "Устройство отключается штатным способом. После выключения оно перестанет отвечать как сетевой узел; для запуска нужен физический доступ к кнопке питания."
	access = NETRUN_ACCESS_ROOT
	icon = "power-off"
	trace = 6
	danger = TRUE

/datum/netrun_command/pc_shutdown/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	var/obj/item/modular_computer/computer = node.parent
	if(!computer.enabled)
		return "Устройство уже выключено."
	computer.shutdown_computer()
	return "Устройство выключено."


/datum/netrun_command/pc_print
	id = "pc_print"
	name = "Печать файла"
	desc = "Распечатать выбранный текст или фотографию из памяти либо шарда на принтере устройства."
	help = "Сначала выберите файл в хранилище терминала. Нужен установленный исправный принтер и бумага; каждый лист или снимок расходует один лист. Результат появляется возле компьютера."
	access = NETRUN_ACCESS_USER
	icon = "print"
	trace = 3

/datum/netrun_command/pc_print/execute(datum/component/netrun_node/node, datum/netrun_console/console, arg, datum/netrun_request/request)
	var/obj/item/modular_computer/computer = node.parent
	var/obj/item/computer_hardware/printer/printer = computer.all_components[MC_PRINT]
	if(!printer)
		return "В устройстве нет принтера."
	var/datum/netrun_file/doc = console.selected_local_file(null, request)
	if(!doc)
		return "Выберите текстовый файл или фотографию в памяти либо на шарде."
	var/printed = FALSE
	if(doc.kind == NETRUN_FILE_TEXT)
		printed = printer.print_text(replacetext(html_encode(doc.content), "\n", "<br>"), doc.name)
	else if(doc.kind == NETRUN_FILE_PHOTO && doc.picture)
		printed = printer.print_picture(doc.picture, doc.name)
	else
		return "Этот тип файла нельзя напечатать."
	if(!printed)
		return "Печать не удалась (нет бумаги или принтер неисправен)."
	return "Отправлено на печать: [doc.name]."
