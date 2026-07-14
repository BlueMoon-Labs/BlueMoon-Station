GLOBAL_LIST_INIT(super_mentor_verbs, list(
	/client/proc/cmd_mentor_aghost,
	/client/proc/cmd_mentor_view_variables,
))
GLOBAL_PROTECT(super_mentor_verbs)

/client/add_mentor_verbs()
	. = ..()
	if(mentor_datum && is_super_mentor())
		add_verb(src, GLOB.super_mentor_verbs)

/client/remove_mentor_verbs()
	. = ..()
	remove_verb(src, GLOB.super_mentor_verbs)

/client/proc/cmd_mentor_aghost()
	set category = "Mentor"
	set name = "Aghost"
	set desc = "Перейти в режим наблюдателя или вернуться в тело."
	if(!is_super_mentor())
		return
	if(isobserver(mob))
		var/mob/dead/observer/ghost = mob
		if(!ghost.mind?.current)
			return
		if(!ghost.can_reenter_corpse)
			log_mentor("[key_name(usr)] re-entered corpse")
		ghost.can_reenter_corpse = TRUE
		ghost.reenter_corpse()
	else if(isnewplayer(mob))
		to_chat(src, span_danger("Error: Aghost: Can't admin-ghost whilst in the lobby. Join or Observe first."))
		return
	else
		log_mentor("[key_name(usr)] mentor ghosted.")
		var/mob/body = mob
		body.ghostize(1, voluntary = TRUE)
		init_verbs()
		if(body && !body.key)
			body.key = "@[key]"

/client/proc/cmd_mentor_view_variables(datum/thing in world)
	set category = "Mentor"
	set name = "View Variables"
	set desc = "Просмотр переменных объекта (только чтение)."
	if(!is_super_mentor())
		return
	debug_variables(thing)
