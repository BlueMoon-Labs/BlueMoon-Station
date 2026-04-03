/client/proc/cmd_mentor_say()
	set category = "Mentor"
	set name = "Msay" //Gave this shit a shorter name so you only have to time out "msay" rather than "mentor say" to use it --NeoFite
	set hidden = 1
	if(!is_mentor())
		return

	var/message = ""
	if(prefs.tgui_input_verbs)
		message = tgui_input_text(src, "", "msay \"text\"", "", MAX_MESSAGE_LEN, encode = TRUE)
	else
		message = stripped_input(mob, "", "msay \"text\"")
	if(!message)
		return

	message = emoji_parse(message)
	log_mentor("MSAY: [key_name(src)] : [message]")

	if(check_rights_for(src, R_ADMIN,0))
		message = "<span class='mentorsay_admin filter_MSAY'><span class='prefix'>MENTOR:</span> <EM>[key_name(src, 0, 0)]</EM>: <span class='message'>[message]</span></span>"
	else
		message = "<span class='mentorsay filter_MSAY'><span class='prefix'>MENTOR:</span> <EM>[key_name(src, 0, 0)]</EM>: <span class='message'>[message]</span></span>"
	to_chat(GLOB.admins | GLOB.mentors, message, confidential = TRUE)
