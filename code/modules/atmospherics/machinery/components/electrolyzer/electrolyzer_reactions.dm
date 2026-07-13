// Electrolyzer reactions (from WhiteMoon). Uses string gas IDs (GAS_*).
#define ELECTROLYSIS_ARGUMENT_SUPERMATTER_POWER "electrolyzer_supermatter_power"
/// Minimum supermatter power for hyper-nob → antinob conversion (~5 GeV equivalent on /tg/).
#define SM_NOB_CONVERSION_MIN_POWER 5000
/// Supermatter power at which conversion reaches 1:1 mol ratio (matches CRITICAL_POWER_PENALTY_THRESHOLD).
#define SM_NOB_CONVERSION_MAX_POWER 9000

GLOBAL_LIST_INIT(electrolyzer_reactions, electrolyzer_reactions_list())

/proc/electrolyzer_reactions_list()
	var/list/built = list()
	for(var/reaction_path in subtypesof(/datum/electrolyzer_reaction))
		var/datum/electrolyzer_reaction/R = new reaction_path()
		built[R.id] = R
	return built

/datum/electrolyzer_reaction
	var/list/requirements
	var/name = "reaction"
	var/id = "r"
	var/desc = ""
	var/list/factor

/datum/electrolyzer_reaction/New()
	init_factors()

/datum/electrolyzer_reaction/proc/init_factors()
	factor = list()

/datum/electrolyzer_reaction/proc/react(datum/gas_mixture/air_mixture, working_power, list/electrolyzer_args = list())
	return

/datum/electrolyzer_reaction/proc/reaction_check(datum/gas_mixture/air_mixture, list/electrolyzer_args = list())
	var/temp = air_mixture.return_temperature()
	if(requirements["MIN_TEMP"] && temp < requirements["MIN_TEMP"])
		return FALSE
	if(requirements["MAX_TEMP"] && temp > requirements["MAX_TEMP"])
		return FALSE
	for(var/gas_id in requirements)
		if(gas_id == "MIN_TEMP" || gas_id == "MAX_TEMP")
			continue
		var/moles = air_mixture.get_moles(gas_id)
		if(!moles || moles < requirements[gas_id])
			return FALSE
	return TRUE

// H2O -> O2 + 2 H2
/datum/electrolyzer_reaction/h2o_conversion
	name = "H2O Conversion"
	id = "h2o_conversion"
	desc = "Conversion of H2O into O2 and H2"
	requirements = list(GAS_H2O = MINIMUM_MOLE_COUNT)

/datum/electrolyzer_reaction/h2o_conversion/react(datum/gas_mixture/air_mixture, working_power, list/electrolyzer_args = list())
	var/h2o_moles = air_mixture.get_moles(GAS_H2O)
	if(!h2o_moles || h2o_moles < MINIMUM_MOLE_COUNT)
		return
	var/old_heat = air_mixture.heat_capacity()
	var/proportion = min(h2o_moles * INVERSE(2), (2.5 * (working_power ** 2)))
	if(proportion < MINIMUM_MOLE_COUNT)
		return
	air_mixture.adjust_moles(GAS_H2O, -proportion * 2)
	air_mixture.adjust_moles(GAS_O2, proportion)
	air_mixture.adjust_moles(GAS_HYDROGEN, proportion * 2)
	var/new_heat = air_mixture.heat_capacity()
	if(new_heat > MINIMUM_HEAT_CAPACITY)
		air_mixture.set_temperature(max(air_mixture.return_temperature() * old_heat / new_heat, TCMB))

/datum/electrolyzer_reaction/h2o_conversion/init_factors()
	factor = list(
		/datum/gas/water_vapor = "H2O consumed at 2x reaction rate",
		/datum/gas/oxygen = "Oxygen produced at 1x reaction rate",
		/datum/gas/hydrogen = "Hydrogen produced at 2x reaction rate",
		"Energy" = "Reaction rate scales with electrolyzer working power squared",
	)

// BZ -> O2 + Halon (temperature‑dependent efficiency)
/datum/electrolyzer_reaction/halon_generation
	name = "Halon generation"
	id = "halon_generation"
	desc = "Production of halon from the electrolysis of BZ."
	requirements = list(GAS_BZ = MINIMUM_MOLE_COUNT)

