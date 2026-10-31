/// A console owns a permitted projection, never a second physical topology.
/datum/netrun_map_view
	var/datum/netrun_console/owner
	var/selected_address
	var/selected_network
	var/viewed_network_id
	var/waypoint_address
	var/search_query
	var/list/ping_route
	var/ping_at = 0
	var/ping_id = 0
	var/ping_until = 0
	var/ping_timer
	var/structure_revision = 0
	var/state_revision = 0
	/// Only stationary geometry and paint data invalidate the cached canvas.
	var/static_revision = 0
	var/list/static_structure
	var/subscribed = FALSE
	var/dirty = TRUE
	/// A structural change (binding, removal, topology) needs a full projection rebuild.
	var/structure_dirty = TRUE
	/// Addresses whose status changed since the last payload - updated in place, no full pass.
	var/list/dirty_nodes = list()
	var/refreshed_at = -INFINITY
	var/list/snapshot
	var/list/structure
	var/list/node_entries = list()
	var/list/edge_entries = list()
	var/list/node_indexes = list()
	var/list/incident_edges = list()
	var/list/shown_addresses = list()
	var/list/shown_network_counts = list()
	/// Access before a source move, including networks on floors outside the current view.
	var/list/projected_network_levels = list()
	var/list/projected_network_keys = list()
	var/projected_mapper = 0
	var/inventory_changed = FALSE
	var/route_reveal_dirty = FALSE
	var/list/pending_network_access = list()
	var/list/revealed_addresses = list()
	var/list/context
	/// Authorization changes replace every UI baseline, including credentials lost by an operator.
	var/authorization_revision = 0
	var/list/security_context
	var/wire_epoch = 0
	var/wire_session_id = 0
	/// REF strings and timestamps only: closed windows/users are never retained by this cache.
	var/list/wire_sessions = list()
	/// Avoid walking every viewer on each TGUI poll.
	var/wire_cleanup_at = -INFINITY
	var/list/wire_journal = list()
	var/wire_journal_entries = 0
	var/active_sector
	var/active_z
	var/source_sector
	var/source_z
	var/list/sector_catalog = list()
	var/datum/netrun_map_geometry/geometry
	/// Navigation and wire cursors belong to the console; permitted projections belong
	/// to operators. Parking them avoids rebuilding the station on every alternating
	/// TGUI viewer. Closed/idle viewers are bounded and released with the subscription.
	var/list/operator_projections = list()
	var/active_projection_key
	var/projection_generation = 0
	var/projection_cleanup_at = -INFINITY
	/// Only events that can draw something in a viewer keep this console repainting.
	var/event_refresh_until = 0
	var/events_need_reconcile = TRUE
	/// Trusted private field contract. Only projection state is switched; command
	/// grants, navigation, authorization_revision and wire_sessions remain shared.
	var/static/list/projection_defaults = list(
		"structure_revision" = 0, "state_revision" = 0, "static_revision" = 0,
		"static_structure" = null, "dirty" = TRUE, "structure_dirty" = TRUE,
		"dirty_nodes" = list(), "refreshed_at" = -INFINITY, "snapshot" = null,
		"structure" = null, "node_entries" = list(), "edge_entries" = list(),
		"node_indexes" = list(), "incident_edges" = list(), "shown_addresses" = list(),
		"shown_network_counts" = list(), "projected_network_levels" = list(),
		"projected_network_keys" = list(), "projected_mapper" = 0,
		"inventory_changed" = FALSE, "route_reveal_dirty" = FALSE,
		"pending_network_access" = list(), "revealed_addresses" = list(),
		"context" = null, "security_context" = null, "wire_epoch" = 0,
		"wire_journal" = list(), "wire_journal_entries" = 0,
		"source_sector" = null, "source_z" = null, "sector_catalog" = list())

/datum/netrun_map_view/New(datum/netrun_console/owner)
	src.owner = owner
	geometry = new

/// Called only within synchronous payload serialization. A parked projection's
/// immutable entries and journal remain intact while another operator is rendered.
/datum/netrun_map_view/proc/select_operator_projection()
	var/key = owner.operator ? REF(owner.operator) : "anonymous"
	var/list/active = active_projection_key ? operator_projections[active_projection_key] : null
	if(active_projection_key != key)
		if(active)
			var/list/fields = active["fields"]
			for(var/field in projection_defaults)
				fields[field] = vars[field]
		var/list/next = operator_projections[key]
		if(next)
			var/list/fields = next["fields"]
			for(var/field in projection_defaults)
				vars[field] = fields[field]
		else
			// The first viewer adopts the initial state, including a resumed map.
			// Later viewers start with fresh lists and a distinct transport epoch.
			if(active_projection_key)
				var/previous_source_sector = source_sector
				var/previous_source_z = source_z
				var/list/previous_nodes = node_entries
				var/list/previous_edges = edge_entries
				for(var/field in projection_defaults)
					var/default_value = projection_defaults[field]
					vars[field] = islist(default_value) ? list() : default_value
				// Opening another viewer is not a physical source move and must not
				// reset the console's shared sector navigation to the source floor.
				source_sector = previous_source_sector
				source_z = previous_source_z
				// Rebuild checks the new operator's permissions for every candidate.
				// Equal immutable entries can then be shared across viewers; the
				// resulting dictionaries and disclosed sets are always independent.
				node_entries = previous_nodes
				edge_entries = previous_edges
				advance_wire_epoch()
			next = list("fields" = list())
			operator_projections[key] = next
			events_need_reconcile = TRUE
		active_projection_key = key
		active = next
	active["seen"] = world.time
	if(length(operator_projections) <= 8 && world.time < projection_cleanup_at)
		return
	projection_cleanup_at = world.time + 1 MINUTES
	var/oldest_key
	var/oldest_at = INFINITY
	for(var/cached_key in operator_projections)
		if(cached_key == active_projection_key)
			continue
		var/list/cached = operator_projections[cached_key]
		if(world.time > cached["seen"] + 5 MINUTES)
			operator_projections -= cached_key
		else if(cached["seen"] < oldest_at)
			oldest_key = cached_key
			oldest_at = cached["seen"]
	if(length(operator_projections) > 8 && oldest_key)
		operator_projections -= oldest_key

/// Recreated/evicted projections must never reuse an old viewer's wire baseline.
/datum/netrun_map_view/proc/advance_wire_epoch()
	projection_generation = max(projection_generation, wire_epoch) + 1
	wire_epoch = projection_generation

/datum/netrun_map_view/proc/subscribe()
	if(subscribed)
		return
	subscribed = TRUE
	dirty = TRUE
	events_need_reconcile = TRUE
	RegisterSignal(SSnetrun, COMSIG_NETRUN_NODES_CHANGED, PROC_REF(on_nodes_changed))
	RegisterSignal(SSnetrun, COMSIG_NETRUN_TOPOLOGY_CHANGED, PROC_REF(on_topology_changed))
	RegisterSignal(SSnetrun, COMSIG_NETRUN_EVENT_POSTED, PROC_REF(on_event_posted))

/// Closed/hidden maps do not receive every process movement elsewhere in the world.
/datum/netrun_map_view/proc/suspend()
	operator_projections.Cut()
	active_projection_key = null
	event_refresh_until = 0
	if(!subscribed)
		return
	subscribed = FALSE
	UnregisterSignal(SSnetrun, list(COMSIG_NETRUN_NODES_CHANGED, COMSIG_NETRUN_TOPOLOGY_CHANGED, COMSIG_NETRUN_EVENT_POSTED))
	dirty_nodes.Cut()
	dirty = TRUE

