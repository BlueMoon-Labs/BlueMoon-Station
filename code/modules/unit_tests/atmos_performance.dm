// Benchmarks and conservation checks for the native DM atmospherics hot paths.
// Timing results are logged via log_test for before/after comparison of
// optimization work; assertions only cover correctness (conservation,
// convergence), never wall-clock time, to stay CI-stable.

/// Builds a standard station air mixture (o2/n2 at T20C) in a fresh gas_mixture.
/proc/unit_test_air_mix(volume = CELL_VOLUME)
	var/datum/gas_mixture/mix = new(volume)
	mix.set_moles(GAS_O2, MOLES_O2STANDARD)
	mix.set_moles(GAS_N2, MOLES_N2STANDARD)
	mix.set_temperature(T20C)
	return mix

///Repeated fire lines crossing one turf must reuse its active hotspot instead
///of leaving the previous effect orphaned in SSair.hotspots.
/datum/unit_test/hotspot_ensure_reuses_active/Run()
	var/turf/open/test_turf = run_loc_floor_bottom_left
	if(test_turf.active_hotspot)
		qdel(test_turf.active_hotspot)
	var/hotspots_before = length(SSair.hotspots)

	var/obj/effect/hotspot/first = test_turf.ensure_hotspot()
	var/obj/effect/hotspot/second = test_turf.ensure_hotspot()

	TEST_ASSERT_NOTNULL(first, "ensure_hotspot() must create a hotspot on an open turf")
	TEST_ASSERT_EQUAL(second, first, "A second fire exposure must reuse the turf's active hotspot")
	TEST_ASSERT_EQUAL(test_turf.active_hotspot, first, "The reused hotspot must remain the turf's active owner")
	TEST_ASSERT_EQUAL(length(SSair.hotspots), hotspots_before + 1, "Reusing a hotspot must add exactly one SSair processing entry")
	qdel(first)

/datum/unit_test/atmos_hot_proc_benchmark
	priority = TEST_LONGER

/datum/unit_test/atmos_hot_proc_benchmark/proc/bench_line(name, iterations, time_ms)
	log_test("  ATMOSBENCH [name]: [iterations] iters in [round(time_ms, 0.01)]ms ([round(time_ms * 1000 / iterations, 0.01)]us/op)")

/datum/unit_test/atmos_hot_proc_benchmark/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")

	// --- gas list reductions: native BYOND 516 vs the DM loop they replaced ---
	// Measured here rather than in the world benchmark on purpose. A full
	// headless A/B on the sustained-leak arena could not separate this change
	// from its own noise floor (3 interleaved pairs, every slot inside +-10%),
	// which is the correct answer to "does it move the phase" and no answer at
	// all to "is the reduction faster". This is the unit the change actually
	// touches, so this is where it gets a verdict.
	//
	// The memoised procs are deliberately bypassed: total_moles() caches on
	// mutation_rev and would time the guard, not the reduction (the same trap the
	// archive line below fell into). Rounds alternate A,B,A,B so a warmed list
	// cache cannot hand the second contestant a free win.
	var/datum/gas_mixture/reduction_src = unit_test_air_mix()
	reduction_src.set_moles(GAS_CO2, 0.37)
	var/list/reduction_gases = reduction_src.gases
	var/list/reduction_heats = GLOB.gas_data.specific_heats
	var/iterations = 20000
	var/sum_native_ms = 0
	var/sum_loop_ms = 0
	var/dot_native_ms = 0
	var/dot_loop_ms = 0
	var/reduction_sink = 0
	var/t1
	for(var/ab_round in 1 to 2)
		t1 = TICK_USAGE_REAL
		for(var/i in 1 to iterations)
			reduction_sink += values_sum(reduction_gases)
		sum_native_ms += TICK_USAGE_TO_MS(t1)
		t1 = TICK_USAGE_REAL
		for(var/i in 1 to iterations)
			var/sum = 0
			for(var/id, gas_moles in reduction_gases)
				sum += gas_moles
			reduction_sink += sum
		sum_loop_ms += TICK_USAGE_TO_MS(t1)
		t1 = TICK_USAGE_REAL
		for(var/i in 1 to iterations)
			reduction_sink += values_dot(reduction_gases, reduction_heats)
		dot_native_ms += TICK_USAGE_TO_MS(t1)
		t1 = TICK_USAGE_REAL
		for(var/i in 1 to iterations)
			var/capacity = 0
			for(var/id, gas_moles in reduction_gases)
				capacity += (gas_moles || 0) * (reduction_heats[id] || 0)
			reduction_sink += capacity
		dot_loop_ms += TICK_USAGE_TO_MS(t1)
	bench_line("sum_native", iterations * 2, sum_native_ms)
	bench_line("sum_loop", iterations * 2, sum_loop_ms)
	bench_line("dot_native", iterations * 2, dot_native_ms)
	bench_line("dot_loop", iterations * 2, dot_loop_ms)
	TEST_ASSERT(reduction_sink > 0, "the reduction benchmark must not be optimised away into nothing")
	qdel(reduction_src)

	// --- archive(): the two cases have to be timed apart ---
	// archive() skips its gases.Copy() when the mixture has not been touched
	// since the last snapshot (archive_mutation_rev == mutation_rev). Looping it
	// on an untouched mixture therefore measures the guard, not the archive: the
	// first iteration copies and the other 19999 return immediately. Reported as
	// one number that read as a twentyfold speedup against older runs, which is
	// exactly backwards - the guard is free, the archive it skips is not.
	var/datum/gas_mixture/archiver = unit_test_air_mix()
	iterations = 20000
	t1 = TICK_USAGE_REAL
	for(var/i in 1 to iterations)
		archiver.archive()
	bench_line("archive_memo_hit", iterations, TICK_USAGE_TO_MS(t1))

	// Dirty the mixture between snapshots so every iteration takes the copy.
	// set_temperature bumps mutation_rev without changing the gas list, which is
	// the cheapest way to invalidate; the write itself is one field assignment
	// and is charged to both this line and the hit line above equally.
	var/temperature_toggle = T20C
	t1 = TICK_USAGE_REAL
	for(var/i in 1 to iterations)
		temperature_toggle = (temperature_toggle == T20C) ? (T20C + 1) : T20C
		archiver.set_temperature(temperature_toggle)
		archiver.archive()
	bench_line("archive_memo_miss", iterations, TICK_USAGE_TO_MS(t1))

	// --- archive strategies A/B: fresh gases.Copy() vs reused list (Cut + refill) ---
	// Прогоны чередуются (A,B,A,B): подряд идущий второй вариант выигрывал бы на
	// прогретых кешах списков (см. историю с 19% -> 2.3% на atmos-бенчах).
	var/datum/gas_mixture/arch_src = unit_test_air_mix()
	arch_src.set_moles(GAS_CO2, 0.4) // третий ключ, чтобы не мерить вырожденный случай
	var/list/reused_archive = list()
	var/list/fresh_archive
	var/archive_copy_ms = 0
	var/archive_reuse_ms = 0
	iterations = 20000
	for(var/ab_round in 1 to 2)
		t1 = TICK_USAGE_REAL
		for(var/i in 1 to iterations)
			fresh_archive = arch_src.gases.Copy()
		archive_copy_ms += TICK_USAGE_TO_MS(t1)
		t1 = TICK_USAGE_REAL
		for(var/i in 1 to iterations)
			reused_archive.Cut()
			for(var/id, amount in arch_src.gases)
				reused_archive[id] = amount
		archive_reuse_ms += TICK_USAGE_TO_MS(t1)
	bench_line("archive_copy", iterations * 2, archive_copy_ms)
	bench_line("archive_reuse", iterations * 2, archive_reuse_ms)
	TEST_ASSERT_EQUAL(length(fresh_archive), length(reused_archive), "оба варианта архива обязаны снять одинаковый набор газов")
	qdel(arch_src)

	// --- share() steady state (both sides identical, nothing moves) ---
	var/datum/gas_mixture/settled_a = unit_test_air_mix()
	var/datum/gas_mixture/settled_b = unit_test_air_mix()
	settled_a.archive()
	settled_b.archive()
	iterations = 20000
	t1 = TICK_USAGE_REAL
	for(var/i in 1 to iterations)
		settled_a.share(settled_b, 0.2, 0.2)
	bench_line("share_settled", iterations, TICK_USAGE_TO_MS(t1))

	// --- share() steady state с трейс-ключом: быстрый путь потерян ---
	// Быстрый путь share() требует ровно двух ключей во ВСЕХ четырёх списках -
	// своих газах, чужих газах и обоих архивах, - поэтому один подпороговый хвост
	// (ровно тот, что оставляет за собой реакция пара) выбивает пару на общий путь
	// до конца раунда. Разница между этой строкой и share_settled и есть цена
	// потери, на которую опирается вся тема с чисткой трейс-газов; до сих пор её
	// никто не измерял, и утверждение "лишний ключ дорого стоит в share()" было
	// гипотезой без числа. Обе стороны держат ОДИНАКОВЫЙ хвост: дельта по нему
	// нулевая, вещество не движется, то есть меряется ровно потеря быстрого пути.
	var/datum/gas_mixture/traced_a = unit_test_air_mix()
	var/datum/gas_mixture/traced_b = unit_test_air_mix()
	traced_a.set_moles(GAS_H2O, 0.05)
	traced_b.set_moles(GAS_H2O, 0.05)
	traced_a.archive()
	traced_b.archive()
	t1 = TICK_USAGE_REAL
	for(var/i in 1 to iterations)
		traced_a.share(traced_b, 0.2, 0.2)
	bench_line("share_settled_traces", iterations, TICK_USAGE_TO_MS(t1))
	qdel(traced_a)
	qdel(traced_b)

	// --- share() active (pressure delta, gas actually moves) ---
	// Pairs are pre-seeded so the timer covers share() only.
	var/pair_count = 4000
	var/list/side_a = list()
	var/list/side_b = list()
	for(var/i in 1 to pair_count)
		var/datum/gas_mixture/A = unit_test_air_mix()
		A.set_moles(GAS_O2, MOLES_O2STANDARD * 3)
		A.set_moles(GAS_PLASMA, 5)
		A.archive()
		side_a += A
		var/datum/gas_mixture/B = unit_test_air_mix()
		B.set_temperature(T20C + 60)
		B.archive()
		side_b += B
	t1 = TICK_USAGE_REAL
	for(var/i in 1 to pair_count)
		var/datum/gas_mixture/A = side_a[i]
		A.share(side_b[i], 0.2, 0.2)
	bench_line("share_active", pair_count, TICK_USAGE_TO_MS(t1))

	// Conservation check on one representative pair
	var/datum/gas_mixture/cons_a = unit_test_air_mix()
	cons_a.set_moles(GAS_O2, MOLES_O2STANDARD * 3)
	var/datum/gas_mixture/cons_b = unit_test_air_mix()
	var/total_before = cons_a.total_moles() + cons_b.total_moles()
	var/energy_before = cons_a.thermal_energy() + cons_b.thermal_energy()
	cons_a.archive()
	cons_b.archive()
	cons_a.share(cons_b, 0.25, 0.25)
	var/total_after = cons_a.total_moles() + cons_b.total_moles()
	var/energy_after = cons_a.thermal_energy() + cons_b.thermal_energy()
	TEST_ASSERT(abs(total_before - total_after) < 0.01, "share() lost moles: [total_before] -> [total_after]")
	TEST_ASSERT(abs(energy_before - energy_after) < energy_before * 0.001, "share() lost energy: [energy_before] -> [energy_after]")

	// --- compare() equal and unequal ---
	var/datum/gas_mixture/cmp_a = unit_test_air_mix()
	var/datum/gas_mixture/cmp_b = unit_test_air_mix()
	iterations = 40000
	t1 = TICK_USAGE_REAL
	for(var/i in 1 to iterations)
		cmp_a.compare(cmp_b)
	bench_line("compare_equal", iterations, TICK_USAGE_TO_MS(t1))
	TEST_ASSERT_EQUAL(cmp_a.compare(cmp_b), "", "compare() of identical mixes should be empty string")

	cmp_b.set_moles(GAS_PLASMA, 10)
	t1 = TICK_USAGE_REAL
	for(var/i in 1 to iterations)
		cmp_a.compare(cmp_b)
	bench_line("compare_unequal", iterations, TICK_USAGE_TO_MS(t1))
	TEST_ASSERT_EQUAL(cmp_a.compare(cmp_b), GAS_PLASMA, "compare() should report the differing gas id")

	// --- react() on inert station air (the overwhelmingly common case) ---
	var/datum/gas_mixture/inert = unit_test_air_mix()
	iterations = 20000
	t1 = TICK_USAGE_REAL
	for(var/i in 1 to iterations)
		inert.react(null)
	bench_line("react_inert", iterations, TICK_USAGE_TO_MS(t1))
	TEST_ASSERT_EQUAL(inert.react(null), NO_REACTION, "station air must not react")

	// react() on inert air with several trace gases present
	var/datum/gas_mixture/traces = unit_test_air_mix()
	traces.set_moles(GAS_CO2, 4)
	traces.set_moles(GAS_H2O, 0.05)
	traces.set_moles(GAS_NITROUS, 0.1)
	t1 = TICK_USAGE_REAL
	for(var/i in 1 to iterations)
		traces.react(null)
	bench_line("react_traces", iterations, TICK_USAGE_TO_MS(t1))

	// --- гейт по порогу требований: A/B внутри ОДНОГО прогона ---
	// Гейт снимается обнулением индекса полов, поэтому обе стороны меряются на
	// одной сборке, одной смеси и одном прогретом кэше: build-to-build разброс,
	// который на этом стенде и есть главный источник шума, из измерения уходит
	// целиком. Смесь та же, что у react_traces выше: CO2 бакетом не владеет, а
	// H2O и N2O лежат ниже порогов своих реакций - то есть кандидатов ноль в
	// обоих случаях, и разница это ровно цена их сборки и разбора.
	// Индекс мог остаться снятым от упавшего соседа по файлу: пересобираем его
	// перед замером, иначе обе стороны A/B померяют одно и то же.
	SSair.auxtools_update_reactions()
	var/list/saved_floor = SSair.reactions_key_gas_floor
	TEST_ASSERT_NOTNULL(saved_floor, "индекс полов не построен - A/B гейта померял бы обе стороны без гейта")
	var/datum/gas_mixture/gate_mix = unit_test_air_mix()
	gate_mix.set_moles(GAS_CO2, 4)
	gate_mix.set_moles(GAS_H2O, 0.05)
	gate_mix.set_moles(GAS_NITROUS, 0.1)
	// Прогревочный прогон отбрасывается: первый проход систематически медленнее
	// остальных, и без этого его перекос садится на ту сторону, которая шла первой.
	for(var/i in 1 to iterations)
		gate_mix.react(null)
	var/gate_on_ms = 0
	var/gate_off_ms = 0
	// Снятый на время замера индекс возвращается и по исключению: рантайм внутри
	// react() рвёт стек до самого RunUnitTest, и оставленный null уехал бы в
	// соседние тесты как молчаливое отключение гейта.
	try
		for(var/gate_round in 1 to 4)
			// ABBA: порядок внутри пары переворачивается, иначе одна сторона всегда
			// стоит второй и получает чужой прогрев как подарок.
			var/gated_first = (gate_round == 1 || gate_round == 4)
			for(var/leg in 1 to 2)
				var/measure_gated = ((leg == 1) == gated_first)
				SSair.reactions_key_gas_floor = measure_gated ? saved_floor : null
				t1 = TICK_USAGE_REAL
				for(var/i in 1 to iterations)
					gate_mix.react(null)
				if(measure_gated)
					gate_on_ms += TICK_USAGE_TO_MS(t1)
				else
					gate_off_ms += TICK_USAGE_TO_MS(t1)
	catch(var/exception/gate_error)
		SSair.reactions_key_gas_floor = saved_floor
		throw gate_error
	SSair.reactions_key_gas_floor = saved_floor
	qdel(gate_mix)
	bench_line("react_gate_on", iterations * 4, gate_on_ms)
	bench_line("react_gate_off", iterations * 4, gate_off_ms)

	// --- transfer_to() ping-pong ---
	var/datum/gas_mixture/from = unit_test_air_mix()
	var/datum/gas_mixture/into = unit_test_air_mix()
	iterations = 20000
	t1 = TICK_USAGE_REAL
	for(var/i in 1 to iterations)
		from.transfer_to(into, 1)
		into.transfer_to(from, 1)
	bench_line("transfer_to_pingpong", iterations * 2, TICK_USAGE_TO_MS(t1))
	TEST_ASSERT(abs(from.total_moles() + into.total_moles() - 2 * (MOLES_O2STANDARD + MOLES_N2STANDARD)) < 0.01, "transfer_to ping-pong lost moles")

	// --- scrub_into() with nothing filterable (idle scrubber over a clean room) ---
	var/datum/gas_mixture/clean_room = unit_test_air_mix()
	var/datum/gas_mixture/scrubber_pipe = new(200)
	scrubber_pipe.set_temperature(T20C)
	var/list/filter_ids = list(GAS_CO2, GAS_MIASMA, GAS_METHANE)
	iterations = 20000
	t1 = TICK_USAGE_REAL
	for(var/i in 1 to iterations)
		clean_room.scrub_into(scrubber_pipe, 200 / CELL_VOLUME, filter_ids)
	bench_line("scrub_clean_room", iterations, TICK_USAGE_TO_MS(t1))
	TEST_ASSERT(scrubber_pipe.total_moles() < 0.01, "scrubbing a clean room must move no gas")

	// --- scrub_into() with CO2 present (occupied room), refilled each iteration ---
	iterations = 10000
	t1 = TICK_USAGE_REAL
	for(var/i in 1 to iterations)
		clean_room.set_moles(GAS_CO2, 2)
		clean_room.scrub_into(scrubber_pipe, 200 / CELL_VOLUME, filter_ids)
	bench_line("scrub_co2_room", iterations, TICK_USAGE_TO_MS(t1))
	TEST_ASSERT(scrubber_pipe.get_moles(GAS_CO2) > 100, "scrubber should have collected CO2")

	// --- planetary turf template path: what process_cell does per planetary turf ---
	var/turf/model_turf = run_loc_floor_bottom_left
	var/datum/gas_mixture/planet_air = unit_test_air_mix()
	planet_air.archive()
	iterations = 4000
	t1 = TICK_USAGE_REAL
	for(var/i in 1 to iterations)
		var/datum/gas_mixture/G = new
		G.copy_from_turf(model_turf)
		G.archive()
		if(planet_air.compare(G))
			planet_air.share(G, 0.2, 0.2)
		qdel(G)
	bench_line("planetary_share_old_path", iterations, TICK_USAGE_TO_MS(t1))

	// --- planetary turf template path: what process_cell does now ---
	var/datum/gas_mixture/template_planet_air = unit_test_air_mix()
	template_planet_air.archive()
	var/datum/gas_mixture/planet_template = SSair.get_planetary_template(model_turf)
	t1 = TICK_USAGE_REAL
	for(var/i in 1 to iterations)
		if(template_planet_air.compare(planet_template))
			template_planet_air.share_with_template(planet_template, 0.2)
	bench_line("planetary_share_template_path", iterations, TICK_USAGE_TO_MS(t1))
	qdel(template_planet_air)

	// --- pipenet equalize ---
	var/list/pipenet_mixes = list()
	for(var/i in 1 to 20)
		var/datum/gas_mixture/M = new(70)
		M.set_moles(GAS_O2, i)
		M.set_moles(GAS_N2, 20 - i * 0.5)
		M.set_temperature(T20C + i)
		pipenet_mixes += M
	var/net_before = 0
	for(var/datum/gas_mixture/M as anything in pipenet_mixes)
		net_before += M.total_moles()
	iterations = 3000
	t1 = TICK_USAGE_REAL
	for(var/i in 1 to iterations)
		equalize_all_gases_in_list(pipenet_mixes)
	bench_line("equalize_pipenet_20", iterations, TICK_USAGE_TO_MS(t1))
	var/net_after = 0
	for(var/datum/gas_mixture/M as anything in pipenet_mixes)
		net_after += M.total_moles()
	TEST_ASSERT(abs(net_before - net_after) < 0.05, "equalize_all_gases_in_list lost moles: [net_before] -> [net_after]")
	var/datum/gas_mixture/eq_first = pipenet_mixes[1]
	var/datum/gas_mixture/eq_last = pipenet_mixes[20]
	TEST_ASSERT(abs(eq_first.return_pressure() - eq_last.return_pressure()) < 1, "equalize_all_gases_in_list did not equalize pressures")

	// --- update_visuals() on a live turf ---
	var/turf/open/vis_turf = run_loc_floor_bottom_left
	iterations = 20000
	t1 = TICK_USAGE_REAL
	for(var/i in 1 to iterations)
		vis_turf.update_visuals()
	bench_line("update_visuals_invisible", iterations, TICK_USAGE_TO_MS(t1))

	qdel(archiver)
	qdel(settled_a)
	qdel(settled_b)
	for(var/datum/gas_mixture/M as anything in side_a + side_b + pipenet_mixes)
		qdel(M)
	qdel(cons_a)
	qdel(cons_b)
	qdel(cmp_a)
	qdel(cmp_b)
	qdel(inert)
	qdel(traces)
	qdel(from)
	qdel(into)
	qdel(clean_room)
	qdel(scrubber_pipe)

