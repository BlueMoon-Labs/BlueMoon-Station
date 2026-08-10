/datum/tlv
	var/min2
	var/min1
	var/max1
	var/max2
	///Заводские значения порогов. Снимаются в New(), чтобы интерфейс мог
	///откатить строку одной кнопкой вместо ручного набора четырёх чисел.
	var/list/defaults

/datum/tlv/New(min2 as num, min1 as num, max1 as num, max2 as num)
	if(min2) src.min2 = min2
	if(min1) src.min1 = min1
	if(max1) src.max1 = max1
	if(max2) src.max2 = max2
	defaults = list("min2" = src.min2, "min1" = src.min1, "max1" = src.max1, "max2" = src.max2)

///Независимая копия с теми же текущими и заводскими значениями. Присваивать
///напрямую, а не через New(): порог, выставленный игроком в 0, аргументный
///конструктор молча превратил бы обратно в дефолт типа.
/datum/tlv/proc/copy()
	var/datum/tlv/clone = new
	clone.min2 = min2
	clone.min1 = min1
	clone.max1 = max1
	clone.max2 = max2
	clone.defaults = defaults?.Copy()
	return clone

/datum/tlv/proc/reset_to_defaults()
	if(!defaults)
		return FALSE
	min2 = defaults["min2"]
	min1 = defaults["min1"]
	max1 = defaults["max1"]
	max2 = defaults["max2"]
	return TRUE

/datum/tlv/proc/is_at_defaults()
	if(!defaults)
		return FALSE
	return min2 == defaults["min2"] && min1 == defaults["min1"] \
		&& max1 == defaults["max1"] && max2 == defaults["max2"]

///Слепок для tgui: -1 остаётся -1, интерфейс сам рисует его как "отключено".
/datum/tlv/proc/ui_list()
	return list("min2" = min2, "min1" = min1, "max1" = max1, "max2" = max2)

/datum/tlv/proc/get_danger_level(val as num)
	if(max2 != -1 && val >= max2)
		return 2
	if(min2 != -1 && val <= min2)
		return 2
	if(max1 != -1 && val >= max1)
		return TRUE
	if(min1 != -1 && val <= min1)
		return TRUE
	return FALSE

/datum/tlv/no_checks
	min2 = -1
	min1 = -1
	max1 = -1
	max2 = -1

/datum/tlv/dangerous
	min2 = -1
	min1 = -1
	max1 = 0.2
	max2 = 0.5

/obj/item/electronics/airalarm
	name = "air alarm electronics"
	icon_state = "airalarm_electronics"
	custom_price = PRICE_CHEAP

/obj/item/wallframe/airalarm
	name = "air alarm frame"
	desc = "Рабочая начинка воздушной сигнализации."
	icon = 'icons/obj/monitors.dmi'
	icon_state = "alarm_bitem"
	result_path = /obj/machinery/airalarm

#define AALARM_MODE_SCRUBBING 1
#define AALARM_MODE_VENTING 2 //makes draught
#define AALARM_MODE_PANIC 3 //like siphon, but stronger (enables widenet)
#define AALARM_MODE_REPLACEMENT 4 //sucks off all air, then refill and swithes to scrubbing
#define AALARM_MODE_OFF 5
#define AALARM_MODE_FLOOD 6 //Emagged mode; turns off scrubbers and pressure checks on vents
#define AALARM_MODE_SIPHON 7 //Scrubbers suck air
#define AALARM_MODE_CONTAMINATED 8 //Turns on all filtering and widenet scrubbing.
#define AALARM_MODE_REFILL 9 //just like normal, but with triple the air output

/// Declarative air-alarm operating mode. The legacy command emitter remains a
/// compatibility boundary for old vents/scrubbers; selection and UI metadata
/// live here instead of in parallel hardcoded lists.
/datum/air_alarm_mode
	var/id
	///Английское имя: уходит в investigate_log, логи расследований одноязычные.
	var/name
	///Подпись в интерфейсе - на русском, как и весь остальной tgui.
	var/ui_name
	var/description
	var/danger = FALSE
	var/emag_only = FALSE

/datum/air_alarm_mode/proc/apply(obj/machinery/airalarm/alarm)
	alarm.apply_mode_commands(id)

/datum/air_alarm_mode/scrubbing
	id = AALARM_MODE_SCRUBBING
	name = "Filtering"
	ui_name = "Фильтрация"
	description = "Держит нормальное давление и вычищает обычную грязь из воздуха."

/datum/air_alarm_mode/contaminated
	id = AALARM_MODE_CONTAMINATED
	name = "Contaminated"
	ui_name = "Заражение"
	description = "Широкий охват: вычищает все газы, помеченные как опасные."

/datum/air_alarm_mode/venting
	id = AALARM_MODE_VENTING
	name = "Draught"
	ui_name = "Продув"
	description = "Одновременно откачивает и подаёт воздух."

/datum/air_alarm_mode/refill
	id = AALARM_MODE_REFILL
	name = "Refill"
	ui_name = "Дозаправка"
	description = "Быстро поднимает давление в помещении до трёх атмосфер."
	danger = TRUE

/datum/air_alarm_mode/replacement
	id = AALARM_MODE_REPLACEMENT
	name = "Cycle"
	ui_name = "Прокачка"
	description = "Откачивает воздух досуха, потом возвращается к фильтрации."
	danger = TRUE

/datum/air_alarm_mode/siphon
	id = AALARM_MODE_SIPHON
	name = "Siphon"
	ui_name = "Откачка"
	description = "Убирает воздух из помещения через обычную сеть скрубберов."
	danger = TRUE

/datum/air_alarm_mode/panic
	id = AALARM_MODE_PANIC
	name = "Panic Siphon"
	ui_name = "Аварийная откачка"
	description = "Быстрая разгерметизация широким охватом. Нужны внутренние баллоны."
	danger = TRUE

/datum/air_alarm_mode/off
	id = AALARM_MODE_OFF
	name = "Off"
	ui_name = "Выключено"
	description = "Гасит венты и скрубберы."

/datum/air_alarm_mode/flood
	id = AALARM_MODE_FLOOD
	name = "Flood"
	ui_name = "Затопление"
	description = "Снимает проверки давления и открывает подающую сеть."
	danger = TRUE
	emag_only = TRUE

/proc/init_air_alarm_modes()
	var/list/result = list()
	// Stable operational order, with destructive modes grouped after the normal
	// ones. Typepath sorting made this jump around between builds.
	for(var/path in list(
		/datum/air_alarm_mode/scrubbing,
		/datum/air_alarm_mode/contaminated,
		/datum/air_alarm_mode/venting,
		/datum/air_alarm_mode/refill,
		/datum/air_alarm_mode/replacement,
		/datum/air_alarm_mode/siphon,
		/datum/air_alarm_mode/panic,
		/datum/air_alarm_mode/off,
		/datum/air_alarm_mode/flood,
	))
		var/datum/air_alarm_mode/mode = new path
		if(mode.id)
			result["[mode.id]"] = mode
	return result

GLOBAL_LIST_INIT(air_alarm_modes, init_air_alarm_modes())

