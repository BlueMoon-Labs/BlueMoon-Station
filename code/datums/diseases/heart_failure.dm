/datum/disease/heart_failure
	form = "Condition"
	name = "Myocardial Infarction"
	max_stages = 5
	stage_prob = 2
	cure_text = "Пересадка сердца для излечения. Дефибрилляция (или в крайнем случае неконтролируемый электрический шок) также может помочь после остановки сердца. Коразон также смягчает остановку сердца."
	agent = "Плохое сердце"
	viable_mobtypes = list(/mob/living/carbon/human)
	permeability_mod = 1
	desc = "Если не лечить, субъект умрёт!"
	severity = "Dangerous!"
	disease_flags = CAN_CARRY|CAN_RESIST
	spread_flags = DISEASE_SPREAD_NON_CONTAGIOUS
	visibility_flags = HIDDEN_PANDEMIC
	required_organs = list(/obj/item/organ/heart)
	bypasses_immunity = TRUE // Immunity is based on not having an appendix; this isn't a virus
	var/sound = FALSE

/datum/disease/heart_failure/Copy()
	var/datum/disease/heart_failure/D = ..()
	D.sound = sound
	return D

/datum/disease/heart_failure/stage_act()
	..()
	var/obj/item/organ/heart/O = affected_mob.getorgan(/obj/item/organ/heart)
	var/mob/living/carbon/H = affected_mob
	if(O && H.can_heartattack())
		switch(stage)
			if(1 to 2)
				if(prob(2))
					to_chat(H, "<span class='warning'>Вы чувствуете [pick("дискомфорт", "давление", "жжение", "боль")] в груди.</span>")
				if(prob(2))
					to_chat(H, "<span class='warning'>Вы чувствуете головокружение.</span>")
					H.confused += 6
				if(prob(3))
					to_chat(H, "<span class='warning'>Вы чувствуете [pick("полноту", "тошноту", "потливость", "слабость", "усталость", "нехватку дыхания", "беспокойство")].</span>")
			if(3 to 4)
				if(!sound)
					H.playsound_local(H, 'sound/health/slowbeat.ogg', 40, FALSE, channel = CHANNEL_HEARTBEAT)
					sound = TRUE
				if(prob(3))
					to_chat(H, "<span class='danger'>Вы чувствуете острую боль в груди!</span>")
					if(prob(25))
						affected_mob.vomit(95)
					H.emote("cough")
					H.DefaultCombatKnockdown(40)
					H.losebreath += 12
				if(prob(3))
					to_chat(H, "<span class='danger'>Вы чувствуете сильную слабость и головокружение...</span>")
					H.confused += 16
					H.adjustStaminaLoss(80)
					H.emote("cough")
			if(5)
				H.stop_sound_channel(CHANNEL_HEARTBEAT)
				H.playsound_local(H, 'sound/effects/singlebeat.ogg', 100, FALSE)
				if(H.stat == CONSCIOUS)
					H.visible_message("<span class='userdanger'>[H] clutches at [H.ru_ego()] chest as if [H.ru_ego()] heart is stopping!</span>")
				H.adjustStaminaLoss(120)
				H.set_heartattack(TRUE)
				H.reagents.add_reagent(/datum/reagent/medicine/corazone, 3) // To give the victim a final chance to shock their heart before losing consciousness
				cure()

	else
		cure()
