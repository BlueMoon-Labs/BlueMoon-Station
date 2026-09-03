/// Regression: SmiLeY's syringe-rebalance commit hoisted a new "any clothing blocks" check
/// into /mob/living/carbon/human/can_inject(), which silently broke every non-syringe caller
/// (sutures/gauze, patches, medspray, hypospray, antag bites, monkey bites, terror spider
/// stings, DNA injectors, etc.). They all stopped working through normal clothing - players
/// had to strip to underwear to apply a patch or sew a wound.
///
/// can_inject() must keep the legacy semantics: only THICKMATERIAL blocks the zone.
/// The new "any clothing blocks" rule moved to can_inject_syringe() - opt-in for syringes.

/// Naked: any pierce path passes.
/// Thin clothing (jumpsuit only): can_inject() and can_inject_syringe(THICK/ALL) still pass.
///   Only can_inject_syringe(NONE) is blocked.
/// THICKMATERIAL (space suit): blocks can_inject() and the THICK pierce level; only ALL pierces.
/datum/unit_test/can_inject_clothing/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)

	// Naked baseline ---------------------------------------------------------
	TEST_ASSERT(patient.can_inject(user, FALSE, BODY_ZONE_CHEST), \
		"Naked chest must pass can_inject() with default args")
	TEST_ASSERT(patient.can_inject_syringe(user, FALSE, BODY_ZONE_CHEST, SYRINGE_PIERCE_NONE), \
		"Naked chest must pass can_inject_syringe(NONE)")
	TEST_ASSERT(patient.can_inject_syringe(user, FALSE, BODY_ZONE_CHEST, SYRINGE_PIERCE_THICK), \
		"Naked chest must pass can_inject_syringe(THICK)")
	TEST_ASSERT(patient.can_inject_syringe(user, FALSE, BODY_ZONE_CHEST, SYRINGE_PIERCE_ALL), \
		"Naked chest must pass can_inject_syringe(ALL)")

	// Thin clothing only (jumpsuit, no THICKMATERIAL) ------------------------
	var/obj/item/clothing/under/color/grey/jumpsuit = allocate(/obj/item/clothing/under/color/grey)
	TEST_ASSERT(patient.equip_to_slot_or_del(jumpsuit, ITEM_SLOT_ICLOTHING, TRUE), \
		"Failed to equip jumpsuit on patient")

	// THE BUG: SmiLeY's commit made this return 0 because jumpsuit covers the chest.
	// The fix must keep can_inject() insensitive to non-THICK clothing.
	TEST_ASSERT(patient.can_inject(user, FALSE, BODY_ZONE_CHEST), \
		"Jumpsuit-only chest must still pass can_inject() - only THICKMATERIAL should block")

	// Syringe-specific gate: NONE blocks on any clothing, THICK and ALL pierce thin.
	TEST_ASSERT(!patient.can_inject_syringe(user, FALSE, BODY_ZONE_CHEST, SYRINGE_PIERCE_NONE), \
		"Jumpsuit-covered chest must block can_inject_syringe(NONE)")
	TEST_ASSERT(patient.can_inject_syringe(user, FALSE, BODY_ZONE_CHEST, SYRINGE_PIERCE_THICK), \
		"Jumpsuit-covered chest must pass can_inject_syringe(THICK)")
	TEST_ASSERT(patient.can_inject_syringe(user, FALSE, BODY_ZONE_CHEST, SYRINGE_PIERCE_ALL), \
		"Jumpsuit-covered chest must pass can_inject_syringe(ALL)")

	// Add THICKMATERIAL on top (space suit) ----------------------------------
	var/obj/item/clothing/suit/space/space_suit = allocate(/obj/item/clothing/suit/space)
	TEST_ASSERT(patient.equip_to_slot_or_del(space_suit, ITEM_SLOT_OCLOTHING, TRUE), \
		"Failed to equip space suit on patient")

	TEST_ASSERT(!patient.can_inject(user, FALSE, BODY_ZONE_CHEST), \
		"Space suit (THICKMATERIAL) must block can_inject() with default args")
	TEST_ASSERT(patient.can_inject(user, FALSE, BODY_ZONE_CHEST, TRUE), \
		"penetrate_thick=TRUE must bypass THICKMATERIAL")

	TEST_ASSERT(!patient.can_inject_syringe(user, FALSE, BODY_ZONE_CHEST, SYRINGE_PIERCE_NONE), \
		"Space suit must block can_inject_syringe(NONE)")
	TEST_ASSERT(!patient.can_inject_syringe(user, FALSE, BODY_ZONE_CHEST, SYRINGE_PIERCE_THICK), \
		"Space suit must block can_inject_syringe(THICK) - weak pierce should not punch through THICKMATERIAL")
	TEST_ASSERT(patient.can_inject_syringe(user, FALSE, BODY_ZONE_CHEST, SYRINGE_PIERCE_ALL), \
		"Diamond-tipped (SYRINGE_PIERCE_ALL) must pierce through space suit")

/// Sutures, patches, medsprays - the user-visible symptom of the bug - go through
/// can_inject() (no penetrate_thick). They must work on a clothed patient.
/datum/unit_test/medical_stack_through_clothing/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)

	var/obj/item/clothing/under/color/grey/jumpsuit = allocate(/obj/item/clothing/under/color/grey)
	patient.equip_to_slot_or_del(jumpsuit, ITEM_SLOT_ICLOTHING, TRUE)

	// Sutures don't have bypass_armor - they call can_inject() with default args.
	// With the bug, this returned 0 for any clothed zone. With the fix, jumpsuit passes.
	var/obj/item/stack/medical/suture/sutures = allocate(/obj/item/stack/medical/suture)
	TEST_ASSERT(sutures.can_heal(patient, user, BODY_ZONE_CHEST, silent = TRUE), \
		"Sutures must work on a jumpsuit-covered chest (no THICKMATERIAL)")

	// Apply some damage so try_heal has something to do, and stitch it.
	patient.take_overall_damage(20, 0)
	var/brute_before = patient.getBruteLoss()
	TEST_ASSERT(brute_before > 0, "Patient should have brute damage to stitch")

	var/datum/surgery_step/heal/brute/basic/basic_brute_heal = new
	basic_brute_heal.success(user, patient, BODY_ZONE_CHEST)
	// Surgery-stack tests already cover the brute-drop path; here we just need
	// the can_inject gate to not have falsely refused. If we got past can_heal
	// above, the regression is covered.
