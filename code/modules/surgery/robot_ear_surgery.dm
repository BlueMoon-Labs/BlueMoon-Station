/datum/surgery/robot_ear_surgery
	name = "Audio sensor repair"
	desc = "Операция по восстановлению аудиосенсоров синтетика."
	possible_locs = list(BODY_ZONE_HEAD)
	requires_bodypart_type = BODYPART_ROBOTIC
	steps = list(/datum/surgery_step/mechanic_open, /datum/surgery_step/open_hatch, /datum/surgery_step/fix_audio_sensors, /datum/surgery_step/mechanic_close)
	icon_state = "cybernetic_eyeballs"
	radial_priority = SURGERY_RADIAL_PRIORITY_HEAL_ORGAN

/datum/surgery/robot_ear_surgery/can_start(mob/user, mob/living/carbon/target, obj/item/tool)
	if(!..())
		return FALSE
	var/obj/item/organ/ears/E = target.getorganslot(ORGAN_SLOT_EARS)
	if(!E)
		return FALSE
	return TRUE

/datum/surgery_step/fix_audio_sensors
	name = "Починить Аудиосенсоры"
	implements = list(/obj/item/stack/medical/nanogel = 100)
	time = 64

/datum/surgery_step/fix_audio_sensors/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(user, target, "<span class='notice'>You begin to fix [target]'s audio sensors...</span>",
		"[user] begins to fix [target]'s audio sensors.",
		"[user] begins to perform surgery on [target]'s audio sensors.")

/datum/surgery_step/fix_audio_sensors/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	var/obj/item/organ/ears/E = target.getorganslot(ORGAN_SLOT_EARS)
	display_results(user, target, "<span class='notice'>You succeed in fixing [target]'s audio sensors.</span>",
		"[user] successfully fixes [target]'s audio sensors!",
		"[user] completes the surgery on [target]'s audio sensors.")
	target.restoreEars()
	if(E)
		E.setOrganDamage(0)
	return TRUE