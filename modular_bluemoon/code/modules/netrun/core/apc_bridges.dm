/// Minimum additional cables between disconnected nearest-neighbor components.
/// Incremental Prim: each new component checks its nodes against remaining components
/// once. No quadratic edge table, no dependency on component enumeration order.
/datum/netrun_apc_bridges
	var/list/groups
	var/list/group_order
	var/list/positions
	var/list/input_order
	var/list/connected = list()
	var/list/best_by_group = list()
	var/list/links = list()
	var/source_group
	var/source_i = 1
	var/group_i = 1
	var/target_i = 1
	var/select_i = 1
	var/selected_group
	var/list/selected_edge
	var/selecting = FALSE
	var/completed = FALSE
	var/comparisons = 0

/datum/netrun_apc_bridges/New(list/component_groups, list/ordered_groups, list/node_positions, list/address_order)
	groups = component_groups
	group_order = ordered_groups
	positions = node_positions
	input_order = address_order
	if(length(group_order) < 2)
		completed = TRUE
		return
	source_group = group_order[1]
	connected[source_group] = TRUE

/// At most one physical distance or one best-component comparison per work unit.
/datum/netrun_apc_bridges/proc/advance(max_operations = 1)
	for(var/i in 1 to max_operations)
		if(completed)
			return TRUE
		if(selecting)
			select_component()
		else
			scan_pair()
	return completed

/datum/netrun_apc_bridges/proc/scan_pair()
	var/list/source_members = groups[source_group]
	if(source_i > length(source_members))
		selecting = TRUE
		select_i = 1
		selected_group = null
		selected_edge = null
		return
	if(group_i > length(group_order))
		source_i++
		group_i = 1
		target_i = 1
		return
	var/target_group = group_order[group_i]
	var/list/target_members = groups[target_group]
	if(connected[target_group] || target_i > length(target_members))
		group_i++
		target_i = 1
		return
	var/from_address = source_members[source_i]
	var/to_address = target_members[target_i++]
	var/first = input_order[from_address] < input_order[to_address] ? from_address : to_address
	var/second = first == from_address ? to_address : from_address
	var/list/edge = list("from" = first, "to" = second, "distance" = netrun_topology_distance(positions[first], positions[second]))
	comparisons++
	var/list/best = best_by_group[target_group]
	if(!best || cmp_netrun_physical_edge(edge, best) < 0)
		best_by_group[target_group] = edge

/datum/netrun_apc_bridges/proc/select_component()
	if(select_i <= length(group_order))
		var/group = group_order[select_i++]
		var/list/edge = best_by_group[group]
		if(!connected[group] && edge && (!selected_edge || cmp_netrun_physical_edge(edge, selected_edge) < 0))
			selected_group = group
			selected_edge = edge
		return
	if(!selected_group)
		completed = TRUE
		return
	links += list(selected_edge)
	connected[selected_group] = TRUE
	source_group = selected_group
	source_i = 1
	group_i = 1
	target_i = 1
	selecting = FALSE

/datum/netrun_apc_bridges/Destroy()
	groups = null
	group_order = null
	positions = null
	input_order = null
	best_by_group.Cut()
	connected.Cut()
	links = null
	selected_edge = null
	return ..()
