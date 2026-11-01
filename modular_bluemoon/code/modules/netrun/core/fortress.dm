/**
 * Сетевая крепость: укрепления одного узла из модулей (стены, врата, турели,
 * ловушки, сигнализация, хранилище, регенератор). Принадлежит узлу (`node.fortress`).
 *
 * Модули - боевые цели. Внешние стены и врата осаждают из соседнего узла, остальное
 * открывается после падения стен. У крепости один отменяемый таймер: он ставит задачу
 * планировщика только при работе (стройка, турель с целью, ремонт регенератором).
 */
/datum/netrun_fortress
	var/name = "Крепость"
	var/faction = NETRUN_FACTION_OWNER
	var/preset_id
	var/preset_name
	var/datum/component/netrun_node/node
	var/list/datum/netrun_fortress_module/modules = list()
	var/datum/weakref/owner_ref
	var/owner_ckey
	var/owner_name
	var/owner_faction_id
	var/timer_id
	var/next_wake = 0
	var/next_alarm = 0
	var/next_repair = 0
	var/next_turret = 0
	var/next_regen = 0
	/// Weakref of an entity that attacked a module -> world.time of the last hit.
	var/list/besiegers = list()
	var/datum/weakref/turret_target_ref
	var/turret_fire_at = 0
	/// Storage currently added to the node by vault modules.
	var/vault_bonus = 0
	/// Only local defenders are observed; an idle fortress owns no polling task.
	var/list/observed_ice = list()

/datum/netrun_fortress/New(datum/component/netrun_node/node, name, faction = NETRUN_FACTION_OWNER, datum/netrun_console/owner)
	src.node = node
	if(name)
		src.name = name
	src.faction = faction
	if(owner)
		set_owner(owner)
		if(faction == NETRUN_FACTION_OWNER)
			src.faction = owner.get_personal_faction_id()
	SSnetrun.fortress_nodes[node.address] = node
	RegisterSignal(node, COMSIG_NETRUN_NODE_CHANGED, PROC_REF(on_node_changed))
	RegisterSignal(node, COMSIG_NETRUN_TURN_CHANGED, PROC_REF(on_turn_changed))
	refresh_defenders()

/datum/netrun_fortress/Destroy()
	clear_timer()
	clear_defeat_loot()
	SSnetrun.task_scheduler?.cancel("fortress", src)
	cancel_turret()
	var/datum/component/netrun_node/old = node
	if(old)
		UnregisterSignal(old, COMSIG_NETRUN_NODE_CHANGED)
		UnregisterSignal(old, COMSIG_NETRUN_TURN_CHANGED)
		SSnetrun.fortress_nodes -= old.address
		apply_vault_bonus(0)
		if(old.fortress == src)
			old.fortress = null
	node = null
	QDEL_LIST(modules)
	owner_ref = null
	besiegers = null
	turn_siege_leases = null
	turn_jammed_modules = null
	QDEL_NULL(turn_volley_definition)
	for(var/datum/netrun_ice/ice as anything in observed_ice)
		UnregisterSignal(ice, list(COMSIG_NETRUN_COMBAT_CHANGED, COMSIG_PARENT_QDELETING))
	observed_ice.Cut()
	if(!QDELETED(old))
		old.notify_changed()
		SEND_SIGNAL(SSnetrun, COMSIG_NETRUN_FORTRESS_CHANGED, old)
	return ..()

/datum/netrun_fortress/proc/set_owner(datum/netrun_console/owner)
	owner_ref = WEAKREF(owner)
	owner_ckey = owner.operator?.ckey
	owner_name = owner.get_handle()
	owner_faction_id = owner.get_personal_faction_id()

/// A ruined fortress (every module destroyed) can be claimed by whoever rebuilds it.
/datum/netrun_fortress/proc/claim(datum/netrun_console/console)
	clear_ruins()
	set_owner(console)
	faction = console.get_personal_faction_id()
	name = "Крепость [owner_name]"
	preset_id = null
	preset_name = null
	node.add_log("Руины крепости захвачены: [owner_name].")
	node.network?.add_log("Узел [node.address]: руины крепости захвачены.", TRUE)

/// Clearing ruins is explicit rebuilding; regeneration never resurrects destroyed works.
/datum/netrun_fortress/proc/clear_ruins()
	if(!ruined())
		return FALSE
	QDEL_LIST(modules)
	modules = list()
	besiegers.Cut()
	cancel_turret()
	refresh_vault()
	return TRUE

