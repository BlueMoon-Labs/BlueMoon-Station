/// Нейминг работки должен сохранять номер, отпечатки, ДНК чувака без имени
/datum/unit_test/nameless_identity/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	human.real_name = "Test #12345"
	human.nameless = TRUE
	human.dna.nameless = TRUE
	human.dna.update_dna_identity()
	var/original_identity = human.dna.uni_identity
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	human.equip_to_slot(card, ITEM_SLOT_ID)
	var/datum/outfit/job/assistant/outfit = allocate(/datum/outfit/job/assistant)
	outfit.post_equip(human)
	TEST_ASSERT_EQUAL(human.real_name, "Assistant #12345", "Job naming preserves the character number")
	TEST_ASSERT_EQUAL(card.registered_name, human.real_name, "ID uses the final name")
	TEST_ASSERT_EQUAL(human.name, human.real_name, "Displayed name uses the final name")
	TEST_ASSERT_EQUAL(human.dna.real_name, human.real_name, "DNA stores the final name")
	TEST_ASSERT_EQUAL(human.dna.unique_enzymes, md5(human.real_name), "Blood DNA matches the final name")
	TEST_ASSERT_EQUAL(human.dna.uni_identity, original_identity, "Job naming preserves fingerprints")

/// Клонирование должно дублировать просканированного вместе с ДНК.
/datum/unit_test/clone_identity/Run()
	var/mob/living/carbon/human/original = allocate(/mob/living/carbon/human)
	original.real_name = "Assistant #12345"
	original.dna.update_dna_identity()
	original.dna.unique_enzymes = md5("Previously changed blood DNA")
	var/obj/machinery/clonepod/pod = allocate(/obj/machinery/clonepod)
	pod.get_clone_mind = CLONEPOD_NO_MIND
	TEST_ASSERT(pod.growclone(null, original.real_name, original.dna.uni_identity, null, null, original.dna.blood_type, original.dna.species, original.dna.features.Copy(), original.faction, unique_enzymes = original.dna.unique_enzymes, nameless = TRUE), "Clone creation succeeds")
	var/mob/living/carbon/human/clone = pod.occupant
	TEST_ASSERT_NOTNULL(clone, "Pod contains a clone")
	allocated += clone
	TEST_ASSERT_EQUAL(clone.real_name, original.real_name, "Clone keeps the original number")
	TEST_ASSERT_EQUAL(clone.name, original.real_name, "Clone display name matches")
	TEST_ASSERT_EQUAL(clone.dna.real_name, original.real_name, "Clone DNA stores the original name")
	TEST_ASSERT_EQUAL(clone.dna.unique_enzymes, original.dna.unique_enzymes, "Clone restores scanned blood DNA")
	TEST_ASSERT_EQUAL(clone.dna.uni_identity, original.dna.uni_identity, "Clone preserves fingerprints")
	TEST_ASSERT(clone.nameless && clone.dna.nameless, "Clone preserves nameless status")

/datum/unit_test/hardset_dna_name/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/original_identity = human.dna.uni_identity
	human.hardset_dna(newreal_name = "Assistant #54321")
	TEST_ASSERT_EQUAL(human.dna.real_name, human.real_name, "Hardset synchronizes the DNA name")
	TEST_ASSERT_EQUAL(human.dna.unique_enzymes, md5(human.real_name), "Hardset saves generated enzymes")
	TEST_ASSERT_EQUAL(human.dna.uni_identity, original_identity, "Changing only the name preserves fingerprints")
