/// Hermetic proxy слушает только движения уже импортированных fixture nodes, не всю станцию.
/datum/component/netrun_node
	/// Explicit projection tests temporarily own the imported binding, independently of the surrounding scene.
	var/datum/weakref/netrun_projection_fixture_owner

/datum/netrun_topology/external/projection_fixture
	/// Weak executor отделяет fixture от глобального SSnetrun.
	var/datum/weakref/fixture_executor

/datum/netrun_topology/external/projection_fixture/New()
	RegisterSignal(SSnetrun, COMSIG_NETRUN_NODE_MOVED, PROC_REF(on_node_moved))

/datum/netrun_topology/external/projection_fixture/on_node_moved(datum/source, datum/component/netrun_node/node, turf/old_turf, turf/new_turf)
	if(nodes[node.address] == node && old_turf != new_turf)
		var/datum/netrun_external_effects/machines/queries/executor = fixture_executor?.resolve()
		if(executor?.projection_stream_mode)
			executor.invalidate_projection("movement", TRUE, node)
		else
			invalidate()

/datum/netrun_topology/external/projection_fixture/invalidate()
	dirty = TRUE
	var/datum/netrun_external_effects/machines/queries/executor = fixture_executor?.resolve()
	executor?.invalidate_projection()

/// Console position изменяется без создания network node, чтобы проверить point-query stale-context guard.
/datum/netrun_console/projection_fixture
	/// Единственный fixture turf; production cache сам turf не удерживает.
	var/turf/projection_position

/datum/netrun_console/projection_fixture/physical_turf()
	return projection_position

/// Реальные native nodes и fake IPC; все изменённые LAN/binding поля восстанавливаются при cleanup.
/datum/netrun_external_projection_fixture
	/// Изолированный subsystem не регистрируется в MC и не читает ENV/token.
	var/datum/controller/subsystem/netrun/external_fixture/worker
	/// Настоящие identity maps/codec gate, единственная подмена — native bridge.
	var/datum/netrun_external_core/fixture/client
	/// Production dispatcher и projection handlers без mock вычисления маршрутов.
	var/datum/netrun_external_effects/machines/queries/executor
	/// Imported topology принадлежит только этому fixture worker.
	var/datum/netrun_topology/external/projection_fixture/graph
	/// Node → прежние network/anchor/metadata, чтобы fixture не менял соседние тесты.
	var/list/originals = list()
	/// Callback перемещения выполняется один раз внутри notify slice.
	var/turf/move_destination
	var/moved = FALSE

/datum/netrun_external_projection_fixture/New()
	worker = new
	worker.external_configuration_checked = TRUE
	worker.external_mode_checked = TRUE
	worker.external_mode = "external"
	client = new(worker)
	worker.external_core = client
	client.world_epoch = "projection-world"
	client.engine_epoch = "projection-engine"
	client.binding_epoch = "projection-binding"
	client.state = "ready"
	client.ready = TRUE
	graph = new
	worker.topology = graph
	executor = new(worker)
	client.effects = executor
	graph.fixture_executor = WEAKREF(executor)
	executor.observe_projection(client, list("graph_version" = "1", "graph_input_sequence" = "7", "availability_version" = "1"), null)

/datum/netrun_external_projection_fixture/Destroy()
	client?.close("fixture_cleanup")
	for(var/datum/component/netrun_node/node as anything in originals)
		UnregisterSignal(node, COMSIG_NETRUN_NODE_CHANGED)
		if(QDELETED(node))
			continue
		var/list/previous = originals[node]
		node.netrun_projection_fixture_owner = previous["projection_owner"]
		if(node.network != previous["network"])
			node.leave_network(FALSE)
			node.network = previous["network"]
			if(node.network)
				node.network.nodes |= node
		node.bound_apc = previous["anchor"]
		node.binding_area = previous["area"]
		node.binding_sector = previous["sector"]
		node.binding_checked = previous["checked"]
		node.binding_infra_revision = previous["revision"]
	originals.Cut()
	QDEL_NULL(executor)
	QDEL_NULL(client)
	QDEL_NULL(graph)
	for(var/id in worker.networks)
		qdel(worker.networks[id])
	worker.topology = null
	worker.external_core = null
	QDEL_NULL(worker)
	return ..()

/// Source identity экспортируется настоящим client, без REF/address alias на wire.
/datum/netrun_external_projection_fixture/proc/wire_key(datum/component/netrun_node/node)
	if(!originals[node])
		originals[node] = list("network" = node.network, "anchor" = node.bound_apc, "area" = node.binding_area,
			"sector" = node.binding_sector, "checked" = node.binding_checked, "revision" = node.binding_infra_revision, "projection_owner" = node.netrun_projection_fixture_owner)
		node.netrun_projection_fixture_owner = WEAKREF(src)
	var/list/key = client.node_key(node)
	return list("node_id" = key["id"], "generation" = key["generation"])

/// Один structural node row содержит только разрешённые readonly поля.
/datum/netrun_external_projection_fixture/proc/node_row(datum/component/netrun_node/node)
	return list("kind" = "node", "node" = wire_key(node), "address" = node.address,
		"anchor" = null, "lan_id" = "pub:projection-fixture", "is_relay" = FALSE)

/// Удобная envelope сохраняет точные decimal page и graph counters.
/datum/netrun_external_projection_fixture/proc/page(datum/netrun_external_projection_cursor/cursor, index, list/rows, complete, code = null)
	var/source_json = cursor.source_key ? list("node_id" = cursor.source_key["id"], "generation" = cursor.source_key["generation"]) : null
	return list("kind" = "projection_page", "binding_epoch" = client.binding_epoch, "request_id" = cursor.request_id,
		"projection_kind" = cursor.kind, "graph_version" = "1", "graph_input_sequence" = "7", "availability_version" = "1",
		"source" = source_json, "page_index" = index, "rows" = rows, "complete" = complete, "code" = code || (complete ? "completed" : "page"))

