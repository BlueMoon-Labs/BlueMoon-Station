/datum/lighting_corner/dummy/test_update_queue/self_destruct_if_idle()
	return

/// Неизменный цвет не перерисовывается, но яркость для механик и переходы в темноту обновляются.
/datum/unit_test/lighting_corner_visual_changes
	var/turf/subject
	var/datum/lighting_corner/previous_corner
	var/datum/lighting_corner/dummy/test_update_queue/corner

/datum/unit_test/lighting_corner_visual_changes/Destroy()
	if(subject)
		subject.lc_bottomleft = previous_corner
		subject.cached_lumcount = null
	if(corner)
		corner.northeast = null
		qdel(corner, force = TRUE)
	return ..()

/datum/unit_test/lighting_corner_visual_changes/Run()
	subject = run_loc_floor_bottom_left
	var/atom/movable/lighting_object/lighting_object = ensure_lighting_object(subject)
	previous_corner = subject.lc_bottomleft
	corner = new
	corner.northeast = subject
	subject.lc_bottomleft = corner
	corner.lum_r = 2
	corner.lum_g = 2
	corner.lum_b = 2
	corner.update_objects()
	lighting_object.update(use_animate = FALSE)
	var/initial_color = json_encode(lighting_object.color)
	var/initial_lumcount = subject.get_lumcount(0, 10)
	lighting_object.needs_update = FALSE
	GLOB.lighting_update_objects -= lighting_object

	corner.lum_r = 3
	corner.lum_g = 3
	corner.lum_b = 3
	corner.update_objects()
	TEST_ASSERT(!lighting_object.needs_update, "Белый свет выше насыщения не должен перерисовывать ту же матрицу")
	TEST_ASSERT(!(lighting_object in GLOB.lighting_update_objects), "Неизменный цвет не должен попадать в очередь объектов")
	TEST_ASSERT_EQUAL(corner.cache_mx, 3, "Максимальная яркость угла должна обновляться без перерисовки")
	TEST_ASSERT(subject.get_lumcount(0, 10) > initial_lumcount, "Игровые проверки должны видеть новую яркость")
	lighting_object.update(use_animate = FALSE)
	TEST_ASSERT_EQUAL(json_encode(lighting_object.color), initial_color, "Пропущенный апдейт обязан давать ту же матрицу цвета")

	for(var/channel in list("lum_r", "lum_g", "lum_b"))
		corner.lum_r = 3
		corner.lum_g = 3
		corner.lum_b = 3
		corner.update_objects()
		lighting_object.needs_update = FALSE
		GLOB.lighting_update_objects -= lighting_object
		var/lumcount_before_hue_change = subject.get_lumcount(0, 10)
		corner.vars[channel] = 1
		corner.update_objects()
		TEST_ASSERT_EQUAL(corner.cache_mx, 3, "Смена оттенка не должна менять максимум яркости")
		TEST_ASSERT_NULL(subject.cached_lumcount, "Смена [channel] должна сбрасывать кэш яркости до обработки очереди")
		TEST_ASSERT(subject.get_lumcount(0, 10) < lumcount_before_hue_change, "Смена [channel] должна сразу менять яркость для игровых проверок")
		TEST_ASSERT(lighting_object.needs_update, "Смена оттенка насыщенного света должна перерисовываться")
	lighting_object.needs_update = FALSE
	GLOB.lighting_update_objects -= lighting_object
	corner.lum_r = 0
	corner.lum_g = 0
	corner.lum_b = 0
	corner.update_objects()
	TEST_ASSERT(lighting_object.needs_update, "Угасание света должно перерисовываться")
	lighting_object.needs_update = FALSE
	GLOB.lighting_update_objects -= lighting_object
	corner.update_objects()
	TEST_ASSERT(!lighting_object.needs_update, "Повторная темнота не должна перерисовываться")

	corner.cache_r = 1
	corner.cache_g = 1
	corner.cache_b = 1
	corner.cache_mx = 0
	corner.lum_r = 2
	corner.lum_g = 2
	corner.lum_b = 2
	corner.update_objects()
	TEST_ASSERT(lighting_object.needs_update, "Переход через порог темноты должен работать даже при совпавших RGB")
