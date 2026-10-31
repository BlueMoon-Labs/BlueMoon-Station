/datum/netrun_console
	/// Если задано - состояние tgui для этой консоли (импланты, сущности)
	var/datum/ui_state/state_override
	var/tgui_title = "Сетевой терминал"
	var/list/ui_catalog_context
	/// Lightweight subscriptions survive workspace changes; only the visible map owns a projection.
	var/ui_observing = FALSE
	var/ui_source_address
	var/ui_transit_revision = -1
	var/list/ui_context_sources = list()
	var/list/ui_legacy_context
	var/turf/ui_legacy_turf
	var/ui_legacy_status_address
	var/list/ui_legacy_status

/datum/netrun_console/proc/observe_ui_state(defer_context_refresh = FALSE)
	var/new_observation = !ui_observing
	if(new_observation)
		ui_observing = TRUE
		RegisterSignal(SSnetrun, COMSIG_NETRUN_NODES_CHANGED, PROC_REF(on_ui_nodes_changed))
		RegisterSignal(SSnetrun, COMSIG_NETRUN_TOPOLOGY_CHANGED, PROC_REF(on_ui_topology_changed))
		RegisterSignal(SSnetrun, COMSIG_NETRUN_NETWORK_CHANGED, PROC_REF(on_ui_network_changed))
		RegisterSignal(SSnetrun, COMSIG_NETRUN_CHAT_CHANGED, PROC_REF(on_ui_chat_changed))
	// Explicit wakes can replace the operator or attach a newly unconscious body.
	// ui_data alone defers the duplicate scan to its immediate reconciliation.
	if(new_observation || !defer_context_refresh)
		refresh_ui_context_sources()

/datum/netrun_console/proc/stop_ui_observation()
	map_view?.suspend()
	if(ui_observing)
		UnregisterSignal(SSnetrun, list(COMSIG_NETRUN_NODES_CHANGED, COMSIG_NETRUN_TOPOLOGY_CHANGED, COMSIG_NETRUN_NETWORK_CHANGED, COMSIG_NETRUN_CHAT_CHANGED))
	ui_observing = FALSE
	for(var/atom/source as anything in ui_context_sources)
		UnregisterSignal(source, ui_context_sources[source])
	ui_context_sources.Cut()
	ui_legacy_context = null
	ui_legacy_turf = null
	ui_legacy_status = null
	ui_legacy_status_address = null

/// A carried host can change turf when its container moves without receiving MOVED itself.
/datum/netrun_console/proc/refresh_ui_context_sources(list/viewers)
	var/list/targets = list()
	var/atom/movable/carrier = physical_host()
	while(ismovable(carrier))
		targets |= carrier
		carrier = carrier.loc
	if(operator)
		targets |= operator
	add_ui_context_sources(targets)
	if(isnull(viewers))
		var/datum/ui_source = QDELETED(netrun_ui_source) ? src : netrun_ui_source
		viewers = SStgui.get_all_open_uis(ui_source)
	for(var/datum/tgui/ui as anything in viewers)
		if(ui.user)
			targets |= ui.user
	for(var/atom/source as anything in ui_context_sources.Copy())
		if(source in targets)
			continue
		UnregisterSignal(source, ui_context_sources[source])
		ui_context_sources -= source
	for(var/atom/source as anything in targets)
		if(ui_context_sources[source] || QDELETED(source))
			continue
		var/list/signals = list(COMSIG_ATOM_ENTERED, COMSIG_ATOM_EXITED, COMSIG_PARENT_QDELETING)
		if(ismob(source))
			signals |= list(COMSIG_MOB_EQUIPPED_ITEM, COMSIG_MOB_UNEQUIPPED_ITEM)
		ui_context_sources[source] = signals | list(COMSIG_MOVABLE_MOVED)
		RegisterSignal(source, signals, PROC_REF(on_ui_context_changed))
		RegisterSignal(source, COMSIG_MOVABLE_MOVED, PROC_REF(on_ui_context_moved))

/// Consoles with credentials supplied by another physical actor can observe it too.
/datum/netrun_console/proc/add_ui_context_sources(list/targets)
	return

/// Movement changes coordinates. Credentials and source/sector context are checked
/// independently; clearing them here turns each walking step into a full map scan.
/datum/netrun_console/proc/on_ui_context_moved(datum/source)
	SIGNAL_HANDLER
	invalidate_ui()

/datum/netrun_console/proc/on_ui_context_changed(datum/source, atom/movable/changed_atom)
	SIGNAL_HANDLER
	access_cache = null
	ui_node_levels?.Cut()
	ui_legit_levels?.Cut()
	network_level_cache?.Cut()
	invalidate_projection_caches()
	// Ownership can change without moving to another turf or changing ID access.
	// Invalidate the transferred item's nodes now, including devices in a bag;
	// their deferred movement task may not have run by the next UI request.
	if(istype(changed_atom, /obj/item) && map_view?.subscribed)
		for(var/atom/contained as anything in changed_atom.GetAllContents())
			var/datum/component/netrun_node/node = contained.GetComponent(/datum/component/netrun_node)
			if(node)
				map_view.invalidate_node_access(node.address)
	// Equipment and containment signals also fire for ordinary items that do not
	// affect credentials. Wake the UI, then let the map compare the actual access
	// and route context before deciding which parts of its projection changed.
	invalidate_ui()