// MARK: Свои и чужие

/// The builder's session, the same player, or (for private fortresses) that player's agents.
/datum/netrun_fortress/proc/is_owner(datum/netrun_console/console)
	if(QDELETED(console))
		return FALSE
	if(owner_faction_id && owner_faction_id != NETRUN_FACTION_OWNER && SSnetrun.netrun_faction_family(owner_faction_id) == NETRUN_FACTION_OWNER)
		return console.get_personal_faction_id() == owner_faction_id
	var/datum/netrun_console/owner = owner_ref?.resolve()
	if(owner && console == owner)
		return TRUE
	if(owner_ckey && console.operator?.ckey == owner_ckey)
		return TRUE
	var/mob/camera/netrun_entity/entity = console.combat_self()
	if(istype(entity))
		var/datum/netrun_console/master = entity.netrun_owner_console()
		if(master && ((owner && master == owner) || (owner_ckey && master.operator?.ckey == owner_ckey)))
			return TRUE
	return FALSE

/// Friends pass gates, walls and vaults. Station works trust legitimate users and sanctioned processes.
/datum/netrun_fortress/proc/is_friendly(datum/netrun_console/console)
	if(QDELETED(console) || QDELETED(node))
		return FALSE
	if(is_owner(console))
		return TRUE
	if(faction != NETRUN_FACTION_OWNER && SSnetrun.netrun_faction_family(faction) == NETRUN_FACTION_OWNER)
		return console.get_personal_faction_id() == faction
	var/mob/camera/netrun_entity/entity = console.combat_self()
	switch(faction)
		if(NETRUN_FACTION_ROGUE)
			return istype(entity) && entity.netrun_faction() == NETRUN_FACTION_ROGUE
		if(NETRUN_FACTION_STATION)
			if(istype(entity) && !entity.defense_threat())
				return TRUE
			return console.legit_node_level(node) >= NETRUN_ACCESS_USER
	return FALSE

/// Traps, turrets and alarms act only against hostile processes standing in or next to the node.
/datum/netrun_fortress/proc/hostile_to(mob/camera/netrun_entity/entity)
	if(!istype(entity) || QDELETED(entity) || QDELETED(entity.console) || QDELETED(node))
		return FALSE
	if(is_friendly(entity.console))
		return FALSE
	if(faction == NETRUN_FACTION_ROGUE)
		return TRUE
	if(faction == NETRUN_FACTION_STATION && !entity.defense_threat())
		return FALSE
	return entity.console.node_level(node) < NETRUN_ACCESS_USER

/// Building in an existing fortress belongs to its friends, the node's legitimate administrator, or to a claimer of ruins.
/datum/netrun_fortress/proc/can_build(datum/netrun_console/console)
	return is_friendly(console) || console.legit_node_level(node) >= NETRUN_ACCESS_ROOT || ruined()

/datum/netrun_fortress/proc/can_dismantle(datum/netrun_console/console)
	return is_friendly(console) || console.legit_node_level(node) >= NETRUN_ACCESS_ROOT

// MARK: Состояние

/datum/netrun_fortress/proc/intact_count(kind, active_only = FALSE)
	. = 0
	for(var/datum/netrun_fortress_module/module as anything in modules)
		if(module.kind == kind && module.status == NETRUN_FORT_MODULE_ONLINE && (!active_only || !module.is_jammed()))
			.++

/datum/netrun_fortress/proc/count_kind(kind)
	. = 0
	for(var/datum/netrun_fortress_module/module as anything in modules)
		if(module.kind == kind)
			.++

/datum/netrun_fortress/proc/building_count()
	. = 0
	for(var/datum/netrun_fortress_module/module as anything in modules)
		if(module.status == NETRUN_FORT_MODULE_BUILDING)
			.++

/datum/netrun_fortress/proc/ruined()
	if(!length(modules))
		return FALSE
	for(var/datum/netrun_fortress_module/module as anything in modules)
		if(module.status != NETRUN_FORT_MODULE_DESTROYED)
			return FALSE
	return TRUE

/datum/netrun_fortress/proc/slots_used()
	. = 0
	for(var/datum/netrun_fortress_module/module as anything in modules)
		. += module.slot_cost

