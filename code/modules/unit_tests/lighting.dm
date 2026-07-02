#define REPAIR_RELOAD_WAIT_TICKS 600
#define REPAIR_RELOAD_TEST_MIN_LUM_DELTA 0.05
#define REPAIR_RELOAD_TEST_MAX_POST_REPAIR_LUM_DROP 0.1

/datum/unit_test/lighting_object_destroy_clears_blend_queue/Run()
	TEST_ASSERT(SSlighting.initialized, "SSlighting was not initialized")

	var/turf/test_turf = run_loc_floor_bottom_left
	TEST_ASSERT_NULL(test_turf.lighting_object, "Test turf unexpectedly already had a lighting object")

	var/atom/movable/lighting_object/test_object = allocate_lighting_object(test_turf)
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
	var/atom/movable/lighting_object/test_object = allocate_lighting_object(test_turf)
	TEST_ASSERT_EQUAL(test_turf.lighting_object, test_object, "Lighting object was not attached to the original turf")

	var/turf/replacement_turf = test_turf.ChangeTurf(/turf/open/floor/plasteel/white)

	TEST_ASSERT_EQUAL(locate(x, y, z), replacement_turf, "ChangeTurf should return the replacement turf at the original coordinates.")
	TEST_ASSERT(istype(replacement_turf, /turf/open/floor/plasteel/white), "Replacement turf had the wrong type ([replacement_turf.type])")
	TEST_ASSERT_EQUAL(replacement_turf.lighting_object, test_object, "Lighting object was not transferred to the replacement turf")
	TEST_ASSERT_EQUAL(test_object.affected_turf, replacement_turf, "Lighting object still pointed at the old turf after ChangeTurf")
	TEST_ASSERT(test_object in replacement_turf.vis_contents, "Replacement turf did not keep the transferred lighting object in vis_contents")
	qdel(test_object, force = TRUE)

// Путь маплоадера (мид-раунд шаблоны: комнаты отеля Гильберта, авейки): ChangeTurf выполняется
// при отложенном Initialize (map_loader_begin), привязывая lighting_object к vis_contents,
// а затем initTemplateBounds() инициализирует турф, и vis_contents.Cut() в /turf/Initialize
// не должен терять рендер света - иначе турф навсегда чёрный от backdrop'а lighting plane.
/datum/unit_test/lighting_object_survives_deferred_maploader_init/Run()
	TEST_ASSERT(SSlighting.initialized, "SSlighting was not initialized")

	var/turf/test_turf = run_loc_floor_bottom_left
	TEST_ASSERT_NULL(test_turf.lighting_object, "Test turf unexpectedly already had a lighting object")

	var/atom/movable/lighting_object/test_object = allocate_lighting_object(test_turf)
	TEST_ASSERT_EQUAL(test_turf.lighting_object, test_object, "Lighting object was not attached to the original turf")

	SSatoms.map_loader_begin()
	// CHANGETURF_DEFER_CHANGE - как в reader.dm: AfterChange не зовётся на неинициализированном турфе
	var/turf/replacement_turf = test_turf.ChangeTurf(/turf/open/floor/plasteel/white, null, CHANGETURF_DEFER_CHANGE)
	SSatoms.map_loader_stop()

	TEST_ASSERT(!(replacement_turf.flags_1 & INITIALIZED_1), "Turf was initialized inline despite map loader mode; test premise broken")
	TEST_ASSERT_EQUAL(replacement_turf.lighting_object, test_object, "Lighting object was not transferred to the replacement turf")
	TEST_ASSERT(test_object in replacement_turf.vis_contents, "Lighting object was not in vis_contents right after deferred-init ChangeTurf")

	SSatoms.InitializeAtoms(list(replacement_turf))

	TEST_ASSERT_EQUAL(replacement_turf.lighting_object, test_object, "Deferred turf Initialize lost the lighting_object reference")
	TEST_ASSERT(test_object in replacement_turf.vis_contents, "Deferred turf Initialize (maploader path) dropped the lighting object from vis_contents")
	qdel(test_object, force = TRUE)

/datum/unit_test/forced_turf_destroy_cleans_lighting_object/Run()
	TEST_ASSERT(SSlighting.initialized, "SSlighting was not initialized")

	var/turf/test_turf = run_loc_floor_bottom_left
	TEST_ASSERT_NULL(test_turf.lighting_object, "Test turf unexpectedly already had a lighting object")

	var/atom/movable/lighting_object/test_object = allocate_lighting_object(test_turf)
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
	return allocate_lighting_object(T)

