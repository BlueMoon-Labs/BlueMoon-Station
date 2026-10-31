/// Find a public command entry rather than depending on its order in the registry.
/datum/unit_test/proc/netrun_command_entry(list/entries, command_id)
	for(var/list/entry as anything in entries)
		if(entry["id"] == command_id)
			return entry

/// The node card and its open window must expose the same live commands and permissions.
/datum/unit_test/netrun_context_commands/Run()
	var/obj/item/host = allocate(/obj/item)
	var/obj/item/target = allocate(/obj/item)
	var/datum/component/netrun_node/node = target.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL, list(), 2, list(ACCESS_RD))
	var/datum/component/techweb_holder/holder = target.AddComponent(/datum/component/techweb_holder)
	var/datum/netrun_console/console = allocate(/datum/netrun_console, host)
	console.connection.wireless = FALSE
	console.set_jack(node)
	TEST_ASSERT(console.open_window(node.address), "A physically connected node must open a window")
	TEST_ASSERT_EQUAL(console.node_level(node), NETRUN_ACCESS_GUEST, "Physical connection alone must not grant USER on a protected node")
	var/list/guest_entry = netrun_command_entry(node.command_entries(console), "web_copy")
	TEST_ASSERT_NOTNULL(guest_entry, "A techweb holder must contribute its commands dynamically")
	TEST_ASSERT(!guest_entry["allowed"], "Guest access must not allow copying the research network")
	TEST_ASSERT(length(guest_entry["help"]), "Context commands must carry their help text")

	var/datum/netrun_file/key = new("research.key", NETRUN_FILE_KEY, node.network.passcode, 1, node.network.id)
	TEST_ASSERT(console.store_file(key), "The legitimate network key must fit in memory")
	TEST_ASSERT_EQUAL(console.node_level(node), NETRUN_ACCESS_GUEST, "A LAN key must grant traversal without granting USER machine actions")
	console.access_session.node_access[node.address] = NETRUN_ACCESS_USER
	console.workspace_view = "map"
	var/list/payload = console.ui_data(null)
	var/list/selected = payload["selected"]
	var/list/window = console.window_payload()
	TEST_ASSERT_NOTNULL(selected, "Selecting a reachable node must populate its card")
	TEST_ASSERT_EQUAL(json_encode(selected["commands"]), json_encode(window["commands"]), "The node card and window must share command availability and help")
	var/list/copy_entry = netrun_command_entry(window["commands"], "web_copy")
	var/list/bind_entry = netrun_command_entry(window["commands"], "web_bind")
	TEST_ASSERT(copy_entry["allowed"], "A separate node USER grant must enable the USER command in the window")
	TEST_ASSERT(!bind_entry["allowed"], "A node USER grant must not enable a ROOT command")
	console.access_session.node_access[node.address] = NETRUN_ACCESS_ROOT
	window = console.window_payload()
	bind_entry = netrun_command_entry(window["commands"], "web_bind")
	TEST_ASSERT(bind_entry["allowed"], "Obtaining ROOT must immediately update the contextual window")
	qdel(holder)
	TEST_ASSERT_NULL(netrun_command_entry(node.command_entries(console), "web_copy"), "Removing the capability must remove its command without stale registry entries")

