/// Ambient visitors earn every machine entry; service bots and owned agents keep their policies.
/mob/camera/netrun_entity/visitor
	console_type = /datum/netrun_console/entity/visitor

/mob/camera/netrun_entity/visitor/Initialize(mapload, datum/component/netrun_node/start)
	. = ..()
	if(QDELETED(console))
		return
	console.access_session.node_access.Cut()
	console.access_session.network_access.Cut()
	console.access_session.residency_address = null
	console.store_file(netrun_daemon_file("autobreach"))

/datum/netrun_console/entity/visitor/is_home_network(datum/netrun_network/network, datum/netrun_path_tree/tree)
	return FALSE

/datum/netrun_console/entity/visitor/can_traverse_node(datum/component/netrun_node/node, datum/netrun_path_tree/tree)
	return !QDELETED(node) && node_level(node, tree) >= NETRUN_ACCESS_USER

/datum/netrun_console/entity/visitor/compute_node_level(datum/component/netrun_node/node, datum/netrun_path_tree/tree)
	if(QDELETED(node))
		return NETRUN_ACCESS_NONE
	if(network_level(node.network, tree) < NETRUN_ACCESS_GUEST && access_session.acquired_node_level(node) < NETRUN_ACCESS_USER && legit_node_level(node) < NETRUN_ACCESS_USER)
		return NETRUN_ACCESS_NONE
	return ..()

/// The physical relay is the shared arrival/departure boundary; no remote selection suffices.
/proc/netrun_relay_entry_available(datum/component/netrun_node/node)
	if(QDELETED(node) || !istype(node.parent, /obj/machinery/ntnet_relay) || node.network?.isolated || SSnetworks.station_network.setting_disabled || !node.is_online())
		return FALSE
	return !(node.fortress?.slots_max() > 0 && node.fortress.intact_count(NETRUN_FORT_GATE))

/mob/camera/netrun_entity/proc/leave_network_reason()
	if(dive_link?.body)
		return "Вернитесь в своё тело перед выходом из сети."
	if(!istype(host_node?.parent, /obj/machinery/ntnet_relay))
		return "Для выхода войдите в узел реле NTnet."
	if(!netrun_relay_entry_available(host_node))
		return "Реле отключено, изолировано или его внешние врата закрыты."
	if(console.is_locked())
		return "Точка подключения заблокирована трассировкой."
	if(is_stunned())
		return "Оглушённый процесс не может покинуть сеть."
	if(console.get_combat_encounter()?.active)
		return "Сначала выйдите из боя."
	return null

/mob/camera/netrun_entity/proc/can_leave_network()
	return !leave_network_reason()

/mob/camera/netrun_entity/proc/leave_network()
	var/reason = leave_network_reason()
	if(reason)
		console.log_line(reason, "bad")
		return FALSE
	host_node.network?.add_log("Процесс [real_name] покинул сеть через реле [host_node.address].")
	var/obj/machinery/ntnet_relay/relay = host_node.parent
	log_game("NETRUN: [key_name(src)] покинул сеть через [AREACOORD(relay)]")
	to_chat(src, span_notice("Вы уходите во внешнюю сеть. Ваше участие в раунде завершено."))
	ghostize(FALSE)
	qdel(src)
	return TRUE

/mob/camera/netrun_entity/bot/proc/is_network_visitor()
	return !launched_by_owner && SSnetrun.get_netrun_faction(program?.faction)?.arrival_weight > 0

/datum/netrun_console/entity/bot/can_traverse_node(datum/component/netrun_node/node, datum/netrun_path_tree/tree)
	var/mob/camera/netrun_entity/bot/bot = host
	if(bot?.is_network_visitor())
		return !QDELETED(node) && node_level(node, tree) >= NETRUN_ACCESS_USER
	return ..()

/datum/netrun_console/entity/bot/is_home_network(datum/netrun_network/network, datum/netrun_path_tree/tree)
	var/mob/camera/netrun_entity/bot/bot = host
	return bot?.is_network_visitor() ? FALSE : ..()

/// Presence at an entry endpoint is not a free loopback credential for an arriving visitor.
/datum/netrun_console/entity/bot/compute_node_level(datum/component/netrun_node/node, datum/netrun_path_tree/tree)
	if(QDELETED(node))
		return NETRUN_ACCESS_NONE
	var/mob/camera/netrun_entity/bot/bot = host
	if(bot?.is_network_visitor() && network_level(node?.network, tree) < NETRUN_ACCESS_GUEST && access_session.acquired_node_level(node) < NETRUN_ACCESS_USER && legit_node_level(node) < NETRUN_ACCESS_USER)
		return NETRUN_ACCESS_NONE
	return ..()

