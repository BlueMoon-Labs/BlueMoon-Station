/// Attack observations belong to the defended node/LAN. They contain no public
/// actor identity; a delivered, authorized countertrace grants a short contact.
/datum/netrun_attack_observation
	var/id
	var/kind
	var/updated_at
	var/datum/weakref/attacker_ref
	var/datum/weakref/source_ref
	var/datum/weakref/breach_ref

/datum/netrun_attack_observation/proc/active()
	var/datum/netrun_console/attacker = attacker_ref?.resolve()
	var/datum/netrun_breach/breach = breach_ref?.resolve()
	return breach && attacker?.intrusion.breach == breach

/datum/netrun_attack_observation/proc/traceable()
	return attacker_ref?.resolve() && (active() || world.time < updated_at + 30 SECONDS)

/datum/netrun_security_audit
	var/list/datum/netrun_attack_observation/observations = list()

/datum/netrun_security_audit/Destroy()
	QDEL_LIST(observations)
	return ..()

/datum/controller/subsystem/netrun
	var/security_observation_serial = 0

/datum/netrun_security_audit/proc/record(datum/netrun_console/attacker, kind)
	if(QDELETED(attacker))
		return null
	var/datum/netrun_attack_observation/observation
	for(var/datum/netrun_attack_observation/previous as anything in observations)
		if(previous.attacker_ref?.resolve() == attacker && previous.kind == kind)
			observation = previous
			break
	if(!observation)
		observation = new
		observation.id = "attack-[++SSnetrun.security_observation_serial]"
		observation.kind = kind
		observation.attacker_ref = WEAKREF(attacker)
		observations += observation
		while(length(observations) > 16)
			var/datum/oldest = observations[1]
			observations.Cut(1, 2)
			qdel(oldest)
	observation.updated_at = world.time
	observations -= observation
	observations += observation
	var/datum/component/netrun_node/source = attacker.physical_route_source()
	observation.source_ref = source ? WEAKREF(source) : null
	observation.breach_ref = attacker.intrusion.breach ? WEAKREF(attacker.intrusion.breach) : null
	return observation

/datum/component/netrun_node
	var/datum/netrun_security_audit/security_audit

/datum/netrun_network
	var/datum/netrun_security_audit/security_audit

/datum/component/netrun_node/proc/observe_attack(datum/netrun_console/attacker, kind)
	var/datum/netrun_breach/breach = attacker?.intrusion.breach
	if(kind == "breach" && breach?.target_kind == "network" && network?.id == breach.target_id)
		if(!network.security_audit)
			network.security_audit = new
		. = network.security_audit.record(attacker, kind)
	else
		if(!security_audit)
			security_audit = new
		. = security_audit.record(attacker, kind)
	queue_presentation(NETRUN_CHANGED_DETAILS)

/// The shared successful-illegal-action hook never changes the action's trace cost.
/datum/netrun_console/proc/report_illegal_activity(datum/component/netrun_node/node, label, required_access = NETRUN_ACCESS_USER)
	if(QDELETED(src) || QDELETED(node))
		return
	var/atom/target = node.parent
	SSnetrun.raise_defenses(src, node)
	target?.netrun_on_illegal(src, node)
	SSnetrun.report_incident("intrusion", node, src, required_access >= NETRUN_ACCESS_ROOT ? NETRUN_INCIDENT_MEDIUM : NETRUN_INCIDENT_LOW, "Действие без авторизации: [label].")

/// One capability contact per actual observation, not a client-supplied mob REF.
/datum/netrun_security_contact
	var/datum/netrun_security_session/session
	var/id
	var/kind
	var/datum/weakref/defended_ref
	var/datum/weakref/attacker_ref
	var/datum/weakref/actor_ref
	var/datum/weakref/breach_ref
	var/datum/weakref/source_ref
	var/name
	var/updated_at
	var/expires_at

/datum/netrun_security_contact/New(datum/netrun_security_session/session, datum/netrun_attack_observation/observation, datum/component/netrun_node/defended)
	src.session = session
	id = observation.id
	kind = observation.kind
	defended_ref = WEAKREF(defended)
	attacker_ref = observation.attacker_ref
	breach_ref = observation.breach_ref
	updated_at = world.time
	expires_at = world.time + 45 SECONDS
	source_ref = observation.source_ref
	var/datum/netrun_console/attacker = attacker_ref?.resolve()
	var/mob/camera/netrun_entity/actor = attacker?.combat_self()
	if(istype(actor))
		actor_ref = WEAKREF(actor)
		name = actor.real_name
		RegisterSignal(actor, COMSIG_NETRUN_ENTITY_NODE_CHANGED, PROC_REF(on_actor_moved))
	else
		name = "Сетевой клиент ([attacker?.origin])"

