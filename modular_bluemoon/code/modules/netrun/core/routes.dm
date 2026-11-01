/// Ping, requests and the map consume the same physical node graph.
/datum/netrun_route
	var/list/hops = list()
	var/latency = 0
	var/name = "нет маршрута"

/proc/netrun_quantum_link(datum/component/netrun_node/first, datum/component/netrun_node/second)
	return first != second && istype(first?.parent, /obj/machinery/ntnet_relay) && istype(second?.parent, /obj/machinery/ntnet_relay)

/// A local reboot never causes structural rebinding; only forwarding stops.
/proc/netrun_link_available(datum/component/netrun_node/first, datum/component/netrun_node/second, allow_offline_destination = FALSE)
	if(QDELETED(first) || QDELETED(second) || !first.is_online() || (!allow_offline_destination && !second.is_online()))
		return FALSE
	if(netrun_quantum_link(first, second))
		var/obj/machinery/ntnet_relay/from_relay = first.parent
		var/obj/machinery/ntnet_relay/to_relay = second.parent
		return !SSnetworks.station_network.setting_disabled && from_relay.is_operational() && to_relay.is_operational()
	return TRUE

/// Request-local weighted shortest paths. UI serialization shares one snapshot; later requests
/// revalidate live APC and relay availability instead of caching working routes.
/datum/netrun_path_tree
	/// Only the topology may release its retained tables. Synchronous readers borrow them.
	var/retained = FALSE
	var/datum/component/netrun_node/source
	var/revision = 0
	var/updated_at = 0
	var/list/reached = list()
	/// LAN id -> first reached witness address; live authority validates that path.
	var/list/reached_networks = list()
	var/network_index_ready = FALSE
	var/list/previous = list()
	var/list/costs = list()
	var/list/remote = list()
	var/geometry_revision = 0
	var/availability_revision = 0
	var/transit_availability_revision = 0
	var/source_online = FALSE
	var/infrastructure_only = FALSE
	var/datum/weakref/graph_ref
	/// Changing a source leaf cable shifts every non-self path equally. Keep that
	/// shared prefix separate until a request-owned copy materializes its costs.
	var/source_cost_offset = 0
	/// A flat binary heap avoids one disposable datum for every relaxed endpoint.
	var/list/frontier_addresses = list()
	var/list/frontier_costs = list()
	var/popped_cost = 0
	/// Number of heap candidates; terminal destinations must not add heap work.
	var/frontier_insertions = 0
	var/neighbor_visits = 0

