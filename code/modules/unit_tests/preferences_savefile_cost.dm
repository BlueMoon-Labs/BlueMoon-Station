#ifdef PREFS_SAVEFILE_BENCHMARK

#define SAVEFILE_BENCH_SLOTS 40
#define SAVEFILE_BENCH_REPS 20

/// Замер цены записи префов и смоделированной сессии игрока на сейве с сорока слотами.
/// Собирается и на старом коде, где нет удержания файла: для парного замера туда хватает счётчика открытий.
/datum/unit_test/preferences_savefile_cost_benchmark

/datum/unit_test/preferences_savefile_cost_benchmark/proc/bench_release(datum/preferences/prefs)
	if(hascall(prefs, "release_savefile"))
		call(prefs, "release_savefile")()

/datum/unit_test/preferences_savefile_cost_benchmark/proc/bench_prefs(path)
	var/datum/preferences/prefs = new
	prefs.path = path
	prefs.vr_path = "[GLOB.log_directory]/savefile_bench_vore"
	if("session_savefile" in prefs.vars)
		prefs.vars["session_savefile"] = TRUE
	return prefs

/datum/unit_test/preferences_savefile_cost_benchmark/Run()
	var/path = "[GLOB.log_directory]/savefile_bench.sav"
	fdel(path)
	var/datum/preferences/writer = bench_prefs(path)
	writer.save_preferences(bypass_cooldown = TRUE, silent = TRUE)
	for(var/slot in 1 to SAVEFILE_BENCH_SLOTS)
		writer.default_slot = slot
		writer.random_character()
		writer.real_name = "Bench Character [slot]"
		writer.save_character(bypass_cooldown = TRUE, silent = TRUE, update_active_preset = FALSE)
	writer.default_slot = 1
	writer.save_preferences(bypass_cooldown = TRUE, silent = TRUE)
	bench_release(writer)
	qdel(writer)
	sleep(1)
	log_test("SAVEFILEBENCH fixture slots=[SAVEFILE_BENCH_SLOTS] size=[length(file(path))]")
	var/tiny_path = "[GLOB.log_directory]/savefile_bench_tiny.sav"
	for(var/raw_path in list(path, tiny_path))
		var/list/raw = list("open" = 0, "read" = 0, "write" = 0, "close" = 0)
		for(var/rep in 1 to SAVEFILE_BENCH_REPS)
			rustg_time_reset("savefile_bench")
			var/savefile/raw_file = new /savefile(raw_path)
			raw["open"] += rustg_time_microseconds("savefile_bench")
			rustg_time_reset("savefile_bench")
			raw_file.cd = "/"
			var/raw_version
			READ_FILE(raw_file["version"], raw_version)
			raw["read"] += rustg_time_microseconds("savefile_bench")
			rustg_time_reset("savefile_bench")
			WRITE_FILE(raw_file["bench_probe"], rep)
			raw["write"] += rustg_time_microseconds("savefile_bench")
			rustg_time_reset("savefile_bench")
			raw_file = null
			raw["close"] += rustg_time_microseconds("savefile_bench")
		var/list/raw_parts = list()
		for(var/op in raw)
			raw_parts += "[op]_us=[round(raw[op] / SAVEFILE_BENCH_REPS)]"
		log_test("SAVEFILEBENCH raw [raw_path] [jointext(raw_parts, " ")]")
	fdel(tiny_path)

	var/datum/preferences/prefs = bench_prefs(path)
	prefs.load_preferences(bypass_cooldown = TRUE)
	prefs.load_character(1, bypass_cooldown = TRUE)
	var/state = "{\"tabs\":\[1,2,3\],\"pad\":\"[jointext(new /list(400), "x")]\"}"

	for(var/held in list(FALSE, TRUE))
		var/list/costs = list("single" = 0, "full" = 0, "char" = 0, "load" = 0)
		var/opens_before = GLOB.player_savefile_opens
		for(var/rep in 1 to SAVEFILE_BENCH_REPS)
			if(!held)
				bench_release(prefs)
			prefs.tgui_panel_state = "[state][rep]"
			prefs.save_single_pref("tgui_panel_state", prefs.tgui_panel_state)
			rustg_time_reset("savefile_bench")
			prefs.flush_single_prefs()
			costs["single"] += rustg_time_microseconds("savefile_bench")
			if(!held)
				bench_release(prefs)
			rustg_time_reset("savefile_bench")
			prefs.save_preferences(bypass_cooldown = TRUE, silent = TRUE)
			costs["full"] += rustg_time_microseconds("savefile_bench")
			if(!held)
				bench_release(prefs)
			rustg_time_reset("savefile_bench")
			prefs.save_character(bypass_cooldown = TRUE, silent = TRUE, update_active_preset = FALSE)
			costs["char"] += rustg_time_microseconds("savefile_bench")
			if(!held)
				bench_release(prefs)
			rustg_time_reset("savefile_bench")
			prefs.load_character((rep % SAVEFILE_BENCH_SLOTS) + 1, bypass_cooldown = TRUE)
			costs["load"] += rustg_time_microseconds("savefile_bench")
		var/list/parts = list()
		for(var/op in costs)
			parts += "[op]_us=[round(costs[op] / SAVEFILE_BENCH_REPS)]"
		log_test("SAVEFILEBENCH ops [held ? "warm" : "cold"] [jointext(parts, " ")] opens=[GLOB.player_savefile_opens - opens_before] of [SAVEFILE_BENCH_REPS * 4] calls")
	bench_release(prefs)
	qdel(prefs)

	for(var/session in 1 to 3)
		var/list/phase_us = list()
		var/list/phase_opens = list()
		var/opens_mark = GLOB.player_savefile_opens
		var/datum/preferences/player = bench_prefs(path)

		rustg_time_reset("savefile_bench")
		player.load_preferences(bypass_cooldown = TRUE)
		player.load_character(null, bypass_cooldown = TRUE)
		phase_us["login"] = rustg_time_microseconds("savefile_bench")
		phase_opens["login"] = GLOB.player_savefile_opens - opens_mark
		opens_mark = GLOB.player_savefile_opens

		rustg_time_reset("savefile_bench")
		player.slot_names_cache = null
		player.get_slot_names()
		for(var/switch_index in 1 to 5)
			player.save_character(bypass_cooldown = TRUE, silent = TRUE, update_active_preset = FALSE)
			player.get_slot_names()
			player.load_character(switch_index + 1, bypass_cooldown = TRUE)
			player.save_preferences(bypass_cooldown = TRUE, silent = TRUE)
		player.save_character(bypass_cooldown = TRUE, silent = TRUE, update_active_preset = FALSE)
		phase_us["editor"] = rustg_time_microseconds("savefile_bench")
		phase_opens["editor"] = GLOB.player_savefile_opens - opens_mark
		opens_mark = GLOB.player_savefile_opens

		bench_release(player)
		rustg_time_reset("savefile_bench")
		for(var/flush_index in 1 to 3)
			player.tgui_fancy = !player.tgui_fancy
			player.save_pref_var("tgui_fancy")
			player.max_chat_length = 100 + flush_index
			player.save_pref_var("max_chat_length")
			player.flush_single_prefs()
			bench_release(player)
		phase_us["toggles"] = rustg_time_microseconds("savefile_bench")
		phase_opens["toggles"] = GLOB.player_savefile_opens - opens_mark
		opens_mark = GLOB.player_savefile_opens

		rustg_time_reset("savefile_bench")
		player.save_character(bypass_cooldown = TRUE, silent = TRUE, update_active_preset = FALSE)
		phase_us["spawn"] = rustg_time_microseconds("savefile_bench")
		phase_opens["spawn"] = GLOB.player_savefile_opens - opens_mark
		opens_mark = GLOB.player_savefile_opens

		bench_release(player)
		rustg_time_reset("savefile_bench")
		for(var/tick_index in 1 to 6)
			player.metadollar_minute_pool = tick_index * 7
			player.save_single_pref("metadollar_minute_pool", player.metadollar_minute_pool, lazy = TRUE)
			player.tgui_panel_state = "[state]-[tick_index]"
			player.save_single_pref("tgui_panel_state", player.tgui_panel_state)
			player.flush_single_prefs()
			bench_release(player)
		phase_us["midround"] = rustg_time_microseconds("savefile_bench")
		phase_opens["midround"] = GLOB.player_savefile_opens - opens_mark
		opens_mark = GLOB.player_savefile_opens

		rustg_time_reset("savefile_bench")
		player.save_character(bypass_cooldown = TRUE, silent = TRUE, update_active_preset = FALSE)
		player.metadollar_minute_pool = 55
		player.save_single_pref("metadollar_minute_pool", player.metadollar_minute_pool, lazy = TRUE)
		player.flush_single_prefs()
		bench_release(player)
		phase_us["logout"] = rustg_time_microseconds("savefile_bench")
		phase_opens["logout"] = GLOB.player_savefile_opens - opens_mark

		var/total_us = 0
		var/total_opens = 0
		var/list/parts = list()
		for(var/phase in phase_us)
			total_us += phase_us[phase]
			total_opens += phase_opens[phase]
			parts += "[phase]=[round(phase_us[phase])]us/[phase_opens[phase]]open"
		log_test("SAVEFILEBENCH session [session] total_us=[round(total_us)] opens=[total_opens] [jointext(parts, " ")]")
		qdel(player)

	fdel(path)
	fdel("[path].journal")

#undef SAVEFILE_BENCH_SLOTS
#undef SAVEFILE_BENCH_REPS

#endif
