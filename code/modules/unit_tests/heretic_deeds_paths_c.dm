/// Путеводная звезда засчитывается делу Космоса один раз на отдел, а звёзды созвездия дело не двигают.
/datum/unit_test/heretic_deed_cosmic/Run()
	allocated += new /datum/heretic_test_station_level(run_loc_floor_bottom_left.z)
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_COSMIC)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_cosmic/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	var/turf/first = run_loc_floor_bottom_left
	var/turf/second = get_step(get_step(first, EAST), EAST)
	TEST_ASSERT(knowledge.add_star(first, user), "Звезда созвездия зажигается.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, 0, "Звезда созвездия дело не двигает.")
	TEST_ASSERT(knowledge.place_guide_star(user, first), "Путеводная звезда зажигается.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, 1, "Путеводная звезда продвигает дело.")
	var/obj/effect/decal/cleanable/heretic_trace/trace = locate() in first
	TEST_ASSERT_NOTNULL(trace, "След остаётся под звездой.")
	allocated += trace
	COOLDOWN_RESET(heretic.deed, progress_cooldown)
	TEST_ASSERT(knowledge.place_guide_star(user, second), "Вторая путеводная звезда зажигается.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, 1, "Тот же отдел не засчитывается второй раз.")
	TEST_ASSERT(findtext(heretic.deed.desc, "путеводная звезда не зажигается"), "Описание дела называет паузу ремесла.")

/// Открытый Хваткой запертый шкаф засчитывается делу Замка один раз на отдел, помеченный шлюз в другом отделе станции - тоже.
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
	var/turf/door_spot = locate(user.x + 2, user.y + 3, user.z)
	allocated += new /datum/heretic_test_station_level(door_spot.z)
	heretic_test_area(door_spot, /area/unit_test_lock_deck)
	var/obj/machinery/door/airlock/door = allocate(/obj/machinery/door/airlock, door_spot)
	COOLDOWN_RESET(heretic.deed, progress_cooldown)
	TEST_ASSERT(knowledge.mark_door(user, door), "Хватка в «Помощи» помечает шлюз в другом отделе.")
	TEST_ASSERT_EQUAL(length(heretic.deed.counted_keys), 2, "Помеченный шлюз засчитывается делу.")
	var/obj/effect/decal/cleanable/heretic_trace/door_trace = locate() in door_spot
	TEST_ASSERT_NOTNULL(door_trace, "След остаётся у помеченного шлюза.")
	allocated += door_trace
	TEST_ASSERT(findtext(heretic.deed.desc, "шлюз не помечается"), "Описание дела называет паузу ремесла.")

/// Хватка по раковине открывает прорыв и засчитывается делу Пучины один раз на отдел.
/datum/unit_test/heretic_deed_tide/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_TIDE)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_tide/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_tide)
	var/obj/structure/sink/sink = allocate(/obj/structure/sink, get_step(user, EAST))
	TEST_ASSERT(knowledge.on_mansus_grasp(sink, user, TRUE, null), "Хватка по раковине открывает прорыв.")
	TEST_ASSERT(sink in knowledge.breaches, "Раковина стала прорывом.")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/heretic_tide_puddle/breach) in get_turf(sink), "У раковины стоит вода.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, 1, "Прорыв продвигает дело.")
	var/obj/effect/decal/cleanable/heretic_trace/trace = locate() in get_turf(sink)
	TEST_ASSERT_NOTNULL(trace, "След остаётся у источника.")
	allocated += trace
	var/obj/structure/sink/second = allocate(/obj/structure/sink, get_step(user, NORTH))
	COOLDOWN_RESET(heretic.deed, progress_cooldown)
	TEST_ASSERT(knowledge.on_mansus_grasp(second, user, TRUE, null), "Вторая раковина тоже открывает прорыв.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, 1, "Тот же отдел не засчитывается второй раз.")
	TEST_ASSERT(!knowledge.on_mansus_grasp(user, user, TRUE, null), "Живая цель не считается источником воды.")
