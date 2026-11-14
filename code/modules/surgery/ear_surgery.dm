/datum/surgery/ear_surgery
	name = "Ear surgery"
	desc = "Хирургическая процедура, направленная на восстановление слуха пациента."
	steps = list(/datum/surgery_step/incise, /datum/surgery_step/retract_skin, /datum/surgery_step/clamp_bleeders, /datum/surgery_step/fix_ears, /datum/surgery_step/close)
	target_mobtypes = list(/mob/living/carbon/human, /mob/living/carbon/monkey)
	possible_locs = list(BODY_ZONE_HEAD)
	requires_bodypart_type = BODYPART_ORGANIC
	icon_state = "ears"
	radial_priority = SURGERY_RADIAL_PRIORITY_HEAL_ORGAN

/datum/surgery/ear_surgery/can_start(mob/user, mob/living/carbon/target, obj/item/tool)
	. = ..()
	if(!.)
		return .
	var/obj/item/organ/ears/E = target.getorganslot(ORGAN_SLOT_EARS)
	if(!E)
		return FALSE
	return TRUE

/datum/surgery_step/fix_ears
	name = "Исправить Уши"
	implements = list(TOOL_HEMOSTAT = 100, TOOL_SCREWDRIVER = 45, /obj/item/pen = 25)
	time = 64

/datum/surgery_step/fix_ears/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(user, target, "<span class='notice'>You begin to fix [target]'s ears...</span>",
		"[user] begins to fix [target]'s ears.",
		"[user] begins to perform surgery on [target]'s ears.")

/datum/surgery_step/fix_ears/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	var/obj/item/organ/ears/E = target.getorganslot(ORGAN_SLOT_EARS)
	display_results(user, target, "<span class='notice'>You succeed in fixing [target]'s ears.</span>",
		"[user] successfully fixes [target]'s ears!",
		"[user] completes the surgery on [target]'s ears.")
	target.restoreEars()
	if(E)
		E.setOrganDamage(0)
	return TRUE