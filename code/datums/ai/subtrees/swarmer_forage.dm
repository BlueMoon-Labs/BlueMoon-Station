// AI-сварнеры лавалендского маяка на адаптер-контроллере.
// Боевой контур (диззаблеры/лазер/электрошок, вызов стаи через Aggro) -
// штатная машина через делегацию OpenFire/AttackingTarget; здесь их фирменный
// мирный цикл из легаси handle_automated_action (оба цепных переопределения):
// самопочинка -> репликация -> баррикада/ловушка -> поедание объектов
// (Integrate/DisIntegrate через легаси swarmer_act с обучаемыми typecache).
// Сценарные паузы StartAction/EndAction (toggle_ai) работают через мост
// легаси-статусов; лавовые катвоки и бросок из пропасти остаются в
// легаси-Move override пауна и требуют cross_dangerous_turfs у профилей.

///Стоимость репликации нового шелла (легаси-литерал CreateSwarmer)
#define SWARMER_AI_REPLICATE_COST 50
///Порог ресурсов, ниже которого постройки не рассматриваются (легаси resources > 5)
#define SWARMER_AI_STRUCTURE_RESERVE 5
///Порог самопочинки: чинимся ниже четверти здоровья (легаси maxHealth * 0.25)
#define SWARMER_AI_REPAIR_HEALTH_FRAC 0.25
///Легаси-вероятность построек за проход цикла (prob(5) на тик NPC-пула)
#define SWARMER_AI_STRUCTURE_PROB 5

// ===== Обёртки сценарных вербов =====
// StartAction (легаси-пауза) гасит контроллер через toggle_ai-мост и
// синхронно отменяет текущие действия, поэтому дёргается ТОЛЬКО из
// отложенного вызова (addtimer 0), а не изнутри perform. Вербы спят в
// do_mob - waitfor = FALSE отцепляет их от таймерного тикера.

/mob/living/simple_animal/hostile/swarmer/ai/proc/ai_self_repair()
	set waitfor = FALSE
	StartAction(10 SECONDS) //легаси StartAction(100) перед RepairSelf
	RepairSelf()

/mob/living/simple_animal/hostile/swarmer/ai/proc/ai_replicate()
	set waitfor = FALSE
	StartAction(10 SECONDS) //легаси StartAction(100): стоим смирно весь do_mob
	CreateSwarmer()

/mob/living/simple_animal/hostile/swarmer/ai/proc/ai_barricade()
	set waitfor = FALSE
	StartAction(1 SECONDS) //легаси StartAction(10) - "not a typo"
	CreateBarricade()

// ===== Сабтри =====

///Стрелковый сабтри только по живым целям: OpenFire ресурсника гейтит
///неживое - не тратим боевой план на "стрельбу" по стене, которую едим.
/datum/ai_planning_subtree/ranged_skirmish/living_only

/datum/ai_planning_subtree/ranged_skirmish/living_only/SelectBehaviors(datum/ai_controller/controller, delta_time)
	if(!isliving(controller.blackboard[target_key]))
		return
	return ..()

///Фуражирский цикл ресурсного сварнера. Гейт "нет живой угрозы": живой целью
///уже занялись боевые сабтри выше по списку, хозяйство подождёт. Приоритеты -
///как в легаси handle_automated_action: починка -> репликация -> постройки ->
///поиск еды; найденный объект-еда становится обычной целью контроллера, и её
///ест милишный делегат (AttackingTarget -> swarmer_act + обучение typecache).
/datum/ai_planning_subtree/swarmer_forage

/datum/ai_planning_subtree/swarmer_forage/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/mob/living/simple_animal/hostile/swarmer/ai/resource/forager = controller.pawn
	if(!istype(forager))
		return
	if(forager.stop_automated_movement) //сценарная пауза StartAction: уже заняты вербом
		return
	var/atom/current_target = controller.blackboard[BB_AI_CURRENT_TARGET]
	if(isliving(current_target)) //живая угроза важнее хозяйства
		return
	if(forager.health < forager.maxHealth * SWARMER_AI_REPAIR_HEALTH_FRAC)
		controller.queue_behavior(/datum/ai_behavior/swarmer_scenario_action/self_repair)
		return SUBTREE_RETURN_FINISH_PLANNING
	if(length(GLOB.AISwarmers) < GetTotalAISwarmerCap() && forager.resources >= SWARMER_AI_REPLICATE_COST)
		controller.queue_behavior(/datum/ai_behavior/swarmer_scenario_action/replicate)
		return SUBTREE_RETURN_FINISH_PLANNING
	if(forager.resources > SWARMER_AI_STRUCTURE_RESERVE)
		//легаси-вероятности за проход: редкие постройки, приоритет у репликации;
		//каденс планирования сопоставим с тиком NPC-пула, где жил prob(5)
		if(prob(SWARMER_AI_STRUCTURE_PROB))
			controller.queue_behavior(/datum/ai_behavior/swarmer_scenario_action/barricade)
			return SUBTREE_RETURN_FINISH_PLANNING
		if(prob(SWARMER_AI_STRUCTURE_PROB))
			controller.queue_behavior(/datum/ai_behavior/swarmer_lay_trap)
			return SUBTREE_RETURN_FINISH_PLANNING
	//объект-еда уже выбран - его доедает милишный делегат дальше по списку
	if(isnull(current_target))
		controller.queue_behavior(/datum/ai_behavior/swarmer_find_food, BB_AI_CURRENT_TARGET)

