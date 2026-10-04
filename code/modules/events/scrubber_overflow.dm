/datum/round_event_control/scrubber_overflow
	name = "Scrubber Overflow: Normal"
	typepath = /datum/round_event/scrubber_overflow
	// Вес 75 (при типичных 25-50 у соседей по MINOR) плюс наследование его всеми подтипами давали
	// семейству труб ~28% каждого minor-ролла: по 3-5 переливов за раунд. Семейство "scrubbers"
	// делит фолл-офф повторов и паузу, метка disruptive глушит переливы в мягких профилях.
	weight = 20
	max_occurrences = 2
	min_players = 10
	category = EVENT_CATEGORY_JANITORIAL
	family = "scrubbers"
	disruption = DIRECTOR_DISRUPTION_DISRUPTIVE
	description = "The scrubbers release a tide of mostly harmless froth."
	admin_setup = list(/datum/event_admin_setup/listed_options/scrubber_overflow)

/datum/round_event/scrubber_overflow
	announce_when = 1
	start_when = 5
	/// The probability that the ejected reagents will be dangerous
	var/danger_chance = 1
	/// Amount of reagents ejected from each scrubber
	var/reagents_amount = 100
	/// Probability of an individual scrubber overflowing.
	/// 100, а не меньше: вентиляция разложена по всей станции, и волна накрывает её целиком только
	/// когда бьёт каждый экземпляр (и скруббер, и помпа), а не когда бьёт каждый второй.
	var/overflow_probability = 100
	/// Specific reagent to force all scrubbers to use, null for random reagent choice
	var/datum/reagent/forced_reagent_type
	/// A list of scrubbers and vents that will have reagents ejected from them
	var/list/scrubbers = list()
	/// The list of chems that scrubbers can produce
	var/list/safer_chems = list(/datum/reagent/water,
		/datum/reagent/carbon,
		/datum/reagent/space_cleaner,
		/datum/reagent/carpet,
		/datum/reagent/carpet/black,
		/datum/reagent/carpet/orange,
		/datum/reagent/carpet/blackred,
		/datum/reagent/carpet/royalblack,
		/datum/reagent/lube,
		/datum/reagent/glitter/blue,
		/datum/reagent/glitter/pink,
		/datum/reagent/glitter/white,
		/datum/reagent/cryptobiolin,
		/datum/reagent/blood,
		/datum/reagent/medicine/charcoal,
		/datum/reagent/water/holywater,
		/datum/reagent/consumable/ethanol,
		/datum/reagent/consumable/hot_coco,
		/datum/reagent/consumable/yoghurt,
		/datum/reagent/consumable/tinlux,
		/datum/reagent/bluespace,
		/datum/reagent/pax,
		/datum/reagent/consumable/laughter,
		/datum/reagent/concentrated_barbers_aid,
		/datum/reagent/baldium,
		/datum/reagent/colorful_reagent,
		/datum/reagent/consumable/ethanol/beer,
		/datum/reagent/hair_dye,
		/datum/reagent/gravitum,
		/datum/reagent/growthserum,
		/datum/reagent/consumable/sugar,
		/datum/reagent/consumable/flour,
		/datum/reagent/consumable/sodiumchloride,
		/datum/reagent/consumable/cornoil,
		/datum/reagent/consumable/nutriment,
		/datum/reagent/consumable/condensedcapsaicin,
		/datum/reagent/drug/mushroomhallucinogen,
		/datum/reagent/toxin/plantbgone,
		/datum/reagent/drug/space_drugs,
		/datum/reagent/medicine/morphine,
		/datum/reagent/toxin/mindbreaker,
		/datum/reagent/toxin/rotatium,
		/datum/reagent/peaceborg_confuse,
		/datum/reagent/peaceborg_tire,
		/datum/reagent/firefighting_foam,
		/datum/reagent/consumable/tearjuice,
		/datum/reagent/medicine/strange_reagent
	)
	//needs to be chemid unit checked at some point

/// Вентиляция, из которой может пойти жидкость: и скрубберы, и помпы - они соседние ветки от vent,
/// поэтому в переборе нужны оба типа.
#define OVERFLOW_VENT_TYPES list(\
	/obj/machinery/atmospherics/components/unary/vent_scrubber, \
	/obj/machinery/atmospherics/components/unary/vent_pump \
)

/// Вся незваренная вентиляция станции - кандидаты на источники для перелива.
/// Список берётся из индекса SSmachines по типу, а не обходом GLOB.machines: тот на каждый ивент
/// дважды перебирает всю технику на карте, ради пары сотен вентилей.
/// Отдаёт новый список - вызывающий вправе чистить и фильтровать его на месте.
/proc/get_overflow_station_vents()
	var/list/station_vents = list()
	for(var/vent_type in OVERFLOW_VENT_TYPES)
		for(var/obj/machinery/atmospherics/components/unary/vent as anything in SSmachines.get_machines_by_type_and_subtypes(vent_type))
			// Не вварилась в нуль (loc == null) машина тоже сюда не попадёт: z у неё 0, не станция.
			if(vent.welded || !is_station_level(vent.z))
				continue
			station_vents += vent
	return station_vents

/datum/round_event/scrubber_overflow/announce(fake)
	priority_announce("Сеть вентиляции испытывает скачок противодавления. Может произойти некоторый выброс содержимого.", "ВНИМАНИЕ: АТМОСФЕРА", 'sound/announcer/classic/ventclog.ogg')

/datum/round_event/scrubber_overflow/setup()
	for(var/obj/machinery/atmospherics/components/unary/vent as anything in get_overflow_station_vents())
		if(!prob(overflow_probability))
			continue
		scrubbers += vent

	if(!scrubbers.len)
		return kill()

/datum/round_event_control/scrubber_overflow/can_fire(datum/director_signals/signals)
	. = ..()
	if(!.)
		return
	return length(get_overflow_station_vents()) > 0

/// proc that will run the prob check of the event and return a safe or dangerous reagent based off of that.
/datum/round_event/scrubber_overflow/proc/get_overflowing_reagent(dangerous)
	return dangerous ? get_random_reagent_id() : pick(safer_chems)

/datum/round_event/scrubber_overflow/start()
	for(var/obj/machinery/atmospherics/components/unary/vent as anything in scrubbers)
		// Между setup() и start() проходит несколько тиков - за это время вент
		// могли снести (взрыв, фауна). CRASH здесь обрывал весь цикл на первом
		// же снесённом венте и глушил событие целиком (раунд 9915).
		if(QDELETED(vent) || !vent.loc)
			continue

		var/datum/reagents/dispensed_reagent = new /datum/reagents(reagents_amount)
		dispensed_reagent.my_atom = vent
		if (forced_reagent_type)
			dispensed_reagent.add_reagent(forced_reagent_type, reagents_amount)
		else if (prob(danger_chance))
			dispensed_reagent.add_reagent(get_overflowing_reagent(dangerous = TRUE), reagents_amount)
			new /mob/living/simple_animal/cockroach(get_turf(vent))
			new /mob/living/simple_animal/cockroach(get_turf(vent))
		else
			dispensed_reagent.add_reagent(get_overflowing_reagent(dangerous = FALSE), reagents_amount)

		dispensed_reagent.create_foam(/datum/effect_system/foam_spread/short, reagents_amount)

		CHECK_TICK

/datum/round_event_control/scrubber_overflow/threatening
	name = "Scrubber Overflow: Threatening"
	typepath = /datum/round_event/scrubber_overflow/threatening
	// Свой typepath - уже выбранная жидкость, спрашивать тип заново нечего.
	admin_setup = list()
	weight = 4
	min_players = 25
	max_occurrences = 1
	earliest_start = 35 MINUTES
	severity = DIRECTOR_SEVERITY_MODERATE
	description = "The scrubbers release a tide of moderately harmless froth."

/datum/round_event/scrubber_overflow/threatening
	danger_chance = 10
	reagents_amount = 100

/datum/round_event_control/scrubber_overflow/catastrophic
	name = "Scrubber Overflow: Catastrophic"
	typepath = /datum/round_event/scrubber_overflow/catastrophic
	admin_setup = list()
	weight = 2
	min_players = 35
	max_occurrences = 1
	earliest_start = 45 MINUTES
	severity = DIRECTOR_SEVERITY_MODERATE
	description = "The scrubbers release a tide of mildly harmless froth."

/datum/round_event/scrubber_overflow/catastrophic
	danger_chance = 30
	reagents_amount = 150

/datum/round_event_control/scrubber_overflow/every_vent
	name = "Scrubber Overflow: Every Vent"
	typepath = /datum/round_event/scrubber_overflow/every_vent
	admin_setup = list()
	admin_only = TRUE
	max_occurrences = 0
	description = "The scrubbers release a tide of mostly harmless froth, but twice as deep as usual."

/datum/round_event/scrubber_overflow/every_vent
	// overflow_probability уже 100 у базового ивента, отличается только объёмом.
	reagents_amount = 200

/datum/event_admin_setup/listed_options/scrubber_overflow
	normal_run_option = "Random Reagents"
	special_run_option = "Random Single Reagent"

/datum/event_admin_setup/listed_options/scrubber_overflow/get_list()
	return sort_list(subtypesof(/datum/reagent), /proc/cmp_typepaths_asc)

/datum/event_admin_setup/listed_options/scrubber_overflow/apply_to_event(datum/round_event/scrubber_overflow/event)
	if(chosen == special_run_option)
		chosen = event.get_overflowing_reagent(dangerous = prob(event.danger_chance))
	event.forced_reagent_type = chosen
