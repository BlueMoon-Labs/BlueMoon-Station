// Regression tests guarding the machinery optimization pass.
// These pin observable behaviour — they pass before AND after the optimizations.

/// A1: auto_use_power() must charge the machine's area exactly the same amount as before
/// the rewrite (idle / active / unpowered), and return the area's powered state.
/datum/unit_test/machinery_auto_use_power/Run()
	var/turf/floor = run_loc_floor_bottom_left
	// The reservation z-level turfs live in /area/space, which unconditionally
	// overrides powered() to return FALSE. Create a synthetic plain /area (base type,
	// not the space subtype), move the turf into it for the duration of the test,
	// and restore at the end.
	var/area/original_area = get_area(floor)
	var/area/test_area = new /area
	allocated += test_area
	test_area.contents.Add(floor) // reassigns floor.loc → test_area

	// The base /area has requires_power = TRUE and power_equip = TRUE by default.
	TEST_ASSERT(test_area.powered(EQUIP), "synthetic area must be powered on EQUIP by default")

	var/obj/machinery/machine = allocate(/obj/machinery)
	machine.forceMove(floor)
	machine.power_channel = EQUIP
	machine.idle_power_usage = 100
	machine.active_power_usage = 500

	// --- idle power ---
	machine.use_power = IDLE_POWER_USE
	test_area.clear_usage()
	var/before = test_area.used_equip
	var/result = machine.auto_use_power()
	TEST_ASSERT(result, "auto_use_power() should return TRUE in a powered area")
	TEST_ASSERT_EQUAL(test_area.used_equip - before, 100, "idle machine must add idle_power_usage to area EQUIP usage")

	// --- active power ---
	machine.use_power = ACTIVE_POWER_USE
	before = test_area.used_equip
	machine.auto_use_power()
	TEST_ASSERT_EQUAL(test_area.used_equip - before, 500, "active machine must add active_power_usage to area EQUIP usage")

	// --- unpowered channel ---
	test_area.power_equip = FALSE
	before = test_area.used_equip
	result = machine.auto_use_power()
	TEST_ASSERT(!result, "auto_use_power() should return FALSE when the area's EQUIP channel is unpowered")
	TEST_ASSERT_EQUAL(test_area.used_equip - before, 0, "unpowered machine must not consume power")

	// Restore floor to its original area before test_area is qdel'd by teardown.
	original_area.contents.Add(floor)

/// A2: the is_operational *var* must stay identical to the is_operational() proc result on
/// any machine that does not override the proc, across machine_stat transitions — this is
/// what makes swapping the proc calls for var reads a no-op.
/datum/unit_test/machinery_is_operational_invariant/Run()
	var/obj/machinery/machine = allocate(/obj/machinery)
	machine.forceMove(run_loc_floor_bottom_left)

	machine.set_machine_stat(0)
	TEST_ASSERT_EQUAL(machine.is_operational, machine.is_operational(), "var/proc must agree with no stat flags")
	TEST_ASSERT(machine.is_operational, "machine with no stat flags should be operational")

	machine.set_machine_stat(NOPOWER)
	TEST_ASSERT_EQUAL(machine.is_operational, machine.is_operational(), "var/proc must agree with NOPOWER")
	TEST_ASSERT(!machine.is_operational, "NOPOWER machine should not be operational")

	machine.set_machine_stat(BROKEN)
	TEST_ASSERT_EQUAL(machine.is_operational, machine.is_operational(), "var/proc must agree with BROKEN")

	machine.set_machine_stat(MAINT)
	TEST_ASSERT_EQUAL(machine.is_operational, machine.is_operational(), "var/proc must agree with MAINT")

	machine.set_machine_stat(NOPOWER | BROKEN | MAINT)
	TEST_ASSERT_EQUAL(machine.is_operational, machine.is_operational(), "var/proc must agree with all flags")

	machine.set_machine_stat(0)
	machine.obj_break()
	TEST_ASSERT_EQUAL(machine.is_operational, machine.is_operational(), "var/proc must agree after obj_break")
	TEST_ASSERT(!machine.is_operational, "obj_break should make the machine not operational")

	machine.set_machine_stat(0)
	TEST_ASSERT_EQUAL(machine.is_operational, machine.is_operational(), "var/proc must agree after clearing flags")
	TEST_ASSERT(machine.is_operational, "machine should be operational again after clearing flags")

