/**
 * Боевая программа ("карточка") - активный файл, который раннер запускает против
 * процесса, с которым делит узел: ICE или другой сущности. В отличие от демонов
 * (пассивные бонусы) программы применяются вручную, имеют перезарядку, а часть -
 * одноразовые (consumable): такой файл удаляется после запуска.
 *
 * Новую программу добавляет подтип - консоли находят файлы через этот реестр.
 */
/datum/netrun_program
	var/id
	var/name = "program.exe"
	var/desc = "Боевая сетевая программа."
	var/help = ""
	var/size = 2
	var/file_kind = NETRUN_FILE_PROGRAM
	/// Роль: атака/щит/оглушение/ремонт/очистка
	var/role = NETRUN_PROGRAM_ATTACK
	/// Сила эффекта (урон/лечение/щит в процентах/время оглушения в децисекундах)
	var/power = 20
	/// Перезарядка на этой консоли, децисекунды
	var/cooldown = 2 SECONDS
	/// Одноразовая "карточка": файл сгорает после применения
	var/consumable = FALSE
	/// Нужна враждебная цель (FALSE - действие на себя)
	var/needs_target = TRUE
	/// Трассировка за запуск (шум боевой активности)
	var/trace = 3
	var/icon = "bolt"
	/// ICE announces this preparation period before applying the same effect.
	var/windup = 2.5 SECONDS
	/// Encounter costs are shared by players, bots and ICE; legacy clocks remain
	/// available to out-of-encounter consumers of the same ordinary program files.
	var/ap_cost = 2
	var/cooldown_turns = 0
	var/shield_turns = 1
	var/stun_turns = 1
	/// Category is UI/tactical metadata; execution is dispatched through procs.
	var/console_usable = TRUE
	var/hostile = FALSE
	var/biofeedback = FALSE
	var/targets_breach = FALSE

/// Registry definitions are shared. Per-cast state belongs to the caller.
/datum/netrun_program/proc/apply(datum/target, datum/netrun_console/attacker, damage_scale = 1)
	return

/datum/netrun_program/proc/combat_message(target_name, executable_name)
	return null

/datum/netrun_program/proc/can_apply_status(datum/netrun_combat_encounter/encounter, datum/target)
	return TRUE

/// Return TRUE only when a turn-owned status was changed.
/datum/netrun_program/proc/apply_status(datum/netrun_combat_encounter/encounter, datum/target)
	return FALSE

/datum/netrun_program/proc/status_denial()
	return "Программа не может применить эффект к этой цели."

/datum/netrun_program/proc/turn_value(effective_limit)
	return power

/datum/netrun_program/proc/bot_value(effective_limit, turn_based)
	if(!turn_based)
		return power
	return turn_value(effective_limit) / max(1, ap_cost) * (consumable ? 0.8 : 1)

/datum/netrun_program/proc/casting_payload(damage_scale = 1)
	return list("name" = name, "role" = role, "stun_turns" = 0, "power" = power)

/datum/netrun_program/proc/ice_should_use(datum/netrun_ice/ice)
	return TRUE

/datum/netrun_program/proc/valid_ice_target(datum/netrun_ice/ice, datum/target, fresh_access = FALSE)
	if(QDELETED(target))
		return FALSE
	if(!needs_target)
		return target == ice
	if(istype(target, /datum/netrun_ice))
		return ice.hostile_actor(target, ice.node)
	var/mob/camera/netrun_entity/entity = target
	if(!istype(entity) || entity.host_node != ice.node || world.time < entity.combat_ignore_until)
		return FALSE
	if(!fresh_access || ice.enemy_ref?.resolve() == entity)
		return ice.is_intruder(entity, ice.node)
	var/datum/netrun_path_tree/tree = entity.console?.connection.read_path_tree(TRUE)
	. = ice.is_intruder(entity, ice.node, tree)
	entity.console?.release_path_tree(tree)

/datum/netrun_program/proc/capture_ice_target(datum/netrun_ice/ice, datum/target)
	return

/datum/netrun_program/proc/ice_target_current(datum/netrun_ice/ice, datum/target)
	return TRUE

/datum/netrun_program/proc/ice_counterplay(turn_based)
	return turn_based ? "Подготовьте щит в свой ход. В свой ход можно отступить за 1 ОД." : "Щит снизит урон; оглушение ICE или выход из узла сорвут атаку."

/datum/netrun_program/proc/ice_trace_advice(turn_based)
	return ""

/datum/netrun_program/proc/create_file()
	return new /datum/netrun_file(name, file_kind, id, size)

