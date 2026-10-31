/// The console is the physical external communications gateway. Local inboxes
/// contain packet-delivered copies; actionable messages remain owned by ingress.
/obj/machinery/computer/communications/netrun_machine_service_types()
	. = ..()
	. |= /datum/netrun_machine_service/communications_console
	. |= /datum/netrun_machine_service/communications_gateway

/datum/comm_message
	var/netrun_message_id
	var/netrun_gateway_tag
	var/netrun_answer_pending = FALSE
	var/netrun_answer_deadline = 0

/datum/netrun_machine_message/communications
	var/datum/weakref/answer_ref
	var/datum/weakref/console_ref

/datum/netrun_machine_message/communications/copy()
	var/datum/netrun_machine_message/communications/result = ..()
	result.answer_ref = answer_ref
	result.console_ref = console_ref
	return result

/datum/netrun_machine_message/communications/failed(reason)
	var/datum/comm_message/inbox = answer_ref?.resolve()
	if(inbox)
		inbox.netrun_answer_pending = FALSE
	var/obj/machinery/computer/communications/console = console_ref?.resolve()
	if(console)
		SStgui.update_uis(console)
	var/mob/user = user_ref?.resolve()
	if(user)
		to_chat(user, span_warning("Коммуникационный пакет не доставлен: [reason]."))

/// Ingress retains undelivered mail; transport completion retires only its copy.
/datum/netrun_machine_message/communications/inbox_delivery
	var/datum/weakref/gateway_ref

/datum/netrun_machine_message/communications/inbox_delivery/copy()
	var/datum/netrun_machine_message/communications/inbox_delivery/result = ..()
	result.gateway_ref = gateway_ref
	return result

/datum/netrun_machine_message/communications/inbox_delivery/coalescing_key()
	return "communications.inbox|[payload["id"]]"

/datum/netrun_machine_message/communications/inbox_delivery/delivered(datum/netrun_machine_service/recipient_service)
	var/datum/netrun_machine_service/communications_gateway/gateway = gateway_ref?.resolve()
	gateway?.inbox_delivered(payload["id"], payload["delivery_address"])

/datum/netrun_machine_message/communications/inbox_delivery/failed(reason)
	var/datum/netrun_machine_service/communications_gateway/gateway = gateway_ref?.resolve()
	gateway?.schedule_inbox_retry()
	return ..()

/datum/netrun_communications_record
	var/datum/comm_message/message
	var/list/recipients = list()
	var/list/pending = list()
	var/print = FALSE

/datum/netrun_communications_record/New(datum/comm_message/message)
	src.message = message

/datum/netrun_communications_record/Destroy()
	// Events may retain the canonical message and inspect its answer later.
	message = null
	recipients.Cut()
	pending.Cut()
	return ..()

/datum/netrun_machine_service/communications_gateway
	service_id = "communications.gateway"
	var/list/inbox = list()
	var/next_message_id = 0
	var/retry_timer

/datum/netrun_machine_service/communications_gateway/Destroy()
	if(retry_timer)
		deltimer(retry_timer)
	for(var/id in inbox)
		qdel(inbox[id])
	inbox.Cut()
	return ..()

/datum/netrun_machine_service/communications_gateway/proc/store(datum/comm_message/message)
	var/id = "[node.address]:[++next_message_id]"
	inbox[id] = new /datum/netrun_communications_record(message)
	if(length(inbox) > 400)
		var/oldest = inbox[1]
		qdel(inbox[oldest])
		inbox -= oldest
	return id

/// Trusted external ingress chooses one powered gateway; every inbox delivery
/// still resolves its physical destination and travels through the transport.
/datum/netrun_machine_service/communications_gateway/proc/broadcast(datum/comm_message/sending, print = FALSE, unique = FALSE)
	var/shared_id = unique ? store(sending) : null
	for(var/obj/machinery/computer/communications/console as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/computer/communications))
		if(console.machine_stat & (BROKEN | NOPOWER) || !is_station_level(console.z))
			continue
		var/datum/netrun_machine_service/client = console.get_netrun_machine_service("communications.console")
		if(!client)
			continue
		var/id = shared_id
		if(!id)
			var/datum/comm_message/copy = new(sending.title, sending.content, sending.possible_answers.Copy())
			id = store(copy)
		var/datum/netrun_communications_record/record = inbox[id]
		record.recipients[client.node.address] = WEAKREF(client)
		record.pending[client.node.address] = TRUE
		record.print = print
		send_inbox(id, client.node.address)
	schedule_inbox_retry()

