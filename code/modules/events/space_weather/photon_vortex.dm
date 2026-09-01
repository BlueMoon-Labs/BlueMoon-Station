/**
 * # Фотонный вихрь
 *
 * Коллапсировавший объект проходит достаточно близко, чтобы станцию было чем тянуть.
 * Единственное тяжёлое явление ветки и самое ценное научное окно раунда.
 *
 * На пике станцию рвут приливные волны: пол уходит из-под ног, незакреплённое летит,
 * гравитационный генератор изредка не выдерживает нагрузки. Внешний контур простреливает
 * излучением аккреционного диска, и выход за борт становится по-настоящему опасен -
 * ровно там, где на корпусе оседает сжатая материя, которой больше взять неоткуда.
 *
 * Полная невесомость станции сюда НЕ заводится сознательно. Гравитация на z считается
 * кэшем SSmapping, который пересчитывается от генераторов, и временная подмена этого кэша
 * жила бы до первого чужого пересчёта. Приливная встряска даёт ту же картину - станцию
 * швыряет - через существующие и проверенные throw_at/Knockdown, а тяжёлый исход берёт
 * на себя штатный blackout() генератора, который инженерия умеет чинить.
 */

/// Шанс приливной волны за тик на полной интенсивности, в процентах. При тике директора
/// в две секунды это волна примерно раз в шестнадцать секунд на пике - достаточно, чтобы
/// станцию мотало, и не настолько, чтобы игрок весь пик пролежал на полу.
#define VORTEX_WAVE_CHANCE 12
/// Длительность тряски камеры на волне.
#define VORTEX_SHAKE_DURATION 12
/// Шанс сбить с ног на волне, в процентах от интенсивности.
#define VORTEX_KNOCKDOWN_CHANCE 40
/// Шанс за волну, что нагрузки не выдержит гравитационный генератор, в процентах.
/// Единица, а не больше: волн за пик около десятка, и уже при семи процентах генератор
/// срывало бы в четырёх раундах из пяти. Срыв обязан остаться редким событием, о котором
/// вспоминают, а не обязательной частью явления.
#define VORTEX_GENERATOR_TRIP_CHANCE 1
/// Шанс всплеска излучения за тик на полной интенсивности, в процентах.
#define VORTEX_RADIATION_CHANCE 40
/// Сила импульса излучения по внешнему контуру.
#define VORTEX_RADIATION_POWER 180
/// Сколько залежей сжатой материи вихрь наносит на корпус за пик.
#define VORTEX_MATTER_TARGET 8

/datum/round_event_control/space_weather/photon_vortex
	name = "Photon Vortex"
	typepath = /datum/round_event/space_weather/photon_vortex
	enabled = TRUE
	weight = 3
	earliest_start = 30 MINUTES
	category = EVENT_CATEGORY_SPACE
	// Единственное тяжёлое явление ветки: трясёт всю станцию, роняет гравитацию и
	// простреливает внешний контур излучением.
	severity = DIRECTOR_SEVERITY_MAJOR
	cost = 20
	disruption = DIRECTOR_DISRUPTION_DISRUPTIVE
	description = "A collapsed object drags the station through tidal waves and hard \
		radiation, and leaves compressed matter on the hull for anyone brave enough."

