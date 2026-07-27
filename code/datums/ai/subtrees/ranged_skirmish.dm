// PORT: tgstation@14140a6355d1 code/datums/ai/basic_mobs/basic_subtrees/ranged_skirmish.dm
// Адаптация BlueMoon: hostile-пауны стреляют своим OpenFire() (внутри сохранены
// точная трасса, friendly-fire, rapid/casing-логика и сабтиповые переопределения),
// не-hostile пауны используют RangedAttack.

/// Fire a ranged attack without interrupting movement.
/datum/ai_planning_subtree/ranged_skirmish
	/// Blackboard key holding target atom
	var/target_key = BB_AI_CURRENT_TARGET
	/// What AI behaviour do we actually run?
	var/attack_behavior = /datum/ai_behavior/ranged_skirmish
	/// If target is further away than this we don't fire
	var/max_range = AI_RANGED_MAX_FIRE_RANGE
	/// If target is closer than this we don't fire
	var/min_range = 2

/datum/ai_planning_subtree/ranged_skirmish/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/mob/living/simple_animal/hostile/hostile_pawn = controller.pawn
	if(istype(hostile_pawn) && !hostile_pawn.ranged)
		return
	if(!controller.blackboard_key_exists(target_key))
		return
	var/atom/target = controller.blackboard[target_key]
	var/distance = get_dist(controller.pawn, target)
	if(distance > max_range || distance < min_range)
		return
	if(istype(hostile_pawn) && hostile_pawn.CheckRangedFireLane(target))
		controller.queue_behavior(/datum/ai_behavior/reposition_for_shot, target_key)
		return SUBTREE_RETURN_FINISH_PLANNING
	controller.queue_behavior(attack_behavior, target_key, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION, max_range, min_range)

/// How often will we try to perform our ranged attack?
/datum/ai_behavior/ranged_skirmish
	action_cooldown = 0.5 SECONDS
	behavior_flags = AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION

/datum/ai_behavior/ranged_skirmish/setup(datum/ai_controller/controller, target_key, targeting_strategy_key, hiding_location_key, max_range, min_range)
	. = ..()
	var/atom/target = controller.blackboard[hiding_location_key] || controller.blackboard[target_key]
	return !QDELETED(target)

/datum/ai_behavior/ranged_skirmish/perform(delta_time, datum/ai_controller/controller, target_key, targeting_strategy_key, hiding_location_key, max_range, min_range)
	var/atom/target = controller.blackboard[target_key]
	if(QDELETED(target))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	var/datum/targeting_strategy/targeting_strategy = GET_TARGETING_STRATEGY(controller.blackboard[targeting_strategy_key])
	if(targeting_strategy && !targeting_strategy.can_attack(controller.pawn, target))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	if(targeting_strategy)
		var/hiding_target = targeting_strategy.find_hidden_mobs(controller.pawn, target)
		controller.set_blackboard_key(hiding_location_key, hiding_target)
		target = hiding_target || target

	var/distance = get_dist(controller.pawn, target)
	if(distance > max_range || distance < min_range)
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	var/mob/living/simple_animal/hostile/hostile_pawn = controller.pawn
	//Do not pay for LOS while the weapon is cooling down. Once it can actually
	//fire, however, a cached target must still be visible at that exact moment.
	if(istype(hostile_pawn) && hostile_pawn.ranged_cooldown > world.time)
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	if(!can_fire_without_sight(controller, targeting_strategy))
		AI_METRIC_INC(los_checks)
		if(!can_see(controller.pawn, target, max_range))
			return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	if(!fire_at(controller, target))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

