//ATMOS
//stuff you should probably leave well alone!
#define R_IDEAL_GAS_EQUATION	8.31	//kPa*L/(K*mol)
#define ONE_ATMOSPHERE			101.325	//kPa
#define TCMB					2.7		// -270.3degC
#define TCRYO					225		// -48.15degC
#define T0C						273.15	// 0degC
#define T20C					293.15	// 20degC

#define MOLES_CELLSTANDARD		(ONE_ATMOSPHERE*CELL_VOLUME/(T20C*R_IDEAL_GAS_EQUATION))	//moles in a 2.5 m^3 cell at 101.325 Pa and 20 degC
#define M_CELL_WITH_RATIO		(MOLES_CELLSTANDARD * 0.005) //compared against for superconductivity
#define O2STANDARD				0.21	//percentage of oxygen in a normal mixture of air
#define N2STANDARD				0.79	//same but for nitrogen
#define MOLES_O2STANDARD		(MOLES_CELLSTANDARD*O2STANDARD)	// O2 standard value (21%)
#define MOLES_N2STANDARD		(MOLES_CELLSTANDARD*N2STANDARD)	// N2 standard value (79%)
#define CELL_VOLUME				2500	//liters in a cell
#define BREATH_VOLUME			0.5		//liters in a normal breath

//Ключи разобранной строки газа, см. SSair.get_parsed_gas_string()
#define GAS_STRING_TEMP			"temp"
#define GAS_STRING_MOLES		"moles"
///Потолок кэша разобранных строк. Карта укладывается в пару десятков ключей и
///разбирается на старте, а atmos_spawn_air() лепит строки на лету ("o2=[N];...") -
///их кэшировать бессмысленно, поэтому после потолка просто перестаём запоминать.
#define GAS_STRING_CACHE_LIMIT	512
#define BREATH_PERCENTAGE		(BREATH_VOLUME/CELL_VOLUME)					//Amount of air to take a from a tile

//EXCITED GROUPS
#define EXCITED_GROUP_BREAKDOWN_CYCLES				4		//number of FULL air controller ticks before an excited group breaks down (averages gas contents across turfs)
#define EXCITED_GROUP_DISMANTLE_CYCLES				16		//number of FULL air controller ticks before an excited group dismantles and removes its turfs from active
///Stalled cycles before a grouped turf rests individually (leaves the active list but stays in
///its group, see sleep_active_turf). Kept above EXCITED_GROUP_BREAKDOWN_CYCLES so an idling turf
///holds the group average through at least one more breakdown before it stops processing.
#define EXCITED_GROUP_INDIVIDUAL_REST_CYCLES		6
/// Maximum excited-group members processed between master-controller budget checks.
/// Breakdown keeps its accumulator and write-back state across SSair resumes.
#define EXCITED_GROUP_BREAKDOWN_SLICE				192
/// Small groups are cheaper and safer to finish atomically. Resumable state is
/// reserved for memberships large enough to threaten a server tick. Два среза:
/// на старом пороге в 1024 группа из ~1000 турфов усреднялась одним куском на
/// сотни миллисекунд - при станционном пожаре таких групп десятки.
#define EXCITED_GROUP_RESUMABLE_THRESHOLD			(EXCITED_GROUP_BREAKDOWN_SLICE * 2)
/// Excited-group size at which the zone equalizer engages even with the config
/// flag off. Pure LINDA diffusion cannot finish a single differential this
/// large in bounded time: the giant-hall bench (120x100 hall, 16:1 pressure
/// split) never settles and holds ~140ms/fire indefinitely without this valve.
#define EXCITED_GROUP_ZONE_EQUALIZE_THRESHOLD		1500
/// Sleeping edges: кэш осевших пар включается только после стольких тихих
/// фаеров турфа (atmos_cooldown на входе в process_cell). Активный фронт
/// разгерма не оседает и не хитует кэш - без этого гейта он платил лукап на
/// каждой паре каждый фаер: multi-breach A/B мерил +7-9% на нейборс-цикл.
#define ATMOS_EDGE_SLEEP_MIN_QUIET_FIRES			2
/// Перепад давления, при котором пара турфов с файрлоком в проёме захлопывает
/// створку прямо из парного шаринга (пер-парный consider_firelocks). Зонное
/// декомп-событие гейтится отдельно, по HAZARD_LOW_PRESSURE у кромки пробоины.
#define DECOMPRESSION_FIRELOCK_PRESSURE_DELTA		WARNING_LOW_PRESSURE
#define MINIMUM_AIR_RATIO_TO_SUSPEND				0.1		//Ratio of air that must move to/from a tile to reset group processing
#define MINIMUM_AIR_RATIO_TO_MOVE					0.001	//Minimum ratio of air that must move to/from a tile
#define MINIMUM_AIR_TO_SUSPEND						(MOLES_CELLSTANDARD*MINIMUM_AIR_RATIO_TO_SUSPEND)	//Minimum amount of air that has to move before a group processing can be suspended
#define MINIMUM_MOLES_DELTA_TO_MOVE					(MOLES_CELLSTANDARD*MINIMUM_AIR_RATIO_TO_MOVE) //Either this must be active
///Content-relative floor for the share-significance gates: movement below this fraction of a tile's
///contents never counts as significant, so 100+ atm supply tanks don't stay excited forever from
///sub-percent machinery ripple. Deliberately far below MINIMUM_AIR_RATIO_TO_SUSPEND: real
///decompression flows on high-mole tiles (canister floods) must still reset the group cooldowns,
///or excited group breakdown averages the flood flat mid-flow (stepwise gas movement, no winds).
#define SIGNIFICANT_SHARE_CONTENT_RATIO				0.01
#define MINIMUM_TEMPERATURE_TO_MOVE					(T20C+100)			//or this (or both, obviously)
#define MINIMUM_TEMPERATURE_DELTA_TO_SUSPEND		4		//Minimum temperature difference before group processing is suspended
#define MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER		0.5		//Minimum temperature difference before the gas temperatures are just set to be equal
#define MINIMUM_TEMPERATURE_FOR_SUPERCONDUCTION		(T20C+10)
#define MINIMUM_TEMPERATURE_START_SUPERCONDUCTION	(T20C+200)
#define MINIMUM_HEAT_CAPACITY	0.0003

//PLANETARY ATMOS
#define PLANET_SHARE_RATIO							0.8		//Ratio of the difference a planetary turf shares with its template atmosphere each cycle
#define PLANET_SHARE_TEMPERATURE_CAPACITY			5		//Template heat capacity multiplier for the follow-up conductive temperature share, simulating a large atmosphere above the turf

//HEAT TRANSFER COEFFICIENTS
//Must be between 0 and 1. Values closer to 1 equalize temperature faster
//Should not exceed 0.4 else strange heat flow occur
#define WALL_HEAT_TRANSFER_COEFFICIENT		0.0
#define OPEN_HEAT_TRANSFER_COEFFICIENT		0.4
#define WINDOW_HEAT_TRANSFER_COEFFICIENT	0.1		//a hack for now
#define HEAT_CAPACITY_VACUUM				7000	//a hack to help make vacuums "cold", sacrificing realism for gameplay

//SSair FIRE CADENCE - the atmos speed lever and the adaptive lag valve
/// Slowest the operator lever may run atmos; below this the lever would be a way
/// to freeze the simulation from config.
#define ATMOS_SPEED_MULTIPLIER_MIN			0.25
/// Fastest the operator lever may ask for. The cadence saturates one tick apart
/// well before this, so the ceiling is only a guard against silly config values.
#define ATMOS_SPEED_MULTIPLIER_MAX			20
/// Time dilation (percent) at which the valve starts slowing atmos down.
#define ATMOS_LAG_VALVE_DILATION			20
/// Time dilation (percent) at which the valve backs atmos off hard.
#define ATMOS_LAG_VALVE_SEVERE_DILATION		40
#define ATMOS_LAG_VALVE_SCALE				0.75
#define ATMOS_LAG_VALVE_SEVERE_SCALE		0.5
/// How far below the compiled cadence the valve may drag the subsystem.
#define ATMOS_CADENCE_SLOWEST_FACTOR		4
/// Насколько адаптивные клапаны вправе замедлить газ относительно текущей
/// настроенной скорости. Ступень 0.5 у лестницы это ровно вдвое; потолок назван
/// отдельно и зажимается в apply_atmos_cadence(), чтобы правка лестницы не смогла
/// его тихо пробить. Рычаг оператора это ограничение не трогает - он про
/// осознанную настройку, а не про автоматику под нагрузкой.
#define ATMOS_VALVE_SLOWEST_FACTOR			2

