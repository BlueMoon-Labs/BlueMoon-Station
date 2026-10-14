#define HK_TEST_BURN 40

/// Броня, неотрываемые конечности, защита от вспышек, запрет слотов и действия IPC у шасси HK.
/datum/unit_test/hk_chassis_basics

/datum/unit_test/hk_chassis_basics/Run()
	var/mob/living/carbon/human/droid = allocate(/mob/living/carbon/human)
	droid.set_species(/datum/species/ipc/hk/hk47)
	droid.apply_damage(HK_TEST_BURN, BURN, BODY_ZONE_CHEST, wound_bonus = CANT_WOUND)
	TEST_ASSERT_EQUAL(droid.getFireLoss(), HK_TEST_BURN * (100 - HK_ARMOR) / 100, "HK-47 armor reduces damage")
	TEST_ASSERT(HAS_TRAIT(droid, TRAIT_ROBOTIC_ORGANISM), "HK is robotic")
	TEST_ASSERT(!HAS_TRAIT(droid, TRAIT_EASYDISMEMBER), "HK lost IPC easy dismember")
	var/obj/item/bodypart/arm = droid.get_bodypart(BODY_ZONE_L_ARM)
	TEST_ASSERT(!arm.dismember(), "HK limbs can't be torn off")
	TEST_ASSERT_EQUAL(droid.get_bodypart(BODY_ZONE_L_ARM), arm, "HK arm stays attached")
	TEST_ASSERT(!droid.flash_act(1), "HK eyes protect from flashes")
	TEST_ASSERT(!(locate(/datum/action/innate/ipc_designation) in droid.actions), "HK can't rename itself")
	TEST_ASSERT(!(locate(/datum/action/innate/monitor_change) in droid.actions), "HK has no IPC screen")

	var/obj/item/clothing/under/color/grey/jumpsuit = allocate(/obj/item/clothing/under/color/grey)
	TEST_ASSERT(!droid.equip_to_slot_if_possible(jumpsuit, ITEM_SLOT_ICLOTHING, disable_warning = TRUE), "HK can't wear a jumpsuit")
	var/obj/item/clothing/suit/armor/vest/vest = allocate(/obj/item/clothing/suit/armor/vest)
	TEST_ASSERT(!droid.equip_to_slot_if_possible(vest, ITEM_SLOT_OCLOTHING, disable_warning = TRUE), "HK can't wear an armor vest")
	var/obj/item/clothing/head/helmet/helmet = allocate(/obj/item/clothing/head/helmet)
	TEST_ASSERT(!droid.equip_to_slot_if_possible(helmet, ITEM_SLOT_HEAD, disable_warning = TRUE), "HK can't wear a helmet")
	var/obj/item/storage/belt/utility/belt = allocate(/obj/item/storage/belt/utility)
	TEST_ASSERT(droid.equip_to_slot_if_possible(belt, ITEM_SLOT_BELT, disable_warning = TRUE), "HK can wear a belt")
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	TEST_ASSERT(droid.equip_to_slot_if_possible(card, ITEM_SLOT_ID, disable_warning = TRUE), "HK can wear an ID")

#define HK_VACUUM_TEST_TICKS 60
#define HK_HOT_GAS_TEMPERATURE (T0C + 300)

/// Шасси HK держит вакуум без перегрева, обычный IPC там же греется, а горячий газ HK греет по-прежнему.
/datum/unit_test/hk_vacuum_rated
	var/list/changed_turfs = list()
	var/datum/gas_mixture/heated_air
	var/heated_air_temperature

