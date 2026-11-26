/*
//////////////////////////////////////
Disfiguration

	Hidden.
	No change to resistance.
	Increases stage speed.
	Slightly increases transmittability.
	Critical Level.

BONUS
	Adds disfiguration trait making the mob appear as "Unknown" to others.

//////////////////////////////////////
*/

/datum/symptom/disfiguration

	name = "Disfiguration"
	desc = "Вирус разжижает мышцы лица, обезображивая хозяина."
	stealth = 2
	resistance = 0
	stage_speed = 3
	transmittable = 1
	level = 5
	severity = 1
	symptom_delay_min = 25
	symptom_delay_max = 75

/datum/symptom/disfiguration/Activate(datum/disease/advance/A)
	. = ..()
	if(!.)
		return
	var/mob/living/M = A.affected_mob
	if (HAS_TRAIT(M, TRAIT_DISFIGURED))
		return
	switch(A.stage)
		if(5)
			ADD_TRAIT(M, TRAIT_DISFIGURED, DISEASE_TRAIT)
			M.visible_message("<span class='warning'>Лицо [M] будто проваливается внутрь!</span>", "<span class='notice'>Вы чувствуете, как ваше лицо сминается и проваливается!</span>")
		else
			M.visible_message("<span class='warning'>Лицо [M] начинает искажаться...</span>", "<span class='notice'>Ваше лицо ощущается влажным и податливым...</span>")


/datum/symptom/disfiguration/End(datum/disease/advance/A)
	. = ..()
	if(!.)
		return
	if(A.affected_mob)
		REMOVE_TRAIT(A.affected_mob, TRAIT_DISFIGURED, DISEASE_TRAIT)
