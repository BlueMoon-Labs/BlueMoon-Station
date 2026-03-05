/// Caused by dirty food. Makes you vomit stars.
/datum/disease/nebula_nausea
	name = "Nebula Nausea"
	desc = "You can't contain the colorful beauty of the cosmos inside."
	form = "Condition"
	agent = "Stars"
	cure_text = "Space Cleaner"
	cures = list(/datum/reagent/space_cleaner)
	viable_mobtypes = list(/mob/living/carbon/human)
	spread_flags = DISEASE_SPREAD_NON_CONTAGIOUS
	severity = DISEASE_SEVERITY_MEDIUM
	required_organs = list(/obj/item/organ/stomach)
	max_stages = 5

/datum/disease/nebula_nausea/stage_act()
	. = ..()
	if(!.)
		return

	switch(stage)
		if(2)
			if(prob(1) && affected_mob.stat == CONSCIOUS)
				to_chat(affected_mob, span_warning("The colorful beauty of the cosmos seems to have taken a toll on your equilibrium."))
		if(3)
			if(prob(1) && affected_mob.stat == CONSCIOUS)
				to_chat(affected_mob, span_warning("Your stomach swirls with colors unseen by human eyes."))
		if(4)
			if(prob(1) && affected_mob.stat == CONSCIOUS)
				to_chat(affected_mob, span_warning("It feels like you're floating through a maelstrom of celestial colors."))
		if(5)
			if(prob(1) && affected_mob.stat == CONSCIOUS)
				to_chat(affected_mob, span_warning("Your stomach has become a turbulent nebula, swirling with kaleidoscopic patterns."))
			else
				affected_mob.vomit(10, FALSE, TRUE, 2)
