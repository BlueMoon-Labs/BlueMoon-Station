/// Поставленный шаблоном второй эвакуационный шаттл не забирает SSshuttle.emergency у живого, а после снятия старого (как в action_load с replace) забирает.
/datum/unit_test/emergency_shuttle_second_port_no_takeover
	var/obj/docking_port/mobile/emergency/original_emergency
	var/obj/docking_port/mobile/emergency/placed_port
	var/datum/turf_reservation/placement

/datum/unit_test/emergency_shuttle_second_port_no_takeover/Run()
	original_emergency = SSshuttle.emergency
	TEST_ASSERT_NOTNULL(original_emergency, "premise: no emergency shuttle in the test world")

	var/datum/map_template/shuttle/template = SSmapping.shuttle_templates["emergency_vault"]
	TEST_ASSERT_NOTNULL(template, "premise: emergency_vault template is missing")
	placement = SSmapping.RequestBlockReservation(template.width, template.height)
	TEST_ASSERT_NOTNULL(placement, "premise: no room to place the template")
	var/turf/bottom_left = TURF_FROM_COORDS_LIST(placement.bottom_left_coords)
	TEST_ASSERT(template.load(bottom_left), "premise: emergency_vault failed to load")

	for(var/turf/place as anything in template.get_affected_turfs(bottom_left))
		placed_port = locate(/obj/docking_port/mobile/emergency) in place
		if(placed_port)
			break
	TEST_ASSERT_NOTNULL(placed_port, "premise: the placed template has no emergency docking port")
	TEST_ASSERT(placed_port in SSshuttle.mobile, "premise: the placed port was not registered")

	TEST_ASSERT_EQUAL(SSshuttle.emergency, original_emergency, "registering a placed emergency template took SSshuttle.emergency from the live shuttle ([original_emergency]) and gave it to [placed_port]")

	placed_port.unregister()
	SSshuttle.emergencyDeregister()
	placed_port.register(TRUE)
	TEST_ASSERT_EQUAL(SSshuttle.emergency, placed_port, "after the old emergency shuttle was deregistered the replacement did not become SSshuttle.emergency")

/datum/unit_test/emergency_shuttle_second_port_no_takeover/Destroy()
	if(placed_port && !QDELETED(placed_port))
		placed_port.jumpToNullSpace()
	placed_port = null
	if(original_emergency && !QDELETED(original_emergency))
		SSshuttle.emergency = original_emergency
	original_emergency = null
	QDEL_NULL(placement)
	return ..()
