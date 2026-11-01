// MARK: Кибернетика носителя как узел сети
//
// Человек виден в сети одним узлом, пока в нём есть кибернетика: кибер-импланты или
// синтетические органы. Набор команд узла собирается из самих органов: каждый тип
// предлагает только то, что вытекает из его собственной механики. Команда адресована
// конкретному органу по слоту (`heart_stop@heart`), поэтому две руки-импланта - две цели.

/obj/item/organ/Insert(mob/living/carbon/organ_mob, special, drop_if_replaced)
	. = ..()
	if(. && owner)
		owner.netrun_refresh_cyber_node()

/obj/item/organ/Remove(special)
	var/mob/living/carbon/prev_owner = owner
	. = ..()
	var/datum/component/netrun_cyber_guard/defense = GetComponent(/datum/component/netrun_cyber_guard)
	QDEL_NULL(defense)
	if(prev_owner && !QDELETED(prev_owner))
		prev_owner.netrun_refresh_cyber_node(removing = src)

/// Кибернетический ли орган (импланты и синтетические органы)
/obj/item/organ/proc/netrun_is_cyber()
	return istype(src, /obj/item/organ/cyberimp) || (organ_flags & ORGAN_SYNTHETIC) || status == ORGAN_ROBOTIC

/// id команд, которые принимает этот орган
/obj/item/organ/proc/netrun_hacks()
	return list()

/// Выполнить команду над органом. Возвращает текст результата или null при неудаче
/obj/item/organ/proc/netrun_hack(id, datum/netrun_console/console)
	return

/// Узел носителя: есть, пока есть кибернетика; список команд - из органов
/mob/living/carbon/proc/netrun_refresh_cyber_node(obj/item/organ/removing)
	netrun_rebuild_cyber_uplinks(removing)
	var/list/command_ids = list()
	var/has_cyber = netrun_has_cyber_uplink(removing)
	for(var/obj/item/organ/organ as anything in internal_organs)
		if(!has_cyber || organ == removing || !organ.netrun_is_cyber())
			continue
		if(!organ.slot)
			continue
		for(var/hack in organ.netrun_hacks())
			command_ids += "[hack]@[organ.slot]"
	var/datum/component/netrun_node/node = GetComponent(/datum/component/netrun_node)
	if(!has_cyber)
		if(node)
			qdel(node)
		netrun_update_firewall_action()
		netrun_refresh_cyber_security()
		return
	if(!node)
		node = AddComponent(/datum/component/netrun_node, NETRUN_NODE_IMPLANT, list(), 2)
	node.command_ids = list("scan", "ping", "probe_location", "countertrace") + command_ids
	netrun_update_firewall_action()
	netrun_refresh_cyber_security()

/mob/living/carbon/netrun_online(remote = TRUE)
	return stat != DEAD && netrun_cyber_uplink_available()

/mob/living/carbon/netrun_status()
	. = list()
	. += "Носитель: [stat == DEAD ? "сигнал потерян" : "сигнал есть"]"
	var/list/parts = list()
	for(var/obj/item/organ/organ as anything in internal_organs)
		if(organ.netrun_is_cyber())
			parts += "[organ.name][organ.netrun_suppressed() ? " (подавлен)" : ""]"
	if(length(parts))
		. += "Кибернетика: [jointext(parts, ", ")]"

// MARK: Базовая команда органа

/datum/netrun_command/organ
	access = NETRUN_ACCESS_USER
	icon = "microchip"

/datum/netrun_command/organ/proc/find_organ(datum/component/netrun_node/node, slot)
	var/mob/living/carbon/host = node.parent
	if(!istype(host) || !slot)
		return
	var/obj/item/organ/organ = host.getorganslot(slot)
	if(host.netrun_cyber_uplink_available() && organ && (id in organ.netrun_hacks()))
		return organ

/datum/netrun_command/organ/display_name(datum/component/netrun_node/node, arg)
	var/obj/item/organ/organ = find_organ(node, arg)
	return organ ? "[organ.name]: [name]" : name

/datum/netrun_command/organ/execute(datum/component/netrun_node/node, datum/netrun_console/console, arg)
	var/obj/item/organ/organ = find_organ(node, arg)
	if(!organ)
		console.log_line("Орган не отвечает.", "bad")
		return
	return organ.netrun_hack(id, console)

// MARK: Подавление кибер-имплантов
//
// Тот же механизм, которым импланты блокируются по уровню тревоги: activate_allowed()
// отказывает, активные функции выключаются через deactivate(), пассивные (on_life) замирают.

/obj/item/organ
	var/netrun_suppressed_until = 0

