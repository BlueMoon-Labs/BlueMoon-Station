/datum/disease/crabcancer
	name = "Crab Cancer"
	form = "Рак кожи"
	max_stages = 3
	cure_text = "Мутадон"
	spread_text = "Не заразно"
	cures = list(/datum/reagent/medicine/mutadone)
	agent = "Carcinisoprojection Jelly"
	viable_mobtypes = list(/mob/living/carbon/human, /mob/living/carbon/monkey)
	permeability_mod = 1
	desc = "Если не лечить, пациент быстро и болезненно отрастит плоть, которая будет отваливаться. Это может привести к смерти, если не следить."
	severity = DISEASE_SEVERITY_DANGEROUS
	spread_flags = DISEASE_SPREAD_NON_CONTAGIOUS
	visibility_flags = HIDDEN_PANDEMIC
	bypasses_immunity = TRUE

/datum/disease/crabcancer/stage_act()
	..()
	switch(stage)
		if(1)
			if(prob(10))
				to_chat(affected_mob, "<span class='warning'>" + pick("Вам неудобно.",
				"Вы чувствуете пульсацию в руках и ногах.",
				"Вы чувствуете... крабовость.",
				"От вас начинает пахнуть морепродуктами.") + "</span>")
		if(2)
			if(prob(10))
				to_chat(affected_mob, "<span class='danger'>" + pick("Ваша плоть начинает выглядеть деформированной.",
				"Вы чувствуете, как плоть пузырится и вздувается.",
				"Вам кажется, что из плоти торчат клешни.",
				"Настало время краба...") + "</span>")
		if(3)
			if(prob(5))
				to_chat(affected_mob, "<span class='danger'>" + pick("Кожа покрывается чёрными грубыми пятнами!",
				"Боль невыносима!",
				"На коже образуются болезненные кисты!") + "</span>")
				affected_mob.take_bodypart_damage(rand(1,5))
			if(prob(5))
				affected_mob.visible_message("<span class='danger'>Плоть [affected_mob] вздувается и отрывается от \him!</span>", \
				"<span class='userdanger'>" + pick("Вы чувствуете, как плоть вздувается и отрывается от вас!",
				"Ваша плоть растёт и падает под вами!",
				"Боль... крабовое мясо отваливается от вас!",
				"Ваша плоть... она рвётся!",
				"Настало время краба!") + "</span>",
				"<span class='italics'>Вы слышите отвратительный чавкающий звук разрывающейся плоти.</span>")
				playsound(affected_mob, 'sound/items/poster_ripped.ogg', 50, TRUE)
				playsound(get_turf(affected_mob), 'sound/effects/splat.ogg', 20, TRUE)
				if(!HAS_TRAIT(affected_mob, TRAIT_ROBOTIC_ORGANISM)) // BLUEMOON ADD - роботы не кричат от боли
					affected_mob.emote("scream")
				affected_mob.take_bodypart_damage(rand(15,25))
				var/humanmeatamount = rand(0,2)
				var/crabmeatamount = rand(1,2)
				var/meattype = /obj/item/reagent_containers/food/snacks/meat/slab/human
				if(ishuman(affected_mob))
					meattype = affected_mob.dna.species.meat
				else //grab the carbon's meat instead (usually this means monkey meat... though other disease-compatible carbon mobs might apply.)
					meattype = affected_mob.type_of_meat

				if(humanmeatamount)
					for(var/i=1 to humanmeatamount)
						var/obj/item/reagent_containers/food/snacks/meat/slab/newmeat = new meattype
						newmeat.name = "[affected_mob.real_name] [newmeat.name]"
						newmeat.forceMove(affected_mob.loc)
				if(crabmeatamount)
					for(var/i=1 to crabmeatamount)
						new /obj/item/reagent_containers/food/snacks/meat/rawcrab(affected_mob.loc)
				affected_mob.jitteriness += 3

