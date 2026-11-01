/// Сотые доли урона после смены размера лечатся до нуля и не держат на медхуде отметку неполного здоровья.
/datum/unit_test/medhud_near_full_health

/datum/unit_test/medhud_near_full_health/proc/hud_state(mob/living/carbon/human/patient)
	var/image/holder = patient.hud_list[HEALTH_HUD]
	return holder.icon_state

/datum/unit_test/medhud_near_full_health/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
	patient.update_size(0.25)
	patient.apply_damage(0.02, BRUTE, BODY_ZONE_CHEST)
	patient.update_size(1)
	TEST_ASSERT(abs(patient.getBruteLoss() - 0.02) < 0.001, "Урон 0.02 после роста стал [patient.getBruteLoss()]")
	TEST_ASSERT_EQUAL(hud_state(patient), "", "Медхуд при 0.02 урона из [patient.maxHealth] показывает неполное здоровье")

	patient.adjustBruteLoss(-1)
	TEST_ASSERT_EQUAL(patient.getBruteLoss(), 0, "Лечение не довело остаток урона до нуля")
	TEST_ASSERT_EQUAL(patient.health, patient.maxHealth, "После лечения здоровье не полное")
	TEST_ASSERT_EQUAL(hud_state(patient), "", "Медхуд полностью здорового показывает неполное здоровье")

	patient.apply_damage(5, BRUTE, BODY_ZONE_CHEST)
	TEST_ASSERT_EQUAL(hud_state(patient), "hudhealth93.75", "5 урона из 100 должны оставаться видны на медхуде")
	patient.apply_damage(5, BRUTE, BODY_ZONE_CHEST)
	TEST_ASSERT_EQUAL(hud_state(patient), "hudhealth87.5", "10 урона из 100 показаны не той ступенью")

/// Рост раненого персонажа увеличивает урон конечностей, но не выше их max_damage в новом размере.
/datum/unit_test/resize_damage_scaling_bounded

/datum/unit_test/resize_damage_scaling_bounded/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
	patient.apply_damage(30, BRUTE, BODY_ZONE_CHEST)
	patient.apply_damage(3.37, BURN, BODY_ZONE_HEAD)
	patient.apply_damage(20, BRUTE, BODY_ZONE_L_ARM)
	for(var/i in 1 to 6)
		var/new_size = 1 + i * 0.17
		patient.update_size(new_size)
		for(var/obj/item/bodypart/limb as anything in patient.bodyparts)
			var/limb_damage = limb.brute_dam + limb.burn_dam
			TEST_ASSERT(limb_damage <= limb.max_damage + 0.02, "[limb.body_zone]: урон [limb_damage] выше max_damage [limb.max_damage] после роста до [new_size]")
			TEST_ASSERT(abs(limb.brute_dam - round(limb.brute_dam, DAMAGE_PRECISION)) < 0.001, "[limb.body_zone]: дробный остаток урона [limb.brute_dam] вне шага DAMAGE_PRECISION")
		patient.update_size(0.83)
	patient.update_size(1)

	for(var/i in 1 to 20)
		patient.adjustBruteLoss(-50)
		patient.adjustFireLoss(-50)
	TEST_ASSERT_EQUAL(patient.getBruteLoss(), 0, "Урон от роста не лечится до нуля")
	TEST_ASSERT_EQUAL(patient.getFireLoss(), 0, "Ожоги от роста не лечатся до нуля")
