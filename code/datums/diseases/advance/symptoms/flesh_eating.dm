/*
//////////////////////////////////////

Necrotizing Fasciitis (AKA Flesh-Eating Disease)

	Very very noticable.
	Lowers resistance tremendously.
	No changes to stage speed.
	Decreases transmittablity temrendously.
	Fatal Level.

Bonus
	Deals brute damage over time.

//////////////////////////////////////
*/

/datum/symptom/flesh_eating

	name = "Necrotizing Fasciitis"
	desc = "Вирус агрессивно атакует клетки тела, некротизируя ткани и органы."
	stealth = -3
	resistance = -2
	stage_speed = 0
	transmittable = -3
	level = 6
	severity = 5
	base_message_chance = 50
	symptom_delay_min = 15
	symptom_delay_max = 60
	var/bleed = FALSE
	var/pain = FALSE
	threshold_desc = list(
		"Сопротивление 7" = "Разъедает кожу хозяина, вызывая обильное кровотечение.",
		"Передача 8" = "Разъедает мышечную массу хозяина, вызывая повышенную усталость."
	)

/datum/symptom/flesh_eating/Start(datum/disease/advance/A)
	if(!..())
		return
	if(A.properties["resistance"] >= 7) //extra bleeding
		bleed = TRUE
	if(A.properties["transmittable"] >= 8) //extra stamina damage
		pain = TRUE

/datum/symptom/flesh_eating/Activate(datum/disease/advance/A)
	if(!..())
		return
	var/mob/living/M = A.affected_mob
	switch(A.stage)
		if(2,3)
			if(prob(base_message_chance))
				to_chat(M, "<span class='warning'>[pick("Вы чувствуете внезапную боль по всему телу.", "На коже внезапно появляются капли крови.")]</span>")
		if(4,5)
			to_chat(M, "<span class='userdanger'>[pick("Вы корчитесь от сильной боли, охватывающей тело.", "Кажется, ваше тело пожирает себя изнутри.", "ЭТО БОЛЬНО.")]</span>")
			Flesheat(M, A)

/datum/symptom/flesh_eating/proc/Flesheat(mob/living/M, datum/disease/advance/A)
	var/get_damage = rand(15,25) * power
	M.adjustBruteLoss(get_damage)
	if(pain)
		M.adjustStaminaLoss(get_damage)
	if(bleed)
		if(ishuman(M))
			var/mob/living/carbon/human/H = M
			var/obj/item/bodypart/random_part = pick(H.bodyparts)
			random_part.generic_bleedstacks += 5 * power
	return TRUE

/*
//////////////////////////////////////

Autophagocytosis (AKA Programmed mass cell death)

	Very noticable.
	Lowers resistance.
	Fast stage speed.
	Decreases transmittablity.
	Fatal Level.

Bonus
	Deals brute damage over time.

//////////////////////////////////////
*/

/datum/symptom/flesh_death
	name = "Autophagocytosis Necrosis"
	desc = "Вирус быстро поглощает заражённые клетки, приводя к тяжёлым и обширным повреждениям."
	stealth = -2
	resistance = -2
	stage_speed = 1
	transmittable = -2
	level = 7
	severity = 6
	base_message_chance = 50
	symptom_delay_min = 3
	symptom_delay_max = 6
	var/chems = FALSE
	var/zombie = FALSE
	threshold_desc = list(
		"Скорость стадий 7" = "Синтезирует гепарин и липолицид в организме хозяина, вызывая усиленное кровотечение и голод.",
		"Скрытность 5" = "Симптом остаётся скрытым до активации.",
	)


/datum/symptom/flesh_death/Start(datum/disease/advance/A)
	if(!..())
		return
	if(A.properties["stealth"] >= 5)
		suppress_warning = TRUE
	if(A.properties["stage_rate"] >= 7) //bleeding and hunger
		chems = TRUE

/datum/symptom/flesh_death/Activate(datum/disease/advance/A)
	if(!..())
		return
	var/mob/living/M = A.affected_mob
	switch(A.stage)
		if(2,3)
			if(prob(base_message_chance) && !suppress_warning)
				to_chat(M, "<span class='warning'>[pick("Вы чувствуете, как ваше тело распадается.", "Ваша кожа слезает, как пыль.")]</span>")
		if(4,5)
			if(prob(base_message_chance / 2)) //reduce spam
				to_chat(M, "<span class='userdanger'>[pick("Вы чувствуете ослабление мышц.", "Часть вашей кожи отслаивается.", "Вы чувствуете себя песчаным.")]</span>")
			Flesh_death(M, A)

/datum/symptom/flesh_death/proc/Flesh_death(mob/living/M, datum/disease/advance/A)
	var/get_damage = rand(6,10)
	M.adjustBruteLoss(get_damage)
	if(chems)
		M.reagents.add_reagent_list(list(/datum/reagent/toxin/heparin = 2, /datum/reagent/toxin/lipolicide = 2))
	if(zombie)
		M.reagents.add_reagent(/datum/reagent/romerol, 1)
	return TRUE
