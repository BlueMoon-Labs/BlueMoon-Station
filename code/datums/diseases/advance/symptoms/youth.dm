/*
//////////////////////////////////////
Eternal Youth

	Moderate stealth boost.
	Increases resistance tremendously.
	Increases stage speed tremendously.
	Reduces transmission tremendously.
	Critical Level.

BONUS
	Gives you immortality and eternal youth!!!
	Can be used to buff your virus

//////////////////////////////////////
*/

/datum/symptom/youth

	name = "Eternal Youth"
	desc = "Вирус симбиотически связывается с клетками тела хозяина, предотвращая и обращая старение. \
	Взамен вирус становится более устойчивым, распространяется быстрее и труднее обнаруживается, хотя без хозяина он процветает хуже."
	stealth = 3
	resistance = 4
	stage_speed = 4
	transmittable = -4
	level = 5
	base_message_chance = 100
	symptom_delay_min = 25
	symptom_delay_max = 50

/datum/symptom/youth/Activate(datum/disease/advance/A)
	if(!..())
		return
	var/mob/living/M = A.affected_mob
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		switch(A.stage)
			if(1)
				if(H.age > 41)
					H.age = 41
					to_chat(H, "<span class='notice'>У вас не было столько энергии годами!</span>")
			if(2)
				if(H.age > 36)
					H.age = 36
					to_chat(H, "<span class='notice'>Вы внезапно в хорошем настроении.</span>")
			if(3)
				if(H.age > 31)
					H.age = 31
					to_chat(H, "<span class='notice'>Вы начинаете чувствовать себя более гибким.</span>")
			if(4)
				if(H.age > 26)
					H.age = 26
					to_chat(H, "<span class='notice'>Вы чувствуете себя обновлённым.</span>")
			if(5)
				if(H.age > 21)
					H.age = 21
					to_chat(H, "<span class='notice'>Вы чувствуете, что можете покорить мир!</span>")
