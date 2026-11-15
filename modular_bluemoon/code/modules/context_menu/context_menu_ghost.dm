/mob/dead/observer
	right_click_actions = TRUE

/// Второе действие призрака - то же, что двойной ЛКМ, кроме возврата в тело: следовать за объектом или перейти на клетку
/mob/dead/observer/proc/ghost_right_click(atom/A)
	if(ismovable(A) && A != src)
		ManualFollow(A)
		return
	var/turf/destination = get_turf(A)
	if(destination)
		forceMove(destination)

/// Как сделать то же без меню: второе действие или двойной ЛКМ
/mob/dead/observer/proc/ghost_follow_hint()
	var/hint = right_click_action_hint()
	return hint == "ПКМ в бою" ? "двойной ЛКМ" : hint

/mob/dead/observer/proc/is_own_body(atom/A)
	var/mob/body = mind?.current
	return can_reenter_corpse && body && (A == body || (body in A))

/// Пункты призрака вместо действий живого: интентов, рук и вербов вещей у него нет
/datum/context_menu/proc/add_ghost_entries(atom/A, list/result, list/shown_clicks)
	var/mob/dead/observer/ghost = user
	if(ghost.is_own_body(A))
		result += new /datum/context_menu_entry/ghost_reenter("Вернуться в тело", "двойной ЛКМ", CONTEXT_ENTRY_CURRENT)
	if(isobj(A))
		add_click(result, shown_clicks, A, "Взаимодействовать", "ЛКМ", "left=1")
	else if(isliving(A) && ghost.health_scan)
		add_click(result, shown_clicks, A, "Проверить здоровье", "ЛКМ", "left=1")
	if(ismovable(A) && A != ghost)
		if(ghost.orbiting?.parent == A)
			result += new /datum/context_menu_entry/ghost_unfollow("Перестать следовать", null, CONTEXT_ENTRY_CURRENT)
		else
			result += new /datum/context_menu_entry/ghost_follow("Следовать", ghost.ghost_follow_hint(), CONTEXT_ENTRY_NORMAL)
	if(ismob(A) && A != ghost)
		if(ghost.observetarget == A)
			result += new /datum/context_menu_entry/ghost_stop_observe("Перестать смотреть его глазами", null, CONTEXT_ENTRY_CURRENT)
		else
			result += new /datum/context_menu_entry/ghost_observe("Смотреть его глазами", null, CONTEXT_ENTRY_NORMAL)
	var/datum/context_menu_entry/jump_entry = new /datum/context_menu_entry/ghost_jump("Перейти сюда", isturf(A) ? ghost.ghost_follow_hint() : null, CONTEXT_ENTRY_NORMAL)
	// голый пол меню не открывает, как и у живых: перейти туда можно и без меню
	jump_entry.filler = isturf(A)
	result += jump_entry

/datum/context_menu_entry/ghost_follow

/datum/context_menu_entry/ghost_follow/execute(mob/dead/observer/user, atom/movable/target)
	if(isobserver(user) && ismovable(target) && target != user)
		user.ManualFollow(target)

/datum/context_menu_entry/ghost_unfollow

/datum/context_menu_entry/ghost_unfollow/execute(mob/dead/observer/user, atom/target)
	if(isobserver(user) && user.orbiting?.parent == target)
		user.orbiting.end_orbit(user)

/datum/context_menu_entry/ghost_observe

/datum/context_menu_entry/ghost_observe/execute(mob/dead/observer/user, mob/target)
	if(!isobserver(user) || !ismob(target) || target == user)
		return
	user.reset_perspective(null)
	user.do_observe(target)

/datum/context_menu_entry/ghost_stop_observe

/datum/context_menu_entry/ghost_stop_observe/execute(mob/dead/observer/user, atom/target)
	if(isobserver(user) && user.observetarget)
		user.reset_perspective(null)

/datum/context_menu_entry/ghost_jump

/datum/context_menu_entry/ghost_jump/execute(mob/dead/observer/user, atom/target)
	var/turf/destination = get_turf(target)
	if(isobserver(user) && destination)
		user.forceMove(destination)

/datum/context_menu_entry/ghost_reenter

/datum/context_menu_entry/ghost_reenter/execute(mob/dead/observer/user, atom/target)
	if(isobserver(user) && user.is_own_body(target))
		INVOKE_ASYNC(user, /mob/dead/observer/verb/reenter_corpse)
