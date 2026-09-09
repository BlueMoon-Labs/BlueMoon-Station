/datum/antagonist/nightmare
	name = "Nightmare"
	show_in_antagpanel = FALSE
	show_name_in_check_antagonists = TRUE
	threat = 5
	show_to_ghosts = TRUE
	ui_name = "AntagInfoNightmare"
	suicide_cry = "FOR THE DARKNESS!!"

/**
 * Годится ли турф под появление кошмара.
 *
 * Темнота меряется тем же порогом, что и лечение/уворот теневых видов, - если турф проходит
 * проверку, кошмар на нём сразу дееспособен. Космос отсекаем отдельно: открытый турф в вакууме
 * формально бывает тёмным, но кошмара оттуда просто уносит инерцией.
 */
/proc/is_valid_nightmare_spawn(turf/candidate)
	if(!isopenturf(candidate) || isspaceturf(candidate))
		return FALSE
	if(!is_station_level(candidate.z))
		return FALSE
	if(candidate.is_blocked_turf())
		return FALSE
	return candidate.get_lumcount() < SHADOW_SPECIES_LIGHT_THRESHOLD

/**
 * Возвращает турф, на котором можно выпустить кошмара, либо null, если темноты на станции нет.
 *
 * Первый проход - исторический пул лендмарков xeno_spawn. На Боксе и Мете часть точек стоит
 * в неосвещённых тупиках техтоннелей, и поведение там остаётся ровно прежним.
 *
 * Второй проход нужен из-за Дельты: там все 24 точки xeno_spawn стоят в 0-3 тайлах от исправной
 * лампы (ближайшая освещённость 0.15 при пороге 0.05), поэтому первый проход не находил ничего
 * и спавн отменялся каждый раз. Тёмные турфы на карте при этом есть - их больше восьмисот,
 * и почти все в техтоннелях, то есть ровно там, где кошмару и место.
 */
/proc/find_nightmare_spawn()
	var/list/candidates = list()
	for(var/turf/landmark_turf as anything in GLOB.xeno_spawn)
		if(is_valid_nightmare_spawn(landmark_turf))
			candidates += landmark_turf
	if(length(candidates))
		return pick(candidates)

	for(var/area/maintenance/maintenance_area in GLOB.all_areas)
		for(var/turf/maintenance_turf in maintenance_area)
			if(is_valid_nightmare_spawn(maintenance_turf))
				candidates += maintenance_turf
	if(!length(candidates))
		return null
	return pick(candidates)

/**
 * Пишет в лог, если кошмара пришлось выпускать мимо исторических точек xeno_spawn.
 *
 * Зовётся только там, где кошмар действительно создан: find_nightmare_spawn() дёргает и
 * ready() динамики, и лог из самого поиска утверждал бы, что точка выбрана, в проверках,
 * после которых никто никуда не спавнится.
 */
/proc/log_nightmare_spawn(turf/chosen)
	if(!chosen || (chosen in GLOB.xeno_spawn))
		return
	log_game("NIGHTMARE: среди [length(GLOB.xeno_spawn)] точек xeno_spawn тёмной не нашлось, кошмар выпущен в техтоннелях ([AREACOORD(chosen)]).")
