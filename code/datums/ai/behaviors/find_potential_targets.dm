// Поиск целей hostile AI через спатиал-грид.
// Архитектура по мотивам tgstation@14140a6355d1
// code/datums/ai/basic_mobs/basic_ai_behaviors/targeting.dm, но пул кандидатов
// берётся из канала AI_TARGETS грида + личных врагов + реестра
// GLOB.hostile_machines - НИКАКИХ hearers()/view()-сканов. Порядок фильтров:
// точная дистанция -> стратегия (дешёвая) -> скоринг -> LOS лидера. Если лидер
// скрыт, скорер выбирает следующего. Так толпа не вызывает can_see() для каждого
// пригодного кандидата, но цель за стеной всё ещё никогда не приобретается.

/datum/ai_behavior/find_potential_targets
	action_cooldown = 2 SECONDS
	behavior_flags = AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION
	///Дефолтный радиус поиска, если профиль не задал BB_AI_AGGRO_RANGE
	var/vision_range = 9

/datum/ai_behavior/find_potential_targets/perform(delta_time, datum/ai_controller/controller, target_key, targeting_strategy_key, hiding_location_key)
	var/mob/living/living_mob = controller.pawn
	var/datum/targeting_strategy/targeting_strategy = GET_TARGETING_STRATEGY(controller.blackboard[targeting_strategy_key])
	if(!targeting_strategy)
		CRASH("No targeting strategy was supplied in the blackboard for [controller.pawn]")

	var/aggro_range = targeting_strategy.get_aggro_range(living_mob, controller.blackboard[BB_AI_AGGRO_RANGE] || vision_range)

	var/atom/current_target = controller.blackboard[target_key]
	if(!current_target && world.time < (controller.blackboard[BB_AI_ROUTE_RETRY_AT] || 0))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	controller.blackboard[BB_AI_ROUTE_RETRY_AT] = null
	var/current_target_eligible = current_target && candidate_passes(living_mob, current_target, targeting_strategy, aggro_range, FALSE)
	//Скрывшаяся цель разжалуется в контакт после короткого грейса: продолжать
	//движение к реальной позиции атома за стеной дольше - GPS-волхак, но
	//МГНОВЕННЫЙ демоушен разрешал бесплатный пик-фарм из-за угла: выход на
	//полсекунды обнулял ENGAGE всей группы, и моб не успевал даже начать
	//выстрел (round-23.35.57). Грейс короче двух кадансов финдера, стрельба
	//всё равно гейтится собственным can_see, а движение к мигнувшей цели -
	//ровно то, что делает пик наказуемым. После грейса - контакт, SEARCH, и
	//живой атом возвращается в цели исключительно через собственный LOS ниже.
	if(current_target_eligible && !candidate_is_visible(living_mob, current_target, targeting_strategy, aggro_range))
		var/los_lost_at = controller.blackboard[BB_AI_LOS_LOST_AT]
		if(isnull(los_lost_at))
			controller.blackboard[BB_AI_LOS_LOST_AT] = world.time
			return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
		if(world.time - los_lost_at < AI_LOS_DEMOTE_GRACE)
			return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
		AI_TRACE(controller, "target", "потерял LOS: [current_target] разжалован в контакт")
		controller.demote_target_to_contact(target_key)
		current_target = null
		current_target_eligible = FALSE
	else if(current_target_eligible)
		controller.blackboard[BB_AI_LOS_LOST_AT] = null
	var/current_target_congested = current_target_eligible && target_has_active_mob_congestion(controller, current_target)
	//Видимую валидную цель не пересравниваем с альтернативами каждый план -
	//только по refresh-каденсу. Фрустрация или подтверждённая очередь из
	//мобов форсирует сравнение немедленно.
	if(current_target_eligible && !current_target_congested && !(controller.blackboard[BB_AI_FRUSTRATION] || 0) && world.time < (controller.blackboard[BB_AI_TARGET_REFRESH_AT] || 0))
		remember_target_position(controller, current_target)
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	var/current_target_valid = current_target_eligible //видимость уже подтверждена выше

	if(!current_target_valid && current_target)
		AI_TRACE(controller, "target", "цель [current_target] непригодна (дистанция/стратегия) - сброс")
		controller.clear_mob_congestion(current_target)
		controller.clear_blackboard_key(target_key)
		current_target = null
	if(!current_target && !isnull(controller.blackboard[hiding_location_key]))
		controller.clear_blackboard_key(hiding_location_key)

	//Congestion refresh is deliberately local: a packed queue must not turn
	//every third bump into another full aggro-range scan. Normal cadence keeps
	//using the profile's complete acquisition radius.
	var/target_scan_range = current_target_congested ? min(aggro_range, AI_MOB_CONGESTION_RETARGET_RANGE) : aggro_range
	//грубый пул: ячейки грида (возвращают больше радиуса - фильтруем точно ниже)
	var/list/potential_targets = SSspatial_grid.orthogonal_range_search(living_mob, SPATIAL_GRID_CONTENTS_TYPE_AI_TARGETS, target_scan_range)
	potential_targets -= living_mob
	if(current_target_valid)
		potential_targets |= current_target

	//AI_TARGETS содержит только живых. Личные враги нужны отдельно: например,
	//мегафауна с stat_attack = DEAD должна добить и удалить обидчика-труп.
	var/mob/living/simple_animal/hostile/hostile_mob = living_mob
	if(istype(hostile_mob) && length(hostile_mob.enemies))
		potential_targets |= hostile_mob.enemies

	//Редкие search_objects-мобы (watcher bait, gutlunch food и т.п.) по
	//легаси-семантике ищут и объекты. Дорогой локальный обзор остаётся строго
	//гейтнут этим флагом; обычные hostile используют только spatial grid.
	if(istype(hostile_mob) && hostile_mob.search_objects && length(hostile_mob.wanted_objects))
		potential_targets |= typecache_filter_list(oview(target_scan_range, hostile_mob.targets_from), hostile_mob.wanted_objects)

	//враждебные машины: сразу только текущий z-бакет вместо глобального скана
	var/turf/mob_turf = get_turf(living_mob)
	if(mob_turf && mob_turf.z <= length(GLOB.hostile_machines_by_zlevel))
		for(var/atom/hostile_machine as anything in GLOB.hostile_machines_by_zlevel[mob_turf.z])
			var/turf/machine_turf = get_turf(hostile_machine)
			if(!machine_turf)
				continue
			if(get_dist(living_mob, hostile_machine) > target_scan_range)
				continue
			potential_targets += hostile_machine

	if(!length(potential_targets))
		schedule_target_refresh(controller, controller.is_combat_alert())
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	//Свежепомеченная непробиваемой цель не участвует в выборе: реаквайр был бы
	//немедленно брошен should_abandon_pursuit, и моб мерцал "взял-бросил" каждые
	//полсекунды, стоя вплотную. Боссы (pursuit_leashed = FALSE) пометку игнорируют:
	//для них и выход из погони по непробиваемости не существует.
	var/datum/weakref/impervious_ref
	if(controller.pursuit_leashed && world.time < (controller.blackboard[BB_AI_TARGET_IMPERVIOUS_UNTIL] || 0))
		impervious_ref = controller.blackboard[BB_AI_TARGET_IMPERVIOUS_REF]
	var/atom/impervious_target = impervious_ref?.resolve()

	var/list/filtered_targets = list()
	for(var/atom/pot_target as anything in potential_targets)
		AI_METRIC_INC(candidates_examined)
		if(pot_target == impervious_target)
			continue
		if(!candidate_passes(living_mob, pot_target, targeting_strategy, aggro_range, FALSE))
			continue
		filtered_targets += pot_target

	if(!length(filtered_targets))
		schedule_target_refresh(controller, controller.is_combat_alert())
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	if(current_target_congested)
		var/list/local_alternatives = collect_open_local_alternatives(controller, filtered_targets, current_target)
		// One congestion marker buys one rescore. Sustained blocking can arm a
		// later one, but an empty crowd cannot make every target pass scan the grid.
		controller.clear_mob_congestion(current_target)
		if(length(local_alternatives))
			filtered_targets = local_alternatives

	var/datum/target_scorer/scorer = GET_TARGET_SCORER(controller.blackboard[BB_AI_TARGET_SCORER] || /datum/target_scorer)
	var/atom/target = select_visible_target(controller, scorer, filtered_targets, current_target, current_target_valid, living_mob, targeting_strategy, aggro_range)
	if(!target)
		schedule_target_refresh(controller, controller.is_combat_alert())
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	schedule_target_refresh(controller)
	if(target == current_target)
		remember_target_position(controller, current_target)
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	controller.set_blackboard_key(target_key, target)
	AI_METRIC_INC(targets_acquired)
	AI_TRACE(controller, "target", "взял [target] (дист [get_dist(living_mob, target)], радиус [aggro_range])")
	controller.blackboard[BB_AI_TARGET_ACQUIRED_AT] = world.time
	controller.blackboard[BB_AI_FRUSTRATION] = 0
	//новая цель - новый маршрут: осада прежней и отметка мигнувшего LOS протухли
	controller.blackboard[BB_AI_SIEGE_UNTIL] = null
	controller.blackboard[BB_AI_LOS_LOST_AT] = null
	//Точка отсчёта усталости погони: откуда моб пошёл за этой целью и когда в
	//последний раз был обмен уроном. Без них погоня не имела условия окончания
	//вовсе - прод 9887: watcher вёл игрока 118 секунд на 26 тайлов и добивал
	//лежачего, потому что LOS на открытой лаве не рвётся никогда.
	controller.blackboard[BB_AI_PURSUIT_ORIGIN] = get_turf(living_mob)
	controller.blackboard[BB_AI_LAST_EXCHANGE_AT] = world.time
	//захват собственным восприятием закрывает розыск по контакту
	controller.clear_blackboard_key(BB_AI_CONTACT_TARGET)
	controller.blackboard[BB_AI_CONTACT_SOURCE] = null
	remember_target_position(controller, target)

	if(!isnull(controller.blackboard[hiding_location_key]))
		controller.clear_blackboard_key(hiding_location_key)
	var/atom/potential_hiding_location = targeting_strategy.find_hidden_mobs(living_mob, target)
	if(potential_hiding_location) //If they're hiding inside of something, we need to know so we can go for that instead initially.
		controller.set_blackboard_key(hiding_location_key, potential_hiding_location)

	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

