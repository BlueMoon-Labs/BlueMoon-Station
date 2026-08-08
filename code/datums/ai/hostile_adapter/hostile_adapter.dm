// Адаптер-контроллер hostile-мобов.
//
// Главный принцип: адаптер ПОДДЕРЖИВАЕТ легаси-состояние моба (pawn.target,
// Aggro/LoseAggro, in_melee), потому что ~90 переопределений AttackingTarget
// и ~40 OpenFire читают его. Исполнение ударов делегируется мобу
// (MeleeAction/OpenFire/enter_charge) - вся кастомщина сабтипов работает
// без изменений. Восприятие, память, скоринг и движение - новые.

/datum/ai_controller/hostile_adapter
	ai_movement = /datum/ai_movement/hybrid
	///Prevents a target change originating in a legacy proc from being mirrored back into that proc.
	var/syncing_target_from_legacy = FALSE
	///Prevents a controller target change from being written back to its own blackboard.
	var/syncing_target_to_pawn = FALSE

/datum/ai_controller/hostile_adapter/TryPossessPawn(atom/new_pawn)
	if(!istype(new_pawn, /mob/living/simple_animal/hostile))
		return AI_CONTROLLER_INCOMPATIBLE
	setup_from_pawn(new_pawn)
	RegisterSignal(new_pawn, COMSIG_AI_BLACKBOARD_KEY_SET(BB_AI_CURRENT_TARGET), PROC_REF(on_target_key_set))
	RegisterSignal(new_pawn, COMSIG_AI_BLACKBOARD_KEY_CLEARED(BB_AI_CURRENT_TARGET), PROC_REF(on_target_key_cleared))
	RegisterSignal(new_pawn, COMSIG_ATOM_BULLET_ACT, PROC_REF(on_pawn_shot))
	assign_idle_routine(new_pawn)
	return ..()

///A hostile must resist buckling even when its current plan does not require a
///movement step (for example, a ranged mob already inside its firing band).
///The movement pre-check remains a fallback for a buckle between planning ticks.
/datum/ai_controller/hostile_adapter/SelectBehaviors(delta_time)
	request_unbuckle()
	return ..()

///Живой idle: рутина выбирается по типу моба один раз при захвате пауна.
///Профили, задавшие своё фоновое поведение явно (майнбот, floor cluwne), не
///трогаются - там idle это часть сценария, а не декорация.
/datum/ai_controller/hostile_adapter/proc/assign_idle_routine(mob/living/simple_animal/hostile/hostile_pawn)
	if(idle_behavior?.type != /datum/idle_behavior/idle_random_walk/hostile_ambience)
		return
	var/routine_type = ai_idle_routine_for(hostile_pawn)
	if(!routine_type || routine_type == idle_behavior.type)
		return
	idle_behavior = new routine_type

/datum/ai_controller/hostile_adapter/UnpossessPawn(destroy)
	if(pawn)
		var/mob/living/simple_animal/hostile/hostile_pawn = pawn
		if(istype(hostile_pawn))
			hostile_pawn.ai_attack_tables_active = FALSE
		UnregisterSignal(pawn, list(COMSIG_AI_BLACKBOARD_KEY_SET(BB_AI_CURRENT_TARGET), COMSIG_AI_BLACKBOARD_KEY_CLEARED(BB_AI_CURRENT_TARGET), COMSIG_ATOM_BULLET_ACT))
	return ..()

