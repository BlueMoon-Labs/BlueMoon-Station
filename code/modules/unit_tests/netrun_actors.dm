/// The public actor facade does not make passive contact enumeration allocate consoles.
/datum/unit_test/netrun_actor_ice_session/Run()
	var/datum/netrun_entity_contact_scene/scene = allocate(/datum/netrun_entity_contact_scene, run_loc_floor_bottom_left)
	var/datum/netrun_ice/ice = allocate(/datum/netrun_ice, scene.target_node)
	TEST_ASSERT_EQUAL(scene.recipient.netrun_actor_node(), scene.target_node, "Players expose their actual resident node")
	TEST_ASSERT_EQUAL(scene.recipient.netrun_actor_console(), scene.recipient.console, "Players use their existing session")
	TEST_ASSERT_EQUAL(ice.netrun_actor_node(), scene.target_node, "ICE exposes the same actor residency contract")
	TEST_ASSERT_EQUAL(ice.netrun_actor_name(), ice.name, "Actor identity belongs to the actual process")
	TEST_ASSERT_EQUAL(ice.netrun_actor_faction(), NETRUN_FACTION_STATION, "Ordinary ICE belongs to station protection")
	TEST_ASSERT_NULL(ice.netrun_actor_console(FALSE), "An idle guard has no command session")
	var/datum/netrun_console/ice/session = ice.netrun_actor_console()
	TEST_ASSERT_EQUAL(session, ice.netrun_actor_console(), "Repeated use preserves one session")
	TEST_ASSERT_EQUAL(session.netrun_actor(), ice, "A lightweight session retains its stable datum actor")
	TEST_ASSERT_EQUAL(session.inventory.local_store, ice.agent.memory, "Commands use the guard's actual program memory")
	TEST_ASSERT_EQUAL(session.route_source(), scene.target_node, "Commands originate at the guard's current node")
	TEST_ASSERT_NULL(session.host, "The guarded endpoint is never impersonated as the process's physical owner")
	TEST_ASSERT_NULL(session.operator, "ICE does not borrow an unrelated player's operator or ID")
	session.set_jack(scene.source_node)
	TEST_ASSERT_NULL(session.connection.jack, "ICE cannot borrow the physical cable authority of another endpoint")
	TEST_ASSERT_EQUAL(session.node_level(scene.target_node), NETRUN_ACCESS_GUEST, "Creating a session grants no machine USER or ROOT")
	TEST_ASSERT(!length(session.access_session.node_access) && !length(session.access_session.network_access), "A profile does not create acquired authority")
	TEST_ASSERT(session.autonomous() && session.automates_breach_input(), "ICE supplies ordinary delayed puzzle input")
	TEST_ASSERT(!session.needs_processing(), "An unused guard session adds no permanent polling work")

/// The guard owns its disk; its optional command session owns only session resources.
/datum/unit_test/netrun_actor_ice_lifetime/Run()
	var/datum/netrun_entity_contact_scene/scene = allocate(/datum/netrun_entity_contact_scene, run_loc_floor_bottom_left)
	var/datum/netrun_ice/ice = allocate(/datum/netrun_ice, scene.target_node)
	var/datum/netrun_file_store/memory = ice.agent.memory
	var/file_count = length(memory.files)
	var/datum/netrun_console/ice/session = ice.netrun_actor_console()
	qdel(session)
	TEST_ASSERT(!QDELETED(memory) && length(memory.files) == file_count, "Closing an optional session preserves the guard's existing files")
	TEST_ASSERT_NULL(ice.netrun_actor_console(FALSE), "Closing a session releases its public alias")
	session = ice.netrun_actor_console()
	TEST_ASSERT(session.start_breach("node", scene.target_node.address), "ICE starts a normal puzzle through its session")
	var/datum/netrun_breach/breach = session.intrusion.breach
	TEST_ASSERT_NOTNULL(breach, "Puzzle completion is delayed rather than awarded at dispatch")
	TEST_ASSERT(session in SSnetrun.currentbreaches, "Only an actual puzzle registers breach interest")
	TEST_ASSERT(!ice.valid_trace_target(session), "A process cannot countertrace its own ordinary puzzle")
	ice.enter_node(scene.source_node)
	TEST_ASSERT(QDELETED(breach) && !session.intrusion.breach, "Movement cancels the puzzle bound to the previous residency")
	TEST_ASSERT(!(session in SSnetrun.currentbreaches), "Movement removes the cancelled puzzle from live breach interests immediately")
	TEST_ASSERT_EQUAL(session.route_source(), scene.source_node, "The same session follows real ICE movement")
	ice.leave_node()
	TEST_ASSERT_NULL(session.route_source(), "A departed guard has no stale source endpoint")
	ice.enter_node(scene.target_node)
	qdel(ice)
	TEST_ASSERT(QDELETED(session), "Deleting an actor cancels its owned command session")
	TEST_ASSERT(QDELETED(memory), "Only deleting the guard releases its profile memory")

/// The session delegates combat to native ICE admission rather than an entity impostor.
/datum/unit_test/netrun_actor_ice_program_use/Run()
	var/datum/netrun_entity_contact_scene/scene = allocate(/datum/netrun_entity_contact_scene, run_loc_floor_bottom_left)
	var/datum/netrun_ice/ice = allocate(/datum/netrun_ice, scene.target_node, NETRUN_ICE_BLACK)
	var/datum/netrun_console/ice/session = ice.netrun_actor_console()
	var/datum/netrun_file/file = ice.agent.program_file("assault")
	TEST_ASSERT_NOTNULL(file, "The profile owns the actual program file")
	TEST_ASSERT_NULL(session.combat_self(), "The stable ICE datum is never cast as a player entity")
	TEST_ASSERT(!session.program_use("assault", REF(scene.recipient)), "A program ID cannot impersonate an owned executable UID")
	TEST_ASSERT(!session.program_use(file.uid, REF(scene.recipient), "stale-turn"), "The common action rejects obsolete encounter input")
	var/before = scene.recipient.integrity
	TEST_ASSERT(session.program_use(file.uid, REF(scene.recipient)), "The shared action facade accepts an actual owned executable")
	TEST_ASSERT_EQUAL(ice.pending_program.id, "assault", "The action starts the ordinary ICE cast")
	TEST_ASSERT(ice.attack_at > world.time, "The common API preserves the native warning and windup")
	TEST_ASSERT_EQUAL(scene.recipient.integrity, before, "Admission cannot apply damage before the native telegraph")
	TEST_ASSERT(!session.program_use(file.uid, REF(scene.recipient)), "A second API call cannot overlap the pending cast")
	ice.agent.memory.remove(file)
	TEST_ASSERT_NULL(ice.pending_program, "Removing the actual executable cancels its pending native cast")
	TEST_ASSERT(!session.program_use(file.uid, REF(scene.recipient)), "A removed UID cannot replay a former executable")
	qdel(file)

/datum/netrun_actor_contact_probe
	var/datum/owner
	var/count = 0
	var/datum/netrun_console/last_sender
	var/last_message

/datum/netrun_actor_contact_probe/New(datum/owner)
	src.owner = owner
	RegisterSignal(owner, COMSIG_NETRUN_ACTOR_CONTACT, PROC_REF(on_contact))

/datum/netrun_actor_contact_probe/Destroy()
	if(owner)
		UnregisterSignal(owner, COMSIG_NETRUN_ACTOR_CONTACT)
	owner = null
	last_sender = null
	return ..()

/datum/netrun_actor_contact_probe/proc/on_contact(datum/source, datum/netrun_console/sender, message)
	SIGNAL_HANDLER
	count++
	last_sender = sender
	last_message = message

/// Players, bots and ICE communicate through actual packets, never direct AI callbacks.
/datum/unit_test/netrun_actor_ice_messages/Run()
	var/datum/netrun_entity_contact_scene/scene = allocate(/datum/netrun_entity_contact_scene, run_loc_floor_bottom_left)
	scene.authorize()
	var/datum/netrun_ice/ice = allocate(/datum/netrun_ice, scene.target_node)
	var/datum/netrun_actor_contact_probe/probe = allocate(/datum/netrun_actor_contact_probe, ice)
	TEST_ASSERT(scene.console.signal_entity(scene.target_node, REF(ice), "Actor contact"), "An authorized physical client can address an ICE actor")
	TEST_ASSERT_NULL(ice.netrun_actor_console(FALSE), "Queued mail does not allocate the recipient session before delivery")
	var/datum/netrun_request/entity_contact/packet = netrun_operation_packet(scene.console, /datum/netrun_request/entity_contact)
	TEST_ASSERT(packet && packet.deliver(), "ICE mail uses ordinary routed delivery")
	TEST_ASSERT_EQUAL(probe.count, 1, "The behavioral fact is emitted exactly once after delivery")
	TEST_ASSERT_EQUAL(probe.last_sender, scene.console, "A reaction receives the actual sending session")
	TEST_ASSERT_EQUAL(probe.last_message, "Actor contact", "A reaction receives the delivered message snapshot")
	var/datum/netrun_console/ice/session = ice.netrun_actor_console(FALSE)
	TEST_ASSERT_NOTNULL(session, "Delivered mail opens one optional recipient session")
	TEST_ASSERT(session.signal_entity(scene.target_node, REF(scene.recipient), "Guard reply"), "An ICE actor can address a player through the same interface")
	packet = netrun_operation_packet(session, /datum/netrun_request/entity_contact)
	TEST_ASSERT(packet && packet.deliver(), "A guard reply uses the same delivery boundary")
	TEST_ASSERT(scene.received("Guard reply"), "The player's ordinary session receives the reply")
	var/datum/netrun_ice/peer = allocate(/datum/netrun_ice, scene.target_node)
	var/datum/netrun_actor_contact_probe/peer_probe = allocate(/datum/netrun_actor_contact_probe, peer)
	session.next_entity_signal = 0
	TEST_ASSERT(session.signal_entity(scene.target_node, REF(peer)), "An ICE actor can signal another ICE")
	packet = netrun_operation_packet(session, /datum/netrun_request/entity_contact)
	TEST_ASSERT(packet && packet.deliver(), "Peer communication uses a real packet")
	TEST_ASSERT_EQUAL(peer_probe.last_sender, session, "The peer observes the original actor session")
	TEST_ASSERT_EQUAL(peer_probe.count, 1, "A presence signal reaches the peer once")
	session.next_entity_signal = 0
	TEST_ASSERT(!session.signal_entity(scene.target_node, REF(ice)), "The common facade still prevents self-contact")

/// Runtime recipient movement, authority loss and destruction are revalidated for ICE too.
/datum/unit_test/netrun_actor_ice_contact_revalidation/Run()
	var/datum/netrun_entity_contact_scene/scene = allocate(/datum/netrun_entity_contact_scene, run_loc_floor_bottom_left)
	scene.authorize()
	var/datum/netrun_ice/ice = allocate(/datum/netrun_ice, scene.target_node)
	TEST_ASSERT(scene.console.signal_entity(scene.target_node, REF(ice)), "An initial authorized signal is admitted")
	var/datum/netrun_request/entity_contact/packet = netrun_operation_packet(scene.console, /datum/netrun_request/entity_contact)
	scene.console.access_session.network_access.Cut()
	TEST_ASSERT(packet && !packet.deliver(), "Revoked rights reject the ICE delivery")
	TEST_ASSERT_NULL(ice.netrun_actor_console(FALSE), "Rejected delivery creates no guard session")
	scene.authorize()
	scene.console.next_entity_signal = 0
	TEST_ASSERT(scene.console.signal_entity(scene.target_node, REF(ice)), "Restored rights admit a new independent signal")
	packet = netrun_operation_packet(scene.console, /datum/netrun_request/entity_contact)
	ice.enter_node(scene.source_node)
	TEST_ASSERT(packet && !packet.deliver(), "A queued signal cannot follow a guard into another node")
	ice.enter_node(scene.target_node)
	scene.console.next_entity_signal = 0
	TEST_ASSERT(scene.console.signal_entity(scene.target_node, REF(ice)), "The returned guard can receive a fresh packet")
	packet = netrun_operation_packet(scene.console, /datum/netrun_request/entity_contact)
	qdel(ice)
	TEST_ASSERT(QDELETED(packet), "Deleting the recipient cancels queued actor communication")

