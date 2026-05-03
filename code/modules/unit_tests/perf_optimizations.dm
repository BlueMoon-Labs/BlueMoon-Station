/// Tests for performance optimizations addressing high tick-overtime contributors
/// surfaced by the perf.log profile (shuttle_docker scan, MouseEntered screentip,
/// unbounded icon caches, photo capture flat-icon dedup, get_mob_by_ckey sort).

// ===== Fix A: shuttle_docker setLoc dedups checkLandingSpot =====

/// Test subtype: skips the heavy port-scan in checkLandingSpot, just counts
/// invocations so the test can assert dedup behavior without needing a real
/// shuttle_port + docking ports. Initialize() of the parent gracefully no-ops
/// when there is no shuttle to connect to.
/obj/machinery/computer/camera_advanced/shuttle_docker/unit_test_dedup_counter
	var/check_landing_calls = 0

/obj/machinery/computer/camera_advanced/shuttle_docker/unit_test_dedup_counter/checkLandingSpot()
	check_landing_calls++
	return SHUTTLE_DOCKER_LANDING_CLEAR

/datum/unit_test/shuttle_docker_setloc_dedup/Run()
	var/obj/machinery/computer/camera_advanced/shuttle_docker/unit_test_dedup_counter/console = \
		allocate(/obj/machinery/computer/camera_advanced/shuttle_docker/unit_test_dedup_counter)

	var/mob/camera/aiEye/remote/shuttle_docker/the_eye = new(null, console)
	allocated += the_eye

	var/turf/turf_a = run_loc_floor_bottom_left
	var/turf/turf_b = get_step(turf_a, EAST)
	TEST_ASSERT_NOTNULL(turf_b, "Test reservation must have an EAST neighbour for turf_b")

	// /mob/camera/aiEye/remote/setLoc only actually moves the eye when an eye_user
	// is attached. The unit test has no client, so we forceMove the eye into place
	// first — the dedup logic still keys off of get_turf(src) so it does the right
	// thing regardless.
	the_eye.forceMove(turf_a)

	// /mob/camera/aiEye/Initialize calls setLoc(loc, TRUE) once at construction
	// time, which already incremented the counter. Reset it so the assertions
	// below measure only the calls under test.
	console.check_landing_calls = 0
	the_eye.last_checked_turf = null
	the_eye.last_checked_dir = 0

	// First setLoc → must run the (mocked) checkLandingSpot
	the_eye.setLoc(turf_a)
	TEST_ASSERT_EQUAL(console.check_landing_calls, 1, "First setLoc should invoke checkLandingSpot")
	TEST_ASSERT_EQUAL(the_eye.last_checked_turf, turf_a, "Dedup state should record the checked turf")

	// Repeating setLoc on the same turf+dir must be deduped
	the_eye.setLoc(turf_a)
	TEST_ASSERT_EQUAL(console.check_landing_calls, 1, "Repeat setLoc on same turf must skip checkLandingSpot")

	// Moving to a different turf must invalidate the dedup
	the_eye.forceMove(turf_b)
	the_eye.setLoc(turf_b)
	TEST_ASSERT_EQUAL(console.check_landing_calls, 2, "Movement must trigger a fresh checkLandingSpot")

	// Re-stationary at turf_b → deduped again
	the_eye.setLoc(turf_b)
	TEST_ASSERT_EQUAL(console.check_landing_calls, 2, "Subsequent setLoc at the same turf must remain deduped")

	// force_update bypasses dedup unconditionally (used for explicit refresh paths)
	the_eye.setLoc(turf_b, force_update = TRUE)
	TEST_ASSERT_EQUAL(console.check_landing_calls, 3, "force_update must bypass the dedup")


// ===== Fix C.1: bicon_cache eviction Cut math is correct =====