/// A2: the three machines that DO override is_operational() must keep returning their custom
/// value (we deliberately do NOT swap their call sites).
/datum/unit_test/machinery_is_operational_overrides/Run()
	var/obj/machinery/bloodbankgen/bbg = allocate(/obj/machinery/bloodbankgen)
	bbg.setAnchored(FALSE)
	TEST_ASSERT(!bbg.is_operational(), "unanchored bloodbankgen reports not operational")

	var/obj/machinery/ntnet_relay/relay = allocate(/obj/machinery/ntnet_relay)
	relay.set_machine_stat(0)
	relay.enabled = FALSE
	TEST_ASSERT(!relay.is_operational(), "ntnet_relay with !enabled reports not operational even with no stat flags")

	var/obj/machinery/computer/camera_advanced/shuttle_creator/shuttle_creator = allocate(/obj/machinery/computer/camera_advanced/shuttle_creator)
	shuttle_creator.set_machine_stat(BROKEN | NOPOWER | MAINT)
	TEST_ASSERT(shuttle_creator.is_operational(), "shuttle_creator reports operational even with stat flags")

/// Counts how many times the miner rebuilds its overlays.
/obj/machinery/mineral/bluespace_miner/unit_test_icon_counter
	var/icon_rebuilds = 0

/obj/machinery/mineral/bluespace_miner/unit_test_icon_counter/update_overlays()
	icon_rebuilds++
	return ..()

/// A3: with no change to any of the inputs that drive the miner's appearance, repeatedly
/// asking it to refresh must NOT rebuild the overlays; changing a tracked input must.
/datum/unit_test/bluespace_miner_icon_throttle/Run()
	var/obj/machinery/mineral/bluespace_miner/unit_test_icon_counter/miner = allocate(/obj/machinery/mineral/bluespace_miner/unit_test_icon_counter)
	miner.forceMove(run_loc_floor_bottom_left)

	miner.icon_rebuilds = 0
	for(var/i in 1 to 10)
		miner.update_miner_icon_if_changed()
	TEST_ASSERT(miner.icon_rebuilds <= 1, "miner rebuilt its icon [miner.icon_rebuilds] times across 10 unchanged refreshes (expected ≤1)")

	var/rebuilds_after_steady = miner.icon_rebuilds
	miner.panel_open = TRUE
	miner.update_miner_icon_if_changed()
	TEST_ASSERT_EQUAL(miner.icon_rebuilds, rebuilds_after_steady + 1, "opening the panel must trigger exactly one rebuild")

	miner.update_miner_icon_if_changed()
	TEST_ASSERT_EQUAL(miner.icon_rebuilds, rebuilds_after_steady + 1, "a second refresh with the panel still open must not rebuild again")

/// B2: an idle conveyor must drop out of SSfastprocess (process() returns PROCESS_KILL),
/// and a belt that turns back on must re-register itself (exercised here via the auto
/// variant's update() — the same one-line START_PROCESSING is in conveyor_switch/do_process()).
/datum/unit_test/conveyor_idle_processing/Run()
	var/obj/machinery/conveyor/belt = allocate(/obj/machinery/conveyor)
	belt.forceMove(run_loc_floor_bottom_left)
	belt.operating = 0

	// An idle conveyor must ask the fast-process subsystem to drop it.
	TEST_ASSERT_EQUAL(belt.process(2), PROCESS_KILL, "an idle conveyor's process() must return PROCESS_KILL")
	STOP_PROCESSING(SSfastprocess, belt) // mimic what the subsystem does with that return value
	TEST_ASSERT(!(belt in SSfastprocess.processing), "the idle belt should now be out of SSfastprocess")

	// An auto conveyor that was evicted must re-register itself when update() turns it back on
	// (this is the power-restore path: power_change() -> update()).
	var/obj/machinery/conveyor/auto/auto_belt = allocate(/obj/machinery/conveyor/auto)
	auto_belt.forceMove(run_loc_floor_bottom_left)
	auto_belt.set_machine_stat(0) // clear NOPOWER — the test reservation area is unpowered
	STOP_PROCESSING(SSfastprocess, auto_belt)
	TEST_ASSERT(!(auto_belt in SSfastprocess.processing), "the auto belt should start out of SSfastprocess for this check")
	auto_belt.update()
	TEST_ASSERT_EQUAL(auto_belt.operating, 1, "a powered auto conveyor must turn operating on in update()")
	TEST_ASSERT(auto_belt.datum_flags & DF_ISPROCESSING, "an operating auto conveyor must be flagged DF_ISPROCESSING")
	TEST_ASSERT(auto_belt in SSfastprocess.processing, "an operating auto conveyor must (re-)register itself in SSfastprocess via update()")
	// Stop it so teardown doesn't queue a convey() timer on a soon-to-be-qdel'd belt.
	STOP_PROCESSING(SSfastprocess, auto_belt)
	auto_belt.operating = 0

