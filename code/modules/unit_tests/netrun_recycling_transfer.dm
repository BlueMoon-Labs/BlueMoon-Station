/// Deposit is an ordinary delivered file packet and moves the original once.
/datum/unit_test/netrun_recycling_delivered_move/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/bot/collector = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_b, "collector")
	var/datum/netrun_console/console = collector.console
	var/datum/netrun_file/file = new("recovered.txt", NETRUN_FILE_TEXT, "real cargo", 2)
	TEST_ASSERT(console.store_file(file), "Recovered cargo occupies the collector's actual memory")
	scene.node_b.file_store.capacity = scene.node_b.used_storage() + file.size
	console.map_view.selected_address = scene.node_a.address
	TEST_ASSERT(console.deposit_to_node(file.uid, scene.node_b, input_nonce = "deposit-original"), "A local USER may queue unloading at the explicit server")
	var/datum/netrun_request/file/packet = netrun_operation_packet(console, /datum/netrun_request/file)
	TEST_ASSERT_NOTNULL(packet, "Unloading is represented by a real cancellable file packet")
	TEST_ASSERT_EQUAL(packet.node, scene.node_b, "Changing UI selection cannot replace the requested server")
	TEST_ASSERT(!packet.delivery_interactive(), "A collector uses the autonomous queue lane")
	TEST_ASSERT_EQUAL(console.inventory.local_store.find_file(file.uid), file, "Admission retains ownership in the collector")
	TEST_ASSERT_NULL(scene.node_b.file_store.find_file(file.uid), "Admission does not teleport or pre-copy cargo")
	var/id = packet.operation.id
	TEST_ASSERT(packet.deliver(), "Delivery accepts the live original at the exact available capacity")
	TEST_ASSERT_NULL(console.inventory.local_store.find_file(file.uid), "Successful unloading frees the collector's memory")
	TEST_ASSERT_EQUAL(scene.node_b.file_store.find_file(file.uid), file, "The server owns the same file and UID, not a duplicate")
	var/list/result = netrun_operation_result(console, id)
	TEST_ASSERT_EQUAL(result["phase"], "completed", "The unified operation channel reports completion")
	TEST_ASSERT_EQUAL(result["nonce"], "deposit-original", "Completion preserves the source request's nonce")

/// Every delayed boundary failure leaves the actual file where it currently is.
/datum/unit_test/netrun_recycling_delivery_revalidation/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/bot/collector = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_b, "collector")
	var/datum/netrun_console/console = collector.console
	var/datum/netrun_file/file = new("cargo.txt", NETRUN_FILE_TEXT, "cargo", 2)
	TEST_ASSERT(console.store_file(file), "The fixture owns a real cargo file")
	scene.node_b.file_store.capacity = scene.node_b.used_storage() + 4
	TEST_ASSERT(console.deposit_to_node(file.uid, scene.node_b), "A valid local request is admitted")
	var/datum/netrun_request/file/packet = netrun_operation_packet(console, /datum/netrun_request/file)
	collector.enter_node(scene.node_a)
	TEST_ASSERT(!packet.deliver(), "Leaving the server before delivery rejects unloading even with a remaining network route")
	TEST_ASSERT_EQUAL(console.inventory.local_store.find_file(file.uid), file, "A rejected remote deposit retains its original")
	collector.enter_node(scene.node_b)
	console.next_command = world.time
	TEST_ASSERT(console.deposit_to_node(file.uid, scene.node_b), "Returning to the server may submit a fresh request")
	packet = netrun_operation_packet(console, /datum/netrun_request/file)
	scene.node_b.file_store.capacity = scene.node_b.used_storage()
	TEST_ASSERT(!packet.deliver(), "Another writer filling the destination rejects the move at delivery")
	TEST_ASSERT_EQUAL(console.inventory.local_store.find_file(file.uid), file, "Capacity failure is atomic and never deletes cargo")
	scene.node_b.file_store.capacity += 4
	console.next_command = world.time
	TEST_ASSERT(console.deposit_to_node(file.uid, scene.node_b), "A fresh request may be admitted after memory is available")
	packet = netrun_operation_packet(console, /datum/netrun_request/file)
	console.access_session.revoke_node(scene.node_b.address)
	TEST_ASSERT(!packet.deliver(), "Losing USER before delivery rejects the ordinary file action")
	TEST_ASSERT_EQUAL(console.inventory.local_store.find_file(file.uid), file, "ACL rejection leaves the source intact")
	console.access_session.grant_node(scene.node_b, NETRUN_ACCESS_USER)
	console.next_command = world.time
	TEST_ASSERT(console.deposit_to_node(file.uid, scene.node_b), "A restored ordinary grant may submit a new request")
	packet = netrun_operation_packet(console, /datum/netrun_request/file)
	var/obj/item/netrun_shard/shard = allocate(/obj/item/netrun_shard)
	TEST_ASSERT(console.inventory.local_store.transfer_to(shard.file_store, file, TRUE), "The live source may move to another real disk while the request is in flight")
	TEST_ASSERT(!packet.deliver(), "A UID no longer owned in local memory cannot be unloaded from a shard")
	TEST_ASSERT_EQUAL(shard.file_store.find_file(file.uid), file, "Rejected delivery preserves the actual new owner")
	TEST_ASSERT_NULL(scene.node_b.file_store.find_file(file.uid), "None of the rejected deliveries left a server copy")

/datum/netrun_file/recycling_restricted/can_transfer(datum/netrun_file_store/destination, move = FALSE)
	return FALSE

/// File restrictions and goal cancellation share the existing owned packet lifecycle.
/datum/unit_test/netrun_recycling_restrictions_and_cancellation/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/bot/collector = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_b, "collector")
	var/datum/netrun_console/console = collector.console
	var/datum/netrun_file/recycling_restricted/restricted = new("bound.txt", NETRUN_FILE_TEXT, "bound")
	TEST_ASSERT(console.store_file(restricted), "A transport-restricted source can still be owned locally")
	TEST_ASSERT(!console.deposit_to_node(restricted.uid, scene.node_b), "Deposit cannot bypass file.can_transfer")
	TEST_ASSERT_EQUAL(console.inventory.local_store.find_file(restricted.uid), restricted, "Admission failure leaves the original intact")
	var/datum/netrun_file/file = new("cancelled.txt", NETRUN_FILE_TEXT, "cancelled")
	TEST_ASSERT(console.store_file(file), "The collector also owns ordinary movable cargo")
	TEST_ASSERT(!console.deposit_to_node(file.uid, scene.node_a), "A collector cannot submit remote unloading to another endpoint")
	collector.brain.command_nonce = "deposit-cancel"
	TEST_ASSERT(console.deposit_to_node(file.uid, scene.node_b, input_nonce = collector.brain.command_nonce), "A module may use the common brain nonce channel")
	var/datum/netrun_request/file/packet = collector.brain.command_packet_ref?.resolve()
	TEST_ASSERT_NOTNULL(packet, "track_file_packet binds the matching pending file packet to its goal")
	var/id = packet.operation.id
	collector.brain.clear_goals()
	TEST_ASSERT(QDELETED(packet), "Replacing a goal cancels its outstanding deposit through the ordinary lifecycle")
	TEST_ASSERT_EQUAL(console.inventory.local_store.find_file(file.uid), file, "Cancellation never consumes in-flight cargo")
	TEST_ASSERT_NULL(scene.node_b.file_store.find_file(file.uid), "Cancelled work cannot leave a duplicate at the destination")
	var/list/result = netrun_operation_result(console, id)
	TEST_ASSERT_EQUAL(result["phase"], "cancelled", "The same operation channel reports cancellation")
