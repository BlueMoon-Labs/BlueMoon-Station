/client/proc/cmd_loud_admin_say(msg)
	set category = "Special Verbs"
	set name = "loudAsay"
	set desc = "Send a message to other admins (loudly)."
	set hidden = 1
	if(!check_rights(0))
		return

	var/message = msg
	if(!message)
		if(prefs.tgui_input_verbs)
			message = tgui_input_text(src, "", "loudAsay \"text\"", "", MAX_MESSAGE_LEN, encode = TRUE)
		else
			message = stripped_input(mob, "", "loudAsay \"text\"")
	if(!message)
		return

	GLOB.bot_asay_sending_que += list(list("author" = key, "message" = message, "rank" = holder.rank.name))

	message = emoji_parse(message)
	mob.log_talk(message, LOG_ASAY)

	message = keywords_lookup(message)
	message = span_command_headset("<span class='adminsay'><span class='prefix'>ADMIN:</span> <EM>[key_name(usr, 1)]</EM> [ADMIN_FLW(mob)]: <span class='message linkify'><font color='#ff4500'>[message]</font></span></span>")
	to_chat(GLOB.admins, message, confidential = TRUE)

	for(var/client/admin_client in GLOB.admins)
		if(admin_client?.prefs?.toggles & SOUND_ADMINHELP)
			SEND_SOUND(admin_client, sound('modular_bluemoon/code/modules/admin/sound/duckhonk.ogg'))
		window_flash(admin_client, ignorepref = TRUE)

	SSblackbox.record_feedback("tally", "admin_verb", 1, "loudAsay")
