/// Native outer-wall attacks admit a battery; idle decision time cannot fire or heal it.
/datum/unit_test/netrun_turn_fortress_siege/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/datum/netrun_fortress/fortress = new(scene.node_b, "Turn battery", NETRUN_FACTION_ROGUE)
	scene.node_b.fortress = fortress
	var/datum/netrun_fortress_module/wall = fortress.add_module(NETRUN_FORT_WALL, TRUE)
	fortress.add_module(NETRUN_FORT_TURRET, TRUE)
	fortress.add_module(NETRUN_FORT_REGEN, TRUE)
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.apc_node)
	TEST_ASSERT(entity.console.store_file(scene.key_file()), "The siege uses a real route through the neighbouring APC")
	TEST_ASSERT(entity.console.program_use("builtin:sting", REF(wall)), "The actual outer-wall program starts a legal adjacent siege")
	var/datum/netrun_combat_encounter/encounter = entity.console.get_combat_encounter()
	TEST_ASSERT(encounter?.contains(fortress) && encounter.has_turn(entity), "One fortress battery joins the initiating player's queue")
	TEST_ASSERT(fortress.valid_turn_siege(entity), "Admission records the exact live neighbouring source without granting entry")
	TEST_ASSERT_EQUAL(entity.host_node, scene.apc_node, "Siege admission does not move the process into the defended node")
	fortress.besiegers[WEAKREF(entity)] = world.time - 21 SECONDS
	var/list/lease = fortress.turn_siege_leases[WEAKREF(entity)]
	lease["until"] = world.time - 1
	TEST_ASSERT(fortress.valid_turn_siege(entity) && fortress.valid_turret_target(entity), "Thinking through several turns cannot expire a live siege's native target lease")
	var/wall_before = wall.integrity
	var/health_before = entity.integrity
	for(var/pass in 1 to 8)
		fortress.process_tick()
	TEST_ASSERT_EQUAL(wall.integrity, wall_before, "A regenerator cannot heal repeatedly while the attacker is deciding")
	TEST_ASSERT_EQUAL(entity.integrity, health_before, "A turret cannot strike between turns")
	TEST_ASSERT_EQUAL(fortress.next_deadline(), INFINITY, "An off-turn battery schedules no polling or combat deadline")
	TEST_ASSERT(encounter.pass(entity), "The attacker yields to the battery")
	SSnetrun.get_task_scheduler().cancel("fortress", fortress)
	fortress.process_tick()
	TEST_ASSERT_EQUAL(wall.integrity, min(wall.max_integrity, wall_before + 6), "The battery spends one AP for exactly its native repair amount")
	TEST_ASSERT(fortress.turret_fire_at && encounter.deferred && encounter.member(fortress).ap == 0, "One AP of regeneration and two AP of volley reserve the full turn")
	TEST_ASSERT_EQUAL(entity.integrity, health_before, "Committing a volley retains its native preparation window")
	fortress.turret_fire_at = world.time
	fortress.process_tick()
	TEST_ASSERT(entity.integrity < health_before && encounter.has_turn(entity), "The prepared volley applies before the battery yields")
	var/after_volley = entity.integrity
	fortress.process_tick()
	TEST_ASSERT_EQUAL(entity.integrity, after_volley, "Another fortress tick cannot fire again in the player's turn")
	scene.apc_node.offline_until = world.time + 1 MINUTES
	TEST_ASSERT(!fortress.valid_turn_siege(entity) && !encounter.member(entity).valid(), "A lost native direct link invalidates the admission lease")
	scene.apc_node.offline_until = 0
	entity.enter_node(scene.node_a)
	TEST_ASSERT(QDELETED(encounter) && !fortress.get_combat_encounter(), "Leaving the admitted siege source releases the battery's encounter")

