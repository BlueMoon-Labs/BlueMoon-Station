/// Точка похмелья не держит свой мусор жёсткой ссылкой: персистенс удаляет его до старта раунда, пока точка жива.
/datum/unit_test/hangover_debris_not_held

/datum/unit_test/hangover_debris_not_held/Run()
	ADD_TRAIT(SSstation, STATION_TRAIT_HANGOVER, "unit_test")
	var/obj/effect/landmark/start/hangover/spot = allocate(/obj/effect/landmark/start/hangover, run_loc_floor_bottom_left)
	for(var/attempt in 1 to 20)
		if(length(spot.debris))
			break
		spot.LateInitialize()
	REMOVE_TRAIT(SSstation, STATION_TRAIT_HANGOVER, "unit_test")
	TEST_ASSERT(length(spot.debris), "Точка похмелья за 20 попыток ничего не разложила")

	for(var/entry in spot.debris)
		TEST_ASSERT(istype(entry, /datum/weakref), "Точка похмелья держит [entry] жёсткой ссылкой: удалённый мусор станет хардделом")
		var/datum/weakref/debris_ref = entry
		qdel(debris_ref.resolve())
