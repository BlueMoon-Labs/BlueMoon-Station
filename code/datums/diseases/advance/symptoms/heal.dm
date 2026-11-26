/datum/symptom/heal
	name = "Basic Healing (does nothing)" //warning for adminspawn viruses
	desc = "Вы не должны этого видеть."
	stealth = 0
	resistance = 0
	stage_speed = 0
	transmittable = 0
	level = 0 //not obtainable
	base_message_chance = 20 //here used for the overlays
	symptom_delay_min = 1
	symptom_delay_max = 1
	var/passive_message = "" //random message to infected but not actively healing people
	threshold_desc = list(
		"Скорость стадий 6" = "Удваивает скорость лечения.",
		"Скрытность 4" = "Лечение больше не будет видно окружающим.",
	)
/datum/symptom/heal/Start(datum/disease/advance/A)
	if(!..())
		return
	if(A.properties["stage_rate"] >= 6) //stronger healing
		power = 2

/datum/symptom/heal/Activate(datum/disease/advance/A)
	if(!..())
		return
	var/mob/living/M = A.affected_mob
	switch(A.stage)
		if(4, 5)
			var/effectiveness = CanHeal(A)
			if(!effectiveness)
				if(passive_message && prob(2) && passive_message_condition(M))
					to_chat(M, passive_message)
				return
			else
				Heal(M, A, effectiveness)
	return

/datum/symptom/heal/proc/CanHeal(datum/disease/advance/A)
	return power

/datum/symptom/heal/proc/Heal(mob/living/M, datum/disease/advance/A, actual_power)
	return TRUE

/datum/symptom/heal/proc/passive_message_condition(mob/living/M)
	return TRUE

/datum/symptom/heal/starlight
	name = "Starlight Condensation"
	desc = "Вирус реагирует на прямой звёздный свет, вырабатывая регенеративные химикаты. Наиболее эффективен против токсинового урона."
	stealth = -1
	resistance = -2
	stage_speed = 0
	transmittable = 1
	level = 6
	passive_message = "<span class='notice'>Вы скучаете по ощущению звёздного света на коже.</span>"
	var/nearspace_penalty = 0.3
	threshold_desc = list(
		"Скорость стадий 6" = "Увеличивает скорость лечения.",
		"Передача 6" = "Снимает штраф за нахождение только рядом с космосом.",
	)

/datum/symptom/heal/starlight/Start(datum/disease/advance/A)
	if(!..())
		return
	if(A.properties["transmittable"] >= 6)
		nearspace_penalty = 1
	if(A.properties["stage_rate"] >= 6)
		power = 2

/datum/symptom/heal/starlight/CanHeal(datum/disease/advance/A)
	var/mob/living/M = A.affected_mob
	if(istype(get_turf(M), /turf/open/space))
		return power
	else
		for(var/turf/T in view(M, 2))
			if(istype(T, /turf/open/space))
				return power * nearspace_penalty

/datum/symptom/heal/starlight/Heal(mob/living/carbon/M, datum/disease/advance/A, actual_power)
	var/heal_amt = actual_power
	if(M.getToxLoss() && prob(5))
		to_chat(M, "<span class='notice'>Ваша кожа покалывает, словно звёздный свет исцеляет вас.</span>")

	M.adjustToxLoss(-(8 * heal_amt), forced = TRUE) //most effective on toxins

	var/list/parts = M.get_damaged_bodyparts(1,1)

	if(!parts.len)
		return

	for(var/obj/item/bodypart/L in parts)
		if(L.heal_damage(heal_amt/parts.len, heal_amt/parts.len))
			M.update_damage_overlays()
	return TRUE

/datum/symptom/heal/starlight/passive_message_condition(mob/living/M)
	if(M.getBruteLoss() || M.getFireLoss() || M.getToxLoss())
		return TRUE
	return FALSE

/datum/symptom/heal/chem
	name = "Toxolysis"
	stealth = 0
	resistance = -2
	stage_speed = 2
	transmittable = -2
	level = 7
	var/food_conversion = FALSE
	desc = "Вирус быстро расщепляет любые чужеродные химикаты в кровотоке."
	threshold_desc = list(
		"Сопротивление 7" = "Увеличивает скорость удаления химикатов.",
		"Скорость стадий 6" = "Потребляемые химикаты питают хозяина.",
	)

/datum/symptom/heal/chem/Start(datum/disease/advance/A)
	if(!..())
		return
	if(A.properties["stage_rate"] >= 6)
		food_conversion = TRUE
	if(A.properties["resistance"] >= 7)
		power = 2

/datum/symptom/heal/chem/Heal(mob/living/M, datum/disease/advance/A, actual_power)
	for(var/E in M.reagents.reagent_list) //Not just toxins!
		var/datum/reagent/R = E
		M.reagents.remove_reagent(R.type, actual_power)
		if(food_conversion)
			M.adjust_nutrition(0.3)
		if(prob(2))
			to_chat(M, "<span class='notice'>Вы чувствуете лёгкое тепло, когда ваша кровь очищается.</span>")
	return TRUE



/datum/symptom/heal/metabolism
	name = "Metabolic Boost"
	stealth = -1
	resistance = -2
	stage_speed = 2
	transmittable = 1
	level = 7
	var/triple_metabolism = FALSE
	var/reduced_hunger = FALSE
	desc = "Вирус резко ускоряет метаболизм хозяина, заставляя его перерабатывать химикаты вдвое быстрее,\
	 но также вызывая повышенный голод."
	threshold_desc = list(
		"Скрытность 3" = "Снижает скорость голода.",
		"Скорость стадий 10" = "Метаболизация химикатов утраивается вместо удвоения.",
	)
/datum/symptom/heal/metabolism/Start(datum/disease/advance/A)
	if(!..())
		return
	if(A.properties["stage_rate"] >= 10)
		triple_metabolism = TRUE
	if(A.properties["stealth"] >= 3)
		reduced_hunger = TRUE

/datum/symptom/heal/metabolism/Heal(mob/living/carbon/C, datum/disease/advance/A, actual_power)
	if(!istype(C))
		return
	C.reagents.metabolize(C, SSMOBS_DT, 0, can_overdose=TRUE) //this works even without a liver; it's intentional since the virus is metabolizing by itself
	if(triple_metabolism)
		C.reagents.metabolize(C, SSMOBS_DT, 0, can_overdose=TRUE)
	C.overeatduration = max(C.overeatduration - 2, 0)
	var/lost_nutrition = 9 - (reduced_hunger * 5)
	C.adjust_nutrition(-lost_nutrition * HUNGER_FACTOR) //Hunger depletes at 10x the normal speed
	if(prob(2))
		to_chat(C, "<span class='notice'>Вы чувствуете странное урчание в животе, словно он работает гораздо быстрее обычного.</span>")
	return TRUE

/datum/symptom/heal/darkness
	name = "Nocturnal Regeneration"
	desc = "Вирус способен заживлять плоть хозяина в условиях низкой освещённости, восстанавливая физический урон. Более эффективен против механического урона."
	stealth = 2
	resistance = -1
	stage_speed = -2
	transmittable = -1
	level = 6
	passive_message = "<span class='notice'>Вы чувствуете покалывание на коже, когда свет проходит по ней.</span>"
	threshold_desc = list(
		"Скорость стадий 8" = "Удваивает скорость лечения.",
	)
/datum/symptom/heal/darkness/Start(datum/disease/advance/A)
	if(!..())
		return
	if(A.properties["stage_rate"] >= 8)
		power = 2

/datum/symptom/heal/darkness/CanHeal(datum/disease/advance/A)
	var/mob/living/M = A.affected_mob
	var/light_amount = 0
	if(isturf(M.loc)) //else, there's considered to be no light
		var/turf/T = M.loc
		light_amount = min(1,T.get_lumcount()) - 0.5
		if(light_amount < SHADOW_SPECIES_LIGHT_THRESHOLD)
			return power

