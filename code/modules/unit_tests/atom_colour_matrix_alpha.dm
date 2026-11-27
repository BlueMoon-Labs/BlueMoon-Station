/// Матрица из atom_colours (стоп времени, заморозка) не гасит прозрачность атома и не теряет её смену.
/datum/unit_test/atom_colour_matrix_keeps_alpha

/datum/unit_test/atom_colour_matrix_keeps_alpha/Run()
	var/list/negative = list(-1,0,0,0, 0,-1,0,0, 0,0,-1,0, 0,0,0,1, 1,1,1,0)
	var/obj/item/thing = allocate(/obj/item)
	thing.alpha = 100
	thing.add_atom_colour(negative, TEMPORARY_COLOUR_PRIORITY)
	var/list/applied = thing.color
	TEST_ASSERT(islist(applied), "Инверсия легла матрицей")
	TEST_ASSERT_EQUAL(round(applied[16] * 255, 1), 100, "Матрица погасила прозрачность")
	thing.remove_atom_colour(TEMPORARY_COLOUR_PRIORITY)
	TEST_ASSERT_EQUAL(thing.alpha, 100, "Снятая матрица сбила прозрачность")
#if DM_VERSION > 516 || DM_BUILD >= 1689
	thing.add_atom_colour(negative, TEMPORARY_COLOUR_PRIORITY)
	thing.alpha = 60
	thing.remove_atom_colour(TEMPORARY_COLOUR_PRIORITY)
	TEST_ASSERT_EQUAL(thing.alpha, 60, "Прозрачность, выставленная под матрицей, пропала вместе с ней")
#endif

/// Край поля еретика полупрозрачен, хотя его цвет - матрица.
/datum/unit_test/heretic_field_edge_translucent

/datum/unit_test/heretic_field_edge_translucent/Run()
	var/obj/effect/heretic_field_edge/edge = allocate(/obj/effect/heretic_field_edge, run_loc_floor_bottom_left, list(run_loc_floor_bottom_left), "#ff8b3d")
	var/list/tint = edge.color
	TEST_ASSERT(islist(tint), "Край выкрашен матрицей")
	TEST_ASSERT_EQUAL(round(tint[16] * 255, 1), initial(edge.alpha), "Матрица края погасила его прозрачность")
