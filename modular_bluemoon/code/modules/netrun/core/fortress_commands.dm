// MARK: Команды крепости

/// Every node able to carry works publishes the build menu; repair/dismantle appear once works exist.
/atom/netrun_extra_commands()
	. = ..()
	var/datum/component/netrun_node/node = GetComponent(/datum/component/netrun_node)
	if(!node || netrun_fortress_slots(node) <= 0)
		return
	for(var/kind in netrun_fortress_kinds())
		. += "fort_build@[kind]"
	if(!node.fortress)
		return
	. += "fort_repair"
	for(var/kind in node.fortress.module_kinds())
		. += "fort_dismantle@[kind]"
	for(var/datum/netrun_fortress_module/module as anything in node.fortress.modules)
		. += "fort_repair@[module.id]"
		. += "fort_dismantle@[module.id]"

/// Shared refusal for the button and the delivered request.
/proc/netrun_fortress_build_denial(datum/component/netrun_node/node, datum/netrun_console/console, kind)
	var/datum/netrun_fortress_module/path = netrun_fortress_module_type(kind)
	if(!path)
		return "Неизвестный модуль крепости."
	var/slots = netrun_fortress_slots(node)
	if(slots <= 0)
		return "Этот узел не может нести укрепления."
	if(QDELETED(console) || console.is_locked() || !console.can_route(node) || !node.is_online())
		return "Нет действующего подключения к работающему узлу."
	if(console.node_level(node) < NETRUN_ACCESS_ROOT)
		return "Постройка крепости требует доступа ROOT к узлу."
	if(!console.daemon_capability("forge"))
		return "Нужен демон forge.exe в памяти или на подключённом шарде."
	var/datum/netrun_fortress/fortress = node.fortress
	if(!fortress)
		return initial(path.slot_cost) > slots ? "Не хватает слотов крепости." : null
	if(!fortress.can_build(console))
		return "Крепость принадлежит [fortress.owner_name || "станции"]: сначала разрушьте все её модули."
	if(fortress.ruined())
		return initial(path.slot_cost) > slots ? "Не хватает слотов крепости." : null
	if(fortress.count_kind(kind) >= initial(path.max_per_fortress))
		return "Достигнут предел модулей «[initial(path.name)]»."
	if(fortress.slots_used() + initial(path.slot_cost) > slots)
		return "Не хватает слотов крепости: [fortress.slots_used()]/[slots]."
	if(fortress.building_count() >= 2)
		return "Одновременно строятся не больше двух модулей."
	return null

/datum/netrun_command/fort_build
	id = "fort_build"
	name = "Построить модуль"
	desc = "Возвести модуль сетевой крепости в этом узле."
	help = "Нужны ROOT и демон forge.exe. Модуль занимает слоты крепости и строится несколько секунд; недостроенный модуль уязвим."
	access = NETRUN_ACCESS_ROOT
	trace = 5
	icon = "trowel-bricks"
	group = "fortress"

/datum/netrun_command/fort_build/display_name(datum/component/netrun_node/node, arg)
	var/datum/netrun_fortress_module/path = netrun_fortress_module_type(arg)
	return path ? "Построить: [initial(path.name)]" : name

/datum/netrun_command/fort_build/ui_entry(datum/component/netrun_node/node, datum/netrun_console/console, full_id)
	. = ..()
	var/arg = netrun_command_arg(full_id)
	var/datum/netrun_fortress_module/path = netrun_fortress_module_type(arg)
	if(path)
		.["desc"] = initial(path.desc)
	if(.["allowed"])
		var/reason = netrun_fortress_build_denial(node, console, arg)
		if(reason)
			.["allowed"] = FALSE
			.["unavailable_reason"] = reason

/datum/netrun_command/fort_build/execute(datum/component/netrun_node/node, datum/netrun_console/console, arg)
	var/reason = netrun_fortress_build_denial(node, console, arg)
	if(reason)
		console.log_line("[node.address]: [reason]", "bad")
		return null
	var/datum/netrun_fortress_module/module = SSnetrun.build_fortress_module(node, arg, console)
	if(!module)
		console.log_line("[node.address]: модуль не удалось заложить.", "bad")
		return null
	return "Строительство «[module.name]» начато: готовность через [module.build_time / (1 SECONDS)] с."

/datum/netrun_command/fort_repair
	id = "fort_repair"
	name = "Ремонт крепости"
	desc = "Восстановить самый повреждённый модуль крепости на 50 единиц; разрушенный возвращается в строй."
	help = "Своим и законным пользователям узла хватает доступа ПОЛЬЗОВАТЕЛЯ, чужую крепость чинят только с ROOT. Между ремонтами - 4 секунды."
	access = NETRUN_ACCESS_USER
	trace = 4
	icon = "screwdriver-wrench"
	group = "fortress"

/datum/netrun_command/fort_repair/display_name(datum/component/netrun_node/node, arg)
	var/datum/netrun_fortress_module/module = node?.fortress?.find_module(arg)
	return module ? "Ремонт: [module.name]" : name

/datum/netrun_command/fort_repair/ui_entry(datum/component/netrun_node/node, datum/netrun_console/console, full_id)
	. = ..()
	if(.["allowed"])
		var/reason = node?.fortress?.repair_denial(console, netrun_command_arg(full_id))
		if(reason)
			.["allowed"] = FALSE
			.["unavailable_reason"] = reason

/datum/netrun_command/fort_repair/execute(datum/component/netrun_node/node, datum/netrun_console/console, arg)
	var/datum/netrun_fortress/fortress = node.fortress
	if(!fortress)
		console.log_line("[node.address]: в узле нет крепости.", "bad")
		return null
	var/reason = fortress.repair_denial(console, arg)
	if(reason)
		console.log_line("[node.address]: [reason]", "bad")
		return null
	var/datum/netrun_fortress_module/module = arg ? fortress.find_module(arg) : fortress.most_damaged()
	if(!module)
		return "Все модули крепости целы."
	fortress.next_repair = world.time + 4 SECONDS
	var/was_destroyed = module.status == NETRUN_FORT_MODULE_DESTROYED
	module.repair(50)
	node.add_log("[console.log_source()]: ремонт модуля «[module.name]».")
	return was_destroyed ? "Модуль «[module.name]» восстановлен из обломков." : "Модуль «[module.name]» отремонтирован: [round(module.integrity)]/[module.max_integrity]."

/datum/netrun_command/fort_dismantle
	id = "fort_dismantle"
	name = "Разобрать модуль"
	desc = "Снять модуль крепости и освободить его слоты."
	help = "Нужен ROOT. Разбирать могут владелец, свои и законный администратор узла."
	access = NETRUN_ACCESS_ROOT
	trace = 6
	icon = "hammer"
	danger = TRUE
	group = "fortress"

/datum/netrun_command/fort_dismantle/display_name(datum/component/netrun_node/node, arg)
	var/datum/netrun_fortress_module/module = node?.fortress?.find_module(arg)
	if(module)
		return "Разобрать: [module.name]"
	var/datum/netrun_fortress_module/path = netrun_fortress_module_type(arg)
	return path ? "Разобрать: [initial(path.name)]" : name

/datum/netrun_command/fort_dismantle/ui_entry(datum/component/netrun_node/node, datum/netrun_console/console, full_id)
	. = ..()
	if(.["allowed"])
		var/reason = node?.fortress?.dismantle_denial(console, netrun_command_arg(full_id))
		if(reason)
			.["allowed"] = FALSE
			.["unavailable_reason"] = reason

/datum/netrun_command/fort_dismantle/execute(datum/component/netrun_node/node, datum/netrun_console/console, arg)
	var/datum/netrun_fortress/fortress = node.fortress
	if(!fortress)
		console.log_line("[node.address]: в узле нет крепости.", "bad")
		return null
	var/reason = fortress.dismantle_denial(console, arg)
	if(reason)
		console.log_line("[node.address]: [reason]", "bad")
		return null
	var/datum/netrun_fortress_module/target = fortress.find_module(arg)
	if(!target)
		console.log_line("[node.address]: такого модуля в крепости нет.", "bad")
		return null
	var/module_name = target.name
	var/fortress_name = fortress.name
	node.add_log("[console.log_source()]: разобран модуль «[module_name]».")
	fortress.remove_module(target)
	return "Модуль «[module_name]» крепости [fortress_name] разобран."

// MARK: forge.exe

/datum/netrun_program/daemon/forge
	id = "forge"
	name = "forge.exe"
	desc = "Конструктор сетевых крепостей: с доступом ROOT позволяет возводить, чинить и разбирать модули укреплений узла."
	size = 4
	bonus_kind = "forge"
	bonus = 1
	loot_weight = 0.5

/obj/item/netrun_shard/forge
	name = "data shard (forge.exe)"
	desc = "Шард с конструктором сетевых крепостей. Вставьте в деку или терминал."
	icon_state = "datadisk2"
	preload_daemons = list("forge")

/datum/design/netrun_daemon_forge
	name = "Fortress Forge Daemon"
	desc = "Шард с forge.exe: постройка модулей сетевых крепостей."
	id = "netrun_daemon_forge"
	build_type = PROTOLATHE
	materials = list(/datum/material/glass = 700, /datum/material/gold = 300, /datum/material/silver = 300)
	build_path = /obj/item/netrun_shard/forge
	category = list("Computer Parts")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING | DEPARTMENTAL_FLAG_SCIENCE
