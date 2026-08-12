/// Opt-in processing for atoms which must keep reacting after their turf rests.
/datum/element/atmos_sensitive
	element_flags = ELEMENT_DETACH

/// Registers an opt-in exposure listener while maintaining a cheap turf-side
/// gate list for the SSair hot path. The list is keyed by listener so removal
/// is exact, and ChangeTurf carries it (and re-registers every listener) onto
/// the replacement turf - see /turf/proc/ChangeTurf.
/datum/proc/register_turf_exposure(turf/open/target, handler)
	if(!istype(target))
		return
	LAZYSET(target.atmos_exposure_listeners, src, handler)
	RegisterSignal(target, COMSIG_TURF_EXPOSE, handler, override = TRUE)

/// Exact removal: only a listener that actually holds a registration on this
/// turf may drop it, so one owner's Destroy can never sever another's.
/datum/proc/unregister_turf_exposure(turf/target)
	if(!istype(target) || !LAZYACCESS(target.atmos_exposure_listeners, src))
		return
	LAZYREMOVE(target.atmos_exposure_listeners, src)
	UnregisterSignal(target, COMSIG_TURF_EXPOSE)

/datum/element/atmos_sensitive/Attach(datum/target, mapload)
	if(!isatom(target))
		return ELEMENT_INCOMPATIBLE
	var/atom/to_track = target
	if(isopenturf(to_track.loc))
		to_track.register_turf_exposure(to_track.loc, TYPE_PROC_REF(/atom, check_atmos_process))
	if(ismovable(to_track))
		RegisterSignal(to_track, COMSIG_MOVABLE_MOVED, PROC_REF(react_to_move))
	if(!mapload && isopenturf(to_track.loc))
		to_track.atmos_conditions_changed()
	return ..()

/datum/element/atmos_sensitive/Detach(atom/source)
	if(isturf(source.loc))
		source.unregister_turf_exposure(source.loc)
	UnregisterSignal(source, COMSIG_MOVABLE_MOVED)
	if(source.flags_1 & ATMOS_IS_PROCESSING_1)
		source.atmos_end()
		SSair.atom_process -= source
		source.flags_1 &= ~ATMOS_IS_PROCESSING_1
	return ..()

/datum/element/atmos_sensitive/proc/react_to_move(atom/source, atom/oldloc)
	SIGNAL_HANDLER
	if(isturf(oldloc))
		source.unregister_turf_exposure(oldloc)
	if(isopenturf(source.loc))
		source.register_turf_exposure(source.loc, TYPE_PROC_REF(/atom, check_atmos_process))
	source.atmos_conditions_changed()

/atom/proc/atmos_conditions_changed()
	var/turf/open/spot = loc
	if(istype(spot) && spot.air)
		check_atmos_process(spot, spot.air, spot.air.return_temperature())
	else if(flags_1 & ATMOS_IS_PROCESSING_1)
		atmos_end()
		SSair.atom_process -= src
		flags_1 &= ~ATMOS_IS_PROCESSING_1

/atom/proc/check_atmos_process(datum/source, datum/gas_mixture/exposed_air, exposed_temperature)
	SIGNAL_HANDLER
	if(should_atmos_process(exposed_air, exposed_temperature))
		if(flags_1 & ATMOS_IS_PROCESSING_1)
			return
		SSair.atom_process += src
		flags_1 |= ATMOS_IS_PROCESSING_1
	else if(flags_1 & ATMOS_IS_PROCESSING_1)
		atmos_end()
		SSair.atom_process -= src
		flags_1 &= ~ATMOS_IS_PROCESSING_1

/atom/proc/process_exposure()
	var/turf/open/spot = loc
	if(!istype(spot) || !should_atmos_process(spot.air, spot.air.return_temperature()))
		atmos_end()
		SSair.atom_process -= src
		flags_1 &= ~ATMOS_IS_PROCESSING_1
		return
	atmos_expose(spot.air, spot.air.return_temperature())

/atom/proc/should_atmos_process(datum/gas_mixture/exposed_air, exposed_temperature)
	return FALSE

/atom/proc/atmos_expose(datum/gas_mixture/exposed_air, exposed_temperature)
	return

/atom/proc/atmos_end()
	return
