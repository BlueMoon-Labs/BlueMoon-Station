// Configuration defines
#define TETRIS_REWARD_DIVISOR CONFIG_GET(number/tetris_reward_divisor)
#define TETRIS_PRIZES_MAX CONFIG_GET(number/tetris_prizes_max)
#define TETRIS_SCORE_HIGH CONFIG_GET(number/tetris_score_high)
#define TETRIS_SCORE_MAX CONFIG_GET(number/tetris_score_max)
#define TETRIS_SCORE_MAX_SCI CONFIG_GET(number/tetris_score_max_sci)
#define TETRIS_TIME_COOLDOWN CONFIG_GET(number/tetris_time_cooldown)
#define TETRIS_NO_SCIENCE CONFIG_GET(flag/tetris_no_science)

// Cooldown defines
#define TETRIS_COOLDOWN_MAIN cooldown_timer

/obj/machinery/computer/arcade/tetris
	name = "T.E.T.R.I.S."
	desc = "The pinnacle of human technology."
	circuit = /obj/item/circuitboard/computer/arcade/tetris
	COOLDOWN_DECLARE(TETRIS_COOLDOWN_MAIN)
	/// Кто сейчас играет (для остановки музыки при закрытии UI)
	var/mob/current_player = null
	/// Все еще защита от дурочков с href, разделяем состояние игры.
	var/game_active = FALSE
	var/mob/active_game_player = null

/obj/machinery/computer/arcade/tetris/ui_interact(mob/user, datum/tgui/ui)
	if(!isliving(user))
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ArcadeTetris", name)
		ui.open()

/// Останавливаем музыку при закрытии окна и сбрасываем состояние игры
/obj/machinery/computer/arcade/tetris/ui_close(mob/user)
	. = ..()
	stop_tetris_music(user)
	if(user == active_game_player)
		game_active = FALSE
		active_game_player = null

/// Запускаем случайный саундтрек в цикле
/obj/machinery/computer/arcade/tetris/proc/start_tetris_music(mob/user)
	if(!user?.client)
		return
	current_player = user
	var/track = pick(
		'modular_bluemoon/sound/machines/tetris/03.ogg',
		'modular_bluemoon/sound/machines/tetris/04.ogg',
		'modular_bluemoon/sound/machines/tetris/06.ogg',
		'modular_bluemoon/sound/machines/tetris/16.ogg',
		'modular_bluemoon/sound/machines/tetris/19.ogg',
		'modular_bluemoon/sound/machines/tetris/21.mp3',
		'modular_bluemoon/sound/machines/tetris/33.ogg',
		'modular_bluemoon/sound/machines/tetris/34.ogg')
	var/sound/S = sound(track, repeat = TRUE, wait = FALSE, volume = 40, channel = CHANNEL_TETRIS_MUSIC)
	SEND_SOUND(user, S)

/// Останавливаем музыку
/obj/machinery/computer/arcade/tetris/proc/stop_tetris_music(mob/user)
	if(!user)
		user = current_player
	if(user?.client)
		user.stop_sound_channel(CHANNEL_TETRIS_MUSIC)
	if(current_player == user)
		current_player = null

/// Проигрываем звуковой эффект на автомате
/obj/machinery/computer/arcade/tetris/proc/play_tetris_sfx(sfx_type)
	switch(sfx_type)
		if("move")
			playsound(src, 'modular_bluemoon/sound/machines/tetris/move_piece.ogg', 20, TRUE, extrarange = -5)
		if("rotate")
			playsound(src, 'modular_bluemoon/sound/machines/tetris/rotate_piece.ogg', 25, TRUE, extrarange = -5)
		if("drop")
			playsound(src, 'modular_bluemoon/sound/machines/tetris/piece_falling_after_line_clear.ogg', 30, TRUE, extrarange = -4)
		if("line_clear")
			playsound(src, 'modular_bluemoon/sound/machines/tetris/line_clear.ogg', 40, TRUE, extrarange = -3)
		if("tetris")
			playsound(src, 'modular_bluemoon/sound/machines/tetris/player_sending_blocks.ogg', 50, TRUE, extrarange = -3)
		if("level_up")
			playsound(src, 'modular_bluemoon/sound/machines/tetris/level_up_jingle.ogg', 45, TRUE, extrarange = -3)
		if("game_over")
			playsound(src, 'modular_bluemoon/sound/machines/tetris/game_over.ogg', 50, TRUE, extrarange = -2)
		if("high_score")
			playsound(src, 'modular_bluemoon/sound/machines/tetris/game_over.ogg', 55, TRUE, extrarange = -2)

