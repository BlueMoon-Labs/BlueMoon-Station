/obj/effect/changeturf_unit_test_hide_probe
	var/hide_calls = 0
	var/last_intact

/obj/effect/changeturf_unit_test_hide_probe/hide(intact)
	hide_calls++
	last_intact = intact

/obj/machinery/door/firedoor/changeturf_unit_test_probe
	var/recalculations = 0

/obj/machinery/door/firedoor/changeturf_unit_test_probe/CalculateAffectingAreas(initializing = FALSE)
	recalculations++
	return ..()

/// Замена турфа прячет и открывает подпольные объекты одним вызовом hide() с флагом нового турфа.
/datum/unit_test/changeturf_hides_underfloor_once/Run()
	var/turf/spot = run_loc_floor_bottom_left
	var/obj/effect/changeturf_unit_test_hide_probe/probe = allocate(/obj/effect/changeturf_unit_test_hide_probe, spot)
	var/obj/structure/cable/cable = allocate(/obj/structure/cable, spot)

	spot.ChangeTurf(/turf/open/floor/plating)
	TEST_ASSERT_EQUAL(probe.hide_calls, 1, "Снятие плитки звало hide() [probe.hide_calls] раз")
	TEST_ASSERT(!probe.last_intact, "На пластине объект остался спрятанным")
	TEST_ASSERT_EQUAL(cable.invisibility, 0, "Кабель на пластине не виден")

	spot.ChangeTurf(/turf/open/floor/plasteel)
	TEST_ASSERT_EQUAL(probe.hide_calls, 2, "Укладка плитки звала hide() [probe.hide_calls - 1] раз")
	TEST_ASSERT(probe.last_intact, "Под плиткой объект не спрятан")
	TEST_ASSERT_EQUAL(cable.invisibility, INVISIBILITY_MAXIMUM, "Кабель под плиткой виден")

/// Замена турфа пересчитывает зоны пожарных шлюзов на нём и на соседях по сторонам света, но не по диагонали.
/datum/unit_test/changeturf_recalculates_firedoor_areas/Run()
	var/turf/center = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	var/obj/machinery/door/firedoor/changeturf_unit_test_probe/on_center = allocate(/obj/machinery/door/firedoor/changeturf_unit_test_probe, center)
	var/obj/machinery/door/firedoor/changeturf_unit_test_probe/on_side = allocate(/obj/machinery/door/firedoor/changeturf_unit_test_probe, get_step(center, EAST))
	var/obj/machinery/door/firedoor/changeturf_unit_test_probe/on_diagonal = allocate(/obj/machinery/door/firedoor/changeturf_unit_test_probe, get_step(center, SOUTHWEST))
	var/center_before = on_center.recalculations
	var/side_before = on_side.recalculations
	var/diagonal_before = on_diagonal.recalculations

	center.ChangeTurf(/turf/open/floor/plating)

	TEST_ASSERT_EQUAL(on_center.recalculations - center_before, 1, "Шлюз на заменённом турфе")
	TEST_ASSERT_EQUAL(on_side.recalculations - side_before, 1, "Шлюз на соседе сбоку")
	TEST_ASSERT_EQUAL(on_diagonal.recalculations - diagonal_before, 0, "Шлюз на соседе по диагонали")

/// copyTurf кладёт прежний облик открытого приёмника единственной подложкой, а закрытый приёмник подложкой не становится.
/datum/unit_test/copyturf_destination_underlay/Run()
	var/turf/source = run_loc_floor_bottom_left
	source.underlays += mutable_appearance('icons/turf/floors.dmi', "floor")
	var/turf/destination = run_loc_floor_top_right
	destination.ChangeTurf(/turf/open/floor/plating)
	var/old_icon = destination.icon
	var/old_icon_state = destination.icon_state

	source.copyTurf(destination)
	TEST_ASSERT_EQUAL(destination.type, source.type, "Тип источника не скопирован")
	TEST_ASSERT_EQUAL(length(destination.underlays), 1, "Подложек у приёмника")
	var/mutable_appearance/underlay = new(destination.underlays[1])
	TEST_ASSERT_EQUAL(underlay.icon, old_icon, "Подложка не из прежнего облика приёмника")
	TEST_ASSERT_EQUAL(underlay.icon_state, old_icon_state, "Подложка не из прежнего облика приёмника")

	destination.ChangeTurf(/turf/closed/wall)
	source.copyTurf(destination)
	TEST_ASSERT_EQUAL(destination.type, source.type, "Тип источника не скопирован поверх стены")
	TEST_ASSERT_EQUAL(length(destination.underlays), 0, "Стена стала подложкой")

/// copyTurf с copy_air переносит в приёмник ровно воздух источника.
/datum/unit_test/copyturf_copies_air/Run()
	var/turf/open/source = run_loc_floor_bottom_left
	source.air.set_moles(GAS_PLASMA, 50)
	source.air.set_temperature(500)
	var/turf/open/destination = run_loc_floor_top_right
	destination.ChangeTurf(/turf/open/floor/plating)

	source.copyTurf(destination, TRUE)
	TEST_ASSERT_EQUAL(destination.air.get_moles(GAS_PLASMA), 50, "Плазма в приёмнике")
	TEST_ASSERT_EQUAL(destination.air.get_moles(GAS_O2), source.air.get_moles(GAS_O2), "Кислород в приёмнике")
	TEST_ASSERT_EQUAL(destination.air.return_temperature(), 500, "Температура приёмника")

/// Assimilate_Air усредняет воздух соседей на каждом вызове заново, без остатка от прошлого вызова.
/datum/unit_test/assimilate_air_averages_neighbours/Run()
	var/turf/open/center = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	TEST_ASSERT(LAZYLEN(center.atmos_adjacent_turfs), "У центра арены нет атмос-соседей")

	for(var/turf/open/neighbor as anything in center.atmos_adjacent_turfs)
		neighbor.air.clear()
		neighbor.air.set_moles(GAS_O2, 100)
		neighbor.air.set_moles(GAS_PLASMA, 40)
		neighbor.air.set_temperature(400)
	center.Assimilate_Air()
	TEST_ASSERT(abs(center.air.get_moles(GAS_O2) - 100) < 0.001, "Кислород после первого вызова: [center.air.get_moles(GAS_O2)]")
	TEST_ASSERT(abs(center.air.get_moles(GAS_PLASMA) - 40) < 0.001, "Плазма после первого вызова: [center.air.get_moles(GAS_PLASMA)]")
	TEST_ASSERT(abs(center.air.return_temperature() - 400) < 0.001, "Температура после первого вызова: [center.air.return_temperature()]")

	for(var/turf/open/neighbor as anything in center.atmos_adjacent_turfs)
		neighbor.air.clear()
		neighbor.air.set_moles(GAS_O2, 20)
		neighbor.air.set_temperature(250)
	center.Assimilate_Air()
	TEST_ASSERT(abs(center.air.get_moles(GAS_O2) - 20) < 0.001, "Кислород после второго вызова: [center.air.get_moles(GAS_O2)]")
	TEST_ASSERT_EQUAL(center.air.get_moles(GAS_PLASMA), 0, "Плазма первого вызова осталась в смеси")
	TEST_ASSERT(abs(center.air.return_temperature() - 250) < 0.001, "Температура после второго вызова: [center.air.return_temperature()]")

/// empty() удаляет содержимое турфа вместе с вложенным, оставляет ориентиры и меняет тип турфа.
/datum/unit_test/turf_empty_spares_ignored_atoms/Run()
	var/turf/spot = run_loc_floor_bottom_left
	var/obj/item/storage/box/box = allocate(/obj/item/storage/box, spot)
	var/obj/item/pen/nested = allocate(/obj/item/pen, box)
	var/obj/effect/landmark/landmark = allocate(/obj/effect/landmark, spot)

	spot.empty(/turf/open/floor/plating)
	TEST_ASSERT(QDELETED(box), "Коробка пережила empty()")
	TEST_ASSERT(QDELETED(nested), "Вложенный предмет пережил empty()")
	TEST_ASSERT(!QDELETED(landmark) && landmark.loc == spot, "Ориентир удалён или сдвинут")
	TEST_ASSERT(istype(spot, /turf/open/floor/plating), "Турф с содержимым не заменён")

	var/turf/bare = run_loc_floor_top_right
	bare.empty(/turf/open/floor/plating)
	TEST_ASSERT(istype(bare, /turf/open/floor/plating), "Пустой турф не заменён")

/// empty() оставляет турфу его объект света: без него динамически освещённый турф после замены остаётся чёрным.
/datum/unit_test/turf_empty_keeps_lighting_object/Run()
	var/turf/spot = run_loc_floor_bottom_left
	var/atom/movable/lighting_object/overlay = ensure_lighting_object(spot)

	spot.empty(FALSE)
	TEST_ASSERT(!QDELETED(overlay), "empty() без замены турфа удалил объект света")
	TEST_ASSERT_EQUAL(spot.lighting_object, overlay, "Турф потерял объект света")

	spot.empty(/turf/open/floor/plating)
	TEST_ASSERT(!QDELETED(overlay), "empty() с заменой турфа удалил объект света")
	TEST_ASSERT_EQUAL(spot.lighting_object, overlay, "Объект света не перешёл на новый турф")
	TEST_ASSERT(overlay in spot.vis_contents, "Объект света не в vis_contents нового турфа")
