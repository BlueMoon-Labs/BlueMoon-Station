/// Декоративные фильтры плоскостей живут только на этаже глаза и возвращаются при смене этажа.

#define EYE_FLOOR_FILTERS_TEST_KEY "unit-test-eye-floor-filters"

/// Размытие света снимается с нижнего этажа, возвращается ему при спуске глаза и не теряет параметров.
/datum/unit_test/multiz_eye_floor_filters_follow_viewer

/datum/unit_test/multiz_eye_floor_filters_follow_viewer/Run()
	var/datum/plane_master_group/main/group = allocate(/datum/plane_master_group/main, EYE_FLOOR_FILTERS_TEST_KEY)
	group.build_plane_masters(1, 1)
	var/atom/movable/screen/plane_master/upper = group.plane_masters["[GET_NEW_PLANE(LIGHTING_PLANE, 0)]"]
	var/atom/movable/screen/plane_master/lower = group.plane_masters["[GET_NEW_PLANE(LIGHTING_PLANE, 1)]"]
	TEST_ASSERT_NOTNULL(upper, "Нет мастера света этажа 0")
	TEST_ASSERT_NOTNULL(lower, "Нет мастера света этажа 1")
	upper.add_filter("lighting_blur", 0, list("type" = "blur", "size" = 2))
	lower.add_filter("lighting_blur", 0, list("type" = "blur", "size" = 3))

	group.apply_viewer_offset(0, 1, MULTIZ_PERFORMANCE_DISABLE, MULTIZ_SCALE_PER_LEVEL)
	TEST_ASSERT_NOTNULL(upper.get_filter("lighting_blur"), "Этаж глаза обязан сохранить размытие света")
	TEST_ASSERT_NULL(lower.get_filter("lighting_blur"), "Нижний этаж не должен платить за размытие света")
	TEST_ASSERT_NOTNULL(lower.get_filter("emissives"), "Маска эмиссии нужна свету на любом этаже")

	group.apply_viewer_offset(1, 1, MULTIZ_PERFORMANCE_DISABLE, MULTIZ_SCALE_PER_LEVEL)
	TEST_ASSERT_NULL(upper.get_filter("lighting_blur"), "Скрытый верхний этаж не должен держать размытие света")
	TEST_ASSERT_NOTNULL(lower.get_filter("lighting_blur"), "Спуск глаза обязан вернуть этажу его размытие")
	TEST_ASSERT_EQUAL(lower.filter_data["lighting_blur"]["size"], 3, "Возвращённое размытие обязано сохранить свои параметры")

	group.apply_viewer_offset(0, 1, MULTIZ_PERFORMANCE_DISABLE, MULTIZ_SCALE_PER_LEVEL)
	TEST_ASSERT_NOTNULL(upper.get_filter("lighting_blur"), "Подъём глаза обязан вернуть размытие верхнему этажу")
	TEST_ASSERT_EQUAL(upper.filter_data["lighting_blur"]["size"], 2, "Размытие верхнего этажа не должно смешаться с нижним")

/// Настройки, применённые к чужому этажу, ждут глаза, а снятые - не воскресают.
/datum/unit_test/multiz_eye_floor_filters_backdrop_on_other_floor

/datum/unit_test/multiz_eye_floor_filters_backdrop_on_other_floor/Run()
	var/datum/plane_master_group/main/group = allocate(/datum/plane_master_group/main, EYE_FLOOR_FILTERS_TEST_KEY)
	group.build_plane_masters(1, 1)
	var/atom/movable/screen/plane_master/lower = group.plane_masters["[GET_NEW_PLANE(LIGHTING_PLANE, 1)]"]
	group.apply_viewer_offset(0, 1, MULTIZ_PERFORMANCE_DISABLE, MULTIZ_SCALE_PER_LEVEL)

	lower.add_filter("lighting_blur", 0, list("type" = "blur", "size" = 2))
	TEST_ASSERT_NULL(lower.get_filter("lighting_blur"), "Фильтр, выставленный нижнему этажу, не должен рисоваться до прихода глаза")
	group.apply_viewer_offset(1, 1, MULTIZ_PERFORMANCE_DISABLE, MULTIZ_SCALE_PER_LEVEL)
	TEST_ASSERT_NOTNULL(lower.get_filter("lighting_blur"), "Отложенный фильтр обязан появиться на этаже глаза")

	group.apply_viewer_offset(0, 1, MULTIZ_PERFORMANCE_DISABLE, MULTIZ_SCALE_PER_LEVEL)
	lower.remove_filter("lighting_blur")
	group.apply_viewer_offset(1, 1, MULTIZ_PERFORMANCE_DISABLE, MULTIZ_SCALE_PER_LEVEL)
	TEST_ASSERT_NULL(lower.get_filter("lighting_blur"), "Снятый в запасе фильтр не должен вернуться")

/// Искажения мира и экспозиция ламп следуют за глазом без дублей.
/datum/unit_test/multiz_eye_floor_distortion_and_exposure

