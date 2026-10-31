/// A dive owns the body link and its subscriptions, independently of resident movement and vision.
/datum/netrun_dive_link
	parent_type = /datum/netrun_delivery
	delivery_kind = "dive_link"
	var/mob/camera/netrun_entity/owner
	var/mob/living/carbon/body
	var/entry_address
	var/list/route_chain = list()
	var/datum/weakref/entry_client_ref
	var/datum/weakref/entry_jack_ref
	/// Returning is terminal: concurrent damage, deletion and cable signals share one exit.
	var/returning = FALSE
	var/checking = FALSE
	var/list/datum/component/netrun_node/watched_nodes = list()
	/// The resident gets USER at its initial host for residency, not as a transferable hack.
	var/initial_residency_only = FALSE
	var/datum/netrun_file/access/session_snapshot/identity_snapshot
	var/datum/weakref/personal_principal_ref
	var/next_body_notice = 0
	var/body_tox_baseline = 0
	var/body_oxy_baseline = 0

/datum/netrun_dive_link/New(mob/camera/netrun_entity/owner)
	src.owner = owner
	RegisterSignal(owner, COMSIG_NETRUN_ENTITY_NODE_CHANGED, PROC_REF(on_node_changed))

/datum/netrun_dive_link/Destroy()
	release_body()
	UnregisterSignal(owner, COMSIG_NETRUN_ENTITY_NODE_CHANGED)
	owner = null
	return ..()

/datum/netrun_dive_link/proc/attach(mob/living/carbon/new_body, datum/component/netrun_node/entry)
	if(QDELETED(new_body) || QDELETED(entry))
		return FALSE
	release_body()
	body = new_body
	returning = FALSE
	identity_snapshot = new("dive-id.access", body.netrun_credential_access(), src)
	if(!owner.console.inventory.mount_session_file(identity_snapshot))
		QDEL_NULL(identity_snapshot)
		body = null
		return FALSE
	personal_principal_ref = WEAKREF(body.netrun_personal_principal())
	body.netrun_personal_dive_ref = WEAKREF(src)
	entry_address = entry.address
	route_chain = list(entry.address)
	RegisterSignal(body, COMSIG_MOB_APPLY_DAMAGE, PROC_REF(on_body_damage))
	RegisterSignal(body, COMSIG_LIVING_DEATH, PROC_REF(on_body_death))
	RegisterSignal(body, COMSIG_PARENT_QDELETING, PROC_REF(on_body_deleted))
	RegisterSignal(body, COMSIG_MOVABLE_MOVED, PROC_REF(on_body_moved))
	RegisterSignal(body, COMSIG_PARENT_EXAMINE, PROC_REF(on_body_examine))
	RegisterSignal(body, COMSIG_CARBON_PRE_MISC_HELP, PROC_REF(on_body_help))
	body_tox_baseline = body.getToxLoss()
	body_oxy_baseline = body.getOxyLoss()
	next_body_notice = world.time + 15 SECONDS
	body.visible_message(span_notice("У [body] подёргиваются пальцы: нейролинк начинает погружение в сеть."))
	watch_nodes(list(entry))
	return TRUE

/datum/netrun_dive_link/proc/bind_client(datum/netrun_console/implant/client, datum/component/netrun_node/jack)
	entry_client_ref = WEAKREF(client)
	entry_jack_ref = jack ? WEAKREF(jack) : null
	RegisterSignal(client, COMSIG_PARENT_QDELETING, PROC_REF(on_client_deleted))
	client.access_session.process_events()
	var/datum/netrun_access_session/resident = owner.console.access_session
	initial_residency_only = !client.access_session.direct_node_level(SSnetrun.find_node(entry_address))
	for(var/address in client.access_session.node_access)
		var/datum/component/netrun_node/node = SSnetrun.find_node(address)
		resident.grant_node(node, client.access_session.direct_node_level(node), client.access_session.exportable_node_level(node))
	for(var/id in client.access_session.network_access)
		var/datum/netrun_network/network = SSnetrun.networks[id]
		resident.grant_network(network, client.access_session.direct_network_level(network), client.access_session.exportable_network_level(network))
	resident.server_passwords = client.access_session.server_passwords.Copy()
	owner.console.inventory.borrow_from(client.inventory)
	// Establish the physical return path once; later ticks borrow its retained route table.
	check_link(0)

/// Merge only grants that survived all queued firewall resets in both sessions.
/datum/netrun_dive_link/proc/return_access(datum/netrun_console/implant/client)
	if(QDELETED(client) || QDELETED(owner.console))
		return
	var/datum/netrun_access_session/target = client.access_session
	var/datum/netrun_access_session/resident = owner.console.access_session
	target.process_events()
	resident.process_events()
	for(var/address in resident.node_access)
		var/datum/component/netrun_node/node = SSnetrun.find_node(address)
		var/level = resident.direct_node_level(node)
		if(initial_residency_only && address == entry_address && level <= NETRUN_ACCESS_USER)
			continue
		target.grant_node(node, level, resident.exportable_node_level(node))
	for(var/network_id in resident.network_access)
		var/datum/netrun_network/network = SSnetrun.networks[network_id]
		target.grant_network(network, resident.direct_network_level(network), resident.exportable_network_level(network))
	for(var/address in resident.server_passwords)
		target.server_passwords[address] = resident.server_passwords[address]
	client.invalidate_projection_caches()
	client.map_view.invalidate(TRUE)

/datum/netrun_dive_link/proc/release_body()
	cancel_delivery()
	// Expire before transferring control or releasing the body. Copies and moves
	// were never allowed, so no other disk can retain this session's authority.
	expire_identity_snapshot()
	if(body)
		if(body.netrun_personal_dive_ref?.resolve() == src)
			body.netrun_personal_dive_ref = null
		UnregisterSignal(body, list(COMSIG_MOB_APPLY_DAMAGE, COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING, COMSIG_MOVABLE_MOVED, COMSIG_PARENT_EXAMINE, COMSIG_CARBON_PRE_MISC_HELP))
	var/datum/netrun_console/implant/client = entry_client_ref?.resolve()
	if(client)
		UnregisterSignal(client, COMSIG_PARENT_QDELETING)
		if(client.dive_ref?.resolve() == owner)
			client.dive_ref = null
	watch_nodes(list())
	body = null
	entry_address = null
	route_chain.Cut()
	entry_client_ref = null
	entry_jack_ref = null
	initial_residency_only = FALSE
	personal_principal_ref = null

/datum/netrun_dive_link/proc/expire_identity_snapshot()
	owner?.console?.inventory.clear_session_store()
	QDEL_NULL(identity_snapshot)

/datum/netrun_dive_link/proc/on_node_changed(datum/source, datum/component/netrun_node/old_node, datum/component/netrun_node/new_node)
	SIGNAL_HANDLER
	track_route(new_node)
	if(body && new_node)
		// Subscribe to the new host immediately; the worker replaces this superset
		// with the precise physical return path after the residency change settles.
		watch_nodes(watched_nodes | list(new_node))
		queue_link_check()

/datum/netrun_dive_link/proc/track_route(datum/component/netrun_node/node)
	if(!body || !node?.address)
		return
	var/existing = route_chain.Find(node.address)
	if(existing)
		route_chain.Cut(existing + 1)
	else
		route_chain += node.address

/datum/netrun_dive_link/proc/on_body_damage(datum/source, damage, damagetype)
	SIGNAL_HANDLER
	if(damage < 5 || !(damagetype in list(BRUTE, BURN, TOX, OXY)))
		return
	INVOKE_ASYNC(src, PROC_REF(emergency_return), "Ваше тело ранено! Аварийный выход из сети!")

/// A bystander can recognize a dive and use the ordinary help interaction to end it safely.
/datum/netrun_dive_link/proc/on_body_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	if(!body || returning)
		return
	examine_list += span_notice("Нейролинк активен: сознание находится в сети. Потрясите тело с намерением «Помощь», чтобы безопасно прервать погружение.")
	var/datum/netrun_combat_encounter/encounter = owner?.console?.get_combat_encounter()
	if(encounter?.active)
		examine_list += span_warning("Тело напряжено и подёргивается: в сети идёт бой.")

/datum/netrun_dive_link/proc/on_body_help(datum/source, mob/living/carbon/helper)
	SIGNAL_HANDLER
	if(!body || returning || body.stat == DEAD || !istype(helper) || helper == body || helper.incapacitated() || !helper.Adjacent(body))
		return
	helper.visible_message(span_notice("[helper] осторожно трясёт [body], прерывая погружение в сеть."), span_notice("Вы осторожно выводите [body] из сетевого погружения."))
	INVOKE_ASYNC(src, PROC_REF(return_to_body))
	return COMPONENT_BLOCK_MISC_HELP

