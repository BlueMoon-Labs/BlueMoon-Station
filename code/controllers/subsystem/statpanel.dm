#define LISTED_TURF_LIST_REFRESH_INTERVAL (2 SECONDS)
#define LISTED_TURF_ICON_REFRESH_INTERVAL (10 SECONDS)
/// Minimum gap between signal-driven listed-turf refreshes — coalesces churn on busy turfs (lockers, brigs, fights).
#define LISTED_TURF_DIRTY_MIN_INTERVAL (3) // 0.3 seconds
/// Inactivity threshold (deciseconds) after which heavy per-client work is skipped.
#define STATPANEL_AFK_INACTIVITY (5 MINUTES)
/// MC subsystem rows: each fire reuses cached payload until this many fires have elapsed.
#define MC_DATA_REFRESH_FIRES 6
/// Full-cycle gate for slow global data (vote, server section).
#define STATPANEL_FULL_CYCLE_FIRES 3
/// Refresh slow server section every Nth full cycle.
#define STATPANEL_SLOW_CYCLE_FULLS 9
/// Number of stagger groups across clients — each client receives a heavy update every (group * wait) deciseconds.
#define STATPANEL_STAGGER_GROUPS 3
/// LRU cap for per-client statpanel_sent_icons; older entries are evicted as new ones arrive.
#define STATPANEL_ICON_CACHE_CAP 256
/// Атомам с большим числом оверлеев иконку не флаттеним: один getFlatIcon одетого человека
/// (30-80 оверлеев) блокирует тик на 150-250мс Blend'ов. Таким отдаётся базовая иконка.
#define STATPANEL_MAX_FLAT_OVERLAYS 12
/// Send tidi only every Nth ping fire — non-Status-tab clients still see fresh ping every fire.
#define STATPANEL_TIDI_INTERVAL 10
/// Bridge protocol version. Bump whenever the DM->JS payload shape changes incompatibly.
#define STATBROWSER_PROTOCOL_VERSION 2
/// Channel keys for client.statpanel_last_sent dirty cache. String constants kept in one place
/// so DM-side dirty checks and any future invalidation paths can share them.
#define STATPANEL_CHANNEL_STATUS "status"
#define STATPANEL_CHANNEL_VOTING "voting"
#define STATPANEL_CHANNEL_SPELLS "spells"
#define STATPANEL_CHANNEL_TICKETS "tickets"
#define STATPANEL_CHANNEL_SDQL2 "sdql2"

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
	var/mc_iteration_sent = 0
	var/list/icon_queue = list()
	var/icon_budget_per_tick = 5
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
	var/tidi_counter = 0
	var/is_full_cycle = FALSE
	var/prev_player_count = 0
	var/client_stagger_groups = STATPANEL_STAGGER_GROUPS
	var/client_stagger_index = 0
	var/cached_tickets_encoded
	var/list/cached_client_stats
	var/client_stats_refresh_counter = 0
	var/list/ping_run = list()
	var/list/icon_run = list()

/datum/controller/subsystem/statpanels/Initialize(start_timeofday)
	build_global_slow_payload()
	..()

/// Builds the slow-changing server section once. Used for eager init so the first ~27 seconds of a round
/// don't ship an empty server section to every Status-tab client.
/datum/controller/subsystem/statpanels/proc/build_global_slow_payload()
	var/datum/map_config/cached = SSmapping?.next_map_config
	var/list/server_section = list(
		list("Карта", SSmapping?.config?.map_name || "Loading..."))
	if(cached)
		server_section += list(list("Следующая карта", cached.map_name))
	var/current_players = length(GLOB.clients)
	var/player_delta = current_players - prev_player_count
	var/player_trend = "[current_players]"
	if(prev_player_count && player_delta != 0)
		player_trend = "[current_players] ([player_delta > 0 ? "+" : ""][player_delta])"
	prev_player_count = current_players
	server_section += list(
		list("ID раунда", GLOB.round_id ? GLOB.round_id : "NULL"),
		list("Игровой Режим", GLOB.master_mode),
		list("Подключено Игроков", player_trend),
		list("Предыдущие Режимы", SSpersistence ? jointext(SSpersistence.saved_modes, ", ") : ""))
	encoded_global_slow = url_encode(json_encode(server_section))

