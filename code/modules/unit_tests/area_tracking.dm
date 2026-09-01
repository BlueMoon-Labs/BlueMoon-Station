// Unit tests for GLOB.all_areas tracking and the consumers that depended on
// O(N_world) atom walks to find areas. Same pattern as GLOB.cleanable_decals.
//
// Pre-fix call sites:
//   repopulate_sorted_areas()              code/__HELPERS/areas.dm
//   make_maint_all_access()                code/modules/security_levels/keycard_authentication.dm
//   revoke_maint_all_access()              same
// All three iterated `for(var/area/A in world)` — DM walks every atom in world
// and filters by type, which on a real station is tens of thousands of atoms.
// GLOB.all_areas tracks every live area so these become O(N_areas).
//
// GLOB.areas_by_type cannot replace these calls on its own: only UNIQUE_AREA
// instances are written to it (see /area/New() in code/game/area/areas.dm).
// We need a list that contains every live area regardless of flag.

/datum/unit_test/area_glob_all_areas_initialized/Run()
	TEST_ASSERT_NOTNULL(GLOB.all_areas, "GLOB.all_areas must be initialized as a list")
	TEST_ASSERT(GLOB.all_areas.len > 0, "GLOB.all_areas must contain the map's areas after world init (got [GLOB.all_areas.len])")

	// Every entry must be a live (non-deleted) area.
	for(var/datum/entry as anything in GLOB.all_areas)
		TEST_ASSERT(isarea(entry), "GLOB.all_areas must only contain /area instances (found [entry] [entry?.type])")
		var/area/A = entry
		TEST_ASSERT(!QDELETED(A), "GLOB.all_areas must not contain deleted areas ([A.type])")

/// Set-parity guard: the GLOB list must mirror what `for(var/area/A in world)`
/// finds, otherwise any consumer that switches to GLOB.all_areas loses areas.
/datum/unit_test/area_glob_all_areas_parity_with_world_walk
	priority = TEST_LONGER

/datum/unit_test/area_glob_all_areas_parity_with_world_walk/Run()
	TEST_ASSERT_NOTNULL(GLOB.all_areas, "GLOB.all_areas must be initialized")

	// QDELETED areas linger in world.contents until BYOND GCs them (Destroy already ran and
	// removed them from GLOB.all_areas). The invariant we want is "live areas track 1:1" —
	// ignore the lingering dead.
	var/list/from_world = list()
	for(var/area/A in world)
		if(QDELETED(A))
			continue
		from_world += A

	// Diagnostic: log every live area present in world but missing from GLOB.all_areas.
	var/list/missing = list()
	for(var/area/A as anything in from_world)
		if(!(A in GLOB.all_areas))
			missing += A
	if(missing.len)
		for(var/area/A as anything in missing)
			log_test("  PARITY MISS: [A.type] '[A.name]' (ref=[REF(A)])")

	TEST_ASSERT_EQUAL(missing.len, 0, "GLOB.all_areas misses [missing.len] live areas that exist in world walk (glob=[GLOB.all_areas.len] world=[from_world.len]) — see PARITY MISS log entries")

/// New areas created at runtime must enroll, and qdel'd areas must remove themselves.
/datum/unit_test/area_glob_all_areas_lifecycle/Run()
	TEST_ASSERT_NOTNULL(GLOB.all_areas, "GLOB.all_areas must be initialized")

	var/initial = GLOB.all_areas.len
	var/area/test_area/new_area = new
	TEST_ASSERT(new_area in GLOB.all_areas, "Newly-created area must be enrolled in GLOB.all_areas")
	TEST_ASSERT_EQUAL(GLOB.all_areas.len, initial + 1, "GLOB.all_areas must grow by exactly 1 after creating one area (got [GLOB.all_areas.len - initial])")

	// Прод-сценарий null в GLOB.sortedAreas: область попала в список (репопуляция при
	// mid-round загрузке шаблона), затем её qdel-нули. Destroy обязан выписать её из
	// sortedAreas — иначе список держит реф (гарантированный харддел), а после дела
	// в списке остаётся null и валит get_area_turfs/dead_tele по всему раунду.
	new_area.addSorted()
	TEST_ASSERT(new_area in GLOB.sortedAreas, "addSorted must enroll the area in GLOB.sortedAreas")

	// force=TRUE so Destroy runs immediately AND the atom is removed from world — otherwise the
	// area lingers in `for(area in world)` and pollutes the parity test that runs after this one.
	qdel(new_area, force = TRUE)
	TEST_ASSERT(!(new_area in GLOB.all_areas), "Destroyed area must be removed from GLOB.all_areas")
	TEST_ASSERT(!(new_area in GLOB.sortedAreas), "Destroyed area must be removed from GLOB.sortedAreas")
	TEST_ASSERT_EQUAL(GLOB.all_areas.len, initial, "GLOB.all_areas must return to initial length after qdel")

