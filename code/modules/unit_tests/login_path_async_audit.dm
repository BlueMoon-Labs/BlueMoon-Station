// Regression tests for world-blocking HTTP in hot paths: world.Export("http://...")
// performs the whole request on the main thread — the ENTIRE world freezes until the
// remote endpoint answers or times out (~10s+), and `set waitfor = FALSE` does NOT
// help (the block happens inside the native call, before any sleep). Production round
// on 6604475cc1 caught a 10.3s full-world freeze at roundstart from exactly this.
//
// The replacement is rustg async http (/proc/world_safe_http_get): the calling proc
// sleeps while polling, the world keeps ticking.
//
// Source-level checks via read_source_file: actually exercising these procs needs a
// real client + reachable byond.com, so we verify the structural invariant instead.

/// Locate proc body in source text by header. Returns the substring from the header
/// to the next declaration at column 0 with the given prefix (or end of file).
/datum/unit_test/proc/_extract_proc_body(source, header, next_decl_prefix = "\n/client/proc/")
	var/start = findtext(source, header)
	if(!start)
		return null
	var/search_from = start + length(header)
	var/end = findtext(source, next_decl_prefix, search_from)
	if(!end)
		end = length(source) + 1
	return copytext(source, start, end)

/// Counts non-overlapping occurrences of needle in haystack.
/datum/unit_test/proc/_count_occurrences(haystack, needle)
	var/count = 0
	var/pos = findtext(haystack, needle)
	while(pos)
		count++
		pos = findtext(haystack, needle, pos + length(needle))
	return count

/datum/unit_test/login_validate_key_in_db_is_async/Run()
	var/source = read_source_file("code/modules/client/client_procs.dm")
	TEST_ASSERT(length(source) > 1000, "client_procs.dm must be readable from the test working directory or parent checkout (got [length(source)] chars)")

	var/body = _extract_proc_body(source, "/client/proc/validate_key_in_db()")
	TEST_ASSERT_NOTNULL(body, "/client/proc/validate_key_in_db() must exist in client_procs.dm")

	// Fire-and-forget: must still detach from /client/New() at its first sleep.
	TEST_ASSERT(findtext(body, "set waitfor = FALSE"), "/client/proc/validate_key_in_db must declare 'set waitfor = FALSE' — its byond.com request must not block /client/New()")
	// And the request itself must not hold the world: rustg async, not world.Export.
	TEST_ASSERT(!findtext(body, "world.Export("), "/client/proc/validate_key_in_db must not call world.Export() — it freezes the entire world for the whole HTTP round-trip")
	TEST_ASSERT(findtext(body, "world_safe_http_get("), "/client/proc/validate_key_in_db must fetch byond.com via world_safe_http_get() (rustg async)")

/datum/unit_test/login_findjoindate_no_world_export/Run()
	var/source = read_source_file("code/modules/client/client_procs.dm")
	TEST_ASSERT(length(source) > 1000, "client_procs.dm must be readable (got [length(source)] chars)")

	var/body = _extract_proc_body(source, "/client/proc/findJoinDate()")
	TEST_ASSERT_NOTNULL(body, "/client/proc/findJoinDate() must exist in client_procs.dm")

	// findJoinDate runs synchronously inside set_client_age_from_db (its return value
	// feeds the INSERT), so it cannot be waitfor=FALSE — but it CAN sleep. rustg async
	// makes it sleep-only: the connecting client waits, the world does not.
	TEST_ASSERT(!findtext(body, "world.Export("), "/client/proc/findJoinDate must not call world.Export() — a slow byond.com at roundstart froze the whole world for 10+ seconds")
	TEST_ASSERT(findtext(body, "world_safe_http_get("), "/client/proc/findJoinDate must fetch byond.com via world_safe_http_get() (rustg async)")

/datum/unit_test/ipintel_no_world_export/Run()
	var/source = read_source_file("code/modules/admin/ipintel.dm")
	TEST_ASSERT(length(source) > 500, "ipintel.dm must be readable (got [length(source)] chars)")

	var/body = _extract_proc_body(source, "/proc/ip_intel_query(", "\n/proc/")
	TEST_ASSERT_NOTNULL(body, "/proc/ip_intel_query must exist in ipintel.dm")

	TEST_ASSERT(!findtext(body, "world.Export("), "/proc/ip_intel_query must not call world.Export() — it runs on the client login path")
	TEST_ASSERT(findtext(body, "world_safe_http_get("), "/proc/ip_intel_query must query ipintel via world_safe_http_get() (rustg async)")

/datum/unit_test/redbot_no_world_export/Run()
	var/source = read_source_file("modular_splurt/code/controllers/subsystem/redbot.dm")
	TEST_ASSERT(length(source) > 200, "redbot.dm must be readable (got [length(source)] chars)")

	// Both the roundstart serverStart notification and send_discord_message are
	// fire-and-forget GETs; a dead bot_ip must not stall init or the caller's tick.
	TEST_ASSERT(!findtext(source, "world.Export("), "SSredbot must not call world.Export() — a dead bot_ip freezes the whole world for the connect timeout")
	TEST_ASSERT(findtext(source, "world_safe_http_get"), "SSredbot must send its notifications via world_safe_http_get* (rustg async)")

/datum/unit_test/roundstart_ping_volley_is_single_message/Run()
	var/source = read_source_file("code/controllers/subsystem/ticker.dm")
	TEST_ASSERT(length(source) > 1000, "ticker.dm must be readable (got [length(source)] chars)")

	var/body = _extract_proc_body(source, "/datum/controller/subsystem/ticker/proc/PostSetup()", "\n/datum/controller/subsystem/ticker/proc/")
	TEST_ASSERT_NOTNULL(body, "PostSetup() must exist in ticker.dm")

	// Every send2chat is a synchronous TGS bridge round-trip (world.Export to the TGS
	// host handler): a volley of role pings at the exact moment of roundstart stacks
	// those round-trips into one freeze. Role pings must go out as ONE message.
	var/send_count = _count_occurrences(body, "send2chat(")
	TEST_ASSERT(send_count <= 1, "PostSetup must send at most one send2chat message — each call is a blocking TGS bridge round-trip at roundstart (found [send_count])")
