/**
 * Консоль - общий датум для всех точек подключения к сети.
 * Терминал, кибердека, имплант, NTOS-программа и сущность держат свою консоль
 * и отличаются только тем, откуда идёт подключение (origin) и куда бьёт трассировка.
 */
/datum/netrun_console
	/// The active interval starts when the scheduler wakes this session.
	var/last_netrun_tick
	var/datum/netrun_ui_source
	var/name = "консоль"
	/// Физический носитель: терминал, дека, имплант, компьютер или сущность
	var/atom/host
	var/origin = NETRUN_ORIGIN_TERMINAL
	/// Type configuration is consumed once; mutable state belongs to the sessions.
	var/initial_storage_capacity = 6 * NETRUN_STORAGE_SCALE
	var/initial_can_breach = TRUE
	var/datum/netrun_connection/connection
	var/datum/netrun_access_session/access_session
	var/datum/netrun_intrusion_session/intrusion
	var/datum/netrun_inventory/inventory
	var/datum/netrun_map_view/map_view
	var/datum/netrun_remote_session/remote_session
	var/list/log = list()
	/// Small primitive event ring; presentation never inserts rows into gameplay panels.
	var/list/notices = list()
	var/notice_serial = 0
	var/last_notice_text
	var/last_notice_kind
	var/last_notice_topic
	var/last_notice_at = -INFINITY
	/// Последний оператор - от его ID считается легальный доступ
	var/mob/operator
	var/next_command = 0
	/// Each workspace page owns the available screen area; hidden maps are not serialized.
	var/workspace_view = "terminal"
	/// One consistent, request-local topology snapshot during ui_data serialization.
	var/datum/netrun_path_tree/ui_routes
	/// Кеш на время одного ui_data: доступы оператора и уровни сетей
	var/list/access_cache
	var/list/network_level_cache
	/// Read-only caches expire with a UI snapshot; execution never trusts these.
	var/list/ui_node_levels
	var/list/ui_legit_levels
	var/list/ui_latency
	var/list/ui_commands
	var/list/ui_keys
	var/list/ui_bonuses
	var/list/ui_files
	var/list/ui_network_catalog
	var/ui_uplink_value = FALSE
	var/ui_uplink_refresh = -INFINITY
	var/ui_dirty = TRUE
	/// Domain changes coalesce until the scheduled repaint; explicit input may flush now.
	var/ui_event_pending = FALSE
	var/ui_processing = FALSE
	/// Acknowledgement confirms receipt only, never access or action success.
	var/input_ack
	var/ui_flushing = FALSE
	var/datum/netrun_interaction/interaction
	var/datum/netrun_security_session/security_session
	var/datum/netrun_file_exchange/file_exchange
	/// UI polling renews this lease, including consoles embedded in NTOS windows.
	var/last_ui_at = -INFINITY
	/// Actual snapshots, independently of activity leases renewed by incoming input.
	var/ui_rendered_at = -INFINITY
	/// TRUE only inside one ui_data serialization pass; enables per-pass projection reuse.
	var/ui_serializing = FALSE
	/// Projection-context snapshot shared by catalog/CLI validity checks within one pass.
	var/list/ui_projection_cache
	/// TRUE when ui_routes is a borrowed shared table that must not be qdel()ed on teardown.
	var/ui_routes_borrowed = FALSE
	/// Resolved selected node for one pass; selected_address cannot change during serialization.
	var/datum/component/netrun_node/ui_selected_node_cache
	var/ui_selected_resolved = FALSE
	/// Keep repainting until here: covers a live countdown plus a one-second tail so its final
	/// frame (lock cleared, trace hit zero) is always drawn even though that has no change signal.
	var/live_refresh_until = 0

/datum/netrun_console/New(atom/host, origin)
	src.host = host
	if(origin)
		src.origin = origin
	connection = new(src)
	access_session = new(src)
	intrusion = new(src)
	intrusion.can_breach = initial_can_breach
	inventory = new(src, initial_storage_capacity)
	remote_session = new(src)
	map_view = new(src)
	combat_context = new(src)
	interaction = new(src)
	security_session = new(src)
	file_exchange = new(src)
	RegisterSignal(inventory, COMSIG_NETRUN_INVENTORY_CHANGED, PROC_REF(on_session_changed))
	RegisterSignal(src, COMSIG_NETRUN_COMBAT_CHANGED, PROC_REF(on_session_changed))
	SSnetrun.consoles += src
	if(origin == NETRUN_ORIGIN_ENTITY)
		activate()
	log_line("Сеанс открыт. help — команды и обучение; ls — файлы памяти и шарда; Tab — дополнение команды. Выберите узел на карте и откройте «Справку узла».", "good")

/datum/netrun_console/Destroy()
	QDEL_NULL(security_session)
	QDEL_NULL(file_exchange)
	stop_ui_observation()
	SSnetrun.consoles -= src
	SSnetrun.active_consoles -= src
	SSnetrun.currentbreaches -= src
	SSnetrun.task_scheduler?.cancel("console", src)
	QDEL_NULL(combat_context)
	QDEL_NULL(interaction)
	QDEL_NULL(map_view)
	QDEL_NULL(remote_session)
	QDEL_NULL(intrusion)
	QDEL_NULL(access_session)
	QDEL_NULL(connection)
	QDEL_NULL(inventory)
	operator = null
	host = null
	return ..()

/datum/netrun_console/proc/on_session_changed(datum/source)
	SIGNAL_HANDLER
	if(source == inventory)
		map_view?.invalidate_inventory()
		invalidate_projection_caches()
	invalidate_ui()

/// Internal organs live in nullspace; their wearer supplies the client's physical position.
/datum/netrun_console/proc/physical_host()
	return host?.netrun_physical_host()

/datum/netrun_console/proc/physical_turf()
	return get_turf(physical_host())

