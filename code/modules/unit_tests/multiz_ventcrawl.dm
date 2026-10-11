/// Ползущий по трубам перебирается на соседний этаж через мульти-Z переходник, а из обычной трубы - нет.
/datum/unit_test/multiz_ventcrawl_through_adapter

/datum/unit_test/multiz_ventcrawl_through_adapter/Run()
	var/list/levels = multiz_ai_floor_test_levels()
	var/obj/machinery/atmospherics/pipe/simple/multiz/lower = allocate(/obj/machinery/atmospherics/pipe/simple/multiz, locate(60, 60, levels[1]))
	var/obj/machinery/atmospherics/pipe/simple/multiz/upper = allocate(/obj/machinery/atmospherics/pipe/simple/multiz, locate(60, 60, levels[2]))
	var/obj/machinery/atmospherics/pipe/simple/plain = allocate(/obj/machinery/atmospherics/pipe/simple, locate(61, 60, levels[1]))
	lower.atmosinit()
	upper.atmosinit()
	TEST_ASSERT_EQUAL(lower.nodes[2], upper, "Переходник не связался с переходником этажом выше")

	var/mob/living/carbon/human/crawler = allocate(/mob/living/carbon/human, locate(60, 60, levels[1]))
	crawler.forceMove(lower)
	TEST_ASSERT(crawler.move_vertically(UP), "Из переходника не удалось подняться по трубам")
	TEST_ASSERT_EQUAL(crawler.loc, upper, "Ползущий поднялся не в переходник этажом выше")
	TEST_ASSERT(crawler.move_vertically(DOWN), "Из переходника не удалось спуститься по трубам")
	TEST_ASSERT_EQUAL(crawler.loc, lower, "Ползущий спустился не в переходник этажом ниже")

	crawler.forceMove(plain)
	TEST_ASSERT(!crawler.move_vertically(UP), "Из обычной трубы удалось сменить этаж")
	TEST_ASSERT_EQUAL(crawler.loc, plain, "Неудачная смена этажа вытащила ползущего из трубы")
	crawler.forceMove(locate(60, 60, levels[1]))
