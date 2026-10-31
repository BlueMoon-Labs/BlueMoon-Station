/**
 * Мозг автономного бота. Думает по одному отменяемому таймеру через задачу
 * планировщика `bot` и за один шаг выполняет не больше одного действия: переход,
 * команду узла, боевую программу или подбор обломков. Фоновый взлом может
 * запускаться до боя, не отнимая боевой шаг. Движение и команды следуют после
 * боевого поведения; без целей программа бота составляет план.
 */
/datum/netrun_bot_brain
	var/mob/camera/netrun_entity/bot/owner
	var/list/datum/netrun_bot_goal/goals = list()
	var/state = "запуск"
	var/handling_behavior = FALSE
	var/in_combat = FALSE
	var/timer_id
	/// One deadline for signal-waiting work, independent of paced combat actions.
	var/goal_wait_timer_id
	var/datum/weakref/waiting_goal_ref
	var/goal_wait_deadline = 0
	/// address -> world.time of the last visit, bounded.
	var/list/visited = list()
	/// address -> expiry: unreachable or dangerous nodes are skipped for a while.
	var/list/blacklist = list()
	/// weakref(process) -> expiry: processes that attacked this bot or were marked as targets.
	var/list/enemies = list()
	var/datum/weakref/pending_attack_ref
	var/pending_attack_at = 0
	/// Agent order and its node (guard post).
	var/order
	var/datum/weakref/order_node_ref
	var/next_rogue_report = 0
	/// Exactly one ordinary command may be outstanding for this brain.
	var/command_serial = 0
	var/command_nonce
	var/command_address
	var/command_id
	var/command_phase
	var/command_result
	var/command_deadline = 0
	var/datum/weakref/command_packet_ref
	var/order_command
	var/order_command_address
	/// A rotating itinerary includes distant nodes without re-scanning the station each think.
	var/list/patrol_candidates
	var/patrol_cursor = 1
	/// Fisher-Yates is advanced only as far as this plan's bounded candidate window.
	var/patrol_shuffled_until = 0
	var/salvage_cursor = 1
	/// Earliest fresh debris deadline seen during the current bounded search.
	var/salvage_wait_until = 0
	/// Retain a legal local combat target across AP actions, not just telegraphs.
	var/datum/weakref/combat_target_ref
	var/datum/weakref/controlled_target_ref

/datum/netrun_bot_brain/New(mob/camera/netrun_entity/bot/owner)
	src.owner = owner

/datum/netrun_bot_brain/Destroy()
	clear_goal_wait()
	clear_timer()
	SSnetrun.task_scheduler?.cancel("bot", src)
	QDEL_LIST(goals)
	pending_attack_ref = null
	combat_target_ref = null
	controlled_target_ref = null
	order_node_ref = null
	release_incident()
	owner = null
	return ..()

// MARK: Такт

/datum/netrun_bot_brain/proc/clear_timer()
	if(timer_id)
		deltimer(timer_id)
	timer_id = null

/// Repeated scheduling of the same wait retains one cancellable deadline.
/datum/netrun_bot_brain/proc/schedule_goal_wait(datum/netrun_bot_goal/goal)
	if(QDELETED(src) || QDELETED(owner) || QDELETED(goal) || goal != current_goal() || !goal.waits_for_signal())
		return
	if(goal_wait_timer_id && IS_WEAKREF_OF(goal, waiting_goal_ref) && goal_wait_deadline == goal.expires_at)
		return
	clear_goal_wait()
	waiting_goal_ref = WEAKREF(goal)
	goal_wait_deadline = goal.expires_at
	goal_wait_timer_id = addtimer(CALLBACK(src, PROC_REF(on_goal_wait_timeout), waiting_goal_ref, goal_wait_deadline), max(NETRUN_EXECUTION_MIN_INTERVAL, goal_wait_deadline - world.time), TIMER_STOPPABLE | TIMER_DELETE_ME)

/datum/netrun_bot_brain/proc/clear_goal_wait(datum/netrun_bot_goal/goal)
	// Destruction may already hide goal from resolve(); compare its owned weakref.
	if(goal && !IS_WEAKREF_OF(goal, waiting_goal_ref))
		return
	if(goal_wait_timer_id)
		deltimer(goal_wait_timer_id)
	goal_wait_timer_id = null
	waiting_goal_ref = null
	goal_wait_deadline = 0

