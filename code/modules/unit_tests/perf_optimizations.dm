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


/// Malformed or overlapping map loads can ask a component about a pipeline or
/// connector it does not actually contain. The lookup must fail softly instead
/// of using a failed lookup result as a list index and raising a runtime.
/datum/unit_test/atmos_component_pipenet_lookup_guards/Run()
	var/obj/machinery/atmospherics/pipe/build_pipeline_test_node/connected_pipe = allocate(/obj/machinery/atmospherics/pipe/build_pipeline_test_node)
	var/obj/machinery/atmospherics/pipe/build_pipeline_test_node/unknown_pipe = allocate(/obj/machinery/atmospherics/pipe/build_pipeline_test_node)
	var/obj/machinery/atmospherics/components/build_pipeline_test_component/component = allocate(/obj/machinery/atmospherics/components/build_pipeline_test_component)
	var/datum/pipeline/connected_pipeline = new
	var/datum/pipeline/unknown_pipeline = new
	var/datum/pipeline/replacement_pipeline = new
	allocated += connected_pipeline
	allocated += unknown_pipeline
	allocated += replacement_pipeline

	component.nodes[1] = connected_pipe
	component.setPipenet(connected_pipeline, connected_pipe)
	TEST_ASSERT_EQUAL(component.returnPipenet(connected_pipe), connected_pipeline, "Valid connector must be assigned its pipeline")

	var/runtimes_before = GLOB.total_runtimes
	var/list/missing_expansion = component.pipeline_expansion(unknown_pipeline)
	component.setPipenet(replacement_pipeline, unknown_pipe)
	component.replacePipenet(unknown_pipeline, replacement_pipeline)
	var/runtimes_added = GLOB.total_runtimes - runtimes_before

	TEST_ASSERT_EQUAL(runtimes_added, 0, "Missing pipenet lookups must not raise runtimes (got [runtimes_added])")
	TEST_ASSERT_EQUAL(length(missing_expansion), 0, "Unknown pipeline must have no expansion")
	TEST_ASSERT_EQUAL(component.returnPipenet(connected_pipe), connected_pipeline, "Failed lookups must not change the valid pipeline")

	var/list/known_expansion = component.pipeline_expansion(connected_pipeline)
	TEST_ASSERT_EQUAL(length(known_expansion), 1, "Known pipeline must return one connected node")
	TEST_ASSERT_EQUAL(known_expansion[1], connected_pipe, "Known pipeline must expand to its connected pipe")
	component.replacePipenet(connected_pipeline, replacement_pipeline)
	TEST_ASSERT_EQUAL(component.returnPipenet(connected_pipe), replacement_pipeline, "Valid pipeline replacement must still succeed")


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


// ===== Ventcrawl pipe vision: collect_pipes_in_view hoists the bounds check =====
//
// Profile snapshot (perf.log 2026-07): /proc/in_view_range - 749294 calls / 1.16s
// self + /proc/getviewsize - 753355 calls / 0.55s self, nearly all from
// add_ventcrawl() iterating EVERY member of the pipenet (a station distro loop is
// thousands of pipes) and paying a proc call + a list allocation per pipe, on
// every ventcrawl step. collect_pipes_in_view() computes the view box once and
// does inline comparisons per pipe.

/// Simulates the retired per-pipe path (in_view_range body: getviewsize list
/// allocation + turf lookup + inclusive range check) for an honest A/B timing.
/datum/unit_test/ventcrawl_pipe_collection/proc/legacy_in_view_range_sim(turf/source, atom/candidate, view)
	var/list/view_range = getviewsize(view)
	var/turf/target = get_turf(candidate)
	if(isnull(target))
		return FALSE
	return ISINRANGE(target.x, source.x - view_range[1], source.x + view_range[1]) && ISINRANGE(target.y, source.y - view_range[1], source.y + view_range[1])

#define VENTCRAWL_BENCH_PIPES 2000
#define VENTCRAWL_BENCH_PASSES 20

