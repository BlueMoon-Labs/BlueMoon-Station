//Mild traumas are the most common; they are generally minor annoyances.
//They can be cured with mannitol and patience, although brain surgery still works.
//Most of the old brain damage effects have been transferred to the dumbness trauma.

/datum/brain_trauma/mild

/datum/brain_trauma/mild/hallucinations
	name = "Hallucinations"
	desc = "Пациент страдает от постоянных галлюцинаций."
	scan_desc = "шизофрения"
	gain_text = "<span class='warning'>Вы чувствуете, как теряете связь с реальностью...</span>"
	lose_text = "<span class='notice'>Вы чувствуете себя более уверенно в реальности.</span>"

/datum/brain_trauma/mild/hallucinations/on_life()
	if(HAS_TRAIT(owner, TRAIT_RDS_SUPPRESSED))
		owner.hallucination = max(0, owner.hallucination - PROTEAN_HALLUCINATION_RECOVERY)
		return
	owner.hallucination = min(owner.hallucination + 10, 50)
	..()

/datum/brain_trauma/mild/hallucinations/on_lose()
	owner.hallucination = 0
	..()

/datum/brain_trauma/mild/stuttering
	name = "Stuttering"
	desc = "Пациент не может говорить чётко."
	scan_desc = "нарушенная координация речи"
	gain_text = "<span class='warning'>Говорить чётко становится всё сложнее.</span>"
	lose_text = "<span class='notice'>Вы снова контролируете свою речь.</span>"

/datum/brain_trauma/mild/stuttering/on_life()
	owner.stuttering = min(owner.stuttering + 5, 25)
	..()

/datum/brain_trauma/mild/stuttering/on_lose()
	owner.stuttering = 0
	..()

/datum/brain_trauma/mild/dumbness
	name = "Dumbness"
	desc = "У пациента снижена мозговая активность, из-за чего он становится менее сообразительным."
	scan_desc = "сниженная мозговая активность"
	gain_text = "<span class='warning'>Вы чувствуете себя глупее.</span>"
	lose_text = "<span class='notice'>Вы снова чувствуете себя умным.</span>"

/datum/brain_trauma/mild/dumbness/on_gain()
	ADD_TRAIT(owner, TRAIT_DUMB, TRAUMA_TRAIT)
	SEND_SIGNAL(owner, COMSIG_ADD_MOOD_EVENT, "dumb", /datum/mood_event/oblivious)
	..()

/datum/brain_trauma/mild/dumbness/on_life()
	owner.derpspeech = min(owner.derpspeech + 5, 25)
	if(prob(3))
		owner.emote("drool")
	else if(owner.stat == CONSCIOUS && prob(3))
		var/braindamage_variant = isrobotic(owner) ? "synth_brain_damage" : "brain_damage"
		owner.say(pick_list_replacements(BRAIN_DAMAGE_FILE, braindamage_variant), forced = "brain damage")
	..()

/datum/brain_trauma/mild/dumbness/on_lose()
	REMOVE_TRAIT(owner, TRAIT_DUMB, TRAUMA_TRAIT)
	owner.derpspeech = 0
	SEND_SIGNAL(owner, COMSIG_CLEAR_MOOD_EVENT, "dumb")
	..()

/datum/brain_trauma/mild/speech_impediment
	name = "Speech Impediment"
	desc = "Пациент не может формировать связные предложения."
	scan_desc = "коммуникативное расстройство"
	gain_text = "<span class='danger'>Вы не можете связать две мысли воедино!</span>"
	lose_text = "<span class='danger'>Ваш разум проясняется.</span>"

/datum/brain_trauma/mild/speech_impediment/on_gain()
	ADD_TRAIT(owner, TRAIT_UNINTELLIGIBLE_SPEECH, TRAUMA_TRAIT)
	..()

/datum/brain_trauma/mild/speech_impediment/on_lose()
	REMOVE_TRAIT(owner, TRAIT_UNINTELLIGIBLE_SPEECH, TRAUMA_TRAIT)
	..()

/datum/brain_trauma/mild/concussion
	name = "Concussion"
	desc = "У пациента сотрясение мозга."
	scan_desc = "сотрясение мозга"
	gain_text = "<span class='warning'>У вас болит голова!</span>"
	lose_text = "<span class='notice'>Давление в голове начинает стихать.</span>"

/datum/brain_trauma/mild/concussion/on_life()
	if(!owner || QDELETED(owner))
		return
	if(prob(5))
		switch(rand(1,11))
			if(1)
				owner.vomit()
			if(2,3)
				owner.dizziness += 10
			if(4,5)
				owner.confused += 10
				owner.blur_eyes(10)
			if(6 to 9)
				owner.slurring += 30
			if(10)
				to_chat(owner, "<span class='notice'>Вы на мгновение забываете, чем занимались.</span>")
				owner.Stun(20)
			if(11)
				to_chat(owner, "<span class='warning'>Вы теряете сознание.</span>")
				owner.Unconscious(80)
	owner.AdjustConfused(5 SECONDS, 10, 20)
	..()

