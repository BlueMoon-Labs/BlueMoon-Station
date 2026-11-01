// MARK: Шлюзы

/obj/machinery/door/airlock/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/netrun_node, NETRUN_NODE_AIRLOCK, list("door_open", "door_bolt", "door_emergency", "door_shock", "reboot"), 1)

/obj/machinery/door/airlock/netrun_online(remote = TRUE)
	if(!hasPower())
		return FALSE
	return remote ? canAIControl() : TRUE

/obj/machinery/door/airlock/netrun_status()
	. = list()
	. += "Створки: [density ? "закрыты" : "открыты"][welded ? ", заварены" : ""]"
	. += "Болты: [locked ? "опущены" : "подняты"]"
	. += "Аварийный доступ: [emergency ? "включён" : "выключен"]"
	if(isElectrified())
		. += "ВНИМАНИЕ: на створках напряжение"

/datum/netrun_command/door_open
	id = "door_open"
	name = "Открыть/закрыть"
	desc = "Открыть закрытый шлюз или закрыть открытый."
	help = "Опущенные болты и сварка блокируют движение створок. Сначала поднимите болты отдельной командой; сварку нужно убрать физически."
	icon = "door-open"
	trace = 4

/datum/netrun_command/door_open/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	var/obj/machinery/door/airlock/door = node.parent
	if(door.locked || door.welded)
		console.log_line("Створки заблокированы.", "bad")
		return
	if(door.density)
		INVOKE_ASYNC(door, TYPE_PROC_REF(/obj/machinery/door, open))
		return "Шлюз открывается."
	INVOKE_ASYNC(door, TYPE_PROC_REF(/obj/machinery/door, close))
	return "Шлюз закрывается."

/datum/netrun_command/door_bolt
	id = "door_bolt"
	name = "Болты"
	desc = "Поднять опущенные болты шлюза или опустить поднятые."
	help = "Команда меняет запирание. Чтобы после снятия болтов раздвинуть створки, отдельно выполните «Открыть/закрыть»."
	icon = "lock"
	trace = 6

/datum/netrun_command/door_bolt/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	var/obj/machinery/door/airlock/door = node.parent
	if(door.locked)
		door.unbolt()
		return "Болты подняты."
	door.bolt()
	return "Болты опущены."

/datum/netrun_command/door_emergency
	id = "door_emergency"
	name = "Аварийный доступ"
	desc = "Включить или выключить аварийный доступ через шлюз."
	help = "Меняет штатный аварийный режим двери. Текущее состояние видно в карточке шлюза; повторный вызов отменяет режим."
	icon = "triangle-exclamation"
	trace = 5

/datum/netrun_command/door_emergency/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	var/obj/machinery/door/airlock/door = node.parent
	door.toggle_emergency()
	return "Аварийный доступ [door.emergency ? "включён" : "выключен"]."

/datum/netrun_command/door_shock
	id = "door_shock"
	name = "Подать напряжение"
	desc = "Электрифицировать створки на 30 секунд."
	access = NETRUN_ACCESS_ROOT
	icon = "bolt"
	trace = 8
	danger = TRUE

/datum/netrun_command/door_shock/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	var/obj/machinery/door/airlock/door = node.parent
	if(door.wires.is_cut(WIRE_SHOCK))
		console.log_line("Цепь электрификации повреждена.", "bad")
		return
	if(door.isElectrified())
		door.set_electrified(MACHINE_NOT_ELECTRIFIED, console.operator)
		return "Напряжение снято."
	door.set_electrified(30, console.operator)
	return "Створки под напряжением на 30 секунд."