/datum/netrun_machine_service/communications_gateway/proc/send_inbox(id, address)
	var/datum/netrun_communications_record/record = inbox[id]
	var/datum/weakref/reference = record?.recipients[address]
	var/datum/netrun_machine_service/client = reference?.resolve()
	if(QDELETED(client))
		if(record)
			record.pending -= address
		return FALSE
	var/datum/comm_message/sending = record.message
	var/datum/netrun_machine_message/communications/inbox_delivery/packet = new(list("operation" = "inbox", "id" = id,
		"gateway" = service_tag(), "title" = sending.title, "content" = sending.content, "delivery_address" = address,
		"answers" = sending.possible_answers.Copy(), "answered" = sending.answered, "print" = record.print))
	packet.gateway_ref = WEAKREF(src)
	return send("communications.console", packet, client.service_tag())

/datum/netrun_machine_service/communications_gateway/proc/inbox_delivered(id, address)
	var/datum/netrun_communications_record/record = inbox[id]
	if(record)
		record.pending -= address

/datum/netrun_machine_service/communications_gateway/proc/schedule_inbox_retry()
	if(!QDELETED(src) && !retry_timer)
		retry_timer = addtimer(CALLBACK(src, PROC_REF(retry_inbox)), 10 SECONDS, TIMER_STOPPABLE | TIMER_DELETE_ME)

/datum/netrun_machine_service/communications_gateway/proc/retry_inbox()
	retry_timer = null
	var/pending = FALSE
	for(var/id in inbox)
		var/datum/netrun_communications_record/record = inbox[id]
		for(var/address in record.pending.Copy())
			send_inbox(id, address)
		pending = pending || length(record.pending)
	if(pending)
		schedule_inbox_retry()

/datum/netrun_machine_service/communications_gateway/accepts(datum/netrun_machine_message/message)
	return ..() && message.source?.service_id == "communications.console" && istype(message.source.host, /obj/machinery/computer/communications)

/datum/netrun_machine_service/communications_gateway/receive(datum/netrun_machine_message/message)
	if(!accepts(message))
		return FALSE
	var/obj/machinery/computer/communications/console = message.source.host
	var/mob/user = message.user_ref?.resolve()
	if(QDELETED(user) || !console.has_communication())
		return FALSE
	var/list/data = message.payload
	switch(data["operation"])
		if("answer")
			if(!console.authenticated(user))
				return FALSE
			var/datum/netrun_communications_record/record = inbox[data["id"]]
			var/datum/weakref/recipient = record?.recipients[message.source.node.address]
			if(!record || recipient?.resolve() != message.source)
				return FALSE
			var/answer = data["answer"]
			if(!isnum(answer) || answer != round(answer) || answer < 1 || answer > length(record.message.possible_answers))
				return FALSE
			if(!record.message.answered)
				record.message.answered = answer
				record.message.answer_callback?.InvokeAsync()
			for(var/address in record.recipients)
				var/datum/weakref/reference = record.recipients[address]
				var/datum/netrun_machine_service/client = reference?.resolve()
				if(!QDELETED(client))
					send_to(client, new /datum/netrun_machine_message/communications(list("operation" = "answered", "id" = data["id"], "answer" = record.message.answered)))
			return TRUE
		if("associates", "sector")
			// Outbound requests belong to this terminal's external gateway.
			if(console != host)
				return FALSE
			return console.deliver_netrun_outbound(data, user)
	return FALSE

/datum/netrun_machine_service/communications_console
	service_id = "communications.console"
	var/list/answer_states = list()

/datum/netrun_machine_service/communications_console/accepts(datum/netrun_machine_message/message)
	return ..() && message.source?.service_id == "communications.gateway" && istype(message.source.host, /obj/machinery/computer/communications)

/datum/netrun_machine_service/communications_console/receive(datum/netrun_machine_message/message)
	if(!accepts(message))
		return FALSE
	var/obj/machinery/computer/communications/console = host
	var/list/data = message.payload
	var/state_id = "[message.source.service_tag()]|[data["id"]]"
	if(data["operation"] == "answered")
		answer_states[state_id] = data["answer"]
		if(length(answer_states) > 400)
			answer_states.Cut(1, 101)
		for(var/datum/comm_message/inbox as anything in console.messages)
			if(inbox.netrun_message_id == data["id"] && inbox.netrun_gateway_tag == message.source.service_tag())
				inbox.answered = data["answer"]
				inbox.netrun_answer_pending = FALSE
	else if(data["operation"] == "inbox")
		if(data["gateway"] != message.source.service_tag())
			return FALSE
		for(var/datum/comm_message/inbox as anything in console.messages)
			if(inbox.netrun_message_id == data["id"] && inbox.netrun_gateway_tag == data["gateway"])
				return TRUE
		var/list/answers = data["answers"]
		var/datum/comm_message/inbox = new(data["title"], data["content"], answers.Copy())
		inbox.netrun_message_id = data["id"]
		inbox.netrun_gateway_tag = data["gateway"]
		inbox.answered = answer_states[state_id] || data["answered"]
		console.add_message(inbox)
		if(data["print"])
			var/obj/item/paper/printed_paper = new(console.loc)
			printed_paper.name = "paper - '[inbox.title]'"
			printed_paper.add_raw_text(inbox.content)
			printed_paper.update_appearance()
	else
		return FALSE
	SStgui.update_uis(console)
	SEND_SIGNAL(console, COMSIG_NETRUN_SERVICE_STATE_CHANGED)
	return TRUE