/obj/item/organ/proc/netrun_suppressed()
	return world.time < netrun_suppressed_until

/obj/item/organ/activate_allowed(datum/action/action, mob/user, silent = FALSE)
	if(netrun_suppressed())
		if(!silent && user)
			to_chat(user, span_warning("[src] не отвечает: сбой сетевого контроллера."))
		return FALSE
	return ..()

/obj/item/organ/cyberimp/netrun_hacks()
	return list("imp_suppress")

/obj/item/organ/cyberimp/netrun_hack(id, datum/netrun_console/console)
	if(id != "imp_suppress")
		return ..()
	netrun_suppressed_until = world.time + 30 SECONDS
	deactivate()
	for(var/datum/action/action in actions)
		action.UpdateButtons(TRUE)
	if(owner)
		to_chat(owner, span_warning("[src] перестаёт отвечать."))
	return "[src] подавлен на 30 секунд."

/datum/netrun_command/organ/imp_suppress
	id = "imp_suppress"
	access = NETRUN_ACCESS_ROOT
	danger = TRUE
	name = "подавить"
	desc = "Заблокировать имплант на 30 секунд: он не активируется, активная функция выключается."
	icon = "ban"
	trace = 8

// MARK: Импланты рук

/obj/item/organ/cyberimp/arm/netrun_hacks()
	return ..() + list("arm_retract")

/obj/item/organ/cyberimp/arm/netrun_hack(id, datum/netrun_console/console)
	if(id != "arm_retract")
		return ..()
	if(!holder)
		return "Модуль и так убран."
	Retract()
	to_chat(owner, span_warning("[src] самопроизвольно складывается!"))
	return "Модуль [src] втянут."

/datum/netrun_command/organ/arm_retract
	id = "arm_retract"
	name = "втянуть модуль"
	desc = "Принудительно сложить выдвинутый инструмент или оружие руки."
	icon = "hand"
	trace = 6

// MARK: Импланты мозга

/obj/item/organ/cyberimp/brain/anti_drop/netrun_hacks()
	return ..() + list("antidrop_release")

/obj/item/organ/cyberimp/brain/anti_drop/netrun_hack(id, datum/netrun_console/console)
	if(id != "antidrop_release")
		return ..()
	if(!active)
		return "Хват и так разжат."
	ui_action_click()
	return "Хват разжат."

/datum/netrun_command/organ/antidrop_release
	id = "antidrop_release"
	name = "разжать хват"
	desc = "Снять фиксацию предметов в руках."
	icon = "hand-holding"
	trace = 6

/obj/item/organ/cyberimp/brain/anti_stun/netrun_hacks()
	return ..() + list("rebooter_fault")

/obj/item/organ/cyberimp/brain/anti_stun/netrun_hack(id, datum/netrun_console/console)
	if(id != "rebooter_fault")
		return ..()
	if(crit_fail)
		return "Ребутер уже в сбое."
	crit_fail = TRUE
	organ_flags |= ORGAN_FAILING
	addtimer(CALLBACK(src, PROC_REF(reboot)), 20 SECONDS)
	return "Ребутер ЦНС в сбое на 20 секунд."

/datum/netrun_command/organ/rebooter_fault
	id = "rebooter_fault"
	access = NETRUN_ACCESS_ROOT
	danger = TRUE
	name = "сбой ребутера"
	desc = "Перевести ребутер ЦНС в аварийный перезапуск."
	icon = "rotate"
	trace = 7

// MARK: Импланты груди

/obj/item/organ/cyberimp/chest/thrusters/netrun_hacks()
	return ..() + list("thrusters_toggle")

/obj/item/organ/cyberimp/chest/thrusters/netrun_hack(id, datum/netrun_console/console)
	if(id != "thrusters_toggle")
		return ..()
	toggle()
	return "Двигатели [on ? "включены" : "выключены"]."

/datum/netrun_command/organ/thrusters_toggle
	id = "thrusters_toggle"
	name = "двигатели"
	desc = "Включить или выключить маневровые двигатели."
	icon = "rocket"
	trace = 6

/obj/item/organ/cyberimp/chest/chem_implant/netrun_hacks()
	return ..() + list("chem_discharge")

/obj/item/organ/cyberimp/chest/chem_implant/netrun_hack(id, datum/netrun_console/console)
	if(id != "chem_discharge")
		return ..()
	charge = 0
	to_chat(owner, span_warning("[src] теряет заряд!"))
	return "Заряд химимпланта сброшен."

/datum/netrun_command/organ/chem_discharge
	id = "chem_discharge"
	name = "сбросить заряд"
	desc = "Обнулить накопленный заряд химического импланта."
	icon = "battery-empty"
	trace = 5

