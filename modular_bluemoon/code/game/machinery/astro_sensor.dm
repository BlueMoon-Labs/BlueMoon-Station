/**
 * # Астрометрический сенсор
 *
 * Направленная тарелка, которую ставят у иллюминатора и наводят на явление за бортом.
 * Пока за окном обычный космос, сенсор молчит. Когда идёт космическая погода, он даёт
 * две вещи: РАЗВЕДКУ (какая фаза, сколько до пика, что именно на пике будет) и ДАННЫЕ
 * (исследовательские очки тем больше, чем выше интенсивность явления).
 *
 * Сенсор НЕ защищает. Явление бьёт по станции одинаково, есть он на борту или нет.
 * Он говорит когда и куда, чтобы отделы успели подготовиться, но подготовка - отдельная
 * работа. Станция без сенсора играет событие целиком, просто вслепую.
 *
 * # Петля
 *
 * Усиление против нагрева. Нагрев растёт как усиление на интенсивность, поэтому на
 * подходе можно безнаказанно выкрутить тарелку на максимум, а на пике то же усиление
 * сожжёт приёмник меньше чем за минуту. Оптимум двигается вместе с фазой явления, и
 * решение приходится принимать в реальном времени, а не выставить один раз и уйти.
 *
 * Выдача за одно явление ограничена сверху: сенсор - повод прийти и поработать в нужный
 * момент, а не постоянный источник очков.
 */

/// Базовая дальность обзора в тайлах, до вклада микролазера.
#define ASTRO_SENSOR_BASE_VIEW 5
/// Прибавка дальности за уровень микролазера.
#define ASTRO_SENSOR_VIEW_PER_TIER 3
/// Данных в секунду при полном усилении, полной интенсивности и базовом сканере.
#define ASTRO_SENSOR_DATA_RATE 22
/// Нагрев в секунду при полном усилении, полной интенсивности и базовом конденсаторе.
#define ASTRO_SENSOR_HEAT_RATE 3.2
/// Пассивное остывание в секунду. Задаёт усиление, которое можно держать вечно:
/// на полной интенсивности это ровно COOL / HEAT долей шкалы усиления.
#define ASTRO_SENSOR_COOL_RATE 1
/// Доля нагрева, с которой консоль начинает предупреждать.
#define ASTRO_SENSOR_HEAT_WARNING 0.7

/obj/machinery/astro_sensor
	name = "астрометрический сенсор"
	desc = "Направленная тарелка Отдела Астрономии NanoTrasen. Считывает спектр явления \
		за бортом и переводит его в исследовательские данные. Требует прямого обзора \
		космоса: наводится в ту сторону, куда смотрит."
	icon = 'icons/obj/machines/astro_sensor.dmi'
	icon_state = "astro_sensor"
	density = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = 50
	active_power_usage = 900
	max_integrity = 200
	integrity_failure = 0.4
	circuit = /obj/item/circuitboard/machine/astro_sensor

	/// Усиление приёмника, 0..1. Единственный рычаг игрока.
	var/gain = 0.3
	/// Нагрев приёмника, 0..heat_limit.
	var/heat = 0
	/// Нагрев, на котором приёмник выгорает.
	var/heat_limit = 100
	/// Потолок выдачи за одно явление, до множителя самого явления. Сопоставим с хорошим
	/// экспериментом: сенсор - повод прийти в нужный момент, а не источник дохода.
	var/base_yield = 700
	/// Накоплено данных за текущее явление. Показывается на консоли.
	var/collected = 0
	/// Уже отдано очков за текущее явление. Против потолка выдачи.
	var/yielded = 0
	/// Тип явления, за которым идёт наблюдение. Хранится ТИППАС, а не ссылка на событие:
	/// ссылка на удаляемый датум - это лишний держатель и лишний харддел на ровном месте.
	var/tracked_type
	/// Множитель темпа сбора от сканирующего модуля.
	var/sensitivity = 1
	/// Делитель нагрева от конденсатора.
	var/heat_capacity = 1
	/// Дальность обзора в тайлах, от микролазера.
	var/view_range = ASTRO_SENSOR_BASE_VIEW + ASTRO_SENSOR_VIEW_PER_TIER
	/// Видит ли сенсор космос. Пересчитывается в process(), читается интерфейсом.
	var/sees_space = FALSE

/obj/machinery/astro_sensor/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/simple_rotation, ROTATION_ALTCLICK | ROTATION_CLOCKWISE)

/obj/machinery/astro_sensor/RefreshParts()
	var/scanning_rating = 0
	for(var/obj/item/stock_parts/scanning_module/module in component_parts)
		scanning_rating += module.rating
	var/capacitor_rating = 0
	for(var/obj/item/stock_parts/capacitor/capacitor in component_parts)
		capacitor_rating += capacitor.rating
	var/laser_rating = 0
	for(var/obj/item/stock_parts/micro_laser/laser in component_parts)
		laser_rating += laser.rating
	sensitivity = 0.7 + 0.3 * max(scanning_rating, 1)
	heat_capacity = 0.85 + 0.15 * max(capacitor_rating, 1)
	view_range = ASTRO_SENSOR_BASE_VIEW + ASTRO_SENSOR_VIEW_PER_TIER * max(laser_rating, 1)

