/// Два этажа связки с гравитацией: list(нижний z, верхний z). Уровни живут до конца прогона, поэтому поднимаются один раз.
/proc/multiz_gravity_test_levels()
	var/static/list/levels
	if(levels)
		return levels
	var/datum/space_level/lower = SSmapping.add_new_zlevel("Тест мульти-Z: нижний этаж", list(ZTRAIT_GRAVITY = TRUE))
	var/datum/space_level/upper = SSmapping.add_new_zlevel("Тест мульти-Z: верхний этаж", list(ZTRAIT_GRAVITY = TRUE))
	var/datum/map_template/stack = new
	stack.link_template_stack(list(lower, upper))
	qdel(stack)
	levels = list(lower.z_value, upper.z_value)
	return levels

/proc/multiz_gravity_test_turf(x, y, z, turf_type)
	var/turf/spot = locate(x, y, z)
	if(spot.type != turf_type)
		spot = spot.ChangeTurf(turf_type)
	return spot

/// Блобы на четырёх сторонах: расти центру остаётся только по вертикали.
/proc/blob_multiz_test_surround(obj/structure/blob/center)
	. = list()
	for(var/direction in GLOB.cardinals)
		. += new /obj/structure/blob/normal(get_step(center, direction))

/proc/blob_multiz_test_overmind(turf/spot)
	var/mob/camera/blob/overmind = new(spot, 0)
	overmind.forceMove(spot)
	overmind.set_strain(/datum/blobstrain/reagent/regenerative_materia)
	overmind.set_hud_used(new /datum/hud/blob_overmind(overmind))
	overmind.hud_used.eye_z_changed(force = TRUE)
	overmind.placed = TRUE
	overmind.blob_points = 100
	return overmind

/// Блоб, занявший дыру в полу, прорастает на этаж ниже и сам не проваливается.
/datum/unit_test/blob_multiz_spreads_down_through_hole

/datum/unit_test/blob_multiz_spreads_down_through_hole/Run()
	var/list/levels = multiz_gravity_test_levels()
	var/turf/below = multiz_gravity_test_turf(10, 10, levels[1], /turf/open/floor/plating)
	var/turf/hole = multiz_gravity_test_turf(10, 10, levels[2], /turf/open/openspace)
	var/obj/structure/blob/source = allocate(/obj/structure/blob/normal, hole)
	allocated += blob_multiz_test_surround(source)

	var/obj/structure/blob/grown = source.expand()
	TEST_ASSERT(istype(grown), "Блоб в дыре, обложенный со всех сторон, не пророс вниз")
	allocated += grown
	TEST_ASSERT_EQUAL(grown.loc, below, "Блоб пророс не в клетку под дырой")

	hole.zFall(source)
	TEST_ASSERT_EQUAL(source.loc, hole, "Блоб над дырой провалился на нижний этаж")

/// Блоб под дырой в потолке прорастает в неё, и новый блоб остаётся висеть в дыре.
/datum/unit_test/blob_multiz_spreads_up_into_hole

/datum/unit_test/blob_multiz_spreads_up_into_hole/Run()
	var/list/levels = multiz_gravity_test_levels()
	var/turf/floor = multiz_gravity_test_turf(20, 10, levels[1], /turf/open/floor/plating)
	var/turf/hole = multiz_gravity_test_turf(20, 10, levels[2], /turf/open/openspace)
	var/obj/structure/blob/source = allocate(/obj/structure/blob/normal, floor)
	allocated += blob_multiz_test_surround(source)

	var/obj/structure/blob/grown = source.expand()
	TEST_ASSERT(istype(grown), "Блоб под дырой, обложенный со всех сторон, не пророс вверх")
	allocated += grown
	TEST_ASSERT_EQUAL(grown.loc, hole, "Блоб пророс не в дыру над собой")

	hole.zFall(grown)
	TEST_ASSERT_EQUAL(grown.loc, hole, "Блоб в дыре провалился обратно")

/// Сплошной пол между этажами, катуок над дырой и одноэтажная карта вертикальный рост не пускают.
/datum/unit_test/blob_multiz_spread_needs_open_hole

