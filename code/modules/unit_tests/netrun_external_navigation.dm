/// Scene fixtures declare the raw registry before the production cursor captures its capacity.
/// This mirrors their supplied imported graph; it never derives edges, access, or a route.
/datum/netrun_external_core/fixture/scene_bus/request_entity_navigation(datum/netrun_entity_navigation/navigation, datum/component/netrun_node/target, manual_move = FALSE, direct_only = FALSE, relay_only = FALSE)
	var/datum/netrun_external_fixture/scene_bus/bus = bus_ref?.resolve()
	var/datum/netrun_route_scene/scene = bus?.scene_ref?.resolve()
	if(scene?.fixture_graph)
		owner.nodes_by_address = scene.fixture_graph.nodes.Copy()
		owner.networks = list()
		for(var/address in owner.nodes_by_address)
			var/datum/component/netrun_node/node = owner.nodes_by_address[address]
			if(node.network)
				owner.networks[node.network.id] = node.network
			export_node(node, TRUE)
		var/datum/netrun_external_effects/machines/queries/executor = effects
		if(executor.projection_graph_version == "0")
			executor.projection_graph_version = "1"
	return ..(navigation, target, manual_move, direct_only, relay_only)

/// Supplied Core pages exercise production continuations; fixtures never search for a route.
/datum/unit_test/proc/netrun_navigation_wait_request(mob/camera/netrun_entity/entity, timeout = 5 SECONDS)
	var/deadline = world.time + timeout
	while(!QDELETED(entity) && world.time < deadline)
		var/datum/netrun_external_navigation_request/request = entity.navigation?.external_request
		if(QDELETED(request))
			return null
		if(request.request_id)
			return request
		sleep(world.tick_lag)
	return null

/// Wire nodes retain generation; an address is converted only by the fixture producer.
/datum/unit_test/proc/netrun_navigation_page(datum/netrun_external_core/client, datum/netrun_external_navigation_request/request, list/path, page_index = "1", complete = TRUE, code = null)
	var/list/nodes = list()
	for(var/datum/component/netrun_node/node as anything in path)
		var/list/key = client.node_key(node)
		nodes += list(list("node_id" = key["id"], "generation" = key["generation"]))
	var/datum/netrun_external_effects/machines/queries/executor = client.effects
	// The scene bus declares its imported graph; this is supplied metadata, never a local solve.
	if(executor.projection_graph_version == "0")
		executor.projection_graph_version = "1"
	return list("kind" = "entity_navigation_page", "binding_epoch" = client.binding_epoch, "request_id" = request.request_id,
		"actor" = request.actor_key.Copy(), "actor_revision" = request.actor_revision,
		"source" = request.source_key.Copy(), "destination" = request.destination_key.Copy(),
		"graph_version" = executor.projection_graph_version, "graph_input_sequence" = executor.projection_input_sequence,
		"availability_version" = executor.projection_availability, "page_index" = page_index,
		"nodes" = nodes, "complete" = complete, "code" = code || (complete ? "completed" : "page"))

/// Existing native movement tests supply an explicit remote path before checking per-hop behavior.
/datum/unit_test/proc/netrun_navigation_outcome_details(mob/camera/netrun_entity/entity, datum/netrun_external_navigation_request/request = null, datum/netrun_external_core/client = null)
	var/datum/netrun_entity_navigation/navigation = entity?.navigation
	var/datum/netrun_console/console = entity?.console
	var/list/last_line = length(console?.log) ? console.log[length(console.log)] : null
	var/details = "host=[entity?.host_node?.address], queue=[length(navigation?.queue)], timer=[!!navigation?.timer], pending=[!!navigation?.external_request], last_log=[last_line?["text"]]"
	if(request && client)
		var/datum/netrun_external_effects/machines/queries/executor = client.effects
		var/source_matches = client.resolve_node(request.source_key?["node_id"], request.source_key?["generation"]) == entity?.host_node
		var/destination_resolves = !!client.resolve_node(request.destination_key?["node_id"], request.destination_key?["generation"])
		// Capture causal counters before the diagnostic export yields; never print raw credentials or their hash.
		details += ", fact_tail=[request.fact_tail]/[client.fact_tail], graph=[request.graph_version]/[executor?.projection_graph_version], input=[request.graph_input_sequence]/[executor?.projection_input_sequence], availability=[request.availability_version]/[executor?.projection_availability], binding=[request.binding]/[client.binding_epoch], ready=[client.ready], source_matches=[source_matches], destination_resolves=[destination_resolves]"
		var/raw_access = client.ready && !QDELETED(console) ? client.entity_access_json(console) : null
		var/access_matches = !!raw_access && md5(raw_access) == request.access_hash
		details += ", fresh_access_matches=[access_matches]"
	return details

/datum/unit_test/proc/netrun_supply_navigation(mob/camera/netrun_entity/entity, list/path, code = "completed")
	var/datum/netrun_external_core/fixture/scene_bus/scene_client = SSnetrun.external_core
	var/datum/netrun_external_fixture/scene_bus/bus = istype(scene_client) ? scene_client.bus_ref?.resolve() : null
	var/auto_pump = bus?.auto_pump
	if(bus)
		// This test supplies its own response; the ordinary scene pump must not consume the pending query.
		bus.auto_pump = FALSE
	var/remaining_cooldown = max(0, entity.next_hop - world.time)
	var/drive_first_hop = remaining_cooldown == 0
	// Freeze the native fixture clock while preparation and the supplied response yield.
	entity.next_hop = world.time + 1 MINUTES
	var/datum/netrun_external_navigation_request/request = netrun_navigation_wait_request(entity)
	if(QDELETED(request))
		entity.next_hop = world.time + remaining_cooldown
		if(bus)
			bus.auto_pump = auto_pump
		TEST_FAIL("Navigation preparation produced no query: [netrun_navigation_outcome_details(entity)]")
		return FALSE
	var/datum/netrun_external_core/client = SSnetrun.external_core
	var/datum/netrun_external_effects/machines/queries/executor = client?.effects
	var/datum/component/netrun_node/source = entity.host_node
	if(!istype(executor) || !executor.process_result(client, netrun_navigation_page(client, request, path, code = code)))
		entity.next_hop = world.time + remaining_cooldown
		if(bus)
			bus.auto_pump = auto_pump
		TEST_FAIL("The supplied Core page was rejected: [netrun_navigation_outcome_details(entity)]")
		return FALSE
	var/deadline = world.time + 5 SECONDS
	while(entity.navigation?.external_request == request && world.time < deadline)
		sleep(world.tick_lag)
	var/retired = entity.navigation?.external_request != request
	var/datum/netrun_entity_navigation/navigation = entity.navigation
	entity.next_hop = world.time + remaining_cooldown
	if(retired && length(navigation?.queue))
		if(navigation.timer)
			deltimer(navigation.timer)
		if(drive_first_hop)
			navigation.advance_route(navigation.generation)
		else
			navigation.schedule_step()
	if(bus)
		bus.auto_pump = auto_pump
	var/list/last_line = length(entity.console?.log) ? entity.console.log[length(entity.console.log)] : null
	var/native_safety_stop = istext(last_line?["text"]) && findtext(last_line["text"], "Автопроход остановлен перед ") == 1
	var/success = code != "completed" ? retired && entity.host_node == source && !navigation?.is_active() : retired && (entity.host_node != source || (!drive_first_hop && length(navigation?.queue)) || native_safety_stop)
	if(!success)
		TEST_FAIL("The supplied Core route did not reach its expected native outcome: [netrun_navigation_outcome_details(entity, request, client)]")
	return success

