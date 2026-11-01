/// Messenger programs are logical endpoints on their actual device's node.
/obj/item/modular_computer/netrun_machine_service_types()
	return ..() + list(/datum/netrun_machine_service/pda_messenger)

/// A resident process moves its endpoint with its host; it never creates a PDA node.
/obj/item/modular_computer/pda/netrun/netrun_machine_service_node()
	var/mob/camera/netrun_entity/entity = loc
	return istype(entity) ? entity.host_node : null

/obj/item/modular_computer/pda/silicon/pai/netrun_machine_service_node()
	return silicon_owner?.GetComponent(/datum/component/netrun_node)

/datum/netrun_machine_service/pda_messenger
	service_id = "pda.messenger"

/datum/netrun_machine_service/pda_messenger/resolve_node()
	var/obj/item/modular_computer/computer = host
	if(!computer.netrun_nodeable)
		node = host.netrun_machine_service_node()
	return node

/datum/netrun_machine_service/pda_messenger/proc/messenger()
	var/obj/item/modular_computer/computer = host
	if(QDELETED(computer))
		return null
	return locate(/datum/computer_file/program/messenger) in computer.get_all_files()

/datum/netrun_machine_service/pda_messenger/service_tag()
	var/datum/computer_file/program/messenger/app = messenger()
	return app ? REF(app) : null

/datum/netrun_machine_service/pda_messenger/matches(datum/netrun_machine_service/source_service, recipient_tag)
	return ..() && !!messenger()

/datum/netrun_machine_service/pda_messenger/accepts(datum/netrun_machine_message/message)
	if(!..() || !istype(message, /datum/netrun_machine_message/telecomms/pda))
		return FALSE
	var/datum/computer_file/program/messenger/app = messenger()
	var/obj/item/modular_computer/computer = host
	var/datum/netrun_machine_message/telecomms/pda/packet = message
	if(!app || !computer.enabled || !app.sending_and_receiving || packet.target_program?.resolve() != app)
		return FALSE
	if(istype(computer, /obj/item/modular_computer/pda))
		var/obj/item/modular_computer/pda/pda = computer
		if(pda.toff)
			return FALSE
	return TRUE

/datum/netrun_machine_service/pda_messenger/receive(datum/netrun_machine_message/telecomms/pda/message)
	if(!accepts(message))
		return FALSE
	var/datum/computer_file/program/messenger/app = messenger()
	var/datum/netrun_telecomms_transmission/transmission = message.transmission
	if(!transmission || transmission.finished)
		return FALSE
	if(transmission.received_by[REF(app)])
		return TRUE
	if(!app.receive_message(message.signal))
		return FALSE
	transmission.received_by[REF(app)] = TRUE
	message.signal.mark_done()
	if(istype(transmission, /datum/netrun_telecomms_transmission/pda))
		var/datum/netrun_telecomms_transmission/pda/pda_delivery = transmission
		pda_delivery.recipient_delivered(app)
	return TRUE

/datum/netrun_machine_service/pda_messenger/rejection_reason(datum/netrun_machine_message/message)
	var/obj/item/modular_computer/computer = host
	var/datum/computer_file/program/messenger/app = messenger()
	if(!app)
		return "PDA: программа сообщений удалена"
	if(!computer.enabled)
		return "PDA: устройство выключено"
	if(!app.sending_and_receiving)
		return "PDA: приём сообщений отключён"
	if(istype(computer, /obj/item/modular_computer/pda))
		var/obj/item/modular_computer/pda/pda = computer
		if(pda.toff)
			return "PDA: модуль связи отключён"
	var/datum/netrun_machine_message/telecomms/pda/packet = message
	if(!istype(packet) || packet.target_program?.resolve() != app)
		return "PDA: адрес программы изменился"
	if(!packet.transmission || packet.transmission.finished)
		return "PDA: передача уже завершена"
	return "PDA: программа не приняла сообщение"

/datum/netrun_machine_message/telecomms/pda
	var/datum/weakref/target_program