/// Native ID access lists and NTnet switches still have legacy direct writes. Compare only
/// this small context, never the graph/panels; a quiet session does not serialize its UI.
/datum/netrun_console/proc/reconcile_ui_context()
	if(!ui_observing)
		return
	var/datum/ui_source = QDELETED(netrun_ui_source) ? src : netrun_ui_source
	var/list/viewers = SStgui.get_all_open_uis(ui_source)
	refresh_ui_context_sources(viewers)
	// The observed credential set is independent of which viewer TGUI renders
	// first. Alternating two users must not look like a station-wide ID change.
	var/list/credential_users = list()
	for(var/datum/tgui/ui as anything in viewers)
		if(ui.user)
			credential_users[REF(ui.user)] = ui.user
	if(operator)
		credential_users[REF(operator)] = operator
	var/list/credentials = list()
	for(var/reference in sort_list(credential_users.Copy()))
		var/mob/viewer = credential_users[reference]
		credentials += list(list(viewer, viewer == operator ? user_access(TRUE) : netrun_mob_access(viewer)))
	if(!operator)
		credentials += list(list(null, user_access(TRUE)))
	var/turf/here = physical_turf()
	if(ui_legacy_turf != here)
		on_ui_context_moved(src)
	ui_legacy_turf = here
	var/list/current = list(credentials, SSntnet.is_enabled(), length(SSntnet.catalog), SSnetworks.station_network?.setting_disabled)
	if(ui_legacy_context && !netrun_snapshot_equal(ui_legacy_context, current))
		on_ui_context_changed(src)
	ui_legacy_context = current
	// APC charge, relay load and other older status readers contain direct native writes.
	// Sample just the displayed device, and send nothing while its fields are unchanged.
	var/address = workspace_view == "pinned" ? remote_session.active_window : ((workspace_view in list("map", "files")) ? map_view.selected_address : null)
	var/datum/component/netrun_node/node = address ? SSnetrun.find_node(address) : null
	var/atom/target = node?.parent
	var/list/status = target && !QDELETED(target) ? target.netrun_status() : null
	if(ui_legacy_status_address == address && ui_legacy_status && !netrun_snapshot_equal(ui_legacy_status, status))
		invalidate_ui()
	ui_legacy_status_address = address
	ui_legacy_status = status

/datum/netrun_console/proc/on_ui_node_changed(datum/source, datum/component/netrun_node/node, flags)
	SIGNAL_HANDLER
	if(!node)
		return
	var/list/changes = list()
	changes[node.address] = flags
	on_ui_nodes_changed(source, changes)

/datum/netrun_console/proc/on_ui_nodes_changed(datum/source, list/changes)
	SIGNAL_HANDLER
	if(!length(changes) || !is_ui_active())
		return
	// Infrastructure affects reachability on every workspace. Ordinary unrelated activity
	// is handled only by a visible map and must not wake every terminal in the world.
	var/transit_revision = SSnetrun.topology?.transit_availability_revision || 0
	var/routes_changed = transit_revision != ui_transit_revision
	var/relevant = FALSE
	for(var/address in changes)
		if(changes[address] & (NETRUN_CHANGED_BINDING | NETRUN_CHANGED_REMOVED))
			routes_changed = TRUE
		if(address == ui_source_address || address == map_view.selected_address || address == remote_session.active_window || (address in remote_session.windows))
			relevant = TRUE
	if(routes_changed)
		ui_transit_revision = transit_revision
		invalidate_projection_caches()
	if(routes_changed || relevant)
		invalidate_ui()

/datum/netrun_console/proc/on_ui_topology_changed(datum/source)
	SIGNAL_HANDLER
	ui_transit_revision = SSnetrun.topology?.transit_availability_revision || 0
	invalidate_projection_caches()
	invalidate_ui()

/datum/netrun_console/proc/on_ui_network_changed(datum/source, datum/netrun_network/network)
	RETURN_TYPE(/datum/component/netrun_node)
	SIGNAL_HANDLER
	if(network?.id == map_view.selected_network || selected_node()?.network == network)
		invalidate_ui()

/datum/netrun_console/proc/on_ui_chat_changed(datum/source)
	SIGNAL_HANDLER
	if(workspace_view == "terminal")
		invalidate_ui()

/datum/netrun_console/ui_state(mob/user)
	if(state_override)
		return state_override
	return ..()

/datum/netrun_console/ui_interact(mob/user, datum/tgui/ui)
	operator = user
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "NetrunTerminal", tgui_title)
		// Event-driven: SSnetrun pushes updates through flush_ui only when state actually changes
		// or a live countdown is ticking, instead of tgui re-serializing the graph every tick.
		ui.set_autoupdate(FALSE)
		ui.open()

/datum/netrun_console/ui_data(mob/user, datum/ui_source)
	ui_rendered_at = world.time
	netrun_ui_source = ui_source || src // scheduler
	if(user)
		if(operator != user)
			ui_network_catalog = null
		operator = user
	note_ui_activity(TRUE)
	// Matrix clicks need no global discovery pass. The live delivery/finish
	// checks own fresh trees; this snapshot only describes the visible panel.
	refresh_route_node(selected_node())
	if(!intrusion.breach || (workspace_view in list("map", "files", "agents", "pinned", "terminal", "web")))
		ui_routes = acquire_ui_routes()
	else
		ui_routes = null
		ui_routes_borrowed = FALSE
	// Route-source resolution can itself publish a carried endpoint's latest
	// movement. Drain the merged batch before choosing this viewer's map cache.
	SSnetrun.flush_node_publications()
	ui_source_address = ui_routes?.source?.address
	ui_transit_revision = SSnetrun.topology?.transit_availability_revision || 0
	reconcile_ui_context()
	access_cache = user_access()
	network_level_cache = list()
	ui_node_levels = list()
	ui_legit_levels = list()
	ui_latency = list()
	ui_commands = list()
	ui_keys = list()
	ui_bonuses = list()
	ui_files = all_files()
	ui_completion_cache = list()
	ui_projection_cache = null
	ui_selected_resolved = FALSE
	ui_serializing = TRUE
	var/list/session
	if(user)
		ui_source = ui_source || src
		session = map_view.wire_session(user, ui_source, SStgui.get_open_ui(user, ui_source))
	. = build_ui_data(user, ui_source, session)
	access_cache = null
	network_level_cache = null
	ui_node_levels = null
	ui_legit_levels = null
	ui_latency = null
	ui_commands = null
	ui_keys = null
	ui_bonuses = null
	ui_files = null
	ui_completion_cache = null
	ui_projection_cache = null
	ui_selected_node_cache = null
	ui_selected_resolved = FALSE
	ui_serializing = FALSE
	connection.ui_refreshed_nodes = null
	if(ui_routes_borrowed)
		// Borrowed the server's shared routing table; never destroy it on teardown.
		ui_routes = null
		ui_routes_borrowed = FALSE
	else
		QDEL_NULL(ui_routes)

