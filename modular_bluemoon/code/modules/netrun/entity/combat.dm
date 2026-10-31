/** A console owns one combat context; machine permissions never derive from combat contacts. */
/datum/netrun_console
	var/datum/netrun_combat_context/combat_context

/datum/netrun_console/proc/combat_node(datum/netrun_path_tree/tree)
	var/datum/component/netrun_node/node = selected_node()
	if(node && can_route(node, tree) && node.is_online(node != connection.jack) && node_level(node, tree) >= NETRUN_ACCESS_GUEST)
		return node
	return null

/datum/netrun_console/entity/combat_node(datum/netrun_path_tree/tree)
	var/mob/camera/netrun_entity/entity = host
	return entity?.host_node

/datum/netrun_console/proc/combat_self()
	return null

/datum/netrun_console/entity/combat_self()
	return host

/datum/netrun_console/proc/builtin_program_ids()
	return combat_self() ? list("sting", "pulse", "surge", "shell", "mend") : list()

/datum/netrun_console/proc/pass_combat_turn(turn_id)
	var/datum/netrun_combat_encounter/encounter = get_combat_encounter()
	if(!isnull(turn_id) && !encounter?.accepts_input(turn_id))
		return FALSE
	if(!encounter?.pass(src))
		combat_log("Сейчас нельзя завершить ход: дождитесь своей очереди и окончания программы.", "bad")
		return FALSE
	return TRUE

/// Spectators explicitly enter the queue through their current native contact.
/// This grants neither a route nor machine access and never selects a target.
/datum/netrun_console/proc/join_combat_turn(turn_id)
	if(is_locked())
		return FALSE
	var/datum/netrun_path_tree/tree = connection.read_path_tree(TRUE)
	var/datum/component/netrun_node/node = combat_node(tree)
	var/datum/netrun_combat_encounter/encounter = node?.combat_encounter
	release_path_tree(tree)
	if(!encounter?.accepts_join_input(turn_id))
		return FALSE
	// A spectator spends no AP: a queued timeout may rotate the decision but
	// must not discard a valid request to enter this same surviving encounter.
	encounter.expired_input()
	if(QDELETED(encounter) || !encounter.active || encounter.contains(src) || !encounter.join(src))
		return FALSE
	encounter.changed()
	return TRUE

/datum/netrun_console/proc/combat_targets()
	return combat_context.targets()

/// The same action facade is used by the combat panel and CLI.
/datum/netrun_console/proc/start_pursuit(target_ref)
	var/mob/camera/netrun_entity/entity = host
	if(!istype(entity) || !entity.navigation)
		log_line("Преследовать цель может только сетевая сущность.", "bad")
		return FALSE
	if(!istext(target_ref))
		return FALSE
	var/mob/camera/netrun_entity/target = locate(target_ref)
	if(!istype(target))
		log_line("Для преследования выберите процесс, а не ICE или укрепление.", "bad")
		return FALSE
	return entity.navigation.pursue(target)

/datum/netrun_console/proc/stop_pursuit()
	var/mob/camera/netrun_entity/entity = host
	if(!istype(entity) || !entity.navigation)
		return FALSE
	entity.navigation.cancel()
	log_line("Преследование остановлено.")
	return TRUE

/datum/netrun_console/proc/combat_programs()
	return combat_context.programs()

/datum/netrun_console/proc/combat_payload()
	return combat_context.payload()

/datum/netrun_console/proc/incoming_programs()
	return combat_context.incoming()

/// A puzzle hides the map, never the attacker's identity or the player's programs.
/datum/netrun_console/proc/breach_combat_payload()
	return combat_context.payload()

/datum/netrun_console/proc/program_use(uid, target_ref, turn_id)
	return combat_context.use_program(uid, target_ref, turn_id)

