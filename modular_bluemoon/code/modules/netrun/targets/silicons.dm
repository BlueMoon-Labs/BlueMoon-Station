// MARK: Силиконы в сети - киборги и ИИ (механика игры SS13)

// MARK: Киборги

/mob/living/silicon/robot/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/netrun_node, NETRUN_NODE_BORG, list("borg_lockdown", "reboot"), 3, list(ACCESS_ROBOTICS))

/mob/living/silicon/robot/netrun_online(remote = TRUE)
	return stat != DEAD && !low_power_mode

/mob/living/silicon/robot/netrun_name()
	return name

/mob/living/silicon/robot/netrun_status()
	. = list()
	. += "Состояние: [stat == DEAD ? "не отвечает" : locked_down ? "ЗАБЛОКИРОВАН" : "активен"]"
	if(cell)
		. += "Ячейка: [round(cell.percent())]%"
	if(module)
		. += "Модуль: [module.name]"

/datum/netrun_command/borg_lockdown
	id = "borg_lockdown"
	name = "Блокировка шасси"
	desc = "Удалённо заблокировать или разблокировать киборга."
	access = NETRUN_ACCESS_ROOT
	icon = "lock"
	trace = 9
	danger = TRUE

/datum/netrun_command/borg_lockdown/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	var/mob/living/silicon/robot/borg = node.parent
	borg.SetLockdown(!borg.locked_down)
	to_chat(borg, span_userdanger("Внешняя команда: система [borg.locked_down ? "заблокирована" : "разблокирована"]!"))
	return "Киборг [borg.locked_down ? "заблокирован" : "разблокирован"]."

// MARK: ИИ

/mob/living/silicon/ai/Initialize(mapload, datum/ai_laws/L, mob/target_ai)
	. = ..()
	if(. == INITIALIZE_HINT_QDEL)
		return
	AddComponent(/datum/component/netrun_node, NETRUN_NODE_AI, list("ai_jam"), 5, list(ACCESS_AI_UPLOAD))
	initialize_netrun_access()

/mob/living/silicon/ai/Destroy()
	destroy_netrun_access()
	return ..()

/mob/living/silicon/ai/netrun_online(remote = TRUE)
	return stat != DEAD

/mob/living/silicon/ai/netrun_name()
	return name

/mob/living/silicon/ai/netrun_status()
	. = list()
	. += "Ядро: [stat == DEAD ? "не отвечает" : control_disabled ? "ПОМЕХИ" : "активно"]"
	. += "Подключено киборгов: [length(connected_robots)]"

/datum/netrun_command/ai_jam
	id = "ai_jam"
	name = "Глушение ядра"
	desc = "Забить канал ядра ИИ помехами: 10 секунд оно не сможет взаимодействовать с системами."
	access = NETRUN_ACCESS_ROOT
	icon = "tower-broadcast"
	trace = 14
	danger = TRUE

/datum/netrun_command/ai_jam/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	var/mob/living/silicon/ai/ai = node.parent
	if(ai.control_disabled)
		return "Канал ядра уже заглушён."
	ai.control_disabled = TRUE
	to_chat(ai, span_userdanger("Канал управления забит помехами! Взаимодействие с системами недоступно."))
	addtimer(CALLBACK(src, PROC_REF(clear_jam), ai), 10 SECONDS)
	return "Канал ядра ИИ заглушён на 10 секунд."

/datum/netrun_command/ai_jam/proc/clear_jam(mob/living/silicon/ai/ai)
	if(QDELETED(ai))
		return
	ai.control_disabled = FALSE
	to_chat(ai, span_notice("Канал управления очищен от помех."))
