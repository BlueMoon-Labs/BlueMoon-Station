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

/// Уменьшение снимает урон, добавленный ростом, и не больше него: циклы роста не копят урон, а лечение в большом размере не даёт выгоды.
/datum/unit_test/resize_damage_returns_on_shrink

/datum/unit_test/resize_damage_returns_on_shrink/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
	var/obj/item/bodypart/chest/chest = patient.get_bodypart(BODY_ZONE_CHEST)
	patient.apply_damage(30, BRUTE, BODY_ZONE_CHEST, wound_bonus = CANT_WOUND)
	patient.apply_damage(5, TOX)

	for(var/i in 1 to 6)
		patient.update_size(2)
		TEST_ASSERT(chest.brute_dam > 30, "Предпосылка: рост раненого усиливает урон груди, а стало [chest.brute_dam]")
		patient.update_size(1)
	TEST_ASSERT(abs(chest.brute_dam - 30) < 0.02, "Шесть циклов роста и уменьшения оставили на груди [chest.brute_dam] урона вместо 30")
	TEST_ASSERT(abs(patient.getToxLoss() - 5) < 0.02, "Циклы роста оставили [patient.getToxLoss()] токсинов вместо 5")

	patient.update_size(2)
	var/grown_damage = chest.brute_dam
	patient.update_size(1.5)
	TEST_ASSERT(abs(chest.brute_dam - (grown_damage + 30) / 2) < 0.02, "Уменьшение на половину роста сняло не половину прибавки: [chest.brute_dam]")
	patient.update_size(1)
	TEST_ASSERT(abs(chest.brute_dam - 30) < 0.02, "Возврат к исходному размеру оставил [chest.brute_dam] урона вместо 30")

	patient.update_size(2)
	chest.heal_damage(10, 0)
	patient.update_size(1)
	TEST_ASSERT(abs(chest.brute_dam - 20) < 0.02, "Лечение 10 в большом размере дало [chest.brute_dam] урона, а без роста было бы 20")

	patient.update_size(2)
	chest.heal_damage(100, 0)
	patient.update_size(1)
	TEST_ASSERT_EQUAL(chest.brute_dam, 0, "Уменьшение после полного лечения увело урон в минус или вернуло его")