/datum/netrun_console/ui_static_data(mob/user)
	if(user)
		operator = user
	return list("cli" = cli_payload(workspace_view == "terminal"), "networks" = network_catalog(), "operations" = operations_payload())

/datum/netrun_console/proc/build_ui_data(mob/user, datum/ui_source, list/session)
	var/list/data = list()
	data["input_ack"] = input_ack
	append_operations_payload(data, session)
	data["origin"] = origin
	data["ui_theme"] = theme_id(user)
	data["workspace_view"] = workspace_view
	data["wireless"] = connection.wireless
	if(!intrusion.breach || world.time >= ui_uplink_refresh)
		ui_uplink_value = has_uplink()
		var/datum/netrun_execution_limits/limits = SSnetrun.get_execution_limits()
		ui_uplink_refresh = world.time + limits.ui_refresh_interval
	data["uplink"] = ui_uplink_value
	data["trace"] = round(intrusion.trace, 0.1)
	data["locked"] = is_locked() ? round((intrusion.lockout_until - world.time) / (1 SECONDS)) : 0
	data["can_breach"] = intrusion.can_breach
	data["can_autobreach"] = intrusion.can_breach && !!daemon_capability("autobreach")
	data["log"] = log
	data["notices"] = notices
	data["security"] = workspace_view == "breach" ? list("defended" = null, "entries" = list()) : security_session.payload()
	data["file_exchange"] = file_exchange.payload()
	data["access_export"] = workspace_view == "files" ? acquired_key_payload() : null
	data["jack"] = connection.jack ? list("address" = connection.jack.address, "name" = connection.jack.get_name()) : null
	data["host_actions"] = host_actions()
	data["file"] = (workspace_view in list("files", "agents")) ? file_payload() : null
	// Matrix clicks must not rebuild the hidden graph, global autocomplete,
	// selected-node command help or the native machine UI behind the puzzle.
	if(intrusion.breach && !(workspace_view in list("map", "files", "agents", "pinned", "terminal", "web")))
		append_network_catalog(data, session, FALSE)
		data["view"] = null
		data["web"] = null
		data["map"] = null
		data["selected"] = null
		data["selected_network"] = null
		data["ping_route"] = null
		data["ping"] = null
		data["events"] = null
		data["waypoint"] = null
		data["storage"] = storage_payload()
		data["shard"] = shard_payload()
		data["breach"] = intrusion.breach.ui_payload()
		data["entity"] = entity_data()
		data["combat"] = workspace_view == "combat" ? combat_payload() : combat_context.status_payload()
		data["chat"] = chat_data()
		append_cli_payload(data, FALSE, session)
		data["windows"] = windows_payload()
		data["window"] = null
		return data

	append_network_catalog(data, session)

	if(workspace_view == "web" && web_browsing())
		data["view"] = null
		data["selected"] = null
		data["web"] = web_payload()
		data["storage"] = storage_payload()
		data["shard"] = shard_payload()
		data["breach"] = intrusion.breach?.ui_payload()
		data["entity"] = entity_data()
		data["combat"] = workspace_view == "combat" ? combat_payload() : combat_context.status_payload()
		data["chat"] = chat_data()
		append_cli_payload(data, FALSE, session)
		data["windows"] = windows_payload()
		data["window"] = null
		data["map"] = null
		data["selected_network"] = null
		data["ping_route"] = null
		data["ping"] = null
		data["events"] = null
		data["waypoint"] = null
		return data
	data["web"] = null

	data["map"] = workspace_view == "map" ? map_payload(user, ui_source, session) : null
	data["waypoint"] = workspace_view == "map" ? waypoint_payload() : null
	data["view"] = null

	var/datum/component/netrun_node/node = selected_node()
	var/list/selected = null
	if(workspace_view == "agents" && node && node_visible(node))
		selected = list("address" = node.address, "name" = node.get_name(), "type" = node.node_type,
			"online" = node.is_online(), "access" = node_level(node), "commands" = node.command_entries(src))
	else if((workspace_view in list("map", "files", "pinned")) && node && node_visible(node))
		var/level = node_level(node)
		selected = node.ui_entry(src)
		if(origin == NETRUN_ORIGIN_ENTITY && istype(host, /mob/camera/netrun_entity))
			var/mob/camera/netrun_entity/entity = host
			selected["movement"] = entity.navigation?.movement_payload(node, ui_routes)
		selected["network"] = node.network?.short_name
		selected["legit"] = legit_node_level(node)
		selected["commands"] = node.command_entries(src)
		selected["interactions"] = node_interactions(node)
		selected["contacts"] = entity_contacts(node)
		// APC/шлюз - это точка входа в ЛВС: отдаём доступ и взлом сети прямо на узле, без верхней панели.
		if((node.node_type in list(NETRUN_NODE_APC, NETRUN_NODE_GATEWAY)) && node.network)
			var/datum/netrun_network/lan = node.network
			var/lan_level = network_level(lan)
			selected["lan"] = list(
				"id" = lan.id,
				"code" = lan.code,
				"name" = lan.name,
				"color" = lan.color,
				"security" = lan.security,
				"access" = lan_level,
				"has_key" = has_key(lan),
				"can_breach" = intrusion.can_breach && lan_level < NETRUN_ACCESS_GUEST,
			)
		selected["logs"] = level >= NETRUN_ACCESS_USER ? node.logs.Copy() : list()
		selected["packets"] = level >= NETRUN_ACCESS_USER ? node.packet_headers_payload() : list()
		var/atom/A = node.parent
		selected["status"] = level >= NETRUN_ACCESS_USER ? A.netrun_status() : list()
		if(level >= NETRUN_ACCESS_GUEST)
			var/datum/netrun_file/manual/public_manual = public_node_manual(node)
			selected["manual_uid"] = public_manual?.uid
		if(node.file_store && level >= max(NETRUN_ACCESS_USER, node.fortress?.file_access_level(src) || 0))
			selected["files"] = node.file_store.ui_entries()
			selected["storage"] = list("used" = node.used_storage(), "capacity" = node.file_store?.capacity)
		selected["fortress"] = node.fortress?.ui_payload(src, level)
	data["selected"] = selected

	var/datum/netrun_network/selnet = SSnetrun.networks[map_view.selected_network]
	if(selnet)
		var/snlevel = network_level(selnet)
		data["selected_network"] = list(
			"id" = selnet.id,
			"code" = selnet.code,
			"name" = selnet.name,
			"color" = selnet.color,
			"security" = selnet.security,
			"access" = snlevel,
			"has_key" = has_key(selnet),
			"can_breach" = intrusion.can_breach && snlevel < NETRUN_ACCESS_GUEST,
			"log" = snlevel >= NETRUN_ACCESS_USER ? selnet.logs.Copy(max(1, length(selnet.logs) - 14)) : list(),
		)
	else
		data["selected_network"] = null

	data["storage"] = storage_payload()
	data["shard"] = shard_payload()

	data["breach"] = intrusion.breach?.ui_payload()
	data["entity"] = entity_data()
	data["combat"] = workspace_view == "combat" ? combat_payload() : combat_context.status_payload()
	data["chat"] = chat_data()
	append_cli_payload(data, workspace_view == "terminal", session)
	data["windows"] = windows_payload()
	data["window"] = workspace_view == "pinned" && remote_session.active_window ? window_payload() : null
	data["ping_route"] = map_view.has_ping() ? map_view.ping_route : null
	data["ping"] = map_view.ping_metadata()
	// Only a visible map animates events; hidden pages never serialize the shared ring.
	data["events"] = workspace_view == "map" ? SSnetrun.recent_events(src) : null
	data["search"] = workspace_view == "map" ? search_payload() : null
	data["agent_count"] = length(agents())
	data["agents"] = workspace_view == "agents" ? agents_payload() : null
	return data

