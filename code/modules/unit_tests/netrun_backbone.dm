/// Creating distant component B before nearer C must not force an unnecessarily long A-B cable.
/datum/unit_test/netrun_apc_minimum_component_bridges/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, origin.z)
	var/area/room = scene.room(/area/netrun_route_test)
	var/list/groups = list()
	var/list/all_addresses = list()
	var/component_size = max(2, NETRUN_APC_NEIGHBORS + 1)
	for(var/x in list(30, 150, 60))
		var/list/members = list()
		for(var/offset in 0 to component_size - 1)
			var/turf/spot = scene.take(locate(x + offset, 30, origin.z), room, TRUE)
			var/obj/machinery/power/apc/apc = scene.machine(/obj/machinery/power/apc, spot)
			var/datum/component/netrun_node/node = apc.GetComponent(/datum/component/netrun_node)
			members += node.address
			all_addresses += node.address
		groups += list(members)
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	var/bridge_length = 0
	var/bridge_count = 0
	for(var/list/edge as anything in graph.edges)
		if(edge["kind"] != "apc" || !(edge["from"] in all_addresses) || !(edge["to"] in all_addresses))
			continue
		var/same_group = FALSE
		for(var/list/members as anything in groups)
			if((edge["from"] in members) && (edge["to"] in members))
				same_group = TRUE
		if(!same_group)
			bridge_count++
			bridge_length += edge["distance"]
	TEST_ASSERT_EQUAL(bridge_count, 2, "Three components require exactly two additional cables")
	TEST_ASSERT_EQUAL(bridge_length, 120 - 2 * (component_size - 1), "Bridge selection must minimize total added distance regardless of registration order")
	var/synchronous = json_encode(graph.edges)
	graph.invalidate()
	var/datum/netrun_apc_prebuild/prepared = new(graph)
	graph.apc_prebuild = prepared
	var/finished = FALSE
	for(var/i in 1 to 20000)
		var/before = prepared.comparisons
		if(prepared.advance(1))
			finished = TRUE
			break
		TEST_ASSERT(prepared.comparisons - before <= 1, "A background work unit must evaluate at most one physical distance")
	TEST_ASSERT(finished && prepared.valid_inputs(), "Incremental mesh construction must complete with valid inputs")
	graph.rebuild()
	TEST_ASSERT_EQUAL(json_encode(graph.edges), synchronous, "Background and immediate requests must publish the same deterministic mesh")

/// Endpoint churn must not discard valid speculative infrastructure work.
/datum/unit_test/netrun_apc_prebuild_survives_endpoint_changes/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = netrun_connected_test_area()
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	graph.invalidate()
	var/datum/netrun_apc_prebuild/job = new(graph)
	graph.apc_prebuild = job
	var/generation = job.generation
	var/obj/machinery/computer/netrun_terminal/client = scene.machine(/obj/machinery/computer/netrun_terminal, origin)
	TEST_ASSERT(job.valid_inputs(), "Registering/binding an endpoint does not change APC positions or neighbors")
	TEST_ASSERT_EQUAL(job.generation, generation, "The APC work item must retain its infrastructure generation")
	var/complete = FALSE
	for(var/i in 1 to 1000)
		if(job.advance(1))
			complete = TRUE
			break
	TEST_ASSERT(complete, "The original job must finish even while endpoints are added")
	graph.rebuild()
	TEST_ASSERT(!graph.dirty && QDELETED(job), "Publication must consume the original speculative job")
	var/datum/component/netrun_node/client_node = client.GetComponent(/datum/component/netrun_node)
	TEST_ASSERT_NOTNULL(graph.edge_between(client_node.address, client_node.bound_apc.address), "The same graph publication must include the new endpoint's cable")