/datum/brain_trauma/mild/concussion/on_lose()
	owner.cut_overlays()
	owner.regenerate_icons()
	..()

/datum/brain_trauma/mild/healthy
	name = "Anosognosia"
	desc = "Пациент всегда чувствует себя здоровым, независимо от своего состояния."
	scan_desc = "дефицит самосознания"
	gain_text = "<span class='notice'>Вы чувствуете себя великолепно!</span>"
	lose_text = "<span class='warning'>Вы больше не чувствуете себя идеально здоровым.</span>"

/datum/brain_trauma/mild/healthy/on_gain()
	owner.set_screwyhud(SCREWYHUD_HEALTHY)
	..()

/datum/brain_trauma/mild/healthy/on_life()
	owner.set_screwyhud(SCREWYHUD_HEALTHY) //just in case of hallucinations
	owner.adjustStaminaLoss(-5) //no pain, no fatigue
	..()

/datum/brain_trauma/mild/healthy/on_lose()
	owner.set_screwyhud(SCREWYHUD_NONE)
	..()

/datum/brain_trauma/mild/muscle_weakness
	name = "Muscle Weakness"
	desc = "Пациент испытывает периодические приступы мышечной слабости."
	scan_desc = "слабый сигнал двигательных нервов"
	gain_text = "<span class='warning'>Ваши мышцы ощущаются странно слабыми.</span>"
	lose_text = "<span class='notice'>Вы снова контролируете свои мышцы.</span>"

/datum/brain_trauma/mild/muscle_weakness/on_life()
	if(QDELETED(owner) || !owner)
		return
	var/fall_chance = 1
	if(owner.m_intent == MOVE_INTENT_RUN)
		fall_chance += 2
	if(prob(fall_chance) && !owner.lying && !owner.buckled)
		to_chat(owner, "<span class='warning'>Нога подкашивается!</span>")
		owner.DefaultCombatKnockdown(35)

	else if(owner.get_active_held_item())
		var/drop_chance = 1
		var/obj/item/I = owner.get_active_held_item()
		drop_chance += I.w_class
		if(prob(drop_chance) && owner.dropItemToGround(I))
			to_chat(owner, "<span class='warning'>Вы роняете [I]!</span>")

	else if(prob(3))
		to_chat(owner, "<span class='warning'>Вы чувствуете внезапную слабость в мышцах!</span>")
		owner.adjustStaminaLoss(50)
	..()

/datum/brain_trauma/mild/muscle_spasms
	name = "Muscle Spasms"
	desc = "У пациента случаются мышечные спазмы, из-за которых он непроизвольно двигается."
	scan_desc = "нервные припадки"
	gain_text = "<span class='warning'>Ваши мышцы ощущаются странно слабыми.</span>"
	lose_text = "<span class='notice'>Вы снова контролируете свои мышцы.</span>"

/datum/brain_trauma/mild/muscle_spasms/on_gain()
	owner.apply_status_effect(STATUS_EFFECT_SPASMS)
	..()

/datum/brain_trauma/mild/muscle_spasms/on_lose()
	owner.remove_status_effect(STATUS_EFFECT_SPASMS)
	..()

/datum/brain_trauma/mild/nervous_cough
	name = "Nervous Cough"
	desc = "Пациент испытывает постоянную потребность кашлять."
	scan_desc = "нервный кашель"
	gain_text = "<span class='warning'>В горле невыносимо першит...</span>"
	lose_text = "<span class='notice'>Першение в горле проходит.</span>"

/datum/brain_trauma/mild/nervous_cough/on_life()
	if(QDELETED(owner) || !owner)
		return
	if(prob(12) && !HAS_TRAIT(owner, TRAIT_SOOTHED_THROAT))
		if(prob(5))
			to_chat(owner, "<span notice='warning'>[pick("У вас приступ кашля!", "Вы не можете перестать кашлять!")]</span>")
			owner.Stun(20)
			owner.emote("cough")
			addtimer(CALLBACK(owner, TYPE_PROC_REF(/mob, emote), "cough"), 6)
			addtimer(CALLBACK(owner, TYPE_PROC_REF(/mob, emote), "cough"), 12)
		owner.emote("cough")
	..()

/datum/brain_trauma/mild/expressive_aphasia
	name = "Expressive Aphasia"
	desc = "Пациент страдает частичной потерей речи, из-за чего его словарный запас сокращается."
	scan_desc = "неспособность строить сложные предложения"
	gain_text = "<span class='warning'>Вы теряете хватку за сложные слова.</span>"
	lose_text = "<span class='notice'>Ваш словарный запас снова возвращается в норму.</span>"

	var/static/list/common_words = world.file2list("strings/1000_most_common.txt")

