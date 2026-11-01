/// Portable extension definitions are an allowlist of real daemon files. The
/// capability manager never interprets a client-supplied type or procedure name.
/datum/netrun_agent_extension
	var/id
	var/daemon_id
	var/name
	var/desc
	var/module_type

/datum/netrun_agent_extension/hacking
	id = "hacking"
	daemon_id = "autobreach"
	name = "Модуль взлома"
	desc = "Планирует взлом: последовательно решает обычные миниигры с задержкой, получает права по их результату, двигается по реальным переходам и выполняет приказ."
	module_type = /datum/netrun_entity_module/hacking

/datum/netrun_agent_extension/icepick
	id = "icepick"
	daemon_id = "icepick"
	name = "Подбор защиты"
	desc = "Штатный icepick.exe снижает сложность взлома и открывает миниигру прошивки при наличии ROOT. Права и совместимость устройства проверяются обычно."

/datum/netrun_agent_extension/cloak
	id = "cloak"
	daemon_id = "cloak"
	name = "Скрытность"
	desc = "Штатный cloak.exe уменьшает прирост трассировки; обнаружение и ICE продолжают действовать."

/datum/netrun_agent_extension/scrub
	id = "scrub"
	daemon_id = "scrub"
	name = "Очистка следов"
	desc = "Штатный scrub.exe ускоряет обычное затухание трассировки после прекращения нелегальных действий."

/datum/netrun_agent_extension/ghostlink
	id = "ghostlink"
	daemon_id = "ghostlink"
	name = "Компактная скрытность"
	desc = "ghostlink.exe: маскировка 20% и ускоренная очистка следов."

/datum/netrun_agent_extension/breachkit
	id = "breachkit"
	daemon_id = "breachkit"
	name = "Комплект подбора"
	desc = "breachkit.exe: снижение сложности и дополнительный буфер ручного взлома. Не заменяет autobreach.exe."

/datum/netrun_agent_extension/analyst
	id = "analyst"
	daemon_id = "analyst"
	name = "Анализ и извлечение"
	desc = "analyst.exe: разведка карты и штатный массовый слив доступных файлов."

/datum/controller/subsystem/netrun
	var/list/datum/netrun_agent_extension/agent_extension_definitions

/datum/controller/subsystem/netrun/proc/get_agent_extensions()
	if(!agent_extension_definitions)
		agent_extension_definitions = list()
		for(var/datum/netrun_agent_extension/path as anything in subtypesof(/datum/netrun_agent_extension))
			if(initial(path.id))
				var/datum/netrun_agent_extension/extension = new path
				agent_extension_definitions[extension.id] = extension
	return agent_extension_definitions

/proc/netrun_agent_extension_for(datum/netrun_file/file)
	RETURN_TYPE(/datum/netrun_agent_extension)
	if(QDELETED(file) || file.kind != NETRUN_FILE_DAEMON)
		return null
	var/list/extensions = SSnetrun.get_agent_extensions()
	for(var/id in extensions)
		var/datum/netrun_agent_extension/extension = extensions[id]
		if(file.content == extension.daemon_id)
			return extension
	return null

/// File changes are facts, not a per-think scan. Each installed extension owns
/// its own behavior and subscriptions; this manager only reconciles composition.
/datum/netrun_entity_module/agent_extensions
	id = "agent_extensions"
	priority = 60
	requires = list("console", "navigation")
	var/reconciling = FALSE
	var/list/datum/netrun_entity_module/managed = list()

/datum/netrun_entity_module/agent_extensions/on_install()
	listen(owner.console.inventory, COMSIG_NETRUN_INVENTORY_CHANGED, PROC_REF(on_inventory_changed))
	listen(owner, COMSIG_NETRUN_ENTITY_MODULE_READY, PROC_REF(on_ready))
	return TRUE

/datum/netrun_entity_module/agent_extensions/proc/on_inventory_changed(datum/source)
	SIGNAL_HANDLER
	reconcile_extensions()

/datum/netrun_entity_module/agent_extensions/proc/on_ready(datum/source, datum/netrun_entity_module/module)
	SIGNAL_HANDLER
	reconcile_extensions()

