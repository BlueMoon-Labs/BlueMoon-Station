/// Two endpoints behind one real APC: A - APC - B, all in one engineering LAN.
/datum/netrun_fortress_scene
	parent_type = /datum/netrun_route_scene
	var/obj/machinery/power/apc/apc
	var/datum/component/netrun_node/apc_node
	var/datum/component/netrun_node/node_a
	var/datum/component/netrun_node/node_b

/datum/netrun_fortress_scene/New(turf/origin)
	..(origin.z)
	var/area/room = room(/area/engineering/netrun_route_test)
	take(origin, room)
	var/turf/b_spot = take(get_step(origin, EAST), room)
	var/turf/apc_spot = take(get_step(origin, NORTH), room)
	apc = machine(/obj/machinery/power/apc, apc_spot)
	apc_node = apc.GetComponent(/datum/component/netrun_node)
	// Anchored endpoints are stationary devices that may carry fortress works.
	var/obj/item/a_host = new(origin)
	a_host.anchored = TRUE
	owned += a_host
	node_a = a_host.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL, list(), 1, list(), 4)
	var/obj/item/b_host = new(b_spot)
	b_host.anchored = TRUE
	owned += b_host
	node_b = b_host.AddComponent(/datum/component/netrun_node, NETRUN_NODE_SERVER, list(), 1, list(), 4)
	SSnetrun.ensure_topology()

/datum/netrun_fortress_scene/proc/key_file()
	var/datum/netrun_network/network = node_b.network
	return new /datum/netrun_file("[network.id].key", NETRUN_FILE_KEY, network.passcode, 1, network.id)

/// Bare items are stationary and anchored enough for the fortress slot rule.
/datum/unit_test/proc/netrun_fortress_node(node_type = NETRUN_NODE_SERVER)
	var/obj/item/host = allocate(/obj/item)
	host.anchored = TRUE
	return host.AddComponent(/datum/component/netrun_node, node_type, list(), 1, list(), 4)

/datum/unit_test/netrun_fortress_build_requirements/Run()
	var/datum/component/netrun_node/node = netrun_fortress_node()
	var/mob/camera/netrun_entity/builder = allocate(/mob/camera/netrun_entity)
	builder.enter_node(node)
	var/datum/netrun_console/console = builder.console
	console.access_session.node_access[node.address] = NETRUN_ACCESS_ROOT
	TEST_ASSERT(findtext(netrun_fortress_build_denial(node, console, NETRUN_FORT_WALL), "forge.exe"), "Building must require the forge daemon")
	TEST_ASSERT(console.store_file(netrun_daemon_file("forge")), "The forge daemon must fit client memory")
	TEST_ASSERT_NULL(netrun_fortress_build_denial(node, console, NETRUN_FORT_WALL), "ROOT with forge.exe may build on a server")
	TEST_ASSERT(netrun_fortress_build_denial(node, console, "moat"), "Unknown modules are refused")
	var/before = node.get_security()
	var/datum/netrun_fortress_module/wall = SSnetrun.build_fortress_module(node, NETRUN_FORT_WALL, console)
	TEST_ASSERT_NOTNULL(node.fortress, "The first module founds the fortress")
	TEST_ASSERT(node.fortress.is_owner(console), "The builder owns the new fortress")
	TEST_ASSERT_EQUAL(wall.status, NETRUN_FORT_MODULE_BUILDING, "A new module is a construction site first")
	TEST_ASSERT_EQUAL(node.get_security(), before, "Scaffolding gives no protection")
	wall.complete_build()
	TEST_ASSERT_EQUAL(node.get_security(), min(5, before + 1), "A standing wall raises the node's security")
	TEST_ASSERT(SSnetrun.fortress_nodes[node.address] == node, "Fortified nodes are indexed for siege lookups")
	var/datum/component/netrun_node/camera = netrun_fortress_node(NETRUN_NODE_CAMERA)
	TEST_ASSERT(findtext(netrun_fortress_build_denial(camera, console, NETRUN_FORT_WALL), "не может"), "Cameras cannot carry works")
	TEST_ASSERT(("fort_build@wall" in node.all_command_ids()) && !("fort_build@wall" in camera.all_command_ids()), "Only eligible nodes publish the build menu")
	TEST_ASSERT("fort_dismantle@wall" in node.all_command_ids(), "Built kinds can be dismantled")