/// Заметание следов разрывает бой: контакты сбрасываются, атакующий лёд снимает агро,
/// отменяет подготовленную программу и не перезахватывает цель короткое время.
/datum/netrun_console/proc/disengage_combat()
	combat_context.clear_contacts()
	var/datum/netrun_daemon_context/effects = new
	effects.disengage_grace = NETRUN_DISENGAGE_GRACE
	apply_daemon_effects(effects)
	var/grace = effects.disengage_grace
	qdel(effects)
	var/datum/self = combat_self()
	var/mob/camera/netrun_entity/entity = self
	if(istype(entity))
		entity.combat_ignore_until = world.time + grace
	var/mob/camera/netrun_entity/bot/bot = self
	for(var/datum/netrun_ice/ice as anything in SSnetrun.ice_processes)
		if(QDELETED(ice))
			continue
		if(istype(bot))
			// Successful cleanup also releases the NPC's remembered guard target;
			// otherwise it immediately provokes the same ICE after earning USER.
			bot.brain?.enemies -= WEAKREF(ice)
		var/datum/target = ice.pending_target()
		var/datum/resolved_enemy = ice.enemy_ref?.resolve()
		if(target == src || (self && (target == self || resolved_enemy == self)))
			ice.cancel_program()
			ice.enemy_ref = null
			ice.next_attack = max(ice.next_attack, world.time + grace)
	combat_context.changed()

/datum/netrun_combat_contact
	var/datum/weakref/ice_ref
	var/datum/weakref/node_ref
	var/datum/weakref/network_ref
	var/datum/weakref/breach_ref

/datum/netrun_combat_contact/New(datum/netrun_ice/ice, datum/netrun_breach/breach)
	ice_ref = WEAKREF(ice)
	node_ref = WEAKREF(ice.node)
	if(ice.node.network)
		network_ref = WEAKREF(ice.node.network)
	breach_ref = WEAKREF(breach)

/datum/netrun_combat_contact/proc/valid_for(datum/netrun_console/console)
	var/datum/netrun_ice/ice = ice_ref.resolve()
	var/datum/component/netrun_node/node = node_ref.resolve()
	var/datum/netrun_breach/breach = breach_ref.resolve()
	return !QDELETED(ice) && !QDELETED(node) && !QDELETED(breach) && console.intrusion.breach == breach && !console.is_locked() && ice.node == node && node.network == network_ref?.resolve()

/datum/netrun_combat_context
	var/datum/netrun_console/console
	/// Cooldowns belong to this session, not to the UI or the installed file.
	var/list/program_cd = list()
	var/next_program = 0
	/// REF(ICE) -> contact. Contacts survive cast resolution and stun until the breach ends.
	var/list/contacts = list()
	/// Weak sources replace the previous global scan of every ICE on every UI update.
	var/list/observed_ice = list()
	var/datum/weakref/observed_breach
	/// Last visible opponents, for expiring status badges without rebuilding routes.
	var/list/visible_status_sources = list()
	var/datum/weakref/observed_turn_node
	var/datum/weakref/resident_ref

/datum/netrun_combat_context/New(datum/netrun_console/console)
	src.console = console
	RegisterSignal(console, COMSIG_NETRUN_ICE_CAST_STARTED, PROC_REF(on_cast_started))
	var/mob/camera/netrun_entity/resident = console.combat_self()
	if(istype(resident))
		resident_ref = WEAKREF(resident)
		RegisterSignal(resident, COMSIG_NETRUN_ENTITY_NODE_CHANGED, PROC_REF(on_resident_moved))

/datum/netrun_combat_context/Destroy()
	UnregisterSignal(console, COMSIG_NETRUN_ICE_CAST_STARTED)
	var/mob/camera/netrun_entity/resident = resident_ref?.resolve()
	if(resident)
		UnregisterSignal(resident, COMSIG_NETRUN_ENTITY_NODE_CHANGED)
	resident_ref = null
	observe_turns(null)
	clear_contacts()
	for(var/id in observed_ice)
		var/datum/weakref/reference = observed_ice[id]
		var/datum/netrun_ice/ice = reference.resolve()
		if(ice)
			UnregisterSignal(ice, list(COMSIG_NETRUN_COMBAT_CHANGED, COMSIG_NETRUN_ICE_NODE_CHANGED, COMSIG_PARENT_QDELETING))
	observed_ice.Cut()
	visible_status_sources.Cut()
	console = null
	return ..()

/datum/netrun_combat_context/proc/changed()
	SEND_SIGNAL(console, COMSIG_NETRUN_COMBAT_CHANGED)

