/// A raised guard has one quiet deadline, then retains its nest without periodic AI.
/datum/unit_test/netrun_reactive_guard_lifecycle/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/datum/component/netrun_node/node = scene.node_b
	node.base_security = 3
	SSnetrun.raise_defenses(null, node)
	TEST_ASSERT_EQUAL(length(node.netrun_ice), 1, "An illegal action raises one guard on the hardened node")
	var/datum/netrun_ice/guard = node.netrun_ice[1]
	TEST_ASSERT(guard.reactive && !guard.drops_loot, "Raised guards use dormant nests and cannot be farmed for executables")
	SSnetrun.get_task_scheduler().cancel("ice", guard)
	guard.reaction.schedule_next()
	TEST_ASSERT(guard.reaction.timer_id && guard.reaction.deadline == guard.reactive_sleep_at, "Quiet active guards own one expiry deadline instead of repeated polls")
	guard.integrity = 37
	guard.program_cd["strike"] = world.time + 1 MINUTES
	guard.reactive_sleep_at = world.time
	guard.process_ai(0)
	guard.reaction.schedule_next()
	TEST_ASSERT(guard.dormant && !guard.needs_netrun_tick(), "A quiet nest releases ordinary worker population")
	TEST_ASSERT(!guard.reaction.timer_id, "Dormant guards own no polling timer")
	var/mob/camera/netrun_entity/intruder = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	intruder.enter_node(node)
	TEST_ASSERT(!guard.dormant, "An actual arrival wakes the resident nest immediately")
	TEST_ASSERT_EQUAL(guard.integrity, 37, "Waking the same guard does not heal it")
	TEST_ASSERT_EQUAL(guard.program_cd["strike"], world.time + 1 MINUTES, "Waking cannot reset combat cooldowns")
	SSnetrun.get_task_scheduler().cancel("ice", guard)
	guard.process_ai(0)
	TEST_ASSERT(!guard.dormant && guard.reactive_sleep_at > world.time, "A hostile local process keeps the nest active")
	TEST_ASSERT_NOTNULL(guard.pending_program, "The wounded guard prepares its ordinary defensive program")
	intruder.enter_node(scene.node_a)
	guard.attack_at = world.time
	var/datum/controller/subsystem/netrun/netrun_execution_test/worker = allocate(/datum/controller/subsystem/netrun/netrun_execution_test)
	worker.next_task_population = INFINITY
	worker.get_task_scheduler().enqueue("ice", guard, NETRUN_TASK_NORMAL)
	worker.run_pass()
	TEST_ASSERT(!guard.pending_program && guard.reaction.timer_id, "Completing the last program in normal population still arms the quiet deadline")
	guard.reactive_sleep_at = world.time
	guard.process_ai(0)
	guard.reaction.schedule_next()
	TEST_ASSERT(guard.dormant && !guard.reaction.timer_id, "After the threat leaves, the same nest sleeps again")
	var/salvage_before = length(node.salvage)
	guard.destroyed(null)
	TEST_ASSERT_EQUAL(length(node.salvage), salvage_before, "Defeating a reactive nest produces no renewable salvage")
	SSnetrun.raise_defenses(null, node)
	TEST_ASSERT_EQUAL(length(node.netrun_ice), 0, "Another intrusion cannot respawn the defeated nest on this node")
	var/datum/netrun_ice/ordinary = allocate(/datum/netrun_ice, node, NETRUN_ICE_SENTRY)
	ordinary.process_ai(0)
	TEST_ASSERT(!ordinary.reactive && !ordinary.dormant && ordinary.drops_loot, "Explicit guards retain their existing lifecycle and rewards")

