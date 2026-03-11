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