/// Запрашивает и полностью импортирует маленький graph, при необходимости добавляя один physical кабель.
/datum/netrun_external_projection_fixture/proc/publish_graph(list/nodes, datum/component/netrun_node/first = null, datum/component/netrun_node/second = null)
	executor.projection_submit(client, "graph")
	var/datum/netrun_external_projection_cursor/cursor = executor.projection_graph_cursor
	var/list/rows = list()
	for(var/datum/component/netrun_node/node as anything in nodes)
		rows += list(node_row(node))
	if(first && second)
		rows += list(list("kind" = "edge", "from" = wire_key(first), "to" = wire_key(second), "link_kind" = "apc", "distance" = 1, "latency_ds" = 1))
	if(!executor.process_projection(client, page(cursor, "1", rows, TRUE)))
		return FALSE
	executor.prepare_projection(client)
	executor.prepare_projection(client)
	return executor.projection_ready(client)

/// Создаёт настоящий source/mode continuation, не вызывая C# или native Dijkstra в тесте.
/datum/netrun_external_projection_fixture/proc/routes(datum/component/netrun_node/source)
	var/list/key = client.node_key(source)
	var/cache_key = executor.projection_key(key, "discovery")
	executor.projection_submit(client, "routes", key, "discovery", cache_key)
	for(var/id in executor.projection_pending)
		var/datum/netrun_external_projection_cursor/cursor = executor.projection_pending[id]
		if(cursor.cache_key == cache_key)
			return cursor

/// Реальный node signal callback меняет физический контекст внутри import notification.
/datum/netrun_external_projection_fixture/proc/move_during_notify(datum/component/netrun_node/node, datum/component/netrun_node/changed, flags)
	SIGNAL_HANDLER
	if(!moved && (flags & NETRUN_CHANGED_BINDING))
		moved = TRUE
		var/atom/movable/host = node.parent
		host.forceMove(move_destination)

/// Неполная таблица не публикуется; binding commit и notify каждый укладываются в32 nodes.
/datum/unit_test/netrun_external_projection_atomic_bounded_commit/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_external_projection_fixture/fixture = allocate(/datum/netrun_external_projection_fixture)
	var/list/nodes = list(scene.source.resolve_node(), scene.target.resolve_node())
	for(var/index in 3 to 33)
		var/obj/machinery/netrun_server/server = scene.machine(/obj/machinery/netrun_server, scene.source_spot)
		nodes += server.GetComponent(/datum/component/netrun_node)
	TEST_ASSERT(fixture.executor.projection_submit(fixture.client, "graph"), "One bounded graph query is admitted")
	var/datum/netrun_external_projection_cursor/cursor = fixture.executor.projection_graph_cursor
	var/list/first = list()
	for(var/index in 1 to 32)
		first += list(fixture.node_row(nodes[index]))
	TEST_ASSERT(fixture.executor.process_projection(fixture.client, fixture.page(cursor, "1", first, FALSE)), "Partial graph page is staged")
	TEST_ASSERT_EQUAL(length(fixture.graph.nodes), 0, "Partial pages never become topology authority")
	TEST_ASSERT(!fixture.executor.projection_ready(fixture.client), "No route authorization before completed")
	TEST_ASSERT(fixture.executor.process_projection(fixture.client, fixture.page(cursor, "2", list(fixture.node_row(nodes[33])), TRUE)), "Final page starts bounded commit")
	fixture.executor.prepare_projection(fixture.client)
	TEST_ASSERT_EQUAL(length(fixture.graph.nodes), 0, "The first 32 derived writes do not publish a partial graph")
	TEST_ASSERT_EQUAL(cursor.commit_cursor, 33, "One slice processes exactly 32 node records")
	fixture.executor.prepare_projection(fixture.client)
	TEST_ASSERT_EQUAL(length(fixture.graph.nodes), 33, "Graph swaps only after every binding/LAN write")
	TEST_ASSERT(fixture.executor.projection_ready(fixture.client), "Whole graph now matches authoritative hints")
	TEST_ASSERT_EQUAL(cursor.phase, "notify", "Notifications run after graph publication")
	fixture.executor.prepare_projection(fixture.client)
	TEST_ASSERT_EQUAL(cursor.commit_cursor, 33, "Notification work also has a 32-node ceiling")
	fixture.executor.prepare_projection(fixture.client)
	TEST_ASSERT_NULL(fixture.executor.projection_graph_cursor, "Final notification releases staging workspace")
	TEST_ASSERT_EQUAL(fixture.client.native_calls, 0, "Projection uses no real IPC in the fixture")

/// Смена версии и явный changed terminal отзывают staging без применения его строк.
/datum/unit_test/netrun_external_projection_version_and_terminal_revoke/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_external_projection_fixture/fixture = allocate(/datum/netrun_external_projection_fixture)
	fixture.executor.projection_submit(fixture.client, "graph")
	var/datum/netrun_external_projection_cursor/cursor = fixture.executor.projection_graph_cursor
	TEST_ASSERT(fixture.executor.process_projection(fixture.client, fixture.page(cursor, "1", list(fixture.node_row(scene.source.resolve_node())), FALSE)), "First page is staged")
	fixture.executor.observe_projection(fixture.client, list("graph_version" = "2", "graph_input_sequence" = "8", "availability_version" = "1"), null)
	TEST_ASSERT_NULL(fixture.executor.projection_graph_cursor, "New graph hint retires the old cursor immediately")
	TEST_ASSERT_EQUAL(length(fixture.graph.nodes), 0, "No old staging becomes visible")
	TEST_ASSERT_EQUAL(length(fixture.executor.projection_pending), 0, "No stale continuation remains")
	fixture.executor.projection_submit(fixture.client, "graph")
	cursor = fixture.executor.projection_graph_cursor
	var/list/terminal = fixture.page(cursor, "1", list(), TRUE, "projection_changed")
	terminal["graph_version"] = "2"
	terminal["graph_input_sequence"] = "8"
	TEST_ASSERT(fixture.executor.process_projection(fixture.client, terminal), "Known changed terminal is consumed")
	TEST_ASSERT_NULL(fixture.executor.projection_graph_cursor, "Changed query cannot publish an empty successful graph")

/// Immutable route rows дают exact-generation authority; собственная копия отзывается тем же binding и availability.
/datum/unit_test/netrun_external_projection_route_authority_and_generation/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_external_projection_fixture/fixture = allocate(/datum/netrun_external_projection_fixture)
	var/datum/component/netrun_node/source = scene.source.resolve_node()
	var/datum/component/netrun_node/target = scene.target.resolve_node()
	TEST_ASSERT(fixture.publish_graph(list(source, target), source, target), "Imported physical graph is ready")
	var/datum/netrun_external_projection_cursor/cursor = fixture.routes(source)
	var/cache_key = cursor.cache_key
	var/list/rows = list(list("kind" = "route", "node" = fixture.wire_key(source), "previous" = null, "latency_ds" = 0, "quantum" = FALSE),
		list("kind" = "route", "node" = fixture.wire_key(target), "previous" = fixture.wire_key(source), "latency_ds" = 1, "quantum" = FALSE))
	TEST_ASSERT(fixture.executor.process_projection(fixture.client, fixture.page(cursor, "1", rows, TRUE)), "One completed source tree is imported")
	var/datum/netrun_path_tree/external/tree = fixture.executor.projection_trees[cache_key]
	TEST_ASSERT(tree.path_available(fixture.graph, target.address), "Exact live generations authorize the imported physical path")
	var/datum/netrun_path_tree/external/copy = tree.copy()
	var/list/key = copy.external_keys[target.address]
	fixture.client.nodes_by_id -= key["node_id"]
	TEST_ASSERT(!copy.path_available(fixture.graph, target.address), "A retained address cannot resolve a revoked protocol generation")
	fixture.client.nodes_by_id[key["node_id"]] = WEAKREF(target)
	fixture.client.binding_epoch = "new-binding"
	TEST_ASSERT(!copy.external_current(), "Request-owned copy cannot revive in a new IPC binding")
	qdel(copy)

/// Availability-only hint оставляет structural Graph staging, но немедленно отзывает все route caches.
/datum/unit_test/netrun_external_projection_availability_only/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_external_projection_fixture/fixture = allocate(/datum/netrun_external_projection_fixture)
	var/datum/component/netrun_node/source = scene.source.resolve_node()
	TEST_ASSERT(fixture.publish_graph(list(source)), "Structural baseline is available")
	var/datum/netrun_external_projection_cursor/routes = fixture.routes(source)
	var/cache_key = routes.cache_key
	TEST_ASSERT(fixture.executor.process_projection(fixture.client, fixture.page(routes, "1", list(list("kind" = "route", "node" = fixture.wire_key(source), "previous" = null, "latency_ds" = 0, "quantum" = FALSE)), TRUE)), "Self tree is cached")
	var/datum/netrun_console/projection_fixture/console = allocate(/datum/netrun_console/projection_fixture, scene.sender)
	fixture.executor.projection_watch(fixture.client, source, console)
	TEST_ASSERT_NULL(fixture.executor.projection_waiters[cache_key], "Reading an already current source tree needs no completion waiter")
	fixture.executor.projection_submit(fixture.client, "graph")
	var/datum/netrun_external_projection_cursor/graph_cursor = fixture.executor.projection_graph_cursor
	fixture.executor.observe_projection(fixture.client, list("graph_version" = "1", "graph_input_sequence" = "7", "availability_version" = "2"), null)
	TEST_ASSERT_EQUAL(fixture.executor.projection_graph_cursor, graph_cursor, "Availability churn cannot starve structural graph pages")
	TEST_ASSERT_NULL(fixture.executor.projection_trees[cache_key], "Old route availability cannot remain authority")
	TEST_ASSERT(fixture.executor.projection_ready(fixture.client), "Previously published structural graph remains usable")

/// Native movement внутри notify_changed отзывает текущий cursor и уже опубликованную authority, даже во время import.
/datum/unit_test/netrun_external_projection_reentrant_physical_change/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_external_projection_fixture/fixture = allocate(/datum/netrun_external_projection_fixture)
	var/datum/component/netrun_node/source = scene.source.resolve_node()
	fixture.executor.projection_submit(fixture.client, "graph")
	var/datum/netrun_external_projection_cursor/cursor = fixture.executor.projection_graph_cursor
	TEST_ASSERT(fixture.executor.process_projection(fixture.client, fixture.page(cursor, "1", list(fixture.node_row(source)), TRUE)), "Graph enters commit")
	fixture.executor.prepare_projection(fixture.client)
	fixture.move_destination = scene.target_spot
	fixture.RegisterSignal(source, COMSIG_NETRUN_NODE_CHANGED, TYPE_PROC_REF(/datum/netrun_external_projection_fixture, move_during_notify))
	fixture.executor.prepare_projection(fixture.client)
	TEST_ASSERT(fixture.moved, "A real native listener moved its parent during notification")
	TEST_ASSERT_NULL(fixture.executor.projection_graph_cursor, "Reentrant movement retires the cursor being processed")
	TEST_ASSERT(fixture.graph.dirty, "Imported adjacency cannot authorize after the local movement")
	TEST_ASSERT(!fixture.executor.projection_ready(fixture.client), "No import suppression can hide a real physical change")

/// Старый nested anchor_result и переместившийся console context не создают cached nearest authority.
/datum/unit_test/netrun_external_projection_anchor_stale_context/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_external_projection_fixture/fixture = allocate(/datum/netrun_external_projection_fixture)
	var/datum/netrun_console/projection_fixture/console = allocate(/datum/netrun_console/projection_fixture, scene.sender)
	console.projection_position = scene.source_spot
	TEST_ASSERT_NULL(fixture.executor.projection_anchor(fixture.client, console), "A point lookup is asynchronous")
	var/datum/netrun_external_anchor_cursor/cursor = fixture.executor.projection_anchors[REF(console)]
	var/datum/netrun_external_query_command/command = new
	command.kind = "anchor_query"
	command.consumer = WEAKREF(cursor)
	var/datum/component/netrun_node/apc = scene.apc.GetComponent(/datum/component/netrun_node)
	var/list/answer = list("request_id" = cursor.request_id, "node" = fixture.wire_key(apc), "graph_version" = "0", "graph_input_sequence" = "0", "code" = "found")
	fixture.executor.observe_projection(fixture.client, list("anchor_result" = answer), command)
	TEST_ASSERT_NULL(fixture.executor.projection_anchors[REF(console)], "An old nested reply cannot override current runtime hints")
	fixture.executor.projection_anchor(fixture.client, console)
	cursor = fixture.executor.projection_anchors[REF(console)]
	command.consumer = WEAKREF(cursor)
	answer["request_id"] = cursor.request_id
	answer["graph_version"] = "1"
	answer["graph_input_sequence"] = "7"
	console.projection_position = scene.target_spot
	fixture.executor.observe_projection(fixture.client, list("anchor_result" = answer), command)
	TEST_ASSERT_NULL(fixture.executor.projection_anchors[REF(console)], "Coordinate change while pending rejects a once-correct anchor")
	qdel(command)

