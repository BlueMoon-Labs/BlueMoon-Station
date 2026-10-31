/// Every archetype starts as a real clientless entity with its own console, memory and programs.
/datum/unit_test/netrun_bot_archetypes/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	for(var/id in list(NETRUN_BOT_RAIDER, "scavenger", NETRUN_BOT_CUSTODIAN, NETRUN_BOT_POLICE, NETRUN_BOT_SENTINEL, NETRUN_BOT_MENDER))
		var/mob/camera/netrun_entity/bot/bot = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, id)
		TEST_ASSERT_EQUAL(bot.bot_kind, id, "The archetype is applied")
		TEST_ASSERT_EQUAL(bot.host_node, scene.node_a, "The bot lives in its spawn node")
		TEST_ASSERT(bot.console.autonomous(), "Bot consoles are autonomous")
		TEST_ASSERT(istype(bot.console, bot.program.console_type), "The program chooses the console implementation")
		TEST_ASSERT_EQUAL(bot.integrity, bot.program.max_integrity, "The program sets integrity")
		TEST_ASSERT_EQUAL(bot.console.inventory.local_store.capacity, bot.program.storage, "The program sets memory")
		TEST_ASSERT_NULL(bot.messenger_pda, "Autonomous processes do not join the crew messenger")
		TEST_ASSERT(bot in SSnetrun.bots, "Bots are registered")
		for(var/program_id in bot.program.programs)
			var/found = FALSE
			for(var/datum/netrun_file/file as anything in bot.console.all_files())
				if(file.kind == NETRUN_FILE_PROGRAM && file.content == program_id)
					found = TRUE
			TEST_ASSERT(found, "Combat programs are real files in bot memory")
		var/list/entry = bot.get_netrun_combatant().ui_entry()
		TEST_ASSERT_EQUAL(entry["kind"], "bot", "Bots are a distinct contact kind")
		TEST_ASSERT_EQUAL(entry["bot_kind"], id, "Contacts carry the archetype")
		bot.brain.think()
		TEST_ASSERT(!QDELETED(bot), "A quiet think must not destroy the bot")
		qdel(bot)
		TEST_ASSERT(!(bot in SSnetrun.bots), "Deleted bots leave the registry")
	var/list/summary = scene.node_a.ui_entry(allocate(/datum/netrun_console, allocate(/obj/item)))
	TEST_ASSERT_EQUAL(summary["bots"], 0, "The map counts only live bots")

/// Sanctioned processes act legally and stay invisible to ICE; rogue ones are intruders once they move.
/datum/unit_test/netrun_bot_clearance/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/bot/police = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, NETRUN_BOT_POLICE)
	TEST_ASSERT(!police.defense_threat(), "Police does not wake departmental ICE")
	TEST_ASSERT(police.console.legit_node_level(scene.node_b) >= NETRUN_ACCESS_USER, "Police has legal USER on station LANs")
	TEST_ASSERT(police.console.legit_node_level(scene.node_b) < NETRUN_ACCESS_ROOT, "Police clearance never grants ROOT")
	TEST_ASSERT_EQUAL(police.console.intrusion.trace_mult, 0, "Police activity is not traced")
	var/datum/netrun_ice/sentry = allocate(/datum/netrun_ice, scene.node_b)
	police.enter_node(scene.apc_node)
	police.enter_node(scene.node_b)
	TEST_ASSERT(!sentry.is_intruder(police, scene.node_b), "ICE ignores the lawful police process")
	var/mob/camera/netrun_entity/bot/raider = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, NETRUN_BOT_RAIDER)
	TEST_ASSERT(raider.defense_threat(), "Rogue processes are threats")
	TEST_ASSERT(!raider.console.has_key(scene.node_b.network, TRUE), "An ambient raider starts without its LAN's key")
	raider.enter_node(scene.apc_node)
	raider.enter_node(scene.node_b)
	TEST_ASSERT(sentry.is_intruder(raider, scene.node_b), "ICE treats a keyed raider without USER as an intruder")
	var/list/summary = scene.node_b.ui_entry(police.console)
	TEST_ASSERT_EQUAL(summary["bots"], 2, "Both bots are counted on the map")
	TEST_ASSERT(summary["police"], "A police presence is flagged for the map")
	TEST_ASSERT_EQUAL(summary["entities"], 0, "Bots are not counted as player residents")