/datum/netrun_fortress/proc/slots_max()
	return netrun_fortress_slots(node)

/datum/netrun_fortress/proc/module_kinds()
	. = list()
	for(var/datum/netrun_fortress_module/module as anything in modules)
		. |= module.kind

/datum/netrun_fortress/proc/security_bonus()
	if(slots_max() <= 0)
		return 0
	return min(NETRUN_FORT_MAX_SECURITY_BONUS, intact_count(NETRUN_FORT_WALL))

/datum/netrun_fortress/proc/gate_blocks(datum/netrun_console/console)
	return slots_max() > 0 && intact_count(NETRUN_FORT_GATE) && !is_friendly(console)

/datum/netrun_fortress/proc/blocks_breach(datum/netrun_console/console)
	return slots_max() > 0 && intact_count(NETRUN_FORT_WALL) && !is_friendly(console)

/datum/netrun_fortress/proc/file_access_level(datum/netrun_console/console)
	return slots_max() > 0 && intact_count(NETRUN_FORT_VAULT) && !is_friendly(console) ? NETRUN_ACCESS_ROOT : 0

/// Everything still standing, including works under construction.
/datum/netrun_fortress/proc/combat_targets()
	. = list()
	for(var/datum/netrun_fortress_module/module as anything in modules)
		if(module.status != NETRUN_FORT_MODULE_DESTROYED)
			. += module

/// Outer works face the neighbours; the inner modules open up once every wall is down.
/datum/netrun_fortress/proc/siege_targets()
	. = list()
	var/walls_up = intact_count(NETRUN_FORT_WALL)
	for(var/datum/netrun_fortress_module/module as anything in modules)
		if(module.status == NETRUN_FORT_MODULE_DESTROYED)
			continue
		if(walls_up && module.kind != NETRUN_FORT_WALL && module.kind != NETRUN_FORT_GATE)
			continue
		. += module

/datum/netrun_fortress/proc/damaged_modules()
	. = list()
	for(var/datum/netrun_fortress_module/module as anything in modules)
		if(module.status == NETRUN_FORT_MODULE_DESTROYED || (module.status == NETRUN_FORT_MODULE_ONLINE && module.integrity < module.max_integrity))
			. += module

/datum/netrun_fortress/proc/most_damaged()
	var/best_ratio = 1
	for(var/datum/netrun_fortress_module/module as anything in damaged_modules())
		if(module.status == NETRUN_FORT_MODULE_DESTROYED)
			return module
		var/ratio = module.integrity / module.max_integrity
		if(ratio < best_ratio)
			best_ratio = ratio
			. = module

/datum/netrun_fortress/proc/add_module(kind, instant = FALSE)
	var/path = netrun_fortress_module_type(kind)
	if(!path)
		return null
	var/datum/netrun_fortress_module/module_type = path
	if(count_kind(kind) >= initial(module_type.max_per_fortress) || slots_used() + initial(module_type.slot_cost) > slots_max())
		return null
	var/datum/netrun_fortress_module/module = new path(src, instant)
	modules += module
	if(instant)
		refresh_vault()
	return module

/datum/netrun_fortress/proc/remove_module(datum/netrun_fortress_module/module)
	if(!(module in modules))
		return FALSE
	modules -= module
	qdel(module)
	refresh_vault()
	if(!length(modules))
		qdel(src)
		return TRUE
	changed()
	return TRUE

/// Map overlay summary; read for every node entry, so it never touches routes.
/datum/netrun_fortress/proc/map_summary()
	var/intact = 0
	var/walls = 0
	var/damaged = FALSE
	for(var/datum/netrun_fortress_module/module as anything in modules)
		switch(module.status)
			if(NETRUN_FORT_MODULE_ONLINE)
				intact++
				if(module.kind == NETRUN_FORT_WALL)
					walls++
				if(module.integrity < module.max_integrity)
					damaged = TRUE
			if(NETRUN_FORT_MODULE_DESTROYED)
				damaged = TRUE
	return list("tier" = intact >= 6 ? 3 : (intact >= 3 ? 2 : 1), "walls" = walls, "faction" = faction,
		"damaged" = damaged, "online" = intact > 0 && !QDELETED(node) && slots_max() > 0 && node.is_online())