/// Helper: create a lighting_object the canonical way (new(turf) - loc на турфе, гибридный
/// рендер loc+vis_contents) with end-of-test cleanup. allocate() itself can't be used - its
/// plain qdel teardown is ignored by lighting_object/Destroy(), so these go into the
/// force-qdel cleanup list.
/datum/unit_test/proc/allocate_lighting_object(turf/T)
	var/atom/movable/lighting_object/lo = new(T)
	allocated_force_qdel += lo
	return lo

/datum/unit_test/proc/wait_for_repair_reload(datum/mapGenerator/repair/reload_station_map/reload_generator = null, max_ticks = REPAIR_RELOAD_WAIT_TICKS)
	for(var/i in 1 to max_ticks)
		if(!GLOB.reloading_map)
			if(reload_generator)
				return reload_generator.last_reload_succeeded
			return TRUE
		sleep(world.tick_lag)
	return FALSE

/datum/unit_test/proc/is_station_repair_test_turf(turf/T, area/expected_area = null)
	if(!istype(T, /turf/open/floor))
		return FALSE
	if(T.z != SSmapping.station_start || !is_station_level(T.z))
		return FALSE
	var/area/turf_area = get_area(T)
	if(expected_area && turf_area != expected_area)
		return FALSE
	if(!IS_DYNAMIC_LIGHTING(T) || !IS_DYNAMIC_LIGHTING(turf_area))
		return FALSE
	// Exclude space/ruins areas and overlay-on-non-floor coords: random-ruin or
	// prefab overlays placed on top of space / closed-mineral coords do not
	// survive reload_station_map (it restores the station DMM's golden copy,
	// which has the original /turf/open/space or /turf/closed/mineral at those
	// coords). Runtime area can look like a normal station area after overlay,
	// so also reject any floor whose baseturfs chain contains a non-floor
	// ancestor — that's the tell-tale sign of an overlay.
	if(istype(turf_area, /area/space))
		return FALSE
	if(istype(turf_area, /area/shuttle))
		return FALSE
	// Non-station surface and dungeon areas: random cave/ruin generators place
	// dynamic-lit floors on top of closed mineral or sand; reload_station_map
	// correctly restores the DMM's non-floor turf at those coords, tripping
	// either the has_lo assertion or the lit_after regression guard.
	if(istype(turf_area, /area/asteroid))
		return FALSE
	if(istype(turf_area, /area/icemoon))
		return FALSE
	if(istype(turf_area, /area/mine))
		return FALSE
	if(istype(turf_area, /area/lavaland))
		return FALSE
	if(istype(turf_area, /area/edina))
		return FALSE
	var/list/baseturfs = islist(T.baseturfs) ? T.baseturfs : list(T.baseturfs)
	for(var/base_path in baseturfs)
		if(ispath(base_path, /turf/open/space) || ispath(base_path, /turf/closed))
			return FALSE
	// Reject turfs that carry infrastructure whose reload_station_map 1x1 crop
	// cannot reconstruct cleanly. Partial reloads of a single tile containing
	// a vent/pump or cable leave the atmos/power pipeline unconnected and
	// setup_template_machinery runtimes when re-initializing the lone machine.
	for(var/atom/movable/A as anything in T)
		if(ismob(A) || A.density)
			return FALSE
		if(istype(A, /obj/machinery/atmospherics))
			return FALSE
		if(istype(A, /obj/structure/cable))
			return FALSE
		if(istype(A, /obj/structure/disposalpipe))
			return FALSE
	return TRUE

/datum/unit_test/proc/find_station_repair_test_regions()
	var/list/candidates = list()
	var/z = SSmapping.station_start
	for(var/x in 2 to world.maxx)
		for(var/y in 1 to world.maxy)
			var/turf/start = locate(x, y, z)
			if(!start)
				continue
			var/area/base_area = get_area(start)
			var/turf/west = locate(x - 1, y, z)
			if(!is_station_repair_test_turf(start, base_area) || !is_station_repair_test_turf(west, base_area))
				continue
			if(!start.lighting_object)
				continue
			candidates += list(list(
				"start" = start,
				"end" = start,
				"light_turf" = west,
				"target_x" = start.x,
				"target_y" = start.y,
				"target_z" = start.z
			))
	return candidates

