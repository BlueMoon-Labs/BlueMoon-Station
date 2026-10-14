GLOBAL_DATUM_INIT(shift_invite_link, /datum/shift_invite_link, new)

/// Получатель ссылки "Войти в смену" из приглашений: действует только над тем, кто нажал.
/datum/shift_invite_link

/datum/shift_invite_link/Topic(href, list/href_list)
	if(!href_list["join_shift"])
		return
	var/mob/user = usr
	if(!user?.client)
		return
	user.try_join_shift()

/// Живой посетитель гост-кафе, который может уйти в призраки без штрафа.
/proc/is_ghost_cafe_visitor(mob/living/target)
	if(!isliving(target) || target.stat == DEAD || !target.mind?.has_antag_datum(/datum/antagonist/ghost_role/ghost_cafe))
		return FALSE
	var/datum/element/ghost_role_eligibility/eligibility = get_ghost_role_eligibility_element(target)
	return !!eligibility?.free_ghost

/// Путь "Войти в смену": ссылка из приглашения и кнопка наблюдателя. Проверки респавна и джоббаны не обходятся.
/mob/proc/try_join_shift()
	to_chat(src, span_warning("Войти в смену можно из лобби, наблюдателем или из гост-кафе."))
	return FALSE

/mob/dead/new_player/try_join_shift()
	if(!client || !age_verify())
		return FALSE
	if(!SSticker?.IsRoundInProgress())
		to_chat(src, span_warning("Раунд сейчас не идёт."))
		return FALSE
	LateChoices()
	return TRUE

/mob/dead/observer/try_join_shift()
	var/block_reason = respawn_block_reason(src, client?.prefs)
	if(block_reason)
		to_chat(src, span_warning(block_reason))
		return FALSE
	if(!client)
		return FALSE
	if(!SSticker?.IsRoundInProgress())
		to_chat(src, span_warning("Раунд сейчас не идёт."))
		return FALSE
	if(can_reenter_corpse && mind?.current && !QDELETED(mind.current))
		if(tgui_alert(src, "Если вернуться в лобби, в своё тело вы больше не попадёте. Войти в смену заново?", "Войти в смену", list("Войти", "Остаться")) != "Войти")
			return FALSE
		if(QDELETED(src) || !client || respawn_block_reason(src, client.prefs))
			return FALSE
	var/client/user_client = client
	log_game("[key_name(src)] вернулся в лобби через \"Войти в смену\"")
	if(!do_respawn(TRUE))
		return FALSE
	var/mob/dead/new_player/lobby_player = user_client?.mob
	if(!istype(lobby_player))
		return FALSE
	lobby_player.LateChoices()
	return TRUE

/mob/living/try_join_shift()
	if(!is_ghost_cafe_visitor(src))
		return ..()
	var/block_reason = respawn_block_reason(src, client?.prefs)
	if(block_reason)
		to_chat(src, span_warning(block_reason))
		return FALSE
	if(!SSticker?.IsRoundInProgress())
		to_chat(src, span_warning("Раунд сейчас не идёт."))
		return FALSE
	if(tgui_alert(src, "Покинуть гост-кафе и войти в смену? Персонаж кафе исчезнет, штрафа за выход нет.", "Войти в смену", list("Войти", "Остаться")) != "Войти")
		return FALSE
	if(QDELETED(src) || !client || !is_ghost_cafe_visitor(src))
		return FALSE
	var/client/user_client = client
	ghost()
	var/mob/dead/observer/new_ghost = user_client?.mob
	if(!isobserver(new_ghost))
		return FALSE
	return new_ghost.try_join_shift()

/// Кнопка наблюдателя: вернуться в лобби и сразу открыть список должностей.
/datum/action/join_shift
	name = "Войти в смену"
	desc = "Вернуться в лобби и выбрать должность. Задержки респавна, запреты режима и джоббаны действуют как обычно."
	icon_icon = 'icons/mob/actions/actions_minor_antag.dmi'
	button_icon_state = "join"

/datum/action/join_shift/Trigger(trigger_flags)
	if(!..())
		return FALSE
	INVOKE_ASYNC(owner, TYPE_PROC_REF(/mob, try_join_shift))
	return TRUE

/datum/preferences
	/// Получать приглашения в пустые критичные отделы
	var/shift_invites = TRUE

/datum/preferences/save_preferences(bypass_cooldown = FALSE, silent = FALSE)
	. = ..()
	if(!istype(., /savefile))
		return
	WRITE_FILE(.["shift_invites"], shift_invites)

/datum/preferences/load_preferences(bypass_cooldown = FALSE)
	. = ..()
	if(!istype(., /savefile))
		return
	.["shift_invites"] >> shift_invites
	shift_invites = isnull(shift_invites) ? TRUE : !!shift_invites
