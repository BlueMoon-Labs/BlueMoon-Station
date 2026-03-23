/datum/surgery/sew_up_the_mouth
	name = "Зашить Рот"
	steps = list(/datum/surgery_step/incise, /datum/surgery_step/retract_skin, /datum/surgery_step/clamp_bleeders, /datum/surgery_step/incise, /datum/surgery_step/sew_up_the_mouth, /datum/surgery_step/close)
	possible_locs = list(BODY_ZONE_PRECISE_MOUTH)
	requires_bodypart_type = BODYPART_ORGANIC
	is_healing = FALSE // BLUEMOON ADD
	icon_state = "surgery_mouth"
	radial_priority = SURGERY_RADIAL_PRIORITY_OTHER_THIRD

/datum/surgery/sew_up_the_mouth/can_start(mob/user, mob/living/patient, obj/item/tool)
	. = ..()
	if(!.)
		return .
	. = !(HAS_TRAIT_FROM(patient, TRAIT_MUTE, ORGAN_TRAIT))

/datum/surgery_step/sew_up_the_mouth
	name = "Зашить или Прижечь Рот"
	implements = list(TOOL_CAUTERY = 100, /obj/item/gun/energy/laser = 90, /obj/item/stack/medical/suture = 85, TOOL_WELDER = 70,
		/obj/item = 30) // 30% success with any hot item.
	time = 24
	preop_sound = 'sound/surgery/cautery1.ogg'
	success_sound = 'sound/surgery/cautery2.ogg'

/datum/surgery_step/sew_up_the_mouth/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(user, target, "<span class='notice'>Вы начинаете зашивать <b>[ru_parse_zone(target_zone)]</b> <b>[target]</b>...</span>",
		"<b>[user]</b> начинает зашивать <b>[ru_parse_zone(target_zone)]</b> <b>[target]</b>.",
		"<b>[user]</b> начинает зашивать <b>[ru_parse_zone(target_zone)]</b> <b>[target]</b>.")

/datum/surgery_step/sew_up_the_mouth/tool_check(mob/user, obj/item/tool)
	if(implement_type == TOOL_WELDER || implement_type == /obj/item)
		return tool.get_temperature()
	return TRUE

/datum/surgery_step/sew_up_the_mouth/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	sew_up_the_mouth(target)
	if (ishuman(target))
		var/mob/living/carbon/human/H = target
		var/obj/item/bodypart/BP = H.get_bodypart(target_zone)
		if(BP)
			BP.generic_bleedstacks -= 3
	return ..()

/datum/surgery_step/proc/sew_up_the_mouth(mob/living/carbon/target)
	ADD_TRAIT(target, TRAIT_MUTE, ORGAN_TRAIT)

/datum/surgery/unsew_up_the_mouth
	name = "Расшить Рот"
	steps = list(/datum/surgery_step/incise, /datum/surgery_step/retract_skin, /datum/surgery_step/clamp_bleeders, /datum/surgery_step/unsew_up_the_mouth, /datum/surgery_step/close)
	possible_locs = list(BODY_ZONE_PRECISE_MOUTH)
	requires_bodypart_type = BODYPART_ORGANIC
	icon_state = "surgery_mouth"
	radial_priority = SURGERY_RADIAL_PRIORITY_HEAL_EMERGENCY

/datum/surgery/unsew_up_the_mouth/can_start(mob/user, mob/living/patient, obj/item/tool)
	. = ..()
	if(!.)
		return .
	. = HAS_TRAIT_FROM(patient, TRAIT_MUTE, ORGAN_TRAIT)

/datum/surgery_step/unsew_up_the_mouth
	name = "Расшить Рот"
	implements = list(TOOL_SCALPEL = 100, /obj/item/melee/transforming/energy/sword = 75, /obj/item/kitchen/knife = 65,
		/obj/item/shard = 45, /obj/item = 30) // 30% success with any sharp item.
	time = 24
	preop_sound = 'sound/surgery/cautery1.ogg'
	success_sound = 'sound/surgery/cautery2.ogg'

/datum/surgery_step/unsew_up_the_mouth/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(user, target, "<span class='notice'>Вы начинаете расшивать <b>[ru_parse_zone(target_zone)]</b> <b>[target]</b>...</span>",
		"<b>[user]</b> начинает расшивать <b>[ru_parse_zone(target_zone)]</b> <b>[target]</b>.",
		"<b>[user]</b> начинает расшивать <b>[ru_parse_zone(target_zone)]</b> <b>[target]</b>.")

/datum/surgery_step/unsew_up_the_mouth/tool_check(mob/user, obj/item/tool)
	if(implement_type == TOOL_WELDER || implement_type == /obj/item)
		return tool.get_temperature()
	return TRUE

/datum/surgery_step/unsew_up_the_mouth/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	unsew_up_the_mouth(target)
	if (ishuman(target))
		var/mob/living/carbon/human/H = target
		var/obj/item/bodypart/BP = H.get_bodypart(target_zone)
		if(BP)
			BP.generic_bleedstacks -= 3
	return ..()

/datum/surgery_step/proc/unsew_up_the_mouth(mob/living/carbon/target)
	REMOVE_TRAIT(target, TRAIT_MUTE, ORGAN_TRAIT)
