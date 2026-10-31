/datum/netrun_salvage_test_observer
	var/changes = 0
	var/recovers = 0
	var/datum/netrun_file/recovered_file
	var/datum/component/netrun_node/recovered_node
	var/datum/weakref/entity_ref

/datum/netrun_salvage_test_observer/New(mob/camera/netrun_entity/entity)
	RegisterSignal(SSnetrun, COMSIG_NETRUN_SALVAGE_CHANGED, PROC_REF(on_changed))
	if(entity)
		entity_ref = WEAKREF(entity)
		RegisterSignal(entity, COMSIG_NETRUN_SALVAGE_RECOVERED, PROC_REF(on_recovered))

/datum/netrun_salvage_test_observer/Destroy()
	UnregisterSignal(SSnetrun, COMSIG_NETRUN_SALVAGE_CHANGED)
	var/mob/camera/netrun_entity/entity = entity_ref?.resolve()
	if(entity)
		UnregisterSignal(entity, COMSIG_NETRUN_SALVAGE_RECOVERED)
	entity_ref = null
	recovered_file = null
	recovered_node = null
	return ..()

/datum/netrun_salvage_test_observer/proc/on_changed(datum/source, datum/component/netrun_node/node)
	SIGNAL_HANDLER
	changes++

/datum/netrun_salvage_test_observer/proc/on_recovered(datum/source, datum/netrun_file/file, datum/component/netrun_node/node)
	SIGNAL_HANDLER
	recovers++
	recovered_file = file
	recovered_node = node

/// Caches own original datums, reject duplicate insertion and evict within a fixed bound.
/datum/unit_test/netrun_salvage_cache_bounds/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/component/netrun_node/node = host.AddComponent(/datum/component/netrun_node, NETRUN_NODE_SERVER)
	TEST_ASSERT_EQUAL(SSnetrun.recycling_servers[node.address], node, "Server registration adds its unload-candidate index entry")
	var/datum/netrun_salvage_test_observer/observer = allocate(/datum/netrun_salvage_test_observer)
	var/datum/netrun_file/first = new("first.txt", NETRUN_FILE_TEXT, "original")
	TEST_ASSERT(node.leave_salvage(first, "fixture"), "A detached real file becomes recoverable debris")
	TEST_ASSERT_EQUAL(SSnetrun.salvage_nodes[node.address], node, "Only a nonempty debris cache enters the index")
	TEST_ASSERT(node.leave_salvage(first, "fixture"), "Reinserting the same datum is idempotent")
	TEST_ASSERT_EQUAL(length(node.salvage), 1, "An original file cannot occupy two cache slots")
	TEST_ASSERT_EQUAL(observer.changes, 1, "An idempotent insert emits no extra work")
	for(var/index in 1 to NETRUN_MAX_SALVAGE_FILES)
		TEST_ASSERT(node.leave_salvage(new /datum/netrun_file("[index].txt", NETRUN_FILE_TEXT, "payload")), "Bounded cache insertion accepts a detached original")
	TEST_ASSERT_EQUAL(length(node.salvage), NETRUN_MAX_SALVAGE_FILES, "The cache cannot grow without bound")
	TEST_ASSERT(QDELETED(first), "Eviction releases the oldest owned file")
	var/address = node.address
	var/list/remaining = node.salvage.Copy()
	qdel(host)
	TEST_ASSERT_NULL(SSnetrun.salvage_nodes[address], "Destroying the host removes its debris index entry")
	TEST_ASSERT_NULL(SSnetrun.recycling_servers[address], "Destroying a server also removes its unload-candidate index entry")
	for(var/datum/netrun_file/file as anything in remaining)
		TEST_ASSERT(QDELETED(file), "Host destruction releases every remaining debris file")

/// A rejected pickup retains ownership; a successful one transfers and announces the same object.
/datum/unit_test/netrun_salvage_pickup_identity/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	var/datum/netrun_salvage_test_observer/observer = allocate(/datum/netrun_salvage_test_observer, entity)
	var/datum/netrun_file/file = new("cargo.txt", NETRUN_FILE_TEXT, "carried original", 2)
	TEST_ASSERT(scene.node_a.leave_salvage(file), "The source cache owns one actual cargo file")
	entity.console.inventory.local_store.capacity = 0
	TEST_ASSERT(!entity.console.recover_salvage(file.uid), "Pickup rejects a full process memory")
	TEST_ASSERT((file in scene.node_a.salvage) && SSnetrun.salvage_nodes[scene.node_a.address], "A failed pickup preserves file and index ownership")
	TEST_ASSERT_EQUAL(observer.recovers, 0, "Rejected recovery emits no successful-cargo signal")
	entity.console.inventory.local_store.capacity = file.size
	TEST_ASSERT(entity.console.recover_salvage(file.uid), "A resident can recover the original after freeing memory")
	TEST_ASSERT(file in entity.console.inventory.local_store.files, "Recovery moves the actual datum instead of copying it")
	TEST_ASSERT_NULL(SSnetrun.salvage_nodes[scene.node_a.address], "Emptying the last cache entry releases its index")
	TEST_ASSERT(observer.recovers == 1 && observer.recovered_file == file && observer.recovered_node == scene.node_a, "The successful recovery identifies its original cargo and source")
	TEST_ASSERT(!entity.console.recover_salvage(file.uid), "A repeated UID request cannot duplicate recovered cargo")