/// Turret jamming consumes a battery turn; destroying its last active module removes the actor.
/datum/unit_test/netrun_turn_fortress_stun_and_cleanup/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/datum/netrun_fortress/fortress = new(scene.node_b, "Jammed battery", NETRUN_FACTION_ROGUE)
	scene.node_b.fortress = fortress
	var/datum/netrun_fortress_module/turret = fortress.add_module(NETRUN_FORT_TURRET, TRUE)
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_b)
	var/datum/netrun_combat_encounter/encounter = scene.node_b.get_combat_encounter()
	TEST_ASSERT(encounter.admit(entity, 1, turret), "The native turret maps to its one active battery")
	var/datum/netrun_program/stun = SSnetrun.get_program("blackout")
	turret.jam(stun.power)
	encounter.apply_program_status(stun, turret)
	TEST_ASSERT_EQUAL(turret.jammed_until, INFINITY, "A jam cannot expire during another actor's decision countdown")
	encounter.pass(entity)
	TEST_ASSERT(encounter.has_turn(entity) && !turret.is_jammed(), "The battery's skipped turn consumes only its owned jam sentinel")
	TEST_ASSERT(!encounter.can_apply_program_status(stun, turret), "The battery shares the bounded anti-chain-stun rule")
	TEST_ASSERT(!fortress.turret_fire_at, "A skipped battery turn launches no hidden volley")
	turret.take_damage(10000, "test", entity.console)
	TEST_ASSERT(QDELETED(encounter), "Destroying the last active capability removes the battery immediately")
	TEST_ASSERT_NULL(entity.console.get_combat_encounter(), "The surviving process is released from the dead battery's queue")
	TEST_ASSERT_NULL(fortress.get_combat_encounter(), "The fortress keeps no stale controller binding")

/// Purely passive works remain damage targets without acquiring their own AP turn.
/datum/unit_test/netrun_turn_fortress_passive_walls/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/datum/netrun_fortress/fortress = new(scene.node_b, "Passive wall", NETRUN_FACTION_ROGUE)
	scene.node_b.fortress = fortress
	var/datum/netrun_fortress_module/wall = fortress.add_module(NETRUN_FORT_WALL, TRUE)
	TEST_ASSERT_NULL(netrun_turn_actor(wall), "A wall without an active battery is not an autonomous participant")
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.apc_node)
	TEST_ASSERT(entity.console.store_file(scene.key_file()), "A passive siege still uses a native reachable route")
	TEST_ASSERT(entity.console.program_use("builtin:sting", REF(wall)), "The existing outer-wall damage contract remains available")
	TEST_ASSERT(wall.integrity < wall.max_integrity, "The real program damages the passive module")
	TEST_ASSERT_NULL(entity.console.get_combat_encounter(), "A passive wall creates no artificial opposing turn")

/// Dying-controller teardown cancels its native volley despite weak resolve hiding it.
/datum/unit_test/netrun_turn_fortress_pending_teardown/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/datum/netrun_fortress/fortress = new(scene.node_b, "Cancelled battery", NETRUN_FACTION_ROGUE)
	scene.node_b.fortress = fortress
	fortress.add_module(NETRUN_FORT_TURRET, TRUE)
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_b)
	var/health_before = entity.integrity
	fortress.process_tick()
	var/datum/netrun_combat_encounter/encounter = fortress.get_combat_encounter()
	TEST_ASSERT(encounter?.has_turn(fortress) && encounter.deferred && fortress.turret_fire_at, "The native battery reserves a real pending volley")
	entity.enter_node(scene.apc_node)
	TEST_ASSERT(QDELETED(encounter), "The final opponent's forced departure destroys the controller")
	TEST_ASSERT(!fortress.turret_fire_at && !fortress.turret_target_ref, "Controller destruction cancels its already prepared native volley")
	TEST_ASSERT(!fortress.combat_encounter_ref && !entity.console.combat_encounter_ref, "Teardown clears exact weak bindings without resolving the dying controller")
	fortress.process_tick()
	TEST_ASSERT_EQUAL(entity.integrity, health_before, "A later native fortress tick cannot deliver the cancelled volley")

