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

/// Оптика — обычная замена глаз: установка глаза поверх оптики выбрасывает её, а не удаляет.
/datum/unit_test/optics_are_eye_replacement/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
	var/obj/item/organ/old_eyes = patient.getorganslot(ORGAN_SLOT_EYES)
	TEST_ASSERT_NOTNULL(old_eyes, "У пациента не было глаз до операции")

	var/obj/item/organ/cyberimp/eyes/optical/kiroshi/optics = allocate(/obj/item/organ/cyberimp/eyes/optical/kiroshi)
	TEST_ASSERT(istype(optics, /obj/item/organ/eyes), "Оптика должна быть полноценным органом глаз")
	user.put_in_active_hand(optics)

	var/datum/surgery/organ_manipulation/soft/surgery = new(patient, BODY_ZONE_PRECISE_EYES, patient.get_bodypart(BODY_ZONE_HEAD))
	var/datum/surgery_step/manipulate_organs/step = new
	TEST_ASSERT_NOTEQUAL(step.preop(user, patient, BODY_ZONE_PRECISE_EYES, optics, surgery), -1, \
		"Хирургия отказалась ставить оптику вместо глаз")
	step.success(user, patient, BODY_ZONE_PRECISE_EYES, optics, surgery)
	TEST_ASSERT_EQUAL(patient.getorganslot(ORGAN_SLOT_EYES), optics, "Оптика не заменила глаза")
	TEST_ASSERT_NULL(old_eyes.owner, "Старые глаза остались внутри пациента")
	TEST_ASSERT(!QDELETED(old_eyes), "Старые глаза должны выбрасываться, а не удаляться")

	user.put_in_active_hand(old_eyes)
	TEST_ASSERT_NOTEQUAL(step.preop(user, patient, BODY_ZONE_PRECISE_EYES, old_eyes, surgery), -1, \
		"Хирургия отказалась вернуть глаз на место оптики")
	step.success(user, patient, BODY_ZONE_PRECISE_EYES, old_eyes, surgery)
	TEST_ASSERT_EQUAL(patient.getorganslot(ORGAN_SLOT_EYES), old_eyes, "Глаз не заменил оптику")
	TEST_ASSERT_NULL(optics.owner, "Оптика осталась внутри пациента после замены")
	TEST_ASSERT(!QDELETED(optics), "Оптика должна выбрасываться на пол, а не удаляться")
	TEST_ASSERT_EQUAL(get_turf(optics), get_turf(patient), "Оптика должна оказаться на полу под пациентом")

/// Militech-оптика сама даёт защиту глаз, потому что является органом глаз, а не отдельным имплантом.
/datum/unit_test/militech_optics_flash_protection/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
	var/obj/item/organ/cyberimp/eyes/optical/militech/optics = allocate(/obj/item/organ/cyberimp/eyes/optical/militech)
	optics.Insert(patient)
	TEST_ASSERT_EQUAL(patient.getorganslot(ORGAN_SLOT_EYES), optics, "Militech-оптика не заменила глаза")
	TEST_ASSERT_EQUAL(patient.get_eye_protection(), 3, "Militech-оптика должна давать защиту от вспышек")

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
