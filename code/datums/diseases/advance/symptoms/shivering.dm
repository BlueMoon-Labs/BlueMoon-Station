/*
//////////////////////////////////////

Shivering

	No change to hidden.
	Increases resistance.
	Increases stage speed.
	Little transmittable.
	Low level.

Bonus
	Cools down your body.

//////////////////////////////////////
*/

/datum/symptom/shivering
	name = "Shivering"
	desc = "Вирус подавляет терморегуляцию организма, охлаждая его."
	stealth = 0
	resistance = 2
	stage_speed = 3
	transmittable = 2
	level = 2
	severity = 2
	symptom_delay_min = 10
	symptom_delay_max = 30
	var/unsafe = FALSE //over the cold threshold
	threshold_desc = list(
		"Скорость стадий 5" = "Увеличивает скорость охлаждения; хозяин может опуститься ниже безопасной температуры.",
		"Скорость стадий 10" = "Ещё больше увеличивает скорость охлаждения."
	)

/datum/symptom/shivering/Start(datum/disease/advance/A)
	if(!..())
		return
	if(A.properties["stage_rate"] >= 5) //dangerous cold
		power = 1.5
		unsafe = TRUE
	if(A.properties["stage_rate"] >= 10)
		power = 2.5

/datum/symptom/shivering/Activate(datum/disease/advance/A)
	if(!..())
		return
	var/mob/living/carbon/M = A.affected_mob
	if(!unsafe || A.stage < 4)
		to_chat(M, "<span class='warning'>[pick("Вам холодно.", "Вы дрожите.")]</span>")
	else
		to_chat(M, "<span class='userdanger'>[pick("Вы чувствуете, как кровь стынет в жилах.", "Вы чувствуете лёд в венах.", "Вы чувствуете, что не можете согреться.", "Вы яростно дрожите." )]</span>")
	if(M.bodytemperature > BODYTEMP_COLD_DAMAGE_LIMIT || unsafe)
		Chill(M, A)

/datum/symptom/shivering/proc/Chill(mob/living/M, datum/disease/advance/A)
	var/get_cold = 6 * power
	var/limit = BODYTEMP_COLD_DAMAGE_LIMIT + 1
	if(unsafe)
		limit = 0
	M.adjust_bodytemperature(-get_cold * A.stage, limit)
	return TRUE
