/// The controller predicate can change while the same ordinary puzzle is open.
/datum/netrun_console/entity/bot/npc_breach_fixture
	var/player_controlled = FALSE

/datum/netrun_console/entity/bot/npc_breach_fixture/automates_breach_input()
	return !player_controlled && ..()

/// Tests advance the due boundary explicitly, without sleeping a unit-test world.
/datum/unit_test/proc/netrun_complete_npc_breach(datum/netrun_console/console)
	for(var/index in 1 to 32)
		var/datum/netrun_breach/npc/breach = console.intrusion.breach
		if(!breach)
			return TRUE
		if(!istype(breach))
			return FALSE
		breach.next_choice_at = world.time
		console.intrusion.process_tick(0)
	return !console.intrusion.breach

/// Ordinary tools, rewards and legal inputs are shared; only the input is automatic.
/datum/unit_test/netrun_npc_breach_delayed_sequence/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/bot/bot = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, NETRUN_BOT_SENTINEL)
	TEST_ASSERT(!bot.console.daemon_capability("autobreach"), "The fixture has no automatic cracking executable")
	TEST_ASSERT(bot.console.start_breach("node", scene.node_a.address), "An autonomous process may start the ordinary manual puzzle")
	var/datum/netrun_breach/npc/breach = bot.console.intrusion.breach
	TEST_ASSERT(istype(breach), "The factory selects autonomous input for a clientless bot")
	TEST_ASSERT_EQUAL(breach.minigame, "sequence", "The target retains its native minigame")
	TEST_ASSERT(breach.next_choice_at >= world.time + 1 SECONDS, "The first input has a real delay")
	breach.advance_automation()
	breach.advance_automation()
	TEST_ASSERT_EQUAL(breach.progress, 0, "Calling the solver repeatedly cannot skip the first delay")
	TEST_ASSERT(bot.console.node_level(scene.node_a) < NETRUN_ACCESS_ROOT, "Starting a solver cannot grant ROOT")
	breach.next_choice_at = world.time
	bot.console.intrusion.process_tick(0)
	TEST_ASSERT_EQUAL(breach.progress, 1, "A due console task supplies exactly one ordinary choice")
	bot.console.intrusion.process_tick(0)
	TEST_ASSERT_EQUAL(breach.progress, 1, "A second task at the same world time cannot accelerate solving")
	TEST_ASSERT(netrun_complete_npc_breach(bot.console), "The native generated sequence finishes")
	TEST_ASSERT_EQUAL(bot.console.node_level(scene.node_a), NETRUN_ACCESS_ROOT, "The ordinary completed puzzle awards its real ROOT reward")
	TEST_ASSERT_NOTNULL(bot.console.canonical_acquired_key(), "The reward is persisted by the ordinary acquired-key pipeline")

/datum/unit_test/netrun_npc_breach_matrix_and_player/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	scene.node_a.base_security = 5
	var/mob/camera/netrun_entity/bot/bot = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, NETRUN_BOT_SENTINEL)
	TEST_ASSERT(bot.console.start_breach("node", scene.node_a.address), "A protected target starts its normal challenge")
	var/datum/netrun_breach/npc/breach = bot.console.intrusion.breach
	TEST_ASSERT_EQUAL(breach.minigame, "matrix", "High security keeps the matrix challenge")
	TEST_ASSERT(netrun_complete_npc_breach(bot.console), "The generated matrix route remains legal through every ordinary choose")
	TEST_ASSERT_EQUAL(bot.console.node_level(scene.node_a), NETRUN_ACCESS_ROOT, "Matrix rewards go through native final validation")
	var/mob/camera/netrun_entity/player = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	TEST_ASSERT(player.console.start_breach("node", scene.node_a.address), "A player session can start the same target")
	TEST_ASSERT(!istype(player.console.intrusion.breach, /datum/netrun_breach/npc), "A clientless player entity is never mistaken for an autonomous bot")
	TEST_ASSERT_EQUAL(player.console.intrusion.breach.type, /datum/netrun_breach, "The player's ordinary manual puzzle remains manual")

/// Controller takeover, explicit input and disconnection cannot produce delayed grants.
/datum/unit_test/netrun_npc_breach_takeover_and_cancellation/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/bot/bot = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, NETRUN_BOT_SENTINEL)
	var/datum/netrun_console/entity/bot/npc_breach_fixture/console = allocate(/datum/netrun_console/entity/bot/npc_breach_fixture, bot, NETRUN_ORIGIN_ENTITY)
	TEST_ASSERT(console.start_breach("node", scene.node_a.address), "The autonomous controller starts a native puzzle")
	var/datum/netrun_breach/npc/breach = console.intrusion.breach
	console.player_controlled = TRUE
	breach.next_choice_at = world.time
	breach.advance_automation()
	TEST_ASSERT_EQUAL(breach.progress, 0, "Taking control prevents further automated inputs")
	TEST_ASSERT(breach.choose(breach.solution_path[1]), "The new controller may supply an ordinary manual choice")
	console.player_controlled = FALSE
	breach.advance_automation()
	TEST_ASSERT_EQUAL(breach.progress, 1, "The generated route cannot replay over a manually changed puzzle")
	scene.node_a.offline_until = world.time + 1 MINUTES
	console.intrusion.process_tick(0)
	TEST_ASSERT_NULL(console.intrusion.breach, "Native target invalidation cancels the solver")
	TEST_ASSERT(QDELETED(breach), "A cancelled solver cannot retain pending input")
	TEST_ASSERT(console.node_level(scene.node_a) < NETRUN_ACCESS_ROOT, "The cancelled work grants no ROOT")

/// Firmware requires the same existing ROOT, executable and supported native operation.
/datum/unit_test/netrun_npc_breach_firmware/Run()
	var/obj/item/clothing/glasses/hud/health/night/glasses = allocate(/obj/item/clothing/glasses/hud/health/night, run_loc_floor_bottom_left)
	var/datum/component/netrun_node/node = glasses.GetComponent(/datum/component/netrun_node)
	var/mob/camera/netrun_entity/bot/bot = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, node, NETRUN_BOT_SENTINEL)
	TEST_ASSERT(!bot.console.start_breach("firmware", node.address), "Automatic input cannot skip the native ROOT requirement")
	bot.console.access_session.node_access[node.address] = NETRUN_ACCESS_ROOT
	TEST_ASSERT(!bot.console.start_breach("firmware", node.address), "Automatic input cannot conjure the required firmware executable")
	TEST_ASSERT(bot.console.store_file(netrun_daemon_file("icepick")), "The required tool consumes real memory")
	TEST_ASSERT(bot.console.start_breach("firmware", node.address), "An equipped autonomous process starts the real firmware puzzle")
	TEST_ASSERT(!(glasses.obj_flags & EMAGGED), "Starting the solver cannot mutate firmware immediately")
	TEST_ASSERT(netrun_complete_npc_breach(bot.console), "The stricter regenerated firmware matrix remains solvable")
	TEST_ASSERT(glasses.obj_flags & EMAGGED, "Only completion invokes the endpoint's native firmware operation")
