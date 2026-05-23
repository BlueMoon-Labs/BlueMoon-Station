/// Тесты применения модификаций конечностей (протезов и ампутаций) из preferences.
/// Покрывает proc /datum/preferences/proc/apply_prefs_modified_limbs(), который раньше
/// был встроенным блоком в copy_to() под флагом initial_spawn и поэтому не срабатывал
/// при заходе на гост-роли/антаги через load_client_appearance.

/// Без модификаций все четыре конечности остаются на месте и не превращаются в робо.
/datum/unit_test/apply_prefs_modified_limbs_no_modifications

/datum/unit_test/apply_prefs_modified_limbs_no_modifications/Run()
	var/mob/living/carbon/human/H = allocate(/mob/living/carbon/human)
	var/datum/preferences/P = new
	P.modified_limbs = list()

	P.apply_prefs_modified_limbs(H)

	var/obj/item/bodypart/l_arm = H.get_bodypart(BODY_ZONE_L_ARM)
	var/obj/item/bodypart/r_arm = H.get_bodypart(BODY_ZONE_R_ARM)
	var/obj/item/bodypart/l_leg = H.get_bodypart(BODY_ZONE_L_LEG)
	var/obj/item/bodypart/r_leg = H.get_bodypart(BODY_ZONE_R_LEG)

	TEST_ASSERT_NOTNULL(l_arm, "Left arm should still exist with no modifications")
	TEST_ASSERT_NOTNULL(r_arm, "Right arm should still exist with no modifications")
	TEST_ASSERT_NOTNULL(l_leg, "Left leg should still exist with no modifications")
	TEST_ASSERT_NOTNULL(r_leg, "Right leg should still exist with no modifications")

	TEST_ASSERT(!l_arm.is_robotic_limb(FALSE), "Left arm should remain organic")
	TEST_ASSERT(!r_arm.is_robotic_limb(FALSE), "Right arm should remain organic")
	TEST_ASSERT(!l_leg.is_robotic_limb(FALSE), "Left leg should remain organic")
	TEST_ASSERT(!r_leg.is_robotic_limb(FALSE), "Right leg should remain organic")

/// LOADOUT_LIMB_PROSTHETIC превращает указанную конечность в робо.
/datum/unit_test/apply_prefs_modified_limbs_prosthetic

/datum/unit_test/apply_prefs_modified_limbs_prosthetic/Run()
	var/mob/living/carbon/human/H = allocate(/mob/living/carbon/human)
	var/datum/preferences/P = new
	P.modified_limbs = list()
	P.modified_limbs[BODY_ZONE_R_ARM] = list(LOADOUT_LIMB_PROSTHETIC, "prosthetic")

	P.apply_prefs_modified_limbs(H)

	var/obj/item/bodypart/r_arm = H.get_bodypart(BODY_ZONE_R_ARM)
	TEST_ASSERT_NOTNULL(r_arm, "Right arm should still exist after prosthetic application")
	TEST_ASSERT(r_arm.is_robotic_limb(FALSE), "Right arm should be robotic after LOADOUT_LIMB_PROSTHETIC")

	var/obj/item/bodypart/l_arm = H.get_bodypart(BODY_ZONE_L_ARM)
	TEST_ASSERT_NOTNULL(l_arm, "Left arm should still exist")
	TEST_ASSERT(!l_arm.is_robotic_limb(FALSE), "Left arm should remain organic when only the right is prosthetic")

/// LOADOUT_LIMB_AMPUTATED удаляет указанную конечность.
/datum/unit_test/apply_prefs_modified_limbs_amputated

/datum/unit_test/apply_prefs_modified_limbs_amputated/Run()
	var/mob/living/carbon/human/H = allocate(/mob/living/carbon/human)
	var/datum/preferences/P = new
	P.modified_limbs = list()
	P.modified_limbs[BODY_ZONE_L_LEG] = list(LOADOUT_LIMB_AMPUTATED)

	P.apply_prefs_modified_limbs(H)

	var/obj/item/bodypart/l_leg = H.get_bodypart(BODY_ZONE_L_LEG)
	TEST_ASSERT_NULL(l_leg, "Left leg should be missing after LOADOUT_LIMB_AMPUTATED")

	var/obj/item/bodypart/r_leg = H.get_bodypart(BODY_ZONE_R_LEG)
	TEST_ASSERT_NOTNULL(r_leg, "Right leg should still exist when only the left is amputated")

/// Смешанная конфигурация: протез на одной руке и ампутация на одной ноге одновременно.
/datum/unit_test/apply_prefs_modified_limbs_mixed

