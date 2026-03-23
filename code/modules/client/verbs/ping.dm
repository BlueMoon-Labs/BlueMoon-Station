#define PING_RTT_WINDOW_SIZE 15

/client/proc/current_ping_tickstamp()
	return world.time + world.tick_lag * TICK_USAGE_REAL / 100

/client/proc/pingfromtickstamp(tickstamp)
	return (current_ping_tickstamp() - tickstamp) * 100

/client/proc/pingfromrealtime(sent_realtime)
	return max((REALTIMEOFDAY - sent_realtime) * 100, 0)

/client/proc/stabilize_rtt_ping(raw_rtt_ping)
	raw_rtt_ping = max(raw_rtt_ping, 0)
	if(!islist(ping_rtt_window))
		ping_rtt_window = list()
	ping_rtt_window += raw_rtt_ping
	var/window_len = length(ping_rtt_window)
	if(window_len > PING_RTT_WINDOW_SIZE)
		ping_rtt_window.Cut(1, window_len - PING_RTT_WINDOW_SIZE + 1)
	var/list/sorted_samples = ping_rtt_window.Copy()
	sortTim(sorted_samples, GLOBAL_PROC_REF(cmp_numeric_asc))
	var/sample_index = max(1, CEILING(length(sorted_samples) * 0.2, 1))
	return sorted_samples[sample_index]

/client/verb/update_ping(tickstamp as num, sent_realtime as null|num)
	set instant = TRUE
	set name = ".update_ping"

	var/tick_ping = pingfromtickstamp(tickstamp)
	var/rtt_ping_raw
	if(isnum(sent_realtime))
		rtt_ping_raw = pingfromrealtime(sent_realtime)
	else
		// Backward compatibility with one-argument invocations.
		rtt_ping_raw = tick_ping
	var/rtt_ping = stabilize_rtt_ping(rtt_ping_raw)
	var/server_ping = max(tick_ping - rtt_ping_raw, 0)

	lastping_tick = tick_ping
	lastping_rtt = rtt_ping
	lastping_rtt_raw = rtt_ping_raw
	lastping_server = server_ping
	lastping = rtt_ping

	if(!avgping_tick)
		avgping_tick = tick_ping
	else
		avgping_tick = MC_AVERAGE_SLOW(avgping_tick, tick_ping)

	if(!avgping_rtt)
		avgping_rtt = rtt_ping
	else
		avgping_rtt = MC_AVERAGE_SLOW(avgping_rtt, rtt_ping)

	if(!avgping_rtt_raw)
		avgping_rtt_raw = rtt_ping_raw
	else
		avgping_rtt_raw = MC_AVERAGE_SLOW(avgping_rtt_raw, rtt_ping_raw)

	if(!avgping_server)
		avgping_server = server_ping
	else
		avgping_server = MC_AVERAGE_SLOW(avgping_server, server_ping)

	// Keep the legacy fields as the player-facing RTT value.
	avgping = avgping_rtt

/client/verb/display_ping(tickstamp as num, sent_realtime as null|num)
	set instant = TRUE
	set name = ".display_ping"

	var/tick_ping = pingfromtickstamp(tickstamp)
	var/rtt_ping_raw
	if(isnum(sent_realtime))
		rtt_ping_raw = pingfromrealtime(sent_realtime)
	else
		// Backward compatibility with one-argument invocations.
		rtt_ping_raw = tick_ping
	var/rtt_ping = max(rtt_ping_raw, 0)
	to_chat(src, "<span class='notice'>Round trip ping took [round(rtt_ping, 1)]ms (Stable Avg: [round(avgping, 1)]ms)</span>")

/client/verb/ping()
	set name = "Ping"
	set category = "OOC"
	winset(src, null, "command=.display_ping+[current_ping_tickstamp()]+[REALTIMEOFDAY]")

#undef PING_RTT_WINDOW_SIZE