/// Spectators subscribe only to the encounter they are inspecting. Turn facts
/// refresh its panel without updating map markers or polling every participant.
/datum/netrun_combat_context/proc/observe_turns(datum/component/netrun_node/node)
	var/datum/component/netrun_node/previous = observed_turn_node?.resolve()
	if(previous == node)
		return
	if(previous)
		UnregisterSignal(previous, list(COMSIG_NETRUN_TURN_CHANGED, COMSIG_PARENT_QDELETING))
	observed_turn_node = node ? WEAKREF(node) : null
	if(node)
		RegisterSignal(node, COMSIG_NETRUN_TURN_CHANGED, PROC_REF(on_turn_changed))
		RegisterSignal(node, COMSIG_PARENT_QDELETING, PROC_REF(on_turn_node_deleted))

/datum/netrun_combat_context/proc/on_turn_changed(datum/source)
	SIGNAL_HANDLER
	if(console.workspace_view == "combat" || console.get_combat_encounter() || console.is_ui_active())
		changed()

/datum/netrun_combat_context/proc/on_resident_moved(datum/source, datum/component/netrun_node/previous, datum/component/netrun_node/current)
	SIGNAL_HANDLER
	// Dormant autonomous consoles never acquire a UI observer just by walking.
	if(!observed_turn_node && !console.is_ui_active())
		return
	observe_turns(current)
	changed()

/datum/netrun_combat_context/proc/on_turn_node_deleted(datum/source)
	SIGNAL_HANDLER
	observe_turns(null)
	changed()

/datum/netrun_combat_context/proc/observe(datum/netrun_ice/ice)
	var/id = REF(ice)
	if(observed_ice[id])
		return
	observed_ice[id] = WEAKREF(ice)
	RegisterSignal(ice, COMSIG_NETRUN_COMBAT_CHANGED, PROC_REF(on_combat_changed))
	RegisterSignal(ice, COMSIG_NETRUN_ICE_NODE_CHANGED, PROC_REF(on_ice_moved))
	RegisterSignal(ice, COMSIG_PARENT_QDELETING, PROC_REF(on_ice_deleted))

/datum/netrun_combat_context/proc/on_cast_started(datum/source, datum/netrun_ice/ice, datum/netrun_console/victim)
	SIGNAL_HANDLER
	if(victim != console || QDELETED(ice))
		return
	observe(ice)
	var/mob/camera/netrun_entity/entity = console.combat_self()
	if(ice.pending_program?.targets_breach && (!entity || entity.host_node != ice.node))
		register_attacker(ice, console.intrusion.breach)
	changed()

/datum/netrun_combat_context/proc/register_attacker(datum/netrun_ice/ice, datum/netrun_breach/breach)
	if(QDELETED(breach) || !ice.node || ice.pending_target() != console || !ice.valid_trace_target(console))
		return FALSE
	if(observed_breach?.resolve() != breach)
		clear_contacts()
		observed_breach = WEAKREF(breach)
		RegisterSignal(breach, COMSIG_PARENT_QDELETING, PROC_REF(on_breach_deleted))
	var/id = REF(ice)
	qdel(contacts[id])
	contacts[id] = new /datum/netrun_combat_contact(ice, breach)
	return TRUE

/datum/netrun_combat_context/proc/clear_contacts()
	var/datum/netrun_breach/breach = observed_breach?.resolve()
	if(breach)
		UnregisterSignal(breach, COMSIG_PARENT_QDELETING)
	observed_breach = null
	QDEL_LIST_ASSOC_VAL(contacts)
	contacts = list()

/datum/netrun_combat_context/proc/on_breach_deleted(datum/source)
	SIGNAL_HANDLER
	clear_contacts()
	changed()

/datum/netrun_combat_context/proc/on_combat_changed(datum/source)
	SIGNAL_HANDLER
	changed()

/datum/netrun_combat_context/proc/on_ice_moved(datum/netrun_ice/source)
	SIGNAL_HANDLER
	var/id = REF(source)
	qdel(contacts[id])
	contacts -= id
	changed()

/datum/netrun_combat_context/proc/on_ice_deleted(datum/netrun_ice/source)
	SIGNAL_HANDLER
	on_ice_moved(source)
	observed_ice -= REF(source)
	UnregisterSignal(source, list(COMSIG_NETRUN_COMBAT_CHANGED, COMSIG_NETRUN_ICE_NODE_CHANGED, COMSIG_PARENT_QDELETING))

/datum/netrun_combat_context/proc/prune_contacts()
	for(var/id in contacts.Copy())
		var/datum/netrun_combat_contact/contact = contacts[id]
		if(!contact.valid_for(console))
			qdel(contact)
			contacts -= id