/// A failed move leaves the source intact; a successful move preserves one owner and one UID.
/datum/unit_test/netrun_storage_transfer/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/netrun_console/console = allocate(/datum/netrun_console, host)
	var/obj/item/netrun_shard/shard = allocate(/obj/item/netrun_shard)
	console.inventory.shard = shard
	console.inventory.local_store.capacity = 2
	shard.file_store.capacity = 1
	var/datum/netrun_file/document = new("report.txt", NETRUN_FILE_TEXT, "original", 2)
	TEST_ASSERT(console.store_file(document), "The source file must fit exactly in local memory")
	var/original_uid = document.uid
	TEST_ASSERT(!console.transfer_local_file(document, TRUE, TRUE), "A move to an undersized shard must fail")
	TEST_ASSERT(document in console.inventory.local_store.files, "A rejected move must retain the original file")
	TEST_ASSERT(!(document in shard.file_store.files), "A rejected move must not install a second owner")
	TEST_ASSERT(!QDELETED(document), "A rejected move must not delete the source")
	shard.file_store.capacity = 2
	TEST_ASSERT(console.transfer_local_file(document, TRUE, TRUE), "A move must accept a file that exactly fills the destination")
	TEST_ASSERT(!(document in console.inventory.local_store.files) && (document in shard.file_store.files), "A moved file must belong only to the shard")
	TEST_ASSERT_EQUAL(document.uid, original_uid, "Moving a file must preserve its stable UID")
	TEST_ASSERT_EQUAL(netrun_storage_used(console.inventory.local_store.files), 0, "The move must release source capacity")
	TEST_ASSERT_EQUAL(netrun_storage_used(shard.file_store.files), 2, "The move must charge destination capacity")
	TEST_ASSERT(console.transfer_local_file(document, FALSE, TRUE), "The same file must move back into local memory")
	TEST_ASSERT((document in console.inventory.local_store.files) && !(document in shard.file_store.files), "The return move must release shard ownership")
	TEST_ASSERT(console.transfer_local_file(document, TRUE, FALSE), "Copying to the shard must create a separate file")
	var/datum/netrun_file/copied = console.selected_local_file()
	TEST_ASSERT_NOTNULL(copied, "The new copy must become the selected local file")
	TEST_ASSERT_NOTEQUAL(copied, document, "Copying must not share the owning file datum")
	TEST_ASSERT_NOTEQUAL(copied.uid, document.uid, "Two copies must not share an addressing UID")
	TEST_ASSERT(console.edit_text_file(copied, "edited copy"), "The copied text must remain editable")
	TEST_ASSERT_EQUAL(document.content, "original", "Editing the copy must preserve the source")
	console.delete_local_file(copied)
	TEST_ASSERT(!QDELETED(document) && (document in console.inventory.local_store.files), "Deleting the shard copy must preserve the source file")

/// Rich file payloads survive copying without either deleting the other's photograph or techweb.
/datum/unit_test/netrun_rich_file_copy/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/netrun_console/console = allocate(/datum/netrun_console, host)
	console.inventory.local_store.capacity = 10
	var/datum/netrun_file/photo = new("frame.png", NETRUN_FILE_PHOTO, "", 3)
	photo.picture = new /datum/picture("frame", "camera frame", icon('icons/effects/camera_image_base.dmi'), null, 32, 32, FALSE, "original caption")
	TEST_ASSERT(console.store_file(photo), "The original picture must fit in memory")
	var/datum/netrun_file/photo_copy = photo.copy()
	TEST_ASSERT(console.store_file(photo_copy), "The picture copy must fit in memory")
	TEST_ASSERT_NOTEQUAL(photo.picture, photo_copy.picture, "Picture datums must not share deletion ownership")
	TEST_ASSERT_NOTEQUAL(photo.picture.picture_image, photo_copy.picture.picture_image, "Picture pixels must be copied independently")
	TEST_ASSERT_EQUAL(photo_copy.picture.caption, "original caption", "Copying a picture must retain its caption")
	photo_copy.picture.caption = "copy caption"
	TEST_ASSERT_EQUAL(photo.picture.caption, "original caption", "Editing a copied picture must not mutate its source")
	console.delete_local_file(photo)
	TEST_ASSERT(!QDELETED(photo_copy.picture), "Deleting the original file must leave the copied picture alive")
	TEST_ASSERT_NOTNULL(photo_copy.picture.picture_image, "The surviving picture must retain its actual pixels")

	var/datum/techweb/web = allocate(/datum/techweb)
	var/datum/netrun_file/link = new("research.link", NETRUN_FILE_TECHWEB_LINK, web.organization, 1)
	link.techweb_ref = WEAKREF(web)
	TEST_ASSERT(console.store_file(link), "The techweb link must fit in memory")
	var/datum/netrun_file/link_copy = link.copy()
	TEST_ASSERT(console.store_file(link_copy), "The techweb link copy must fit in memory")
	TEST_ASSERT_EQUAL(link_copy.techweb_ref.resolve(), web, "A copied link must resolve to the same live research network")
	console.delete_local_file(link)
	TEST_ASSERT(!QDELETED(web), "A link file must not own or delete its research network")
	TEST_ASSERT_EQUAL(link_copy.techweb_ref.resolve(), web, "Deleting one link must not invalidate the other")
	qdel(web)
	TEST_ASSERT_NULL(link_copy.techweb_ref.resolve(), "A link must safely expire when the actual research network is deleted")

