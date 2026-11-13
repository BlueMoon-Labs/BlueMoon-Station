/// Хирургическая установка органа заменяет уже стоящий в слоте орган,
/// а не требует предварительно извлекать его.
/datum/unit_test/organ_manipulation_replaces_occupied_slot/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
	var/obj/item/organ/old_eyes = patient.getorganslot(ORGAN_SLOT_EYES)
	TEST_ASSERT_NOTNULL(old_eyes, "У пациента не было глаз до операции")

	var/obj/item/organ/cyberimp/eyes/optical/kiroshi/optics = allocate(/obj/item/organ/cyberimp/eyes/optical/kiroshi)
	user.put_in_active_hand(optics)

	var/datum/surgery/organ_manipulation/soft/surgery = new(patient, BODY_ZONE_PRECISE_EYES, patient.get_bodypart(BODY_ZONE_HEAD))
	var/datum/surgery_step/manipulate_organs/step = new
	TEST_ASSERT_NOTEQUAL(step.preop(user, patient, BODY_ZONE_PRECISE_EYES, optics, surgery), -1, \
		"Хирургия отказалась ставить оптику на место уже существующих глаз")

	step.success(user, patient, BODY_ZONE_PRECISE_EYES, optics, surgery)
	TEST_ASSERT_EQUAL(patient.getorganslot(ORGAN_SLOT_EYES), optics, "Оптика не заняла слот глаз")
	TEST_ASSERT_NULL(old_eyes.owner, "Старые глаза остались внутри пациента после замены")

/// Двурукий имплант можно поставить поверх видового органа (силового кабеля IPC):
/// старый орган извлекается и выбрасывается, оба слота рук переходят импланту.
/datum/unit_test/organ_manipulation_replaces_power_cord/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)

	var/obj/item/organ/cyberimp/arm/power_cord/cord = allocate(/obj/item/organ/cyberimp/arm/power_cord)
	cord.Insert(patient)
	TEST_ASSERT_EQUAL(patient.getorganslot(ORGAN_SLOT_LEFT_ARM_AUG), cord, "Силовой кабель не занял левый слот руки")

	var/obj/item/organ/cyberimp/arm/monostring/sec_level/monowire = allocate(/obj/item/organ/cyberimp/arm/monostring/sec_level)
	user.put_in_active_hand(monowire)

	var/datum/surgery/organ_manipulation/soft/surgery = new(patient, BODY_ZONE_R_ARM, patient.get_bodypart(BODY_ZONE_R_ARM))
	var/datum/surgery_step/manipulate_organs/step = new
	TEST_ASSERT_NOTEQUAL(step.preop(user, patient, BODY_ZONE_R_ARM, monowire, surgery), -1, \
		"Хирургия отказалась ставить двурукий имплант поверх силового кабеля")

	step.success(user, patient, BODY_ZONE_R_ARM, monowire, surgery)
	TEST_ASSERT_EQUAL(patient.getorganslot(ORGAN_SLOT_LEFT_ARM_AUG), monowire, "Имплант не занял левый слот руки")
	TEST_ASSERT_EQUAL(patient.getorganslot(ORGAN_SLOT_RIGHT_ARM_AUG), monowire, "Имплант не занял правый слот руки")
	TEST_ASSERT_NULL(cord.owner, "Силовой кабель остался внутри пациента после замены")

/// Орган, помеченный как незаменяемый, по-прежнему блокирует установку.
/datum/unit_test/organ_manipulation_blocks_unremovable_slot/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)

	var/obj/item/organ/old_eyes = patient.getorganslot(ORGAN_SLOT_EYES)
	TEST_ASSERT_NOTNULL(old_eyes, "У пациента не было глаз до операции")
	old_eyes.organ_flags |= ORGAN_UNREMOVABLE

	var/obj/item/organ/cyberimp/eyes/optical/kiroshi/optics = allocate(/obj/item/organ/cyberimp/eyes/optical/kiroshi)
	user.put_in_active_hand(optics)

	var/datum/surgery/organ_manipulation/soft/surgery = new(patient, BODY_ZONE_PRECISE_EYES, patient.get_bodypart(BODY_ZONE_HEAD))
	var/datum/surgery_step/manipulate_organs/step = new
	TEST_ASSERT_EQUAL(step.preop(user, patient, BODY_ZONE_PRECISE_EYES, optics, surgery), -1, \
		"Хирургия разрешила замену незаменяемого органа")