/datum/netrun_security_contact/Destroy()
	var/mob/camera/netrun_entity/actor = actor_ref?.resolve()
	if(actor)
		UnregisterSignal(actor, COMSIG_NETRUN_ENTITY_NODE_CHANGED)
	var/mob/camera/netrun_entity/pursuer = session?.owner?.combat_self()
	if(istype(pursuer) && pursuer.navigation?.security_contact_id == id)
		pursuer.navigation.cancel()
	session = null
	return ..()

/datum/netrun_security_contact/proc/on_actor_moved(datum/source, datum/component/netrun_node/previous, datum/component/netrun_node/current)
	SIGNAL_HANDLER
	if(!current || world.time >= expires_at)
		return
	source_ref = WEAKREF(current)
	updated_at = world.time
	session?.owner?.invalidate_ui()

/datum/netrun_security_contact/proc/valid(check_authority = TRUE)
	return world.time < expires_at && !QDELETED(session?.owner) && (!check_authority || session.can_defend(defended_ref?.resolve()))

/datum/netrun_security_contact/proc/map_denial(check_authority = TRUE)
	if(!valid(check_authority))
		return "След истёк или право защищать узел утрачено."
	var/datum/component/netrun_node/source = source_ref?.resolve()
	if(!source || !session.owner.node_visible(source))
		return "Источник недоступен по вашим маршрутам и доступам."
	return null

/datum/netrun_security_contact/proc/pursuit_denial(map_reason, map_checked = FALSE)
	var/reason = map_checked ? map_reason : map_denial()
	if(reason)
		return reason
	var/mob/camera/netrun_entity/pursuer = session.owner.combat_self()
	var/mob/camera/netrun_entity/actor = actor_ref?.resolve()
	if(!istype(pursuer) || !pursuer.navigation || !actor || actor == pursuer)
		return "Преследование доступно сущности против живого процесса."
	if(pursuer.is_stunned())
		return "Ваш процесс оглушён."
	if(actor.host_node != source_ref?.resolve())
		return "Положение процесса изменилось; обновите след."
	return null

/datum/netrun_security_session
	var/datum/netrun_console/owner
	var/list/datum/netrun_security_contact/contacts = list()
	var/expiry_timer

/datum/netrun_security_session/New(datum/netrun_console/owner)
	src.owner = owner

/datum/netrun_security_session/Destroy()
	if(expiry_timer)
		deltimer(expiry_timer)
	QDEL_LIST_ASSOC_VAL(contacts)
	owner = null
	return ..()

/datum/netrun_security_session/proc/can_defend(datum/component/netrun_node/node)
	return !QDELETED(node) && !QDELETED(owner) && !owner.is_locked() && owner.can_route(node) && owner.legit_node_level(node) >= NETRUN_ACCESS_USER

/datum/netrun_security_session/proc/defended_node()
	RETURN_TYPE(/datum/component/netrun_node)
	var/datum/component/netrun_node/node = owner.selected_node()
	if(can_defend(node))
		return node
	node = owner.physical_route_source()
	return can_defend(node) ? node : null

/datum/netrun_security_session/proc/observations(datum/component/netrun_node/node)
	var/list/result = list()
	if(node?.security_audit)
		result |= node.security_audit.observations
	if(node?.network?.security_audit)
		result |= node.network.security_audit.observations
	return result

/datum/netrun_security_session/proc/capture(datum/netrun_attack_observation/observation, datum/component/netrun_node/node)
	if(!can_defend(node) || !(observation in observations(node)) || !observation?.traceable() || observation.attacker_ref?.resolve() == owner)
		return FALSE
	var/datum/netrun_security_contact/old = contacts[observation.id]
	if(old)
		old.updated_at = world.time
		old.expires_at = world.time + 45 SECONDS
		old.source_ref = observation.source_ref
		old.breach_ref = observation.breach_ref
		old.defended_ref = WEAKREF(node)
	else
		contacts[observation.id] = new /datum/netrun_security_contact(src, observation, node)
	while(length(contacts) > 16)
		var/key = contacts[1]
		old = contacts[key]
		contacts -= key
		qdel(old)
	arm_expiry()
	owner.invalidate_ui()
	return TRUE

/datum/netrun_security_session/proc/arm_expiry()
	if(expiry_timer)
		deltimer(expiry_timer)
	expiry_timer = null
	var/earliest = INFINITY
	for(var/id in contacts)
		var/datum/netrun_security_contact/contact = contacts[id]
		earliest = min(earliest, contact.expires_at)
	if(earliest != INFINITY)
		expiry_timer = addtimer(CALLBACK(src, PROC_REF(expire)), max(1, earliest - world.time), TIMER_STOPPABLE | TIMER_DELETE_ME)

