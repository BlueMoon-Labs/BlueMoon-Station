/client/proc/cmd_mentor_dementor()
	set category = "Mentor"
	set name = "Dementor"
	if(!is_mentor())
		return
	// Флаг, а не только выход из GLOB.mentors: админы получают менторский
	// трафик через GLOB.admins, и без флага Dementor для них не работал.
	dementored = TRUE
	remove_mentor_verbs()
	if (/client/proc/mentor_unfollow in verbs)
		mentor_unfollow()
	GLOB.mentors -= src
	add_verb(src, /client/proc/cmd_mentor_rementor)
	to_chat(src, "<span class='mentornotice'>Вы больше не получаете менторские уведомления. Верните их вербом Rementor.</span>", confidential = TRUE)

/client/proc/cmd_mentor_rementor()
	set category = "Mentor"
	set name = "Rementor"
	if(!is_mentor())
		return
	dementored = FALSE
	add_mentor_verbs()
	if(!check_rights_for(src, R_ADMIN, 0)) // админов в GLOB.mentors не держим (см. mentor_datum_set)
		GLOB.mentors |= src
	remove_verb(src, /client/proc/cmd_mentor_rementor)
	to_chat(src, "<span class='mentornotice'>Менторские уведомления снова включены.</span>", confidential = TRUE)
