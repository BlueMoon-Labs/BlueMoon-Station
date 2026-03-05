/datum/disease/death_sandwich_poisoning
	name = "Death Sandwich Poisoning"
	desc = "If left untreated the subject will ultimately perish."
	form = "Condition"
	spread_text = "Unknown"
	max_stages = 3
	cure_text = "Anacea"
	cures = list(/datum/reagent/toxin/anacea)
	cure_chance = 4
	agent = "eating the Death Sandwich wrong"
	viable_mobtypes = list(/mob/living/carbon/human)
	severity = DISEASE_SEVERITY_DANGEROUS
	disease_flags = CURABLE
	spread_flags = DISEASE_SPREAD_SPECIAL
	visibility_flags = HIDDEN_SCANNER
	bypasses_immunity = TRUE
	required_organs = list(/obj/item/organ/stomach)

/datum/disease/death_sandwich_poisoning/stage_act()
	. = ..()
	if(!.)
		return

	switch(stage)
		if(1)
			if(prob(1))
				affected_mob.emote("cough")
			if(prob(1))
				affected_mob.emote("gag")
			if(prob(1))
				affected_mob.adjustToxLoss(5)
		if(2)
			if(prob(5))
				affected_mob.emote("cough")
			if(prob(2))
				affected_mob.emote("gag")
			if(prob(1))
				to_chat(affected_mob, span_danger("Your body feels hot!"))
				if(prob(20))
					affected_mob.take_bodypart_damage(0, 1)
			if(prob(3))
				affected_mob.adjustToxLoss(10)

		if(3)
			if(prob(5))
				affected_mob.emote("gag")
			if(prob(10))
				affected_mob.emote("gasp")
			if(prob(2))
				affected_mob.vomit(20, TRUE)
			if(prob(2))
				to_chat(affected_mob, span_danger("Your body feels hot!"))
				if(prob(60))
					affected_mob.take_bodypart_damage(0, 2)
			if(prob(6))
				affected_mob.adjustToxLoss(15)
			if(prob(1))
				to_chat(affected_mob, span_danger("You try to scream, but nothing comes out!"))
				affected_mob.Stun(50)