/datum/round_event/space_weather/photon_vortex
	profile_id = "photon_vortex"
	token = "event_photon_vortex"
	phenomenon_name = "Фотонный вихрь"
	peak_layer = /atom/movable/screen/parallax_layer/eris/close/micro_debris/vortex_peak
	tint_low = "#000000"
	tint_high = "#2e1046"
	// Самое ценное научное явление раунда: сближение редкое, а пик на нём смертельно
	// опасен. Выдача обязана окупать риск, иначе к вихрю никто не пойдёт.
	sensor_yield_mult = 2.5
	approach_ticks = 45
	peak_ticks = 80
	departure_ticks = 35
	announce_source = "Отдел Астрономии NanoTrasen"
	announce_text = "В зоне видимости станции коллапсировавший объект. Прогнозируются приливные колебания гравитации и всплески жёсткого излучения по внешнему контуру. Выход за борт на время сближения запрещён. Отдел Астрономии напоминает, что следующее такое сближение произойдёт нескоро, и рекомендует снять показания."
	peak_announce_text = "Сближение максимально. Приливные волны идут по всей станции, внешний контур под излучением. Магнитные ботинки настоятельно рекомендованы."
	announce_end_text = "Коллапсировавший объект вышел из зоны видимости. Приливные колебания прекратились."
	/// Сколько залежей сжатой материи уже осело.
	var/matter_placed = 0
	/// Срывался ли уже генератор. Второй срыв за явление - это уже не памятный момент,
	/// а издевательство над теми, кто только что дошёл до рубильника.
	var/generator_tripped = FALSE

/datum/round_event/space_weather/photon_vortex/apply_intensity(current_intensity)
	// На подходе вихрь только даёт о себе знать: пол подрагивает, но с ног не сбивает.
	// Настоящие волны, излучение и залежи приходят с пиком - подход нужен, чтобы успеть
	// достать магнитные ботинки и увести людей с внешнего контура.
	if(phase != PHENOMENON_PHASE_PEAK)
		if(prob(current_intensity * VORTEX_WAVE_CHANCE))
			tremor()
		return
	if(prob(current_intensity * VORTEX_WAVE_CHANCE))
		tidal_wave(current_intensity)
	irradiate_hull(current_intensity)
	accrete_matter(current_intensity)

/// Предвестник: станцию ощутимо ведёт, но ничего не роняет.
/datum/round_event/space_weather/photon_vortex/proc/tremor()
	for(var/mob/living/victim in GLOB.player_list)
		if(QDELETED(victim) || !victim.client || !is_station_level(victim.z))
			continue
		shake_camera(victim, VORTEX_SHAKE_DURATION * 0.5, 1)

/datum/round_event/space_weather/photon_vortex/sensor_readout()
	. = list("Спектр: гравитационный градиент растёт нелинейно, жёсткая составляющая нарастает.")
	. += "Прогноз на пик: приливные волны по всей станции, излучение по внешнему контуру."
	. += "Нагрузка на генератор гравитации выше расчётной. Выход за борт смертельно опасен."
	. += "Показания вихря ценнее всех прочих явлений вместе взятых."

/**
 * Приливная волна: станцию тянет в сторону, пол уходит из-под ног.
 *
 * Магнитные ботинки держат: у волны есть противодействие, и оно то самое, которое экипаж
 * может подготовить заранее по объявлению. Без этого волна была бы просто налогом.
 */
/datum/round_event/space_weather/photon_vortex/proc/tidal_wave(current_intensity)
	var/direction = pick(GLOB.cardinals)
	for(var/mob/living/victim in GLOB.player_list)
		if(QDELETED(victim) || !is_station_level(victim.z))
			continue
		if(victim.client)
			shake_camera(victim, VORTEX_SHAKE_DURATION, 2)
		if(victim.buckled || victim.anchored || HAS_TRAIT(victim, TRAIT_NOSLIPALL))
			continue
		var/turf/thrown_to = get_step(victim, direction)
		if(thrown_to && !thrown_to.density)
			victim.throw_at(thrown_to, 1, 2, spin = FALSE)
		if(prob(current_intensity * VORTEX_KNOCKDOWN_CHANCE))
			victim.Knockdown(2 SECONDS)
			to_chat(victim, span_warning("Пол уходит из-под ног - станцию тянет вбок."))

	if(!generator_tripped && prob(VORTEX_GENERATOR_TRIP_CHANCE))
		trip_gravity_generator()

/**
 * Нагрузка сбивает станционный генератор гравитации.
 *
 * Зовётся штатный blackout(): его инженерия уже умеет чинить рубильником, а событие не
 * заводит себе ни своего состояния, ни своего способа вернуть гравитацию обратно.
 */
/datum/round_event/space_weather/photon_vortex/proc/trip_gravity_generator()
	var/list/obj/machinery/gravity_generator/main/victims = list()
	for(var/z_key in GLOB.gravity_generators)
		for(var/obj/machinery/gravity_generator/main/generator in GLOB.gravity_generators[z_key])
			if(is_station_level(generator.z))
				victims += generator
	if(!length(victims))
		return
	generator_tripped = TRUE
	for(var/obj/machinery/gravity_generator/main/generator as anything in victims)
		if(!QDELETED(generator))
			generator.blackout()

/// Всплеск излучения с аккреционного диска по внешнему контуру. Внутри станции его
/// глушит обшивка - опасен он ровно там, где лежит сжатая материя.
/datum/round_event/space_weather/photon_vortex/proc/irradiate_hull(current_intensity)
	if(!prob(current_intensity * VORTEX_RADIATION_CHANCE))
		return
	var/list/station_levels = SSmapping.levels_by_trait(ZTRAIT_STATION)
	if(!length(station_levels))
		return
	var/turf/outside = find_hull_space_turf(pick(station_levels))
	if(!outside)
		return
	radiation_pulse(outside, VORTEX_RADIATION_POWER * current_intensity)

/// Наносит на корпус сжатую материю. Собирать её надо в излучении и под волнами -
/// в этом и состоит цена самого богатого материала явления.
/datum/round_event/space_weather/photon_vortex/proc/accrete_matter(current_intensity)
	if(matter_placed >= VORTEX_MATTER_TARGET || !prob(current_intensity * 35))
		return
	var/list/station_levels = SSmapping.levels_by_trait(ZTRAIT_STATION)
	if(!length(station_levels))
		return
	var/turf/spot = find_hull_space_turf(pick(station_levels))
	if(!spot)
		return
	var/obj/structure/loot_pile/compressed_matter/deposit = new(spot)
	deposit.alpha = 0
	animate(deposit, alpha = 255, time = 3 SECONDS)
	matter_placed++

/**
 * Сжатая приливными силами материя.
 *
 * Богаче любого другого залежа явлений и лежит там, где по внешнему контуру бьёт
 * излучение. Это и есть плата: материал доступен только тому, кто вышел наружу в пик.
 */
/obj/structure/loot_pile/compressed_matter
	name = "залежь сжатой материи"
	desc = "Вещество, спрессованное приливными силами до состояния, в котором его \
		обычно не встречают. Счётчик рядом с ним щёлкает без остановки."
	icon_states_to_use = list("alien_pile1", "alien_pile2")
	density = FALSE
	anchored = TRUE
	max_integrity = 80
	loot_amount = 3
	scavenge_time = 9 SECONDS
	can_use_hands = FALSE
	allowed_tools = list(TOOL_WELDER = 0.6, TOOL_CROWBAR = 0.8, TOOL_SHOVEL = 0.5)
	delete_on_depletion = TRUE
	loot = list(
		/obj/item/stack/sheet/mineral/plasma = 24,
		/obj/item/stack/sheet/mineral/silver = 20,
		/obj/item/stack/sheet/mineral/gold = 16,
		/obj/item/stack/sheet/mineral/titanium = 14,
		/obj/item/stack/sheet/mineral/uranium = 12,
		/obj/item/stack/sheet/mineral/diamond = 8,
		/obj/item/stack/ore/bluespace_crystal = 6)

#undef VORTEX_WAVE_CHANCE
#undef VORTEX_SHAKE_DURATION
#undef VORTEX_KNOCKDOWN_CHANCE
#undef VORTEX_GENERATOR_TRIP_CHANCE
#undef VORTEX_RADIATION_CHANCE
#undef VORTEX_RADIATION_POWER
#undef VORTEX_MATTER_TARGET
