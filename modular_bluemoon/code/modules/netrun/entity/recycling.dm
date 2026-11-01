/// A station maintenance process assembles the same movement, combat and file
/// capabilities as other entities. Recycling policy lives in its own module.
/datum/netrun_bot_program/recycler
	id = NETRUN_BOT_RECYCLER
	name = "Станционный утилизатор"
	desc = "Собирает обломки погибших процессов и переносит добычу в доступную серверную память."
	faction = NETRUN_FACTION_STATION
	sanctioned = TRUE
	max_integrity = 90
	storage = 16 * NETRUN_STORAGE_SCALE
	programs = list("barrier", "patch")
	name_prefix = "RECYCLE"
	avatar = "moth"
	accent = "mint"
	tagline = "очищает сеть и сохраняет файлы"
	console_type = /datum/netrun_console/entity/bot/recycler
	extra_behavior_modules = list(/datum/netrun_entity_module/recycling)
	flee_ratio = 0.7
	think_idle = 10 SECONDS

/datum/netrun_bot_program/recycler/plan(datum/netrun_bot_brain/brain)
	var/datum/netrun_entity_module/recycling/module = brain.owner.entity_modules["recycling"]
	if(brain.owner.entity_module_current(module))
		module.plan(brain)
	else
		..()

/// USER is sufficient for ordinary server disks, never for a foreign vault.
/// Isolated networks retain their normal admission policy.
/datum/netrun_console/entity/bot/recycler/compute_legit_node_level(datum/component/netrun_node/node, fresh = FALSE)
	. = ..()
	if(node?.network && !node.network.isolated)
		. = max(., NETRUN_ACCESS_USER)

/datum/netrun_console/entity/bot/recycler/legit_network_level(datum/netrun_network/network, fresh = FALSE)
	. = ..()
	if(network && !network.isolated)
		. = max(., NETRUN_ACCESS_GUEST)

/// Completed/cancelled file operations use the same nonce, deadline, cancellation
/// and signal-driven wakeups as device commands. Only one may be in flight.
/datum/netrun_bot_brain/proc/deposit_step(datum/component/netrun_node/node, uid)
	if(QDELETED(node) || QDELETED(owner?.console))
		return NETRUN_BOT_GOAL_FAILED
	if(command_nonce)
		if(command_address != node.address || command_id != "file.deposit")
			return NETRUN_BOT_GOAL_FAILED
		if(command_phase == "completed")
			return NETRUN_BOT_GOAL_DONE
		if((command_phase in list("rejected", "cancelled")) || world.time >= command_deadline)
			return NETRUN_BOT_GOAL_FAILED
		return NETRUN_BOT_GOAL_CONTINUE
	if(world.time < owner.console.next_command)
		return NETRUN_BOT_GOAL_CONTINUE
	command_nonce = "bot-deposit-[++command_serial]"
	command_address = node.address
	command_id = "file.deposit"
	command_deadline = world.time + 30 SECONDS
	if(!owner.console.queue_file_request("deposit", node, uid, FALSE, command_nonce))
		return NETRUN_BOT_GOAL_FAILED
	return NETRUN_BOT_GOAL_CONTINUE

/datum/netrun_entity_module/recycling
	id = "recycling"
	priority = 145
	requires = list("navigation", "bot_lifecycle", "bot_goals")
	/// UIDs acquired through actual recovery; installed runtime files are excluded.
	var/list/cargo_uids = list()
	var/server_cursor = 1

/datum/netrun_entity_module/recycling/on_install()
	listen(owner, COMSIG_NETRUN_SALVAGE_RECOVERED, PROC_REF(on_recovered))
	listen(SSnetrun, COMSIG_NETRUN_SALVAGE_CHANGED, PROC_REF(on_salvage_changed))
	return TRUE

/datum/netrun_entity_module/recycling/proc/on_recovered(datum/source, datum/netrun_file/file, datum/component/netrun_node/node)
	SIGNAL_HANDLER
	cargo_uids |= file.uid
	wake_behavior()

/datum/netrun_entity_module/recycling/proc/on_salvage_changed(datum/source, datum/component/netrun_node/node)
	SIGNAL_HANDLER
	if(!owner.entity_module_current(src) || QDELETED(node) || !length(node.salvage) || node.network?.isolated)
		return
	var/datum/netrun_bot_brain/brain = owner?.module_brain()
	var/datum/netrun_bot_goal/goal = brain?.current_goal()
	if(istype(goal, /datum/netrun_bot_goal/recycling_wait))
		brain.clear_goals()
		wake_behavior()
	else if(!goal)
		wake_behavior()

/datum/netrun_entity_module/recycling/on_remove()
	var/datum/netrun_bot_brain/brain = owner?.module_brain()
	if(istype(brain?.current_goal(), /datum/netrun_bot_goal/recycle_deposit))
		brain.clear_goals()
	cargo_uids.Cut()

/datum/netrun_entity_module/recycling/proc/first_cargo()
	RETURN_TYPE(/datum/netrun_file)
	var/datum/netrun_file_store/store = owner.console.inventory.local_store
	while(length(cargo_uids))
		var/uid = cargo_uids[1]
		var/datum/netrun_file/file = store.find_file(uid)
		if(file)
			return file
		cargo_uids -= uid
	return null

