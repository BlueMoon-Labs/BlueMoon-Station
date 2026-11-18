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
	original.dna.nameless = TRUE
	original.dna.unique_enzymes = md5("Previously changed blood DNA")
	var/obj/machinery/clonepod/pod = allocate(/obj/machinery/clonepod)
	pod.get_clone_mind = CLONEPOD_NO_MIND
	TEST_ASSERT(pod.growclone(null, original.real_name, original.dna.uni_identity, null, null, original.dna.blood_type, original.dna.species, original.dna.features.Copy(), original.faction, unique_enzymes = original.dna.unique_enzymes, nameless = original.dna.nameless), "Clone creation succeeds")
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

/// Прозопагнозия и закрытое лицо скрывают личность независимо от видимого пола.
/datum/unit_test/examine_identity_and_gender/Run()
	var/mob/living/carbon/human/viewer = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human, get_step(viewer, EAST))
	target.gender = FEMALE
	target.real_name = "Examine Gender Test"
	target.jitteriness = 150
	ADD_TRAIT(viewer, TRAIT_PROSOPAGNOSIA, TRAIT_GENERIC)
	TEST_ASSERT_EQUAL(target.examine_shown_name(viewer), "Неизвестный", "Прозопагнозия скрывает имя.")
	TEST_ASSERT(target.examine_identity_hidden(viewer), "Прозопагнозия скрывает профиль личности.")
	TEST_ASSERT(findtext(jointext(target.examine(viewer, silent = TRUE), ""), "Она дрожит."), "Прозопагнозия сохраняет видимый женский род.")
	REMOVE_TRAIT(viewer, TRAIT_PROSOPAGNOSIA, TRAIT_GENERIC)

	var/obj/item/clothing/mask/gas/mask = allocate(/obj/item/clothing/mask/gas)
	target.equip_to_slot(mask, ITEM_SLOT_MASK)
	TEST_ASSERT_EQUAL(target.examine_shown_name(viewer), "Неизвестный", "Закрытое лицо без ID скрывает имя.")
	TEST_ASSERT(findtext(jointext(target.examine(viewer, silent = TRUE), ""), "Она дрожит."), "Одна маска не скрывает пол.")

	var/obj/item/clothing/suit/suit = allocate(/obj/item/clothing/suit)
	suit.flags_inv |= HIDEJUMPSUIT
	target.equip_to_slot(suit, ITEM_SLOT_OCLOTHING)
	TEST_ASSERT(findtext(jointext(target.examine(viewer, silent = TRUE), ""), "Он дрожит."), "Закрытые лицо и тело скрывают пол.")
	qdel(mask)
	TEST_ASSERT(findtext(jointext(target.examine(viewer, silent = TRUE), ""), "Она дрожит."), "Один закрывающий костюм не скрывает пол.")
	ADD_TRAIT(viewer, TRAIT_PROSOPAGNOSIA, TRAIT_GENERIC)
	TEST_ASSERT(findtext(jointext(target.examine(viewer, silent = TRUE), ""), "Он дрожит."), "При прозопагнозии закрывающий костюм скрывает пол даже с открытым лицом.")
	REMOVE_TRAIT(viewer, TRAIT_PROSOPAGNOSIA, TRAIT_GENERIC)
	TEST_ASSERT(findtext(jointext(target.examine(viewer, silent = TRUE), ""), "Она дрожит."), "Обычный наблюдатель по-прежнему различает пол по открытому лицу.")