/datum/netrun_map_view/Destroy()
	if(ping_timer)
		deltimer(ping_timer)
	ping_timer = null
	UnregisterSignal(SSnetrun, list(COMSIG_NETRUN_NODES_CHANGED, COMSIG_NETRUN_TOPOLOGY_CHANGED, COMSIG_NETRUN_EVENT_POSTED))
	QDEL_NULL(geometry)
	snapshot = null
	structure = null
	context = null
	node_entries.Cut()
	edge_entries.Cut()
	node_indexes.Cut()
	incident_edges.Cut()
	shown_addresses.Cut()
	shown_network_counts.Cut()
	projected_network_levels.Cut()
	projected_network_keys.Cut()
	pending_network_access.Cut()
	revealed_addresses.Cut()
	static_structure = null
	wire_sessions.Cut()
	wire_journal.Cut()
	security_context = null
	operator_projections.Cut()
	owner = null
	return ..()

/// A ping is one finite event. Repeating the same path must still have a new identity.
/datum/netrun_map_view/proc/start_ping(list/hops, duration = 6 SECONDS)
	if(ping_timer)
		deltimer(ping_timer)
	ping_route = hops.Copy()
	ping_at = world.time
	ping_until = world.time + duration
	ping_id++
	ping_timer = addtimer(CALLBACK(src, PROC_REF(on_ping_expired), ping_id), duration, TIMER_STOPPABLE)
	SSnetrun.retain_route_interest(ping_route, ping_until)
	owner?.invalidate_ui()

/datum/netrun_map_view/proc/ping_deadline()
	return ping_until || ping_at + 6 SECONDS

/datum/netrun_map_view/proc/has_ping()
	return ping_route && world.time < ping_deadline()

/datum/netrun_map_view/proc/ping_metadata()
	if(!has_ping())
		return null
	return list("id" = ping_id, "remaining_ms" = max(0, (ping_deadline() - world.time) * 100))

/datum/netrun_map_view/proc/on_ping_expired(sequence)
	if(sequence != ping_id)
		return
	ping_timer = null
	expire_ping(sequence)

/// The scheduler also closes an overdue ping if its timer has not run yet.
/datum/netrun_map_view/proc/expire_ping(sequence)
	if((!isnull(sequence) && sequence != ping_id) || !ping_route || world.time < ping_deadline())
		return FALSE
	if(ping_timer)
		deltimer(ping_timer)
	ping_timer = null
	ping_route = null
	owner?.invalidate_ui()
	return TRUE

/// A leaf changing its APC is repaired incrementally while both ends and the
/// gateway set remain visible. Permission changes fall back to rebuild().
/datum/netrun_map_view/proc/on_node_changed(datum/source, datum/component/netrun_node/node, flags)
	SIGNAL_HANDLER
	if(!node)
		return
	var/list/changes = list()
	changes[node.address] = flags
	on_nodes_changed(source, changes)

/// One publication batch wakes each map once, regardless of how many devices
/// changed. Merge parked-view dirty queues here without per-node UI scheduling.
/datum/netrun_map_view/proc/on_nodes_changed(datum/source, list/changes)
	SIGNAL_HANDLER
	var/changed = FALSE
	var/datum/netrun_topology/graph = SSnetrun.topology
	for(var/address in changes)
		var/flags = changes[address]
		if(!(flags & ~NETRUN_CHANGED_DETAILS))
			continue
		var/datum/component/netrun_node/node = SSnetrun.nodes_by_address[address]
		// Leaf activity cannot change permissions or forwarding. Its hidden or
		// offscreen status does not contribute anything to this viewer's map.
		var/all_projections = (flags & (NETRUN_CHANGED_BINDING | NETRUN_CHANGED_REMOVED)) || graph?.is_infrastructure(node) || length(graph?.adjacency[address]) > 1
		var/list/known = node_entries[address]
		// Permitted offscreen endpoints still own sector-catalog membership.
		// Their cached binding supplies these scalar checks without a turf scan.
		var/offscreen_changed = known && (known["z"] != node?.topology_turf?.z || known["sector"] != node?.binding_sector || known["network"] != node?.network?.id)
		if(all_projections || !snapshot || shown_addresses[address] || offscreen_changed)
			if(flags & NETRUN_CHANGED_REMOVED)
				structure_dirty = TRUE
			else
				dirty_nodes[address] = TRUE
			changed = TRUE
		for(var/key in operator_projections)
			if(key == active_projection_key)
				continue
			var/list/cached = operator_projections[key]
			var/list/fields = cached["fields"]
			known = fields["node_entries"][address]
			offscreen_changed = known && (known["z"] != node?.topology_turf?.z || known["sector"] != node?.binding_sector || known["network"] != node?.network?.id)
			if(!all_projections && fields["snapshot"] && !fields["shown_addresses"][address] && !offscreen_changed)
				continue
			if(flags & NETRUN_CHANGED_REMOVED)
				fields["structure_dirty"] = TRUE
			else
				fields["dirty_nodes"][address] = TRUE
			changed = TRUE
	if(changed)
		owner?.invalidate_ui()

/datum/netrun_map_view/proc/on_topology_changed(datum/source)
	SIGNAL_HANDLER
	structure_dirty = TRUE
	for(var/key in operator_projections)
		if(key == active_projection_key)
			continue
		var/list/cached = operator_projections[key]
		cached["fields"]["structure_dirty"] = TRUE
	if(owner)
		owner.invalidate_ui()

/datum/netrun_map_view/proc/on_event_posted(datum/source, kind, from_ref, to_ref, list/route, lifetime = NETRUN_MAP_EVENT_LIFETIME)
	SIGNAL_HANDLER
	if(subscribed && owner && event_visible(from_ref, to_ref, route))
		event_refresh_until = max(event_refresh_until, world.time + lifetime)
		owner.invalidate_ui()

/// Events only animate visible endpoints and route segments. A packet elsewhere
/// must not keep every open station map serializing its panels and countdowns.
/datum/netrun_map_view/proc/event_visible(from_ref, to_ref, list/route)
	// Preserve global/synthetic notifications that have no physical endpoint.
	if(!length(route) && !SSnetrun.nodes_by_address[from_ref] && !SSnetrun.nodes_by_address[to_ref])
		return TRUE
	if(event_visible_in(from_ref, to_ref, route, shown_addresses))
		return TRUE
	for(var/key in operator_projections)
		if(key == active_projection_key)
			continue
		var/list/cached = operator_projections[key]
		if(event_visible_in(from_ref, to_ref, route, cached["fields"]["shown_addresses"]))
			return TRUE
	return FALSE

/datum/netrun_map_view/proc/event_visible_in(from_ref, to_ref, list/route, list/shown)
	if(shown[from_ref] || shown[to_ref])
		return TRUE
	for(var/address in route)
		if(shown[address])
			return TRUE
	return FALSE

/// Opening a map or revealing a sector can expose an event posted before this
/// subscription. Initialize its fade once from the bounded recent-event history.
/datum/netrun_map_view/proc/reconcile_visible_events()
	events_need_reconcile = FALSE
	for(var/list/event as anything in SSnetrun.map_event_snapshot())
		var/until = event["until"] || event["t"] + NETRUN_MAP_EVENT_LIFETIME
		if(until <= world.time || !event_visible(event["from"], event["to"], event["route"]))
			continue
		event_refresh_until = max(event_refresh_until, until)

/datum/netrun_map_view/proc/invalidate(sensitive = TRUE)
	dirty = TRUE
	for(var/key in operator_projections)
		if(key == active_projection_key)
			continue
		var/list/cached = operator_projections[key]
		cached["fields"]["dirty"] = TRUE
	if(sensitive)
		authorization_revision++
	if(owner)
		owner.invalidate_ui()

/// A node-specific permission change does not invalidate unrelated projections.
/datum/netrun_map_view/proc/invalidate_node_access(address)
	if(!address)
		invalidate()
		return
	dirty_nodes[address] = TRUE
	route_reveal_dirty = TRUE
	for(var/key in operator_projections)
		if(key == active_projection_key)
			continue
		var/list/cached = operator_projections[key]
		var/list/fields = cached["fields"]
		fields["dirty_nodes"][address] = TRUE
		fields["route_reveal_dirty"] = TRUE
	authorization_revision++
	owner?.invalidate_ui()

/datum/netrun_map_view/proc/invalidate_network_access(network_id)
	var/datum/netrun_network/network = SSnetrun.networks[network_id]
	if(!network)
		invalidate()
		return
	for(var/datum/component/netrun_node/node as anything in network.nodes)
		if(!QDELETED(node))
			dirty_nodes[node.address] = TRUE
	for(var/key in operator_projections)
		if(key == active_projection_key)
			continue
		var/list/cached = operator_projections[key]
		var/list/fields = cached["fields"]
		for(var/datum/component/netrun_node/node as anything in network.nodes)
			if(!QDELETED(node))
				fields["dirty_nodes"][node.address] = TRUE
		fields["pending_network_access"][network_id] = TRUE
		fields["route_reveal_dirty"] = TRUE
	pending_network_access[network_id] = TRUE
	route_reveal_dirty = TRUE
	authorization_revision++
	owner?.invalidate_ui()

/datum/netrun_map_view/proc/invalidate_inventory()
	inventory_changed = TRUE
	route_reveal_dirty = TRUE
	for(var/key in operator_projections)
		if(key == active_projection_key)
			continue
		var/list/cached = operator_projections[key]
		cached["fields"]["inventory_changed"] = TRUE
		cached["fields"]["route_reveal_dirty"] = TRUE
	authorization_revision++
	owner?.invalidate_ui()

/// Reconciliation catches credentials and native state that have no change signal.
/// One UI request shares a path tree; clicks during a puzzle never call this method.
/datum/netrun_map_view/proc/payload()
	subscribe()
	select_operator_projection()
	// Drain revocations before deciding which pending nodes to reconcile.
	owner.access_session.process_events()
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	var/datum/component/netrun_node/focus = owner.map_focus_node()
	var/turf/current = owner.route_source()?.physical_turf() || owner.physical_turf()
	var/current_sector = netrun_sector_for(current)
	if(source_sector != current_sector || source_z != current?.z)
		active_sector = current_sector
		active_z = current?.z
	source_sector = current_sector
	source_z = current?.z
	// Access is included so a credential change (an ID picked up or dropped) refreshes the
	// projection through the context diff - no periodic full pass is needed to catch it.
	var/datum/component/netrun_node/source = owner.route_source()
	var/list/current_context = list(owner.operator, source?.address, source?.is_online(), source?.network?.id, selected_address, waypoint_address, active_sector, active_z, owner.user_access(), owner.is_locked(), graph.transit_availability_revision)
	var/list/changed_networks
	var/entity_source_changed = FALSE
	var/navigation_changed = FALSE
	if(!netrun_snapshot_equal(context, current_context))
		if(reconcile_navigation_context(graph, current_context))
			navigation_changed = TRUE
		else if(source_network_projection_unchanged(graph, source, current_context))
			reconcile_route_reveals()
		else
			changed_networks = reconcile_entity_source_context(graph, source, current_context)
			entity_source_changed = !isnull(changed_networks)
			if(isnull(changed_networks))
				changed_networks = reconcile_source_network_context(graph, source, current_context)
			if(isnull(changed_networks))
				changed_networks = reconcile_credential_context(graph, current_context)
			if(isnull(changed_networks))
				dirty = TRUE
	if(inventory_changed)
		inventory_changed = FALSE
		if(snapshot && owner.daemon_capability("reveal_nodes") != projected_mapper)
			dirty = TRUE
		else if(snapshot)
			for(var/id in projected_network_levels)
				var/datum/netrun_network/network = SSnetrun.networks[id]
				if(!network || !!projected_network_keys[id] == !!owner.has_key(network))
					continue
				invalidate_network_access(id)
	if(length(pending_network_access))
		if(!changed_networks)
			changed_networks = list()
		for(var/id in pending_network_access)
			var/datum/netrun_network/network = SSnetrun.networks[id]
			if(network)
				changed_networks[id] = owner.network_level(network)
		pending_network_access.Cut()
	if(route_reveal_dirty)
		route_reveal_dirty = FALSE
		if(snapshot && !dirty && !structure_dirty)
			reconcile_route_reveals()
	context = current_context
	// Credentials change the projection, not the identity of this UI stream. The
	// journal composes removals with later upserts, and a missing baseline forces a
	// full resync. A different operator/source must never inherit the old stream.
	var/list/current_security = list(owner.operator, owner.origin == NETRUN_ORIGIN_ENTITY ? owner.host : source?.address)
	if(!netrun_snapshot_equal(security_context, current_security))
		security_context = current_security
		advance_wire_epoch()
	// Fully event-driven: a full rebuild only on a structural change, context change or a new
	// graph revision; a status-only change updates just the affected nodes in place.
	if(dirty || structure_dirty || !snapshot || snapshot["revision"] != graph.revision)
		rebuild(graph)
	else if(length(dirty_nodes))
		apply_incremental(graph)
	if((entity_source_changed || navigation_changed) && !dirty && !structure_dirty)
		refresh_selected_zone()
	if(changed_networks && !dirty && !structure_dirty)
		refresh_network_gateways(changed_networks)
	if(events_need_reconcile)
		reconcile_visible_events()
	var/list/result = snapshot.Copy()
	result["focus"] = focus?.address
	result["route"] = owner.map_route_payload(owner.selected_node() || focus)
	// Readiness/stun can expire without changing the physical projection.
	result["relay_destinations"] = relay_destinations(graph, owner.selected_node(), shown_addresses, node_entries)
	return result

/// Selecting a device or waypoint changes route disclosure and the selected APC
/// shape. It does not change the permissions or geometry of every other device.
/datum/netrun_map_view/proc/reconcile_navigation_context(datum/netrun_topology/graph, list/current_context)
	if(!context || !snapshot || dirty || structure_dirty || snapshot["revision"] != graph.revision)
		return FALSE
	var/list/other_context = current_context.Copy()
	other_context[5] = context[5]
	other_context[6] = context[6]
	if(!netrun_snapshot_equal(context, other_context))
		return FALSE
	reconcile_route_reveals()
	return TRUE

/// Crossing departments need not replace the projection when both LAN grants stay
/// identical and the old APC is still in the new source's forwarding component.
/datum/netrun_map_view/proc/source_network_projection_unchanged(datum/netrun_topology/graph, datum/component/netrun_node/source, list/current_context)
	if(!context || !snapshot || dirty || structure_dirty || snapshot["revision"] != graph.revision || context[4] == current_context[4])
		return FALSE
	var/list/without_network_change = current_context.Copy()
	without_network_change[4] = context[4]
	if(!netrun_snapshot_equal(context, without_network_change))
		return FALSE
	var/list/previous_source = node_entries[source?.address]
	var/datum/component/netrun_node/old_apc = graph.nodes[previous_source?["uplink"]]
	if(!old_apc || !old_apc.is_online() || !source?.is_online() || !source.bound_apc?.is_online() || !owner.can_route(old_apc))
		return FALSE
	var/datum/netrun_network/old_network = SSnetrun.networks[context[4]]
	var/datum/netrun_network/new_network = source.network
	if(!old_network || !new_network || isnull(projected_network_levels[old_network.id]) || isnull(projected_network_levels[new_network.id]))
		return FALSE
	return projected_network_levels[old_network.id] == owner.network_level(old_network) && projected_network_levels[new_network.id] == owner.network_level(new_network)

