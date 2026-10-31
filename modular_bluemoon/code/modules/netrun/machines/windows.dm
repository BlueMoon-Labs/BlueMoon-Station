// MARK: Вкладки и окна машин
//
// Любой узел можно открыть «окном» во вкладке терминала: его состояние, команды и особые
// действия (у некоторых машин - свои механики, часть под взломом). Камеру можно смотреть
// по подключению. Команды окна - это те же сетевые запросы к машине, что и в панели узла,
// плюс оконные действия, которые машина объявляет через хуки ниже.

#define NETRUN_MAX_WINDOWS 5

// MARK: Хуки машин

/// Дополнительные поля окна (строки состояния сверх netrun_status). По умолчанию - статус.
/atom/proc/netrun_window_fields(datum/netrun_console/console, datum/component/netrun_node/node)
	return netrun_status()

/// Особые оконные действия машины: list(list("id","name","icon","access","danger","desc"))
/atom/proc/netrun_window_actions(datum/netrun_console/console, datum/component/netrun_node/node)
	if(!netrun_view_capable())
		return list()
	return list(
		list("id" = "view_watch", "name" = "Смотреть", "icon" = "eye", "access" = NETRUN_ACCESS_USER, "desc" = "Подключиться к видеопотоку устройства."),
		list("id" = "view_unwatch", "name" = "Отключить обзор", "icon" = "eye-slash", "access" = NETRUN_ACCESS_GUEST, "desc" = "Вернуть собственный обзор."),
	)

/// «Живой кадр» для окон-камер: список строк, что видно; null - не камера/нет доступа
/atom/proc/netrun_window_feed(datum/netrun_console/console, datum/component/netrun_node/node)
	if(!netrun_view_capable() || console.node_level(node) < NETRUN_ACCESS_USER)
		return null
	if(console.view_denial(node))
		console.remote_session.feed_node = null
		return null
	var/atom/eye = node.is_online() && console.can_route(node) ? netrun_view_target() : null
	if(!eye)
		console.remote_session.feed_node = null
		return list("Нет видеосигнала: проверьте питание, состояние оптики и прошивку.")
	var/turf/eye_turf = get_turf(eye)
	if(!eye_turf)
		console.remote_session.feed_node = null
		return list("Нет видеосигнала: проверьте питание, состояние оптики и прошивку.")
	var/datum/netrun_remote_session/session = console.remote_session
	// The text summary can lag by one second; the native camera view stays live.
	// Permission, route and sensor readiness are still checked above on every poll.
	if(session.feed_node == node && session.feed_eye == eye && session.feed_turf == eye_turf && session.feed_operator == console.operator && world.time < session.feed_updated_at + 1 SECONDS && session.feed_data)
		SSnetrun.camera_feed_cache_hits++
		return session.feed_data.Copy()
	SSnetrun.camera_feed_scans++
	var/feed_started = SSnetrun.profile_armed ? TICK_USAGE : 0
	var/list/seen = list()
	for(var/mob/living/person in view(7, eye))
		if(person == eye)
			continue
		seen += "[person.name] — [person.stat == DEAD ? "не двигается" : "движется"]"
	if(!length(seen))
		seen += "В поле зрения пусто."
	if(SSnetrun.profile_armed)
		var/feed_ms = max(0, TICK_DELTA_TO_MS(TICK_USAGE - feed_started))
		SSnetrun.camera_feed_scan_ms += feed_ms
		SSnetrun.camera_feed_scan_max_ms = max(SSnetrun.camera_feed_scan_max_ms, feed_ms)
	session.feed_node = node
	session.feed_eye = eye
	session.feed_turf = eye_turf
	session.feed_operator = console.operator
	session.feed_updated_at = world.time
	session.feed_data = seen
	return seen

/// Обработать оконное действие машины. Возврат - текст результата или null
/atom/proc/netrun_window_act(datum/netrun_console/console, datum/component/netrun_node/node, action, list/params)
	if(!netrun_view_capable())
		return
	switch(action)
		if("view_watch")
			return console.start_watch(node) ? "Видеопоток подключён." : "Видеопоток недоступен."
		if("view_unwatch")
			console.stop_watch()
			return "Обзор возвращён."

