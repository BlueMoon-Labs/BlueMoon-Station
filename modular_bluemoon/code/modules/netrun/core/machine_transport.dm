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

/// Явный opt-in заменяемого состояния выбирает отдельный idempotent wire contract.
/datum/netrun_machine_message/proc/transport_operation()
	return isnull(coalescing_key()) ? "message" : "state"

/// Необязательная положительная decimal revision для C#; игровые команды возвращают null.
/datum/netrun_machine_message/proc/transport_revision()
	return null

/// Replaceable state may carry a domain revision. A delayed older producer must
/// not discard newer state already waiting in discovery or on the wire.
/datum/netrun_machine_message/proc/can_replace(datum/netrun_machine_message/previous)
	return TRUE

/// Replaceable telemetry yields to ordinary traffic. An actor reference is not
/// evidence of explicit input: radio speech and automated notices also have one.
/datum/netrun_machine_message/proc/delivery_priority()
	return isnull(coalescing_key()) ? NETRUN_TASK_NORMAL : NETRUN_TASK_BACKGROUND

/// Core owns admission, coalescing, latency and routing. Native callbacks retain the owned message.
/datum/netrun_machine_transport/proc/dispatch(datum/netrun_machine_service/source, datum/netrun_machine_service/target, datum/netrun_machine_message/message)
	if(QDELETED(message))
		return FALSE
	var/datum/netrun_external_effects/machines/executor = SSnetrun.external_core?.effects
	if(!SSnetrun.external_core?.ready || !istype(executor))
		message.failed("внешнее сетевое ядро недоступно")
		qdel(message)
		return FALSE
	return executor.dispatch(source, target, message)
