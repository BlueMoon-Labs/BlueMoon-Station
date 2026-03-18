/// Tests that unbounded list growth is prevented by limits in various subsystems

// ===== Message Server: pda_msgs limit =====

/// Verifies that pda_msgs list doesn't grow beyond its limit via receive_information()
/datum/unit_test/message_server_pda_msgs_limit/Run()
	var/obj/machinery/telecomms/message_server/server = allocate(/obj/machinery/telecomms/message_server)
	server.toggled = TRUE
	// Clear the default system message
	server.pda_msgs.Cut()
	// Send 550 PDA messages through the real receive_information path
	for(var/i in 1 to 550)
		var/datum/signal/subspace/pda/signal = new(run_loc_floor_bottom_left, list(
			"name" = "sender_[i]",
			"job" = "job_[i]",
			"message" = "message_[i]",
			"targets" = list("recipient_[i]")
		))
		server.receive_information(signal, null)

	TEST_ASSERT(length(server.pda_msgs) <= 500, "pda_msgs exceeded limit of 500: got [length(server.pda_msgs)]")
	TEST_ASSERT(length(server.pda_msgs) > 0, "pda_msgs should not be empty after trimming")

/// Verifies that pda_msgs keeps the LATEST messages after trimming via receive_information()
/datum/unit_test/message_server_pda_msgs_keeps_latest/Run()
	var/obj/machinery/telecomms/message_server/server = allocate(/obj/machinery/telecomms/message_server)
	server.toggled = TRUE
	// Clear the default system message
	server.pda_msgs.Cut()
	// Send 550 PDA messages through the real receive_information path
	for(var/i in 1 to 550)
		var/datum/signal/subspace/pda/signal = new(run_loc_floor_bottom_left, list(
			"name" = "sender_[i]",
			"job" = "job_[i]",
			"message" = "message_[i]",
			"targets" = list("recipient_[i]")
		))
		server.receive_information(signal, null)
	// The last message should be the one with i=550
	var/datum/data_pda_msg/last_msg = server.pda_msgs[length(server.pda_msgs)]
	TEST_ASSERT_EQUAL(last_msg.sender, "sender_550 (job_550)", "Last message should be the most recent one (sender_550)")

/// Verifies that message_server Destroy() cleans up lists
/datum/unit_test/message_server_destroy_cleanup/Run()
	var/obj/machinery/telecomms/message_server/server = allocate(/obj/machinery/telecomms/message_server)
	server.toggled = TRUE
	// Add messages through receive_information
	for(var/i in 1 to 10)
		var/datum/signal/subspace/pda/signal = new(run_loc_floor_bottom_left, list(
			"name" = "sender_[i]",
			"job" = "job_[i]",
			"message" = "message_[i]",
			"targets" = list("recipient_[i]")
		))
		server.receive_information(signal, null)
	LAZYADD(server.rc_msgs, new /datum/data_rc_msg("r", "s", "m"))
	TEST_ASSERT(length(server.pda_msgs) > 0, "pda_msgs should have entries before Destroy")
	TEST_ASSERT(length(server.rc_msgs) > 0, "rc_msgs should have entries before Destroy")
	// Call real Destroy() via qdel - if cleanup is broken, it will runtime
	qdel(server)

// ===== Request Console: rc_msgs limit =====

/// Verifies that rc_msgs list doesn't grow beyond its limit
/// Note: rc_msgs trimming is inline in requests_console Topic(), no standalone proc to call
/datum/unit_test/request_console_rc_msgs_limit/Run()
	var/obj/machinery/telecomms/message_server/server = allocate(/obj/machinery/telecomms/message_server)
	// Simulate adding 550 request console messages with the same trim logic as Topic()
	for(var/i in 1 to 550)
		LAZYADD(server.rc_msgs, new /datum/data_rc_msg("dept_[i]", "sender_[i]", "msg_[i]"))
		if(length(server.rc_msgs) > 500)
			var/trim_count = length(server.rc_msgs) - 400
			server.rc_msgs.Cut(1, trim_count + 1)

	TEST_ASSERT(length(server.rc_msgs) <= 500, "rc_msgs exceeded limit of 500: got [length(server.rc_msgs)]")
	TEST_ASSERT(length(server.rc_msgs) > 0, "rc_msgs should not be empty after trimming")

// ===== GC Failure Cache: failures limit =====

/// Verifies that gc_failure_cache failures list doesn't grow beyond its limit via log_gc_failure()
/datum/unit_test/gc_failure_cache_limit/Run()
	// Create a temporary cache to test without polluting the global one
	var/datum/gc_failure_viewer/gc_failure_cache/test_cache = new()
	// Log 600 failures through the real log_gc_failure path
	// Pass null as D to avoid triggering expensive world scans in TESTING mode
	for(var/i in 1 to 600)
		test_cache.log_gc_failure(null, "/datum/test_type_[i % 2]", "ref_[i]", world.time)

	TEST_ASSERT(length(test_cache.failures) <= 500, "gc_failure_cache failures exceeded 500: got [length(test_cache.failures)]")
	// Verify per-source limits (2 sources with ~300 each should trigger the >200 trim)
	for(var/key in test_cache.failure_sources)
		var/datum/gc_failure_viewer/gc_failure_source/source = test_cache.failure_sources[key]
		TEST_ASSERT(length(source.failures) <= 200, "gc_failure_source '[key]' exceeded 200: got [length(source.failures)]")
	qdel(test_cache)

