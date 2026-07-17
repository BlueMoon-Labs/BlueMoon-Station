#define CONDENSATION_MIN_FLOORS 8

/// Конденсат на палубе (порт идеи goonstation "Slippery Floors"): сбой терморегуляции,
/// в нескольких отсеках на полу выпадает конденсат - пару минут там скользко, потом
/// само высыхает. Массовые падения, работа уборщику и повод не бегать по коридорам.
/// Мокрота вешается штатным wet_floor-компонентом, никакой новой механики.
/datum/round_event_control/slippery_floors
	name = "Deck Condensation"
	typepath = /datum/round_event/slippery_floors
	weight = 25
	max_occurrences = 2
	earliest_start = 15 MINUTES
	min_players = 5
	alert_observers = FALSE
	category = EVENT_CATEGORY_JANITORIAL
	disruption = DIRECTOR_DISRUPTION_MILD
	description = "Thermal regulation glitch: floors of several areas become wet and slippery for a few minutes."

/datum/round_event/slippery_floors
	announce_when = 1
	start_when = 6
	/// Сколько отсеков накрыть конденсатом
	var/area_count = 2

/datum/round_event/slippery_floors/setup()
	area_count = rand(2, 4)

/datum/round_event/slippery_floors/announce(fake)
	priority_announce("Зафиксирован сбой системы терморегуляции: в ряде отсеков возможно выпадение конденсата. Будьте осторожны - покрытие палубы может оказаться скользким до полного высыхания.",
		"Служба технического контроля NanoTrasen",
		sound = 'sound/misc/notice2.ogg')

/datum/round_event/slippery_floors/start()
	// Тянем зоны из GLOB.the_station_areas (только станционные типы, без космоса
	// и планетарных простыней), мелкие технические закутки пропускаем.
	var/list/candidates = GLOB.the_station_areas.Copy()
	var/applied = 0
	while(applied < area_count && length(candidates))
		var/picked_type = pick_n_take(candidates)
		var/list/floors = list()
		for(var/turf/open/floor/deck in get_area_turfs(picked_type))
			if(is_station_level(deck.z))
				floors += deck
			CHECK_TICK
		if(length(floors) < CONDENSATION_MIN_FLOORS)
			continue
		for(var/turf/open/floor/deck as anything in floors)
			deck.MakeSlippery(TURF_WET_WATER, 1 MINUTES, rand(1 MINUTES, 2 MINUTES))
			CHECK_TICK
		applied++

	if(!applied)
		return kill()

#undef CONDENSATION_MIN_FLOORS
