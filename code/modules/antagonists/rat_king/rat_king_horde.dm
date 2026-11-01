// Логика орды, режимы управления.

/datum/rat_horde
	/// RAT_HORDE_HARD или RAT_HORDE_SOFT.
	var/mode = RAT_HORDE_HARD
	var/mob/living/leader
	var/list/mob/living/minions = list()
	var/max_minions = RAT_HORDE_HARD_MAX
	var/order = RAT_ORDER_NONE
	var/atom/order_target
	var/turf/order_turf
	var/order_expires = 0
	var/order_timer

/datum/rat_horde/New(mob/living/new_leader, new_mode = RAT_HORDE_HARD)
	. = ..()
	if(!isliving(new_leader))
		return
	leader = new_leader
	mode = new_mode
	max_minions = (mode == RAT_HORDE_SOFT) ? RAT_HORDE_SOFT_MAX : RAT_HORDE_HARD_MAX
	RegisterSignal(leader, COMSIG_PARENT_QDELETING, PROC_REF(on_leader_deleted))

/datum/rat_horde/Destroy()
	deltimer(order_timer)
	order_timer = null
	release_all()
	if(leader)
		UnregisterSignal(leader, COMSIG_PARENT_QDELETING)
	leader = null
	return ..()

/datum/rat_horde/proc/on_leader_deleted(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/// Переносит орду на новое тело по требованию кролика.
/datum/rat_horde/proc/set_leader(mob/living/new_leader)
	if(QDELETED(src) || !isliving(new_leader) || new_leader == leader)
		return FALSE
	if(leader)
		UnregisterSignal(leader, COMSIG_PARENT_QDELETING)
	leader = new_leader
	RegisterSignal(leader, COMSIG_PARENT_QDELETING, PROC_REF(on_leader_deleted))
	return TRUE

/datum/rat_horde/proc/register_minion(mob/living/minion)
	if(QDELETED(src) || QDELETED(minion) || minion == leader)
		return FALSE
	if(!(minion in minions) && length(minions) >= max_minions)
		if(leader)
			to_chat(leader, span_warning("Орда уже слишком велика."))
		return FALSE
	if(mode == RAT_HORDE_SOFT)
		if(!istype(minion, /mob/living/simple_animal/mouse))
			return FALSE
	else if(!istype(minion, /mob/living/simple_animal/hostile) || !("rat" in minion.faction))
		return FALSE
	var/datum/component/rat_minion/existing = minion.GetComponent(/datum/component/rat_minion)
	if(existing)
		if(existing.horde == src)
			return TRUE
		existing.RemoveComponent()
	minions += minion
	if(!minion.AddComponent(/datum/component/rat_minion, src))
		minions -= minion
		return FALSE
	RegisterSignal(minion, COMSIG_PARENT_QDELETING, PROC_REF(on_minion_deleted))
	return TRUE

/datum/rat_horde/proc/unregister_minion(mob/living/minion)
	if(!minion)
		return FALSE
	minions -= minion
	UnregisterSignal(minion, COMSIG_PARENT_QDELETING)
	var/datum/component/rat_minion/component = minion.GetComponent(/datum/component/rat_minion)
	if(component)
		component.RemoveComponent()
	return TRUE

/datum/rat_horde/proc/on_minion_deleted(datum/source)
	SIGNAL_HANDLER
	minions -= source

/datum/rat_horde/proc/issue_order(new_order, atom/new_target, turf/new_turf, duration = RAT_HORDE_ORDER_DURATION)
	if(QDELETED(src) || !leader)
		return FALSE
	if(!is_order_allowed(new_order))
		return FALSE
	clear_order()
	order = new_order
	order_target = new_target
	order_turf = new_turf || (new_target ? get_turf(new_target) : get_turf(leader))
	order_expires = world.time + duration
	order_timer = addtimer(CALLBACK(src, PROC_REF(clear_order)), duration, TIMER_STOPPABLE)
	wake_minions()
	to_chat(leader, span_notice("Орда получила приказ: [get_order_label()]."))
	return TRUE

/datum/rat_horde/proc/has_active_order()
	return order != RAT_ORDER_NONE && world.time <= order_expires

/datum/rat_horde/proc/is_order_allowed(new_order)
	switch(new_order)
		if(RAT_ORDER_FOLLOW, RAT_ORDER_GATHER, RAT_ORDER_SCATTER)
			return TRUE
		if(RAT_ORDER_PLAY)
			return mode == RAT_HORDE_SOFT
		if(RAT_ORDER_ATTACK, RAT_ORDER_GUARD, RAT_ORDER_HOLD)
			return mode == RAT_HORDE_HARD
	return FALSE

/datum/rat_horde/proc/clear_order()
	deltimer(order_timer)
	order_timer = null
	order = RAT_ORDER_NONE
	order_target = null
	order_turf = null
	order_expires = 0
	sleep_minions()

/datum/rat_horde/proc/alert_betrayal(mob/living/traitor)
	if(!traitor)
		return
	if(mode == RAT_HORDE_HARD)
		issue_order(RAT_ORDER_ATTACK, traitor, get_turf(traitor), RAT_HORDE_ORDER_DURATION)
	else
		clear_order()

/datum/rat_horde/proc/release_all()
	for(var/mob/living/minion as anything in minions.Copy())
		unregister_minion(minion)
	minions.Cut()

/datum/rat_horde/proc/get_follow_turf(mob/living/minion)
	var/turf/leader_turf = get_turf(leader)
	if(!leader_turf || QDELETED(minion))
		return null
	var/datum/component/rat_minion/component = minion.GetComponent(/datum/component/rat_minion)
	if(!component)
		return leader_turf
	var/turf/destination = locate(leader_turf.x + component.follow_offset_x, leader_turf.y + component.follow_offset_y, leader_turf.z)
	if(!destination || destination.is_blocked_turf(exclude_mobs = TRUE, source_atom = minion))
		return leader_turf
	return destination

/datum/rat_horde/proc/get_order_label()
	switch(order)
		if(RAT_ORDER_FOLLOW)
			return "следовать за лидером"
		if(RAT_ORDER_GATHER)
			return "собраться в точке"
		if(RAT_ORDER_ATTACK)
			return "атаковать [order_target || "цель"]"
		if(RAT_ORDER_GUARD)
			return "охранять [order_turf || "точку"]"
		if(RAT_ORDER_HOLD)
			return "держать позицию"
		if(RAT_ORDER_SCATTER)
			return "разбежаться"
		if(RAT_ORDER_PLAY)
			return "играться с [order_target || "целью"]"
	return "ждать"


// Компонент миньонства.

/datum/component/rat_minion
	var/datum/rat_horde/horde
	var/old_stop_automated_movement = FALSE
	var/old_chew_probability = -1
	var/last_play = 0
	var/next_step = 0
	var/follow_offset_x = 0
	var/follow_offset_y = 0

/datum/component/rat_minion/Initialize(datum/rat_horde/new_horde)
	var/mob/living/simple_animal/minion = parent
	if(!istype(minion) || QDELETED(new_horde))
		return COMPONENT_INCOMPATIBLE
	horde = new_horde
	follow_offset_x = rand(-2, 2)
	follow_offset_y = rand(-2, 2)
	old_stop_automated_movement = minion.stop_automated_movement
	if(istype(minion, /mob/living/simple_animal/mouse))
		var/mob/living/simple_animal/mouse/mouse = minion
		if(!mouse.GetComponent(/datum/component/swarming))
			mouse.AddComponent(/datum/component/swarming)
		old_chew_probability = mouse.chew_probability
		mouse.chew_probability = 0
		mouse.stop_automated_movement = TRUE
		if(horde.has_active_order())
			START_PROCESSING(SSprocessing, src)
	RegisterSignal(parent, COMSIG_PARENT_QDELETING, PROC_REF(on_deleted))

/datum/component/rat_minion/proc/start_processing()
	if(istype(parent, /mob/living/simple_animal/mouse))
		next_step = 0
		START_PROCESSING(SSprocessing, src)

/datum/component/rat_minion/proc/stop_processing()
	STOP_PROCESSING(SSprocessing, src)

/datum/component/rat_minion/Destroy()
	STOP_PROCESSING(SSprocessing, src)
	var/mob/living/simple_animal/minion = parent
	if(minion)
		UnregisterSignal(minion, COMSIG_PARENT_QDELETING)
		if(!minion.has_buckled_mobs())
			minion.stop_automated_movement = old_stop_automated_movement
		if(istype(minion, /mob/living/simple_animal/mouse) && old_chew_probability >= 0)
			var/mob/living/simple_animal/mouse/mouse = minion
			mouse.chew_probability = old_chew_probability
	if(horde && !QDELETED(horde))
		if(minion)
			horde.minions -= minion
		horde = null
	return ..()

/datum/component/rat_minion/proc/on_deleted(datum/source)
	SIGNAL_HANDLER
	if(horde && !QDELETED(horde))
		horde.minions -= source

/datum/component/rat_minion/process(delta_time)
	if(QDELETED(src) || !horde || QDELETED(parent) || QDELETED(horde))
		return PROCESS_KILL
	var/mob/living/simple_animal/mouse/mouse = parent
	if(!istype(mouse))
		return PROCESS_KILL
	if(mouse.has_buckled_mobs())
		return
	if(!horde.has_active_order())
		return PROCESS_KILL
	if(world.time < next_step)
		return
	next_step = world.time + 1 SECONDS
	switch(horde.order)
		if(RAT_ORDER_FOLLOW)
			var/turf/follow_turf = horde.get_follow_turf(mouse)
			if(!follow_turf)
				return
			if(get_dist(mouse, follow_turf) > RAT_HORDE_GATHER_DISTANCE)
				step_towards(mouse, follow_turf)
		if(RAT_ORDER_GATHER)
			var/turf/order_turf = horde.order_turf
			if(!order_turf)
				return
			if(get_dist(mouse, order_turf) > RAT_HORDE_GATHER_DISTANCE)
				step_towards(mouse, order_turf)
		if(RAT_ORDER_SCATTER)
			var/mob/living/leader = horde.leader
			if(QDELETED(leader))
				return
			if(get_dist(mouse, leader) < 6)
				step_away(mouse, leader, 7)
		if(RAT_ORDER_PLAY)
			var/atom/play_target = horde.order_target
			if(QDELETED(play_target))
				return
			if(get_dist(mouse, play_target) > 2)
				step_towards(mouse, play_target)
			else if(world.time > last_play + 2 SECONDS)
				last_play = world.time
				if(prob(30))
					new /obj/effect/temp_visual/heart(get_turf(mouse))
					mouse.visible_message(span_notice("[mouse] ластится к [play_target]!"))

/// останавливаем обработку для инактивных миньонов
/datum/rat_horde/proc/wake_minions()
	for(var/mob/living/minion as anything in minions)
		var/datum/component/rat_minion/component = minion.GetComponent(/datum/component/rat_minion)
		if(component)
			component.start_processing()

/datum/rat_horde/proc/sleep_minions()
	for(var/mob/living/minion as anything in minions)
		var/datum/component/rat_minion/component = minion.GetComponent(/datum/component/rat_minion)
		if(component)
			component.stop_processing()

// АИ дерево приказов hard-орды.
/datum/ai_behavior/travel_towards/rat_order
	required_distance = RAT_HORDE_GATHER_DISTANCE
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION

/datum/ai_behavior/rat_hold
	action_cooldown = 0.5 SECONDS

/datum/ai_behavior/rat_hold/perform(delta_time, datum/ai_controller/controller)
	return AI_BEHAVIOR_DELAY

/datum/ai_behavior/rat_scatter
	action_cooldown = 1 SECONDS

/datum/ai_behavior/rat_scatter/perform(delta_time, datum/ai_controller/controller)
	var/mob/living/simple_animal/hostile/soldier = controller.pawn
	if(!istype(soldier))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	var/datum/component/rat_minion/minion = soldier.GetComponent(/datum/component/rat_minion)
	var/datum/rat_horde/horde = minion?.horde
	if(!horde || !horde.has_active_order() || horde.order != RAT_ORDER_SCATTER)
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	var/mob/living/leader = horde.leader
	if(QDELETED(leader))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	if(get_dist(soldier, leader) < RAT_HORDE_GUARD_LEASH)
		step_away(soldier, leader, 7)
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

/datum/ai_planning_subtree/rat_horde_orders

/datum/ai_planning_subtree/rat_horde_orders/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/mob/living/simple_animal/hostile/soldier = controller.pawn
	if(!istype(soldier))
		return
	var/datum/component/rat_minion/minion = soldier.GetComponent(/datum/component/rat_minion)
	if(!minion)
		return
	var/datum/rat_horde/horde = minion.horde
	if(!horde || QDELETED(horde) || horde.mode != RAT_HORDE_HARD)
		return
	if(horde.order == RAT_ORDER_NONE || world.time > horde.order_expires)
		return
	switch(horde.order)
		if(RAT_ORDER_FOLLOW)
			var/turf/follow_turf = horde.get_follow_turf(soldier)
			if(!follow_turf)
				return SUBTREE_RETURN_FINISH_PLANNING
			if(get_dist(soldier, follow_turf) > RAT_HORDE_GATHER_DISTANCE)
				controller.set_blackboard_key(BB_RAT_ORDER_TARGET, follow_turf)
				controller.queue_behavior(/datum/ai_behavior/travel_towards/rat_order, BB_RAT_ORDER_TARGET)
				return SUBTREE_RETURN_FINISH_PLANNING
			return
		if(RAT_ORDER_GATHER)
			var/turf/order_turf = horde.order_turf
			if(!order_turf || get_dist(soldier, order_turf) <= RAT_HORDE_GATHER_DISTANCE)
				return SUBTREE_RETURN_FINISH_PLANNING
			controller.set_blackboard_key(BB_RAT_ORDER_TARGET, order_turf)
			controller.queue_behavior(/datum/ai_behavior/travel_towards/rat_order, BB_RAT_ORDER_TARGET)
			return SUBTREE_RETURN_FINISH_PLANNING
		if(RAT_ORDER_ATTACK)
			var/atom/order_target = horde.order_target
			if(QDELETED(order_target) || !soldier.CanAttack(order_target))
				return
			controller.set_blackboard_key(BB_AI_CURRENT_TARGET, order_target)
			controller.queue_behavior(/datum/ai_behavior/hostile_melee_attack, BB_AI_CURRENT_TARGET)
			return SUBTREE_RETURN_FINISH_PLANNING
		if(RAT_ORDER_GUARD)
			var/atom/order_target = horde.order_target
			var/turf/guard_turf = horde.order_turf
			if(!QDELETED(order_target) && soldier.CanAttack(order_target) && get_dist(soldier, order_target) <= RAT_HORDE_GUARD_LEASH)
				controller.set_blackboard_key(BB_AI_CURRENT_TARGET, order_target)
				controller.queue_behavior(/datum/ai_behavior/hostile_melee_attack, BB_AI_CURRENT_TARGET)
				return SUBTREE_RETURN_FINISH_PLANNING
			if(guard_turf && get_dist(soldier, guard_turf) > RAT_HORDE_GATHER_DISTANCE)
				controller.set_blackboard_key(BB_RAT_ORDER_TARGET, guard_turf)
				controller.queue_behavior(/datum/ai_behavior/travel_towards/rat_order, BB_RAT_ORDER_TARGET)
				return SUBTREE_RETURN_FINISH_PLANNING
			return
		if(RAT_ORDER_HOLD)
			controller.queue_behavior(/datum/ai_behavior/rat_hold)
			return SUBTREE_RETURN_FINISH_PLANNING
		if(RAT_ORDER_SCATTER)
			controller.queue_behavior(/datum/ai_behavior/rat_scatter)
			return SUBTREE_RETURN_FINISH_PLANNING