/obj/machinery/computer/communications/proc/queue_netrun_answer(datum/comm_message/inbox, answer, mob/user)
	if(inbox.netrun_answer_pending && world.time < inbox.netrun_answer_deadline)
		return FALSE
	var/datum/netrun_machine_service/client = get_netrun_machine_service("communications.console")
	var/datum/netrun_machine_message/communications/message = new(list("operation" = "answer", "id" = inbox.netrun_message_id, "answer" = answer))
	message.answer_ref = WEAKREF(inbox)
	message.console_ref = WEAKREF(src)
	message.user_ref = WEAKREF(user)
	inbox.netrun_answer_pending = TRUE
	inbox.netrun_answer_deadline = world.time + 1 MINUTES
	return client.send("communications.gateway", message, inbox.netrun_gateway_tag)

/obj/machinery/computer/communications/proc/queue_netrun_outbound(operation, text, mob/user, destination)
	var/datum/netrun_machine_service/client = get_netrun_machine_service("communications.console")
	var/datum/netrun_machine_message/communications/message = new(list("operation" = operation, "text" = text, "destination" = destination))
	message.user_ref = WEAKREF(user)
	message.console_ref = WEAKREF(src)
	if(!client.send("communications.gateway", message, client.node.address))
		return FALSE
	to_chat(user, span_notice("Сообщение поставлено в сетевую очередь."))
	return TRUE

/// These external side effects happen only after APC discovery and packet delivery.
/obj/machinery/computer/communications/proc/deliver_netrun_outbound(list/data, mob/user)
	var/text = data["text"]
	if(!istext(text) || !length(text) || length(text) > MAX_MESSAGE_LEN)
		return FALSE
	if(data["operation"] == "associates")
		if(!authenticated_as_non_silicon_command(user))
			return FALSE
		var/emagged = obj_flags & EMAGGED
		if((emagged && GLOB.master_mode == "Extended") || syndicate)
			message_syndicate(text, user)
		else if(emagged)
			message_inteq(text, user)
		else
			message_centcom(text, user)
		var/associates = (emagged || syndicate) ? "the Illegal Channel" : "CentCom"
		to_chat(user, span_notice("Сообщение доставлено: [associates]."))
		user.log_talk(text, LOG_SAY, tag = "сообщение для [associates]")
		deadchat_broadcast(" отправляет [associates], \"[text]\" где-то на территории [span_name("[get_area_name(user, TRUE)]")].", span_name("[user.real_name]"), user, message_type = DEADCHAT_ANNOUNCEMENT)
		return TRUE
	if(data["operation"] == "sector")
		if(!authenticated_as_non_silicon_captain(user) || !can_send_messages_to_other_sectors(user))
			return FALSE
		var/list/payload = list("sender_ckey" = user.ckey)
		var/network_name = CONFIG_GET(string/cross_comms_network)
		if(network_name)
			payload["network"] = network_name
		var/destination = data["destination"]
		var/list/servers = CONFIG_GET(keyed_list/cross_server)
		if(destination != "all" && !(destination in servers))
			return FALSE
		send2otherserver(html_decode(station_name()), text, "Comms_Console", destination == "all" ? null : list(destination), additional_data = payload)
		minor_announce(text, title = "Outgoing message to allied station")
		user.log_talk(text, LOG_SAY, tag = "message to the other server")
		message_admins("[ADMIN_LOOKUPFLW(user)] has sent a message to the other server\[s].")
		deadchat_broadcast(" has sent an outgoing message to the other station(s).</span>", "<span class='bold'>[user.real_name]", user, message_type = DEADCHAT_ANNOUNCEMENT)
		to_chat(user, span_notice("Сообщение передано союзной станции."))
		return TRUE
	return FALSE