/// Never serialize UI or rebuild topology inside a synchronous signal handler.
/datum/netrun_console/proc/invalidate_ui(immediate = TRUE)
	if(QDELETED(src))
		return
	ui_dirty = TRUE
	// A batch can contain hundreds of changed nodes, and several observers may
	// invalidate the same console. One pending wake already owns that work.
	if(immediate && ui_event_pending && SSnetrun.active_consoles[src])
		var/datum/netrun_execution_limits/limits = SSnetrun.get_execution_limits()
		if(ui_processing || ui_flushing || world.time < ui_rendered_at + limits.ui_refresh_interval || SSnetrun.task_scheduler?.by_key["console:[REF(src)]"])
			return
	ui_event_pending ||= immediate
	activate()
	if(immediate && !ui_processing && is_ui_active())
		SSnetrun.get_task_scheduler().enqueue("console", src, NETRUN_TASK_NORMAL)

/datum/netrun_console/proc/activate()
	if(QDELETED(src))
		return
	if(!SSnetrun.active_consoles[src])
		// Time asleep must not become trace, damage or healing on the first active tick.
		last_netrun_tick = world.time
	SSnetrun.active_consoles[src] = TRUE

/datum/netrun_console/proc/note_ui_activity(defer_context_refresh = FALSE)
	var/new_observation = !ui_observing
	last_ui_at = world.time
	observe_ui_state(defer_context_refresh)
	activate()
	if(new_observation)
		SSnetrun.collect_console_node_interest(src)

/datum/netrun_console/proc/needs_processing()
	if(is_ui_active() || intrusion.breach || intrusion.trace > 0 || is_locked() || connection.jack || remote_session.watch_node)
		return TRUE
	if(istype(host, /mob/camera/netrun_entity))
		var/mob/camera/netrun_entity/entity = host
		return entity.needs_processing()
	return FALSE

/// Autonomous clients (circuits, bots) never impersonate player input: their packets stay
/// out of the interactive lane and do not renew UI activity leases.
/datum/netrun_console/proc/autonomous()
	return origin == NETRUN_ORIGIN_CIRCUIT

/// Only an autonomous resident without a controlling player supplies puzzle input.
/// Other autonomous clients may opt in without changing the breach implementation.
/datum/netrun_console/proc/automates_breach_input()
	var/mob/camera/netrun_entity/entity = host
	return autonomous() && istype(entity) && !entity.client

/datum/netrun_console/proc/is_ui_active()
	var/datum/netrun_execution_limits/limits = SSnetrun.get_execution_limits()
	if(world.time <= last_ui_at + limits.ui_activity_lease)
		return TRUE
	var/datum/source = QDELETED(netrun_ui_source) ? src : netrun_ui_source
	return !!length(SStgui.get_all_open_uis(source))

/datum/netrun_console/proc/flush_ui(immediate = FALSE)
	if(!ui_dirty || ui_serializing || ui_flushing)
		return
	var/datum/netrun_execution_limits/limits = SSnetrun.get_execution_limits()
	if((!immediate || !limits.interactive_flush) && world.time < last_ui_at + limits.ui_refresh_interval)
		return
	if(!is_ui_active())
		return
	ui_flushing = TRUE
	ui_dirty = FALSE
	ui_event_pending = FALSE
	push_ui_update()
	ui_flushing = FALSE

/datum/netrun_console/proc/push_ui_update()
	var/datum/source = QDELETED(netrun_ui_source) ? src : netrun_ui_source
	SStgui.update_uis(source)

/datum/netrun_console/ui_host(mob/user)
	return host || src

// MARK: Маршрутизация

/// Сети, в которых консоль находится физически
/datum/netrun_console/proc/home_networks()
	return connection.home_networks()

/datum/netrun_connection/proc/home_networks()
	. = list()
	if(jack?.network && owner.jack_valid())
		. += jack.network
	if(!wireless)
		var/datum/component/netrun_node/source = owner.route_source()
		if(source?.network)
			. |= source.network

/// Permission checks need a boolean, not a disposable home_networks() list.
/datum/netrun_console/proc/is_home_network(datum/netrun_network/network, datum/netrun_path_tree/tree)
	return connection.is_home_network(network, tree)

/datum/netrun_connection/proc/is_home_network(datum/netrun_network/network, datum/netrun_path_tree/tree)
	if(jack?.network == network && owner.jack_valid())
		return TRUE
	if(!wireless)
		var/datum/component/netrun_node/source = tree ? tree.source : route_source()
		return source?.network == network
	return FALSE

/// Есть ли выход в NTnet
/datum/netrun_console/proc/has_uplink()
	return connection.has_uplink()

/datum/netrun_connection/proc/has_uplink()
	if(SSnetworks.station_network.setting_disabled)
		return FALSE
	var/datum/netrun_path_tree/tree = read_path_tree()
	var/datum/netrun_topology/graph = SSnetrun.topology
	if(!graph || graph.dirty)
		graph = SSnetrun.ensure_topology()
	. = FALSE
	for(var/address in graph.relay_addresses)
		if(!tree.reached[address])
			continue
		var/datum/component/netrun_node/node = graph.nodes[address]
		if(!istype(node?.parent, /obj/machinery/ntnet_relay) || !node.is_online())
			continue
		// This relay's netrun_online() already validated native operation.
		. = TRUE
		break
	owner.release_path_tree(tree)

/datum/netrun_console/proc/can_reach(datum/netrun_network/network, datum/netrun_path_tree/tree)
	return connection.can_reach(network, tree)