/datum/netrun_program/proc/ui_entry()
	return list(
		"id" = id,
		"name" = name,
		"desc" = desc,
		"size" = size,
		"role" = role,
		"power" = power,
		"cooldown" = round(cooldown / (1 SECONDS), 0.1),
		"consumable" = consumable,
		"needs_target" = needs_target,
		"icon" = icon,
		"windup" = windup / (1 SECONDS),
		"ap_cost" = ap_cost,
		"cooldown_turns" = cooldown_turns,
		"shield_turns" = shield_turns,
		"stun_turns" = stun_turns,
	)

// MARK: Реестр

/datum/controller/subsystem/netrun
	var/list/datum/netrun_program/programs

/datum/controller/subsystem/netrun/proc/get_program(id)
	RETURN_TYPE(/datum/netrun_program)
	if(!programs)
		programs = list()
		for(var/datum/netrun_program/path as anything in subtypesof(/datum/netrun_program))
			var/program_id = initial(path.id)
			if(!program_id || initial(path.file_kind) != NETRUN_FILE_PROGRAM)
				continue
			programs[program_id] = new path
	return istext(id) ? programs[lowertext(trim(id))] : null

/datum/controller/subsystem/netrun/proc/program_definitions()
	get_program(null)
	. = list()
	for(var/id in programs)
		var/datum/netrun_program/program = programs[id]
		. += list(program.ui_entry())

/proc/netrun_program_file(id)
	var/datum/netrun_program/program = SSnetrun.get_program(id)
	return program?.create_file()

// MARK: Полиморфные семейства эффектов (без id, не попадают в реестр)

/datum/netrun_program/attack
	hostile = TRUE
	biofeedback = TRUE

/datum/netrun_program/attack/apply(datum/target, datum/netrun_console/attacker, damage_scale = 1)
	netrun_combatant_hit(target, round(power * damage_scale), "программа [name]", attacker)

/datum/netrun_program/attack/combat_message(target_name, executable_name)
	return "[executable_name] -> [target_name]: урон [power]."

/datum/netrun_program/attack/turn_value(effective_limit)
	return min(power, effective_limit)

/datum/netrun_program/attack/casting_payload(damage_scale = 1)
	. = ..()
	.["power"] = round(power * damage_scale)

/datum/netrun_program/stun
	role = NETRUN_PROGRAM_STUN
	hostile = TRUE

/datum/netrun_program/stun/apply(datum/target, datum/netrun_console/attacker, damage_scale = 1)
	netrun_combatant_stun(target, power)

/datum/netrun_program/stun/combat_message(target_name, executable_name)
	return "[executable_name] -> [target_name]: цель оглушена."

/datum/netrun_program/stun/can_apply_status(datum/netrun_combat_encounter/encounter, datum/target)
	return !encounter.member(target)?.stun_immune

/datum/netrun_program/stun/apply_status(datum/netrun_combat_encounter/encounter, datum/target)
	if(stun_turns <= 0)
		return FALSE
	var/datum/netrun_turn_participant/participant = encounter.member(target)
	var/datum/actor = participant?.actor()
	if(istype(actor, /datum/netrun_fortress))
		var/datum/netrun_fortress/fortress = actor
		return fortress.apply_turn_stun(src, target, participant)
	var/datum/body = participant?.body_ref?.resolve()
	if(!body)
		return FALSE
	participant.stun_turns = max(participant.stun_turns, stun_turns)
	if(istype(body, /datum/netrun_ice))
		var/datum/netrun_ice/ice = body
		ice.combat_stun_until = INFINITY
	else
		var/mob/camera/netrun_entity/entity = body
		entity.combat_stun_until = INFINITY
	return TRUE

/datum/netrun_program/stun/status_denial()
	return "Цель адаптировалась к оглушению: она должна получить полноценный ход перед повторным подавлением."

/datum/netrun_program/stun/turn_value(effective_limit)
	return 20 * max(1, stun_turns)

/datum/netrun_program/stun/casting_payload(damage_scale = 1)
	. = ..()
	.["stun_turns"] = stun_turns

/datum/netrun_program/stun/ice_counterplay(turn_based)
	return turn_based ? "Подавление пропустит ход. Контрмеры доступны в ваш ход; выход стоит 1 ОД." : "Оглушение ICE или выход из узла сорвут оглушение."

/datum/netrun_program/shield
	role = NETRUN_PROGRAM_SHIELD
	needs_target = FALSE

/datum/netrun_program/shield/apply(datum/target, datum/netrun_console/attacker, damage_scale = 1)
	netrun_combatant_shield(target, power, 5 SECONDS)

/datum/netrun_program/shield/combat_message(target_name, executable_name)
	return "[executable_name]: защитный контур поднят."