/// Timers admit work only. Goal cancellation and replanning run in the worker.
/datum/netrun_bot_brain/proc/on_goal_wait_timeout(datum/weakref/expected_goal, expected_deadline)
	if(waiting_goal_ref != expected_goal || goal_wait_deadline != expected_deadline)
		return
	var/datum/netrun_bot_goal/goal = expected_goal?.resolve()
	clear_goal_wait()
	if(!QDELETED(goal) && goal == current_goal() && goal.waits_for_signal())
		wake_now()

/datum/netrun_bot_brain/proc/schedule(delay)
	clear_timer()
	if(QDELETED(src) || QDELETED(owner))
		return
	timer_id = addtimer(CALLBACK(src, PROC_REF(wake_now)), max(NETRUN_EXECUTION_MIN_INTERVAL, delay), TIMER_STOPPABLE | TIMER_DELETE_ME)

/datum/netrun_bot_brain/proc/schedule_next()
	if(QDELETED(src) || QDELETED(owner))
		return
	// Actual turns and completion signals own combat scheduling, including AP leftovers.
	if(owner.console?.get_combat_encounter()?.active)
		return
	// Completion, stun recovery and return delivery own their exact wakeups.
	// A waiting agent does not poll the same fact every think_busy interval.
	if(owner.client || !owner.host_node || owner.is_stunned() || owner.return_pending)
		return
	var/datum/netrun_entity_module/goals_module = owner.entity_modules["bot_goals"]
	if(!goals_module?.enabled && !in_combat)
		return
	var/datum/netrun_bot_goal/waiting_goal = current_goal()
	if(!in_combat && waiting_goal?.waits_for_signal())
		schedule_goal_wait(waiting_goal)
		return
	if(command_nonce && !(command_phase in list("completed", "rejected", "cancelled")))
		schedule(max(NETRUN_EXECUTION_MIN_INTERVAL, command_deadline - world.time))
		return
	var/datum/netrun_bot_goal/guard/guard = current_goal()
	if(istype(guard) && owner.host_node == guard.post_ref?.resolve() && !in_combat)
		schedule(max(NETRUN_EXECUTION_MIN_INTERVAL, guard.expires_at - world.time))
		return
	var/datum/netrun_bot_program/program = owner.program
	var/interval = in_combat ? program.think_combat : (length(goals) ? program.think_busy : program.think_idle)
	schedule(interval + rand(-5, 5))

/// Timers and combat events only admit work; thinking runs inside the subsystem budget.
/datum/netrun_bot_brain/proc/wake_now()
	clear_timer()
	if(QDELETED(src) || QDELETED(owner))
		return
	SSnetrun.get_task_scheduler().enqueue("bot", src, NETRUN_TASK_NORMAL)

/datum/netrun_bot_brain/proc/think()
	if(QDELETED(owner) || QDELETED(owner.console) || owner.client || handling_behavior)
		return
	handling_behavior = TRUE
	// A stalled signal wait must expire even when combat/stun has priority.
	var/datum/netrun_bot_goal/goal = current_goal()
	if(goal && world.time >= goal.expires_at)
		finish_goal(goal)
	if(QDELETED(src) || QDELETED(owner))
		return
	owner.process_behavior(src)
	if(!QDELETED(src))
		handling_behavior = FALSE

/// Goal execution is a capability; policy and reactions live in installed modules.
/datum/netrun_bot_brain/proc/advance_goals()
	var/datum/netrun_bot_goal/goal = current_goal()
	if(goal && world.time >= goal.expires_at)
		finish_goal(goal)
		goal = null
	if(!goal)
		var/datum/netrun_agent_behavior/pattern/temperament/policy = netrun_actor_temperament(owner)
		if(policy)
			policy.plan(src)
		else
			owner.program.plan(src)
		goal = current_goal()
	if(!goal)
		state = "ожидание"
		return
	var/result = goal.advance()
	if(QDELETED(src) || QDELETED(goal))
		return
	if(result != NETRUN_BOT_GOAL_CONTINUE || world.time >= goal.expires_at)
		finish_goal(goal)

// MARK: Цели

/datum/netrun_bot_brain/proc/push_goal(datum/netrun_bot_goal/goal)
	if(!goal)
		return
	goals += goal
	while(length(goals) > 4)
		var/datum/netrun_bot_goal/oldest = goals[1]
		goals.Cut(1, 2)
		qdel(oldest)
	SEND_SIGNAL(owner, COMSIG_NETRUN_ENTITY_GOALS_CHANGED, handling_behavior)

/datum/netrun_bot_brain/proc/current_goal()
	RETURN_TYPE(/datum/netrun_bot_goal)
	return length(goals) ? goals[1] : null

/datum/netrun_bot_brain/proc/finish_goal(datum/netrun_bot_goal/goal)
	clear_goal_wait(goal)
	if(istype(goal, /datum/netrun_bot_goal/command) && order == "command")
		order = "guard"
		order_command = null
		order_command_address = null
	owner?.navigation?.cancel()
	clear_command()
	goals -= goal
	qdel(goal)
	SEND_SIGNAL(owner, COMSIG_NETRUN_ENTITY_GOALS_CHANGED, handling_behavior)

/datum/netrun_bot_brain/proc/clear_goals()
	clear_goal_wait()
	// A one-shot device mutation must never replay after recall/relaunch.
	if(order == "command")
		order = "guard"
		order_command = null
		order_command_address = null
	QDEL_LIST(goals)
	goals = list()
	owner?.navigation?.cancel()
	clear_command()
	release_incident()
	SEND_SIGNAL(owner, COMSIG_NETRUN_ENTITY_GOALS_CHANGED, handling_behavior)

/datum/netrun_bot_brain/proc/goal_text()
	var/datum/netrun_bot_goal/goal = current_goal()
	return goal ? goal.describe() : null

/// Retain only the delivered response of this brain's own command, never a live node journal.
/datum/netrun_bot_brain/proc/command_updated(datum/netrun_packet_context/operation)
	if(!command_nonce || operation.nonce != command_nonce)
		return
	command_phase = operation.phase
	if(operation.finished)
		command_result = operation.result
		SEND_SIGNAL(owner, COMSIG_NETRUN_ENTITY_COMMAND_FINISHED, operation.id)

/datum/netrun_bot_brain/proc/clear_command()
	var/datum/netrun_request/delivery/packet = command_packet_ref?.resolve()
	command_packet_ref = null
	if(!QDELETED(packet) && !packet.delivering)
		packet.cancelled = TRUE
		qdel(packet)
	command_nonce = null
	command_address = null
	command_id = null
	command_phase = null
	command_result = null
	command_deadline = 0

/// Ordinary entity commands retain their normal dispatch, latency and delivery-time ACL checks.
/datum/netrun_bot_brain/proc/command_step(datum/component/netrun_node/node, id)
	if(QDELETED(node) || QDELETED(owner?.console))
		return NETRUN_BOT_GOAL_FAILED
	if(command_nonce)
		if(command_address != node.address || command_id != id)
			return NETRUN_BOT_GOAL_FAILED
		if(command_phase == "completed")
			return NETRUN_BOT_GOAL_DONE
		if((command_phase in list("rejected", "cancelled")) || world.time >= command_deadline)
			return NETRUN_BOT_GOAL_FAILED
		return NETRUN_BOT_GOAL_CONTINUE
	if(world.time < owner.console.next_command)
		return NETRUN_BOT_GOAL_CONTINUE
	command_nonce = "bot-[++command_serial]"
	command_address = node.address
	command_id = id
	command_deadline = world.time + 30 SECONDS
	if(!owner.console.run_command(node, id, command_nonce))
		return NETRUN_BOT_GOAL_FAILED
	return NETRUN_BOT_GOAL_CONTINUE

// MARK: Память

/datum/netrun_bot_brain/proc/prune_memory()
	for(var/address in blacklist)
		if(blacklist[address] <= world.time)
			blacklist -= address
	for(var/datum/weakref/reference as anything in enemies)
		if(enemies[reference] <= world.time || !reference.resolve())
			enemies -= reference

/datum/netrun_bot_brain/proc/blacklist(address, duration = 2 MINUTES)
	if(!address)
		return
	blacklist[address] = world.time + duration
	while(length(blacklist) > 32)
		blacklist.Cut(1, 2)

/datum/netrun_bot_brain/proc/is_blacklisted(address)
	return blacklist[address] > world.time

/datum/netrun_bot_brain/proc/remember_visit(address)
	visited -= address
	visited[address] = world.time
	while(length(visited) > 64)
		visited.Cut(1, 2)

/datum/netrun_bot_brain/proc/mark_enemy(datum/target, duration = 60 SECONDS)
	if(QDELETED(target) || target == owner)
		return
	enemies[WEAKREF(target)] = world.time + duration
	while(length(enemies) > 16)
		enemies.Cut(1, 2)

/datum/netrun_bot_brain/proc/remembered_enemy(datum/target)
	return enemies[WEAKREF(target)] > world.time