/// Planning may consider a closed frontier, but never authorizes movement or reads its disk.
/datum/netrun_bot_brain/proc/can_plan_visit(datum/component/netrun_node/node, datum/netrun_path_tree/tree)
	if(owner.console.can_traverse_node(node, tree))
		return TRUE
	var/datum/netrun_entity_module/hacking/module = owner.entity_modules["hacking"]
	return owner.is_network_visitor() && module?.can_hack() && !QDELETED(node) && node.is_online() && !node.fortress?.blocks_breach(owner.console) && owner.console.can_route(node, tree)

/datum/netrun_bot_brain/proc/queue_frontier_hack(datum/component/netrun_node/target)
	var/datum/netrun_entity_module/hacking/module = owner.entity_modules["hacking"]
	if(!owner.is_network_visitor() || !module?.can_hack() || QDELETED(target) || target.fortress?.blocks_breach(owner.console))
		return FALSE
	if(is_blacklisted(target.address) || !target.is_online() || !owner.console.can_route(target))
		return FALSE
	goals.Insert(1, new /datum/netrun_bot_goal/hack(src, target))
	while(length(goals) > 4)
		var/datum/netrun_bot_goal/excess = goals[length(goals)]
		goals.Cut(length(goals))
		qdel(excess)
	state = "подбор доступа к следующему узлу"
	SEND_SIGNAL(owner, COMSIG_NETRUN_ENTITY_GOALS_CHANGED, handling_behavior)
	return TRUE

/datum/netrun_bot_brain/proc/assign_visitor_objective()
	if(!owner.is_network_visitor())
		return
	if(owner.net_faction == "redshift")
		visitor_objective = "sabotage"
		visitor_required = 1
	else if(istype(owner.program, /datum/netrun_bot_program/scavenger))
		visitor_objective = "salvage"
		visitor_required = 2
	else
		visitor_objective = "survey"
		visitor_required = owner.net_faction == "collective" ? 4 : 3

/datum/netrun_bot_brain/proc/visitor_objective_text()
	if(visitor_departing)
		return visitor_completed ? "Задача выполнена: уход через NTnet" : "Срок задания истёк: уход через NTnet"
	switch(visitor_objective)
		if("sabotage")
			return "Цель: провести одну диверсию на станции"
		if("salvage")
			return "Цель: собрать станционные обломки ([visitor_progress]/[visitor_required])"
		if("survey")
			return "Цель: разведать устройства станции ([visitor_progress]/[visitor_required])"
	return null

/datum/netrun_bot_brain/proc/advance_visitor_objective()
	if(visitor_departing || !visitor_objective)
		return
	var/datum/component/netrun_node/current = owner.host_node
	var/turf/spot = current?.physical_turf()
	if(visitor_objective == "survey" && spot && is_station_level(spot.z) && !current.is_dynamic() && !istype(current.parent, /obj/machinery/ntnet_relay) && owner.console.node_level(current) >= NETRUN_ACCESS_USER && !(current.address in visitor_surveyed))
		visitor_surveyed += current.address
		visitor_progress++
	if(visitor_progress >= visitor_required)
		visitor_completed = TRUE
		begin_visitor_departure()

/datum/netrun_bot_brain/proc/plan_visitor_objective()
	if(visitor_departing)
		push_goal(new /datum/netrun_bot_goal/depart_network(src))
		return
	owner.program.plan(src)

/datum/netrun_bot_brain/proc/begin_visitor_departure()
	if(visitor_departing || !owner.is_network_visitor())
		return FALSE
	visitor_departing = TRUE
	clear_goals()
	// One bounded grace period, including combat and loss of every physical exit.
	owner.expires_at = world.time + 90 SECONDS
	SEND_SIGNAL(owner, COMSIG_NETRUN_ENTITY_MODULE_READY, null)
	push_goal(new /datum/netrun_bot_goal/depart_network(src))
	state = visitor_objective_text()
	owner.host_node?.network?.add_log("[owner.real_name]: [state].")
	return TRUE

/// A topology read and bounded relay search reuse the ordinary route/ACL checks.
/datum/netrun_bot_brain/proc/visitor_exit_node()
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	var/datum/netrun_console/console = owner.console
	var/datum/netrun_path_tree/tree = console.connection.read_path_tree(TRUE)
	var/best_cost = INFINITY
	for(var/index in 1 to min(16, length(graph.registered_relays)))
		if(visitor_exit_cursor > length(graph.registered_relays))
			visitor_exit_cursor = 1
		var/address = graph.registered_relays[visitor_exit_cursor++]
		var/datum/component/netrun_node/node = graph.registered_relays[address]
		if(!netrun_relay_entry_available(node) || is_blacklisted(address) || !can_plan_visit(node, tree) || !console.can_route(node, tree))
			continue
		var/cost = tree.cost_to(address)
		if(cost < best_cost)
			. = node
			best_cost = cost
	console.release_path_tree(tree)
