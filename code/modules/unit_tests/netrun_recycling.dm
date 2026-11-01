/// A ready-made station process follows actual debris through recovery, hops and
/// delivered MOVE. It never unloads the files that implement its own behavior.
/datum/unit_test/netrun_recycling_round_trip/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/bot/bot = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, NETRUN_BOT_RECYCLER)
	var/datum/netrun_entity_module/recycling/module = bot.entity_modules["recycling"]
	TEST_ASSERT_NOTNULL(module, "The station profile installs a separate recycling capability")
	TEST_ASSERT(!bot.defense_threat(), "A maintenance process does not provoke station ICE")
	TEST_ASSERT(bot.console.legit_node_level(scene.node_b) >= NETRUN_ACCESS_USER, "The collector can legally use a station server")
	TEST_ASSERT(bot.console.legit_node_level(scene.node_b) < NETRUN_ACCESS_ROOT, "Maintenance does not acquire ROOT")
	scene.node_b.file_store.capacity = 256
	var/list/runtime_files = bot.console.inventory.local_store.files.Copy()
	bot.brain.think()
	TEST_ASSERT(istype(bot.brain.current_goal(), /datum/netrun_bot_goal/recycling_wait), "An idle collector waits without scanning the station")
	var/datum/netrun_file/cargo = new("visitor-debris.txt", NETRUN_FILE_TEXT, "recovered visitor data", 3)
	TEST_ASSERT(scene.node_a.leave_salvage(cargo, "visitor"), "A real death cache owns the original file")
	cargo.salvage_recycle_after = world.time
	TEST_ASSERT_NULL(bot.brain.current_goal(), "A new debris fact interrupts idle waiting")
	bot.brain.think()
	TEST_ASSERT_EQUAL(bot.console.inventory.local_store.find_file(cargo.uid), cargo, "The collector notices debris under itself")
	TEST_ASSERT(cargo.uid in module.cargo_uids, "Only actual recovered cargo is marked for unloading")
	var/datum/netrun_request/file/packet
	for(var/step in 1 to 12)
		bot.next_hop = 0
		bot.brain.think()
		packet = bot.brain.command_packet_ref?.resolve()
		if(packet)
			break
	TEST_ASSERT_EQUAL(bot.host_node, scene.node_b, "The collector physically traverses A-APC-B to the server")
	TEST_ASSERT_NOTNULL(packet, "Unloading owns a real file delivery packet")
	TEST_ASSERT_EQUAL(packet.action, "deposit", "The collector requests MOVE, not COPY upload")
	TEST_ASSERT_EQUAL(bot.console.inventory.local_store.find_file(cargo.uid), cargo, "Dispatch still owns cargo locally")
	TEST_ASSERT(packet.deliver(), "An ordinary legal server accepts the original file")
	bot.brain.think()
	TEST_ASSERT_EQUAL(scene.node_b.file_store.find_file(cargo.uid), cargo, "The actual recovered file now belongs to the server")
	TEST_ASSERT_NULL(bot.console.inventory.local_store.find_file(cargo.uid), "No duplicate remains in the collector")
	TEST_ASSERT_NULL(module.first_cargo(), "Delivered cargo leaves the module's pending work")
	for(var/datum/netrun_file/file as anything in runtime_files)
		TEST_ASSERT_EQUAL(bot.console.inventory.local_store.find_file(file.uid), file, "Runtime programs remain installed")
		TEST_ASSERT_NULL(scene.node_b.file_store.find_file(file.uid), "Installed programs are never treated as collected debris")