/datum/unit_test/hk_vacuum_rated/Run()
	var/turf/droid_spot = make_space(get_step(run_loc_floor_bottom_left, NORTH))
	var/turf/control_spot = make_space(get_step(run_loc_floor_bottom_left, EAST))
	var/mob/living/carbon/human/droid = allocate(/mob/living/carbon/human, droid_spot)
	droid.set_species(/datum/species/ipc/hk/hk47)
	var/mob/living/carbon/human/control = allocate(/mob/living/carbon/human, control_spot)
	control.set_species(/datum/species/ipc)
	for(var/tick in 1 to HK_VACUUM_TEST_TICKS)
		droid.handle_environment(droid_spot.return_air())
		control.handle_environment(control_spot.return_air())
	TEST_ASSERT(control.bodytemperature > BODYTEMP_HEAT_DAMAGE_LIMIT, "plain IPC stayed at [control.bodytemperature]K in vacuum")
	TEST_ASSERT(droid.bodytemperature <= BODYTEMP_NORMAL, "HK overheated to [droid.bodytemperature]K in vacuum")
	TEST_ASSERT_EQUAL(droid.getToxLoss(), 0, "HK took heat damage in vacuum")
	TEST_ASSERT_EQUAL(droid.getFireLoss(), 0, "HK took cold damage in vacuum")

	var/turf/open/hot_spot = run_loc_floor_bottom_left
	heated_air = hot_spot.return_air()
	heated_air_temperature = heated_air.return_temperature()
	heated_air.set_temperature(HK_HOT_GAS_TEMPERATURE)
	droid.forceMove(hot_spot)
	for(var/tick in 1 to HK_VACUUM_TEST_TICKS)
		droid.handle_environment(heated_air)
	TEST_ASSERT(droid.bodytemperature > BODYTEMP_HEAT_DAMAGE_LIMIT, "hot gas left HK at [droid.bodytemperature]K")

/datum/unit_test/hk_vacuum_rated/Destroy()
	heated_air?.set_temperature(heated_air_temperature)
	for(var/turf/spot as anything in changed_turfs)
		spot.ChangeTurf(changed_turfs[spot])
	return ..()

/datum/unit_test/hk_vacuum_rated/proc/make_space(turf/spot)
	changed_turfs[spot] = spot.type
	return spot.ChangeTurf(/turf/open/space/basic)

#undef HK_HOT_GAS_TEMPERATURE
#undef HK_VACUUM_TEST_TICKS

/// HK-50 слабее по броне, у моделей свои id, магическое зеркало их не предлагает.
/datum/unit_test/hk_chassis_models

/datum/unit_test/hk_chassis_models/Run()
	var/mob/living/carbon/human/droid = allocate(/mob/living/carbon/human)
	droid.set_species(/datum/species/ipc/hk/hk50)
	var/datum/species/ipc/hk/species = droid.dna.species
	TEST_ASSERT_EQUAL(species.hk_model, HK_MODEL_50, "HK-50 model")
	droid.apply_damage(HK_TEST_BURN, BURN, BODY_ZONE_CHEST, wound_bonus = CANT_WOUND)
	TEST_ASSERT_EQUAL(droid.getFireLoss(), HK_TEST_BURN * (100 - HK50_ARMOR) / 100, "HK-50 armor reduces damage less")
	droid.set_species(/datum/species/ipc/hk/hk51)
	species = droid.dna.species
	TEST_ASSERT_EQUAL(species.hk_model, HK_MODEL_51, "HK-51 model")
	TEST_ASSERT_EQUAL(GLOB.species_list[SPECIES_HK47], /datum/species/ipc/hk/hk47, "HK-47 has its own species id")
	TEST_ASSERT_EQUAL(GLOB.species_list[SPECIES_HK50], /datum/species/ipc/hk/hk50, "HK-50 has its own species id")
	TEST_ASSERT_EQUAL(GLOB.species_list[SPECIES_HK51], /datum/species/ipc/hk/hk51, "HK-51 has its own species id")
	var/obj/structure/mirror/magic/mirror = allocate(/obj/structure/mirror/magic)
	for(var/species_id in list(SPECIES_HK, SPECIES_HK47, SPECIES_HK50, SPECIES_HK51))
		TEST_ASSERT(!(species_id in mirror.choosable_races), "magic mirror doesn't offer [species_id]")

/// Префикс речи по последнему знаку, без дубля; после смены вида речь не трогается.
/datum/unit_test/hk_speech_prefix

/datum/unit_test/hk_speech_prefix/Run()
	var/datum/species/ipc/hk/hk47/species = new
	TEST_ASSERT_EQUAL(species.hk_speech_prefix("цель найдена"), "[HK_PREFIX_STATEMENT] цель найдена", "statement")
	TEST_ASSERT_EQUAL(species.hk_speech_prefix("где хозяин?"), "[HK_PREFIX_QUERY] где хозяин?", "query")
	TEST_ASSERT_EQUAL(species.hk_speech_prefix("огонь!"), "[HK_PREFIX_EXCLAMATION] огонь!", "exclamation")
	TEST_ASSERT_EQUAL(species.hk_speech_prefix("[HK_PREFIX_QUERY] где хозяин?"), "[HK_PREFIX_QUERY] где хозяин?", "no duplicate prefix")
	TEST_ASSERT_EQUAL(species.hk_speech_prefix(""), "", "empty message untouched")
	qdel(species)

	var/mob/living/carbon/human/droid = allocate(/mob/living/carbon/human)
	droid.set_species(/datum/species/ipc/hk/hk47)
	TEST_ASSERT_EQUAL(droid.say_mod("Цель найдена"), "states", "HK vocabulator states")
	droid.say("Цель найдена", language = /datum/language/common, ignore_spam = TRUE)
	TEST_ASSERT_EQUAL(droid.last_words, "[HK_PREFIX_STATEMENT] Цель найдена", "HK speech gets a prefix")
	droid.set_species(/datum/species/human)
	droid.say("Проверка связи", language = /datum/language/common, ignore_spam = TRUE)
	TEST_ASSERT_EQUAL(droid.last_words, "Проверка связи", "former HK speaks without a prefix")

#undef HK_TEST_BURN

/// Конечности HK-47 на теле рисуются стейтами модели с листа HK и ничем не перекрашиваются.
/datum/unit_test/hk_chassis_limb_sprites

/datum/unit_test/hk_chassis_limb_sprites/Run()
	var/hk_icon = 'modular_bluemoon/icons/mob/human/hk_droid.dmi'
	var/list/states = icon_states(hk_icon)
	var/mob/living/carbon/human/droid = allocate(/mob/living/carbon/human)
	droid.dna.features["mcolor"] = "ff00ff"
	droid.skin_tone = "african1"
	droid.set_species(/datum/species/ipc/hk/hk47)
	var/drawn_chest = FALSE
	for(var/image/limb in droid.overlays_standing[BODYPARTS_LAYER])
		TEST_ASSERT_EQUAL(limb.icon, hk_icon, "limb [limb.icon_state] is drawn from the HK sheet")
		TEST_ASSERT(limb.icon_state in states, "limb state [limb.icon_state] exists in the HK sheet")
		TEST_ASSERT(!limb.color, "limb [limb.icon_state] is tinted [limb.color]")
		if(limb.icon_state == "[HK_MODEL_47]_chest")
			drawn_chest = TRUE
	TEST_ASSERT(drawn_chest, "HK-47 chest is drawn as [HK_MODEL_47]_chest")

/// Каждой модели хватает стейтов, глаза светятся у живого и гаснут у мёртвого.
/datum/unit_test/hk_chassis_render