/datum/netrun_entity_module/agent_extensions/proc/reconcile_extensions()
	if(reconciling || !installed || QDELETED(owner))
		return
	reconciling = TRUE
	var/list/present = list()
	for(var/datum/netrun_file/file as anything in owner.console.inventory.all_files(TRUE))
		var/datum/netrun_agent_extension/extension = netrun_agent_extension_for(file)
		if(extension?.module_type)
			present[extension.id] = extension
	for(var/id in managed.Copy())
		var/datum/netrun_entity_module/module = managed[id]
		if(QDELETED(module) || owner.entity_modules[id] != module)
			managed -= id
		else if(!present[id])
			managed -= id
			owner.remove_module(id)
	for(var/id in present)
		if(owner.entity_modules[id])
			continue
		var/datum/netrun_agent_extension/extension = present[id]
		var/datum/netrun_entity_module/module = owner.install_module(extension.module_type)
		if(module)
			managed[id] = module
	reconciling = FALSE

/datum/netrun_entity_module/agent_extensions/on_remove()
	for(var/id in managed)
		if(owner?.entity_modules[id] == managed[id])
			owner.remove_module(id)
	managed.Cut()

/// The installed autobreach tool enables autonomous hacking goals and orders.
/// Their puzzles and rewards use ordinary player paths with delayed NPC input.
/// The planning capability never writes an access grant itself.
/datum/netrun_entity_module/hacking
	id = "hacking"
	priority = 125
	requires = list("console", "navigation", "agent_extensions")
	var/datum/weakref/breach_ref
	var/datum/weakref/goal_ref
	var/list/candidates
	var/candidate_cursor = 1

/datum/netrun_entity_module/hacking/on_install()
	listen(owner, COMSIG_NETRUN_AGENT_ORDER_LIST, PROC_REF(on_order_list))
	listen(owner, COMSIG_NETRUN_AGENT_CONTROL, PROC_REF(on_agent_control))
	return TRUE

/// Mini-game input is a background activity for players and NPCs alike. Combat
/// must not starve admission of an existing hack goal, including on an enemy turn.
/// Movement and device commands remain ordinary goal actions after combat policy.
/datum/netrun_entity_module/hacking/behavior_step(datum/netrun_bot_brain/brain)
	if(!brain || brain.owner != owner || !owner.console.automates_breach_input())
		return FALSE
	var/datum/netrun_bot_goal/hack/goal = brain.current_goal()
	if(!istype(goal) || goal.module_ref?.resolve() != src || goal.waiting)
		return FALSE
	var/result = goal.advance(TRUE)
	if(!QDELETED(goal) && result != NETRUN_BOT_GOAL_CONTINUE)
		brain.finish_goal(goal)
	// Starting a puzzle spends no AP and must not strand the current AI turn.
	return FALSE

/datum/netrun_entity_module/hacking/proc/can_hack()
	return installed && enabled && !QDELETED(owner?.console) && owner.console.intrusion.can_breach && owner.console.daemon_capability("autobreach")

/datum/netrun_entity_module/hacking/proc/on_order_list(datum/source, list/orders)
	SIGNAL_HANDLER
	if(can_hack())
		orders += list(list("id" = "hack", "name" = "Взломать выбранный узел", "needs_node" = TRUE))

/datum/netrun_entity_module/hacking/proc/on_agent_control(datum/source, datum/netrun_console/master, list/options)
	SIGNAL_HANDLER
	if(options["order"] != "hack")
		return FALSE
	var/datum/netrun_bot_brain/brain = owner.module_brain()
	if(!can_hack() || QDELETED(brain) || QDELETED(master) || owner.netrun_owner_console() != master)
		return FALSE
	var/datum/component/netrun_node/target = SSnetrun.find_node(options["address"])
	var/command = options["command"]
	if(QDELETED(target) || !master.can_route(target) || (command && (!istext(command) || length(command) > 64 || !(command in target.all_command_ids()))))
		master.log_line("Цель взлома или последующая команда недоступна.", "bad")
		return FALSE
	brain.clear_goals()
	brain.order = "guard"
	brain.push_goal(new /datum/netrun_bot_goal/hack(brain, target, command))
	master.log_line("[owner.real_name]: принят приказ взлома [target.address][command ? " и команды [command]" : ""].", "average")
	return TRUE

