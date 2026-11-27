/datum/disease/magnitis
	name = "Magnitis"
	max_stages = 4
	spread_text = "Воздушно-капельный"
	cure_text = "Железо"
	cures = list(/datum/reagent/iron)
	agent = "Fukkos Miracos"
	viable_mobtypes = list(/mob/living/carbon/human)
	disease_flags = CAN_CARRY|CAN_RESIST|CURABLE
	permeability_mod = 0.75
	desc = "Эта болезнь нарушает магнитное поле тела, заставляя его действовать как мощный магнит. Инъекции железа помогают стабилизировать поле."
	severity = DISEASE_SEVERITY_MEDIUM
	infectable_biotypes = MOB_ORGANIC|MOB_ROBOTIC
	process_dead = TRUE

/datum/disease/magnitis/stage_act()
	..()
	switch(stage)
		if(2)
			if(prob(2))
				to_chat(affected_mob, "<span class='danger'>Вы чувствуете лёгкий удар током по телу.</span>")
			if(prob(2))
				for(var/obj/M in orange(2,affected_mob))
					if(!M.anchored && (M.flags_1 & CONDUCT_1))
						step_towards(M,affected_mob)
				for(var/mob/living/silicon/S in orange(2,affected_mob))
					if(isAI(S))
						continue
					step_towards(S,affected_mob)
		if(3)
			if(prob(2))
				to_chat(affected_mob, "<span class='danger'>Вы чувствуете сильный удар током по телу.</span>")
			if(prob(2))
				to_chat(affected_mob, "<span class='danger'>Вам хочется клоунады.</span>")
			if(prob(4))
				for(var/obj/M in orange(4,affected_mob))
					if(!M.anchored && (M.flags_1 & CONDUCT_1))
						var/i
						var/iter = rand(1,2)
						for(i=0,i<iter,i++)
							step_towards(M,affected_mob)
				for(var/mob/living/silicon/S in orange(4,affected_mob))
					if(isAI(S))
						continue
					var/i
					var/iter = rand(1,2)
					for(i=0,i<iter,i++)
						step_towards(S,affected_mob)
		if(4)
			if(prob(2))
				to_chat(affected_mob, "<span class='danger'>Вы чувствуете мощный удар током по телу.</span>")
			if(prob(2))
				to_chat(affected_mob, "<span class='danger'>Вы размышляете о природе чудес.</span>")
			if(prob(8))
				for(var/obj/M in orange(6,affected_mob))
					if(!M.anchored && (M.flags_1 & CONDUCT_1))
						var/i
						var/iter = rand(1,3)
						for(i=0,i<iter,i++)
							step_towards(M,affected_mob)
				for(var/mob/living/silicon/S in orange(6,affected_mob))
					if(isAI(S))
						continue
					var/i
					var/iter = rand(1,3)
					for(i=0,i<iter,i++)
						step_towards(S,affected_mob)
	return
