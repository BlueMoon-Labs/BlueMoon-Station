// PORT: tgstation@14140a6355d1 code/datums/ai/basic_mobs/basic_subtrees/maintain_distance.dm
// Кайт-band рейнджера: шаг назад при сближении, догоняем при отдалении.

/// Step away if too close, or towards if too far
/datum/ai_planning_subtree/maintain_distance
	/// Blackboard key holding atom we want to stay away from
	var/target_key = BB_AI_CURRENT_TARGET
	/// How far do we look for our target?
	var/view_distance = 10
	/// the run away behavior we will use
	var/run_away_behavior = /datum/ai_behavior/step_away
	///FALSE - кайтим и без легаси-флага ranged (кастеры вроде визарда: их
	///retreat_distance жил в MoveToTarget мимо ranged-ветки)
	var/require_ranged_pawn = TRUE

/datum/ai_planning_subtree/maintain_distance/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()

	var/mob/living/living_pawn = controller.pawn
	if(LAZYLEN(living_pawn.do_afters))
		return
	var/mob/living/simple_animal/hostile/hostile_pawn = living_pawn
	if(istype(hostile_pawn) && require_ranged_pawn && !hostile_pawn.ranged)
		return

	var/atom/target = controller.blackboard[target_key]
	if(!isliving(target) || !can_see(controller.pawn, target, view_distance))
		return
	var/range = get_dist(controller.pawn, target)

	var/minimum_distance = controller.blackboard[BB_AI_MIN_DISTANCE] || 4
	var/maximum_distance = controller.blackboard[BB_AI_MAX_DISTANCE] || 6

	if(range < minimum_distance)
		//длинная серия зажатых планов: очередной невозможный шаг не планируем -
		//прорываемся на дальний достижимый тайл (зажатый у стены стрелок стоял
		//столбом минутами, спамя "отход зажат" каждые полсекунды)
		if((controller.blackboard[BB_AI_KITE_PINNED_STREAK] || 0) >= AI_KITE_BREAK_AWAY_STREAK)
			controller.blackboard[BB_AI_KITE_PINNED_STREAK] = 0
			controller.queue_behavior(/datum/ai_behavior/ranged_break_away, target_key)
			return
		controller.queue_behavior(run_away_behavior, target_key, minimum_distance)
		return
	if(range > maximum_distance)
		controller.queue_behavior(/datum/ai_behavior/pursue_to_range, target_key, maximum_distance)
		return

///Кайт кастера: band задаёт профиль, легаси-флаг ranged не требуется
/datum/ai_planning_subtree/maintain_distance/spellcaster
	require_ranged_pawn = FALSE

/// Take one step away
/// Каденс 0.4с: на 0.2с вотчер скользил непопадаемым зигзагом ("его ни видно,
/// ни попасть") - кайт остаётся живым, но по читаемой траектории.
/datum/ai_behavior/step_away
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION
	required_distance = 0
	///Держится в паре с глайдом backstep-мувмента (см. AI_KITE_STEP_CADENCE)
	action_cooldown = AI_KITE_STEP_CADENCE

/datum/ai_behavior/step_away/setup(datum/ai_controller/controller, target_key)
	. = ..()
	var/atom/current_target = controller.blackboard[target_key]
	if(QDELETED(current_target))
		return FALSE

	var/mob/living/our_pawn = controller.pawn
	our_pawn.face_atom(current_target)

	//отходим от всей группы угроз, а не только от текущей цели: иначе кайт
	//одного врага заводит прямо на второго фланкера.
	var/list/threats = controller.get_nearby_threats()
	var/turf/next_step
	if(length(threats))
		//вердикт best_retreat_tile окончателен: null = зажаты, и тогда setup
		//обязан провалиться, чтобы hostile_break_away дрался в упор. Фоллбэк
		//get_step_away здесь запрещён - он ОБХОДИТ препятствия и у стены
		//возвращает равноудалённый боковой тайл, воскрешая пляску на месте.
		//Серия провалов подряд - другое дело: явная эскалация разрешает
		//боковое скольжение вдоль стены (без разворота), см. best_retreat_tile.
		var/pinned_streak = controller.blackboard[BB_AI_KITE_PINNED_STREAK] || 0
		next_step = controller.best_retreat_tile(threats, pinned_streak >= AI_KITE_LATERAL_STREAK)
		if(isnull(next_step))
			controller.blackboard[BB_AI_KITE_PINNED_STREAK] = pinned_streak + 1
			AI_TRACE_THROTTLED(controller, "kite", "отход зажат: некуда шагнуть от [length(threats)] угроз")
			return FALSE
		controller.blackboard[BB_AI_KITE_PINNED_STREAK] = 0
	else
		//не-living цель (враждебная машина) не попадает в список угроз -
		//простой шаг прочь с проверкой проходимости
		next_step = get_step_away(controller.pawn, current_target)
		if(isnull(next_step) || !controller.can_enter_turf(next_step) || next_step.is_blocked_turf(source_atom = our_pawn))
			return FALSE
	set_movement_target(controller, target = next_step, new_movement = /datum/ai_movement/basic_avoidance/backstep)
	return TRUE

