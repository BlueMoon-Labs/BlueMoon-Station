/datum/disease/anxiety
	name = "Severe Anxiety"
	form = "Infection"
	max_stages = 4
	spread_text = "При контакте"
	spread_flags = DISEASE_SPREAD_BLOOD | DISEASE_SPREAD_CONTACT_SKIN | DISEASE_SPREAD_CONTACT_FLUIDS
	cure_text = "Этанол"
	cures = list(/datum/reagent/consumable/ethanol)
	agent = "Избыток лепидоптицидов"
	viable_mobtypes = list(/mob/living/carbon/human, /mob/living/carbon/monkey)
	desc = "Если не лечить, субъект будет отрыгивать бабочек."
	severity = DISEASE_SEVERITY_MINOR

/datum/disease/anxiety/stage_act()
	..()
	if(!affected_mob)
		return
	switch(stage)
		if(2) //also changes say, see say.dm
			if(prob(5))
				to_chat(affected_mob, "<span class='notice'>Вы чувствуете тревогу.</span>")
		if(3)
			if(prob(10))
				to_chat(affected_mob, "<span class='notice'>Ваш живот трепещет.</span>")
			if(prob(5))
				to_chat(affected_mob, "<span class='notice'>Вы чувствуете панику.</span>")
			if(prob(2))
				to_chat(affected_mob, "<span class='danger'>Вас охватывает паника!</span>")
				affected_mob.confused += (rand(2,3))
		if(4)
			if(prob(10))
				to_chat(affected_mob, "<span class='danger'>Вы чувствуете бабочек в животе.</span>")
			if(prob(5))
				affected_mob.visible_message("<span class='danger'>[affected_mob] шатается в панике.</span>", \
												"<span class='userdanger'>У вас паническая атака!</span>")
				affected_mob.confused += (rand(6,8))
				affected_mob.jitteriness += (rand(6,8))
			if(prob(2))
				affected_mob.visible_message("<span class='danger'>[affected_mob] отрыгивает бабочек!</span>", \
													"<span class='userdanger'>Вы отрыгиваете бабочек!</span>")
				new /mob/living/simple_animal/butterfly(affected_mob.loc)
				new /mob/living/simple_animal/butterfly(affected_mob.loc)
	return