// SSair SATURATION VALVE
//
// Time dilation cannot see a saturated SS_BACKGROUND subsystem. MC_TICK_CHECK
// makes SSair yield exactly at the tick budget, so the MC keeps its frame rate
// and the dilation counters stay near zero while atmos eats 40-80% of every
// tick. Round 9860 (station-wide plasma flood, 90 minutes, SSair resumed almost
// every tick) peaked at 8.95% dilation against a 20% valve threshold: the lag
// valve never opened once. The subsystem's own pass length is the only signal
// that can see this, and cost_full already measures it.
/// Доля НОМИНАЛЬНОГО интервала, которую завершённый проход вправе занять по
/// РЕАЛЬНОМУ времени, прежде чем клапан шагнёт вниз. 1 означает "проход ровно
/// съел свой слот". Отсчёт ведётся от initial(wait), а не от текущего: текущий
/// интервал - это собственный выход клапана, и отсчёт от него делал порог
/// отпускания выше порога срабатывания, то есть гистерезис был перевёрнут.
#define ATMOS_SATURATION_ENGAGE_RATIO		1
/// Доля, ниже которой проход должен опуститься, чтобы клапан отдал ступень назад.
/// Зазор до порога срабатывания и есть гистерезис.
#define ATMOS_SATURATION_RELEASE_RATIO		0.8
/// Сколько завершённых проходов подряд должны согласиться, прежде чем клапан
/// двинется. Один длинный проход (слив канистры, взрыв) не вправе переставить
/// каденс всей подсистемы. Полоса гистерезиса гасит накопленный голос по единице
/// за проход, а не обнуляет: обнуление означало, что нагрузка, качающаяся вокруг
/// порога, не накапливалась вообще никогда.
#define ATMOS_SATURATION_VOTES				3
/// Ниже этого стоимость фазы считается нулевой. MC_AVERAGE(x, 0) в 32-битных
/// float до нуля не доходит - около 2.8e-45 умножение на 0.8 округляется обратно
/// в себя, и колонка навсегда застревает на денормале вместо честного нуля.
#define ATMOS_COST_ZERO_EPSILON				0.001

//FIRE
#define FIRE_MINIMUM_TEMPERATURE_TO_SPREAD	(150+T0C)
#define FIRE_MINIMUM_TEMPERATURE_TO_EXIST	(100+T0C)
#define FIRE_SPREAD_RADIOSITY_SCALE			0.85
/// Floor for the flameless exposure path (/datum/element/atmos_sensitive). Atoms
/// whose flame-contact threshold sits below this keep it for direct contact but
/// only enroll for hot-air processing once the room is hot enough to burn on its
/// own: our lavaland ambient is 315-320 K, so a literal 300 K gate would cook ash
/// walker nests and ignite plasma structures with no fire anywhere in sight.
#define ATMOS_EXPOSURE_MINIMUM_TEMPERATURE	FIRE_MINIMUM_TEMPERATURE_TO_EXIST
#define FIRE_GROWTH_RATE					40000	//For small fires
#define PLASMA_MINIMUM_BURN_TEMPERATURE		(100+T0C)
#define PLASMA_UPPER_TEMPERATURE			(1370+T0C)
#define PLASMA_OXYGEN_FULLBURN				10

//GASES
#define MIN_TOXIC_GAS_DAMAGE				1
#define MAX_TOXIC_GAS_DAMAGE				10
#define MOLES_GAS_VISIBLE					0.25	//Moles in a standard cell after which gases are visible
#define FACTOR_GAS_VISIBLE_MAX				20 //moles_visible * FACTOR_GAS_VISIBLE_MAX = Moles after which gas is at maximum visibility
#define MOLES_GAS_VISIBLE_STEP				0.25 //Mole step for alpha updates. This means alpha can update at 0.25, 0.5, 0.75 and so on

//REACTIONS
//return values for reactions (bitflags)
#define NO_REACTION		0
#define REACTING		1
#define STOP_REACTIONS 	2
/// The tile hosts a volatile reaction (a live fire/hotspot): excited group
/// breakdown must not average the burn away mid-reaction (tg port).
#define VOLATILE_REACTION	4
/// How long a volatile reaction may defer settled-member bookkeeping. At the
/// ceiling a volatile group runs evict_settled_members() - NOT the averaging
/// self_breakdown (which would smear fuel and heat of a long burn across the
/// whole group) - so perpetual fires keep the giant-group churn control the
/// ordinary breakdown provides without the fire being touched.
#define EXCITED_GROUP_VOLATILE_BREAKDOWN_CEILING	(EXCITED_GROUP_BREAKDOWN_CYCLES * 4)

// Exact pressure solver for pumps (tg port, see gas_pressure_calculate)
/// Molar accuracy target of the Newton-Raphson fallback solver.
#define MOLAR_ACCURACY 1e-4
/// Iteration cap of the Newton-Raphson fallback solver.
#define ATMOS_PRESSURE_APPROXIMATION_ITERATIONS 20
/// Float slack added to the solver's analytic mole bounds.
#define ATMOS_PRESSURE_ERROR_TOLERANCE 0.01

// Pressure limits.
#define HAZARD_HIGH_PRESSURE				550		//This determins at what pressure the ultra-high pressure red icon is displayed. (This one is set as a constant)
#define WARNING_HIGH_PRESSURE				325		//This determins when the orange pressure icon is displayed (it is 0.7 * HAZARD_HIGH_PRESSURE)
#define WARNING_LOW_PRESSURE				50		//This is when the gray low pressure icon is displayed. (it is 2.5 * HAZARD_LOW_PRESSURE)
#define HAZARD_LOW_PRESSURE					20		//This is when the black ultra-low pressure icon is displayed. (This one is set as a constant)

#define TEMPERATURE_DAMAGE_COEFFICIENT		1.5		//This is used in handle_temperature_damage() for humans, and in reagents that affect body temperature. Temperature damage is multiplied by this amount.

#define SYNTH_PASSIVE_HEAT_GAIN 10							//Degrees C per handle_environment() Synths passively heat up. Mitigated by cooling efficiency. Can lead to overheating if not managed.
#define SYNTH_MAX_PASSIVE_GAIN_TEMP 250						//Degrees C that a synth can be heated up to by their internal heat gain, provided their cooling is insufficient to mitigate it.
#define SYNTH_MIN_PASSIVE_COOLING_TEMP -30					//Degrees C a synth can cool towards at very high cooling efficiency.
#define SYNTH_HEAT_EFFICIENCY_COEFF 0.005					//How quick the difference between the Synth and the environment starts to matter. The smaller the higher the difference has to be for the same change.
#define SYNTH_SINGLE_INFLUENCE_COOLING_EFFECT_CAP 3			//How big can the multiplier for heat / pressure cooling be in an optimal environment
#define SYNTH_TOTAL_ENVIRONMENT_EFFECT_CAP 2				//How big of an multiplier can the environment give in an optimal scenario (maximum efficiency in the end is at a lower cap, this mostly counters low coolant levels)
#define SYNTH_MAX_COOLING_EFFICIENCY 1.5					//The maximum possible cooling efficiency one can achieve at optimal conditions.
#define SYNTH_ACTIVE_COOLING_TEMP_BOUNDARY 10				//The minimum distance from room temperature a Synth needs to have for active cooling to actively cool.
#define SYNTH_ACTIVE_COOLING_LOW_PRESSURE_THRESHOLD 0.05	//At how much percentage of default pressure (or lower) active cooling gets a massive cost penalty.
#define SYNTH_ACTIVE_COOLING_LOW_PRESSURE_PENALTY 2.5		//By how much is active cooling cost multiplied if in a very-low-pressure environment?
#define SYNTH_ACTIVE_COOLING_MIN_ADJUSTMENT 5				//What is the minimum amount of temp you move towards the target point, even if it would be less with default calculations?
#define SYNTH_INTEGRATION_COOLANT_PENALTY 0.4				//Integrating coolant is multiplied with this for calculation of impact on passive cooling.
#define SYNTH_INTEGRATION_COOLANT_CAP 0.25					//Integrating coolant is capped at counting as current_blood * this number. This is so you can't just run on salglu or whatever.
#define SYNTH_COLD_OFFSET -125								//How much colder temps Synths can tolerate. Used in their species.

