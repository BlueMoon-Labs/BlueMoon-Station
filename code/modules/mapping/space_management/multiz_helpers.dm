/proc/get_step_multiz(ref, dir)
	if(dir & UP)
		dir &= ~UP
		var/turf/above = GET_TURF_ABOVE(get_turf(ref))
		return dir ? get_step(above, dir) : above
	if(dir & DOWN)
		dir &= ~DOWN
		var/turf/below = GET_TURF_BELOW(get_turf(ref))
		return dir ? get_step(below, dir) : below
	return get_step(ref, dir)

/// Связка z-уровней целиком. Кэш SSmapping, а не свежий список: не мутировать.
/proc/get_multiz_accessible_levels(center_z)
	return SSmapping.get_connected_levels(center_z)

/proc/get_dir_multiz(turf/us, turf/them)
	us = get_turf(us)
	them = get_turf(them)
	if(!us || !them)
		return NONE
	if(us.z == them.z)
		return get_dir(us, them)
	else
		var/turf/T = us.above()
		var/dir = NONE
		if(T && (T.z == them.z))
			dir = UP
		else
			T = us.below()
			if(T && (T.z == them.z))
				dir = DOWN
			else
				return get_dir(us, them)
		return (dir | get_dir(us, them))

/turf/proc/above()
	return GET_TURF_ABOVE(src)

/turf/proc/below()
	return GET_TURF_BELOW(src)

