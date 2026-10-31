/// An entity owns one navigation operation. Replacing/cancelling it releases its timer;
/// generation checks also reject a callback already dispatched for an older operation.
/datum/netrun_entity_navigation
	var/mob/camera/netrun_entity/owner
	var/list/queue = list()
	var/destination
	var/expected_source
	var/timer
	var/generation = 0
	/// A combat lock observes one live process; it never retains that process.
	var/datum/weakref/pursuit_target_ref
	var/pursuit_name
	var/pursuit_node
	var/pursuit_status
	var/security_contact_id

/datum/netrun_entity_navigation/New(mob/camera/netrun_entity/entity)
	owner = entity

/datum/netrun_entity_navigation/Destroy()
	cancel()
	owner = null
	return ..()

/datum/netrun_entity_navigation/proc/is_active()
	return !!length(queue)

/datum/netrun_entity_navigation/proc/cancel(clear_pursuit = TRUE)
	generation++
	if(timer)
		deltimer(timer)
		timer = null
	queue.Cut()
	destination = null
	expected_source = null
	if(clear_pursuit)
		security_contact_id = null
		var/mob/camera/netrun_entity/target = pursuit_target_ref?.resolve()
		if(target)
			UnregisterSignal(target, list(COMSIG_NETRUN_ENTITY_NODE_CHANGED, COMSIG_PARENT_QDELETING))
		pursuit_target_ref = null
		pursuit_name = null
		pursuit_node = null
		pursuit_status = null
	owner?.console?.invalidate_ui()

/// A lock can only be acquired from an actual combat contact, never an arbitrary REF.
/datum/netrun_entity_navigation/proc/pursue(mob/camera/netrun_entity/target, evidence_id)
	if(QDELETED(owner) || !istype(target) || QDELETED(target) || target == owner || owner.is_stunned())
		return FALSE
	var/reason = owner.console.combat_context.target_denial(target)
	if(evidence_id)
		var/datum/netrun_security_contact/contact = owner.console.security_session.contacts[evidence_id]
		if(QDELETED(contact) || contact.actor_ref?.resolve() != target || contact.pursuit_denial())
			return FALSE
		reason = null
	if(reason)
		owner.console.log_line("Захват цели невозможен: [reason]", "bad")
		return FALSE
	cancel()
	security_contact_id = evidence_id
	pursuit_target_ref = WEAKREF(target)
	pursuit_name = target.real_name
	pursuit_node = target.host_node.address
	RegisterSignal(target, COMSIG_NETRUN_ENTITY_NODE_CHANGED, PROC_REF(on_pursuit_moved))
	RegisterSignal(target, COMSIG_PARENT_QDELETING, PROC_REF(on_pursuit_deleted))
	if(refresh_pursuit())
		schedule_step()
	if(!pursuit_target_ref)
		return FALSE
	owner.console.log_line("Цель зафиксирована: [pursuit_name]. Переходы выполняются по разрешённому маршруту, боевые программы запускайте вручную.")
	return TRUE

/datum/netrun_entity_navigation/proc/on_pursuit_moved(datum/source)
	SIGNAL_HANDLER
	// Leaving and entering are two signals in one hop. One owned callback sees
	// the settled destination and coalesces further movement during our cooldown.
	if(!timer && pursuit_target_ref)
		schedule_step()

/datum/netrun_entity_navigation/proc/on_pursuit_deleted(datum/source)
	SIGNAL_HANDLER
	UnregisterSignal(source, list(COMSIG_NETRUN_ENTITY_NODE_CHANGED, COMSIG_PARENT_QDELETING))
	cancel()
	owner?.console?.log_line("Преследование завершено: цель удалена.", "average")

/// Replan only after a target changes nodes or a route stops being usable.
/datum/netrun_entity_navigation/proc/refresh_pursuit()
	if(security_contact_id)
		var/datum/netrun_security_contact/contact = owner?.console?.security_session.contacts[security_contact_id]
		if(QDELETED(contact) || !contact.valid())
			cancel()
			return FALSE
	var/mob/camera/netrun_entity/target = pursuit_target_ref?.resolve()
	var/datum/component/netrun_node/node = target?.host_node
	if(QDELETED(target) || QDELETED(node) || QDELETED(owner) || !owner.host_node || owner.console.is_locked())
		cancel()
		owner?.console?.log_line("Преследование остановлено: цель или подключение недоступны.", "average")
		return FALSE
	if(node == owner.host_node)
		cancel(FALSE)
		pursuit_node = node.address
		pursuit_status = "Цель в вашем узле: можно атаковать."
		return FALSE
	var/datum/component/netrun_node/next = length(queue) ? SSnetrun.find_node(queue[1]) : null
	if(destination != node.address || !is_active() || !owner.can_enter(next))
		var/list/path = path_to(node)
		if(!length(path))
			cancel()
			owner.console.log_line("Преследование остановлено: нет разрешённого пути к цели.", "average")
			return FALSE
		cancel(FALSE)
		queue = path
		destination = node.address
		expected_source = owner.host_node.address
	pursuit_node = node.address
	pursuit_status = "Преследование по узлам."
	return TRUE

/datum/netrun_entity_navigation/proc/pursuit_payload()
	var/mob/camera/netrun_entity/target = pursuit_target_ref?.resolve()
	if(!target)
		return null
	return list("target_ref" = REF(target), "name" = pursuit_name, "node" = pursuit_node,
		"following" = is_active(), "status" = pursuit_status)

/// Search the entire reachable graph once. This synchronous search borrows one
/// fresh authority tree without copying the station or imposing a 200-node cap.
/datum/netrun_entity_navigation/proc/path_to(datum/component/netrun_node/target)
	if(QDELETED(target) || QDELETED(owner) || !owner.host_node || owner.console.is_locked())
		return list()
	var/datum/netrun_path_tree/tree = owner.console.connection.read_path_tree(TRUE)
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	var/start = owner.host_node.address
	var/list/visited = list()
	visited[start] = TRUE
	var/list/previous = list()
	var/list/frontier = list(start)
	var/list/result = list()
	for(var/i = 1, i <= length(frontier), i++)
		var/address = frontier[i]
		if(address == target.address)
			while(address && address != start)
				result.Insert(1, address)
				address = previous[address]
			break
		var/datum/component/netrun_node/current = graph.nodes[address]
		for(var/neighbor in graph.neighbors(address))
			if(visited[neighbor])
				continue
			var/datum/component/netrun_node/node = graph.nodes[neighbor]
			if(QDELETED(node) || !netrun_link_available(current, node))
				continue
			var/allowed = owner.console.can_traverse_node(node, tree)
			if(QDELETED(tree))
				// Live authority may replace a retained tree after an unsigned outage.
				// Retry this candidate once with its replacement, never a stale borrow.
				tree = owner.console.connection.read_path_tree(TRUE)
				allowed = owner.console.can_traverse_node(node, tree)
			if(!allowed || QDELETED(tree))
				continue
			visited[neighbor] = TRUE
			previous[neighbor] = address
			frontier += neighbor
	owner.console.release_path_tree(tree)
	return result

/// Selected-node admission is cheap: no BFS and no path promise on a UI pass.
/// A permitted distant destination may still have a closed intermediate node;
/// start() resolves the complete live route only when the user actually clicks.
/datum/netrun_entity_navigation/proc/movement_payload(datum/component/netrun_node/node, datum/netrun_path_tree/tree)
	if(QDELETED(owner) || QDELETED(owner.console))
		return list("action" = "travel", "allowed" = FALSE, "reason" = "Процесс или его сеанс недоступен.")
	var/owns_tree = !tree
	if(owns_tree)
		tree = owner.console.connection.read_path_tree(TRUE)
	var/reason = movement_denial(node, tree)
	var/action = !reason && world.time >= owner.next_hop && owner.can_enter(node, tree) ? "hop" : "travel"
	if(owns_tree)
		owner.console.release_path_tree(tree)
	return list("action" = action, "allowed" = !reason, "reason" = reason)

/datum/netrun_entity_navigation/proc/movement_denial(datum/component/netrun_node/node, datum/netrun_path_tree/tree)
	if(QDELETED(owner.host_node))
		return "Нет текущего узла для перехода."
	if(QDELETED(node) || QDELETED(node.parent))
		return "Узел назначения больше не существует."
	if(node == owner.host_node)
		return "Вы уже находитесь в этом узле."
	if(owner.console.is_locked())
		return "Точка подключения заблокирована трассировкой."
	if(owner.is_stunned())
		return "Процесс оглушён."
	var/datum/netrun_combat_encounter/encounter = owner.console.get_combat_encounter()
	if(encounter?.active && (encounter.is_waiting(owner.console) || encounter.remaining_ap(owner.console) < 1))
		return "Для выхода из боя нужен ваш ход и одно очко действий."
	if(!node.is_online())
		return "Узел назначения отключён."
	if(!owner.console.can_route(node, tree))
		return "До узла назначения нет действующего сетевого маршрута."
	if(!owner.console.can_traverse_node(node, tree))
		if(node.fortress?.gate_blocks(owner.console))
			return "Врата крепости требуют доступа ПОЛЬЗОВАТЕЛЯ к узлу; вход или ключ ЛВС не подходят."
		return "Нужен доступ ПОЛЬЗОВАТЕЛЯ к узлу, добытый вход ЛВС или её ключ."
	return null