#define BODYTEMP_NORMAL						310.15			//The natural temperature for a body
#define BODYTEMP_AUTORECOVERY_DIVISOR		11		//This is the divisor which handles how much of the temperature difference between the current body temperature and 310.15K (optimal temperature) humans auto-regenerate each tick. The higher the number, the slower the recovery. This is applied each tick, so long as the mob is alive.
#define BODYTEMP_AUTORECOVERY_MINIMUM		12		//Minimum amount of kelvin moved toward 310K per tick. So long as abs(310.15 - bodytemp) is more than 50.
#define BODYTEMP_COLD_DIVISOR				6		//Similar to the BODYTEMP_AUTORECOVERY_DIVISOR, but this is the divisor which is applied at the stage that follows autorecovery. This is the divisor which comes into play when the human's loc temperature is lower than their body temperature. Make it lower to lose bodytemp faster.
#define BODYTEMP_HEAT_DIVISOR				15		//Similar to the BODYTEMP_AUTORECOVERY_DIVISOR, but this is the divisor which is applied at the stage that follows autorecovery. This is the divisor which comes into play when the human's loc temperature is higher than their body temperature. Make it lower to gain bodytemp faster.
#define BODYTEMP_COOLING_MAX				-100		//The maximum number of degrees that your body can cool in 1 tick, due to the environment, when in a cold area.
#define BODYTEMP_HEATING_MAX				30		//The maximum number of degrees that your body can heat up in 1 tick, due to the environment, when in a hot area.

#define BODYTEMP_HEAT_DAMAGE_LIMIT			(BODYTEMP_NORMAL + 20) // The limit the human body can take before it starts taking damage from heat. //CITADEL EDIT to 20
#define BODYTEMP_COLD_DAMAGE_LIMIT			(BODYTEMP_NORMAL - 50) // The limit the human body can take before it starts taking damage from coldness.
#define BODYTEMP_FROZEN_THRESHOLD		154		//Below this temperature, dead body tissue stops taking cold damage (effectively frozen/preserved)

/// Passive heat exchange / temp HUD: standing under freezing spray behaves like icy water, not like the hallway's air temperature.
#define SHOWER_FREEZING_LOCAL_TEMP (T0C - 10)
/// Passive heat exchange / temp HUD under a boiling-water shower (steam dominates over cool air).
#define SHOWER_BOILING_LOCAL_TEMP (T0C + 55)

#define SPACE_HELM_MIN_TEMP_PROTECT			2.0		//what min_cold_protection_temperature is set to for space-helmet quality headwear. MUST NOT BE 0.
#define SPACE_HELM_MAX_TEMP_PROTECT			1500	//Thermal insulation works both ways /Malkevin
#define SPACE_SUIT_MIN_TEMP_PROTECT			2.0		//what min_cold_protection_temperature is set to for space-suit quality jumpsuits or suits. MUST NOT BE 0.
#define SPACE_SUIT_MAX_TEMP_PROTECT			1500

#define FIRE_SUIT_MIN_TEMP_PROTECT			60		//Cold protection for firesuits
#define FIRE_SUIT_MAX_TEMP_PROTECT			30000	//what max_heat_protection_temperature is set to for firesuit quality suits. MUST NOT BE 0.
#define FIRE_HELM_MIN_TEMP_PROTECT			60		//Cold protection for fire helmets
#define FIRE_HELM_MAX_TEMP_PROTECT			30000	//for fire helmet quality items (red and white hardhats)

#define FIRE_IMMUNITY_MAX_TEMP_PROTECT	35000		//what max_heat_protection_temperature is set to for firesuit quality suits and helmets. MUST NOT BE 0.

#define HELMET_MIN_TEMP_PROTECT				160		//For normal helmets
#define HELMET_MAX_TEMP_PROTECT				600		//For normal helmets
#define ARMOR_MIN_TEMP_PROTECT				160		//For armor
#define ARMOR_MAX_TEMP_PROTECT				600		//For armor

#define GLOVES_MIN_TEMP_PROTECT				2.0		//For some gloves (black and)
#define GLOVES_MAX_TEMP_PROTECT				1500	//For some gloves
#define SHOES_MIN_TEMP_PROTECT				2.0		//For gloves
#define SHOES_MAX_TEMP_PROTECT				1500	//For gloves
#define COAT_MAX_TEMP_PROTECT				330     //For winter coats (if they can stop you from getting cold why can't they do it the other way to a lesser extent)

#define PRESSURE_DAMAGE_COEFFICIENT			4		//The amount of pressure damage someone takes is equal to (pressure / HAZARD_HIGH_PRESSURE)*PRESSURE_DAMAGE_COEFFICIENT, with the maximum of MAX_PRESSURE_DAMAGE
#define MAX_HIGH_PRESSURE_DAMAGE			16		// CITADEL CHANGES Max to 16, low to 8.
#define LOW_PRESSURE_DAMAGE					12		//The amount of damage someone takes when in a low pressure area (The pressure threshold is so low that it doesn't make sense to do any calculations, so it just applies this flat value).

#define COLD_SLOWDOWN_FACTOR				35		//Humans are slowed by the difference between bodytemp and BODYTEMP_COLD_DAMAGE_LIMIT divided by this

//PIPES
//Atmos pipe limits
#define MAX_OUTPUT_PRESSURE					4500 // (kPa) What pressure pumps and powered equipment max out at.
#define MAX_TRANSFER_RATE					200 // (L/s) Maximum speed powered equipment can work at.

//used for device_type vars
#define UNARY		1
#define BINARY 		2
#define TRINARY		3
#define QUATERNARY	4

//TANKS
#define TANK_MELT_TEMPERATURE				1000000	//temperature in kelvins at which a tank will start to melt
#define TANK_LEAK_PRESSURE					(30.*ONE_ATMOSPHERE)	//Tank starts leaking
#define TANK_RUPTURE_PRESSURE				(35.*ONE_ATMOSPHERE)	//Tank spills all contents into atmosphere
#define TANK_FRAGMENT_PRESSURE				(40.*ONE_ATMOSPHERE)	//Boom 3x3 base explosion
#define TANK_FRAGMENT_SCALE	    			(6.*ONE_ATMOSPHERE)		//+1 for each SCALE kPa aboe threshold
#define TANK_MAX_RELEASE_PRESSURE 			(ONE_ATMOSPHERE*3)
#define TANK_MIN_RELEASE_PRESSURE 			0
#define TANK_DEFAULT_RELEASE_PRESSURE 		17

// Trace plasma should not turn routine waste handling into a hidden clothing
// tax. These values make contamination a sustained exposure hazard.
#define PLASMA_CLOTHING_MIN_PARTIAL_PRESSURE 5
#define PLASMA_CLOTHING_MAX_CONTAMINATION 100
/// Fabric at or below this permeability is treated as sealed against plasma,
/// both for absorbing it and for shielding the layer worn underneath.
#define PLASMA_CLOTHING_SEALED_PERMEABILITY 0.02

/// Minimum time between full decompression alarm sweeps of one base area.
/// Raw deciseconds (30 seconds): expanded inside native_atmos_bindings.dm,
/// which is included before the SECONDS macro exists.
#define DECOMPRESSION_AREA_ALARM_COOLDOWN 300

/// Подтверждающее окно декомп-тревоги в фаерах SSair: зона попадает в очередь
/// тревоги, только если перевзвелась более поздним фаером не дальше этого окна
/// от первого замера. Настоящая пробоина перевзводится каждый фаер, пока кромку
/// кормят соседи; одноразовый пшик (цикл наружного шлюза, мгновенно осушенный
/// карман) до тревоги не доезжает. Сырые фаеры, не время: разворачивается в
/// native_atmos_bindings.dm до макросов времени.
#define DECOMPRESSION_PENDING_WINDOW_FIRES 10

/// Температура воздуха, на которой срабатывают беспламенные детекторы жара:
/// пожарная сигнализация поднимает тревогу зоны, файрлок зажигает горячую лампу
/// и закрывается. Порог один на оба, иначе между ними остаётся полоса, в которой
/// двери захлопываются, а сирены и тревоги зоны нет - и сбрасывать экипажу
/// нечего.
#define ATMOS_HEAT_ALARM_TEMPERATURE (T0C + 200)

/// Насколько воздух должен остыть ниже порога, чтобы беспламенная тревога
/// взвелась заново. Без неё зал, который греют намеренно (турбина, камера
/// сгорания), поднимает тревогу каждый кулдаун до конца раунда.
#define ATMOS_HEAT_ALARM_HYSTERESIS 20

#define FIRELOCK_ALARM_TYPE_HOT "firelock_alarm_type_hot"
#define FIRELOCK_ALARM_TYPE_COLD "firelock_alarm_type_cold"
#define FIRELOCK_ALARM_TYPE_GENERIC "firelock_alarm_type_generic"

/// Температура, ниже которой файрлок зажигает холодную лампу. Это ПРЕДУПРЕЖДЕНИЕ,
/// а не команда закрыться: холод сам по себе двери больше не хлопает (см.
/// firelock_alarm_seals()). Порог по телу человека (260 K) для лампы не годится -
/// половина станции холоднее по устройству: телекомы мапятся при 80 K
/// (TCOMMS_ATMOS), холодильник кухни при 259 K (KITCHEN_COLDROOM_ATMOS), снег
/// при 180 K (FROZEN_ATMOS). Лампа, которая горит всегда, не сообщает ничего.
#define FIRELOCK_COLD_ALARM_TEMPERATURE (T0C - 40)

/// Полоса возврата температурной тревоги файрлока, в кельвинах. Взведённая
/// тревога снимается только когда турф ушёл за свой порог на эту величину:
/// на одном пороге турф у кромки пожара пересекает границу по нескольку раз
/// в секунду, а каждый переход перерисовывает лампы всей группы и хлопает
/// дверью со звуком.
#define FIRELOCK_ALARM_TEMPERATURE_HYSTERESIS 10

/// Сколько дверь держится открытой после того, как её вскрыли ломом или ручным
/// приводом. Шести секунд хватало ровно на то, чтобы створка захлопнулась на
/// человеке в проёме при следующем же переходе тревоги.
#define FIRELOCK_MANUAL_OVERRIDE_GRACE (20 SECONDS)

/// Как часто закрытая автоматикой дверь перепроверяет, не отпала ли причина
/// закрытия. Пересчёт тревоги ходит только по фронту, а закрытия от зоны и от
/// разгерметизации фронта не создают вовсе - без этой проверки такая дверь
/// оставалась закрытой до конца смены, с пустой тревогой и погашенной лампой.
#define FIRELOCK_AUTO_REOPEN_RETRY (10 SECONDS)

/// Разброс, добавляемый к каждому перевзводу проверки переоткрытия. Двери,
/// закрытые одной волной разгерметизации, без него ретраились все в один тик
/// каждые десять секунд до конца пожара - сотни is_holding_pressure() разом.
#define FIRELOCK_AUTO_REOPEN_JITTER (4 SECONDS)

/// Сколько предметов один турф может сдвинуть за проход фазы high-pressure.
/// MC_TICK_CHECK стоит только между турфами, и завал из сотен предметов после
/// взрыва обрабатывался атомарным куском по 300+мс (раунд 9911). Остаток кучи
/// дожуют следующие проходы: ветер держит турф в очереди, пока перепад жив.
#define HIGH_PRESSURE_MOVES_PER_TURF 40

/// Пауза между визуалами ветра на одном турфе, равна длительности анимации
/// самого визуала: затяжная разгерметизация создавала новый поверх ещё живого
/// каждый проход SSair и раздувала очередь GC.
#define SPACE_WIND_VISUAL_COOLDOWN (2 SECONDS)

/// Перепад ДАВЛЕНИЯ в кПа, начиная с которого дверь считается удерживающей
/// разгерметизацию. Раньше сравнивались моли с порогом 20, а моль зависит и от
/// температуры: горячая комната при том же давлении содержит их меньше, и
/// закрывшийся по жару файрлок рапортовал перепад там, где давление было
/// одинаковым с обеих сторон. 20 кПа - это те же 20 молей при комнатных 293 K,
/// то есть чувствительность к настоящей разгерметизации не изменилась.
#define DOOR_PRESSURE_DIFFERENCE_TOLERANCE 20

#define MERGE_TURF_PACKET_DIR 1
#define MERGE_TURF_PACKET_ATOMS 2
#define TANK_POST_FRAGMENT_REACTIONS		5

//CANATMOSPASS
#define ATMOS_PASS_YES 1
#define ATMOS_PASS_NO 0
#define ATMOS_PASS_PROC -1 //ask CanAtmosPass()
#define ATMOS_PASS_DENSITY -2 //just check density

// Adjacency flags
#define ATMOS_ADJACENT_ANY		(1<<0)
#define ATMOS_ADJACENT_FIRELOCK	(1<<1)

#ifdef TESTING
GLOBAL_LIST_INIT(atmos_adjacent_savings, list(0,0))
#define CALCULATE_ADJACENT_TURFS(T) if (SSadjacent_air.queue[T]) { GLOB.atmos_adjacent_savings[1] += 1 } else { GLOB.atmos_adjacent_savings[2] += 1; SSadjacent_air.queue[T] = 1 }
#else
#define CALCULATE_ADJACENT_TURFS(T) SSadjacent_air.queue[T] = 1
#endif

#define CANATMOSPASS(A, O) ( A.CanAtmosPass == ATMOS_PASS_PROC ? A.CanAtmosPass(O) : ( A.CanAtmosPass == ATMOS_PASS_DENSITY ? !A.density : A.CanAtmosPass ) )
#define CANVERTICALATMOSPASS(A, O) ( A.CanAtmosPassVertical == ATMOS_PASS_PROC ? A.CanAtmosPass(O, TRUE) : ( A.CanAtmosPassVertical == ATMOS_PASS_DENSITY ? !A.density : A.CanAtmosPassVertical ) )

//OPEN TURF ATMOS
#define OPENTURF_DEFAULT_ATMOS		"o2=21.78;n2=82.36;TEMP=293.15" //the default air mix that open turfs spawn, also is what the station vents output at assuming a 21/79% o2/n2 mix
#define TCOMMS_ATMOS				"n2=100;TEMP=80" //-193,15degC telecommunications. also used for xenobiology slime killrooms
#define AIRLESS_ATMOS				"TEMP=2.7" //space
#define FROZEN_ATMOS				"o2=21.78;n2=82.36;TEMP=180" //-93.15degC snow and ice turfs
#define BURNMIX_ATMOS				"o2=2500;plasma=5000;TEMP=370" //used in the holodeck burn test program

/// -14°C kitchen coldroom, just might loss your tail; higher amount of mol to reach about 101.3 kpA
#define KITCHEN_COLDROOM_ATMOS "o2=26;n2=97;TEMP=259.15"

//ATMOSPHERICS DEPARTMENT GAS TANK TURFS
#define ATMOS_TANK_N2O				"n2o=6000;TEMP=293.15"
#define ATMOS_TANK_CO2				"co2=50000;TEMP=293.15"
#define ATMOS_TANK_PLASMA			"plasma=70000;TEMP=293.15"
#define ATMOS_TANK_O2				"o2=100000;TEMP=293.15"
#define ATMOS_TANK_N2				"n2=100000;TEMP=293.15"
#define ATMOS_TANK_AIRMIX			"o2=2811;n2=10583;TEMP=293.15"

//LAVALAND
#define LAVALAND_EQUIPMENT_EFFECT_PRESSURE 50 //what pressure you have to be under to increase the effect of equipment meant for lavaland
#define LAVALAND_DEFAULT_ATMOS "LAVALAND_ATMOS"

