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


/// Regression coverage for the reported pipeline teardown runtimes
/// ("Cannot modify null.parent" in Destroy, "Cannot modify null.air_temporary"
/// in temporarily_store_air). BYOND leaves a null slot in a list when a
/// referenced object is hard-deleted, so a member pipe deleted elsewhere leaves
/// `members` holding a null. The teardown loops must skip those quietly; an
/// `as anything` iteration dereferences the null and crashes. The runtime
/// counter catches it because DM keeps executing past a null-deref runtime.
/datum/unit_test/pipeline_teardown_skips_null_members/Run()
	var/obj/machinery/atmospherics/pipe/build_pipeline_test_node/p1 = allocate(/obj/machinery/atmospherics/pipe/build_pipeline_test_node)

	var/datum/pipeline/P = new()
	allocated += P // double-qdel is safe; this just guarantees cleanup on early assert failure
	P.members += p1
	P.members += null // simulate a member pipe hard-deleted elsewhere
	p1.parent = P
	// air must have volume so Destroy takes the temporarily_store_air() branch.
	P.air = new /datum/gas_mixture()
	P.air.set_volume(100)
	P.air.set_temperature(T20C)

	var/runtimes_before = GLOB.total_runtimes
	P.temporarily_store_air()
	qdel(P) // Destroy() iterates members again ("P.parent = null")
	var/runtimes_added = GLOB.total_runtimes - runtimes_before

	TEST_ASSERT_EQUAL(runtimes_added, 0, "pipeline teardown must not raise runtimes on a null member (got [runtimes_added])")
	TEST_ASSERT_NOTNULL(p1.air_temporary, "the real member must still get its air_temporary parcel")


/// merge() walks the absorbed pipeline's members/other_atmosmch to re-parent
/// them. If that pipeline holds a stale null (same hard-delete cause as above),
/// the re-parent loop must skip it rather than deref null.parent / null methods.
/datum/unit_test/pipeline_merge_skips_null_members/Run()
	var/obj/machinery/atmospherics/pipe/build_pipeline_test_node/p1 = allocate(/obj/machinery/atmospherics/pipe/build_pipeline_test_node)
	var/obj/machinery/atmospherics/pipe/build_pipeline_test_node/p2 = allocate(/obj/machinery/atmospherics/pipe/build_pipeline_test_node)

	var/datum/pipeline/keeper = new()
	allocated += keeper
	keeper.air = new /datum/gas_mixture()
	keeper.air.set_volume(100)
	keeper.members += p1
	p1.parent = keeper

	var/datum/pipeline/absorbed = new()
	absorbed.air = new /datum/gas_mixture()
	absorbed.air.set_volume(100)
	absorbed.members += p2
	absorbed.members += null // stale null in the pipeline being merged in
	p2.parent = absorbed

	var/runtimes_before = GLOB.total_runtimes
	keeper.merge(absorbed) // merge() qdels absorbed for us
	var/runtimes_added = GLOB.total_runtimes - runtimes_before

	TEST_ASSERT_EQUAL(runtimes_added, 0, "merge() must not raise runtimes on a null member (got [runtimes_added])")
	TEST_ASSERT_EQUAL(p2.parent, keeper, "the real absorbed member must be re-parented to the keeper")


// ===== Fix F: getFlatIcon directional-check + icon_states memoisation =====
//
// Profile snapshot: /proc/getFlatIcon — 2005 calls / 10.5s total CPU / 3.9s overtime,
// a top tick-overtime contributor. Two pure-but-uncached lookups ran on *every* call:
//   1. icon_states(curicon)                        — rebuilds the state list each time
//   2. a 3-way directional probe that constructed three throwaway /icon objects plus
//      three icon_states() calls just to pick base_icon_dir (the proc itself flagged
//      this block as a "CPU hog").
// Both depend only on immutable DMI data, so they are now memoised behind
// /proc/cached_icon_states and /proc/icon_state_has_directional_frames.
//
// Tests:
//   * flat_icon_state_caches — cached_icon_states / icon_state_has_directional_frames
//     return results consistent with the raw built-ins, memoise icon *files*, and
//     decline to cache unstable runtime /icon datums.
//   * flat_icon_smoke — getFlatIcon still yields a valid icon in every cardinal dir
//     (exercising the cached directional path), both cold and warm.

