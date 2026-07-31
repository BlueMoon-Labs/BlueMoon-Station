// PORT: tgstation@14140a6355d1 code/datums/ai/basic_mobs/basic_subtrees/flee_target.dm
// + basic_ai_behaviors/run_away_from_target.dm (в одном файле - они неразделимы).

/// Try to escape from your current target, without performing any other actions.
/datum/ai_planning_subtree/flee_target
	/// Behaviour to execute in order to flee
	var/flee_behaviour = /datum/ai_behavior/run_away_from_target
	/// Blackboard key in which to store selected target
	var/target_key = BB_AI_CURRENT_TARGET
	/// Blackboard key in which to store selected target's hiding place
	var/hiding_place_key = BB_AI_TARGET_HIDING_LOCATION

/datum/ai_planning_subtree/flee_target/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/atom/flee_from = controller.blackboard[target_key]
	if(!should_flee(controller, flee_from))
		return
	var/flee_distance = controller.blackboard[BB_AI_FLEE_DISTANCE] || AI_DEFAULT_FLEE_DISTANCE
	if(get_dist(controller.pawn, flee_from) >= flee_distance)
		return

	controller.queue_behavior(flee_behaviour, target_key, hiding_place_key)
	return SUBTREE_RETURN_FINISH_PLANNING //we gotta get out of here.

/datum/ai_planning_subtree/flee_target/proc/should_flee(datum/ai_controller/controller, atom/flee_from)
	if(controller.blackboard[BB_AI_STOP_FLEEING] || QDELETED(flee_from))
		return FALSE
	return TRUE

/// Move to a position further away from your current target
/datum/ai_behavior/run_away_from_target
	required_distance = 0
	action_cooldown = 0
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_MOVE_AND_PERFORM | AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION
	/// How far do we try to run? Further makes for smoother running, but potentially weirder pathfinding
	var/run_distance = AI_DEFAULT_FLEE_DISTANCE
	/// Clear target if we finish the action unsuccessfully
	var/clear_failed_targets = TRUE

/datum/ai_behavior/run_away_from_target/setup(datum/ai_controller/controller, target_key, hiding_location_key)
	var/atom/target = controller.blackboard[hiding_location_key] || controller.blackboard[target_key]
	if(QDELETED(target))
		return FALSE
	run_distance = controller.blackboard[BB_AI_FLEE_DISTANCE] || initial(run_distance)
	if(!plot_path_away_from(controller, target))
		return FALSE
	return ..()

/datum/ai_behavior/run_away_from_target/perform(delta_time, datum/ai_controller/controller, target_key, hiding_location_key)
	if(controller.blackboard[BB_AI_STOP_FLEEING])
		return AI_BEHAVIOR_DELAY
	var/atom/target = controller.blackboard[hiding_location_key] || controller.blackboard[target_key]
	if(QDELETED(target) || !can_see(controller.pawn, target, run_distance))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED
	if(get_dist(controller.pawn, controller.current_movement_target) > required_distance)
		return AI_BEHAVIOR_DELAY // Still heading over
	if(plot_path_away_from(controller, target))
		return AI_BEHAVIOR_DELAY
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

///Выбрать турф подальше от угрозы: шесть смещённых углов, берём самый дальний
/datum/ai_behavior/run_away_from_target/proc/plot_path_away_from(datum/ai_controller/controller, atom/target)
	var/turf/target_destination = get_turf(controller.pawn)
	var/static/list/offset_angles = list(45, 90, 135, 180, 225, 270)
	for(var/angle in offset_angles)
		var/turf/test_turf = get_furthest_turf(controller.pawn, angle, target)
		if(isnull(test_turf))
			continue
		var/distance_from_target = get_dist(target, test_turf)
		if(distance_from_target <= get_dist(target, target_destination))
			continue
		target_destination = test_turf
		if(distance_from_target == run_distance) //we already got the max running distance
			break

	if(target_destination == get_turf(controller.pawn))
		return FALSE
	set_movement_target(controller, target_destination)
	return TRUE

/datum/ai_behavior/run_away_from_target/proc/get_furthest_turf(atom/source, angle, atom/target)
	var/turf/return_turf
	for(var/i in 1 to run_distance)
		var/turf/test_destination = get_ranged_target_turf_direct(source, target, range = i, offset = angle)
		if(!test_destination)
			break
		//двери не считаем тупиком: их можно открыть на бегу
		if(test_destination.is_blocked_turf(source_atom = source) && !(locate(/obj/machinery/door) in test_destination))
			break
		return_turf = test_destination
	return return_turf

/datum/ai_behavior/run_away_from_target/finish_action(datum/ai_controller/controller, succeeded, target_key, hiding_location_key)
	. = ..()
	if(clear_failed_targets)
		controller.clear_blackboard_key(target_key)

// ===== Goldgrub =====

///Голдграб: живая цель - это УГРОЗА, а не добыча. Легаси включал бегство
///прямо в GiveTarget (retreat_distance = 10) для любого живого таргета;
///здесь то же решение принимает сабтри - живая цель обрывает боевое
///планирование бегством, милишный план остаётся только руде. Бежим
///retreat-поведением: провал бегства (зажат) не должен стирать цель.
/datum/ai_planning_subtree/flee_target/goldgrub
	flee_behaviour = /datum/ai_behavior/run_away_from_target/retreat

/datum/ai_planning_subtree/flee_target/goldgrub/should_flee(datum/ai_controller/controller, atom/flee_from)
	if(!isliving(flee_from))
		return FALSE //руда и прочие wanted_objects - еда, не угроза
	return ..()

/datum/ai_planning_subtree/flee_target/goldgrub/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	if(. != SUBTREE_RETURN_FINISH_PLANNING)
		return
	//читаемый статус: бегство отражается состоянием RETREAT, чтобы FSM после
	//потери цели штатно вернул моба к мирной жизни
	if(controller.blackboard[BB_AI_STATE] != AI_STATE_RETREAT)
		controller.blackboard[BB_AI_STATE] = AI_STATE_RETREAT
		controller.blackboard[BB_AI_STATE_ENTERED_AT] = world.time

// ===== Escape-иллюзия =====

///Приманка: бежит от закреплённой GiveTarget-цели (владельца-кастера) и от
///любого перехваченного преследователя. Легаси включал бегство своим
///retreat_distance = 10 в MoveToTarget; здесь то же решает сабтри - цель
///есть и ближе кольца, значит бежим. Retreat-поведение: провал бегства
///(зажата в углу) не должен стирать закреплённую цель.
/datum/ai_planning_subtree/flee_target/illusion_decoy
	flee_behaviour = /datum/ai_behavior/run_away_from_target/retreat

/datum/ai_planning_subtree/flee_target/illusion_decoy/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	if(. != SUBTREE_RETURN_FINISH_PLANNING)
		return
	//читаемый статус: бегство приманки отражается состоянием RETREAT
	if(controller.blackboard[BB_AI_STATE] != AI_STATE_RETREAT)
		controller.blackboard[BB_AI_STATE] = AI_STATE_RETREAT
		controller.blackboard[BB_AI_STATE_ENTERED_AT] = world.time
