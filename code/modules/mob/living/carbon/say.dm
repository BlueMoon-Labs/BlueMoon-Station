/mob/living/carbon/proc/handle_tongueless_speech(mob/living/carbon/speaker, list/speech_args)
	SIGNAL_HANDLER
	var/datum/language/speaking = speech_args[SPEECH_LANGUAGE]
	if(speaking && initial(speaking.visual_language)) //жесты языком не выговаривают
		return
	var/message = speech_args[SPEECH_MESSAGE]
	var/static/regex/tongueless_lower = new("\[gdntke]+", "g")
	var/static/regex/tongueless_upper = new("\[GDNTKE]+", "g")
	if(message[1] != "*" && message[1] != "!")
		message = tongueless_lower.Replace(message, pick("aa","oo","'"))
		message = tongueless_upper.Replace(message, pick("AA","OO","'"))
		speech_args[SPEECH_MESSAGE] = message

/mob/living/carbon/can_speak_vocal(message, datum/language/speaking = null)
	var/datum/language/selected_lang = speaking || get_selected_language()
	var/is_visual = selected_lang && initial(selected_lang.visual_language)
	if(silent && !is_visual) //немота глушит голос, а не руки
		return FALSE
	if(is_visual && handcuffed)
		return FALSE
	return ..()

/mob/living/carbon/could_speak_language(datum/language/language)
	var/obj/item/organ/tongue/T = getorganslot(ORGAN_SLOT_TONGUE)
	if(!QDELETED(T))
		return T.could_speak_language(language)
	else
		return initial(language.flags) & TONGUELESS_SPEECH
