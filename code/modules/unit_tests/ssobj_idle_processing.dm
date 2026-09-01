/// Regression + optimization coverage for the SSobj "idle processing" pass.
///
/// A family of objects call START_PROCESSING(SSobj, src) unconditionally in
/// Initialize() and their process() early-returns when there is no work to do,
/// but never returns PROCESS_KILL — so they sit in SSobj.processing for their
/// entire lifetime doing a no-op call every 2s. On a busy round this is hundreds
/// of wasted entries (geiger counters, proximity sensors, self-fueling welders).
///
/// The fix makes each one leave the processing list when idle (process() ->
/// PROCESS_KILL) and re-register when it becomes active again, exactly like the
/// conveyor/air-alarm precedents in machinery_optimization.dm.
///
/// These tests pin BOTH the optimization (idle -> not in SSobj) AND the preserved
/// functionality (active -> still processes and does its real work).

// ===== Geiger counter =====

/// An idle (not scanning) geiger counter must not be resident in SSobj, and its
/// process() must ask the subsystem to drop it.
/datum/unit_test/geiger_idle_leaves_ssobj/Run()
	var/obj/item/geiger_counter/geiger = allocate(/obj/item/geiger_counter)

	TEST_ASSERT(!geiger.scanning, "a fresh geiger counter must start switched off")
	TEST_ASSERT(!(geiger in SSobj.processing), "an idle geiger counter must not be registered in SSobj")
	TEST_ASSERT_EQUAL(geiger.process(), PROCESS_KILL, "an idle geiger's process() must return PROCESS_KILL")

/// Switching the geiger on must (re-)register it, and a scanning geiger must keep
/// accumulating radiation and must NOT return PROCESS_KILL. Switching off again
/// must evict it.
/datum/unit_test/geiger_scanning_processes/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/geiger_counter/geiger = allocate(/obj/item/geiger_counter)

	geiger.attack_self(user) // toggle scanning ON
	TEST_ASSERT(geiger.scanning, "attack_self must switch the geiger on")
	TEST_ASSERT(geiger in SSobj.processing, "a scanning geiger must be registered in SSobj")
	TEST_ASSERT(geiger.datum_flags & DF_ISPROCESSING, "a scanning geiger must carry the DF_ISPROCESSING flag")

	geiger.current_tick_amount = 100
	var/result = geiger.process()
	TEST_ASSERT_NOTEQUAL(result, PROCESS_KILL, "a scanning geiger's process() must not return PROCESS_KILL")
	TEST_ASSERT(geiger.radiation_count > 0, "a scanning geiger must accumulate radiation_count from current_tick_amount")

	geiger.attack_self(user) // toggle scanning OFF
	TEST_ASSERT(!geiger.scanning, "attack_self must switch the geiger back off")
	TEST_ASSERT_EQUAL(geiger.process(), PROCESS_KILL, "after switching off, the geiger's process() must return PROCESS_KILL")

// ===== Proximity sensor =====

/// A proximity sensor that is not in its arming countdown has no per-tick work
/// (movement detection is handled by its proximity_monitor, not process()), so it
/// must not be resident in SSobj and its process() must return PROCESS_KILL.
/datum/unit_test/prox_sensor_idle_leaves_ssobj/Run()
	var/obj/item/assembly/prox_sensor/sensor = allocate(/obj/item/assembly/prox_sensor)

	TEST_ASSERT(!sensor.timing, "a fresh proximity sensor must not be arming")
	TEST_ASSERT(!(sensor in SSobj.processing), "an un-armed proximity sensor must not be registered in SSobj")
	TEST_ASSERT_EQUAL(sensor.process(), PROCESS_KILL, "an un-armed sensor's process() must return PROCESS_KILL")

/// Arming the sensor (activate -> timing) must register it, and while arming its
/// process() must count the timer down and must NOT return PROCESS_KILL.
/datum/unit_test/prox_sensor_arming_processes/Run()
	var/obj/item/assembly/prox_sensor/sensor = allocate(/obj/item/assembly/prox_sensor)
	sensor.time = 10

	var/activated = sensor.activate() // toggles the arming countdown on
	TEST_ASSERT(activated, "activate() must succeed on a fresh secured sensor")
	TEST_ASSERT(sensor.timing, "activate() must start the timing countdown")
	TEST_ASSERT(sensor in SSobj.processing, "an arming sensor must register in SSobj")

	var/time_before = sensor.time
	var/result = sensor.process()
	TEST_ASSERT_NOTEQUAL(result, PROCESS_KILL, "an arming sensor's process() must not return PROCESS_KILL")
	TEST_ASSERT_EQUAL(sensor.time, time_before - 1, "an arming sensor's process() must count its timer down by one")

// ===== Self-fueling welders =====

