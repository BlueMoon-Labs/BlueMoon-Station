/datum/language/ratvar
	name = "Ratvarian"
	desc = "Вневременной язык, полный власти и непостижимый для непросвещённых."
	var/static/random_speech_verbs = list("clanks", "clinks", "clunks", "clangs")
	ask_verb = "requests"
	exclaim_verb = "proclaims"
	whisper_verb = "imparts"
	key = "r"
	default_priority = 10
	spans = list(SPAN_ROBOT)
	icon_state = "ratvar"
	//SKYRAT CHANGE - language restriction
	restricted = TRUE
	//

/datum/language/ratvar/scramble(var/input)
	var/govno = "" // bluemoon change start
	while(length_char(govno) < length_char(input))
		govno += pickweight(list( "a", "b", "c", "d", "f", "g", "e", "r", "'", " " = 3)) //я нихуя не понимаю, как это починить. В теории оно должно заменять любые буквы на рандомные английские и передавать дальше функции, но это не работает. Главное что теперь другие перестанут понимать ратварский, а пусть нормально фиксит кто то другой.
	input = govno // bluemoon change end
	. = text2ratvar(input)

/datum/language/ratvar/get_spoken_verb(msg_end)
	if(!msg_end)
		return pick(random_speech_verbs)
	return ..()
