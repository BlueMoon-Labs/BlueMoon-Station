/// Unit tests for /datum/controller/subsystem/auto_cryo

/// Helper: enable autocryo config flags for testing, returns list of previous values to restore
/proc/auto_cryo_test_enable_config()
	var/list/prev = list()
	prev["autocryo_enabled"] = CONFIG_GET(flag/autocryo_enabled)
	prev["ghost_checking"] = CONFIG_GET(flag/ghost_checking)
	prev["autocryo_time_trigger"] = CONFIG_GET(number/autocryo_time_trigger)
	prev["ghost_check_time"] = CONFIG_GET(number/ghost_check_time)
	CONFIG_SET(flag/autocryo_enabled, TRUE)
	CONFIG_SET(flag/ghost_checking, TRUE)
	CONFIG_SET(number/autocryo_time_trigger, 600) // 1 minute for tests
	CONFIG_SET(number/ghost_check_time, 600)
	return prev

/// Helper: restore config after test
/proc/auto_cryo_test_restore_config(list/prev)
	CONFIG_SET(flag/autocryo_enabled, prev["autocryo_enabled"])
	CONFIG_SET(flag/ghost_checking, prev["ghost_checking"])
	CONFIG_SET(number/autocryo_time_trigger, prev["autocryo_time_trigger"])
	CONFIG_SET(number/ghost_check_time, prev["ghost_check_time"])

// ===== Test 1: SSD mob is sent to cryo when time has expired =====

/datum/unit_test/auto_cryo_ssd_expired

/datum/unit_test/auto_cryo_ssd_expired/Run()
	var/list/prev_config = auto_cryo_test_enable_config()
	var/list/prev_ssd_list = GLOB.ssd_mob_list.Copy()

	var/mob/living/carbon/human/ssd_human = allocate(/mob/living/carbon/human)
	ssd_human.lastclienttime = world.time - CONFIG_GET(number/autocryo_time_trigger) - 100
	GLOB.ssd_mob_list |= ssd_human

	// Clear currentrun so fire() rebuilds from ssd_mob_list
	SSauto_cryo.currentrun_cryo = list()
	SSauto_cryo.fire()

	TEST_ASSERT(QDELETED(ssd_human), "SSD mob with expired time should be deleted by auto cryo")
	TEST_ASSERT(!(ssd_human in GLOB.ssd_mob_list), "SSD mob should be removed from ssd_mob_list after cryo")

	// Cleanup
	GLOB.ssd_mob_list = prev_ssd_list
	SSauto_cryo.currentrun_cryo = list()
	auto_cryo_test_restore_config(prev_config)

// ===== Test 2: SSD mob is NOT sent to cryo when time has NOT expired =====

/datum/unit_test/auto_cryo_ssd_not_expired

/datum/unit_test/auto_cryo_ssd_not_expired/Run()
	var/list/prev_config = auto_cryo_test_enable_config()
	var/list/prev_ssd_list = GLOB.ssd_mob_list.Copy()

	var/mob/living/carbon/human/ssd_human = allocate(/mob/living/carbon/human)
	ssd_human.lastclienttime = world.time // Just disconnected
	GLOB.ssd_mob_list |= ssd_human

	SSauto_cryo.currentrun_cryo = list()
	SSauto_cryo.fire()

	TEST_ASSERT(!QDELETED(ssd_human), "SSD mob with unexpired time should NOT be deleted")
	TEST_ASSERT((ssd_human in GLOB.ssd_mob_list), "SSD mob should still be in ssd_mob_list")

	// Cleanup
	GLOB.ssd_mob_list = prev_ssd_list
	SSauto_cryo.currentrun_cryo = list()
	auto_cryo_test_restore_config(prev_config)

// ===== Test 3: Deleted mob in ssd_mob_list is skipped without runtime =====

/datum/unit_test/auto_cryo_deleted_mob_skipped