/proc/get_air_alarm_mode(id)
	return GLOB.air_alarm_modes["[id]"]

#define AALARM_REPORT_TIMEOUT 100

/// Единственные поля /datum/tlv, которые интерфейс имеет право писать. Без
/// белого списка params["var"] уходил прямо в tlv.vars[] и позволял писать
/// в любую переменную датума.
#define AALARM_THRESHOLD_VARS list("min2", "min1", "max1", "max2")

/// Adaptive process() backoff cap: once danger_level has been stable, the air alarm reads
/// the turf air at most every this-many SSmachines fires (2 s each). The instant danger_level
/// changes it snaps back to reading every fire. (Not #undef'd — read by the regression test.)
#define AALARM_MAX_PROCESS_INTERVAL 2
/// Backoff cap while the local turf sits outside active atmos exchange entirely (not excited,
/// no excited group): its air cannot drift, so reads only guard against missed excitations.
#define AALARM_INACTIVE_PROCESS_INTERVAL 15

#define AALARM_OVERLAY_OFF		"alarm_off"
#define AALARM_OVERLAY_GREEN	"alarm_green"
#define AALARM_OVERLAY_WARN		"alarm_amber"
#define AALARM_OVERLAY_DANGER	"alarm_red"

/obj/machinery/airalarm
	name = "air alarm"
	desc = "Машина для отслеживания атмосферных показателей. Сигнализирует при опасности окружающей среды."
	icon = 'icons/obj/monitors.dmi'
	icon_state = "alarm0"
	plane = ABOVE_WALL_PLANE
	use_power = IDLE_POWER_USE
	idle_power_usage = 4
	active_power_usage = 8
	power_channel = ENVIRON
	req_access = list(ACCESS_ATMOSPHERICS)
	max_integrity = 250
	integrity_failure = 0.33
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 100, BOMB = 0, BIO = 100, RAD = 100, FIRE = 90, ACID = 30)
	resistance_flags = FIRE_PROOF

	COOLDOWN_DECLARE(decomp_alarm)

	var/danger_level = 0
	///Что именно вылезло за порог: AALARM_CAUSE_*. Едет в сигнал тревоги.
	var/danger_source
	///Идентификатор газа, если причина - газ.
	var/danger_source_gas
	var/mode = AALARM_MODE_SCRUBBING

	/// Adaptive process() throttle: how many SSmachines fires between full turf air reads.
	/// 1 = every fire. Grows toward AALARM_MAX_PROCESS_INTERVAL while danger_level is stable;
	/// resets to 1 the instant danger_level changes.
	var/process_interval = 1
	/// Fires left to skip (cheap early-out) before the next full air read.
	var/process_skips_left = 0

	var/locked = TRUE
	var/aidisabled = 0
	var/shorted = 0
	var/buildstage = 2 // 2 = complete, 1 = no wires,  0 = circuit gone
	var/brightness_on = 1

	var/frequency = FREQ_ATMOS_CONTROL
	var/alarm_frequency = FREQ_ATMOS_ALARMS
	var/datum/radio_frequency/radio_connection
	///Represents a signel source of atmos alarms, complains to all the listeners if one of our thresholds is violated
	var/datum/alarm_handler/alarm_manager
	///The area this alarm is registered in (area.airalarms); kept so Destroy
	///removes us from the same list we joined even if areas got rearranged.
	var/area/alarm_area

	var/list/TLV = list( // Breathable air.
		"pressure"					= new/datum/tlv(ONE_ATMOSPHERE * 0.8, ONE_ATMOSPHERE*  0.9, ONE_ATMOSPHERE * 1.1, ONE_ATMOSPHERE * 1.2), // kPa
		"temperature"				= new/datum/tlv(T0C, T0C+10, T0C+40, T0C+66),
		GAS_O2			= new/datum/tlv(16, 19, 40, 50), // Partial pressure, kpa
		GAS_N2			= new/datum/tlv(-1, -1, 1000, 1000),
		GAS_CO2	= new/datum/tlv(-1, -1, 5, 10),
		GAS_MIASMA			= new/datum/tlv(-1, -1, 2, 5),
		GAS_PLASMA			= new/datum/tlv/dangerous,
		GAS_NITROUS	= new/datum/tlv/dangerous,
		GAS_BZ				= new/datum/tlv/dangerous,
		GAS_HYPERNOB		= new/datum/tlv(-1, -1, 1000, 1000), // Hyper-Noblium is inert and nontoxic
		GAS_H2O		= new/datum/tlv/dangerous,
		GAS_TRITIUM			= new/datum/tlv/dangerous,
		GAS_STIMULUM			= new/datum/tlv(-1, -1, 1000, 1000), // Stimulum has only positive effects
		GAS_NITRYL			= new/datum/tlv/dangerous,
		GAS_PLUOXIUM			= new/datum/tlv(-1, -1, 5, 6), // Unlike oxygen, pluoxium does not fuel plasma/tritium fires
		GAS_METHANE			= new/datum/tlv(-1, -1, 3, 6),
		GAS_METHYL_BROMIDE	= new/datum/tlv/dangerous,
		GAS_AMMONIA		= new/datum/tlv/dangerous,
		GAS_BROMINE			= new/datum/tlv/dangerous,

	)

/// Температурные пороги алярма заданы по человеку: ниже нуля по Цельсию - уже
/// тревога. В комнате, которую РАЗЛОЖИЛИ холодной, это означает красный алярм с
/// первой секунды раунда и до конца: телекомы мапятся при 80 K, холодильник
/// кухни при 259 K, и починить там нечего - комната работает как задумано.
/// Тревога, которую нельзя ни снять, ни исправить, не сообщает ничего и учит
/// экипаж не смотреть на алярмы вообще.
///
/// Полоса сдвигается под проектную температуру САМОГО турфа и сохраняет свою
/// ширину, так что отклонения алярм ловит по-прежнему - в телекомах он всё так
/// же заметит нагрев, просто перестанет ругаться на штатный холод. Заводскими
/// после сдвига считаются новые значения - иначе кнопка сброса в интерфейсе
/// одним кликом возвращает вечную тревогу.
/obj/machinery/airalarm/proc/adapt_temperature_thresholds()
	var/datum/tlv/temperature_tlv = TLV["temperature"]
	if(!temperature_tlv || !SSair)
		return
	var/turf/here = get_turf(src)
	if(!isopenturf(here))
		return
	var/list/designed = SSair.get_parsed_gas_string(here.initial_gas_mix)
	var/designed_temperature = designed?[GAS_STRING_TEMP]
	if(!isnum(designed_temperature))
		return
	var/changed = FALSE
	// -1 это "порог отключён", и трогать его нельзя: у серверного алярма так
	// отключены вообще все пороги.
	if(temperature_tlv.min2 != -1 && designed_temperature < temperature_tlv.min2 + AIRALARM_DESIGN_TEMPERATURE_MARGIN)
		var/warning_band = max(temperature_tlv.min1 - temperature_tlv.min2, 0)
		temperature_tlv.min2 = designed_temperature - AIRALARM_DESIGN_TEMPERATURE_MARGIN
		temperature_tlv.min1 = temperature_tlv.min2 + warning_band
		changed = TRUE
	if(temperature_tlv.max2 != -1 && designed_temperature > temperature_tlv.max2 - AIRALARM_DESIGN_TEMPERATURE_MARGIN)
		var/warning_band = max(temperature_tlv.max2 - temperature_tlv.max1, 0)
		temperature_tlv.max2 = designed_temperature + AIRALARM_DESIGN_TEMPERATURE_MARGIN
		temperature_tlv.max1 = temperature_tlv.max2 - warning_band
		changed = TRUE
	if(changed)
		temperature_tlv.defaults = temperature_tlv.ui_list()

