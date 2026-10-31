/// This cache owns its paths; only route() exposes mutable request-owned copies.
/datum/netrun_machine_path
	parent_type = /datum/netrun_route
	var/datum/weakref/graph_ref
	var/geometry_revision
	var/transit_revision
	var/from_anchor
	var/to_anchor
	var/prefix_cost
	var/suffix_cost

/datum/netrun_machine_transport/proc/clear_pair_routes()
	for(var/key in pair_routes)
		qdel(pair_routes[key])
	pair_routes.Cut()
	pair_used.Cut()
	pair_previous.Cut()
	pair_next.Cut()
	pair_oldest = null
	pair_newest = null

/// Pair capacity is large enough for a station poll, so eviction must not scan it.
/datum/netrun_machine_transport/proc/unlink_pair_route(key)
	var/previous = pair_previous[key]
	var/next = pair_next[key]
	if(previous)
		pair_next[previous] = next
	else if(pair_oldest == key)
		pair_oldest = next
	if(next)
		pair_previous[next] = previous
	else if(pair_newest == key)
		pair_newest = previous
	pair_previous -= key
	pair_next -= key

/// Link an admitted, detached key at the MRU end. New entries need no unlink.
/datum/netrun_machine_transport/proc/append_pair_route(key)
	pair_previous[key] = pair_newest
	pair_next[key] = null
	if(pair_newest)
		pair_next[pair_newest] = key
	else
		pair_oldest = key
	pair_newest = key

/datum/netrun_machine_transport/proc/touch_pair_route(key)
	pair_used[key] = ++pair_serial
	if(pair_newest == key)
		return
	unlink_pair_route(key)
	append_pair_route(key)

/datum/netrun_machine_transport/proc/forget_pair_route(key)
	var/datum/netrun_machine_path/path = pair_routes[key]
	if(!path)
		return
	unlink_pair_route(key)
	qdel(path)
	pair_routes -= key
	pair_used -= key

/datum/netrun_machine_transport/proc/store_pair_route(key, datum/netrun_machine_path/path)
	var/limit = max(1, CEILING(route_cache_limit, 1))
	var/datum/netrun_machine_path/previous = pair_routes[key]
	if(previous)
		// Replace the owned value in place; only a real LRU move changes links.
		pair_routes[key] = path
		if(previous != path)
			qdel(previous)
		touch_pair_route(key)
		// Live tuning can shrink a cache even when this is only a replacement.
		while(length(pair_routes) > limit)
			forget_pair_route(pair_oldest)
		return
	while(length(pair_routes) >= limit)
		forget_pair_route(pair_oldest)
	pair_routes[key] = path
	pair_used[key] = ++pair_serial
	append_pair_route(key)

/// Transport borrows the graph's physical cache and retains only its solve diagnostic.
/datum/netrun_machine_transport/proc/path_tree(datum/netrun_topology/graph, datum/component/netrun_node/root, availability_reconciled = FALSE)
	var/builds_before = graph.infrastructure_tree_builds
	var/datum/netrun_path_tree/tree = graph.borrow_infrastructure_tree(root, availability_reconciled)
	tree_builds += graph.infrastructure_tree_builds - builds_before
	return tree

/// Return a mutable request-owned route; boolean checks borrow cached paths directly.
/datum/netrun_machine_transport/proc/route(datum/netrun_machine_service/source, datum/netrun_machine_service/recipient, communications, frequency)
	var/datum/netrun_machine_path/path = borrowed_path(source, recipient)
	if(isnull(communications))
		communications = netrun_communication_policy(source, recipient?.service_id)
	if(!path && communications)
		path = communication_path(source, recipient, frequency)
	if(!path)
		return null
	var/datum/netrun_route/result = new
	result.hops = path.hops.Copy()
	result.latency = path.latency
	return result

