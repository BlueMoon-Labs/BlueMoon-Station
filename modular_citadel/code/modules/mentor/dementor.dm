/client/proc/cmd_mentor_dementor()
	set category = "Mentor"
	set name = "Dementor"
	set desc = "Временно отключить менторские инструменты."
	if(!mentor_datum)
		return
	become_inactive_mentor()