/// Counts how many times the warden re-scans for targets.
/obj/structure/destructible/clockwork/ocular_warden/unit_test_scan_counter
	var/scan_count = 0

/obj/structure/destructible/clockwork/ocular_warden/unit_test_scan_counter/acquire_nearby_targets()
	scan_count++
	return ..()

/// B1: the warden must re-scan for targets at most once per scan interval, not every tick.
/datum/unit_test/ocular_warden_scan_throttle/Run()
	var/obj/structure/destructible/clockwork/ocular_warden/unit_test_scan_counter/warden = allocate(/obj/structure/destructible/clockwork/ocular_warden/unit_test_scan_counter)
	warden.forceMove(run_loc_floor_bottom_left)
	warden.setAnchored(TRUE)

	warden.scan_count = 0
	warden.process()
	TEST_ASSERT_EQUAL(warden.scan_count, 1, "the first process() (cooldown unset) must scan once")
	for(var/i in 1 to 5)
		warden.process()
	TEST_ASSERT_EQUAL(warden.scan_count, 1, "process() calls inside the scan interval must NOT re-scan")

	warden.scan_count = 0
	warden.target_scan_cooldown = world.time - 1 // force the cooldown to be finished
	warden.process()
	TEST_ASSERT_EQUAL(warden.scan_count, 1, "process() after the cooldown lapses must scan again")

// ---------------------------------------------------------------------------
// Tier 1 follow-up: air alarm backoff, turret scan throttle, status display gate
// ---------------------------------------------------------------------------

