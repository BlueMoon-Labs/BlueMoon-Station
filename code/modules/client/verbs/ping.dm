#define PING_RTT_WINDOW_SIZE 15

/// Pushes a sample into a FIFO window while incrementally maintaining its sorted mirror.
/// Returns the median of the window. Replaces a full copy+TimSort per sample.
/proc/rtt_window_push(list/window, list/sorted, value, max_size)
	// evict oldest samples first so the new one always fits
	while(length(window) >= max_size)
		var/oldest = window[1]
		window.Cut(1, 2)
		var/oldest_index = sorted.Find(oldest)
		if(oldest_index)
			sorted.Cut(oldest_index, oldest_index + 1)
	window += value
	// binary search for the insertion position in the sorted mirror
	var/low = 1
	var/high = length(sorted) + 1
	while(low < high)
		var/mid = (low + high) >> 1
		if(sorted[mid] < value)
			low = mid + 1
		else
			high = mid
	sorted.Insert(low, value)
	if(length(sorted) != length(window)) // desync (window mutated externally) - rebuild the mirror
		sorted.Cut()
		sorted += window
		sortTim(sorted, GLOBAL_PROC_REF(cmp_numeric_asc))
	return sorted[max(1, CEILING(length(sorted) * 0.5, 1))]

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
	if(!islist(ping_rtt_sorted))
		ping_rtt_sorted = list()
	return rtt_window_push(ping_rtt_window, ping_rtt_sorted, raw_rtt_ping, PING_RTT_WINDOW_SIZE)

/client/verb/update_ping(tickstamp as num, sent_realtime as null|num)
	set instant = TRUE
	set name = ".update_ping"

	// Helper procs are inlined here: this verb runs roughly once per 2 seconds per client.
	var/tick_ping = (world.time + world.tick_lag * TICK_USAGE_REAL / 100 - tickstamp) * 100
	var/rtt_ping_raw
	if(isnum(sent_realtime))
		rtt_ping_raw = max((REALTIMEOFDAY - sent_realtime) * 100, 0)
	else
		// Backward compatibility with one-argument invocations.
		rtt_ping_raw = tick_ping

	// When rtt_raw is 0 the round-trip completed within a single REALTIMEOFDAY
	// tick, meaning the timer resolution is too coarse to measure it.
	// Fall back to the tick-based measurement which has finer granularity.
	var/best_ping = rtt_ping_raw ? rtt_ping_raw : tick_ping

	var/rtt_ping = stabilize_rtt_ping(best_ping)
	var/server_ping = max(tick_ping - best_ping, 0)

	var/jitter = abs(best_ping - lastping_rtt_raw)
	if(isnull(avgping_jitter))
		avgping_jitter = jitter
	else
		avgping_jitter = MC_AVERAGE_FAST(avgping_jitter, jitter)

	lastping_tick = tick_ping
	lastping_rtt = rtt_ping
	lastping_rtt_raw = best_ping
	lastping_server = server_ping
	lastping = rtt_ping
	ping_updated = TRUE

	if(isnull(avgping_rtt))
		avgping_rtt = best_ping
	else
		avgping_rtt = MC_AVG_FAST_UP_SLOW_DOWN(avgping_rtt, best_ping)

	if(isnull(avgping_rtt_raw))
		avgping_rtt_raw = best_ping
	else
		avgping_rtt_raw = MC_AVERAGE_SLOW(avgping_rtt_raw, best_ping)

	if(isnull(avgping_server))
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
	var/rtt_ping = lastping_rtt ? lastping_rtt : max(rtt_ping_raw, 0)
	to_chat(src, "<span class='notice'>Round trip ping took [round(rtt_ping, 1)]ms (Stable Avg: [round(avgping, 1)]ms)</span>")

/client/verb/ping()
	set name = "Ping"
	set category = "OOC"
	winset(src, null, "command=.display_ping+[current_ping_tickstamp()]+[REALTIMEOFDAY]")

#undef PING_RTT_WINDOW_SIZE
