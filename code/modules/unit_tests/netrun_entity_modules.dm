/// Probes exercise the public extension contract, not a special dispatch path.
/mob/camera/netrun_entity/module_fixture
	var/list/module_events = list()
	var/list/module_configuration
	var/module_signal_count = 0

/mob/camera/netrun_entity/module_fixture/entity_module_types()
	return islist(module_configuration) ? module_configuration : ..()

/datum/netrun_entity_module/module_probe
	id = "probe_first"
	priority = 60
	requires = list("console")
	var/demand = FALSE

/datum/netrun_entity_module/module_probe/proc/record(event)
	var/mob/camera/netrun_entity/module_fixture/fixture = owner
	fixture.module_events += event

/datum/netrun_entity_module/module_probe/on_remove()
	record("remove:[id]")

/datum/netrun_entity_module/module_probe/process_tick(delta)
	record(id)

/datum/netrun_entity_module/module_probe/needs_processing()
	return demand

/datum/netrun_entity_module/module_probe/handle_action(action, list/params, mob/user)
	if(action != "module_probe")
		return FALSE
	record(id)
	return TRUE

/datum/netrun_entity_module/module_probe/behavior_step(datum/netrun_bot_brain/brain)
	record(id)
	return TRUE

/datum/netrun_entity_module/module_probe/second
	id = "probe_second"
	priority = 70

/datum/netrun_entity_module/module_probe/late
	id = "probe_late"
	priority = 65

/datum/netrun_entity_module/module_probe/dependent
	id = "probe_dependent"
	priority = 75
	requires = list("probe_first")

/datum/netrun_entity_module/module_probe/missing
	id = "probe_missing"
	requires = list("no_such_capability")

/datum/netrun_entity_module/module_probe/mutator
	id = "probe_mutator"
	priority = 55
	var/mutated = FALSE

/datum/netrun_entity_module/module_probe/mutator/process_tick(delta)
	record(id)
	if(mutated)
		return
	mutated = TRUE
	owner.remove_module("probe_second")
	owner.install_module(/datum/netrun_entity_module/module_probe/late)

/datum/netrun_entity_module/module_probe/signals
	id = "probe_signals"

/datum/netrun_entity_module/module_probe/signals/on_install()
	return listen(owner, "netrun_module_probe_fact", PROC_REF(on_fact))

/datum/netrun_entity_module/module_probe/signals/proc/on_fact(datum/source)
	SIGNAL_HANDLER
	var/mob/camera/netrun_entity/module_fixture/fixture = owner
	fixture.module_signal_count++

/datum/netrun_entity_module/module_probe/signals/failed
	id = "probe_failed"

/datum/netrun_entity_module/module_probe/signals/failed/on_install()
	..()
	return FALSE

