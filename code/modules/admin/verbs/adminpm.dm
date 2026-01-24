#define EXTERNALREPLYCOUNT 2

//allows right clicking mobs to send an admin PM to their client, forwards the selected mob's client to cmd_admin_pm
/client/proc/cmd_admin_pm_context(mob/M in GLOB.mob_list)
	set category = null
	set name = "Admin PM Mob"
	if(!holder)
		to_chat(src, "<span class='danger'>Error: Admin-PM-Context: Only administrators may use this command.</span>", confidential = TRUE)
		return
	if( !ismob(M) || !M.client )
		return
	cmd_admin_pm(M.client,null)
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Admin PM Mob") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

//shows a list of clients we could send PMs to, then forwards our choice to cmd_admin_pm
/client/proc/cmd_admin_pm_panel()
	set category = "Admin"
	set name = "Admin PM"
	if(!holder)
		to_chat(src, "<span class='danger'>Error: Admin-PM-Panel: Only administrators may use this command.</span>", confidential = TRUE)
		return
	var/list/client/targets[0]
	for(var/client/T)
		if(T.mob)
			if(isnewplayer(T.mob))
				targets["(New Player) - [T]"] = T
			else if(isobserver(T.mob))
				targets["[T.mob.name](Ghost) - [T]"] = T
			else
				targets["[T.mob.real_name](as [T.mob.name]) - [T]"] = T
		else
			targets["(No Mob) - [T]"] = T
	var/target = input(src,"Кто получит нашу весть?","Admin PM",null) as null|anything in sort_list(targets)
	cmd_admin_pm(targets[target],null)
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Admin PM") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/client/proc/cmd_ahelp_reply(whom)
	if(prefs.muted & MUTE_ADMINHELP)
		to_chat(src, "<span class='danger'>Error: Admin-PM: You are unable to use admin PM-s (muted).</span>", confidential = TRUE)
		return
	var/client/C
	if(istext(whom))
		if(whom[1] == "@")
			whom = findStealthKey(whom)
		C = GLOB.directory[whom]
	else if(istype(whom, /client))
		C = whom
	if(!C)
		if(holder)
			to_chat(src, "<span class='danger'>Ошибка: Admin-PM: Клиент не найден.</span>", confidential = TRUE)
		return

	var/datum/admin_help/AH = C.current_ticket

	if(AH)
		message_admins("[key_name_admin(src)] начал отвечать на админхелп [key_name_admin(C, 0, 0)].")
	var/msg = input(src,"Сообщение:", "Приватное сообщение [C.holder?.fakekey ? "администрации" : key_name(C, 0, 0)].") as message|null
	if (!msg)
		message_admins("[key_name_admin(src)] прекратил отвечать на admin help [key_name_admin(C, 0, 0)].")
		return
	if(!C) //We lost the client during input, disconnected or relogged.
		if(GLOB.directory[AH.initiator_ckey]) // Client has reconnected, lets try to recover
			whom = GLOB.directory[AH.initiator_ckey]
		else
			to_chat(src, "<span class='danger'>Ошибка: Admin-PM: Клиент не найден.</span>", confidential = TRUE)
			to_chat(src, "<span class='danger'><b>Сообщение не отправлено:</b></span><br>[msg]", confidential = TRUE)
			AH.AddInteraction("<b>Клиент не найден, сообщение не отправлено:</b><br>[msg]")
			return
	cmd_admin_pm(whom, msg)

//takes input from cmd_admin_pm_context, cmd_admin_pm_panel or /client/Topic and sends them a PM.
//Fetching a message if needed. src is the sender and C is the target client
/client/proc/cmd_admin_pm(whom, msg)
	if(prefs.muted & MUTE_ADMINHELP)
		to_chat(src, "<span class='danger'>Error: Admin-PM: You are unable to use admin PM-s (muted).</span>", confidential = TRUE)
		return

	if(!holder && !current_ticket)	//no ticket? https://www.youtube.com/watch?v=iHSPf6x1Fdo
		to_chat(src, "<span class='danger'>Вы больше не можете отвечать на этот тикет, при надобности, откройте новый при помощи опции Adminhelp.</span>", confidential = TRUE)
		to_chat(src, "<span class='notice'>Сообщение: [msg]</span>", confidential = TRUE)
		return

	var/client/recipient
	var/recipient_ckey // Stored in case client is deleted between this and after the message is input
	var/datum/admin_help/recipient_ticket // Stored in case client is deleted between this and after the message is input
	var/external = 0
	if(istext(whom))
		if(whom[1] == "@")
			whom = findStealthKey(whom)
		if(whom == "IRCKEY")
			external = 1
		else
			recipient = GLOB.directory[whom]
	else if(istype(whom, /client))
		recipient = whom

	if(!recipient)
		to_chat(src, "<span class='danger'>Ошибка: Admin-PM: Клиент не найден.</span>", confidential = TRUE)
		return

	recipient_ckey = recipient.ckey
	recipient_ticket = recipient.current_ticket

	if(external)
		if(!ircreplyamount)	//to prevent people from spamming irc/discord
			return
		if(!msg)
			msg = input(src,"Сообщение:", "Приватное сообщение для администрации") as message|null

		if(!msg)
			return
		if(holder)
			to_chat(src, "<span class='danger'>Ошбика: используй админсский IRC/Discord канал, ботан.</span>", confidential = TRUE)
			return

	else
		//get message text, limit it's length.and clean/escape html
		if(!msg)
			msg = input(src,"Сообщение:", "Приватное сообщение для [recipient.holder?.fakekey ? "администрации" : key_name(recipient, 0, 0)].") as message|null
			msg = trim(msg)
			if(!msg)
				return

		if(!recipient)
			if(GLOB.directory[recipient_ckey]) // Client has reconnected, lets try to recover
				recipient = GLOB.directory[recipient_ckey]
			else
				if(holder)
					to_chat(src, "<span class='danger'>Ошибка: Admin-PM: Клиент не найден.</span>", confidential = TRUE)
					to_chat(src, "<span class='danger'><b>Message not sent:</b></span><br>[sanitize(msg)]", confidential = TRUE)
					if(recipient_ticket)
						recipient_ticket.AddInteraction("<b>Клиент не найден, сообщение не отправлено:</b><br>[msg]")
					return
				else
					//clean the message if it's not sent by a high-rank admin
					if(!check_rights(R_SERVER|R_DEBUG,0)||external)//no sending html to the poor bots
						msg = sanitize(copytext_char(msg, 1, MAX_MESSAGE_LEN))
						if(!msg)
							return
					current_ticket.MessageNoRecipient(msg)
					return


	if(prefs.muted & MUTE_ADMINHELP)
		to_chat(src, "<span class='danger'>Error: Admin-PM: You are unable to use admin PM-s (muted).</span>", confidential = TRUE)
		return

	if(src.handle_spam_prevention(msg,MUTE_ADMINHELP))
		return

	//clean the message if it's not sent by a high-rank admin
	if(!check_rights(R_SERVER|R_DEBUG,0)||external)//no sending html to the poor bots
		msg = sanitize(copytext_char(msg, 1, MAX_MESSAGE_LEN))
		if(!msg)
			return

	var/rawmsg = msg

	if(holder)
		msg = emoji_parse(msg)

	var/keywordparsedmsg = keywords_lookup(msg)

	if(external)
		to_chat(src, "<span class='notice'>PM к-<b>Админаам</b>: <span class='linkify'>[rawmsg]</span></span>", confidential = TRUE)
		var/datum/admin_help/AH = admin_ticket_log(src, "<font color='red'>PM ответ от-<b>[key_name(src, TRUE, TRUE)]</b> к <i>External</i>: [keywordparsedmsg]</font>")
		ircreplyamount--
		send2adminchat("[AH ? "#[AH.id] " : ""]Reply: [ckey]", rawmsg)

	else
		var/badmin = FALSE //Lets figure out if an admin is getting bwoinked.
		if(holder && recipient.holder && !current_ticket) //Both are admins, and this is not a reply to our own ticket.
			badmin = TRUE
		if(recipient.holder && !badmin)
			SEND_SIGNAL(current_ticket, COMSIG_ADMIN_HELP_REPLIED)
			if(holder)
				to_chat(recipient, "<span class='danger'>Админ PM от<b> [key_name(src, recipient, 1)]</b>: <span class='linkify'>[keywordparsedmsg]</span></span>", confidential = TRUE)
				to_chat(src, "<span class='notice'>Админ PM к <b>[key_name(recipient, src, 1)]</b>: <span class='linkify'>[keywordparsedmsg]</span></span>", confidential = TRUE)

				//omg this is dumb, just fill in both their tickets
				var/interaction_message = "<font color='purple'>PM от <b>[key_name(src, recipient, 1)]</b> к <b>[key_name(recipient, src, 1)]</b>: [keywordparsedmsg]</font>"
				admin_ticket_log(src, interaction_message)
				if(recipient != src)	//reeee
					admin_ticket_log(recipient, interaction_message)
				SSblackbox.LogAhelp(current_ticket.id, "Reply", msg, recipient.ckey, src.ckey)
			else		//recipient is an admin but sender is not
				var/replymsg = "PM-ответ от <b>[key_name(src, recipient, 1)]</b>: <span class='linkify'>[keywordparsedmsg]</span>"
				admin_ticket_log(src, "<font color='red'>[replymsg]</font>")
				to_chat(recipient, "<span class='danger'>[replymsg]</span>", confidential = TRUE)
				to_chat(src, "<span class='notice'>PM к <b>Админам</b>: <span class='linkify'>[msg]</span></span>", confidential = TRUE)
				SSblackbox.LogAhelp(current_ticket.id, "Reply", msg, recipient.ckey, src.ckey)

			//play the receiving admin the adminhelp sound (if they have them enabled)
			if(recipient.prefs.toggles & SOUND_ADMINHELP)
				SEND_SOUND(recipient, sound('sound/effects/adminhelp.ogg'))

		else
			if(holder)	//sender is an admin but recipient is not. Do BIG RED TEXT
				var/already_logged = FALSE //BLUEMOON EDIT, enable ticket logging
				if(!recipient.current_ticket)
					new /datum/admin_help(msg, recipient, TRUE)
					already_logged = TRUE //BLUEMOON EDIT, enable ticket logging
					SSblackbox.LogAhelp(recipient.current_ticket.id, "Ticket Opened", msg, recipient.ckey, src.ckey)

				var/recipient_message = ""
				recipient_message += "<br><center><font color='red' size='4'><b>-- Administrator private message --</b></font></center>"
				recipient_message += "<span class='adminsay'>Админ PM от <b>[key_name(src, recipient, 0)]</b>: <span class='linkify'>[msg]</span></span>"
				recipient_message += "<br><span class='adminsay'><i>Нажмите на имя администратора для ответа</i></span>"
				recipient_message += "<br><br>"
				to_chat(recipient, recipient_message, confidential = TRUE)
				to_chat(src, "<span class='notice'>Админ PM к <b>[key_name(recipient, src, 1)]</b>: <span class='linkify'>[msg]</span></span>", confidential = TRUE)

				admin_ticket_log(recipient, "<font color='purple'>PM от [key_name_admin(src)]: [keywordparsedmsg]</font>")

				if(!already_logged) //Reply to an existing ticket   //BLUEMOON EDIT, enable ticket logging
					SSblackbox.LogAhelp(recipient.current_ticket.id, "Reply", msg, recipient.ckey, src.ckey) //BLUEMOON EDIT, enable ticket logging


				//always play non-admin recipients the adminhelp sound
				SEND_SOUND(recipient, sound('sound/effects/adminhelp.ogg'))


			else		//neither are admins
				to_chat(src, "<span class='danger'>Error: Admin-PM: Non-admin to non-admin PM communication is forbidden.</span>", confidential = TRUE)
				return

	if(external)
		log_admin_private("PM: [key_name(src)]->External: [rawmsg]")
		for(var/client/X in GLOB.admins)
			to_chat(X, "<span class='notice'><B>PM: [key_name(src, X, 0)]-&gt;External:</B> [keywordparsedmsg]</span>", confidential = TRUE)
	else
		window_flash(recipient, ignorepref = TRUE)
		log_admin_private("PM: [key_name(src)]->[key_name(recipient)]: [rawmsg]")
		//we don't use message_admins here because the sender/receiver might get it too
		for(var/client/X in GLOB.admins)
			if(X.key!=key && X.key!=recipient.key)	//check client/X is an admin and isn't the sender or recipient
				to_chat(X, "<span class='notice'><B>PM: [key_name(src, X, 0)]-&gt;[key_name(recipient, X, 0)]:</B> [keywordparsedmsg]</span>" , confidential = TRUE)

/proc/IrcPm(target,msg,sender)
	return TgsPm(target,msg,sender) //compatability moment.

#define TGS_AHELP_USAGE "Usage: ticket <close|resolve|icissue|skillissue|reject|reopen \[ticket #\]|list>"
/proc/TgsPm(target,msg,sender)
	target = ckey(target)
	var/client/C = GLOB.directory[target]

	var/datum/admin_help/ticket = C ? C.current_ticket : GLOB.ahelp_tickets.CKey2ActiveTicket(target)
	var/compliant_msg = trim(lowertext(msg))
	var/tgs_tagged = "[sender](TGS/External)"
	var/list/splits = splittext(compliant_msg, " ")
	if(splits.len && splits[1] == "ticket")
		if(splits.len < 2)
			return TGS_AHELP_USAGE
		switch(splits[2])
			if("close")
				if(ticket)
					ticket.Close(tgs_tagged)
					return "Тикет #[ticket.id] успешно закрыт"
			if("resolve")
				if(ticket)
					ticket.Resolve(tgs_tagged)
					return "Тикет #[ticket.id] успешно решён"
			if("icissue")
				if(ticket)
					ticket.ICIssue(tgs_tagged)
					return "Тикет #[ticket.id] успешно обозначен как IC issue"
			if("skillissue")
				if(ticket)
					ticket.SkillIssue(tgs_tagged)
					return "Тикет #[ticket.id] успешно обозначен как Skill issue"
			if("reject")
				if(ticket)
					ticket.Reject(tgs_tagged)
					return "Тикет #[ticket.id] успешно отклонён"
			if("reopen")
				if(ticket)
					return "Ошибка: [target] уже имеет открытый тикет #[ticket.id]"
				var/fail = splits.len < 3 ? null : -1
				if(!isnull(fail))
					fail = text2num(splits[3])
				if(isnull(fail))
					return "Error: No/Invalid ticket id specified. [TGS_AHELP_USAGE]"
				var/datum/admin_help/AH = GLOB.ahelp_tickets.TicketByID(fail)
				if(!AH)
					return "Ошибка: Тикет #[fail] не найден"
				if(AH.initiator_ckey != target)
					return "Ошибка: Тикет #[fail] принадлежит [AH.initiator_ckey]"
				AH.Reopen()
				return "Тикет #[ticket.id] успешно переоткрыт"
			if("list")
				var/list/tickets = GLOB.ahelp_tickets.TicketsByCKey(target)
				if(!tickets.len)
					return "None"
				. = ""
				for(var/I in tickets)
					var/datum/admin_help/AH = I
					if(.)
						. += ", "
					if(AH == ticket)
						. += "Active: "
					. += "#[AH.id]"
				return
			else
				return TGS_AHELP_USAGE
		return "Error: Ticket could not be found"

	var/static/stealthkey
	var/adminname = CONFIG_GET(flag/show_irc_name) ? tgs_tagged : "Administrator"

	if(!C)
		return "Error: No client"

	if(!stealthkey)
		stealthkey = GenTgsStealthKey()

	msg = sanitize(copytext_char(msg, 1, MAX_MESSAGE_LEN))
	if(!msg)
		return "Error: No message"

	message_admins("External message from [sender] to [key_name_admin(C)] : [msg]")
	log_admin_private("External PM: [sender] -> [key_name(C)] : [msg]")
	msg = emoji_parse(msg)
	var/recipient_message = ""
	recipient_message += "<br><center><font color='red' size='4'><b>-- Administrator private message --</b></font></center>"
	recipient_message += "<span class='adminsay'>Админ PM от <b><a href='?priv_msg=[stealthkey]'>[adminname]</A></b>: [msg]</span>"
	recipient_message += "<br><span class='adminsay'><i>Нажмите на имя администратора для ответа</i></span>"
	recipient_message += "<br><br>"
	to_chat(C, recipient_message, confidential = TRUE)

	admin_ticket_log(C, "<font color='purple'>PM от [tgs_tagged]: [msg]</font>")

	window_flash(C, ignorepref = TRUE)
	//always play non-admin recipients the adminhelp sound
	SEND_SOUND(C, 'sound/effects/adminhelp.ogg')

	// C.externalreplyamount = EXTERNALREPLYCOUNT
	C.ircreplyamount = EXTERNALREPLYCOUNT

	return "Message Successful"

/proc/GenTgsStealthKey()
	var/num = (rand(0,1000))
	var/i = 0
	while(i == 0)
		i = 1
		for(var/P in GLOB.stealthminID)
			if(num == GLOB.stealthminID[P])
				num++
				i = 0
	var/stealth = "@[num2text(num)]"
	GLOB.stealthminID["IRCKEY"] = stealth
	return	stealth

#undef EXTERNALREPLYCOUNT