// MARK: Консоль: окна

/datum/netrun_console/proc/open_window(address)
	return remote_session.open_window(address)

/datum/netrun_remote_session/proc/open_window(address)
	var/datum/component/netrun_node/node = SSnetrun.find_node(address)
	if(!node || !owner.node_visible(node))
		return FALSE
	if(!(address in windows))
		if(length(windows) >= NETRUN_MAX_WINDOWS)
			windows.Cut(1, 2)
		windows += address
	active_window = address
	owner.workspace_view = "pinned"
	owner.map_view.selected_address = address
	owner.map_view.selected_network = null
	return TRUE

/datum/netrun_console/proc/close_window(address)
	return remote_session.close_window(address)

/datum/netrun_remote_session/proc/close_window(address)
	windows -= address
	if(watch_node?.address == address)
		owner.stop_watch()
	if(active_window == address)
		active_window = length(windows) ? windows[length(windows)] : null
		owner.map_view.selected_address = active_window
		owner.map_view.selected_network = null

/datum/netrun_console/proc/window_payload()
	return remote_session.window_payload()

/datum/netrun_remote_session/proc/window_payload()
	var/datum/component/netrun_node/node = SSnetrun.find_node(active_window)
	if(!node)
		active_window = null
		return null
	var/level = owner.node_level(node)
	var/atom/A = node.parent
	var/route_ok = owner.can_route(node)
	var/online = node.is_online()
	var/unlocked = !owner.is_locked()
	var/list/extra = list()
	for(var/list/entry as anything in A.netrun_window_actions(owner, node))
		entry["allowed"] = level >= (entry["access"] || NETRUN_ACCESS_GUEST) && route_ok && online && unlocked
		if(entry["id"] == "view_watch" && owner.view_denial(node))
			entry["allowed"] = FALSE
		extra += list(entry)
	var/datum/netrun_network/network = node.network
	return list(
		"address" = node.address,
		"title" = node.get_name(),
		"type" = node.node_type,
		"online" = online,
		"access" = level,
		"legit" = owner.legit_node_level(node),
		"security" = node.get_security(),
		"can_breach" = owner.intrusion.can_breach && level >= NETRUN_ACCESS_GUEST && level < NETRUN_ACCESS_ROOT && route_ok,
		"network" = network ? list("id" = network.id, "name" = network.name, "code" = network.code, "access" = owner.network_level(network), "can_breach" = owner.intrusion.can_breach && owner.can_reach(network) && owner.network_level(network) < NETRUN_ACCESS_GUEST) : null,
		"fields" = level >= NETRUN_ACCESS_USER ? A.netrun_window_fields(owner, node) : list(),
		"commands" = node.command_entries(owner),
		"logs" = level >= NETRUN_ACCESS_USER ? node.logs.Copy() : list(),
		"remote" = owner.remote_payload(node),
		"extra" = extra,
		"feed" = level >= NETRUN_ACCESS_USER ? A.netrun_window_feed(owner, node) : null,
		"watching" = watch_node == node,
	)

/datum/netrun_console/proc/windows_payload()
	return remote_session.windows_payload()

/datum/netrun_remote_session/proc/windows_payload()
	. = list()
	for(var/address in windows.Copy())
		var/datum/component/netrun_node/node = SSnetrun.find_node(address)
		if(!node)
			windows -= address
			if(active_window == address)
				active_window = null
			continue
		. += list(list("address" = address, "title" = node.get_name(), "type" = node.node_type, "online" = node.is_online()))

/datum/netrun_console/proc/window_act(address, action, list/params, input_nonce)
	return remote_session.window_act(address, action, params, input_nonce)