/// Настоящие новые stamps включают persistent production protocol, не legacy diagnostic Graph.
/datum/netrun_external_projection_fixture/proc/start_stream()
	executor.observe_projection(client, hints(), null)
	if(!executor.projection_start_stream(client))
		return null
	return executor.projection_sync

/// Hint scalar snapshot совпадает с input на стороне C#; leaf updates меняют graph/availability, но не infrastructure proof.
/datum/netrun_external_projection_fixture/proc/hints(version = "1", input_sequence = "7", availability = "1", infra = "1", av_infra = "1")
	return list("graph_version" = version, "graph_input_sequence" = input_sequence, "availability_version" = availability,
		"infra_stamp" = infra, "av_infra_stamp" = av_infra)

/// Upsert revision берётся из настоящего raw exporter, отдельно от structural graph публикации.
/datum/netrun_external_projection_fixture/proc/node_operation(datum/component/netrun_node/node)
	var/list/key = wire_key(node)
	client.export_node(node)
	return list("kind" = "node_upsert", "node" = key, "address" = node.address, "anchor" = null,
		"lan_id" = "pub:projection-fixture", "is_relay" = istype(node.parent, /obj/machinery/ntnet_relay),
		"node_revision" = client.node_revision(client.node_key(node)), "is_endpoint" = !client.node_is_forwarder(node))

/// Edge wire IDs не зависят от native адресов; символ выбирается fixture только для различения рёбер.
/datum/netrun_external_projection_fixture/proc/edge_operation(datum/component/netrun_node/first, datum/component/netrun_node/second, character = "a", cost = 1)
	return list("kind" = "edge_upsert", "edge_id" = repeat_string(64, character), "from" = wire_key(first), "to" = wire_key(second),
		"link_kind" = "endpoint", "distance" = cost, "latency_ds" = cost)

/// Страница frozen batch не переименовывается в latest graph при последующем movement.
/datum/netrun_external_projection_fixture/proc/sync_page(datum/netrun_external_graph_cursor/cursor, index, list/operations, complete = TRUE,
	phase = "snapshot", from_version = "0", version = "1", input_sequence = "7", infra = "1", av_infra = "1")
	return list("kind" = "graph_sync_page", "binding_epoch" = client.binding_epoch, "request_id" = cursor.request_id,
		"page_index" = index, "phase" = phase, "from_graph_version" = from_version, "graph_version" = version,
		"graph_input_sequence" = input_sequence, "infra_stamp" = infra, "av_infra_stamp" = av_infra,
		"operations" = operations, "batch_complete" = complete, "code" = complete ? "completed" : "page")

/// Эмулирует только application result Continue: переданное native page содержимое уже применено.
/datum/netrun_external_projection_fixture/proc/ack_stream()
	for(var/datum/netrun_external_query_command/command as anything in executor.query_commands.Copy())
		if(command.kind == "graph_sync_continue")
			executor.query_commands -= command
			executor.observe_projection(client, list("action" = list("accepted" = TRUE, "code" = "continued")), command)
			qdel(command)
			return TRUE
	return FALSE

/// Captured route row revision не меняется при emit после нового raw movement.
/datum/netrun_external_projection_fixture/proc/route_row(datum/component/netrun_node/node, datum/component/netrun_node/previous, cost)
	client.export_node(node)
	return list("kind" = "route", "node" = wire_key(node), "previous" = previous ? wire_key(previous) : null,
		"latency_ds" = cost, "quantum" = FALSE, "node_revision" = client.node_revision(client.node_key(node)))

/// Route pages имеют отдельные source/infra proofs, а GraphVersion остаётся только captured diagnostic metadata.
/datum/netrun_external_projection_fixture/proc/stamped_route_page(datum/netrun_external_projection_cursor/cursor, index, list/rows, complete)
	var/list/result = page(cursor, index, rows, complete)
	result["infra_stamp"] = "1"
	result["av_infra_stamp"] = "1"
	result["source_node_revision"] = client.node_revision(cursor.source_key)
	return result

/// Стартовый baseline остаётся тем же query при leaf movement; historical revision не откатывает native LAN.
/datum/unit_test/netrun_external_projection_stream_snapshot_churn_and_ack/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_external_projection_fixture/fixture = allocate(/datum/netrun_external_projection_fixture)
	var/datum/component/netrun_node/first = scene.source.resolve_node()
	var/datum/component/netrun_node/second = scene.target.resolve_node()
	var/list/first_operation = fixture.node_operation(first)
	var/list/second_operation = fixture.node_operation(second)
	var/datum/netrun_network/old_network = second.network
	var/datum/netrun_external_graph_cursor/cursor = fixture.start_stream()
	TEST_ASSERT(cursor, "A single persistent production stream starts")
	TEST_ASSERT(fixture.executor.process_graph_sync(fixture.client, fixture.sync_page(cursor, "1", list(first_operation), FALSE)), "First historical page applies without publication")
	TEST_ASSERT_EQUAL(length(fixture.graph.nodes), 0, "Initial partial baseline cannot become graph authority")
	TEST_ASSERT(cursor.ack_pending, "Bounded apply queues an explicit Continue ACK")
	TEST_ASSERT(!fixture.executor.process_graph_sync(fixture.client, fixture.sync_page(cursor, "2", list(second_operation))), "A second page cannot pass an unacknowledged first page")
	TEST_ASSERT(fixture.ack_stream(), "Continue application result releases exactly one in-flight page")
	scene.receiver.forceMove(scene.source_spot)
	fixture.client.export_node(second)
	fixture.executor.invalidate_projection("movement", TRUE, second)
	fixture.executor.observe_projection(fixture.client, fixture.hints("2", "8", "2"), null)
	TEST_ASSERT_EQUAL(fixture.executor.projection_sync, cursor, "Unrelated graph version changes never restart baseline")
	TEST_ASSERT(fixture.executor.process_graph_sync(fixture.client, fixture.sync_page(cursor, "2", list(second_operation))), "Frozen baseline finishes despite current leaf movement")
	TEST_ASSERT_EQUAL(second.network, old_network, "Stale historical row cannot roll back native derived binding")
	TEST_ASSERT_EQUAL(length(fixture.graph.nodes), 2, "All historical identities are installed before the following delta")
	TEST_ASSERT(fixture.executor.projection_ready(fixture.client), "Endpoint proof prevents one moving leaf from blocking all infrastructure")
	fixture.ack_stream()
	TEST_ASSERT(fixture.executor.process_graph_sync(fixture.client, fixture.sync_page(cursor, "3", list(fixture.node_operation(second)), TRUE, "delta", "1", "2", "8")), "Newest coalesced delta catches up the changed leaf")
	TEST_ASSERT_EQUAL(second.network.id, "pub:projection-fixture", "Only the matching raw revision applies current derived data")
	TEST_ASSERT(!hascall(fixture.graph, "rebuild"), "The imported read-model exposes no native topology builder")
	TEST_ASSERT(!hascall(fixture.graph, "borrow_infrastructure_tree"), "Graph apply cannot invoke a native Dijkstra cache")

