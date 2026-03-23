/datum/surgery/embalming //Fast and easy way to husk bodys
	name = "Embalming"
	desc = "Хирургическая процедура, которая предотвращает выделение миазмов из трупа."
	steps = list(/datum/surgery_step/incise,
				/datum/surgery_step/embalming,
				/datum/surgery_step/close)

	target_mobtypes = list(/mob/living/carbon/human, /mob/living/carbon/monkey)
	possible_locs = list(BODY_ZONE_CHEST)
	requires_bodypart_type = BODYPART_ORGANIC
	is_healing = FALSE // BLUEMOON ADD
	icon = 'icons/mob/human_parts_greyscale.dmi'
	icon_state = "human_chest_m"
	radial_priority = SURGERY_RADIAL_PRIORITY_OTHER_SECOND

/datum/surgery_step/embalming
	name = "Бальмазировать Тело"
	implements = list(TOOL_HEMOSTAT = 100, TOOL_SCREWDRIVER = 35)
	chems_needed = list(/datum/reagent/space_cleaner/sterilizine, /datum/reagent/drying_agent)
	require_all_chems = FALSE

/datum/surgery_step/embalming/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	user.visible_message("[user] starts to embalm [target]'s body.", "<span class='notice'>You start embalming [target]'s body.</span>")

/datum/surgery_step/embalming/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	user.visible_message("[user] embalms [target]'s body.", "<span class='notice'>You succeed in embalming [target]'s body.</span>")
	ADD_TRAIT(target, TRAIT_HUSK, MAGIC_TRAIT) //Husk's prevent body smell
	return TRUE

/datum/surgery_step/embalming/failure(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	. = ..()
	user.visible_message("[user] screws up!", "<span class='warning'>You screwed up!</span>")
	ADD_TRAIT(target, TRAIT_NOCLONE, MAGIC_TRAIT) //That body is ruined, but still gives miasma
