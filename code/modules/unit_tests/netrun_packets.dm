/// Map packet flights: a dispatch is drawn with its hops and transit time, its outcome follows.

/datum/unit_test/proc/netrun_packet_events(id)
	. = list()
	for(var/list/event as anything in SSnetrun.events)
		var/list/packet = event["packet"]
		if(packet && packet["id"] == id)
			. += list(event)

/datum/unit_test/proc/netrun_packet_event_phase(id, phase)
	for(var/list/event as anything in netrun_packet_events(id))
		var/list/packet = event["packet"]
		if(packet["phase"] == phase)
			return event
	return null

/// A routed command is published when it is sent, not only when it arrives.
/datum/unit_test/netrun_packet_flight_dispatch/Run()
	var/datum/netrun_entity_contact_scene/scene = allocate(/datum/netrun_entity_contact_scene, run_loc_floor_bottom_left)
	scene.authorize()
	TEST_ASSERT(scene.console.run_command(scene.target_node, "scan", "flight-nonce"), "A real command must be admitted")
	var/datum/netrun_request/command/packet = netrun_operation_packet(scene.console, /datum/netrun_request/command)
	TEST_ASSERT_NOTNULL(packet, "The command must own a pending delivery")
	var/id = packet.operation.id
	var/list/sent = netrun_packet_event_phase(id, "send")
	TEST_ASSERT_NOTNULL(sent, "Dispatch must publish a packet flight before delivery")
	TEST_ASSERT_EQUAL(sent["kind"], "packet", "Flights use their own event kind")
	TEST_ASSERT_EQUAL(sent["from"], scene.source_node.address, "The flight starts at the real route source")
	TEST_ASSERT_EQUAL(sent["to"], scene.target_node.address, "The flight ends at the addressed node")
	var/list/route = sent["route"]
	TEST_ASSERT(length(route) >= 2 && route[1] == scene.source_node.address && route[length(route)] == scene.target_node.address, "The flight carries the actual hop list")
	var/list/flight = sent["packet"]
	TEST_ASSERT_EQUAL(flight["packet"], "command", "The packet class is the operation kind")
	TEST_ASSERT_EQUAL(flight["duration"], packet.operation.eta, "The flight lasts exactly the dispatched transit time")
	TEST_ASSERT(sent["until"] >= sent["t"] + flight["duration"] + NETRUN_MAP_EVENT_TAIL, "A long flight must outlive its own transit")
	TEST_ASSERT_NULL(netrun_packet_event_phase(id, "done"), "Nothing may claim arrival before delivery")
	TEST_ASSERT(packet.deliver(), "The scan must be handled")
	TEST_ASSERT_NOTNULL(netrun_packet_event_phase(id, "done"), "A handled packet publishes its successful outcome")
	TEST_ASSERT_EQUAL(length(netrun_packet_events(id)), 2, "One dispatch and one outcome per packet")

/// A packet rejected at delivery is drawn as a failure; a preflight refusal never flies.
/datum/unit_test/netrun_packet_flight_rejection/Run()
	var/datum/netrun_entity_contact_scene/scene = allocate(/datum/netrun_entity_contact_scene, run_loc_floor_bottom_left)
	scene.authorize()
	var/before = length(SSnetrun.events)
	TEST_ASSERT(!scene.console.run_command(scene.target_node, "reboot", "denied"), "Guest access must not admit a ROOT command")
	for(var/i in before + 1 to length(SSnetrun.events))
		var/list/event = SSnetrun.events[i]
		TEST_ASSERT(event["kind"] != "packet", "A command refused before sending must not appear in flight")
	scene.console.next_command = 0
	TEST_ASSERT(scene.console.run_command(scene.target_node, "scan", "revoked"), "The scan must be admitted with guest access")
	var/datum/netrun_request/command/packet = netrun_operation_packet(scene.console, /datum/netrun_request/command)
	var/id = packet.operation.id
	scene.console.access_session.network_access -= scene.target_node.network.id
	TEST_ASSERT(!packet.deliver(), "Revoked access must reject the packet at delivery")
	TEST_ASSERT_NOTNULL(netrun_packet_event_phase(id, "fail"), "A rejection after dispatch is drawn as a failed flight")
	TEST_ASSERT_NULL(netrun_packet_event_phase(id, "done"), "A rejected packet never reports success")