/// A self-fueling welder spawns full and switched off, so it has no work to do
/// (nothing to burn, nothing to refuel) and must leave SSobj.
/datum/unit_test/welder_selffueling_full_leaves_ssobj/Run()
	var/obj/item/weldingtool/experimental/welder = allocate(/obj/item/weldingtool/experimental)

	TEST_ASSERT(welder.self_fueling, "the experimental welder must be self-fueling")
	TEST_ASSERT(!welder.welding, "a fresh welder must be switched off")
	TEST_ASSERT_EQUAL(welder.get_fuel(), welder.max_fuel, "a fresh welder must spawn with full fuel")
	TEST_ASSERT_EQUAL(welder.process(), PROCESS_KILL, "an off, topped-up self-fueling welder's process() must return PROCESS_KILL")

/// A self-fueling welder that is below max fuel must keep processing so it can
/// refuel itself back to full (the preserved behavior).
/datum/unit_test/welder_selffueling_refuels/Run()
	var/obj/item/weldingtool/experimental/welder = allocate(/obj/item/weldingtool/experimental)
	welder.reagents.remove_reagent(/datum/reagent/fuel, 5) // drop below max
	welder.nextrefueltick = 0 // allow an immediate refuel this tick

	var/fuel_before = welder.get_fuel()
	TEST_ASSERT(fuel_before < welder.max_fuel, "precondition: welder must be below max fuel")

	var/result = welder.process()
	TEST_ASSERT_NOTEQUAL(result, PROCESS_KILL, "a below-max self-fueling welder must keep processing to refuel")
	TEST_ASSERT(welder.get_fuel() > fuel_before, "a self-fueling welder must add fuel while it is processing")

/// The re-arm path: switching a welder on must register it again (so a welder
/// that was evicted while idle resumes processing the moment it is lit).
/datum/unit_test/welder_switch_on_rearms/Run()
	var/obj/item/weldingtool/experimental/welder = allocate(/obj/item/weldingtool/experimental)
	STOP_PROCESSING(SSobj, welder) // simulate the idle-evicted state
	TEST_ASSERT(!(welder in SSobj.processing), "precondition: the evicted welder must start out of SSobj")

	welder.switched_on()
	TEST_ASSERT(welder.welding, "switched_on must light the welder (it has fuel)")
	TEST_ASSERT(welder in SSobj.processing, "a lit welder must be registered in SSobj")

	welder.switched_off() // cleanup: don't leave an open flame burning

// ===== Aggregate population metric =====

/// Real-number metric: a batch of freshly-spawned IDLE geigers, proximity sensors
/// and full self-fueling welders must add ZERO net entries to SSobj.processing
/// once each has had the single process() the subsystem would give it. Before the
/// optimization this batch adds 3 per item (one each), i.e. dozens of permanent
/// no-op residents; after it, none persist.
/datum/unit_test/ssobj_idle_processing_population/Run()
	var/before = length(SSobj.processing)

	var/list/spawned = list()
	for(var/i in 1 to 20)
		spawned += allocate(/obj/item/geiger_counter)
		spawned += allocate(/obj/item/assembly/prox_sensor)
		spawned += allocate(/obj/item/weldingtool/experimental)

	// Mirror what the SSobj fire loop does: any resident whose process() returns
	// PROCESS_KILL gets dropped. None of these are in an active state.
	for(var/datum/thing as anything in spawned)
		if(thing in SSobj.processing)
			if(thing.process() == PROCESS_KILL)
				STOP_PROCESSING(SSobj, thing)

	var/after = length(SSobj.processing)
	TEST_ASSERT_EQUAL(after, before, "60 idle geiger/prox/welder items must net ZERO SSobj entries after one eviction pass (before=[before], after=[after])")

// ===== Timer assembly =====

/// A timer assembly that is not counting down has no per-tick work, so it must
/// not be resident in SSobj and its process() must return PROCESS_KILL.
/datum/unit_test/timer_assembly_idle_leaves_ssobj/Run()
	var/obj/item/assembly/timer/timer = allocate(/obj/item/assembly/timer)

	TEST_ASSERT(!timer.timing, "a fresh timer must not be counting down")
	TEST_ASSERT(!(timer in SSobj.processing), "an idle timer must not be registered in SSobj")
	TEST_ASSERT_EQUAL(timer.process(), PROCESS_KILL, "an idle timer's process() must return PROCESS_KILL")

/// Starting the countdown must register the timer, and while counting down its
/// process() must tick the timer and must NOT return PROCESS_KILL.
/datum/unit_test/timer_assembly_counting_processes/Run()
	var/obj/item/assembly/timer/timer = allocate(/obj/item/assembly/timer)
	timer.time = 10

	var/activated = timer.activate() // toggles timing on
	TEST_ASSERT(activated, "activate() must succeed on a fresh secured timer")
	TEST_ASSERT(timer.timing, "activate() must start the countdown")
	TEST_ASSERT(timer in SSobj.processing, "a counting timer must register in SSobj")

	var/time_before = timer.time
	var/result = timer.process()
	TEST_ASSERT_NOTEQUAL(result, PROCESS_KILL, "a counting timer's process() must not return PROCESS_KILL")
	TEST_ASSERT_EQUAL(timer.time, time_before - 1, "a counting timer's process() must tick its timer down by one")

