// FSM hostile-профилей:
// IDLE -> ALERT -> ENGAGE -> SEARCH -> RETREAT/GUARD -> IDLE.
// Сабтри ставится в план ПОСЛЕ find_potential_targets и ПЕРЕД боевыми:
// бой планируют последующие сабтри (state = ENGAGE, планирование
// продолжается), а ALERT/SEARCH/RETREAT/GUARD ставят свои поведения и
// обрывают план. Поиск потерянной цели идёт к последней ПОДТВЕРЖДЁННОЙ
// точке БЕЗ волхака: живой атом при потере LOS разжалован в контакт ещё
// в find_potential_targets, и реакквизиция возможна только через его LOS-гейт.

/datum/ai_planning_subtree/hostile_fsm

///Сменить состояние с отметкой времени входа
/datum/ai_planning_subtree/hostile_fsm/proc/set_state(datum/ai_controller/controller, new_state)
	if(controller.blackboard[BB_AI_STATE] == new_state)
		return
	controller.blackboard[BB_AI_STATE] = new_state
	controller.blackboard[BB_AI_STATE_ENTERED_AT] = world.time

/datum/ai_planning_subtree/hostile_fsm/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/state = controller.blackboard[BB_AI_STATE] || AI_STATE_IDLE
	var/atom/target = controller.blackboard[BB_AI_CURRENT_TARGET]

	//есть цель - бой; сам бой планируют сабтри дальше по списку
	if(!QDELETED(target))
		var/turf/home_turf = controller.blackboard[BB_AI_HOME_TURF]
		var/guard_leash = controller.blackboard[BB_AI_GUARD_LEASH] || 5
		if(home_turf && (target.z != home_turf.z || get_dist(target, home_turf) > guard_leash))
			controller.clear_engagement_memory()
			set_state(controller, AI_STATE_GUARD)
			if(get_dist(controller.pawn, home_turf) > 0)
				controller.queue_behavior(/datum/ai_behavior/travel_towards, BB_AI_HOME_TURF)
			return SUBTREE_RETURN_FINISH_PLANNING

		//отступление: мораль/здоровье с гистерезисом и разворотом при зажиме
		if(should_retreat(controller))
			if(plan_retreat(controller))
				return SUBTREE_RETURN_FINISH_PLANNING
			//зажат в угол: короткий запрет бегства, дерёмся
			set_state(controller, AI_STATE_ENGAGE)
			return

		//читаемая пауза обнаружения: моб замечает жертву прежде чем броситься
		if(state != AI_STATE_ENGAGE && state != AI_STATE_ALERT && should_alert_pause(controller, target, state))
			set_state(controller, AI_STATE_ALERT)
			controller.queue_behavior(/datum/ai_behavior/alert_reaction, BB_AI_CURRENT_TARGET)
			return SUBTREE_RETURN_FINISH_PLANNING
		if(state == AI_STATE_ALERT && world.time < (controller.blackboard[BB_AI_STATE_ENTERED_AT] || 0) + AI_ALERT_REACTION_TIME)
			controller.queue_behavior(/datum/ai_behavior/alert_reaction, BB_AI_CURRENT_TARGET)
			return SUBTREE_RETURN_FINISH_PLANNING

		set_state(controller, AI_STATE_ENGAGE)
		return

	switch(state)
		if(AI_STATE_ENGAGE) //цель только что потеряна (разжалована в контакт)
			var/turf/last_pos = controller.blackboard[BB_AI_LAST_KNOWN_POS]
			if(last_pos)
				enter_search(controller)
				return plan_search(controller)
			return_to_peace(controller)
			return

		if(AI_STATE_SEARCH)
			if(world.time < (controller.blackboard[BB_AI_SEARCH_UNTIL] || 0))
				return plan_search(controller)
			//не нашли - забываем и возвращаемся к мирной жизни
			controller.clear_engagement_memory()
			return_to_peace(controller)
			return

		if(AI_STATE_GUARD)
			var/turf/home_turf = controller.blackboard[BB_AI_HOME_TURF]
			if(home_turf && get_dist(controller.pawn, home_turf) > (controller.blackboard[BB_AI_GUARD_LEASH] || 5))
				controller.queue_behavior(/datum/ai_behavior/travel_towards, BB_AI_HOME_TURF)
				return SUBTREE_RETURN_FINISH_PLANNING
			return

		else //IDLE/ALERT/RETREAT без цели - к мирной жизни
			return_to_peace(controller)
			if(controller.blackboard[BB_AI_STATE] == AI_STATE_IDLE)
				return plan_patrol_return(controller)

