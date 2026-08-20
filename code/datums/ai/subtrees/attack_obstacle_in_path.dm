// PORT: tgstation@14140a6355d1 code/datums/ai/basic_mobs/basic_subtrees/attack_obstacle_in_path.dm
// Апгрейд BlueMoon: если у пауна есть активный JPS-луп с кэшированным путём,
// проверяется и атакуется РЕАЛЬНЫЙ следующий турф маршрута, а не направляющая
// догадка get_step_towards (требование спеки: бить настоящую преграду пути).
// Исполнение удара - через obstacle policy (двери открываются, объекты
// ломаются по разрешениям профиля).

///Следующий шаг пауна к цели, либо null, если его ещё не на чем основать.
///Прямой (bee-line) режим лупа честно ходит по get_step_towards, поэтому там
///направляющая догадка И ЕСТЬ маршрут. А вот у JPS-лупа с пустым кэшем маршрут
///только считается: поиск асинхронный и умеет спать в очереди за слотом
///SSpathfinder. Догадка в этом окне уводила моба вскрывать дверь/стену по прямой
///к цели, хотя настоящий путь вёл совсем в другую сторону (репорт плейтеста про
///выломанную дверь). Ждём реальный шаг вместо того, чтобы ломать что попало.
///
///Но ЗАВЕРШИВШИЙСЯ поиск с пустым результатом - это не "подожди", это "маршрута
///нет вообще": цель за стеной/рудой, и пробить её - единственный способ дойти.
///Без догадки в этом случае моб просто вставал перед преградой и не делал ничего
///(плейтест: "стоял перед толпой карпов, они мне ничего не делали", "отойти за
///экранчик - и они тупят"). Ждём только пока поиск реально в работе.
/proc/ai_next_path_step(mob/living/pawn, atom/target)
	var/datum/move_loop/has_target/jps/jps_loop = SSmove_manager.processing_on(pawn, SSai_movement)
	if(istype(jps_loop))
		if(length(jps_loop.movement_path))
			return jps_loop.movement_path[1]
		if(jps_loop.repath_in_progress)
			return null
	return get_step_towards(pawn, target)

///Реальный заблокированный следующий турф маршрута к цели, либо null
/proc/ai_get_blocked_path_turf(mob/living/pawn, atom/target)
	var/turf/current_turf = get_turf(pawn)
	var/turf/next_step = ai_next_path_step(pawn, target)
	if(current_turf && next_step && (next_step.is_blocked_turf(exclude_mobs = TRUE, source_atom = pawn) || current_turf.LinkBlockedWithAccess(next_step, pawn, pawn.get_idcard(), FALSE)))
		return next_step
	return null

///Живой АТАКУЕМЫЙ моб, перегородивший телом следующий шаг пути к цели (body-block),
///либо null. Союзники/нейтралы (CanAttack=FALSE) сюда не попадают - их мовер обходит,
///а вот врага (игрока) моб обязан пробивать, а не обтекать (fairness-паритет с PvP).
/proc/ai_path_blocker_mob(mob/living/pawn, atom/target)
	var/mob/living/simple_animal/hostile/hostile_pawn = pawn
	if(!istype(hostile_pawn) || QDELETED(target))
		return null
	var/turf/next_step = ai_next_path_step(pawn, target)
	if(!next_step || !next_step.Adjacent(pawn))
		return null
	for(var/mob/living/blocker in next_step)
		if(blocker == pawn || blocker == target || !blocker.density)
			continue
		if(hostile_pawn.CanAttack(blocker))
			return blocker
	return null

///Плотное пристёгнутое тело без сознания (труп на стуле) на этом турфе, либо null.
///Такой блокер не цель (CanAttack режет мёртвых) и не "толпа, которая разойдётся":
///пристёгнутое бессознательное тело не освободит тайл никогда. Игрок снимает его
///одним кликом - пауну нужен тот же глагол, иначе это неразрушимая стена от NPC.
/proc/ai_seated_body_blocker(mob/living/pawn, turf/step)
	if(!step)
		return null
	for(var/mob/living/blocker in step)
		if(blocker == pawn || !blocker.density || !blocker.buckled)
			continue
		if(blocker.stat < UNCONSCIOUS)
			continue
		if(pawn.see_invisible < blocker.invisibility)
			continue
		return blocker
	return null

///Тело-баррикада на следующем шаге пути к цели, либо null. Саму цель не считаем
///баррикадой - до неё паун "доходит" атакой, а не отстёгиванием.
/proc/ai_body_barricade_mob(mob/living/pawn, atom/target)
	if(QDELETED(target))
		return null
	var/turf/next_step = ai_next_path_step(pawn, target)
	if(!next_step || !next_step.Adjacent(pawn))
		return null
	var/mob/living/blocker = ai_seated_body_blocker(pawn, next_step)
	if(blocker == target)
		return null
	return blocker

///TRUE если на этом шаге стоит живой моб, которого паун может атаковать
///(враг-body-block), либо пристёгнутое тело-баррикада, которое он умеет отстегнуть.
///Мовер по этому флагу НЕ обходит блокера, а держит позицию под расчистку.
/proc/ai_step_blocker_attackable(mob/living/pawn, turf/step)
	var/mob/living/simple_animal/hostile/hostile_pawn = pawn
	if(!istype(hostile_pawn) || !step)
		return FALSE
	for(var/mob/living/blocker in step)
		if(blocker == pawn || !blocker.density)
			continue
		if(hostile_pawn.CanAttack(blocker))
			return TRUE
	return !!ai_seated_body_blocker(pawn, step)

/// If there's something between us and our target then we need to queue a behaviour to make it not be there
/datum/ai_planning_subtree/attack_obstacle_in_path
	/// Blackboard key containing current target
	var/target_key = BB_AI_CURRENT_TARGET
	/// The action to execute, extend to add a different cooldown or something
	var/attack_behaviour = /datum/ai_behavior/attack_obstructions

/datum/ai_planning_subtree/attack_obstacle_in_path/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/atom/target = controller.blackboard[target_key]
	if(QDELETED(target))
		return

	//живой атакуемый блокер (враг, перегородивший телом путь) важнее стены: моб
	//пробивает его, а не обходит - иначе body-block против мобов не работает.
	//Проверяется ДО предметного гейта ниже: враг, вставший на пути к добыче, -
	//законная цель удара независимо от того, что моб шёл за предметом.
	if(ai_path_blocker_mob(controller.pawn, target))
		controller.queue_behavior(/datum/ai_behavior/attack_path_blocker, target_key)
		return

	//Труп на стуле - не цель и не толпа: пристёгнутое тело не освободит тайл
	//само (репорт: "трупики на стул садят и защищаются от ботов"). Отстёгивание
	//ничего не ломает, поэтому предметный гейт ниже его не касается.
	if(ai_body_barricade_mob(controller.pawn, target))
		controller.queue_behavior(/datum/ai_behavior/clear_body_barricade, target_key)
		return

	//Ломать окружение можно ради добычи, но не ради ХЛАМА. Мобы с
	//search_objects/wanted_objects (гусь за мусором, watcher за алмазом,
	//голдграб за рудой, майнбот в режиме сбора) целью делают предмет, и без
	//этого гейта они вскрывали шлюзы, чтобы подобрать его. Живые цели, мехи и
	//машинерия остаются законным поводом пробиваться.
	if(isitem(target))
		return

	if(!ai_get_blocked_path_turf(controller.pawn, target))
		return

	controller.queue_behavior(attack_behaviour, target_key)
	// Don't cancel future planning, maybe we can move now

/// Something is in our way, get it outta here
/datum/ai_behavior/attack_obstructions
	action_cooldown = 2 SECONDS
	behavior_flags = AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION

///Separate behavior slot so a just-lost combat target cannot leave SEARCH
///executing the old BB_AI_CURRENT_TARGET arguments for another planning cycle.
/datum/ai_behavior/attack_obstructions/search

/datum/ai_behavior/attack_obstructions/perform(delta_time, datum/ai_controller/controller, target_key)
	var/mob/living/living_pawn = controller.pawn
	var/atom/target = controller.blackboard[target_key]

	if(QDELETED(target))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	var/turf/blocked_turf = ai_get_blocked_path_turf(living_pawn, target)
	if(!blocked_turf)
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED //путь чист - нам тут больше нечего делать
	if(!blocked_turf.Adjacent(living_pawn))
		return AI_BEHAVIOR_DELAY //ещё подходим к преграде - не считаем это неудачей

	var/datum/obstacle_policy/policy = GET_OBSTACLE_POLICY(controller.blackboard[BB_AI_OBSTACLE_POLICY] || /datum/obstacle_policy)

	var/dir_to_next_step = get_dir(living_pawn, blocked_turf)
	//диагональ разбираем на кардиналы: бьём то, что реально мешает
	var/list/dirs_to_clear = list()
	if(ISDIAGONALDIR(dir_to_next_step))
		for(var/direction in GLOB.cardinals)
			if(direction & dir_to_next_step)
				dirs_to_clear += direction
	else
		dirs_to_clear += dir_to_next_step

	for(var/direction in dirs_to_clear)
		if(clear_in_direction(controller, living_pawn, direction, policy))
			return AI_BEHAVIOR_DELAY

	//ничем не помочь - копим фрустрацию, пусть скорер/поиск целей решают
	controller.note_move_failure()
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

