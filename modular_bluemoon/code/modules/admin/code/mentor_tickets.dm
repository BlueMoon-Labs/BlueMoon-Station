GLOBAL_DATUM_INIT(mentor_tickets, /datum/mentor_ticket_manager, new)

#define MENTOR_TICKET_ACTIVE 1
#define MENTOR_TICKET_CLOSED 2
#define MENTOR_TICKET_RESOLVED 3

/datum/mentor_ticket_manager
	var/list/active_tickets = list()
	var/list/closed_tickets = list()
	var/list/resolved_tickets = list()

/datum/mentor_ticket_manager/Destroy()
	QDEL_LIST(active_tickets)
	QDEL_LIST(closed_tickets)
	QDEL_LIST(resolved_tickets)
	return ..()

/datum/mentor_ticket_manager/proc/CKey2Ticket(ckey)
	for(var/I in active_tickets)
		var/datum/mentor_ticket/MT = I
		if(MT.initiator_ckey == ckey)
			return MT

/datum/mentor_ticket_manager/proc/TicketsByCKey(ckey)
	. = list()
	for(var/list/ticket_list as anything in list(active_tickets, closed_tickets, resolved_tickets))
		for(var/datum/mentor_ticket/ticket as anything in ticket_list)
			if(ticket.initiator_ckey == ckey)
				. += ticket

/datum/mentor_ticket_manager/proc/TicketByID(id)
	for(var/list/ticket_list as anything in list(active_tickets, closed_tickets, resolved_tickets))
		for(var/datum/mentor_ticket/ticket as anything in ticket_list)
			if(ticket.id == id)
				return ticket

/datum/mentor_ticket_manager/proc/ListInsert(datum/mentor_ticket/new_ticket)
	var/list/ticket_list
	switch(new_ticket.state)
		if(MENTOR_TICKET_ACTIVE)
			ticket_list = active_tickets
		if(MENTOR_TICKET_CLOSED)
			ticket_list = closed_tickets
		if(MENTOR_TICKET_RESOLVED)
			ticket_list = resolved_tickets
		else
			CRASH("Invalid mentor ticket state: [new_ticket.state]")
	var/num_closed = ticket_list.len
	if(num_closed)
		for(var/I in 1 to num_closed)
			var/datum/mentor_ticket/MT = ticket_list[I]
			if(MT.id > new_ticket.id)
				ticket_list.Insert(I, new_ticket)
				return
	ticket_list += new_ticket

/datum/mentor_ticket
	var/id
	var/name
	var/state = MENTOR_TICKET_ACTIVE

	var/opened_at
	var/closed_at
	var/close_reason

	var/client/initiator
	var/initiator_ckey
	var/initiator_key_name

	var/list/_interactions

	var/static/ticket_counter = 0
	var/answered = FALSE

	var/handler
	var/list/typing_mentors
	var/initiator_typing_time
/datum/mentor_ticket/New(msg, client/C, is_bwoink)
	msg = copytext_char(msg, 1, MAX_MESSAGE_LEN)
	if(!msg || !C || !C.mob)
		qdel(src)
		return

	if(GLOB.mentor_tickets?.CKey2Ticket(C.ckey))
		qdel(src)
		return

	id = ++ticket_counter
	opened_at = world.time

	name = length_char(msg) > 27 ? html_encode(copytext_char(msg, 1, 28)) + "..." : html_encode(msg)

	initiator = C
	initiator_ckey = initiator.ckey
	initiator_key_name = CONFIG_GET(flag/mentors_mobname_only) ? "Ментор" : key_name(initiator, FALSE, TRUE)

	_interactions = list()
	typing_mentors = list()

	if(is_bwoink)
		AddInteraction("<font color='#a855f7'>[key_name_admin(usr)] PM'd [LinkedReplyName()]</font>")
		message_admins("<font color='#a855f7'>Mentor ticket [TicketHref("#[id]")] created</font>")
		handle_issue()
	else
		MessageNoRecipient(msg)
		log_admin_private("Mentor Ticket #[id]: [key_name(initiator)]: [name]")

	if(!length(mentor_traffic_recipients()))
		to_chat(C, "<span class='notice'>Сейчас нет менторов и администраторов онлайн. Ваш вопрос сохранён и будет рассмотрен, как только кто-то из них появится.</span>")

	GLOB.mentor_tickets.active_tickets += src

/datum/mentor_ticket/Destroy()
	GLOB.mentor_tickets.active_tickets -= src
	GLOB.mentor_tickets.closed_tickets -= src
	GLOB.mentor_tickets.resolved_tickets -= src
	return ..()

/datum/mentor_ticket/proc/AddInteraction(formatted_message)
	if(usr && (usr.ckey != initiator_ckey) && !answered)
		answered = TRUE
		send2adminchat(initiator_ckey, "[key_name(initiator)] | Mentor Ticket #[id]: Answered by [key_name(usr)]")
	_interactions += "[TIME_STAMP("hh:mm:ss", FALSE)]: [formatted_message]"

/datum/mentor_ticket/proc/LinkedReplyName(ref_src)
	if(!ref_src)
		ref_src = "[REF(src)]"
	var/link = CONFIG_GET(flag/mentors_mobname_only) && initiator?.mob ? REF(initiator.mob) : initiator_ckey
	return "<A HREF='?_src_=mentor;mentor_msg=[link]'>[initiator_key_name]</A>"

/datum/mentor_ticket/proc/TicketHref(msg, ref_src, action = "mentorticket")
	if(!ref_src)
		ref_src = "[REF(src)]"
	return "<A HREF='?_src_=holder;[HrefToken(TRUE)];mentorticket=[ref_src];mentorticket_action=[action]'>[msg]</A>"

/datum/mentor_ticket/proc/MessageNoRecipient(msg)
	msg = copytext_char(sanitize(msg), 1, MAX_MESSAGE_LEN)
	var/encoded_msg = html_encode(msg)
	var/ref_src = "[REF(src)]"

	var/mentor_msg = "<span class='mentornotice'><span class='mentorhelp'>Mentor Ticket [TicketHref("#[id]", ref_src)]</span><b>: "
	mentor_msg += "[LinkedReplyName(ref_src)]:</b> <span class='linkify'>[keywords_lookup(msg)]</span><br></span>"
	AddInteraction("<font color='#a855f7'>[LinkedReplyName(ref_src)]: [encoded_msg]</font>")

	// mentor_traffic_recipients(), а не GLOB.mentors | GLOB.admins: нажавшие
	// Dementor не должны получать ментор-тикеты (для админов список не фильтр).
	for(var/client/X in mentor_traffic_recipients())
		if(X.prefs.toggles & SOUND_ADMINHELP)
			SEND_SOUND(X, sound('sound/effects/adminhelp.ogg'))
		to_chat(X, examine_block(mentor_msg))

	to_chat(initiator, "<span class='mentornotice'>PM для-<b>Менторов</b>: <span class='linkify'>[encoded_msg]</span></span>")

/datum/mentor_ticket/proc/Close()
	if(state != MENTOR_TICKET_ACTIVE)
		return
	RemoveActive()
	state = MENTOR_TICKET_CLOSED
	if(!close_reason)
		close_reason = "Закрыт"
	GLOB.mentor_tickets.ListInsert(src)
	to_chat(initiator, examine_block("<center><span class='mentornotice'>Ваш ментор-тикет был закрыт.</span></center>"))
	AddInteraction("<font color='#a855f7'><u>Закрыт</u> [key_name_admin(usr)].</font>")
	var/msg = "Mentor ticket [TicketHref("#[id]")] closed by [key_name_admin(usr)]."
	message_admins(msg, islog = FALSE, prefix = "MENTOR")
	log_admin_private(msg)

/datum/mentor_ticket/proc/Resolve()
	if(state != MENTOR_TICKET_ACTIVE)
		return
	RemoveActive()
	state = MENTOR_TICKET_RESOLVED
	if(!close_reason)
		close_reason = "Решён"
	GLOB.mentor_tickets.ListInsert(src)

	AddInteraction("<font color='#4ade80'><u>Решён</u> [key_name_admin(usr)].</font>")
	to_chat(initiator, examine_block("<center><span class='mentornotice'>Ваш ментор-тикет был решён.</span></center>"))
	var/msg = "Mentor ticket [TicketHref("#[id]")] resolved by [key_name_admin(usr)]."
	message_admins(msg, islog = FALSE, prefix = "MENTOR")
	log_admin_private(msg)

/datum/mentor_ticket/proc/handle_issue()
	if(state != MENTOR_TICKET_ACTIVE)
		return FALSE
	if(handler && handler == usr.ckey)
		return TRUE
	if(handler && handler != usr.ckey)
		var/response = tgui_alert(usr, "Тикет уже взят ментором [handler]. Взять всё равно?", "Тикет назначен", list("Да", "Нет"))
		if(response != "Да")
			return FALSE
	if(initiator)
		to_chat(initiator, "<span class='mentornotice'>Ваш ментор-тикет был взят. Пожалуйста, подождите.</span>")
	handler = "[usr.ckey]"
	AddInteraction("<u>Взят ментором</u> [key_name_admin(usr)]")
	var/msg = "Mentor ticket [TicketHref("#[id]")] taken by [key_name_admin(usr)]."
	message_admins(msg, islog = FALSE, prefix = "MENTOR")
	log_admin_private(msg)
	return TRUE

/datum/mentor_ticket/proc/Action(action)
	switch(action)
		if("reply")
			usr.client.cmd_mentor_pm(initiator)
		if("close")
			Close()
		if("resolve")
			Resolve()
		if("handle_issue")
			handle_issue()
		if("reopen")
			Reopen()

/datum/mentor_ticket/proc/RemoveActive()
	if(state != MENTOR_TICKET_ACTIVE)
		return
	closed_at = world.time
	GLOB.mentor_tickets.active_tickets -= src

/datum/mentor_ticket/proc/Reopen()
	if(state == MENTOR_TICKET_ACTIVE)
		to_chat(usr, "<span class='warning'>Этот тикет уже открыт.</span>")
		return
	if(GLOB.mentor_tickets.CKey2Ticket(initiator_ckey))
		to_chat(usr, "<span class='warning'>У этого пользователя уже есть открытый ментор-тикет.</span>")
		return
	GLOB.mentor_tickets.active_tickets += src
	GLOB.mentor_tickets.closed_tickets -= src
	GLOB.mentor_tickets.resolved_tickets -= src
	state = MENTOR_TICKET_ACTIVE
	closed_at = null
	close_reason = null
	AddInteraction("<font color='#c084fc'><u>Переоткрыт</u> [key_name_admin(usr)]</font>")
	var/msg = "Mentor ticket [TicketHref("#[id]")] was reopened by [key_name_admin(usr)]."
	message_admins(msg, islog = FALSE, prefix = "MENTOR")
	log_admin_private(msg)
