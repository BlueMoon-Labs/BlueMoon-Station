/datum/weather/unit_test_budget_probe
	var/affected_mobs = 0

/datum/weather/unit_test_budget_probe/can_weather_act(mob/living/mob_to_check)
	return !QDELETED(mob_to_check)

/datum/weather/unit_test_budget_probe/weather_act(mob/living/living_mob)
	affected_mobs++

/// An active storm must give the MC a resume boundary between victims. A
/// single weather datum used to hide its entire GLOB.mob_living_list walk
/// behind one generic-processing call.
/datum/unit_test/weather_population_scan_resumes/Run()
	var/list/saved_living_mobs = GLOB.mob_living_list
	var/list/saved_processing = SSweather.processing
	var/list/saved_currentrun = SSweather.currentrun
	var/datum/weather/saved_current_weather = SSweather.current_weather
	var/list/saved_current_weather_mobs = SSweather.current_weather_mobs
	var/list/saved_eligible_zlevels = SSweather.eligible_zlevels
	var/saved_state = SSweather.state
	var/saved_ticklimit = Master.current_ticklimit
	var/saved_profile_strikes = SSweather.profile_strikes
	var/saved_profile_armed = SSweather.profile_armed
	var/saved_profile_cooldown_until = SSweather.profile_cooldown_until
	var/saved_current_pass_cost_ms = SSweather.current_pass_cost_ms
	var/list/saved_profile_cost_by_type = SSweather.profile_cost_by_type
	var/list/saved_profile_count_by_type = SSweather.profile_count_by_type
	var/list/saved_profile_max_by_type = SSweather.profile_max_by_type

	var/mob/living/simple_animal/probe_mob = allocate(/mob/living/simple_animal, run_loc_floor_bottom_left)
	var/datum/weather/unit_test_budget_probe/probe_weather = new(list(run_loc_floor_bottom_left.z))
	probe_weather.stage = MAIN_STAGE
	var/list/stress_population = list()
	for(var/i in 1 to 1000)
		stress_population += probe_mob

	GLOB.mob_living_list = stress_population
	SSweather.processing = list(probe_weather)
	SSweather.currentrun = list()
	SSweather.current_weather = null
	SSweather.current_weather_mobs = list()
	SSweather.eligible_zlevels = list()
	SSweather.state = SS_RUNNING
	SSweather.profile_strikes = 0
	SSweather.profile_armed = FALSE
	SSweather.current_pass_cost_ms = 0
	SSweather.profile_cost_by_type = null
	SSweather.profile_count_by_type = null
	SSweather.profile_max_by_type = null
	Master.current_ticklimit = 0
	SSweather.fire(FALSE)

	TEST_ASSERT(probe_weather.affected_mobs > 0, "Weather must begin processing the population before yielding")
	TEST_ASSERT(probe_weather.affected_mobs < length(stress_population), "Weather must yield before one datum consumes the whole over-budget population")
	TEST_ASSERT_NOTNULL(SSweather.current_weather, "A yielded weather scan must retain its active datum")
	TEST_ASSERT(length(SSweather.current_weather_mobs), "A yielded weather scan must retain its remaining population")

	SSweather.state = SS_RUNNING
	Master.current_ticklimit = INFINITY
	SSweather.fire(TRUE)
	TEST_ASSERT_EQUAL(probe_weather.affected_mobs, length(stress_population), "A resumed weather scan must affect every snapshotted mob exactly once")
	TEST_ASSERT_NULL(SSweather.current_weather, "A completed weather scan must release its active datum")
	TEST_ASSERT(!length(SSweather.current_weather_mobs), "A completed weather scan must release its population snapshot")

	GLOB.mob_living_list = saved_living_mobs
	SSweather.processing = saved_processing
	SSweather.currentrun = saved_currentrun
	SSweather.current_weather = saved_current_weather
	SSweather.current_weather_mobs = saved_current_weather_mobs
	SSweather.eligible_zlevels = saved_eligible_zlevels
	SSweather.state = saved_state
	SSweather.profile_strikes = saved_profile_strikes
	SSweather.profile_armed = saved_profile_armed
	SSweather.profile_cooldown_until = saved_profile_cooldown_until
	SSweather.current_pass_cost_ms = saved_current_pass_cost_ms
	SSweather.profile_cost_by_type = saved_profile_cost_by_type
	SSweather.profile_count_by_type = saved_profile_count_by_type
	SSweather.profile_max_by_type = saved_profile_max_by_type
	Master.current_ticklimit = saved_ticklimit
	qdel(probe_weather)
