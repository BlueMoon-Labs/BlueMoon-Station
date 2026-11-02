/// Read-only C# projection cursor: один bounded staging graph либо source tree без native вычисления маршрутов.
/datum/netrun_external_projection_cursor
	/// ID logical query не меняется при retry outer frame.
	var/request_id
	/// graph либо routes; тип строк проверяется до изменения staging.
	var/kind
	/// discovery допускает offline final, machine требует online весь путь.
	var/mode = "discovery"
	/// Exact source identity с полями id/generation; Graph использует null.
	var/list/source_key
	/// Ключ bounded source/mode cache, не ссылка на игрового владельца.
	var/cache_key
	/// Локальные generations закрывают окно между native signal и C# ACK фактов.
	var/generation
	var/state_generation
	/// Все страницы одного query обязаны объявлять одинаковые structural metadata.
	var/graph_version
	var/input_sequence
	var/availability_version
	/// Routes proof отделяет C# infrastructure от unrelated leaf changes.
	var/infra_stamp
	var/av_infra_stamp
	var/source_revision
	var/stale_rows = FALSE
	/// Следующий положительный decimal page serial без преобразования в DM float.
	var/next_page = "1"
	/// pending → commit → notify; read-only query не выполняет native machine handlers.
	var/phase = "pending"
	/// Исчезнувший native generation отзывает staging, даже если wire страница корректна.
	var/invalid = FALSE
	/// Graph обязан полностью выдать nodes перед первой physical edge строкой.
	var/seen_edges = FALSE
	/// Не более32 derived writes либо notifications за один worker slice.
	var/commit_cursor = 1
	/// Staging индексы ограничены10000 nodes и100000 physical edges.
	var/list/nodes = list()
	/// Address → точный protocol NodeKey; не разрешаем заменённый объект по одному адресу.
	var/list/keys = list()
	/// Только импортированные anchors/LAN IDs, без native nearest вычислений.
	var/list/anchors = list()
	var/list/lans = list()
	/// Неориентированная physical adjacency; relay bucket хранится отдельно.
	var/list/adjacency = list()
	var/list/edges = list()
	var/list/edge_lookup = list()
	/// Имена расположенных real NTnet relays, а не всех gateway node types.
	var/list/relays = list()
	/// Registry представления формируются постранично, поэтому final publication не сканирует все nodes.
	var/list/apcs = list()
	var/list/relay_nodes = list()
	/// Diagnostic one-shot commit также не должен отзывать keys при неизменившейся binding.
	var/list/notification_flags = list()
	/// Routes staging хранит predecessor scalars, не запускает constructor solver.
	var/datum/netrun_path_tree/external/tree

/// Point-query cache удерживает только weak console и exact coordinates, а не turf или native node.
/datum/netrun_external_anchor_cursor
	/// Opaque request ID принадлежит фиксированному producer anchor.
	var/request_id
	/// Weak UI owner позволяет LRU не удерживать закрытые consoles.
	var/datum/weakref/console_ref
	/// Локальный structural generation закрывает окно до подтверждения новых raw facts Host.
	var/generation
	/// Binding и structural metadata проверяются отдельно от outer-frame replay ACK.
	var/binding
	var/graph_version
	var/input_sequence
	/// Selection зависит от APC/sector structure, не от движения чужих endpoints или availability.
	var/infra_stamp
	/// Координаты не удерживают заменённый turf; sector/area взяты из исходного native контекста.
	var/x
	var/y
	var/z
	var/sector
	var/area_id
	/// pending либо ready; ready с null key является отрицательным bounded cache entry.
	var/phase = "pending"
	/// Только exact generation key, без strong node reference в console cache.
	var/list/node_key

/// Кэши ограничены одним graph cursor и шестнадцатью source/mode таблицами текущего binding.
/datum/netrun_external_effects/machines/queries
	/// Authoritative C# hints; structural graph не зависит от availability-only churn.
	var/projection_graph_version = "0"
	var/projection_input_sequence = "0"
	var/projection_availability = "0"
	/// Local signals немедленно отзывают authority до доставки raw fact journal.
	var/projection_generation = "1"
	var/projection_state_generation = "1"
	/// Metadata последнего целиком импортированного graph, отдельные от последних Host hints.
	var/projection_published_generation
	var/projection_published_graph
	var/projection_published_input
	/// Единственный Graph staging предотвращает неограниченное удержание старых таблиц.
	var/datum/netrun_external_projection_cursor/projection_graph_cursor
	/// До16 живых route/graph continuations; dispatcher mappings также bounded.
	var/list/projection_pending = list()
	/// До16 retained source/mode trees; oldest source вытесняется без station scan.
	var/list/projection_trees = list()
	var/list/projection_tree_order = list()
	/// Coalesced pending demands не содержат payload или UI snapshots.
	var/list/projection_demands = list()
	/// До16 source/mode ожиданий по16 weak consoles: готовый async ответ будит только своих читателей.
	var/list/projection_waiters = list()
	/// До16 без-node consoles имеют собственный point context; один producer не расходуется на каждое новое окно.
	var/list/projection_anchors = list()
	var/list/projection_anchor_order = list()
	/// Persistent stream не перезапускает baseline из-за ordinary leaf churn.
	var/datum/netrun_external_graph_cursor/projection_sync
	/// Последний применённый native baseline; только keys/scalars и текущие native nodes.
	var/datum/netrun_external_graph_data/projection_data
	/// Global proofs меняются только при изменениях реальной инфраструктуры и её forwarding availability.
	var/projection_infra_stamp = "0"
	var/projection_av_infra_stamp = "0"
	var/projection_published_infra
	var/projection_published_av_infra
	/// Native presentation generation меняется только при реальной структуре, а не на каждом leaf weight/AV input.
	var/projection_presentation_revision = "0"
	/// NodeKey token → endpoint/infra. До source exporter callback dirty флаг уже запрещает authority.
	var/list/projection_dirty_nodes = list()
	var/projection_dirty_infra = 0
	/// Native binding notifications обрабатываются отдельно по32, а не полным station scan.
	var/list/projection_notifications = list()
	/// Совместимость одноразовой диагностической Graph projection не включается в production prepare path.
	var/projection_stream_mode = FALSE

/// Внешний режим выбирается без IPC до регистрации первого node; local diagnostic mode сохраняет прежний путь.
/proc/netrun_external_projection_mode()
	return SSnetrun?.ensure_external_mode() == "external"

/// Возвращает только доверенный query coordinator текущего binding; отсутствие связи не включает DM fallback.
/proc/netrun_external_projection_executor()
	var/datum/netrun_external_effects/machines/queries/executor = SSnetrun.external_core?.effects
	return istype(executor) ? executor : null

/// Structural authority существует только для целиком импортированного текущего C# graph.
/datum/netrun_external_effects/machines/queries/proc/projection_ready(datum/netrun_external_core/client)
	if(projection_stream_mode)
		return projection_stream_ready(client)
	return client?.ready && !closed && owner?.topology && !owner.topology.dirty && projection_graph_version != "0" && projection_published_generation == projection_generation && projection_published_graph == projection_graph_version && projection_published_input == projection_input_sequence

/// Local physical changes немедленно закрывают authority ещё до отправки raw facts; availability отзывает только trees.
/datum/netrun_external_effects/machines/queries/proc/invalidate_projection(reason = "changed", structural = TRUE, datum/component/netrun_node/node = null, removed = FALSE)
	if(!owner || closed)
		return
	if(projection_stream_mode)
		if(node)
			projection_mark_node(owner?.external_core, node, structural, removed)
		else
			projection_update_dirty(owner?.external_core)
		return
	projection_state_generation = netrun_external_decimal_next(projection_state_generation)
	if(!projection_state_generation)
		owner.external_core?.abort_session("projection_generation_exhausted")
		return
	if(structural)
		projection_waiters.Cut()
		projection_generation = netrun_external_decimal_next(projection_generation)
		if(!projection_generation)
			owner.external_core?.abort_session("projection_generation_exhausted")
			return
		if(owner?.topology)
			owner.topology.dirty = TRUE
		for(var/key in projection_anchor_order.Copy())
			projection_forget_anchor(key)
	for(var/key in projection_trees)
		qdel(projection_trees[key])
	projection_trees.Cut()
	projection_tree_order.Cut()
	for(var/id in projection_pending.Copy())
		var/datum/netrun_external_projection_cursor/cursor = projection_pending[id]
		if(structural || cursor.kind == "routes")
			projection_drop(cursor, TRUE)
	owner.wake_ready_delivery()

/// Retired страницы известного ID ACK-аются dispatcher, но больше не имеют consumer или права публикации.
/datum/netrun_external_effects/machines/queries/proc/projection_drop(datum/netrun_external_projection_cursor/cursor, cancel = FALSE)
	if(QDELETED(cursor))
		return
	projection_pending -= cursor.request_id
	if(cursor.cache_key)
		projection_waiters -= cursor.cache_key
	if(projection_graph_cursor == cursor)
		projection_graph_cursor = null
	forget_query(cursor.request_id, cancel && cursor.phase == "pending" ? "projection_cancel" : null)
	QDEL_NULL(cursor.tree)
	qdel(cursor)

