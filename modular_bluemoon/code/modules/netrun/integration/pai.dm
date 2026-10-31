/// The personal AI is a client in its own right, both folded and in a mobile shell.
/mob/living/silicon/pai
	var/datum/netrun_console/pai/netrun_console
	var/datum/action/innate/pai/netrun/network_action

/mob/living/silicon/pai/Initialize(mapload)
	. = ..()
	netrun_console = new(src, NETRUN_ORIGIN_PAI)
	AddComponent(/datum/component/netrun_access_device, netrun_console, NETRUN_NODE_PAI, 2)
	var/datum/component/neural_interface/interface = LoadComponent(/datum/component/neural_interface)
	AddComponent(/datum/component/netrun_neural_feedback, interface, netrun_console, "PAI_NET")
	network_action = new
	network_action.Grant(src)

/mob/living/silicon/pai/Destroy()
	QDEL_NULL(netrun_console)
	QDEL_NULL(network_action)
	return ..()

/mob/living/silicon/pai/netrun_online(remote = TRUE)
	return stat != DEAD && cell?.charge > 0

/mob/living/silicon/pai/netrun_owner_access(datum/netrun_console/console)
	return netrun_console_owner(console) == src ? NETRUN_ACCESS_ROOT : NETRUN_ACCESS_NONE

/mob/living/silicon/pai/netrun_status()
	return list("Состояние: [stat == DEAD ? "не отвечает" : "активен"]", "Батарея: [cell ? round(cell.percent()) : 0]%", "Проекция: [holoform ? "включена" : "карта"]")

/mob/living/silicon/pai/netrun_traced(datum/netrun_console/console)
	to_chat(src, span_userdanger("Защита сети разрывает соединение вашего сетевого клиента!"))
	Stun(4 SECONDS)
	SStgui.close_uis(console)

/datum/netrun_console/pai
	name = "клиент pAI"
	initial_storage_capacity = 6 * NETRUN_STORAGE_SCALE
	tgui_title = "Сеть pAI"

/datum/netrun_console/pai/New(atom/host, origin)
	. = ..()
	operator = host
	state_override = GLOB.conscious_state

/datum/netrun_console/pai/has_uplink()
	var/mob/living/silicon/pai/pai = host
	return istype(pai) && pai.netrun_online() && ..()

/datum/netrun_console/pai/user_access()
	return list()

/datum/action/innate/pai/netrun
	name = "Сеть"
	desc = "Открыть сетевой клиент pAI."
	button_icon_state = "camera_jump"
	icon_icon = 'icons/mob/actions/actions_silicon.dmi'
	background_icon_state = "bg_tech_blue"

/datum/action/innate/pai/netrun/Trigger()
	var/mob/living/silicon/pai/pai = owner
	if(istype(pai) && pai.stat == CONSCIOUS)
		pai.netrun_console?.ui_interact(pai)