/datum/netrun_connection/proc/can_reach(datum/netrun_network/network, datum/netrun_path_tree/tree)
	if(!network)
		return FALSE
	var/owns_tree = !tree
	if(owns_tree)
		tree = read_path_tree()
	. = FALSE
	if(!tree.graph_ref)
		// Restricted wireless trees contain only loopback; no station solve is needed.
		. = tree.source?.network == network && !!tree.reached[tree.source?.address]
	else if(owner.ui_serializing && tree == owner.ui_routes && tree.network_index_ready)
		. = !!tree.reached_networks[network.id]
	else
		var/datum/netrun_topology/graph = SSnetrun.topology
		if(!graph || graph.dirty)
			graph = SSnetrun.ensure_topology()
		. = tree.network_available(graph, network)
		if(!. && tree.transit_availability_revision != graph.transit_availability_revision)
			// A failed witness may have discovered an unsigned intermediate outage.
			// Rebuild once to consider alternate entrances; the graph owns this borrow.
			var/datum/netrun_path_tree/current = graph.route_snapshot(tree.source, TRUE)
			if(current)
				. = current.network_available(graph, network)
	if(owns_tree)
		owner.release_path_tree(tree)

/datum/netrun_console/proc/is_locked()
	return intrusion.is_locked()

/datum/netrun_intrusion_session/proc/is_locked()
	return world.time < lockout_until

// MARK: Доступ

/datum/netrun_console/proc/user_access(fresh = FALSE)
	return access_session.user_access(fresh)

/datum/netrun_access_session/proc/user_access(fresh = FALSE)
	if(!fresh && owner.access_cache)
		return owner.access_cache
	return netrun_mob_access(owner.operator)

/datum/netrun_console/proc/has_key(datum/netrun_network/network, fresh = FALSE)
	return access_session.has_key(network, fresh)

/// Пароль сервера сообщений — разведданные сессии: добывается взломом, открывает чтение сообщений.
/datum/netrun_console/proc/knows_server_password(address)
	return !isnull(access_session.server_passwords[address])

/datum/netrun_console/proc/learn_server_password(address)
	access_session.server_passwords[address] = TRUE

/datum/netrun_access_session/proc/has_key(datum/netrun_network/network, fresh = FALSE)
	if(!network)
		return FALSE
	if(!fresh && owner.ui_keys && !isnull(owner.ui_keys[network.id]))
		return owner.ui_keys[network.id]
	. = owner.inventory.has_key(network, fresh)
	if(!fresh && owner.ui_keys)
		owner.ui_keys[network.id] = .

/datum/netrun_console/proc/legit_network_level(datum/netrun_network/network, fresh = FALSE)
	return access_session.legit_network_level(network, fresh)

/datum/netrun_access_session/proc/legit_network_level(datum/netrun_network/network, fresh = FALSE)
	if(!network)
		return NETRUN_ACCESS_NONE
	// String IDs cache effective LAN grants; datum keys cache only ID/key access.
	// Sharing this pass-local list also shares all existing permission invalidation.
	if(!fresh && owner.network_level_cache && !isnull(owner.network_level_cache[network]))
		return owner.network_level_cache[network]
	. = (owner.has_key(network, fresh) || network.legit_guest(owner.user_access(fresh))) ? NETRUN_ACCESS_GUEST : NETRUN_ACCESS_NONE
	if(!fresh && owner.network_level_cache)
		owner.network_level_cache[network] = .

/datum/netrun_console/proc/network_level(datum/netrun_network/network, datum/netrun_path_tree/tree)
	return access_session.network_level(network, tree)

/datum/netrun_access_session/proc/network_level(datum/netrun_network/network, datum/netrun_path_tree/tree)
	if(length(pending_firewalls))
		process_events()
	if(!network)
		return NETRUN_ACCESS_NONE
	var/ui_read = !tree || (owner.ui_serializing && tree == owner.ui_routes)
	if(ui_read && owner.network_level_cache && !isnull(owner.network_level_cache[network.id]))
		return owner.network_level_cache[network.id]
	if(!owner.can_reach(network, tree) || owner.is_locked())
		. = NETRUN_ACCESS_NONE
	else
		. = max(acquired_network_level(network), owner.legit_network_level(network, !ui_read))
		if(owner.is_home_network(network, tree))
			. = max(., NETRUN_ACCESS_GUEST)
	if(ui_read && owner.network_level_cache)
		owner.network_level_cache[network.id] = .

/datum/netrun_console/proc/legit_node_level(datum/component/netrun_node/node, datum/netrun_path_tree/tree)
	return access_session.legit_node_level(node, tree)

/datum/netrun_access_session/proc/legit_node_level(datum/component/netrun_node/node, datum/netrun_path_tree/tree)
	var/ui_read = !tree || (owner.ui_serializing && tree == owner.ui_routes)
	if(ui_read && owner.ui_legit_levels && !isnull(owner.ui_legit_levels[node.address]))
		return owner.ui_legit_levels[node.address]
	. = owner.compute_legit_node_level(node, !ui_read)
	if(ui_read && owner.ui_legit_levels)
		owner.ui_legit_levels[node.address] = .

/datum/netrun_console/proc/compute_legit_node_level(datum/component/netrun_node/node, fresh = FALSE)
	return access_session.compute_legit_node_level(node, fresh)

/datum/netrun_access_session/proc/compute_legit_node_level(datum/component/netrun_node/node, fresh = FALSE)
	if(!node.network)
		return NETRUN_ACCESS_NONE
	. = owner.legit_network_level(node.network, fresh) ? NETRUN_ACCESS_GUEST : NETRUN_ACCESS_NONE
	var/atom/target = node.parent
	. = max(., target.netrun_owner_access(owner))
	var/list/access = owner.user_access(fresh)
	if(!length(access))
		return
	var/user_ok
	if(node.required_access)
		user_ok = FALSE
		for(var/needed in node.required_access)
			if(needed in access)
				user_ok = TRUE
				break
	else if(isobj(node.parent))
		var/obj/O = node.parent
		user_ok = O.check_access_list(access)
	if(!user_ok)
		return
	. = max(., NETRUN_ACCESS_USER)
	if((ACCESS_CAPTAIN in access) || (ACCESS_NETWORK in access))
		. = NETRUN_ACCESS_ROOT