/// Bots never impersonate a player at the console.
/datum/unit_test/netrun_bot_autonomous_console/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/bot/bot = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, NETRUN_BOT_CUSTODIAN)
	var/lease = bot.console.last_ui_at
	bot.console.note_user_action()
	bot.console.finish_user_action(scene.node_a)
	TEST_ASSERT_EQUAL(bot.console.last_ui_at, lease, "Autonomous actions do not renew UI activity")
	TEST_ASSERT(!SSnetrun.task_scheduler?.by_key["console:[REF(bot.console)]"], "Autonomous actions do not enqueue interactive console work")
	bot.console.log_line("проверка")
	TEST_ASSERT_EQUAL(bot.console.log[length(bot.console.log)]["text"], "проверка", "The bot keeps its own bounded log")

/// The police claims an incident, confronts a rogue process on site and attacks it through combat programs.
/datum/unit_test/netrun_bot_police_incident/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/bot/police = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, NETRUN_BOT_POLICE)
	var/mob/camera/netrun_entity/bot/raider = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, NETRUN_BOT_RAIDER)
	var/datum/netrun_incident/incident = SSnetrun.report_incident("rogue", scene.node_a, raider, NETRUN_INCIDENT_MEDIUM, "Проверка")
	var/datum/netrun_bot_brain/brain = police.brain
	brain.clear_goals()
	TEST_ASSERT_EQUAL(brain.claim_incident(), incident, "The police claims the open incident")
	TEST_ASSERT_EQUAL(incident.claimed_by(), brain, "The incident records its handler")
	var/datum/netrun_bot_goal/investigate/goal = new(brain, incident)
	brain.push_goal(goal)
	goal.advance()
	TEST_ASSERT(!goal.scanned, "An admitted scan is not a delivered inspection")
	var/datum/netrun_request/command/scan = netrun_operation_packet(police.console, /datum/netrun_request/command)
	TEST_ASSERT_NOTNULL(scan, "The police uses a real routed scan")
	scan.deliver()
	goal.advance()
	TEST_ASSERT(goal.scanned, "Arrival starts with an ordinary scan command")
	goal.advance()
	TEST_ASSERT(brain.remembered_enemy(raider), "A rogue suspect is engaged without a warning")
	var/before = raider.integrity
	TEST_ASSERT(brain.combat_step(), "The police prepares control against the healthy suspect")
	TEST_ASSERT(raider.is_stunned(), "The first native combat action actually suppresses the suspect")
	TEST_ASSERT_EQUAL(raider.integrity, before, "Control is not falsely treated as direct damage")
	var/datum/netrun_combat_encounter/encounter = police.console.get_combat_encounter()
	TEST_ASSERT(encounter?.has_turn(police.console) && encounter.remaining_ap(police.console) > 0, "The officer retains AP in the same native turn after control")
	TEST_ASSERT(brain.combat_step(), "The officer spends remaining AP on a real attack")
	TEST_ASSERT(raider.integrity < before, "The next native combat program damages the controlled suspect")
	qdel(raider)
	goal.arrived_at = world.time - 9 SECONDS
	TEST_ASSERT_EQUAL(goal.advance(), NETRUN_BOT_GOAL_DONE, "A cleared scene ends the investigation")
	TEST_ASSERT(incident.closed, "The incident is closed with a report")
	var/report = FALSE
	for(var/datum/netrun_file/file as anything in police.console.all_files())
		if(file.kind == NETRUN_FILE_TEXT && findtext(file.name, "report-") == 1)
			report = TRUE
	TEST_ASSERT(report, "The police keeps a written report in its memory")