/datum/unit_test/ventcrawl_pipe_collection/Run()
	var/turf/source_turf = run_loc_floor_bottom_left

	// --- Correctness ---
	var/obj/machinery/atmospherics/pipe/build_pipeline_test_node/near_pipe = allocate(/obj/machinery/atmospherics/pipe/build_pipeline_test_node)
	near_pipe.forceMove(source_turf)
	var/turf/far_turf = get_step(get_step(get_step(source_turf, EAST), EAST), EAST)
	TEST_ASSERT_NOTNULL(far_turf, "Test reservation must have three EAST neighbours")
	var/obj/machinery/atmospherics/pipe/build_pipeline_test_node/far_pipe = allocate(/obj/machinery/atmospherics/pipe/build_pipeline_test_node)
	far_pipe.forceMove(far_turf)
	var/obj/machinery/atmospherics/pipe/build_pipeline_test_node/nowhere_pipe = allocate(/obj/machinery/atmospherics/pipe/build_pipeline_test_node)
	nowhere_pipe.moveToNullspace()

	var/list/members = list(near_pipe, far_pipe, nowhere_pipe)

	var/list/tight = list()
	collect_pipes_in_view(source_turf, 2, members, tight)
	TEST_ASSERT(near_pipe in tight, "Pipe on the source turf must be collected")
	TEST_ASSERT(!(far_pipe in tight), "Pipe outside the view box must not be collected")
	TEST_ASSERT(!(nowhere_pipe in tight), "Nullspace pipe must be skipped")

	var/list/wide = list()
	collect_pipes_in_view(source_turf, 7, members, wide)
	TEST_ASSERT(near_pipe in wide, "Near pipe must be collected with a wide box")
	TEST_ASSERT(far_pipe in wide, "Pipe three tiles away must be collected with view_half 7")
	TEST_ASSERT(!(nowhere_pipe in wide), "Nullspace pipe must be skipped regardless of box size")

	// Both paths must agree on visibility for every member
	for(var/obj/machinery/atmospherics/member as anything in members)
		var/legacy_visible = legacy_in_view_range_sim(source_turf, member, "15x15") // legacy used the raw width (15) as the box half-size
		var/list/single = list()
		collect_pipes_in_view(source_turf, 15, list(member), single)
		TEST_ASSERT_EQUAL(!!(member in single), !!legacy_visible, "New and legacy visibility must agree for [member] ([member.loc])")

	// --- Benchmark ---
	var/list/bench_members = list()
	for(var/i in 1 to VENTCRAWL_BENCH_PIPES)
		var/obj/machinery/atmospherics/pipe/build_pipeline_test_node/bench_pipe = new(source_turf)
		allocated += bench_pipe
		bench_members += bench_pipe

	var/start = REALTIMEOFDAY
	for(var/pass in 1 to VENTCRAWL_BENCH_PASSES)
		var/list/sink = list()
		collect_pipes_in_view(source_turf, 7, bench_members, sink)
	var/new_ds = REALTIMEOFDAY - start

	start = REALTIMEOFDAY
	for(var/pass in 1 to VENTCRAWL_BENCH_PASSES)
		var/list/sink = list()
		for(var/obj/machinery/atmospherics/member as anything in bench_members)
			if(legacy_in_view_range_sim(source_turf, member, "15x15"))
				sink += member
	var/legacy_ds = REALTIMEOFDAY - start

	log_world("### VENTCRAWL BENCH: [VENTCRAWL_BENCH_PASSES]x[VENTCRAWL_BENCH_PIPES] pipes: new = [new_ds] ds; legacy-style = [legacy_ds] ds")

#undef VENTCRAWL_BENCH_PIPES
#undef VENTCRAWL_BENCH_PASSES


// ===== Throw impact sound cap (Paradise port) =====
//
// SSthrowing.playsound_capped() drops throw-impact sounds past
// impact_sounds_cap per tick: a grenade dump or an explosion throwing a room's
// contents produces hundreds of playsound() bursts in one tick, each one
// fanning out to every listener in range.

/datum/unit_test/throw_impact_sound_cap/Run()
	var/old_impact = SSthrowing.impact_sounds
	var/old_skipped = SSthrowing.skipped_sounds
	var/old_last = SSthrowing.last_impact_sounds
	SSthrowing.impact_sounds = 0
	SSthrowing.skipped_sounds = 0

	var/cap = SSthrowing.impact_sounds_cap
	TEST_ASSERT(cap > 0, "impact_sounds_cap must be positive (got [cap])")

	var/played = 0
	for(var/i in 1 to cap + 5)
		if(SSthrowing.playsound_capped(run_loc_floor_bottom_left, 'sound/weapons/genhit.ogg', 30, TRUE, -1))
			played++

	TEST_ASSERT_EQUAL(played, cap, "Exactly impact_sounds_cap sounds must play in one tick window")
	TEST_ASSERT_EQUAL(SSthrowing.impact_sounds, cap, "impact_sounds counter must stop at the cap")
	TEST_ASSERT_EQUAL(SSthrowing.skipped_sounds, 5, "Sounds past the cap must be counted as skipped")

	// fire() opens a new tick window: counter resets, last tick's total is kept
	SSthrowing.fire(resumed = FALSE)
	TEST_ASSERT_EQUAL(SSthrowing.impact_sounds, 0, "fire() must reset the per-tick sound counter")
	TEST_ASSERT_EQUAL(SSthrowing.last_impact_sounds, cap, "fire() must record last tick's sound total")
	TEST_ASSERT(SSthrowing.playsound_capped(run_loc_floor_bottom_left, 'sound/weapons/genhit.ogg', 30, TRUE, -1), "First sound of a fresh window must play")

	SSthrowing.impact_sounds = old_impact
	SSthrowing.skipped_sounds = old_skipped
	SSthrowing.last_impact_sounds = old_last


// ===== Storage typecache statics =====
//
// Profile snapshot (perf.log 2026-07): /proc/typecacheof - 1445 calls per
// round, all of its 0.16s self time counted as tick OVERTIME (it runs in spawn
// bursts), plus per-type hotspots like wallet/tailbag ComponentInitialize.
// Storage whitelists are compile-time constants, so they are now built once
// into proc statics and shared. Two invariants matter:
//   1. instances of the same type share one list (the point of the change);
//   2. subtypes must not mutate the shared parent list (the old tailbag
//      `can_hold |=` would now poison every wallet - it builds its own merged
//      static instead).

/datum/unit_test/storage_typecache_statics/Run()
	var/obj/item/storage/wallet/wallet_one = allocate(/obj/item/storage/wallet)
	var/obj/item/storage/wallet/wallet_two = allocate(/obj/item/storage/wallet)
	var/obj/item/storage/wallet/tailbag/tail_one = allocate(/obj/item/storage/wallet/tailbag)
	var/obj/item/storage/wallet/tailbag/tail_two = allocate(/obj/item/storage/wallet/tailbag)

	var/datum/component/storage/wallet_store_one = wallet_one.GetComponent(/datum/component/storage)
	var/datum/component/storage/wallet_store_two = wallet_two.GetComponent(/datum/component/storage)
	var/datum/component/storage/tail_store_one = tail_one.GetComponent(/datum/component/storage)
	var/datum/component/storage/tail_store_two = tail_two.GetComponent(/datum/component/storage)
	TEST_ASSERT_NOTNULL(wallet_store_one, "wallet must have a storage component")
	TEST_ASSERT_NOTNULL(tail_store_one, "tailbag must have a storage component")

	// Same type -> same shared list instance (no per-spawn typecacheof rebuild)
	TEST_ASSERT_EQUAL("\ref[wallet_store_one.can_hold]", "\ref[wallet_store_two.can_hold]", "Two wallets must share one static can_hold list")
	TEST_ASSERT_EQUAL("\ref[tail_store_one.can_hold]", "\ref[tail_store_two.can_hold]", "Two tailbags must share one static can_hold list")

	// Tailbag whitelist = wallet whitelist + extras
	TEST_ASSERT(tail_store_one.can_hold[/obj/item/restraints/handcuffs], "Tailbag must accept its extra types (handcuffs)")
	TEST_ASSERT(tail_store_one.can_hold[/obj/item/pen], "Tailbag must keep the common wallet types (pen)")
	TEST_ASSERT(wallet_store_one.can_hold[/obj/item/pen], "Wallet must accept its own whitelist (pen)")

	// The merged tailbag list must NOT leak back into the shared wallet list
	TEST_ASSERT(!wallet_store_one.can_hold[/obj/item/restraints/handcuffs], "Wallet whitelist must not be poisoned by tailbag extras (handcuffs)")
	TEST_ASSERT_NOTEQUAL("\ref[wallet_store_one.can_hold]", "\ref[tail_store_one.can_hold]", "Wallet and tailbag must use different list instances")

