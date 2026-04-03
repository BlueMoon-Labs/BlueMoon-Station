/// Test: Alert timeout timer is cancelled on Destroy, preventing strong ref from blocking GC
/datum/unit_test/gc_screen_alert_timeout_timer_cleanup
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_screen_alert_timeout_timer_cleanup/Run()
	configure_immediate_gc()
	var/mob/unit_test/gc_alert_dummy/dummy = allocate(/mob/unit_test/gc_alert_dummy)

	// notify_cloning has timeout = 30 SECONDS
	var/atom/movable/screen/alert/alert = dummy.throw_alert("test_timeout", /atom/movable/screen/alert/notify_cloning)
	TEST_ASSERT_NOTNULL(alert, "Timed alert was not created")
	TEST_ASSERT_NOTNULL(alert.timeout_id, "Timed alert did not store its timer ID")

	var/timerid = alert.timeout_id
	TEST_ASSERT_NOTNULL(SStimer.timer_id_dict[timerid], "Timer was not registered in SStimer")

	// Destroy alert before timeout fires
	dummy.clear_alert("test_timeout")

	// Timer should be cancelled
	TEST_ASSERT_NULL(SStimer.timer_id_dict[timerid], "Alert Destroy() did not cancel timeout timer")

	run_gc_fire_cycles(2)
	assert_no_gc_failures(/atom/movable/screen/alert/notify_cloning, "Timed alert early destroy")

/// Test: Alert Destroy properly scrubs all references without redundant reorganize_alerts
/datum/unit_test/gc_screen_alert_destroy_no_reorg
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_screen_alert_destroy_no_reorg/Run()
	configure_immediate_gc()
	var/mob/unit_test/gc_alert_dummy/dummy = allocate(/mob/unit_test/gc_alert_dummy)

	// Create two alerts — one will stay, one will be destroyed
	dummy.throw_alert("stay", /atom/movable/screen/alert/buckled)
	var/atom/movable/screen/alert/doomed = dummy.throw_alert("doomed", /atom/movable/screen/alert/weightless)
	TEST_ASSERT_NOTNULL(doomed, "Second alert was not created")
	TEST_ASSERT_EQUAL(length(dummy.alerts), 2, "Both alerts should exist")

	// Destroy just the doomed alert
	dummy.clear_alert("doomed")

	// Remaining alert should still be in alerts dict
	TEST_ASSERT_EQUAL(length(dummy.alerts), 1, "Only one alert should remain")
	TEST_ASSERT_NOTNULL(dummy.alerts["stay"], "Staying alert was incorrectly removed")

	// Doomed alert should be fully gone
	run_gc_fire_cycles(2)
	assert_no_gc_failures(/atom/movable/screen/alert/weightless, "Alert destroyed while sibling remains")

/// Test: Storage component destruction chain runs without screen GC failures
/datum/unit_test/gc_screen_storage_wipe_cleanup
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_screen_storage_wipe_cleanup/Run()
	configure_immediate_gc()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/item/storage/backpack/bag = allocate(/obj/item/storage/backpack, run_loc_floor_bottom_left)

	// Put bag in hand and verify storage component exists
	human.put_in_active_hand(bag, forced = TRUE)
	var/datum/component/storage/S = bag.GetComponent(/datum/component/storage)
	TEST_ASSERT_NOTNULL(S, "Backpack has no storage component")

	// Destroy the bag (triggers storage component Destroy -> close_all -> wipe_ui_objects)
	allocated -= bag
	qdel(bag)
	bag = null
	S = null

	run_gc_fire_cycles(2)
	assert_no_gc_failures(/atom/movable/screen/storage/boxes, "Storage boxes during bag destruction")
	assert_no_gc_failures(/atom/movable/screen/storage/close, "Storage close during bag destruction")
	assert_no_gc_failures(/atom/movable/screen/storage/continuous, "Storage continuous during bag destruction")
	assert_no_gc_failures(/atom/movable/screen/storage/item_holder, "Storage item_holder during bag destruction")