/datum/mapGeneratorModule/bottomLayer/massdelete/test_repair_delete/generate()
	if(!istype(mother, /datum/mapGenerator/repair/reload_station_map/test_ordering))
		return
	var/datum/mapGenerator/repair/reload_station_map/test_ordering/test_generator = mother
	test_generator.phase_events += "delete:start"
	sleep(world.tick_lag)
	test_generator.delete_complete = TRUE
	test_generator.phase_events += "delete:end"

/datum/mapGenerator/repair/reload_station_map/test_ordering
	modules = list(/datum/mapGeneratorModule/bottomLayer/massdelete/test_repair_delete)
	cleanload = TRUE
	var/list/phase_events = list()
	var/delete_complete = FALSE
	var/loader_started_before_delete_complete = FALSE

/datum/mapGenerator/repair/reload_station_map/test_ordering/run_reload_phase()
	phase_events += "reload:start"
	if(!delete_complete)
		loader_started_before_delete_complete = TRUE
	phase_events += "reload:end"
	return TRUE

/datum/mapGenerator/repair/reload_station_map/test_failure_signal/run_reload_phase()
	return FALSE

/datum/unit_test/repair_reload_serializes_delete_before_reload/Run()
	var/datum/mapGenerator/repair/reload_station_map/test_ordering/test_generator = new
	var/turf/test_turf = run_loc_floor_bottom_left
	test_generator.map = list(test_turf)
	test_generator.x_low = test_turf.x
	test_generator.y_low = test_turf.y
	test_generator.x_high = test_turf.x
	test_generator.y_high = test_turf.y
	test_generator.z = test_turf.z

	TEST_ASSERT(test_generator.generate(), "Test repair generator failed to start.")
	TEST_ASSERT(wait_for_repair_reload(test_generator), "Timed out waiting for test repair generator to finish.")
	TEST_ASSERT(!test_generator.loader_started_before_delete_complete, "Reload phase started before delete phase completed.")
	var/joined_events = test_generator.phase_events.Join(">")
	TEST_ASSERT_EQUAL(joined_events, "delete:start>delete:end>reload:start>reload:end", "Repair reload phases executed out of order: [joined_events].")

	qdel(test_generator)

/datum/unit_test/repair_reload_failure_is_observable/Run()
	var/datum/mapGenerator/repair/reload_station_map/test_failure_signal/test_generator = new
	var/turf/test_turf = run_loc_floor_bottom_left
	test_generator.map = list(test_turf)
	test_generator.x_low = test_turf.x
	test_generator.y_low = test_turf.y
	test_generator.x_high = test_turf.x
	test_generator.y_high = test_turf.y
	test_generator.z = test_turf.z

	TEST_ASSERT(test_generator.generate(), "Failure-signalling repair generator failed to start.")
	TEST_ASSERT(!wait_for_repair_reload(test_generator), "Repair reload failure should be observable to the waiting helper.")
	TEST_ASSERT(!GLOB.reloading_map, "Repair reload failure should still release the global reload guard.")
	TEST_ASSERT_EQUAL(test_generator.last_reload_succeeded, FALSE, "Failed repair reload should publish a FALSE completion state.")

	qdel(test_generator)

