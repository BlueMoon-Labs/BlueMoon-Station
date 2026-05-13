// Unit tests for GLOB.cleanable_decals tracking and the persistence-debris
// scan that depends on it. Profile snapshot: SSpersistence.RelevantPersistentDebris
// (and SSpersistence.SaveMapDebris / wipe_existing_debris through it) used to do
// `for(var/obj/effect/decal/cleanable/C in world)` — an O(N_atoms_in_world) walk
// over every atom in the world, not over cleanables. Same issue lived in
// /datum/round_event_control/slaughter/canSpawnEvent.
//
// GLOB.cleanable_decals tracks every live cleanable so the scan is O(N_cleanables).
// These tests verify:
//   1. Initialize enrolls the decal in GLOB.cleanable_decals.
//   2. Destroy removes it (no list leak even on QDEL_HINT_IWILLGC reuse paths).
//   3. RelevantPersistentDebris returns the same set as a manual world walk.
//   4. Scan cost stays low on a synthetic cleanables load.

/datum/unit_test/cleanable_decals_glob_tracking_initialize/Run()
	TEST_ASSERT_NOTNULL(GLOB.cleanable_decals, "GLOB.cleanable_decals must be initialized as a list")

	var/turf/T = run_loc_floor_bottom_left
	var/initial = GLOB.cleanable_decals.len

	// Use a non-mergeable subtype so creating two does not collapse them via replace_decal().
	var/obj/effect/decal/cleanable/cobweb/cobweb1 = allocate(/obj/effect/decal/cleanable/cobweb, T)
	TEST_ASSERT(cobweb1 in GLOB.cleanable_decals, "Newly created cleanable must be tracked in GLOB.cleanable_decals")

	var/turf/T2 = locate(T.x + 1, T.y, T.z)
	TEST_ASSERT_NOTNULL(T2, "Test reservation must have an east neighbour")
	var/obj/effect/decal/cleanable/cobweb/cobweb2 = allocate(/obj/effect/decal/cleanable/cobweb, T2)
	TEST_ASSERT(cobweb2 in GLOB.cleanable_decals, "Second cleanable on a different turf must also be tracked")
	TEST_ASSERT_EQUAL(GLOB.cleanable_decals.len, initial + 2, "GLOB.cleanable_decals must grow by exactly 2 after creating 2 cleanables")

/datum/unit_test/cleanable_decals_glob_tracking_destroy/Run()
	TEST_ASSERT_NOTNULL(GLOB.cleanable_decals, "GLOB.cleanable_decals must be initialized")

	var/turf/T = run_loc_floor_bottom_left
	var/initial = GLOB.cleanable_decals.len

	var/obj/effect/decal/cleanable/cobweb/C = new(T)
	TEST_ASSERT(C in GLOB.cleanable_decals, "Sanity: cleanable enrolled after creation")

	qdel(C)
	TEST_ASSERT(!(C in GLOB.cleanable_decals), "Destroyed cleanable must be removed from GLOB.cleanable_decals")
	TEST_ASSERT_EQUAL(GLOB.cleanable_decals.len, initial, "GLOB.cleanable_decals must return to its initial length after qdel")

/// Mass create / mass qdel should not leave nulls or duplicates in the global list.
/datum/unit_test/cleanable_decals_glob_no_leaks_under_churn/Run()
	TEST_ASSERT_NOTNULL(GLOB.cleanable_decals, "GLOB.cleanable_decals must be initialized")

	var/turf/base = run_loc_floor_bottom_left
	var/list/decals = list()
	var/initial = GLOB.cleanable_decals.len

	// 5x5 grid of cleanables — cobwebs do not stack on the same tile, so one per turf.
	for(var/dx in 0 to 4)
		for(var/dy in 0 to 4)
			var/turf/T = locate(base.x + dx, base.y + dy, base.z)
			if(!T || !isturf(T))
				continue
			var/obj/effect/decal/cleanable/cobweb/c = new(T)
			decals += c

	TEST_ASSERT(decals.len >= 20, "Should have created at least 20 cleanables, got [decals.len]")
	TEST_ASSERT_EQUAL(GLOB.cleanable_decals.len, initial + decals.len, "GLOB.cleanable_decals must grow by exactly the number of created cleanables")

	// No nulls in the list
	var/nulls_found = 0
	for(var/entry in GLOB.cleanable_decals)
		if(isnull(entry))
			nulls_found++
	TEST_ASSERT_EQUAL(nulls_found, 0, "GLOB.cleanable_decals must contain no nulls after mass create (found [nulls_found])")

	// Mass qdel
	for(var/obj/effect/decal/cleanable/c as anything in decals)
		qdel(c)

	TEST_ASSERT_EQUAL(GLOB.cleanable_decals.len, initial, "GLOB.cleanable_decals must return to initial length after mass qdel")

