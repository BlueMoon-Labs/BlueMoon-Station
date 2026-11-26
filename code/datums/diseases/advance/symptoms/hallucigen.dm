/*
//////////////////////////////////////

Hallucigen

	Very noticable.
	Lowers resistance considerably.
	Decreases stage speed.
	Reduced transmittable.
	Critical Level.

Bonus
	Makes the affected mob be hallucinated for short periods of time.

//////////////////////////////////////
*/

/datum/symptom/hallucigen
	name = "Hallucigen"
	desc = "Вирус стимулирует мозг, вызывая периодические галлюцинации."
	stealth = -1
	resistance = -3
	stage_speed = -3
	transmittable = -1
	level = 5
	severity = 2
	base_message_chance = 25
	symptom_delay_min = 25
	symptom_delay_max = 90
	var/fake_healthy = FALSE
	threshold_desc = list(
		"Stage Speed 7" = "Увеличивает количество галлюцинаций.",
		"Stealth 4" = "Вирус имитирует положительные симптомы.",
	)

/datum/symptom/hallucigen/Start(datum/disease/advance/A)
	if(!..())
		return
	if(A.properties["stealth"] >= 4) //fake good symptom messages
		fake_healthy = TRUE
		base_message_chance = 50
	if(A.properties["stage_rate"] >= 7) //stronger hallucinations
		power = 2

/datum/symptom/hallucigen/Activate(datum/disease/advance/A)
	if(!..())
		return
	var/mob/living/carbon/M = A.affected_mob
	var/list/healthy_messages = list("Ваши лёгкие чувствуют себя отлично.", "Вы понимаете, что не дышали.", "Вы не чувствуете потребности дышать.",\
					"Ваши глаза чувствуют себя отлично.", "Теперь вы моргаете вручную.", "Вы не чувствуете потребности моргать.")
	switch(A.stage)
		if(1, 2)
			if(prob(base_message_chance))
				if(!fake_healthy)
					to_chat(M, "<span class='notice'>[pick("Что-то появляется на периферии зрения, а затем исчезает.", "Вы слышите тихий шёпот без источника.", "У вас болит голова.")]</span>")
				else
					to_chat(M, "<span class='notice'>[pick(healthy_messages)]</span>")
		if(3, 4)
			if(prob(base_message_chance))
				if(!fake_healthy)
					to_chat(M, "<span class='danger'>[pick("Что-то следует за вами.", "За вами наблюдают.", "Вы слышите шёпот в ухо.", "Откуда-то раздаются громкие шаги.")]</span>")
				else
					to_chat(M, "<span class='notice'>[pick(healthy_messages)]</span>")
		else
			if(prob(base_message_chance))
				to_chat(M, "<span class='userdanger'>[pick("Ох, ваша голова...", "Ваша голова раскалывается.", "Они повсюду! Бегите!", "Что-то в тенях...")]</span>")
			M.hallucination += (45 * power)
