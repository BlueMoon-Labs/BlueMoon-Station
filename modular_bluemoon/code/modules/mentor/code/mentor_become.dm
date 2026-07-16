/client/proc/add_become_mentor_verb()
	if(!mentor_datum)
		return
	if(/client/proc/cmd_mentor_become in verbs)
		return
	add_verb(src, /client/proc/cmd_mentor_become)
	init_verbs()

/client/proc/remove_become_mentor_verb()
	remove_verb(src, /client/proc/cmd_mentor_become)

/client/proc/cmd_mentor_become()
	set category = "Mentor"
	set name = "Стать ментором"
	set desc = "Включить менторские инструменты и начать отвечать на обращения."
	if(!ensure_mentor_datum())
		return
	add_mentor_verbs()
	if(is_super_mentor() && !check_rights_for(src, R_ADMIN, 0))
		GLOB.mentors |= src
	remove_become_mentor_verb()
	init_verbs()
	log_mentor("[key_name(src)] became an active mentor.")

/client/proc/is_active_mentor()
	return mentor_datum && !(/client/proc/cmd_mentor_become in verbs)

/// Toggles mentor mode. Returns TRUE when mentor tools are now active.
/client/proc/toggle_active_mentor()
	if(!ensure_mentor_datum())
		return FALSE
	if(/client/proc/cmd_mentor_become in verbs)
		cmd_mentor_become()
		return TRUE
	become_inactive_mentor()
	return FALSE

/client/proc/become_inactive_mentor()
	remove_mentor_verbs()
	if(/client/proc/mentor_unfollow in verbs)
		mentor_unfollow()
	GLOB.mentors -= src
	add_become_mentor_verb()
	init_verbs()
	log_mentor("[key_name(src)] stopped being an active mentor.")
