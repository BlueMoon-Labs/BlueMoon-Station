/// Wire message values and asynchronous, revalidated data delivery.
/// Every message is owned by its delivery. Payload lists never alias native state.
/// Preserve indexed sublists as array elements, not associative keys with null values.
/// The generic deepCopyList helper changes their JSON shape (notably scrubber filters).
/proc/netrun_copy_wire_value(value)
	if(!islist(value))
		return value
	var/list/input = value
	var/list/output = input.Copy()
	for(var/i in 1 to length(input))
		var/key = input[i]
		if(islist(key))
			output[i] = netrun_copy_wire_value(key)
		else if(!isnum(key) && islist(input[key]))
			output[key] = netrun_copy_wire_value(input[key])
	return output

/datum/netrun_machine_message
	var/list/payload
	var/datum/netrun_machine_service/source
	var/datum/netrun_machine_service/recipient
	var/datum/weakref/user_ref
	var/correlation_id

/datum/netrun_machine_message/New(list/payload)
	src.payload = payload ? netrun_copy_wire_value(payload) : list()

/datum/netrun_machine_message/Destroy()
	payload = null
	source = null
	recipient = null
	user_ref = null
	return ..()

/datum/netrun_machine_message/proc/copy()
	var/datum/netrun_machine_message/result = new type()
	result.payload = netrun_copy_wire_value(payload)
	result.user_ref = user_ref
	result.correlation_id = correlation_id
	return result

/datum/netrun_machine_message/proc/reply(datum/netrun_machine_message/response)
	response.correlation_id = correlation_id
	return recipient.send_to(source, response)

/datum/netrun_machine_message/proc/failed(reason)
	return

/datum/netrun_machine_message/proc/delivered(datum/netrun_machine_service/recipient_service)
	return

/// Only replaceable state snapshots opt in; commands retain their own delivery.
/datum/netrun_machine_message/proc/coalescing_key()
	return null

/// Replaceable state may carry a domain revision. A delayed older producer must
/// not discard newer state already waiting in discovery or on the wire.
/datum/netrun_machine_message/proc/can_replace(datum/netrun_machine_message/previous)
	return TRUE

/// Replaceable telemetry yields to ordinary traffic. An actor reference is not
/// evidence of explicit input: radio speech and automated notices also have one.
/datum/netrun_machine_message/proc/delivery_priority()
	return isnull(coalescing_key()) ? NETRUN_TASK_NORMAL : NETRUN_TASK_BACKGROUND

/datum/netrun_machine_transport/proc/dispatch(datum/netrun_machine_service/source, datum/netrun_machine_service/target, datum/netrun_machine_message/message)
	if(QDELETED(message))
		return FALSE
	var/contract_key = message.coalescing_key()
	var/key
	if(!isnull(contract_key) && !QDELETED(source) && !QDELETED(target))
		// Service identity and binding both belong to the delivery context. A new
		// service on the same host must not reuse a packet addressed to its predecessor.
		key = "[REF(source)]|[source.resolve_node()?.address]|[REF(target)]|[target.service_tag()]|[contract_key]"
		var/datum/netrun_machine_packet/data/previous = replaceable_packets[key]
		if(!QDELETED(previous) && !previous.finishing)
			if(!message.can_replace(previous.message))
				qdel(message)
				coalesced_packets++
				return TRUE
			message.source = source
			message.recipient = target
			message.correlation_id = previous.operation.operation_id
			qdel(previous.message)
			previous.message = message
			previous.capture_dirty = TRUE
			coalesced_packets++
			return TRUE
	var/datum/netrun_machine_packet/data/packet = new(source, target, message)
	if(key)
		packet.replacement_key = key
		replaceable_packets[key] = packet
	return packet.send()

/// Machine traffic is drawn at dispatch, bounded independently of the number of packets.
/datum/netrun_machine_transport/proc/record_flow(datum/netrun_machine_service/source, datum/netrun_machine_service/target, datum/netrun_packet_context/operation)
	if(world.time >= flow_window)
		flow_window = world.time + 1 SECONDS
		flow_count = 0
	if(flow_count >= NETRUN_MAX_MACHINE_FLIGHTS)
		return FALSE
	var/from = source?.resolve_node()?.address
	var/destination = target?.resolve_node()?.address
	if(!from || !destination || from == destination)
		return FALSE
	var/pair = "[from]>[destination]"
	if(last_flow[pair] > world.time)
		return FALSE
	if(length(last_flow) > 2048)
		last_flow.Cut()
	last_flow[pair] = world.time + 2 SECONDS
	flow_count++
	operation.quiet_success = TRUE
	return operation.announce_flight()

/// A cancellable packet checks the current route again when its latency elapses.
/datum/netrun_machine_packet
	parent_type = /datum/netrun_delivery
	delivery_kind = "machine_delivery"
	var/datum/netrun_machine_service/source
	var/datum/netrun_machine_service/recipient
	var/finishing = FALSE
	var/kind = "machine"
	var/list/interest_route
	var/packet_id
	var/source_address
	var/destination_address
	var/datum/netrun_packet_context/operation
	var/sent_at
	var/due_at

/datum/netrun_machine_packet/New(datum/netrun_machine_service/source, datum/netrun_machine_service/recipient, operation_id)
	src.source = source
	src.recipient = recipient
	source_address = source?.resolve_node()?.address
	destination_address = recipient?.resolve_node()?.address
	operation = new(kind, "Обмен между машинами",
		source_address, destination_address, recipient?.service_id, operation_id = operation_id)
	packet_id = operation.id