/datum/netrun_fortress/proc/manage_denial(datum/netrun_console/viewer, level)
	if(slots_max() <= 0)
		return "Этот узел больше не может нести действующие укрепления."
	if(!node.is_online())
		return "Узел отключён; управление крепостью недоступно."
	if(level < NETRUN_ACCESS_ROOT)
		return "Управление крепостью требует доступа ROOT к узлу."
	if(!viewer.daemon_capability("forge"))
		return "Нужен демон forge.exe в памяти или на подключённом шарде."
	if(!can_build(viewer))
		return "Крепость принадлежит [owner_name || "станции"]: сначала разрушьте все её модули."
	return null

/datum/netrun_fortress/proc/ui_payload(datum/netrun_console/viewer, level)
	if(level < NETRUN_ACCESS_GUEST)
		return null
	var/list/entries = list()
	for(var/datum/netrun_fortress_module/module as anything in modules)
		entries += list(module.ui_entry())
	var/reason = manage_denial(viewer, level)
	var/datum/netrun_file_store/store = node?.file_store
	return list("name" = name, "owner" = owner_name || (faction == NETRUN_FACTION_STATION ? "Станция" : null),
		"faction" = faction, "preset" = preset_name, "security_bonus" = security_bonus(),
		"slots_used" = slots_used(), "slots_max" = slots_max(), "modules" = entries,
		"can_manage" = !reason, "manage_reason" = reason,
		"storage" = list("used" = store?.used() || 0, "capacity" = store?.capacity || 0, "vault_bonus" = vault_bonus,
			"required_access" = max(NETRUN_ACCESS_USER, file_access_level(viewer))))

/datum/netrun_fortress/proc/find_module(id_or_kind)
	for(var/datum/netrun_fortress_module/module as anything in modules)
		if(module.id == id_or_kind)
			return module
	// Old CLI kind-based commands remain valid and prefer a ruin over intact works.
	for(var/datum/netrun_fortress_module/module as anything in modules)
		if(module.kind == id_or_kind && (!. || module.status == NETRUN_FORT_MODULE_DESTROYED))
			. = module

/// Buttons and delivered commands share exactly the same authorization and target checks.
/datum/netrun_fortress/proc/repair_denial(datum/netrun_console/console, module_id)
	if(QDELETED(console) || console.is_locked() || !console.can_route(node) || !node.is_online())
		return "Нет действующего подключения к работающему узлу."
	var/level = console.node_level(node)
	if(level < NETRUN_ACCESS_USER || (!is_friendly(console) && level < NETRUN_ACCESS_ROOT))
		return "Ремонт чужой крепости требует ROOT; своим нужен доступ ПОЛЬЗОВАТЕЛЯ."
	if(world.time < next_repair)
		return "Ремонтные процессы ещё заняты."
	var/datum/netrun_fortress_module/module = module_id ? find_module(module_id) : most_damaged()
	if(!module)
		return module_id ? "Модуль больше не существует." : "Все модули крепости целы."
	if(module.status == NETRUN_FORT_MODULE_BUILDING)
		return "Строящийся модуль ещё нельзя ремонтировать."
	if(module.integrity >= module.max_integrity)
		return "Модуль уже полностью восстановлен."
	return null

/datum/netrun_fortress/proc/dismantle_denial(datum/netrun_console/console, module_id)
	if(QDELETED(console) || console.is_locked() || !console.can_route(node) || !node.is_online())
		return "Нет действующего подключения к работающему узлу."
	if(console.node_level(node) < NETRUN_ACCESS_ROOT)
		return "Разбор крепости требует ROOT."
	if(!can_dismantle(console))
		return "Разбирать крепость могут только владелец, свои и законный администратор."
	if(!find_module(module_id))
		return "Модуль больше не существует."
	return null

/datum/netrun_fortress/proc/needs_live_refresh()
	var/in_combat = get_combat_encounter()?.active
	if(!in_combat && turret_fire_at > world.time)
		return TRUE
	for(var/datum/netrun_fortress_module/module as anything in modules)
		if(module.status == NETRUN_FORT_MODULE_BUILDING || (!in_combat && (module.is_jammed() || module.ready_at > world.time)))
			return TRUE
	return FALSE

// MARK: Изменения и таймер

