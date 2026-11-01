/**
 * Явный адаптер штатного ui_data/ui_act машины. Политика и параметры живут
 * на датуме-подтипе, а доставка, права, трассировка и журнал — в консоли.
 * Неопубликованные действия машины через сеть вызвать нельзя.
 */
/datum/netrun_api
	parent_type = /datum/netrun_provider
	state_signals = list(COMSIG_UI_ACT, COMSIG_ATOM_UPDATED_ICON)

/datum/netrun_api/read_data(atom/A, datum/netrun_console/console, datum/component/netrun_node/node)
	if(!console.operator)
		return list()
	var/list/device_data = A.ui_static_data(console.operator) || list()
	device_data = device_data.Copy()
	var/list/live_data = A.ui_data(console.operator)
	for(var/key in live_data)
		device_data[key] = live_data[key]
	return device_data

/// Native actions keep their own final checks and side effects. Providers never
/// lend the operator silicon privileges, machine ID access, or a physical UI.
/datum/netrun_api/execute(atom/target, action, list/arguments, datum/netrun_console/console, datum/component/netrun_node/node)
	if(!interface_name || !console?.operator || QDELETED(node) || node.parent != target || action_unavailable_reason(target, action, console, node))
		return FALSE
	var/datum/ui_state/netrun_request/request_state = new(console, node, src, action)
	// Network reachability replaces physical proximity only. Native ui_status may
	// still reject an ID, a team's uniform, a lock, or another machine-specific policy.
	var/status = min(request_state.can_use_topic(target, console.operator), target.ui_status(console.operator, request_state))
	if(status != UI_INTERACTIVE)
		qdel(request_state)
		console.log_line("Штатный интерфейс устройства запретил запрос.", "bad")
		return FALSE
	var/list/entry = actions[action]
	var/list/native_params = arguments.Copy()
	for(var/list/param as anything in entry["params"])
		if(param["native_text"])
			var/id = param["id"]
			native_params[id] = "[native_params[id]]"
	var/list/fixed_params = entry["fixed_params"]
	for(var/key in fixed_params)
		native_params[key] = fixed_params[key]
	var/datum/tgui/request = new(console.operator, target, interface_name)
	request.state = request_state
	request.status = status
	world.PushUsr(console.operator, CALLBACK(target, TYPE_PROC_REF(/datum, ui_act), entry["native_action"] || action, native_params, request, request_state))
	qdel(request)
	qdel(request_state)
	return TRUE

/datum/netrun_console/proc/remote_payload(datum/component/netrun_node/node)
	var/datum/netrun_provider/api = SSnetrun.get_provider(node.parent)
	return api?.payload(node.parent, src, node)

/datum/netrun_console/proc/remote_request(address, action, list/arguments, input_nonce)
	var/datum/component/netrun_node/node = refresh_route_node(SSnetrun.find_node(address))
	var/datum/netrun_provider/api = node ? SSnetrun.get_provider(node.parent) : null
	var/list/entry = api?.actions[action]
	var/datum/netrun_packet_context/operation = new("remote", entry?["name"] || "Запрос устройства",
		route_source()?.address, node?.address, action, src, input_nonce)
	if(!entry)
		return reject_operation(operation, "Действие устройства недоступно.")
	var/datum/netrun_path_tree/tree = make_path_tree()
	if(!can_route(node, tree) || !node.is_online() || is_locked() || node_level(node, tree) < api.action_access(action) || world.time < next_command)
		qdel(tree)
		return reject_operation(operation, "Запрос недоступен: нет связи, доступа или канал занят.")
	var/reason = api.action_unavailable_reason(node.parent, action, src, node)
	if(reason)
		qdel(tree)
		log_line(reason, "bad")
		return reject_operation(operation, reason)
	var/list/clean = api.clean_params(action, arguments || list())
	if(isnull(clean))
		qdel(tree)
		log_line("Некорректные параметры запроса [action].", "bad")
		return reject_operation(operation, "Некорректные параметры запроса.")
	var/lat = latency_to(node, tree)
	var/list/poll_route = tree.addresses_to(node.address)
	qdel(tree)
	next_command = world.time + max(lat, 0.5 SECONDS)
	log_line("[address]: [entry["name"]] — доставка ~[lat * 100] мс.")
	var/datum/netrun_request/remote/request = new(src, node, api, action, clean, node.network, operator, operation)
	return request.send(lat, poll_route)

