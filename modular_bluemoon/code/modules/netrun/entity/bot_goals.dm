/// Цель бота: один шаг за такт мозга, у каждой цели свой срок.
/datum/netrun_bot_goal
	var/name = "задача"
	var/datum/netrun_bot_brain/brain
	var/expires_at = 0

/datum/netrun_bot_goal/New(datum/netrun_bot_brain/brain, timeout = 2 MINUTES)
	src.brain = brain
	expires_at = world.time + timeout

/datum/netrun_bot_goal/Destroy()
	brain = null
	return ..()

/// NETRUN_BOT_GOAL_CONTINUE / DONE / FAILED
/datum/netrun_bot_goal/proc/advance()
	return NETRUN_BOT_GOAL_DONE

/datum/netrun_bot_goal/proc/describe()
	return name

/datum/netrun_bot_goal/proc/waits_for_signal()
	return FALSE

/// Shared movement outcome: arrival continues the goal, a blocked node is skipped for a while.
/datum/netrun_bot_goal/proc/approach(datum/component/netrun_node/target)
	switch(brain.move_toward(target))
		if(NETRUN_BOT_MOVE_ARRIVED)
			return NETRUN_BOT_MOVE_ARRIVED
		if(NETRUN_BOT_MOVE_BLOCKED)
			if(target)
				brain.blacklist(target.address)
			return NETRUN_BOT_MOVE_BLOCKED
	return NETRUN_BOT_MOVE_PROGRESS

/datum/netrun_bot_goal/travel
	name = "переход"
	var/datum/weakref/target_ref
	var/target_name

/datum/netrun_bot_goal/travel/New(datum/netrun_bot_brain/brain, datum/component/netrun_node/target, timeout = 90 SECONDS)
	..(brain, timeout)
	target_ref = WEAKREF(target)
	target_name = target?.get_name()

/datum/netrun_bot_goal/travel/describe()
	return "переход к узлу [target_name || "?"]"

/datum/netrun_bot_goal/travel/advance()
	switch(approach(target_ref?.resolve()))
		if(NETRUN_BOT_MOVE_ARRIVED)
			return NETRUN_BOT_GOAL_DONE
		if(NETRUN_BOT_MOVE_BLOCKED)
			return NETRUN_BOT_GOAL_FAILED
	return NETRUN_BOT_GOAL_CONTINUE

/datum/netrun_bot_goal/patrol
	name = "патруль"
	var/list/scope
	var/datum/weakref/target_ref

/datum/netrun_bot_goal/patrol/New(datum/netrun_bot_brain/brain, list/scope)
	..(brain, 90 SECONDS)
	src.scope = scope

/datum/netrun_bot_goal/patrol/advance()
	var/datum/component/netrun_node/target = target_ref?.resolve()
	if(!target)
		target = brain.patrol_destination(scope)
		if(!target)
			brain.state = "ожидание"
			return NETRUN_BOT_GOAL_FAILED
		target_ref = WEAKREF(target)
	switch(approach(target))
		if(NETRUN_BOT_MOVE_ARRIVED)
			brain.state = "патруль"
			return NETRUN_BOT_GOAL_DONE
		if(NETRUN_BOT_MOVE_BLOCKED)
			return NETRUN_BOT_GOAL_FAILED
	brain.state = "патруль"
	return NETRUN_BOT_GOAL_CONTINUE

/// A user or behavior program may request an ordinary command at an authorized node.
/datum/netrun_bot_goal/command
	name = "команда устройства"
	var/datum/weakref/node_ref
	var/command_id
	var/node_name

/datum/netrun_bot_goal/command/New(datum/netrun_bot_brain/brain, datum/component/netrun_node/node, command_id)
	..(brain, 2 MINUTES)
	node_ref = WEAKREF(node)
	src.command_id = command_id
	node_name = node?.get_name()

/datum/netrun_bot_goal/command/describe()
	return "[command_id] @ [node_name || "?"]"

/datum/netrun_bot_goal/command/advance()
	var/datum/component/netrun_node/node = node_ref?.resolve()
	if(QDELETED(node))
		return NETRUN_BOT_GOAL_FAILED
	if(brain.owner.host_node != node)
		return approach(node) == NETRUN_BOT_MOVE_BLOCKED ? NETRUN_BOT_GOAL_FAILED : NETRUN_BOT_GOAL_CONTINUE
	brain.state = "команда устройства"
	return brain.command_step(node, command_id)

/// Stay on a node; combat against trespassers is handled by the brain's combat step.
/datum/netrun_bot_goal/guard
	name = "охрана"
	var/datum/weakref/post_ref
	var/post_name

/datum/netrun_bot_goal/guard/New(datum/netrun_bot_brain/brain, datum/component/netrun_node/post)
	..(brain, 30 SECONDS)
	post_ref = WEAKREF(post)
	post_name = post?.get_name()

/datum/netrun_bot_goal/guard/describe()
	return "охрана узла [post_name || "?"]"

/datum/netrun_bot_goal/guard/advance()
	var/datum/component/netrun_node/post = post_ref?.resolve()
	if(!post)
		return NETRUN_BOT_GOAL_FAILED
	if(brain.owner.host_node == post)
		brain.state = "охрана"
		return NETRUN_BOT_GOAL_CONTINUE
	if(approach(post) == NETRUN_BOT_MOVE_BLOCKED)
		return NETRUN_BOT_GOAL_FAILED
	return NETRUN_BOT_GOAL_CONTINUE

