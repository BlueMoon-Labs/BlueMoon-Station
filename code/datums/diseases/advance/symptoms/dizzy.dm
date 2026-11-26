/*
//////////////////////////////////////

Dizziness

	Hidden.
	Lowers resistance considerably.
	Decreases stage speed.
	Reduced transmittability
	Intense Level.

Bonus
	Shakes the affected mob's screen for short periods.

//////////////////////////////////////
*/

/datum/symptom/dizzy // Not the egg

	name = "Dizziness"
	desc = "Вирус вызывает воспаление вестибулярной системы, приводящее к приступам головокружения."
	resistance = -2
	stage_speed = -3
	transmittable = -1
	level = 4
	severity = 2
	base_message_chance = 50
	symptom_delay_min = 15
	symptom_delay_max = 40
	threshold_desc = list(
		"Transmission 6" = "Также вызывает дурманящее зрение.",
		"Stealth 4" = "Симптом остаётся скрытым до активации.",
	)

/datum/symptom/dizzy/Start(datum/disease/advance/A)
	if(!..())
		return
	if(A.properties["stealth"] >= 4)
		suppress_warning = TRUE
	if(A.properties["transmittable"] >= 6) //druggy
		power = 2

/datum/symptom/dizzy/Activate(datum/disease/advance/A)
	if(!..())
		return
	var/mob/living/M = A.affected_mob
	switch(A.stage)
		if(1, 2, 3, 4)
			if(prob(base_message_chance) && !suppress_warning)
				to_chat(M, "<span class='warning'>[pick("Вам кружится голова.", "Ваша голова кружится.")]</span>")
		else
			to_chat(M, "<span class='userdanger'>На вас накатывает волна головокружения!</span>")
			M.Dizzy(5)
			if(power >= 2)
				M.set_drugginess(5)