/datum/controller/subsystem/statpanels/fire(resumed = FALSE)
	if (!resumed)
		full_cycle_counter++
		slow_data_counter++
		tidi_counter++
		is_full_cycle = (full_cycle_counter >= STATPANEL_FULL_CYCLE_FIRES)
		var/is_slow_cycle = (slow_data_counter >= STATPANEL_SLOW_CYCLE_FULLS)
		if(is_full_cycle)
			full_cycle_counter = 0
		if(is_slow_cycle)
			slow_data_counter = 0
		var/include_tidi_in_ping = (tidi_counter >= STATPANEL_TIDI_INTERVAL)
		if(include_tidi_in_ping)
			tidi_counter = 0

		var/list/tidi_data = list(
			round(SStime_track.time_dilation_current, 0.1),
			round(SStime_track.time_dilation_avg_fast, 0.1),
			round(SStime_track.time_dilation_avg, 0.1),
			round(SStime_track.time_dilation_avg_slow, 0.1))
		// Only encode the tidi payload on the rare ping fires that ship it; saves work otherwise.
		encoded_tidi = include_tidi_in_ping ? url_encode(json_encode(tidi_data)) : ""

		// Compute fast global data every fire — cheap, and stagger groups need fresh data each fire
		var/round_time = world.time - SSticker.round_start_time
		var/real_round_time = world.timeofday - SSticker.real_round_start_time
		var/list/fast_data = list()
		fast_data["time"] = list(
			list("Время Раунда", time2text(round_time, "hh:mm:ss", 0)),
			list("Наст. Время Раунда", time2text(real_round_time, "hh:mm:ss", 0)),
			list("Дата", "[time2text(world.realtime, "MMM DD")] [GLOB.year_integer]"),
			list("Время Станции", STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)),
			list("Время в Солнечной", SOLAR_TIME_TIMESTAMP("hh:mm:ss", world.time)),
			list("Время Сервера", time2text(world.timeofday, "YYYY-MM-DD hh:mm:ss")))
		fast_data["tidi"] = tidi_data
		if(SSshuttle.emergency)
			var/ETA = SSshuttle.emergency.getModeStr()
			if(ETA)
				var/timer_total = 0
				if(SSshuttle.emergency.last_timer_length)
					timer_total = round(SSshuttle.emergency.last_timer_length / 10, 1)
				fast_data["shuttle"] = list(ETA, SSshuttle.emergency.getTimerStr(), SSshuttle.emergency.mode, timer_total)
		encoded_global_fast = url_encode(json_encode(fast_data))

		// is_full_cycle gates slow-updating global data and vote cache only;
		// per-client throttling is handled by stagger groups (each client visited every Nth fire)
		if(is_full_cycle)
			if(is_slow_cycle)
				build_global_slow_payload()

			cached_vote_base = null
			cached_vote_encoded = null
			if(SSvote.mode)
				var/list/vote_base = list(
					list("Vote active!", "There is currently a vote running. Question: [SSvote.question]"))
				if(!(SSvote.vote_system in list(PLURALITY_VOTING, APPROVAL_VOTING, SCHULZE_VOTING, INSTANT_RUNOFF_VOTING)))
					vote_base[++vote_base.len] += list("STATPANEL VOTING DISABLED!", "The current vote system is not supported by statpanel rendering. Please vote manually by opening the vote popup using the action button or chat link.", "disabled")
				else
 //BLUEMOON ADDITION START
					var/time_left = SSticker.timeLeft
					if(SSvote.mode == "roundtype")
						time_left = max(time_left - ROUNDTYPE_VOTE_END_PENALTY, 0)
 //BLUEMOON ADDITION END
					vote_base[++vote_base.len] += list("Time Left:", " [DisplayTimeText(time_left)]")
					vote_base[++vote_base.len] += list("Choices:", "")
				cached_vote_base = vote_base

		mc_data_refresh_counter++
		if(mc_data_refresh_counter >= MC_DATA_REFRESH_FIRES)
			mc_data_encoded = null
			mc_ss_data_encoded = null
			mc_data_refresh_counter = 0

		if(!null_bullet_encoded)
			null_bullet_encoded = url_encode(json_encode(list(list(null))))

		// Adaptive wait and icon budget based on server load
		var/client_count = length(GLOB.clients)
		if(client_count > 60 || SStime_track.time_dilation_current > 20)
			wait = 5
			icon_budget_per_tick = 2
		else if(client_count > 40 || SStime_track.time_dilation_current > 10)
			wait = 4
			icon_budget_per_tick = 5
		else
			wait = 3
			icon_budget_per_tick = 8

		// Build staggered client list — each fire processes 1/N of all clients
		// Each client gets a full update every (stagger_groups * wait) deciseconds.
		// Copy() so a disconnect mid-cycle that mutates GLOB.clients can't desync our snapshot.
		var/list/all_clients = GLOB.clients.Copy()
		var/list/run_list = list()
		for(var/i in (client_stagger_index + 1) to length(all_clients) step client_stagger_groups)
			run_list += all_clients[i]
		client_stagger_index = (client_stagger_index + 1) % client_stagger_groups
		cached_tickets_encoded = null
		src.currentrun = run_list

		// Ping forwarding — ALL clients every fire, independent of stagger.
		src.ping_run = all_clients

		// Snapshot icon queue clients for resumable processing
		src.icon_run = list()
		for(var/client/C as anything in icon_queue)
			src.icon_run += C

	// Process ping queue (resumable)
	while(length(ping_run))
		var/client/ping_target = ping_run[length(ping_run)]
		ping_run.len--
		if(!ping_target?.statbrowser_ready || !ping_target.ping_updated || ping_target.inactivity >= STATPANEL_AFK_INACTIVITY)
			continue
		ping_target.ping_updated = FALSE
		// Tidi is only included every Nth fire; saves repeated identical bytes across the client list otherwise.
		ping_target << output("%5B[round(ping_target.lastping, 1)]%2C[round(ping_target.avgping, 1)]%2C[round(ping_target.avgping_jitter, 1)]%5D;[encoded_tidi]", "statbrowser:update_ping")
		if(MC_TICK_CHECK)
			return

	var/list/currentrun = src.currentrun
	while(length(currentrun))
		var/client/target = currentrun[length(currentrun)]
		currentrun.len--
		if(!target?.statbrowser_ready)
			continue

		// Ack protocol version once per session so JS can detect a stale cached HTML mismatch.
		if(!target.statpanel_protocol_acked)
			target << output("[STATBROWSER_PROTOCOL_VERSION]", "statbrowser:set_protocol_version")
			target.statpanel_protocol_acked = TRUE

		// Skip heavy work for AFK clients (5 min inactivity)
		// Admin clients are also skipped; they self-recover on the first active fire
		if(target.inactivity >= STATPANEL_AFK_INACTIVITY)
			if(!target.holder && !target.admin_tabs_cleared)
				target << output("", "statbrowser:remove_admin_tabs")
				target.admin_tabs_cleared = TRUE
			if(MC_TICK_CHECK)
				return
			continue

		if(target.stat_tab == "Status")
			var/raw_status = json_encode(target.mob?.get_status_tab_items())
			// Per-client dirty check: only re-encode + ship if the mob's status payload actually changed.
			var/last_status = target.statpanel_last_sent[STATPANEL_CHANNEL_STATUS]
			var/status_changed = (raw_status != last_status)
			var/other_str = status_changed ? url_encode(raw_status) : null
			var/slow_str = encoded_global_slow ? encoded_global_slow : ""
			// Always send the fast/slow payload (timer/round-time tick every second). Mob other_str is
			// suppressed when unchanged; JS retains its last decoded value.
			if(status_changed)
				target << output("[encoded_global_fast];[slow_str];[other_str]", "statbrowser:update")
				target.statpanel_last_sent[STATPANEL_CHANNEL_STATUS] = raw_status
			else
				target << output("[encoded_global_fast];[slow_str];", "statbrowser:update")

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
				var/raw_vote = json_encode(vote_arry)
				if(target.statpanel_last_sent[STATPANEL_CHANNEL_VOTING] != raw_vote)
					target << output("[url_encode(raw_vote)]", "statbrowser:update_voting")
					target.statpanel_last_sent[STATPANEL_CHANNEL_VOTING] = raw_vote
				target.stat_vote_sent_null = FALSE
			else if(!target.stat_vote_sent_null)
				target << output("[null_bullet_encoded]", "statbrowser:update_voting")
				target.stat_vote_sent_null = TRUE
				target.statpanel_last_sent -= STATPANEL_CHANNEL_VOTING

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
					mc_iteration_sent = Master.iteration
				// Send mc_iteration alongside payload so JS can dedupe without JSON.stringify-hashing each update.
				if(target.statpanel_last_mc_iter != mc_iteration_sent)
					target << output("[mc_data_encoded];[mc_ss_data_encoded];[coord_entry];[mc_iteration_sent]", "statbrowser:update_mc")
					target.statpanel_last_mc_iter = mc_iteration_sent
				else
					// Iteration unchanged — only ship coords (cheap, eye position changes per move).
					target << output(";;[coord_entry];[mc_iteration_sent]", "statbrowser:update_mc")
			if(target.stat_tab == "Tickets")
				if(!cached_tickets_encoded)
					cached_tickets_encoded = url_encode(json_encode(GLOB.ahelp_tickets.stat_entry()))
				if(target.statpanel_last_sent[STATPANEL_CHANNEL_TICKETS] != cached_tickets_encoded)
					target << output("[cached_tickets_encoded];", "statbrowser:update_tickets")
					target.statpanel_last_sent[STATPANEL_CHANNEL_TICKETS] = cached_tickets_encoded
			if(!length(GLOB.sdql2_queries) && ("SDQL2" in target.panel_tabs))
				target << output("", "statbrowser:remove_sdql2")
				target.statpanel_last_sent -= STATPANEL_CHANNEL_SDQL2
			else if(length(GLOB.sdql2_queries) && (target.stat_tab == "SDQL2" || !("SDQL2" in target.panel_tabs)))
				var/list/sdql2A = list()
				sdql2A[++sdql2A.len] = list("", "Access Global SDQL2 List", REF(GLOB.sdql2_vv_statobj))
				var/list/sdql2B = list()
				for(var/i in GLOB.sdql2_queries)
					var/datum/SDQL2_query/Q = i
					sdql2B = Q.generate_stat()
				sdql2A += sdql2B
				var/raw_sdql = json_encode(sdql2A)
				if(target.statpanel_last_sent[STATPANEL_CHANNEL_SDQL2] != raw_sdql)
					target << output(url_encode(raw_sdql), "statbrowser:update_sdql2")
					target.statpanel_last_sent[STATPANEL_CHANNEL_SDQL2] = raw_sdql

		if(target.mob)
			var/mob/M = target.mob
			// Process listed-turf BEFORE the spell tick check, so the listed-turf path is not starved
			// when a slow fire yields halfway through this client's per-tick work.
			if(M?.listed_turf)
				var/mob/target_mob = M
				if(QDELETED(target_mob.listed_turf) || !target_mob.TurfAdjacent(target_mob.listed_turf))
					target.clear_listed_turf()
				else if(target.stat_tab == M?.listed_turf.name || !(M?.listed_turf.name in target.panel_tabs))
					refresh_listed_turf(target)
			if((target.stat_tab in target.spell_tabs) || !length(target.spell_tabs) && (length(M.mob_spell_list) || length(M.mind?.spell_list)))
				var/list/proc_holders = M.get_proc_holders()
				target.spell_tabs.Cut()
				for(var/phl in proc_holders)
					var/list/proc_holder_list = phl
					target.spell_tabs |= proc_holder_list[1]
				var/proc_holders_encoded = ""
				if(length(proc_holders))
					proc_holders_encoded = url_encode(json_encode(proc_holders))
				var/raw_spells = "[json_encode(target.spell_tabs)];[proc_holders_encoded]"
				if(target.statpanel_last_sent[STATPANEL_CHANNEL_SPELLS] != raw_spells)
					target << output("[url_encode(json_encode(target.spell_tabs))];[proc_holders_encoded]", "statbrowser:update_spells")
					target.statpanel_last_sent[STATPANEL_CHANNEL_SPELLS] = raw_spells
		if(MC_TICK_CHECK)
			return

	// --- Progressive icon generation (resumable via icon_run) ---
	var/queued_clients = length(icon_run)
	var/per_client_budget = queued_clients ? max(round(icon_budget_per_tick / queued_clients), 1) : icon_budget_per_tick
	while(length(icon_run))
		var/client/C = icon_run[length(icon_run)]
		icon_run.len--
		if(!C?.statbrowser_ready || !C.mob?.listed_turf)
			icon_queue -= C
			continue
		var/list/pending = icon_queue[C]
		if(!length(pending))
			icon_queue -= C
			continue
		var/list/batch = list()
		var/icons_done = 0
		while(length(pending) && icons_done < per_client_budget)
			var/atom/A = pending[length(pending)]
			pending.len--
			if(QDELETED(A))
				continue
			var/ref = REF(A)
			if(C.statpanel_sent_icons[ref])
				continue
			var/icon_url
			var/overlay_count = length(A.overlays)
			if((ismob(A) || overlay_count > 4) && overlay_count <= STATPANEL_MAX_FLAT_OVERLAYS)
				icon_url = costly_icon2html(A, C, sourceonly=TRUE)
			else
				icon_url = icon2html(A, C, sourceonly=TRUE)
			if(icon_url)
				cache_sent_icon(C, ref, icon_url)
				batch[++batch.len] = list(ref, icon_url)
			icons_done++
			// Бюджет в штуках не ограничивает время: тик-чек после каждой сгенерированной иконки,
			// иначе пачка дорогих флаттенов складывается в сотни мс одним тиком
			if(MC_TICK_CHECK)
				break
		if(length(batch))
			C << output("[url_encode(json_encode(batch))];", "statbrowser:update_turf_icons")
		if(!length(pending))
			icon_queue -= C
		if(MC_TICK_CHECK)
			return

