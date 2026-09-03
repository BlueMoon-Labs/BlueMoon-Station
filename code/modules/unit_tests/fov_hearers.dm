/// Guards the premise behind the play_fov_effect optimization: on this fork the FOV
/// trait system is dead code - fov_traits is never populated anywhere, so fov_view is
/// always null and in_fov() returns TRUE for every sighted mob. play_fov_effect therefore
/// only ever shows its indicator to blind players, and gathering hearers with the
/// expensive recursive-contents get_hearers_in_view buys nothing over native hearers().
/// If this test ever fails, someone revived FOV - re-evaluate play_fov_effect (living_fov.dm).
/datum/unit_test/fov_dead_code_premise/Run()
	var/mob/living/carbon/human/observer = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	observer.update_fov()
	TEST_ASSERT_NULL(observer.fov_view, "fov_view is unexpectedly set - the FOV system came alive")
	TEST_ASSERT(observer.in_fov(target), "A sighted mob without fov_traits must always pass in_fov()")

/// The invariant the get_hearers_in_view -> hearers() swap in play_fov_effect relies on:
/// for mobs STANDING ON TURFS (not nested in containers), both gathering methods include
/// them identically. hearers() must also ignore darkness (like the luminosity hack in
/// get_hearers_in_view does), which this exercises on the dark reserved test z-level.
/datum/unit_test/fov_hearers_equivalence/Run()
	var/turf/center = run_loc_floor_bottom_left
	var/list/mobs = list()
	for(var/i in 0 to 2)
		var/turf/T = locate(center.x + i, center.y + i, center.z)
		TEST_ASSERT_NOTNULL(T, "Could not locate test turf at offset [i]")
		mobs += allocate(/mob/living/carbon/human, T)

	var/list/via_view = get_hearers_in_view(7, center)
	var/list/via_hearers = hearers(7, center)
	for(var/mob/M in mobs)
		TEST_ASSERT((M in via_view), "get_hearers_in_view missed turf-standing mob at ([M.x],[M.y])")
		TEST_ASSERT((M in via_hearers), "hearers() missed turf-standing mob at ([M.x],[M.y])")

	// Smoke-test the production path with no clients around (must not runtime)
	play_fov_effect(mobs[1], 7, "fov_sound")

	// Nullspace center must be a quiet no-op
	var/mob/living/carbon/human/floating = allocate(/mob/living/carbon/human)
	floating.moveToNullspace()
	play_fov_effect(floating, 7, "fov_sound")

/// Compares hearer-gathering costs and logs timings.
/// No assertions on timing, output is for before/after comparison in test logs.
/datum/unit_test/fov_hearers_bench
	priority = TEST_LONGER

/datum/unit_test/fov_hearers_bench/Run()
	var/turf/center = run_loc_floor_bottom_left
	for(var/i in 0 to 2)
		allocate(/mob/living/carbon/human, locate(center.x + i, center.y + i, center.z))

	var/iterations = 5000
	var/start = REALTIMEOFDAY
	for(var/i in 1 to iterations)
		get_hearers_in_view(7, center)
	var/view_ds = REALTIMEOFDAY - start

	var/list/bench_hearers_sink = null
	start = REALTIMEOFDAY
	for(var/i in 1 to iterations)
		bench_hearers_sink = hearers(7, center)
	var/hearers_ds = REALTIMEOFDAY - start
	TEST_ASSERT_NOTNULL(bench_hearers_sink, "hearers() unexpectedly returned null during benchmark")

	log_world("PERF: hearer gathering x[iterations]: get_hearers_in_view [view_ds * 100]ms vs native hearers [hearers_ds * 100]ms")
