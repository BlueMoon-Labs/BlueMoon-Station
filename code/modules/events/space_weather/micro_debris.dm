/**
 * # Поле микрообломков
 *
 * Взвесь мелких частиц, которая точит станцию снаружи. Ничего катастрофического: трещины
 * в остеклении внешнего контура, осевшая на панелях пыль, изредка микропробой в стене.
 * Но если не чинить - накапливается.
 *
 * Возможность и риск здесь - одно и то же действие. Обломки оседают на корпусе наростами,
 * которые дают материал; выйти за ними во время пика значит собрать больше, но подставить
 * скафандр под ту же взвесь. Кто дождался ухода, выходит безопасно и находит меньше:
 * наросты сдувает вместе с полем.
 */

/// Множитель выработки соларов на полной интенсивности: пыль на панелях.
#define MICRO_DEBRIS_SOLAR_FLOOR 0.35
/// Урона остеклению за одно попадание.
#define MICRO_DEBRIS_WINDOW_DAMAGE 8
/// Доля целостности, ниже которой взвесь окно уже не точит. Объявление обещает износ,
/// а не разгерметизацию: пробитое поле микрообломков окно - это чужое событие.
#define MICRO_DEBRIS_WINDOW_FLOOR 0.3
/// Сколько точек внешнего контура пробуется за тик на полной интенсивности.
#define MICRO_DEBRIS_HITS_AT_PEAK 3
/// Урона скафандру за тик снаружи, на полной интенсивности.
#define MICRO_DEBRIS_SUIT_DAMAGE 3
/// Наростов, которые за пик успевают осесть на корпусе.
#define MICRO_DEBRIS_CRUST_TARGET 14
/// Доля наростов, которую уносит на уходе.
#define MICRO_DEBRIS_CRUST_BLOWOFF 0.5

/datum/round_event_control/space_weather/micro_debris
	name = "Micro Debris Field"
	typepath = /datum/round_event/space_weather/micro_debris
	enabled = TRUE
	weight = 6
	earliest_start = 15 MINUTES
	category = EVENT_CATEGORY_ENGINEERING
	severity = DIRECTOR_SEVERITY_MODERATE
	cost = 6
	disruption = DIRECTOR_DISRUPTION_MILD
	description = "The station passes through micro debris: hull wear, dust on the solars, \
		scrapeable crust outside for whoever is willing to suit up."

/datum/round_event/space_weather/micro_debris
	profile_id = "micro_debris"
	token = "event_micro_debris"
	phenomenon_name = "Поле микрообломков"
	peak_layer = /atom/movable/screen/parallax_layer/eris/close/micro_debris/peak
	tint_low = "#000000"
	tint_high = "#3c3c46"
	approach_ticks = 30
	peak_ticks = 60
	departure_ticks = 25
	announce_text = "Станция входит в поле микрообломков. Отдельная частица безвредна, но плотность потока выше расчётной: ожидается износ внешнего остекления и падение выработки солнечных панелей. Выход за борт на время прохождения не рекомендован."
	peak_announce_text = "Плотность потока достигла максимума. Внешний контур под непрерывным износом. Инженерному отделу рекомендуется осмотреть остекление."
	announce_end_text = "Поле микрообломков пройдено. Осевшее на корпусе вещество постепенно сдувает."
	/// Сколько наростов уже осело за это явление.
	var/crust_placed = 0

/datum/round_event/space_weather/micro_debris/apply_intensity(current_intensity)
	// Осевшая пыль сажает выработку тем сильнее, чем плотнее поток. Это единственное,
	// что идёт с самого начала: панель пылится постепенно, а не рывком на пике.
	GLOB.solar_output_multiplier = 1 - (1 - MICRO_DEBRIS_SOLAR_FLOOR) * current_intensity
	// Всё остальное - только на пике. Подход существует, чтобы к нему подготовиться,
	// и точить обшивку в это же время значило бы отнимать у экипажа само окно подготовки.
	if(phase != PHENOMENON_PHASE_PEAK)
		return
	sand_the_hull(current_intensity)
	abrade_suits(current_intensity)
	accrete_crust(current_intensity)