///The movement layer only arms congestion after repeated mob-only bumps. Check
///that the same first step is still occupied when the target finder runs; a
///moving ally which already cleared the lane must not cause a stale retarget.
/datum/ai_behavior/find_potential_targets/proc/target_has_active_mob_congestion(datum/ai_controller/controller, atom/current_target)
	if(controller.blackboard[BB_AI_CONGESTED_TARGET] != current_target \
		|| world.time >= (controller.blackboard[BB_AI_CONGESTED_UNTIL] || 0))
		controller.clear_mob_congestion(current_target)
		return FALSE
	var/turf/blocked_step = get_step_towards(controller.pawn, current_target)
	if(controller.is_mob_only_blocked_step(blocked_step))
		return TRUE
	controller.clear_mob_congestion(current_target)
	return FALSE

///Under a confirmed crowd block, prefer only nearby candidates which can be
///attacked now or approached by an unobstructed first step. This avoids both
///queueing behind allies and replacing one blocked long chase with another.
/datum/ai_behavior/find_potential_targets/proc/collect_open_local_alternatives(datum/ai_controller/controller, list/candidates, atom/current_target)
	var/list/local_alternatives = list()
	var/atom/movable/pawn = controller.pawn
	var/turf/pawn_turf = get_turf(pawn)
	for(var/atom/candidate as anything in candidates)
		if(candidate == current_target)
			continue
		var/candidate_distance = get_dist(pawn, candidate)
		if(candidate_distance > AI_MOB_CONGESTION_RETARGET_RANGE)
			continue
		if(candidate_distance <= 1)
			local_alternatives += candidate
			continue
		var/turf/next_step = get_step_towards(pawn, candidate)
		if(!next_step || !controller.can_enter_turf(next_step) || next_step.is_blocked_turf(source_atom = pawn))
			continue
		if(pawn_turf?.LinkBlockedWithAccess(next_step, pawn, controller.get_access(), FALSE))
			continue
		local_alternatives += candidate
	return local_alternatives