/// Side-by-side benchmark: repopulate_sorted_areas() through the GLOB list vs the
/// pre-fix `for(var/area/A in world)`. Measures the same filter-and-collect work
/// to make the comparison honest.
/datum/unit_test/repopulate_sorted_areas_glob_vs_world_walk_benchmark
	priority = TEST_LONGER

/datum/unit_test/repopulate_sorted_areas_glob_vs_world_walk_benchmark/Run()
	TEST_ASSERT_NOTNULL(GLOB.all_areas, "GLOB.all_areas must be initialized")

	var/iterations = 20

	// === GLOB-based scan (production path after fix) ===
	var/t_glob = TICK_USAGE_REAL
	for(var/iter in 1 to iterations)
		var/list/collected = list()
		for(var/area/A as anything in GLOB.all_areas)
			collected += A
	var/glob_total_ms = TICK_USAGE_TO_MS(t_glob)
	var/glob_per_call_ms = glob_total_ms / iterations

	// === world-walk scan (pre-fix path) ===
	var/t_world = TICK_USAGE_REAL
	for(var/iter in 1 to iterations)
		var/list/collected = list()
		for(var/area/A in world)
			collected += A
	var/world_total_ms = TICK_USAGE_TO_MS(t_world)
	var/world_per_call_ms = world_total_ms / iterations

	var/speedup = (glob_total_ms > 0.001) ? (world_total_ms / glob_total_ms) : 0

	log_test("  repopulate_sorted_areas collection benchmark ([iterations] iterations, [GLOB.all_areas.len] areas, world has many atoms):")
	log_test("    GLOB-based : total [round(glob_total_ms, 0.01)]ms, per call [round(glob_per_call_ms, 0.001)]ms")
	log_test("    world walk : total [round(world_total_ms, 0.01)]ms, per call [round(world_per_call_ms, 0.001)]ms")
	if(speedup > 0)
		log_test("    Speedup    : [round(speedup, 0.1)]x")

	// On the small CentCom test reservation there are only ~400 areas and `for in world` is fast,
	// so collection-only timings can be near parity. Only assert the speedup when the world walk
	// is large enough to make the comparison meaningful (real station load).
	if(world_total_ms > 20)
		TEST_ASSERT(glob_total_ms < world_total_ms, "GLOB-based scan ([round(glob_total_ms, 0.01)]ms) must be faster than world walk ([round(world_total_ms, 0.01)]ms) on non-trivial loads")
		TEST_ASSERT(speedup >= 2, "GLOB scan must be at least 2x faster than world walk on non-trivial loads (got [round(speedup, 0.1)]x)")

	// Production path: repopulate_sorted_areas must finish quickly relative to its old O(world) cost.
	var/t_prod = TICK_USAGE_REAL
	for(var/iter in 1 to iterations)
		repopulate_sorted_areas()
	var/prod_total_ms = TICK_USAGE_TO_MS(t_prod)
	log_test("    Production repopulate_sorted_areas(): total [round(prod_total_ms, 0.01)]ms, per call [round(prod_total_ms / iterations, 0.001)]ms (includes sortTim)")

/// Functional + benchmark for make_maint_all_access(): the proc must still set
/// emergency = TRUE on every maintenance airlock, and the dedicated maintenance
/// area list must match the old world-walk view.
/datum/unit_test/make_maint_all_access_via_glob
	priority = TEST_LONGER

