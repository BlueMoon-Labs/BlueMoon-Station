/**
 * Автономный бот - сетевая сущность без клиента. Он ходит, выполняет команды узлов
 * и сражается теми же путями, что игрок: права проверяются при доставке, пакеты
 * видны на карте, ICE считает его нарушителем без доступа ПОЛЬЗОВАТЕЛЯ.
 */
/mob/camera/netrun_entity/bot
	has_messenger = FALSE
	var/bot_kind
	var/net_faction = NETRUN_FACTION_ROGUE
	var/datum/netrun_bot_program/program
	var/datum/netrun_bot_brain/brain
	/// Last explicitly accepted reporting/recall client, never the ownership authority.
	var/datum/weakref/owner_ref
	/// A native dive's physical return client is known without scanning other consoles.
	var/datum/weakref/owner_fallback_ref
	var/datum/weakref/owner_principal_ref
	var/datum/weakref/owner_faction_ref
	var/launched_by_owner = FALSE
	/// Agents: the program file returns to the owner on recall.
	var/datum/netrun_file/agent_file
	var/home_address
	var/expires_at = 0
	var/return_pending = FALSE
	/// Dissolution can be triggered by combat and lifecycle in the same dispatch.
	var/remains_dropped = FALSE
	var/static/serial = 0

/mob/camera/netrun_entity/bot/entity_module_types()
	var/list/types = ..()
	// Autonomous agents do not need a rendered HUD, its fastprocess monitors,
	// or a second moving network endpoint. A player login can add the capability.
	types -= /datum/netrun_entity_module/neural_feedback
	var/navigation_slot = types.Find(/datum/netrun_entity_module/navigation)
	if(navigation_slot)
		types[navigation_slot] = /datum/netrun_entity_module/navigation/bot
	types |= program.behavior_modules
	types |= program.extra_behavior_modules
	types |= /datum/netrun_entity_module/agent_extensions
	return types

/mob/camera/netrun_entity/bot/Initialize(mapload, datum/component/netrun_node/start, program_id, datum/netrun_console/owner)
	program = SSnetrun.get_bot_program(program_id) || SSnetrun.get_bot_program(NETRUN_BOT_RAIDER)
	bot_kind = program.id
	net_faction = owner ? owner.get_personal_faction_id() : program.faction
	console_type = program.console_type
	max_integrity = program.max_integrity
	integrity = max_integrity
	if(owner)
		owner_ref = WEAKREF(owner)
		owner_principal_ref = WEAKREF(owner.personal_faction_principal())
		var/datum/netrun_faction/faction = SSnetrun.get_netrun_faction(net_faction)
		owner_faction_ref = faction ? WEAKREF(faction) : null
		var/mob/camera/netrun_entity/resident = owner.combat_self()
		var/datum/netrun_console/fallback = istype(resident) ? resident.dive_link?.entry_client_ref?.resolve() : null
		if(!fallback)
			var/datum/netrun_inventory/borrowed = owner.inventory?.borrowed_inventory_ref?.resolve()
			fallback = borrowed?.owner
		if(fallback && fallback != owner)
			owner_fallback_ref = WEAKREF(fallback)
		launched_by_owner = TRUE
	. = ..(mapload, start)
	if(QDELETED(src) || QDELETED(console))
		return
	console.operator = src
	if(is_network_visitor())
		console.access_session.node_access.Cut()
		console.access_session.network_access.Cut()
		console.access_session.residency_address = null
	console.inventory.local_store.capacity = program.storage
	serial++
	set_net_name("[program.name_prefix]-[serial < 10 ? "0" : ""][serial]", program.name)
	var/datum/netrun_persona/persona = get_persona()
	if(persona)
		persona.avatar = program.avatar
		persona.accent = program.accent
		persona.tagline = program.tagline
	home_address = start?.address
	if(!owner && program.lifetime)
		expires_at = world.time + program.lifetime + rand(0, 2 MINUTES)
	brain = new(src)
	if(is_network_visitor())
		brain.assign_visitor_objective()
	program.equip(src)
	if(is_network_visitor() && !console.daemon_capability("autobreach"))
		console.store_file(netrun_daemon_file("autobreach"))
	SSnetrun.bots |= src
	program.on_spawn(src)
	if(is_network_visitor() && host_node)
		brain.push_goal(new /datum/netrun_bot_goal/hack(brain, host_node))
	SEND_SIGNAL(src, COMSIG_NETRUN_ENTITY_MODULE_READY, null)
	host_node?.network?.add_log("Запущен автономный процесс [real_name] ([program.name]).")
	brain.schedule(1 SECONDS)

/mob/camera/netrun_entity/bot/Destroy()
	SSnetrun.bots -= src
	SSnetrun.note_bot_lost(src)
	QDEL_NULL(brain)
	QDEL_NULL(agent_file)
	owner_ref = null
	owner_fallback_ref = null
	owner_principal_ref = null
	owner_faction_ref = null
	program = null
	return ..()

/// Player possession suspends the autonomous clock. Returning control is a fact
/// that resumes behavior and releases presentation-only resources immediately.
/mob/camera/netrun_entity/bot/Logout()
	. = ..()
	remove_module("neural_feedback")
	brain?.wake_now()

/mob/camera/netrun_entity/bot/netrun_bot_kind()
	return bot_kind

/mob/camera/netrun_entity/bot/defense_threat()
	return !program?.sanctioned

/mob/camera/netrun_entity/bot/netrun_faction()
	return net_faction

/mob/camera/netrun_entity/bot/netrun_owner_console()
	RETURN_TYPE(/datum/netrun_console)
	var/datum/netrun_console/client = owner_ref?.resolve()
	if(owned_by(client))
		return client
	client = owner_fallback_ref?.resolve()
	return owned_by(client) ? client : null

