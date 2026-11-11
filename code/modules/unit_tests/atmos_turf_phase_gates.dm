// Ранние выходы фазы турфов (гейт react(), индикатор видимых газов, пропуск второго
// прохода compare/share) - чистые оптимизации: там, где они срабатывают, полный путь
// дал бы тот же результат.

/proc/unit_test_gate_mix(gas_id, amount, temperature)
	var/datum/gas_mixture/mix = new(CELL_VOLUME)
	mix.set_moles(GAS_O2, MOLES_O2STANDARD)
	mix.set_moles(GAS_N2, MOLES_N2STANDARD)
	mix.set_moles(gas_id, amount)
	mix.set_temperature(temperature)
	return mix

/proc/unit_test_gas_state(datum/gas_mixture/mix)
	. = "T=[num2text(mix.temperature, 12)]"
	for(var/id, moles in mix.gases)
		. += " [id]=[num2text(moles, 12)]"

/// Где гейт отпускает смесь, полный сбор кандидатов не находит реакции, которая что-то изменила бы.
/datum/unit_test/atmos_react_idle_gate_matches_full_path

/datum/unit_test/atmos_react_idle_gate_matches_full_path/Run()
	TEST_ASSERT(SSair?.initialized, "SSair не инициализирован")
	var/list/key_indicator = SSair.reaction_key_gas_indicator
	TEST_ASSERT_NOTNULL(key_indicator, "гейт react() выключен: индикатор ключей не построен")
	var/list/temperatures = list(T20C, SSair.temp_gated_min_temp - 1, SSair.temp_gated_min_temp, 400, SSair.temp_gated_air_ceiling - 1, SSair.temp_gated_air_ceiling, 5000)
	var/list/amounts = list(0, 0.005, 1, 60)
	var/gated_cases = 0
	for(var/gas_id in GLOB.gas_data.specific_heats)
		for(var/amount in amounts)
			for(var/temperature in temperatures)
				var/datum/gas_mixture/gated = unit_test_gate_mix(gas_id, amount, temperature)
				if(!GAS_MIXTURE_REACT_IDLE(gated, SSair))
					qdel(gated)
					continue
				gated_cases++
				var/datum/gas_mixture/full = unit_test_gate_mix(gas_id, amount, temperature)
				var/gated_result = gated.react(null)
				SSair.reaction_key_gas_indicator = null
				var/full_result = full.react(null)
				SSair.reaction_key_gas_indicator = key_indicator
				var/case_name = "[gas_id] [amount] моль при [temperature] K"
				TEST_ASSERT_EQUAL(gated_result, NO_REACTION, "гейт вернул реакцию: [case_name]")
				TEST_ASSERT_EQUAL(full_result, NO_REACTION, "гейт отпустил смесь, в которой полный путь нашёл реакцию: [case_name]")
				TEST_ASSERT_EQUAL(unit_test_gas_state(gated), unit_test_gas_state(full), "смесь после гейта и после полного пути разошлась: [case_name]")
				qdel(gated)
				qdel(full)
	TEST_ASSERT(gated_cases > 0, "гейт не сработал ни разу")
	// Дышащий воздух - главный клиент гейта: O2, N2 и CO2 при комнатной температуре.
	var/datum/gas_mixture/breathed = unit_test_gate_mix(GAS_CO2, 0.4, T20C + 2)
	TEST_ASSERT(GAS_MIXTURE_REACT_IDLE(breathed, SSair), "воздух с CO2 от дыхания должен отпускаться гейтом")
	qdel(breathed)

/// Индикатор видимых газов в точности повторяет условие обхода смеси в process_cell.
/datum/unit_test/atmos_visible_gas_indicator_matches_visibility

/datum/unit_test/atmos_visible_gas_indicator_matches_visibility/Run()
	var/list/indicator = SSair.visible_gas_indicator
	TEST_ASSERT_NOTNULL(indicator, "индикатор видимых газов не построен")
	var/list/visibility = GLOB.gas_data.visibility
	var/list/no_overlay_gases = typecache_of_gases_with_no_overlays()
	for(var/gas_id in visibility)
		var/expected = visibility[gas_id] && !no_overlay_gases[gas_id]
		TEST_ASSERT_EQUAL(!!indicator[gas_id], !!expected, "индикатор разошёлся с видимостью газа [gas_id]")

/// Наборы ключей одной длины, но разные: второй проход compare() и share() пропускать нельзя.
/datum/unit_test/atmos_compare_share_equal_length_key_sets