/// Test: Mob with storage in hand — screen objects GC cleanly when mob is destroyed
/datum/unit_test/gc_screen_storage_mob_destroy
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_screen_storage_mob_destroy/Run()
	configure_immediate_gc()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/item/storage/backpack/bag = allocate(/obj/item/storage/backpack, run_loc_floor_bottom_left)
	human.put_in_active_hand(bag, forced = TRUE)

	var/datum/component/storage/S = bag.GetComponent(/datum/component/storage)
	TEST_ASSERT_NOTNULL(S, "Backpack has no storage component")

	// Destroy the human — triggers hud teardown + storage cleanup chain
	allocated -= human
	allocated -= bag
	qdel(human)
	human = null
	bag = null
	S = null

	run_gc_fire_cycles(2)
	assert_no_gc_failures(/atom/movable/screen/storage/boxes, "Storage boxes during mob destruction")
	assert_no_gc_failures(/atom/movable/screen/storage/close, "Storage close during mob destruction")
	assert_no_gc_failures(/atom/movable/screen/storage/item_holder, "Storage item_holder during mob destruction")

/// Test: Multiple alerts (timed and untimed) on mob destroy all GC cleanly
/datum/unit_test/gc_screen_multi_alert_mob_destroy
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_screen_multi_alert_mob_destroy/Run()
	configure_immediate_gc()
	var/mob/unit_test/gc_alert_dummy/dummy = allocate(/mob/unit_test/gc_alert_dummy)

	// Mix of timed and untimed alerts
	dummy.throw_alert("buckled", /atom/movable/screen/alert/buckled)
	dummy.throw_alert("weightless", /atom/movable/screen/alert/weightless)
	dummy.throw_alert("fire", /atom/movable/screen/alert/fire)
	dummy.throw_alert("cloning", /atom/movable/screen/alert/notify_cloning) // has timeout
	TEST_ASSERT_EQUAL(length(dummy.alerts), 4, "All four alerts should be set")

	// Destroy the mob — all alerts must be cleaned up
	allocated -= dummy
	qdel(dummy)
	dummy = null

	run_gc_fire_cycles(2)
	assert_no_gc_failures(/atom/movable/screen/alert/buckled, "Buckled alert during multi-alert mob destroy")
	assert_no_gc_failures(/atom/movable/screen/alert/weightless, "Weightless alert during multi-alert mob destroy")
	assert_no_gc_failures(/atom/movable/screen/alert/fire, "Fire alert during multi-alert mob destroy")
	assert_no_gc_failures(/atom/movable/screen/alert/notify_cloning, "Cloning alert during multi-alert mob destroy")

/// Test: Storage modeswitch_action is cleaned up when storage component is destroyed
/datum/unit_test/gc_screen_storage_modeswitch_action_cleanup
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_screen_storage_modeswitch_action_cleanup/Run()
	configure_immediate_gc()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/item/storage/backpack/bag = allocate(/obj/item/storage/backpack, run_loc_floor_bottom_left)
	human.put_in_active_hand(bag, forced = TRUE)

	var/datum/component/storage/S = bag.GetComponent(/datum/component/storage)
	TEST_ASSERT_NOTNULL(S, "Backpack has no storage component")

	// The storage component creates a modeswitch_action when item is in inventory
	// It must be cleaned up on Destroy to avoid leaking backpack ref
	var/had_action = !isnull(S.modeswitch_action)

	// Destroy the bag — modeswitch_action must be qdel'd in storage/Destroy()
	allocated -= bag
	qdel(bag)
	bag = null
	S = null

	run_gc_fire_cycles(2)
	// If modeswitch_action existed and wasn't cleaned, the backpack will fail GC
	if(had_action)
		assert_no_gc_failures(/obj/item/storage/backpack, "Backpack with modeswitch_action")

/// Test: gc_alert_dummy mob GC — verify global lists are cleaned and mob GC's
/datum/unit_test/gc_screen_alert_dummy_mob_gc
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_screen_alert_dummy_mob_gc/Run()
	configure_immediate_gc()
	var/mob/unit_test/gc_alert_dummy/dummy = allocate(/mob/unit_test/gc_alert_dummy)

	// Verify mob is in global lists
	TEST_ASSERT(dummy in GLOB.mob_list, "Mob should be in GLOB.mob_list")

	allocated -= dummy
	qdel(dummy)

	// After qdel, mob should be removed from global lists
	TEST_ASSERT(!(dummy in GLOB.mob_list), "Mob still in GLOB.mob_list after qdel")
	TEST_ASSERT(!(dummy in GLOB.alive_mob_list), "Mob still in GLOB.alive_mob_list after qdel")
	TEST_ASSERT(!(dummy in GLOB.dead_mob_list), "Mob still in GLOB.dead_mob_list after qdel")

	dummy = null

	run_gc_fire_cycles(2)
	assert_no_gc_failures(/mob/unit_test/gc_alert_dummy, "Bare gc_alert_dummy mob")