/datum/netrun_fortress/proc/on_node_changed(datum/source, datum/component/netrun_node/changed_node, flags)
	SIGNAL_HANDLER
	if(flags & NETRUN_CHANGED_OCCUPANTS)
		refresh_defenders()
	if(flags & (NETRUN_CHANGED_BINDING | NETRUN_CHANGED_STATE))
		refresh_vault()
	schedule()

/datum/netrun_fortress/proc/refresh_defenders()
	for(var/datum/netrun_ice/ice as anything in observed_ice.Copy())
		if(QDELETED(ice) || !(ice in node.netrun_ice))
			UnregisterSignal(ice, list(COMSIG_NETRUN_COMBAT_CHANGED, COMSIG_PARENT_QDELETING))
			observed_ice -= ice
	for(var/datum/netrun_ice/ice as anything in node.netrun_ice)
		if(!QDELETED(ice) && !observed_ice[ice])
			observed_ice[ice] = TRUE
			RegisterSignal(ice, COMSIG_NETRUN_COMBAT_CHANGED, PROC_REF(on_defender_changed))
			RegisterSignal(ice, COMSIG_PARENT_QDELETING, PROC_REF(on_defender_deleted))

/datum/netrun_fortress/proc/on_defender_changed(datum/source)
	SIGNAL_HANDLER
	schedule()

/datum/netrun_fortress/proc/on_defender_deleted(datum/source)
	SIGNAL_HANDLER
	observed_ice -= source
	UnregisterSignal(source, list(COMSIG_NETRUN_COMBAT_CHANGED, COMSIG_PARENT_QDELETING))
	schedule()

/datum/netrun_fortress/proc/changed()
	if(QDELETED(src) || QDELETED(node))
		return
	if(!has_turn_battery())
		var/datum/netrun_combat_encounter/encounter = get_combat_encounter()
		for(var/datum/netrun_turn_participant/participant as anything in encounter?.participants)
			if(participant.actor() == src)
				encounter.remove(participant)
				break
	node.notify_changed()
	SEND_SIGNAL(SSnetrun, COMSIG_NETRUN_FORTRESS_CHANGED, node)
	schedule()

/datum/netrun_fortress/proc/refresh_vault()
	apply_vault_bonus(slots_max() > 0 && intact_count(NETRUN_FORT_VAULT) ? NETRUN_FORT_VAULT_STORAGE : 0)

/datum/netrun_fortress/proc/apply_vault_bonus(amount)
	if(amount == vault_bonus)
		return
	var/datum/netrun_file_store/store = node?.file_store
	if(!QDELETED(node) && store)
		store.capacity = max(0, store.capacity - vault_bonus + amount)
		store.notify_changed()
	vault_bonus = amount

/// The earliest moment the fortress has real work; INFINITY keeps it asleep.
/datum/netrun_fortress/proc/next_deadline()
	. = INFINITY
	if(QDELETED(node))
		return
	for(var/datum/netrun_fortress_module/module as anything in modules)
		if(module.status == NETRUN_FORT_MODULE_BUILDING)
			. = min(., module.build_until)
		if(module.status == NETRUN_FORT_MODULE_ONLINE && module.jammed_until > world.time)
			. = min(., module.jammed_until)
		if(module.status == NETRUN_FORT_MODULE_ONLINE && module.ready_at > world.time)
			. = min(., module.ready_at)
	if(slots_max() <= 0 || !node.is_online())
		return
	var/datum/netrun_combat_encounter/encounter = get_combat_encounter()
	if(encounter?.active)
		if(encounter.has_turn(src) && turret_fire_at)
			. = min(., turret_fire_at)
		return
	if(turret_fire_at)
		. = min(., turret_fire_at)
	else if(intact_count(NETRUN_FORT_TURRET, TRUE) && pick_turret_target())
		. = min(., max(world.time, next_turret))
	if(intact_count(NETRUN_FORT_REGEN) && needs_regen())
		. = min(., max(world.time, next_regen))

/datum/netrun_fortress/proc/schedule()
	if(QDELETED(src))
		return
	var/deadline = next_deadline()
	if(deadline == INFINITY)
		clear_timer()
		return
	deadline = max(world.time + NETRUN_EXECUTION_MIN_INTERVAL, deadline)
	if(timer_id && next_wake <= deadline)
		return
	clear_timer()
	next_wake = deadline
	timer_id = addtimer(CALLBACK(src, PROC_REF(wake)), deadline - world.time, TIMER_STOPPABLE | TIMER_DELETE_ME)

/datum/netrun_fortress/proc/clear_timer()
	if(timer_id)
		deltimer(timer_id)
	timer_id = null
	next_wake = 0

/datum/netrun_fortress/proc/wake()
	timer_id = null
	next_wake = 0
	if(QDELETED(src))
		return
	SSnetrun.get_task_scheduler().enqueue("fortress", src, NETRUN_TASK_NORMAL)

/datum/netrun_fortress/proc/process_tick()
	if(QDELETED(node))
		return
	var/updated = FALSE
	for(var/datum/netrun_fortress_module/module as anything in modules.Copy())
		if(module.status == NETRUN_FORT_MODULE_BUILDING && world.time >= module.build_until)
			module.complete_build()
			updated = TRUE
		if(module.jammed_until && world.time >= module.jammed_until)
			module.jammed_until = 0
			updated = TRUE
		if(module.ready_at && world.time >= module.ready_at)
			module.ready_at = 0
			updated = TRUE
	if(slots_max() <= 0 || !node.is_online())
		cancel_turret()
		var/datum/netrun_combat_encounter/encounter = get_combat_encounter()
		if(encounter?.active && encounter.has_turn(src) && !encounter.deferred)
			encounter.pass(src)
	else
		if(get_combat_encounter()?.active)
			process_turn_battery()
		else
			process_turret()
		if(!get_combat_encounter()?.active && intact_count(NETRUN_FORT_REGEN) && world.time >= next_regen && needs_regen())
			next_regen = world.time + 5 SECONDS
			regenerate()
			updated = TRUE
	if(updated)
		changed()

// MARK: Турели

/datum/netrun_fortress/proc/note_attack(datum/netrun_console/attacker, datum/netrun_fortress_module/module)
	var/mob/camera/netrun_entity/entity = attacker?.combat_self()
	if(istype(entity))
		besiegers[WEAKREF(entity)] = world.time
		while(length(besiegers) > 8)
			besiegers.Cut(1, 2)
	trigger_alarm(entity || attacker, "атакован модуль «[module.name]».")
	schedule()

/// A recent attacker waiting in a directly linked neighbour remains a valid turret target.
/datum/netrun_fortress/proc/besieging(mob/camera/netrun_entity/entity)
	if(!istype(entity) || QDELETED(entity) || !entity.host_node || entity.host_node == node)
		return FALSE
	var/hit_at = besiegers[WEAKREF(entity)]
	if(isnull(hit_at) || world.time - hit_at > 20 SECONDS)
		var/datum/netrun_combat_encounter/encounter = get_combat_encounter()
		if(!encounter?.active || !encounter.contains(entity) || !turn_siege_leases[WEAKREF(entity)])
			return FALSE
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	return (node.address in graph.neighbors(entity.host_node.address, FALSE)) && netrun_link_available(entity.host_node, node)

/datum/netrun_fortress/proc/valid_turret_target(mob/camera/netrun_entity/entity)
	if(!istype(entity) || QDELETED(entity))
		return FALSE
	if(is_friendly(entity.console))
		return FALSE
	return entity.host_node == node ? hostile_to(entity) : besieging(entity)

/datum/netrun_fortress/proc/pick_turret_target()
	var/mob/camera/netrun_entity/best
	for(var/mob/camera/netrun_entity/entity as anything in node.entities)
		if(hostile_to(entity) && (!best || entity.integrity < best.integrity))
			best = entity
	if(best)
		return best
	for(var/datum/weakref/reference as anything in besiegers)
		var/mob/camera/netrun_entity/entity = reference.resolve()
		if(besieging(entity))
			return entity
	return null

/datum/netrun_fortress/proc/cancel_turret(release_turn = TRUE)
	var/had_volley = !!turret_fire_at
	turret_target_ref = null
	turret_fire_at = 0
	if(had_volley && release_turn)
		get_combat_encounter()?.resolve(src)

