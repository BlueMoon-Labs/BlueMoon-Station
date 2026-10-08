/// Портал гостролей на станцию на карте без сферы ghostdojo ведёт в прибытие станции.
/datum/unit_test/custom_portal_station_without_sphere

/datum/unit_test/custom_portal_station_without_sphere/Run()
	var/obj/effect/custom_portal/Station/portal = allocate(/obj/effect/custom_portal/Station, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/walker = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/list/saved_spheres = SShilbertshotel.all_hilbert_spheres
	SShilbertshotel.all_hilbert_spheres = list()
	portal.Crossed(walker)
	SShilbertshotel.all_hilbert_spheres = saved_spheres

	var/turf/landed = get_turf(walker)
	TEST_ASSERT_NOTEQUAL(landed, run_loc_floor_bottom_left, "Портал без сферы никуда не перенёс")
	TEST_ASSERT(is_station_level(landed.z), "Портал без сферы увёл не на станцию: [AREACOORD(landed)]")
	TEST_ASSERT(istype(get_area(landed), /area/hallway/secondary/entry), "Портал без сферы привёл не в прибытие: [AREACOORD(landed)]")
