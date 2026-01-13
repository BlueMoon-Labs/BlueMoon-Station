//BIOAEGIS MODULES.
//LIVER

//TIER 1 LIVER//
/obj/item/organ/liver/tier1
	name = "improved liver"
	desc = "A somewhat decent replica of baseline liver. Tougher than the baseline liver."
	icon = 'modular_bluemoon/icons/obj/surgery.dmi'
	icon_state = "weakliver"
	maxHealth = 1.5 * STANDARD_ORGAN_THRESHOLD
	toxTolerance = 2 * LIVER_DEFAULT_TOX_TOLERANCE
	toxLethality = 0.4 * LIVER_DEFAULT_TOX_LETHALITY

/obj/item/organ/liver/tier1/Insert(mob/living/carbon/organ_mob, special, drop_if_replaced)
	. = ..()
	to_chat(owner, "<span class = 'notice'>Что-то неприятно упёрлось внутри живота...</span>\n")

//TIER 2 LIVER//
/obj/item/organ/liver/tier2
	name = "changed liver"
	icon = 'modular_bluemoon/icons/obj/surgery.dmi'
	icon_state = "weakliver"
	desc = "An improved version of baseline liver. Better than the baseline counterpart."
	alcohol_tolerance = 0.001
	maxHealth = 2.5 * STANDARD_ORGAN_THRESHOLD
	toxTolerance = 5 * LIVER_DEFAULT_TOX_TOLERANCE
	toxLethality = 0.4 * LIVER_DEFAULT_TOX_LETHALITY
	healing_factor = 1.5 * STANDARD_ORGAN_HEALING //Heals itself a bit faster
	decay_factor = 0.8 * STANDARD_ORGAN_DECAY //Decays a bit longer

/obj/item/organ/liver/tier2/on_life(seconds, times_fired)
	. = ..()
	if(!. || !owner)//can't process reagents with a failing liver
		return

	if(filterToxins && !HAS_TRAIT(owner, TRAIT_TOXINLOVER))
		//handle liver toxin filtration
		for(var/datum/reagent/toxin/T in owner.reagents.reagent_list)
			var/thisamount = owner.reagents.get_reagent_amount(T.type)
			if (thisamount && thisamount <= toxTolerance)
				owner.reagents.remove_reagent(T.type, 1)
			else
				damage += (thisamount*toxLethality)

	//metabolize reagents
	owner.adjustToxLoss(-0.25, TRUE) //Doesn't kill slimes. Yes.
	owner.adjustFireLoss(-0.25, FALSE)
	owner.reagents.metabolize(owner, seconds, times_fired, can_overdose=TRUE)

	if(damage > 10 && prob(damage/3))//the higher the damage the higher the probability
		to_chat(owner, "<span class='warning'>You feel a dull pain in your abdomen.</span>")

/obj/item/organ/liver/tier2/Insert(mob/living/carbon/organ_mob, special, drop_if_replaced)
	. = ..()
	to_chat(owner, "<span class = 'notice'>Вы ощущаете, словно ваша кровь стала чище.</span>\n")

///TIER 3 LIVER//
/obj/item/organ/liver/tier3
	name = "exalted liver"
	icon = 'modular_bluemoon/icons/obj/surgery.dmi'
	icon_state = "exaltedliver"
	desc = "Something that an alcoholic of the future could use - this version of liver is stronger, better, capable to filter and withstand more, even than cybernetic counterpart!"
	alcohol_tolerance = 0.0005 //At this point just drink everything.
	maxHealth = 3.5 * STANDARD_ORGAN_THRESHOLD
	toxTolerance = 7 * LIVER_DEFAULT_TOX_TOLERANCE
	toxLethality = 0.2 * LIVER_DEFAULT_TOX_LETHALITY
	healing_factor = 2.5 * STANDARD_ORGAN_HEALING
	decay_factor = 0.5 * STANDARD_ORGAN_DECAY

