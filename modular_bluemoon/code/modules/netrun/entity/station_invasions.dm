/// Only hostile ambient Redshift visitors can start a physical raid.
/datum/controller/subsystem/netrun
	var/next_station_invasion = 0
	var/list/active_station_invasions = list()

/datum/component/netrun_node
	var/station_invasion_ready_at = 0
	var/datum/weakref/station_invasion_ref

/datum/netrun_bot_brain/proc/node_can_be_raided(datum/component/netrun_node/node)
	var/turf/location = node?.physical_turf()
	if(!location || !is_station_level(location.z) || !node.is_online() || world.time < node.station_invasion_ready_at || node.station_invasion_ref?.resolve())
		return FALSE
	var/datum/component/netrun_node/anchor = node.bound_apc || node
	if(world.time < anchor.station_invasion_ready_at)
		return FALSE
	if(istype(node.parent, /obj/machinery/power/apc))
		var/obj/machinery/power/apc/apc = node.parent
		return apc.operating && !area_has_critical_machine(apc.area)
	return istype(node.parent, /obj/machinery/telecomms) && node.bound_apc?.is_online()

/datum/netrun_bot_brain/proc/plan_station_invasion()
	if(!owner.is_network_visitor() || owner.net_faction != "redshift" || world.time < SSnetrun.next_station_invasion || length(SSnetrun.active_station_invasions) >= 2)
		return FALSE
	var/datum/component/netrun_node/target = node_can_be_raided(owner.host_node) ? owner.host_node : find_nearby_node(PROC_REF(node_can_be_raided))
	if(!target)
		return FALSE
	push_goal(new /datum/netrun_bot_goal/station_invasion(src, target))
	return TRUE

/datum/netrun_bot_program/raider/redshift/plan(datum/netrun_bot_brain/brain)
	if(!brain.plan_station_invasion())
		return ..()

/datum/netrun_bot_program/hacker/redshift/plan(datum/netrun_bot_brain/brain)
	if(!brain.plan_station_invasion())
		return ..()

/// The existing brain owns cadence and lifetime. No additional per-frame work or station scan.
/datum/netrun_bot_goal/station_invasion
	name = "вторжение в оборудование станции"
	var/datum/weakref/target_ref
	var/datum/weakref/apc_ref
	var/disrupt_at = 0
	var/interrupted = FALSE
	var/applied = FALSE

/datum/netrun_bot_goal/station_invasion/New(datum/netrun_bot_brain/brain, datum/component/netrun_node/node)
	..(brain, 5 MINUTES)
	target_ref = WEAKREF(node)

/datum/netrun_bot_goal/station_invasion/proc/announce(text)
	var/datum/component/netrun_node/node = target_ref?.resolve()
	var/atom/host = node?.parent
	if(QDELETED(host))
		return
	var/area/sector = get_area(host)
	for(var/mob/living/witness in sector)
		if(witness.client)
			to_chat(witness, span_warning(text))
	host.visible_message(span_warning("Индикаторы [host] подают сигнал сетевой тревоги."))
	playsound(host, 'sound/machines/triple_beep.ogg', 45, FALSE)

/datum/netrun_bot_goal/station_invasion/proc/holder_changed()
	SIGNAL_HANDLER
	var/mob/camera/netrun_entity/bot/actor = brain?.owner
	var/datum/component/netrun_node/node = target_ref?.resolve()
	var/datum/component/netrun_node/apc = apc_ref?.resolve()
	if(QDELETED(actor) || actor.host_node != node || actor.is_stunned() || actor.console.get_combat_encounter()?.active || !node?.is_online() || (apc_ref && !apc?.is_online()) || actor.console.node_level(node) < NETRUN_ACCESS_USER)
		interrupted = TRUE
		brain?.wake_now()

