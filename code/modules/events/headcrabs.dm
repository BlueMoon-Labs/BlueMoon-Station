#define HEADCRAB_NORMAL 0
#define HEADCRAB_FASTMIX 1
#define HEADCRAB_FAST 2
#define HEADCRAB_POISONMIX 3
#define HEADCRAB_POISON 4
#define HEADCRAB_SPAWNER 5

/datum/round_event_control/headcrabs
	name = "Headcrabs"
	typepath = /datum/round_event/headcrabs
	min_players = 15
	weight = 10
	max_occurrences = 1
	category = EVENT_CATEGORY_ENTITIES
	severity = DIRECTOR_SEVERITY_MODERATE
	description = "Насылает кучу Мозгососов на Космическую Станцию."

/datum/round_event/headcrabs
	announce_when = 2
	end_when = 3
	var/headcrab_type
	/// Что рандомится внутри капсул: типы мобов (или гнёзд), которые из неё высыплются
	var/list/spawn_types = list()
	/// Сколько всего груза раскидано по капсулам
	var/max_number
	/// Сколько капсул Combine приземлится на станцию
	var/number_of_canisters
	/// Сколько гнёзд прорастёт прямо на вентиляции техтоннелей
	var/number_of_nests

/datum/round_event/headcrabs/start()
	headcrab_type = rand(0, 5)
	switch(headcrab_type)
		if(HEADCRAB_NORMAL)
			spawn_types = list(/mob/living/simple_animal/hostile/headcrab)
			max_number = 18
		if(HEADCRAB_FASTMIX)
			spawn_types = list(/mob/living/simple_animal/hostile/headcrab, /mob/living/simple_animal/hostile/headcrab/fast)
			max_number = 16
		if(HEADCRAB_FAST)
			spawn_types = list(/mob/living/simple_animal/hostile/headcrab/fast)
			max_number = 12
		if(HEADCRAB_POISONMIX)
			spawn_types = list(/mob/living/simple_animal/hostile/headcrab, /mob/living/simple_animal/hostile/headcrab/poison)
			max_number = 8
		if(HEADCRAB_POISON)
			spawn_types = list(/mob/living/simple_animal/hostile/headcrab/poison)
			max_number = 6
		if(HEADCRAB_SPAWNER)
			spawn_types = list(/obj/structure/spawner/headcrab)
			max_number = 4

	number_of_canisters = rand(6, 9)
	number_of_nests = rand(2, 4)

	// Оба фаза события идут одновременно: капсулы с рандомным содержимым
	// и гнёзда, прорастающие из вентиляции техтоннелей.
	drop_canisters()
	spawn_vent_nests()

/// Собирает турфы под приземление капсул: вся станция - и техтоннели, и обычные отделы.
/// Космос, стены и турфы, заблокированные плотными объектами, отбрасываются.
/datum/round_event/headcrabs/proc/get_landing_turfs()
	var/list/landing_turfs = list()
	for(var/area/station_area as anything in GLOB.sortedAreas)
		if(!(station_area.type in GLOB.the_station_areas))
			continue
		if(!(station_area.area_flags & VALID_TERRITORY))
			continue
		for(var/turf/landing_turf in station_area)
			if(isspaceturf(landing_turf))
				continue
			if(landing_turf.is_blocked_turf(exclude_mobs = TRUE))
				continue
			landing_turfs += landing_turf
	for(var/turf/xeno_turf in GLOB.xeno_spawn)
		if(isspaceturf(xeno_turf) || xeno_turf.is_blocked_turf(exclude_mobs = TRUE))
			continue
		landing_turfs += xeno_turf
	return landing_turfs

/// Собирает капсулу Combine: не взрывается при приземлении, не улетает и не
/// самоуничтожается после выгрузки - на станции остаётся сама капсула.
/datum/round_event/headcrabs/proc/make_canister()
	var/obj/structure/closet/supplypod/canister = new()
	canister.setStyle(STYLE_CANISTER)
	canister.stay_after_drop = TRUE
	canister.bluespace = FALSE
	canister.explosionSize = list(0, 0, 0, 0)
	return canister

/// Капсулы приземляются по всей станции и высыпают рандомно выбранный груз.
/datum/round_event/headcrabs/proc/drop_canisters()
	var/list/landing_turfs = get_landing_turfs()
	if(!length(landing_turfs))
		return

	var/num = rand(clamp(number_of_canisters, 2, max_number), max_number)
	var/canisters_left = clamp(number_of_canisters, 1, min(length(landing_turfs), num))

	for(var/i in 1 to canisters_left)
		if(num <= 0)
			break
		var/turf/landing_turf = pick_n_take(landing_turfs)
		var/payload = max(1, round(num / (canisters_left - i + 1)))
		num -= payload

		var/obj/structure/closet/supplypod/canister = make_canister()
		for(var/j in 1 to payload)
			var/spawn_type = pick(spawn_types)
			new spawn_type(canister)
		new /obj/effect/pod_landingzone(landing_turf, canister)
		CHECK_TICK

/// Гнёзда хедкрабов прорастают прямо на вентиляции и скрабберах техтоннелей.
/datum/round_event/headcrabs/proc/spawn_vent_nests()
	var/list/vents = list()
	for(var/vent_type in list(/obj/machinery/atmospherics/components/unary/vent_pump, /obj/machinery/atmospherics/components/unary/vent_scrubber))
		for(var/obj/machinery/atmospherics/components/unary/vent as anything in SSmachines.get_machines_by_type_and_subtypes(vent_type))
			if(QDELETED(vent) || vent.welded || !is_station_level(vent.z))
				continue
			if(!istype(get_area(vent), /area/maintenance))
				continue
			vents += vent

	var/num = min(number_of_nests, length(vents))
	for(var/i in 1 to num)
		var/obj/machinery/atmospherics/vent = pick_n_take(vents)
		new /obj/structure/spawner/headcrab(get_turf(vent))
		CHECK_TICK

/datum/round_event/headcrabs/announce()
	if(prob(90))
		priority_announce("Биосканеры фиксируют размножение хедкрабов на борту станции. Избавьтесь от них, прежде чем это начнет влиять на продуктивность станции", "ВНИМАНИЕ: НЕОПОЗНАННЫЕ ФОРМЫ ЖИЗНИ.")
	else
		priority_announce("ХЕДКРАБЫ!!!", "ВНИМАНИЕ: НЕОПОЗНАННЫЕ ФОРМЫ ЖИЗНИ.", sound = 'sound/misc/headcrabs01.wav')

#undef HEADCRAB_NORMAL
#undef HEADCRAB_FASTMIX
#undef HEADCRAB_FAST
#undef HEADCRAB_POISONMIX
#undef HEADCRAB_POISON
#undef HEADCRAB_SPAWNER
