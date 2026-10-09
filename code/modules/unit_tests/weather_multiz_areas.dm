/// Многоэтажная область: регистрация в SSmapping.areas_in_z под каждым z и отбор бури по этажам, а не по area.z.

/area/unit_test_multiz_weather
	name = "Multi-Z Weather Test Area"
	area_flags = NONE
	requires_power = FALSE
	outdoors = TRUE

/datum/weather/unit_test_multiz_probe
	area_type = /area/unit_test_multiz_weather

/// Область с турфами на двух этажах стоит в areas_in_z под обоими z, буря только на этаже выше area.z её не пропускает, Destroy снимает обе записи.
/datum/unit_test/weather_multiz_areas

/datum/unit_test/weather_multiz_areas/Run()
	var/turf/floor = run_loc_floor_bottom_left
	var/other_z = floor.z == 1 ? 2 : 1
	var/turf/other_floor = locate(1, 1, other_z)
	TEST_ASSERT_NOTNULL(other_floor, "Тесту нужен турф на z=[other_z]")

	var/area/floor_area = get_area(floor)
	var/area/other_area = get_area(other_floor)
	var/area/unit_test_multiz_weather/two_floor_area = new
	two_floor_area.contents.Add(floor)
	two_floor_area.contents.Add(other_floor)
	two_floor_area.addSorted()
	two_floor_area.reg_in_areas_in_z()

	var/registered_upper = (two_floor_area in SSmapping.areas_in_z["[floor.z]"])
	var/registered_lower = (two_floor_area in SSmapping.areas_in_z["[other_z]"])
	var/lowest_z = two_floor_area.z
	var/target_z = lowest_z == floor.z ? other_z : floor.z
	var/datum/weather/unit_test_multiz_probe/storm = new(list(target_z))
	var/included = (two_floor_area in storm.collect_impacted_areas())

	floor_area.contents.Add(floor)
	other_area.contents.Add(other_floor)
	qdel(two_floor_area, force = TRUE)
	var/still_registered = (two_floor_area in SSmapping.areas_in_z["[floor.z]"]) || (two_floor_area in SSmapping.areas_in_z["[other_z]"])

	TEST_ASSERT(registered_upper, "Область с турфом на z=[floor.z] обязана стоять в areas_in_z под этим z")
	TEST_ASSERT(registered_lower, "Область с турфом на z=[other_z] обязана стоять в areas_in_z под этим z")
	TEST_ASSERT(included, "Буря на z=[target_z] обязана включить область, у которой area.z=[lowest_z], но есть турф на z=[target_z]")
	TEST_ASSERT(!still_registered, "Destroy обязан снять область из areas_in_z под всеми её z")
