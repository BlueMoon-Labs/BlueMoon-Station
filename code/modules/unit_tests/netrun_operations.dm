/// Results are value snapshots. A late completion never borrows another action's nonce.
/datum/unit_test/netrun_operation_packet_decode_and_feedback/Run()
	var/datum/netrun_entity_contact_scene/scene = allocate(/datum/netrun_entity_contact_scene, run_loc_floor_bottom_left)
	scene.authorize()
	var/datum/netrun_packet_context/capture = allocate(/datum/netrun_packet_context, "machine", "Fixture", scene.source_node.address, scene.target_node.address, "fixture")
	capture.capture(list("body" = "CAPTURED_CONTENT", "nested" = list(list("filter" = "oxygen"))))
	capture.queued(list(scene.source_node.address, scene.target_node.address))
	capture.receive(list(scene.source_node.address, scene.target_node.address))
	capture.finish("completed")
	TEST_ASSERT(!findtext(json_encode(scene.target_node.packet_headers_payload()), "CAPTURED_CONTENT"), "Ordinary headers must not include the packet body")
	TEST_ASSERT(findtext(scene.target_node.decode_packet(capture.id), "CAPTURED_CONTENT"), "An explicitly decoded local packet must expose its captured body")
	TEST_ASSERT(!findtext(scene.target_node.decode_packet("unknown"), "CAPTURED_CONTENT"), "An ID absent from this node's journal cannot read another capture")
	TEST_ASSERT(scene.console.run_command(scene.target_node, "scan", "feedback-nonce"), "A native command must be queued")
	var/datum/netrun_request/command/packet = netrun_operation_packet(scene.console, /datum/netrun_request/command)
	var/id = packet.operation.id
	packet.deliver()
	var/list/outcome = netrun_operation_result(scene.console, id)
	TEST_ASSERT(istext(outcome["result"]) && findtext(outcome["result"], scene.target_node.address), "The operations tab must receive the actual scan response")
	scene.console.next_command = 0
	TEST_ASSERT(!scene.console.run_command(scene.target_node, "packet_decrypt", "denied", capture.id), "Guest access must never admit packet decryption")
	scene.console.next_command = 0
	scene.console.access_session.node_access[scene.target_node.address] = NETRUN_ACCESS_ROOT
	TEST_ASSERT(scene.console.run_command(scene.target_node, "packet_decrypt", "decode", capture.id), "ROOT must admit the selected packet as a routed request")
	packet = netrun_operation_packet(scene.console, /datum/netrun_request/command)
	id = packet.operation.id
	packet.deliver()
	outcome = netrun_operation_result(scene.console, id)
	TEST_ASSERT(findtext(outcome["result"], "CAPTURED_CONTENT"), "Explicit ROOT decryption must return contents through the operations tab")
	scene.console.next_command = 0
	TEST_ASSERT(scene.console.run_command(scene.target_node, "packet_decrypt", "revoked", capture.id), "A second decode must retain its own immutable packet selection")
	packet = netrun_operation_packet(scene.console, /datum/netrun_request/command)
	id = packet.operation.id
	scene.console.access_session.node_access -= scene.target_node.address
	TEST_ASSERT(!packet.deliver(), "Revoked ROOT must prevent decoding when delivery finally executes")
	outcome = netrun_operation_result(scene.console, id)
	TEST_ASSERT(!outcome["result"], "A rejected decode must expose no body")
	for(var/i in 1 to 270)
		var/datum/netrun_packet_context/overflow = new("machine", "Overflow", "A", "B", "fixture")
		overflow.capture(list("value" = i))
		overflow.finish("completed")
		qdel(overflow)
	TEST_ASSERT_EQUAL(length(SSnetrun.packet_captures), 256, "Payload history must have a global memory cap")
	TEST_ASSERT_NULL(SSnetrun.packet_captures[capture.id], "Old capture bodies must expire independently of metadata")

/datum/unit_test/proc/netrun_operation_result(datum/netrun_console/console, id)
	for(var/list/entry as anything in console.operations_payload())
		if(entry["id"] == id)
			return entry
	return null