/// A resident moving between connected hosts keeps its UI identity. Its home LAN,
/// local-endpoint privilege and hop permissions are the only changed inputs.
/datum/netrun_map_view/proc/reconcile_entity_source_context(datum/netrun_topology/graph, datum/component/netrun_node/source, list/current_context)
	if(owner.origin != NETRUN_ORIGIN_ENTITY || !context || !snapshot || dirty || structure_dirty || snapshot["revision"] != graph.revision || context[2] == current_context[2])
		return null
	if(context[5] != context[2] || current_context[5] != current_context[2])
		return null
	var/list/other_context = current_context.Copy()
	other_context[2] = context[2]
	other_context[4] = context[4]
	other_context[5] = context[5]
	if(!netrun_snapshot_equal(context, other_context))
		return null
	var/datum/component/netrun_node/old_source = graph.nodes[context[2]]
	if(QDELETED(old_source) || !old_source.is_online() || !source?.is_online() || !owner.can_route(old_source))
		return null
	var/datum/netrun_network/old_network = SSnetrun.networks[context[4]]
	var/datum/netrun_network/new_network = source.network
	if(!old_network || !new_network || isnull(projected_network_levels[old_network.id]) || isnull(projected_network_levels[new_network.id]))
		return null
	var/list/changed = list()
	for(var/datum/netrun_network/network as anything in list(old_network, new_network))
		if(!isnull(changed[network.id]))
			continue
		var/level = owner.network_level(network)
		if(projected_network_levels[network.id] == level)
			continue
		changed[network.id] = level
		for(var/datum/component/netrun_node/node as anything in network.nodes)
			if(QDELETED(node) || graph.nodes[node.address] != node)
				continue
			var/list/previous = node_entries[node.address]
			if(!previous || previous["access"] != owner.node_level(node))
				dirty_nodes[node.address] = TRUE
	for(var/datum/component/netrun_node/node as anything in list(old_source, source))
		dirty_nodes[node.address] = TRUE
		for(var/address in graph.neighbors(node.address))
			dirty_nodes[address] = TRUE
	reconcile_route_reveals()
	return changed

/// Selection follows the entity host, including when that host is an APC.
/datum/netrun_map_view/proc/refresh_selected_zone()
	var/list/zones = list()
	var/datum/component/netrun_node/selected = owner.selected_node()
	if(selected?.node_type == NETRUN_NODE_APC && shown_addresses[selected.address])
		var/list/zone = geometry.apc_zone(selected, active_z)
		if(zone)
			zones += list(zone)
	if(netrun_snapshot_equal(snapshot["apc_zones"], zones))
		return
	var/previous_revision = state_revision
	snapshot["apc_zones"] = zones
	static_structure[3] = zones
	snapshot["static_revision"] = ++static_revision
	snapshot["state_revision"] = ++state_revision
	record_wire_delta(previous_revision, list(), list(), list(), list())

/// A source moving between LANs in the same forwarding component changes only
/// home-LAN permissions. Visit those LANs, not every station node.
/datum/netrun_map_view/proc/reconcile_source_network_context(datum/netrun_topology/graph, datum/component/netrun_node/source, list/current_context)
	if(!context || !snapshot || dirty || structure_dirty || snapshot["revision"] != graph.revision || context[4] == current_context[4])
		return null
	var/list/other_context = current_context.Copy()
	other_context[4] = context[4]
	if(!netrun_snapshot_equal(context, other_context))
		return null
	var/list/previous_source = node_entries[source?.address]
	var/datum/component/netrun_node/old_apc = graph.nodes[previous_source?["uplink"]]
	if(!old_apc || !old_apc.is_online() || !source?.is_online() || !source.bound_apc?.is_online() || !owner.can_route(old_apc))
		return null
	var/datum/netrun_network/old_network = SSnetrun.networks[context[4]]
	var/datum/netrun_network/new_network = source.network
	if(!old_network || !new_network || isnull(projected_network_levels[old_network.id]) || isnull(projected_network_levels[new_network.id]))
		return null
	var/list/changed = list()
	for(var/datum/netrun_network/network as anything in list(old_network, new_network))
		var/level = owner.network_level(network)
		if(projected_network_levels[network.id] == level)
			continue
		changed[network.id] = level
		for(var/datum/component/netrun_node/node as anything in network.nodes)
			if(QDELETED(node) || graph.nodes[node.address] != node)
				continue
			var/list/previous = node_entries[node.address]
			if(!previous || previous["access"] != owner.node_level(node))
				dirty_nodes[node.address] = TRUE
	reconcile_route_reveals()
	return changed

/datum/netrun_map_view/proc/reconcile_route_reveals()
	var/list/new_revealed = owner.route_reveal_addresses(owner.map_focus_node())
	for(var/address in revealed_addresses)
		if(!(address in new_revealed))
			dirty_nodes[address] = TRUE
	for(var/address in new_revealed)
		if(!(address in revealed_addresses))
			dirty_nodes[address] = TRUE
	revealed_addresses = new_revealed

/// Native ID access may affect arbitrary check_access_list implementations, so
/// examine permissions without serializing unchanged entries. No guessed access
/// index can safely replace the native per-node check here.
/datum/netrun_map_view/proc/reconcile_credential_context(datum/netrun_topology/graph, list/current_context)
	if(!context || !snapshot || dirty || structure_dirty || snapshot["revision"] != graph.revision)
		return null
	var/list/other_context = current_context.Copy()
	other_context[9] = context[9]
	if(!netrun_snapshot_equal(context, other_context))
		return null
	reconcile_route_reveals()
	var/list/changed = list()
	var/reveal_all = owner.daemon_capability("reveal_nodes")
	for(var/id in projected_network_levels)
		var/datum/netrun_network/network = SSnetrun.networks[id]
		if(!network)
			return null
		var/level = owner.network_level(network)
		if(projected_network_levels[id] != level)
			changed[id] = level
	for(var/address in graph.nodes)
		var/datum/component/netrun_node/node = graph.nodes[address]
		if(QDELETED(node))
			continue
		var/list/previous = node_entries[address]
		var/visible = owner.can_route(node) && (reveal_all || (address in revealed_addresses) || owner.node_visible(node))
		if(!!previous != !!visible || (visible && previous["access"] != owner.node_level(node)))
			dirty_nodes[address] = TRUE
	return changed

/datum/netrun_map_view/proc/refresh_network_gateways(list/changed)
	if(!length(changed) || !snapshot)
		return
	var/list/gateways = snapshot["gateways"]
	var/list/next = gateways.Copy()
	var/modified = FALSE
	for(var/i in 1 to length(gateways))
		var/list/gateway = gateways[i]
		var/id = gateway["id"]
		if(isnull(changed[id]))
			continue
		var/list/entry = gateway.Copy()
		entry["access"] = changed[id]
		var/datum/netrun_network/network = SSnetrun.networks[id]
		entry["has_key"] = owner.has_key(network)
		entry["can_breach"] = owner.intrusion.can_breach && changed[id] < NETRUN_ACCESS_GUEST
		next[i] = entry
		modified = TRUE
	for(var/id in changed)
		projected_network_levels[id] = changed[id]
		var/datum/netrun_network/network = SSnetrun.networks[id]
		projected_network_keys[id] = owner.has_key(network)
	if(modified)
		var/previous_revision = state_revision
		snapshot["gateways"] = next
		snapshot["state_revision"] = ++state_revision
		record_wire_delta(previous_revision, list(), list(), list(), list())

