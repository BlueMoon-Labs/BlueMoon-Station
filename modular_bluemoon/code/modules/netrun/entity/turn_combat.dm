/// Turn ownership is local to an actual encounter, never a station-wide clock.
/datum/component/netrun_node
	var/datum/netrun_combat_encounter/combat_encounter

/datum/component/netrun_node/proc/get_combat_encounter()
	RETURN_TYPE(/datum/netrun_combat_encounter)
	if(QDELETED(src))
		return null
	if(QDELETED(combat_encounter))
		combat_encounter = new(src)
	return combat_encounter

/datum/netrun_console
	var/datum/weakref/combat_encounter_ref
	var/combat_carried_ap = -1
	var/combat_carried_until = 0

/datum/netrun_console/proc/get_combat_encounter()
	RETURN_TYPE(/datum/netrun_combat_encounter)
	return combat_encounter_ref?.resolve()

/datum/netrun_ice
	var/datum/weakref/combat_encounter_ref
	var/combat_carried_ap = -1
	var/combat_carried_until = 0

/datum/netrun_ice/proc/get_combat_encounter()
	RETURN_TYPE(/datum/netrun_combat_encounter)
	return combat_encounter_ref?.resolve()

/// Changing nodes cannot refill an unfinished decision's budget for hit-and-run
/// loops. Once that decision expires, a new encounter starts with ordinary AP.
/proc/netrun_carried_turn_ap(datum/actor)
	if(istype(actor, /datum/netrun_console))
		var/datum/netrun_console/console = actor
		. = console.combat_carried_until > world.time && console.combat_carried_ap >= 0 ? console.combat_carried_ap : NETRUN_COMBAT_AP
		console.combat_carried_ap = -1
	else if(istype(actor, /datum/netrun_ice))
		var/datum/netrun_ice/ice = actor
		. = ice.combat_carried_until > world.time && ice.combat_carried_ap >= 0 ? ice.combat_carried_ap : NETRUN_COMBAT_AP
		ice.combat_carried_ap = -1
	else
		. = NETRUN_COMBAT_AP
	return clamp(., 0, NETRUN_COMBAT_AP)

/// Bodies and their console are one actor; passive structures do not take turns.
/proc/netrun_turn_actor(datum/actor)
	if(istype(actor, /datum/netrun_fortress_module))
		var/datum/netrun_fortress_module/module = actor
		return module.fortress?.has_turn_battery() ? module.fortress : null
	if(istype(actor, /datum/netrun_fortress))
		var/datum/netrun_fortress/fortress = actor
		return fortress.has_turn_battery() ? fortress : null
	if(istype(actor, /mob/camera/netrun_entity))
		var/mob/camera/netrun_entity/entity = actor
		return entity.console
	if(istype(actor, /datum/netrun_console) || istype(actor, /datum/netrun_ice))
		return actor
	return null

/proc/netrun_turn_encounter(datum/actor)
	RETURN_TYPE(/datum/netrun_combat_encounter)
	actor = netrun_turn_actor(actor)
	if(istype(actor, /datum/netrun_fortress))
		var/datum/netrun_fortress/fortress = actor
		return fortress.get_combat_encounter()
	if(istype(actor, /datum/netrun_console))
		var/datum/netrun_console/console = actor
		return console.get_combat_encounter()
	if(istype(actor, /datum/netrun_ice))
		var/datum/netrun_ice/ice = actor
		return ice.get_combat_encounter()

/datum/netrun_turn_participant
	var/datum/netrun_combat_encounter/encounter
	var/datum/weakref/actor_ref
	var/datum/weakref/body_ref
	var/datum/weakref/breach_ref
	/// A remote resident is bound to the exact native breach and original host.
	var/datum/weakref/source_node_ref
	var/ap = 0
	var/own_turn = 0
	var/list/program_turn_cooldowns = list()
	var/shield_until_turn = 0
	var/shield_factor = 1
	var/stun_turns = 0
	var/stun_immune = FALSE
	var/real_turn = FALSE

/datum/netrun_turn_participant/New(datum/netrun_combat_encounter/encounter, datum/actor)
	src.encounter = encounter
	actor_ref = WEAKREF(actor)
	RegisterSignal(actor, COMSIG_PARENT_QDELETING, PROC_REF(on_departure))
	if(istype(actor, /datum/netrun_ice))
		body_ref = WEAKREF(actor)
		RegisterSignal(actor, COMSIG_NETRUN_ICE_NODE_CHANGED, PROC_REF(on_moved))
	else if(istype(actor, /datum/netrun_console))
		var/datum/netrun_console/console = actor
		var/mob/camera/netrun_entity/entity = console.combat_self()
		if(istype(entity))
			body_ref = WEAKREF(entity)
			RegisterSignal(entity, COMSIG_PARENT_QDELETING, PROC_REF(on_departure))
			RegisterSignal(entity, COMSIG_NETRUN_ENTITY_NODE_CHANGED, PROC_REF(on_moved))
			var/datum/component/netrun_node/anchor = encounter.node_ref?.resolve()
			var/datum/netrun_breach/breach = console.intrusion.breach
			if(entity.host_node && entity.host_node != anchor && !anchor?.fortress?.valid_turn_siege(entity) && !QDELETED(breach) && ((breach.target_kind == "network" && breach.target_id == anchor?.network?.id) || (breach.target_kind != "network" && breach.target_id == anchor?.address)))
				breach_ref = WEAKREF(breach)
				source_node_ref = WEAKREF(entity.host_node)
				RegisterSignal(breach, COMSIG_PARENT_QDELETING, PROC_REF(on_departure))
				RegisterSignal(entity.host_node, COMSIG_PARENT_QDELETING, PROC_REF(on_departure))
		else if(!QDELETED(console.intrusion.breach))
			breach_ref = WEAKREF(console.intrusion.breach)
			RegisterSignal(console.intrusion.breach, COMSIG_PARENT_QDELETING, PROC_REF(on_departure))

/datum/netrun_turn_participant/Destroy()
	var/datum/actor = actor_ref?.resolve()
	if(actor)
		UnregisterSignal(actor, list(COMSIG_PARENT_QDELETING, COMSIG_NETRUN_ICE_NODE_CHANGED))
	var/datum/body = body_ref?.resolve()
	if(body && body != actor)
		UnregisterSignal(body, list(COMSIG_PARENT_QDELETING, COMSIG_NETRUN_ENTITY_NODE_CHANGED))
	var/datum/breach = breach_ref?.resolve()
	if(breach)
		UnregisterSignal(breach, COMSIG_PARENT_QDELETING)
	var/datum/source_node = source_node_ref?.resolve()
	if(source_node)
		UnregisterSignal(source_node, COMSIG_PARENT_QDELETING)
	clear_statuses()
	encounter = null
	actor_ref = null
	body_ref = null
	breach_ref = null
	source_node_ref = null
	return ..()

/datum/netrun_turn_participant/proc/actor()
	return actor_ref?.resolve()

/datum/netrun_turn_participant/proc/on_departure(datum/source)
	SIGNAL_HANDLER
	encounter?.remove(src)

/datum/netrun_turn_participant/proc/on_moved(datum/source)
	SIGNAL_HANDLER
	if(!valid())
		encounter?.remove(src)

/datum/netrun_turn_participant/proc/valid()
	var/datum/actor = actor()
	var/datum/component/netrun_node/node = encounter?.node_ref?.resolve()
	if(QDELETED(actor) || QDELETED(node))
		return FALSE
	if(istype(actor, /datum/netrun_fortress))
		var/datum/netrun_fortress/fortress = actor
		return fortress.node == node && fortress.has_turn_battery()
	if(istype(actor, /datum/netrun_ice))
		var/datum/netrun_ice/ice = actor
		return ice.node == node
	var/datum/netrun_console/console = actor
	if(console.is_locked())
		return FALSE
	var/mob/camera/netrun_entity/entity = body_ref?.resolve()
	if(body_ref && !entity)
		return FALSE
	if(istype(entity))
		if(source_node_ref)
			var/datum/component/netrun_node/source_node = source_node_ref.resolve()
			var/datum/netrun_breach/breach = breach_ref?.resolve()
			if(entity.console != console || QDELETED(source_node) || entity.host_node != source_node || QDELETED(breach) || console.intrusion.breach != breach)
				return FALSE
			if(!((breach.target_kind == "network" && breach.target_id == node.network?.id) || (breach.target_kind != "network" && breach.target_id == node.address)))
				return FALSE
			var/datum/netrun_path_tree/tree = console.connection.read_path_tree(TRUE)
			var/reachable = console.can_route(node, tree)
			console.release_path_tree(tree)
			var/native_valid = reachable && breach.valid_target()
			// A native authority read can process a queued firewall and delete this breach.
			return native_valid && !QDELETED(breach) && console.intrusion.breach == breach
		return entity.console == console && (entity.host_node == node || node.fortress?.valid_turn_siege(entity))
	var/datum/netrun_breach/breach = breach_ref?.resolve()
	if(breach_ref)
		return !QDELETED(breach) && breach == console.intrusion.breach
	return console.combat_node() == node

/datum/netrun_turn_participant/proc/display_name()
	var/datum/actor = actor()
	if(istype(actor, /datum/netrun_fortress))
		var/datum/netrun_fortress/fortress = actor
		return "Батарея: [fortress.name]"
	if(istype(actor, /datum/netrun_ice))
		var/datum/netrun_ice/ice = actor
		return ice.name
	var/mob/camera/netrun_entity/entity = body_ref?.resolve()
	return entity?.real_name || "Удалённый сетевой клиент"

/datum/netrun_turn_participant/proc/visible_ref()
	var/datum/visible = body_ref?.resolve() || actor()
	return QDELETED(visible) ? null : REF(visible)

/// Infinite native timestamps represent turn-owned statuses only while bound.
/datum/netrun_turn_participant/proc/clear_statuses()
	clear_shield()
	clear_stun()

/datum/netrun_turn_participant/proc/clear_shield()
	var/datum/body = body_ref?.resolve()
	if(istype(body, /datum/netrun_ice))
		var/datum/netrun_ice/ice = body
		if(shield_until_turn && ice.combat_shield_until == INFINITY)
			ice.combat_shield_until = world.time
	else if(istype(body, /mob/camera/netrun_entity))
		var/mob/camera/netrun_entity/entity = body
		if(shield_until_turn && entity.combat_shield_until == INFINITY)
			entity.combat_shield_until = world.time
	shield_until_turn = 0
	shield_factor = 1

/datum/netrun_turn_participant/proc/clear_stun()
	var/datum/actor = actor()
	if(istype(actor, /datum/netrun_fortress))
		var/datum/netrun_fortress/fortress = actor
		fortress.clear_turn_stuns()
	var/datum/body = body_ref?.resolve()
	if(istype(body, /datum/netrun_ice))
		var/datum/netrun_ice/ice = body
		if(ice.combat_stun_until == INFINITY)
			ice.combat_stun_until = world.time
	else if(istype(body, /mob/camera/netrun_entity))
		var/mob/camera/netrun_entity/entity = body
		if(entity.combat_stun_until == INFINITY)
			entity.combat_stun_until = world.time
	stun_turns = 0

/datum/netrun_turn_participant/proc/begin_turn()
	own_turn++
	ap = own_turn == 1 ? netrun_carried_turn_ap(actor()) : NETRUN_COMBAT_AP
	real_turn = FALSE
	if(shield_until_turn && own_turn >= shield_until_turn)
		clear_shield()
	if(stun_turns <= 0)
		real_turn = ap > 0
		return real_turn
	stun_turns--
	stun_immune = TRUE
	if(!stun_turns)
		clear_stun()
	ap = 0
	return FALSE

/datum/netrun_combat_encounter
	var/static/next_serial = 0
	var/serial
	var/datum/weakref/node_ref
	var/list/datum/netrun_turn_participant/participants = list()
	var/current_index = 0
	var/round = 1
	var/quiet_rounds = 0
	var/round_had_combat = FALSE
	var/deadline = 0
	var/timer_id
	var/generation = 0
	var/deferred = FALSE
	var/active = FALSE
	var/advancing = FALSE
	var/closing = FALSE