//SNOSTATION
#define ICEMOON_DEFAULT_ATMOS "ICEMOON_ATMOS"

//FESTIVESTATION
#define FESTIVE_ATMOS "o2=22;n2=82;TEMP=266" //this goes here right putnam??

//ATMOSIA GAS MONITOR TAGS
#define ATMOS_GAS_MONITOR_INPUT_O2 "o2_in"
#define ATMOS_GAS_MONITOR_OUTPUT_O2 "o2_out"
#define ATMOS_GAS_MONITOR_SENSOR_O2 "o2_sensor"

#define ATMOS_GAS_MONITOR_INPUT_TOX "tox_in"
#define ATMOS_GAS_MONITOR_OUTPUT_TOX "tox_out"
#define ATMOS_GAS_MONITOR_SENSOR_TOX "tox_sensor"

#define ATMOS_GAS_MONITOR_INPUT_AIR "air_in"
#define ATMOS_GAS_MONITOR_OUTPUT_AIR "air_out"
#define ATMOS_GAS_MONITOR_SENSOR_AIR "air_sensor"

#define ATMOS_GAS_MONITOR_INPUT_MIX "mix_in"
#define ATMOS_GAS_MONITOR_OUTPUT_MIX "mix_out"
#define ATMOS_GAS_MONITOR_SENSOR_MIX "mix_sensor"

#define ATMOS_GAS_MONITOR_INPUT_N2O "n2o_in"
#define ATMOS_GAS_MONITOR_OUTPUT_N2O "n2o_out"
#define ATMOS_GAS_MONITOR_SENSOR_N2O "n2o_sensor"

#define ATMOS_GAS_MONITOR_INPUT_N2 "n2_in"
#define ATMOS_GAS_MONITOR_OUTPUT_N2 "n2_out"
#define ATMOS_GAS_MONITOR_SENSOR_N2 "n2_sensor"

#define ATMOS_GAS_MONITOR_INPUT_CO2 "co2_in"
#define ATMOS_GAS_MONITOR_OUTPUT_CO2 "co2_out"
#define ATMOS_GAS_MONITOR_SENSOR_CO2 "co2_sensor"

#define ATMOS_GAS_MONITOR_INPUT_INCINERATOR "incinerator_in"
#define ATMOS_GAS_MONITOR_OUTPUT_INCINERATOR "incinerator_out"
#define ATMOS_GAS_MONITOR_SENSOR_INCINERATOR "incinerator_sensor"

#define ATMOS_GAS_MONITOR_INPUT_TOXINS_LAB "toxinslab_in"
#define ATMOS_GAS_MONITOR_OUTPUT_TOXINS_LAB "toxinslab_out"
#define ATMOS_GAS_MONITOR_SENSOR_TOXINS_LAB "toxinslab_sensor"

#define ATMOS_GAS_MONITOR_LOOP_DISTRIBUTION "distro-loop_meter"
#define ATMOS_GAS_MONITOR_LOOP_ATMOS_WASTE "atmos-waste_loop_meter"

#define ATMOS_GAS_MONITOR_WASTE_ENGINE "engine-waste_out"
#define ATMOS_GAS_MONITOR_WASTE_ATMOS "atmos-waste_out"

//BlueMoon Edit Begin.
#define INCINERATOR_TARKOFF_IGNITER "tarkoff_igniter"
#define INCINERATOR_TARKOFF_DP_VENTPUMP "tarkoff_airlock_pump"
#define INCINERATOR_TARKOFF_AIRLOCK_SENSOR "tarkoff_airlock_sensor"
#define INCINERATOR_TARKOFF_AIRLOCK_CONTROLLER "tarkoff_airlock_controller"
#define INCINERATOR_TARKOFF_AIRLOCK_INTERIOR "tarkoff_airlock_interior"
#define INCINERATOR_TARKOFF_AIRLOCK_EXTERIOR "tarkoff_airlock_exterior"

#define ATMOS_GAS_MONITOR_TARKOFF_O2 "tarkoff_o2"
#define ATMOS_GAS_MONITOR_TARKOFF_PLAS "tarkoff_plas"
#define ATMOS_GAS_MONITOR_TARKOFF_MIX "tarkoff_mix"
#define ATMOS_GAS_MONITOR_TARKOFF_N2 "tarkoff_n2"
#define ATMOS_GAS_MONITOR_TARKOFF_N2O "tarkoff_n2o"
#define ATMOS_GAS_MONITOR_TARKOFF_CO2 "tarkoff_co2"
#define ATMOS_GAS_MONITOR_TARKOFF_INCINERATOR "tarkoff_incinerator"

//AIRLOCK CONTROLLER TAGS

//RnD toxins burn chamber
#define INCINERATOR_TOXMIX_IGNITER 				"toxmix_igniter"
#define INCINERATOR_TOXMIX_VENT 				"toxmix_vent"
#define INCINERATOR_TOXMIX_DP_VENTPUMP			"toxmix_airlock_pump"
#define INCINERATOR_TOXMIX_AIRLOCK_SENSOR 		"toxmix_airlock_sensor"
#define INCINERATOR_TOXMIX_AIRLOCK_CONTROLLER 	"toxmix_airlock_controller"
#define INCINERATOR_TOXMIX_AIRLOCK_INTERIOR 	"toxmix_airlock_interior"
#define INCINERATOR_TOXMIX_AIRLOCK_EXTERIOR 	"toxmix_airlock_exterior"

//Atmospherics/maintenance incinerator
#define INCINERATOR_ATMOS_IGNITER 				"atmos_incinerator_igniter"
#define INCINERATOR_ATMOS_MAINVENT 				"atmos_incinerator_mainvent"
#define INCINERATOR_ATMOS_AUXVENT 				"atmos_incinerator_auxvent"
#define INCINERATOR_ATMOS_DP_VENTPUMP			"atmos_incinerator_airlock_pump"
#define INCINERATOR_ATMOS_AIRLOCK_SENSOR 		"atmos_incinerator_airlock_sensor"
#define INCINERATOR_ATMOS_AIRLOCK_CONTROLLER	"atmos_incinerator_airlock_controller"
#define INCINERATOR_ATMOS_AIRLOCK_INTERIOR 		"atmos_incinerator_airlock_interior"
#define INCINERATOR_ATMOS_AIRLOCK_EXTERIOR 		"atmos_incinerator_airlock_exterior"

//Syndicate lavaland base incinerator (Lavaland.dmm)
#define INCINERATOR_SYNDICATELAVA_IGNITER 				"syndicatelava_igniter"
#define INCINERATOR_SYNDICATELAVA_MAINVENT 				"syndicatelava_mainvent"
#define INCINERATOR_SYNDICATELAVA_AUXVENT 				"syndicatelava_auxvent"
#define INCINERATOR_SYNDICATELAVA_DP_VENTPUMP			"syndicatelava_airlock_pump"
#define INCINERATOR_SYNDICATELAVA_AIRLOCK_SENSOR 		"syndicatelava_airlock_sensor"
#define INCINERATOR_SYNDICATELAVA_AIRLOCK_CONTROLLER 	"syndicatelava_airlock_controller"
#define INCINERATOR_SYNDICATELAVA_AIRLOCK_INTERIOR 		"syndicatelava_airlock_interior"
#define INCINERATOR_SYNDICATELAVA_AIRLOCK_EXTERIOR	 	"syndicatelava_airlock_exterior"

//MULTIPIPES
//IF YOU EVER CHANGE THESE CHANGE SPRITES TO MATCH.
#define PIPING_LAYER_MIN 1
#define PIPING_LAYER_MAX 5
#define PIPING_LAYER_DEFAULT 3
#define PIPING_LAYER_P_X 5
#define PIPING_LAYER_P_Y 5
#define PIPING_LAYER_LCHANGE 0.005

