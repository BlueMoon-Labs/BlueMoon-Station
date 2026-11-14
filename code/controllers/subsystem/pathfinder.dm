///Сколько поиск держит слот, прежде чем слот отберут и поиск запишут в game.log
#define PATHFINDER_LEASE_TIMEOUT (15 SECONDS)

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

/datum/controller/subsystem/pathfinder/stat_entry(msg)
	var/datum/ai_metrics/metrics = GLOB.ai_metrics
	if(metrics)
		msg = "Поиски:[metrics.jps_searches]|Уступки:[metrics.jps_yields]|Брошено:[metrics.jps_aborted]|Тиков ср:[metrics.jps_searches ? round(metrics.jps_search_ticks / metrics.jps_searches, 0.1) : 0] макс:[metrics.jps_search_ticks_max]"
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
	///Поиск, который держит слот: для строки о слишком долгом поиске
	var/datum/pathfind/search

/datum/pathfinder_lease/Destroy(force, ...)
	if(timer)
		deltimer(timer)
	timer = null
	cache = null
	owner = null
	search = null
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
		lease.timer = addtimer(CALLBACK(src, TYPE_PROC_REF(/datum/flowcache, toolong), lease), PATHFINDER_LEASE_TIMEOUT, TIMER_STOPPABLE)
		flow[free] = lease
		return lease
	else
		return FALSE

/datum/flowcache/proc/toolong(datum/pathfinder_lease/lease)
	if(QDELETED(lease) || lease.cache != src || flow[lease.slot] != lease)
		return
	log_game(toolong_message(lease))
	found(lease, FALSE, FALSE)

/datum/flowcache/proc/toolong_message(datum/pathfinder_lease/lease)
	return "Pathfinder route took longer than [PATHFINDER_LEASE_TIMEOUT / (1 SECONDS)] seconds, src bot [lease.owner], radius [lease.search?.max_distance], yields [lease.search?.yields]"

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
	lease.search = null
	lease.timer = null
	if(delete_lease)
		qdel(lease)

#undef PATHFINDER_LEASE_TIMEOUT
