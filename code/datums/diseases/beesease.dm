/datum/disease/beesease
	name = "Beesease"
	form = "Infection"
	max_stages = 4
	spread_text = "При контакте"
	spread_flags = DISEASE_SPREAD_BLOOD | DISEASE_SPREAD_CONTACT_SKIN | DISEASE_SPREAD_CONTACT_FLUIDS
	cure_text = "Сахар"
	cures = list(/datum/reagent/consumable/sugar)
	agent = "Заражение пчёлами"
	viable_mobtypes = list(/mob/living/carbon/human, /mob/living/carbon/monkey)
	desc = "Если не лечить, субъект будет отрыгивать пчёл."
	severity = DISEASE_SEVERITY_MEDIUM
	infectable_biotypes = MOB_ORGANIC|MOB_UNDEAD //bees nesting in corpses

/datum/disease/beesease/stage_act()
	..()
	switch(stage)
		if(2) //also changes say, see say.dm
			if(prob(2))
				to_chat(affected_mob, "<span class='notice'>Вы чувствуете мёд во рту.</span>")
		if(3)
			if(prob(10))
				to_chat(affected_mob, "<span class='notice'>Ваш живот урчит.</span>")
			if(prob(2))
				to_chat(affected_mob, "<span class='danger'>Ваш живот болезненно жжёт.</span>")
				if(prob(20))
					affected_mob.adjustToxLoss(2)
					affected_mob.updatehealth()
		if(4)
			if(prob(10))
				affected_mob.visible_message("<span class='danger'>[affected_mob] жужжит.</span>", \
												"<span class='userdanger'>Ваш живот яростно жужжит!</span>")
			if(prob(5))
				to_chat(affected_mob, "<span class='danger'>Вы чувствуете, как что-то движется в горле.</span>")
			if(prob(1))
				affected_mob.visible_message("<span class='danger'>[affected_mob] отрыгивает рой пчёл!</span>", \
													"<span class='userdanger'>Вы отрыгиваете рой пчёл!</span>")
				new /mob/living/simple_animal/hostile/poison/bees(affected_mob.loc)
	return
