/// Один модуль крепости. Новый вид модуля - подтип со своим `kind` и параметрами.
/datum/netrun_fortress_module
	var/static/next_id = 0
	var/id
	var/kind
	var/name = "модуль"
	var/desc = ""
	var/max_integrity = 100
	var/integrity = 100
	var/build_time = 20 SECONDS
	var/slot_cost = 1
	var/max_per_fortress = 1
	var/status = NETRUN_FORT_MODULE_BUILDING
	var/build_until = 0
	/// Trap re-arm deadline.
	var/ready_at = 0
	/// Stun programs jam a module (turrets stop firing) until this time.
	var/jammed_until = 0
	var/datum/netrun_fortress/fortress

/datum/netrun_fortress_module/New(datum/netrun_fortress/fortress, instant = FALSE)
	id = "fort-module-[++next_id]"
	src.fortress = fortress
	if(instant)
		status = NETRUN_FORT_MODULE_ONLINE
		integrity = max_integrity
	else
		status = NETRUN_FORT_MODULE_BUILDING
		// Scaffolding is fragile: a construction site can be torn down before it stands.
		integrity = max(1, round(max_integrity / 4))
		build_until = world.time + build_time

/datum/netrun_fortress_module/Destroy()
	fortress = null
	return ..()

/datum/netrun_fortress_module/get_netrun_combatant()
	RETURN_TYPE(/datum/component/netrun_combatant)
	return LoadComponent(/datum/component/netrun_combatant/fortress)

/datum/netrun_fortress_module/proc/is_jammed()
	return world.time < jammed_until

/// The UI distinguishes a standing module on an unpowered node.
/datum/netrun_fortress_module/proc/display_status()
	if(status == NETRUN_FORT_MODULE_ONLINE && (QDELETED(fortress?.node) || fortress.slots_max() <= 0 || !fortress.node.is_online()))
		return "offline"
	return status

/datum/netrun_fortress_module/proc/ui_entry()
	var/remaining
	if(status == NETRUN_FORT_MODULE_BUILDING)
		remaining = max(0, CEILING((build_until - world.time) / (1 SECONDS), 1))
	else if(kind == NETRUN_FORT_TRAP && ready_at > world.time)
		remaining = CEILING((ready_at - world.time) / (1 SECONDS), 1)
	if(is_jammed() && jammed_until < INFINITY)
		remaining = CEILING((jammed_until - world.time) / (1 SECONDS), 1)
	return list("ref" = REF(src), "id" = id, "kind" = kind, "name" = name, "desc" = desc,
		"integrity" = round(integrity), "max_integrity" = max_integrity,
		"status" = display_status(), "remaining" = remaining, "jammed" = is_jammed(),
		"repair_command" = "fort_repair@[id]", "dismantle_command" = "fort_dismantle@[id]")

/datum/netrun_fortress_module/proc/complete_build()
	if(status != NETRUN_FORT_MODULE_BUILDING || QDELETED(fortress))
		return
	status = NETRUN_FORT_MODULE_ONLINE
	integrity = max_integrity
	build_until = 0
	fortress.node?.add_log("Крепость [fortress.name]: модуль «[name]» введён в строй.")
	var/datum/netrun_console/owner = fortress.owner_ref?.resolve()
	owner?.log_line("Крепость [fortress.name]: модуль «[name]» построен.", "good")
	fortress.refresh_vault()

/datum/netrun_fortress_module/proc/take_damage(amount, reason, datum/netrun_console/attacker)
	if(status == NETRUN_FORT_MODULE_DESTROYED || QDELETED(fortress) || !IS_FINITE(amount) || amount <= 0)
		return
	integrity = max(0, integrity - amount)
	if(integrity <= 0)
		destroyed()
	fortress.note_attack(attacker, src)
	if(status == NETRUN_FORT_MODULE_DESTROYED)
		fortress.release_defeat_loot(attacker)
	fortress.changed()

/datum/netrun_fortress_module/proc/destroyed()
	status = NETRUN_FORT_MODULE_DESTROYED
	build_until = 0
	jammed_until = 0
	var/datum/component/netrun_node/node = fortress.node
	node?.add_log("Крепость [fortress.name]: модуль «[name]» разрушен.")
	node?.network?.add_log("Узел [node.address]: разрушен модуль крепости «[name]».", TRUE)
	if(node)
		SSnetrun.post_event("purge", null, node.address)
	fortress.refresh_vault()

/// Repairs return a destroyed module to service; `quiet` skips the shared change publication.
/datum/netrun_fortress_module/proc/repair(amount, quiet = FALSE)
	if(QDELETED(fortress) || status == NETRUN_FORT_MODULE_BUILDING || !IS_FINITE(amount) || amount <= 0)
		return FALSE
	if(status == NETRUN_FORT_MODULE_DESTROYED)
		status = NETRUN_FORT_MODULE_ONLINE
		integrity = 0
		fortress.refresh_vault()
	integrity = min(max_integrity, integrity + amount)
	if(!quiet)
		fortress.changed()
	return TRUE

/datum/netrun_fortress_module/proc/jam(duration)
	if(status != NETRUN_FORT_MODULE_ONLINE || kind != NETRUN_FORT_TURRET)
		return
	jammed_until = max(jammed_until, world.time + duration)
	if(fortress?.turret_fire_at && !fortress.intact_count(NETRUN_FORT_TURRET, TRUE))
		fortress.cancel_turret()
	fortress?.changed()

/datum/netrun_fortress_module/wall
	kind = NETRUN_FORT_WALL
	name = "Стена"
	desc = "Повышает защиту узла на 1 (суммарно не больше +2) и не даёт взламывать узел, пока стоит. Осаждается из соседних узлов."
	max_integrity = 160
	build_time = 20 SECONDS
	slot_cost = 2
	max_per_fortress = 3