/// Browsing a different sector never moves the runner or grants permissions.
/datum/netrun_map_view/proc/select_sector(id, z)
	for(var/list/sector as anything in sector_catalog)
		if(sector["id"] != id)
			continue
		var/list/levels = sector["levels"]
		var/requested_z = isnum(z) ? z : text2num("[z]")
		active_sector = id
		active_z = (requested_z in levels) ? requested_z : ((source_z in levels) ? source_z : levels[1])
		invalidate(FALSE)
		return TRUE
	return FALSE

/datum/netrun_map_view/proc/follow_source()
	active_sector = source_sector
	active_z = source_z
	invalidate(FALSE)

/datum/netrun_map_view/proc/rebuild(datum/netrun_topology/graph)
	events_need_reconcile = TRUE
	var/previous_revision = state_revision
	var/list/changed_nodes = list()
	var/list/changed_edges = list()
	var/list/removed_nodes = list()
	var/list/removed_edges = list()
	var/list/revealed = owner.route_reveal_addresses(owner.map_focus_node())
	revealed_addresses = revealed
	var/list/shown = list()
	var/list/networks = list()
	var/list/next_nodes = list()
	var/list/next_edges = list()
	var/list/map_nodes = list()
	var/list/permitted_nodes = list()
	var/list/sector_levels = list()
	var/list/map_edges = list()
	var/list/next_structure = list()
	var/list/next_static_nodes = list()
	var/list/next_static_edges = list()
	node_indexes = list()
	incident_edges = list()
	shown_network_counts = list()
	projected_network_levels = list()
	projected_network_keys = list()
	var/reveal_all = owner.daemon_capability("reveal_nodes")
	projected_mapper = reveal_all
	for(var/address in graph.nodes)
		var/datum/component/netrun_node/node = graph.nodes[address]
		if(QDELETED(node) || !owner.can_route(node) || (!reveal_all && !(address in revealed) && !owner.node_visible(node)))
			continue
		var/list/entry = project_entry(node, length(graph.neighbors(address)))
		if(netrun_snapshot_equal(node_entries[address], entry))
			entry = node_entries[address]
		next_nodes[address] = entry
		permitted_nodes[address] = entry
		if(node.network && isnull(projected_network_levels[node.network.id]))
			projected_network_levels[node.network.id] = owner.network_level(node.network)
			projected_network_keys[node.network.id] = owner.has_key(node.network)
		if(entry["sector"] && entry["z"])
			var/list/levels = sector_levels[entry["sector"]]
			if(!levels)
				levels = list()
				sector_levels[entry["sector"]] = levels
			levels |= entry["z"]
	sector_catalog = list()
	for(var/id in sort_list(sector_levels.Copy()))
		var/list/levels = sector_levels[id]
		sortTim(levels, GLOBAL_PROC_REF(cmp_numeric_asc))
		var/datum/space_level/level = SSmapping.z_list[levels[1]]
		sector_catalog += list(list("id" = id, "name" = level?.name || "Сектор [levels[1]]", "levels" = levels))
	if(!sector_levels[active_sector] && length(sector_catalog))
		var/list/first = sector_catalog[1]
		active_sector = first["id"]
		var/list/levels = first["levels"]
		active_z = levels[1]
	var/list/active_levels = sector_levels[active_sector]
	if(length(active_levels) && !(active_z in active_levels))
		active_z = active_levels[1]
	for(var/address in permitted_nodes)
		var/list/entry = permitted_nodes[address]
		if(entry["sector"] != active_sector || entry["z"] != active_z)
			continue
		map_nodes += list(entry)
		if(!shown_addresses[address] || node_entries[address] != entry)
			changed_nodes += list(entry)
		node_indexes[address] = length(map_nodes)
		incident_edges[address] = list()
		shown[address] = TRUE
		next_structure[address] = structure_entry(entry)
		if(!entry["dynamic"])
			next_static_nodes[address] = static_entry(entry)
		var/datum/component/netrun_node/node = graph.nodes[address]
		if(node.network)
			networks[node.network.id] = node.network
			shown_network_counts[node.network.id]++
	var/list/edge_structure = list()
	for(var/list/edge as anything in graph.edges)
		if(!shown[edge["from"]] || !shown[edge["to"]])
			continue
		var/list/entry = edge.Copy()
		entry["online"] = netrun_link_available(graph.nodes[edge["from"]], graph.nodes[edge["to"]])
		if(netrun_snapshot_equal(edge_entries[edge["id"]], entry))
			entry = edge_entries[edge["id"]]
		next_edges[edge["id"]] = entry
		if(edge_entries[edge["id"]] != entry)
			changed_edges += list(entry)
		map_edges += list(entry)
		var/list/from_edges = incident_edges[edge["from"]]
		var/list/to_edges = incident_edges[edge["to"]]
		from_edges += length(map_edges)
		to_edges += length(map_edges)
		if(!next_nodes[edge["from"]]["dynamic"] && !next_nodes[edge["to"]]["dynamic"])
			next_static_edges[edge["id"]] = entry.Copy()
		edge_structure += edge["id"]
	var/list/gateways = list()
	for(var/network_id in networks)
		var/datum/netrun_network/network = networks[network_id]
		var/level = owner.network_level(network)
		gateways += list(list("id" = network.id, "code" = network.code, "name" = network.name,
			"color" = network.color, "security" = network.security, "access" = level,
			"has_key" = owner.has_key(network), "can_breach" = owner.intrusion.can_breach && level < NETRUN_ACCESS_GUEST))
	var/list/apc_zones = list()
	var/datum/component/netrun_node/selected = owner.selected_node()
	if(selected?.node_type == NETRUN_NODE_APC && shown[selected.address])
		var/list/zone = geometry.apc_zone(selected, active_z)
		if(zone)
			apc_zones += list(zone)
	var/list/destinations = relay_destinations(graph, selected, shown, permitted_nodes)
	var/list/new_structure = list(active_sector, active_z, next_structure, edge_structure)
	var/list/new_static = list(next_static_nodes, next_static_edges, apc_zones)
	if(!netrun_snapshot_equal(static_structure, new_static))
		static_revision++
	static_structure = new_static
	if(!netrun_snapshot_equal(structure, new_structure))
		structure_revision++
	if(!snapshot || !netrun_snapshot_equal(snapshot["nodes"], map_nodes) || !netrun_snapshot_equal(snapshot["edges"], map_edges) || !netrun_snapshot_equal(snapshot["gateways"], gateways) || !netrun_snapshot_equal(snapshot["sectors"], sector_catalog) || !netrun_snapshot_equal(snapshot["apc_zones"], apc_zones) || !netrun_snapshot_equal(snapshot["relay_destinations"], destinations))
		state_revision++
	structure = new_structure
	for(var/address in shown_addresses)
		if(!shown[address])
			removed_nodes += address
	for(var/id in edge_entries)
		if(!next_edges[id])
			removed_edges += id
	node_entries = next_nodes
	edge_entries = next_edges
	shown_addresses = shown
	snapshot = list("nodes" = map_nodes, "edges" = map_edges, "gateways" = gateways,
		"revision" = graph.revision, "structure_revision" = structure_revision, "state_revision" = state_revision, "static_revision" = static_revision,
		"source_sector" = source_sector, "source_z" = source_z, "active_sector" = active_sector, "active_z" = active_z,
		"sectors" = sector_catalog, "apc_zones" = apc_zones, "relay_destinations" = destinations)
	record_wire_delta(previous_revision, changed_nodes, changed_edges, removed_nodes, removed_edges)
	dirty = FALSE
	structure_dirty = FALSE
	dirty_nodes.Cut()
	refreshed_at = world.time