/// C1: a stable air alarm reads the turf air less often over time (interval ramps to the cap
/// and saturates), a queued skip short-circuits before the air read, and danger_level changing
/// snaps it back to reading every fire.
/datum/unit_test/airalarm_process_backoff/Run()
	var/obj/machinery/airalarm/alarm = allocate(/obj/machinery/airalarm)
	alarm.forceMove(run_loc_floor_bottom_left)
	alarm.set_machine_stat(0) // clear NOPOWER — the test reservation is unpowered

	TEST_ASSERT_EQUAL(alarm.process_interval, 1, "a fresh air alarm processes every fire")
	TEST_ASSERT_EQUAL(alarm.process_skips_left, 0, "...with nothing queued to skip")

	// The backoff cap depends on whether the local turf takes part in active atmos exchange:
	// an excited turf caps at AALARM_MAX_PROCESS_INTERVAL, a parked one coasts much longer at
	// AALARM_INACTIVE_PROCESS_INTERVAL. Excite the test turf for the first steady-state block.
	var/turf/open/alarm_turf = get_turf(alarm)
	TEST_ASSERT(istype(alarm_turf), "the test reservation floor must be an open turf")
	var/was_excited = alarm_turf.excited
	alarm_turf.excited = TRUE

	// Steady state on an active turf: an excited turf cuts queued skips short, so EVERY fire is
	// a real air read, and the per-fire interval ramps up to the cap and stays there.
	for(var/i in 1 to 2 * AALARM_MAX_PROCESS_INTERVAL + 4)
		var/interval_before = alarm.process_interval
		alarm.process()
		TEST_ASSERT(alarm.process_interval >= interval_before, "process_interval must not shrink while danger_level is stable (was [interval_before], now [alarm.process_interval])")
		TEST_ASSERT(alarm.process_interval <= AALARM_MAX_PROCESS_INTERVAL, "process_interval ([alarm.process_interval]) must never exceed AALARM_MAX_PROCESS_INTERVAL ([AALARM_MAX_PROCESS_INTERVAL]) on an active turf")
		TEST_ASSERT_EQUAL(alarm.process_skips_left, alarm.process_interval - 1, "after a real read the alarm queues (interval - 1) skipped fires")
	TEST_ASSERT_EQUAL(alarm.process_interval, AALARM_MAX_PROCESS_INTERVAL, "process_interval must saturate at the cap in steady state")

	// The turf leaves active exchange: queued skips now burn down one per fire, and the cap
	// opens up to the inactive interval. The burn loops are bounded by the queued count so a
	// contract change fails the test instead of hanging it.
	alarm_turf.excited = FALSE
	for(var/i in 1 to 2 * AALARM_INACTIVE_PROCESS_INTERVAL + 4)
		var/queued_skips = alarm.process_skips_left
		for(var/burn in 1 to queued_skips)
			alarm.process()
		TEST_ASSERT_EQUAL(alarm.process_skips_left, 0, "on a parked turf each skipped fire must decrement the queue by exactly one")
		alarm.process()
		TEST_ASSERT(alarm.process_interval <= AALARM_INACTIVE_PROCESS_INTERVAL, "process_interval ([alarm.process_interval]) must never exceed AALARM_INACTIVE_PROCESS_INTERVAL ([AALARM_INACTIVE_PROCESS_INTERVAL]) on an inactive turf")
	TEST_ASSERT_EQUAL(alarm.process_interval, AALARM_INACTIVE_PROCESS_INTERVAL, "process_interval must saturate at the inactive cap on a parked turf")

	// The turf re-enters active exchange: the very next fire must cut through the queued skips,
	// read now, and clamp the interval back to the active cap.
	alarm_turf.excited = TRUE
	TEST_ASSERT(alarm.process_skips_left > 0, "precondition: skips must be queued before the re-excite check")
	alarm.process()
	TEST_ASSERT(alarm.process_interval <= AALARM_MAX_PROCESS_INTERVAL, "a re-excited turf must clamp the interval back to AALARM_MAX_PROCESS_INTERVAL (got [alarm.process_interval])")
	TEST_ASSERT_EQUAL(alarm.process_skips_left, alarm.process_interval - 1, "the re-excited fire performs a real read and re-queues from the clamped interval")

	// A queued skip must not touch the air: a real read can never produce this danger_level.
	// Park the turf again - an excited turf never skips.
	alarm_turf.excited = FALSE
	alarm.process_skips_left = AALARM_MAX_PROCESS_INTERVAL
	var/sentinel = 1234
	alarm.danger_level = sentinel
	var/queued = alarm.process_skips_left
	alarm.process()
	TEST_ASSERT_EQUAL(alarm.danger_level, sentinel, "an air alarm with skips queued must not read the air")
	TEST_ASSERT_EQUAL(alarm.process_skips_left, queued - 1, "a skipped fire decrements the skip counter")
	for(var/burn in 1 to alarm.process_skips_left)
		alarm.process()
	TEST_ASSERT_EQUAL(alarm.process_skips_left, 0, "burning the queued skips must leave none behind")
	TEST_ASSERT_EQUAL(alarm.danger_level, sentinel, "danger_level stays untouched while skips remain")
	alarm.process()
	TEST_ASSERT_NOTEQUAL(alarm.danger_level, sentinel, "with no skips queued the alarm reads the air and recomputes danger_level")
	alarm_turf.excited = was_excited

	// danger_level changing snaps the alarm back to processing every fire. Rig a TLV so the
	// next read produces a different level than the current one (no_checks → 0; an impossibly
	// high lower pressure bound → danger 2 for any real pressure), then read.
	alarm.process_interval = AALARM_MAX_PROCESS_INTERVAL
	alarm.process_skips_left = 0
	var/level_before = alarm.danger_level
	if(level_before == 2)
		for(var/tlv_key in alarm.TLV)
			alarm.TLV[tlv_key] = new /datum/tlv/no_checks
	else
		alarm.TLV["pressure"] = new /datum/tlv(INFINITY, INFINITY, -1, -1)
	alarm.process()
	TEST_ASSERT_NOTEQUAL(alarm.danger_level, level_before, "the rigged TLV must change danger_level on the next read (was [level_before])")
	TEST_ASSERT_EQUAL(alarm.process_interval, 1, "danger_level changing resets the alarm to every-fire processing")
	TEST_ASSERT_EQUAL(alarm.process_skips_left, 0, "...with no skips queued")