/// A scoped scene binding ignores foreign world facts while preserving its own native authority journal.
/datum/unit_test/netrun_external_navigation_scene_scope/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	scene.bus.auto_pump = FALSE
	var/datum/netrun_external_core/client = scene.bus.client
	var/datum/component/netrun_node/declared = scene.source.resolve_node()
	TEST_ASSERT_NOTNULL(client.node_key(declared), "A declared scene endpoint retains its production node identity")
	TEST_ASSERT_NOTNULL(client.service_key(scene.source), "A declared native service retains its production service identity")
	client.observe_service(scene.source)
	var/before_fact_tail = client.fact_tail
	var/obj/item/foreign_host = allocate(/obj/item, get_step(scene.source_spot, SOUTH))
	var/datum/component/netrun_node/foreign_node = foreign_host.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
	var/datum/netrun_machine_service/external_fixture/foreign_service = allocate(/datum/netrun_machine_service/external_fixture, foreign_node)
	TEST_ASSERT_NULL(scene.fixture_graph.nodes[foreign_node.address], "The foreign host is outside the scene's declared native scope")
	TEST_ASSERT_NULL(client.node_key(foreign_node), "A global native endpoint cannot acquire an unrelated scene identity")
	TEST_ASSERT_NULL(client.service_key(foreign_service), "A global service-watch source cannot subscribe the scene client to a foreign node")
	client.observe_service(foreign_service)
	client.on_node_changed(foreign_host, foreign_node, NETRUN_CHANGED_STATE)
	TEST_ASSERT_NULL(client.node_metadata[foreign_node], "Foreign state callbacks create no direct native subscription or metadata")
	TEST_ASSERT_NULL(client.service_metadata[foreign_service], "Foreign registration creates no service metadata")
	TEST_ASSERT_EQUAL(client.fact_tail, before_fact_tail, "Foreign callbacks cannot invalidate a scene query's causal fact prefix")
	declared.offline_until = world.time + 10 SECONDS
	client.on_node_changed(declared.parent, declared, NETRUN_CHANGED_STATE)
	TEST_ASSERT(netrun_external_decimal_compare(client.fact_tail, before_fact_tail) > 0, "A real change to a declared endpoint still enters the production fact journal")

/// A production UI intent stays pending until all Core pages arrive, then moves on a later callback.
/datum/unit_test/netrun_external_navigation_paged_handoff/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	scene.bus.auto_pump = FALSE
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	TEST_ASSERT(entity.console.store_file(scene.key_file()), "The native representation owns a real traversal credential")
	entity.remove_module("vitals")
	entity.integrity = 63
	entity.next_hop = world.time + 1 MINUTES
	TEST_ASSERT(entity.dispatch_module_action("move", list("address" = scene.node_b.address), entity), "The production module accepts the distant movement intent")
	TEST_ASSERT_NOTNULL(entity.navigation.external_request, "Admission creates one asynchronous route continuation")
	TEST_ASSERT_EQUAL(entity.host_node, scene.node_a, "UI admission never performs a synchronous hop")
	TEST_ASSERT_EQUAL(length(entity.navigation.queue), 0, "Admission cannot manufacture a local path")
	TEST_ASSERT_NULL(entity.external_entity_proxy, "A navigation query does not create a second HP owner")
	var/datum/netrun_external_navigation_request/request = netrun_navigation_wait_request(entity)
	TEST_ASSERT_NOTNULL(request, "Cooperative preparation enqueues the query")
	var/datum/netrun_external_core/client = scene.bus.client
	var/datum/netrun_external_effects/machines/queries/executor = client.effects
	var/list/first = netrun_navigation_page(client, request, list(scene.apc_node), "1", FALSE)
	TEST_ASSERT(executor.process_result(client, first), "The first bounded page is accepted")
	TEST_ASSERT_EQUAL(entity.host_node, scene.node_a, "A partial route cannot move its consumer")
	TEST_ASSERT_EQUAL(length(entity.navigation.queue), 0, "Staging is not a published native route")
	TEST_ASSERT(!executor.process_result(client, first), "An already staged page cannot be appended twice")
	var/list/last = netrun_navigation_page(client, request, list(scene.node_b), "2")
	var/list/foreign = last.Copy()
	foreign["actor_revision"] = netrun_external_decimal_next(request.actor_revision)
	TEST_ASSERT(!executor.process_result(client, foreign), "A different operation revision cannot complete this route")
	TEST_ASSERT_EQUAL(request.next_page, "2", "Rejected identity does not consume the next page")
	TEST_ASSERT(executor.process_result(client, last), "Only the complete matching route can schedule handoff")
	TEST_ASSERT_EQUAL(entity.host_node, scene.node_a, "The decoder never executes native movement")
	var/deadline = world.time + 5 SECONDS
	while(entity.navigation.external_request == request && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT_EQUAL(length(entity.navigation.queue), 2, "The completed Core route is committed while native movement remains held")
	TEST_ASSERT_EQUAL(entity.host_node, scene.node_a, "The deferred route handoff also preserves the native cooldown")
	entity.next_hop = world.time
	deltimer(entity.navigation.timer)
	entity.navigation.advance_route(entity.navigation.generation)
	TEST_ASSERT_EQUAL(entity.host_node, scene.apc_node, "One later native callback traverses exactly the first actual edge")
	TEST_ASSERT_EQUAL(entity.integrity, 63, "Navigation never overwrites independently owned integrity")
	TEST_ASSERT(executor.process_result(client, last), "A retired read-only response is harmless")
	TEST_ASSERT_EQUAL(entity.host_node, scene.apc_node, "Replay cannot issue the next native hop")
	entity.navigation.cancel()

/// A replacement/cancelled operation never receives a late page from its predecessor.
/datum/unit_test/netrun_external_navigation_cancel_and_late_page/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	scene.bus.auto_pump = FALSE
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	TEST_ASSERT(entity.console.store_file(scene.key_file()), "The route has a real credential")
	TEST_ASSERT(entity.travel_to(scene.node_b), "The first asynchronous request is admitted")
	var/datum/netrun_external_navigation_request/request = netrun_navigation_wait_request(entity)
	TEST_ASSERT_NOTNULL(request, "The first request is prepared")
	var/datum/netrun_external_core/client = scene.bus.client
	var/datum/netrun_external_effects/machines/queries/executor = client.effects
	var/list/old_page = netrun_navigation_page(client, request, list(scene.apc_node, scene.node_b))
	var/old_revision = request.actor_revision
	entity.navigation.cancel()
	TEST_ASSERT(QDELETED(request), "Cancellation releases the staging continuation")
	TEST_ASSERT(executor.process_result(client, old_page), "A known cancelled response is acknowledged without a callback")
	TEST_ASSERT_EQUAL(entity.host_node, scene.node_a, "The cancelled result cannot move the representation")
	TEST_ASSERT(entity.travel_to(scene.node_b), "A replacement request has an independent continuation")
	request = netrun_navigation_wait_request(entity)
	TEST_ASSERT_NOTNULL(request, "The replacement request is prepared")
	TEST_ASSERT(netrun_external_decimal_compare(request.actor_revision, old_revision) > 0, "Replacement increments the operation authority revision")
	TEST_ASSERT(executor.process_result(client, old_page), "A predecessor page remains harmless during replacement")
	TEST_ASSERT_EQUAL(length(request.nodes), 0, "An old response cannot contaminate replacement staging")
	entity.navigation.cancel()
	TEST_ASSERT(!entity.navigation.is_active() && !entity.navigation.timer, "Cancellation leaves no route callback or fallback")

/// Native facts may change after decode and before the deferred handoff rechecks authority.
/datum/unit_test/netrun_external_navigation_authority_and_graph_races/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	scene.bus.auto_pump = FALSE
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	TEST_ASSERT(entity.console.store_file(scene.key_file()), "Traversal stays permitted throughout the inventory race")
	TEST_ASSERT(entity.travel_to(scene.node_b), "The authority-race request is admitted")
	var/datum/netrun_external_navigation_request/request = netrun_navigation_wait_request(entity)
	TEST_ASSERT_NOTNULL(request, "The authority-race request is prepared")
	var/datum/netrun_external_core/client = scene.bus.client
	var/datum/netrun_external_effects/machines/queries/executor = client.effects
	TEST_ASSERT(executor.process_result(client, netrun_navigation_page(client, request, list(scene.apc_node, scene.node_b))), "A complete page schedules deferred validation")
	var/datum/netrun_file/file = scene.key_file()
	TEST_ASSERT(entity.console.store_file(file), "A second real credential changes the raw access snapshot while preserving live traversal")
	var/deadline = world.time + 5 SECONDS
	while(entity.navigation.external_request && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT_EQUAL(entity.host_node, scene.node_a, "A changed raw snapshot discards the result before native movement")
	TEST_ASSERT(!entity.navigation.is_active() && !entity.navigation.timer, "Stale authority leaves no local route fallback")
	TEST_ASSERT(entity.can_enter(scene.apc_node), "The rejection comes from stale snapshot identity while live traversal remains allowed")
	TEST_ASSERT(entity.travel_to(scene.node_b), "A new request can capture the changed authority")
	request = netrun_navigation_wait_request(entity)
	TEST_ASSERT_NOTNULL(request, "The graph-race request is prepared")
	TEST_ASSERT(executor.process_result(client, netrun_navigation_page(client, request, list(scene.apc_node, scene.node_b))), "The next complete page is staged")
	executor.projection_graph_version = netrun_external_decimal_next(executor.projection_graph_version)
	deadline = world.time + 5 SECONDS
	while(entity.navigation.external_request && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT_EQUAL(entity.host_node, scene.node_a, "A newer graph hint revokes the already decoded path")
	TEST_ASSERT(!entity.navigation.is_active() && !entity.navigation.timer, "Graph invalidation leaves no queued movement")

/// Residence and binding checks survive a response already accepted by the decoder.
/datum/unit_test/netrun_external_navigation_source_and_rebind_races/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	scene.bus.auto_pump = FALSE
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	TEST_ASSERT(entity.console.store_file(scene.key_file()), "The route has real authority")
	TEST_ASSERT(entity.travel_to(scene.node_b), "The residence-race request is admitted")
	var/datum/netrun_external_navigation_request/request = netrun_navigation_wait_request(entity)
	TEST_ASSERT_NOTNULL(request, "The residence-race request is prepared")
	var/datum/netrun_external_core/client = scene.bus.client
	var/datum/netrun_external_effects/machines/queries/executor = client.effects
	TEST_ASSERT(executor.process_result(client, netrun_navigation_page(client, request, list(scene.apc_node, scene.node_b))), "The result is staged before a native residence change")
	entity.enter_node(scene.apc_node, TRUE)
	var/deadline = world.time + 5 SECONDS
	while(entity.navigation.external_request && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT_EQUAL(entity.host_node, scene.apc_node, "A result from the former source cannot continue from a new residence")
	TEST_ASSERT(!entity.navigation.is_active() && !entity.navigation.timer, "Residence invalidation clears the pending route")
	entity.enter_node(scene.node_a)
	TEST_ASSERT(entity.travel_to(scene.node_b), "A new residence-bound request can be admitted")
	request = netrun_navigation_wait_request(entity)
	TEST_ASSERT_NOTNULL(request, "The rebind-race request is prepared")
	TEST_ASSERT(executor.process_result(client, netrun_navigation_page(client, request, list(scene.apc_node, scene.node_b))), "The result is staged before rebind")
	client.binding_epoch = "navigation-rebound"
	deadline = world.time + 5 SECONDS
	while(entity.navigation.external_request && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT_EQUAL(entity.host_node, scene.node_a, "An old-binding completion cannot move the current native actor")
	TEST_ASSERT(!entity.navigation.is_active() && !entity.navigation.timer, "Rebind does not retain an old movement callback")

/// Query pressure and an unavailable Core reject the intent without synchronous pathfinding.
/datum/unit_test/netrun_external_navigation_pressure_fail_closed/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	scene.bus.auto_pump = FALSE
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	TEST_ASSERT(entity.console.store_file(scene.key_file()), "A local route would otherwise exist")
	var/datum/netrun_external_core/client = scene.bus.client
	var/datum/netrun_external_effects/machines/queries/executor = client.effects
	executor.query_command_limit = 1
	var/datum/consumer = allocate(/datum)
	var/id = executor.new_query_id("projection")
	var/raw = netrun_external_json_object(list("kind" = json_encode("projection_query"), "request_id" = json_encode(id)))
	TEST_ASSERT(executor.enqueue_query("projection_query", raw, consumer), "An independent query consumes the bounded slot")
	TEST_ASSERT(entity.travel_to(scene.node_b), "UI admission returns while preparation is still asynchronous")
	var/deadline = world.time + 5 SECONDS
	while(entity.navigation.external_request && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT_EQUAL(entity.host_node, scene.node_a, "Pressure cannot trigger local pathfinding or movement")
	TEST_ASSERT(!entity.navigation.is_active() && !entity.navigation.timer, "Failed admission releases its continuation")
	TEST_ASSERT_EQUAL(length(executor.query_consumers), 1, "The failed route does not leak a query slot")
	client.ready = FALSE
	TEST_ASSERT(!entity.travel_to(scene.node_b), "An unavailable Core rejects a new manual route")
	TEST_ASSERT_EQUAL(entity.host_node, scene.node_a, "Unavailability never chooses a local fallback")
	TEST_ASSERT_NULL(entity.navigation.external_request, "A rejected request owns no pending continuation")
	client.ready = TRUE

/// A valid scene-bus ACK advances the duplex ledger while a domain request still awaits its result.
/datum/unit_test/netrun_external_navigation_ack_during_wait/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	scene.bus.auto_pump = FALSE
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	TEST_ASSERT(entity.console.store_file(scene.key_file()), "The route has actual traversal authority")
	TEST_ASSERT(entity.travel_to(scene.node_b), "The asynchronous route intent is admitted")
	var/datum/netrun_external_navigation_request/request = netrun_navigation_wait_request(entity)
	TEST_ASSERT_NOTNULL(request, "The request is awaiting a supplied Core result")
	var/datum/netrun_external_core/client = scene.bus.client
	TEST_ASSERT(scene.bus.ack_facts(), "The scene acknowledges its preceding causal facts through the real ledger")
	TEST_ASSERT(client.enqueue("\[\]", 0), "An independent time-only input is queued while the query waits")
	var/sequence = client.input_sequence
	TEST_ASSERT(scene.bus.ack_input(), "The supplied Host ACK follows physical acceptance of that input")
	TEST_ASSERT_EQUAL(client.sent_input_sequence, sequence, "The fixture advances the same sent watermark as the production bridge")
	TEST_ASSERT_EQUAL(client.last_applied_sequence, sequence, "Application ACK is validated against the accepted input")
	TEST_ASSERT(client.ready && entity.navigation.external_request == request, "A valid unrelated ACK cannot disconnect or replace the waiting route")
	TEST_ASSERT_EQUAL(entity.host_node, scene.node_a, "Transport ACK alone never applies a domain route")
	TEST_ASSERT(netrun_supply_navigation(entity, list(scene.apc_node, scene.node_b)), "The later explicit Core result still reaches the native route consumer")
	TEST_ASSERT_EQUAL(entity.host_node, scene.apc_node, "The route remains usable after the independent ACK")
	entity.navigation.cancel()

/// A completed request does not release its route's exact binding while native hops wait for cooldown.
/datum/unit_test/netrun_external_navigation_rebind_during_cooldown/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	scene.bus.auto_pump = FALSE
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	TEST_ASSERT(entity.console.store_file(scene.key_file()), "The route has actual traversal authority")
	TEST_ASSERT(entity.travel_to(scene.node_b), "The two-edge route intent is admitted")
	TEST_ASSERT(netrun_supply_navigation(entity, list(scene.apc_node, scene.node_b)), "A completed Core path performs its first deferred hop")
	TEST_ASSERT_EQUAL(entity.host_node, scene.apc_node, "The process is waiting between the two actual edges")
	var/datum/netrun_entity_navigation/navigation = entity.navigation
	TEST_ASSERT_NULL(navigation.external_request, "The query continuation is already retired")
	TEST_ASSERT(navigation.is_active() && navigation.timer, "The native route still owns a cooldown callback")
	scene.bus.client.binding_epoch = "navigation-cooldown-rebound"
	entity.next_hop = world.time
	deltimer(navigation.timer)
	navigation.advance_route(navigation.generation)
	TEST_ASSERT_EQUAL(entity.host_node, scene.apc_node, "A queued hop cannot survive the binding that authorized its Core path")
	TEST_ASSERT(!navigation.is_active() && !navigation.timer, "Rebind cancels the remaining path and its timer")
	TEST_ASSERT_EQUAL(length(navigation.external_route_keys), 0, "Cancelled navigation releases every retained Core node identity")

/// A physical-fact callback schedules cancellation at the exporter's next cooperative boundary.
/obj/item/netrun_navigation_cancel_export_fixture
	var/datum/weakref/navigation_ref
	var/datum/netrun_external_entity_access_cursor/exported_cursor
	var/cancel_scheduled = FALSE
	var/cancelled_while_incomplete = FALSE
	var/exported_policies = 0

/obj/item/netrun_navigation_cancel_export_fixture/netrun_external_native_owners()
	var/datum/netrun_entity_navigation/navigation = navigation_ref?.resolve()
	var/datum/netrun_external_navigation_request/request = navigation?.external_request
	if(!cancel_scheduled && request?.access_cursor)
		cancel_scheduled = TRUE
		exported_cursor = request.access_cursor
		cancel_after_slice(request)
	return list()

/obj/item/netrun_navigation_cancel_export_fixture/proc/cancel_after_slice(datum/netrun_external_navigation_request/request)
	set waitfor = FALSE
	sleep(0)
	if(QDELETED(request) || QDELETED(exported_cursor))
		return
	cancelled_while_incomplete = !exported_cursor.complete
	exported_policies = length(exported_cursor.node_policies)
	var/datum/netrun_entity_navigation/navigation = navigation_ref?.resolve()
	navigation?.cancel()

/// Cancellation owns a still-running multi-slice raw export, including its temporary station scan.
/datum/unit_test/netrun_external_navigation_cancel_during_export/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	scene.bus.auto_pump = FALSE
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	TEST_ASSERT(entity.console.store_file(scene.key_file()), "The route has native credentials")
	var/obj/item/netrun_navigation_cancel_export_fixture/canceller = new(run_loc_floor_bottom_left)
	scene.owned += canceller
	canceller.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
	canceller.navigation_ref = WEAKREF(entity.navigation)
	for(var/index in 1 to 80)
		var/obj/item/host = new(run_loc_floor_bottom_left)
		scene.owned += host
		host.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
	var/datum/netrun_external_effects/machines/queries/executor = scene.bus.client.effects
	var/navigation_serial = executor.query_serials["navigation"]
	TEST_ASSERT(entity.travel_to(scene.node_b), "The large raw export starts asynchronously")
	var/datum/netrun_external_navigation_request/request = entity.navigation.external_request
	TEST_ASSERT_NOTNULL(request, "The request owns the cooperative export")
	var/deadline = world.time + 5 SECONDS
	while(!QDELETED(request) && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(canceller.cancel_scheduled && canceller.cancelled_while_incomplete, "Cancellation runs at a boundary before the multi-slice export completes")
	TEST_ASSERT(canceller.exported_policies > 1, "The export advances a real bounded slice before cancellation")
	TEST_ASSERT(QDELETED(canceller.exported_cursor), "Cancelling the request releases its owned access cursor")
	TEST_ASSERT(QDELETED(request), "The export continuation is released with its navigation owner")
	TEST_ASSERT_EQUAL(length(executor.navigation_pending), 0, "No abandoned request remains in the binding")
	TEST_ASSERT_EQUAL(executor.query_serials["navigation"], navigation_serial, "A cancelled preparation never allocates a navigation query identity")
	var/navigation_consumers = 0
	for(var/id in executor.query_consumers)
		if(findtext(id, "navigation:") == 1)
			navigation_consumers++
	TEST_ASSERT_EQUAL(navigation_consumers, 0, "A cancelled preparation never acquires a navigation-owned query slot")
	TEST_ASSERT_EQUAL(entity.host_node, scene.node_a, "Cancelling a partial raw export never moves the representation")

/// Core can invalidate an unread page; its empty terminal revocation supersedes the skipped index.
/datum/unit_test/netrun_external_navigation_terminal_revokes_partial/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	scene.bus.auto_pump = FALSE
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	TEST_ASSERT(entity.console.store_file(scene.key_file()), "The planned route has real credentials")
	TEST_ASSERT(entity.travel_to(scene.node_b), "The paged request is admitted")
	var/datum/netrun_external_navigation_request/request = netrun_navigation_wait_request(entity)
	TEST_ASSERT_NOTNULL(request, "The paged request is prepared")
	var/datum/netrun_external_core/client = scene.bus.client
	var/datum/netrun_external_effects/machines/queries/executor = client.effects
	TEST_ASSERT(executor.process_result(client, netrun_navigation_page(client, request, list(scene.apc_node), "1", FALSE)), "The partial prefix is staged")
	TEST_ASSERT_EQUAL(length(request.nodes), 1, "The request retains only its unpublished prefix")
	var/list/revocation = netrun_navigation_page(client, request, list(), "4", TRUE, "navigation_changed")
	TEST_ASSERT_EQUAL(length(revocation), 14, "The supplied terminal envelope has the complete wire shape")
	TEST_ASSERT_EQUAL(revocation["code"], "navigation_changed", "The fixture supplies the actual terminal failure code")
	TEST_ASSERT_EQUAL(length(revocation["nodes"]), 0, "A terminal revocation never includes path nodes")
	TEST_ASSERT(executor.process_result(client, revocation), "An empty terminal failure may skip superseded page indices")
	TEST_ASSERT_EQUAL(length(request.nodes), 0, "Terminal invalidation discards the entire staged prefix immediately")
	TEST_ASSERT_EQUAL(entity.host_node, scene.node_a, "Decoding a revocation never applies its former prefix")
	var/deadline = world.time + 5 SECONDS
	while(entity.navigation.external_request && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(!entity.navigation.is_active() && !entity.navigation.timer, "Deferred failure leaves no native movement callback")
	TEST_ASSERT(executor.process_result(client, revocation), "A retired terminal result is harmless")
	TEST_ASSERT_EQUAL(entity.host_node, scene.node_a, "Replaying terminal invalidation cannot start a route")

/// Manual adjacent movement preserves deliberate combat entry; explicit autopilot still stops before ICE.
/datum/unit_test/netrun_external_navigation_manual_edge_and_ice/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	scene.bus.auto_pump = FALSE
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	TEST_ASSERT(entity.console.store_file(scene.key_file()), "A LAN credential permits the actual adjacent hop")
	var/datum/netrun_ice/ice = allocate(/datum/netrun_ice, scene.apc_node)
	TEST_ASSERT(ice.is_intruder(entity, scene.apc_node), "The credential does not make this process lawful to the sentry")
	TEST_ASSERT(entity.navigation.move_to(scene.apc_node), "The ordinary UI move is admitted for Core planning")
	TEST_ASSERT_EQUAL(entity.host_node, scene.node_a, "Even a one-edge manual move waits for the Core result")
	TEST_ASSERT(netrun_supply_navigation(entity, list(scene.apc_node)), "Core supplies exactly one adjacent edge")
	TEST_ASSERT_EQUAL(entity.host_node, scene.apc_node, "The deferred manual hop preserves deliberate entry into hostile ICE")
	entity.enter_node(scene.node_a)
	entity.next_hop = world.time
	TEST_ASSERT(entity.travel_to(scene.apc_node), "Explicit autopilot requests the same adjacent route")
	TEST_ASSERT(netrun_supply_navigation(entity, list(scene.apc_node)), "The same Core path reaches the autopilot safety consumer")
	TEST_ASSERT_EQUAL(entity.host_node, scene.node_a, "Autopilot stops before the hostile sentry")
	TEST_ASSERT(!entity.navigation.is_active() && !entity.navigation.timer, "The ICE safety stop releases the imported route")