/// Counter-tracing uses the same delivered commands as a player; no direct brain mutation.
/datum/unit_test/netrun_bot_countertrace_delivery/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/bot/police = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, NETRUN_BOT_POLICE)
	var/obj/item/host = allocate(/obj/item)
	var/datum/netrun_console/attacker = allocate(/datum/netrun_console, host)
	attacker.intrusion.breach = allocate(/datum/netrun_breach, attacker, "node", scene.node_a.address, scene.node_a.get_name(), 1)
	SSnetrun.currentbreaches |= attacker
	var/before = attacker.intrusion.trace
	TEST_ASSERT(police.brain.counter_trace(scene.node_a), "The officer admits a real countertrace command")
	TEST_ASSERT_EQUAL(attacker.intrusion.trace, before, "The brain cannot raise trace before command delivery")
	var/datum/netrun_request/command/packet = netrun_operation_packet(police.console, /datum/netrun_request/command)
	TEST_ASSERT_NOTNULL(packet, "Countertrace owns a routed command packet")
	TEST_ASSERT_EQUAL(packet.command_id, "countertrace", "The police uses the public device command")
	TEST_ASSERT(packet.deliver(), "A legal station officer can protect the node")
	TEST_ASSERT_EQUAL(attacker.intrusion.trace, before + 8, "The delivered command applies the countertrace once")
	police.brain.clear_command()
	police.console.next_command = 0
	TEST_ASSERT(police.brain.counter_trace(scene.node_a), "Another observation can dispatch a new command")
	packet = netrun_operation_packet(police.console, /datum/netrun_request/command)
	attacker.intrusion.breach.target_id = scene.node_b.address
	TEST_ASSERT(packet.deliver(), "A no-longer-attacked node returns a valid empty result")
	TEST_ASSERT_EQUAL(attacker.intrusion.trace, before + 8, "Delivery rechecks the live breach instead of punishing stale observations")
	var/datum/netrun_command/command = SSnetrun.get_command("countertrace")
	attacker.access_session.node_access[scene.node_a.address] = NETRUN_ACCESS_ROOT
	TEST_ASSERT_NULL(command.execute(scene.node_a, attacker), "Acquired ROOT is not legal authority to countertrace another client")

/// Agents leave memory as processes and come back as files.
/datum/unit_test/netrun_bot_agent_lifecycle/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/owner = allocate(/mob/camera/netrun_entity)
	owner.enter_node(scene.node_a)
	var/datum/netrun_file/file = netrun_bot_file(NETRUN_BOT_SENTINEL)
	TEST_ASSERT(owner.console.store_file(file), "The agent program fits client memory")
	TEST_ASSERT(owner.console.launch_bot_file(file.uid), "An entity launches an agent at its own node")
	TEST_ASSERT_NULL(owner.console.find_local_file(file.uid), "The file leaves memory with the agent")
	var/list/agents = owner.console.agents()
	TEST_ASSERT_EQUAL(length(agents), 1, "The owner tracks its agent")
	var/mob/camera/netrun_entity/bot/agent = agents[1]
	TEST_ASSERT_EQUAL(agent.netrun_owner_console(), owner.console, "The agent knows its owner")
	TEST_ASSERT_EQUAL(agent.host_node, scene.node_a, "The agent starts at the owner's node")
	var/list/payload = owner.console.agents_payload()
	TEST_ASSERT_EQUAL(payload[1]["bot_kind"], NETRUN_BOT_SENTINEL, "The payload describes the agent")
	TEST_ASSERT(length(payload[1]["orders"]), "The payload lists available orders")
	TEST_ASSERT(owner.console.agent_order(REF(agent), "recall"), "The owner can recall the agent")
	var/datum/netrun_request/agent_control/control = netrun_operation_packet(owner.console, /datum/netrun_request/agent_control)
	TEST_ASSERT_NOTNULL(control, "A recall order first travels to the agent")
	control.deliver()
	agent.brain.think()
	TEST_ASSERT(!QDELETED(agent) && agent.agent_file == file, "The agent retains its program until the actual file arrives")
	var/datum/netrun_request/agent_recall/recall = netrun_operation_packet(owner.console, /datum/netrun_request/agent_recall)
	TEST_ASSERT_NOTNULL(recall, "Returning the program uses a real file packet")
	agent.brain.think()
	TEST_ASSERT_NULL(agent.brain.current_goal(), "A process awaiting recall acceptance must not start another patrol or guard route")
	recall.deliver()
	TEST_ASSERT(QDELETED(agent), "The accepted file delivery releases the live agent")
	var/returned = FALSE
	for(var/datum/netrun_file/stored as anything in owner.console.all_files())
		if(stored.kind == NETRUN_FILE_BOT && stored.content == NETRUN_BOT_SENTINEL)
			returned = TRUE
	TEST_ASSERT(returned, "The agent program returns to the owner's memory")

