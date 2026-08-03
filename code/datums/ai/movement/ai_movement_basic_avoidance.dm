///Uses Byond's basic obstacle avoidance mvovement
/datum/ai_movement/basic_avoidance
	max_pathing_attempts = 10
	///флаги создаваемого мув-лупа (см. MOVEMENT_LOOP_*)
	var/move_flags = NONE

///Задержка шага этого мув-лупа. Из неё же считается glide_size, поэтому
///подтипы с собственным тактом обязаны переопределять именно её.
/datum/ai_movement/basic_avoidance/proc/get_step_delay(datum/ai_controller/controller)
	return controller.movement_delay

/datum/ai_movement/basic_avoidance/start_moving_towards(datum/ai_controller/controller, atom/current_movement_target, min_distance)
	. = ..()
	var/atom/movable/moving = controller.pawn
	var/min_dist = controller.blackboard[BB_CURRENT_MIN_MOVE_DISTANCE]
	var/delay = get_step_delay(controller)
	var/datum/move_loop/loop = SSmove_manager.move_to(moving, current_movement_target, min_dist, delay, flags = move_flags, subsystem = SSai_movement, extra_info = controller)
	RegisterSignal(loop, COMSIG_MOVELOOP_PREPROCESS_CHECK, PROC_REF(pre_move))
	RegisterSignal(loop, COMSIG_MOVELOOP_POSTPROCESS, PROC_REF(post_move))

/datum/ai_movement/basic_avoidance/proc/pre_move(datum/move_loop/has_target/dist_bound/source)
	SIGNAL_HANDLER
	var/atom/movable/pawn = source.moving
	var/datum/ai_controller/controller = source.extra_info
	source.delay = get_step_delay(controller)
	source.distance = controller.blackboard[BB_CURRENT_MIN_MOVE_DISTANCE]

	var/can_move = TRUE
	if(controller.ai_traits & STOP_MOVING_WHEN_PULLED && pawn.pulledby)
		can_move = FALSE

	// Check if this controller can actually run, so we don't chase people with corpses
	if(!controller.able_to_run)
		controller.CancelActions()
		qdel(source) //stop moving
		return MOVELOOP_SKIP_STEP

	if(!isturf(pawn.loc)) //No moving if not on a turf
		can_move = FALSE

	var/turf/target_turf = get_step_to(pawn, source.target)

	if(!controller.can_enter_turf(target_turf))
		can_move = FALSE

	if(can_move)
		return
	increment_pathing_failures(controller)
	return MOVELOOP_SKIP_STEP

/datum/ai_movement/basic_avoidance/proc/post_move(datum/move_loop/source, succeeded)
	SIGNAL_HANDLER
	if(succeeded)
		return
	var/datum/ai_controller/controller = source.extra_info
	increment_pathing_failures(controller)

///Одиночный шаг (кайт/бекстеп): мгновенный старт, без смены направления взгляда.
///PORT: tgstation@14140a6355d1 /datum/ai_movement/basic_avoidance/backstep
/datum/ai_movement/basic_avoidance/backstep
	max_pathing_attempts = 4
	move_flags = MOVEMENT_LOOP_START_FAST | MOVEMENT_LOOP_NO_DIR_UPDATE

///Кайт-шаг планируется раз в AI_KITE_STEP_CADENCE, а глайд считался из
///задержки ПОГОНИ (обычно вдвое короче). Моб рывком проскакивал тайл и
///замирал до следующего шага: жалобы "вотчеры/легионы ходят по диагонали,
///не успеваешь понять, на какой они клетке". Тянем анимацию на весь такт -
///тайлов в секунду ровно столько же, но шаг читается сплошным скольжением.
/datum/ai_movement/basic_avoidance/backstep/get_step_delay(datum/ai_controller/controller)
	return max(..(), AI_KITE_STEP_CADENCE)
