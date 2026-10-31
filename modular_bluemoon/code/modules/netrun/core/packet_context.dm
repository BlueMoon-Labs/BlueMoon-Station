/// A delivery owns its metadata. Consoles retain bounded value snapshots, never live packets.
/datum/controller/subsystem/netrun
	var/packet_context_serial = 0
	/// One global ring, never one payload copy per routing hop or station node.
	var/list/packet_captures = list()

/// Bounded primitive wire preview. Datums, icons and native object references are not retained.
/proc/netrun_packet_preview(value, list/budget, depth = 0)
	if(budget[1]-- <= 0)
		budget[2] = TRUE
		return "<limit>"
	if(islist(value))
		if(depth >= 4)
			budget[2] = TRUE
			return "<depth limit>"
		var/list/input = value
		var/list/output = list()
		if(length(input) > 32)
			budget[2] = TRUE
		for(var/i in 1 to min(length(input), 32))
			if(budget[1] <= 0)
				budget[2] = TRUE
				break
			var/key = input[i]
			var/associative = istext(key) && !isnull(input[key])
			var/entry = associative ? input[key] : key
			var/preview
			if(islist(entry))
				preview = netrun_packet_preview(entry, budget, depth + 1)
			else
				// Scalar fields need no recursive proc call. Preserve the same
				// shared item/character budget and never retain native references.
				budget[1]--
				if(istext(entry))
					if(length_char(entry) > 512)
						budget[2] = TRUE
					preview = copytext_char(entry, 1, 513)
				else if(isnum(entry) || isnull(entry))
					preview = entry
				else
					preview = "<native value>"
			if(associative)
				output[copytext_char(key, 1, 129)] = preview
			else
				output += list(preview)
		return output
	if(istext(value))
		if(length_char(value) > 512)
			budget[2] = TRUE
		return copytext_char(value, 1, 513)
	if(isnum(value) || isnull(value))
		return value
	return "<native value>"

/datum/netrun_packet_context
	var/id
	var/operation_id
	var/nonce
	var/kind
	var/label
	var/from_address
	var/to_address
	var/service_id
	var/phase = "queued"
	var/reason
	var/result
	var/list/headers
	var/started_at
	var/updated_at
	/// Replaced atomically; journal entries may share this immutable address snapshot.
	var/list/route = list()
	var/datum/weakref/console_ref
	var/sent = FALSE
	var/received = FALSE
	var/finished = FALSE
	/// Transit time chosen at dispatch, deciseconds; the map animates the flight with it.
	var/eta = 0
	/// The dispatch was drawn on maps, so its outcome is drawn too.
	var/map_announced = FALSE
	/// High-volume machine traffic publishes only failures; arrival is implied by the flight.
	var/quiet_success = FALSE

/datum/netrun_packet_context/New(kind, label, from_address, to_address, service_id, datum/netrun_console/console, nonce, operation_id)
	id = "packet-[++SSnetrun.packet_context_serial]"
	src.operation_id = istext(operation_id) ? copytext_char(operation_id, 1, 129) : id
	src.kind = istext(kind) ? copytext_char(kind, 1, 65) : "request"
	src.label = istext(label) ? copytext_char(label, 1, 129) : src.kind
	src.from_address = istext(from_address) ? copytext_char(from_address, 1, 129) : null
	src.to_address = istext(to_address) ? copytext_char(to_address, 1, 129) : null
	src.service_id = istext(service_id) ? copytext_char(service_id, 1, 129) : src.kind
	if(istext(nonce) && length(nonce) <= NETRUN_INPUT_ACK_MAX_LENGTH)
		src.nonce = nonce
	if(!QDELETED(console))
		console_ref = WEAKREF(console)
	started_at = world.time
	updated_at = world.time
	headers = list("protocol" = "NETRUN/1", "content_type" = "application/netrun", "captured_chars" = 0)
	publish()

/datum/netrun_packet_context/Destroy()
	if(!finished)
		finish("cancelled", "Доставка отменена.")
	console_ref = null
	route = null
	return ..()

/datum/netrun_packet_context/proc/snapshot()
	return list("id" = id, "operation_id" = operation_id, "nonce" = nonce, "kind" = kind,
		"label" = label, "from" = from_address, "to" = to_address, "service" = service_id,
		"phase" = phase, "reason" = reason, "result" = result, "started_at" = started_at, "updated_at" = updated_at,
		"route" = route.Copy())

/datum/netrun_packet_context/proc/capture(list/payload)
	if(!islist(payload))
		return
	var/list/budget = list(96, FALSE)
	var/body = json_encode(netrun_packet_preview(payload, budget))
	var/truncated = budget[2] || length_char(body) > 4096
	body = copytext_char(body, 1, 4097)
	// Shared immutable value. Only the explicit ROOT decode command reads this ring.
	SSnetrun.packet_captures[id] = body
	if(length(SSnetrun.packet_captures) > 256)
		SSnetrun.packet_captures.Cut(1, length(SSnetrun.packet_captures) - 255)
	headers = list("protocol" = "NETRUN/1", "content_type" = "application/json", "captured_chars" = length_char(body), "truncated" = truncated)

/datum/netrun_packet_context/proc/set_result(text)
	result = istext(text) ? copytext_char(text, 1, 4097) : null