/// Turrets warn first (like ICE), then strike if the target is still a valid one.
/datum/netrun_fortress/proc/process_turret()
	var/turrets = intact_count(NETRUN_FORT_TURRET, TRUE)
	if(!turrets)
		cancel_turret()
		return
	var/datum/netrun_combat_encounter/encounter = get_combat_encounter()
	var/already_in_combat = encounter?.active
	if(!encounter)
		var/mob/camera/netrun_entity/hostile = pick_turret_target()
		if(hostile)
			encounter = node.get_combat_encounter()
			encounter.join(src)
			if(!encounter.admit(src, 2, hostile) && !encounter.active)
				return
	if(encounter?.active && (!encounter.has_turn(src) || encounter.expired_input()))
		return
	if(turret_fire_at)
		if(world.time < turret_fire_at)
			return
		var/mob/camera/netrun_entity/target = turret_target_ref?.resolve()
		cancel_turret(FALSE)
		next_turret = world.time + 3 SECONDS
		if(!valid_turret_target(target))
			encounter?.resolve(src)
			return
		var/datum/netrun_program/strike = SSnetrun.get_program("strike")
		for(var/i in 1 to min(3, turrets))
			if(QDELETED(target))
				break
			netrun_apply_program(strike, target, null, 0.85)
		if(!QDELETED(encounter))
			encounter.resolve(src)
		if(QDELETED(target))
			return
		node.add_log("Турели крепости [name] бьют по [target.real_name].")
		target.console?.combat_log("Турели крепости [name] поразили ваш процесс.", "bad")
		SSnetrun.post_event("intrusion", null, node.address)
		return
	if(!encounter?.active && world.time < next_turret)
		return
	var/mob/camera/netrun_entity/target = pick_turret_target()
	if(!target)
		return
	if(encounter?.active)
		var/datum/netrun_program/volley = turn_volley_program()
		if(encounter.cooldown_remaining(src, volley) || !encounter.admit(src, volley.ap_cost, target) || !encounter.commit_program(src, volley, TRUE))
			return
	turret_target_ref = WEAKREF(target)
	var/telegraph = already_in_combat ? NETRUN_ICE_COMBAT_TELEGRAPH : NETRUN_ICE_MIN_TELEGRAPH
	turret_fire_at = world.time + telegraph
	to_chat(target, span_userdanger("Турели крепости [name] наводятся на ваш процесс: [telegraph / (1 SECONDS)] с до выстрела. Уйдите из зоны поражения или оглушите турель."))
	target.console?.combat_log("Турели крепости [name] наводятся на вас: [telegraph / (1 SECONDS)] с до выстрела.", "bad")

// MARK: Ловушки, сигнализация, ремонт

/datum/netrun_fortress/proc/armed_trap()
	for(var/datum/netrun_fortress_module/module as anything in modules)
		if(module.kind == NETRUN_FORT_TRAP && module.status == NETRUN_FORT_MODULE_ONLINE && world.time >= module.ready_at)
			return module
	return null

/// Called by entity.enter_node() after the arrival; the entity may be stunned or traced here.
/datum/netrun_fortress/proc/on_arrival(mob/camera/netrun_entity/entity)
	if(QDELETED(node) || slots_max() <= 0 || !node.is_online() || !hostile_to(entity))
		return
	var/datum/netrun_fortress_module/trap = armed_trap()
	if(trap)
		trap.ready_at = world.time + NETRUN_FORT_TRAP_REARM
		netrun_combatant_stun(entity, 3 SECONDS)
		to_chat(entity, span_userdanger("Ловушка крепости [name] захлопнулась: процесс оглушён, след раскрыт!"))
		node.add_log("Ловушка крепости [name] сработала на [entity.real_name].")
		entity.console?.combat_log("Ловушка крепости [name]: процесс оглушён, трассировка растёт.", "bad")
		entity.console?.add_trace(15)
	if(QDELETED(entity))
		return
	trigger_alarm(entity, "в узел вошёл [entity.real_name].")
	changed()

/datum/netrun_fortress/proc/trigger_alarm(datum/suspect, text)
	if(QDELETED(node) || !intact_count(NETRUN_FORT_ALARM) || world.time < next_alarm)
		return FALSE
	next_alarm = world.time + 15 SECONDS
	node.add_log("Сигнализация крепости [name]: [text]")
	node.network?.add_log("Сигнализация крепости [name] ([node.address]): [text]", TRUE)
	SSnetrun.report_incident("fortress", node, suspect, NETRUN_INCIDENT_HIGH, "Крепость [name]: [text]")
	var/datum/netrun_console/owner = owner_ref?.resolve()
	owner?.log_line("Сигнализация крепости [name] ([node.address]): [text]", "bad")
	node.wake_defenses()
	return TRUE