/// The attacking session's own process becomes an enemy; a remote attacker cannot be hit back here.
/datum/netrun_bot_brain/proc/note_attacker(datum/netrun_console/attacker)
	var/datum/self = attacker?.combat_self()
	if(self && self != owner)
		mark_enemy(self)
	wake_now()

// MARK: Перемещение

/// One movement action toward a node: a direct hop, or an authorized auto-travel route.
/datum/netrun_bot_brain/proc/move_toward(datum/component/netrun_node/target)
	if(QDELETED(target) || QDELETED(owner))
		return NETRUN_BOT_MOVE_BLOCKED
	if(owner.host_node == target)
		remember_visit(target.address)
		return NETRUN_BOT_MOVE_ARRIVED
	var/datum/netrun_entity_navigation/navigation = owner.navigation
	if(navigation.is_active())
		if(navigation.destination == target.address)
			state = "в пути"
			if(world.time >= owner.next_hop)
				navigation.advance_route(navigation.generation)
			if(owner.host_node == target)
				remember_visit(target.address)
				return NETRUN_BOT_MOVE_ARRIVED
			return NETRUN_BOT_MOVE_PROGRESS
		navigation.cancel()
	if(world.time < owner.next_hop)
		return NETRUN_BOT_MOVE_PROGRESS
	// A neighbour is entered directly, including one guarded by ICE the bot wants to fight.
	if(owner.can_enter(target))
		state = "в пути"
		if(owner.hop(target))
			remember_visit(target.address)
			return NETRUN_BOT_MOVE_ARRIVED
		return NETRUN_BOT_MOVE_PROGRESS
	if(owner.travel_to(target))
		state = "в пути"
		return NETRUN_BOT_MOVE_PROGRESS
	if(queue_frontier_hack(target))
		return NETRUN_BOT_MOVE_PROGRESS
	return NETRUN_BOT_MOVE_BLOCKED

/// Breadth-first search over nodes this bot may enter, bounded to its surroundings.
/// `predicate` is a proc on this brain taking the candidate node.
/datum/netrun_bot_brain/proc/find_nearby_node(predicate, list/scope, limit = 48)
	var/datum/component/netrun_node/start = owner?.host_node
	if(!start)
		return null
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	var/datum/netrun_console/console = owner.console
	var/datum/netrun_path_tree/tree = console.connection.read_path_tree(TRUE)
	var/list/queue = list(start.address)
	var/list/seen = list()
	seen[start.address] = TRUE
	for(var/i = 1, i <= length(queue) && i <= limit, i++)
		var/datum/component/netrun_node/current = graph.nodes[queue[i]]
		if(QDELETED(current))
			continue
		if(current != start && !is_blacklisted(current.address) && call(src, predicate)(current))
			. = current
			break
		for(var/address in graph.neighbors(current.address, FALSE))
			if(seen[address])
				continue
			seen[address] = TRUE
			var/datum/component/netrun_node/next = graph.nodes[address]
			if(QDELETED(next) || !netrun_link_available(current, next))
				continue
			if(scope && !(next.network?.id in scope))
				continue
			if(!can_plan_visit(next, tree))
				continue
			queue += address
	console.release_path_tree(tree)

/datum/netrun_bot_brain/proc/node_has_salvage(datum/component/netrun_node/node)
	return !!best_salvage(node)

/// Pure bounded ranking; it never reads a device disk or grants file authority.
/proc/netrun_salvage_value(datum/netrun_file/file)
	if(QDELETED(file))
		return 0
	. = 10
	switch(file.kind)
		if(NETRUN_FILE_PROGRAM)
			. = 180
		if(NETRUN_FILE_DAEMON)
			. = 140
		if(NETRUN_FILE_BOT)
			. = 160
		if(NETRUN_FILE_KEY)
			. = 120
		if(NETRUN_FILE_TECHWEB, NETRUN_FILE_TECHWEB_LINK)
			. = 80
	if(file.fortress_reward)
		. += 70
	. += min(20, max(0, file.size))

/datum/netrun_bot_brain/proc/best_salvage(datum/component/netrun_node/node)
	RETURN_TYPE(/datum/netrun_file)
	if(QDELETED(node) || !node.is_online())
		return null
	var/best_value = -1
	for(var/datum/netrun_file/file as anything in node.salvage)
		if(QDELETED(file) || !file.can_transfer(null, TRUE) || !owner.console.inventory.local_store.can_fit(file))
			continue
		if(owner.bot_kind == NETRUN_BOT_RECYCLER && world.time < file.salvage_recycle_after)
			salvage_wait_until = min(salvage_wait_until || INFINITY, file.salvage_recycle_after)
			continue
		var/value = netrun_salvage_value(file)
		if(value > best_value)
			. = file
			best_value = value