/// Ключ не использует float serial или REF; оба поколения принадлежат текущему protocol binding.
/datum/netrun_external_effects/machines/queries/proc/projection_key(list/key, mode)
	return "[key["id"]]:[key["generation"]]:[mode]"

/// Pending UI чтение сохраняет только weak waiter; готовый cache не порождает подписку или новый query.
/datum/netrun_external_effects/machines/queries/proc/projection_watch(datum/netrun_external_core/client, datum/component/netrun_node/source, datum/netrun_console/console, mode = "discovery")
	if(QDELETED(source) || QDELETED(console) || !client?.ready || closed)
		return
	var/list/key = client.node_key(source)
	if(!key)
		return
	var/cache_key = projection_key(key, mode)
	var/datum/netrun_path_tree/external/tree = projection_trees[cache_key]
	var/pending = !!projection_demands[cache_key]
	if(!pending)
		for(var/id in projection_pending)
			var/datum/netrun_external_projection_cursor/cursor = projection_pending[id]
			if(cursor.cache_key == cache_key)
				pending = TRUE
				break
	if(!pending && tree?.external_current())
		return
	var/list/waiters = projection_waiters[cache_key]
	if(!waiters)
		if(length(projection_waiters) >= 16)
			return
		waiters = list()
		projection_waiters[cache_key] = waiters
	for(var/reference in waiters.Copy())
		var/datum/weakref/waiter = waiters[reference]
		if(!waiter.resolve())
			waiters -= reference
	var/console_reference = REF(console)
	if(length(waiters) < 16 || waiters[console_reference])
		waiters[console_reference] = WEAKREF(console)

/// Completion не сканирует station consoles и не выполняет сериализацию внутри callback.
/datum/netrun_external_effects/machines/queries/proc/projection_wake(cache_key)
	var/list/waiters = projection_waiters[cache_key]
	projection_waiters -= cache_key
	for(var/reference in waiters)
		var/datum/weakref/waiter = waiters[reference]
		var/datum/netrun_console/console = waiter.resolve()
		if(!QDELETED(console))
			console.invalidate_projection_caches()
			console.invalidate_ui()

/// Чтение ставит coalesced demand, но никогда не строит topology/Dijkstra и не авторизует по stale таблице.
/datum/netrun_external_effects/machines/queries/proc/projection_tree(datum/netrun_external_core/client, datum/component/netrun_node/source, mode = "discovery")
	if(QDELETED(source) || !client?.ready || !(mode in list("machine", "discovery")))
		return new /datum/netrun_path_tree
	var/list/key = client.node_key(source)
	if(!key)
		return new /datum/netrun_path_tree
	var/cache_key = projection_key(key, mode)
	var/datum/netrun_path_tree/external/tree = projection_trees[cache_key]
	if(tree?.external_current())
		projection_tree_order -= cache_key
		projection_tree_order += cache_key
		return tree
	if(length(projection_demands) < 16 || projection_demands[cache_key])
		projection_demands[cache_key] = list("key" = key.Copy(), "mode" = mode)
		owner.wake_ready_delivery()
	return new /datum/netrun_path_tree

/// Одна immutable logical команда после source journal; would_block повторяет её dispatcher с прежним ID.
/datum/netrun_external_effects/machines/queries/proc/projection_submit(datum/netrun_external_core/client, kind, list/key = null, mode = "discovery", cache_key = null)
	if(kind == "graph" && projection_stream_mode)
		return FALSE
	if(length(projection_pending) >= 16)
		return FALSE
	var/id = new_query_id("projection")
	if(!id)
		return FALSE
	var/datum/netrun_external_projection_cursor/cursor = new
	cursor.request_id = id
	cursor.kind = kind
	cursor.mode = mode
	cursor.source_key = key?.Copy()
	cursor.cache_key = cache_key
	cursor.generation = projection_generation
	cursor.state_generation = projection_state_generation
	var/source_json = key ? netrun_external_json_object(list("node_id" = json_encode(key["id"]), "generation" = json_encode(key["generation"]))) : "null"
	var/body = netrun_external_json_object(list("kind" = json_encode("projection_query"), "request_id" = json_encode(id), "projection_kind" = json_encode(kind), "source" = source_json, "mode" = json_encode(mode)))
	if(!enqueue_query("projection_query", body, cursor))
		qdel(cursor)
		return FALSE
	projection_pending[id] = cursor
	if(kind == "graph")
		projection_graph_cursor = cursor
	return TRUE

/// Local commit/notification slices ограничены 32 nodes; atomically published graph появляется только после всех binding/LAN writes.
/datum/netrun_external_effects/machines/queries/proc/prepare_projection(datum/netrun_external_core/client)
	if(!client?.ready || closed)
		return FALSE
	if(projection_graph_cursor?.phase == "commit" || projection_graph_cursor?.phase == "notify")
		projection_commit(client, projection_graph_cursor)
		return FALSE
	// Обычный production путь использует persistent stream; legacy one-shot Graph нужен лишь diagnostic callers.
	if(!projection_sync)
		projection_start_stream(client)
	projection_notify_stream(client)
	projection_update_dirty(client)
	if(!projection_ready(client))
		return FALSE
	for(var/cache_key in projection_demands.Copy())
		var/pending = FALSE
		for(var/id in projection_pending)
			var/datum/netrun_external_projection_cursor/cursor = projection_pending[id]
			if(cursor.cache_key == cache_key)
				pending = TRUE
				break
		if(pending)
			continue
		var/list/demand = projection_demands[cache_key]
		var/list/key = demand["key"]
		if(!client.resolve_node(key["id"], key["generation"]))
			projection_demands -= cache_key
			projection_waiters -= cache_key
			continue
		if(projection_submit(client, "routes", key, demand["mode"], cache_key))
			projection_demands -= cache_key
		break
	return FALSE

/// Hints принадлежат C# runtime, а не outer sequence: service-only inputs не делают structural graph новым.
/datum/netrun_external_effects/machines/queries/proc/observe_projection(datum/netrun_external_core/client, list/result, datum/netrun_external_query_command/command)
	if(!owner || closed)
		return
	if(command)
		if(command.kind == "graph_sync_start" || command.kind == "graph_sync_continue")
			var/datum/netrun_external_graph_cursor/cursor = command.consumer?.resolve()
			if(!istype(cursor) || cursor != projection_sync)
				return
			var/list/admission = result["admission"]
			var/list/action = result["action"]
			if((command.kind == "graph_sync_start" && !(admission?["status"] in list("accepted", "duplicate"))) || (command.kind == "graph_sync_continue" && !action?["accepted"]))
				client.abort_session("graph_sync_rejected")
				return
			if(command.kind == "graph_sync_continue")
				cursor.ack_pending = FALSE
				if(cursor.terminal)
					forget_query(cursor.request_id)
					projection_sync = null
					projection_data = null
					qdel(cursor)
					projection_update_dirty(client)
			return
		if(command.kind == "anchor_query")
			projection_observe_anchor(client, result, command)
			return
		var/datum/netrun_external_projection_cursor/cursor = command.consumer?.resolve()
		var/list/admission = result["admission"]
		if(istype(cursor) && !(admission?["status"] in list("accepted", "duplicate")))
			projection_drop(cursor)
		return
	var/version = result["graph_version"]
	var/input = result["graph_input_sequence"]
	var/availability = result["availability_version"]
	if(!netrun_external_valid_decimal(version, TRUE) || !netrun_external_valid_decimal(input, TRUE) || !netrun_external_valid_decimal(availability, TRUE))
		client.abort_session("invalid_projection_hint")
		return
	var/infra_stamp = result["infra_stamp"]
	var/av_infra_stamp = result["av_infra_stamp"]
	if(projection_stream_mode && (!netrun_external_valid_decimal(infra_stamp, TRUE) || !netrun_external_valid_decimal(av_infra_stamp, TRUE)))
		client.abort_session("invalid_projection_hint")
		return
	if(netrun_external_valid_decimal(infra_stamp, TRUE) && netrun_external_valid_decimal(av_infra_stamp, TRUE))
		var/infra_changed = infra_stamp != projection_infra_stamp
		var/av_infra_changed = av_infra_stamp != projection_av_infra_stamp
		projection_infra_stamp = infra_stamp
		projection_av_infra_stamp = av_infra_stamp
		if(projection_stream_mode)
			projection_graph_version = version
			projection_input_sequence = input
			projection_availability = availability
			if(infra_changed)
				projection_generation = netrun_external_decimal_next(projection_generation)
				for(var/cache_key in projection_anchor_order.Copy())
					projection_forget_anchor(cache_key)
			if(infra_changed || av_infra_changed)
				for(var/id in projection_pending.Copy())
					projection_drop(projection_pending[id], TRUE)
				projection_refresh_sources()
			projection_update_dirty(client)
			return
	var/structural = version != projection_graph_version || input != projection_input_sequence
	var/state_changed = availability != projection_availability
	projection_graph_version = version
	projection_input_sequence = input
	projection_availability = availability
	if(structural || state_changed)
		invalidate_projection("runtime_changed", structural)
	if(istype(owner.topology, /datum/netrun_topology/external))
		owner.topology.availability_revision = availability
		owner.topology.transit_availability_revision = availability