#define PIPING_ALL_LAYER				(1<<0)	//intended to connect with all layers, check for all instead of just one.
#define PIPING_ONE_PER_TURF				(1<<1) 	//can only be built if nothing else with this flag is on the tile already.
#define PIPING_DEFAULT_LAYER_ONLY		(1<<2)	//can only exist at PIPING_LAYER_DEFAULT
#define PIPING_CARDINAL_AUTONORMALIZE	(1<<3)	//north/south east/west doesn't matter, auto normalize on build.
#define PIPING_ALL_COLORS				(1<<4)	//intended to connect regardless of paint, both ways.
#define PIPING_BRIDGE					(1<<5)	//may cross one perpendicular pipe on the same layer
/// Не встаёт на крайние слои: спрайт шире, чем остаётся места под сдвиг.
/// Полоса теплообменной трубы - 15 пикселей, пять полос с шагом 5 требуют
/// 15 + 4*5 = 35 пикселей на 32-пиксельном тайле. На крайних слоях лист
/// обрезался краем: у трубы отъедало крайнее ребро, у джанкшена - зубец,
/// а манифолд уезжал за границу целиком.
#define PIPING_INNER_LAYERS_ONLY		(1<<6)

///Paint that imposes no restriction at all: an omni pipe joins every colour and every colour joins it.
#define ATMOS_COLOR_OMNI "#ffffff"
///Unpainted mapped pipes carry no colour at all, which has to read as omni too.
#define IS_OMNI_PIPE_COLOR(col) (!(col) || (lowertext(col) == ATMOS_COLOR_OMNI))

///Laying and pulling pipe is instant. The single exception is a pipe still holding
///pressure: the warning about a gush of air needs a window in which letting go is
///still an option, otherwise it is a death notice rather than a warning.
#define ATMOS_UNSAFE_WRENCH_DELAY (1 SECONDS)

///Used to define the temperature of a tile, arg is the temperature it should be at. Should always be put at the end of the atmos list.
///This is solely to be used after compile-time.
#define TURF_TEMPERATURE(temperature) "TEMP=[temperature]"

// Gas defines because i hate typepaths
#define GAS_O2					"o2"
#define GAS_N2					"n2"
#define GAS_CO2					"co2"
#define GAS_PLASMA				"plasma"
#define GAS_H2O					"water_vapor"
#define GAS_HYPERNOB			"nob"
#define GAS_NITRIC				"no"
#define GAS_NITROUS				"n2o"
#define GAS_NITRYL				"no2"
#define GAS_HYDROGEN			"hydrogen"
#define GAS_TRITIUM				"tritium"
#define GAS_BZ					"bz"
#define GAS_STIMULUM			"stim"
#define GAS_PLUOXIUM			"pluox"
#define GAS_MIASMA				"miasma"
#define GAS_METHANE				"methane"
#define GAS_METHYL_BROMIDE		"methyl_bromide"
#define GAS_BROMINE				"bromine"
#define GAS_AMMONIA				"ammonia"
#define GAS_FLUORINE			"fluorine"
#define GAS_ETHANOL				"ethanol"
#define GAS_MOTOR_OIL			"motor_oil" // BLUEMOON ADD - Напитки для синтетиков
#define GAS_QCD					"qcd"
// HFR / fusion gases (from WhiteMoon HFR port)
#define GAS_HELIUM				"helium"
#define GAS_FREON				"freon"
#define GAS_HALON				"halon"
#define GAS_ANTINOBLIUM			"antinoblium"
#define GAS_PROTO_NITRATE		"proto_nitrate"
#define GAS_ZAUKER				"zauker"
#define GAS_HEALIUM				"healium"
#define GAS_NITRIUM				"nitrium"
// Газы высокого давления: синтезируются только в контуре, который обычная труба
// не держит. Смысл в том, что за усиленной разводкой лежит контент, а не просто
// отсутствие поломок.
#define GAS_PYRONITE			"pyronite"
#define GAS_FLUXIN				"fluxin"

// Лестница сложности синтеза. Уровень объявляется у каждого газа явно, а не
// выводится читателем из цепочки реакций: по этой лестнице калибруются и цена
// продажи, и разовая награда науки за первый синтез.
/// Сырьё: берётся без синтеза - воздухозаборником, из канистры, из листа плазмы,
/// с трупа. Открывать нечего, наград нет.
#define GAS_TIER_RAW			0
/// Один узел от сырья: камера сгорания, электролизёр или простой нагрев. На входе
/// только сырьё и другие базовые газы.
#define GAS_TIER_BASIC			1
/// Нужен второй узел со своим режимом - крио-петля, узкое температурное окно или
/// газ-катализатор сверх основных компонентов.
#define GAS_TIER_ADVANCED		2
/// Вершина: две несовместимые ветки одновременно, особое оборудование (HFR,
/// разряд супермтерии) либо усиленный контур.
#define GAS_TIER_EXOTIC			3

// Ценовые полосы газов по уровням. Полосы не пересекаются и разделены зазором,
// поэтому газ более глубокого уровня не может стоить дешевле менее глубокого ни
// при какой калибровке внутри полосы. За этим следит юнит-тест
// /datum/unit_test/gas_price_matches_tier.
#define GAS_PRICE_MIN_TIER_RAW			0
#define GAS_PRICE_MAX_TIER_RAW			1
#define GAS_PRICE_MIN_TIER_BASIC		2
#define GAS_PRICE_MAX_TIER_BASIC		4
#define GAS_PRICE_MIN_TIER_ADVANCED		6
#define GAS_PRICE_MAX_TIER_ADVANCED		10
#define GAS_PRICE_MIN_TIER_EXOTIC		12
#define GAS_PRICE_MAX_TIER_EXOTIC		25

#define GAS_GROUP_CHEMICALS		"Chemicals"

#define GAS_FLAG_DANGEROUS		(1<<0)
#define GAS_FLAG_BREATH_PROC	(1<<1)
#define GAS_FLAG_CHEMICAL		(1<<2)

/// Ключ `min_requirements`, требующий минимального давления смеси.
///
/// Служебные ключи требований - строки рядом с идентификаторами газов
/// ("TEMP", "ENER", "MAX_TEMP", "FIRE_REAGENTS"). Каждый такой ключ обязан быть
/// известен ТРЁМ местам: циклу реакций в `/datum/gas_mixture/react()`,
/// индексатору `SSair.auxtools_update_reactions()` (иначе ключ примут за газ,
/// реакцию положат в несуществующий бакет и она не пойдёт никогда) и сборщику
/// кандидатов для анализатора. Поэтому он и вынесен в дефайн, а не написан
/// строкой в пяти файлах.
#define REACTION_REQ_MIN_PRESSURE	"MIN_PRESSURE"

//SUPERMATTER DEFINES
#define HEAT_PENALTY "heat penalties"
#define TRANSMIT_MODIFIER "transmit"
#define RADIOACTIVITY_MODIFIER "radioactivity"
#define HEAT_RESISTANCE "heat resistance"
#define POWERLOSS_INHIBITION "powerloss inhibition"
#define ALL_SUPERMATTER_GASES "gases we care about"
#define POWER_MIX "gas powermix"

//HELPERS
#define PIPING_LAYER_SHIFT(T, PipingLayer) \
	if(T.dir & (NORTH|SOUTH)) {									\
		T.pixel_x = (PipingLayer - PIPING_LAYER_DEFAULT) * PIPING_LAYER_P_X;\
	}																		\
	if(T.dir & (WEST|EAST)) {										\
		T.pixel_y = (PipingLayer - PIPING_LAYER_DEFAULT) * PIPING_LAYER_P_Y;\
	}

#define PIPING_LAYER_DOUBLE_SHIFT(T, PipingLayer) \
	T.pixel_x = (PipingLayer - PIPING_LAYER_DEFAULT) * PIPING_LAYER_P_X;\
	T.pixel_y = (PipingLayer - PIPING_LAYER_DEFAULT) * PIPING_LAYER_P_Y;

#define QUANTIZE(variable)		(round(variable,0.0000001))/*I feel the need to document what happens here. Basically this is used to catch most rounding errors, however it's previous value made it so that
															once gases got hot enough, most procedures wouldnt occur due to the fact that the mole counts would get rounded away. Thus, we lowered it a few orders of magnititude */

