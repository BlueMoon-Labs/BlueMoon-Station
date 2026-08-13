// Событийная погоня/кормёжка слаймов вместо блокирующего while+sleep цикла
// AIprocess() (жил в life.dm).
//
// Разделение обязанностей: handle_targets() в Life ОСТАЁТСЯ мозгом приобретения
// цели, терпения, дисциплины и блуждания - контроллер только исполняет погоню.
// Источник истины по цели - сам слайм (Target): Life нуджит контроллер через
// slime_wake_pursuit(), а сабтри зеркалирует цель в blackboard и снимает план,
// когда мозг передумал.

/datum/ai_controller/slime
	ai_movement = /datum/ai_movement/basic_avoidance //исторический step_to погони
	planning_subtrees = list(/datum/ai_planning_subtree/slime_pursuit)

/datum/ai_controller/slime/TryPossessPawn(atom/new_pawn)
	if(!isslime(new_pawn))
		return AI_CONTROLLER_INCOMPATIBLE
	blackboard[BB_CURRENT_MIN_MOVE_DISTANCE] = SLIME_AI_FEED_RANGE
	sync_movement_delay(new_pawn)
	return ..()

///Каденс шага погони = легаси-циклу AIprocess: movement_delay() слайма + 2дс
///("это примерно так же быстро, как может идти слайм-игрок"). movement_delay()
///уже отдаёт децисекунды, конверсия из мировых тиков (AI_LEGACY_MOVE_DELAY_DS)
///здесь не нужна - легаси спал sleep(movement_delay() + 2) напрямую.
/datum/ai_controller/slime/proc/sync_movement_delay(mob/living/simple_animal/slime/slime_pawn)
	if(!istype(slime_pawn))
		return
	var/step_delay = slime_pawn.movement_delay()
	if(step_delay <= 0)
		step_delay = SLIME_AI_STEP_DELAY_FLOOR
	movement_delay = step_delay + SLIME_AI_STEP_DELAY_SLACK

///Погоня планируется только при живой цели от мозга Life; гейты исполнения
///повторяют выходы старого цикла - слайм стоит, но цель не бросает
/datum/ai_planning_subtree/slime_pursuit

/datum/ai_planning_subtree/slime_pursuit/SelectBehaviors(datum/ai_controller/controller, delta_time)
	var/datum/ai_controller/slime/slime_controller = controller
	var/mob/living/simple_animal/slime/slime_pawn = controller.pawn
	if(!istype(slime_controller) || !istype(slime_pawn))
		return
	var/mob/living/target = slime_pawn.Target
	if(QDELETED(target))
		controller.clear_blackboard_key(BB_SLIME_TARGET)
		return
	if(controller.blackboard[BB_SLIME_TARGET] != target)
		controller.set_blackboard_key(BB_SLIME_TARGET, target)
	//Гейты исполнения легаси-цикла: кормимся (buckled - ведёт handle_feeding в
	//Life), стан/стазис/клиент/обездвиженность - стоим на месте
	if(slime_pawn.stat || slime_pawn.client || slime_pawn.buckled)
		return
	if(!CHECK_MOBILITY(slime_pawn, MOBILITY_MOVE))
		return
	if(slime_pawn.SStun > world.time)
		return
	//Легаси-драйв входа в AIprocess: без голода, злости или бешенства слайм
	//цель не преследует (сытый слайм игнорирует даже команду "attack")
	if(!slime_pawn.attacked && !slime_pawn.rabid && !slime_pawn.get_hunger_drive())
		return
	slime_controller.sync_movement_delay(slime_pawn)
	controller.queue_behavior(/datum/ai_behavior/slime_pursue_and_feed, BB_SLIME_TARGET)
	return SUBTREE_RETURN_FINISH_PLANNING

///Догнать цель и вплотную повторить решающее дерево старого AIprocess:
///CanFeedon -> Feedon, иначе атака с кулдауном Atkcool
/datum/ai_behavior/slime_pursue_and_feed
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_MOVE_AND_PERFORM | AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION
	required_distance = SLIME_AI_FEED_RANGE

///Каденс решений = легаси-каденсу шага цикла (movement_delay() + 2дс)
/datum/ai_behavior/slime_pursue_and_feed/get_cooldown(datum/ai_controller/cooldown_for)
	return cooldown_for.movement_delay