/obj/machinery/airalarm/proc/regenerate_TLV()
	var/list/TLVs = GLOB.gas_data.TLVs
	for(var/g in TLVs)
		// Копия, а не сама глобальная запись: раньше все алярмы станции держали
		// один и тот же /datum/tlv на газ, и правка порога плазмы в баре
		// молча меняла его в каждой комнате.
		var/datum/tlv/shared = TLVs[g]
		TLV[g] = shared.copy()

/obj/machinery/airalarm/server // No checks here.
	TLV = list(
		"pressure"					= new/datum/tlv/no_checks,
		"temperature"				= new/datum/tlv/no_checks,
		GAS_O2			= new/datum/tlv/no_checks,
		GAS_N2			= new/datum/tlv/no_checks,
		GAS_CO2	= new/datum/tlv/no_checks,
		GAS_MIASMA			= new/datum/tlv/no_checks,
		GAS_PLASMA			= new/datum/tlv/no_checks,
		GAS_NITROUS	= new/datum/tlv/no_checks,
		GAS_BZ				= new/datum/tlv/no_checks,
		GAS_HYPERNOB		= new/datum/tlv/no_checks,
		GAS_H2O		= new/datum/tlv/no_checks,
		GAS_TRITIUM			= new/datum/tlv/no_checks,
		GAS_STIMULUM			= new/datum/tlv/no_checks,
		GAS_NITRYL			= new/datum/tlv/no_checks,
		GAS_PLUOXIUM			= new/datum/tlv/no_checks,
		GAS_METHANE			= new/datum/tlv/no_checks,
		GAS_METHYL_BROMIDE	= new/datum/tlv/no_checks
	)

/obj/machinery/airalarm/server/regenerate_TLV()
	var/list/TLVs = GLOB.gas_data.TLVs
	for(var/g in TLVs)
		TLV[g] = new/datum/tlv/no_checks

/obj/machinery/airalarm/kitchen_cold_room // Copypasta: to check temperatures.
	TLV = list(
		"pressure"					= new/datum/tlv(ONE_ATMOSPHERE * 0.8, ONE_ATMOSPHERE*  0.9, ONE_ATMOSPHERE * 1.1, ONE_ATMOSPHERE * 1.2), // kPa
		"temperature"				= new/datum/tlv(T0C-73.15, T0C-63.15, T0C, T0C+10),
		GAS_O2			= new/datum/tlv(16, 19, 135, 140), // Partial pressure, kpa
		GAS_N2			= new/datum/tlv(-1, -1, 1000, 1000),
		GAS_CO2	= new/datum/tlv(-1, -1, 5, 10),
		GAS_MIASMA			= new/datum/tlv/(-1, -1, 2, 5),
		GAS_PLASMA			= new/datum/tlv/dangerous,
		GAS_NITROUS	= new/datum/tlv/dangerous,
		GAS_BZ				= new/datum/tlv/dangerous,
		GAS_HYPERNOB		= new/datum/tlv(-1, -1, 1000, 1000), // Hyper-Noblium is inert and nontoxic
		GAS_H2O		= new/datum/tlv/dangerous,
		GAS_TRITIUM			= new/datum/tlv/dangerous,
		GAS_STIMULUM			= new/datum/tlv(-1, -1, 1000, 1000), // Stimulum has only positive effects
		GAS_NITRYL			= new/datum/tlv/dangerous,
		GAS_PLUOXIUM			= new/datum/tlv(-1, -1, 1000, 1000), // Unlike oxygen, pluoxium does not fuel plasma/tritium fires
		GAS_METHANE			= new/datum/tlv(-1, -1, 3, 6),
		GAS_METHYL_BROMIDE	= new/datum/tlv/dangerous
	)

/obj/machinery/airalarm/unlocked
	locked = FALSE

/obj/machinery/airalarm/engine
	name = "engine air alarm"
	locked = FALSE
	req_access = null
	req_one_access = list(ACCESS_ATMOSPHERICS, ACCESS_ENGINE)

/obj/machinery/airalarm/mixingchamber
	name = "chamber air alarm"
	locked = FALSE
	req_access = null
	req_one_access = list(ACCESS_ATMOSPHERICS, ACCESS_TOX, ACCESS_TOX_STORAGE)

/obj/machinery/airalarm/all_access
	name = "all-access air alarm"
	desc = "This particular atmos control unit appears to have no access restrictions."
	locked = FALSE
	req_access = null
	req_one_access = null

/obj/machinery/airalarm/syndicate //general syndicate access
	req_access = list(ACCESS_SYNDICATE)

/obj/machinery/airalarm/inteq //general inteq access
	req_access = list(ACCESS_INTEQ)

/obj/machinery/airalarm/directional/north //Pixel offsets get overwritten on New()
	dir = SOUTH
	pixel_y = 24

/obj/machinery/airalarm/directional/south
	dir = NORTH
	pixel_y = -24

/obj/machinery/airalarm/directional/east
	dir = WEST
	pixel_x = 24

/obj/machinery/airalarm/directional/west
	dir = EAST
	pixel_x = -24

//all air alarms in area are connected via magic
/area
	var/list/air_vent_names = list()
	var/list/air_scrub_names = list()
	var/list/air_vent_info = list()
	var/list/air_scrub_info = list()
	///Air alarms in this exact area (not the base-area group). Lazy, maintained
	///by /obj/machinery/airalarm Initialize/Destroy so per-area consumers never
	///have to type-scan area contents.
	var/list/airalarms

/obj/machinery/airalarm/Initialize(mapload, ndir, nbuild)
	. = ..()
	regenerate_TLV()
	RegisterSignal(SSdcs,COMSIG_GLOB_NEW_GAS, PROC_REF(regenerate_TLV))
	set_wires(new /datum/wires/airalarm(src))

	if(ndir)
		setDir(ndir)

	if(nbuild)
		buildstage = 0
		panel_open = TRUE
		pixel_x = (dir & 3)? 0 : (dir == 4 ? -24 : 24)
		pixel_y = (dir & 3)? (dir == 1 ? -24 : 24) : 0

	if(name == initial(name))
		name = "[get_area_name(src, get_base_area = TRUE)] Air Alarm"

	alarm_manager = new(src)
	power_change()
	set_frequency(frequency)
	register_context()
	adapt_temperature_thresholds()
	alarm_area = get_area(src)
	if(alarm_area)
		LAZYADD(alarm_area.airalarms, src)

/obj/machinery/airalarm/add_context(atom/source, list/context, obj/item/held_item, mob/living/user)
	. = ..()
	LAZYSET(context[SCREENTIP_CONTEXT_ALT_LMB], INTENT_ANY, locked ? "Unlock" : "Lock")
	return CONTEXTUAL_SCREENTIP_SET

/obj/machinery/airalarm/Destroy()
	if(alarm_area)
		LAZYREMOVE(alarm_area.airalarms, src)
		alarm_area = null
	UnregisterSignal(SSdcs, COMSIG_GLOB_NEW_GAS)
	SSradio.remove_object(src, frequency)
	QDEL_NULL(wires)
	QDEL_NULL(alarm_manager)
	return ..()

/obj/machinery/airalarm/examine(mob/user)
	. = ..()
	switch(buildstage)
		if(0)
			. += "<span class='notice'>Отсутствует электроника.</span>"
		if(1)
			. += "<span class='notice'>Отсутствует проводка.</span>"
		if(2)
			. += "<span class='notice'>Alt-click, чтобы [locked ? "раз" : "за"]блокировать интерфейс.</span>"
	. += "<span class='notice'>Текущий уровень угрозы: <b><u>[SECURITY_LEVEL_COLORED_UPPERTEXT(GLOB.security_level)]</u></b>.</span>"

/obj/machinery/airalarm/ui_status(mob/user)
	if(hasSiliconAccessInArea(user))
		if(aidisabled)
			to_chat(user, "ИИ-управление отключено")
			return UI_CLOSE
		else if(!issilicon(user)) //True sillycones use ..()
			return UI_INTERACTIVE
	if(!shorted)
		return ..()
	return UI_CLOSE

/obj/machinery/airalarm/can_interact(mob/user)
	. = ..()
	if (!issilicon(user) && hasSiliconAccessInArea(user))
		return TRUE

/obj/machinery/airalarm/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "AirAlarm", name)
		ui.open()

/obj/machinery/airalarm/ui_data(mob/user)
	var/data = list(
		"locked" = locked,
		"siliconUser" = hasSiliconAccessInArea(user),
		"emagged" = (obj_flags & EMAGGED ? 1 : 0),
		"danger_level" = danger_level,
	)

	var/area/A = get_base_area(src)
	data["atmos_alarm"] = !!A.active_alarms[ALARM_ATMOS]
	data["fire_alarm"] = A.fire

	var/turf/T = get_turf(src)
	var/datum/gas_mixture/environment = T.return_air()
	var/datum/tlv/cur_tlv

	data["environment_data"] = list()
	var/pressure = environment.return_pressure()
	cur_tlv = TLV["pressure"]
	data["environment_data"] += list(list(
							"id" = "pressure",
							"name" = "Pressure",
							"value" = pressure,
							"unit" = "kPa",
							"danger_level" = cur_tlv.get_danger_level(pressure),
							"tlv" = cur_tlv.ui_list()
	))
	var/temperature = environment.return_temperature()
	cur_tlv = TLV["temperature"]
	data["environment_data"] += list(list(
							"id" = "temperature",
							"name" = "Temperature",
							"value" = temperature,
							"unit" = "K",
							"danger_level" = cur_tlv.get_danger_level(temperature),
							"tlv" = cur_tlv.ui_list()
	))
	var/total_moles = environment.total_moles()
	var/partial_pressure = R_IDEAL_GAS_EQUATION * environment.return_temperature() / environment.return_volume()
	for(var/gas_id in environment.get_gases())
		if(!(gas_id in TLV)) // We're not interested in this gas, it seems.
			continue
		cur_tlv = TLV[gas_id]
		// Порог газа проверяется по парциальному давлению, а показывается процент
		// от смеси. Интерфейсу нужны обе величины, иначе "0.1 %" рядом с красным
		// флажком выглядит как ошибка прибора.
		var/gas_partial_pressure = environment.get_moles(gas_id) * partial_pressure
		data["environment_data"] += list(list(
								"id" = gas_id,
								"name" = GLOB.gas_data.names[gas_id],
								"value" = environment.get_moles(gas_id) / total_moles * 100,
								"unit" = "%",
								"partial_pressure" = gas_partial_pressure,
								"danger_level" = cur_tlv.get_danger_level(gas_partial_pressure),
								"tlv" = cur_tlv.ui_list()
		))

	if(!locked || hasSiliconAccessInArea(user, PRIVILEGES_SILICON|PRIVILEGES_DRONE))
		data["vents"] = list()
		for(var/id_tag in A.air_vent_names)
			var/long_name = A.air_vent_names[id_tag]
			var/list/info = A.air_vent_info[id_tag]
			if(!info || info["frequency"] != frequency)
				continue
			data["vents"] += list(list(
					"id_tag"	= id_tag,
					"long_name" = sanitize(long_name),
					"power"		= info["power"],
					"checks"	= info["checks"],
					"excheck"	= info["checks"]&1,
					"incheck"	= info["checks"]&2,
					"direction"	= info["direction"],
					"external"	= info["external"],
					"internal"	= info["internal"],
					"extdefault"= (info["external"] == ONE_ATMOSPHERE),
					"intdefault"= (info["internal"] == 0)
				))
		data["scrubbers"] = list()
		for(var/id_tag in A.air_scrub_names)
			var/long_name = A.air_scrub_names[id_tag]
			var/list/info = A.air_scrub_info[id_tag]
			if(!info || info["frequency"] != frequency)
				continue
			data["scrubbers"] += list(list(
					"id_tag"				= id_tag,
					"long_name" 			= sanitize(long_name),
					"power"					= info["power"],
					"scrubbing"				= info["scrubbing"],
					"widenet"				= info["widenet"],
					"filter_types"			= info["filter_types"]
				))
		data["mode"] = mode
		// Идентификаторы режимов, на которые завязан обзорный экран: пусть
		// tgui не хардкодит числа из #define, которые здесь же и #undef'ятся.
		data["panic_mode"] = AALARM_MODE_PANIC
		data["filtering_mode"] = AALARM_MODE_SCRUBBING
		data["modes"] = list()
		for(var/mode_id in GLOB.air_alarm_modes)
			var/datum/air_alarm_mode/mode_data = GLOB.air_alarm_modes[mode_id]
			if(mode_data.emag_only && !(obj_flags & EMAGGED))
				continue
			data["modes"] += list(list(
				"name" = mode_data.ui_name || mode_data.name,
				"description" = mode_data.description,
				"mode" = mode_data.id,
				"selected" = mode == mode_data.id,
				"danger" = mode_data.danger,
			))

		var/list/thresholds = list()
		var/list/row = build_threshold_row("pressure", "Pressure", "kPa")
		if(row)
			thresholds += list(row)
		row = build_threshold_row("temperature", "Temperature", "K")
		if(row)
			thresholds += list(row)
		for(var/gas_id in GLOB.gas_data.names)
			if(!(gas_id in TLV)) // We're not interested in this gas, it seems.
				continue
			// Пороги газов задаются в парциальном давлении, а не в процентах:
			// без подписи единиц игрок вводит проценты и не понимает, почему
			// тревога не срабатывает.
			row = build_threshold_row(gas_id, GLOB.gas_data.names[gas_id], "kPa")
			if(row)
				thresholds += list(row)

		data["thresholds"] = thresholds
	return data

