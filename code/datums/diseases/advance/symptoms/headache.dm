/*
//////////////////////////////////////

Headache

	Noticable.
	Highly resistant.
	Increases stage speed.
	Not transmittable.
	Low Level.

BONUS
	Displays an annoying message!
	Should be used for buffing your disease.

//////////////////////////////////////
*/

/datum/symptom/headache

	name = "Headache"
	desc = "Вирус вызывает воспаление внутри мозга, вызывая постоянные головные боли."
	stealth = -1
	resistance = 4
	stage_speed = 2
	transmittable = 0
	level = 1
	severity = 1
	base_message_chance = 100
	symptom_delay_min = 15
	symptom_delay_max = 30
	threshold_desc = list(
		"Stage Speed 6" = "Головные боли вызывают сильную боль, ослабляющую хозяина.",
		"Stage Speed 9" = "Головные боли становятся реже, но гораздо интенсивнее, не позволяя хозяину действовать.",
		"Stealth 4" = "Снижает частоту головных болей до более поздних стадий.",
	)

/datum/symptom/headache/Start(datum/disease/advance/A)
	if(!..())
		return
	if(A.properties["stealth"] >= 4)
		base_message_chance = 50
	if(A.properties["stage_rate"] >= 6) //severe pain
		power = 2
	if(A.properties["stage_rate"] >= 9) //cluster headaches
		symptom_delay_min = 30
		symptom_delay_max = 60
		power = 3

/datum/symptom/headache/Activate(datum/disease/advance/A)
	if(!..())
		return
	var/mob/living/M = A.affected_mob
	if(power < 2)
		if(prob(base_message_chance) || A.stage >=4)
			to_chat(M, "<span class='warning'>[pick("У вас болит голова.", "Ваша голова раскалывается.")]</span>")
	if(power >= 2 && A.stage >= 4)
		to_chat(M, "<span class='warning'>[pick("У вас сильно болит голова.", "Ваша голова нестерпимо раскалывается.")]</span>")
		M.adjustStaminaLoss(25)
	if(power >= 3 && A.stage >= 5)
		to_chat(M, "<span class='userdanger'>[pick("У вас болит голова!", "Вы чувствуете раскалённый нож внутри мозга!", "Волну боли захлёстывает вашу голову!")]</span>")
		M.Stun(35)
