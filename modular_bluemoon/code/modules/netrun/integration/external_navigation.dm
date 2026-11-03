/// Read-only navigation does not register an EntityWorld actor or import HP/status.
/// The legacy movement/combat owner remains responsible for executing each hop.
/datum/netrun_external_effects/machines/queries
	var/list/navigation_pending = list()

/datum/netrun_external_core/proc/request_entity_navigation(datum/netrun_entity_navigation/navigation, datum/component/netrun_node/target, manual_move = FALSE, direct_only = FALSE, relay_only = FALSE)
	var/datum/netrun_external_effects/machines/queries/executor = effects
	var/mob/camera/netrun_entity/entity = navigation?.owner
	if(!ready || !istype(executor) || executor.closed || executor.query_disconnecting || QDELETED(entity) || QDELETED(entity.host_node) || QDELETED(target) || navigation.external_request)
		return null
	var/source_json = entity_access_node_json(entity.host_node)
	var/destination_json = entity_access_node_json(target)
	if(!source_json || !destination_json)
		return null
	var/datum/netrun_external_navigation_request/request = new(src, navigation, json_decode(source_json), json_decode(destination_json))
	request.manual_move = manual_move
	request.direct_only = direct_only
	request.relay_only = relay_only
	navigation.external_request = request
	executor.navigation_pending += request
	request.prepare()
	return request

/// One pending intent. Only completed Core pages may become a route; no local search fallback.
/datum/netrun_external_navigation_request
	var/datum/weakref/client_ref
	var/datum/weakref/navigation_ref
	var/binding
	var/operation_generation
	var/list/actor_key
	var/actor_revision
	var/list/source_key
	var/list/destination_key
	var/datum/weakref/destination_ref
	var/datum/weakref/pursuit_target_ref
	var/request_id
	var/access_hash
	var/fact_tail
	var/graph_version
	var/graph_input_sequence
	var/availability_version
	var/next_page = "1"
	var/list/nodes = list()
	var/list/seen_nodes = list()
	var/maximum_nodes
	var/complete = FALSE
	var/manual_move = FALSE
	var/direct_only = FALSE
	var/relay_only = FALSE
	var/completion_timer
	var/datum/netrun_external_entity_access_cursor/access_cursor

/datum/netrun_external_navigation_request/New(datum/netrun_external_core/client, datum/netrun_entity_navigation/navigation, list/source, list/destination)
	client_ref = WEAKREF(client)
	navigation_ref = WEAKREF(navigation)
	binding = client.binding_epoch
	operation_generation = navigation.generation
	actor_revision = navigation.external_revision
	actor_key = list("actor_id" = client.entity_access_identity(navigation.owner), "generation" = "1")
	source_key = source.Copy()
	destination_key = destination.Copy()
	var/datum/component/netrun_node/target = client.resolve_node(destination_key["node_id"], destination_key["generation"])
	destination_ref = target ? WEAKREF(target) : null
	pursuit_target_ref = navigation.pursuit_target_ref
	maximum_nodes = length(client.owner.nodes_by_address)

/datum/netrun_external_navigation_request/Destroy()
	if(completion_timer)
		deltimer(completion_timer)
	QDEL_NULL(access_cursor)
	var/datum/netrun_entity_navigation/navigation = navigation_ref?.resolve()
	if(navigation?.external_request == src)
		navigation.external_request = null
	var/datum/netrun_external_core/client = client_ref?.resolve()
	var/datum/netrun_external_effects/machines/queries/executor = client?.effects
	if(istype(executor))
		executor.navigation_pending -= src
		if(binding == client.binding_epoch && request_id)
			executor.forget_query(request_id, "entity_navigation_cancel")
	client_ref = null
	navigation_ref = null
	destination_ref = null
	pursuit_target_ref = null
	nodes.Cut()
	seen_nodes.Cut()
	return ..()

/// Constant-time identity/residence gate, repeated after every cooperative export.
/datum/netrun_external_navigation_request/proc/current()
	var/datum/netrun_external_core/client = client_ref?.resolve()
	var/datum/netrun_entity_navigation/navigation = navigation_ref?.resolve()
	var/mob/camera/netrun_entity/entity = navigation?.owner
	if(QDELETED(src) || !client?.ready || binding != client.binding_epoch || navigation?.external_request != src || navigation.generation != operation_generation || navigation.external_revision != actor_revision || QDELETED(entity) || QDELETED(entity.console) || QDELETED(entity.host_node))
		return FALSE
	var/datum/component/netrun_node/target_node = client.resolve_node(destination_key?["node_id"], destination_key?["generation"])
	if(!target_node || destination_ref?.resolve() != target_node || entity.host_node != client.resolve_node(source_key?["node_id"], source_key?["generation"]))
		return FALSE
	if(pursuit_target_ref)
		var/mob/camera/netrun_entity/target = pursuit_target_ref.resolve()
		if(QDELETED(target) || navigation.pursuit_target_ref != pursuit_target_ref || target.host_node != target_node)
			return FALSE
	return TRUE

