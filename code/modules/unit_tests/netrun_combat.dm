/// Automatic breaches reuse real target validation and never award access early.
/datum/unit_test/netrun_autobreach_lifecycle/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/component/netrun_node/node = host.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity)
	entity.enter_node(node)
	var/datum/netrun_console/console = entity.console
	TEST_ASSERT(!console.start_breach("node", node.address, TRUE), "Automatic hacking must require an actual daemon file")
	TEST_ASSERT(console.store_file(netrun_daemon_file("autobreach")), "The daemon must occupy actual process memory")
	TEST_ASSERT(console.start_breach("node", node.address, TRUE), "The installed daemon must start a normal reachable target")
	var/datum/netrun_breach/automatic/job = console.intrusion.breach
	TEST_ASSERT(istype(job), "Automatic mode must use its own breach implementation")
	TEST_ASSERT(job.duration >= 14 SECONDS && job.duration <= 30 SECONDS, "Node cracking must have a bounded, useful waiting period")
	TEST_ASSERT(!job.choose(1), "Puzzle clicks must not accelerate automatic cracking")
	job.finish()
	TEST_ASSERT_EQUAL(console.node_level(node), NETRUN_ACCESS_GUEST, "Stopping early must never award USER")
	TEST_ASSERT(console.start_breach("node", node.address, TRUE), "The daemon must remain usable after a cancelled attempt")
	job = console.intrusion.breach
	job.deadline = world.time
	job.finish()
	TEST_ASSERT_EQUAL(console.node_level(node), NETRUN_ACCESS_USER, "An uninterrupted completed timer must guarantee USER without a random roll")
	TEST_ASSERT(!console.start_breach("firmware", node.address, TRUE), "Automatic cracking must not bypass the separate firmware challenge")

/datum/unit_test/netrun_autobreach_program_revocation/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/component/netrun_node/node = host.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity)
	entity.enter_node(node)
	var/datum/netrun_file/file = netrun_daemon_file("autobreach")
	entity.console.store_file(file)
	TEST_ASSERT(entity.console.start_breach("node", node.address, TRUE), "The actual daemon must start its job")
	entity.console.delete_local_file(file)
	entity.console.process_tick(1)
	TEST_ASSERT_NULL(entity.console.intrusion.breach, "Removing the only daemon copy must cancel the active automatic job")
	TEST_ASSERT_EQUAL(entity.console.node_level(node), NETRUN_ACCESS_GUEST, "A revoked program must not grant delayed access")

/// ICE programs warn first, share shield handling, and retain their own cooldowns.
/datum/unit_test/netrun_ice_program_reaction/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/component/netrun_node/node = host.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity)
	entity.enter_node(node)
	var/datum/netrun_ice/ice = allocate(/datum/netrun_ice, node)
	var/datum/netrun_program/strike = SSnetrun.get_program("strike")
	var/initial_integrity = entity.integrity
	TEST_ASSERT(ice.begin_program(strike, entity), "A sentry must be able to queue its real strike program")
	TEST_ASSERT(ice.attack_at >= world.time + 2 SECONDS, "The player must receive a meaningful reaction period")
	TEST_ASSERT_EQUAL(entity.integrity, initial_integrity, "Announcing an attack must not deal immediate damage")
	var/list/incoming = entity.console.incoming_programs()
	TEST_ASSERT_EQUAL(length(incoming), 1, "The targeted process must see an incoming program")
	entity.apply_shield(50, 5 SECONDS)
	ice.attack_at = world.time
	ice.resolve_program()
	var/expected_hit = round(strike.power * ice.damage_factor) * 0.5
	TEST_ASSERT_EQUAL(entity.integrity, initial_integrity - expected_hit, "ICE damage must use the same shield-aware dispatcher, scaled by the ICE damage factor")
	ice.next_attack = world.time
	TEST_ASSERT(!ice.begin_program(strike, entity), "The turn's remaining AP must prevent another immediate two-point cast")
	ice.program_cd.Cut()
	TEST_ASSERT(!ice.begin_program(strike, entity), "Clearing a realtime cooldown cannot refill the active turn's AP")
	TEST_ASSERT(netrun_test_yield_to(ice, TRUE), "The victim and guard explicitly pass to the guard's next own turn")
	TEST_ASSERT(ice.begin_program(strike, entity), "A fresh turn and ready program must allow a new warning")
	ice.apply_stun(2 SECONDS)
	TEST_ASSERT_NULL(ice.pending_program, "Stunning ICE must interrupt its prepared program")
	ice.resolve_program()
	TEST_ASSERT_EQUAL(entity.integrity, initial_integrity - expected_hit, "An interrupted program must not deal later damage")
	TEST_ASSERT(!entity.console.program_use("builtin:logic_bomb", REF(ice)), "A forged builtin UID must not conjure a consumable program")

/// Entity acquisition is real loot, and a full inventory does not silently lose it.
/datum/unit_test/netrun_entity_daemon_salvage/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/component/netrun_node/node = host.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity)
	entity.enter_node(node)
	var/datum/netrun_ice/ice = allocate(/datum/netrun_ice, node)
	entity.console.inventory.local_store.capacity = 0
	ice.drop_loot(entity.console)
	TEST_ASSERT_EQUAL(length(node.salvage), 1, "A defeated sentry must leave a daemon even when the killer has no free memory")
	var/datum/netrun_file/file = node.salvage[1]
	TEST_ASSERT_EQUAL(file.kind, NETRUN_FILE_DAEMON, "The primary reward must be a usable daemon rather than only a combat card")
	TEST_ASSERT(!entity.console.recover_salvage(file.uid), "Picking up debris must honor process memory capacity")
	TEST_ASSERT(file in node.salvage, "A failed pickup must preserve the actual file")
	entity.console.inventory.local_store.capacity = file.size
	TEST_ASSERT(entity.console.recover_salvage(file.uid), "The resident entity must be able to obtain the daemon without USER rights on the host")
	TEST_ASSERT_EQUAL(length(node.salvage), 0, "Successful pickup must transfer ownership out of the debris cache")
	TEST_ASSERT(file in entity.console.inventory.local_store.files, "The actual recovered file must be stored in process memory")
	TEST_ASSERT(!entity.console.recover_salvage(file.uid), "Repeating a pickup request must not duplicate the daemon")

/// Real routes and a closed LAN reproduce the remote trace/empty combat regression.
/datum/unit_test/netrun_remote_combat_contacts/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, origin.z)
	var/area/room = scene.room(/area/engineering/netrun_route_test)
	scene.take(origin, room)
	var/turf/target_spot = scene.take(get_step(origin, EAST), room)
	var/turf/apc_spot = scene.take(get_step(origin, NORTH), room)
	scene.machine(/obj/machinery/power/apc, apc_spot)
	var/obj/item/source_host = allocate(/obj/item, origin)
	source_host.AddComponent(/datum/component/netrun_node, NETRUN_NODE_DECK)
	var/obj/item/target_host = allocate(/obj/item, target_spot)
	var/datum/component/netrun_node/node = target_host.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
	var/datum/netrun_console/console = allocate(/datum/netrun_console, source_host, NETRUN_ORIGIN_DECK)
	console.inventory.local_store.capacity = 32
	SSnetrun.ensure_topology()
	TEST_ASSERT(console.can_route(node), "The fixture must have a real APC route to the ICE")
	TEST_ASSERT_EQUAL(console.node_level(node), NETRUN_ACCESS_NONE, "A foreign endpoint in the closed LAN must not already grant guest rights")
	var/datum/netrun_file/strike = netrun_program_file("strike")
	var/datum/netrun_file/blackout = netrun_program_file("blackout")
	var/datum/netrun_file/barrier = netrun_program_file("barrier")
	var/datum/netrun_file/patch = netrun_program_file("patch")
	var/datum/netrun_file/trace_program = netrun_program_file("trace")
	console.store_file(strike)
	console.store_file(blackout)
	console.store_file(barrier)
	console.store_file(patch)
	console.store_file(trace_program)
	TEST_ASSERT(console.start_breach("network", node.network.id), "LAN cracking must begin without guest rights")
	var/datum/netrun_ice/first = allocate(/datum/netrun_ice, node)
	var/datum/netrun_ice/second = allocate(/datum/netrun_ice, node)
	var/datum/netrun_ice/unrelated = allocate(/datum/netrun_ice, node)
	var/datum/netrun_program/trace = SSnetrun.get_program("trace")
	TEST_ASSERT(first.begin_program(trace, console), "The first sentry must announce its real trace")
	TEST_ASSERT(!second.begin_program(trace, console), "A second sentry must wait for its own turn rather than cast beside another telegraph")
	TEST_ASSERT_NULL(second.pending_program, "An off-turn guard cannot manufacture an incoming cast")
	TEST_ASSERT_NULL(second.program_cd[trace.id], "Off-turn rejection spends no cooldown")
	first.attack_at = world.time
	first.resolve_program()
	TEST_ASSERT(netrun_test_yield_to(second), "The first guard and remote console explicitly yield to the second guard")
	TEST_ASSERT(second.begin_program(trace, console), "A second sentry obtains its own independent contact on its turn")
	var/before_combat_paths = SSnetrun.combat_ui_tree_builds
	var/before_combat_copies = SSnetrun.get_topology().route_snapshot_copies
	var/list/warnings_only = console.combat_context.status_payload()
	TEST_ASSERT_EQUAL(length(warnings_only["incoming"]), 1, "The compact warning identifies the current telegraph while prior contacts remain")
	TEST_ASSERT(!("targets" in warnings_only) && !("programs" in warnings_only), "A warning must not build hidden combat cards or program inventory")
	TEST_ASSERT_EQUAL(SSnetrun.combat_ui_tree_builds, before_combat_paths, "The compact HUD must never build a routing tree")
	var/list/payload = console.breach_combat_payload()
	TEST_ASSERT_EQUAL(SSnetrun.combat_ui_tree_builds, before_combat_paths + 1, "One combat payload with several targets must acquire only one routing tree")
	TEST_ASSERT_EQUAL(SSnetrun.get_topology().route_snapshot_copies, before_combat_copies, "Combat cards must borrow current physical routes without copying every network endpoint")
	TEST_ASSERT_EQUAL(length(payload["targets"]), 2, "The puzzle must expose both actual attackers and no unrelated ICE")
	TEST_ASSERT_EQUAL(length(payload["incoming"]), 1, "Only the current guard's prepared attack is pending")
	TEST_ASSERT_EQUAL(length(payload["programs"]), 4, "Installed counterattacks remain available and player trace stays hidden")
	var/list/incoming = payload["incoming"]
	var/list/warning = incoming[1]
	TEST_ASSERT_EQUAL(warning["source_ref"], REF(second), "Warnings must identify the guard actually preparing on its own turn")
	TEST_ASSERT_EQUAL(warning["source_node"], node.address, "A LAN warning must name the actual source node")
	second.attack_at = world.time
	second.resolve_program()
	TEST_ASSERT(netrun_test_yield_to(console), "Remote replies wait for the console's own turn after incoming delivery")
	TEST_ASSERT(!console.program_use(strike.uid, REF(unrelated)), "An arbitrary ICE REF must not inherit a contact's access exemption")
	TEST_ASSERT(!console.program_use("builtin:sting", REF(first)), "Remote consoles must not gain free entity attacks")
	TEST_ASSERT(!console.program_use(trace_program.uid, REF(first)), "A stored trace file must remain ICE-only")
	TEST_ASSERT(!console.program_use(barrier.uid, null), "A terminal or deck still has no entity to shield")
	TEST_ASSERT(!console.program_use(patch.uid, null), "A terminal or deck still has no entity to repair")
	TEST_ASSERT(!console.run_command(node, "purge"), "Combat contacts must not bypass ROOT machine command permissions")
	TEST_ASSERT(console.program_use(blackout.uid, REF(first)), "The actual attacker can be stunned before LAN guest access is obtained")
	TEST_ASSERT_EQUAL(console.get_combat_encounter().member(first).stun_turns, 1, "The accepted reply must stun the actual attacker for its next own turn")
	TEST_ASSERT_EQUAL(length(console.combat_targets()), 2, "Stun must not make the enemy disappear from the combat list")
	TEST_ASSERT_EQUAL(length(console.combat_targets()), 2, "A completed cast and its cooldown must retain the contact")
	console.map_view.selected_address = null
	console.combat_context.next_program = world.time
	TEST_ASSERT(netrun_test_yield_to(console, TRUE), "A second two-point reply waits for the next console turn instead of refilling AP")
	TEST_ASSERT(console.program_use(strike.uid, REF(second)), "Selection changes and enemy cooldown do not prevent a reply")
	var/datum/netrun_program/strike_definition = SSnetrun.get_program("strike")
	TEST_ASSERT_EQUAL(second.integrity, second.max_integrity - strike_definition.power, "The response must apply the original program power")
	TEST_ASSERT_EQUAL(console.node_level(node), NETRUN_ACCESS_NONE, "A successful counterattack must not award guest rights")
	console.intrusion.breach.finish()
	TEST_ASSERT_EQUAL(length(console.combat_targets()), 0, "Ending the breach must revoke every response contact")
	console.combat_context.next_program = world.time
	console.combat_context.program_cd.Cut()
	TEST_ASSERT(!console.program_use(strike.uid, REF(second)), "A stale source REF must not outlive its breach")
	TEST_ASSERT(console.start_breach("network", node.network.id), "A later breach must create an independent combat lifetime")
	TEST_ASSERT_EQUAL(length(console.combat_targets()), 0, "A new breach must not inherit the previous attacker's exemption")
	first.combat_stun_until = 0
	first.program_cd.Cut()
	// The previous remote principal left when its breach ended. The guards may
	// retain their local queue, so the fresh breach still waits for a guard turn.
	var/datum/netrun_combat_encounter/remaining_encounter = first.get_combat_encounter()
	if(remaining_encounter?.active)
		TEST_ASSERT(netrun_test_yield_to(first, TRUE), "A new breach waits for the old encounter's ordinary next guard turn")
	TEST_ASSERT(first.begin_program(trace, console), "A fresh incoming trace may establish a new contact on its own turn")
	TEST_ASSERT_EQUAL(length(console.combat_targets()), 1, "Only the fresh attacker should appear in the new breach")
	qdel(first)
	TEST_ASSERT_EQUAL(length(console.combat_targets()), 0, "Deleting an attacker must immediately revoke the contact")

/// Availability changes invalidate actions while the card remains readable until the breach ends.
/datum/unit_test/netrun_remote_combat_route_lifecycle/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, origin.z)
	var/area/room = scene.room(/area/engineering/netrun_route_test)
	scene.take(origin, room)
	var/turf/target_spot = scene.take(get_step(origin, EAST), room)
	var/turf/apc_spot = scene.take(get_step(origin, NORTH), room)
	var/obj/machinery/power/apc/apc = scene.machine(/obj/machinery/power/apc, apc_spot)
	var/obj/item/source_host = allocate(/obj/item, origin)
	var/datum/component/netrun_node/source_node = source_host.AddComponent(/datum/component/netrun_node, NETRUN_NODE_DECK)
	var/obj/item/target_host = allocate(/obj/item, target_spot)
	var/datum/component/netrun_node/node = target_host.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
	var/datum/netrun_console/console = allocate(/datum/netrun_console, source_host, NETRUN_ORIGIN_DECK)
	var/datum/netrun_file/strike = netrun_program_file("strike")
	console.store_file(strike)
	SSnetrun.ensure_topology()
	TEST_ASSERT(console.start_breach("network", node.network.id), "The source must reach the LAN before the route failure")
	var/datum/netrun_ice/ice = allocate(/datum/netrun_ice, node)
	TEST_ASSERT(ice.begin_program(SSnetrun.get_program("trace"), console), "The real incoming trace must create the contact")
	apc.set_machine_stat(BROKEN)
	var/list/targets = console.combat_targets()
	TEST_ASSERT_EQUAL(length(targets), 1, "Route failure must leave an identifiable opponent card")
	var/list/target = targets[1]
	TEST_ASSERT(target["unavailable_reason"], "A disconnected opponent must explain why a reply is disabled")
	TEST_ASSERT(!console.program_use(strike.uid, REF(ice)), "The action must recheck the actual route, regardless of the last UI payload")
	TEST_ASSERT_NULL(console.combat_context.program_cd["strike"], "A rejected reply must not spend cooldown")
	apc.set_machine_stat(0)
	ice.attack_at = world.time
	ice.resolve_program()
	TEST_ASSERT(netrun_test_yield_to(console), "Restoring a route does not let the console reply outside its own turn")
	TEST_ASSERT(console.program_use(strike.uid, REF(ice)), "Restoring the same route during the breach must restore the reply")
	ice.enter_node(source_node)
	TEST_ASSERT_EQUAL(length(console.combat_targets()), 0, "A moved attacker must not retain its original remote contact")
	console.intrusion.lockout_until = world.time + 10 SECONDS
	TEST_ASSERT(!console.program_use(strike.uid, REF(ice)), "Trace lockout must still reject every combat action")
