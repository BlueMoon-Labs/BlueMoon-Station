//Dangerous designs are supposed to be, in fact, 'dangerous', providing both huge buffs and horrendous debuffs.
//Main rule - make organs strong and traumatic to use, with no 'i can hack it and benefit with no drawbacks.'
//It would be really good to provide a short description of what it does, straight to the point.

/obj/item/organ/bodyoverload
	name = "Optimia ossmodula"
	desc = "A special gland which was made out of artificial bacteria via nanites. Dangerous. In this case, they are programmed to overload restorative bodily systems, but this puts a certain toll on body - causes severe oxygen loss, with toxic degeneration of body."
	icon = 'modular_bluemoon/icons/obj/surgery.dmi'
	icon_state = "overload"
	slot = ORGAN_SLOT_THRUSTERS //Only one at a time, organicpsychos would be funny but no.
	w_class = WEIGHT_CLASS_NORMAL
	zone = BODY_ZONE_CHEST

/obj/item/organ/bodyoverload/on_life()
	. = ..()
	if(!. || !owner)
		return
	owner.adjustBruteLoss(-15, FALSE)
	owner.adjustFireLoss(-15, FALSE)
	owner.adjustStaminaLoss(1.5, 0) //It overloads body.
	owner.adjustToxLoss(4, FALSE)
	owner.adjustOxyLoss(5, FALSE)

/obj/item/organ/neuralderanger
	name = "Nemedia ossmodula"
	desc = "A special gland which was made out of artificial bacteria via nanites. Dangerous. Due to some irregular encoding, causes removal of 'purge' drugs from the body. Allows body to withstand against any use of stamina and run 24/7 non-stop, but due to 'mishaps' in bodily processes, person will be afflicted with secreted drugs and general sense of insanity."
	icon = 'modular_bluemoon/icons/obj/surgery.dmi'
	icon_state = "nemedia"
	slot = ORGAN_SLOT_THRUSTERS
	w_class = WEIGHT_CLASS_NORMAL
	zone = BODY_ZONE_CHEST
	var/list/possible_reagents = list(/datum/reagent/drug/labebium, /datum/reagent/drug/krokodil, /datum/reagent/drug/heroin, /datum/reagent/drug/happiness, /datum/reagent/drug/methamphetamine, /datum/reagent/drug/space_drugs,  /datum/reagent/drug/skooma, /datum/reagent/medicine/damagedcompound)

/obj/item/organ/neuralderanger/Insert(mob/living/carbon/M, drop_if_replaced = TRUE)
	. = ..()
	if(!.)
		return
	ADD_TRAIT(owner, TRAIT_FREESPRINT, GENETIC_MUTATION)

/obj/item/organ/neuralderanger/on_life()
	var/chem_to_add = pick(possible_reagents)
	owner.reagents.add_reagent(chem_to_add, 1.5) //....But stupidly high on drugs all the time.
	owner.adjustToxLoss(-1, TRUE, TRUE)
	owner.adjustOrganLoss(ORGAN_SLOT_BRAIN, -1) //Labebium and Co hurts brain, so let us heal it just a little bit to offset the threat.
	owner.adjustStaminaLoss(-100, 0) //You can run non-stop...

/obj/item/organ/neuralderanger/Remove(special = FALSE)
	. = ..()
	var/mob/living/carbon/organ_mob = .
	if(!istype(organ_mob))
		return
	REMOVE_TRAIT(organ_mob, TRAIT_FREESPRINT, GENETIC_MUTATION)

/datum/reagent/medicine/damagedcompound
	name = "Artificial Compound"
	description = "Made by Nemedia ossmodula, this chemical removes certain 'purge' chemicals from the body."
	color = "#CF3600" // rgb: 207, 54, 0
	taste_description = "mint" //Minty.
	pH = 8
	value = REAGENT_VALUE_UNCOMMON

/datum/reagent/medicine/damagedcompound/on_mob_life(mob/living/carbon/M)
	holder.remove_reagent(/datum/reagent/medicine/charcoal, 20)
	holder.remove_reagent(/datum/reagent/medicine/calomel, 20)
	holder.remove_reagent(/datum/reagent/medicine/antitoxin, 20)
	holder.remove_reagent(/datum/reagent/medicine/pen_acid, 20)
	holder.remove_reagent(/datum/reagent/medicine/pen_acid/pen_jelly, 20)
//	if(holder.has_reagent(/datum/reagent/medicine/charcoal, /datum/reagent/medicine/calomel, /datum/reagent/medicine/antitoxin, /datum/reagent/medicine/pen_acid, /datum/reagent/medicine/pen_acid/pen_jelly))
//		M.gib() Yes, i wanted just to gib 'em all.
	return ..()
