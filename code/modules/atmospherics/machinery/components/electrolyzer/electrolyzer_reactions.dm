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
	/// Газ, о первом синтезе которого сообщает эта реакция. Электролизёр - штатный
	/// и единственный источник водорода, галона и антинобеля вне HFR.
	var/synthesis_gas
	/// Взводится после первого сообщения: react() здесь часто выходит раньше
	/// производства, поэтому о синтезе реакции сообщают сами, из нужной ветки.
	var/synthesis_reported = FALSE

/datum/electrolyzer_reaction/New()
	init_factors()

/// Сообщает о первом за раунд синтезе своего газа. Флаг взводится, только когда
/// наука готова принять сообщение, иначе открытие теряется на весь раунд.
/datum/electrolyzer_reaction/proc/report_synthesis()
	if(!SSresearch || !SSresearch.science_tech)
		return
	synthesis_reported = TRUE
	register_gas_synthesis(synthesis_gas)

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
	name = "Электролиз воды"
	id = "h2o_conversion"
	desc = "Электролизёр разбирает водяной пар на кислород и водород. Самый дешёвый источник и того, и другого."
	requirements = list(GAS_H2O = MINIMUM_MOLE_COUNT)
	synthesis_gas = GAS_HYDROGEN

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
	if(!synthesis_reported)
		report_synthesis()
	var/new_heat = air_mixture.heat_capacity()
	if(new_heat > MINIMUM_HEAT_CAPACITY)
		air_mixture.set_temperature(max(air_mixture.return_temperature() * old_heat / new_heat, TCMB))

/datum/electrolyzer_reaction/h2o_conversion/init_factors()
	factor = list(
		/datum/gas/water_vapor = "Расходуется вдвое быстрее скорости реакции",
		/datum/gas/oxygen = "Рождается один к одному со скоростью реакции",
		/datum/gas/hydrogen = "Рождается вдвое быстрее скорости реакции",
		"Energy" = "Скорость растёт как квадрат рабочей мощности электролизёра",
	)

// BZ -> O2 + Halon (temperature‑dependent efficiency)
/datum/electrolyzer_reaction/halon_generation
	name = "Электролиз BZ в галон"
	id = "halon_generation"
	desc = "Электролиз BZ даёт пожарный галон. Чем горячее смесь, тем выше выход."
	requirements = list(GAS_BZ = MINIMUM_MOLE_COUNT)
	synthesis_gas = GAS_HALON

/datum/electrolyzer_reaction/halon_generation/init_factors()
	factor = list(
		/datum/gas/bz = "Расходуется один к одному со скоростью реакции",
		/datum/gas/halon = "Рождается вдвое быстрее скорости реакции",
		/datum/gas/oxygen = "Рождается в объёме 0.2 от скорости реакции",
		"Temperature" = "Чем горячее смесь, тем выше выход",
		"Energy" = "Выделяет [HALON_FORMATION_ENERGY] джоулей на моль израсходованного BZ",
	)

/datum/electrolyzer_reaction/halon_generation/react(datum/gas_mixture/air_mixture, working_power, list/electrolyzer_args = list())
	var/old_heat = air_mixture.heat_capacity()
	var/bz_moles = air_mixture.get_moles(GAS_BZ)
	var/reaction_efficency = min(bz_moles * (1 - NUM_E ** (-0.5 * air_mixture.return_temperature() * working_power / FIRE_MINIMUM_TEMPERATURE_TO_EXIST)), bz_moles)
	air_mixture.adjust_moles(GAS_BZ, -reaction_efficency)
	air_mixture.adjust_moles(GAS_O2, reaction_efficency * 0.2)
	air_mixture.adjust_moles(GAS_HALON, reaction_efficency * 2)
	if(reaction_efficency > 0 && !synthesis_reported)
		report_synthesis()
	var/energy_used = reaction_efficency * HALON_FORMATION_ENERGY
	var/new_heat = air_mixture.heat_capacity()
	if(new_heat > MINIMUM_HEAT_CAPACITY)
		air_mixture.set_temperature(max(((air_mixture.return_temperature() * old_heat + energy_used) / new_heat), TCMB))

// Hyper-Nob -> Antinob (supermatter zap electrolysis only)
/datum/electrolyzer_reaction/nob_conversion
	name = "Превращение гипернобеля в антиноблий"
	id = "nob_conversion"
	desc = "Разряд супермтерии переворачивает гипернобель в антиноблий. Единственный штатный источник антиноблия в игре."
	requirements = list(GAS_HYPERNOB = MINIMUM_MOLE_COUNT)
	synthesis_gas = GAS_ANTINOBLIUM

/datum/electrolyzer_reaction/nob_conversion/init_factors()
	factor = list(
		/datum/gas/hypernoblium = "Один моль на каждый превращённый моль",
		/datum/gas/antinoblium = "Один моль на каждый превращённый моль",
		"Location" = "Идёт на турфах, куда бьёт разряд супермтерии мощностью выше [SM_NOB_CONVERSION_MIN_POWER]",
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
	if(!synthesis_reported)
		report_synthesis()
	var/new_heat_capacity = air_mixture.heat_capacity()
	if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
		air_mixture.set_temperature(max(temperature * old_heat_capacity / new_heat_capacity, TCMB))
