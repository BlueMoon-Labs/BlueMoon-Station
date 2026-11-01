/// These contacts use real APC routing and a closed LAN, never a fake route oracle.
/datum/netrun_entity_contact_scene
	parent_type = /datum/netrun_route_scene
	var/obj/machinery/power/apc/apc
	var/datum/component/netrun_node/source_node
	var/datum/component/netrun_node/target_node
	var/datum/netrun_console/console
	var/mob/camera/netrun_entity/recipient

/datum/netrun_entity_contact_scene/New(turf/origin, storage_capacity = 0)
	..(origin.z)
	var/area/room = room(/area/engineering/netrun_route_test)
	take(origin, room)
	var/turf/target_spot = take(get_step(origin, EAST), room)
	var/turf/apc_spot = take(get_step(origin, NORTH), room)
	apc = machine(/obj/machinery/power/apc, apc_spot)
	var/obj/item/source_host = new(origin)
	owned += source_host
	source_node = source_host.AddComponent(/datum/component/netrun_node, NETRUN_NODE_DECK)
	var/obj/item/target_host = new(target_spot)
	owned += target_host
	target_node = target_host.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL, list(), 1, list(), storage_capacity)
	console = new(source_host, NETRUN_ORIGIN_DECK)
	owned += console
	recipient = new(null, target_node)
	owned += recipient
	SSnetrun.ensure_topology()

/datum/netrun_entity_contact_scene/Destroy()
	// Tear sessions down before their physical hosts, cancelling every pending delivery.
	owned -= list(recipient, console)
	QDEL_NULL(recipient)
	QDEL_NULL(console)
	return ..()

/datum/netrun_entity_contact_scene/proc/authorize()
	console.access_session.network_access[target_node.network.id] = NETRUN_ACCESS_GUEST

/datum/netrun_entity_contact_scene/proc/received(text)
	for(var/list/entry as anything in recipient.console.log)
		if(findtext(entry["text"], text))
			return TRUE
	return FALSE

/datum/netrun_entity_contact_scene/proc/packet()
	for(var/datum/netrun_request/entity_contact/packet as anything in SSnetrun.pending_requests)
		if(istype(packet) && packet.console == console)
			return packet
	return null

/datum/unit_test/netrun_entity_contacts_visibility/Run()
	var/datum/netrun_entity_contact_scene/scene = allocate(/datum/netrun_entity_contact_scene, run_loc_floor_bottom_left)
	var/datum/netrun_ice/sentry = allocate(/datum/netrun_ice, scene.target_node, NETRUN_ICE_SENTRY)
	var/datum/netrun_ice/hunter = allocate(/datum/netrun_ice, scene.target_node, NETRUN_ICE_HUNTER)
	TEST_ASSERT_EQUAL(length(scene.console.entity_contacts(scene.target_node)), 0, "A reachable closed LAN must not publish its residents without guest rights")
	scene.authorize()
	var/list/contacts = scene.console.entity_contacts(scene.target_node)
	TEST_ASSERT_EQUAL(length(contacts), 3, "The selected node must expose its resident and both local ICE kinds")
	var/list/entity_entry = contacts[1]
	TEST_ASSERT_EQUAL(entity_entry["ref"], REF(scene.recipient), "Contacts must address the actual resident process")
	TEST_ASSERT(entity_entry["can_signal"] && entity_entry["can_message"], "Authorized residents must support non-combat communication")
	var/list/sentry_entry = contacts[2]
	var/list/hunter_entry = contacts[3]
	TEST_ASSERT_EQUAL(sentry_entry["ref"], REF(sentry), "A sentry card must keep its own identity")
	TEST_ASSERT_EQUAL(hunter_entry["ref"], REF(hunter), "A hunter card must keep its own identity")
	TEST_ASSERT(sentry_entry["state"] != hunter_entry["state"], "The user must distinguish a guard from a patrol")
	TEST_ASSERT(sentry_entry["can_message"] && hunter_entry["can_signal"], "Authorized communication addresses ICE through the common actor contract")
	TEST_ASSERT_NULL(sentry.netrun_actor_console(FALSE), "Contact enumeration must not allocate an idle session for every guard")
	TEST_ASSERT_NULL(hunter.netrun_actor_console(FALSE), "Reading a patrol card is passive")
	var/list/self_contacts = scene.recipient.console.entity_contacts(scene.target_node)
	var/list/self_entry = self_contacts[1]
	TEST_ASSERT(self_entry["self"] && !self_entry["can_signal"], "A resident must identify itself without exposing a self-ping action")

/datum/unit_test/netrun_entity_message_delivery/Run()
	var/datum/netrun_entity_contact_scene/scene = allocate(/datum/netrun_entity_contact_scene, run_loc_floor_bottom_left)
	scene.authorize()
	scene.console.handle = "unit-sender"
	TEST_ASSERT(scene.console.signal_entity(scene.target_node, REF(scene.recipient), "Unit private message"), "An authorized private message must enter the real delivery queue")
	var/datum/netrun_request/entity_contact/packet = scene.packet()
	TEST_ASSERT(packet, "The addressed message must own a cancellable request")
	TEST_ASSERT(packet.deliver(), "The original route and resident must admit delivery")
	TEST_ASSERT(QDELETED(packet), "Delivery must consume the request and cancel its pending timer")
	TEST_ASSERT(scene.received("Unit private message"), "The recipient must actually receive the private payload")
	var/list/sent = scene.source_node.packet_logs[length(scene.source_node.packet_logs)]
	var/list/received = scene.target_node.packet_logs[length(scene.target_node.packet_logs)]
	TEST_ASSERT_EQUAL(sent["phase"], "SEND", "The source must journal the emitted packet")
	TEST_ASSERT_EQUAL(received["phase"], "ACCEPT", "The destination must journal its terminal acceptance after receipt")
	TEST_ASSERT_EQUAL(sent["id"], received["id"], "Node journals must correlate the same addressed packet")
	TEST_ASSERT_EQUAL(received["kind"], "entity.message", "The journal must distinguish private messages from pings")
	TEST_ASSERT(!scene.console.signal_entity(scene.target_node, REF(scene.recipient)), "Repeated signals must respect the communication cooldown")

/datum/unit_test/netrun_entity_signal_delivery/Run()
	var/datum/netrun_entity_contact_scene/scene = allocate(/datum/netrun_entity_contact_scene, run_loc_floor_bottom_left)
	scene.authorize()
	scene.console.handle = "unit-signal"
	TEST_ASSERT(scene.console.signal_entity(scene.target_node, REF(scene.recipient)), "A presence signal must work without an NTnet relay")
	var/datum/netrun_request/entity_contact/packet = scene.packet()
	TEST_ASSERT(packet && packet.deliver(), "A local presence signal must use ordinary packet delivery")
	TEST_ASSERT(scene.received("unit-signal"), "The recipient must identify the signaling process")
	TEST_ASSERT_EQUAL(scene.console.node_level(scene.target_node), NETRUN_ACCESS_GUEST, "Signaling must not award additional machine rights")
	var/list/received = scene.target_node.packet_logs[length(scene.target_node.packet_logs)]
	TEST_ASSERT_EQUAL(received["kind"], "entity.signal", "Presence signals need their own observable packet kind")
	scene.console.next_entity_signal = 0
	scene.console.set_jack(scene.target_node)
	var/previous_logs = length(scene.target_node.packet_logs)
	TEST_ASSERT(scene.console.signal_entity(scene.target_node, REF(scene.recipient)), "A single-node direct route must admit delivery without artificial latency")
	packet = scene.packet()
	TEST_ASSERT(packet && packet.deliver(), "A ready direct packet must use the same budgeted delivery boundary")
	TEST_ASSERT_EQUAL(length(scene.target_node.packet_logs), previous_logs + 3, "A direct route must journal SEND, RECEIVE and ACCEPT without invented forwarding hops")

