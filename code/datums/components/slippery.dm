/datum/component/slippery
	var/intensity
	var/lube_flags
	var/datum/callback/callback
	/// Слоты, из которых надетый предмет делает скользким лежащего носителя.
	var/slot_whitelist = ITEM_SLOT_OCLOTHING | ITEM_SLOT_ICLOTHING | ITEM_SLOT_GLOVES | ITEM_SLOT_FEET | ITEM_SLOT_HEAD | ITEM_SLOT_MASK | ITEM_SLOT_BELT | ITEM_SLOT_NECK

/datum/component/slippery/Initialize(_intensity, _lube_flags = NONE, datum/callback/_callback, _slot_whitelist)
	intensity = max(_intensity, 0)
	lube_flags = _lube_flags
	callback = _callback
	if(_slot_whitelist)
		slot_whitelist = _slot_whitelist
	RegisterSignal(parent, list(COMSIG_MOVABLE_CROSSED, COMSIG_ATOM_ENTERED), PROC_REF(Slip))
	RegisterSignal(parent, COMSIG_ITEM_WEARERCROSSED, PROC_REF(slip_on_wearer))

/datum/component/slippery/proc/slip_on_wearer(obj/item/source, atom/movable/crosser)
	SIGNAL_HANDLER
	if(!(source.current_equipped_slot & slot_whitelist))
		return
	var/mob/living/wearer = source.loc
	if(!istype(wearer) || wearer.body_position != LYING_DOWN || wearer.buckled)
		return
	Slip(source, crosser)

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