/// Delivery runs after the environment changes, just as a queued callback does, without timer sleeps.
/datum/unit_test/netrun_delivery_revalidates/Run()
	var/obj/item/host = allocate(/obj/item)
	var/obj/item/target = allocate(/obj/item)
	var/datum/component/netrun_node/node = target.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL, list(), 2, list(ACCESS_RD))
	target.AddComponent(/datum/component/techweb_holder)
	var/datum/techweb/web = allocate(/datum/techweb)
	SEND_SIGNAL(target, COMSIG_ATOM_SET_TECHWEB, web)
	var/datum/netrun_console/console = allocate(/datum/netrun_console, host)
	console.connection.wireless = FALSE
	console.set_jack(node)
	var/datum/netrun_file/key = new("research.key", NETRUN_FILE_KEY, node.network.passcode, 1, node.network.id)
	TEST_ASSERT(console.store_file(key), "The delivery test needs a legitimate LAN traversal key")
	console.access_session.node_access[node.address] = NETRUN_ACCESS_USER
	var/datum/netrun_network/sent_network = node.network
	var/datum/netrun_command/command = SSnetrun.get_command("web_copy")
	TEST_ASSERT(console.do_command(node, command, "web_copy", FALSE, sent_network, null, "none"), "An unchanged authorized request must execute")
	var/files_before = length(console.inventory.local_store.files)

	console.set_jack(null)
	host.moveToNullspace()
	TEST_ASSERT(!console.can_route(node), "Removing the cable and physical host must actually remove the route")
	TEST_ASSERT(!console.do_command(node, command, "web_copy", FALSE, sent_network, null, "none"), "A request must be cancelled when its route disappears")
	TEST_ASSERT_EQUAL(length(console.inventory.local_store.files), files_before, "A cancelled request must not copy research data")
	host.forceMove(run_loc_floor_bottom_left)
	console.set_jack(node)
	TEST_ASSERT(console.can_route(node), "Restoring the physical connection must restore the route")
	console.delete_local_file(key)
	console.access_session.node_access -= node.address
	files_before = length(console.inventory.local_store.files)
	TEST_ASSERT_EQUAL(console.node_level(node), NETRUN_ACCESS_GUEST, "Removing the node's USER grant must revoke machine authorization")
	TEST_ASSERT(!console.do_command(node, command, "web_copy", FALSE, sent_network, null, "none"), "A request must be cancelled when its authorization expires")
	TEST_ASSERT_EQUAL(length(console.inventory.local_store.files), files_before, "An unauthorized delivery must not create a file")

	// The callback still carries the previous LAN while the target is attached to its current one.
	// Leave real turf classification intact so delivery may refresh join_network() itself.
	var/datum/netrun_network/previous_network = allocate(/datum/netrun_network, "unit-test-netrun-[REF(src)]")
	var/datum/netrun_file/current_key = new("current.key", NETRUN_FILE_KEY, node.network.passcode, 1, node.network.id)
	TEST_ASSERT(console.store_file(current_key), "The current network key must fit in memory")
	console.access_session.node_access[node.address] = NETRUN_ACCESS_USER
	TEST_ASSERT(console.can_route(node) && console.node_level(node) >= NETRUN_ACCESS_USER, "The current LAN must be independently reachable and authorized")
	files_before = length(console.inventory.local_store.files)
	TEST_ASSERT(!console.do_command(node, command, "web_copy", FALSE, previous_network, null, "none"), "A request sent to the previous LAN must not follow the node into another LAN")
	TEST_ASSERT_EQUAL(length(console.inventory.local_store.files), files_before, "A cancelled old-LAN request must not create a file")