/// Full process_cell loop over a sealed 3x3 room with a pressure imbalance:
/// measures per-cycle cost and verifies gases equalize and conserve.
/datum/unit_test/atmos_process_cell_grid
	priority = TEST_LONGER

/datum/unit_test/atmos_process_cell_grid/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")

	var/turf/base = run_loc_floor_bottom_left

	// Wall off the 5x5 perimeter so the inner 3x3 room is sealed.
	for(var/dx in 0 to 4)
		for(var/dy in 0 to 4)
			var/turf/T = locate(base.x + dx, base.y + dy, base.z)
			TEST_ASSERT_NOTNULL(T, "test zone turf missing at offset [dx],[dy]")
			if(dx == 0 || dy == 0 || dx == 4 || dy == 4)
				T.ChangeTurf(/turf/closed/wall)

	var/list/turf/open/room = list()
	for(var/dx in 1 to 3)
		for(var/dy in 1 to 3)
			var/turf/open/T = locate(base.x + dx, base.y + dy, base.z)
			TEST_ASSERT(istype(T), "inner room turf is not open at offset [dx],[dy]")
			T.ImmediateCalculateAdjacentTurfs()
			room += T

	// Seed an imbalance: center turf heavily pressurized and hot.
	var/turf/open/center = locate(base.x + 2, base.y + 2, base.z)
	center.air.set_moles(GAS_O2, MOLES_O2STANDARD * 8)
	center.air.set_temperature(T20C + 100)

	var/moles_before = 0
	for(var/turf/open/T as anything in room)
		moles_before += T.air.total_moles()
		SSair.add_to_active(T, FALSE)

	var/cycles = 60
	var/fire_base = SSair.times_fired + 1000
	var/t1 = TICK_USAGE_REAL
	for(var/cycle in 1 to cycles)
		for(var/turf/open/T as anything in room)
			T.process_cell(fire_base + cycle)
	var/grid_ms = TICK_USAGE_TO_MS(t1)
	log_test("  ATMOSBENCH process_cell_3x3: [cycles] cycles in [round(grid_ms, 0.01)]ms ([round(grid_ms * 1000 / (cycles * 9), 0.01)]us/turf-cycle)")

	var/moles_after = 0
	var/pressure_min = INFINITY
	var/pressure_max = 0
	for(var/turf/open/T as anything in room)
		moles_after += T.air.total_moles()
		var/p = T.air.return_pressure()
		pressure_min = min(pressure_min, p)
		pressure_max = max(pressure_max, p)

	TEST_ASSERT(abs(moles_before - moles_after) < moles_before * 0.001, "sealed room lost gas: [moles_before] -> [moles_after]")
	TEST_ASSERT(pressure_max - pressure_min < pressure_max * 0.25, "room failed to trend toward equalization: min [pressure_min], max [pressure_max]")

	// Cleanup: reset room to standard air and deactivate.
	for(var/turf/open/T as anything in room)
		T.air.copy_from_turf(T)
		SSair.remove_from_active(T)

// Измеряет только проверку локализации: построение карты и работа физики исключены.
// Порогов по времени нет: CI проверяет результат, а длительности сохраняет для анализа.
/datum/unit_test/decompression_containment_benchmark
	priority = TEST_LONGER
	var/datum/turf_reservation/arena
	var/area/original_area
	var/list/benchmark_areas = list()
	var/list/benchmark_doors = list()
	var/list/room = list()
	var/list/sources = list()
	var/list/results = list()
	var/saved_can_fire
	var/has_saved_state = FALSE
	var/origin_x
	var/origin_y
	var/origin_z

/obj/machinery/door/firedoor/window/containment_benchmark
	var/close_check_count = 0

/obj/machinery/door/firedoor/window/containment_benchmark/can_close_for_alarm()
	close_check_count++
	return ..()

/datum/unit_test/decompression_containment_benchmark/proc/prepare_room(size, area_count = 1)
	QDEL_LIST(benchmark_doors)
	for(var/turf/member as anything in arena.reserved_turfs)
		original_area.contents += member
	QDEL_LIST(benchmark_areas)
	room.Cut()
	sources.Cut()
	for(var/index in 1 to area_count)
		var/area/unit_test_decompression/part = new
		benchmark_areas += part
	for(var/turf/member as anything in arena.reserved_turfs)
		var/dx = member.x - origin_x
		var/dy = member.y - origin_y
		if(dx >= 0 && dx < size && dy >= 0 && dy < size)
			var/turf/open/floor = member.ChangeTurf(/turf/open/floor/plasteel)
			var/area/part = benchmark_areas[min(area_count, round(dx * area_count / size) + 1)]
			part.contents += floor
			floor.air.copy_from_turf(floor)
			SSair.remove_from_active(floor)
			room += floor
		else
			member.ChangeTurf(/turf/closed/wall)
		CHECK_TICK
	for(var/index in 1 to area_count)
		var/turf/open/source = locate(origin_x + round((index - 1) * size / area_count), origin_y, origin_z)
		var/area/part = get_base_area(source)
		sources[part] = list(source)
		var/turf/hole = get_step(source, SOUTH)
		hole.ChangeTurf(/turf/open/space/basic)
	refresh_adjacency()