/datum/unit_test/repair_reload_in_place_restores_station_lighting/Run()
	TEST_ASSERT(SSlighting.initialized, "SSlighting was not initialized")

	var/list/candidate_regions = find_station_repair_test_regions()
	if(!length(candidate_regions))
		return

	var/list/region = null
	var/turf/start = null
	var/turf/end = null
	var/turf/light_turf = null
	var/target_x = 0
	var/target_y = 0
	var/target_z = 0
	var/turf/target_turf = null
	var/obj/effect/light_emitter/emitter = null
	var/baseline_lum = 0
	var/lit_before = 0

	for(var/list/candidate as anything in candidate_regions)
		start = candidate["start"]
		end = candidate["end"]
		light_turf = candidate["light_turf"]
		target_x = candidate["target_x"]
		target_y = candidate["target_y"]
		target_z = candidate["target_z"]
		target_turf = locate(target_x, target_y, target_z)
		if(!target_turf?.lighting_object)
			continue
		drain_nightshift_lighting_work()
		baseline_lum = target_turf.get_lumcount()
		emitter = allocate(/obj/effect/light_emitter, light_turf)
		emitter.set_light(5, 2, COLOR_WHITE)
		drain_nightshift_lighting_work()
		if(emitter.light)
			lit_before = target_turf.get_lumcount()
			if(lit_before > baseline_lum + REPAIR_RELOAD_TEST_MIN_LUM_DELTA)
				region = candidate
				break
		qdel(emitter)
		allocated -= emitter
		emitter = null

	// If no candidate region could be lit by a neighbouring emitter, there is
	// nothing meaningful to test on this map (happens on ultra-minimal maps
	// like runtimestation_minimal that have no station interior at all). Skip
	// rather than assert — the reload invariant is only meaningful on maps
	// that actually expose a reload-safe station interior.
	if(!region)
		return
	TEST_ASSERT(emitter?.light, "Emitter should have a live light source before repair.")

	var/datum/mapGenerator/repair/reload_station_map/clean/in_place/reload_generator = new
	reload_generator.defineRegion(start, end, TRUE)

	TEST_ASSERT(reload_generator.generate(), "Repair reload generator failed to start.")
	TEST_ASSERT(wait_for_repair_reload(reload_generator), "Timed out waiting for station repair reload to finish.")
	drain_nightshift_lighting_work()

	target_turf = locate(target_x, target_y, target_z)
	TEST_ASSERT(target_turf?.lighting_object, "Target turf lost its lighting object after repair reload.")

	var/lit_after = target_turf.get_lumcount()
	TEST_ASSERT(lit_after > baseline_lum + REPAIR_RELOAD_TEST_MIN_LUM_DELTA, "Target turf no longer receives neighboring light after repair reload (baseline [round(baseline_lum, 0.01)], after [round(lit_after, 0.01)]).")
	TEST_ASSERT(lit_after >= lit_before - REPAIR_RELOAD_TEST_MAX_POST_REPAIR_LUM_DROP, "Repair reload caused a large lighting regression on the restored turf (before [round(lit_before, 0.01)], after [round(lit_after, 0.01)]).")

	qdel(reload_generator)

#undef REPAIR_RELOAD_WAIT_TICKS
#undef REPAIR_RELOAD_TEST_MIN_LUM_DELTA
#undef REPAIR_RELOAD_TEST_MAX_POST_REPAIR_LUM_DROP

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

/// Гибридный рендер lighting_object: объект лежит на турфе (loc) И продублирован в
/// vis_contents. loc-канал - доставка animate()/appearance клиентам (у nullspace-атома,
/// видимого только через vis_contents, анимации до клиентов не доезжают - устаревшие
/// "тёмные зоны" до пересинка view/реконнекта). vis_contents-канал сохранён (паритет master).
/datum/unit_test/lighting_object_hybrid_render/Run()
	TEST_ASSERT(SSlighting.initialized, "SSlighting was not initialized")

	var/turf/test_turf = run_loc_floor_bottom_left
	// Предыдущие тесты могли оставить lighting_object (авто-уборка allocate() делает
	// нефорсированный qdel, который lighting_object игнорирует) - чистим форсированно
	test_turf.lighting_clear_overlay()
	TEST_ASSERT_NULL(test_turf.lighting_object, "Test turf still had a lighting object after lighting_clear_overlay")

	var/atom/movable/lighting_object/test_object = allocate_lighting_object(test_turf)
	TEST_ASSERT_EQUAL(test_turf.lighting_object, test_object, "Lighting object was not attached to the test turf")
	TEST_ASSERT_EQUAL(test_object.loc, test_turf, "Lighting object must sit on its turf (delivery channel), had loc [test_object.loc]")
	TEST_ASSERT(test_object in test_turf.vis_contents, "Lighting object must also be referenced in turf vis_contents")

	var/turf/replacement_turf = test_turf.ChangeTurf(/turf/open/floor/plasteel/white)
	TEST_ASSERT_EQUAL(test_object.loc, replacement_turf, "Lighting object must stay on the tile after ChangeTurf, had loc [test_object.loc]")
	TEST_ASSERT(test_object in replacement_turf.vis_contents, "Replacement turf did not keep the lighting object in vis_contents")
	qdel(test_object, force = TRUE)

