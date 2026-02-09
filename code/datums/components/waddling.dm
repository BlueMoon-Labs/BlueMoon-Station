/datum/component/waddling
	dupe_mode = COMPONENT_DUPE_UNIQUE_PASSARGS

/datum/component/waddling/Initialize()
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE
	RegisterSignal(parent, list(COMSIG_MOVABLE_MOVED), PROC_REF(Waddle))

/datum/component/waddling/proc/Waddle()
	var/mob/living/L = parent
	if(L.incapacitated() || L.lying)
		return
	var/prev_pixel_z = L.pixel_z
	var/matrix/otransform = matrix(L.transform) //make a copy of the current transform
	animate(L, pixel_z = prev_pixel_z + 4, time = 0)
	animate(pixel_z = prev_pixel_z, transform = turn(L.transform, pick(-12, 0, 12)), time=2) //waddle.
	animate(pixel_z = prev_pixel_z, transform = otransform, time = 0) //return to previous transform.
