/datum/unit_test/lighting_object_destroy_clears_blend_queue/Run()
	TEST_ASSERT(SSlighting.initialized, "SSlighting was not initialized")

	var/turf/test_turf = run_loc_floor_bottom_left
	TEST_ASSERT_NULL(test_turf.lighting_object, "Test turf unexpectedly already had a lighting object")

	test_turf.set_light(MINIMUM_USEFUL_LIGHT_RANGE, 1)
	sleep(1)
	TEST_ASSERT(test_turf.light_sources, "Test turf did not acquire a light source")

	test_turf.lighting_build_overlay()

	var/atom/movable/lighting_object/test_object = test_turf.lighting_object
	TEST_ASSERT_NOTNULL(test_object, "lighting_build_overlay() did not create a lighting object")

	test_turf.recalc_area_blend_region()

	TEST_ASSERT(test_object in GLOB.lighting_update_blends, "Lighting object was not queued for area blend recalculation")

	qdel(test_object, force = TRUE)

	TEST_ASSERT_NULL(test_turf.lighting_object, "Force-qdeleted lighting object was still attached to the turf")
	TEST_ASSERT(!(test_object in GLOB.lighting_update_objects), "Force-qdeleted lighting object remained in lighting_update_objects")
	TEST_ASSERT(!(test_object in GLOB.lighting_update_blends), "Force-qdeleted lighting object remained in lighting_update_blends")

	test_turf.set_light(0)