/datum/unit_test/proc/netrun_packet_phase_count(datum/component/netrun_node/node, id, phase)
	var/count = 0
	for(var/list/entry as anything in node.packet_logs)
		if(entry["id"] == id && entry["phase"] == phase)
			count++
	return count

/datum/unit_test/proc/netrun_operation_packet(datum/netrun_console/console, packet_type)
	for(var/datum/netrun_request/delivery/packet as anything in SSnetrun.pending_requests)
		if(packet.console == console && istype(packet, packet_type))
			return packet
	return null

/datum/unit_test/netrun_operation_value_snapshots/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/netrun_console/console = allocate(/datum/netrun_console, host)
	var/datum/netrun_packet_context/operation = allocate(/datum/netrun_packet_context, "command", "Проверка", "SOURCE", "TARGET", "fixture", console, "original-nonce")
	var/list/hops = list("SOURCE", "MIDDLE", "TARGET")
	operation.queued(hops)
	hops[2] = "MUTATED"
	TEST_ASSERT_EQUAL(operation.route[2], "MIDDLE", "A delivery must own its route instead of retaining the caller's mutable list")
	var/list/snapshot = operation.snapshot()
	var/list/snapshot_route = snapshot["route"]
	snapshot_route[2] = "MUTATED"
	TEST_ASSERT_EQUAL(operation.route[2], "MIDDLE", "UI values must not alias a packet's immutable journal snapshot")
	console.input_ack = "newer-nonce"
	operation.running()
	operation.finish("completed")
	TEST_ASSERT(!operation.finish("rejected", "Late failure"), "A terminal result may be settled only once")
	var/list/result = netrun_operation_result(console, operation.id)
	TEST_ASSERT_EQUAL(result["nonce"], "original-nonce", "Completion must preserve the sender's explicit nonce")
	TEST_ASSERT_EQUAL(result["phase"], "completed", "A duplicate settlement must not downgrade the completed result")
	TEST_ASSERT_EQUAL(length(console.operations_payload()), 1, "Updating an operation must replace its value rather than append another history row")
	var/list/session = list()
	var/list/first_update = list()
	console.append_operations_payload(first_update, session)
	TEST_ASSERT(islist(first_update["operations"]), "A new viewer must receive its own operation history")
	var/list/quiet_update = list()
	console.append_operations_payload(quiet_update, session)
	TEST_ASSERT(!("operations" in quiet_update), "Unchanged operations must not repeat response bodies on every map update")
	var/list/refreshed = console.ui_static_data()
	TEST_ASSERT_EQUAL(length(refreshed["operations"]), 1, "A full browser refresh must restore history even when its server cursor is unchanged")
	qdel(console)
	TEST_ASSERT_NULL(operation.console_ref.resolve(), "An operation must not retain its deleted console")
	operation.finish("cancelled", "Ignored after completion")

/datum/unit_test/netrun_operation_bounded_history/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/netrun_console/console = allocate(/datum/netrun_console, host)
	var/datum/netrun_packet_context/pending = allocate(/datum/netrun_packet_context, "file", "Ожидание", "A", "B", "file", console)
	for(var/i in 1 to 40)
		var/datum/netrun_packet_context/operation = new("command", "Проверка", "A", "B", "fixture", console)
		operation.finish("completed")
		qdel(operation)
	TEST_ASSERT_EQUAL(length(console.operations_payload()), 32, "A console must keep a strict bounded operation history")
	TEST_ASSERT_NULL(netrun_operation_result(console, pending.id), "A busy history may evict a display snapshot")
	TEST_ASSERT(!QDELETED(pending), "Display eviction must not cancel the actual pending delivery")
	pending.finish("completed")
	TEST_ASSERT_EQUAL(length(console.operations_payload()), 32, "A late completion must keep the same history bound")
	var/list/result = netrun_operation_result(console, pending.id)
	TEST_ASSERT_EQUAL(result?["phase"], "completed", "The live owner must be able to republish a previously evicted operation")