/datum/ai_behavior/step_away/perform(delta_time, datum/ai_controller/controller)
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

/datum/ai_behavior/step_away/finish_action(datum/ai_controller/controller, succeeded)
	. = ..()
	controller.change_ai_movement_type(initial(controller.ai_movement))

/// Pursue a target until we are within a provided range
/datum/ai_behavior/pursue_to_range
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION | AI_BEHAVIOR_MOVE_AND_PERFORM

/datum/ai_behavior/pursue_to_range/setup(datum/ai_controller/controller, target_key, range)
	. = ..()
	var/atom/current_target = controller.blackboard[target_key]
	if(QDELETED(current_target))
		return FALSE
	if(get_dist(controller.pawn, current_target) <= range)
		return FALSE
	set_movement_target(controller, current_target)

/datum/ai_behavior/pursue_to_range/perform(delta_time, datum/ai_controller/controller, target_key, range)
	var/atom/current_target = controller.blackboard[target_key]
	if(!QDELETED(current_target) && get_dist(controller.pawn, current_target) > range)
		return AI_BEHAVIOR_INSTANT
	return AI_BEHAVIOR_INSTANT | AI_BEHAVIOR_SUCCEEDED

///Если стрелок уже зажат вплотную и реальный отход не запланировался,
///он защищается в мили вместо бесконечных попыток бежать на месте.
/datum/ai_planning_subtree/hostile_melee_when_cornered
	var/target_key = BB_AI_CURRENT_TARGET
	var/retreat_behavior = /datum/ai_behavior/step_away

/datum/ai_planning_subtree/hostile_melee_when_cornered/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/atom/target = controller.blackboard[target_key]
	if(QDELETED(target) || get_dist(controller.pawn, target) > 1)
		return

	//maintain_distance уже нашёл настоящий свободный тайл - не перебиваем отход
	var/datum/ai_behavior/retreat = GET_AI_BEHAVIOR(retreat_behavior)
	if(controller.planned_behaviors[retreat])
		return

	controller.queue_behavior(/datum/ai_behavior/hostile_melee_attack, target_key)
	return SUBTREE_RETURN_FINISH_PLANNING

///Смешанный семейный профиль: обычные сабтипы преследуют в мили, а ranged-
///сабтипы используют тот же список сабтри и переходят в мили только в тупике.
/datum/ai_planning_subtree/hostile_melee_when_cornered/adaptive/SelectBehaviors(datum/ai_controller/controller, delta_time)
	var/mob/living/simple_animal/hostile/hostile_pawn = controller.pawn
	if(istype(hostile_pawn) && !hostile_pawn.ranged)
		if(!controller.blackboard_key_exists(target_key))
			return
		controller.queue_behavior(/datum/ai_behavior/hostile_melee_attack, target_key)
		return SUBTREE_RETURN_FINISH_PLANNING
	return ..()

///Выстрел в упор по зажавшей вплотную цели (обход min_range), либо огрызок в мили
///как крайняя мера. Без движения - работает в паре с ranged_break_away.
/datum/ai_behavior/point_blank_shot
	action_cooldown = 0.4 SECONDS
	behavior_flags = AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION

///Темп задаёт легаси-каденс NPC-пула, как у hostile_melee_attack: без него
///мили-огрызок молотил каждые 0.4с ретрай-тика. Выстрелам не мешает - их
///реальный темп и так гейтит ranged_cooldown оружия.
/datum/ai_behavior/point_blank_shot/get_cooldown(datum/ai_controller/cooldown_for)
	var/mob/living/simple_animal/hostile/shooter = cooldown_for?.pawn
	if(!istype(shooter))
		return ..()
	return max(world.tick_lag, SSnpcpool.wait * shooter.ai_melee_cadence_scale / max(shooter.rapid_melee, 1))

/datum/ai_behavior/point_blank_shot/perform(delta_time, datum/ai_controller/controller, target_key)
	var/mob/living/simple_animal/hostile/shooter = controller.pawn
	var/atom/target = controller.blackboard[target_key]
	if(!istype(shooter) || QDELETED(target))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	//выстрел в упор по чистой линии: min_range здесь не применяется
	if(shooter.ranged && shooter.ranged_cooldown <= world.time && !shooter.CheckRangedFireLane(target))
		shooter.target = target
		//легаси-OpenFire может спать в телеграфах - не вешаем тикер поведений
		INVOKE_ASYNC(shooter, TYPE_PROC_REF(/mob/living/simple_animal/hostile, OpenFire), target)
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED
	//крайняя мера: некуда бежать и нечем стрелять - огрызаемся в мили
	if(get_dist(shooter, target) <= 1)
		shooter.target = target
		//сабтиповые AttackingTarget свободно спят в телеграфах - контракт NPC-пула
		INVOKE_ASYNC(shooter, TYPE_PROC_REF(/mob/living/simple_animal/hostile, AttackingTarget))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

///Прорыв из зажима: движется к самому дальнему достижимому тайлу от угроз
///(JPS уводит через двери/в обход). setup проваливается, если бежать совсем
///некуда - тогда работает только point_blank_shot.
/datum/ai_behavior/ranged_break_away
	required_distance = 0
	action_cooldown = 0.4 SECONDS
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_MOVE_AND_PERFORM | AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION

/datum/ai_behavior/ranged_break_away/setup(datum/ai_controller/controller, target_key)
	. = ..()
	var/atom/target = controller.blackboard[target_key]
	if(QDELETED(target))
		return FALSE
	var/turf/escape = controller.plot_break_away(controller.get_nearby_threats())
	if(isnull(escape))
		return FALSE
	set_movement_target(controller, escape)
	return TRUE

/datum/ai_behavior/ranged_break_away/perform(delta_time, datum/ai_controller/controller, target_key)
	var/atom/target = controller.blackboard[target_key]
	if(QDELETED(target))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	//пере-прокладка отхода: угрозы/цель могли сдвинуться
	var/turf/escape = controller.plot_break_away(controller.get_nearby_threats())
	if(isnull(escape))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED
	set_movement_target(controller, escape)
	return AI_BEHAVIOR_DELAY

///Зажатый вплотную дальник: если maintain_distance не нашёл реального отхода,
///рвётся из окружения (стрельба в упор + прорыв), а не встаёт в слабый мили.
/datum/ai_planning_subtree/hostile_break_away
	var/target_key = BB_AI_CURRENT_TARGET
	var/retreat_behavior = /datum/ai_behavior/step_away

/datum/ai_planning_subtree/hostile_break_away/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/atom/target = controller.blackboard[target_key]
	if(QDELETED(target) || get_dist(controller.pawn, target) > 1)
		return
	//реальный свободный отход уже запланирован maintain_distance - не перебиваем
	var/datum/ai_behavior/retreat = GET_AI_BEHAVIOR(retreat_behavior)
	if(controller.planned_behaviors[retreat])
		return
	//зажаты: гарантированно наносим урон в упор + пытаемся прорваться
	controller.queue_behavior(/datum/ai_behavior/point_blank_shot, target_key)
	controller.queue_behavior(/datum/ai_behavior/ranged_break_away, target_key)
	return SUBTREE_RETURN_FINISH_PLANNING

///Смешанный профиль: мили-сабтипы бьют в мили, ranged-сабтипы прорываются.
/datum/ai_planning_subtree/hostile_break_away/adaptive/SelectBehaviors(datum/ai_controller/controller, delta_time)
	var/mob/living/simple_animal/hostile/hostile_pawn = controller.pawn
	if(istype(hostile_pawn) && !hostile_pawn.ranged)
		var/atom/target = controller.blackboard[target_key]
		if(QDELETED(target) || get_dist(controller.pawn, target) > 1)
			return
		var/datum/ai_behavior/retreat = GET_AI_BEHAVIOR(retreat_behavior)
		if(controller.planned_behaviors[retreat])
			return
		controller.queue_behavior(/datum/ai_behavior/hostile_melee_attack, target_key)
		return SUBTREE_RETURN_FINISH_PLANNING
	return ..()