/// A physical device can be shared, replaced or destroyed without changing its issuer.
/mob/camera/netrun_entity/bot/proc/owned_by(datum/netrun_console/client)
	if(QDELETED(client) || agent_orphaned())
		return FALSE
	var/datum/principal = owner_principal_ref?.resolve()
	return launched_by_owner && client.personal_faction_principal() == principal && client.get_personal_faction_id() == net_faction

/mob/camera/netrun_entity/bot/contact_state()
	if(is_stunned())
		return "оглушён"
	return brain?.state || "ожидание"

/mob/camera/netrun_entity/bot/get_netrun_combatant()
	RETURN_TYPE(/datum/component/netrun_combatant)
	return LoadComponent(/datum/component/netrun_combatant/entity/bot)

/// Only loss of the actual principal or its membership ends the owned lifetime.
/mob/camera/netrun_entity/bot/proc/agent_orphaned()
	if(!launched_by_owner)
		return FALSE
	var/datum/principal = owner_principal_ref?.resolve()
	var/datum/netrun_faction/private/personal/faction = owner_faction_ref?.resolve()
	return QDELETED(principal) || QDELETED(faction) || !istype(faction) || faction.id != net_faction || faction.principal_ref?.resolve() != principal

/// Visiting processes depart without being destroyed or generating free combat loot.
/mob/camera/netrun_entity/bot/proc/retire(reason)
	if(reason)
		brain.state = "процесс завершён: [reason]"
		host_node?.network?.add_log("Автономный процесс [real_name] завершён: [reason].")
	else
		host_node?.network?.add_log("Автономный процесс [real_name] завершил обход и покинул сеть.")
	qdel(src)

/mob/camera/netrun_entity/bot/dissolve()
	if(QDELETED(src))
		return
	var/datum/component/netrun_node/node = host_node
	drop_remains(node)
	var/datum/netrun_console/master = netrun_owner_console()
	master?.combat_log("Агент [real_name] уничтожен[node ? " в узле [node.address]" : ""].", "bad")
	node?.network?.add_log("Автономный процесс [real_name] завершён.")
	if(node)
		SSnetrun.post_event("purge", null, node.address)
	qdel(src)

/// Death transfers existing files, never a freshly generated copy of the loadout.
/mob/camera/netrun_entity/bot/proc/drop_remains(datum/component/netrun_node/node)
	if(remains_dropped || QDELETED(node))
		return
	remains_dropped = TRUE
	var/datum/netrun_file_store/store = console?.inventory.local_store
	if(!QDELETED(agent_file))
		var/datum/netrun_file/file = agent_file
		agent_file = null
		if(!istype(file, /datum/netrun_file/bot))
			var/datum/netrun_file/bot/container = new(file.name, file.kind, file.content, file.size, file.network_id)
			qdel(file)
			file = container
		if(!QDELETED(store))
			brain?.clear_goals()
			var/datum/netrun_file/bot/saved = file
			saved.size = program.file_size + store.used()
			saved.remember_agent(src)
		if(!node.leave_salvage(file, real_name))
			qdel(file)
		return
	if(QDELETED(store))
		return
	var/changed = FALSE
	for(var/datum/netrun_file/file as anything in store.files.Copy())
		if(!file.can_transfer(null, TRUE) || !store.remove(file))
			continue
		if(!node.leave_salvage(file, real_name, FALSE))
			qdel(file)
		else
			changed = TRUE
	if(changed)
		node.refresh_salvage()

/// Recall: the agent becomes a file in its owner's memory again (or debris when there is no room).
/mob/camera/netrun_entity/bot/proc/return_to_owner(datum/netrun_console/master)
	master = master || netrun_owner_console()
	var/datum/component/netrun_node/node = host_node
	if(agent_orphaned())
		dissolve()
		return FALSE
	if(QDELETED(master) || !master.owns_agent(src))
		return FALSE
	var/datum/component/netrun_node/source = master.route_source()
	if(return_pending || !node || !source || !agent_file)
		return FALSE
	var/datum/netrun_path_tree/tree = master.make_path_tree()
	if(master.is_locked() || !master.can_route(node, tree))
		qdel(tree)
		return FALSE
	var/list/route = reverseRange(tree.addresses_to(node.address))
	var/eta = master.latency_to(node, tree)
	qdel(tree)
	var/datum/netrun_request/agent_recall/packet = new(master, src, source)
	return_pending = TRUE
	return packet.send(eta, route)

/mob/camera/netrun_entity/bot/proc/agent_entry()
	var/datum/netrun_file_store/store = console.inventory.local_store
	var/list/orders = agent_orders()
	var/list/files = list()
	for(var/datum/netrun_file/file as anything in store.files)
		files += list(file.ui_entry(null))
	var/list/goals = list()
	for(var/datum/netrun_bot_goal/goal as anything in brain.goals)
		goals += list(list("id" = REF(goal), "name" = goal.name, "desc" = goal.describe(), "selected" = goal == brain.current_goal()))
	return list("ref" = REF(src), "name" = real_name, "bot_kind" = bot_kind,
		"node" = host_node?.address, "node_name" = host_node?.get_name(),
		"integrity" = round(integrity), "max_integrity" = max_integrity,
		"state" = contact_state(), "goal" = brain?.goal_text(),
		"storage" = list("used" = store.used(), "capacity" = store.capacity), "orders" = orders,
		"persona" = get_persona().ui_payload(FALSE), "files" = files, "programs" = console.combat_context.programs(), "goals" = goals,
		"behavior" = behavior_settings())

/// A primitive snapshot is safe to display, transport and persist independently.
/mob/camera/netrun_entity/bot/proc/behavior_settings()
	var/datum/netrun_agent_behavior/pattern/temperament/policy = netrun_actor_temperament(src)
	if(!policy)
		return null
	return list("strategy" = policy.strategy, "aggression" = policy.aggression, "caution" = policy.caution, "cooperation" = policy.cooperation)