/// Исчезнувший weak generation и exact tombstone не отменяют целый historical snapshot.
/datum/unit_test/netrun_external_projection_stream_missing_generation/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_external_projection_fixture/fixture = allocate(/datum/netrun_external_projection_fixture)
	var/datum/component/netrun_node/node = scene.source.resolve_node()
	var/list/operation = fixture.node_operation(node)
	var/list/key = operation["node"]
	var/datum/netrun_external_graph_cursor/cursor = fixture.start_stream()
	fixture.client.nodes_by_id -= key["node_id"]
	TEST_ASSERT(fixture.executor.process_graph_sync(fixture.client, fixture.sync_page(cursor, "1", list(operation))), "Missing native weakref is a historical identity, not corrupt wire")
	TEST_ASSERT_EQUAL(length(fixture.executor.projection_data.records), 1, "Historical key is retained until the target diff removes it")
	TEST_ASSERT_EQUAL(length(fixture.graph.nodes), 0, "No native object is invented for a missing generation")
	fixture.ack_stream()
	var/list/remove = list("kind" = "node_remove", "node" = key)
	TEST_ASSERT(fixture.executor.process_graph_sync(fixture.client, fixture.sync_page(cursor, "2", list(remove), TRUE, "delta", "1", "2", "8")), "Exact tombstone applies in the next bounded batch")
	TEST_ASSERT_EQUAL(length(fixture.executor.projection_data.records), 0, "No historical generations accumulate after the diff")

/// Edge removal использует index/swap-delete, а повтор remove старого address owner не удаляет заменяющую identity.
/datum/unit_test/netrun_external_projection_stream_edges_and_address_owner/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_external_projection_fixture/fixture = allocate(/datum/netrun_external_projection_fixture)
	var/datum/component/netrun_node/first = scene.source.resolve_node()
	var/datum/component/netrun_node/second = scene.target.resolve_node()
	var/datum/component/netrun_node/third = scene.apc.GetComponent(/datum/component/netrun_node)
	var/list/first_operation = fixture.node_operation(first)
	var/list/edge_a = fixture.edge_operation(first, third, "a")
	var/list/edge_b = fixture.edge_operation(second, third, "b")
	var/datum/netrun_external_graph_cursor/cursor = fixture.start_stream()
	TEST_ASSERT(fixture.executor.process_graph_sync(fixture.client, fixture.sync_page(cursor, "1", list(first_operation, fixture.node_operation(second), fixture.node_operation(third), edge_a, edge_b))), "Physical graph imports two real cables")
	fixture.ack_stream()
	TEST_ASSERT(fixture.executor.process_graph_sync(fixture.client, fixture.sync_page(cursor, "2", list(list("kind" = "edge_remove", "edge_id" = edge_a["edge_id"])), TRUE, "delta", "1", "2", "8")), "One indexed cable is removed")
	TEST_ASSERT_EQUAL(length(fixture.graph.edges), 1, "Swap-delete retains exactly the other cable")
	var/list/remaining = fixture.graph.edges[1]
	TEST_ASSERT_EQUAL(remaining["id"], edge_b["edge_id"], "Remaining edge position is valid after swap")
	fixture.ack_stream()
	var/list/replacement = first_operation.Copy()
	var/list/new_key = list("node_id" = "historical-replacement", "generation" = "1")
	replacement["node"] = new_key
	TEST_ASSERT(fixture.executor.process_graph_sync(fixture.client, fixture.sync_page(cursor, "3", list(replacement, list("kind" = "node_remove", "node" = first_operation["node"])), TRUE, "delta", "2", "3", "9")), "Late old generation removal is harmless after address replacement")
	var/token = fixture.executor.projection_token(new_key)
	TEST_ASSERT_EQUAL(fixture.executor.projection_data.address_keys[first.address], token, "Exact address owner guard retains replacement")
	TEST_ASSERT(fixture.executor.projection_data.records[token], "Replacement historical identity remains in the baseline")

