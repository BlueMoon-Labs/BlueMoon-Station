/// One bounded, coalesced local registry lookup per source/service/tag. Discovery
/// never creates wire packets or per-client directory replicas. APC topology is
/// authoritative, while the ordinary data packet revalidates the path at delivery.
/datum/netrun_machine_resolution
	parent_type = /datum/netrun_delivery
	delivery_kind = "service_discovery"
	var/datum/netrun_machine_service/source
	var/destination_id
	var/recipient_tag
	var/query_key
	var/list/queued = list()
	var/completed = FALSE
	var/failure_reason = "Обнаружение службы отменено"
	var/operation_id
	/// An owned registry snapshot keeps removals between slices from skipping peers.
	var/list/candidates
	var/candidate_cursor = 1
	var/target_limit = 0
	var/communications = FALSE
	var/list/resolved_targets
	var/target_cursor = 1
	var/message_attempted = FALSE

/datum/netrun_machine_resolution/New(datum/netrun_machine_service/source, destination_id, recipient_tag)
	src.source = source
	src.destination_id = destination_id
	src.recipient_tag = recipient_tag
	query_key = "[destination_id]|[recipient_tag]"
	operation_id = "discovery-[++SSnetrun.get_machine_transport().packet_serial]"
	RegisterSignal(source, COMSIG_PARENT_QDELETING, PROC_REF(source_deleted))

/datum/netrun_machine_resolution/proc/source_deleted()
	SIGNAL_HANDLER
	failure_reason = "Источник службы удалён"
	qdel(src)

/datum/netrun_machine_resolution/Destroy()
	cancel_delivery()
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	transport.waiting_resolutions -= src
	if(source?.resolutions[query_key] == src)
		source.resolutions -= query_key
	transport.queued_messages -= length(queued)
	var/list/abandoned = queued
	queued = list()
	var/already_dispatched = message_attempted
	for(var/datum/netrun_machine_message/message as anything in abandoned)
		// Copies already admitted for the head message own their own outcomes.
		if(!already_dispatched)
			message.failed(failure_reason)
		qdel(message)
		already_dispatched = FALSE
	candidates = null
	resolved_targets = null
	if(source)
		UnregisterSignal(source, COMSIG_PARENT_QDELETING)
	source = null
	return ..()

/datum/netrun_machine_resolution/proc/enqueue(datum/netrun_machine_message/message)
	if(!message.correlation_id)
		message.correlation_id = operation_id
	var/key = message.coalescing_key()
	if(!completed && !isnull(key))
		for(var/index in 1 to length(queued))
			var/datum/netrun_machine_message/previous = queued[index]
			if(previous.coalescing_key() == key)
				if(!message.can_replace(previous))
					qdel(message)
					return TRUE
				queued[index] = message
				qdel(previous)
				return TRUE
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	if(completed || length(queued) >= 64 || transport.queued_messages >= 4096)
		message.failed("Очередь обнаружения служб заполнена")
		qdel(message)
		return FALSE
	queued += message
	transport.queued_messages++
	return TRUE

/datum/netrun_machine_resolution/proc/begin()
	if(QDELETED(src) || !can_queue_delivery())
		return
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	if(!transport.is_ready())
		transport.waiting_resolutions[src] = TRUE
		return
	transport.waiting_resolutions -= src
	queue_delivery()

/datum/netrun_machine_resolution/delivery_priority()
	return NETRUN_TASK_NORMAL

/datum/netrun_machine_resolution/can_queue_delivery()
	return !completed || length(queued)

/datum/netrun_machine_resolution/deliver()
	set waitfor = FALSE
	var/slice_started = TICK_USAGE
	var/slice_time = world.time
	var/budget_ms = SSnetrun.remaining_task_budget_ms(SSnetrun.get_execution_limits().min_budget_ms)
	cancel_delivery()
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	if(!transport.is_ready())
		transport.waiting_resolutions[src] = TRUE
		return FALSE
	if(QDELETED(source) || QDELETED(source.host))
		failure_reason = "Источник службы удалён"
		qdel(src)
		return FALSE
	if(!completed)
		completed = TRUE
		// Snapshot once for the whole admitted burst. Remove this generation before
		// callbacks, so newly submitted commands own a separate lookup.
		if(source.resolutions[query_key] == src)
			source.resolutions -= query_key
		var/list/bucket = source.discovery_candidates(destination_id, recipient_tag)
		candidates = bucket ? bucket.Copy() : list()
		resolved_targets = list()
		communications = netrun_communication_policy(source, destination_id)
		target_limit = source.discovery_target_limit(destination_id)
	if(candidates)
		var/work = 0
		while(candidate_cursor <= length(candidates) && work++ < 8)
			var/datum/netrun_machine_service/candidate = candidates[candidate_cursor++]
			var/eligible = transport.discoverable(source, candidate, recipient_tag, communications)
			// Live binding/availability callbacks may delete this producer mid-lookup.
			if(QDELETED(src))
				return FALSE
			if(eligible)
				resolved_targets += candidate
				if(target_limit > 0 && length(resolved_targets) >= target_limit)
					candidate_cursor = length(candidates) + 1
					break
			if(world.time != slice_time || TICK_DELTA_TO_MS(TICK_USAGE - slice_started) >= budget_ms)
				break
		if(candidate_cursor <= length(candidates))
			queue_delivery()
			return FALSE
		candidates = null
		resolved_targets = source.select_targets(destination_id, resolved_targets)
		if(QDELETED(src))
			return FALSE
		if(world.time != slice_time || TICK_DELTA_TO_MS(TICK_USAGE - slice_started) >= budget_ms)
			queue_delivery()
			return FALSE
	// Bound both command bursts and broadcast fanout. Originals remain owned and
	// counted until consumed; one packet admission is an indivisible routing step.
	// Cheap local fanout may share a slice, but never outlive lookup's remaining
	// CPU allowance or a native callback yielding into another world tick.
	var/work = 0
	while(length(queued) && work++ < 8)
		if(QDELETED(source))
			failure_reason = "Источник службы удалён"
			qdel(src)
			return FALSE
		var/datum/netrun_machine_message/message = queued[1]
		if(target_cursor <= length(resolved_targets))
			var/datum/netrun_machine_service/target = resolved_targets[target_cursor++]
			var/matches = !QDELETED(target) && target.matches(source, recipient_tag)
			if(QDELETED(src))
				return FALSE
			if(matches && !QDELETED(target))
				if(target_cursor > length(resolved_targets))
					// Transfer the owned original to the last recipient. Earlier
					// recipients retain independent copies; a unicast needs none.
					queued.Cut(1, 2)
					transport.queued_messages--
					target_cursor = 1
					message_attempted = FALSE
					source.send_to(target, message)
				else
					message_attempted = TRUE
					source.send_to(target, message.copy())
		else
			queued.Cut(1, 2)
			transport.queued_messages--
			if(!message_attempted)
				message.failed("Служба недоступна по сети APC")
			qdel(message)
			if(QDELETED(src))
				return FALSE
			target_cursor = 1
			message_attempted = FALSE
		if(QDELETED(src))
			return FALSE
		if(world.time != slice_time || TICK_DELTA_TO_MS(TICK_USAGE - slice_started) >= budget_ms)
			break
	if(length(queued))
		queue_delivery()
		return FALSE
	qdel(src)
	return TRUE

/datum/netrun_task/service_discovery
	parent_type = /datum/netrun_task/delivery
	kind = "service_discovery"
