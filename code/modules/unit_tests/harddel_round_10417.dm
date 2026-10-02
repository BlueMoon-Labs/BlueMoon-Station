/// Удаление моба удаляет его vore-панель: панель держит хозяина в host.
/datum/unit_test/vore_panel_released_with_mob/Run()
	var/mob/living/carbon/human/host = allocate(/mob/living/carbon/human)
	host.vorePanel = new(host)
	var/datum/vore_look/panel = host.vorePanel
	qdel(host)
	TEST_ASSERT(QDELETED(panel), "vore-панель пережила удаление моба")
	TEST_ASSERT_NULL(panel.host, "vore-панель держит удалённого моба")
