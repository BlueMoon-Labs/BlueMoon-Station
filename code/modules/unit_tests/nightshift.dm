/datum/unit_test/proc/nightshift_lighting_work_pending()
	return length(GLOB.nightshift_apc_queue) || length(GLOB.nightshift_light_queue) || length(GLOB.lighting_update_blends) || length(GLOB.lighting_update_lights) || length(GLOB.lighting_update_corners) || length(GLOB.lighting_update_objects)

/datum/unit_test/proc/process_nightshift_lighting_work()
	SSlighting.process_nightshift_queues(TRUE)

	if(GLOB.lighting_update_blends.len)
		var/list/pending_blends = GLOB.lighting_update_blends.Copy()
		GLOB.lighting_update_blends.Cut()
		for(var/atom/movable/lighting_object/blend_obj as anything in pending_blends)
			if(!QDELETED(blend_obj))
				blend_obj.calculate_area_blend()

	if(GLOB.lighting_update_lights.len)
		var/list/pending_sources = GLOB.lighting_update_lights.Copy()
		GLOB.lighting_update_lights.Cut()
		for(var/datum/light_source/light_source as anything in pending_sources)
			if(QDELETED(light_source))
				continue
			light_source.update_corners()
			light_source.needs_update = LIGHTING_NO_UPDATE

	if(GLOB.lighting_update_corners.len)
		var/list/pending_corners = GLOB.lighting_update_corners.Copy()
		GLOB.lighting_update_corners.Cut()
		for(var/datum/lighting_corner/corner as anything in pending_corners)
			if(QDELETED(corner))
				continue
			corner.update_objects()
			corner.needs_update = FALSE

	if(GLOB.lighting_update_objects.len)
		var/list/pending_objects = GLOB.lighting_update_objects.Copy()
		GLOB.lighting_update_objects.Cut()
		for(var/atom/movable/lighting_object/lighting_object as anything in pending_objects)
			if(QDELETED(lighting_object))
				continue
			if(!lighting_object.affected_turf)
				qdel(lighting_object, force = TRUE)
				continue
			lighting_object.update(use_animate = FALSE)
			lighting_object.needs_update = FALSE

/datum/unit_test/proc/drain_nightshift_lighting_work(max_passes = 40)
	for(var/i in 1 to max_passes)
		if(nightshift_lighting_work_pending())
			process_nightshift_lighting_work()
		if(!nightshift_lighting_work_pending() && !SSnightshift.nightshift_refresh_running)
			return
		sleep(world.tick_lag)

/datum/unit_test/proc/assert_live_light_matches_fixture(obj/machinery/light/test_light, message_prefix = "Fixture")
	drain_nightshift_lighting_work()
	TEST_ASSERT(test_light.light, "[message_prefix] should have a live light source.")
	TEST_ASSERT_EQUAL(test_light.light.light_power, test_light.light_power, "[message_prefix] light source power should match the fixture state.")
	TEST_ASSERT_EQUAL(lowertext(test_light.light.light_color), lowertext(test_light.light_color), "[message_prefix] light source color should match the fixture state.")

/datum/unit_test/nightshift_profile/Run()
	TEST_ASSERT_EQUAL(SSnightshift.compute_indoor_nightshift_level(19 HOURS + 30 MINUTES), 0.2, "Nightshift profile should start with a light blue tint at 19:30.")
	TEST_ASSERT_EQUAL(SSnightshift.compute_indoor_nightshift_level(21 HOURS), 0.55, "Nightshift profile should deepen by 21:00.")
	TEST_ASSERT_EQUAL(SSnightshift.compute_indoor_nightshift_level(23 HOURS + 30 MINUTES), 1, "Nightshift profile should reach deep night at 23:30.")
	TEST_ASSERT_EQUAL(SSnightshift.compute_indoor_nightshift_level(6 HOURS), 0.35, "Nightshift profile should ease off by 06:00.")
	TEST_ASSERT_EQUAL(SSnightshift.compute_indoor_nightshift_level(7 HOURS + 30 MINUTES), 0, "Nightshift profile should end at 07:30.")
	TEST_ASSERT(SSnightshift.is_solar_time_night(SSnightshift.nightshift_start_time), "Night start should be inclusive at the configured boundary.")