// ===== Status effects: passive permanents stay out of processing =====
//
// perf2.log (4h, 1 player): 5.19M /datum/status_effect/process calls - wound
// family effects live forever on NPC corpses and burned a slot in every
// SSstatus_effects fire while their tick() is a no-op. Effects with
// duration -1 AND tick_interval -1 now never enter processing.

/datum/status_effect/unit_test_passive
	id = "unit_test_passive"
	duration = -1
	tick_interval = -1
	alert_type = null

/datum/status_effect/unit_test_finite
	id = "unit_test_finite"
	duration = 30 SECONDS
	tick_interval = -1
	alert_type = null

/datum/unit_test/status_effect_processing_gate/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)

	var/datum/status_effect/passive_effect = human.apply_status_effect(/datum/status_effect/unit_test_passive)
	TEST_ASSERT_NOTNULL(passive_effect, "the passive test effect must apply")
	TEST_ASSERT(!(passive_effect in SSstatus_effects.processing), "A permanent no-tick effect must not enter SSstatus_effects processing")

	var/datum/status_effect/finite_effect = human.apply_status_effect(/datum/status_effect/unit_test_finite)
	TEST_ASSERT_NOTNULL(finite_effect, "the finite test effect must apply")
	TEST_ASSERT(finite_effect in SSstatus_effects.processing, "A finite effect must keep processing (it has to expire)")

	// the perf.log offenders are pinned as passive: signal-driven, no tick()
	// (vars hold the TYPEPATH: initial() on a null-valued var reads nothing)
	var/datum/status_effect/wound/wound_type = /datum/status_effect/wound
	var/datum/status_effect/limp/limp_type = /datum/status_effect/limp
	var/datum/status_effect/determined/determined_type = /datum/status_effect/determined
	TEST_ASSERT_EQUAL(initial(wound_type.tick_interval), -1, "wound status effects must stay passive (tick_interval -1)")
	TEST_ASSERT_EQUAL(initial(limp_type.tick_interval), -1, "limp must stay passive (tick_interval -1)")
	TEST_ASSERT_EQUAL(initial(determined_type.tick_interval), -1, "determined must stay passive (tick_interval -1)")

	human.remove_status_effect(/datum/status_effect/unit_test_passive)
	human.remove_status_effect(/datum/status_effect/unit_test_finite)

// ===== Pool drain: fastprocess only while a fill/drain cycle runs =====
//
// perf2.log: /obj/machinery/pool/drain/process = 45k calls / 12s total on an
// idle server - the item-suction range() scan ran 10 times a second forever.
// Idle drains now sit on slow SSobj and only join SSfastprocess for
// the duration of an active cycle.

