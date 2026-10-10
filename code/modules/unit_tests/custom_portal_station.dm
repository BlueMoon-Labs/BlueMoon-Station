/// Портал гостролей на станцию на карте без сферы ghostdojo ведёт в прибытие станции, а без прибытия - туда же, куда латеджойн.
/datum/unit_test/custom_portal_station_without_sphere

/datum/unit_test/custom_portal_station_without_sphere/Run()
	var/obj/effect/custom_portal/Station/portal = allocate(/obj/effect/custom_portal/Station, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/walker = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/list/saved_spheres = SShilbertshotel.all_hilbert_spheres
	SShilbertshotel.all_hilbert_spheres = list()
	portal.Crossed(walker)
	var/turf/groundless
	for(var/attempt in 1 to 50)
		var/turf/destination = portal.find_station_destination()
		if(isgroundlessturf(destination))
			groundless = destination
			break
	SShilbertshotel.all_hilbert_spheres = saved_spheres
	TEST_ASSERT_NULL(groundless, "Портал выбирает клетку без пола: [AREACOORD(groundless)]")

	var/turf/landed = get_turf(walker)
	TEST_ASSERT_NOTEQUAL(landed, run_loc_floor_bottom_left, "Портал без сферы никуда не перенёс")
	for(var/turf/open/entry_turf in get_area_turfs(/area/hallway/secondary/entry))
		if(is_station_level(entry_turf.z) && !isgroundlessturf(entry_turf) && !entry_turf.is_blocked_turf(TRUE))
			TEST_ASSERT(is_station_level(landed.z), "Портал без сферы увёл не на станцию: [AREACOORD(landed)]")
			TEST_ASSERT(istype(get_area(landed), /area/hallway/secondary/entry), "Портал без сферы привёл не в прибытие: [AREACOORD(landed)]")
			return
	if(length(SSjob.latejoin_trackers))
		var/list/latejoin_turfs = list()
		for(var/atom/tracker as anything in SSjob.latejoin_trackers)
			latejoin_turfs += get_turf(tracker)
		TEST_ASSERT(landed in latejoin_turfs, "Портал на карте без прибытия привёл не к точке латеджойна: [AREACOORD(landed)]")
		return
	TEST_ASSERT(istype(get_area(landed), /area/shuttle/arrival), "Портал на карте без прибытия и латеджойна увёл не на шаттл прибытия: [AREACOORD(landed)]")
