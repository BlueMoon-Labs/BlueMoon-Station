/datum/unit_test/nightshift_light_colors/Run()
	var/obj/machinery/light/default_light = allocate(/obj/machinery/light, run_loc_floor_bottom_left)
	default_light.status = LIGHT_OK
	default_light.on = TRUE
	default_light.nightshift_enabled = TRUE
	default_light.switchcount = 0
	default_light.update(FALSE, TRUE)

	TEST_ASSERT_EQUAL(default_light.light_color, LIGHT_COLOR_FAINT_BLUE, "Default nightshift lighting should use the cool blue tint.")

	var/turf/second_turf = locate(run_loc_floor_bottom_left.x + 1, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/obj/machinery/light/warm/warm_light = allocate(/obj/machinery/light/warm, second_turf)
	warm_light.status = LIGHT_OK
	warm_light.on = TRUE
	warm_light.nightshift_enabled = TRUE
	warm_light.switchcount = 0
	warm_light.update(FALSE, TRUE)

	TEST_ASSERT_EQUAL(warm_light.light_color, warm_light.bulb_colour, "Warm lights with a null nightshift tint should keep their own bulb colour.")

/datum/unit_test/nightshift_security
	var/list/original_station_areas
	var/original_security_level
	var/original_nightshift_start_time
	var/original_nightshift_end_time
	var/original_high_security_mode
	var/original_nightshift_active
	var/area/test_area
	var/obj/machinery/power/apc/test_apc
	var/obj/machinery/light/test_light

/datum/unit_test/nightshift_security/New()
	..()
	test_area = get_area(run_loc_floor_bottom_left)

	original_station_areas = GLOB.the_station_areas.Copy()
	original_security_level = GLOB.security_level
	original_nightshift_start_time = SSnightshift.nightshift_start_time
	original_nightshift_end_time = SSnightshift.nightshift_end_time
	original_high_security_mode = SSnightshift.high_security_mode
	original_nightshift_active = SSnightshift.nightshift_active

	GLOB.the_station_areas = list(test_area.type)

	test_apc = allocate(/obj/machinery/power/apc, run_loc_floor_bottom_left)
	test_apc.area = test_area

	var/turf/light_turf = locate(run_loc_floor_bottom_left.x + 1, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	test_light = allocate(/obj/machinery/light, light_turf)
	test_light.status = LIGHT_OK
	test_light.on = TRUE
	test_light.nightshift_enabled = FALSE

	SSnightshift.nightshift_start_time = 0
	SSnightshift.nightshift_end_time = 0
	SSnightshift.high_security_mode = FALSE
	SSnightshift.nightshift_active = FALSE
	GLOB.security_level = SEC_LEVEL_GREEN

/datum/unit_test/nightshift_security/Destroy()
	GLOB.the_station_areas = original_station_areas
	GLOB.security_level = original_security_level
	SSnightshift.nightshift_start_time = original_nightshift_start_time
	SSnightshift.nightshift_end_time = original_nightshift_end_time
	SSnightshift.high_security_mode = original_high_security_mode
	SSnightshift.nightshift_active = original_nightshift_active
	return ..()

/datum/unit_test/nightshift_security/proc/reset_to_green_night()
	GLOB.security_level = SEC_LEVEL_GREEN
	SSnightshift.high_security_mode = FALSE
	SSnightshift.update_nightshift(TRUE, FALSE)
	TEST_ASSERT(test_apc.nightshift_lights, "Nightshift should enable the APC lighting state during nighttime on green.")
	TEST_ASSERT(test_light.nightshift_enabled, "Nightshift should propagate to lights in the APC area.")

/datum/unit_test/nightshift_security/proc/assert_delayed_code_turns_off_nightshift(code_name, target_level)
	TEST_ASSERT_EQUAL(GLOB.security_level, target_level, "[code_name] should set the expected security level.")
	TEST_ASSERT(SSnightshift.high_security_mode, "[code_name] should immediately refresh the nightshift emergency mode.")
	TEST_ASSERT(!SSnightshift.nightshift_active, "[code_name] should immediately disable nightshift.")
	TEST_ASSERT(!test_apc.nightshift_lights, "[code_name] should turn off nightshift on the APC immediately.")
	TEST_ASSERT(!test_light.nightshift_enabled, "[code_name] should turn off nightshift on lights immediately.")

/datum/unit_test/nightshift_security/Run()
	reset_to_green_night()

	SSsecurity_level.set_level(SEC_LEVEL_BLUE)
	TEST_ASSERT_EQUAL(GLOB.security_level, SEC_LEVEL_BLUE, "Security level should change to blue.")
	TEST_ASSERT(!SSnightshift.nightshift_active, "Blue code should disable nightshift immediately.")
	TEST_ASSERT(!test_apc.nightshift_lights, "Blue code should disable nightshift on the APC.")
	TEST_ASSERT(!test_light.nightshift_enabled, "Blue code should disable nightshift on lights.")

	SSsecurity_level.set_level(SEC_LEVEL_GREEN)
	TEST_ASSERT_EQUAL(GLOB.security_level, SEC_LEVEL_GREEN, "Security level should change back to green.")
	TEST_ASSERT(SSnightshift.nightshift_active, "Green code during nighttime should re-enable nightshift immediately.")
	TEST_ASSERT(test_apc.nightshift_lights, "Green code should re-enable nightshift on the APC.")
	TEST_ASSERT(test_light.nightshift_enabled, "Green code should re-enable nightshift on lights.")

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
