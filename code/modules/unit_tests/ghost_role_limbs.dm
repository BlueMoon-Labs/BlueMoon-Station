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

/// Протез у вида с роботизированными конечностями не даёт очков квирков, ампутация и протез человека - дают.
/datum/unit_test/limb_modification_points_by_species

/datum/unit_test/limb_modification_points_by_species/Run()
	var/datum/preferences/synth_prefs = new
	synth_prefs.pref_species = new /datum/species/mammal/synthetic
	var/datum/character_setup/synth_setup = new(synth_prefs)
	for(var/zone in list(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG))
		limb_act(synth_setup, zone, LOADOUT_LIMB_PROSTHETIC)
	TEST_ASSERT_EQUAL(length(synth_prefs.modified_limbs), 3, "Synthetic should still be able to pick cosmetic prosthetics")
	TEST_ASSERT_EQUAL(synth_prefs.quirk_balance(), 0, "Prosthetics on a robotic-limbed species should give no quirk points")
	limb_act(synth_setup, BODY_ZONE_R_LEG, LOADOUT_LIMB_AMPUTATED)
	TEST_ASSERT_EQUAL(synth_prefs.quirk_balance(), 2, "Amputation should still give points to a synthetic")
	TEST_ASSERT_EQUAL(synth_setup.build_modifications_data()["limbBonus"], 2, "Modifications tab should show the same limb bonus as the balance")

	// СЛАЙМОЛЮДЫ НЫЫЫА ЧЕРТИ ЕБАННЫЕ НЫЫЫААА
	var/datum/preferences/jelly_prefs = new
	jelly_prefs.pref_species = new /datum/species/jelly
	var/datum/character_setup/jelly_setup = new(jelly_prefs)
	limb_act(jelly_setup, BODY_ZONE_R_ARM, LOADOUT_LIMB_AMPUTATED)
	TEST_ASSERT_EQUAL(jelly_prefs.quirk_balance(), 0, "Amputation should give no points to a species that regrows limbs")
	TEST_ASSERT_EQUAL(jelly_setup.build_modifications_data()["limbBonus"], 0, "Modifications tab should show no amputation bonus for a regrowing species")

	var/datum/preferences/human_prefs = new
	human_prefs.pref_species = new /datum/species/human
	var/datum/character_setup/human_setup = new(human_prefs)
	limb_act(human_setup, BODY_ZONE_L_ARM, LOADOUT_LIMB_PROSTHETIC)
	TEST_ASSERT_EQUAL(human_prefs.quirk_balance(), 1, "Prosthetic on an organic species should give a quirk point")

	qdel(jelly_setup)
	qdel(jelly_prefs)
	qdel(synth_setup)
	qdel(synth_prefs)
	qdel(human_setup)
	qdel(human_prefs)

/datum/unit_test/limb_modification_points_by_species/proc/limb_act(datum/character_setup/setup, zone, kind)
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/datum/tgui/ui = allocate(/datum/tgui, user, setup, "CharacterSetup")
	ui.status = UI_INTERACTIVE
	usr = user
	setup.ui_act("set_limb", list("zone" = zone, "value" = kind), ui)
	usr = null

/datum/unit_test/body_mod_synthetic_glow_eyes

/datum/unit_test/body_mod_synthetic_glow_eyes/Run()
	var/datum/preferences/P = new
	P.pref_species = new /datum/species/ipc
	TEST_ASSERT(!P.body_mod_organ_locked(ORGAN_SLOT_EYES), "Synthetic eyes should be replaceable")
	TEST_ASSERT_NOTNULL(P.body_mod_organ_option(ORGAN_SLOT_EYES, "glow"), "Glow eyes should be available to synthetics")
	TEST_ASSERT_NULL(P.body_mod_organ_option(ORGAN_SLOT_EYES, "organic"), "Organic eyes should stay unavailable to synthetics")

	var/mob/living/carbon/human/H = allocate(/mob/living/carbon/human)
	H.set_species(/datum/species/ipc)

	var/datum/character_setup/S = new(P)
	var/list/mods = S.build_modifications_data()
	var/list/eye_options = list()
	var/eyes_locked = TRUE
	for(var/list/group in mods["organs"])
		if(group["slot"] != ORGAN_SLOT_EYES)
			continue
		eyes_locked = group["locked"]
		for(var/list/option in group["options"])
			eye_options += option["id"]
		break
	TEST_ASSERT(!eyes_locked, "Eyes group should be unlocked in the UI for synthetics")
	TEST_ASSERT("glow" in eye_options, "Glow option should be shown to synthetics")
	TEST_ASSERT(!("organic" in eye_options), "Organic option should be hidden from synthetics")

	P.organ_mods = list(ORGAN_SLOT_EYES = "glow")
	P.apply_prefs_body_mods(H)

	var/obj/item/organ/eyes/eyes = H.getorganslot(ORGAN_SLOT_EYES)
	TEST_ASSERT(istype(eyes, /obj/item/organ/eyes/robotic/toggled/glow), "Synthetic should receive glow eyes from preferences")

	var/datum/preferences/lizard_prefs = new
	lizard_prefs.pref_species = new /datum/species/lizard
	TEST_ASSERT(lizard_prefs.body_mod_organ_locked(ORGAN_SLOT_EYES), "Mutant-eyed organics should keep the eye group locked")

	qdel(S)
	qdel(lizard_prefs)
	qdel(P)

/datum/unit_test/copy_to_initial_spawn_applies_body_mods

/datum/unit_test/copy_to_initial_spawn_applies_body_mods/Run()
	var/datum/preferences/P = new
	P.pref_species = new /datum/species/human
	P.implant_mods = list("hide_backpack" = TRUE)
	P.modified_limbs = list(BODY_ZONE_R_ARM = list(LOADOUT_LIMB_PROSTHETIC, "prosthetic"))
	P.organ_mods = list(ORGAN_SLOT_EYES = "glow")

	var/mob/living/carbon/human/H = allocate(/mob/living/carbon/human)
	P.copy_to(H, icon_updates = FALSE, roundstart_checks = FALSE, initial_spawn = TRUE)

	TEST_ASSERT(locate(/obj/item/implant/hide_backpack) in H.implants, "Implant from preferences should be applied")
	TEST_ASSERT(istype(H.get_bodypart(BODY_ZONE_R_ARM), /obj/item/bodypart/r_arm/robot/surplus), "Prosthetic from preferences should be applied")
	TEST_ASSERT(istype(H.getorganslot(ORGAN_SLOT_EYES), /obj/item/organ/eyes/robotic/toggled/glow), "Organ modification from preferences should be applied")

	qdel(P)