/// Requests contain other control fields; persisted policy must contain only these.
/// Validation precedes all mutation and produces a fresh scalar-only snapshot.
/proc/netrun_agent_behavior_settings(list/options, strict = FALSE)
	if(!islist(options))
		return null
	var/list/keys = list("strategy", "aggression", "caution", "cooperation")
	if(strict)
		for(var/key in options)
			if(!(key in keys))
				return null
	var/list/result = list()
	for(var/key in keys)
		if(!(key in options))
			continue
		var/value = options[key]
		switch(key)
			if("strategy")
				if(!(value in list("profile", "patrol", "scavenge", "guard")))
					return null
			if("aggression", "caution")
				if(!isnum(value) || !IS_FINITE(value) || value < 0 || value > 100)
					return null
			if("cooperation")
				if(!(value in list(TRUE, FALSE)))
					return null
		result[key] = value
	return length(result) ? result : null

/mob/camera/netrun_entity/bot/proc/agent_orders()
	var/list/orders = list(list("id" = "recall", "name" = "Отозвать"), list("id" = "guard", "name" = "Перевести на выбранный узел", "needs_node" = TRUE), list("id" = "terminate", "name" = "Завершить"))
	orders += list(list("id" = "patrol", "name" = "Патрулировать доступную сеть"), list("id" = "command", "name" = "Команда выбранного узла", "needs_node" = TRUE))
	orders += list(list("id" = "collect", "name" = "Собрать трофеи на выбранном узле", "needs_node" = TRUE))
	orders += list(list("id" = "persona", "name" = "Личность"), list("id" = "upload", "name" = "Передать файл"), list("id" = "download", "name" = "Забрать файл"))
	orders += list(list("id" = "behavior", "name" = "Настроить поведение"))
	SEND_SIGNAL(src, COMSIG_NETRUN_AGENT_ORDER_LIST, orders)
	return orders

// MARK: Консоль бота

/datum/netrun_console/entity/bot
	name = "автономный процесс"

/datum/netrun_console/entity/bot/autonomous()
	return TRUE

/datum/netrun_console/entity/bot/note_user_action()
	return

/datum/netrun_console/entity/bot/note_ui_activity(defer_context_refresh = FALSE)
	return

/// Autonomous logs/operations have no terminal observer. Wake only actual timed gameplay.
/datum/netrun_console/entity/bot/invalidate_ui(immediate = TRUE)
	ui_dirty = TRUE
	if(needs_processing())
		activate()
	var/mob/camera/netrun_entity/bot/bot = host
	var/datum/netrun_console/master = bot?.netrun_owner_console()
	if(master?.is_ui_active())
		master.invalidate_ui(immediate)

/datum/netrun_console/entity/bot/record_operation(datum/netrun_packet_context/operation)
	. = ..()
	var/mob/camera/netrun_entity/bot/bot = host
	bot?.brain?.command_updated(operation)

/datum/netrun_console/proc/track_command_packet(datum/netrun_request/command/packet)
	return

/datum/netrun_console/entity/bot/track_command_packet(datum/netrun_request/command/packet)
	var/mob/camera/netrun_entity/bot/bot = host
	if(bot?.brain?.command_nonce && packet.operation?.nonce == bot.brain.command_nonce)
		bot.brain.command_packet_ref = WEAKREF(packet)

/// Arrival still reacts on the machine side; there is no player UI to wake.
/datum/netrun_console/entity/bot/finish_user_action(datum/component/netrun_node/node)
	if(QDELETED(node))
		return
	node.reconcile_state()
	node.wake_defenses()

/// Nobody watches a bot terminal: keep a bounded log without waking UI machinery.
/datum/netrun_console/entity/bot/log_line(text, kind = "label", notice_topic)
	log += list(list("time" = STATION_TIME_TIMESTAMP("hh:mm:ss", world.time), "text" = text, "kind" = kind))
	if(length(log) > NETRUN_MAX_CONSOLE_LOG)
		log.Cut(1, length(log) - NETRUN_MAX_CONSOLE_LOG + 1)
	SEND_SIGNAL(src, COMSIG_NETRUN_CONSOLE_EVENT, text, kind)

/datum/netrun_console/entity/bot/log_source()
	var/mob/camera/netrun_entity/bot/bot = host
	return "автономный процесс [bot?.real_name]"

/// A station custodian works legally inside its department LANs.
/datum/netrun_console/entity/bot/custodian
	/// LAN ids of the custodian's department.
	var/list/jurisdiction = list()

/datum/netrun_console/entity/bot/custodian/compute_legit_node_level(datum/component/netrun_node/node, fresh = FALSE)
	. = ..()
	if(node?.network && (node.network.id in jurisdiction))
		. = max(., NETRUN_ACCESS_USER)

/datum/netrun_console/entity/bot/custodian/legit_network_level(datum/netrun_network/network, fresh = FALSE)
	. = ..()
	if(network && (network.id in jurisdiction))
		. = max(., NETRUN_ACCESS_GUEST)

// MARK: Боевой интерфейс бота

/datum/component/netrun_combatant/entity/bot
	kind = "bot"

/datum/component/netrun_combatant/entity/bot/Initialize()
	if(!istype(parent, /mob/camera/netrun_entity/bot))
		return COMPONENT_INCOMPATIBLE

/datum/component/netrun_combatant/entity/bot/damage(amount, reason, datum/netrun_console/attacker)
	var/mob/camera/netrun_entity/bot/bot = parent
	. = ..()
	if(!QDELETED(bot))
		bot.brain?.note_attacker(attacker)

/datum/component/netrun_combatant/entity/bot/stun(duration)
	var/mob/camera/netrun_entity/bot/bot = parent
	. = ..()
	bot.brain?.wake_now()