/datum/netrun_fortress/proc/needs_regen()
	for(var/datum/netrun_fortress_module/module as anything in modules)
		if(module.status == NETRUN_FORT_MODULE_ONLINE && module.integrity < module.max_integrity)
			return TRUE
	for(var/datum/netrun_ice/ice as anything in node.netrun_ice)
		if(!QDELETED(ice) && ice.integrity < ice.max_integrity)
			return TRUE
	return FALSE

/datum/netrun_fortress/proc/regenerate()
	var/datum/netrun_fortress_module/worst
	for(var/datum/netrun_fortress_module/module as anything in modules)
		if(module.status != NETRUN_FORT_MODULE_ONLINE || module.integrity >= module.max_integrity)
			continue
		if(!worst || module.integrity / module.max_integrity < worst.integrity / worst.max_integrity)
			worst = module
	worst?.repair(6, TRUE)
	for(var/datum/netrun_ice/ice as anything in node.netrun_ice)
		if(!QDELETED(ice) && ice.integrity < ice.max_integrity)
			ice.apply_heal(5)

/// Number of fortress slots a node offers; zero means it cannot be fortified.
/proc/netrun_fortress_slots(datum/component/netrun_node/node)
	if(QDELETED(node))
		return 0
	// Mobile endpoints never host works; the AI core is a mob but does not move.
	if(node.node_type != NETRUN_NODE_AI && node.is_dynamic())
		return 0
	switch(node.node_type)
		if(NETRUN_NODE_AI)
			return 16
		if(NETRUN_NODE_SERVER)
			return 12
		if(NETRUN_NODE_GATEWAY)
			return 10
		if(NETRUN_NODE_TERMINAL)
			return 8
		if(NETRUN_NODE_APC)
			return 6
	return 0

/// Physically adjacent nodes whose fortress currently offers siege targets.
/proc/netrun_adjacent_fortress_nodes(datum/component/netrun_node/node)
	. = list()
	if(!length(SSnetrun.fortress_nodes) || QDELETED(node))
		return
	var/datum/netrun_topology/graph = SSnetrun.topology
	if(!graph || graph.dirty)
		graph = SSnetrun.ensure_topology()
	for(var/address in graph.neighbors(node.address, FALSE))
		var/datum/component/netrun_node/neighbor = SSnetrun.fortress_nodes[address]
		if(QDELETED(neighbor) || !neighbor.fortress || !netrun_link_available(node, neighbor))
			continue
		if(length(neighbor.fortress.siege_targets()))
			. += neighbor

/datum/controller/subsystem/netrun
	/// address -> node carrying a fortress.
	var/list/fortress_nodes = list()

/// Start (or extend) a fortress with one module under construction for the given builder.
/datum/controller/subsystem/netrun/proc/build_fortress_module(datum/component/netrun_node/node, kind, datum/netrun_console/console)
	if(netrun_fortress_build_denial(node, console, kind))
		return null
	var/datum/netrun_fortress/fortress = node.fortress
	if(!fortress)
		fortress = new(node, "Крепость [console.get_handle()]", console.get_personal_faction_id(), console)
		node.fortress = fortress
		node.add_log("Заложена крепость: [fortress.name].")
	else if(fortress.ruined() && !fortress.is_friendly(console) && console.legit_node_level(node) < NETRUN_ACCESS_ROOT)
		fortress.claim(console)
	else if(fortress.ruined())
		fortress.clear_ruins()
	var/datum/netrun_fortress_module/module = fortress.add_module(kind, FALSE)
	if(!module)
		return null
	node.add_log("[console.log_source()]: начато строительство «[module.name]».")
	node.network?.add_log("Узел [node.address]: строится модуль крепости «[module.name]».")
	fortress.changed()
	return module

/datum/netrun_task/fortress
	kind = "fortress"

/datum/netrun_task/fortress/execute(datum/controller/subsystem/netrun/worker, datum/netrun_execution_limits/limits)
	var/datum/netrun_fortress/fortress = target()
	if(QDELETED(fortress))
		return FALSE
	fortress.process_tick()
	if(!QDELETED(fortress))
		fortress.schedule()
	return TRUE
