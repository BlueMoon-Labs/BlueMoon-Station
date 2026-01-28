//Emergency Reboot: A surgery that allows for revival of Synthetics without the need for a defib. Doesn't all all the organs like the Revival surgery though.

/datum/surgery/emergency_reboot
	name = "Emergency Reboot"
	desc = "A surgery forcing the posibrain of a robot to begin it's reboot procedure, if their body can sustain its operation."
	possible_locs = list(BODY_ZONE_HEAD)
	requires_bodypart_type = BODYPART_ROBOTIC	//If you are a Synth with a organic head (somehow), this won't work.
	steps = list(/datum/surgery_step/mechanic_open, /datum/surgery_step/open_hatch, /datum/surgery_step/mechanic_unwrench, /datum/surgery_step/force_reboot, /datum/surgery_step/mechanic_wrench, /datum/surgery_step/mechanic_close)
	icon = 'modular_bluemoon/phenyamomota/icon/obj/tools.dmi'
	icon_state = "multitool_wiring"
	radial_priority = SURGERY_RADIAL_PRIORITY_HEAL_EMERGENCY

/datum/surgery/emergency_reboot/can_start(mob/user, mob/living/carbon/target, obj/item/tool)
	if(!..())
		return FALSE
	if(target.stat != DEAD)
		return FALSE
	if(target.suiciding || HAS_TRAIT(target, TRAIT_NOCLONE) || target.hellbound)
		return FALSE
	if(!HAS_TRAIT(target, TRAIT_ROBOTIC_ORGANISM))
		return FALSE
	var/obj/item/organ/brain/B = target.getorganslot(ORGAN_SLOT_BRAIN)
	if(!B || !istype(B, /obj/item/organ/brain/ipc))
		return FALSE
	return TRUE

/datum/surgery_step/force_reboot
	name = "Инициировать Перезагрузку Системы"
	implements = list(TOOL_MULTITOOL = 100, /obj/item/borg/upgrade/restart = 100)
	time = 100

/datum/surgery_step/force_reboot/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(user, target, "<span class='notice'>You prepare to begin rebooting [target]'s posibrain.</span>",
		"[user] prepares to reboot [target]'s posibrain with [tool].",
		"[user] prepares to reboot [target]'s posibrain with [tool].")
	target.notify_ghost_cloning("Someone is trying to reboot you! Re-enter your corpse if you want to be revived!", source = target)

/datum/surgery_step/force_reboot/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(user, target, "<span class='notice'>You successfully initiate a reboot in [target]'s posibrain...</span>",
		"[user] initiates a reboot in [target]'s posibrain...",
		"[user] initiates a reboot in [target]'s posibrain...")
	target.adjustOxyLoss(-50, 0)
	target.updatehealth()
	if(target.revive())
		target.visible_message("...[target]'s posibrain flickers to life once again!")
		target.emote("ping")
		// BLUEMOON EDIT START - изменение памяти после смерти
		target.mind?.revival_handle_memory("force reboot")
		// BLUEMOON EDIT END
		return TRUE
	else
		target.visible_message("...[target]'s posibrain flickers a few times, before the lights fade yet again...")
		return FALSE

/datum/surgery_step/force_reboot/failure(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	. = ..()
	display_results(user, target, "<span class='notice'>You attempt to reboot [target]'s posibrain, but [target.ru_who()] doesn't react.</span>",
		"[user] attempts to reboot [target]'s posibrain, but [target.ru_who()] doesn't react.",
		"[user] attempts to reboot [target]'s posibrain, but [target.ru_who()] doesn't react")
	target.adjustOrganLoss(ORGAN_SLOT_BRAIN, 15, 199)
