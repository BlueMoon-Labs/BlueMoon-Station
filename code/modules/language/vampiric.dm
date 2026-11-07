//	BLOODSUCKER LANGUAGE //

/datum/language/vampiric
	name = "Blah-Sucker"
	desc = "Родной язык старейших Кровопийц. Птенцы усваивают его интуитивно, переходя от смерти к бессмертию; обращённые получают право говорить на нём как часть ритуала посвящения."
	speech_verb = "growls"
	ask_verb = "growls"
	exclaim_verb = "snarls"
	whisper_verb = "hisses"
	key = "b"
	space_chance = 40
	default_priority = 90
	icon_state = "bloodsucker"
	//SKYRAT CHANGE - language restriction
	restricted = TRUE
	//

	flags =  LANGUAGE_HIDE_ICON_IF_NOT_UNDERSTOOD // Hide the icon next to your text if someone doesn't know this language. (TONGUELESS_SPEECH bluemoon change)
	syllables = list(
		"luk","cha","no","kra","pru","chi","busi","tam","pol","spu","och",		// Start: Vampiric
		"umf","ora","stu","si","ri","li","ka","red","ani","lup","ala","pro",
		"to","siz","nu","pra","ga","ump","ort","a","ya","yach","tu","lit",
		"wa","mabo","mati","anta","tat","tana","prol",
		"tsa","si","tra","te","ele","fa","inz",									// Start: Romanian
		"nza","est","sti","ra","pral","tsu","ago","esch","chi","kys","praz",	// Start: Custom
		"froz","etz","tzil",
		"t'","k'","t'","k'","th'","tz'"
		)
