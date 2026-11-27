
//Yes, they can only be rectangular.
//Yes, I'm sorry.
/datum/turf_reservation
	var/list/reserved_turfs = list()
	var/width = 0
	var/height = 0
	var/bottom_left_coords[3]
	var/top_right_coords[3]
	var/wipe_reservation_on_release = TRUE
	var/turf_type = /turf/open/space
	var/borderturf
	/// Additional flags passed to ChangeTurf during Reserve()
	var/changeturf_flags = CHANGETURF_SKIP

/datum/turf_reservation/transit
	turf_type = /turf/open/space/transit
	borderturf = /turf/open/space/transit/border

/datum/turf_reservation/proc/Release()
	SSmapping.used_turfs -= reserved_turfs // bulk removal — O(n) instead of O(n²)
	SSmapping.reserve_turfs(reserved_turfs)
	reserved_turfs.Cut()

/datum/turf_reservation/transit/Release()
	for(var/turf/open/space/transit/T in reserved_turfs)
		for(var/atom/movable/AM in T)
			dump_in_space(AM)
	. = ..()

/datum/turf_reservation/proc/Reserve(width, height, zlevel)
	if(width > world.maxx || height > world.maxy || width < 1 || height < 1)
		return FALSE
	var/list/avail = SSmapping.unused_turfs["[zlevel]"]
	var/turf/BL
	var/turf/TR
	var/list/turf/final = list()
	var/passing = FALSE
	for(var/i in avail)
		CHECK_TICK
		BL = i
		if(!(BL.flags_1 & UNUSED_RESERVATION_TURF_1))
			continue
		if(BL.x + width > world.maxx || BL.y + height > world.maxy)
			continue
		TR = locate(BL.x + width - 1, BL.y + height - 1, BL.z)
		if(!(TR.flags_1 & UNUSED_RESERVATION_TURF_1))
			continue
		final = block(BL, TR)
		if(!final)
			continue
		passing = TRUE
		for(var/I in final)
			var/turf/checking = I
			if(!(checking.flags_1 & UNUSED_RESERVATION_TURF_1))
				passing = FALSE
				break
		if(!passing)
			continue
		break
	if(!passing || !istype(BL) || !istype(TR))
		return FALSE
	bottom_left_coords = list(BL.x, BL.y, BL.z)
	top_right_coords = list(TR.x, TR.y, TR.z)
	for(var/i in final)
		var/turf/T = i
		reserved_turfs += T // block() guarantees unique turfs — no dedup needed
		T.flags_1 &= ~UNUSED_RESERVATION_TURF_1
		SSmapping.used_turfs[T] = src
		if(borderturf && (T.x == BL.x || T.x == TR.x || T.y == BL.y || T.y == TR.y))
			T.ChangeTurf(borderturf, borderturf, changeturf_flags)
		else
			T.ChangeTurf(turf_type, turf_type, changeturf_flags)
	// `-=` сдвигает хвост пула за каждую выданную клетку; проход с фильтром по флагу линеен.
	var/list/still_unused = list()
	for(var/turf/free as anything in avail)
		if(free.flags_1 & UNUSED_RESERVATION_TURF_1)
			still_unused += free
	SSmapping.unused_turfs["[BL.z]"] = still_unused
	src.width = width
	src.height = height
	return TRUE

/**
 * Reserves an exact rectangle on one z-level.
 *
 * Reserve() picks the first free block it can find, which is fine for a single
 * level but cannot line several levels of a multi-level map up over the same
 * coordinates. Callers that already know where the block has to go use this
 * instead; every turf is checked against the same unused pool Reserve() reads.
 */
/datum/turf_reservation/proc/ReserveArea(width, height, zlevel, x, y)
	if(width > world.maxx || height > world.maxy || width < 1 || height < 1)
		return FALSE
	if(x < 1 || y < 1 || x + width - 1 > world.maxx || y + height - 1 > world.maxy)
		return FALSE
	var/list/avail = SSmapping.unused_turfs["[zlevel]"]
	if(!length(avail))
		return FALSE
	var/turf/BL = locate(x, y, zlevel)
	var/turf/TR = locate(x + width - 1, y + height - 1, zlevel)
	if(!istype(BL) || !istype(TR))
		return FALSE
	var/list/final = block(BL, TR)
	if(!final)
		return FALSE
	for(var/I in final)
		var/turf/checking = I
		if(!(checking.flags_1 & UNUSED_RESERVATION_TURF_1))
			return FALSE
	bottom_left_coords = list(BL.x, BL.y, BL.z)
	top_right_coords = list(TR.x, TR.y, TR.z)
	for(var/i in final)
		var/turf/T = i
		reserved_turfs += T
		T.flags_1 &= ~UNUSED_RESERVATION_TURF_1
		SSmapping.used_turfs[T] = src
		if(borderturf && (T.x == BL.x || T.x == TR.x || T.y == BL.y || T.y == TR.y))
			T.ChangeTurf(borderturf, borderturf, changeturf_flags)
		else
			T.ChangeTurf(turf_type, turf_type, changeturf_flags)
	// Same linear rebuild Reserve() does, for the same reason.
	var/list/still_unused = list()
	for(var/turf/free as anything in avail)
		if(free.flags_1 & UNUSED_RESERVATION_TURF_1)
			still_unused += free
	SSmapping.unused_turfs["[zlevel]"] = still_unused
	src.width = width
	src.height = height
	return TRUE

/datum/turf_reservation/New()
	LAZYADD(SSmapping.turf_reservations, src)

/datum/turf_reservation/Destroy()
	SSmapping.used_turfs -= reserved_turfs
	for(var/turf/reserved as anything in reserved_turfs)
		free_turf(reserved)
	reserved_turfs.Cut()
	LAZYREMOVE(SSmapping.turf_reservations, src)
	return ..()

/datum/turf_reservation/proc/free_turf(turf/reserved)
	LAZYINITLIST(SSmapping.unused_turfs["[reserved.z]"])
	SSmapping.unused_turfs["[reserved.z]"] += reserved
	reserved.flags_1 |= UNUSED_RESERVATION_TURF_1
	GLOB.areas_by_type[world.area].contents += reserved
	reserved.ChangeTurf(turf_type, turf_type, changeturf_flags)

/// Освобождает клетки по частям между тиками и удаляет резервацию, когда отдаст последнюю.
/datum/turf_reservation/proc/release_gradually()
	set waitfor = FALSE
	while(length(reserved_turfs))
		var/turf/reserved = reserved_turfs[1]
		reserved_turfs.Cut(1, 2)
		SSmapping.used_turfs -= reserved
		free_turf(reserved)
		CHECK_TICK
		if(QDELETED(src))
			return
	qdel(src)

/datum/turf_reservation/transit/Destroy()
	for(var/turf/open/space/transit/T in reserved_turfs)
		for(var/atom/movable/AM in T)
			dump_in_space(AM)
	. = ..()