/datum/unit_test/blob_multiz_spread_needs_open_hole/Run()
	var/list/levels = multiz_gravity_test_levels()
	var/turf/lower_floor = multiz_gravity_test_turf(30, 10, levels[1], /turf/open/floor/plating)
	var/turf/upper_floor = multiz_gravity_test_turf(30, 10, levels[2], /turf/open/floor/plating)
	var/obj/structure/blob/under_ceiling = allocate(/obj/structure/blob/normal, lower_floor)
	allocated += blob_multiz_test_surround(under_ceiling)
	TEST_ASSERT(!under_ceiling.expand(), "Блоб пророс вверх сквозь сплошной потолок")
	var/obj/structure/blob/on_floor = allocate(/obj/structure/blob/normal, upper_floor)
	allocated += blob_multiz_test_surround(on_floor)
	TEST_ASSERT(!on_floor.expand(), "Блоб пророс вниз сквозь сплошной пол")

	var/turf/covered_below = multiz_gravity_test_turf(40, 10, levels[1], /turf/open/floor/plating)
	var/turf/covered_hole = multiz_gravity_test_turf(40, 10, levels[2], /turf/open/openspace)
	allocate(/obj/structure/lattice/catwalk, covered_hole)
	var/obj/structure/blob/on_catwalk = allocate(/obj/structure/blob/normal, covered_hole)
	allocated += blob_multiz_test_surround(on_catwalk)
	TEST_ASSERT(!on_catwalk.expand(), "Блоб пророс вниз сквозь катуок")
	var/obj/structure/blob/under_catwalk = allocate(/obj/structure/blob/normal, covered_below)
	allocated += blob_multiz_test_surround(under_catwalk)
	TEST_ASSERT(!under_catwalk.expand(), "Блоб пророс вверх сквозь катуок")

	var/obj/structure/blob/single_floor = allocate(/obj/structure/blob/normal, run_loc_floor_bottom_left)
	allocated += blob_multiz_test_surround(single_floor)
	TEST_ASSERT(!single_floor.expand(), "На одноэтажной карте блобу без свободных соседей расти некуда")

/// Клик разума по клетке соседнего этажа растит блоб сквозь дыру в обе стороны по обычной цене.
/datum/unit_test/blob_multiz_overmind_expands_through_hole

/datum/unit_test/blob_multiz_overmind_expands_through_hole/Run()
	var/list/levels = multiz_gravity_test_levels()
	var/turf/below = multiz_gravity_test_turf(50, 10, levels[1], /turf/open/floor/plating)
	var/turf/hole = multiz_gravity_test_turf(50, 10, levels[2], /turf/open/openspace)
	allocate(/obj/structure/blob/normal, hole)
	var/mob/camera/blob/overmind = blob_multiz_test_overmind(hole)
	allocated += overmind
	var/points_before = overmind.blob_points

	overmind.expand_blob(below)
	var/obj/structure/blob/grown_down = locate() in below
	TEST_ASSERT_NOTNULL(grown_down, "Клик по клетке под занятой дырой не вырастил там блоб")
	allocated += grown_down
	TEST_ASSERT_EQUAL(overmind.blob_points, points_before - BLOB_SPREAD_COST, "Рост на другой этаж обязан стоить как обычный")

	var/turf/lower_floor = multiz_gravity_test_turf(55, 10, levels[1], /turf/open/floor/plating)
	var/turf/upper_hole = multiz_gravity_test_turf(55, 10, levels[2], /turf/open/openspace)
	allocate(/obj/structure/blob/normal, lower_floor)
	overmind.last_attack = 0
	overmind.expand_blob(upper_hole)
	var/obj/structure/blob/grown_up = locate() in upper_hole
	TEST_ASSERT_NOTNULL(grown_up, "Клик по дыре над блобом не вырастил в ней блоб")
	allocated += grown_up

/// Разум переходит на соседний этаж только к своему блобу или туда, куда тот прорастёт, и худ переезжает на плоскости этажа.
/datum/unit_test/blob_multiz_overmind_changes_floor

/datum/unit_test/blob_multiz_overmind_changes_floor/Run()
	var/list/levels = multiz_gravity_test_levels()
	var/turf/floor = multiz_gravity_test_turf(60, 10, levels[1], /turf/open/floor/plating)
	var/turf/hole = multiz_gravity_test_turf(60, 10, levels[2], /turf/open/openspace)
	var/turf/far_floor = multiz_gravity_test_turf(70, 10, levels[1], /turf/open/floor/plating)
	allocate(/obj/structure/blob/normal, floor)
	var/mob/camera/blob/overmind = blob_multiz_test_overmind(floor)
	allocated += overmind
	var/datum/hud/hud = overmind.hud_used
	TEST_ASSERT_EQUAL(hud.current_plane_offset, GET_Z_PLANE_OFFSET(levels[1]), "Худ разума не стоит на плоскостях нижнего этажа")

	TEST_ASSERT(overmind.move_vertically(UP), "Разум не поднялся в дыру над своим блобом")
	TEST_ASSERT_EQUAL(overmind.loc, hole, "Разум поднялся не в дыру над блобом")
	TEST_ASSERT_EQUAL(hud.current_plane_offset, GET_Z_PLANE_OFFSET(levels[2]), "Худ разума остался на плоскостях нижнего этажа")

	TEST_ASSERT(overmind.move_vertically(DOWN), "Разум не спустился обратно к своему блобу")
	TEST_ASSERT_EQUAL(overmind.loc, floor, "Разум спустился не к своему блобу")
	TEST_ASSERT_EQUAL(hud.current_plane_offset, GET_Z_PLANE_OFFSET(levels[1]), "Худ разума остался на плоскостях верхнего этажа")

	overmind.forceMove(far_floor)
	TEST_ASSERT(!overmind.move_vertically(UP), "Разум поднялся туда, где рядом нет блоба")
	TEST_ASSERT_EQUAL(overmind.loc, far_floor, "Отказ в подъёме сдвинул разум")