/// Pick the scored leader with one cheap pass; pay for a raycast on it alone.
/// Only when that leader is hidden does the pool get ranked once and walked in
/// preference order: a sequence of hidden leaders costs O(N log N) + K raycasts
/// instead of the old O(N^2) rescoring, while the common open-arena case keeps
/// the single-pass price. A hidden target still never wins, and the
/// already-validated current target reuses its LOS.
/datum/ai_behavior/find_potential_targets/proc/select_visible_target(datum/ai_controller/controller, datum/target_scorer/scorer, list/candidates, atom/current_target, current_target_valid, mob/living/living_mob, datum/targeting_strategy/targeting_strategy, aggro_range)
	if(targeting_strategy.ignores_sight(living_mob))
		return scorer.select(controller, candidates, current_target)

	var/atom/leader = scorer.select(controller, candidates, current_target)
	if(!leader)
		return null
	if(leader == current_target && current_target_valid)
		return leader
	if(candidate_is_visible(living_mob, leader, targeting_strategy, aggro_range))
		return leader

	for(var/atom/candidate as anything in scorer.rank(controller, candidates, current_target))
		if(candidate == leader)
			continue //лидер уже проверен и скрыт
		if(candidate == current_target && current_target_valid)
			return candidate
		if(candidate_is_visible(living_mob, candidate, targeting_strategy, aggro_range))
			return candidate
	return null

