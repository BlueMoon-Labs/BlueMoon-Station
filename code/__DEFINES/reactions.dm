//Defines used in atmos gas reactions. Used to be located in ..\modules\atmospherics\gasmixtures\reactions.dm, but were moved here because fusion added so fucking many.

//Plasma fire properties
#define OXYGEN_BURN_RATE_BASE				1.4
#define PLASMA_BURN_RATE_DELTA				9
#define PLASMA_MINIMUM_OXYGEN_NEEDED		2
#define PLASMA_MINIMUM_OXYGEN_PLASMA_RATIO	30
#define FIRE_CARBON_ENERGY_RELEASED			100000	//Amount of heat released per mole of burnt carbon into the tile
#define FIRE_HYDROGEN_ENERGY_RELEASED		280000  //Amount of heat released per mole of burnt hydrogen and/or tritium(hydrogen isotope)
#define FIRE_PLASMA_ENERGY_RELEASED			3000000	//Amount of heat released per mole of burnt plasma into the tile
//General assmos defines.
#define WATER_VAPOR_FREEZE					200
#define NITRYL_FORMATION_ENERGY				100000
#define TRITIUM_BURN_OXY_FACTOR				100
#define TRITIUM_BURN_TRIT_FACTOR			10
#define TRITIUM_BURN_RADIOACTIVITY_FACTOR	5000 	//The neutrons gotta go somewhere. Completely arbitrary number.
#define TRITIUM_MINIMUM_RADIATION_ENERGY	0.1  	//minimum 0.01 moles trit or 10 moles oxygen to start producing rads
#define SUPER_SATURATION_THRESHOLD			96
#define STIMULUM_HEAT_SCALE					100000
#define STIMULUM_FIRST_RISE					0.65
#define STIMULUM_FIRST_DROP					0.065
#define STIMULUM_SECOND_RISE				0.0009
#define STIMULUM_ABSOLUTE_DROP				0.00000335
#define REACTION_OPPRESSION_THRESHOLD		5 // stops reactions when >5 mol and temp > 20 K
#define NOBLIUM_FORMATION_ENERGY			2e9 	// energy released per mole (exothermic); BZ reduces amount
#define NOBLIUM_FORMATION_MAX_TEMP			15		// below 15 K only
//Research point amounts
#define NOBLIUM_RESEARCH_AMOUNT				25
#define BZ_RESEARCH_SCALE					4
#define BZ_RESEARCH_MAX_AMOUNT				400
#define QCD_RESEARCH_AMOUNT					0.2 // often made in absolutely massive quantities due to the simple nature of fusion
#define MIASMA_RESEARCH_AMOUNT				6
#define STIMULUM_RESEARCH_AMOUNT			50
//Plasma fusion properties
#define FUSION_ENERGY_THRESHOLD				3e9 	//Amount of energy it takes to start a fusion reaction
#define FUSION_MOLE_THRESHOLD				250 	//Mole count required (tritium/plasma) to start a fusion reaction
#define FUSION_TRITIUM_CONVERSION_COEFFICIENT (1e-10)
#define INSTABILITY_GAS_POWER_FACTOR 		0.003
#define FUSION_TRITIUM_MOLES_USED  			1
#define PLASMA_BINDING_ENERGY  				20000000
#define TOROID_VOLUME_BREAKEVEN			1000
#define FUSION_TEMPERATURE_THRESHOLD	    10000
#define PARTICLE_CHANCE_CONSTANT 			(-20000000)
#define FUSION_RAD_MAX						2000
#define FUSION_RAD_COEFFICIENT				(-1000)
#define FUSION_INSTABILITY_ENDOTHERMALITY   2
#define FUSION_MAXIMUM_TEMPERATURE 1e8
// Snowflake fire product types
#define FIRE_PRODUCT_PLASMA 				0

