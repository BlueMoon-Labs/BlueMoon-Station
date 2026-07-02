///Global list of recipes for atmospheric machines to use (id -> datum)
GLOBAL_LIST_INIT(hfr_fuels_list, hfr_fuels_create_list())

/proc/hfr_fuels_create_list()
	. = list()
	for(var/fuel_mix_path in subtypesof(/datum/hfr_fuel))
		var/datum/hfr_fuel/fuel_mix = new fuel_mix_path()
		if(!fuel_mix.id || .[fuel_mix.id])
			stack_trace("hfr_fuel: skipping [fuel_mix_path] with empty or duplicate id '[fuel_mix.id]'")
			continue
		.[fuel_mix.id] = fuel_mix

/datum/hfr_fuel
	var/id = ""
	var/name = ""
	var/negative_temperature_multiplier = 1
	var/positive_temperature_multiplier = 1
	var/energy_concentration_multiplier = 1
	var/fuel_consumption_multiplier = 1
	var/gas_production_multiplier = 1
	var/temperature_change_multiplier = 1
	/// Main fuels: list of gas ID strings (e.g. GAS_PLASMA, GAS_O2)
	var/list/requirements = list()
	/// Gases produced in internal fusion mix: list of gas ID strings
	var/list/primary_products = list()
	/// Gases produced in moderator (power level 1-6): list of 6 gas ID strings
	var/list/secondary_products = list()
	var/meltdown_flags = HYPERTORUS_FLAG_BASE_EXPLOSION

/datum/hfr_fuel/New()
	. = ..()
	temperature_change_multiplier = min(temperature_change_multiplier, 1)

/datum/hfr_fuel/plasma_oxy_fuel
	id = "plasma_o2_fuel"
	name = "Plasma + Oxygen fuel"
	negative_temperature_multiplier = 2.5
	positive_temperature_multiplier = 0.1
	energy_concentration_multiplier = 10
	fuel_consumption_multiplier = 3.3
	gas_production_multiplier = 1.4
	temperature_change_multiplier = 0.6
	requirements = list(GAS_PLASMA, GAS_O2)
	primary_products = list(GAS_CO2, GAS_H2O)
	secondary_products = list(GAS_CO2, GAS_H2O, GAS_FREON, GAS_NITROUS, GAS_PLUOXIUM, GAS_HALON)
	meltdown_flags = HYPERTORUS_FLAG_BASE_EXPLOSION | HYPERTORUS_FLAG_MINIMUM_SPREAD

/datum/hfr_fuel/hydrogen_oxy_fuel
	id = "h2_o2_fuel"
	name = "Hydrogen + Oxygen fuel"
	negative_temperature_multiplier = 2
	positive_temperature_multiplier = 0.6
	energy_concentration_multiplier = 3
	fuel_consumption_multiplier = 1.1
	gas_production_multiplier = 0.9
	temperature_change_multiplier = 0.75
	requirements = list(GAS_HYDROGEN, GAS_O2)
	primary_products = list(GAS_HELIUM, GAS_N2)
	secondary_products = list(GAS_HELIUM, GAS_PLASMA, GAS_O2, GAS_N2, GAS_BZ, GAS_HYPERNOB)
	meltdown_flags = HYPERTORUS_FLAG_BASE_EXPLOSION | HYPERTORUS_FLAG_EMP | HYPERTORUS_FLAG_MEDIUM_SPREAD

/datum/hfr_fuel/tritium_oxy_fuel
	id = "t2_o2_fuel"
	name = "Tritium + Oxygen fuel"
	negative_temperature_multiplier = 2.1
	positive_temperature_multiplier = 0.5
	energy_concentration_multiplier = 2
	fuel_consumption_multiplier = 1.2
	gas_production_multiplier = 0.8
	temperature_change_multiplier = 0.8
	requirements = list(GAS_TRITIUM, GAS_O2)
	primary_products = list(GAS_HELIUM, GAS_PLUOXIUM)
	secondary_products = list(GAS_HELIUM, GAS_PLASMA, GAS_O2, GAS_N2, GAS_BZ, GAS_HYPERNOB)
	meltdown_flags = HYPERTORUS_FLAG_BASE_EXPLOSION | HYPERTORUS_FLAG_RADIATION_PULSE | HYPERTORUS_FLAG_MEDIUM_SPREAD

