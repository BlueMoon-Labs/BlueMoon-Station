/// Газ без реакций и без температуры горения: нулевой ключ из него уводит смесь с путей станционного воздуха на общий, ничего не меняя в арифметике.
/proc/unit_test_inert_padding_gas()
	var/list/by_gas = SSair.reactions_by_key_gas
	var/list/fuel_temps = GLOB.gas_data.fire_temperatures
	var/list/oxidation_temps = GLOB.gas_data.oxidation_temperatures
	for(var/id in GLOB.gas_data.specific_heats)
		if(id == GAS_O2 || id == GAS_N2)
			continue
		if(length(by_gas?[id]) || fuel_temps[id] || oxidation_temps[id])
			continue
		return id

/proc/unit_test_station_air(o2, n2, temperature)
	var/datum/gas_mixture/mix = new(CELL_VOLUME)
	mix.set_moles(GAS_O2, o2)
	mix.set_moles(GAS_N2, n2)
	mix.set_temperature(temperature)
	return mix

/proc/unit_test_mix_state(datum/gas_mixture/mix)
	return "o2=[num2text(mix.gases[GAS_O2], 12)] n2=[num2text(mix.gases[GAS_N2], 12)] T=[num2text(mix.temperature, 12)] share=[num2text(mix.last_share, 12)]"

/// share() станционного воздуха с перепадом температур совпадает с общим путём бит в бит.
/datum/unit_test/atmos_share_station_air_heat_path

/datum/unit_test/atmos_share_station_air_heat_path/Run()
	var/padding_gas = unit_test_inert_padding_gas()
	TEST_ASSERT_NOTNULL(padding_gas, "нужен газ без реакций и горения")
	var/list/scales = list(0.01, 0.37, 1, 1.9, 4.5)
	var/list/temperatures = list(TCMB, 150, T20C, T20C + 0.4, T20C + 40, 900)
	var/list/coefficients = list(0.2, 0.25, 1 / 3)
	var/cases = 0
	for(var/our_scale in scales)
		for(var/their_scale in scales)
			for(var/our_temperature in temperatures)
				for(var/their_temperature in temperatures)
					var/coefficient = coefficients[(cases % length(coefficients)) + 1]
					cases++
					var/datum/gas_mixture/fast_a = unit_test_station_air(MOLES_O2STANDARD * our_scale, MOLES_N2STANDARD * our_scale * 1.07, our_temperature)
					var/datum/gas_mixture/fast_b = unit_test_station_air(MOLES_O2STANDARD * their_scale * 0.93, MOLES_N2STANDARD * their_scale, their_temperature)
					var/datum/gas_mixture/generic_a = unit_test_station_air(MOLES_O2STANDARD * our_scale, MOLES_N2STANDARD * our_scale * 1.07, our_temperature)
					var/datum/gas_mixture/generic_b = unit_test_station_air(MOLES_O2STANDARD * their_scale * 0.93, MOLES_N2STANDARD * their_scale, their_temperature)
					generic_a.set_moles(padding_gas, 0)
					for(var/datum/gas_mixture/mix as anything in list(fast_a, fast_b, generic_a, generic_b))
						mix.archive()
					var/fast_result = fast_a.share(fast_b, coefficient, 0.2)
					var/generic_result = generic_a.share(generic_b, coefficient, 0.2)
					TEST_ASSERT_EQUAL(num2text(fast_result, 12), num2text(generic_result, 12), "перепад давления разошёлся: [our_scale]/[their_scale], [our_temperature]/[their_temperature] K")
					TEST_ASSERT_EQUAL(unit_test_mix_state(fast_a), unit_test_mix_state(generic_a), "своя смесь разошлась: [our_scale]/[their_scale], [our_temperature]/[their_temperature] K")
					TEST_ASSERT_EQUAL(unit_test_mix_state(fast_b), unit_test_mix_state(generic_b), "смесь соседа разошлась: [our_scale]/[their_scale], [our_temperature]/[their_temperature] K")
					TEST_ASSERT(isnull(generic_a.gases[padding_gas]), "нулевой ключ общего пути должен был уйти чисткой")
					for(var/datum/gas_mixture/mix as anything in list(fast_a, fast_b, generic_a, generic_b))
						qdel(mix)
