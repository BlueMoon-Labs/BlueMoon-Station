/client/proc/cmd_mentor_dementor()
	set category = "Mentor"
	set name = "Dementor"
	if(!is_super_mentor())
		return
	remove_mentor_verbs()
	if (/client/proc/mentor_unfollow in verbs)
		mentor_unfollow()
	GLOB.mentors -= src
	add_verb(src, /client/proc/cmd_mentor_rementor)

/client/proc/cmd_mentor_rementor()
	set category = "Mentor"
	set name = "Rementor"
	if(!is_super_mentor())
		return
	add_mentor_verbs()
	if(is_super_mentor() && !check_rights_for(src, R_ADMIN, 0))
		GLOB.mentors |= src
	remove_verb(src, /client/proc/cmd_mentor_rementor)