/datum/unit_test/flat_icon_state_caches/Run()
	var/test_icon = 'icons/effects/effects.dmi'
	var/test_icon_key = "[test_icon]"

	// cached_icon_states must mirror icon_states()...
	var/list/raw_states = icon_states(test_icon)
	TEST_ASSERT(length(raw_states) > 0, "test fixture icon must expose at least one icon_state")
	var/list/cached_first = cached_icon_states(test_icon)
	TEST_ASSERT_EQUAL(length(cached_first), length(raw_states), "cached_icon_states returned a different number of states than icon_states")
	for(var/state in raw_states)
		TEST_ASSERT(state in cached_first, "cached_icon_states is missing state '[state]'")

	// ...and a repeat call must hand back the exact same (memoised) list.
	var/list/cached_second = cached_icon_states(test_icon)
	TEST_ASSERT(cached_first == cached_second, "cached_icon_states must return the memoised list on repeat calls")
	TEST_ASSERT(GLOB.cached_icon_states_by_file["[test_icon_key]|0"] == cached_first, "GLOB.cached_icon_states_by_file must hold the returned list")

	// Runtime /icon datums have unstable refs — must not be cached, but must still work.
	var/icon/runtime_icon = icon(test_icon)
	var/list/runtime_states = cached_icon_states(runtime_icon)
	TEST_ASSERT_NOTNULL(runtime_states, "cached_icon_states must still resolve states for a runtime /icon datum")

	// icon_state_has_directional_frames must agree with a direct N/E/W probe for every state...
	for(var/state in raw_states)
		var/expected_directional = FALSE
		for(var/checkdir in list(NORTH, EAST, WEST))
			if(length(icon_states(icon(test_icon, state, checkdir))))
				expected_directional = TRUE
				break
		TEST_ASSERT_EQUAL(icon_state_has_directional_frames(test_icon, state), expected_directional, "icon_state_has_directional_frames disagreed with a direct probe for state '[state]'")
		// ...the cached second call must agree with the first and populate the cache.
		TEST_ASSERT_EQUAL(icon_state_has_directional_frames(test_icon, state), expected_directional, "cached directional result changed on the second call for state '[state]'")
		TEST_ASSERT("[test_icon_key]|[state]" in GLOB.cached_icon_state_directional, "directional cache entry missing for state '[state]'")

	// Runtime /icon datums: uncached, but consistent with a direct probe.
	var/runtime_state = raw_states[1]
	var/runtime_expected = FALSE
	for(var/checkdir in list(NORTH, EAST, WEST))
		if(length(icon_states(icon(runtime_icon, runtime_state, checkdir))))
			runtime_expected = TRUE
			break
	TEST_ASSERT_EQUAL(icon_state_has_directional_frames(runtime_icon, runtime_state), runtime_expected, "icon_state_has_directional_frames must stay correct for runtime /icon datums")


/datum/unit_test/flat_icon_smoke/Run()
	var/mob/living/carbon/human/dummy = allocate(/mob/living/carbon/human)

	for(var/test_dir in list(SOUTH, NORTH, EAST, WEST))
		dummy.setDir(test_dir)
		var/icon/flat = getFlatIcon(dummy, no_anim = TRUE)
		TEST_ASSERT_NOTNULL(flat, "getFlatIcon must return an icon for a human facing [dir2text(test_dir)]")
		TEST_ASSERT(flat.Width() > 0 && flat.Height() > 0, "getFlatIcon result must have positive dimensions facing [dir2text(test_dir)] (got [flat.Width()]x[flat.Height()])")

	// Caches are warm now — a repeat call must still produce a valid icon.
	dummy.setDir(WEST)
	var/icon/warm = getFlatIcon(dummy, no_anim = TRUE)
	TEST_ASSERT_NOTNULL(warm, "getFlatIcon must still return an icon once the directional/state caches are warm")
	TEST_ASSERT(warm.Width() > 0 && warm.Height() > 0, "warm-cache getFlatIcon result must have positive dimensions (got [warm.Width()]x[warm.Height()])")


// ===== Fix G: icon2html result cache =====
//
// Profile snapshot: /proc/icon2html — 3698 calls / 7.2s total CPU / 6.7s self / 2.0s overtime.
// icon2html renders only an atom's base icon/icon_state (overlays are never flattened), so its
// asset output is a pure function of (icon file, icon_state, dir, frame, moving). A bounded
// result cache (GLOB.icon2html_result_cache → list(asset_name, html, url)) lets repeat calls
// skip get_icon_dmi_path / fcopy_rsc / md5 / icon() entirely. Verifies the eviction strategy
// (shared Cut(1, MAX/4 + 1) idiom used by the other icon caches) keeps the cache bounded while
// retaining ~75% of entries. A live functional test is impossible here — unit tests run
// headless, GLOB.clients is empty, and icon2html early-returns when there is no target.
/datum/unit_test/icon2html_result_cache_eviction_math/Run()
	var/list/synthetic_cache = list()
	for(var/i in 1 to ICON2HTML_RESULT_CACHE_MAX + 5)
		synthetic_cache["entry_[i]"] = list("name_[i]", "html_[i]", "url_[i]")

	if(length(synthetic_cache) > ICON2HTML_RESULT_CACHE_MAX)
		synthetic_cache.Cut(1, (ICON2HTML_RESULT_CACHE_MAX / 4) + 1)

	TEST_ASSERT(length(synthetic_cache) <= ICON2HTML_RESULT_CACHE_MAX, "Eviction must keep cache <= ICON2HTML_RESULT_CACHE_MAX (got [length(synthetic_cache)])")
	TEST_ASSERT(length(synthetic_cache) >= (ICON2HTML_RESULT_CACHE_MAX * 3 / 4), "Eviction should retain ~75% of entries (got [length(synthetic_cache)])")
	TEST_ASSERT(isnull(synthetic_cache["entry_1"]), "Oldest entry should be evicted")
	TEST_ASSERT_NOTNULL(synthetic_cache["entry_[ICON2HTML_RESULT_CACHE_MAX + 1]"], "Recently-added entry should survive eviction")
	TEST_ASSERT(GLOB.icon2html_result_cache != null, "GLOB.icon2html_result_cache must be initialized as a list")