// Freon — below 0°C (273.15 K) endothermic with O2, down to ~50 K; Proto-Nitrate catalyst up to 310 K; hot ice 120–160 K
#define FREON_MAXIMUM_BURN_TEMPERATURE		T0C
#define FREON_CATALYST_MAX_TEMPERATURE		310
#define FREON_LOWER_TEMPERATURE				60
#define FREON_TERMINAL_TEMPERATURE			50
#define FREON_HOT_ICE_MIN_TEMP				120
#define FREON_HOT_ICE_MAX_TEMP				160
#define FREON_OXYGEN_FULLBURN				10
#define FREON_BURN_RATE_DELTA				4
#define FIRE_FREON_ENERGY_CONSUMED			3e5
#define FREON_FORMATION_MIN_TEMPERATURE		(FIRE_MINIMUM_TEMPERATURE_TO_EXIST + 100)
#define FREON_FORMATION_ENERGY_CONSUMED		2e5
#define OXYGEN_BURN_RATIO_BASE				2

// Halon
/// Energy released per mole of BZ consumed during electrolytic halon formation.
#define HALON_FORMATION_ENERGY				91232.1
#define HALON_COMBUSTION_ENERGY				2500
#define HALON_COMBUSTION_MIN_TEMPERATURE		(T0C + 70)
#define HALON_COMBUSTION_TEMPERATURE_SCALE	(FIRE_MINIMUM_TEMPERATURE_TO_EXIST * 10)
#define HALON_COMBUSTION_MINIMUM_RESIN_MOLES	(0.99 * HALON_COMBUSTION_MIN_TEMPERATURE / HALON_COMBUSTION_TEMPERATURE_SCALE)

// Healium
#define HEALIUM_FORMATION_MIN_TEMP			25
#define HEALIUM_FORMATION_MAX_TEMP			300
#define HEALIUM_FORMATION_ENERGY				9000

// Zauker
#define ZAUKER_FORMATION_MIN_TEMPERATURE		50000
#define ZAUKER_FORMATION_MAX_TEMPERATURE	75000
#define ZAUKER_FORMATION_TEMPERATURE_SCALE	5e-6
#define ZAUKER_FORMATION_ENERGY				5000
#define ZAUKER_DECOMPOSITION_MAX_RATE		20
#define ZAUKER_DECOMPOSITION_ENERGY			460

// Nitrium
#define NITRIUM_FORMATION_MIN_TEMP			1500
#define NITRIUM_FORMATION_TEMP_DIVISOR		(FIRE_MINIMUM_TEMPERATURE_TO_EXIST * 8)
#define NITRIUM_FORMATION_ENERGY			100000
#define NITRIUM_DECOMPOSITION_MAX_TEMP		(T0C + 70)
#define NITRIUM_DECOMPOSITION_TEMP_DIVISOR	(FIRE_MINIMUM_TEMPERATURE_TO_EXIST * 8)
#define NITRIUM_DECOMPOSITION_ENERGY		30000

// Pluoxium formation (CO2 + O2 + Tritium)
#define PLUOXIUM_FORMATION_MIN_TEMP			50
#define PLUOXIUM_FORMATION_MAX_TEMP			T0C
#define PLUOXIUM_FORMATION_MAX_RATE			5
#define PLUOXIUM_FORMATION_ENERGY			250

// Proto-Nitrate
#define PN_FORMATION_MIN_TEMPERATURE			5000
#define PN_FORMATION_MAX_TEMPERATURE			10000
#define PN_FORMATION_ENERGY					650
#define PN_HYDROGEN_CONVERSION_THRESHOLD		150
#define PN_HYDROGEN_CONVERSION_MAX_RATE		5
#define PN_HYDROGEN_CONVERSION_ENERGY		2500
#define PN_TRITIUM_CONVERSION_MIN_TEMP		150
#define PN_TRITIUM_CONVERSION_MAX_TEMP		340
#define PN_TRITIUM_CONVERSION_ENERGY			10000
#define PN_BZASE_MIN_TEMP					260
#define PN_BZASE_MAX_TEMP					280
#define PN_BZASE_ENERGY						60000

// Antinoblium
#define ANTINOBLIUM_CONVERSION_DIVISOR		90
#define REACTION_OPPRESSION_MIN_TEMP			20

// Radiation gas conversions (see /datum/gas_mixture/react_to_radiation)
#define PLUOXIUM_RADIATION_CO2_DIVISOR		1000
#define PLUOXIUM_RADIATION_O2_DIVISOR		2000
#define PLUOXIUM_RADIATION_OUTPUT_DIVISOR	4000
#define HYDROGEN_IRRADIATION_DIVISOR		1000