///Одна строка таблицы порогов для tgui: текущие значения, заводские и единицы.
/obj/machinery/airalarm/proc/build_threshold_row(env, display_name, unit)
	var/datum/tlv/selected = TLV[env]
	if(!selected)
		return null
	var/list/factory = selected.defaults
	var/list/settings = list()
	for(var/threshold_var in list("min2", "min1", "max1", "max2"))
		settings += list(list(
			"env" = env,
			"val" = threshold_var,
			"selected" = selected.vars[threshold_var],
			"default" = factory ? factory[threshold_var] : null,
		))
	return list(
		"env" = env,
		"name" = display_name,
		"unit" = unit,
		"is_default" = selected.is_at_defaults(),
		"settings" = settings,
	)

/obj/machinery/airalarm/ui_act(action, params)
	if(..() || buildstage != 2)
		return
	var/silicon_access = hasSiliconAccessInArea(usr)
	var/bot_privileges = silicon_access || (usr.silicon_privileges & PRIVILEGES_DRONE)
	if((locked && !bot_privileges) || (silicon_access && aidisabled))
		return
	var/device_id = params["id_tag"]
	switch(action)
		if("lock")
			if(bot_privileges && !wires.is_cut(WIRE_IDSCAN))
				locked = !locked
				. = TRUE
		if("power", "toggle_filter", "widenet", "scrubbing")
			send_signal(device_id, list("[action]" = params["val"]), usr)
			. = TRUE
		if("excheck")
			send_signal(device_id, list("checks" = text2num(params["val"])^1), usr)
			. = TRUE
		if("incheck")
			send_signal(device_id, list("checks" = text2num(params["val"])^2), usr)
			. = TRUE
		if("direction")
			send_signal(device_id, list("direction" = text2num(params["val"])), usr)
			. = TRUE
		if("set_external_pressure", "set_internal_pressure")

			var/target = params["value"]
			if(!isnull(target))

				send_signal(device_id, list("[action]" = target), usr)
				. = TRUE
		if("reset_external_pressure")
			send_signal(device_id, list("reset_external_pressure"), usr)
			. = TRUE
		if("reset_internal_pressure")
			send_signal(device_id, list("reset_internal_pressure"), usr)
			. = TRUE
		if("threshold")
			// Значение приходит из tgui-модалки. Раньше здесь стоял блокирующий
			// input(): окно алярма замирало до ответа, а брошенный диалог
			// продолжал держать ссылку на игрока после дисконнекта.
			var/env = params["env"]
			var/name = params["var"]
			if(!set_threshold(env, name, text2num(params["value"])))
				return
			investigate_log(" treshold value for [env]:[name] was set to [params["value"]] by [key_name(usr)]",INVESTIGATE_ATMOS)
			. = TRUE
		if("reset_threshold")
			var/datum/tlv/tlv = TLV[params["env"]]
			if(isnull(tlv) || !tlv.reset_to_defaults())
				return
			investigate_log(" treshold values for [params["env"]] were reset by [key_name(usr)]", INVESTIGATE_ATMOS)
			. = TRUE
		if("set_all_filters")
			. = set_all_filters(device_id, text2num(params["val"]), usr)
		if("power_all")
			. = power_all_devices(params["target"], text2num(params["val"]), usr)
		if("mode")
			var/new_mode = text2num(params["mode"])
			var/datum/air_alarm_mode/mode_data = get_air_alarm_mode(new_mode)
			if(!mode_data || (mode_data.emag_only && !(obj_flags & EMAGGED)))
				return
			mode = new_mode
			investigate_log("was turned to [get_mode_name(mode)] mode by [key_name(usr)]",INVESTIGATE_ATMOS)
			apply_mode()
			. = TRUE
		if("alarm")
			if(alarm_manager.send_alarm(ALARM_ATMOS))
				post_alert(2, AALARM_CAUSE_MANUAL)
			. = TRUE
		if("reset")
			if(alarm_manager.clear_alarm(ALARM_ATMOS))
				post_alert(0)
			. = TRUE
	if(.)
		// settings changed (thresholds, mode, vent/scrubber orders): re-read the air on the very
		// next fire instead of coasting on the adaptive backoff
		process_interval = 1
		process_skips_left = 0
	update_icon()

/obj/machinery/airalarm/proc/reset(wire)
	switch(wire)
		if(WIRE_POWER)
			if(!wires.is_cut(WIRE_POWER))
				shorted = FALSE
				update_icon()
		if(WIRE_AI)
			if(!wires.is_cut(WIRE_AI))
				aidisabled = FALSE


/obj/machinery/airalarm/proc/shock(mob/user, prb)
	if((machine_stat & (NOPOWER)))		// unpowered, no shock
		return FALSE
	if(!prob(prb))
		return FALSE //you lucked out, no shock for you
	var/datum/effect_system/spark_spread/s = new /datum/effect_system/spark_spread
	s.set_up(5, 1, src)
	s.start() //sparks always.
	if (electrocute_mob(user, get_area(src), src, 1, TRUE))
		return TRUE
	else
		return FALSE

/obj/machinery/airalarm/proc/refresh_all()
	var/area/A = get_base_area(src)
	for(var/id_tag in A.air_vent_names)
		var/list/I = A.air_vent_info[id_tag]
		if(I && I["timestamp"] + AALARM_REPORT_TIMEOUT / 2 > world.time)
			continue
		send_signal(id_tag, list("status"))
	for(var/id_tag in A.air_scrub_names)
		var/list/I = A.air_scrub_info[id_tag]
		if(I && I["timestamp"] + AALARM_REPORT_TIMEOUT / 2 > world.time)
			continue
		send_signal(id_tag, list("status"))

/obj/machinery/airalarm/proc/set_frequency(new_frequency)
	SSradio.remove_object(src, frequency)
	frequency = new_frequency
	radio_connection = SSradio.add_object(src, frequency, RADIO_TO_AIRALARM)

/obj/machinery/airalarm/proc/send_signal(target, list/command, mob/user)//sends signal 'command' to 'target'. Returns 0 if no radio connection, 1 otherwise
	if(!radio_connection)
		return FALSE

	var/datum/signal/signal = new(command)
	signal.data["tag"] = target
	signal.data["sigtype"] = "command"
	signal.data["user"] = user
	radio_connection.post_signal(src, signal, RADIO_FROM_AIRALARM)

	return TRUE

///Запись одного порога. Отдельным проком, потому что значение уходит в
///tlv.vars[]: белый список полей обязан жить ровно в одном месте, иначе
///params["var"] из интерфейса пишет в любую переменную датума.
/obj/machinery/airalarm/proc/set_threshold(env, threshold_var, value)
	if(!(threshold_var in AALARM_THRESHOLD_VARS))
		return FALSE
	var/datum/tlv/tlv = TLV[env]
	if(isnull(tlv) || isnull(value))
		return FALSE
	tlv.vars[threshold_var] = value < 0 ? -1 : round(value, 0.01)
	return TRUE