/obj/item/organ/liver/tier3/Insert(mob/living/carbon/organ_mob, special, drop_if_replaced)
	. = ..()
	to_chat(owner, "<span class = 'notice'>Вы можете заметить, словно ваша кожа стала светлее...</span>\n") //This is a *very precise* superior version of liver - you wouldn't feel anything.
	SEND_SIGNAL(organ_mob, COMSIG_ADD_MOOD_EVENT, "super liver", /datum/mood_event/superliver)

/datum/mood_event/superliver
	description = "<span class='nicegreen'>Алкоголизм мне не помеха!</span>\n"
	mood_change = 1 //Less, but persistent mood buff. Hey, handsome, you deserve it.

/obj/item/organ/liver/tier3/on_life(seconds, times_fired)
	. = ..()
	if(!. || !owner)//can't process reagents with a failing liver
		return

	if(filterToxins && !HAS_TRAIT(owner, TRAIT_TOXINLOVER))
		//handle liver toxin filtration
		for(var/datum/reagent/toxin/T in owner.reagents.reagent_list)
			var/thisamount = owner.reagents.get_reagent_amount(T.type)
			if (thisamount && thisamount <= toxTolerance)
				owner.reagents.remove_reagent(T.type, 1)
			else
				damage += (thisamount*toxLethality)

	//metabolize reagents
	owner.adjustToxLoss(-1.5, TRUE)
	owner.adjustFireLoss(-0.35, FALSE)
	owner.reagents.metabolize(owner, seconds, times_fired, can_overdose=TRUE)

	if(damage > 10 && prob(damage/3))//the higher the damage the higher the probability
		to_chat(owner, "<span class='warning'>You feel a dull pain in your abdomen.</span>")

//ANTAG LIVER//
/obj/item/organ/liver/tier3/antag //antag organ that can be found in some shitty places or in antag uplink since why not?
	name = "biomorphed liver"
	desc = "A very secretive weapon against alcoholism, or NT's safety regarding chemicals!"
	icon_state = "exaltedliver"
	maxHealth = 4.5 * STANDARD_ORGAN_THRESHOLD
	toxTolerance = 9 * LIVER_DEFAULT_TOX_TOLERANCE
	toxLethality = 0.1 * LIVER_DEFAULT_TOX_LETHALITY
	healing_factor = 3.5 * STANDARD_ORGAN_HEALING
	decay_factor = 0.1 * STANDARD_ORGAN_DECAY

/obj/item/organ/liver/tier3/antag/on_life(seconds, times_fired)
	. = ..()
	if(!. || !owner)//can't process reagents with a failing liver
		return

	if(filterToxins && !HAS_TRAIT(owner, TRAIT_TOXINLOVER))
		//handle liver toxin filtration
		for(var/datum/reagent/toxin/T in owner.reagents.reagent_list)
			var/thisamount = owner.reagents.get_reagent_amount(T.type)
			if (thisamount && thisamount <= toxTolerance)
				owner.reagents.remove_reagent(T.type, 1)
			else
				damage += (thisamount*toxLethality)

	//metabolize reagents
	owner.adjustToxLoss(-5, TRUE) //Heals like hell.
	owner.adjustFireLoss(-2, FALSE)
	owner.adjustStaminaLoss(-5, 0)
	owner.reagents.metabolize(owner, seconds, times_fired, can_overdose=TRUE)

	if(damage > 10 && prob(damage/3))//the higher the damage the higher the probability
		to_chat(owner, "<span class='warning'>You feel a dull pain in your abdomen.</span>")

/obj/item/autosurgeon/syndicate/inteq/biomorphedliver
	uses = 1
	starting_organ = /obj/item/organ/liver/tier3/antag

/datum/uplink_item/implants/biomorphedliver
	name = "Biomorphed Liver"
	desc = "Экспериментальный орган, что используется некоторыми отрядами супер-солдат в различных 'чёрных операциях'. Даёт усиленное восстановление от токсинов и уменьшает изнурение."
	item = /obj/item/autosurgeon/syndicate/inteq/biomorphedliver
	cost = 5
	purchasable_from = (UPLINK_TRAITORS | UPLINK_NUKE_OPS)
