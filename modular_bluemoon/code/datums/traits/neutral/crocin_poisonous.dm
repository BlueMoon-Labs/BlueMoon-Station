
/datum/quirk/crocin_poisonous
	name = "Кроциновая токсичность"
	desc = "Ваше тело выделяет кроцин, легко проникающий в чужой организм при близком контакте. Особую эффективность имеют в этом поцелуи."
	value = 0
	medical_record_text = "Пациент имеет токсичность с выделением кроцина на своём теле."
	mob_trait = TRAIT_BLUEMOON_CROCIN_POISONOUS
	gain_text = span_notice("Вы ощущаете свою токсичность")
	lose_text = span_notice("Вы стали менее токсичны. Как минимум физически.")

/datum/quirk/crocin_poisonous/add()
	RegisterSignal(quirk_holder, COMSIG_INTERACTION_ADJACENT, PROC_REF(pois), TRUE)
	RegisterSignal(quirk_holder, COMSIG_INTERACTION_KISS, PROC_REF(kiss_pois), TRUE)

/datum/quirk/crocin_poisonous/remove()
	UnregisterSignal(quirk_holder, list(COMSIG_INTERACTION_ADJACENT, COMSIG_INTERACTION_KISS))

/datum/quirk/crocin_poisonous/proc/kiss_pois(mob/living/user, mob/living/target)
	SIGNAL_HANDLER
	pois(user, target, /datum/reagent/drug/aphrodisiacplus)

/datum/quirk/crocin_poisonous/proc/pois(mob/living/user, mob/living/target, datum/reagent/used_reagent = /datum/reagent/drug/aphrodisiac)
	SIGNAL_HANDLER
	if(!target.reagents)
		return
	var/reagent_amount = target.reagents.get_reagent_amount(used_reagent)
	if(reagent_amount < 2)
		target.reagents.add_reagent(used_reagent, 2 - reagent_amount)