/datum/unit_test/nightshift_light_colors/Run()
	var/obj/machinery/light/default_light = allocate(/obj/machinery/light, run_loc_floor_bottom_left)
	default_light.status = LIGHT_OK
	default_light.on = TRUE
	default_light.switchcount = 0
	default_light.update(FALSE, TRUE)
	assert_live_light_matches_fixture(default_light, "Daytime fixture")

	TEST_ASSERT_EQUAL(default_light.light_power, default_light.bulb_power, "Daytime lighting should preserve the base bulb power.")
	TEST_ASSERT_EQUAL(default_light.light_color, default_light.bulb_colour, "Daytime lighting should preserve the base bulb colour.")

	default_light.nightshift_enabled = TRUE
	default_light.nightshift_level = 1
	default_light.switchcount = 0
	default_light.update(FALSE, TRUE)
	assert_live_light_matches_fixture(default_light, "Deep-night fixture")
	var/list/deep_night_overlays = default_light.update_overlays()

	TEST_ASSERT_EQUAL(default_light.light_color, "#A9BFFF", "Default nightshift lighting should use the configured deep-night tint.")
	TEST_ASSERT_EQUAL(default_light.light_power, default_light.nightshift_light_power, "Deep night should reach the configured nightshift power.")
	TEST_ASSERT_EQUAL(lowertext(default_light.light.light_color), lowertext("#A9BFFF"), "Deep-night emitted light should use the configured tint.")
	TEST_ASSERT_EQUAL(default_light.light.light_power, default_light.nightshift_light_power, "Deep-night emitted light should reach the configured nightshift power.")
	TEST_ASSERT(length(deep_night_overlays) >= 2, "Lit fixtures should add both visible and emissive nightshift overlays.")
	for(var/mutable_appearance/O as anything in deep_night_overlays)
		TEST_ASSERT_EQUAL(lowertext(O.color), lowertext("#A9BFFF"), "Deep-night overlays should visibly carry the nightshift tint.")

	default_light.nightshift_level = 0.2
	default_light.switchcount = 0
	default_light.update(FALSE, TRUE)
	assert_live_light_matches_fixture(default_light, "Partial-night fixture")

	TEST_ASSERT(default_light.light_power < default_light.bulb_power, "Partial nightshift should dim lights below daytime power.")
	TEST_ASSERT(default_light.light_power > default_light.nightshift_light_power, "Partial nightshift should not jump straight to deep-night power.")

	var/turf/second_turf = locate(run_loc_floor_bottom_left.x + 1, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/obj/machinery/light/warm/warm_light = allocate(/obj/machinery/light/warm, second_turf)
	warm_light.status = LIGHT_OK
	warm_light.on = TRUE
	warm_light.nightshift_enabled = TRUE
	warm_light.nightshift_level = 1
	warm_light.switchcount = 0
	warm_light.update(FALSE, TRUE)
	assert_live_light_matches_fixture(warm_light, "Warm-night fixture")

	TEST_ASSERT_EQUAL(warm_light.light_color, warm_light.bulb_colour, "Warm lights with a null nightshift tint should keep their own bulb colour.")
	TEST_ASSERT_EQUAL(warm_light.light_power, warm_light.nightshift_light_power, "Warm lights should still dim to the configured nightshift power.")

	var/turf/third_turf = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/obj/machinery/light/small/default_bulb = allocate(/obj/machinery/light/small, third_turf)
	default_bulb.status = LIGHT_OK
	default_bulb.on = TRUE
	default_bulb.nightshift_enabled = TRUE
	default_bulb.nightshift_level = 1
	default_bulb.switchcount = 0
	default_bulb.update(FALSE, TRUE)
	assert_live_light_matches_fixture(default_bulb, "Default small bulb at night")

	TEST_ASSERT_EQUAL(default_bulb.light_color, default_bulb.nightshift_light_color, "Default small bulbs should inherit the stronger deep-night tint.")
	TEST_ASSERT_EQUAL(lowertext(default_bulb.light.light_color), lowertext("#A9BFFF"), "Default small bulbs should emit the stronger deep-night tint.")

/datum/unit_test/nightshift_queueing/Run()
	GLOB.nightshift_apc_queue.Cut()
	GLOB.nightshift_light_queue.Cut()
	var/obj/machinery/light/test_light = allocate(/obj/machinery/light, run_loc_floor_bottom_left)
	test_light.status = LIGHT_OK
	test_light.on = TRUE
	test_light.nightshift_enabled = TRUE
	test_light.nightshift_level = 1

	TEST_ASSERT(test_light.queue_nightshift_update(), "The first queue request should succeed.")
	TEST_ASSERT(!test_light.queue_nightshift_update(), "Duplicate queue requests should be ignored.")
	TEST_ASSERT_EQUAL(length(GLOB.nightshift_light_queue), 1, "Nightshift queue should not contain duplicates.")

	drain_nightshift_lighting_work()

	TEST_ASSERT(!test_light.nightshift_update_queued, "Nightshift queue processing should clear the queued flag.")
	TEST_ASSERT_EQUAL(length(GLOB.nightshift_light_queue), 0, "Nightshift queue should be drained by SSlighting.")
	TEST_ASSERT_EQUAL(length(GLOB.lighting_update_lights), 0, "Nightshift queue processing should also drain queued emitted-light updates.")
	assert_live_light_matches_fixture(test_light, "Queued nightshift fixture")

/datum/unit_test/nightshift_area_apc_fast_path/Run()
	var/area/test_area = get_area(run_loc_floor_bottom_left)
	var/obj/machinery/power/apc/original_area_apc = test_area.power_apc
	var/obj/machinery/power/apc/test_apc = allocate(/obj/machinery/power/apc, run_loc_floor_bottom_left)

	TEST_ASSERT_EQUAL(test_area.power_apc, test_apc, "APC initialization should seed the area APC fast path.")
	TEST_ASSERT_EQUAL(test_area.get_apc(), test_apc, "Area APC lookups should use the cached APC when available.")

	qdel(test_apc, force = TRUE)

	TEST_ASSERT_NULL(test_area.power_apc, "Destroying an APC should clear the area APC fast path.")
	test_area.power_apc = original_area_apc

/datum/unit_test/nightshift_apc_light_cache/Run()
	var/area/test_area = get_area(run_loc_floor_bottom_left)
	var/obj/machinery/power/apc/original_area_apc = test_area.power_apc
	var/obj/machinery/power/apc/test_apc = allocate(/obj/machinery/power/apc, run_loc_floor_bottom_left)
	test_apc.area = test_area
	test_apc.light_cache_dirty = FALSE
	test_apc.cached_area_lights = list()

	var/turf/light_turf = locate(run_loc_floor_bottom_left.x + 1, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/obj/machinery/light/test_light = allocate(/obj/machinery/light, light_turf)

	TEST_ASSERT(test_apc.light_cache_dirty, "Creating a light in the APC area should dirty the APC light cache.")
	test_apc.ensure_light_cache()
	TEST_ASSERT(!test_apc.light_cache_dirty, "Rebuilding the APC light cache should clear the dirty flag.")
	TEST_ASSERT(test_light in test_apc.get_cached_area_lights(), "Area light cache should include lights in the APC area.")

	test_apc.light_cache_dirty = FALSE
	qdel(test_light, force = TRUE)
	TEST_ASSERT(test_apc.light_cache_dirty, "Deleting a light in the APC area should dirty the APC light cache.")
	qdel(test_apc, force = TRUE)
	test_area.power_apc = original_area_apc

/datum/unit_test/nightshift_apc_light_cache_linked_subarea
	var/area/original_base_area
	var/area/original_linked_area
	var/area/synthetic_root
	var/area/synthetic_linked
	var/turf/base_turf
	var/turf/linked_turf
	var/obj/machinery/power/apc/test_apc

/datum/unit_test/nightshift_apc_light_cache_linked_subarea/New()
	..()
	base_turf = run_loc_floor_bottom_left
	linked_turf = run_loc_floor_top_right
	original_base_area = get_area(base_turf)
	original_linked_area = get_area(linked_turf)
	synthetic_root = new /area
	synthetic_linked = new /area
	synthetic_root.contents.Add(base_turf)
	synthetic_linked.contents.Add(linked_turf)
	synthetic_root.sub_areas = list(synthetic_linked)
	synthetic_linked.base_area = synthetic_root
	test_apc = allocate(/obj/machinery/power/apc, base_turf)
	test_apc.area = synthetic_root
	synthetic_root.power_apc = test_apc
	test_apc.light_cache_dirty = FALSE
	test_apc.cached_area_lights = list()

/datum/unit_test/nightshift_apc_light_cache_linked_subarea/Destroy()
	if(original_base_area)
		original_base_area.contents.Add(base_turf)
	if(original_linked_area)
		original_linked_area.contents.Add(linked_turf)
	if(synthetic_linked)
		synthetic_linked.base_area = null
	if(synthetic_root)
		synthetic_root.sub_areas = null
	QDEL_NULL(synthetic_linked)
	QDEL_NULL(synthetic_root)
	return ..()

/datum/unit_test/nightshift_apc_light_cache_linked_subarea/Run()
	var/obj/machinery/light/linked_light = allocate(/obj/machinery/light, linked_turf)
	TEST_ASSERT(test_apc.light_cache_dirty, "Creating a light in a linked sub-area should dirty the APC light cache.")
	test_apc.ensure_light_cache()
	TEST_ASSERT(!test_apc.light_cache_dirty, "Rebuilding the linked-area APC light cache should clear the dirty flag.")
	TEST_ASSERT(linked_light in test_apc.get_cached_area_lights(), "Area light cache should include lights in linked sub-areas.")

/datum/unit_test/nightshift_opt_out_sync/Run()
	var/area/test_area = get_area(run_loc_floor_bottom_left)
	var/obj/machinery/power/apc/original_area_apc = test_area.power_apc
	var/obj/machinery/power/apc/test_apc = allocate(/obj/machinery/power/apc, run_loc_floor_bottom_left)
	test_apc.area = test_area
	test_apc.mark_light_cache_dirty()
	test_apc.set_nightshift(TRUE, 1, FALSE)
	drain_nightshift_lighting_work()

	var/turf/light_turf = locate(run_loc_floor_bottom_left.x + 1, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/obj/machinery/light/red/test_light = allocate(/obj/machinery/light/red, light_turf)
	test_light.status = LIGHT_OK
	test_light.on = TRUE

	TEST_ASSERT(!test_light.nightshift_enabled, "Nightshift-disabled fixtures should not inherit APC nightshift on spawn.")
	TEST_ASSERT_EQUAL(test_light.nightshift_level, 0, "Nightshift-disabled fixtures should stay at zero nightshift level on spawn.")

	test_light.nightshift_enabled = TRUE
	test_light.nightshift_level = 1

	var/turf/move_turf = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	test_light.forceMove(move_turf)

	TEST_ASSERT(!test_light.nightshift_enabled, "Nightshift-disabled fixtures should clear inherited nightshift state after moving.")
	TEST_ASSERT_EQUAL(test_light.nightshift_level, 0, "Nightshift-disabled fixtures should keep a zero nightshift level after moving.")
	qdel(test_apc, force = TRUE)
	test_area.power_apc = original_area_apc

/datum/unit_test/nightshift_silent_updates_do_not_age_bulbs/Run()
	var/obj/machinery/light/test_light = allocate(/obj/machinery/light, run_loc_floor_bottom_left)
	test_light.status = LIGHT_OK
	test_light.on = TRUE
	test_light.switchcount = 7
	test_light.update(FALSE, TRUE)
	test_light.nightshift_enabled = TRUE
	test_light.nightshift_level = 0.4
	test_light.update(FALSE, TRUE)

	TEST_ASSERT_EQUAL(test_light.switchcount, 7, "Silent nightshift interpolation should not increment bulb aging.")

/datum/unit_test/nightshift_relight_resync
	var/list/original_station_areas
	var/list/original_apcs_list
	var/obj/machinery/power/apc/original_area_apc
	var/original_can_fire
	var/area/test_area
	var/turf/light_turf
	var/obj/machinery/power/apc/test_apc
	var/obj/machinery/light/test_light

/datum/unit_test/nightshift_relight_resync/New()
	..()
	original_can_fire = SSnightshift.can_fire
	SSnightshift.can_fire = FALSE
	sleep(world.tick_lag)
	SSnightshift.nightshift_refresh_running = FALSE
	test_area = get_area(run_loc_floor_bottom_left)
	light_turf = locate(run_loc_floor_bottom_left.x + 1, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	original_station_areas = GLOB.the_station_areas.Copy()
	original_apcs_list = GLOB.apcs_list.Copy()
	original_area_apc = test_area.power_apc
	GLOB.the_station_areas = list(test_area.type)
	GLOB.nightshift_apc_queue.Cut()
	GLOB.nightshift_light_queue.Cut()
	test_apc = allocate(/obj/machinery/power/apc, run_loc_floor_bottom_left)
	test_apc.area = test_area
	test_area.power_apc = test_apc
	GLOB.apcs_list = list(test_apc)
	test_apc.update()
	test_light = allocate(/obj/machinery/light, light_turf)
	test_light.status = LIGHT_OK
	test_light.on = test_light.has_power()
	test_light.switchcount = 0
	test_light.update(FALSE, TRUE)
	drain_nightshift_lighting_work()

/datum/unit_test/nightshift_relight_resync/Destroy()
	drain_nightshift_lighting_work(20)
	SSnightshift.can_fire = original_can_fire
	GLOB.the_station_areas = original_station_areas
	GLOB.apcs_list = original_apcs_list
	test_area.power_apc = original_area_apc
	if(original_area_apc && !QDELETED(original_area_apc))
		original_area_apc.area = test_area
		original_area_apc.register_area_apc()
		original_area_apc.update()
	return ..()

/datum/unit_test/nightshift_relight_resync/proc/prime_deep_night_fixture()
	test_light.status = LIGHT_OK
	test_apc.update()
	test_light.on = test_light.has_power()
	test_light.switchcount = 0
	test_light.update(FALSE, TRUE)
	test_apc.mark_light_cache_dirty()
	test_apc.set_nightshift(FALSE, 0, FALSE)
	drain_nightshift_lighting_work()
	test_apc.mark_light_cache_dirty()
	test_apc.set_nightshift(TRUE, 1, FALSE)
	drain_nightshift_lighting_work()
	assert_deep_night_emission("Setup")

/datum/unit_test/nightshift_relight_resync/proc/assert_deep_night_emission(message_prefix)
	drain_nightshift_lighting_work()
	TEST_ASSERT(test_light.nightshift_enabled, "[message_prefix] should keep the fixture in nightshift mode.")
	TEST_ASSERT_EQUAL(test_light.nightshift_level, 1, "[message_prefix] should restore the full nightshift level from the APC.")
	TEST_ASSERT_EQUAL(lowertext(test_light.light_color), lowertext("#A9BFFF"), "[message_prefix] fixture color should match the deep-night tint.")
	TEST_ASSERT_EQUAL(test_light.light_power, test_light.nightshift_light_power, "[message_prefix] fixture power should match the deep-night power.")
	assert_live_light_matches_fixture(test_light, message_prefix)
	if(test_light.light)
		TEST_ASSERT_EQUAL(lowertext(test_light.light.light_color), lowertext("#A9BFFF"), "[message_prefix] emitted light should match the deep-night tint.")
		TEST_ASSERT_EQUAL(test_light.light.light_power, test_light.nightshift_light_power, "[message_prefix] emitted light should match the deep-night power.")

/datum/unit_test/nightshift_relight_resync/Run()
	prime_deep_night_fixture()
	test_light.nightshift_enabled = FALSE
	test_light.nightshift_level = 0
	test_light.switchcount = -1
	test_light.power_loss_stage = 1
	test_light.on = FALSE
	test_light.set_light(0, l_cone_angle = 0)
	drain_nightshift_lighting_work()
	test_light.power_change()
	assert_deep_night_emission("Power restore")

	prime_deep_night_fixture()
	test_light.nightshift_enabled = FALSE
	test_light.nightshift_level = 0
	test_light.switchcount = -1
	test_light.status = LIGHT_BROKEN
	test_light.on = FALSE
	test_light.set_light(0, l_cone_angle = 0)
	drain_nightshift_lighting_work()
	test_light.fix()
	assert_deep_night_emission("Fixture repair")

	prime_deep_night_fixture()
	test_light.nightshift_enabled = FALSE
	test_light.nightshift_level = 0
	test_light.status = LIGHT_EMPTY
	test_light.on = FALSE
	test_light.update(FALSE, TRUE)
	drain_nightshift_lighting_work()
	var/mob/living/carbon/human/technician = allocate(/mob/living/carbon/human, light_turf)
	var/obj/item/light/tube/replacement_tube = allocate(/obj/item/light/tube, light_turf)
	replacement_tube.switchcount = -1
	technician.put_in_active_hand(replacement_tube, forced = TRUE)
	test_light.attackby(replacement_tube, technician)
	assert_deep_night_emission("Bulb reinsertion")

/datum/unit_test/nightshift_security
	var/list/original_station_areas
	var/list/original_apcs_list
	var/original_security_level
	var/original_nightshift_start_time
	var/original_nightshift_end_time
	var/original_high_security_mode
	var/original_nightshift_active
	var/original_last_indoor_nightshift_level
	var/original_nightshift_refresh_generation
	var/original_nightshift_refresh_running
	var/original_queued_nightshift_active
	var/original_queued_nightshift_level
	var/original_queued_nightshift_max_level
	var/original_queued_nightshift_force_clear
	var/original_gametime_offset
	var/original_round_start_time
	var/original_area_apc
	var/original_nightshift_public_area
	var/area/test_area
	var/obj/machinery/power/apc/test_apc
	var/obj/machinery/light/test_light

/datum/unit_test/nightshift_security/New()
	..()
	sleep(world.tick_lag)
	test_area = get_area(run_loc_floor_bottom_left)

	original_station_areas = GLOB.the_station_areas.Copy()
	original_apcs_list = GLOB.apcs_list.Copy()
	original_security_level = GLOB.security_level
	original_nightshift_public_area = test_area.nightshift_public_area
	original_nightshift_start_time = SSnightshift.nightshift_start_time
	original_nightshift_end_time = SSnightshift.nightshift_end_time
	original_high_security_mode = SSnightshift.high_security_mode
	original_nightshift_active = SSnightshift.nightshift_active
	original_last_indoor_nightshift_level = SSnightshift.last_indoor_nightshift_level
	original_nightshift_refresh_generation = SSnightshift.nightshift_refresh_generation
	original_nightshift_refresh_running = SSnightshift.nightshift_refresh_running
	original_queued_nightshift_active = SSnightshift.queued_nightshift_active
	original_queued_nightshift_level = SSnightshift.queued_nightshift_level
	original_queued_nightshift_max_level = SSnightshift.queued_nightshift_max_level
	original_queued_nightshift_force_clear = SSnightshift.queued_nightshift_force_clear
	original_gametime_offset = SSticker.gametime_offset
	original_round_start_time = SSticker.round_start_time
	original_area_apc = test_area.power_apc

	GLOB.the_station_areas = list(test_area.type)
	test_area.nightshift_public_area = NIGHTSHIFT_AREA_FORCED
	GLOB.nightshift_apc_queue.Cut()
	GLOB.nightshift_light_queue.Cut()

	test_apc = allocate(/obj/machinery/power/apc, run_loc_floor_bottom_left)
	test_apc.area = test_area
	GLOB.apcs_list = list(test_apc)
	test_apc.update()

	var/turf/light_turf = locate(run_loc_floor_bottom_left.x + 1, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	test_light = allocate(/obj/machinery/light, light_turf)
	test_light.status = LIGHT_OK
	test_light.on = TRUE
	test_light.nightshift_enabled = FALSE

	SSnightshift.nightshift_start_time = 0
	SSnightshift.nightshift_end_time = 0
	SSnightshift.high_security_mode = FALSE
	SSnightshift.nightshift_active = FALSE
	SSnightshift.last_indoor_nightshift_level = 0
	SSnightshift.nightshift_refresh_generation = 0
	SSnightshift.nightshift_refresh_running = FALSE
	SSnightshift.queued_nightshift_active = FALSE
	SSnightshift.queued_nightshift_level = 0
	SSnightshift.queued_nightshift_max_level = 0
	SSnightshift.queued_nightshift_force_clear = FALSE
	GLOB.security_level = SEC_LEVEL_GREEN
	SSticker.round_start_time = world.time
	SSticker.gametime_offset = 23 HOURS + 30 MINUTES

/datum/unit_test/nightshift_security/proc/ensure_test_machinery()
	if(QDELETED(test_apc) || !test_apc)
		test_apc = allocate(/obj/machinery/power/apc, run_loc_floor_bottom_left)
	test_apc.area = test_area
	GLOB.apcs_list = list(test_apc)
	test_area.power_apc = test_apc
	test_apc.update()

	if(QDELETED(test_light) || !test_light)
		var/turf/light_turf = locate(run_loc_floor_bottom_left.x + 1, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
		test_light = allocate(/obj/machinery/light, light_turf)
	test_light.status = LIGHT_OK
	test_light.on = TRUE

/datum/unit_test/nightshift_security/Destroy()
	drain_nightshift_work(20)
	GLOB.the_station_areas = original_station_areas
	GLOB.apcs_list = original_apcs_list
	GLOB.security_level = original_security_level
	SSnightshift.nightshift_start_time = original_nightshift_start_time
	SSnightshift.nightshift_end_time = original_nightshift_end_time
	SSnightshift.high_security_mode = original_high_security_mode
	SSnightshift.nightshift_active = original_nightshift_active
	SSnightshift.last_indoor_nightshift_level = original_last_indoor_nightshift_level
	SSnightshift.nightshift_refresh_generation = original_nightshift_refresh_generation
	SSnightshift.nightshift_refresh_running = original_nightshift_refresh_running
	SSnightshift.queued_nightshift_active = original_queued_nightshift_active
	SSnightshift.queued_nightshift_level = original_queued_nightshift_level
	SSnightshift.queued_nightshift_max_level = original_queued_nightshift_max_level
	SSnightshift.queued_nightshift_force_clear = original_queued_nightshift_force_clear
	SSticker.gametime_offset = original_gametime_offset
	SSticker.round_start_time = original_round_start_time
	test_area.power_apc = original_area_apc
	test_area.nightshift_public_area = original_nightshift_public_area
	return ..()

/datum/unit_test/nightshift_security/proc/reset_to_green_night()
	ensure_test_machinery()
	GLOB.security_level = SEC_LEVEL_GREEN
	SSnightshift.high_security_mode = FALSE
	test_apc.nightshift_manual_override = FALSE
	test_apc.nightshift_refresh_queued = FALSE
	test_apc.queued_nightshift_lights = FALSE
	test_apc.queued_nightshift_level = 0
	test_apc.queued_nightshift_force_clear = FALSE
	GLOB.nightshift_apc_queue.Cut()
	GLOB.nightshift_light_queue.Cut()
	test_light.nightshift_update_queued = FALSE
	test_apc.mark_light_cache_dirty()
	SSnightshift.nightshift_active = TRUE
	SSnightshift.last_indoor_nightshift_level = SSnightshift.quantize_nightshift_level(SSnightshift.compute_indoor_nightshift_level(SOLAR_TIME(FALSE, world.time)))
	var/list/automatic_state = test_apc.get_automatic_nightshift_state()
	test_apc.set_nightshift(automatic_state[1], automatic_state[2], FALSE)
	drain_nightshift_work()
	wait_for_light_state(TRUE)
	TEST_ASSERT(test_apc.nightshift_lights, "Nightshift should enable the APC lighting state during nighttime on green.")
	TEST_ASSERT(test_light.nightshift_enabled, "Nightshift should propagate to lights in the APC area.")

/datum/unit_test/nightshift_security/proc/drain_nightshift_work(max_passes = 40)
	for(var/i in 1 to max_passes)
		if(nightshift_lighting_work_pending())
			process_nightshift_lighting_work()
		if(!SSnightshift.nightshift_refresh_running && !nightshift_lighting_work_pending())
			return
		sleep(world.tick_lag)

/datum/unit_test/nightshift_security/proc/wait_for_light_state(expected_enabled)
	for(var/i in 1 to 60)
		drain_nightshift_work()
		if(test_light.nightshift_enabled == expected_enabled && test_apc.nightshift_lights == expected_enabled && !SSnightshift.nightshift_refresh_running && !length(GLOB.nightshift_apc_queue) && !length(GLOB.nightshift_light_queue))
			return
		sleep(world.tick_lag)

/datum/unit_test/nightshift_security/proc/assert_repeat_check_is_stable()
	for(var/obj/machinery/power/apc/APC in GLOB.nightshift_apc_queue)
		if(!QDELETED(APC))
			APC.nightshift_refresh_queued = FALSE
	GLOB.nightshift_apc_queue.Cut()
	for(var/obj/machinery/light/L in GLOB.nightshift_light_queue)
		if(!QDELETED(L))
			L.nightshift_update_queued = FALSE
	GLOB.nightshift_light_queue.Cut()
	SSnightshift.last_nightshift_lights_queued = 0
	SSnightshift.check_nightshift()
	drain_nightshift_work()
	TEST_ASSERT_EQUAL(SSnightshift.last_nightshift_lights_queued, 0, "Repeated nightshift checks at the same quantized level should not queue lamps again.")

/datum/unit_test/nightshift_security/proc/assert_delayed_code_turns_off_nightshift(code_name, target_level)
	wait_for_light_state(FALSE)
	TEST_ASSERT_EQUAL(GLOB.security_level, target_level, "[code_name] should set the expected security level.")
	TEST_ASSERT(SSnightshift.high_security_mode, "[code_name] should immediately refresh the nightshift emergency mode.")
	TEST_ASSERT(!SSnightshift.nightshift_active, "[code_name] should immediately disable nightshift.")
	TEST_ASSERT(!test_apc.nightshift_lights, "[code_name] should turn off nightshift on the APC immediately.")
	TEST_ASSERT(!test_light.nightshift_enabled, "[code_name] should turn off nightshift on lights immediately.")

/datum/unit_test/nightshift_security/Run()
	reset_to_green_night()
	assert_repeat_check_is_stable()

	SSsecurity_level.set_level(SEC_LEVEL_BLUE)
	wait_for_light_state(FALSE)
	TEST_ASSERT_EQUAL(GLOB.security_level, SEC_LEVEL_BLUE, "Security level should change to blue.")
	TEST_ASSERT(!SSnightshift.nightshift_active, "Blue code should disable nightshift immediately.")
	TEST_ASSERT(!test_apc.nightshift_lights, "Blue code should disable nightshift on the APC.")
	TEST_ASSERT(!test_light.nightshift_enabled, "Blue code should disable nightshift on lights.")

	SSsecurity_level.set_level(SEC_LEVEL_GREEN)
	wait_for_light_state(TRUE)
	TEST_ASSERT_EQUAL(GLOB.security_level, SEC_LEVEL_GREEN, "Security level should change back to green.")
	TEST_ASSERT(SSnightshift.nightshift_active, "Green code during nighttime should re-enable nightshift immediately.")
	TEST_ASSERT(test_apc.nightshift_lights, "Green code should re-enable nightshift on the APC.")
	TEST_ASSERT(test_light.nightshift_enabled, "Green code should re-enable nightshift on lights.")

	test_apc.set_nightshift(FALSE, 0, TRUE)
	drain_nightshift_work()
	TEST_ASSERT(!test_apc.nightshift_lights, "Manual APC nightshift toggle should be able to force nightshift off.")
	TEST_ASSERT(test_apc.nightshift_manual_override, "Manual APC nightshift toggle should mark the APC as manually overridden.")
	TEST_ASSERT(!test_light.nightshift_enabled, "Manual APC nightshift toggle should update area lights immediately.")
	SSnightshift.check_nightshift()
	drain_nightshift_work()
	TEST_ASSERT(!test_apc.nightshift_lights, "Automatic nightshift refresh should not overwrite a manual APC override.")
	TEST_ASSERT(test_apc.nightshift_manual_override, "Automatic nightshift refresh should preserve the manual override flag.")
	TEST_ASSERT(!test_light.nightshift_enabled, "Automatic nightshift refresh should not re-enable manually overridden lights.")
	test_apc.last_nightshift_switch = world.time - 101
	test_apc.toggle_nightshift_lights()
	drain_nightshift_work()
	TEST_ASSERT(!test_apc.nightshift_manual_override, "Toggling nightshift again should clear the manual APC override.")
	TEST_ASSERT(test_apc.nightshift_lights, "Clearing a manual override at night should restore the automatic nightshift state.")

	reset_to_green_night()
	lambda_process()
	assert_delayed_code_turns_off_nightshift("Lambda", SEC_LEVEL_LAMBDA)

	reset_to_green_night()
	gamma_process()
	assert_delayed_code_turns_off_nightshift("Gamma", SEC_LEVEL_GAMMA)

	reset_to_green_night()
	epsilon_process()
	assert_delayed_code_turns_off_nightshift("Epsilon", SEC_LEVEL_EPSILON)

	reset_to_green_night()
	delta_process()
	assert_delayed_code_turns_off_nightshift("Delta", SEC_LEVEL_DELTA)

/datum/unit_test/nightshift_admin_controls
	var/list/original_station_areas
	var/list/original_apcs_list
	var/original_security_level
	var/original_nightshift_active
	var/original_high_security_mode
	var/original_last_indoor_nightshift_level
	var/original_nightshift_refresh_generation
	var/original_nightshift_refresh_running
	var/original_queued_nightshift_active
	var/original_queued_nightshift_level
	var/original_queued_nightshift_max_level
	var/original_queued_nightshift_force_clear
	var/original_can_fire
	var/original_enable_night_shifts
	var/original_admin_solar_time_override
	var/original_admin_solar_time_restore_offset
	var/original_gametime_offset
	var/original_round_start_time
	var/original_area_apc
	var/original_nightshift_public_area
	var/area/test_area
	var/obj/machinery/power/apc/test_apc
	var/obj/machinery/light/test_light

/datum/unit_test/nightshift_admin_controls/New()
	..()
	sleep(world.tick_lag)
	test_area = get_area(run_loc_floor_bottom_left)

	original_station_areas = GLOB.the_station_areas.Copy()
	original_apcs_list = GLOB.apcs_list.Copy()
	original_security_level = GLOB.security_level
	original_nightshift_active = SSnightshift.nightshift_active
	original_high_security_mode = SSnightshift.high_security_mode
	original_last_indoor_nightshift_level = SSnightshift.last_indoor_nightshift_level
	original_nightshift_refresh_generation = SSnightshift.nightshift_refresh_generation
	original_nightshift_refresh_running = SSnightshift.nightshift_refresh_running
	original_queued_nightshift_active = SSnightshift.queued_nightshift_active
	original_queued_nightshift_level = SSnightshift.queued_nightshift_level
	original_queued_nightshift_max_level = SSnightshift.queued_nightshift_max_level
	original_queued_nightshift_force_clear = SSnightshift.queued_nightshift_force_clear
	original_can_fire = SSnightshift.can_fire
	original_enable_night_shifts = CONFIG_GET(flag/enable_night_shifts)
	original_admin_solar_time_override = SSnightshift.admin_solar_time_override
	original_admin_solar_time_restore_offset = SSnightshift.admin_solar_time_restore_offset
	original_gametime_offset = SSticker.gametime_offset
	original_round_start_time = SSticker.round_start_time
	original_area_apc = test_area.power_apc
	original_nightshift_public_area = test_area.nightshift_public_area

	GLOB.the_station_areas = list(test_area.type)
	test_area.nightshift_public_area = NIGHTSHIFT_AREA_FORCED
	GLOB.nightshift_apc_queue.Cut()
	GLOB.nightshift_light_queue.Cut()

	test_apc = allocate(/obj/machinery/power/apc, run_loc_floor_bottom_left)
	test_apc.area = test_area
	GLOB.apcs_list = list(test_apc)
	test_area.power_apc = test_apc
	test_apc.update()

	var/turf/light_turf = locate(run_loc_floor_bottom_left.x + 1, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	test_light = allocate(/obj/machinery/light, light_turf)
	test_light.status = LIGHT_OK
	test_light.on = TRUE
	test_light.switchcount = 0
	test_light.update(FALSE, TRUE)

	SSnightshift.nightshift_active = FALSE
	SSnightshift.high_security_mode = FALSE
	SSnightshift.last_indoor_nightshift_level = 0
	SSnightshift.nightshift_refresh_generation = 0
	SSnightshift.nightshift_refresh_running = FALSE
	SSnightshift.queued_nightshift_active = FALSE
	SSnightshift.queued_nightshift_level = 0
	SSnightshift.queued_nightshift_max_level = 0
	SSnightshift.queued_nightshift_force_clear = FALSE
	SSnightshift.admin_solar_time_override = FALSE
	SSnightshift.admin_solar_time_restore_offset = null
	SSnightshift.can_fire = TRUE
	CONFIG_SET(flag/enable_night_shifts, TRUE)
	GLOB.security_level = SEC_LEVEL_GREEN
	SSticker.round_start_time = world.time
	SSticker.gametime_offset = 21 HOURS

/datum/unit_test/nightshift_admin_controls/Destroy()
	drain_nightshift_lighting_work(20)
	GLOB.the_station_areas = original_station_areas
	GLOB.apcs_list = original_apcs_list
	GLOB.security_level = original_security_level
	SSnightshift.nightshift_active = original_nightshift_active
	SSnightshift.high_security_mode = original_high_security_mode
	SSnightshift.last_indoor_nightshift_level = original_last_indoor_nightshift_level
	SSnightshift.nightshift_refresh_generation = original_nightshift_refresh_generation
	SSnightshift.nightshift_refresh_running = original_nightshift_refresh_running
	SSnightshift.queued_nightshift_active = original_queued_nightshift_active
	SSnightshift.queued_nightshift_level = original_queued_nightshift_level
	SSnightshift.queued_nightshift_max_level = original_queued_nightshift_max_level
	SSnightshift.queued_nightshift_force_clear = original_queued_nightshift_force_clear
	SSnightshift.can_fire = original_can_fire
	CONFIG_SET(flag/enable_night_shifts, original_enable_night_shifts)
	SSnightshift.admin_solar_time_override = original_admin_solar_time_override
	SSnightshift.admin_solar_time_restore_offset = original_admin_solar_time_restore_offset
	SSticker.gametime_offset = original_gametime_offset
	SSticker.round_start_time = original_round_start_time
	test_area.power_apc = original_area_apc
	test_area.nightshift_public_area = original_nightshift_public_area
	return ..()

/datum/unit_test/nightshift_admin_controls/proc/expected_color(level)
	if(level <= 0)
		return lowertext(test_light.bulb_colour)
	return lowertext(test_light.blend_light_color(test_light.bulb_colour, test_light.nightshift_light_color, level))

/datum/unit_test/nightshift_admin_controls/proc/expected_power(level)
	if(level <= 0)
		return test_light.bulb_power
	return test_light.interpolate_light_value(test_light.bulb_power, test_light.nightshift_light_power, level)

/datum/unit_test/nightshift_admin_controls/proc/assert_fixture_state(message_prefix, expected_enabled, expected_level)
	var/expected_color_value = expected_color(expected_level)
	var/expected_power_value = expected_power(expected_level)
	TEST_ASSERT_EQUAL(test_apc.nightshift_lights, expected_enabled, "[message_prefix] APC nightshift state should match the expected mode.")
	TEST_ASSERT_EQUAL(test_light.nightshift_enabled, expected_enabled, "[message_prefix] fixture nightshift flag should match the expected mode.")
	TEST_ASSERT_EQUAL(test_light.nightshift_level, expected_level, "[message_prefix] fixture nightshift level should update immediately.")
	TEST_ASSERT_EQUAL(lowertext(test_light.light_color), expected_color_value, "[message_prefix] fixture light color should update immediately.")
	TEST_ASSERT_EQUAL(test_light.light_power, expected_power_value, "[message_prefix] fixture light power should update immediately.")
	TEST_ASSERT(test_light.light, "[message_prefix] fixture should keep a live light datum.")
	TEST_ASSERT_EQUAL(lowertext(test_light.light.light_color), expected_color_value, "[message_prefix] live emitted light color should update immediately.")
	TEST_ASSERT_EQUAL(test_light.light.light_power, expected_power_value, "[message_prefix] live emitted light power should update immediately.")
	var/list/current_overlays = test_light.update_overlays()
	TEST_ASSERT(length(current_overlays) >= 2, "[message_prefix] lit fixtures should expose visible and emissive overlays.")
	for(var/mutable_appearance/O as anything in current_overlays)
		TEST_ASSERT_EQUAL(lowertext(O.color), expected_color_value, "[message_prefix] overlays should stay in sync with the fixture color.")

/datum/unit_test/nightshift_admin_controls/Run()
	TEST_ASSERT(SSnightshift.apply_admin_mode("On"), "Global On should apply successfully.")
	TEST_ASSERT(!SSnightshift.can_fire, "Global On should pause automatic nightshift polling.")
	TEST_ASSERT(SSnightshift.nightshift_active, "Global On should activate nightshift immediately.")
	assert_fixture_state("Global On", TRUE, 1)

	TEST_ASSERT(SSnightshift.apply_admin_mode("Off"), "Global Off should apply successfully.")
	TEST_ASSERT(!SSnightshift.can_fire, "Global Off should keep automatic nightshift polling paused.")
	TEST_ASSERT(!SSnightshift.nightshift_active, "Global Off should disable nightshift immediately.")
	assert_fixture_state("Global Off", FALSE, 0)

	SSticker.gametime_offset = 21 HOURS
	var/auto_level = SSnightshift.get_automatic_nightshift_level(21 HOURS)
	TEST_ASSERT(SSnightshift.apply_admin_mode("Auto"), "Global Auto should apply successfully.")
	TEST_ASSERT(SSnightshift.can_fire, "Global Auto should resume automatic nightshift polling.")
	TEST_ASSERT(SSnightshift.nightshift_active, "Global Auto should become active during the evening profile.")
	assert_fixture_state("Global Auto", TRUE, auto_level)

	TEST_ASSERT(SSnightshift.apply_admin_solar_time_change(12 HOURS), "Solar-time override should accept a daytime anchor.")
	TEST_ASSERT(SSnightshift.admin_solar_time_override, "Setting solar time should mark the admin override as active.")
	assert_fixture_state("Solar Day", FALSE, 0)

	TEST_ASSERT(SSnightshift.apply_admin_solar_time_change(21 HOURS), "Solar-time override should accept an evening anchor.")
	assert_fixture_state("Solar Evening", TRUE, SSnightshift.get_automatic_nightshift_level(21 HOURS))

	TEST_ASSERT(SSnightshift.apply_admin_solar_time_change(23 HOURS + 30 MINUTES), "Solar-time override should accept a deep-night anchor.")
	assert_fixture_state("Solar Night", TRUE, 1)

	TEST_ASSERT(SSnightshift.apply_admin_solar_time_change(6 HOURS), "Solar-time override should accept a dawn anchor.")
	assert_fixture_state("Solar Morning", TRUE, SSnightshift.get_automatic_nightshift_level(6 HOURS))

	TEST_ASSERT(SSnightshift.apply_admin_solar_time_change(null, TRUE), "Solar-time override should clear cleanly.")
	TEST_ASSERT(!SSnightshift.admin_solar_time_override, "Clearing solar time should restore normal progression.")
	TEST_ASSERT_EQUAL(SSticker.gametime_offset, 21 HOURS, "Clearing solar time should restore the pre-override offset.")
	assert_fixture_state("Solar Clear", TRUE, auto_level)