/// Damage during a battery turn must not strand a bot in an expiring native trap stun.
/datum/unit_test/netrun_turn_fortress_bot_trap_recovery/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/datum/netrun_fortress/fortress = new(scene.node_b, "Trap battery", NETRUN_FACTION_ROGUE)
	scene.node_b.fortress = fortress
	var/datum/netrun_fortress_module/trap = fortress.add_module(NETRUN_FORT_TRAP, TRUE)
	var/datum/netrun_fortress_module/turret = fortress.add_module(NETRUN_FORT_TURRET, TRUE)
	var/mob/camera/netrun_entity/bot/bot = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, NETRUN_BOT_CUSTODIAN)
	bot.enter_node(scene.node_b)
	var/datum/netrun_entity_module/bot_stun/stun = bot.entity_modules["bot_stun"]
	var/recovery_timer = stun.stun_timer
	TEST_ASSERT(bot.is_stunned() && recovery_timer, "The actual arrival trap owns a finite recovery timer")
	fortress.process_tick()
	var/datum/netrun_combat_encounter/encounter = fortress.get_combat_encounter()
	TEST_ASSERT(encounter?.has_turn(fortress) && fortress.turret_fire_at, "The native battery starts its opening volley")
	fortress.turret_fire_at = world.time
	fortress.process_tick()
	TEST_ASSERT(bot.is_stunned(), "The volley resolves before the native trap stun expires")
	TEST_ASSERT_EQUAL(stun.stun_timer, recovery_timer, "Combat damage preserves the exact finite recovery deadline")
	TEST_ASSERT(timeleft(stun.stun_timer) <= 3 SECONDS, "Recovery does not wait for the twelve-second decision deadline")
	fortress.process_tick()
	TEST_ASSERT(encounter.has_turn(bot), "The battery yields its unused final AP to the trapped bot")
	bot.brain.think()
	TEST_ASSERT_EQUAL(encounter.remaining_ap(bot), NETRUN_COMBAT_AP, "A still-stunned bot cannot spend AP")
	deltimer(stun.stun_timer)
	bot.combat_stun_until = world.time
	SSnetrun.get_task_scheduler().cancel("bot", bot.brain)
	bot.brain.clear_timer()
	stun.on_recovered()
	TEST_ASSERT(SSnetrun.get_task_scheduler().by_key["bot:[REF(bot.brain)]"], "Native recovery queues the bot without polling or a combat timeout")
	// Recovery must spend the current turn. Target ranking legitimately prefers
	// the 60-HP trap over the 90-HP turret; this test does not prescribe that policy.
	var/before = trap.integrity + turret.integrity
	var/ap_before = encounter.remaining_ap(bot)
	bot.brain.think()
	TEST_ASSERT(trap.integrity + turret.integrity < before, "The recovered bot must deliver a native attack against the battery")
	TEST_ASSERT(encounter.remaining_ap(bot) < ap_before, "Recovery must spend the bot's current AP without waiting for another turn")
	encounter.apply_program_status(SSnetrun.get_program("blackout"), bot)
	bot.combat_changed()
	TEST_ASSERT_EQUAL(bot.combat_stun_until, INFINITY, "A turn-owned stun still uses its native sentinel")
	TEST_ASSERT_NULL(stun.stun_timer, "A turn-owned stun does not acquire a real-time recovery timer")

/// A hostile battery is an ordinary AI damage target, including after it attacks first.
/datum/unit_test/netrun_turn_fortress_bot_retaliation/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/datum/netrun_fortress/fortress = new(scene.node_b, "Hostile battery", NETRUN_FACTION_ROGUE)
	scene.node_b.fortress = fortress
	var/datum/netrun_fortress_module/turret = fortress.add_module(NETRUN_FORT_TURRET, TRUE)
	var/mob/camera/netrun_entity/bot/bot = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_b, NETRUN_BOT_CUSTODIAN)
	fortress.process_tick()
	var/datum/netrun_combat_encounter/encounter = fortress.get_combat_encounter()
	TEST_ASSERT(encounter?.has_turn(fortress), "The hostile battery initiates the actual encounter")
	fortress.turret_fire_at = world.time
	fortress.process_tick()
	fortress.process_tick()
	TEST_ASSERT(encounter.has_turn(bot), "The bot gets its normal reply turn")
	TEST_ASSERT(turret in bot.brain.hostiles(), "The bot recognizes the hostile turret")
	var/before = turret.integrity
	bot.brain.think()
	TEST_ASSERT(turret.integrity < before, "The bot delivers a real native attack instead of passing")

/// Passive works can be attacked without creating a singleton encounter or a mob telegraph.
/datum/unit_test/netrun_turn_fortress_bot_passive_attack/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/datum/netrun_fortress/fortress = new(scene.node_b, "Passive hostile wall", NETRUN_FACTION_ROGUE)
	scene.node_b.fortress = fortress
	var/datum/netrun_fortress_module/wall = fortress.add_module(NETRUN_FORT_WALL, TRUE)
	var/mob/camera/netrun_entity/bot/bot = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_b, NETRUN_BOT_CUSTODIAN)
	bot.brain.think()
	TEST_ASSERT(wall.integrity < wall.max_integrity, "A passive hostile structure receives the bot's real attack")
	TEST_ASSERT_NULL(bot.console.get_combat_encounter(), "Passive structures grant no artificial AI turns")
	TEST_ASSERT_NULL(scene.node_b.combat_encounter, "A passive attack leaves no singleton controller")
	TEST_ASSERT_NULL(bot.brain.pending_attack_ref, "A structure does not enter the player-only telegraph path")

