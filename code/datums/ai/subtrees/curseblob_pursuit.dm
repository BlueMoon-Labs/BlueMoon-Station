// Curseblob на адаптер-контроллере. У моба ЖЁСТКО закреплённая жертва
// (set_target от проклятия некрополиса), собственное движение телепорт-шагами
// (легаси move_loop с forceMove) и самоуничтожение при потере жертвы
// (check_for_target). Контроллер поэтому НЕ ищет цели и НЕ водит пауна штатным
// мувером: сабтри лишь поддерживает закрепление в блэкборде, гоняет легаси-цикл
// движения делегатом (как boss_attack оборачивает легаси-атаки) и бьёт
// вплотную через MeleeAction - вся кастомщина атак и фильтров
// "не жертва - не трогаем" работает без изменений.

///Стратегия закреплённой цели: пригодна только собственная жертва проклятия.
///Зрение игнорируется - блоб ведёт жертву сквозь стены, как легаси-цикл.
/datum/targeting_strategy/curseblob_victim
	ignore_sight = TRUE

/datum/targeting_strategy/curseblob_victim/can_attack(mob/living/living_mob, atom/target, vision_range)
	var/mob/living/simple_animal/hostile/asteroid/curseblob/blob = living_mob
	if(!istype(blob))
		return FALSE
	return !QDELETED(target) && target == blob.set_target

///Условия легаси check_for_target() БЕЗ его синхронного qdel: сносить пауна
///изнутри цикла планирования/поведений контроллера небезопасно, поэтому само
///растворение уходит на таймер (см. вызовы ниже).
/mob/living/simple_animal/hostile/asteroid/curseblob/proc/ai_victim_lost()
	return QDELETED(set_target) || set_target.stat != CONSCIOUS || z != set_target.z

// ===== Сабтри =====

///Единственный сабтри curseblob-профиля: закрепление жертвы + легаси-движение
///+ милишный делегат. Потеря жертвы растворяет блоб легаси-проком.
/datum/ai_planning_subtree/curseblob_pursuit

/datum/ai_planning_subtree/curseblob_pursuit/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/mob/living/simple_animal/hostile/asteroid/curseblob/blob = controller.pawn
	if(!istype(blob))
		return
	if(blob.ai_victim_lost())
		//жертва потеряна: блоб исчезает легаси check_for_target(), но отложенно -
		//qdel пауна из собственного планирования рвёт цикл контроллера
		addtimer(CALLBACK(blob, TYPE_PROC_REF(/mob/living/simple_animal/hostile/asteroid/curseblob, check_for_target)), 0)
		return SUBTREE_RETURN_FINISH_PLANNING
	controller.queue_behavior(/datum/ai_behavior/curseblob_pursuit)
	return SUBTREE_RETURN_FINISH_PLANNING

// ===== Поведение =====

///Шаг преследования: держит закрепление жертвы в блэкборде, гоняет
///самоподдерживающийся легаси move_loop и бьёт вплотную через MeleeAction.
///Контроллерное движение не используется вовсе - телепорт-шаги и есть
///фирменная "атака-перемещение" этого моба.
/datum/ai_behavior/curseblob_pursuit
	behavior_flags = AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION

///Каденс милишки адаптера: легаси-формула NPC-пула с профильным скейлом
///(та же, что у hostile_melee_attack - блоб бьёт как остальные мигранты)
/datum/ai_behavior/curseblob_pursuit/get_cooldown(datum/ai_controller/cooldown_for)
	var/mob/living/simple_animal/hostile/hostile_pawn = cooldown_for.pawn
	if(!istype(hostile_pawn))
		return ..()
	return max(world.tick_lag, SSnpcpool.wait * hostile_pawn.ai_melee_cadence_scale / max(hostile_pawn.rapid_melee, 1))

/datum/ai_behavior/curseblob_pursuit/perform(delta_time, datum/ai_controller/controller)
	var/mob/living/simple_animal/hostile/asteroid/curseblob/blob = controller.pawn
	if(!istype(blob))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	if(blob.ai_victim_lost())
		//растворение отложенно легаси-проком: qdel пауна из perform небезопасен
		addtimer(CALLBACK(blob, TYPE_PROC_REF(/mob/living/simple_animal/hostile/asteroid/curseblob, check_for_target)), 0)
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	var/mob/living/victim = blob.set_target
	//жертва проклятия не может быть потеряна или подменена
	if(controller.blackboard[BB_AI_CURRENT_TARGET] != victim)
		controller.set_blackboard_key(BB_AI_CURRENT_TARGET, victim)
	//легаси-движение: телепорт-шаги; цикл самоподдерживающийся (waitfor = FALSE),
	//повторный вызов при живом цикле - no-op. Задержка в легаси-единицах sleep().
	blob.move_loop(victim, blob.move_to_delay)
	var/atom/attack_origin = blob.targets_from || blob
	if(victim.Adjacent(attack_origin))
		blob.in_melee = TRUE
		//MeleeAction -> AttackingTarget: детач на случай спящих сабтиповых атак
		INVOKE_ASYNC(blob, TYPE_PROC_REF(/mob/living/simple_animal/hostile, MeleeAction), FALSE)
		return AI_BEHAVIOR_DELAY
	blob.in_melee = FALSE
	return AI_BEHAVIOR_DELAY