/// Death leaves real inventory for both visiting and station processes.
/datum/unit_test/netrun_bot_remains/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/datum/netrun_salvage_test_observer/observer = allocate(/datum/netrun_salvage_test_observer)
	var/mob/camera/netrun_entity/bot/raider = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, NETRUN_BOT_RAIDER)
	var/list/raider_files = raider.console.inventory.local_store.files.Copy()
	raider.take_integrity(1000, "test")
	TEST_ASSERT(QDELETED(raider), "A destroyed bot is removed")
	TEST_ASSERT_EQUAL(observer.changes, 1, "A full dead inventory publishes one debris fact rather than one per file")
	TEST_ASSERT_EQUAL(length(scene.node_a.salvage), min(NETRUN_MAX_SALVAGE_FILES, length(raider_files)), "A rogue leaves its existing loadout within the debris bound")
	for(var/datum/netrun_file/file as anything in scene.node_a.salvage)
		TEST_ASSERT(file in raider_files, "A death reward is the original owned file, not a minted replacement")
	var/mob/camera/netrun_entity/bot/custodian = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_b, NETRUN_BOT_CUSTODIAN)
	var/list/station_files = custodian.console.inventory.local_store.files.Copy()
	custodian.take_integrity(1000, "test")
	TEST_ASSERT_EQUAL(observer.changes, 2, "Station death also batches its inventory into one collector wakeup")
	TEST_ASSERT_EQUAL(length(scene.node_b.salvage), min(NETRUN_MAX_SALVAGE_FILES, length(station_files)), "Station processes also leave their real inventory")
	for(var/datum/netrun_file/file as anything in scene.node_b.salvage)
		TEST_ASSERT(file in station_files, "Station loot also preserves file identity")

/// A custodian repairs station works in its jurisdiction with the ordinary command.
/datum/unit_test/netrun_bot_custodian_repair/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/datum/netrun_fortress/fortress = SSnetrun.build_fortress_preset(scene.node_b, "relay_outpost")
	var/datum/netrun_fortress_module/wall = fortress.modules[1]
	wall.integrity = 10
	var/mob/camera/netrun_entity/bot/custodian = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_b, NETRUN_BOT_CUSTODIAN)
	var/datum/netrun_console/entity/bot/custodian/console = custodian.console
	console.jurisdiction = list(scene.node_b.network.id)
	TEST_ASSERT(fortress.is_friendly(console), "Station works trust the custodian")
	custodian.brain.clear_goals()
	custodian.program.plan(custodian.brain)
	var/datum/netrun_bot_goal/repair/goal = custodian.brain.current_goal()
	TEST_ASSERT(istype(goal), "Damaged station works become a repair goal")
	goal.advance()
	var/datum/netrun_request/command/packet = netrun_operation_packet(console, /datum/netrun_request/command)
	TEST_ASSERT_NOTNULL(packet, "The repair is an ordinary routed command")
	packet.deliver()
	TEST_ASSERT(wall.integrity > 10, "The delivered command repairs the module")