/datum/unit_test/hk_chassis_render/Run()
	var/list/states = icon_states('modular_bluemoon/icons/mob/human/hk_droid.dmi')
	for(var/model in list(HK_MODEL_47, HK_MODEL_50, HK_MODEL_51))
		for(var/part in list("head", "chest", "r_arm", "l_arm", "r_hand", "r_hand_behind", "l_hand", "l_hand_behind", "r_leg_front", "r_leg_behind", "l_leg_front", "l_leg_behind", "eyes"))
			TEST_ASSERT("[model]_[part]" in states, "missing state [model]_[part]")
	var/mob/living/carbon/human/droid = allocate(/mob/living/carbon/human)
	droid.set_species(/datum/species/ipc/hk/hk47)
	var/datum/species/ipc/hk/species = droid.dna.species
	TEST_ASSERT_EQUAL(length(species.hk_eye_overlays(droid)), 2, "living HK: eyes + emissive")
	var/datum/species/ipc/hk/abstract_chassis = new
	TEST_ASSERT_EQUAL(length(abstract_chassis.hk_eye_overlays(droid)), 0, "abstract HK has no eyes")
	qdel(abstract_chassis)
	droid.death()
	TEST_ASSERT_EQUAL(length(species.hk_eye_overlays(droid)), 0, "dead HK: eyes off")

/// Кисти каждой модели HK во всех ракурсах лежат в рамке кистей человека, под которую нарисованы инхенды.
/datum/unit_test/hk_hands_in_human_hand_box

/datum/unit_test/hk_hands_in_human_hand_box/Run()
	for(var/dir in GLOB.cardinals)
		for(var/part in list("r_hand", "l_hand", "r_hand_behind", "l_hand_behind"))
			var/list/human_box = opaque_box('icons/mob/human_parts_greyscale.dmi', "human_[part]", dir)
			for(var/model in list(HK_MODEL_47, HK_MODEL_50, HK_MODEL_51))
				var/list/hk_box = opaque_box('modular_bluemoon/icons/mob/human/hk_droid.dmi', "[model]_[part]", dir)
				if(!hk_box)
					continue
				var/inside = human_box && hk_box[1] >= human_box[1] && hk_box[2] >= human_box[2] && hk_box[3] <= human_box[3] && hk_box[4] <= human_box[4]
				TEST_ASSERT(inside, "[model]_[part] [dir2text(dir)]: hand [hk_box.Join(",")] is outside the human hand box [human_box?.Join(",")]")

/// Границы непрозрачных пикселей стейта в одном направлении: list(x1, y1, x2, y2) или null.
/datum/unit_test/hk_hands_in_human_hand_box/proc/opaque_box(file, state, dir)
	var/icon/sprite = icon(file, state, dir)
	var/list/box
	for(var/x in 1 to sprite.Width())
		for(var/y in 1 to sprite.Height())
			if(!sprite.GetPixel(x, y))
				continue
			if(!box)
				box = list(x, y, x, y)
				continue
			box[1] = min(box[1], x)
			box[2] = min(box[2], y)
			box[3] = max(box[3], x)
			box[4] = max(box[4], y)
	return box

/// Глаза HK-51 рисуются на теле со свечением и светом, в крите мигают без лишних перерисовок, у мёртвого гаснут.
/datum/unit_test/hk_eye_glow_on_body

