/*
//////////////////////////////////////

Hyphema (Eye bleeding)

	Slightly noticable.
	Lowers resistance tremendously.
	Decreases stage speed tremendously.
	Decreases transmittablity.
	Critical Level.

Bonus
	Causes blindness.

//////////////////////////////////////
*/

/datum/symptom/visionloss

	name = "Hyphema"
	desc = "Вирус вызывает воспаление сетчатки, приводящее к повреждению глаз и в итоге к слепоте."
	stealth = -1
	resistance = -4
	stage_speed = -4
	transmittable = -3
	level = 5
	severity = 5
	base_message_chance = 50
	symptom_delay_min = 25
	symptom_delay_max = 80
	var/remove_eyes = FALSE
	threshold_desc = list(
		"Сопротивление 12" = "Ослабляет наружные мышцы глаза, в итоге приводя к полному отслоению глаз.",
		"Скрытность 4" = "Симптом остаётся скрытым до активации.",
	)
/datum/symptom/visionloss/Start(datum/disease/advance/A)
	if(!..())
		return
	if(A.properties["stealth"] >= 4)
		suppress_warning = TRUE
	if(A.properties["resistance"] >= 12) //goodbye eyes
		remove_eyes = TRUE

/datum/symptom/visionloss/Activate(datum/disease/advance/A)
	if(!..())
		return
	var/mob/living/carbon/M = A.affected_mob
	var/obj/item/organ/eyes/eyes = M.getorganslot(ORGAN_SLOT_EYES)
	if(eyes)
		switch(A.stage)
			if(1, 2)
				if(prob(base_message_chance) && !suppress_warning)
					to_chat(M, "<span class='warning'>Ваши глаза чешутся.</span>")
			if(3, 4)
				to_chat(M, "<span class='warning'><b>Ваши глаза горят!</b></span>")
				M.blur_eyes(10)
				eyes.applyOrganDamage(1)
			else
				M.blur_eyes(20)
				eyes.applyOrganDamage(5)
				if(eyes.damage >= 10)
					M.become_nearsighted(EYE_DAMAGE)
				if(prob(eyes.damage - 10 + 1))
					if(!remove_eyes)
						if(!HAS_TRAIT(M, TRAIT_BLIND))
							to_chat(M, "<span class='userdanger'>Вы слепнете!</span>")
							eyes.applyOrganDamage(eyes.maxHealth)
					else
						M.visible_message("<span class='warning'>Глаза [M] выпадают из орбит!</span>", "<span class='userdanger'>Ваши глаза выпадают из орбит!</span>")
						eyes.Remove()
						eyes.forceMove(get_turf(M))
				else
					to_chat(M, "<span class='userdanger'>Ваши глаза ужасно горят!</span>")