///Вернуться к мирному состоянию: охрана дома либо покой
/datum/ai_planning_subtree/hostile_fsm/proc/return_to_peace(datum/ai_controller/controller)
	if(controller.blackboard[BB_AI_HOME_TURF])
		set_state(controller, AI_STATE_GUARD)
	else
		set_state(controller, AI_STATE_IDLE)

// ===== ALERT =====

///Пауза обнаружения уместна только на холодном контакте: нас ещё не бьют,
///мы не под огнём и не знали, что враг рядом (иначе - мгновенный ENGAGE)
/datum/ai_planning_subtree/hostile_fsm/proc/should_alert_pause(datum/ai_controller/controller, atom/target, state)
	if(state != AI_STATE_IDLE && state != AI_STATE_GUARD)
		return FALSE
	if(target == controller.blackboard[BB_AI_LAST_ATTACKER])
		return FALSE
	if(world.time < (controller.blackboard[BB_AI_UNDER_FIRE_UNTIL] || 0))
		return FALSE
	if(controller.has_fresh_contact())
		return FALSE
	return TRUE

// ===== RETREAT =====

///Нужно ли отступать: профильный порог здоровья с гистерезисом выхода
/datum/ai_planning_subtree/hostile_fsm/proc/should_retreat(datum/ai_controller/controller)
	var/retreat_frac = controller.blackboard[BB_AI_RETREAT_HEALTH_FRAC]
	if(!retreat_frac)
		return FALSE
	if(world.time < (controller.blackboard[BB_AI_RETREAT_BACKOFF_UNTIL] || 0))
		return FALSE
	var/mob/living/living_pawn = controller.pawn
	if(!isliving(living_pawn) || living_pawn.maxHealth <= 0)
		return FALSE
	var/health_frac = living_pawn.health / living_pawn.maxHealth
	//вошёл в RETREAT ниже порога - выходит только восстановившись с запасом
	if(controller.blackboard[BB_AI_STATE] == AI_STATE_RETREAT)
		return health_frac < min(1, retreat_frac + AI_RETREAT_RECOVER_MARGIN)
	return health_frac < retreat_frac

///Спланировать бегство. FALSE = моб зажат (не сдвинулся несколько планов
///подряд): взводится backoff, вызывающий переводит его в ENGAGE - драться.
/datum/ai_planning_subtree/hostile_fsm/proc/plan_retreat(datum/ai_controller/controller)
	var/turf/pawn_turf = get_turf(controller.pawn)
	if(controller.blackboard[BB_AI_STATE] == AI_STATE_RETREAT && controller.blackboard[BB_AI_RETREAT_LAST_POS] == pawn_turf)
		var/fails = (controller.blackboard[BB_AI_RETREAT_FAILS] || 0) + 1
		controller.blackboard[BB_AI_RETREAT_FAILS] = fails
		if(fails >= AI_RETREAT_CORNERED_FRUSTRATION)
			controller.blackboard[BB_AI_RETREAT_BACKOFF_UNTIL] = world.time + AI_RETREAT_BACKOFF_TIME
			controller.blackboard[BB_AI_RETREAT_FAILS] = 0
			controller.clear_blackboard_key(BB_AI_RETREAT_LAST_POS)
			return FALSE
	else
		controller.set_blackboard_key(BB_AI_RETREAT_LAST_POS, pawn_turf)
		controller.blackboard[BB_AI_RETREAT_FAILS] = 0
	set_state(controller, AI_STATE_RETREAT)
	controller.queue_behavior(/datum/ai_behavior/run_away_from_target/retreat, BB_AI_CURRENT_TARGET, BB_AI_TARGET_HIDING_LOCATION)
	return TRUE

