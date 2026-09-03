/**
 * Proximity monitor: fires HasProximity() on a receiver whenever a movable enters range of a tracked host.
 *
 * Signal-based: instead of spawning a physical /obj/effect/abstract/proximity_checker on every turf in
 * range (which churned objects and hard-deleted them), it hooks COMSIG_ATOM_ENTERED on the ring of turfs
 * via /datum/component/connect_range, which also re-registers as the host moves through containers.
 * The old checker object still exists purely as the parent type for the /advanced field engine.
 */
/datum/proximity_monitor
	///The atom we are tracking.
	var/atom/host
	///The atom that will receive HasProximity calls.
	var/atom/hasprox_receiver
	///The range of the proximity monitor. Things moving within it trigger HasProximity calls.
	var/current_range
	///If we don't check turfs in range when the host's loc isn't a turf.
	var/ignore_if_not_on_turf
	///Legacy field retained for the /advanced field engine, which tracks host movement itself.
	var/atom/last_host_loc
	///The signals hooked onto every turf in range via connect_range.
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
	)

/datum/proximity_monitor/New(atom/_host, range, _ignore_if_not_on_turf = TRUE)
	last_host_loc = _host?.loc
	ignore_if_not_on_turf = _ignore_if_not_on_turf
	current_range = range
	SetHost(_host)

/datum/proximity_monitor/proc/SetHost(atom/new_host, atom/new_receiver)
	if(new_host == host)
		return
	if(host)
		UnregisterSignal(host, list(COMSIG_MOVABLE_MOVED, COMSIG_MOVABLE_Z_CHANGED, COMSIG_PARENT_QDELETING))
	if(hasprox_receiver && hasprox_receiver != host)
		UnregisterSignal(hasprox_receiver, COMSIG_PARENT_QDELETING)
	if(new_receiver)
		hasprox_receiver = new_receiver
		if(new_receiver != new_host)
			RegisterSignal(new_receiver, COMSIG_PARENT_QDELETING, PROC_REF(on_host_or_receiver_del))
	else if(hasprox_receiver == host) //Default case
		hasprox_receiver = new_host
	host = new_host
	last_host_loc = host?.loc
	RegisterSignal(host, COMSIG_PARENT_QDELETING, PROC_REF(on_host_or_receiver_del))
	// connect_range (set up in SetRange) already re-registers its turf signals when the host OR any
	// container it is inside moves, so a carried host is followed without a separate connect_containers.
	RegisterSignal(host, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))
	RegisterSignal(host, COMSIG_MOVABLE_Z_CHANGED, PROC_REF(on_z_change))
	SetRange(current_range, TRUE)

/datum/proximity_monitor/proc/on_host_or_receiver_del(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/proximity_monitor/Destroy()
	host = null
	hasprox_receiver = null
	last_host_loc = null
	return ..()

/// Manual API for the /advanced field engine, which overrides this to recalculate its field turfs.
/// Deliberately NOT called from on_moved(): advanced fields are built via make_field() and never pass
/// through SetHost(), so no movement signal is registered on them. Owners with moving hosts pump this
/// themselves (e.g. the peaceborg dampener from its process()).
/datum/proximity_monitor/proc/HandleMove()
	return

/datum/proximity_monitor/proc/SetRange(range, force_rebuild = FALSE)
	if(!force_rebuild && range == current_range)
		return FALSE
	. = TRUE
	current_range = range
	//If the connect_range component exists already, this just updates its range. No errors or duplicates.
	AddComponent(/datum/component/connect_range, host, loc_connections, range, !ignore_if_not_on_turf)

/datum/proximity_monitor/proc/on_moved(atom/movable/source, atom/old_loc)
	SIGNAL_HANDLER
	last_host_loc = host?.loc
	if(source == host)
		hasprox_receiver?.HasProximity(host)

/datum/proximity_monitor/proc/on_z_change()
	SIGNAL_HANDLER
	return

/datum/proximity_monitor/proc/on_entered(atom/source, atom/movable/arrived)
	SIGNAL_HANDLER
	// on_moved already handles the host's own movement; only report OTHER movables entering range.
	if(source == host || arrived == host)
		return
	hasprox_receiver?.HasProximity(arrived)

/**
 * Abstract parent kept only for the /advanced field engine (field_turf / field_edge subtypes).
 * The base proximity_monitor no longer spawns plain checkers - detection is signal-based.
 */
/obj/effect/abstract/proximity_checker
	invisibility = INVISIBILITY_ABSTRACT
	anchored = TRUE
	var/datum/proximity_monitor/monitor

/obj/effect/abstract/proximity_checker/Initialize(mapload, datum/proximity_monitor/_monitor)
	. = ..()
	if(_monitor)
		monitor = _monitor
	else
		stack_trace("proximity_checker created without host")
		return INITIALIZE_HINT_QDEL

/obj/effect/abstract/proximity_checker/Destroy()
	monitor = null
	return ..()

/obj/effect/abstract/proximity_checker/Crossed(atom/movable/AM)
	set waitfor = FALSE
	. = ..()
	monitor?.hasprox_receiver?.HasProximity(AM)

/// After holodeck/thunderdome area copies, re-apply each duplicated host's range so its monitor tracks
/// the copy in the state the copy was left in (perfectcopy overwrites scanning/anchored after Initialize).
/proc/rebuild_duplicated_proximity_monitors(list/atoms)
	for(var/atom/movable/AM as anything in atoms)
		var/datum/proximity_monitor/PM = AM.proximity_monitor
		if(!PM)
			continue
		var/range = PM.current_range
		if(istype(AM, /obj/item/assembly/prox_sensor))
			var/obj/item/assembly/prox_sensor/PS = AM
			range = PS.scanning ? PS.sensitivity : 0
		else if(istype(AM, /obj/machinery/flasher/portable))
			var/obj/machinery/flasher/portable/F = AM
			range = F.anchored ? F.range : 0
		PM.SetRange(range, TRUE)
