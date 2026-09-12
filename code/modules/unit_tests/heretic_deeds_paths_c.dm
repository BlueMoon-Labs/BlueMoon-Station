/// Зажжённая звезда засчитывается делу Космоса один раз на отдел.
/datum/unit_test/heretic_deed_cosmic/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_COSMIC)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	var/turf/first = run_loc_floor_bottom_left
	var/turf/second = get_step(get_step(first, EAST), EAST)
	TEST_ASSERT(knowledge.add_star(first, user), "Первая звезда зажигается.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, 1, "Звезда продвигает дело.")
	var/obj/effect/decal/cleanable/heretic_trace/trace = locate() in first
	TEST_ASSERT_NOTNULL(trace, "След остаётся под звездой.")
	allocated += trace
	user.forceMove(second)
	COOLDOWN_RESET(heretic.deed, progress_cooldown)
	TEST_ASSERT(knowledge.add_star(second, user), "Вторая звезда зажигается.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, 1, "Тот же отдел не засчитывается второй раз.")

/// Открытый Хваткой запертый шкаф засчитывается делу Замка один раз на отдел.
/datum/unit_test/heretic_deed_lock/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LOCK)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_lock)
	var/obj/structure/closet/closet = allocate(/obj/structure/closet, get_step(user, NORTH))
	closet.locked = TRUE
	TEST_ASSERT(knowledge.open_lock(closet, user, TRUE), "Хватка открывает запертый шкаф.")
	TEST_ASSERT(closet.opened && !closet.locked, "Шкаф открыт, а его замок снят.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, 1, "Открытый шкаф продвигает дело.")
	var/obj/effect/decal/cleanable/heretic_trace/trace = locate() in get_turf(closet)
	TEST_ASSERT_NOTNULL(trace, "След остаётся у замка.")
	allocated += trace
	var/obj/structure/closet/second = allocate(/obj/structure/closet, get_step(user, EAST))
	second.locked = TRUE
	COOLDOWN_RESET(heretic.deed, progress_cooldown)
	TEST_ASSERT(knowledge.open_lock(second, user, TRUE), "Второй шкаф тоже открывается.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, 1, "Тот же отдел не засчитывается второй раз.")

/// Хватка по раковине оставляет воду под еретиком и засчитывается делу Пучины один раз на отдел.
/datum/unit_test/heretic_deed_tide/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_TIDE)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_tide/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_tide)
	var/turf/open/place = get_turf(user)
	var/obj/structure/sink/sink = allocate(/obj/structure/sink, get_step(user, EAST))
	TEST_ASSERT(knowledge.on_mansus_grasp(sink, user, TRUE, null), "Хватка по раковине срабатывает.")
	TEST_ASSERT_NOTNULL(place.GetComponent(/datum/component/wet_floor), "Под еретиком появляется вода.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, 1, "Раковина продвигает дело.")
	var/obj/effect/decal/cleanable/heretic_trace/trace = locate() in place
	TEST_ASSERT_NOTNULL(trace, "След остаётся под еретиком.")
	allocated += trace
	var/obj/structure/sink/second = allocate(/obj/structure/sink, get_step(user, NORTH))
	COOLDOWN_RESET(heretic.deed, progress_cooldown)
	TEST_ASSERT(knowledge.on_mansus_grasp(second, user, TRUE, null), "Вторая раковина тоже даёт воду.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, 1, "Тот же отдел не засчитывается второй раз.")
	TEST_ASSERT(!knowledge.on_mansus_grasp(user, user, TRUE, null), "Живая цель не считается источником воды.")
	place.ClearWet()