/// Killed owner agents preserve their real memory in one container and do not re-equip lost tools.
/datum/unit_test/netrun_salvage_owned_agent_memory/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/bot/agent = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, "collector")
	var/datum/netrun_file/bot/container = netrun_bot_file("collector")
	agent.agent_file = container
	agent.set_net_name("ARCHIVE-TEST")
	agent.get_persona().tagline = "preserved personality"
	var/datum/netrun_file/cargo = new("recovered.txt", NETRUN_FILE_TEXT, "original cargo", 2)
	TEST_ASSERT(agent.console.store_file(cargo), "The agent has real carried cargo")
	var/list/memory = agent.console.inventory.local_store.files.Copy()
	var/expected_size = agent.program.file_size + agent.console.inventory.local_store.used()
	agent.drop_remains(scene.node_a)
	agent.drop_remains(scene.node_a)
	TEST_ASSERT_EQUAL(length(scene.node_a.salvage), 1, "Repeated death paths leave one agent container")
	TEST_ASSERT_EQUAL(scene.node_a.salvage[1], container, "The existing typed agent file remains the owned container")
	TEST_ASSERT_EQUAL(container.size, expected_size, "The package charges the full real inventory size")
	TEST_ASSERT(cargo in container.stored_files, "Cargo belongs to the fallen agent package")
	TEST_ASSERT_EQUAL(length(container.stored_files), length(memory), "All owned memory transfers into the same package")
	TEST_ASSERT_EQUAL(length(agent.console.inventory.local_store.files), 0, "Packaged files no longer also belong to the live disk")
	agent.dissolve()
	for(var/datum/netrun_file/file as anything in memory)
		TEST_ASSERT(!QDELETED(file) && (file in container.stored_files), "Destroying the process does not destroy its saved memory")
	var/mob/camera/netrun_entity/bot/restored = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_b, "collector")
	scene.node_a.salvage -= container
	scene.node_a.refresh_salvage()
	restored.agent_file = container
	TEST_ASSERT(container.restore_agent(restored), "The normal restoration path accepts the preserved memory")
	TEST_ASSERT(cargo in restored.console.inventory.local_store.files, "Restoration moves the same original cargo back")
	TEST_ASSERT_EQUAL(restored.real_name, "ARCHIVE-TEST", "The fallen agent retains its name")
	TEST_ASSERT_EQUAL(restored.get_persona().tagline, "preserved personality", "The fallen agent retains its personality")
	TEST_ASSERT_EQUAL(length(restored.console.inventory.local_store.files), length(memory), "Restoration replaces spawn defaults rather than minting another loadout")

/// Legacy plain BOT files are upgraded on death; voluntary departures never spill inventory.
/datum/unit_test/netrun_salvage_legacy_and_retirement/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/bot/agent = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, NETRUN_BOT_SENTINEL)
	var/datum/netrun_file/legacy = new("legacy.bot", NETRUN_FILE_BOT, NETRUN_BOT_SENTINEL, agent.program.file_size)
	agent.agent_file = legacy
	var/datum/netrun_file/cargo = new("legacy-cargo.txt", NETRUN_FILE_TEXT, "survives legacy death")
	TEST_ASSERT(agent.console.store_file(cargo), "The legacy agent owns a real cargo file")
	agent.take_integrity(1000, "test")
	var/datum/netrun_file/bot/container = scene.node_a.salvage[1]
	TEST_ASSERT(istype(container) && QDELETED(legacy), "A plain BOT file becomes a real memory-bearing container on death")
	TEST_ASSERT(cargo in container.stored_files, "Legacy conversion preserves its real current memory")
	TEST_ASSERT_EQUAL(container.name, "legacy.bot", "Conversion retains the original file metadata")
	var/mob/camera/netrun_entity/bot/visitor = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_b, NETRUN_BOT_RAIDER)
	var/list/visitor_memory = visitor.console.inventory.local_store.files.Copy()
	visitor.retire()
	TEST_ASSERT_EQUAL(length(scene.node_b.salvage), 0, "A visitor's planned retirement creates no death loot")
	TEST_ASSERT_NULL(SSnetrun.salvage_nodes[scene.node_b.address], "A voluntary departure creates no empty debris index entry")
	for(var/datum/netrun_file/file as anything in visitor_memory)
		TEST_ASSERT(QDELETED(file), "Retirement releases the visitor's memory without minting a reward")

/// Every configured visiting faction, including hackers, leaves its real loadout
/// and already collected cargo when killed rather than disappearing empty.
/datum/unit_test/netrun_salvage_visiting_factions/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	SSnetrun.get_netrun_faction(null)
	for(var/id in SSnetrun.netrun_factions)
		var/datum/netrun_faction/faction = SSnetrun.netrun_factions[id]
		for(var/program_id in faction.visitors)
			var/mob/camera/netrun_entity/bot/visitor = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, program_id)
			var/datum/netrun_file/cargo = new("visitor-cargo.txt", NETRUN_FILE_TEXT, program_id, 2)
			TEST_ASSERT(visitor.console.store_file(cargo), "[program_id] has room for a collected file")
			var/list/memory = visitor.console.inventory.local_store.files.Copy()
			visitor.take_integrity(1000, "test")
			TEST_ASSERT(QDELETED(visitor), "[program_id] is destroyed by ordinary combat damage")
			TEST_ASSERT_EQUAL(length(scene.node_a.salvage), length(memory), "[program_id] leaves actual programs, daemons, keys and collected cargo")
			for(var/datum/netrun_file/file as anything in memory)
				TEST_ASSERT(!QDELETED(file) && (file in scene.node_a.salvage), "[program_id] preserves each original datum and UID")
			QDEL_LIST(scene.node_a.salvage)
			scene.node_a.salvage = list()
			scene.node_a.refresh_salvage()