/// Shared inventory transport retains explicit recipient acceptance and actual disk ownership.
/datum/unit_test/netrun_actor_ice_file_exchange/Run()
	var/datum/netrun_entity_contact_scene/scene = allocate(/datum/netrun_entity_contact_scene, run_loc_floor_bottom_left)
	var/datum/netrun_ice/ice = allocate(/datum/netrun_ice, scene.target_node)
	var/datum/netrun_file/original = new("peer.txt", NETRUN_FILE_TEXT, "shared payload", 1)
	TEST_ASSERT(scene.recipient.console.store_file(original), "The sending player owns an actual local file")
	TEST_ASSERT(scene.recipient.console.offer_entity_file(scene.target_node.address, REF(ice), original.uid), "A player can offer an inert file copy to ICE")
	var/datum/netrun_request/entity_file_offer/packet = netrun_operation_packet(scene.recipient.console, /datum/netrun_request/entity_file_offer)
	TEST_ASSERT(packet && packet.deliver(), "The proposal uses ordinary routed file delivery")
	var/datum/netrun_console/ice/session = ice.netrun_actor_console(FALSE)
	TEST_ASSERT_EQUAL(length(session.file_exchange.incoming), 1, "The guard receives one bounded proposal")
	var/offer_id = session.file_exchange.incoming[1]
	var/datum/netrun_file_offer/offer = session.file_exchange.incoming[offer_id]
	var/datum/netrun_file/copy = offer.file
	TEST_ASSERT(!(copy in ice.agent.memory.files), "Delivery alone never installs or executes the offered file")
	TEST_ASSERT(session.file_exchange.respond(offer_id, TRUE), "The guard can explicitly accept through the common exchange")
	TEST_ASSERT(copy in ice.agent.memory.files, "Acceptance stores the copy on the guard's actual disk")
	TEST_ASSERT(original in scene.recipient.console.inventory.local_store.files, "The original remains owned by the sender")
	TEST_ASSERT(copy != original && copy.uid != original.uid, "The accepted file has an independent identity")
	TEST_ASSERT(session.offer_entity_file(scene.target_node.address, REF(scene.recipient), copy.uid), "ICE can offer its owned files back through the same transport")
	packet = netrun_operation_packet(session, /datum/netrun_request/entity_file_offer)
	TEST_ASSERT(packet && packet.deliver(), "ICE file proposals use the same delivery boundary")
	TEST_ASSERT_EQUAL(length(scene.recipient.console.file_exchange.incoming), 1, "The player receives the guard's independent proposal")

/// Trace reveals resident actors; it cannot disconnect a lightweight resident as a deck.
/datum/unit_test/netrun_actor_ice_trace_parity/Run()
	var/datum/netrun_entity_contact_scene/scene = allocate(/datum/netrun_entity_contact_scene, run_loc_floor_bottom_left)
	var/datum/netrun_ice/ice = allocate(/datum/netrun_ice, scene.target_node)
	var/datum/netrun_console/ice/session = ice.netrun_actor_console()
	session.access_session.node_access[scene.target_node.address] = NETRUN_ACCESS_USER
	TEST_ASSERT(session.start_breach("node", scene.target_node.address), "A resident ICE can start its own ordinary puzzle")
	var/datum/netrun_breach/breach = session.intrusion.breach
	session.intrusion.trace = 100
	session.traced()
	// Do not leave this fixture's high-severity report for later police tests.
	for(var/datum/netrun_incident/incident as anything in SSnetrun.incidents)
		if(incident.kind == "trace" && incident.suspect() == session)
			incident.close("fixture complete")
	TEST_ASSERT_EQUAL(session.intrusion.trace, 0, "Trace completion resets the ordinary trace meter")
	TEST_ASSERT(QDELETED(breach) && !session.intrusion.breach, "Trace completion cancels the unfinished puzzle")
	TEST_ASSERT(!session.is_locked(), "A native resident remains available instead of inheriting a remote deck lockout")
	TEST_ASSERT_EQUAL(session.node_level(scene.target_node), NETRUN_ACCESS_USER, "Resident trace preserves the same existing authority as a player's resident session")
	TEST_ASSERT_EQUAL(ice.node, scene.target_node, "Tracing reveals residency without moving the actual ICE actor")