/// The sparse index contains only nonempty debris nodes. Inspect at most24
/// candidates per plan, with one shared route snapshot and a rotating cursor.
/datum/netrun_entity_module/recycling/proc/find_debris(datum/netrun_bot_brain/brain)
	return brain.find_salvage(null, TRUE)

/// Servers are indexed at registration, not rediscovered by scanning machines.
/datum/netrun_entity_module/recycling/proc/find_server(datum/netrun_bot_brain/brain)
	var/datum/netrun_file/file = first_cargo()
	if(brain.node_accepts_cargo(owner.host_node, file = file))
		return owner.host_node
	var/list/candidates = SSnetrun.recycling_servers
	if(!length(candidates))
		return null
	var/datum/netrun_console/console = owner.console
	var/datum/netrun_path_tree/tree = console.connection.read_path_tree(TRUE)
	for(var/i in 1 to min(24, length(candidates)))
		if(server_cursor > length(candidates))
			server_cursor = 1
		var/datum/component/netrun_node/node = candidates[candidates[server_cursor++]]
		if(brain.node_accepts_cargo(node, tree, file) && console.can_route(node, tree))
			. = node
			break
	console.release_path_tree(tree)

/datum/netrun_entity_module/recycling/behavior_step(datum/netrun_bot_brain/brain)
	if(!brain || brain.current_goal())
		return FALSE
	plan(brain)
	return FALSE

/datum/netrun_entity_module/recycling/proc/plan(datum/netrun_bot_brain/brain)
	var/datum/netrun_file/cargo = first_cargo()
	var/datum/component/netrun_node/target = cargo ? find_server(brain) : null
	if(target)
		brain.push_goal(new /datum/netrun_bot_goal/recycle_deposit(brain, target))
	else
		target = find_debris(brain)
		if(target)
			brain.push_goal(new /datum/netrun_bot_goal/salvage(brain, target))
		else
			brain.push_goal(new /datum/netrun_bot_goal/recycling_wait(brain, owner.host_node))

/datum/netrun_bot_brain/proc/node_accepts_cargo(datum/component/netrun_node/node, datum/netrun_path_tree/tree, datum/netrun_file/file)
	if(QDELETED(node) || node.node_type != NETRUN_NODE_SERVER || node.is_dynamic() || node.network?.isolated || is_blacklisted(node.address) || !node.is_online())
		return FALSE
	var/datum/netrun_entity_module/recycling/module = owner.entity_modules["recycling"]
	if(!owner.entity_module_current(module))
		return FALSE
	file ||= module.first_cargo()
	if(!file || !file.can_transfer(node.file_store, TRUE) || !node.file_store.can_fit(file))
		return FALSE
	return owner.console.node_level(node, tree) >= max(NETRUN_ACCESS_USER, node.fortress?.file_access_level(owner.console) || 0)

/datum/netrun_bot_goal/recycling_wait
	parent_type = /datum/netrun_bot_goal/guard
	name = "ожидание обломков или свободного сервера"

/datum/netrun_bot_goal/recycling_wait/New(datum/netrun_bot_brain/brain, datum/component/netrun_node/post)
	..(brain, post)
	expires_at = min(world.time + 60 SECONDS, brain.salvage_wait_until || INFINITY)

/datum/netrun_bot_goal/recycle_deposit
	name = "доставка обломков на сервер"
	var/datum/weakref/node_ref
	var/node_name

/datum/netrun_bot_goal/recycle_deposit/New(datum/netrun_bot_brain/brain, datum/component/netrun_node/node)
	..(brain, 2 MINUTES)
	node_ref = WEAKREF(node)
	node_name = node?.get_name()

/datum/netrun_bot_goal/recycle_deposit/describe()
	return "доставка собранных файлов на сервер [node_name || "?"]"

/datum/netrun_bot_goal/recycle_deposit/advance()
	var/datum/netrun_entity_module/recycling/module = brain.owner.entity_modules["recycling"]
	var/datum/component/netrun_node/node = node_ref?.resolve()
	if(!brain.owner.entity_module_current(module) || !node)
		return NETRUN_BOT_GOAL_FAILED
	// Consume the actual delivery outcome before pruning the removed cargo UID.
	if(brain.command_nonce)
		var/result = brain.deposit_step(node, null)
		if(result == NETRUN_BOT_GOAL_FAILED)
			brain.blacklist(node.address, 60 SECONDS)
			return result
		if(result == NETRUN_BOT_GOAL_CONTINUE)
			return result
		brain.clear_command()
	var/datum/netrun_file/file = module.first_cargo()
	if(!file)
		return NETRUN_BOT_GOAL_DONE
	if(!brain.node_accepts_cargo(node))
		brain.blacklist(node.address, 60 SECONDS)
		return NETRUN_BOT_GOAL_FAILED
	if(brain.owner.host_node != node)
		return approach(node) == NETRUN_BOT_MOVE_BLOCKED ? NETRUN_BOT_GOAL_FAILED : NETRUN_BOT_GOAL_CONTINUE
	brain.state = "разгрузка обломков"
	return brain.deposit_step(node, file.uid)
