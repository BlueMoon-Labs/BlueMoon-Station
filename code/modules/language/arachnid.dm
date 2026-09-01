/datum/language/arachnid
	name = "Rachnidian"
	desc = "A language that exploits the multiple limbs of arachnids to do subtle dance like movements to communicate.\
	A proper speaker's movements are quick and sharp enough to make audible whiffs and thumps however, which are intelligible over the radio."
	speech_verb = "chitter"
	ask_verb = "chitter"
	exclaim_verb = "chitter"
	key = "c"
	default_priority = 95
	syllables = list(
		"za", "az", "ze", "ez", "zi", "iz", "zo", "oz", "zu", "uz", "zs", "sz",
		"ha", "ah", "he", "eh", "hi", "ih", "ho", "oh", "hu", "uh", "hs", "sh",
		"la", "al", "le", "el", "li", "il", "lo", "ol", "lu", "ul", "ls", "sl",
		"ka", "ak", "ke", "ek", "ki", "ik", "ko", "ok", "ku", "uk", "ks", "sk",
		"sa", "as", "se", "es", "si", "is", "so", "os", "su", "us", "ss", "ss",
		"ra", "ar", "re", "er", "ri", "ir", "ro", "or", "ru", "ur", "rs", "sr",
		"a",  "a",  "e",  "e",  "i",  "i",  "o",  "o",  "u",  "u",  "s",  "s"
	)
	flags = NO_STUTTER | LANGUAGE_HIDE_ICON_IF_NOT_UNDERSTOOD

	icon_state = "arachnid"
	//SKYRAT CHANGE - language restriction
	restricted = FALSE
	//
	//arachnid tongue carries no accents, so style via the language itself
	spans = list(SPAN_CHITVOICE)

/datum/language/arachnid/scramble(input)
	. = prob(65) ? "<i>wiff</i>" : "<i>thump</i>"
	. += (copytext(input, length(input)) == "?") ? "?" : "!"
