/// Relations and visitor pools are data, shared by combat, population and UI.
/datum/netrun_faction
	var/id
	var/name
	var/color = "#9ba8b7"
	var/list/enemies = list()
	var/arrival_weight = 0
	var/list/visitors = list()
	/// Stable policy family; a personal owner's distinct ID still belongs to owner.
	var/family

/datum/netrun_faction/proc/hostile_to(other)
	if(!other || other == id)
		return FALSE
	var/datum/netrun_faction/faction = SSnetrun.get_netrun_faction(other)
	return (other in enemies) || (SSnetrun.netrun_faction_family(other) in enemies) || (id in faction?.enemies) || ((family || id) in faction?.enemies)

/datum/netrun_faction/rogue
	id = NETRUN_FACTION_ROGUE
	name = "Дикие процессы"
	color = "#ed7687"
	enemies = list(NETRUN_FACTION_STATION, NETRUN_FACTION_OWNER, "redshift", "collective", "archivists")
	arrival_weight = 2
	visitors = list(NETRUN_BOT_RAIDER, "scavenger")

/datum/netrun_faction/station
	id = NETRUN_FACTION_STATION
	name = "Защита станции"
	color = "#72ddea"

/datum/netrun_faction/private
	id = NETRUN_FACTION_OWNER
	family = NETRUN_FACTION_OWNER
	name = "Частные агенты"
	color = "#77d9ad"

/// One principal owns its faction across devices; consoles only cache the lookup.
/datum/netrun_faction/private/personal
	id = null
	var/datum/weakref/principal_ref
	var/principal_key

/datum/netrun_faction/private/personal/New(datum/principal, faction_id, label)
	if(QDELETED(principal))
		return
	id = faction_id
	name = "Личная сеть [label]"
	var/static/list/personal_colors = list("#77d9ad", "#78bfff", "#d9a5ff", "#f2bf6c", "#74d9e8", "#e9a2c8", "#b8d77e", "#a6acef", "#efb191", "#79c7b4", "#d8c98b", "#a8c7e0")
	color = personal_colors[((max(1, SSnetrun.personal_faction_serial) - 1) % length(personal_colors)) + 1]
	principal_ref = WEAKREF(principal)
	principal_key = REF(principal)
	RegisterSignal(principal, COMSIG_PARENT_QDELETING, PROC_REF(on_owner_deleted))

/datum/netrun_faction/private/personal/proc/on_owner_deleted(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/netrun_faction/private/personal/Destroy()
	var/datum/principal = principal_ref?.resolve()
	if(principal)
		UnregisterSignal(principal, COMSIG_PARENT_QDELETING)
	if(id && SSnetrun.netrun_factions?[id] == src)
		SSnetrun.netrun_factions -= id
	if(principal_key && SSnetrun.personal_factions_by_principal[principal_key] == src)
		SSnetrun.personal_factions_by_principal -= principal_key
	principal_ref = null
	return ..()

/datum/netrun_faction/redshift
	id = "redshift"
	name = "Красное смещение"
	color = "#f18f65"
	enemies = list(NETRUN_FACTION_STATION, NETRUN_FACTION_OWNER, "collective", "archivists")
	arrival_weight = 3
	visitors = list("redshift_raider", "redshift_hacker")

/datum/netrun_faction/collective
	id = "collective"
	name = "Осколочный коллектив"
	color = "#b7a0ff"
	enemies = list("redshift")
	arrival_weight = 3
	visitors = list("collective_guard")

/datum/netrun_faction/archivists
	id = "archivists"
	name = "Вольный архив"
	color = "#d5c77d"
	enemies = list("redshift")
	arrival_weight = 2
	visitors = list("archive_collector")

/datum/controller/subsystem/netrun
	var/list/netrun_factions
	var/personal_faction_serial = 0
	var/list/personal_factions_by_principal = list()
	/// Separate visitor and per-faction limits leave room for station/player agents.
	var/visitor_limit = 12
	var/visitor_faction_limit = 4
	var/visitor_wave_min = 3
	var/visitor_wave_max = 4

/datum/controller/subsystem/netrun/proc/netrun_faction_family(id)
	var/datum/netrun_faction/faction = get_netrun_faction(id)
	if(faction)
		return faction.family || faction.id
	// Orphan cleanup is queued; an old personal ID cannot become immune in that gap.
	return istext(id) && findtext(id, "owner:") == 1 ? NETRUN_FACTION_OWNER : id

/datum/netrun_console
	var/personal_faction_id
	var/datum/weakref/personal_faction_principal_ref

/mob
	/// Exact native body link; lookup never scans implants, players or consoles.
	var/datum/weakref/netrun_personal_dive_ref

/mob/proc/netrun_personal_principal()
	if(QDELETED(src))
		return null
	if(!QDELETED(mind))
		return mind
	var/datum/netrun_dive_link/link = netrun_personal_dive_ref?.resolve()
	if(link?.body == src && !link.returning)
		var/datum/principal = link.personal_principal_ref?.resolve()
		if(!QDELETED(principal))
			return principal
	return src

/// A mind/body is authoritative. An unused console is only a bounded fallback
/// for native fixtures or operator-less storage ownership, never a user identity.
/datum/netrun_console/proc/personal_faction_principal()
	var/datum/netrun_console/current = src
	for(var/step in 1 to 8)
		var/mob/camera/netrun_entity/entity = current.combat_self()
		if(istype(entity))
			var/datum/netrun_dive_link/link = entity.dive_link
			var/datum/principal = link?.personal_principal_ref?.resolve()
			if(!QDELETED(principal) && !QDELETED(link.body) && !link.returning)
				return principal
			if(!QDELETED(entity.mind))
				return entity.mind
		if(!isnull(current.operator))
			return current.operator.netrun_personal_principal()
		var/datum/netrun_inventory/source = current.inventory?.borrowed_inventory_ref?.resolve()
		if(!QDELETED(source?.owner) && source.owner != current)
			current = source.owner
			continue
		return istype(entity) ? entity : current
	return src

/datum/netrun_console/proc/get_personal_faction_id()
	if(QDELETED(src))
		return null
	var/mob/camera/netrun_entity/bot/bot = combat_self()
	if(istype(bot))
		// An agent snapshots the issuing player. Reusing its owner's console
		// cannot transfer the agent's allegiance to the next operator.
		return bot.net_faction
	var/datum/principal = personal_faction_principal()
	if(QDELETED(principal))
		return null
	if(personal_faction_principal_ref?.resolve() == principal && personal_faction_id && SSnetrun.get_netrun_faction(personal_faction_id))
		return personal_faction_id
	SSnetrun.get_netrun_faction(null)
	var/key = REF(principal)
	var/datum/netrun_faction/private/personal/faction = SSnetrun.personal_factions_by_principal[key]
	if(QDELETED(faction) || faction.principal_ref?.resolve() != principal)
		if(!QDELETED(faction))
			qdel(faction)
		var/new_id = "owner:[++SSnetrun.personal_faction_serial]"
		faction = new(principal, new_id, get_handle())
		SSnetrun.netrun_factions[new_id] = faction
		SSnetrun.personal_factions_by_principal[key] = faction
	personal_faction_principal_ref = WEAKREF(principal)
	personal_faction_id = faction.id
	return personal_faction_id

/datum/controller/subsystem/netrun/proc/get_netrun_faction(id)
	RETURN_TYPE(/datum/netrun_faction)
	if(!netrun_factions)
		netrun_factions = list()
		for(var/path in subtypesof(/datum/netrun_faction))
			var/datum/netrun_faction/faction = new path
			if(faction.id)
				netrun_factions[faction.id] = faction
			else
				qdel(faction)
	return netrun_factions[id]

/datum/controller/subsystem/netrun/proc/count_network_visitors()
	. = 0
	for(var/mob/camera/netrun_entity/bot/bot as anything in bots)
		if(!QDELETED(bot) && !bot.launched_by_owner && get_netrun_faction(bot.net_faction)?.arrival_weight)
			.++

/// A dense but bounded wave. Count processes once, then update that census on
/// successful spawns; personal factions never enter the visitor selection pool.
/datum/controller/subsystem/netrun/proc/spawn_visitor_wave()
	get_netrun_faction(null)
	var/visitors = 0
	var/list/counts = list()
	for(var/mob/camera/netrun_entity/bot/bot as anything in bots)
		if(QDELETED(bot))
			continue
		counts[bot.net_faction] = (counts[bot.net_faction] || 0) + 1
		if(!bot.launched_by_owner && get_netrun_faction(bot.net_faction)?.arrival_weight)
			visitors++
	var/wave_size = rand(visitor_wave_min, visitor_wave_max)
	for(var/index in 1 to wave_size)
		if(visitors >= visitor_limit || length(bots) >= NETRUN_MAX_BOTS)
			break
		var/list/pool = list()
		for(var/id in netrun_factions)
			var/datum/netrun_faction/faction = netrun_factions[id]
			var/free = visitor_faction_limit - (counts[id] || 0)
			if(faction.arrival_weight && length(faction.visitors) && free > 0)
				pool[id] = faction.arrival_weight * free
		if(!length(pool))
			break
		var/datum/netrun_faction/faction = get_netrun_faction(pickweight(pool))
		var/mob/camera/netrun_entity/bot/visitor = spawn_bot(pick(faction.visitors), bot_entry_node())
		if(!visitor)
			break
		visitors++
		counts[visitor.net_faction] = (counts[visitor.net_faction] || 0) + 1
		if(visitor && faction.hostile_to(NETRUN_FACTION_STATION))
			report_incident("rogue", visitor.host_node, visitor, NETRUN_INCIDENT_MEDIUM, "Вторжение: [faction.name], процесс [visitor.real_name].")

/datum/netrun_bot_program/raider/redshift
	id = "redshift_raider"
	name = "Налётчик Красного смещения"
	faction = "redshift"
	name_prefix = "RIFT"
	accent = "rose"
	programs = list("strike", "blackout", "barrier")
	max_integrity = 100
	lifetime = 6 MINUTES

/datum/netrun_bot_program/hacker/redshift
	id = "redshift_hacker"
	name = "Диверсант Красного смещения"
	faction = "redshift"
	name_prefix = "WRAITH"
	file_size = 0
	lifetime = 5 MINUTES

/datum/netrun_bot_program/raider/collective
	id = "collective_guard"
	name = "Страж Осколочного коллектива"
	faction = "collective"
	name_prefix = "SHARD"
	accent = "violet"
	programs = list("strike", "barrier", "patch")
	lifetime = 7 MINUTES

/// Allied visitors defend against actual enemies rather than repeatedly walking
/// toward friendly ICE that their combat policy will never attack.
/datum/netrun_bot_program/raider/collective/plan(datum/netrun_bot_brain/brain)
	var/datum/component/netrun_node/target = brain.find_nearby_node(TYPE_PROC_REF(/datum/netrun_bot_brain, node_has_enemy))
	if(target)
		brain.push_goal(new /datum/netrun_bot_goal/travel(brain, target))
	else
		brain.push_goal(new /datum/netrun_bot_goal/patrol(brain, patrol_networks(brain)))

/datum/netrun_bot_program/scavenger/archivist
	id = "archive_collector"
	name = "Собиратель Вольного архива"
	faction = "archivists"
	name_prefix = "SCRIBE"
	accent = "amber"
	programs = list("blackout", "patch")
	lifetime = 6 MINUTES
