/// Dedicated pages do not erase active jobs, pinned nodes or local file selection.
/datum/unit_test/netrun_workspace_pages/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, origin.z)
	var/area/room = scene.room(/area/netrun_route_test)
	scene.take(origin, room)
	var/turf/apc_spot = scene.take(get_step(origin, NORTH), room)
	scene.machine(/obj/machinery/power/apc, apc_spot)
	var/obj/machinery/computer/netrun_terminal/terminal = scene.machine(/obj/machinery/computer/netrun_terminal, origin)
	var/datum/component/netrun_node/node = terminal.GetComponent(/datum/component/netrun_node)
	var/datum/netrun_console/console = terminal.console
	SSnetrun.ensure_topology()
	console.map_view.selected_address = node.address
	TEST_ASSERT(console.create_text_file("draft.txt", "persistent file"), "The workspace needs a real selected local file")
	var/uid = console.inventory.selected_file_uid
	var/list/data = console.ui_data(null)
	TEST_ASSERT_EQUAL(data["workspace_view"], "terminal", "A new session must start on the dedicated terminal page")
	TEST_ASSERT_NULL(data["map"], "A hidden map must not serialize a full graph")
	TEST_ASSERT(console.start_breach("node", node.address), "The fixture must run a real breach")
	TEST_ASSERT_EQUAL(console.workspace_view, "breach", "A new breach must open its own workspace")
	var/datum/netrun_breach/job = console.intrusion.breach
	data = console.ui_data(null)
	var/list/file = data["file"]
	TEST_ASSERT_NULL(file, "A puzzle must not serialize a hidden file editor or photo preview")
	TEST_ASSERT_EQUAL(console.inventory.selected_file_uid, uid, "A puzzle preserves file selection without serializing its content")
	console.workspace_view = "map"
	data = console.ui_data(null)
	TEST_ASSERT_NOTNULL(data["map"], "The map page must be available while a breach is running")
	TEST_ASSERT_NOTNULL(data["breach"], "Browsing the map must preserve the active breach")
	TEST_ASSERT_EQUAL(console.intrusion.breach, job, "Page navigation must never replace the job")
	TEST_ASSERT(console.open_window(node.address), "A permitted node must be pinnable")
	TEST_ASSERT_EQUAL(console.workspace_view, "pinned", "Pinning a node must open the dedicated pinned workspace")
	data = console.ui_data(null)
	TEST_ASSERT_NOTNULL(data["window"], "Pinned nodes must remain operable during a breach")
	TEST_ASSERT_NULL(data["map"], "Pinned workspace must not contain the hidden map")
	console.workspace_view = "files"
	data = console.ui_data(null)
	file = data["file"]
	TEST_ASSERT_EQUAL(file["uid"], uid, "The file workspace must retain the selected local file")
	TEST_ASSERT_NOTNULL(data["selected"], "File upload controls need the selected remote node's permissions")
	TEST_ASSERT_EQUAL(console.remote_session.active_window, node.address, "Leaving the pinned page must preserve its active node")
	console.workspace_view = "agents"
	data = console.ui_data(null)
	file = data["file"]
	TEST_ASSERT_EQUAL(file["uid"], uid, "The agent workspace shares the preserved file selection")
	TEST_ASSERT_NOTNULL(data["selected"], "Addressed agent orders retain their selected-node context")
	TEST_ASSERT_NULL(data["selected"]["files"], "Agent controls do not serialize the hidden remote disk")

