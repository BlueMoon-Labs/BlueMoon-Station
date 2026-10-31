/**
 * Журнал инцидентов сети: общий источник работы для сетевой полиции.
 *
 * Инцидент — ограниченная запись о подозрительной активности: взлом, нелегальная
 * команда, полная трассировка, сработавшая сигнализация крепости, вредоносный бот.
 * Подозреваемый хранится слабой ссылкой; запись не удерживает консоль или процесс.
 * Повторный отчёт о той же активности в том же узле усиливает открытый инцидент.
 */
/datum/netrun_incident
	var/id
	/// "breach", "intrusion", "trace", "combat", "fortress", "rogue"
	var/kind
	var/address
	var/network_id
	var/severity = NETRUN_INCIDENT_LOW
	var/text
	var/created_at
	var/updated_at
	var/reports = 1
	var/datum/weakref/suspect_ref
	var/suspect_name
	/// The police process currently handling this record.
	var/datum/weakref/claim_ref
	var/closed = FALSE
	var/resolution

/datum/netrun_incident/New(kind, datum/component/netrun_node/node, datum/suspect, severity, text)
	id = "INC-[++SSnetrun.incident_serial]"
	src.kind = kind
	address = node?.address
	network_id = node?.network?.id
	src.severity = clamp(severity || NETRUN_INCIDENT_LOW, NETRUN_INCIDENT_LOW, NETRUN_INCIDENT_HIGH)
	src.text = text
	created_at = world.time
	updated_at = world.time
	set_suspect(suspect)

/datum/netrun_incident/Destroy()
	suspect_ref = null
	claim_ref = null
	return ..()

/datum/netrun_incident/proc/set_suspect(datum/suspect)
	if(QDELETED(suspect))
		return
	suspect_ref = WEAKREF(suspect)
	suspect_name = netrun_incident_suspect_name(suspect)

/// Console, process or other datum that caused the incident, if it still exists.
/datum/netrun_incident/proc/suspect()
	return suspect_ref?.resolve()

/datum/netrun_incident/proc/node()
	RETURN_TYPE(/datum/component/netrun_node)
	return SSnetrun.find_node(address)

/datum/netrun_incident/proc/claimed_by()
	return claim_ref?.resolve()

/datum/netrun_incident/proc/claim(datum/handler)
	claim_ref = handler ? WEAKREF(handler) : null

/datum/netrun_incident/proc/is_open()
	return !closed && world.time - updated_at < NETRUN_INCIDENT_STALE_AFTER

/datum/netrun_incident/proc/close(new_resolution)
	if(closed)
		return FALSE
	closed = TRUE
	resolution = new_resolution
	claim_ref = null
	updated_at = world.time
	return TRUE

/datum/netrun_incident/proc/ui_entry()
	return list("id" = id, "kind" = kind, "address" = address, "network" = network_id,
		"severity" = severity, "text" = text, "suspect" = suspect_name, "reports" = reports,
		"age" = round((world.time - created_at) / (1 SECONDS)), "open" = is_open(), "resolution" = resolution)

/// Human-readable identity without exposing a real name the network cannot know.
/proc/netrun_incident_suspect_name(datum/suspect)
	if(istype(suspect, /mob/camera/netrun_entity))
		var/mob/camera/netrun_entity/entity = suspect
		return entity.real_name
	if(istype(suspect, /datum/netrun_console))
		var/datum/netrun_console/console = suspect
		var/datum/component/netrun_node/source = console.route_source()
		return "клиент [console.origin][source ? " @ [source.address]" : ""]"
	if(istype(suspect, /datum/netrun_ice))
		var/datum/netrun_ice/ice = suspect
		return ice.name
	return null

/datum/controller/subsystem/netrun
	/// Bounded incident registry shared by police processes.
	var/list/datum/netrun_incident/incidents = list()
	var/incident_serial = 0

/// Register suspicious activity. Callers pass the acting console or process when known.
/// Never builds routes; listeners only queue work.
/datum/controller/subsystem/netrun/proc/report_incident(kind, datum/component/netrun_node/node, datum/suspect, severity = NETRUN_INCIDENT_LOW, text)
	if(!kind)
		return null
	var/address = node?.address
	var/atom/security_host = node?.parent
	if(node && (kind in list("breach", "intrusion", "trace")))
		var/datum/netrun_console/attacker
		if(istype(suspect, /datum/netrun_console))
			attacker = suspect
		else if(istype(suspect, /mob/camera/netrun_entity))
			var/mob/camera/netrun_entity/entity = suspect
			attacker = entity.console
		node.record_interference(attacker, text || kind)
	if(node && (kind in list("breach", "intrusion")))
		var/datum/netrun_console/attacker = suspect
		if(istype(attacker))
			node.observe_attack(attacker, kind)
	for(var/datum/netrun_incident/incident as anything in incidents)
		if(!incident.is_open() || incident.kind != kind || incident.address != address)
			continue
		// The same suspect repeating itself escalates one record instead of flooding the log.
		var/datum/known = incident.suspect()
		if(known && suspect && known != suspect)
			continue
		incident.reports++
		incident.updated_at = world.time
		incident.severity = clamp(max(incident.severity, severity) + (incident.reports % 4 == 0 ? 1 : 0), NETRUN_INCIDENT_LOW, NETRUN_INCIDENT_HIGH)
		if(text)
			incident.text = text
		if(!known && suspect)
			incident.set_suspect(suspect)
		SEND_SIGNAL(src, COMSIG_NETRUN_INCIDENT_REPORTED, incident)
		security_host?.publish_netrun_security_event(incident)
		return incident
	var/datum/netrun_incident/incident = new(kind, node, suspect, severity, text)
	incidents += incident
	prune_incidents()
	SEND_SIGNAL(src, COMSIG_NETRUN_INCIDENT_REPORTED, incident)
	security_host?.publish_netrun_security_event(incident)
	return incident

/// Closed and stale records go first; open records are evicted only past twice the bound.
/datum/controller/subsystem/netrun/proc/prune_incidents()
	if(length(incidents) <= NETRUN_MAX_INCIDENTS)
		return
	for(var/datum/netrun_incident/incident as anything in incidents.Copy())
		if(length(incidents) <= NETRUN_MAX_INCIDENTS)
			return
		if(!incident.is_open())
			incidents -= incident
			qdel(incident)
	while(length(incidents) > NETRUN_MAX_INCIDENTS * 2)
		var/datum/netrun_incident/oldest = incidents[1]
		incidents.Cut(1, 2)
		qdel(oldest)

/// Open incidents, most severe and most recent first.
/datum/controller/subsystem/netrun/proc/open_incidents()
	. = list()
	for(var/datum/netrun_incident/incident as anything in incidents)
		if(incident.is_open())
			. += incident
	sortTim(., GLOBAL_PROC_REF(cmp_netrun_incidents))

/proc/cmp_netrun_incidents(datum/netrun_incident/a, datum/netrun_incident/b)
	if(a.severity != b.severity)
		return b.severity - a.severity
	return b.updated_at - a.updated_at
