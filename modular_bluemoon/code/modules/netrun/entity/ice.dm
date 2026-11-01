/**
 * ICE (Intrusion Countermeasure) - враждебный сетевой процесс.
 *
 * Профили защиты:
 *  - СТОРОЖ (sentry): закреплён за узлом, атакует несанкционированных гостей и
 *    поднимает трассировку тем, кто ломает его узел.
 *  - ОХОТНИК (hunter): путешествует по сети, преследует нарушителей по графу узлов
 *    и бьёт их, догнав. Живёт ограниченное время без целей.
 *  - ЧЁРНЫЙ ЛЁД (black): нелегальная защита с нейронной обратной связью.
 *
 * ICE - лёгкий датум, а не моб: он не смотрит камерами и не говорит, только дерётся.
 * Поведение собирается netrun_ice_agent и выполняется в бюджете SSnetrun.
 */
/datum/netrun_ice
	var/last_netrun_tick = 0 // scheduler
	var/datum/netrun_ice_reaction/reaction
	var/datum/netrun_ice_agent/agent
	var/datum/weakref/deployer_ref
	var/datum/weakref/deployer_principal_ref
	/// Reconnectable personal guards must not become an unlimited salvage source.
	var/drops_loot = TRUE
	/// Only a guard raised by an intrusion uses the dormant-nest lifecycle.
	var/reactive = FALSE
	var/dormant = FALSE
	var/reactive_sleep_at = 0
	var/reactive_quiet_timeout = 45 SECONDS
	var/name = "ICE"
	var/datum/component/netrun_node/node
	var/kind = NETRUN_ICE_SENTRY
	var/integrity = 90
	var/max_integrity = 90
	/// ICE hits softer than a runner with the same program, so a dive is survivable.
	var/damage_factor = 0.78
	/// Programs are registry definitions, with the same power and cooldown as player files.
	var/list/program_ids = list("strike", "barrier", "trace")
	var/list/program_cd = list()
	var/next_attack = 0
	var/datum/netrun_program/pending_program
	var/datum/weakref/pending_target_ref
	/// A cancelled breach cannot pass its old incoming trace on to a new attempt.
	var/datum/weakref/pending_breach_ref
	var/datum/weakref/enemy_ref
	var/attack_at = 0
	var/next_ai = 0
	/// Сторож: узел, который он охраняет (чтобы вернуться)
	var/datum/weakref/anchor_ref
	/// Охотник: сколько тиков без цели он ещё проживёт
	var/patrol_life = 40
	/// Персистентный патруль (с начала раунда) не сворачивается без цели и роняет ключ своей ЛВС.
	var/persistent = FALSE
	var/patrol_network_id
	var/hop_cooldown = 0
	/// Idle patrols visit adjacent devices without a station-wide target search.
	var/list/patrol_visits = list()
	var/patrol_visit = 0
	var/idle_expires_at = 0
	// Боевые состояния (как у сущностей)
	var/combat_stun_until = 0
	var/combat_shield_until = 0
	var/combat_shield_factor = 1

/datum/netrun_ice/New(datum/component/netrun_node/start, ice_kind)
	last_netrun_tick = world.time
	reaction = new(src)
	if(ice_kind)
		kind = ice_kind
	var/datum/netrun_ice_profile/profile = SSnetrun.get_ice_profile(kind)
	name = profile.name
	integrity = profile.integrity
	max_integrity = profile.integrity
	damage_factor = profile.damage_factor
	program_ids = profile.program_ids.Copy()
	agent = new(src, profile)
	if(kind == NETRUN_ICE_HUNTER)
		idle_expires_at = world.time + patrol_life * (1 SECONDS)
	SSnetrun.ice_processes += src
	if(profile.illegal)
		SSnetrun.illegal_ice |= src
	if(start)
		enter_node(start)
		anchor_ref = WEAKREF(start)

/datum/netrun_ice/Destroy()
	SSnetrun.unregister_hunter(src)
	QDEL_NULL(reaction)
	QDEL_NULL(agent)
	deployer_ref = null
	deployer_principal_ref = null
	cancel_program()
	SSnetrun.ice_processes -= src
	SSnetrun.illegal_ice -= src
	SSnetrun.task_scheduler?.cancel("ice", src)
	leave_node()
	anchor_ref = null
	return ..()

/datum/netrun_ice/proc/anchor()
	return anchor_ref?.resolve()

/datum/netrun_ice/proc/enter_node(datum/component/netrun_node/new_node)
	if(!new_node)
		return FALSE
	leave_node()
	node = new_node
	if(kind == NETRUN_ICE_HUNTER)
		if(!patrol_network_id)
			patrol_network_id = new_node.network?.id
		SSnetrun.register_hunter(src)
		patrol_visits[new_node.address] = ++patrol_visit
	LAZYADD(new_node.netrun_ice, src)
	new_node.notify_changed(NETRUN_CHANGED_OCCUPANTS)
	SEND_SIGNAL(src, COMSIG_NETRUN_ICE_NODE_CHANGED, null, new_node)
	if(length(new_node.entities) || length(new_node.netrun_ice) > 1)
		new_node.wake_defenses()
	return TRUE

