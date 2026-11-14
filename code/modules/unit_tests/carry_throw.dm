/// Тело, которое несут на плечах, бросается кликом в режиме броска, а не кладётся под ноги.
/datum/unit_test/fireman_carry_throw

/datum/unit_test/fireman_carry_throw/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/turf/aim = locate(start.x + 4, start.y, start.z)
	var/mob/living/carbon/human/carrier = allocate(/mob/living/carbon/human, start)
	var/mob/living/carbon/human/body = allocate(/mob/living/carbon/human, start)

	carrier.buckle_mob(body, TRUE, TRUE, buckle_type = RIDING_FIREMAN, auto_by_type = TRUE)
	TEST_ASSERT_EQUAL(body.buckled, carrier, "Тело лежит на плечах переносчика.")
	TEST_ASSERT(istype(carrier.get_active_held_item(), /obj/item/riding_offhand), "Переносчик держит тело активной рукой.")

	carrier.throw_mode_on()
	carrier.ClickOn(aim, "")

	TEST_ASSERT_NULL(body.buckled, "После броска тело не на плечах.")
	TEST_ASSERT(body.throwing || get_dist(start, body) >= 2, "Тело летит, а не падает под ноги (до цели [get_dist(body, aim)]).")
	TEST_ASSERT(!carrier.get_active_held_item(), "Оффхенд переноски убран из руки.")

/// Пацифист, бросая тело с плеч, только аккуратно его отпускает.
/datum/unit_test/fireman_carry_throw_pacifist

/datum/unit_test/fireman_carry_throw_pacifist/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/turf/aim = locate(start.x + 4, start.y, start.z)
	var/mob/living/carbon/human/carrier = allocate(/mob/living/carbon/human, start)
	var/mob/living/carbon/human/body = allocate(/mob/living/carbon/human, start)
	ADD_TRAIT(carrier, TRAIT_PACIFISM, TRAIT_GENERIC)

	carrier.buckle_mob(body, TRUE, TRUE, buckle_type = RIDING_FIREMAN, auto_by_type = TRUE)
	carrier.throw_mode_on()
	carrier.ClickOn(aim, "")

	TEST_ASSERT_NULL(body.buckled, "Пацифист снимает тело с плеч.")
	TEST_ASSERT_NULL(body.throwing, "Пацифист тело не бросает.")
	TEST_ASSERT_EQUAL(get_turf(body), start, "Тело остаётся у ног пацифиста.")

/// Того, кто держится за спину переносчика, сам седок бросить не может.
/datum/unit_test/piggyback_rider_cannot_throw_carrier

/datum/unit_test/piggyback_rider_cannot_throw_carrier/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/turf/aim = locate(start.x + 4, start.y, start.z)
	var/mob/living/carbon/human/carrier = allocate(/mob/living/carbon/human, start)
	var/mob/living/carbon/human/rider = allocate(/mob/living/carbon/human, start)

	carrier.buckle_mob(rider, TRUE, TRUE, buckle_type = RIDING_PIGGYBACK, auto_by_type = TRUE)
	TEST_ASSERT_EQUAL(rider.buckled, carrier, "Седок на спине.")
	TEST_ASSERT(istype(rider.get_active_held_item(), /obj/item/riding_offhand), "Седок держится руками.")

	rider.throw_mode_on()
	rider.ClickOn(aim, "")

	TEST_ASSERT_EQUAL(rider.buckled, carrier, "Седок остаётся на спине.")
	TEST_ASSERT_NULL(carrier.throwing, "Переносчик никуда не летит.")

/// Моба в агрессивном захвате бросают кликом в режиме броска.
/datum/unit_test/aggressive_grab_throw

/datum/unit_test/aggressive_grab_throw/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/turf/aim = locate(start.x + 4, start.y, start.z)
	var/mob/living/carbon/human/thrower = allocate(/mob/living/carbon/human, start)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(start, EAST))

	victim.grabbedby(thrower)
	TEST_ASSERT_EQUAL(thrower.pulling, victim, "Цель взята за руку.")
	victim.grabbedby(thrower)
	TEST_ASSERT_EQUAL(thrower.grab_state, GRAB_AGGRESSIVE, "Захват агрессивный.")

	// кликдилей усиления захвата игрок пережидает, тест его сбрасывает
	thrower.last_action = 0
	thrower.last_action_immediate = 0
	thrower.next_action = 0
	thrower.next_action_immediate = 0
	thrower.throw_mode_on()
	thrower.ClickOn(aim, "")

	TEST_ASSERT_NULL(thrower.pulling, "Захват отпущен броском.")
	TEST_ASSERT(victim.throwing || get_dist(start, victim) >= 3, "Схваченный летит (до цели [get_dist(victim, aim)]).")