/// Pinned route tree завершается при чужом leaf churn: живые строки продолжают авторизовать, изменившаяся строка ждёт refresh.
/datum/unit_test/netrun_external_projection_stream_pinned_route_rows/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_external_projection_fixture/fixture = allocate(/datum/netrun_external_projection_fixture)
	var/datum/component/netrun_node/source = scene.apc.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/target = scene.source.resolve_node()
	var/datum/component/netrun_node/moving = scene.target.resolve_node()
	var/list/source_operation = fixture.node_operation(source)
	var/list/target_operation = fixture.node_operation(target)
	var/list/moving_operation = fixture.node_operation(moving)
	var/datum/netrun_external_graph_cursor/stream = fixture.start_stream()
	TEST_ASSERT(fixture.executor.process_graph_sync(fixture.client, fixture.sync_page(stream, "1", list(source_operation, target_operation, moving_operation, fixture.edge_operation(source, target), fixture.edge_operation(source, moving, "b")))), "Infrastructure baseline is ready")
	fixture.ack_stream()
	fixture.executor.prepare_projection(fixture.client)
	var/key_epoch = moving.access_key_epoch
	var/presentation_revision = fixture.graph.revision
	var/datum/netrun_external_projection_cursor/routes = fixture.routes(source)
	var/cache_key = routes.cache_key
	var/datum/netrun_console/projection_fixture/console = allocate(/datum/netrun_console/projection_fixture, scene.sender)
	console.ui_dirty = FALSE
	console.ui_catalog_context = list("pending")
	fixture.executor.projection_watch(fixture.client, source, console)
	TEST_ASSERT(fixture.executor.projection_waiters[cache_key], "A pending source tree retains only a bounded weak UI waiter")
	var/list/source_row = fixture.route_row(source, null, 0)
	var/list/target_row = fixture.route_row(target, source, 1)
	var/list/moving_row = fixture.route_row(moving, source, 1)
	TEST_ASSERT(fixture.executor.process_projection(fixture.client, fixture.stamped_route_page(routes, "1", list(source_row, target_row), FALSE)), "First pinned source-tree rows are staged")
	TEST_ASSERT(!console.ui_dirty, "A partial source tree does not wake UI with unpublished rows")
	scene.receiver.forceMove(scene.source_spot)
	fixture.client.export_node(moving)
	fixture.executor.invalidate_projection("movement", TRUE, moving)
	fixture.executor.observe_projection(fixture.client, fixture.hints("2", "8", "2"), null)
	TEST_ASSERT(fixture.executor.process_projection(fixture.client, fixture.stamped_route_page(routes, "2", list(moving_row), TRUE)), "Unrelated endpoint revision does not abort every route row")
	var/datum/netrun_path_tree/external/tree = fixture.executor.projection_trees[cache_key]
	TEST_ASSERT(console.ui_dirty, "Completed source tree wakes its quiet console without unrelated world activity")
	TEST_ASSERT_NULL(console.ui_catalog_context, "Completion invalidates the console's previously empty catalog cache")
	TEST_ASSERT_NULL(fixture.executor.projection_waiters[cache_key], "Completion releases its weak waiter bucket")
	TEST_ASSERT(tree?.external_current(), "Tree authority is tied to infrastructure and its unchanged source")
	TEST_ASSERT(tree.path_available(fixture.graph, target.address), "Unaffected row keeps working without a fresh all-pairs solve")
	TEST_ASSERT(!tree.path_available(fixture.graph, moving.address), "Captured stale target revision cannot authorize its moved endpoint")
	TEST_ASSERT(tree.external_refresh_needed, "The next read will request fresh target rows")
	TEST_ASSERT_NULL(fixture.executor.projection_demands[cache_key], "Completion alone does not subscribe a passive cache to continuous refresh")
	TEST_ASSERT(fixture.executor.process_graph_sync(fixture.client, fixture.sync_page(stream, "2", list(fixture.node_operation(moving), fixture.edge_operation(source, moving, "b", 2)), TRUE, "delta", "1", "2", "8")), "Movement/cost delta updates only the existing endpoint and cable")
	fixture.executor.prepare_projection(fixture.client)
	TEST_ASSERT_EQUAL(moving.access_key_epoch, key_epoch, "Stable LAN/anchor movement must not revoke node access keys")
	TEST_ASSERT_EQUAL(fixture.graph.revision, presentation_revision, "Cost-only changes do not reset every topology/patrol/UI projection")
	TEST_ASSERT_EQUAL(fixture.graph.weight_revision, "2", "Physical cost diagnostic still follows target graph version")
	TEST_ASSERT_EQUAL(fixture.graph.external_weight_versions[moving.address], "2", "Only incident edge weight gets an incremental presentation revision")
	fixture.ack_stream()
	moving.offline_until = world.time + 10 SECONDS
	fixture.client.export_node(moving)
	fixture.executor.invalidate_projection("availability", FALSE, moving)
	fixture.executor.observe_projection(fixture.client, fixture.hints("2", "8", "3"), null)
	TEST_ASSERT(fixture.executor.process_graph_sync(fixture.client, fixture.sync_page(stream, "3", list(fixture.node_operation(moving)), TRUE, "delta", "2", "2", "8")), "Availability-only revision requires no structural graph replacement")
	fixture.executor.prepare_projection(fixture.client)
	TEST_ASSERT_EQUAL(moving.access_key_epoch, key_epoch, "Power/availability refresh must not masquerade as a new binding")
	TEST_ASSERT_EQUAL(fixture.graph.revision, presentation_revision, "Online-only updates preserve the structural presentation generation")
	fixture.executor.disconnect_projection(fixture.client, "waiter_cleanup")
	TEST_ASSERT_EQUAL(length(fixture.executor.projection_waiters), 0, "Disconnect never retains old-generation UI waiters")

