// PORT: tgstation@14140a6355d1 code/datums/ai/basic_mobs/basic_subtrees/attack_obstacle_in_path.dm
// Апгрейд BlueMoon: если у пауна есть активный JPS-луп с кэшированным путём,
// проверяется и атакуется РЕАЛЬНЫЙ следующий турф маршрута, а не направляющая
// догадка get_step_towards (требование спеки: бить настоящую преграду пути).
// Исполнение удара - через obstacle policy (двери открываются, объекты
// ломаются по разрешениям профиля).

///Реальный заблокированный следующий турф маршрута к цели, либо null
/proc/ai_get_blocked_path_turf(mob/living/pawn, atom/target)
	var/turf/current_turf = get_turf(pawn)
	var/turf/next_step
	var/datum/move_loop/has_target/jps/jps_loop = SSmove_manager.processing_on(pawn, SSai_movement)
	if(istype(jps_loop) && length(jps_loop.movement_path))
		next_step = jps_loop.movement_path[1]
	else
		next_step = get_step_towards(pawn, target)
	if(current_turf && next_step && (next_step.is_blocked_turf(exclude_mobs = TRUE, source_atom = pawn) || current_turf.LinkBlockedWithAccess(next_step, pawn, pawn.get_idcard(), FALSE)))
		return next_step
	return null

/// If there's something between us and our target then we need to queue a behaviour to make it not be there
/datum/ai_planning_subtree/attack_obstacle_in_path
	/// Blackboard key containing current target
	var/target_key = BB_AI_CURRENT_TARGET
	/// The action to execute, extend to add a different cooldown or something
	var/attack_behaviour = /datum/ai_behavior/attack_obstructions

/datum/ai_planning_subtree/attack_obstacle_in_path/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/atom/target = controller.blackboard[target_key]
	if(QDELETED(target))
		return

	if(!ai_get_blocked_path_turf(controller.pawn, target))
		return

	controller.queue_behavior(attack_behaviour, target_key)
	// Don't cancel future planning, maybe we can move now

/// Something is in our way, get it outta here
/datum/ai_behavior/attack_obstructions
	action_cooldown = 2 SECONDS
	behavior_flags = AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION

///Separate behavior slot so a just-lost combat target cannot leave SEARCH
///executing the old BB_AI_CURRENT_TARGET arguments for another planning cycle.
/datum/ai_behavior/attack_obstructions/search

/datum/ai_behavior/attack_obstructions/perform(delta_time, datum/ai_controller/controller, target_key)
	var/mob/living/living_pawn = controller.pawn
	var/atom/target = controller.blackboard[target_key]

	if(QDELETED(target))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	var/turf/blocked_turf = ai_get_blocked_path_turf(living_pawn, target)
	if(!blocked_turf)
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED //путь чист - нам тут больше нечего делать
	if(!blocked_turf.Adjacent(living_pawn))
		return AI_BEHAVIOR_DELAY //ещё подходим к преграде - не считаем это неудачей

	var/datum/obstacle_policy/policy = GET_OBSTACLE_POLICY(controller.blackboard[BB_AI_OBSTACLE_POLICY] || /datum/obstacle_policy)

	var/dir_to_next_step = get_dir(living_pawn, blocked_turf)
	//диагональ разбираем на кардиналы: бьём то, что реально мешает
	var/list/dirs_to_clear = list()
	if(ISDIAGONALDIR(dir_to_next_step))
		for(var/direction in GLOB.cardinals)
			if(direction & dir_to_next_step)
				dirs_to_clear += direction
	else
		dirs_to_clear += dir_to_next_step

	for(var/direction in dirs_to_clear)
		if(clear_in_direction(controller, living_pawn, direction, policy))
			return AI_BEHAVIOR_DELAY

	//ничем не помочь - копим фрустрацию, пусть скорер/поиск целей решают
	controller.note_move_failure()
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

///Разобраться с преградой в направлении; TRUE = чем-то занялись
/datum/ai_behavior/attack_obstructions/proc/clear_in_direction(datum/ai_controller/controller, mob/living/living_pawn, direction, datum/obstacle_policy/policy)
	var/turf/current_turf = get_turf(living_pawn)
	var/turf/next_step = get_step(living_pawn, direction)
	if(!current_turf || !next_step)
		return FALSE
	if(!next_step.is_blocked_turf(exclude_mobs = TRUE, source_atom = living_pawn) && !current_turf.LinkBlockedWithAccess(next_step, living_pawn, controller.get_access(), FALSE))
		return FALSE
	return policy.try_step(living_pawn, controller, current_turf, next_step)