/datum/unit_test/pool_drain_idle_cadence/Run()
	var/obj/machinery/pool/drain/drain = allocate(/obj/machinery/pool/drain)
	TEST_ASSERT(drain in SSobj.processing, "An idle pool drain must sit on slow processing")
	TEST_ASSERT(!(drain in SSfastprocess.processing), "An idle pool drain must not be on fastprocess")

	drain.set_active(TRUE)
	TEST_ASSERT(drain in SSfastprocess.processing, "An active pool drain must move to fastprocess")
	TEST_ASSERT(!(drain in SSobj.processing), "An active pool drain must leave slow processing")

	drain.set_active(FALSE)
	TEST_ASSERT(drain in SSobj.processing, "A deactivated pool drain must return to slow processing")
	TEST_ASSERT(!(drain in SSfastprocess.processing), "A deactivated pool drain must leave fastprocess")

// ===== Plumbing: демандер без подключений паркуется, add_plumber будит =====
//
// perf3.log: 276k send_request/process_request за холостой раунд - каждый
// роундстартовый хим-агрегат без единого дакта гонял пустой request-цикл
// каждый фаер SSfluids.

/datum/unit_test/plumbing_idle_park/Run()
	var/obj/item/holder = allocate(/obj/item)
	holder.create_reagents(100)
	var/datum/component/plumbing/simple_demand/demander = holder.AddComponent(/datum/component/plumbing/simple_demand)
	TEST_ASSERT_NOTNULL(demander, "the demand component must attach to an obj with reagents")
	TEST_ASSERT(demander.active, "the component must enable on creation")
	TEST_ASSERT(demander.datum_flags & DF_ISPROCESSING, "a fresh demander starts on SSfluids")

	// Без дактов первый же фаер паркует компонент.
	demander.process()
	TEST_ASSERT(!(demander.datum_flags & DF_ISPROCESSING), "a demander with no duct connections must park itself")

	// Подключение через ductnet будит.
	var/datum/ductnet/net = new
	TEST_ASSERT(net.add_plumber(demander, NORTH), "add_plumber must accept the active demander on its demand side")
	TEST_ASSERT(demander.datum_flags & DF_ISPROCESSING, "connecting a duct network must wake the parked demander")
	TEST_ASSERT_EQUAL(length(demander.ducts), 1, "the demander must track its new connection")

	// Отключение: следующий фаер снова паркует.
	net.remove_plumber(demander) // с пустым списком дактов сеть самоуничтожается
	TEST_ASSERT_EQUAL(length(demander.ducts), 0, "remove_plumber must clear the tracked connection")
	demander.process()
	TEST_ASSERT(!(demander.datum_flags & DF_ISPROCESSING), "a disconnected demander must park itself again")

// ===== alarm_handler: clear_alarm без своих тревог - дешёвый ранний выход =====
//
// perf3.log: 56k clear_alarm за раунд (здоровые APC зовут его каждый фаер),
// каждый вызов ходил в get_area. Теперь пустой sent_alarms отсекает сразу.

/datum/unit_test/alarm_handler_clear_fastpath/Run()
	var/obj/machinery/source = allocate(/obj/machinery)
	var/datum/alarm_handler/handler = new(source)

	TEST_ASSERT_EQUAL(handler.clear_alarm(ALARM_POWER), FALSE, "clear_alarm with nothing sent must return FALSE via the early exit")

	// Тревога должна по-прежнему ставиться и сниматься. Резервация лежит в
	// /area/space - подсовываем синтетическую область без NO_ALERTS.
	var/turf/floor = run_loc_floor_bottom_left
	var/area/original_area = get_area(floor)
	var/area/test_area = new /area
	allocated += test_area
	test_area.contents.Add(floor)
	source.forceMove(floor)

	handler.send_alarm(ALARM_POWER)
	TEST_ASSERT(handler.sent_alarms[ALARM_POWER], "send_alarm must record the alarm on the handler")
	TEST_ASSERT_EQUAL(handler.clear_alarm(ALARM_POWER), TRUE, "clear_alarm must still clear a real alarm")
	TEST_ASSERT(!handler.sent_alarms[ALARM_POWER], "the cleared alarm must leave the handler's ledger")

	qdel(handler)
	original_area.contents.Add(floor)

