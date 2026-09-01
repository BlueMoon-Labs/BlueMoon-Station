/client/proc/admin_end_shift()
	set category = "Admin.Shuttles"
	set name = "End shift"
	set desc = "Calls the shuttle as if a roundend vote passed."

	if(EMERGENCY_AT_LEAST_DOCKED)
		return

	if(!check_rights(R_ADMIN))
		return

	var/confirm = alert(src, "End the shift?", "Confirm", "Yes", "No")
	if(confirm != "Yes")
		return

	SSshuttle.autoEnd()
	SSblackbox.record_feedback("tally", "admin_verb", 1, "End Shift") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!
	log_admin("[key_name(usr)] ended the shift.")
	message_admins("<span class='adminnotice'>[key_name_admin(usr)] ended the shift.</span>")
	return
