/**
 * # Кладбище кораблей
 *
 * Станция проходит сквозь поле списанных корпусов. Само поле остаётся фоном за
 * иллюминатором, а на пике из него к станции выносит обломки, до которых можно долететь
 * и которые можно разобрать.
 *
 * Возможность и риск здесь - одно и то же поле. Обломки дрейфуют у самого корпуса, но
 * один-два корпуса идут по курсу столкновения, и удар приходит в известный сектор.
 * Астрометрический сенсор называет сектор и время; без него объявление приходит тоже,
 * но общее. Явление с дедлайном: на уходе несобранное уносит вместе с полем.
 */

/// Сколько обломков выносит к станции на пике.
#define GRAVEYARD_HULKS_MIN 4
#define GRAVEYARD_HULKS_MAX 8
/// Сколько уплывает несобранный обломок.
#define GRAVEYARD_DRIFT_TIME (6 SECONDS)

/datum/round_event_control/space_weather/graveyard
	name = "Ship Graveyard"
	typepath = /datum/round_event/space_weather/graveyard
	enabled = TRUE
	weight = 6
	earliest_start = 15 MINUTES
	// Явление больше не обои: за него отвечают выход за борт, лут и точечный пробой.
	// Ступень проставлена руками - от категории SPACE вывелось бы "крупное", а там
	// лимит одновременных держал бы явление насмерть.
	category = EVENT_CATEGORY_SPACE
	severity = DIRECTOR_SEVERITY_MODERATE
	cost = 6
	disruption = DIRECTOR_DISRUPTION_MILD
	description = "The station drifts past a field of derelict hulls. Salvageable wrecks \
		drift within reach, and one or two are on a collision course."

/datum/round_event/space_weather/graveyard
	profile_id = "graveyard"
	token = "event_graveyard"
	phenomenon_name = "Кладбище кораблей"
	peak_layer = /atom/movable/screen/parallax_layer/eris/close/graveyard/peak
	tint_low = "#000000"
	tint_high = "#42382c"
	approach_ticks = 40
	peak_ticks = 80
	departure_ticks = 30
	announce_text = "Станция входит в зону скопления списанных корпусов. Обломки принадлежат кораблям, потерянным в этом секторе за последние сорок лет. Часть из них пройдёт вплотную к обшивке. Отдел Астрономии напоминает, что права на бесхозное имущество в этом секторе не закреплены ни за кем."
	peak_announce_text = "Плотность поля обломков достигла максимума. К корпусу подошли фрагменты, пригодные к разбору. Траектории части объектов не просчитаны."
	announce_end_text = "Станция покинула зону скопления обломков. Не поднятое за борт уходит вместе с полем."
	/// За сколько тиков до удара выходит предупреждение. Расписание ударов обязано
	/// оставлять этот запас внутри пика, иначе о контакте сообщат уже после него.
	var/impact_warning_ticks = 22
	/// Тики от начала пика, на которых прилетают обломки по курсу столкновения.
	var/list/impact_schedule
	/// Сторона, с которой придёт ближайший обломок.
	var/impact_bearing
	/// Выдано ли предупреждение о ближайшем ударе.
	var/impact_warned = FALSE
	/// Уведено ли поле. Уход зовётся из двух мест - из фазы ухода и из уборки, - и оба
	/// пути штатны: админская отмена на пике идёт мимо фазы ухода, а фаза ухода наступает
	/// раньше уборки. Второй проход обязан ничего не делать.
	var/drifted_away = FALSE

/datum/round_event/space_weather/graveyard/on_phase_enter(next_phase, previous_phase)
	switch(next_phase)
		if(PHENOMENON_PHASE_PEAK)
			scatter_hulks()
		if(PHENOMENON_PHASE_DEPARTURE)
			drift_away()
	if(next_phase != PHENOMENON_PHASE_APPROACH)
		return
	// Расписание строится СРАЗУ, а не на пике: сенсор существует ради того, чтобы назвать
	// сектор и время до того, как объект прилетит. Считанное на пике расписание он смог бы
	// показать только тогда, когда готовиться уже поздно.
	schedule_impacts()

