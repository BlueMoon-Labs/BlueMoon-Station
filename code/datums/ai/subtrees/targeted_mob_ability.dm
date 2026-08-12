// PORT: tgstation@14140a6355d1 code/datums/ai/basic_mobs/basic_subtrees/targeted_mob_ability.dm
// Адаптация BlueMoon: способности здесь двух видов - /datum/action (Trigger()
// без аргументов) и /obj/effect/proc_holder/spell (perform(list(target), TRUE,
// user)). Универсальный вызов - ai_trigger_ability().

///Активировать способность по цели с поправкой на её вид; TRUE при успехе
/proc/ai_trigger_ability(ability, mob/living/user, atom/target)
	if(istype(ability, /obj/effect/proc_holder/spell))
		var/obj/effect/proc_holder/spell/spell_ability = ability
		if(!spell_ability.can_cast(user, FALSE, TRUE))
			return FALSE
		INVOKE_ASYNC(spell_ability, TYPE_PROC_REF(/obj/effect/proc_holder/spell, perform), list(target), TRUE, user)
		return TRUE
	if(istype(ability, /datum/action))
		var/datum/action/action_ability = ability
		if(!action_ability.IsAvailable())
			return FALSE
		INVOKE_ASYNC(action_ability, TYPE_PROC_REF(/datum/action, Trigger))
		return TRUE
	return FALSE

///TRUE, если способность в принципе готова к использованию
/proc/ai_ability_available(ability, mob/living/user)
	if(istype(ability, /obj/effect/proc_holder/spell))
		var/obj/effect/proc_holder/spell/spell_ability = ability
		return spell_ability.can_cast(user, FALSE, TRUE)
	if(istype(ability, /datum/action))
		var/datum/action/action_ability = ability
		return action_ability.IsAvailable()
	return FALSE

/// Attempts to use an ability on a target then removes it
/datum/ai_planning_subtree/targeted_mob_ability
	/// Blackboard key for the ability datum
	var/ability_key = BB_AI_TARGETED_ACTION
	/// Blackboard key for target
	var/target_key = BB_AI_CURRENT_TARGET
	/// Do we end planning after using the ability?
	var/finish_planning = TRUE

/datum/ai_planning_subtree/targeted_mob_ability/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/ability = controller.blackboard[ability_key]
	var/atom/target = controller.blackboard[target_key]
	if(isnull(ability) || QDELETED(target))
		return
	if(!ai_ability_available(ability, controller.pawn))
		return
	controller.queue_behavior(/datum/ai_behavior/targeted_mob_ability, ability_key, target_key)
	if(finish_planning)
		return SUBTREE_RETURN_FINISH_PLANNING

/// Behavior to activate an ability on a target
/datum/ai_behavior/targeted_mob_ability
	action_cooldown = 6 SECONDS

/datum/ai_behavior/targeted_mob_ability/perform(delta_time, datum/ai_controller/controller, ability_key, target_key)
	var/ability = controller.blackboard[ability_key]
	var/atom/target = controller.blackboard[target_key]
	if(isnull(ability) || QDELETED(target))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	var/mob/living/living_pawn = controller.pawn
	living_pawn.face_atom(target)
	if(!ai_trigger_ability(ability, living_pawn, target))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED
