/datum/language/signlanguage
	name = "Space Sign Language"
	desc = "Те, кто не может говорить, могут выучить его вместо речи."
	speech_verb = "signs"
	whisper_verb = "gestures"
	key = "9"
	flags = TONGUELESS_SPEECH
	visual_language = TRUE

	syllables = list(".")
	spans = list(SPAN_SIGNLANG)

	icon_state = "ssl"
	default_priority = 90
	//SKYRAT CHANGE - language restriction
	restricted = FALSE
	//