/// Cancellation owns the export cursor too, so replaced UI intents do not retain station scans.
/datum/netrun_external_navigation_request/proc/export_access()
	if(!current())
		return null
	var/datum/netrun_external_core/client = client_ref.resolve()
	var/datum/netrun_entity_navigation/navigation = navigation_ref.resolve()
	access_cursor = new(client, navigation.owner.console)
	var/datum/netrun_external_entity_access_cursor/cursor = access_cursor
	while(current() && !QDELETED(cursor) && !cursor.complete)
		cursor.advance(32)
		if(!cursor.complete)
			CHECK_TICK
			sleep(0)
	var/result = current() && !QDELETED(cursor) && cursor.complete && !cursor.error ? cursor.result_json : null
	if(!QDELETED(src) && access_cursor == cursor)
		QDEL_NULL(access_cursor)
	return result

/// Export can yield; it never runs inside UI dispatch or the IPC reader/writer.
/datum/netrun_external_navigation_request/proc/prepare()
	set waitfor = FALSE
	sleep(0)
	if(!current())
		reject("navigation_changed")
		return
	var/datum/netrun_external_core/client = client_ref.resolve()
	var/raw_access = export_access()
	if(!current() || !raw_access)
		reject("navigation_changed")
		return
	var/datum/netrun_external_effects/machines/queries/executor = client.effects
	request_id = executor.new_query_id("navigation")
	access_hash = md5(raw_access)
	fact_tail = client.fact_tail
	var/raw = netrun_external_json_object(list("kind" = json_encode("entity_navigation_query"), "request_id" = json_encode(request_id), "actor" = netrun_external_entity_actor_json(actor_key), "actor_revision" = json_encode(actor_revision), "source" = json_encode(source_key), "destination" = json_encode(destination_key), "access" = raw_access))
	if(!request_id || !executor.enqueue_query("entity_navigation_query", raw, src))
		reject("navigation_pressure")

/datum/netrun_external_navigation_request/proc/reject(code)
	if(QDELETED(src))
		return
	var/datum/netrun_entity_navigation/navigation = navigation_ref?.resolve()
	if(navigation?.external_request == src)
		navigation.external_request = null
		navigation.cancel()
		navigation.on_external_navigation_failed(src, code)
		navigation.owner?.console?.log_line("Автопроход остановлен: Core не подтвердил актуальный маршрут ([netrun_external_safe_code(code, "navigation_failed")]).", "bad")
	qdel(src)

