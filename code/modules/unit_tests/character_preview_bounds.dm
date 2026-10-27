// Замер границ превью персонажа: сканирование с краёв совпадает с полным обходом, а новое окно не мерит слои заново.
/datum/unit_test/character_preview_bounds

/datum/unit_test/character_preview_bounds/Run()
	var/atom/movable/screen/map_view/character_setup_screen/first = allocate(/atom/movable/screen/map_view/character_setup_screen)
	var/list/icon_files = list('icons/mob/clothing/uniform.dmi', 'icons/mob/human_face.dmi', 'icons/effects/effects.dmi')
	var/checked = 0
	for(var/icon_file in icon_files)
		var/list/states = icon_states(icon_file)
		for(var/index in 1 to min(length(states), 40))
			var/icon/measured = icon(icon_file, states[index], SOUTH, 1)
			var/list/expected = full_scan_bounds(measured)
			var/list/actual = first.measure_pixel_bounds(measured)
			if(isnull(expected))
				TEST_ASSERT_NULL(actual, "Пустой стейт [icon_file]:[states[index]] получил границы")
			else
				TEST_ASSERT(actual && actual.len == 4, "Нет границ у [icon_file]:[states[index]]")
				for(var/side in 1 to 4)
					TEST_ASSERT_EQUAL(actual[side], expected[side], "Граница [side] у [icon_file]:[states[index]]")
			checked++
	TEST_ASSERT(checked > 40, "Проверено слишком мало стейтов: [checked]")

	var/mob/living/carbon/human/doctor = allocate(/mob/living/carbon/human/dummy/consistent)
	doctor.equipOutfit(/datum/outfit/job/doctor, visualsOnly = TRUE)
	var/mutable_appearance/source = new /mutable_appearance(doctor)
	first.update_character(source, "steel")
	var/list/first_bounds = first.view_bounds_cache.Copy()
	var/cache_size = length(GLOB.character_preview_icon_bounds)
	TEST_ASSERT(cache_size > 0, "Замеры не попали в общий кэш")

	var/atom/movable/screen/map_view/character_setup_screen/second = allocate(/atom/movable/screen/map_view/character_setup_screen)
	second.update_character(source, "steel")
	TEST_ASSERT_EQUAL(length(GLOB.character_preview_icon_bounds), cache_size, "Новое окно заново измерило уже известные слои")
	TEST_ASSERT(second.background_cache && second.background_cache == first.background_cache, "Новое окно того же размера собрало свой фон")
	for(var/direction in GLOB.cardinals)
		var/list/expected = first_bounds["[direction]"]
		var/list/actual = second.view_bounds_cache["[direction]"]
		for(var/side in 1 to 4)
			TEST_ASSERT_EQUAL(actual[side], expected[side], "Граница [side] ракурса [direction] во втором окне")

/datum/unit_test/character_preview_bounds/proc/full_scan_bounds(icon/measured)
	var/list/bounds
	for(var/x in 1 to measured.Width())
		for(var/y in 1 to measured.Height())
			if(!measured.GetPixel(x, y))
				continue
			if(!bounds)
				bounds = list(x - 1, y - 1, x, y)
			else
				bounds[1] = min(bounds[1], x - 1)
				bounds[2] = min(bounds[2], y - 1)
				bounds[3] = max(bounds[3], x)
				bounds[4] = max(bounds[4], y)
	return bounds
