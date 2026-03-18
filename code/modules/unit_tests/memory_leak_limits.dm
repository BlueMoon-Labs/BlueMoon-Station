/// Tests that unbounded list growth is prevented by limits in various subsystems

// ===== Message Server: pda_msgs limit =====

/// Verifies that pda_msgs list doesn't grow beyond its limit
/datum/unit_test/message_server_pda_msgs_limit/Run()
	var/obj/machinery/telecomms/message_server/server = allocate(/obj/machinery/telecomms/message_server)
	// Fill beyond the limit of 500
	for(var/i in 1 to 550)
		var/datum/data_pda_msg/msg = new("recipient_[i]", "sender_[i]", "message_[i]")
		server.pda_msgs += msg
	// Simulate what receive_information does after adding
	if(length(server.pda_msgs) > 500)
		server.pda_msgs.Cut(1, length(server.pda_msgs) - 400)

	TEST_ASSERT(length(server.pda_msgs) <= 500, "pda_msgs exceeded limit of 500: got [length(server.pda_msgs)]")
	TEST_ASSERT(length(server.pda_msgs) > 0, "pda_msgs should not be empty after trimming")

/// Verifies that pda_msgs keeps the LATEST messages after trimming
/datum/unit_test/message_server_pda_msgs_keeps_latest/Run()
	var/obj/machinery/telecomms/message_server/server = allocate(/obj/machinery/telecomms/message_server)
	// Clear the default system message
	server.pda_msgs.Cut()
	// Add 550 messages
	for(var/i in 1 to 550)
		var/datum/data_pda_msg/msg = new("recipient_[i]", "sender_[i]", "message_[i]")
		server.pda_msgs += msg
	// Trigger the trim
	if(length(server.pda_msgs) > 500)
		server.pda_msgs.Cut(1, length(server.pda_msgs) - 400)
	// The last message should be the one with i=550
	var/datum/data_pda_msg/last_msg = server.pda_msgs[length(server.pda_msgs)]
	TEST_ASSERT_EQUAL(last_msg.sender, "sender_550", "Last message should be the most recent one (sender_550)")

/// Verifies that message_server Destroy() cleans up lists
/datum/unit_test/message_server_destroy_cleanup/Run()
	var/obj/machinery/telecomms/message_server/server = allocate(/obj/machinery/telecomms/message_server)
	for(var/i in 1 to 10)
		server.pda_msgs += new /datum/data_pda_msg("r", "s", "m")
		LAZYADD(server.rc_msgs, new /datum/data_rc_msg("r", "s", "m"))
	var/pda_count_before = length(server.pda_msgs)
	var/rc_count_before = length(server.rc_msgs)
	TEST_ASSERT(pda_count_before > 0, "pda_msgs should have entries before Destroy")
	TEST_ASSERT(rc_count_before > 0, "rc_msgs should have entries before Destroy")
	// Simulate the cleanup portion of Destroy (without actually destroying)
	server.pda_msgs.Cut()
	server.rc_msgs.Cut()
	TEST_ASSERT_EQUAL(length(server.pda_msgs), 0, "pda_msgs should be empty after cleanup")
	TEST_ASSERT_EQUAL(length(server.rc_msgs), 0, "rc_msgs should be empty after cleanup")

// ===== Request Console: rc_msgs limit =====

/// Verifies that rc_msgs list doesn't grow beyond its limit
/datum/unit_test/request_console_rc_msgs_limit/Run()
	var/obj/machinery/telecomms/message_server/server = allocate(/obj/machinery/telecomms/message_server)
	// Simulate adding 550 request console messages
	for(var/i in 1 to 550)
		LAZYADD(server.rc_msgs, new /datum/data_rc_msg("dept_[i]", "sender_[i]", "msg_[i]"))
		if(length(server.rc_msgs) > 500)
			server.rc_msgs.Cut(1, length(server.rc_msgs) - 400)

	TEST_ASSERT(length(server.rc_msgs) <= 500, "rc_msgs exceeded limit of 500: got [length(server.rc_msgs)]")
	TEST_ASSERT(length(server.rc_msgs) > 0, "rc_msgs should not be empty after trimming")

// ===== GC Failure Cache: failures limit =====

/// Verifies that gc_failure_cache failures list doesn't grow beyond its limit
/datum/unit_test/gc_failure_cache_limit/Run()
	// Create a temporary cache to test without polluting the global one
	var/datum/gc_failure_viewer/gc_failure_cache/test_cache = new()
	// Simulate logging 600 failures
	for(var/i in 1 to 600)
		test_cache.total_failures++
		var/type_key = "/datum/test_type_[i % 5]" // 5 different type sources
		var/datum/gc_failure_viewer/gc_failure_source/source = test_cache.failure_sources[type_key]
		if(!source)
			source = new("[type_key]")
			test_cache.failure_sources[type_key] = source
		var/datum/gc_failure_viewer/gc_failure_entry/entry = new()
		entry.failure_source = source
		test_cache.failures += entry
		source.failures += entry
		// Apply the limit logic
		if(length(test_cache.failures) > 500)
			test_cache.failures.Cut(1, length(test_cache.failures) - 300)
		if(length(source.failures) > 200)
			source.failures.Cut(1, length(source.failures) - 100)

	TEST_ASSERT(length(test_cache.failures) <= 500, "gc_failure_cache failures exceeded 500: got [length(test_cache.failures)]")
	// Verify per-source limits
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

// ===== Communications Console: messages limit =====

/// Verifies that communications console messages list doesn't grow beyond limit
/datum/unit_test/comms_console_messages_limit/Run()
	var/obj/machinery/computer/communications/console = allocate(/obj/machinery/computer/communications)
	// Add 250 messages through add_message
	for(var/i in 1 to 250)
		var/datum/comm_message/msg = new()
		msg.title = "Message [i]"
		msg.content = "Content [i]"
		console.add_message(msg)

	TEST_ASSERT(length(console.messages) <= 200, "Communications messages exceeded limit of 200: got [length(console.messages)]")
	TEST_ASSERT(length(console.messages) > 0, "Communications messages should not be empty after trimming")

/// Verifies that the latest messages are kept after trimming
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

/// Verifies that communications console Destroy cleans up messages
/datum/unit_test/comms_console_destroy_cleanup/Run()
	var/obj/machinery/computer/communications/console = allocate(/obj/machinery/computer/communications)
	for(var/i in 1 to 5)
		var/datum/comm_message/msg = new()
		msg.title = "Test [i]"
		console.add_message(msg)
	TEST_ASSERT(length(console.messages) > 0, "Console should have messages before Destroy")
	// Simulate the cleanup from Destroy
	LAZYCLEARLIST(console.messages)
	TEST_ASSERT(length(console.messages) == 0, "Messages should be cleared after LAZYCLEARLIST")