/datum/component/netrun_combatant/entity/bot/protected_by_station()
	var/mob/camera/netrun_entity/bot/bot = parent
	return bot.net_faction == NETRUN_FACTION_STATION

/datum/component/netrun_combatant/entity/bot/ui_entry()
	. = ..()
	var/mob/camera/netrun_entity/bot/bot = parent
	.["bot_kind"] = bot.bot_kind
	.["faction"] = bot.net_faction
	.["goal"] = bot.brain?.goal_text()
	.["hostile"] = bot.net_faction == NETRUN_FACTION_ROGUE

// MARK: Агенты игроков

/datum/netrun_console/proc/agents()
	. = list()
	var/personal_id = get_personal_faction_id()
	if(!personal_id)
		return
	for(var/mob/camera/netrun_entity/bot/bot as anything in SSnetrun.bots)
		if(!QDELETED(bot) && bot.net_faction == personal_id && bot.owned_by(src))
			. += bot

/datum/netrun_console/proc/owns_agent(mob/camera/netrun_entity/bot/agent)
	return !QDELETED(agent) && agent.owned_by(src)

/datum/netrun_console/proc/agents_payload()
	if(!length(SSnetrun.bots))
		return null
	var/list/entries = list()
	for(var/mob/camera/netrun_entity/bot/bot as anything in agents())
		entries += list(bot.agent_entry())
	return length(entries) ? entries : null

/// The entity's own node, otherwise the requested/selected node with USER and a route.
/datum/netrun_console/proc/agent_launch_site(address)
	var/mob/camera/netrun_entity/self = combat_self()
	if(istype(self))
		return self.host_node
	var/datum/component/netrun_node/node = SSnetrun.find_node(address) || selected_node()
	if(!node || !can_route(node) || !node.is_online(node != connection.jack) || node_level(node) < NETRUN_ACCESS_USER)
		return null
	return node

/datum/netrun_console/proc/launch_bot_file(uid, address)
	var/datum/netrun_file/file = find_local_file(uid)
	if(!file || file.kind != NETRUN_FILE_BOT)
		log_line("Файл агента не найден.", "bad")
		return FALSE
	var/datum/netrun_bot_program/program = SSnetrun.get_bot_program(file.content)
	if(!program?.file_size)
		log_line("Программа агента [file.name] повреждена.", "bad")
		return FALSE
	if(is_locked())
		log_line("Точка подключения заблокирована.", "bad")
		return FALSE
	if(length(agents()) >= NETRUN_MAX_AGENTS_PER_CONSOLE)
		log_line("Уже работают [NETRUN_MAX_AGENTS_PER_CONSOLE] агента. Отзовите одного из них.", "bad")
		return FALSE
	if(length(SSnetrun.bots) >= NETRUN_MAX_BOTS)
		log_line("Сеть перегружена автономными процессами: запуск отклонён.", "bad")
		return FALSE
	var/datum/component/netrun_node/site = agent_launch_site(address)
	if(!site)
		log_line("Агента негде запустить: нужен выбранный узел с доступом ПОЛЬЗОВАТЕЛЯ и маршрутом.", "bad")
		return FALSE
	var/datum/netrun_file_store/store = inventory.store_for(file)
	if(!store?.remove(file))
		return FALSE
	if(inventory.selected_file_uid == file.uid)
		inventory.selected_file_uid = null
	var/mob/camera/netrun_entity/bot/agent = SSnetrun.spawn_bot(program.id, site, src)
	if(!agent || !owns_agent(agent))
		if(agent)
			qdel(agent)
		store.insert(file, TRUE)
		log_line("Агента не удалось запустить.", "bad")
		return FALSE
	var/datum/netrun_file/acquired_key/delegated = snapshot_acquired_key("agent-access.grants", NETRUN_ACCESS_USER)
	var/original_size = file.size
	var/had_stored_files = FALSE
	var/required_memory = agent.console.inventory.local_store.used()
	var/credential_memory = delegated?.size || 0
	if(delegated && agent.console.inventory.local_store.acquired_key_target())
		credential_memory = 0
	if(istype(file, /datum/netrun_file/bot))
		var/datum/netrun_file/bot/saved = file
		if(!isnull(saved.stored_files))
			had_stored_files = TRUE
			required_memory = netrun_storage_used(saved.stored_files)
			for(var/datum/netrun_file/acquired_key/key as anything in saved.stored_files)
				if(istype(key))
					credential_memory = 0
					break
	if(delegated && required_memory + credential_memory > agent.console.inventory.local_store.capacity)
		qdel(delegated)
		qdel(agent)
		store.insert(file, TRUE)
		log_line("В памяти агента нет ячейки для передаваемого ключа; исходный файл и его память сохранены.", "bad")
		return FALSE
	agent.agent_file = file
	if(istype(file, /datum/netrun_file/bot))
		var/datum/netrun_file/bot/saved = file
		if(!saved.restore_agent(agent))
			qdel(delegated)
			agent.agent_file = null
			qdel(agent)
			store.insert(file, TRUE)
			return FALSE
	if(delegated)
		var/datum/netrun_file/acquired_key/installed = agent.console.store_file(delegated)
		if(!installed)
			if(had_stored_files)
				var/datum/netrun_file/bot/saved = file
				saved.remember_agent(agent)
				file.size = original_size
			agent.agent_file = null
			qdel(delegated)
			qdel(agent)
			store.insert(file, TRUE)
			return FALSE
		agent.console.inventory.canonical_key_uid = installed.uid
	// Unsigned bootstrap/delegated residency remains non-exportable. Actual
	// hacked/file authority is carried only by the removable owned key above.
	for(var/address_key in access_session.node_access)
		var/datum/component/netrun_node/known_node = SSnetrun.find_node(address_key)
		if(known_node && !access_session.exportable_node_level(known_node))
			agent.console.access_session.grant_node(known_node, min(access_session.direct_node_level(known_node), NETRUN_ACCESS_USER))
	for(var/network_key in access_session.network_access)
		var/datum/netrun_network/known_network = SSnetrun.networks[network_key]
		if(known_network && !access_session.exportable_network_level(known_network))
			agent.console.access_session.grant_network(known_network, access_session.direct_network_level(known_network))
	log_line("Агент [agent.real_name] запущен в узле [site.get_name()] [site.address].", "good")
	site.add_log("[log_source()]: запущен агент [agent.real_name].")
	return TRUE