///Право стрелять вслепую - НЕ то же самое, что право преследовать вслепую.
///Легаси-MoveToTarget держал их раздельно: ветка environment_smash вела цель
///сквозь стену через Goto + FindHidden, а OpenFire в ней звался только под
///гейтом ranged_ignores_vision. Стратегия таргетирования отвечает за первое
///(ignore_sight выдаётся и смэшерам стен), поэтому гейт выстрела спрашивает
///самого моба. Иначе голиаф - SMASH_WALLS без ranged_ignores_vision - кладёт
///щупальца сквозь стену, а геометрический гейт линии огня его не ловит:
///способности без projectiletype он пропускает как CLEAR.
///Не-hostile пауны (порты basic-мобов) своего флага не имеют - им остаётся
///стратегия.
/datum/ai_behavior/ranged_skirmish/proc/can_fire_without_sight(datum/ai_controller/controller, datum/targeting_strategy/targeting_strategy)
	var/mob/living/simple_animal/hostile/hostile_pawn = controller.pawn
	if(istype(hostile_pawn))
		return hostile_pawn.ranged_ignores_vision
	return targeting_strategy?.ignores_sight(controller.pawn)

///Собственно выстрел; hostile-пауны сохраняют всю свою OpenFire-логику.
///Легаси-переопределения OpenFire свободно спят в телеграфах (иерофант:
///blink/cross-спам) - синхронный вызов подвешивал весь тикер поведений.
///NPC-пул всегда звал их через INVOKE_ASYNC; сохраняем тот же контракт.
/datum/ai_behavior/ranged_skirmish/proc/fire_at(datum/ai_controller/controller, atom/target)
	var/mob/living/simple_animal/hostile/hostile_pawn = controller.pawn
	if(istype(hostile_pawn))
		if(hostile_pawn.ranged_cooldown > world.time)
			return FALSE
		if(hostile_pawn.CheckRangedFireLane(target))
			return FALSE
		hostile_pawn.target = target
		INVOKE_ASYNC(hostile_pawn, TYPE_PROC_REF(/mob/living/simple_animal/hostile, OpenFire), target)
		return TRUE
	var/mob/living/living_pawn = controller.pawn
	INVOKE_ASYNC(living_pawn, TYPE_PROC_REF(/mob, RangedAttack), target)
	return TRUE

///Один дешёвый боковой шаг в позицию с чистой фактической траекторией.
/datum/ai_behavior/reposition_for_shot
	action_cooldown = 0.5 SECONDS

/datum/ai_behavior/reposition_for_shot/perform(delta_time, datum/ai_controller/controller, target_key)
	var/mob/living/simple_animal/hostile/shooter = controller.pawn
	var/atom/target = controller.blackboard[target_key]
	if(!istype(shooter) || QDELETED(target) || !shooter.can_ai_controller_move())
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	var/list/threats = controller.get_nearby_threats()
	var/ideal_min = controller.blackboard[BB_AI_MIN_DISTANCE] || 0
	var/ideal_max = controller.blackboard[BB_AI_MAX_DISTANCE] || 0
	//Лучший огневой тайл среди соседей И текущего: чистая линия огня, боевая
	//дистанция, дальше от угроз, под прикрытием стен. Текущий держится при
	//near-равенстве (анти-джиттер), поэтому в коридоре стрелок стоит, а не пляшет.
	var/turf/chosen = controller.best_reposition_tile(target, threats, want_lane = TRUE, ideal_min = ideal_min, ideal_max = ideal_max)
	if(isnull(chosen))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	//Текущий тайл уже лучший - держим позицию, не двигаемся.
	if(chosen == get_turf(shooter))
		controller.set_blackboard_key(BB_AI_SAFE_FIRE_POSITION, chosen)
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED
	if(!shooter.Move(chosen, get_dir(shooter, chosen)))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	controller.set_blackboard_key(BB_AI_SAFE_FIRE_POSITION, chosen)
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

///Занять прикрывающий тайл (движение до него) и ждать на нём.
///Планируется SEARCH-состоянием hostile_fsm: скрывшаяся цель часто выглядывает
///обратно, и дальник поджидает её с линией огня на последнюю точку.
/datum/ai_behavior/hold_covering_position
	required_distance = 0
	action_cooldown = 0.3 SECONDS
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION

/datum/ai_behavior/hold_covering_position/setup(datum/ai_controller/controller, turf/hold_tile)
	. = ..()
	if(!isturf(hold_tile))
		return FALSE
	set_movement_target(controller, hold_tile)
	return TRUE

/datum/ai_behavior/hold_covering_position/perform(delta_time, datum/ai_controller/controller, turf/hold_tile)
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED
