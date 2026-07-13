SUBSYSTEM_DEF(icon_smooth)
	name = "Icon Smoothing"
	init_order = INIT_ORDER_ICON_SMOOTHING
	wait = 1
	priority = FIRE_PRIOTITY_SMOOTHING
	flags = SS_TICKER

	var/list/smooth_queue = list()
	var/list/deferred = list()

/datum/controller/subsystem/icon_smooth/fire()
	var/list/cached = smooth_queue
	while(cached.len)
		var/atom/A = cached[cached.len]
		cached.len--
		if(QDELETED(A))
			continue
		if(A.smoothing_flags & USES_SMOOTHING)
			if(!(A.smoothing_flags & SMOOTH_QUEUED))
				continue
			if(A.flags_1 & INITIALIZED_1)
				A.smooth_icon_bitmask()
			else
				deferred += A
		else if(A.smooth)
			if(A.flags_1 & INITIALIZED_1)
				smooth_icon(A)
			else
				deferred += A
		if(MC_TICK_CHECK)
			return

	if(!cached.len)
		if(deferred.len)
			smooth_queue = deferred
			deferred = cached
		else
			can_fire = 0

/datum/controller/subsystem/icon_smooth/Initialize()
	smooth_zlevel(1, TRUE)
	smooth_zlevel(2, TRUE)
	smooth_zlevel_bitmask(1, TRUE)
	smooth_zlevel_bitmask(2, TRUE)
	var/queue = smooth_queue
	smooth_queue = list()
	for(var/V in queue)
		var/atom/A = V
		if(!A || A.z <= 2)
			continue
		if(A.smoothing_flags & USES_SMOOTHING)
			if(A.smoothing_flags & SMOOTH_QUEUED)
				A.smooth_icon_bitmask()
		else if(A.smooth)
			smooth_icon(A)
		CHECK_TICK

	return ..()

/datum/controller/subsystem/icon_smooth/proc/add_to_queue(atom/thing)
	if(thing.smoothing_flags & SMOOTH_QUEUED)
		return
	thing.smoothing_flags |= SMOOTH_QUEUED
	smooth_queue += thing
	can_fire = 1
