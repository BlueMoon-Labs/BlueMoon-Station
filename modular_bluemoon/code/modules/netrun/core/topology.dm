/// Native linked floors form one physical sector. Never mutate mapping's shared stack cache.
/proc/netrun_sector_for(turf/position)
	if(!position)
		return null
	var/min_z = position.z
	for(var/z in SSmapping.get_connected_levels(position.z))
		min_z = min(min_z, z)
	return "sector:[min_z]"

/// Physical distance determines endpoint binding, APC neighbors, and cable latency.
/proc/netrun_topology_distance(turf/first, turf/second)
	if(!first || !second)
		return INFINITY
	var/list/levels = SSmapping.get_connected_levels(first.z)
	var/first_floor = levels.Find(first.z)
	var/second_floor = levels.Find(second.z)
	var/floor_distance = first_floor && second_floor ? abs(first_floor - second_floor) : abs(first.z - second.z)
	return max(abs(first.x - second.x), abs(first.y - second.y), floor_distance)

/// Registry subscriptions replace full endpoint scans for infrastructure changes.
/datum/netrun_topology/New()
	. = ..()
	RegisterSignal(SSnetrun, COMSIG_NETRUN_NODE_REGISTERED, PROC_REF(on_node_registered))
	RegisterSignal(SSnetrun, COMSIG_NETRUN_NODE_UNREGISTERED, PROC_REF(on_node_unregistered))
	RegisterSignal(SSnetrun, COMSIG_NETRUN_NODE_MOVED, PROC_REF(on_node_moved))
	for(var/address in SSnetrun.nodes_by_address)
		var/datum/component/netrun_node/node = SSnetrun.nodes_by_address[address]
		if(QDELETED(node))
			continue
		if(node.node_type == NETRUN_NODE_APC)
			registered_apcs[address] = node
			if(!node.is_online())
				unavailable_apcs[address] = node
		else if(is_relay(node))
			registered_relays[address] = node

/datum/netrun_topology/proc/on_node_registered(datum/source, datum/component/netrun_node/node)
	SIGNAL_HANDLER
	if(QDELETED(node))
		return
	if(node.node_type == NETRUN_NODE_APC)
		registered_apcs[node.address] = node
		if(!node.is_online())
			unavailable_apcs[node.address] = node
		infrastructure_changed()
	else if(is_relay(node))
		registered_relays[node.address] = node
		infrastructure_changed()
	else
		invalidate()

/datum/netrun_topology/proc/on_node_unregistered(datum/source, datum/component/netrun_node/node)
	SIGNAL_HANDLER
	if(!node)
		return
	registered_apcs -= node.address
	registered_relays -= node.address
	forget_node(node)

/datum/netrun_topology/proc/on_node_moved(datum/source, datum/component/netrun_node/node, turf/old_turf, turf/new_turf)
	SIGNAL_HANDLER
	if(QDELETED(node) || old_turf == new_turf)
		return
	if(!is_infrastructure(node))
		moved_nodes[node] = TRUE
		return
	node.topology_turf = new_turf
	infrastructure_changed()

/// Explicit full route snapshots need current destination costs even before the
/// next worker pass. Reconcile only moved leaves, never scan stationary endpoints.
/datum/netrun_topology/proc/reconcile_movement()
	if(rebuilding || !length(moved_nodes))
		return
	var/list/pending = moved_nodes
	moved_nodes = list()
	for(var/datum/component/netrun_node/node as anything in pending)
		if(!QDELETED(node))
			node.join_network()