/// Rank at most24 nonempty caches with one shared route table. Quality wins,
/// with actual route cost breaking ties; arbitrary station nodes are never polled.
/datum/netrun_bot_brain/proc/find_salvage(list/scope, station_only = FALSE)
	salvage_wait_until = 0
	var/datum/component/netrun_node/current = owner?.host_node
	var/datum/netrun_file/local = (station_only && current?.network?.isolated) ? null : best_salvage(current)
	var/datum/component/netrun_node/best = local ? current : null
	var/best_value = local ? netrun_salvage_value(local) : -1
	var/best_cost = local ? 0 : INFINITY
	var/list/candidates = SSnetrun.salvage_nodes
	if(!length(candidates))
		return best
	var/datum/netrun_console/console = owner.console
	var/datum/netrun_path_tree/tree = console.connection.read_path_tree(TRUE)
	for(var/index in 1 to min(24, length(candidates)))
		if(salvage_cursor > length(candidates))
			salvage_cursor = 1
		var/datum/component/netrun_node/node = candidates[candidates[salvage_cursor++]]
		if(QDELETED(node) || node == current || is_blacklisted(node.address) || (station_only && node.network?.isolated) || (scope && !(node.network?.id in scope)))
			continue
		if(!can_plan_visit(node, tree) || !console.can_route(node, tree))
			continue
		var/datum/netrun_file/file = best_salvage(node)
		if(!file)
			continue
		var/value = netrun_salvage_value(file)
		var/cost = tree.cost_to(node.address)
		if(value > best_value || (value == best_value && cost < best_cost))
			best = node
			best_value = value
			best_cost = cost
	console.release_path_tree(tree)
	return best

/datum/netrun_bot_brain/proc/node_has_ice(datum/component/netrun_node/node)
	return LAZYLEN(node.netrun_ice) > 0

/datum/netrun_bot_brain/proc/node_has_enemy(datum/component/netrun_node/node)
	if(!node.is_online())
		return FALSE
	for(var/mob/camera/netrun_entity/entity as anything in node.entities)
		if(entity != owner && !QDELETED(entity) && proactive_enemy(entity))
			return TRUE
	return FALSE

/datum/netrun_bot_brain/proc/node_is_patrol_point(datum/component/netrun_node/node)
	return node.is_online() && !node.is_dynamic() && world.time - (visited[node.address] || -INFINITY) > 2 MINUTES

/// Inspect at most24 itinerary entries per plan; the cursor eventually covers every
/// reachable node, including destinations beyond the nearby tactical search radius.
/datum/netrun_bot_brain/proc/patrol_destination(list/scope, police = FALSE)
	var/datum/netrun_console/console = owner.console
	var/datum/netrun_path_tree/tree = console.connection.read_path_tree(TRUE)
	if(!length(patrol_candidates) || patrol_cursor > length(patrol_candidates))
		patrol_candidates = tree.reached.Copy()
		patrol_cursor = 1
		patrol_shuffled_until = 0
	var/best_index
	var/best_time = INFINITY
	var/best_activity = -INFINITY
	var/end = min(length(patrol_candidates), patrol_cursor + 23)
	// A full station shuffle used to run before the 24-candidate bound. Shuffle
	// the next prefix lazily, preserving random coverage without a long cold step.
	for(var/index = max(patrol_cursor, patrol_shuffled_until + 1), index <= end, index++)
		patrol_candidates.Swap(index, rand(index, length(patrol_candidates)))
	patrol_shuffled_until = end
	for(var/index = patrol_cursor, index <= end, index++)
		var/address = patrol_candidates[index]
		var/datum/component/netrun_node/node = SSnetrun.nodes_by_address[address]
		if(QDELETED(node) || !tree.reached[address] || node.network?.isolated || node.is_dynamic() || !node.is_online() || is_blacklisted(address))
			continue
		if(scope && !(node.network?.id in scope))
			continue
		if(!can_plan_visit(node, tree) || (police && console.node_level(node, tree) < NETRUN_ACCESS_USER))
			continue
		var/inspected = police ? SSnetrun.police_inspected[address] : visited[address]
		var/score = isnull(inspected) ? -INFINITY : inspected
		if(!best_index || score < best_time || (score == best_time && node.last_activity > best_activity))
			best_index = index
			best_time = score
			best_activity = node.last_activity
	if(best_index)
		var/address = patrol_candidates[best_index]
		. = SSnetrun.nodes_by_address[address]
		patrol_candidates[best_index] = patrol_candidates[patrol_cursor]
		patrol_candidates[patrol_cursor++] = address
	else
		patrol_cursor = end + 1
	console.release_path_tree(tree)

// MARK: Бой

/datum/netrun_bot_brain/proc/hostiles()
	. = list()
	var/datum/component/netrun_node/node = owner.host_node
	if(!node)
		return
	var/list/candidates = list()
	var/datum/netrun_agent_behavior/pattern/temperament/policy = netrun_actor_temperament(owner)
	for(var/datum/netrun_ice/ice as anything in node.netrun_ice)
		if(QDELETED(ice))
			continue
		var/retaliating = remembered_enemy(ice) || ice.enemy_ref?.resolve() == owner || ice.pending_target() == owner
		if(retaliating || (ice.is_intruder(owner, node) && (!policy || policy.willing_to_engage(ice))))
			candidates += ice
	for(var/mob/camera/netrun_entity/entity as anything in node.entities)
		if(entity == owner || QDELETED(entity) || world.time < entity.combat_ignore_until)
			continue
		if(remembered_enemy(entity) || proactive_enemy(entity))
			candidates += entity
	var/list/fortified_nodes = list(node) + netrun_adjacent_fortress_nodes(node)
	for(var/datum/component/netrun_node/fortified as anything in fortified_nodes)
		var/datum/netrun_fortress/fortress = fortified.fortress
		if(QDELETED(fortress) || !fortified.is_online() || fortress.is_friendly(owner.console))
			continue
		if(fortress.hostile_to(owner) || netrun_bot_factions_hostile(owner.net_faction, fortress.faction))
			candidates += fortified == node ? fortress.combat_targets() : fortress.siege_targets()
	// A remote siege binds the bot to the defended node. Targets at its source
	// and inner works behind walls must obey the same native contact checks.
	for(var/datum/target as anything in candidates)
		if(!owner.console.combat_context.target_denial(target, null, node, TRUE))
			. += target

/datum/netrun_bot_brain/proc/combat_step()
	var/datum/netrun_combat_encounter/encounter = owner.console.get_combat_encounter()
	if(encounter?.active && (!encounter.has_turn(owner.console) || encounter.deferred))
		in_combat = TRUE
		state = "ожидание хода"
		return TRUE
	var/list/foes = hostiles()
	if(!length(foes))
		if(encounter?.active && encounter.has_turn(owner.console))
			encounter.pass(owner.console)
			return TRUE
		in_combat = FALSE
		pending_attack_ref = null
		combat_target_ref = null
		controlled_target_ref = null
		return FALSE
	in_combat = TRUE
	state = "бой"
	var/datum/target = pick_target(foes)
	// Structure attacks authorize their native siege lease and select the
	// defended node inside program_use(); passive works need no controller.
	if(!encounter && !istype(target, /datum/netrun_fortress_module))
		encounter = owner.host_node.get_combat_encounter()
		if(!encounter.admit(owner.console, 1, target))
			return TRUE
	// Navigation must not carry a fighting process away between two brain tasks.
	if(owner.navigation.is_active())
		owner.navigation.cancel()
	var/ratio = owner.integrity / max(1, owner.max_integrity)
	var/datum/netrun_agent_behavior/pattern/temperament/policy = netrun_actor_temperament(owner)
	if(ratio < (policy ? policy.caution / 100 : owner.program.flee_ratio) && try_flee())
		return TRUE
	if(ratio < 0.5 && world.time >= owner.combat_shield_until && use_role(NETRUN_PROGRAM_SHIELD, owner))
		return TRUE
	if(ratio < 0.4 && use_role(NETRUN_PROGRAM_REPAIR, owner))
		return TRUE
	var/list/target_hp = netrun_combatant_integrity(target)
	var/ordinary_hit = SSnetrun.get_program("strike")?.power || 22
	// Real-time interrupts cannot be cast in somebody else's active turn.
	// Prepare one proactive control effect against a healthy opponent instead;
	// native status/cooldown checks prevent stacking, and cheap finishes stay cheap.
	if(encounter?.active && target_hp?["cur"] > ordinary_hit && !IS_WEAKREF_OF(target, controlled_target_ref) && use_role(NETRUN_PROGRAM_STUN, target))
		controlled_target_ref = WEAKREF(target)
		return TRUE
	if(istype(target, /datum/netrun_ice))
		var/datum/netrun_ice/ice = target
		if(ice.pending_program && use_role(NETRUN_PROGRAM_STUN, ice))
			return TRUE
		if(!use_role(NETRUN_PROGRAM_ATTACK, ice))
			pass_if_idle()
		return TRUE
	if(!encounter?.active && istype(target, /mob/camera/netrun_entity) && !istype(target, /mob/camera/netrun_entity/bot))
		telegraphed_attack(target)
		return TRUE
	if(!use_role(NETRUN_PROGRAM_ATTACK, target))
		pass_if_idle()
	return TRUE