/// Retained tables do not subscribe closed windows to every moving endpoint on the station.
/datum/unit_test/netrun_external_projection_stream_demand_refresh/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_external_projection_fixture/fixture = allocate(/datum/netrun_external_projection_fixture)
	var/datum/component/netrun_node/source = scene.source.resolve_node()
	var/datum/component/netrun_node/target = scene.target.resolve_node()
	var/turf/original_position = target.physical_turf()
	var/datum/netrun_external_graph_cursor/stream = fixture.start_stream()
	TEST_ASSERT(fixture.executor.process_graph_sync(fixture.client, fixture.sync_page(stream, "1", list(fixture.node_operation(source), fixture.node_operation(target), fixture.edge_operation(source, target)))), "Baseline is published")
	fixture.ack_stream()
	var/datum/netrun_external_projection_cursor/routes = fixture.routes(source)
	var/cache_key = routes.cache_key
	TEST_ASSERT(fixture.executor.process_projection(fixture.client, fixture.stamped_route_page(routes, "1", list(fixture.route_row(source, null, 0), fixture.route_row(target, source, 1)), TRUE)), "A passive source table is cached")
	var/datum/netrun_path_tree/external/tree = fixture.executor.projection_trees[cache_key]
	TEST_ASSERT(!tree.external_refresh_needed, "The just-completed table is current")
	var/queries = length(fixture.executor.projection_pending)
	scene.receiver.forceMove(scene.source_spot)
	fixture.client.export_node(target)
	fixture.executor.invalidate_projection("movement", TRUE, target)
	var/generation = fixture.executor.projection_refresh_generation
	TEST_ASSERT(tree.external_refresh_needed, "Movement records that fresh rows will be needed")
	TEST_ASSERT(!fixture.executor.projection_demands[cache_key], "A passive LRU entry does not request a full source table")
	TEST_ASSERT(fixture.executor.process_graph_sync(fixture.client, fixture.sync_page(stream, "2", list(fixture.node_operation(target), fixture.edge_operation(source, target, "a", 2)), TRUE, "delta", "1", "2", "8")), "Core catches up with the same movement")
	TEST_ASSERT_EQUAL(fixture.executor.projection_refresh_generation, generation, "Dirty mark and its graph upsert are one refresh generation")
	fixture.ack_stream()
	fixture.executor.prepare_projection(fixture.client)
	TEST_ASSERT_EQUAL(length(fixture.executor.projection_pending), queries, "Background preparation does not refresh an unused cache")
	var/datum/netrun_console/projection_fixture/console = allocate(/datum/netrun_console/projection_fixture, scene.sender)
	console.ui_dirty = FALSE
	fixture.executor.projection_watch(fixture.client, source, console)
	TEST_ASSERT_EQUAL(fixture.executor.projection_tree(fixture.client, source), tree, "A reader can retain the unaffected source proof during refresh")
	TEST_ASSERT(fixture.executor.projection_demands[cache_key], "A real read requests one coalesced refresh")
	TEST_ASSERT(fixture.executor.projection_waiters[cache_key], "The active reader waits for completion")
	fixture.executor.prepare_projection(fixture.client)
	for(var/id in fixture.executor.projection_pending)
		var/datum/netrun_external_projection_cursor/current = fixture.executor.projection_pending[id]
		if(current.cache_key == cache_key)
			routes = current
	TEST_ASSERT(routes, "The requested refresh is admitted")
	fixture.executor.projection_tree(fixture.client, source)
	fixture.executor.projection_tree(fixture.client, source)
	TEST_ASSERT_NULL(fixture.executor.projection_demands[cache_key], "Repeated reads share the in-flight query instead of queuing a second one")
	TEST_ASSERT(fixture.executor.process_projection(fixture.client, fixture.stamped_route_page(routes, "1", list(fixture.route_row(source, null, 0), fixture.route_row(target, source, 2)), TRUE)), "Fresh rows complete")
	tree = fixture.executor.projection_trees[cache_key]
	TEST_ASSERT(!tree.external_refresh_needed, "Current completion clears the refresh flag")
	TEST_ASSERT_NULL(fixture.executor.projection_demands[cache_key], "Completion does not request the same table again")
	TEST_ASSERT(console.ui_dirty, "Only the active reader is woken for the new rows")
	scene.receiver.forceMove(original_position)
	fixture.client.export_node(target)
	fixture.executor.invalidate_projection("movement", TRUE, target)
	fixture.executor.projection_tree(fixture.client, source)
	fixture.executor.prepare_projection(fixture.client)
	for(var/id in fixture.executor.projection_pending)
		var/datum/netrun_external_projection_cursor/current = fixture.executor.projection_pending[id]
		if(current.cache_key == cache_key)
			routes = current
	TEST_ASSERT(fixture.executor.process_projection(fixture.client, fixture.stamped_route_page(routes, "1", list(fixture.route_row(source, null, 0), fixture.route_row(target, source, 1)), FALSE)), "A frozen query has already received the target row")
	generation = fixture.executor.projection_refresh_generation
	scene.receiver.forceMove(scene.source_spot)
	fixture.client.export_node(target)
	fixture.executor.invalidate_projection("movement", TRUE, target)
	TEST_ASSERT(fixture.executor.projection_refresh_generation != generation, "A second change before the first graph ACK still invalidates captured rows")
	TEST_ASSERT(fixture.executor.process_projection(fixture.client, fixture.stamped_route_page(routes, "2", list(), TRUE)), "Completion retains the captured table without silently treating it as fresh")
	tree = fixture.executor.projection_trees[cache_key]
	TEST_ASSERT(tree.external_refresh_needed, "A change after receiving a row is retained for the next actual reader")
	TEST_ASSERT_NULL(fixture.executor.projection_demands[cache_key], "Even an outdated completion does not start another query without a reader")
	fixture.executor.prepare_projection(fixture.client)
	TEST_ASSERT_EQUAL(length(fixture.executor.projection_pending), queries, "Closing the observer leaves no self-sustaining refresh loop")

/// Путь Core содержит cumulative doubles; DM float не вправе отвергать его после вычитания округлённых costs.
/datum/unit_test/netrun_external_projection_stream_fractional_route/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_external_projection_fixture/fixture = allocate(/datum/netrun_external_projection_fixture)
	var/datum/component/netrun_node/source = scene.source.resolve_node()
	var/datum/component/netrun_node/apc = scene.apc.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/target = scene.target.resolve_node()
	var/datum/netrun_external_graph_cursor/stream = fixture.start_stream()
	TEST_ASSERT(fixture.executor.process_graph_sync(fixture.client, fixture.sync_page(stream, "1", list(fixture.node_operation(source), fixture.node_operation(apc), fixture.node_operation(target), fixture.edge_operation(source, apc, "a", 0.1), fixture.edge_operation(apc, target, "b", 0.2)))), "Fractional C# edge baseline is imported")
	fixture.ack_stream()
	fixture.executor.prepare_projection(fixture.client)
	var/datum/netrun_external_projection_cursor/routes = fixture.routes(source)
	var/cache_key = routes.cache_key
	TEST_ASSERT(fixture.executor.process_projection(fixture.client, fixture.stamped_route_page(routes, "1", list(fixture.route_row(source, null, 0), fixture.route_row(apc, source, 0.1), fixture.route_row(target, apc, 0.3)), TRUE)), "Frozen cumulative C# costs are imported")
	var/datum/netrun_path_tree/external/tree = fixture.executor.projection_trees[cache_key]
	TEST_ASSERT(tree.path_available(fixture.graph, target.address), "Current C# path must survive DM cumulative float rounding")
	target.offline_until = world.time + 10 SECONDS
	fixture.client.export_node(target)
	fixture.executor.invalidate_projection("availability", FALSE, target)
	TEST_ASSERT(!tree.path_available(fixture.graph, target.address), "A changed native revision still revokes the captured path")