/datum/netrun_fortress_module/gate
	kind = NETRUN_FORT_GATE
	name = "Врата"
	desc = "Не пускают в узел процессы без доступа ПОЛЬЗОВАТЕЛЯ, даже с ключом ЛВС. Свои и владелец проходят."
	max_integrity = 130
	build_time = 25 SECONDS
	slot_cost = 2
	max_per_fortress = 1

/datum/netrun_fortress_module/turret
	kind = NETRUN_FORT_TURRET
	name = "Турель"
	desc = "В бою залп стоит батарее 2 ОД и готовится с предупреждением; бьёт нарушителей и недавних осаждающих в соседних узлах. Вне боя интервал — 3 секунды. Оглушение заклинивает турель."
	max_integrity = 90
	build_time = 30 SECONDS
	slot_cost = 2
	max_per_fortress = 2

/datum/netrun_fortress_module/trap
	kind = NETRUN_FORT_TRAP
	name = "Ловушка"
	desc = "Оглушает вошедшего нарушителя на 3 секунды и добавляет его сеансу 15% трассировки; перезаряжается 30 секунд."
	max_integrity = 60
	build_time = 15 SECONDS
	slot_cost = 1
	max_per_fortress = 2

/datum/netrun_fortress_module/alarm
	kind = NETRUN_FORT_ALARM
	name = "Сигнализация"
	desc = "Сообщает о нарушителях и атаках сетевой полиции, владельцу и защите ЛВС."
	max_integrity = 50
	build_time = 10 SECONDS
	slot_cost = 1
	max_per_fortress = 1

/datum/netrun_fortress_module/vault
	kind = NETRUN_FORT_VAULT
	name = "Хранилище"
	desc = "Добавляет узлу память; посторонним файлы узла доступны только с ROOT."
	max_integrity = 110
	build_time = 30 SECONDS
	slot_cost = 2
	max_per_fortress = 1

/datum/netrun_fortress_module/regen
	kind = NETRUN_FORT_REGEN
	name = "Регенератор"
	desc = "Чинит самый повреждённый модуль и восстанавливает ICE. В бою — один раз за свой ход за 1 ОД, вне боя — раз в 5 секунд."
	max_integrity = 80
	build_time = 25 SECONDS
	slot_cost = 2
	max_per_fortress = 1

/// Ordered catalogue for build menus and commands.
/proc/netrun_fortress_kinds()
	var/static/list/kinds = list(NETRUN_FORT_WALL, NETRUN_FORT_GATE, NETRUN_FORT_TURRET, NETRUN_FORT_TRAP, NETRUN_FORT_ALARM, NETRUN_FORT_VAULT, NETRUN_FORT_REGEN)
	return kinds

/proc/netrun_fortress_module_type(kind)
	var/static/list/types
	if(!types)
		types = list()
		for(var/datum/netrun_fortress_module/path as anything in subtypesof(/datum/netrun_fortress_module))
			if(initial(path.kind))
				types[initial(path.kind)] = path
	return istext(kind) ? types[kind] : null

// MARK: Боевой интерфейс модуля

/datum/component/netrun_combatant/fortress
	kind = "fortress"
	hostile = TRUE

/datum/component/netrun_combatant/fortress/Initialize()
	if(!istype(parent, /datum/netrun_fortress_module))
		return COMPONENT_INCOMPATIBLE

/datum/component/netrun_combatant/fortress/node()
	var/datum/netrun_fortress_module/module = parent
	return module.fortress?.node

/datum/component/netrun_combatant/fortress/display_name()
	var/datum/netrun_fortress_module/module = parent
	return "[module.name] · [module.fortress?.name]"

/datum/component/netrun_combatant/fortress/integrity_payload()
	var/datum/netrun_fortress_module/module = parent
	return list("cur" = round(module.integrity), "max" = module.max_integrity,
		"stunned" = module.is_jammed(), "shielded" = FALSE)

/datum/component/netrun_combatant/fortress/damage(amount, reason, datum/netrun_console/attacker)
	var/datum/netrun_fortress_module/module = parent
	module.take_damage(amount, reason, attacker)

/datum/component/netrun_combatant/fortress/stun(duration)
	var/datum/netrun_fortress_module/module = parent
	module.jam(duration)

/datum/component/netrun_combatant/fortress/shield(pct, duration)
	return

/datum/component/netrun_combatant/fortress/heal(amount)
	var/datum/netrun_fortress_module/module = parent
	if(module.status == NETRUN_FORT_MODULE_ONLINE)
		module.repair(amount)

/// Outer works can be engaged from a directly linked neighbour by a resident process.
/datum/component/netrun_combatant/fortress/allows_remote_attack(datum/netrun_console/console, datum/component/netrun_node/local_node)
	var/datum/netrun_fortress_module/module = parent
	var/datum/netrun_fortress/fortress = module.fortress
	var/mob/camera/netrun_entity/entity = console?.combat_self()
	if(QDELETED(fortress?.node) || QDELETED(entity) || !local_node || entity.host_node != local_node || local_node == fortress.node)
		return FALSE
	if(!(module in fortress.siege_targets()))
		return FALSE
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	return (fortress.node.address in graph.neighbors(local_node.address, FALSE)) && netrun_link_available(local_node, fortress.node)

/datum/component/netrun_combatant/fortress/protected_by_station()
	var/datum/netrun_fortress_module/module = parent
	return module.fortress?.faction == NETRUN_FACTION_STATION

/datum/component/netrun_combatant/fortress/ui_entry()
	. = ..()
	var/datum/netrun_fortress_module/module = parent
	.["module"] = module.kind
	.["faction"] = module.fortress?.faction