/// Поиск по всей сети: находит достижимые узлы по имени/адресу, чтобы проложить
/// к ним маршрут даже если они ещё не открыты на карте. Доступ к узлу этим не выдаётся.
/datum/netrun_console/proc/search_payload()
	if(!map_view.search_query)
		return null
	var/query = lowertext(map_view.search_query)
	. = list()
	var/count = 0
	for(var/address in SSnetrun.nodes_by_address)
		if(count >= 24)
			break
		var/datum/component/netrun_node/node = SSnetrun.nodes_by_address[address]
		if(QDELETED(node) || QDELETED(node.parent))
			continue
		if(!findtext(lowertext(node.get_name()), query) && !findtext(lowertext(address), query))
			continue
		if(!can_route(node))
			continue
		count++
		. += list(list(
			"address" = node.address,
			"name" = node.get_name(),
			"type" = node.node_type,
			"network" = node.network?.short_name,
			"online" = node.is_online(),
			"visible" = node_visible(node),
		))

/// Дополнительные кнопки носителя (выдернуть провод, вынуть шард, вернуться в тело...)
/datum/netrun_console/proc/host_actions()
	. = list()
	if(has_service_lead())
		. += list(list("id" = "choose_connection", "name" = "Подключиться к порту рядом", "icon" = "plug"))
	if(connection.jack)
		. += list(list("id" = "unjack", "name" = "Выдернуть провод", "icon" = "plug-circle-xmark"))
	if(inventory.shard)
		. += list(list("id" = "eject_shard", "name" = "Извлечь шард", "icon" = "eject"))

/// Данные для режима сущности - переопределяется у консоли сущности
/datum/netrun_console/proc/entity_data()
	return null

// MARK: Node neighborhoods and graph navigation

/datum/netrun_console/proc/map_focus_node()
	var/datum/component/netrun_node/selected = selected_node()
	if(selected && node_visible(selected))
		return selected
	return route_source()

/datum/netrun_console/proc/map_payload(mob/user, datum/ui_source, list/session)
	return map_view.wire_payload(user, ui_source, session)

/datum/netrun_console/proc/route_reveal_addresses(datum/component/netrun_node/focus)
	. = list()
	var/datum/component/netrun_node/waypoint = map_view.waypoint_address ? SSnetrun.find_node(map_view.waypoint_address) : null
	if(waypoint && can_route(waypoint))
		var/datum/netrun_route/route = route_to(waypoint)
		for(var/list/hop as anything in route.hops)
			. += hop["ref"]
		qdel(route)
	var/datum/component/netrun_node/selected = selected_node() || focus
	if(selected && node_visible(selected))
		var/datum/netrun_route/route = route_to(selected)
		for(var/list/hop as anything in route.hops)
			. += hop["ref"]
		qdel(route)

/// The client receives the selected route, not the whole server routing table.
/datum/netrun_console/proc/map_route_payload(datum/component/netrun_node/target)
	if(!target)
		return null
	var/datum/netrun_path_tree/tree = connection.read_path_tree()
	var/list/addresses = tree.addresses_to(target.address)
	var/datum/netrun_route/route = route_to(target, tree)
	. = list(
		"route" = addresses,
		"hops" = max(0, length(addresses) - 1),
		"latency" = route.latency * 100,
		"revision" = tree.revision,
		"reachable" = !!length(addresses),
	)
	qdel(route)
	release_path_tree(tree)

/// Network travel uses hops and node addresses, independently of physical tile distance.
/datum/netrun_console/proc/waypoint_payload()
	if(!map_view.waypoint_address)
		return null
	var/datum/component/netrun_node/node = SSnetrun.find_node(map_view.waypoint_address)
	if(QDELETED(node) || QDELETED(node.parent))
		map_view.waypoint_address = null
		return null
	var/datum/netrun_route/route = route_to(node)
	var/list/addresses = list()
	for(var/list/hop as anything in route.hops)
		addresses += hop["ref"]
	. = list(
		"address" = node.address,
		"name" = node.get_name(),
		"type" = node.node_type,
		"reachable" = length(addresses) > 0,
		"hops" = max(0, length(addresses) - 1),
		"route" = addresses,
		"next" = length(addresses) > 1 ? addresses[2] : null,
	)
	qdel(route)