/datum/netrun_machine_message/telecomms/pda/New(datum/signal/subspace/messaging/tablet_message/signal, datum/computer_file/program/messenger/app)
	..(signal)
	if(app)
		target_program = WEAKREF(app)

/datum/netrun_machine_message/telecomms/pda/copy()
	var/datum/netrun_machine_message/telecomms/pda/duplicate = ..()
	duplicate.target_program = target_program
	return duplicate

/datum/netrun_machine_message/telecomms/pda/Destroy()
	target_program = null
	return ..()

/// Broadcasters submit one routed packet per logical recipient, with no global delivery.
/proc/netrun_broadcast_tablet(datum/signal/subspace/messaging/tablet_message/signal)
	var/obj/machinery/telecomms/transmitter = signal.netrun_transmitter?.resolve()
	var/datum/netrun_machine_service/sender = transmitter?.get_netrun_machine_service("telecomms.relay")
	if(!signal.netrun_transmission)
		signal.netrun_transmission = new(signal)
	var/datum/netrun_telecomms_transmission/transmission = signal.netrun_transmission
	transmission.dispatching++
	var/admitted = 0
	if(sender)
		for(var/datum/computer_file/program/messenger/app as anything in signal.data["targets"])
			if(QDELETED(app) || QDELETED(app.computer) || transmission.received_by[REF(app)])
				continue
			var/datum/netrun_machine_service/recipient = app.computer.get_netrun_machine_service("pda.messenger")
			if(!recipient)
				continue
			var/datum/netrun_machine_message/telecomms/pda/packet = new(signal, app)
			if(sender.send(recipient.service_id, packet, recipient.service_tag()))
				admitted++
	if(!admitted && !length(transmission.received_by))
		transmission.failure_reason = "Не удалось передать сообщение на устройство адресата."
	transmission.dispatching--
	transmission.check_finished()
	return admitted

/datum/computer_file/program/messenger
	var/netrun_pending_messages = 0
	var/netrun_delivery_status
	var/netrun_delivery_error = FALSE

/// Sender state is weakly referenced; closing/deleting the device cannot retain a user.
/datum/netrun_telecomms_transmission/pda
	var/datum/weakref/sender_program
	var/datum/weakref/actor
	var/list/target_chats = list()
	var/list/target_names = list()
	var/photo_asset

/datum/netrun_telecomms_transmission/pda/New(datum/signal/subspace/messaging/tablet_message/signal, datum/computer_file/program/messenger/app, atom/source, list/chats, photo_asset)
	..(signal)
	sender_program = WEAKREF(app)
	if(source)
		actor = WEAKREF(source)
	for(var/datum/pda_chat/chat as anything in chats)
		if(chat.recipient)
			target_chats[chat.recipient.reference] = WEAKREF(chat)
	src.photo_asset = photo_asset

/datum/netrun_telecomms_transmission/pda/proc/recipient_delivered(datum/computer_file/program/messenger/recipient)
	var/datum/computer_file/program/messenger/app = sender_program?.resolve()
	var/datum/weakref/chat_ref = target_chats[REF(recipient)]
	var/datum/pda_chat/chat = chat_ref?.resolve()
	if(!app || !chat || app.saved_chats[REF(chat)] != chat)
		return
	var/datum/pda_message/message = new(signal.data["message"], TRUE, STATION_TIME_TIMESTAMP("hh:mm", world.time), photo_asset, signal.data["everyone"])
	chat.add_message(message, show_in_recents = !signal.data["everyone"])
	chat.unread_messages = 0
	if(!signal.data["everyone"])
		app.viewing_messages_of = REF(chat)
	SStgui.update_uis(app.computer)

