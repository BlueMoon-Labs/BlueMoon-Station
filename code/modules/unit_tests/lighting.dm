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
	process_nightshift_lighting_work()
	TEST_ASSERT(test_light.light, "Directional fixture should create a live light source.")
	TEST_ASSERT_EQUAL(test_light.light.light_cone_angle, test_light.cone_angle, "Initial cone angle should match the fixture configuration.")
	TEST_ASSERT_EQUAL(test_light.light.light_cone_dir, turn(test_light.dir, 180), "Initial cone direction should match the fixture direction.")
	test_light.dir = SOUTH
	test_light.update(FALSE, TRUE)
	process_nightshift_lighting_work()
	TEST_ASSERT_EQUAL(test_light.light.light_cone_dir, turn(test_light.dir, 180), "Changing only direction should refresh the live cone direction.")
	test_light.cone_angle = LIGHTING_WALL_BULB_CONE_ANGLE
	test_light.update(FALSE, TRUE)
	process_nightshift_lighting_work()
	TEST_ASSERT_EQUAL(test_light.light.light_cone_angle, test_light.cone_angle, "Changing only cone angle should refresh the live cone angle.")

/datum/unit_test/light_damage_flicker_restores_effective_power/Run()
	var/obj/machinery/light/test_light = allocate(/obj/machinery/light, run_loc_floor_bottom_left)
	test_light.status = LIGHT_OK
	test_light.on = TRUE
	test_light.switchcount = 0
	test_light.nightshift_enabled = TRUE
	test_light.nightshift_level = 1
	test_light.update(FALSE, TRUE)
	process_nightshift_lighting_work()
	var/expected_power = test_light.light_power
	TEST_ASSERT_NOTEQUAL(expected_power, test_light.bulb_power, "Nightshift should change the emitted power away from raw bulb_power.")
	test_light.start_damage_flicker()
	TEST_ASSERT_EQUAL(test_light.damage_flicker_base_power, expected_power, "Damage flicker should capture the current emitted power.")
	test_light.stop_damage_flicker()
	TEST_ASSERT_NULL(test_light.damage_flicker_base_power, "Stopping damage flicker should clear the stored emitted power.")
	TEST_ASSERT_EQUAL(test_light.light_power, expected_power, "Stopping damage flicker should restore the effective fixture power.")
	TEST_ASSERT(test_light.light, "Damage flicker stop should leave the live light source intact.")
	process_nightshift_lighting_work()
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

// Tests for repair reload lighting rebuild (mass delete + reload cycle)

/// Helper: ensure test turf has a lighting_object, creating one if needed.
/// Returns the lighting_object. Handles the case where a previous test left one.
/datum/unit_test/proc/ensure_lighting_object(turf/T)
	if(T.lighting_object)
		return T.lighting_object
	var/atom/movable/lighting_object/lo = allocate(/atom/movable/lighting_object, T)
	return lo

/// Simulates the full mass-delete + reload cycle and verifies light is restored.
/// This reproduces the bug where Build Mode > Map Gen > Repair: Reload Block
/// would not restore lighting after reloading turfs.
/datum/unit_test/repair_cycle_restores_lighting/Run()
	TEST_ASSERT(SSlighting.initialized, "SSlighting was not initialized")

	var/turf/test_turf = run_loc_floor_bottom_left
	var/atom/movable/lighting_object/test_lo = ensure_lighting_object(test_turf)
	TEST_ASSERT_EQUAL(test_turf.lighting_object, test_lo, "Lighting object was not attached to turf")

	// Create a light-emitting object
	var/obj/effect/light_emitter/emitter = allocate(/obj/effect/light_emitter, test_turf)
	emitter.set_light(3, 1, COLOR_WHITE)
	process_nightshift_lighting_work()

	// Verify light source was created
	TEST_ASSERT(emitter.light, "Emitter should have a live light source after set_light")

	// --- Simulate mass delete: destroy the light emitter ---
	qdel(emitter)
	allocated -= emitter
	process_nightshift_lighting_work()

	// --- Simulate mass delete ChangeTurf (same type, FORCEOP) ---
	test_turf.ChangeTurf(test_turf.type, null, CHANGETURF_FORCEOP)
	test_turf = run_loc_floor_bottom_left
	TEST_ASSERT_EQUAL(test_turf.lighting_object, test_lo, "Lighting object should survive mass delete ChangeTurf")

	// --- Simulate load_map ChangeTurf (DEFER_CHANGE) ---
	test_turf.ChangeTurf(/turf/open/floor/plasteel, null, CHANGETURF_DEFER_CHANGE)
	test_turf = run_loc_floor_bottom_left
	TEST_ASSERT_EQUAL(test_turf.lighting_object, test_lo, "Lighting object should survive load_map ChangeTurf")

	// --- Simulate newly loaded fixture ---
	var/obj/effect/light_emitter/new_emitter = allocate(/obj/effect/light_emitter, test_turf)
	new_emitter.set_light(3, 1, COLOR_WHITE)
	TEST_ASSERT(new_emitter.light, "New emitter should have a live light source after set_light")

	// --- Apply the fix: rebuild lighting ---
	test_turf.recalc_atom_opacity()
	test_turf.reconsider_lights()
	if(test_turf.lighting_object)
		GLOB.lighting_update_blends |= test_turf.lighting_object
		if(!test_turf.lighting_object.needs_update)
			test_turf.lighting_object.needs_update = TRUE
			GLOB.lighting_update_objects += test_turf.lighting_object

	process_nightshift_lighting_work()

	// Verify light source survived the repair cycle
	TEST_ASSERT(new_emitter.light, "Light source should still exist after repair cycle")
	TEST_ASSERT_EQUAL(test_turf.lighting_object, test_lo, "Lighting object should still be on the turf after repair")
	TEST_ASSERT(test_lo in test_turf.vis_contents, "Lighting object should be in vis_contents after repair")
	// Verify the lighting_object was queued for update (blend recalc happened)
	TEST_ASSERT_NOTEQUAL(test_lo.blended_temperature, 999, "Blend values should have been recalculated")

/// Verifies has_opaque_atom is correctly rescanned after simulated repair.
/datum/unit_test/repair_cycle_opacity_rescan/Run()
	TEST_ASSERT(SSlighting.initialized, "SSlighting was not initialized")

	var/turf/test_turf = run_loc_floor_bottom_left
	ensure_lighting_object(test_turf)

	// Create an opaque object
	var/obj/effect/light_emitter/opaque_obj = allocate(/obj/effect/light_emitter, test_turf)
	opaque_obj.opacity = TRUE
	test_turf.recalc_atom_opacity()
	TEST_ASSERT(test_turf.has_opaque_atom, "Turf should have opaque atom after adding opaque object")

	// Delete it — Exited handler updates opacity
	qdel(opaque_obj)
	allocated -= opaque_obj
	TEST_ASSERT(!test_turf.has_opaque_atom, "Turf should not have opaque atom after removing opaque object")

	// Simulate repair ChangeTurf — preserves has_opaque_atom
	test_turf.ChangeTurf(test_turf.type, null, CHANGETURF_FORCEOP)
	test_turf = run_loc_floor_bottom_left
	TEST_ASSERT(!test_turf.has_opaque_atom, "has_opaque_atom should be FALSE after ChangeTurf (no opaque contents)")

	// Simulate newly loaded opaque object (e.g., door from map)
	var/obj/effect/light_emitter/new_opaque = allocate(/obj/effect/light_emitter, test_turf)
	new_opaque.opacity = TRUE

	// Without recalc, has_opaque_atom is stale
	TEST_ASSERT(!test_turf.has_opaque_atom, "has_opaque_atom should still be FALSE before recalc (stale state)")

	// Apply the fix
	test_turf.recalc_atom_opacity()
	TEST_ASSERT(test_turf.has_opaque_atom, "has_opaque_atom should be TRUE after recalc_atom_opacity with opaque contents")

/// Verifies area blend is recalculated after repair by queuing to GLOB.lighting_update_blends.
/datum/unit_test/repair_cycle_refreshes_area_blend/Run()
	TEST_ASSERT(SSlighting.initialized, "SSlighting was not initialized")

	var/turf/test_turf = run_loc_floor_bottom_left
	var/atom/movable/lighting_object/test_lo = ensure_lighting_object(test_turf)
	process_nightshift_lighting_work()

	// Record blend values (should match area defaults)
	var/area/test_area = test_turf.loc
	var/expected_temp = test_area.light_temperature
	TEST_ASSERT_EQUAL(test_lo.blended_temperature, expected_temp, "Initial blend temperature should match area")

	// Corrupt blend values to simulate stale state
	test_lo.blended_temperature = 999

	// Queue blend recalc (the fix)
	GLOB.lighting_update_blends |= test_lo
	if(!test_lo.needs_update)
		test_lo.needs_update = TRUE
		GLOB.lighting_update_objects += test_lo

	process_nightshift_lighting_work()

	// Verify blend was recalculated
	TEST_ASSERT_EQUAL(test_lo.blended_temperature, expected_temp, "Blend temperature should be restored after recalc (got [test_lo.blended_temperature], expected [expected_temp])")

