//
// HFR formula constants (what they scale: modifiers, heat, damage, thresholds)
//

///Speed of light, in m/s
#define LIGHT_SPEED 299792458
/// Scale factor for (LIGHT_SPEED**2) to avoid 32-bit float overflow: compute (c²/scale) then multiply by scale.
#define LIGHT_SPEED_SQ_SCALE 1e10
#define LIGHT_SPEED_SQ_SCALED (LIGHT_SPEED * LIGHT_SPEED / LIGHT_SPEED_SQ_SCALE)
///Calculation between the plank constant and the lambda of the lightwave
#define PLANCK_LIGHT_CONSTANT 2e-16
///Radius of the h2 calculated based on the amount of number of atom in a mole (and some addition for balancing issues)
#define CALCULATED_H2RADIUS 120e-4
///Radius of the trit calculated based on the amount of number of atom in a mole (and some addition for balancing issues)
#define CALCULATED_TRITRADIUS 230e-3
///Power conduction in the void, used to calculate the efficiency of the reaction
#define VOID_CONDUCTION 1e-2
/// Volume scaling for scaled_fuel/scaled_moderator lists (scale_factor = volume * this)
#define HFR_VOLUME_SCALE 0.5
/// Moderator gas counts toward gas_power at this fraction (fusion mix = 1.0)
#define HFR_MODERATOR_GAS_POWER_FRAC 0.75
/// Instability: current_damper contribution per 0.01
#define HFR_INSTABILITY_DAMPER_FACTOR 0.01
/// Instability: iron_content penalty per point
#define HFR_INSTABILITY_IRON_PENALTY 0.05
/// Modifier clamp min (power/heat), max 100
#define HFR_MODIFIER_CLAMP_MIN 0.25
#define HFR_MODIFIER_CLAMP_MAX 100
/// Radiation modifier clamp min
#define HFR_RADIATION_MODIFIER_MIN 0.005
#define HFR_RADIATION_MODIFIER_MAX 1000
/// Energy upper bound (float safety)
#define HFR_ENERGY_CLAMP_MAX 1e35
/// core_temperature from internal_power: divide by this
#define HFR_CORE_TEMP_DIVISOR 1000
/// Conduction: magnetic_constrictor multiplier (0.001 = 0.1% per point)
#define HFR_CONDUCTION_MAGNETIC_FACTOR 0.001
/// Radiation formula: Planck constant divisor (scale to usable range)
#define HFR_PLANCK_RADIATION_DIVISOR 5e-18
/// Heat limiter base: 5 * (10 ** power_level) * (heating_conductor/100)
#define HFR_HEAT_LIMITER_BASE 5
/// Heat output formula divisor (internal_instability * power_output * heat_modifier / this)
#define HFR_HEAT_OUTPUT_DIVISOR 200
/// Sanitize heat values for UI/sim (NaN/Inf rejected; negative values are valid for endothermic output)
#define HFR_SANITIZE_HEAT(heat) (isnum(heat) && (heat == heat) && (heat) >= -1e30 && (heat) <= 1e30 ? (heat) : 0)
/// Fuel consumption: fuel_injection_rate * this * power_level, then clamp
#define HFR_FUEL_CONSUMPTION_RATE_FACTOR (0.01 * 5)
#define HFR_FUEL_CONSUMPTION_CLAMP_MIN 0.05
#define HFR_FUEL_CONSUMPTION_CLAMP_MAX 30
/// Production at level 3/4: heat_output / this
#define HFR_PRODUCTION_HEAT_DIVISOR 1000
/// Production at other levels: heat_output * 2 / (10 ** (power_level+1))
#define HFR_PRODUCTION_HEAT_MULT 2
/// Fuel consumption in moderator_fuel_process: consumption_amount * this * fuel_consumption_multiplier
#define HFR_FUEL_CONSUMPTION_MULT 0.85
/// Primary product moles added per fuel_consumption
#define HFR_PRIMARY_PRODUCTION_FRAC 0.5
/// Heat limiter cooling: per-tick multiplier (heat_limiter_modifier * this * seconds_per_tick)
#define HFR_COOLING_PER_TICK_FACTOR 0.01
/// Evaporate moderator: (1 - (1 - this * power_level)^seconds_per_tick) fraction removed per tick
#define HFR_EVAPORATE_RATE_BASE 0.0005
/// Iron content damage: (round(iron_content)-1) * this * seconds_per_tick per point above 1
#define HFR_IRON_DAMAGE_PER_POINT 2.5
/// Healium heal: only when critical_threshold_proximity > this
#define HFR_HEALIUM_HEAL_PROXIMITY_THRESHOLD 400
/// Healium heal rate: (moderator_list[GAS_HEALIUM]/100) * this * melting_point * seconds_per_tick
#define HFR_HEALIUM_HEAL_RATE_FACTOR 0.0011
/// Antinoblium production temp threshold (K): below this or (plasma+BZ) condition
#define HFR_ANTINOBLIUM_TEMP_THRESHOLD 1e7
/// Overmole: moles above this trigger 2% integrity damage every 5 sec
#define HFR_OVERMOLE_MOLES 5000
/// Overmole: deciseconds between damage applications (5 sec)
#define HFR_OVERMOLE_INTERVAL_DS 50
/// Overmole: integrity damage per trigger (2% of melting_point)
#define HFR_OVERMOLE_DAMAGE_FRAC 0.02
/// Iron heal chance: 25 / (power_level+1) prob per tick when power_level <= 4
#define HFR_IRON_HEAL_CHANCE_DIVISOR 25
/// Iron passive decay when power_level <= 4: this * seconds_per_tick per tick
#define HFR_IRON_DECAY_RATE 0.01
/// Iron content clamp max
#define HFR_IRON_CONTENT_MAX 5
/// O2 iron heal: moderator_list[GAS_O2] > this to allow iron heal
#define HFR_IRON_HEAL_O2_THRESHOLD 150
/// Lightning/tesla: radiation_pulse range
#define HFR_LIGHTNING_RADIATION_RANGE 6
/// Lightning: only when moderator_list[GAS_ANTINOBLIUM] > this and proximity <= 500
#define HFR_LIGHTNING_ANTINOBLIUM_MIN 50
#define HFR_LIGHTNING_PROXIMITY_MAX 500

/// Fallback when no power / unanchored: default values written each tick
#define HFR_FALLBACK_MAGNETIC_CONSTRICTOR 100
#define HFR_FALLBACK_HEATING_CONDUCTOR 500
#define HFR_FALLBACK_CURRENT_DAMPER 0
#define HFR_FALLBACK_FUEL_INJECTION_RATE 200
#define HFR_FALLBACK_MODERATOR_INJECTION_RATE 500
/// Iron accumulation per second when no power
#define HFR_FALLBACK_IRON_RATE 0.10
/// Volume = internal_fusion.return_volume() * (magnetic_constrictor * this)
#define HFR_MAGNETIC_VOLUME_FRAC 0.01

///Mole count required (tritium/hydrogen) to start a fusion reaction in HFR (reactions.dm uses 250 for other fusion)
#define HFR_FUSION_MOLE_THRESHOLD 25
///Used to reduce the gas_power to a more useful amount
#ifndef INSTABILITY_GAS_POWER_FACTOR
#define INSTABILITY_GAS_POWER_FACTOR 0.003
#endif
///Used to calculate the toroidal_size for the instability
#ifndef TOROID_VOLUME_BREAKEVEN
#define TOROID_VOLUME_BREAKEVEN 1000
#endif
///Constant used when calculating the chance of emitting a radioactive particle
#ifndef PARTICLE_CHANCE_CONSTANT
#define PARTICLE_CHANCE_CONSTANT (-20000000)
#endif
///Conduction of heat inside the fusion reactor
#define METALLIC_VOID_CONDUCTIVITY 0.38
///Conduction of heat near the external cooling loop (output gases at 95% of moderator temp)
#define HIGH_EFFICIENCY_CONDUCTIVITY 0.95
///Sets the minimum amount of power the machine uses
#define MIN_POWER_USAGE (50 KILO WATTS)
///Sets the multiplier for the damage
#define DAMAGE_CAP_MULTIPLIER 0.005
/// Max overmole (5000+ moles) damage per 5-second trigger so huge melting_point doesn't overshoot (still subject to cap)
#define HYPERTORUS_OVERMOLE_MAX_ADD 50
///Sets the range of the hallucinations
#define HALLUCINATION_HFR(P) (min(7, round(abs(P) ** 0.25)))
///Chance in percentage points per fusion level of iron accumulation when operating at unsafe levels
#define IRON_CHANCE_PER_FUSION_LEVEL 17
///Amount of iron accumulated per second whenever we fail our saving throw, using the chance above
#define IRON_ACCUMULATED_PER_SECOND 0.005
///Maximum amount of iron that can be healed per second. Calculated to mostly keep up with fusion level 5.
#define IRON_OXYGEN_HEAL_PER_SECOND (IRON_ACCUMULATED_PER_SECOND * (100 - IRON_CHANCE_PER_FUSION_LEVEL) / 100)
///Amount of oxygen in moles required to fully remove 100% iron content. Currently about 2409mol. Calculated to consume at most 10mol/s.
#define OXYGEN_MOLES_CONSUMED_PER_IRON_HEAL (10 / IRON_OXYGEN_HEAL_PER_SECOND)

//If integrity percent remaining is less than these values, the monitor sets off the relevant alarm.
#define HYPERTORUS_MELTING_PERCENT 5
#define HYPERTORUS_EMERGENCY_PERCENT 25
#define HYPERTORUS_DANGER_PERCENT 50
#define HYPERTORUS_WARNING_PERCENT 100

#define WARNING_TIME_DELAY 60
///to prevent accent sounds from layering
#define HYPERTORUS_ACCENT_SOUND_MIN_COOLDOWN (3 SECONDS)

/// SFX keys for HFR ambient accents — datums below; assets under sound/machines/hypertorus/
#define SFX_HYPERTORUS_CALM "hypertorus_calm"
#define SFX_HYPERTORUS_MELTING "hypertorus_melting"

#define HYPERTORUS_COUNTDOWN_TIME (30 SECONDS)

//
// Damage source: Too much mass in the fusion mix at high fusion levels
//

#define HYPERTORUS_OVERFULL_MIN_POWER_LEVEL 5
#define HYPERTORUS_OVERFULL_MAX_SAFE_COLD_FUSION_MOLES 2700
#define HYPERTORUS_OVERFULL_MAX_SAFE_HOT_FUSION_MOLES 1800
#define HYPERTORUS_OVERFULL_MOLAR_SLOPE (1/80)
#define HYPERTORUS_OVERFULL_TEMPERATURE_SLOPE (HYPERTORUS_OVERFULL_MOLAR_SLOPE * (HYPERTORUS_OVERFULL_MAX_SAFE_COLD_FUSION_MOLES - HYPERTORUS_OVERFULL_MAX_SAFE_HOT_FUSION_MOLES) / (FUSION_MAXIMUM_TEMPERATURE - 1))
#define HYPERTORUS_OVERFULL_CONSTANT (-(HYPERTORUS_OVERFULL_MOLAR_SLOPE * HYPERTORUS_OVERFULL_MAX_SAFE_HOT_FUSION_MOLES + HYPERTORUS_OVERFULL_TEMPERATURE_SLOPE * FUSION_MAXIMUM_TEMPERATURE))

//
// Heal source: Small enough mass in the fusion mix
//

#define HYPERTORUS_SUBCRITICAL_MOLES 800
#define HYPERTORUS_SUBCRITICAL_SCALE 150

//
// Heal source: Cold enough coolant
//

#define HYPERTORUS_COLD_COOLANT_MAX_RESTORE 2.5
#define HYPERTORUS_COLD_COOLANT_THRESHOLD (10 ** 5)
#define HYPERTORUS_COLD_COOLANT_SCALE (HYPERTORUS_COLD_COOLANT_MAX_RESTORE / log(10, HYPERTORUS_COLD_COOLANT_THRESHOLD))

//
// Damage source: Iron content
//

#define HYPERTORUS_MAX_SAFE_IRON 0.35

//
// Damage source: Extreme levels of mass in fusion mix at any power level
//

#define HYPERTORUS_HYPERCRITICAL_MOLES 10000
#define HYPERTORUS_HYPERCRITICAL_SCALE 0.005
#define HYPERTORUS_HYPERCRITICAL_MAX_DAMAGE 40

#define HYPERTORUS_WEAK_SPILL_RATE 0.0005
#define HYPERTORUS_WEAK_SPILL_CHANCE 1
#define HYPERTORUS_MEDIUM_SPILL_PRESSURE 10000
#define HYPERTORUS_MEDIUM_SPILL_INITIAL 0.25
#define HYPERTORUS_MEDIUM_SPILL_RATE 0.01
#define HYPERTORUS_STRONG_SPILL_PRESSURE 12000
#define HYPERTORUS_STRONG_SPILL_INITIAL 0.75
#define HYPERTORUS_STRONG_SPILL_RATE 0.05

//
// Explosion flags for use in fuel recipes
//
#define HYPERTORUS_FLAG_BASE_EXPLOSION (1<<0)
#define HYPERTORUS_FLAG_MEDIUM_EXPLOSION (1<<1)
#define HYPERTORUS_FLAG_DEVASTATING_EXPLOSION (1<<2)
#define HYPERTORUS_FLAG_RADIATION_PULSE (1<<3)
#define HYPERTORUS_FLAG_EMP (1<<4)
#define HYPERTORUS_FLAG_MINIMUM_SPREAD (1<<5)
#define HYPERTORUS_FLAG_MEDIUM_SPREAD (1<<6)
#define HYPERTORUS_FLAG_BIG_SPREAD (1<<7)
#define HYPERTORUS_FLAG_MASSIVE_SPREAD (1<<8)
#define HYPERTORUS_FLAG_CRITICAL_MELTDOWN (1<<9)

///High power damage
#define HYPERTORUS_FLAG_HIGH_POWER_DAMAGE (1<<0)
///High fuel mix mole
#define HYPERTORUS_FLAG_HIGH_FUEL_MIX_MOLE (1<<1)
///iron content damage
#define HYPERTORUS_FLAG_IRON_CONTENT_DAMAGE (1<<2)
///Iron content increasing
#define HYPERTORUS_FLAG_IRON_CONTENT_INCREASE (1<<3)
///Emped hypertorus
#define HYPERTORUS_FLAG_EMPED (1<<4)

// Status for get_status()
#define HYPERTORUS_MELTING 1
#define HYPERTORUS_EMERGENCY 2
#define HYPERTORUS_DANGER 3
#define HYPERTORUS_WARNING 4
#define HYPERTORUS_NOMINAL 5
#define HYPERTORUS_INACTIVE 6

// BlueMoon compatibility (do not define zap/COMSIG here; supermatter.dm and modular define them)
#ifndef BASE_MACHINE_IDLE_CONSUMPTION
#define BASE_MACHINE_IDLE_CONSUMPTION 50
#endif
#ifndef ZAP_SUPERMATTER_FLAGS
#define ZAP_SUPERMATTER_FLAGS 0
#endif
#ifndef AREA_USAGE_ENVIRON
#define AREA_USAGE_ENVIRON ENVIRON
#endif

// Hypertorus accent sounds (Kovapa) — .ogg under sound/machines/hypertorus/

/datum/sound_effect/hypertorus_calm
	key = SFX_HYPERTORUS_CALM
	file_paths = list(
		'sound/machines/hypertorus/accent/calm/1.ogg',
		'sound/machines/hypertorus/accent/calm/2.ogg',
		'sound/machines/hypertorus/accent/calm/3.ogg',
	)

/datum/sound_effect/hypertorus_melting
	key = SFX_HYPERTORUS_MELTING
	file_paths = list(
		'sound/machines/hypertorus/accent/melting/1.ogg',
		'sound/machines/hypertorus/accent/melting/2.ogg',
		'sound/machines/hypertorus/accent/melting/3.ogg',
		'sound/machines/hypertorus/accent/melting/4.ogg',
	)
