/// Стопка попапа и сжатие нижних этажей: подписка на новые этажи и transform, переживающий чужую запись.

#define POPUP_GROUP_TEST_KEY "unit-test-popup-group"
#define POPUP_GROUP_TEST_MAP "unit_test_popup_map"
#define POPUP_GROUP_TEST_TOLERANCE 0.001

/// map_view строит стопку через группу, и рост связки достраивает ей этажи в карту попапа.
/datum/unit_test/multiz_popup_group_follows_new_floors

/datum/unit_test/multiz_popup_group_follows_new_floors/Run()
	var/atom/movable/screen/map_view/view = new
	allocated += view
	view.generate_view(POPUP_GROUP_TEST_MAP)

	var/datum/plane_master_group/popup/group = view.ensure_plane_group()
	TEST_ASSERT_NOTNULL(group, "map_view обязан строить стопку попапа через группу")
	TEST_ASSERT_EQUAL(view.ensure_plane_group(), group, "Повторный показ не должен плодить вторую стопку")
	TEST_ASSERT_EQUAL(group.map, POPUP_GROUP_TEST_MAP, "Стопка попапа обязана адресоваться в карту map_view")
	TEST_ASSERT_EQUAL(length(group.registered_clients), 0, "Без клиента подписчиков быть не должно")

	var/next_floor = group.built_depth + 1
	var/new_plane_key = "[GET_NEW_PLANE(GAME_PLANE, next_floor)]"
	TEST_ASSERT_NULL(group.plane_masters[new_plane_key], "Этаж [next_floor] не должен существовать до роста связки")

	group.on_plane_increase(SSmapping, group.built_depth, next_floor)
	var/atom/movable/screen/plane_master/added = group.plane_masters[new_plane_key]
	TEST_ASSERT_NOTNULL(added, "Рост связки обязан достроить игровой мастер этажа [next_floor]")
	TEST_ASSERT_EQUAL(added.assigned_map, POPUP_GROUP_TEST_MAP, "Достроенный мастер обязан адресоваться в карту попапа")
	TEST_ASSERT_EQUAL(group.built_depth, next_floor, "Глубина стопки обязана вырасти вместе со связкой")

	qdel(view)
	TEST_ASSERT(QDELETED(group), "Удаление map_view обязано снести его стопку")
	TEST_ASSERT_NULL(view.popup_plane_group, "Удалённый map_view не должен держать стопку")

/// Сжатие нижнего этажа переписывается заново при каждом пересчёте и композируется с эффектами.
/datum/unit_test/multiz_floor_scale_survives_transform_overwrite

/datum/unit_test/multiz_floor_scale_survives_transform_overwrite/Run()
	var/datum/plane_master_group/main/group = allocate(/datum/plane_master_group/main, POPUP_GROUP_TEST_KEY)
	//Мимо ensure_depth(): на одноэтажной карте она режет глубину до нуля.
	group.build_plane_masters(1, 1)

	var/atom/movable/screen/plane_master/eye_floor = group.plane_masters["[GET_NEW_PLANE(GAME_PLANE, 0)]"]
	var/atom/movable/screen/plane_master/lower = group.plane_masters["[GET_NEW_PLANE(GAME_PLANE, 1)]"]
	TEST_ASSERT_NOTNULL(eye_floor, "У этажа глаза нет игрового мастера")
	TEST_ASSERT_NOTNULL(lower, "Этаж 1 не построился")

	group.apply_viewer_offset(0, 1, MULTIZ_PERFORMANCE_DISABLE, MULTIZ_SCALE_PER_LEVEL)
	TEST_ASSERT_EQUAL(eye_floor.multiz_scale, 1, "Этаж глаза сжиматься не должен")
	assert_scaled(lower, MULTIZ_SCALE_PER_LEVEL, "после первого пересчёта")

	lower.transform = matrix()
	group.apply_viewer_offset(0, 1, MULTIZ_PERFORMANCE_DISABLE, MULTIZ_SCALE_PER_LEVEL)
	assert_scaled(lower, MULTIZ_SCALE_PER_LEVEL, "после чужой записи transform")

	var/matrix/expected = matrix(45, MATRIX_ROTATE)
	expected.Scale(MULTIZ_SCALE_PER_LEVEL)
	var/matrix/composed = lower.compose_transform(matrix(45, MATRIX_ROTATE))
	TEST_ASSERT(matrices_match(composed, expected), "Эффект поверх нижнего этажа обязан нести и поворот, и сжатие")
	var/matrix/rotation_only = matrix(45, MATRIX_ROTATE)
	TEST_ASSERT(!matrices_match(composed, rotation_only), "Эффект без сжатия рисовал бы нижний этаж 1:1")

	group.apply_viewer_offset(1, 1, MULTIZ_PERFORMANCE_DISABLE, MULTIZ_SCALE_PER_LEVEL)
	TEST_ASSERT_EQUAL(lower.multiz_scale, 1, "Этаж под глазом сжиматься не должен")
	assert_scaled(lower, 1, "после спуска глаза на этаж 1")

/datum/unit_test/multiz_floor_scale_survives_transform_overwrite/proc/assert_scaled(atom/movable/screen/plane_master/plane, scale, when)
	var/matrix/expected = matrix()
	expected.Scale(scale)
	var/matrix/actual = plane.transform
	TEST_ASSERT(matrices_match(actual, expected), "transform мастера [plane] [when] не несёт масштаб [scale]")

/datum/unit_test/multiz_floor_scale_survives_transform_overwrite/proc/matrices_match(matrix/left, matrix/right)
	if(isnull(left) || isnull(right))
		return FALSE
	return abs(left.a - right.a) < POPUP_GROUP_TEST_TOLERANCE \
		&& abs(left.b - right.b) < POPUP_GROUP_TEST_TOLERANCE \
		&& abs(left.c - right.c) < POPUP_GROUP_TEST_TOLERANCE \
		&& abs(left.d - right.d) < POPUP_GROUP_TEST_TOLERANCE \
		&& abs(left.e - right.e) < POPUP_GROUP_TEST_TOLERANCE \
		&& abs(left.f - right.f) < POPUP_GROUP_TEST_TOLERANCE

#undef POPUP_GROUP_TEST_KEY
#undef POPUP_GROUP_TEST_MAP
#undef POPUP_GROUP_TEST_TOLERANCE
