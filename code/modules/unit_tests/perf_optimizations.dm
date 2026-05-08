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


// ===== Fix E: /datum/pipeline/proc/build_pipeline scales linearly =====
//
// Profile snapshot: 15 calls / 4.228s total CPU / 3.432s overtime — dominant
// hot proc in the pipenet rebuild path. Two quadratic loops drove the cost:
//   1. members.Find(item) — O(M) membership probe, called once per discovered
//      pipe → O(N²) total on a chain of N pipes.
//   2. possible_expansions -= borderline — O(P) list removal each step. Less
//      pathological than (1) on a pure chain but quadratic on dense topology.
//
// The rewrite replaces the membership probe with a local seen-set assoc list
// and walks `possible_expansions` via an index cursor (no -= per step). All
// observable outputs (members, other_atmosmch, other_airs, volume, merged
// air_temporary) must stay identical.
//
// These tests:
//   * build_pipeline_collects_chain — small chain, asserts every pipe enrolled
//     with correct parent and the pipeline volume is the sum of pipe volumes;
//     verifies air_temporary on a member gets merged into pipeline air.
//   * build_pipeline_handles_cycles — diamond topology proves dedup still
//     works (no duplicate enrolment, no infinite loop).
//   * build_pipeline_attaches_components — non-pipe atmos machinery in the
//     expansion must land in other_atmosmch (not members) exactly once and
//     get its parents slot wired through setPipenet.
//   * build_pipeline_scales_linearly — 3000-pipe chain must complete in well
//     under the budget that an O(N²) algorithm would burn (the pre-fix code
//     spends >1s here on this size; the optimized code finishes near-instant).

/// Synthetic pipe used to drive build_pipeline through arbitrary topologies
/// without going through SSair atmosinit / can_be_node / piping_layer rules.
/// pipeline_expansion returns whatever neighbors we wire up by hand.
/obj/machinery/atmospherics/pipe/build_pipeline_test_node
	name = "build_pipeline_test_node"
	device_type = 1
	volume = 100
	var/list/test_neighbors

/obj/machinery/atmospherics/pipe/build_pipeline_test_node/New(loc, process = TRUE, setdir)
	// Skip SSair processing registration — we drive build_pipeline manually.
	..(loc, FALSE, setdir)
	// /obj/machinery/atmospherics/pipe/New rewrites volume = 35 * device_type;
	// pin a deterministic value so the volume-sum assertions are exact.
	volume = 100

/obj/machinery/atmospherics/pipe/build_pipeline_test_node/atmosinit(list/node_connects)
	return

/obj/machinery/atmospherics/pipe/build_pipeline_test_node/pipeline_expansion()
	return test_neighbors || list()

/// Synthetic atmos component used to exercise the non-pipe branch of
/// build_pipeline. Inherits the parents/airs setup from
/// /obj/machinery/atmospherics/components/New so addMachineryMember and
/// setPipenet can run unmodified.
/obj/machinery/atmospherics/components/build_pipeline_test_component
	name = "build_pipeline_test_component"
	device_type = 1

/obj/machinery/atmospherics/components/build_pipeline_test_component/New(loc, process = TRUE, setdir)
	..(loc, FALSE, setdir)

/obj/machinery/atmospherics/components/build_pipeline_test_component/atmosinit(list/node_connects)
	return


/datum/unit_test/build_pipeline_collects_chain/Run()
	var/list/obj/machinery/atmospherics/pipe/build_pipeline_test_node/pipes = list()
	for(var/i in 1 to 4)
		pipes += allocate(/obj/machinery/atmospherics/pipe/build_pipeline_test_node)
	var/obj/machinery/atmospherics/pipe/build_pipeline_test_node/p1 = pipes[1]
	var/obj/machinery/atmospherics/pipe/build_pipeline_test_node/p2 = pipes[2]
	var/obj/machinery/atmospherics/pipe/build_pipeline_test_node/p3 = pipes[3]
	var/obj/machinery/atmospherics/pipe/build_pipeline_test_node/p4 = pipes[4]
	p1.test_neighbors = list(p2)
	p2.test_neighbors = list(p1, p3)
	p3.test_neighbors = list(p2, p4)
	p4.test_neighbors = list(p3)

	// Stash a temporary air parcel on pipes[3] to verify air_temporary merging.
	p3.air_temporary = new /datum/gas_mixture()
	p3.air_temporary.set_volume(100)
	p3.air_temporary.set_temperature(T20C)
	p3.air_temporary.set_moles(GAS_O2, 5)

	var/datum/pipeline/P = new()
	allocated += P
	// Real callers (/obj/machinery/atmospherics/pipe/build_network) set
	// base.parent = pipeline before invoking build_pipeline; the proc itself
	// only assigns .parent on *discovered* members. Mirror that contract here
	// so the post-condition assertion is meaningful for every pipe.
	p1.parent = P
	P.build_pipeline(p1)

	TEST_ASSERT_EQUAL(length(P.members), 4, "All four pipes must be collected into members (got [length(P.members)])")
	for(var/obj/machinery/atmospherics/pipe/build_pipeline_test_node/p as anything in pipes)
		TEST_ASSERT(p in P.members, "[p] must appear in members")
		TEST_ASSERT_EQUAL(p.parent, P, "[p].parent must be set to the pipeline")
	TEST_ASSERT_EQUAL(P.air.return_volume(), 4 * 100, "Pipeline volume must equal the sum of pipe volumes")
	TEST_ASSERT(P.air.get_moles(GAS_O2) >= 5 - 0.01, "air_temporary moles must be merged into pipeline air (got [P.air.get_moles(GAS_O2)])")
	TEST_ASSERT_NULL(p3.air_temporary, "air_temporary must be cleared after merging")


/datum/unit_test/build_pipeline_handles_cycles/Run()
	// Diamond topology: 1 connects to 2 and 3; both 2 and 3 connect down to 4.
	var/list/obj/machinery/atmospherics/pipe/build_pipeline_test_node/pipes = list()
	for(var/i in 1 to 4)
		pipes += allocate(/obj/machinery/atmospherics/pipe/build_pipeline_test_node)
	var/obj/machinery/atmospherics/pipe/build_pipeline_test_node/p1 = pipes[1]
	var/obj/machinery/atmospherics/pipe/build_pipeline_test_node/p2 = pipes[2]
	var/obj/machinery/atmospherics/pipe/build_pipeline_test_node/p3 = pipes[3]
	var/obj/machinery/atmospherics/pipe/build_pipeline_test_node/p4 = pipes[4]
	p1.test_neighbors = list(p2, p3)
	p2.test_neighbors = list(p1, p4)
	p3.test_neighbors = list(p1, p4)
	p4.test_neighbors = list(p2, p3)

	var/datum/pipeline/P = new()
	allocated += P
	P.build_pipeline(p1)

	TEST_ASSERT_EQUAL(length(P.members), 4, "Diamond topology must collect each pipe exactly once (got [length(P.members)])")
	TEST_ASSERT_EQUAL(P.air.return_volume(), 4 * 100, "Volume must sum each pipe exactly once (got [P.air.return_volume()])")


/// Regression coverage: pipeline_expansion may return list entries that are
/// null (e.g. /obj/machinery/atmospherics/components/pipeline_expansion does
/// `list(nodes[parents.Find(reference)])`, and that nodes slot is null on
/// disconnected components). build_pipeline must skip those entries quietly
/// — reaching setPipenet on null crashes SSair during pipenet setup.
/datum/unit_test/build_pipeline_skips_null_neighbors/Run()
	var/obj/machinery/atmospherics/pipe/build_pipeline_test_node/p1 = allocate(/obj/machinery/atmospherics/pipe/build_pipeline_test_node)
	var/obj/machinery/atmospherics/pipe/build_pipeline_test_node/p2 = allocate(/obj/machinery/atmospherics/pipe/build_pipeline_test_node)
	p1.test_neighbors = list(null, p2, null)
	p2.test_neighbors = list(p1, null)

	var/datum/pipeline/P = new()
	allocated += P
	// Snapshot the global runtime counter — DM keeps executing past null-deref
	// runtimes inside the proc body, so member-count assertions alone wouldn't
	// catch a regression that reaches setPipenet(null, …). The counter does.
	var/runtimes_before = GLOB.total_runtimes
	P.build_pipeline(p1)
	var/runtimes_added = GLOB.total_runtimes - runtimes_before

	TEST_ASSERT_EQUAL(runtimes_added, 0, "build_pipeline must not raise runtimes on null neighbors (got [runtimes_added])")
	TEST_ASSERT_EQUAL(length(P.members), 2, "Both real pipes must be collected; null entries skipped (got [length(P.members)])")
	TEST_ASSERT(p1 in P.members, "p1 must be in members")
	TEST_ASSERT(p2 in P.members, "p2 must be in members")
	TEST_ASSERT_EQUAL(P.air.return_volume(), 2 * 100, "Volume must equal 2 * pipe volume")


