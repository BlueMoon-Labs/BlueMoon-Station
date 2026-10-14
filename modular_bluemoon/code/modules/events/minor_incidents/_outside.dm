/// Запас вокруг стоянки шаттла: прилетевший шаттл не должен давить находку.
#define OUTSIDE_DOCK_MARGIN 3

/// Происшествие с объектом снаружи станции. Место ищется и в preflight, и при запуске.
/datum/round_event_control/minor_outside
	weight = 15
	max_occurrences = 1
	earliest_start = 20 MINUTES
	severity = DIRECTOR_SEVERITY_MINOR
	category = EVENT_CATEGORY_FRIENDLY
	intensity_linger = 4 MINUTES
	var/announcement_title = ""
	var/announcement_text = ""

/datum/round_event_control/minor_outside/proc/find_site(first_only = FALSE)
	return null

/datum/round_event_control/minor_outside/proc/get_announcement_text()
	return announcement_text

/datum/round_event_control/minor_outside/director_preflight()
	var/turf/site = find_site(first_only = TRUE)
	director_preflight_detail = site ? "Есть место для находки." : "Нет подходящего места снаружи станции."
	director_preflight_failure = site ? null : director_preflight_detail
	return !isnull(site)

/datum/round_event_control/minor_outside/execute_action()
	if(!director_preflight())
		return FALSE
	return ..()

/datum/round_event/minor_outside
	fakeable = FALSE
	var/datum/weakref/spawned_ref
	var/site_description

/datum/round_event/minor_outside/start()
	var/datum/round_event_control/minor_outside/outside = control
	if(!istype(outside))
		return
	var/turf/site = outside.find_site()
	if(!site)
		log_game("DIRECTOR: [control.name], подходящее место не найдено, событие не состоялось.")
		return
	var/atom/movable/created = spawn_at(site)
	if(QDELETED(created))
		return
	spawned_ref = WEAKREF(created)
	site_description = describe_site(site)
	log_game("DIRECTOR: [control.name], [created] появляется в [AREACOORD(site)].")

/datum/round_event/minor_outside/announce(fake)
	if(!spawned_ref?.resolve())
		return
	var/datum/round_event_control/minor_outside/outside = control
	priority_announce(build_announcement(outside.get_announcement_text()), outside.announcement_title)

/datum/round_event/minor_outside/proc/build_announcement(text)
	return site_description ? "[text] [site_description]" : text

/datum/round_event/minor_outside/proc/spawn_at(turf/site)
	return null

/datum/round_event/minor_outside/proc/describe_site(turf/site)
	return null

/// Космическая клетка в min_dist..max_dist клетках от обшивки, рядом с внешним шлюзом станции.
/proc/outside_find_hull_space(min_dist, max_dist, first_only = FALSE)
	var/list/airlock_turfs = list()
	for(var/obj/machinery/door/airlock/external/airlock in GLOB.airlocks)
		var/turf/airlock_turf = get_turf(airlock)
		if(!airlock_turf || !is_station_level(airlock_turf.z) || istype(airlock_turf.loc, /area/shuttle))
			continue
		airlock_turfs |= airlock_turf
	shuffle_inplace(airlock_turfs)
	for(var/turf/airlock_turf as anything in airlock_turfs)
		var/list/candidates = list()
		for(var/turf/open/space/candidate in RANGE_TURFS(max_dist, airlock_turf))
			if(get_dist(candidate, airlock_turf) < min_dist || !outside_is_clear_space(candidate, min_dist))
				continue
			if(first_only)
				return candidate
			candidates += candidate
		if(length(candidates))
			return pick(candidates)
		CHECK_TICK
	return null

/// Открытый космос без построек, до ближайшей обшивки не меньше min_dist клеток.
/proc/outside_is_clear_space(turf/candidate, min_dist)
	if(!isspaceturf(candidate) || istype(candidate, /turf/open/space/transit) || !istype(candidate.loc, /area/space))
		return FALSE
	for(var/atom/movable/thing as anything in candidate)
		if(ismob(thing) || isitem(thing) || isstructure(thing) || ismachinery(thing))
			return FALSE
	for(var/turf/nearby as anything in RANGE_TURFS(min_dist - 1, candidate))
		if(!isspaceturf(nearby) || !istype(nearby.loc, /area/space))
			return FALSE
	return !outside_near_dock(candidate)

/proc/outside_near_dock(turf/candidate)
	for(var/obj/docking_port/stationary/port as anything in SSshuttle.stationary)
		if(port.z != candidate.z)
			continue
		var/list/bounds = port.return_coords()
		if(candidate.x < min(bounds[1], bounds[3]) - OUTSIDE_DOCK_MARGIN || candidate.x > max(bounds[1], bounds[3]) + OUTSIDE_DOCK_MARGIN)
			continue
		if(candidate.y < min(bounds[2], bounds[4]) - OUTSIDE_DOCK_MARGIN || candidate.y > max(bounds[2], bounds[4]) + OUTSIDE_DOCK_MARGIN)
			continue
		return TRUE
	return FALSE

/// Ближайший к находке отсек станции, чтобы объявление называло сторону корпуса.
/proc/outside_nearest_station_area(turf/site, radius)
	var/area/nearest
	var/best_distance = INFINITY
	for(var/turf/nearby as anything in RANGE_TURFS(radius, site))
		var/area/nearby_area = nearby.loc
		if(isspaceturf(nearby) || istype(nearby_area, /area/space) || istype(nearby_area, /area/shuttle))
			continue
		var/distance = get_dist(site, nearby)
		if(distance < best_distance)
			best_distance = distance
			nearest = nearby_area
	return nearest

#undef OUTSIDE_DOCK_MARGIN