/// Every resident must leave a destroyed host even though leave_node mutates its resident list.
/datum/unit_test/netrun_node_evacuation_keeps_all_residents/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = netrun_connected_test_area()
	var/obj/machinery/computer/netrun_terminal/source = scene.machine(/obj/machinery/computer/netrun_terminal, origin)
	var/datum/component/netrun_node/source_node = source.GetComponent(/datum/component/netrun_node)
	var/list/residents = list()
	for(var/i in 1 to 3)
		var/mob/camera/netrun_entity/entity = new(origin, source_node)
		scene.owned.Insert(1, entity)
		residents += entity
	TEST_ASSERT_EQUAL(length(source_node.entities), 3, "All fixture residents must share the doomed endpoint")
	qdel(source)
	for(var/mob/camera/netrun_entity/entity as anything in residents)
		TEST_ASSERT(!QDELETED(entity) && entity.host_node && entity.host_node != source_node, "Deleting a host must evacuate every resident, without skipping entries removed during iteration")

/// A sparse sector with fewer peers than K must not walk thousands of empty buckets.
/datum/unit_test/netrun_apc_spatial_sparse_sector/Run()
	var/list/addresses = list("A", "B", "C")
	var/list/positions = list("A" = locate(1, 1, run_loc_floor_bottom_left.z), "B" = locate(230, 230, run_loc_floor_bottom_left.z), "C" = locate(1, 230, run_loc_floor_bottom_left.z))
	var/datum/netrun_apc_spatial_index/spatial = allocate(/datum/netrun_apc_spatial_index, addresses, positions)
	var/datum/netrun_apc_neighbor_scan/scan = allocate(/datum/netrun_apc_neighbor_scan, spatial, "A")
	var/steps = 0
	while(!scan.advance() && steps < 10)
		steps++
	TEST_ASSERT(scan.done && steps <= 3, "A three-APC sector should finish after scanning its three occupied positions")
	TEST_ASSERT_EQUAL(scan.comparisons, 2, "Each actual peer must be measured once")
	TEST_ASSERT_EQUAL(length(scan.best), 2, "A small sector must retain every existing peer")

/// Native machine resources can already be gone when its node announces removal.
/datum/unit_test/netrun_node_online_after_teardown/Run()
	var/obj/machinery/door/airlock/door = allocate(/obj/machinery/door/airlock)
	var/datum/component/netrun_node/node = door.GetComponent(/datum/component/netrun_node)
	TEST_ASSERT_NOTNULL(node, "A real airlock must expose a network endpoint")
	qdel(door)
	TEST_ASSERT(QDELETED(node), "Deleting a machine must delete its endpoint")
	TEST_ASSERT(!node.is_online(), "A deleted endpoint must be offline without reading torn-down native wires")

/// Finish candidate selection separately so binding regressions exercise the new bounded phase.
/datum/unit_test/proc/netrun_binding_prebuild(datum/netrun_topology/graph)
	var/datum/netrun_apc_prebuild/job = allocate(/datum/netrun_apc_prebuild, graph)
	graph.apc_prebuild = job
	for(var/i in 1 to 20000)
		if(job.advance(32))
			return job
	return null

/// Preparing moved leaves must leave the last published graph intact until one final commit.
/datum/unit_test/netrun_apc_binding_prebuild_atomic/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = netrun_connected_test_area()
	var/turf/destination = locate(origin.x + 3, origin.y, origin.z)
	var/obj/machinery/computer/netrun_terminal/client = scene.machine(/obj/machinery/computer/netrun_terminal, origin)
	var/datum/component/netrun_node/node = client.GetComponent(/datum/component/netrun_node)
	// Keep another ordinary entry after the moved endpoint in the preparation snapshot.
	scene.machine(/obj/machinery/computer/netrun_terminal, get_step(origin, NORTH))
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	var/published_revision = graph.revision
	var/published_edges = json_encode(graph.edges)
	var/published_adjacency = json_encode(graph.adjacency)
	var/list/published_nodes = graph.nodes
	graph.invalidate()
	var/datum/netrun_apc_prebuild/job = netrun_binding_prebuild(graph)
	TEST_ASSERT_NOTNULL(job, "The fixture must finish APC candidates before preparing bindings")
	TEST_ASSERT(job.valid_inputs(), "Endpoint movement must not invalidate prepared APC candidates")
	SSatoms.map_loader_begin()
	var/premature = job.advance_bindings(1)
	SSatoms.map_loader_stop()
	TEST_ASSERT(!premature && !job.binding_operations, "Bindings must not advance while native map initialization is active")
	TEST_ASSERT_NULL(job.binding_apcs, "The readiness barrier must prevent allocating an APC snapshot")
	TEST_ASSERT_NULL(job.binding_nodes, "The readiness barrier must prevent allocating an endpoint snapshot")
	client.forceMove(destination)
	var/finished = FALSE
	var/processed_moved_leaf = FALSE
	var/operations = 0
	for(var/i in 1 to length(SSnetrun.nodes_by_address) + length(graph.registered_apcs) + 4)
		var/before = job.binding_operations
		finished = job.advance_bindings(1)
		TEST_ASSERT(job.binding_operations - before <= 1, "One binding slice must examine at most one snapshot entry")
		operations += job.binding_operations - before
		if(node.topology_turf == destination)
			processed_moved_leaf = TRUE
			TEST_ASSERT_EQUAL(json_encode(graph.edges), published_edges, "Preparing a moved leaf must not rewrite published edge weights")
			TEST_ASSERT_EQUAL(json_encode(graph.adjacency), published_adjacency, "Preparing bindings must not rewrite published adjacency")
			TEST_ASSERT_EQUAL(graph.nodes, published_nodes, "Preparation must retain the published node registry")
			TEST_ASSERT_EQUAL(graph.revision, published_revision, "Preparation must not publish an intermediate graph revision")
		if(finished)
			break
	TEST_ASSERT(finished && processed_moved_leaf && operations > 1, "One-entry slices must eventually prepare the moved endpoint and all remaining entries")
	TEST_ASSERT(job.bindings_completed && graph.dirty, "Completing binding preparation must still leave publication pending")
	TEST_ASSERT_NULL(job.binding_apcs, "Completed preparation must release its APC snapshot")
	TEST_ASSERT_NULL(job.binding_nodes, "Completed preparation must release its endpoint snapshot")
	TEST_ASSERT(graph.advance_apc_prebuild(1), "The worker must publish a fully prepared graph")
	TEST_ASSERT_EQUAL(graph.revision, published_revision + 1, "Completing preparation must publish exactly one revision")
	TEST_ASSERT(QDELETED(job), "Publication must consume the preparation job")
	var/list/cable = graph.edge_between(node.address, node.bound_apc.address)
	TEST_ASSERT_NOTNULL(cable, "The moved endpoint must retain its real APC cable after publication")
	TEST_ASSERT_EQUAL(cable["distance"], netrun_topology_distance(destination, node.bound_apc.physical_turf()), "The committed cable must use the endpoint's current physical distance")
	graph.advance_apc_prebuild(1)
	TEST_ASSERT_EQUAL(graph.revision, published_revision + 1, "A completed background continuation must not publish a second revision")

