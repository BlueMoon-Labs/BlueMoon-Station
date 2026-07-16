/client/proc/cmd_loud_admin_say(msg)
	set category = "Admin"
	set name = "Loud Asay"
	set desc = "Send a message to other admins (with sound and window flash)."
	if(!check_rights(0))
		return

	var/message = msg
	if(!message)
		if(prefs.tgui_input_verbs)
			message = tgui_input_text(src, "", "Loud Asay", "", MAX_MESSAGE_LEN, encode = TRUE)
		else
			message = stripped_input(mob, "", "Loud Asay")
	if(!message)
		return

	GLOB.bot_asay_sending_que += list(list("author" = key, "message" = message, "rank" = holder.rank.name))

	message = emoji_parse(message)
	mob?.log_talk(message, LOG_ASAY)

	message = keywords_lookup(message)
	message = "<span class='adminsay'><span class='prefix'>LOUD ADMIN:</span> <EM>[key_name(src, 1)]</EM> [ADMIN_FLW(mob)]: <span class='message linkify'><font color='#ff4500'>[message]</font></span></span>"
	to_chat(GLOB.admins, message, confidential = TRUE)

	var/sound/alert = sound('modular_bluemoon/code/modules/admin/sound/duckhonk.ogg')
	for(var/client/admin_client as anything in GLOB.admins)
		if(!admin_client)
			continue
		var/ah_vol = admin_client.prefs?.get_sound_volume("adminhelp") || 100
		SEND_SOUND(admin_client, sound(alert, volume = ah_vol))
		window_flash(admin_client, ignorepref = TRUE)

	SSblackbox.record_feedback("tally", "admin_verb", 1, "Loud Asay")
