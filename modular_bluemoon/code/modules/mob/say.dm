/mob/verb/whisper_typing_indicator()
	set name = "Whisper (Indicator)"
	set hidden = TRUE
	set category = "Say"
	if(GLOB.say_disabled)	//This is here to try to identify lag problems
		to_chat(usr, "<span class='danger'>Speech is currently admin-disabled.</span>")
		return
	display_typing_indicator(isSay = TRUE)
	
	var/message = ""
	if(client?.prefs.tgui_input_verbs)
		message = tgui_input_text(src, "", "Whisper (Indicator)", null, MAX_MESSAGE_LEN, encode = TRUE)
	else
		message = stripped_input(src, "", "Whisper (Indicator)")

	clear_typing_indicator()
	if(!length(message))
		return
	whisper(message)
