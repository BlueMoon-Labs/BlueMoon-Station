/datum/language/modular_bluemoon/vox
	name = "Vox-Pidgin"
	desc = "A language comprised largely of screeching and squawking sounds. The language is largely shared only between Vox. (Используйте русскую букву для префикса)"
	icon = 'modular_bluemoon/icons/misc/language.dmi'
	icon_state = "vox"
	speech_verb = "shrieks"
	ask_verb = "queries"
	exclaim_verb = "declares"
	whisper_verb = "hushes"
	key = "в"
	space_chance = 75
	default_priority = 99
	syllables = list("ti","ti","ti","hi","hi","ki","ki","ki","ki","ya","ta","ha","ka","ya", "yi", "chi","cha","kah","SKRE","AHK","EHK","RAWK","KRA","AAA","EEE","KI","II","KRI","KA")
	restricted = TRUE
	spans = list(SPAN_VOXSHRIEK)