/// Bot command goals keep the same ACL and cancellation boundary as real entity commands.
/datum/unit_test/netrun_bot_command_delivery/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/bot/bot = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, NETRUN_BOT_SENTINEL)
	scene.node_a.command_ids |= "reboot"
	TEST_ASSERT_EQUAL(bot.brain.command_step(scene.node_a, "reboot"), NETRUN_BOT_GOAL_FAILED, "An autonomous USER cannot execute a ROOT command")
	TEST_ASSERT(scene.node_a.offline_until <= world.time, "The rejected command must not reboot the node")
	bot.brain.clear_command()
	bot.console.next_command = world.time
	TEST_ASSERT_EQUAL(bot.brain.command_step(scene.node_a, "scan"), NETRUN_BOT_GOAL_CONTINUE, "A valid command first enters the normal delivery queue")
	var/datum/netrun_request/command/packet = bot.brain.command_packet_ref?.resolve()
	TEST_ASSERT_NOTNULL(packet, "The brain owns exactly its pending ordinary command")
	TEST_ASSERT(!packet.delivery_interactive(), "Bot work never enters the player's interactive lane")
	bot.brain.clear_goals()
	TEST_ASSERT(QDELETED(packet), "Replacing a goal cancels its outstanding command and owned timer")
	TEST_ASSERT_NULL(bot.brain.command_nonce, "Cancellation forgets the previous response nonce")

/// Police consumes the delivered response, never the target's current private journal.
/datum/unit_test/netrun_bot_inspection_response/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/bot/police = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, NETRUN_BOT_POLICE)
	scene.node_a.add_packet_log("observed-response", "REJECT", "command", scene.node_b.address, scene.node_a.address, "scan")
	TEST_ASSERT_EQUAL(police.brain.inspect(scene.node_a), NETRUN_BOT_GOAL_CONTINUE, "Admission does not reveal a remote journal")
	TEST_ASSERT_NULL(police.brain.command_result, "An in-flight command has no response body")
	var/datum/netrun_request/command/packet = netrun_operation_packet(police.console, /datum/netrun_request/command)
	TEST_ASSERT_NOTNULL(packet, "Inspection uses the ordinary packet_log command")
	packet.deliver()
	scene.node_a.packet_logs = list()
	TEST_ASSERT_EQUAL(police.brain.inspect(scene.node_a), NETRUN_BOT_GOAL_DONE, "A delivered inspection completes")
	var/found = FALSE
	for(var/datum/netrun_file/file as anything in police.console.all_files())
		if(file.name == "last-inspection.txt" && findtext(file.content, "observed-response"))
			found = TRUE
	TEST_ASSERT(found, "The bot stores its received response even after the source journal changes")