/datum/netrun_program/shield/can_apply_status(datum/netrun_combat_encounter/encounter, datum/target)
	var/datum/netrun_turn_participant/participant = encounter.member(target)
	var/new_factor = clamp(1 - power / 100, 0.1, 1)
	var/datum/body = participant?.body_ref?.resolve()
	if(istype(body, /mob/camera/netrun_entity))
		var/mob/camera/netrun_entity/entity = body
		if(world.time < entity.combat_shield_until && entity.combat_shield_factor < new_factor)
			return FALSE
	else if(istype(body, /datum/netrun_ice))
		var/datum/netrun_ice/ice = body
		if(world.time < ice.combat_shield_until && ice.combat_shield_factor < new_factor)
			return FALSE
	return TRUE

/datum/netrun_program/shield/apply_status(datum/netrun_combat_encounter/encounter, datum/target)
	var/datum/netrun_turn_participant/participant = encounter.member(target)
	var/datum/body = participant?.body_ref?.resolve()
	if(!body || shield_turns <= 0)
		return FALSE
	var/new_factor = clamp(1 - power / 100, 0.1, 1)
	if(participant.shield_until_turn && participant.shield_factor < new_factor)
		return FALSE
	participant.shield_until_turn = participant.own_turn + shield_turns
	participant.shield_factor = new_factor
	if(istype(body, /datum/netrun_ice))
		var/datum/netrun_ice/ice = body
		ice.combat_shield_until = INFINITY
	else
		var/mob/camera/netrun_entity/entity = body
		entity.combat_shield_until = INFINITY
	return TRUE

/datum/netrun_program/shield/status_denial()
	return "Более сильный защитный контур уже действует."

/datum/netrun_program/shield/turn_value(effective_limit)
	return power * max(1, shield_turns)

/datum/netrun_program/shield/ice_should_use(datum/netrun_ice/ice)
	return ice.integrity <= ice.max_integrity * 0.75 && world.time >= ice.combat_shield_until

/datum/netrun_program/repair
	role = NETRUN_PROGRAM_REPAIR
	needs_target = FALSE

/datum/netrun_program/repair/apply(datum/target, datum/netrun_console/attacker, damage_scale = 1)
	netrun_combatant_heal(target, power)

/datum/netrun_program/repair/combat_message(target_name, executable_name)
	return "[executable_name]: целостность восстановлена."

/datum/netrun_program/repair/turn_value(effective_limit)
	return min(power, effective_limit)

// MARK: Атакующие программы

/// Встроенная атака процесса: слабая, но всегда доступна и не занимает память.
/// Благодаря ей сущность может повредить ICE даже с пустым хранилищем.
/datum/netrun_program/attack/sting
	id = "sting"
	name = "sting"
	desc = "Встроенный процессорный удар. Слабый, но бесплатный и не теряется."
	role = NETRUN_PROGRAM_ATTACK
	power = 8
	ap_cost = 1
	cooldown = 2 SECONDS
	size = 0
	trace = 2
	icon = "hand-fist"

/// Встроенная защита процесса: всегда доступна, слабее печатных щитов, не теряется.
/datum/netrun_program/shield/shell
	id = "shell"
	name = "shell"
	desc = "Встроенный защитный контур: снижает входящий урон на четверть на один ход."
	role = NETRUN_PROGRAM_SHIELD
	power = 25
	ap_cost = 1
	cooldown_turns = 1
	cooldown = 12 SECONDS
	size = 0
	needs_target = FALSE
	trace = 1
	icon = "shield"

/datum/netrun_program/attack/strike
	id = "strike"
	name = "strike.exe"
	desc = "Короткий пакетный удар по целостности процесса. Малая перезарядка."
	role = NETRUN_PROGRAM_ATTACK
	power = 22
	cooldown = 2 SECONDS
	size = 2
	trace = 3
	icon = "bolt"

/datum/netrun_program/attack/assault
	id = "assault"
	name = "assault.exe"
	desc = "Тяжёлый эксплойт: много урона, но долгая перезарядка и заметный след."
	role = NETRUN_PROGRAM_ATTACK
	power = 40
	ap_cost = 3
	cooldown_turns = 1
	cooldown = 5 SECONDS
	size = 4
	trace = 7
	icon = "burst"

/datum/netrun_program/attack/logic_bomb
	id = "logic_bomb"
	name = "logic_bomb.card"
	desc = "Одноразовая логическая бомба. Огромный урон, сгорает после запуска."
	help = "Карточка расходуется при применении."
	role = NETRUN_PROGRAM_ATTACK
	power = 70
	ap_cost = 3
	cooldown = 1 SECONDS
	size = 3
	consumable = TRUE
	trace = 10
	icon = "bomb"

