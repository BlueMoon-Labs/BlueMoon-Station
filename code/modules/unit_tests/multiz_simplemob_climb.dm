/// Симплмоб кликом по лестнице лезет по ней, а не бьёт её.
/datum/unit_test/multiz_simplemob_ladder_click

/datum/unit_test/multiz_simplemob_ladder_click/Run()
	var/list/levels = multiz_ai_floor_test_levels()
	var/obj/structure/ladder/bottom = allocate(/obj/structure/ladder, locate(80, 60, levels[1]))
	var/obj/structure/ladder/top = allocate(/obj/structure/ladder, locate(80, 60, levels[2]))
	TEST_ASSERT_EQUAL(bottom.up, top, "Лестницы на соседних этажах не связались")

	for(var/climber_type in list(/mob/living/simple_animal/mouse, /mob/living/simple_animal/hostile/bear, /mob/living/simple_animal/slime))
		var/mob/living/simple_animal/climber = allocate(climber_type, get_turf(bottom))
		var/integrity_before = bottom.obj_integrity
		climber.CommonClickOn(bottom, "left=1")
		TEST_ASSERT_EQUAL(climber.loc, get_turf(top), "[climber_type] не поднялся по лестнице кликом")
		TEST_ASSERT_EQUAL(bottom.obj_integrity, integrity_before, "[climber_type] бил лестницу вместо подъёма")

/// Ползущий по трубам симплмоб меняет этаж через мульти-Z переходник.
/datum/unit_test/multiz_simplemob_ventcrawl_adapter

/datum/unit_test/multiz_simplemob_ventcrawl_adapter/Run()
	var/list/levels = multiz_ai_floor_test_levels()
	var/obj/machinery/atmospherics/pipe/simple/multiz/lower = allocate(/obj/machinery/atmospherics/pipe/simple/multiz, locate(82, 60, levels[1]))
	var/obj/machinery/atmospherics/pipe/simple/multiz/upper = allocate(/obj/machinery/atmospherics/pipe/simple/multiz, locate(82, 60, levels[2]))
	lower.atmosinit()
	upper.atmosinit()

	var/mob/living/simple_animal/mouse/crawler = allocate(/mob/living/simple_animal/mouse, locate(82, 60, levels[1]))
	crawler.forceMove(lower)
	TEST_ASSERT(crawler.move_vertically(UP), "Мышь не поднялась по трубам через переходник")
	TEST_ASSERT_EQUAL(crawler.loc, upper, "Мышь поднялась не в переходник этажом выше")
	TEST_ASSERT(crawler.move_vertically(DOWN), "Мышь не спустилась по трубам через переходник")
	TEST_ASSERT_EQUAL(crawler.loc, lower, "Мышь спустилась не в переходник этажом ниже")
	crawler.forceMove(locate(82, 60, levels[1]))
