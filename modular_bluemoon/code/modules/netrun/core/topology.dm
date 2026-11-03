/// Native linked floors form one physical sector for native authorization domains.
/proc/netrun_sector_for(turf/position)
	if(!position)
		return null
	var/min_z = position.z
	for(var/z in SSmapping.get_connected_levels(position.z))
		min_z = min(min_z, z)
	return "sector:[min_z]"

/// Read-only publication imported from C#. DM never builds physical links or binds endpoints.
/datum/netrun_topology
	/// Stable address -> current native node identity.
	var/list/nodes = list()
	/// Imported physical neighbors; virtual relay connectivity is represented by relay_addresses.
	var/list/adjacency = list()
	/// Imported edge rows and directional lookup share the same immutable publication.
	var/list/edges = list()
	var/list/edge_lookup = list()
	/// Imported edge id -> slot, maintained by the projection delta adapter.
	var/list/edge_positions = list()
	/// Readers fail closed while the external publication is incomplete.
	var/dirty = TRUE
	var/revision = 0
	/// Imported topology and availability revisions are independent of native gameplay state.
	var/infrastructure_revision = 0
	var/weight_revision = 0
	var/availability_revision = 0
	var/transit_availability_revision = 0
	/// Imported infrastructure indexes support native presentation and game AI.
	var/list/relay_addresses = list()
	var/list/registered_apcs = list()
	var/list/registered_relays = list()

/// Lifecycle callbacks invalidate the imported projection; they never start a native builder.
/datum/netrun_topology/New()
	. = ..()
	RegisterSignal(SSnetrun, COMSIG_NETRUN_NODE_REGISTERED, PROC_REF(on_node_registered))
	RegisterSignal(SSnetrun, COMSIG_NETRUN_NODE_UNREGISTERED, PROC_REF(on_node_unregistered))
	RegisterSignal(SSnetrun, COMSIG_NETRUN_NODE_MOVED, PROC_REF(on_node_moved))

/datum/netrun_topology/proc/on_node_registered(datum/source, datum/component/netrun_node/node)
	SIGNAL_HANDLER
	invalidate()

/datum/netrun_topology/proc/on_node_unregistered(datum/source, datum/component/netrun_node/node)
	SIGNAL_HANDLER
	if(node)
		nodes -= node.address
		registered_apcs -= node.address
		registered_relays -= node.address
	invalidate()

/datum/netrun_topology/proc/on_node_moved(datum/source, datum/component/netrun_node/node, turf/old_turf, turf/new_turf)
	SIGNAL_HANDLER
	if(old_turf != new_turf)
		invalidate()

/datum/netrun_topology/proc/invalidate()
	dirty = TRUE

/datum/netrun_topology/proc/infrastructure_changed()
	invalidate()

/datum/netrun_topology/proc/availability_changed(datum/component/netrun_node/node, online)
	invalidate()

/// Native state is exported separately; C# owns the resulting reachability calculation.
/datum/netrun_topology/proc/reconcile_availability()
	SSnetrun.reconcile_dirty_availability()

/datum/netrun_topology/proc/is_relay(datum/component/netrun_node/node)
	return node && istype(node.parent, /obj/machinery/ntnet_relay)

/datum/netrun_topology/proc/is_infrastructure(datum/component/netrun_node/node)
	return node && (node.node_type == NETRUN_NODE_APC || is_relay(node))

/// Native LAN profiles use the APC's supplied base area; this does not choose an attachment.
/datum/netrun_topology/proc/apc_area(datum/component/netrun_node/node)
	var/area/room
	if(istype(node?.parent, /obj/machinery/power/apc))
		var/obj/machinery/power/apc/apc = node.parent
		room = apc.area
	room = room || get_area(node?.parent)
	return room?.base_area || room

/datum/netrun_topology/proc/neighbors(address, include_relays = TRUE)
	var/list/local = adjacency[address] || list()
	if(!include_relays || !(address in relay_addresses))
		return local
	// Quantum connectivity is a bucket, not a quadratic list of materialized edges.
	. = local.Copy()
	for(var/relay_address in relay_addresses)
		if(relay_address != address && nodes[relay_address])
			. += relay_address

/datum/netrun_topology/proc/edge_between(first, second)
	RETURN_TYPE(/list)
	var/list/edge = edge_lookup["[first]>[second]"]
	if(edge)
		return edge
	return projected_relay_edge(first, second)

/// Представление виртуального ребра из импортированного relay-bucket; физические связи здесь не рассчитываются.
/datum/netrun_topology/proc/projected_relay_edge(first, second)
	RETURN_TYPE(/list)
	if(first != second && (first in relay_addresses) && (second in relay_addresses) && nodes[first] && nodes[second])
		var/list/pair = sort_list(list(first, second))
		return list("id" = "relay:[pair[1]]>[pair[2]]", "from" = pair[1], "to" = pair[2], "kind" = "relay", "latency" = NETRUN_RELAY_LATENCY)

/// Release only the native view; projection owners release their own cached tables.
/datum/netrun_topology/Destroy()
	UnregisterSignal(SSnetrun, list(COMSIG_NETRUN_NODE_REGISTERED, COMSIG_NETRUN_NODE_UNREGISTERED, COMSIG_NETRUN_NODE_MOVED))
	nodes.Cut()
	adjacency.Cut()
	edges.Cut()
	edge_lookup.Cut()
	edge_positions.Cut()
	registered_apcs.Cut()
	registered_relays.Cut()
	relay_addresses.Cut()
	return ..()
