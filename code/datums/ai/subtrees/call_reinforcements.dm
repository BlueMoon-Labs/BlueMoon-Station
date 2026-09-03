// PORT: tgstation@14140a6355d1 code/datums/ai/basic_mobs/basic_subtrees/call_reinforcements.dm
// Адаптация BlueMoon: вместо oview(15)-обхода - report_contact_to_allies()
// (грид-канал AI_TARGETS, будит спящих союзников). Союзники получают точку
// контакта, а не сам атом. Простые речь/эмоут поведения включены сюда же.

/// Calls all nearby mobs that share a faction to give backup in combat
/datum/ai_planning_subtree/call_reinforcements
	/// Reinforcement-calling behavior to use
	var/call_type = /datum/ai_behavior/call_reinforcements

/datum/ai_planning_subtree/call_reinforcements/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	if(!decide_to_call(controller) || controller.blackboard[BB_AI_REINFORCEMENTS_COOLDOWN] > world.time)
		return

	var/call_say = controller.blackboard[BB_AI_REINFORCEMENTS_SAY]
	var/call_emote = controller.blackboard[BB_AI_REINFORCEMENTS_EMOTE]

	if(!isnull(call_say))
		controller.queue_behavior(/datum/ai_behavior/perform_speech, call_say)
	else if(!isnull(call_emote))
		controller.queue_behavior(/datum/ai_behavior/perform_emote, call_emote)

	controller.queue_behavior(call_type)

/// Decides when to call reinforcements, can be overridden for alternate behavior
/datum/ai_planning_subtree/call_reinforcements/proc/decide_to_call(datum/ai_controller/controller)
	return controller.blackboard_key_exists(BB_AI_CURRENT_TARGET) && ismob(controller.blackboard[BB_AI_CURRENT_TARGET])

/// Call out to all same-faction controllers in range for help
/datum/ai_behavior/call_reinforcements
	/// How frequently can we call for reinforcements?
	var/cooldown = 30 SECONDS
	/// Range to call reinforcements from
	var/reinforcements_range = 15

/datum/ai_behavior/call_reinforcements/perform(delta_time, datum/ai_controller/controller)
	controller.set_blackboard_key(BB_AI_REINFORCEMENTS_COOLDOWN, world.time + cooldown)
	var/atom/target = controller.blackboard[BB_AI_CURRENT_TARGET]
	if(QDELETED(target))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	controller.report_contact_to_allies(target, reinforcements_range)
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

///Сказать фразу (боевой клич, призыв)
/datum/ai_behavior/perform_speech

/datum/ai_behavior/perform_speech/perform(delta_time, datum/ai_controller/controller, speech)
	var/mob/living/living_pawn = controller.pawn
	if(!istype(living_pawn))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	INVOKE_ASYNC(living_pawn, TYPE_PROC_REF(/atom/movable, say), speech)
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

///Выполнить эмоут
/datum/ai_behavior/perform_emote

/datum/ai_behavior/perform_emote/perform(delta_time, datum/ai_controller/controller, emote_text)
	var/mob/living/living_pawn = controller.pawn
	if(!istype(living_pawn))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	INVOKE_ASYNC(living_pawn, TYPE_PROC_REF(/mob, emote), emote_text)
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED
