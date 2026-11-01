/// Есть ли у турфа сосед, с которым process_cell двинул бы газ.
/proc/atmos_test_differs_from_neighbors(turf/open/subject)
	for(var/turf/open/neighbor as anything in subject.atmos_adjacent_turfs)
		if(istype(neighbor) && neighbor.air && subject.air.compare(neighbor.air))
			return TRUE
	return FALSE

/// Выравнивает воздух пола 5x5 тестовой зоны по reference и снимает его с очереди SSair.
/proc/atmos_test_level_zone(turf/base, turf/open/reference)
	for(var/dx in 0 to 4)
		for(var/dy in 0 to 4)
			var/turf/open/floor = locate(base.x + dx, base.y + dy, base.z)
			if(!istype(floor) || !floor.air)
				continue
			if(floor != reference)
				floor.air.copy_from(reference.air)
			SSair.remove_from_active(floor)

/// Загрузка шаблона шаттла в космос будит только турфы с реальным перепадом: ни космоса, ни ровного воздуха.
/datum/unit_test/atmos_template_load_wakes_only_gradients
	var/datum/turf_reservation/placement
	var/obj/docking_port/mobile/placed_port
	var/air_could_fire

/datum/unit_test/atmos_template_load_wakes_only_gradients/Run()
	var/datum/map_template/shuttle/template = SSmapping.shuttle_templates["emergency_vault"]
	TEST_ASSERT_NOTNULL(template, "premise: emergency_vault template is missing")
	placement = SSmapping.RequestBlockReservation(template.width + 2, template.height + 2)
	TEST_ASSERT_NOTNULL(placement, "premise: no room to place the template")
	var/turf/corner = TURF_FROM_COORDS_LIST(placement.bottom_left_coords)
	var/turf/bottom_left = locate(corner.x + 1, corner.y + 1, corner.z)

	air_could_fire = SSair.can_fire
	SSair.can_fire = FALSE
	var/list/active_before = list()
	for(var/turf/active as anything in SSair.active_turfs)
		active_before[active] = TRUE
	TEST_ASSERT(template.load(bottom_left, register = FALSE), "premise: emergency_vault failed to load")

	var/list/placement_turfs = list()
	for(var/turf/place as anything in block(corner, locate(corner.x + template.width + 1, corner.y + template.height + 1, corner.z)))
		placement_turfs[place] = TRUE
	var/woken = 0
	var/woken_space = 0
	var/list/settled_samples = list()
	for(var/turf/open/active as anything in SSair.active_turfs)
		if(active_before[active] || !placement_turfs[active])
			continue
		woken++
		if(isspaceturf(active))
			woken_space++
		else if(!atmos_test_differs_from_neighbors(active))
			settled_samples += "[active.type] ([active.x],[active.y])"
	for(var/turf/place as anything in template.get_affected_turfs(bottom_left))
		placed_port = locate(/obj/docking_port/mobile) in place
		if(placed_port)
			break

	TEST_ASSERT_EQUAL(woken_space, 0, "загрузка шаблона поставила в очередь SSair [woken_space] турфов космоса из [woken] разбуженных")
	TEST_ASSERT_EQUAL(length(settled_samples), 0, "загрузка шаблона разбудила [length(settled_samples)] турфов без перепада с соседями из [woken], например [english_list(settled_samples.Copy(1, min(length(settled_samples), 5) + 1))]")

/datum/unit_test/atmos_template_load_wakes_only_gradients/Destroy()
	if(!isnull(air_could_fire))
		SSair.can_fire = air_could_fire
	if(placed_port && !QDELETED(placed_port))
		placed_port.jumpToNullSpace()
	placed_port = null
	QDEL_NULL(placement)
	return ..()

/// Смена геометрии и замена турфа будят только при перепаде, а настоящий перепад будит по-прежнему.
/datum/unit_test/atmos_geometry_change_wakes_only_gradients/Run()
	var/turf/base = run_loc_floor_bottom_left
	var/turf/open/center = locate(base.x + 2, base.y + 2, base.z)
	var/turf/open/east = locate(base.x + 3, base.y + 2, base.z)
	var/turf/open/north = locate(base.x + 2, base.y + 3, base.z)
	TEST_ASSERT(istype(center) && istype(east) && istype(north), "premise: test zone center is not open floor")
	atmos_test_level_zone(base, center)
	TEST_ASSERT(!atmos_test_differs_from_neighbors(center), "premise: test zone air is not uniform")

	center.air_update_turf(TRUE)
	TEST_ASSERT(!center.excited, "пересчёт смежности разбудил турф без перепада с соседями")

	east = east.ChangeTurf(/turf/open/floor/plating)
	TEST_ASSERT(!center.excited, "замена соседнего пола на пол с тем же воздухом разбудила турф")
	TEST_ASSERT(!east.excited, "заменённый турф с воздухом соседей встал в очередь SSair")

	north.air.adjust_moles(GAS_O2, MOLES_CELLSTANDARD)
	center.air_update_turf(TRUE)
	TEST_ASSERT(center.excited, "пересчёт смежности не разбудил турф с перепадом к соседу")

	var/turf/open/space/void = locate(base.x, base.y, base.z)
	void = void.ChangeTurf(/turf/open/space)
	TEST_ASSERT(isspaceturf(void), "premise: corner did not become space")
	SSair.add_to_active(void)
	TEST_ASSERT(!void.excited, "турф космоса встал в очередь SSair")

/// Пока грузится шаблон, пробуждение от смежности ждёт StopLoadingMap() и решается по готовой геометрии.
/datum/unit_test/atmos_template_load_defers_wakes
	var/loading_opened = FALSE

/datum/unit_test/atmos_template_load_defers_wakes/Run()
	var/turf/base = run_loc_floor_bottom_left
	var/turf/open/center = locate(base.x + 2, base.y + 2, base.z)
	var/turf/open/north = locate(base.x + 2, base.y + 3, base.z)
	var/turf/open/south = locate(base.x + 2, base.y + 1, base.z)
	TEST_ASSERT(istype(center) && istype(north) && istype(south), "premise: test zone center is not open floor")
	atmos_test_level_zone(base, center)
	TEST_ASSERT(!atmos_test_differs_from_neighbors(south), "premise: test zone air is not uniform")
	north.air.adjust_moles(GAS_O2, MOLES_CELLSTANDARD)

	SSair.StartLoadingMap()
	loading_opened = TRUE
	center.air_update_turf(TRUE)
	south.air_update_turf(TRUE)
	TEST_ASSERT(!center.excited, "пробуждение от смежности не дождалось конца загрузки шаблона")
	SSair.StopLoadingMap()
	loading_opened = FALSE

	TEST_ASSERT(!SSair.map_loading, "StopLoadingMap() не закрыл загрузку")
	TEST_ASSERT(center.excited, "отложенное пробуждение турфа с перепадом потерялось")
	TEST_ASSERT(!south.excited, "отложенное пробуждение разбудило турф без перепада")

/datum/unit_test/atmos_template_load_defers_wakes/Destroy()
	if(loading_opened)
		SSair.StopLoadingMap()
	return ..()