/datum/netrun_console/proc/do_remote_request(datum/component/netrun_node/node, datum/netrun_provider/api, action, list/params, datum/netrun_network/sent_network, mob/sender)
	var/datum/netrun_request/remote/request = new(src, node, api, action, params, sent_network, sender)
	return request.deliver()

/// Контекст проверенного сетевого запроса: не раздаёт привилегии или доступ мобу.
/datum/ui_state/netrun_request
	requires_physical_interaction = FALSE
	var/datum/weakref/console_ref
	var/datum/weakref/node_ref
	var/datum/weakref/target_ref
	var/datum/weakref/host_ref
	var/datum/weakref/provider_ref
	var/datum/weakref/network_ref
	var/action

/datum/ui_state/netrun_request/New(datum/netrun_console/console, datum/component/netrun_node/node, datum/netrun_provider/provider, action)
	console_ref = WEAKREF(console)
	node_ref = WEAKREF(node)
	var/atom/target = node.parent
	target_ref = WEAKREF(target)
	var/datum/host = target.ui_host(console.operator)
	if(!QDELETED(host))
		host_ref = WEAKREF(host)
	provider_ref = WEAKREF(provider)
	if(node.network)
		network_ref = WEAKREF(node.network)
	src.action = action

/datum/ui_state/netrun_request/can_use_topic(src_object, mob/user)
	var/datum/netrun_console/console = console_ref?.resolve()
	var/datum/component/netrun_node/node = node_ref?.resolve()
	var/datum/netrun_provider/provider = provider_ref?.resolve()
	var/atom/target = target_ref?.resolve()
	var/datum/host = host_ref?.resolve()
	if(!console || !node || !target || !host || node.parent != target || console.operator != user || console.is_locked() || !node.is_online())
		return UI_CLOSE
	// ui_status resolves ui_host(), e.g. a covered turret's native control cover.
	// Both identities are fixed to this endpoint; an arbitrary or replacement host is denied.
	if((src_object != target && src_object != host) || target.ui_host(user) != host)
		return UI_CLOSE
	var/list/entry = provider?.actions[action]
	if(!entry || SSnetrun.get_provider(node.parent) != provider || provider.action_unavailable_reason(node.parent, action, console, node))
		return UI_CLOSE
	node.join_network()
	if(node.network != network_ref?.resolve())
		return UI_CLOSE
	var/datum/netrun_path_tree/tree = console.make_path_tree()
	var/allowed = console.can_route(node, tree) && console.node_level(node, tree) >= provider.action_access(action)
	qdel(tree)
	return allowed ? UI_INTERACTIVE : UI_CLOSE

/datum/netrun_console/proc/apply_firmware_bypass(datum/component/netrun_node/node)
	var/datum/netrun_provider/api = SSnetrun.get_provider(node.parent)
	if(!api?.allow_emag)
		return FALSE
	var/atom/A = node.parent
	world.PushUsr(operator, CALLBACK(A, TYPE_PROC_REF(/atom, emag_act), operator))
	node.add_log("[log_source()]: атака защиты прошивки.")
	node.network?.add_log("Атака прошивки [node.address]: [log_source()].", TRUE)
	log_game("NETRUN FIRMWARE: [key_name(operator)] -> [node.address] [AREACOORD(A)]")
	log_line("Атака передана контроллеру прошивки; результат зависит от состояния машины.", "average")
	add_trace(35)
	return TRUE
