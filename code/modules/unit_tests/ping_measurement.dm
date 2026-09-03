// Regression tests for the client ping round trip.
//
// Both timestamps in the .update_ping command leave the server as text inside a winset
// command line and come back as verb arguments. Plain string interpolation keeps six
// significant digits, and REALTIMEOFDAY needs all six for its integer part alone from
// 02:47 GMT until midnight - which silently rounded every send stamp to a whole
// decisecond and injected up to 50ms of error into every sample.

/// Every timestamp that goes out over the ping command line has to come back unchanged.
/datum/unit_test/ping_wire_preserves_timestamp/Run()
	// Each stamp is exactly representable as a 32-bit float, so a lossless wire format
	// round-trips it bit for bit and any drift below is the wire format's own doing.
	var/static/list/stamps = list(
		// REALTIMEOFDAY at 21:19 GMT. Six digits stop at the decimal point.
		767600.5,
		// world.time three hours into a round - same overflow, same total loss.
		108000.5,
		// world.time two hours in. One decimal survives, the rest does not.
		72000.0546875,
	)

	for(var/stamp in stamps)
		var/error_ms = abs(text2num(ping_wire_num(stamp)) - stamp) * 100
		TEST_ASSERT_EQUAL(error_ms, 0, "wire round-trip of [num2text(stamp, 12)] moved the timestamp by this many ms")

/// The server share of a round trip is the wall clock's lead over the game clock.
/datum/unit_test/ping_server_component_charges_stall_time/Run()
	// A stall freezes world.time but not the wall clock: 201ms of real time against a
	// game clock that only booked 50ms means 151ms went into the stall, not the wire.
	TEST_ASSERT_EQUAL(ping_server_component(201, 50), 151, "wall time above game time is server stall")

	// An idle server books the same time on both clocks and owes the round trip nothing.
	TEST_ASSERT_EQUAL(ping_server_component(3, 3), 0, "matching clocks must charge the server nothing")

	// The game clock cannot outrun the wall clock, so a negative gap is measurement
	// noise from the intra-tick estimate rather than negative server time.
	TEST_ASSERT_EQUAL(ping_server_component(3, 5), 0, "noise must not produce negative server time")
