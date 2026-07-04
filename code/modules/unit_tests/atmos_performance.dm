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

/datum/unit_test/atmos_hot_proc_benchmark
	priority = TEST_LONGER

/datum/unit_test/atmos_hot_proc_benchmark/proc/bench_line(name, iterations, time_ms)
	log_test("  ATMOSBENCH [name]: [iterations] iters in [round(time_ms, 0.01)]ms ([round(time_ms * 1000 / iterations, 0.01)]us/op)")

/datum/unit_test/atmos_hot_proc_benchmark/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")

	// --- archive() ---
	var/datum/gas_mixture/archiver = unit_test_air_mix()
	var/iterations = 20000
	var/t1 = TICK_USAGE_REAL
	for(var/i in 1 to iterations)
		archiver.archive()
	bench_line("archive", iterations, TICK_USAGE_TO_MS(t1))

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
