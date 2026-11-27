/datum/disease/decloning
	form = "Virus"
	name = "Cellular Degeneration"
	max_stages = 5
	stage_prob = 0.5
	cure_text = "Резадон, мутадон для продления или смерть."
	agent = "Сильное генетическое повреждение"
	viable_mobtypes = list(/mob/living/carbon/human)
	desc = @"Если не лечить, субъект [REDACTED]!"
	severity = "Dangerous!"
	cures = list(/datum/reagent/medicine/rezadone)
	spread_flags = DISEASE_SPREAD_NON_CONTAGIOUS
	spread_text = "Органический распад"
	process_dead = TRUE
	bypasses_immunity = TRUE

/datum/disease/decloning/cure(add_resistance = TRUE)
	affected_mob.remove_status_effect(/datum/status_effect/decloning)
	return ..()

/datum/disease/decloning/stage_act()
	. = ..()
	if(!.)
		return

	if(affected_mob.stat == DEAD)
		cure()
		return

	switch(stage)
		if(2)
			if(prob(1))
				affected_mob.emote("itch")
			if(prob(1))
				affected_mob.emote("yawn")
		if(3)
			if(prob(1))
				affected_mob.emote("itch")
			if(prob(1))
				affected_mob.emote("drool")
			if(prob(1))
				affected_mob.apply_status_effect(/datum/status_effect/decloning)
			if(prob(1))
				to_chat(affected_mob, span_danger("Ваша кожа ощущается странно."))
		if(4)
			if(prob(1))
				affected_mob.emote("itch")
			if(prob(1))
				affected_mob.emote("drool")
			if(prob(2))
				affected_mob.apply_status_effect(/datum/status_effect/decloning)
				affected_mob.adjustOrganLoss(ORGAN_SLOT_BRAIN, 1, 170)
			if(prob(7))
				affected_mob.stuttering = max(affected_mob.stuttering, 60)
		if(5)
			if(prob(1))
				affected_mob.emote("itch")
			if(prob(1))
				affected_mob.emote("drool")
			if(prob(2))
				to_chat(affected_mob, span_danger("Ваша кожа начинает разрушаться!"))
			if(prob(5))
				affected_mob.apply_status_effect(/datum/status_effect/decloning)
				affected_mob.adjustOrganLoss(ORGAN_SLOT_BRAIN, 2, 170)
