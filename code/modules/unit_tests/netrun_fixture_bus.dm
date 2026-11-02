/// A hermetic source of supplied remote events for native adapter tests.
/// The fixture declares every scoped star endpoint connected; it never searches geometry,
/// chooses routes, computes latency, or substitutes native effect authorization.
/datum/netrun_external_fixture/scene_bus
	/// Scene lifetime and native graph are owned by the route fixture.
	var/datum/weakref/scene_ref
	/// Paused production/outer fixture connection is restored before this bus closes.
	var/datum/netrun_external_core/previous_client
	/// Frozen invocation rows preserve replay fingerprints across yielding callbacks.
	var/list/invocation_rows = list()
	/// Reentrant native callbacks may enqueue work for the following worker pass.
	var/pumping = FALSE
	/// Тест может остановить автоматическую подачу и явно задать очередной remote event.
	var/auto_pump = TRUE
	var/discovery_calls = 0

/datum/netrun_external_fixture/scene_bus/New(datum/netrun_route_scene/scene)
	scene_ref = WEAKREF(scene)
	previous_client = SSnetrun.external_core
	worker = new
	worker.external_configuration_checked = TRUE
	worker.external_mode_checked = TRUE
	worker.external_mode = "external"
	client = new /datum/netrun_external_core/fixture/scene_bus(worker)
	var/datum/netrun_external_core/fixture/scene_bus/bus_client = client
	bus_client.bus_ref = WEAKREF(src)
	worker.external_core = client
	worker.topology = scene.fixture_graph
	client.world_epoch = "scene-world-[REF(src)]"
	client.engine_epoch = "scene-engine"
	client.binding_epoch = "scene-binding-[REF(src)]"
	client.state = "ready"
	client.ready = TRUE
	executor = new /datum/netrun_external_effects/machines/queries/scene_bus(worker)
	var/datum/netrun_external_effects/machines/queries/scene_bus/bus_executor = executor
	bus_executor.bus_ref = WEAKREF(src)
	bus_executor.backbone_applied = !SSnetworks.station_network.setting_disabled
	client.effects = executor
	SSnetrun.external_core = client

/datum/netrun_external_fixture/scene_bus/Destroy()
	var/restore_binding = SSnetrun.external_core == client
	// Test allocations may be disposed in creation order. Unlink this scope from any inner scope.
	var/datum/netrun_external_core/fixture/scene_bus/current = SSnetrun.external_core
	for(var/depth in 1 to 64)
		if(!istype(current) || current == client)
			break
		var/datum/netrun_external_fixture/scene_bus/inner = current.bus_ref?.resolve()
		if(!inner)
			break
		if(inner.previous_client == client)
			inner.previous_client = previous_client
			break
		current = inner.previous_client
	client?.close("fixture_cleanup")
	if(restore_binding)
		SSnetrun.external_core = QDELETED(previous_client) ? null : previous_client
	worker.topology = null
	scene_ref = null
	invocation_rows.Cut()
	. = ..()
	previous_client = null

/// A fake remote ACK goes through the production decoder and its fact-prefix gate.
/datum/netrun_external_fixture/scene_bus/proc/ack_facts()
	if(client.pending_frame)
		ack_input()
	if(client.send_journal(128, FALSE))
		ack_input()
	return client.infrastructure_facts_ready()

/datum/netrun_external_fixture/scene_bus/proc/ack_input()
	if(!client.pending_frame)
		return TRUE
	var/body = netrun_external_json_object(list("kind" = json_encode("output"), "world_epoch" = json_encode(client.world_epoch), "engine_epoch" = json_encode(client.engine_epoch), "binding_epoch" = json_encode(client.binding_epoch), "output_sequence" = json_encode(netrun_external_decimal_next(client.ack_output_sequence)), "applied_sequence" = json_encode(client.input_sequence), "results" = "\[\]"))
	return client.process_frame(body)

/// Exact admitted native contexts remain inspectable without recreating machine_packet.
/datum/netrun_external_fixture/scene_bus/proc/pending_contexts(datum/netrun_machine_service/source_service, datum/netrun_machine_service/target_service)
	var/list/result = list()
	for(var/id in executor.pending)
		var/datum/netrun_external_request_context/context = executor.pending[id]
		if((!source_service || context.source_ref?.resolve() == source_service) && (!target_service || context.destination_ref?.resolve() == target_service))
			result += context
	return result

/// Supply a frozen invocation and its terminal event through the actual native dispatcher.
/datum/netrun_external_fixture/scene_bus/deliver_context(datum/netrun_external_request_context/context)
	if(QDELETED(context) || !ack_facts())
		return FALSE
	var/request_id = context.request_id
	var/list/row = invocation_rows[request_id]
	if(!row)
		row = invocation(context)
		invocation_rows[request_id] = row
	if(!executor.process_result(client, row) || context.executing || !context.invocation?.result_json)
		return FALSE
	var/list/result = json_decode(context.invocation.result_json)
	var/success = result["success"]
	executor.process_result(client, completion(request_id, success ? "completed" : "failed", result["code"]))
	invocation_rows -= request_id
	return success

/// The declared service directory supplies candidate identities; production domain filtering follows.
/datum/netrun_external_fixture/scene_bus/proc/deliver_discovery(datum/netrun_external_query_command/command)
	var/datum/netrun_machine_resolution/external/query = command.consumer?.resolve()
	var/datum/netrun_route_scene/scene = scene_ref?.resolve()
	if(QDELETED(query) || !scene)
		return FALSE
	discovery_calls++
	var/list/keys = list()
	var/list/bucket = SSnetrun.get_machine_transport().by_id[query.destination_id]
	for(var/datum/netrun_machine_service/service as anything in bucket)
		var/datum/component/netrun_node/node = service.resolve_node()
		if(QDELETED(node) || scene.fixture_graph.nodes[node.address] != node || (!isnull(query.recipient_tag) && service.service_tag() != query.recipient_tag))
			continue
		var/list/key = client.service_key(service)
		if(key)
			keys += list(wire_key(key, "service_id"))
	return supply_discovery(query, keys)

/// Wire identities supplied by a test enter the real bounded decoder and native continuation.
/datum/netrun_external_fixture/scene_bus/proc/supply_discovery(datum/netrun_machine_resolution/external/query, list/keys, code = "completed")
	var/datum/netrun_external_effects/machines/queries/queries = executor
	for(var/offset = 1, offset <= max(1, length(keys)), offset += 64)
		var/complete = offset + 64 > length(keys)
		var/list/page = keys.Copy(offset, min(offset + 64, length(keys) + 1))
		if(!queries.process_result(client, list("kind" = "discovery_page", "binding_epoch" = client.binding_epoch, "request_id" = query.external_request_id, "candidates" = page, "complete" = complete, "code" = complete ? code : "page")))
			return FALSE
	return TRUE

/// One native worker tick supplies a bounded batch, keeping startup and replies asynchronous.
/datum/netrun_external_fixture/scene_bus/proc/pump()
	if(pumping || QDELETED(client) || !client.ready)
		return
	pumping = TRUE
	ack_facts()
	var/datum/netrun_external_effects/machines/queries/queries = executor
	queries.backbone_pending = FALSE
	queries.backbone_applied = !SSnetworks.station_network.setting_disabled
	var/work = 0
	for(var/datum/netrun_external_query_command/command as anything in queries.query_commands.Copy())
		if(work++ >= 16)
			break
		if(command.kind == "service_discover")
			deliver_discovery(command)
		if(command in queries.query_commands)
			queries.query_commands -= command
			qdel(command)
	work = 0
	for(var/datum/netrun_external_command/command as anything in executor.request_commands.Copy())
		if(work++ >= 16)
			break
		executor.request_commands -= command
		qdel(command)
	work = 0
	for(var/datum/netrun_external_request_context/context as anything in pending_contexts())
		if(work++ >= 16)
			break
		deliver_context(context)
	// The fake remote acknowledges native results after their real terminal callback.
	for(var/datum/netrun_external_command/command as anything in executor.control_commands.Copy())
		executor.control_commands -= command
		var/datum/netrun_external_invocation/invocation = command.invocation
		if(invocation)
			invocation.result_queued = FALSE
			command.invocation = null
		qdel(command)
		executor.try_retire_invocation(invocation)
	pumping = FALSE

/// Only IPC is replaced. Source registries, codecs, raw revisions and native effects stay real.
/datum/netrun_external_core/fixture/scene_bus
	var/datum/weakref/bus_ref

/datum/netrun_external_core/fixture/scene_bus/tick(max_records = 32)
	var/datum/netrun_external_fixture/scene_bus/bus = bus_ref?.resolve()
	if(bus?.auto_pump)
		bus.pump()

/// Read-only queries receive the fixture's already declared graph rows, never another routing engine.
/datum/netrun_external_effects/machines/queries/scene_bus
	var/datum/weakref/bus_ref
	projection_stream_mode = FALSE

/// Сцена импортирует свои строки отдельно; production exporter продолжает журналировать native revisions.
/datum/netrun_external_effects/machines/queries/scene_bus/invalidate_projection(reason = "changed", structural = TRUE, datum/component/netrun_node/node = null, removed = FALSE)
	return

/datum/netrun_external_effects/machines/queries/scene_bus/projection_tree(datum/netrun_external_core/client, datum/component/netrun_node/source, mode = "discovery")
	return owner?.topology ? owner.topology.route_snapshot(source, TRUE) : new /datum/netrun_path_tree

/datum/netrun_external_effects/machines/queries/scene_bus/projection_watch(datum/netrun_external_core/client, datum/component/netrun_node/source, datum/netrun_console/console, mode = "discovery")
	return owner?.topology ? owner.topology.route_snapshot(source, TRUE) : new /datum/netrun_path_tree

/datum/netrun_external_effects/machines/queries/scene_bus/projection_anchor(datum/netrun_external_core/client, datum/netrun_console/console)
	var/datum/netrun_external_fixture/scene_bus/bus = bus_ref?.resolve()
	var/datum/netrun_route_scene/scene = bus?.scene_ref?.resolve()
	return scene?.fixture_anchor

/datum/netrun_external_effects/machines/queries/scene_bus/projection_ready(datum/netrun_external_core/client)
	return client?.ready && owner?.topology && !owner.topology.dirty

/// Research/security tests can inspect supplied requests while ordinary adapter startup uses the worker pump.
/datum/netrun_route_scene/proc/pending_contexts(datum/netrun_machine_service/source_service, datum/netrun_machine_service/target_service)
	return bus?.pending_contexts(source_service, target_service) || list()

/datum/netrun_route_scene/proc/deliver_context(datum/netrun_external_request_context/context)
	return bus?.deliver_context(context) || FALSE

/// Read-only catalog retrieval is asynchronous in production; tests wait for its real native continuation.
/datum/unit_test/proc/netrun_wait_catalog(datum/netrun_machine_service/source, destination_id, recipient_tag, timeout = 5 SECONDS)
	var/deadline = world.time + timeout
	var/list/targets = source.resolve(destination_id, recipient_tag)
	while(!length(targets) && world.time < deadline)
		sleep(world.tick_lag)
		targets = source.resolve(destination_id, recipient_tag)
	return targets
