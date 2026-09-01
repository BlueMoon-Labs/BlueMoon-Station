/mob/living/unit_test/no_med_huds
	hud_possible = list(ANTAG_HUD)

/datum/unit_test/med_hud_null_safety/Run()
	var/mob/living/unit_test/no_med_huds/test_mob = allocate(/mob/living/unit_test/no_med_huds)

	TEST_ASSERT(!test_mob.hud_list[HEALTH_HUD], "Test mob unexpectedly has a health HUD holder.")
	TEST_ASSERT(!test_mob.hud_list[STATUS_HUD], "Test mob unexpectedly has a status HUD holder.")
	TEST_ASSERT(!test_mob.hud_list[RAD_HUD], "Test mob unexpectedly has a radiation HUD holder.")

	// These calls used to runtime when a /mob/living subtype lacked med HUD entries.
	test_mob.med_hud_set_health()
	test_mob.med_hud_set_status()
	test_mob.med_hud_set_radstatus()