/// Delivered controls edit only the owned process, and recall preserves its personal memory.
/datum/unit_test/netrun_bot_owned_memory/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/owner = allocate(/mob/camera/netrun_entity)
	owner.enter_node(scene.node_a)
	var/datum/netrun_file/bot/program = netrun_bot_file(NETRUN_BOT_SENTINEL)
	TEST_ASSERT(owner.console.store_file(program), "The owner installs the agent file")
	TEST_ASSERT(owner.console.launch_bot_file(program.uid), "The owner launches the actual program")
	var/list/agents = owner.console.agents()
	var/mob/camera/netrun_entity/bot/agent = agents[1]
	allocated += agent
	var/original_name = agent.real_name
	TEST_ASSERT(owner.console.agent_order(REF(agent), "persona", null, list("name" = "Keeper Seven", "avatar" = "moth", "accent" = "amber", "tagline" = "Keeps the notes")), "The owner submits a persona patch")
	TEST_ASSERT_EQUAL(agent.real_name, original_name, "An in-flight control cannot mutate its destination early")
	var/datum/netrun_request/agent_control/control = netrun_operation_packet(owner.console, /datum/netrun_request/agent_control)
	control.deliver()
	TEST_ASSERT_EQUAL(agent.real_name, "Keeper Seven", "Delivery applies the ordinary validated name change")
	var/datum/netrun_file/note = new("private.txt", NETRUN_FILE_TEXT, "Personal memory")
	owner.console.store_file(note)
	TEST_ASSERT(owner.console.agent_order(REF(agent), "upload", null, list("uid" = note.uid)), "The owner submits a real file transfer")
	TEST_ASSERT(owner.console.find_local_file(note.uid), "The source keeps its file before acceptance")
	control = netrun_operation_packet(owner.console, /datum/netrun_request/agent_control)
	control.deliver()
	TEST_ASSERT_EQUAL(agent.console.find_local_file(note.uid), note, "Delivery moves the exact file into the bot's own bounded memory")
	TEST_ASSERT_NULL(owner.console.find_local_file(note.uid), "A moved file is no longer retained by the sender")
	TEST_ASSERT(agent.return_to_owner(), "Recall admits a real file packet")
	var/datum/netrun_request/agent_recall/recall = netrun_operation_packet(owner.console, /datum/netrun_request/agent_recall)
	var/old_capacity = owner.console.inventory.local_store.capacity
	owner.console.inventory.local_store.capacity = 0
	recall.deliver()
	TEST_ASSERT(!QDELETED(agent) && agent.agent_file == program, "A full receiving store cannot delete the process or its original program")
	TEST_ASSERT_EQUAL(agent.console.find_local_file(note.uid), note, "Failed recall retains the bot's personal files")
	owner.console.inventory.local_store.capacity = old_capacity
	TEST_ASSERT(agent.return_to_owner(), "The retained process can retry after memory becomes available")
	recall = netrun_operation_packet(owner.console, /datum/netrun_request/agent_recall)
	recall.deliver()
	TEST_ASSERT(QDELETED(agent), "Only the accepted recall releases the process")
	TEST_ASSERT(owner.console.launch_bot_file(program.uid), "The saved program launches again")
	agents = owner.console.agents()
	agent = agents[1]
	allocated += agent
	TEST_ASSERT_EQUAL(agent.real_name, "Keeper Seven", "The relaunched process retains its chosen name")
	TEST_ASSERT_EQUAL(agent.get_persona().avatar, "moth", "The relaunched process retains its persona")
	TEST_ASSERT_EQUAL(agent.console.find_local_file(note.uid), note, "The relaunched process owns its original personal file")

/// A complete rotating itinerary reaches beyond the tactical48-node search radius.
/datum/unit_test/netrun_bot_full_patrol
	var/list/addresses = list()

/datum/unit_test/netrun_bot_full_patrol/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	for(var/index in 1 to 64)
		var/obj/item/host = allocate(/obj/item, run_loc_floor_bottom_left)
		host.anchored = TRUE
		var/datum/component/netrun_node/node = host.AddComponent(/datum/component/netrun_node, NETRUN_NODE_SERVER, list(), 1, list(), 4)
		addresses += node.address
	var/mob/camera/netrun_entity/bot/police = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, NETRUN_BOT_POLICE)
	police.brain.patrol_candidates = addresses.Copy()
	var/list/visited = list()
	for(var/index in 1 to length(addresses))
		var/shuffled_before = police.brain.patrol_shuffled_until
		var/datum/component/netrun_node/node = police.brain.police_destination()
		TEST_ASSERT_NOTNULL(node, "A large connected LAN retains a patrol destination")
		TEST_ASSERT(police.brain.patrol_shuffled_until - shuffled_before <= 24, "One patrol plan must not shuffle the whole station before checking its bounded window")
		TEST_ASSERT(!visited[node.address], "An itinerary does not starve distant nodes by repeatedly selecting its first neighborhood")
		visited[node.address] = TRUE
		SSnetrun.police_inspected[node.address] = world.time
	TEST_ASSERT_EQUAL(length(visited), 64, "The police covers the entire reachable itinerary, including nodes beyond48")
	var/datum/netrun_incident/incident = SSnetrun.report_incident("intrusion", scene.node_a, null, NETRUN_INCIDENT_HIGH, "Patrol interruption")
	police.brain.clear_goals()
	TEST_ASSERT_EQUAL(police.brain.claim_incident(), incident, "A serious incident interrupts ordinary patrol planning")
	police.brain.push_goal(new /datum/netrun_bot_goal/investigate(police.brain, incident))
	police.brain.clear_goals()
	TEST_ASSERT_NULL(incident.claimed_by(), "Cancelling an investigation immediately releases its claim")
	incident.close("fixture complete")