/// Отладочный глобальный сигнал NTnet (verb администратора) доставляет мимо telecomms и сети APC, как до netrun.
/datum/netrun_telecomms_transmission/pda/proc/deliver_directly()
	dispatching++
	for(var/datum/computer_file/program/messenger/app as anything in signal.data["targets"])
		if(QDELETED(app) || received_by[REF(app)] || !app.receive_message(signal))
			continue
		received_by[REF(app)] = TRUE
		recipient_delivered(app)
	if(length(received_by))
		signal.mark_done()
	else
		failure_reason = "Ни один адресат не принял сообщение."
	. = length(received_by)
	dispatching--
	check_finished()

/datum/netrun_telecomms_transmission/pda/player_actor()
	return actor?.resolve()

/datum/netrun_telecomms_transmission/pda/complete()
	var/datum/computer_file/program/messenger/app = sender_program?.resolve()
	if(!app || QDELETED(app.computer))
		return
	app.netrun_pending_messages = max(0, app.netrun_pending_messages - 1)
	app.netrun_delivery_error = !length(received_by)
	var/atom/source = actor?.resolve()
	if(length(received_by))
		app.netrun_delivery_status = "Доставлено адресатам: [length(received_by)] из [length(signal.data["targets"])]."
		app.complete_netrun_message(source, signal, target_names)
	else
		app.netrun_delivery_status = "Ошибка доставки: [failure_reason || "сервер не ответил"]."
		if(ismob(source))
			to_chat(source, span_warning(app.netrun_delivery_status))
		if(app.alert_able && !app.alert_silenced)
			playsound(app.computer, 'sound/machines/terminal_error.ogg', 15, TRUE)
	SStgui.update_uis(app.computer)

/datum/netrun_telecomms_transmission/pda/Destroy()
	sender_program = null
	actor = null
	target_chats.Cut()
	target_names.Cut()
	photo_asset = null
	return ..()

/// Automated notices and message monitors report completion, never queued == delivered.
/datum/netrun_telecomms_transmission/notification
	var/datum/weakref/actor
	var/datum/weakref/message_console

/datum/netrun_telecomms_transmission/notification/New(datum/signal/subspace/messaging/tablet_message/signal, mob/user, obj/machinery/computer/message_monitor/console)
	..(signal)
	if(user)
		actor = WEAKREF(user)
	if(console)
		message_console = WEAKREF(console)

/datum/netrun_telecomms_transmission/notification/complete()
	var/mob/user = actor?.resolve()
	var/obj/machinery/computer/message_monitor/console = message_console?.resolve()
	var/status = length(received_by) ? "Сообщение доставлено." : "Ошибка доставки: [failure_reason || "сервер не ответил"]."
	if(user)
		if(length(received_by))
			var/datum/signal/subspace/messaging/tablet_message/tablet = signal
			user.log_message("(PDA: [signal.source]) sent \"[signal.data["message"]]\" to [tablet.format_target()]", LOG_PDA)
			to_chat(user, span_notice(status))
		else
			to_chat(user, span_warning(status))
	if(console)
		console.message = status
		SStgui.update_uis(console)
	..()

/datum/netrun_telecomms_transmission/notification/player_actor()
	return actor?.resolve()

/datum/netrun_telecomms_transmission/notification/Destroy()
	actor = null
	message_console = null
	return ..()

/proc/netrun_send_tablet_via_server(datum/signal/subspace/messaging/tablet_message/signal, obj/machinery/telecomms/message_server/server, mob/user)
	var/obj/machinery/computer/message_monitor/console = signal.source
	var/datum/netrun_telecomms_transmission/notification/transmission = new(signal, user, istype(console) ? console : null)
	transmission.dispatching++
	var/datum/netrun_machine_service/sender = netrun_telecomms_origin(signal.source)
	var/datum/netrun_machine_service/recipient = server?.get_netrun_machine_service("telecomms.relay")
	var/admitted = FALSE
	if(sender && recipient)
		admitted = sender.send(recipient.service_id, new /datum/netrun_machine_message/telecomms(signal), recipient.service_tag())
	if(!admitted)
		transmission.failure_reason = "Нет маршрута к серверу сообщений."
	transmission.dispatching--
	transmission.check_finished()
	return admitted
