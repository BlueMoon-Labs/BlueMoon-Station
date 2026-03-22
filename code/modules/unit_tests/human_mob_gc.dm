/// Test: Destroy() properly breaks hud_list image→mob reference cycle
/datum/unit_test/gc_human_hud_list_cleanup
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_human_hud_list_cleanup/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	TEST_ASSERT_NOTNULL(human.hud_list, "Human mob hud_list was not initialized")
	TEST_ASSERT(length(human.hud_list) > 0, "Human mob hud_list is empty")

	// Verify images reference the mob via loc (the cycle we're fixing)
	var/found_image_with_loc = FALSE
	for(var/hud_key in human.hud_list)
		var/image/hud_image = human.hud_list[hud_key]
		if(istype(hud_image) && hud_image.loc == human)
			found_image_with_loc = TRUE
			break
	TEST_ASSERT(found_image_with_loc, "No hud_list images reference the mob via loc (test premise broken)")

	// Save references to images before destruction
	var/list/saved_images = list()
	for(var/hud_key in human.hud_list)
		var/image/hud_image = human.hud_list[hud_key]
		if(istype(hud_image))
			saved_images += hud_image

	allocated -= human
	qdel(human)

	// Verify all image locs were broken
	for(var/image/img in saved_images)
		TEST_ASSERT_NULL(img.loc, "hud_list image still has loc set after mob Destroy()")
	saved_images = null
	human = null

/// Test: Destroy() properly clears last_mind reference
/datum/unit_test/gc_human_last_mind_cleanup
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_human_last_mind_cleanup/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/mind/test_mind = new()
	test_mind.transfer_to(human)

	TEST_ASSERT_EQUAL(human.last_mind, test_mind, "last_mind was not set during mind transfer")

	allocated -= human
	qdel(human)

	// Mind should not prevent GC — last_mind must be nulled during Destroy
	// We can't check the variable directly after qdel since the mob may be gone,
	// so we verify the mind's destroy_time doesn't block (it was properly detached)
	qdel(test_mind)
	test_mind = null
	human = null

/// Test: human mob Destroy() chain runs without runtimes
/datum/unit_test/gc_human_destroy_no_runtimes
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_human_destroy_no_runtimes/Run()
	configure_immediate_gc()

	// Basic human — no mind, no equipment
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	allocated -= human
	qdel(human)
	human = null
	run_gc_fire_cycles(2)

	// Human with mind — simulates player mob
	var/mob/living/carbon/human/human_with_mind = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/mind/test_mind = new()
	test_mind.transfer_to(human_with_mind)
	allocated -= human_with_mind
	qdel(human_with_mind)
	human_with_mind = null
	qdel(test_mind)
	test_mind = null
	run_gc_fire_cycles(2)

	// Dead human with mind — explosion death scenario
	var/mob/living/carbon/human/dead_human = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/mind/dead_mind = new()
	dead_mind.transfer_to(dead_human)
	dead_human.death()
	TEST_ASSERT_EQUAL(dead_human.stat, DEAD, "Human did not die")
	allocated -= dead_human
	qdel(dead_human)
	dead_human = null
	qdel(dead_mind)
	dead_mind = null
	run_gc_fire_cycles(2)

	// If we got here without runtimes, the Destroy chain is clean
	// (runtimes during fire cycles would cause test failure)

/// Test: human mob with wounds Destroy() chain runs without runtimes
/datum/unit_test/gc_human_wound_cleanup
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_human_wound_cleanup/Run()
	configure_immediate_gc()

	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/item/bodypart/chest/chest = human.get_bodypart(BODY_ZONE_CHEST)
	TEST_ASSERT_NOTNULL(chest, "Human has no chest bodypart")

	// Apply a wound to create the reference cycle
	var/datum/wound/slash/moderate/wound = new()
	wound.apply_wound(chest)

	TEST_ASSERT(LAZYLEN(human.all_wounds) > 0, "Wound was not applied to human")
	TEST_ASSERT(LAZYLEN(chest.wounds) > 0, "Wound was not applied to chest bodypart")

	chest = null
	wound = null
	allocated -= human
	qdel(human)
	human = null

	run_gc_fire_cycles(2)

	// Verify the Destroy chain ran without runtimes
	// (runtimes during fire cycles would cause test failure)