/datum/unit_test/netrun_fortress_walls_block_breach/Run()
	var/datum/component/netrun_node/node = netrun_fortress_node()
	var/obj/item/owner_host = allocate(/obj/item)
	var/datum/netrun_console/owner = allocate(/datum/netrun_console, owner_host)
	var/datum/netrun_fortress/fortress = new(node, "Проверка", NETRUN_FACTION_OWNER, owner)
	node.fortress = fortress
	var/datum/netrun_fortress_module/wall = fortress.add_module(NETRUN_FORT_WALL, TRUE)
	var/mob/camera/netrun_entity/intruder = allocate(/mob/camera/netrun_entity)
	intruder.enter_node(node)
	TEST_ASSERT(fortress.blocks_breach(intruder.console), "Standing walls refuse strangers")
	TEST_ASSERT(!fortress.blocks_breach(owner), "The owner is never blocked by own walls")
	TEST_ASSERT(!intruder.console.start_breach("node", node.address), "The breach protocol cannot start through a wall")
	wall.take_damage(1000, "test", null)
	TEST_ASSERT_EQUAL(wall.status, NETRUN_FORT_MODULE_DESTROYED, "Enough damage destroys a module")
	TEST_ASSERT(!fortress.blocks_breach(intruder.console), "A ruined wall no longer protects the node")
	TEST_ASSERT(intruder.console.start_breach("node", node.address), "The node can be cracked once the walls fall")
	intruder.console.intrusion.breach.finish()
	TEST_ASSERT(fortress.ruined(), "A fortress with every module destroyed is a ruin")
	TEST_ASSERT(fortress.can_build(intruder.console), "Ruins may be claimed by a new builder")

/datum/unit_test/netrun_fortress_gate_and_trap/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/obj/item/owner_host = allocate(/obj/item)
	var/datum/netrun_console/owner = allocate(/datum/netrun_console, owner_host)
	var/mob/camera/netrun_entity/visitor = allocate(/mob/camera/netrun_entity)
	visitor.enter_node(scene.apc_node)
	TEST_ASSERT(visitor.console.store_file(scene.key_file()), "The visitor carries the LAN key")
	TEST_ASSERT(visitor.can_enter(scene.node_b), "A LAN key admits travel to an unfortified neighbour")
	var/datum/netrun_fortress/fortress = new(scene.node_b, "Проверка", NETRUN_FACTION_OWNER, owner)
	scene.node_b.fortress = fortress
	fortress.add_module(NETRUN_FORT_GATE, TRUE)
	TEST_ASSERT(!visitor.can_enter(scene.node_b), "A closed gate ignores LAN keys")
	TEST_ASSERT(findtext(visitor.hop_denial(scene.node_b), "врата"), "The refusal names the gate")
	visitor.console.access_session.node_access[scene.node_b.address] = NETRUN_ACCESS_USER
	TEST_ASSERT(visitor.can_enter(scene.node_b), "USER on the node passes the gate")
	visitor.console.access_session.node_access -= scene.node_b.address
	var/datum/netrun_fortress_module/trap = fortress.add_module(NETRUN_FORT_TRAP, TRUE)
	var/trace_before = visitor.console.intrusion.trace
	visitor.enter_node(scene.node_b)
	TEST_ASSERT(visitor.is_stunned(), "An armed trap stuns a hostile arrival")
	TEST_ASSERT(visitor.console.intrusion.trace > trace_before, "A trap exposes the intruder's session")
	TEST_ASSERT(trap.ready_at > world.time, "A sprung trap needs time to re-arm")
	visitor.combat_stun_until = 0
	var/trace_after = visitor.console.intrusion.trace
	visitor.enter_node(scene.apc_node)
	visitor.enter_node(scene.node_b)
	TEST_ASSERT(!visitor.is_stunned() && visitor.console.intrusion.trace == trace_after, "A spent trap does not fire twice")