/datum/unit_test/netrun_operation_command_journal/Run()
	var/datum/netrun_entity_contact_scene/scene = allocate(/datum/netrun_entity_contact_scene, run_loc_floor_bottom_left)
	scene.authorize()
	TEST_ASSERT(scene.console.run_command(scene.target_node, "scan", "command-nonce"), "A real command must enter its routed delivery")
	var/datum/netrun_request/command/packet = netrun_operation_packet(scene.console, /datum/netrun_request/command)
	TEST_ASSERT_NOTNULL(packet, "The command must own a delayed delivery object")
	var/id = packet.operation.id
	var/list/queued = netrun_operation_result(scene.console, id)
	TEST_ASSERT_EQUAL(queued?["phase"], "queued", "Admission must report queued rather than completed")
	scene.console.input_ack = "another-action"
	TEST_ASSERT(packet.deliver(), "The scan command must return its explicit handled result")
	var/list/result = netrun_operation_result(scene.console, id)
	TEST_ASSERT_EQUAL(result?["nonce"], "command-nonce", "A delayed command must not take a later receipt's nonce")
	TEST_ASSERT_EQUAL(result?["phase"], "completed", "A successful command delivery must report completion")
	TEST_ASSERT_EQUAL(netrun_packet_phase_count(scene.source_node, id, "SEND"), 1, "The source must record exactly one command emission")
	TEST_ASSERT_EQUAL(netrun_packet_phase_count(scene.apc.GetComponent(/datum/component/netrun_node), id, "FORWARD"), 1, "The real APC must record forwarding the command")
	TEST_ASSERT_EQUAL(netrun_packet_phase_count(scene.target_node, id, "RECEIVE"), 1, "The actual target must record command receipt")
	TEST_ASSERT_EQUAL(netrun_packet_phase_count(scene.target_node, id, "ACCEPT"), 1, "The command target must record one terminal acceptance")
	var/list/route = result["route"]
	TEST_ASSERT_EQUAL(route[1], scene.source_node.address, "The operation route must retain its actual source")
	TEST_ASSERT_EQUAL(route[length(route)], scene.target_node.address, "The operation route must retain its actual target")

/datum/unit_test/netrun_operation_preflight_and_revocation/Run()
	var/datum/netrun_entity_contact_scene/scene = allocate(/datum/netrun_entity_contact_scene, run_loc_floor_bottom_left)
	scene.authorize()
	scene.console.next_command = world.time + 5 SECONDS
	TEST_ASSERT(!scene.console.run_command(scene.target_node, "scan", "busy-nonce"), "A busy command channel must reject before sending")
	var/list/results = scene.console.operations_payload()
	var/list/busy = results[length(results)]
	TEST_ASSERT_EQUAL(busy["phase"], "rejected", "A preflight denial must have a correlated result")
	TEST_ASSERT_EQUAL(busy["nonce"], "busy-nonce", "A preflight denial must identify the rejected action")
	TEST_ASSERT_EQUAL(netrun_packet_phase_count(scene.source_node, busy["id"], "SEND"), 0, "A preflight denial must never invent a network emission")
	scene.console.next_command = 0
	TEST_ASSERT(scene.console.run_command(scene.target_node, "scan", "revoked-nonce"), "The available channel must admit a new packet")
	var/datum/netrun_request/command/packet = netrun_operation_packet(scene.console, /datum/netrun_request/command)
	var/id = packet.operation.id
	scene.console.access_session.network_access.Cut()
	TEST_ASSERT(!packet.deliver(), "Delivery must still enforce rights revoked after emission")
	var/list/rejected = netrun_operation_result(scene.console, id)
	TEST_ASSERT_EQUAL(rejected?["phase"], "rejected", "Revoked authorization must never appear completed")
	TEST_ASSERT(rejected["reason"], "A rejected delivery must explain the failed policy check")
	TEST_ASSERT_EQUAL(netrun_packet_phase_count(scene.target_node, id, "REJECT"), 1, "The destination must journal its actual refusal")

/datum/unit_test/netrun_operation_deleted_endpoint/Run()
	var/datum/netrun_entity_contact_scene/scene = allocate(/datum/netrun_entity_contact_scene, run_loc_floor_bottom_left)
	scene.authorize()
	TEST_ASSERT(scene.console.run_command(scene.target_node, "scan", "cancelled-nonce"), "The lifecycle case must begin with a live pending packet")
	var/datum/netrun_request/command/packet = netrun_operation_packet(scene.console, /datum/netrun_request/command)
	var/id = packet.operation.id
	var/source_address = scene.source_node.address
	var/target_address = scene.target_node.address
	qdel(scene.target_node)
	TEST_ASSERT(QDELETED(packet), "Deleting the endpoint must consume its pending packet")
	var/list/result = netrun_operation_result(scene.console, id)
	TEST_ASSERT_EQUAL(result?["phase"], "cancelled", "Dependency deletion must produce one terminal cancellation")
	TEST_ASSERT_EQUAL(result["from"], source_address, "Cancellation must preserve the sender's address")
	TEST_ASSERT_EQUAL(result["to"], target_address, "Cancellation must preserve the deleted endpoint's address")
	TEST_ASSERT_EQUAL(netrun_packet_phase_count(scene.source_node, id, "DROP"), 1, "Dependency cancellation must journal one dropped packet")

/datum/unit_test/netrun_operation_file_result/Run()
	var/datum/netrun_entity_contact_scene/scene = allocate(/datum/netrun_entity_contact_scene, run_loc_floor_bottom_left, 8)
	scene.authorize()
	scene.console.access_session.node_access[scene.target_node.address] = NETRUN_ACCESS_USER
	var/datum/netrun_file/file = new("private.txt", NETRUN_FILE_TEXT, "SECRET_OPERATION_PAYLOAD", 1)
	TEST_ASSERT(scene.console.store_file(file), "The sender must own a real source file")
	scene.target_node.file_store.capacity = 8
	var/baseline_files = length(scene.target_node.file_store.files)
	var/trace_before = scene.console.intrusion.trace
	TEST_ASSERT(scene.console.queue_file_request("upload", scene.target_node, file.uid, FALSE, "full-disk"), "An initially writable destination must admit the valid upload")
	var/datum/netrun_request/file/packet = netrun_operation_packet(scene.console, /datum/netrun_request/file)
	var/id = packet.operation.id
	scene.target_node.file_store.capacity = 0
	TEST_ASSERT(!packet.deliver(), "A destination that becomes read-only after dispatch must reject the actual write")
	var/list/rejected = netrun_operation_result(scene.console, id)
	TEST_ASSERT_EQUAL(rejected?["phase"], "rejected", "A failed file mutation must never appear completed")
	TEST_ASSERT_EQUAL(length(scene.target_node.file_store.files), baseline_files, "The rejected upload must not change the destination")
	TEST_ASSERT(file in scene.console.inventory.local_store.files, "Rejected delivery retains the only sender-owned original")
	TEST_ASSERT_EQUAL(scene.console.intrusion.trace, trace_before, "A rejected write adds no successful-execution trace")
	scene.console.next_command = 0
	TEST_ASSERT(!scene.console.queue_file_request("upload", scene.target_node, file.uid, FALSE, "preflight-full-disk"), "An already read-only destination rejects before network emission")
	TEST_ASSERT_EQUAL(scene.console.next_command, 0, "Storage preflight rejection cannot charge the command channel")
	var/list/results = scene.console.operations_payload()
	var/list/preflight = results[length(results)]
	TEST_ASSERT_EQUAL(preflight["nonce"], "preflight-full-disk", "Early disk rejection retains its own action receipt")
	TEST_ASSERT_EQUAL(preflight["phase"], "rejected", "Early disk rejection is a terminal refusal")
	TEST_ASSERT_EQUAL(netrun_packet_phase_count(scene.source_node, preflight["id"], "SEND"), 0, "An early disk refusal cannot invent a network emission")
	scene.target_node.file_store.capacity = 8
	scene.console.next_command = 0
	TEST_ASSERT(scene.console.queue_file_request("upload", scene.target_node, file.uid, FALSE, "free-disk"), "A recovered disk must admit a new independent upload")
	packet = netrun_operation_packet(scene.console, /datum/netrun_request/file)
	id = packet.operation.id
	TEST_ASSERT(packet.deliver(), "A real file mutation must report its successful handling")
	var/list/completed = netrun_operation_result(scene.console, id)
	TEST_ASSERT_EQUAL(completed?["phase"], "completed", "The completed file mutation must have a final result")
	TEST_ASSERT_EQUAL(length(scene.target_node.file_store.files), baseline_files + 1, "The accepted upload must create exactly one copy")
	TEST_ASSERT(!findtext(json_encode(scene.console.operations_payload()), "SECRET_OPERATION_PAYLOAD"), "Operation values must never expose file contents")
	TEST_ASSERT(!findtext(json_encode(scene.target_node.packet_logs), "SECRET_OPERATION_PAYLOAD"), "Node journals must never expose file contents")

