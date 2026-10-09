/// Тот же уровень размытия не пересобирает фильтры игровых плоскостей, новый уровень и снятие до них доходят.
/datum/unit_test/eye_blur_filter_rebuilds_only_on_change

/datum/unit_test/eye_blur_filter_rebuilds_only_on_change/Run()
	var/mob/living/carbon/human/viewer = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/hud/human/hud = new(viewer)
	viewer.set_hud_used(hud)
	var/atom/movable/plane_master_controller/controller = hud.plane_master_controllers[PLANE_MASTERS_GAME]
	TEST_ASSERT(length(controller?.controlled_planes), "У худа нет игровых плоскостей")
	var/atom/movable/screen/plane_master/game_plane = controller.controlled_planes[controller.controlled_planes[1]]

	viewer.set_blurriness(100)
	var/list/applied = LAZYACCESS(game_plane.filter_data, "eye_blur")
	TEST_ASSERT_NOTNULL(applied, "Размытие обязано лечь на игровую плоскость")
	viewer.adjust_blurriness(-1)
	TEST_ASSERT(LAZYACCESS(game_plane.filter_data, "eye_blur") == applied, "Тот же уровень размытия не должен пересобирать фильтры плоскостей")

	viewer.set_blurriness(10)
	var/list/reduced = LAZYACCESS(game_plane.filter_data, "eye_blur")
	TEST_ASSERT_NOTNULL(reduced, "Новый уровень размытия обязан остаться на плоскости")
	TEST_ASSERT_EQUAL(reduced["size"], 1, "Новый уровень размытия обязан дойти до плоскости")

	viewer.set_blurriness(0)
	TEST_ASSERT_NULL(game_plane.get_filter("eye_blur"), "Снятое размытие не должно остаться на плоскости")
	TEST_ASSERT_NULL(LAZYACCESS(controller.filter_data, "eye_blur"), "Снятое размытие не должно остаться в контроллере")

/// Фильтр, выставленный через контроллер, пересобирает каждую плоскость один раз.
/datum/unit_test/plane_controller_single_rebuild

/datum/unit_test/plane_controller_single_rebuild/Run()
	var/mob/living/carbon/human/viewer = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/hud/human/hud = new(viewer)
	viewer.set_hud_used(hud)
	var/atom/movable/plane_master_controller/controller = hud.plane_master_controllers[PLANE_MASTERS_GAME]
	var/atom/movable/filter_rebuild_probe/probe = allocate(/atom/movable/filter_rebuild_probe)
	controller.controlled_planes["unit-test-probe"] = probe

	controller.add_filter("unit_test_blur", 1, gauss_blur_filter(1))
	TEST_ASSERT_EQUAL(probe.rebuilds, 1, "Добавление фильтра через контроллер обязано пересобрать плоскость один раз")
	probe.rebuilds = 0
	controller.remove_filter("unit_test_blur")
	TEST_ASSERT_EQUAL(probe.rebuilds, 1, "Снятие фильтра через контроллер обязано пересобрать плоскость один раз")
	controller.controlled_planes -= "unit-test-probe"

/atom/movable/filter_rebuild_probe
	var/rebuilds = 0

/atom/movable/filter_rebuild_probe/update_filters()
	rebuilds++
	return ..()