/datum/netrun_ice/proc/leave_node()
	cancel_program()
	if(!node)
		return
	var/datum/component/netrun_node/old_node = node
	LAZYREMOVE(node.netrun_ice, src)
	old_node.notify_changed(NETRUN_CHANGED_OCCUPANTS)
	node = null
	SEND_SIGNAL(src, COMSIG_NETRUN_ICE_NODE_CHANGED, old_node, null)

/// Узел уничтожен: сторож гибнет вместе с ним, охотник пробует перепрыгнуть.
/datum/netrun_ice/proc/host_lost()
	var/datum/netrun_network/network = defense_network()
	leave_node()
	if(kind != NETRUN_ICE_HUNTER)
		qdel(src)
		return
	var/list/candidates = list()
	for(var/datum/component/netrun_node/candidate as anything in network?.nodes)
		if(candidate.is_online() && !QDELETED(candidate.parent))
			candidates += candidate
	if(!length(candidates))
		qdel(src)
		return
	enter_node(pick(candidates))

// MARK: Боевой интерфейс

/datum/netrun_ice/proc/combat_name()
	return name

/datum/netrun_ice/proc/program_payload()
	. = list()
	var/datum/netrun_combat_encounter/encounter = get_combat_encounter()
	for(var/id in program_ids)
		var/datum/netrun_program/program = SSnetrun.get_program(id)
		if(!program)
			continue
		var/list/entry = program.ui_entry()
		entry["ready_in"] = max(0, CEILING(((program_cd[id] || 0) - world.time) / (1 SECONDS), 0.1))
		if(encounter?.active)
			entry["ready_in"] = 0
			entry["ready_turns"] = encounter.cooldown_remaining(src, program)
		. += list(entry)

/datum/netrun_ice/proc/casting_payload()
	if(!pending_program)
		return null
	. = pending_program.casting_payload(damage_factor)
	.["remaining"] = max(0, CEILING(round((attack_at - world.time) / (1 SECONDS), 0.01), 0.1))

/datum/netrun_ice/proc/is_stunned()
	return world.time < combat_stun_until

/// A legal resident can still provoke ICE by attacking it, including with a stun.
/datum/netrun_ice/proc/register_enemy(datum/netrun_console/attacker)
	var/mob/camera/netrun_entity/enemy = attacker?.combat_self()
	if(!istype(enemy) || QDELETED(enemy) || enemy.host_node != node)
		return FALSE
	enemy_ref = WEAKREF(enemy)
	return TRUE

/datum/netrun_ice/proc/apply_damage(amount, reason, datum/netrun_console/attacker)
	if(QDELETED(src))
		return
	register_enemy(attacker)
	if(amount > 0)
		netrun_actor_attacked(attacker?.netrun_actor())
	if(world.time < combat_shield_until)
		amount *= combat_shield_factor
	integrity -= amount
	if(integrity <= 0)
		destroyed(attacker)
	else
		SEND_SIGNAL(src, COMSIG_NETRUN_COMBAT_CHANGED)
		reaction.wake()

/datum/netrun_ice/proc/apply_stun(duration)
	combat_stun_until = max(combat_stun_until, world.time + duration)
	cancel_program()
	SEND_SIGNAL(src, COMSIG_NETRUN_COMBAT_CHANGED)
	reaction.wake()

/datum/netrun_ice/proc/apply_shield(pct, duration)
	var/new_factor = clamp(1 - pct / 100, 0.1, 1)
	if(world.time < combat_shield_until && new_factor > combat_shield_factor)
		return
	combat_shield_until = world.time + duration
	combat_shield_factor = new_factor
	SEND_SIGNAL(src, COMSIG_NETRUN_COMBAT_CHANGED)

/datum/netrun_ice/proc/apply_heal(amount)
	integrity = min(max_integrity, integrity + amount)
	SEND_SIGNAL(src, COMSIG_NETRUN_COMBAT_CHANGED)

/datum/netrun_ice/proc/destroyed(datum/netrun_console/killer)
	if(QDELETED(src))
		return
	node?.network?.add_log("Процесс защиты [name] уничтожен.")
	node?.add_log("[name]: процесс завершён.")
	SSnetrun.post_event("purge", null, node?.address)
	if(drops_loot)
		drop_loot(killer)
	qdel(src)

/// Лут с ICE. В первую очередь - в память убившей консоли (включая раннера за терминалом/декой),
/// затем сущности-игроку в узле, затем в ограниченный кеш обломков узла.
/datum/netrun_ice/proc/drop_loot(datum/netrun_console/killer)
	// A daemon is guaranteed; hunters also leave a combat program.
	SSnetrun.get_daemon(null)
	var/list/pool = list()
	for(var/id in SSnetrun.daemons)
		var/datum/netrun_program/daemon/daemon = SSnetrun.daemons[id]
		if(daemon.loot_weight > 0)
			pool[id] = daemon.loot_weight
	if(length(pool))
		deliver_loot(netrun_daemon_file(pickweight(pool)), killer)
	if(kind == NETRUN_ICE_HUNTER)
		SSnetrun.get_program(null)
		var/list/program_pool = list()
		for(var/id in SSnetrun.programs)
			var/datum/netrun_program/program = SSnetrun.programs[id]
			if(program.size > 0 && program.console_usable)
				program_pool += id
		if(length(program_pool))
			deliver_loot(netrun_program_file(pick(program_pool)), killer)
	// Патруль несёт ключ своей ЛВС: его уничтожение открывает свободное перемещение по отделу.
	if(persistent)
		var/datum/netrun_network/net = SSnetrun.networks[patrol_network_id] || node?.network
		if(net)
			deliver_loot(new /datum/netrun_file("[net.id].key", NETRUN_FILE_KEY, net.passcode, 1, net.id), killer)

/datum/netrun_ice/proc/deliver_loot(datum/netrun_file/loot, datum/netrun_console/killer)
	if(!loot)
		return
	if(!QDELETED(killer) && killer.store_file(loot))
		killer.log_line("Из обломков [name] извлечён файл: [loot.name].", "good")
		if(ismob(killer.host))
			to_chat(killer.host, span_notice("Из обломков процесса вы вытащили файл: [loot.name]."))
		return
	for(var/mob/camera/netrun_entity/entity as anything in node?.entities)
		if(entity.client && entity.console?.store_file(loot))
			to_chat(entity, span_notice("Из обломков процесса вы вытащили файл: [loot.name]."))
			return
	if(!QDELETED(node))
		// Debris is recoverable without USER privileges on the host machine.
		// Bounded separately: defeating ICE never expands the machine's disk.
		if(!node.leave_salvage(loot, name))
			qdel(loot)
			return
		killer?.log_line("Нет места в памяти. [loot.name] можно забрать из обломков в узле [node.address].", "average")
		return
	// Нет места нигде в сети - роняем физический шард рядом с убившим (у кого есть тело/машина).
	var/turf/drop_turf = (!QDELETED(killer) && isatom(killer.host)) ? killer.physical_turf() : node?.physical_turf()
	if(drop_turf)
		var/obj/item/netrun_shard/shard = new(drop_turf)
		shard.name = "data shard ([loot.name])"
		shard.file_store.insert(loot, TRUE)
		killer?.log_line("Нет места в памяти - лут выпал физическим шардом.", "average")
		return
	qdel(loot)

// MARK: Поведение (AI)

/// A hunter belongs to one LAN even when another LAN is physically adjacent.
/datum/netrun_ice/proc/defense_network()
	if(kind == NETRUN_ICE_HUNTER && patrol_network_id)
		return SSnetrun.networks[patrol_network_id]
	return node?.network

/// Population inspects cheap deadlines; only due patrols and active combat queue AI work.
/datum/netrun_ice/proc/needs_netrun_tick()
	if(get_combat_encounter()?.active)
		return FALSE
	if(reactive && dormant)
		return FALSE
	if(QDELETED(node) || QDELETED(node.parent) || pending_program)
		return TRUE
	if(kind == NETRUN_ICE_HUNTER && !persistent && world.time >= idle_expires_at)
		return TRUE
	// Empty departments have nothing to simulate or display. Real arrivals and
	// breaches wake their own LAN immediately; a shared index avoids per-hunter
	// client scans and native availability checks while the department sleeps.
	if(kind == NETRUN_ICE_HUNTER && persistent && !length(node.entities) && !SSnetrun.active_defense_networks[patrol_network_id || node.network?.id])
		return FALSE
	if(is_stunned() || !node.is_online())
		return FALSE
	if(length(node.entities) || find_intruder(node))
		return TRUE
	if(kind == NETRUN_ICE_HUNTER)
		return world.time >= hop_cooldown
	for(var/datum/netrun_console/console as anything in SSnetrun.currentbreaches)
		if(valid_trace_target(console))
			return TRUE
	return FALSE

/datum/netrun_ice/proc/process_ai(delta)
	var/datum/netrun_combat_encounter/encounter = get_combat_encounter()
	if(encounter?.active && !encounter.has_turn(src))
		return
	var/was_casting = !!pending_program
	if(reactive && (pending_program || has_reactive_threat()))
		dormant = FALSE
		reactive_sleep_at = world.time + reactive_quiet_timeout
	agent.advance(delta)
	if(!QDELETED(src))
		encounter = get_combat_encounter()
		if(encounter?.active && reactive && dormant)
			encounter.remove(encounter.member(src))
			return
		if(encounter?.active && encounter.has_turn(src) && !pending_program && !was_casting)
			encounter.pass(src)

/// Local residents and the bounded active-breach index are the only wake interests.
/datum/netrun_ice/proc/has_reactive_threat()
	if(QDELETED(node) || !node.is_online())
		return FALSE
	if(find_intruder(node))
		return TRUE
	for(var/datum/netrun_console/console as anything in SSnetrun.currentbreaches)
		if(valid_trace_target(console))
			return TRUE
	return FALSE

/datum/netrun_ice/proc/wake_reactive()
	if(!reactive || !dormant)
		return
	dormant = FALSE
	reactive_sleep_at = world.time + reactive_quiet_timeout
	agent.state = "охрана"
	node?.queue_presentation(NETRUN_CHANGED_OCCUPANTS)

/// May also inspect a destination before arrival; presence is checked by the caller.
/datum/netrun_ice/proc/is_intruder(mob/camera/netrun_entity/entity, datum/component/netrun_node/where, datum/netrun_path_tree/tree)
	if(!where)
		where = node
	if(!istype(entity) || QDELETED(entity) || QDELETED(where) || world.time < entity.combat_ignore_until)
		return FALSE
	if(agent?.profile.illegal)
		return !is_deployer(entity.console)
	return enemy_ref?.resolve() == entity || entity.console?.node_level(where, tree) < NETRUN_ACCESS_USER

/// Immunity belongs to the deploying principal, including its owned agents.
/// Both direct combat and remote countertrace recheck it at delivery.
/datum/netrun_ice/proc/bind_deployer(datum/netrun_console/console)
	if(QDELETED(console))
		return FALSE
	var/datum/principal = console.personal_faction_principal()
	var/mob/camera/netrun_entity/bot/bot = console.combat_self()
	if(istype(bot) && bot.launched_by_owner)
		principal = bot.agent_orphaned() ? null : bot.owner_principal_ref?.resolve()
	if(QDELETED(principal))
		return FALSE
	console.get_personal_faction_id()
	deployer_ref = WEAKREF(console)
	deployer_principal_ref = WEAKREF(principal)
	return TRUE

/datum/netrun_ice/proc/is_deployer(datum/netrun_console/console)
	var/datum/principal = deployer_principal_ref?.resolve()
	if(QDELETED(principal) || QDELETED(console))
		return FALSE
	var/mob/camera/netrun_entity/bot/bot = console.combat_self()
	if(istype(bot) && bot.launched_by_owner)
		return !bot.agent_orphaned() && bot.owner_principal_ref?.resolve() == principal
	return console.personal_faction_principal() == principal

/// Нарушитель в узле: нелегальная сущность или тот, кто спровоцировал этот ICE.
/// Both lightweight guards and resident entities use the same local combat interface.
/datum/netrun_ice/proc/hostile_actor(datum/actor, datum/component/netrun_node/where)
	if(QDELETED(actor) || actor == src || QDELETED(where) || actor.netrun_actor_node() != where)
		return FALSE
	if(istype(actor, /mob/camera/netrun_entity))
		return is_intruder(actor, where)
	if(!istype(actor, /datum/netrun_ice))
		return FALSE
	return enemy_ref?.resolve() == actor || netrun_actor_faction() != actor.netrun_actor_faction()

/datum/netrun_ice/proc/find_intruder(datum/component/netrun_node/where)
	var/datum/enemy = enemy_ref?.resolve()
	if(hostile_actor(enemy, where))
		return enemy
	var/list/occupants = list()
	occupants |= where?.entities
	occupants |= where?.netrun_ice
	var/best_integrity = INFINITY
	for(var/datum/actor as anything in occupants)
		if(!hostile_actor(actor, where))
			continue
		var/list/health = actor.get_netrun_combatant()?.integrity_payload()
		if(health && health["cur"] < best_integrity)
			. = actor
			best_integrity = health["cur"]

/datum/netrun_ice/proc/try_attack(datum/prey)
	if(QDELETED(prey))
		return
	var/datum/netrun_combat_encounter/encounter = node.get_combat_encounter()
	var/opening_attack = !encounter.active
	if(!encounter.admit(src, 1, prey))
		return
	if(!encounter.active && world.time < next_attack)
		return
	// A damaged guard visibly raises its barrier before returning to its attacks.
	if(integrity <= max_integrity * 0.75 && world.time >= combat_shield_until)
		for(var/id in program_ids)
			var/datum/netrun_program/program = SSnetrun.get_program(id)
			if(program?.role == NETRUN_PROGRAM_SHIELD && begin_program(program, src, opening_attack))
				return
	for(var/id in program_ids)
		var/datum/netrun_program/program = SSnetrun.get_program(id)
		if(!program || program.targets_breach)
			continue
		if(encounter.active ? (encounter.cooldown_remaining(src, program) || program.ap_cost > encounter.remaining_ap(src)) : world.time < (program_cd[id] || 0))
			continue
		if(!program.ice_should_use(src))
			continue
		if(begin_program(program, program.needs_target ? prey : src, opening_attack))
			return

