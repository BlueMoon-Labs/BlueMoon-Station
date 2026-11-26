/// Caused by dirty food. Makes you vomit stars.
/datum/disease/nebula_nausea
	name = "Nebula Nausea"
	desc = "Вы не можете сдержать красочную красоту космоса внутри."
	form = "Condition"
	agent = "Stars"
	cure_text = "Космический очиститель"
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
				to_chat(affected_mob, span_warning("Красочная красота космоса, кажется, сказалась на вашем равновесии."))
		if(3)
			if(prob(1) && affected_mob.stat == CONSCIOUS)
				to_chat(affected_mob, span_warning("Живот кружится цветами, невиданными человеческим глазом."))
		if(4)
			if(prob(1) && affected_mob.stat == CONSCIOUS)
				to_chat(affected_mob, span_warning("Кажется, вы плывёте сквозь водоворот небесных цветов."))
		if(5)
			if(prob(1) && affected_mob.stat == CONSCIOUS)
				to_chat(affected_mob, span_warning("Ваш живот превратился в бурную туманность, кружась калейдоскопическими узорами."))
			else
				affected_mob.vomit(10, FALSE, TRUE, 2)
