/// Сколько отрезков кабеля перегрызается за событие
#define WIRE_FEAST_MIN_BITES 4
#define WIRE_FEAST_MAX_BITES 8
/// Шанс оставить возле обрыва виновника-мышь
#define WIRE_FEAST_MOUSE_PROB 35

/// Пир грызунов (идея goonstation): в техтоннелях кто-то перегрыз кабели, возле части
/// обрывов сидят сытые виновники. Никаких анонсов - экипаж сам замечает обесточенные
/// закоулки и идёт по мейнтам искать разрывы. Обрыв оставляет обрезок кабеля на полу,
/// так что след "погрыза" читается глазами.
/datum/round_event_control/wire_feast
	name = "Wire Feast"
	typepath = /datum/round_event/wire_feast
	weight = 25
	max_occurrences = 3
	earliest_start = 15 MINUTES
	alert_observers = FALSE
	category = EVENT_CATEGORY_ENGINEERING
	// Категория ENGINEERING по умолчанию даёт MODERATE; горстка обрывов в мейнте - мелочь
	severity = DIRECTOR_SEVERITY_MINOR
	family = "petty_power" // с APC Scramble: две тихие электро-неприятности подряд - перебор
	description = "Cables in maintenance get chewed through; culprit mice linger nearby."

/datum/round_event/wire_feast
	fakeable = FALSE
	/// Сколько отрезков перегрызть в этот раз
	var/bite_count = 0

/datum/round_event/wire_feast/setup()
	bite_count = rand(WIRE_FEAST_MIN_BITES, WIRE_FEAST_MAX_BITES)

/datum/round_event/wire_feast/start()
	var/list/obj/structure/cable/candidates = list()
	for(var/obj/structure/cable/wire as anything in GLOB.cable_list)
		var/turf/wire_turf = get_turf(wire)
		if(!wire_turf || !is_station_level(wire_turf.z))
			continue
		if(!istype(get_area(wire), /area/maintenance))
			continue
		// Под плиткой кабель никто не грыз - нужны только открытые
		var/turf/open/floor/floor = wire_turf
		if(istype(floor) && floor.intact)
			continue
		candidates += wire
		CHECK_TICK
	if(!length(candidates))
		return kill()
	for(var/i in 1 to min(bite_count, length(candidates)))
		var/obj/structure/cable/victim = pick_n_take(candidates)
		if(QDELETED(victim)) // сосед по турфу мог уйти вместе с уже перегрызенным куском
			continue
		var/turf/victim_turf = get_turf(victim)
		if(victim.avail())
			do_sparks(2, TRUE, victim_turf)
		victim.deconstruct()
		if(prob(WIRE_FEAST_MOUSE_PROB))
			new /mob/living/simple_animal/mouse(victim_turf)
		CHECK_TICK

#undef WIRE_FEAST_MIN_BITES
#undef WIRE_FEAST_MAX_BITES
#undef WIRE_FEAST_MOUSE_PROB