/datum/unit_test/netrun_fortress_siege_adjacent/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/obj/item/owner_host = allocate(/obj/item)
	var/datum/netrun_console/owner = allocate(/datum/netrun_console, owner_host)
	var/datum/netrun_fortress/fortress = new(scene.node_b, "Проверка", NETRUN_FACTION_OWNER, owner)
	scene.node_b.fortress = fortress
	var/datum/netrun_fortress_module/wall = fortress.add_module(NETRUN_FORT_WALL, TRUE)
	var/datum/netrun_fortress_module/turret = fortress.add_module(NETRUN_FORT_TURRET, TRUE)
	TEST_ASSERT((wall in fortress.siege_targets()) && !(turret in fortress.siege_targets()), "Walls shield the inner works from a siege")
	var/mob/camera/netrun_entity/attacker = allocate(/mob/camera/netrun_entity)
	attacker.enter_node(scene.apc_node)
	TEST_ASSERT(scene.node_b in netrun_adjacent_fortress_nodes(scene.apc_node), "The neighbouring fortress is visible to a besieger")
	var/datum/component/netrun_combatant/combatant = wall.get_netrun_combatant()
	TEST_ASSERT(combatant.allows_remote_attack(attacker.console, scene.apc_node), "Outer works can be hit from an adjacent node")
	TEST_ASSERT(!combatant.allows_remote_attack(attacker.console, scene.node_a), "Two hops away is out of siege range")
	var/found = FALSE
	for(var/list/entry as anything in attacker.console.combat_targets())
		if(entry["ref"] == REF(wall))
			found = TRUE
			TEST_ASSERT_NULL(entry["unavailable_reason"], "An adjacent besieger may target the wall")
			TEST_ASSERT_EQUAL(entry["kind"], "fortress", "Structures are their own target kind")
	TEST_ASSERT(found, "The wall appears among the besieger's targets")
	wall.take_damage(1000, "test", attacker.console)
	TEST_ASSERT(turret in fortress.siege_targets(), "Once the walls fall the inner works are exposed")

/datum/unit_test/netrun_fortress_vault_access/Run()
	var/datum/component/netrun_node/node = netrun_fortress_node()
	var/obj/item/owner_host = allocate(/obj/item)
	var/datum/netrun_console/owner = allocate(/datum/netrun_console, owner_host)
	var/obj/item/stranger_host = allocate(/obj/item)
	var/datum/netrun_console/stranger = allocate(/datum/netrun_console, stranger_host)
	var/base_capacity = node.file_store.capacity
	var/datum/netrun_fortress/fortress = new(node, "Проверка", NETRUN_FACTION_OWNER, owner)
	node.fortress = fortress
	var/datum/netrun_fortress_module/vault = fortress.add_module(NETRUN_FORT_VAULT, TRUE)
	TEST_ASSERT_EQUAL(node.file_store.capacity, base_capacity + NETRUN_FORT_VAULT_STORAGE, "A vault extends the node disk")
	TEST_ASSERT_EQUAL(fortress.file_access_level(stranger), NETRUN_ACCESS_ROOT, "Strangers need ROOT for vault files")
	TEST_ASSERT_EQUAL(fortress.file_access_level(owner), 0, "The owner keeps ordinary file access")
	vault.take_damage(1000, "test", null)
	TEST_ASSERT_EQUAL(node.file_store.capacity, base_capacity, "A destroyed vault returns its storage")
	TEST_ASSERT_EQUAL(fortress.file_access_level(stranger), 0, "A destroyed vault no longer locks files")

/datum/unit_test/netrun_fortress_preset_lifecycle/Run()
	var/datum/component/netrun_node/node = netrun_fortress_node()
	var/datum/netrun_fortress/fortress = SSnetrun.build_fortress_preset(node, "rnd_archive")
	TEST_ASSERT_NOTNULL(fortress, "A preset deploys on an eligible node")
	TEST_ASSERT_EQUAL(fortress.faction, NETRUN_FACTION_STATION, "Station presets belong to the station")
	TEST_ASSERT_EQUAL(length(fortress.modules), 5, "The archive preset deploys all its modules")
	TEST_ASSERT_EQUAL(fortress.intact_count(NETRUN_FORT_WALL), 2, "Preset modules stand immediately")
	TEST_ASSERT_EQUAL(SSnetrun.build_fortress_preset(node, "relay_outpost"), fortress, "A fortified node keeps its fortress")
	var/list/summary = node.ui_entry(allocate(/datum/netrun_console, allocate(/obj/item)))["fortress"]
	TEST_ASSERT_EQUAL(summary?["walls"], 2, "The map summary counts standing walls")
	var/address = node.address
	qdel(node)
	TEST_ASSERT(QDELETED(fortress), "A deleted node takes its fortress with it")
	TEST_ASSERT_NULL(SSnetrun.fortress_nodes[address], "The siege index forgets deleted fortresses")

/// Public backend construction must enforce the same ROOT/tool admission as its command.
/datum/unit_test/netrun_fortress_backend_admission/Run()
	var/datum/component/netrun_node/node = netrun_fortress_node()
	var/mob/camera/netrun_entity/builder = allocate(/mob/camera/netrun_entity)
	builder.enter_node(node)
	TEST_ASSERT(builder.console.store_file(netrun_daemon_file("forge")), "The builder must own the actual construction daemon")
	TEST_ASSERT_NULL(SSnetrun.build_fortress_module(node, NETRUN_FORT_WALL, builder.console), "A direct backend call must not bypass ROOT")
	TEST_ASSERT_NULL(node.fortress, "Rejected construction must not leave an empty claimed fortress")
	builder.console.access_session.node_access[node.address] = NETRUN_ACCESS_ROOT
	TEST_ASSERT_NULL(SSnetrun.build_fortress_module(node, "unknown", builder.console), "Invalid module kinds must be rejected before founding works")
	TEST_ASSERT_NULL(node.fortress, "An invalid kind must not consume the fortress index")
	TEST_ASSERT(SSnetrun.build_fortress_module(node, NETRUN_FORT_WALL, builder.console), "An admitted builder must still start ordinary construction")

/// Fully occupied ruins must not permanently block takeover with their obsolete slot counters.
/datum/unit_test/netrun_fortress_ruins_rebuild/Run()
	var/datum/component/netrun_node/node = netrun_fortress_node()
	var/datum/netrun_console/owner = allocate(/datum/netrun_console, allocate(/obj/item))
	var/datum/netrun_fortress/fortress = new(node, "Old works", NETRUN_FACTION_OWNER, owner)
	node.fortress = fortress
	for(var/i in 1 to 3)
		fortress.add_module(NETRUN_FORT_WALL, TRUE)
	fortress.add_module(NETRUN_FORT_GATE, TRUE)
	for(var/i in 1 to 2)
		fortress.add_module(NETRUN_FORT_TURRET, TRUE)
	TEST_ASSERT_EQUAL(fortress.slots_used(), fortress.slots_max(), "The fixture must occupy every fortress slot")
	var/datum/netrun_fortress_module/old = fortress.modules[1]
	for(var/datum/netrun_fortress_module/module as anything in fortress.modules)
		module.take_damage(1000, "test", null)
	var/mob/camera/netrun_entity/claimer = allocate(/mob/camera/netrun_entity)
	claimer.enter_node(node)
	claimer.console.access_session.node_access[node.address] = NETRUN_ACCESS_ROOT
	claimer.console.store_file(netrun_daemon_file("forge"))
	TEST_ASSERT_NULL(netrun_fortress_build_denial(node, claimer.console, NETRUN_FORT_WALL), "Ruins must be rebuildable even when the former loadout used every wall and slot")
	var/datum/netrun_fortress_module/rebuilt = SSnetrun.build_fortress_module(node, NETRUN_FORT_WALL, claimer.console)
	TEST_ASSERT(rebuilt && fortress.is_owner(claimer.console), "Rebuilding hostile ruins must transfer ownership")
	TEST_ASSERT(QDELETED(old), "A new claim must release obsolete destroyed-module datums")
	TEST_ASSERT_EQUAL(length(fortress.modules), 1, "Rebuilding must retain only its new construction site")
	TEST_ASSERT_EQUAL(fortress.slots_used(), rebuilt.slot_cost, "Old ruins must not continue consuming slots")

