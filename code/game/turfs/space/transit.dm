/turf/open/space/transit
	name = "\proper hyperspace"
	icon_state = "black"
	dir = SOUTH
	baseturfs = /turf/open/space/transit
	flags_1 = NOJAUNT_1 //This line goes out to every wizard that ever managed to escape the den. I'm sorry.
	explosion_block = INFINITY

/turf/open/space/transit/get_smooth_underlay_icon(mutable_appearance/underlay_appearance, turf/asking_turf, adjacency_dir)
	. = ..()
	underlay_appearance.icon_state = "speedspace_ns_[get_transit_state(asking_turf)]"
	underlay_appearance.transform = turn(matrix(), get_transit_angle(asking_turf))

/turf/open/space/transit/south
	dir = SOUTH

/turf/open/space/transit/north
	dir = NORTH

/turf/open/space/transit/horizontal
	dir = WEST

/turf/open/space/transit/west
	dir = WEST

/turf/open/space/transit/east
	dir = EAST

/turf/open/space/transit/border
	opacity = TRUE

/turf/open/space/transit/border/south
	dir = SOUTH

/turf/open/space/transit/border/north
	dir = NORTH

/turf/open/space/transit/border/west
	dir = WEST

/turf/open/space/transit/border/east
	dir = EAST

/turf/open/space/transit/centcom
	dir = SOUTH

/// Start tg-style hyperspace drift for movables entering a transit tile (flow direction follows turf dir).
/// If [ignore_shuttle_interior] is TRUE, drift is applied even when inside a mobile dock's bbox (shuttle event spawns often sit there but are still open transit).
/proc/init_shuttle_cling(atom/movable/M, ignore_shuttle_interior = FALSE)
	if(!M || M.anchored || istype(M, /obj/docking_port))
		return
	if(M.GetComponent(/datum/component/shuttle_cling))
		return
	if(HAS_TRAIT(M, TRAIT_FREE_HYPERSPACE_MOVEMENT) || HAS_TRAIT(M, TRAIT_FREE_HYPERSPACE_SOFTCORDON_MOVEMENT))
		return
	// Transit floor inside a moving shuttle should not add extra drift (items get flung into open hyperspace).
	if(!ignore_shuttle_interior && SSshuttle.is_in_shuttle_bounds(M))
		return
	var/turf/open/space/transit/T = get_turf(M)
	if(!istype(T))
		return
	M.inertia_dir = 0
	M.AddComponent(/datum/component/shuttle_cling, REVERSE_DIR(T.dir))

/// Next tick — avoids running AddComponent(shuttle_cling) synchronously inside shuttle event spawn (same MC tick as SSshuttle.fire).
/proc/deferred_init_shuttle_cling_for_event(datum/weakref/wref)
	var/atom/movable/M = wref?.resolve()
	if(QDELETED(M) || !ismovable(M) || M.anchored)
		return
	if(istype(get_turf(M), /turf/open/space/transit))
		init_shuttle_cling(M, TRUE)

/turf/open/space/transit/Entered(atom/movable/AM, atom/OldLoc)
	. = ..()
	init_shuttle_cling(AM)

/turf/open/space/transit/Exited(atom/movable/gone, direction)
	. = ..()
	if(!istype(gone.loc, /turf/open/space/transit))
		var/datum/component/shuttle_cling/cling = gone.GetComponent(/datum/component/shuttle_cling)
		if(cling)
			qdel(cling)

/turf/open/space/transit/CanBuildHere()
	return SSshuttle.is_in_shuttle_bounds(src)


/turf/open/space/transit/Initialize(mapload)
	. = ..()
	update_icon()
	for(var/atom/movable/AM in src)
		init_shuttle_cling(AM)

/turf/open/space/transit/update_icon()
	. = ..()
	transform = turn(matrix(), get_transit_angle(src))

/turf/open/space/transit/update_icon_state()
	icon_state = "speedspace_ns_[get_transit_state(src)]"

/proc/get_transit_state(turf/T)
	var/p = 9
	. = 1
	switch(T.dir)
		if(NORTH)
			. = ((-p*T.x+T.y) % 15) + 1
			if(. < 1)
				. += 15
		if(EAST)
			. = ((T.x+p*T.y) % 15) + 1
		if(WEST)
			. = ((T.x-p*T.y) % 15) + 1
			if(. < 1)
				. += 15
		else
			. = ((p*T.x+T.y) % 15) + 1

/proc/get_transit_angle(turf/T)
	. = 0
	switch(T.dir)
		if(NORTH)
			. = 180
		if(EAST)
			. = 90
		if(WEST)
			. = -90

///Dump a movable in a random valid spacetile
/proc/dump_in_space(atom/movable/dumpee)
	if(HAS_TRAIT(dumpee, TRAIT_DEL_ON_SPACE_DUMP))
		qdel(dumpee)
		return

	var/max = world.maxx-TRANSITIONEDGE
	var/min = 1+TRANSITIONEDGE

	var/list/possible_transtitons = list()
	for(var/datum/space_level/level as anything in SSmapping.z_list)
		if (level.linkage == CROSSLINKED)
			possible_transtitons += level.z_value
	if(!length(possible_transtitons)) //No space to throw them to - try throwing them onto mining
		possible_transtitons = SSmapping.levels_by_trait(ZTRAIT_MINING)
		if(!length(possible_transtitons)) //Just throw them back on station, if not just runtime.
			possible_transtitons = SSmapping.levels_by_trait(ZTRAIT_STATION)

	//move the dumpee to a random coordinate turf
	dumpee.forceMove(locate(rand(min,max), rand(min,max), pick(possible_transtitons)))
