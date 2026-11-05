/// Ножной имплант занимает оба слота ног, виден хирургии обеих ног и освобождает оба слота при извлечении.
/datum/unit_test/dual_leg_implant_slots/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
	var/obj/item/organ/cyberimp/leg/tendons/implant = allocate(/obj/item/organ/cyberimp/leg/tendons)

	TEST_ASSERT(implant.can_insert_into_zone(BODY_ZONE_L_LEG), "Имплант нельзя установить в левую ногу")
	TEST_ASSERT(implant.can_insert_into_zone(BODY_ZONE_R_LEG), "Имплант нельзя установить в правую ногу")
	TEST_ASSERT(implant.occupies_zone(BODY_ZONE_L_LEG), "Имплант не считается находящимся в левой ноге")
	TEST_ASSERT(implant.occupies_zone(BODY_ZONE_R_LEG), "Имплант не считается находящимся в правой ноге")

	implant.prepare_insert(patient, BODY_ZONE_L_LEG)
	implant.Insert(patient)

	TEST_ASSERT_EQUAL(patient.getorganslot(ORGAN_SLOT_LEFT_LEG_AUG), implant, "Имплант не занял левый слот ноги")
	TEST_ASSERT_EQUAL(patient.getorganslot(ORGAN_SLOT_RIGHT_LEG_AUG), implant, "Имплант не занял правый слот ноги")
	TEST_ASSERT(implant in patient.getorganszone(BODY_ZONE_L_LEG), "Имплант не виден хирургии левой ноги")
	TEST_ASSERT(implant in patient.getorganszone(BODY_ZONE_R_LEG), "Имплант не виден хирургии правой ноги")
	TEST_ASSERT_EQUAL(implant.zone, BODY_ZONE_L_LEG, "Имплант не перестроился под левую ногу")

	var/datum/component/jump/jump = patient.GetComponent(/datum/component/jump)
	TEST_ASSERT_NOTNULL(jump, "У пациента нет компонента прыжка")
	TEST_ASSERT_EQUAL(jump.air_jumps, 1, "Имплант не дал второй прыжок")
	TEST_ASSERT_EQUAL(jump.leap_distance, 3, "Имплант не увеличил длину прыжка")

	implant.Remove()
	TEST_ASSERT_NULL(patient.getorganslot(ORGAN_SLOT_LEFT_LEG_AUG), "Левый слот не освободился при извлечении")
	TEST_ASSERT_NULL(patient.getorganslot(ORGAN_SLOT_RIGHT_LEG_AUG), "Правый слот не освободился при извлечении")
	TEST_ASSERT_EQUAL(jump.air_jumps, 0, "Имплант не убрал второй прыжок")
	TEST_ASSERT_EQUAL(jump.leap_distance, 2, "Имплант не вернул обычную длину прыжка")

	// Пассивный имплант Lynx Paws даёт бесшумные шаги и снимает их при извлечении.
	var/obj/item/organ/cyberimp/leg/lynx_paws/paws = allocate(/obj/item/organ/cyberimp/leg/lynx_paws)
	paws.Insert(patient)
	TEST_ASSERT(HAS_TRAIT(patient, TRAIT_SILENT_STEP), "Lynx Paws не дал бесшумные шаги")
	paws.Remove()
	TEST_ASSERT(!HAS_TRAIT(patient, TRAIT_SILENT_STEP), "Lynx Paws не снял бесшумные шаги")

	// Обычный (не двойной) ножной имплант занимает только свою ногу.
	var/obj/item/organ/cyberimp/leg/single_test/single = allocate(/obj/item/organ/cyberimp/leg/single_test)
	single.prepare_insert(patient, BODY_ZONE_R_LEG)
	single.Insert(patient)
	TEST_ASSERT_EQUAL(patient.getorganslot(ORGAN_SLOT_RIGHT_LEG_AUG), single, "Обычный имплант не занял правую ногу")
	TEST_ASSERT_NULL(patient.getorganslot(ORGAN_SLOT_LEFT_LEG_AUG), "Обычный имплант занял вторую ногу")
	single.Remove()

/// Усиленные сухожилия действительно разрешают второй прыжок, находясь в воздухе.
/datum/unit_test/leg_implant_double_jump/Run()
	var/mob/living/carbon/human/jumper = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/component/jump/leap = jumper.GetComponent(/datum/component/jump)
	TEST_ASSERT_NOTNULL(leap, "У пациента нет компонента прыжка")

	leap.air_jumps = 1
	leap.jump_cooldown = 0.1 SECONDS
	leap.jump_duration = 0.5 SECONDS
	leap.do_jump(jumper)
	TEST_ASSERT(HAS_TRAIT(jumper, TRAIT_JUMPING), "Первый прыжок не начался")

	sleep(0.2 SECONDS)
	TEST_ASSERT(HAS_TRAIT(jumper, TRAIT_JUMPING), "Прыжок закончился раньше времени")
	leap.do_jump(jumper)
	TEST_ASSERT_EQUAL(leap.jumps_performed, 2, "Второй прыжок в воздухе не сработал")

	sleep(leap.jump_duration + 2)
	TEST_ASSERT(!HAS_TRAIT(jumper, TRAIT_JUMPING), "Двойной прыжок не завершился")
	TEST_ASSERT_EQUAL(leap.jumps_performed, 0, "Счётчик прыжков не сбросился")

/obj/item/organ/cyberimp/leg/single_test
	occupies_both_legs = FALSE
