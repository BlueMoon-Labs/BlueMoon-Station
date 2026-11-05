/datum/surgery/amputation
	name = "Amputation"
	steps = list(/datum/surgery_step/incise, /datum/surgery_step/clamp_bleeders, /datum/surgery_step/retract_skin, /datum/surgery_step/saw, /datum/surgery_step/clamp_bleeders, /datum/surgery_step/sever_limb)
	target_mobtypes = list(/mob/living/carbon/human, /mob/living/carbon/monkey)
	possible_locs = list(BODY_ZONE_R_ARM, BODY_ZONE_L_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG, BODY_ZONE_HEAD)
	requires_bodypart_type = BODYPART_ORGANIC // BLUEMOON EDIT - было 0, изменено для отдельных ампутаций робоконечностям
	special_surgery_traits = list(OPERATION_NEED_FULL_ANESTHETIC) // BLUEMOON ADD - операция требует, чтобы пациент находился без сознания
	icon_state = "saw"
	radial_priority = SURGERY_RADIAL_PRIORITY_HEAL_ADDITIONAL

/datum/surgery/amputation/can_start(mob/user, mob/living/carbon/target, obj/item/tool)
	if(istype(target.get_bodypart(user.zone_selected), /obj/item/bodypart/l_leg/naga_tail))
		return FALSE
	return ..()

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

// После отсечения хвоста разрез на оставшемся туловище необходимо закрыть.
/datum/surgery/naga_tail_removal
	name = "Supporting tail removal"
	desc = "Отделение опорного хвоста через доступ в области паха. После удаления пациент не сможет ходить."
	icon_state = "saw"
	steps = list(/datum/surgery_step/incise, /datum/surgery_step/clamp_bleeders, /datum/surgery_step/retract_skin, /datum/surgery_step/saw, /datum/surgery_step/clamp_bleeders, /datum/surgery_step/sever_naga_tail, /datum/surgery_step/close/naga_tail_removal)
	possible_locs = list(BODY_ZONE_PRECISE_GROIN)
	requires_bodypart_type = 0
	radial_priority = SURGERY_RADIAL_PRIORITY_HEAL_ADDITIONAL
	special_surgery_traits = list(OPERATION_NEED_FULL_ANESTHETIC)

/datum/surgery/naga_tail_removal/can_start(mob/user, mob/living/carbon/target, obj/item/tool)
	return HAS_TRAIT(target, TRAIT_NAGA_ANATOMY) && istype(target.get_bodypart(BODY_ZONE_L_LEG), /obj/item/bodypart/l_leg/naga_tail) && ..()

/datum/surgery_step/sever_naga_tail
	name = "Отделить опорный хвост"
	parent_type = /datum/surgery_step/sever_limb

/datum/surgery_step/sever_naga_tail/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(user, target, span_notice("Вы начинаете отделять опорный хвост [target]..."),
		"[user] начинает отделять опорный хвост [target].",
		"[user] начинает отделять опорный хвост [target].")

/datum/surgery_step/sever_naga_tail/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	var/obj/item/bodypart/l_leg/naga_tail/tail = target.get_bodypart(BODY_ZONE_L_LEG)
	if(!istype(tail))
		return FALSE
	tail.drop_limb()
	target.updatehealth()
	display_results(user, target, span_notice("Вы отделили опорный хвост [target]."),
		"[user] отделяет опорный хвост [target]!",
		"[user] отделяет опорный хвост [target]!")
	log_combat(user, target, "surgically removed supporting tail")
	return TRUE

/datum/surgery_step/close/naga_tail_removal/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	. = ..()
	var/obj/item/bodypart/bodypart = target.get_bodypart(check_zone(target_zone))
	if(bodypart)
		// Разрез даёт 10 единиц кровотечения, а два зажима и обычное прижигание снимают только 9.
		bodypart.generic_bleedstacks = max(0, bodypart.generic_bleedstacks - 1)
		bodypart.update_part_wound_overlay()
	return TRUE
