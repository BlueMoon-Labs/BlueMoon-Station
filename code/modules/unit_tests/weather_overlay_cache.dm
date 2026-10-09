/// Оверлеи погоды на областях: снятие по фактически выданным областям и раскладка по этажам стопки.

/datum/weather/unit_test_overlay_probe
	telegraph_overlay = "light_ash"
	weather_overlay = "ash_storm"
	end_overlay = "light_ash"

/// Плоскости оверлеев бури на области.
/datum/unit_test/proc/weather_overlay_planes(area/target, weather_state)
	var/list/planes = list()
	for(var/mutable_appearance/overlay as anything in target.overlays)
		if(overlay.icon_state == weather_state)
			planes += overlay.plane
	return planes

/// Оверлей снимается со всех областей, которым его выдали, даже если impacted_areas переписали снаружи.
/datum/unit_test/weather_overlay_cache_follows_overlaid_areas

/datum/unit_test/weather_overlay_cache_follows_overlaid_areas/Run()
	var/area/first_area = new /area
	var/area/second_area = new /area
	allocated += first_area
	allocated += second_area

	var/datum/weather/unit_test_overlay_probe/storm = new(list(run_loc_floor_bottom_left.z))
	storm.stage = MAIN_STAGE
	storm.impacted_areas = list(first_area, second_area)
	storm.update_areas()
	TEST_ASSERT_EQUAL(length(weather_overlay_planes(first_area, storm.weather_overlay)), 1, "Первая область обязана получить оверлей бури")
	TEST_ASSERT_EQUAL(length(weather_overlay_planes(second_area, storm.weather_overlay)), 1, "Вторая область обязана получить оверлей бури")

	storm.impacted_areas = list(first_area)
	storm.update_areas()
	TEST_ASSERT_EQUAL(length(weather_overlay_planes(first_area, storm.weather_overlay)), 1, "Область, оставшаяся в impacted_areas, обязана сохранить оверлей бури")
	TEST_ASSERT_EQUAL(length(weather_overlay_planes(second_area, storm.weather_overlay)), 0, "Область, выпавшая из impacted_areas, обязана лишиться оверлея бури")

	storm.end()
	TEST_ASSERT_EQUAL(length(weather_overlay_planes(first_area, storm.weather_overlay)), 0, "end() обязан снять оверлей с затронутой области")
	TEST_ASSERT_EQUAL(length(weather_overlay_planes(second_area, storm.weather_overlay)), 0, "end() обязан снять оверлей с области, выпавшей из impacted_areas")

/// Область получает оверлей только для смещений плоскостей тех этажей, где у неё есть турфы.
/datum/unit_test/weather_overlay_cache_matches_area_floors

/datum/unit_test/weather_overlay_cache_matches_area_floors/Run()
	var/turf/floor = run_loc_floor_bottom_left
	var/turf/second_floor = locate(floor.x + 1, floor.y, floor.z)
	var/other_z = floor.z == 1 ? 2 : 1
	var/turf/other_floor = locate(1, 1, other_z)
	TEST_ASSERT_NOTNULL(second_floor, "Резервации нужен второй турф на этаже бури")
	TEST_ASSERT_NOTNULL(other_floor, "Тесту нужен турф на z=[other_z]")

	var/area/floor_area = get_area(floor)
	var/area/second_floor_area = get_area(second_floor)
	var/area/other_area = get_area(other_floor)
	var/area/single_floor_area = new /area
	var/area/two_floor_area = new /area
	allocated += single_floor_area
	allocated += two_floor_area
	single_floor_area.contents.Add(floor)
	two_floor_area.contents.Add(second_floor)
	two_floor_area.contents.Add(other_floor)
	single_floor_area.reg_in_areas_in_z()
	two_floor_area.reg_in_areas_in_z()

	// Второй этаж стопки подменяется в таблице смещений: на карте без стопки его нет. Ни одного сна до возврата.
	var/floor_offset = SSmapping.z_level_to_plane_offset[floor.z]
	var/other_offset = floor_offset + 1
	var/saved_other_offset = SSmapping.z_level_to_plane_offset[other_z]
	var/saved_max_plane_offset = SSmapping.max_plane_offset
	SSmapping.z_level_to_plane_offset[other_z] = other_offset
	SSmapping.max_plane_offset = max(saved_max_plane_offset, other_offset)

	var/datum/weather/unit_test_overlay_probe/storm = new(list(floor.z, other_z))
	storm.stage = MAIN_STAGE
	storm.impacted_areas = list(single_floor_area, two_floor_area)
	storm.update_areas()
	var/list/single_floor_planes = weather_overlay_planes(single_floor_area, storm.weather_overlay)
	var/list/two_floor_planes = weather_overlay_planes(two_floor_area, storm.weather_overlay)
	storm.end()
	var/single_floor_after_end = length(weather_overlay_planes(single_floor_area, storm.weather_overlay))
	var/two_floor_after_end = length(weather_overlay_planes(two_floor_area, storm.weather_overlay))

	SSmapping.z_level_to_plane_offset[other_z] = saved_other_offset
	SSmapping.max_plane_offset = saved_max_plane_offset
	floor_area.contents.Add(floor)
	second_floor_area.contents.Add(second_floor)
	other_area.contents.Add(other_floor)

	var/floor_plane = GET_NEW_PLANE(storm.overlay_plane, floor_offset)
	var/other_plane = GET_NEW_PLANE(storm.overlay_plane, other_offset)
	TEST_ASSERT_EQUAL(length(single_floor_planes), 1, "Область одного этажа получила [length(single_floor_planes)] оверлеев бури вместо одного")
	TEST_ASSERT_EQUAL(single_floor_planes[1], floor_plane, "Оверлей области одного этажа обязан лежать на плоскости её этажа")
	TEST_ASSERT_EQUAL(length(two_floor_planes), 2, "Область на двух этажах получила [length(two_floor_planes)] оверлеев бури вместо двух")
	TEST_ASSERT(floor_plane in two_floor_planes, "Область на двух этажах обязана получить оверлей верхнего этажа")
	TEST_ASSERT(other_plane in two_floor_planes, "Область на двух этажах обязана получить оверлей нижнего этажа")
	TEST_ASSERT_EQUAL(single_floor_after_end, 0, "end() обязан снять оверлей с области одного этажа")
	TEST_ASSERT_EQUAL(two_floor_after_end, 0, "end() обязан снять оба оверлея с области на двух этажах")