/datum/netrun_entity_module/hacking/proc/start_for_goal(datum/netrun_bot_goal/hack/goal, kind, target_id)
	if(!can_hack() || !owner.console.automates_breach_input() || goal.brain?.owner != owner || goal.brain.current_goal() != goal || owner.console.intrusion.breach)
		return FALSE
	if(!(kind in list("node", "network")) || !owner.console.start_breach(kind, target_id))
		return FALSE
	var/datum/netrun_breach/npc/breach = owner.console.intrusion.breach
	if(!istype(breach))
		return FALSE
	breach_ref = WEAKREF(breach)
	goal_ref = WEAKREF(goal)
	goal.waiting = TRUE
	listen(breach, COMSIG_PARENT_QDELETING, PROC_REF(on_breach_ended))
	goal.brain.schedule_goal_wait(goal)
	return TRUE

/datum/netrun_entity_module/hacking/proc/on_breach_ended(datum/source)
	SIGNAL_HANDLER
	unlisten(source, COMSIG_PARENT_QDELETING)
	var/datum/netrun_bot_goal/hack/goal = goal_ref?.resolve()
	if(goal)
		goal.brain?.clear_goal_wait(goal)
		goal.waiting = FALSE
	breach_ref = null
	goal_ref = null
	wake_behavior()

/datum/netrun_entity_module/hacking/proc/cancel_goal(datum/netrun_bot_goal/hack/goal)
	// Destroy runs after qdel marks the goal dead, so resolve() already returns
	// null there. Compare the owned weak reference before the goal's base cleanup.
	if(goal && !IS_WEAKREF_OF(goal, goal_ref))
		return
	var/datum/netrun_breach/breach = breach_ref?.resolve()
	var/datum/netrun_bot_goal/hack/current = goal_ref?.resolve()
	if(goal || current)
		owner?.module_brain()?.clear_goal_wait(goal || current)
	if(current)
		current.waiting = FALSE
		current.cancelled = TRUE
	breach_ref = null
	goal_ref = null
	if(!QDELETED(breach))
		unlisten(breach, COMSIG_PARENT_QDELETING)
		if(owner?.console?.intrusion.breach == breach)
			owner.console.intrusion.breach = null
			owner.console.log_line("Агент прервал свой автовзлом: доступ не получен, трассировка сохранена.", "average")
		qdel(breach)

/datum/netrun_entity_module/hacking/on_remove()
	cancel_goal(null)
	var/datum/netrun_bot_brain/brain = owner?.module_brain()
	if(!QDELETED(brain) && !brain.handling_behavior)
		brain.wake_now()
	candidates = null

/// Planning examines at most twelve physical candidates at a time. A private
/// itinerary contains addresses only; authoritative state is sampled per plan.
/datum/netrun_entity_module/hacking/proc/pick_target(datum/netrun_bot_brain/brain)
	if(!can_hack() || brain.owner != owner)
		return null
	var/datum/netrun_path_tree/tree = owner.console.connection.read_path_tree(TRUE)
	if(!length(candidates) || candidate_cursor > length(candidates))
		candidates = shuffle(tree.reached.Copy())
		candidate_cursor = 1
	var/end = min(length(candidates), candidate_cursor + 11)
	var/datum/netrun_network/home = owner.host_node?.network
	for(var/index = candidate_cursor; index <= end; index++)
		var/datum/component/netrun_node/node = SSnetrun.find_node(candidates[index])
		if(QDELETED(node) || node == owner.host_node || node.network != home || brain.is_blacklisted(node.address) || !tree.reached[node.address] || !node.is_online() || owner.console.node_level(node, tree) >= NETRUN_ACCESS_USER || node.fortress?.blocks_breach(owner.console))
			continue
		. = node
		candidate_cursor = index + 1
		break
	if(!.)
		candidate_cursor = end + 1
	owner.console.release_path_tree(tree)

/// One frontier at a time: network GUEST, node USER, native hop, then the next
/// frontier. Neither movement nor the final device command borrows the master's ID.
/datum/netrun_bot_goal/hack
	name = "взлом узла"
	var/datum/weakref/target_ref
	var/datum/weakref/module_ref
	var/target_name
	var/command_id
	var/attempted_key
	var/waiting = FALSE
	var/cancelled = FALSE