/// Native dispatch repeats admission with fresh physical routes and access.
/// A neighbour is one normal hop; every other move uses the existing autopilot.
/datum/netrun_entity_navigation/proc/move_to(datum/component/netrun_node/node)
	if(QDELETED(owner) || QDELETED(owner.console))
		return FALSE
	var/datum/netrun_path_tree/tree = owner.console.connection.read_path_tree(TRUE)
	var/list/admission = movement_payload(node, tree)
	owner.console.release_path_tree(tree)
	if(!admission["allowed"])
		owner.console.log_line("Переход невозможен: [admission["reason"]]", "bad")
		return FALSE
	if(admission["action"] == "hop")
		if(owner.hop(node))
			return TRUE
		owner.console.log_line(owner.hop_denial(node), "bad")
		return FALSE
	if(start(node))
		return TRUE
	owner.console.log_line("Автопроход невозможен: промежуточные узлы отключены, закрыты вратами или требуют отдельного доступа.", "bad")
	return FALSE

/datum/netrun_entity_navigation/proc/start(datum/component/netrun_node/target)
	if(QDELETED(owner) || target == owner.host_node || owner.is_stunned())
		return FALSE
	var/list/path = path_to(target)
	if(!length(path))
		return FALSE
	cancel()
	queue = path
	destination = target.address
	expected_source = owner.host_node.address
	advance_route(generation)
	return TRUE

/datum/netrun_entity_navigation/proc/schedule_step()
	if(timer)
		deltimer(timer)
	timer = addtimer(CALLBACK(src, PROC_REF(advance_route), generation), max(1, owner.next_hop - world.time), TIMER_STOPPABLE)

/// Keys permit travel, but do not make an unauthorized process safe from ICE.
/// Check each live step so a newly arrived patrol cannot be crossed on a stale route.
/datum/netrun_entity_navigation/proc/threat_at(datum/component/netrun_node/next)
	if(QDELETED(next) || !next.is_online() || !length(next.netrun_ice))
		return null
	var/datum/netrun_path_tree/tree = owner.console.connection.read_path_tree(TRUE)
	for(var/datum/netrun_ice/ice as anything in next.netrun_ice)
		if(QDELETED(ice))
			continue
		var/hostile = ice.is_intruder(owner, next, tree) && owner.can_enter(next, tree)
		if(QDELETED(tree))
			tree = owner.console.connection.read_path_tree(TRUE)
			hostile = ice.is_intruder(owner, next, tree) && owner.can_enter(next, tree)
		if(hostile && !QDELETED(tree))
			. = ice
			break
	owner.console.release_path_tree(tree)

/datum/netrun_entity_navigation/proc/advance_route(expected_generation)
	if(expected_generation != generation || QDELETED(owner) || (!is_active() && !pursuit_target_ref))
		return
	timer = null
	if(pursuit_target_ref)
		if(!refresh_pursuit())
			return
		expected_generation = generation
	if(owner.host_node?.address != expected_source)
		cancel()
		return
	// Issuing/replacing a route during a hop cooldown should wait, not lose the route.
	if(world.time < owner.next_hop)
		schedule_step()
		return
	var/datum/component/netrun_node/next = SSnetrun.find_node(queue[1])
	var/datum/netrun_ice/threat = threat_at(next)
	if(threat)
		var/message = "Автопроход остановлен перед [next.get_name()] ([next.address]): [threat.name] враждебен вашему процессу. Изучите узел; для боя войдите вручную."
		cancel()
		owner.console.log_line(message, "average")
		to_chat(owner, span_warning(message))
		return
	if(!owner.hop(next, TRUE))
		var/reason = owner.hop_denial(next)
		cancel()
		owner.console.log_line("Автопроход прерван. [reason]", "bad")
		to_chat(owner, span_warning("Автопроход прерван. [reason]"))
		return
	// Arrival emits extension signals. A listener may replace/cancel navigation,
	// end the dive or delete its owner; this callback no longer owns that state.
	if(QDELETED(src) || QDELETED(owner) || expected_generation != generation || !owner.host_node)
		return
	queue.Cut(1, 2)
	expected_source = owner.host_node.address
	if(is_active())
		schedule_step()
	else
		if(pursuit_target_ref)
			if(refresh_pursuit())
				schedule_step()
		else
			cancel()
			owner.console.log_line("Автопроход завершён.", "good")
			to_chat(owner, span_notice("Автопроход завершён."))
	owner.console.invalidate_ui()

/datum/netrun_entity_navigation/proc/ui_payload()
	if(!is_active())
		return null
	return list("target" = destination, "remaining" = length(queue))