// MARK: Поддержка

/datum/netrun_program/stun/blackout
	id = "blackout"
	name = "blackout.exe"
	desc = "Прерывает действия цели оглушением на один ход."
	cooldown_turns = 2
	role = NETRUN_PROGRAM_STUN
	power = 4 SECONDS
	cooldown = 8 SECONDS
	size = 3
	trace = 4
	icon = "ban"

/datum/netrun_program/stun/emp
	id = "emp"
	name = "emp.card"
	desc = "Одноразовый ЭМИ-разряд: оглушает на два хода. Сгорает после запуска, заметный след."
	ap_cost = 3
	stun_turns = 2
	help = "Карточка расходуется при применении."
	role = NETRUN_PROGRAM_STUN
	power = 6 SECONDS
	cooldown = 1 SECONDS
	size = 3
	consumable = TRUE
	trace = 8
	icon = "bolt-lightning"

/datum/netrun_program/shield/barrier
	id = "barrier"
	name = "barrier.exe"
	desc = "Снижает входящий урон вдвое на один ход."
	cooldown_turns = 1
	role = NETRUN_PROGRAM_SHIELD
	power = 50
	cooldown = 10 SECONDS
	size = 3
	needs_target = FALSE
	trace = 2
	icon = "shield-halved"

/datum/netrun_program/shield/fortify
	id = "fortify"
	name = "fortify.exe"
	desc = "Тяжёлый защитный контур: снижает входящий урон на 65% на два хода."
	ap_cost = 3
	cooldown_turns = 2
	shield_turns = 2
	role = NETRUN_PROGRAM_SHIELD
	power = 65
	cooldown = 14 SECONDS
	size = 4
	needs_target = FALSE
	trace = 2
	icon = "shield"

/datum/netrun_program/repair/patch
	id = "patch"
	name = "patch.exe"
	desc = "Восстанавливает часть собственной целостности."
	role = NETRUN_PROGRAM_REPAIR
	power = 30
	cooldown_turns = 1
	cooldown = 8 SECONDS
	size = 2
	needs_target = FALSE
	trace = 1
	icon = "briefcase-medical"

/// Counter-intrusion uses the same program/cooldown machinery as physical attacks.
/datum/netrun_program/trace
	id = "trace"
	name = "trace.exe"
	desc = "Увеличивает трассировку активного взломщика после предупреждения."
	role = NETRUN_PROGRAM_TRACE
	power = 6
	cooldown_turns = 1
	cooldown = 5 SECONDS
	windup = 3 SECONDS
	icon = "fingerprint"
	console_usable = FALSE
	biofeedback = TRUE
	targets_breach = TRUE

/datum/netrun_program/trace/apply(datum/target, datum/netrun_console/attacker, damage_scale = 1)
	if(istype(target, /datum/netrun_console))
		var/datum/netrun_console/console = target
		console.add_trace(power)

/datum/netrun_program/trace/valid_ice_target(datum/netrun_ice/ice, datum/target, fresh_access = FALSE)
	if(!ice.valid_trace_target(target))
		return FALSE
	if(!fresh_access)
		return TRUE
	var/datum/netrun_console/victim = target
	var/datum/netrun_path_tree/tree = victim.connection.read_path_tree(TRUE)
	. = victim.can_route(ice.node, tree) && ice.valid_trace_target(victim)
	victim.release_path_tree(tree)

/datum/netrun_program/trace/capture_ice_target(datum/netrun_ice/ice, datum/target)
	var/datum/netrun_console/victim = target
	ice.pending_breach_ref = WEAKREF(victim.intrusion.breach)

/datum/netrun_program/trace/ice_target_current(datum/netrun_ice/ice, datum/target)
	var/datum/netrun_console/victim = target
	return ice.pending_breach_ref?.resolve() == victim.intrusion.breach

/datum/netrun_program/trace/ice_trace_advice(turn_based)
	return turn_based ? " Прервите взлом, чтобы сорвать трассировку; подавление ICE доступно в ваш ход." : " Прервите взлом или оглушите ICE, чтобы сорвать трассировку."

// MARK: Встроенные варианты и печатная тактика

/datum/netrun_program/attack/pulse
	id = "pulse"
	name = "pulse"
	desc = "Встроенный средний удар: 18 урона за 2 ОД. Не занимает память."
	power = 18
	size = 0
	trace = 2
	icon = "wave-square"

/datum/netrun_program/attack/surge
	id = "surge"
	name = "surge"
	desc = "Встроенный тяжёлый удар: 28 урона за 3 ОД. Не занимает память."
	power = 28
	ap_cost = 3
	size = 0
	trace = 4
	icon = "burst"

