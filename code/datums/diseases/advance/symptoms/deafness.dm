/*
//////////////////////////////////////

Deafness

	Slightly noticable.
	Lowers resistance.
	Decreases stage speed slightly.
	Decreases transmittablity.
	Intense Level.

Bonus
	Causes intermittent loss of hearing.

//////////////////////////////////////
*/

/datum/symptom/deafness

	name = "Deafness"
	desc = "Вирус вызывает воспаление барабанных перепонок, приводящее к периодической глухоте."
	stealth = -1
	resistance = -2
	stage_speed = -1
	transmittable = -3
	level = 4
	severity = 4
	base_message_chance = 100
	symptom_delay_min = 25
	symptom_delay_max = 80
	threshold_desc = list(
		"Resistance 9" = "Вызывает постоянную глухоту вместо периодической.",
		"Stealth 4" = "Симптом остаётся скрытым до активации.",
	)

/datum/symptom/deafness/Start(datum/disease/advance/A)
	if(!..())
		return
	if(A.properties["stealth"] >= 4)
		suppress_warning = TRUE
	if(A.properties["resistance"] >= 9) //permanent deafness
		power = 2

/datum/symptom/deafness/Activate(datum/disease/advance/A)
	if(!..())
		return
	var/mob/living/carbon/M = A.affected_mob
	switch(A.stage)
		if(3, 4)
			if(prob(base_message_chance) && !suppress_warning)
				to_chat(M, "<span class='warning'>[pick("Вы слышите звон в ухе.", "У вас закладывает уши.")]</span>")
		if(5)
			if(power > 2)
				var/obj/item/organ/ears/ears = M.getorganslot(ORGAN_SLOT_EARS)
				if(istype(ears) && ears.damage < ears.maxHealth)
					to_chat(M, "<span class='userdanger'>У вас болезненно закладывает уши и начинается кровотечение!</span>")
					ears.damage = max(ears.damage, ears.maxHealth)
					if(!HAS_TRAIT(M, TRAIT_ROBOTIC_ORGANISM)) // BLUEMOON ADD - роботы не кричат от боли
						M.emote("scream")
			else
				to_chat(M, "<span class='userdanger'>У вас закладывает уши и начинается громкий звон!</span>")
				M.minimumDeafTicks(20)