/datum/unit_test/decompression_containment_benchmark/proc/refresh_adjacency()
	for(var/turf/open/member as anything in room)
		member.ImmediateCalculateAdjacentTurfs()
		CHECK_TICK

// Герметизация между срезами должна отменять старый обход, а новая пробоина — старый кэш.
/datum/unit_test/decompression_containment_benchmark/proc/check_resumption()
	prepare_room(16)
	var/area/base = benchmark_areas[1]
	var/turf/open/source = sources[base][1]
	var/datum/decompression_context/context = new(benchmark_areas)
	var/datum/decompression_check/check = new(base, sources[base], context)
	CHECK_TICK
	TEST_ASSERT(isnull(check.advance(0.25)), "обход не уступил управление при исчерпании среза")
	var/turf/hole = get_step(source, SOUTH)
	hole.ChangeTurf(/turf/closed/wall)
	source.ImmediateCalculateAdjacentTurfs()
	var/contained
	var/attempts = 0
	do
		CHECK_TICK
		contained = check.advance(0.25)
		TEST_ASSERT(++attempts < 1000, "обход после изменения геометрии не завершился")
	while(isnull(contained))
	TEST_ASSERT(contained, "герметизация между срезами не отменила старую пробоину")
	hole = get_step(source, SOUTH)
	hole.ChangeTurf(/turf/open/space/basic)
	source.ImmediateCalculateAdjacentTurfs()
	TEST_ASSERT(!SSair.contain_decompression(base, sources[base], context), "новая пробоина использовала кэш герметичной комнаты")

