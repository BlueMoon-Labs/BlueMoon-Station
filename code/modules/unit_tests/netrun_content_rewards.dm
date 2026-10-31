/// Presets hide owned finite files until their actual final combat defeat.
/datum/unit_test/netrun_fortress_reward_ownership/Run()
	var/datum/component/netrun_node/node = netrun_fortress_node()
	var/datum/netrun_fortress/fortress = SSnetrun.build_fortress_preset(node, "rnd_archive")
	TEST_ASSERT_NOTNULL(fortress.defeat_loot_store, "An authored fortress owns a hidden reward disk")
	var/list/originals = fortress.defeat_loot_store.files.Copy()
	TEST_ASSERT_EQUAL(length(originals), 4, "The research archive rewards two programs and two tools")
	TEST_ASSERT(fortress.defeat_loot_store.used() <= fortress.defeat_loot_store.capacity, "Hidden rewards respect actual capacity")
	TEST_ASSERT(!fortress.release_defeat_loot(null), "An intact fortress cannot be looted through the release API")
	TEST_ASSERT_EQUAL(length(node.salvage), 0, "An intact reward never enters public debris")
	for(var/datum/netrun_fortress_module/module as anything in fortress.modules.Copy())
		module.take_damage(10000, "test", null)
	TEST_ASSERT(node.fortress_loot_released, "Actual final module defeat commits the one-time reward")
	TEST_ASSERT_EQUAL(length(fortress.defeat_loot_store.files), 0, "The hidden disk retains no second ownership")
	for(var/datum/netrun_file/file as anything in originals)
		TEST_ASSERT(file in node.salvage, "The original rewarded file enters debris, never a copy")
	fortress.release_defeat_loot(null)
	TEST_ASSERT_EQUAL(length(node.salvage), length(originals), "Repeated damage/release cannot mint more rewards")
	qdel(fortress)
	fortress = SSnetrun.build_fortress_preset(node, "rnd_archive")
	TEST_ASSERT_NULL(fortress.defeat_loot_store, "Reconstruction of the same node cannot seed a second reward")
	for(var/datum/netrun_file/file as anything in originals)
		TEST_ASSERT(!QDELETED(file), "Removing the empty old fortress does not delete its public earned files")

/// A full public cache preserves everybody's existing files. Earned leftovers
/// drain on local frees, including after the ruins have already been claimed.
/datum/unit_test/netrun_fortress_reward_overflow/Run()
	var/datum/component/netrun_node/node = netrun_fortress_node()
	var/datum/netrun_fortress/fortress = SSnetrun.build_fortress_preset(node, "relay_outpost")
	var/list/originals = fortress.defeat_loot_store.files.Copy()
	var/list/previous = list()
	for(var/index in 1 to NETRUN_MAX_SALVAGE_FILES)
		var/datum/netrun_file/file = new("existing-[index].txt", NETRUN_FILE_TEXT, "existing data", 1)
		previous += file
		node.leave_salvage(file, null, FALSE)
	node.refresh_salvage()
	for(var/datum/netrun_fortress_module/module as anything in fortress.modules.Copy())
		module.take_damage(10000, "test", null)
	TEST_ASSERT_EQUAL(length(node.salvage), NETRUN_MAX_SALVAGE_FILES, "Defeat never overflows the public file bound")
	TEST_ASSERT_EQUAL(length(fortress.defeat_loot_store.files), length(originals), "Rewards wait as owned originals when there is no room")
	for(var/datum/netrun_file/file as anything in previous)
		TEST_ASSERT((file in node.salvage) && !QDELETED(file), "A reward does not evict an unrelated existing file")
	var/datum/netrun_console/claimer = allocate(/datum/netrun_console, allocate(/obj/item))
	fortress.claim(claimer)
	for(var/index in 1 to length(originals))
		var/datum/netrun_file/removed = previous[index]
		node.salvage -= removed
		qdel(removed)
		node.refresh_salvage()
		TEST_ASSERT_EQUAL(length(node.salvage), NETRUN_MAX_SALVAGE_FILES, "Each freed slot admits one earned reward without recursion")
	TEST_ASSERT_EQUAL(length(fortress.defeat_loot_store.files), 0, "Claiming/rebuilding does not strand already earned loot")
	TEST_ASSERT(!fortress.defeat_loot_waiting, "An empty reward releases its local subscription")
	for(var/datum/netrun_file/file as anything in originals)
		TEST_ASSERT(file in node.salvage, "Every original reward reaches public debris exactly once")