/// Строгая page корреляция предотвращает смешивание поколений и частичную публикацию старого query.
/datum/netrun_external_effects/machines/queries/proc/process_projection(datum/netrun_external_core/client, list/result)
	var/datum/netrun_external_projection_cursor/cursor = get_query_consumer(result["request_id"])
	if(!istype(cursor) || projection_pending[cursor.request_id] != cursor || cursor.phase != "pending")
		return FALSE
	var/list/rows = result["rows"]
	if(result["projection_kind"] != cursor.kind || result["page_index"] != cursor.next_page || !islist(rows) || length(rows) > 32 || !netrun_external_valid_decimal(result["graph_version"], TRUE) || !netrun_external_valid_decimal(result["graph_input_sequence"], TRUE) || !netrun_external_valid_decimal(result["availability_version"], TRUE))
		return FALSE
	if(cursor.next_page == "1")
		cursor.graph_version = result["graph_version"]
		cursor.input_sequence = result["graph_input_sequence"]
		cursor.availability_version = result["availability_version"]
		if(projection_stream_mode && cursor.kind == "routes")
			if(!netrun_external_valid_decimal(result["infra_stamp"], TRUE) || !netrun_external_valid_decimal(result["av_infra_stamp"], TRUE) || !netrun_external_valid_decimal(result["source_node_revision"], TRUE))
				return FALSE
			cursor.infra_stamp = result["infra_stamp"]
			cursor.av_infra_stamp = result["av_infra_stamp"]
			cursor.source_revision = result["source_node_revision"]
	else if(cursor.graph_version != result["graph_version"] || cursor.input_sequence != result["graph_input_sequence"] || cursor.availability_version != result["availability_version"])
		return FALSE
	else if(projection_stream_mode && cursor.kind == "routes" && (cursor.infra_stamp != result["infra_stamp"] || cursor.av_infra_stamp != result["av_infra_stamp"] || cursor.source_revision != result["source_node_revision"]))
		return FALSE
	cursor.next_page = netrun_external_decimal_next(cursor.next_page)
	if((cursor.kind == "graph" && !isnull(result["source"])) || (cursor.kind == "routes" && !same_key(result["source"], cursor.source_key, "node_id")))
		return FALSE
	for(var/list/row as anything in rows)
		if(!islist(row) || !projection_row(client, cursor, row))
			return FALSE
	if(!result["complete"])
		return result["code"] == "page"
	var/current_proof
	if(projection_stream_mode && cursor.kind == "routes")
		current_proof = cursor.infra_stamp == projection_infra_stamp && cursor.av_infra_stamp == projection_av_infra_stamp && cursor.source_revision == client.node_revision(cursor.source_key)
	else
		current_proof = cursor.generation == projection_generation && cursor.graph_version == projection_graph_version && cursor.input_sequence == projection_input_sequence && (cursor.kind != "routes" || (cursor.availability_version == projection_availability && cursor.state_generation == projection_state_generation))
	if(result["code"] != "completed" || cursor.invalid || !current_proof)
		projection_drop(cursor)
		return TRUE
	if(cursor.kind == "graph")
		cursor.phase = "commit"
		return TRUE
	var/datum/netrun_path_tree/external/tree = cursor.tree
	if(!tree || !tree.reached[tree.source?.address] || tree.previous[tree.source.address] || tree.costs[tree.source.address] != 0)
		return FALSE
	tree.retained = TRUE
	tree.network_index_ready = TRUE
	tree.revision = cursor.graph_version
	tree.geometry_revision = cursor.graph_version
	tree.availability_revision = cursor.availability_version
	tree.transit_availability_revision = cursor.availability_version
	tree.external_generation = cursor.generation
	tree.external_state_generation = cursor.state_generation
	tree.external_input = cursor.input_sequence
	tree.external_mode = cursor.mode
	tree.external_executor = WEAKREF(src)
	tree.external_binding = client.binding_epoch
	tree.external_source_key = cursor.source_key.Copy()
	tree.external_source_revision = cursor.source_revision
	tree.external_infra_stamp = cursor.infra_stamp
	tree.external_av_infra_stamp = cursor.av_infra_stamp
	tree.external_cache_key = cursor.cache_key
	tree.graph_ref = WEAKREF(owner.get_topology())
	qdel(projection_trees[cursor.cache_key])
	projection_trees[cursor.cache_key] = tree
	projection_tree_order -= cursor.cache_key
	projection_tree_order += cursor.cache_key
	cursor.tree = null
	if(cursor.stale_rows)
		projection_demands[cursor.cache_key] = list("key" = cursor.source_key.Copy(), "mode" = cursor.mode)
	while(length(projection_tree_order) > 16)
		var/oldest = projection_tree_order[1]
		qdel(projection_trees[oldest])
		projection_trees -= oldest
		projection_tree_order.Cut(1, 2)
	projection_wake(cursor.cache_key)
	projection_drop(cursor)
	return TRUE

/// Resolver проверяет exact protocol generation; исчезнувший native объект отзывает таблицу без разрешения по одному адресу.
/datum/netrun_external_effects/machines/queries/proc/projection_resolve(datum/netrun_external_core/client, list/key)
	if(!islist(key) || !istext(key["node_id"]) || !netrun_external_valid_decimal(key["generation"]))
		return null
	return client.resolve_node(key["node_id"], key["generation"])

/// Максимум 32 строки обрабатываются непосредственно в output handler; topology geometry здесь не вычисляется.
/datum/netrun_external_effects/machines/queries/proc/projection_row(datum/netrun_external_core/client, datum/netrun_external_projection_cursor/cursor, list/row)
	var/list/node_key = row["node"]
	if(row["kind"] == "node" && cursor.kind == "graph")
		if(cursor.seen_edges || length(cursor.nodes) >= 10000)
			return FALSE
		var/datum/component/netrun_node/node = projection_resolve(client, row["node"])
		if(QDELETED(node))
			cursor.invalid = TRUE
			return TRUE
		if(cursor.nodes[node.address] || row["address"] != node.address || (!isnull(row["lan_id"]) && !istext(row["lan_id"])))
			return FALSE
		cursor.nodes[node.address] = node
		if(node.node_type == NETRUN_NODE_APC)
			cursor.apcs[node.address] = node
		cursor.keys[node.address] = node_key.Copy()
		cursor.adjacency[node.address] = list()
		cursor.lans[node.address] = row["lan_id"]
		if(row["anchor"])
			var/datum/component/netrun_node/anchor = projection_resolve(client, row["anchor"])
			if(!anchor || anchor.node_type != NETRUN_NODE_APC)
				cursor.invalid = TRUE
			else
				cursor.anchors[node.address] = anchor
		if(row["is_relay"])
			if(!istype(node.parent, /obj/machinery/ntnet_relay))
				return FALSE
			cursor.relays += node.address
			cursor.relay_nodes[node.address] = node
		return TRUE
	if(row["kind"] == "edge" && cursor.kind == "graph")
		cursor.seen_edges = TRUE
		if(length(cursor.edges) >= 100000 || !(row["link_kind"] in list("endpoint", "apc")) || !isnum(row["distance"]) || row["distance"] < 0 || !isnum(row["latency_ds"]) || row["latency_ds"] <= 0 || row["latency_ds"] >= INFINITY)
			return FALSE
		var/datum/component/netrun_node/from_node = projection_resolve(client, row["from"])
		var/datum/component/netrun_node/to_node = projection_resolve(client, row["to"])
		if(!from_node || !to_node || cursor.nodes[from_node.address] != from_node || cursor.nodes[to_node.address] != to_node)
			cursor.invalid = TRUE
			return TRUE
		if(from_node == to_node || cursor.edge_lookup["[from_node.address]>[to_node.address]"])
			return FALSE
		var/list/edge = list("id" = "[row["link_kind"]]:[from_node.address]>[to_node.address]", "from" = from_node.address, "to" = to_node.address, "kind" = row["link_kind"], "distance" = row["distance"], "latency" = row["latency_ds"])
		cursor.edges += list(edge)
		cursor.edge_lookup["[from_node.address]>[to_node.address]"] = edge
		cursor.edge_lookup["[to_node.address]>[from_node.address]"] = edge
		var/list/from_neighbors = cursor.adjacency[from_node.address]
		var/list/to_neighbors = cursor.adjacency[to_node.address]
		from_neighbors += to_node.address
		to_neighbors += from_node.address
		return TRUE
	if(row["kind"] == "route" && cursor.kind == "routes")
		if(!cursor.tree)
			cursor.tree = new /datum/netrun_path_tree/external
			cursor.tree.source = client.resolve_node(cursor.source_key["id"], cursor.source_key["generation"])
		if(length(cursor.tree.reached) >= 10000 || !isnum(row["latency_ds"]) || row["latency_ds"] < 0 || row["latency_ds"] >= INFINITY)
			return FALSE
		var/datum/component/netrun_node/node = projection_resolve(client, row["node"])
		var/datum/component/netrun_node/previous = row["previous"] ? projection_resolve(client, row["previous"]) : null
		if(projection_stream_mode && !netrun_external_valid_decimal(row["node_revision"]))
			return FALSE
		if(!node || (row["previous"] && !previous))
			if(projection_stream_mode)
				cursor.stale_rows = TRUE
			else
				cursor.invalid = TRUE
			return TRUE
		if(cursor.tree.reached[node.address])
			return FALSE
		cursor.tree.reached[node.address] = TRUE
		cursor.tree.previous[node.address] = previous?.address
		cursor.tree.costs[node.address] = row["latency_ds"]
		cursor.tree.remote[node.address] = !!row["quantum"]
		cursor.tree.external_keys[node.address] = node_key.Copy()
		if(projection_stream_mode)
			cursor.tree.external_node_revisions[node.address] = row["node_revision"]
			if(row["node_revision"] != projection_raw_revision(client, row["node"]))
				cursor.stale_rows = TRUE
		if(node.network && !cursor.tree.reached_networks[node.network.id])
			cursor.tree.reached_networks[node.network.id] = node.address
		return TRUE
	return FALSE

/// Два bounded прохода: сначала все derived LAN/binding поля под закрытой authority, затем notification после atomic graph swap.
/datum/netrun_external_effects/machines/queries/proc/projection_commit(datum/netrun_external_core/client, datum/netrun_external_projection_cursor/cursor)
	if(cursor.generation != projection_generation || cursor.graph_version != projection_graph_version || cursor.input_sequence != projection_input_sequence)
		projection_drop(cursor)
		return
	var/stop = min(length(cursor.nodes), cursor.commit_cursor + 31)
	while(!QDELETED(cursor) && projection_graph_cursor == cursor && cursor.commit_cursor <= stop)
		if(QDELETED(cursor) || projection_graph_cursor != cursor)
			return
		var/address = cursor.nodes[cursor.commit_cursor++]
		var/datum/component/netrun_node/node = cursor.nodes[address]
		var/list/key = cursor.keys[address]
		if(QDELETED(node) || client.resolve_node(key["node_id"], key["generation"]) != node)
			cursor.invalid = TRUE
			continue
		if(cursor.phase == "notify")
			node.notify_changed(cursor.notification_flags[address] || NETRUN_CHANGED_STATE)
			// Native listener вправе переместить/удалить node; такой сигнал немедленно отзывает даже этот cursor.
			if(QDELETED(cursor) || projection_graph_cursor != cursor)
				return
			continue
		var/datum/component/netrun_node/anchor = cursor.anchors[address]
		var/lan_id = cursor.lans[address]
		var/datum/netrun_network/network = lan_id ? owner.networks[lan_id] : null
		if(lan_id && !network)
			var/datum/component/netrun_node/profile = node.node_type == NETRUN_NODE_APC ? node : anchor
			var/area/room = profile ? owner.get_topology().apc_area(profile) : null
			network = new(lan_id, room)
			owner.networks[lan_id] = network
		cursor.notification_flags[address] = (node.network != network || node.bound_apc != anchor) ? NETRUN_CHANGED_BINDING : NETRUN_CHANGED_STATE
		if(node.network != network)
			node.leave_network(FALSE)
			node.network = network
			if(network)
				network.nodes += node
		node.bound_apc = anchor
		node.binding_checked = TRUE
		node.binding_infra_revision = cursor.graph_version
		node.topology_turf = node.physical_turf()
		node.binding_area = get_base_area(node.topology_turf)
		node.binding_sector = netrun_sector_for(node.topology_turf)
		node.pending_physical_update = FALSE
	if(QDELETED(cursor) || projection_graph_cursor != cursor)
		return
	if(cursor.commit_cursor <= length(cursor.nodes))
		return
	if(cursor.invalid)
		projection_drop(cursor)
		return
	if(cursor.phase == "notify")
		projection_drop(cursor)
		return
	var/datum/netrun_topology/external/graph = owner.get_topology()
	graph.nodes = cursor.nodes
	graph.adjacency = cursor.adjacency
	graph.forwarding_adjacency = cursor.adjacency
	graph.edges = cursor.edges
	graph.edge_lookup = cursor.edge_lookup
	graph.relay_addresses = cursor.relays
	graph.external_keys = cursor.keys
	graph.registered_apcs = cursor.apcs
	graph.registered_relays = cursor.relay_nodes
	graph.revision = cursor.graph_version
	graph.infrastructure_revision = cursor.graph_version
	graph.weight_revision = cursor.graph_version
	graph.availability_revision = projection_availability
	graph.transit_availability_revision = projection_availability
	graph.dirty = FALSE
	projection_published_generation = projection_generation
	projection_published_graph = cursor.graph_version
	projection_published_input = cursor.input_sequence
	cursor.phase = "notify"
	cursor.commit_cursor = 1
	SEND_SIGNAL(owner, COMSIG_NETRUN_TOPOLOGY_CHANGED, graph.revision)

/// Потеря binding отзывает все client authority до освобождения общих query mappings dispatcher.
/datum/netrun_external_effects/machines/queries/proc/disconnect_projection(datum/netrun_external_core/client, reason)
	if(projection_sync)
		forget_query(projection_sync.request_id)
		qdel(projection_sync)
		projection_sync = null
	projection_data = null
	projection_notifications.Cut()
	projection_dirty_nodes.Cut()
	projection_dirty_infra = 0
	projection_published_infra = null
	projection_published_av_infra = null
	for(var/id in projection_pending.Copy())
		projection_drop(projection_pending[id])
	for(var/key in projection_trees)
		qdel(projection_trees[key])
	projection_trees.Cut()
	projection_tree_order.Cut()
	projection_demands.Cut()
	projection_waiters.Cut()
	for(var/key in projection_anchor_order.Copy())
		projection_forget_anchor(key)
	projection_published_generation = null
	if(owner?.topology)
		owner.topology.dirty = TRUE

/// Удаляет один bounded point slot; уже отправленный read-only запрос может безопасно завершиться без consumer.
/datum/netrun_external_effects/machines/queries/proc/projection_forget_anchor(cache_key)
	var/datum/netrun_external_anchor_cursor/cursor = projection_anchors[cache_key]
	if(cursor)
		forget_query(cursor.request_id)
		qdel(cursor)
	projection_anchors -= cache_key
	projection_anchor_order -= cache_key

/// Source без собственного node получает только подтверждённый C# nearest anchor; pending никогда не сканирует APC локально.
/datum/netrun_external_effects/machines/queries/proc/projection_anchor(datum/netrun_external_core/client, datum/netrun_console/console)
	if(!client?.ready || projection_graph_version == "0" || QDELETED(console))
		return null
	var/turf/position = console.physical_turf()
	if(!position)
		return null
	var/sector = netrun_sector_for(position)
	var/area_id = client.area_key(get_base_area(position))
	var/cache_key = REF(console)
	var/datum/netrun_external_anchor_cursor/cursor = projection_anchors[cache_key]
	var/structure_changed = cursor && (projection_stream_mode ? cursor.infra_stamp != projection_infra_stamp : (cursor.graph_version != projection_graph_version || cursor.input_sequence != projection_input_sequence))
	if(cursor && (cursor.console_ref?.resolve() != console || cursor.binding != client.binding_epoch || cursor.generation != projection_generation || structure_changed || cursor.x != position.x || cursor.y != position.y || cursor.z != position.z || cursor.sector != sector || cursor.area_id != area_id))
		projection_forget_anchor(cache_key)
		cursor = null
	if(cursor)
		projection_anchor_order -= cache_key
		projection_anchor_order += cache_key
		return cursor.phase == "ready" && cursor.node_key ? client.resolve_node(cursor.node_key["node_id"], cursor.node_key["generation"]) : null
	while(length(projection_anchor_order) >= 16)
		projection_forget_anchor(projection_anchor_order[1])
	cursor = new
	cursor.request_id = new_query_id("anchor")
	if(!cursor.request_id)
		qdel(cursor)
		return null
	cursor.console_ref = WEAKREF(console)
	cursor.generation = projection_generation
	cursor.binding = client.binding_epoch
	cursor.graph_version = projection_graph_version
	cursor.input_sequence = projection_input_sequence
	cursor.infra_stamp = projection_infra_stamp
	cursor.x = position.x
	cursor.y = position.y
	cursor.z = position.z
	cursor.sector = sector
	cursor.area_id = area_id
	var/point_json = netrun_external_json_object(list("x" = json_encode(position.x), "y" = json_encode(position.y), "z" = json_encode(position.z)))
	var/body = netrun_external_json_object(list("kind" = json_encode("anchor_query"), "request_id" = json_encode(cursor.request_id), "position" = point_json, "sector_id" = json_encode(sector), "base_area_id" = json_encode(area_id)))
	if(!enqueue_query("anchor_query", body, cursor))
		qdel(cursor)
		return null
	projection_anchors[cache_key] = cursor
	projection_anchor_order += cache_key
	return null