/// Returns the same denial reason used by both the payload and the actual action.
/datum/netrun_combat_context/proc/target_denial(datum/target, datum/netrun_path_tree/tree, datum/component/netrun_node/local_node, local_known = FALSE)
	if(QDELETED(target) || target == console.combat_self())
		return "Цель недоступна."
	var/datum/component/netrun_combatant/combatant = target.get_netrun_combatant()
	var/datum/component/netrun_node/node = combatant?.node()
	if(!node)
		return "Цель покинула узел."
	if(console.is_locked())
		return "Точка подключения заблокирована."
	var/datum/netrun_combat_encounter/encounter = console.get_combat_encounter()
	if(encounter?.active && encounter.node_ref?.resolve() != node)
		return "Сначала завершите текущий бой или выйдите из него: цель находится в другом узле."
	// During one combat payload the local node has already been resolved once.
	var/datum/component/netrun_node/local = local_known ? local_node : console.combat_node(tree)
	if(node == local)
		return null
	// Structures may be engaged from a neighbouring node (siege of fortress outer works).
	if(combatant.allows_remote_attack(console, local))
		if(!node.is_online(node != console.connection.jack))
			return "Узел противника не отвечает."
		return null
	var/datum/netrun_combat_contact/contact = contacts[REF(target)]
	if(!contact?.valid_for(console))
		return "Нет активного боевого контакта."
	if(!node.is_online(node != console.connection.jack))
		return "Узел противника не отвечает."
	if(!console.can_route(node, tree))
		return "Нет маршрута к противнику."
	return null

/datum/netrun_combat_context/proc/targets(datum/netrun_path_tree/tree, datum/component/netrun_node/local_node, local_known = FALSE)
	prune_contacts()
	var/owns_tree = !tree
	if(owns_tree)
		tree = console.connection.read_path_tree(TRUE)
		SSnetrun.combat_ui_tree_builds++
	var/datum/component/netrun_node/node = local_known ? local_node : console.combat_node(tree)
	var/list/candidates = list()
	if(node)
		candidates |= node.entities || list()
		candidates |= node.netrun_ice || list()
		candidates |= node.fortress?.combat_targets() || list()
		// A resident process can lay siege to the outer works of fortresses next door.
		if(console.combat_self())
			for(var/datum/component/netrun_node/neighbor as anything in netrun_adjacent_fortress_nodes(node))
				candidates |= neighbor.fortress.siege_targets()
	for(var/id in contacts)
		var/datum/netrun_combat_contact/contact = contacts[id]
		var/datum/netrun_ice/ice = contact.ice_ref.resolve()
		if(ice)
			candidates |= ice
	. = list()
	visible_status_sources.Cut()
	for(var/datum/target as anything in candidates)
		if(QDELETED(target) || target == console.combat_self())
			continue
		var/datum/component/netrun_combatant/combatant = target.get_netrun_combatant()
		if(!combatant)
			continue
		visible_status_sources += WEAKREF(target)
		var/list/entry = combatant.ui_entry()
		var/mob/camera/netrun_entity/viewer = console.combat_self()
		if(istype(target, /datum/netrun_ice) && istype(viewer))
			var/datum/netrun_ice/ice = target
			entry["hostile"] = ice.is_intruder(viewer, ice.node, tree)
		entry["unavailable_reason"] = target_denial(target, tree, node, TRUE)
		. += list(entry)
	if(owns_tree)
		console.release_path_tree(tree)

/datum/netrun_combat_context/proc/program_entry(datum/netrun_program/program, uid, builtin = FALSE, file_name)
	var/list/entry = program.ui_entry()
	if(file_name)
		entry["name"] = file_name
	entry["uid"] = uid
	entry["builtin"] = builtin
	entry["ready_in"] = max(0, CEILING(((program_cd[program.id] || 0) - world.time) / (1 SECONDS), 0.1))
	entry["unavailable_reason"] = !program.needs_target && !console.combat_self() ? "Нужна собственная сущность в сети." : null
	var/datum/netrun_combat_encounter/encounter = console.get_combat_encounter()
	if(encounter?.active)
		entry["ready_in"] = 0
		entry["ready_turns"] = encounter.cooldown_remaining(console, program)
		if(encounter.is_waiting(console))
			entry["unavailable_reason"] = "Дождитесь своего хода и окончания текущей программы."
		else if(encounter.remaining_ap(console) < program.ap_cost)
			entry["unavailable_reason"] = "Недостаточно очков действий: нужно [program.ap_cost]."
		else if(entry["ready_turns"])
			entry["unavailable_reason"] = "Программа восстанавливается: ещё [entry["ready_turns"]] ход(а)."
	return entry

