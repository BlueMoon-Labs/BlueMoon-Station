// Пилот меха на адаптер-контроллере (curseblob-паттерн: сабтри-делегат его
// легаси-FSM). Вне меха пилот - обычный пехотинец штатной машины: угон
// свободного меха работает через CanAttack/AttackingTarget-делегацию
// (подошёл вплотную - залез), а сабтри лишь гоняет легаси-скан
// ai_seek_stolen_mecha с каденсом NPC-пула. В мехе штатный мувер бессилен
// (loc пауна - не турф, шаги запрещены), поэтому оператор двигает САМ МЕХ
// мув-лупами walk_to-семантики - ровно как легаси Goto водил мех walk_to -
// и бьёт делегацией MeleeAction/OpenFire; фазовую логику (дым, щит,
// отступление, эвакуация) целиком ведёт легаси-прок ai_operate_mecha_phase.

///FSM пилота: без меха - скан на угон (остальной план живёт), в мехе -
///оператор и заморозка штатных сабтри (им нечего делать внутри объекта)
/datum/ai_planning_subtree/mecha_pilot_fsm

/datum/ai_planning_subtree/mecha_pilot_fsm/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/mob/living/simple_animal/hostile/syndicate/mecha_pilot/pilot = controller.pawn
	if(!istype(pilot))
		return
	if(!pilot.mecha)
		//пеший приоритет угона: свободный мех перебивает мобов, как легаси
		controller.queue_behavior(/datum/ai_behavior/mecha_pilot_seek_mecha)
		return
	controller.queue_behavior(/datum/ai_behavior/mecha_pilot_operate)
	return SUBTREE_RETURN_FINISH_PLANNING

// ===== Поведения =====

///Пеший скан на угон: легаси-прок ai_seek_stolen_mecha с каденсом NPC-пула.
///Найденный мех становится целью (GiveTarget-зеркало) - дальше штатная
///милишка сама подводит пилота и сажает его делегацией AttackingTarget.
/datum/ai_behavior/mecha_pilot_seek_mecha
	behavior_flags = AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION

/datum/ai_behavior/mecha_pilot_seek_mecha/get_cooldown(datum/ai_controller/cooldown_for)
	return SSnpcpool.wait //легаси-каденс handle_automated_action

/datum/ai_behavior/mecha_pilot_seek_mecha/perform(delta_time, datum/ai_controller/controller)
	var/mob/living/simple_animal/hostile/syndicate/mecha_pilot/pilot = controller.pawn
	if(!istype(pilot) || pilot.mecha)
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	if(pilot.ai_seek_stolen_mecha())
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

///Оператор меха: фазы легаси-проком, движение мув-лупами самого меха,
///атаки - делегацией MeleeAction/OpenFire (вся кастомщина оружия меха
///в AttackingTarget/OpenFire пилота работает без изменений)
/datum/ai_behavior/mecha_pilot_operate
	behavior_flags = AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION

/datum/ai_behavior/mecha_pilot_operate/get_cooldown(datum/ai_controller/cooldown_for)
	return SSnpcpool.wait //легаси-каденс handle_automated_action

/datum/ai_behavior/mecha_pilot_operate/perform(delta_time, datum/ai_controller/controller)
	var/mob/living/simple_animal/hostile/syndicate/mecha_pilot/pilot = controller.pawn
	if(!istype(pilot) || !pilot.mecha)
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	controller.set_blackboard_key(BB_AI_PILOTED_MECHA, pilot.mecha)

	//фазовая логика (дым/щит/отступление/эвакуация) - легаси-делегат;
	//эвакуация сама останавливает лупы меха (aimob_exit_mech)
	if(!pilot.ai_operate_mecha_phase())
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

	var/atom/target = controller.blackboard[BB_AI_CURRENT_TARGET]
	if(QDELETED(target))
		//без цели мех стоит, как легаси без MoveToTarget
		stop_mecha_loops(controller)
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	var/datum/targeting_strategy/targeting_strategy = GET_TARGETING_STRATEGY(controller.blackboard[BB_AI_TARGETING_STRATEGY])
	if(targeting_strategy && !targeting_strategy.can_attack(pilot, target))
		stop_mecha_loops(controller)
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	pilot.target = target
	var/atom/attack_origin = pilot.targets_from || pilot
	if(target.Adjacent(attack_origin))
		pilot.in_melee = TRUE
		//MeleeAction -> AttackingTarget: оружие меха/mech_melee_attack;
		//детачимся от возможных до-афтеров, как обычная милишка
		INVOKE_ASYNC(pilot, TYPE_PROC_REF(/mob/living/simple_animal/hostile, MeleeAction), FALSE)
	else
		pilot.in_melee = FALSE
		//легаси-паритет MoveToTarget: расчистка пути к цели и дальний бой
		pilot.DestroyPathToTarget()
		if(pilot.ranged && pilot.ranged_cooldown <= world.time)
			INVOKE_ASYNC(pilot, TYPE_PROC_REF(/mob/living/simple_animal/hostile, OpenFire), target)

	//движение мехом: walk_to/walk_away-семантика легаси Goto/MoveToTarget.
	//Повторный вызов move_manager с теми же аргументами штатно заменяет луп.
	var/target_distance = get_dist(attack_origin, target)
	if(!isnull(pilot.retreat_distance) && target_distance <= pilot.retreat_distance)
		SSmove_manager.move_away(pilot.mecha, target, pilot.retreat_distance, pilot.mecha.movedelay, subsystem = SSai_movement)
	else
		SSmove_manager.move_to(pilot.mecha, target, pilot.minimum_distance, pilot.mecha.movedelay, subsystem = SSai_movement)
	return AI_BEHAVIOR_DELAY

/datum/ai_behavior/mecha_pilot_operate/finish_action(datum/ai_controller/controller, succeeded)
	. = ..()
	stop_mecha_loops(controller)

///Остановить наши мув-лупы меха. Мех берём из блэкборда: смерть/выброс
///могли уже разорвать pawn.mecha, а бесхозный луп продолжил бы возить
///пустой мех. Сам aimob_exit_mech тоже глушит лупы на всех путях выхода.
/datum/ai_behavior/mecha_pilot_operate/proc/stop_mecha_loops(datum/ai_controller/controller)
	var/obj/vehicle/sealed/mecha/piloted = controller.blackboard[BB_AI_PILOTED_MECHA]
	controller.clear_blackboard_key(BB_AI_PILOTED_MECHA)
	if(QDELETED(piloted))
		return
	SSmove_manager.stop_looping(piloted, SSai_movement)