/datum/netrun_packet_context/proc/publish()
	updated_at = world.time
	var/datum/netrun_console/console = console_ref?.resolve()
	if(!QDELETED(console))
		console.record_operation(src)

/// Accept the two existing route representations without retaining the caller's lists.
/datum/netrun_packet_context/proc/set_route(list/hops)
	// Admission and delivery usually observe the same physical route. It is
	// already an immutable owned snapshot, so retain it when every hop matches.
	if(length(route) == length(hops))
		var/unchanged = TRUE
		for(var/i in 1 to length(hops))
			var/hop = hops[i]
			var/address = hop
			if(islist(hop))
				var/list/entry = hop
				if(entry["kind"] && entry["kind"] != "node")
					unchanged = FALSE
					break
				address = entry["ref"]
			if(!istext(address) || route[i] != address)
				unchanged = FALSE
				break
		if(unchanged)
			return
	var/list/addresses = list()
	for(var/hop as anything in hops)
		var/address = hop
		if(islist(hop))
			var/list/entry = hop
			if(entry["kind"] && entry["kind"] != "node")
				continue
			address = entry["ref"]
		if(istext(address))
			addresses += address
	route = addresses

/// `announce` = FALSE leaves map publication to a rate-limited owner (machine traffic).
/datum/netrun_packet_context/proc/queued(list/hops, delay = 0, announce = TRUE)
	if(finished || sent)
		return FALSE
	sent = TRUE
	set_route(hops)
	if(!from_address && length(route))
		from_address = route[1]
	eta = max(0, delay || 0)
	journal(from_address, "SEND")
	publish()
	if(announce)
		announce_flight()
	return TRUE

/// Publish the dispatch with its hops and transit time once; the result follows in finish().
/datum/netrun_packet_context/proc/announce_flight()
	if(map_announced || !sent)
		return FALSE
	map_announced = TRUE
	SSnetrun.post_packet(src, "send")
	return TRUE

/datum/netrun_packet_context/proc/running()
	if(finished)
		return FALSE
	phase = "running"
	publish()
	return TRUE

/// Only a freshly validated delivery path may produce forwarding records.
/datum/netrun_packet_context/proc/receive(list/hops)
	if(finished || received)
		return FALSE
	received = TRUE
	set_route(hops)
	for(var/i = 2; i < length(route); i++)
		journal(route[i], "FORWARD")
	journal(to_address, "RECEIVE")
	publish()
	return TRUE

/datum/netrun_packet_context/proc/journal(address, packet_phase, failure_reason)
	var/datum/component/netrun_node/node = SSnetrun.nodes_by_address[address]
	if(!QDELETED(node))
		node.add_packet_log(id, packet_phase, kind, from_address, to_address, service_id,
			failure_reason, operation_id, route, headers)

/// A terminal outcome is immutable. Completion means handling, not a promised physical effect.
/datum/netrun_packet_context/proc/finish(outcome, failure_reason, at_address)
	if(finished || !(outcome in list("completed", "rejected", "cancelled")))
		return FALSE
	finished = TRUE
	phase = outcome
	reason = istext(failure_reason) ? copytext_char(failure_reason, 1, 513) : null
	if(outcome == "completed")
		if(isnull(result))
			result = "Запрос обработан получателем."
		journal(at_address || to_address || from_address, "ACCEPT")
	else if(outcome == "rejected")
		journal(at_address || (received ? to_address : from_address), "REJECT", reason)
	else if(sent)
		journal(at_address || from_address, "DROP", reason)
	publish()
	if(map_announced && (outcome != "completed" || !quiet_success))
		SSnetrun.post_packet(src, outcome == "completed" ? "done" : "fail")
	return TRUE

/datum/netrun_console
	var/list/operation_snapshots = list()
	var/operation_revision = 0

/datum/netrun_console/proc/record_operation(datum/netrun_packet_context/operation)
	if(QDELETED(src))
		return
	for(var/i = length(operation_snapshots); i >= 1; i--)
		var/list/previous = operation_snapshots[i]
		if(previous["id"] == operation.id)
			operation_snapshots.Cut(i, i + 1)
			break
	operation_snapshots += list(operation.snapshot())
	if(length(operation_snapshots) > 32)
		operation_snapshots.Cut(1, length(operation_snapshots) - 31)
	operation_revision++
	invalidate_ui()

/// Walking/map updates must not retransmit all previously completed response bodies.
/datum/netrun_console/proc/append_operations_payload(list/data, list/session)
	if(session && !isnull(session["operation_revision"]) && session["operation_revision"] == operation_revision)
		return
	data["operations"] = operations_payload()
	if(session)
		session["operation_revision"] = operation_revision

/// operation_snapshots is an indexed list whose elements are themselves assoc lists.
/// deepCopyList() on such a container would treat each element-list as an associative
/// key (mapping it to null), turning the result into an assoc list that json_encode
/// then serializes as an object instead of an array. Copy each snapshot individually.
/datum/netrun_console/proc/operations_payload()
	var/list/payload = list()
	for(var/list/snapshot as anything in operation_snapshots)
		payload += list(deepCopyList(snapshot))
	return payload

/// Preflight failure has an operation result but never pretends to have crossed the network.
/datum/netrun_console/proc/reject_operation(datum/netrun_packet_context/operation, reason)
	operation?.finish("rejected", reason, operation.from_address)
	qdel(operation)
	return FALSE
