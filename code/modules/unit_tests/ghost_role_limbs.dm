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

	// Свои глаза (ночное зрение) у пеплоходов, а не у обычных ящеров.
	var/datum/preferences/lizard_prefs = new
	lizard_prefs.pref_species = new /datum/species/lizard/ashwalker
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

/datum/unit_test/body_mod_implant_costs

/datum/unit_test/body_mod_implant_costs/Run()
	var/datum/preferences/P = new
	P.pref_species = new /datum/species/human
	var/list/expected_costs = list(
		"kiroshi_optics" = 1,
		"lynx_paws" = 1,
		"reinforced_tendons" = 1,
		"fortified_ankles" = 1,
		"corp_blood_pump" = 2,
		"corp_mantis_blades" = 3,
		"corp_monowire" = 3,
		"corp_hand_cannon" = 3,
		"corp_gorilla_arms" = 2,
		"subdermal_armor" = 2,
		"reinforced_skeleton" = 2,
		"nutriment_pump" = 1,
	)
	for(var/implant_id in expected_costs)
		var/list/option = P.body_mod_implant_option(implant_id)
		TEST_ASSERT_NOTNULL(option, "Implant [implant_id] should be listed in the modifications tab")
		TEST_ASSERT_EQUAL(option["cost"], expected_costs[implant_id], "Implant [implant_id] should cost the configured amount")
		TEST_ASSERT(option["organ"], "Implant [implant_id] should be applied as an organ implant")

	P.implant_mods = list(
		"kiroshi_optics" = TRUE,
		"lynx_paws" = TRUE,
		"corp_hand_cannon" = TRUE,
		"subdermal_armor" = TRUE,
		"reinforced_skeleton" = TRUE,
		"nutriment_pump" = TRUE,
		"corp_blood_pump" = TRUE,
	)
	TEST_ASSERT_EQUAL(P.quirk_balance(), -12, "Selected implants should be paid for with quirk points")

	// Импланты одной группы занимают одни и те же слоты: новый выбор снимает старый и возвращает очки.
	var/datum/preferences/conflict_prefs = new
	conflict_prefs.pref_species = new /datum/species/human
	conflict_prefs.implant_mods = list("corp_mantis_blades" = TRUE)
	TEST_ASSERT("corp_mantis_blades" in conflict_prefs.body_mod_implant_conflicts("corp_monowire"), "Arm implants should conflict with each other")
	TEST_ASSERT_EQUAL(conflict_prefs.body_mod_implant_swap_refund("corp_monowire"), 3, "Replacing an arm implant should refund its cost")
	TEST_ASSERT_EQUAL(conflict_prefs.quirk_balance(), -3, "A single selected implant should be charged once")

	conflict_prefs.implant_mods = list("corp_mantis_blades" = TRUE, "corp_monowire" = TRUE, "corp_hand_cannon" = TRUE)
	conflict_prefs.sanitize_body_mods()
	TEST_ASSERT_EQUAL(length(conflict_prefs.implant_mods), 1, "Only one arm implant should survive sanitizing")

	// Оптика Кироши занимает слот глаз и приоритетнее выбора органа в той же вкладке.
	conflict_prefs.implant_mods = list("kiroshi_optics" = TRUE)
	conflict_prefs.organ_mods = list(ORGAN_SLOT_EYES = "glow")
	conflict_prefs.sanitize_body_mods()
	TEST_ASSERT_NULL(conflict_prefs.organ_mods[ORGAN_SLOT_EYES], "Kiroshi optics should replace the selected eye organ")

	// Видам с мутантными глазами имплант глаз недоступен так же, как и замена органа глаз.
	conflict_prefs.pref_species = new /datum/species/lizard/ashwalker
	conflict_prefs.implant_mods = list("kiroshi_optics" = TRUE)
	conflict_prefs.sanitize_body_mods()
	TEST_ASSERT_NULL(conflict_prefs.implant_mods["kiroshi_optics"], "Kiroshi optics should be dropped for mutant-eyed species")

	var/mob/living/carbon/human/H = allocate(/mob/living/carbon/human)
	var/health_before = H.maxHealth
	P.apply_prefs_body_mods(H)

	TEST_ASSERT(istype(H.getorganslot(ORGAN_SLOT_EYES), /obj/item/organ/cyberimp/eyes/optical/kiroshi), "Kiroshi optics should be implanted")
	TEST_ASSERT(istype(H.getorganslot(ORGAN_SLOT_LEFT_LEG_AUG), /obj/item/organ/cyberimp/leg/lynx_paws), "Lynx paws should occupy the left leg")
	TEST_ASSERT(istype(H.getorganslot(ORGAN_SLOT_RIGHT_LEG_AUG), /obj/item/organ/cyberimp/leg/lynx_paws), "Lynx paws should occupy the right leg")
	TEST_ASSERT(istype(H.getorganslot(ORGAN_SLOT_RIGHT_ARM_AUG), /obj/item/organ/cyberimp/arm/handgun/sec_level), "Corporate hand cannon should be implanted")
	TEST_ASSERT(istype(H.getorganslot(ORGAN_SLOT_SUBDERMAL_ARMOR), /obj/item/organ/cyberimp/chest/subdermal_armor), "Subdermal armor should be implanted")
	TEST_ASSERT(istype(H.getorganslot(ORGAN_SLOT_REINFORCED_SKELETON), /obj/item/organ/cyberimp/chest/reinforced_skeleton), "Reinforced skeleton should be implanted")
	TEST_ASSERT(istype(H.getorganslot(ORGAN_SLOT_STOMACH_AID), /obj/item/organ/cyberimp/chest/nutriment), "Nutriment pump should be implanted")
	TEST_ASSERT(istype(H.getorganslot(INTERNAL_ORGAN_CHEM_IMPLANT), /obj/item/organ/cyberimp/chest/blood_pump/sec_level), "Corporate blood pump should be implanted")
	TEST_ASSERT_EQUAL(H.maxHealth, health_before + 25, "Reinforced skeleton should raise max health")

	qdel(conflict_prefs)
	qdel(P)