/datum/unit_test/atmos_compare_share_equal_length_key_sets/Run()
	var/datum/gas_mixture/ours = unit_test_air_mix()
	var/datum/gas_mixture/theirs = unit_test_air_mix()
	ours.set_moles(GAS_CO2, MINIMUM_MOLES_DELTA_TO_MOVE * 0.5)
	theirs.set_moles(GAS_PLASMA, 5)
	TEST_ASSERT_EQUAL(ours.compare(theirs), GAS_PLASMA, "газ, которого у нас нет, обязан найтись при равной длине списков")
	TEST_ASSERT_EQUAL(theirs.compare(ours), GAS_PLASMA, "газ, которого нет у соседа, обязан найтись при равной длине списков")

	var/datum/gas_mixture/ref_ours = unit_test_air_mix()
	var/datum/gas_mixture/ref_theirs = unit_test_air_mix()
	ref_ours.set_moles(GAS_CO2, MINIMUM_MOLES_DELTA_TO_MOVE * 0.5)
	ref_theirs.set_moles(GAS_PLASMA, 5)
	for(var/datum/gas_mixture/mix as anything in list(ours, theirs, ref_ours, ref_theirs))
		mix.set_temperature(T20C + 30 * (mix == theirs || mix == ref_theirs))
		mix.archive()
	var/result = ours.share(theirs, 0.2, 0.25)
	var/ref_result = unit_test_reference_share(ref_ours, ref_theirs, 0.2, 0.25)
	TEST_ASSERT(abs(result - ref_result) < 0.01, "перепад давления разошёлся с эталоном: [result] против [ref_result]")
	TEST_ASSERT(ours.get_moles(GAS_PLASMA) > 0, "плазма соседа не дошла до нас")
	for(var/id in ours.gases | ref_ours.gases)
		TEST_ASSERT(abs(ours.get_moles(id) - ref_ours.get_moles(id)) < 0.001, "наш [id] разошёлся с эталоном")
	for(var/id in theirs.gases | ref_theirs.gases)
		TEST_ASSERT(abs(theirs.get_moles(id) - ref_theirs.get_moles(id)) < 0.001, "[id] соседа разошёлся с эталоном")
	TEST_ASSERT(abs(ours.temperature - ref_ours.temperature) < 0.01, "наша температура разошлась с эталоном")
	TEST_ASSERT(abs(theirs.temperature - ref_theirs.temperature) < 0.01, "температура соседа разошлась с эталоном")
	for(var/datum/gas_mixture/mix as anything in list(ours, theirs, ref_ours, ref_theirs))
		qdel(mix)

/// Сравнение пары внутри группы в process_cell: равный воздух не шерит, газ, которого у нас нет, и разница температур - шерят.
/datum/unit_test/atmos_process_cell_group_pair_compare

/datum/unit_test/atmos_process_cell_group_pair_compare/Run()
	TEST_ASSERT(SSair?.initialized, "SSair не инициализирован")
	var/turf/base = run_loc_floor_bottom_left
	for(var/dx in 0 to 3)
		for(var/dy in 0 to 2)
			var/turf/T = locate(base.x + dx, base.y + dy, base.z)
			TEST_ASSERT_NOTNULL(T, "нет турфа арены [dx],[dy]")
			if(dx == 0 || dy == 0 || dx == 3 || dy == 2)
				T.ChangeTurf(/turf/closed/wall)
	var/turf/open/tile_a = locate(base.x + 1, base.y + 1, base.z)
	var/turf/open/tile_b = locate(base.x + 2, base.y + 1, base.z)
	tile_a.ImmediateCalculateAdjacentTurfs()
	tile_b.ImmediateCalculateAdjacentTurfs()
	TEST_ASSERT(tile_b in tile_a.atmos_adjacent_turfs, "пара обязана быть смежной")
	var/datum/excited_group/pair_group = new
	pair_group.add_turf(tile_a)
	pair_group.add_turf(tile_b)
	var/fire = max(tile_a.current_cycle, tile_b.current_cycle, SSair.times_fired) + 100

	// Равный воздух: шера нет.
	tile_a.air.copy_from_turf(tile_a)
	tile_b.air.copy_from_turf(tile_b)
	tile_a.air.last_share = 0
	tile_a.process_cell(++fire)
	TEST_ASSERT_EQUAL(tile_a.air.last_share, 0, "равный воздух не должен шерить")

	// Газ только у соседа при равной длине списков: у нас вместо него нулевой ключ.
	tile_a.air.copy_from_turf(tile_a)
	tile_b.air.copy_from_turf(tile_b)
	tile_a.air.set_moles(GAS_CO2, 0)
	tile_b.air.set_moles(GAS_PLASMA, 10)
	tile_a.process_cell(++fire)
	TEST_ASSERT(tile_a.air.get_moles(GAS_PLASMA) > 0, "плазма соседа должна была перейти к нам")

	// Только температура, моли равны.
	tile_a.air.copy_from_turf(tile_a)
	tile_b.air.copy_from_turf(tile_b)
	tile_b.air.set_temperature(T20C + MINIMUM_TEMPERATURE_DELTA_TO_SUSPEND * 10)
	var/cold_before = tile_a.air.temperature
	tile_a.process_cell(++fire)
	TEST_ASSERT(tile_a.air.temperature > cold_before, "разница температур в группе должна была шерить тепло")

	pair_group.garbage_collect()
	for(var/turf/open/T as anything in list(tile_a, tile_b))
		T.air.copy_from_turf(T)
		SSair.remove_from_active(T)