/// Cached structural graph. Online state is deliberately absent: routing validates it live.
/datum/netrun_topology
	var/list/nodes = list()
	var/list/adjacency = list()
	/// Forwarding-only neighbor lists avoid scanning every machine cable per APC solve.
	var/list/forwarding_adjacency = list()
	var/list/edges = list()
	var/list/edge_lookup = list()
	/// Stable edge id -> slot: replacing a leaf cable must not scan thousands of edges.
	var/list/edge_positions = list()
	var/dirty = TRUE
	var/rebuilding = FALSE
	var/structural_generation = 0
	var/datum/netrun_apc_prebuild/apc_prebuild
	var/revision = 0
	/// Last complete publication's CPU phases, without retaining nodes or snapshots.
	var/list/last_rebuild_costs = list()
	var/list/peak_rebuild_costs = list()
	var/peak_rebuild_ms = 0
	var/deferred_bindings = FALSE
	var/infrastructure_revision = 0
	var/indexed_revision = -1
	var/list/apcs_by_sector = list()
	/// Physical sector + supplied base area. Native APCs always outrank foreign ones.
	var/list/apcs_by_area = list()
	var/list/relay_addresses = list()
	var/list/registered_apcs = list()
	/// Only observed outages need fallback recovery polling; usable paths stay live-checked.
	var/list/unavailable_apcs = list()
	var/list/registered_relays = list()
	/// Coalesced leaf geometry changes, shared by node workers and route snapshots.
	var/list/moved_nodes = list()
	var/indexed_infrastructure_visits = 0
	var/nearest_apc_visits = 0
	var/list/nearest_by_turf = list()
	/// Moving an endpoint updates route costs without replacing its structural parent.
	var/weight_revision = 0
	/// Forwarding availability changes independently from graph geometry and occupancy.
	var/availability_revision = 0
	/// Only forwarding nodes can change visibility beyond their own marker.
	var/transit_availability_revision = 0
	var/backbone_disabled

/datum/netrun_topology/proc/availability_changed(datum/component/netrun_node/node, online)
	if(node.node_type == NETRUN_NODE_APC)
		if(isnull(online))
			online = node.is_online()
		if(online || QDELETED(node))
			unavailable_apcs -= node.address
		else
			unavailable_apcs[node.address] = node
	availability_revision++
	if(is_infrastructure(node) || length(adjacency[node.address]) > 1)
		transit_availability_revision++

/datum/netrun_topology/proc/invalidate()
	dirty = TRUE
	structural_generation++
	SEND_SIGNAL(SSnetrun, COMSIG_NETRUN_TOPOLOGY_DIRTY, src, structural_generation)

/datum/netrun_topology/proc/infrastructure_changed()
	infrastructure_revision++
	clear_infrastructure_routes()
	nearest_by_turf.Cut()
	invalidate()

/// Drop strong cache references immediately; an unopened map must not retain deleted nodes.
/datum/netrun_topology/proc/forget_node(datum/component/netrun_node/node)
	moved_nodes -= node
	if(!node)
		return
	unavailable_apcs -= node.address
	forget_infrastructure_route(node.address)
	forget_route_table(node.address)
	nodes -= node.address
	adjacency -= node.address
	forwarding_adjacency -= node.address
	for(var/address in forwarding_adjacency)
		var/list/connected = forwarding_adjacency[address]
		connected -= node.address
	for(var/address in adjacency)
		var/list/connected = adjacency[address]
		connected -= node.address
	if(is_infrastructure(node))
		infrastructure_changed()
	else
		invalidate()
	if(node.node_type != NETRUN_NODE_APC)
		return
	for(var/address in SSnetrun.nodes_by_address)
		var/datum/component/netrun_node/dependent = SSnetrun.nodes_by_address[address]
		if(dependent.bound_apc == node)
			dependent.bound_apc = null
			dependent.binding_infra_revision = -1
			dependent.join_network()

/datum/netrun_topology/proc/is_relay(datum/component/netrun_node/node)
	return node && istype(node.parent, /obj/machinery/ntnet_relay)

/datum/netrun_topology/proc/is_infrastructure(datum/component/netrun_node/node)
	return node && (node.node_type == NETRUN_NODE_APC || is_relay(node))

/// A mapped APC may be mounted outside the area it actually supplies.
/datum/netrun_topology/proc/apc_area(datum/component/netrun_node/node)
	var/area/room
	if(istype(node?.parent, /obj/machinery/power/apc))
		var/obj/machinery/power/apc/apc = node.parent
		room = apc.area
	room = room || get_area(node?.parent)
	return room?.base_area || room