/// Repair a damaged fortress with the ordinary `fort_repair` command.
/datum/netrun_bot_goal/repair
	name = "ремонт"
	var/datum/weakref/node_ref
	var/node_name

/datum/netrun_bot_goal/repair/New(datum/netrun_bot_brain/brain, datum/component/netrun_node/node)
	..(brain, 2 MINUTES)
	node_ref = WEAKREF(node)
	node_name = node?.get_name()

/datum/netrun_bot_goal/repair/describe()
	return "ремонт крепости в узле [node_name || "?"]"

/datum/netrun_bot_goal/repair/advance()
	var/datum/component/netrun_node/node = node_ref?.resolve()
	if(!node?.fortress || !length(node.fortress.damaged_modules()))
		return NETRUN_BOT_GOAL_DONE
	if(brain.owner.host_node != node)
		return approach(node) == NETRUN_BOT_MOVE_BLOCKED ? NETRUN_BOT_GOAL_FAILED : NETRUN_BOT_GOAL_CONTINUE
	brain.state = "ремонт"
	var/datum/netrun_console/console = brain.owner.console
	if(brain.command_nonce || (world.time >= console.next_command && world.time >= node.fortress.next_repair))
		var/result = brain.command_step(node, "fort_repair")
		if(result == NETRUN_BOT_GOAL_FAILED)
			return NETRUN_BOT_GOAL_FAILED
		if(result == NETRUN_BOT_GOAL_DONE)
			brain.clear_command()
	return NETRUN_BOT_GOAL_CONTINUE

/// Pick up debris files left by defeated processes.
/datum/netrun_bot_goal/salvage
	name = "сбор обломков"
	var/datum/weakref/node_ref
	var/node_name

/datum/netrun_bot_goal/salvage/New(datum/netrun_bot_brain/brain, datum/component/netrun_node/node)
	..(brain, 90 SECONDS)
	node_ref = WEAKREF(node)
	node_name = node?.get_name()

/datum/netrun_bot_goal/salvage/describe()
	return "сбор ценных обломков в узле [node_name || "?"]"

/datum/netrun_bot_goal/salvage/advance()
	var/datum/component/netrun_node/node = node_ref?.resolve()
	if(!node || !length(node.salvage))
		return NETRUN_BOT_GOAL_DONE
	if(brain.owner.host_node != node)
		return approach(node) == NETRUN_BOT_MOVE_BLOCKED ? NETRUN_BOT_GOAL_FAILED : NETRUN_BOT_GOAL_CONTINUE
	brain.state = "сбор обломков"
	var/datum/netrun_console/console = brain.owner.console
	var/datum/netrun_file/file = brain.best_salvage(node)
	if(file)
		if(!console.recover_salvage(file.uid))
			return NETRUN_BOT_GOAL_FAILED
		var/turf/spot = node.physical_turf()
		if(brain.visitor_objective == "salvage" && !brain.visitor_departing && spot && is_station_level(spot.z))
			brain.visitor_progress++
		return NETRUN_BOT_GOAL_CONTINUE
	// Full memory is not a bad route: unloading may make this cache useful again.
	return NETRUN_BOT_GOAL_DONE

/// An agent returns to its owner's console as a file again.
/datum/netrun_bot_goal/recall
	name = "возврат к владельцу"

/datum/netrun_bot_goal/recall/New(datum/netrun_bot_brain/brain)
	..(brain, 60 SECONDS)

/datum/netrun_bot_goal/recall/advance()
	var/mob/camera/netrun_entity/bot/agent = brain.owner
	var/datum/netrun_console/master = agent.netrun_owner_console()
	if(agent.agent_orphaned())
		agent.dissolve()
		return NETRUN_BOT_GOAL_DONE
	if(QDELETED(master))
		brain.state = "ожидание владельца"
		return NETRUN_BOT_GOAL_FAILED
	brain.state = "возврат"
	if(agent.host_node && master.can_route(agent.host_node))
		agent.return_to_owner()
		return NETRUN_BOT_GOAL_DONE
	if(world.time > expires_at - 1)
		master.log_line("[agent.real_name]: нет маршрута до владельца, агент остаётся в узле [agent.host_node?.address].", "average")
		return NETRUN_BOT_GOAL_FAILED
	return NETRUN_BOT_GOAL_CONTINUE

/// Return through an actual reachable relay; loss of all exits does not grant teleportation.
/datum/netrun_bot_goal/depart_network
	name = "уход во внешнюю сеть через реле NTnet"
	var/datum/weakref/relay_ref

/datum/netrun_bot_goal/depart_network/New(datum/netrun_bot_brain/brain)
	..(brain, 90 SECONDS)

/datum/netrun_bot_goal/depart_network/advance()
	var/mob/camera/netrun_entity/bot/visitor = brain.owner
	brain.state = name
	if(visitor.can_leave_network())
		visitor.leave_network()
		return NETRUN_BOT_GOAL_DONE
	var/datum/component/netrun_node/relay = relay_ref?.resolve()
	if(!netrun_relay_entry_available(relay) || brain.is_blacklisted(relay.address))
		relay = brain.visitor_exit_node()
		relay_ref = relay ? WEAKREF(relay) : null
	if(!relay)
		brain.state = "ожидание доступного реле NTnet"
		return NETRUN_BOT_GOAL_CONTINUE
	if(approach(relay) == NETRUN_BOT_MOVE_BLOCKED)
		relay_ref = null
	return NETRUN_BOT_GOAL_CONTINUE
