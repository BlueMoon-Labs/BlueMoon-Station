//Severe traumas, when your brain gets abused way too much.
//These range from very annoying to completely debilitating.
//They cannot be cured with chemicals, and require brain surgery to solve.

/datum/brain_trauma/severe
	resilience = TRAUMA_RESILIENCE_SURGERY

/datum/brain_trauma/severe/mute
	name = "Mutism"
	desc = "Пациент полностью утрачивает способность говорить."
	scan_desc = "обширное повреждение речевого центра мозга"
	gain_text = "<span class='warning'>Вы забываете, как говорить!</span>"
	lose_text = "<span class='notice'>Вы внезапно вспоминаете, как говорить.</span>"

/datum/brain_trauma/severe/mute/on_gain()
	ADD_TRAIT(owner, TRAIT_MUTE, TRAUMA_TRAIT)
	..()

/datum/brain_trauma/severe/mute/on_lose()
	REMOVE_TRAIT(owner, TRAIT_MUTE, TRAUMA_TRAIT)
	..()

/datum/brain_trauma/severe/aphasia
	name = "Aphasia"
	desc = "Пациент не может говорить или понимать какие-либо языки."
	scan_desc = "обширное повреждение языкового центра мозга"
	gain_text = "<span class='warning'>Вам трудно подбирать слова в голове...</span>"
	lose_text = "<span class='notice'>Вы внезапно вспоминаете, как работают языки.</span>"

/datum/brain_trauma/severe/aphasia/on_gain()
	owner.add_blocked_language(subtypesof(/datum/language) - /datum/language/aphasia, LANGUAGE_APHASIA)
	owner.grant_language(/datum/language/aphasia, source = LANGUAGE_APHASIA)
	..()

/datum/brain_trauma/severe/aphasia/on_lose()
	owner.remove_blocked_language(subtypesof(/datum/language), LANGUAGE_APHASIA)
	owner.remove_language(/datum/language/aphasia, source = LANGUAGE_APHASIA)
	..()

/datum/brain_trauma/severe/blindness
	name = "Cerebral Blindness"
	desc = "Мозг пациента больше не связан с глазами."
	scan_desc = "обширное повреждение затылочной доли мозга"
	gain_text = "<span class='warning'>Вы не видите!</span>"
	lose_text = "<span class='notice'>Зрение возвращается.</span>"

/datum/brain_trauma/severe/blindness/on_gain()
	owner.become_blind(TRAUMA_TRAIT)
	..()

/datum/brain_trauma/severe/blindness/on_lose()
	owner.cure_blind(TRAUMA_TRAIT)
	..()

/datum/brain_trauma/severe/paralysis
	name = "Paralysis"
	desc = "Мозг пациента больше не может управлять частью двигательных функций."
	scan_desc = "церебральный паралич"
	gain_text = ""
	lose_text = ""
	var/paralysis_type
	var/list/paralysis_traits = list()
	 //for descriptions

/datum/brain_trauma/severe/paralysis/New(specific_type)
	if(specific_type)
		paralysis_type = specific_type
	if(!paralysis_type)
		paralysis_type = pick("full","left","right","arms","legs","r_arm","l_arm","r_leg","l_leg")
	var/subject
	switch(paralysis_type)
		if("full")
			subject = "своё тело"
			paralysis_traits = list(TRAIT_PARALYSIS_L_ARM, TRAIT_PARALYSIS_R_ARM, TRAIT_PARALYSIS_L_LEG, TRAIT_PARALYSIS_R_LEG)
		if("left")
			subject = "левую сторону тела"
			paralysis_traits = list(TRAIT_PARALYSIS_L_ARM, TRAIT_PARALYSIS_L_LEG)
		if("right")
			subject = "правую сторону тела"
			paralysis_traits = list(TRAIT_PARALYSIS_R_ARM, TRAIT_PARALYSIS_R_LEG)
		if("arms")
			subject = "свои руки"
			paralysis_traits = list(TRAIT_PARALYSIS_L_ARM, TRAIT_PARALYSIS_R_ARM)
		if("legs")
			subject = "свои ноги"
			paralysis_traits = list(TRAIT_PARALYSIS_L_LEG, TRAIT_PARALYSIS_R_LEG)
		if("r_arm")
			subject = "правую руку"
			paralysis_traits = list(TRAIT_PARALYSIS_R_ARM)
		if("l_arm")
			subject = "левую руку"
			paralysis_traits = list(TRAIT_PARALYSIS_L_ARM)
		if("r_leg")
			subject = "правую ногу"
			paralysis_traits = list(TRAIT_PARALYSIS_R_LEG)
		if("l_leg")
			subject = "левую ногу"
			paralysis_traits = list(TRAIT_PARALYSIS_L_LEG)

	gain_text = "<span class='warning'>Вы больше не чувствуете [subject]!</span>"
	lose_text = "<span class='notice'>Вы снова чувствуете [subject]!</span>"

