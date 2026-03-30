/client/proc/cmd_admin_say(msg)
	set category = "Special Verbs"
	set name = "Asay" //Gave this shit a shorter name so you only have to time out "asay" rather than "admin say" to use it --NeoFite
	set hidden = 1
	if(!check_rights(0))
		return
		
	var/message = msg
	if(!message)
		if(prefs.tgui_input_verbs)
			message = tgui_input_text(src, "", "asay \"text\"", "", MAX_MESSAGE_LEN, encode = TRUE)
		else
			message = stripped_input(mob, "", "asay \"text\"")
	if(!message)
		return

	var/list/pinged_admin_clients = check_admin_pings(message)
	if(length(pinged_admin_clients) && pinged_admin_clients[ADMINSAY_PING_UNDERLINE_NAME_INDEX])
		message = pinged_admin_clients[ADMINSAY_PING_UNDERLINE_NAME_INDEX]
		pinged_admin_clients -= ADMINSAY_PING_UNDERLINE_NAME_INDEX

	for(var/iter_ckey in pinged_admin_clients)
		var/client/iter_admin_client = pinged_admin_clients[iter_ckey]
		if(!iter_admin_client?.holder)
			continue
		window_flash(iter_admin_client)
		SEND_SOUND(iter_admin_client.mob, sound('sound/misc/bloop.ogg'))

	GLOB.bot_asay_sending_que += list(list("author" = key, "message" = message, "rank" = holder.rank.name))

	message = emoji_parse(message)
	mob.log_talk(message, LOG_ASAY)

	message = keywords_lookup(message)
	message = "<span class='adminsay'><span class='prefix'>ADMIN:</span> <EM>[key_name(usr, 1)]</EM> [ADMIN_FLW(mob)]: <span class='message linkify'><font color='[prefs.ooccolor && (prefs.custom_colors & CUSTOM_OOC) ? prefs.ooccolor : "#ff4500"]'>[message]</font></span></span>"
	to_chat(GLOB.admins, message, confidential = TRUE)

	SSblackbox.record_feedback("tally", "admin_verb", 1, "Asay") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!