/datum/netrun_ice/proc/pending_target()
	return pending_target_ref?.resolve()

/// A console is a valid trace target only while it is still attacking this node/LAN.
/datum/netrun_ice/proc/valid_trace_target(datum/netrun_console/console)
	if(!istype(console) || QDELETED(console) || console.netrun_actor() == src)
		return FALSE
	if(agent?.profile.illegal && is_deployer(console))
		return FALSE
	var/datum/netrun_breach/breach = console?.intrusion.breach
	return !console.is_locked() && !QDELETED(breach) && ((breach.target_kind == "network" && node?.network && breach.target_id == node.network.id) || (breach.target_kind != "network" && breach.target_id == node?.address))

/// Recheck authority and presence at both ends of the telegraph, not just at acquisition.
/datum/netrun_ice/proc/valid_program_target(datum/netrun_program/program, datum/target, fresh_access = FALSE)
	return program && program.valid_ice_target(src, target, fresh_access)

/datum/netrun_ice/proc/begin_program(datum/netrun_program/program, datum/target, opening_attack = FALSE)
	var/datum/netrun_combat_encounter/encounter = get_combat_encounter()
	if(!program || pending_program || is_stunned() || !node?.is_online() || !agent.program_file(program.id))
		return FALSE
	if(encounter?.active ? encounter.cooldown_remaining(src, program) : (world.time < next_attack || world.time < (program_cd[program.id] || 0)))
		return FALSE
	if(!valid_program_target(program, target, TRUE))
		return FALSE
	if(!encounter && netrun_turn_actor(target) != src)
		encounter = node.get_combat_encounter()
	// try_attack admits before choosing a program. Preserve the pre-admission
	// state from that caller as well as from direct casts and remote traces.
	var/already_in_combat = encounter?.active && !opening_attack
	if(encounter && (!encounter.admit(src, program.ap_cost, target) || !encounter.can_apply_program_status(program, target) || !encounter.commit_program(src, program, TRUE)))
		return FALSE
	if(program.consumable)
		var/datum/netrun_file/file = agent.program_file(program.id)
		agent.memory.remove(file)
		qdel(file)
	pending_program = program
	pending_target_ref = WEAKREF(target)
	program.capture_ice_target(src, target)
	var/telegraph = already_in_combat ? NETRUN_ICE_COMBAT_TELEGRAPH : max(NETRUN_ICE_MIN_TELEGRAPH, program.windup)
	attack_at = world.time + telegraph
	program_cd[program.id] = attack_at + program.cooldown
	var/datum/netrun_console/victim
	if(istype(target, /mob/camera/netrun_entity))
		var/mob/camera/netrun_entity/entity = target
		victim = entity.console
		var/counterplay = program.ice_counterplay(encounter?.active)
		if(agent?.profile.illegal)
			counterplay += " Чёрный ICE опасен для нейронного канала и тела!"
		to_chat(entity, span_userdanger("[name] готовит [program.name]: до срабатывания [telegraph / (1 SECONDS)] с! [counterplay]"))
	else if(istype(target, /datum/netrun_console))
		victim = target
	SEND_SIGNAL(SSnetrun, COMSIG_NETRUN_ICE_CAST_STARTED, src, victim)
	if(victim)
		SEND_SIGNAL(victim, COMSIG_NETRUN_ICE_CAST_STARTED, src, victim)
	SEND_SIGNAL(src, COMSIG_NETRUN_COMBAT_CHANGED)
	var/trace_advice = program.ice_trace_advice(encounter?.active)
	victim?.combat_log("[name] готовит [program.name], срабатывание через [telegraph / (1 SECONDS)] с.[trace_advice]", "bad")
	node.add_log("[name]: подготовка [program.name].")
	reaction.schedule_at(attack_at)
	victim?.finish_user_action()
	return TRUE

/datum/netrun_ice/proc/cancel_program(resolve_turn = TRUE)
	reaction?.clear_timer()
	var/had_program = !!pending_program
	pending_program = null
	pending_target_ref = null
	pending_breach_ref = null
	attack_at = 0
	if(had_program)
		SEND_SIGNAL(src, COMSIG_NETRUN_COMBAT_CHANGED)
		if(resolve_turn)
			get_combat_encounter()?.resolve(src)