// MARK: Глазные импланты

/obj/item/organ/cyberimp/eyes/hud/netrun_hacks()
	return ..() + list("hud_toggle")

/obj/item/organ/cyberimp/eyes/hud/netrun_hack(id, datum/netrun_console/console)
	if(id != "hud_toggle")
		return ..()
	toggle()
	return "HUD [active ? "включён" : "выключен"]."

/datum/netrun_command/organ/hud_toggle
	id = "hud_toggle"
	name = "HUD"
	desc = "Включить или выключить проекцию HUD."
	icon = "eye"
	trace = 4

// MARK: Нейролинк

/obj/item/organ/cyberimp/brain/netlink/netrun_hacks()
	return ..() + list("netlink_sever")

/obj/item/organ/cyberimp/brain/netlink/netrun_hack(id, datum/netrun_console/console)
	if(id != "netlink_sever")
		return ..()
	if(!src.console)
		return
	src.console.intrusion.lockout_until = max(src.console.intrusion.lockout_until, world.time + 45 SECONDS)
	src.console.disconnect_client(TRUE)
	src.console.log_line("Сессия разорвана извне.", "bad")
	to_chat(owner, span_warning("Нейролинк теряет связь с сетью."))
	return "Сессия нейролинка разорвана, вход заблокирован на 45 секунд."

/datum/netrun_command/organ/netlink_sever
	id = "netlink_sever"
	access = NETRUN_ACCESS_ROOT
	danger = TRUE
	name = "разорвать сессию"
	desc = "Выбить нейролинк из сети и заблокировать повторный вход."
	icon = "link-slash"
	trace = 8

// MARK: Синтетические органы

/// Временный отказ органа - как при ЭМИ. Снимается, только если отказ не от урона
/obj/item/organ/proc/netrun_fail_temporarily(duration)
	if(organ_flags & ORGAN_FAILING)
		return FALSE
	organ_flags |= ORGAN_FAILING
	addtimer(CALLBACK(src, PROC_REF(netrun_end_failure)), duration)
	return TRUE

/obj/item/organ/proc/netrun_end_failure()
	if(damage < maxHealth)
		organ_flags &= ~ORGAN_FAILING

/obj/item/organ/heart/cybernetic/netrun_hacks()
	return list("heart_arrhythmia", "heart_stop")

/obj/item/organ/heart/ipc/netrun_hacks()
	return list("heart_arrhythmia", "heart_stop")

/obj/item/organ/heart/netrun_hack(id, datum/netrun_console/console)
	switch(id)
		if("heart_arrhythmia")
			owner.Dizzy(10)
			owner.losebreath += 5
			to_chat(owner, span_warning("Сердце сбивается с ритма."))
			return "Ритм сердца сбит."
		if("heart_stop")
			if(!beating)
				return "Сердце уже не бьётся."
			Stop()
			addtimer(CALLBACK(src, PROC_REF(Restart)), 5 SECONDS)
			to_chat(owner, span_userdanger("Сердце замирает!"))
			return "Сердце остановлено на 5 секунд."
	return ..()

/datum/netrun_command/organ/heart_arrhythmia
	id = "heart_arrhythmia"
	access = NETRUN_ACCESS_ROOT
	danger = TRUE
	name = "аритмия"
	desc = "Сбить ритм искусственного сердца: головокружение и одышка."
	icon = "heart-pulse"
	trace = 8

/datum/netrun_command/organ/heart_stop
	id = "heart_stop"
	name = "остановка"
	desc = "Остановить искусственное сердце на 5 секунд."
	access = NETRUN_ACCESS_ROOT
	icon = "heart-crack"
	trace = 14
	danger = TRUE

/obj/item/organ/lungs/cybernetic/netrun_hacks()
	return list("lungs_choke")

/obj/item/organ/lungs/ipc/netrun_hacks()
	return list("lungs_choke")

/obj/item/organ/lungs/netrun_hack(id, datum/netrun_console/console)
	if(id != "lungs_choke")
		return ..()
	owner.losebreath += 6
	to_chat(owner, span_warning("Дыхательный модуль сбоит - не вдохнуть!"))
	return "Дыхательный модуль сбит."

/datum/netrun_command/organ/lungs_choke
	id = "lungs_choke"
	access = NETRUN_ACCESS_ROOT
	danger = TRUE
	name = "сбой дыхания"
	desc = "Сбить цикл искусственных лёгких на несколько вдохов."
	icon = "lungs"
	trace = 8

/obj/item/organ/eyes/robotic/netrun_hacks()
	return list("eyes_flash")