/datum/netrun_path_tree/New(datum/netrun_topology/graph, datum/component/netrun_node/start, infrastructure_only = FALSE)
	source = start
	if(graph)
		graph_ref = WEAKREF(graph)
	src.infrastructure_only = infrastructure_only
	geometry_revision = (infrastructure_only ? graph?.infrastructure_revision : graph?.weight_revision) || 0
	availability_revision = graph?.availability_revision || 0
	transit_availability_revision = graph?.transit_availability_revision || 0
	source_online = !QDELETED(start) && start.is_online()
	if(QDELETED(start) || !graph.nodes[start.address])
		return
	var/list/settled = list()
	var/list/relay_states
	var/list/changed_availability
	var/relays_expanded = FALSE
	var/backbone_enabled = !SSnetworks.station_network.setting_disabled
	reached[start.address] = TRUE
	costs[start.address] = 0
	push_candidate(start.address, 0)
	while(length(frontier_addresses))
		var/address = pop_candidate()
		if(settled[address] || popped_cost != costs[address])
			continue
		settled[address] = TRUE
		var/datum/component/netrun_node/current = graph.nodes[address]
		if(current?.network && !reached_networks[current.network.id])
			reached_networks[current.network.id] = address
		if(QDELETED(current))
			continue
		var/current_relay = istype(current.parent, /obj/machinery/ntnet_relay)
		var/current_online = current == start ? source_online : current.is_online()
		// A cold solve already samples forwarders. Remember unsigned native
		// changes so negative trees can recover without another station scan.
		if((current.node_type == NETRUN_NODE_APC || current_relay || length(graph.adjacency[address]) > 1) && current_online != current.last_online)
			if(!changed_availability)
				changed_availability = list()
			changed_availability[current] = current_online
		// Offline destinations are leaves: they cannot forward traffic.
		if(!current_online)
			continue
		if(current_relay)
			if(!relay_states)
				relay_states = list()
			// netrun_online() on an actual relay already checked is_operational().
			relay_states[address] = TRUE
		var/current_cost = costs[address]
		var/current_remote = remote[address]
		var/list/neighbors = infrastructure_only ? graph.forwarding_neighbors(address) : graph.neighbors(address, FALSE)
		for(var/neighbor in neighbors)
			neighbor_visits++
			var/datum/component/netrun_node/next = graph.nodes[neighbor]
			if(settled[neighbor] || QDELETED(next) || QDELETED(next.parent))
				continue
			var/next_relay = istype(next.parent, /obj/machinery/ntnet_relay)
			// The source's live state is fixed for this synchronous solve and was
			// checked above. Physical cables allow offline destinations; only a
			// relay-to-relay transition adds a destination-operational requirement.
			if(current_relay && next_relay && (!backbone_enabled || !solve_relay_available(next, relay_states)))
				continue
			// Ordinary endpoints have exactly one cable and cannot be transit. Their
			// shortest path is final when this sole parent settles: skip a heap visit.
			var/transit = next.node_type == NETRUN_NODE_APC || next_relay || length(graph.adjacency[neighbor]) > 1
			if(infrastructure_only && !transit)
				continue
			relax(neighbor, address, current_cost + graph.cached_edge_cost(address, neighbor), current_remote, transit)
			if(!transit && next.network && !reached_networks[next.network.id])
				reached_networks[next.network.id] = neighbor
		// Every operational relay can reach every other relay at the same cost.
		// The cheapest settled entry expands this virtual bucket exactly once.
		if(relays_expanded || !current_relay || !backbone_enabled)
			continue
		relays_expanded = TRUE
		for(var/relay_address in graph.relay_addresses)
			if(relay_address == address || settled[relay_address])
				continue
			var/datum/component/netrun_node/next = graph.nodes[relay_address]
			if(QDELETED(next) || QDELETED(next.parent) || !solve_relay_available(next, relay_states))
				continue
			relax(relay_address, address, current_cost + NETRUN_RELAY_LATENCY, TRUE)
	frontier_addresses.Cut()
	frontier_costs.Cut()
	network_index_ready = TRUE
	// No callbacks run while Dijkstra is traversing mutable graph arrays. Record
	// all sampled state first, then publish checked lifecycle notifications. Any
	// callback's later change advances the graph beyond this tree's generation.
	for(var/datum/component/netrun_node/node as anything in changed_availability)
		if(QDELETED(node))
			continue
		node.last_online = changed_availability[node]
		graph.availability_changed(node, node.last_online)
	availability_revision = graph.availability_revision
	transit_availability_revision = graph.transit_availability_revision
	for(var/datum/component/netrun_node/node as anything in changed_availability)
		if(!QDELETED(node))
			node.notify_changed(NETRUN_CHANGED_STATE, FALSE, TRUE)

/// A solve never yields. Sample each remote relay's native state once within it,
/// while preserving discoverability of an operational relay with offline_until set.
/datum/netrun_path_tree/proc/solve_relay_available(datum/component/netrun_node/node, list/states)
	var/online = states[node.address]
	if(isnull(online))
		var/obj/machinery/ntnet_relay/relay = node.parent
		online = relay.is_operational()
		states[node.address] = online
	return online

/datum/netrun_path_tree/Destroy()
	source = null
	graph_ref = null
	reached.Cut()
	reached_networks.Cut()
	previous.Cut()
	costs.Cut()
	remote.Cut()
	frontier_addresses.Cut()
	frontier_costs.Cut()
	return ..()

/datum/netrun_path_tree/proc/relax(address, from_address, cost, quantum, enqueue = TRUE)
	if(!isnull(costs[address]) && costs[address] <= cost)
		return
	reached[address] = TRUE
	previous[address] = from_address
	costs[address] = cost
	remote[address] = quantum
	if(enqueue)
		push_candidate(address, cost)

/datum/netrun_path_tree/proc/frontier_before(first, second)
	if(frontier_costs[first] != frontier_costs[second])
		return frontier_costs[first] < frontier_costs[second]
	return sorttext(frontier_addresses[first], frontier_addresses[second]) == 1