/datum/netrun_ice/proc/resolve_program()
	if(!pending_program)
		return
	var/datum/target = pending_target()
	if(is_stunned() || !node?.is_online() || !valid_program_target(pending_program, target, world.time >= attack_at))
		cancel_program()
		return
	if(!pending_program.ice_target_current(src, target))
		cancel_program()
		return
	var/datum/netrun_combat_encounter/encounter = get_combat_encounter()
	if(encounter?.active && (!encounter.has_turn(src) || !encounter.deferred))
		cancel_program(FALSE)
		encounter.expire_turn()
		return
	if(encounter?.active && !encounter.can_apply_program_status(pending_program, target))
		cancel_program()
		return
	if(world.time < attack_at)
		return
	var/datum/netrun_program/program = pending_program
	cancel_program(FALSE)
	next_attack = world.time + 0.5 SECONDS
	if(program.hostile)
		target.netrun_actor_attacked(src)
	program.apply(target, null, damage_factor)
	if(!QDELETED(encounter))
		encounter.apply_program_status(program, target)
		encounter.resolve(src)
	SEND_SIGNAL(src, COMSIG_NETRUN_ICE_PROGRAM_RESOLVED, program, target)
	if(istype(target, /datum/netrun_console))
		var/datum/netrun_console/victim = target
		victim.finish_user_action()
	SSnetrun.post_event("intrusion", null, node?.address)
	if(!QDELETED(target) && istype(target, /mob/camera/netrun_entity))
		var/mob/camera/netrun_entity/entity = target
		entity.console?.combat_log("[name]: сработала [program.name].", "bad")
		entity.console?.finish_user_action()

/// Сторож без прямой цели давит на тех, кто ломает его узел или сеть.
/datum/netrun_ice/proc/harass_intruders()
	var/datum/netrun_program/program = SSnetrun.get_program("trace")
	var/datum/netrun_combat_encounter/encounter = get_combat_encounter()
	if(encounter?.active ? (encounter.cooldown_remaining(src, program) || program.ap_cost > encounter.remaining_ap(src)) : (world.time < next_attack || world.time < (program_cd[program.id] || 0)))
		return FALSE
	// During the subsystem pass this is one shared, bounded breach snapshot.
	// Standalone callers still inspect live consoles; execution checks every candidate.
	var/list/candidates = SSnetrun.breach_snapshot_active ? SSnetrun.currentbreaches : SSnetrun.consoles
	for(var/datum/netrun_console/console as anything in candidates)
		if(valid_trace_target(console) && begin_program(program, console))
			idle_expires_at = world.time + patrol_life * (1 SECONDS)
			return TRUE
	return FALSE

/datum/netrun_ice/proc/hunt()
	if(world.time < hop_cooldown)
		return FALSE
	var/datum/netrun_network/network = defense_network()
	var/list/targets = list()
	var/list/checked_nodes = list()
	for(var/mob/camera/netrun_entity/entity as anything in SSnetrun.entities)
		if(QDELETED(entity))
			continue
		var/datum/component/netrun_node/host = entity.host_node
		if(QDELETED(host) || host.network != network || checked_nodes[host.address])
			continue
		// find_intruder inspects all residents. Authorized crowds need the same
		// one check per host as hostile crowds, including a negative result.
		checked_nodes[host.address] = TRUE
		if(find_intruder(host))
			targets[host.address] = TRUE
	for(var/datum/netrun_ice/other as anything in SSnetrun.illegal_ice)
		var/datum/component/netrun_node/host = other.node
		if(QDELETED(other) || QDELETED(host) || host.network != network || checked_nodes[host.address])
			continue
		checked_nodes[host.address] = TRUE
		if(find_intruder(host))
			targets[host.address] = TRUE
	if(!length(targets))
		return FALSE
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	// Search only this LAN, and only when a real intruder is present there.
	var/list/queue = list(node.address)
	var/list/came_from = list()
	came_from[node.address] = null
	var/target_address
	for(var/i = 1, i <= length(queue), i++)
		var/address = queue[i]
		var/datum/component/netrun_node/current = graph.nodes[address]
		if(QDELETED(current) || current.network != network || !current.is_online())
			continue
		if(address != node.address && targets[address])
			target_address = address
			break
		for(var/neighbor in graph.neighbors(address, FALSE))
			if(!isnull(came_from[neighbor]) || neighbor == node.address)
				continue
			var/datum/component/netrun_node/next = graph.nodes[neighbor]
			if(next?.network != network || !netrun_link_available(current, next))
				continue
			came_from[neighbor] = address
			queue += neighbor
	if(!target_address)
		return FALSE
	idle_expires_at = world.time + patrol_life * (1 SECONDS)
	// Восстанавливаем первый шаг пути.
	var/step = target_address
	while(came_from[step] && came_from[step] != node.address)
		step = came_from[step]
	var/datum/component/netrun_node/next_node = graph.nodes[step]
	if(next_node && next_node != node)
		enter_node(next_node)
		hop_cooldown = world.time + 1.5 SECONDS
		return TRUE
	return FALSE

