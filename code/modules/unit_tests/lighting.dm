/datum/unit_test/lighting_object_destroy_clears_blend_queue/Run()
	TEST_ASSERT(SSlighting.initialized, "SSlighting was not initialized")

	var/turf/test_turf = run_loc_floor_bottom_left
	TEST_ASSERT_NULL(test_turf.lighting_object, "Test turf unexpectedly already had a lighting object")

	var/atom/movable/lighting_object/test_object = allocate(/atom/movable/lighting_object, test_turf)
	TEST_ASSERT_EQUAL(test_turf.lighting_object, test_object, "Lighting object was not attached to the test turf")

	test_turf.recalc_area_blend_region()

	TEST_ASSERT(test_object in GLOB.lighting_update_blends, "Lighting object was not queued for area blend recalculation")

	qdel(test_object, force = TRUE)

	TEST_ASSERT_NULL(test_turf.lighting_object, "Force-qdeleted lighting object was still attached to the turf")
	TEST_ASSERT(!(test_object in GLOB.lighting_update_objects), "Force-qdeleted lighting object remained in lighting_update_objects")
	TEST_ASSERT(!(test_object in GLOB.lighting_update_blends), "Force-qdeleted lighting object remained in lighting_update_blends")

/datum/unit_test/lighting_object_changeturf_preserves_transfer/Run()
	TEST_ASSERT(SSlighting.initialized, "SSlighting was not initialized")

	var/turf/test_turf = run_loc_floor_bottom_left
	TEST_ASSERT_NULL(test_turf.lighting_object, "Test turf unexpectedly already had a lighting object")

	var/x = test_turf.x
	var/y = test_turf.y
	var/z = test_turf.z
	var/atom/movable/lighting_object/test_object = allocate(/atom/movable/lighting_object, test_turf)
	TEST_ASSERT_EQUAL(test_turf.lighting_object, test_object, "Lighting object was not attached to the original turf")

	var/turf/replacement_turf = test_turf.ChangeTurf(/turf/open/floor/plasteel/white)

	TEST_ASSERT_EQUAL(locate(x, y, z), replacement_turf, "ChangeTurf should return the replacement turf at the original coordinates.")
	TEST_ASSERT(istype(replacement_turf, /turf/open/floor/plasteel/white), "Replacement turf had the wrong type ([replacement_turf.type])")
	TEST_ASSERT_EQUAL(replacement_turf.lighting_object, test_object, "Lighting object was not transferred to the replacement turf")
	TEST_ASSERT_EQUAL(test_object.affected_turf, replacement_turf, "Lighting object still pointed at the old turf after ChangeTurf")
	TEST_ASSERT(test_object in replacement_turf.vis_contents, "Replacement turf did not keep the transferred lighting object in vis_contents")
	qdel(test_object, force = TRUE)

/datum/unit_test/forced_turf_destroy_cleans_lighting_object/Run()
	TEST_ASSERT(SSlighting.initialized, "SSlighting was not initialized")

	var/turf/test_turf = run_loc_floor_bottom_left
	TEST_ASSERT_NULL(test_turf.lighting_object, "Test turf unexpectedly already had a lighting object")

	var/atom/movable/lighting_object/test_object = allocate(/atom/movable/lighting_object, test_turf)
	TEST_ASSERT_EQUAL(test_turf.lighting_object, test_object, "Lighting object was not attached to the test turf")

	test_turf.recalc_area_blend_region()
	TEST_ASSERT(test_object in GLOB.lighting_update_blends, "Lighting object was not queued for area blend recalculation")

	var/x = test_turf.x
	var/y = test_turf.y
	var/z = test_turf.z
	test_turf.changing_turf = TRUE
	qdel(test_turf, force = TRUE)

	var/turf/replacement_turf = locate(x, y, z)
	TEST_ASSERT(QDELETED(test_object), "Forced turf deletion did not delete the lighting object")
	TEST_ASSERT_NULL(replacement_turf.lighting_object, "Replacement turf retained the deleted lighting object")
	TEST_ASSERT(!(test_object in GLOB.lighting_update_objects), "Deleted lighting object remained in lighting_update_objects after turf deletion")
	TEST_ASSERT(!(test_object in GLOB.lighting_update_blends), "Deleted lighting object remained in lighting_update_blends after turf deletion")