/// Forwarder dirty немедленно закрывает всю route authority, хотя ordinary leaf changes такого global эффекта не имеют.
/datum/unit_test/netrun_external_projection_stream_infrastructure_dirty/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_external_projection_fixture/fixture = allocate(/datum/netrun_external_projection_fixture)
	var/datum/component/netrun_node/apc = scene.apc.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/endpoint = scene.source.resolve_node()
	var/list/apc_operation = fixture.node_operation(apc)
	var/list/endpoint_operation = fixture.node_operation(endpoint)
	var/datum/netrun_external_graph_cursor/cursor = fixture.start_stream()
	TEST_ASSERT(fixture.executor.process_graph_sync(fixture.client, fixture.sync_page(cursor, "1", list(apc_operation, endpoint_operation, fixture.edge_operation(apc, endpoint)))), "Whole baseline is initially usable")
	TEST_ASSERT(fixture.executor.projection_ready(fixture.client), "No infrastructure dirty markers remain")
	fixture.executor.invalidate_projection("availability", FALSE, endpoint)
	TEST_ASSERT(fixture.executor.projection_ready(fixture.client), "A leaf outage only revokes that endpoint")
	fixture.executor.invalidate_projection("availability", FALSE, apc)
	TEST_ASSERT_EQUAL(fixture.executor.projection_dirty_infra, 1, "Native forwarding role is recorded before a later C# hint")
	TEST_ASSERT(!fixture.executor.projection_ready(fixture.client), "No stale infrastructure can authorize a path")
	fixture.executor.disconnect_projection(fixture.client, "test_close")
	fixture.executor.owner = null
	fixture.executor.disconnect_projection(fixture.client, "repeated_close")
	TEST_ASSERT_EQUAL(length(fixture.executor.projection_dirty_nodes), 0, "Repeated shutdown clears owned state without reading null owner")
	fixture.executor.owner = fixture.worker

/// Новый leaf ещё не получил C# proof, но не меняет уже опубликованные транзитные пути.
/datum/unit_test/netrun_external_projection_stream_new_endpoint/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_external_projection_fixture/fixture = allocate(/datum/netrun_external_projection_fixture)
	var/datum/component/netrun_node/source = scene.source.resolve_node()
	var/datum/component/netrun_node/target = scene.target.resolve_node()
	var/datum/netrun_external_graph_cursor/stream = fixture.start_stream()
	TEST_ASSERT(fixture.executor.process_graph_sync(fixture.client, fixture.sync_page(stream, "1", list(fixture.node_operation(source), fixture.node_operation(target), fixture.edge_operation(source, target)))), "The existing physical route is published")
	fixture.ack_stream()
	fixture.executor.prepare_projection(fixture.client)
	var/datum/netrun_external_projection_cursor/routes = fixture.routes(source)
	var/cache_key = routes.cache_key
	TEST_ASSERT(fixture.executor.process_projection(fixture.client, fixture.stamped_route_page(routes, "1", list(fixture.route_row(source, null, 0), fixture.route_row(target, source, 1)), TRUE)), "The source tree has current proofs")
	var/obj/item/new_host = allocate(/obj/item, scene.source_spot)
	var/datum/component/netrun_node/new_node = new_host.AddComponent(/datum/component/netrun_node, NETRUN_NODE_NEURAL)
	fixture.client.export_node(new_node)
	fixture.executor.invalidate_projection("registered", TRUE, new_node)
	var/datum/netrun_path_tree/external/tree = fixture.executor.projection_trees[cache_key]
	TEST_ASSERT(fixture.executor.projection_ready(fixture.client), "An unpublished ordinary endpoint must not close the infrastructure gate")
	TEST_ASSERT(tree.path_available(fixture.graph, target.address), "Existing return paths survive unrelated endpoint registration")
	TEST_ASSERT(!tree.path_available(fixture.graph, new_node.address), "No route authority is granted to the unacknowledged endpoint")

/// Point selection cache зависит от APC structure и собственного context, а не от движения любого чужого leaf или power availability.
/datum/unit_test/netrun_external_projection_stream_anchor_infra_cache/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_external_projection_fixture/fixture = allocate(/datum/netrun_external_projection_fixture)
	fixture.start_stream()
	var/datum/netrun_console/projection_fixture/console = allocate(/datum/netrun_console/projection_fixture, scene.sender)
	console.projection_position = scene.source_spot
	fixture.executor.projection_anchor(fixture.client, console)
	var/datum/netrun_external_anchor_cursor/cursor = fixture.executor.projection_anchors[REF(console)]
	var/datum/netrun_external_query_command/command = new
	command.kind = "anchor_query"
	command.consumer = WEAKREF(cursor)
	var/datum/component/netrun_node/apc = scene.apc.GetComponent(/datum/component/netrun_node)
	var/list/answer = list("request_id" = cursor.request_id, "node" = fixture.wire_key(apc), "graph_version" = "1", "graph_input_sequence" = "7", "code" = "found")
	console.ui_dirty = FALSE
	fixture.executor.observe_projection(fixture.client, list("anchor_result" = answer), command)
	TEST_ASSERT(console.ui_dirty, "A quiet node-less console wakes when its first anchor query becomes ready")
	TEST_ASSERT_EQUAL(fixture.executor.projection_anchor(fixture.client, console), apc, "First typed point result resolves its exact native generation")
	fixture.executor.observe_projection(fixture.client, fixture.hints("2", "8", "2", "1", "2"), null)
	TEST_ASSERT_EQUAL(fixture.executor.projection_anchor(fixture.client, console), apc, "Unrelated leaf graph changes and AV stamp do not redo nearest search")
	TEST_ASSERT_EQUAL(fixture.executor.projection_anchors[REF(console)], cursor, "Cache still holds the same bounded context")
	fixture.executor.observe_projection(fixture.client, fixture.hints("3", "9", "3", "2", "2"), null)
	TEST_ASSERT_NULL(fixture.executor.projection_anchors[REF(console)], "Actual APC/sector structural stamp revokes the cached selection")
	qdel(command)
