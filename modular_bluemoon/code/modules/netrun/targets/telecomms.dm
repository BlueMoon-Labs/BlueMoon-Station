// MARK: Телекоммуникации как узлы сети
//
// Машины телекомов становятся узлами: их видно в сети, можно снять состояние, отключить
// (рвёт обработку сигналов) и - у серверов связи - прочитать перехваченные логи переговоров.

/obj/machinery/telecomms/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/netrun_node, NETRUN_NODE_SERVER, netrun_telecomms_hacks(), 3, list(ACCESS_TCOMSAT))

/// Базовый набор команд телеком-машины
/obj/machinery/telecomms/proc/netrun_telecomms_hacks()
	return list("tcomm_toggle")

/obj/machinery/telecomms/netrun_online(remote = TRUE)
	return on

/obj/machinery/telecomms/netrun_status()
	. = list()
	. += "Питание: [on ? "включено" : "выключено"]"
	. += "Сеть: [network], ID: [id]"
	. += "Трафик: [traffic] ГБ"

/datum/netrun_command/tcomm_toggle
	id = "tcomm_toggle"
	name = "Питание узла"
	desc = "Включить или выключить машину телекоммуникаций. Выключенная не обрабатывает сигналы."
	access = NETRUN_ACCESS_ROOT
	icon = "tower-cell"
	trace = 7
	danger = TRUE

/datum/netrun_command/tcomm_toggle/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	var/obj/machinery/telecomms/machine = node.parent
	machine.toggled = !machine.toggled
	machine.update_power()
	machine.update_icon()
	return "Узел [machine.toggled ? "включён" : "выключен"]."

// MARK: Серверы связи - перехват логов переговоров

/obj/machinery/telecomms/server/netrun_telecomms_hacks()
	return ..() + list("tcomm_logs", "tcomm_wipe")

/datum/netrun_command/tcomm_logs
	id = "tcomm_logs"
	read_only = TRUE
	name = "Логи переговоров"
	desc = "Прочитать перехваченные сервером связи записи сообщений."
	access = NETRUN_ACCESS_USER
	icon = "comment-dots"
	trace = 4
	works_offline = TRUE

/datum/netrun_command/tcomm_logs/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	var/obj/machinery/telecomms/server/server = node.parent
	if(!LAZYLEN(server.log_entries))
		return "Журнал сервера пуст."
	var/list/lines = list()
	var/count = 0
	for(var/datum/comm_log_entry/entry as anything in server.log_entries)
		if(count++ >= length(server.log_entries) - 12)
			var/name = entry.parameters["name"] || "неизвестно"
			var/message = entry.parameters["message"] || ""
			lines += "[name]: «[message]»"
	return "Перехват [server.id]:\n[jointext(lines, "\n")]"

/datum/netrun_command/tcomm_wipe
	id = "tcomm_wipe"
	name = "Стереть логи"
	desc = "Удалить журнал перехваченных сообщений сервера связи."
	access = NETRUN_ACCESS_ROOT
	icon = "eraser"
	trace = 5
	danger = TRUE
	works_offline = TRUE

/datum/netrun_command/tcomm_wipe/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	var/obj/machinery/telecomms/server/server = node.parent
	var/count = LAZYLEN(server.log_entries)
	server.log_entries.Cut()
	return "Удалено записей: [count]."

// MARK: Сервер сообщений - пароль и перехват ПДА-сообщений

/obj/machinery/telecomms/message_server/netrun_telecomms_hacks()
	return ..() + list("pda_password", "pda_logs")

/datum/netrun_command/pda_password
	id = "pda_password"
	name = "Пароль сервера"
	desc = "Извлечь пароль сервера сообщений, открывающий чтение перехваченных ПДА-сообщений."
	help = "Пароль хранится на самом сервере. Знание пароля сохраняется в этой сессии и открывает команду чтения сообщений."
	access = NETRUN_ACCESS_ROOT
	icon = "key"
	trace = 6
	danger = TRUE
	works_offline = TRUE

/datum/netrun_command/pda_password/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	var/obj/machinery/telecomms/message_server/server = node.parent
	if(!istype(server))
		return "Это не сервер сообщений."
	console.learn_server_password(node.address)
	return "Пароль сервера сообщений извлечён: [server.decryptkey]. Доступно чтение перехваченных сообщений."

/datum/netrun_command/pda_logs
	id = "pda_logs"
	read_only = TRUE
	name = "Сообщения ПДА"
	desc = "Прочитать перехваченные сервером ПДА-сообщения. Требуется пароль сервера."
	help = "Без извлечённого пароля сервера сообщения зашифрованы. Сначала примените «Пароль сервера» (ROOT)."
	access = NETRUN_ACCESS_USER
	icon = "comment-sms"
	trace = 4
	works_offline = TRUE

/datum/netrun_command/pda_logs/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	var/obj/machinery/telecomms/message_server/server = node.parent
	if(!istype(server))
		return "Это не сервер сообщений."
	if(!console.knows_server_password(node.address))
		return "Сообщения зашифрованы. Сначала извлеките пароль сервера (ROOT: «Пароль сервера»)."
	if(!length(server.pda_msgs))
		return "Перехваченных сообщений нет."
	var/list/lines = list()
	var/start = max(1, length(server.pda_msgs) - 20)
	for(var/i in start to length(server.pda_msgs))
		var/datum/data_pda_msg/msg = server.pda_msgs[i]
		lines += "[msg.sender] -> [msg.recipient]: [msg.message]"
	return "Перехваченные сообщения ([length(lines)]):\n[jointext(lines, "\n")]"