///Считать легаси-переменные моба в блэкборд и настройки контроллера
/datum/ai_controller/hostile_adapter/proc/setup_from_pawn(mob/living/simple_animal/hostile/hostile_pawn)
	movement_delay = hostile_pawn.ai_movement_delay()
	blackboard[BB_AI_PACK_ROLE] = ai_pack_role
	var/detect_range = max(hostile_pawn.vision_range, hostile_pawn.aggro_vision_range)
	interesting_dist = max(detect_range, AI_DEFAULT_INTERESTING_DIST)
	max_target_distance = max(initial(max_target_distance), detect_range)
	// Sight distance drives pursuit range (above), NOT the pathfinding radius.
	// JPS/breach only need room for a local detour, so keep the search bounded to
	// the proven default: a far-sighted mob's target is bee-lined via the cheap
	// direct loop until it is within this range, where JPS takes over for obstacles.
	// Inflating this by vision made every open-terrain search (megafauna on
	// lavaland: aggro 40 -> radius 50) pathologically expensive.
	max_path_length = AI_MAX_PATH_LENGTH
	blackboard[BB_AI_AGGRO_RANGE] = detect_range

	//retaliate-семейство атакует только обидчиков (легаси-гейт ListTargets &= enemies);
	//смэшеры стен и стрелки-сквозь-стены ведут цель без прямой видимости
	if(istype(hostile_pawn, /mob/living/simple_animal/hostile/retaliate))
		blackboard[BB_AI_TARGETING_STRATEGY] = /datum/targeting_strategy/hostile_legacy/retaliate
	else if(hostile_pawn.ranged_ignores_vision || (hostile_pawn.environment_smash & (ENVIRONMENT_SMASH_WALLS|ENVIRONMENT_SMASH_RWALLS)))
		blackboard[BB_AI_TARGETING_STRATEGY] = /datum/targeting_strategy/hostile_legacy/ignore_sight
	else
		blackboard[BB_AI_TARGETING_STRATEGY] = /datum/targeting_strategy/hostile_legacy

	if(!hostile_pawn.environment_smash)
		blackboard[BB_AI_OBSTACLE_POLICY] = /datum/obstacle_policy/doors_only
	else
		blackboard[BB_AI_OBSTACLE_POLICY] = /datum/obstacle_policy

	//кайт-band рейнджера из легаси-переменных: retreat = ближе нельзя,
	//minimum_distance = докуда подходим
	if(hostile_pawn.ranged)
		if(!isnull(hostile_pawn.retreat_distance))
			blackboard[BB_AI_MIN_DISTANCE] = hostile_pawn.retreat_distance
			blackboard[BB_AI_MAX_DISTANCE] = max(hostile_pawn.minimum_distance, hostile_pawn.retreat_distance + 2)
		else
			blackboard[BB_AI_MIN_DISTANCE] = 0
			blackboard[BB_AI_MAX_DISTANCE] = max(hostile_pawn.minimum_distance, 1)
	else
		blackboard -= BB_AI_MIN_DISTANCE
		blackboard -= BB_AI_MAX_DISTANCE

	//падальщики предпочитают беспомощные цели
	if(hostile_pawn.stat_attack != CONSCIOUS)
		blackboard[BB_AI_TARGET_SCORER] = /datum/target_scorer/prefer_vulnerable

///Отдельный хук для фаз, которые легаси-Goto/MoveToTarget раньше удерживали на месте.
///FALSE не считается ошибкой пути: это штатная атака/трансформация, а не тупик.
/mob/living/simple_animal/hostile/proc/can_ai_controller_move()
	return TRUE

/mob/living/simple_animal/hostile/carp/can_ai_controller_move()
	return !istype(loc, /turf/open/space/transit)

/mob/living/simple_animal/hostile/megafauna/dragon/can_ai_controller_move()
	return !swooping

/mob/living/simple_animal/hostile/megafauna/bubblegum/can_ai_controller_move()
	return !charging

/mob/living/simple_animal/hostile/megafauna/legion/can_ai_controller_move()
	return !charging

/mob/living/simple_animal/hostile/megafauna/demonic_frost_miner/can_ai_controller_move()
	return !enraging

/mob/living/simple_animal/hostile/megafauna/hierophant/can_ai_controller_move()
	return !blinking

///Крыло-порыв: легаси-гейт Move() "не ходить во время спецатаки"
/mob/living/simple_animal/hostile/space_dragon/can_ai_controller_move()
	return !using_special

///Зеркалирование цели в легаси-переменную моба: сабтипы читают src.target
/datum/ai_controller/hostile_adapter/proc/on_target_key_set(mob/source)
	SIGNAL_HANDLER
	if(syncing_target_from_legacy)
		return
	var/mob/living/simple_animal/hostile/hostile_pawn = pawn
	if(!istype(hostile_pawn))
		return
	syncing_target_to_pawn = TRUE
	hostile_pawn.GiveTarget(blackboard[BB_AI_CURRENT_TARGET])
	syncing_target_to_pawn = FALSE