/// Highlighting an APC transmits actual area tiles rather than its bounding rectangle.
/datum/unit_test/netrun_apc_geographic_area/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, origin.z)
	var/area/room = scene.room(/area/netrun_route_test)
	var/list/tiles = list(origin, get_step(origin, EAST), get_step(origin, NORTH), locate(origin.x + 3, origin.y + 1, origin.z))
	for(var/turf/spot as anything in tiles)
		scene.take(spot, room)
	var/obj/machinery/power/apc/apc = scene.machine(/obj/machinery/power/apc, origin)
	var/obj/machinery/computer/netrun_terminal/terminal = scene.machine(/obj/machinery/computer/netrun_terminal, origin)
	var/datum/component/netrun_node/apc_node = apc.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/terminal_node = terminal.GetComponent(/datum/component/netrun_node)
	SSnetrun.ensure_topology()
	terminal.console.workspace_view = "map"
	terminal.console.map_view.selected_address = apc_node.address
	var/list/data = terminal.console.ui_data(null)
	var/list/map = data["map"]
	var/list/zones = map["apc_zones"]
	TEST_ASSERT_EQUAL(length(zones), 1, "Only the selected APC area should be highlighted")
	var/list/zone = zones[1]
	TEST_ASSERT_EQUAL(zone["address"], apc_node.address, "The highlight must identify the selected physical APC")
	var/list/runs = zone["runs"]
	var/list/reconstructed = list()
	for(var/list/run as anything in runs)
		for(var/x = run["x"], x < run["x"] + run["width"], x++)
			reconstructed["[x],[run["y"]]"] = TRUE
	TEST_ASSERT_EQUAL(length(reconstructed), length(tiles), "Runs must preserve holes and disconnected native area tiles")
	for(var/turf/spot as anything in tiles)
		TEST_ASSERT(reconstructed["[spot.x],[spot.y]"], "Every native APC area tile must appear in its shape")
	TEST_ASSERT(!reconstructed["[origin.x + 2],[origin.y]"], "The bounding box's missing tiles must not be filled")
	var/list/entries = map["nodes"]
	for(var/list/entry as anything in entries)
		if(entry["address"] != terminal_node.address)
			continue
		TEST_ASSERT_EQUAL(entry["x"], origin.x, "Map X must match physical turf X")
		TEST_ASSERT_EQUAL(entry["y"], origin.y, "Map Y must match physical turf Y")
		TEST_ASSERT_EQUAL(entry["apc"], apc_node.address, "The endpoint must publish its actual APC binding")

/// Cached ID credentials stay a list while pages serialize their independent payloads.
/datum/unit_test/netrun_cached_id_list/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/netrun_console/console = allocate(/datum/netrun_console, host)
	console.access_cache = list(ACCESS_MEDICAL, ACCESS_NETWORK)
	TEST_ASSERT(islist(console.user_access()), "A cached access read must return its ID list")
	TEST_ASSERT(ACCESS_MEDICAL in console.user_access(), "Cached ID access must preserve every access code")
	TEST_ASSERT(!(ACCESS_MEDICAL in console.user_access(TRUE)), "A fresh access read must not reuse a cached operator snapshot")

/// Sector browsing filters physical nodes without moving the source or fabricating gateway nodes.
/datum/unit_test/netrun_map_sector_browsing/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, origin.z)
	var/area/local_room = scene.room(/area/netrun_route_test)
	var/area/remote_room = scene.room(/area/netrun_route_test)
	var/list/levels = multiz_gravity_test_levels()
	scene.mark_station(levels[1])
	scene.take(origin, local_room)
	var/turf/apc_spot = scene.take(get_step(origin, NORTH), local_room)
	var/turf/relay_spot = scene.take(get_step(apc_spot, NORTH), local_room)
	var/turf/remote_apc_spot = scene.take(locate(81, 80, levels[1]), remote_room, TRUE)
	var/turf/remote_relay_spot = scene.take(locate(82, 80, levels[1]), remote_room, TRUE)
	scene.machine(/obj/machinery/power/apc, apc_spot)
	scene.machine(/obj/machinery/power/apc, remote_apc_spot)
	var/obj/machinery/computer/netrun_terminal/source = scene.machine(/obj/machinery/computer/netrun_terminal, origin)
	var/obj/machinery/ntnet_relay/local_relay = scene.machine(/obj/machinery/ntnet_relay, relay_spot)
	var/obj/machinery/ntnet_relay/remote_relay = scene.machine(/obj/machinery/ntnet_relay, remote_relay_spot)
	var/datum/component/netrun_node/local_node = local_relay.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/remote_node = remote_relay.GetComponent(/datum/component/netrun_node)
	SSnetworks.station_network.setting_disabled = FALSE
	SSnetrun.ensure_topology()
	source.console.workspace_view = "map"
	source.console.map_view.selected_address = local_node.address
	var/list/data = source.console.ui_data(null)
	var/list/map = data["map"]
	TEST_ASSERT(netrun_map_has_node(data, local_node.address), "The initial map must include the current sector's relay")
	TEST_ASSERT(!netrun_map_has_node(data, remote_node.address), "A remote-sector relay must not be drawn among local physical nodes")
	var/list/destinations = map["relay_destinations"]
	var/found = FALSE
	for(var/list/destination as anything in destinations)
		if(destination["to"] == remote_node.address)
			found = TRUE
	TEST_ASSERT(found, "The selected relay must expose its actual remote gateway destination")
	TEST_ASSERT(source.console.map_view.select_sector(remote_node.binding_sector, remote_relay_spot.z), "A disclosed destination sector must be browsable")
	data = source.console.ui_data(null)
	map = data["map"]
	TEST_ASSERT(netrun_map_has_node(data, remote_node.address), "Switching sectors must display remote physical coordinates")
	TEST_ASSERT(!netrun_map_has_node(data, local_node.address), "Sector switching must unload nodes from the other sector")
	TEST_ASSERT_EQUAL(get_turf(source), origin, "Browsing a sector must not teleport the physical client")
	TEST_ASSERT(!source.console.map_view.select_sector("sector:forged", 999), "An undisclosed or forged sector must not be accepted")
	source.console.map_view.follow_source()
	data = source.console.ui_data(null)
	TEST_ASSERT(netrun_map_has_node(data, local_node.address), "Return to source must restore the source sector")

/// An offscreen source changing departments must replace the remote floor's permissions.
/datum/unit_test/netrun_map_remote_floor_source_lan/Run()
	var/list/levels = multiz_gravity_test_levels()
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, levels[1])
	scene.mark_station(levels[2])
	var/area/lower_engineering = scene.room(/area/engineering/netrun_route_test)
	var/area/lower_medical = scene.room(/area/medical/netrun_route_test)
	var/area/upper_engineering = scene.room(/area/engineering/netrun_route_test)
	var/area/upper_medical = scene.room(/area/medical/netrun_route_test)
	var/turf/source_spot = scene.take(locate(80, 80, levels[1]), lower_engineering, TRUE)
	var/turf/destination = scene.take(locate(84, 80, levels[1]), lower_medical, TRUE)
	var/turf/engineering_spot = scene.take(locate(80, 80, levels[2]), upper_engineering, TRUE)
	var/turf/medical_spot = scene.take(locate(84, 80, levels[2]), upper_medical, TRUE)
	scene.machine(/obj/machinery/power/apc, scene.take(locate(81, 80, levels[1]), lower_engineering, TRUE))
	scene.machine(/obj/machinery/power/apc, scene.take(locate(85, 80, levels[1]), lower_medical, TRUE))
	scene.machine(/obj/machinery/power/apc, scene.take(locate(81, 80, levels[2]), upper_engineering, TRUE))
	scene.machine(/obj/machinery/power/apc, scene.take(locate(85, 80, levels[2]), upper_medical, TRUE))
	var/obj/machinery/computer/netrun_terminal/source = scene.machine(/obj/machinery/computer/netrun_terminal, source_spot)
	var/obj/item/engineering_device = new(engineering_spot)
	var/obj/item/medical_device = new(medical_spot)
	scene.owned += engineering_device
	scene.owned += medical_device
	var/datum/component/netrun_node/engineering_node = engineering_device.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
	var/datum/component/netrun_node/medical_node = medical_device.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
	SSnetworks.station_network.setting_disabled = TRUE
	// Every endpoint and APC exists before warming; no delayed construction may
	// cause a topology rebuild which would mask missing context invalidation.
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	var/datum/component/netrun_node/source_node = source.GetComponent(/datum/component/netrun_node)
	var/datum/netrun_network/old_network = source_node.network
	var/datum/netrun_console/console = source.console
	qdel(console.map_view)
	var/datum/netrun_map_view/netrun_performance_test/view = new(console)
	console.map_view = view
	console.workspace_view = "map"
	console.ui_data(null)
	TEST_ASSERT(view.select_sector(engineering_node.binding_sector, levels[2]), "The linked remote floor must already be disclosed by its APCs")
	var/list/data = console.ui_data(null)
	TEST_ASSERT_EQUAL(view.active_z, levels[2], "The baseline must browse the upper floor while the source remains downstairs")
	TEST_ASSERT(!view.shown_addresses[source_node.address], "The moving source must start outside the displayed projection")
	TEST_ASSERT(netrun_map_has_node(data, engineering_node.address), "The original home LAN must disclose its upper-floor endpoint")
	TEST_ASSERT(!netrun_map_has_node(data, medical_node.address), "The protected medical endpoint must initially be hidden")
	var/revision = graph.revision
	var/builds = view.rebuilds
	var/address = source_node.address
	source.forceMove(destination)
	source_node.join_network()
	source_node.publish_changes()
	TEST_ASSERT(source_node.network != old_network, "The physical move must actually change the source LAN")
	TEST_ASSERT_EQUAL(source_node.address, address, "The context change must retain the source's address")
	TEST_ASSERT_EQUAL(graph.revision, revision, "A leaf rebind must retain the warm topology revision")
	data = console.ui_data(null)
	TEST_ASSERT_EQUAL(view.active_z, levels[2], "Changing departments downstairs must preserve the browsed remote floor")
	TEST_ASSERT(!netrun_map_has_node(data, engineering_node.address), "Losing the offscreen source's home LAN must revoke its remote private endpoint")
	TEST_ASSERT(netrun_map_has_node(data, medical_node.address), "The new home LAN must disclose its remote private endpoint on the next poll")
	TEST_ASSERT(view.rebuilds > builds, "A changed offscreen source LAN must replace the permission projection")
	TEST_ASSERT_EQUAL(graph.revision, revision, "Permission refresh must not depend on a full physical graph rebuild")

