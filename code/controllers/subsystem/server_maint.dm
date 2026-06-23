#define PING_BUFFER_TIME 25

SUBSYSTEM_DEF(server_maint)
	name = "Server Tasks"
	wait = 6
	flags = SS_POST_FIRE_TIMING
	priority = FIRE_PRIORITY_SERVER_MAINT
	init_order = INIT_ORDER_SERVER_MAINT
	runlevels = RUNLEVEL_LOBBY | RUNLEVELS_DEFAULT
	var/list/currentrun
	var/cleanup_ticker = 0
	/// Whether this fire sends ping measurements - once per 3 fires (1.8s at wait = 6),
	/// 0.6s cadence bought nothing but ~80k verb round-trips and stats math per round.
	var/ping_send_this_fire = FALSE
	/// Last measured null-cleanup cost in ms.
	var/cleanup_last_ms = 0
	/// Running average null-cleanup cost in ms.
	var/cleanup_avg_ms = 0
	/// Name of list processed during the last cleanup pass.
	var/cleanup_target_last = "none"

/datum/controller/subsystem/server_maint/PreInit()
	world.hub_password = "" //quickly! before the hubbies see us.

/datum/controller/subsystem/server_maint/Initialize(timeofday)
	if (CONFIG_GET(flag/hub))
		world.update_hub_visibility(TRUE)
	return ..()

/datum/controller/subsystem/server_maint/proc/run_null_cleanup(list/target_list, target_name)
	var/cleanup_start = TICK_USAGE_REAL
	var/had_nulls = listclearnulls(target_list)
	var/cleanup_cost_ms = TICK_DELTA_TO_MS(TICK_USAGE_REAL - cleanup_start)
	cleanup_last_ms = cleanup_cost_ms
	cleanup_avg_ms = cleanup_avg_ms ? MC_AVERAGE(cleanup_avg_ms, cleanup_cost_ms) : cleanup_cost_ms
	cleanup_target_last = target_name
	return had_nulls

/datum/controller/subsystem/server_maint/fire(resumed = FALSE)
	if(!resumed)
		if(run_null_cleanup(GLOB.clients, "clients"))
			log_world("Found a null in clients list!")
		src.currentrun = GLOB.clients.Copy()
		ping_send_this_fire = (times_fired % 3 == 0)

		switch (cleanup_ticker) // do only one of these at a time, once per 5 fires
			if (0)
				if(run_null_cleanup(GLOB.player_list, "player_list"))
					log_world("Found a null in player_list!")
				cleanup_ticker++
			if (5)
				if(run_null_cleanup(GLOB.mob_list, "mob_list"))
					log_world("Found a null in mob_list!")
				cleanup_ticker++
			if (10)
				if(run_null_cleanup(GLOB.alive_mob_list, "alive_mob_list"))
					log_world("Found a null in alive_mob_list!")
				cleanup_ticker++
			if (15)
				if(run_null_cleanup(GLOB.dead_mob_list, "dead_mob_list"))
					log_world("Found a null in dead_mob_list!")
				cleanup_ticker++
			if (20)
				cleanup_ticker = 0
			else
				cleanup_ticker++

	var/list/currentrun = src.currentrun
	var/round_started = SSticker.HasRoundStarted()

	var/kick_inactive = CONFIG_GET(flag/kick_inactive)
	var/afk_period
	if(kick_inactive)
		afk_period = CONFIG_GET(number/afk_period)
	while(currentrun.len)
		var/client/C = currentrun[currentrun.len]
		currentrun.len--
		if(!C)
			continue
		//handle kicking inactive players
		if(round_started && kick_inactive && !C.holder && C.is_afk(afk_period))
			var/cmob = C.mob
			if (!isnewplayer(cmob) || !SSticker.queued_players.Find(cmob))
				log_access("AFK: [key_name(C)]")
				to_chat(C, "<span class='userdanger'>You have been inactive for more than [DisplayTimeText(afk_period)] and have been disconnected.</span><br><span class='danger'>You may reconnect via the button in the file menu or by <b><u><a href='byond://winset?command=.reconnect'>clicking here to reconnect</a></u></b>.</span>")
				QDEL_IN(C, 1) //to ensure they get our message before getting disconnected
				continue

		if (ping_send_this_fire && !(world.time - C.connection_time < PING_BUFFER_TIME || C.inactivity >= 3000))
			winset(C, null, "command=.update_ping+[world.time+world.tick_lag*TICK_USAGE_REAL/100]+[REALTIMEOFDAY]")

		MC_TICK_CHECK

/datum/controller/subsystem/server_maint/Shutdown()
	kick_clients_in_lobby("<span class='boldannounce'>The round came to an end with you in the lobby.</span>", TRUE) //second parameter ensures only afk clients are kicked
	var/server = CONFIG_GET(string/server)
	for(var/thing in GLOB.clients)
		if(!thing)
			continue
		var/client/C = thing
		C?.tgui_panel?.send_roundrestart()
		if(server)	//if you set a server location in config.txt, it sends you there instead of trying to reconnect to the same world address. -- NeoFite
			C << link("byond://[server]")
	var/datum/tgs_version/tgsversion = world.TgsVersion()
	if(tgsversion)
		SSblackbox.record_feedback("text", "server_tools", 1, tgsversion.raw_parameter)


#undef PING_BUFFER_TIME
