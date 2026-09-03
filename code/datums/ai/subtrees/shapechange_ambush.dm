// PORT: tgstation@14140a6355d1 code/datums/ai/basic_mobs/basic_subtrees/shapechange_ambush.dm
// Адаптация BlueMoon: вместо компонента ai_target_timer время владения целью
// считается от BB_AI_TARGET_ACQUIRED_AT (ставит find_potential_targets) -
// компонент не нужен.

/// Shapeshift when we have no target, until someone has been nearby for long enough
/datum/ai_planning_subtree/shapechange_ambush
	/// Key where we keep our ability
	var/ability_key = BB_AI_SHAPESHIFT_ACTION
	/// Key where we keep our target
	var/target_key = BB_AI_CURRENT_TARGET
	/// How long to lull our target into a false sense of security
	var/minimum_target_time = 8 SECONDS

/datum/ai_planning_subtree/shapechange_ambush/SelectBehaviors(datum/ai_controller/controller, delta_time)
	var/mob/living/living_pawn = controller.pawn
	var/is_shifted = ismob(living_pawn.loc)
	var/has_target = controller.blackboard_key_exists(target_key)
	var/ability = controller.blackboard[ability_key]

	if(!is_shifted)
		if(has_target)
			return // We're busy

		if(ai_ability_available(ability, living_pawn))
			controller.queue_behavior(/datum/ai_behavior/shapeshift_ambush, ability_key) // Shift
		return SUBTREE_RETURN_FINISH_PLANNING

	if(!has_target || !ai_ability_available(ability, living_pawn))
		return SUBTREE_RETURN_FINISH_PLANNING // Lie in wait

	var/acquired_at = controller.blackboard[BB_AI_TARGET_ACQUIRED_AT]
	if(!acquired_at || world.time - acquired_at < minimum_target_time)
		return // Wait a bit longer
	controller.queue_behavior(/datum/ai_behavior/shapeshift_ambush, ability_key) // Surprise!

///Применить способность смены облика на себя
/datum/ai_behavior/shapeshift_ambush
	action_cooldown = 2 SECONDS

/datum/ai_behavior/shapeshift_ambush/perform(delta_time, datum/ai_controller/controller, ability_key)
	var/ability = controller.blackboard[ability_key]
	var/mob/living/living_pawn = controller.pawn
	if(!ai_trigger_ability(ability, living_pawn, living_pawn))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED
