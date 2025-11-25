/datum/surgery/advanced/toxichealing
	name = "Body Rejuvenation"
	desc = "Хирургическая процедура, которая помогает справиться с кислородным голоданием и лечит части тела, поврежденные из-за токсичных соединений. Работает как с трупами, так и с живыми."
	steps = list(/datum/surgery_step/incise,
				/datum/surgery_step/retract_skin,
				/datum/surgery_step/incise,
				/datum/surgery_step/clamp_bleeders,
				/datum/surgery_step/incise,
				/datum/surgery_step/retract_skin,
				/datum/surgery_step/toxichealing,
				/datum/surgery_step/close)

	target_mobtypes = list(/mob/living/carbon/human, /mob/living/carbon/monkey)
	possible_locs = list(BODY_ZONE_CHEST)
	requires_bodypart_type = 0
	icon_state = "toxin"
	radial_priority = SURGERY_RADIAL_PRIORITY_HEAL_EXTRA

/datum/surgery_step/toxichealing
	name = "Изъять Токсичную Субстанцию и Плоть"
	implements = list(TOOL_HEMOSTAT = 100, TOOL_SCREWDRIVER = 35, /obj/item/pen = 15)
	repeatable = TRUE
	time = 25

/datum/surgery_step/toxichealing/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	user.visible_message("[user] starts rejuvenating some of [target]'s flesh back to life.", "<span class='notice'>You start knitting some of [target]'s flesh back to life.</span>")

/datum/surgery_step/toxichealing/initiate(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery, try_to_fail = FALSE)
	if(..())
		while((target.getToxLoss() >= 1) || (target.getOxyLoss() >= 1))
			. = ..()
			if(!.)
				break

/datum/surgery_step/toxichealing/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	user.visible_message("[user] fixes some of [target]'s wounds.", "<span class='notice'>You succeed in fixing some of [target]'s wounds.</span>")
	target.heal_bodypart_damage(0,0,30) //Heals stam
	target.adjustToxLoss(-15, 0, TRUE)
	target.adjustOxyLoss(-20, 0)
	return TRUE

/datum/surgery_step/toxichealing/failure(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	. = ..()
	target.take_bodypart_damage(25,0)
