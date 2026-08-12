/// A receiver that records the movables reported to it by a proximity_monitor.
/obj/effect/proximity_test_receiver
	var/list/detected

/obj/effect/proximity_test_receiver/HasProximity(atom/movable/AM)
	LAZYADD(detected, AM)

/// The signal-based proximity_monitor must report a third party that MOVES into range, and must NOT
/// spawn any physical /obj/effect/abstract/proximity_checker objects (the point of the connect_range port).
/datum/unit_test/proximity_monitor_detects_entry/Run()
	var/obj/effect/proximity_test_receiver/receiver = allocate(/obj/effect/proximity_test_receiver)
	receiver.proximity_monitor = new /datum/proximity_monitor(receiver, 1)

	// No physical checker carpet may be laid down.
	var/turf/center = get_turf(receiver)
	var/checkers = 0
	for(var/turf/near_turf as anything in RANGE_TURFS(1, center))
		for(var/obj/effect/abstract/proximity_checker/checker in near_turf)
			checkers++
	TEST_ASSERT_EQUAL(checkers, 0, "signal-based proximity_monitor must not spawn physical proximity_checker objects (found [checkers])")

	// A mover entering a turf in range must trigger HasProximity(mover) on the receiver.
	var/obj/effect/mover = allocate(/obj/effect)
	receiver.detected = null
	var/turf/in_range = get_step(center, EAST)
	TEST_ASSERT_NOTNULL(in_range, "the test reservation must have a tile east of the receiver")
	mover.forceMove(in_range)
	TEST_ASSERT(LAZYFIND(receiver.detected, mover), "a movable entering a turf in range must fire HasProximity on the receiver")

/// Destroying the host must clean the monitor up (it registers COMSIG_PARENT_QDELETING on its host).
/datum/unit_test/proximity_monitor_host_qdel_cleans_up/Run()
	var/obj/effect/proximity_test_receiver/receiver = allocate(/obj/effect/proximity_test_receiver)
	receiver.proximity_monitor = new /datum/proximity_monitor(receiver, 1)
	var/datum/proximity_monitor/monitor = receiver.proximity_monitor

	qdel(receiver)
	TEST_ASSERT(QDELETED(monitor), "destroying the host must qdel its proximity_monitor")
