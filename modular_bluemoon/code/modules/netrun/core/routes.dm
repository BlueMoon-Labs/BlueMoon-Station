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

/// Imported predecessor/cost table. Native code validates paths and permissions, never solves them.
/datum/netrun_path_tree
	/// Retained tables belong to the external projection; operation copies belong to their caller.
	var/retained = FALSE
	var/datum/component/netrun_node/source
	var/revision = 0
	var/updated_at = 0
	var/list/reached = list()
	/// LAN id -> an imported witness address, validated against current native authority.
	var/list/reached_networks = list()
	var/network_index_ready = FALSE
	var/list/previous = list()
	var/list/costs = list()
	var/list/remote = list()
	var/geometry_revision = 0
	var/availability_revision = 0
	var/transit_availability_revision = 0
	var/datum/weakref/graph_ref

/// An unpopulated table is fail-closed. Only an external projection may add reachable entries.
/datum/netrun_path_tree/New(datum/netrun_topology/graph, datum/component/netrun_node/start)
	source = start
	if(graph)
		graph_ref = WEAKREF(graph)

/datum/netrun_path_tree/Destroy()
	source = null
	graph_ref = null
	reached.Cut()
	reached_networks.Cut()
	previous.Cut()
	costs.Cut()
	remote.Cut()
	return ..()

/// Reconstruct the imported chain with a finite bound so malformed tables cannot loop.
/datum/netrun_path_tree/proc/addresses_to(address)
	var/list/path = list()
	if(!reached[address])
		return path
	for(var/step in 1 to length(reached))
		path += address
		address = previous[address]
		if(!address)
			reverseRange(path)
			return path
	return list()

/// Return the exact C# cost; native leaf movement never patches a stale route table.
/datum/netrun_path_tree/proc/cost_to(address)
	return costs[address]

/// Request-local copies preserve the imported table without retaining a second route cache.
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
	snapshot.remote = remote.Copy()
	snapshot.geometry_revision = geometry_revision
	snapshot.availability_revision = availability_revision
	snapshot.transit_availability_revision = transit_availability_revision
	snapshot.graph_ref = graph_ref
	return snapshot

/// Validate a supplied predecessor chain against live native hosts. This never chooses another route.
/datum/netrun_path_tree/proc/path_available(datum/netrun_topology/graph, address)
	if(!graph || graph.dirty || !reached[address] || QDELETED(source) || graph.nodes[source.address] != source)
		return FALSE
	var/destination = address
	for(var/step in 1 to length(reached))
		var/datum/component/netrun_node/node = graph.nodes[address]
		if(QDELETED(node) || QDELETED(node.parent))
			return FALSE
		var/parent_address = previous[address]
		if(!parent_address)
			return node == source
		var/datum/component/netrun_node/parent_node = graph.nodes[parent_address]
		if(!netrun_link_available(parent_node, node, address == destination) || !graph.edge_between(parent_address, address))
			return FALSE
		address = parent_address
	return FALSE

/datum/netrun_path_tree/proc/network_available(datum/netrun_topology/graph, datum/netrun_network/network)
	var/address = reached_networks[network.id]
	var/datum/component/netrun_node/witness = graph?.nodes[address]
	return !QDELETED(witness) && witness.network == network && path_available(graph, address)

/// The external subtype supplies imported tables; an unpublished graph has no reachable addresses.
/datum/netrun_topology/proc/route_snapshot(datum/component/netrun_node/start, borrow = FALSE)
	RETURN_TYPE(/datum/netrun_path_tree)
	return new /datum/netrun_path_tree

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
	// Point attachment describes wireless access; a detached cable cannot authorize it.
	if(!wireless)
		return null
	var/datum/netrun_external_effects/machines/queries/executor = netrun_external_projection_executor()
	return executor?.projection_anchor(SSnetrun.external_core, owner)

/datum/netrun_console/entity/physical_route_source()
	var/mob/camera/netrun_entity/entity = host
	return refresh_route_node(entity?.host_node)

/// Resolve only a live native identity; C# owns the published attachment and LAN.
/datum/netrun_console/proc/refresh_route_node(datum/component/netrun_node/node)
	return connection.refresh_route_node(node)

/datum/netrun_connection/proc/refresh_route_node(datum/component/netrun_node/node)
	if(QDELETED(node) || QDELETED(node.parent))
		return null
	// Repeated UI reads share the same checked identity in this serialization pass.
	if(owner.ui_serializing && owner.ui_routes && ui_refreshed_nodes)
		if(ui_refreshed_nodes[node.address] == node && !node.pending_physical_update)
			return node
		ui_refreshed_nodes[node.address] = node
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
	var/datum/netrun_external_effects/machines/queries/executor = netrun_external_projection_executor()
	executor?.projection_watch(SSnetrun.external_core, start, owner)
	var/datum/netrun_path_tree/external/tree = SSnetrun.get_topology().route_snapshot(start, TRUE)
	return wireless_zone_restricted() && istype(tree) ? tree.external_local_copy() : tree

/datum/netrun_connection/proc/wireless_zone_restricted()
	if(!wireless || owner.origin == NETRUN_ORIGIN_ENTITY || owner.jack_valid())
		return FALSE
	var/turf/here = owner.physical_turf()
	return !here || (!is_station_level(here.z) && !is_mining_level(here.z))

/// Explicit request trees are local variables, so concurrent yielding device
/// operations cannot borrow another request's path or an old UI snapshot.
/datum/netrun_console/proc/make_path_tree(use_stored_routes = TRUE)
	return connection.make_path_tree(use_stored_routes)

/datum/netrun_connection/proc/make_path_tree(use_stored_routes = TRUE)
	var/datum/netrun_path_tree/tree = read_path_tree(TRUE)
	return tree.retained ? tree.copy() : tree

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