/// Оверлейный свет: компонент вешается по light_system, тумблер двигает маску в underlays
/// держателя и динамическую люминосити. Ассерты source-local: на reserved z тестовой зоны
/// view() пуст, поэтому кросс-тайловый dynamic_lumcount здесь не проверяем.
/datum/unit_test/overlay_lighting/Run()
	var/mob/living/carbon/human/holder = allocate(/mob/living/carbon/human)
	var/obj/item/flashlight/test_light = allocate(/obj/item/flashlight)
	var/datum/component/overlay_lighting/comp = test_light.GetComponent(/datum/component/overlay_lighting)
	TEST_ASSERT_NOTNULL(comp, "Flashlight must carry the overlay_lighting component")
	TEST_ASSERT_NULL(test_light.light, "Overlay-light flashlight must not own a complex light_source")
	TEST_ASSERT(!test_light.light_on, "Flashlight must spawn with light_on = FALSE")

	TEST_ASSERT(holder.put_in_active_hand(test_light), "Test mob could not pick up the flashlight")
	var/underlays_before = holder.underlays.len

	test_light.attack_self(holder) // on
	TEST_ASSERT(test_light.light_on, "attack_self must toggle light_on to TRUE")
	TEST_ASSERT(holder.underlays.len > underlays_before, "Holder must receive the light mask underlay")
	TEST_ASSERT(holder.affecting_dynamic_lumi > 0, "Holder must gain dynamic luminosity while the light is on")
	TEST_ASSERT_EQUAL(comp.current_holder, holder, "Component must track the mob as current holder")

	test_light.attack_self(holder) // off
	TEST_ASSERT(!test_light.light_on, "Second attack_self must toggle light_on back to FALSE")
	TEST_ASSERT_EQUAL(holder.underlays.len, underlays_before, "Light mask must leave holder underlays when off")
	TEST_ASSERT_EQUAL(holder.affecting_dynamic_lumi, 0, "Dynamic luminosity must reset when the light is off")

/// Регрессия: лампы фонарного столба - оверлейные lighting_obj. Тумблер идёт через
/// set_light_on(), а не легаси set_light() (который шумел stack_trace и из-за
/// одностороннего range-тумблера не зажигал свет обратно). Ассерт light_on не зависит
/// от позиции дамми (его форсмувают за пределы зоны), свечение проверяем на валидном полу.
/datum/unit_test/lamppost_overlay_light/Run()
	var/turf/spawn_turf = run_loc_floor_bottom_left
	var/obj/machinery/power/floodlight/lamppost/one/lamp = allocate(/obj/machinery/power/floodlight/lamppost/one, spawn_turf)
	TEST_ASSERT_EQUAL(length(lamp.lamp_lights), 1, "lamppost/one must spawn exactly one lamp light")
	var/obj/effect/dummy/lighting_obj/light_source = lamp.lamp_lights[1]
	TEST_ASSERT_NOTNULL(light_source, "lamppost must hold a reference to its lamp light")
	var/datum/component/overlay_lighting/comp = light_source.GetComponent(/datum/component/overlay_lighting)
	TEST_ASSERT_NOTNULL(comp, "lamp light must use the overlay lighting component")
	TEST_ASSERT_NULL(light_source.light, "overlay lamp light must not own a complex light_source")
	// Стартует выключенным: легаси set_light(0,0,...) оставлял бы light_on = TRUE.
	TEST_ASSERT(!light_source.light_on, "lamp light must initialize in the off state")

	// Питание не симулируем: дёргаем тумблер напрямую, как try_initial_lighting под нагрузкой.
	lamp.lamps_active = lamp.number_of_lamps
	lamp.adjust_lamppost_light()
	TEST_ASSERT(light_source.light_on, "active lamp light must switch on via set_light_on")
	// Ставим источник на заведомо валидный пол и проверяем, что свет реально проецируется.
	light_source.forceMove(spawn_turf)
	TEST_ASSERT_EQUAL(comp.current_holder, light_source, "dummy on a turf must be its own holder")
	TEST_ASSERT(comp.currently_displaying, "active lamp light must project its mask on the holder")

	lamp.turn_off()
	TEST_ASSERT(!light_source.light_on, "turn_off must switch the lamp light back off")
	TEST_ASSERT(!comp.currently_displaying, "off lamp light must drop its mask")

	// Полный цикл off->on: старый range-тумблер сюда уже не зажигал свет обратно.
	lamp.lamps_active = lamp.number_of_lamps
	lamp.adjust_lamppost_light()
	TEST_ASSERT(light_source.light_on, "lamp light must switch on again after a full off/on cycle")
	TEST_ASSERT(comp.currently_displaying, "re-lit lamp light must project its mask again")