/datum/ai_controller/hostile_adapter/proc/on_target_key_cleared(mob/source)
	SIGNAL_HANDLER
	if(syncing_target_from_legacy)
		return
	var/mob/living/simple_animal/hostile/hostile_pawn = pawn
	if(!istype(hostile_pawn))
		return
	syncing_target_to_pawn = TRUE
	hostile_pawn.LoseTarget()
	syncing_target_to_pawn = FALSE

///Реактивный флаг: пауна реально обстреляли - включаем уворот, даже если тип
///оружия цели классификатором не распознан (сменилось/убрано в кобуру).
/datum/ai_controller/hostile_adapter/proc/on_pawn_shot(mob/source, obj/item/projectile/proj, def_zone)
	SIGNAL_HANDLER
	blackboard[BB_AI_UNDER_FIRE_UNTIL] = world.time + AI_UNDER_FIRE_DURATION

/// Base blackboard cleanup removes a qdeleting datum directly from its lists.
/// That path deliberately does not emit COMSIG_AI_BLACKBOARD_KEY_CLEARED, so a
/// hostile adapter must also release the mirrored legacy target and volley.
/datum/ai_controller/hostile_adapter/sig_remove_from_blackboard(datum/source)
	. = ..()
	var/mob/living/simple_animal/hostile/hostile_pawn = pawn
	if(!istype(hostile_pawn))
		return
	if(hostile_pawn.target == source)
		hostile_pawn.LoseTarget()
	else if(hostile_pawn.rapid_fire_target == source)
		hostile_pawn.cancel_rapid_fire_sequence()

/datum/ai_controller/hostile_adapter/get_able_to_run()
	. = ..()
	var/mob/living/simple_animal/hostile/hostile_pawn = pawn
	if(istype(hostile_pawn) && hostile_pawn.mob_transforming)
		return AI_UNABLE_TO_RUN

///Keep JPS door decisions consistent with the pawn's real Bump()/allowed()
///interaction. Simple animals may carry an ID or expose an access_card.
/datum/ai_controller/hostile_adapter/get_access()
	var/mob/living/simple_animal/hostile/hostile_pawn = pawn
	if(!istype(hostile_pawn))
		return
	return hostile_pawn.get_idcard()

// ===== Сабтри-обёртки =====

///Очередь поиска целей (behavior find_potential_targets)
/datum/ai_planning_subtree/find_hostile_targets

/datum/ai_planning_subtree/find_hostile_targets/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	controller.queue_behavior(/datum/ai_behavior/find_potential_targets, BB_AI_CURRENT_TARGET, BB_AI_TARGETING_STRATEGY, BB_AI_TARGET_HIDING_LOCATION)

///Милишная атака, когда цель есть
/datum/ai_planning_subtree/hostile_melee

/datum/ai_planning_subtree/hostile_melee/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	if(!controller.blackboard_key_exists(BB_AI_CURRENT_TARGET))
		return
	controller.queue_behavior(/datum/ai_behavior/hostile_melee_attack, BB_AI_CURRENT_TARGET)
	return SUBTREE_RETURN_FINISH_PLANNING

///Милишная атака только для мобов без дальнобойной.
///
///Нужна профилям, где выше по списку стоят ranged-сабтри: ranged_skirmish планирование НЕ
///обрывает (кроме ветки с перепозиционированием), поэтому обычный hostile_melee ниже заставил
///бы дальнобойного пауна после выстрела ещё и лезть в упор. Гейт зеркалит проверку из
///maintain_distance.
/datum/ai_planning_subtree/hostile_melee/melee_only

/datum/ai_planning_subtree/hostile_melee/melee_only/SelectBehaviors(datum/ai_controller/controller, delta_time)
	var/mob/living/simple_animal/hostile/hostile_pawn = controller.pawn
	if(istype(hostile_pawn) && hostile_pawn.ranged)
		return
	return ..()

///Неподвижная милишка (stationary_grappler): цель есть - бьём, но НЕ идём
/datum/ai_planning_subtree/hostile_melee_stationary

/datum/ai_planning_subtree/hostile_melee_stationary/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	if(!controller.blackboard_key_exists(BB_AI_CURRENT_TARGET))
		return
	controller.queue_behavior(/datum/ai_behavior/hostile_melee_attack/stationary, BB_AI_CURRENT_TARGET)
	return SUBTREE_RETURN_FINISH_PLANNING

///Чардж, если моб умеет и цель в band
/datum/ai_planning_subtree/hostile_charge

/datum/ai_planning_subtree/hostile_charge/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/mob/living/simple_animal/hostile/hostile_pawn = controller.pawn
	if(!istype(hostile_pawn) || !hostile_pawn.charger)
		return
	var/atom/target = controller.blackboard[BB_AI_CURRENT_TARGET]
	if(QDELETED(target))
		return
	var/target_distance = get_dist(hostile_pawn, target)
	if(target_distance <= hostile_pawn.minimum_distance || target_distance > hostile_pawn.charge_distance)
		return
	if(!COOLDOWN_FINISHED(hostile_pawn, charge_cooldown))
		return
	controller.queue_behavior(/datum/ai_behavior/hostile_charge, BB_AI_CURRENT_TARGET)

///Сайдстеп в ближнем бою для уклоняющихся мобов
/datum/ai_planning_subtree/hostile_dodge

/datum/ai_planning_subtree/hostile_dodge/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/mob/living/simple_animal/hostile/hostile_pawn = controller.pawn
	if(!istype(hostile_pawn) || !hostile_pawn.dodging || !hostile_pawn.in_melee)
		return
	if(!controller.blackboard_key_exists(BB_AI_CURRENT_TARGET))
		return
	controller.queue_behavior(/datum/ai_behavior/hostile_sidestep)

// ===== Боевые поведения =====

///Милишная атака через легаси-исполнение моба (MeleeAction: rapid_melee, vore и вся кастомщина)
/datum/ai_behavior/hostile_melee_attack
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_MOVE_AND_PERFORM | AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION
	required_distance = 1
	action_cooldown = CLICK_CD_MELEE

/datum/ai_behavior/hostile_melee_attack/get_cooldown(datum/ai_controller/cooldown_for)
	var/mob/living/simple_animal/hostile/hostile_pawn = cooldown_for.pawn
	if(!istype(hostile_pawn))
		return ..()
	//Компромиссный каденс: базой остаётся легаси-формула "rapid_melee ударов за
	//тик NPC-пула" (монотонная по rapid_melee, в отличие от плоского
	//CLICK_CD_MELEE, на котором bubblegum молотил в 2.5 раза быстрее задумки),
	//но темп задаётся ПРОФИЛЬНЫМ ai_melee_cadence_scale: чистые 2 секунды
	//ощущались дубово, а один глобальный множитель делал всех одинаковыми.
	return max(world.tick_lag, SSnpcpool.wait * hostile_pawn.ai_melee_cadence_scale / max(hostile_pawn.rapid_melee, 1))

/datum/ai_behavior/hostile_melee_attack/setup(datum/ai_controller/controller, target_key)
	. = ..()
	var/atom/target = controller.blackboard[target_key]
	if(QDELETED(target))
		return FALSE
	set_movement_target(controller, desired_movement_goal(controller, target))

///Цель движения: тайл подхода от tactical_approach (фланг/окружение), если он
///ведётся, иначе сама цель. Тайл лежит вплотную к цели, так что адъяценси-гейт
///атаки в perform() срабатывает как обычно.
///
///Тайл в пределах required_distance от пешки больше не ведёт: гейт прибытия
///мовера считает его достигнутым и не делает ни шага, а атака ещё не в
///адъяценси - моб замирал в двух клетках от жертвы до самого поводка погони
///(плейтест round-01.18.04: STALL дист 2, move_loop=нет). Дотянувшись до
///тайла, последний шаг ведём на саму цель.
/datum/ai_behavior/hostile_melee_attack/proc/desired_movement_goal(datum/ai_controller/controller, atom/target)
	var/turf/approach = controller.blackboard[BB_AI_APPROACH_TILE]
	if(isnull(approach) || QDELETED(approach))
		return target
	var/atom/movable/moving_pawn = controller.pawn
	if(isnull(moving_pawn) || get_dist(moving_pawn, approach) <= required_distance)
		return target
	return approach

/datum/ai_behavior/hostile_melee_attack/perform(delta_time, datum/ai_controller/controller, target_key)
	var/mob/living/simple_animal/hostile/hostile_pawn = controller.pawn
	var/atom/target = controller.blackboard[target_key]
	if(!istype(hostile_pawn) || QDELETED(target))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	var/datum/targeting_strategy/targeting_strategy = GET_TARGETING_STRATEGY(controller.blackboard[BB_AI_TARGETING_STRATEGY])
	if(targeting_strategy && !targeting_strategy.can_attack(hostile_pawn, target))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	hostile_pawn.target = target
	var/atom/attack_origin = hostile_pawn.targets_from || hostile_pawn
	if(target.Adjacent(attack_origin))
		hostile_pawn.in_melee = TRUE
		controller.note_combat_exchange()
		controller.note_melee_attempt(target)
		//MeleeAction -> AttackingTarget: сабтиповые переопределения (иерофант)
		//синхронно кастуют спящие способности - детачимся, как легаси NPC-пул
		INVOKE_ASYNC(hostile_pawn, TYPE_PROC_REF(/mob/living/simple_animal/hostile, MeleeAction), FALSE)
		return AI_BEHAVIOR_DELAY
	hostile_pawn.in_melee = FALSE
	//на подходе держим цель движения свежей: tactical_approach мог сменить
	//тайл подхода (окружение/фланг) или снять его
	var/atom/movement_goal = desired_movement_goal(controller, target)
	if(controller.current_movement_target != movement_goal)
		set_movement_target(controller, movement_goal)
	return AI_BEHAVIOR_INSTANT //ещё идём - без кулдауна

///Неподвижный вариант милишки: пауна НЕ двигаем вовсе (нет REQUIRE_MOVEMENT),
///каденс наследуем от родителя. Цель вне досягаемости - честный провал:
///жертва либо подойдёт сама, либо контроллер переждёт на месте.
/datum/ai_behavior/hostile_melee_attack/stationary
	behavior_flags = AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION

/datum/ai_behavior/hostile_melee_attack/stationary/setup(datum/ai_controller/controller, target_key)
	//без вызова родителя: тот назначает цель движения, а мы вкопаны
	var/atom/target = controller.blackboard[target_key]
	return !QDELETED(target)

/datum/ai_behavior/hostile_melee_attack/stationary/perform(delta_time, datum/ai_controller/controller, target_key)
	var/mob/living/simple_animal/hostile/hostile_pawn = controller.pawn
	var/atom/target = controller.blackboard[target_key]
	if(!istype(hostile_pawn) || QDELETED(target))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	var/datum/targeting_strategy/targeting_strategy = GET_TARGETING_STRATEGY(controller.blackboard[BB_AI_TARGETING_STRATEGY])
	if(targeting_strategy && !targeting_strategy.can_attack(hostile_pawn, target))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	hostile_pawn.target = target
	var/atom/attack_origin = hostile_pawn.targets_from || hostile_pawn
	if(!target.Adjacent(attack_origin))
		hostile_pawn.in_melee = FALSE
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	hostile_pawn.in_melee = TRUE
	//MeleeAction -> AttackingTarget: захват тентаклей и прочая кастомщина
	//сабтипов; детачимся от возможного сна, как обычная милишка
	INVOKE_ASYNC(hostile_pawn, TYPE_PROC_REF(/mob/living/simple_animal/hostile, MeleeAction), FALSE)
	return AI_BEHAVIOR_DELAY

///Разгон-чардж через легаси enter_charge (телеграф+бросок+станы как раньше)
/datum/ai_behavior/hostile_charge
	action_cooldown = 1 SECONDS

/datum/ai_behavior/hostile_charge/perform(delta_time, datum/ai_controller/controller, target_key)
	var/mob/living/simple_animal/hostile/hostile_pawn = controller.pawn
	var/atom/target = controller.blackboard[target_key]
	if(!istype(hostile_pawn) || QDELETED(target))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	hostile_pawn.target = target
	hostile_pawn.enter_charge(target)
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

///Сайдстеп: легаси-уворот в ближнем бою.
///
///Легаси гейтил уворот вероятностью dodge_prob раз в тик NPC-пула, то есть
///примерно 0.15 уворота в секунду. При переезде на контроллер гейт потеряли:
///поведение срабатывало безусловно каждые 0.5 с - в тринадцать раз чаще, и
///игроки читали это как "ниндзя, прыгающий сквозь тебя". Возвращаем оба
///ограничения: и каденс пула, и саму вероятность.
/datum/ai_behavior/hostile_sidestep
	action_cooldown = 0.5 SECONDS

/datum/ai_behavior/hostile_sidestep/get_cooldown(datum/ai_controller/cooldown_for)
	return max(world.tick_lag, SSnpcpool.wait)

/datum/ai_behavior/hostile_sidestep/perform(delta_time, datum/ai_controller/controller)
	var/mob/living/simple_animal/hostile/hostile_pawn = controller.pawn
	if(!istype(hostile_pawn))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	var/datum/ai_temperament/temperament = controller.get_temperament()
	if(!prob(hostile_pawn.dodge_prob * temperament.dodge_mult))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED
	hostile_pawn.sidestep()
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

// ===== Фоновое поведение =====

///Брождение + амбиент-речь легаси-моба возле игроков
///Мирный поводок: моб бродит вокруг якоря (точки первого покоя) - фауна
///патрулирует свою территорию, а не дрейфует рейдить базы гост-ролей.
///Возврат уведённого моба домой планирует hostile_fsm ШТАТНЫМ мувером
///(JPS, двери, задержки движения); здесь только якорная бухгалтерия и
///запрет брождения за поводком. Якорь переезжает ТОЛЬКО при явном скачке
///(телепорт/смена z, см. update_grid ниже) - выманивание территорию не крадёт.
/datum/idle_behavior/idle_random_walk/hostile_ambience

/datum/idle_behavior/idle_random_walk/hostile_ambience/perform_idle_behavior(delta_time, datum/ai_controller/controller)
	var/mob/living/simple_animal/living_pawn = controller.pawn
	if(istype(living_pawn) && living_pawn.stop_automated_movement)
		return
	var/turf/pawn_turf = get_turf(living_pawn)
	if(pawn_turf)
		var/turf/anchor = controller.blackboard[BB_AI_PATROL_ANCHOR]
		if(isnull(anchor) || anchor.z != pawn_turf.z)
			//первый покой на месте (или скачок на новый z) - это наш дом
			controller.set_blackboard_key(BB_AI_PATROL_ANCHOR, pawn_turf)
		else if(get_dist(pawn_turf, anchor) > AI_PATROL_LEASH)
			//за поводком не бродим: hostile_fsm уже ведёт нас домой
			if(istype(living_pawn) && SPT_PROB(2, delta_time))
				living_pawn.handle_automated_speech()
			return
	. = ..()
	if(istype(living_pawn) && SPT_PROB(2, delta_time))
		living_pawn.handle_automated_speech()

///Явный скачок пауна (телепорт мимо соседних тайлов) переставляет якорь: дом
///моба - там, куда его перенесли, а не точка, откуда его выманили пешком.
/datum/ai_controller/hostile_adapter/update_grid(datum/source, atom/old_loc)
	. = ..()
	if(isnull(blackboard[BB_AI_PATROL_ANCHOR]))
		return
	var/turf/old_turf = get_turf(old_loc)
	var/turf/new_turf = get_turf(pawn)
	if(!old_turf || !new_turf)
		return
	if(old_turf.z != new_turf.z || get_dist(old_turf, new_turf) > 2)
		clear_blackboard_key(BB_AI_PATROL_ANCHOR)
		blackboard[BB_AI_PATROL_RETURN_FAILS] = 0
		clear_blackboard_key(BB_AI_PATROL_RETURN_FROM)