/datum/netrun_path_tree/proc/push_candidate(address, cost)
	frontier_insertions++
	frontier_addresses += address
	frontier_costs += cost
	var/index = length(frontier_addresses)
	while(index > 1)
		var/parent_index = round(index / 2)
		if(!frontier_before(index, parent_index))
			break
		frontier_addresses.Swap(index, parent_index)
		frontier_costs.Swap(index, parent_index)
		index = parent_index

/datum/netrun_path_tree/proc/pop_candidate()
	. = frontier_addresses[1]
	popped_cost = frontier_costs[1]
	var/last = length(frontier_addresses)
	frontier_addresses[1] = frontier_addresses[last]
	frontier_costs[1] = frontier_costs[last]
	frontier_addresses.len--
	frontier_costs.len--
	var/index = 1
	while(index * 2 <= length(frontier_addresses))
		var/child = index * 2
		if(child < length(frontier_addresses) && frontier_before(child + 1, child))
			child++
		if(!frontier_before(child, index))
			break
		frontier_addresses.Swap(index, child)
		frontier_costs.Swap(index, child)
		index = child

/datum/netrun_path_tree/proc/addresses_to(address)
	var/list/path = list()
	if(!reached[address])
		return path
	while(address)
		path += address
		address = previous[address]
	reverseRange(path)
	return path

/// Costs in retained tables may carry a constant source-leaf prefix adjustment.
/datum/netrun_path_tree/proc/cost_to(address)
	if(isnull(costs[address]))
		return null
	return costs[address] + (address == source?.address ? 0 : source_cost_offset)

/// Return a request-owned copy, never the server's retained routing table.
/datum/netrun_path_tree/proc/copy()
	var/datum/netrun_path_tree/snapshot = new
	snapshot.source = source
	snapshot.revision = revision
	snapshot.updated_at = updated_at
	snapshot.reached = reached.Copy()
	snapshot.reached_networks = reached_networks.Copy()
	snapshot.network_index_ready = network_index_ready
	snapshot.previous = previous.Copy()
	snapshot.costs = costs.Copy()
	if(source_cost_offset)
		for(var/address in snapshot.costs)
			if(address != source?.address)
				snapshot.costs[address] += source_cost_offset
	snapshot.remote = remote.Copy()
	snapshot.geometry_revision = geometry_revision
	snapshot.availability_revision = availability_revision
	snapshot.transit_availability_revision = transit_availability_revision
	snapshot.source_online = source_online
	snapshot.infrastructure_only = infrastructure_only
	snapshot.graph_ref = graph_ref
	snapshot.frontier_insertions = frontier_insertions
	snapshot.neighbor_visits = neighbor_visits
	return snapshot

/// Only physical paths are retained. Permissions and command authorization
/// deliberately remain outside this cache and are evaluated for each request.
/datum/netrun_topology
	var/list/datum/netrun_path_tree/route_tables = list()
	var/list/route_used = list()
	var/route_revision = 0
	/// Deep snapshots are reserved for operations that can yield, never boolean reads.
	var/route_snapshot_copies = 0
	var/route_refresh_at = -INFINITY
	var/forwarding_checked_at = -INFINITY
	/// The physical graph alone owns reusable APC/forwarder trees. Consumers borrow.
	var/list/infrastructure_route_trees = list()
	var/list/infrastructure_route_used = list()
	var/infrastructure_route_limit = 512
	var/infrastructure_route_serial = 0
	var/infrastructure_tree_builds = 0

/datum/netrun_topology/proc/forget_infrastructure_route(address)
	qdel(infrastructure_route_trees[address])
	infrastructure_route_trees -= address
	infrastructure_route_used -= address

/datum/netrun_topology/proc/clear_infrastructure_routes()
	for(var/address in infrastructure_route_trees)
		qdel(infrastructure_route_trees[address])
	infrastructure_route_trees.Cut()
	infrastructure_route_used.Cut()

/datum/netrun_topology/proc/trim_infrastructure_routes(limit)
	while(length(infrastructure_route_trees) > limit)
		var/oldest
		for(var/address in infrastructure_route_trees)
			if(!oldest || infrastructure_route_used[address] < infrastructure_route_used[oldest])
				oldest = address
		forget_infrastructure_route(oldest)

