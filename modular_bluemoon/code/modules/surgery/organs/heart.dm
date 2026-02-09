//BIOAEGIS MODULES.
//HEART

//TIER 1 HEART//
/obj/item/organ/heart/tier1
	name = "improved heart"
	desc = "A somewhat decent replica of baseline heart. Tougher than the baseline heart."
	icon = 'modular_bluemoon/icons/obj/surgery.dmi'
	icon_state = "weakheart"
	maxHealth = 1.5 * STANDARD_ORGAN_THRESHOLD

/obj/item/organ/heart/tier1/Insert(mob/living/carbon/organ_mob, special, drop_if_replaced)
	. = ..()
	to_chat(owner, "<span class = 'notice'>Как ни странно...словно ничего не поменялось.</span>\n")

//TIER 2 HEART//
/obj/item/organ/heart/tier2
	name = "changed heart"
	desc = "An improved version of baseline heart. Better than the baseline counterpart."
	icon = 'modular_bluemoon/icons/obj/surgery.dmi'
	icon_state = "weakheart"
	maxHealth = 2.5 * STANDARD_ORGAN_THRESHOLD //Usual factor is 2x, so...
	healing_factor = 2.5 * STANDARD_ORGAN_HEALING //Heals itself a bit faster
	decay_factor = 0.8 * STANDARD_ORGAN_DECAY //Decays a bit longer

/obj/item/organ/heart/tier2/on_life()
	owner.adjustOxyLoss(-0.25, FALSE) //Only two healing factors, but heals really, really good. An exchange for being way too problematic to create.
	owner.adjustBruteLoss(-0.25, FALSE)

/obj/item/organ/heart/tier2/Insert(mob/living/carbon/organ_mob, special, drop_if_replaced)
	. = ..()
	to_chat(owner, "<span class = 'notice'>Вы ощущаете, словно ваше сердце стало немного больше.</span>\n")

//TIER 3 HEART//
/obj/item/organ/heart/tier3
	name = "exalted heart"
	desc = "A recent so-called 'perfection' in terms of being heartful. Pumps a little amount of chemicals to mend physical damage, as well as better amount of blood."
	icon = 'modular_bluemoon/icons/obj/surgery.dmi'
	icon_state = "exaltedheart"
	maxHealth = 3.5 * STANDARD_ORGAN_THRESHOLD
	healing_factor = 2.5 * STANDARD_ORGAN_HEALING //Heals itself way faster
	decay_factor = 0.5 * STANDARD_ORGAN_DECAY //Decays way longer than the usual one

/obj/item/organ/heart/tier3/Insert(mob/living/carbon/organ_mob, special, drop_if_replaced)
	. = ..()
	to_chat(owner, "<span class = 'notice'>Ритм вашего нового сердца словно марш легионов.</span>\n")
	SEND_SIGNAL(organ_mob, COMSIG_ADD_MOOD_EVENT, "super heart", /datum/mood_event/superheart)

/datum/mood_event/superheart
	description = "<span class='nicegreen'>Выносливость нового сердца радует разум!</span>\n"
	mood_change = 1 //Perma boost since you deserved it, handsome.

/obj/item/organ/heart/tier3/proc/undo_heart_attack()
	var/mob/living/carbon/human/H = owner
	if(!H || !istype(H))
		return
	H.set_heartattack(FALSE)
	if(H.stat == CONSCIOUS || H.stat == SOFT_CRIT)
		to_chat(H, "<span class='notice'>Вы ощущаете как словно ваши собственные вены начали биться в знакомый ритм!</span>\n")

/obj/item/organ/heart/tier3/on_life()
	owner.adjustOxyLoss(-0.25, FALSE) //It can pump blood rather well, so it can delay oxy damage to some degree.
	owner.adjustBruteLoss(-0.8, FALSE)
	owner.adjustStaminaLoss(-1.5, 0)

//ANTAG HEART//
/obj/item/organ/heart/tier3/antag //antag organ that can be found in some shitty places or in antag uplink since why not?
	name = "biomorphed heart"
	desc = "Something that is straight-up from sci-fi movies about abominations! Very weird, quite big 'pumps'!"
	icon_state = "exaltedheart"
	maxHealth = 4.5 * STANDARD_ORGAN_THRESHOLD
	healing_factor = 3.5 * STANDARD_ORGAN_HEALING
	decay_factor = 0.1 * STANDARD_ORGAN_DECAY

/obj/item/organ/heart/tier3/antag/on_life()
	owner.adjustToxLoss(-2, TRUE) //Heals like hell.
	owner.adjustOxyLoss(-2, FALSE)
	owner.adjustBruteLoss(-2, FALSE)
	owner.adjustFireLoss(-2, FALSE)
	owner.adjustStaminaLoss(-3, 0)