/datum/brain_trauma/severe/paralysis/on_gain()
	..()
	for(var/X in paralysis_traits)
		ADD_TRAIT(owner, X, "trauma_paralysis")
	owner.update_disabled_bodyparts()

/datum/brain_trauma/severe/paralysis/on_lose()
	..()
	for(var/X in paralysis_traits)
		REMOVE_TRAIT(owner, X, "trauma_paralysis")
	owner.update_disabled_bodyparts()

/datum/brain_trauma/severe/paralysis/paraplegic
	random_gain = FALSE
	paralysis_type = "legs"
	resilience = TRAUMA_RESILIENCE_ABSOLUTE

/datum/brain_trauma/severe/paralysis/spinesnapped
	random_gain = FALSE
	clonable = FALSE
	paralysis_type = "legs"
	resilience = TRAUMA_RESILIENCE_LOBOTOMY // It shouldn't fix severed spinal cords really, but there is no specific surgery for that yet.

/datum/brain_trauma/severe/narcolepsy
	name = "Narcolepsy"
	desc = "Пациент может непроизвольно засыпать во время обычной деятельности."
	scan_desc = "травматическая нарколепсия"
	gain_text = "<span class='warning'>Вы постоянно чувствуете сонливость...</span>"
	lose_text = "<span class='notice'>Вы снова чувствуете себя бодрым и осознанным.</span>"

/datum/brain_trauma/severe/narcolepsy/on_life()
	..()
	if(owner.IsSleeping())
		return
	var/sleep_chance = 1
	if(owner.m_intent == MOVE_INTENT_RUN)
		sleep_chance += 2
	if(owner.drowsyness)
		sleep_chance += 3
	if(prob(sleep_chance))
		to_chat(owner, "<span class='warning'>Вы засыпаете.</span>")
		owner.Sleeping(60)
	else if(!owner.drowsyness && prob(sleep_chance * 2))
		to_chat(owner, "<span class='warning'>Вы чувствуете усталость...</span>")
		owner.drowsyness += 10

/datum/brain_trauma/severe/monophobia
	name = "Monophobia"
	desc = "Пациент чувствует себя плохо и испытывает стресс, когда рядом нет других людей, что может привести к смертельно опасному уровню стресса."
	scan_desc = "монофобия"
	gain_text = ""
	lose_text = "<span class='notice'>Вы чувствуете, что можете быть в безопасности и в одиночестве.</span>"
	var/stress = 0
	COOLDOWN_DECLARE(effect_timer)
	var/last_chance = TRUE // даём последний шанс чтобы принять Psicodine или найти хоть кого-то чтобы снять стресс

/datum/brain_trauma/severe/monophobia/on_gain()
	..()
	if(check_alone())
		to_chat(owner, span_warning("Вы ощущаете себя очень одиноко..."))
	else
		to_chat(owner, span_notice("Вы чувствуете себя в безопасности, пока рядом с вами есть хоть кто-то."))

/datum/brain_trauma/severe/monophobia/on_life()
	..()
	if(HAS_TRAIT(owner, TRAIT_FEARLESS)) // трейт от Psicodine или Happiness
		if(check_alone())
			stress = max(stress - 0.25, 0) // в разы меньше чем от настоящей компании
		else
			stress = max(stress - 4.5, 0) // химия в 2 раза эффективнее при наличии компании
		last_chance = TRUE
		return

	if(!check_alone())
		stress = max(stress - 4, 0)
		return

	stress = min(stress + 0.25, 100)
	if(stress > 10 && prob(5) && COOLDOWN_FINISHED(src, effect_timer))
		COOLDOWN_START(src, effect_timer, rand(2, 7) MINUTES)
		stress_reaction()