/// Shared physical reachability contains no service registry, viewer or authority state.
/// Leaf attachment/cost changes are composed by callers and do not invalidate this tree.
/datum/netrun_topology/proc/borrow_infrastructure_tree(datum/component/netrun_node/root, availability_reconciled = FALSE)
	if(QDELETED(root) || nodes[root.address] != root)
		return null
	if(!availability_reconciled)
		reconcile_availability()
	var/limit = max(1, infrastructure_route_limit)
	var/datum/netrun_path_tree/tree = infrastructure_route_trees[root.address]
	if(!tree || tree.graph_ref?.resolve() != src || tree.source != root || tree.geometry_revision != infrastructure_revision || tree.transit_availability_revision != transit_availability_revision || tree.source_online != root.is_online())
		reconcile_availability()
		forget_infrastructure_route(root.address)
		trim_infrastructure_routes(limit - 1)
		tree = new(src, root, TRUE)
		infrastructure_route_trees[root.address] = tree
		infrastructure_tree_builds++
	infrastructure_route_used[root.address] = ++infrastructure_route_serial
	trim_infrastructure_routes(limit)
	return tree

/datum/netrun_topology/proc/clear_route_tables(release_sources = FALSE)
	for(var/address in route_tables)
		qdel(route_tables[address])
	route_tables.Cut()
	if(release_sources)
		route_used.Cut()
	route_refresh_at = -INFINITY

/// A deleted source cannot issue more reads. Release its full table immediately,
/// rather than keeping its node and every destination until the idle expiry poll.
/datum/netrun_topology/proc/forget_route_table(address)
	qdel(route_tables[address])
	route_tables -= address
	route_used -= address

/datum/netrun_topology/proc/store_route_table(datum/component/netrun_node/start)
	reconcile_availability()
	var/datum/netrun_path_tree/table = new(src, start)
	table.retained = TRUE
	table.revision = ++route_revision
	table.updated_at = world.time
	qdel(route_tables[start.address])
	route_tables[start.address] = table
	return table

/// Unsigned native relay toggles and backbone settings have no common change signal.
/// Their small infrastructure index is reconciled without walking the full graph.
/datum/netrun_topology/proc/reconcile_availability()
	SSnetrun.reconcile_dirty_availability()
	var/disabled = !!SSnetworks.station_network?.setting_disabled
	if(disabled != backbone_disabled)
		backbone_disabled = disabled
		availability_revision++
		transit_availability_revision++
	for(var/address in relay_addresses)
		var/datum/component/netrun_node/node = nodes[address]
		if(QDELETED(node))
			continue
		var/online = node.is_online()
		if(online != node.last_online)
			node.last_online = online
			availability_changed(node, online)
			node.notify_changed(NETRUN_CHANGED_STATE, FALSE, TRUE)
	// Positive paths and cold solves sample their actual forwarders. Only an
	// observed outage can leave a negative tree waiting for unsigned countdown
	// recovery, so poll that small set once per tick instead of every station APC.
	if(forwarding_checked_at != world.time)
		forwarding_checked_at = world.time
		for(var/address in unavailable_apcs)
			var/datum/component/netrun_node/node = unavailable_apcs[address]
			if(QDELETED(node) || registered_apcs[address] != node)
				unavailable_apcs -= address
				continue
			var/online = node.is_online()
			if(online)
				unavailable_apcs -= address
			if(online != node.last_online)
				node.last_online = online
				availability_changed(node, online)
				node.notify_changed(NETRUN_CHANGED_STATE, FALSE, TRUE)

