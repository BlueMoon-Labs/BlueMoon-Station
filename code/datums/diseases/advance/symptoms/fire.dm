/*
//////////////////////////////////////

Spontaneous Combustion

	Slightly hidden.
	Lowers resistance tremendously.
	Decreases stage tremendously.
	Decreases transmittablity tremendously.
	Fatal Level.

Bonus
	Ignites infected mob.

//////////////////////////////////////
*/

/datum/symptom/fire

	name = "Spontaneous Combustion"
	desc = "Вирус превращает жир в чрезвычайно воспламеняющееся вещество и повышает температуру тела, заставляя хозяина самовозгораться."
	stealth = -1
	resistance = -2
	stage_speed = -3
	transmittable = -4
	level = 6
	severity = 5
	base_message_chance = 20
	symptom_delay_min = 20
	symptom_delay_max = 75
	var/infective = FALSE
	threshold_desc = list(
		"Скорость стадий 4" = "Увеличивает интенсивность пламени.",
		"Скорость стадий 8" = "Дополнительно увеличивает интенсивность пламени.",
		"Передача 8" = "Хозяин будет распространять вирус через чешуйки кожи при самовозгорании.",
		"Скрытность 4" = "Симптом остаётся скрытым до активации.",
	)
/datum/symptom/fire/Start(datum/disease/advance/A)
	if(!..())
		return
	if(A.properties["stage_rate"] >= 4)
		power = 1.5
	if(A.properties["stage_rate"] >= 8)
		power = 2
	if(A.properties["stealth"] >= 4)
		suppress_warning = TRUE
	if(A.properties["transmittable"] >= 8) //burning skin spreads the virus through smoke
		infective = TRUE

/datum/symptom/fire/Activate(datum/disease/advance/A)
	if(!..())
		return
	var/mob/living/M = A.affected_mob
	switch(A.stage)
		if(3)
			if(prob(base_message_chance) && !suppress_warning)
				to_chat(M, "<span class='warning'>[pick("Вам жарко.", "Вы слышите потрескивание.", "Вы чувствуете запах дыма.")]</span>")
		if(4)
			Firestacks_stage_4(M, A)
			M.IgniteMob()
			to_chat(M, "<span class='userdanger'>Ваша кожа вспыхивает!</span>")
			if(!HAS_TRAIT(M, TRAIT_ROBOTIC_ORGANISM)) // BLUEMOON ADD - роботы не кричат от боли
				M.emote("scream")
		if(5)
			Firestacks_stage_5(M, A)
			M.IgniteMob()
			to_chat(M, "<span class='userdanger'>Ваша кожа превращается в инферно!</span>")
			if(!HAS_TRAIT(M, TRAIT_ROBOTIC_ORGANISM)) // BLUEMOON ADD - роботы не кричат от боли
				M.emote("realagony")

/datum/symptom/fire/proc/Firestacks_stage_4(mob/living/M, datum/disease/advance/A)
	M.adjust_fire_stacks(1 * power)
	M.adjustFireLoss(3 * power)
	if(infective)
		A.spread(2)
	return TRUE

/datum/symptom/fire/proc/Firestacks_stage_5(mob/living/M, datum/disease/advance/A)
	M.adjust_fire_stacks(3 * power)
	M.adjustFireLoss(5 * power)
	if(infective)
		A.spread(4)
	return TRUE

/*
//////////////////////////////////////

Alkali perspiration

	Hidden.
	Lowers resistance.
	Decreases stage speed.
	Decreases transmittablity.
	Fatal Level.

Bonus
	Ignites infected mob.
	Explodes mob on contact with water.

//////////////////////////////////////
*/

/datum/symptom/alkali
	name = "Alkali perspiration"
	desc = "Вирус прикрепляется к потовым железам, синтезируя вещество, которое вспыхивает при контакте с водой, приводя к самовозгоранию."
	stealth = 2
	resistance = -2
	stage_speed = -2
	transmittable = -2
	level = 7
	severity = 6
	base_message_chance = 100
	symptom_delay_min = 30
	symptom_delay_max = 90
	var/chems = FALSE
	var/explosion_power = 1
	threshold_desc = list("Сопротивление 9" = "Удваивает интенсивность эффекта, но снижает его частоту.",
					  "Скорость стадий 8" = "Увеличивает радиус взрыва, если хозяин мокрый.",
					  "Передача 8" = "Дополнительно синтезирует трифторид хлора и напалм в организме хозяина.")

/datum/symptom/alkali/Start(datum/disease/advance/A)
	if(!..())
		return
	if(A.properties["resistance"] >= 9) //intense but sporadic effect
		power = 2
		symptom_delay_min = 50
		symptom_delay_max = 140
	if(A.properties["stage_rate"] >= 8) //serious boom when wet
		explosion_power = 2
	if(A.properties["transmittable"] >= 8) //extra chemicals
		chems = TRUE

/datum/symptom/alkali/Activate(datum/disease/advance/A)
	if(!..())
		return
	var/mob/living/M = A.affected_mob
	switch(A.stage)
		if(3)
			if(prob(base_message_chance))
				to_chat(M, "<span class='warning'>[pick("Ваши вены кипят.", "Вам жарко.", "Вы чувствуете запах жарящегося мяса.")]</span>")
		if(4)
			Alkali_fire_stage_4(M, A)
			M.IgniteMob()
			to_chat(M, "<span class='userdanger'>Ваш пот вспыхивает!</span>")
			if(!HAS_TRAIT(M, TRAIT_ROBOTIC_ORGANISM)) // BLUEMOON ADD - роботы не кричат от боли
				M.emote("scream")
		if(5)
			Alkali_fire_stage_5(M, A)
			M.IgniteMob()
			to_chat(M, "<span class='userdanger'>Ваша кожа превращается в инферно!</span>")
			if(!HAS_TRAIT(M, TRAIT_ROBOTIC_ORGANISM)) // BLUEMOON ADD - роботы не кричат от боли
				M.emote("realagony")
			if(M.fire_stacks < 0)
				M.visible_message("<span class='warning'>Пот [M] шипит и трещит при контакте с водой!</span>")
				explosion(get_turf(M),0,0,2 * explosion_power)
				Alkali_fire_stage_5(M, A)

/datum/symptom/alkali/proc/Alkali_fire_stage_4(mob/living/M, datum/disease/advance/A)
	var/get_stacks = 6 * power
	M.adjust_fire_stacks(get_stacks)
	M.adjustFireLoss(get_stacks/2)
	if(chems)
		M.reagents.add_reagent(/datum/reagent/clf3, 2 * power)
	return TRUE

/datum/symptom/alkali/proc/Alkali_fire_stage_5(mob/living/M, datum/disease/advance/A)
	var/get_stacks = 8 * power
	M.adjust_fire_stacks(get_stacks)
	M.adjustFireLoss(get_stacks)
	if(chems)
		M.reagents.add_reagent_list(list(/datum/reagent/napalm = 4 * power, /datum/reagent/clf3 = 4 * power))
	return TRUE