/// A command in flight must use its chosen UID even when the operator selects a different file.
/datum/unit_test/netrun_delivery_keeps_file_selection/Run()
	var/obj/item/host = allocate(/obj/item)
	var/obj/item/target = allocate(/obj/item)
	var/datum/component/netrun_node/node = target.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL, list(), 2, list(ACCESS_RD))
	target.AddComponent(/datum/component/techweb_holder)
	var/datum/techweb/first_web = allocate(/datum/techweb)
	var/datum/techweb/second_web = allocate(/datum/techweb)
	var/datum/netrun_console/console = allocate(/datum/netrun_console, host)
	console.connection.wireless = FALSE
	console.set_jack(node)
	console.access_session.node_access[node.address] = NETRUN_ACCESS_ROOT
	var/datum/netrun_file/first = new("first.link", NETRUN_FILE_TECHWEB_LINK, "first", 1)
	first.techweb_ref = WEAKREF(first_web)
	var/datum/netrun_file/second = new("second.link", NETRUN_FILE_TECHWEB_LINK, "second", 1)
	second.techweb_ref = WEAKREF(second_web)
	TEST_ASSERT(console.store_file(first) && console.store_file(second), "Both candidate link files must fit in memory")
	console.inventory.selected_file_uid = second.uid
	var/datum/netrun_command/command = SSnetrun.get_command("web_bind")
	TEST_ASSERT(console.do_command(node, command, "web_bind", TRUE, node.network, null, first.uid), "A request with a live captured UID must execute")
	TEST_ASSERT_EQUAL(netrun_atom_techweb(target), first_web, "Changing the UI selection must not change an already sent request")
	TEST_ASSERT_EQUAL(console.inventory.selected_file_uid, second.uid, "Delivering the request must preserve the user's newer UI selection")
	var/deleted_uid = first.uid
	console.delete_local_file(first)
	console.do_command(node, command, "web_bind", TRUE, node.network, null, deleted_uid)
	TEST_ASSERT_EQUAL(netrun_atom_techweb(target), first_web, "A deleted captured file must not silently fall back to the newer selection")

/// Machine adapters publish an explicit schema, never the arbitrary ui_act parameter bag.
/datum/unit_test/netrun_api_parameter_whitelist/Run()
	var/datum/netrun_api/fabricator/api = allocate(/datum/netrun_api/fabricator)
	var/list/clean = api.clean_params("build", list("id" = "powercell", "amount" = "2", "force" = TRUE, "path" = "/obj/item"))
	TEST_ASSERT_NOTNULL(clean, "A valid published production request must be accepted")
	TEST_ASSERT_EQUAL(clean["id"], "powercell", "The design identifier must survive validation")
	TEST_ASSERT_EQUAL(clean["amount"], 2, "A validated numeric argument must reach the machine as a number")
	TEST_ASSERT_EQUAL(length(clean), 2, "Unknown parameters must not cross the adapter boundary")
	TEST_ASSERT_NULL(clean["force"], "An injected force flag must be discarded")
	TEST_ASSERT_NULL(clean["path"], "An injected construction path must be discarded")
	TEST_ASSERT_NULL(api.clean_params("purge_chem", list("chem" = "all")), "An unpublished native machine action must be rejected")
	TEST_ASSERT_NULL(api.clean_params("build", list("id" = "powercell")), "Required arguments must not be invented")
	TEST_ASSERT_NULL(api.clean_params("build", list("id" = list("nested"), "amount" = 1)), "Structured values must not become text identifiers")
	TEST_ASSERT_NULL(api.clean_params("build", list("id" = "powercell", "amount" = "not-a-number")), "Malformed numbers must be rejected")
	TEST_ASSERT_NULL(api.clean_params("build", list("id" = "powercell", "amount" = 0)), "Amounts below the published minimum must be rejected")
	TEST_ASSERT_NULL(api.clean_params("build", list("id" = "powercell", "amount" = 61)), "Amounts above the published maximum must be rejected")