/// A moved APC must refresh its cached LAN before an earlier-registered endpoint reuses it.
/datum/unit_test/netrun_apc_binding_prebuild_apc_first/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, origin.z)
	var/area/room = scene.room(/area/engineering/netrun_route_test)
	var/area/remote_room = scene.room(/area/medical/netrun_route_test)
	scene.take(origin, room)
	var/turf/apc_spot = scene.take(get_step(origin, NORTH), room)
	var/turf/remote = scene.take(locate(origin.x + 3, origin.y, origin.z), remote_room)
	var/turf/remote_apc = scene.take(locate(origin.x + 3, origin.y + 1, origin.z), remote_room)
	// Registration order deliberately puts the ordinary node before its APC.
	var/obj/machinery/computer/netrun_terminal/client = scene.machine(/obj/machinery/computer/netrun_terminal, origin)
	var/obj/machinery/power/apc/apc = scene.machine(/obj/machinery/power/apc, apc_spot)
	var/datum/component/netrun_node/node = client.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/apc_node = apc.GetComponent(/datum/component/netrun_node)
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	var/datum/netrun_network/old_network = apc_node.network
	// Reconfigure the native supplied area as when installing an APC in another department.
	apc.unregister_area_apc()
	apc.area = remote_room
	apc.register_area_apc()
	apc.forceMove(remote_apc)
	client.forceMove(remote)
	TEST_ASSERT_EQUAL(apc_node.network, old_network, "Native movement must leave the old LAN cached until the bounded worker resolves it")
	var/datum/netrun_apc_prebuild/job = netrun_binding_prebuild(graph)
	TEST_ASSERT_NOTNULL(job, "The moved APC must produce valid fresh candidates")
	var/finished = FALSE
	for(var/i in 1 to length(SSnetrun.nodes_by_address) + length(graph.registered_apcs) + 4)
		finished = job.advance_bindings(1)
		if(node.topology_turf == remote)
			TEST_ASSERT_NOTEQUAL(apc_node.network, old_network, "The APC's new department LAN must be ready before its endpoint is prepared")
			TEST_ASSERT_EQUAL(node.network, apc_node.network, "An earlier-registered endpoint must reuse the refreshed APC LAN rather than the stale one")
		if(finished)
			break
	TEST_ASSERT(finished && node.topology_turf == remote, "Single-entry binding slices must prepare both moved machines")
	graph.rebuild()
	TEST_ASSERT_EQUAL(node.network, apc_node.network, "Final publication must preserve the newly prepared common LAN")
	TEST_ASSERT_NOTNULL(graph.edge_between(node.address, apc_node.address), "The endpoint must be cabled to the APC in its new department")

/// An interactive route request can consume a partially prepared job without a later duplicate commit.
/datum/unit_test/netrun_apc_binding_prebuild_forced_route/Run()
	var/datum/netrun_route_scene/scene = netrun_connected_test_area()
	scene.machine(/obj/machinery/computer/netrun_terminal, run_loc_floor_bottom_left)
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	var/published_revision = graph.revision
	graph.invalidate()
	var/datum/netrun_apc_prebuild/job = netrun_binding_prebuild(graph)
	TEST_ASSERT_NOTNULL(job, "The fixture must finish candidates before a forced route request")
	TEST_ASSERT(!job.advance_bindings(1), "One slice must leave further APC or endpoint entries pending")
	TEST_ASSERT_EQUAL(graph.revision, published_revision, "A partial binding slice must not publish")
	var/before_invalidation = job.binding_operations
	graph.infrastructure_changed()
	TEST_ASSERT(!job.advance_bindings(1), "Changed infrastructure must reject an obsolete binding snapshot")
	TEST_ASSERT_EQUAL(job.binding_operations, before_invalidation, "An invalidated job must not process another snapshot entry")
	TEST_ASSERT_EQUAL(SSnetrun.ensure_topology(), graph, "Interactive routing must retain the authoritative topology datum")
	TEST_ASSERT(!graph.dirty && QDELETED(job), "A forced routing rebuild must consume the partial background job")
	TEST_ASSERT_EQUAL(graph.revision, published_revision + 1, "The forced route must publish exactly one complete revision")
	TEST_ASSERT(graph.advance_apc_prebuild(1), "A queued background continuation must notice that routing already completed the graph")
	TEST_ASSERT_EQUAL(graph.revision, published_revision + 1, "Resuming the old worker must not publish its obsolete snapshot")

