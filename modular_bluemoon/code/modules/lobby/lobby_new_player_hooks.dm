/datum/hud/new_player

/datum/hud/new_player/proc/populate_buttons(mob/dead/new_player/owner)

/mob/dead/new_player/create_mob_hud()
	return

/mob/dead/new_player/proc/new_player_panel()
	return

/mob/dead/new_player/close_spawn_windows()
	bm_hide_lobby()
	return ..()

/mob/dead/new_player/Logout()
	bm_assets_sent = FALSE
	bm_lobby_ready = FALSE
	bm_lobby_music_path = ""
	bm_lobby_track_name = ""
	return ..()

/mob/dead/new_player/reset_menu_hud()
	set hidden = 1
	if(!client)
		return
	bm_show_lobby()

/client/proc/bm_push_lobby_music()
	var/mob/dead/new_player/player = mob
	if(!istype(player))
		return
	if(!(prefs?.toggles & SOUND_LOBBY))
		return
	var/music_path = player.bm_lobby_music_path
	var/track_name = player.bm_lobby_track_name
	if(!music_path)
		music_path = SSticker?.login_music
		if(music_path)
			// Сохраняем чтобы _lobby_tick не повторял доставку
			player.bm_lobby_music_path = music_path
	if(!music_path || !fexists(music_path))
		return
	if(!track_name)
		track_name = music_path
		var/last_slash = findlasttext(track_name, "/")
		if(last_slash)
			track_name = copytext(track_name, last_slash + 1)
		var/dot_pos = findlasttext(track_name, ".")
		if(dot_pos > 1)
			track_name = copytext(track_name, 1, dot_pos)
		track_name = replacetext(replacetext(track_name, "_", " "), "-", " ")
		// Сохраняем имя трека для повторных вызовов
		player.bm_lobby_track_name = track_name
	src << browse(fcopy_rsc(music_path), "file=bm_lobby_music.ogg;display=0")
	src << output("bm_lobby_music.ogg", "bm_lobby_browser:bm_load_audio")
	if(track_name)
		src << output(track_name, "bm_lobby_browser:bm_set_audio_track")

/client/playtitlemusic(vol = 85)
	if(!istype(mob, /mob/dead/new_player))
		return ..()
