#define TETRIS_WEEKLY_REWARD_INTERVAL (7 * 24 HOURS)
#define TETRIS_WEEKLY_REWARD_CHECK_INTERVAL (5 MINUTES)
#define TETRIS_WEEKLY_REWARD_STATE_FILE "data/tetris_weekly_rewards.json"
#define TETRIS_WEEKLY_REWARD_PROGRESS_FILE "data/tetris_weekly_rewards_progress.json"

SUBSYSTEM_DEF(tetris_weekly_rewards)
	name = "Tetris Weekly Rewards"
	init_order = INIT_ORDER_ACHIEVEMENTS - 1
	wait = TETRIS_WEEKLY_REWARD_CHECK_INTERVAL
	flags = SS_BACKGROUND|SS_POST_FIRE_TIMING
	var/next_reset_realtime = 0
	var/processing_rewards = FALSE
	var/current_index = 1
	var/list/current_entries = list()
	var/list/paid_ckeys = list()
	var/list/granting_ckeys = list()
	var/current_cycle_started = 0
	var/leaderboard_reset_done = FALSE

/datum/controller/subsystem/tetris_weekly_rewards/Initialize()
	. = ..()
	load_state()
	load_progress()
	if(!next_reset_realtime)
		next_reset_realtime = next_monday_midnight()
		save_state()
	if(length(current_entries))
		processing_rewards = TRUE

/datum/controller/subsystem/tetris_weekly_rewards/fire(resumed = FALSE)
	if(processing_rewards)
		continue_reward_cycle()
		return
	if(world.realtime >= next_reset_realtime)
		begin_reward_cycle()

/datum/controller/subsystem/tetris_weekly_rewards/proc/load_state()
	var/json = file2text(TETRIS_WEEKLY_REWARD_STATE_FILE)
	if(!json)
		return
	var/list/data = json_decode(json)
	if(!islist(data))
		return
	next_reset_realtime = json_number(data["next_reset_realtime"]) || 0

/datum/controller/subsystem/tetris_weekly_rewards/proc/save_state()
	var/list/data = list()
	data["next_reset_realtime"] = next_reset_realtime
	fdel(TETRIS_WEEKLY_REWARD_STATE_FILE)
	WRITE_FILE(file(TETRIS_WEEKLY_REWARD_STATE_FILE), json_encode(data))

/datum/controller/subsystem/tetris_weekly_rewards/proc/load_progress()
	var/json = file2text(TETRIS_WEEKLY_REWARD_PROGRESS_FILE)
	if(!json)
		return
	var/list/data = json_decode(json)
	if(!islist(data))
		return
	current_cycle_started = json_number(data["cycle_started"]) || 0
	current_index = max(1, json_number(data["current_index"]) || 1)
	current_entries = islist(data["entries"]) ? data["entries"] : list()
	paid_ckeys = islist(data["paid_ckeys"]) ? data["paid_ckeys"] : list()
	granting_ckeys = islist(data["granting_ckeys"]) ? data["granting_ckeys"] : list()
	leaderboard_reset_done = data["leaderboard_reset_done"] ? TRUE : FALSE

/datum/controller/subsystem/tetris_weekly_rewards/proc/json_number(value)
	return isnum(value) ? value : text2num(value)

/datum/controller/subsystem/tetris_weekly_rewards/proc/save_progress()
	var/list/data = list()
	data["cycle_started"] = current_cycle_started
	data["current_index"] = current_index
	data["entries"] = current_entries
	data["paid_ckeys"] = paid_ckeys
	data["granting_ckeys"] = granting_ckeys
	data["leaderboard_reset_done"] = leaderboard_reset_done
	fdel(TETRIS_WEEKLY_REWARD_PROGRESS_FILE)
	WRITE_FILE(file(TETRIS_WEEKLY_REWARD_PROGRESS_FILE), json_encode(data))

/datum/controller/subsystem/tetris_weekly_rewards/proc/clear_progress()
	current_cycle_started = 0
	current_index = 1
	current_entries = list()
	paid_ckeys = list()
	granting_ckeys = list()
	processing_rewards = FALSE
	leaderboard_reset_done = FALSE
	fdel(TETRIS_WEEKLY_REWARD_PROGRESS_FILE)

/datum/controller/subsystem/tetris_weekly_rewards/proc/begin_reward_cycle()
	if(!SSachievements?.achievements_enabled || !SSdbcore.Connect())
		return
	var/list/entries = collect_tetris_entries()
	if(isnull(entries))
		return
	current_entries = entries
	paid_ckeys = list()
	granting_ckeys = list()
	current_index = 1
	current_cycle_started = world.realtime
	leaderboard_reset_done = FALSE
	processing_rewards = TRUE
	save_progress()
	continue_reward_cycle()

/datum/controller/subsystem/tetris_weekly_rewards/proc/collect_tetris_entries()
	var/list/entries = list()
	var/datum/db_query/Q = SSdbcore.NewQuery(
		"SELECT ckey,value FROM [format_table_name("achievements")] WHERE achievement_key = :achievement_key ORDER BY value DESC",
		list("achievement_key" = TETRIS_SCORE)
	)
	if(!Q.warn_execute())
		qdel(Q)
		return null
	var/rank = 0
	while(Q.NextRow())
		var/key = ckey(Q.item[1])
		var/score = json_number(Q.item[2]) || 0
		if(!key || score <= 0)
			continue
		rank++
		entries += list(list(
			"ckey" = key,
			"score" = score,
			"rank" = rank,
			"amount" = reward_amount_for_rank(rank)
		))
	qdel(Q)
	return entries