/// Removing intact defenses administratively burns their sealed stock, not a
/// farmable drop. A later reconstruction keeps the node's permanent seed stamp.
/datum/unit_test/netrun_fortress_reward_administrative_removal/Run()
	var/datum/component/netrun_node/node = netrun_fortress_node()
	var/datum/netrun_fortress/fortress = SSnetrun.build_fortress_preset(node, "relay_outpost")
	var/list/originals = fortress.defeat_loot_store.files.Copy()
	qdel(fortress)
	TEST_ASSERT_EQUAL(length(node.salvage), 0, "Administrative deletion never reveals a reward")
	for(var/datum/netrun_file/file as anything in originals)
		TEST_ASSERT(QDELETED(file), "The removed hidden disk deletes the files it still owns")
	fortress = SSnetrun.build_fortress_preset(node, "relay_outpost")
	TEST_ASSERT_NULL(fortress.defeat_loot_store, "Removal and reconstruction do not refill hidden rewards")

/// Station collection ranks useful earned files above incidental notes, but
/// cannot acquire protected files from the intact machine's ordinary disk.
/datum/unit_test/netrun_recycling_value_priority/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/bot/bot = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, NETRUN_BOT_RECYCLER)
	var/datum/netrun_console/private_owner = allocate(/datum/netrun_console, allocate(/obj/item))
	var/datum/netrun_fortress/vault = new(scene.node_b, "Private archive", NETRUN_FACTION_OWNER, private_owner)
	scene.node_b.fortress = vault
	vault.add_module(NETRUN_FORT_VAULT, TRUE)
	var/datum/netrun_file/protected = netrun_program_file("aegis")
	scene.node_b.file_store.insert(protected)
	TEST_ASSERT_NULL(bot.brain.find_salvage(null, TRUE), "A valuable intact disk is never a debris target")
	var/datum/netrun_file/note = new("note.txt", NETRUN_FILE_TEXT, "ordinary debris", 1)
	scene.node_a.leave_salvage(note)
	note.salvage_recycle_after = world.time
	var/datum/netrun_file/reward = netrun_program_file("lance")
	reward.fortress_reward = TRUE
	scene.node_b.leave_salvage(reward)
	reward.salvage_recycle_after = world.time
	TEST_ASSERT_EQUAL(bot.brain.find_salvage(null, TRUE), scene.node_b, "A reachable earned program outranks an adjacent ordinary note")
	bot.enter_node(scene.node_b)
	var/datum/netrun_bot_goal/salvage/goal = allocate(/datum/netrun_bot_goal/salvage, bot.brain, scene.node_b)
	goal.advance()
	TEST_ASSERT_EQUAL(bot.console.inventory.local_store.find_file(reward.uid), reward, "The collector acquires the actual rewarded original")
	TEST_ASSERT_EQUAL(scene.node_b.file_store.find_file(protected.uid), protected, "Collection never robs the protected machine disk")
	TEST_ASSERT(note in scene.node_a.salvage, "Lower priority debris remains available for a later trip")

