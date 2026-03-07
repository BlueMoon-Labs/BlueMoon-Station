/datum/preferences
	var/bm_lobby_show_nsfw = FALSE
	var/bm_lobby_show_admin_bg = TRUE

/datum/preferences/save_preferences(bypass_cooldown = FALSE, silent = FALSE)
	. = ..()
	if(!istype(., /savefile))
		return FALSE
	WRITE_FILE(.["bm_lobby_show_nsfw"], bm_lobby_show_nsfw)
	WRITE_FILE(.["bm_lobby_show_admin_bg"], bm_lobby_show_admin_bg)

/datum/preferences/load_preferences(bypass_cooldown = FALSE)
	. = ..()
	if(!istype(., /savefile))
		return FALSE
	.["bm_lobby_show_nsfw"] >> bm_lobby_show_nsfw
	if(isnull(bm_lobby_show_nsfw))
		bm_lobby_show_nsfw = FALSE
	bm_lobby_show_nsfw = !!bm_lobby_show_nsfw
	.["bm_lobby_show_admin_bg"] >> bm_lobby_show_admin_bg
	if(isnull(bm_lobby_show_admin_bg))
		bm_lobby_show_admin_bg = TRUE
	bm_lobby_show_admin_bg = !!bm_lobby_show_admin_bg
