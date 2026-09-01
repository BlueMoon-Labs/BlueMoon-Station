/mob/living/treat_message(message, datum/language/speaking = null)
	if (HAS_TRAIT(src, TRAIT_TONGUELESS_SPEECH)) //this exists solely because deprivation helms
		message = detongueify(message)
	. = ..(message, speaking)
