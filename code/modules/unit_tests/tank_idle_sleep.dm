// Regression tests for gas tank idle-sleep on SSobj: a settled tank parks itself off the
// processing list, and every external air mutation path puts it back on.

/// E1: a settled tank's process() returns PROCESS_KILL; remove_air()/assume_air() wake it.
/datum/unit_test/tank_idle_sleep/Run()
	var/obj/item/tank/internals/oxygen/tank = allocate(/obj/item/tank/internals/oxygen)

	// 6 atm of pure oxygen: far below TANK_LEAK_PRESSURE and chemically inert.
	TEST_ASSERT_EQUAL(tank.process(), PROCESS_KILL, "a settled tank's process() must return PROCESS_KILL")
	STOP_PROCESSING(SSobj, tank) // mimic what the subsystem does with that return value
	TEST_ASSERT(!(tank.datum_flags & DF_ISPROCESSING), "the settled tank should be off SSobj")

	// The breathing path drains through remove_air(): must wake the tank.
	tank.remove_air(0.01)
	TEST_ASSERT(tank.datum_flags & DF_ISPROCESSING, "remove_air() must put the tank back on SSobj")
	TEST_ASSERT_EQUAL(tank.process(), PROCESS_KILL, "the drained tank must settle again on its next process()")
	STOP_PROCESSING(SSobj, tank)

	// The fill path merges through assume_air(): must wake the tank.
	var/datum/gas_mixture/puff = new(1)
	puff.set_moles(GAS_N2, 0.1)
	puff.set_temperature(T20C)
	tank.assume_air(puff)
	TEST_ASSERT(tank.datum_flags & DF_ISPROCESSING, "assume_air() must put the tank back on SSobj")

/// E2: a tank docked in a portable stays awake - canister valves, portable pumps and
/// scrubbers write into holding.air_contents directly, bypassing the tank's mutators.
/datum/unit_test/tank_docked_no_sleep/Run()
	var/obj/machinery/portable_atmospherics/canister/canister = allocate(/obj/machinery/portable_atmospherics/canister)
	var/obj/item/tank/internals/oxygen/tank = allocate(/obj/item/tank/internals/oxygen)

	tank.forceMove(canister)
	canister.replace_tank(null, FALSE, tank)
	TEST_ASSERT_EQUAL(canister.holding, tank, "the canister should hold the docked tank (test precondition)")
	TEST_ASSERT(tank.datum_flags & DF_ISPROCESSING, "docking must excite the tank")
	TEST_ASSERT_NOTEQUAL(tank.process(), PROCESS_KILL, "a docked tank must not park itself off SSobj")

	// Undocked and settled: the next process() parks it as usual.
	canister.holding = null
	tank.forceMove(run_loc_floor_bottom_left)
	TEST_ASSERT_EQUAL(tank.process(), PROCESS_KILL, "an undocked settled tank must sleep again")
