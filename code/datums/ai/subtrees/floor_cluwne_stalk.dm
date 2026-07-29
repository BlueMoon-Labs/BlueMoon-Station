// Floor cluwne на адаптер-контроллере. Вся сценарная машина (фазы
// HAUNT/SPOOK/TORMENT/ATTACK, счётчик интереса, явление из пола, утаскивание
// Grab/Kill, самотелепорты и перевыбор жертвы) живёт в Life()/On_Stage() и
// НЕ трогается - паттерн curseblob: контроллер лишь заменяет легаси-петлю
// FindTarget/MoveToTarget/Goto преследованием закреплённой сценарием жертвы.
// Жертву назначают только Acquire_Victim()/Kill(), а не поиск целей.

///Стратегия закреплённой жертвы: пригодна только текущая жертва сценария.
///Зрение игнорируется - клувень чует жертву сквозь стены, как легаси-цикл
///(walk_to по атому без всяких LOS-проверок).
/datum/targeting_strategy/floor_cluwne_victim
	ignore_sight = TRUE

/datum/targeting_strategy/floor_cluwne_victim/can_attack(mob/living/living_mob, atom/target, vision_range)
	var/mob/living/simple_animal/hostile/floor_cluwne/creep = living_mob
	if(!istype(creep))
		return FALSE
	return !QDELETED(target) && target == creep.current_victim

///Легаси-гейт Goto: явленный клувень вкопан на месте (его сценарные do_after
///Grab/Kill не должны рваться шагами), а к жертве в недостижимой зоне пешком
///не ходят - Life() сам телепортирует и клувня, и стадии.
/mob/living/simple_animal/hostile/floor_cluwne/can_ai_controller_move()
	if(manifested)
		return FALSE
	if(QDELETED(current_victim) || !is_station_level(current_victim.z))
		return FALSE
	var/area/victim_area = get_area(current_victim)
	return !is_type_in_typecache(victim_area, invalid_area_typecache)

// ===== Сабтри =====

///Единственный сабтри профиля floor_cluwne: закрепление жертвы сценария в
///блэкборде + вечное преследование. Потерянную жертву переназначает сам
///сценарий (Life -> Acquire_Victim), контроллер не вмешивается.
/datum/ai_planning_subtree/floor_cluwne_stalk

/datum/ai_planning_subtree/floor_cluwne_stalk/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/mob/living/simple_animal/hostile/floor_cluwne/creep = controller.pawn
	if(!istype(creep))
		return
	if(QDELETED(creep.current_victim))
		//без жертвы не планируем: Life() либо найдёт новую, либо удалит пауна
		return SUBTREE_RETURN_FINISH_PLANNING
	//жертва закреплена сценарием и не может быть подменена планировщиком
	if(controller.blackboard[BB_AI_CURRENT_TARGET] != creep.current_victim)
		controller.set_blackboard_key(BB_AI_CURRENT_TARGET, creep.current_victim)
	controller.queue_behavior(/datum/ai_behavior/floor_cluwne_stalk, BB_AI_CURRENT_TARGET)
	return SUBTREE_RETURN_FINISH_PLANNING

// ===== Поведение =====

///Преследование жертвы с легаси-дистанцией зависания (minimum_distance = 2):
///клувень кружит около жертвы, не вставая на неё; каждый шаг дополнительно
///гейтится can_ai_controller_move() (явление/недоступная зона) - точный
///перенос ветвления легаси-Goto. Атаки нет вовсе: AttackingTarget клувня
///пуст, убийство ведёт сценарий Life()/On_Stage().
/datum/ai_behavior/floor_cluwne_stalk
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_MOVE_AND_PERFORM | AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION
	required_distance = 2 //легаси walk_to(src, target, minimum_distance = 2, delay)
	action_cooldown = 0.5 SECONDS

/datum/ai_behavior/floor_cluwne_stalk/setup(datum/ai_controller/controller, target_key)
	. = ..()
	var/atom/victim = controller.blackboard[target_key]
	if(QDELETED(victim))
		return FALSE
	set_movement_target(controller, victim)

/datum/ai_behavior/floor_cluwne_stalk/perform(delta_time, datum/ai_controller/controller, target_key)
	var/mob/living/simple_animal/hostile/floor_cluwne/creep = controller.pawn
	var/atom/victim = controller.blackboard[target_key]
	if(!istype(creep) || QDELETED(victim) || victim != creep.current_victim)
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	//сценарий мог сменить жертву между планами - держим цель движения свежей
	if(controller.current_movement_target != victim)
		set_movement_target(controller, victim)
	return AI_BEHAVIOR_DELAY //преследование бессрочно: конец решает сценарий