///Разом гасит или поднимает все фильтры одного скруббера. Руками это
///пятнадцать с лишним кликов по кнопкам-плиткам.
/obj/machinery/airalarm/proc/set_all_filters(device_id, enable, mob/user)
	if(!device_id)
		return FALSE
	var/area/our_area = get_base_area(src)
	var/list/info = our_area.air_scrub_info[device_id]
	if(!info)
		return FALSE
	var/list/gas_ids = list()
	if(enable)
		for(var/list/filter as anything in info["filter_types"])
			gas_ids += filter["gas_id"]
	send_signal(device_id, list("set_filters" = gas_ids), user)
	investigate_log("set every filter on [device_id] [enable ? "on" : "off"] by [key_name(user)]", INVESTIGATE_ATMOS)
	return TRUE

///Массовое включение/выключение всех вентов или всех скрубберов зоны.
/obj/machinery/airalarm/proc/power_all_devices(target, enable, mob/user)
	var/area/our_area = get_base_area(src)
	var/list/device_names
	switch(target)
		if("vents")
			device_names = our_area.air_vent_names
		if("scrubbers")
			device_names = our_area.air_scrub_names
		else
			return FALSE
	if(!length(device_names))
		return FALSE
	for(var/device_id in device_names)
		send_signal(device_id, list("power" = enable), user)
	investigate_log("turned every [target] in [our_area] [enable ? "on" : "off"] by [key_name(user)]", INVESTIGATE_ATMOS)
	return TRUE

/obj/machinery/airalarm/proc/get_mode_name(mode_value)
	var/datum/air_alarm_mode/mode_data = get_air_alarm_mode(mode_value)
	return mode_data?.name || "Unknown"

/obj/machinery/airalarm/proc/apply_mode()
	var/datum/air_alarm_mode/mode_data = get_air_alarm_mode(mode)
	if(mode_data)
		mode_data.apply(src)

/obj/machinery/airalarm/proc/apply_mode_commands(mode_to_apply)
	var/area/A = get_base_area(src)
	switch(mode_to_apply)
		if(AALARM_MODE_SCRUBBING)
			for(var/device_id in A.air_scrub_names)
				send_signal(device_id, list(
					"power" = 1,
					"set_filters" = list(GAS_CO2, GAS_MIASMA, GAS_GROUP_CHEMICALS),
					"scrubbing" = 1,
					"widenet" = 0,
				))
			for(var/device_id in A.air_vent_names)
				send_signal(device_id, list(
					"power" = 1,
					"checks" = 1,
					"set_external_pressure" = ONE_ATMOSPHERE
				))
		if(AALARM_MODE_CONTAMINATED)
			var/list/all_gases = GLOB.gas_data.get_by_flag(GAS_FLAG_DANGEROUS)
			for(var/device_id in A.air_scrub_names)
				send_signal(device_id, list(
					"power" = 1,
					"set_filters" = all_gases,
					"scrubbing" = 1,
					"widenet" = 1,
				))
			for(var/device_id in A.air_vent_names)
				send_signal(device_id, list(
					"power" = 1,
					"checks" = 1,
					"set_external_pressure" = ONE_ATMOSPHERE
				))
		if(AALARM_MODE_VENTING)
			for(var/device_id in A.air_scrub_names)
				send_signal(device_id, list(
					"power" = 1,
					"widenet" = 0,
					"scrubbing" = 0
				))
			for(var/device_id in A.air_vent_names)
				send_signal(device_id, list(
					"is_pressurizing" = 1,
					"power" = 1,
					"checks" = 1,
					"set_external_pressure" = ONE_ATMOSPHERE*1.4
				))
				send_signal(device_id, list(
					"is_siphoning" = 1,
					"power" = 1,
					"checks" = 1,
					"set_external_pressure" = ONE_ATMOSPHERE/1.4
				))
		if(AALARM_MODE_REFILL)
			for(var/device_id in A.air_scrub_names)
				send_signal(device_id, list(
					"power" = 1,
					"set_filters" = list(GAS_CO2, GAS_MIASMA, GAS_GROUP_CHEMICALS),
					"scrubbing" = 1,
					"widenet" = 0,
				))
			for(var/device_id in A.air_vent_names)
				send_signal(device_id, list(
					"is_pressurizing" = 1,
					"power" = 1,
					"checks" = 1,
					"set_external_pressure" = ONE_ATMOSPHERE * 3
				))
				send_signal(device_id, list(
					"is_siphoning" = 1,
					"power" = 0,
				))
		if(AALARM_MODE_PANIC,
			AALARM_MODE_REPLACEMENT)
			for(var/device_id in A.air_scrub_names)
				send_signal(device_id, list(
					"power" = 1,
					"widenet" = 1,
					"scrubbing" = 0
				))
			for(var/device_id in A.air_vent_names)
				send_signal(device_id, list(
					"is_pressurizing" = 1,
					"power" = 0
				))
				send_signal(device_id, list(
					"is_siphoning" = 1,
					"power" = 1,
					"checks" = 0
				))
		if(AALARM_MODE_SIPHON)
			for(var/device_id in A.air_scrub_names)
				send_signal(device_id, list(
					"power" = 1,
					"widenet" = 0,
					"scrubbing" = 0
				))
			for(var/device_id in A.air_vent_names)
				send_signal(device_id, list(
					"is_pressurizing" = 1,
					"power" = 0
				))
				send_signal(device_id, list(
					"is_siphoning" = 1,
					"power" = 1,
					"checks" = 0
				))
		if(AALARM_MODE_OFF)
			for(var/device_id in A.air_scrub_names)
				send_signal(device_id, list(
					"power" = 0
				))
			for(var/device_id in A.air_vent_names)
				send_signal(device_id, list(
					"power" = 0
				))
		if(AALARM_MODE_FLOOD)
			for(var/device_id in A.air_scrub_names)
				send_signal(device_id, list(
					"power" = 0
				))
			for(var/device_id in A.air_vent_names)
				send_signal(device_id, list(
					"power" = 1,
					"checks" = 0,
					"is_pressurizing" = 1
				))
				send_signal(device_id, list(
					"power" = 0,
					"is_siphoning" = 1
				))

/obj/machinery/airalarm/update_icon_state()
	if(machine_stat & NOPOWER)
		icon_state = "alarm0"
		return

	if(machine_stat & BROKEN)
		icon_state = "alarm_broken"
		return

	if(!panel_open)
		icon_state = "alarm1"
		return

	switch(buildstage)
		if(2)
			icon_state = "alarmx"
		if(1)
			icon_state = "alarm_b2"
		if(0)
			icon_state = "alarm_b1"

