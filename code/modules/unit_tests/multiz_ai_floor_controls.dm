/// Два пустых сцепленных уровня, общие для тестов этого файла: поднятый уровень живёт до конца прогона.
/proc/multiz_ai_floor_test_levels()
	var/static/list/levels
	if(!levels)
		var/datum/space_level/lower = SSmapping.add_new_zlevel("Тест этажей ИИ: нижний этаж", list())
		var/datum/space_level/upper = SSmapping.add_new_zlevel("Тест этажей ИИ: верхний этаж", list())
		var/datum/map_template/probe = new
		probe.link_template_stack(list(lower, upper))
		qdel(probe)
		levels = list(lower.z_value, upper.z_value)
	return levels

/// Камерный моб, переставленный forceMove на другой этаж, уводит за собой этаж своего худа.
/datum/unit_test/multiz_camera_forcemove_moves_hud

/datum/unit_test/multiz_camera_forcemove_moves_hud/Run()
	var/list/levels = multiz_ai_floor_test_levels()
	var/turf/lower = locate(10, 10, levels[1])
	var/turf/upper = locate(10, 10, levels[2])
	var/mob/camera/aiEye/eye = allocate(/mob/camera/aiEye, upper)
	var/datum/hud/hud = new(eye)
	eye.set_hud_used(hud)
	TEST_ASSERT_EQUAL(hud.current_plane_offset, 0, "Глаз на верхнем этаже связки, смещение худа должно быть нулевым")

	eye.forceMove(lower)
	TEST_ASSERT_EQUAL(eye.loc, lower, "forceMove не перенёс камеру")
	TEST_ASSERT_EQUAL(hud.current_plane_offset, GET_Z_PLANE_OFFSET(lower.z), "Худ камеры остался на верхнем этаже: нижний рисуется как этаж под ногами, то есть чёрным")

	eye.forceMove(upper)
	TEST_ASSERT_EQUAL(hud.current_plane_offset, 0, "Худ не вернулся на верхний этаж вслед за камерой")

/// Кнопки этажей на худе ИИ видны только в связке, показывают этаж камеры и переводят её по клику.
/datum/unit_test/multiz_ai_floor_buttons

/datum/unit_test/multiz_ai_floor_buttons/Run()
	var/list/levels = multiz_ai_floor_test_levels()
	var/turf/lower = locate(10, 10, levels[1])
	var/turf/upper = locate(10, 10, levels[2])
	var/mob/living/carbon/human/donor = allocate(/mob/living/carbon/human)
	var/mob/living/silicon/ai/ai = allocate(/mob/living/silicon/ai, lower, null, donor)
	var/datum/hud/ai/hud = new(ai)
	ai.set_hud_used(hud)
	TEST_ASSERT_NOTNULL(hud.floor_changer, "На худе ИИ нет кнопки смены этажа")
	TEST_ASSERT(hud.floor_changer in hud.static_inventory, "Кнопка смены этажа не попала на экран худа")
	TEST_ASSERT_EQUAL(hud.floor_changer.invisibility, 0, "В связке из двух этажей кнопка смены этажа скрыта")
	TEST_ASSERT_EQUAL(hud.floor_indicator.invisibility, 0, "В связке из двух этажей номер этажа скрыт")
	TEST_ASSERT(findtext(hud.floor_indicator.maptext, "1/2"), "Нижний этаж связки подписан не как 1/2: [hud.floor_indicator.maptext]")

	usr = ai
	hud.floor_changer.Click(null, null, "icon-x=24;icon-y=24")
	TEST_ASSERT_EQUAL(ai.eyeobj.loc, upper, "Клик по верхней половине кнопки не поднял камеру ИИ")
	hud.floor_changer.Click(null, null, "icon-x=24;icon-y=8")
	TEST_ASSERT_EQUAL(ai.eyeobj.loc, lower, "Клик по нижней половине кнопки не опустил камеру ИИ")
	usr = null

	ai.forceMove(upper)
	TEST_ASSERT(findtext(hud.floor_indicator.maptext, "2/2"), "Верхний этаж связки подписан не как 2/2: [hud.floor_indicator.maptext]")

	ai.forceMove(run_loc_floor_bottom_left)
	TEST_ASSERT_EQUAL(hud.floor_changer.invisibility, INVISIBILITY_ABSTRACT, "На одноэтажном уровне кнопка смены этажа видна")
	TEST_ASSERT_EQUAL(hud.floor_indicator.invisibility, INVISIBILITY_ABSTRACT, "На одноэтажном уровне номер этажа виден")

/// Кнопка этажей госта переносит его на соседний уровень.
/datum/unit_test/multiz_ghost_floor_changer

/datum/unit_test/multiz_ghost_floor_changer/Run()
	var/list/levels = multiz_ai_floor_test_levels()
	var/turf/lower = locate(10, 10, levels[1])
	var/mob/dead/observer/ghost = allocate(/mob/dead/observer, lower)
	var/atom/movable/screen/floor_changer/ghost/changer = new
	allocated += changer

	usr = ghost
	changer.Click(null, null, "icon-x=16;icon-y=24")
	usr = null
	TEST_ASSERT_EQUAL(ghost.z, lower.z + 1, "Кнопка этажей не подняла госта на уровень выше")
