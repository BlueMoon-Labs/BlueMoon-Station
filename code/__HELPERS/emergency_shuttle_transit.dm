/**
 * Emergency escape shuttle is flying through reserved hyperspace transit
 * (between station dock and CentCom / end destination).
 */
/proc/emergency_shuttle_in_transit()
	if(!SSshuttle?.emergency)
		return FALSE
	var/obj/docking_port/stationary/docked = SSshuttle.emergency.get_docked()
	return istype(docked, /obj/docking_port/stationary/transit)

/**
 * While the shuttle is in transit, dangerous random events get a lower pick weight (not zero).
 * Strongest reduction for space threats (meteors, dust, rods, rad storms).
 */
/proc/shuttle_transit_random_event_weight_mult(datum/round_event_control/E)
	if(!istype(E))
		return 1
	if(E.category == EVENT_CATEGORY_SPACE)
		return 0.12
	if(E.category == EVENT_CATEGORY_INVASION)
		return 0.25
	if(istype(E, /datum/round_event_control/supernova))
		return 0.25
	if(istype(E, /datum/round_event_control/carp_migration) || istype(E, /datum/round_event_control/space_dragon) || istype(E, /datum/round_event_control/rogue_drone) || istype(E, /datum/round_event_control/blob))
		return 0.3
	return 1