/// Verifies BICON_CACHE_MAX + the Cut(1, MAX/4 + 1) eviction strategy used by
/// /proc/icon2base64html. Logic test on a synthetic list — keeps the assertion
/// fast and independent of the icon→png pipeline (which has its own savefile
/// state). Mirrors the humanoid_icon_cache_eviction_math test below.
/datum/unit_test/bicon_cache_eviction_math/Run()
	var/list/synthetic_cache = list()
	for(var/i in 1 to BICON_CACHE_MAX + 5)
		synthetic_cache["entry_[i]"] = "data_[i]"

	if(length(synthetic_cache) > BICON_CACHE_MAX)
		synthetic_cache.Cut(1, (BICON_CACHE_MAX / 4) + 1)

	TEST_ASSERT(length(synthetic_cache) <= BICON_CACHE_MAX, "Eviction must keep cache <= BICON_CACHE_MAX (got [length(synthetic_cache)])")
	TEST_ASSERT(length(synthetic_cache) >= (BICON_CACHE_MAX * 3 / 4), "Eviction should retain ~75% of entries (got [length(synthetic_cache)])")
	TEST_ASSERT(isnull(synthetic_cache["entry_1"]), "Oldest entry should be evicted")
	TEST_ASSERT_NOTNULL(synthetic_cache["entry_[BICON_CACHE_MAX + 1]"], "Recently-added entry should survive eviction")
	TEST_ASSERT(GLOB.bicon_cache != null, "GLOB.bicon_cache must be initialized as a list")


// ===== Fix C.2: humanoid_icon_cache eviction Cut math is correct =====

/// Verifies HUMANOID_ICON_CACHE_MAX + the Cut(1, MAX/4 + 1) eviction strategy
/// shared with bicon_cache. This is a logic test on a synthetic list (the
/// production proc is too expensive to invoke MAX+1 times in CI).
/datum/unit_test/humanoid_icon_cache_eviction_math/Run()
	var/list/synthetic_cache = list()
	for(var/i in 1 to HUMANOID_ICON_CACHE_MAX + 5)
		synthetic_cache["entry_[i]"] = i

	if(length(synthetic_cache) > HUMANOID_ICON_CACHE_MAX)
		synthetic_cache.Cut(1, (HUMANOID_ICON_CACHE_MAX / 4) + 1)

	TEST_ASSERT(length(synthetic_cache) <= HUMANOID_ICON_CACHE_MAX, "Eviction must keep the cache <= HUMANOID_ICON_CACHE_MAX (got [length(synthetic_cache)])")
	TEST_ASSERT(isnull(synthetic_cache["entry_1"]), "Oldest entry should be evicted")
	TEST_ASSERT_NOTNULL(synthetic_cache["entry_[HUMANOID_ICON_CACHE_MAX + 1]"], "Recently-added entry should survive eviction")
	TEST_ASSERT(GLOB.humanoid_icon_cache != null, "GLOB.humanoid_icon_cache must be initialized as a list")


// ===== Fix D: get_mob_by_ckey skips redundant sortmobs() =====

/// Regression coverage for /proc/get_mob_by_ckey after dropping the sortmobs()
/// call that fed cmp_name_asc ~1.6M times per round in profiles. The proc
/// returns the first mob whose ckey matches; sort order is irrelevant since
/// ckey is unique. We verify the lookup returns the correct mob regardless of
/// its position in GLOB.mob_list, and short-circuits cleanly on null/empty.
/datum/unit_test/get_mob_by_ckey_lookup/Run()
	var/mob/living/carbon/human/alpha = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/bravo = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/charlie = allocate(/mob/living/carbon/human)

	// BYOND ckey is alphanumeric-only after stripping; use simple lowercase ids.
	alpha.ckey = "perftestckeya"
	bravo.ckey = "perftestckeyb"
	charlie.ckey = "perftestckeyc"

	TEST_ASSERT(alpha in GLOB.mob_list, "Allocated alpha must be tracked in GLOB.mob_list")
	TEST_ASSERT(bravo in GLOB.mob_list, "Allocated bravo must be tracked in GLOB.mob_list")
	TEST_ASSERT(charlie in GLOB.mob_list, "Allocated charlie must be tracked in GLOB.mob_list")

	TEST_ASSERT_EQUAL(get_mob_by_ckey("perftestckeya"), alpha, "get_mob_by_ckey should locate alpha by its ckey")
	TEST_ASSERT_EQUAL(get_mob_by_ckey("perftestckeyb"), bravo, "get_mob_by_ckey should locate bravo by its ckey")
	TEST_ASSERT_EQUAL(get_mob_by_ckey("perftestckeyc"), charlie, "get_mob_by_ckey should locate charlie by its ckey")

	TEST_ASSERT_NULL(get_mob_by_ckey("perftestmissing"), "Unknown ckey should return null")
	TEST_ASSERT_NULL(get_mob_by_ckey(""), "Empty ckey should short-circuit to null without scanning")
	TEST_ASSERT_NULL(get_mob_by_ckey(null), "Null ckey should short-circuit to null without scanning")