/// No affordable legal program means a deliberate pass, rather than periodic retries.
/datum/netrun_bot_brain/proc/pass_if_idle()
	var/datum/netrun_combat_encounter/encounter = owner.console.get_combat_encounter()
	if(encounter?.active && encounter.has_turn(owner.console) && !encounter.deferred)
		encounter.pass(owner.console)

/datum/netrun_bot_brain/proc/pick_target(list/foes)
	var/datum/current_target = combat_target_ref?.resolve()
	if(current_target && (current_target in foes))
		return current_target
	var/datum/pending = pending_attack_ref?.resolve()
	if(pending && (pending in foes))
		combat_target_ref = WEAKREF(pending)
		return pending
	var/best_hp = INFINITY
	for(var/datum/foe as anything in foes)
		var/list/hp = netrun_combatant_integrity(foe)
		var/current_hp = hp ? hp["cur"] : INFINITY
		if(!. || current_hp < best_hp)
			. = foe
			best_hp = current_hp
	combat_target_ref = . ? WEAKREF(.) : null

/// Prefer effective benefit per AP, conserving consumables for worthwhile hits.
/// Legacy real-time behavior retains its strongest-program policy.
/datum/netrun_bot_brain/proc/program_value(datum/netrun_program/program, effective_limit, turn_based)
	return program.bot_value(effective_limit, turn_based)

/// Readiness, target status, AP and execution still use the native combat path.
/datum/netrun_bot_brain/proc/use_role(role, datum/target)
	var/datum/netrun_console/console = owner.console
	var/datum/netrun_combat_context/combat = console.combat_context
	var/datum/netrun_combat_encounter/encounter = console.get_combat_encounter()
	if(QDELETED(target) || (encounter?.active ? (!encounter.has_turn(console) || encounter.deferred) : world.time < combat.next_program))
		return FALSE
	if(role == NETRUN_PROGRAM_STUN && istype(target, /datum/netrun_fortress_module))
		var/datum/netrun_fortress_module/module = target
		if(module.kind != NETRUN_FORT_TURRET || module.status != NETRUN_FORT_MODULE_ONLINE)
			return FALSE
	var/best_uid
	var/best_value = -1
	var/list/hp = netrun_combatant_integrity(target)
	var/effective_limit = hp ? (role == NETRUN_PROGRAM_REPAIR ? hp["max"] - hp["cur"] : hp["cur"]) : INFINITY
	for(var/id in console.builtin_program_ids())
		var/datum/netrun_program/program = SSnetrun.get_program(id)
		if(program?.role != role || (encounter?.active ? (encounter.cooldown_remaining(console, program) || program.ap_cost > encounter.remaining_ap(console) || !encounter.can_apply_program_status(program, target)) : world.time < (combat.program_cd[program.id] || 0)))
			continue
		var/value = program_value(program, effective_limit, encounter?.active)
		if(value > best_value)
			best_uid = "builtin:[id]"
			best_value = value
	for(var/datum/netrun_file/file as anything in console.all_files())
		if(file.kind != NETRUN_FILE_PROGRAM)
			continue
		var/datum/netrun_program/program = SSnetrun.get_program(file.content)
		if(program?.role != role || (encounter?.active ? (encounter.cooldown_remaining(console, program) || program.ap_cost > encounter.remaining_ap(console) || !encounter.can_apply_program_status(program, target)) : world.time < (combat.program_cd[program.id] || 0)))
			continue
		var/value = program_value(program, effective_limit, encounter?.active)
		if(value > best_value)
			best_uid = file.uid
			best_value = value
	if(!best_uid)
		return FALSE
	return console.program_use(best_uid, REF(target))

/// Player processes get the same warning ICE gives before a hit.
/datum/netrun_bot_brain/proc/telegraphed_attack(mob/camera/netrun_entity/target)
	var/datum/pending = pending_attack_ref?.resolve()
	if(pending == target)
		if(world.time < pending_attack_at)
			return TRUE
		pending_attack_ref = null
		return use_role(NETRUN_PROGRAM_ATTACK, target)
	pending_attack_ref = WEAKREF(target)
	pending_attack_at = world.time + NETRUN_ICE_MIN_TELEGRAPH
	var/seconds = NETRUN_ICE_MIN_TELEGRAPH / (1 SECONDS)
	to_chat(target, span_userdanger("[owner.real_name] готовит атаку на ваш процесс: [seconds] с. Щит снизит урон, уход из узла сорвёт удар."))
	target.console?.combat_log("[owner.real_name] готовит атаку: [seconds] с до удара.", "bad")
	return TRUE

/// Leave through an enterable neighbour without hostile ICE.
/datum/netrun_bot_brain/proc/try_flee()
	var/datum/component/netrun_node/here = owner.host_node
	if(!here || world.time < owner.next_hop)
		return FALSE
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	for(var/address in shuffle(graph.neighbors(here.address, FALSE)))
		var/datum/component/netrun_node/next = graph.nodes[address]
		if(QDELETED(next) || is_blacklisted(address) || !owner.can_enter(next))
			continue
		var/dangerous = FALSE
		for(var/datum/netrun_ice/ice as anything in next.netrun_ice)
			if(!QDELETED(ice) && ice.is_intruder(owner, next))
				dangerous = TRUE
				break
		if(dangerous || !owner.hop(next))
			continue
		blacklist(here.address, 30 SECONDS)
		state = "отступление"
		owner.navigation.cancel()
		return TRUE
	return FALSE

// MARK: Наблюдение и агенты

/// Custodians notify the police about rogue processes they meet.
/datum/netrun_bot_brain/proc/report_rogues()
	if(world.time < next_rogue_report)
		return
	for(var/mob/camera/netrun_entity/bot/other in owner.host_node.entities)
		if(netrun_bot_factions_hostile(owner.net_faction, other.net_faction))
			next_rogue_report = world.time + 20 SECONDS
			SSnetrun.report_incident("rogue", owner.host_node, other, NETRUN_INCIDENT_MEDIUM, "[owner.real_name] сообщает о диком процессе [other.real_name].")
			return

/datum/netrun_bot_brain/proc/post_node()
	RETURN_TYPE(/datum/component/netrun_node)
	var/datum/component/netrun_node/node = order_node_ref?.resolve()
	return node || SSnetrun.find_node(owner.home_address)

/datum/netrun_bot_brain/proc/at_post()
	var/datum/component/netrun_node/post = post_node()
	return post && owner.host_node == post

/// A process without USER on the post that is neither the owner nor one of its agents.
/datum/netrun_bot_brain/proc/trespasser(mob/camera/netrun_entity/entity)
	if(!istype(entity) || entity == owner || QDELETED(entity.console) || !entity.defense_threat())
		return FALSE
	var/datum/netrun_console/master = owner.netrun_owner_console()
	if(master && (entity.console == master || entity.netrun_owner_console() == master))
		return FALSE
	return entity.console.node_level(owner.host_node) < NETRUN_ACCESS_USER

/datum/netrun_task/bot
	kind = "bot"

/datum/netrun_task/bot/execute(datum/controller/subsystem/netrun/worker, datum/netrun_execution_limits/limits)
	var/datum/netrun_bot_brain/brain = target()
	if(QDELETED(brain))
		return FALSE
	brain.think()
	if(!QDELETED(brain))
		brain.schedule_next()
	return TRUE

/// Bot movement shares the brain's common-worker budget. Timers only admit a step.
/datum/netrun_entity_navigation/bot/schedule_step()
	if(timer)
		deltimer(timer)
	timer = addtimer(CALLBACK(src, PROC_REF(wake_brain)), max(1, owner.next_hop - world.time), TIMER_STOPPABLE)

/datum/netrun_entity_navigation/bot/proc/wake_brain()
	timer = null
	var/mob/camera/netrun_entity/bot/bot = owner
	bot?.brain?.wake_now()

/// These bots deliberately engage ICE; each hop still revalidates the entity's actual authority.
/datum/netrun_entity_navigation/bot/threat_at(datum/component/netrun_node/next)
	return null

/datum/netrun_bot_brain/proc/proactive_enemy(mob/camera/netrun_entity/entity)
	var/datum/netrun_agent_behavior/pattern/temperament/policy = netrun_actor_temperament(owner)
	return owner.program.is_enemy(src, entity) && (!policy || policy.willing_to_engage(entity))