/datum/netrun_console/proc/agent_order(ref, order, address, list/options)
	var/mob/camera/netrun_entity/bot/agent = locate(ref)
	if(!istype(agent) || !owns_agent(agent))
		log_line("Агент не найден.", "bad")
		return FALSE
	var/known_order = FALSE
	for(var/list/entry as anything in agent.agent_orders())
		if(entry["id"] == order)
			known_order = TRUE
			break
	if(!known_order)
		log_line("Неизвестный приказ агенту.", "bad")
		return FALSE
	var/list/behavior
	if(order == "behavior")
		behavior = netrun_agent_behavior_settings(options)
		if(!behavior)
			log_line("Недопустимые настройки поведения агента.", "bad")
			return FALSE
	var/datum/component/netrun_node/site = agent.host_node
	var/datum/netrun_path_tree/tree = make_path_tree()
	if(!site || is_locked() || !can_route(site, tree))
		qdel(tree)
		log_line("Нет действующего маршрута к агенту.", "bad")
		return FALSE
	var/eta = latency_to(site, tree)
	var/list/route = tree.addresses_to(site.address)
	qdel(tree)
	var/list/arguments = list("order" = order, "address" = order == "behavior" ? null : (address || selected_node()?.address))
	if(order != "behavior")
		for(var/key in list("command", "uid", "name", "avatar", "accent", "tagline", "theme"))
			if(options && (key in options))
				arguments[key] = options[key]
	for(var/key in behavior)
		arguments[key] = behavior[key]
	var/datum/netrun_request/agent_control/packet = new(src, agent, arguments)
	return packet.send(eta, route)

/// Called only by an authenticated, freshly delivered control packet.
/datum/netrun_console/proc/apply_agent_order(mob/camera/netrun_entity/bot/agent, list/options)
	if(!owns_agent(agent))
		return FALSE
	// Extension handlers use the reporting client too. Commit this destination
	// only if the already authenticated delivery accepts its actual action.
	var/datum/weakref/previous_client = agent.owner_ref
	agent.owner_ref = WEAKREF(src)
	. = execute_agent_order(agent, options)
	if(!. && !QDELETED(agent))
		agent.owner_ref = previous_client

/datum/netrun_console/proc/execute_agent_order(mob/camera/netrun_entity/bot/agent, list/options)
	if(!owns_agent(agent))
		return FALSE
	if(SEND_SIGNAL(agent, COMSIG_NETRUN_AGENT_CONTROL, src, options))
		return TRUE
	var/order = options["order"]
	switch(order)
		if("recall")
			agent.brain.clear_goals()
			agent.brain.push_goal(new /datum/netrun_bot_goal/recall(agent.brain))
			agent.brain.wake_now()
			log_line("Агенту [agent.real_name] отдан приказ вернуться.")
			return TRUE
		if("terminate")
			log_line("Агент [agent.real_name] завершён: его файл остаётся в обломках узла.", "average")
			agent.dissolve()
			return TRUE
		if("guard")
			var/datum/component/netrun_node/node = SSnetrun.find_node(options["address"])
			if(!node || !can_route(node) || node_level(node) < NETRUN_ACCESS_USER)
				log_line("Новый пост агента должен быть узлом с вашим доступом ПОЛЬЗОВАТЕЛЯ.", "bad")
				return FALSE
			// An explicit standing order replaces the default strategy, retaining traits.
			agent.get_module_host().mutate_pattern("temperament", list("strategy" = "profile"))
			// The owner delegates residency on the new post.
			agent.console.access_session.grant_node(node, NETRUN_ACCESS_USER)
			agent.brain.order = "guard"
			agent.brain.order_node_ref = WEAKREF(node)
			agent.brain.clear_goals()
			agent.brain.wake_now()
			log_line("Агент [agent.real_name] переводится на узел [node.get_name()] [node.address].")
			return TRUE
		if("collect")
			var/datum/component/netrun_node/node = SSnetrun.find_node(options["address"])
			if(QDELETED(node) || !can_route(node) || node_level(node) < NETRUN_ACCESS_USER)
				log_line("Для сбора трофеев нужен узел с вашим доступом ПОЛЬЗОВАТЕЛЯ.", "bad")
				return FALSE
			if(!agent.brain.best_salvage(node))
				log_line("В выбранном узле нет обломков, которые помещаются в память агента.", "average")
				return FALSE
			agent.get_module_host().mutate_pattern("temperament", list("strategy" = "profile"))
			// This delegates residency only. No private device disk is read, and
			// every physical hop still observes gates and the agent's own authority.
			agent.console.access_session.grant_node(node, NETRUN_ACCESS_USER)
			agent.brain.clear_goals()
			agent.brain.order = "guard"
			agent.brain.order_node_ref = WEAKREF(node)
			agent.brain.push_goal(new /datum/netrun_bot_goal/salvage(agent.brain, node))
			agent.brain.wake_now()
			log_line("[agent.real_name]: собрать ценные обломки в узле [node.get_name()] и остаться на посту.", "good")
			return TRUE
		if("patrol")
			agent.get_module_host().mutate_pattern("temperament", list("strategy" = "profile"))
			agent.brain.clear_goals()
			agent.brain.order = "patrol"
			agent.brain.push_goal(new /datum/netrun_bot_goal/patrol(agent.brain))
			agent.brain.wake_now()
			return TRUE
		if("command")
			var/datum/component/netrun_node/node = SSnetrun.find_node(options["address"])
			var/command = options["command"]
			if(!node || !istext(command) || !(command in node.all_command_ids()))
				return FALSE
			agent.brain.clear_goals()
			agent.brain.order = "command"
			agent.brain.order_command = command
			agent.brain.order_command_address = node.address
			agent.brain.push_goal(new /datum/netrun_bot_goal/command(agent.brain, node, command))
			agent.brain.wake_now()
			return TRUE
		if("persona")
			if(("theme" in options) && !(options["theme"] in netrun_theme_ids()))
				return FALSE
			if(!agent.console.update_persona(options, agent))
				return FALSE
			if("theme" in options)
				agent.console.set_ui_theme(options["theme"], agent)
			return TRUE
		if("behavior")
			var/list/changes = netrun_agent_behavior_settings(options)
			if(!changes || !agent.get_module_host().mutate_pattern("temperament", changes))
				return FALSE
			agent.console.invalidate_ui()
			log_line("Поведение агента [agent.real_name] обновлено.", "good")
			return TRUE
		if("upload", "download")
			var/datum/netrun_console/source = order == "upload" ? src : agent.console
			var/datum/netrun_console/destination = order == "upload" ? agent.console : src
			var/datum/netrun_file/file = source.find_local_file(options["uid"])
			var/datum/netrun_file_store/store = source.inventory.store_for(file)
			return !!store?.transfer_to(destination.inventory.local_store, file, TRUE)
	return FALSE