/datum/netrun_console/proc/storage_payload()
	var/list/local = list()
	for(var/datum/netrun_file/file as anything in inventory.local_store.files)
		local += list(file.ui_entry(inventory.selected_file_uid))
	for(var/datum/netrun_file/file as anything in inventory.session_store?.files)
		var/list/entry = file.ui_entry(inventory.selected_file_uid)
		entry["source"] = "session"
		local += list(entry)
	return list("files" = local, "used" = netrun_storage_used(inventory.local_store.files), "capacity" = inventory.local_store.capacity)

/datum/netrun_console/proc/shard_payload()
	if(!inventory.shard)
		return null
	var/list/shard_files = list()
	for(var/datum/netrun_file/file as anything in inventory.shard.file_store.files)
		shard_files += list(file.ui_entry(inventory.selected_file_uid))
	return list("name" = inventory.shard.name, "files" = shard_files, "used" = netrun_storage_used(inventory.shard.file_store.files), "capacity" = inventory.shard.file_store.capacity)

// MARK: Мост «сайты NTnet в терминале» (только чтение, данные из SSntnet)

/// Можно ли с этой точки просматривать сайты NTnet
/datum/netrun_console/proc/web_browsing()
	return origin != NETRUN_ORIGIN_CIRCUIT

/datum/netrun_console/proc/web_payload()
	SSntnet.last_used = world.time
	SSntnet.refresh_index()
	var/list/sites = list()
	for(var/site_id in SSntnet.sites)
		var/list/site = SSntnet.sites[site_id]
		sites += list(list("id" = site_id, "domain" = site["domain"], "title" = site["title"]))
	var/list/payload = list(
		"available" = SSntnet.available,
		"sites" = sites,
		"site" = null,
		"page" = null,
	)
	var/list/site = remote_session.web_site_id ? SSntnet.sites[remote_session.web_site_id] : null
	if(!site)
		remote_session.web_site_id = null
		remote_session.web_slug = null
		return payload
	var/list/pages = list()
	for(var/list/page as anything in site["pages"])
		pages += list(list("slug" = page["slug"], "title" = page["title"]))
	payload["site"] = list("id" = remote_session.web_site_id, "domain" = site["domain"], "title" = site["title"], "pages" = pages)
	if(!remote_session.web_slug)
		return payload
	SSntnet.request_page(remote_session.web_site_id, remote_session.web_slug)
	var/cache_key = json_encode(list(remote_session.web_site_id, remote_session.web_slug))
	var/list/cached = SSntnet.pages[cache_key]
	payload["page"] = list(
		"slug" = remote_session.web_slug,
		"title" = cached ? cached["title"] : remote_session.web_slug,
		"text" = cached ? cached["text"] : null,
		"loading" = !cached && !SSntnet.page_failed(remote_session.web_site_id, remote_session.web_slug),
		"failed" = SSntnet.page_failed(remote_session.web_site_id, remote_session.web_slug),
	)
	return payload

/datum/netrun_console/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	// Protocol-only acknowledgement; it must not wake ICE, change selections,
	// produce player action feedback or initiate another UI broadcast.
	if(action == "map_sync_ack")
		map_view.ack_full(ui, params["epoch"], params["revision"])
		return TRUE
	operator = ui.user
	var/input_nonce = params["_netrun_action"]
	if(istext(input_nonce) && length(input_nonce) <= NETRUN_INPUT_ACK_MAX_LENGTH)
		input_ack = input_nonce
	note_user_action()
	. = handle_ui_action(action, params, ui, input_nonce)
	if(!QDELETED(src))
		finish_user_action(selected_node())
	return .

/// Dispatch follows the ordinary TGUI permission check; denied domain actions still get receipt.
/datum/netrun_console/proc/handle_ui_action(action, list/params, datum/tgui/ui, input_nonce)
	if(action == "combat_pass")
		return pass_combat_turn(params["turn_id"])
	if(action == "combat_join")
		return join_combat_turn(params["turn_id"])
	if(action == "access_export")
		return !!export_acquired_key(params["name"], !!params["to_shard"])
	if(action == "entity_file_offer")
		return offer_entity_file(params["address"], params["ref"], params["uid"])
	if(action in list("entity_file_accept", "entity_file_reject"))
		return file_exchange.respond(params["id"], action == "entity_file_accept")
	if(action in list("security_probe", "security_trace", "security_map", "security_pursue"))
		return security_session.act(action, params["id"])
	if(action == "map_resync")
		map_view.resync(ui)
		return TRUE
	if(file_act(action, params, ui.user))
		return TRUE
	switch(action)
		if("set_theme")
			return set_ui_theme(params["id"], ui.user)
		if("appearance_update")
			return update_persona(params, ui.user)
		if("workspace_view")
			var/page = params["page"]
			if(page in list("terminal", "map", "files", "agents", "pinned", "combat", "breach", "web"))
				if(page != "web" || web_browsing())
					workspace_view = page
					map_view.viewed_network_id = page == "web" ? "web" : null
			return TRUE
		if("map_sector")
			map_view.select_sector(params["id"], params["z"])
			return TRUE
		if("relay_hop")
			if(origin == NETRUN_ORIGIN_ENTITY && istype(host, /mob/camera/netrun_entity))
				var/mob/camera/netrun_entity/entity = host
				var/datum/component/netrun_node/target = SSnetrun.find_node(params["address"])
				if(SSnetrun.get_topology().is_relay(entity.host_node) && SSnetrun.get_topology().is_relay(target))
					entity.relay_hop(target)
			return TRUE
		if("view_network")
			if(params["id"] == "web" && web_browsing())
				workspace_view = "web"
				map_view.viewed_network_id = "web"
			else
				workspace_view = "map"
				map_view.viewed_network_id = null
			return TRUE
		if("select_network")
			var/datum/netrun_network/network = SSnetrun.networks[params["id"]]
			if(network && can_reach(network))
				map_view.selected_network = network.id
				map_view.selected_address = null
			return TRUE
		if("set_waypoint")
			var/datum/component/netrun_node/node = SSnetrun.find_node(params["address"])
			// Пеленг можно ставить на любой достижимый узел, даже ещё не открытый на карте.
			if(node && (node_visible(node) || can_route(node)))
				map_view.waypoint_address = node.address
				log_line("Пеленг на [node.get_name()] [node.address].", "label")
			else
				log_line("К этому узлу нет маршрута для пеленга.", "bad")
			return TRUE
		if("clear_waypoint")
			map_view.waypoint_address = null
			return TRUE
		if("focus_host")
			var/datum/component/netrun_node/here = route_source()
			if(here)
				map_view.selected_address = here.address
				map_view.selected_network = null
				map_view.follow_source()
			return TRUE
		if("search")
			var/text = params["text"]
			map_view.search_query = istext(text) ? trim(copytext_char(sanitize(text), 1, 40)) : null
			if(!length(map_view.search_query))
				map_view.search_query = null
			return TRUE
		if("select")
			var/datum/component/netrun_node/node = SSnetrun.find_node(params["address"])
			if(node && node_visible(node))
				map_view.selected_address = node.address
				map_view.selected_network = null
				var/turf/position = node.physical_turf()
				if(node.binding_sector != map_view.active_sector || position?.z != map_view.active_z)
					map_view.select_sector(node.binding_sector, position?.z)
			return TRUE
		if("window_open")
			open_window(params["address"])
			return TRUE
		if("window_close")
			close_window(params["address"])
			return TRUE
		if("window_focus")
			if(params["address"] in remote_session.windows)
				workspace_view = "pinned"
				remote_session.active_window = params["address"]
				map_view.selected_address = remote_session.active_window
				map_view.selected_network = null
			return TRUE
		if("remote_act")
			remote_request(params["address"], params["request"], params["arguments"], input_nonce)
			return TRUE
		if("window_act")
			window_act(params["address"], params["waction"], params, input_nonce)
			return TRUE
		if("command")
			run_command(selected_node(), params["id"], input_nonce, params["packet_id"])
			return TRUE
		if("node_interact")
			return node_interact(selected_node(), params["id"], ui.user)
		if("entity_signal")
			return signal_entity(selected_node(), params["ref"], null, input_nonce)
		if("entity_message")
			if(!istext(params["text"]))
				return FALSE
			return signal_entity(selected_node(), params["ref"], params["text"], input_nonce)
		if("breach")
			start_breach(params["kind"] == "network" ? "network" : "node", params["id"], !!params["automatic"])
			return TRUE
		if("recover_salvage")
			recover_salvage(params["uid"])
			return TRUE
		if("breach_pick")
			intrusion.breach?.choose(text2num("[params["index"]]"))
			return TRUE
		if("breach_abort")
			intrusion.breach?.finish()
			return TRUE
		if("program_use")
			program_use(params["uid"], params["target"], params["turn_id"])
			return TRUE
		if("bot_launch")
			launch_bot_file(params["uid"], params["address"])
			return TRUE
		if("agent_order")
			agent_order(params["ref"], params["order"], params["address"], params)
			return TRUE
		if("download")
			transfer_from_node(params["uid"], !!params["to_shard"], input_nonce = input_nonce)
			return TRUE
		if("upload")
			transfer_to_node(params["uid"], input_nonce = input_nonce)
			return TRUE
		if("delete_remote")
			delete_from_node(params["uid"], input_nonce = input_nonce)
			return TRUE
		if("delete_local")
			var/datum/netrun_file/file = find_local_file(params["uid"])
			if(file)
				delete_local_file(file)
			return TRUE
		if("read")
			read_file(ui.user, params["uid"], input_nonce)
			return TRUE
		if("cli")
			cli(params["text"])
			return TRUE
		if("chat_send")
			chat_send(params["text"])
			return TRUE
		if("set_handle")
			var/new_handle = reject_bad_name(params["handle"], allow_numbers = TRUE)
			if(new_handle && origin != NETRUN_ORIGIN_ENTITY)
				handle = copytext_char(new_handle, 1, 24)
			return TRUE
		if("web_site")
			if(SSntnet.sites[params["id"]])
				remote_session.web_site_id = params["id"]
				remote_session.web_slug = SSntnet.has_page(remote_session.web_site_id, "index") ? "index" : null
			return TRUE
		if("web_page")
			if(remote_session.web_site_id && SSntnet.has_page(remote_session.web_site_id, params["slug"]))
				remote_session.web_slug = params["slug"]
			return TRUE
		if("web_back")
			if(remote_session.web_slug)
				remote_session.web_slug = null
			else
				remote_session.web_site_id = null
			return TRUE
		else
			return host_act(action, params, ui.user)

/// Кнопки носителя
/datum/netrun_console/proc/host_act(action, list/params, mob/user)
	switch(action)
		if("choose_connection")
			if(has_service_lead() && user == operator)
				INVOKE_ASYNC(src, PROC_REF(choose_connection), user)
			return TRUE
		if("unjack")
			set_jack(null)
			log_line("Провод отключён.")
			return TRUE
		if("eject_shard")
			eject_shard(user)
			return TRUE

/datum/netrun_console/proc/insert_shard(obj/item/netrun_shard/new_shard, mob/user)
	if(inventory.shard)
		to_chat(user, span_warning("Разъём уже занят."))
		return FALSE
	if(user && !user.transferItemToLoc(new_shard, host))
		return FALSE
	inventory.set_shard(new_shard)
	log_line("Шард подключён: [inventory.shard.name].")
	return TRUE

/datum/netrun_console/proc/eject_shard(mob/user)
	if(!inventory.shard)
		return
	var/obj/item/netrun_shard/old = inventory.shard
	inventory.set_shard(null)
	old.forceMove(physical_turf())
	if(user && isliving(user))
		user.put_in_hands(old)
	log_line("Шард извлечён.")

// MARK: Файловые операции

