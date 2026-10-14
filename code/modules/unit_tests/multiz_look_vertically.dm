/datum/unit_test/multiz_look_vertically
	/// list(x, y, z, исходный тип) на каждый подменённый турф.
	var/list/replaced_turfs = list()

/// Общая база: раннер гоняет и её, поэтому Run() пустой.
/datum/unit_test/multiz_look_vertically/Run()
	return

/datum/unit_test/multiz_look_vertically/Destroy()
	for(var/list/entry as anything in replaced_turfs)
		var/turf/replaced = locate(entry[1], entry[2], entry[3])
		replaced.ChangeTurf(entry[4])
	replaced_turfs = null
	return ..()

/datum/unit_test/multiz_look_vertically/proc/set_turf(x, y, z, new_type)
	var/turf/old_turf = locate(x, y, z)
	replaced_turfs += list(list(x, y, z, old_turf.type))
	return old_turf.ChangeTurf(new_type)

/// Пол на квадрате 5x5 обоих этажей с центром в (x, y).
/datum/unit_test/multiz_look_vertically/proc/build_floors(x, y)
	var/list/levels = multiz_ai_floor_test_levels()
	for(var/z in levels)
		for(var/turf_x in x - 2 to x + 2)
			for(var/turf_y in y - 2 to y + 2)
				set_turf(turf_x, turf_y, z, /turf/open/floor/plasteel)

/// Вверх смотрят сквозь дыру над собой, перед собой или рядом; уход от дыры возвращает взгляд.
/datum/unit_test/multiz_look_vertically/up

/datum/unit_test/multiz_look_vertically/up/Run()
	var/list/levels = multiz_ai_floor_test_levels()
	build_floors(30, 30)
	var/mob/living/carbon/human/looker = allocate(/mob/living/carbon/human, locate(30, 30, levels[1]))

	TEST_ASSERT(!looker.look_vertically(UP), "Сквозь сплошной потолок посмотреть вверх удалось")
	TEST_ASSERT_EQUAL(looker.looking_vertically, NONE, "Неудачный взгляд вверх оставил флаг")
	TEST_ASSERT_NULL(looker.looking_holder, "Неудачный взгляд вверх оставил держатель")

	var/turf/side_hole = set_turf(31, 30, levels[2], /turf/open/openspace)
	var/turf/front_hole = set_turf(30, 31, levels[2], /turf/open/openspace)
	TEST_ASSERT(side_hole.shows_level_below() && front_hole.shows_level_below(), "Openspace не стал прозрачным")
	looker.setDir(NORTH)
	looker.next_move = 0
	TEST_ASSERT(looker.look_vertically(UP), "Взгляд вверх сквозь соседние дыры не удался")
	TEST_ASSERT_EQUAL(looker.looking_vertically, UP, "Флаг взгляда вверх не встал")
	var/obj/effect/abstract/looking_holder/holder = looker.looking_holder
	TEST_ASSERT_EQUAL(holder?.loc, front_hole, "Из двух дыр взгляд выбрал не ту, что перед мобом")

	looker.forceMove(locate(32, 29, levels[1]))
	TEST_ASSERT_EQUAL(holder.loc, side_hole, "Шаг под другую дыру не перевёл взгляд на неё")

	looker.forceMove(locate(40, 40, levels[1]))
	TEST_ASSERT_EQUAL(looker.looking_vertically, NONE, "Уход от дыр не вернул взгляд")
	TEST_ASSERT(QDELETED(holder), "Уход от дыр не удалил держатель")

/// Вниз смотрят сквозь дыру в своём полу на этаж ниже; взгляд в обратную сторону только сбрасывает его.
/datum/unit_test/multiz_look_vertically/down

/datum/unit_test/multiz_look_vertically/down/Run()
	var/list/levels = multiz_ai_floor_test_levels()
	build_floors(50, 30)
	var/mob/living/carbon/human/looker = allocate(/mob/living/carbon/human, locate(50, 30, levels[2]))
	set_turf(51, 30, levels[2], /turf/open/openspace)

	TEST_ASSERT(looker.look_vertically(DOWN), "Взгляд вниз сквозь соседнюю дыру не удался")
	var/obj/effect/abstract/looking_holder/holder = looker.looking_holder
	TEST_ASSERT_EQUAL(holder?.loc, locate(51, 30, levels[1]), "Взгляд вниз встал не под дырой")

	looker.next_move = 0
	TEST_ASSERT(!looker.look_vertically(UP), "Взгляд вверх из взгляда вниз не должен сразу переключать этаж")
	TEST_ASSERT_EQUAL(looker.looking_vertically, NONE, "Взгляд в обратную сторону не сбросил взгляд вниз")
	TEST_ASSERT(QDELETED(holder), "Сброшенный взгляд оставил держатель")

	looker.next_move = 0
	TEST_ASSERT(!looker.look_vertically(UP), "С верхнего этажа связки посмотреть вверх удалось")

/// Чужая смена вида и удаление моба гасят взгляд; свой держатель в роли глаза взгляд не трогает.
/datum/unit_test/multiz_look_vertically/cleanup

/datum/unit_test/multiz_look_vertically/cleanup/Run()
	var/list/levels = multiz_ai_floor_test_levels()
	build_floors(70, 30)
	var/mob/living/carbon/human/looker = allocate(/mob/living/carbon/human, locate(70, 30, levels[1]))
	set_turf(70, 30, levels[2], /turf/open/openspace)

	TEST_ASSERT(looker.look_vertically(UP), "Взгляд вверх сквозь дыру прямо над мобом не удался")
	var/obj/effect/abstract/looking_holder/holder = looker.looking_holder
	SEND_SIGNAL(looker, COMSIG_MOB_RESET_PERSPECTIVE, holder)
	TEST_ASSERT_EQUAL(looker.looking_holder, holder, "Вид на свой держатель сбросил взгляд")
	SEND_SIGNAL(looker, COMSIG_MOB_RESET_PERSPECTIVE, null)
	TEST_ASSERT_EQUAL(looker.looking_vertically, NONE, "Чужая смена вида не сбросила взгляд")
	TEST_ASSERT(QDELETED(holder), "Чужая смена вида оставила держатель")

	looker.next_move = 0
	TEST_ASSERT(looker.look_vertically(UP), "Повторный взгляд вверх не удался")
	holder = looker.looking_holder
	allocated -= looker
	qdel(looker)
	TEST_ASSERT(QDELETED(holder), "Удалённый моб оставил держатель")
