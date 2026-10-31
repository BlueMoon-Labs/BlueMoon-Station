/**
 * Сетевая полиция: станционный процесс с законным доступом ПОЛЬЗОВАТЕЛЯ во всех
 * станционных ЛВС. Обходит сеть, осматривает узлы обычными командами и работает
 * с журналом инцидентов: приходит на место, предупреждает нарушителя, при отказе
 * уйти атакует с телеграфом, отслеживает удалённый взлом и пишет рапорт СБ.
 */
/datum/netrun_bot_program/police
	id = NETRUN_BOT_POLICE
	name = "Сетевая полиция"
	desc = "Станционный процесс правопорядка: патрулирует всю сеть, расследует инциденты и обезвреживает нарушителей."
	faction = NETRUN_FACTION_STATION
	sanctioned = TRUE
	max_integrity = 160
	programs = list("assault", "strike", "blackout", "barrier", "patch")
	name_prefix = "NETPOL"
	avatar = "eye"
	accent = "cyan"
	tagline = "служит и защищает сеть"
	console_type = /datum/netrun_console/entity/bot/police
	extra_behavior_modules = list(/datum/netrun_entity_module/bot_local/watch/police)
	think_idle = 3 SECONDS
	flee_ratio = 0.15
	lifetime = 8 MINUTES

/datum/netrun_bot_program/police/on_spawn(mob/camera/netrun_entity/bot/bot)
	. = ..()
	bot.get_netrun_machine_service("security.monitor")

/datum/netrun_bot_program/police/plan(datum/netrun_bot_brain/brain)
	var/datum/netrun_incident/incident = brain.claimed_incident() || brain.claim_incident()
	if(incident)
		brain.push_goal(new /datum/netrun_bot_goal/investigate(brain, incident))
		return
	brain.push_goal(new /datum/netrun_bot_goal/police_patrol(brain))

/// Legal USER on every station LAN; never ROOT, never on isolated segments.
/datum/netrun_console/entity/bot/police

/datum/netrun_console/entity/bot/police/New(atom/host, origin)
	. = ..()
	intrusion.trace_mult = 0

/datum/netrun_console/entity/bot/police/compute_legit_node_level(datum/component/netrun_node/node, fresh = FALSE)
	. = ..()
	if(node?.network && !node.network.isolated)
		. = max(., NETRUN_ACCESS_USER)

/datum/netrun_console/entity/bot/police/legit_network_level(datum/netrun_network/network, fresh = FALSE)
	. = ..()
	if(network && !network.isolated)
		. = max(., NETRUN_ACCESS_GUEST)

// MARK: Инциденты

/datum/netrun_bot_brain
	var/datum/weakref/incident_ref
	/// weakref(process) -> world.time of the warning.
	var/list/warned = list()
/// Cancellation/expiry must not reserve an incident until this entire process dies.
/datum/netrun_bot_brain/proc/release_incident()
	var/datum/netrun_incident/incident = incident_ref?.resolve()
	if(incident?.claimed_by() == src)
		incident.claim(null)
	incident_ref = null

/datum/netrun_bot_brain/proc/claimed_incident()
	var/datum/netrun_incident/incident = incident_ref?.resolve()
	if(incident && incident.is_open() && incident.claimed_by() == src)
		return incident
	incident_ref = null
	return null

/// The most severe open incident nobody else handles; single low reports wait for a repeat.
/datum/netrun_bot_brain/proc/claim_incident()
	for(var/datum/netrun_incident/incident as anything in SSnetrun.open_incidents())
		var/datum/claimer = incident.claimed_by()
		if(claimer && claimer != src)
			continue
		if(incident.severity < NETRUN_INCIDENT_MEDIUM && incident.reports < 2)
			continue
		if(incident.address && is_blacklisted(incident.address))
			continue
		incident.claim(src)
		incident_ref = WEAKREF(incident)
		return incident
	return null

/// Close the record and file a report with the security LAN and the NTnet IDS.
/datum/netrun_bot_brain/proc/police_report(datum/netrun_incident/incident, resolution)
	if(!incident || incident.closed)
		return
	incident.close(resolution)
	incident_ref = null
	var/text = "[owner.real_name]: [incident.id] ([incident.kind])[incident.address ? " в узле [incident.address]" : ""]: [resolution]."
	SSnetrun.ntnet_log(text, TRUE)
	for(var/id in SSnetrun.networks)
		var/datum/netrun_network/network = SSnetrun.networks[id]
		if(!network.isolated && netrun_network_department(network) == "security")
			network.add_log(text, TRUE)
	var/datum/netrun_file_store/store = owner.console.inventory.local_store
	var/list/reports = list()
	for(var/datum/netrun_file/file as anything in store.files)
		if(file.kind == NETRUN_FILE_TEXT && findtext(file.name, "report-") == 1)
			reports += file
	while(length(reports) >= 4)
		var/datum/netrun_file/oldest = reports[1]
		reports.Cut(1, 2)
		store.delete_file(oldest)
	owner.console.store_file(new /datum/netrun_file("report-[lowertext(incident.id)].txt", NETRUN_FILE_TEXT, "[STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)] [text]\nПодозреваемый: [incident.suspect_name || "не установлен"]. Отчётов: [incident.reports]."))

/// A suspect is a rogue process, or a process without USER here that is a real threat.
/datum/netrun_bot_brain/proc/is_suspect(mob/camera/netrun_entity/entity, datum/component/netrun_node/node)
	if(!istype(entity) || entity == owner || QDELETED(entity) || QDELETED(entity.console))
		return FALSE
	if(entity.netrun_faction() == NETRUN_FACTION_ROGUE)
		return TRUE
	if(!entity.defense_threat())
		return FALSE
	return entity.console.node_level(node) < NETRUN_ACCESS_USER

/datum/netrun_bot_brain/proc/find_suspect(datum/component/netrun_node/node, datum/netrun_incident/incident)
	var/datum/named = incident?.suspect()
	if(istype(named, /mob/camera/netrun_entity))
		var/mob/camera/netrun_entity/entity = named
		if(entity.host_node == node && is_suspect(entity, node))
			return entity
	for(var/mob/camera/netrun_entity/entity as anything in node.entities)
		if(is_suspect(entity, node))
			return entity
	return null

/// Rogue processes are engaged at once; a player process is warned and gets five seconds to leave.
/datum/netrun_bot_brain/proc/confront(mob/camera/netrun_entity/suspect, datum/component/netrun_node/node)
	if(istype(suspect, /mob/camera/netrun_entity/bot))
		mark_enemy(suspect)
		return
	var/datum/weakref/reference = WEAKREF(suspect)
	var/warned_at = warned[reference]
	if(!warned_at)
		if(!owner.console.signal_entity(node, REF(suspect), "Сетевая полиция [owner.real_name]: несанкционированный процесс в узле [node.address]. Покиньте узел в течение 5 секунд, иначе процесс будет обезврежен."))
			return
		warned[reference] = world.time
		while(length(warned) > 16)
			warned.Cut(1, 2)
		return
	if(world.time - warned_at >= 5 SECONDS)
		mark_enemy(suspect)

/// Remote breaches against this node or its LAN are traced back while the police stands here.
/datum/netrun_bot_brain/proc/counter_trace(datum/component/netrun_node/node)
	if(!length(netrun_countertrace_targets(node)))
		if(command_id == "countertrace")
			clear_command()
		return FALSE
	var/result = command_step(node, "countertrace")
	if(result != NETRUN_BOT_GOAL_CONTINUE)
		clear_command()
	return TRUE

/// Perception may observe active attacks, but mutation belongs to a delivered node command.
/proc/netrun_countertrace_targets(datum/component/netrun_node/node)
	. = list()
	if(QDELETED(node))
		return
	for(var/datum/netrun_console/console as anything in SSnetrun.currentbreaches)
		if(QDELETED(console) || console.is_locked())
			continue
		var/datum/netrun_breach/breach = console.intrusion.breach
		if(!breach)
			continue
		if(breach.target_id != node.address && !(breach.target_kind == "network" && node.network && breach.target_id == node.network.id))
			continue
		. += console

/datum/netrun_command/countertrace
	id = "countertrace"
	name = "Контртрассировка"
	desc = "Установить источник недавней атаки на 45 секунд и повысить трассировку активных взломщиков на 8%."
	help = "Нужен законный доступ ПОЛЬЗОВАТЕЛЯ к узлу. Полученный взломом доступ не позволяет выдавать себя за его защитника."
	access = NETRUN_ACCESS_USER
	trace = 0
	read_only = TRUE
	icon = "shield-halved"

/datum/netrun_command/countertrace/ui_entry(datum/component/netrun_node/node, datum/netrun_console/console, full_id)
	. = ..()
	if(console.legit_node_level(node) < NETRUN_ACCESS_USER)
		.["allowed"] = FALSE
		.["unavailable_reason"] = "Нужен законный доступ ПОЛЬЗОВАТЕЛЯ к узлу."

/datum/netrun_command/countertrace/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	if(console.legit_node_level(node) < NETRUN_ACCESS_USER)
		console.log_line("Контртрассировка требует законного доступа к узлу.", "bad")
		return null
	var/list/targets = netrun_countertrace_targets(node)
	// Capture attribution before trace can lock/disconnect the offending client.
	for(var/datum/netrun_console/attacker as anything in targets)
		if(attacker != console && attacker.intrusion.breach?.valid_target())
			node.observe_attack(attacker, "breach")
	var/identified = 0
	for(var/datum/netrun_attack_observation/observation as anything in console.security_session.observations(node))
		if(console.security_session.capture(observation, node))
			identified++
	var/tracked = 0
	for(var/datum/netrun_console/target as anything in targets)
		if(target == console)
			continue
		tracked++
		target.add_trace(8)
		target.log_line("Защитник [console.get_handle()] отслеживает взлом узла [node.address]: трассировка растёт.", "bad")
	if(tracked)
		SSnetrun.post_event("trace", null, node.address)
	return "Контртрассировка [node.address]: активных подключений — [tracked], установлено источников — [identified]. Откройте «Безопасность» для выбора на карте."

// MARK: Обход сети

/datum/controller/subsystem/netrun
	/// Node address -> world.time of the last delivered police inspection.
	var/list/police_inspected = list()

/// The least recently inspected reachable station LAN; recent activity draws the officer first.
/datum/netrun_bot_brain/proc/police_destination()
	return patrol_destination(null, TRUE)

/// Read the node journal with the ordinary command and look for repeated refusals.
/datum/netrun_bot_brain/proc/inspect(datum/component/netrun_node/node)
	var/result = command_step(node, "packet_log")
	if(result != NETRUN_BOT_GOAL_DONE)
		return result
	SSnetrun.police_inspected[node.address] = world.time
	// Store only what the ordinary delivered command actually returned. Incident
	// signals carry authoritative suspicious activity; no private journal is read here.
	var/datum/netrun_file_store/store = owner.console.inventory.local_store
	for(var/datum/netrun_file/file as anything in store.files.Copy())
		if(file.name == "last-inspection.txt" && file.kind == NETRUN_FILE_TEXT)
			store.delete_file(file)
	var/datum/netrun_file/report = new("last-inspection.txt", NETRUN_FILE_TEXT, command_result || "Журнал пуст.")
	if(!owner.console.store_file(report))
		qdel(report)
	var/mob/camera/netrun_entity/suspect = find_suspect(node, null)
	if(suspect)
		SSnetrun.report_incident(suspect.netrun_faction() == NETRUN_FACTION_ROGUE ? "rogue" : "intrusion", node, suspect, NETRUN_INCIDENT_MEDIUM, "[owner.real_name] застал процесс [suspect.real_name] без доступа.")
	return NETRUN_BOT_GOAL_DONE

