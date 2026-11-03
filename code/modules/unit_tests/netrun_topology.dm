/// Native gameplay checks over imported fixture data; physical algorithms are tested in netrun-core.
/datum/unit_test/proc/netrun_map_has_node(list/payload, address)
	var/list/map = payload["map"]
	for(var/list/node as anything in map?["nodes"])
		if(node["address"] == address)
			return TRUE
	return FALSE

/// Map initialization registers an early distant APC, then a client, then its actual nearest APC.
/datum/unit_test/netrun_topology_entity_neighbors/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, origin.z)
	var/area/room = scene.room(/area/engineering/netrun_route_test)
	scene.take(origin, room)
	var/turf/apc_spot = scene.take(get_step(origin, NORTH), room)
	var/turf/peer_spot = scene.take(get_step(origin, EAST), room)
	var/obj/machinery/power/apc/apc = scene.machine(/obj/machinery/power/apc, apc_spot)
	var/obj/machinery/computer/netrun_terminal/source = scene.machine(/obj/machinery/computer/netrun_terminal, origin)
	var/obj/machinery/computer/netrun_terminal/peer = scene.machine(/obj/machinery/computer/netrun_terminal, peer_spot)
	SSnetrun.ensure_topology()
	var/datum/component/netrun_node/source_node = source.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/peer_node = peer.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/apc_node = apc.GetComponent(/datum/component/netrun_node)
	var/mob/camera/netrun_entity/entity = new(origin, source_node)
	scene.owned.Insert(1, entity)
	TEST_ASSERT(entity.console.store_file(new /datum/netrun_file/access("network-engineer.access", list(ACCESS_NETWORK, ACCESS_ENGINE_EQUIP))), "The entity needs actual matching credentials for actions independently of LAN traversal")
	TEST_ASSERT(entity.console.node_level(peer_node) >= NETRUN_ACCESS_USER, "The peer must be authorized independently of graph adjacency")
	TEST_ASSERT(!entity.can_enter(peer_node), "An entity must not jump directly between two endpoints behind the same APC")
	TEST_ASSERT(entity.can_enter(apc_node), "The immediate online APC neighbor must be eligible")
	TEST_ASSERT(entity.hop(apc_node), "A legal hop must enter the adjacent APC")
	TEST_ASSERT_EQUAL(entity.host_node, apc_node, "The successful hop must update the entity's actual host")
	TEST_ASSERT(entity.can_enter(peer_node), "After entering the APC its endpoint must become an immediate neighbor")