/// Counts how many times a turret re-scans its surroundings for targets.
/obj/machinery/porta_turret/unit_test_scan_counter
	var/scan_count = 0

/obj/machinery/porta_turret/unit_test_scan_counter/scan_for_targets()
	scan_count++
	return ..()

/// C2: a powered-on turret re-scans (view()/mechs/blobs) at most once per scan interval, not
/// every fire — between scans process() reuses the cached target list.
/datum/unit_test/turret_scan_throttle/Run()
	var/obj/machinery/porta_turret/unit_test_scan_counter/turret = allocate(/obj/machinery/porta_turret/unit_test_scan_counter)
	turret.forceMove(run_loc_floor_bottom_left)
	turret.set_machine_stat(0) // clear NOPOWER — the test reservation is unpowered
	turret.on = TRUE

	// process() skips scanning entirely on z-levels without clients, so simulate one
	// (same trick as the ssmobs_optimization tests).
	var/turf/turret_turf = get_turf(turret)
	if(!islist(SSmobs.clients_by_zlevel) || turret_turf.z > SSmobs.clients_by_zlevel.len)
		SSmobs.MaxZChanged()
	var/mob/living/carbon/human/fake_player = allocate(/mob/living/carbon/human)
	SSmobs.clients_by_zlevel[turret_turf.z] += fake_player

	turret.scan_count = 0
	turret.process()
	TEST_ASSERT_EQUAL(turret.scan_count, 1, "the first process() (cooldown unset) must scan once")
	for(var/i in 1 to 5)
		turret.process()
	TEST_ASSERT_EQUAL(turret.scan_count, 1, "process() calls inside the scan interval must reuse the cache, not re-scan")

	turret.scan_count = 0
	turret.target_scan_cooldown = world.time - 1 // force the cooldown to be finished
	turret.process()
	TEST_ASSERT_EQUAL(turret.scan_count, 1, "process() after the scan cooldown lapses must scan again")

	// C2b: with no clients left on the z-level the turret must not scan at all.
	SSmobs.clients_by_zlevel[turret_turf.z] -= fake_player
	turret.scan_count = 0
	turret.target_scan_cooldown = world.time - 1
	turret.process()
	TEST_ASSERT_EQUAL(turret.scan_count, 0, "process() on a clientless z-level must skip scanning entirely")

/// Counts how many times a status display rebuilds its appearance/overlays.
/obj/machinery/status_display/unit_test_appearance_counter
	var/appearance_updates = 0

/obj/machinery/status_display/unit_test_appearance_counter/update_appearance(updates=ALL)
	appearance_updates++
	return ..()

