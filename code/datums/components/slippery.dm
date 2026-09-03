/datum/component/slippery
	var/intensity
	var/lube_flags
	var/datum/callback/callback

/datum/component/slippery/Initialize(_intensity, _lube_flags = NONE, datum/callback/_callback)
	intensity = max(_intensity, 0)
	lube_flags = _lube_flags
	callback = _callback
	RegisterSignal(parent, list(COMSIG_MOVABLE_CROSSED, COMSIG_ATOM_ENTERED, COMSIG_ITEM_WEARERCROSSED), PROC_REF(Slip))

/datum/component/slippery/proc/Slip(datum/source, atom/movable/AM)
	var/mob/victim = AM
	if(!istype(victim))
		return
	var/datum/forced_movement/in_flight = victim.force_moving
	// Уже катящегося не стануем и не роняем заново: каждая пройденная смазанная клетка
	// продлевает текущее качение, пока впереди луб. Дорожка кончилась - катящийся ещё
	// пролетает пару-тройку клеток по инерции, и там качение само останавливается.
	if(in_flight && (lube_flags & SLIDE) && istype(in_flight.target, /turf))
		var/turf/open/slip_turf = parent
		var/slide_dir = get_dir(get_turf(victim), in_flight.target)
		if(istype(slip_turf) && slide_dir && !(slide_dir & (slide_dir - 1))) // только прямые направления, без диагоналей
			in_flight.target = get_ranged_target_turf(victim, slide_dir, max(1, slip_turf.lube_slide_run(slide_dir) + 1 + rand(2, 3)))
			return
	if(victim.slip(intensity, parent, lube_flags) && callback)
		callback.Invoke(victim)