/datum/unit_test/light_cone_changes_refresh_emission/Run()
	var/obj/machinery/light/test_light = allocate(/obj/machinery/light, run_loc_floor_bottom_left)
	test_light.status = LIGHT_OK
	test_light.on = TRUE
	test_light.switchcount = 0
	test_light.update(FALSE, TRUE)
	TEST_ASSERT(test_light.light, "Directional fixture should create a live light source.")
	TEST_ASSERT_EQUAL(test_light.light.light_cone_angle, test_light.cone_angle, "Initial cone angle should match the fixture configuration.")
	TEST_ASSERT_EQUAL(test_light.light.light_cone_dir, turn(test_light.dir, 180), "Initial cone direction should match the fixture direction.")
	test_light.dir = SOUTH
	test_light.update(FALSE, TRUE)
	TEST_ASSERT_EQUAL(test_light.light.light_cone_dir, turn(test_light.dir, 180), "Changing only direction should refresh the live cone direction.")
	test_light.cone_angle = LIGHTING_WALL_BULB_CONE_ANGLE
	test_light.update(FALSE, TRUE)
	TEST_ASSERT_EQUAL(test_light.light.light_cone_angle, test_light.cone_angle, "Changing only cone angle should refresh the live cone angle.")

/datum/unit_test/light_damage_flicker_restores_effective_power/Run()
	var/obj/machinery/light/test_light = allocate(/obj/machinery/light, run_loc_floor_bottom_left)
	test_light.status = LIGHT_OK
	test_light.on = TRUE
	test_light.switchcount = 0
	test_light.nightshift_enabled = TRUE
	test_light.nightshift_level = 1
	test_light.update(FALSE, TRUE)
	var/expected_power = test_light.light_power
	TEST_ASSERT_NOTEQUAL(expected_power, test_light.bulb_power, "Nightshift should change the emitted power away from raw bulb_power.")
	test_light.start_damage_flicker()
	TEST_ASSERT_EQUAL(test_light.damage_flicker_base_power, expected_power, "Damage flicker should capture the current emitted power.")
	test_light.stop_damage_flicker()
	TEST_ASSERT_NULL(test_light.damage_flicker_base_power, "Stopping damage flicker should clear the stored emitted power.")
	TEST_ASSERT_EQUAL(test_light.light_power, expected_power, "Stopping damage flicker should restore the effective fixture power.")
	TEST_ASSERT(test_light.light, "Damage flicker stop should leave the live light source intact.")
	TEST_ASSERT_EQUAL(test_light.light.light_power, expected_power, "Stopping damage flicker should restore the live emitted power.")
	TEST_ASSERT_EQUAL(test_light.bulb_power, initial(test_light.bulb_power), "Damage flicker should not rewrite the raw bulb power.")

/datum/unit_test/light_emergency_reset_stops_processing
	var/area/test_area
	var/original_power_light
	var/original_lightswitch

/datum/unit_test/light_emergency_reset_stops_processing/New()
	..()
	test_area = get_area(run_loc_floor_bottom_left)
	original_power_light = test_area.power_light
	original_lightswitch = test_area.lightswitch

/datum/unit_test/light_emergency_reset_stops_processing/Destroy()
	if(test_area)
		test_area.power_light = original_power_light
		test_area.lightswitch = original_lightswitch
	return ..()

/datum/unit_test/light_emergency_reset_stops_processing/Run()
	var/obj/machinery/light/test_light = allocate(/obj/machinery/light, run_loc_floor_bottom_left)
	test_area.power_light = FALSE
	test_area.lightswitch = TRUE
	test_light.status = LIGHT_OK
	test_light.on = FALSE
	test_light.emergency_mode = TRUE
	test_light.power_loss_stage = 3
	test_light.cell.charge = 0
	START_PROCESSING(SSmachines, test_light)
	TEST_ASSERT(test_light in SSmachines.processing, "Emergency-mode fixture should start in machine processing.")
	test_light.emergency_flicker_tick()
	TEST_ASSERT(!(test_light in SSmachines.processing), "Emergency reset without station power should remove the fixture from machine processing.")
	TEST_ASSERT(!test_light.emergency_mode, "Emergency reset should clear emergency_mode.")
	TEST_ASSERT_EQUAL(test_light.power_loss_stage, 0, "Emergency reset should clear the power-loss stage.")
