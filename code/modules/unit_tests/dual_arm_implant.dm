/// Имплант руки занимает оба слота, раскрывается в активированную руку и извлекается из любой.
/datum/unit_test/dual_arm_implant_slots/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
	var/obj/item/organ/cyberimp/arm/mantis_blade/implant = allocate(/obj/item/organ/cyberimp/arm/mantis_blade)
	implant.Insert(patient)

	TEST_ASSERT_EQUAL(patient.getorganslot(ORGAN_SLOT_LEFT_ARM_AUG), implant, "Имплант не занял левый слот руки")
	TEST_ASSERT_EQUAL(patient.getorganslot(ORGAN_SLOT_RIGHT_ARM_AUG), implant, "Имплант не занял правый слот руки")
	TEST_ASSERT(implant in patient.getorganszone(BODY_ZONE_L_ARM), "Имплант не виден хирургии левой руки")
	TEST_ASSERT(implant in patient.getorganszone(BODY_ZONE_R_ARM), "Имплант не виден хирургии правой руки")

	// Активация пустой левой руки раскрывает клинок в левую руку.
	patient.active_hand_index = 1
	TEST_ASSERT(patient.execute_mode(null, patient.active_hand_index), "Активация пустой левой руки не раскрыла имплант")
	TEST_ASSERT_NOTNULL(implant.holder, "Клинок не вышел из импланта")
	TEST_ASSERT_EQUAL(patient.get_held_index_of_item(implant.holder), 1, "Клинок раскрылся не в активированной левой руке")
	implant.Retract()

	// Активация пустой правой руки раскрывает клинок в правую руку.
	patient.active_hand_index = 2
	TEST_ASSERT(patient.execute_mode(null, patient.active_hand_index), "Активация пустой правой руки не раскрыла имплант")
	TEST_ASSERT_EQUAL(patient.get_held_index_of_item(implant.holder), 2, "Клинок раскрылся не в активированной правой руке")
	implant.Retract()

	// Извлечение из любой руки освобождает оба слота.
	implant.Remove()
	TEST_ASSERT_NULL(patient.getorganslot(ORGAN_SLOT_LEFT_ARM_AUG), "Левый слот не освободился при извлечении")
	TEST_ASSERT_NULL(patient.getorganslot(ORGAN_SLOT_RIGHT_ARM_AUG), "Правый слот не освободился при извлечении")

	// Обычные импланты рук (тулсет, пушки, щиты и т.п.) по-прежнему занимают один слот.
	var/mob/living/carbon/human/engineer = allocate(/mob/living/carbon/human)
	var/obj/item/organ/cyberimp/arm/toolset/toolset = allocate(/obj/item/organ/cyberimp/arm/toolset)
	toolset.Insert(engineer)
	var/other_arm_slot = (toolset.slot == ORGAN_SLOT_LEFT_ARM_AUG) ? ORGAN_SLOT_RIGHT_ARM_AUG : ORGAN_SLOT_LEFT_ARM_AUG
	TEST_ASSERT_EQUAL(engineer.getorganslot(toolset.slot), toolset, "Обычный имплант не занял свой слот руки")
	TEST_ASSERT_NULL(engineer.getorganslot(other_arm_slot), "Обычный имплант занял вторую руку")
	toolset.Remove()
