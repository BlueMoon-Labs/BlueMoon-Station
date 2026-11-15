/mob/dead/observer
	right_click_actions = TRUE

/// Второе действие призрака - то же, что двойной ЛКМ, кроме возврата в тело: следовать за объектом или перейти на клетку
/mob/dead/observer/proc/ghost_right_click(atom/A)
	if(ismovable(A) && A != src)
		ManualFollow(A)
	else
		var/turf/destination = get_turf(A)
		if(!destination)
			return
		forceMove(destination)
	leave_observed_view()

/// Призрак сам ушёл с места: камера возвращается к нему, а не остаётся на том, чьими глазами он смотрел
/mob/dead/observer/proc/leave_observed_view()
	if(observetarget)
		reset_perspective(null)

/// Смотреть глазами цели, как из окна орбиты: призрак на её орбите, и любой шаг сходит с орбиты и возвращает камеру
/mob/dead/observer/proc/observe_with_orbit(mob/target)
	ManualFollow(target)
	// без орбиты из наблюдения не выйти шагом
	if(orbiting?.parent != target)
		return
	reset_perspective(null)
	do_observe(target)
	to_chat(src, span_notice("Теперь вы видите то же, что и [target]. Чтобы вернуться, сделайте шаг или выберите в меню «Перестать смотреть [target.ru_ego()] глазами»."))

/// Как сделать то же без меню: второе действие или двойной ЛКМ
/mob/dead/observer/proc/ghost_follow_hint()
	var/hint = right_click_action_hint()
	return hint == "ПКМ в бою" ? "двойной ЛКМ" : hint

/mob/dead/observer/proc/is_own_body(atom/A)
	var/mob/body = mind?.current
	return can_reenter_corpse && body && (A == body || (body in A))

/// Что сделает ЛКМ призрака (attack_ghost) по этому атому; null - ничего, о чём стоит писать в меню
/atom/proc/ghost_click_label(mob/dead/observer/ghost)
	return IsAdminGhost(ghost) ? "Взаимодействовать как ИИ" : null

/turf/ghost_click_label(mob/dead/observer/ghost)
	return null

/turf/open/space/ghost_click_label(mob/dead/observer/ghost)
	return destination_z ? "Перелететь дальше" : null

/turf/closed/indestructible/hoteldoor/ghost_click_label(mob/dead/observer/ghost)
	return parentSphere ? "Выйти из номера" : null

/obj/ghost_click_label(mob/dead/observer/ghost)
	return ..() || "Взаимодействовать"

/obj/effect/mob_spawn/ghost_click_label(mob/dead/observer/ghost)
	return ghost_usable && loc ? "Занять роль" : null

/obj/item/mmi/posibrain/ghost_click_label(mob/dead/observer/ghost)
	return QDELETED(brainmob) || is_occupied() ? null : "Занять роль"

/obj/item/drone_shell/ghost_click_label(mob/dead/observer/ghost)
	return "Занять роль"

/obj/item/clockwork/construct_chassis/ghost_click_label(mob/dead/observer/ghost)
	return "Занять роль"

/obj/structure/ash_walker_eggshell/ghost_click_label(mob/dead/observer/ghost)
	return egg ? "Занять роль" : ..()

/mob/living/ghost_click_label(mob/dead/observer/ghost)
	return ghost.health_scan ? "Проверить здоровье" : ..()

/mob/living/simple_animal/ghost_click_label(mob/dead/observer/ghost)
	return playable_by_ghost && !key && !stat ? "Вселиться" : ..()

/mob/living/simple_animal/hostile/poison/giant_spider/ghost_click_label(mob/dead/observer/ghost)
	return playable_spider && !key && !stat ? "Вселиться" : ..()

/mob/living/simple_animal/hostile/venus_human_trap/ghost_click_label(mob/dead/observer/ghost)
	return playable_plant && !key && !stat ? "Вселиться" : ..()

// эти три attack_ghost не зовут родителя: ни скана здоровья, ни ИИ, только вселение
/mob/living/simple_animal/banana_spider/ghost_click_label(mob/dead/observer/ghost)
	return key ? null : "Вселиться"

/mob/living/simple_animal/hostile/bread/ghost_click_label(mob/dead/observer/ghost)
	return key ? null : "Вселиться"

/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/ghost_click_label(mob/dead/observer/ghost)
	if(key || stat == DEAD || spider_awaymission || !ai_playercontrol_allowtype || degenerate || (ghost.ckey in GLOB.ts_ckey_blacklist))
		return null
	return "Вселиться"

/mob/living/simple_animal/hostile/swarmer/mega/ghost_click_label(mob/dead/observer/ghost)
	var/obj/effect/mob_spawn/swarmer_mega/spawner = locate() in contents
	return spawner?.ghost_usable ? spawner.ghost_click_label(ghost) : ..()

/mob/living/carbon/true_devil/ghost_click_label(mob/dead/observer/ghost)
	return ascended || (ghost.mind && ghost.mind.soulOwner == mind) ? "Стать бесом" : ..()

/// Пункты призрака вместо действий живого: интентов, рук и вербов вещей у него нет
/datum/context_menu/proc/add_ghost_entries(atom/A, list/result, list/shown_clicks)
	var/mob/dead/observer/ghost = user
	if(ghost.is_own_body(A))
		result += new /datum/context_menu_entry/ghost_reenter("Вернуться в тело", "двойной ЛКМ", CONTEXT_ENTRY_CURRENT)
	var/click_label = A == ghost ? null : A.ghost_click_label(ghost)
	if(click_label)
		add_click(result, shown_clicks, A, click_label, "ЛКМ", "left=1")
	if(ismovable(A) && A != ghost)
		if(ghost.orbiting?.parent == A)
			result += new /datum/context_menu_entry/ghost_unfollow("Перестать следовать", null, CONTEXT_ENTRY_CURRENT)
		else
			result += new /datum/context_menu_entry/ghost_follow("Следовать", ghost.ghost_follow_hint(), CONTEXT_ENTRY_NORMAL)
	if(ismob(A) && A != ghost)
		if(ghost.observetarget == A)
			result += new /datum/context_menu_entry/ghost_stop_observe("Перестать смотреть [A.ru_ego()] глазами", null, CONTEXT_ENTRY_CURRENT)
		else
			result += new /datum/context_menu_entry/ghost_observe("Смотреть [A.ru_ego()] глазами", null, CONTEXT_ENTRY_NORMAL)
	var/datum/context_menu_entry/jump_entry = new /datum/context_menu_entry/ghost_jump("Перейти сюда", isturf(A) ? ghost.ghost_follow_hint() : null, CONTEXT_ENTRY_NORMAL)
	// голый пол и сам призрак меню не открывают, как и у живых: перейти туда можно и без меню
	jump_entry.filler = isturf(A) || A == ghost
	result += jump_entry

/datum/context_menu_entry/ghost_follow

/datum/context_menu_entry/ghost_follow/execute(mob/dead/observer/user, atom/movable/target)
	if(isobserver(user) && ismovable(target) && target != user)
		user.ManualFollow(target)
		user.leave_observed_view()

/datum/context_menu_entry/ghost_unfollow

/datum/context_menu_entry/ghost_unfollow/execute(mob/dead/observer/user, atom/target)
	if(isobserver(user) && user.orbiting?.parent == target)
		user.orbiting.end_orbit(user)

/datum/context_menu_entry/ghost_observe

/datum/context_menu_entry/ghost_observe/execute(mob/dead/observer/user, mob/target)
	if(isobserver(user) && ismob(target) && target != user)
		user.observe_with_orbit(target)

/datum/context_menu_entry/ghost_stop_observe

/datum/context_menu_entry/ghost_stop_observe/execute(mob/dead/observer/user, atom/target)
	if(isobserver(user) && user.observetarget)
		user.reset_perspective(null)

/datum/context_menu_entry/ghost_jump

/datum/context_menu_entry/ghost_jump/execute(mob/dead/observer/user, atom/target)
	var/turf/destination = get_turf(target)
	if(isobserver(user) && destination)
		user.forceMove(destination)
		user.leave_observed_view()

/datum/context_menu_entry/ghost_reenter

/datum/context_menu_entry/ghost_reenter/execute(mob/dead/observer/user, atom/target)
	if(isobserver(user) && user.is_own_body(target))
		INVOKE_ASYNC(user, /mob/dead/observer/verb/reenter_corpse)