/// Allocation and index refresh do not build the graph or call join_network().
/datum/netrun_topology/proc/index_infrastructure()
	if(indexed_revision == infrastructure_revision)
		return
	apcs_by_sector = list()
	apcs_by_area = list()
	relay_addresses = list()
	// Work scales with infrastructure, not the count of endpoints.
	for(var/address in sort_list(registered_apcs.Copy()))
		var/datum/component/netrun_node/node = registered_apcs[address]
		if(QDELETED(node) || QDELETED(node.parent))
			continue
		indexed_infrastructure_visits++
		var/sector = netrun_sector_for(node.physical_turf())
		if(!sector)
			continue
		var/list/sector_apcs = apcs_by_sector[sector]
		if(!sector_apcs)
			sector_apcs = list()
			apcs_by_sector[sector] = sector_apcs
		sector_apcs += address
		var/area_key = "[sector]:[REF(apc_area(node))]"
		var/list/area_apcs = apcs_by_area[area_key]
		if(!area_apcs)
			area_apcs = list()
			apcs_by_area[area_key] = area_apcs
		area_apcs += address
	for(var/address in sort_list(registered_relays.Copy()))
		var/datum/component/netrun_node/node = registered_relays[address]
		if(QDELETED(node) || QDELETED(node.parent))
			continue
		indexed_infrastructure_visits++
		if(netrun_sector_for(node.physical_turf()))
			relay_addresses += address
	indexed_revision = infrastructure_revision

/datum/netrun_topology/proc/nearest_apc(turf/position)
	if(!position)
		return null
	index_infrastructure()
	var/sector = netrun_sector_for(position)
	var/area/room = get_area(position)
	var/area/root_area = room?.base_area || room
	// Coordinates avoid keeping replaced turfs alive in a long-lived cache.
	var/cache_key = "[sector]:[REF(root_area)]:[position.x],[position.y],[position.z]"
	if(cache_key in nearest_by_turf)
		return nearest_by_turf[cache_key]
	// A room's native APC wins regardless of distance. Avoid scanning every APC
	// in the sector for every uncached endpoint turf during startup and rebuilds.
	var/list/native_candidates = apcs_by_area["[sector]:[REF(root_area)]"]
	var/list/candidates = length(native_candidates) ? native_candidates : apcs_by_sector[sector]
	var/datum/component/netrun_node/best
	var/best_distance = INFINITY
	var/best_native = FALSE
	// The index is address-sorted, so equal distances have a total, stable tie-break.
	for(var/address in candidates)
		nearest_apc_visits++
		var/datum/component/netrun_node/candidate = SSnetrun.nodes_by_address[address]
		if(QDELETED(candidate) || netrun_sector_for(candidate.physical_turf()) != sector)
			continue
		var/distance = netrun_topology_distance(position, candidate.physical_turf())
		var/native = apc_area(candidate) == root_area
		if((native && !best_native) || (native == best_native && distance < best_distance))
			best = candidate
			best_distance = distance
			best_native = native
	nearest_by_turf[cache_key] = best
	return best