/// A quiet LAN still has a visible patrol walking real cables, without a global intruder.
/datum/unit_test/netrun_ice_patrol_walks_local_links/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, origin.z)
	var/area/room = scene.room(/area/engineering/netrun_route_test)
	var/turf/apc_spot = scene.take(origin, room)
	var/turf/first_spot = scene.take(get_step(origin, EAST), room)
	var/turf/second_spot = scene.take(get_step(origin, NORTH), room)
	var/obj/machinery/power/apc/apc = scene.machine(/obj/machinery/power/apc, apc_spot)
	var/obj/machinery/computer/netrun_terminal/first = scene.machine(/obj/machinery/computer/netrun_terminal, first_spot)
	var/obj/machinery/computer/netrun_terminal/second = scene.machine(/obj/machinery/computer/netrun_terminal, second_spot)
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	var/datum/component/netrun_node/apc_node = apc.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/first_node = first.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/second_node = second.GetComponent(/datum/component/netrun_node)
	var/datum/netrun_ice/ice = allocate(/datum/netrun_ice, first_node, NETRUN_ICE_HUNTER)
	ice.persistent = TRUE
	ice.process_ai(0)
	TEST_ASSERT_EQUAL(ice.node, apc_node, "An idle hunter must leave its leaf through the real APC cable")
	TEST_ASSERT_NOTNULL(graph.edge_between(first_node.address, ice.node.address), "A patrol step must have a real physical edge")
	TEST_ASSERT(!ice.needs_netrun_tick(), "A quiet patrol must sleep between its movement deadlines")
	ice.process_ai(0)
	TEST_ASSERT_EQUAL(ice.node, apc_node, "An extra same-tick wake must not bypass the patrol cooldown")
	ice.hop_cooldown = world.time
	ice.process_ai(0)
	TEST_ASSERT_EQUAL(ice.node, second_node, "The patrol must inspect an unvisited endpoint instead of bouncing straight back")

/// Physically connected departments are separate defense domains.
/datum/unit_test/netrun_ice_hunt_stays_in_lan/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, origin.z)
	var/area/engineering = scene.room(/area/engineering/netrun_route_test)
	var/area/medical = scene.room(/area/medical/netrun_route_test)
	var/turf/eng_spot = scene.take(origin, engineering)
	var/turf/eng_leaf_spot = scene.take(get_step(origin, EAST), engineering)
	var/turf/med_spot = scene.take(locate(origin.x + 4, origin.y, origin.z), medical)
	var/turf/med_leaf_spot = scene.take(get_step(med_spot, NORTH), medical)
	var/obj/machinery/power/apc/eng = scene.machine(/obj/machinery/power/apc, eng_spot)
	scene.machine(/obj/machinery/power/apc, med_spot)
	var/obj/machinery/computer/netrun_terminal/eng_leaf = scene.machine(/obj/machinery/computer/netrun_terminal, eng_leaf_spot)
	var/obj/machinery/computer/netrun_terminal/med_leaf = scene.machine(/obj/machinery/computer/netrun_terminal, med_leaf_spot)
	SSnetrun.ensure_topology()
	var/datum/component/netrun_node/eng_node = eng.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/eng_target = eng_leaf.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/med_target = med_leaf.GetComponent(/datum/component/netrun_node)
	var/datum/netrun_ice/ice = allocate(/datum/netrun_ice, eng_node, NETRUN_ICE_HUNTER)
	ice.persistent = TRUE
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity)
	entity.enter_node(med_target)
	TEST_ASSERT_NOTNULL(ice.find_intruder(med_target), "The remote fixture must actually be an unauthorized entity")
	TEST_ASSERT(!ice.hunt(), "A hunter must not search or leave its LAN for another department's intruder")
	TEST_ASSERT_EQUAL(ice.node, eng_node, "An unrelated remote intruder must not move this LAN's hunter")
	entity.enter_node(eng_target)
	TEST_ASSERT(ice.hunt(), "An intruder arriving in the hunter's own LAN must be pursued")
	TEST_ASSERT_EQUAL(ice.node, eng_target, "The pursuit must take the actual adjacent cable to its target")

/// Count real authorization scans without replacing their target policy.
/datum/netrun_ice/hunt_probe
	var/list/intruder_checks = list()

/datum/netrun_ice/hunt_probe/find_intruder(datum/component/netrun_node/where)
	intruder_checks[where.address] = (intruder_checks[where.address] || 0) + 1
	return ..()

/// Several residents of one host require one scan, whether authorized or hostile.
/datum/unit_test/netrun_ice_hunt_checks_each_host_once/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	for(var/i in 1 to 4)
		var/mob/camera/netrun_entity/authorized = allocate(/mob/camera/netrun_entity)
		authorized.enter_node(scene.node_a)
		authorized.console.access_session.grant_node(scene.node_a, NETRUN_ACCESS_USER)
		var/mob/camera/netrun_entity/intruder = allocate(/mob/camera/netrun_entity)
		intruder.enter_node(scene.node_b)
	var/datum/netrun_ice/hunt_probe/ice = allocate(/datum/netrun_ice/hunt_probe, scene.apc_node, NETRUN_ICE_HUNTER)
	ice.persistent = TRUE
	TEST_ASSERT_NULL(ice.find_intruder(scene.node_a), "The first crowd must actually be authorized, so its scan has a negative result")
	TEST_ASSERT_NOTNULL(ice.find_intruder(scene.node_b), "The second crowd must contain a real intruder")
	ice.intruder_checks.Cut()
	TEST_ASSERT(ice.hunt(), "A real intruder on the adjacent leaf must still be pursued")
	TEST_ASSERT_EQUAL(ice.intruder_checks[scene.node_a.address], 1, "Authorized residents sharing a host must not repeat a negative intruder scan")
	TEST_ASSERT_EQUAL(ice.intruder_checks[scene.node_b.address], 1, "Hostile residents sharing a host must not repeat a positive intruder scan")
	TEST_ASSERT_EQUAL(ice.node, scene.node_b, "Deduplicated acquisition must preserve the actual authorized cable step toward the target")

/// Initialization waits for a committed graph and also covers departments introduced later.
/datum/unit_test/netrun_ice_patrol_topology_lifecycle/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, origin.z)
	var/area/engineering = scene.room(/area/engineering/netrun_route_test)
	var/area/medical = scene.room(/area/medical/netrun_route_test)
	var/obj/machinery/power/apc/eng = scene.machine(/obj/machinery/power/apc, scene.take(origin, engineering))
	var/obj/machinery/power/apc/med = scene.machine(/obj/machinery/power/apc, scene.take(get_step(origin, EAST), medical))
	SSnetrun.ensure_topology()
	var/datum/component/netrun_node/eng_node = eng.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/med_node = med.GetComponent(/datum/component/netrun_node)
	var/datum/controller/subsystem/netrun/netrun_execution_test/worker = allocate(/datum/controller/subsystem/netrun/netrun_execution_test)
	worker.topology = allocate(/datum/netrun_topology)
	worker.networks = list()
	worker.networks[eng_node.network.id] = eng_node.network
	worker.initialize_patrol()
	TEST_ASSERT(!worker.patrol_initialized && !length(worker.patrol_seeded_networks), "An incomplete graph must not consume the one-time patrol initialization")
	worker.topology.dirty = FALSE
	worker.topology.revision = 1
	var/list/before = SSnetrun.ice_processes.Copy()
	worker.initialize_patrol()
	var/list/created = SSnetrun.ice_processes - before
	allocated |= created
	TEST_ASSERT_EQUAL(length(created), 1, "The first committed protected LAN must receive one persistent hunter")
	var/datum/netrun_ice/patrol = created[1]
	TEST_ASSERT(patrol.persistent && patrol.patrol_network_id == eng_node.network.id, "A spawned patrol must retain its own LAN identity")
	worker.initialize_patrol()
	TEST_ASSERT_EQUAL(length(SSnetrun.ice_processes - before), 1, "Reconciliation must not duplicate an existing patrol")
	worker.networks[med_node.network.id] = med_node.network
	worker.topology.revision++
	worker.initialize_patrol()
	created = SSnetrun.ice_processes - before
	allocated |= created
	TEST_ASSERT_EQUAL(length(created), 2, "A protected LAN added after startup must also receive its patrol")
	qdel(patrol)
	worker.initialize_patrol()
	TEST_ASSERT_EQUAL(length(SSnetrun.ice_processes - before), 1, "Defeating a patrol must not respawn it on an unrelated topology update")

/// Alerts wake only their LAN and temporary response limits do not count persistent patrols.
/datum/unit_test/netrun_ice_defense_scope_and_quota/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, origin.z)
	var/area/engineering = scene.room(/area/engineering/netrun_route_test)
	var/area/medical = scene.room(/area/medical/netrun_route_test)
	var/obj/machinery/power/apc/eng = scene.machine(/obj/machinery/power/apc, scene.take(origin, engineering))
	var/obj/machinery/power/apc/med = scene.machine(/obj/machinery/power/apc, scene.take(get_step(origin, EAST), medical))
	SSnetrun.ensure_topology()
	var/datum/component/netrun_node/eng_node = eng.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/med_node = med.GetComponent(/datum/component/netrun_node)
	var/datum/netrun_ice/patrol = allocate(/datum/netrun_ice, eng_node, NETRUN_ICE_HUNTER)
	patrol.persistent = TRUE
	allocate(/datum/netrun_ice, eng_node, NETRUN_ICE_HUNTER)
	allocate(/datum/netrun_ice, eng_node, NETRUN_ICE_HUNTER)
	var/datum/netrun_ice/foreign = allocate(/datum/netrun_ice, med_node, NETRUN_ICE_HUNTER)
	foreign.hop_cooldown = world.time + 50 SECONDS
	var/datum/controller/subsystem/netrun/netrun_execution_test/worker = allocate(/datum/controller/subsystem/netrun/netrun_execution_test)
	worker.nodes_by_address = SSnetrun.nodes_by_address
	worker.hunters_by_network = SSnetrun.hunters_by_network
	worker.defense_nests[eng_node.address] = 5
	worker.defense_nests[med_node.address] = 2
	var/list/before = SSnetrun.ice_processes.Copy()
	worker.alert_defenses(eng_node, null)
	var/list/responses = SSnetrun.ice_processes - before
	allocated |= responses
	TEST_ASSERT_EQUAL(length(responses), 1, "A LAN with two temporary hunters may wake only one additional response")
	TEST_ASSERT_EQUAL(worker.defense_nests[eng_node.address], 4, "Only successfully spawned responses must consume the local reserve")
	TEST_ASSERT_EQUAL(worker.defense_nests[med_node.address], 2, "An alert must not consume another LAN's reserve")
	TEST_ASSERT_EQUAL(foreign.hop_cooldown, world.time + 50 SECONDS, "An unrelated department's hunter must remain asleep")
	worker.dispatch_hunter(eng_node)
	TEST_ASSERT_EQUAL(length(SSnetrun.ice_processes - before), 1, "A full local temporary quota must prevent another response")
	for(var/datum/netrun_ice/hunter as anything in SSnetrun.hunters_by_network[eng_node.network.id].Copy())
		if(!hunter.persistent)
			qdel(hunter)
	before = SSnetrun.ice_processes.Copy()
	worker.dispatch_hunter(eng_node)
	responses = SSnetrun.ice_processes - before
	allocated |= responses
	TEST_ASSERT_EQUAL(length(responses), 1, "A persistent patrol and foreign hunters must not consume the local temporary response quota")
	var/datum/netrun_ice/temporary = responses[1]
	temporary.idle_expires_at = world.time
	temporary.process_ai(0)
	TEST_ASSERT(QDELETED(temporary), "An unused temporary response must expire by deadline even without regular AI ticks")