/// Verifies SSpersistence.RelevantPersistentDebris returns the same set whether it
/// scans GLOB.cleanable_decals or every atom in world. Guards against the GLOB
/// list missing entries (the only correctness risk after the optimization).
/datum/unit_test/cleanable_decals_relevant_debris_set_parity
	priority = TEST_LONGER

/datum/unit_test/cleanable_decals_relevant_debris_set_parity/Run()
	TEST_ASSERT_NOTNULL(GLOB.cleanable_decals, "GLOB.cleanable_decals must be initialized")

	// Snapshot via the production path (GLOB-based after optimization).
	var/list/from_glob = SSpersistence.RelevantPersistentDebris()

	// Snapshot via a brute-force world walk — must contain the same persistent + valid-location entries.
	var/list/allowed_turf_typecache = typecacheof(/turf/open) - typecacheof(/turf/open/space)
	var/list/allowed_z_cache = list()
	for(var/z in SSmapping.levels_by_trait(ZTRAIT_STATION))
		allowed_z_cache[num2text(z)] = TRUE

	var/list/from_world = list()
	for(var/obj/effect/decal/cleanable/C in world)
		if(!C.loc || QDELETED(C))
			continue
		if(!C.persistent)
			continue
		if(!SSpersistence.IsValidDebrisLocation(C.loc, allowed_turf_typecache, allowed_z_cache, C.type, FALSE))
			continue
		from_world += C

	TEST_ASSERT_EQUAL(from_glob.len, from_world.len, "GLOB-based scan and world-based scan must return the same number of cleanables (glob=[from_glob.len] world=[from_world.len])")

	// Set equality
	for(var/obj/effect/decal/cleanable/C as anything in from_world)
		TEST_ASSERT(C in from_glob, "Cleanable [C] ([C.type]) at [COORD(C)] is in world scan but missing from GLOB-based scan — GLOB tracking has a hole")
	for(var/obj/effect/decal/cleanable/C as anything in from_glob)
		TEST_ASSERT(C in from_world, "Cleanable [C] ([C.type]) at [COORD(C)] is in GLOB scan but not produced by world scan — false positive")

/// Side-by-side benchmark: scan a fixed set of cleanables via the production
/// path (GLOB-based) vs the pre-fix path (`for(... in world)`), on the same
/// world state, in the same test run. Reports the speedup ratio via log_test.
/// The size of `world` (every atom on the test map) is what makes the old
/// scan expensive — the new scan only walks `GLOB.cleanable_decals`.
/datum/unit_test/cleanable_decals_glob_vs_world_walk_benchmark
	priority = TEST_LONGER

