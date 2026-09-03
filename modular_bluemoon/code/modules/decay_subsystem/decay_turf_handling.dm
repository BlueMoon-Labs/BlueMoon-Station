/turf/open/floor
	flags_1 = NO_SCREENTIPS_1 | CAN_BE_DIRTY_1

/turf/open/floor/proc/can_ssdecay_break()
	return TRUE

/turf/open/floor/plating/can_ssdecay_break()
	return FALSE

/turf/open/floor/glass/can_ssdecay_break()
	return FALSE

/turf/open/floor/plating/asteroid/can_ssdecay_break()
	return FALSE

/turf/closed/wall
	flags_1 = CAN_BE_DIRTY_1 | DEFAULT_RICOCHET_1