// ===== Поведения =====

///Общий каркас обёрток: отложенно запустить сценарный верб пауна.
///Сам верб ставит паузу StartAction и спит в do_mob уже вне тика поведений.
/datum/ai_behavior/swarmer_scenario_action
	action_cooldown = 2 SECONDS
	///Проки-обёртка на пауне, которую запускаем отложенно
	var/pawn_action_proc

/datum/ai_behavior/swarmer_scenario_action/perform(delta_time, datum/ai_controller/controller)
	var/mob/living/simple_animal/hostile/swarmer/ai/drone = controller.pawn
	if(!istype(drone))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	if(drone.stop_automated_movement) //верб уже идёт - не дублируем
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	//отложенный старт (паттерн curseblob): пауза StartAction синхронно отменяет
	//действия контроллера - дёргать её из собственного perform небезопасно
	addtimer(CALLBACK(drone, pawn_action_proc), 0)
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

///Самопочинка ниже четверти здоровья (легаси RepairSelf + StartAction(100))
/datum/ai_behavior/swarmer_scenario_action/self_repair
	pawn_action_proc = TYPE_PROC_REF(/mob/living/simple_animal/hostile/swarmer/ai, ai_self_repair)

///Репликация нового шелла при 50+ ресурсах под общий кап роя
/datum/ai_behavior/swarmer_scenario_action/replicate
	pawn_action_proc = TYPE_PROC_REF(/mob/living/simple_animal/hostile/swarmer/ai, ai_replicate)

///Баррикада (легаси CreateBarricade + StartAction(10))
/datum/ai_behavior/swarmer_scenario_action/barricade
	pawn_action_proc = TYPE_PROC_REF(/mob/living/simple_animal/hostile/swarmer/ai, ai_barricade)

///Ловушка: без паузы и без сна (легаси звал CreateTrap без StartAction)
/datum/ai_behavior/swarmer_lay_trap
	action_cooldown = 2 SECONDS

/datum/ai_behavior/swarmer_lay_trap/perform(delta_time, datum/ai_controller/controller)
	var/mob/living/simple_animal/hostile/swarmer/ai/drone = controller.pawn
	if(!istype(drone))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	drone.CreateTrap()
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

///Найти ближайший съедобный объект. Пригодность решает CanAttack ресурсника -
///обучаемые sharedWanted/sharedIgnore и спец-правила (грили/окна) работают
///через делегацию, как легаси FindTarget по ListTargets(search_objects).
/datum/ai_behavior/swarmer_find_food
	action_cooldown = 2 SECONDS

/datum/ai_behavior/swarmer_find_food/perform(delta_time, datum/ai_controller/controller, target_key)
	var/mob/living/simple_animal/hostile/swarmer/ai/resource/forager = controller.pawn
	if(!istype(forager))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	var/atom/best_food
	var/best_distance = INFINITY
	//легаси-радиус: ListTargets брал объекты из oview(vision_range)
	for(var/obj/candidate in oview(forager.vision_range, forager))
		if(!forager.CanAttack(candidate))
			continue
		var/candidate_distance = get_dist(forager, candidate)
		if(candidate_distance >= best_distance)
			continue
		best_food = candidate
		best_distance = candidate_distance
	if(isnull(best_food))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	controller.set_blackboard_key(target_key, best_food)
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

#undef SWARMER_AI_REPLICATE_COST
#undef SWARMER_AI_STRUCTURE_RESERVE
#undef SWARMER_AI_REPAIR_HEALTH_FRAC
#undef SWARMER_AI_STRUCTURE_PROB
