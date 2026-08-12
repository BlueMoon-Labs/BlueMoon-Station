SUBSYSTEM_DEF(pathfinder)
	name = "Pathfinder"
	init_order = INIT_ORDER_PATH
	flags = SS_NO_FIRE
	var/datum/flowcache/mobs
	var/datum/flowcache/circuits
	var/static/space_type_cache

/datum/controller/subsystem/pathfinder/Initialize()
	space_type_cache = typecacheof(/turf/open/space)
	mobs = new(10)
	circuits = new(3)
	return ..()

/datum/flowcache
	var/lcount
	var/run
	var/free
	var/list/flow

/// Opaque generation token for one pathfinder slot. A timed-out request may
/// finish much later; the token prevents it from releasing a newer occupant.
/datum/pathfinder_lease
	var/datum/flowcache/cache
	var/slot
	var/timer
	var/atom/owner

/datum/pathfinder_lease/Destroy(force, ...)
	if(timer)
		deltimer(timer)
	timer = null
	cache = null
	owner = null
	return ..()

/datum/flowcache/New(n)
	. = ..()
	lcount = n
	run = 0
	free = 1
	flow = new/list(lcount)

/datum/flowcache/Destroy(force, ...)
	for(var/datum/pathfinder_lease/lease as anything in flow)
		qdel(lease)
	flow = null
	return ..()

/datum/flowcache/proc/getfree(atom/M)
	if(run < lcount)
		run += 1
		while(flow[free])
			CHECK_TICK
			free = (free % lcount) + 1
		var/datum/pathfinder_lease/lease = new
		lease.cache = src
		lease.slot = free
		lease.owner = M
		lease.timer = addtimer(CALLBACK(src, TYPE_PROC_REF(/datum/flowcache, toolong), lease), 150, TIMER_STOPPABLE)
		flow[free] = lease
		return lease
	else
		return FALSE

/datum/flowcache/proc/toolong(datum/pathfinder_lease/lease)
	if(QDELETED(lease) || lease.cache != src || flow[lease.slot] != lease)
		return
	log_game("Pathfinder route took longer than 150 ticks, src bot [lease.owner]")
	found(lease, FALSE, FALSE)

/datum/flowcache/proc/found(datum/pathfinder_lease/lease, cancel_timer = TRUE, delete_lease = TRUE)
	if(QDELETED(lease))
		return
	if(lease.cache != src || flow[lease.slot] != lease)
		// A timeout already released this generation. Its original request owns
		// the last reference and disposes the token when it eventually returns.
		if(!lease.cache && delete_lease)
			qdel(lease)
		return
	if(cancel_timer)
		deltimer(lease.timer)
	flow[lease.slot] = null
	run = max(run - 1, 0)
	lease.cache = null
	lease.owner = null
	lease.timer = null
	if(delete_lease)
		qdel(lease)
