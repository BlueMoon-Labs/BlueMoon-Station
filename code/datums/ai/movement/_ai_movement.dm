///This datum is an abstract class that can be overriden for different types of movement
/datum/ai_movement
	///Контроллер в движении -> weakref его цели (турф - как есть). Синглтон бессмертен: сильная ссылка держала
	///удалённую цель, пока контроллер не тронется снова. Сравнивать через is_moving_towards()
	var/list/moving_controllers = list()
	///How many times a given controller can fail on their route before they just give up
	var/max_pathing_attempts

//Override this to setup the moveloop you want to use
/datum/ai_movement/proc/start_moving_towards(datum/ai_controller/controller, atom/current_movement_target, min_distance)
	SHOULD_CALL_PARENT(TRUE)
	controller.pathing_attempts = 0
	controller.blackboard[BB_CURRENT_MIN_MOVE_DISTANCE] = min_distance
	//турф не удаляется, а weakref на нём остался бы до конца раунда
	moving_controllers[controller] = isturf(current_movement_target) ? current_movement_target : WEAKREF(current_movement_target)

///TRUE, если записанная погоня контроллера ведёт именно к этой цели
/datum/ai_movement/proc/is_moving_towards(datum/ai_controller/controller, atom/target)
	var/record = moving_controllers[controller]
	if(isnull(record) || isnull(target))
		return FALSE
	return record == target || record == target.weak_reference

/datum/ai_movement/proc/stop_moving_towards(datum/ai_controller/controller)
	controller.pathing_attempts = 0
	moving_controllers -= controller
	//Луп сносим по прямой ссылке: путь через pawn.move_packet рвётся, когда
	//харддел уже занулил pawn, и осиротевший луп жил бы на SSai_movement до ребута.
	//QDEL_NULL заодно синхронно чистит ссылку, даже если сигнал qdel не дошёл
	QDEL_NULL(controller.active_move_loop)
	SSmove_manager.stop_looping(controller.pawn, SSai_movement)

/datum/ai_movement/proc/increment_pathing_failures(datum/ai_controller/controller)
	AI_METRIC_INC(failed_moves)
	controller.note_move_failure()
	controller.pathing_attempts++
	if(controller.pathing_attempts >= max_pathing_attempts)
		controller.CancelActions()
		controller.on_pathing_attempts_exhausted()

///Hook for controller families which need to release an unreachable target.
/datum/ai_controller/proc/on_pathing_attempts_exhausted()
	return

