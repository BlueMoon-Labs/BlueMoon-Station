// Atmos handbook metadata (init_factors) for gas reactions.
// Kept separate from reactions.dm to keep reaction logic readable.

/datum/gas_reaction/nobliumsupression/init_factors()
	desc = "Hyper-noblium suppresses other gas reactions when present in sufficient quantity."
	factor = list(
		/datum/gas/hypernoblium = "At least [REACTION_OPPRESSION_THRESHOLD] moles required to suppress reactions",
		"Temperature" = "Only suppresses reactions above [REACTION_OPPRESSION_MIN_TEMP] kelvin",
	)

/datum/gas_reaction/water_vapor/init_factors()
	desc = "Water vapor extinguishes fires or freezes freon-based effects on open turfs."
	factor = list(
		/datum/gas/water_vapor = "At least [MOLES_GAS_VISIBLE] moles required",
		"Temperature" = "Above [WATER_VAPOR_FREEZE] K extinguishes fires; at or below, triggers freon turf effects",
		"Location" = "Only occurs on open turfs",
	)

/datum/gas_reaction/tritfire/init_factors()
	desc = "Tritium combustion with oxygen. Runs before plasma combustion."
	factor = list(
		/datum/gas/tritium = "Consumed as fuel; rate depends on oxygen ratio",
		/datum/gas/oxygen = "Oxidizer for tritium burn",
		/datum/gas/water_vapor = "Produced from combustion",
		"Temperature" = "Requires at least [FIRE_MINIMUM_TEMPERATURE_TO_EXIST] kelvin",
		"Radiation" = "May emit radiation pulses when enough fuel burns",
		"Energy" = "[FIRE_HYDROGEN_ENERGY_RELEASED] joules released per mole of fuel burned",
		"Location" = "Creates hotspots on open turfs",
	)

/datum/gas_reaction/plasmafire/init_factors()
	desc = "Plasma combustion with oxygen. High O2:plasma ratio produces tritium instead of CO2."
	factor = list(
		/datum/gas/plasma = "Primary fuel; burn rate scales with temperature",
		/datum/gas/oxygen = "Oxidizer; high O2:plasma ratio produces tritium instead of CO2",
		/datum/gas/carbon_dioxide = "Produced when O2:plasma ratio is below [SUPER_SATURATION_THRESHOLD]",
		/datum/gas/tritium = "Produced when O2:plasma ratio exceeds [SUPER_SATURATION_THRESHOLD]",
		"Temperature" = "Requires at least [FIRE_MINIMUM_TEMPERATURE_TO_EXIST] kelvin",
		"Energy" = "[FIRE_PLASMA_ENERGY_RELEASED] joules released per mole of plasma burned",
		"Location" = "Creates hotspots on open turfs",
	)

/datum/gas_reaction/genericfire/init_factors()
	desc = "Universal combustion of oxidizers and flammable gases based on enthalpy tables. Plasma and tritium are handled separately."
	factor = list(
		"Temperature" = "Each gas burns only above its ignition or oxidation temperature",
		"Energy" = "Heat released from per-gas enthalpy values; products defined per gas type",
		"Location" = "On lavaland Z-levels, nitrogen is not treated as a fuel",
	)

/datum/gas_reaction/fusion/init_factors()
	desc = "Chaotic plasma fusion. Disabled in active atmospheric processing."
	factor = list(
		/datum/gas/plasma = "Primary fuel; must exceed [FUSION_MOLE_THRESHOLD] moles",
		/datum/gas/carbon_dioxide = "Must exceed [FUSION_MOLE_THRESHOLD] moles; modulates instability",
		/datum/gas/tritium = "[FUSION_TRITIUM_MOLES_USED] mole consumed per tick",
		/datum/gas/oxygen = "Produced during exothermic fusion",
		/datum/gas/nitrous_oxide = "Produced during exothermic fusion",
		/datum/gas/bz = "Produced during endothermic fusion",
		/datum/gas/nitryl = "Produced during endothermic fusion",
		"Temperature" = "Requires at least [FUSION_TEMPERATURE_THRESHOLD] kelvin",
		"Radiation" = "Emits radiation and may spawn nuclear particles at high energy",
		"Energy" = "Highly variable; includes mass-energy conversion via plasma binding energy",
	)

/datum/gas_reaction/nitrylformation/init_factors()
	desc = "Endothermic formation of nitryl from oxygen and nitrogen, catalyzed by N2O."
	factor = list(
		/datum/gas/oxygen = "Consumed at 1:1 reaction rate",
		/datum/gas/nitrogen = "Consumed at 1:1 reaction rate",
		/datum/gas/nitrous_oxide = "Catalyst; at least 5 moles required",
		/datum/gas/nitryl = "Produced at 2x reaction rate",
		"Temperature" = "Rate scales with temperature above [FIRE_MINIMUM_TEMPERATURE_TO_EXIST * 25] kelvin",
		"Energy" = "[NITRYL_FORMATION_ENERGY] joules absorbed per reaction rate",
	)