// ===== Статус-эффекты: вечные без tick() не встают в SSstatus_effects =====
//
// perf3.log: 2.15M status_effect/process за раунд - ~187 вечных эффектов с
// дефолтным tick_interval. Главный виновник - crusher_damage на каждом
// майнинг-мобе и мегафауне.

/datum/unit_test/status_effect_passive_optouts/Run()
	// Пины на initial() (переменные держат ТАЙППУТЬ - initial() на null не работает).
	var/datum/status_effect/crusher_damage/crusher_type = /datum/status_effect/crusher_damage
	var/datum/status_effect/in_love/love_type = /datum/status_effect/in_love
	var/datum/status_effect/vtec_disabled/vtec_type = /datum/status_effect/vtec_disabled
	var/datum/status_effect/pregnancy/pregnancy_type = /datum/status_effect/pregnancy
	var/datum/status_effect/lactation/lactation_type = /datum/status_effect/lactation
	var/datum/status_effect/frenzy/frenzy_type = /datum/status_effect/frenzy
	TEST_ASSERT_EQUAL(initial(crusher_type.tick_interval), -1, "crusher_damage is a pure data holder - it must not tick")
	TEST_ASSERT_EQUAL(initial(love_type.tick_interval), -1, "in_love only shows an alert - it must not tick")
	TEST_ASSERT_EQUAL(initial(vtec_type.tick_interval), -1, "vtec_disabled expires via duration - it must not tick")
	TEST_ASSERT_EQUAL(initial(pregnancy_type.tick_interval), -1, "pregnancy must not tick")
	TEST_ASSERT_EQUAL(initial(lactation_type.tick_interval), -1, "lactation must not tick")
	TEST_ASSERT_NOTEQUAL(initial(frenzy_type.tick_interval), -1, "frenzy DOES tick (burn damage) and must keep its interval")

	// Живой crusher_damage на мобе существует, но не процессится.
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/datum/status_effect/crusher_damage/tracker = human.apply_status_effect(STATUS_EFFECT_CRUSHERDAMAGETRACKING)
	TEST_ASSERT_NOTNULL(tracker, "the crusher tracker must apply")
	TEST_ASSERT(!(tracker.datum_flags & DF_ISPROCESSING), "a permanent tickless effect must stay out of SSstatus_effects")
	human.remove_status_effect(STATUS_EFFECT_CRUSHERDAMAGETRACKING)

// ===== Лодаут: превью генерятся лениво, а не на старте сервера =====
//
// perf3/perf4: ровно 1559 icon2base64 (~1.3с CPU) на каждом раундстарте -
// /datum/gear/New энкодил превью всего каталога. Теперь энкод по первому
// запросу UI, меню рендерит одну подкатегорию за раз.

/datum/unit_test/loadout_preview_lazy/Run()
	TEST_ASSERT(length(GLOB.loadout_items), "loadout catalog must be populated")
	var/datum/gear/probe
	var/eager = 0
	for(var/category in GLOB.loadout_items)
		var/list/subcategories = GLOB.loadout_items[category]
		for(var/subcategory in subcategories)
			var/list/items = subcategories[subcategory]
			for(var/gear_name in items)
				var/datum/gear/gear = items[gear_name]
				if(!gear)
					continue
				if(gear.base64icon)
					eager++
				if(!probe && gear.path)
					var/preview = gear.get_base64icon()
					if(preview)
						probe = gear
						TEST_ASSERT_EQUAL(gear.get_base64icon(), preview, "repeated preview requests must return the cached encode")
	TEST_ASSERT_EQUAL(eager, 0, "no gear preview may be encoded before the first UI request ([eager] already were)")
	TEST_ASSERT_NOTNULL(probe, "at least one gear item must produce a preview on demand")

// ===== Air sensor: бродкаст только при изменении показаний или heartbeat =====
//
// perf4.log: 79k receive_signal у атмос-консолей за 6-минутный холостой раунд -
// каждый сенсор рассылал отчёт всем консолям частоты, даже когда танк осел.

