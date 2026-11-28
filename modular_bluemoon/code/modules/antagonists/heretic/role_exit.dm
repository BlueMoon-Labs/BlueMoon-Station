/datum/antagonist/heretic
	/// Когда выдана роль: от неё можно отказаться в первые HERETIC_ROLE_ABANDON_WINDOW.
	var/role_gained_at = 0
	/// Когда выбран путь: сменить его можно в первые HERETIC_PATH_RESET_WINDOW.
	var/path_selected_at = 0
	var/path_reset_used = FALSE
	/// Очки, потраченные на ступени и пассивки текущего пути: сброс возвращает их как были.
	var/path_spent_knowledge = 0
	var/path_spent_side = 0
	/// Ступень дела старого пути: новое дело начинается с неё, награды ступеней не выдаются дважды.
	var/carried_deed_tier = 0
	/// Роль куплена жетоном метамагазина: при отказе потраченные М$ не возвращаются.
	var/granted_by_token = FALSE

/datum/antagonist/heretic/proc/role_exit_block_reason()
	if(simulated)
		return "На полигоне путь и роль меняет сам полигон."
	if(role_removed)
		return "Сейчас это недоступно."
	if(ascended)
		return "Вознёсшийся уже не может отступить."
	if(total_sacrifices)
		return "После первой жертвы дороги назад нет."
	if(pocket?.active)
		return "Сначала покиньте изнанку."
	return null

/datum/antagonist/heretic/proc/path_reset_error()
	. = role_exit_block_reason()
	if(.)
		return
	if(!selected_path)
		return "Путь ещё не выбран."
	if(path_reset_used)
		return "Путь уже меняли: второй раз Мансус не отпустит."
	if(world.time - path_selected_at > HERETIC_PATH_RESET_WINDOW)
		return "С выбора пути прошло больше [DisplayTimeText(HERETIC_PATH_RESET_WINDOW)]."

/datum/antagonist/heretic/proc/role_abandon_error()
	. = role_exit_block_reason()
	if(.)
		return
	if(world.time - role_gained_at > HERETIC_ROLE_ABANDON_WINDOW)
		return "С получения роли прошло больше [DisplayTimeText(HERETIC_ROLE_ABANDON_WINDOW)]: отказаться теперь можно только через администрацию (F1)."

/datum/antagonist/heretic/proc/role_exit_data()
	var/reset_reason = path_reset_error()
	var/abandon_reason = role_abandon_error()
	return list(
		"can_reset" = !reset_reason,
		"reset_reason" = reset_reason,
		"can_abandon" = !abandon_reason,
		"abandon_reason" = abandon_reason,
		"reset_possible" = !simulated && !role_removed && !ascended && !total_sacrifices && !path_reset_used,
		"token_role" = granted_by_token,
		"reset_window" = HERETIC_PATH_RESET_WINDOW / (1 MINUTES),
		"abandon_window" = HERETIC_ROLE_ABANDON_WINDOW / (1 MINUTES),
	)

/datum/antagonist/heretic/proc/can_use_role_exit(mob/living/user)
	return user && user.mind == owner && IS_HERETIC(user) == src && !heretic_incapacitated(user)

/// Игрок перепутал путь: один раз в первые минуты и до первой жертвы.
/datum/antagonist/heretic/proc/reset_path(mob/living/user)
	if(!can_use_role_exit(user))
		return FALSE
	var/error_message = path_reset_error()
	if(error_message)
		to_chat(user, span_warning(error_message))
		return FALSE
	var/datum/heretic_path/old_path = GLOB.heretic_paths[selected_path]
	var/held_for = DisplayTimeText(world.time - path_selected_at)
	var/list/refund = release_path(user)
	path_reset_used = TRUE
	to_chat(user, span_eldritch("Путь «[old_path.name]» отпускает вас. Вернулось очков знаний: [refund[1]], побочных: [refund[2]]; ступень дела сохранена[refund[3] ? ", клинки старого пути рассыпались" : ""]. Выберите новый путь в главе «Путь»: второй раз сменить его не выйдет."))
	log_game("[key_name(user)] сбрасывает путь [old_path.id] через [held_for] после выбора: возвращено [refund[1]] очков и [refund[2]] побочных.")
	message_admins("[ADMIN_LOOKUPFLW(user)] сменил путь еретика: отпустил путь «[old_path.name]».")
	return TRUE

/datum/antagonist/heretic/proc/admin_reset_path(mob/admin)
	var/datum/heretic_path/old_path = GLOB.heretic_paths[selected_path]
	if(!old_path || role_removed)
		to_chat(admin, span_warning("У еретика нет выбранного пути."))
		return
	if(ascended)
		to_chat(admin, span_warning("Еретик уже вознёсся: сброс оставил бы вознесение без пути. Снимите роль целиком, если нужно."))
		return
	if(simulated)
		to_chat(admin, span_warning("Это учебный еретик полигона: путь меняет пульт полигона."))
		return
	var/list/refund = release_path(owner?.current)
	to_chat(owner?.current, span_eldritch("Путь «[old_path.name]» отпускает вас: изученное вернулось очками знаний[refund[3] ? ", клинки старого пути рассыпались" : ""]. Выберите новый путь в кодексе."))
	message_admins("[key_name_admin(admin)] сбросил путь «[old_path.name]» еретику [key_name_admin(owner)].")
	log_admin("[key_name(admin)] сбросил путь [old_path.id] еретику [key_name(owner)]: возвращено [refund[1]] очков и [refund[2]] побочных.")

/// Снимает знания пути и возвращает за них очки. Общие и побочные знания остаются. Возвращает list(очки, побочные, рассыпано клинков).
/datum/antagonist/heretic/proc/release_path(mob/living/body)
	var/datum/heretic_path/old_path = GLOB.heretic_paths[selected_path]
	var/crumbled = 0
	for(var/knowledge_type in old_path?.knowledge)
		var/datum/eldritch_knowledge/knowledge = researched_knowledge[knowledge_type]
		if(!knowledge)
			continue
		researched_knowledge -= knowledge_type
		crumbled += crumble_released_blades(knowledge)
		knowledge.on_lose(body)
		qdel(knowledge)
	. = list(path_spent_knowledge, path_spent_side, crumbled)
	knowledge_points += path_spent_knowledge
	side_knowledge_points += path_spent_side
	path_spent_knowledge = 0
	path_spent_side = 0
	if(deed)
		carried_deed_tier = max(carried_deed_tier, deed.tier)
		QDEL_NULL(deed)
	selected_path = null
	path_stage = 0
	refresh_evolution()
	path_selected_at = 0
	ability_hotkey_types = list(/obj/effect/proc_holder/spell/targeted/touch/mansus_grasp)
	collect_combat_spells(list())
	update_combat_resource_alert(FALSE, body)
	if(body)
		attune_robes(body)
	refresh_book_ui()

/// Клинки снятого пути рассыпаются: иначе новый путь начинал счёт с нуля, и сброс давал клинки сверх HERETIC_BLADE_LIMIT.
/datum/antagonist/heretic/proc/crumble_released_blades(datum/eldritch_knowledge/knowledge)
	var/crumbled = 0
	for(var/datum/weakref/blade_ref as anything in LAZYCOPY(knowledge.created_blades))
		var/obj/item/melee/sickly_blade/blade = blade_ref?.resolve()
		if(QDELETED(blade))
			continue
		knowledge.crumble_blade(blade, "при сбросе пути")
		crumbled++
	if(crumbled)
		log_game("HERETIC BLADE: сброс пути [key_name(owner)] рассыпал клинков старого пути: [crumbled].")
	return crumbled

/// Игрок не хочет играть еретиком: в первые минуты и до первой жертвы. Страховка директора вернёт цену роли.
/datum/antagonist/heretic/proc/abandon_role(mob/living/user)
	if(!can_use_role_exit(user))
		return FALSE
	var/error_message = role_abandon_error()
	if(error_message)
		to_chat(user, span_warning(error_message))
		return FALSE
	var/datum/mind/leaving = owner
	var/held_for = DisplayTimeText(world.time - role_gained_at)
	var/from_token = granted_by_token
	leaving.declined_antag_role = TRUE
	var/refund_note = from_token ? "роль куплена жетоном метамагазина, М$ не возвращаются" : "если роль выдал директор, через [DisplayTimeText(DIRECTOR_ANTAG_LOSS_GRACE)] страховка вернёт неотработанную часть её цены"
	message_admins("[ADMIN_LOOKUPFLW(user)] сам отказался от роли еретика через [held_for] после выдачи. Мидраунд-инжекции его больше не выберут; [refund_note].")
	log_game("[key_name(user)] отказывается от роли еретика через [held_for] после выдачи[from_token ? " (роль с жетона метамагазина)" : ""].")
	leaving.remove_antag_datum(/datum/antagonist/heretic)
	to_chat(user, span_notice("Вы отказались от роли еретика и снова обычный член экипажа: цели и знания ушли. Скрытую роль посреди раунда вам больше не предложат.[from_token ? " Жетон потрачен: М$ за него не возвращаются." : ""]"))
	return TRUE