/datum/symptom/heal/darkness/Heal(mob/living/carbon/M, datum/disease/advance/A, actual_power)
	var/heal_amt = 5 * actual_power

	var/list/parts = M.get_damaged_bodyparts(1,1)

	if(!parts.len)
		return

	if(prob(5))
		to_chat(M, "<span class='notice'>Тьма успокаивает и заживляет ваши раны.</span>")

	for(var/obj/item/bodypart/L in parts)
		if(L.heal_damage(heal_amt/parts.len, heal_amt/parts.len * 0.5)) //more effective on brute
			M.update_damage_overlays()
	return TRUE

/datum/symptom/heal/darkness/passive_message_condition(mob/living/M)
	if(M.getBruteLoss() || M.getFireLoss())
		return TRUE
	return FALSE

/datum/symptom/heal/coma
	name = "Regenerative Coma"
	desc = "Вирус вводит хозяина в похожую на смерть кому при тяжёлых повреждениях, а затем быстро их восстанавливает."
	stealth = 0
	resistance = 2
	stage_speed = -3
	transmittable = -2
	level = 8
	passive_message = "<span class='notice'>Боль от ваших ран заставляет вас чувствовать странную сонливость...</span>"
	var/deathgasp = FALSE
	var/stabilize = FALSE
	var/active_coma = FALSE //to prevent multiple coma procs
	threshold_desc = list(
		"Скрытность 2" = "Хозяин выглядит мёртвым при впадении в кому.",
		"Сопротивление 4" = "Вирус также стабилизирует хозяина в критическом состоянии.",
		"Скорость стадий 7" = "Увеличивает скорость лечения.",
	)

/datum/symptom/heal/coma/Start(datum/disease/advance/A)
	if(!..())
		return
	if(A.properties["stage_rate"] >= 7)
		power = 1.5
	if(A.properties["resistance"] >= 4)
		stabilize = TRUE
	if(A.properties["stealth"] >= 2)
		deathgasp = TRUE

/datum/symptom/heal/coma/on_stage_change(datum/disease/advance/A)  //mostly copy+pasted from the code for self-respiration's TRAIT_NOBREATH stuff
	if(!..())
		return FALSE
	if(A.stage >= 4 && stabilize)
		ADD_TRAIT(A.affected_mob, TRAIT_NOCRITDAMAGE, DISEASE_TRAIT)
	else
		REMOVE_TRAIT(A.affected_mob, TRAIT_NOCRITDAMAGE, DISEASE_TRAIT)
	return TRUE

/datum/symptom/heal/coma/End(datum/disease/advance/A)
	if(!..())
		return
	if(active_coma)
		uncoma()
	REMOVE_TRAIT(A.affected_mob, TRAIT_NOCRITDAMAGE, DISEASE_TRAIT)

/datum/symptom/heal/coma/CanHeal(datum/disease/advance/A)
	var/mob/living/M = A.affected_mob
	if(M.getBruteLoss() + M.getFireLoss() >= 70 && !active_coma)
		to_chat(M, "<span class='warning'>Вы чувствуете, как погружаетесь в регенеративную кому...</span>")
		active_coma = TRUE
		addtimer(CALLBACK(src, PROC_REF(coma), M), 60)
	if(HAS_TRAIT(M, TRAIT_DEATHCOMA))
		return power
	else if(M.stat == SOFT_CRIT)
		return power * 0.5
	else if(M.IsSleeping())
		return power * 0.25
	else if(M.IsUnconscious() || M.stat == UNCONSCIOUS)
		return power * 0.9

/datum/symptom/heal/coma/proc/coma(mob/living/M)
	if(deathgasp)
		M.emote("deathgasp")
	M.fakedeath("regenerative_coma", TRUE)
	M.update_stat()
	M.update_mobility()
	addtimer(CALLBACK(src, PROC_REF(uncoma), M), 300)

/datum/symptom/heal/coma/proc/uncoma(mob/living/M)
	if(!active_coma)
		return
	active_coma = FALSE
	M.cure_fakedeath("regenerative_coma")
	M.update_stat()
	M.update_mobility()

/datum/symptom/heal/coma/Heal(mob/living/carbon/M, datum/disease/advance/A, actual_power)
	var/heal_amt = 8 * actual_power

	var/list/parts = M.get_damaged_bodyparts(1,1)

	if(!parts.len)
		return

	for(var/obj/item/bodypart/L in parts)
		if(L.heal_damage(heal_amt/parts.len, heal_amt/parts.len))
			M.update_damage_overlays()

	if(active_coma && M.getBruteLoss() + M.getFireLoss() == 0)
		uncoma(M)

	return TRUE

/datum/symptom/heal/coma/passive_message_condition(mob/living/M)
	if((M.getBruteLoss() + M.getFireLoss()) > 30)
		return TRUE
	return FALSE

/datum/symptom/heal/water
	name = "Tissue Hydration"
	desc = "Вирус использует избыток воды внутри и снаружи тела для восстановления повреждённых клеток ткани. Более эффективен против ожогов."
	stealth = 0
	resistance = -1
	stage_speed = 0
	transmittable = 1
	level = 6
	passive_message = "<span class='notice'>Ваша кожа ощущается странно сухой...</span>"
	var/absorption_coeff = 1
	threshold_desc = list(
		"Сопротивление 5" = "Вода расходуется гораздо медленнее.",
		"Скорость стадий 7" = "Увеличивает скорость лечения.",
	)

/datum/symptom/heal/water/Start(datum/disease/advance/A)
	if(!..())
		return
	if(A.properties["stage_rate"] >= 7)
		power = 2
	if(A.properties["stealth"] >= 2)
		absorption_coeff = 0.25

/datum/symptom/heal/water/CanHeal(datum/disease/advance/A)
	. = 0
	var/mob/living/M = A.affected_mob
	if(M.fire_stacks < 0)
		M.fire_stacks = min(M.fire_stacks + 1 * absorption_coeff, 0)
		. += power
	if(M.reagents.has_reagent(/datum/reagent/water/holywater))
		M.reagents.remove_reagent(/datum/reagent/water/holywater, 0.5 * absorption_coeff)
		. += power * 0.75
	else if(M.reagents.has_reagent(/datum/reagent/water))
		M.reagents.remove_reagent(/datum/reagent/water, 0.5 * absorption_coeff)
		. += power * 0.5

/datum/symptom/heal/water/Heal(mob/living/carbon/M, datum/disease/advance/A, actual_power)
	var/heal_amt = 5 * actual_power

	var/list/parts = M.get_damaged_bodyparts(1,1) //more effective on burns

	if(!parts.len)
		return

	if(prob(5))
		to_chat(M, "<span class='notice'>Вы чувствуете, как впитываете воду вокруг себя, успокаивая повреждённую кожу.</span>")

	for(var/obj/item/bodypart/L in parts)
		if(L.heal_damage(heal_amt/parts.len * 0.5, heal_amt/parts.len))
			M.update_damage_overlays()

	return TRUE

/datum/symptom/heal/water/passive_message_condition(mob/living/M)
	if(M.getBruteLoss() || M.getFireLoss())
		return TRUE
	return FALSE

/datum/symptom/heal/plasma
	name = "Plasma Fixation"
	desc = "Вирус извлекает плазму из атмосферы и изнутри тела для лечения и стабилизации температуры тела."
	stealth = 0
	resistance = 3
	stage_speed = -2
	transmittable = -2
	level = 8
	passive_message = "<span class='notice'>Вы чувствуете странное влечение к плазме.</span>"
	var/temp_rate = 1
	threshold_desc = list(
		"Передача 6" = "Дополнительно увеличивает скорость регулировки температуры и лечит любителей токсинов",
		"Скорость стадий 7" = "Увеличивает скорость лечения.",
	)
/datum/symptom/heal/plasma/Start(datum/disease/advance/A)
	if(!..())
		return
	if(A.properties["stage_rate"] >= 7)
		power = 2
	if(A.properties["transmittable"] >= 6)
		temp_rate = 4

/datum/symptom/heal/plasma/CanHeal(datum/disease/advance/A)
	var/mob/living/M = A.affected_mob
	var/datum/gas_mixture/environment
	var/plasmamount

	. = 0

	if(M.loc)
		environment = M.loc.return_air()
	if(environment)
		plasmamount = environment.get_moles(GAS_PLASMA)
		if(plasmamount && plasmamount > GLOB.gas_data.visibility[GAS_PLASMA]) //if there's enough plasma in the air to see
			. += power * 0.5
	if(M.reagents.has_reagent(/datum/reagent/toxin/plasma))
		. +=  power * 0.75

/datum/symptom/heal/plasma/Heal(mob/living/carbon/M, datum/disease/advance/A, actual_power)
	var/heal_amt = 10 * actual_power

	if(prob(5))
		to_chat(M, "<span class='notice'>Вы чувствуете, как впитываете плазму внутри и вокруг себя...</span>")

	if(M.bodytemperature > BODYTEMP_NORMAL)
		M.adjust_bodytemperature(-20 * temp_rate * TEMPERATURE_DAMAGE_COEFFICIENT,BODYTEMP_NORMAL)
		if(prob(5))
			to_chat(M, "<span class='notice'>Уже не так жарко.</span>")
	else if(M.bodytemperature < (BODYTEMP_NORMAL + 1))
		M.adjust_bodytemperature(20 * temp_rate * TEMPERATURE_DAMAGE_COEFFICIENT,0,BODYTEMP_NORMAL)
		if(prob(5))
			to_chat(M, "<span class='notice'>Тепло.</span>")

	M.adjustToxLoss(-heal_amt, forced = (temp_rate == 4))

	var/list/parts = M.get_damaged_bodyparts(1,1)
	if(!parts.len)
		return
	if(prob(5))
		to_chat(M, "<span class='notice'>Боль от ваших ран быстро проходит.</span>")
	for(var/obj/item/bodypart/L in parts)
		if(L.heal_damage(heal_amt/parts.len, heal_amt/parts.len))
			M.update_damage_overlays()
	return TRUE


/datum/symptom/heal/radiation
	name = "Radioactive Resonance"
	desc = "Вирус использует радиацию для исправления повреждений через мутации ДНК."
	stealth = -1
	resistance = -2
	stage_speed = 2
	transmittable = -3
	level = 6
	symptom_delay_min = 1
	symptom_delay_max = 1
	passive_message = "<span class='notice'>Ваша кожа слабо светится на мгновение.</span>"
	var/cellular_damage = FALSE
	threshold_desc = list(
	"Передача 6" = "Дополнительно лечит клеточный урон и любителей токсинов.",
	"Сопротивление 7" = "Увеличивает скорость лечения.",
	)

/datum/symptom/heal/radiation/Start(datum/disease/advance/A)
	if(!..())
		return
	if(A.properties["resistance"] >= 7)
		power = 2
	if(A.properties["transmittable"] >= 6)
		cellular_damage = TRUE

/datum/symptom/heal/radiation/CanHeal(datum/disease/advance/A)
	var/mob/living/M = A.affected_mob
	switch(M.radiation)
		if(0)
			return FALSE
		if(1 to RAD_MOB_SAFE)
			return 0.25
		if(RAD_MOB_SAFE to RAD_BURN_THRESHOLD)
			return 0.5
		if(RAD_BURN_THRESHOLD to RAD_MOB_MUTATE)
			return 0.75
		if(RAD_MOB_MUTATE to RAD_MOB_KNOCKDOWN)
			return TRUE
		else
			return 1.5

/datum/symptom/heal/radiation/Heal(mob/living/carbon/M, datum/disease/advance/A, actual_power)
	var/heal_amt = 10 * actual_power

	if(cellular_damage)
		M.adjustCloneLoss(-heal_amt * 0.5)

	M.adjustToxLoss(-(2 * heal_amt), forced = cellular_damage)

	var/list/parts = M.get_damaged_bodyparts(1,1)

	if(!parts.len)
		return

	if(prob(4))
		to_chat(M, "<span class='notice'>Ваша кожа слабо светится, и вы чувствуете, как раны заживают сами по себе.</span>")

	for(var/obj/item/bodypart/L in parts)
		if(L.heal_damage(heal_amt/parts.len, heal_amt/parts.len))
			M.update_damage_overlays()
	return TRUE
