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

// Запись зрителя без живого экрана роняла schedule_preview_update на null.viewport_width (раунд 10618).
/datum/unit_test/character_preview_dead_viewer_screen

/datum/unit_test/character_preview_dead_viewer_screen/Run()
	var/datum/preferences/prefs = new
	var/datum/character_setup/setup = new(prefs)
	var/mob/living/carbon/human/viewer = allocate(/mob/living/carbon/human/dummy/consistent)
	LAZYSET(setup.viewer_screens, viewer, null)
	setup.preview_dirty = TRUE
	setup.schedule_preview_update()
	TEST_ASSERT(!length(setup.viewer_screens), "Запись без экрана должна убираться из зрителей")
	TEST_ASSERT(!setup.preview_update_pending, "Без готового экрана сборка превью не планируется")
	qdel(setup)
	qdel(prefs)

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

// Заранее замеренная внешность собирается без новых замеров и с теми же границами (раунд 10624: 65-863 мс на сборку).
/datum/unit_test/character_preview_bounds_prewarm
	var/list/original_cache

/datum/unit_test/character_preview_bounds_prewarm/Run()
	original_cache = GLOB.character_preview_icon_bounds
	var/mob/living/carbon/human/doctor = allocate(/mob/living/carbon/human/dummy/consistent)
	doctor.equipOutfit(/datum/outfit/job/doctor, visualsOnly = TRUE)
	var/mutable_appearance/source = new /mutable_appearance(doctor)

	GLOB.character_preview_icon_bounds = list()
	var/atom/movable/screen/map_view/character_setup_screen/cold = allocate(/atom/movable/screen/map_view/character_setup_screen)
	cold.update_character(source, "steel")
	var/list/cold_bounds = cold.view_bounds_cache.Copy()

	GLOB.character_preview_icon_bounds = list()
	var/atom/movable/screen/map_view/character_setup_screen/warm = allocate(/atom/movable/screen/map_view/character_setup_screen)
	warm.prewarm_preview_bounds(source)
	var/warmed_size = length(GLOB.character_preview_icon_bounds)
	TEST_ASSERT(warmed_size > 0, "Прогрев ничего не замерил")
	warm.update_character(source, "steel")
	TEST_ASSERT_EQUAL(length(GLOB.character_preview_icon_bounds), warmed_size, "Сборка после прогрева мерила слои заново")
	for(var/direction in GLOB.cardinals)
		var/list/expected = cold_bounds["[direction]"]
		var/list/actual = warm.view_bounds_cache["[direction]"]
		for(var/side in 1 to 4)
			TEST_ASSERT_EQUAL(actual[side], expected[side], "Граница [side] ракурса [direction] после прогрева")

/datum/unit_test/character_preview_bounds_prewarm/Destroy()
	if(original_cache)
		GLOB.character_preview_icon_bounds = original_cache
	original_cache = null
	return ..()
