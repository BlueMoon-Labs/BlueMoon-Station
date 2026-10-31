// MARK: Сетевой экран носителя кибернетики
//
// Базовая мера противодействия для мясного игрока, в чьи импланты лезут по сети.
// Нелегальный доступ к узлу-носителю поднимает тревогу, а действие «Сетевой экран»
// на время усиливает защиту узла, сбрасывает взломанные доступы и рвёт активный взлом.

/mob/living/carbon
	var/netrun_firewall_cd = 0
	var/netrun_next_intrusion_warn = 0
	var/datum/action/innate/netrun_firewall/netrun_firewall_action

/// Тревога кибернетики: кто-то действует в нашем узле без авторизации.
/mob/living/carbon/netrun_on_illegal(datum/netrun_console/console, datum/component/netrun_node/node)
	if(node.node_type != NETRUN_NODE_IMPLANT || stat == DEAD)
		return
	if(world.time < netrun_next_intrusion_warn)
		return
	netrun_next_intrusion_warn = world.time + 8 SECONDS
	to_chat(src, span_userdanger("ТРЕВОГА КИБЕРНЕТИКИ: несанкционированный доступ к вашим имплантам! Поднимите сетевой экран (действие в углу экрана)."))
	SEND_SOUND(src, sound('sound/machines/triple_beep.ogg', volume = 50))

/// Грант/снятие действия экрана увязано с наличием кибернетического узла.
/mob/living/carbon/proc/netrun_update_firewall_action()
	var/datum/component/netrun_node/node = GetComponent(/datum/component/netrun_node)
	if(node)
		if(!netrun_firewall_action)
			netrun_firewall_action = new(src)
			netrun_firewall_action.Grant(src)
	else if(netrun_firewall_action)
		netrun_firewall_action.Remove(src)
		QDEL_NULL(netrun_firewall_action)

/mob/living/carbon/proc/netrun_raise_firewall()
	if(world.time < netrun_firewall_cd)
		to_chat(src, span_warning("Сетевой экран ещё перезаряжается ([round((netrun_firewall_cd - world.time) / (1 SECONDS))] с)."))
		return
	var/datum/component/netrun_node/node = GetComponent(/datum/component/netrun_node)
	if(!node)
		to_chat(src, span_warning("В вас нет сетевой кибернетики."))
		return
	netrun_firewall_cd = world.time + 1 MINUTES
	node.raise_firewall(20 SECONDS)
	to_chat(src, span_notice("Вы поднимаете сетевой экран кибернетики: доступ взломщиков сброшен, защита усилена на 20 секунд."))

/datum/action/innate/netrun_firewall
	name = "Сетевой экран"
	desc = "Поднять защиту кибернетики: сбросить взломанные доступы и усилить узел на 20 секунд."
	button_icon_state = "camera_off"
	icon_icon = 'icons/mob/actions/actions_silicon.dmi'
	background_icon_state = "bg_tech_blue"

/datum/action/innate/netrun_firewall/Activate()
	var/mob/living/carbon/carbon = owner
	if(istype(carbon))
		carbon.netrun_raise_firewall()