/datum/unit_test/netrun_entity_contact_recipient_move/Run()
	var/datum/netrun_entity_contact_scene/scene = allocate(/datum/netrun_entity_contact_scene, run_loc_floor_bottom_left)
	scene.authorize()
	TEST_ASSERT(scene.console.signal_entity(scene.target_node, REF(scene.recipient), "Must not follow"), "The original resident must admit dispatch")
	var/datum/netrun_request/entity_contact/packet = scene.packet()
	scene.recipient.enter_node(scene.source_node)
	TEST_ASSERT(packet && !packet.deliver(), "A queued message must not silently follow a resident to another node")
	TEST_ASSERT(!scene.received("Must not follow"), "The moved recipient must not receive a stale-node message")
	var/list/dropped = scene.source_node.packet_logs[length(scene.source_node.packet_logs)]
	TEST_ASSERT_EQUAL(dropped["phase"], "REJECT", "A stale resident must leave an explainable packet rejection")

/datum/unit_test/netrun_entity_contact_authority_lifecycle/Run()
	var/datum/netrun_entity_contact_scene/scene = allocate(/datum/netrun_entity_contact_scene, run_loc_floor_bottom_left)
	TEST_ASSERT(!scene.console.signal_entity(scene.target_node, REF(scene.recipient)), "A forged contact action must not bypass the LAN's guest requirement")
	TEST_ASSERT_EQUAL(scene.console.next_entity_signal, 0, "Rejected dispatch must not spend the signal cooldown")
	scene.authorize()
	TEST_ASSERT(scene.console.signal_entity(scene.target_node, REF(scene.recipient)), "Authorized dispatch must succeed")
	var/datum/netrun_request/entity_contact/packet = scene.packet()
	scene.console.access_session.network_access.Cut()
	TEST_ASSERT(packet && !packet.deliver(), "Delivery must recheck revoked LAN permissions")
	scene.console.next_entity_signal = 0
	scene.authorize()
	TEST_ASSERT(scene.console.signal_entity(scene.target_node, REF(scene.recipient)), "Restored rights must admit a new independent packet")
	packet = scene.packet()
	scene.apc.set_machine_stat(BROKEN)
	TEST_ASSERT(packet && !packet.deliver(), "Delivery must reject a route that failed after dispatch")

/datum/unit_test/netrun_entity_contact_reference_validation/Run()
	var/datum/netrun_entity_contact_scene/scene = allocate(/datum/netrun_entity_contact_scene, run_loc_floor_bottom_left)
	scene.authorize()
	TEST_ASSERT(!scene.console.signal_entity(scene.target_node, REF(scene.apc)), "An arbitrary machine REF cannot be reinterpreted as a resident actor")
	TEST_ASSERT(!scene.console.signal_entity(scene.target_node, REF(scene.recipient), "   "), "Empty private messages must not become ambiguous pings")
	TEST_ASSERT(!scene.recipient.console.signal_entity(scene.target_node, REF(scene.recipient)), "A forged request must not send a process to itself")
	TEST_ASSERT_EQUAL(scene.console.next_entity_signal, 0, "Invalid references and empty payloads must leave cooldown available")

/datum/unit_test/netrun_entity_contact_cancel_journal/Run()
	var/datum/netrun_entity_contact_scene/scene = allocate(/datum/netrun_entity_contact_scene, run_loc_floor_bottom_left)
	scene.authorize()
	TEST_ASSERT(scene.console.signal_entity(scene.target_node, REF(scene.recipient), "Cancelled message"), "A cancellation scenario must begin with a real pending packet")
	var/datum/netrun_request/entity_contact/packet = scene.packet()
	QDEL_NULL(scene.console)
	TEST_ASSERT(QDELETED(packet), "Deleting the sending session must cancel its scheduled packet")
	TEST_ASSERT(!scene.received("Cancelled message"), "A cancelled message must never reach the recipient")
	var/list/dropped = scene.source_node.packet_logs[length(scene.source_node.packet_logs)]
	TEST_ASSERT_EQUAL(dropped["phase"], "DROP", "Cancellation before delivery must leave a terminal journal entry after SEND")