/datum/gas_reaction/bzformation/init_factors()
	desc = "Formation of BZ from N2O and plasma at low pressure. Exothermic."
	factor = list(
		/datum/gas/nitrous_oxide = "Consumed at 1:1 reaction rate; at least 10 moles",
		/datum/gas/plasma = "Consumed at 2:1 reaction rate relative to N2O; at least 10 moles",
		/datum/gas/bz = "Produced at 1:1 reaction rate",
		/datum/gas/oxygen = "May be produced when all N2O is consumed",
		"Pressure" = "Lower pressure increases efficiency; optimal around 10 kPa",
		"Energy" = "[FIRE_CARBON_ENERGY_RELEASED * 2] joules released per reaction rate",
	)

/datum/gas_reaction/stimformation/init_factors()
	desc = "Formation of stimulum from tritium, plasma, nitryl, and BZ. Can be exo- or endothermic."
	factor = list(
		/datum/gas/tritium = "Consumed at 1:1 heat scale; at least 30 moles",
		/datum/gas/plasma = "Consumed at 1:1 heat scale; at least 10 moles",
		/datum/gas/nitryl = "Consumed at 1:1 heat scale; at least 30 moles",
		/datum/gas/bz = "Required catalyst; at least 20 moles",
		/datum/gas/stimulum = "Produced at 0.1x heat scale",
		"Temperature" = "Effectiveness follows a quintic curve vs temperature / [STIMULUM_HEAT_SCALE]",
		"Energy" = "Net heat change varies with temperature via stimulum polynomial",
	)

/datum/gas_reaction/nobliumformation/init_factors()
	desc = "Formation of hyper-noblium from nitrogen and tritium at cryogenic temperatures."
	factor = list(
		/datum/gas/nitrogen = "10 moles consumed per mole of hyper-noblium",
		/datum/gas/tritium = "5 moles per noblium at no BZ; less with BZ present",
		/datum/gas/bz = "Reduces tritium consumption and energy released",
		/datum/gas/hypernoblium = "Produced from N2 and tritium",
		"Temperature" = "Only occurs below [NOBLIUM_FORMATION_MAX_TEMP] kelvin",
		"Energy" = "[NOBLIUM_FORMATION_ENERGY] joules released per mole formed (reduced by BZ)",
	)

/datum/gas_reaction/miaster/init_factors()
	desc = "Dry heat sterilization of miasma into oxygen."
	factor = list(
		/datum/gas/miasma = "Consumed up to 20 + (T - 443.15) / 20 moles per tick",
		/datum/gas/oxygen = "Produced 1:1 from destroyed miasma",
		/datum/gas/water_vapor = "More than 0.1 moles prevents the reaction",
		"Temperature" = "Requires at least [T0C + 170] kelvin (170°C)",
		"Energy" = "Slightly exothermic (+0.002 K per mole cleaned)",
	)

/datum/gas_reaction/nitric_oxide/init_factors()
	desc = "Low-temperature decomposition and oxidation of nitric oxide."
	factor = list(
		/datum/gas/nitric_oxide = "Decomposes to N2 and O2, or reacts with O2 to form nitryl",
		/datum/gas/oxygen = "Enables nitryl formation when present",
		/datum/gas/nitryl = "Produced from NO + O2 reaction",
		/datum/gas/nitrogen = "Produced from decomposition",
		"Temperature" = "Only occurs below [FIRE_MINIMUM_TEMPERATURE_TO_EXIST + 100] kelvin",
	)

/datum/gas_reaction/hagedorn/init_factors()
	desc = "Converts all gases into quark matter at extreme temperatures."
	factor = list(
		/datum/gas/quark_matter = "All mixture energy converted into quark matter moles",
		"Temperature" = "Requires at least 2e12 kelvin",
		"Energy" = "Conserves total thermal energy of the mixture",
	)

/datum/gas_reaction/dehagedorn/init_factors()
	desc = "Condenses quark matter back into random gases below the Hagedorn temperature."
	factor = list(
		/datum/gas/quark_matter = "Consumed entirely to seed gas reformation",
		"Temperature" = "Only occurs below 1.99e12 kelvin",
		"Energy" = "Thermal energy redistributed into random gases (not tritium or hyper-noblium)",
	)

