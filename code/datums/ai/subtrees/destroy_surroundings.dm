// Каденс сноса окружения для мегафауны и осадных мобов:
// легаси звал DestroySurroundings() каждый пасс npcpool - здесь то же самое
// поведением на кулдауне, пока есть цель.

/datum/ai_planning_subtree/destroy_surroundings

/datum/ai_planning_subtree/destroy_surroundings/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	if(!controller.blackboard_key_exists(BB_AI_CURRENT_TARGET))
		return
	var/mob/living/simple_animal/hostile/hostile_pawn = controller.pawn
	if(!istype(hostile_pawn) || !hostile_pawn.environment_smash)
		return
	controller.queue_behavior(/datum/ai_behavior/destroy_surroundings)

/datum/ai_behavior/destroy_surroundings
	action_cooldown = 1 SECONDS
	behavior_flags = AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION

/datum/ai_behavior/destroy_surroundings/perform(delta_time, datum/ai_controller/controller)
	var/mob/living/simple_animal/hostile/hostile_pawn = controller.pawn
	if(!istype(hostile_pawn))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	hostile_pawn.DestroySurroundings()
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED
