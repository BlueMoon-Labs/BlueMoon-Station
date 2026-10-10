/// Пыль, врезавшаяся в скалу станции, тратит удар; камень руин её по-прежнему пропускает.
/datum/unit_test/meteor_spent_on_station_rock

/datum/unit_test/meteor_spent_on_station_rock/Run()
	var/turf/open/origin = run_loc_floor_bottom_left
	var/turf/station_rock = locate(origin.x + 1, origin.y, origin.z)
	var/turf/ruin_rock = locate(origin.x + 1, origin.y + 2, origin.z)
	// Пробитая скала обязана стать полом астероида, как на картах: иначе исход зависел бы от броска на пробитие.
	station_rock = station_rock.ChangeTurf(/turf/closed/mineral/random/stationside/asteroid/porus, /turf/open/floor/plating/asteroid)
	ruin_rock = ruin_rock.ChangeTurf(/turf/closed/mineral, /turf/open/floor/plating/asteroid/airless)
	var/obj/effect/meteor/dust/station_dust = allocate(/obj/effect/meteor/dust, origin)
	var/obj/effect/meteor/dust/ruin_dust = allocate(/obj/effect/meteor/dust, locate(origin.x, origin.y + 2, origin.z))

	station_dust.Bump(station_rock)
	ruin_dust.Bump(ruin_rock)

	TEST_ASSERT(QDELETED(station_dust), "Пыль прошла насквозь через скалу, в которую врезана станция")
	TEST_ASSERT(!QDELETED(ruin_dust), "Камень руин стал останавливать метеоры")

/// В скале станции нет гибтонита.
/datum/unit_test/stationside_rock_has_no_gibtonite

/datum/unit_test/stationside_rock_has_no_gibtonite/Run()
	var/turf/spot = locate(run_loc_floor_bottom_left.x + 1, run_loc_floor_bottom_left.y + 1, run_loc_floor_bottom_left.z)
	for(var/rock_type in typesof(/turf/closed/mineral/random/stationside))
		var/turf/closed/mineral/random/rock = spot.ChangeTurf(rock_type, /turf/open/floor/plating/asteroid)
		TEST_ASSERT(istype(rock, /turf/closed/mineral/random), "[rock_type] при появлении превратился в [rock.type]")
		for(var/spawn_type in rock.mineralSpawnChanceList)
			TEST_ASSERT(!ispath(spawn_type, /turf/closed/mineral/gibtonite), "[rock_type] может породить [spawn_type]")
		spot = rock

/// Распорки пористой скалы держат копающего, а взрыв ломает её и с ними.
/datum/unit_test/porous_rock_struts_block_mining

/datum/unit_test/porous_rock_struts_block_mining/Run()
	var/turf/spot = locate(run_loc_floor_bottom_left.x + 1, run_loc_floor_bottom_left.y + 1, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/miner = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)

	var/turf/closed/mineral/asteroid/porous/rock = spot.ChangeTurf(/turf/closed/mineral/asteroid/porous, /turf/open/floor/plating/asteroid)
	rock.gets_drilled(miner)
	TEST_ASSERT(istype(spot, /turf/closed/mineral/asteroid/porous), "Скалу с распорками раскопали")
	rock.cut_struts()
	rock.gets_drilled(miner)
	TEST_ASSERT(!istype(spot, /turf/closed/mineral), "Скала без распорок не копается")

	rock = spot.ChangeTurf(/turf/closed/mineral/asteroid/porous, /turf/open/floor/plating/asteroid)
	rock.gets_drilled(null)
	TEST_ASSERT(!istype(spot, /turf/closed/mineral), "Взрыв не ломает скалу с распорками")
