//Emergency Reboot: A surgery that allows for revival of Synthetics without the need for a defib. Doesn't all all the organs like the Revival surgery though.

/datum/surgery/robot_eye_surgery
	name = "Camera Repair"
	desc = "The operation allows the robot's cameras to be repaired and its vision to be restored."
	possible_locs = list(BODY_ZONE_PRECISE_EYES)
	requires_bodypart_type = BODYPART_ROBOTIC	//If you are a Synth with a organic head (somehow), this won't work.
	steps = list(/datum/surgery_step/mechanic_open, /datum/surgery_step/open_hatch, /datum/surgery_step/fix_cameras, /datum/surgery_step/mechanic_close)
	icon_state = "cybernetic_eyeballs"
	radial_priority = SURGERY_RADIAL_PRIORITY_HEAL_ORGAN

/datum/surgery/robot_eye_surgery/can_start(mob/user, mob/living/carbon/target, obj/item/tool)
	if(!..())
		return FALSE
	var/obj/item/organ/eyes/E = target.getorganslot(ORGAN_SLOT_EYES)
	if(!E && (E.organ_flags & ORGAN_FAILING))
		return FALSE
	return TRUE

/datum/surgery_step/fix_cameras
	name = "Починить камеры"
	implements = list(/obj/item/stack/medical/nanogel = 100)
	time = 64

/datum/surgery_step/fix_cameras/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(user, target, "<span class='notice'>You begin to fix [target]'s eyes...</span>",
		"[user] begins to fix [target]'s eyes.",
		"[user] begins to perform surgery on [target]'s eyes.")

/datum/surgery_step/fix_cameras/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	var/obj/item/organ/eyes/E = target.getorganslot(ORGAN_SLOT_EYES)
	display_results(user, target, "<span class='notice'>You succeed in fixing [target]'s eyes.</span>",
		"[user] successfully fixes [target]'s eyes!",
		"[user] completes the surgery on [target]'s eyes.")
	target.cure_blind(list(EYE_DAMAGE))
	target.set_blindness(0)
	target.cure_nearsighted(list(EYE_DAMAGE))
	target.blur_eyes(35)	//this will fix itself slowly.
	E.setOrganDamage(0)
	return TRUE

/datum/surgery_step/fix_cameras/failure(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	. = ..()
	if(target.getorgan(/obj/item/organ/brain))
		display_results(user, target, "<span class='warning'>You accidentally stab [target] right in the brain!</span>",
			"<span class='warning'>[user] accidentally stabs [target] right in the brain!</span>",
			"<span class='warning'>[user] accidentally stabs [target] right in the brain!</span>")
		target.adjustOrganLoss(ORGAN_SLOT_BRAIN, 70)
	else
		display_results(user, target, "<span class='warning'>You accidentally stab [target] right in the brain! Or would have, if [target] had a brain.</span>",
			"<span class='warning'>[user] accidentally stabs [target] right in the brain! Or would have, if [target] had a brain.</span>",
			"<span class='warning'>[user] accidentally stabs [target] right in the brain!</span>")
