/datum/mentor_ticket_panel
	var/datum/mentor_ticket/selected_ticket
	var/selected_state = MENTOR_TICKET_ACTIVE

/datum/mentor_ticket_panel/Destroy(force, ...)
	selected_ticket = null
	SStgui.close_uis(src)
	return ..()

/datum/mentor_ticket_panel/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "MentorTicketPanel")
		ui.set_autoupdate(TRUE)
		ui.open()

/datum/mentor_ticket_panel/ui_state(mob/user)
	if(user?.client?.is_mentor())
		return GLOB.always_state
	return GLOB.admin_state

/datum/mentor_ticket_panel/ui_data(mob/user)
	. = list()
	.["ckey"] = user?.ckey

	var/list/tickets_data = list()

	if(GLOB.mentor_tickets)
		for(var/datum/mentor_ticket/MT in GLOB.mentor_tickets.active_tickets)
			tickets_data += list(serialize_ticket(MT))
		for(var/datum/mentor_ticket/MT in GLOB.mentor_tickets.closed_tickets)
			tickets_data += list(serialize_ticket(MT))
		for(var/datum/mentor_ticket/MT in GLOB.mentor_tickets.resolved_tickets)
			tickets_data += list(serialize_ticket(MT))

	.["tickets"] = tickets_data

	if(selected_ticket)
		.["selected_ticket_ref"] = REF(selected_ticket)
	else
		.["selected_ticket_ref"] = null

	.["active_count"] = length(GLOB.mentor_tickets?.active_tickets)
	.["closed_count"] = length(GLOB.mentor_tickets?.closed_tickets)
	.["resolved_count"] = length(GLOB.mentor_tickets?.resolved_tickets)
	.["selected_state"] = selected_state
	.["time"] = world.time

/datum/mentor_ticket_panel/proc/serialize_ticket(datum/mentor_ticket/MT)
	. = list()
	.["ref"] = REF(MT)
	.["id"] = MT.id
	.["name"] = MT.name
	.["state"] = MT.state
	.["opened_at"] = MT.opened_at
	.["closed_at"] = MT.closed_at
	.["opened_at_text"] = GAMETIMESTAMP("hh:mm:ss", MT.opened_at)
	.["opened_ago_text"] = DisplayTimeText(world.time - MT.opened_at)
	.["closed_at_text"] = MT.closed_at ? GAMETIMESTAMP("hh:mm:ss", MT.closed_at) : null
	.["closed_ago_text"] = MT.closed_at ? DisplayTimeText(world.time - MT.closed_at) : null
	.["close_reason"] = MT.close_reason
	.["initiator_ckey"] = MT.initiator_ckey
	.["initiator_key_name"] = MT.initiator_key_name
	.["has_initiator"] = !isnull(MT.initiator)
	.["handler"] = MT.handler
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
	.["initiator_typing"] = (MT.initiator_typing_time != null && world.time - MT.initiator_typing_time < 5 SECONDS)
	if(!.["initiator_typing"] && MT.initiator_ckey)
		var/client/C = GLOB.directory[MT.initiator_ckey]
		if(C?.reply_modal_open)
			.["initiator_typing"] = TRUE
	.["interactions"] = MT._interactions.Copy()

/datum/mentor_ticket_panel/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	if(!usr.client?.is_mentor())
		return

	switch(action)
		if("select_ticket")
			var/ref = params["ref"]
			selected_ticket = locate(ref) in (GLOB.mentor_tickets?.active_tickets + GLOB.mentor_tickets?.closed_tickets + GLOB.mentor_tickets?.resolved_tickets)
			if(!selected_ticket)
				return TRUE
			. = TRUE

		if("refresh")
			. = TRUE

		if("send_reply")
			if(!selected_ticket || selected_ticket.state != MENTOR_TICKET_ACTIVE)
				return TRUE
			var/message = params["message"]
			if(!istext(message))
				return TRUE
			message = trim(message)
			if(!message)
				return TRUE
			message = copytext_char(message, 1, MAX_MESSAGE_LEN)
			if(!selected_ticket.handler)
				selected_ticket.handle_issue()
			selected_ticket.typing_mentors -= usr.ckey
			if(selected_ticket.initiator)
				selected_ticket.AddInteraction("<font color='#a855f7'>[key_name_admin(usr)]: [html_encode(message)]</font>")
				usr.client.cmd_mentor_pm(selected_ticket.initiator, message)
			. = TRUE

		if("reopen")
			if(!selected_ticket || selected_ticket.state == MENTOR_TICKET_ACTIVE)
				return TRUE
			selected_ticket.Reopen()
			. = TRUE

		if("close")
			if(!selected_ticket || selected_ticket.state != MENTOR_TICKET_ACTIVE)
				return TRUE
			selected_ticket.Close()
			. = TRUE

		if("resolve")
			if(!selected_ticket || selected_ticket.state != MENTOR_TICKET_ACTIVE)
				return TRUE
			selected_ticket.Resolve()
			. = TRUE

		if("handle_issue")
			if(!selected_ticket || selected_ticket.state != MENTOR_TICKET_ACTIVE)
				return TRUE
			selected_ticket.handle_issue()
			. = TRUE

		if("typing_start")
			if(!selected_ticket || selected_ticket.state != MENTOR_TICKET_ACTIVE)
				return TRUE
			selected_ticket.typing_mentors[usr.ckey] = world.time
			. = TRUE

		if("typing_stop")
			if(!selected_ticket)
				return TRUE
			selected_ticket.typing_mentors -= usr.ckey
			. = TRUE

	SStgui.update_uis(src)
