/// Write ping diagnostics every 60 seconds under normal conditions.
#define PING_PERF_LOG_EVERY_TICKS 120
/// Always flush diagnostics early when RTT spikes above this threshold.
#define PING_PERF_SPIKE_RTT_MS 20
/// Always flush diagnostics early when raw glide jitter is unusually high.
#define PING_PERF_SPIKE_JITTER_PCT 8
/// Always flush diagnostics early on visible tick dilation spikes.
#define PING_PERF_SPIKE_TIDI_PCT 5

SUBSYSTEM_DEF(time_track)
	name = "Time Tracking"
	wait = 5
	flags = SS_NO_TICK_CHECK
	init_order = INIT_ORDER_TIMETRACK
	runlevels = RUNLEVEL_LOBBY | RUNLEVELS_DEFAULT

	var/time_dilation_current = 0

	var/time_dilation_avg_fast = 0
	var/time_dilation_avg = 0
	var/time_dilation_avg_slow = 0

	var/first_run = TRUE

	/// Last realtime value used for per-fire raw multiplier tracking.
	var/last_raw_realtime = 0
	/// Last byond world.time used for per-fire raw multiplier tracking.
	var/last_raw_byond_time = 0

	var/last_tick_realtime = 0
	var/last_tick_byond_time = 0
	var/last_tick_tickcount = 0

	var/raw_multiplier_last = 1
	var/raw_multiplier_jitter_abs_last = 0
	var/raw_multiplier_jitter_abs_avg = 0
	var/raw_multiplier_jitter_abs_max_window = 0
	var/glide_size_multiplier_current = 1

	var/ping_samples = 0
	var/ping_rtt_last_avg = 0
	var/ping_rtt_last_max = 0
	var/ping_rtt_avg_avg = 0
	var/ping_tick_last_avg = 0
	var/ping_tick_last_max = 0
	var/ping_server_last_avg = 0
	var/ping_server_last_max = 0
	var/ping_server_avg_avg = 0

/datum/controller/subsystem/time_track/Initialize(start_timeofday)
	. = ..()
	GLOB.perf_log = "[GLOB.log_directory]/perf-[GLOB.round_id ? GLOB.round_id : "NULL"]-[SSmapping.config?.map_name].csv"
	GLOB.ping_perf_log = "[GLOB.log_directory]/ping-perf-[GLOB.round_id ? GLOB.round_id : "NULL"]-[SSmapping.config?.map_name].csv"
	log_perf(
		list(
			"time",
			"players",
			"tidi",
			"tidi_fastavg",
			"tidi_avg",
			"tidi_slowavg",
			"maptick",
			"num_timers",
			"air_turf_cost",
			"air_turf_thread_time",
			"air_equalize_cost",
			"air_post_process_cost",
			"air_eg_cost",
			"air_highpressure_cost",
			"air_hotspots_cost",
			"air_heat_spread_cost",
			"air_pipenets_cost",
			"air_rebuilds_cost",
			"air_amt_gas_mixes",
			"air_alloc_gas_mixes",
			"air_hotspot_count",
			"air_network_count",
			"air_delta_count",
		)
	)
	log_ping_perf(
		list(
			"time",
			"players",
			"ping_samples",
			"rtt_last_avg",
			"rtt_last_max",
			"rtt_avg_avg",
			"tick_last_avg",
			"tick_last_max",
			"server_last_avg",
			"server_last_max",
			"server_avg_avg",
			"server_maint_cleanup_last_ms",
			"server_maint_cleanup_avg_ms",
			"server_maint_cleanup_target",
			"time_dilation_current",
			"maptick",
			"raw_multiplier_last",
			"raw_jitter_abs_last",
			"raw_jitter_abs_avg",
			"raw_jitter_abs_max_window",
			"glide_size_multiplier_current",
		)
	)

/datum/controller/subsystem/time_track/proc/update_ping_metrics()
	ping_samples = 0
	ping_rtt_last_avg = 0
	ping_rtt_last_max = 0
	ping_rtt_avg_avg = 0
	ping_tick_last_avg = 0
	ping_tick_last_max = 0
	ping_server_last_avg = 0
	ping_server_last_max = 0
	ping_server_avg_avg = 0

	var/rtt_last_total = 0
	var/rtt_avg_total = 0
	var/tick_last_total = 0
	var/server_last_total = 0
	var/server_avg_total = 0

	for(var/client/C as anything in GLOB.clients)
		if(!C || !C.connection_time || (world.time - C.connection_time < 25))
			continue

		var/rtt_last = C.lastping_rtt_raw
		var/rtt_avg = C.avgping_rtt_raw
		var/tick_last = C.lastping_tick
		var/server_last = C.lastping_server
		var/server_avg = C.avgping_server
		if(!rtt_last && C.lastping_rtt)
			rtt_last = C.lastping_rtt
		if(!rtt_avg && C.avgping_rtt)
			rtt_avg = C.avgping_rtt

		// Compatibility fallback for clients that only have legacy ping values populated.
		if(!rtt_last && !rtt_avg && !tick_last && !server_last && !server_avg)
			rtt_last = C.lastping
			rtt_avg = C.avgping
			tick_last = C.lastping
			server_last = 0
			server_avg = 0

		if(!rtt_last && !rtt_avg && !tick_last && !server_last && !server_avg)
			continue

		ping_samples++
		rtt_last_total += rtt_last
		rtt_avg_total += rtt_avg
		tick_last_total += tick_last
		server_last_total += server_last
		server_avg_total += server_avg

		ping_rtt_last_max = max(ping_rtt_last_max, rtt_last)
		ping_tick_last_max = max(ping_tick_last_max, tick_last)
		ping_server_last_max = max(ping_server_last_max, server_last)

	if(!ping_samples)
		return

	ping_rtt_last_avg = rtt_last_total / ping_samples
	ping_rtt_avg_avg = rtt_avg_total / ping_samples
	ping_tick_last_avg = tick_last_total / ping_samples
	ping_server_last_avg = server_last_total / ping_samples
	ping_server_avg_avg = server_avg_total / ping_samples