/datum/round_event/space_weather/micro_debris/on_phase_enter(next_phase, previous_phase)
	if(next_phase != PHENOMENON_PHASE_DEPARTURE)
		return
	// Часть наростов уносит вместе с полем: кто ждал безопасного окна, находит меньше.
	for(var/obj/structure/loot_pile/debris_crust/crust as anything in GLOB.debris_crusts.Copy())
		if(QDELETED(crust) || !prob(MICRO_DEBRIS_CRUST_BLOWOFF * 100))
			continue
		animate(crust, alpha = 0, time = 4 SECONDS)
		QDEL_IN(crust, 4 SECONDS + 1)

/datum/round_event/space_weather/micro_debris/cleanup_effects()
	GLOB.solar_output_multiplier = 1

/datum/round_event/space_weather/micro_debris/sensor_readout()
	. = list("Спектр: силикатная и металлическая пыль, размер частиц ниже порога радара.")
	. += "Прогноз на пик: износ внешнего остекления, выработка панелей падает до [round(MICRO_DEBRIS_SOLAR_FLOOR * 100)]%."
	. += "Скафандр снаружи изнашивается. Осевшее на корпусе вещество пригодно к сбору."
	if(phase == PHENOMENON_PHASE_DEPARTURE)
		. += "Поток спадает. Осевшее вещество начинает сдувать."

// ---------------------------------------------------------------------------
// Воздействие
// ---------------------------------------------------------------------------

/**
 * Точит внешний контур станции.
 *
 * Целится не в список окон - его пришлось бы собирать обходом всей карты, - а в
 * прикорпусные точки космоса. Что окажется по соседству, то и получит: остекление
 * трескается, глухая стена сносит удар молча. Так износ сам собой концентрируется
 * там, где станция обращена к потоку.
 */
/datum/round_event/space_weather/micro_debris/proc/sand_the_hull(current_intensity)
	var/hits = round(MICRO_DEBRIS_HITS_AT_PEAK * current_intensity)
	if(hits <= 0)
		return
	var/list/station_levels = SSmapping.levels_by_trait(ZTRAIT_STATION)
	if(!length(station_levels))
		return
	for(var/hit in 1 to hits)
		var/turf/outside = find_hull_space_turf(pick(station_levels))
		if(!outside)
			continue
		for(var/direction in GLOB.cardinals)
			var/turf/neighbour = get_step(outside, direction)
			if(!neighbour || isspaceturf(neighbour))
				continue
			var/obj/structure/window/glass = locate(/obj/structure/window) in neighbour
			if(!glass)
				continue
			// Треснувшее окно взвесь дальше не точит. Иначе за пик она выбила бы часть
			// внешнего остекления, а это уже разгерметизация - не то, что обещано.
			if(glass.obj_integrity <= glass.max_integrity * MICRO_DEBRIS_WINDOW_FLOOR)
				break
			glass.take_damage(MICRO_DEBRIS_WINDOW_DAMAGE, BRUTE, MELEE, FALSE)
			break
		CHECK_TICK

/**
 * Точит скафандры тех, кто вышел за борт. Именно это делает выбор "идти сейчас или
 * подождать" настоящим: снаружи и больше вещества, и дороже там находиться.
 *
 * Обход идёт по GLOB.player_list, а не по всем живым: риск здесь адресован игроку,
 * принимающему решение, а проход по каждому мобу мира ради фауны в вакууме стоил бы
 * на порядок дороже и никому ничего не сказал бы.
 */
/datum/round_event/space_weather/micro_debris/proc/abrade_suits(current_intensity)
	var/damage = MICRO_DEBRIS_SUIT_DAMAGE * current_intensity
	if(damage <= 0)
		return
	for(var/mob/living/carbon/human/spacewalker in GLOB.player_list)
		var/turf/standing = get_turf(spacewalker)
		if(!standing || !isspaceturf(standing) || !is_station_level(standing.z))
			continue
		var/obj/item/clothing/suit/space/suit = spacewalker.get_item_by_slot(ITEM_SLOT_OCLOTHING)
		if(!istype(suit))
			continue
		suit.take_damage(damage, BRUTE, MELEE, FALSE)
		if(prob(12))
			to_chat(spacewalker, span_warning("Взвесь стучит по скафандру мелкой дробью."))

/// Наращивает на корпусе то, что потом можно соскрести. Темп зависит от интенсивности,
/// поэтому к концу пика снаружи есть что собирать, а на подходе ещё нет.
/datum/round_event/space_weather/micro_debris/proc/accrete_crust(current_intensity)
	if(crust_placed >= MICRO_DEBRIS_CRUST_TARGET || !prob(current_intensity * 60))
		return
	var/list/station_levels = SSmapping.levels_by_trait(ZTRAIT_STATION)
	if(!length(station_levels))
		return
	var/turf/spot = find_hull_space_turf(pick(station_levels))
	if(!spot)
		return
	var/obj/structure/loot_pile/debris_crust/crust = new(spot)
	crust.alpha = 0
	animate(crust, alpha = 255, time = 3 SECONDS)
	crust_placed++

// ---------------------------------------------------------------------------
// Объекты
// ---------------------------------------------------------------------------

/// Наросты на корпусе. Список ведёт сам объект: соскребают их игроки, и событие не
/// должно держать ссылки на то, что удаляет кто-то другой.
GLOBAL_LIST_EMPTY(debris_crusts)

/**
 * Спёкшаяся на обшивке взвесь.
 *
 * Не плотная: по ней ходят, её соскребают. Разбирается любым инструментом и исчезает -
 * пустой нарост на корпусе до конца раунда никому не нужен.
 */
/obj/structure/loot_pile/debris_crust
	name = "нарост на обшивке"
	desc = "Спёкшаяся корка из микрообломков, налипшая на корпус. В ней хватает металла \
		и застывшего газа, чтобы соскабливание окупилось."
	icon_states_to_use = list("junk_pile1", "junk_pile2", "junk_pile3")
	density = FALSE
	anchored = TRUE
	max_integrity = 60
	loot_amount = 2
	scavenge_time = 6 SECONDS
	// В перчатках скафандра корку не отскребёшь - нужен инструмент.
	can_use_hands = FALSE
	allowed_tools = list(TOOL_WELDER = 0.6, TOOL_CROWBAR = 0.7, TOOL_SHOVEL = 0.5, TOOL_WRENCH = 1)
	delete_on_depletion = TRUE
	loot = list(
		/obj/item/stack/ore/iron = 34,
		/obj/item/stack/sheet/metal/five = 22,
		/obj/item/stack/ore/glass = 18,
		/obj/item/stack/ore/plasma = 12,
		/obj/item/stack/ore/silver = 8,
		/obj/item/stack/ore/titanium = 4)

/obj/structure/loot_pile/debris_crust/Initialize(mapload)
	. = ..()
	GLOB.debris_crusts += src

/obj/structure/loot_pile/debris_crust/Destroy()
	GLOB.debris_crusts -= src
	return ..()

#undef MICRO_DEBRIS_SOLAR_FLOOR
#undef MICRO_DEBRIS_WINDOW_DAMAGE
#undef MICRO_DEBRIS_WINDOW_FLOOR
#undef MICRO_DEBRIS_HITS_AT_PEAK
#undef MICRO_DEBRIS_SUIT_DAMAGE
#undef MICRO_DEBRIS_CRUST_TARGET
#undef MICRO_DEBRIS_CRUST_BLOWOFF
