// ===== Sleeping edges: осевшие одногрупповые пары пропускают compare/share =====
//
// Идея ZAS (Nebula ConnectionGroup): выровнявшееся ребро засыпает и не платит
// даже compare(), пока ревизии смесей обоих концов не изменились. Контракт
// инвалидации: каждый мутатор gas_mixture бампает mutation_rev, пересчёт
// соседства (ImmediateCalculateAdjacentTurfs) сбрасывает кэши пары. Фича за
// флагом SSair.sleeping_edges_enabled (конфиг atmos_sleeping_edges, дефолт ON).

/datum/unit_test/atmos_sleeping_edges
	priority = TEST_LONGER

/datum/unit_test/atmos_sleeping_edges/proc/build_pair_arena(turf/base, width)
	for(var/dx in 0 to width)
		for(var/dy in 0 to 2)
			var/turf/T = locate(base.x + dx, base.y + dy, base.z)
			TEST_ASSERT_NOTNULL(T, "test zone turf missing at offset [dx],[dy]")
			if(dx == 0 || dy == 0 || dx == width || dy == 2)
				T.ChangeTurf(/turf/closed/wall)

/datum/unit_test/atmos_sleeping_edges/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/saved_flag = SSair.sleeping_edges_enabled

	// Карман 4x3: внутри ровно пара открытых тайлов A-B.
	var/turf/base = run_loc_floor_bottom_left
	build_pair_arena(base, 3)
	var/turf/open/tile_a = locate(base.x + 1, base.y + 1, base.z)
	var/turf/open/tile_b = locate(base.x + 2, base.y + 1, base.z)
	TEST_ASSERT(istype(tile_a) && istype(tile_b), "arena pair is not open turfs")
	tile_a.ImmediateCalculateAdjacentTurfs()
	tile_b.ImmediateCalculateAdjacentTurfs()
	TEST_ASSERT(tile_b in tile_a.atmos_adjacent_turfs, "pair must be atmos-adjacent")

	// Одинаковый воздух с обеих сторон и общая excited group.
	tile_a.air.copy_from_turf(tile_a)
	tile_b.air.copy_from_turf(tile_b)
	var/datum/excited_group/pair_group = new
	pair_group.add_turf(tile_a)
	pair_group.add_turf(tile_b)
	SSair.add_to_active(tile_a, FALSE)
	SSair.add_to_active(tile_b, FALSE)

	SSair.sleeping_edges_enabled = TRUE
	var/fire = max(tile_a.current_cycle, tile_b.current_cycle, SSair.times_fired) + 100

	// Кэш гейтится тишиной турфа: активный фронт не платит лукап вовсе.
	// Изображаем турф, который уже отмолчал свой порог.
	tile_a.atmos_cooldown = ATMOS_EDGE_SLEEP_MIN_QUIET_FIRES

	// Первый цикл: compare() говорит "разницы нет", ребро засыпает.
	tile_a.process_cell(fire)
	var/list/edge_state = tile_a.settled_edge_revs?[tile_b]
	TEST_ASSERT_NOTNULL(edge_state, "settled pair must cache both mutation revisions")
	TEST_ASSERT_EQUAL(edge_state[1], tile_a.air.mutation_rev, "cached self revision must match the mixture")
	TEST_ASSERT_EQUAL(edge_state[2], tile_b.air.mutation_rev, "cached enemy revision must match the mixture")

	// Доказательство скипа: разница, созданная ПРЯМОЙ записью в список (мимо
	// мутаторов, ревизия не бампается), для спящего ребра невидима - шер не
	// бежит. Так в бою не бывает (прямых записей в кодбазе нет), но именно это
	// отличает "пару скипнули" от "compare увидел равенство".
	var/o2_before = tile_a.air.get_moles(GAS_O2)
	tile_b.air.gases[GAS_O2] += 30
	tile_a.atmos_cooldown = ATMOS_EDGE_SLEEP_MIN_QUIET_FIRES
	fire++
	tile_a.process_cell(fire)
	TEST_ASSERT(abs(tile_a.air.get_moles(GAS_O2) - o2_before) < 0.001, \
		"sleeping edge must skip the pair entirely while revisions are unchanged")

	// Пробуждение по ревизии: бамп на любом конце снимает сон, разница
	// разъезжается обычным share() в тот же фаер.
	tile_b.air.mutation_rev++
	tile_a.atmos_cooldown = ATMOS_EDGE_SLEEP_MIN_QUIET_FIRES
	fire++
	tile_a.process_cell(fire)
	TEST_ASSERT(tile_a.air.get_moles(GAS_O2) > o2_before + 1, \
		"a revision bump must wake the edge and let the pair share (moved [tile_a.air.get_moles(GAS_O2) - o2_before] mol)")

	// Пересчёт соседства сбрасывает кэш целиком. Пару принудительно выравниваем
	// (copy_from_turf бампает ревизии сам), одним циклом даём ей снова осесть.
	tile_a.air.copy_from_turf(tile_a)
	tile_b.air.copy_from_turf(tile_b)
	tile_a.atmos_cooldown = ATMOS_EDGE_SLEEP_MIN_QUIET_FIRES
	fire++
	tile_a.process_cell(fire)
	TEST_ASSERT_NOTNULL(tile_a.settled_edge_revs?[tile_b], "re-settled pair must be cached again")
	tile_a.ImmediateCalculateAdjacentTurfs()
	TEST_ASSERT_NULL(tile_a.settled_edge_revs, "adjacency recalculation must drop the settled-edge cache")

	// С выключенным флагом кэш не создаётся вовсе.
	SSair.sleeping_edges_enabled = FALSE
	fire++
	tile_a.process_cell(fire)
	TEST_ASSERT_NULL(tile_a.settled_edge_revs, "the cache must stay empty with the feature flag off")

	// Cleanup.
	SSair.sleeping_edges_enabled = saved_flag
	tile_a.air.copy_from_turf(tile_a)
	tile_b.air.copy_from_turf(tile_b)
	if(tile_a.excited_group)
		tile_a.excited_group.dismantle()
	SSair.remove_from_active(tile_a)
	SSair.remove_from_active(tile_b)