/// Only O(changed nodes + their incident edges) work for a live map update.
/datum/netrun_map_view/proc/apply_incremental(datum/netrun_topology/graph)
	if(!reconcile_visibility_batch(graph))
		rebuild(graph)
		return
	var/previous_revision = state_revision
	var/list/node_updates = list()
	var/list/edge_updates = list()
	var/list/map_nodes = snapshot["nodes"]
	var/list/map_edges = snapshot["edges"]
	var/list/paint_nodes = static_structure[1]
	var/list/paint_edges = static_structure[2]
	var/list/structural_nodes = structure[3]
	var/bumped = FALSE
	var/static_changed = FALSE
	var/geometry_changed = FALSE
	var/list/changed_edges = list()
	var/list/prepared = list()
	var/list/rewired_edges = list()
	var/list/removed_edge_ids = list()
	var/list/network_changes = list()
	// Preflight visibility before mutating the retained snapshot: a late full rebuild must
	// not lose earlier changes from the same batch or publish a partially updated baseline.
	for(var/address in dirty_nodes)
		var/list/previous = node_entries[address]
		var/index = node_indexes[address]
		var/datum/component/netrun_node/node = graph.nodes[address]
		if(QDELETED(node))
			continue
		var/turf/position = node.observe_location()
		// Known offscreen nodes still contribute to the sector catalog. A move
		// across floors/LANs must revoke that catalog, even while another floor is viewed.
		if(previous && !index && (previous["sector"] != node.last_known_sector || previous["z"] != position?.z || previous["network"] != node.last_known_network))
			rebuild(graph)
			return
		var/now_shown = node.last_known_sector == active_sector && position?.z == active_z && owner.can_route(node) && (owner.daemon_capability("reveal_nodes") || (address in revealed_addresses) || owner.node_visible(node))
		// Floor changes and a personal endpoint changing owner can change visibility
		// without changing its APC attachment. Ordinary same-floor motion stays local.
		if(!!index != !!now_shown)
			rebuild(graph)
			return
		if(!previous || !index)
			continue
		var/list/entry = project_entry(node, previous["neighbor_count"])
		// Anchoring/unanchoring transfers a marker between canvas and DOM layers.
		if(previous["dynamic"] != entry["dynamic"])
			rebuild(graph)
			return
		// Retain gateways only while both LANs remain represented in this view.
		// Permission/visibility changes were checked above; source grants are checked in payload().
		if(previous["network"] != entry["network"] && (shown_network_counts[previous["network"]] <= 1 || !shown_network_counts[entry["network"]]))
			rebuild(graph)
			return
		if(previous["network"] != entry["network"])
			network_changes[previous["network"]]--
			network_changes[entry["network"]]++
		if(previous["uplink"] != entry["uplink"])
			var/list/incident = incident_edges[address]
			var/list/neighbors = graph.adjacency[address]
			if(length(incident) != 1 || length(neighbors) != 1 || neighbors[1] != entry["uplink"] || !shown_addresses[entry["uplink"]])
				rebuild(graph)
				return
			var/index_old = incident[1]
			var/list/old_edge = map_edges[index_old]
			var/list/new_edge = graph.edge_between(address, entry["uplink"])
			if(!old_edge || !new_edge || (old_edge["from"] != address && old_edge["to"] != address))
				rebuild(graph)
				return
			var/old_parent = old_edge["from"] == address ? old_edge["to"] : old_edge["from"]
			rewired_edges[address] = list("index" = index_old, "old_parent" = old_parent, "new_parent" = entry["uplink"], "edge" = new_edge)
		prepared[address] = entry
	// Several coalesced moves can remove a LAN's last visible markers together.
	for(var/network_id in network_changes)
		if(shown_network_counts[network_id] + network_changes[network_id] <= 0)
			rebuild(graph)
			return
	for(var/address in prepared)
		var/list/previous = node_entries[address]
		var/list/entry = prepared[address]
		var/index = node_indexes[address]
		if(netrun_snapshot_equal(previous, entry))
			continue
		if(previous["network"] != entry["network"])
			shown_network_counts[previous["network"]]--
			shown_network_counts[entry["network"]]++
		map_nodes[index] = entry
		node_entries[address] = entry
		node_updates += list(entry)
		bumped = TRUE
		var/list/node_structure = structure_entry(entry)
		if(!netrun_snapshot_equal(structural_nodes[address], node_structure))
			structural_nodes[address] = node_structure
			geometry_changed = TRUE
		if(!entry["dynamic"])
			var/list/paint_entry = static_entry(entry)
			if(!netrun_snapshot_equal(paint_nodes[address], paint_entry))
				paint_nodes[address] = paint_entry
				static_changed = TRUE
		for(var/edge_index in incident_edges[address])
			changed_edges["[edge_index]"] = edge_index
	// Swap the retained edge in place so all other edges keep their client indices.
	// The wire journal emits one removal and one upsert, not a full graph payload.
	for(var/address in rewired_edges)
		var/list/rewire = rewired_edges[address]
		var/index = rewire["index"]
		var/list/previous_edge = map_edges[index]
		var/list/rewired_edge = rewire["edge"]
		var/list/entry = rewired_edge.Copy()
		entry["online"] = netrun_link_available(graph.nodes[entry["from"]], graph.nodes[entry["to"]])
		var/old_id = previous_edge["id"]
		var/new_id = entry["id"]
		map_edges[index] = entry
		edge_entries -= old_id
		edge_entries[new_id] = entry
		structure[4][index] = new_id
		var/list/old_incident = incident_edges[rewire["old_parent"]]
		old_incident -= index
		var/list/new_incident = incident_edges[rewire["new_parent"]]
		new_incident += index
		if(paint_edges[old_id])
			paint_edges -= old_id
			paint_edges[new_id] = entry.Copy()
			static_changed = TRUE
		removed_edge_ids += old_id
		edge_updates += list(entry)
		geometry_changed = TRUE
		bumped = TRUE
	for(var/key in changed_edges)
		var/index = changed_edges[key]
		var/list/previous = map_edges[index]
		var/list/current_edge = graph.edge_between(previous["from"], previous["to"])
		if(!current_edge)
			rebuild(graph)
			return
		var/list/entry = current_edge.Copy()
		entry["online"] = netrun_link_available(graph.nodes[entry["from"]], graph.nodes[entry["to"]])
		if(netrun_snapshot_equal(previous, entry))
			continue
		map_edges[index] = entry
		edge_entries[entry["id"]] = entry
		edge_updates += list(entry)
		bumped = TRUE
		if(paint_edges[entry["id"]])
			paint_edges[entry["id"]] = entry.Copy()
			static_changed = TRUE
	dirty_nodes.Cut()
	if(bumped)
		snapshot["state_revision"] = ++state_revision
	if(geometry_changed)
		snapshot["structure_revision"] = ++structure_revision
	if(static_changed)
		snapshot["static_revision"] = ++static_revision
	record_wire_delta(previous_revision, node_updates, edge_updates, list(), removed_edge_ids)