/datum/netrun_remote_session/proc/window_act(address, action, list/params, input_nonce)
	var/datum/component/netrun_node/node = owner.refresh_route_node(SSnetrun.find_node(address))
	if(node && (action in node.all_command_ids()))
		return owner.run_command(node, action, input_nonce)
	var/datum/netrun_packet_context/operation = new("window", "Действие устройства",
		owner.route_source()?.address, node?.address, action, owner, input_nonce)
	if(!node)
		return owner.reject_operation(operation, "Узел недоступен.")
	var/datum/netrun_path_tree/tree = owner.make_path_tree()
	if(owner.node_level(node, tree) < NETRUN_ACCESS_GUEST || !owner.can_route(node, tree) || owner.is_locked())
		qdel(tree)
		return owner.reject_operation(operation, "Нет связи или доступа к окну устройства.")
	// Оконное действие машины
	if(world.time < owner.next_command || !node.is_online())
		qdel(tree)
		return owner.reject_operation(operation, "Канал занят или устройство не отвечает.")
	var/list/entry = owner.window_action(node, action)
	if(!entry || owner.node_level(node, tree) < (entry["access"] || NETRUN_ACCESS_GUEST))
		qdel(tree)
		owner.log_line("Действие окна не разрешено.", "bad")
		return owner.reject_operation(operation, "Действие окна не разрешено.")
	operation.label = entry["name"]
	var/lat = owner.latency_to(node, tree)
	var/list/poll_route = tree.addresses_to(node.address)
	qdel(tree)
	owner.next_command = world.time + max(0.5 SECONDS, lat)
	owner.log_line("[node.address]: запрос «[entry["name"]]» отправлен, ~[lat * 100] мс.")
	var/datum/netrun_request/window/packet = new(owner, node, action, params, node.network, owner.operator, operation)
	return packet.send(max(1, lat), poll_route)

/datum/netrun_console/proc/window_action(datum/component/netrun_node/node, action)
	return remote_session.window_action(node, action)

/datum/netrun_remote_session/proc/window_action(datum/component/netrun_node/node, action)
	var/atom/A = node.parent
	for(var/list/entry as anything in A.netrun_window_actions(owner, node))
		if(entry["id"] == action)
			return entry

/datum/netrun_console/proc/do_window_act(datum/component/netrun_node/node, action, list/params, datum/netrun_network/sent_network, mob/sender, datum/netrun_packet_context/operation)
	return remote_session.do_window_act(node, action, params, sent_network, sender, operation)

/datum/netrun_remote_session/proc/do_window_act(datum/component/netrun_node/node, action, list/params, datum/netrun_network/sent_network, mob/sender, datum/netrun_packet_context/operation)
	if(!QDELETED(node))
		node.join_network()
	var/datum/netrun_path_tree/tree = owner.make_path_tree()
	var/reachable = !QDELETED(node) && owner.can_route(node, tree)
	if(reachable)
		operation?.receive(tree.addresses_to(node.address))
	if(QDELETED(node) || owner.is_locked() || !reachable || !node.is_online() || node.network != sent_network || sender != owner.operator)
		qdel(tree)
		owner.log_line("Запрос окна отменён: связь изменилась.", "bad")
		operation?.finish("rejected", "Связь или оператор изменились.")
		return FALSE
	var/list/entry = owner.window_action(node, action)
	var/required = entry?["access"] || NETRUN_ACCESS_GUEST
	if(!entry || owner.node_level(node, tree) < required)
		qdel(tree)
		operation?.finish("rejected", "Действие окна недоступно или недостаточно прав.")
		return FALSE
	// The native window action owns its execution context and may yield.
	var/illegal = owner.legit_node_level(node, tree) < required
	qdel(tree)
	var/atom/A = node.parent
	var/result = world.PushUsr(owner.operator, CALLBACK(A, TYPE_PROC_REF(/atom, netrun_window_act), owner, node, action, params))
	operation?.set_result(result)
	if(QDELETED(src) || QDELETED(owner) || QDELETED(node))
		return TRUE
	if(!isnull(result))
		owner.log_line(result)
	node.add_log("[owner.log_source()]: [entry["name"]][illegal ? " (без авторизации)" : ""].")
	node.network?.add_log("[owner.log_source()] -> [node.address]: [entry["name"]]", illegal)
	if(illegal)
		var/datum/netrun_console/actor = owner
		var/trace_cost = 4 * node.get_security()
		actor.report_illegal_activity(node, entry["name"], required)
		if(!QDELETED(actor))
			actor.add_trace(trace_cost)
	return TRUE