/datum/netrun_combat_context/proc/programs()
	. = list()
	for(var/id in console.builtin_program_ids())
		var/datum/netrun_program/builtin = SSnetrun.get_program(id)
		if(builtin)
			. += list(program_entry(builtin, "builtin:[id]", TRUE))
	for(var/datum/netrun_file/file as anything in (console.ui_files || console.all_files()))
		if(file.kind != NETRUN_FILE_PROGRAM)
			continue
		var/datum/netrun_program/program = SSnetrun.get_program(file.content)
		if(program?.console_usable)
			. += list(program_entry(program, file.uid, FALSE, file.name))

/datum/netrun_combat_context/proc/incoming()
	. = list()
	for(var/id in observed_ice)
		var/datum/weakref/reference = observed_ice[id]
		var/datum/netrun_ice/ice = reference.resolve()
		if(QDELETED(ice) || !ice.pending_program)
			continue
		var/datum/target = ice.pending_target()
		if(target != console && target != console.combat_self())
			continue
		var/list/entry = ice.casting_payload()
		entry["source"] = ice.name
		entry["source_ref"] = REF(ice)
		entry["source_node"] = ice.node?.address
		. += list(entry)

/// Observation is a subscription, not a countdown: idle observed ICE must not
/// force permanent UI polling after the first encounter. Cast start/end emits signals.
/datum/netrun_combat_context/proc/needs_live_refresh()
	// The browser counts down a turn locally. Infinite turn-owned shield/stun
	// markers must not reactivate the legacy wall-clock polling of all targets.
	if(console.get_combat_encounter()?.active)
		return FALSE
	var/datum/self = console.combat_self()
	for(var/id in observed_ice)
		var/datum/weakref/reference = observed_ice[id]
		var/datum/netrun_ice/ice = reference.resolve()
		if(QDELETED(ice) || !ice.pending_program)
			continue
		var/datum/target = ice.pending_target()
		if(target == console || (self && target == self))
			return TRUE
	if(console.workspace_view != "combat")
		return FALSE
	for(var/datum/weakref/reference as anything in visible_status_sources)
		var/list/hp = netrun_combatant_integrity(reference.resolve())
		if(hp?["stunned"] || hp?["shielded"])
			return TRUE
	if(next_program > world.time)
		return TRUE
	for(var/id in program_cd)
		if(program_cd[id] > world.time)
			return TRUE
	return FALSE

/// Only the cross-tab warning is needed until the user opens the combat workspace.
/// Do not compute routes, target permissions or load every program file on a puzzle tick.
/datum/netrun_combat_context/proc/status_payload()
	SSnetrun.combat_summary_payloads++
	var/list/warnings = incoming()
	var/datum/netrun_combat_encounter/encounter = console.get_combat_encounter()
	var/mob/camera/netrun_entity/resident = console.combat_self()
	if(istype(resident))
		// Native residency is already authoritative. A compact spectator summary
		// must not build routes or trust another selected device's combat state.
		var/datum/component/netrun_node/node = resident.console == console && resident.netrun_actor_present(resident.host_node) ? resident.host_node : null
		observe_turns(node)
		if(!encounter)
			encounter = node?.combat_encounter
	var/list/turn = encounter?.payload(console)
	if(!length(warnings) && !turn)
		return null
	return list("incoming" = warnings, "turn" = turn)

/datum/netrun_combat_context/proc/payload()
	SSnetrun.combat_full_payloads++
	var/measuring = SSnetrun.profile_armed
	var/started = measuring ? TICK_USAGE : 0
	var/datum/netrun_path_tree/tree = console.ui_routes
	var/owns_tree = !tree
	if(owns_tree)
		tree = console.connection.read_path_tree(TRUE)
		SSnetrun.combat_ui_tree_builds++
	var/datum/component/netrun_node/node = console.combat_node(tree)
	observe_turns(node)
	var/list/target_entries = targets(tree, node, TRUE)
	var/list/incoming_entries = incoming()
	if(!node && !length(target_entries) && !length(incoming_entries))
		if(owns_tree)
			console.release_path_tree(tree)
		return null
	var/datum/self = console.combat_self()
	var/list/hp = netrun_combatant_integrity(self)
	var/list/loot = console.salvage_payload(node, TRUE)
	var/list/result = list("node" = node?.address, "node_name" = node?.get_name(),
		"self" = hp ? list("integrity" = hp["cur"], "max_integrity" = hp["max"], "stunned" = hp["stunned"], "shielded" = hp["shielded"]) : null,
		"targets" = target_entries, "programs" = programs(), "incoming" = incoming_entries, "loot" = loot,
		"action_ready_in" = max(0, CEILING((next_program - world.time) / (1 SECONDS), 0.1)))
	var/datum/netrun_combat_encounter/encounter = console.get_combat_encounter() || node?.combat_encounter
	result["turn"] = encounter?.payload(console)
	if(encounter?.active)
		result["action_ready_in"] = 0
	var/mob/camera/netrun_entity/entity = self
	result["pursuit_available"] = istype(entity) && !!entity.navigation
	result["pursuit"] = istype(entity) ? entity.navigation?.pursuit_payload() : null
	if(owns_tree)
		console.release_path_tree(tree)
	if(measuring)
		var/cost = max(0, TICK_DELTA_TO_MS(TICK_USAGE - started))
		SSnetrun.combat_full_payload_ms += cost
		SSnetrun.combat_full_payload_peak_ms = max(SSnetrun.combat_full_payload_peak_ms, cost)
	return result

/datum/netrun_combat_context/proc/use_program(uid, target_ref, turn_id)
	if(console.is_locked())
		return FALSE
	var/datum/netrun_combat_encounter/encounter = console.get_combat_encounter()
	if(!isnull(turn_id) && !encounter?.accepts_input(turn_id))
		return FALSE
	if(!encounter?.active && world.time < next_program)
		console.combat_log("Предыдущая программа ещё выполняется: осталось [max(0, CEILING((next_program - world.time) / (1 SECONDS), 0.1))] с.", "bad")
		return FALSE
	var/builtin = findtext("[uid]", "builtin:") == 1
	var/datum/netrun_file/file
	var/datum/netrun_program/program
	if(builtin)
		var/id = copytext("[uid]", length("builtin:") + 1)
		if(!(id in console.builtin_program_ids()))
			return FALSE
		program = SSnetrun.get_program(id)
	else
		file = console.find_local_file(uid)
		if(!file || file.kind != NETRUN_FILE_PROGRAM)
			return FALSE
		program = SSnetrun.get_program(file.content)
	if(!program?.console_usable)
		return FALSE
	var/executable_name = file?.name || program.name
	if(!encounter?.active && world.time < (program_cd[program.id] || 0))
		console.combat_log("[executable_name]: идёт перезарядка.", "bad")
		return FALSE
	var/datum/self = console.combat_self()
	var/list/hp = netrun_combatant_integrity(self)
	if(hp?["stunned"])
		console.combat_log("Ваш процесс оглушён и не может запускать программы.", "bad")
		return FALSE
	var/datum/target = program.needs_target ? locate(target_ref) : self
	if(!target)
		console.combat_log(program.needs_target ? "Цель недоступна." : "[executable_name]: нужна собственная сущность в сети.", "bad")
		return FALSE
	prune_contacts()
	var/datum/netrun_path_tree/tree = console.connection.read_path_tree(TRUE)
	var/denial = program.needs_target ? target_denial(target, tree) : null
	var/datum/component/netrun_combatant/combatant = target.get_netrun_combatant()
	var/datum/component/netrun_node/node = combatant?.node()
	if(!program.needs_target && (!node || node != console.combat_node(tree)))
		denial = "Нет боевого контакта."
	console.release_path_tree(tree)
	if(denial)
		console.combat_log(denial, "bad")
		return FALSE
	var/datum/netrun_fortress_module/module = target
	if(istype(module) && module.fortress?.has_turn_battery())
		if(encounter?.active && (encounter.is_waiting(console) || encounter.remaining_ap(console) < program.ap_cost || encounter.cooldown_remaining(console, program)))
			console.combat_log("Для этой атаки нужен ваш ход, готовая программа и достаточно очков действий.", "bad")
			return FALSE
		if(!module.fortress.authorize_turn_siege(console, module))
			console.combat_log("Нет действующего канала осады к этой крепости.", "bad")
			return FALSE
	if(!encounter)
		// A self buff outside an encounter retains its ordinary cooldown. An
		// attack enrolls actual active actors; passive structures take no turns.
		encounter = node?.combat_encounter
		if(!encounter && netrun_turn_actor(target) && netrun_turn_actor(target) != console)
			encounter = node?.get_combat_encounter()
	if(encounter)
		if(encounter.cooldown_remaining(console, program))
			console.combat_log("[executable_name]: восстановление ещё [encounter.cooldown_remaining(console, program)] ход(а).", "bad")
			return FALSE
		if(!encounter.admit(console, program.ap_cost, target))
			console.combat_log("Дождитесь своего хода; для программы нужно [program.ap_cost] очк(а) действий.", "bad")
			return FALSE
		if(!encounter.can_apply_program_status(program, target))
			console.combat_log(program.status_denial(), "bad")
			return FALSE
		if(!encounter.commit_program(console, program, TRUE))
			return FALSE
	next_program = world.time + 0.5 SECONDS
	program_cd[program.id] = world.time + program.cooldown
	// Attacking reveals the process again, including an otherwise authorized user.
	// Rejected requests above must never spend the disengagement grace period.
	if(program.hostile)
		var/mob/camera/netrun_entity/entity = self
		if(istype(entity))
			var/was_ignored = world.time < entity.combat_ignore_until
			entity.combat_ignore_until = 0
			if(istype(target, /datum/netrun_ice))
				var/datum/netrun_ice/ice = target
				// Revealing an attack also ends this ICE's disengagement pause;
				// individual program cooldowns still protect interrupted casts.
				if(was_ignored)
					ice.next_attack = min(ice.next_attack, world.time)
				ice.register_enemy(console)
	// A lethal effect deletes its component and clears its native parent/profile.
	// Preserve incident facts before delivery instead of consulting dead targets.
	var/station_target = combatant.protected_by_station()
	var/target_name = combatant.display_name()
	console.apply_program_effect(program, target, node, executable_name)
	if(!QDELETED(encounter))
		encounter.apply_program_status(program, target)
		encounter.resolve(console)
	if(program.trace)
		console.add_trace(program.trace)
	SSnetrun.post_event("intrusion", node.network?.id, node.address)
	if(program.hostile && station_target)
		SSnetrun.report_incident("combat", node, self || console, NETRUN_INCIDENT_MEDIUM, "Атака на [target_name].")
	if(program.consumable)
		console.delete_local_file(file)
		console.combat_log("Карточка [executable_name] израсходована.", "average")
	changed()
	console.finish_user_action(node)
	return TRUE

