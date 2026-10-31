/// Compressed native APC area tiles. Runs preserve holes and disconnected shapes.
/datum/netrun_map_geometry
	var/list/cache = list()
	/// Turf runs are independent of the viewer and APC address. Share the immutable
	/// shape briefly so simultaneous viewers do not each walk the same native area.
	/// Keys retain only REF strings; expiry and a hard bound limit retained run data.
	var/static/list/area_run_cache = list()
	var/static/area_run_cleanup_at = -INFINITY

/datum/netrun_map_geometry/proc/apc_zone(datum/component/netrun_node/node, z)
	if(QDELETED(node) || !istype(node.parent, /obj/machinery/power/apc) || !z)
		return null
	var/obj/machinery/power/apc/apc = node.parent
	var/area/room = apc.area || get_area(apc)
	room = room?.base_area || room
	if(!room)
		return null
	var/key = "[node.address]:[z]:[REF(room)]"
	var/list/previous = cache[key]
	var/datum/weakref/previous_room = previous?["area_ref"]
	if(previous && world.time < previous["expires"] && previous_room?.resolve() == room)
		return previous["zone"]
	var/list/runs = area_runs(room, z)
	var/list/shared = area_run_cache["[REF(room)]:[z]"]
	var/list/zone = list("address" = node.address, "name" = room.name, "z" = z,
		"color" = node.network?.color, "runs" = runs)
	// Only the selected APC is retained; ordinary graph polls do not rescan world areas.
	// Inherit the shared scan's deadline instead of extending stale native geometry.
	cache = list()
	cache[key] = list("expires" = shared?["expires"] || world.time + 1 SECONDS, "zone" = zone, "area_ref" = WEAKREF(room))
	return zone

/datum/netrun_map_geometry/proc/area_runs(area/room, z)
	var/key = "[REF(room)]:[z]"
	var/list/previous = area_run_cache[key]
	var/datum/weakref/area_ref = previous?["area_ref"]
	if(previous && world.time < previous["expires"] && area_ref?.resolve() == room)
		return previous["runs"]
	if(world.time >= area_run_cleanup_at)
		area_run_cleanup_at = world.time + 1 SECONDS
		for(var/stale_key in area_run_cache)
			var/list/stale = area_run_cache[stale_key]
			if(world.time >= stale["expires"])
				area_run_cache -= stale_key
	var/list/runs = build_area_runs(room, z)
	area_run_cache[key] = list("expires" = world.time + 1 SECONDS, "runs" = runs, "area_ref" = WEAKREF(room))
	if(length(area_run_cache) > 64)
		area_run_cache.Cut(1, 2)
	return runs

/datum/netrun_map_geometry/proc/build_area_runs(area/room, z)
	var/list/rows = list()
	var/list/areas = list(room)
	areas |= room.sub_areas || list()
	for(var/area/member as anything in areas)
		for(var/turf/tile in member)
			if(tile.z != z)
				continue
			var/row_key = "[tile.y]"
			if(!rows[row_key])
				rows[row_key] = list()
			var/list/columns = rows[row_key]
			// Native areas contain disjoint turfs; no duplicate-membership scan is needed.
			columns += tile.x
	var/list/runs = list()
	var/list/row_numbers = list()
	for(var/row_key in rows)
		row_numbers += text2num(row_key)
	sortTim(row_numbers, GLOBAL_PROC_REF(cmp_numeric_asc))
	for(var/y in row_numbers)
		var/list/columns = rows["[y]"]
		sortTim(columns, GLOBAL_PROC_REF(cmp_numeric_asc))
		var/start
		var/last
		for(var/x in columns)
			if(!isnull(last) && x != last + 1)
				runs += list(list("x" = start, "y" = y, "width" = last - start + 1))
				start = null
			if(isnull(start))
				start = x
			last = x
		if(!isnull(start))
			runs += list(list("x" = start, "y" = y, "width" = last - start + 1))
	return runs

/datum/netrun_map_geometry/Destroy()
	cache.Cut()
	return ..()
