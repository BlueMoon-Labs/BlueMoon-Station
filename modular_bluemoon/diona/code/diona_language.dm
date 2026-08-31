/datum/language/rootsong
	name = "Rootsong"
	desc = "Сложный язык дион, 'произносимый' скрипом и шорохом модулированных волн, инстинктивно понятный каждой нимфе гештальта."
	speech_verb = "скрипит и шелестит"
	ask_verb = "скрипит"
	exclaim_verb = "шелестит"
	key = "q"
	flags = TONGUELESS_SPEECH
	space_chance = 10
	syllables = list(
		"хс", "зт", "кр", "ст", "ш", "хса", "зц", "крр", "стс", "шу",
		"хск", "зк", "кж", "срк", "сс", "хсс", "жжт", "кст", "срт", "шк"
	)
	icon_state = "plant"
	default_priority = 90
	restricted = FALSE

/datum/language_holder/diona
	understood_languages = list(/datum/language/common = list(LANGUAGE_ATOM),
								/datum/language/rootsong = list(LANGUAGE_ATOM))
	spoken_languages = list(/datum/language/common = list(LANGUAGE_ATOM),
							/datum/language/rootsong = list(LANGUAGE_ATOM))