/// Other maps see only the hops and endpoints they already disclose, never the command name.
/datum/unit_test/netrun_packet_flight_visibility/Run()
	var/datum/netrun_entity_contact_scene/scene = allocate(/datum/netrun_entity_contact_scene, run_loc_floor_bottom_left)
	scene.authorize()
	var/obj/item/viewer_host = allocate(/obj/item)
	var/datum/netrun_console/viewer = allocate(/datum/netrun_console, viewer_host)
	TEST_ASSERT(scene.console.run_command(scene.target_node, "scan", "private"), "A real command must be admitted")
	var/datum/netrun_request/command/packet = netrun_operation_packet(scene.console, /datum/netrun_request/command)
	var/id = packet.operation.id
	scene.console.map_view.shown_addresses = list()
	scene.console.map_view.shown_addresses[scene.source_node.address] = TRUE
	scene.console.map_view.shown_addresses[scene.target_node.address] = TRUE
	var/list/own
	for(var/list/entry as anything in SSnetrun.recent_events(scene.console))
		if(entry["id"] == id && entry["phase"] == "send")
			own = entry
	TEST_ASSERT_NOTNULL(own, "The sender's map receives its own flight")
	TEST_ASSERT(own["own"], "The sender recognizes its own packet")
	TEST_ASSERT(istext(own["label"]) && length(own["label"]), "The sender sees what it sent")
	TEST_ASSERT_EQUAL(own["to"], scene.target_node.address, "A disclosed endpoint stays addressable")
	viewer.map_view.shown_addresses = list()
	var/list/foreign
	for(var/list/entry as anything in SSnetrun.recent_events(viewer))
		if(entry["id"] == id && entry["phase"] == "send")
			foreign = entry
	TEST_ASSERT_NULL(foreign, "An unrelated map must receive no traffic metadata or empty flight shells")
	viewer.map_view.shown_addresses[scene.source_node.address] = TRUE
	for(var/list/entry as anything in SSnetrun.recent_events(viewer))
		if(entry["id"] == id && entry["phase"] == "send")
			foreign = entry
	TEST_ASSERT_NOTNULL(foreign, "A visible source discloses only its visible part of the flight")
	TEST_ASSERT(!foreign["own"], "Another console's packet is not marked as its own")
	TEST_ASSERT_NULL(foreign["label"], "Command names stay private to the sender")
	TEST_ASSERT_EQUAL(foreign["from"], scene.source_node.address, "The visible source remains usable on the map")
	TEST_ASSERT_NULL(foreign["to"], "An undisclosed destination address must not leak")
	var/list/disclosed_route = foreign["route"]
	for(var/hop in disclosed_route)
		TEST_ASSERT(!hop || hop == scene.source_node.address, "Undisclosed intermediate hops remain holes, not an invented path")
	packet.deliver()

/// An in-flight route is retained even when unrelated traffic churns the recent history.
/datum/unit_test/netrun_packet_flight_retention/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/netrun_console/viewer = allocate(/datum/netrun_console, host)
	viewer.map_view.shown_addresses = list("FLIGHT-A" = TRUE, "FLIGHT-B" = TRUE)
	var/datum/netrun_packet_context/operation = allocate(/datum/netrun_packet_context, "command", "Long flight", "FLIGHT-A", "FLIGHT-B", "fixture", viewer)
	operation.queued(list("FLIGHT-A", "HIDDEN", "FLIGHT-B"), 10 SECONDS)
	for(var/i in 1 to NETRUN_MAX_MAP_EVENTS + 10)
		SSnetrun.post_event("traffic", "OTHER-A", "OTHER-B", list("OTHER-A", "OTHER-B"))
	TEST_ASSERT(length(SSnetrun.events) <= NETRUN_MAX_MAP_EVENTS, "Recent traffic must retain its bounded ring")
	var/list/retained
	for(var/list/event as anything in SSnetrun.recent_events(viewer))
		if(event["id"] == operation.id)
			retained = event
	TEST_ASSERT_NOTNULL(retained, "Unrelated traffic must not erase an actual long flight")
	TEST_ASSERT(istext(retained["event_id"]), "Every dispatch has a stable event identity across map updates")
	TEST_ASSERT(retained["remaining_ms"] > 0 && retained["remaining_ms"] <= retained["lifetime_ms"], "The client gets the remaining authoritative lifetime in milliseconds")
	var/list/route = retained["route"]
	TEST_ASSERT_EQUAL(route[2], "", "The retained flight must not expose its hidden intermediate hop")
	TEST_ASSERT_EQUAL(length(route), 3, "Holes retain their position in the physical route")
	operation.finish("cancelled", "Fixture cancellation")
	TEST_ASSERT_NULL(SSnetrun.map_packet_flights[operation.id], "Terminal outcomes release the active flight index immediately")
	TEST_ASSERT_NOTNULL(netrun_packet_event_phase(operation.id, "fail"), "Cancellation still publishes its actual outcome")

