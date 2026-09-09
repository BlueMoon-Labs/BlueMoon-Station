/atom/movable/screen/fullscreen/scaled/psydon
	icon = 'modular_bluemoon/icons/effects/psydon_fullscreen.dmi'
	icon_state = "hey"
	layer = CRIT_LAYER
	plane = FULLSCREEN_PLANE
	size_x = 15
	size_y = 15

/atom/movable/screen/fullscreen/scaled/psydon/SetSeverity(severity)
	src.severity = severity
	icon_state = initial(icon_state)

/// Brief divine flash + clear, ported from Roguetown's psydo_nyte().
/mob/proc/psydo_nyte()
	sleep(0.2 SECONDS)
	if(QDELETED(src))
		return
	overlay_fullscreen("psydon", /atom/movable/screen/fullscreen/scaled/psydon)
	sleep(0.2 SECONDS)
	if(QDELETED(src))
		return
	clear_fullscreen("psydon")