/datum/unit_test/air_sensor_report_gate/Run()
	var/obj/machinery/air_sensor/sensor = allocate(/obj/machinery/air_sensor)

	// Первый отчёт всегда уходит и взводит heartbeat.
	TEST_ASSERT(sensor.try_report(), "the first report must always broadcast")
	TEST_ASSERT(sensor.next_forced_report > world.time, "the first report must arm the heartbeat deadline")
	TEST_ASSERT_NOTNULL(sensor.last_report_pressure, "the report must record the broadcast readings")

	// Осевшие показания внутри heartbeat-окна - тишина в эфире.
	TEST_ASSERT(!sensor.try_report(), "unchanged readings inside the heartbeat window must not broadcast")

	// Изменение показаний пробивает гейт.
	sensor.last_report_pressure += 10
	TEST_ASSERT(sensor.try_report(), "a pressure delta must broadcast")

	// Истёкший heartbeat пробивает гейт даже без изменений.
	sensor.next_forced_report = 0
	TEST_ASSERT(sensor.try_report(), "an expired heartbeat must force a broadcast")
	TEST_ASSERT(sensor.next_forced_report > world.time, "the forced broadcast must re-arm the heartbeat")

// ===== Спеллы вне SSfastprocess: perform() обязан будить откат =====
//
// Пас 24fcd1779e снял вечный START_PROCESSING из Initialize: заряженный спелл
// не молотит в SSfastprocess всю жизнь владельца. Регресс первой версии:
// perform() выставлял recharging = TRUE голым флагом, спелл не вставал в
// очередь и после первого каста не откатывался никогда (тот же баг в
// on_hand_destroy тач-спеллов). Тест гоняет реальный путь каста и полный
// цикл отката.

/datum/unit_test/spell_recharge_after_cast/Run()
	var/obj/effect/proc_holder/spell/spell = allocate(/obj/effect/proc_holder/spell)
	spell.charge_max = 10
	spell.charge_counter = 10
	spell.recharging = FALSE

	// Реальный путь каста: cast_check() роняет счётчик, perform() стартует откат
	TEST_ASSERT(spell.cast_check(FALSE, null, TRUE), "premise: cast_check must pass for a fully charged spell")
	TEST_ASSERT_EQUAL(spell.charge_counter, 0, "cast_check must zero the charge counter")
	spell.perform(list(), TRUE, null)
	TEST_ASSERT(spell.recharging, "perform() must mark the spell as recharging")
	TEST_ASSERT(spell in SSfastprocess.processing, "perform() must return the spell to SSfastprocess")

	// Полный откат: process() докручивает счётчик (+2 за фаер) и гасит флаг
	for(var/i in 1 to 5)
		spell.process()
	TEST_ASSERT_EQUAL(spell.charge_counter, spell.charge_max, "five processes at +2 must fully recharge charge_max = 10")
	TEST_ASSERT(!spell.recharging, "a recharged spell must clear the recharging flag")
	TEST_ASSERT_EQUAL(spell.process(), PROCESS_KILL, "a fully recharged spell must PROCESS_KILL out of SSfastprocess")

/datum/unit_test/touch_spell_recharge_on_hand_destroy/Run()
	var/obj/effect/proc_holder/spell/targeted/touch/touch_spell = allocate(/obj/effect/proc_holder/spell/targeted/touch)
	touch_spell.charge_max = 10
	touch_spell.charge_counter = 0
	touch_spell.recharging = FALSE
	var/obj/item/melee/touch_attack/hand = new(touch_spell)
	allocated += hand
	touch_spell.attached_hand = hand
	hand.attached_spell = touch_spell

	// Рука истратилась (charges_check) - спелл обязан проснуться на откат
	touch_spell.on_hand_destroy(hand)
	TEST_ASSERT_NULL(touch_spell.attached_hand, "on_hand_destroy must detach the hand")
	TEST_ASSERT(touch_spell.recharging, "on_hand_destroy must mark the touch spell as recharging")
	TEST_ASSERT(touch_spell in SSfastprocess.processing, "on_hand_destroy must return the touch spell to SSfastprocess")