/datum/netrun_console/proc/salvage_payload(datum/component/netrun_node/local_node, local_known = FALSE)
	. = list()
	var/datum/component/netrun_node/node = local_known ? local_node : combat_node()
	if(!combat_self() || !node)
		return
	for(var/datum/netrun_file/file as anything in node.salvage)
		. += list(file.ui_entry())

/datum/netrun_console/proc/recover_salvage(uid)
	var/mob/camera/netrun_entity/entity = combat_self()
	var/datum/component/netrun_node/node = entity?.host_node
	if(!istype(entity) || !node?.is_online() || is_locked() || entity.is_stunned())
		return FALSE
	for(var/datum/netrun_file/file as anything in node.salvage)
		if(file.uid != uid)
			continue
		var/file_name = file.name
		var/datum/netrun_file/recovered = store_file(file)
		if(!recovered)
			log_line("Нет места для [file.name]. Освободите память.", "bad")
			return FALSE
		node.salvage -= file
		node.refresh_salvage()
		SEND_SIGNAL(entity, COMSIG_NETRUN_SALVAGE_RECOVERED, recovered, node)
		log_line("Получено из обломков: [file_name].", "good")
		return TRUE
	return FALSE

/datum/netrun_console/proc/apply_program_effect(datum/netrun_program/program, target, datum/component/netrun_node/node, executable_name)
	executable_name = executable_name || program.name
	var/target_name = netrun_combatant_name(target)
	program.apply(target, src)
	var/message = program.combat_message(target_name, executable_name)
	if(message)
		combat_log(message, "good")
	node.touch()
	node.add_log("[log_source()]: запущена программа [executable_name].")
