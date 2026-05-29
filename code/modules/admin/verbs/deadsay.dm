/client/proc/dsay(msg)
	set category = "Admin.Game"
	set name = "Dsay"
	set hidden = 1
	if(!holder)
		to_chat(src, "Only administrators may use this command.", confidential = TRUE)
		return
	if(!mob)
		return
	if(prefs.muted & MUTE_DEADCHAT)
		to_chat(src, "<span class='danger'>You cannot send DSAY messages (muted).</span>", confidential = TRUE)
		return

	var/message = msg
	if(!message)
		if(prefs.tgui_input_verbs)
			message = tgui_input_text(src, "", "Dsay", "", MAX_MESSAGE_LEN, encode = TRUE)
		else
			message = stripped_input(mob, "", "Dsay")

	if (handle_spam_prevention(message,MUTE_DEADCHAT))
		return

	mob.log_talk(message, LOG_DSAY)

	if (!message)
		return
	var/static/nicknames = world.file2list("[global.config.directory]/admin_nicknames.txt")

	var/rendered = "<span class='game deadsay'><span class='prefix'>DEAD:</span> <span class='name'>[uppertext(holder.rank)]([src.holder.fakekey ? pick(nicknames) : src.key])</span> says, <span class='message'>\"[emoji_parse(message)]\"</span></span>"

	for (var/mob/M in GLOB.player_list)
		if(isnewplayer(M))
			continue
		if (M.stat == DEAD || (M.client.holder && (M.client.prefs.chat_toggles & CHAT_DEAD))) //admins can toggle deadchat on and off. This is a proc in admin.dm and is only give to Administrators and above
			to_chat(M, rendered, confidential = TRUE)

	SSblackbox.record_feedback("tally", "admin_verb", 1, "Dsay") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!