/// Only infrastructure participates in shortest-path solving. Endpoint attachment and
/// cable costs are checked separately, so unrelated leaf movement/power cannot flush it.
/datum/netrun_machine_transport/proc/borrowed_path(datum/netrun_machine_service/source, datum/netrun_machine_service/recipient)
	if(QDELETED(source) || QDELETED(recipient) || QDELETED(source.host) || QDELETED(recipient.host))
		return null
	var/datum/component/netrun_node/start = source.resolve_node()
	var/datum/component/netrun_node/finish = recipient.resolve_node()
	if(QDELETED(start) || QDELETED(finish) || !start.is_online() || (start != finish && !finish.is_online()))
		return null
	// Native movement/containment subscriptions already include every carrier.
	// A packet changes neither endpoint's attachment: reconcile only a queued
	// physical change or a new infrastructure generation, even during discovery.
	var/datum/netrun_topology/graph = SSnetrun.get_topology()
	var/recheck_endpoints = graph.dirty
	if(start.pending_physical_update || !start.binding_checked || start.binding_infra_revision != graph.infrastructure_revision)
		recheck_endpoints = TRUE
		start.join_network()
	if(start != finish && (finish.pending_physical_update || !finish.binding_checked || finish.binding_infra_revision != graph.infrastructure_revision))
		recheck_endpoints = TRUE
		finish.join_network()
	graph = SSnetrun.ensure_topology()
	if(graph.nodes[start.address] != start || graph.nodes[finish.address] != finish)
		return null
	var/previous_availability = graph.availability_revision
	graph.reconcile_availability()
	// Binding/reconciliation can publish native signals. Only those callbacks
	// require resampling endpoints; an unchanged warm lookup is one atomic read.
	if(recheck_endpoints || previous_availability != graph.availability_revision)
		if(!start.is_online() || (start != finish && !finish.is_online()))
			return null
	var/datum/component/netrun_node/root = start
	var/datum/component/netrun_node/destination = finish
	var/prefix_cost = 0
	var/suffix_cost = 0
	var/list/neighbors = graph.adjacency[start.address]
	if(start != finish && !graph.is_infrastructure(start) && length(neighbors) == 1)
		root = graph.nodes[neighbors[1]]
		// A non-infrastructure leaf cannot form a quantum transition. Its own
		// state was just sampled above, so only the attachment needs checking.
		if(QDELETED(root) || (root != start && root != finish && !root.is_online()))
			return null
		prefix_cost = graph.cached_edge_cost(start.address, root.address)
	neighbors = graph.adjacency[finish.address]
	if(start != finish && !graph.is_infrastructure(finish) && length(neighbors) == 1)
		destination = graph.nodes[neighbors[1]]
		if(QDELETED(destination) || (destination != root && destination != start && destination != finish && !destination.is_online()))
			return null
		suffix_cost = graph.cached_edge_cost(destination.address, finish.address)
	var/key = "[start.address]>[finish.address]"
	var/datum/netrun_machine_path/cached = pair_routes[key]
	if(cached && cached.graph_ref?.resolve() == graph && cached.geometry_revision == graph.infrastructure_revision && cached.transit_revision == graph.transit_availability_revision && cached.from_anchor == root.address && cached.to_anchor == destination.address && cached.prefix_cost == prefix_cost && cached.suffix_cost == suffix_cost)
		if(!length(cached.hops) || path_available(graph, cached.hops, start, finish, root, destination))
			touch_pair_route(key)
			path_cache_hits++
			return length(cached.hops) ? cached : null
		// Legacy native writes can change a forwarding node without its usual signal.
		// Reconcile only this failed path, then allow an alternate route immediately.
		reconcile_path(graph, cached.hops)
	var/datum/netrun_machine_path/result = new
	result.graph_ref = WEAKREF(graph)
	result.from_anchor = root.address
	result.to_anchor = destination.address
	result.prefix_cost = prefix_cost
	result.suffix_cost = suffix_cost
	path_builds++
	if(start == finish)
		result.hops = list(start.address)
	else
		var/datum/netrun_path_tree/tree
		if(root == destination)
			result.hops = list(root.address)
		else
			tree = path_tree(graph, root, TRUE)
			result.hops = tree.addresses_to(destination.address)
		if(length(result.hops))
			if(root != start)
				result.hops.Insert(1, start.address)
			if(destination != finish)
				result.hops += finish.address
			result.latency = prefix_cost + (tree ? tree.cost_to(destination.address) : 0) + suffix_cost
			if(!path_available(graph, result.hops))
				// Never cache a stale usable route. The next lookup rebuilds after the
				// discovered native availability change instead of extending its lifetime.
				reconcile_path(graph, result.hops)
				qdel(result)
				return null
	result.geometry_revision = graph.infrastructure_revision
	result.transit_revision = graph.transit_availability_revision
	store_pair_route(key, result)
	return length(result.hops) ? result : null

/datum/netrun_machine_transport/proc/path_available(datum/netrun_topology/graph, list/path, datum/component/netrun_node/checked_start, datum/component/netrun_node/checked_finish, datum/component/netrun_node/checked_root, datum/component/netrun_node/checked_destination)
	// Sample every host once. Checking both ends of every cable rechecks every
	// interior APC twice and each quantum relay's operational state several times.
	var/backbone_enabled = !SSnetworks.station_network.setting_disabled
	var/previous_relay = FALSE
	for(var/address in path)
		var/datum/component/netrun_node/node = graph.nodes[address]
		if(QDELETED(node))
			return FALSE
		// Warm pair lookup has already sampled both leaves and their anchors,
		// with no intervening callbacks. Never reuse these samples on the cold
		// solve path, which may publish a fresh availability generation.
		if(node != checked_start && node != checked_finish && node != checked_root && node != checked_destination && !node.is_online())
			return FALSE
		var/current_relay = istype(node.parent, /obj/machinery/ntnet_relay)
		// Relay netrun_online already includes its native is_operational check.
		if(previous_relay && current_relay && !backbone_enabled)
			return FALSE
		previous_relay = current_relay
	return TRUE

/datum/netrun_machine_transport/proc/reconcile_path(datum/netrun_topology/graph, list/path)
	for(var/address in path)
		var/datum/component/netrun_node/node = graph.nodes[address]
		if(QDELETED(node))
			continue
		var/online = node.is_online()
		if(node.last_online != online)
			node.last_online = online
			graph.availability_changed(node, online)
			node.notify_changed(NETRUN_CHANGED_STATE, FALSE, TRUE)


/datum/netrun_machine_transport/proc/reachable(datum/netrun_machine_service/source, datum/netrun_machine_service/recipient, communications)
	if(isnull(communications))
		communications = netrun_communication_policy(source, recipient?.service_id)
	return !!(borrowed_path(source, recipient) || (communications && communication_path(source, recipient)))

