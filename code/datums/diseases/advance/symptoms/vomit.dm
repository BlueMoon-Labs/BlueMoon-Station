/*
//////////////////////////////////////

Vomiting

	Very Very Noticable.
	Decreases resistance.
	Doesn't increase stage speed.
	Little transmissibility.
	Medium Level.

Bonus
	Forces the affected mob to vomit!
	Meaning your disease can spread via
	people walking on vomit.
	Makes the affected mob lose nutrition and
	heal toxin damage.

//////////////////////////////////////
*/

/datum/symptom/vomit

	name = "Vomiting"
	desc = "Вирус вызывает тошноту и раздражает желудок, приводя к периодической рвоте."
	stealth = -2
	resistance = -1
	stage_speed = -1
	transmittable = 2
	level = 3
	severity = 3
	base_message_chance = 100
	symptom_delay_min = 25
	symptom_delay_max = 80
	var/vomit_blood = FALSE
	var/proj_vomit = 0
	threshold_desc = list(
		"Сопротивление 7" =  "Хозяин будет рвать кровью, нанося внутренние повреждения.",
		"Передача 7" =  "Хозяин будет рвать на расстояние, увеличивая дальность рвоты.",
		"Скрытность 4" =  "Симптом остаётся скрытым до активации."
	)

/datum/symptom/vomit/Start(datum/disease/advance/A)
	if(!..())
		return
	if(A.properties["stealth"] >= 4)
		suppress_warning = TRUE
	if(A.properties["resistance"] >= 7) //blood vomit
		vomit_blood = TRUE
	if(A.properties["transmittable"] >= 7) //projectile vomit
		proj_vomit = 5

/datum/symptom/vomit/Activate(datum/disease/advance/A)
	if(!..())
		return
	var/mob/living/M = A.affected_mob
	switch(A.stage)
		if(1, 2, 3, 4)
			if(prob(base_message_chance) && !suppress_warning)
				to_chat(M, "<span class='warning'>[pick("Вас тошнит.", "Вам кажется, что вас сейчас вырвет!")]</span>")
		else
			vomit(M)

/datum/symptom/vomit/proc/vomit(mob/living/carbon/M)
	M.vomit(20, vomit_blood, distance = proj_vomit)
