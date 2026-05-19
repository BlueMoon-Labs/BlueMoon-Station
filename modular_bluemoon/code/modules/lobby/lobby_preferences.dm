/datum/preferences
	var/bm_lobby_show_nsfw = FALSE
	var/bm_lobby_show_admin_bg = TRUE

/datum/preferences/proc/_bm_push_name_to_lobby()
	var/client/C = parent
	if(!istype(C))
		return
	if(!isnewplayer(C.mob))
		return
	var/mob/dead/new_player/player = C.mob
	if(SStitle_bm && player.bm_lobby_ready)
		SStitle_bm.update_character_name(player, real_name)

/datum/preferences/save_character(bypass_cooldown = FALSE, silent = FALSE, export = FALSE)
	. = ..()
	if(!istype(., /savefile))
		return
	if(export)
		return
	_bm_push_name_to_lobby()

/datum/preferences/load_character(slot, bypass_cooldown = FALSE, savefile/provided)
	. = ..()
	if(!.)
		return
	_bm_push_name_to_lobby()

/datum/preferences/save_preferences(bypass_cooldown = FALSE, silent = FALSE)
	. = ..()
	if(!istype(., /savefile))
		return FALSE
	WRITE_FILE(.["bm_lobby_show_nsfw"], bm_lobby_show_nsfw)
	WRITE_FILE(.["bm_lobby_show_admin_bg"], bm_lobby_show_admin_bg)
	WRITE_FILE(.["connection_telemetry_history"], json_encode(connection_telemetry_history))
	return .

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
	var/telemetry_history_json
	.["connection_telemetry_history"] >> telemetry_history_json
	connection_telemetry_history = sanitize_connection_telemetry_history(json_decode(telemetry_history_json))
	return .
