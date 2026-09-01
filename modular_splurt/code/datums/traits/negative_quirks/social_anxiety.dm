/datum/quirk/social_anxiety
	name = "Социофобия"
	desc = "Вам с трудом даётся общение с другими — вы часто заикаетесь или даже замыкаетесь."
	value = -1
	gain_text = "<span class='danger'>Вы начинаете волноваться о своих словах.</span>"
	lose_text = "<span class='notice'>Вам становится легче говорить.</span>" //if only it were that easy!
	medical_record_text = "Пациент предпочитает избегать социальных взаимодействий."
	mob_trait = TRAIT_ANXIOUS
	var/dumb_thing = TRUE
	processing_quirk = FALSE

/datum/quirk/social_anxiety/add()
	. = ..()
	RegisterSignal(quirk_holder, COMSIG_MOB_EYECONTACT, PROC_REF(eye_contact))
	RegisterSignal(quirk_holder, COMSIG_MOB_EXAMINATE, PROC_REF(looks_at_floor))
	RegisterSignal(quirk_holder, COMSIG_MOB_SAY, PROC_REF(handle_speech))

/datum/quirk/social_anxiety/remove()
	. = ..()
	UnregisterSignal(quirk_holder, COMSIG_MOB_SAY)
	UnregisterSignal(quirk_holder, list(COMSIG_MOB_EYECONTACT, COMSIG_MOB_EXAMINATE))

/datum/quirk/social_anxiety/on_process()
	var/nearby_people = 0
	for(var/mob/living/carbon/human/H in oview(3, quirk_holder))
		if(H.client)
			nearby_people++
	var/mob/living/carbon/human/H = quirk_holder
	if(prob(2 + nearby_people))
		H.stuttering = max(3, H.stuttering)
	else if(prob(min(3, nearby_people)) && !H.silent)
		to_chat(H, "<span class='danger'>Вы замыкаетесь в себе. Вы <i>действительно</i> не в настроении для разговоров.</span>")
		H.silent = max(10, H.silent)
	else if(prob(0.5) && dumb_thing)
		to_chat(H, "<span class='userdanger'>Вы думаете о глупости, сказанной давно, и сгораете от стыда.</span>")
		dumb_thing = FALSE //only once per life
		if(prob(1))
			new/obj/item/reagent_containers/food/snacks/pastatomato(get_turf(H)) //now that's what I call spaghetti code

// small chance to make eye contact with inanimate objects/mindless mobs because of nerves
/datum/quirk/social_anxiety/proc/looks_at_floor(datum/source, atom/A)
	var/mob/living/mind_check = A
	if(prob(85) || (istype(mind_check) && mind_check.mind))
		return

	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(to_chat), quirk_holder, "<span class='smallnotice'>Вы пересекаетесь взглядами с [A].</span>"), 3)

/datum/quirk/social_anxiety/proc/eye_contact(datum/source, mob/living/other_mob, triggering_examiner)
	if(prob(75))
		return
	var/msg
	if(triggering_examiner)
		msg = "Вы смотрите на [other_mob], "
	else
		msg = "[other_mob] смотрит на вас, "

	switch(rand(1,3))
		if(1)
			quirk_holder.Jitter(10)
			msg += "из-за чего вы начинаете ёрзать!"
		if(2)
			quirk_holder.stuttering = max(3, quirk_holder.stuttering)
			msg += "из-за чего вы начинаете заикаться!"
		if(3)
			quirk_holder.Stun(2 SECONDS)
			msg += "из-за чего вы замираете!"

	SEND_SIGNAL(quirk_holder, COMSIG_ADD_MOOD_EVENT, "anxiety_eyecontact", /datum/mood_event/anxiety_eyecontact)
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(to_chat), quirk_holder, "<span class='userdanger'>[msg]</span>"), 3) // so the examine signal has time to fire and this will print after
	return COMSIG_BLOCK_EYECONTACT

/datum/quirk/social_anxiety/proc/handle_speech(datum/source, list/speech_args)
	SIGNAL_HANDLER

	if(HAS_TRAIT(quirk_holder, TRAIT_FEARLESS))
		return

	var/datum/language/speaking = quirk_holder.get_message_language(speech_args[SPEECH_MESSAGE])
	if(!speaking)
		speaking = quirk_holder.get_selected_language()
	if(speaking && initial(speaking.visual_language))
		return

	var/datum/component/mood/mood = quirk_holder.GetComponent(/datum/component/mood)
	var/moodmod
	if(mood)
		moodmod = (1+0.02*(50-(max(50, mood.mood_level*(7-mood.sanity_level))))) //low sanity levels are better, they max at 6
	else
		moodmod = (1+0.02*(50-(max(50, 0.1*quirk_holder.nutrition))))
	var/nearby_people = 0
	for(var/mob/living/carbon/human/H in oview(3, quirk_holder))
		if(H.client)
			nearby_people++
	var/message = speech_args[SPEECH_MESSAGE]
	if(message)
		var/list/message_split = splittext(message, " ")
		var/list/new_message = list()
		var/mob/living/carbon/human/quirker = quirk_holder
		for(var/word in message_split)
			if(prob(max(5,(nearby_people*12.5*moodmod))) && word != message_split[1]) //Minimum 1/20 chance of filler
				new_message += pick("а,","э,","мм,")
				if(prob(min(5,(0.05*(nearby_people*12.5)*moodmod)))) //Max 1 in 20 chance of cutoff after a succesful filler roll, for 50% odds in a 15 word sentence
					quirker.silent = max(3, quirker.silent)
					to_chat(quirker, span_danger("Вы чувствуете себя неловко и перестаёте говорить. Вам необходимо прийти в себя!"))
					break
			if(prob(max(5,(nearby_people*12.5*moodmod)))) //Minimum 1/20 chance of stutter
				// Add a short stutter, THEN treat our word
				quirker.stuttering = max(0.25, quirker.stuttering)
				new_message += quirker.treat_message(word)

			else
				new_message += word

		message = jointext(new_message, " ")
	var/mob/living/carbon/human/quirker = quirk_holder
	if(prob(min(50,(0.50*(nearby_people*12.5)*moodmod)))) //Max 50% chance of not talking
		if(dumb_thing)
			to_chat(quirker, span_userdanger("Вы думаете о глупости, сказанной давно, и сгораете от стыда."))
			dumb_thing = FALSE //only once per life
			if(prob(1))
				new/obj/item/reagent_containers/food/snacks/pastatomato(get_turf(quirker)) //now that's what I call spaghetti code
		else
			to_chat(quirk_holder, span_warning("Вы считаете, что не способны поддержать разговор, и потому отмалчиваетесь."))
			if(prob(min(25,(0.25*(nearby_people*12.75)*moodmod)))) //Max 25% chance of silence stacks after succesful not talking roll
				to_chat(quirker, span_danger("Вы замыкаетесь в себе. Вы <i>действительно</i> не в настроении для разговоров."))
				quirker.silent = max(5, quirker.silent)
		speech_args[SPEECH_MESSAGE] = pick("А.","Э.","Мм.")
	else
		speech_args[SPEECH_MESSAGE] = message
