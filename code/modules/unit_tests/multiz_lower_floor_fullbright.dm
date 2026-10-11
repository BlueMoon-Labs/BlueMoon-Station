/// Неосвещаемая зона светит этажи под верхним засветкой самого турфа: оверлей зоны лежит только на плоскости света верхнего этажа.
/datum/unit_test/multiz_lower_floor_fullbright

/datum/unit_test/multiz_lower_floor_fullbright/proc/fullbright_count(turf/target, offset)
	var/lighting_plane = GET_NEW_PLANE(LIGHTING_PLANE, offset)
	. = 0
	for(var/mutable_appearance/overlay as anything in target.overlays)
		if(overlay.plane == lighting_plane && overlay.blend_mode == BLEND_ADD && overlay.icon_state == "white")
			.++

/datum/unit_test/multiz_lower_floor_fullbright/Run()
	var/datum/space_level/lower = SSmapping.add_new_zlevel("Тест засветки: нижний этаж", list())
	var/datum/space_level/upper = SSmapping.add_new_zlevel("Тест засветки: верхний этаж", list())
	var/datum/map_template/probe = new
	probe.link_template_stack(list(lower, upper))
	qdel(probe)
	TEST_ASSERT_EQUAL(GET_Z_PLANE_OFFSET(lower.z_value), 1, "Нижний этаж связки обязан получить смещение 1")

	var/turf/lower_space = locate(10, 10, lower.z_value)
	var/turf/upper_space = locate(10, 10, upper.z_value)
	var/area/space_area = lower_space.loc
	TEST_ASSERT(!IS_DYNAMIC_LIGHTING(space_area), "Пустой уровень обязан лежать в неосвещаемой зоне, а не в [space_area.type]")
	TEST_ASSERT_EQUAL(fullbright_count(lower_space, 1), 1, "Космос нижнего этажа без своей засветки: живой видит его чёрным")
	TEST_ASSERT_EQUAL(fullbright_count(upper_space, 0), 0, "Верхний этаж светит оверлей зоны, своя засветка турфа там лишняя")

	SSatoms.InitializeAtoms(list(lower_space))
	TEST_ASSERT_EQUAL(fullbright_count(lower_space, 1), 1, "Initialize переложенного космоса оставил [fullbright_count(lower_space, 1)] засветок вместо одной")

	var/turf/lower_floor = lower_space.ChangeTurf(/turf/open/floor/plating)
	TEST_ASSERT_EQUAL(fullbright_count(lower_floor, 1), 1, "Пол, построенный в космосе нижнего этажа, остался без засветки")

	var/area/lit_area = new /area
	allocated += lit_area
	lit_area.contents += lower_floor
	lower_floor.change_area(space_area, lit_area)
	TEST_ASSERT_EQUAL(fullbright_count(lower_floor, 1), 0, "Засветка космоса осталась на полу, ушедшем в освещаемую зону")

	lit_area.set_dynamic_lighting(DYNAMIC_LIGHTING_DISABLED)
	TEST_ASSERT_EQUAL(fullbright_count(lower_floor, 1), 1, "Зона, переставшая освещаться, не засветила свой турф нижнего этажа")
	lit_area.set_dynamic_lighting(DYNAMIC_LIGHTING_ENABLED)
	TEST_ASSERT_EQUAL(fullbright_count(lower_floor, 1), 0, "Зона, снова освещаемая, не сняла засветку с турфа")

	space_area.contents += lower_floor
	lower_floor.change_area(lit_area, space_area)
	TEST_ASSERT_EQUAL(fullbright_count(lower_floor, 1), 1, "Пол, вернувшийся в космос нижнего этажа, остался без засветки")