/obj/machinery/airalarm/update_overlays()
	. = ..()
	SSvis_overlays.remove_vis_overlay(src, managed_vis_overlays)
	var/overlay_state = AALARM_OVERLAY_OFF
	var/area/our_area = get_base_area(src)
	switch(max(danger_level, !!our_area.active_alarms[ALARM_ATMOS]))
		if(0)
			overlay_state = AALARM_OVERLAY_GREEN
			light_color = LIGHT_COLOR_GREEN
		if(1)
			overlay_state = AALARM_OVERLAY_WARN
			light_color = LIGHT_COLOR_LAVA
		if(2)
			overlay_state = AALARM_OVERLAY_DANGER
			light_color = LIGHT_COLOR_RED

	if(overlay_state != AALARM_OVERLAY_OFF)
		. += overlay_state
		set_light(brightness_on)
	else
		set_light(0)

	SSvis_overlays.add_vis_overlay(src, icon, overlay_state, layer, plane, dir)
	SSvis_overlays.add_vis_overlay(src, icon, overlay_state, EMISSIVE_LAYER, EMISSIVE_PLANE, dir)
	update_light()

/obj/machinery/airalarm/process()
	if((machine_stat & (NOPOWER|BROKEN)) || shorted)
		return

	// While danger_level has been stable, skip the (relatively expensive) turf air read on
	// most fires. Snaps back to reading every fire the moment danger_level changes (below).
	// Exception: if the monitored turf has just entered active atmos exchange it may be drifting
	// toward a hazard, so cut the backoff short and read now instead of coasting up to ~30s blind.
	if(process_skips_left > 0)
		var/turf/open/open_location = get_turf(src)
		if(!istype(open_location) || (!open_location.excited && !open_location.excited_group))
			process_skips_left--
			return
		process_skips_left = 0

	var/turf/location = get_turf(src)
	if(!location)
		return

	var/datum/tlv/cur_tlv

	// Read the mixture's fields directly and walk its gas list once. Every accessor here is a
	// one-line getter, and the old shape paid for two separate walks of the gas list (total_moles()
	// inside return_pressure(), then the per-gas danger pass) plus a get_moles() dispatch per gas.
	// That is ~20 proc calls per alarm per SSmachines fire, on ~400 alarms, forever - the dominant
	// cost of the whole machinery pass on a live station. Same arithmetic, same danger levels.
	var/datum/gas_mixture/environment = location.return_air()
	var/list/environment_gases = environment.gases
	var/environment_temperature = environment.temperature
	var/environment_volume = max(0, environment.volume)

	var/total_moles = 0
	for(var/gas_id in environment_gases)
		total_moles += environment_gases[gas_id]

	// Both expressions keep the exact operand order the accessors used, so the arithmetic is
	// bit-identical to before. return_pressure() reported 0 for a volumeless mixture; the
	// per-mole scale now shares that guard, where the old expression divided by zero instead.
	var/environment_pressure = environment_volume > 0 ? total_moles * R_IDEAL_GAS_EQUATION * environment_temperature / environment_volume : 0
	var/pressure_per_mole = environment_volume > 0 ? R_IDEAL_GAS_EQUATION * environment_temperature / environment_volume : 0

	cur_tlv = TLV["pressure"]
	var/pressure_dangerlevel = cur_tlv.get_danger_level(environment_pressure)

	cur_tlv = TLV["temperature"]
	var/temperature_dangerlevel = cur_tlv.get_danger_level(environment_temperature)

	var/gas_dangerlevel = 0
	var/worst_gas
	for(var/gas_id in environment_gases)
		cur_tlv = TLV[gas_id]
		if(!cur_tlv) // We're not interested in this gas, it seems.
			continue
		var/this_gas_level = cur_tlv.get_danger_level(environment_gases[gas_id] * pressure_per_mole)
		if(this_gas_level > gas_dangerlevel)
			gas_dangerlevel = this_gas_level
			worst_gas = gas_id

	var/old_danger_level = danger_level
	danger_level = max(pressure_dangerlevel, temperature_dangerlevel, gas_dangerlevel)
	// Что именно вылезло за порог. Консоль тревог показывала одно имя зоны, и
	// понять по ней, бежать с огнетушителем или с баллоном, было нельзя.
	if(!danger_level)
		danger_source = null
		danger_source_gas = null
	else if(pressure_dangerlevel == danger_level)
		danger_source = AALARM_CAUSE_PRESSURE
		danger_source_gas = null
	else if(temperature_dangerlevel == danger_level)
		danger_source = AALARM_CAUSE_TEMPERATURE
		danger_source_gas = null
	else
		danger_source = AALARM_CAUSE_GAS
		danger_source_gas = worst_gas

	if(old_danger_level != danger_level)
		apply_danger_level()

	// Adaptive backoff: read every fire while danger_level is moving (or we're mid-air-replacement
	// and watching for the pressure cutoff); coast at AALARM_MAX_PROCESS_INTERVAL once it settles.
	// A turf parked outside active atmos exchange cannot drift at all, so coast much longer there.
	if(old_danger_level != danger_level || mode == AALARM_MODE_REPLACEMENT)
		process_interval = 1
	else
		var/max_interval = AALARM_MAX_PROCESS_INTERVAL
		var/turf/open/open_location = location
		if(!istype(open_location) || (!open_location.excited && !open_location.excited_group))
			max_interval = AALARM_INACTIVE_PROCESS_INTERVAL
		process_interval = min(process_interval + 1, max_interval)
	process_skips_left = process_interval - 1

	if(mode == AALARM_MODE_REPLACEMENT && environment_pressure < ONE_ATMOSPHERE * 0.05)
		mode = AALARM_MODE_SCRUBBING
		apply_mode()

	return


/obj/machinery/airalarm/proc/post_alert(alert_level, cause, cause_gas)
	var/datum/radio_frequency/frequency = SSradio.return_frequency(alarm_frequency)

	if(!frequency)
		return

	var/datum/signal/alert_signal = new(list(
		"zone" = get_area_name(src, get_base_area = TRUE),
		"type" = "Atmospheric",
		// Причина едет вместе с тревогой: одного имени зоны инженеру мало,
		// чтобы решить, что брать с собой.
		"cause" = cause,
		"cause_gas" = cause_gas,
		"source" = "[src]"
	))
	if(alert_level==2)
		alert_signal.data["alert"] = "severe"
	else if (alert_level==1)
		alert_signal.data["alert"] = "minor"
	else if (alert_level==0)
		alert_signal.data["alert"] = "clear"

	frequency.post_signal(src, alert_signal, range = -1)

/obj/machinery/airalarm/proc/apply_danger_level()
	var/area/A = get_base_area(src)
	var/new_area_danger_level = 0
	var/obj/machinery/airalarm/loudest
	for(var/obj/machinery/airalarm/AA in A)
		if (!(AA.machine_stat & (NOPOWER|BROKEN)) && !AA.shorted)
			new_area_danger_level = clamp(max(new_area_danger_level, AA.danger_level), 0, 1)
			if(AA.danger_level && (!loudest || AA.danger_level > loudest.danger_level))
				loudest = AA

	var/did_anything_happen
	if(new_area_danger_level)
		did_anything_happen = alarm_manager.send_alarm(ALARM_ATMOS)
	else
		did_anything_happen = alarm_manager.clear_alarm(ALARM_ATMOS)
	if(did_anything_happen) //if something actually changed
		post_alert(new_area_danger_level, loudest?.danger_source, loudest?.danger_source_gas)

	update_icon()