/// Closed gates can be besieged through a real direct edge without moving or bypassing walls.
/datum/unit_test/netrun_turn_fortress_bot_adjacent_siege/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/datum/netrun_fortress/fortress = new(scene.node_b, "Defended gate", NETRUN_FACTION_STATION)
	scene.node_b.fortress = fortress
	var/datum/netrun_fortress_module/wall = fortress.add_module(NETRUN_FORT_WALL, TRUE)
	var/datum/netrun_fortress_module/gate = fortress.add_module(NETRUN_FORT_GATE, TRUE)
	var/datum/netrun_fortress_module/turret = fortress.add_module(NETRUN_FORT_TURRET, TRUE)
	var/mob/camera/netrun_entity/bot/bot = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.apc_node, NETRUN_BOT_RAIDER)
	TEST_ASSERT(bot.console.store_file(scene.key_file()), "A real LAN key grants the route independently of the gate")
	// Isolate the siege from the visitor's separate bootstrap hack and its source-node ICE.
	bot.console.access_session.grant_node(scene.apc_node, NETRUN_ACCESS_USER)
	TEST_ASSERT(fortress.gate_blocks(bot.console), "The closed fortress gate blocks this otherwise keyed bot")
	TEST_ASSERT(!bot.can_enter(scene.node_b), "The native fortress gate prevents entry")
	var/list/foes = bot.brain.hostiles()
	TEST_ASSERT((wall in foes) && (gate in foes) && !(turret in foes), "The AI sees only the exposed outer works")
	bot.brain.think()
	TEST_ASSERT(wall.integrity < wall.max_integrity || gate.integrity < gate.max_integrity, "An ordinary bot program damages the exposed works")
	TEST_ASSERT_EQUAL(turret.integrity, turret.max_integrity, "Standing walls keep the inner turret protected")
	var/datum/netrun_combat_encounter/encounter = bot.console.get_combat_encounter()
	TEST_ASSERT(encounter?.node_ref.resolve() == scene.node_b && encounter.contains(fortress), "Native admission anchors the siege to the defended node")
	TEST_ASSERT(fortress.valid_turn_siege(bot), "The bot acquires only the real adjacent siege lease")
	TEST_ASSERT_EQUAL(bot.host_node, scene.apc_node, "Attacking a gate never moves the bot through it")
	TEST_ASSERT_NULL(scene.apc_node.combat_encounter, "The source node does not retain a competing singleton encounter")
	var/mob/camera/netrun_entity/bot/local_enemy = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.apc_node, NETRUN_BOT_CUSTODIAN)
	local_enemy.integrity = 1
	TEST_ASSERT(!(local_enemy in bot.brain.hostiles()), "An active remote siege excludes targets in the source node")
	TEST_ASSERT_EQUAL(length(bot.brain.hostiles()), 2, "Only native reachable outer works remain legal siege targets")

/// Suppression is useful against a working turret, not passive fortress modules.
/datum/unit_test/netrun_turn_fortress_bot_control_targets/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/datum/netrun_fortress/fortress = new(scene.node_b, "Control targets", NETRUN_FACTION_ROGUE)
	scene.node_b.fortress = fortress
	var/datum/netrun_fortress_module/wall = fortress.add_module(NETRUN_FORT_WALL, TRUE)
	var/datum/netrun_fortress_module/turret = fortress.add_module(NETRUN_FORT_TURRET, TRUE)
	var/mob/camera/netrun_entity/bot/bot = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_b, NETRUN_BOT_SENTINEL)
	var/datum/netrun_combat_encounter/encounter = scene.node_b.get_combat_encounter()
	TEST_ASSERT(encounter.admit(bot, 1, wall), "The bot starts an ordinary local fortress encounter")
	bot.brain.combat_target_ref = WEAKREF(wall)
	bot.brain.think()
	TEST_ASSERT(wall.integrity < wall.max_integrity, "A wall receives damage instead of an ineffective control program")
	TEST_ASSERT_NULL(bot.brain.controlled_target_ref, "The bot does not claim to have suppressed a passive wall")
	TEST_ASSERT_EQUAL(encounter.cooldown_remaining(bot, SSnetrun.get_program("blackout")), 0, "Wall attacks conserve the real suppression program")
	TEST_ASSERT(encounter.pass(bot) && encounter.pass(fortress), "Both actors complete their first decisions")
	bot.brain.combat_target_ref = WEAKREF(turret)
	bot.brain.think()
	TEST_ASSERT(turret.is_jammed() && bot.brain.controlled_target_ref?.resolve() == turret, "A working turret remains a useful native control target")