/// Cache an icon REF→URL on the client with a soft LRU bound. When the cap is hit, the oldest
/// entries are evicted (BYOND assoc lists preserve insertion order). Prevents 4-hour sessions
/// from accumulating multi-MB caches and avoids serving stale icons across REF recycling.
/datum/controller/subsystem/statpanels/proc/cache_sent_icon(client/C, ref, icon_url)
	if(!C || !ref || !icon_url)
		return
	if(C.statpanel_sent_icons[ref])
		C.statpanel_sent_icons[ref] = icon_url
		return
	C.statpanel_sent_icons[ref] = icon_url
	var/overflow = length(C.statpanel_sent_icons) - STATPANEL_ICON_CACHE_CAP
	if(overflow > 0)
		C.statpanel_sent_icons.Cut(1, overflow + 1)

/datum/controller/subsystem/statpanels/proc/get_listedturf_overrides(client/target, turf/listed)
	if(!target || !listed || !length(target.images))
		return null
	var/list/overrides = list()
	for(var/img in target.images)
		var/image/target_image = img
		if(!target_image.loc || target_image.loc.loc != listed || !target_image.override)
			continue
		overrides += target_image.loc
	return overrides

/datum/controller/subsystem/statpanels/proc/build_listedturf_snapshot(turf/listed, see_invisible, list/overrides = null, list/sent_icons = null)
	if(!listed || QDELETED(listed))
		return null
	var/list/turfitems = list()
	var/list/needs_icons = list()
	var/listed_ref = REF(listed)
	turfitems[++turfitems.len] = list("[listed]", listed_ref)
	if(!sent_icons || !sent_icons[listed_ref])
		needs_icons += listed
	for(var/tc in listed)
		var/atom/movable/turf_content = tc
		if(QDELETED(turf_content))
			continue
		if(turf_content.mouse_opacity == MOUSE_OPACITY_TRANSPARENT)
			continue
		if(turf_content.invisibility > see_invisible)
			continue
		if(overrides && (turf_content in overrides))
			continue
		if(turf_content.IsObscured())
			continue
		var/ref = REF(turf_content)
		turfitems[++turfitems.len] = list("[turf_content.name]", ref)
		if(!sent_icons || !sent_icons[ref])
			needs_icons += turf_content
	return list(
		"entries" = turfitems,
		"encoded" = url_encode(json_encode(turfitems)),
		"needs_icons" = needs_icons,
	)