/datum/netrun_machine_packet/Destroy()
	cancel_delivery()
	SSnetrun.get_machine_transport().packets -= src
	SSnetrun.get_machine_transport().interactive_packets -= src
	QDEL_NULL(operation)
	interest_route = null
	source = null
	recipient = null
	return ..()

/datum/netrun_machine_packet/proc/capture_payload()
	return

/datum/netrun_machine_packet/proc/send()
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	if(finishing || delivery_queued || timer_id || (src in transport.packets))
		return FALSE
	if(length(transport.packets) >= NETRUN_MAX_MACHINE_PACKETS)
		fail("очередь транспортных пакетов переполнена")
		return FALSE
	var/datum/netrun_route/route = transport.route(source, recipient, communication_policy(), communication_frequency())
	if(!route)
		qdel(route)
		fail("нет сетевого маршрута")
		return FALSE
	// Rejected admissions/routes must not serialize a payload that never left.
	capture_payload()
	transport.packets |= src
	var/delay = clamp(route.latency * NETRUN_MACHINE_LATENCY_SCALE, 0, NETRUN_MACHINE_MAX_LATENCY)
	// Scaled local hops are shorter than one representable world tick. Admit
	// them asynchronously to MC directly instead of adding a timer tick and a
	// second dispatch tick at every native telecomms stage.
	if(delay < world.tick_lag)
		delay = 0
	operation.queued(route.hops, delay, FALSE)
	transport.record_flow(source, recipient, operation)
	var/mob/user = interest_user()
	var/mob/camera/netrun_entity/entity = user
	if(user?.client || (istype(entity) && entity.dive_link?.body?.client))
		interest_route = route.hops.Copy()
		transport.interactive_packets |= src
		SSnetrun.retain_route_interest(interest_route, world.time + NETRUN_NODE_INTEREST_LEASE)
	sent_at = world.time
	due_at = world.time + delay
	qdel(route)
	return schedule_delivery(delay)

/datum/netrun_machine_packet/can_queue_delivery()
	return !finishing

/// Arbitrary data never opts into communication-only forwarding.
/datum/netrun_machine_packet/proc/communication_policy()
	return FALSE

/datum/netrun_machine_packet/proc/communication_frequency()
	return null

/datum/netrun_machine_packet/deliver()
	set waitfor = FALSE
	cancel_delivery()
	if(finishing)
		return
	var/datum/netrun_route/route = SSnetrun.get_machine_transport().route(source, recipient, communication_policy(), communication_frequency())
	if(!route)
		fail("маршрут разорван")
		return
	finishing = TRUE
	SSnetrun.get_machine_transport().trace_delivery(src)
	destination_address = route.hops[length(route.hops)]
	capture_payload()
	operation.running()
	operation.receive(route.hops)
	qdel(route)
	execute()
	if(!operation.finished)
		operation.finish("completed")
	qdel(src)

/datum/netrun_machine_packet/proc/execute()
	return

/datum/netrun_machine_packet/proc/interest_user()
	return null

/datum/netrun_machine_packet/proc/journal(address, phase, reason)
	operation.journal(address, phase, reason)

/datum/netrun_machine_packet/proc/fail(reason)
	if(finishing)
		return
	finishing = TRUE
	operation.finish(operation.sent ? "cancelled" : "rejected", reason, source_address)
	qdel(src)

/datum/netrun_machine_packet/data
	var/datum/netrun_machine_message/message
	var/recipient_tag
	var/replacement_key
	var/capture_dirty = TRUE

/datum/netrun_machine_packet/data/New(datum/netrun_machine_service/source, datum/netrun_machine_service/recipient, datum/netrun_machine_message/message)
	..(source, recipient, message.correlation_id)
	src.message = message
	message.source = source
	message.recipient = recipient
	message.correlation_id = operation.operation_id
	recipient_tag = recipient?.service_tag()

/datum/netrun_machine_packet/data/capture_payload()
	if(!capture_dirty)
		return
	operation.capture(message.payload)
	capture_dirty = FALSE

/datum/netrun_machine_packet/data/Destroy()
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	if(replacement_key && transport.replaceable_packets[replacement_key] == src)
		transport.replaceable_packets -= replacement_key
	replacement_key = null
	QDEL_NULL(message)
	return ..()

/datum/netrun_machine_packet/data/interest_user()
	return message.user_ref?.resolve()

/datum/netrun_machine_packet/data/delivery_priority()
	return message.delivery_priority()

/datum/netrun_machine_packet/data/communication_policy()
	return netrun_communication_policy(source, recipient?.service_id) && (istype(message, /datum/netrun_machine_message/telecomms) || istype(message, /datum/netrun_machine_message/communications))

/datum/netrun_machine_packet/data/communication_frequency()
	var/datum/netrun_machine_message/telecomms/packet = message
	return istype(packet) ? packet.signal?.frequency : null

/datum/netrun_machine_packet/data/execute()
	if(recipient.matches(source, recipient_tag) && recipient.accepts(message) && recipient.receive(message))
		operation.finish("completed")
		message.delivered(recipient)
	else
		var/reason = recipient.rejection_reason(message)
		operation.finish("rejected", reason)
		message.failed(reason)

/datum/netrun_machine_packet/data/fail(reason)
	if(!finishing)
		message?.failed(reason)
	return ..()
