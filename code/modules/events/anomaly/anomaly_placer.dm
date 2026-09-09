/datum/anomaly_placer
	var/static/list/allowed_areas

/**
 * Returns an area which is safe to place an anomaly inside.
 *
 * Arguments
 * * fail_silently - вернуть null вместо CRASH(), если подходящей зоны нет. Нужен
 * объявлениям: ложная тревога печатает зону "по возможности" и не имеет права
 * ронять событие рантаймом. Спавну аномалии зона обязана, он остаётся строгим.
 */
/datum/anomaly_placer/proc/findValidArea(fail_silently = FALSE)
	if(!allowed_areas)
		generateAllowedAreas()
	var/list/possible_areas = typecache_filter_list(GLOB.sortedAreas, allowed_areas)
	if (!length(possible_areas))
		if(fail_silently)
			return null
		CRASH("No valid areas for anomaly found.")

	var/area/landing_area = pick(possible_areas)
	var/list/turf_test = get_area_turfs(landing_area)
	if(!turf_test.len)
		if(fail_silently)
			return null
		CRASH("Anomaly : No valid turfs found for [landing_area] - [landing_area.type]")

	return landing_area

/**
 * Returns a turf which is safe to place an anomaly on.
 *
 * Arguments
 * * target_area - Area to return a turf from.
 */
/datum/anomaly_placer/proc/findValidTurf(area/target_area)
	var/list/valid_turfs = list()
	for (var/turf/try_turf as anything in get_area_turfs(target_area))
		if (!is_valid_destination(try_turf))
			continue
		valid_turfs += try_turf

	if (!valid_turfs.len)
		CRASH("Dimensional anomaly attempted to reach invalid location [target_area].")

	return pick(valid_turfs)

/**
 * Returns true if the provided turf is valid to place an anomaly on.
 *
 * Arguments
 * * tested - Turf to try landing on.
 */
/datum/anomaly_placer/proc/is_valid_destination(turf/tested)
	if (isspaceturf(tested))
		return FALSE
	if (tested.is_blocked_turf(exclude_mobs = TRUE))
		return FALSE
	if (islava(tested))
		return FALSE
	if (ischasm(tested))
		return FALSE
	return TRUE

/**
 * Populates the allowed areas list.
 */
/datum/anomaly_placer/proc/generateAllowedAreas()
	//Places that shouldn't explode
	var/static/list/safe_area_types = typecacheof(list(
		/area/ai_monitored/turret_protected/ai,
		/area/ai_monitored/turret_protected/ai_upload,
		/area/engineering,
		/area/solars,
		/area/holodeck,
		/area/maintenance,
	))

	//Subtypes from the above that actually should explode.
	var/static/list/unsafe_area_subtypes = typecacheof(list(/area/engineering/break_room))

	allowed_areas = make_associative(GLOB.the_station_areas) - safe_area_types + unsafe_area_subtypes