/datum/netrun_bot_goal/station_invasion/advance()
	var/mob/camera/netrun_entity/bot/actor = brain.owner
	var/datum/component/netrun_node/node = target_ref?.resolve()
	if(interrupted || !actor.is_network_visitor() || actor.net_faction != "redshift" || QDELETED(node) || !node.is_online() || actor.is_stunned() || actor.console.get_combat_encounter()?.active)
		return NETRUN_BOT_GOAL_FAILED
	if(actor.host_node != node)
		return approach(node) == NETRUN_BOT_MOVE_BLOCKED ? NETRUN_BOT_GOAL_FAILED : NETRUN_BOT_GOAL_CONTINUE
	if(actor.console.node_level(node) < NETRUN_ACCESS_USER)
		return brain.queue_frontier_hack(node) ? NETRUN_BOT_GOAL_CONTINUE : NETRUN_BOT_GOAL_FAILED
	if(!disrupt_at)
		if(!brain.node_can_be_raided(node) || world.time < SSnetrun.next_station_invasion || length(SSnetrun.active_station_invasions) >= 2)
			return NETRUN_BOT_GOAL_FAILED
		disrupt_at = world.time + 30 SECONDS
		node.station_invasion_ready_at = world.time + 3 MINUTES
		var/datum/component/netrun_node/anchor = node.bound_apc || node
		anchor.station_invasion_ready_at = node.station_invasion_ready_at
		node.station_invasion_ref = WEAKREF(src)
		SSnetrun.next_station_invasion = world.time + 1 MINUTES
		SSnetrun.active_station_invasions += src
		RegisterSignal(actor, COMSIG_NETRUN_ENTITY_NODE_CHANGED, PROC_REF(holder_changed))
		RegisterSignal(actor.console, COMSIG_NETRUN_COMBAT_CHANGED, PROC_REF(holder_changed))
		RegisterSignal(node, list(COMSIG_NETRUN_NODE_CHANGED, COMSIG_NETRUN_TURN_CHANGED), PROC_REF(holder_changed))
		if(node.bound_apc && node.bound_apc != node)
			apc_ref = WEAKREF(node.bound_apc)
			RegisterSignal(node.bound_apc, COMSIG_NETRUN_NODE_CHANGED, PROC_REF(holder_changed))
		announce("СЕТЕВОЕ ВТОРЖЕНИЕ: Красное смещение удерживает [node.get_name()] в [get_area_name(node.parent, TRUE)]. Через 30 секунд возможен краткий сбой. Изолируйте сетевой интерфейс APC или уничтожьте вторгшийся процесс!")
		SSnetrun.report_incident("invasion", node, actor, NETRUN_INCIDENT_HIGH, "Красное смещение готовит сбой в [get_area_name(node.parent, TRUE)]; 30 секунд на изоляцию APC или подавление процесса.")
		return NETRUN_BOT_GOAL_CONTINUE
	holder_changed()
	if(interrupted)
		return NETRUN_BOT_GOAL_FAILED
	brain.state = "удержание узла: [max(0, CEILING((disrupt_at - world.time) / (1 SECONDS), 1))] с"
	if(world.time < disrupt_at)
		return NETRUN_BOT_GOAL_CONTINUE
	applied = TRUE
	actor.console.report_illegal_activity(node, "Диверсия Красного смещения", NETRUN_ACCESS_USER)
	if(istype(node.parent, /obj/machinery/power/apc))
		var/obj/machinery/power/apc/apc = node.parent
		// Native duration counts machine fires, with power restored on the following fire.
		// One failed cycle keeps the ordinary outage within two machine intervals (2–4 s).
		apc.energy_fail(1)
		if(!apc.failure_timer)
			announce("СЕТЕВОЕ ВТОРЖЕНИЕ: защита критической инфраструктуры [node.get_name()] предотвратила сбой.")
			return NETRUN_BOT_GOAL_DONE
	else
		node.offline_until = max(node.offline_until, world.time + 5 SECONDS)
	node.notify_changed(NETRUN_CHANGED_STATE)
	announce("СЕТЕВОЕ ВТОРЖЕНИЕ: [node.get_name()] даёт кратковременный сбой. Оборудование восстановится автоматически через несколько секунд.")
	return NETRUN_BOT_GOAL_DONE

/datum/netrun_bot_goal/station_invasion/Destroy()
	var/mob/camera/netrun_entity/bot/actor = brain?.owner
	if(actor)
		UnregisterSignal(actor, COMSIG_NETRUN_ENTITY_NODE_CHANGED)
		if(actor.console)
			UnregisterSignal(actor.console, COMSIG_NETRUN_COMBAT_CHANGED)
	var/datum/component/netrun_node/node = target_ref?.resolve()
	if(node)
		UnregisterSignal(node, list(COMSIG_NETRUN_NODE_CHANGED, COMSIG_NETRUN_TURN_CHANGED))
		if(IS_WEAKREF_OF(src, node.station_invasion_ref))
			node.station_invasion_ref = null
	var/datum/component/netrun_node/apc = apc_ref?.resolve()
	if(apc)
		UnregisterSignal(apc, COMSIG_NETRUN_NODE_CHANGED)
	SSnetrun.active_station_invasions -= src
	if(disrupt_at && !applied)
		announce("СЕТЕВОЕ ВТОРЖЕНИЕ ОСТАНОВЛЕНО: захват [node?.get_name() || "узла"] прерван.")
	target_ref = null
	apc_ref = null
	return ..()