/obj/machinery/astro_sensor/examine(mob/user, silent = FALSE)
	. = ..()
	if(machine_stat & BROKEN)
		. += span_warning("Приёмник выгорел. Заменить его можно сварочником.")
		return
	. += span_notice("Обзор: [sees_space ? "открыт" : "ПЕРЕКРЫТ"]. Дальность наводки - [view_range] м.")
	. += span_notice("Усиление [round(gain * 100)]%, нагрев приёмника [round(heat)]%.")

// ---------------------------------------------------------------------------
// Обзор
// ---------------------------------------------------------------------------

/**
 * Видит ли сенсор космос.
 *
 * Трассируем от машины по её направлению и засчитываем первый же космический турф.
 * Идём, пока путь прозрачен для взгляда: иллюминатор и решётка пропускают, стена и
 * закрытый ставень - нет. Поэтому сенсор в шкафу техобслуживания не работает, а
 * сенсор у окна работает, и выбор места становится частью постройки.
 */
/obj/machinery/astro_sensor/proc/has_space_view()
	var/turf/checked = get_turf(src)
	if(!checked)
		return FALSE
	for(var/steps in 1 to view_range)
		checked = get_step(checked, dir)
		if(!checked)
			return FALSE
		if(isspaceturf(checked))
			return TRUE
		if(checked.opacity)
			return FALSE
		for(var/atom/movable/blocker as anything in checked)
			if(blocker.opacity)
				return FALSE
	return FALSE

// ---------------------------------------------------------------------------
// Наблюдение
// ---------------------------------------------------------------------------

/obj/machinery/astro_sensor/process(seconds_per_tick)
	if(machine_stat & (NOPOWER|BROKEN))
		update_appearance()
		return

	sees_space = has_space_view()
	var/datum/round_event/space_weather/phenomenon = active_space_phenomenon()

	// Смена явления обнуляет и накопленное, и израсходованный потолок: потолок задан
	// НА ЯВЛЕНИЕ, а не на смену, иначе один сенсор за раунд выбирал бы его целиком.
	if(phenomenon?.type != tracked_type)
		tracked_type = phenomenon?.type
		collected = 0
		yielded = 0

	var/observing = phenomenon && sees_space
	var/intensity = observing ? phenomenon.intensity : 0
	use_power = (observing && gain > 0) ? ACTIVE_POWER_USE : IDLE_POWER_USE

	update_heat(intensity, seconds_per_tick)
	if(machine_stat & BROKEN)
		return
	if(observing)
		collect_data(phenomenon, intensity, seconds_per_tick)
	update_appearance()

/**
 * Ведёт нагрев приёмника.
 *
 * Остывание постоянно, нагрев растёт как усиление на интенсивность. Отсюда и решение
 * игрока: на подходе остывание перекрывает нагрев при любом усилении, на пике удержать
 * можно лишь треть шкалы, а всё сверх неё - ставка на то, что успеешь снять раньше,
 * чем выгорит приёмник.
 */
/obj/machinery/astro_sensor/proc/update_heat(intensity, seconds_per_tick)
	var/gained = gain * intensity * ASTRO_SENSOR_HEAT_RATE / heat_capacity
	heat = clamp(heat + (gained - ASTRO_SENSOR_COOL_RATE) * seconds_per_tick, 0, heat_limit)
	if(heat < heat_limit)
		return
	burn_out()

/// Выгорание приёмника: пока его не заменят сварочником, сенсор бесполезен, и явление
/// в это время идёт своим ходом. Цена ставки на высокое усиление.
/obj/machinery/astro_sensor/proc/burn_out()
	if(machine_stat & BROKEN)
		return
	visible_message(span_danger("[src] выбрасывает сноп искр - приёмник выгорел."))
	playsound(src, 'sound/machines/warning-buzzer.ogg', 50, TRUE)
	do_sparks(3, TRUE, src)
	gain = 0
	obj_break()
	update_appearance()

/**
 * Копит данные и отдаёт их в техвеб, пока не выбран потолок явления.
 *
 * Очки идут МИМО пассивного дохода (income = FALSE): вся петля сенсора построена на
 * том, что игрок ведёт усиление и видит отдачу прямо сейчас. Буфер до следующего
 * начисления оторвал бы обратную связь от действия.
 */
/obj/machinery/astro_sensor/proc/collect_data(datum/round_event/space_weather/phenomenon, intensity, seconds_per_tick)
	if((machine_stat & BROKEN) || gain <= 0 || intensity <= 0)
		return
	var/cap = base_yield * phenomenon.sensor_yield_mult
	if(yielded >= cap)
		return
	var/gathered = min(ASTRO_SENSOR_DATA_RATE * gain * intensity * sensitivity * seconds_per_tick, cap - yielded)
	collected += gathered
	yielded += gathered
	SSresearch.science_tech?.add_point_type(TECHWEB_POINT_TYPE_GENERIC, gathered, income = FALSE)