/// A looping timer must keep processing across a fire: when the countdown hits 0,
/// timer_end() re-arms timing and the timer must reset and stay in SSobj.
/datum/unit_test/timer_assembly_loop_keeps_processing/Run()
	var/obj/item/assembly/timer/timer = allocate(/obj/item/assembly/timer)
	timer.forceMove(run_loc_floor_bottom_left)
	timer.loop = TRUE
	timer.saved_time = 5
	timer.time = 1

	timer.activate() // timing = TRUE, registers
	timer.next_activate = 0 // let timer_end actually fire (bypass the activate cooldown)
	TEST_ASSERT(timer.timing, "activate() must start the countdown")
	TEST_ASSERT(timer in SSobj.processing, "an arming looping timer must register in SSobj")

	// One process() drives time 1 -> 0 -> timer_end(); the loop must re-arm timing.
	var/result = timer.process()
	TEST_ASSERT(timer.timing, "a looping timer must re-arm timing after it fires")
	TEST_ASSERT_NOTEQUAL(result, PROCESS_KILL, "a looping timer must NOT leave SSobj when it loops")
	TEST_ASSERT_EQUAL(timer.time, timer.saved_time, "a looping timer must reset its countdown to saved_time")

	// cleanup so the timer doesn't keep firing during teardown
	timer.timing = FALSE
	STOP_PROCESSING(SSobj, timer)

// ===== InteQ propaganda poster / flag scan throttle =====
//
// Posters and flags legitimately stay in SSobj (they always have potential
// scaring work), but they were running a full view(5) sweep EVERY 2s tick even
// in an empty room. The fix throttles that sweep to once per
// DEMORALISER_SCAN_INTERVAL while preserving the scare itself.

/// Counter subtype: counts how many times the poster runs its view() scare scan.
/obj/structure/sign/poster/contraband/inteq/inteq_recruitment/unit_test_scan_counter
	var/scan_count = 0

/obj/structure/sign/poster/contraband/inteq/inteq_recruitment/unit_test_scan_counter/do_scare_scan()
	scan_count++
	return ..()

/// Counter subtype: counts how many times the flag runs its view() scare scan.
/obj/structure/sign/flag/inteq/unit_test_scan_counter
	var/scan_count = 0

/obj/structure/sign/flag/inteq/unit_test_scan_counter/do_scare_scan()
	scan_count++
	return ..()

/// A poster's process() must run the view() scan at most once per scan interval,
/// not on every 2s tick.
/datum/unit_test/inteq_poster_scan_throttle/Run()
	var/obj/structure/sign/poster/contraband/inteq/inteq_recruitment/unit_test_scan_counter/poster = \
		allocate(/obj/structure/sign/poster/contraband/inteq/inteq_recruitment/unit_test_scan_counter)
	TEST_ASSERT_NOTNULL(poster.demotivator, "poster must have a demotivator after Initialize")

	poster.scan_count = 0
	poster.demotivator.next_scan = 0
	poster.process()
	TEST_ASSERT_EQUAL(poster.scan_count, 1, "the first process() must run one scare scan")

	for(var/i in 1 to 5)
		poster.process()
	TEST_ASSERT_EQUAL(poster.scan_count, 1, "process() within the scan interval must NOT re-run the view() sweep")

	poster.demotivator.next_scan = world.time - 1 // force the interval to have elapsed
	poster.process()
	TEST_ASSERT_EQUAL(poster.scan_count, 2, "process() after the scan interval elapses must scan again")

/// The flag shares the same throttle.
/datum/unit_test/inteq_flag_scan_throttle/Run()
	var/obj/structure/sign/flag/inteq/unit_test_scan_counter/flag = \
		allocate(/obj/structure/sign/flag/inteq/unit_test_scan_counter)
	TEST_ASSERT_NOTNULL(flag.demotivator, "flag must have a demotivator after Initialize")

	flag.scan_count = 0
	flag.demotivator.next_scan = 0
	flag.process()
	TEST_ASSERT_EQUAL(flag.scan_count, 1, "the first process() must run one scare scan")

	for(var/i in 1 to 5)
		flag.process()
	TEST_ASSERT_EQUAL(flag.scan_count, 1, "process() within the scan interval must NOT re-run the view() sweep")

	flag.demotivator.next_scan = world.time - 1
	flag.process()
	TEST_ASSERT_EQUAL(flag.scan_count, 2, "process() after the scan interval elapses must scan again")

/// Preserved behavior (view-independent): the demoraliser still applies the
/// propaganda mood event to a scared human.
/datum/unit_test/demoraliser_pugach_applies_mood/Run()
	var/obj/structure/sign/poster/contraband/inteq/inteq_recruitment/poster = \
		allocate(/obj/structure/sign/poster/contraband/inteq/inteq_recruitment)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	victim.mind_initialize()
	victim.was_scared = 0

	poster.demotivator.pugach(victim)

	var/datum/component/mood/mood = victim.GetComponent(/datum/component/mood)
	TEST_ASSERT_NOTNULL(mood, "victim must have a mood component")
	TEST_ASSERT_NOTNULL(LAZYACCESS(mood.mood_events, "inteq_propagand"), "pugach must apply the InteQ propaganda mood event to a nearby human")