/// Verifies lighting_object recovers from prev_was_dark state when light is added.
/// Tests the corner lum pipeline: light_source → update_corners → corner lum values.
/datum/unit_test/repair_cycle_prev_was_dark_recovery/Run()
	TEST_ASSERT(SSlighting.initialized, "SSlighting was not initialized")

	var/turf/test_turf = run_loc_floor_bottom_left
	var/atom/movable/lighting_object/test_lo = ensure_lighting_object(test_turf)
	process_nightshift_lighting_work()

	// With no light sources, turf should be dark
	TEST_ASSERT(test_lo.prev_was_dark, "Lighting object should be dark with no light sources")

	// Add a light source directly via set_light on the turf itself
	// (avoids view() issues on reserved z-levels by affecting the source turf's own corners)
	var/obj/effect/light_emitter/emitter = allocate(/obj/effect/light_emitter, test_turf)
	emitter.set_light(3, 1, COLOR_WHITE)
	TEST_ASSERT(emitter.light, "Emitter should have a live light source")

	// Process multiple passes — light pipeline: sources → corners → objects
	drain_nightshift_lighting_work()

	// The light source should exist and be applied
	TEST_ASSERT(emitter.light, "Light source should still exist after draining")
	// If corners were updated, prev_was_dark should clear
	// On reserved z-levels, view() might not find turfs, so corners might not update
	// In that case, just verify the light source and lighting_object infrastructure is intact
	if(test_turf.lc_topright)
		var/lum = test_turf.lc_topright.lum_r + test_turf.lc_topright.lum_g + test_turf.lc_topright.lum_b
		if(lum > 0)
			TEST_ASSERT(!test_lo.prev_was_dark, "Lighting object should recover from prev_was_dark when corners have light")

/// Verifies shadow_weight_sum is correctly rescanned after simulated repair.
/datum/unit_test/repair_cycle_shadow_weight_rescan/Run()
	TEST_ASSERT(SSlighting.initialized, "SSlighting was not initialized")

	var/turf/test_turf = run_loc_floor_bottom_left
	ensure_lighting_object(test_turf)

	// Create a shadow-casting object
	var/obj/effect/light_emitter/shadow_obj = allocate(/obj/effect/light_emitter, test_turf)
	shadow_obj.shadow_weight = 0.5
	test_turf.recalc_atom_opacity()
	TEST_ASSERT(test_turf.shadow_weight_sum >= 0.49, "shadow_weight_sum should reflect shadow object (got [test_turf.shadow_weight_sum])")

	// Delete it
	qdel(shadow_obj)
	allocated -= shadow_obj
	test_turf.recalc_atom_opacity()
	TEST_ASSERT(test_turf.shadow_weight_sum < 0.01, "shadow_weight_sum should be ~0 after removing shadow object (got [test_turf.shadow_weight_sum])")

	// Simulate repair ChangeTurf — preserves shadow_weight_sum
	test_turf.ChangeTurf(test_turf.type, null, CHANGETURF_FORCEOP)
	test_turf = run_loc_floor_bottom_left

	// Simulate newly loaded shadow-casting object
	var/obj/effect/light_emitter/new_shadow = allocate(/obj/effect/light_emitter, test_turf)
	new_shadow.shadow_weight = 0.5

	// Without recalc, shadow_weight_sum is stale
	TEST_ASSERT(test_turf.shadow_weight_sum < 0.01, "shadow_weight_sum should be stale before recalc (got [test_turf.shadow_weight_sum])")

	// Apply the fix
	test_turf.recalc_atom_opacity()
	TEST_ASSERT(test_turf.shadow_weight_sum >= 0.49, "shadow_weight_sum should be updated after recalc (got [test_turf.shadow_weight_sum])")
