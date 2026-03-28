SUBSYSTEM_DEF(statpanels)
	name = "Stat Panels"
	wait = 3
	init_order = INIT_ORDER_STATPANELS
	priority = FIRE_PRIORITY_STATPANEL
	runlevels = RUNLEVELS_DEFAULT | RUNLEVEL_LOBBY
	var/list/currentrun = list()
	var/encoded_global_fast
	var/encoded_global_slow
	var/mc_data_encoded
	var/mc_ss_data_encoded
	var/list/cached_images = list()
	var/mc_data_refresh_counter = 0
	var/static/null_bullet_encoded
	var/full_cycle_counter = 0
	var/slow_data_counter = 0
	var/list/cached_vote_base
	var/cached_vote_encoded
	var/list/perf_history_cpu = list()
	var/list/perf_history_tidi = list()
	var/list/perf_history_ping = list()
	var/encoded_tidi
	var/is_full_cycle = FALSE
	var/prev_player_count = 0
	var/client_stagger_groups = 3
	var/client_stagger_index = 0
	var/cached_tickets_encoded
	var/turf_fire_skip = FALSE
	var/list/cached_client_stats
	var/client_stats_refresh_counter = 0

/datum/controller/subsystem/statpanels/fire(resumed = FALSE)
	if (!resumed)
		full_cycle_counter++
		slow_data_counter++
		is_full_cycle = (full_cycle_counter >= 3)
		var/is_slow_cycle = (slow_data_counter >= 9)
		if(is_full_cycle)
			full_cycle_counter = 0
		if(is_slow_cycle)
			slow_data_counter = 0
			cached_images.Cut()

		turf_fire_skip = !turf_fire_skip

		var/list/tidi_data = list(
			round(SStime_track.time_dilation_current, 0.1),
			round(SStime_track.time_dilation_avg_fast, 0.1),
			round(SStime_track.time_dilation_avg, 0.1),
			round(SStime_track.time_dilation_avg_slow, 0.1))
		encoded_tidi = url_encode(json_encode(tidi_data))

		// Compute fast global data every fire — cheap, and stagger groups need fresh data each fire
		var/round_time = world.time - SSticker.round_start_time
		var/real_round_time = world.timeofday - SSticker.real_round_start_time
		var/list/fast_data = list()
		fast_data["time"] = list(
			list("\u0412\u0440\u0435\u043C\u044F \u0420\u0430\u0443\u043D\u0434\u0430", time2text(round_time, "hh:mm:ss", 0)),
			list("\u041D\u0430\u0441\u0442. \u0412\u0440\u0435\u043C\u044F \u0420\u0430\u0443\u043D\u0434\u0430", time2text(real_round_time, "hh:mm:ss", 0)),
			list("\u0414\u0430\u0442\u0430", "[time2text(world.realtime, "MMM DD")] [GLOB.year_integer]"),
			list("\u0412\u0440\u0435\u043C\u044F \u0421\u0442\u0430\u043D\u0446\u0438\u0438", STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)),
			list("\u0412\u0440\u0435\u043C\u044F \u0432 \u0421\u043E\u043B\u043D\u0435\u0447\u043D\u043E\u0439", SOLAR_TIME_TIMESTAMP("hh:mm:ss", world.time)),
			list("\u0412\u0440\u0435\u043C\u044F \u0421\u0435\u0440\u0432\u0435\u0440\u0430", time2text(world.timeofday, "YYYY-MM-DD hh:mm:ss")))
		fast_data["tidi"] = tidi_data
		if(SSshuttle.emergency)
			var/ETA = SSshuttle.emergency.getModeStr()
			if(ETA)
				fast_data["shuttle"] = list(ETA, SSshuttle.emergency.getTimerStr())
		encoded_global_fast = url_encode(json_encode(fast_data))

		// is_full_cycle gates slow-updating global data and vote cache only;
		// per-client throttling is handled by stagger groups (each client visited every 3rd fire)
		if(is_full_cycle)
			if(is_slow_cycle)
				var/datum/map_config/cached = SSmapping.next_map_config
				var/list/server_section = list(
					list("\u041A\u0430\u0440\u0442\u0430", SSmapping.config?.map_name || "Loading..."))
				if(cached)
					server_section += list(list("\u0421\u043B\u0435\u0434\u0443\u044E\u0449\u0430\u044F \u043A\u0430\u0440\u0442\u0430", cached.map_name))
				var/current_players = GLOB.clients.len
				var/player_delta = current_players - prev_player_count
				var/player_trend = "[current_players]"
				if(prev_player_count && player_delta != 0)
					player_trend = "[current_players] ([player_delta > 0 ? "+" : ""][player_delta])"
				prev_player_count = current_players
				server_section += list(
					list("ID \u0440\u0430\u0443\u043D\u0434\u0430", GLOB.round_id ? GLOB.round_id : "NULL"),
					list("\u0418\u0433\u0440\u043E\u0432\u043E\u0439 \u0420\u0435\u0436\u0438\u043C", GLOB.master_mode),
					list("\u041F\u043E\u0434\u043A\u043B\u044E\u0447\u0435\u043D\u043E \u0418\u0433\u0440\u043E\u043A\u043E\u0432", player_trend),
					list("\u041F\u0440\u0435\u0434\u044B\u0434\u0443\u0449\u0438\u0435 \u0420\u0435\u0436\u0438\u043C\u044B", jointext(SSpersistence.saved_modes, ", ")))
				encoded_global_slow = url_encode(json_encode(server_section))

			cached_vote_base = null
			cached_vote_encoded = null
			if(SSvote.mode)
				var/list/vote_base = list(
					list("Vote active!", "There is currently a vote running. Question: [SSvote.question]"))
				if(!(SSvote.vote_system in list(PLURALITY_VOTING, APPROVAL_VOTING, SCHULZE_VOTING, INSTANT_RUNOFF_VOTING)))
					vote_base[++vote_base.len] += list("STATPANEL VOTING DISABLED!", "The current vote system is not supported by statpanel rendering. Please vote manually by opening the vote popup using the action button or chat link.", "disabled")
				else
 //BLUEMOON ADDITION START
					if(SSvote.mode == "roundtype")
						vote_base[++vote_base.len] += list("Time Left:", " [DisplayTimeText(SSticker.timeLeft - ROUNDTYPE_VOTE_END_PENALTY)] seconds")
					else
 //BLUEMOON ADDITION END
						vote_base[++vote_base.len] += list("Time Left:", " [DisplayTimeText(SSticker.timeLeft)] seconds")
					vote_base[++vote_base.len] += list("Choices:", "")
				cached_vote_base = vote_base

		mc_data_refresh_counter++
		if(mc_data_refresh_counter >= 6)
			mc_data_encoded = null
			mc_ss_data_encoded = null
			mc_data_refresh_counter = 0

		if(!null_bullet_encoded)
			null_bullet_encoded = url_encode(json_encode(list(list(null))))

		// Adaptive wait based on server load
		var/client_count = length(GLOB.clients)
		if(client_count > 60 || SStime_track.time_dilation_current > 20)
			wait = 5
		else if(client_count > 40 || SStime_track.time_dilation_current > 10)
			wait = 4
		else
			wait = 3

		// Build staggered client list — each fire processes 1/N of all clients
		// Each client gets a full update every (stagger_groups * wait) deciseconds
		var/list/all_clients = GLOB.clients
		var/list/run_list = list()
		for(var/i in (client_stagger_index + 1) to length(all_clients) step client_stagger_groups)
			run_list += all_clients[i]
		client_stagger_index = (client_stagger_index + 1) % client_stagger_groups
		cached_tickets_encoded = null
		src.currentrun = run_list

	var/list/currentrun = src.currentrun
	while(length(currentrun))
		var/client/target = currentrun[length(currentrun)]
		currentrun.len--
		if(!target?.statbrowser_ready)
			continue

		if(target.ping_updated && target.inactivity < 3000)
			target.ping_updated = FALSE
			var/ping_str = "%5B[round(target.lastping, 1)]%2C[round(target.avgping, 1)]%2C[round(target.avgping_jitter, 1)]%5D"
			target << output("[ping_str];[encoded_tidi]", "statbrowser:update_ping")

		// Skip heavy work for AFK clients (5 min inactivity)
		// Admin clients are also skipped; they self-recover on the first active fire
		if(target.inactivity >= 3000)
			if(!target.holder && !target.admin_tabs_cleared)
				target << output("", "statbrowser:remove_admin_tabs")
				target.admin_tabs_cleared = TRUE
			if(MC_TICK_CHECK)
				return
			continue

		if(target.stat_tab == "Status")
			var/other_str = url_encode(json_encode(target.mob?.get_status_tab_items()))
			var/slow_str = encoded_global_slow ? encoded_global_slow : ""
			target << output("[encoded_global_fast];[slow_str];[other_str]", "statbrowser:update")

			if(SSvote.mode && cached_vote_base)
				var/list/vote_arry = cached_vote_base.Copy()
				if(SSvote.vote_system in list(PLURALITY_VOTING, APPROVAL_VOTING, SCHULZE_VOTING, INSTANT_RUNOFF_VOTING))
					for(var/choice in SSvote.choice_statclicks)
						var/choice_id = SSvote.choice_statclicks[choice]
						if(target.ckey)
							switch(SSvote.vote_system)
								if(PLURALITY_VOTING, APPROVAL_VOTING)
									var/ivotedforthis = FALSE
									if(SSvote.vote_system == APPROVAL_VOTING)
										ivotedforthis = SSvote.voted[target.ckey] && (text2num(choice_id) in SSvote.voted[target.ckey])
									else
										ivotedforthis = (SSvote.voted[target.ckey] == text2num(choice_id))
									vote_arry[++vote_arry.len] += list(ivotedforthis ? "\[X\]" : "\[ \]", choice, "[REF(SSvote)];vote=[choice_id];statpannel=1")
								if(SCHULZE_VOTING, INSTANT_RUNOFF_VOTING)
									var/list/vote = SSvote.voted[target.ckey]
									var/vote_position = " "
									if(vote)
										vote_position = vote.Find(text2num(choice_id))
									vote_arry[++vote_arry.len] += list("\[[vote_position]\]", choice, "[REF(SSvote)];vote=[choice_id];statpannel=1")
				var/vote_str = url_encode(json_encode(vote_arry))
				target << output("[vote_str]", "statbrowser:update_voting")
				target.stat_vote_sent_null = FALSE
			else if(!target.stat_vote_sent_null)
				target << output("[null_bullet_encoded]", "statbrowser:update_voting")
				target.stat_vote_sent_null = TRUE

		if(!target.holder)
			if(!target.admin_tabs_cleared)
				target << output("", "statbrowser:remove_admin_tabs")
				target.admin_tabs_cleared = TRUE
		else
			target.admin_tabs_cleared = FALSE
			if(!("MC" in target.panel_tabs) || !("Tickets" in target.panel_tabs))
				target << output("[url_encode(target.holder.href_token)]", "statbrowser:add_admin_tabs")
			if(target.stat_tab == "MC")
				var/turf/eye_turf = get_turf(target.eye)
				var/coord_entry = url_encode(COORD(eye_turf))
				if(!mc_data_encoded)
					generate_mc_data()
				target << output("[mc_data_encoded];[mc_ss_data_encoded];[coord_entry]", "statbrowser:update_mc")
			if(target.stat_tab == "Tickets")
				if(!cached_tickets_encoded)
					cached_tickets_encoded = url_encode(json_encode(GLOB.ahelp_tickets.stat_entry()))
				target << output("[cached_tickets_encoded];", "statbrowser:update_tickets")
			if(!length(GLOB.sdql2_queries) && ("SDQL2" in target.panel_tabs))
				target << output("", "statbrowser:remove_sdql2")
			else if(length(GLOB.sdql2_queries) && (target.stat_tab == "SDQL2" || !("SDQL2" in target.panel_tabs)))
				var/list/sdql2A = list()
				sdql2A[++sdql2A.len] = list("", "Access Global SDQL2 List", REF(GLOB.sdql2_vv_statobj))
				var/list/sdql2B = list()
				for(var/i in GLOB.sdql2_queries)
					var/datum/SDQL2_query/Q = i
					sdql2B = Q.generate_stat()
				sdql2A += sdql2B
				target << output(url_encode(json_encode(sdql2A)), "statbrowser:update_sdql2")

		if(target.mob)
			var/mob/M = target.mob
			if((target.stat_tab in target.spell_tabs) || !length(target.spell_tabs) && (length(M.mob_spell_list) || length(M.mind?.spell_list)))
				var/list/proc_holders = M.get_proc_holders()
				target.spell_tabs.Cut()
				for(var/phl in proc_holders)
					var/list/proc_holder_list = phl
					target.spell_tabs |= proc_holder_list[1]
				var/proc_holders_encoded = ""
				if(length(proc_holders))
					proc_holders_encoded = url_encode(json_encode(proc_holders))
				target << output("[url_encode(json_encode(target.spell_tabs))];[proc_holders_encoded]", "statbrowser:update_spells")
			if(MC_TICK_CHECK)
				return
			if(!turf_fire_skip && M?.listed_turf)
				var/mob/target_mob = M
				if(!target_mob.TurfAdjacent(target_mob.listed_turf))
					target << output("", "statbrowser:remove_listedturf")
					target_mob.listed_turf = null
					target.cached_turf_ref = null
					target.cached_turf_encoded = null
				else if(target.stat_tab == M?.listed_turf.name || !(M?.listed_turf.name in target.panel_tabs))
					var/turf_ref = REF(target_mob.listed_turf)
					target.turf_refresh_counter++
					// Use cached data if same turf and not time for forced refresh
					if(turf_ref == target.cached_turf_ref && target.cached_turf_encoded && target.turf_refresh_counter < 3)
						target << output("[target.cached_turf_encoded];", "statbrowser:update_listedturf")
					else
						target.turf_refresh_counter = 0
						var/list/overrides = list()
						var/list/turfitems = list()
						for(var/img in target.images)
							var/image/target_image = img
							if(!target_image.loc || target_image.loc.loc != target_mob.listed_turf || !target_image.override)
								continue
							overrides += target_image.loc
						turfitems[++turfitems.len] = list("[target_mob.listed_turf]", REF(target_mob.listed_turf), icon2html(target_mob.listed_turf, target, sourceonly=TRUE))
						for(var/tc in target_mob.listed_turf)
							var/atom/movable/turf_content = tc
							if(turf_content.mouse_opacity == MOUSE_OPACITY_TRANSPARENT)
								continue
							if(turf_content.invisibility > target_mob.see_invisible)
								continue
							if(turf_content in overrides)
								continue
							if(turf_content.IsObscured())
								continue
							if(length(turfitems) < 30)
								if(!cached_images[REF(turf_content)])
									cached_images[REF(turf_content)] = TRUE
									turf_content.RegisterSignal(turf_content, COMSIG_PARENT_QDELETING, TYPE_PROC_REF(/atom, remove_from_cache))
									if(ismob(turf_content) || length(turf_content.overlays) > 4)
										turfitems[++turfitems.len] = list("[turf_content.name]", REF(turf_content), costly_icon2html(turf_content, target, sourceonly=TRUE))
									else
										turfitems[++turfitems.len] = list("[turf_content.name]", REF(turf_content), icon2html(turf_content, target, sourceonly=TRUE))
								else
									turfitems[++turfitems.len] = list("[turf_content.name]", REF(turf_content))
							else
								turfitems[++turfitems.len] = list("[turf_content.name]", REF(turf_content))
						var/encoded = url_encode(json_encode(turfitems))
						target.cached_turf_ref = turf_ref
						target.cached_turf_encoded = encoded
						target << output("[encoded];", "statbrowser:update_listedturf")
		if(MC_TICK_CHECK)
			return


/datum/controller/subsystem/statpanels/proc/generate_mc_data()
	var/list/server_info = list()
	server_info["cpu"] = world.cpu
	server_info["instances"] = world.contents.len
	server_info["world_time"] = world.time
	server_info["fps"] = world.fps
	server_info["tick_count"] = round(world.time / world.tick_lag)
	server_info["tick_drift"] = round(Master.tickdrift, 0.1)
	server_info["tick_drift_pct"] = round((Master.tickdrift / max(world.time / world.tick_lag, 1)) * 100, 0.1)
	server_info["internal_tick_usage"] = round(MAPTICK_LAST_INTERNAL_TICK_USAGE, 0.1)
	// MC state
	server_info["mc_tick_rate"] = Master.processing
	server_info["mc_iteration"] = Master.iteration
	server_info["mc_tick_limit"] = round(Master.current_ticklimit, 0.1)
	server_info["mc_stat"] = Master.stat_entry()
	server_info["failsafe_stat"] = Failsafe.stat_entry()
	// Ping RTT
	server_info["ping_samples"] = SStime_track.ping_samples
	server_info["ping_rtt_avg"] = round(SStime_track.ping_rtt_last_avg, 1)
	server_info["ping_rtt_max"] = round(SStime_track.ping_rtt_last_max, 1)
	server_info["ping_rtt_avg_avg"] = round(SStime_track.ping_rtt_avg_avg, 1)
	// Ping tick/server
	server_info["ping_tick_avg"] = round(SStime_track.ping_tick_last_avg, 1)
	server_info["ping_tick_max"] = round(SStime_track.ping_tick_last_max, 1)
	server_info["ping_server_avg"] = round(SStime_track.ping_server_last_avg, 1)
	server_info["ping_server_max"] = round(SStime_track.ping_server_last_max, 1)
	// Movement jitter
	server_info["raw_mult"] = round(SStime_track.raw_multiplier_last, 4)
	server_info["jitter_last"] = round(SStime_track.raw_multiplier_jitter_abs_last, 2)
	server_info["jitter_avg"] = round(SStime_track.raw_multiplier_jitter_abs_avg, 2)
	server_info["jitter_max_wnd"] = round(SStime_track.raw_multiplier_jitter_abs_max_window, 2)
	server_info["glide_mult"] = round(SStime_track.glide_size_multiplier_current, 4)
	// Server maintenance
	server_info["cleanup_last"] = round(SSserver_maint.cleanup_last_ms, 3)
	server_info["cleanup_avg"] = round(SSserver_maint.cleanup_avg_ms, 3)
	server_info["cleanup_target"] = SSserver_maint.cleanup_target_last
	// Time dilation
	server_info["tidi_current"] = round(SStime_track.time_dilation_current, 0.1)
	server_info["tidi_avg_fast"] = round(SStime_track.time_dilation_avg_fast, 0.1)
	server_info["tidi_avg"] = round(SStime_track.time_dilation_avg, 0.1)
	server_info["tidi_avg_slow"] = round(SStime_track.time_dilation_avg_slow, 0.1)
	// VV refs
	server_info["ref_glob"] = "\ref[GLOB]"
	server_info["ref_config"] = "\ref[config]"
	server_info["ref_master"] = "\ref[Master]"
	server_info["ref_failsafe"] = "\ref[Failsafe]"
	server_info["ref_cameranet"] = "\ref[GLOB.cameranet]"
	// Camera net
	server_info["camera_count"] = GLOB.cameranet.cameras.len
	server_info["camera_chunks"] = GLOB.cameranet.chunks.len

	perf_history_cpu += world.cpu
	if(length(perf_history_cpu) > 30)
		perf_history_cpu.Cut(1, length(perf_history_cpu) - 29)
	perf_history_tidi += round(SStime_track.time_dilation_current, 0.1)
	if(length(perf_history_tidi) > 30)
		perf_history_tidi.Cut(1, length(perf_history_tidi) - 29)
	perf_history_ping += round(SStime_track.ping_rtt_last_avg, 1)
	if(length(perf_history_ping) > 30)
		perf_history_ping.Cut(1, length(perf_history_ping) - 29)
	server_info["history"] = list(
		"cpu" = perf_history_cpu.Copy(),
		"tidi" = perf_history_tidi.Copy(),
		"ping" = perf_history_ping.Copy()
	)

	var/list/key_ss = list()
	// Atmospherics
	key_ss["Atmospherics"] = list(
		list("\u0412\u044B\u0441\u043E\u043A\u043E\u0435 \u0434\u0430\u0432\u043B\u0435\u043D\u0438\u0435", round(SSair.cost_highpressure, 0.1)),
		list("\u0413\u043E\u0440\u0435\u043D\u0438\u0435", round(SSair.cost_hotspots, 0.1)),
		list("\u0421\u0432\u0435\u0440\u0445\u043F\u0440\u043E\u0432\u043E\u0434\u0438\u043C\u043E\u0441\u0442\u044C", round(SSair.cost_superconductivity, 0.1)),
		list("\u0422\u0440\u0443\u0431\u043E\u043F\u0440\u043E\u0432\u043E\u0434\u044B", round(SSair.cost_pipenets, 0.1)),
		list("\u0410\u0442\u043C\u043E\u0441. \u043C\u0430\u0448\u0438\u043D\u044B", round(SSair.cost_atmos_machinery, 0.1)),
		list("\u0410\u043A\u0442\u0438\u0432\u043D\u044B\u0435 \u0442\u0430\u0439\u043B\u044B", round(SSair.cost_turfs, 0.1)),
		list("\u041E\u0447\u0430\u0433\u0438", SSair.hotspots.len),
		list("\u0421\u0435\u0442\u0438", SSair.networks.len),
		list("\u0412\u044B\u0441 \u0434\u0430\u0432\u043B. \u0442\u0430\u0439\u043B\u044B", SSair.high_pressure_turfs),
		list("\u041D\u0438\u0437\u043A \u0434\u0430\u0432\u043B. \u0442\u0430\u0439\u043B\u044B", SSair.low_pressure_turfs),
		list("\u0413\u0430\u0437\u043E\u0432\u044B\u0435 \u0441\u043C\u0435\u0441\u0438", SSair.gas_mixes_count)
	)
	// Garbage Collector
	var/gc_ratio = (SSgarbage.totaldels + SSgarbage.totalgcs) ? "[round((SSgarbage.totalgcs / (SSgarbage.totaldels + SSgarbage.totalgcs)) * 100, 0.1)]%" : "n/a"
	var/list/gc_queue_counts = list()
	for (var/i in 1 to GC_QUEUE_COUNT)
		gc_queue_counts += SSgarbage.GetQueueDepth(i)
	key_ss["Garbage"] = list(
		list("\u041E\u0447\u0435\u0440\u0435\u0434\u0438", gc_queue_counts.Join(", ")),
		list("Del/\u0442\u0438\u043A", SSgarbage.delslasttick),
		list("GC/\u0442\u0438\u043A", SSgarbage.gcedlasttick),
		list("\u0412\u0441\u0435\u0433\u043E Del", SSgarbage.totaldels),
		list("\u0412\u0441\u0435\u0433\u043E GC", SSgarbage.totalgcs),
		list("GC %", gc_ratio)
	)
	// Machines
	key_ss["Machines"] = list(
		list("\u0412\u0441\u0435\u0433\u043E \u043C\u0430\u0448\u0438\u043D", SSmachines.get_machine_count()),
		list("\u0422\u0438\u043F\u043E\u0432", SSmachines.get_machine_type_count()),
		list("\u041E\u0431\u0440\u0430\u0431\u043E\u0442\u043A\u0430", length(SSmachines.processing)),
		list("\u042D\u043D\u0435\u0440\u0433\u043E\u0441\u0435\u0442\u0438", length(SSmachines.powernets))
	)
	// Mobs
	key_ss["Mobs"] = list(
		list("\u0416\u0438\u0432\u044B\u0445 \u043C\u043E\u0431\u043E\u0432", length(GLOB.mob_living_list))
	)
	// Timer
	key_ss["Timer"] = list(
		list("\u0411\u0430\u043A\u0435\u0442\u044B", SStimer.bucket_count),
		list("\u041E\u0447\u0435\u0440\u0435\u0434\u044C", length(SStimer.second_queue)),
		list("\u0425\u044D\u0448\u0438", length(SStimer.hashes)),
		list("\u041A\u043B\u0438\u0435\u043D\u0442 \u0442\u0430\u0439\u043C\u0435\u0440\u044B", length(SStimer.clienttime_timers)),
		list("\u0412\u0441\u0435\u0433\u043E ID", length(SStimer.timer_id_dict))
	)
	// Objects (processing subsystem)
	key_ss["Objects"] = list(
		list("\u041E\u0431\u0440\u0430\u0431\u043E\u0442\u043A\u0430", length(SSobj.processing))
	)
	// Lighting
	var/light_total = SSlighting.cost_sources + SSlighting.cost_corners + SSlighting.cost_objects
	var/light_pct_s = light_total > 0 ? round(SSlighting.cost_sources / light_total * 100) : 0
	var/light_pct_c = light_total > 0 ? round(SSlighting.cost_corners / light_total * 100) : 0
	var/light_pct_o = light_total > 0 ? round(SSlighting.cost_objects / light_total * 100) : 0
	var/light_avg = SSlighting.avg_sources_processed >= 0.5 ? round(SSlighting.cost_sources / SSlighting.avg_sources_processed, 0.01) : 0
	key_ss["Lighting"] = list(
		list("\u041E\u0447\u0435\u0440\u0435\u0434\u044C \u0438\u0441\u0442\u043E\u0447.", length(GLOB.lighting_update_lights)),
		list("\u041E\u0447\u0435\u0440\u0435\u0434\u044C \u0443\u0433\u043B\u043E\u0432", length(GLOB.lighting_update_corners)),
		list("\u041E\u0447\u0435\u0440\u0435\u0434\u044C \u043E\u0431\u044A\u0435\u043A\u0442.", length(GLOB.lighting_update_objects)),
		list("\u041A\u044D\u043F \u0438\u0441\u0442\u043E\u0447\u043D\u0438\u043A\u043E\u0432", SSlighting.sources_cap),
		list("\u0424\u0430\u0437\u0430: \u0418\u0441\u0442\u043E\u0447\u043D\u0438\u043A\u0438", "[round(SSlighting.cost_sources, 0.1)]ms ([light_pct_s]%)"),
		list("\u0424\u0430\u0437\u0430: \u0423\u0433\u043B\u044B", "[round(SSlighting.cost_corners, 0.1)]ms ([light_pct_c]%)"),
		list("\u0424\u0430\u0437\u0430: \u041E\u0431\u044A\u0435\u043A\u0442\u044B", "[round(SSlighting.cost_objects, 0.1)]ms ([light_pct_o]%)"),
		list("\u0421\u0440\u0435\u0434\u043D\u0435\u0435/\u0438\u0441\u0442\u043E\u0447\u043D\u0438\u043A", "[light_avg]ms ([round(SSlighting.avg_sources_processed)] \u0448\u0442)"),
		list("\u041F\u0438\u043A: \u0418\u0441\u0442./\u0423\u0433\u043B./\u041E\u0431\u044A.", "[SSlighting.peak_sources]/[SSlighting.peak_corners]/[SSlighting.peak_objects]"),
		list("\u0425\u0443\u0434\u0448\u0438\u0439 fire", "[round(SSlighting.worst_fire_cost, 0.1)]ms"),
		list("\u041A\u044D\u0448 \u0442\u0430\u0431\u043B\u0438\u0446", length(GLOB.lighting_sheets)),
		list("\u0417\u0432\u0451\u0437\u0434\u043D\u044B\u0435 \u0442\u0430\u0439\u043B\u044B", length(GLOB.starlight))
	)
	// Clients performance aggregate — cached separately, refreshed every 3rd MC data call
	client_stats_refresh_counter++
	if(client_stats_refresh_counter >= 3 || !cached_client_stats)
		client_stats_refresh_counter = 0
		var/total_clients = length(GLOB.clients)
		if(total_clients)
			var/sum_ping = 0
			var/min_ping = INFINITY
			var/max_ping = 0
			var/sum_server_delay = 0
			var/list/fps_counts = list()
			var/list/version_counts = list()
			var/valid_clients = total_clients
			for(var/client/C as anything in GLOB.clients)
				var/p = C.avgping_rtt || C.avgping
				if(!p)
					valid_clients--
					continue
				sum_ping += p
				if(p < min_ping) min_ping = p
				if(p > max_ping) max_ping = p
				sum_server_delay += (C.avgping_server || 0)
				var/fps_key = "[C.fps || world.fps]"
				fps_counts[fps_key] = (fps_counts[fps_key] || 0) + 1
				var/ver_key = "[C.byond_version].[C.byond_build]"
				version_counts[ver_key] = (version_counts[ver_key] || 0) + 1
			var/list/fps_parts = list()
			for(var/fps_val in fps_counts)
				fps_parts += "[fps_val]: [fps_counts[fps_val]]"
			var/list/ver_parts = list()
			var/ver_shown = 0
			for(var/ver in version_counts)
				if(ver_shown >= 3)
					break
				ver_parts += "[ver] ([version_counts[ver]])"
				ver_shown++
			var/avg_ping = valid_clients ? round(sum_ping / valid_clients, 1) : 0
			var/avg_delay = valid_clients ? round(sum_server_delay / valid_clients, 1) : 0
			var/ping_minmax = valid_clients ? "[round(min_ping, 1)]/[round(max_ping, 1)]ms" : "n/a"
			cached_client_stats = list(
				list("\u041F\u043E\u0434\u043A\u043B\u044E\u0447\u0435\u043D\u043E", length(GLOB.clients)),
				list("Ping \u0441\u0440\u0435\u0434\u043D\u0438\u0439", "[avg_ping]ms"),
				list("Ping \u043C\u0438\u043D/\u043C\u0430\u043A\u0441", ping_minmax),
				list("\u0417\u0430\u0434\u0435\u0440\u0436\u043A\u0430 \u0441\u0435\u0440\u0432\u0435\u0440\u0430", "[avg_delay]ms"),
				list("FPS \u043D\u0430\u0441\u0442\u0440\u043E\u0439\u043A\u0438", jointext(fps_parts, ", ")),
				list("BYOND \u0432\u0435\u0440\u0441\u0438\u0438", jointext(ver_parts, ", "))
			)
		else
			cached_client_stats = null
	if(cached_client_stats)
		key_ss["Clients"] = cached_client_stats
	server_info["key_ss"] = key_ss

	mc_data_encoded = url_encode(json_encode(server_info))

	// Subsystem rows: [name, state, cost, tick_usage, tick_overrun, ticks, times_fired, can_fire, is_bg, ref, stat_extra]
	var/list/ss_data = list()
	for(var/datum/controller/subsystem/SS as anything in Master.subsystems)
		var/is_active = (SS.can_fire && !(SS.flags & SS_NO_FIRE)) ? 1 : 0
		// Extract subsystem-specific stat data (part after \t in stat_entry)
		var/stat_text = SS.stat_entry()
		var/stat_extra = ""
		var/tab_pos = findtext(stat_text, "\t")
		if(tab_pos)
			stat_extra = copytext(stat_text, tab_pos + 1)
		ss_data[++ss_data.len] = list(
			SS.name,
			SS.state,
			round(SS.cost, 0.1),
			round(SS.tick_usage, 0.1),
			round(SS.tick_overrun, 0.1),
			round(SS.ticks, 0.1),
			SS.times_fired,
			is_active,
			(SS.flags & SS_BACKGROUND) ? 1 : 0,
			"\ref[SS]",
			stat_extra
		)
	mc_ss_data_encoded = url_encode(json_encode(ss_data))

/atom/proc/remove_from_cache()
	SSstatpanels.cached_images -= REF(src)

/// verbs that send information from the browser UI
/client/verb/set_tab(tab as text|null)
	set name = "Set Tab"
	set hidden = TRUE

	stat_tab = tab

/client/verb/send_tabs(tabs as text|null)
	set name = "Send Tabs"
	set hidden = TRUE

	panel_tabs |= tabs

/client/verb/remove_tabs(tabs as text|null)
	set name = "Remove Tabs"
	set hidden = TRUE

	panel_tabs -= tabs

/client/verb/reset_tabs()
	set name = "Reset Tabs"
	set hidden = TRUE

	panel_tabs = list()

/client/verb/panel_ready()
	set name = "Panel Ready"
	set hidden = TRUE

	statbrowser_ready = TRUE
	init_verbs()
	// Re-apply theme and favorites after byondStorage is guaranteed available
	src << output("1", "statbrowser:reapply_storage")