/// Friendly structures and fortresses beyond siege range must never become autonomous targets.
/datum/unit_test/netrun_turn_fortress_bot_target_permissions/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/datum/netrun_fortress/fortress = new(scene.node_b, "Friendly wall", NETRUN_FACTION_ROGUE)
	scene.node_b.fortress = fortress
	var/datum/netrun_fortress_module/wall = fortress.add_module(NETRUN_FORT_WALL, TRUE)
	var/mob/camera/netrun_entity/bot/bot = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_b, NETRUN_BOT_RAIDER)
	TEST_ASSERT(!(wall in bot.brain.hostiles()), "Rogue processes do not attack their own faction's fortress")
	bot.enter_node(scene.node_a)
	fortress.faction = NETRUN_FACTION_STATION
	TEST_ASSERT(!(wall in bot.brain.hostiles()), "An enemy fortress two hops away is outside native siege range")
	bot.enter_node(scene.apc_node)
	TEST_ASSERT(wall in bot.brain.hostiles(), "The same fortress becomes a legal target across one direct edge")
	scene.node_b.offline_until = world.time + 1 MINUTES
	TEST_ASSERT(!(wall in bot.brain.hostiles()), "An offline neighbouring node is not a valid siege target")
	scene.node_b.offline_until = 0
	var/mob/camera/netrun_entity/bot/custodian = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_b, NETRUN_BOT_CUSTODIAN)
	TEST_ASSERT(!(wall in custodian.brain.hostiles()), "Sanctioned maintenance respects a friendly station fortress")

/// A disabled battery yields immediately instead of retaining an empty twelve-second turn.
/datum/unit_test/netrun_turn_fortress_offline_yields/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/datum/netrun_fortress/fortress = new(scene.node_b, "Offline battery", NETRUN_FACTION_ROGUE)
	scene.node_b.fortress = fortress
	var/datum/netrun_fortress_module/turret = fortress.add_module(NETRUN_FORT_TURRET, TRUE)
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_b)
	var/datum/netrun_combat_encounter/encounter = scene.node_b.get_combat_encounter()
	TEST_ASSERT(encounter.admit(entity, 1, turret) && encounter.pass(entity), "The native queue reaches the battery's turn")
	scene.node_b.offline_until = world.time + 1 MINUTES
	fortress.process_tick()
	TEST_ASSERT(encounter.has_turn(entity), "An offline battery passes without waiting for its decision timeout")
	TEST_ASSERT(!fortress.turret_fire_at && !encounter.deferred, "Yielding an offline battery leaves no pending volley")

/// Opening warnings preserve counterplay; later volleys use the same short turn windup as ICE.
/datum/unit_test/netrun_turn_fortress_volley_tempo/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/datum/netrun_fortress/fortress = new(scene.node_b, "Paced battery", NETRUN_FACTION_ROGUE)
	scene.node_b.fortress = fortress
	fortress.add_module(NETRUN_FORT_TURRET, TRUE)
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_b)
	fortress.process_tick()
	var/datum/netrun_combat_encounter/encounter = fortress.get_combat_encounter()
	TEST_ASSERT_EQUAL(fortress.turret_fire_at - world.time, NETRUN_ICE_MIN_TELEGRAPH, "The opening volley retains its full native reaction window")
	fortress.turret_fire_at = world.time
	fortress.process_tick()
	fortress.process_tick()
	TEST_ASSERT(encounter.has_turn(entity) && encounter.pass(entity), "The next battery turn follows a real opposing decision")
	fortress.process_tick()
	TEST_ASSERT_EQUAL(fortress.turret_fire_at - world.time, NETRUN_ICE_COMBAT_TELEGRAPH, "Subsequent volleys do not repeat the out-of-combat warning delay")