// ===== Fix G.2: icon2html result cache covers humans =====
//
// Humans were originally excluded from the result cache, but icon2html's human path only Insert()s
// the same base icon/icon_state and forces dir = SOUTH — its output is still a pure function of
// (icon file, icon_state, frame, moving), so it is cacheable. This costs ~1.6ms/call (icon() +
// Insert() + md5asfile) every time without the cache. We exploit that send_assets() early-returns
// on a mob with no client, so we can drive the full icon2html pipeline headlessly with such a mob.
/datum/unit_test/icon2html_human_result_cached/Run()
	var/mob/null_target = allocate(/mob)
	var/mob/living/carbon/human/subject = allocate(/mob/living/carbon/human)

	var/before = length(GLOB.icon2html_result_cache)
	var/html_first = icon2html(subject, null_target)
	TEST_ASSERT_NOTNULL(html_first, "icon2html on a human must return an <img> string")
	TEST_ASSERT(findtext(html_first, "<img"), "icon2html on a human must return an <img ...> tag (got [html_first])")
	TEST_ASSERT(length(GLOB.icon2html_result_cache) > before, "icon2html on a human must populate the result cache (humans are now cached)")

	var/after_first = length(GLOB.icon2html_result_cache)
	var/html_second = icon2html(subject, null_target)
	TEST_ASSERT_EQUAL(html_first, html_second, "repeat icon2html on the same human must return the identical cached html")
	TEST_ASSERT_EQUAL(length(GLOB.icon2html_result_cache), after_first, "the second icon2html call on the same human must hit the cache, not add another entry")

	// sourceonly path must also be served from the same entry and return a bare url, not an <img>.
	var/url = icon2html(subject, null_target, sourceonly = TRUE)
	TEST_ASSERT_NOTNULL(url, "icon2html(sourceonly) on a cached human must return a url")
	TEST_ASSERT(!findtext(url, "<img"), "icon2html(sourceonly) must return a bare url, not an <img> tag (got [url])")
	TEST_ASSERT_EQUAL(length(GLOB.icon2html_result_cache), after_first, "sourceonly call on a cached human must not add a new entry")


// ===== Fix H: get_icon_dmi_path memoisation =====
//
// get_icon_dmi_path runs on every icon2html call that misses the result cache (and for raw-file
// inputs). Its result is a pure function of the resolved icon file, so it is now memoised per
// icon file (GLOB.icon_dmi_path_cache, empty-string = negative-cache sentinel). Runtime /icon
// datums are NOT cached — they all stringify to "/icon" and would collide.
/datum/unit_test/get_icon_dmi_path_caching/Run()
	var/obj/item/subject = allocate(/obj/item/flashlight)
	var/icon_file = subject.icon
	TEST_ASSERT_NOTNULL(icon_file, "test fixture must have an icon")

	var/path_first = get_icon_dmi_path(subject)
	var/path_second = get_icon_dmi_path(subject)
	TEST_ASSERT_EQUAL(path_first, path_second, "get_icon_dmi_path must be stable across calls")
	TEST_ASSERT_NOTNULL(path_first, "a compile-time dmi item must resolve to a dmi path")
	TEST_ASSERT(is_valid_dmi_file(path_first), "resolved path must be a valid icons/*.dmi path (got [path_first])")
	TEST_ASSERT("[icon_file]" in GLOB.icon_dmi_path_cache, "get_icon_dmi_path must cache the resolved path keyed on the icon file")
	TEST_ASSERT_EQUAL(GLOB.icon_dmi_path_cache["[icon_file]"], path_first, "cached value must equal the resolved path")
	// passing the resolved icon file directly must hit the same cache entry.
	TEST_ASSERT_EQUAL(get_icon_dmi_path(icon_file), path_first, "passing the icon file directly must resolve to the same path")

	// runtime /icon datums must not be cached (would collide on the "/icon" key).
	var/size_before = length(GLOB.icon_dmi_path_cache)
	var/icon/runtime_ic = icon(icon_file)
	get_icon_dmi_path(runtime_ic)
	TEST_ASSERT_EQUAL(length(GLOB.icon_dmi_path_cache), size_before, "runtime /icon datums must not be added to icon_dmi_path_cache")