/datum/unit_test/netrun_bot_full_patrol/Destroy()
	for(var/address in addresses)
		SSnetrun.police_inspected -= address
	return ..()

/// Round arrivals run through the real housekeeping task, with controlled game deadlines.
/datum/unit_test/netrun_bot_round_population
	var/list/original_state
	var/datum/netrun_task_scheduler/census_scheduler
	var/datum/netrun_console/presence_console

/datum/unit_test/netrun_bot_round_population/proc/census()
	if(!presence_console)
		presence_console = allocate(/datum/netrun_console, allocate(/obj/item))
	presence_console.last_ui_at = world.time
	SSnetrun.next_bot_census = world.time
	SSnetrun.ensure_topology()
	census_scheduler.enqueue("housekeeping", null, NETRUN_TASK_BACKGROUND)
	var/datum/netrun_task/task = census_scheduler.take()
	SSnetrun.execute_task(task)
	qdel(task)

/datum/unit_test/netrun_bot_round_population/Run()
	original_state = list()
	for(var/field in list("bots", "bots_enabled", "next_bot_census", "rogue_wave_at", "police_respawn_at", "custodian_respawn_at", "recycler_respawn_at", "bot_spawn_pools", "bot_spawn_revision", "bot_spawn_index_builds", "bot_spawn_candidate_checks"))
		original_state[field] = SSnetrun.vars[field]
	SSnetrun.bots = list()
	SSnetrun.bots_enabled = TRUE
	SSnetrun.police_respawn_at = world.time
	SSnetrun.custodian_respawn_at = INFINITY
	SSnetrun.recycler_respawn_at = INFINITY
	SSnetrun.rogue_wave_at = world.time - 1
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/obj/machinery/ntnet_relay/relay = scene.machine(/obj/machinery/ntnet_relay, run_loc_floor_bottom_left)
	relay.enabled = TRUE
	relay.set_machine_stat(NONE)
	census_scheduler = allocate(/datum/netrun_task_scheduler, SSnetrun.get_execution_limits())
	for(var/index in 1 to NETRUN_POLICE_QUOTA)
		census()
	TEST_ASSERT_EQUAL(SSnetrun.count_bots(NETRUN_BOT_POLICE), NETRUN_POLICE_QUOTA, "Native round housekeeping fills the bounded visiting police quota")
	for(var/mob/camera/netrun_entity/bot/bot as anything in SSnetrun.bots)
		TEST_ASSERT(istype(bot.host_node?.parent, /obj/machinery/ntnet_relay), "Visitors enter through a real functioning network relay")
		TEST_ASSERT(bot.expires_at > world.time, "A police visit has a finite patrol lifetime")
	for(var/index in 1 to 4)
		var/before_wave = SSnetrun.count_network_visitors()
		SSnetrun.rogue_wave_at = world.time - 1
		census()
		var/arrived = SSnetrun.count_network_visitors() - before_wave
		TEST_ASSERT(arrived <= SSnetrun.visitor_wave_max, "A due wave cannot create an unbounded burst")
		if(before_wave + SSnetrun.visitor_wave_min <= SSnetrun.visitor_limit)
			TEST_ASSERT(arrived >= SSnetrun.visitor_wave_min, "A functioning entry admits a dense wave rather than a single straggler")
	for(var/id in SSnetrun.netrun_factions)
		if(SSnetrun.get_netrun_faction(id)?.arrival_weight)
			TEST_ASSERT(SSnetrun.count_bot_faction(id) <= SSnetrun.visitor_faction_limit, "Every visitor faction respects its own quota")
	TEST_ASSERT_EQUAL(SSnetrun.count_network_visitors(), SSnetrun.visitor_limit, "Timed waves populate the shared quota across all visitor factions")
	SSnetrun.rogue_wave_at = world.time - 1
	census()
	TEST_ASSERT_EQUAL(SSnetrun.count_network_visitors(), SSnetrun.visitor_limit, "A new due wave cannot bypass the shared visitor quota")
	var/index_builds = SSnetrun.bot_spawn_index_builds
	var/candidate_checks = SSnetrun.bot_spawn_candidate_checks
	for(var/index in 1 to 16)
		SSnetrun.maintain_bots()
	TEST_ASSERT_EQUAL(SSnetrun.bot_spawn_index_builds, index_builds, "Fast worker checks do not rescan the station's spawn candidates")
	TEST_ASSERT_EQUAL(SSnetrun.bot_spawn_candidate_checks, candidate_checks, "An undued census does not poll native nodes")
	var/mob/camera/netrun_entity/bot/departing
	for(var/mob/camera/netrun_entity/bot/bot as anything in SSnetrun.bots)
		if(SSnetrun.get_netrun_faction(bot.net_faction)?.arrival_weight)
			departing = bot
			break
	departing.expires_at = world.time - 1
	departing.brain.think()
	TEST_ASSERT(QDELETED(departing), "A visitor actually leaves when its lifetime expires")
	SSnetrun.rogue_wave_at = world.time - 1
	census()
	TEST_ASSERT_EQUAL(SSnetrun.count_network_visitors(), SSnetrun.visitor_limit, "A later native wave replaces departed visitors during the round")