/datum/unit_test/auto_cryo_deleted_mob_skipped/Run()
	var/list/prev_config = auto_cryo_test_enable_config()
	var/list/prev_ssd_list = GLOB.ssd_mob_list.Copy()

	var/mob/living/carbon/human/doomed = new(run_loc_floor_bottom_left)
	doomed.lastclienttime = world.time - CONFIG_GET(number/autocryo_time_trigger) - 100
	GLOB.ssd_mob_list |= doomed

	// Delete mob BEFORE fire
	qdel(doomed)

	SSauto_cryo.currentrun_cryo = list()
	SSauto_cryo.fire()

	// If we got here without runtime, the test passes
	TEST_ASSERT(TRUE, "fire() should handle deleted mobs without runtime errors")

	// Cleanup
	GLOB.ssd_mob_list = prev_ssd_list
	SSauto_cryo.currentrun_cryo = list()
	auto_cryo_test_restore_config(prev_config)

// ===== Test 4: Ghost without client is deleted when time expired =====

/datum/unit_test/auto_cryo_ghost_expired

/datum/unit_test/auto_cryo_ghost_expired/Run()
	var/list/prev_config = auto_cryo_test_enable_config()

	var/mob/dead/observer/ghost = new(run_loc_floor_bottom_left)
	ghost.lastclienttime = world.time - CONFIG_GET(number/ghost_check_time) - 100

	TEST_ASSERT(!ghost.client, "Ghost should have no client")
	TEST_ASSERT((ghost in GLOB.dead_mob_list), "Ghost should be in dead_mob_list after creation")

	SSauto_cryo.currentrun_ghosts = list()
	SSauto_cryo.fire()

	TEST_ASSERT(QDELETED(ghost), "Ghost without client and expired time should be deleted")

	// Cleanup
	SSauto_cryo.currentrun_ghosts = list()
	auto_cryo_test_restore_config(prev_config)

// ===== Test 5: Ghost with unexpired time is NOT deleted =====

/datum/unit_test/auto_cryo_ghost_not_expired

/datum/unit_test/auto_cryo_ghost_not_expired/Run()
	var/list/prev_config = auto_cryo_test_enable_config()

	var/mob/dead/observer/ghost = new(run_loc_floor_bottom_left)
	ghost.lastclienttime = world.time // Fresh disconnect

	SSauto_cryo.currentrun_ghosts = list()
	SSauto_cryo.fire()

	TEST_ASSERT(!QDELETED(ghost), "Ghost with unexpired time should NOT be deleted")

	// Cleanup
	qdel(ghost)
	SSauto_cryo.currentrun_ghosts = list()
	auto_cryo_test_restore_config(prev_config)

// ===== Test 6: Empty lists — fire() completes without errors =====

/datum/unit_test/auto_cryo_empty_lists

/datum/unit_test/auto_cryo_empty_lists/Run()
	var/list/prev_config = auto_cryo_test_enable_config()
	var/list/prev_ssd_list = GLOB.ssd_mob_list.Copy()

	GLOB.ssd_mob_list = list()
	SSauto_cryo.currentrun_cryo = list()
	SSauto_cryo.currentrun_ghosts = list()

	SSauto_cryo.fire()

	// If we got here, it works
	TEST_ASSERT(TRUE, "fire() should handle empty lists without errors")

	// Cleanup
	GLOB.ssd_mob_list = prev_ssd_list
	auto_cryo_test_restore_config(prev_config)

// ===== Test 7: Batch processing — multiple SSD mobs all get processed =====

/datum/unit_test/auto_cryo_batch_processing
	priority = TEST_LONGER

/datum/unit_test/auto_cryo_batch_processing/Run()
	var/list/prev_config = auto_cryo_test_enable_config()
	var/list/prev_ssd_list = GLOB.ssd_mob_list.Copy()

	var/list/test_mobs = list()
	for(var/i in 1 to 10)
		var/mob/living/carbon/human/ssd_human = new(run_loc_floor_bottom_left)
		ssd_human.lastclienttime = world.time - CONFIG_GET(number/autocryo_time_trigger) - 100
		GLOB.ssd_mob_list |= ssd_human
		test_mobs += ssd_human

	// Fire multiple times to ensure all mobs get processed (yield between them)
	for(var/i in 1 to 15)
		SSauto_cryo.currentrun_cryo = list() // Force re-scan each time
		SSauto_cryo.fire()

	for(var/mob/living/carbon/human/test_mob as anything in test_mobs)
		TEST_ASSERT(QDELETED(test_mob), "All SSD mobs should be processed after multiple fire() calls")

	// Cleanup
	GLOB.ssd_mob_list = prev_ssd_list
	SSauto_cryo.currentrun_cryo = list()
	auto_cryo_test_restore_config(prev_config)