// MARK: Видеопотоки

/// A client can retain actor-specific optical policy alongside route and node permissions.
/datum/netrun_console/proc/view_denial(datum/component/netrun_node/node)
	var/mob/viewer = netrun_console_owner(src)
	return viewer?.netrun_view_denial(node)

/// Native actor restrictions follow the operator across built-in clients and ordinary terminals.
/mob/proc/netrun_view_denial(datum/component/netrun_node/node)
	return null

/// Revalidate the source on every tick, including worn optics and disabled implants.
/datum/netrun_console/proc/watch_target()
	return remote_session.watch_target()

/datum/netrun_remote_session/proc/watch_target()
	if(QDELETED(watch_node) || QDELETED(owner.operator) || watch_viewer != owner.operator || owner.is_locked())
		return null
	if(!watch_node.is_online() || owner.view_denial(watch_node))
		return null
	// Refresh moving endpoints before borrowing the retained routing table.
	owner.refresh_route_node(watch_node)
	var/route_started = SSnetrun.profile_armed ? TICK_USAGE : 0
	var/turf/here = owner.physical_turf()
	// Outside allowed wireless zones the connection uses a request-local restricted tree.
	// Never modify the shared table (e.g. reached.Cut()) or delete it.
	var/private_tree = owner.connection.wireless && owner.origin != NETRUN_ORIGIN_ENTITY && !owner.jack_valid() && (!here || (!is_station_level(here.z) && !is_mining_level(here.z)))
	var/datum/netrun_path_tree/tree
	if(private_tree)
		tree = owner.make_path_tree(TRUE)
	else
		var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
		var/datum/component/netrun_node/start = owner.physical_route_source()
		graph = SSnetrun.ensure_topology()
		tree = graph.route_snapshot(start, TRUE)
		SSnetrun.camera_route_borrows++
	var/allowed = tree && owner.can_route(watch_node, tree) && owner.node_level(watch_node, tree) >= NETRUN_ACCESS_USER
	if(SSnetrun.profile_armed)
		var/route_ms = max(0, TICK_DELTA_TO_MS(TICK_USAGE - route_started))
		SSnetrun.camera_route_check_ms += route_ms
		SSnetrun.camera_route_check_max_ms = max(SSnetrun.camera_route_check_max_ms, route_ms)
	if(private_tree)
		qdel(tree)
	if(!allowed)
		return null
	var/atom/source = watch_node.parent
	return source.netrun_view_target()

/datum/netrun_console/proc/start_watch(datum/component/netrun_node/node)
	return remote_session.start_watch(node)

/datum/netrun_remote_session/proc/start_watch(datum/component/netrun_node/node)
	if(!owner.operator?.client || QDELETED(node))
		return FALSE
	owner.stop_watch()
	watch_viewer = owner.operator
	watch_node = node
	var/atom/eye = owner.watch_target()
	if(!eye)
		owner.stop_watch()
		return FALSE
	if(owner.operator.netrun_watch_console && owner.operator.netrun_watch_console != owner)
		owner.operator.netrun_watch_console.stop_watch()
	owner.operator.netrun_watch_console = owner
	watch_eye = new(get_turf(eye), owner)
	owner.operator.reset_perspective(watch_eye)
	if(istype(owner.operator, /mob/camera/netrun_entity))
		var/mob/camera/netrun_entity/entity = owner.operator
		entity.update_vision()
	return TRUE

/datum/netrun_console/proc/stop_watch()
	return remote_session.stop_watch()

#undef NETRUN_MAX_WINDOWS
