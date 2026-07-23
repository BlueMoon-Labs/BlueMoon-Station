/datum/player_ticket_panel

/datum/player_ticket_panel/Destroy(force, ...)
	SStgui.close_uis(src)
	return ..()

/datum/player_ticket_panel/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PlayerTicketPanel")
		ui.set_autoupdate(TRUE)
		ui.open()

/datum/player_ticket_panel/ui_state(mob/user)
	return GLOB.always_state

/datum/player_ticket_panel/ui_data(mob/user)
	. = list()

	var/datum/admin_help/AH = GLOB.ahelp_tickets.CKey2ActiveTicket(user.ckey)
	.["has_ticket"] = !isnull(AH)
	if(AH)
		.["ticket"] = serialize_ticket(AH, user)

	var/datum/mentor_ticket/MT = GLOB.mentor_tickets?.CKey2Ticket(user.ckey)
	.["has_mentor_ticket"] = !isnull(MT)
	if(MT)
		.["mentor_ticket"] = serialize_mentor_ticket(MT, user)

/datum/player_ticket_panel/proc/serialize_ticket(datum/admin_help/AH, mob/user)
	. = list()
	.["ref"] = REF(AH)
	.["id"] = AH.id
	.["name"] = AH.name
	.["state"] = AH.state
	.["opened_at"] = AH.opened_at
	.["opened_at_text"] = GAMETIMESTAMP("hh:mm:ss", AH.opened_at)
	.["opened_ago_text"] = DisplayTimeText(world.time - AH.opened_at)
	.["close_reason"] = AH.close_reason
	.["initiator_ckey"] = AH.initiator_ckey
	.["handler"] = AH.handler
	.["initiator_typing"] = (AH.initiator_typing_time != null && world.time - AH.initiator_typing_time < 5 SECONDS)
	if(!.["initiator_typing"] && AH.initiator_ckey)
		var/client/C = GLOB.directory[AH.initiator_ckey]
		if(C?.reply_modal_open)
			.["initiator_typing"] = TRUE
	var/list/typing = list()
	for(var/typing_ckey in AH.typing_admins)
		if(world.time - AH.typing_admins[typing_ckey] < 5 SECONDS)
			typing += typing_ckey
		else
			var/client/C = GLOB.directory[typing_ckey]
			if(C?.reply_modal_open)
				typing += typing_ckey
			else
				AH.typing_admins -= typing_ckey
	.["typing_admins"] = typing
	.["interactions"] = AH._interactions.Copy()

/datum/player_ticket_panel/proc/serialize_mentor_ticket(datum/mentor_ticket/MT, mob/user)
	. = list()
	.["ref"] = REF(MT)
	.["id"] = MT.id
	.["name"] = MT.name
	.["state"] = MT.state
	.["opened_at_text"] = GAMETIMESTAMP("hh:mm:ss", MT.opened_at)
	.["opened_ago_text"] = DisplayTimeText(world.time - MT.opened_at)
	.["close_reason"] = MT.close_reason
	.["initiator_ckey"] = MT.initiator_ckey
	.["handler"] = MT.handler
	.["initiator_typing"] = (MT.initiator_typing_time != null && world.time - MT.initiator_typing_time < 5 SECONDS)
	if(!.["initiator_typing"] && MT.initiator_ckey)
		var/client/C = GLOB.directory[MT.initiator_ckey]
		if(C?.reply_modal_open)
			.["initiator_typing"] = TRUE
	var/list/typing = list()
	for(var/typing_ckey in MT.typing_mentors)
		if(world.time - MT.typing_mentors[typing_ckey] < 5 SECONDS)
			typing += typing_ckey
		else
			var/client/C = GLOB.directory[typing_ckey]
			if(C?.reply_modal_open)
				typing += typing_ckey
			else
				MT.typing_mentors -= typing_ckey
	.["typing_admins"] = typing
	.["interactions"] = MT._interactions.Copy()

/datum/player_ticket_panel/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("create_ticket")
			if(GLOB.say_disabled)
				to_chat(usr, "<span class='danger'>Речь отключена администратором.</span>")
				return TRUE

			if(usr.client.prefs.muted & MUTE_ADMINHELP)
				to_chat(usr, "<span class='danger'>Ошибка: Admin-PM: Вы не можете отправлять админхелпы (Мут).</span>")
				return TRUE

			var/message = params["message"]
			var/type = params["type"]
			if(!istext(message) || !istext(type))
				return TRUE
			message = trim(message)
			if(!message)
				return TRUE
			if(type == "mentor")
				if(jobban_isbanned(usr.client.mob, "ahelp"))
					to_chat(usr, "<span class='danger'>Вам запрещено использовать ахелп.</span>")
					return TRUE
				if(GLOB.mentor_tickets?.CKey2Ticket(usr.client.ckey))
					to_chat(usr, "<span class='warning'>У вас уже есть открытый ментор-тикет.</span>")
					return TRUE
				new /datum/mentor_ticket(message, usr.client, FALSE)
			else
				if(!usr.client.holder && jobban_isbanned(usr.client.mob, "ahelp"))
					to_chat(usr, "<span class='danger'>Вам запрещено использовать ахелп.</span>")
					return TRUE
				if(GLOB.ahelp_tickets.CKey2ActiveTicket(usr.client.ckey))
					to_chat(usr, "<span class='warning'>У вас уже есть открытый тикет.</span>")
					return TRUE
				new /datum/admin_help(message, usr.client, FALSE)
			. = TRUE

		if("send_message")
			var/message = params["message"]
			var/ref = params["ref"]
			var/type = params["type"]
			if(!istext(message) || !istext(ref))
				return TRUE
			message = trim(message)
			if(!message)
				return TRUE
			if(type == "mentor")
				var/datum/mentor_ticket/MT = locate(ref)
				if(MT && MT.state == MENTOR_TICKET_ACTIVE && MT.initiator_ckey == usr.client.ckey)
					MT.MessageNoRecipient(message)
			else
				var/datum/admin_help/AH = locate(ref)
				if(AH && AH.state == AHELP_ACTIVE && AH.initiator_ckey == usr.client.ckey)
					AH.MessageNoRecipient(message)
			. = TRUE

		if("typing_start")
			var/ref = params["ref"]
			var/type = params["type"]
			if(type == "mentor")
				var/datum/mentor_ticket/MT = locate(ref)
				if(MT && MT.initiator_ckey == usr.client.ckey)
					MT.initiator_typing_time = world.time
			else
				var/datum/admin_help/AH = locate(ref)
				if(AH && AH.initiator_ckey == usr.client.ckey)
					AH.initiator_typing_time = world.time
			. = TRUE

		if("typing_stop")
			var/ref = params["ref"]
			var/type = params["type"]
			if(type == "mentor")
				var/datum/mentor_ticket/MT = locate(ref)
				if(MT && MT.initiator_ckey == usr.client.ckey)
					MT.initiator_typing_time = null
			else
				var/datum/admin_help/AH = locate(ref)
				if(AH && AH.initiator_ckey == usr.client.ckey)
					AH.initiator_typing_time = null
			. = TRUE

		if("refresh")
			. = TRUE

	SStgui.update_uis(src)