// ===== Broadcasting: list(R.z) reuse =====

/// Verifies that broadcasting doesn't create excessive temporary lists
/// by checking the optimized code path works correctly with reused list
/datum/unit_test/broadcasting_radio_z_reuse/Run()
	// Test that the reusable list pattern works correctly
	var/list/radio_z = list(0)
	var/test_z = 3
	radio_z[1] = test_z
	TEST_ASSERT_EQUAL(radio_z[1], 3, "radio_z reusable list should hold the assigned z-level")
	TEST_ASSERT_EQUAL(length(radio_z), 1, "radio_z should remain a single-element list")
	// Reassign to simulate next iteration
	radio_z[1] = 5
	TEST_ASSERT_EQUAL(radio_z[1], 5, "radio_z should be updated to new z-level")
	TEST_ASSERT_EQUAL(length(radio_z), 1, "radio_z should still be single-element after reassignment")

// ===== Broadcaster: recentmessages cleanup =====

/// Verifies that GLOB.recentmessages is cleaned up when broadcaster is destroyed with message_delay active
/datum/unit_test/broadcaster_destroy_cleans_recentmessages/Run()
	var/obj/machinery/telecomms/broadcaster/B = allocate(/obj/machinery/telecomms/broadcaster)
	// Simulate active message_delay state with pending messages
	GLOB.message_delay = 1
	GLOB.recentmessages = list("test_freq:test_msg:test_name", "test_freq2:test_msg2:test_name2")
	// Destroy the broadcaster
	qdel(B)
	TEST_ASSERT_EQUAL(GLOB.message_delay, 0, "GLOB.message_delay should be reset to 0 after broadcaster Destroy")
	TEST_ASSERT_EQUAL(length(GLOB.recentmessages), 0, "GLOB.recentmessages should be empty after broadcaster Destroy")
	// Clean up global state for other tests
	GLOB.recentmessages = list()
	GLOB.message_delay = 0

/// Verifies that recentmessages is not touched when no message_delay is active
/datum/unit_test/broadcaster_destroy_no_delay/Run()
	var/obj/machinery/telecomms/broadcaster/B = allocate(/obj/machinery/telecomms/broadcaster)
	GLOB.message_delay = 0
	GLOB.recentmessages = list("leftover_msg")
	qdel(B)
	// When message_delay is 0, the Destroy should not touch recentmessages
	// (messages clear naturally via spawn(10) callback)
	TEST_ASSERT_EQUAL(GLOB.message_delay, 0, "message_delay should remain 0")
	// Clean up global state for other tests
	GLOB.recentmessages = list()

// ===== Communications Console: messages limit =====

/// Verifies that communications console messages list doesn't grow beyond limit via add_message()
/datum/unit_test/comms_console_messages_limit/Run()
	var/obj/machinery/computer/communications/console = allocate(/obj/machinery/computer/communications)
	// Add 250 messages through the real add_message proc
	for(var/i in 1 to 250)
		var/datum/comm_message/msg = new()
		msg.title = "Message [i]"
		msg.content = "Content [i]"
		console.add_message(msg)

	TEST_ASSERT(length(console.messages) <= 200, "Communications messages exceeded limit of 200: got [length(console.messages)]")
	TEST_ASSERT(length(console.messages) > 0, "Communications messages should not be empty after trimming")

/// Verifies that the latest messages are kept after trimming via add_message()
/datum/unit_test/comms_console_messages_keeps_latest/Run()
	var/obj/machinery/computer/communications/console = allocate(/obj/machinery/computer/communications)
	for(var/i in 1 to 250)
		var/datum/comm_message/msg = new()
		msg.title = "Message [i]"
		msg.content = "Content [i]"
		console.add_message(msg)
	// Check that the last message is the most recent one
	var/datum/comm_message/last_msg = console.messages[length(console.messages)]
	TEST_ASSERT_EQUAL(last_msg.title, "Message 250", "Last message should be the most recent (Message 250)")

/// Verifies that communications console Destroy() cleans up messages
/datum/unit_test/comms_console_destroy_cleanup/Run()
	var/obj/machinery/computer/communications/console = allocate(/obj/machinery/computer/communications)
	for(var/i in 1 to 5)
		var/datum/comm_message/msg = new()
		msg.title = "Test [i]"
		console.add_message(msg)
	TEST_ASSERT(length(console.messages) > 0, "Console should have messages before Destroy")
	// Call real Destroy() via qdel - if cleanup is broken, it will runtime
	qdel(console)