/datum/netrun_dive_link/proc/on_body_death(datum/source)
	SIGNAL_HANDLER
	expire_identity_snapshot()
	// The native death signal precedes set_stat(DEAD); return after it finishes,
	// so the dying body is not briefly treated as an awakened living operator.
	addtimer(CALLBACK(src, PROC_REF(emergency_return), "Ваше тело погибло! Аварийный разрыв нейролинка!"), 0)

/datum/netrun_dive_link/proc/on_body_deleted(datum/source)
	SIGNAL_HANDLER
	// A deleted body cannot receive a mind. Preserve its player as an observer,
	// never leave a formerly neural process occupying the network indefinitely.
	if(returning)
		return
	returning = TRUE
	release_body()
	owner.ghostize(FALSE)
	qdel(owner)

/datum/netrun_dive_link/proc/on_body_moved(datum/source)
	SIGNAL_HANDLER
	var/datum/netrun_console/implant/client = entry_client_ref?.resolve()
	if(entry_jack_ref && (!client || !client.jack_valid()))
		emergency_return("Сервисный кабель нейролинка оборван!")

/datum/netrun_dive_link/proc/on_client_deleted(datum/source)
	SIGNAL_HANDLER
	emergency_return("Нейролинк отключён!")

/// Only the actual return path is subscribed, rather than every endpoint on the station.
/datum/netrun_dive_link/proc/watch_nodes(list/nodes)
	for(var/datum/component/netrun_node/node as anything in watched_nodes.Copy())
		if(node in nodes)
			continue
		UnregisterSignal(node, list(COMSIG_PARENT_QDELETING, COMSIG_NETRUN_NODE_CHANGED))
		watched_nodes -= node
	for(var/datum/component/netrun_node/node as anything in nodes)
		if(QDELETED(node) || (node in watched_nodes))
			continue
		watched_nodes += node
		RegisterSignal(node, COMSIG_PARENT_QDELETING, PROC_REF(on_link_node_deleted))
		RegisterSignal(node, COMSIG_NETRUN_NODE_CHANGED, PROC_REF(on_link_node_changed))

/datum/netrun_dive_link/proc/on_link_node_changed(datum/source, datum/component/netrun_node/changed_node, flags)
	SIGNAL_HANDLER
	var/datum/component/netrun_node/node = source
	if((flags & (NETRUN_CHANGED_BINDING | NETRUN_CHANGED_REMOVED)) || !node.is_online())
		queue_link_check()

/datum/netrun_dive_link/proc/on_link_node_deleted(datum/source)
	SIGNAL_HANDLER
	var/datum/component/netrun_node/node = source
	if(node.address == entry_address)
		emergency_return("Точка входа в сеть уничтожена!")
	else
		// The queued check runs after graph removal. An intact alternative path
		// may still carry the link; no full resident/UI population cycle is needed.
		queue_link_check()

/datum/netrun_dive_link/proc/queue_link_check()
	return queue_delivery()

/datum/netrun_dive_link/can_queue_delivery()
	return body && !returning && !checking

/datum/netrun_dive_link/delivery_priority()
	return NETRUN_TASK_CRITICAL

/datum/netrun_dive_link/delivery_interactive()
	return TRUE

/datum/netrun_dive_link/deliver()
	cancel_delivery()
	check_link(0)
	return TRUE

/datum/netrun_task/dive_link
	parent_type = /datum/netrun_task/delivery
	kind = "dive_link"

/datum/netrun_dive_link/proc/process_tick(delta)
	if(!body || returning)
		return
	// Gradual suffocation and poisoning usually bypass apply_damage(). Count actual
	// deterioration since attachment (or a healthier reading), not existing injuries.
	body_tox_baseline = min(body_tox_baseline, body.getToxLoss())
	body_oxy_baseline = min(body_oxy_baseline, body.getOxyLoss())
	if(body.getToxLoss() >= body_tox_baseline + 5 || body.getOxyLoss() >= body_oxy_baseline + 5 || body.IsStun() || body.IsParalyzed())
		emergency_return("Тело в опасности! Аварийный выход из сети!")
		return
	body.SetUnconscious(5 SECONDS)
	if(world.time >= next_body_notice)
		next_body_notice = world.time + 15 SECONDS
		var/datum/netrun_combat_encounter/encounter = owner.console?.get_combat_encounter()
		if(encounter?.active)
			body.visible_message(span_warning("[body] судорожно подёргивается: нейролинк выдаёт признаки сетевого боя."))
		else
			body.visible_message(span_notice("У [body] подёргиваются пальцы и веки: нейролинк продолжает сетевое погружение."))
	check_link(delta)