/datum/unit_test/cleanable_decals_glob_vs_world_walk_benchmark/Run()
	TEST_ASSERT_NOTNULL(GLOB.cleanable_decals, "GLOB.cleanable_decals must be initialized")

	var/turf/base = run_loc_floor_bottom_left
	var/list/created = list()
	for(var/dx in 0 to 4)
		for(var/dy in 0 to 4)
			var/turf/T = locate(base.x + dx, base.y + dy, base.z)
			if(!T || !isturf(T))
				continue
			created += new /obj/effect/decal/cleanable/cobweb(T)

	// Production filters — same for both paths so the only difference is the iterator source.
	var/list/allowed_turf_typecache = typecacheof(/turf/open) - typecacheof(/turf/open/space)
	var/list/allowed_z_cache = list()
	for(var/z in SSmapping.levels_by_trait(ZTRAIT_STATION))
		allowed_z_cache[num2text(z)] = TRUE

	// Warm both paths once so any one-shot caches do not skew the first measurement.
	var/list/warm_glob = list()
	for(var/obj/effect/decal/cleanable/C as anything in GLOB.cleanable_decals)
		if(!C.loc || QDELETED(C) || !C.persistent)
			continue
		if(!SSpersistence.IsValidDebrisLocation(C.loc, allowed_turf_typecache, allowed_z_cache, C.type, FALSE))
			continue
		warm_glob += C
	var/list/warm_world = list()
	for(var/obj/effect/decal/cleanable/C in world)
		if(!C.loc || QDELETED(C) || !C.persistent)
			continue
		if(!SSpersistence.IsValidDebrisLocation(C.loc, allowed_turf_typecache, allowed_z_cache, C.type, FALSE))
			continue
		warm_world += C

	var/iterations = 30

	// === GLOB-based scan (production path after fix) ===
	var/t_glob = TICK_USAGE_REAL
	for(var/iter in 1 to iterations)
		var/list/out = list()
		for(var/obj/effect/decal/cleanable/C as anything in GLOB.cleanable_decals)
			if(!C.loc || QDELETED(C) || !C.persistent)
				continue
			if(!SSpersistence.IsValidDebrisLocation(C.loc, allowed_turf_typecache, allowed_z_cache, C.type, FALSE))
				continue
			out += C
	var/glob_total_ms = TICK_USAGE_TO_MS(t_glob)
	var/glob_per_call_ms = glob_total_ms / iterations

	// === world-walk scan (pre-fix path) ===
	var/t_world = TICK_USAGE_REAL
	for(var/iter in 1 to iterations)
		var/list/out = list()
		for(var/obj/effect/decal/cleanable/C in world)
			if(!C.loc || QDELETED(C) || !C.persistent)
				continue
			if(!SSpersistence.IsValidDebrisLocation(C.loc, allowed_turf_typecache, allowed_z_cache, C.type, FALSE))
				continue
			out += C
	var/world_total_ms = TICK_USAGE_TO_MS(t_world)
	var/world_per_call_ms = world_total_ms / iterations

	var/speedup = (glob_total_ms > 0.001) ? (world_total_ms / glob_total_ms) : 0

	log_test("  RelevantPersistentDebris scan benchmark ([iterations] iterations, [GLOB.cleanable_decals.len] tracked cleanables, world has many atoms):")
	log_test("    GLOB-based : total [round(glob_total_ms, 0.01)]ms, per call [round(glob_per_call_ms, 0.001)]ms")
	log_test("    world walk : total [round(world_total_ms, 0.01)]ms, per call [round(world_per_call_ms, 0.001)]ms")
	if(speedup > 0)
		log_test("    Speedup    : [round(speedup, 0.1)]x (GLOB faster than world walk)")

	// Sanity: both paths must return the same set
	TEST_ASSERT_EQUAL(warm_glob.len, warm_world.len, "GLOB-based scan and world walk must produce identically-sized results (glob=[warm_glob.len] world=[warm_world.len]) — otherwise the speedup is comparing apples to oranges")

	// Hard floor: GLOB scan must not be slower than world walk. If it is, GLOB list grew unbounded
	// or the production proc fell back to a world walk. On Box Station this is a 7x+ gap.
	if(world_total_ms > 0.05) // Only assert when world walk is measurable — otherwise noise dominates.
		TEST_ASSERT(glob_total_ms < world_total_ms, "GLOB-based scan ([round(glob_total_ms, 0.01)]ms) must be faster than world walk ([round(world_total_ms, 0.01)]ms) — investigate GLOB.cleanable_decals contents")
		// Stronger sanity: if there were enough cleanables to make the world walk take real time,
		// the speedup should be at least 2x. On a real station, the gap is ~7x.
		if(world_total_ms > 50)
			TEST_ASSERT(speedup >= 2, "GLOB-based scan must be at least 2x faster than world walk on non-trivial loads (got [round(speedup, 0.1)]x with world walk at [round(world_total_ms, 0.01)]ms)")

	// Production path matches what we just measured
	var/t_prod = TICK_USAGE_REAL
	for(var/iter in 1 to iterations)
		SSpersistence.RelevantPersistentDebris()
	var/prod_total_ms = TICK_USAGE_TO_MS(t_prod)
	log_test("    Production RelevantPersistentDebris(): total [round(prod_total_ms, 0.01)]ms, per call [round(prod_total_ms / iterations, 0.001)]ms")
	// On Box Station with ~3000 cleanables the GLOB-based scan measures ~8ms/call (vs ~60ms/call
	// for the pre-fix world walk — verified 7.3x speedup). Budget set at 20ms to leave room for CI
	// noise and station growth. If this assertion ever fails, it means either the GLOB list grew
	// unbounded or someone replaced the scan with a world walk again.
	TEST_ASSERT(prod_total_ms / iterations < 20, "RelevantPersistentDebris per-call cost must be under 20ms (got [round(prod_total_ms / iterations, 0.01)]ms)")

	// Cleanup
	for(var/obj/effect/decal/cleanable/c as anything in created)
		qdel(c)
