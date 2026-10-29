SUBSYSTEM_DEF(minimaps)
	name = "Minimaps"
	flags = SS_NO_FIRE
	// Спрайты должны получить сглаживание до построения миникарты.
	init_order = INIT_ORDER_ICON_SMOOTHING - 1
	var/list/station_minimaps = list()
	var/datum/minimap_group/station_minimap = null

/datum/controller/subsystem/minimaps/Initialize()
	if(!CONFIG_GET(flag/minimaps_enabled))
		to_chat(world, span_boldwarning("Генерация миникарт отключена."))
		return ..()
	build_minimaps()
	return ..()

/datum/controller/subsystem/minimaps/proc/build_minimaps()
	var/datum/asset/simple/nanomaps/nanomaps = get_asset_datum(/datum/asset/simple/nanomaps)
	var/list/station_maps = list()
	var/list/station_sources = list()
	var/list/map_files = islist(SSmapping.config.map_file) ? SSmapping.config.map_file : list(SSmapping.config.map_file)
	for(var/map_file in map_files)
		var/list/file_maps = nanomaps.map_data["[SSmapping.config.map_path]/[map_file]"]
		if(file_maps)
			station_maps += file_maps
			station_sources += read_source_features("_maps/[SSmapping.config.map_path]/[map_file]")
	for(var/z in SSmapping.levels_by_trait(ZTRAIT_STATION))
		var/station_index = SSmapping.z_to_station_z_index["[z]"]
		var/list/stack = SSmapping.get_connected_levels(z)
		// В LOWMEMORYMODE PNG не собираются: остаётся старая раскраска зон.
		if(!station_index || station_index > length(station_maps))
			log_mapping("Для станционного z=[z] не найдена миникарта NanoMap, строится схема зон.")
			station_minimaps += new /datum/minimap(z, name = "Этаж [stack.Find(z)]", autocrop = FALSE, area_colors = TRUE)
			continue
		var/list/map_data = station_maps[station_index]
		var/datum/asset_cache_item/map_asset = nanomaps.assets[map_data["asset"]]
		station_minimaps += new /datum/minimap(z, x2 = map_data["width"], y2 = map_data["height"], name = "Этаж [stack.Find(z)]", autocrop = FALSE, source_icon = map_asset.resource, area_colors = TRUE, source_tiles = station_sources[station_index])

	// Общая рамка: этажи одной станции совпадают по координатам и масштабу
	var/crop_x1 = world.maxx
	var/crop_y1 = world.maxy
	var/crop_x2 = 1
	var/crop_y2 = 1
	for(var/datum/minimap/floor_map as anything in station_minimaps)
		if(floor_map.minx > floor_map.maxx)
			continue
		crop_x1 = min(crop_x1, floor_map.minx)
		crop_y1 = min(crop_y1, floor_map.miny)
		crop_x2 = max(crop_x2, floor_map.maxx)
		crop_y2 = max(crop_y2, floor_map.maxy)
	if(crop_x1 > crop_x2)
		crop_x1 = 1
		crop_y1 = 1
		crop_x2 = world.maxx
		crop_y2 = world.maxy
	for(var/datum/minimap/floor_map as anything in station_minimaps)
		floor_map.finalize(crop_x1, crop_y1, crop_x2, crop_y2)

	station_minimap = new(station_minimaps, "Карта станции")

// Дополняем статический NanoMap геометрией того же DMM, без пещер и шаттлов другого запуска.
/datum/controller/subsystem/minimaps/proc/read_source_features(map_path)
	var/datum/parsed_map/parsed = new(file(map_path))
	var/list/models = parsed.build_cache()
	var/list/floors = list()
	for(var/datum/grid_set/grid as anything in parsed.gridSets)
		floors.len = max(length(floors), grid.zcrd)
		if(!floors[grid.zcrd])
			floors[grid.zcrd] = list()
		var/list/tiles = floors[grid.zcrd]
		var/y = grid.ycrd
		for(var/line in grid.gridLines)
			var/x = grid.xcrd
			for(var/position in 1 to length(line) step parsed.key_len)
				var/list/model = models[copytext(line, position, position + parsed.key_len)]
				tiles["[x],[y]"] = model
				x++
				y--
		CHECK_TICK
	qdel(parsed)
	return floors