// ===== Test 8: Mob removed from ssd_mob_list between fires is skipped =====

/datum/unit_test/auto_cryo_mob_removed_between_fires

/datum/unit_test/auto_cryo_mob_removed_between_fires/Run()
	var/list/prev_config = auto_cryo_test_enable_config()
	var/list/prev_ssd_list = GLOB.ssd_mob_list.Copy()

	var/mob/living/carbon/human/reconnected = allocate(/mob/living/carbon/human)
	reconnected.lastclienttime = world.time - CONFIG_GET(number/autocryo_time_trigger) - 100
	GLOB.ssd_mob_list |= reconnected

	// Pre-populate currentrun_cryo manually (simulating mid-batch state)
	SSauto_cryo.currentrun_cryo = list(reconnected)

	// Simulate player reconnecting — remove from SSD list
	GLOB.ssd_mob_list -= reconnected

	SSauto_cryo.fire()

	TEST_ASSERT(!QDELETED(reconnected), "Mob removed from ssd_mob_list should NOT be sent to cryo")

	// Cleanup
	GLOB.ssd_mob_list = prev_ssd_list
	SSauto_cryo.currentrun_cryo = list()
	auto_cryo_test_restore_config(prev_config)

// ===== Test 9: Disabled config — cryo does not process =====

/datum/unit_test/auto_cryo_disabled_config

/datum/unit_test/auto_cryo_disabled_config/Run()
	var/list/prev_config = auto_cryo_test_enable_config()

	// Disable both features
	CONFIG_SET(flag/autocryo_enabled, FALSE)
	CONFIG_SET(flag/ghost_checking, FALSE)

	var/mob/living/carbon/human/ssd_human = allocate(/mob/living/carbon/human)
	ssd_human.lastclienttime = world.time - 100000
	GLOB.ssd_mob_list |= ssd_human

	var/mob/dead/observer/ghost = new(run_loc_floor_bottom_left)
	ghost.lastclienttime = world.time - 100000

	SSauto_cryo.currentrun_cryo = list()
	SSauto_cryo.currentrun_ghosts = list()
	SSauto_cryo.fire()

	TEST_ASSERT(!QDELETED(ssd_human), "SSD mob should NOT be processed when autocryo_enabled is FALSE")
	TEST_ASSERT(!QDELETED(ghost), "Ghost should NOT be processed when ghost_checking is FALSE")

	// Cleanup
	GLOB.ssd_mob_list -= ssd_human
	qdel(ghost)
	SSauto_cryo.currentrun_cryo = list()
	SSauto_cryo.currentrun_ghosts = list()
	auto_cryo_test_restore_config(prev_config)

// ===== Test 10: Deleted ghost in dead_mob_list is skipped without runtime =====

/datum/unit_test/auto_cryo_deleted_ghost_skipped

/datum/unit_test/auto_cryo_deleted_ghost_skipped/Run()
	var/list/prev_config = auto_cryo_test_enable_config()

	var/mob/dead/observer/ghost = new(run_loc_floor_bottom_left)
	ghost.lastclienttime = world.time - CONFIG_GET(number/ghost_check_time) - 100

	// Pre-fill currentrun with this ghost
	SSauto_cryo.currentrun_ghosts = list(ghost)

	// Delete ghost BEFORE fire
	qdel(ghost)

	SSauto_cryo.fire()

	// If we got here without runtime, the test passes
	TEST_ASSERT(TRUE, "fire() should handle deleted ghosts without runtime errors")

	// Cleanup
	SSauto_cryo.currentrun_ghosts = list()
	auto_cryo_test_restore_config(prev_config)