/// Re-evaluate only a changed binding context, a lost APC, or a formerly empty sector.
/// Existing valid bindings survive added nearer APCs and ordinary movement within their root area.
/datum/netrun_topology/proc/refresh_node(datum/component/netrun_node/node)
	moved_nodes -= node
	if(QDELETED(node) || QDELETED(node.parent))
		return
	var/turf/position = node.physical_turf()
	// Fast path: an already-bound node that has not moved, under unchanged infrastructure,
	// keeps its binding - skip the sector/area/nearest-APC work entirely.
	if(position == node.topology_turf && node.binding_checked && node.binding_infra_revision == infrastructure_revision)
		return
	var/sector = netrun_sector_for(position)
	var/area/room = position ? get_area(position) : null
	var/area/root_area = room?.base_area || room
	// The endpoint stays on its APC while its geographic cable length changes.
	if(!is_infrastructure(node) && node.topology_turf != position)
		node.topology_turf = position
		// A dirty graph is an old published snapshot. Background membership
		// preparation must not change its edges before the replacement commits.
		if(!dirty && !rebuilding)
			refresh_node_weights(node)
		node.notify_changed(NETRUN_CHANGED_STATE)
	if(is_infrastructure(node) && (node.topology_turf != position || (node.binding_checked && node.binding_sector != sector)))
		node.topology_turf = position
		infrastructure_changed()
	// Map initialization order must not pin a machine to an early, distant APC.
	// The first normal graph build binds all mapped endpoints after registration.
	if(!node.binding_checked && SSatoms.initialized != INITIALIZATION_INNEW_REGULAR)
		deferred_bindings = TRUE
		return
	var/context_changed = !node.binding_checked || node.binding_area != root_area || node.binding_sector != sector
	var/datum/component/netrun_node/previous = node.bound_apc
	var/valid_binding = !QDELETED(previous) && previous.node_type == NETRUN_NODE_APC && SSnetrun.nodes_by_address[previous.address] == previous && sector && netrun_sector_for(previous.physical_turf()) == sector
	if(node.node_type == NETRUN_NODE_APC)
		node.bound_apc = null
	else if(context_changed || (previous && !valid_binding) || (!previous && node.binding_infra_revision != infrastructure_revision))
		node.bound_apc = nearest_apc(position)
	node.binding_checked = TRUE
	node.binding_area = root_area
	node.binding_sector = sector
	node.binding_infra_revision = infrastructure_revision
	if(previous != node.bound_apc)
		if(!rebind_leaf(node))
			invalidate()
		// join_network publishes once after both the APC and LAN are current.

/// Changing one endpoint's APC does not change the infrastructure mesh. Update
/// its single edge directly rather than rebuilding every APC pair and endpoint.
/datum/netrun_topology/proc/rebind_leaf(datum/component/netrun_node/node)
	if(dirty || rebuilding || is_infrastructure(node) || nodes[node.address] != node)
		return FALSE
	var/list/neighbors = adjacency[node.address]
	if(length(neighbors) > 1 || (node.bound_apc && nodes[node.bound_apc.address] != node.bound_apc))
		return FALSE
	for(var/neighbor in neighbors)
		var/list/edge = edge_lookup["[node.address]>[neighbor]"]
		if(edge)
			// Swap-delete in O(1). Graph-wide edge scans are unacceptable for mobile leaves.
			var/slot = edge_positions[edge["id"]]
			var/last_slot = length(edges)
			if(slot && last_slot)
				var/list/last_edge = edges[last_slot]
				if(slot != last_slot)
					edges[slot] = last_edge
					edge_positions[last_edge["id"]] = slot
				edges.len--
			edge_positions -= edge["id"]
			edge_lookup -= "[node.address]>[neighbor]"
			edge_lookup -= "[neighbor]>[node.address]"
		var/list/peers = adjacency[neighbor]
		peers -= node.address
	adjacency[node.address] = list()
	if(node.bound_apc)
		add_edge(node.address, node.bound_apc.address, "endpoint")
	// Only the leaf's predecessor changed. Keep the infrastructure graph and
	// every unrelated viewer's cached routes instead of broadcasting a full rebuild.
	var/previous_geometry = weight_revision
	weight_revision++
	rebind_leaf_route_tables(node, previous_geometry)
	return TRUE

/datum/netrun_topology/proc/neighbors(address, include_relays = TRUE)
	var/list/local = adjacency[address] || list()
	if(!include_relays || !(address in relay_addresses))
		return local
	// Quantum connectivity is a bucket, not a quadratic list of materialized edges.
	. = local.Copy()
	for(var/relay_address in relay_addresses)
		if(relay_address != address && nodes[relay_address])
			. += relay_address

/datum/netrun_topology/proc/forwarding_neighbors(address)
	return forwarding_adjacency[address] || adjacency[address] || list()

/datum/netrun_topology/proc/edge_between(first, second)
	RETURN_TYPE(/list)
	var/list/edge = edge_lookup["[first]>[second]"]
	if(edge)
		return edge
	if(first != second && (first in relay_addresses) && (second in relay_addresses) && nodes[first] && nodes[second])
		var/list/pair = sort_list(list(first, second))
		return list("id" = "relay:[pair[1]]>[pair[2]]", "from" = pair[1], "to" = pair[2], "kind" = "relay", "latency" = NETRUN_RELAY_LATENCY)

/datum/netrun_topology/proc/edge_cost(first, second, distance)
	if(netrun_quantum_link(nodes[first], nodes[second]))
		return NETRUN_RELAY_LATENCY
	if(isnull(distance))
		var/datum/component/netrun_node/from_node = nodes[first]
		var/datum/component/netrun_node/to_node = nodes[second]
		distance = netrun_topology_distance(from_node?.physical_turf(), to_node?.physical_turf())
	return max(1, CEILING(distance / NETRUN_LINK_TILES_PER_DS, 1))

/datum/netrun_topology/proc/refresh_node_weights(datum/component/netrun_node/node)
	var/changed = FALSE
	var/delta = 0
	var/list/neighbors = adjacency[node.address]
	for(var/neighbor in neighbors)
		var/list/edge = edge_lookup["[node.address]>[neighbor]"]
		var/datum/component/netrun_node/peer = nodes[neighbor]
		var/cost = edge_cost(node.address, neighbor)
		if(edge["latency"] != cost)
			delta = cost - edge["latency"]
			edge["latency"] = cost
			changed = TRUE
		edge["distance"] = netrun_topology_distance(node.physical_turf(), peer.physical_turf())
	if(changed)
		var/previous_geometry = weight_revision
		weight_revision++
		if(!is_infrastructure(node) && length(neighbors) == 1)
			reweight_leaf_routes(node.address, neighbors[1], delta, previous_geometry)

/// All edges are undirected and canonicalized by address, including endpoint bindings.
/datum/netrun_topology/proc/add_edge(first, second, kind)
	if(!first || !second || first == second || !nodes[first] || !nodes[second])
		return
	if(edge_lookup["[first]>[second]"])
		return
	// Match cmp_text_asc without allocating and sorting a pair for every cable.
	if(sorttext(second, first) > 0)
		var/swap = first
		first = second
		second = swap
	var/list/first_neighbors = adjacency[first]
	first_neighbors += second
	var/list/second_neighbors = adjacency[second]
	second_neighbors += first
	var/datum/component/netrun_node/from_node = nodes[first]
	var/datum/component/netrun_node/to_node = nodes[second]
	var/distance = netrun_topology_distance(from_node.physical_turf(), to_node.physical_turf())
	var/list/edge = list("id" = "[kind]:[first]>[second]", "from" = first, "to" = second, "kind" = kind,
		"latency" = edge_cost(first, second, distance), "distance" = distance)
	edges += list(edge)
	edge_positions[edge["id"]] = length(edges)
	edge_lookup["[first]>[second]"] = edge
	edge_lookup["[second]>[first]"] = edge

/// Stable distance ordering, then canonical endpoint addresses for equal lengths.
/proc/cmp_netrun_physical_edge(list/first, list/second)
	var/order = first["distance"] - second["distance"]
	if(order)
		return order
	order = sorttext(second["from"], first["from"])
	if(order)
		return order
	return sorttext(second["to"], first["to"])

/datum/netrun_topology/proc/apc_component(list/components, address)
	var/root = address
	while(components[root] != root)
		root = components[root]
	while(address != root)
		var/next = components[address]
		components[address] = root
		address = next
	return root

