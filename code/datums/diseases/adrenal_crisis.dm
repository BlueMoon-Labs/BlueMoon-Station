/datum/disease/adrenal_crisis
	form = "Condition"
	name = "Adrenal Crisis"
	max_stages = 2
	cure_text = "Trauma"
	cures = list(/datum/reagent/determination)
	cure_chance = 10
	agent = "Shitty Adrenal Glands"
	viable_mobtypes = list(/mob/living/carbon/human)
	permeability_mod = 1
	desc = "If left untreated the subject will suffer from lethargy, dizziness and periodic loss of consciousness."
	severity = DISEASE_SEVERITY_MEDIUM
	spread_flags = DISEASE_SPREAD_NON_CONTAGIOUS
	spread_text = "Organ failure"
	visibility_flags = HIDDEN_PANDEMIC
	bypasses_immunity = TRUE

/datum/disease/adrenal_crisis/stage_act()
	. = ..()
	if(!.)
		return

	switch(stage)
		if(1)
			if(prob(2))
				to_chat(affected_mob, span_warning(pick("You feel lightheaded.", "You feel lethargic.")))
		if(2)
			if(prob(5))
				affected_mob.Unconscious(40)

			if(prob(10))
				affected_mob.slurring = max(affected_mob.slurring, 140)

			if(prob(7))
				affected_mob.Dizzy(200)

			if(prob(2))
				to_chat(affected_mob, span_warning(pick("You feel pain shoot down your legs!", "You feel like you are going to pass out at any moment.", "You feel really dizzy.")))
