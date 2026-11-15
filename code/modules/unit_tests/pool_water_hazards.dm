/// Тесты бассейна на клетках резервации: уборка тестов турфы не возвращает, база перестилает их обратно.
/datum/unit_test/pool_water
	abstract_type = /datum/unit_test/pool_water
	var/list/changed_turfs = list()
	var/area/test_area
	var/saved_gravity

/datum/unit_test/pool_water/Destroy()
	for(var/turf/spot as anything in changed_turfs)
		for(var/obj/effect/decal/cleanable/mess in spot)
			qdel(mess)
		if(spot.liquids)
			qdel(spot.liquids, TRUE)
		spot.ChangeTurf(changed_turfs[spot])
	if(test_area)
		test_area.has_gravity = saved_gravity
	test_area = null
	return ..()

/datum/unit_test/pool_water/proc/spot_at(offset_x, offset_y)
	return locate(run_loc_floor_bottom_left.x + offset_x, run_loc_floor_bottom_left.y + offset_y, run_loc_floor_bottom_left.z)

/datum/unit_test/pool_water/proc/make_filled_pool(offset_x, offset_y)
	var/turf/spot = spot_at(offset_x, offset_y)
	if(!changed_turfs[spot])
		changed_turfs[spot] = spot.type
	var/turf/open/pool/pool = spot.ChangeTurf(/turf/open/pool)
	if(!test_area)
		test_area = get_area(pool)
		saved_gravity = test_area.has_gravity
		test_area.has_gravity = STANDARD_GRAVITY
	refill(pool)
	return pool

/datum/unit_test/pool_water/proc/refill(turf/open/pool/pool)
	if(pool.liquids)
		qdel(pool.liquids, TRUE)
	pool.add_liquid(/datum/reagent/water, POOL_START_LIQUID, TRUE)

/// Пена ивентов из вентиляции не смывает и не высушивает воду бассейна, с каким бы реагентом она ни шла.
/datum/unit_test/pool_water/survives_event_foam

/datum/unit_test/pool_water/survives_event_foam/Run()
	var/turf/open/pool/pool = make_filled_pool(1, 1)
	var/datum/round_event/scrubber_overflow/overflow = new(FALSE)
	var/list/reagent_types = list(
		/datum/reagent/space_cleaner/gentle,
		/datum/reagent/space_cleaner,
		/datum/reagent/drying_agent,
		/datum/reagent/toxin/acid,
		/datum/reagent/toxin/acid/fluacid,
		/datum/reagent/clf3
	) | overflow.safer_chems
	overflow.kill()
	qdel(overflow)
	for(var/reagent_type in reagent_types)
		refill(pool)
		var/obj/effect/particle_effect/foam/foam = new(pool)
		foam.stop_processing()
		foam.reagents.add_reagent(reagent_type, 100)
		foam.apply_reagent_dose(1, pool)
		qdel(foam)
		TEST_ASSERT(istype(pool, /turf/open/pool), "пена с [reagent_type] превратила бассейн в [pool.type]")
		var/water_left = pool.liquids ? pool.liquids.reagent_list[/datum/reagent/water] : 0
		TEST_ASSERT(water_left >= POOL_START_LIQUID, "пена с [reagent_type] убрала воду бассейна: осталось [water_left] из [POOL_START_LIQUID]")

/// Ботинки-осушители не выпивают бассейн, по которому в них идут.
/datum/unit_test/pool_water/survives_drying_galoshes

/datum/unit_test/pool_water/survives_drying_galoshes/Run()
	var/turf/open/pool/pool = make_filled_pool(1, 1)
	var/obj/item/clothing/shoes/galoshes/dry/galoshes = allocate(/obj/item/clothing/shoes/galoshes/dry, pool)
	galoshes.step_action()
	TEST_ASSERT_NOTNULL(pool.liquids, "ботинки-осушители высушили бассейн")

/// Летящий над бассейном не падает в воду, но опускается в неё, когда садится; идущий пешком падает сразу.
/datum/unit_test/pool_water/flyer_hovers

/datum/unit_test/pool_water/flyer_hovers/Run()
	var/turf/open/pool/pool = make_filled_pool(1, 1)
	var/turf/shore = spot_at(2, 1)

	var/mob/living/carbon/human/flyer = allocate(/mob/living/carbon/human, shore)
	flyer.setMovetype(flyer.movement_type | FLYING)
	flyer.forceMove(pool)
	TEST_ASSERT(!HAS_TRAIT(flyer, TRAIT_SWIMMING), "летящий упал в воду бассейна")
	TEST_ASSERT_EQUAL(flyer.getBruteLoss(), 0, "летящий ударился о воду бассейна")
	TEST_ASSERT_NULL(flyer.has_status_effect(/datum/status_effect/water_affected), "летящий намок, не касаясь воды")

	flyer.setMovetype(flyer.movement_type & ~FLYING)
	TEST_ASSERT(HAS_TRAIT(flyer, TRAIT_SWIMMING), "севший над бассейном не оказался в воде")
	TEST_ASSERT_EQUAL(flyer.getBruteLoss(), 0, "посадка в воду бьёт как падение")

	var/mob/living/carbon/human/walker = allocate(/mob/living/carbon/human, shore)
	walker.forceMove(pool)
	TEST_ASSERT(HAS_TRAIT(walker, TRAIT_SWIMMING), "шагнувший в бассейн пешком не упал в воду")