/// Each APC selects its two nearest peers. Prim adds only the shortest
/// bridges between remaining components; no artificial hub or relay is involved.
/datum/netrun_topology/proc/connect_apcs(list/addresses)
	if(length(addresses) < 2)
		return
	// Exact indexed search: nearby cells first, prune only provably farther cells.
	var/list/nearest = list()
	var/list/components = list()
	var/list/input_order = list()
	var/list/positions = list()
	for(var/i in 1 to length(addresses))
		var/address = addresses[i]
		components[address] = address
		input_order[address] = i
		var/datum/component/netrun_node/apc = nodes[address]
		positions[address] = apc.physical_turf()
	var/datum/netrun_apc_spatial_index/spatial = new(addresses, positions)
	for(var/address in addresses)
		nearest[address] = spatial.nearest_edges(address)
	qdel(spatial)
	// Deduplicate each selected pair and preserve deterministic edge ordering.
	var/list/candidate_pairs = list()
	var/list/seen_pairs = list()
	for(var/address in addresses)
		var/list/listing = nearest[address]
		for(var/list/pair as anything in listing)
			var/key = "[pair["from"]]>[pair["to"]]"
			if(seen_pairs[key])
				continue
			seen_pairs[key] = TRUE
			candidate_pairs += list(pair)
	sortTim(candidate_pairs, GLOBAL_PROC_REF(cmp_netrun_physical_edge))
	for(var/list/pair as anything in candidate_pairs)
		var/first = pair["from"]
		var/second = pair["to"]
		add_edge(first, second, "apc")
		components[apc_component(components, second)] = apc_component(components, first)
	// The nearby-APC edges may form several disconnected groups.
	// Connect every remaining group to the growing network in one bounded pass.
	// Pair endpoints are canonical, NOT necessarily attached->unattached.
	var/list/component_groups = list()
	var/list/group_order = list()
	for(var/address in addresses)
		var/root = apc_component(components, address)
		var/list/members = component_groups[root]
		if(!members)
			members = list()
			component_groups[root] = members
			group_order += root
		members += address
	if(length(group_order) < 2)
		return
	var/datum/netrun_apc_bridges/bridges = new(component_groups, group_order, positions, input_order)
	while(!bridges.advance(NETRUN_DEFAULT_APC_PREBUILD_OPERATIONS))
		continue
	for(var/list/edge as anything in bridges.links)
		add_edge(edge["from"], edge["to"], "apc")
	qdel(bridges)

/// Prepare expensive APC work without changing published nodes, edges or adjacency.
/datum/netrun_topology/proc/advance_apc_prebuild(max_operations = NETRUN_DEFAULT_APC_PREBUILD_OPERATIONS)
	if(!dirty || rebuilding)
		QDEL_NULL(apc_prebuild)
		return TRUE
	if(!apc_prebuild || apc_prebuild.generation != infrastructure_revision)
		QDEL_NULL(apc_prebuild)
		apc_prebuild = new(src)
	if(!apc_prebuild.advance(max_operations))
		return FALSE
	if(apc_prebuild.valid_inputs())
		if(!apc_prebuild.advance_bindings(min(max_operations, 16)))
			return FALSE
		if(!apc_prebuild?.valid_inputs())
			QDEL_NULL(apc_prebuild)
			return !dirty
		rebuild()
	else
		QDEL_NULL(apc_prebuild)
	return !dirty