/datum/unit_test/decompression_containment_benchmark/proc/measure_case(label, expected, rounds = 7, reuse_context = FALSE)
	var/list/pass_ms = list()
	var/sum_ms = 0
	var/max_call_ms = 0
	var/close_checks = 0
	var/geometry_restarts = 0
	var/datum/decompression_context/context
	if(reuse_context)
		context = new(benchmark_areas)
		for(var/area/part as anything in benchmark_areas)
			SSair.contain_decompression(part, sources[part], context)
	for(var/round_index in 1 to rounds)
		CHECK_TICK
		var/total_ms = 0
		if(!reuse_context)
			context = new(benchmark_areas)
		for(var/obj/machinery/door/firedoor/window/containment_benchmark/door in benchmark_doors)
			door.close_check_count = 0
		for(var/area/part as anything in benchmark_areas)
			var/started = TICK_USAGE_REAL
			var/contained = SSair.contain_decompression(part, sources[part], context)
			var/elapsed_ms = TICK_USAGE_TO_MS(started)
			total_ms += elapsed_ms
			max_call_ms = max(max_call_ms, elapsed_ms)
			TEST_ASSERT_EQUAL(contained, expected, "неожиданный результат локализации в [label]")
		for(var/obj/machinery/door/firedoor/window/containment_benchmark/door in benchmark_doors)
			close_checks += door.close_check_count
			TEST_ASSERT(door.close_check_count <= context.restarts + 1, "одна шторка проверена повторно без изменения геометрии в [label]")
		geometry_restarts += context.restarts
		pass_ms += total_ms
		sum_ms += total_ms
		CHECK_TICK
	var/list/record = list(
		"case" = label,
		"areas" = length(benchmark_areas),
		"open_turfs" = length(room),
		"doors" = length(benchmark_doors),
		"rounds" = rounds,
		"mean_pass_ms" = sum_ms / rounds,
		"min_pass_ms" = min(arglist(pass_ms)),
		"max_pass_ms" = max(arglist(pass_ms)),
		"max_call_ms" = max_call_ms,
		"shutter_checks_per_pass" = close_checks / rounds,
		"geometry_restarts_per_pass" = geometry_restarts / rounds,
	)
	results += list(record)
	log_test("CONTAINMENTBENCH [json_encode(record)]")