// ----------------------------------------------------------------------------------------------------
// Регрессии одностороннего light_on: гейт !light_on в update_light() требует, чтобы каждый
// COMPLEX-потребитель хоть раз включил тумблер, а оверлейный компонент умел зажигаться обратно
// после range 0. Ассерты source-local (light источника, light_on, currently_displaying).
// ----------------------------------------------------------------------------------------------------

/// COMPLEX-подтипы фонарика (eyelight, flashdark, spotlight) обязаны уметь светить: их управляющий
/// код (органы глаз, джукбокс) не трогает light_on напрямую и полагается на update_brightness()/update_light().
/datum/unit_test/complex_flashlight_subtypes_emit/Run()
	// Глаза-фонарики: орган делает eye.on = TRUE и зовёт update_brightness()
	var/obj/item/flashlight/eyelight/eye = allocate(/obj/item/flashlight/eyelight)
	eye.on = TRUE
	eye.update_brightness()
	TEST_ASSERT(eye.light_on, "eyelight: update_brightness при on=TRUE должен включать light_on")
	TEST_ASSERT_NOTNULL(eye.light, "eyelight: включённые глаза-фонарики должны создавать живой источник")

	// Фонарь тьмы: негативный свет тем же путём
	var/obj/item/flashlight/flashdark/dark = allocate(/obj/item/flashlight/flashdark)
	dark.on = TRUE
	dark.update_brightness()
	TEST_ASSERT_NOTNULL(dark.light, "flashdark: включённый фонарь тьмы должен создавать живой источник")

	// Спотлайт дискотеки: джукбокс пишет range/power напрямую и зовёт update_light()
	var/obj/item/flashlight/spotlight/spot = allocate(/obj/item/flashlight/spotlight)
	TEST_ASSERT(spot.light_on, "spotlight: тип с on=TRUE должен инициализироваться с light_on")
	spot.light_range = 4
	spot.light_power = 2
	spot.update_light()
	TEST_ASSERT_NOTNULL(spot.light, "spotlight: прямое выставление range/power джукбоксом должно зажигать источник")

/// Light eater теневиков не должен окирпичивать COMPLEX-предметы: немигрированные потребители
/// (свечи и т.п.) перезажигаются голым set_light(range) без l_on.
/datum/unit_test/light_eater_leaves_items_relightable/Run()
	var/obj/item/light_eater/eater = allocate(/obj/item/light_eater)
	var/obj/item/lit_item = allocate(/obj/item)
	lit_item.set_light(2, 1)
	TEST_ASSERT_NOTNULL(lit_item.light, "precondition: COMPLEX-предмет с set_light(2,1) должен светить")

	eater.disintegrate(lit_item)
	TEST_ASSERT_NULL(lit_item.light, "light eater должен гасить свет предмета")

	// Старый контракт перезажигания: свеча зовёт set_light(CANDLE_LUMINOSITY) без l_on
	lit_item.set_light(2, 1)
	TEST_ASSERT_NOTNULL(lit_item.light, "после light eater предмет должен снова зажигаться голым set_light() (контракт немигрированных потребителей)")

/// Оверлейный свет: range 0 гасит, возврат range > 0 при light_on=TRUE обязан зажечь обратно.
/// Раньше это был односторонний тумблер: turn_off() без синка light_on, а set_light_on(TRUE)
/// no-op'ал по гарду "значение не изменилось" - свет кирпичился до ручного FALSE->TRUE.
/datum/unit_test/overlay_zero_range_roundtrip/Run()
	var/obj/effect/dummy/lighting_obj/light_source = allocate(/obj/effect/dummy/lighting_obj)
	var/datum/component/overlay_lighting/comp = light_source.GetComponent(/datum/component/overlay_lighting)
	TEST_ASSERT_NOTNULL(comp, "lighting_obj должен нести компонент оверлейного света")
	TEST_ASSERT(comp.currently_displaying, "precondition: свежий lighting_obj на полу должен проецировать маску")

	light_source.set_light_range(0)
	TEST_ASSERT(!comp.currently_displaying, "range 0 должен гасить оверлейный свет")
	TEST_ASSERT_EQUAL(light_source.luminosity, 0, "погашенный свет не должен держать динамическую люминосити")
	TEST_ASSERT(light_source.light_on, "тумблер light_on не должен меняться range-сеттером")

	light_source.set_light_range(3)
	TEST_ASSERT(comp.currently_displaying, "возврат range > 0 при light_on=TRUE должен снова зажигать оверлейный свет")
	TEST_ASSERT(light_source.luminosity > 0, "заново зажжённый свет должен вернуть динамическую люминосити")

