/// Минимум горящих ламп, чтобы зона считалась пригодной для зонального мигания
#define AREA_FLICKER_MIN_LIGHTS 6

/// Лампочки на верхушке малой категории (запрос основателя): либо мигают, либо лопают.
/// Тихое амбиентное событие без анонса: волна мигания по станции, изредка вдобавок
/// лопается несколько ламп - мелкая работа уборщику или инженеру.
/datum/round_event_control/faulty_lighting
	name = "Faulty Lighting"
	typepath = /datum/round_event/faulty_lighting
	weight = 90
	max_occurrences = 8
	earliest_start = 0 MINUTES
	alert_observers = FALSE
	repeat_penalty = 0.15 // филлер обязан оставаться наверху пула весь раунд, обычное затухание не для него
	filler = TRUE
	category = EVENT_CATEGORY_ENGINEERING
	severity = DIRECTOR_SEVERITY_MINOR
	family = "lighting" // с зональным миганием ниже: два световых события подряд - перебор
	disruption = DIRECTOR_DISRUPTION_MILD // лопнувшие лампы - уже не чистая косметика
	description = "Station lights flicker across the halls; sometimes a few bulbs burst."

/datum/round_event/faulty_lighting
	fakeable = FALSE
	/// TRUE - вдобавок к миганию лопается несколько ламп
	var/burst_mode = FALSE
	/// Сколько ламп лопнет в burst-режиме
	var/burst_count = 0
	/// Сколько ламп мигнёт. Ограничено числом, а не долей: сотни одновременных flicker()
	/// (каждый с циклом sleep/update) - это шторм для подсистемы света, филлеру такое не к лицу.
	var/flicker_count = 0

/datum/round_event/faulty_lighting/setup()
	burst_mode = prob(35)
	if(burst_mode)
		burst_count = rand(6, 14)
		flicker_count = rand(30, 60)
	else
		flicker_count = rand(60, 120)

/datum/round_event/faulty_lighting/start()
	var/list/obj/machinery/light/candidates = list()
	for(var/obj/machinery/light/fixture in GLOB.machines)
		var/turf/fixture_turf = get_turf(fixture)
		if(!fixture_turf || !is_station_level(fixture_turf.z))
			continue
		// Горящая лампа = целая (LIGHT_OK живёт локальным дефайном lighting.dm, отсюда его не видно);
		// break_light_tube() и flicker() дополнительно гейтят статус сами.
		if(!fixture.on)
			continue
		candidates += fixture
		CHECK_TICK
	if(!length(candidates))
		return kill()
	// Сначала лопаем: break_light_tube() сам даёт звук и искры, а flicker() не трогает не-OK лампы.
	for(var/i in 1 to min(burst_count, length(candidates)))
		var/obj/machinery/light/victim = pick_n_take(candidates)
		victim.break_light_tube()
		CHECK_TICK
	for(var/i in 1 to min(flicker_count, length(candidates)))
		var/obj/machinery/light/twitcher = pick_n_take(candidates)
		twitcher.flicker(rand(2, 6))
		CHECK_TICK

/// Зональная версия (запрос основателя): мигает освещение одного-двух отделов ЦЕЛИКОМ.
/// Ничего не лопается - чистая жуть на пару десятков секунд, поэтому метка ambient.
/datum/round_event_control/faulty_lighting/area_wide
	name = "Faulty Lighting: Area"
	typepath = /datum/round_event/faulty_lighting/area_wide
	weight = 60
	max_occurrences = 6
	description = "All lights of one or two areas flicker at once."
	disruption = DIRECTOR_DISRUPTION_AMBIENT

/datum/round_event/faulty_lighting/area_wide
	/// Сколько зон накрыть миганием
	var/area_count = 1

/datum/round_event/faulty_lighting/area_wide/setup()
	area_count = prob(25) ? 2 : 1

/datum/round_event/faulty_lighting/area_wide/start()
	// Один проход по машинам: лампы раскладываются по зонам, зоны без живого освещения не годятся.
	var/list/lights_by_area = list()
	for(var/obj/machinery/light/fixture in GLOB.machines)
		if(!fixture.on)
			continue
		var/turf/fixture_turf = get_turf(fixture)
		if(!fixture_turf || !is_station_level(fixture_turf.z))
			continue
		var/area/fixture_area = get_area(fixture)
		if(!fixture_area)
			continue
		var/list/bucket = lights_by_area[fixture_area]
		if(!bucket)
			bucket = list()
			lights_by_area[fixture_area] = bucket
		bucket += fixture
		CHECK_TICK
	var/list/area/candidates = list()
	for(var/area/lit_area as anything in lights_by_area)
		if(length(lights_by_area[lit_area]) >= AREA_FLICKER_MIN_LIGHTS)
			candidates += lit_area
	if(!length(candidates))
		return kill()
	for(var/i in 1 to min(area_count, length(candidates)))
		var/area/target = pick_n_take(candidates)
		for(var/obj/machinery/light/fixture as anything in lights_by_area[target])
			fixture.flicker(rand(6, 12))
			CHECK_TICK

#undef AREA_FLICKER_MIN_LIGHTS
