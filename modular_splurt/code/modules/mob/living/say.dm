/mob/living/treat_message(message, datum/language/speaking = null)
	if(HAS_TRAIT(src, TRAIT_TONGUELESS_SPEECH) && !(speaking && initial(speaking.visual_language)))
		message = detongueify(message)
	. = ..(message, speaking)
