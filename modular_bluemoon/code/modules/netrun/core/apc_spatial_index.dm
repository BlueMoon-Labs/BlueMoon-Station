/// Exact Chebyshev nearest-neighbor index. Z distance only increases XY distance.
#define NETRUN_APC_BUCKET_SIZE 16

/datum/netrun_apc_spatial_index
	var/list/cells = list()
	var/list/positions
	var/list/order = list()
	var/min_x = INFINITY
	var/max_x = -INFINITY
	var/min_y = INFINITY
	var/max_y = -INFINITY

/datum/netrun_apc_spatial_index/New(list/addresses, list/positions_by_address)
	. = ..()
	positions = positions_by_address
	for(var/i in 1 to length(addresses))
		var/address = addresses[i]
		var/turf/point = positions[address]
		if(!point)
			continue
		order[address] = i
		var/cx = round(point.x / NETRUN_APC_BUCKET_SIZE)
		var/cy = round(point.y / NETRUN_APC_BUCKET_SIZE)
		var/key = "[cx]:[cy]"
		var/list/cell = cells[key]
		if(!cell)
			cell = list()
			cells[key] = cell
		cell += address
		min_x = min(min_x, cx)
		max_x = max(max_x, cx)
		min_y = min(min_y, cy)
		max_y = max(max_y, cy)

/datum/netrun_apc_spatial_index/proc/nearest_edges(address)
	var/datum/netrun_apc_neighbor_scan/scan = new(src, address)
	while(!scan.advance())
		continue
	. = scan.best.Copy()
	qdel(scan)

/// Each advance performs at most one cell lookup or one physical distance check.
/datum/netrun_apc_neighbor_scan
	var/datum/netrun_apc_spatial_index/index
	var/address
	var/turf/point
	var/cx
	var/cy
	var/ring = 0
	var/perimeter_cursor = 0
	var/list/direct_candidates
	var/direct_cursor = 1
	var/max_ring = 0
	var/list/cell
	var/cell_cursor = 1
	var/list/best = list()
	var/limit = 1
	var/comparisons = 0
	var/done = FALSE

/datum/netrun_apc_neighbor_scan/New(datum/netrun_apc_spatial_index/spatial, source_address)
	. = ..()
	index = spatial
	address = source_address
	point = spatial.positions[address]
	cx = round(point.x / NETRUN_APC_BUCKET_SIZE)
	cy = round(point.y / NETRUN_APC_BUCKET_SIZE)
	limit = min(max(1, NETRUN_APC_NEIGHBORS), max(0, length(spatial.order) - 1))
	if(length(spatial.order) <= 16)
		direct_candidates = spatial.order
	max_ring = max(abs(spatial.min_x - cx), abs(spatial.max_x - cx), abs(spatial.min_y - cy), abs(spatial.max_y - cy))

/datum/netrun_apc_neighbor_scan/proc/check_neighbor(other_address)
	if(other_address == address)
		return
	var/turf/other = index.positions[other_address]
	var/first = index.order[address] < index.order[other_address] ? address : other_address
	var/second = first == address ? other_address : address
	var/list/edge = list("from" = first, "to" = second, "distance" = netrun_topology_distance(point, other))
	comparisons++
	if(length(best) >= limit && cmp_netrun_physical_edge(edge, best[length(best)]) >= 0)
		return
	best += list(edge)
	sortTim(best, GLOBAL_PROC_REF(cmp_netrun_physical_edge))
	if(length(best) > limit)
		best.len = limit

/datum/netrun_apc_neighbor_scan/proc/advance()
	if(done)
		return TRUE
	// Sparse/small sectors are cheaper to scan directly than to visit empty buckets.
	if(direct_candidates)
		if(direct_cursor <= length(direct_candidates))
			check_neighbor(direct_candidates[direct_cursor++])
			return FALSE
		done = TRUE
		return TRUE
	if(cell && cell_cursor <= length(cell))
		check_neighbor(cell[cell_cursor++])
		return FALSE
	cell = null
	if(perimeter_cursor >= (ring ? 8 * ring : 1))
		// Outside ring R the XY lower bound is R*BUCKET_SIZE + 1.
		if(ring >= max_ring || (length(best) >= limit && best[length(best)]["distance"] <= ring * NETRUN_APC_BUCKET_SIZE))
			done = TRUE
			return TRUE
		ring++
		perimeter_cursor = 0
		return FALSE
	var/dx = 0
	var/dy = 0
	if(ring)
		// Visit each perimeter cell once; never spend work units on ring interiors.
		var/side = round(perimeter_cursor / (2 * ring))
		var/offset = perimeter_cursor % (2 * ring)
		switch(side)
			if(0)
				dx = -ring + offset
				dy = -ring
			if(1)
				dx = ring
				dy = -ring + offset
			if(2)
				dx = ring - offset
				dy = ring
			if(3)
				dx = -ring
				dy = ring - offset
	perimeter_cursor++
	cell = index.cells["[cx + dx]:[cy + dy]"]
	cell_cursor = 1
	return FALSE

/datum/netrun_apc_neighbor_scan/Destroy()
	index = null
	cell = null
	direct_candidates = null
	best = null
	return ..()

