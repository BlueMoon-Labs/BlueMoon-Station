/// Tests for /obj/structure/disposalholder GC and lifecycle behavior

/// Test that disposalholder properly cleans up move_packet on Destroy,
/// allowing soft GC instead of expensive hard delete
/datum/unit_test/disposal_holder_move_packet_cleanup

/datum/unit_test/disposal_holder_move_packet_cleanup/Run()
	var/turf/T = run_loc_floor_bottom_left

	// Create a pipe for the holder to sit in
	var/obj/structure/disposalpipe/segment/pipe = new(T)
	pipe.dpdir = NORTH | SOUTH

	// Create holder and place it in the pipe
	var/obj/structure/disposalholder/holder = new(pipe)
	holder.active = TRUE
	holder.setDir(NORTH)
	holder.current_pipe = pipe

	// Start movement - this creates move_packet and move_loop
	holder.start_moving()

	TEST_ASSERT_NOTNULL(holder.move_packet, "Holder should have a move_packet after start_moving()")

	var/datum/movement_packet/packet = holder.move_packet

	// qdel the holder - Destroy() should clean up move_packet
	qdel(holder)

	TEST_ASSERT(QDELETED(holder), "Holder should be marked for deletion after qdel")
	TEST_ASSERT(QDELETED(packet), "move_packet should be deleted when holder is destroyed")

	qdel(pipe)

/// Test that disposalholder can be safely destroyed without ever starting movement
/datum/unit_test/disposal_holder_destroy_no_movement

/datum/unit_test/disposal_holder_destroy_no_movement/Run()
	var/obj/structure/disposalholder/holder = allocate(/obj/structure/disposalholder)

	TEST_ASSERT_EQUAL(holder.active, FALSE, "Holder should not be active initially")
	TEST_ASSERT_NULL(holder.move_packet, "Holder should have no move_packet without movement")

	// Should not crash or error
	qdel(holder)

	TEST_ASSERT(QDELETED(holder), "Holder should be marked for deletion")

/// Test that gas mixture is properly cleaned up on Destroy
/datum/unit_test/disposal_holder_gas_cleanup

/datum/unit_test/disposal_holder_gas_cleanup/Run()
	var/obj/structure/disposalholder/holder = allocate(/obj/structure/disposalholder)

	// Give it a gas mixture
	holder.gas = new /datum/gas_mixture()

	var/datum/gas_mixture/gas_ref = holder.gas

	qdel(holder)

	TEST_ASSERT(QDELETED(holder), "Holder should be marked for deletion")
	TEST_ASSERT(QDELETED(gas_ref), "Gas mixture should be deleted with holder")

/// Test that pipe references are nulled on Destroy
/datum/unit_test/disposal_holder_pipe_refs_cleanup

/datum/unit_test/disposal_holder_pipe_refs_cleanup/Run()
	var/turf/T = run_loc_floor_bottom_left

	var/obj/structure/disposalpipe/segment/pipe1 = new(T)
	pipe1.dpdir = NORTH | SOUTH

	var/obj/structure/disposalholder/holder = new(pipe1)
	holder.last_pipe = pipe1
	holder.current_pipe = pipe1

	qdel(holder)

	TEST_ASSERT(QDELETED(holder), "Holder should be marked for deletion")
	// Pipes should still exist - holder shouldn't delete them
	TEST_ASSERT(!QDELETED(pipe1), "Pipe should NOT be deleted when holder is destroyed")

	qdel(pipe1)

/// Test that the Moved() failsafe correctly dumps contents and self-destructs
/// when holder ends up outside disposal pipes
/datum/unit_test/disposal_holder_failsafe_expel

/datum/unit_test/disposal_holder_failsafe_expel/Run()
	var/turf/T = run_loc_floor_bottom_left

	var/obj/structure/disposalpipe/segment/pipe = new(T)
	pipe.dpdir = NORTH | SOUTH

	var/obj/structure/disposalholder/holder = new(pipe)
	holder.active = TRUE

	// Put an item inside the holder
	var/obj/item/crowbar/item = new(holder)

	// Move holder to a non-pipe turf - should trigger failsafe
	holder.forceMove(T)

	// Holder should have self-destructed
	TEST_ASSERT(QDELETED(holder), "Holder should self-destruct when moved outside pipes")
	// Item should have been dumped to the turf, not deleted
	TEST_ASSERT(!QDELETED(item), "Item should be dumped, not deleted")
	TEST_ASSERT_EQUAL(item.loc, T, "Item should be on the turf after failsafe expel")

	qdel(item)
	qdel(pipe)

/// Test that merging two holders properly destroys the merged holder
/datum/unit_test/disposal_holder_merge

/datum/unit_test/disposal_holder_merge/Run()
	var/turf/T = run_loc_floor_bottom_left

	var/obj/structure/disposalpipe/segment/pipe = new(T)
	pipe.dpdir = NORTH | SOUTH

	var/obj/structure/disposalholder/holder1 = new(pipe)
	var/obj/structure/disposalholder/holder2 = new(pipe)

	// Put items in the second holder
	var/obj/item/crowbar/item = new(holder2)

	// Merge holder2 into holder1
	holder1.merge(holder2)

	TEST_ASSERT(QDELETED(holder2), "Merged holder should be deleted")
	TEST_ASSERT(!QDELETED(item), "Item from merged holder should survive")
	TEST_ASSERT_EQUAL(item.loc, holder1, "Item should be in the surviving holder")

	qdel(item)
	qdel(holder1)
	qdel(pipe)

/// Test that holder with active move_packet properly cleans up on merge (qdel of merged holder)
/datum/unit_test/disposal_holder_merge_with_movement

/datum/unit_test/disposal_holder_merge_with_movement/Run()
	var/turf/T = run_loc_floor_bottom_left

	var/obj/structure/disposalpipe/segment/pipe = new(T)
	pipe.dpdir = NORTH | SOUTH

	var/obj/structure/disposalholder/holder1 = new(pipe)
	var/obj/structure/disposalholder/holder2 = new(pipe)

	// Start movement on holder2 to create move_packet
	holder2.active = TRUE
	holder2.setDir(NORTH)
	holder2.current_pipe = pipe
	holder2.start_moving()

	var/datum/movement_packet/packet = holder2.move_packet
	TEST_ASSERT_NOTNULL(packet, "holder2 should have move_packet")

	// Merge holder2 into holder1 - holder2 gets qdel'd
	holder1.merge(holder2)

	TEST_ASSERT(QDELETED(holder2), "Merged holder should be deleted")
	TEST_ASSERT(QDELETED(packet), "move_packet of merged holder should be cleaned up")

	qdel(holder1)
	qdel(pipe)