/// Requests validate the selected predecessor chain without allocating a hop list.
/// Offline terminal destinations remain discoverable; intermediate nodes must forward.
/datum/netrun_path_tree/proc/path_available(datum/netrun_topology/graph, address)
	if(!reached[address] || QDELETED(source) || graph.nodes[source.address] != source)
		return FALSE
	var/destination = address
	var/datum/component/netrun_node/to_node = graph.nodes[address]
	if(QDELETED(to_node) || QDELETED(to_node.parent))
		return FALSE
	while(previous[address])
		var/parent_address = previous[address]
		var/datum/component/netrun_node/from_node = graph.nodes[parent_address]
		// Walking backwards samples every forwarder exactly once. The previous
		// iteration already checked to_node when it was the source of that edge.
		if(QDELETED(from_node))
			return FALSE
		if(!from_node.is_online())
			// A cached path may be the first observer of an unsigned native outage.
			// Remember it before returning, so negative trees can recover by index.
			if(from_node.last_online != FALSE)
				from_node.last_online = FALSE
				graph.availability_changed(from_node, FALSE)
				from_node.notify_changed(NETRUN_CHANGED_STATE, FALSE, TRUE)
			return FALSE
		var/quantum = netrun_quantum_link(from_node, to_node)
		if(!graph.edge_lookup["[parent_address]>[address]"] && !quantum)
			return FALSE
		if(quantum)
			if(SSnetworks.station_network.setting_disabled)
				return FALSE
			// Only the final destination can be offline. Its relay hardware must
			// still operate for a quantum transition, as in netrun_link_available.
			if(address == destination)
				var/obj/machinery/ntnet_relay/relay = to_node.parent
				if(!relay.is_operational())
					return FALSE
		address = parent_address
		to_node = from_node
	return address == source.address

/// A cached LAN marker is a hint, not authority. Usually one witness suffices;
/// only a failed witness needs to try other entrances to the same department.
/datum/netrun_path_tree/proc/network_available(datum/netrun_topology/graph, datum/netrun_network/network)
	var/address = reached_networks[network.id]
	if(network_index_ready && !address)
		return FALSE
	var/datum/component/netrun_node/witness = istext(address) ? graph.nodes[address] : null
	if(!QDELETED(witness) && witness.network == network && path_available(graph, address))
		return TRUE
	// A newly observed forwarding outage invalidates every predecessor chain.
	// Let the connection retry one fresh tree instead of repeating the same cut.
	if(transit_availability_revision != graph.transit_availability_revision)
		return FALSE
	for(var/datum/component/netrun_node/node as anything in network.nodes)
		if(node != witness && !QDELETED(node) && node.network == network && graph.nodes[node.address] == node && path_available(graph, node.address))
			return TRUE
	return FALSE

/// Geometry is already maintained by structural/movement signals. Reuse its cached
/// edge weights while solving a tree instead of measuring every cable again.
/datum/netrun_topology/proc/cached_edge_cost(first, second)
	var/list/edge = edge_lookup["[first]>[second]"]
	return edge ? edge["latency"] : edge_cost(first, second)

/// A source unused for two intervals expires. This housekeeping never solves a tree:
/// an invalidated table is rebuilt lazily only if its UI actually requests it.
/datum/netrun_topology/proc/refresh_route_tables(refresh_interval = NETRUN_DEFAULT_ROUTE_REFRESH_INTERVAL, expiry_interval = NETRUN_DEFAULT_ROUTE_EXPIRY_INTERVAL)
	if(world.time < route_refresh_at)
		return
	route_refresh_at = world.time + refresh_interval
	for(var/address in route_used.Copy())
		var/datum/component/netrun_node/start = nodes[address]
		if(QDELETED(start) || route_used[address] < world.time - expiry_interval)
			forget_route_table(address)
			continue

/// A degree-one endpoint cannot be transit for any other destination. Moving its
/// cable changes one destination cost, or a constant prefix if it is the source.
/// Repair valid retained trees in O(active sources), without running Dijkstra.
/datum/netrun_topology/proc/reweight_leaf_routes(address, parent_address, delta, previous_geometry)
	var/cost = cached_edge_cost(address, parent_address)
	for(var/source_address in route_tables)
		var/datum/netrun_path_tree/table = route_tables[source_address]
		if(table.geometry_revision != previous_geometry || table.transit_availability_revision != transit_availability_revision)
			continue
		if(table.source?.address == address)
			table.source_cost_offset += delta
		else if(table.reached[address] && table.previous[address] == parent_address)
			// Both values omit the same optional source prefix.
			table.costs[address] = table.costs[parent_address] + cost
		table.geometry_revision = weight_revision
		table.updated_at = world.time

