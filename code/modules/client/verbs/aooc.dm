GLOBAL_VAR_INIT(AOOC_COLOR, null)//If this is null, use the CSS for OOC. Otherwise, use a custom colour.
GLOBAL_VAR_INIT(normal_aooc_colour, "#ce254f")

/client/verb/aooc()
	set name = "AOOC"
	set desc = "An OOC channel exclusive to antagonists."
	set category = "OOC"

	if(GLOB.say_disabled)	//This is here to try to identify lag problems
		to_chat(usr, "<span class='danger'>Speech is currently admin-disabled.</span>")
		return

	if(!mob)
		return

	if(!(prefs.chat_toggles & CHAT_OOC))
		to_chat(src, "<span class='danger'> You have OOC muted.</span>")
		return
	if(jobban_isbanned(mob, "OOC"))
		to_chat(src, "<span class='danger'>You have been banned from OOC.</span>")
		return

	var/message = ""
	if(prefs.tgui_input_verbs)
		message = tgui_input_text(src, "", "AOOC", "", MAX_MESSAGE_LEN, encode = TRUE)
	else
		message = stripped_input(mob, "", "AOOC")

	if(QDELETED(src) || !length(message))
		return

	if(!holder)
		if(!GLOB.aooc_allowed)
			to_chat(src, "<span class='danger'>AOOC is currently muted.</span>")
			return
		if(prefs.muted & MUTE_OOC)
			to_chat(src, "<span class='danger'>You cannot use AOOC (muted).</span>")
			return
		if(!is_special_character(mob))
			to_chat(usr, "<span class='danger'>You aren't an antagonist!</span>")
		if(handle_spam_prevention(message,MUTE_OOC))
			return
		if(findtext(message, "byond://"))
			to_chat(src, "<B>Advertising other servers is not allowed.</B>")
			log_admin("[key_name(src)] has attempted to advertise in LOOC: [message]")
			return
		if(mob.stat)
			to_chat(usr, "<span class='danger'>You cannot use AOOC while unconscious or dead.</span>")
			return
		if(isdead(mob))
			to_chat(src, "<span class='danger'>You cannot use AOOC while ghosting.</span>")
			return
		if(HAS_TRAIT(mob, TRAIT_AOOC_MUTE))
			to_chat(src, "<span class='danger'>You cannot use AOOC right now.</span>")
			return
		
	var/raw_msg = message
	message = emoji_parse(message)

	if(!holder)
		if(handle_spam_prevention(message,MUTE_OOC))
			return
		if(findtext(message, "byond://"))
			to_chat(src, "<B>Advertising other servers is not allowed.</B>")
			log_admin("[key_name(src)] has attempted to advertise in AOOC: [message]")
			message_admins("[key_name_admin(src)] has attempted to advertise in AOOC: [message]")
			return

	mob.log_talk(raw_msg,LOG_OOC, tag="(AOOC)")

	var/keyname = key
	if(prefs.unlock_content)
		if(prefs.toggles & MEMBER_PUBLIC)
			keyname = "<font color='[prefs.aooccolor && (prefs.custom_colors & CUSTOM_AOOC) ? prefs.aooccolor : GLOB.normal_aooc_colour]'>[icon2html('icons/member_content.dmi', world, "blag")][keyname]</font>"
	//The linkify span classes and linkify=TRUE below make ooc text get clickable chat href links if you pass in something resembling a url

	var/antaglisting = list()

	for(var/datum/mind/M in get_antag_minds(/datum/antagonist))
		if(!M.current || !M.current.client || isnewplayer(M.current))
			continue
		antaglisting |= M.current.client

	for(var/mob/M in GLOB.player_list)
		if(M.client && (M.stat == DEAD || M.client.holder) && !istype(M, /mob/dead/new_player))
			antaglisting |= M.client

	for(var/client/C in antaglisting)
		if(!C || !istype(C))
			continue
		if(holder)
			if(!holder.fakekey || C.holder)
				if(check_rights_for(src, R_ADMIN))
					to_chat(C, "<span class='adminantagooc'>[CONFIG_GET(flag/allow_admin_ooccolor) && prefs.ooccolor && (prefs.custom_colors & CUSTOM_OOC) ? "<font color=[prefs.ooccolor]>" :"" ]<span class='prefix'>Antag OOC:</span> <EM>[keyname][holder.fakekey ? "/([holder.fakekey])" : ""]:</EM> <span class='message linkify'>[message]</span></span></font>")
				else
					to_chat(C, "<span class='adminobserverooc'><span class='prefix'>Antag OOC:</span> <EM>[keyname][holder.fakekey ? "/([holder.fakekey])" : ""]:</EM> <span class='message linkify'>[message]</span></span>")
			else
				if(GLOB.AOOC_COLOR)
					to_chat(C, "<font color='[GLOB.AOOC_COLOR]'><b><span class='prefix'>Antag OOC:</span> <EM>[holder.fakekey ? holder.fakekey : key]:</EM> <span class='message linkify'>[message]</span></b></font>")
				else
					to_chat(C, "<span class='antagooc'><span class='prefix'>Antag OOC:</span> <EM>[holder.fakekey ? holder.fakekey : key]:</EM> <span class='message linkify'>[message]</span></span>")
		else if(!(key in C.prefs.ignoring))
			if(GLOB.AOOC_COLOR)
				to_chat(C, "<font color='[GLOB.AOOC_COLOR]'><b><span class='prefix'>Antag OOC:</span> <EM>[keyname]:</EM> <span class='message linkify'>[message]</span></b></font>")
			else
				to_chat(C, "<span class='antagooc'><span class='prefix'>Antag OOC:</span> <EM>[keyname]:</EM> <span class='message linkify'>[message]</span></span>")

/client/proc/set_aooc(newColor as color)
	set name = "Set Antag OOC Color"
	set desc = "Modifies antag OOC Color"
	set category = "Fun"
	GLOB.AOOC_COLOR = sanitize_ooccolor(newColor)

/client/proc/reset_aooc()
	set name = "Reset Antag OOC Color"
	set desc = "Returns antag OOC Color to default"
	set category = "Fun"
	GLOB.AOOC_COLOR = null

/proc/toggle_aooc(toggle = null)
	if(toggle != null) //if we're specifically en/disabling ooc
		if(toggle != GLOB.aooc_allowed)
			GLOB.aooc_allowed = toggle
		else
			return
	else //otherwise just toggle it
		GLOB.aooc_allowed = !GLOB.aooc_allowed

	var/antaglisting = list()	//Only those who have access to AOOC need to know if it's enabled or not.

	for(var/datum/mind/M in get_antag_minds(/datum/antagonist))
		if(!M.current || !M.current.client || isnewplayer(M.current))
			continue
		antaglisting |= M.current.client

	for(var/mob/M in GLOB.player_list)
		if(M.client && (M.stat == DEAD || M.client.holder || is_special_character(M)))
			antaglisting |= M.client

	for(var/client/C in antaglisting)
		if(!C || !istype(C))
			continue
		to_chat(C, "<B>The Antagonist OOC channel has been [GLOB.aooc_allowed ? "enabled. If you're an antagonist, you can access it through the \"AOOC\" verb." : "disabled"].</B>")