/datum/round_event/space_weather/graveyard/apply_intensity(current_intensity)
	if(phase != PHENOMENON_PHASE_PEAK || !length(impact_schedule))
		return
	var/into_peak = activeFor - start_when - approach_ticks
	var/due = impact_schedule[1]

	if(!impact_warned && into_peak >= due - impact_warning_ticks)
		impact_warned = TRUE
		var/seconds_left = round(max(due - into_peak, 0) * SSdirector.wait * 0.1)
		announce_phase("Один из корпусов сошёл с расчётной траектории и идёт на сближение. Расчётное время контакта - [seconds_left] секунд, направление - [bearing_text(impact_bearing)]. Персоналу рекомендуется покинуть внешний контур с этой стороны.")

	if(into_peak < due)
		return
	impact_schedule.Cut(1, 2)
	impact_warned = FALSE
	spawn_meteor(list(/obj/effect/meteor/derelict = 1), impact_bearing)
	impact_bearing = pick(GLOB.cardinals)

/datum/round_event/space_weather/graveyard/cleanup_effects()
	drift_away()

/datum/round_event/space_weather/graveyard/sensor_readout()
	. = list("Спектр: холодный металл, следы органики. Поле состоит из корпусов, не из породы.")
	if(!length(impact_schedule))
		. += (phase == PHENOMENON_PHASE_NONE) ? "Траектории объектов ещё не просчитаны." : "Объектов на курсе столкновения не осталось."
		return
	if(phase != PHENOMENON_PHASE_PEAK)
		. += "Объектов на курсе: [length(impact_schedule)]. Первый контакт через [round(impact_schedule[1] * SSdirector.wait * 0.1)] с после начала пика, направление [bearing_text(impact_bearing)]."
		return
	var/into_peak = activeFor - start_when - approach_ticks
	var/seconds_left = round(max(impact_schedule[1] - into_peak, 0) * SSdirector.wait * 0.1)
	. += "Объект на курсе: контакт через [seconds_left] с, направление [bearing_text(impact_bearing)]."

// ---------------------------------------------------------------------------
// Обломки
// ---------------------------------------------------------------------------

/// Разбрасывает обломки по космосу у корпуса станции. Место ищет каркас: то же самое
/// прикорпусное кольцо нужно и полю микрообломков, и приливной зоне вихря.
/datum/round_event/space_weather/graveyard/proc/scatter_hulks()
	var/list/station_levels = SSmapping.levels_by_trait(ZTRAIT_STATION)
	if(!length(station_levels))
		return
	for(var/attempt in 1 to rand(GRAVEYARD_HULKS_MIN, GRAVEYARD_HULKS_MAX))
		var/turf/spot = find_hull_space_turf(pick(station_levels))
		if(!spot)
			continue
		var/obj/structure/loot_pile/derelict/hulk = new(spot)
		hulk.alpha = 0
		animate(hulk, alpha = 255, time = GRAVEYARD_DRIFT_TIME)
		CHECK_TICK

/**
 * Уводит несобранные обломки вместе с полем.
 *
 * Обломки берутся из глобального списка, а не из своего: игрок вправе разобрать обломок
 * до конца, и тот удалится сам. Хранить на событии ссылки на объекты, которые удаляет
 * кто-то другой, значит держать их за хвост до конца раунда.
 *
 * Ровно один проход за событие: второй перевзвёл бы QDEL_IN на тех же обломках, а
 * отложенный qdel держит обломок жёсткой ссылкой из таймера уже после его удаления.
 */
/datum/round_event/space_weather/graveyard/proc/drift_away()
	if(drifted_away)
		return
	drifted_away = TRUE
	for(var/obj/structure/loot_pile/derelict/hulk as anything in GLOB.derelict_hulks)
		if(QDELETED(hulk))
			continue
		animate(hulk, alpha = 0, time = GRAVEYARD_DRIFT_TIME)
		QDEL_IN(hulk, GRAVEYARD_DRIFT_TIME + 1)

