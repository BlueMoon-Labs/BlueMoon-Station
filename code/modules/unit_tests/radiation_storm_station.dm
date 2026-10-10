/// Радиационная буря на загруженной станции: задевает каждый станционный этаж и все коридоры, видна везде, где бьёт, и облучает экипаж.
/datum/unit_test/radiation_storm_reaches_station
	requires_full_map = TRUE

/datum/unit_test/radiation_storm_reaches_station/Run()
	var/list/station_levels = SSmapping.levels_by_trait(ZTRAIT_STATION)
	var/datum/weather/rad_storm/storm = new(station_levels)
	storm.telegraph()
	storm.start()

	var/list/levels_without_storm = station_levels.Copy()
	var/list/hidden_areas = list()
	var/turf/open/floor/victim_floor
	for(var/area/impacted as anything in storm.impacted_areas)
		levels_without_storm -= impacted.z_levels
		var/drawn = FALSE
		for(var/mutable_appearance/overlay as anything in impacted.overlays)
			if(overlay.icon_state != storm.weather_overlay)
				continue
			var/effective_blend = overlay.blend_mode == BLEND_DEFAULT ? impacted.blend_mode : overlay.blend_mode
			if(effective_blend != BLEND_MULTIPLY)
				drawn = TRUE
		if(!drawn)
			hidden_areas += "[impacted.type]"
		if(!victim_floor && !istype(impacted, /area/space))
			victim_floor = locate(/turf/open/floor) in impacted

	var/list/sheltered_halls = list()
	for(var/area/hallway/hall in GLOB.sortedAreas)
		if(!hall.z_levels || !length(hall.z_levels & station_levels))
			continue
		if(!(hall in storm.impacted_areas))
			sheltered_halls += "[hall.type]"
			continue
		var/turf/open/floor/hall_floor = locate(/turf/open/floor) in hall
		if(hall_floor)
			victim_floor = hall_floor

	var/rads_taken = 0
	if(victim_floor)
		var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, victim_floor)
		if(storm.can_weather_act(victim))
			storm.weather_act(victim)
		rads_taken = victim.radiation
	storm.end()
	qdel(storm)

	TEST_ASSERT(!length(levels_without_storm), "Буря не задела станционные этажи [levels_without_storm.Join(", ")] из [station_levels.Join(", ")]")
	TEST_ASSERT(!length(sheltered_halls), "Коридоры станции оказались укрытием от бури: [sheltered_halls.Join(", ")]")
	var/list/hidden_sample = hidden_areas.Copy(1, min(length(hidden_areas), 10) + 1)
	TEST_ASSERT(!length(hidden_areas), "Оверлей бури не рисуется (умножение области) в [length(hidden_areas)] областях: [hidden_sample.Join(", ")]")
	TEST_ASSERT_NOTNULL(victim_floor, "На станции нет пола, задетого бурей")
	TEST_ASSERT(rads_taken > 0, "Человек на [AREACOORD(victim_floor)] не получил радиации от бури")

/area/icemoon/underground/unit_test_radstorm
	name = "Radstorm Test Cave"

/area/icemoon/surface/outdoors/unit_test_radstorm
	name = "Radstorm Test Surface"

/// Радиационная буря на планетарной станции: подземные пещеры - укрытие, как у tg, а поверхность под бурей.
/datum/unit_test/radiation_storm_icemoon_underground_shelters

/datum/unit_test/radiation_storm_icemoon_underground_shelters/Run()
	var/turf/cave_floor = run_loc_floor_bottom_left
	var/turf/surface_floor = locate(cave_floor.x + 1, cave_floor.y, cave_floor.z)
	var/area/cave_floor_area = get_area(cave_floor)
	var/area/surface_floor_area = get_area(surface_floor)
	var/area/icemoon/underground/unit_test_radstorm/cave = new
	var/area/icemoon/surface/outdoors/unit_test_radstorm/surface = new
	cave.contents.Add(cave_floor)
	surface.contents.Add(surface_floor)
	cave.addSorted()
	surface.addSorted()
	cave.reg_in_areas_in_z()
	surface.reg_in_areas_in_z()

	var/datum/weather/rad_storm/storm = new(list(cave_floor.z))
	var/list/impacted = storm.collect_impacted_areas()
	var/cave_hit = (cave in impacted)
	var/surface_hit = (surface in impacted)
	qdel(storm)

	cave_floor_area.contents.Add(cave_floor)
	surface_floor_area.contents.Add(surface_floor)
	qdel(cave, force = TRUE)
	qdel(surface, force = TRUE)

	TEST_ASSERT(!cave_hit, "Подземные пещеры планеты обязаны укрывать от радиационной бури")
	TEST_ASSERT(surface_hit, "Поверхность планеты обязана оставаться под радиационной бурей")