/// Owner controls cross exactly the same cancellable delivery boundary as device commands.
/datum/netrun_request/agent_control
	parent_type = /datum/netrun_request/delivery
	var/mob/camera/netrun_entity/bot/agent
	var/list/arguments
	operation_kind = "agent"
	operation_label = "Приказ агенту"

/datum/netrun_request/agent_control/New(datum/netrun_console/master, mob/camera/netrun_entity/bot/agent, list/arguments)
	..(master, agent.host_node, agent.host_node.network, master.operator)
	src.agent = agent
	src.arguments = arguments.Copy()
	dependencies += agent
	RegisterSignal(agent, COMSIG_PARENT_QDELETING, TYPE_PROC_REF(/datum/netrun_request/delivery, on_dependency_deleted))
	operation.capture(src.arguments)

/datum/netrun_request/agent_control/Destroy()
	agent = null
	arguments = null
	return ..()

/datum/netrun_request/agent_control/execute()
	if(!console.owns_agent(agent) || agent.host_node != node || sender != console.operator || console.is_locked())
		return reject("Агент, владелец или место назначения изменились.")
	node.join_network()
	var/datum/netrun_path_tree/tree = console.make_path_tree()
	var/valid = node.network == sent_network && node.is_online() && console.can_route(node, tree)
	if(valid)
		operation.receive(tree.addresses_to(node.address))
	qdel(tree)
	if(!valid)
		return reject("Действующего маршрута к агенту больше нет.")
	return console.apply_agent_order(agent, arguments)

/// Returning an agent is a real in-flight file. The live process retains everything until acceptance.
/datum/netrun_request/agent_recall
	parent_type = /datum/netrun_request/delivery
	var/mob/camera/netrun_entity/bot/agent
	var/datum/component/netrun_node/owner_node
	operation_kind = "file"
	operation_label = "Возврат агента"

/datum/netrun_request/agent_recall/New(datum/netrun_console/master, mob/camera/netrun_entity/bot/agent, datum/component/netrun_node/owner_node)
	var/datum/netrun_packet_context/context = new("file", "Возврат агента [agent.real_name]", agent.host_node.address, owner_node.address, "agent_recall", master)
	..(master, agent.host_node, agent.host_node.network, master.operator, null, context)
	src.agent = agent
	src.owner_node = owner_node
	for(var/datum/dependency as anything in list(agent, owner_node))
		if(dependency in dependencies)
			continue
		dependencies += dependency
		RegisterSignal(dependency, COMSIG_PARENT_QDELETING, TYPE_PROC_REF(/datum/netrun_request/delivery, on_dependency_deleted))

/datum/netrun_request/agent_recall/Destroy()
	if(!QDELETED(agent))
		agent.return_pending = FALSE
		agent.brain?.wake_now()
	agent = null
	owner_node = null
	return ..()

/datum/netrun_request/agent_recall/execute()
	if(!console.owns_agent(agent) || !agent.agent_file || agent.host_node != node || sender != console.operator || console.is_locked())
		return reject("Процесс или его владелец изменились до возврата.")
	var/datum/component/netrun_node/current_source = console.route_source()
	var/datum/netrun_path_tree/tree = console.make_path_tree()
	var/valid = current_source == owner_node && node.network == sent_network && node.is_online() && console.can_route(node, tree)
	if(valid)
		operation.receive(reverseRange(tree.addresses_to(node.address)))
	qdel(tree)
	if(!valid)
		return reject("Маршрут возврата агента потерян.")
	var/datum/netrun_file/file = agent.agent_file
	var/previous_size = file.size
	if(istype(file, /datum/netrun_file/bot))
		file.size = agent.program.file_size + agent.console.inventory.local_store.used()
	if(!console.store_file(file))
		file.size = previous_size
		return reject("В памяти владельца нет места для агента с его файлами.")
	if(istype(file, /datum/netrun_file/bot))
		var/datum/netrun_file/bot/saved = file
		saved.remember_agent(agent)
	agent.agent_file = null
	console.log_line("Агент [agent.real_name] вернулся: [file.name] и его память сохранены.", "good")
	node.network?.add_log("Автономный процесс [agent.real_name] отозван владельцем.")
	qdel(agent)
	return TRUE

