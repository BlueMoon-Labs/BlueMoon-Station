/datum/disease/flu
	name = "The Flu"
	max_stages = 3
	spread_text = "Воздушно-капельный"
	cure_text = "Спейсациллин"
	cures = list(/datum/reagent/medicine/spaceacillin)
	cure_chance = 10
	agent = "H13N1 flu virion"
	viable_mobtypes = list(/mob/living/carbon/human, /mob/living/carbon/monkey)
	permeability_mod = 0.75
	desc = "Если не лечить, субъект будет чувствовать себя довольно плохо."
	severity = DISEASE_SEVERITY_MINOR

/datum/disease/flu/stage_act()
	..()
	switch(stage)
		if(2)
			if(affected_mob.lying && prob(20))
				to_chat(affected_mob, "<span class='notice'>Вы чувствуете себя лучше.</span>")
				stage--
				return
			if(prob(1))
				affected_mob.emote("sneeze")
			if(prob(1))
				affected_mob.emote("cough")
			if(prob(1))
				to_chat(affected_mob, "<span class='danger'>У вас болят мышцы.</span>")
				if(prob(20))
					affected_mob.take_bodypart_damage(1)
			if(prob(1))
				to_chat(affected_mob, "<span class='danger'>У вас болит живот.</span>")
				if(prob(20))
					affected_mob.adjustToxLoss(1)
					affected_mob.updatehealth()

		if(3)
			if(affected_mob.lying && prob(15))
				to_chat(affected_mob, "<span class='notice'>Вы чувствуете себя лучше.</span>")
				stage--
				return
			if(prob(1))
				affected_mob.emote("sneeze")
			if(prob(1))
				affected_mob.emote("cough")
			if(prob(1))
				to_chat(affected_mob, "<span class='danger'>У вас болят мышцы.</span>")
				if(prob(20))
					affected_mob.take_bodypart_damage(1)
			if(prob(1))
				to_chat(affected_mob, "<span class='danger'>У вас болит живот.</span>")
				if(prob(20))
					affected_mob.adjustToxLoss(1)
					affected_mob.updatehealth()
	return