/// An active remote breach is also a real wake interest, even without a local body.
/datum/unit_test/netrun_reactive_guard_breach/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	scene.node_b.base_security = 3
	SSnetrun.raise_defenses(null, scene.node_b)
	var/datum/netrun_ice/guard = scene.node_b.netrun_ice[1]
	SSnetrun.get_task_scheduler().cancel("ice", guard)
	guard.reactive_sleep_at = world.time
	guard.process_ai(0)
	var/mob/camera/netrun_entity/intruder = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	TEST_ASSERT(intruder.console.store_file(scene.key_file()), "The remote process has an ordinary route to the target")
	TEST_ASSERT(intruder.console.start_breach("node", scene.node_b.address), "A native remote breach starts against the guarded node")
	TEST_ASSERT(!guard.dormant && guard.has_reactive_threat(), "Breach intent wakes the local guard and retains its real target")
	SSnetrun.get_task_scheduler().cancel("ice", guard)
	qdel(intruder.console.intrusion.breach)
	TEST_ASSERT(!guard.valid_trace_target(intruder.console), "A deleted breach retained by the session is no longer an attack target")
	guard.cancel_program()
	guard.reactive_sleep_at = world.time
	guard.process_ai(0)
	guard.reaction.schedule_next()
	TEST_ASSERT(guard.dormant && !guard.reaction.timer_id, "Cancelling the last remote breach permits quiet sleep")

/obj/machinery/netrun_server/netrun_archive_preload_test
	preload_daemons = list("buffer", "extend", "scrub")

/// Native registration defers seeding, respects preloads and remembers the physical host.
/datum/unit_test/netrun_server_archive_once
	var/previous_content_enabled = NETRUN_AUTONOMOUS_CONTENT

/datum/unit_test/netrun_server_archive_once/Destroy()
	SSnetrun.server_content_enabled = previous_content_enabled
	return ..()

/datum/unit_test/netrun_server_archive_once/Run()
	previous_content_enabled = SSnetrun.server_content_enabled
	SSnetrun.server_content_enabled = TRUE
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	TEST_ASSERT_NULL(scene.node_b.parent.GetComponent(/datum/component/netrun_server_archive), "A bare server-shaped endpoint receives no machine loot")
	var/obj/machinery/netrun_server/server = scene.machine(/obj/machinery/netrun_server/netrun_archive_preload_test, get_step(run_loc_floor_bottom_left, EAST))
	var/datum/component/netrun_node/node = server.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_server_archive/archive = server.GetComponent(/datum/component/netrun_server_archive)
	var/expected_capacity = 80 * NETRUN_STORAGE_SCALE
	for(var/obj/item/stock_parts/matter_bin/bin in server.component_parts)
		expected_capacity += bin.rating * 10 * NETRUN_STORAGE_SCALE
	TEST_ASSERT_EQUAL(node.file_store.capacity, expected_capacity, "The real data server has enlarged base memory and retains stock-part upgrades")
	TEST_ASSERT_NOTNULL(archive, "Real server registration admits exactly one physical-host archive")
	TEST_ASSERT(!archive.seeded, "Authored Initialize preloads finish before the archive task runs")
	var/initial_files = length(node.file_store.files)
	SSnetrun.get_task_scheduler().cancel("server.content", archive)
	var/datum/controller/subsystem/netrun/netrun_execution_test/worker = allocate(/datum/controller/subsystem/netrun/netrun_execution_test)
	worker.next_task_population = INFINITY
	worker.get_task_scheduler().enqueue("server.content", archive, NETRUN_TASK_BACKGROUND)
	worker.run_pass()
	TEST_ASSERT(archive.seeded && archive.inserted == 1, "The ordinary worker adds one useful program without duplicating the full daemon preload")
	TEST_ASSERT_EQUAL(length(node.file_store.files), initial_files + 1, "The bounded archive preserves all authored files")
	TEST_ASSERT(node.used_storage() <= node.file_store.capacity, "Generated files obey writable memory capacity")
	node.file_store.clear()
	TEST_ASSERT(!archive.seed() && !length(node.file_store.files), "Emptying the disk cannot regenerate its rewards")
	qdel(node)
	node = server.AddComponent(/datum/component/netrun_node, NETRUN_NODE_SERVER)
	TEST_ASSERT_EQUAL(server.GetComponent(/datum/component/netrun_server_archive), archive, "Replacing the address preserves the physical carrier's seed record")
	TEST_ASSERT(!archive.seed(), "Re-registering a live carrier cannot mint another archive")
	TEST_ASSERT_EQUAL(length(node.file_store.files), 1, "A replacement node gets its firmware manual, without a fresh loot payload")

/// Even zero-capacity and already overfull disks are never bypassed or retried later.
/datum/unit_test/netrun_server_archive_capacity
	var/previous_content_enabled = NETRUN_AUTONOMOUS_CONTENT

/datum/unit_test/netrun_server_archive_capacity/Destroy()
	SSnetrun.server_content_enabled = previous_content_enabled
	return ..()

/datum/unit_test/netrun_server_archive_capacity/Run()
	previous_content_enabled = SSnetrun.server_content_enabled
	SSnetrun.server_content_enabled = TRUE
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/obj/machinery/netrun_server/server = scene.machine(/obj/machinery/netrun_server, get_step(run_loc_floor_bottom_left, EAST))
	var/datum/component/netrun_node/node = server.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_server_archive/archive = server.GetComponent(/datum/component/netrun_server_archive)
	SSnetrun.get_task_scheduler().cancel("server.content", archive)
	node.file_store.capacity = 0
	TEST_ASSERT(archive.seed(), "A full archive still commits its one generation attempt")
	TEST_ASSERT_EQUAL(archive.inserted, 0, "Content generation never forces an over-capacity insert")
	TEST_ASSERT_EQUAL(node.used_storage(), 0, "Only the zero-sized built-in manual remains")
	node.file_store.capacity = 100
	TEST_ASSERT(!archive.seed() && !archive.inserted, "Freeing storage after generation does not turn the server into a dispenser")
	var/datum/component/netrun_server_archive/pending = archive
	SSnetrun.get_task_scheduler().enqueue("server.content", pending, NETRUN_TASK_BACKGROUND)
	var/task_key = "server.content:[REF(pending)]"
	qdel(server)
	TEST_ASSERT(QDELETED(pending) && !SSnetrun.get_task_scheduler().by_key[task_key], "Carrier deletion releases the archive and cancels its queued work")

/// An independently registered profile needs no changes to seeding or machine dispatch.
/datum/netrun_server_content_profile/unit_test_archive
	id = "unit-test-archive"
	programs = list("patch" = 1)
	daemons = list("buffer" = 1)
	advanced_daemons = list("ghostlink" = 1)
	advanced_security = 4

/obj/machinery/netrun_server/netrun_archive_profile_test/netrun_server_content_profile()
	return "unit-test-archive"

/obj/machinery/netrun_server/netrun_archive_profile_test/preloaded
	preload_daemons = list("buffer")

/obj/machinery/netrun_server/netrun_archive_profile_test/hardened
	server_security = 4

/datum/unit_test/netrun_server_archive_profile_extension
	var/previous_content_enabled = NETRUN_AUTONOMOUS_CONTENT

/datum/unit_test/netrun_server_archive_profile_extension/Destroy()
	SSnetrun.server_content_enabled = previous_content_enabled
	return ..()

