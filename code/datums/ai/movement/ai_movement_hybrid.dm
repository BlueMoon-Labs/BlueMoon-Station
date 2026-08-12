// Гибридное движение hostile AI: в открытом пространстве -
// дешёвый прямой шаг (move_towards_legacy), после direct_fail_threshold
// неудачных шагов подряд или при обнаружении реальной преграды - JPS с кэшем
// пути и кулдауном перепрокладки controller.repath_delay. Дистанция сама по
// себе не требует поиска пути: длинный открытый коридор остаётся O(steps),
// а не запускает отдельный JPS для каждого моба. JPS-запросы бюджетируются
// существующим семафором SSpathfinder (10 слотов) и переносятся между fire
// самим move-лупом (repath_cooldown). Архитектура по мотивам связки
// dumb+jps из tg, реализация переключения наша.

/datum/ai_movement/hybrid
	max_pathing_attempts = 12
	///сколько неудачных шагов подряд терпит прямой режим до перехода на JPS
	var/direct_fail_threshold = 2

/datum/ai_movement/hybrid/start_moving_towards(datum/ai_controller/controller, atom/current_movement_target, min_distance)
	. = ..()
	controller.blackboard[BB_AI_DIRECT_FAILS] = 0
	start_direct_loop(controller, current_movement_target)

///Прямой bee-line луп
/datum/ai_movement/hybrid/proc/start_direct_loop(datum/ai_controller/controller, atom/current_movement_target)
	var/atom/movable/moving = controller.pawn
	var/datum/move_loop/loop = SSmove_manager.move_towards_legacy(moving, current_movement_target, controller.movement_delay, subsystem = SSai_movement, extra_info = controller)
	if(!loop)
		return
	RegisterSignal(loop, COMSIG_MOVELOOP_PREPROCESS_CHECK, PROC_REF(pre_move_direct))
	RegisterSignal(loop, COMSIG_MOVELOOP_POSTPROCESS, PROC_REF(post_move_direct))

///Умный JPS-луп с кэшем пути
/datum/ai_movement/hybrid/proc/start_jps_loop(datum/ai_controller/controller, atom/current_movement_target, turf/avoid)
	var/atom/movable/moving = controller.pawn
	var/datum/move_loop/loop = SSmove_manager.jps_move(moving,
		current_movement_target,
		controller.movement_delay,
		repath_delay = controller.repath_delay,
		max_path_length = controller.max_path_length,
		minimum_distance = controller.get_minimum_distance(),
		id = controller.get_access(),
		simulated_only = !controller.can_path_through_space(),
		avoid = avoid,
		skip_first = TRUE,
		subsystem = SSai_movement,
		extra_info = controller)
	if(!loop)
		return
	RegisterSignal(loop, COMSIG_MOVELOOP_PREPROCESS_CHECK, PROC_REF(pre_move_jps))
	RegisterSignal(loop, COMSIG_MOVELOOP_POSTPROCESS, PROC_REF(post_move_jps))
	RegisterSignal(loop, COMSIG_MOVELOOP_JPS_REPATH, PROC_REF(repath_incoming))

///Общие гейты шага; вернуть MOVELOOP_SKIP_STEP при запрете
/datum/ai_movement/hybrid/proc/shared_pre_move_checks(datum/move_loop/source)
	var/atom/movable/pawn = source.moving
	var/datum/ai_controller/controller = source.extra_info
	var/mob/living/simple_animal/hostile/hostile_pawn = pawn
	if(istype(hostile_pawn))
		//Some hostiles change their legacy movement delay at runtime for combat phases.
		controller.movement_delay = hostile_pawn.ai_movement_delay()
	source.set_delay(controller.movement_delay)

	if(!controller.able_to_run)
		controller.CancelActions()
		qdel(source) //stop moving
		return MOVELOOP_SKIP_STEP

	if(istype(hostile_pawn) && !hostile_pawn.can_ai_controller_move())
		return MOVELOOP_SKIP_STEP

	//Пристёгнутый моб при Move() толкает незаанкоренный стул вместо собственного
	//шага (living_movement.dm). Легаси-пул это знал (simple_animal.dm гейтит
	//брождение по !buckled), контроллеры при миграции гард потеряли - и мобы
	//поехали кататься. Единая точка: через этот прок проходят оба лупа.
	var/mob/living/living_pawn = pawn
	if(isliving(living_pawn) && living_pawn.buckled)
		controller.request_unbuckle()
		return MOVELOOP_SKIP_STEP

	var/can_move = TRUE
	if(controller.ai_traits & STOP_MOVING_WHEN_PULLED && pawn.pulledby)
		can_move = FALSE
	if(!isturf(pawn.loc)) //no moving if not on a turf
		can_move = FALSE
	if(can_move)
		return NONE
	increment_pathing_failures(controller)
	return MOVELOOP_SKIP_STEP