/datum/netrun_console/proc/node_level(datum/component/netrun_node/node, datum/netrun_path_tree/tree)
	return access_session.node_level(node, tree)

/datum/netrun_access_session/proc/node_level(datum/component/netrun_node/node, datum/netrun_path_tree/tree)
	if(length(pending_firewalls))
		process_events()
	if(!node?.network || owner.is_locked())
		return NETRUN_ACCESS_NONE
	var/ui_read = !tree || (owner.ui_serializing && tree == owner.ui_routes)
	if(ui_read && owner.ui_node_levels && !isnull(owner.ui_node_levels[node.address]))
		return owner.ui_node_levels[node.address]
	. = owner.compute_node_level(node, tree)
	if(ui_read && owner.ui_node_levels)
		owner.ui_node_levels[node.address] = .

/datum/netrun_console/proc/compute_node_level(datum/component/netrun_node/node, datum/netrun_path_tree/tree)
	return access_session.compute_node_level(node, tree)

/datum/netrun_access_session/proc/compute_node_level(datum/component/netrun_node/node, datum/netrun_path_tree/tree)
	var/owns_tree = !tree && !owner.ui_routes
	if(owns_tree)
		// One synchronous authority read has one physical source and one tree.
		// Reuse them for the LAN, loopback and optional owner-route checks.
		tree = owner.connection.read_path_tree(TRUE)
	var/net_level = owner.network_level(node.network, tree)
	var/atom/target = node.parent
	var/owner_level = target.netrun_owner_access(owner)
	var/acquired_level = acquired_node_level(node)
	var/local_endpoint = node == (tree ? tree.source : owner.route_source())
	if(net_level < NETRUN_ACCESS_GUEST && !local_endpoint && (!(owner_level || acquired_level) || !owner.can_route(node, tree)))
		. = NETRUN_ACCESS_NONE
	else
		. = max(NETRUN_ACCESS_GUEST, owner_level, net_level, acquired_level, owner.legit_node_level(node, tree))
		if(node == owner.connection.jack)
			. = max(., NETRUN_ACCESS_GUEST)
	if(owns_tree)
		owner.release_path_tree(tree)

// MARK: Действия

/datum/netrun_console/proc/selected_node()
	RETURN_TYPE(/datum/component/netrun_node)
	// selected_address is fixed during one ui_data pass, and this is resolved many times per poll
	// (string build + hash lookup each time); resolve it once per serialization pass.
	if(ui_serializing && ui_selected_resolved)
		return ui_selected_node_cache
	. = SSnetrun.find_node(map_view.selected_address)
	if(ui_serializing)
		ui_selected_node_cache = .
		ui_selected_resolved = TRUE

/// Закрытая сеть публикует лишь шлюз и APC. Владелец видит собственное устройство.
/datum/netrun_console/proc/node_visible(datum/component/netrun_node/node)
	return access_session.node_visible(node)

/datum/netrun_access_session/proc/node_visible(datum/component/netrun_node/node)
	if(!node?.network || !owner.can_route(node))
		return FALSE
	return owner.node_level(node) >= NETRUN_ACCESS_GUEST || (node.node_type in list(NETRUN_NODE_APC, NETRUN_NODE_GATEWAY)) || owner.daemon_capability("reveal_nodes")

/datum/netrun_console/proc/run_command(datum/component/netrun_node/node, command_id, input_nonce, packet_id)
	var/datum/netrun_packet_context/operation = new("command", "Команда устройства",
		route_source()?.address, node?.address, command_id, src, input_nonce)
	if(world.time < next_command)
		return reject_operation(operation, "Канал команд ещё занят.")
	next_command = world.time + 0.5 SECONDS
	node = refresh_route_node(node)
	if(!node || !(command_id in node.all_command_ids()))
		return reject_operation(operation, "Узел или команда недоступны.")
	var/datum/netrun_command/command = SSnetrun.get_command(command_id)
	if(!command)
		return reject_operation(operation, "Команда не найдена.")
	if(!command.visible_to(src))
		return reject_operation(operation, "Для команды нужна [command.required_daemon].exe.")
	operation.label = command.display_name(node, netrun_command_arg(command_id))
	packet_id = command_id == "packet_decrypt" && istext(packet_id) ? copytext_char(packet_id, 1, 65) : null
	operation.capture(list("command" = command_id, "packet_id" = packet_id))
	if(is_locked())
		log_line("Точка подключения заблокирована.", "bad")
		return reject_operation(operation, "Точка подключения заблокирована.")
	var/datum/netrun_path_tree/tree = make_path_tree()
	if(!can_route(node, tree))
		qdel(tree)
		log_line("[node.address]: нет маршрута к узлу.", "bad")
		return reject_operation(operation, "Нет маршрута к узлу.")
	if(!command.works_offline && !node.is_online(node != connection.jack))
		qdel(tree)
		log_line("[node.address]: узел не отвечает.", "bad")
		return reject_operation(operation, "Узел не отвечает.")
	var/level = node_level(node, tree)
	if(level < command.access)
		qdel(tree)
		log_line("[node.address]: недостаточно прав для «[command.name]».", "bad")
		return reject_operation(operation, "Недостаточно прав для команды.")
	node.touch()
	// Задержка маршрута: прямое/близкое подключение - почти мгновенно, дальнее через реле - с лагом.
	var/lat = command.ignores_latency ? 0 : latency_to(node, tree)
	var/list/poll_route = tree.addresses_to(node.address)
	qdel(tree)
	if(lat <= 0)
		log_line("> [command_id] @ [node.address]")
		var/datum/netrun_request/command/packet = new(src, node, command, command_id, node.network, operator, inventory.selected_file_uid || "none", operation, packet_id)
		return packet.send(0, poll_route)
	else
		log_line("> [command_id] @ [node.address] (отправка, ~[lat * 100]мс)")
		next_command = world.time + max(0.5 SECONDS, lat)
		var/datum/netrun_request/command/packet = new(src, node, command, command_id, node.network, operator, inventory.selected_file_uid || "none", operation, packet_id)
		return packet.send(lat, poll_route)

/// Собственно выполнение команды - может вызываться с задержкой маршрута
/datum/netrun_console/proc/do_command(datum/component/netrun_node/node, datum/netrun_command/command, command_id, illegal, datum/netrun_network/sent_network, mob/sender, file_uid, datum/netrun_packet_context/operation, packet_id)
	if(QDELETED(src) || QDELETED(node) || !command)
		operation?.finish("cancelled", "Узел или сеанс удалён.")
		return FALSE
	node.join_network()
	if(is_locked())
		operation?.finish("rejected", "Точка подключения заблокирована.")
		return FALSE
	var/datum/netrun_path_tree/tree = make_path_tree()
	var/reachable = can_route(node, tree)
	if(reachable)
		operation?.receive(tree.addresses_to(node.address))
	if(sender != operator || !reachable || node.network != sent_network || !(command_id in node.all_command_ids()) || node_level(node, tree) < command.access)
		qdel(tree)
		log_line("[node.address]: запрос отменён — маршрут, оператор или права изменились.", "bad")
		operation?.finish("rejected", "Маршрут, оператор или права изменились.")
		return FALSE
	if(!command.works_offline && !node.is_online(node != connection.jack))
		qdel(tree)
		log_line("[node.address]: узел не отвечает.", "bad")
		operation?.finish("rejected", "Узел не отвечает.")
		return FALSE
	if(!command.visible_to(src))
		qdel(tree)
		operation?.finish("rejected", "Необходимая программа больше не подключена.")
		return FALSE
	illegal = legit_node_level(node, tree) < command.access
	qdel(tree)
	var/datum/netrun_request/request = new(file_uid)
	var/result = world.PushUsr(operator, CALLBACK(command, TYPE_PROC_REF(/datum/netrun_command, execute), node, src, packet_id || netrun_command_arg(command_id), request))
	operation?.set_result(result)
	qdel(request)
	if(QDELETED(src) || QDELETED(node))
		return !isnull(result)
	if(command.read_only)
		node.queue_presentation(NETRUN_CHANGED_DETAILS)
	else
		node.notify_changed()
	if(isnull(result))
		operation?.finish("rejected", "Команда не принята устройством. Подробности в терминале.")
		return FALSE
	log_line(result, illegal ? "average" : "good")
	node.add_log("[log_source()]: [command.name][illegal ? " (без авторизации)" : ""].")
	SSnetrun.post_event(illegal ? "intrusion" : "command", node.network?.id, node.address)
	var/atom/target = node.parent
	log_game("NETRUN: [key_name(operator)] ([origin]) [command.id] -> [node.get_name()] [node.address][illegal ? " (взлом)" : ""] [AREACOORD(target)]")
	node.network?.add_log("[log_source()] -> [node.address]: [command.name][illegal ? " (без авторизации)" : ""]", illegal && command.access >= NETRUN_ACCESS_ROOT)
	if(illegal)
		report_illegal_activity(node, command.name, command.access)
		add_trace(command.trace * node.get_security())
	return TRUE

/// Есть ли вообще маршрут к узлу (иначе узел отрезан - подключиться нельзя)
/datum/netrun_console/proc/can_route(datum/component/netrun_node/node, datum/netrun_path_tree/tree)
	return connection.can_route(node, tree)

/datum/netrun_connection/proc/can_route(datum/component/netrun_node/node, datum/netrun_path_tree/tree)
	node = owner.refresh_route_node(node)
	if(!node)
		return FALSE
	var/owns_tree = !tree
	if(owns_tree)
		tree = read_path_tree()
	. = !!tree.reached[node.address]
	if(. && (!owner.ui_serializing || tree != owner.ui_routes))
		var/datum/netrun_topology/graph = SSnetrun.topology
		if(!graph || graph.dirty)
			graph = SSnetrun.ensure_topology()
		. = tree.path_available(graph, node.address)
	if(owns_tree)
		owner.release_path_tree(tree)

/// Ответ ping приходит после round-trip
/datum/netrun_console/proc/ping_reply(address, lat, route_name)
	var/datum/component/netrun_node/node = SSnetrun.find_node(address)
	if(!node || !can_route(node))
		log_line("ping [address]: ответа нет (узел отрезан).", "bad")
		return
	log_line("[address]: [lat * 2 * 100]мс туда-обратно ([route_name]).", "good")

/// Задержка маршрута до узла в децисекундах: 0 - прямое/рядом, больше - дальше и через реле
/datum/netrun_console/proc/latency_to(datum/component/netrun_node/node, datum/netrun_path_tree/tree)
	return connection.latency_to(node, tree)

/datum/netrun_connection/proc/latency_to(datum/component/netrun_node/node, datum/netrun_path_tree/tree)
	if(!tree && owner.ui_latency && node && !isnull(owner.ui_latency[node.address]))
		return owner.ui_latency[node.address]
	var/datum/netrun_route/route = owner.route_to(node, tree)
	. = route.latency
	qdel(route)
	if(!tree && owner.ui_latency && node)
		owner.ui_latency[node.address] = .

/datum/netrun_console/proc/log_source()
	if(operator && !connection.wireless)
		return "[operator.real_name || operator.name] ([get_area_name(host, TRUE)])"
	return "узел [origin] [REF(src)]"

