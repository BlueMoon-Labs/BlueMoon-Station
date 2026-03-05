/datum/disease/parasite
	form = "Parasite"
	name = "Parasitic Infection"
	max_stages = 4
	cure_text = "Surgical removal of the liver."
	agent = "Consuming Live Parasites"
	spread_text = "Non-Biological"
	viable_mobtypes = list(/mob/living/carbon/human)
	permeability_mod = 1
	desc = "If left untreated the subject will passively lose nutrients, and eventually lose their liver."
	severity = DISEASE_SEVERITY_HARMFUL
	disease_flags = CAN_CARRY|CAN_RESIST
	spread_flags = DISEASE_SPREAD_NON_CONTAGIOUS
	required_organs = list(/obj/item/organ/liver)
	bypasses_immunity = TRUE

/datum/disease/parasite/stage_act()
	. = ..()
	if(!.)
		return

	switch(stage)
		if(1)
			if(prob(2))
				affected_mob.emote("cough")
		if(2)
			if(prob(5))
				if(prob(50))
					to_chat(affected_mob, span_notice("You feel the weight loss already!"))
				affected_mob.adjust_nutrition(-3)
		if(3)
			if(prob(10))
				if(prob(20))
					to_chat(affected_mob, span_notice("You're... REALLY starting to feel the weight loss."))
				affected_mob.adjust_nutrition(-6)
		if(4)
			if(prob(16))
				if(affected_mob.nutrition >= 100)
					if(prob(10))
						to_chat(affected_mob, span_warning("You feel like your body's shedding weight rapidly!"))
					affected_mob.adjust_nutrition(-12)
				else
					to_chat(affected_mob, span_warning("You feel much, MUCH lighter!"))
					affected_mob.vomit(20, TRUE)
					var/obj/item/organ/liver/affected_liver = affected_mob.getorganslot(ORGAN_SLOT_LIVER)
					if(affected_liver)
						affected_liver.Remove(affected_mob)
						affected_liver.forceMove(get_turf(affected_mob))
					cure()
					return FALSE
