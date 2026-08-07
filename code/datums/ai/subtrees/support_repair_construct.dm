// Artificer support role. The repair target is separate from the combat target:
// this avoids feeding a friendly construct through hostile FSM/aggro hooks.

/datum/ai_planning_subtree/support_repair_construct
	var/search_range = 9

/datum/ai_planning_subtree/support_repair_construct/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/mob/living/simple_animal/hostile/construct/builder/repairer = controller.pawn
	if(!istype(repairer) || !repairer.can_repair_constructs)
		return

	var/mob/living/simple_animal/hostile/construct/repair_target = controller.task_reservation?.target
	if(!is_valid_repair_target(repairer, repair_target))
		controller.release_ai_target_reservation()
		controller.clear_blackboard_key(BB_AI_SUPPORT_TARGET)
		repair_target = null

	if(!repair_target)
		var/range_limit = controller.blackboard[BB_AI_AGGRO_RANGE] || search_range
		var/best_distance = INFINITY
		for(var/mob/living/simple_animal/hostile/construct/candidate as anything in SSspatial_grid.orthogonal_range_search(repairer, SPATIAL_GRID_CONTENTS_TYPE_AI_TARGETS, range_limit))
			if(!is_valid_repair_target(repairer, candidate))
				continue
			var/candidate_distance = get_dist(repairer, candidate)
			if(candidate_distance > range_limit || candidate_distance >= best_distance)
				continue
			var/datum/ai_target_reservation/existing_reservation = GLOB.ai_target_reservations[candidate]
			if(existing_reservation && !existing_reservation.can_acquire(controller))
				continue
			repair_target = candidate
			best_distance = candidate_distance
		if(repair_target && !controller.reserve_ai_target(repair_target, 1))
			repair_target = null

	if(!repair_target)
		return
	controller.set_blackboard_key(BB_AI_SUPPORT_TARGET, repair_target)
	controller.queue_behavior(/datum/ai_behavior/support_repair_construct, BB_AI_SUPPORT_TARGET)
	return SUBTREE_RETURN_FINISH_PLANNING

/datum/ai_planning_subtree/support_repair_construct/proc/is_valid_repair_target(mob/living/simple_animal/hostile/construct/builder/repairer, mob/living/simple_animal/hostile/construct/candidate)
	if(QDELETED(candidate) || candidate == repairer || candidate.stat == DEAD)
		return FALSE
	if(candidate.health >= candidate.maxHealth)
		return FALSE
	return repairer.faction_check_mob(candidate)

/datum/ai_behavior/support_repair_construct
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_MOVE_AND_PERFORM
	required_distance = 1
	action_cooldown = CLICK_CD_MELEE

/datum/ai_behavior/support_repair_construct/setup(datum/ai_controller/controller, target_key)
	. = ..()
	var/atom/repair_target = controller.blackboard[target_key]
	if(QDELETED(repair_target))
		return FALSE
	set_movement_target(controller, repair_target)

/datum/ai_behavior/support_repair_construct/perform(delta_time, datum/ai_controller/controller, target_key)
	var/mob/living/simple_animal/hostile/construct/builder/repairer = controller.pawn
	var/mob/living/simple_animal/hostile/construct/repair_target = controller.blackboard[target_key]
	if(!istype(repairer) || QDELETED(repair_target) || repair_target.health >= repair_target.maxHealth || !repairer.faction_check_mob(repair_target))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	if(!repairer.Adjacent(repair_target))
		return AI_BEHAVIOR_INSTANT
	repair_target.attack_animal(repairer)
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

/datum/ai_behavior/support_repair_construct/finish_action(datum/ai_controller/controller, succeeded, target_key)
	. = ..()
	controller.clear_blackboard_key(target_key)
	controller.release_ai_target_reservation()