/datum/controller/subsystem/statpanels/proc/get_listedturf_refresh_actions(force_send = FALSE, force_icon_refresh = FALSE, turf_changed = FALSE, listed_turf_dirty = FALSE, listed_turf_dirty_at = 0, listed_turf_icon_refresh_pending = FALSE, eye_changed = FALSE, last_refresh = 0, last_icon_refresh = 0, current_time = world.time)
	// Dirty signals coalesce: a busy turf that fires entered/exited every tick is rate-limited so
	// we don't rebuild the snapshot at full subsystem fire rate. Force/turf/eye changes still bypass.
	var/dirty_due = listed_turf_dirty && (!listed_turf_dirty_at || (current_time - last_refresh) >= LISTED_TURF_DIRTY_MIN_INTERVAL)
	var/list_refresh_due = force_send || turf_changed || eye_changed || dirty_due || (current_time - last_refresh >= LISTED_TURF_LIST_REFRESH_INTERVAL)
	var/icon_refresh_due = force_icon_refresh || listed_turf_icon_refresh_pending || turf_changed || !last_icon_refresh || (current_time - last_icon_refresh >= LISTED_TURF_ICON_REFRESH_INTERVAL)
	return list(
		"list_refresh_due" = list_refresh_due,
		"icon_refresh_due" = icon_refresh_due,
	)