/datum/unit_test/hk_eye_glow_on_body/Run()
	var/mob/living/carbon/human/droid = allocate(/mob/living/carbon/human)
	droid.set_species(/datum/species/ipc/hk/hk51)
	var/datum/species/ipc/hk/species = droid.dna.species
	TEST_ASSERT_EQUAL(drawn_eyes(droid), 2, "living HK draws its eyes")
	TEST_ASSERT_EQUAL(drawn_eyes(droid, glowing = TRUE), 1, "HK eyes glow")
	var/obj/effect/dummy/lighting_obj/moblight/hk_eyes/glow = locate() in droid
	TEST_ASSERT(glow?.light_on, "HK eyes cast light")
	var/list/body_overlays = droid.overlays_standing[BODY_LAYER]
	species.spec_life(droid)
	TEST_ASSERT(droid.overlays_standing[BODY_LAYER] == body_overlays, "healthy HK isn't redrawn every tick")

	var/obj/item/bodypart/chest = droid.get_bodypart(BODY_ZONE_CHEST)
	chest.receive_damage(droid.health - droid.crit_threshold + 10, wound_bonus = CANT_WOUND)
	TEST_ASSERT(droid.InCritical(), "HK is in crit: health [droid.health], stat [droid.stat]")
	body_overlays = droid.overlays_standing[BODY_LAYER]
	for(var/tick in 1 to HK_EYE_BLINK_TICKS - 1)
		species.spec_life(droid)
		TEST_ASSERT(droid.overlays_standing[BODY_LAYER] == body_overlays, "no redraw before the blink, tick [tick]")
	species.spec_life(droid)
	TEST_ASSERT_EQUAL(drawn_eyes(droid), 0, "eyes blink off in crit")
	TEST_ASSERT(!glow.light_on, "eye light blinks off in crit")
	for(var/tick in 1 to HK_EYE_BLINK_TICKS)
		species.spec_life(droid)
	TEST_ASSERT_EQUAL(drawn_eyes(droid), 2, "eyes blink back on in crit")
	for(var/tick in 1 to HK_EYE_BLINK_TICKS)
		species.spec_life(droid)
	TEST_ASSERT_EQUAL(drawn_eyes(droid), 0, "eyes blink off again")

	chest.heal_damage(chest.brute_dam, 0, 0, only_organic = FALSE)
	TEST_ASSERT(!droid.InCritical(), "HK left crit: health [droid.health], stat [droid.stat]")
	species.spec_life(droid)
	TEST_ASSERT_EQUAL(drawn_eyes(droid), 2, "eyes light up after leaving crit")

	droid.death()
	TEST_ASSERT_EQUAL(drawn_eyes(droid), 0, "dead HK has dark eyes")
	TEST_ASSERT(!glow.light_on, "dead HK casts no eye light")
	droid.set_species(/datum/species/human)
	TEST_ASSERT(QDELETED(glow), "former HK keeps no eye light")

/datum/unit_test/hk_eye_glow_on_body/proc/drawn_eyes(mob/living/carbon/human/droid, glowing = FALSE)
	. = 0
	for(var/mutable_appearance/overlay in droid.overlays_standing[BODY_LAYER])
		if(overlay.icon_state != "[HK_MODEL_51]_eyes")
			continue
		if(!glowing || PLANE_TO_TRUE(overlay.plane) == EMISSIVE_PLANE)
			.++

/// Перепрошивка перекрашивает глаза HK-47 и HK-50, а у HK-51 они остаются жёлтыми; сброс хозяина без нового глаза не трогает.
/datum/unit_test/hk_reprogrammed_eyes

/datum/unit_test/hk_reprogrammed_eyes/Run()
	var/mob/living/carbon/human/surgeon = allocate_minded_human()
	for(var/species_type in list(/datum/species/ipc/hk/hk47, /datum/species/ipc/hk/hk50, /datum/species/ipc/hk/hk51))
		var/mob/living/carbon/human/droid = allocate(/mob/living/carbon/human)
		droid.set_species(species_type)
		var/datum/species/ipc/hk/species = droid.dna.species
		var/list/eye_overlays = species.hk_eye_overlays(droid)
		var/mutable_appearance/eyes = eye_overlays[1]
		TEST_ASSERT_NULL(eyes.color, "[species.hk_model] eyes keep their factory color")
		var/datum/component/hk_loyalty/loyalty = droid.AddComponent(/datum/component/hk_loyalty)
		loyalty.set_master(null)
		TEST_ASSERT(!species.eyes_reprogrammed, "a reset without a new master leaves [species.hk_model] eyes alone")
		loyalty.set_master(surgeon.mind)
		eye_overlays = species.hk_eye_overlays(droid)
		eyes = eye_overlays[1]
		var/examine_text = jointext(droid.examine(surgeon), "\n")
		if(species.recolor_on_reprogram)
			TEST_ASSERT(islist(eyes.color), "reprogrammed [species.hk_model] eyes change color")
			TEST_ASSERT(findtext(examine_text, "светятся голубым"), "examine tells a reprogrammed [species.hk_model] by its eyes")
		else
			TEST_ASSERT_NULL(eyes.color, "[species.hk_model] eyes stay yellow after reprogramming")
			TEST_ASSERT(!findtext(examine_text, "светятся голубым"), "examine does not call [species.hk_model] eyes blue")