/datum/netrun_program/repair/mend
	id = "mend"
	name = "mend"
	desc = "Встроенное восстановление: 8 целостности за 1 ОД. Слабее файлов ремонта."
	role = NETRUN_PROGRAM_REPAIR
	power = 8
	ap_cost = 1
	cooldown_turns = 1
	cooldown = 8 SECONDS
	size = 0
	needs_target = FALSE
	trace = 0
	icon = "kit-medical"

/datum/netrun_program/attack/needle
	id = "needle"
	name = "needle.exe"
	desc = "Компактный быстрый удар: 12 урона за 1 ОД. Оставляет действия для защиты или ремонта."
	power = 12
	ap_cost = 1
	size = 2
	cooldown = 1 SECONDS
	trace = 2
	icon = "syringe"

/datum/netrun_program/attack/lance
	id = "lance"
	name = "lance.exe"
	desc = "Точный тяжёлый пакет: 34 урона за 2 ОД. Требует перезарядки между ходами и больше памяти, чем strike."
	power = 34
	ap_cost = 2
	cooldown_turns = 1
	cooldown = 5 SECONDS
	size = 4
	trace = 6
	icon = "crosshairs"

/datum/netrun_program/shield/aegis
	id = "aegis"
	name = "aegis.exe"
	desc = "Дорогая оборона: снижает входящий урон на 70% на два хода, занимая все 3 ОД."
	role = NETRUN_PROGRAM_SHIELD
	power = 70
	ap_cost = 3
	shield_turns = 2
	cooldown_turns = 2
	cooldown = 16 SECONDS
	size = 5
	needs_target = FALSE
	trace = 3
	icon = "shield"

/datum/netrun_program/repair/renew
	id = "renew"
	name = "renew.exe"
	desc = "Быстрый ремонт: восстанавливает 18 целостности за 1 ОД с перезарядкой между ходами."
	role = NETRUN_PROGRAM_REPAIR
	power = 18
	ap_cost = 1
	cooldown_turns = 1
	cooldown = 10 SECONDS
	size = 3
	needs_target = FALSE
	trace = 1
	icon = "heart-pulse"

/datum/netrun_program/stun/jam
	id = "jam"
	name = "jam.exe"
	desc = "Экономное подавление: оглушает цель на один ход за 1 ОД, затем долго перезаряжается."
	role = NETRUN_PROGRAM_STUN
	power = 2 SECONDS
	ap_cost = 1
	stun_turns = 1
	cooldown_turns = 2
	cooldown = 12 SECONDS
	size = 3
	trace = 4
	icon = "ban"

/// Compatibility entry point for callers outside the program hierarchy.
/// Each effect decides how scaling applies; registry definitions stay immutable.
/proc/netrun_apply_program(datum/netrun_program/program, target, datum/netrun_console/attacker, damage_scale = 1)
	return program?.apply(target, attacker, damage_scale)

// MARK: Печатаемые/добываемые шарды с программами

/obj/item/netrun_shard/strike
	name = "data shard (strike.exe)"
	desc = "Шард с базовой атакующей программой для сетевого боя."
	icon_state = "datadisk2"
	preload_programs = list("strike")

/obj/item/netrun_shard/combat
	name = "data shard (combat suite)"
	desc = "Боевой набор сетевика: стандартный и быстрый удары, щит и два варианта ремонта."
	icon_state = "datadisk3"
	preload_programs = list("strike", "barrier", "patch", "needle", "renew")

/obj/item/netrun_shard/assault
	name = "data shard (assault.exe)"
	desc = "Шард с тяжёлой атакующей программой."
	icon_state = "datadisk2"
	preload_programs = list("assault", "lance")

/obj/item/netrun_shard/logic_bomb
	name = "data shard (logic_bomb.card)"
	desc = "Шард с одноразовой логической бомбой. Военного образца."
	icon_state = "datadisk3"
	preload_programs = list("logic_bomb")

/obj/item/netrun_shard/blackout
	name = "data shard (blackout.exe)"
	icon_state = "datadisk2"
	preload_programs = list("blackout", "jam")

/obj/item/netrun_shard/emp
	name = "data shard (emp.card)"
	desc = "Шард с одноразовым ЭМИ-разрядом для сетевого боя."
	icon_state = "datadisk3"
	preload_programs = list("emp")

/obj/item/netrun_shard/fortify
	name = "data shard (fortify.exe)"
	desc = "Шард с тяжёлой защитной программой сетевика."
	icon_state = "datadisk2"
	preload_programs = list("fortify", "aegis")