/obj/item/organ/eyes/robotic/toggled/netrun_hacks()
	return ..() + list("eyes_mode")

/obj/item/organ/eyes/robotic/netrun_hack(id, datum/netrun_console/console)
	if(id != "eyes_flash")
		return ..()
	owner.blind_eyes(3)
	owner.eye_blurry = max(owner.eye_blurry, 6)
	to_chat(owner, span_warning("Оптика вспыхивает белым!"))
	return "Оптика засвечена."

/obj/item/organ/eyes/robotic/toggled/netrun_hack(id, datum/netrun_console/console)
	if(id != "eyes_mode")
		return ..()
	toggle()
	return "Режим оптики [active ? "включён" : "выключен"]."

/datum/netrun_command/organ/eyes_flash
	id = "eyes_flash"
	access = NETRUN_ACCESS_ROOT
	danger = TRUE
	name = "засветить"
	desc = "Перегрузить сенсор искусственных глаз: ослепление на пару секунд."
	icon = "sun"
	trace = 7

/datum/netrun_command/organ/eyes_mode
	id = "eyes_mode"
	name = "режим"
	desc = "Переключить особый режим оптики (рентген, тепловизор, щиток)."
	icon = "glasses"
	trace = 5

/obj/item/organ/ears/cybernetic/netrun_hacks()
	return list("ears_deafen")

/obj/item/organ/ears/ipc/netrun_hacks()
	return list("ears_deafen")

/obj/item/organ/ears/netrun_hack(id, datum/netrun_console/console)
	if(id != "ears_deafen")
		return ..()
	deaf = max(deaf, 10)
	to_chat(owner, span_warning("В ушах - ровный белый шум."))
	return "Слуховой модуль заглушён."

/datum/netrun_command/organ/ears_deafen
	id = "ears_deafen"
	access = NETRUN_ACCESS_ROOT
	danger = TRUE
	name = "глушение"
	desc = "Забить слуховой модуль шумом."
	icon = "ear-deaf"
	trace = 6

/obj/item/organ/tongue/robot/netrun_hacks()
	return list("tongue_mute")

/obj/item/organ/tongue/cybernetic/netrun_hacks()
	return list("tongue_mute")

/obj/item/organ/tongue/netrun_hack(id, datum/netrun_console/console)
	if(id != "tongue_mute")
		return ..()
	owner.silent = max(owner.silent, 5)
	to_chat(owner, span_warning("Синтезатор речи не отвечает."))
	return "Синтезатор речи отключён."

/datum/netrun_command/organ/tongue_mute
	id = "tongue_mute"
	access = NETRUN_ACCESS_ROOT
	danger = TRUE
	name = "отключить синтезатор"
	desc = "Выключить синтезатор речи на несколько секунд."
	icon = "comment-slash"
	trace = 6

/obj/item/organ/liver/cybernetic/netrun_hacks()
	return list("organ_halt")

/obj/item/organ/liver/ipc/netrun_hacks()
	return list("organ_halt")

/obj/item/organ/stomach/cybernetic/netrun_hacks()
	return list("organ_halt")

/obj/item/organ/liver/netrun_hack(id, datum/netrun_console/console)
	if(id != "organ_halt")
		return ..()
	return netrun_fail_temporarily(30 SECONDS) ? "[src] остановлен на 30 секунд." : "[src] уже не работает."

/obj/item/organ/stomach/netrun_hack(id, datum/netrun_console/console)
	if(id != "organ_halt")
		return ..()
	return netrun_fail_temporarily(30 SECONDS) ? "[src] остановлен на 30 секунд." : "[src] уже не работает."

/datum/netrun_command/organ/organ_halt
	id = "organ_halt"
	access = NETRUN_ACCESS_ROOT
	danger = TRUE
	name = "остановить"
	desc = "Перевести искусственный орган в аварийный простой на 30 секунд."
	icon = "pause"
	trace = 7

/obj/item/organ/stomach/ipc/netrun_hacks()
	return list("cell_drain")

/obj/item/organ/stomach/ipc/netrun_hack(id, datum/netrun_console/console)
	if(id != "cell_drain")
		return ..()
	owner.adjust_nutrition(-75)
	to_chat(owner, span_warning("Тревога: утечка энергии из внутренней батареи!"))
	return "Батарея носителя частично разряжена."

/datum/netrun_command/organ/cell_drain
	id = "cell_drain"
	access = NETRUN_ACCESS_ROOT
	danger = TRUE
	name = "утечка заряда"
	desc = "Сбросить часть заряда внутренней батареи синтетика."
	icon = "battery-quarter"
	trace = 7