/// Микробенч пары: осевшая комната с флагом и без, чередованием (A/B/A/B).
/// Ассерты только на корректность (газ не дрейфует), тайминги - в log_test.
/datum/unit_test/atmos_sleeping_edges_benchmark
	priority = TEST_LONGER

/datum/unit_test/atmos_sleeping_edges_benchmark/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/saved_flag = SSair.sleeping_edges_enabled

	// Осевшая комната 3x3 в одной группе. Резервация тестов - 5x5, дальше
	// четырёх тайлов от угла уже космос, а с full-dump вентом любая щель в
	// периметре высасывает арену за один цикл.
	var/turf/base = run_loc_floor_bottom_left
	for(var/dx in 0 to 4)
		for(var/dy in 0 to 4)
			var/turf/T = locate(base.x + dx, base.y + dy, base.z)
			TEST_ASSERT_NOTNULL(T, "bench zone turf missing at offset [dx],[dy]")
			if(dx == 0 || dy == 0 || dx == 4 || dy == 4)
				T.ChangeTurf(/turf/closed/wall)
	var/list/turf/open/room = list()
	var/datum/excited_group/bench_group = new
	for(var/dx in 1 to 3)
		for(var/dy in 1 to 3)
			var/turf/open/T = locate(base.x + dx, base.y + dy, base.z)
			TEST_ASSERT(istype(T), "bench tile is not open at offset [dx],[dy]")
			T.ImmediateCalculateAdjacentTurfs()
			T.air.copy_from_turf(T)
			bench_group.add_turf(T)
			SSair.add_to_active(T, FALSE)
			room += T

	var/moles_before = 0
	for(var/turf/open/T as anything in room)
		moles_before += T.air.total_moles()

	var/cycles = 400
	var/fire = max(SSair.times_fired, 10000) + 500
	var/off_ms = 0
	var/on_ms = 0
	for(var/ab_round in 1 to 2)
		SSair.sleeping_edges_enabled = FALSE
		var/t1 = TICK_USAGE_REAL
		for(var/cycle in 1 to cycles)
			fire++
			for(var/turf/open/T as anything in room)
				T.process_cell(fire)
		off_ms += TICK_USAGE_TO_MS(t1)
		SSair.sleeping_edges_enabled = TRUE
		t1 = TICK_USAGE_REAL
		for(var/cycle in 1 to cycles)
			fire++
			for(var/turf/open/T as anything in room)
				T.process_cell(fire)
		on_ms += TICK_USAGE_TO_MS(t1)
	var/turf_cycles = cycles * 2 * length(room)
	log_test("  ATMOSBENCH settled_room_flag_off: [turf_cycles] turf-cycles in [round(off_ms, 0.01)]ms ([round(off_ms * 1000 / turf_cycles, 0.01)]us/turf-cycle)")
	log_test("  ATMOSBENCH settled_room_flag_on:  [turf_cycles] turf-cycles in [round(on_ms, 0.01)]ms ([round(on_ms * 1000 / turf_cycles, 0.01)]us/turf-cycle)")

	// Корректность: осевшая комната не дрейфует ни по молям, ни по составу.
	var/moles_after = 0
	for(var/turf/open/T as anything in room)
		moles_after += T.air.total_moles()
	TEST_ASSERT(abs(moles_before - moles_after) < moles_before * 0.001, \
		"settled room drifted under sleeping edges: [moles_before] -> [moles_after] mol")

	// Cleanup.
	SSair.sleeping_edges_enabled = saved_flag
	for(var/turf/open/T as anything in room)
		T.air.copy_from_turf(T)
		SSair.remove_from_active(T)
	if(bench_group && !QDELETED(bench_group))
		bench_group.dismantle()