/datum/netrun_security_session/proc/expire()
	expiry_timer = null
	for(var/id in contacts)
		var/datum/netrun_security_contact/contact = contacts[id]
		if(world.time < contact.expires_at)
			continue
		contacts -= id
		qdel(contact)
	arm_expiry()
	owner?.invalidate_ui()

/datum/netrun_security_session/proc/payload()
	var/datum/component/netrun_node/node = defended_node()
	var/list/entries = list()
	var/list/seen = list()
	// The same protected node commonly owns every contact. Check its authority
	// once in this serialization; action handlers still perform live checks.
	var/list/defense_cache = list()
	for(var/id in contacts)
		var/datum/netrun_security_contact/contact = contacts[id]
		var/datum/component/netrun_node/defended = contact.defended_ref?.resolve()
		if(!defended || !contact.valid(FALSE))
			continue
		if(!(defended.address in defense_cache))
			defense_cache[defended.address] = can_defend(defended)
		if(!defense_cache[defended.address])
			continue
		var/reason = contact.map_denial(FALSE)
		var/pursuit_reason = contact.pursuit_denial(reason, TRUE)
		var/datum/component/netrun_node/source = reason ? null : contact.source_ref?.resolve()
		var/datum/netrun_breach/active_breach = contact.breach_ref?.resolve()
		var/datum/netrun_console/attacker = contact.attacker_ref?.resolve()
		entries += list(list("id" = id, "kind" = contact.kind, "age" = round((world.time - contact.updated_at) / (1 SECONDS)),
			"ttl" = max(0, round((contact.expires_at - world.time) / (1 SECONDS))), "attributed" = TRUE,
			"name" = contact.name, "source_address" = source?.address, "source_name" = source?.get_name(),
			"active" = active_breach && attacker?.intrusion.breach == active_breach, "status" = "Временный контакт контртрассировки.", "map_allowed" = !reason, "map_reason" = reason,
			"pursue_allowed" = !pursuit_reason, "pursue_reason" = pursuit_reason, "trace_allowed" = FALSE, "trace_reason" = "Обновите контртрассировку защищаемого узла."))
		seen[id] = TRUE
	for(var/datum/netrun_attack_observation/observation as anything in observations(node))
		if(length(entries) >= 16)
			break
		if(seen[observation.id] || world.time > observation.updated_at + 2 MINUTES)
			continue
		var/can_trace = observation.traceable() && observation.attacker_ref?.resolve() != owner
		entries += list(list("id" = observation.id, "kind" = observation.kind, "age" = round((world.time - observation.updated_at) / (1 SECONDS)),
			"ttl" = 0, "attributed" = FALSE, "active" = !!observation.active(), "status" = "Источник ещё не установлен.",
			"map_allowed" = FALSE, "map_reason" = "Сначала выполните контртрассировку.", "pursue_allowed" = FALSE,
			"pursue_reason" = "Сначала выполните контртрассировку.", "trace_allowed" = can_trace,
			"trace_reason" = can_trace ? null : "След устарел или принадлежит вашему сеансу."))
	var/list/defended
	if(node)
		var/datum/netrun_command/command = SSnetrun.get_command("countertrace")
		var/list/action = command.ui_entry(node, owner)
		defended = list("address" = node.address, "name" = node.get_name(), "can_countertrace" = action["allowed"] && ("countertrace" in node.all_command_ids()), "reason" = action["unavailable_reason"])
	return list("defended" = defended, "entries" = entries)

/datum/netrun_security_session/proc/act(action, id)
	var/datum/component/netrun_node/node = defended_node()
	if(action == "security_probe")
		return node && owner.run_command(node, "countertrace")
	if(!istext(id))
		return FALSE
	if(action == "security_trace")
		for(var/datum/netrun_attack_observation/observation as anything in observations(node))
			if(observation.id == id && observation.traceable())
				return owner.run_command(node, "countertrace")
		return FALSE
	var/datum/netrun_security_contact/contact = contacts[id]
	if(QDELETED(contact))
		return FALSE
	if(action == "security_map" && !contact.map_denial())
		var/datum/component/netrun_node/source = contact.source_ref.resolve()
		var/turf/position = source.observe_location()
		owner.map_view.waypoint_address = source.address
		owner.map_view.selected_address = source.address
		owner.map_view.selected_network = null
		owner.map_view.select_sector(source.binding_sector, position?.z)
		owner.workspace_view = "map"
		return TRUE
	if(action == "security_pursue" && !contact.pursuit_denial())
		var/mob/camera/netrun_entity/entity = owner.combat_self()
		return entity.navigation.pursue(contact.actor_ref.resolve(), id)
	return FALSE
