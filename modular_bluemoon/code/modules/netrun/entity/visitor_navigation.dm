/// Ambient visitors earn every machine entry; service bots and owned agents keep their policies.
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
