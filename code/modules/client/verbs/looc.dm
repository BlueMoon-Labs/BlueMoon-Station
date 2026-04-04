GLOBAL_VAR_INIT(LOOC_COLOR, null)//If this is null, use the CSS for OOC. Otherwise, use a custom colour.
GLOBAL_VAR_INIT(normal_looc_colour, "#6699CC")

/client/verb/looc()
	set name = "LOOC"
	set desc = "Local OOC, seen only by those in view."
	set category = "OOC"

	var/vibe_check = SSdiscord?.check_login(usr)
	if(isnull(vibe_check))
		to_chat(usr, span_notice("The server is still starting up. Please wait... "))
		return
	else if(vibe_check == FALSE) //Dirty but I guess we gotta tell when the subsystem hasn't started
		to_chat(usr, span_warning("You must link your discord account to your ckey in order to join the game. Join our <a style=\"color: #ff00ff;\" href=\"[CONFIG_GET(string/discordurl)]\">discord</a> and use the <span style=\"color: #ff00ff;\">[CONFIG_GET(string/discordbotcommandprefix)][CONFIG_GET(string/verification_command)]</span> command [CONFIG_GET(string/verification_channel) ? "as indicated in #[CONFIG_GET(string/verification_channel)] " : ""]. It won't take you more than two minutes :)<br>Ahelp or ask staff in the discord if this is an error."))
		return

	if(GLOB.say_disabled)	//This is here to try to identify lag problems
		to_chat(usr, "<span class='danger'> Speech is currently admin-disabled.</span>")
		return

	if(QDELETED(src) || !mob)
		return

	var/message = ""
	if(prefs.tgui_input_verbs)
		message = tgui_input_text(src, "", "LOOC", "", MAX_MESSAGE_LEN, encode = TRUE)
	else
		message = stripped_input(mob, "", "LOOC")

	if(QDELETED(src) || !length(message))
		return

	if(!(prefs.chat_toggles & CHAT_OOC))
		to_chat(src, "<span class='danger'> You have OOC muted.</span>")
		return
	if(jobban_isbanned(mob, "OOC"))
		to_chat(src, "<span class='danger'>You have been banned from OOC.</span>")
		return

	if(!holder)
		if(!GLOB.looc_allowed)
			to_chat(src, "<span class='danger'> LOOC is globally muted</span>")
			return
		if(prefs.muted & MUTE_OOC)
			to_chat(src, "<span class='danger'> You cannot use OOC (muted).</span>")
			return
		if(handle_spam_prevention(message,MUTE_OOC))
			return
		if(findtext(message, "byond://"))
			to_chat(src, "<B>Advertising other servers is not allowed.</B>")
			log_admin("[key_name(src)] has attempted to advertise in LOOC: [message]")
			return
		//if(mob.stat) # Suggestion 3611, add LOOC for unconscious and dead | SPLURT 10.12.2022
		//	to_chat(src, "<span class='danger'>You cannot use LOOC while unconscious or dead.</span>")
		//	return
		if(isobserver(mob) && !(src in GLOB.admins))
			to_chat(src, "<span class='danger'>You cannot use LOOC while ghosting.</span>")
			return
		if(HAS_TRAIT(mob, TRAIT_LOOC_MUTE))
			to_chat(src, "<span class='danger'>You cannot use LOOC right now.</span>")
			return


	message = emoji_parse(message)

	mob.log_talk(message,LOG_OOC, tag="LOOC")

	var/list/heard = get_hearers_in_view(7, get_top_level_mob(src.mob))
	for(var/mob/M in heard)
		if(!M.client)
			continue
		var/client/C = M.client

		if(!(C.prefs.chat_toggles & CHAT_OOC))
			continue

		if (isobserver(M) && !C.holder)
			continue //ghosts dont hear looc, apparantly

		if(M.client.prefs.chat_on_map)
			M.create_chat_message(mob, raw_message = "(LOOC: [message])", spans = list("emote", "whisper")) // emote для игнорирования фильтра по языкам, whisper для мелкотекста рунчата

		if(C in GLOB.admins)
			continue //admins are handled afterwards

		if(GLOB.LOOC_COLOR)
			to_chat(C, "<font color='[GLOB.LOOC_COLOR]'><b><span class='prefix'>LOOC:</span> <EM>[src.mob.name]:</EM> <span class='message'>[message]</span></b></font>")
		else
			to_chat(C, "<span class='looc'><span class='prefix'>LOOC:</span> <EM>[src.mob.name]:</EM> <span class='message'>[message]</span></span>")

	for(var/client/C in GLOB.admins)
		if(C.prefs.chat_toggles & CHAT_OOC)

			var/local = (C.mob in heard)
			var/prefix = "[local ? "" : "(R)"]LOOC"
			var/admin_looc = ""
			if(GLOB.LOOC_COLOR)
				admin_looc = "<font color='[GLOB.LOOC_COLOR]'><b>[ADMIN_FLW(usr)] <span class='prefix'>[prefix]:</span> <EM>[src.key]/[src.mob.name]:</EM> <span class='message'>[message]</span></b></font>"
				if(!local)
					admin_looc = span_adminlooc(admin_looc)
			else
				admin_looc = "[ADMIN_FLW(usr)] <span class='prefix'>[prefix]:</span> <EM>[src.key]/[src.mob.name]:</EM> <span class='message'>[message]</span>"
				admin_looc = local ? span_looc(admin_looc) : span_adminlooc(admin_looc)
			to_chat(C, admin_looc)