/// A collect order is authenticated at delivery and delegates at most the
/// issuer's actual USER residency; the resulting goal still uses real recovery.
/datum/unit_test/netrun_agent_collect_order/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/owner = allocate(/mob/camera/netrun_entity)
	owner.enter_node(scene.node_a)
	var/mob/camera/netrun_entity/bot/agent = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, "collector", owner.console)
	var/datum/netrun_file/reward = netrun_program_file("lance")
	scene.node_b.leave_salvage(reward)
	TEST_ASSERT(!owner.console.execute_agent_order(agent, list("order" = "collect", "address" = scene.node_b.address)), "Seeing a remote node does not delegate USER")
	TEST_ASSERT(!agent.console.access_session.direct_node_level(scene.node_b), "A rejected collect order grants no node authority")
	owner.console.access_session.grant_node(scene.node_b, NETRUN_ACCESS_USER)
	TEST_ASSERT(owner.console.agent_order(REF(agent), "collect", scene.node_b.address), "An authorized order first enters the real delivery pipeline")
	TEST_ASSERT(!istype(agent.brain.current_goal(), /datum/netrun_bot_goal/salvage), "Dispatch alone cannot change the agent's task")
	var/datum/netrun_request/agent_control/control = netrun_operation_packet(owner.console, /datum/netrun_request/agent_control)
	TEST_ASSERT_NOTNULL(control, "Collection owns an ordinary routed control packet")
	TEST_ASSERT(control.deliver(), "Delivery accepts the current owner and current target authority")
	TEST_ASSERT(istype(agent.brain.current_goal(), /datum/netrun_bot_goal/salvage), "Delivery starts a finite collection task")
	TEST_ASSERT_EQUAL(agent.console.access_session.direct_node_level(scene.node_b), NETRUN_ACCESS_USER, "Only the selected USER residency is delegated")
	TEST_ASSERT_EQUAL(agent.console.access_session.exportable_node_level(scene.node_b), NETRUN_ACCESS_NONE, "An order cannot mint a transferable acquired grant")
	TEST_ASSERT(reward in scene.node_b.salvage, "A control message never transfers the actual target file remotely")
	agent.enter_node(scene.node_b)
	agent.brain.current_goal().advance()
	TEST_ASSERT_EQUAL(agent.console.inventory.local_store.find_file(reward.uid), reward, "Physical arrival recovers the same original file")
	TEST_ASSERT_EQUAL(agent.brain.order, "guard", "After finite collection the agent retains an explicit post")

/// Keep a chosen valid opponent instead of switching every AP action, and do
/// not spend three AP or a one-shot card on a target a cheap attack can finish.
/datum/unit_test/netrun_bot_target_and_ap_policy/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/bot/bot = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, NETRUN_BOT_SENTINEL)
	var/mob/camera/netrun_entity/first = allocate(/mob/camera/netrun_entity)
	var/mob/camera/netrun_entity/second = allocate(/mob/camera/netrun_entity)
	first.integrity = 70
	second.integrity = 90
	TEST_ASSERT_EQUAL(bot.brain.pick_target(list(first, second)), first, "The initial legal choice prefers an easier target")
	second.integrity = 1
	TEST_ASSERT_EQUAL(bot.brain.pick_target(list(first, second)), first, "HP changes do not steal a still valid target lock")
	TEST_ASSERT_EQUAL(bot.brain.pick_target(list(second)), second, "A departed opponent releases its target lock")
	var/datum/netrun_program/cheap = SSnetrun.get_program("sting")
	var/datum/netrun_program/card = SSnetrun.get_program("logic_bomb")
	TEST_ASSERT(bot.brain.program_value(cheap, 7, TRUE) > bot.brain.program_value(card, 7, TRUE), "The AI conserves AP and one-shot cards on a cheap finish")
	TEST_ASSERT(bot.brain.program_value(card, 100, TRUE) > bot.brain.program_value(cheap, 100, TRUE), "A high-value one-shot remains useful against a healthy enemy")

/// A turn bot cannot interrupt an ICE windup during that ICE's deferred turn.
/// Its ordinary ready control program is therefore prepared in its own turn.
/datum/unit_test/netrun_bot_proactive_control/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/bot/bot = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, NETRUN_BOT_SENTINEL)
	var/mob/camera/netrun_entity/bot/enemy = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, NETRUN_BOT_RAIDER)
	TEST_ASSERT(bot.brain.combat_step(), "A real hostile encounter is handled by the combat capability")
	TEST_ASSERT_EQUAL(bot.brain.controlled_target_ref?.resolve(), enemy, "A healthy hostile process receives proactive control before attacks")
	var/datum/netrun_combat_encounter/encounter = bot.console.get_combat_encounter()
	TEST_ASSERT(encounter?.cooldown_remaining(bot.console, SSnetrun.get_program("blackout")) > 0, "Control was admitted through the native turn program pipeline")
