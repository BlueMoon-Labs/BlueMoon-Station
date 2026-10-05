/obj/effect/decal/refactor_turfside_probe

/// Замена турфа на стену удаляет декаль, лежащую прямо на нём; декаль в коробке на том же турфе и декаль на сменившемся полу остаются.
/datum/unit_test/refactor_turfside_turf_change_decals/Run()
	var/turf/base = run_loc_floor_bottom_left
	var/turf/walled = locate(base.x + 1, base.y + 1, base.z)
	var/turf/floored = locate(base.x + 3, base.y + 1, base.z)
	var/obj/effect/decal/refactor_turfside_probe/on_wall = allocate(/obj/effect/decal/refactor_turfside_probe, walled)
	var/obj/item/storage/box/box = allocate(/obj/item/storage/box, walled)
	var/obj/effect/decal/refactor_turfside_probe/boxed = allocate(/obj/effect/decal/refactor_turfside_probe, walled)
	boxed.forceMove(box)
	var/obj/effect/decal/refactor_turfside_probe/on_floor = allocate(/obj/effect/decal/refactor_turfside_probe, floored)

	walled.ChangeTurf(/turf/closed/wall)
	floored.ChangeTurf(/turf/open/floor/plating)

	TEST_ASSERT(QDELETED(on_wall), "Декаль пережила замену пола на стену")
	TEST_ASSERT(!QDELETED(boxed) && boxed.loc == box, "Декаль в коробке удалена или сдвинута")
	TEST_ASSERT(!QDELETED(on_floor) && on_floor.loc == floored, "Декаль на новом полу удалена или сдвинута")

/// Перелёт шаттла кладёт в турф назначения воздух исходного турфа: и со сменой типа, и поверх такого же пола.
/datum/unit_test/refactor_turfside_shuttle_move_air/Run()
	var/turf/base = run_loc_floor_bottom_left
	var/list/arrival_types = list(/turf/open/space, /turf/open/floor/plasteel)
	for(var/row in 1 to length(arrival_types))
		var/turf/open/source = locate(base.x, base.y + (row - 1) * 2, base.z)
		var/turf/arrival = locate(base.x + 4, base.y + (row - 1) * 2, base.z)
		arrival.ChangeTurf(arrival_types[row])
		var/list/source_baseturfs = source.baseturfs
		var/list/arrival_baseturfs = arrival.baseturfs
		source.baseturfs = list(/turf/open/space, /turf/baseturf_skipover/shuttle)
		source.air.set_moles(GAS_PLASMA, 50)
		source.air.set_moles(GAS_O2, 33)
		source.air.set_temperature(500)
		var/source_n2 = source.air.get_moles(GAS_N2)

		source.onShuttleMove(arrival, null, NORTH)

		var/turf/open/landed = arrival
		TEST_ASSERT(istype(landed), "Турф назначения не открытый после перелёта на [arrival_types[row]]")
		TEST_ASSERT_EQUAL(landed.air.get_moles(GAS_PLASMA), 50, "Плазма после перелёта на [arrival_types[row]]")
		TEST_ASSERT_EQUAL(landed.air.get_moles(GAS_O2), 33, "Кислород после перелёта на [arrival_types[row]]")
		TEST_ASSERT_EQUAL(landed.air.get_moles(GAS_N2), source_n2, "Азот после перелёта на [arrival_types[row]]")
		TEST_ASSERT_EQUAL(landed.air.return_temperature(), 500, "Температура после перелёта на [arrival_types[row]]")

		landed.lateShuttleMove(source)
		source.baseturfs = source_baseturfs
		landed.baseturfs = arrival_baseturfs
		source.air.copy_from_turf(source)

/// Повторный add_turf() члена не задваивает его в turf_list, выселенный и вернувшийся турф числится в группе один раз.
/datum/unit_test/refactor_turfside_group_readd_single_listing/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/base = run_loc_floor_bottom_left
	var/turf/open/first = locate(base.x + 1, base.y + 1, base.z)
	var/turf/open/second = locate(base.x + 2, base.y + 1, base.z)
	TEST_ASSERT(istype(first) && istype(second), "test turfs are not open")

	var/datum/excited_group/group = new
	group.add_turf(first)
	group.add_turf(second)
	group.add_turf(first)
	TEST_ASSERT_EQUAL(length(group.turf_list), 2, "Повторно добавленный член задвоился в turf_list")

	SSair.sleep_active_turf(second)
	group.evict_settled_members()
	TEST_ASSERT_NULL(second.excited_group, "Осевший член не выселен")
	group.add_turf(second)
	TEST_ASSERT_EQUAL(length(group.turf_list), 2, "Вернувшийся турф числится в turf_list не один раз")
	TEST_ASSERT_EQUAL(second.excited_group, group, "Вернувшийся турф не указывает на группу")

	group.dismantle()
	SSair.remove_from_active(first)
	SSair.remove_from_active(second)