/// Full/offline/vault destinations remain unsuitable and cargo survives module
/// cancellation rather than completing a hidden transfer after removal.
/datum/unit_test/netrun_recycling_destination_and_detach/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/bot/bot = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_b, NETRUN_BOT_RECYCLER)
	var/datum/netrun_file/cargo = new("cargo.txt", NETRUN_FILE_TEXT, "cargo", 2)
	scene.node_b.leave_salvage(cargo)
	TEST_ASSERT(bot.console.recover_salvage(cargo.uid), "Cargo enters through normal recovery")
	TEST_ASSERT(!bot.brain.node_accepts_cargo(scene.node_a), "An ordinary terminal is not a recycling server")
	scene.node_b.file_store.capacity = scene.node_b.used_storage()
	TEST_ASSERT(!bot.brain.node_accepts_cargo(scene.node_b), "A full server cannot be selected")
	scene.node_b.file_store.capacity += 16
	scene.node_b.offline_until = world.time + 30 SECONDS
	TEST_ASSERT(!bot.brain.node_accepts_cargo(scene.node_b), "An offline server cannot be selected")
	scene.node_b.offline_until = 0
	var/datum/netrun_console/owner = allocate(/datum/netrun_console, allocate(/obj/item))
	var/datum/netrun_fortress/vault = new(scene.node_b, "Private vault", NETRUN_FACTION_OWNER, owner)
	scene.node_b.fortress = vault
	vault.add_module(NETRUN_FORT_VAULT, TRUE)
	TEST_ASSERT(!bot.brain.node_accepts_cargo(scene.node_b), "A foreign ROOT vault is not writable by station USER")
	QDEL_NULL(scene.node_b.fortress)
	TEST_ASSERT(bot.brain.node_accepts_cargo(scene.node_b), "An online ordinary server with capacity is suitable")
	bot.brain.clear_goals()
	bot.brain.think()
	var/datum/netrun_request/file/packet = bot.brain.command_packet_ref?.resolve()
	TEST_ASSERT_NOTNULL(packet, "The unload goal has an in-flight packet")
	TEST_ASSERT(bot.remove_module("recycling"), "The optional maintenance behavior may be removed")
	TEST_ASSERT(QDELETED(packet), "Removing the module cancels its in-flight file operation")
	TEST_ASSERT_EQUAL(bot.console.inventory.local_store.find_file(cargo.uid), cargo, "Cancellation retains recovered cargo")
	TEST_ASSERT_NULL(scene.node_b.file_store.find_file(cargo.uid), "Cancelled work never leaves a server copy")

/// Fresh loot belongs to the winner's opportunity window before maintenance plans recovery.
/datum/unit_test/netrun_recycling_loot_grace/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/bot/bot = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, NETRUN_BOT_RECYCLER)
	var/datum/netrun_file/cargo = new("fresh-debris.txt", NETRUN_FILE_TEXT, "earned loot", 2)
	TEST_ASSERT(scene.node_a.leave_salvage(cargo, "defeated process"), "Defeat leaves a real file")
	TEST_ASSERT_EQUAL(cargo.salvage_recycle_after, world.time + NETRUN_SALVAGE_RECYCLE_GRACE, "Each fresh drop gets its own grace deadline")
	// Other tests may leave indexed caches. This assertion concerns the deadline
	// of the only debris cache visible to this fixture's bounded search.
	var/list/previous_caches = SSnetrun.salvage_nodes
	SSnetrun.salvage_nodes = list()
	SSnetrun.salvage_nodes[scene.node_a.address] = scene.node_a
	bot.program.plan(bot.brain)
	SSnetrun.salvage_nodes = previous_caches
	var/datum/netrun_bot_goal/recycling_wait/wait = bot.brain.current_goal()
	TEST_ASSERT(istype(wait), "A recycler waits rather than taking fresh loot")
	TEST_ASSERT_EQUAL(wait.expires_at, cargo.salvage_recycle_after, "Waiting wakes at the grace deadline without polling")
	TEST_ASSERT_NULL(bot.brain.best_salvage(scene.node_a), "Autonomous recovery still respects the opportunity window")
	var/mob/camera/netrun_entity/player = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	TEST_ASSERT(player.console.recover_salvage(cargo.uid), "The player can recover the original during the grace window")
	TEST_ASSERT_EQUAL(player.console.inventory.local_store.find_file(cargo.uid), cargo, "Recovery gives the player the original file")
	var/datum/netrun_file/older = new("older-debris.txt", NETRUN_FILE_TEXT, "unclaimed loot", 2)
	scene.node_a.leave_salvage(older)
	older.salvage_recycle_after = world.time
	TEST_ASSERT_EQUAL(bot.brain.best_salvage(scene.node_a), older, "Unclaimed loot becomes available after its grace deadline")

/// Shared legacy collectors also recognize salvage at their current location.
/datum/unit_test/netrun_recycling_local_visitors/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	for(var/id in list("scavenger", "collector", NETRUN_BOT_RAIDER, "archive_collector"))
		var/mob/camera/netrun_entity/bot/bot = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, id)
		// Test local collection independently of a visitor's initial access acquisition.
		bot.brain.clear_goals()
		var/datum/netrun_file/file = new("local-debris.txt", NETRUN_FILE_TEXT, id)
		scene.node_a.leave_salvage(file)
		bot.program.plan(bot.brain)
		TEST_ASSERT(istype(bot.brain.current_goal(), /datum/netrun_bot_goal/salvage), "[id] chooses debris in its current node")
		bot.brain.current_goal().advance()
		TEST_ASSERT_EQUAL(bot.console.inventory.local_store.find_file(file.uid), file, "[id] recovers the original file")
		qdel(bot)

