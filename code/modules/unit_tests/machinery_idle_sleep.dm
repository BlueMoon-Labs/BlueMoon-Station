// Regression tests for the SSmachines idle-sleep pass (machine_sleep()/machine_wake()):
// sleeping machines leave the processing list but keep billing their idle draw to their area
// as a static load, and every wake path restores fully dynamic behaviour.

/// D1: machine_sleep()/machine_wake() bookkeeping on a plain console — static draw registered
/// with the area on sleep, follows NOPOWER flips while asleep, dropped on wake, restored by the
/// start_typing() interaction path, and cleaned up by Destroy().
/datum/unit_test/machine_sleep_static_power/Run()
	var/turf/floor = run_loc_floor_bottom_left
	// The reservation z lives in /area/space (powered() hard-FALSE); use a synthetic plain /area.
	var/area/original_area = get_area(floor)
	var/area/test_area = new /area
	allocated += test_area
	test_area.contents.Add(floor) // reassigns floor.loc → test_area

	var/obj/machinery/computer/console = allocate(/obj/machinery/computer)
	console.forceMove(floor)
	console.set_machine_stat(0) // clear NOPOWER — Initialize ran before the floor swap

	var/baseline = test_area.static_equip
	var/result = console.process(2)
	TEST_ASSERT_EQUAL(result, PROCESS_KILL, "an idle console's process() must return PROCESS_KILL")
	TEST_ASSERT(console.machine_sleeping, "an idle console must be machine_sleeping after process()")
	TEST_ASSERT_EQUAL(console.sleep_static_power, console.idle_power_usage, "the sleeping console's static stand-in must equal its idle draw")
	TEST_ASSERT_EQUAL(test_area.static_equip - baseline, console.idle_power_usage, "the sleeping console must bill its idle draw to the area's static EQUIP load")

	// NOPOWER while asleep: the stand-in draw must drop without waking the machine.
	console.set_machine_stat(NOPOWER)
	TEST_ASSERT(console.machine_sleeping, "losing power must not wake a sleeping console")
	TEST_ASSERT_EQUAL(test_area.static_equip - baseline, 0, "an unpowered sleeping console must bill nothing")
	console.set_machine_stat(0)
	TEST_ASSERT_EQUAL(test_area.static_equip - baseline, console.idle_power_usage, "power back: the static stand-in must re-register")

	// Wake: static draw gone, back onto the processing list.
	console.machine_wake()
	TEST_ASSERT(!console.machine_sleeping, "machine_wake() must clear machine_sleeping")
	TEST_ASSERT_EQUAL(test_area.static_equip - baseline, 0, "an awake console must not keep a static stand-in")
	TEST_ASSERT(console.datum_flags & DF_ISPROCESSING, "an awake console must be back on SSmachines")

	// start_typing() is the interaction wake path.
	console.process(2) // back to sleep
	TEST_ASSERT(console.machine_sleeping, "the console must sleep again for the wake-path check")
	var/mob/living/carbon/human/typist = allocate(/mob/living/carbon/human)
	console.start_typing(typist)
	TEST_ASSERT(!console.machine_sleeping, "start_typing() must wake the console")
	console.stop_typing(typist)

	// Destroy() of a sleeping machine must return its static stand-in to the area.
	console.process(2)
	TEST_ASSERT(console.machine_sleeping, "the console must sleep again for the destroy-path check")
	TEST_ASSERT_EQUAL(test_area.static_equip - baseline, console.idle_power_usage, "pre-destroy sanity: the stand-in is registered")
	qdel(console)
	TEST_ASSERT_EQUAL(test_area.static_equip - baseline, 0, "destroying a sleeping console must remove its static stand-in")

	original_area.contents.Add(floor) // restore the floor before test_area is qdel'd by teardown