/datum/hfr_fuel/hydrogen_tritium_fuel
	id = "h2_t2_fuel"
	name = "Hydrogen + Tritium fuel"
	negative_temperature_multiplier = 1
	positive_temperature_multiplier = 1
	energy_concentration_multiplier = 1
	fuel_consumption_multiplier = 1
	gas_production_multiplier = 1
	temperature_change_multiplier = 0.85
	requirements = list(GAS_HYDROGEN, GAS_TRITIUM)
	primary_products = list(GAS_HELIUM)
	secondary_products = list(GAS_HELIUM, GAS_PLASMA, GAS_O2, GAS_N2, GAS_BZ, GAS_HYPERNOB)
	meltdown_flags = HYPERTORUS_FLAG_MEDIUM_EXPLOSION | HYPERTORUS_FLAG_RADIATION_PULSE | HYPERTORUS_FLAG_EMP | HYPERTORUS_FLAG_MEDIUM_SPREAD

/datum/hfr_fuel/hypernob_hydrogen_fuel
	id = "hypernob_hydrogen_fuel"
	name = "Hypernoblium + Hydrogen fuel"
	negative_temperature_multiplier = 0.2
	positive_temperature_multiplier = 2.2
	energy_concentration_multiplier = 0.2
	fuel_consumption_multiplier = 0.55
	gas_production_multiplier = 1.4
	temperature_change_multiplier = 0.9
	requirements = list(GAS_HYPERNOB, GAS_HYDROGEN)
	primary_products = list(GAS_ANTINOBLIUM)
	secondary_products = list(GAS_ANTINOBLIUM, GAS_HELIUM, GAS_PROTO_NITRATE, GAS_ZAUKER, GAS_HEALIUM, GAS_MIASMA)
	meltdown_flags = HYPERTORUS_FLAG_DEVASTATING_EXPLOSION | HYPERTORUS_FLAG_RADIATION_PULSE | HYPERTORUS_FLAG_EMP | HYPERTORUS_FLAG_BIG_SPREAD

/datum/hfr_fuel/hypernob_trit_fuel
	id = "hypernob_trit_fuel"
	name = "Hypernoblium + Tritium fuel"
	negative_temperature_multiplier = 0.1
	positive_temperature_multiplier = 2.5
	energy_concentration_multiplier = 0.1
	fuel_consumption_multiplier = 0.45
	gas_production_multiplier = 1.7
	temperature_change_multiplier = 0.95
	requirements = list(GAS_HYPERNOB, GAS_TRITIUM)
	primary_products = list(GAS_ANTINOBLIUM)
	secondary_products = list(GAS_ANTINOBLIUM, GAS_HELIUM, GAS_PROTO_NITRATE, GAS_ZAUKER, GAS_HEALIUM, GAS_MIASMA)
	meltdown_flags = HYPERTORUS_FLAG_DEVASTATING_EXPLOSION | HYPERTORUS_FLAG_RADIATION_PULSE | HYPERTORUS_FLAG_EMP | HYPERTORUS_FLAG_BIG_SPREAD

/datum/hfr_fuel/hypernob_antinob_fuel
	id = "hypernob_antinob_fuel"
	name = "Hypernoblium + Antinoblium fuel"
	negative_temperature_multiplier = 0.01
	positive_temperature_multiplier = 3.5
	energy_concentration_multiplier = 2
	fuel_consumption_multiplier = 0.01
	gas_production_multiplier = 3
	temperature_change_multiplier = 1
	requirements = list(GAS_HYPERNOB, GAS_ANTINOBLIUM)
	primary_products = list(GAS_HELIUM)
	secondary_products = list(GAS_PLASMA, GAS_O2, GAS_N2, GAS_PROTO_NITRATE, GAS_NITRIUM, GAS_MIASMA)
	meltdown_flags = HYPERTORUS_FLAG_DEVASTATING_EXPLOSION | HYPERTORUS_FLAG_RADIATION_PULSE | HYPERTORUS_FLAG_EMP | HYPERTORUS_FLAG_MASSIVE_SPREAD | HYPERTORUS_FLAG_CRITICAL_MELTDOWN