/// Осмотр обездвиженного HK подсказывает перепрошивку, а хозяина показывает робототехнику и диагностическому HUD, но не сквозь маскировку.
/datum/unit_test/hk_examine_loyalty

/datum/unit_test/hk_examine_loyalty/Run()
	var/mob/living/carbon/human/master = allocate_minded_human()
	var/mob/living/carbon/human/droid = allocate(/mob/living/carbon/human)
	droid.set_species(/datum/species/ipc/hk/hk51)
	droid.AddComponent(/datum/component/hk_loyalty, master.mind)
	var/mob/living/carbon/human/viewer = allocate_minded_human()
	var/examine_text = jointext(droid.examine(viewer), "\n")
	TEST_ASSERT(!findtext(examine_text, "перепрошить"), "a free HK shows no reprogramming hint")
	TEST_ASSERT(!findtext(examine_text, "Блок лояльности:"), "a crewman can't read the loyalty block")

	droid.Knockdown(10 SECONDS)
	examine_text = jointext(droid.examine(viewer), "\n")
	TEST_ASSERT(findtext(examine_text, "перепрошить операцией на голове"), "a disabled HK shows the reprogramming hint")
	droid.SetKnockdown(0)

	viewer.mind.assigned_role = "Roboticist"
	examine_text = jointext(droid.examine(viewer), "\n")
	TEST_ASSERT(findtext(examine_text, "Блок лояльности: хозяин - [master.mind.name]"), "a roboticist reads the master")
	viewer.mind.assigned_role = "Assistant"

	var/obj/item/clothing/glasses/hud/diagnostic/goggles = allocate(/obj/item/clothing/glasses/hud/diagnostic)
	TEST_ASSERT(viewer.equip_to_slot_if_possible(goggles, ITEM_SLOT_EYES, disable_warning = TRUE), "the viewer puts on a diagnostic HUD")
	examine_text = jointext(droid.examine(viewer), "\n")
	TEST_ASSERT(findtext(examine_text, "Блок лояльности: хозяин - [master.mind.name]"), "a diagnostic HUD reads the master")

	ADD_TRAIT(droid, TRAIT_HK47_DISGUISED, TRAIT_GENERIC)
	examine_text = jointext(droid.examine(viewer), "\n")
	TEST_ASSERT(!findtext(examine_text, "Блок лояльности"), "the disguise hides the loyalty block")
	REMOVE_TRAIT(droid, TRAIT_HK47_DISGUISED, TRAIT_GENERIC)

	var/datum/component/hk_loyalty/loyalty = droid.GetComponent(/datum/component/hk_loyalty)
	loyalty.set_master(null)
	examine_text = jointext(droid.examine(viewer), "\n")
	TEST_ASSERT(findtext(examine_text, "Блок лояльности: хозяин не задан"), "a reset block reads as no master")

/// Удар HK-51 оглушает не чаще, чем удар HK-47.
/datum/unit_test/hk51_punch_balance

/datum/unit_test/hk51_punch_balance/Run()
	var/datum/species/ipc/hk/hk51/hk51 = new
	var/datum/species/ipc/hk/hk47/hk47 = new
	var/hk51_stun_rolls = max(0, hk51.punchdamagehigh - hk51.punchstunthreshold + 1)
	var/hk51_rolls = hk51.punchdamagehigh - hk51.punchdamagelow + 1
	TEST_ASSERT(hk51_stun_rolls / hk51_rolls <= 0.2, "HK-51 stun punch chance is [hk51_stun_rolls] of [hk51_rolls]")
	TEST_ASSERT(hk51.punchstunthreshold > hk47.punchstunthreshold, "HK-51 stuns less often than HK-47")
	qdel(hk51)
	qdel(hk47)