/// Preparation snapshots must tolerate deletion, late registration and movement after a node's slice.
/datum/unit_test/netrun_apc_binding_prebuild_endpoint_churn/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, origin.z)
	var/area/first_room = scene.room(/area/engineering/netrun_route_test)
	var/area/second_room = scene.room(/area/medical/netrun_route_test)
	scene.take(origin, first_room)
	var/turf/local_step = scene.take(get_step(origin, EAST), first_room)
	var/turf/first_apc_spot = scene.take(get_step(origin, NORTH), first_room)
	var/turf/destination = scene.take(locate(origin.x + 3, origin.y, origin.z), second_room)
	var/turf/second_apc_spot = scene.take(locate(origin.x + 3, origin.y + 1, origin.z), second_room)
	scene.machine(/obj/machinery/power/apc, first_apc_spot)
	var/obj/machinery/power/apc/second = scene.machine(/obj/machinery/power/apc, second_apc_spot)
	var/obj/machinery/computer/netrun_terminal/client = scene.machine(/obj/machinery/computer/netrun_terminal, origin)
	var/obj/machinery/computer/netrun_terminal/doomed = scene.machine(/obj/machinery/computer/netrun_terminal, origin)
	var/datum/component/netrun_node/node = client.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/doomed_node = doomed.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/second_node = second.GetComponent(/datum/component/netrun_node)
	var/doomed_address = doomed_node.address
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	var/published_revision = graph.revision
	graph.invalidate()
	var/datum/netrun_apc_prebuild/job = netrun_binding_prebuild(graph)
	TEST_ASSERT_NOTNULL(job, "The endpoint churn fixture must finish APC candidates")
	client.forceMove(local_step)
	var/prepared_client = FALSE
	for(var/i in 1 to length(SSnetrun.nodes_by_address) + length(graph.registered_apcs) + 4)
		job.advance_bindings(1)
		if(node.topology_turf == local_step)
			prepared_client = TRUE
			break
	TEST_ASSERT(prepared_client && !job.bindings_completed, "The client must receive its own preparation slice before a later snapshot entry")
	qdel(doomed)
	var/obj/machinery/computer/netrun_terminal/late_client = scene.machine(/obj/machinery/computer/netrun_terminal, destination)
	var/datum/component/netrun_node/late_node = late_client.GetComponent(/datum/component/netrun_node)
	client.forceMove(destination)
	TEST_ASSERT(job.valid_inputs(), "Endpoint churn must retain the completed APC candidate mesh")
	var/finished = FALSE
	for(var/i in 1 to length(SSnetrun.nodes_by_address) + length(graph.registered_apcs) + 4)
		var/before = job.binding_operations
		finished = job.advance_bindings(2)
		TEST_ASSERT(job.binding_operations - before <= 2, "Deleted snapshot entries must still respect the examined-entry budget")
		if(finished)
			break
	TEST_ASSERT(finished, "Preparation must finish after skipping deleted snapshot entries")
	TEST_ASSERT(graph.advance_apc_prebuild(1), "The background worker must commit current registry contents after preparation")
	TEST_ASSERT_EQUAL(graph.revision, published_revision + 1, "Endpoint churn must still produce one completed revision")
	TEST_ASSERT_NULL(graph.nodes[doomed_address], "Publication must not resurrect a node deleted from the preparation snapshot")
	TEST_ASSERT_NULL(graph.adjacency[doomed_address], "A deleted endpoint must have no published neighbor list")
	TEST_ASSERT_EQUAL(graph.nodes[late_node.address], late_node, "The final graph must include an endpoint registered after the preparation snapshot")
	TEST_ASSERT_NOTNULL(graph.edge_between(late_node.address, second_node.address), "The late endpoint must receive its current physical APC cable")
	TEST_ASSERT_EQUAL(node.bound_apc, second_node, "The final build must reconcile movement that occurred after the node's preparation slice")
	TEST_ASSERT_EQUAL(node.network, second_node.network, "The moved endpoint must use the destination APC's live authorization domain")
	TEST_ASSERT_NOTNULL(graph.edge_between(node.address, second_node.address), "The committed graph must use the post-preparation destination cable")
