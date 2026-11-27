/datum/disease/dna_retrovirus
	name = "Retrovirus"
	max_stages = 4
	spread_text = "Контакт"
	spread_flags = DISEASE_SPREAD_BLOOD | DISEASE_SPREAD_CONTACT_SKIN | DISEASE_SPREAD_CONTACT_FLUIDS
	cure_text = "Отдых или инъекция мутадона"
	cure_chance = 6
	agent = ""
	viable_mobtypes = list(/mob/living/carbon/human)
	desc = "Ретровирус, изменяющий ДНК, постоянно сбивает структурные и уникальные ферменты хозяина."
	severity = DISEASE_SEVERITY_HARMFUL
	permeability_mod = 0.4
	stage_prob = 2
	var/restcure = 0

/datum/disease/dna_retrovirus/New(make_typecache = TRUE)
	..()
	agent = "Virus class [pick("A","B","C","D","E","F")][pick("A","B","C","D","E","F")]-[rand(50,300)]"
	if(prob(40))
		cures = list(/datum/reagent/medicine/mutadone)
	else
		restcure = 1

/datum/disease/dna_retrovirus/Copy()
	var/datum/disease/dna_retrovirus/D = ..()
	D.restcure = restcure
	return D

/datum/disease/dna_retrovirus/stage_act()
	..()
	switch(stage)
		if(1)
			if(restcure)
				if(affected_mob.lying && prob(30))
					to_chat(affected_mob, "<span class='notice'>Вы чувствуете себя лучше.</span>")
					cure()
					return
			if (prob(8))
				to_chat(affected_mob, "<span class='danger'>У вас болит голова.</span>")
			if (prob(9))
				to_chat(affected_mob, "Вы чувствуете покалывание в груди.")
			if (prob(9))
				to_chat(affected_mob, "<span class='danger'>Вы чувствуете гнев.</span>")
		if(2)
			if(restcure)
				if(affected_mob.lying && prob(20))
					to_chat(affected_mob, "<span class='notice'>Вы чувствуете себя лучше.</span>")
					cure()
					return
			if (prob(8))
				to_chat(affected_mob, "<span class='danger'>Кожа ощущается свободной.</span>")
			if (prob(10))
				to_chat(affected_mob, "Вы чувствуете себя очень странно.")
			if (prob(4))
				to_chat(affected_mob, "<span class='danger'>Вы чувствуете колющую боль в голове!</span>")
				affected_mob.Unconscious(40)
			if (prob(4))
				to_chat(affected_mob, "<span class='danger'>Желудок сжимается.</span>")
		if(3)
			if(restcure)
				if(affected_mob.lying && prob(20))
					to_chat(affected_mob, "<span class='notice'>Вы чувствуете себя лучше.</span>")
					cure()
					return
			if (prob(10))
				to_chat(affected_mob, "<span class='danger'>Всё тело вибрирует.</span>")

			if (prob(35))
				if(prob(50))
					scramble_dna(affected_mob, 1, 0, rand(15,45))
				else
					scramble_dna(affected_mob, 0, 1, rand(15,45))

		if(4)
			if(restcure)
				if(affected_mob.lying && prob(5))
					to_chat(affected_mob, "<span class='notice'>Вы чувствуете себя лучше.</span>")
					cure()
					return
			if (prob(60))
				if(prob(50))
					scramble_dna(affected_mob, 1, 0, rand(50,75))
				else
					scramble_dna(affected_mob, 0, 1, rand(50,75))