/datum/netrun_console/proc/add_trace(amount)
	if(amount > 0)
		activate()
	return intrusion.add_trace(amount)

/datum/netrun_intrusion_session/proc/add_trace(amount)
	if(amount <= 0)
		return
	last_illegal = world.time
	trace = min(NETRUN_TRACE_MAX, trace + amount * owner.effective_trace_mult())
	if(trace >= NETRUN_TRACE_MAX)
		owner.traced()

/datum/netrun_console/proc/traced()
	return intrusion.traced()

/datum/netrun_intrusion_session/proc/traced()
	trace = 0
	QDEL_NULL(breach)
	owner.map_view.invalidate()
	var/datum/resident = owner.netrun_actor()
	var/datum/component/netrun_node/resident_node = resident?.netrun_actor_node()
	var/where = get_area_name(resident_node?.parent || owner.host, TRUE) || "неизвестно"
	SSnetrun.post_event("trace", null, owner.map_view.selected_address)
	SSnetrun.ntnet_log("Нарушитель отслежен: точка [owner.origin], район: [where].", TRUE)
	for(var/network_id in SSnetrun.networks)
		var/datum/netrun_network/network = SSnetrun.networks[network_id]
		if(!network.isolated)
			network.add_log("Трассировка завершена: нарушитель в районе [where].")
	var/mob/camera/netrun_entity/entity = owner.combat_self()
	SSnetrun.report_incident("trace", istype(entity) ? entity.host_node : owner.route_source(), istype(entity) ? entity : owner, NETRUN_INCIDENT_HIGH, "Нарушитель отслежен: точка [owner.origin], район: [where].")
	if(istype(entity) || istype(resident, /datum/netrun_ice))
		// Сущность живёт в сети: её не выбрасывает, но защита поднимается и идёт к её узлу.
		owner.log_line("ВАС ОБНАРУЖИЛИ! Заметайте следы, иначе процессы защиты доберутся до вас.", "bad")
		SSnetrun.alert_defenses(resident_node, owner)
	else
		// Удалённая точка подключения: трассировка рвёт соединение и блокирует точку.
		lockout_until = world.time + NETRUN_TRACE_LOCKOUT
		owner.access_session.node_access.Cut()
		owner.access_session.network_access.Cut()
		owner.stop_watch()
		owner.remote_session.windows.Cut()
		owner.remote_session.active_window = null
		owner.log_line("ВАС ОТСЛЕДИЛИ. Соединение разорвано.", "bad")
		var/datum/component/netrun_node/near = owner.route_source()
		if(near)
			SSnetrun.dispatch_hunter(near)
	owner.host?.netrun_traced(owner)

/// Does the open UI currently show something that advances with world.time but emits no change
/// signal of its own? Those are the only states that still need a once-per-second repaint; every
/// other change already pushes itself through a domain signal, so a quiet UI can stop serializing.
/datum/netrun_console/proc/needs_live_refresh()
	if(intrusion.breach || intrusion.trace > 0 || is_locked())
		return TRUE
	if(world.time < next_command)
		return TRUE
	if(remote_session.watch_node)
		return TRUE
	if(combat_context.needs_live_refresh())
		return TRUE
	var/datum/component/netrun_node/displayed = workspace_view == "pinned" ? SSnetrun.find_node(remote_session.active_window) : ((workspace_view in list("map", "files")) ? selected_node() : null)
	if(displayed?.fortress?.needs_live_refresh())
		return TRUE
	// Web pages (NTnet) and pinned machine windows carry external/async content that arrives with
	// no netrun change signal, so those tabs keep polling; the map and terminal stay event-driven.
	if(workspace_view == "web" || (workspace_view == "pinned" && remote_session.active_window))
		return TRUE
	if(workspace_view != "map")
		return FALSE
	if(map_view.has_ping())
		return TRUE
	// Only visible event effects need fading frames. Traffic in an unrelated
	// sector must not keep every station map serializing once per second.
	return world.time < map_view.event_refresh_until

/datum/netrun_console/proc/process_tick(delta)
	map_view.expire_ping()
	if(map_view.has_ping())
		SSnetrun.retain_route_interest(map_view.ping_route, map_view.ping_until)
	if(!is_ui_active())
		stop_ui_observation()
	else
		reconcile_ui_context()
	intrusion.process_tick(delta)
	if(connection.jack && !jack_valid())
		log_line("Провод выдернут.", "average")
		set_jack(null)
	remote_session.process_tick()
	if(workspace_view != "map" || !is_ui_active())
		map_view.suspend()
	// Event-driven changes already wake the console (domain signals -> invalidate_ui/activate).
	// Only a live, event-less countdown on screen needs a periodic repaint; a quiet open UI rests
	// instead of re-serializing identical data once per second. The one-second tail guarantees the
	// countdown's closing frame is drawn once it stops being "live".
	if(needs_live_refresh())
		var/datum/netrun_execution_limits/limits = SSnetrun.get_execution_limits()
		live_refresh_until = world.time + limits.ui_refresh_interval
	if(world.time <= live_refresh_until)
		invalidate_ui(FALSE)

/datum/netrun_intrusion_session/proc/process_tick(delta)
	if(breach)
		// Wakes may occur twice in one tick; charge only time spent in this breach.
		delta = min(delta, max(0, world.time - last_breach_tick) / (1 SECONDS))
		last_breach_tick = world.time
		if(!breach.valid_target())
			owner.log_line("Взлом отменён: цель недоступна или переменила сеть.", "bad")
			QDEL_NULL(breach)
			owner.invalidate_ui()
		else if(breach.time_left() <= 0)
			breach.finish()
		else
			owner.add_trace(0.6 * breach.security * delta * (breach.target_kind == "network" ? 1.25 : 1))
			breach?.advance_automation()
	else if(trace > 0 && world.time - last_illegal > 10 SECONDS)
		var/datum/netrun_daemon_context/context = new
		context.trace_decay = NETRUN_TRACE_DECAY * delta
		owner.apply_daemon_effects(context)
		trace = max(0, trace - context.trace_decay)
		qdel(context)

