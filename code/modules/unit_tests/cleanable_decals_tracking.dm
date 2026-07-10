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
//   4. (informational) Scan cost is logged for eyeballing; timing is NOT asserted in CI.

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
/// world state, in the same test run. Asserts only set parity; timings are
/// logged for eyeballing, never asserted (CI runner timing is not trustworthy).
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

	// Sanity: both paths must return the same set. Это единственный ассерт бенчмарка -
	// корректность. Ассерты на относительную скорость двух путей отсюда убраны: замер шёл
	// через TICK_USAGE, а обе петли длиннее тика (world-walk BYOND ещё и переводил в
	// background посреди прохода), так что дельты через границы тиков давали мусор в обе
	// стороны ("26мс" за world-walk, который реально стоит сотни), плюс CPU-steal шаренного
	// CI-раннера произвольно раздувал любую из сторон. Тайминги ниже - только в лог,
	// замером через REALTIMEOFDAY (стеночное время, разрешение 100мс).
	TEST_ASSERT_EQUAL(warm_glob.len, warm_world.len, "GLOB-based scan and world walk must produce identically-sized results (glob=[warm_glob.len] world=[warm_world.len])")

	var/iterations = 10

	// === GLOB-based scan (production path after fix) ===
	var/t_glob = REALTIMEOFDAY
	for(var/iter in 1 to iterations)
		var/list/out = list()
		for(var/obj/effect/decal/cleanable/C as anything in GLOB.cleanable_decals)
			if(!C.loc || QDELETED(C) || !C.persistent)
				continue
			if(!SSpersistence.IsValidDebrisLocation(C.loc, allowed_turf_typecache, allowed_z_cache, C.type, FALSE))
				continue
			out += C
	var/glob_total_ms = (REALTIMEOFDAY - t_glob) * 100

	// === world-walk scan (pre-fix path) ===
	var/t_world = REALTIMEOFDAY
	for(var/iter in 1 to iterations)
		var/list/out = list()
		for(var/obj/effect/decal/cleanable/C in world)
			if(!C.loc || QDELETED(C) || !C.persistent)
				continue
			if(!SSpersistence.IsValidDebrisLocation(C.loc, allowed_turf_typecache, allowed_z_cache, C.type, FALSE))
				continue
			out += C
	var/world_total_ms = (REALTIMEOFDAY - t_world) * 100

	log_test("  RelevantPersistentDebris scan benchmark ([iterations] iterations, [GLOB.cleanable_decals.len] tracked cleanables, wall-clock, 100ms resolution):")
	log_test("    GLOB-based : total [glob_total_ms]ms, per call [round(glob_total_ms / iterations, 0.1)]ms")
	log_test("    world walk : total [world_total_ms]ms, per call [round(world_total_ms / iterations, 0.1)]ms")

	// Production path, timing informational only
	var/t_prod = REALTIMEOFDAY
	for(var/iter in 1 to iterations)
		SSpersistence.RelevantPersistentDebris()
	var/prod_total_ms = (REALTIMEOFDAY - t_prod) * 100
	log_test("    Production RelevantPersistentDebris(): total [prod_total_ms]ms, per call [round(prod_total_ms / iterations, 0.1)]ms")

	// Cleanup
	for(var/obj/effect/decal/cleanable/c as anything in created)
		qdel(c)
