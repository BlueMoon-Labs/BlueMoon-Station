/datum/language/draconic
	name = "Draconic"
	desc = "Общий язык ящеролюдей, сложенный из шипения и сухого треска."
	speech_verb = "hisses"
	ask_verb = "hisses"
	exclaim_verb = "roars"
	key = "o"
	//flags = TONGUELESS_SPEECH bluemoon change
	space_chance = 40
	syllables = list(
		"za", "az", "ze", "ez", "zi", "iz", "zo", "oz", "zu", "uz", "zs", "sz",
		"ha", "ah", "he", "eh", "hi", "ih", "ho", "oh", "hu", "uh", "hs", "sh",
		"la", "al", "le", "el", "li", "il", "lo", "ol", "lu", "ul", "ls", "sl",
		"ka", "ak", "ke", "ek", "ki", "ik", "ko", "ok", "ku", "uk", "ks", "sk",
		"sa", "as", "se", "es", "si", "is", "so", "os", "su", "us", "ss", "ss",
		"ra", "ar", "re", "er", "ri", "ir", "ro", "or", "ru", "ur", "rs", "sr",
		"a",  "a",  "e",  "e",  "i",  "i",  "o",  "o",  "u",  "u",  "s",  "s"
	)
	icon_state = "lizard"
	default_priority = 90
	//SKYRAT CHANGE - language restriction
	restricted = FALSE
	//