/// Agent files own recalled inventory and cosmetics; copies have independent contents.
/datum/netrun_file/bot
	var/list/datum/netrun_file/stored_files
	var/list/stored_persona
	var/list/stored_behavior
	var/stored_name
	var/stored_order
	var/stored_post
	var/stored_command
	var/stored_command_address

/datum/netrun_file/bot/Destroy()
	QDEL_LIST(stored_files)
	stored_persona = null
	stored_behavior = null
	return ..()

/datum/netrun_file/bot/copy()
	var/datum/netrun_file/bot/result = new(name, kind, content, size, network_id)
	result.stored_persona = stored_persona?.Copy()
	result.stored_behavior = islist(stored_behavior) ? stored_behavior.Copy() : stored_behavior
	result.stored_name = stored_name
	result.stored_order = stored_order
	result.stored_post = stored_post
	result.stored_command = stored_command
	result.stored_command_address = stored_command_address
	if(!isnull(stored_files))
		result.stored_files = list()
		for(var/datum/netrun_file/file as anything in stored_files)
			result.stored_files += file.copy()
	return result

/datum/netrun_file/bot/proc/remember_agent(mob/camera/netrun_entity/bot/agent)
	stored_persona = agent.get_persona().ui_payload(FALSE)
	stored_behavior = agent.behavior_settings()
	stored_name = agent.real_name
	stored_order = agent.brain.order
	stored_post = agent.brain.post_node()?.address
	stored_command = agent.brain.order_command
	stored_command_address = agent.brain.order_command_address
	stored_files = list()
	var/datum/netrun_file_store/store = agent.console.inventory.local_store
	for(var/datum/netrun_file/file as anything in store.files.Copy())
		store.remove(file)
		stored_files += file

/datum/netrun_file/bot/proc/restore_agent(mob/camera/netrun_entity/bot/agent)
	var/list/behavior
	if(!isnull(stored_behavior))
		behavior = netrun_agent_behavior_settings(stored_behavior, TRUE)
		if(!behavior || !netrun_actor_temperament(agent))
			return FALSE
	if(isnull(stored_files))
		return !behavior || agent.get_module_host().mutate_pattern("temperament", behavior)
	var/required = 0
	for(var/datum/netrun_file/file as anything in stored_files)
		required += file.size
	var/datum/netrun_file_store/store = agent.console.inventory.local_store
	if(required > store.capacity)
		return FALSE
	if(behavior && !agent.get_module_host().mutate_pattern("temperament", behavior))
		return FALSE
	for(var/datum/netrun_file/file as anything in store.files.Copy())
		store.delete_file(file)
	for(var/datum/netrun_file/file as anything in stored_files)
		store.insert(file)
	stored_files = null
	var/datum/netrun_persona/profile = agent.get_persona()
	if(stored_persona)
		profile.avatar = stored_persona["avatar"]
		profile.accent = stored_persona["accent"]
		profile.tagline = stored_persona["tagline"]
		profile.alias = stored_persona["alias"]
		profile.theme = stored_persona["theme"]
	if(stored_name)
		agent.set_net_name(stored_name)
	agent.brain.order = stored_order
	var/datum/component/netrun_node/post = SSnetrun.find_node(stored_post)
	agent.brain.order_node_ref = post ? WEAKREF(post) : null
	agent.brain.order_command = stored_command
	agent.brain.order_command_address = stored_command_address
	var/datum/component/netrun_node/target = SSnetrun.find_node(stored_command_address)
	if(stored_order == "command" && target && (stored_command in target.all_command_ids()))
		agent.brain.push_goal(new /datum/netrun_bot_goal/command(agent.brain, target, stored_command))
	size = agent.program.file_size
	return TRUE

// MARK: Население

/datum/controller/subsystem/netrun
	var/list/mob/camera/netrun_entity/bot/bots = list()
	/// Unit tests spawn their own bots.
	var/bots_enabled = NETRUN_AUTONOMOUS_CONTENT
	var/next_bot_census = 0
	var/rogue_wave_at = 0
	var/police_respawn_at = 0
	var/custodian_respawn_at = 0
	var/recycler_respawn_at = 0
	/// Spawn candidates are addresses cached at a topology boundary, not polled every census.
	var/list/bot_spawn_pools
	var/bot_spawn_revision = -1
	var/bot_spawn_index_builds = 0
	var/bot_spawn_candidate_checks = 0

/datum/controller/subsystem/netrun/proc/spawn_bot(program_id, datum/component/netrun_node/node, datum/netrun_console/owner)
	if(QDELETED(node) || QDELETED(node.parent) || !node.is_online() || length(bots) >= NETRUN_MAX_BOTS)
		return null
	var/turf/spot = node.physical_turf()
	if(!spot)
		return null
	var/mob/camera/netrun_entity/bot/bot = new(spot, node, program_id, owner)
	return QDELETED(bot) ? null : bot

/datum/controller/subsystem/netrun/proc/note_bot_lost(mob/camera/netrun_entity/bot/bot)
	switch(bot.bot_kind)
		if(NETRUN_BOT_POLICE)
			police_respawn_at = world.time + 5 MINUTES
		if(NETRUN_BOT_CUSTODIAN)
			custodian_respawn_at = world.time + 8 MINUTES
		if(NETRUN_BOT_RECYCLER)
			recycler_respawn_at = world.time + 4 MINUTES

/datum/controller/subsystem/netrun/proc/count_bots(kind)
	. = 0
	for(var/mob/camera/netrun_entity/bot/bot as anything in bots)
		if(!QDELETED(bot) && bot.bot_kind == kind)
			.++

/datum/controller/subsystem/netrun/proc/count_bot_faction(faction)
	. = 0
	for(var/mob/camera/netrun_entity/bot/bot as anything in bots)
		if(!QDELETED(bot) && bot.net_faction == faction)
			.++

