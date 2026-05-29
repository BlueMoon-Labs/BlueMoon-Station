// Regression tests for the client login path: the procs invoked synchronously
// from /client/New() that hit byond.com via world.Export() must be wrapped in
// `set waitfor = FALSE` so a slow byond.com response does not freeze the entire
// game for everyone while one player's connect handshake hangs on HTTP.
//
// Source-level checks via file2text: the runtime cost of actually exercising
// these procs requires a real client + reachable byond.com (or an HTTP mock,
// which we do not have infrastructure for here), so we verify the structural
// invariant instead. If the regression sneaks back in, the assertion identifies
// exactly which proc lost its async annotation.

/// Locate proc body in `client_procs.dm` source by header. Returns the substring
/// from the header to the next /client/proc/ declaration (or end of file).
/datum/unit_test/proc/_extract_client_proc_body(source, header)
	var/start = findtext(source, header)
	if(!start)
		return null
	var/search_from = start + length(header)
	var/end = findtext(source, "\n/client/proc/", search_from)
	if(!end)
		end = length(source) + 1
	return copytext(source, start, end)

/datum/unit_test/login_validate_key_in_db_is_async/Run()
	var/source = read_source_file("code/modules/client/client_procs.dm")
	TEST_ASSERT(length(source) > 1000, "client_procs.dm must be readable from the test working directory or parent checkout (got [length(source)] chars)")

	var/body = _extract_client_proc_body(source, "/client/proc/validate_key_in_db()")
	TEST_ASSERT_NOTNULL(body, "/client/proc/validate_key_in_db() must exist in client_procs.dm")

	// validate_key_in_db() does a synchronous world.Export("http://byond.com/members/...")
	// on the slow path (when the local sql_key disagrees with the live BYOND key). Without
	// `set waitfor = FALSE` that Export blocks /client/New() for the duration of the HTTP
	// round-trip — every other player's tick pays for byond.com being slow for this one.
	TEST_ASSERT(findtext(body, "set waitfor = FALSE"), "/client/proc/validate_key_in_db must declare 'set waitfor = FALSE' — its world.Export() to byond.com must not block /client/New()")

	// findJoinDate has a return value that is used synchronously and cannot be
	// made waitfor=FALSE without rewriting set_player_age_in_db. Tracked as a
	// known caveat — there is no async assertion on it.
