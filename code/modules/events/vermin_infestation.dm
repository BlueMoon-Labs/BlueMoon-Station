/// Сколько вредителей расплодится
#define VERMIN_INFESTATION_MIN 6
#define VERMIN_INFESTATION_MAX 10
/// Минимум свободных тайлов, чтобы отсек считался пригодным для заражения
#define VERMIN_INFESTATION_MIN_TURFS 5

/// Заражение вредителями (порт с Paradise): в одном именованном отсеке разом плодятся
/// мыши или тараканы, биосканер называет отсек в анонсе. Отличие от Mice Migration:
/// не безадресная волна по мейнтам, а точечная санитарная задача - уборщик знает,
/// куда идти с мухобойкой.
/datum/round_event_control/vermin_infestation
	name = "Vermin Infestation"
	typepath = /datum/round_event/vermin_infestation
	weight = 40
	max_occurrences = 3
	earliest_start = 10 MINUTES
	min_players = 5
	category = EVENT_CATEGORY_JANITORIAL
	family = "vermin" // с Mice Migration: два грызунных события подряд - перебор
	description = "Mice or cockroaches breed all over one named department room."

/datum/round_event/vermin_infestation
	fakeable = FALSE
	/// Сколько вредителей вывелось
	var/vermin_count = 0
	/// Тип вредителя на этот раз
	var/vermin_type = /mob/living/simple_animal/mouse
	/// Имя заражённого отсека для анонса
	var/target_area_name
	/// Отсеки, где водятся вредители: обжитые "мягкие" зоны с едой и укромными углами
	var/static/list/candidate_area_types = list(
		/area/service/kitchen,
		/area/service/bar,
		/area/service/hydroponics,
		/area/service/library,
		/area/service/chapel/main,
		/area/service/theater,
		/area/commons/dorms,
		/area/commons/locker,
		/area/commons/fitness,
		/area/commons/vacant_room,
		/area/cargo/warehouse,
	)

/datum/round_event/vermin_infestation/setup()
	vermin_count = rand(VERMIN_INFESTATION_MIN, VERMIN_INFESTATION_MAX)
	vermin_type = prob(60) ? /mob/living/simple_animal/mouse : /mob/living/simple_animal/cockroach

/datum/round_event/vermin_infestation/announce(fake)
	if(!target_area_name)
		return
	priority_announce("Дальний биосканер фиксирует бурное размножение мелких форм жизни в отсеке: [target_area_name]. Санитарной службе рекомендуется провести обработку.", "Санитарный Контроль Нанотрейзен")

/datum/round_event/vermin_infestation/start()
	var/list/area/candidates = list()
	for(var/area/dept in GLOB.sortedAreas)
		if(is_type_in_list(dept, candidate_area_types))
			candidates += dept
	while(length(candidates))
		var/area/target = pick_n_take(candidates)
		var/list/turf/open/nest_turfs = list()
		for(var/turf/open/nest in target)
			if(!is_station_level(nest.z))
				continue
			if(is_blocked_turf(nest, TRUE))
				continue
			nest_turfs += nest
			CHECK_TICK
		if(length(nest_turfs) < VERMIN_INFESTATION_MIN_TURFS)
			continue
		target_area_name = target.name
		var/mob/first_spawned
		for(var/i in 1 to vermin_count)
			var/mob/vermin = new vermin_type(pick(nest_turfs))
			if(!first_spawned)
				first_spawned = vermin
			CHECK_TICK
		announce_to_ghosts(first_spawned)
		return
	kill()

#undef VERMIN_INFESTATION_MIN
#undef VERMIN_INFESTATION_MAX
#undef VERMIN_INFESTATION_MIN_TURFS
