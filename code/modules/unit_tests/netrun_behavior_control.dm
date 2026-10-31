/// Owned policy changes cross the real control delivery boundary with scalar snapshots.
/datum/unit_test/netrun_behavior_control_delivery/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/owner = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	owner.console.operator = owner
	var/mob/camera/netrun_entity/bot/agent = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, NETRUN_BOT_SENTINEL, owner.console)
	var/mob/camera/netrun_entity/bot/peer = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, NETRUN_BOT_SENTINEL, owner.console)
	var/datum/netrun_agent_behavior/pattern/temperament/policy = netrun_actor_temperament(agent)
	var/datum/netrun_agent_behavior/pattern/temperament/peer_policy = netrun_actor_temperament(peer)
	var/list/changes = list("strategy" = "guard", "aggression" = 25, "caution" = 75, "cooperation" = FALSE)
	TEST_ASSERT(owner.console.agent_order(REF(agent), "behavior", null, changes), "The owner can send an allowlisted behavior control")
	TEST_ASSERT_EQUAL(policy.strategy, "profile", "An in-flight behavior order cannot change its destination")
	changes["strategy"] = "patrol"
	changes["aggression"] = 99
	var/datum/netrun_request/agent_control/control = netrun_operation_packet(owner.console, /datum/netrun_request/agent_control)
	TEST_ASSERT(control && control.deliver(), "Only authenticated routed delivery applies the control")
	TEST_ASSERT_EQUAL(policy.strategy, "guard", "The packet owns an independent scalar snapshot")
	TEST_ASSERT_EQUAL(policy.aggression, 25, "Mutating the caller's options cannot rewrite a queued control")
	TEST_ASSERT_EQUAL(policy.caution, 75, "The delivered policy retains its configured caution")
	TEST_ASSERT(!policy.cooperation, "An explicit false flag survives transport")
	TEST_ASSERT_EQUAL(peer_policy.strategy, "profile", "A shared archetype does not share mutable policy")
	var/list/payload = agent.agent_entry()
	var/list/displayed = payload["behavior"]
	TEST_ASSERT_EQUAL(displayed["strategy"], "guard", "Owner payload exposes the actual policy")
	displayed["strategy"] = "profile"
	TEST_ASSERT_EQUAL(policy.strategy, "guard", "A presentation snapshot cannot mutate policy")
	owner.console.cli("agent [REF(agent)] behavior scavenge 35 65 on")
	control = netrun_operation_packet(owner.console, /datum/netrun_request/agent_control)
	TEST_ASSERT(control && control.deliver(), "The CLI uses the same routed control path")
	TEST_ASSERT_EQUAL(policy.strategy, "scavenge", "CLI strategy reaches the installed pattern")
	TEST_ASSERT_EQUAL(policy.aggression, 35, "CLI numeric options retain their values")
	TEST_ASSERT(policy.cooperation, "CLI cooperation is an ordinary boolean policy value")

/// Foreign control, invalid options and a lost route never partially change policy.
/datum/unit_test/netrun_behavior_control_authority/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/owner = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	var/mob/camera/netrun_entity/stranger = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	owner.console.operator = owner
	stranger.console.operator = stranger
	var/mob/camera/netrun_entity/bot/agent = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, NETRUN_BOT_SENTINEL, owner.console)
	var/datum/netrun_agent_behavior/pattern/temperament/policy = netrun_actor_temperament(agent)
	TEST_ASSERT(!stranger.console.agent_order(REF(agent), "behavior", null, list("strategy" = "guard")), "A forged agent reference does not grant control")
	TEST_ASSERT(!owner.console.agent_order(REF(agent), "behavior", null, list("strategy" = "guard", "aggression" = 101)), "Out-of-range options reject the entire control")
	TEST_ASSERT(!owner.console.agent_order(REF(agent), "behavior", null, list("cooperation" = "on")), "A wire request must contain a boolean rather than arbitrary text")
	TEST_ASSERT(!owner.console.agent_order(REF(agent), "behavior", null, list("strategy" = list("guard"))), "Nested data cannot become a strategy")
	TEST_ASSERT(!owner.console.agent_order(REF(agent), "behavior", null, list("module_type" = /datum/netrun_agent_behavior/pattern/communication)), "Client data cannot name an executable module")
	TEST_ASSERT_EQUAL(policy.strategy, "profile", "Rejected controls leave the current policy intact")
	TEST_ASSERT(owner.console.agent_order(REF(agent), "behavior", null, list("strategy" = "guard")), "A valid control may begin")
	var/datum/netrun_request/agent_control/control = netrun_operation_packet(owner.console, /datum/netrun_request/agent_control)
	scene.node_a.offline_until = world.time + 1 MINUTES
	TEST_ASSERT(control && !control.deliver(), "Delivery revalidates node availability")
	TEST_ASSERT_EQUAL(policy.strategy, "profile", "Losing the route cannot deliver a stale mutation")

