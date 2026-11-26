/*
//////////////////////////////////////

Primal Regression (Monkey Transformation)

	Noticeable.
	Lowers resistance.
	Decreases transmittability.
	Fatal/Transformation Level.

Bonus
	At stage 5, transforms the host into a monkey. Used by sentient disease antagonist.

//////////////////////////////////////
*/

/datum/symptom/monkey_transform
	name = "Primal Regression"
	desc = "Вирус переписывает геном хозяина в более примитивную форму, в итоге превращая его в обезьяну."
	stealth = -2
	resistance = -2
	stage_speed = 0
	transmittable = -3
	level = 6
	severity = 5
	naturally_occuring = FALSE
	base_message_chance = 30
	symptom_delay_min = 30
	symptom_delay_max = 80
	threshold_desc = list(
		"Скорость стадии 8" = "Превращение происходит раньше.",
	)

/datum/symptom/monkey_transform/Activate(datum/disease/advance/A)
	if(!..())
		return
	var/mob/living/carbon/M = A.affected_mob
	switch(A.stage)
		if(3, 4)
			if(prob(base_message_chance))
				to_chat(M, "<span class='warning'>[pick("У вас болит спина.", "Вам хочется бананов.", "Ваш разум затуманен.")]</span>")
		if(5)
			if(ishuman(M))
				to_chat(M, "<span class='userdanger'>Вам хочется пообезьянничать!</span>")
				if(M.mind && !is_monkey(M.mind))
					var/datum/antagonist/monkey/monkey_antag = new
					monkey_antag.monkey_only = FALSE
					M.mind.add_antag_datum(monkey_antag)
				M.monkeyize(TR_KEEPITEMS | TR_KEEPIMPLANTS | TR_KEEPORGANS | TR_KEEPDAMAGE | TR_KEEPVIRUS | TR_KEEPSE)
			else if(ismonkey(M) && !SEND_SIGNAL(M, COMSIG_CHECK_VENTCRAWL))
				M.AddElement(/datum/element/ventcrawling, given_tier = VENTCRAWLER_ALWAYS)