/datum/netrun_console/proc/remote_file(datum/component/netrun_node/node, uid)
	for(var/datum/netrun_file/file as anything in node?.file_store?.files)
		if(file.uid == uid)
			return file

/// Only live firmware bound to this node is public; an uploaded readme is ordinary data.
/datum/netrun_console/proc/public_node_manual(datum/component/netrun_node/node, uid)
	RETURN_TYPE(/datum/netrun_file/manual)
	for(var/datum/netrun_file/manual/manual in node?.file_store?.files)
		if((isnull(uid) || manual.uid == uid) && manual.node_ref?.resolve() == node)
			return manual

/// Public documentation can be read at GUEST; copies and other files retain disk protection.
/datum/netrun_console/proc/remote_file_access(action, datum/component/netrun_node/node, uid)
	if(action == "read" && public_node_manual(node, uid))
		return NETRUN_ACCESS_GUEST
	return max(action == "delete" ? NETRUN_ACCESS_ROOT : NETRUN_ACCESS_USER, node?.fortress?.file_access_level(src) || 0)

/datum/netrun_console/proc/transfer_from_node(uid, to_shard, datum/component/netrun_node/node, delivered = FALSE, input_nonce)
	if(!delivered)
		return queue_file_request("download", selected_node(), uid, to_shard, input_nonce)
	if(!node?.file_store?.files || node_level(node) < max(NETRUN_ACCESS_USER, node.fortress?.file_access_level(src) || 0) || !node.is_online(node != connection.jack) || !can_route(node))
		return
	var/datum/netrun_file/file = remote_file(node, uid)
	if(!file)
		return
	var/datum/netrun_file_store/destination = to_shard ? inventory.shard?.file_store : inventory.local_store
	var/reason = node.file_store.transfer_denial(destination, file)
	if(reason)
		log_line(reason, "bad")
		return FALSE
	var/datum/netrun_file/stored = node.file_store.transfer_to(destination, file)
	if(!stored)
		log_line("Файл или память назначения изменились.", "bad")
		return FALSE
	inventory.selected_file_uid = stored.uid
	node.touch()
	node.add_log("[log_source()]: скачан [file.name].")
	log_line("Скачано: [file.name].", "good")
	var/illegal = legit_node_level(node) < NETRUN_ACCESS_USER
	node.network?.add_log("[log_source()] скачал [file.name] с [node.address][illegal ? " (без авторизации)" : ""]", illegal)
	if(illegal)
		add_trace(4 * node.get_security())
	return TRUE

/datum/netrun_console/proc/transfer_to_node(uid, datum/component/netrun_node/node, delivered = FALSE, input_nonce)
	if(!delivered)
		return queue_file_request("upload", selected_node(), uid, input_nonce = input_nonce)
	if(!node?.file_store?.files || node_level(node) < max(NETRUN_ACCESS_USER, node.fortress?.file_access_level(src) || 0) || !node.is_online(node != connection.jack) || !can_route(node))
		return
	var/datum/netrun_file/file = find_local_file(uid)
	if(!file)
		return
	var/datum/netrun_file_store/source = inventory.store_for(file)
	var/reason = source?.transfer_denial(node.file_store, file)
	if(reason || !source)
		log_line(reason || "Исходный носитель недоступен.", "bad")
		return FALSE
	if(!source.transfer_to(node.file_store, file))
		log_line("Файл или память узла изменились.", "bad")
		return FALSE
	node.touch()
	node.add_log("[log_source()]: загружен [file.name].")
	log_line("Загружено: [file.name].", "good")
	var/illegal = legit_node_level(node) < NETRUN_ACCESS_USER
	node.network?.add_log("[log_source()] загрузил [file.name] на [node.address]")
	if(illegal)
		add_trace(3 * node.get_security())
	return TRUE

/datum/netrun_console/proc/delete_from_node(uid, datum/component/netrun_node/node, delivered = FALSE, input_nonce)
	if(!delivered)
		return queue_file_request("delete", selected_node(), uid, input_nonce = input_nonce)
	if(!node?.file_store?.files || node_level(node) < NETRUN_ACCESS_ROOT || !node.is_online(node != connection.jack) || !can_route(node))
		return
	var/datum/netrun_file/file = remote_file(node, uid)
	if(!file)
		return
	if(!file.can_delete(node.file_store))
		log_line("Хранилище узла доступно только для чтения.", "bad")
		return FALSE
	if(!node.file_store.remove(file))
		log_line("Исходный файл или носитель изменились.", "bad")
		return FALSE
	log_line("Удалено с узла: [file.name].", "average")
	node.add_log("[log_source()]: удалён [file.name].")
	node.network?.add_log("[log_source()] удалил [file.name] с [node.address]")
	if(legit_node_level(node) < NETRUN_ACCESS_ROOT)
		add_trace(5 * node.get_security())
	qdel(file)
	return TRUE

/// Один путь доставки файлов для кнопок, CLI и будущих клиентов.
/datum/netrun_console/proc/queue_file_request(action, datum/component/netrun_node/node, uid, to_shard = FALSE, input_nonce)
	var/list/labels = list("download" = "Скачивание файла", "upload" = "Загрузка файла", "deposit" = "Разгрузка файла", "delete" = "Удаление файла", "read" = "Чтение файла")
	var/datum/netrun_packet_context/operation = new("file", labels[action] || "Файловый запрос",
		route_source()?.address, node?.address, "file.[action]", src, input_nonce)
	if(action == "deposit")
		var/reason = deposit_denial(uid, node)
		if(reason)
			return reject_operation(operation, reason)
	var/required = remote_file_access(action, node, uid)
	var/datum/netrun_path_tree/tree = make_path_tree()
	if(!node?.file_store?.files || !can_route(node, tree) || node_level(node, tree) < required || !node.is_online(node != connection.jack) || is_locked() || world.time < next_command)
		qdel(tree)
		return reject_operation(operation, "Файловый запрос недоступен: нет связи, доступа или канал занят.")
	var/lat = latency_to(node, tree)
	var/list/poll_route = tree.addresses_to(node.address)
	qdel(tree)
	var/datum/netrun_request/file/packet = new(src, node, action, uid, to_shard, node.network, operator, operation)
	var/storage_reason = packet.storage_denial()
	if(storage_reason)
		packet.reject(storage_reason)
		qdel(packet)
		return FALSE
	next_command = world.time + max(lat, 0.5 SECONDS)
	if(lat)
		log_line("[node.address]: файловый запрос отправлен, ~[lat * 100] мс.")
	return packet.send(lat, poll_route)