/// Accepted recall and relaunch preserve owned policy; copies remain independent.
/datum/unit_test/netrun_behavior_control_roundtrip/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/owner = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	owner.console.operator = owner
	var/datum/netrun_file/bot/program = netrun_bot_file(NETRUN_BOT_SENTINEL)
	TEST_ASSERT(owner.console.store_file(program) && owner.console.launch_bot_file(program.uid), "The owner launches a real agent package")
	var/list/agents = owner.console.agents()
	var/mob/camera/netrun_entity/bot/agent = agents[1]
	allocated += agent
	TEST_ASSERT(owner.console.agent_order(REF(agent), "behavior", null, list("strategy" = "scavenge", "aggression" = 20, "caution" = 80, "cooperation" = FALSE)), "The owner configures the launched agent")
	var/datum/netrun_request/agent_control/control = netrun_operation_packet(owner.console, /datum/netrun_request/agent_control)
	TEST_ASSERT(control && control.deliver(), "Configuration is delivered before recall")
	TEST_ASSERT(agent.return_to_owner(), "Recall starts its ordinary file delivery")
	var/datum/netrun_request/agent_recall/recall = netrun_operation_packet(owner.console, /datum/netrun_request/agent_recall)
	TEST_ASSERT(recall && recall.deliver(), "Accepted recall persists policy in the actual package")
	TEST_ASSERT_EQUAL(program.stored_behavior["strategy"], "scavenge", "The recalled package owns the selected strategy")
	var/datum/netrun_file/bot/copied = program.copy()
	allocated += copied
	copied.stored_behavior["caution"] = 5
	TEST_ASSERT_EQUAL(program.stored_behavior["caution"], 80, "A copied package owns an independent policy snapshot")
	TEST_ASSERT(owner.console.launch_bot_file(program.uid), "The original recalled package relaunches")
	agents = owner.console.agents()
	agent = agents[1]
	allocated += agent
	var/datum/netrun_agent_behavior/pattern/temperament/policy = netrun_actor_temperament(agent)
	TEST_ASSERT_EQUAL(policy.strategy, "scavenge", "Relaunch restores strategy through validated mutation")
	TEST_ASSERT_EQUAL(policy.aggression, 20, "Relaunch restores aggression")
	TEST_ASSERT_EQUAL(policy.caution, 80, "A copy's changes cannot alter the original relaunched policy")
	TEST_ASSERT(!policy.cooperation, "False cooperation survives recall and relaunch")

/// Directly edited packages are validated before policy or inventory mutation.
/datum/unit_test/netrun_behavior_control_invalid_package/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/bot/agent = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, NETRUN_BOT_SENTINEL)
	var/datum/netrun_agent_behavior/pattern/temperament/policy = netrun_actor_temperament(agent)
	var/datum/netrun_file/bot/package = netrun_bot_file(NETRUN_BOT_SENTINEL)
	allocated += package
	var/datum/netrun_file/note = new("saved.txt", NETRUN_FILE_TEXT, "Saved memory")
	package.stored_files = list(note)
	package.stored_behavior = list("strategy" = "guard", "caution" = list(80))
	var/datum/netrun_file/original = agent.console.inventory.local_store.files[1]
	TEST_ASSERT(!package.restore_agent(agent), "A non-scalar persisted option rejects restoration")
	TEST_ASSERT_EQUAL(policy.strategy, "profile", "Validation happens before any partial policy mutation")
	TEST_ASSERT(original in agent.console.inventory.local_store.files, "Rejected restoration preserves live inventory")
	TEST_ASSERT(note in package.stored_files, "Rejected restoration preserves saved inventory ownership")
	package.stored_behavior = list("strategy" = "guard", "module_type" = /datum/netrun_agent_behavior/pattern/communication)
	TEST_ASSERT(!package.restore_agent(agent), "Persisted policy cannot carry executable type names")
	TEST_ASSERT_EQUAL(policy.strategy, "profile", "Unknown persisted fields leave live policy intact")

/// An explicit standing order replaces custom planning without resetting traits.
/datum/unit_test/netrun_behavior_control_standing_order/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/owner = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	owner.console.operator = owner
	owner.console.access_session.grant_node(scene.node_b, NETRUN_ACCESS_USER)
	var/mob/camera/netrun_entity/bot/agent = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, NETRUN_BOT_SENTINEL, owner.console)
	TEST_ASSERT(agent.get_module_host().mutate_pattern("temperament", list("strategy" = "scavenge", "aggression" = 20, "caution" = 80, "cooperation" = FALSE)), "The agent begins with its own custom planning and traits")
	var/datum/netrun_agent_behavior/pattern/temperament/policy = netrun_actor_temperament(agent)
	TEST_ASSERT(owner.console.agent_order(REF(agent), "guard", scene.node_b.address), "The owner submits the normal authorized guard order")
	TEST_ASSERT_EQUAL(policy.strategy, "scavenge", "Dispatch cannot replace custom planning before delivery")
	var/datum/netrun_request/agent_control/control = netrun_operation_packet(owner.console, /datum/netrun_request/agent_control)
	TEST_ASSERT(control && control.deliver(), "The standing order crosses the native control packet boundary")
	TEST_ASSERT_EQUAL(policy.strategy, "profile", "Accepted guard control restores archetype planning")
	TEST_ASSERT_EQUAL(policy.aggression, 20, "A standing order retains configured aggression")
	TEST_ASSERT_EQUAL(policy.caution, 80, "A standing order retains configured caution")
	TEST_ASSERT(!policy.cooperation, "A standing order retains the cooperation trait")
	// Keep this first planning step on its source, so the goal itself is inspected.
	agent.next_hop = world.time + 1 SECONDS
	agent.brain.advance_goals()
	var/datum/netrun_bot_goal/guard/goal = agent.brain.current_goal()
	TEST_ASSERT(istype(goal), "Native planning honors the standing guard order after custom strategy")
	TEST_ASSERT_EQUAL(goal.post_ref?.resolve(), scene.node_b, "The new guard goal targets the requested post rather than the current node")