/// Native housekeeping installs ready station collectors and replaces a killed
/// one only after its maintenance cooldown, within the common process budget.
/datum/unit_test/netrun_bot_round_population/recyclers/Run()
	original_state = list()
	for(var/field in list("bots", "bots_enabled", "next_bot_census", "rogue_wave_at", "police_respawn_at", "custodian_respawn_at", "recycler_respawn_at", "bot_spawn_pools", "bot_spawn_revision", "bot_spawn_index_builds", "bot_spawn_candidate_checks"))
		original_state[field] = SSnetrun.vars[field]
	SSnetrun.bots = list()
	SSnetrun.bots_enabled = TRUE
	SSnetrun.police_respawn_at = INFINITY
	SSnetrun.custodian_respawn_at = INFINITY
	SSnetrun.rogue_wave_at = INFINITY
	SSnetrun.recycler_respawn_at = world.time
	allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	census_scheduler = allocate(/datum/netrun_task_scheduler, SSnetrun.get_execution_limits())
	for(var/index in 1 to NETRUN_RECYCLER_QUOTA + 1)
		census()
	TEST_ASSERT_EQUAL(SSnetrun.count_bots(NETRUN_BOT_RECYCLER), NETRUN_RECYCLER_QUOTA, "Round housekeeping fills the station recycler quota and stops")
	var/mob/camera/netrun_entity/bot/lost = SSnetrun.bots[1]
	var/datum/component/netrun_node/node = lost.host_node
	lost.take_integrity(1000, "test")
	TEST_ASSERT(length(node.salvage), "A destroyed station collector leaves its actual files")
	TEST_ASSERT(SSnetrun.recycler_respawn_at >= world.time + 4 MINUTES, "Loss applies a maintenance replacement delay")
	census()
	TEST_ASSERT_EQUAL(SSnetrun.count_bots(NETRUN_BOT_RECYCLER), NETRUN_RECYCLER_QUOTA - 1, "A census cannot immediately replace killed collectors for unlimited loot")
	SSnetrun.recycler_respawn_at = world.time
	census()
	TEST_ASSERT_EQUAL(SSnetrun.count_bots(NETRUN_BOT_RECYCLER), NETRUN_RECYCLER_QUOTA, "A later maintenance census restores the configured population")

/// Waiting away from home sleeps until its own deadline. Expiry replans the
/// maintenance policy; disabling it cannot keep unloading through program.plan.
/datum/unit_test/netrun_recycling_idle_and_disable/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/bot/bot = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, NETRUN_BOT_RECYCLER)
	bot.enter_node(scene.node_b)
	bot.brain.clear_goals()
	bot.brain.think()
	var/datum/netrun_bot_goal/recycling_wait/wait = bot.brain.current_goal()
	TEST_ASSERT(istype(wait), "An empty network gives maintenance a sleeping goal")
	TEST_ASSERT_EQUAL(wait.post_ref?.resolve(), scene.node_b, "Waiting belongs to the current node, not the original spawn")
	bot.brain.schedule_next()
	TEST_ASSERT_EQUAL(timeleft(bot.brain.timer_id), wait.expires_at - world.time, "A wait away from home sleeps until expiry instead of think_busy polling")
	wait.expires_at = world.time - 1
	bot.brain.think()
	wait = bot.brain.current_goal()
	TEST_ASSERT(istype(wait), "Expiry re-enters maintenance policy instead of starting an unrelated patrol")
	var/datum/netrun_entity_module/recycling/module = bot.entity_modules["recycling"]
	module.enabled = FALSE
	var/datum/netrun_file/file = new("disabled.txt", NETRUN_FILE_TEXT, "debris")
	scene.node_b.leave_salvage(file)
	TEST_ASSERT_EQUAL(bot.brain.current_goal(), wait, "Disabled modules do not interrupt goals from their signal handler")
	bot.brain.clear_goals()
	bot.program.plan(bot.brain)
	TEST_ASSERT(!istype(bot.brain.current_goal(), /datum/netrun_bot_goal/salvage), "program.plan respects the installed module's enabled state")
	TEST_ASSERT(file in scene.node_b.salvage, "A disabled collector has not acquired or copied debris")
