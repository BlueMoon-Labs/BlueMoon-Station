// Селектор способностей боссов: вместо rand()/prob()-цепочек
// в OpenFire - таблица атак с весами, дальностями, фазами по здоровью и
// индивидуальными кулдаунами. Записи ОБОРАЧИВАЮТ легаси-проки атак (сами атаки
// не переписаны). Таблицы инстанцируются на контроллер (кулдауны - состояние
// конкретного босса). Путь игрока if(client)/chosen_attack не тронут.

/datum/boss_attack
	///имя для отладки/логов
	var/name = "boss attack"
	///индивидуальный кулдаун записи
	var/cooldown_time = 4 SECONDS
	///минимальная дистанция до цели
	var/min_range = 0
	///максимальная дистанция до цели
	var/max_range = INFINITY
	///доля здоровья, НИЖЕ которой атака доступна (1 = всегда)
	var/max_health_frac = 1
	///доля здоровья, ВЫШЕ которой атака доступна (0 = всегда)
	var/min_health_frac = 0
	///базовый вес при выборе
	var/weight = 10
	///PROC_REF легаси-атаки на мобе
	var/attack_proc
	///аргументы легаси-прока (null = без аргументов)
	var/list/attack_args
	///передавать ли текущую цель первым аргументом прока
	var/pass_target = FALSE
	///world.time следующего допустимого использования
	var/next_use_time = 0

/datum/boss_attack/New(name, attack_proc, cooldown_time, weight, min_range, max_range, min_health_frac, max_health_frac, list/attack_args)
	if(name)
		src.name = name
	src.attack_proc = attack_proc
	if(!isnull(cooldown_time))
		src.cooldown_time = cooldown_time
	if(!isnull(weight))
		src.weight = weight
	if(!isnull(min_range))
		src.min_range = min_range
	if(!isnull(max_range))
		src.max_range = max_range
	if(!isnull(min_health_frac))
		src.min_health_frac = min_health_frac
	if(!isnull(max_health_frac))
		src.max_health_frac = max_health_frac
	src.attack_args = attack_args

///Доступна ли запись прямо сейчас против цели
/datum/boss_attack/proc/is_available(mob/living/boss, atom/target)
	if(QDELETED(boss) || QDELETED(target))
		return FALSE
	if(world.time < next_use_time)
		return FALSE
	var/health_frac = boss.health / boss.maxHealth
	if(health_frac > max_health_frac || health_frac < min_health_frac)
		return FALSE
	var/distance = get_dist(boss, target)
	if(distance < min_range || distance > max_range)
		return FALSE
	return TRUE

///Исполнить легаси-прок атаки (асинхронно: многие атаки спят в телеграфах)
/datum/boss_attack/proc/execute(mob/living/boss, atom/target)
	if(QDELETED(boss) || QDELETED(target))
		return FALSE
	next_use_time = world.time + cooldown_time
	var/datum/callback/attack_call = CALLBACK(boss, attack_proc)
	var/list/final_args = list()
	if(pass_target)
		final_args += target
	if(length(attack_args))
		final_args += attack_args
	if(length(final_args))
		attack_call.InvokeAsync(arglist(final_args))
	else
		attack_call.InvokeAsync()
	return TRUE

///Ситуативный счёт записи; больше - лучше
/datum/boss_attack/proc/score(mob/living/boss, atom/target)
	. = weight
	//фазовые атаки срочнее универсальных: окно может закрыться
	if(max_health_frac < 1 || min_health_frac > 0)
		. += 5

// ===== Выбор и исполнение =====

///Выбрать лучшую доступную атаку и поставить исполнение
/datum/ai_planning_subtree/boss_ability_selection

/datum/ai_planning_subtree/boss_ability_selection/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/list/attack_table = controller.blackboard[BB_AI_BOSS_ATTACKS]
	if(!length(attack_table))
		return
	var/mob/living/simple_animal/hostile/boss = controller.pawn
	if(!istype(boss) || boss.ranged_cooldown > world.time) //общий темп способностей босса
		return
	var/atom/target = controller.blackboard[BB_AI_CURRENT_TARGET]
	if(QDELETED(target))
		return
	if(!boss.can_use_ai_ability(target))
		return

	//взвешенная колода вместо детерминированного максимума: паттерн боя
	//читается, но не заучивается наизусть. Анти-повтор режет вес только что
	//использованной записи; фазовые атаки сохраняют приоритет через score().
	var/datum/boss_attack/last_attack = controller.blackboard[BB_AI_BOSS_LAST_ATTACK]
	var/list/deck = list()
	for(var/datum/boss_attack/candidate as anything in attack_table)
		if(!candidate.is_available(boss, target))
			continue
		var/candidate_weight = max(1, candidate.score(boss, target))
		if(candidate == last_attack)
			candidate_weight = max(1, round(candidate_weight * AI_BOSS_ANTI_REPEAT_MULT))
		deck[candidate] = candidate_weight
	if(!length(deck))
		return

	var/datum/boss_attack/chosen = pickweight(deck)
	controller.set_blackboard_key(BB_AI_BOSS_CHOSEN_ATTACK, chosen)
	controller.queue_behavior(/datum/ai_behavior/boss_use_attack, BB_AI_BOSS_CHOSEN_ATTACK, BB_AI_CURRENT_TARGET)

///Боссы без новой таблицы сохраняют легаси-ветку MoveToTarget -> OpenFire.
///Вплотную стрелять не надо: там hostile_melee вызовет их AttackingTarget().
/datum/ai_planning_subtree/boss_legacy_ranged

/datum/ai_planning_subtree/boss_legacy_ranged/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	if(length(controller.blackboard[BB_AI_BOSS_ATTACKS]))
		return

	var/mob/living/simple_animal/hostile/boss = controller.pawn
	var/atom/target = controller.blackboard[BB_AI_CURRENT_TARGET]
	if(!istype(boss) || !boss.ranged || QDELETED(target) || boss.ranged_cooldown > world.time)
		return
	var/atom/attack_origin = boss.targets_from || boss
	if(target.Adjacent(attack_origin))
		return

	controller.queue_behavior(
		/datum/ai_behavior/ranged_skirmish,
		BB_AI_CURRENT_TARGET,
		BB_AI_TARGETING_STRATEGY,
		BB_AI_TARGET_HIDING_LOCATION,
		INFINITY,
		2,
	)

///Исполнение выбранной атаки
/datum/ai_behavior/boss_use_attack
	action_cooldown = 1 SECONDS

/datum/ai_behavior/boss_use_attack/perform(delta_time, datum/ai_controller/controller, chosen_key, target_key)
	var/datum/boss_attack/chosen = controller.blackboard[chosen_key]
	var/atom/target = controller.blackboard[target_key]
	var/mob/living/simple_animal/hostile/boss = controller.pawn
	if(isnull(chosen) || QDELETED(target) || !istype(boss) || QDELETED(boss) || boss.ranged_cooldown > world.time)
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	if(!boss.can_use_ai_ability(target) || !chosen.is_available(boss, target))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	boss.target = target //легаси-проки атак читают src.target
	//Темп взводим синхронно: прелюдия может спать (энрейдж-спин фрост-майнера),
	//и селектор не должен успеть выбрать вторую способность во время телеграфа.
	//Атака, задающая свой кулдаун (элитки, пандора), перезапишет его позже сама.
	chosen.next_use_time = world.time + chosen.cooldown_time
	if(boss.ranged_cooldown <= world.time)
		boss.ranged_cooldown = world.time + chosen.cooldown_time
	controller.set_blackboard_key(BB_AI_BOSS_LAST_ATTACK, chosen) //анти-повтор колоды
	INVOKE_ASYNC(src, PROC_REF(run_attack_chain), chosen, boss, target)
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

///Прелюдия и исполнение одной async-цепочкой: порядок легаси-OpenFire сохранён
///(атака ждёт конца прелюдии), а сон внутри не вешает тикер поведений
/datum/ai_behavior/boss_use_attack/proc/run_attack_chain(datum/boss_attack/chosen, mob/living/simple_animal/hostile/boss, atom/target)
	if(QDELETED(boss) || boss.stat == DEAD || QDELETED(target))
		return
	boss.ai_ability_prelude()
	if(QDELETED(boss) || boss.stat == DEAD || QDELETED(target))
		return
	chosen.execute(boss, target)

/datum/ai_behavior/boss_use_attack/finish_action(datum/ai_controller/controller, succeeded, chosen_key, target_key)
	. = ..()
	controller.clear_blackboard_key(chosen_key)