/// Оверлей бури не наследует BLEND_MULTIPLY области: в пустой картинке своей плоскости умножение ничего не рисует.
/datum/unit_test/weather_overlay_ignores_area_blend

/datum/unit_test/weather_overlay_ignores_area_blend/Run()
	var/area/storm_area = new /area
	allocated += storm_area
	var/datum/weather/unit_test_overlay_probe/storm = new(list(run_loc_floor_bottom_left.z))
	storm.stage = MAIN_STAGE
	storm.impacted_areas = list(storm_area)
	storm.update_areas()
	var/list/drawn_blends = list()
	for(var/mutable_appearance/overlay as anything in storm_area.overlays)
		if(overlay.icon_state == storm.weather_overlay)
			drawn_blends += overlay.blend_mode == BLEND_DEFAULT ? storm_area.blend_mode : overlay.blend_mode
	storm.end()

	TEST_ASSERT_EQUAL(length(drawn_blends), 1, "Область получила [length(drawn_blends)] оверлеев бури вместо одного")
	TEST_ASSERT(drawn_blends[1] == BLEND_DEFAULT || drawn_blends[1] == BLEND_OVERLAY, "Оверлей бури рисуется с blend_mode [drawn_blends[1]] (у области [storm_area.blend_mode]), а не обычным наложением")

/// Этажи оверлея бури берутся из реестра области (z_levels и area.z), а не обходом её турфов.
/datum/unit_test/weather_overlay_offsets_from_area_registry

/datum/unit_test/weather_overlay_offsets_from_area_registry/Run()
	var/turf/floor = run_loc_floor_bottom_left
	var/other_z = floor.z == 1 ? 2 : 1
	var/area/floor_area = get_area(floor)
	var/area/registry_area = new /area
	allocated += registry_area
	registry_area.contents.Add(floor)
	registry_area.z_levels = list(floor.z, other_z)

	var/floor_offset = SSmapping.z_level_to_plane_offset[floor.z]
	var/other_offset = floor_offset + 1
	var/saved_other_offset = SSmapping.z_level_to_plane_offset[other_z]
	var/saved_max_plane_offset = SSmapping.max_plane_offset
	SSmapping.z_level_to_plane_offset[other_z] = other_offset
	SSmapping.max_plane_offset = max(saved_max_plane_offset, other_offset)

	var/datum/weather/unit_test_overlay_probe/storm = new(list(floor.z, other_z))
	storm.stage = MAIN_STAGE
	storm.impacted_areas = list(registry_area)
	storm.update_areas()
	var/list/registry_planes = weather_overlay_planes(registry_area, storm.weather_overlay)
	registry_area.z_levels = null
	storm.update_areas()
	var/list/live_z_planes = weather_overlay_planes(registry_area, storm.weather_overlay)
	storm.end()

	SSmapping.z_level_to_plane_offset[other_z] = saved_other_offset
	SSmapping.max_plane_offset = saved_max_plane_offset
	floor_area.contents.Add(floor)

	var/floor_plane = GET_NEW_PLANE(storm.overlay_plane, floor_offset)
	TEST_ASSERT_EQUAL(length(registry_planes), 2, "Область с z_levels на двух этажах получила [length(registry_planes)] оверлеев бури вместо двух")
	TEST_ASSERT_EQUAL(length(live_z_planes), 1, "Область без z_levels получила [length(live_z_planes)] оверлеев бури вместо одного по area.z")
	TEST_ASSERT_EQUAL(live_z_planes[1], floor_plane, "Без z_levels оверлей обязан лечь на этаж area.z")

/// Обновление иконки одной области во время бури не снимает с неё оверлей и не переукладывает бурю на остальных областях.
/datum/unit_test/weather_area_icon_update_is_local

/datum/unit_test/weather_area_icon_update_is_local/Run()
	var/area/updated_area = new /area
	var/area/other_area = new /area
	allocated += updated_area
	allocated += other_area
	var/datum/weather/unit_test_overlay_probe/storm = new(list(run_loc_floor_bottom_left.z))
	storm.stage = MAIN_STAGE
	storm.impacted_areas = list(updated_area, other_area)
	START_PROCESSING(SSweather, storm)
	storm.update_areas()
	other_area.cut_overlay(storm.overlay_cache)
	updated_area.update_icon()
	var/updated_overlays = length(weather_overlay_planes(updated_area, storm.weather_overlay))
	var/other_overlays = length(weather_overlay_planes(other_area, storm.weather_overlay))
	storm.end()

	TEST_ASSERT_EQUAL(updated_overlays, 1, "update_icon() области сняло с неё оверлей бури")
	TEST_ASSERT_EQUAL(other_overlays, 0, "update_icon() одной области переуложило оверлей бури на другой затронутой области")
