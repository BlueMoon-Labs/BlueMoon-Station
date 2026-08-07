/datum/admins/proc/player_panel_new()
	if(!check_rights())
		return
	log_admin("[key_name(usr)] checked the player panel in [usr.loc] and X:[usr.x] Y:[usr.y] Z:[usr.z] coordinate.")
	var/datum/admin_player_list/PL = new
	PL.ui_interact(usr)