/// Apply all newly visible/hidden leaves together. This scans the retained arrays
/// once even when a whole LAN changes permissions; unchanged node entries are reused.
/datum/netrun_map_view/proc/reconcile_visibility_batch(datum/netrun_topology/graph)
	var/list/added = list()
	var/list/removed = list()
	var/list/network_changes = list()
	var/reveal_all = owner.daemon_capability("reveal_nodes")
	for(var/address in dirty_nodes)
		var/datum/component/netrun_node/node = graph.nodes[address]
		if(QDELETED(node))
			continue
		var/list/previous = node_entries[address]
		var/index = node_indexes[address]
		var/turf/position = node.observe_location()
		var/permitted = owner.can_route(node) && (reveal_all || (address in revealed_addresses) || owner.node_visible(node))
		if(node.last_known_sector != active_sector || position?.z != active_z)
			// Other floors contribute to the sector catalog and relay chooser.
			if(!!previous != !!permitted)
				return FALSE
			continue
		if(!!index == !!permitted)
			continue
		var/list/neighbors = graph.adjacency[address]
		if(!node.network || length(neighbors) != 1 || !shown_addresses[neighbors[1]])
			return FALSE
		var/network_id = node.network.id
		if(!shown_network_counts[network_id])
			return FALSE
		if(permitted)
			if(!graph.edge_between(address, neighbors[1]))
				return FALSE
			added[address] = node
			network_changes[network_id]++
		else
			var/list/incident = incident_edges[address]
			if(length(incident) != 1)
				return FALSE
			removed[address] = node
			network_changes[network_id]--
	for(var/network_id in network_changes)
		if(shown_network_counts[network_id] + network_changes[network_id] <= 0)
			return FALSE
	if(!length(added) && !length(removed))
		return TRUE
	var/list/old_nodes = snapshot["nodes"]
	var/list/old_edges = snapshot["edges"]
	var/list/next_nodes = list()
	var/list/next_edges = list()
	var/list/edge_ids = list()
	var/list/node_updates = list()
	var/list/edge_updates = list()
	var/list/removed_nodes = list()
	var/list/removed_edges = list()
	var/list/paint_nodes = static_structure[1]
	var/list/paint_edges = static_structure[2]
	var/list/structural_nodes = structure[3]
	var/static_changed = FALSE
	for(var/list/entry as anything in old_nodes)
		var/address = entry["address"]
		if(!removed[address])
			next_nodes += list(entry)
			continue
		node_entries -= address
		shown_addresses -= address
		structural_nodes -= address
		if(paint_nodes[address])
			paint_nodes -= address
			static_changed = TRUE
		removed_nodes += address
		dirty_nodes -= address
	for(var/list/edge as anything in old_edges)
		var/id = edge["id"]
		if(removed[edge["from"]] || removed[edge["to"]])
			edge_entries -= id
			if(paint_edges[id])
				paint_edges -= id
				static_changed = TRUE
			removed_edges += id
			continue
		next_edges += list(edge)
		edge_ids += id
	for(var/address in added)
		var/datum/component/netrun_node/node = added[address]
		var/list/neighbors = graph.adjacency[address]
		var/list/entry = project_entry(node, length(neighbors))
		var/list/edge = graph.edge_between(address, neighbors[1]).Copy()
		edge["online"] = netrun_link_available(graph.nodes[edge["from"]], graph.nodes[edge["to"]])
		next_nodes += list(entry)
		next_edges += list(edge)
		edge_ids += edge["id"]
		node_entries[address] = entry
		shown_addresses[address] = TRUE
		structural_nodes[address] = structure_entry(entry)
		edge_entries[edge["id"]] = edge
		if(!entry["dynamic"])
			paint_nodes[address] = static_entry(entry)
			static_changed = TRUE
			if(!node_entries[neighbors[1]]["dynamic"])
				paint_edges[edge["id"]] = edge.Copy()
		node_updates += list(entry)
		edge_updates += list(edge)
		dirty_nodes -= address
	for(var/network_id in network_changes)
		shown_network_counts[network_id] += network_changes[network_id]
	node_indexes = list()
	incident_edges = list()
	for(var/i in 1 to length(next_nodes))
		var/list/entry = next_nodes[i]
		var/address = entry["address"]
		node_indexes[address] = i
		incident_edges[address] = list()
	for(var/i in 1 to length(next_edges))
		var/list/edge = next_edges[i]
		var/list/from_edges = incident_edges[edge["from"]]
		var/list/to_edges = incident_edges[edge["to"]]
		from_edges += i
		to_edges += i
	snapshot["nodes"] = next_nodes
	snapshot["edges"] = next_edges
	structure[4] = edge_ids
	var/previous_revision = state_revision
	snapshot["state_revision"] = ++state_revision
	snapshot["structure_revision"] = ++structure_revision
	if(static_changed)
		snapshot["static_revision"] = ++static_revision
	record_wire_delta(previous_revision, node_updates, edge_updates, removed_nodes, removed_edges)
	return TRUE

/// One serialization seam makes incremental work measurable without constructing fake topology.
/datum/netrun_map_view/proc/project_entry(datum/component/netrun_node/node, neighbor_count)
	var/list/entry = node.ui_entry(owner)
	entry["network"] = node.last_known_network
	entry["sector"] = node.last_known_sector
	entry["neighbor_count"] = neighbor_count
	return entry

/datum/netrun_map_view/proc/structure_entry(list/entry)
	return list(entry["type"], entry["uplink"], entry["network"], entry["sector"], entry["x"], entry["y"], entry["z"], entry["dynamic"])

/// Transient occupants, activity, can_hop and selection belong to the live overlay.
/datum/netrun_map_view/proc/static_entry(list/entry)
	return list(entry["name"], entry["type"], entry["x"], entry["y"], entry["z"], entry["security"], entry["online"], entry["access"], entry["uplink"], entry["network"], entry["sector"])

/datum/netrun_map_view/proc/relay_destinations(datum/netrun_topology/graph, datum/component/netrun_node/selected, list/shown, list/permitted)
	. = list()
	if(!graph.is_relay(selected) || !shown[selected.address])
		return
	var/mob/camera/netrun_entity/entity = owner.origin == NETRUN_ORIGIN_ENTITY ? owner.host : null
	for(var/address in graph.relay_addresses)
		if(address == selected.address || !permitted[address])
			continue
		var/datum/component/netrun_node/target = graph.nodes[address]
		var/turf/position = target.physical_turf()
		var/online = netrun_link_available(selected, target)
		var/can_hop = entity && entity.host_node == selected && world.time >= entity.next_hop && !entity.is_stunned() && entity.can_enter(target, owner.ui_routes)
		var/reason
		if(!entity)
			reason = "Переход доступен сетевой сущности."
		else if(entity.host_node != selected)
			reason = "Сначала перейдите в выбранное реле."
		else if(!online)
			reason = "Нет связи между реле."
		else if(!can_hop)
			reason = "Нет доступа к реле назначения или переход ещё не готов."
		. += list(list("from" = selected.address, "to" = address, "name" = target.get_name(),
			"sector" = target.binding_sector, "z" = position?.z, "online" = online,
			"can_hop" = !!can_hop, "unavailable_reason" = reason))

/// Bounded immutable change batches are shared by viewers; no quiet poll walks map entries.
/datum/netrun_map_view/proc/record_wire_delta(previous_revision, list/nodes, list/edges, list/removed_nodes, list/removed_edges)
	if(state_revision == previous_revision)
		return
	var/count = length(nodes) + length(edges) + length(removed_nodes) + length(removed_edges)
	wire_journal += list(list("base_revision" = previous_revision, "state_revision" = state_revision,
		"nodes" = nodes, "edges" = edges, "removed_nodes" = removed_nodes, "removed_edges" = removed_edges, "count" = count))
	wire_journal_entries += count
	while(length(wire_journal) > 32 || wire_journal_entries > 4096)
		var/list/oldest = wire_journal[1]
		wire_journal_entries -= oldest["count"]
		wire_journal.Cut(1, 2)