/// Players and autonomous archetypes compose the same resources and public aliases.
/datum/unit_test/netrun_entity_modules_shared/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	var/mob/camera/netrun_entity/bot/bot = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, NETRUN_BOT_SENTINEL)
	for(var/id in list("identity", "console", "navigation", "vitals", "dive"))
		var/datum/netrun_entity_module/player_module = entity.entity_modules[id]
		var/datum/netrun_entity_module/bot_module = bot.entity_modules[id]
		TEST_ASSERT_NOTNULL(player_module, "The player has common capability [id]")
		TEST_ASSERT_NOTNULL(bot_module, "The bot has common capability [id]")
		TEST_ASSERT(player_module != bot_module, "Capabilities are owned per entity")
		TEST_ASSERT_EQUAL(player_module.owner, entity, "The player capability owns its player")
		TEST_ASSERT_EQUAL(bot_module.owner, bot, "The bot capability owns its bot")
	var/datum/netrun_entity_module/console/player_console = entity.entity_modules["console"]
	var/datum/netrun_entity_module/navigation/player_navigation = entity.entity_modules["navigation"]
	var/datum/netrun_entity_module/navigation/bot/bot_navigation = bot.entity_modules["navigation"]
	var/datum/netrun_entity_module/dive/player_dive = entity.entity_modules["dive"]
	TEST_ASSERT_EQUAL(entity.console, player_console.client_console, "The public console aliases its capability resource")
	TEST_ASSERT_EQUAL(entity.navigation, player_navigation.navigation, "The public navigation aliases its capability resource")
	TEST_ASSERT_EQUAL(entity.dive_link, player_dive.link, "The public dive aliases its capability resource")
	TEST_ASSERT(istype(bot_navigation), "The bot selects its navigation capability declaratively")
	TEST_ASSERT_EQUAL(bot.navigation, bot_navigation.navigation, "Bots do not recreate navigation outside the capability")
	TEST_ASSERT(istype(bot.navigation, /datum/netrun_entity_navigation/bot), "The selected capability supplies bot navigation")
	TEST_ASSERT_NOTNULL(bot.brain, "Behavior reactions resolve a brain initialized after common resources")
	TEST_ASSERT_NULL(bot.GetComponent(/datum/component/neural_interface), "Autonomous agents allocate no idle HUD monitors or display endpoint")
	TEST_ASSERT_NOTNULL(entity.GetComponent(/datum/component/netrun_neural_feedback), "Players retain their optional neural presentation capability")
	for(var/id in list("bot_lifecycle", "bot_stun", "bot_combat", "bot_return_wait", "bot_goals"))
		var/datum/netrun_entity_module/module = bot.entity_modules[id]
		TEST_ASSERT_NOTNULL(module, "The archetype supplies behavior [id]")
		TEST_ASSERT(!module.behavior_step(null), "Bot behavior ignores a missing brain")
	TEST_ASSERT(!bot.entity_modules["bot_watch"], "An archetype without a watcher does not gain that capability")
	entity.integrity = entity.max_integrity - 10
	entity.process_modules(1)
	TEST_ASSERT(entity.integrity > entity.max_integrity - 10, "Common vitals preserve native self repair")
	TEST_ASSERT_EQUAL(bot.integrity, bot.max_integrity, "One owner's clock does not mutate another entity")

/// Stable ordering is reused across passes; the first handler owns an action.
/datum/unit_test/netrun_entity_modules_order/Run()
	var/mob/camera/netrun_entity/module_fixture/entity = allocate(/mob/camera/netrun_entity/module_fixture)
	var/datum/netrun_entity_module/module_probe/second = entity.install_module(/datum/netrun_entity_module/module_probe/second)
	var/datum/netrun_entity_module/module_probe/first = entity.install_module(/datum/netrun_entity_module/module_probe)
	TEST_ASSERT(first && second, "Capabilities can be added to a running player")
	var/list/ordered = entity.entity_module_order
	entity.process_modules(1)
	entity.process_modules(1)
	TEST_ASSERT_EQUAL(jointext(entity.module_events, ","), "probe_first,probe_second,probe_first,probe_second", "Priority, rather than installation order, controls processing")
	TEST_ASSERT_EQUAL(entity.entity_module_order, ordered, "Processing does not copy or rebuild the cached dispatch list")
	entity.module_events.Cut()
	first.enabled = FALSE
	entity.process_modules(1)
	TEST_ASSERT_EQUAL(jointext(entity.module_events, ","), "probe_second", "Disabled modules are skipped")
	first.enabled = TRUE
	first.demand = TRUE
	TEST_ASSERT(entity.modules_need_processing(), "An installed capability can request its own clock")
	entity.module_events.Cut()
	TEST_ASSERT(entity.dispatch_module_action("module_probe", list(), entity), "Runtime capabilities handle actions through the shared facade")
	TEST_ASSERT_EQUAL(jointext(entity.module_events, ","), "probe_first", "The first action handler prevents another action in the same dispatch")
	entity.module_events.Cut()
	TEST_ASSERT(entity.process_behavior(null), "Extensions can supply behavior through the same ordered facade")
	TEST_ASSERT_EQUAL(jointext(entity.module_events, ","), "probe_first", "Only the first behavior handler acts")

/// A callback may remove and install capabilities without corrupting its active pass.
/datum/unit_test/netrun_entity_modules_mutation/Run()
	var/mob/camera/netrun_entity/module_fixture/entity = allocate(/mob/camera/netrun_entity/module_fixture)
	entity.install_module(/datum/netrun_entity_module/module_probe)
	var/datum/netrun_entity_module/second = entity.install_module(/datum/netrun_entity_module/module_probe/second)
	entity.install_module(/datum/netrun_entity_module/module_probe/mutator)
	var/list/ordered = entity.entity_module_order
	entity.process_modules(1)
	TEST_ASSERT_EQUAL(jointext(entity.module_events, ","), "probe_mutator,remove:probe_second,probe_first", "A removed module is skipped and a newly installed module waits for the next pass")
	TEST_ASSERT(QDELETED(second), "Removal releases the previous capability")
	TEST_ASSERT(entity.entity_module_order != ordered, "Mutations publish a replacement ordered list")
	entity.module_events.Cut()
	entity.process_modules(1)
	TEST_ASSERT_EQUAL(jointext(entity.module_events, ","), "probe_mutator,probe_first,probe_late", "The replacement list includes the new capability in priority order")

/// Dependencies block unsafe removal and failed assembly preserves existing resources.
/datum/unit_test/netrun_entity_modules_dependencies/Run()
	var/mob/camera/netrun_entity/module_fixture/entity = allocate(/mob/camera/netrun_entity/module_fixture)
	var/datum/netrun_console/entity/console = entity.console
	TEST_ASSERT_NULL(entity.install_module(/datum/netrun_entity_module/module_probe/missing), "A missing dependency prevents installation")
	entity.module_configuration = list(/datum/netrun_entity_module/module_probe/dependent, /datum/netrun_entity_module/module_probe)
	TEST_ASSERT(entity.assemble_modules(), "Assembly resolves dependencies even when their types are authored in reverse order")
	var/events_before_duplicate = length(entity.module_events)
	TEST_ASSERT_NULL(entity.install_module(/datum/netrun_entity_module/module_probe), "Duplicate capability IDs are rejected")
	TEST_ASSERT_EQUAL(length(entity.module_events), events_before_duplicate, "A discarded factory candidate never runs the resource cleanup hook")
	TEST_ASSERT(entity.assemble_modules(), "Reassembly reuses compatible installed capabilities")
	TEST_ASSERT_EQUAL(length(entity.module_events), events_before_duplicate, "Reassembly discards unused candidates without resource cleanup")
	TEST_ASSERT(!entity.remove_module("probe_first"), "An installed dependent protects its requirement")
	TEST_ASSERT(entity.remove_module("probe_dependent"), "A leaf capability can be removed")
	TEST_ASSERT(entity.remove_module("probe_first"), "A requirement can be removed after its dependents")
	entity.module_configuration = list(/datum/netrun_entity_module/module_probe, /datum/netrun_entity_module/module_probe/missing)
	TEST_ASSERT(!entity.assemble_modules(), "An unresolvable assembly fails")
	TEST_ASSERT(!entity.entity_modules["probe_first"], "Failed assembly rolls back capabilities it added")
	TEST_ASSERT_EQUAL(entity.console, console, "Rollback preserves pre-existing resource aliases")
	TEST_ASSERT(!QDELETED(console), "Rollback does not destroy pre-existing resources")

/// Reverse teardown releases resources/actions and supports a fresh installation.
/datum/unit_test/netrun_entity_modules_cleanup/Run()
	var/mob/camera/netrun_entity/module_fixture/entity = allocate(/mob/camera/netrun_entity/module_fixture)
	var/datum/netrun_persona/persona = entity.get_persona()
	var/datum/netrun_console/entity/console = entity.console
	var/datum/netrun_entity_navigation/navigation = entity.navigation
	var/datum/netrun_dive_link/dive = entity.dive_link
	var/datum/action/innate/netrun_console/console_action = entity.console_action
	var/datum/action/innate/netrun_rename/rename_action = entity.rename_action
	entity.install_module(/datum/netrun_entity_module/module_probe)
	entity.install_module(/datum/netrun_entity_module/module_probe/second)
	entity.destroy_modules()
	TEST_ASSERT_EQUAL(jointext(entity.module_events, ","), "remove:probe_second,remove:probe_first", "Teardown removes capabilities in reverse priority order")
	TEST_ASSERT(!length(entity.entity_modules) && !length(entity.entity_module_order), "Teardown clears both indexes")
	TEST_ASSERT(!entity.console && !entity.navigation && !entity.dive_link && !entity.persona && !entity.console_action && !entity.rename_action, "Teardown clears public aliases")
	TEST_ASSERT(QDELETED(console) && QDELETED(navigation) && QDELETED(dive), "Owned capability resources are destroyed")
	TEST_ASSERT(QDELETED(console_action) && QDELETED(rename_action), "Owned innate actions are destroyed")
	TEST_ASSERT(QDELETED(persona), "A resident-owned identity is released")
	TEST_ASSERT(entity.assemble_modules(), "Default capabilities can be installed again at runtime")
	TEST_ASSERT(entity.console && entity.navigation && entity.dive_link, "Reinstallation restores the native aliases")
	TEST_ASSERT(entity.console != console && entity.navigation != navigation && entity.dive_link != dive, "Reinstallation creates independent live resources")
	TEST_ASSERT_NOTNULL(entity.GetComponent(/datum/component/netrun_neural_feedback), "Console reinstallation restores its neural feedback binding")
	var/mob/living/carbon/human/body = allocate(/mob/living/carbon/human)
	body.mind_initialize()
	var/datum/mind/identity = body.mind
	identity.transfer_to(entity)
	var/datum/netrun_persona/persistent = entity.get_persona()
	entity.destroy_modules()
	TEST_ASSERT(!QDELETED(persistent), "Removing identity does not delete a mind-owned presentation profile")
	TEST_ASSERT_EQUAL(identity.netrun_persona, persistent, "The identity keeps its presentation across capability removal")
	identity.transfer_to(body)

/// Reactions have module ownership, and goal facts produced during behavior do not self-wake.
/datum/unit_test/netrun_entity_modules_reactions/Run()
	var/mob/camera/netrun_entity/module_fixture/entity = allocate(/mob/camera/netrun_entity/module_fixture)
	var/datum/netrun_entity_module/module_probe/signals/module = entity.install_module(/datum/netrun_entity_module/module_probe/signals)
	TEST_ASSERT_NOTNULL(module, "A runtime capability installs an owned reaction")
	TEST_ASSERT(module.listen(entity, "netrun_module_probe_fact", TYPE_PROC_REF(/datum/netrun_entity_module/module_probe/signals, on_fact)), "Repeated subscriptions are idempotent")
	SEND_SIGNAL(entity, "netrun_module_probe_fact")
	TEST_ASSERT_EQUAL(entity.module_signal_count, 1, "A fact invokes the capability once")
	TEST_ASSERT(entity.remove_module("probe_signals"), "A reacting capability can be uninstalled")
	TEST_ASSERT(!length(module.subscriptions), "Uninstall clears its owned subscription records")
	SEND_SIGNAL(entity, "netrun_module_probe_fact")
	TEST_ASSERT_EQUAL(entity.module_signal_count, 1, "Uninstalled reactions no longer observe facts")
	TEST_ASSERT_NULL(entity.install_module(/datum/netrun_entity_module/module_probe/signals/failed), "An installation hook can reject installation")
	SEND_SIGNAL(entity, "netrun_module_probe_fact")
	TEST_ASSERT_EQUAL(entity.module_signal_count, 1, "Failed installation also unregisters reactions")
	TEST_ASSERT(!entity.entity_modules["probe_failed"], "Failed installation leaves no indexed capability")
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/bot/bot = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, NETRUN_BOT_SENTINEL)
	var/datum/netrun_bot_brain/brain = bot.brain
	brain.clear_timer()
	SSnetrun.task_scheduler?.cancel("bot", brain)
	SEND_SIGNAL(bot, COMSIG_NETRUN_ENTITY_GOALS_CHANGED, TRUE)
	TEST_ASSERT(!SSnetrun.task_scheduler?.by_key["bot:[REF(brain)]"], "A goal transition inside behavior does not enqueue itself again")
	SEND_SIGNAL(bot, COMSIG_NETRUN_ENTITY_GOALS_CHANGED, FALSE)
	TEST_ASSERT(SSnetrun.task_scheduler?.by_key["bot:[REF(brain)]"], "An external goal transition wakes budgeted behavior")
	SSnetrun.task_scheduler.cancel("bot", brain)
	TEST_ASSERT(bot.remove_module("bot_goals"), "The goal reaction is a removable capability")
	SEND_SIGNAL(bot, COMSIG_NETRUN_ENTITY_GOALS_CHANGED, FALSE)
	TEST_ASSERT(!SSnetrun.task_scheduler.by_key["bot:[REF(brain)]"], "Removing the goal capability removes its wake reaction")
	TEST_ASSERT(bot.remove_module("bot_combat"), "The combat reaction is a removable capability")
	SEND_SIGNAL(bot.console, COMSIG_NETRUN_ICE_CAST_STARTED, null, bot.console)
	TEST_ASSERT(!SSnetrun.task_scheduler.by_key["bot:[REF(brain)]"], "Removing combat also removes its addressed ICE reaction")
