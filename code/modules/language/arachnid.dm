/datum/language/arachnid
	name = "Rachnidian"
	desc = "Язык, в котором пауки используют множество своих конечностей для тонких, танцевальных движений. У настоящего собеседника движения достаточно быстры и чётки, чтобы издавать слышимые свисты и удары, различимые даже по радио."
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
	// Спиздите сюда пожалуйста стейт арахнидов, мне лень
	icon_state = "spider"
	//SKYRAT CHANGE - language restriction
	restricted = FALSE
	//
	//arachnid tongue carries no accents, so style via the language itself
	spans = list(SPAN_CHITVOICE)

/datum/language/arachnid/scramble(input)
	. = prob(65) ? "<i>wiff</i>" : "<i>thump</i>"
	. += (copytext(input, length(input)) == "?") ? "?" : "!"