/// Duplicate outer reply может содержать старый nested anchor_result: hints текущего runtime всегда имеют приоритет.
/datum/netrun_external_effects/machines/queries/proc/projection_observe_anchor(datum/netrun_external_core/client, list/result, datum/netrun_external_query_command/command)
	var/datum/netrun_external_anchor_cursor/cursor = command.consumer?.resolve()
	if(!istype(cursor))
		return
	var/datum/netrun_console/console = cursor.console_ref?.resolve()
	var/cache_key = console ? REF(console) : null
	var/list/answer = result["anchor_result"]
	var/turf/position = console?.physical_turf()
	var/structure_changed = projection_stream_mode ? cursor.infra_stamp != projection_infra_stamp : (cursor.graph_version != projection_graph_version || cursor.input_sequence != projection_input_sequence)
	if(!console || projection_anchors[cache_key] != cursor || cursor.generation != projection_generation || cursor.binding != client.binding_epoch || !position || cursor.x != position.x || cursor.y != position.y || cursor.z != position.z || !islist(answer) || answer["request_id"] != cursor.request_id || answer["graph_version"] != projection_graph_version || answer["graph_input_sequence"] != projection_input_sequence || structure_changed)
		if(cache_key)
			projection_forget_anchor(cache_key)
		else
			forget_query(cursor.request_id)
			qdel(cursor)
		return
	forget_query(cursor.request_id)
	if(answer["code"] == "found")
		var/list/node_key = answer["node"]
		var/datum/component/netrun_node/node = projection_resolve(client, node_key)
		if(!node || node.node_type != NETRUN_NODE_APC)
			projection_forget_anchor(cache_key)
			return
		cursor.node_key = node_key.Copy()
	else if(!(answer["code"] in list("not_found", "sector_unknown", "sector_position")))
		projection_forget_anchor(cache_key)
		return
	cursor.phase = "ready"
	console.invalidate_projection_caches()
	console.invalidate_ui()

/// Native graph является импортированной таблицей; любые старые входы rebuild/binding/route solve здесь запрещены.
/datum/netrun_topology/external
	/// Address → protocol generation, используемый authority path validation.
	var/list/external_keys = list()
	/// Weak publication owner и typed data не зависят от глобального SSnetrun в isolated readers/tests.
	var/datum/weakref/external_executor
	var/datum/netrun_external_graph_data/external_data
	/// Address → последняя imported weight revision инцидентных кабелей, для точечного UI edge refresh.
	var/list/external_weight_versions = list()

/// До первой публикации production использует глобального владельца; затем exact weak coordinator.
/datum/netrun_topology/external/proc/projection_owner()
	return external_executor?.resolve() || netrun_external_projection_executor()

/datum/netrun_topology/external/on_node_registered(datum/source, datum/component/netrun_node/node)
	var/datum/netrun_external_effects/machines/queries/executor = projection_owner()
	if(executor?.projection_stream_mode)
		executor.invalidate_projection("registered", TRUE, node)
	else
		invalidate()

/datum/netrun_topology/external/on_node_unregistered(datum/source, datum/component/netrun_node/node)
	if(!node)
		return
	var/datum/netrun_external_effects/machines/queries/executor = projection_owner()
	if(executor?.projection_stream_mode)
		executor.invalidate_projection("removed", TRUE, node, TRUE)
	nodes -= node.address
	external_keys -= node.address
	registered_apcs -= node.address
	registered_relays -= node.address
	if(!executor?.projection_stream_mode)
		invalidate()

/datum/netrun_topology/external/on_node_moved(datum/source, datum/component/netrun_node/node, turf/old_turf, turf/new_turf)
	if(old_turf != new_turf)
		var/datum/netrun_external_effects/machines/queries/executor = projection_owner()
		if(executor?.projection_stream_mode)
			executor.invalidate_projection("movement", TRUE, node)
		else
			invalidate()

/datum/netrun_topology/external/invalidate()
	dirty = TRUE
	var/datum/netrun_external_effects/machines/queries/executor = projection_owner()
	executor?.invalidate_projection()

/datum/netrun_topology/external/availability_changed(datum/component/netrun_node/node, online)
	var/datum/netrun_external_effects/machines/queries/executor = projection_owner()
	executor?.invalidate_projection("availability", FALSE, node)

/datum/netrun_topology/external/infrastructure_changed()
	var/datum/netrun_external_effects/machines/queries/executor = projection_owner()
	// Старые service-registry hints не меняют raw topology: реальные lifecycle/movement события имеют exact node выше.
	if(!executor?.projection_stream_mode)
		invalidate()

/datum/netrun_topology/external/refresh_node(datum/component/netrun_node/node)
	return

/datum/netrun_topology/external/nearest_apc(turf/position)
	// Point query пока не объявлен: произвольный fallback создал бы неподтверждённую authority.
	return null

/datum/netrun_topology/external/rebuild()
	return

/datum/netrun_topology/external/advance_apc_prebuild(max_operations)
	return TRUE

/datum/netrun_topology/external/reconcile_movement()
	return

/datum/netrun_topology/external/reconcile_availability()
	SSnetrun.reconcile_dirty_availability()

/datum/netrun_topology/external/refresh_route_tables(refresh_interval, expiry_interval)
	return

/datum/netrun_topology/external/borrow_infrastructure_tree(datum/component/netrun_node/root, availability_reconciled = FALSE)
	var/datum/netrun_external_effects/machines/queries/executor = netrun_external_projection_executor()
	return executor ? executor.projection_tree(SSnetrun.external_core, root, "machine") : new /datum/netrun_path_tree

/datum/netrun_topology/external/store_route_table(datum/component/netrun_node/start)
	return route_snapshot(start, TRUE)

/datum/netrun_topology/external/route_snapshot(datum/component/netrun_node/start, borrow = FALSE)
	var/datum/netrun_external_effects/machines/queries/executor = netrun_external_projection_executor()
	var/datum/netrun_path_tree/tree = executor ? executor.projection_tree(SSnetrun.external_core, start) : new /datum/netrun_path_tree
	return borrow || !tree.retained ? tree : tree.copy()

/datum/netrun_topology/external/neighbors(address, include_relays = TRUE)
	return dirty ? list() : ..()

/datum/netrun_topology/external/edge_between(first, second)
	if(dirty)
		return null
	if(!external_data)
		return ..()
	var/list/edge = edge_lookup["[first]>[second]"]
	if(edge && external_data.address_keys[edge["from"]] == edge["from_token"] && external_data.address_keys[edge["to"]] == edge["to_token"])
		return edge
	if(first != second && (first in relay_addresses) && (second in relay_addresses) && nodes[first] && nodes[second])
		var/list/pair = sort_list(list(first, second))
		return list("id" = "relay:[pair[1]]>[pair[2]]", "from" = pair[1], "to" = pair[2], "kind" = "relay", "latency" = NETRUN_RELAY_LATENCY)

/// Источник UI не может превратить импортированную таблицу в native Dijkstra через copy/self-healing.
/datum/netrun_path_tree/external
	/// Собственные immutable key values не дают старому адресу разрешиться в новое поколение.
	var/list/external_keys = list()
	/// Weak owner и binding не разрешают request-owned copy ожить после пересоздания IPC session.
	var/datum/weakref/external_executor
	var/external_binding
	/// Source/row proof pins raw fact revisions at solve, не при emit следующей страницы.
	var/list/external_source_key
	var/external_source_revision
	var/list/external_node_revisions = list()
	var/external_infra_stamp
	var/external_av_infra_stamp
	var/external_cache_key
	/// Causal identity состояния, на котором C# построил predecessor table.
	var/external_generation
	var/external_state_generation
	var/external_input
	/// Machine и Discovery применяют разные требования к final online состоянию.
	var/external_mode = "discovery"

/datum/netrun_path_tree/external/proc/external_current()
	var/datum/netrun_external_effects/machines/queries/executor = external_executor?.resolve()
	var/datum/netrun_external_core/client = executor?.owner?.external_core
	if(executor?.projection_stream_mode)
		var/token = executor.projection_token(list("node_id" = external_source_key?["id"], "generation" = external_source_key?["generation"]))
		return client?.binding_epoch == external_binding && executor.projection_stream_ready(client) && external_infra_stamp == executor.projection_infra_stamp && external_av_infra_stamp == executor.projection_av_infra_stamp && external_source_revision == client.node_revision(external_source_key) && !executor.projection_dirty_nodes[token]
	return client?.binding_epoch == external_binding && executor?.projection_ready(client) && graph_ref?.resolve() == executor.owner.topology && executor.projection_generation == external_generation && executor.projection_state_generation == external_state_generation && executor.projection_graph_version == geometry_revision && executor.projection_input_sequence == external_input && executor.projection_availability == availability_revision