/// Тики, на которых прилетят обломки по курсу. Оба удара внутри пика и с запасом на
/// предупреждение: удар, о котором сообщили после него самого, ничего не решает.
/datum/round_event/space_weather/graveyard/proc/schedule_impacts()
	impact_schedule = list()
	for(var/impact in 1 to rand(1, 2))
		impact_schedule += round(peak_ticks * (0.4 + 0.35 * (impact - 1)))
	impact_bearing = pick(GLOB.cardinals)

/// Сторона света по-русски, для объявлений и сенсора.
/datum/round_event/space_weather/graveyard/proc/bearing_text(bearing)
	switch(bearing)
		if(NORTH)
			return "северный сектор"
		if(SOUTH)
			return "южный сектор"
		if(EAST)
			return "восточный сектор"
		if(WEST)
			return "западный сектор"
	return "сектор не определён"

// ---------------------------------------------------------------------------
// Объекты
// ---------------------------------------------------------------------------

/// Обломки в космосе. Глобальный список вместо списка на событии: обломок удаляет тот,
/// кто разобрал его до конца, и событие не должно об этом знать.
GLOBAL_LIST_EMPTY(derelict_hulks)

/**
 * Фрагмент корпуса с кладбища кораблей.
 *
 * Стоит в вакууме, поэтому голыми руками не разбирается: нужен инструмент, а значит и
 * выход за борт подготовленным. Разбирается до конца и тогда исчезает - обломок, из
 * которого всё вынули, не должен висеть у станции до конца раунда.
 */
/obj/structure/loot_pile/derelict
	name = "обломок корпуса"
	desc = "Фрагмент обшивки корабля, потерянного в этом секторе. Переборки вскрыты \
		перегрузкой, внутренние отсеки доступны. Судя по маркировке, борт списали \
		задолго до того, как он сюда попал."
	icon_states_to_use = list("technical_pile1", "technical_pile2", "technical_pile3")
	density = TRUE
	anchored = TRUE
	max_integrity = 150
	loot_amount = 4
	scavenge_time = 8 SECONDS
	// В вакууме и в перчатках скафандра руками не разберёшь - только инструментом.
	can_use_hands = FALSE
	allowed_tools = list(TOOL_WELDER = 0.5, TOOL_CROWBAR = 0.8, TOOL_WRENCH = 1)
	delete_on_depletion = TRUE
	loot = list(
		/obj/item/stack/sheet/metal/five = 30,
		/obj/item/stack/cable_coil/random = 16,
		/obj/item/stack/sheet/plasteel = 12,
		/obj/item/stock_parts/cell/high = 8,
		/obj/item/stack/sheet/mineral/silver = 6,
		/obj/item/stock_parts/scanning_module/adv = 4,
		/obj/item/stock_parts/capacitor/adv = 4,
		/obj/item/stack/sheet/mineral/gold = 3)

/obj/structure/loot_pile/derelict/Initialize(mapload)
	. = ..()
	GLOB.derelict_hulks += src

/obj/structure/loot_pile/derelict/Destroy()
	GLOB.derelict_hulks -= src
	return ..()

/**
 * Корпус, сошедший с траектории.
 *
 * Тяжелее рядового метеора, но легче большого: пробой должен быть работой для инженерии
 * на несколько минут, а не поводом эвакуировать отсек. Роняет обшивку, а не породу -
 * это корабль, а не камень.
 */
/obj/effect/meteor/derelict
	name = "фрагмент корпуса"
	desc = "Кусок чужой обшивки, идущий прямо на станцию."
	icon_state = "large"
	hits = 5
	heavy = TRUE
	dropamt = 5
	threat = 8
	meteordrop = list(/obj/item/stack/sheet/metal, /obj/item/stack/sheet/plasteel)

/obj/effect/meteor/derelict/meteor_effect()
	..()
	explosion(loc, 0, 1, 3, 4, 0)

#undef GRAVEYARD_HULKS_MIN
#undef GRAVEYARD_HULKS_MAX
#undef GRAVEYARD_DRIFT_TIME
