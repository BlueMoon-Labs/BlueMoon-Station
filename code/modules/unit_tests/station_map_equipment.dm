/// Гравген станции собран из частей, а консоли законов и тренажёры стоят рабочими подтипами, не абстрактной базой.
/datum/unit_test/station_machines_not_abstract
	requires_full_map = TRUE

/datum/unit_test/station_machines_not_abstract/Run()
	for(var/obj/machinery/gravity_generator/main/generator as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/gravity_generator/main))
		if(!is_station_level(generator.z))
			continue
		TEST_ASSERT(generator.connected_parts(), "Гравген без частей на ([generator.x],[generator.y],[generator.z]): [length(generator.parts)] из 8")

	var/list/abstract_found = list()
	for(var/obj/thing in world)
		if(thing.type == /obj/machinery/computer/upload || thing.type == /obj/structure/weightmachine)
			abstract_found += "[thing.type] ([thing.x],[thing.y],[thing.z])"
	TEST_ASSERT(!length(abstract_found), "Абстрактные типы на карте: [abstract_found.Join(", ")]")

/// На Трамстанции есть снаряжение ролей BlueMoon и рабочие машины вместо tg-шных заглушек.
/datum/unit_test/tramstation_bluemoon_equipment
	requires_full_map = TRUE

/datum/unit_test/tramstation_bluemoon_equipment/Run()
	if(SSmapping.config.map_name != "Tramstation")
		return
	var/list/required = list(
		/obj/structure/closet/secure_closet/blueshield = 0,
		/obj/machinery/vending/wardrobe/blueshield_wardrobe = 0,
		/obj/structure/closet/secure_closet/ntr = 0,
		/obj/structure/closet/secure_closet/bridgesec = 0,
		/obj/machinery/vending/wardrobe/bridgeofficer_wardrobe = 0,
		/obj/structure/closet/secure_closet/brigdoc = 0,
		/obj/machinery/vending/brigdoc_vendomat = 0,
		/obj/machinery/vending/wardrobe/cap_wardrobe = 0,
		/obj/structure/closet/secure_closet/hosnew = 0,
		/obj/machinery/computer/upload/ai = 0,
		/obj/machinery/computer/upload/borg = 0,
		/obj/machinery/doppler_array/research/science = 0,
		/obj/machinery/atmospherics/miner/nitrogen = 0,
		/obj/machinery/atmospherics/miner/oxygen = 0,
		/obj/machinery/atmospherics/miner/carbon_dioxide = 0,
		/obj/machinery/atmospherics/miner/toxins = 0,
		/obj/machinery/atmospherics/miner/n2o = 0,
	)
	for(var/obj/thing in world)
		if(!isnull(required[thing.type]) && is_station_level(thing.z))
			required[thing.type]++
	var/list/missing = list()
	for(var/wanted_type in required)
		if(!required[wanted_type])
			missing += "[wanted_type]"
	TEST_ASSERT(!length(missing), "На станции нет: [missing.Join(", ")]")

	var/list/idle_timers = list()
	for(var/obj/machinery/door_timer/timer as anything in GLOB.celltimers_list)
		if(is_station_level(timer.z) && !length(timer.targets))
			idle_timers += "[timer.name] ([timer.x],[timer.y],[timer.z])"
	TEST_ASSERT(!length(idle_timers), "Таймеры камер без дверей: [idle_timers.Join(", ")]")

	for(var/chamber_type in list(/area/engineering/supermatter, /area/science/mixing/chamber, /area/science/mixing/freezer))
		var/has_alarm = FALSE
		for(var/area/chamber as anything in GLOB.all_areas)
			if(chamber.type == chamber_type && length(chamber.airalarms))
				has_alarm = TRUE
				break
		TEST_ASSERT(has_alarm, "У камеры [chamber_type] нет своей алармы")