/// Walk real online links, preferring devices visited least recently over APC ping-pong.
/datum/netrun_ice/proc/patrol()
	hop_cooldown = world.time + 4 SECONDS
	var/datum/netrun_network/network = defense_network()
	if(!network)
		return FALSE
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	var/datum/component/netrun_node/destination
	var/oldest = INFINITY
	for(var/address in graph.neighbors(node.address, FALSE))
		var/datum/component/netrun_node/candidate = graph.nodes[address]
		if(candidate?.network != network || !netrun_link_available(node, candidate))
			continue
		var/visited = patrol_visits[address] || 0
		if(visited < oldest)
			destination = candidate
			oldest = visited
	return destination && enter_node(destination)

// MARK: Подсистема

/datum/controller/subsystem/netrun
	var/list/datum/netrun_ice/ice_processes = list()
	var/list/currentice = list()
	/// Explicit contraband deployments are capped; guards never scan every other guard.
	var/list/datum/netrun_ice/illegal_ice = list()
	/// Патрульные процессы поднимаются один раз за раунд при первом игровом тике.
	var/patrol_initialized = FALSE
	var/patrol_topology_revision = -1
	/// Destroying a persistent patrol clears the LAN permanently; topology edits do not respawn it.
	var/list/patrol_seeded_networks = list()
	var/list/list/datum/netrun_ice/hunters_by_network = list()
	/// LAN ids with a resident or live breach, rebuilt once per population pass.
	var/list/active_defense_networks = list()
	/// Лорные документы раскладываются по серверам один раз за раунд.
	var/lore_initialized = FALSE
	/// Узлы защиты со спящими ячейками льда: address -> сколько ячеек ещё можно пробудить.
	var/list/defense_nests = list()

/// A dormant patrol must not generate movement/log/UI traffic in an empty LAN.
/// Read current residency and breach targets only; this never builds route trees.
/datum/controller/subsystem/netrun/proc/collect_defense_network_interest()
	active_defense_networks.Cut()
	for(var/mob/camera/netrun_entity/entity as anything in entities)
		var/network_id = entity.host_node?.network?.id
		if(!QDELETED(entity) && network_id && entity.defense_threat())
			active_defense_networks[network_id] = TRUE
	for(var/datum/netrun_ice/ice as anything in illegal_ice)
		var/network_id = ice.node?.network?.id
		if(!QDELETED(ice) && network_id)
			active_defense_networks[network_id] = TRUE
	for(var/datum/netrun_console/console as anything in currentbreaches)
		if(QDELETED(console))
			continue
		var/datum/netrun_breach/breach = console.intrusion.breach
		if(QDELETED(breach))
			continue
		var/datum/component/netrun_node/target = nodes_by_address[breach.target_id]
		var/network_id = breach.target_kind == "network" ? breach.target_id : target?.network?.id
		if(network_id)
			active_defense_networks[network_id] = TRUE

/datum/controller/subsystem/netrun/proc/register_hunter(datum/netrun_ice/ice)
	if(ice.kind != NETRUN_ICE_HUNTER || !ice.patrol_network_id)
		return
	var/list/hunters = hunters_by_network[ice.patrol_network_id]
	if(!hunters)
		hunters = list()
		hunters_by_network[ice.patrol_network_id] = hunters
	hunters |= ice

/datum/controller/subsystem/netrun/proc/unregister_hunter(datum/netrun_ice/ice)
	var/list/hunters = hunters_by_network[ice.patrol_network_id]
	if(!hunters)
		return
	hunters -= ice
	if(!length(hunters))
		hunters_by_network -= ice.patrol_network_id

/// Создать ICE в узле. Возвращает процесс.
/datum/controller/subsystem/netrun/proc/spawn_ice(datum/component/netrun_node/where, ice_kind = NETRUN_ICE_SENTRY)
	if(QDELETED(where) || QDELETED(where.parent))
		return null
	var/datum/netrun_ice/ice = new(where, ice_kind)
	where.network?.add_log("Активирован процесс защиты: [ice.name].")
	where.add_log("[ice.name]: процесс защиты запущен.")
	return ice

/// Сколько ICE уже стоит в узле (не плодим бесконечно).
/datum/controller/subsystem/netrun/proc/ice_count(datum/component/netrun_node/where)
	return LAZYLEN(where?.netrun_ice)

/// Среагировать на нелегальную активность: закалённый узел ставит сторожа,
/// а при высокой трассировке с ближайшего реле/сервера выходит охотник.
/datum/component/netrun_node
	/// The carrier has one reactive nest for its lifetime, even after its guard is defeated.
	var/reactive_defense_seeded = FALSE