/// D2: idle vendors leave SSmachines via machine_sleep(); electrified vendors stay awake to run
/// the countdown, and the area's static load always mirrors the registered stand-in.
/datum/unit_test/vending_idle_sleep/Run()
	var/turf/floor = run_loc_floor_bottom_left
	var/area/original_area = get_area(floor)
	var/area/test_area = new /area
	allocated += test_area
	test_area.contents.Add(floor)

	var/obj/machinery/vending/vendor = allocate(/obj/machinery/vending)
	vendor.forceMove(floor)
	vendor.set_machine_stat(0) // clear NOPOWER — the reservation area is unpowered

	var/baseline = test_area.static_equip
	var/result = vendor.process(2)
	TEST_ASSERT_EQUAL(result, PROCESS_KILL, "an idle vendor's process() must return PROCESS_KILL (machine_sleep)")
	TEST_ASSERT(vendor.machine_sleeping, "an idle vendor must be machine_sleeping")
	TEST_ASSERT_EQUAL(test_area.static_equip - baseline, vendor.sleep_static_power, "the area's static load must match the vendor's registered stand-in")

	// The wires wake path: an electrified vendor must keep processing to run its countdown.
	vendor.seconds_electrified = 30
	vendor.machine_wake()
	TEST_ASSERT(!vendor.machine_sleeping, "machine_wake() must wake the vendor")
	TEST_ASSERT_EQUAL(test_area.static_equip - baseline, 0, "an awake vendor must not keep a static stand-in")
	result = vendor.process(2)
	TEST_ASSERT_NOTEQUAL(result, PROCESS_KILL, "an electrified vendor must keep processing")
	TEST_ASSERT_EQUAL(vendor.seconds_electrified, 29, "process() must run the electrified countdown")

	vendor.seconds_electrified = 0
	result = vendor.process(2)
	TEST_ASSERT_EQUAL(result, PROCESS_KILL, "with the hazard gone the vendor must sleep again")
	TEST_ASSERT(vendor.machine_sleeping, "...and be machine_sleeping")

	original_area.contents.Add(floor)

/// D3: a settled disposal bin (pump off/charged, nothing to auto-flush) sleeps, and anything
/// dropped into it wakes it back up through Entered().
/datum/unit_test/disposal_bin_idle_sleep/Run()
	var/obj/machinery/disposal/bin/bin = allocate(/obj/machinery/disposal/bin)
	bin.forceMove(run_loc_floor_bottom_left)
	bin.set_machine_stat(0)
	// No trunk under the reservation floor: trunk_check() already forced the pump off.
	TEST_ASSERT(!bin.pressure_charging, "a trunkless bin must have its pump off (test precondition)")

	var/result = bin.process()
	TEST_ASSERT_EQUAL(result, PROCESS_KILL, "a settled bin's process() must return PROCESS_KILL (machine_sleep)")
	TEST_ASSERT(bin.machine_sleeping, "a settled bin must be machine_sleeping")

	// Something thrown in must wake it so the auto-flush countdown can resume.
	var/obj/item/paper/trash = allocate(/obj/item/paper)
	trash.forceMove(bin)
	TEST_ASSERT(!bin.machine_sleeping, "an item entering the bin must wake it")

	// Still no pressure and no pump: the next process() parks it again.
	result = bin.process()
	TEST_ASSERT_EQUAL(result, PROCESS_KILL, "an unpressurised pump-off bin must go back to sleep")
	TEST_ASSERT(bin.machine_sleeping, "...and be machine_sleeping")

/// D4: a lifeless hydroponics tray leaves SSmachines; water (a state injection that can
/// restart the weed lottery) wakes it back up.
/datum/unit_test/hydroponics_idle_sleep/Run()
	var/obj/machinery/hydroponics/constructable/tray = allocate(/obj/machinery/hydroponics/constructable)
	tray.set_machine_stat(0)
	tray.waterlevel = 0 // dry, unplanted, weedless: fully inert

	TEST_ASSERT_EQUAL(tray.process(), PROCESS_KILL, "a dry empty tray must park itself")
	TEST_ASSERT(tray.machine_sleeping, "...and be machine_sleeping")

	tray.adjustWater(50)
	TEST_ASSERT(!tray.machine_sleeping, "adjustWater() must wake the tray")

/// D5: a dark solar panel parks itself; the sun-moved signal path wakes it.
/datum/unit_test/solar_idle_sleep/Run()
	var/obj/machinery/power/solar/panel = allocate(/obj/machinery/power/solar)
	panel.set_machine_stat(0)
	panel.total_flux = 0
	panel.needs_to_turn = FALSE
	panel.needs_to_update_solar_exposure = FALSE

	TEST_ASSERT_EQUAL(panel.process(), PROCESS_KILL, "a dark panel must park itself")
	TEST_ASSERT(panel.machine_sleeping, "...and be machine_sleeping")

	panel.queue_update_solar_exposure()
	TEST_ASSERT(!panel.machine_sleeping, "the sun-moved path must wake the panel")

