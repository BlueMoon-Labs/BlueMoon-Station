/mob/living/simple_animal/hostile/jungle
	vision_range = 5
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	faction = list("jungle")
	weather_immunities = list("acid")
	obj_damage = 30
	environment_smash = ENVIRONMENT_SMASH_WALLS
	minbodytemp = 0
	maxbodytemp = 450
	response_harm_continuous = "strikes"
	response_harm_simple = "strike"
	status_flags = NONE
	a_intent = INTENT_HARM
	see_in_dark = 4
	lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE
	mob_size = MOB_SIZE_LARGE

// ===== Адаптер-профиль фазовых бойцов =====
// У мука и сидлинга атаки - легаси-машины состояний на таймерах (разминка ->
// удар/залп -> откат). Легаси handle_automated_action при активной фазе
// возвращался до любых решений; jungle_phase_guard воспроизводит этот ранний
// return: замораживает весь план (поиск целей, FSM, движение, атаки) и глушит
// уже запущенные поведения. Сами фазы идут делегацией: милишный делегат
// попадает в AttackingTarget, дальний - в OpenFire, оба уходят в WarmupAttack.

///Активна ли легаси-фаза атаки: гейт jungle_phase_guard. Сабтипы с фазовой
///машиной (мук, сидлинг) переопределяют по своим файл-локальным константам.
/mob/living/simple_animal/hostile/jungle/proc/ai_attack_phase_active()
	return FALSE

///Фазовые бойцы джунглей (мук, сидлинг): дальний-в-мили план, но активная
///легаси-фаза атаки замораживает планирование целиком
/datum/ai_controller/hostile_adapter/ranged_chaser/jungle_staged
	planning_subtrees = list(
		/datum/ai_planning_subtree/jungle_phase_guard,
		/datum/ai_planning_subtree/find_hostile_targets,
		/datum/ai_planning_subtree/hostile_fsm,
		/datum/ai_planning_subtree/ranged_skirmish,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/hostile_melee,
	)

///Фазовый гейт: легаси-ранний return handle_automated_action. Фазовые таймеры
///сами доведут атаку и вернут моба в нейтраль - контроллер не вмешивается.
/datum/ai_planning_subtree/jungle_phase_guard

/datum/ai_planning_subtree/jungle_phase_guard/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/mob/living/simple_animal/hostile/jungle/beast = controller.pawn
	if(!istype(beast) || !beast.ai_attack_phase_active())
		return
	if(length(controller.current_behaviors))
		controller.CancelActions()
	return SUBTREE_RETURN_FINISH_PLANNING