//If you're doing spreading things related to atmos, DO NOT USE CANATMOSPASS, IT IS NOT CHEAP. use this instead, the info is cached after all. it's tweaked just a bit to allow for circular checks
#define TURFS_CAN_SHARE(T1, T2) (LAZYACCESS(T2.atmos_adjacent_turfs, T1) || LAZYLEN(T1.atmos_adjacent_turfs & T2.atmos_adjacent_turfs))

/// Consecutive no-op SSair fires before a vent/scrubber drops into the idle heartbeat.
#define ATMOS_MACHINE_IDLE_STREAK 4

/// While idle, vents/scrubbers only run a full recheck this often. Event wakes
/// (turf activation, pipenet pressure jump, radio signals, power, welding) clear
/// the idle state instantly, so this is a safety net, not the response time.
/// The rotation is a standing share of the machinery phase: every sleeping
/// machine returns for one recheck per period, so on a station with ~1400
/// sleepers a 5 SECONDS period meant ~110 rechecks every fire (mprof: ~2ms of
/// c_am, half the pass size). Keep it long; correctness rides the event wakes.
#define ATMOS_MACHINE_IDLE_HEARTBEAT (15 SECONDS)
/// Ступеней удвоения периода сердцебиения для машины, которая раз за разом
/// просыпается впустую. Ступень N ждёт ATMOS_MACHINE_IDLE_HEARTBEAT * 2**N.
///
/// База в 15 секунд при каденсе SSair в 5 децисекунд означает, что каждый проход
/// возвращает к обработке одну тридцатую ВСЕЙ атмос-машинерии карты. В раунде
/// 9868 это 13824 машины, то есть примерно 460 пробуждений на проход, и
/// наблюдаемый air_machinery_count (289-668) - ровно эта ротация, а не работа.
/// Три ступени доводят период вечно спящей машины до двух минут и режут ротацию
/// восьмикратно. Любое событие (atmos_wake) обнуляет atmos_idle_streak, то есть
/// возвращает машину на нулевую ступень - откат наказывает только тех, кого уже
/// много раз будили зря.
#define ATMOS_MACHINE_IDLE_BACKOFF_STEPS 3
/// Pipenet pressure change (kPa) after reconcile that wakes idle machines attached to it.
#define ATMOS_PIPENET_WAKE_PRESSURE_DELTA 5
/// Ниже 100 кПа порог пробуждения берётся долей от давления сети, а не
/// абсолютом: криоконтур на 2.7К целиком живёт ниже 5 кПа, и с абсолютным
/// порогом рассылка не срабатывала для него никогда - спящие машины там держал
/// один heartbeat, после отката до двух минут на событие (раунд 9875, "помпы
/// сами отмирают").
#define ATMOS_PIPENET_WAKE_PRESSURE_RATIO 0.05
/// Пол относительного порога (кПа): пустая или свежесобранная сеть обязана
/// проснуться от первого же пришедшего газа, но не от дрожи давления в
/// последних разрядах мантиссы.
#define ATMOS_PIPENET_WAKE_PRESSURE_FLOOR 0.1
/// Pipenet temperature change (K) after reconcile that wakes idle heat exchanging
/// pipes on it. Their own conduction gate is far finer (0.01 K), so this is only
/// the "heat arrived from elsewhere in the loop" trigger; a slow drift that never
/// crosses it is still picked up by the idle heartbeat.
#define ATMOS_PIPENET_WAKE_TEMPERATURE_DELTA 1
/// Vents ignore pressure imbalances smaller than this (kPa). Stops perpetual
/// sub-visible top-ups that keep every room's turfs excited forever.
#define ATMOS_VENT_PRESSURE_EPSILON 0.05
/// Сколько миллисекунд тика должно остаться, чтобы фаза эквалайзера взялась за
/// ещё один СРЕЗ обхода зоны. Сам обход теперь возобновляемый (см.
/// /datum/atmos_zone_walk), но его стадия сведения газа атомарна по построению и
/// упирается в equalize_hard_turf_limit = 2000 турфов, поэтому порог держим
/// заведомо выше одного среза, но ниже полного тика: хотя бы один срез за фаер
/// идёт всё равно, иначе обход не двигался бы вовсе.
#define ATMOS_EQUALIZE_ZONE_MIN_BUDGET_MS 8
/// Сколько турфов зоны обход эквалайзера обрабатывает между проверками бюджета
/// тика. Это только гранулярность контроля, а не потолок работы за фаер: фаза
/// крутит срезы подряд, пока в тике есть запас, поэтому мельче срез - точнее
/// остановка, и платится за это лишь вызов прока на срез. Величина того же
/// порядка, что EXCITED_GROUP_BREAKDOWN_SLICE, у которого работа на элемент
/// сопоставима.
#define ATMOS_EQUALIZE_ZONE_SLICE 256
/// Разброс давления (кПа) внутри зоны, ниже которого сводить нечего, и он же -
/// порог, по которому фаза решает, что турф вообще стоит зоны. Раньше жил двумя
/// независимыми литералами: `var/const/` внутри обхода и голой пятёркой в фазе.
#define EQUALIZE_MIN_PRESSURE_DELTA 5
/// Pure-telemetry devices (meters, air sensors) only report once per this many
/// SSair fires; their power draw is compensated by the same constant.
#define ATMOS_TELEMETRY_INTERVAL 4
/// Air sensors with unchanged readings still rebroadcast at least this often,
/// so consoles built mid-round and timestamp displays stay fresh.
#define ATMOS_TELEMETRY_HEARTBEAT (30 SECONDS)
/// Past this silence the monitoring console marks a sensor's reading as stale:
/// comfortably more than one heartbeat, so a healthy sensor never trips it.
#define ATMOS_TELEMETRY_STALE_AFTER (ATMOS_TELEMETRY_HEARTBEAT * 3)

/// Why an air alarm raised a zone alert. Travels in the FREQ_ATMOS_ALARMS
/// signal so the alert console can say what broke, not just where.
#define AALARM_CAUSE_PRESSURE "pressure"
#define AALARM_CAUSE_TEMPERATURE "temperature"
#define AALARM_CAUSE_GAS "gas"
#define AALARM_CAUSE_MANUAL "manual"

/// Запас в кельвинах, на который температурная полоса алярма расходится за
/// проектную температуру комнаты. Ровно по проекту нельзя: обычный дрейф на
/// пару градусов тут же поднимал бы тревогу.
#define AIRALARM_DESIGN_TEMPERATURE_MARGIN 15

// ХОЛОФАНЫ
//
// Собранный вентилятор стоит материалов, времени и места: его надо принести,
// поставить и потом разобрать. Голограмма не стоит ничего, и без ограничения
// проектор давал три бесплатные вечные стены - строго лучше, чем то, что игрок
// может собрать руками. Ограничиваем не давлением, а временем: проектор тратит
// ёмкость, пока фаны спроецированы, и восстанавливает её, когда все сняты.
// Холофаны, расставленные на картах, проектора не имеют и работают как раньше -
// вечно.
//
// Времени должно хватать на работу, ради которой фан и ставят: заварить дыру,
// перекрыть проём, пока меняешь венту. Первая раскладка (100 ёмкости, 0.5 в
// секунду на фан) давала на стену из трёх фанов около минуты - за минуту не
// успеть ничего, и проектор превращался в расходник, который надо носить
// пачками. Отсюда запас втрое больше и вдвое быстрее восстановление.
/// Ёмкость проектора холофанов.
#define HOLOFAN_PROJECTOR_MAX_CHARGE 300
/// Расход ёмкости в секунду на каждый спроецированный фан. При ёмкости 300 это
/// четырнадцать минут на один фан и почти пять на стену из трёх.
#define HOLOFAN_PROJECTOR_DRAIN_PER_SIGN 0.35
/// Восстановление ёмкости в секунду, когда не спроецировано ни одного фана.
/// Полный бак из нуля - минута: снял фаны, дошёл до следующей дыры, поставил.
#define HOLOFAN_PROJECTOR_RECOVERY 5
/// Доля ёмкости, ниже которой проектор предупреждает носителя.
#define HOLOFAN_PROJECTOR_WARN_RATIO 0.25
/// Доля ёмкости, ниже которой проектор отказывается ставить новый фан: иначе
/// он гаснет через пару секунд после установки.
#define HOLOFAN_PROJECTOR_DEPLOY_RATIO 0.1
/// Сколько ёмкости остаётся, когда разряженный эмиттер сбрасывает одну лишнюю
/// проекцию. Стена не гаснет разом: она осыпается по одному фану, начиная с
/// последнего поставленного, и у игрока есть время увидеть это и уйти.
#define HOLOFAN_PROJECTOR_SHED_BUFFER_RATIO 0.12