/datum/netrun_path_tree/external/path_available(datum/netrun_topology/graph, address)
	if(!external_current() || !graph || graph_ref?.resolve() != graph || !reached[address] || graph.dirty)
		return FALSE
	var/destination = address
	var/datum/netrun_external_effects/machines/queries/executor = external_executor?.resolve()
	var/datum/netrun_external_core/client = executor.owner.external_core
	var/datum/netrun_topology/external/external_graph = graph
	if(executor.projection_stream_mode)
		if(!istype(external_graph) || !external_graph.external_data)
			return FALSE
		var/list/target_key = external_keys[address]
		if(!target_key || executor.projection_dirty_nodes[executor.projection_token(target_key)] || external_node_revisions[address] != executor.projection_raw_revision(client, target_key))
			return FALSE
	for(var/step in 1 to min(10001, length(reached) + 1))
		var/list/key = external_keys[address]
		var/datum/component/netrun_node/node = client.resolve_node(key?["node_id"], key?["generation"])
		if(QDELETED(node) || graph.nodes[address] != node || (external_mode == "machine" && !node.is_online()))
			return FALSE
		var/parent_address = previous[address]
		if(!parent_address)
			return node == source
		var/list/parent_key = external_keys[parent_address]
		var/datum/component/netrun_node/parent_node = client.resolve_node(parent_key?["node_id"], parent_key?["generation"])
		if(QDELETED(parent_node) || !parent_node.is_online() || (address != destination && !node.is_online()))
			return FALSE
		var/list/edge = graph.edge_lookup["[parent_address]>[address]"]
		if(executor.projection_stream_mode && edge && (external_graph.external_data.address_keys[edge["from"]] != edge["from_token"] || external_graph.external_data.address_keys[edge["to"]] != edge["to_token"]))
			edge = null
		if(!edge || edge["latency"] != costs[address] - costs[parent_address])
			if(!netrun_quantum_link(parent_node, node) || SSnetworks.station_network.setting_disabled)
				return FALSE
			var/obj/machinery/ntnet_relay/first = parent_node.parent
			var/obj/machinery/ntnet_relay/second = node.parent
			if(!first.is_operational() || !second.is_operational())
				return FALSE
		address = parent_address
	return FALSE

/datum/netrun_path_tree/external/network_available(datum/netrun_topology/graph, datum/netrun_network/network)
	if(!external_current())
		return FALSE
	var/address = reached_networks[network.id]
	return address && path_available(graph, address)

/datum/netrun_path_tree/external/addresses_to(address)
	if(!path_available(graph_ref?.resolve(), address))
		return list()
	var/list/path = list()
	for(var/step in 1 to length(reached))
		path += address
		address = previous[address]
		if(!address)
			reverseRange(path)
			return path
	return list()

/// Wireless-zone policy отсекает remote entries уже вычисленного C# tree без копирования станции и без native solve.
/datum/netrun_path_tree/external/proc/external_local_copy()
	var/datum/netrun_path_tree/external/local = new
	if(!external_current() || !source || !reached[source.address])
		return local
	local.source = source
	local.graph_ref = graph_ref
	local.external_executor = external_executor
	local.external_binding = external_binding
	local.external_source_key = external_source_key?.Copy()
	local.external_source_revision = external_source_revision
	local.external_infra_stamp = external_infra_stamp
	local.external_av_infra_stamp = external_av_infra_stamp
	local.external_cache_key = external_cache_key
	local.revision = revision
	local.geometry_revision = geometry_revision
	local.availability_revision = availability_revision
	local.transit_availability_revision = transit_availability_revision
	local.external_generation = external_generation
	local.external_state_generation = external_state_generation
	local.external_input = external_input
	local.external_mode = external_mode
	local.reached[source.address] = TRUE
	local.costs[source.address] = 0
	local.external_keys[source.address] = external_keys[source.address]
	local.external_node_revisions[source.address] = external_node_revisions[source.address]
	local.network_index_ready = TRUE
	if(source.network)
		local.reached_networks[source.network.id] = source.address
	return local

/datum/netrun_path_tree/external/copy()
	var/datum/netrun_path_tree/external/copy = new
	copy.source = source
	copy.revision = revision
	copy.geometry_revision = geometry_revision
	copy.availability_revision = availability_revision
	copy.transit_availability_revision = transit_availability_revision
	copy.graph_ref = graph_ref
	copy.external_executor = external_executor
	copy.external_binding = external_binding
	copy.external_source_key = external_source_key?.Copy()
	copy.external_source_revision = external_source_revision
	copy.external_node_revisions = external_node_revisions.Copy()
	copy.external_infra_stamp = external_infra_stamp
	copy.external_av_infra_stamp = external_av_infra_stamp
	copy.external_cache_key = external_cache_key
	copy.reached = reached.Copy()
	copy.previous = previous.Copy()
	copy.costs = costs.Copy()
	copy.remote = remote.Copy()
	copy.reached_networks = reached_networks.Copy()
	copy.network_index_ready = network_index_ready
	copy.external_keys = external_keys.Copy()
	copy.external_generation = external_generation
	copy.external_state_generation = external_state_generation
	copy.external_input = external_input
	copy.external_mode = external_mode
	return copy

/// Одна bounded native таблица baseline: исторические keys разрешены даже после исчезновения weak native объекта.
/datum/netrun_external_graph_data
	/// Protocol token → полный node row с captured revision и endpoint proof.
	var/list/records = list()
	/// Native address → exact protocol token; старое удаление не снимает замену с тем же адресом.
	var/list/address_keys = list()
	/// Native compatibility key map также обновляется exact-owner removal, не поиском по всем nodes.
	var/list/keys = list()
	/// Совместимые read-only представления для прежних UI/NPC gameplay readers.
	var/list/nodes = list()
	var/list/adjacency = list()
	var/list/edges = list()
	var/list/edge_lookup = list()
	/// O(1) swap-delete physical edge без поиска по station-wide списку.
	var/list/edge_positions = list()
	var/list/edges_by_id = list()
	/// Отдельные native registries, без materialized relay clique.
	var/list/apcs = list()
	var/list/relays = list()
	/// Batch-local flags и target revision отделяют UI structure от изменившейся стоимости прежнего кабеля.
	var/structure_changed = FALSE
	var/target_version
	var/list/weight_versions = list()

/// Persistent stream удерживает initial staging либо одну изменяемую ACKed baseline таблицу, без истории snapshots.
/datum/netrun_external_graph_cursor
	/// Корреляция persistent producer request и его binding.
	var/request_id
	var/binding
	/// Exact positive page sequence; одна apply страница ожидает один explicit Continue ACK.
	var/next_page = "1"
	var/last_page
	var/last_hash
	var/ack_pending = FALSE
	/// Frozen batch metadata не меняются до batch_complete.
	var/in_batch = FALSE
	var/phase
	var/from_version
	var/target_version
	var/target_input
	var/infra_stamp
	var/av_infra_stamp
	/// Только batch barrier меняет baseline version; successful stream остаётся живым.
	var/baseline_version = "0"
	var/has_baseline = FALSE
	var/terminal = FALSE
	var/datum/netrun_external_graph_data/data

/// Exact wire token не зависит от native address, float или weakref identity.
/datum/netrun_external_effects/machines/queries/proc/projection_token(list/key)
	if(!islist(key) || !istext(key["node_id"]) || !length(key["node_id"]) || length(key["node_id"]) > 128 || !netrun_external_valid_decimal(key["generation"]))
		return null
	return "[key["node_id"]]|[key["generation"]]"

/// Читает authoritative raw revision конкретного native generation, а не structural snapshot metadata.
/datum/netrun_external_effects/machines/queries/proc/projection_raw_revision(datum/netrun_external_core/client, list/key)
	return client.node_revision(list("id" = key?["node_id"], "generation" = key?["generation"]))

/// Live dirty помечается до exporter callback; для известного endpoint не отзывает unrelated paths.
/datum/netrun_external_effects/machines/queries/proc/projection_mark_node(datum/netrun_external_core/client, datum/component/netrun_node/node, structural = TRUE, removed = FALSE)
	if(!client || !node)
		return
	var/list/metadata = client.node_metadata[node]
	var/list/key = metadata ? list("node_id" = metadata["id"], "generation" = "1") : null
	if(removed && key)
		var/list/source_key = list("id" = key["node_id"], "generation" = key["generation"])
		projection_waiters -= projection_key(source_key, "machine")
		projection_waiters -= projection_key(source_key, "discovery")
	var/datum/netrun_external_graph_data/known_data = projection_data || projection_sync?.data
	var/token = projection_token(key) || known_data?.address_keys[node.address]
	if(!token)
		return
	var/list/record = known_data?.records[token]
	if(removed && !record)
		projection_clear_dirty(token)
		return
	var/infra = !record || !record["is_endpoint"] || client.node_is_forwarder(node)
	if(infra && projection_dirty_nodes[token] != "infra")
		projection_dirty_infra++
	projection_dirty_nodes[token] = infra ? "infra" : "endpoint"
	if(infra && structural)
		projection_generation = netrun_external_decimal_next(projection_generation)
		if(!projection_generation)
			client.abort_session("projection_generation_exhausted")
			return
		for(var/cache_key in projection_anchor_order.Copy())
			projection_forget_anchor(cache_key)
	projection_refresh_sources()
	projection_update_dirty(client)
	owner?.wake_ready_delivery()

