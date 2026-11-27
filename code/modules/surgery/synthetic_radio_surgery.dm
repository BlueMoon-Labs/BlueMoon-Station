/datum/surgery/synthetic_radio_repair
	name = "Radio module repair"
	desc = "Операция по восстановлению встроенной радиосистемы синтетика."
	possible_locs = list(BODY_ZONE_HEAD)
	requires_bodypart_type = BODYPART_ROBOTIC
	steps = list(/datum/surgery_step/mechanic_open, /datum/surgery_step/open_hatch, /datum/surgery_step/fix_synth_radio, /datum/surgery_step/mechanic_close)
	icon_state = "cybernetic_eyeballs"
	radial_priority = SURGERY_RADIAL_PRIORITY_HEAL_ORGAN

/datum/surgery/synthetic_radio_repair/can_start(mob/user, mob/living/carbon/target, obj/item/tool)
	if(!..())
		return FALSE
	return !!target.getorganslot(ORGAN_SLOT_SYNTH_RADIO)

/datum/surgery_step/fix_synth_radio
	name = "Починить радиомодуль"
	implements = list(/obj/item/stack/medical/nanogel = 100)
	time = 64

/datum/surgery_step/fix_synth_radio/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(user, target, "<span class='notice'>You begin to fix [target]'s built-in radio...</span>",
		"[user] begins to fix [target]'s built-in radio.",
		"[user] begins to perform surgery on [target]'s built-in radio.")

/datum/surgery_step/fix_synth_radio/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	var/obj/item/organ/synthetic_radio/R = target.getorganslot(ORGAN_SLOT_SYNTH_RADIO)
	display_results(user, target, "<span class='notice'>You succeed in fixing [target]'s built-in radio.</span>",
		"[user] successfully fixes [target]'s built-in radio!",
		"[user] completes the surgery on [target]'s built-in radio.")
	if(R)
		R.setOrganDamage(0)
		R.organ_flags &= ~ORGAN_SYNTHETIC_EMP
		if(R.radio)
			R.radio.recalculateChannels()
	return TRUE