/datum/unit_test/apply_prefs_modified_limbs_mixed/Run()
	var/mob/living/carbon/human/H = allocate(/mob/living/carbon/human)
	var/datum/preferences/P = new
	P.modified_limbs = list()
	P.modified_limbs[BODY_ZONE_R_ARM] = list(LOADOUT_LIMB_PROSTHETIC, "prosthetic")
	P.modified_limbs[BODY_ZONE_L_LEG] = list(LOADOUT_LIMB_AMPUTATED)

	P.apply_prefs_modified_limbs(H)

	var/obj/item/bodypart/r_arm = H.get_bodypart(BODY_ZONE_R_ARM)
	TEST_ASSERT_NOTNULL(r_arm, "Right arm should exist as prosthetic")
	TEST_ASSERT(r_arm.is_robotic_limb(FALSE), "Right arm should be robotic")

	var/obj/item/bodypart/l_leg = H.get_bodypart(BODY_ZONE_L_LEG)
	TEST_ASSERT_NULL(l_leg, "Left leg should be missing (amputated)")

	var/obj/item/bodypart/l_arm = H.get_bodypart(BODY_ZONE_L_ARM)
	var/obj/item/bodypart/r_leg = H.get_bodypart(BODY_ZONE_R_LEG)
	TEST_ASSERT_NOTNULL(l_arm, "Left arm should remain present and untouched")
	TEST_ASSERT_NOTNULL(r_leg, "Right leg should remain present and untouched")
	TEST_ASSERT(!l_arm.is_robotic_limb(FALSE), "Left arm should remain organic")
	TEST_ASSERT(!r_leg.is_robotic_limb(FALSE), "Right leg should remain organic")

/// Существующие "посторонние" робо-конечности сбрасываются и заменяются плотскими по дефолту.
/// Это контракт оригинального блока в copy_to: "delete any existing prosthetic limbs to make
/// sure no remnant prosthetics are left over".
/datum/unit_test/apply_prefs_modified_limbs_strips_existing_robotic

/datum/unit_test/apply_prefs_modified_limbs_strips_existing_robotic/Run()
	var/mob/living/carbon/human/H = allocate(/mob/living/carbon/human)

	var/obj/item/bodypart/r_arm_orig = H.get_bodypart(BODY_ZONE_R_ARM)
	r_arm_orig.drop_limb()
	qdel(r_arm_orig)
	var/obj/item/bodypart/r_arm/robot/surplus/preexisting = new(H)
	preexisting.replace_limb(H)

	var/obj/item/bodypart/r_arm_check = H.get_bodypart(BODY_ZONE_R_ARM)
	TEST_ASSERT_NOTNULL(r_arm_check, "Robotic arm should be attached before test")
	TEST_ASSERT(r_arm_check.is_robotic_limb(FALSE), "Pre-existing arm should be robotic before applying prefs")

	var/datum/preferences/P = new
	P.modified_limbs = list()

	P.apply_prefs_modified_limbs(H)

	var/obj/item/bodypart/r_arm_after = H.get_bodypart(BODY_ZONE_R_ARM)
	TEST_ASSERT_NOTNULL(r_arm_after, "Right arm should be regenerated as flesh after empty prefs applied")
	TEST_ASSERT(!r_arm_after.is_robotic_limb(FALSE), "Right arm should be organic after applying empty prefs over a robotic one")

/// Сценарий из бага: пользователь зашёл на гост-роль через copy_to() БЕЗ initial_spawn.
/// До фикса блок с модификациями скипался. Теперь отдельный proc вызывается явно
/// через load_client_appearance, поэтому модификации должны применяться независимо от
/// флага initial_spawn в copy_to.
/datum/unit_test/apply_prefs_modified_limbs_works_outside_initial_spawn

/datum/unit_test/apply_prefs_modified_limbs_works_outside_initial_spawn/Run()
	var/mob/living/carbon/human/H = allocate(/mob/living/carbon/human)
	var/datum/preferences/P = new
	P.modified_limbs = list()
	P.modified_limbs[BODY_ZONE_L_ARM] = list(LOADOUT_LIMB_PROSTHETIC, "prosthetic")
	P.modified_limbs[BODY_ZONE_R_LEG] = list(LOADOUT_LIMB_AMPUTATED)

	// Эмулируем то, что load_client_appearance делает после copy_to: вызов proc напрямую.
	P.apply_prefs_modified_limbs(H)

	var/obj/item/bodypart/l_arm = H.get_bodypart(BODY_ZONE_L_ARM)
	TEST_ASSERT_NOTNULL(l_arm, "Left arm should exist as prosthetic on ghost-role spawn")
	TEST_ASSERT(l_arm.is_robotic_limb(FALSE), "Left arm should be robotic on ghost-role spawn")

	var/obj/item/bodypart/r_leg = H.get_bodypart(BODY_ZONE_R_LEG)
	TEST_ASSERT_NULL(r_leg, "Right leg should be amputated on ghost-role spawn")
