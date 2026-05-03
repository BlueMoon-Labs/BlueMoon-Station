
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
	var/list/avail_turfs = SSmapping.unused_turfs["[BL.z]"]
	for(var/i in final)
		var/turf/T = i
		reserved_turfs += T // block() guarantees unique turfs — no dedup needed
		T.flags_1 &= ~UNUSED_RESERVATION_TURF_1
		SSmapping.used_turfs[T] = src
		if(borderturf && (T.x == BL.x || T.x == TR.x || T.y == BL.y || T.y == TR.y))
			T.ChangeTurf(borderturf, borderturf, changeturf_flags)
		else
			T.ChangeTurf(turf_type, turf_type, changeturf_flags)
	avail_turfs -= final // single bulk O(n+m) instead of per-element O(n*m)
	src.width = width
	src.height = height
	return TRUE

/datum/turf_reservation/New()
	LAZYADD(SSmapping.turf_reservations, src)

/datum/turf_reservation/Destroy()
	Release()
	LAZYREMOVE(SSmapping.turf_reservations, src)
	return ..()
