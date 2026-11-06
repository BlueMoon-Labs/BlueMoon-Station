/// Генератор пещер в начале раунда перекатывает каждый турф своей зоны в случайную скалу или снег.
/// Стена отсека, закрашенная такой зоной, через раунд становится дырой на улицу, и отсек вымерзает
/// (IceMoon, техтоннели у дормиториев). Проверяется по зонам и объектам, а не по выпавшему турфу.
/datum/unit_test/station_rooms_sealed_from_cave_generator
	requires_full_map = TRUE

/datum/unit_test/station_rooms_sealed_from_cave_generator/Run()
	var/list/breaches = list()
	for(var/z in SSmapping.levels_by_trait(ZTRAIT_STATION))
		for(var/turf/open/room in block(locate(1, 1, z), locate(world.maxx, world.maxy, z)))
			var/area/room_area = room.loc
			if(!room.air || room.planetary_atmos || room_area.outdoors || istype(room_area, /area/ruin) || istype(room_area, /area/shuttle))
				continue
			for(var/direction in GLOB.cardinals)
				var/turf/outside = get_step(room, direction)
				var/area/outside_area = outside?.loc
				if(!outside_area?.map_generator || !(outside_area.area_flags & CAVES_ALLOWED))
					continue
				if(!objects_seal_border(room, outside))
					breaches += "[room_area.type] ([room.x],[room.y],[room.z]) -> [outside_area.type] ([outside.x],[outside.y])"
	TEST_ASSERT(!length(breaches), "отсеки станции граничат с зоной генератора пещер без стены своей зоны: [breaches.Join("; ")]")

/datum/unit_test/station_rooms_sealed_from_cave_generator/proc/objects_seal_border(turf/open/room, turf/outside)
	for(var/obj/thing in room.contents + outside.contents)
		var/turf/other_side = (thing.loc == room ? outside : room)
		if(!CANATMOSPASS(thing, other_side))
			return TRUE
	return FALSE