/// D7: APC standby - a fixed-point APC (full cell, healthy grid, static-only draw) parks its
/// load on the powernet and leaves SSmachines; area activity and grid shortfalls unpark it.
/datum/unit_test/apc_standby/Run()
	var/turf/floor = run_loc_floor_bottom_left
	var/area/original_area = get_area(floor)
	var/area/test_area = new /area
	allocated += test_area
	test_area.contents.Add(floor) // reassigns floor.loc → test_area

	var/obj/machinery/power/apc/apc = allocate(/obj/machinery/power/apc)
	TEST_ASSERT_EQUAL(apc.area, test_area, "the test APC must belong to the synthetic area (precondition)")
	TEST_ASSERT_NOTNULL(apc.terminal, "the APC must have spawned its terminal (precondition)")
	TEST_ASSERT_EQUAL(test_area.power_apc, apc, "the synthetic area must know its APC (precondition)")

	var/datum/powernet/net = new
	SSmachines.powernets -= net // keep the live SSmachines fire from resetting our test grid
	net.add_machine(apc.terminal)
	apc.cell.charge = apc.cell.maxcharge
	test_area.static_equip = 500 // pretend sleeping machines parked 500 W of static draw here

	// A comfortable grid and a full cell settle into standby within a few fires.
	for(var/i in 1 to 8) // headroom for the APC_PARK_SETTLE_FIRES debounce (parks a few fires after the fixed point holds)
		if(apc.apc_parked)
			break
		net.newavail = 1000000 // the test generator refills every cycle
		net.reset()
		apc.process()
	TEST_ASSERT(apc.apc_parked, "a full-cell APC with static-only draw on a healthy grid must park")
	TEST_ASSERT_EQUAL(net.standby_load, 500, "the parked APC must leave its static draw on the powernet")
	TEST_ASSERT(apc.machine_sleeping, "a parked APC is off SSmachines")

	// Dynamic draw in the area unparks it immediately.
	test_area.use_power(100, EQUIP)
	TEST_ASSERT(!apc.apc_parked, "dynamic area draw must unpark the APC")
	TEST_ASSERT_EQUAL(net.standby_load, 0, "unparking must pull the parked load back off the powernet")

	// Settle again, then kill the grid: the shortfall check in reset() must unpark it.
	for(var/i in 1 to 8) // headroom for the APC_PARK_SETTLE_FIRES debounce (parks a few fires after the fixed point holds)
		if(apc.apc_parked)
			break
		net.newavail = 1000000
		net.reset()
		apc.process()
	TEST_ASSERT(apc.apc_parked, "the APC must re-park once the dynamic draw is gone")
	net.newavail = 0
	net.reset() // avail 0 < standby load
	TEST_ASSERT(!apc.apc_parked, "a grid shortfall must unpark the APC in powernet reset()")

	// Destroying the powernet while parked must also unpark (no phantom loads on dead nets).
	for(var/i in 1 to 8) // headroom for the APC_PARK_SETTLE_FIRES debounce (parks a few fires after the fixed point holds)
		if(apc.apc_parked)
			break
		net.newavail = 1000000
		net.reset()
		apc.process()
	TEST_ASSERT(apc.apc_parked, "the APC must re-park for the destroy check")
	qdel(net)
	TEST_ASSERT(!apc.apc_parked, "destroying the powernet must unpark its standby APCs")

	original_area.contents.Add(floor) // restore before teardown qdels test_area

/// D6: idle holopads and empty cryopods park themselves.
/datum/unit_test/holopad_cryopod_idle_sleep/Run()
	var/obj/machinery/holopad/pad = allocate(/obj/machinery/holopad)
	pad.set_machine_stat(0)
	TEST_ASSERT_EQUAL(pad.process(), PROCESS_KILL, "an idle holopad must park itself")
	TEST_ASSERT(pad.machine_sleeping, "...and be machine_sleeping")

	var/obj/machinery/cryopod/pod = allocate(/obj/machinery/cryopod)
	pod.set_machine_stat(0)
	TEST_ASSERT_EQUAL(pod.process(), PROCESS_KILL, "an empty cryopod must park itself")
	TEST_ASSERT(pod.machine_sleeping, "...and be machine_sleeping")