/// Relocating a terminal leaf never changes an APC-to-APC path. Repair just
/// that terminal's predecessor in warm trees; the terminal's own source tree
/// is rebuilt lazily, because its entire root has actually changed.
/datum/netrun_topology/proc/rebind_leaf_route_tables(datum/component/netrun_node/node, previous_geometry)
	var/address = node.address
	var/list/neighbors = adjacency[address]
	var/parent_address = length(neighbors) == 1 ? neighbors[1] : null
	var/datum/component/netrun_node/parent = nodes[parent_address]
	var/connected = !QDELETED(parent) && netrun_link_available(parent, node, TRUE)
	var/edge_cost = connected ? cached_edge_cost(parent_address, address) : 0
	for(var/source_address in route_tables)
		var/datum/netrun_path_tree/table = route_tables[source_address]
		if(table.geometry_revision != previous_geometry || table.transit_availability_revision != transit_availability_revision)
			continue
		if(source_address == address)
			// Its APC changed, not just its cable length. Do not serve old source paths.
			continue
		if(connected && table.reached[parent_address])
			table.reached[address] = TRUE
			table.previous[address] = parent_address
			table.costs[address] = table.costs[parent_address] + edge_cost
			table.remote[address] = table.remote[parent_address]
			// The parent's LAN is already indexed. node.network still names its old
			// LAN until join_network finishes, so adding it would invent reachability.
		else
			table.reached -= address
			table.previous -= address
			table.costs -= address
			table.remote -= address
		table.geometry_revision = weight_revision
		table.updated_at = world.time

/// Borrowed snapshots must never be modified or qdel()ed by callers.
/datum/netrun_topology/proc/route_snapshot(datum/component/netrun_node/start, borrow = FALSE)
	reconcile_movement()
	if(dirty && !rebuilding)
		SSnetrun.ensure_topology()
	if(QDELETED(start) || nodes[start.address] != start)
		if(borrow)
			return null
		return new /datum/netrun_path_tree
	route_used[start.address] = world.time
	reconcile_availability()
	var/datum/netrun_execution_limits/limits = SSnetrun.get_execution_limits()
	refresh_route_tables(limits.route_refresh_interval, limits.route_expiry_interval)
	var/datum/netrun_path_tree/table = route_tables[start.address]
	if(!table || table.geometry_revision != weight_revision || table.transit_availability_revision != transit_availability_revision || table.source_online != start.is_online())
		table = store_route_table(start)
	if(borrow)
		return table
	route_snapshot_copies++
	return table.copy()

/datum/netrun_console/proc/route_source()
	RETURN_TYPE(/datum/component/netrun_node)
	return connection.route_source()

/datum/netrun_connection/proc/route_source()
	RETURN_TYPE(/datum/component/netrun_node)
	if(owner.ui_routes)
		return owner.ui_routes.source
	return owner.physical_route_source()

/datum/netrun_console/proc/physical_route_source()
	return connection.physical_route_source()

/datum/netrun_connection/proc/physical_route_source()
	if(jack && owner.jack_valid())
		return owner.refresh_route_node(jack)
	var/datum/component/netrun_node/source = owner.refresh_route_node(netrun_find_node(owner.host))
	if(source)
		return source
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	return graph.nearest_apc(owner.physical_turf())

/datum/netrun_console/entity/physical_route_source()
	var/mob/camera/netrun_entity/entity = host
	return refresh_route_node(entity?.host_node)

/// Nested items can cross an area with their carrier without receiving MOVED.
/datum/netrun_console/proc/refresh_route_node(datum/component/netrun_node/node)
	return connection.refresh_route_node(node)

/datum/netrun_connection/proc/refresh_route_node(datum/component/netrun_node/node)
	if(QDELETED(node) || QDELETED(node.parent))
		return null
	// ui_data is synchronous. Repeated visibility/access reads of the same node
	// share its completed binding instead of asking it to join the LAN each time.
	if(owner.ui_serializing && owner.ui_routes && ui_refreshed_nodes)
		if(ui_refreshed_nodes[node.address] == node && !node.pending_physical_update)
			return node
		ui_refreshed_nodes[node.address] = node
	var/datum/netrun_network/previous = node.network
	node.join_network()
	if(previous != node.network)
		owner.network_level_cache?.Cut()
	return node

/datum/netrun_console/proc/path_tree()
	return connection.path_tree()

/datum/netrun_connection/proc/path_tree()
	if(owner.ui_routes)
		return owner.ui_routes
	return owner.make_path_tree()