/datum/controller/subsystem/statpanels/proc/merge_listedturf_icon_queue(list/existing, list/needs_icons)
	if(!length(needs_icons))
		return existing
	if(!existing)
		return needs_icons.Copy()
	for(var/atom/A as anything in needs_icons)
		if(!(A in existing))
			existing += A
	return existing

/datum/controller/subsystem/statpanels/proc/queue_listedturf_icons(client/target, list/needs_icons)
	if(!target || !length(needs_icons))
		return
	icon_queue[target] = merge_listedturf_icon_queue(icon_queue[target], needs_icons)

/datum/controller/subsystem/statpanels/proc/refresh_listed_turf(client/target, force_send = FALSE, force_icon_refresh = FALSE)
	if(!target?.statbrowser_ready)
		return
	var/mob/target_mob = target.mob
	var/turf/listed = target_mob?.listed_turf
	if(!target_mob || !listed || QDELETED(listed) || !target_mob.TurfAdjacent(listed))
		target?.clear_listed_turf()
		return
	var/turf_ref = REF(listed)
	var/turf_changed = turf_ref != target.cached_turf_ref
	var/turf/eye_turf = get_turf(target.eye)
	var/eye_turf_ref = eye_turf ? REF(eye_turf) : null
	var/eye_changed = eye_turf_ref != target.listed_turf_eye_ref
	var/list/refresh_actions = get_listedturf_refresh_actions(force_send, force_icon_refresh, turf_changed, target.listed_turf_dirty, target.listed_turf_dirty_at, target.listed_turf_icon_refresh_pending, eye_changed, target.listed_turf_last_refresh, target.listed_turf_last_icon_refresh)
	var/list_refresh_due = refresh_actions["list_refresh_due"]
	var/icon_refresh_due = refresh_actions["icon_refresh_due"]
	if(!list_refresh_due && !icon_refresh_due)
		return
	if(icon_refresh_due)
		target.reset_listed_turf_icon_cache()
	var/list/overrides = get_listedturf_overrides(target, listed)
	var/list/snapshot = build_listedturf_snapshot(listed, target_mob.see_invisible, overrides, target.statpanel_sent_icons)
	if(!snapshot)
		target.clear_listed_turf()
		return
	var/encoded = snapshot["encoded"]
	if(force_send || encoded != target.cached_turf_encoded)
		target << output("[encoded];", "statbrowser:update_listedturf")
		target.cached_turf_encoded = encoded
		target.listed_turf_last_refresh = world.time
	else if(list_refresh_due)
		target.listed_turf_last_refresh = world.time
	target.cached_turf_ref = turf_ref
	target.listed_turf_eye_ref = eye_turf_ref
	target.listed_turf_dirty = FALSE
	target.listed_turf_dirty_at = 0
	target.listed_turf_icon_refresh_pending = FALSE
	if(icon_refresh_due)
		target.listed_turf_last_icon_refresh = world.time
	queue_listedturf_icons(target, snapshot["needs_icons"])


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
	// MC state — iteration is the natural per-tick counter; JS uses it to dedupe identical payloads.
	server_info["iteration"] = Master.iteration
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
		list("Высокое давление", round(SSair.cost_highpressure, 0.1)),
		list("Горение", round(SSair.cost_hotspots, 0.1)),
		list("Сверхпроводимость", round(SSair.cost_superconductivity, 0.1)),
		list("Трубопроводы", round(SSair.cost_pipenets, 0.1)),
		list("Атмос. машины", round(SSair.cost_atmos_machinery, 0.1)),
		list("Активные тайлы", round(SSair.cost_turfs, 0.1)),
		list("Очаги", SSair.hotspots.len),
		list("Сети", SSair.networks.len),
		list("Выс давл. тайлы", SSair.high_pressure_turfs),
		list("Низк давл. тайлы", SSair.low_pressure_turfs),
		list("Газовые смеси", SSair.gas_mixes_count)
	)
	// Garbage Collector
	var/gc_ratio = (SSgarbage.totaldels + SSgarbage.totalgcs) ? "[round((SSgarbage.totalgcs / (SSgarbage.totaldels + SSgarbage.totalgcs)) * 100, 0.1)]%" : "n/a"
	var/list/gc_queue_counts = list()
	for (var/i in 1 to GC_QUEUE_COUNT)
		gc_queue_counts += SSgarbage.GetQueueDepth(i)
	key_ss["Garbage"] = list(
		list("Очереди", gc_queue_counts.Join(", ")),
		list("Del/тик", SSgarbage.delslasttick),
		list("GC/тик", SSgarbage.gcedlasttick),
		list("Всего Del", SSgarbage.totaldels),
		list("Всего GC", SSgarbage.totalgcs),
		list("GC %", gc_ratio)
	)
	// Machines
	key_ss["Machines"] = list(
		list("Всего машин", SSmachines.get_machine_count()),
		list("Типов", SSmachines.get_machine_type_count()),
		list("Обработка", length(SSmachines.processing)),
		list("Энергосети", length(SSmachines.powernets))
	)
	// Mobs
	key_ss["Mobs"] = list(
		list("Живых мобов", length(GLOB.mob_living_list))
	)
	// Timer
	key_ss["Timer"] = list(
		list("Бакеты", SStimer.bucket_count),
		list("Очередь", length(SStimer.second_queue)),
		list("Хэши", length(SStimer.hashes)),
		list("Клиент таймеры", length(SStimer.clienttime_timers)),
		list("Всего ID", length(SStimer.timer_id_dict))
	)
	// Objects (processing subsystem)
	key_ss["Objects"] = list(
		list("Обработка", length(SSobj.processing))
	)
	// Lighting
	var/light_total = SSlighting.cost_sources + SSlighting.cost_corners + SSlighting.cost_objects
	var/light_pct_s = light_total > 0 ? round(SSlighting.cost_sources / light_total * 100) : 0
	var/light_pct_c = light_total > 0 ? round(SSlighting.cost_corners / light_total * 100) : 0
	var/light_pct_o = light_total > 0 ? round(SSlighting.cost_objects / light_total * 100) : 0
	var/light_avg = SSlighting.avg_sources_processed >= 0.5 ? round(SSlighting.cost_sources / SSlighting.avg_sources_processed, 0.01) : 0
	key_ss["Lighting"] = list(
		list("Очередь источ.", length(GLOB.lighting_update_lights)),
		list("Очередь углов", length(GLOB.lighting_update_corners)),
		list("Очередь объект.", length(GLOB.lighting_update_objects)),
		list("Кэп источников", SSlighting.sources_cap),
		list("Фаза: Источники", "[round(SSlighting.cost_sources, 0.1)]ms ([light_pct_s]%)"),
		list("Фаза: Углы", "[round(SSlighting.cost_corners, 0.1)]ms ([light_pct_c]%)"),
		list("Фаза: Объекты", "[round(SSlighting.cost_objects, 0.1)]ms ([light_pct_o]%)"),
		list("Среднее/источник", "[light_avg]ms ([round(SSlighting.avg_sources_processed)] шт)"),
		list("Пик: Ист./Угл./Объ.", "[SSlighting.peak_sources]/[SSlighting.peak_corners]/[SSlighting.peak_objects]"),
		list("Худший fire", "[round(SSlighting.worst_fire_cost, 0.1)]ms"),
		list("Кэш таблиц", length(GLOB.lighting_sheets)),
		list("Звёздные тайлы", length(GLOB.starlight))
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
				list("Подключено", length(GLOB.clients)),
				list("Ping средний", "[avg_ping]ms"),
				list("Ping мин/макс", ping_minmax),
				list("Задержка сервера", "[avg_delay]ms"),
				list("FPS настройки", jointext(fps_parts, ", ")),
				list("BYOND версии", jointext(ver_parts, ", "))
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
	// Re-acknowledge protocol on each ready event so JS can detect a stale cached HTML.
	statpanel_protocol_acked = FALSE
	statpanel_last_sent.Cut()
	statpanel_last_mc_iter = -1
	init_verbs()
	// Re-apply theme and favorites after byondStorage is guaranteed available
	src << output("1", "statbrowser:reapply_storage")
	// Send current ping immediately so the ping bar appears without waiting for stagger cycle
	var/ping_str = "%5B[round(lastping, 1)]%2C[round(avgping, 1)]%2C[round(avgping_jitter, 1)]%5D"
	var/list/tidi = list(
		round(SStime_track.time_dilation_current, 0.1),
		round(SStime_track.time_dilation_avg_fast, 0.1),
		round(SStime_track.time_dilation_avg, 0.1),
		round(SStime_track.time_dilation_avg_slow, 0.1))
	src << output("[ping_str];[url_encode(json_encode(tidi))]", "statbrowser:update_ping")
	if(mob?.listed_turf)
		open_listed_turf(mob.listed_turf)

#undef LISTED_TURF_LIST_REFRESH_INTERVAL
#undef LISTED_TURF_ICON_REFRESH_INTERVAL
#undef LISTED_TURF_DIRTY_MIN_INTERVAL
#undef STATPANEL_AFK_INACTIVITY
#undef MC_DATA_REFRESH_FIRES
#undef STATPANEL_FULL_CYCLE_FIRES
#undef STATPANEL_SLOW_CYCLE_FULLS
#undef STATPANEL_STAGGER_GROUPS
#undef STATPANEL_ICON_CACHE_CAP
#undef STATPANEL_MAX_FLAT_OVERLAYS
#undef STATPANEL_TIDI_INTERVAL
#undef STATBROWSER_PROTOCOL_VERSION
#undef STATPANEL_CHANNEL_STATUS
#undef STATPANEL_CHANNEL_VOTING
#undef STATPANEL_CHANNEL_SPELLS
#undef STATPANEL_CHANNEL_TICKETS
#undef STATPANEL_CHANNEL_SDQL2
