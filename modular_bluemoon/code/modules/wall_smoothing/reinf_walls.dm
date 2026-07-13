/turf/closed/wall/r_wall/update_icon(updates = ALL)
	. = ..()
	if(d_state != INTACT)
		smoothing_flags &= ~USES_SMOOTHING
		clear_smooth_overlays()
	else
		smoothing_flags |= SMOOTH_BITMASK | SMOOTH_OBJ
		QUEUE_SMOOTH_NEIGHBORS(src)
		QUEUE_SMOOTH(src)

/turf/closed/wall/r_wall/update_icon_state()
	if(d_state != INTACT)
		icon = 'modular_bluemoon/icons/turf/walls/reinforced_states.dmi'
		icon_state = "[base_decon_state]-[d_state]"
	else
		icon = initial(icon)
		icon_state = "[base_icon_state]-[smoothing_junction]"
	return ..()