/// Decoder stages at most one bounded page. Native route work starts in a later timer callback.
/datum/netrun_external_effects/machines/queries/proc/process_entity_navigation(datum/netrun_external_core/client, list/result)
	if(length(result) != 14 || !known_query_id(result["request_id"]))
		return FALSE
	var/datum/netrun_external_navigation_request/request = get_query_consumer(result["request_id"])
	if(!istype(request))
		return TRUE
	if(request.complete || request.binding != client.binding_epoch || !netrun_external_entity_actor_same(result["actor"], request.actor_key) || result["actor_revision"] != request.actor_revision || !request.same_node(result["source"], request.source_key) || !request.same_node(result["destination"], request.destination_key))
		return FALSE
	for(var/field in list("graph_version", "graph_input_sequence", "availability_version", "page_index"))
		if(!netrun_external_valid_decimal(result[field], field != "page_index"))
			return FALSE
	var/list/page_nodes = result["nodes"]
	if(!islist(page_nodes) || length(page_nodes) > 64 || !(result["complete"] == TRUE || result["complete"] == FALSE) || !istext(result["code"]))
		return FALSE
	var/success = (result["code"] in list("page", "completed"))
	if(!success)
		// Core may revoke an unread success page; its terminal failure can skip an index.
		if(!result["complete"] || length(page_nodes) || netrun_external_decimal_compare(result["page_index"], request.next_page) < 0)
			return FALSE
		request.complete = TRUE
		request.nodes.Cut()
		request.completion_timer = addtimer(CALLBACK(request, TYPE_PROC_REF(/datum/netrun_external_navigation_request, reject), result["code"]), 1, TIMER_STOPPABLE | TIMER_DELETE_ME)
		return TRUE
	if(result["page_index"] != request.next_page || result["complete"] != (result["code"] == "completed") || result["graph_version"] == "0")
		return FALSE
	if(request.graph_version && (request.graph_version != result["graph_version"] || request.graph_input_sequence != result["graph_input_sequence"] || request.availability_version != result["availability_version"]))
		return FALSE
	for(var/list/key as anything in page_nodes)
		if(!islist(key) || length(key) != 2 || !istext(key["node_id"]) || !length(key["node_id"]) || length(key["node_id"]) > 128 || !netrun_external_valid_decimal(key["generation"]))
			return FALSE
	if(length(request.nodes) + length(page_nodes) > request.maximum_nodes)
		return FALSE
	var/list/page_seen = list()
	for(var/list/key as anything in page_nodes)
		var/token = json_encode(list(key["node_id"], key["generation"]))
		if(request.seen_nodes[token] || page_seen[token])
			return FALSE
		page_seen[token] = TRUE
	request.graph_version = result["graph_version"]
	request.graph_input_sequence = result["graph_input_sequence"]
	request.availability_version = result["availability_version"]
	request.next_page = netrun_external_decimal_next(request.next_page)
	for(var/list/key as anything in page_nodes)
		request.nodes += list(key.Copy())
		request.seen_nodes[json_encode(list(key["node_id"], key["generation"]))] = TRUE
	if(result["complete"])
		request.complete = TRUE
		request.completion_timer = addtimer(CALLBACK(request, TYPE_PROC_REF(/datum/netrun_external_navigation_request, finish)), 1, TIMER_STOPPABLE | TIMER_DELETE_ME)
	return TRUE

/datum/netrun_external_effects/machines/queries/proc/observe_entity_navigation(datum/netrun_external_core/client, list/result, datum/netrun_external_query_command/command)
	var/list/admission = result["admission"]
	var/datum/netrun_external_navigation_request/request = command.consumer?.resolve()
	if(istype(request) && !(admission?["status"] in list("accepted", "duplicate")))
		request.complete = TRUE
		request.completion_timer = addtimer(CALLBACK(request, TYPE_PROC_REF(/datum/netrun_external_navigation_request, reject), admission?["code"]), 1, TIMER_STOPPABLE | TIMER_DELETE_ME)

/// Re-export raw authority off the decoder stack; stale ACL or topology discards the whole path.
/datum/netrun_external_navigation_request/proc/finish()
	set waitfor = FALSE
	completion_timer = null
	if(!current())
		reject("navigation_changed")
		return
	var/datum/netrun_external_core/client = client_ref.resolve()
	var/datum/netrun_entity_navigation/navigation = navigation_ref.resolve()
	var/datum/netrun_external_effects/machines/queries/executor = client.effects
	var/list/path = list()
	for(var/list/key as anything in nodes)
		var/datum/component/netrun_node/node = client.resolve_node(key["node_id"], key["generation"])
		if(!node || same_node(key, source_key))
			reject("stale_endpoint")
			return
		path += node.address
		if(length(path) % 32 == 0)
			CHECK_TICK
			sleep(0)
			if(!current())
				reject("navigation_changed")
				return
	if(!current())
		reject("navigation_changed")
		return
	var/raw_access = export_access()
	var/list/last = length(nodes) ? nodes[length(nodes)] : null
	if(!current() || !raw_access || md5(raw_access) != access_hash || fact_tail != client.fact_tail || graph_version != executor.projection_graph_version || graph_input_sequence != executor.projection_input_sequence || availability_version != executor.projection_availability || !same_node(last, destination_key))
		reject("navigation_changed")
		return
	if(direct_only && length(path) != 1)
		reject("direct_hop_unavailable")
		return
	executor.forget_query(request_id)
	navigation.apply_external_route(src, path)
	qdel(src)

/datum/netrun_external_navigation_request/proc/same_node(list/first, list/second)
	return islist(first) && length(first) == 2 && islist(second) && first["node_id"] == second["node_id"] && first["generation"] == second["generation"]

/datum/netrun_external_effects/machines/queries/proc/disconnect_entity_navigation()
	for(var/datum/netrun_external_navigation_request/request as anything in navigation_pending.Copy())
		request.reject("navigation_disconnected")
	navigation_pending.Cut()