/// The active-flight index is separately bounded and expired events cannot restart on reopening.
/datum/unit_test/netrun_packet_active_flight_bound/Run()
	var/list/contexts = list()
	for(var/i in 1 to NETRUN_MAX_MAP_EVENTS + 10)
		var/datum/netrun_packet_context/operation = allocate(/datum/netrun_packet_context, "command", "Long flight", "A", "B", "fixture")
		contexts += operation
		operation.queued(list("A", "B"), 10 SECONDS)
	TEST_ASSERT(length(SSnetrun.map_packet_flights) <= NETRUN_MAX_MAP_EVENTS, "Concurrent visual flights have a strict metadata bound")
	var/datum/netrun_packet_context/last = contexts[length(contexts)]
	var/list/expired = SSnetrun.map_packet_flights[last.id]
	expired["until"] = world.time - 1
	SSnetrun.map_event_snapshot()
	TEST_ASSERT_NULL(SSnetrun.map_packet_flights[last.id], "Expired active flights are released without retaining the packet")
	for(var/datum/netrun_packet_context/operation as anything in contexts)
		operation.finish("cancelled", "Fixture teardown")

/// The operator can recognize dispatches from its own agent, without revealing them to others.
/datum/unit_test/netrun_packet_agent_ownership/Run()
	var/datum/netrun_entity_contact_scene/scene = allocate(/datum/netrun_entity_contact_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/bot/agent = SSnetrun.spawn_bot(NETRUN_BOT_MENDER, scene.source_node, scene.console)
	TEST_ASSERT_NOTNULL(agent, "The operator's agent must spawn as an ordinary entity")
	allocated += agent
	scene.console.map_view.shown_addresses = list()
	scene.console.map_view.shown_addresses[scene.source_node.address] = TRUE
	scene.console.map_view.shown_addresses[scene.target_node.address] = TRUE
	var/datum/netrun_packet_context/operation = allocate(/datum/netrun_packet_context, "command", "Agent scan", scene.source_node.address, scene.target_node.address, "fixture", agent.console)
	operation.queued(list(scene.source_node.address, scene.target_node.address), 5)
	var/list/own
	for(var/list/event as anything in SSnetrun.recent_events(scene.console))
		if(event["id"] == operation.id)
			own = event
	TEST_ASSERT_NOTNULL(own, "The owner receives its agent's visible dispatch")
	TEST_ASSERT(own["own"] && own["label"] == "Agent scan", "An owned bot's operation is identified as the operator's traffic")

/// The ring stays bounded however busy the network is.
/datum/unit_test/netrun_packet_flight_ring_bound/Run()
	for(var/i in 1 to NETRUN_MAX_MAP_EVENTS + 20)
		var/datum/netrun_packet_context/operation = new("command", "Flood", "A", "B", "fixture")
		operation.queued(list("A", "B"), 5)
		operation.finish("completed")
		qdel(operation)
	TEST_ASSERT(length(SSnetrun.events) <= NETRUN_MAX_MAP_EVENTS, "Map events must keep a strict global bound")

/// Machine traffic is drawn at dispatch through a shared limiter and never reports routine success.
/datum/unit_test/netrun_machine_flight_limiter/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	transport.flow_window = 0
	transport.last_flow.Cut()
	var/datum/netrun_packet_context/first = allocate(/datum/netrun_packet_context, "machine", "Fixture", scene.source.resolve_node().address, scene.target.resolve_node().address, "fixture")
	first.queued(list(first.from_address, first.to_address), 1, FALSE)
	TEST_ASSERT(!first.map_announced, "Machine packets defer publication to the limiter")
	TEST_ASSERT(transport.record_flow(scene.source, scene.target, first), "The first flight of a pair is drawn")
	TEST_ASSERT(first.map_announced && first.quiet_success, "A drawn machine flight hides routine success")
	var/datum/netrun_packet_context/second = allocate(/datum/netrun_packet_context, "machine", "Fixture", first.from_address, first.to_address, "fixture")
	second.queued(list(first.from_address, first.to_address), 1, FALSE)
	TEST_ASSERT(!transport.record_flow(scene.source, scene.target, second), "The same pair is drawn at most once per window")
	first.finish("completed")
	TEST_ASSERT_NULL(netrun_packet_event_phase(first.id, "done"), "Routine machine success adds no outcome event")
	second.finish("rejected", "fixture")
	TEST_ASSERT_NULL(netrun_packet_event_phase(second.id, "fail"), "An undrawn packet draws no outcome either")
