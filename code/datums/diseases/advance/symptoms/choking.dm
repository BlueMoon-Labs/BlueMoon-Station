/*
//////////////////////////////////////

Choking

	Very very noticable.
	Lowers resistance.
	Decreases stage speed.
	Decreases transmittablity tremendously.
	Moderate Level.

Bonus
	Inflicts spikes of oxyloss

//////////////////////////////////////
*/

/datum/symptom/choking

	name = "Choking"
	desc = "Вирус вызывает воспаление дыхательных путей хозяина, приводящее к периодическому удушью."
	stealth = -3
	resistance = 0
	stage_speed = -2
	transmittable = -2
	level = 3
	severity = 3
	base_message_chance = 15
	symptom_delay_min = 10
	symptom_delay_max = 30
	threshold_desc = list(
		"Stage Speed 8" = "Вызывает удушье чаще.",
		"Stealth 4" = "Симптом остаётся скрытым до активации."
	)

/datum/symptom/choking/Start(datum/disease/advance/A)
	if(!..())
		return
	if(A.properties["stage_rate"] >= 8)
		symptom_delay_min = 7
		symptom_delay_max = 24
	if(A.properties["stealth"] >= 4)
		suppress_warning = TRUE

/datum/symptom/choking/Activate(datum/disease/advance/A)
	if(!..() || HAS_TRAIT(A.affected_mob,TRAIT_NOBREATH))
		return
	var/mob/living/M = A.affected_mob
	switch(A.stage)
		if(1, 2)
			if(prob(base_message_chance) && !suppress_warning)
				to_chat(M, "<span class='warning'>[pick("Вам трудно дышать.", "Ваше дыхание становится тяжёлым.")]</span>")
		if(3, 4)
			if(!suppress_warning)
				to_chat(M, "<span class='warning'>[pick("Ваша трахея ощущается как соломинка.", "Дышать становится невероятно трудно.")]</span>")
			else
				to_chat(M, "<span class='warning'>Вы чувствуете себя очень [pick("головокружительным","слабым","дурным")].</span>") //fake bloodloss messages
			Choke_stage_3_4(M, A)
			M.emote("gasp")
		else
			to_chat(M, "<span class='userdanger'>[pick("Вы задыхаетесь!", "Вы не можете дышать!")]</span>")
			Choke(M, A)
			M.emote("gasp")

/datum/symptom/choking/proc/Choke_stage_3_4(mob/living/M, datum/disease/advance/A)
	M.adjustOxyLoss(rand(6,13))
	return TRUE

/datum/symptom/choking/proc/Choke(mob/living/M, datum/disease/advance/A)
	M.adjustOxyLoss(rand(10,18))
	return TRUE

/*
//////////////////////////////////////

Asphyxiation

	Very very noticable.
	Decreases stage speed.
	Decreases transmittablity.

Bonus
	Inflicts large spikes of oxyloss
	Introduces Asphyxiating drugs to the system
	Causes cardiac arrest on dying victims.

//////////////////////////////////////
*/

/datum/symptom/asphyxiation

	name = "Acute respiratory distress syndrome"
	desc = "Вирус вызывает сжатие лёгких хозяина, приводящее к тяжёлой асфиксии. Может также привести к сердечным приступам."
	stealth = -2
	resistance = 2
	stage_speed = -1
	transmittable = -2
	level = 7
	severity = 6
	base_message_chance = 15
	symptom_delay_min = 14
	symptom_delay_max = 30
	var/paralysis = FALSE
	threshold_desc = list(
		"Stage Speed 8" = "Дополнительно синтезирует панкуроний и тиопентал натрия в организме хозяина.",
		"Transmission 8" = "Удваивает урон, наносимый симптомом."
	)


/datum/symptom/asphyxiation/Start(datum/disease/advance/A)
	if(!..())
		return
	if(A.properties["stage_rate"] >= 8)
		paralysis = TRUE
	if(A.properties["transmittable"] >= 8)
		power = 2

/datum/symptom/asphyxiation/Activate(datum/disease/advance/A)
	if(!..() || HAS_TRAIT(A.affected_mob,TRAIT_NOBREATH))
		return
	var/mob/living/M = A.affected_mob
	switch(A.stage)
		if(3, 4)
			to_chat(M, "<span class='warning'><b>[pick("Ваша трахея ощущается тонкой.", "Ваши лёгкие ощущаются маленькими.")]</span>")
			Asphyxiate_stage_3_4(M, A)
			M.emote("gasp")
		if(5)
			to_chat(M, "<span class='userdanger'>[pick("Ваши лёгкие болят!", "Больно дышать!")]</span>")
			Asphyxiate(M, A)
			M.emote("gasp")
			if(M.getOxyLoss() >= 120)
				M.visible_message("<span class='warning'>[M] перестаёт дышать, будто его лёгкие полностью схлопнулись!</span>")
				Asphyxiate_death(M, A)
	return

/datum/symptom/asphyxiation/proc/Asphyxiate_stage_3_4(mob/living/M, datum/disease/advance/A)
	var/get_damage = rand(10,15) * power
	M.adjustOxyLoss(get_damage)
	return TRUE

/datum/symptom/asphyxiation/proc/Asphyxiate(mob/living/M, datum/disease/advance/A)
	var/get_damage = rand(15,21) * power
	M.adjustOxyLoss(get_damage)
	if(paralysis)
		M.reagents.add_reagent_list(list(/datum/reagent/toxin/pancuronium = 3, /datum/reagent/toxin/sodium_thiopental = 3))
	return TRUE

/datum/symptom/asphyxiation/proc/Asphyxiate_death(mob/living/M, datum/disease/advance/A)
	var/get_damage = rand(25,35) * power
	M.adjustOxyLoss(get_damage)
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, get_damage/2)
	return TRUE