// Одна створка на перекрёстке защищает целую часть каждой из двух соседних зон.
/datum/unit_test/decompression_containment_benchmark/proc/check_shared_boundary()
	prepare_room(5, 2)
	var/area/first = benchmark_areas[1]
	var/area/second = benchmark_areas[2]
	for(var/turf/member as anything in room)
		var/dx = member.x - origin_x
		var/dy = member.y - origin_y
		if(dx != 2 && dy != 2)
			member.ChangeTurf(/turf/closed/wall)
		else if(dx == 2 && dy != 2)
			second.contents += member
		else
			first.contents += member
	for(var/dx in list(0, 2))
		var/turf/old_hole = locate(origin_x + dx, origin_y - 1, origin_z)
		old_hole.ChangeTurf(/turf/closed/wall)
	var/turf/open/west = locate(origin_x, origin_y + 2, origin_z)
	var/turf/open/north = locate(origin_x + 2, origin_y + 4, origin_z)
	var/turf/west_hole = get_step(west, WEST)
	var/turf/north_hole = get_step(north, NORTH)
	west_hole.ChangeTurf(/turf/open/space/basic)
	north_hole.ChangeTurf(/turf/open/space/basic)
	var/obj/machinery/door/firedoor/door = new(locate(origin_x + 2, origin_y + 2, origin_z))
	door.density = TRUE
	benchmark_doors += door
	refresh_adjacency()
	TEST_ASSERT((door in first.firedoors) && (door in second.firedoors), "контроль: общая дверь не зарегистрирована в обеих зонах")
	var/datum/decompression_context/context = new(benchmark_areas)
	TEST_ASSERT(SSair.contain_decompression(first, list(west), context), "общая дверь не локализовала пробоину первой зоны")
	TEST_ASSERT(SSair.contain_decompression(second, list(north), context), "общая дверь не локализовала пробоину второй зоны")

/datum/unit_test/decompression_containment_benchmark/proc/measure_pending_phase(label = "25_areas_pending_phase", expected_contained = FALSE, reuse_context = FALSE)
	var/list/saved_state = list()
	for(var/state_name in list("decompression_handled_at", "decompression_pending", "decompression_areas", "decompression_started_at", "decompression_seen", "decompression_seals", "currentrun", "num_decompression_areas", "decompression_context", "decompression_check"))
		saved_state[state_name] = SSair.vars[state_name]
	var/list/pass_ms = list()
	var/sum_ms = 0
	var/paused_count = 0
	var/max_tick_delta = 0
	var/max_slice_ms = 0
	var/auto_reopen_ms = 0
	var/auto_reopen_calls = 0
	for(var/round_index in 1 to 3)
		for(var/state_name in list("decompression_handled_at", "decompression_pending", "decompression_areas", "decompression_started_at", "decompression_seen", "decompression_seals", "currentrun"))
			SSair.vars[state_name] = list()
		SSair.decompression_context = null
		SSair.decompression_check = null
		for(var/area/part as anything in benchmark_areas)
			SSair.decompression_areas[part] = TRUE
			SSair.decompression_started_at[part] = world.time
			SSair.decompression_seen[part] = sources[part]
		if(reuse_context)
			SSair.process_decompression_areas_auxtools(FALSE, 0)
		CHECK_TICK
		var/total_ms = 0
		var/resumed = FALSE
		var/attempts = 0
		do
			var/started = TICK_USAGE_REAL
			resumed = SSair.process_decompression_areas_auxtools(resumed)
			var/elapsed_ms = TICK_USAGE_TO_MS(started)
			total_ms += elapsed_ms
			max_slice_ms = max(max_slice_ms, elapsed_ms)
			max_tick_delta = max(max_tick_delta, TICK_USAGE_REAL - started)
			paused_count += !!resumed
			TEST_ASSERT(++attempts < 1000, "возобновляемая фаза не завершилась")
			CHECK_TICK
		while(resumed)
		for(var/area/part as anything in benchmark_areas)
			TEST_ASSERT_EQUAL(!!SSair.decompression_seals[part], expected_contained, "неожиданное удержание границы в [label]")
		pass_ms += total_ms
		sum_ms += total_ms
		if(expected_contained)
			for(var/obj/machinery/door/firedoor/door as anything in benchmark_doors)
				door.auto_closed = TRUE
				for(var/retry in 1 to 100)
					var/reopen_started = TICK_USAGE_REAL
					door.try_auto_reopen()
					auto_reopen_ms += TICK_USAGE_TO_MS(reopen_started)
					auto_reopen_calls++
				TEST_ASSERT(door.density && door.auto_closed && !door.operating, "таймер открыл защитную границу в [label]")
				door.auto_closed = FALSE
				if(door.reopen_timer)
					deltimer(door.reopen_timer)
					door.reopen_timer = null
		for(var/area/part as anything in SSair.decompression_seals.Copy())
			SSair.set_decompression_seals(part)
		CHECK_TICK
	for(var/state_name in saved_state)
		SSair.vars[state_name] = saved_state[state_name]
	var/list/record = list(
		"case" = label,
		"areas" = length(benchmark_areas),
		"rounds" = 3,
		"mean_pass_ms" = sum_ms / 3,
		"min_pass_ms" = min(arglist(pass_ms)),
		"max_pass_ms" = max(arglist(pass_ms)),
		"max_tick_usage_delta" = max_tick_delta,
		"max_slice_ms" = max_slice_ms,
		"paused_calls" = paused_count,
		"auto_reopen_mean_ms" = auto_reopen_calls ? auto_reopen_ms / auto_reopen_calls : 0,
		"auto_reopen_calls" = auto_reopen_calls,
	)
	results += list(record)
	log_test("CONTAINMENTBENCH [json_encode(record)]")

