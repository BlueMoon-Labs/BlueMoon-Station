// MARK: Прочие сетевые устройства
//
// Оконные двери и мулботы уже несут ntnet-интерфейс и слушают пакеты. Подключаем их к сети,
// чтобы они были видны на карте и управлялись единообразно.

// MARK: Оконные двери

/obj/machinery/door/window/Initialize(mapload, set_dir)
	. = ..()
	AddComponent(/datum/component/netrun_node, NETRUN_NODE_AIRLOCK, list("windoor_open"), 1)

/obj/machinery/door/window/netrun_online(remote = TRUE)
	return hasPower()

/obj/machinery/door/window/netrun_status()
	. = list("Створка: [density ? "закрыта" : "открыта"]")

/datum/netrun_command/windoor_open
	id = "windoor_open"
	name = "Открыть/закрыть"
	desc = "Открыть закрытую оконную дверь или закрыть открытую."
	help = "Команда использует штатный механизм движения створки. Питание и ограничения самой двери продолжают действовать."
	icon = "door-open"
	trace = 4

/datum/netrun_command/windoor_open/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	var/obj/machinery/door/window/windoor = node.parent
	if(windoor.density)
		INVOKE_ASYNC(windoor, TYPE_PROC_REF(/obj/machinery/door/window, open))
		return "Окно открывается."
	INVOKE_ASYNC(windoor, TYPE_PROC_REF(/obj/machinery/door/window, close))
	return "Окно закрывается."

// MARK: Мулботы

/mob/living/simple_animal/bot/mulebot/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/netrun_node, NETRUN_NODE_TURRET, list("mule_stop"), 1, list(ACCESS_CARGO))

/mob/living/simple_animal/bot/mulebot/netrun_online(remote = TRUE)
	return stat != DEAD

/mob/living/simple_animal/bot/mulebot/netrun_status()
	. = list()
	. += "Шасси: [on ? "активно" : "остановлено"]"
	if(load)
		. += "Груз: [load]"

/datum/netrun_command/mule_stop
	id = "mule_stop"
	name = "Запуск/останов"
	desc = "Включить или остановить грузового бота по сети."
	icon = "truck-ramp-box"
	trace = 3

/datum/netrun_command/mule_stop/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	var/mob/living/simple_animal/bot/mulebot/mule = node.parent
	mule.on = !mule.on
	mule.update_icon()
	return "Бот [mule.on ? "запущен" : "остановлен"]."