// ===== SEARCH =====

///Вход в SEARCH: таймер, счётчик точек осмотра, окно поджидания для дальников
/datum/ai_planning_subtree/hostile_fsm/proc/enter_search(datum/ai_controller/controller)
	set_state(controller, AI_STATE_SEARCH)
	controller.blackboard[BB_AI_SEARCH_UNTIL] = world.time + (controller.blackboard[BB_AI_SEARCH_TIME] || AI_DEFAULT_SEARCH_TIME)
	controller.blackboard[BB_AI_SEARCH_POINTS_LEFT] = AI_SEARCH_INVESTIGATE_POINTS
	controller.clear_blackboard_key(BB_AI_SEARCH_POINT)
	var/mob/living/simple_animal/hostile/hostile_pawn = controller.pawn
	if(istype(hostile_pawn) && hostile_pawn.ranged)
		controller.blackboard[BB_AI_HOLD_UNTIL] = world.time + AI_RANGED_HOLD_TIME

///Спланировать текущий шаг SEARCH: дальник сначала держит прикрывающую позицию
///к последней точке, остальные идут к улике и осматривают 2-3 точки вокруг
/datum/ai_planning_subtree/hostile_fsm/proc/plan_search(datum/ai_controller/controller)
	var/turf/evidence = controller.blackboard[BB_AI_LAST_KNOWN_POS]
	if(!evidence)
		controller.clear_engagement_memory()
		return_to_peace(controller)
		return

	//поджидание: скрывшаяся цель часто выглядывает обратно - дальник занимает
	//огневую позицию с линией на последнюю точку вместо слепого сближения
	var/mob/living/simple_animal/hostile/hostile_pawn = controller.pawn
	if(istype(hostile_pawn) && hostile_pawn.ranged && world.time < (controller.blackboard[BB_AI_HOLD_UNTIL] || 0))
		var/list/threats = controller.get_nearby_threats()
		var/ideal_min = controller.blackboard[BB_AI_MIN_DISTANCE] || 0
		var/ideal_max = controller.blackboard[BB_AI_MAX_DISTANCE] || 0
		var/turf/hold_tile = controller.best_covering_tile(evidence, threats, ideal_min, ideal_max)
		if(hold_tile && hold_tile != get_turf(controller.pawn))
			controller.queue_behavior(/datum/ai_behavior/hold_covering_position, hold_tile)
		return SUBTREE_RETURN_FINISH_PLANNING

	//осмотр: дошли до точки - выбираем следующую вокруг улики, пока есть лимит
	var/turf/waypoint = controller.blackboard[BB_AI_SEARCH_POINT] || evidence
	var/turf/pawn_turf = get_turf(controller.pawn)
	if(pawn_turf && get_dist(pawn_turf, waypoint) <= 1)
		var/points_left = controller.blackboard[BB_AI_SEARCH_POINTS_LEFT]
		if(isnull(points_left))
			points_left = AI_SEARCH_INVESTIGATE_POINTS
		if(points_left <= 0)
			controller.clear_engagement_memory()
			return_to_peace(controller)
			return
		controller.blackboard[BB_AI_SEARCH_POINTS_LEFT] = points_left - 1
		var/turf/next_point = pick_investigation_point(controller, evidence)
		if(next_point)
			controller.set_blackboard_key(BB_AI_SEARCH_POINT, next_point)
		//некуда идти - стоим настороже, таймер SEARCH дотикает сам
		return SUBTREE_RETURN_FINISH_PLANNING

	var/waypoint_key = controller.blackboard[BB_AI_SEARCH_POINT] ? BB_AI_SEARCH_POINT : BB_AI_LAST_KNOWN_POS
	if(ai_get_blocked_path_turf(controller.pawn, waypoint))
		controller.queue_behavior(/datum/ai_behavior/attack_obstructions/search, waypoint_key)
	controller.queue_behavior(/datum/ai_behavior/travel_towards, waypoint_key)
	return SUBTREE_RETURN_FINISH_PLANNING

