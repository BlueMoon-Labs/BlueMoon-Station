/datum/disease/death_sandwich_poisoning
	name = "Death Sandwich Poisoning"
	desc = "Если не лечить, субъект в конечном итоге погибнет."
	form = "Condition"
	spread_text = "Неизвестно"
	max_stages = 3
	cure_text = "Анацея"
	cures = list(/datum/reagent/toxin/anacea)
	cure_chance = 4
	agent = "неправильное поедание Смертельного сэндвича"
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
				to_chat(affected_mob, span_danger("Ваше тело горит!"))
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
				to_chat(affected_mob, span_danger("Ваше тело горит!"))
				if(prob(60))
					affected_mob.take_bodypart_damage(0, 2)
			if(prob(6))
				affected_mob.adjustToxLoss(15)
			if(prob(1))
				to_chat(affected_mob, span_danger("Вы пытаетесь закричать, но ничего не выходит!"))
				affected_mob.Stun(50)
