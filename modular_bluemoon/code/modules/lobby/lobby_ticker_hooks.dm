/datum/controller/subsystem/title_bm/proc/_on_enter_pregame()
	SIGNAL_HANDLER
	_rotate_current_images()  // выбираем случайную картинку один раз при старте прегейма
	change_image(null)
	deltimer(lobby_tick_timer)
	last_online_count = -1
	last_ready_count = -1
	lobby_tick_timer = addtimer(CALLBACK(src, PROC_REF(_lobby_tick)), 15 SECONDS, TIMER_LOOP | TIMER_STOPPABLE)

/datum/controller/subsystem/title_bm/proc/_lobby_tick()
	if(!length(GLOB.new_player_list))
		return
	update_player_counts_all()
	if(!SSticker?.login_music)
		return
	for(var/mob/dead/new_player/player as anything in GLOB.new_player_list)
		if(!player.bm_lobby_ready || !player.client || player.bm_lobby_music_path)
			continue
		player.client.bm_push_lobby_music()

/datum/controller/subsystem/title_bm/proc/_on_enter_setting_up()
	SIGNAL_HANDLER
	deltimer(lobby_tick_timer) // pregame-таймер больше не нужен — Players spawn out
	deltimer(refresh_timer)
	refresh_timer = addtimer(CALLBACK(src, PROC_REF(_refresh_all_lobby_html)), 0.5 SECONDS, TIMER_STOPPABLE)

/datum/controller/subsystem/title_bm/proc/_refresh_all_lobby_html()
	for(var/mob/dead/new_player/player as anything in GLOB.new_player_list)
		if(player.spawning || player.new_character)
			continue
		if(!player.client)
			continue
		INVOKE_ASYNC(player, TYPE_PROC_REF(/mob/dead/new_player, bm_update_lobby_html))

