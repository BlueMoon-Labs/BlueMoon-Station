/// Космос z-уровня, поднятого посреди раунда, ложится на плоскость своего этажа.

/// Точки уровня для выборочной проверки: углы и центр.
/proc/multiz_test_level_probes(z)
	return list(
		locate(1, 1, z),
		locate(world.maxx, 1, z),
		locate(1, world.maxy, z),
		locate(world.maxx, world.maxy, z),
		locate(round(world.maxx / 2), round(world.maxy / 2), z),
	)

/// Два пустых уровня, сцепленные тем же путём, что и админская подгрузка шаблона: космос нижнего этажа уезжает на плоскость смещения 1, верхний остаётся на нулевом.
/datum/unit_test/multiz_new_level_planes

/datum/unit_test/multiz_new_level_planes/Run()
	var/datum/space_level/lower = SSmapping.add_new_zlevel("Тест плоскостей: нижний этаж", list())
	var/datum/space_level/upper = SSmapping.add_new_zlevel("Тест плоскостей: верхний этаж", list())
	var/datum/map_template/probe = new
	probe.link_template_stack(list(lower, upper))
	qdel(probe)

	TEST_ASSERT_EQUAL(GET_Z_PLANE_OFFSET(lower.z_value), 1, "Нижний этаж связки обязан получить смещение 1")
	TEST_ASSERT_EQUAL(GET_Z_PLANE_OFFSET(upper.z_value), 0, "Верхний этаж связки остаётся на нулевом смещении")

	var/lower_plane = GET_NEW_PLANE(PLANE_SPACE, 1)
	TEST_ASSERT_NOTEQUAL(lower_plane, PLANE_SPACE, "Смещённая плоскость космоса обязана отличаться от настоящей")
	for(var/turf/spot as anything in multiz_test_level_probes(lower.z_value))
		TEST_ASSERT(istype(spot, /turf/open/space/basic), "Пустой уровень обязан состоять из world.turf, а не [spot.type]")
		TEST_ASSERT_EQUAL(spot.plane, lower_plane, "Космос нижнего этажа в ([spot.x],[spot.y]) остался на плоскости нулевого этажа: зритель на этом уровне его не увидит")
	for(var/turf/spot as anything in multiz_test_level_probes(upper.z_value))
		TEST_ASSERT_EQUAL(spot.plane, PLANE_SPACE, "Космос верхнего этажа в ([spot.x],[spot.y]) уехал с настоящей плоскости")

	TEST_ASSERT_EQUAL(SSmapping.apply_level_plane_offset(lower.z_value), 0, "Повторный обход уровня не должен трогать уже переложенные турфы")
	TEST_ASSERT_EQUAL(SSmapping.apply_level_plane_offset(upper.z_value), 0, "Обход уровня с нулевым смещением не должен трогать турфы")

	//Внутри границ шаблона переложенный турф потом проходит Initialize, как в initTemplateBounds().
	var/turf/late_space = locate(1, 1, lower.z_value)
	SSatoms.InitializeAtoms(list(late_space))
	TEST_ASSERT_EQUAL(late_space.plane, lower_plane, "Initialize космоса сложил смещение со смещением, выданным при подъёме уровня")