/// An authorized network operator can use published controls but cannot forge a native action ID.
/datum/unit_test/netrun_api_rejects_unpublished_action/Run()
	var/obj/item/host = allocate(/obj/item)
	var/obj/machinery/porta_turret/turret = allocate(/obj/machinery/porta_turret)
	turret.set_machine_stat(0)
	var/datum/component/netrun_node/node = turret.GetComponent(/datum/component/netrun_node)
	if(!node)
		node = turret.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TURRET, list(), 2, list())
	var/datum/netrun_console/console = allocate(/datum/netrun_console, host)
	console.operator = allocate(/mob)
	console.connection.wireless = FALSE
	console.set_jack(node)
	console.access_session.node_access[node.address] = NETRUN_ACCESS_ROOT
	TEST_ASSERT(console.can_route(node) && node.is_online(), "The real turret fixture must be reachable and online")
	TEST_ASSERT_EQUAL(console.node_level(node), NETRUN_ACCESS_ROOT, "The test operator must have enough rights for published turret controls")
	var/original_locked = turret.locked
	TEST_ASSERT(!console.remote_request(node.address, "ai_auth", list()), "A native silicon-only action not published by the adapter must be rejected")
	TEST_ASSERT_EQUAL(turret.locked, original_locked, "The forged request must not toggle the machine's lock")
	TEST_ASSERT_EQUAL(console.next_command, 0, "An unpublished action must not be scheduled for delivery")
	var/original_flags = turret.turret_flags
	TEST_ASSERT(console.remote_request(node.address, "shootall", list()), "An authorized published control must reach the machine")
	var/datum/netrun_request/remote/packet = netrun_operation_packet(console, /datum/netrun_request/remote)
	TEST_ASSERT_NOTNULL(packet, "A published UI control must own its queued delivery")
	TEST_ASSERT(packet.deliver(), "The queued control must pass the native delivery boundary")
	TEST_ASSERT_EQUAL(turret.turret_flags, original_flags ^ TURRET_FLAG_SHOOT_ALL, "The published action must use the real machine implementation")

/// The service wire cannot keep its direct route after the client moves away or changes Z.
/datum/unit_test/netrun_cable_route/Run()
	var/obj/item/host = allocate(/obj/item)
	var/obj/item/target = allocate(/obj/item)
	var/datum/component/netrun_node/node = target.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL, list(), 2, list())
	var/datum/netrun_console/console = allocate(/datum/netrun_console, host)
	console.connection.wireless = TRUE
	console.set_jack(node)
	TEST_ASSERT(console.jack_valid(), "A cable to the same turf must be valid")
	TEST_ASSERT_EQUAL(console.latency_to(node), 0, "A direct cable must avoid relay latency")
	host.forceMove(run_loc_floor_top_right)
	TEST_ASSERT(!console.jack_valid(), "Moving away must invalidate the cable immediately")
	TEST_ASSERT(!console.can_route(node), "An isolated LAN must not remain reachable through a stretched cable")
	TEST_ASSERT(console.latency_to(node) > 0, "An invalid cable must not retain direct latency")
	host.forceMove(locate(run_loc_floor_bottom_left.x, run_loc_floor_bottom_left.y, 1))
	TEST_ASSERT(!console.jack_valid(), "Matching coordinates on another Z must not count as a valid cable")

/// A gateway protects a whole LAN and must require a harder puzzle than its strongest node.
/datum/unit_test/netrun_gateway_protocol/Run()
	var/obj/item/host = allocate(/obj/item)
	var/obj/item/target = allocate(/obj/item)
	var/datum/component/netrun_node/node = target.AddComponent(/datum/component/netrun_node, NETRUN_NODE_SERVER, list(), 5, list())
	var/datum/netrun_console/console = allocate(/datum/netrun_console, host)
	console.connection.wireless = FALSE
	console.set_jack(node)
	var/security = node.network.breach_security()
	TEST_ASSERT(security >= node.get_security(), "A gateway must account for its strongest member")
	var/datum/netrun_breach/machine = allocate(/datum/netrun_breach, console, "node", node.address, "machine", node.get_security())
	var/datum/netrun_breach/gateway = allocate(/datum/netrun_breach, console, "network", node.network.id, "gateway", security)
	TEST_ASSERT(gateway.size > machine.size, "The gateway matrix must be larger on the same hardware")
	TEST_ASSERT(gateway.deadline < machine.deadline, "The gateway must give less time on the same hardware")
	var/list/machine_access = machine.daemons[1]
	var/list/gateway_access = gateway.daemons[1]
	TEST_ASSERT(length(gateway_access["sequence"]) > length(machine_access["sequence"]), "Gateway access must require a longer sequence")