/// Borrow one cached physical tree instead of walking the entire station for each diver.
/datum/netrun_dive_link/proc/link_intact()
	var/datum/component/netrun_node/client_node
	if(entry_client_ref)
		var/datum/netrun_console/implant/client = entry_client_ref.resolve()
		var/obj/item/organ/cyberimp/brain/netlink/implant = client?.host
		if(!client || !istype(implant) || implant.owner != body || !implant.netrun_online() || client.is_locked())
			return FALSE
		if(entry_jack_ref && (!entry_jack_ref.resolve() || client.connection.jack != entry_jack_ref.resolve() || !client.jack_valid()))
			return FALSE
		if(!entry_jack_ref)
			if(!client.connection.wireless)
				return FALSE
			client_node = implant.GetComponent(/datum/component/netrun_node)
			if(QDELETED(client_node))
				return FALSE
			// A sleeping body's implant remains a physical endpoint; console admission
			// correctly rejects unconscious operators and cannot be used for this check.
			client_node.join_network()
	if(!entry_address)
		return TRUE
	var/datum/component/netrun_node/entry = SSnetrun.find_node(entry_address)
	if(QDELETED(entry) || QDELETED(entry.parent) || !entry.is_online())
		return FALSE
	if(QDELETED(owner.host_node) || !owner.host_node.is_online())
		return FALSE
	// Movement signals enqueue topology work; this route consumer reconciles its
	// two actual endpoints before trusting a retained physical path.
	entry.join_network()
	if(owner.host_node != entry)
		owner.host_node.join_network()
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	var/datum/netrun_path_tree/tree = graph.route_snapshot(entry, TRUE)
	if(!tree || !tree.path_available(graph, owner.host_node.address) || (client_node && !tree.path_available(graph, client_node.address)))
		return FALSE
	var/list/path_nodes = list(entry)
	for(var/address in tree.addresses_to(owner.host_node.address))
		path_nodes |= graph.nodes[address]
	if(client_node)
		for(var/address in tree.addresses_to(client_node.address))
			path_nodes |= graph.nodes[address]
	watch_nodes(path_nodes)
	return TRUE

/datum/netrun_dive_link/proc/check_link(delta)
	if(!body || returning || checking)
		return
	checking = TRUE
	var/intact = link_intact()
	checking = FALSE
	if(intact)
		return
	emergency_return("Связь с телом потеряна! Аварийный выход из сети!")

/// Compatibility callers must use the same cleanup policy instead of creating a ghost process.
/datum/netrun_dive_link/proc/strand_in_network()
	return emergency_return("Связь с телом разорвана!")

/datum/netrun_dive_link/proc/emergency_return(reason)
	return return_to_body(TRUE, reason)

/datum/netrun_dive_link/proc/return_to_body(emergency = FALSE, reason)
	if(!body || returning)
		return
	returning = TRUE
	var/mob/living/carbon/linked_body = body
	var/datum/netrun_console/implant/client = entry_client_ref?.resolve()
	return_access(client)
	release_body()
	if(emergency)
		to_chat(owner, span_userdanger(reason || "Аварийный разрыв соединения!"))
		linked_body.visible_message(span_warning("[linked_body] резко вздрагивает: нейролинк аварийно разрывает погружение в сеть!"))
		// Native organ damage is capped below lethal brain failure, including repeated dives.
		linked_body.adjustOrganLoss(ORGAN_SLOT_BRAIN, 20, 150)
	if(owner.mind)
		owner.mind.transfer_to(linked_body)
	else if(owner.key)
		linked_body.key = owner.key
	linked_body.SetUnconscious(0)
	if(linked_body.stat != DEAD)
		if(!emergency)
			linked_body.visible_message(span_notice("[linked_body] открывает глаза, возвращаясь из сетевого погружения."))
		to_chat(linked_body, span_notice("Вы выныриваете из сети. Голова гудит."))
	qdel(owner)
	return TRUE
