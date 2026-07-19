/datum/admin_ticket_panel
	var/datum/admin_help/selected_ticket
	var/selected_state = AHELP_ACTIVE

/datum/admin_ticket_panel/New()
	. = ..()

/datum/admin_ticket_panel/Destroy(force, ...)
	selected_ticket = null
	SStgui.close_uis(src)
	return ..()

/datum/admin_ticket_panel/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "AdminTicketPanel")
		ui.set_autoupdate(TRUE)
		ui.open()

/datum/admin_ticket_panel/ui_state(mob/user)
	return GLOB.admin_state

/datum/admin_ticket_panel/ui_data(mob/user)
	. = list()
	.["ckey"] = user?.ckey

	var/list/tickets_data = list()

	for(var/datum/admin_help/AH in GLOB.ahelp_tickets.active_tickets)
		tickets_data += list(serialize_ticket(AH))

	for(var/datum/admin_help/AH in GLOB.ahelp_tickets.closed_tickets)
		tickets_data += list(serialize_ticket(AH))

	for(var/datum/admin_help/AH in GLOB.ahelp_tickets.resolved_tickets)
		tickets_data += list(serialize_ticket(AH))

	.["tickets"] = tickets_data

	if(selected_ticket)
		.["selected_ticket_ref"] = REF(selected_ticket)
	else
		.["selected_ticket_ref"] = null

	.["active_count"] = length(GLOB.ahelp_tickets.active_tickets)
	.["closed_count"] = length(GLOB.ahelp_tickets.closed_tickets)
	.["resolved_count"] = length(GLOB.ahelp_tickets.resolved_tickets)
	.["selected_state"] = selected_state

	var/unhandled_messages = 0
	for(var/list/commandMessage in GLOB.centcom_communications_messages)
		if(commandMessage["handled"] == FALSE)
			unhandled_messages++
	.["time"] = world.time
	.["communications"] = GLOB.centcom_communications_messages.Copy()
	.["communications_unhandled"] = unhandled_messages

/datum/admin_ticket_panel/proc/serialize_ticket(datum/admin_help/AH)
	. = list()
	.["ref"] = REF(AH)
	.["id"] = AH.id
	.["name"] = AH.name
	.["state"] = AH.state
	.["opened_at"] = AH.opened_at
	.["closed_at"] = AH.closed_at
	.["opened_at_text"] = GAMETIMESTAMP("hh:mm:ss", AH.opened_at)
	.["opened_ago_text"] = DisplayTimeText(world.time - AH.opened_at)
	.["closed_at_text"] = AH.closed_at ? GAMETIMESTAMP("hh:mm:ss", AH.closed_at) : null
	.["closed_ago_text"] = AH.closed_at ? DisplayTimeText(world.time - AH.closed_at) : null
	.["close_reason"] = AH.close_reason
	.["initiator_ckey"] = AH.initiator_ckey
	.["initiator_key_name"] = AH.initiator_key_name
	.["has_initiator"] = !isnull(AH.initiator)
	.["handler"] = AH.handler
	.["ticket_ping_stop"] = AH.ticket_ping_stop
	.["ticket_ping"] = AH.ticket_ping
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
	.["initiator_typing"] = (AH.initiator_typing_time != null && world.time - AH.initiator_typing_time < 5 SECONDS)
	if(!.["initiator_typing"] && AH.initiator_ckey)
		var/client/C = GLOB.directory[AH.initiator_ckey]
		if(C?.reply_modal_open)
			.["initiator_typing"] = TRUE
	.["interactions"] = AH._interactions.Copy()

/datum/admin_ticket_panel/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	if(!check_rights(R_ADMIN))
		return

	switch(action)
		if("select_ticket")
			var/ref = params["ref"]
			selected_ticket = locate(ref) in (GLOB.ahelp_tickets.active_tickets + GLOB.ahelp_tickets.closed_tickets + GLOB.ahelp_tickets.resolved_tickets)
			if(!selected_ticket)
				return TRUE
			. = TRUE

		if("refresh")
			. = TRUE

		if("reply")
			if(!selected_ticket || selected_ticket.state != AHELP_ACTIVE)
				return TRUE
			usr.client.cmd_ahelp_reply(selected_ticket.initiator)
			. = TRUE

		if("send_reply")
			if(!selected_ticket || selected_ticket.state != AHELP_ACTIVE || !selected_ticket.initiator)
				return TRUE
			var/message = params["message"]
			if(!istext(message))
				return TRUE
			message = trim(message)
			if(!message)
				return TRUE
			//auto-assign
			if(!selected_ticket.handler)
				selected_ticket.handle_issue()
			selected_ticket.typing_admins -= usr.ckey
			usr.client.cmd_admin_pm(selected_ticket.initiator, message)
			. = TRUE

		if("close")
			if(!selected_ticket || selected_ticket.state != AHELP_ACTIVE)
				return TRUE
			selected_ticket.suppress_ticket_panel = TRUE
			selected_ticket.Close()
			. = TRUE

		if("resolve")
			if(!selected_ticket || selected_ticket.state != AHELP_ACTIVE)
				return TRUE
			selected_ticket.suppress_ticket_panel = TRUE
			selected_ticket.Resolve()
			. = TRUE

		if("reject")
			if(!selected_ticket || selected_ticket.state != AHELP_ACTIVE)
				return TRUE
			selected_ticket.suppress_ticket_panel = TRUE
			selected_ticket.Reject()
			. = TRUE

		if("icissue")
			if(!selected_ticket || selected_ticket.state != AHELP_ACTIVE)
				return TRUE
			selected_ticket.suppress_ticket_panel = TRUE
			selected_ticket.ICIssue()
			. = TRUE

		if("skillissue")
			if(!selected_ticket || selected_ticket.state != AHELP_ACTIVE)
				return TRUE
			selected_ticket.suppress_ticket_panel = TRUE
			selected_ticket.SkillIssue()
			. = TRUE

		if("handle_issue")
			if(!selected_ticket || selected_ticket.state != AHELP_ACTIVE)
				return TRUE
			selected_ticket.handle_issue()
			. = TRUE

		if("reopen")
			if(!selected_ticket || selected_ticket.state == AHELP_ACTIVE)
				return TRUE
			selected_ticket.suppress_ticket_panel = TRUE
			selected_ticket.Reopen()
			. = TRUE

		if("retitle")
			if(!selected_ticket)
				return TRUE
			selected_ticket.suppress_ticket_panel = TRUE
			selected_ticket.Retitle()
			. = TRUE

		if("pingmute")
			if(!selected_ticket)
				return TRUE
			selected_ticket.ticket_ping_stop = !selected_ticket.ticket_ping_stop
			SSblackbox.record_feedback("tally", "ahelp_stats", 1, "pingmute")
			var/msg = "Ticket [selected_ticket.TicketHref("#[selected_ticket.id]")] has been [selected_ticket.ticket_ping_stop ? "" : "un"]muted from the Ticket Ping Subsystem by [key_name_admin(usr)]."
			message_admins(msg, islog = FALSE, prefix = "AHELP")
			log_admin_private(msg)
			. = TRUE

		if("player_panel")
			if(!selected_ticket || !selected_ticket.initiator)
				return TRUE
			var/mob/initiator_mob = selected_ticket.initiator.mob
			if(!initiator_mob)
				return TRUE
			usr.client?.holder?.show_player_panel(initiator_mob)
			. = TRUE

		if("follow")
			if(!selected_ticket || !selected_ticket.initiator)
				return TRUE
			var/mob/initiator_mob = selected_ticket.initiator.mob
			if(!initiator_mob)
				return TRUE
			var/client/C = usr.client
			if(!C)
				return TRUE
			if(!isobserver(usr) && !C.admin_ghost())
				return TRUE
			var/mob/dead/observer/observer = C.mob
			if(!istype(observer))
				return TRUE
			observer.ManualFollow(initiator_mob)
			. = TRUE

		if("logs")
			if(!selected_ticket || !selected_ticket.initiator)
				return TRUE
			var/mob/initiator_mob = selected_ticket.initiator.mob
			if(!initiator_mob)
				return TRUE
			var/datum/log_viewer/LV = new(initiator_mob)
			LV.ui_interact(usr)
			. = TRUE

		if("ban_panel")
			if(!selected_ticket)
				return TRUE
			usr.client.holder.DB_ban_panel(selected_ticket.initiator_ckey)
			. = TRUE

		if("mark_communication")
			var/message_id = params["message_id"]
			for(var/list/commandMessage in GLOB.centcom_communications_messages)
				if(commandMessage["id"] == message_id)
					commandMessage["handled"] = TRUE
					break
			. = TRUE

		if("orbit_comm_sender")
			var/sender_ckey = params["sender_ckey"]
			var/atom/movable/sender = get_mob_by_key(sender_ckey)
			if(!sender)
				return TRUE
			var/client/C = usr.client
			if(!C)
				return TRUE
			if(!isobserver(usr) && !C.admin_ghost())
				return TRUE
			var/mob/dead/observer/O = C.mob
			if(!istype(O))
				return TRUE
			O.ManualFollow(sender)
			. = TRUE

		if("typing_start")
			if(!selected_ticket || selected_ticket.state != AHELP_ACTIVE)
				return TRUE
			selected_ticket.typing_admins[usr.ckey] = world.time
			. = TRUE

		if("typing_stop")
			if(!selected_ticket)
				return TRUE
			selected_ticket.typing_admins -= usr.ckey
			. = TRUE

	SStgui.update_uis(src)