// УСТОЙЧИВЫЙ ПРОЕКТОР (исследуемая версия)
//
// Разница не в размере бака, а в том, что эмиттер подзаряжается ПРЯМО ВО ВРЕМЯ
// работы. Отдачи хватает ровно на один развёрнутый фан - он держится сколько
// угодно, а каждый следующий уводит баланс в минус и жрёт запас. Получается
// внятный выбор: одно постоянное уплотнение или несколько временных.
#define HOLOFAN_SUSTAINED_MAX_CHARGE 500
#define HOLOFAN_SUSTAINED_DRAIN_PER_SIGN 0.35
#define HOLOFAN_SUSTAINED_RECOVERY 6
/// Подзарядка в секунду при развёрнутых проекциях. Чуть выше расхода одного
/// фана - отсюда и берётся "один держится вечно".
#define HOLOFAN_SUSTAINED_RECOVERY_ACTIVE 0.4

//Unomos - So for whatever reason, garbage collection actually drastically decreases the cost of atmos later in the round. Turning this into a define yields massively improved performance.
#define GAS_GARBAGE_COLLECT(GASGASGAS)\
	var/list/CACHE_GAS = GASGASGAS;\
	for(var/id in CACHE_GAS){\
		if(QUANTIZE(CACHE_GAS[id]) <= 0)\
			CACHE_GAS -= id;\
	}

///Russian labels for the paint keys above, used by examine so a player sees what
///a pipe will and will not connect to without having to read the hex.
GLOBAL_LIST_INIT(pipe_paint_color_names, list(
		"amethyst" = "аметистовая",
		"blue" = "синяя",
		"brown" = "коричневая",
		"cyan" = "голубая",
		"dark" = "тёмная",
		"green" = "зелёная",
		"grey" = "серая",
		"orange" = "оранжевая",
		"purple" = "фиолетовая",
		"red" = "красная",
		"violet" = "тёмно-фиолетовая",
		"yellow" = "жёлтая"
))

GLOBAL_LIST_INIT(pipe_paint_colors, list(
		"amethyst" = rgb(130,43,255), //supplymain
		"blue" = rgb(0,0,255),
		"brown" = rgb(178,100,56),
		"cyan" = rgb(0,255,249),
		"dark" = rgb(69,69,69),
		"green" = rgb(30,255,0),
		"grey" = rgb(255,255,255),
		"orange" = rgb(255,129,25),
		"purple" = rgb(128,0,182),
		"red" = rgb(255,0,0),
		"violet" = rgb(64,0,128),
		"yellow" = rgb(255,198,0)
))

#define AIR_REF_PLANETARY_TURF (1<<0) //SIMULATION_DIFFUSE 0b1
#define AIR_REF_OPEN_TURF (1<<1) //SIMULATION_ALL 0b10

// ---------------------------------------------------------------------------
// Intra-phase profiler for the active turf pass (ATMOS_HEADLESS_BENCH only).
//
// The turf phase dominates SSair but reports a single number, so every guess
// about what to optimise inside process_cell used to be blind. These macros
// split it into named slots and count which code paths the tiles actually
// took. Production builds compile all of it away: with the define off every
// macro below expands to nothing at all.
//
// Timing is armed for one cycle at a time (see atmos_tprof_arm), so the
// instrumentation cannot distort the cost curve it is supposed to measure.
// Slots must not nest; the inner variants exist for the one place that needs
// a second concurrent stopwatch (the space branch inside the neighbour loop).
// ---------------------------------------------------------------------------
#ifdef ATMOS_HEADLESS_BENCH
GLOBAL_VAR_INIT(atmos_tprof_active, FALSE)
GLOBAL_LIST_EMPTY(atmos_tprof_ms)
GLOBAL_LIST_EMPTY(atmos_tprof_counts)

#define ATMOS_TPROF_VARS var/__tprof_mark = 0; var/__tprof_inner = 0
#define ATMOS_TPROF_MARK if(GLOB.atmos_tprof_active) { __tprof_mark = TICK_USAGE_REAL }
#define ATMOS_TPROF_ADD(slot) if(GLOB.atmos_tprof_active) { GLOB.atmos_tprof_ms[slot] += TICK_DELTA_TO_MS(TICK_USAGE_REAL - __tprof_mark) }
#define ATMOS_TPROF_MARK_INNER if(GLOB.atmos_tprof_active) { __tprof_inner = TICK_USAGE_REAL }
#define ATMOS_TPROF_ADD_INNER(slot) if(GLOB.atmos_tprof_active) { GLOB.atmos_tprof_ms[slot] += TICK_DELTA_TO_MS(TICK_USAGE_REAL - __tprof_inner) }
#define ATMOS_TPROF_COUNT(slot) if(GLOB.atmos_tprof_active) { GLOB.atmos_tprof_counts[slot] += 1 }
/// For sites whose only statement would be a count: an empty macro must not
/// leave a bodyless `if` behind in production builds.
#define ATMOS_TPROF_COUNT_IF(condition, slot) if(GLOB.atmos_tprof_active && (condition)) { GLOB.atmos_tprof_counts[slot] += 1 }
#else
#define ATMOS_TPROF_VARS
#define ATMOS_TPROF_MARK
#define ATMOS_TPROF_ADD(slot)
#define ATMOS_TPROF_MARK_INNER
#define ATMOS_TPROF_ADD_INNER(slot)
#define ATMOS_TPROF_COUNT(slot)
#define ATMOS_TPROF_COUNT_IF(condition, slot)
#endif

/// Давление выхода, выше которого объёмный насос перестаёт качать. Выше ворот
/// верхних рецептов (GAS_RECIPE_HIGH_PRESSURE) с запасом: объёмный насос -
/// штатный способ додавить подающую линию кристаллизатора до порога.
#define VOLUME_PUMP_PRESSURE_CEILING		20000

/// Давление на подающей линии, которого требуют верхние рецепты кристаллизатора.
///
/// Газовый насос упирается в свой потолок (MAX_OUTPUT_PRESSURE) сильно ниже -
/// сюда достаёт только объёмный насос или нагрев контура: верхние призы требуют
/// осознанной сборки, а не выкрученной на максимум помпы.
#define GAS_RECIPE_HIGH_PRESSURE			15000
/// Давление, при котором идёт синтез газов высокого давления (пиронит, флюксин).
///
/// Намеренно ровно то же число, что и у верхних рецептов кристаллизатора: порог
/// в игре один, и двух чисел игроку помнить не нужно.
#define GAS_HIGH_PRESSURE_SYNTHESIS			GAS_RECIPE_HIGH_PRESSURE
/// Как часто кристаллизатор жалуется вслух на нехватку давления. Он тикает
/// каждый атмос-файр, так что без кулдауна жалоба стала бы шумом.
#define CRYSTALLIZER_COMPLAINT_COOLDOWN		(20 SECONDS)

/// Как часто (в файрах SSair) реестр сетей чистится от нулей. Нуль там оставляет
/// только жёсткое удаление сети мимо qdel, то есть в норме - никогда, поэтому
/// интервал редкий: раз в полминуты при штатном каденсе.
#define PIPENET_REGISTRY_SWEEP_INTERVAL		64

// ATMOS HANDBOOK
//
// Разделы внутриигрового справочника сверх газов и реакций. Строка здесь - и
// ключ группировки топиков, и заголовок секции в окне: отдельного словаря
// "ключ - подпись" не заводим, потому что раздел ровно один раз показывается и
// ровно один раз группирует.
#define ATMOS_HANDBOOK_CATEGORY_TOOLS		"Инструменты"
#define ATMOS_HANDBOOK_CATEGORY_METHODS		"Методы"
#define ATMOS_HANDBOOK_CATEGORY_SAFETY		"Безопасность"