/datum/unit_test/netrun_bot_round_population/Destroy()
	if(original_state)
		for(var/mob/camera/netrun_entity/bot/bot as anything in SSnetrun.bots.Copy())
			qdel(bot)
		for(var/field in original_state)
			SSnetrun.vars[field] = original_state[field]
	return ..()

/// Quiet stations do not accumulate ambient visitors or maintenance replacements.
/datum/unit_test/netrun_bot_round_population/quiet/Run()
	original_state = list()
	for(var/field in list("bots", "bots_enabled", "next_bot_census", "rogue_wave_at", "consoles"))
		original_state[field] = SSnetrun.vars[field]
	SSnetrun.bots = list()
	SSnetrun.consoles = list()
	SSnetrun.bots_enabled = TRUE
	SSnetrun.next_bot_census = world.time
	SSnetrun.rogue_wave_at = world.time - 1
	TEST_ASSERT(!SSnetrun.has_active_netrunners(), "An empty station has no active session")
	SSnetrun.maintain_bots()
	TEST_ASSERT_EQUAL(length(SSnetrun.bots), 0, "Quiet housekeeping cannot create ambient processes")
	TEST_ASSERT_EQUAL(SSnetrun.rogue_wave_at, 0, "Quiet time cannot queue an overdue wave")
	var/datum/netrun_console/circuit = allocate(/datum/netrun_console, allocate(/obj/item), NETRUN_ORIGIN_CIRCUIT)
	circuit.last_ui_at = world.time
	TEST_ASSERT(!SSnetrun.has_active_netrunners(), "An autonomous circuit does not count as a player")
	var/datum/netrun_console/player = allocate(/datum/netrun_console, allocate(/obj/item))
	TEST_ASSERT(!SSnetrun.has_active_netrunners(), "An unused player device does not populate the station")
	player.last_ui_at = world.time
	TEST_ASSERT(SSnetrun.has_active_netrunners(), "A displayed player session enables ambient activity")
