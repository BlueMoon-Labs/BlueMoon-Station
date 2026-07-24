/// Look up levels[z].traits[trait]
/datum/controller/subsystem/mapping/proc/level_trait(z, trait)
	if (!isnum(z) || z < 1)
		return null
	if (z_list)
		if (z > z_list.len)
			stack_trace("Unmanaged z-level [z]! maxz = [world.maxz], z_list.len = [z_list.len]")
			return list()
		// Индексируем z_list напрямую: границы уже проверены выше, а прок
		// зовётся сотнями тысяч раз за инициализацию.
		var/datum/space_level/S = z_list[z]
		return S.traits[trait]
	else
		var/list/default = DEFAULT_MAP_TRAITS
		if (z > default.len)
			stack_trace("Unmanaged z-level [z]! maxz = [world.maxz], default.len = [default.len]")
			return list()
		return default[z][DL_TRAITS][trait]

/// Check if levels[z] has any of the specified traits
/datum/controller/subsystem/mapping/proc/level_has_any_trait(z, list/traits)
	for (var/I in traits)
		if (level_trait(z, I))
			return TRUE
	return FALSE

/// Check if levels[z] has all of the specified traits
/datum/controller/subsystem/mapping/proc/level_has_all_traits(z, list/traits)
	for (var/I in traits)
		if (!level_trait(z, I))
			return FALSE
	return TRUE

/// Get a list of all z which have the specified trait
/datum/controller/subsystem/mapping/proc/levels_by_trait(trait)
	. = list()
	var/list/_z_list = z_list
	for(var/A in _z_list)
		var/datum/space_level/S = A
		if (S.traits[trait])
			. += S.z_value

/// Get a list of all z which have any of the specified traits
/datum/controller/subsystem/mapping/proc/levels_by_any_trait(list/traits)
	. = list()
	var/list/_z_list = z_list
	for(var/A in _z_list)
		var/datum/space_level/S = A
		for (var/trait in traits)
			if (S.traits[trait])
				. += S.z_value
				break

// Get a list of all z which have any of the specified traits
/datum/controller/subsystem/mapping/proc/levels_by_all_trait(list/traits)
	. = list()
	var/list/_z_list = z_list
	for(var/A in _z_list)
		var/datum/space_level/S = A
		. += S.z_value
		for (var/trait in traits)
			if (!S.traits[trait])
				. -= S.z_value
				break

/**
 * Мультиз-связки читает каждый /turf/Initialize и /turf/Destroy, то есть больше
 * миллиона раз за старт мира. Поэтому трейт тут берётся прямым индексом в
 * z_list, а не через level_trait() + get_level(): это те же данные, но без двух
 * вызовов проков на каждый турф. Нештатный z и ещё не поднятый z_list уходят на
 * общий путь level_trait() со всеми его проверками и stack_trace.
 *
 * Attempt to get the turf below the provided one according to Z traits
 */
/datum/controller/subsystem/mapping/proc/get_turf_below(turf/T)
	if (!T)
		return
	var/turf_z = T.z
	var/list/levels = z_list
	var/offset
	if(levels && turf_z >= 1 && turf_z <= levels.len)
		var/datum/space_level/level = levels[turf_z]
		offset = level.traits[ZTRAIT_DOWN]
	else
		offset = level_trait(turf_z, ZTRAIT_DOWN)
	if (!isnum(offset) || !offset)
		return
	return locate(T.x, T.y, turf_z + offset)

/// Attempt to get the turf above the provided one according to Z traits.
/// Быстрый путь такой же, как в [/datum/controller/subsystem/mapping/proc/get_turf_below].
/datum/controller/subsystem/mapping/proc/get_turf_above(turf/T)
	if (!T)
		return
	var/turf_z = T.z
	var/list/levels = z_list
	var/offset
	if(levels && turf_z >= 1 && turf_z <= levels.len)
		var/datum/space_level/level = levels[turf_z]
		offset = level.traits[ZTRAIT_UP]
	else
		offset = level_trait(turf_z, ZTRAIT_UP)
	if (!isnum(offset) || !offset)
		return
	return locate(T.x, T.y, turf_z + offset)

/// Prefer not to use this one too often
/datum/controller/subsystem/mapping/proc/get_station_center()
	var/station_z = levels_by_trait(ZTRAIT_STATION)[1]
	return locate(round(world.maxx * 0.5, 1), round(world.maxy * 0.5, 1), station_z)