/datum/unit_test/multiz_eye_floor_distortion_and_exposure/Run()
	var/datum/plane_master_group/main/group = allocate(/datum/plane_master_group/main, EYE_FLOOR_FILTERS_TEST_KEY)
	group.build_plane_masters(1, 1)
	var/atom/movable/screen/plane_master/upper = group.plane_masters["[GET_NEW_PLANE(GAME_PLANE, 0)]"]
	var/atom/movable/screen/plane_master/lower = group.plane_masters["[GET_NEW_PLANE(GAME_PLANE, 1)]"]
	var/atom/movable/screen/plane_master/upper_exposure = group.plane_masters["[GET_NEW_PLANE(LIGHTING_EXPOSURE_PLANE, 0)]"]
	var/atom/movable/screen/plane_master/lower_exposure = group.plane_masters["[GET_NEW_PLANE(LIGHTING_EXPOSURE_PLANE, 1)]"]
	upper_exposure.add_filter("blur_exposure", 1, gauss_blur_filter(size = 12))
	upper_exposure.alpha = 255
	lower_exposure.add_filter("blur_exposure", 1, gauss_blur_filter(size = 12))
	lower_exposure.alpha = 255

	group.apply_viewer_offset(0, 1, MULTIZ_PERFORMANCE_DISABLE, MULTIZ_SCALE_PER_LEVEL)
	var/upper_filters = length(upper.filters)
	TEST_ASSERT_NOTNULL(upper.get_filter("singularity_0"), "Этаж глаза обязан нести искажения мира")
	TEST_ASSERT_NULL(lower.get_filter("singularity_0"), "Нижний этаж искажений нести не должен")
	TEST_ASSERT_EQUAL(lower_exposure.alpha, 0, "Экспозиция без размытия на нижнем этаже должна гаснуть")
	TEST_ASSERT_EQUAL(upper_exposure.alpha, 255, "Экспозиция этажа глаза должна гореть")

	group.apply_viewer_offset(1, 1, MULTIZ_PERFORMANCE_DISABLE, MULTIZ_SCALE_PER_LEVEL)
	TEST_ASSERT_NOTNULL(lower.get_filter("singularity_0"), "Искажения обязаны переехать на этаж глаза")
	TEST_ASSERT_NULL(upper.get_filter("singularity_0"), "Покинутый этаж обязан отдать искажения")
	TEST_ASSERT_EQUAL(lower_exposure.alpha, 255, "Экспозиция обязана загореться на новом этаже глаза")

	group.apply_viewer_offset(0, 1, MULTIZ_PERFORMANCE_DISABLE, MULTIZ_SCALE_PER_LEVEL)
	TEST_ASSERT_EQUAL(length(upper.filters), upper_filters, "Круг по этажам не должен плодить фильтры")

#define DISTORTION_REBUILD_BATCH 50
#define DISTORTION_REBUILD_WARMUP 200
#define DISTORTION_REBUILD_TIMER "unit-test-distortion-rebuild"

/// Пересборка фильтров на этаже с линзой сингулярности не дорожает от раза к разу.
/datum/unit_test/multiz_distortion_rebuild_cost_flat

/datum/unit_test/multiz_distortion_rebuild_cost_flat/Run()
	var/datum/plane_master_group/main/group = allocate(/datum/plane_master_group/main, EYE_FLOOR_FILTERS_TEST_KEY)
	var/atom/movable/screen/plane_master/game = group.plane_masters["[GET_NEW_PLANE(GAME_PLANE, 0)]"]
	TEST_ASSERT(game.world_distortion_applied, "Этаж глаза обязан нести линзу сингулярности")

	var/first_batch = time_rebuilds(game, DISTORTION_REBUILD_BATCH)
	time_rebuilds(game, DISTORTION_REBUILD_WARMUP)
	var/last_batch = time_rebuilds(game, DISTORTION_REBUILD_BATCH)
	TEST_ASSERT(last_batch < first_batch * 10 + 50000, "Пересборка подорожала с [first_batch] до [last_batch] мкс за [DISTORTION_REBUILD_BATCH] раз")

/datum/unit_test/multiz_distortion_rebuild_cost_flat/proc/time_rebuilds(atom/movable/screen/plane_master/target, count)
	rustg_time_reset(DISTORTION_REBUILD_TIMER)
	for(var/i in 1 to count)
		target.update_filters()
	return rustg_time_microseconds(DISTORTION_REBUILD_TIMER)

#undef DISTORTION_REBUILD_BATCH
#undef DISTORTION_REBUILD_WARMUP
#undef DISTORTION_REBUILD_TIMER

/// Тот же порог тьмы не пересобирает фильтры света: его переставляет каждый update_sight().
/datum/unit_test/multiz_light_cutoff_noop

/datum/unit_test/multiz_light_cutoff_noop/Run()
	var/datum/plane_master_group/main/group = allocate(/datum/plane_master_group/main, EYE_FLOOR_FILTERS_TEST_KEY)
	var/atom/movable/screen/plane_master/lighting/lighting = group.plane_masters["[GET_NEW_PLANE(LIGHTING_PLANE, 0)]"]
	TEST_ASSERT(cutoff_rebuilds(lighting, 30, list(10, 0, 0)), "Новый порог обязан пересобрать фильтры")
	TEST_ASSERT(!cutoff_rebuilds(lighting, 30, list(10, 0, 0)), "Тот же порог не должен пересобирать фильтры")
	TEST_ASSERT_NOTNULL(lighting.get_filter("light_cutoff"), "Порог обязан остаться на плоскости")
	TEST_ASSERT(cutoff_rebuilds(lighting, 0, null), "Снятие порога обязано пересобрать фильтры")
	TEST_ASSERT_NULL(lighting.get_filter("light_cutoff"), "Снятый порог не должен остаться на плоскости")
	TEST_ASSERT(!cutoff_rebuilds(lighting, 0, null), "Повторное снятие не должно пересобирать фильтры")

/datum/unit_test/multiz_light_cutoff_noop/proc/cutoff_rebuilds(atom/movable/screen/plane_master/lighting/lighting, cutoff, list/color_cutoffs)
	lighting.filter_updates_deferred = TRUE
	lighting.filters_dirty = FALSE
	lighting.apply_light_cutoff(cutoff, color_cutoffs)
	lighting.filter_updates_deferred = FALSE
	. = lighting.filters_dirty
	lighting.filters_dirty = FALSE
	if(.)
		lighting.update_filters()

#undef EYE_FLOOR_FILTERS_TEST_KEY