// ---------------------------------------------------------------------------
// Внешний вид и сборка
// ---------------------------------------------------------------------------

/obj/machinery/astro_sensor/update_icon_state()
	if(machine_stat & BROKEN)
		icon_state = "astro_sensor-broken"
	else if(machine_stat & NOPOWER)
		icon_state = "astro_sensor-off"
	else
		icon_state = "astro_sensor"
	return ..()

/obj/machinery/astro_sensor/attackby(obj/item/tool, mob/user, params)
	if(default_deconstruction_screwdriver(user, "astro_sensor-off", "astro_sensor", tool))
		update_appearance()
		return
	if(default_deconstruction_crowbar(tool))
		return
	return ..()

/**
 * Ремонт выгоревшего приёмника сваркой.
 *
 * Без него сломанный сенсор чинился бы только разбором и пересборкой: генерического
 * пути снять BROKEN у машинерии в кодовой базе нет. За проигранную ставку на усилении
 * надо платить, но платить минутой со сварочником, а не походом за новой платой.
 */
/obj/machinery/astro_sensor/welder_act(mob/living/user, obj/item/tool)
	if(user.a_intent == INTENT_HARM)
		return
	if(!(machine_stat & BROKEN))
		balloon_alert(user, "приёмник цел")
		return TRUE
	// use_tool с ненулевой задержкой стартовую проверку НЕ зовёт - она остаётся на
	// вызывающем. Без неё погашенный сварочник успевал бы отыграть звук и объявление
	// и отваливался только на первом тике do_after.
	if(!tool.tool_start_check(user, amount = 0))
		return TRUE
	user.balloon_alert_to_viewers("меняет приёмник...", "меняете приёмник...")
	if(!tool.use_tool(src, user, 8 SECONDS, amount = 0, volume = 50))
		return TRUE
	balloon_alert(user, "приёмник заменён")
	heat = 0
	set_machine_stat(machine_stat & ~BROKEN)
	update_appearance()
	return TRUE

/obj/machinery/astro_sensor/wrench_act(mob/living/user, obj/item/tool)
	. = ..()
	if(.)
		return
	// Клик поглощаем только тогда, когда откручивание вообще началось. На машине, которую
	// разбирать нельзя, безусловный успех съел бы удар молча - ни открутки, ни атаки.
	var/result = default_unfasten_wrench(user, tool, 4 SECONDS)
	if(result == CANT_UNFASTEN)
		return
	if(result == SUCCESSFUL_UNFASTEN)
		update_appearance()
	return TOOL_ACT_TOOLTYPE_SUCCESS

// ---------------------------------------------------------------------------
// Интерфейс
// ---------------------------------------------------------------------------

/obj/machinery/astro_sensor/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "AstroSensor", name)
		ui.open()

/obj/machinery/astro_sensor/ui_data(mob/user)
	var/list/data = list()
	data["gain"] = round(gain * 100)
	data["heat"] = round(heat / heat_limit * 100)
	data["heatWarning"] = round(ASTRO_SENSOR_HEAT_WARNING * 100)
	data["broken"] = !!(machine_stat & BROKEN)
	data["seesSpace"] = sees_space
	data["viewRange"] = view_range
	data["collected"] = round(collected)

	var/datum/round_event/space_weather/phenomenon = active_space_phenomenon()
	if(!phenomenon)
		data["phenomenon"] = null
		return data

	data["phenomenon"] = phenomenon.phenomenon_name
	data["phase"] = phenomenon.phase_name()
	data["intensity"] = round(phenomenon.intensity * 100)
	data["secondsToPeak"] = phenomenon.seconds_to_peak()
	data["readout"] = phenomenon.sensor_readout()
	data["yieldCap"] = round(base_yield * phenomenon.sensor_yield_mult)
	return data

/obj/machinery/astro_sensor/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	switch(action)
		if("gain")
			if(machine_stat & BROKEN)
				return TRUE
			gain = clamp(text2num(params["value"]) / 100, 0, 1)
			return TRUE

// ---------------------------------------------------------------------------
// Плата и чертёж
// ---------------------------------------------------------------------------

/obj/item/circuitboard/machine/astro_sensor
	name = "Astrometric Sensor (Machine Board)"
	icon_state = "science"
	build_path = /obj/machinery/astro_sensor
	req_components = list(
		/obj/item/stock_parts/scanning_module = 1,
		/obj/item/stock_parts/capacitor = 1,
		/obj/item/stock_parts/micro_laser = 1)

/datum/design/board/astro_sensor
	name = "Machine Design (Astrometric Sensor Board)"
	desc = "Плата астрометрического сенсора."
	id = "astro_sensor"
	build_path = /obj/item/circuitboard/machine/astro_sensor
	category = list("Research Machinery")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

#undef ASTRO_SENSOR_BASE_VIEW
#undef ASTRO_SENSOR_VIEW_PER_TIER
#undef ASTRO_SENSOR_DATA_RATE
#undef ASTRO_SENSOR_HEAT_RATE
#undef ASTRO_SENSOR_COOL_RATE
#undef ASTRO_SENSOR_HEAT_WARNING
