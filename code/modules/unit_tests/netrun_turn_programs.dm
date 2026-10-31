/// Every registry entry supplies integral turn costs and the same metadata to UI.
/datum/unit_test/netrun_turn_program_registry/Run()
	TEST_ASSERT(istype(SSnetrun.get_daemon("buffer"), /datum/netrun_program/daemon), "Daemons inherit the shared executable program type")
	TEST_ASSERT_NULL(SSnetrun.get_program("buffer"), "Passive daemon definitions cannot leak into the active combat registry")
	for(var/list/entry as anything in SSnetrun.program_definitions())
		var/datum/netrun_program/program = SSnetrun.get_program(entry["id"])
		TEST_ASSERT(program.ap_cost >= 1 && program.ap_cost <= 3 && program.ap_cost == round(program.ap_cost), "Every program costs one to three whole action points")
		TEST_ASSERT(program.cooldown_turns >= 0 && program.cooldown_turns == round(program.cooldown_turns), "Turn cooldowns are non-negative whole turns")
		TEST_ASSERT(program.shield_turns >= 1 && program.stun_turns >= 1, "Timed roles have a finite positive turn duration")
		TEST_ASSERT_EQUAL(entry["ap_cost"], program.ap_cost, "Wire metadata describes the actual program cost")
		TEST_ASSERT_EQUAL(entry["cooldown_turns"], program.cooldown_turns, "Wire metadata describes the actual turn cooldown")
		TEST_ASSERT_EQUAL(entry["shield_turns"], program.shield_turns, "Shield duration is explicit data")
		TEST_ASSERT_EQUAL(entry["stun_turns"], program.stun_turns, "Stun duration is explicit data")

/// Universal fallbacks cost no storage; owned programs improve their efficiency.
/datum/unit_test/netrun_turn_program_tradeoffs/Run()
	var/list/builtins = list("sting" = 1, "pulse" = 2, "surge" = 3, "shell" = 1, "mend" = 1)
	for(var/id in builtins)
		var/datum/netrun_program/program = SSnetrun.get_program(id)
		TEST_ASSERT_NOTNULL(program, "The universal action [id] exists in the same registry as files")
		TEST_ASSERT_EQUAL(program.size, 0, "Builtins do not reserve executable memory")
		TEST_ASSERT_EQUAL(program.ap_cost, builtins[id], "The builtin exposes its intended action budget")
	var/datum/netrun_program/sting = SSnetrun.get_program("sting")
	var/datum/netrun_program/needle = SSnetrun.get_program("needle")
	TEST_ASSERT(needle.power > sting.power && needle.ap_cost == sting.ap_cost && needle.size > 0, "An owned quick attack improves the free one at a real memory cost")
	var/datum/netrun_program/pulse = SSnetrun.get_program("pulse")
	var/datum/netrun_program/strike = SSnetrun.get_program("strike")
	TEST_ASSERT(strike.power > pulse.power && strike.ap_cost == pulse.ap_cost, "The ordinary strike remains useful over the medium fallback")
	var/datum/netrun_program/surge = SSnetrun.get_program("surge")
	var/datum/netrun_program/assault = SSnetrun.get_program("assault")
	TEST_ASSERT(assault.power > surge.power && assault.ap_cost == surge.ap_cost, "A paid heavy attack outperforms the universal full-turn attack")
	var/datum/netrun_program/mend = SSnetrun.get_program("mend")
	var/datum/netrun_program/renew = SSnetrun.get_program("renew")
	TEST_ASSERT(renew.power > mend.power && renew.ap_cost == mend.ap_cost && renew.size > 0, "Owned repair improves the weak emergency fallback")
	var/datum/netrun_program/lance = SSnetrun.get_program("lance")
	TEST_ASSERT(lance.power > strike.power && lance.ap_cost == strike.ap_cost && lance.cooldown_turns > strike.cooldown_turns && lance.size > strike.size, "A stronger two-point attack pays with cooldown and storage")
	var/datum/netrun_program/aegis = SSnetrun.get_program("aegis")
	var/datum/netrun_program/shell = SSnetrun.get_program("shell")
	TEST_ASSERT(aegis.power > shell.power && aegis.shield_turns > shell.shield_turns && aegis.ap_cost > shell.ap_cost, "Long heavy protection trades the remaining turn budget for stronger defense")
	var/datum/netrun_program/jam = SSnetrun.get_program("jam")
	TEST_ASSERT(jam.role == NETRUN_PROGRAM_STUN && jam.ap_cost == 1 && jam.cooldown_turns >= 2 && jam.stun_turns == 1, "Low-cost control cannot repeatedly stun for free")

