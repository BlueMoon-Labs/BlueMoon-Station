GLOBAL_LIST_INIT(bluemoon_mentor_verbs, list(
	/client/proc/cmd_mentor_cancel_camera,
	/client/proc/open_mentor_ticket_panel
))
GLOBAL_PROTECT(bluemoon_mentor_verbs)

/client/add_mentor_verbs()
	. = ..()
	if(mentor_datum)
		add_verb(src, GLOB.bluemoon_mentor_verbs)

/client/remove_mentor_verbs()
	. = ..()
	remove_verb(src, GLOB.bluemoon_mentor_verbs)

/client/proc/cmd_mentor_cancel_camera()
	set category = "Mentor"
	set name = "Cancel Camera View"
	if(!is_mentor())
		return
	mob?.cancel_camera()

/client/proc/open_mentor_ticket_panel()
	set category = "Mentor"
	set name = "Mentor Ticket Panel"
	if(!is_mentor())
		return
	var/datum/mentor_ticket_panel/panel = new()
	panel.ui_interact(usr)