/datum/unit_test/netrun_server_archive_profile_extension/Run()
	previous_content_enabled = SSnetrun.server_content_enabled
	SSnetrun.server_content_enabled = TRUE
	var/datum/netrun_server_content_profile/definition = SSnetrun.get_server_content_profile(" UNIT-TEST-ARCHIVE ")
	TEST_ASSERT_NOTNULL(definition, "An independent profile subtype is discovered and its ID normalized")
	TEST_ASSERT_NULL(SSnetrun.get_server_content_profile("missing-archive"), "An unknown profile cannot silently generate an ordinary archive")
	var/list/programs = definition.programs.Copy()
	var/list/daemons = definition.daemons.Copy()
	var/list/advanced = definition.advanced_daemons.Copy()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/obj/machinery/netrun_server/first = scene.machine(/obj/machinery/netrun_server/netrun_archive_profile_test/preloaded, get_step(run_loc_floor_bottom_left, EAST))
	var/obj/machinery/netrun_server/second = scene.machine(/obj/machinery/netrun_server/netrun_archive_profile_test/hardened, run_loc_floor_bottom_left)
	var/datum/component/netrun_server_archive/first_archive = first.GetComponent(/datum/component/netrun_server_archive)
	var/datum/component/netrun_server_archive/second_archive = second.GetComponent(/datum/component/netrun_server_archive)
	TEST_ASSERT(first_archive && second_archive && first_archive != second_archive, "The inherited carrier hook registers a separate seed record on each physical server")
	SSnetrun.get_task_scheduler().cancel("server.content", first_archive)
	SSnetrun.get_task_scheduler().cancel("server.content", second_archive)
	TEST_ASSERT(first_archive.seed() && second_archive.seed(), "Both carriers seed through the ordinary archive pipeline")
	TEST_ASSERT_EQUAL(first_archive.inserted, 1, "An authored daemon is preserved without duplication and a weak server gets no advanced daemon")
	TEST_ASSERT_EQUAL(second_archive.inserted, 3, "The next server receives all independent pools including its eligible advanced daemon")
	TEST_ASSERT(netrun_snapshot_equal(programs, definition.programs) && netrun_snapshot_equal(daemons, definition.daemons) && netrun_snapshot_equal(advanced, definition.advanced_daemons), "Filtering authored IDs and choosing loot never mutates shared weighted pools")
	var/datum/component/netrun_node/first_node = first.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/second_node = second.GetComponent(/datum/component/netrun_node)
	var/datum/netrun_file/first_program
	var/datum/netrun_file/second_program
	var/list/second_executables = list()
	for(var/datum/netrun_file/file as anything in first_node.file_store.files)
		if(file.kind == NETRUN_FILE_PROGRAM)
			first_program = file
	for(var/datum/netrun_file/file as anything in second_node.file_store.files)
		if(file.kind in list(NETRUN_FILE_PROGRAM, NETRUN_FILE_DAEMON))
			second_executables |= file.content
		if(file.kind == NETRUN_FILE_PROGRAM)
			second_program = file
	TEST_ASSERT(first_program && second_program && first_program != second_program, "Servers own distinct actual files rather than files retained by the profile")
	TEST_ASSERT(("patch" in second_executables) && ("buffer" in second_executables) && ("ghostlink" in second_executables), "The custom profile controls actual executable selection")
	first_node.file_store.clear()
	TEST_ASSERT(!first_archive.seed() && !length(first_node.file_store.files), "An extension cannot refill its already seeded disk")

/// Advanced stock retains the authored stash threshold and intact vault alternative.
/datum/unit_test/netrun_server_archive_advanced_policy/Run()
	var/datum/component/netrun_node/node = netrun_fortress_node()
	var/datum/netrun_server_content_profile/data = SSnetrun.get_server_content_profile("data")
	var/datum/netrun_server_content_profile/stash = SSnetrun.get_server_content_profile("stash")
	node.base_security = 5
	TEST_ASSERT(!data.allows_advanced(node), "A high-security ordinary server alone does not reveal advanced stock")
	node.base_security = 3
	TEST_ASSERT(!stash.allows_advanced(node), "A stash below the authored security threshold has no advanced stock")
	node.base_security = 4
	TEST_ASSERT(stash.allows_advanced(node), "An authored hardened stash still unlocks advanced stock")
	node.base_security = 1
	var/datum/netrun_fortress/fortress = new(node, "Archive policy test", NETRUN_FACTION_STATION)
	node.fortress = fortress
	var/datum/netrun_fortress_module/vault = fortress.add_module(NETRUN_FORT_VAULT, TRUE)
	TEST_ASSERT(data.allows_advanced(node) && stash.allows_advanced(node), "An intact vault admits advanced stock independently of server profile and base security")
	vault.take_damage(10000, "test", null)
	TEST_ASSERT(!data.allows_advanced(node) && !stash.allows_advanced(node), "A destroyed vault does not unlock advanced stock")
