/// Затирка уровня сперва удаляет атомы, пока клетки ещё в своей области, и только потом делает их космосом.
/// В обратном порядке машинерия удалялась уже в /area/space и не снималась с реестров своей области:
/// лампы и люки руины держал кэш её APC, и затирка руины давала пачку хардделов (10603).
/datum/unit_test/zclear_wipe_deletes_atoms_before_turfs/Run()
	var/turf/wiped = run_loc_floor_bottom_left
	var/area/original_area = get_area(wiped)
	var/original_type = wiped.type
	var/obj/item/leftover = allocate(/obj/item/toy/plush, wiped)
	var/datum/zclear_data/data = new
	data.zvalue = wiped.z
	data.divided_turfs = list(list(wiped))
	data.divided_atom_turfs = list(list(wiped))
	data.process_num = 0
	SSzclear.continue_wipe(data)
	TEST_ASSERT(QDELETED(leftover), "первый шаг затирки не удалил атомы")
	TEST_ASSERT_EQUAL(get_area(wiped), original_area, "клетка ушла в космос раньше, чем с неё удалили атомы")
	TEST_ASSERT_EQUAL(wiped.type, original_type, "клетка пересоздана раньше, чем с неё удалили атомы")
