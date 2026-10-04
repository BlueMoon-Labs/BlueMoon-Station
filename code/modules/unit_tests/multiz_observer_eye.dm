/// Наблюдение за мобом без худа регистрирует госта в observers, сброс вида снимает запись с обеих сторон.
/datum/unit_test/multiz_observer_eye_hudless_target

/datum/unit_test/multiz_observer_eye_hudless_target/Run()
	var/mob/living/carbon/human/npc = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/mob/dead/observer/ghost = allocate(/mob/dead/observer, run_loc_floor_bottom_left)
	TEST_ASSERT_NULL(npc.hud_used, "У моба без клиента не должно быть худа")

	ghost.set_observetarget(npc)
	TEST_ASSERT_EQUAL(ghost.observetarget, npc, "observetarget не записался при наблюдении моба без худа")
	TEST_ASSERT(ghost in npc.observers, "Гост, наблюдающий моба без худа, не попал в observers - смена этажа цели до его рендера не дойдёт")

	ghost.reset_perspective(null)
	TEST_ASSERT_NULL(ghost.observetarget, "Сброс вида не снял observetarget")
	TEST_ASSERT(!(ghost in npc.observers), "Сброс вида оставил госта в observers прежней цели")
