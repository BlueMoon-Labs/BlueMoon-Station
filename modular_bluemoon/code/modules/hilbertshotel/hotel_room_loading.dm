/// Сколько DM-работы загрузка комнаты делает за тик. Обычный CHECK_TICK вне МК отпускает тик
/// только на ~98%, и заселение держало тик всем игрокам по 50-170 мс.
#define HILBERT_ROOM_SLICE_MS 15

/datum/map_template/hilbertshotel
	// Разбор .dmm и кэш моделей живут весь раунд: без этого каждое заселение заново разбирало файл
	keep_cached_map = TRUE
	/// Самый долгий непрерывный кусок последней загрузки комнаты, мс
	var/last_room_slice_ms = 0
	/// Сколько раз последняя загрузка комнаты уступила тик
	var/last_room_yields = 0

/// Состояние одной загрузки: шаблон один на всех, а грузить его могут двое сразу
/datum/hilbert_room_load
	var/datum/map_template/hilbertshotel/template
	var/slice_started
	var/slice_world_time
	var/max_slice_ms = 0
	var/yields = 0

/datum/hilbert_room_load/New(datum/map_template/hilbertshotel/template)
	src.template = template
	slice_started = TICK_USAGE
	slice_world_time = world.time

/// Уступает тик, когда кусок вышел за бюджет
/datum/hilbert_room_load/proc/check_slice()
	// Парсер мог уснуть внутри куска сам: тогда TICK_USAGE уже чужого тика
	if(world.time == slice_world_time)
		var/used_ms = TICK_DELTA_TO_MS(TICK_USAGE - slice_started)
		max_slice_ms = max(max_slice_ms, used_ms)
		if(used_ms < HILBERT_ROOM_SLICE_MS && !TICK_CHECK_RESUME)
			return
		yields++
		stoplag()
	slice_started = TICK_USAGE
	slice_world_time = world.time

/datum/hilbert_room_load/proc/finish()
	template.last_room_slice_ms = max_slice_ms
	template.last_room_yields = yields

/**
 * Грузит комнату так же, как load(), но кусками по HILBERT_ROOM_SLICE_MS: тайл за тайлом,
 * затем инициализация атомов по одному. Порядок как у initTemplateBounds(): все Initialize(),
 * потом LateInitialize(), сети и атмос. Шаблоны отеля - один z и ориентация SOUTH.
 */
/datum/map_template/hilbertshotel/proc/load_room(turf/T)
	if(!T || T.x + width - 1 > world.maxx || T.y + height - 1 > world.maxy)
		return FALSE
	var/datum/parsed_map/parsed = cached_map
	if(!parsed)
		parsed = new(file(mappath))
		parsed.template_host = src
		cached_map = parsed
	if(!parsed.parsed_bounds)
		return FALSE
	var/list/model_cache = parsed.build_cache()
	var/max_x = T.x + width - 1
	var/max_y = T.y + height - 1

	for(var/turf/border as anything in block(locate(max(T.x - 1, 1), max(T.y - 1, 1), T.z), locate(min(T.x + width + 1, world.maxx), min(T.y + height + 1, world.maxy), T.z)))
		border.atmos_adjacent_turfs?.Cut()

	var/datum/hilbert_room_load/progress = new(src)
	var/no_changeturf = SSatoms.initialized == INITIALIZATION_INSSATOMS
	var/key_len = parsed.key_len
	// Один кэш зон на всю комнату, иначе каждый кусок завёл бы свою зону
	var/list/area_cache = list()
	var/list/room_bounds = list(INFINITY, INFINITY, T.z, -INFINITY, -INFINITY, T.z)
	SSair.StartLoadingMap()
	Master.StartLoadingMap()
	for(var/datum/grid_set/gridset as anything in parsed.gridSets)
		if(gridset.zcrd != 1)
			continue
		var/placement_y = T.y + gridset.ycrd - 1
		for(var/line in gridset.gridLines)
			var/placement_x = T.x + gridset.xcrd - 1
			for(var/pos = 1 to (length(line) - key_len + 1) step key_len)
				if(placement_x <= max_x && placement_y >= T.y && placement_y <= max_y)
					var/list/model = model_cache[copytext(line, pos, pos + key_len)]
					if(!model)
						Master.StopLoadingMap()
						SSair.StopLoadingMap()
						progress.finish()
						stack_trace("Hilbert's Hotel: в [mappath] ключ без модели")
						return FALSE
					parsed.build_coordinate(area_cache, model, locate(placement_x, placement_y, T.z), no_changeturf, TRUE, 0, FALSE, FALSE, FALSE, FALSE)
					room_bounds[MAP_MINX] = min(room_bounds[MAP_MINX], placement_x)
					room_bounds[MAP_MINY] = min(room_bounds[MAP_MINY], placement_y)
					room_bounds[MAP_MAXX] = max(room_bounds[MAP_MAXX], placement_x)
					room_bounds[MAP_MAXY] = max(room_bounds[MAP_MAXY], placement_y)
					progress.check_slice()
				placement_x++
			placement_y--
	if(room_bounds[MAP_MINX] == INFINITY)
		Master.StopLoadingMap()
		SSair.StopLoadingMap()
		progress.finish()
		return FALSE
	var/turf/low_corner = locate(room_bounds[MAP_MINX], room_bounds[MAP_MINY], T.z)
	var/turf/high_corner = locate(room_bounds[MAP_MAXX], room_bounds[MAP_MAXY], T.z)
	if(!no_changeturf)
		for(var/turf/room_turf as anything in block(low_corner, high_corner))
			room_turf.AfterChange(CHANGETURF_IGNORE_AIR)
			progress.check_slice()
	Master.StopLoadingMap()

	if(!SSmapping.loading_ruins)
		repopulate_sorted_areas()

	var/list/mapload_arg = list(TRUE)
	for(var/turf/room_turf as anything in block(low_corner, high_corner))
		var/list/turf_atoms = list(room_turf) + room_turf.contents
		for(var/atom/thing as anything in turf_atoms)
			if(QDELETED(thing) || (thing.flags_1 & INITIALIZED_1))
				continue
			var/previous_state = SSatoms.initialized
			SSatoms.initialized = INITIALIZATION_INNEW_MAPLOAD
			SSatoms.InitAtom(thing, mapload_arg)
			SSatoms.initialized = previous_state
			progress.check_slice()

	// Атомы уже готовы: остаются LateInitialize(), сети и атмос. Границы читаются до первого сна
	parsed.bounds = room_bounds
	parsed.initTemplateBounds()
	SSair.StopLoadingMap()
	progress.finish()

	log_game("[name] loaded at [T.x],[T.y],[T.z]")
	on_map_loaded(T.z, room_bounds)
	return room_bounds

#undef HILBERT_ROOM_SLICE_MS