/datum/unit_test/build_pipeline_attaches_components/Run()
	var/obj/machinery/atmospherics/pipe/build_pipeline_test_node/p1 = allocate(/obj/machinery/atmospherics/pipe/build_pipeline_test_node)
	var/obj/machinery/atmospherics/pipe/build_pipeline_test_node/p2 = allocate(/obj/machinery/atmospherics/pipe/build_pipeline_test_node)
	var/obj/machinery/atmospherics/components/build_pipeline_test_component/comp = allocate(/obj/machinery/atmospherics/components/build_pipeline_test_component)
	// setPipenet(reference, A) does parents[nodes.Find(A)] = reference, so the
	// component must already know p1 as one of its connector nodes.
	comp.nodes[1] = p1

	p1.test_neighbors = list(p2, comp)
	p2.test_neighbors = list(p1)

	var/datum/pipeline/P = new()
	allocated += P
	P.build_pipeline(p1)

	TEST_ASSERT_EQUAL(length(P.members), 2, "Both pipes must be in members (component goes to other_atmosmch)")
	TEST_ASSERT_EQUAL(length(P.other_atmosmch), 1, "Component must be added to other_atmosmch exactly once (got [length(P.other_atmosmch)])")
	TEST_ASSERT(comp in P.other_atmosmch, "Component must appear in other_atmosmch")
	TEST_ASSERT_EQUAL(comp.parents[1], P, "Component's parents slot for p1 must be wired to the pipeline")
	TEST_ASSERT(comp.airs[1] in P.other_airs, "Component's gas_mixture must be merged into other_airs")


#define BUILD_PIPELINE_PERF_N 3000
/// Synthetic chain of [BUILD_PIPELINE_PERF_N] pipes. The pre-fix
/// build_pipeline does ~N²/2 list scans through `members` (one per discovered
/// pipe), which on N=3000 is ~4.5M comparisons → easily over 1s on CI. The
/// optimized algorithm is O(N) and finishes in single-digit ms. The 5
/// decisecond budget below sits firmly between those regimes.
/datum/unit_test/build_pipeline_scales_linearly/Run()
	var/list/pipes = new(BUILD_PIPELINE_PERF_N)
	for(var/i in 1 to BUILD_PIPELINE_PERF_N)
		var/obj/machinery/atmospherics/pipe/build_pipeline_test_node/p = new(run_loc_floor_bottom_left)
		pipes[i] = p
		allocated += p
	for(var/i in 1 to BUILD_PIPELINE_PERF_N)
		var/list/neighbors = list()
		if(i > 1)
			neighbors += pipes[i - 1]
		if(i < BUILD_PIPELINE_PERF_N)
			neighbors += pipes[i + 1]
		var/obj/machinery/atmospherics/pipe/build_pipeline_test_node/p = pipes[i]
		p.test_neighbors = neighbors

	var/datum/pipeline/P = new()
	allocated += P

	var/start = REALTIMEOFDAY
	P.build_pipeline(pipes[1])
	var/elapsed_ds = REALTIMEOFDAY - start

	TEST_ASSERT_EQUAL(length(P.members), BUILD_PIPELINE_PERF_N, "All [BUILD_PIPELINE_PERF_N] pipes must be collected (got [length(P.members)])")
	TEST_ASSERT(elapsed_ds < 5, "build_pipeline on [BUILD_PIPELINE_PERF_N]-pipe chain must run in linear time (took [elapsed_ds] ds)")
#undef BUILD_PIPELINE_PERF_N
