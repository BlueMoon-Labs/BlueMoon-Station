/// Native credentials remain distinct from the acquired grants of an intruder.
/datum/netrun_console/entity/security_fixture
	var/credentials_enabled = TRUE

/datum/netrun_console/entity/security_fixture/user_access(fresh = FALSE)
	return credentials_enabled ? list(ACCESS_NETWORK) : list()

/mob/camera/netrun_entity/security_fixture
	console_type = /datum/netrun_console/entity/security_fixture

/datum/unit_test/netrun_security_attribution_and_expiry/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	scene.node_a.required_access = list(ACCESS_NETWORK)
	var/mob/camera/netrun_entity/security_fixture/defender = allocate(/mob/camera/netrun_entity/security_fixture, run_loc_floor_bottom_left, scene.node_a)
	var/mob/camera/netrun_entity/attacker = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_b)
	attacker.set_net_name("TRACE-UNKNOWN")
	attacker.console.operator = attacker
	attacker.console.access_session.network_access[scene.node_a.network.id] = NETRUN_ACCESS_GUEST
	defender.console.operator = defender
	TEST_ASSERT(defender.console.store_file(scene.key_file()), "The pursuer has a real LAN traversal key")
	TEST_ASSERT(attacker.console.start_breach("node", scene.node_a.address, FALSE), "The attacker starts an ordinary breach")
	var/list/before = defender.console.security_session.payload()
	TEST_ASSERT(length(before["entries"]) >= 1, "The defended node observes the actual attempt alongside LAN history")
	TEST_ASSERT(!findtext(json_encode(before), "TRACE-UNKNOWN"), "Before attribution the payload does not identify its actor")
	TEST_ASSERT(!findtext(json_encode(before), scene.node_b.address), "Before attribution the source address is not disclosed")
	TEST_ASSERT(defender.console.run_command(scene.node_a, "countertrace"), "Legal protection queues a native countertrace packet")
	var/datum/netrun_request/command/packet = netrun_operation_packet(defender.console, /datum/netrun_request/command)
	TEST_ASSERT_NOTNULL(packet, "Attribution waits for ordinary delivery")
	TEST_ASSERT_EQUAL(length(defender.console.security_session.contacts), 0, "Dispatch does not grant premature intelligence")
	TEST_ASSERT(packet.deliver(), "Delivered countertrace validates the defender and establishes contact")
	var/key = defender.console.security_session.contacts[1]
	var/datum/netrun_security_contact/contact = defender.console.security_session.contacts[key]
	TEST_ASSERT_EQUAL(contact.source_ref.resolve(), scene.node_b, "Attribution records the real entry node")
	TEST_ASSERT(!defender.console.security_session.act("security_map", "forged"), "Client IDs cannot address arbitrary targets")
	TEST_ASSERT(defender.console.security_session.act("security_map", key), "An established source may be selected on the map")
	TEST_ASSERT_EQUAL(defender.console.map_view.selected_address, scene.node_b.address, "The source itself is selected")
	TEST_ASSERT(defender.console.security_session.act("security_pursue", key), "A real contact can authorize a remote pursuit lock")
	TEST_ASSERT(defender.navigation.timer, "Remote acquisition schedules the first real hop")
	attacker.enter_node(scene.apc_node)
	TEST_ASSERT_EQUAL(contact.source_ref.resolve(), scene.apc_node, "A bounded contact reacts to actor movement")
	contact.expires_at = world.time
	defender.console.security_session.expire()
	TEST_ASSERT(!length(defender.console.security_session.contacts), "Expired attribution releases the contact")
	TEST_ASSERT(!defender.navigation.pursuit_target_ref && !defender.navigation.timer, "Expiry cancels only the lock that used this contact")

/datum/unit_test/netrun_security_rejects_acquired_authority/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	scene.node_a.required_access = list(ACCESS_NETWORK)
	var/mob/camera/netrun_entity/security_fixture/defender = allocate(/mob/camera/netrun_entity/security_fixture, run_loc_floor_bottom_left, scene.node_a)
	var/mob/camera/netrun_entity/attacker = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_b)
	scene.node_a.observe_attack(attacker.console, "intrusion")
	var/datum/netrun_attack_observation/observation = scene.node_a.security_audit.observations[1]
	scene.node_b.observe_attack(attacker.console, "intrusion")
	var/datum/netrun_attack_observation/foreign = scene.node_b.security_audit.observations[1]
	TEST_ASSERT(!defender.console.security_session.capture(foreign, scene.node_a), "A legal node cannot launder evidence from another defended scope")
	TEST_ASSERT(defender.console.security_session.capture(observation, scene.node_a), "Legal credentials may capture recent attack evidence")
	var/datum/netrun_console/entity/security_fixture/console = defender.console
	console.credentials_enabled = FALSE
	console.access_session.node_access[scene.node_a.address] = NETRUN_ACCESS_ROOT
	TEST_ASSERT(!console.security_session.can_defend(scene.node_a), "Acquired ROOT cannot impersonate a legitimate defender")
	var/list/data = console.security_session.payload()
	TEST_ASSERT_EQUAL(length(data["entries"]), 0, "Credential loss withdraws attributed UI data immediately")
	TEST_ASSERT(!console.security_session.act("security_map", observation.id), "A stale UI button cannot preserve the capability")

/datum/unit_test/netrun_entity_file_offer_consent/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/sender = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	var/mob/camera/netrun_entity/receiver = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_b)
	sender.console.operator = sender
	var/datum/netrun_file/file = netrun_daemon_file("cloak")
	TEST_ASSERT(sender.console.store_file(file), "The sender owns the real executable")
	TEST_ASSERT(sender.console.offer_entity_file(scene.node_b.address, REF(receiver), file.uid), "An entity can dispatch a file proposal to a reachable contact")
	var/datum/netrun_request/entity_file_offer/packet = netrun_operation_packet(sender.console, /datum/netrun_request/entity_file_offer)
	TEST_ASSERT_NOTNULL(packet, "The proposal travels as an ordinary packet")
	TEST_ASSERT_EQUAL(length(receiver.console.file_exchange.incoming), 0, "A dispatched proposal is not received yet")
	TEST_ASSERT(packet.deliver(), "The actual proposal is delivered")
	var/id = receiver.console.file_exchange.incoming[1]
	TEST_ASSERT_EQUAL(receiver.console.daemon_bonus("cloak"), 0, "A proposal cannot activate a received daemon")
	TEST_ASSERT(!sender.console.file_exchange.respond(id, TRUE), "Only the recipient mailbox can accept its proposal")
	TEST_ASSERT(receiver.console.file_exchange.respond(id, TRUE), "The recipient explicitly accepts into local memory")
	TEST_ASSERT_EQUAL(receiver.console.daemon_bonus("cloak"), 0.3, "Only acceptance activates the copied daemon")
	TEST_ASSERT(file in sender.console.inventory.local_store.files, "The sender retains its original file")
	TEST_ASSERT(!(file in receiver.console.inventory.local_store.files), "The received file is an independent owned copy")
	TEST_ASSERT(!receiver.console.file_exchange.respond(id, TRUE), "A consumed proposal cannot be replayed")

/datum/unit_test/netrun_entity_file_offer_revocation_and_expiry/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/sender = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	var/mob/camera/netrun_entity/receiver = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_b)
	sender.console.operator = sender
	var/datum/netrun_file/file = new("handoff.txt", NETRUN_FILE_TEXT, "content")
	TEST_ASSERT(sender.console.store_file(file), "The sender owns the source")
	TEST_ASSERT(sender.console.offer_entity_file(scene.node_b.address, REF(receiver), file.uid), "A native proposal is queued")
	var/datum/netrun_request/entity_file_offer/packet = netrun_operation_packet(sender.console, /datum/netrun_request/entity_file_offer)
	sender.console.delete_local_file(file)
	TEST_ASSERT(!packet.deliver(), "A deleted source file is rejected at delivery")
	TEST_ASSERT_EQUAL(length(receiver.console.file_exchange.incoming), 0, "A rejected proposal creates no inbox entry")
	TEST_ASSERT(receiver.console.file_exchange.receive(new /datum/netrun_file("temporary.txt", NETRUN_FILE_TEXT, "snapshot"), "fixture"), "The delivered mailbox can own a proposal snapshot")
	var/id = receiver.console.file_exchange.incoming[1]
	var/datum/netrun_file_offer/offer = receiver.console.file_exchange.incoming[id]
	var/datum/netrun_file/copy = offer.file
	receiver.console.inventory.local_store.capacity = 0
	TEST_ASSERT(!receiver.console.file_exchange.respond(id, TRUE), "A full disk cannot accept the proposal")
	TEST_ASSERT_EQUAL(receiver.console.file_exchange.incoming[id], offer, "A failed acceptance preserves the pending choice")
	offer.expires_at = world.time
	receiver.console.file_exchange.expire()
	TEST_ASSERT(QDELETED(copy), "Expiry releases the inert snapshot")
	TEST_ASSERT(!length(receiver.console.file_exchange.incoming), "Expiry releases the mailbox entry")

/datum/unit_test/netrun_faction_conflicts/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/bot/raider = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, "redshift_raider")
	var/mob/camera/netrun_entity/bot/collective = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, "collective_guard")
	var/mob/camera/netrun_entity/bot/archive = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, "archive_collector")
	TEST_ASSERT(collective in raider.brain.hostiles(), "Rival visitors recognize each other through the common combat policy")
	TEST_ASSERT(raider in collective.brain.hostiles(), "Declared rivalry is symmetric")
	TEST_ASSERT(!(archive in collective.brain.hostiles()), "Coexisting factions do not attack each other indiscriminately")
	TEST_ASSERT(!netrun_bot_factions_hostile("redshift", "redshift"), "Members of one faction are not enemies")
	TEST_ASSERT(raider.brain.combat_step(), "A real faction encounter enters ordinary telegraphed combat")
	TEST_ASSERT_EQUAL(SSnetrun.count_network_visitors(), 3, "The visitor quota counts all visiting factions")