/// Read-only, synchronous queries may borrow physical paths. Never carry this tree
/// across sleep()/do_after(): explicit operations use make_path_tree() instead.
/datum/netrun_connection/proc/read_path_tree(fresh = FALSE)
	if(!fresh && owner.ui_routes)
		return owner.ui_routes
	var/datum/component/netrun_node/start = owner.physical_route_source()
	if(wireless_zone_restricted())
		return local_path_tree(start)
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	var/datum/netrun_path_tree/tree = graph.route_snapshot(start, TRUE)
	if(tree)
		return tree
	return new /datum/netrun_path_tree

/datum/netrun_connection/proc/wireless_zone_restricted()
	if(!wireless || owner.origin == NETRUN_ORIGIN_ENTITY || owner.jack_valid())
		return FALSE
	var/turf/here = owner.physical_turf()
	return !here || (!is_station_level(here.z) && !is_mining_level(here.z))

/// A restricted wireless session only knows its own endpoint. Do not solve/copy
/// the entire station graph merely to discard every remote address afterwards.
/datum/netrun_connection/proc/local_path_tree(datum/component/netrun_node/start)
	var/datum/netrun_path_tree/tree = new
	tree.source = start
	tree.network_index_ready = TRUE
	if(start && start == netrun_find_node(owner.host))
		tree.reached[start.address] = TRUE
		tree.costs[start.address] = 0
		if(start.network)
			tree.reached_networks[start.network.id] = start.address
	return tree

/// Explicit request trees are local variables, so concurrent yielding device
/// operations cannot borrow another request's path or an old UI snapshot.
/datum/netrun_console/proc/make_path_tree(use_stored_routes = TRUE)
	return connection.make_path_tree(use_stored_routes)

/datum/netrun_connection/proc/make_path_tree(use_stored_routes = TRUE)
	var/datum/component/netrun_node/start = owner.physical_route_source()
	if(wireless_zone_restricted())
		return local_path_tree(start)
	// A source can move its nested node while being resolved.
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	return use_stored_routes ? graph.route_snapshot(start) : new /datum/netrun_path_tree(graph, start)

/// The one UI snapshot per poll shares the server's retained routing table directly when no
/// request-local restriction (the wireless-zone cut) can mutate it. Borrowing avoids copying
/// the whole reached/cost tree on every poll; the pass marks it so teardown never qdel()s it.
/datum/netrun_console/proc/acquire_ui_routes()
	return connection.acquire_ui_routes()

/datum/netrun_connection/proc/acquire_ui_routes()
	ui_refreshed_nodes = list()
	var/datum/netrun_path_tree/tree = read_path_tree(TRUE)
	owner.ui_routes_borrowed = tree.retained
	return tree

/datum/netrun_console/proc/release_path_tree(datum/netrun_path_tree/tree)
	return connection.release_path_tree(tree)

/datum/netrun_connection/proc/release_path_tree(datum/netrun_path_tree/tree)
	if(tree != owner.ui_routes && !tree?.retained)
		qdel(tree)

/datum/netrun_console/proc/route_to(datum/component/netrun_node/node, datum/netrun_path_tree/tree)
	return connection.route_to(node, tree)

/datum/netrun_connection/proc/route_to(datum/component/netrun_node/node, datum/netrun_path_tree/tree)
	var/datum/netrun_route/route = new
	node = owner.refresh_route_node(node)
	if(!node)
		return route
	var/owns_tree = !tree
	if(owns_tree)
		tree = read_path_tree()
	var/list/addresses = tree.addresses_to(node.address)
	if(!length(addresses))
		route.latency = 3
		if(owns_tree)
			owner.release_path_tree(tree)
		return route
	for(var/address in addresses)
		route.hops += list(list("kind" = "node", "ref" = address))
	if(length(addresses) == 1)
		route.name = "прямое подключение"
	else
		route.name = tree.remote[node.address] ? "через реле NTnet" : "цепочка APC"
		route.latency = tree.cost_to(node.address) + (wireless && owner.origin != NETRUN_ORIGIN_ENTITY && !owner.jack_valid() ? 1 : 0)
		var/datum/netrun_daemon_context/context = new
		context.latency = route.latency
		owner.apply_daemon_effects(context)
		route.latency = context.latency
		qdel(context)
	if(owns_tree)
		owner.release_path_tree(tree)
	return route