/datum/controller/subsystem/netrun/proc/raise_defenses(datum/netrun_console/console, datum/component/netrun_node/target)
	if(QDELETED(target) || QDELETED(target.parent))
		return
	var/atom/host = target.parent
	if(!host.netrun_reactive_defense_allowed())
		return
	if(target.get_security() >= 3 && !target.reactive_defense_seeded && ice_count(target) < 1)
		var/datum/netrun_ice/ice = spawn_ice(target, NETRUN_ICE_SENTRY)
		if(ice)
			target.reactive_defense_seeded = TRUE
			ice.reactive = TRUE
			ice.drops_loot = FALSE
			ice.reactive_sleep_at = world.time + ice.reactive_quiet_timeout
			ice.reaction.wake()

/// Пассивный патруль с начала раунда: по одному персистентному охотнику на крупные
/// отдельские ЛВС. Патруль не сворачивается без цели и роняет ключ своей ЛВС при гибели.
/datum/controller/subsystem/netrun/proc/initialize_patrol()
	var/datum/netrun_topology/graph = get_topology()
	if(graph.dirty)
		return
	patrol_initialized = TRUE
	patrol_topology_revision = graph.revision
	var/count = length(patrol_seeded_networks)
	for(var/net_id in networks)
		if(count >= NETRUN_MAX_PATROLS)
			break
		var/datum/netrun_network/net = networks[net_id]
		if(net.security < 2 || net.isolated || patrol_seeded_networks[net.id])
			continue
		var/list/candidates = list()
		for(var/datum/component/netrun_node/node as anything in net.nodes)
			if(!QDELETED(node) && !QDELETED(node.parent) && node.is_online())
				candidates += node
		if(!length(candidates))
			continue
		var/datum/component/netrun_node/anchor = pick(candidates)
		var/datum/netrun_ice/patrol = spawn_ice(anchor, NETRUN_ICE_HUNTER)
		if(patrol)
			patrol.persistent = TRUE
			patrol.patrol_network_id = net.id
			patrol_seeded_networks[net.id] = TRUE
			net.add_log("В сети активен патрульный процесс защиты.")
			count++
		// В хорошо защищённых отделах один узел становится гнездом спящих ячеек льда.
		if(net.security >= 3)
			var/datum/component/netrun_node/nest
			for(var/datum/component/netrun_node/candidate as anything in candidates)
				if(candidate.node_type == NETRUN_NODE_SERVER)
					nest = candidate
					break
			nest ||= anchor
			if(nest)
				defense_nests[nest.address] = 2
				nest.add_log("Узел защиты: спящие ячейки ICE в резерве.")

/// Трассировка вскрыта: патрули устремляются к нарушителю, а гнёзда пробуждают спящие ячейки.
/datum/controller/subsystem/netrun/proc/alert_defenses(datum/component/netrun_node/target, datum/netrun_console/intruder)
	if(QDELETED(target) || !target.network)
		return
	var/datum/netrun_network/network = target.network
	var/active_responses = 0
	for(var/datum/netrun_ice/ice as anything in hunters_by_network[network.id])
		if(QDELETED(ice))
			continue
		if(!ice.persistent)
			active_responses++
			ice.idle_expires_at = world.time + ice.patrol_life * (1 SECONDS)
		ice.hop_cooldown = min(ice.hop_cooldown, world.time + 1.5 SECONDS)
		ice.reaction.wake()
	for(var/nest_address in defense_nests)
		if(active_responses >= 3)
			break
		if(defense_nests[nest_address] <= 0)
			continue
		var/datum/component/netrun_node/nest = nodes_by_address[nest_address]
		if(QDELETED(nest) || QDELETED(nest.parent) || nest.network != network || !nest.is_online())
			continue
		var/datum/netrun_ice/awoken = spawn_ice(nest, NETRUN_ICE_HUNTER)
		if(awoken)
			defense_nests[nest_address]--
			active_responses++
			awoken.hop_cooldown = 0
			awoken.reaction.wake()
			nest.network?.add_log("Пробуждена ячейка защиты: процесс направлен к нарушителю.")

/// Выслать охотника за нарушителем-сущностью (если он есть и до него есть сеть).
/datum/controller/subsystem/netrun/proc/dispatch_hunter(datum/component/netrun_node/near)
	if(QDELETED(near) || QDELETED(near.parent) || !near.network)
		return
	// Temporary responses have a separate per-LAN quota; passive patrols do not consume it.
	var/hunters = 0
	for(var/datum/netrun_ice/ice as anything in hunters_by_network[near.network?.id])
		if(!QDELETED(ice) && !ice.persistent)
			hunters++
	if(hunters >= 3)
		return
	var/datum/netrun_ice/hunter = spawn_ice(near, NETRUN_ICE_HUNTER)
	hunter?.reaction.wake()

