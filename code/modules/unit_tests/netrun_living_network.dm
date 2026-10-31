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

/// A reusable ghost entry rechecks the real relay after the role prompt.
/datum/unit_test/netrun_relay_visitor_entry/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	SSnetworks.station_network.setting_disabled = FALSE
	var/obj/machinery/ntnet_relay/relay = scene.machine(/obj/machinery/ntnet_relay, get_turf(scene.node_b.parent))
	var/obj/effect/mob_spawn/netrun_entity/relay/spawner = relay.netrun_visitor_spawner
	TEST_ASSERT_NOTNULL(spawner, "Every physical relay publishes an external network ghost role")
	TEST_ASSERT(spawner.allow_spawn(null, TRUE), "An online unisolated relay admits visitors")
	relay.enabled = FALSE
	TEST_ASSERT(!spawner.allow_spawn(null, TRUE), "An offline relay withdraws the ghost entry")
	TEST_ASSERT_NULL(spawner.create(), "Create revalidates a relay disabled while a role prompt was open")
	relay.enabled = TRUE
	var/mob/camera/netrun_entity/visitor/visitor = spawner.create()
	TEST_ASSERT_NOTNULL(visitor, "A restored relay admits a player process")
	allocated += visitor
	var/datum/component/netrun_node/node = relay.GetComponent(/datum/component/netrun_node)
	TEST_ASSERT_EQUAL(visitor.host_node, node, "The process actually resides in its entry relay")
	TEST_ASSERT(!length(visitor.console.access_session.node_access) && !length(visitor.console.access_session.network_access), "Arrival grants neither machine USER nor a LAN login")
	TEST_ASSERT_EQUAL(visitor.console.node_level(node), NETRUN_ACCESS_NONE, "Player visitors follow NPC residency restrictions")
	TEST_ASSERT(visitor.console.daemon_capability("autobreach"), "Visitors arrive with a real hacking tool")
	TEST_ASSERT(!QDELETED(spawner), "Entering does not consume the physical relay ghost role")
	qdel(visitor)
	qdel(relay)
	TEST_ASSERT(QDELETED(spawner), "Destroying the physical relay also removes its ghost entry")
	TEST_ASSERT(!(relay in SSnetworks.station_network.relays), "Ghost-entry cleanup preserves native relay registry teardown")

/// Leaving requires physical relay residency and fresh native availability.
/datum/unit_test/netrun_relay_departure_authority/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	SSnetworks.station_network.setting_disabled = FALSE
	var/obj/machinery/ntnet_relay/relay = scene.machine(/obj/machinery/ntnet_relay, get_turf(scene.node_b.parent))
	var/datum/component/netrun_node/node = relay.GetComponent(/datum/component/netrun_node)
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	entity.console.map_view.selected_address = node.address
	TEST_ASSERT(!entity.can_leave_network(), "Selecting a remote relay cannot end the process")
	TEST_ASSERT(!entity.console.host_act("entity_leave", list(), entity), "Forged actions cannot bypass relay residency")
	entity.enter_node(node)
	TEST_ASSERT(entity.can_leave_network(), "An independent process can leave from an online relay")
	entity.combat_stun_until = world.time + 10 SECONDS
	TEST_ASSERT(!entity.can_leave_network(), "Stun prevents departure")
	entity.combat_stun_until = 0
	relay.enabled = FALSE
	TEST_ASSERT(!entity.console.host_act("entity_leave", list(), entity), "Execution rechecks native relay availability")
	TEST_ASSERT(!QDELETED(entity), "A denied departure preserves the player process")
	relay.enabled = TRUE
	SSnetworks.station_network.setting_disabled = TRUE
	TEST_ASSERT(!entity.can_leave_network(), "The disabled external backbone prevents departure")
	SSnetworks.station_network.setting_disabled = FALSE
	TEST_ASSERT(entity.console.host_act("entity_leave", list(), entity), "The host action ends the process through the real boundary")
	TEST_ASSERT(QDELETED(entity), "A departed process cannot remain as an abandoned resident")
	TEST_ASSERT(!length(node.salvage), "A peaceful departure creates no death loot")

/// Survey counts distinct authorized devices; salvage counts actual recovered files.
/datum/unit_test/netrun_visitor_finite_objectives/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/bot/scout = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, "collective_guard")
	scout.brain.clear_goals()
	scout.brain.visitor_required = 2
	scout.brain.advance_visitor_objective()
	TEST_ASSERT_EQUAL(scout.brain.visitor_progress, 0, "Spawning without machine rights does not complete reconnaissance")
	scout.console.access_session.grant_node(scene.node_a, NETRUN_ACCESS_USER)
	scout.brain.advance_visitor_objective()
	scout.brain.advance_visitor_objective()
	TEST_ASSERT_EQUAL(scout.brain.visitor_progress, 1, "Repeated inspection of the same real device counts once")
	scout.console.access_session.grant_node(scene.node_b, NETRUN_ACCESS_USER)
	scout.enter_node(scene.node_b)
	scout.brain.advance_visitor_objective()
	TEST_ASSERT(scout.brain.visitor_completed && scout.brain.visitor_departing, "A finite completed survey switches to departure")
	TEST_ASSERT(istype(scout.brain.current_goal(), /datum/netrun_bot_goal/depart_network), "Departure replaces unrelated patrol work")
	qdel(scout)
	var/mob/camera/netrun_entity/bot/collector = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, "archive_collector")
	collector.brain.clear_goals()
	for(var/index in 1 to collector.brain.visitor_required)
		var/datum/netrun_file/file = new("debris-[index].txt", NETRUN_FILE_TEXT, "recoverable data", 1)
		scene.node_a.leave_salvage(file, "test")
	var/datum/netrun_bot_goal/salvage/goal = allocate(/datum/netrun_bot_goal/salvage, collector.brain, scene.node_a)
	TEST_ASSERT_EQUAL(goal.advance(), NETRUN_BOT_GOAL_CONTINUE, "The first recovery performs a real file transfer")
	TEST_ASSERT_EQUAL(collector.brain.visitor_progress, 1, "A recovered file advances the mission")
	goal.advance()
	collector.brain.advance_visitor_objective()
	TEST_ASSERT(collector.brain.visitor_completed && collector.brain.visitor_departing, "Recovered cargo triggers a return to external space")

/// Expired visitors get one bounded route home, then clean up if every exit is lost.
/datum/unit_test/netrun_visitor_departure_timeout/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/bot/visitor = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, "scavenger")
	var/datum/netrun_entity_module/bot_lifecycle/lifecycle = visitor.entity_modules["bot_lifecycle"]
	visitor.expires_at = world.time
	lifecycle.behavior_step(visitor.brain)
	TEST_ASSERT(!QDELETED(visitor) && visitor.brain.visitor_departing, "Objective expiry starts physical departure before cleanup")
	TEST_ASSERT(visitor.expires_at > world.time && visitor.expires_at <= world.time + 90 SECONDS, "The departure grace period has one finite deadline")
	var/deadline = visitor.expires_at
	visitor.brain.begin_visitor_departure()
	TEST_ASSERT_EQUAL(visitor.expires_at, deadline, "Repeated requests cannot extend the visitor lifetime")
	visitor.expires_at = world.time
	lifecycle.behavior_step(visitor.brain)
	TEST_ASSERT(QDELETED(visitor), "A disconnected visitor cannot accumulate forever")
	TEST_ASSERT(!length(scene.node_a.salvage), "Lifecycle cleanup does not generate repeatable loot")