/// Paid content uses independent real files and fits existing physical acquisition media.
/datum/unit_test/netrun_turn_program_files_and_shards/Run()
	for(var/id in list("needle", "lance", "aegis", "renew", "jam"))
		var/datum/netrun_program/program = SSnetrun.get_program(id)
		var/datum/netrun_file/file = netrun_program_file(id)
		TEST_ASSERT(file && file.kind == NETRUN_FILE_PROGRAM && file.content == id, "The new action is represented by an ordinary owned executable")
		TEST_ASSERT_EQUAL(file.size, program.size, "Actual file capacity matches its program definition")
		var/datum/netrun_file/copy = file.copy()
		TEST_ASSERT(copy != file && copy.uid != file.uid && copy.content == id && copy.size == file.size, "Normal copies preserve a program without sharing file identity")
		qdel(copy)
		qdel(file)
	var/list/available = list()
	for(var/shard_type in list(/obj/item/netrun_shard/combat, /obj/item/netrun_shard/assault, /obj/item/netrun_shard/blackout, /obj/item/netrun_shard/fortify))
		var/obj/item/netrun_shard/shard = allocate(shard_type)
		TEST_ASSERT(shard.file_store.used() <= shard.file_store.capacity, "Every existing combat medium fits its expanded real preload")
		for(var/datum/netrun_file/file as anything in shard.file_store.files)
			available |= file.content
	for(var/id in list("needle", "lance", "aegis", "renew", "jam"))
		TEST_ASSERT(id in available, "Every new paid action is obtainable on ordinary combat media")

/// Profile variation equips the same registry files and never exceeds actual memory.
/datum/unit_test/netrun_turn_program_profile_memory/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	for(var/id in list(NETRUN_BOT_SENTINEL, NETRUN_BOT_MENDER, "collector", "hacker", "breacher", NETRUN_BOT_RAIDER))
		var/datum/netrun_bot_program/profile = SSnetrun.get_bot_program(id)
		var/mob/camera/netrun_entity/bot/bot = allocate(/mob/camera/netrun_entity/bot, run_loc_floor_bottom_left, scene.node_a, id)
		var/list/equipped = list()
		for(var/datum/netrun_file/file as anything in bot.console.inventory.local_store.files)
			if(file.kind == NETRUN_FILE_PROGRAM)
				equipped |= file.content
		for(var/program_id in profile.programs)
			TEST_ASSERT(program_id in equipped, "The declared program [program_id] was equipped as a real file")
		TEST_ASSERT(bot.console.inventory.local_store.used() <= profile.storage, "The varied profile remains within its actual memory budget")
		qdel(bot)
	for(var/kind in list(NETRUN_ICE_SENTRY, NETRUN_ICE_HUNTER, NETRUN_ICE_BLACK))
		var/datum/netrun_ice_profile/profile = SSnetrun.get_ice_profile(kind)
		var/required = 0
		for(var/id in profile.program_ids)
			var/datum/netrun_program/program = SSnetrun.get_program(id)
			TEST_ASSERT_NOTNULL(program, "Every ICE loadout entry resolves through the common action registry")
			required += program.size
		TEST_ASSERT(required <= profile.storage, "ICE can really own all declared actions without preload overflow")

/// No initial id: this test implementation is never discovered as playable content.
/datum/netrun_program/unit_test_override
	role = "unit_test_override"
	power = 91
	ap_cost = 1
	cooldown_turns = 1
	trace = 0
	var/applications = 0
	var/status_checks = 0
	var/status_applications = 0
	var/status_allowed = TRUE
	var/messages = 0
	var/last_executable_name
	var/last_damage_scale
	var/datum/netrun_console/last_attacker

/datum/netrun_program/unit_test_override/apply(datum/target, datum/netrun_console/attacker, damage_scale = 1)
	applications++
	last_attacker = attacker
	last_damage_scale = damage_scale
	netrun_combatant_hit(target, round(9 * damage_scale), "custom test program", attacker)