/datum/netrun_combat_encounter/New(datum/component/netrun_node/node)
	serial = ++next_serial
	node_ref = WEAKREF(node)
	RegisterSignal(node, COMSIG_PARENT_QDELETING, PROC_REF(on_host_deleted))

/datum/netrun_combat_encounter/Destroy()
	closing = TRUE
	if(timer_id)
		deltimer(timer_id)
	timer_id = null
	generation++
	SSnetrun.task_scheduler?.cancel("combat_turn", src)
	var/datum/component/netrun_node/node = node_ref?.resolve()
	if(node)
		UnregisterSignal(node, COMSIG_PARENT_QDELETING)
		if(node.combat_encounter == src)
			node.combat_encounter = null
	for(var/datum/netrun_turn_participant/participant as anything in participants)
		unbind(participant)
	QDEL_LIST(participants)
	if(node)
		SEND_SIGNAL(node, COMSIG_NETRUN_TURN_CHANGED, null)
	node_ref = null
	return ..()

/datum/netrun_combat_encounter/proc/on_host_deleted(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/netrun_combat_encounter/proc/member(datum/actor)
	RETURN_TYPE(/datum/netrun_turn_participant)
	actor = netrun_turn_actor(actor)
	if(QDELETED(actor))
		return null
	for(var/datum/netrun_turn_participant/participant as anything in participants)
		if(participant.actor() == actor)
			return participant

/datum/netrun_combat_encounter/proc/contains(datum/actor)
	return !!member(actor)

/datum/netrun_combat_encounter/proc/current()
	RETURN_TYPE(/datum/netrun_turn_participant)
	return current_index > 0 && current_index <= length(participants) ? participants[current_index] : null

/datum/netrun_combat_encounter/proc/has_turn(datum/actor)
	return !closing && (!active || (world.time < deadline && current()?.actor() == netrun_turn_actor(actor)))

/// A delayed browser action belongs to one decision, including across encounters.
/// Native synchronous callers omit the token and retain the same arbitration.
/datum/netrun_combat_encounter/proc/decision_id()
	return "[serial]:[generation]"

/datum/netrun_combat_encounter/proc/accepts_input(turn_id)
	return isnull(turn_id) || (istext(turn_id) && active && !closing && turn_id == decision_id())

/// Joining is an encounter-level intent, so NPC turn changes cannot invalidate
/// the click. Older clients may still send a decision from this same encounter.
/datum/netrun_combat_encounter/proc/join_id()
	return "[serial]"

/datum/netrun_combat_encounter/proc/accepts_join_input(token)
	if(!active || closing)
		return FALSE
	if(isnull(token) || token == join_id())
		return TRUE
	if(!istext(token))
		return FALSE
	var/list/parts = splittext(token, ":")
	if(length(parts) != 2 || parts[1] != join_id())
		return FALSE
	var/decision = text2num(parts[2])
	return isnum(decision) && decision >= 1 && decision <= generation && "[decision]" == parts[2]

/// Input cannot spend an expired turn while its queued timeout awaits the worker.
/datum/netrun_combat_encounter/proc/expired_input()
	if(active && world.time >= deadline)
		expire_turn()
		return TRUE
	return FALSE

/datum/netrun_combat_encounter/proc/is_waiting(datum/actor)
	return active && contains(actor) && (!has_turn(actor) || deferred)

/datum/netrun_combat_encounter/proc/remaining_ap(datum/actor)
	var/datum/netrun_turn_participant/participant = member(actor)
	return !active ? NETRUN_COMBAT_AP : (has_turn(actor) ? participant?.ap || 0 : 0)

/datum/netrun_combat_encounter/proc/join(datum/actor)
	actor = netrun_turn_actor(actor)
	if(QDELETED(actor))
		return null
	var/datum/netrun_turn_participant/participant = member(actor)
	if(participant)
		if(participant.valid())
			return participant
		remove(participant)
		return null
	var/datum/netrun_combat_encounter/previous = netrun_turn_encounter(actor)
	if(previous && previous != src && previous.contains(actor))
		return null
	participant = new(src, actor)
	if(!participant.valid())
		qdel(participant)
		return null
	participants += participant
	if(istype(actor, /datum/netrun_console))
		var/datum/netrun_console/console = actor
		console.combat_encounter_ref = WEAKREF(src)
	else if(istype(actor, /datum/netrun_ice))
		var/datum/netrun_ice/ice = actor
		ice.combat_encounter_ref = WEAKREF(src)
	else if(istype(actor, /datum/netrun_fortress))
		var/datum/netrun_fortress/fortress = actor
		fortress.combat_encounter_ref = WEAKREF(src)
		fortress.turn_regen_at = 0
	return participant

/datum/netrun_combat_encounter/proc/unbind(datum/netrun_turn_participant/participant, leaving = FALSE)
	var/datum/actor = participant.actor()
	if(leaving && active && world.time < deadline)
		var/carried = current() == participant ? participant.ap : 0
		if(istype(actor, /datum/netrun_console))
			var/datum/netrun_console/console = actor
			console.combat_carried_ap = carried
			console.combat_carried_until = deadline
		else if(istype(actor, /datum/netrun_ice))
			var/datum/netrun_ice/ice = actor
			ice.combat_carried_ap = carried
			ice.combat_carried_until = deadline
	if(istype(actor, /datum/netrun_fortress))
		var/datum/netrun_fortress/fortress = actor
		if(weak_reference && fortress.combat_encounter_ref == weak_reference)
			fortress.combat_encounter_ref = null
			fortress.cancel_turret(FALSE)
			fortress.schedule()
		return
	if(istype(actor, /datum/netrun_console))
		var/datum/netrun_console/console = actor
		if(weak_reference && console.combat_encounter_ref == weak_reference)
			console.combat_encounter_ref = null
		console.invalidate_ui()
		var/mob/camera/netrun_entity/bot/bot = console.combat_self()
		if(istype(bot) && !bot.client && !QDELETED(bot.host_node))
			bot.brain?.schedule(0.5 SECONDS)
	else if(istype(actor, /datum/netrun_ice))
		var/datum/netrun_ice/ice = actor
		// resolve() intentionally hides this controller once Destroy has started.
		// Compare the owned weakref object so teardown still cancels its native cast.
		if(weak_reference && ice.combat_encounter_ref == weak_reference)
			ice.combat_encounter_ref = null
			ice.cancel_program()
			if(!QDELETED(ice.node))
				ice.reaction?.wake()

/datum/netrun_combat_encounter/proc/remove(datum/netrun_turn_participant/participant)
	var/index = participants.Find(participant)
	if(!index || closing)
		return
	var/was_current = index == current_index
	unbind(participant, TRUE)
	participants.Cut(index, index + 1)
	qdel(participant)
	if(index <= current_index)
		current_index--
	if(!length(participants) || (active && length(participants) <= 1))
		qdel(src)
		return
	if(was_current)
		deferred = FALSE
		advance()
	else
		changed()

/// Native validation occurs before admission; this method only arbitrates time/AP.
/datum/netrun_combat_encounter/proc/admit(datum/actor, cost, datum/target)
	if(closing || !IS_FINITE(cost) || cost < 1 || cost > NETRUN_COMBAT_AP || round(cost) != cost)
		return FALSE
	if(expired_input())
		return FALSE
	var/datum/netrun_turn_participant/previous = member(actor)
	// Joining an existing encounter is an explicit intent to participate. It
	// enrolls only the caller; a rejected attack must not recruit a third party.
	if(active && !previous)
		if(join(actor))
			changed()
		return FALSE
	if(active && (!has_turn(actor) || deferred || previous.ap < cost))
		return FALSE
	var/datum/netrun_turn_participant/participant = join(actor)
	if(!participant)
		return FALSE
	var/datum/opponent = netrun_turn_actor(target)
	if(opponent && opponent != participant.actor() && !join(opponent))
		if(!previous)
			remove(participant)
		return FALSE
	if(!active && length(participants) >= 2)
		active = TRUE
		current_index = participants.Find(participant) - 1
		advance()
	return !active || (has_turn(actor) && !deferred && participant.ap >= cost)

/datum/netrun_combat_encounter/proc/spend(datum/actor, cost, deferred = FALSE, combat_activity = FALSE)
	if(closing || !IS_FINITE(cost) || cost < 1 || cost > NETRUN_COMBAT_AP || cost != round(cost))
		return FALSE
	if(expired_input())
		return FALSE
	if(!active)
		return TRUE
	var/datum/netrun_turn_participant/participant = member(actor)
	if(!participant || !has_turn(actor) || src.deferred || !IS_FINITE(cost) || cost < 1 || cost != round(cost) || participant.ap < cost)
		return FALSE
	participant.ap -= cost
	// Record only an accepted action, before the last AP may wrap the round.
	if(combat_activity)
		round_had_combat = TRUE
		quiet_rounds = 0
	src.deferred = deferred
	if(!deferred && participant.ap <= 0)
		advance()
	else
		changed()
	return TRUE

/datum/netrun_combat_encounter/proc/cooldown_remaining(datum/actor, datum/netrun_program/program)
	var/datum/netrun_turn_participant/participant = member(actor)
	return participant && program ? max(0, (participant.program_turn_cooldowns[program.id] || 0) - participant.own_turn) : 0

/datum/netrun_combat_encounter/proc/commit_program(datum/actor, datum/netrun_program/program, deferred = FALSE)
	if(!program || cooldown_remaining(actor, program))
		return FALSE
	var/datum/netrun_turn_participant/participant = member(actor)
	if(!spend(actor, program.ap_cost, deferred, program.hostile || program.targets_breach))
		return FALSE
	if(participant && !QDELETED(participant))
		participant.program_turn_cooldowns[program.id] = participant.own_turn + max(0, program.cooldown_turns)
	return TRUE

/datum/netrun_combat_encounter/proc/resolve(datum/actor)
	if(!active || !has_turn(actor) || !deferred || closing)
		return
	deferred = FALSE
	if(current()?.ap <= 0)
		advance()
	else
		changed()
		wake_current()

/datum/netrun_combat_encounter/proc/pass(datum/actor)
	if(expired_input())
		return FALSE
	if(!active || !has_turn(actor) || deferred)
		return FALSE
	advance()
	return TRUE

/datum/netrun_combat_encounter/proc/advance()
	if(closing || advancing)
		return
	advancing = TRUE
	deferred = FALSE
	var/datum/netrun_turn_participant/outgoing = current()
	if(outgoing?.real_turn)
		outgoing.stun_immune = FALSE
	// At most two local queue rotations can be consumed by stun in one dispatch.
	for(var/attempt in 1 to max(1, length(participants) * 2))
		if(length(participants) <= 1)
			advancing = FALSE
			qdel(src)
			return
		current_index++
		if(current_index > length(participants))
			current_index = 1
			quiet_rounds = round_had_combat ? 0 : quiet_rounds + 1
			round_had_combat = FALSE
			if(quiet_rounds >= NETRUN_COMBAT_IDLE_ROUNDS)
				advancing = FALSE
				qdel(src)
				return
			round++
		var/datum/netrun_turn_participant/participant = current()
		if(!participant.valid())
			remove(participant)
			if(QDELETED(src))
				return
			continue
		if(participant.begin_turn())
			break
	deadline = world.time + NETRUN_COMBAT_DECISION_TIME
	generation++
	arm_timer()
	advancing = FALSE
	for(var/datum/netrun_turn_participant/participant as anything in participants)
		var/datum/actor = participant.actor()
		if(istype(actor, /datum/netrun_ice))
			var/datum/netrun_ice/ice = actor
			if(participant != current())
				ice.reaction.clear_timer()
		else if(istype(actor, /datum/netrun_console))
			var/datum/netrun_console/console = actor
			var/mob/camera/netrun_entity/bot/bot = console.combat_self()
			if(istype(bot))
				bot.brain?.clear_timer()
	changed()
	var/datum/netrun_console/acting_console = current()?.actor()
	if(istype(acting_console) && !acting_console.autonomous())
		acting_console.push_notice("Ваш ход: [current().ap] ОД, [NETRUN_COMBAT_DECISION_TIME / (1 SECONDS)] секунд на решение.", topic = "combat")
	if(current()?.ap > 0)
		wake_current()

/datum/netrun_combat_encounter/proc/arm_timer()
	if(timer_id)
		deltimer(timer_id)
	timer_id = addtimer(CALLBACK(src, PROC_REF(on_timeout), generation), max(NETRUN_EXECUTION_MIN_INTERVAL, deadline - world.time), TIMER_STOPPABLE | TIMER_DELETE_ME)

/datum/netrun_combat_encounter/proc/on_timeout(expected_generation)
	if(expected_generation != generation || closing)
		return
	timer_id = null
	SSnetrun.get_task_scheduler().enqueue("combat_turn", src, NETRUN_TASK_CRITICAL, TRUE)

/datum/netrun_combat_encounter/proc/expire_turn()
	if(!active || closing || world.time < deadline)
		return
	var/datum/actor = current()?.actor()
	if(deferred && istype(actor, /datum/netrun_ice))
		// Clear the lock first: native cancellation may call resolve reentrantly.
		deferred = FALSE
		var/datum/netrun_ice/ice = actor
		ice.cancel_program()
	advance()

/datum/netrun_combat_encounter/proc/wake_current()
	var/datum/actor = current()?.actor()
	if(istype(actor, /datum/netrun_fortress))
		var/datum/netrun_fortress/fortress = actor
		fortress.clear_timer()
		fortress.wake()
	else if(istype(actor, /datum/netrun_ice))
		var/datum/netrun_ice/ice = actor
		ice.reaction.wake()
	else if(istype(actor, /datum/netrun_console))
		var/datum/netrun_console/console = actor
		var/mob/camera/netrun_entity/bot/bot = console.combat_self()
		if(istype(bot) && !bot.client)
			// Pace only the acting AI; otherwise two healing bots could consume
			// the whole worker repeatedly without a human decision deadline.
			bot.brain?.schedule(0.5 SECONDS)

/datum/netrun_combat_encounter/proc/changed()
	var/datum/component/netrun_node/node = node_ref?.resolve()
	if(!node)
		return
	SEND_SIGNAL(node, COMSIG_NETRUN_TURN_CHANGED, src)
	for(var/datum/netrun_turn_participant/participant as anything in participants)
		var/datum/netrun_console/console = participant.actor()
		if(istype(console))
			console.invalidate_ui()

/datum/netrun_combat_encounter/proc/apply_program_status(datum/netrun_program/program, datum/target)
	if(!can_apply_program_status(program, target))
		return
	if(program.apply_status(src, target))
		changed()

/datum/netrun_combat_encounter/proc/can_apply_program_status(datum/netrun_program/program, datum/target)
	return !program || program.can_apply_status(src, target)

/datum/netrun_combat_encounter/proc/payload(datum/netrun_console/viewer)
	if(!active || closing || !current())
		return null
	var/datum/netrun_turn_participant/participant = current()
	var/list/queue = list()
	for(var/datum/netrun_turn_participant/entry as anything in participants)
		queue += list(list("ref" = entry.visible_ref(), "name" = entry.display_name(), "current" = entry == participant,
			"ap" = entry.ap, "max_ap" = NETRUN_COMBAT_AP))
	var/participating = contains(viewer)
	return list("id" = decision_id(), "join_id" = join_id(), "round" = round, "actor_ref" = participant.visible_ref(), "actor_name" = participant.display_name(),
		"your_turn" = has_turn(viewer), "ap" = participant.ap, "max_ap" = NETRUN_COMBAT_AP,
		"remaining" = max(0, (deadline - world.time) / (1 SECONDS)), "decision_seconds" = NETRUN_COMBAT_DECISION_TIME / (1 SECONDS),
		"can_pass" = has_turn(viewer) && !deferred, "participants" = queue, "participating" = participating,
		"can_join" = !participating && !QDELETED(viewer) && !viewer.is_locked() && !viewer.get_combat_encounter())

/datum/netrun_task/combat_turn
	kind = "combat_turn"

/datum/netrun_task/combat_turn/execute(datum/controller/subsystem/netrun/worker, datum/netrun_execution_limits/limits)
	var/datum/netrun_combat_encounter/encounter = target()
	if(QDELETED(encounter))
		return FALSE
	encounter.expire_turn()
	return TRUE
