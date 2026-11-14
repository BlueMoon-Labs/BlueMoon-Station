/datum/language/drone
	name = "Drone"
	desc = "Сильно закодированный поток координации работ по ликвидации аварий, со специальными флагами для шляп."
	speech_verb = "chitters"
	ask_verb = "chitters inquisitively"
	exclaim_verb = "chitters loudly"
	spans = list(SPAN_ROBOT)
	key = "d"
	flags = NO_STUTTER
	syllables = list(".", "|")
	// ...|..||.||||.|.||.|.|.|||.|||
	space_chance = 0
	sentence_chance = 0
	default_priority = 20

	icon_state = "drone"
	//SKYRAT CHANGE - language restriction
	restricted = TRUE
	//