///Разобраться с преградой в направлении; TRUE = чем-то занялись
/datum/ai_behavior/attack_obstructions/proc/clear_in_direction(datum/ai_controller/controller, mob/living/living_pawn, direction, datum/obstacle_policy/policy)
	var/turf/current_turf = get_turf(living_pawn)
	var/turf/next_step = get_step(living_pawn, direction)
	if(!current_turf || !next_step)
		return FALSE
	if(!next_step.is_blocked_turf(exclude_mobs = TRUE, source_atom = living_pawn) && !current_turf.LinkBlockedWithAccess(next_step, living_pawn, controller.get_access(), FALSE))
		return FALSE
	return policy.try_step(living_pawn, controller, current_turf, next_step)

///Пробить живого блокера на пути: моб бьёт врага, перегородившего телом дорогу к
///цели, обычным милишным ударом (attack_animal уважает КД, урон, пацифизм). КД
///поведения короткое - реальную каденцию всё равно гейтит CLICK_CD_MELEE моба.
/datum/ai_behavior/attack_path_blocker
	action_cooldown = 1 SECONDS
	behavior_flags = AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION

/datum/ai_behavior/attack_path_blocker/perform(delta_time, datum/ai_controller/controller, target_key)
	var/mob/living/living_pawn = controller.pawn
	var/atom/target = controller.blackboard[target_key]
	if(!isliving(living_pawn) || QDELETED(target))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	var/mob/living/blocker = ai_path_blocker_mob(living_pawn, target)
	if(QDELETED(blocker))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED //путь чист - блокера больше нет
	living_pawn.setDir(get_dir(living_pawn, blocker))
	INVOKE_ASYNC(blocker, TYPE_PROC_REF(/atom, attack_animal), living_pawn)
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

///Расчистить тело-баррикаду: отстегнуть пристёгнутый труп с пути тем же глаголом,
///каким пользуется игрок (user_unbuckle_mob). Кулдаун совпадает с AI_UNBUCKLE_COOLDOWN:
///часть оверрайдов отстёгивания спит в do_after, чаще дёргать бессмысленно.
/datum/ai_behavior/clear_body_barricade
	action_cooldown = AI_UNBUCKLE_COOLDOWN
	behavior_flags = AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION

/datum/ai_behavior/clear_body_barricade/perform(delta_time, datum/ai_controller/controller, target_key)
	var/mob/living/living_pawn = controller.pawn
	var/atom/target = controller.blackboard[target_key]
	if(!isliving(living_pawn) || QDELETED(target))
		controller.blackboard[BB_AI_BARRICADE_TUGS] = 0
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	var/mob/living/blocker = ai_body_barricade_mob(living_pawn, target)
	if(QDELETED(blocker) || !blocker.buckled)
		controller.blackboard[BB_AI_BARRICADE_TUGS] = 0
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED //тайл свободен - дальше обычный шаг
	var/tugs = controller.blackboard[BB_AI_BARRICADE_TUGS] || 0
	if(tugs >= AI_BARRICADE_UNBUCKLE_ATTEMPTS)
		//крепление не поддаётся - копим фрустрацию, пусть скорер/поиск целей решают
		controller.blackboard[BB_AI_BARRICADE_TUGS] = 0
		controller.note_move_failure()
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	controller.blackboard[BB_AI_BARRICADE_TUGS] = tugs + 1
	living_pawn.setDir(get_dir(living_pawn, blocker))
	log_combat(living_pawn, blocker, "unbuckled as a path obstacle")
	//user_unbuckle_mob местами спит в do_after - из поведения зовём только асинхронно
	INVOKE_ASYNC(blocker.buckled, TYPE_PROC_REF(/atom/movable, user_unbuckle_mob), blocker, living_pawn)
	return AI_BEHAVIOR_DELAY
