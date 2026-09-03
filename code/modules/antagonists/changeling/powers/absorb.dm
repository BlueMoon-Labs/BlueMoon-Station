/datum/action/changeling/absorbDNA
	name = "Absorb DNA"
	desc = "Absorb the DNA of our victim. Requires us to strangle them."
	button_icon_state = "absorb_dna"
	dna_cost = 0
	req_human = TRUE

/datum/action/changeling/absorbDNA/can_sting(mob/living/carbon/user)
	if(!..())
		return

	var/datum/antagonist/changeling/changeling = user.mind.has_antag_datum(/datum/antagonist/changeling)
	if(changeling.isabsorbing)
		to_chat(user, "<span class='warning'>We are already absorbing!</span>")
		return

	if(!user.pulling || !iscarbon(user.pulling))
		to_chat(user, "<span class='warning'>We must be grabbing a creature to absorb them!</span>")
		return
	if(user.grab_state <= GRAB_NECK)
		to_chat(user, "<span class='warning'>We must have a tighter grip to absorb this creature!</span>")
		return

	var/mob/living/carbon/target = user.pulling
	return changeling.can_absorb_dna(target)



/datum/action/changeling/absorbDNA/sting_action(mob/user)
	var/datum/antagonist/changeling/changeling = user.mind.has_antag_datum(/datum/antagonist/changeling)
	var/mob/living/carbon/human/target = user.pulling
	changeling.isabsorbing = 1
	for(var/i in 1 to 3)
		switch(i)
			if(1)
				to_chat(user, "<span class='notice'>This creature is compatible. We must hold still...</span>")
			if(2)
				user.visible_message("<span class='warning'>[user] extends a proboscis!</span>", "<span class='notice'>We extend a proboscis.</span>")
			if(3)
				user.visible_message("<span class='danger'>[user] stabs [target] with the proboscis!</span>", "<span class='notice'>We stab [target] with the proboscis.</span>")
				to_chat(target, "<span class='userdanger'>You feel a sharp stabbing pain!</span>")
				target.take_overall_damage(40)

		SSblackbox.record_feedback("nested tally", "changeling_powers", 1, list("Absorb DNA", "[i]"))
		if(!do_mob(user, target, 150))
			to_chat(user, "<span class='warning'>Our absorption of [target] has been interrupted!</span>")
			changeling.isabsorbing = 0
			return

	SSblackbox.record_feedback("nested tally", "changeling_powers", 1, list("Absorb DNA", "4"))
	user.visible_message("<span class='danger'>[user] sucks the fluids from [target]!</span>", "<span class='notice'>We have absorbed [target].</span>")
	to_chat(target, "<span class='userdanger'>You are absorbed by the changeling!</span>")

	if(!changeling.has_dna(target.dna))
		changeling.add_new_profile(target)
		changeling.trueabsorbs++

	if(user.nutrition < NUTRITION_LEVEL_WELL_FED)
		user.adjust_nutrition(target.nutrition, NUTRITION_LEVEL_WELL_FED)
	if(get_thirst(user) < THIRST_LEVEL_QUENCHED)
		user.adjust_thirst(target.thirst, THIRST_LEVEL_QUENCHED)

	// Absorb a lizard, speak Draconic.
	user.copy_languages(target, LANGUAGE_ABSORB)

	if(target.mind && user.mind)//if the victim and user have minds
//ambition start
		// Получателя надо передавать явно: без него show_memory подставляет current,
		// то есть окно с воспоминаниями открывалось у ЖЕРТВЫ, а генокраду уходил
		// пустой <i></i>. window = FALSE печатает записи в чат тому, кто поглощает.
		target.mind.show_memory(user, window = FALSE) //I can read your mind, kekeke. Output all their notes.
//ambition end

		//Some of target's recent speech, so the changeling can attempt to imitate them better.
		//Recent as opposed to all because rounds tend to have a LOT of text.
		var/list/recent_speech = list()

		// Ключ - ТЕКСТ, а не число: log_message() кладёт записи под num2text(тип), и
		// logging[LOG_SAY] на ассоциативном списке со строковыми ключами - это обращение
		// по ПОЗИЦИИ, то есть второй ключ вместо лога речи. Дальше строка выдавалась за
		// список, и речь жертвы генокрад не получал вообще ни разу.
		var/list/say_log = target.logging[num2text(LOG_SAY)]
		var/entries = LAZYLEN(say_log)
		// Запись - ассоциативный список полей (см. /mob/log_message), сама фраза лежит
		// в "what". До переработки лог-вьювера здесь лежали строки, отсюда и старый обход.
		for(var/index = max(1, entries - LING_ABSORB_RECENT_SPEECH + 1) to entries)
			var/list/entry = say_log[index]
			if(!islist(entry))
				continue
			var/spoken = entry["what"]
			if(spoken)
				recent_speech += spoken

		if(recent_speech.len)
			changeling.antag_memory += "<B>Some of [target]'s speech patterns, we should study these to better impersonate [target.ru_na()]!</B><br>"
			to_chat(user, "<span class='boldnotice'>Some of [target]'s speech patterns, we should study these to better impersonate [target.ru_na()]!</span>")
			for(var/spoken_memory in recent_speech)
				changeling.antag_memory += "\"[spoken_memory]\"<br>"
				to_chat(user, "<span class='notice'>\"[spoken_memory]\"</span>")
			changeling.antag_memory += "<B>We have no more knowledge of [target]'s speech patterns.</B><br>"
			to_chat(user, "<span class='boldnotice'>We have no more knowledge of [target]'s speech patterns.</span>")


		var/datum/antagonist/changeling/target_ling = target.mind.has_antag_datum(/datum/antagonist/changeling)
		if(target_ling && !target_ling.hostile_absorbed)//If the target was a changeling, suck out their extra juice and objective points!
			to_chat(user, "<span class='boldnotice'>[target] was one of us. We have absorbed their power.</span>")
			target_ling.remove_changeling_powers()
			changeling.geneticpoints += round(target_ling.geneticpoints/2)
			changeling.maxgeneticpoints += round(target_ling.geneticpoints/2)
			target_ling.geneticpoints = 0
			target_ling.can_respec = 0
			changeling.chem_storage += round(target_ling.chem_storage/2)
			changeling.chem_charges += min(target_ling.chem_charges, changeling.chem_storage)
			target_ling.chem_charges = 0
			target_ling.hostile_absorbed = TRUE
			target_ling.chem_storage = 0
			changeling.absorbedcount += (target_ling.absorbedcount)
			target_ling.stored_profiles.len = 1
			target_ling.absorbedcount = 0


	changeling.chem_charges=min(changeling.chem_charges+10, changeling.chem_storage)

	changeling.isabsorbing = 0
	changeling.can_respec = 1

	target.death(0)
	target.Drain()
	return TRUE
