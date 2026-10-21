SUBSYSTEM_DEF(minimaps)
	name = "Minimaps"
	flags = SS_NO_FIRE
	var/list/station_minimaps = list()
	var/datum/minimap_group/station_minimap = null

/datum/controller/subsystem/minimaps/Initialize()
	if(!CONFIG_GET(flag/minimaps_enabled))
		to_chat(world, "<span class='boldwarning'>Minimaps disabled! Skipping init.</span>")
		return ..()
	build_minimaps()
	return ..()

/datum/controller/subsystem/minimaps/proc/build_minimaps()
	for(var/z in SSmapping.levels_by_trait(ZTRAIT_STATION))
		var/datum/space_level/SL = SSmapping.get_level(z)
		var/name = (SL.name == initial(SL.name))? "[z] - Station" : "[z] - [SL.name]"
		station_minimaps += new /datum/minimap(z, name = name, autocrop = FALSE)

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

	station_minimap = new(station_minimaps, "Station")