/obj/machinery/computer/arcade/tetris/ui_data(mob/user)
	var/list/data = list()
	data["cooldownReady"] = COOLDOWN_FINISHED(src, TETRIS_COOLDOWN_MAIN)
	if(user?.client)
		data["personal_best"] = user.client.get_award_status(/datum/award/score/highscore/tetris) || 0
	else
		data["personal_best"] = 0
	var/datum/award/score/highscore/tetris/S = SSachievements.scores[/datum/award/score/highscore/tetris]
	var/list/leaderboard = list()
	if(S && S.high_scores.len)
		var/list/entries = list()
		for(var/ckey in S.high_scores)
			entries += list(list("ckey" = ckey, "score" = S.high_scores[ckey]))
		for(var/i = 1; i <= entries.len; i++)
			for(var/j = i + 1; j <= entries.len; j++)
				var/list/a = entries[i]
				var/list/b = entries[j]
				if(b["score"] > a["score"])
					entries[i] = b
					entries[j] = a
		var/rank = 0
		for(var/list/entry in entries)
			rank++
			leaderboard += list(list("rank" = rank, "ckey" = entry["ckey"], "score" = entry["score"]))
	data["leaderboard"] = leaderboard
	data["is_admin"] = check_rights_for(user?.client, R_ADMIN)
	return data

/obj/machinery/computer/arcade/tetris/ui_act(action, params)
	. = ..()
	if(.)
		return
	if(params["ic_advactivator"])
		return

	switch(action)
		if("sfx")
			play_tetris_sfx(params["type"])
			return TRUE
		if("music_start")
			if(game_active && usr != active_game_player)
				return FALSE
			game_active = TRUE
			active_game_player = usr
			start_tetris_music(usr)
			return TRUE
		if("music_stop")
			stop_tetris_music(usr)
			return TRUE
		if("submitScore")
			if(!game_active || usr != active_game_player)
				return FALSE
			game_active = FALSE
			active_game_player = null
			// Sanitize score as an integer
			// Restricts maximum score to (default) 100,000
			var/temp_score = sanitize_num_clamp(text2num(params["score"]), max=TETRIS_SCORE_MAX)

			if(usr?.client && SSachievements.achievements_enabled)
				usr.client.give_award(/datum/award/score/highscore/tetris, usr, temp_score)

			// Check for high score
			if(temp_score > TETRIS_SCORE_HIGH)
				play_tetris_sfx("high_score")
				// Alert admins
				message_admins("[ADMIN_LOOKUPFLW(usr)] [ADMIN_KICK(usr)] has achieved a score of [temp_score] on [src] in [get_area(src.loc)]! Score exceeds configured suspicion threshold.")

			// Round and clamp prize count from 0 to (default) 5
			var/reward_count = clamp(round(temp_score/TETRIS_REWARD_DIVISOR), 0, TETRIS_PRIZES_MAX)

			// Define score text
			var/score_text = (reward_count ? temp_score : "PATHETIC! TRY HARDER")

			// Display normal message
			say("YOUR SCORE: [score_text]!")

			// Check if any prize would be vended
			if(!reward_count)
				return TRUE

			// Check cooldown
			if(!COOLDOWN_FINISHED(src, TETRIS_COOLDOWN_MAIN))
				playsound(src, 'sound/machines/machine_vend.ogg', 50, TRUE, extrarange = -3)
				visible_message(span_notice("[src] sputters for a moment before going quiet."))
				return TRUE

			// Set cooldown time (ensure > 0 or cooldown would never finish)
			COOLDOWN_START(src, TETRIS_COOLDOWN_MAIN, max(1, TETRIS_TIME_COOLDOWN))

			// Vend prizes
			prizevend(usr, reward_count)

			// Check if science points are possible and allowed
			if((!SSresearch.science_tech) || TETRIS_NO_SCIENCE)
				return TRUE

			// Define user ID card
			var/obj/item/card/id/user_id = usr.get_idcard()

			// Check if ID exists and has science access
			if(istype(user_id) && (ACCESS_RESEARCH in user_id.access))
				// Limit maximum research points to (default) 10,000
				var/score_research_points = clamp(temp_score, 0, TETRIS_SCORE_MAX_SCI)

				// Add science points based on score
				SSresearch.science_tech.add_point_list(list(TECHWEB_POINT_TYPE_GENERIC = score_research_points))

				// Announce points earned
				say("Research personnel detected. Applying gathered data to algorithms...")
		if("deleteRecord")
			if(!check_rights_for(usr?.client, R_ADMIN))
				return FALSE
			var/datum/award/score/highscore/tetris/del_score = SSachievements.scores[/datum/award/score/highscore/tetris]
			if(!del_score)
				return FALSE
			return del_score.admin_delete_record(usr, ckey(params["ckey"]))

	add_fingerprint(usr)
	. = TRUE

// Remove defines
#undef TETRIS_REWARD_DIVISOR
#undef TETRIS_PRIZES_MAX
#undef TETRIS_SCORE_HIGH
#undef TETRIS_SCORE_MAX
#undef TETRIS_SCORE_MAX_SCI
#undef TETRIS_TIME_COOLDOWN
#undef TETRIS_NO_SCIENCE
#undef TETRIS_COOLDOWN_MAIN