/// C3: set_timer_messages() — the per-tick shuttle/supply/evac path — pushes to set_messages()
/// (and thus rebuilds the appearance) only when the (current_mode, line1, line2) differs from
/// what it last pushed; repeated identical pushes (the idle evac-display path) are no-ops, a
/// changed line or a mode change forces exactly one rebuild. set_messages() itself stays
/// unconditional, so direct callers (receive_signal, set_picture, …) always rebuild.
/datum/unit_test/status_display_timer_gate/Run()
	var/obj/machinery/status_display/unit_test_appearance_counter/display = allocate(/obj/machinery/status_display/unit_test_appearance_counter)
	display.forceMove(run_loc_floor_bottom_left)
	display.set_machine_stat(0) // clear NOPOWER — the test reservation is unpowered
	display.current_mode = SD_MESSAGE

	display.appearance_updates = 0
	display.set_timer_messages("-CALL-", "5:00")
	TEST_ASSERT_EQUAL(display.appearance_updates, 1, "the first set_timer_messages() push must rebuild the appearance once")
	TEST_ASSERT_EQUAL(display.message1, "-CALL-", "set_timer_messages() must push the lines through set_messages()")

	for(var/i in 1 to 10)
		display.set_timer_messages("-CALL-", "5:00")
	TEST_ASSERT_EQUAL(display.appearance_updates, 1, "set_timer_messages() with an unchanged (mode, line1, line2) must not rebuild the appearance")

	display.set_timer_messages("-CALL-", "4:59")
	TEST_ASSERT_EQUAL(display.appearance_updates, 2, "a changed line must rebuild the appearance exactly once")

	display.current_mode = SD_EMERGENCY
	display.set_timer_messages("-CALL-", "4:59")
	TEST_ASSERT_EQUAL(display.appearance_updates, 3, "a current_mode change must rebuild even if the lines are unchanged (overlays depend on the mode)")

	// The idle path: blank, then "still blank" every fire.
	display.set_timer_messages("", "")
	var/after_blank = display.appearance_updates
	for(var/i in 1 to 10)
		display.set_timer_messages("", "")
	TEST_ASSERT_EQUAL(display.appearance_updates, after_blank, "repeated blank set_timer_messages() (the idle evac-display path) must not rebuild the appearance")

	// set_messages() stays unconditional — this is what keeps the receive_signal()/set_picture()
	// mode-transition rebuilds working independently of the timer-push cache.
	var/before_direct = display.appearance_updates
	display.set_messages("", "") // identical to what set_timer_messages last pushed, but a direct call
	TEST_ASSERT_EQUAL(display.appearance_updates, before_direct + 1, "a direct set_messages() call must always rebuild, even when the content is unchanged")

/// Counts how many times an atmos gas miner rebuilds its icon overlays.
/obj/machinery/atmospherics/miner/unit_test_icon_counter
	var/icon_rebuilds = 0

/obj/machinery/atmospherics/miner/unit_test_icon_counter/update_icon()
	icon_rebuilds++
	return ..()

/// C4 (A3-pattern): set_broken() is called every process_atmos() tick by check_operation()
/// while the miner is in a broken condition — it must only rebuild the icon on an actual
/// broken-state transition, not on every call.
/datum/unit_test/gas_miner_icon_throttle/Run()
	var/obj/machinery/atmospherics/miner/unit_test_icon_counter/miner = allocate(/obj/machinery/atmospherics/miner/unit_test_icon_counter)
	miner.forceMove(run_loc_floor_bottom_left)

	miner.icon_rebuilds = 0
	for(var/i in 1 to 10)
		miner.set_broken(TRUE)
	TEST_ASSERT_EQUAL(miner.icon_rebuilds, 1, "set_broken(TRUE) x10 must rebuild the icon exactly once (the FALSE->TRUE transition), not every call")
	TEST_ASSERT(miner.broken, "the miner must be flagged broken after set_broken(TRUE)")

	miner.set_broken(FALSE)
	TEST_ASSERT_EQUAL(miner.icon_rebuilds, 2, "clearing the broken flag must rebuild the icon exactly once")
	TEST_ASSERT(!miner.broken, "the miner must be un-broken after set_broken(FALSE)")
	for(var/i in 1 to 10)
		miner.set_broken(FALSE)
	TEST_ASSERT_EQUAL(miner.icon_rebuilds, 2, "set_broken(FALSE) on an already-unbroken miner must not rebuild the icon")

	miner.set_broken(TRUE)
	TEST_ASSERT_EQUAL(miner.icon_rebuilds, 3, "re-breaking the miner must rebuild the icon exactly once")