/datum/ai_movement/hybrid/proc/pre_move_direct(datum/move_loop/has_target/source)
	SIGNAL_HANDLER
	. = shared_pre_move_checks(source)
	if(. & MOVELOOP_SKIP_STEP)
		return
	var/datum/ai_controller/controller = source.extra_info
	var/turf/target_turf = get_step_towards(source.moving, source.target)
	if(!controller.can_enter_turf(target_turf))
		increment_pathing_failures(controller)
		return MOVELOOP_SKIP_STEP
	var/mob/living/simple_animal/simple_pawn = source.moving
	if(istype(simple_pawn) && simple_pawn.requires_safe_atmosphere())
		var/datum/obstacle_policy/policy = GET_OBSTACLE_POLICY(controller.blackboard[BB_AI_OBSTACLE_POLICY] || /datum/obstacle_policy)
		if(!policy.step_preserves_atmosphere(simple_pawn, get_turf(simple_pawn), target_turf))
			increment_pathing_failures(controller)
			return MOVELOOP_SKIP_STEP

	//Do not spend two visible bump attempts on a static wall or inaccessible
	//door. JPS first looks for a clean detour and only then asks the controller
	//for a policy-aware breach route.
	var/turf/current_turf = get_turf(source.moving)
	if(target_turf?.is_blocked_turf(exclude_mobs = TRUE, source_atom = source.moving) || current_turf?.LinkBlockedWithAccess(target_turf, source.moving, controller.get_access(), FALSE))
		//A wall-smasher breaks through the rock on its direct line instead of paying
		//for an expensive open-terrain JPS detour around it: attack_obstacle_in_path
		//clears the wall, so hold the cheap direct loop while it does. Only smashable
		//dense turf qualifies - structures, doors and static walls still route via JPS.
		if(target_turf?.density && controller.clears_obstacles_in_path() && step_smashes_through(controller, target_turf))
			return MOVELOOP_SKIP_STEP
		switch_to_jps(source, controller)
		return MOVELOOP_SKIP_STEP

///TRUE if the pawn's obstacle policy can break the dense turf directly ahead. Cheap
///(no pathfinding), evaluated only when the direct step is already blocked, so a
///wall-smasher keeps its cheap direct loop and lets the obstacle behavior smash through.
/datum/ai_movement/hybrid/proc/step_smashes_through(datum/ai_controller/controller, turf/blocked_turf)
	var/mob/living/simple_animal/simple_pawn = controller.pawn
	if(!istype(simple_pawn))
		return FALSE
	var/datum/obstacle_policy/policy = GET_OBSTACLE_POLICY(controller.blackboard[BB_AI_OBSTACLE_POLICY] || /datum/obstacle_policy)
	return policy.can_smash_turf(simple_pawn, blocked_turf)

/datum/ai_movement/hybrid/proc/pre_move_jps(datum/move_loop/has_target/jps/source)
	SIGNAL_HANDLER
	. = shared_pre_move_checks(source)
	if(. & MOVELOOP_SKIP_STEP)
		return
	//Временный моб-блокер уже ушёл: следующий репас снова может использовать тайл.
	if(source.avoid && !source.avoid.is_blocked_turf(source_atom = source.moving))
		source.avoid = null
		COOLDOWN_RESET(source, repath_cooldown)