/datum/gas_reaction/freonfire/init_factors()
	desc = "Endothermic freon combustion with oxygen. Proto-nitrate extends the burn window."
	factor = list(
		/datum/gas/freon = "Fuel; burn rate scales with temperature below 0°C",
		/datum/gas/oxygen = "Oxidizer consumed per freon burn rate",
		/datum/gas/carbon_dioxide = "Produced 1:1 from burned freon",
		/datum/gas/proto_nitrate = "Raises maximum burn temperature to [FREON_CATALYST_MAX_TEMPERATURE] K",
		"Temperature" = "Burns between [FREON_TERMINAL_TEMPERATURE] and [FREON_MAXIMUM_BURN_TEMPERATURE] K (or [FREON_CATALYST_MAX_TEMPERATURE] K with proto-nitrate)",
		"Energy" = "[FIRE_FREON_ENERGY_CONSUMED] joules absorbed per mole of freon burned",
		"Location" = "May create hot ice on open turfs between [FREON_HOT_ICE_MIN_TEMP]-[FREON_HOT_ICE_MAX_TEMP] K",
	)

/datum/gas_reaction/freonformation/init_factors()
	desc = "Endothermic formation of freon from plasma, CO2, and BZ."
	factor = list(
		/datum/gas/plasma = "Consumed at 0.6 per reaction unit",
		/datum/gas/carbon_dioxide = "Consumed at 0.3 per reaction unit",
		/datum/gas/bz = "Consumed at 0.1 per reaction unit",
		/datum/gas/freon = "Produced at 10x reaction units",
		"Temperature" = "Requires at least [FREON_FORMATION_MIN_TEMPERATURE] kelvin; rate scales with excess heat",
		"Energy" = "[FREON_FORMATION_ENERGY_CONSUMED] joules absorbed per reaction unit",
	)

/datum/gas_reaction/halon_o2removal/init_factors()
	desc = "Halon absorbs oxygen to form pluoxium. Endothermic."
	factor = list(
		/datum/gas/halon = "Consumed at 1:1 reaction rate",
		/datum/gas/oxygen = "Consumed at 20:1 relative to halon",
		/datum/gas/pluoxium = "Produced at 2.5x reaction rate",
		"Temperature" = "Requires at least [HALON_COMBUSTION_MIN_TEMPERATURE] kelvin; rate scales with temperature",
		"Energy" = "[HALON_COMBUSTION_ENERGY] joules absorbed per reaction rate",
	)

/datum/gas_reaction/healium_formation/init_factors()
	desc = "Formation of healium from BZ and freon."
	factor = list(
		/datum/gas/freon = "Consumed at 2.75x reaction rate",
		/datum/gas/bz = "Consumed at 0.25x reaction rate",
		/datum/gas/healium = "Produced at 3x reaction rate",
		"Temperature" = "Can only occur between [HEALIUM_FORMATION_MIN_TEMP] - [HEALIUM_FORMATION_MAX_TEMP] kelvin",
		"Energy" = "[HEALIUM_FORMATION_ENERGY] joules released per reaction rate",
	)

/datum/gas_reaction/zauker_formation/init_factors()
	desc = "Production of zauker using hyper-noblium and nitrium under very high temperatures."
	factor = list(
		/datum/gas/hypernoblium = "Hyper-Noblium is consumed at 0.01 reaction rate",
		/datum/gas/nitrium = "Nitrium is consumed at 0.5 reaction rate",
		/datum/gas/zauker = "Zauker is produced at 0.5 reaction rate",
		"Temperature" = "Can only occur between [ZAUKER_FORMATION_MIN_TEMPERATURE] - [ZAUKER_FORMATION_MAX_TEMPERATURE] kelvin",
		"Energy" = "[ZAUKER_FORMATION_ENERGY] joules of energy is absorbed per reaction rate",
	)

/datum/gas_reaction/zauker_decomp/init_factors()
	desc = "Zauker decomposes in the presence of nitrogen to limit floods."
	factor = list(
		/datum/gas/zauker = "Consumed up to [ZAUKER_DECOMPOSITION_MAX_RATE] moles per tick",
		/datum/gas/nitrogen = "Required catalyst; consumed alongside zauker",
		/datum/gas/oxygen = "Produced at 0.3x decomposition rate",
		"Energy" = "[ZAUKER_DECOMPOSITION_ENERGY] joules released per mole decomposed",
	)

/datum/gas_reaction/nitrium_formation/init_factors()
	desc = "Endothermic formation of nitrium from tritium, nitrogen, and BZ."
	factor = list(
		/datum/gas/tritium = "Consumed at 1:1 reaction rate; at least 20 moles",
		/datum/gas/nitrogen = "Consumed at 1:1 reaction rate; at least 10 moles",
		/datum/gas/bz = "Consumed at 0.05x reaction rate; at least 5 moles",
		/datum/gas/nitrium = "Produced at 1:1 reaction rate",
		"Temperature" = "Requires at least [NITRIUM_FORMATION_MIN_TEMP] kelvin; rate scales with temperature",
		"Energy" = "[NITRIUM_FORMATION_ENERGY] joules absorbed per reaction rate",
	)