/obj/item/netrun_operation_window_fixture
	var/executions = 0

/obj/item/netrun_operation_window_fixture/netrun_window_actions(datum/netrun_console/console, datum/component/netrun_node/node)
	return list(list("id" = "probe", "name" = "Проверка окна", "access" = NETRUN_ACCESS_GUEST))

/obj/item/netrun_operation_window_fixture/netrun_window_act(datum/netrun_console/console, datum/component/netrun_node/node, action, list/params)
	if(action == "probe")
		executions++
		return "Обработано."

/datum/unit_test/netrun_operation_window_result/Run()
	var/datum/netrun_entity_contact_scene/scene = allocate(/datum/netrun_entity_contact_scene, run_loc_floor_bottom_left)
	scene.authorize()
	var/obj/item/netrun_operation_window_fixture/target = allocate(/obj/item/netrun_operation_window_fixture, get_turf(scene.target_node.parent))
	var/datum/component/netrun_node/node = target.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
	SSnetrun.ensure_topology()
	TEST_ASSERT(scene.console.window_act(node.address, "probe", list("text" = "SECRET_WINDOW_ARGUMENT"), "window-nonce"), "A published native window action must be queued")
	var/datum/netrun_request/window/packet = netrun_operation_packet(scene.console, /datum/netrun_request/window)
	TEST_ASSERT_NOTNULL(packet, "Window actions must own their delivery context")
	var/id = packet.operation.id
	TEST_ASSERT(packet.deliver(), "A handled native window action must return an explicit result")
	TEST_ASSERT_EQUAL(target.executions, 1, "The native window callback must execute exactly once")
	var/list/result = netrun_operation_result(scene.console, id)
	TEST_ASSERT_EQUAL(result?["phase"], "completed", "Handling a window action must complete the same operation")
	TEST_ASSERT_EQUAL(result["nonce"], "window-nonce", "Window results must keep their dispatch nonce")
	TEST_ASSERT(!findtext(json_encode(node.packet_logs), "SECRET_WINDOW_ARGUMENT"), "Native request arguments must stay out of metadata journals")

/datum/unit_test/netrun_operation_machine_correlation/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/list/outcomes = list()
	TEST_ASSERT(scene.source.send("transport.fixture", new /datum/netrun_machine_message/transport_fixture(list("value" = "SECRET_MACHINE_PAYLOAD", "reply" = TRUE), outcomes), scene.target.service_tag()), "Cold discovery must admit the machine exchange")
	TEST_ASSERT(netrun_wait_delivery(outcomes), "The APC-discovered data exchange must complete")
	var/deadline = world.time + 1 SECONDS
	while(!scene.source.received && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT_EQUAL(scene.source.received, 1, "The actual reply must return before checking correlation")
	var/operation_id
	var/list/packet_ids = list()
	var/saw_data = FALSE
	for(var/datum/component/netrun_node/node as anything in list(scene.source.node, scene.target.node))
		for(var/list/entry as anything in node.packet_logs)
			if(entry["phase"] != "SEND")
				continue
			if(!operation_id)
				operation_id = entry["operation_id"]
			TEST_ASSERT_EQUAL(entry["operation_id"], operation_id, "Discovery, data and reply must share a logical correlation id")
			packet_ids |= entry["id"]
			TEST_ASSERT(entry["kind"] != "dns", "APC discovery must not create DNS wire packets")
			saw_data ||= entry["kind"] == "machine"
		TEST_ASSERT(!findtext(json_encode(node.packet_logs), "SECRET_MACHINE_PAYLOAD"), "Machine payloads must never leak into journals")
	TEST_ASSERT(saw_data && length(packet_ids) == 2, "One request/reply must use exactly two real data packets")
