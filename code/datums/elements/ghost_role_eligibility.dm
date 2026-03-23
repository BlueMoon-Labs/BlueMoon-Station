GLOBAL_LIST_EMPTY(ghost_eligible_mobs)
GLOBAL_LIST_EMPTY(ghost_eligible_mobs_priority)

GLOBAL_LIST_EMPTY(client_ghost_timeouts)

/datum/element/ghost_role_eligibility
	element_flags = ELEMENT_DETACH | ELEMENT_BESPOKE
	id_arg_index = 2
	var/low_priority = FALSE // Является ли моб менее приоритетным, по отношению ко всем остальным (для Гост кафе)
	var/penalizing = FALSE
	var/free_ghost = FALSE

/datum/element/ghost_role_eligibility/Attach(datum/target,free_ghosting = FALSE, penalize_on_ghost = FALSE, _low_priority)
	. = ..()
	if(!ismob(target))
		return ELEMENT_INCOMPATIBLE
	penalizing = penalize_on_ghost
	free_ghost = free_ghosting
	if(!isnull(_low_priority))
		low_priority = _low_priority
	change_role_lists(target)
	RegisterSignal(target, COMSIG_MOB_GHOSTIZE, PROC_REF(get_ghost_flags))

/datum/element/ghost_role_eligibility/Detach(mob/M)
	. = ..()
	change_role_lists(M, remove = TRUE)
	UnregisterSignal(M, COMSIG_MOB_GHOSTIZE)

/proc/get_all_ghost_role_eligible(silent = FALSE, priority_only = FALSE)
	var/list/possible_candidates = priority_only ? GLOB.ghost_eligible_mobs_priority : GLOB.ghost_eligible_mobs
	var/list/candidates = list()
	for(var/m in possible_candidates)
		var/mob/M = m
		if(M.can_reenter_round(TRUE))
			candidates += M
	return candidates

/mob/proc/can_reenter_round(silent = FALSE)
	if(!(src in GLOB.ghost_eligible_mobs))
		return FALSE
	if(!(ckey in GLOB.client_ghost_timeouts))
		return TRUE
	var/timeout = GLOB.client_ghost_timeouts[ckey]
	if(timeout != CANT_REENTER_ROUND && timeout <= world.realtime)
		return TRUE
	if(!silent && client)
		to_chat(src, "<span class='warning'>You are unable to reenter the round[timeout != CANT_REENTER_ROUND ? " yet. Your ghost role blacklist will expire in [DisplayTimeText(timeout - world.realtime)]" : ""].</span>")
	return FALSE

/datum/element/ghost_role_eligibility/proc/get_ghost_flags()
	. = 0
	if(!penalizing)
		. |= COMPONENT_DO_NOT_PENALIZE_GHOSTING
	if(free_ghost)
		. |= COMPONENT_FREE_GHOSTING
	return .

/datum/element/ghost_role_eligibility/proc/change_role_lists(mob/M, remove = FALSE)
	if(remove)
		GLOB.ghost_eligible_mobs -= M
		GLOB.ghost_eligible_mobs_priority -= M
	else
		GLOB.ghost_eligible_mobs |= M
		if(!low_priority)
			GLOB.ghost_eligible_mobs_priority |= M

// Кнопка по отключению от доступных к выбору мобов
/datum/action/cooldown/ghost_role_eligible
	name = "Участие в распределении гост ролей"
	desc = "Позволяет отключать или включать уведомления о распределеннии на новую гост роль."
	icon_icon = 'icons/mob/mob.dmi'
	button_icon_state = "ghost"
	cooldown_time = 6 SECONDS

/datum/action/cooldown/ghost_role_eligible/UpdateButton(atom/movable/screen/movable/action_button/button, status_only, force)
	var/mob/action_owner = owner
	var/datum/element/ghost_role_eligibility/elem = LAZYACCESS(action_owner.comp_lookup, COMSIG_MOB_GHOSTIZE)
	if(elem)
		button_icon_state = (action_owner in GLOB.ghost_eligible_mobs) ? "ghost" : "ghost_red"
	else
		Remove(action_owner)
		return

	return ..()

/datum/action/cooldown/ghost_role_eligible/Activate(atom/target)
	var/mob/action_owner = owner
	var/datum/element/ghost_role_eligibility/elem = LAZYACCESS(action_owner.comp_lookup, COMSIG_MOB_GHOSTIZE)
	if(elem)
		var/remove = (action_owner in GLOB.ghost_eligible_mobs)
		elem.change_role_lists(action_owner, remove = remove)
		StartCooldown()

		var/message = "Вы [remove ? "отключили" : "включили"] участие в распределении гост ролей"
		action_owner.balloon_alert(action_owner, remove ? span_balloon_warning(message) : message)

		message += "."
		to_chat(action_owner, remove ? span_warning(message) : span_notice(message))

		log_game("[key_name(action_owner)] [remove ? "REMOVE self from" : "ADD self to"] ghost role distribution list.")
	else
		Remove(action_owner)
		return

	UpdateButtons()