/datum/ai_behavior/slime_pursue_and_feed/setup(datum/ai_controller/controller, target_key)
	. = ..()
	var/atom/target = controller.blackboard[target_key]
	if(QDELETED(target))
		return FALSE
	set_movement_target(controller, target)

/datum/ai_behavior/slime_pursue_and_feed/perform(delta_time, datum/ai_controller/controller, target_key)
	var/datum/ai_controller/slime/slime_controller = controller
	var/mob/living/simple_animal/slime/slime_pawn = controller.pawn
	var/mob/living/target = controller.blackboard[target_key]
	if(!istype(slime_controller) || !istype(slime_pawn) || QDELETED(target))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	if(slime_pawn.Target != target) //мозг Life передумал - план протух
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	slime_controller.sync_movement_delay(slime_pawn)

	//Правила отказа от цели 1:1 со старым AIprocess
	if(target.health <= SLIME_AI_TARGET_SPENT_HEALTH || target.stat == DEAD)
		return give_up(controller, slime_pawn, target_key)
	if(locate(/mob/living/simple_animal/slime) in target.buckled_mobs) //на цели уже висит другой слайм
		return give_up(controller, slime_pawn, target_key)

	if(target in view(SLIME_AI_FEED_RANGE, slime_pawn))
		return engage_adjacent(slime_pawn, target)

	if(target in view(SLIME_AI_PURSUIT_RANGE, slime_pawn))
		//ещё догоняем: мув-луп ведёт basic_avoidance, цель движения держим свежей
		if(controller.current_movement_target != target)
			set_movement_target(controller, target)
		return AI_BEHAVIOR_DELAY

	return give_up(controller, slime_pawn, target_key)

///Решающее дерево старого AIprocess вплотную к цели (ветки и вероятности 1:1)
/datum/ai_behavior/slime_pursue_and_feed/proc/engage_adjacent(mob/living/simple_animal/slime/slime_pawn, mob/living/target)
	if(!slime_pawn.CanFeedon(target)) //If they're not able to be fed upon, ignore them.
		slime_attack(slime_pawn, target)
		return AI_BEHAVIOR_DELAY
	if(!target.lying && prob(SLIME_AI_STANDING_CAUTION_PROB))
		if(target.client && target.health >= SLIME_AI_WARY_CLIENT_HEALTH)
			slime_attack(slime_pawn, target)
		else if(!slime_pawn.Atkcool && target.Adjacent(slime_pawn))
			INVOKE_ASYNC(slime_pawn, TYPE_PROC_REF(/mob/living/simple_animal/slime, Feedon), target)
	else if(!slime_pawn.Atkcool && target.Adjacent(slime_pawn))
		INVOKE_ASYNC(slime_pawn, TYPE_PROC_REF(/mob/living/simple_animal/slime, Feedon), target)
	return AI_BEHAVIOR_DELAY

///Легаси-атака цели: взвод Atkcool на 45дс существующим таймер-механизмом
/datum/ai_behavior/slime_pursue_and_feed/proc/slime_attack(mob/living/simple_animal/slime/slime_pawn, mob/living/target)
	if(slime_pawn.Atkcool)
		return
	slime_pawn.Atkcool = TRUE
	slime_pawn.atkcool_timer_id = addtimer(CALLBACK(slime_pawn, TYPE_PROC_REF(/mob/living/simple_animal/slime, reset_atkcool)), SLIME_AI_ATTACK_COOLDOWN, TIMER_STOPPABLE | TIMER_DELETE_ME)
	if(target.Adjacent(slime_pawn))
		//легаси звал из спящего асинхронного цикла; обработчики жертвы могут спать
		INVOKE_ASYNC(target, TYPE_PROC_REF(/atom, attack_slime), slime_pawn)

///Отказ от цели 1:1 с легаси: чистим и Target слайма, и blackboard; движение
///остановит finish_action по флагу FAILED
/datum/ai_behavior/slime_pursue_and_feed/proc/give_up(datum/ai_controller/controller, mob/living/simple_animal/slime/slime_pawn, target_key)
	slime_pawn.Target = null
	controller.clear_blackboard_key(target_key)
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