/// Снятие dirty допустимо только после exact-current upsert либо exact generation tombstone.
/datum/netrun_external_effects/machines/queries/proc/projection_clear_dirty(token)
	if(projection_dirty_nodes[token] == "infra")
		projection_dirty_infra--
	projection_dirty_nodes -= token

/// O(active source caches), максимум16: листовые изменения не заставляют read query сканировать всю станцию.
/datum/netrun_external_effects/machines/queries/proc/projection_refresh_sources()
	for(var/cache_key in projection_trees)
		var/datum/netrun_path_tree/external/tree = projection_trees[cache_key]
		if(tree.external_source_key)
			projection_demands[cache_key] = list("key" = tree.external_source_key.Copy(), "mode" = tree.external_mode)

/// Native adjacency закрывается только для неготовой инфраструктуры, а не при каждом ordinary leaf move.
/datum/netrun_external_effects/machines/queries/proc/projection_update_dirty(datum/netrun_external_core/client)
	if(owner?.topology)
		owner.topology.dirty = !projection_stream_ready(client)

/// Прошедшие source infra facts и опубликованные stamps являются authority barrier для импортированной геометрии.
/datum/netrun_external_effects/machines/queries/proc/projection_stream_ready(datum/netrun_external_core/client)
	return owner && client?.ready && !closed && projection_sync?.has_baseline && projection_data && projection_dirty_infra == 0 && client.infrastructure_facts_ready() && projection_infra_stamp != "0" && projection_published_infra == projection_infra_stamp && projection_published_av_infra == projection_av_infra_stamp

/// Один stream start; никакое движение leaf не отменяет уже передаваемый historical baseline.
/datum/netrun_external_effects/machines/queries/proc/projection_start_stream(datum/netrun_external_core/client)
	if(projection_sync || !client?.ready || closed || !owner)
		return FALSE
	var/datum/netrun_external_graph_cursor/cursor = new
	cursor.request_id = new_query_id("projection")
	cursor.binding = client.binding_epoch
	if(!cursor.request_id)
		qdel(cursor)
		return FALSE
	var/body = netrun_external_json_object(list("kind" = json_encode("graph_sync_start"), "request_id" = json_encode(cursor.request_id)))
	if(!enqueue_query("graph_sync_start", body, cursor))
		qdel(cursor)
		return FALSE
	projection_stream_mode = TRUE
	projection_sync = cursor
	return TRUE

/// Explicit Continue отправляется лишь после завершения всех ≤32 native apply операций этой страницы.
/datum/netrun_external_effects/machines/queries/proc/projection_continue_stream(datum/netrun_external_graph_cursor/cursor)
	var/body = netrun_external_json_object(list("kind" = json_encode("graph_sync_continue"), "request_id" = json_encode(cursor.request_id), "page_index" = json_encode(cursor.last_page)))
	if(!enqueue_query("graph_sync_continue", body, cursor))
		owner?.external_core?.abort_session("graph_sync_ack_pressure")
		return FALSE
	cursor.ack_pending = TRUE
	return TRUE

/// Persistent page проверяется и применяется ровно один раз; output socket ACK не заменяет native apply ACK.
/datum/netrun_external_effects/machines/queries/proc/process_graph_sync(datum/netrun_external_core/client, list/result)
	var/datum/netrun_external_graph_cursor/cursor = get_query_consumer(result["request_id"])
	if(!istype(cursor) || cursor != projection_sync || cursor.binding != client.binding_epoch)
		return FALSE
	var/index = result["page_index"]
	var/hash = rustg_hash_string(RUSTG_HASH_SHA256, json_encode(result))
	if(index == cursor.last_page)
		return hash == cursor.last_hash
	if(cursor.ack_pending)
		return FALSE
	var/list/operations = result["operations"]
	var/code = result["code"]
	if(!netrun_external_valid_decimal(index) || !islist(operations) || length(operations) > 32 || !(result["phase"] in list("snapshot", "delta")))
		return FALSE
	if(index != cursor.next_page && !(code == "cancelled" && netrun_external_decimal_compare(index, cursor.next_page) > 0))
		return FALSE
	for(var/field in list("from_graph_version", "graph_version", "graph_input_sequence", "infra_stamp", "av_infra_stamp"))
		if(!netrun_external_valid_decimal(result[field], TRUE))
			return FALSE
	if(!(code in list("page", "completed")))
		if(length(operations))
			return FALSE
		cursor.terminal = TRUE
	else
		if(!cursor.in_batch)
			if((!cursor.has_baseline && (result["phase"] != "snapshot" || result["from_graph_version"] != "0")) || (cursor.has_baseline && (result["phase"] != "delta" || result["from_graph_version"] != cursor.baseline_version)))
				return FALSE
			cursor.in_batch = TRUE
			cursor.phase = result["phase"]
			cursor.from_version = result["from_graph_version"]
			cursor.target_version = result["graph_version"]
			cursor.target_input = result["graph_input_sequence"]
			cursor.infra_stamp = result["infra_stamp"]
			cursor.av_infra_stamp = result["av_infra_stamp"]
			if(!cursor.has_baseline)
				cursor.data = new
				cursor.data.structure_changed = TRUE
			else
				cursor.data.structure_changed = FALSE
			cursor.data.target_version = cursor.target_version
		else if(cursor.phase != result["phase"] || cursor.from_version != result["from_graph_version"] || cursor.target_version != result["graph_version"] || cursor.target_input != result["graph_input_sequence"] || cursor.infra_stamp != result["infra_stamp"] || cursor.av_infra_stamp != result["av_infra_stamp"])
			return FALSE
		for(var/list/operation as anything in operations)
			if(!islist(operation) || !projection_apply_operation(client, cursor.data, operation))
				return FALSE
		if(result["batch_complete"])
			if(code != "completed")
				return FALSE
			cursor.in_batch = FALSE
			cursor.has_baseline = TRUE
			cursor.baseline_version = cursor.target_version
			projection_data = cursor.data
			projection_publish_stream(client, cursor)
		else if(code != "page")
			return FALSE
	cursor.last_page = index
	cursor.last_hash = hash
	cursor.next_page = netrun_external_decimal_next(index)
	if(!cursor.next_page)
		return FALSE
	return projection_continue_stream(cursor)

/// Opaque edge IDs проверяются до использования как bounded hash keys; address parsing не требуется.
/datum/netrun_external_effects/machines/queries/proc/projection_edge_id(value)
	if(!istext(value) || length(value) != 64)
		return FALSE
	for(var/index in 1 to 64)
		if(!findtext("0123456789abcdef", copytext(value, index, index + 1)))
			return FALSE
	return TRUE