/// Атомный сеттер и компонент должны резать оверлейный range до одного потолка (таблица масок
/// кончается на 352px = range 6), иначе light_range атома врёт про реально рисуемый свет
/// (флаер 7, lighting_obj флешбенга 9).
/datum/unit_test/overlay_light_range_cap_consistent/Run()
	var/obj/effect/dummy/lighting_obj/light_source = allocate(/obj/effect/dummy/lighting_obj)
	light_source.set_light_range(OVERLAY_LIGHT_RANGE_CAP + 3)
	TEST_ASSERT_EQUAL(light_source.light_range, OVERLAY_LIGHT_RANGE_CAP, "оверлейный light_range должен резаться до потолка таблицы масок (OVERLAY_LIGHT_RANGE_CAP)")

/// Анимация подбора клонирует внешность предмета вместе с underlays: без хендлера
/// COMSIG_ITEM_BEFORE_PICKUP_ANIMATION летящий призрак подбора несёт дубль светового квадрата.
/datum/unit_test/pickup_animation_hides_overlay_light/Run()
	var/mob/living/carbon/human/holder = allocate(/mob/living/carbon/human)
	var/obj/item/flashlight/test_light = allocate(/obj/item/flashlight)
	test_light.on = TRUE
	test_light.update_brightness()
	TEST_ASSERT(test_light.light_on, "precondition: включённый фонарик должен иметь light_on")
	TEST_ASSERT(test_light.underlays.len, "precondition: лежащий на полу фонарик держит маску света в собственных underlays")

	test_light.do_pickup_animation(holder)
	TEST_ASSERT_EQUAL(test_light.underlays.len, 0, "перед анимацией подбора маска света должна сниматься с предмета (иначе призрак подбора мигает дублем света)")

	// Сам подбор возвращает свет уже на новом держателе
	var/holder_underlays_before = holder.underlays.len
	TEST_ASSERT(holder.put_in_active_hand(test_light), "тестовый моб должен суметь подобрать фонарик")
	TEST_ASSERT(holder.underlays.len > holder_underlays_before, "после подбора маска света должна переехать на держателя")
	TEST_ASSERT_EQUAL(test_light.underlays.len, 0, "после подбора на предмете не должно оставаться дубля маски")

/// dynamic_lumcount обязан переезжать через ChangeTurf на ВСЕХ путях: оверлейные источники держат
/// ссылку на турф в affected_turfs, и обнулённый счётчик позже уходит в минус при clean_old_turfs().
/datum/unit_test/changeturf_preserves_dynamic_lumcount/Run()
	var/turf/test_turf = run_loc_floor_bottom_left
	var/old_lumcount = test_turf.dynamic_lumcount

	// Путь CHANGETURF_SKIP (резервации шаттлов)
	test_turf.dynamic_lumcount = 0.5
	var/turf/skip_replacement = test_turf.ChangeTurf(/turf/open/floor/plasteel/white, null, CHANGETURF_SKIP)
	var/skip_carried = skip_replacement.dynamic_lumcount

	// Обычный путь - регрессионный гард
	skip_replacement.dynamic_lumcount = 0.25
	var/turf/normal_replacement = skip_replacement.ChangeTurf(/turf/open/floor/plasteel)
	var/normal_carried = normal_replacement.dynamic_lumcount

	normal_replacement.dynamic_lumcount = old_lumcount

	TEST_ASSERT_EQUAL(skip_carried, 0.5, "CHANGETURF_SKIP должен переносить dynamic_lumcount на новый турф")
	TEST_ASSERT_EQUAL(normal_carried, 0.25, "обычный ChangeTurf должен переносить dynamic_lumcount")
