// Regression tests for the event-driven /area/power_change(): the area fans its power state out
// over COMSIG_AREA_POWER_CHANGE instead of walking its own contents looking for machines.
// Each machine subscribes to the area it lives in and re-points that subscription when it moves.

/// Helper: hands back a floor turf reassigned into a freshly built plain /area.
/// The reservation z lives in /area/space (powered() is hard-FALSE there), so tests that care
/// about power need a synthetic area of their own.
/datum/unit_test/proc/claim_floor_into_area(turf/floor, area/new_area)
	new_area.contents.Add(floor) // reassigns floor.loc → new_area
	return new_area

/// Helper: is `listener` on the area's COMSIG_AREA_POWER_CHANGE list?
/// comp_lookup[sig] collapses to the bare listener when there is only one, so both shapes count.
/datum/unit_test/proc/subscribes_to_power(datum/listener, area/target_area)
	var/handlers = target_area.comp_lookup?[COMSIG_AREA_POWER_CHANGE]
	if(islist(handlers))
		return (listener in handlers)
	return handlers == listener

/// E1: a machine tracks its own area's power state through the signal, with no contents walk.
/datum/unit_test/area_power_change_signal/Run()
	var/turf/floor = run_loc_floor_bottom_left
	var/area/original_area = get_area(floor)
	var/area/test_area = new /area
	claim_floor_into_area(floor, test_area)
	test_area.power_equip = TRUE

	var/obj/machinery/computer/console = allocate(/obj/machinery/computer)
	// Appended after the console so teardown destroys the subscriber before the area it points at.
	allocated += test_area
	TEST_ASSERT_EQUAL(console.power_change_area, test_area, "a machine must subscribe to the area it initialized in")

	console.set_machine_stat(0) // clear NOPOWER — Initialize ran before the area was powered
	test_area.power_equip = FALSE
	test_area.power_change()
	TEST_ASSERT(console.machine_stat & NOPOWER, "cutting the area's EQUIP channel must flag the machine NOPOWER over the signal")

	test_area.power_equip = TRUE
	test_area.power_change()
	TEST_ASSERT(!(console.machine_stat & NOPOWER), "restoring the area's EQUIP channel must clear NOPOWER over the signal")

	original_area.contents.Add(floor) // restore the floor before test_area is qdel'd by teardown

/// E2: moving a machine between areas re-points its subscription — the old area stops reaching it
/// and the new one starts. This is what replaces the old recursive contents scan.
/datum/unit_test/area_power_change_follows_move/Run()
	var/turf/first_floor = run_loc_floor_bottom_left
	var/turf/second_floor = locate(first_floor.x + 1, first_floor.y, first_floor.z)
	TEST_ASSERT_NOTNULL(second_floor, "the test reservation must provide a second floor turf")

	var/area/original_area = get_area(first_floor)
	var/area/first_area = new /area
	var/area/second_area = new /area
	claim_floor_into_area(first_floor, first_area)
	claim_floor_into_area(second_floor, second_area)
	first_area.power_equip = TRUE
	second_area.power_equip = TRUE

	var/obj/machinery/computer/console = allocate(/obj/machinery/computer)
	// Appended after the console so teardown destroys the subscriber before the areas it points at.
	allocated += first_area
	allocated += second_area
	console.set_machine_stat(0)
	TEST_ASSERT_EQUAL(console.power_change_area, first_area, "pre-move sanity: the machine subscribes to the area it started in")

	console.forceMove(second_floor)
	TEST_ASSERT_EQUAL(console.power_change_area, second_area, "moving between areas must re-point the machine's power subscription")

	// power_change() re-derives the area itself, so machine_stat cannot tell "never notified" apart
	// from "notified by the wrong area" — the subscription lists are what actually moved.
	TEST_ASSERT(!subscribes_to_power(console, first_area), "the area a machine left must drop it as a power subscriber")
	TEST_ASSERT(subscribes_to_power(console, second_area), "the area a machine entered must pick it up as a power subscriber")

	// And the new area drives it for real.
	second_area.power_equip = FALSE
	second_area.power_change()
	TEST_ASSERT(console.machine_stat & NOPOWER, "the area a machine entered must drive its power state")

	console.forceMove(first_floor)
	original_area.contents.Add(first_floor)
	original_area.contents.Add(second_floor)

/// E3: the sub-area cascade still lands on machines. A machine in a sub-area is subscribed to that
/// sub-area, not to the parent, so the parent must keep propagating down to it.
/datum/unit_test/area_power_change_sub_area/Run()
	var/turf/floor = run_loc_floor_bottom_left
	var/area/original_area = get_area(floor)
	var/area/parent_area = new /area
	var/area/sub_area = new /area
	claim_floor_into_area(floor, sub_area)

	sub_area.base_area = parent_area
	LAZYADD(parent_area.sub_areas, sub_area)
	parent_area.power_equip = TRUE
	sub_area.power_equip = TRUE

	var/obj/machinery/computer/console = allocate(/obj/machinery/computer)
	// Appended after the console so teardown destroys the subscriber before the areas it points at.
	allocated += parent_area
	allocated += sub_area
	console.set_machine_stat(0)
	TEST_ASSERT_EQUAL(console.power_change_area, sub_area, "a machine in a sub-area must subscribe to the sub-area itself")

	parent_area.power_equip = FALSE
	parent_area.power_change()
	TEST_ASSERT(console.machine_stat & NOPOWER, "the parent area's power change must cascade into sub-area machines")

	parent_area.power_equip = TRUE
	parent_area.power_change()
	TEST_ASSERT(!(console.machine_stat & NOPOWER), "restoring the parent area's power must cascade into sub-area machines")

	sub_area.base_area = null
	parent_area.sub_areas = null
	original_area.contents.Add(floor)

/// E4: a destroyed machine leaves no subscription behind on its area — the area outlives machines
/// by design, so a stale handler would be both a hard-delete anchor and a runtime source.
/datum/unit_test/area_power_change_destroy_cleanup/Run()
	var/turf/floor = run_loc_floor_bottom_left
	var/area/original_area = get_area(floor)
	var/area/test_area = new /area
	claim_floor_into_area(floor, test_area)
	test_area.power_equip = TRUE

	var/obj/machinery/computer/console = allocate(/obj/machinery/computer)
	allocated += test_area
	TEST_ASSERT_EQUAL(console.power_change_area, test_area, "pre-destroy sanity: the machine is subscribed")

	// comp_lookup[sig] collapses to the bare listener when there is only one, so both shapes count.
	var/handlers_before = test_area.comp_lookup?[COMSIG_AREA_POWER_CHANGE]
	TEST_ASSERT_NOTNULL(handlers_before, "the area must carry a COMSIG_AREA_POWER_CHANGE handler while the machine lives")

	qdel(console)
	var/handlers_after = test_area.comp_lookup?[COMSIG_AREA_POWER_CHANGE]
	var/still_subscribed = islist(handlers_after) ? (console in handlers_after) : (handlers_after == console)
	TEST_ASSERT(!still_subscribed, "destroying a machine must drop its area power subscription")
	test_area.power_change() // must not runtime on a dead subscriber

	original_area.contents.Add(floor)