/datum/unit_test/make_maint_all_access_via_glob/Run()
	TEST_ASSERT_NOTNULL(GLOB.all_areas, "GLOB.all_areas must be initialized")
	TEST_ASSERT_NOTNULL(GLOB.maintenance_areas, "GLOB.maintenance_areas must be initialized")

	var/list/from_world = list()
	for(var/area/maintenance/A in world)
		if(QDELETED(A))
			continue
		from_world += A

	TEST_ASSERT_EQUAL(GLOB.maintenance_areas.len, from_world.len, "GLOB.maintenance_areas must contain every live maintenance area (glob=[GLOB.maintenance_areas.len] world=[from_world.len])")
	for(var/area/maintenance/A as anything in from_world)
		TEST_ASSERT(A in GLOB.maintenance_areas, "Maintenance area [A] ([A.type]) is present in world walk but missing from GLOB.maintenance_areas")

	// Snapshot maintenance airlocks currently on the test map and their emergency state.
	var/list/maint_airlocks = list()
	var/list/baseline_emergency = list()
	for(var/area/maintenance/A as anything in GLOB.maintenance_areas)
		for(var/obj/machinery/door/airlock/D in A)
			maint_airlocks += D
			baseline_emergency["[REF(D)]"] = D.emergency

	// Functional check: run make_maint_all_access(), every maintenance airlock should now be emergency=TRUE.
	var/baseline_emergency_access = GLOB.emergency_access
	make_maint_all_access()
	TEST_ASSERT(GLOB.emergency_access, "GLOB.emergency_access flag must be set by make_maint_all_access()")
	var/missed = 0
	for(var/obj/machinery/door/airlock/D as anything in maint_airlocks)
		if(!D.emergency)
			missed++
	TEST_ASSERT_EQUAL(missed, 0, "make_maint_all_access() must flip every maintenance airlock to emergency=TRUE (missed [missed] of [maint_airlocks.len])")

	// Revoke and verify the inverse.
	revoke_maint_all_access()
	TEST_ASSERT(!GLOB.emergency_access, "GLOB.emergency_access flag must be cleared by revoke_maint_all_access()")
	var/still_emergency = 0
	for(var/obj/machinery/door/airlock/D as anything in maint_airlocks)
		if(D.emergency)
			still_emergency++
	TEST_ASSERT_EQUAL(still_emergency, 0, "revoke_maint_all_access() must clear emergency on every maintenance airlock ([still_emergency] still set)")

	// Restore prior state
	GLOB.emergency_access = baseline_emergency_access
	for(var/obj/machinery/door/airlock/D as anything in maint_airlocks)
		var/was = baseline_emergency["[REF(D)]"]
		if(was)
			D.emergency = TRUE
			D.update_icon(ALL, 0)

	// Benchmark: side-by-side. Both paths only collect areas (we don't want to redo airlock
	// state churn N times); the airlock loop nested inside is the same in both variants.
	var/iterations = 30

	var/t_glob = TICK_USAGE_REAL
	for(var/iter in 1 to iterations)
		var/list/areas = list()
		for(var/area/maintenance/A as anything in GLOB.maintenance_areas)
			areas += A
	var/glob_total_ms = TICK_USAGE_TO_MS(t_glob)

	var/t_world = TICK_USAGE_REAL
	for(var/iter in 1 to iterations)
		var/list/areas = list()
		for(var/area/maintenance/A in world)
			areas += A
	var/world_total_ms = TICK_USAGE_TO_MS(t_world)

	var/speedup = (glob_total_ms > 0.001) ? (world_total_ms / glob_total_ms) : 0
	log_test("  make_maint_all_access area collection ([iterations] iterations):")
	log_test("    GLOB-based : total [round(glob_total_ms, 0.01)]ms, per call [round(glob_total_ms / iterations, 0.001)]ms")
	log_test("    world walk : total [round(world_total_ms, 0.01)]ms, per call [round(world_total_ms / iterations, 0.001)]ms")
	if(speedup > 0)
		log_test("    Speedup    : [round(speedup, 0.1)]x")

	// Very small maps can complete both paths in single-digit microseconds, where scheduler
	// noise dominates the ratio. Only enforce the relative benchmark when the old path is
	// expensive enough to make the comparison meaningful.
	if(world_total_ms > 20)
		TEST_ASSERT(glob_total_ms < world_total_ms, "GLOB-based scan must be faster than world walk for maintenance areas")

/// Wormholes round event used to scan every floor turf in the world without a
/// CHECK_TICK, which freezes a tick on real stations. Verify the loop yields.
/datum/unit_test/wormholes_start_yields_tick/Run()
	var/source = read_source_file("code/modules/events/wormholes.dm")
	TEST_ASSERT(length(source) > 200, "wormholes.dm must be readable from the test working directory or parent checkout")

	// Locate the start() proc body — find header, copy until the next /datum/round_event/wormholes/ method.
	var/start = findtext(source, "/datum/round_event/wormholes/start()")
	TEST_ASSERT(start, "/datum/round_event/wormholes/start() must exist in wormholes.dm")
	var/end = findtext(source, "/datum/round_event/wormholes/", start + 30)
	if(!end)
		end = length(source) + 1
	var/body = copytext(source, start, end)

	// The collection loop (per-station-z block() walk since the perf fix) must contain a
	// CHECK_TICK (or stoplag) before the work that follows - otherwise on a real station
	// this freezes a tick.
	var/loop_pos = findtext(body, "for(var/turf/open/floor/T in block(")
	TEST_ASSERT(loop_pos, "wormholes.start() must still iterate floor turfs (test needs updating if the iterator changed)")
	var/loop_tail = copytext(body, loop_pos)
	TEST_ASSERT(findtext(loop_tail, "CHECK_TICK") || findtext(loop_tail, "stoplag"), "wormholes.start() floor-turf loop must contain CHECK_TICK or stoplag to avoid freezing a tick on full stations")
	TEST_ASSERT(!findtext(body, " in world)"), "wormholes.start() must not walk the whole world - collect turfs per station z-level")

// Synthetic area for the lifecycle test — needs no map placement, just a fresh allocation.
/area/test_area
	name = "Area Tracking Test Area"
	area_flags = NONE
	requires_power = FALSE
