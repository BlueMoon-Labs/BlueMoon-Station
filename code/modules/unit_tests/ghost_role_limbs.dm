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

// Настройки для сравнения административной выдачи и восстановления без стартовых вещей.
/datum/unit_test/proc/create_quirk_spawn_preferences()
	var/datum/preferences/prefs = new
	allocated += prefs
	prefs.pref_species = new /datum/species/human
	prefs.random_character(MALE)
	prefs.be_random_name = FALSE
	prefs.be_random_body = FALSE
	prefs.real_name = "Quirk Spawn Test"
	prefs.modified_limbs = list()
	prefs.all_quirks = list(/datum/quirk/family_heirloom::name, /datum/quirk/nearsighted::name, /datum/quirk/breathing_tube::name)
	return prefs

// «Персонаж из настроек» пересоздаёт квирки со всеми вещами и применяет конечности из настроек.
/datum/unit_test/admin_character_preferences_restore_spawn_effects/Run()
	var/mob/living/carbon/human/character = allocate(/mob/living/carbon/human)
	character.mind_initialize()
	character.equip_to_slot(new /obj/item/clothing/under/color/grey(character), ITEM_SLOT_ICLOTHING)
	var/datum/preferences/prefs = create_quirk_spawn_preferences()
	prefs.modified_limbs[BODY_ZONE_R_ARM] = list(LOADOUT_LIMB_PROSTHETIC, "prosthetic")
	prefs.modified_limbs[BODY_ZONE_L_LEG] = list(LOADOUT_LIMB_AMPUTATED)
	SSquirks.AssignQuirks(character, null, TRUE, TRUE, preferences_source = prefs, spawn_items = FALSE)
	var/datum/quirk/family_heirloom/old_quirk = character.get_quirk(/datum/quirk/family_heirloom)
	TEST_ASSERT_NOTNULL(old_quirk, "Контроль: квирк реликвии не назначен")
	TEST_ASSERT_NULL(old_quirk.heirloom, "Контроль: восстановление без вещей создало реликвию")

	TEST_ASSERT(prefs.apply_to_existing_character(character), "Административное применение настроек не выполнено")
	var/datum/quirk/family_heirloom/new_quirk = character.get_quirk(/datum/quirk/family_heirloom)
	TEST_ASSERT_NOTNULL(new_quirk, "Квирк реликвии потерян")
	TEST_ASSERT(new_quirk != old_quirk && QDELETED(old_quirk), "Сохранился квирк с ограничениями актуализатора")
	TEST_ASSERT(new_quirk.spawn_items && !QDELETED(new_quirk.heirloom), "Не выдана семейная реликвия")
	TEST_ASSERT(character.contains_atom(new_quirk.heirloom), "Реликвия не попала в инвентарь персонажа")
	TEST_ASSERT(istype(character.glasses, /obj/item/clothing/glasses/regular), "Не выданы стартовые очки")
	TEST_ASSERT(istype(character.getorganslot(ORGAN_SLOT_BREATHING_TUBE), /obj/item/organ/cyberimp/mouth/breathing_tube), "Не восстановлена горловая трубка")
	var/obj/item/bodypart/arm = character.get_bodypart(BODY_ZONE_R_ARM)
	TEST_ASSERT(arm?.is_robotic_limb(FALSE), "Не применён протез из настроек")
	TEST_ASSERT_NULL(character.get_bodypart(BODY_ZONE_L_LEG), "Не применена ампутация из настроек")
	TEST_ASSERT_EQUAL(length(character.roundstart_quirks), length(prefs.all_quirks), "Квирки продублировались")

	prefs.all_quirks = list(/datum/quirk/nearsighted::name)
	TEST_ASSERT(prefs.apply_to_existing_character(character), "Повторное применение настроек не выполнено")
	TEST_ASSERT_EQUAL(length(character.roundstart_quirks), 1, "Остались квирки предыдущего персонажа")
	TEST_ASSERT(character.has_quirk(/datum/quirk/nearsighted), "Не назначен квирк нового персонажа")

// Выдача квирков после выбора экипировки не подменяет имя, тело и уже выбранное снаряжение.
/datum/unit_test/admin_equipment_quirks_preserve_character/Run()
	var/mob/living/carbon/human/character = allocate(/mob/living/carbon/human)
	character.mind_initialize()
	var/original_name = character.real_name
	var/obj/item/clothing/under/uniform = new /obj/item/clothing/under/color/grey(character)
	character.equip_to_slot(uniform, ITEM_SLOT_ICLOTHING)
	var/datum/preferences/prefs = create_quirk_spawn_preferences()
	prefs.modified_limbs[BODY_ZONE_R_ARM] = list(LOADOUT_LIMB_PROSTHETIC, "prosthetic")
	TEST_ASSERT(prefs.apply_spawn_quirks(character), "Квирки после экипировки не применены")
	TEST_ASSERT_EQUAL(character.real_name, original_name, "Выдача квирков изменила имя")
	TEST_ASSERT_EQUAL(character.w_uniform, uniform, "Выдача квирков заменила снаряжение")
	var/obj/item/bodypart/arm = character.get_bodypart(BODY_ZONE_R_ARM)
	TEST_ASSERT(!arm.is_robotic_limb(FALSE), "Выдача квирков подменила конечности настройками другого тела")
	TEST_ASSERT(istype(character.glasses, /obj/item/clothing/glasses/regular), "Квирки после экипировки не выдали предметы")
	var/datum/quirk/family_heirloom/heirloom = character.get_quirk(/datum/quirk/family_heirloom)
	TEST_ASSERT(heirloom && !QDELETED(heirloom.heirloom), "Квирки после экипировки не выдали реликвию")

// Актуализатор по-прежнему не выдаёт ни стартовые предметы, ни горловую трубку.
/datum/unit_test/actualization_preferences_suppress_spawn_items/Run()
	var/mob/living/carbon/human/character = allocate(/mob/living/carbon/human)
	character.mind_initialize()
	var/datum/preferences/prefs = create_quirk_spawn_preferences()
	SSquirks.AssignQuirks(character, null, TRUE, TRUE, preferences_source = prefs, spawn_items = FALSE)
	TEST_ASSERT_EQUAL(length(character.roundstart_quirks), length(prefs.all_quirks), "Ограничение вещей удалило квирки")
	var/datum/quirk/family_heirloom/heirloom = character.get_quirk(/datum/quirk/family_heirloom)
	TEST_ASSERT_NOTNULL(heirloom, "Не назначен квирк семейной реликвии")
	TEST_ASSERT_NULL(heirloom.heirloom, "Актуализатор создал реликвию")
	TEST_ASSERT_NULL(character.glasses, "Актуализатор выдал очки")
	TEST_ASSERT_NULL(character.getorganslot(ORGAN_SLOT_BREATHING_TUBE), "Актуализатор восстановил горловую трубку")