/// A UI is identified by its actual source, including the containing NTOS program.
/// The first registered poll binds the provisional opening snapshot without resending it.
/datum/netrun_map_view/proc/wire_session(mob/user, datum/ui_source, datum/tgui/ui)
	var/key = "[REF(user)]:[REF(ui_source)]"
	var/list/session = wire_sessions[key]
	var/ui_reference = ui ? REF(ui) : null
	if(!session || !ui || (session["ui"] && session["ui"] != ui_reference))
		session = list("id" = ++wire_session_id, "ui" = ui_reference)
		wire_sessions[key] = session
	else if(!session["ui"])
		session["ui"] = ui_reference
	session["seen"] = world.time
	// The session map is read on every poll, but full expiry scans are periodic.
	if(world.time >= wire_cleanup_at)
		wire_cleanup_at = world.time + 1 MINUTES
		SSnetrun.wire_session_sweeps++
		for(var/stale_key in wire_sessions)
			var/list/stale = wire_sessions[stale_key]
			if(world.time > stale["seen"] + 5 MINUTES)
				wire_sessions -= stale_key
	return session

/datum/netrun_map_view/proc/wire_payload(mob/user, datum/ui_source, list/session)
	var/list/full = payload()
	if(!user)
		return full
	ui_source = ui_source || owner
	var/datum/tgui/ui = SStgui.get_open_ui(user, ui_source)
	return encode_wire(full, session ? session : wire_session(user, ui_source, ui))

/// A refresh or skipped delivery cannot silently merge a patch into the wrong baseline.
/// The frontend requests resync through its validated UI action when it detects that case.
/datum/netrun_map_view/proc/resync(datum/tgui/ui)
	if(!ui?.user || !ui.src_object)
		return
	var/key = "[REF(ui.user)]:[REF(ui.src_object)]"
	var/list/session = wire_sessions[key]
	if(!session)
		session = list("id" = ++wire_session_id, "ui" = REF(ui))
		wire_sessions[key] = session
	// Sending a snapshot does not prove TGUI delivered it. Keep this viewer
	// on full snapshots until its frontend explicitly acknowledges the epoch.
	if(session["force_full"])
		// Retries belong to the same recovery stream; restarting its epoch would
		// invalidate in-flight receipts while the station keeps changing.
		owner?.invalidate_ui()
		return
	session["force_full"] = TRUE
	session["revision"] = null
	session["projection_epoch"] = null
	session["full_revisions"] = list()
	owner?.invalidate_ui()

/// Acknowledge a full snapshot only from the UI that owns the wire cursor.
/// A delayed receipt for an older epoch/revision must never unlock a new stream.
/datum/netrun_map_view/proc/ack_full(datum/tgui/ui, epoch, revision)
	if(!ui?.user || !ui.src_object || !istext(epoch))
		return FALSE
	// TGUI action transports may encode a numeric revision as text.
	var/confirmed_revision = isnum(revision) ? revision : (istext(revision) ? text2num(revision) : null)
	if(isnull(confirmed_revision))
		return FALSE
	var/key = "[REF(ui.user)]:[REF(ui.src_object)]"
	var/list/session = wire_sessions[key]
	var/list/sent_revisions = session?["full_revisions"]
	if(!session || !session["force_full"] || session["epoch"] != epoch || !(confirmed_revision in sent_revisions))
		return FALSE
	session["force_full"] = FALSE
	// A newer snapshot may already be in flight. Resume from the baseline this
	// viewer actually confirmed and compose all later changes from the journal.
	session["revision"] = confirmed_revision
	session["full_revisions"] = null
	for(var/metadata_key in list("gateways", "sectors", "apc_zones"))
		session[metadata_key] = null
	return TRUE

/datum/netrun_map_view/proc/encode_wire(list/full, list/session)
	// A restored operator can have an older projection than the most recently
	// rendered viewer. Give each newly bound UI a monotonic stream generation so
	// reusing a browser window cannot mistake that valid baseline for a late packet.
	if(isnull(session["projection_epoch"]) || session["projection_epoch"] != wire_epoch)
		session["projection_epoch"] = wire_epoch
		session["stream_generation"] = ++projection_generation
		session["full_revisions"] = list()
	var/epoch = "[REF(src)]:[session["stream_generation"]]:[session["id"]]"
	var/previous = session["revision"]
	var/list/result = full.Copy()
	var/list/node_updates = list()
	var/list/edge_updates = list()
	var/list/removed_nodes = list()
	var/list/removed_edges = list()
	var/send_full = !!session["force_full"] || isnull(previous) || session["epoch"] != epoch || previous > state_revision
	if(!send_full && previous != state_revision)
		var/cursor = previous
		for(var/list/batch as anything in wire_journal)
			if(batch["state_revision"] <= previous)
				continue
			if(batch["base_revision"] != cursor)
				break
			for(var/address in batch["removed_nodes"])
				node_updates -= address
				removed_nodes[address] = TRUE
			for(var/id in batch["removed_edges"])
				edge_updates -= id
				removed_edges[id] = TRUE
			for(var/list/entry as anything in batch["nodes"])
				node_updates[entry["address"]] = entry
				removed_nodes -= entry["address"]
			for(var/list/entry as anything in batch["edges"])
				edge_updates[entry["id"]] = entry
				removed_edges -= entry["id"]
			cursor = batch["state_revision"]
		send_full = cursor != state_revision
	result["epoch"] = epoch
	result["full"] = send_full
	if(send_full && session["force_full"])
		var/list/sent_revisions = session["full_revisions"]
		if(!islist(sent_revisions))
			sent_revisions = list()
			session["full_revisions"] = sent_revisions
		if(!(state_revision in sent_revisions))
			sent_revisions += state_revision
			if(length(sent_revisions) > 32)
				sent_revisions.Cut(1, 2)
	if(!send_full)
		result["base_revision"] = previous
		// Selected APC shapes and sector catalogs can be large despite being immutable.
		// Omit unchanged metadata rather than re-encoding their tiles every poll.
		for(var/key in list("gateways", "sectors", "apc_zones"))
			if(session[key] == full[key])
				result -= key
		result["nodes"] = list()
		result["edges"] = list()
		var/list/wire_nodes = result["nodes"]
		var/list/wire_edges = result["edges"]
		for(var/address in node_updates)
			wire_nodes += list(node_updates[address])
		for(var/id in edge_updates)
			wire_edges += list(edge_updates[id])
		// Associative keys are emitted as arrays, never as address=>TRUE objects.
		result["removed_nodes"] = list()
		result["removed_edges"] = list()
		var/list/wire_removed_nodes = result["removed_nodes"]
		var/list/wire_removed_edges = result["removed_edges"]
		for(var/address in removed_nodes)
			wire_removed_nodes += address
		for(var/id in removed_edges)
			wire_removed_edges += id
	session["epoch"] = epoch
	session["revision"] = state_revision
	for(var/key in list("gateways", "sectors", "apc_zones"))
		session[key] = full[key]
	return result

/// Compare wire data without serializing the whole graph into another JSON string.
/proc/netrun_snapshot_equal(first, second)
	// Retained projections deliberately reuse unchanged entries. A shared immutable
	// list is already equal; descending through it multiplies work by map size.
	if(first == second)
		return TRUE
	if(islist(first) && islist(second))
		var/list/left = first
		var/list/right = second
		if(length(left) != length(right))
			return FALSE
		for(var/i in 1 to length(left))
			var/key = left[i]
			if(!netrun_snapshot_equal(key, right[i]))
				return FALSE
			if(istext(key) && !netrun_snapshot_equal(left[key], right[key]))
				return FALSE
		return TRUE
	return first == second
