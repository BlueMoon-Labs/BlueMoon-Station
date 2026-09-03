// Pins what an air alarm concludes about its turf. The read inside process() runs on every
// SSmachines fire for every alarm on the station, so it is written for speed (direct gas_mixture
// field access, one walk of the gas list) rather than through the one-line accessors — these tests
// are what keep that rewrite honest about the danger levels it reports.

/// Seeds a turf's air with an exact mixture, wiping whatever the map left there.
/datum/unit_test/proc/seed_turf_air(turf/open/location, list/moles_by_gas, temperature)
	var/datum/gas_mixture/air = location.air
	air.clear()
	for(var/gas_id in moles_by_gas)
		air.set_moles(gas_id, moles_by_gas[gas_id])
	air.set_temperature(temperature)
	return air

/// F1: breathable room air reads as safe; the alarm must not raise a danger level for it.
/datum/unit_test/airalarm_reads_safe_air/Run()
	var/turf/open/floor = run_loc_floor_bottom_left
	TEST_ASSERT(istype(floor), "the test floor must be an open turf carrying air")

	var/obj/machinery/airalarm/alarm = allocate(/obj/machinery/airalarm)
	alarm.forceMove(floor)
	alarm.set_machine_stat(0)

	seed_turf_air(floor, list(GAS_O2 = MOLES_O2STANDARD, GAS_N2 = MOLES_N2STANDARD), T20C)
	alarm.danger_level = 2 // start wrong on purpose so a no-op read cannot pass this
	alarm.process()
	TEST_ASSERT_EQUAL(alarm.danger_level, 0, "standard breathable air must read as danger level 0")

/// F2: a plasma-flooded turf must reach the top danger level through the per-gas pass.
/datum/unit_test/airalarm_reads_plasma_flood/Run()
	var/turf/open/floor = run_loc_floor_bottom_left
	var/obj/machinery/airalarm/alarm = allocate(/obj/machinery/airalarm)
	alarm.forceMove(floor)
	alarm.set_machine_stat(0)

	seed_turf_air(floor, list(GAS_O2 = MOLES_O2STANDARD, GAS_N2 = MOLES_N2STANDARD, GAS_PLASMA = 50), T20C)
	alarm.danger_level = 0
	alarm.process()
	TEST_ASSERT_EQUAL(alarm.danger_level, 2, "a plasma flood must read as danger level 2")

/// F3: a hard vacuum is a pressure hazard, and the gas walk over an empty mixture must not runtime.
/datum/unit_test/airalarm_reads_vacuum/Run()
	var/turf/open/floor = run_loc_floor_bottom_left
	var/obj/machinery/airalarm/alarm = allocate(/obj/machinery/airalarm)
	alarm.forceMove(floor)
	alarm.set_machine_stat(0)

	seed_turf_air(floor, list(), TCMB)
	alarm.danger_level = 0
	alarm.process()
	TEST_ASSERT_EQUAL(alarm.danger_level, 2, "vacuum must read as danger level 2 on the pressure check")

/// F4: an overheated room is a temperature hazard even while its gas mix stays breathable.
/datum/unit_test/airalarm_reads_heat/Run()
	var/turf/open/floor = run_loc_floor_bottom_left
	var/obj/machinery/airalarm/alarm = allocate(/obj/machinery/airalarm)
	alarm.forceMove(floor)
	alarm.set_machine_stat(0)

	seed_turf_air(floor, list(GAS_O2 = MOLES_O2STANDARD, GAS_N2 = MOLES_N2STANDARD), T20C + 200)
	alarm.danger_level = 0
	alarm.process()
	TEST_ASSERT_EQUAL(alarm.danger_level, 2, "a 200K overheat must read as danger level 2")