///Случайная проходимая точка осмотра вокруг улики
/datum/ai_planning_subtree/hostile_fsm/proc/pick_investigation_point(datum/ai_controller/controller, turf/evidence)
	for(var/try_count in 1 to 6)
		var/turf/candidate = locate(
			evidence.x + rand(-AI_SEARCH_WANDER_RADIUS, AI_SEARCH_WANDER_RADIUS),
			evidence.y + rand(-AI_SEARCH_WANDER_RADIUS, AI_SEARCH_WANDER_RADIUS),
			evidence.z)
		if(!candidate || candidate == evidence || !isopenturf(candidate))
			continue
		if(!controller.can_enter_turf(candidate) || candidate.is_blocked_turf(source_atom = controller.pawn))
			continue
		return candidate
	return null

// ===== Возврат мирного патруля =====

///Уведённый от якоря моб возвращается домой ШТАТНЫМ мувером (JPS, двери,
///задержки движения), а не сырым Move(). Недостижимый якорь после нескольких
///планов без прогресса переезжает на текущее место - дом не теряется навсегда.
/datum/ai_planning_subtree/hostile_fsm/proc/plan_patrol_return(datum/ai_controller/controller)
	var/turf/anchor = controller.blackboard[BB_AI_PATROL_ANCHOR]
	var/turf/pawn_turf = get_turf(controller.pawn)
	if(!anchor || !pawn_turf || anchor.z != pawn_turf.z)
		return
	if(get_dist(pawn_turf, anchor) <= AI_PATROL_LEASH)
		controller.blackboard[BB_AI_PATROL_RETURN_FAILS] = 0
		controller.clear_blackboard_key(BB_AI_PATROL_RETURN_FROM)
		return
	if(controller.blackboard[BB_AI_PATROL_RETURN_FROM] == pawn_turf)
		var/fails = (controller.blackboard[BB_AI_PATROL_RETURN_FAILS] || 0) + 1
		controller.blackboard[BB_AI_PATROL_RETURN_FAILS] = fails
		if(fails >= AI_PATROL_RETURN_GIVE_UP)
			controller.set_blackboard_key(BB_AI_PATROL_ANCHOR, pawn_turf)
			controller.blackboard[BB_AI_PATROL_RETURN_FAILS] = 0
			controller.clear_blackboard_key(BB_AI_PATROL_RETURN_FROM)
			return
	else
		controller.set_blackboard_key(BB_AI_PATROL_RETURN_FROM, pawn_turf)
		controller.blackboard[BB_AI_PATROL_RETURN_FAILS] = 0
	controller.queue_behavior(/datum/ai_behavior/travel_towards/patrol_return, BB_AI_PATROL_ANCHOR)
	return SUBTREE_RETURN_FINISH_PLANNING

// ===== Поведения FSM =====

///Читаемая реакция обнаружения: развернуться к цели, собраться перед атакой
/datum/ai_behavior/alert_reaction
	action_cooldown = 0.4 SECONDS
	behavior_flags = AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION

/datum/ai_behavior/alert_reaction/perform(delta_time, datum/ai_controller/controller, target_key)
	var/mob/living/living_pawn = controller.pawn
	var/atom/target = controller.blackboard[target_key]
	if(!isliving(living_pawn) || QDELETED(target))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	living_pawn.setDir(get_dir(living_pawn, target))
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

///Отступление FSM: провал бегства не должен стирать цель - решение о
///развороте принимает plan_retreat() по отсутствию прогресса
/datum/ai_behavior/run_away_from_target/retreat
	clear_failed_targets = FALSE
