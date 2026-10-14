/// Navigate показывает точки со всей связки этажей и ведёт к ближайшей лестнице на этаж цели.
/datum/unit_test/multiz_navigate_other_floor

/datum/unit_test/multiz_navigate_other_floor/Run()
	var/list/levels = multiz_ai_floor_test_levels()
	var/turf/start = locate(30, 30, levels[1])
	var/turf/upstairs_point = locate(40, 30, levels[2])
	GLOB.navigate_destinations[upstairs_point] = "Тестовый гейтвей"
	GLOB.navigate_destinations[run_loc_floor_top_right] = "Чужой уровень"
	var/mob/living/carbon/human/walker = allocate(/mob/living/carbon/human, start)
	var/list/destinations = walker.get_navigation_destinations()
	GLOB.navigate_destinations -= upstairs_point
	GLOB.navigate_destinations -= run_loc_floor_top_right

	TEST_ASSERT_EQUAL(destinations["Тестовый гейтвей (выше)"], upstairs_point, "Точка с верхнего этажа связки не попала в список навигации")
	TEST_ASSERT(!("Чужой уровень" in destinations), "В список навигации попала точка с уровня вне связки")
	TEST_ASSERT_EQUAL(destinations["Nearest Way Up"], UP, "С нижнего этажа связки нет пункта пути наверх")
	TEST_ASSERT(!("Nearest Way Down" in destinations), "С нижнего этажа связки предложен путь вниз")
	TEST_ASSERT_EQUAL(walker.navigation_vertical_dir(upstairs_point), UP, "Цель на верхнем этаже не распознана как цель наверху")

	var/obj/structure/ladder/bottom = allocate(/obj/structure/ladder, locate(33, 30, levels[1]))
	allocate(/obj/structure/ladder, locate(33, 30, levels[2]))
	TEST_ASSERT_EQUAL(walker.find_nearest_stair_or_ladder(UP), bottom, "Путь наверх не нашёл обычную лестницу этого этажа")