///Avoid synchronized LOS/scoring bursts from mobs created in the same tick.
/datum/ai_behavior/find_potential_targets/proc/schedule_target_refresh(datum/ai_controller/controller, target_is_remembered = FALSE)
	if(target_is_remembered)
		controller.blackboard[BB_AI_TARGET_REFRESH_AT] = world.time + AI_TARGET_LOST_REFRESH_COOLDOWN
		return
	controller.blackboard[BB_AI_TARGET_REFRESH_AT] = world.time + AI_TARGET_REFRESH_COOLDOWN + rand(0, AI_TARGET_REFRESH_JITTER)

///Полная проверка кандидата: дистанция -> стратегия -> LOS (последним, он дорогой)
/datum/ai_behavior/find_potential_targets/proc/candidate_passes(mob/living/living_mob, atom/candidate, datum/targeting_strategy/targeting_strategy, aggro_range, check_sight = TRUE)
	if(QDELETED(candidate))
		return FALSE
	//Пилот в закрытой технике недосягаем как прямая цель (Adjacent через не-турф
	//loc всегда FALSE - милишка стояла бы столбом), его представляет сам мех из
	//реестра машин. Грид, в отличие от легаси view(), потроха техники видит,
	//поэтому без гейта пилот выигрывал тай-брейк у меха на той же клетке (репорт:
	//"мобы не агрятся на игроков в мехе"). Ревалидация текущей цели идёт этим же
	//гейтом - севший в мех пилот разжалуется первым же кадансом финдера.
	if(ismob(candidate) && istype(candidate.loc, /obj/vehicle/sealed))
		return FALSE
	if(get_dist(living_mob, candidate) > aggro_range)
		return FALSE
	var/turf/candidate_turf = get_turf(candidate)
	if(!candidate_turf || candidate_turf.z != living_mob.z)
		return FALSE
	if(!targeting_strategy.can_attack(living_mob, candidate, aggro_range))
		return FALSE
	if(check_sight && !candidate_is_visible(living_mob, candidate, targeting_strategy, aggro_range))
		return FALSE
	return TRUE

/// LOS is kept separate from eligibility so the scorer can prune candidates
/// before paying for a raycast.
/datum/ai_behavior/find_potential_targets/proc/candidate_is_visible(mob/living/living_mob, atom/candidate, datum/targeting_strategy/targeting_strategy, aggro_range)
	if(targeting_strategy.ignores_sight(living_mob))
		return TRUE
	AI_METRIC_INC(los_checks)
	return can_see(living_mob, candidate, aggro_range)

///Обновить память о ПОДТВЕРЖДЁННОЙ позиции цели (зовётся только пока цель видима)
/datum/ai_behavior/find_potential_targets/proc/remember_target_position(datum/ai_controller/controller, atom/target)
	var/turf/target_turf = get_turf(target)
	if(!target_turf)
		return
	//направление последнего наблюдаемого движения: по нему SEARCH после потери
	//LOS заворачивает за угол, а не топчется на точке потери. Это не волхак -
	//направление взято из честных наблюдений, пока цель была видима
	var/turf/previous_turf = controller.blackboard[BB_AI_LAST_KNOWN_POS]
	if(previous_turf && previous_turf != target_turf && previous_turf.z == target_turf.z)
		controller.blackboard[BB_AI_LAST_KNOWN_DIR] = get_dir(previous_turf, target_turf)
	controller.set_blackboard_key(BB_AI_LAST_KNOWN_POS, target_turf)
	controller.blackboard[BB_AI_LAST_SEEN_TIME] = world.time

/datum/ai_behavior/find_potential_targets/finish_action(datum/ai_controller/controller, succeeded, target_key, targeting_strategy_key, hiding_location_key)
	. = ..()
	if(succeeded)
		//при перевыборе цели отменить хвост старого плана, чтобы поведение
		//пересобралось под новую цель
		controller.CancelActions()
		controller.modify_cooldown(src, world.time + get_cooldown(controller))