/datum/brain_trauma/severe/monophobia/proc/check_alone()
	var/check_radius = 7

	if(!owner)
		return FALSE
	if(istype(owner.loc, /obj/item/clothing/head/mob_holder/micro))
		return FALSE
	if(istype(owner.loc, /obj/belly))
		return FALSE
	if(!owner.ckey || owner.stat)
		return FALSE
	if(HAS_TRAIT(owner, TRAIT_BLIND))
		check_radius = 1
	for(var/mob/living/L in oview(owner, check_radius))
		if((istype(L, /mob/living/simple_animal/pet)) || L.ckey)
			return FALSE
	return TRUE

/datum/brain_trauma/severe/monophobia/proc/stress_reaction()
	if(owner.stat != CONSCIOUS)
		return

	var/high_stress = (stress > 60) //things get psychosomatic from here on
	switch(rand(1,5))
		if(1)
			if(!high_stress)
				to_chat(owner, span_warning("Вы ощущаете себя очень плохо..."))
			else
				to_chat(owner, span_warning("Вас начинает уже тошнить от одиночества, кажется ещё немного и вас вырвет!"))
				owner.adjust_disgust(45)
		if(2, 3)
			if(!high_stress)
				to_chat(owner, span_warning("Вы не можете перстать трястись..."))
				owner.dizziness += 20
				owner.confused += 20
				owner.Jitter(20)
			else
				to_chat(owner, span_warning("Вы ощущаете себя ослабшим и напуганным. Если кто был только рядом..."))
				owner.dizziness += 20
				owner.confused += 20
				owner.Jitter(20)
				owner.adjustStaminaLoss(50)

		if(4)
			if(!high_stress)
				to_chat(owner, span_warning("Вы ощущаете себя очень одиноко..."))
			else
				to_chat(owner, span_warning("Вы уже начинаете сходит с ума от одиночества!"))
				owner.hallucination += 30

		if(5)
			if(!high_stress)
				to_chat(owner, span_warning("Ваше сердце замирает на мгновение."))
				owner.adjustOxyLoss(8)
			else
				if(prob(50) && ishuman(owner))
					var/mob/living/carbon/human/H = owner
					if(last_chance)
						last_chance = FALSE
						H.emote("cry")
						to_chat(H, span_userdanger("Вы ощущаете как ваше сердце разрывается от боли. Ещё немного и кажется оно лопнет из-за этого!"))
						return
					H.set_heartattack(TRUE)
					to_chat(H, span_userdanger("Вы ощущаете колющую боль в сердце!"))
				else
					to_chat(owner, span_userdanger("Вы чувствуете, как ваше сердце бешено колотится в груди..."))
					owner.adjustOxyLoss(8)

/datum/brain_trauma/severe/discoordination
	name = "Discoordination"
	desc = "Пациент не может пользоваться сложными инструментами или техникой."
	scan_desc = "крайняя дискоординация"
	gain_text = "<span class='warning'>Вы едва контролируете свои руки!</span>"
	lose_text = "<span class='notice'>Вы снова контролируете свои руки.</span>"

/datum/brain_trauma/severe/discoordination/on_gain()
	ADD_TRAIT(owner, TRAIT_MONKEYLIKE, TRAUMA_TRAIT)
	..()

/datum/brain_trauma/severe/discoordination/on_lose()
	REMOVE_TRAIT(owner, TRAIT_MONKEYLIKE, TRAUMA_TRAIT)
	..()

/datum/brain_trauma/severe/pacifism
	name = "Traumatic Non-Violence"
	desc = "Пациент крайне не желает причинять вред другим насильственными способами."
	scan_desc = "пацифистский синдром"
	gain_text = "<span class='notice'>Вы чувствуете странное умиротворение.</span>"
	lose_text = "<span class='notice'>Вы больше не чувствуете принуждения не причинять вред.</span>"