/datum/controller/subsystem/tetris_weekly_rewards/proc/reward_amount_for_rank(rank)
	switch(rank)
		if(1)
			return 250
		if(2)
			return 200
		if(3)
			return 100
		if(4 to 10)
			return 50
	return 0

/datum/controller/subsystem/tetris_weekly_rewards/proc/continue_reward_cycle()
	if(!leaderboard_reset_done)
		if(!reset_tetris_leaderboard())
			save_progress()
			return
		leaderboard_reset_done = TRUE
		save_progress()
	while(current_index <= length(current_entries))
		var/list/entry = current_entries[current_index]
		var/key = ckey(entry["ckey"])
		if(!key || paid_ckeys[key])
			current_index++
			continue
		if(!grant_tetris_reward(entry))
			save_progress()
			return
		paid_ckeys[key] = TRUE
		granting_ckeys -= key
		current_index++
		save_progress()
		if(MC_TICK_CHECK)
			return
	var/completed_records = length(current_entries)
	clear_progress()
	advance_next_reset()
	log_admin("Tetris weekly rewards: completed weekly payout/reset for [completed_records] records.")
	message_admins("Tetris weekly rewards: рейтинг тетриса сброшен, недельные награды выданы.")

/datum/controller/subsystem/tetris_weekly_rewards/proc/grant_tetris_reward(list/entry)
	var/key = ckey(entry["ckey"])
	var/amount = round(json_number(entry["amount"]) || 0)
	if(!key || amount <= 0)
		return TRUE
	var/list/ctx = bm_tgs_get_prefs_for_ckey(key)
	if(!ctx)
		log_admin("Tetris weekly rewards: failed to load preferences for [key], reward [amount] M$ skipped until retry.")
		return FALSE
	var/datum/preferences/P = ctx["prefs"]
	if(!granting_ckeys[key])
		granting_ckeys[key] = list("old_balance" = P.metadollars, "amount" = amount, "reward_saved" = FALSE)
		save_progress()
	else
		var/list/granting_data = granting_ckeys[key]
		if(granting_data["reward_saved"])
			bm_tgs_finish_prefs_edit(ctx, FALSE)
			return TRUE
	P.metadollars = max(0, round(P.metadollars + amount))
	if(!bm_tgs_finish_prefs_edit(ctx, TRUE))
		log_admin("Tetris weekly rewards: failed to save preferences for [key], reward [amount] M$ will retry.")
		return FALSE
	var/list/granting_data = granting_ckeys[key]
	granting_data["reward_saved"] = TRUE
	var/client/C = GLOB.directory[key]
	if(C?.mob)
		to_chat(C.mob, span_purple("Вы получили [amount] М$ за недельный рейтинг тетриса."))
	var/rank = json_number(entry["rank"]) || 0
	var/score = json_number(entry["score"]) || 0
	log_admin("Tetris weekly rewards: granted [amount] M$ to [key] for rank #[rank], score [score].")
	return TRUE

/datum/controller/subsystem/tetris_weekly_rewards/proc/reset_tetris_leaderboard()
	if(!SSdbcore.Connect())
		return FALSE
	var/datum/db_query/Q = SSdbcore.NewQuery(
		"DELETE FROM [format_table_name("achievements")] WHERE achievement_key = :achievement_key",
		list("achievement_key" = TETRIS_SCORE)
	)
	if(!Q.warn_execute())
		qdel(Q)
		return FALSE
	qdel(Q)
	var/datum/award/score/highscore/tetris/S = SSachievements.scores[/datum/award/score/highscore/tetris]
	if(S)
		S.high_scores = list()
	for(var/key in GLOB.player_details)
		var/datum/player_details/PD = GLOB.player_details[key]
		if(!PD?.achievements)
			continue
		PD.achievements.data[/datum/award/score/highscore/tetris] = 0
		PD.achievements.original_cached_data[/datum/award/score/highscore/tetris] = 0
	return TRUE

/datum/controller/subsystem/tetris_weekly_rewards/proc/advance_next_reset()
	next_reset_realtime = next_monday_midnight()
	save_state()

/datum/controller/subsystem/tetris_weekly_rewards/proc/next_monday_midnight()
	var/realtime_seconds = round(world.realtime / 10)
	var/days_since_epoch = round(realtime_seconds / 86400)
	var/dow = (days_since_epoch + 5) % 7
	var/days_until_monday = (7 - dow) % 7
	if(days_until_monday == 0)
		days_until_monday = 7
	var/next_monday_seconds = (days_since_epoch + days_until_monday) * 86400
	return next_monday_seconds * 10

#undef TETRIS_WEEKLY_REWARD_INTERVAL
#undef TETRIS_WEEKLY_REWARD_CHECK_INTERVAL
#undef TETRIS_WEEKLY_REWARD_STATE_FILE
#undef TETRIS_WEEKLY_REWARD_PROGRESS_FILE
