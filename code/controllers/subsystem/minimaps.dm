SUBSYSTEM_DEF(minimaps)
	name = "Minimaps"
	flags = SS_NO_FIRE
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
	var/list/map_files = islist(SSmapping.config.map_file) ? SSmapping.config.map_file : list(SSmapping.config.map_file)
	for(var/map_file in map_files)
		var/list/file_maps = nanomaps.map_data["[SSmapping.config.map_path]/[map_file]"]
		if(file_maps)
			station_maps += file_maps
	for(var/z in SSmapping.levels_by_trait(ZTRAIT_STATION))
		var/station_index = SSmapping.z_to_station_z_index["[z]"]
		if(!station_index || station_index > length(station_maps))
			log_mapping("Для станционного z=[z] не найдена миникарта NanoMap.")
			continue
		var/list/map_data = station_maps[station_index]
		var/datum/asset_cache_item/map_asset = nanomaps.assets[map_data["asset"]]
		var/list/stack = SSmapping.get_connected_levels(z)
		station_minimaps += new /datum/minimap(z, x2 = map_data["width"], y2 = map_data["height"], name = "Этаж [stack.Find(z)]", autocrop = FALSE, source_icon = map_asset.resource)

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
