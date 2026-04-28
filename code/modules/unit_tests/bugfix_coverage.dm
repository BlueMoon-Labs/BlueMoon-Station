/// Tests for bugfixes: offering list iteration, inteq poster null guard, pregnancy signal registration, glow eyes null guards

// Test subtype that bypasses throw_alert (requires client) so we can test check_owner_in_range
/datum/status_effect/offering/unit_test
	id = "offering_unit_test"

/datum/status_effect/offering/unit_test/on_creation(mob/living/new_owner, obj/item/offer, give_alert_override)
	owner = new_owner
	offered_item = offer
	if(owner)
		LAZYADD(owner.status_effects, src)
	return TRUE

// Test: check_owner_in_range collects removals into a separate list before modifying possible_takers
// If the old code (modifying list during iteration) were present, this would runtime
/datum/unit_test/offering_remove_on_move/Run()
	var/mob/living/carbon/human/test_owner = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/taker1 = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/taker2 = allocate(/mob/living/carbon/human)
	var/obj/item/storage/toolbox/test_item = allocate(/obj/item/storage/toolbox)

	// Place owner and takers adjacent
	test_owner.forceMove(run_loc_floor_bottom_left)
	taker1.forceMove(get_step(run_loc_floor_bottom_left, EAST))
	taker2.forceMove(get_step(run_loc_floor_bottom_left, NORTH))

	test_owner.put_in_active_hand(test_item, forced = TRUE)

	// Create offering effect via test subtype that skips client-dependent alert logic
	test_owner.apply_status_effect(/datum/status_effect/offering/unit_test, test_item)
	var/datum/status_effect/offering/effect = test_owner.has_status_effect(/datum/status_effect/offering/unit_test)
	TEST_ASSERT_NOTNULL(effect, "Offering status effect was not applied")

	// Manually populate possible_takers (bypassing throw_alert)
	LAZYADD(effect.possible_takers, taker1)
	LAZYADD(effect.possible_takers, taker2)

	TEST_ASSERT_EQUAL(LAZYLEN(effect.possible_takers), 2, "Should have 2 takers registered")

	// Move takers far away so they are out of range
	taker1.forceMove(locate(run_loc_floor_bottom_left.x + 5, run_loc_floor_bottom_left.y + 5, run_loc_floor_bottom_left.z))
	taker2.forceMove(locate(run_loc_floor_bottom_left.x + 5, run_loc_floor_bottom_left.y + 4, run_loc_floor_bottom_left.z))

	// Call the fixed proc — old code would crash from list modification during iteration
	effect.check_owner_in_range(test_owner)

	// Both takers should have been removed
	TEST_ASSERT(!LAZYLEN(effect.possible_takers), "All out-of-range takers should have been removed")

// Test: InteQ poster process() handles null demotivator gracefully
/datum/unit_test/inteq_poster_null_demotivator/Run()
	var/obj/structure/sign/poster/contraband/inteq/poster = allocate(/obj/structure/sign/poster/contraband/inteq/inteq_recruitment)

	TEST_ASSERT_NOTNULL(poster.demotivator, "Poster should have demotivator after initialization")

	// Simulate wirecutter removing demotivator
	QDEL_NULL(poster.demotivator)

	// This should not runtime with the null guard fix
	poster.process()

	// If we got here without a runtime, the null guard works
	TEST_ASSERT_NULL(poster.demotivator, "Demotivator should still be null after process()")

// Test: Pregnancy component registers handle_damage on COMSIG_MOB_APPLY_DAMAGE, not COMSIG_MOB_DEATH
/datum/unit_test/pregnancy_damage_signal/Run()
	var/mob/living/carbon/human/carrier = allocate(/mob/living/carbon/human)

	// Set up organ for egg placement
	var/obj/item/organ/genital/womb/womb = allocate(/obj/item/organ/genital/womb)
	womb.Insert(carrier)
	TEST_ASSERT_EQUAL(womb.owner, carrier, "Womb organ should be owned by carrier after Insert")

	// Create egg inside the womb
	var/obj/item/oviposition_egg/egg = allocate(/obj/item/oviposition_egg)
	egg.forceMove(womb)

	// Add pregnancy component — carrier is the womb's owner
	egg.AddComponent(/datum/component/pregnancy, carrier, carrier)

	var/datum/component/pregnancy/preg = egg.GetComponent(/datum/component/pregnancy)
	TEST_ASSERT_NOTNULL(preg, "Pregnancy component was not added")
	TEST_ASSERT_NOTNULL(preg.carrier, "Pregnancy component has no carrier")

	// Verify COMSIG_MOB_APPLY_DAMAGE is registered on the carrier (the bug fix)
	// Before the fix, handle_damage was incorrectly registered on COMSIG_MOB_DEATH (duplicate)
	TEST_ASSERT_NOTNULL(carrier.comp_lookup, "Carrier has no signal registrations")
	TEST_ASSERT_NOTNULL(carrier.comp_lookup[COMSIG_MOB_APPLY_DAMAGE], "handle_damage should be registered on COMSIG_MOB_APPLY_DAMAGE")

// Test: update_visuals on High Luminosity Eyes tolerates a null entry in eye_lighting
// without runtiming at L.forceMove() — the reported runtime scenario.
/datum/unit_test/glow_eyes_update_visuals_null_safety/Run()
	var/mob/living/carbon/human/test_mob = allocate(/mob/living/carbon/human)
	var/obj/item/organ/eyes/robotic/glow/eyes = allocate(/obj/item/organ/eyes/robotic/glow)
	eyes.Insert(test_mob, TRUE)
	eyes.activate(silent = TRUE)

	TEST_ASSERT_NOTNULL(eyes.eye_lighting, "eye_lighting should exist after activation")
	TEST_ASSERT(LAZYLEN(eyes.eye_lighting) >= 2, "eye_lighting should have multiple entries after regenerate_light_effects")

	// Inject a null into eye_lighting to simulate a soft-deleted entry
	// (the scenario behind the reported runtime at L.forceMove())
	eyes.eye_lighting[2] = null

	// Without the null guard, this would runtime: "Cannot execute null.forceMove()"
	eyes.update_visuals(test_mob, test_mob.dir, EAST)

	// Valid entries should still be accessible
	TEST_ASSERT_NOTNULL(LAZYACCESS(eyes.eye_lighting, 1), "First entry should still be valid after update_visuals")

	eyes.deactivate(silent = TRUE)