/// Shared CLI pools keep protected endpoints hidden and cannot retain a revoked key across updates.
/datum/unit_test/netrun_cli_completion_access_scope/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, origin.z)
	var/area/engineering = scene.room(/area/engineering/netrun_route_test)
	var/area/medical = scene.room(/area/medical/netrun_route_test)
	scene.take(origin, engineering)
	var/turf/first_apc_spot = scene.take(get_step(origin, NORTH), engineering)
	var/turf/target_spot = scene.take(locate(origin.x + 4, origin.y, origin.z), medical)
	var/turf/second_apc_spot = scene.take(get_step(target_spot, NORTH), medical)
	scene.machine(/obj/machinery/power/apc, first_apc_spot)
	var/obj/machinery/power/apc/medical_apc = scene.machine(/obj/machinery/power/apc, second_apc_spot)
	var/obj/machinery/computer/netrun_terminal/source = scene.machine(/obj/machinery/computer/netrun_terminal, origin)
	var/obj/machinery/computer/netrun_terminal/target = scene.machine(/obj/machinery/computer/netrun_terminal, target_spot)
	SSnetrun.ensure_topology()
	var/datum/component/netrun_node/target_node = target.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/apc_node = medical_apc.GetComponent(/datum/component/netrun_node)
	var/datum/netrun_network/medical_network = scene.fixture_graph.declared_network(apc_node)
	scene.fixture_graph.import_binding(apc_node, apc_node, medical_network)
	scene.fixture_graph.import_binding(target_node, apc_node, medical_network)
	scene.fixture_graph.clear_tables()
	TEST_ASSERT(source.console.can_route(target_node), "The protected endpoint must be physically reachable before testing disclosure")
	TEST_ASSERT(source.console.store_file(netrun_daemon_file("mapper")), "The mapper must fit so map visibility cannot accidentally grant CLI disclosure")
	var/list/payload = source.console.ui_data(null)
	var/list/cli = payload["cli"]
	var/list/pools = cli["completions"]
	var/list/node_addresses = pools["nodes"]
	TEST_ASSERT_NOTNULL(node_addresses, "The public CLI payload must expose its shared address completion pool")
	TEST_ASSERT(!(target_node.address in node_addresses), "Mapper must not leak a locked endpoint into ordinary CLI completion")
	TEST_ASSERT(apc_node.address in node_addresses, "The protected LAN's structural APC must remain discoverable")
	TEST_ASSERT(!(apc_node.network.code in node_addresses), "Combining breach targets must not append network codes to the shared node-address pool")
	var/nodes_verb_pool
	var/select_verb_pool
	for(var/list/verb as anything in cli["verbs"])
		if(verb["id"] == "nodes")
			nodes_verb_pool = verb["completion_key"]
		if(verb["id"] == "sel")
			select_verb_pool = verb["completion_key"]
	TEST_ASSERT_NOTEQUAL(nodes_verb_pool, select_verb_pool, "The no-argument nodes verb must not alias the shared endpoint completion pool")
	var/datum/netrun_file/key = new("medical.key", NETRUN_FILE_KEY, target_node.network.passcode, 1, target_node.network.id)
	TEST_ASSERT(source.console.store_file(key), "The legitimate network key must fit in memory")
	TEST_ASSERT(key in source.console.all_files(TRUE), "The new key must belong to the current inventory before its UI projection is requested")
	TEST_ASSERT(source.console.has_key(target_node.network, TRUE), "Fresh key authorization must recognize the stored file before generating CLI disclosure")
	TEST_ASSERT(source.console.has_key(target_node.network), "Ordinary key authorization must recognize the stored file outside a UI snapshot")
	TEST_ASSERT_EQUAL(source.console.network_level(target_node.network), NETRUN_ACCESS_GUEST, "A legitimate key must grant the reachable protected LAN before generating CLI disclosure")
	payload = source.console.ui_data(null)
	cli = payload["cli"]
	pools = cli["completions"]
	node_addresses = pools["nodes"]
	var/datum/component/netrun_node/source_node = source.GetComponent(/datum/component/netrun_node)
	TEST_ASSERT(target_node.address in node_addresses, "The next UI update must include an endpoint revealed by its legitimate key")
	TEST_ASSERT(source_node.address in node_addresses, "Guest access to the local LAN must disclose its endpoints")
	TEST_ASSERT(apc_node.address in node_addresses, "Granting access must not remove a structural APC from completion")
	source.console.delete_local_file(key)
	payload = source.console.ui_data(null)
	cli = payload["cli"]
	pools = cli["completions"]
	node_addresses = pools["nodes"]
	TEST_ASSERT(!(target_node.address in node_addresses), "A shared completion cache must expire with the request and honor key revocation on the next update")
	TEST_ASSERT(apc_node.address in node_addresses, "Revoking a key must preserve public structural APC discovery")

/datum/unit_test/netrun_cli_help_without_selection/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/netrun_console/console = allocate(/datum/netrun_console, host)
	console.cli("help issue_key")
	var/list/line = console.log[length(console.log)]
	TEST_ASSERT(findtext(line["text"], "Нет такой команды"), "Machine-command help without a selected node must return a readable refusal")

/// Display paths are retained on the server, copied for clients, and refreshed
/// periodically; a stale display path must never authorize a real request.
