/datum/surgery/amputation
	name = "Amputation"
	steps = list(/datum/surgery_step/incise, /datum/surgery_step/clamp_bleeders, /datum/surgery_step/retract_skin, /datum/surgery_step/saw, /datum/surgery_step/clamp_bleeders, /datum/surgery_step/sever_limb)
	target_mobtypes = list(/mob/living/carbon/human, /mob/living/carbon/monkey)
	possible_locs = list(BODY_ZONE_R_ARM, BODY_ZONE_L_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG, BODY_ZONE_HEAD)
	requires_bodypart_type = BODYPART_ORGANIC // BLUEMOON EDIT - было 0, изменено для отдельных ампутаций робоконечностям
	special_surgery_traits = list(OPERATION_NEED_FULL_ANESTHETIC) // BLUEMOON ADD - операция требует, чтобы пациент находился без сознания
	icon_state = "saw"
	radial_priority = SURGERY_RADIAL_PRIORITY_HEAL_ADDITIONAL

/datum/surgery_step/sever_limb
	name = "Отделить Конечность"
	implements = list(TOOL_SCALPEL = 100, TOOL_SAW = 100, /obj/item/melee/transforming/energy/sword/cyborg/saw = 100, /obj/item/melee/arm_blade = 80, /obj/item/chainsaw = 80, /obj/item/mounted_chainsaw = 80, /obj/item/fireaxe = 50, /obj/item/hatchet = 40, /obj/item/kitchen/knife/butcher = 25)
	time = 64
	preop_sound = 'sound/surgery/scalpel1.ogg'
	success_sound = 'sound/surgery/organ2.ogg'

/datum/surgery_step/sever_limb/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(user, target, "<span class='notice'>You begin to sever [target]'s [parse_zone(target_zone)]...</span>",
		"[user] begins to sever [target]'s [parse_zone(target_zone)]!",
		"[user] begins to sever [target]'s [parse_zone(target_zone)]!")

/datum/surgery_step/sever_limb/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	var/mob/living/carbon/human/L = target
	display_results(user, target, "<span class='notice'>You sever [L]'s [parse_zone(target_zone)].</span>",
		"[user] severs [L]'s [parse_zone(target_zone)]!",
		"[user] severs [L]'s [parse_zone(target_zone)]!")
	if(surgery.operated_bodypart)
		var/obj/item/bodypart/target_limb = surgery.operated_bodypart
		target_limb.drop_limb()
	return TRUE