/datum/netrun_program/unit_test_override/combat_message(target_name, executable_name)
	messages++
	last_executable_name = executable_name
	return "[executable_name]: custom effect delivered to [target_name]."

/datum/netrun_program/unit_test_override/can_apply_status(datum/netrun_combat_encounter/encounter, datum/target)
	status_checks++
	return status_allowed

/datum/netrun_program/unit_test_override/apply_status(datum/netrun_combat_encounter/encounter, datum/target)
	status_applications++

/// Restore even when an assertion returns from Run() before normal cleanup.
/datum/netrun_program_registry_test_fixture
	var/id
	var/datum/netrun_program/program
	var/datum/netrun_program/previous_program

/datum/netrun_program_registry_test_fixture/New(datum/netrun_program/definition, program_id)
	program = definition
	id = program_id
	SSnetrun.get_program(null)
	previous_program = SSnetrun.programs[id]
	program.id = id
	SSnetrun.programs[id] = program

/datum/netrun_program_registry_test_fixture/Destroy()
	if(SSnetrun.programs[id] == program)
		if(previous_program)
			SSnetrun.programs[id] = previous_program
		else
			SSnetrun.programs -= id
	program = null
	previous_program = null
	return ..()

/// An unknown role executes its own hooks through an ordinary owned program file.
/datum/unit_test/netrun_turn_program_console_polymorphism/Run()
	var/datum/netrun_program/unit_test_override/program = allocate(/datum/netrun_program/unit_test_override)
	allocate(/datum/netrun_program_registry_test_fixture, program, "unit-test-program-console")
	program.consumable = TRUE
	program.status_allowed = FALSE
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/first = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	var/mob/camera/netrun_entity/second = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	var/datum/netrun_file/file = netrun_program_file(program.id)
	file.name = "renamed-test.card"
	var/file_uid = file.uid
	TEST_ASSERT(first.console.store_file(file), "The custom executable is a real owned file")
	TEST_ASSERT(!first.console.program_use(file_uid, REF(second)), "A program's own status policy can reject native admission")
	var/datum/netrun_combat_encounter/encounter = first.console.get_combat_encounter()
	TEST_ASSERT(program.status_checks > 0 && !program.applications, "Rejected status is checked polymorphically before delivery")
	TEST_ASSERT_EQUAL(encounter.remaining_ap(first), NETRUN_COMBAT_AP, "Custom rejection spends no action points")
	TEST_ASSERT_EQUAL(encounter.cooldown_remaining(first, program), 0, "Custom rejection starts no turn cooldown")
	TEST_ASSERT_EQUAL(first.console.find_local_file(file_uid), file, "Custom rejection preserves the consumable file")
	program.status_allowed = TRUE
	var/health_before = second.integrity
	TEST_ASSERT(first.console.program_use(file_uid, REF(second)), "A custom role runs through the native player entrypoint")
	TEST_ASSERT_EQUAL(second.integrity, health_before - 9, "The override supplies the effect independently of role and power metadata")
	TEST_ASSERT_EQUAL(program.applications, 1, "Player delivery invokes the custom effect exactly once")
	TEST_ASSERT_EQUAL(program.last_attacker, first.console, "The custom effect receives the actual attacking console")
	TEST_ASSERT_EQUAL(program.last_damage_scale, 1, "Player delivery uses the ordinary damage scale")
	TEST_ASSERT_EQUAL(program.status_applications, 1, "Player delivery invokes the custom turn status hook")
	TEST_ASSERT_EQUAL(program.messages, 1, "Player combat feedback comes from the custom program")
	TEST_ASSERT_EQUAL(program.last_executable_name, "renamed-test.card", "Program feedback preserves the actual executable's name")
	TEST_ASSERT_EQUAL(encounter.remaining_ap(first), NETRUN_COMBAT_AP - program.ap_cost, "Custom execution pays the ordinary action cost")
	TEST_ASSERT(encounter.cooldown_remaining(first, program) > 0, "Custom execution starts the ordinary turn cooldown")
	TEST_ASSERT_NULL(first.console.find_local_file(file_uid), "Successful custom execution consumes its actual card")
	var/custom_message_found = FALSE
	for(var/list/entry as anything in first.console.log)
		if(findtext(entry["text"], "renamed-test.card: custom effect delivered"))
			custom_message_found = TRUE
	TEST_ASSERT(custom_message_found, "The player's combat log contains the overridden message")