/// Duplicate kinds are managed by stable instance IDs, with identical UI/delivery refusal.
/datum/unit_test/netrun_fortress_targeted_management/Run()
	var/datum/component/netrun_node/node = netrun_fortress_node()
	var/mob/camera/netrun_entity/builder = allocate(/mob/camera/netrun_entity)
	builder.enter_node(node)
	builder.console.access_session.node_access[node.address] = NETRUN_ACCESS_ROOT
	builder.console.store_file(netrun_daemon_file("forge"))
	var/datum/netrun_fortress_module/first = SSnetrun.build_fortress_module(node, NETRUN_FORT_WALL, builder.console)
	first.complete_build()
	var/datum/netrun_fortress/fortress = node.fortress
	var/datum/netrun_fortress_module/second = fortress.add_module(NETRUN_FORT_WALL, TRUE)
	first.take_damage(50, "test", null)
	second.take_damage(90, "test", null)
	var/datum/netrun_command/repair = SSnetrun.get_command("fort_repair")
	TEST_ASSERT(repair.execute(node, builder.console, first.id), "A selected damaged module must accept repair")
	TEST_ASSERT_EQUAL(first.integrity, first.max_integrity, "The repair must affect the requested instance")
	TEST_ASSERT_EQUAL(second.integrity, second.max_integrity - 90, "A more damaged duplicate must not steal a targeted repair")
	var/list/button = repair.ui_entry(node, builder.console, "fort_repair@[second.id]")
	TEST_ASSERT(!button["allowed"] && button["unavailable_reason"], "UI must describe the actual shared repair cooldown")
	TEST_ASSERT_NULL(repair.execute(node, builder.console, second.id), "Delivery must enforce the same cooldown")
	var/datum/netrun_command/dismantle = SSnetrun.get_command("fort_dismantle")
	var/stale_id = second.id
	TEST_ASSERT(dismantle.execute(node, builder.console, stale_id), "ROOT owner must be able to dismantle one chosen duplicate")
	TEST_ASSERT(QDELETED(second) && !QDELETED(first), "Instance dismantling must preserve the other wall")
	TEST_ASSERT_NULL(dismantle.execute(node, builder.console, stale_id), "A stale delayed module ID must never select another same-kind module")

/// Jam expiry and defender combat signals provide finite wakeups, then return idle works to sleep.
/datum/unit_test/netrun_fortress_reactive_maintenance/Run()
	var/datum/component/netrun_node/node = netrun_fortress_node()
	var/datum/netrun_fortress/fortress = new(node, "Reactive works")
	node.fortress = fortress
	var/datum/netrun_fortress_module/turret = fortress.add_module(NETRUN_FORT_TURRET, TRUE)
	fortress.add_module(NETRUN_FORT_REGEN, TRUE)
	turret.jam(5 SECONDS)
	TEST_ASSERT(fortress.timer_id && fortress.next_wake == turret.jammed_until, "A jammed idle turret must schedule its finite recovery")
	turret.jammed_until = world.time
	fortress.process_tick()
	fortress.schedule()
	TEST_ASSERT(!turret.is_jammed() && !fortress.timer_id, "Recovered idle turrets must return to sleep")
	var/datum/netrun_ice/ice = allocate(/datum/netrun_ice, node)
	ice.apply_damage(3, "test", null)
	TEST_ASSERT(fortress.timer_id, "Damage to a local ICE defender alone must wake its regenerator")
	fortress.process_tick()
	fortress.schedule()
	TEST_ASSERT_EQUAL(ice.integrity, ice.max_integrity, "The awakened regenerator must heal the actual defender")
	TEST_ASSERT(!fortress.timer_id, "A fully healed fortress must stop its maintenance timer")

/// Vault permissions apply to bulk siphoning as well as ordinary file requests.
/datum/unit_test/netrun_fortress_vault_bulk_acl/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/intruder = allocate(/mob/camera/netrun_entity)
	intruder.enter_node(scene.node_b)
	intruder.console.access_session.node_access[scene.node_b.address] = NETRUN_ACCESS_USER
	intruder.console.store_file(netrun_daemon_file("siphon"))
	var/datum/netrun_console/owner = allocate(/datum/netrun_console, allocate(/obj/item))
	var/datum/netrun_fortress/fortress = new(scene.node_b, "Vault", NETRUN_FACTION_OWNER, owner)
	scene.node_b.fortress = fortress
	fortress.add_module(NETRUN_FORT_VAULT, TRUE)
	var/datum/netrun_file/secret = new("secret.txt", NETRUN_FILE_TEXT, "FORTRESS_SECRET", 1)
	scene.node_b.file_store.insert(secret)
	var/datum/netrun_command/siphon = SSnetrun.get_command("siphon")
	var/list/button = siphon.ui_entry(scene.node_b, intruder.console, "siphon")
	TEST_ASSERT(!button["allowed"], "USER must not be offered bulk extraction through a vault")
	TEST_ASSERT_NULL(siphon.execute(scene.node_b, intruder.console), "Direct execution must not bypass vault ROOT")
	TEST_ASSERT(!findtext(json_encode(intruder.console.storage_payload()), "FORTRESS_SECRET"), "A denied bulk request must reveal no vault content")
	intruder.console.access_session.node_access[scene.node_b.address] = NETRUN_ACCESS_ROOT
	TEST_ASSERT(siphon.execute(scene.node_b, intruder.console), "ROOT must retain ordinary bulk extraction from the vault")

/datum/netrun_fortress_preset/invalid_test
	id = "netrun_invalid_test"
	name = "Invalid test preset"
	modules = list(NETRUN_FORT_WALL = 4)

/// Invalid/overfull presets fail atomically and do not create unsupported fortresses.
/datum/unit_test/netrun_fortress_preset_validation/Run()
	var/datum/component/netrun_node/camera = netrun_fortress_node(NETRUN_NODE_CAMERA)
	TEST_ASSERT_NULL(SSnetrun.build_fortress_preset(camera, "rnd_archive"), "Ineligible device types must refuse preset deployment")
	TEST_ASSERT_NULL(camera.fortress, "Rejected presets must not leave a partial fortress")
	var/datum/component/netrun_node/server = netrun_fortress_node()
	TEST_ASSERT_NULL(SSnetrun.build_fortress_preset(server, "netrun_invalid_test"), "Preset deployment must enforce per-kind module limits before mutating the node")
	TEST_ASSERT_NULL(server.fortress, "An invalid loadout must not reserve fortress slots or ownership")