/proc/netrun_map_has_floor(list/data, sector_id, z)
	var/list/map = data["map"]
	for(var/list/sector as anything in map["sectors"])
		if(sector["id"] == sector_id)
			return z in sector["levels"]
	return FALSE

/// A permitted offscreen endpoint can add a floor without changing the physical mesh.
/datum/unit_test/netrun_map_offscreen_floor_catalog/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/list/levels = multiz_gravity_test_levels()
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, origin.z)
	scene.mark_station(levels[1])
	scene.mark_station(levels[2])
	var/area/local_room = scene.room(/area/netrun_route_test)
	var/area/remote_room = scene.room(/area/netrun_route_test)
	scene.take(origin, local_room)
	scene.machine(/obj/machinery/power/apc, scene.take(get_step(origin, NORTH), local_room))
	scene.machine(/obj/machinery/ntnet_relay, scene.take(locate(origin.x, origin.y + 2, origin.z), local_room))
	var/turf/remote_spot = scene.take(locate(80, 80, levels[1]), remote_room, TRUE)
	var/turf/destination = scene.take(locate(80, 80, levels[2]), remote_room, TRUE)
	scene.machine(/obj/machinery/power/apc, scene.take(locate(81, 80, levels[1]), remote_room, TRUE))
	scene.machine(/obj/machinery/ntnet_relay, scene.take(locate(82, 80, levels[1]), remote_room, TRUE))
	var/obj/machinery/computer/netrun_terminal/source = scene.machine(/obj/machinery/computer/netrun_terminal, origin)
	var/obj/item/mobile = new(remote_spot)
	scene.owned += mobile
	var/datum/component/netrun_node/leaf = mobile.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
	SSnetworks.station_network.setting_disabled = FALSE
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	var/datum/netrun_console/console = source.console
	qdel(console.map_view)
	var/datum/netrun_map_view/netrun_performance_test/view = new(console)
	console.map_view = view
	console.workspace_view = "map"
	var/list/data = console.ui_data(null)
	var/remote_sector = leaf.binding_sector
	var/local_sector = view.active_sector
	TEST_ASSERT(local_sector != remote_sector, "The baseline must display a different sector from the moving endpoint")
	TEST_ASSERT(view.node_entries[leaf.address] && !view.shown_addresses[leaf.address], "The remote endpoint must be permitted but offscreen before it moves")
	TEST_ASSERT(netrun_map_has_floor(data, remote_sector, levels[1]), "The baseline catalog must contain the endpoint's old floor")
	TEST_ASSERT(!netrun_map_has_floor(data, remote_sector, levels[2]), "No permitted endpoint may disclose the destination floor before movement")
	var/revision = graph.revision
	var/builds = view.rebuilds
	var/datum/component/netrun_node/original_apc = leaf.bound_apc
	var/datum/netrun_network/original_network = leaf.network
	mobile.forceMove(destination)
	leaf.join_network()
	leaf.publish_changes()
	TEST_ASSERT_EQUAL(leaf.bound_apc, original_apc, "The mobile endpoint must retain its APC within the same linked area")
	TEST_ASSERT_EQUAL(leaf.network, original_network, "A floor change must keep the original authorization domain")
	TEST_ASSERT_EQUAL(graph.revision, revision, "The offscreen floor move must retain the cached physical topology")
	data = console.ui_data(null)
	TEST_ASSERT_EQUAL(view.active_sector, local_sector, "An offscreen move must preserve the user's viewed sector")
	TEST_ASSERT(!view.shown_addresses[leaf.address], "Updating the catalog must not draw offscreen nodes in the local projection")
	var/list/entry = view.node_entries[leaf.address]
	TEST_ASSERT_EQUAL(entry["z"], levels[2], "Offscreen permitted metadata must move to the actual floor")
	TEST_ASSERT(netrun_map_has_floor(data, remote_sector, levels[2]), "The new floor must become browsable on the next poll")
	TEST_ASSERT(view.rebuilds > builds, "Offscreen floor membership changes must rebuild the catalog")
	TEST_ASSERT_EQUAL(graph.revision, revision, "The catalog repair must not rely on a physical topology rebuild")