/datum/netrun_console/proc/deliver_file_request(action, datum/component/netrun_node/node, uid, to_shard, datum/netrun_network/sent_network, mob/sender, datum/netrun_packet_context/operation)
	if(QDELETED(node))
		operation?.finish("cancelled", "Узел удалён.")
		return FALSE
	node.join_network()
	var/datum/netrun_path_tree/tree = make_path_tree()
	var/required = remote_file_access(action, node, uid)
	var/reachable = can_route(node, tree)
	if(reachable)
		operation?.receive(tree.addresses_to(node.address))
	if(sender != operator || node.network != sent_network || is_locked() || !reachable || !node.is_online(node != connection.jack) || node_level(node, tree) < required)
		qdel(tree)
		log_line("Файловый запрос отменён: соединение изменилось.", "bad")
		operation?.finish("rejected", "Соединение, оператор или доступ к файлам изменились.")
		return FALSE
	qdel(tree)
	switch(action)
		if("download")
			. = transfer_from_node(uid, to_shard, node, TRUE)
		if("upload")
			. = transfer_to_node(uid, node, TRUE)
		if("deposit")
			. = deposit_to_node(uid, node, TRUE)
		if("delete")
			. = delete_from_node(uid, node, TRUE)
		if("read")
			if(node_level(node) < remote_file_access(action, node, uid))
				operation?.finish("rejected", "Недостаточно прав для чтения файла.")
				return FALSE
			var/datum/netrun_file/file = remote_file(node, uid)
			if(!file)
				operation?.finish("rejected", "Файл больше не существует.")
				return FALSE
			file.show(operator)
			node.add_log("[log_source()]: прочитан [file.name].")
			if(!public_node_manual(node, uid) && legit_node_level(node) < NETRUN_ACCESS_USER)
				add_trace(2 * node.get_security())
			. = TRUE
	if(!.)
		operation?.finish("rejected", "Файл не передан: файл или место хранения недоступны.")
	else
		var/list/results = list("download" = "Файл скачан.", "upload" = "Файл передан на устройство.", "deposit" = "Исходный файл разгружен на сервер.", "delete" = "Файл удалён.", "read" = "Файл открыт для чтения.")
		operation?.set_result(results[action])
	return !!.

/datum/netrun_console/proc/read_file(mob/user, uid, input_nonce)
	var/datum/netrun_file/file = find_local_file(uid)
	if(!file)
		return queue_file_request("read", selected_node(), uid, input_nonce = input_nonce)
	file?.show(user)

// MARK: Командная строка


/datum/netrun_console/proc/network_catalog()
	var/list/catalog_context = ui_projection_context()
	if(ui_network_catalog && netrun_snapshot_equal(ui_catalog_context, catalog_context))
		return ui_network_catalog
	ui_catalog_context = catalog_context
	var/list/networks = list()
	var/list/homes = home_networks()
	for(var/network_id in SSnetrun.networks)
		var/datum/netrun_network/network = SSnetrun.networks[network_id]
		var/reachable = can_reach(network)
		if(!reachable && network.isolated)
			continue
		networks += list(list(
			"id" = network.id,
			"name" = network.name,
			"short" = network.short_name,
			"code" = network.code,
			"color" = network.color,
			"security" = network.security,
			"isolated" = network.isolated,
			"home" = (network in homes),
			"reachable" = reachable,
			"access" = network_level(network),
			"has_key" = has_key(network),
			"can_breach" = intrusion.can_breach && reachable && network_level(network) < NETRUN_ACCESS_GUEST,
			"nodes" = length(network.nodes),
		))
	if(web_browsing() && has_uplink() && SSntnet.is_enabled())
		networks += list(list(
			"id" = "web",
			"name" = "NTnet — сайты",
			"short" = "WEB",
			"code" = "WEB",
			"color" = "#5bc0de",
			"security" = 0,
			"isolated" = FALSE,
			"home" = FALSE,
			"reachable" = TRUE,
			"access" = NETRUN_ACCESS_GUEST,
			"has_key" = FALSE,
			"can_breach" = FALSE,
			"nodes" = length(SSntnet.catalog),
		))
	ui_network_catalog = networks
	return networks

/// The backend retains omitted fields, so unchanged LAN catalogs need no repeated JSON.
/datum/netrun_console/proc/append_network_catalog(list/data, list/session, refresh = TRUE)
	var/list/catalog = refresh ? network_catalog() : ui_network_catalog
	if(!catalog)
		catalog = list()
	if(session && session["network_catalog"] == catalog)
		return
	data["networks"] = catalog
	if(session)
		session["network_catalog"] = catalog

/// Small authorization/connectivity key shared by catalog and completion projections.
/// File-store revisions cover keys, daemons and renamed/deleted completion candidates.
/datum/netrun_console/proc/ui_projection_context()
	// Within one ui_data pass every input below is fixed, and catalog/CLI validity checks each
	// rebuild this list; compute it once per pass. Standalone callers still get a fresh snapshot.
	if(ui_serializing && ui_projection_cache)
		return ui_projection_cache
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	var/datum/component/netrun_node/source = route_source()
	var/list/access = user_access()
	. = list(operator, source?.address, source?.network?.id, source?.is_online(), graph.revision, graph.transit_availability_revision,
		map_view.authorization_revision, access.Copy(), is_locked(), intrusion.can_breach,
		inventory.local_store?.revision, inventory.shard, inventory.shard?.file_store?.revision,
		connection.wireless, connection.jack?.address, web_browsing(), ui_uplink_value,
		SSntnet.is_enabled(), length(SSntnet.catalog))
	if(ui_serializing)
		ui_projection_cache = .
