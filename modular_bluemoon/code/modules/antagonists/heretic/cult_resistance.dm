#define HERETIC_CULT_STUN_STAMINA 35
#define HERETIC_CULT_STUN_DURATION (1 SECONDS)
#define HERETIC_CULT_STUN_KNOCKDOWN (2 SECONDS)

/mob/living/proc/apply_heretic_cult_stun()
	adjustStaminaLoss(HERETIC_CULT_STUN_STAMINA)
	Stun(HERETIC_CULT_STUN_DURATION)
	Knockdown(HERETIC_CULT_STUN_KNOCKDOWN)
	flash_act(1, TRUE)
	visible_message(span_warning("Красная вспышка сбивает [src] с ног, но за ней проступает знак Мансуса."), span_userdanger("Мансус сдерживает чужую волю. Вы сбиты с ног, но ещё можете сопротивляться!"))

#undef HERETIC_CULT_STUN_STAMINA
#undef HERETIC_CULT_STUN_DURATION
#undef HERETIC_CULT_STUN_KNOCKDOWN

#define HERETIC_GRASP_HOLD_TIME (2 SECONDS)

/// Пока цель лежит после хватки, случайный клик еретика на «помощи» не поднимает её.
/datum/status_effect/heretic_grasp_hold
	id = "heretic_grasp_hold"
	duration = HERETIC_GRASP_HOLD_TIME
	tick_interval = -1
	alert_type = null
	status_type = STATUS_EFFECT_REPLACE
	on_remove_on_mob_delete = TRUE
	var/datum/weakref/holder_ref

/datum/status_effect/heretic_grasp_hold/on_creation(mob/living/new_owner, mob/living/holder)
	holder_ref = WEAKREF(holder)
	return ..()

/datum/status_effect/heretic_grasp_hold/on_apply()
	. = ..()
	if(!.)
		return FALSE
	RegisterSignal(owner, COMSIG_CARBON_PRE_MISC_HELP, PROC_REF(block_help))
	return TRUE

/datum/status_effect/heretic_grasp_hold/on_remove()
	UnregisterSignal(owner, COMSIG_CARBON_PRE_MISC_HELP)
	holder_ref = null
	return ..()

/datum/status_effect/heretic_grasp_hold/proc/block_help(mob/living/carbon/source, mob/living/carbon/helper)
	SIGNAL_HANDLER
	if(helper != holder_ref?.resolve())
		return NONE
	helper.balloon_alert(helper, "цель прижата хваткой")
	return COMPONENT_BLOCK_MISC_HELP

#undef HERETIC_GRASP_HOLD_TIME
