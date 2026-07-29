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

/// E5: the shuttle path. A shuttle move hands the OLD turf back to the underlying area before the
/// contents have moved, then transfers them with a bare `loc =` assignment that fires no area
/// Entered/Exited at all. Both halves have to hold or the shuttle's machinery ends up subscribed to
/// space and nothing ever tells it the power came back — that was the round 9829/9830 blackout.
/datum/unit_test/area_power_change_shuttle_move/Run()
	var/turf/first_floor = run_loc_floor_bottom_left
	var/turf/second_floor = locate(first_floor.x + 1, first_floor.y, first_floor.z)
	TEST_ASSERT_NOTNULL(second_floor, "the test reservation must provide a second floor turf")

	var/area/original_area = get_area(first_floor)
	var/area/shuttle_area = new /area
	var/area/underlying_area = new /area
	claim_floor_into_area(first_floor, shuttle_area)
	claim_floor_into_area(second_floor, shuttle_area)
	shuttle_area.power_equip = TRUE
	// Stands in for /area/space: SHUTTLE_DEFAULT_UNDERLYING_AREA has every channel down.
	underlying_area.power_equip = FALSE

	var/obj/machinery/computer/console = allocate(/obj/machinery/computer)
	allocated += shuttle_area
	allocated += underlying_area
	console.set_machine_stat(0)
	TEST_ASSERT_EQUAL(console.power_change_area, shuttle_area, "pre-move sanity: the machine subscribes to the shuttle area")

	// /area/onShuttleMove: the departure turf goes back to the underlying area while the machine is
	// still standing on it. skip_machinery is what keeps it off the underlying area's books.
	underlying_area.contents.Add(first_floor)
	first_floor.change_area(shuttle_area, underlying_area, skip_blend = TRUE, skip_machinery = TRUE)
	TEST_ASSERT_EQUAL(console.power_change_area, shuttle_area, "handing the departure turf to the underlying area must not re-point machinery still standing on it")
	TEST_ASSERT(!(console.machine_stat & NOPOWER), "the underlying area's dead channels must not flag shuttle machinery NOPOWER")

	// /atom/movable/onShuttleMove: a bare loc assignment, which fires no Moved() and no area
	// Entered/Exited — on_enter_area() cannot run here.
	console.loc = second_floor
	console.afterShuttleMove(first_floor)
	TEST_ASSERT_EQUAL(console.power_change_area, shuttle_area, "afterShuttleMove must re-home the subscription itself, since a bare loc assignment fires no area signals")
	TEST_ASSERT(subscribes_to_power(console, shuttle_area), "the shuttle area must still list its machinery as a power subscriber after the move")

	// And the shuttle area drives it for real — this is the APC/light switch path.
	shuttle_area.power_equip = FALSE
	shuttle_area.power_change()
	TEST_ASSERT(console.machine_stat & NOPOWER, "the shuttle area must still drive its machinery after a move")
	shuttle_area.power_equip = TRUE
	shuttle_area.power_change()
	TEST_ASSERT(!(console.machine_stat & NOPOWER), "restoring the shuttle area's power must reach machinery that moved with it")

	console.loc = first_floor
	original_area.contents.Add(first_floor)
	original_area.contents.Add(second_floor)

/// E6: the non-shuttle half of the same hook. An area edit that swaps the area under a standing
/// machine (admin build mode, shuttle creation) must still re-point it — skip_machinery is opt-in.
/datum/unit_test/area_power_change_turf_area_swap/Run()
	var/turf/floor = run_loc_floor_bottom_left
	var/area/original_area = get_area(floor)
	var/area/first_area = new /area
	var/area/second_area = new /area
	claim_floor_into_area(floor, first_area)
	first_area.power_equip = TRUE
	second_area.power_equip = TRUE

	var/obj/machinery/computer/console = allocate(/obj/machinery/computer)
	allocated += first_area
	allocated += second_area
	console.set_machine_stat(0)
	TEST_ASSERT_EQUAL(console.power_change_area, first_area, "pre-swap sanity: the machine subscribes to the area it initialized in")

	second_area.contents.Add(floor)
	floor.change_area(first_area, second_area)
	TEST_ASSERT_EQUAL(console.power_change_area, second_area, "swapping the area under a standing machine must re-point its power subscription")
	TEST_ASSERT(!subscribes_to_power(console, first_area), "the area that lost the turf must drop the machine as a subscriber")

	original_area.contents.Add(floor)

/// E7: a light bills its static power to the area it was in, not to whichever area it is in when the
/// light goes out. Getting this wrong leaves the area paying for a dark lamp forever, and an APC
/// draws that phantom load straight out of its cell — the "shuttles are discharging" report.
/datum/unit_test/light_static_power_follows_area/Run()
	var/turf/first_floor = run_loc_floor_bottom_left
	var/turf/second_floor = locate(first_floor.x + 1, first_floor.y, first_floor.z)
	TEST_ASSERT_NOTNULL(second_floor, "the test reservation must provide a second floor turf")

	var/area/original_area = get_area(first_floor)
	var/area/first_area = new /area
	var/area/second_area = new /area
	claim_floor_into_area(first_floor, first_area)
	claim_floor_into_area(second_floor, second_area)

	var/obj/machinery/light/lamp = allocate(/obj/machinery/light)
	allocated += first_area
	allocated += second_area

	lamp.bill_static_power(0) // start from a known baseline whatever Initialize did
	var/first_baseline = first_area.static_light
	var/second_baseline = second_area.static_light

	lamp.bill_static_power(160)
	TEST_ASSERT_EQUAL(first_area.static_light, first_baseline + 160, "a lit lamp must bill its static load to the area it stands in")

	// Bare loc assignment, exactly like the shuttle content transfer.
	lamp.loc = second_floor
	lamp.bill_static_power(0)
	TEST_ASSERT_EQUAL(first_area.static_light, first_baseline, "going dark must return the load to the area that was billed, not to the current one")
	TEST_ASSERT_EQUAL(second_area.static_light, second_baseline, "the area a lamp moved into must not be credited a load it never carried")

	lamp.loc = first_floor
	original_area.contents.Add(first_floor)
	original_area.contents.Add(second_floor)

/// E8: destroying a lit lamp releases its static load. Destroy() sets on = FALSE straight past
/// update(), so without an explicit release the area kept paying for a lamp that no longer exists.
/datum/unit_test/light_static_power_destroy_release/Run()
	var/turf/floor = run_loc_floor_bottom_left
	var/area/original_area = get_area(floor)
	var/area/test_area = new /area
	claim_floor_into_area(floor, test_area)

	var/obj/machinery/light/lamp = allocate(/obj/machinery/light)
	allocated += test_area

	lamp.bill_static_power(0)
	var/baseline = test_area.static_light
	lamp.bill_static_power(160)
	TEST_ASSERT_EQUAL(test_area.static_light, baseline + 160, "pre-destroy sanity: the lamp's load is on the area")

	qdel(lamp)
	TEST_ASSERT_EQUAL(test_area.static_light, baseline, "destroying a lit lamp must release its static load from the area")

	original_area.contents.Add(floor)