/datum/netrun_remote_session/proc/process_tick()
	if(!watch_node)
		return
	var/atom/target = owner.watch_target()
	if(!target || !watch_eye || watch_viewer?.client?.eye != watch_eye)
		stop_watch()
		return
	var/turf/target_turf = get_turf(target)
	if(!target_turf)
		stop_watch()
		return
	if(watch_eye.loc != target_turf)
		watch_eye.forceMove(target_turf)
	if(isliving(watch_viewer))
		watch_eye.update_remote_sight(watch_viewer)

/datum/netrun_console/proc/start_breach(kind, id, automatic = FALSE)
	activate()
	return intrusion.start_breach(kind, id, automatic)

/datum/netrun_intrusion_session/proc/start_breach(kind, id, automatic = FALSE)
	if(!can_breach || breach || owner.is_locked())
		return FALSE
	if(automatic && (kind == "firmware" || !owner.daemon_capability("autobreach")))
		return FALSE
	var/security
	var/target_name
	if(kind == "network")
		var/datum/netrun_network/network = SSnetrun.networks[id]
		if(!network || !owner.can_reach(network))
			return FALSE
		security = network.breach_security()
		target_name = "шлюз [network.short_name]"
	else
		var/datum/component/netrun_node/node = SSnetrun.find_node(id)
		if(!node || owner.node_level(node) < NETRUN_ACCESS_GUEST || !node.is_online(node != owner.connection.jack) || !owner.can_route(node))
			return FALSE
		// Standing fortress walls must be breached in combat before the node itself can be cracked.
		if(node.fortress?.blocks_breach(owner))
			owner.log_line("[node.address]: стены крепости [node.fortress.name] отражают взлом. Сначала разрушьте стены боевыми программами.", "bad")
			return FALSE
		security = node.get_security() - (node == owner.connection.jack ? 1 : 0)
		target_name = "[node.get_name()] [node.address]"
		if(kind == "firmware")
			var/datum/netrun_provider/api = SSnetrun.get_provider(node.parent)
			if(!api?.allow_emag || owner.node_level(node) < NETRUN_ACCESS_ROOT || !owner.daemon_capability("firmware"))
				return FALSE
			security = 5
			target_name = "прошивка [target_name]"
		node.touch()
	if((kind in list("node", "network")) && !owner.canonical_acquired_key(TRUE))
		owner.log_line("Взлом не начат: для файла добытых прав нужна одна свободная ячейка в памяти или подключённом шарде.", "bad")
		return FALSE
	if(automatic)
		breach = new /datum/netrun_breach/automatic(owner, kind, id, target_name, security)
	else if(owner.automates_breach_input())
		breach = new /datum/netrun_breach/npc(owner, kind, id, target_name, security)
	else
		breach = new /datum/netrun_breach(owner, kind, id, target_name, security)
	last_breach_tick = world.time
	SSnetrun.currentbreaches |= owner
	if(kind != "network")
		var/datum/component/netrun_node/target = SSnetrun.find_node(id)
		breach.target_network = target.network
	if(kind == "firmware")
		breach.security = 5
		breach.size = 7
		breach.deadline = world.time + 20 SECONDS
		breach.buffer_size = min(breach.buffer_size, 7)
		breach.generate()
	SSnetrun.post_event("breach", kind == "network" ? id : null, kind == "network" ? null : id)
	var/datum/component/netrun_node/incident_node = SSnetrun.find_node(id)
	if(kind == "network")
		var/datum/netrun_network/defended = SSnetrun.networks[id]
		for(var/datum/component/netrun_node/candidate as anything in defended.nodes)
			if(candidate.node_type == NETRUN_NODE_APC || !incident_node)
				incident_node = candidate
			if(candidate.node_type == NETRUN_NODE_APC)
				break
	SSnetrun.report_incident("breach", incident_node, owner, kind == "network" ? NETRUN_INCIDENT_MEDIUM : NETRUN_INCIDENT_LOW, "Взлом: [target_name].")
	// Взлом защищённой цели поднимает сторожевой ICE.
	if(kind != "network")
		SSnetrun.raise_defenses(owner, SSnetrun.find_node(id))
	owner.note_user_action()
	if(kind == "network")
		var/datum/netrun_network/target_network = SSnetrun.networks[id]
		for(var/datum/component/netrun_node/target as anything in target_network.nodes)
			target.wake_defenses()
	else
		var/datum/component/netrun_node/target = SSnetrun.find_node(id)
		target?.wake_defenses()
	owner.log_line("Запущен взлом: [target_name].", "average")
	owner.workspace_view = "breach"
	return TRUE

/datum/netrun_console/proc/breach_finished(datum/netrun_breach/finished)
	return intrusion.breach_finished(finished)