/// Typed delta применяется без вычисления геометрии/nearest; ordering remove → node upsert → edge upsert задаёт C#.
/datum/netrun_external_effects/machines/queries/proc/projection_apply_operation(datum/netrun_external_core/client, datum/netrun_external_graph_data/data, list/operation)
	var/kind = operation["kind"]
	if(kind == "edge_remove")
		if(!projection_edge_id(operation["edge_id"]))
			return FALSE
		projection_remove_edge(data, operation["edge_id"])
		return TRUE
	if(kind == "node_remove")
		var/token = projection_token(operation["node"])
		if(!token)
			return FALSE
		var/list/previous = data.records[token]
		if(previous && data.address_keys[previous["address"]] == token)
			var/address = previous["address"]
			data.address_keys -= address
			data.nodes -= address
			data.keys -= address
			data.adjacency -= address
			data.apcs -= address
			data.relays -= address
			data.weight_versions -= address
		if(previous)
			data.structure_changed = TRUE
		data.records -= token
		projection_clear_dirty(token)
		projection_refresh_sources()
		return TRUE
	if(kind == "node_upsert")
		var/token = projection_token(operation["node"])
		if(!token || !netrun_external_valid_decimal(operation["node_revision"]) || !istext(operation["address"]) || !length(operation["address"]) || length(operation["address"]) > 256 || (!isnull(operation["lan_id"]) && (!istext(operation["lan_id"]) || length(operation["lan_id"]) > 512)) || (operation["anchor"] && !projection_token(operation["anchor"])))
			return FALSE
		if(!data.records[token] && length(data.records) >= 10000)
			return FALSE
		var/list/previous = data.records[token]
		var/address = operation["address"]
		if(!previous || previous["address"] != address || projection_token(previous["anchor"]) != projection_token(operation["anchor"]) || previous["lan_id"] != operation["lan_id"] || previous["is_relay"] != operation["is_relay"] || previous["is_endpoint"] != operation["is_endpoint"])
			data.structure_changed = TRUE
		if(previous && previous["address"] != address && data.address_keys[previous["address"]] == token)
			data.nodes -= previous["address"]
			data.keys -= previous["address"]
			data.address_keys -= previous["address"]
			data.apcs -= previous["address"]
			data.relays -= previous["address"]
			data.weight_versions -= previous["address"]
		data.records[token] = operation.Copy()
		data.address_keys[address] = token
		var/list/node_key = operation["node"]
		data.keys[address] = node_key.Copy()
		if(!data.adjacency[address])
			data.adjacency[address] = list()
		var/datum/component/netrun_node/node = projection_resolve(client, operation["node"])
		if(node)
			var/current_revision = projection_raw_revision(client, operation["node"]) == operation["node_revision"]
			if(current_revision && (node.address != address || (operation["is_relay"] && !istype(node.parent, /obj/machinery/ntnet_relay)) || (operation["is_endpoint"] && client.node_is_forwarder(node))))
				return FALSE
			data.nodes[address] = node
			if(node.node_type == NETRUN_NODE_APC)
				data.apcs[address] = node
			if(operation["is_relay"] && istype(node.parent, /obj/machinery/ntnet_relay))
				data.relays[address] = node
			else
				data.relays -= address
			if(operation["is_endpoint"] && !client.node_is_forwarder(node) && projection_dirty_nodes[token] == "infra")
				// Historical endpoint proof достаточно для снятия unknown-role global gate, но не его собственного dirty guard.
				projection_dirty_infra--
				projection_dirty_nodes[token] = "endpoint"
			if(current_revision)
				projection_clear_dirty(token)
				var/flags = projection_apply_binding(client, node, operation)
				if(flags)
					projection_queue_notification(operation["node"], flags)
		else
			// Исторический baseline не обязан иметь живой native weakref; следующая delta удалит identity.
			data.nodes -= address
		if(!previous || previous["node_revision"] != operation["node_revision"])
			projection_refresh_sources()
		return TRUE
	if(kind == "edge_upsert")
		var/id = operation["edge_id"]
		var/from_token = projection_token(operation["from"])
		var/to_token = projection_token(operation["to"])
		var/list/from_record = data.records[from_token]
		var/list/to_record = data.records[to_token]
		if(!projection_edge_id(id) || !from_token || !to_token || from_token == to_token || !from_record || !to_record || !(operation["link_kind"] in list("apc", "endpoint")) || !isnum(operation["distance"]) || operation["distance"] < 0 || !isnum(operation["latency_ds"]) || operation["latency_ds"] <= 0 || operation["latency_ds"] >= INFINITY)
			return FALSE
		if(!data.edges_by_id[id] && length(data.edges) >= 100000)
			return FALSE
		var/list/old_edge = data.edges_by_id[id]
		var/first = from_record["address"]
		var/second = to_record["address"]
		if(!old_edge || old_edge["from_token"] != from_token || old_edge["to_token"] != to_token || old_edge["kind"] != operation["link_kind"] || old_edge["from"] != first || old_edge["to"] != second)
			data.structure_changed = TRUE
		var/weight_changed = old_edge && (old_edge["distance"] != operation["distance"] || old_edge["latency"] != operation["latency_ds"])
		projection_remove_edge(data, id, FALSE)
		var/list/edge = list("id" = id, "from" = first, "to" = second, "from_token" = from_token, "to_token" = to_token,
			"kind" = operation["link_kind"], "distance" = operation["distance"], "latency" = operation["latency_ds"])
		data.edges += list(edge)
		data.edges_by_id[id] = edge
		data.edge_positions[id] = length(data.edges)
		data.edge_lookup["[first]>[second]"] = edge
		data.edge_lookup["[second]>[first]"] = edge
		var/list/first_neighbors = data.adjacency[first]
		var/list/second_neighbors = data.adjacency[second]
		first_neighbors[second] = id
		second_neighbors[first] = id
		if(weight_changed)
			data.weight_versions[first] = data.target_version
			data.weight_versions[second] = data.target_version
			projection_queue_notification(from_record["node"], NETRUN_CHANGED_STATE)
			projection_queue_notification(to_record["node"], NETRUN_CHANGED_STATE)
		return TRUE
	return FALSE

/// Swap-delete и associative adjacency дают O(1) physical edge removal, включая заменённые address owners.
/datum/netrun_external_effects/machines/queries/proc/projection_remove_edge(datum/netrun_external_graph_data/data, id, structural = TRUE)
	var/list/edge = data.edges_by_id[id]
	if(!edge)
		return
	if(structural)
		data.structure_changed = TRUE
	var/position = data.edge_positions[id]
	var/list/last = data.edges[length(data.edges)]
	data.edges[position] = last
	data.edge_positions[last["id"]] = position
	data.edges.Cut(length(data.edges), length(data.edges) + 1)
	data.edges_by_id -= id
	data.edge_positions -= id
	if(data.edge_lookup["[edge["from"]]>[edge["to"]]"] == edge)
		data.edge_lookup -= "[edge["from"]]>[edge["to"]]"
		data.edge_lookup -= "[edge["to"]]>[edge["from"]]"
	var/list/first_neighbors = data.adjacency[edge["from"]]
	var/list/second_neighbors = data.adjacency[edge["to"]]
	if(first_neighbors?[edge["to"]] == id)
		first_neighbors -= edge["to"]
	if(second_neighbors?[edge["from"]] == id)
		second_neighbors -= edge["from"]

/// Derived binding пишется только при совпадении latest native raw fact revision; historical snapshot не откатывает moved endpoint.
/datum/netrun_external_effects/machines/queries/proc/projection_apply_binding(datum/netrun_external_core/client, datum/component/netrun_node/node, list/operation)
	var/datum/component/netrun_node/anchor = operation["anchor"] ? projection_resolve(client, operation["anchor"]) : null
	if(operation["anchor"] && (!anchor || anchor.node_type != NETRUN_NODE_APC))
		return 0
	var/lan_id = operation["lan_id"]
	var/datum/netrun_network/network = lan_id ? owner.networks[lan_id] : null
	if(lan_id && !network)
		var/datum/component/netrun_node/profile = node.node_type == NETRUN_NODE_APC ? node : anchor
		var/area/room = profile ? owner.get_topology().apc_area(profile) : null
		network = new(lan_id, room)
		owner.networks[lan_id] = network
	var/binding_changed = node.network != network || node.bound_apc != anchor
	if(node.network != network)
		node.leave_network(FALSE)
		node.network = network
		if(network)
			network.nodes += node
	node.bound_apc = anchor
	node.binding_checked = TRUE
	node.topology_turf = node.physical_turf()
	node.binding_area = get_base_area(node.topology_turf)
	node.binding_sector = netrun_sector_for(node.topology_turf)
	node.pending_physical_update = FALSE
	return binding_changed ? NETRUN_CHANGED_BINDING : NETRUN_CHANGED_STATE

/// Flags coalesce по exact key; unchanged binding не может случайно отозвать access_key_epoch.
/datum/netrun_external_effects/machines/queries/proc/projection_queue_notification(list/key, flags)
	var/token = projection_token(key)
	if(!token)
		return
	var/list/previous = projection_notifications[token]
	projection_notifications[token] = list("key" = key.Copy(), "flags" = flags | (previous?["flags"] || 0))

/// Batch barrier заменяет только pointers и stamps; никакого O(N) native commit sweep здесь нет.
/datum/netrun_external_effects/machines/queries/proc/projection_publish_stream(datum/netrun_external_core/client, datum/netrun_external_graph_cursor/cursor)
	var/datum/netrun_topology/external/graph = owner.get_topology()
	var/datum/netrun_external_graph_data/data = cursor.data
	graph.nodes = data.nodes
	graph.adjacency = data.adjacency
	graph.forwarding_adjacency = data.adjacency
	graph.edges = data.edges
	graph.edge_lookup = data.edge_lookup
	graph.edge_positions = data.edge_positions
	graph.external_keys = data.keys
	graph.external_executor = WEAKREF(src)
	graph.external_data = data
	graph.external_weight_versions = data.weight_versions
	graph.registered_apcs = data.apcs
	graph.registered_relays = data.relays
	graph.relay_addresses = data.relays
	var/structure_changed = !projection_published_infra || projection_published_infra != cursor.infra_stamp || data.structure_changed
	if(structure_changed)
		projection_presentation_revision = netrun_external_decimal_next(projection_presentation_revision)
		if(!projection_presentation_revision)
			client.abort_session("projection_generation_exhausted")
			return
	graph.revision = projection_presentation_revision
	graph.infrastructure_revision = cursor.infra_stamp
	graph.weight_revision = cursor.target_version
	graph.availability_revision = projection_availability
	graph.transit_availability_revision = cursor.av_infra_stamp
	projection_published_infra = cursor.infra_stamp
	projection_published_av_infra = cursor.av_infra_stamp
	projection_update_dirty(client)
	if(structure_changed)
		SEND_SIGNAL(owner, COMSIG_NETRUN_TOPOLOGY_CHANGED, graph.revision)

/// Отложенные derived notifications имеют тот же32-node budget и не скрывают реальный reentrant movement.
/datum/netrun_external_effects/machines/queries/proc/projection_notify_stream(datum/netrun_external_core/client)
	if(!projection_data || projection_sync?.in_batch || !owner || closed)
		return
	var/work = 0
	while(length(projection_notifications) && work++ < 32)
		var/token = projection_notifications[1]
		var/list/notification = projection_notifications[token]
		var/list/key = notification["key"]
		projection_notifications -= token
		var/datum/component/netrun_node/node = projection_resolve(client, key)
		var/list/record = projection_data?.records[token]
		if(node && record && record["node_revision"] == projection_raw_revision(client, key))
			node.notify_changed(notification["flags"])