/datum/unit_test/decompression_containment_benchmark/Run()
	TEST_ASSERT(SSair?.initialized, "SSair не инициализирована")
	saved_can_fire = SSair.can_fire
	has_saved_state = TRUE
	SSair.can_fire = FALSE
	arena = SSmapping.RequestBlockReservation(52, 52, border_type_override = /turf/closed/wall)
	TEST_ASSERT_NOTNULL(arena, "не удалось зарезервировать арену")
	origin_x = arena.bottom_left_coords[1] + 1
	origin_y = arena.bottom_left_coords[2] + 1
	origin_z = arena.bottom_left_coords[3]
	original_area = get_area(locate(origin_x, origin_y, origin_z))
	check_resumption()
	check_shared_boundary()
	for(var/size in list(4, 16, 32, 50))
		prepare_room(size)
		measure_case("open_[size]x[size]", FALSE)
	prepare_room(50, 25)
	measure_case("25_connected_areas", FALSE)
	measure_pending_phase()

	prepare_room(16)
	for(var/y in origin_y to origin_y + 15)
		if(y == origin_y + 7)
			continue
		var/turf/divider = locate(origin_x + 7, y, origin_z)
		divider.ChangeTurf(/turf/closed/wall)
	var/obj/machinery/door/firedoor/local_door = new(locate(origin_x + 7, origin_y + 7, origin_z))
	local_door.density = TRUE
	benchmark_doors += local_door
	refresh_adjacency()
	measure_case("sustained_localized", TRUE)
	measure_case("sustained_localized_reused", TRUE, 7, TRUE)
	measure_pending_phase("localized_pending_phase", TRUE)
	measure_pending_phase("localized_pending_phase_reused", TRUE, TRUE)

	for(var/door_count in list(0, 64, 256))
		prepare_room(50)
		for(var/y in origin_y to origin_y + 49)
			var/turf/divider = locate(origin_x + 4, y, origin_z)
			divider.ChangeTurf(/turf/closed/wall)
		for(var/x in origin_x to origin_x + 3)
			var/turf/divider = locate(x, origin_y + 4, origin_z)
			divider.ChangeTurf(/turf/closed/wall)
		for(var/index in 1 to door_count)
			var/obj/machinery/door/firedoor/remote = new(locate(origin_x + 9 + 2 * ((index - 1) % 16), origin_y + 9 + 2 * round((index - 1) / 16), origin_z))
			remote.density = TRUE
			benchmark_doors += remote
		refresh_adjacency()
		measure_case("remote_closed_[door_count]", FALSE)

	prepare_room(16)
	for(var/dx in list(3, 7, 11))
		for(var/dy in list(3, 7, 11))
			var/obj/machinery/door/firedoor/window/containment_benchmark/shutter = new(locate(origin_x + dx, origin_y + dy, origin_z))
			benchmark_doors += shutter
	refresh_adjacency()
	measure_case("9_nonblocking_shutters", FALSE)
	var/report_path = "[GLOB.log_directory]/containment_benchmark.json"
	fdel(report_path)
	file(report_path) << json_encode(results)

/datum/unit_test/decompression_containment_benchmark/Destroy()
	QDEL_LIST(benchmark_doors)
	if(arena)
		for(var/turf/member as anything in arena.reserved_turfs)
			original_area.contents += member
		qdel(arena)
		arena = null
	QDEL_LIST(benchmark_areas)
	if(has_saved_state)
		SSair.can_fire = saved_can_fire
	return ..()