/datum/electrolyzer_reaction/halon_generation/init_factors()
	factor = list(
		/datum/gas/bz = "BZ is consumed at 1:1 reaction rate",
		/datum/gas/halon = "Halon is produced at 2x reaction rate",
		/datum/gas/oxygen = "Oxygen is produced at 0.2x reaction rate",
		"Temperature" = "Higher mix temperature increases reaction efficiency",
		"Energy" = "[HALON_FORMATION_ENERGY] joules of energy is released per mole of BZ consumed",
	)

/datum/electrolyzer_reaction/halon_generation/react(datum/gas_mixture/air_mixture, working_power, list/electrolyzer_args = list())
	var/old_heat = air_mixture.heat_capacity()
	var/bz_moles = air_mixture.get_moles(GAS_BZ)
	var/reaction_efficency = min(bz_moles * (1 - NUM_E ** (-0.5 * air_mixture.return_temperature() * working_power / FIRE_MINIMUM_TEMPERATURE_TO_EXIST)), bz_moles)
	air_mixture.adjust_moles(GAS_BZ, -reaction_efficency)
	air_mixture.adjust_moles(GAS_O2, reaction_efficency * 0.2)
	air_mixture.adjust_moles(GAS_HALON, reaction_efficency * 2)
	var/energy_used = reaction_efficency * HALON_FORMATION_ENERGY
	var/new_heat = air_mixture.heat_capacity()
	if(new_heat > MINIMUM_HEAT_CAPACITY)
		air_mixture.set_temperature(max(((air_mixture.return_temperature() * old_heat + energy_used) / new_heat), TCMB))

// Hyper-Nob -> Antinob (supermatter zap electrolysis only)
/datum/electrolyzer_reaction/nob_conversion
	name = "Hyper-Nob conversion"
	id = "nob_conversion"
	desc = "Conversion of hyper-noblium into antinoblium via supermatter discharge."
	requirements = list(GAS_HYPERNOB = MINIMUM_MOLE_COUNT)

/datum/electrolyzer_reaction/nob_conversion/init_factors()
	factor = list(
		/datum/gas/hypernoblium = "1 mole of hyper-noblium is consumed per converted mole",
		/datum/gas/antinoblium = "1 mole of antinoblium is produced per converted mole",
		"Location" = "Occurs on turfs struck by supermatter zaps above [SM_NOB_CONVERSION_MIN_POWER] power",
	)

/datum/electrolyzer_reaction/nob_conversion/reaction_check(datum/gas_mixture/air_mixture, list/electrolyzer_args = list())
	var/supermatter_power = electrolyzer_args[ELECTROLYSIS_ARGUMENT_SUPERMATTER_POWER]
	if(!supermatter_power || supermatter_power <= SM_NOB_CONVERSION_MIN_POWER)
		return FALSE
	return ..()

/datum/electrolyzer_reaction/nob_conversion/react(datum/gas_mixture/air_mixture, working_power, list/electrolyzer_args = list())
	var/supermatter_power = electrolyzer_args[ELECTROLYSIS_ARGUMENT_SUPERMATTER_POWER]
	var/hypernob_moles = air_mixture.get_moles(GAS_HYPERNOB)
	if(hypernob_moles <= 0)
		return
	var/conversion_scale = clamp(
		supermatter_power - SM_NOB_CONVERSION_MIN_POWER,
		0,
		SM_NOB_CONVERSION_MAX_POWER - SM_NOB_CONVERSION_MIN_POWER,
	) / (SM_NOB_CONVERSION_MAX_POWER - SM_NOB_CONVERSION_MIN_POWER)
	var/electrolysed = hypernob_moles * conversion_scale
	if(electrolysed <= 0)
		return
	var/old_heat_capacity = air_mixture.heat_capacity()
	var/temperature = air_mixture.return_temperature()
	air_mixture.adjust_moles(GAS_HYPERNOB, -electrolysed)
	air_mixture.adjust_moles(GAS_ANTINOBLIUM, electrolysed)
	var/new_heat_capacity = air_mixture.heat_capacity()
	if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
		air_mixture.set_temperature(max(temperature * old_heat_capacity / new_heat_capacity, TCMB))