/// Department key of a LAN, from the area its APC serves.
/proc/netrun_network_department(datum/netrun_network/network)
	return network?.area ? netrun_department_key(network.area) : null

/// A stationary, online, unfortified node of the given departments (any station LAN when null).
/datum/controller/subsystem/netrun/proc/bot_spawn_node(list/departments)
	var/datum/netrun_topology/graph = ensure_topology()
	if(!bot_spawn_pools || bot_spawn_revision != graph.revision)
		bot_spawn_revision = graph.revision
		bot_spawn_index_builds++
		bot_spawn_pools = list("all" = list())
		for(var/id in networks)
			var/datum/netrun_network/network = networks[id]
			if(network.isolated)
				continue
			var/department = netrun_network_department(network) || "general"
			if(!bot_spawn_pools[department])
				bot_spawn_pools[department] = list()
			for(var/datum/component/netrun_node/node as anything in network.nodes)
				if(QDELETED(node) || QDELETED(node.parent) || node.is_dynamic())
					continue
				bot_spawn_pools["all"] += node.address
				bot_spawn_pools[department] += node.address
	var/list/pools = departments || list("all")
	for(var/attempt in 1 to 16)
		var/list/candidates = bot_spawn_pools[pick(pools)]
		if(!length(candidates))
			continue
		var/datum/component/netrun_node/node = find_node(pick(candidates))
		bot_spawn_candidate_checks++
		if(!QDELETED(node) && !QDELETED(node.parent) && !node.fortress && !node.is_dynamic() && node.is_online())
			return node
	return null

/// Visitors enter at a functioning external network relay. Without one they can
/// arrive only on a low-security public/cargo endpoint, never inside a closed department.
/datum/controller/subsystem/netrun/proc/bot_entry_node()
	var/datum/netrun_topology/graph = ensure_topology()
	var/list/entries = list()
	for(var/address in graph.registered_relays)
		var/datum/component/netrun_node/node = graph.registered_relays[address]
		// Walls/turrets do not erase the physical external entry. A real closed
		// gate remains a barrier; creating a visitor must not bypass it.
		if(netrun_relay_entry_available(node))
			entries += node
	if(length(entries))
		return pick(entries)
	var/datum/component/netrun_node/fallback = bot_spawn_node(list("general", "cargo"))
	return fallback?.network?.security <= 2 ? fallback : null

/// A displayed player session or a connected resident keeps ambient arrivals relevant.
/// Circuits and unattended agents cannot populate a station by themselves.
/datum/controller/subsystem/netrun/proc/has_active_netrunners()
	for(var/datum/netrun_console/console as anything in consoles)
		if(QDELETED(console))
			continue
		var/mob/camera/netrun_entity/entity = console.combat_self()
		if(entity?.client || entity?.dive_link?.body?.client)
			return TRUE
		if(!console.autonomous() && console.is_ui_active())
			return TRUE
	return FALSE

/// Housekeeping: ambient arrivals pause without players; existing agents retain their lifetimes.
/datum/controller/subsystem/netrun/proc/maintain_bots()
	if(!bots_enabled || world.time < next_bot_census)
		return
	next_bot_census = world.time + 20 SECONDS
	for(var/mob/camera/netrun_entity/bot/bot as anything in bots.Copy())
		if(QDELETED(bot))
			bots -= bot
	if(!has_active_netrunners())
		// Pausing a quiet network must not accumulate overdue waves for the next visitor.
		rogue_wave_at = 0
		return
	if(!rogue_wave_at)
		rogue_wave_at = world.time + rand(30 SECONDS, 60 SECONDS)
	if(count_bots(NETRUN_BOT_POLICE) < NETRUN_POLICE_QUOTA && world.time >= police_respawn_at)
		var/datum/component/netrun_node/node = bot_entry_node()
		var/mob/camera/netrun_entity/bot/police = spawn_bot(NETRUN_BOT_POLICE, node)
		police?.host_node?.network?.add_log("На дежурство заступил процесс сетевой полиции [police.real_name].")
		if(police)
			return
	if(world.time >= custodian_respawn_at && count_bots(NETRUN_BOT_CUSTODIAN) < NETRUN_CUSTODIAN_QUOTA)
		spawn_custodian()
	if(world.time >= recycler_respawn_at && count_bots(NETRUN_BOT_RECYCLER) < NETRUN_RECYCLER_QUOTA)
		spawn_bot(NETRUN_BOT_RECYCLER, bot_spawn_node())
	if(world.time >= rogue_wave_at)
		rogue_wave_at = world.time + rand(45 SECONDS, 90 SECONDS)
		spawn_visitor_wave()

/// One custodian per department without one, among departments that keep patrols.
/datum/controller/subsystem/netrun/proc/spawn_custodian()
	var/list/covered = list()
	for(var/mob/camera/netrun_entity/bot/bot as anything in bots)
		var/datum/netrun_console/entity/bot/custodian/console = bot.console
		if(!QDELETED(bot) && istype(console))
			for(var/id in console.jurisdiction)
				covered[netrun_network_department(networks[id])] = TRUE
	for(var/department in list("engineering", "medical", "science", "command", "security"))
		if(covered[department])
			continue
		var/list/jurisdiction = list()
		for(var/id in networks)
			var/datum/netrun_network/network = networks[id]
			if(!network.isolated && network.security >= 2 && netrun_network_department(network) == department)
				jurisdiction += id
		if(!length(jurisdiction))
			continue
		var/mob/camera/netrun_entity/bot/custodian = spawn_bot(NETRUN_BOT_CUSTODIAN, bot_spawn_node(list(department)))
		var/datum/netrun_console/entity/bot/custodian/console = custodian?.console
		if(istype(console))
			console.jurisdiction = jurisdiction
		return custodian
	return null