/datum/netrun_topology/proc/rebuild()
	if(rebuilding)
		return
	rebuilding = TRUE
	last_rebuild_costs = list()
	var/phase_started = TICK_USAGE
	clear_route_tables()
	nodes = list()
	adjacency = list()
	forwarding_adjacency = list()
	edges = list()
	edge_lookup = list()
	edge_positions = list()
	// Registry order is stable during this publication. Only APC candidate and
	// adjacency ordering affect routing tie-breaks; sorting every leaf is wasted.
	var/list/addresses = SSnetrun.nodes_by_address.Copy()
	last_rebuild_costs["reset"] = max(0, TICK_DELTA_TO_MS(TICK_USAGE - phase_started))
	phase_started = TICK_USAGE
	// A carrier can move infrastructure without a MOVED signal on the nested machine.
	// Refresh every infrastructure position before any endpoint consults the spatial index.
	var/moved_infrastructure = FALSE
	for(var/address in addresses)
		var/datum/component/netrun_node/node = SSnetrun.nodes_by_address[address]
		if(QDELETED(node) || !is_infrastructure(node))
			continue
		var/turf/position = node.physical_turf()
		if(node.topology_turf != position)
			node.topology_turf = position
			moved_infrastructure = TRUE
	if(moved_infrastructure)
		infrastructure_changed()
	last_rebuild_costs["infrastructure"] = max(0, TICK_DELTA_TO_MS(TICK_USAGE - phase_started))
	phase_started = TICK_USAGE
	// This only refreshes bindings and LANs; neither path calls ensure_topology().
	for(var/address in addresses)
		var/datum/component/netrun_node/node = SSnetrun.nodes_by_address[address]
		if(QDELETED(node) || QDELETED(node.parent))
			continue
		node.join_network()
		nodes[address] = node
		adjacency[address] = list()
	index_infrastructure()
	last_rebuild_costs["bindings"] = max(0, TICK_DELTA_TO_MS(TICK_USAGE - phase_started))
	phase_started = TICK_USAGE
	// Every endpoint has one physical cable to its APC, including personal nodes.
	for(var/address in nodes)
		var/datum/component/netrun_node/node = nodes[address]
		if(!node.bound_apc)
			continue
		add_edge(address, node.bound_apc.address, "endpoint")
	last_rebuild_costs["endpoint_edges"] = max(0, TICK_DELTA_TO_MS(TICK_USAGE - phase_started))
	phase_started = TICK_USAGE
	// Precomputed candidates are optional; forced routing requests still rebuild immediately.
	var/datum/netrun_apc_prebuild/prepared = apc_prebuild
	var/valid_prebuild = prepared?.completed && prepared.valid_inputs()
	var/list/sectors = sort_list(apcs_by_sector.Copy())
	for(var/sector in sectors)
		var/list/prebuilt = valid_prebuild ? prepared.links_by_sector[sector] : null
		if(islist(prebuilt))
			for(var/list/pair as anything in prebuilt)
				add_edge(pair["from"], pair["to"], "apc")
		else
			connect_apcs(apcs_by_sector[sector])
	last_rebuild_costs["apc_edges"] = max(0, TICK_DELTA_TO_MS(TICK_USAGE - phase_started))
	phase_started = TICK_USAGE
	// Relay-to-relay transitions are an implicit uniform-cost bucket.
	for(var/address in adjacency)
		if(length(adjacency[address]) > 1)
			adjacency[address] = sort_list(adjacency[address])
		if(!is_infrastructure(nodes[address]) && length(adjacency[address]) <= 1)
			continue
		var/list/forwarders = list()
		for(var/neighbor in adjacency[address])
			if(is_infrastructure(nodes[neighbor]) || length(adjacency[neighbor]) > 1)
				forwarders += neighbor
		forwarding_adjacency[address] = forwarders
	last_rebuild_costs["forwarding"] = max(0, TICK_DELTA_TO_MS(TICK_USAGE - phase_started))
	phase_started = TICK_USAGE
	dirty = FALSE
	revision++
	weight_revision++
	deferred_bindings = SSatoms.initialized != INITIALIZATION_INNEW_REGULAR
	rebuilding = FALSE
	QDEL_NULL(apc_prebuild)
	SEND_SIGNAL(SSnetrun, COMSIG_NETRUN_TOPOLOGY_CHANGED, revision)
	last_rebuild_costs["notification"] = max(0, TICK_DELTA_TO_MS(TICK_USAGE - phase_started))
	var/total_cost = 0
	for(var/phase in last_rebuild_costs)
		total_cost += last_rebuild_costs[phase]
	if(total_cost > peak_rebuild_ms)
		peak_rebuild_ms = total_cost
		peak_rebuild_costs = last_rebuild_costs

/datum/netrun_topology/Destroy()
	UnregisterSignal(SSnetrun, list(COMSIG_NETRUN_NODE_REGISTERED, COMSIG_NETRUN_NODE_UNREGISTERED, COMSIG_NETRUN_NODE_MOVED))
	QDEL_NULL(apc_prebuild)
	clear_route_tables(TRUE)
	clear_infrastructure_routes()
	nodes.Cut()
	adjacency.Cut()
	forwarding_adjacency.Cut()
	edges.Cut()
	edge_lookup.Cut()
	edge_positions.Cut()
	apcs_by_sector.Cut()
	apcs_by_area.Cut()
	registered_apcs.Cut()
	unavailable_apcs.Cut()
	registered_relays.Cut()
	moved_nodes.Cut()
	relay_addresses.Cut()
	nearest_by_turf.Cut()
	return ..()