/obj/machinery/airalarm/attackby(obj/item/W, mob/user, params)
	switch(buildstage)
		if(2)
			if(W.tool_behaviour == TOOL_WIRECUTTER && panel_open && wires.is_all_cut())
				W.play_tool_sound(src)
				to_chat(user, "<span class='notice'>You cut the final wires.</span>")
				new /obj/item/stack/cable_coil(loc, 5)
				buildstage = 1
				update_icon()
				return
			else if(W.tool_behaviour == TOOL_SCREWDRIVER)  // Opening that Air Alarm up.
				W.play_tool_sound(src)
				panel_open = !panel_open
				to_chat(user, "<span class='notice'>The wires have been [panel_open ? "exposed" : "unexposed"].</span>")
				update_icon()
				return
			else if(istype(W, /obj/item/card/id) || istype(W, /obj/item/modular_computer/pda))// trying to unlock the interface with an ID card
				togglelock(user)
			else if(panel_open && is_wire_tool(W))
				wires.interact(user)
				return
		if(1)
			if(W.tool_behaviour == TOOL_CROWBAR)
				user.visible_message("[user.name] removes the electronics from [src.name].",\
									"<span class='notice'>You start prying out the circuit...</span>")
				W.play_tool_sound(src)
				if (W.use_tool(src, user, 20))
					if (buildstage == 1)
						to_chat(user, "<span class='notice'>You remove the air alarm electronics.</span>")
						new /obj/item/electronics/airalarm( src.loc )
						playsound(src.loc, 'sound/items/deconstruct.ogg', 50, 1)
						buildstage = 0
						update_icon()
				return

			if(istype(W, /obj/item/stack/cable_coil))
				var/obj/item/stack/cable_coil/cable = W
				if(cable.get_amount() < 5)
					to_chat(user, "<span class='warning'>You need five lengths of cable to wire the air alarm!</span>")
					return
				user.visible_message("[user.name] wires the air alarm.", \
									"<span class='notice'>You start wiring the air alarm...</span>")
				if (W.use_tool(src, user, 20, 5))
					if (buildstage == 1)
						to_chat(user, "<span class='notice'>You wire the air alarm.</span>")
						wires.repair()
						aidisabled = 0
						locked = FALSE
						mode = 1
						shorted = 0
						post_alert(0)
						buildstage = 2
						update_icon()
				return
		if(0)
			if(istype(W, /obj/item/electronics/airalarm))
				if(user.temporarilyRemoveItemFromInventory(W))
					to_chat(user, "<span class='notice'>You insert the circuit.</span>")
					buildstage = 1
					update_icon()
					qdel(W)
				return

			if(istype(W, /obj/item/electroadaptive_pseudocircuit))
				var/obj/item/electroadaptive_pseudocircuit/P = W
				if(!P.adapt_circuit(user, 25))
					return
				user.visible_message("<span class='notice'>[user] fabricates a circuit and places it into [src].</span>", \
				"<span class='notice'>You adapt an air alarm circuit and slot it into the assembly.</span>")
				buildstage = 1
				update_icon()
				return

			if(W.tool_behaviour == TOOL_WRENCH)
				to_chat(user, "<span class='notice'>You detach \the [src] from the wall.</span>")
				W.play_tool_sound(src)
				new /obj/item/wallframe/airalarm( user.loc )
				qdel(src)
				return

	return ..()

/obj/machinery/airalarm/rcd_vals(mob/user, obj/item/construction/rcd/the_rcd)
	if((buildstage == 0) && (the_rcd.upgrade & RCD_UPGRADE_SIMPLE_CIRCUITS))
		return list("mode" = RCD_UPGRADE_SIMPLE_CIRCUITS, "delay" = 20, "cost" = 1)
	return FALSE

/obj/machinery/airalarm/rcd_act(mob/user, obj/item/construction/rcd/the_rcd, passed_mode)
	switch(passed_mode)
		if(RCD_UPGRADE_SIMPLE_CIRCUITS)
			user.visible_message("<span class='notice'>[user] fabricates a circuit and places it into [src].</span>", \
			"<span class='notice'>You adapt an air alarm circuit and slot it into the assembly.</span>")
			buildstage = 1
			update_icon()
			return TRUE
	return FALSE

/obj/machinery/airalarm/AltClick(mob/user)
	. = ..()
	if(!user.canUseTopic(src, !hasSiliconAccessInArea(user)) || !isturf(loc))
		return
	togglelock(user)
	return TRUE

/obj/machinery/airalarm/proc/togglelock(mob/living/user)
	if(machine_stat & (NOPOWER|BROKEN))
		to_chat(user, "<span class='warning'>It does nothing!</span>")
	else
		if(src.allowed(usr) && !wires.is_cut(WIRE_IDSCAN))
			locked = !locked
			updateUsrDialog()
			to_chat(user, "<span class='notice'>You [ locked ? "lock" : "unlock"] the air alarm interface.</span>")
		else
			to_chat(user, "<span class='danger'>Доступ запрещён.</span>")
	return

/obj/machinery/airalarm/power_change()
	..()
	if(machine_stat & NOPOWER)
		set_light(0)
	update_icon()

/obj/machinery/airalarm/emag_act(mob/user)
	. = ..()
	if(obj_flags & EMAGGED)
		return
	log_admin("[key_name(usr)] emagged [src] at [AREACOORD(src)]")
	obj_flags |= EMAGGED
	visible_message("<span class='warning'>Sparks fly out of [src]!</span>", "<span class='notice'>You emag [src], disabling its safeties.</span>")
	playsound(src, "sparks", 50, 1)
	return TRUE

/obj/machinery/airalarm/obj_break(damage_flag)
	..()
	update_icon()
	set_light(0)

/obj/machinery/airalarm/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		new /obj/item/stack/sheet/metal(loc, 2)
		var/obj/item/I = new /obj/item/electronics/airalarm(loc)
		if(!disassembled)
			I.obj_integrity = I.max_integrity * 0.5
		new /obj/item/stack/cable_coil(loc, 3)
	qdel(src)

/obj/machinery/airalarm/proc/handle_decomp_alarm()
	if(!is_operational || !COOLDOWN_FINISHED(src, decomp_alarm))
		return
	var/area/A = get_base_area(src)
	A.firealert(src)
	playsound(loc, 'goon/sound/machinery/FireAlarm.ogg', 75)
	COOLDOWN_START(src, decomp_alarm, 1 SECONDS)

#undef AALARM_MODE_SCRUBBING
#undef AALARM_MODE_VENTING
#undef AALARM_MODE_PANIC
#undef AALARM_MODE_REPLACEMENT
#undef AALARM_MODE_OFF
#undef AALARM_MODE_FLOOD
#undef AALARM_MODE_SIPHON
#undef AALARM_MODE_CONTAMINATED
#undef AALARM_MODE_REFILL
#undef AALARM_REPORT_TIMEOUT
#undef AALARM_THRESHOLD_VARS