/datum/controller/subsystem/time_track/fire()

	var/current_realtime = REALTIMEOFDAY
	var/current_byondtime = world.time
	var/current_tickcount = world.time/world.tick_lag

	var/raw_multiplier = 1
	if(last_raw_realtime && last_raw_byond_time)
		var/raw_realtime_delta = current_realtime - last_raw_realtime
		if(raw_realtime_delta > 0)
			raw_multiplier = (current_byondtime - last_raw_byond_time) / raw_realtime_delta
	last_raw_realtime = current_realtime
	last_raw_byond_time = current_byondtime

	raw_multiplier_last = raw_multiplier
	raw_multiplier_jitter_abs_last = abs(raw_multiplier - 1) * 100
	raw_multiplier_jitter_abs_avg = raw_multiplier_jitter_abs_avg ? MC_AVERAGE(raw_multiplier_jitter_abs_avg, raw_multiplier_jitter_abs_last) : raw_multiplier_jitter_abs_last
	raw_multiplier_jitter_abs_max_window = max(raw_multiplier_jitter_abs_max_window, raw_multiplier_jitter_abs_last)

	var/candidate = clamp(raw_multiplier, 0.75, 1.25)
	if(abs(candidate - 1) < 0.01)
		candidate = 1
	if(time_dilation_avg_fast < 3)
		candidate = clamp(candidate, 0.9, 1.1)
	// Smooth the multiplier to prevent jerky visual glide transitions during load spikes.
	GLOB.glide_size_multiplier = MC_AVERAGE(GLOB.glide_size_multiplier, candidate)
	glide_size_multiplier_current = GLOB.glide_size_multiplier

	if(times_fired % 20)	// everything else is once every 10 seconds (wait=5 * 20 = 100ds)
		return

	if (!first_run)
		var/tick_drift = max(0, (((current_realtime - last_tick_realtime) - (current_byondtime - last_tick_byond_time)) / world.tick_lag))
		var/tickcount_delta = current_tickcount - last_tick_tickcount
		if(tickcount_delta > 0)
			time_dilation_current = tick_drift / tickcount_delta * 100

		time_dilation_avg_fast = MC_AVERAGE_FAST(time_dilation_avg_fast, time_dilation_current)
		time_dilation_avg = MC_AVERAGE(time_dilation_avg, time_dilation_avg_fast)
		time_dilation_avg_slow = MC_AVERAGE_SLOW(time_dilation_avg_slow, time_dilation_avg)
	else
		first_run = FALSE
	last_tick_realtime = current_realtime
	last_tick_byond_time = current_byondtime
	last_tick_tickcount = current_tickcount
	update_ping_metrics()
	SSblackbox.record_feedback("associative", "time_dilation_current", 1, list("[SQLtime()]" = list("current" = "[time_dilation_current]", "avg_fast" = "[time_dilation_avg_fast]", "avg" = "[time_dilation_avg]", "avg_slow" = "[time_dilation_avg_slow]")))
	log_perf(
		list(
			world.time,
			length(GLOB.clients),
			time_dilation_current,
			time_dilation_avg_fast,
			time_dilation_avg,
			time_dilation_avg_slow,
			MAPTICK_LAST_INTERNAL_TICK_USAGE,
			length(SStimer.timer_id_dict),
			SSair.cost_turfs,
			SSair.turf_process_time(),
			SSair.cost_equalize,
			SSair.cost_post_process,
			SSair.cost_groups,
			SSair.cost_highpressure,
			SSair.cost_hotspots,
			SSair.cost_superconductivity,
			SSair.cost_pipenets,
			SSair.cost_rebuilds,
			SSair.get_amt_gas_mixes(),
			SSair.get_max_gas_mixes(),
			length(SSair.hotspots),
			length(SSair.networks),
			length(SSair.high_pressure_delta)
		)
	)
	var/should_log_ping_perf = ping_samples && (
		(times_fired % PING_PERF_LOG_EVERY_TICKS == 0) || \
		(ping_rtt_last_max >= PING_PERF_SPIKE_RTT_MS) || \
		(raw_multiplier_jitter_abs_max_window >= PING_PERF_SPIKE_JITTER_PCT) || \
		(time_dilation_current >= PING_PERF_SPIKE_TIDI_PCT)
	)
	if(should_log_ping_perf)
		log_ping_perf(
			list(
				world.time,
				length(GLOB.clients),
				ping_samples,
				ping_rtt_last_avg,
				ping_rtt_last_max,
				ping_rtt_avg_avg,
				ping_tick_last_avg,
				ping_tick_last_max,
				ping_server_last_avg,
				ping_server_last_max,
				ping_server_avg_avg,
				SSserver_maint.cleanup_last_ms,
				SSserver_maint.cleanup_avg_ms,
				SSserver_maint.cleanup_target_last,
				time_dilation_current,
				MAPTICK_LAST_INTERNAL_TICK_USAGE,
				raw_multiplier_last,
				raw_multiplier_jitter_abs_last,
				raw_multiplier_jitter_abs_avg,
				raw_multiplier_jitter_abs_max_window,
				glide_size_multiplier_current,
			)
		)
		raw_multiplier_jitter_abs_max_window = 0

#undef PING_PERF_LOG_EVERY_TICKS
#undef PING_PERF_SPIKE_RTT_MS
#undef PING_PERF_SPIKE_JITTER_PCT
#undef PING_PERF_SPIKE_TIDI_PCT