/// ICE preserves its native telegraph and cost while delivering the same custom object.
/datum/unit_test/netrun_turn_program_ice_polymorphism/Run()
	var/datum/netrun_program/unit_test_override/program = allocate(/datum/netrun_program/unit_test_override)
	allocate(/datum/netrun_program_registry_test_fixture, program, "unit-test-program-ice")
	program.ap_cost = 2
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity, run_loc_floor_bottom_left, scene.node_a)
	var/datum/netrun_ice/ice = allocate(/datum/netrun_ice, scene.node_a)
	TEST_ASSERT(ice.agent.memory.insert(program.create_file()), "The custom executable occupies real ICE memory")
	ice.program_ids = list(program.id)
	ice.damage_factor = 0.5
	TEST_ASSERT(ice.register_enemy(entity.console), "The resident explicitly provokes ICE before it can become a legal combat target")
	var/health_before = entity.integrity
	TEST_ASSERT(ice.begin_program(program, entity), "ICE prepares an installed custom role through native admission")
	var/datum/netrun_combat_encounter/encounter = ice.get_combat_encounter()
	TEST_ASSERT(encounter.deferred && program.status_checks > 0, "Native preparation checks the custom status hook and reserves the turn")
	TEST_ASSERT_EQUAL(entity.integrity, health_before, "Preparation cannot apply the custom effect early")
	TEST_ASSERT_EQUAL(program.applications, 0, "Preparing a custom program does not invoke its effect")
	ice.resolve_program()
	TEST_ASSERT_EQUAL(program.applications, 0, "Resolving before the telegraph expires does not invoke the effect")
	var/ap_after_launch = encounter.remaining_ap(ice)
	ice.attack_at = world.time
	ice.resolve_program()
	TEST_ASSERT_EQUAL(entity.integrity, health_before - round(9 * ice.damage_factor), "ICE delivers the custom effect with its own damage scale")
	TEST_ASSERT_EQUAL(program.applications, 1, "ICE invokes the same program override exactly once")
	TEST_ASSERT_NULL(program.last_attacker, "ICE delivery does not invent an attacking player console")
	TEST_ASSERT_EQUAL(program.last_damage_scale, ice.damage_factor, "ICE forwards its own damage scale to the program object")
	TEST_ASSERT_EQUAL(program.status_applications, 1, "ICE delivery invokes the custom turn status hook")
	TEST_ASSERT_EQUAL(encounter.remaining_ap(ice), ap_after_launch, "Resolving a custom effect cannot spend AP twice")
	TEST_ASSERT(encounter.cooldown_remaining(ice, program) > 0, "Custom ICE programs retain their turn cooldown")
	TEST_ASSERT_NULL(ice.pending_program, "Custom delivery releases the native pending program")
	TEST_ASSERT(!encounter.deferred, "Custom delivery releases its native preparation lock")

/// Roles describe metadata; only subtype methods define effects, without changing shared definitions.
/datum/unit_test/netrun_turn_program_base_and_shared_definition/Run()
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity)
	var/datum/netrun_program/base = allocate(/datum/netrun_program)
	base.role = NETRUN_PROGRAM_ATTACK
	var/health_before = entity.integrity
	netrun_apply_program(base, entity, null)
	TEST_ASSERT_EQUAL(entity.integrity, health_before, "An unimplemented base program cannot gain an effect from its role")
	var/datum/netrun_program/strike = SSnetrun.get_program("strike")
	var/original_power = strike.power
	var/original_cooldown = strike.cooldown
	netrun_apply_program(strike, entity, null, 0.5)
	TEST_ASSERT_EQUAL(entity.integrity, health_before - round(original_power * 0.5), "The compatibility helper invokes the concrete program's scaled effect")
	netrun_apply_program(strike, entity, null)
	TEST_ASSERT_EQUAL(entity.integrity, health_before - round(original_power * 0.5) - original_power, "A later ordinary cast retains the original shared effect strength")
	TEST_ASSERT_EQUAL(strike.power, original_power, "Per-cast scaling cannot mutate the shared program definition")
	TEST_ASSERT_EQUAL(strike.cooldown, original_cooldown, "Execution cannot mutate the shared cooldown definition")