/datum/brain_trauma/severe/pacifism/on_gain()
	ADD_TRAIT(owner, TRAIT_PACIFISM, TRAUMA_TRAIT)
	..()

/datum/brain_trauma/severe/pacifism/on_lose()
	REMOVE_TRAIT(owner, TRAIT_PACIFISM, TRAUMA_TRAIT)
	..()

//ported from TG
/datum/brain_trauma/severe/hypnotic_stupor
	name = "Hypnotic Stupor"
	desc = "Пациент подвержен эпизодам крайнего ступора, во время которых становится чрезвычайно внушаемым."
	scan_desc = "онейрическая петля обратной связи"
	gain_text = "<span class='warning'>Вы чувствуете лёгкую затуманенность сознания.</span>"
	lose_text = "<span class='notice'>Вы чувствуете, будто туман в голове рассеялся.</span>"
	var/min_hypno_duration = 6000
	var/max_hypno_duration = 12000
	var/hypno_duration = -1 // 0 or some world time limits, whereas -1 has old behavior

/datum/brain_trauma/severe/hypnotic_stupor/on_gain()
	..()
	min_hypno_duration = CONFIG_GET(number/min_stupor_hypno_duration) // 6000
	max_hypno_duration = CONFIG_GET(number/max_stupor_hypno_duration) // 12000
	hypno_duration = CONFIG_GET(flag/limit_stupor_trances) ? 0 : -1

/datum/brain_trauma/severe/hypnotic_stupor/on_lose() //hypnosis must be cleared separately, but brain surgery should get rid of both anyway
	..()
	owner.remove_status_effect(/datum/status_effect/trance)

/datum/brain_trauma/severe/hypnotic_stupor/on_life()
	..()
	if(prob(1) && !owner.has_status_effect(/datum/status_effect/trance))
		if (world.time > hypno_duration) // Only re-trance every so often
			owner.apply_status_effect(/datum/status_effect/trance, rand(100,300), FALSE, hypno_duration > -1)

/datum/brain_trauma/severe/hypnotic_stupor/proc/on_hypnosis()
	if (hypno_duration > -1)
		hypno_duration = world.time + rand(min_hypno_duration, max_hypno_duration)

/datum/brain_trauma/severe/hypnotic_trigger
	name = "Hypnotic Trigger"
	desc = "В подсознании пациента установлена триггерная фраза, вызывающая внушаемое трансовое состояние."
	scan_desc = "онейрическая петля обратной связи"
	gain_text = "<span class='warning'>Вы чувствуете себя странно, будто забыли что-то важное.</span>"
	lose_text = "<span class='notice'>Вы чувствуете, будто груз свалился с вашего разума.</span>"
	random_gain = FALSE
	var/trigger_phrase = "Nanotrasen"

/datum/brain_trauma/severe/hypnotic_trigger/New(phrase)
	..()
	if(phrase)
		trigger_phrase = phrase

/datum/brain_trauma/severe/hypnotic_trigger/on_lose() //hypnosis must be cleared separately, but brain surgery should get rid of both anyway
	..()
	owner.remove_status_effect(/datum/status_effect/trance)

/datum/brain_trauma/severe/hypnotic_trigger/handle_hearing(datum/source, list/hearing_args)
	if(!owner.can_hear())
		return
	if(owner == hearing_args[HEARING_SPEAKER])
		return

	var/regex/reg = new("[REGEX_QUOTE(trigger_phrase)]","ig")

	if(findtext(hearing_args[HEARING_RAW_MESSAGE], lowertext(reg.name)))
		addtimer(CALLBACK(src, PROC_REF(hypnotrigger)), 10) //to react AFTER the chat message
		hearing_args[HEARING_RAW_MESSAGE] = reg.Replace(hearing_args[HEARING_RAW_MESSAGE], "<span class='hypnophrase'>*********</span>")

/datum/brain_trauma/severe/hypnotic_trigger/proc/hypnotrigger()
	to_chat(owner, "<span class='warning'>Слова затрагивают что-то глубоко внутри вас, и вы чувствуете, как сознание ускользает...</span>")
	owner.apply_status_effect(/datum/status_effect/trance, rand(100,300), FALSE)