/datum/netrun_intrusion_session/proc/breach_finished(datum/netrun_breach/finished)
	if(finished != breach)
		return
	if(!finished.valid_target())
		breach = null
		owner.log_line("Взлом отменён: соединение с целью потеряно.", "bad")
		qdel(finished)
		return
	var/reward = NETRUN_ACCESS_NONE
	var/clean = FALSE
	for(var/list/daemon as anything in finished.daemons)
		if(!daemon["done"])
			continue
		if(daemon["reward"])
			reward = max(reward, daemon["reward"])
		else
			clean = TRUE
	breach = null
	if(finished.target_kind == "firmware")
		var/datum/component/netrun_node/node = SSnetrun.find_node(finished.target_id)
		if(reward >= NETRUN_ACCESS_ROOT && node && owner.can_route(node) && node.is_online(node != owner.connection.jack) && owner.node_level(node) >= NETRUN_ACCESS_ROOT && owner.daemon_capability("firmware"))
			owner.apply_firmware_bypass(node)
		else
			owner.log_line("Взлом прошивки не завершён или соединение потеряно.", "bad")
			owner.add_trace(25)
		qdel(finished)
		return
	if(finished.target_kind == "network")
		reward = min(reward, NETRUN_ACCESS_GUEST)
	if(!reward && !clean)
		owner.log_line("Взлом провален.", "bad")
		owner.add_trace(25)
	else
		var/stored = !reward || owner.record_breach_grant(finished.target_kind, finished.target_id, reward)
		if(finished.target_kind == "network")
			owner.map_view.invalidate_network_access(finished.target_id)
		else
			owner.map_view.invalidate_node_access(finished.target_id)
		if(stored)
			owner.log_line("Взлом завершён: [finished.target_name], уровень [netrun_access_name(reward)] записан в файл добытых прав.", "good")
		else
			owner.log_line("Взлом завершён, но доступ НЕ получен: файл прав вынесен или удалён, а свободной ячейки для нового ключа нет. Освободите память и повторите взлом.", "bad")
		if(clean)
			trace = 0
			owner.disengage_combat()
			owner.log_line("Следы заметены: трассировка сброшена, бой разорван.", "good")
	qdel(finished)

// MARK: Файлы

/datum/netrun_console/proc/all_files(fresh = FALSE)
	return inventory.all_files(fresh)

/datum/netrun_console/proc/store_file(datum/netrun_file/file, to_shard = FALSE)
	return inventory.store_file(file, to_shard)

/datum/netrun_console/proc/find_local_file(uid)
	return inventory.find_file(uid)

/datum/netrun_console/proc/delete_local_file(datum/netrun_file/file)
	if(!inventory.delete_file(file))
		log_line("Удаление отклонено: файл недоступен или носитель доступен только для чтения.", "bad")
		return FALSE
	return TRUE

/// Бонус от установленных демонов (каждый тип считается один раз)
/datum/netrun_console/proc/daemon_bonus(id)
	if(ui_bonuses && !isnull(ui_bonuses[id]))
		return ui_bonuses[id]
	. = inventory.daemon_bonus(id)
	if(ui_bonuses)
		ui_bonuses[id] = .

/// Modifiers execute against the current mounted files, never a presentation cache.
/datum/netrun_console/proc/apply_daemon_effects(datum/netrun_daemon_context/context)
	return inventory.apply_daemon_effects(context)

/datum/netrun_console/proc/daemon_capability(capability)
	var/datum/netrun_daemon_context/context = new
	context.capability = capability
	apply_daemon_effects(context)
	. = context.capability_granted
	qdel(context)

/datum/netrun_console/proc/effective_trace_mult()
	return intrusion.effective_trace_mult()

/datum/netrun_intrusion_session/proc/effective_trace_mult()
	var/datum/netrun_daemon_context/context = new
	context.trace_factor = trace_mult
	owner.apply_daemon_effects(context)
	. = context.trace_factor
	qdel(context)

// MARK: Провод

/datum/netrun_console/proc/set_jack(datum/component/netrun_node/node)
	connection.set_jack(node)
	map_view.invalidate()
	if(connection.jack)
		map_view.viewed_network_id = node.network?.id
		map_view.selected_address = node.address
	invalidate_ui()

/datum/netrun_console/proc/on_jack_deleted(datum/source)
	SIGNAL_HANDLER
	set_jack(null)

/datum/netrun_console/proc/jack_valid()
	return connection.jack_valid()

// MARK: Журнал

/datum/netrun_console/proc/log_line(text, kind = "label", notice_topic)
	log += list(list("time" = STATION_TIME_TIMESTAMP("hh:mm:ss", world.time), "text" = text, "kind" = kind))
	host?.netrun_console_event(src, text, kind)
	SEND_SIGNAL(src, COMSIG_NETRUN_CONSOLE_EVENT, text, kind)
	if(length(log) > NETRUN_MAX_CONSOLE_LOG)
		log.Cut(1, length(log) - NETRUN_MAX_CONSOLE_LOG + 1)
	if(kind in list("good", "bad", "average"))
		push_notice(text, kind, FALSE, notice_topic)
	// A new log line is an event-less UI change (it can arrive from async delivery, ICE, timers);
	// wake the console so it flushes instead of relying on a blanket per-second repaint.
	invalidate_ui()

/datum/netrun_console/proc/combat_log(text, kind = "label")
	return log_line(text, kind, "combat")

/datum/netrun_console/proc/push_notice(text, kind = "label", immediate = TRUE, topic)
	if(autonomous() || !istext(text) || !length(text))
		return
	var/clean = copytext_char(strip_html_tags(text, TRUE), 1, 321)
	if(clean == last_notice_text && kind == last_notice_kind && topic == last_notice_topic && world.time - last_notice_at < 1 SECONDS)
		return
	last_notice_text = clean
	last_notice_kind = kind
	last_notice_topic = topic
	last_notice_at = world.time
	notices += list(list("id" = ++notice_serial, "text" = clean, "kind" = kind, "topic" = topic))
	if(length(notices) > 8)
		notices.Cut(1, length(notices) - 7)
	if(immediate)
		invalidate_ui()

/proc/netrun_access_name(level)
	switch(level)
		if(NETRUN_ACCESS_GUEST)
			return "ГОСТЬ"
		if(NETRUN_ACCESS_USER)
			return "ПОЛЬЗОВАТЕЛЬ"
		if(NETRUN_ACCESS_ROOT)
			return "ROOT"
	return "НЕТ"
