/*
//////////////////////////////////////

Coughing

	Noticable.
	Little Resistance.
	Doesn't increase stage speed much.
	Transmissibile.
	Low Level.

BONUS
	Will force the affected mob to drop small items!

//////////////////////////////////////
*/

/datum/symptom/cough

	name = "Cough"
	desc = "Вирус раздражает горло хозяина, вызывая периодический кашель."
	stealth = -1
	resistance = 3
	stage_speed = 1
	transmittable = 2
	level = 1
	severity = 1
	base_message_chance = 15
	symptom_delay_min = 2
	symptom_delay_max = 15
	var/infective = FALSE
	threshold_desc = list(
		"Resistance 11" = "Хозяин будет ронять мелкие предметы при кашле.",
		"Resistance 15" = "Иногда вызывает приступы кашля, оглушающие хозяина. Дополнительные кашли не распространяют вирус.",
		"Stage Speed 6" = "Увеличивает частоту кашля.",
		"Transmission 7" = "Кашель теперь заражает окружающих в радиусе до 2 клеток.",
		"Stealth 4" = "Симптом остаётся скрытым до активации.",
	)
/datum/symptom/cough/Start(datum/disease/advance/A)
	if(!..())
		return
	if(A.properties["stealth"] >= 4)
		suppress_warning = TRUE
	if(A.spread_flags &= DISEASE_SPREAD_AIRBORNE) //infect bystanders
		infective = TRUE
	if(A.properties["resistance"] >= 3) //strong enough to drop items
		power = 1.5
	if(A.properties["resistance"] >= 10) //strong enough to stun (rarely)
		power = 2
	if(A.properties["stage_rate"] >= 6) //cough more often
		symptom_delay_max = 10

/datum/symptom/cough/Activate(datum/disease/advance/A)
	if(!..() || HAS_TRAIT(A.affected_mob,TRAIT_NOBREATH))
		return
	var/mob/living/M = A.affected_mob
	switch(A.stage)
		if(1, 2, 3)
			if(prob(base_message_chance) && !suppress_warning)
				to_chat(M, "<span notice='warning'>[pick("Вы глотаете избыточную слизь.", "Вы слегка кашляете.")]</span>")
		else
			M.emote("cough")
			if(power >= 1.5)
				var/obj/item/I = M.get_active_held_item()
				if(I && I.w_class == WEIGHT_CLASS_TINY)
					M.dropItemToGround(I)
			if(power >= 2 && prob(10))
				to_chat(M, "<span notice='userdanger'>[pick("У вас приступ кашля!", "Вы не можете перестать кашлять!")]</span>")
				M.Stun(20)
				M.emote("cough")
				addtimer(CALLBACK(M, TYPE_PROC_REF(/mob, emote), "cough"), 6)
				addtimer(CALLBACK(M, TYPE_PROC_REF(/mob, emote), "cough"), 12)
				addtimer(CALLBACK(M, TYPE_PROC_REF(/mob, emote), "cough"), 18)
			if(infective && M.CanSpreadAirborneDisease())
				A.spread(1)