/datum/gas_reaction/nitrium_decomposition/init_factors()
	desc = "Nitrium decomposes into nitrogen and hydrogen when heated."
	factor = list(
		/datum/gas/nitrium = "Consumed at 1:1 reaction rate",
		/datum/gas/nitrogen = "Produced at 1:1 reaction rate",
		/datum/gas/hydrogen = "Produced at 1:1 reaction rate",
		"Temperature" = "Only occurs below [NITRIUM_DECOMPOSITION_MAX_TEMP] kelvin; rate scales with temperature",
		"Energy" = "[NITRIUM_DECOMPOSITION_ENERGY] joules released per reaction rate",
	)

/datum/gas_reaction/pluox_formation/init_factors()
	desc = "Formation of pluoxium from CO2, oxygen, and tritium."
	factor = list(
		/datum/gas/carbon_dioxide = "Consumed 1:1 per pluoxium produced",
		/datum/gas/oxygen = "Consumed 2:1 per pluoxium produced",
		/datum/gas/tritium = "Consumed at 0.01:1 per pluoxium produced",
		/datum/gas/pluoxium = "Produced up to [PLUOXIUM_FORMATION_MAX_RATE] moles per tick",
		/datum/gas/hydrogen = "Byproduct at 0.01:1 per pluoxium produced",
		"Temperature" = "Can only occur between [PLUOXIUM_FORMATION_MIN_TEMP] - [PLUOXIUM_FORMATION_MAX_TEMP] kelvin",
		"Energy" = "[PLUOXIUM_FORMATION_ENERGY] joules released per mole of pluoxium",
	)

/datum/gas_reaction/proto_nitrate_formation/init_factors()
	desc = "Formation of proto-nitrate from pluoxium and hydrogen at high temperature."
	factor = list(
		/datum/gas/pluoxium = "Consumed at 0.2x reaction rate",
		/datum/gas/hydrogen = "Consumed at 2x reaction rate",
		/datum/gas/proto_nitrate = "Produced at 2.2x reaction rate",
		"Temperature" = "Can only occur between [PN_FORMATION_MIN_TEMPERATURE] - [PN_FORMATION_MAX_TEMPERATURE] kelvin",
		"Energy" = "[PN_FORMATION_ENERGY] joules released per reaction rate",
	)

/datum/gas_reaction/proto_nitrate_hydrogen_response/init_factors()
	desc = "Proto-nitrate converts excess hydrogen into more proto-nitrate."
	factor = list(
		/datum/gas/hydrogen = "Consumed up to [PN_HYDROGEN_CONVERSION_MAX_RATE] moles per tick; requires [PN_HYDROGEN_CONVERSION_THRESHOLD]+ moles",
		/datum/gas/proto_nitrate = "Increased at 0.5x conversion rate",
		"Energy" = "[PN_HYDROGEN_CONVERSION_ENERGY] joules absorbed per mole converted",
	)

/datum/gas_reaction/proto_nitrate_tritium_response/init_factors()
	desc = "Proto-nitrate converts tritium into hydrogen at moderate temperatures."
	factor = list(
		/datum/gas/tritium = "Consumed at 1:1 conversion rate",
		/datum/gas/proto_nitrate = "Consumed at 0.01x conversion rate",
		/datum/gas/hydrogen = "Produced at 1:1 conversion rate",
		"Temperature" = "Can only occur between [PN_TRITIUM_CONVERSION_MIN_TEMP] - [PN_TRITIUM_CONVERSION_MAX_TEMP] kelvin",
		"Energy" = "[PN_TRITIUM_CONVERSION_ENERGY] joules released per mole converted",
	)

/datum/gas_reaction/proto_nitrate_bz_response/init_factors()
	desc = "Proto-nitrate breaks down BZ into nitrogen, helium, and plasma."
	factor = list(
		/datum/gas/bz = "Consumed at 1:1 reaction rate",
		/datum/gas/proto_nitrate = "Consumed at 1:1 reaction rate",
		/datum/gas/nitrogen = "Produced at 0.4x reaction rate",
		/datum/gas/helium = "Produced at 1.6x reaction rate",
		/datum/gas/plasma = "Produced at 0.8x reaction rate",
		"Temperature" = "Can only occur between [PN_BZASE_MIN_TEMP] - [PN_BZASE_MAX_TEMP] kelvin",
		"Energy" = "[PN_BZASE_ENERGY] joules released per mole reacted",
	)

/datum/gas_reaction/antinoblium_replication/init_factors()
	desc = "Antinoblium converts other gases into more antinoblium proportionally."
	factor = list(
		/datum/gas/antinoblium = "Catalyst; at least [MOLES_GAS_VISIBLE] moles required",
		"Temperature" = "Requires above [REACTION_OPPRESSION_MIN_TEMP] kelvin",
		"Energy" = "Endothermic; temperature drops as gases are converted",
	)