/// Converting a stationary host to a mobile endpoint must not create a portable citadel.
/datum/unit_test/netrun_fortress_mobile_dormancy/Run()
	var/datum/component/netrun_node/node = netrun_fortress_node()
	var/obj/item/host = node.parent
	var/base_capacity = node.file_store.capacity
	var/datum/netrun_fortress/fortress = new(node, "Stationary works")
	node.fortress = fortress
	fortress.add_module(NETRUN_FORT_WALL, TRUE)
	fortress.add_module(NETRUN_FORT_VAULT, TRUE)
	var/datum/netrun_file/cargo = new("cargo.txt", NETRUN_FILE_TEXT, "payload", node.file_store.capacity)
	TEST_ASSERT(node.file_store.insert(cargo), "The live vault must hold its complete expanded payload")
	host.anchored = FALSE
	node.notify_changed()
	TEST_ASSERT_EQUAL(fortress.security_bonus(), 0, "A mobile endpoint must not carry active fortress walls")
	TEST_ASSERT_EQUAL(node.file_store.capacity, base_capacity, "A mobile endpoint must lose the dormant vault's bonus")
	TEST_ASSERT((cargo in node.file_store.files) && !QDELETED(cargo), "Removing bonus memory must preserve the existing file owner even when overfull")
	TEST_ASSERT_EQUAL(fortress.next_deadline(), INFINITY, "Dormant works must own no perpetual processing deadline")
	host.anchored = TRUE
	node.notify_changed()
	TEST_ASSERT_EQUAL(node.file_store.capacity, base_capacity + NETRUN_FORT_VAULT_STORAGE, "Restoring a stationary host must restore its original vault exactly once")
	TEST_ASSERT_EQUAL(fortress.security_bonus(), 1, "Stationary walls must resume their passive defense")

/obj/item/netrun_fortress_priority
	anchored = TRUE

/obj/item/netrun_fortress_priority/low
/obj/item/netrun_fortress_priority/high

/datum/netrun_fortress_preset/priority_low_test
	id = "priority_low_test"
	name = "Common test endpoint"
	priority = 100
	modules = list(NETRUN_FORT_WALL = 1)
	target_types = list(/obj/item/netrun_fortress_priority/low)

/datum/netrun_fortress_preset/priority_high_test
	id = "priority_high_test"
	name = "Critical test core"
	priority = 5
	modules = list(NETRUN_FORT_WALL = 1)
	target_types = list(/obj/item/netrun_fortress_priority/high)

/datum/controller/subsystem/netrun/fortress_seed_test
	flags = SS_NO_INIT | SS_NO_FIRE

/datum/controller/subsystem/netrun/fortress_seed_test/New()
	return

/datum/controller/subsystem/netrun/fortress_seed_test/Destroy()
	QDEL_NULL(topology)
	for(var/id in fortress_presets)
		qdel(fortress_presets[id])
	fortress_presets = null
	nodes_by_address.Cut()
	return ..()

/// Abundant low-value endpoints cannot consume the global quota before an important core.
/datum/unit_test/netrun_fortress_priority_and_history/Run()
	var/datum/controller/subsystem/netrun/fortress_seed_test/worker = allocate(/datum/controller/subsystem/netrun/fortress_seed_test)
	worker.fortress_presets_enabled = TRUE
	worker.topology = new
	worker.topology.dirty = FALSE
	for(var/i in 1 to NETRUN_MAX_FORTRESS_PRESETS)
		var/obj/item/netrun_fortress_priority/low/host = allocate(/obj/item/netrun_fortress_priority/low)
		var/datum/component/netrun_node/node = host.AddComponent(/datum/component/netrun_node, NETRUN_NODE_SERVER)
		worker.nodes_by_address[node.address] = node
	var/obj/item/netrun_fortress_priority/high/critical = allocate(/obj/item/netrun_fortress_priority/high)
	var/datum/component/netrun_node/core = critical.AddComponent(/datum/component/netrun_node, NETRUN_NODE_SERVER)
	worker.nodes_by_address[core.address] = core
	worker.topology.dirty = FALSE
	worker.initialize_fortresses()
	TEST_ASSERT_EQUAL(core.fortress?.preset_id, "priority_high_test", "Critical presets must deploy before common endpoints registered earlier")
	TEST_ASSERT_EQUAL(length(worker.fortress_presets_seeded), NETRUN_MAX_FORTRESS_PRESETS, "Priority seeding must still honor the global fortress cap")
	qdel(core.fortress)
	worker.initialize_fortresses()
	TEST_ASSERT_NULL(core.fortress, "Another initialization must not resurrect a destroyed important fortress")
	TEST_ASSERT_EQUAL(worker.fortress_presets_seeded[core.address], "priority_high_test", "A destroyed fortress must retain its original preset identity for quota accounting")