/datum/brain_trauma/mild/expressive_aphasia/handle_speech(datum/source, list/speech_args)
	var/message = speech_args[SPEECH_MESSAGE]
	if(message)
		var/list/message_split = splittext(message, " ")
		var/list/new_message = list()

		for(var/word in message_split)
			var/suffix = ""
			var/suffix_foundon = 0
			for(var/potential_suffix in list("." , "," , ";" , "!" , ":" , "?"))
				suffix_foundon = findtext(word, potential_suffix, -length(potential_suffix))
				if(suffix_foundon)
					suffix = potential_suffix
					break

			if(suffix_foundon)
				word = copytext(word, 1, suffix_foundon)

			word = html_decode(word)

			if(lowertext(word) in common_words)
				new_message += word + suffix
			else
				if(prob(30) && message_split.len > 2)
					new_message += pick("uh","erm")
					break
				else
					var/list/charlist = text2charlist(word)
					shuffle_inplace(charlist)
					new_message += jointext(charlist, "") + suffix

		message = jointext(new_message, " ")

	speech_args[SPEECH_MESSAGE] = trim(message)

/datum/brain_trauma/mild/mind_echo
	name = "Mind Echo"
	desc = "Языковые нейроны пациента не завершают работу должным образом, из-за чего прежние речевые паттерны иногда спонтанно всплывают."
	scan_desc = "зацикленный нейронный паттерн"
	gain_text = "<span class='warning'>Вы чувствуете слабое эхо своих мыслей...</span>"
	lose_text = "<span class='notice'>Слабое эхо затихает.</span>"
	var/list/hear_dejavu = list()
	var/list/speak_dejavu = list()

/datum/brain_trauma/mild/mind_echo/handle_hearing(datum/source, list/hearing_args)
	if(owner == hearing_args[HEARING_SPEAKER])
		return
	if(hear_dejavu.len >= 5)
		if(prob(25))
			var/deja_vu = pick_n_take(hear_dejavu)
			var/static/regex/quoted_spoken_message = regex("\".+\"", "gi")
			hearing_args[HEARING_RAW_MESSAGE] = quoted_spoken_message.Replace(hearing_args[HEARING_RAW_MESSAGE], "\"[deja_vu]\"") //Quotes included to avoid cases where someone says part of their name
			return
	if(hear_dejavu.len >= 15)
		if(prob(50))
			popleft(hear_dejavu) //Remove the oldest
			hear_dejavu += hearing_args[HEARING_RAW_MESSAGE]
	else
		hear_dejavu += hearing_args[HEARING_RAW_MESSAGE]

/datum/brain_trauma/mild/mind_echo/handle_speech(datum/source, list/speech_args)
	if(speak_dejavu.len >= 5)
		if(prob(25))
			var/deja_vu = pick_n_take(speak_dejavu)
			speech_args[SPEECH_MESSAGE] = deja_vu
			return
	if(speak_dejavu.len >= 15)
		if(prob(50))
			popleft(speak_dejavu) //Remove the oldest
			speak_dejavu += speech_args[SPEECH_MESSAGE]
	else
		speak_dejavu += speech_args[SPEECH_MESSAGE]

/datum/brain_trauma/mild/redacted
	name = "Confidentiality Trauma"
	desc = "Языковые нейроны пациента искажены странным образом, из-за чего он не может говорить нормально."
	scan_desc = "<b>\[УДАЛЕНО]</b>"
	gain_text = "<span class='warning'>Вы чувствуете потребность <b>\[УДАЛЕНО]</b></span>"
	lose_text = "<span class='notice'>Вы больше не чувствуете потребности <b>\[УДАЛЕНО]</b>.</span>"

/datum/brain_trauma/mild/redacted/handle_speech(datum/source, list/speech_args)
	var/message = speech_args[SPEECH_MESSAGE]
	if(message)
		var/list/message_split = splittext(message, " ")
		var/list/new_message = list()

		for(var/word in message_split)
			var/suffix = ""
			var/suffix_foundon = 0
			for(var/potential_suffix in list("." , "," , ";" , "!" , ":" , "?"))
				suffix_foundon = findtext(word, potential_suffix, -length(potential_suffix))
				if(suffix_foundon)
					suffix = potential_suffix
					break

			if(suffix_foundon)
				word = copytext(word, 1, suffix_foundon)

			word = html_decode(word)

			if(prob(25))
				word = pick(list("<b>\[УДАЛЕНО]</b>", "<b>\[ЗАСЕКРЕЧЕНО]</b>", "<b>\[ИЗЪЯТО]</b>"))
			new_message += word + suffix
		message = jointext(new_message, " ")
	speech_args[SPEECH_MESSAGE] = trim(message)