/datum/netrun_bot_goal/hack/New(datum/netrun_bot_brain/brain, datum/component/netrun_node/target, command_id)
	..(brain, 5 MINUTES)
	target_ref = WEAKREF(target)
	target_name = "[target.get_name()] [target.address]"
	src.command_id = command_id
	var/datum/netrun_entity_module/hacking/module = brain.owner.entity_modules["hacking"]
	module_ref = QDELETED(module) ? null : WEAKREF(module)

/datum/netrun_bot_goal/hack/Destroy()
	var/datum/netrun_entity_module/hacking/module = module_ref?.resolve()
	module?.cancel_goal(src)
	target_ref = null
	module_ref = null
	return ..()

/datum/netrun_bot_goal/hack/describe()
	return "взлом: [target_name][command_id ? " → [command_id]" : ""]"

/datum/netrun_bot_goal/hack/waits_for_signal()
	var/datum/netrun_entity_module/hacking/module = module_ref?.resolve()
	return waiting && !QDELETED(module)

/// A failed frontier must not become the next autonomous plan immediately.
/// Explicit owner orders can still try again; only automatic selection consults
/// the blacklist. Cancellation/recall never enters this failure path.
/datum/netrun_bot_goal/hack/proc/fail_at(datum/component/netrun_node/frontier)
	var/datum/component/netrun_node/target = target_ref?.resolve()
	if(!cancelled && !QDELETED(brain))
		if(!QDELETED(frontier))
			brain.blacklist(frontier.address, 1 MINUTES)
		if(!QDELETED(target) && target != frontier)
			brain.blacklist(target.address, 1 MINUTES)
	return NETRUN_BOT_GOAL_FAILED

/datum/netrun_bot_goal/hack/advance(background_only = FALSE)
	var/datum/netrun_entity_module/hacking/module = module_ref?.resolve()
	var/datum/component/netrun_node/target = target_ref?.resolve()
	var/mob/camera/netrun_entity/actor = brain.owner
	if(cancelled || QDELETED(module) || !module.can_hack() || QDELETED(target) || QDELETED(actor.console))
		return NETRUN_BOT_GOAL_FAILED
	if(actor.console.is_locked() || !target.is_online())
		return fail_at(target)
	if(waiting)
		brain.state = "взлом"
		return NETRUN_BOT_GOAL_CONTINUE
	if(actor.host_node == target && actor.console.node_level(target) >= NETRUN_ACCESS_USER)
		brain.state = command_id ? "команда после взлома" : "взлом завершён"
		if(background_only && command_id)
			return NETRUN_BOT_GOAL_CONTINUE
		return command_id ? brain.command_step(target, command_id) : NETRUN_BOT_GOAL_DONE
	var/datum/netrun_path_tree/tree = actor.console.connection.read_path_tree(TRUE)
	if(!actor.host_node || !actor.console.can_route(target, tree))
		actor.console.release_path_tree(tree)
		return fail_at(target)
	var/address = target.address
	while(tree.previous[address] && tree.previous[address] != actor.host_node.address)
		address = tree.previous[address]
	var/datum/component/netrun_node/frontier = SSnetrun.find_node(address)
	var/level = actor.console.node_level(frontier, tree)
	actor.console.release_path_tree(tree)
	if(QDELETED(frontier))
		return fail_at(target)
	if(level < NETRUN_ACCESS_USER)
		var/kind = actor.console.network_level(frontier.network) < NETRUN_ACCESS_GUEST ? "network" : "node"
		var/id = kind == "network" ? frontier.network?.id : frontier.address
		var/key = "[kind]:[id]"
		if(!id || attempted_key == key)
			return fail_at(frontier)
		attempted_key = key
		brain.state = "взлом"
		return module.start_for_goal(src, kind, id) ? NETRUN_BOT_GOAL_CONTINUE : fail_at(frontier)
	if(background_only || world.time < actor.next_hop)
		return NETRUN_BOT_GOAL_CONTINUE
	brain.state = "переход к цели взлома"
	return actor.hop(frontier) ? NETRUN_BOT_GOAL_CONTINUE : fail_at(frontier)