// ===== Eviction math for the new icon-helper caches (Fix F caps + Fix H cap) =====
//
// All three new caches share the Cut(1, MAX/4 + 1) "evict oldest 25%" idiom already proven by
// bicon_cache_eviction_math / humanoid_icon_cache_eviction_math. Synthetic-list logic test —
// the production procs are too expensive to invoke MAX+1 times in CI. Verifies each cap keeps
// its cache bounded while retaining ~75% of entries, so a long (4h+) round can't grow these
// without limit.
/datum/unit_test/icon_helper_cache_eviction_math/Run()
	var/list/caps = list(
		"cached_icon_states_by_file" = ICON_STATES_FILE_CACHE_MAX,
		"cached_icon_state_directional" = ICON_STATE_DIRECTIONAL_CACHE_MAX,
		"icon_dmi_path_cache" = ICON_DMI_PATH_CACHE_MAX,
	)
	for(var/cache_name in caps)
		var/cap = caps[cache_name]
		TEST_ASSERT(cap > 0, "[cache_name] cap must be positive (got [cap])")
		var/list/synthetic = list()
		for(var/i in 1 to cap + 5)
			synthetic["entry_[i]"] = i
		if(length(synthetic) > cap)
			synthetic.Cut(1, (cap / 4) + 1)
		TEST_ASSERT(length(synthetic) <= cap, "[cache_name]: eviction must keep size <= cap (got [length(synthetic)] vs [cap])")
		TEST_ASSERT(length(synthetic) >= (cap * 3 / 4), "[cache_name]: eviction should retain ~75% of entries (got [length(synthetic)])")
		TEST_ASSERT(isnull(synthetic["entry_1"]), "[cache_name]: oldest entry must be evicted")
		TEST_ASSERT_NOTNULL(synthetic["entry_[cap + 1]"], "[cache_name]: a recently-added entry must survive eviction")

	TEST_ASSERT(GLOB.cached_icon_states_by_file != null, "GLOB.cached_icon_states_by_file must be a list")
	TEST_ASSERT(GLOB.cached_icon_state_directional != null, "GLOB.cached_icon_state_directional must be a list")
	TEST_ASSERT(GLOB.icon_dmi_path_cache != null, "GLOB.icon_dmi_path_cache must be a list")


// ===== Slime/mob Life-tick movespeed churn: add_or_update short-circuits unchanged values =====

/// Test subtype: counts update_movespeed() rebuilds so the test can assert that
/// re-applying an unchanged variable slowdown (the every-Life-tick pattern used by
/// slime updatehealth, human hunger, etc.) no longer rebuilds the modifier cache.
/mob/living/simple_animal/unit_test_movespeed_counter
	var/movespeed_updates = 0

/mob/living/simple_animal/unit_test_movespeed_counter/update_movespeed()
	movespeed_updates++
	return ..()

/datum/unit_test/movespeed_variable_update_short_circuit/Run()
	var/mob/living/simple_animal/unit_test_movespeed_counter/critter = allocate(/mob/living/simple_animal/unit_test_movespeed_counter)

	// Initialize() already registered simplemob_varspeed (slowdown = speed, default 0).
	// Applying a new value must rebuild the movespeed cache and land in it.
	var/updates_before = critter.movespeed_updates
	critter.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/simplemob_varspeed, multiplicative_slowdown = 2)
	TEST_ASSERT_EQUAL(critter.movespeed_updates, updates_before + 1, "Changing a variable slowdown must rebuild movespeed")
	var/cache_at_two = critter.cached_multiplicative_slowdown

	// Re-applying the same value must be a no-op: no rebuild, cache untouched.
	critter.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/simplemob_varspeed, multiplicative_slowdown = 2)
	TEST_ASSERT_EQUAL(critter.movespeed_updates, updates_before + 1, "Re-applying an unchanged variable slowdown must not rebuild movespeed")
	TEST_ASSERT_EQUAL(critter.cached_multiplicative_slowdown, cache_at_two, "Cached slowdown must be unchanged after a same-value re-apply")

	// A different value must still propagate (positive slowdowns are additive).
	critter.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/simplemob_varspeed, multiplicative_slowdown = 5)
	TEST_ASSERT_EQUAL(critter.movespeed_updates, updates_before + 2, "Changing the slowdown again must rebuild movespeed")
	TEST_ASSERT_EQUAL(critter.cached_multiplicative_slowdown, cache_at_two + 3, "Cached slowdown must reflect the new value")