/datum/ai_movement/hybrid/proc/post_move_direct(datum/move_loop/has_target/source, succeeded)
	SIGNAL_HANDLER
	var/datum/ai_controller/controller = source.extra_info
	if(succeeded)
		AI_METRIC_INC(successful_moves)
		controller.blackboard[BB_AI_DIRECT_FAILS] = 0
		controller.clear_mob_congestion(source.target)
		return

	var/turf/blocked_step = get_step_towards(source.moving, source.target)
	if(controller.is_mob_only_blocked_step(blocked_step))
		// A packed fight makes neighbouring mobs move between virtually every
		// tick. Treating that transient occupancy as an unreachable route both
		// launches an expensive JPS search around a stale position and grows
		// frustration, which in turn forces a full target rescan. Keep the cheap
		// direct loop alive and retry after its normal movement delay instead.
		AI_METRIC_INC(failed_moves)
		controller.blackboard[BB_AI_DIRECT_FAILS] = 0
		controller.note_mob_congestion(source.target)
		return

	controller.clear_mob_congestion_streak()
	increment_pathing_failures(controller)
	var/direct_fails = (controller.blackboard[BB_AI_DIRECT_FAILS] || 0) + 1
	controller.blackboard[BB_AI_DIRECT_FAILS] = direct_fails
	if(direct_fails >= direct_fail_threshold)
		switch_to_jps(source, controller)

/datum/ai_movement/hybrid/proc/post_move_jps(datum/move_loop/has_target/jps/source, succeeded)
	SIGNAL_HANDLER
	var/datum/ai_controller/controller = source.extra_info
	if(succeeded)
		AI_METRIC_INC(successful_moves)
		source.avoid = null
		controller.clear_mob_congestion(source.target)
		return
	var/turf/blocked_step = length(source.movement_path) ? source.movement_path[1] : null
	if(!controller.is_mob_only_blocked_step(blocked_step))
		controller.clear_mob_congestion_streak()
		increment_pathing_failures(controller)
		return
	AI_METRIC_INC(failed_moves)
	controller.note_mob_congestion(source.target)
	//атакуемого блокера (враг, перегородивший телом путь) НЕ обходим: держим
	//позицию, пусть attack_obstacle_in_path его пробьёт - иначе мобы бесплатно
	//обтекают body-block игрока. Обход остаётся для союзников/нейтралов.
	if(ai_step_blocker_attackable(source.moving, blocked_step))
		return
	//JPS не учитывает динамических мобов. Исключаем занятый тайл из следующего
	//маршрута вместо бесконечного пересчёта того же пути через блокера.
	source.avoid = blocked_step
	source.movement_path = null
	COOLDOWN_RESET(source, repath_cooldown)
	INVOKE_ASYNC(source, TYPE_PROC_REF(/datum/move_loop/has_target/jps, recalculate_path))

///Перед перепрокладкой обновить доступ и минимальную дистанцию из контроллера
/datum/ai_movement/hybrid/proc/repath_incoming(datum/move_loop/has_target/jps/source)
	SIGNAL_HANDLER
	var/datum/ai_controller/controller = source.extra_info
	source.id = controller.get_access()
	source.minimum_distance = controller.get_minimum_distance()
	source.simulated_only = !controller.can_path_through_space()

///Прямой режим упёрся: заменить луп на JPS, цель та же
/datum/ai_movement/hybrid/proc/switch_to_jps(datum/move_loop/has_target/old_loop, datum/ai_controller/controller, turf/avoid)
	var/atom/current_movement_target = old_loop.target
	controller.blackboard[BB_AI_DIRECT_FAILS] = 0
	qdel(old_loop)
	if(QDELETED(controller) || !controller.pawn || !current_movement_target)
		return
	start_jps_loop(controller, current_movement_target, avoid)