/// C5 (A1-pattern): vent_scrubber/auto_use_power() must charge its area exactly the same
/// amount as the old powered()+use_power() (= two get_area()s) version did, across the
/// scrubbing/siphoning/widenet modes, and return FALSE (charging nothing) when off / welded /
/// not operational / the area's channel is unpowered.
/datum/unit_test/vent_scrubber_auto_use_power/Run()
	var/turf/floor = run_loc_floor_bottom_left
	// Same trick as machinery_auto_use_power: the reservation z lives in /area/space, which
	// overrides powered() to FALSE. Move the floor into a synthetic plain /area for the test.
	var/area/original_area = get_area(floor)
	var/area/test_area = new /area
	allocated += test_area
	test_area.contents.Add(floor) // reassigns floor.loc → test_area

	var/obj/machinery/atmospherics/components/unary/vent_scrubber/scrubber = allocate(/obj/machinery/atmospherics/components/unary/vent_scrubber)
	scrubber.forceMove(floor)
	scrubber.set_machine_stat(0) // clear NOPOWER → is_operational TRUE
	scrubber.power_channel = EQUIP // so we can poke test_area.power_equip / used_equip
	scrubber.on = TRUE
	scrubber.welded = FALSE
	scrubber.filter_types = list()
	scrubber.widenet = FALSE

	// scrubbing-mode values: vent_scrubber.dm #define's SCRUBBING = 1 / SIPHONING = 0 file-local
	// (and #undef's them), so use the literals here.

	// --- idle scrubbing: idle_power_usage ---
	scrubber.scrubbing = 1 // SCRUBBING
	test_area.clear_usage()
	var/before = test_area.used_equip
	var/result = scrubber.auto_use_power()
	TEST_ASSERT(result, "auto_use_power() returns TRUE when on / powered / operational")
	TEST_ASSERT_EQUAL(test_area.used_equip - before, scrubber.idle_power_usage, "idle scrubbing must draw idle_power_usage from the area")

	// --- siphoning: active_power_usage ---
	scrubber.scrubbing = 0 // SIPHONING
	before = test_area.used_equip
	scrubber.auto_use_power()
	TEST_ASSERT_EQUAL(test_area.used_equip - before, scrubber.active_power_usage, "siphoning must draw active_power_usage from the area")

	// --- widenet over 2 turfs: amount += amount * (2 * (2/2)) = amount * 2 → triples ---
	scrubber.scrubbing = 1 // SCRUBBING
	scrubber.widenet = TRUE
	scrubber.adjacent_turfs = list(floor, floor) // only .len matters here
	before = test_area.used_equip
	scrubber.auto_use_power()
	TEST_ASSERT_EQUAL(test_area.used_equip - before, scrubber.idle_power_usage * 3, "widenet scrubbing over 2 adjacent turfs must triple the draw")
	scrubber.widenet = FALSE
	scrubber.adjacent_turfs = list()
	scrubber.scrubbing = 1 // SCRUBBING

	// --- welded / off / not operational / unpowered channel: FALSE, charges nothing ---
	scrubber.welded = TRUE
	before = test_area.used_equip
	result = scrubber.auto_use_power()
	TEST_ASSERT(!result, "a welded scrubber's auto_use_power() returns FALSE")
	TEST_ASSERT_EQUAL(test_area.used_equip - before, 0, "a welded scrubber draws no power")
	scrubber.welded = FALSE

	scrubber.on = FALSE
	before = test_area.used_equip
	result = scrubber.auto_use_power()
	TEST_ASSERT(!result, "an off scrubber's auto_use_power() returns FALSE")
	TEST_ASSERT_EQUAL(test_area.used_equip - before, 0, "an off scrubber draws no power")
	scrubber.on = TRUE

	scrubber.set_machine_stat(NOPOWER) // is_operational → FALSE
	before = test_area.used_equip
	result = scrubber.auto_use_power()
	TEST_ASSERT(!result, "a non-operational scrubber's auto_use_power() returns FALSE")
	TEST_ASSERT_EQUAL(test_area.used_equip - before, 0, "a non-operational scrubber draws no power")
	scrubber.set_machine_stat(0)

	test_area.power_equip = FALSE
	before = test_area.used_equip
	result = scrubber.auto_use_power()
	TEST_ASSERT(!result, "auto_use_power() returns FALSE when the area's channel is unpowered")
	TEST_ASSERT_EQUAL(test_area.used_equip - before, 0, "an unpowered scrubber draws no power")

	original_area.contents.Add(floor) // restore the floor before test_area is qdel'd by teardown
