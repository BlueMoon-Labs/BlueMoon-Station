/datum/disease/cold9
	name = "The Cold"
	max_stages = 3
	spread_text = "При контакте"
	spread_flags = DISEASE_SPREAD_BLOOD | DISEASE_SPREAD_CONTACT_SKIN | DISEASE_SPREAD_CONTACT_FLUIDS
	cure_text = "Антитела простуды и спейсациллин"
	cures = list(/datum/reagent/medicine/spaceacillin)
	agent = "ICE9-rhinovirus"
	viable_mobtypes = list(/mob/living/carbon/human)
	desc = "Если не лечить, субъект замедлится, как будто частично замёрз."
	severity = DISEASE_SEVERITY_HARMFUL

/datum/disease/cold9/stage_act()
	..()
	switch(stage)
		if(2)
			affected_mob.adjust_bodytemperature(-10)
			if(prob(1) && prob(10))
				to_chat(affected_mob, "<span class='notice'>Вы чувствуете себя лучше.</span>")
				cure()
				return
			if(prob(1))
				affected_mob.emote("sneeze")
			if(prob(1))
				affected_mob.emote("cough")
			if(prob(1))
				to_chat(affected_mob, "<span class='danger'>Ваше горло болит.</span>")
			if(prob(5))
				to_chat(affected_mob, "<span class='danger'>Вы чувствуете скованность.</span>")
		if(3)
			affected_mob.adjust_bodytemperature(-20)
			if(prob(1))
				affected_mob.emote("sneeze")
			if(prob(1))
				affected_mob.emote("cough")
			if(prob(1))
				to_chat(affected_mob, "<span class='danger'>Ваше горло болит.</span>")
			if(prob(10))
				to_chat(affected_mob, "<span class='danger'>Вы чувствуете скованность.</span>")