/datum/netrun_bot_goal/police_patrol
	name = "обход сети"
	var/datum/weakref/target_ref
	var/target_name

/datum/netrun_bot_goal/police_patrol/New(datum/netrun_bot_brain/brain)
	..(brain, 2 MINUTES)

/datum/netrun_bot_goal/police_patrol/describe()
	return target_name ? "обход: [target_name]" : name

/datum/netrun_bot_goal/police_patrol/advance()
	// A fresh serious incident interrupts the round.
	if(brain.claimed_incident() || brain.claim_incident())
		return NETRUN_BOT_GOAL_DONE
	var/datum/component/netrun_node/target = target_ref?.resolve()
	if(!target)
		target = brain.police_destination()
		if(!target)
			return NETRUN_BOT_GOAL_FAILED
		target_ref = WEAKREF(target)
		target_name = "[target.network?.short_name] · [target.get_name()]"
	brain.state = "обход сети"
	switch(approach(target))
		if(NETRUN_BOT_MOVE_ARRIVED)
			return brain.inspect(target)
		if(NETRUN_BOT_MOVE_BLOCKED)
			return NETRUN_BOT_GOAL_FAILED
	return NETRUN_BOT_GOAL_CONTINUE

/datum/netrun_bot_goal/investigate
	name = "расследование"
	var/datum/weakref/incident_ref
	var/incident_id
	var/scanned = FALSE
	var/arrived_at = 0
	var/engaged = FALSE

/datum/netrun_bot_goal/investigate/New(datum/netrun_bot_brain/brain, datum/netrun_incident/incident)
	..(brain, 3 MINUTES)
	incident_ref = WEAKREF(incident)
	incident_id = incident.id

/datum/netrun_bot_goal/investigate/Destroy()
	var/datum/netrun_incident/incident = incident_ref?.resolve()
	if(incident?.claimed_by() == brain)
		incident.claim(null)
	return ..()

/datum/netrun_bot_goal/investigate/describe()
	return "расследование [incident_id]"

/datum/netrun_bot_goal/investigate/advance()
	var/datum/netrun_incident/incident = incident_ref?.resolve()
	if(!incident || !incident.is_open())
		return NETRUN_BOT_GOAL_DONE
	var/datum/component/netrun_node/node = incident.node()
	if(!node)
		brain.police_report(incident, "место происшествия недоступно")
		return NETRUN_BOT_GOAL_DONE
	if(brain.owner.host_node != node)
		if(approach(node) == NETRUN_BOT_MOVE_BLOCKED)
			brain.police_report(incident, "нет пути к месту происшествия")
			return NETRUN_BOT_GOAL_FAILED
		return NETRUN_BOT_GOAL_CONTINUE
	brain.state = "расследование"
	if(!scanned)
		var/result = brain.command_step(node, "scan")
		if(result == NETRUN_BOT_GOAL_DONE)
			scanned = TRUE
			arrived_at = world.time
			brain.clear_command()
		else if(result == NETRUN_BOT_GOAL_FAILED)
			brain.police_report(incident, "доставка команды осмотра отклонена")
			return NETRUN_BOT_GOAL_FAILED
		return NETRUN_BOT_GOAL_CONTINUE
	if(brain.counter_trace(node))
		engaged = TRUE
		return NETRUN_BOT_GOAL_CONTINUE
	var/mob/camera/netrun_entity/suspect = brain.find_suspect(node, incident)
	if(suspect)
		engaged = TRUE
		arrived_at = world.time
		brain.confront(suspect, node)
		return NETRUN_BOT_GOAL_CONTINUE
	if(world.time - arrived_at < 8 SECONDS)
		return NETRUN_BOT_GOAL_CONTINUE
	brain.police_report(incident, engaged ? "нарушитель обезврежен или покинул узел" : "нарушений не обнаружено")
	return NETRUN_BOT_GOAL_DONE