/datum/unit_test/pool_water/proc/make_water_vulnerable_synth(turf/spot)
	var/mob/living/carbon/human/synth = allocate(/mob/living/carbon/human, spot)
	ADD_TRAIT(synth, TRAIT_ROBOTIC_ORGANISM, TRAIT_GENERIC)
	ADD_TRAIT(synth, TRAIT_BLUEMOON_WATER_VULNERABILITY, TRAIT_GENERIC)
	return synth

/// Синтетик с водобоязнью не замыкает, пролетая над бассейном, но замыкает, когда садится в воду.
/datum/unit_test/pool_water/flying_synth_stays_dry

/datum/unit_test/pool_water/flying_synth_stays_dry/Run()
	var/turf/open/pool/pool = make_filled_pool(1, 1)
	var/mob/living/carbon/human/synth = make_water_vulnerable_synth(spot_at(2, 1))
	synth.setMovetype(synth.movement_type | FLYING)
	synth.forceMove(pool)
	TEST_ASSERT(!HAS_TRAIT(synth, TRAIT_BLUEMOON_WATER_EXPOSED), "летящего синтетика замкнуло над бассейном")
	TEST_ASSERT(!is_in_water(synth), "летящий над бассейном считается в воде")
	TEST_ASSERT_EQUAL(synth.getFireLoss(), 0, "летящий синтетик обжёгся над бассейном")

	synth.setMovetype(synth.movement_type & ~FLYING)
	TEST_ASSERT(is_in_water(synth), "севший в бассейн синтетик не в воде")
	TEST_ASSERT(HAS_TRAIT(synth, TRAIT_BLUEMOON_WATER_EXPOSED), "севшего в воду синтетика не замкнуло")

/// Севший в затопленную комнату намокает сразу, не дожидаясь шага.
/datum/unit_test/pool_water/landing_in_flood_wets

/datum/unit_test/pool_water/landing_in_flood_wets/Run()
	var/turf/open/floor = spot_at(1, 1)
	if(!changed_turfs[floor])
		changed_turfs[floor] = floor.type
	floor.add_liquid(/datum/reagent/water, POOL_START_LIQUID, TRUE)
	floor.liquids.calculate_height()
	TEST_ASSERT(floor.liquids.liquid_state >= LIQUID_STATE_ANKLES, "вода на полу не поднялась до лодыжек")

	var/mob/living/carbon/human/flyer = allocate(/mob/living/carbon/human, spot_at(2, 1))
	flyer.setMovetype(flyer.movement_type | FLYING)
	flyer.forceMove(floor)
	TEST_ASSERT_NULL(flyer.has_status_effect(/datum/status_effect/water_affected), "летящий намок над затопленным полом")

	flyer.setMovetype(flyer.movement_type & ~FLYING)
	TEST_ASSERT_NOTNULL(flyer.has_status_effect(/datum/status_effect/water_affected), "севший в воду не намок до первого шага")

/// Продвинутая швабра не стирает воду бассейна одним махом, а с разлива на полу по-прежнему стирает.
/datum/unit_test/pool_water/survives_advanced_mop

/datum/unit_test/pool_water/survives_advanced_mop/Run()
	var/turf/open/pool/pool = make_filled_pool(1, 1)
	var/mob/living/carbon/human/janitor = allocate(/mob/living/carbon/human, spot_at(2, 1))
	var/obj/item/mop/advanced/mop = allocate(/obj/item/mop/advanced, janitor.loc)
	mop.attack_liquids_turf(pool, janitor, pool.liquids)
	var/water_left = pool.liquids ? pool.liquids.reagent_list[/datum/reagent/water] : 0
	TEST_ASSERT(water_left >= POOL_START_LIQUID, "продвинутая швабра убрала воду бассейна: осталось [water_left] из [POOL_START_LIQUID]")

	var/turf/open/floor = spot_at(3, 1)
	if(!changed_turfs[floor])
		changed_turfs[floor] = floor.type
	floor.add_liquid(/datum/reagent/water, 30, TRUE)
	mop.attack_liquids_turf(floor, janitor, floor.liquids)
	TEST_ASSERT(!floor.liquids || floor.liquids.total_reagents <= 0, "продвинутая швабра перестала стирать разлив с пола")
