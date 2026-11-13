/// Майнер над полным баком и обесточенный майнер уходят в сон, а просыпаются от газа на турфе и от питания и снова добывают.
/datum/unit_test/atmos_miner_sleeps_until_tank_or_power_changes/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/floor = run_loc_floor_bottom_left
	TEST_ASSERT(istype(floor), "test location is not an open turf")
	var/area/original_area = get_area(floor)
	var/area/test_area = new /area
	test_area.contents.Add(floor)
	var/obj/machinery/atmospherics/miner/oxygen/miner = allocate(/obj/machinery/atmospherics/miner/oxygen, floor)
	var/datum/gas_mixture/room = floor.air
	var/normal_oxygen = room.get_moles(GAS_O2)
	var/moles_per_kpa = room.return_volume() / (R_IDEAL_GAS_EQUATION * room.return_temperature())

	room.set_moles(GAS_O2, normal_oxygen + miner.max_ext_kpa * moles_per_kpa)
	for(var/i in 1 to ATMOS_MACHINE_IDLE_STREAK)
		miner.process_atmos()
	TEST_ASSERT(miner.active, "a powered miner is not active")
	TEST_ASSERT(miner.broken, "a miner over a full tank did not report the pressure cap")
	TEST_ASSERT(SSair.idle_machine_queued(miner), "a miner over a full tank did not fall asleep")

	room.set_moles(GAS_O2, normal_oxygen)
	SSair.add_to_active(floor)
	TEST_ASSERT(miner.atmos_processing, "a turf air change did not wake the capped miner")
	miner.process_atmos()
	TEST_ASSERT(room.get_moles(GAS_O2) > normal_oxygen + 1, "the woken miner did not mine")
	TEST_ASSERT(!miner.broken, "the woken miner still reports the pressure cap")

	room.set_moles(GAS_O2, normal_oxygen)
	test_area.power_environ = FALSE
	test_area.power_change()
	for(var/i in 1 to ATMOS_MACHINE_IDLE_STREAK)
		miner.process_atmos()
	TEST_ASSERT(!miner.active, "an unpowered miner stayed active")
	TEST_ASSERT(SSair.idle_machine_queued(miner), "an unpowered miner did not fall asleep")
	test_area.power_environ = TRUE
	test_area.power_change()
	TEST_ASSERT(miner.atmos_processing, "restored power did not wake the miner")
	miner.process_atmos()
	TEST_ASSERT(miner.active, "the repowered miner did not turn back on")
	TEST_ASSERT(room.get_moles(GAS_O2) > normal_oxygen + 1, "the repowered miner did not mine")

	room.set_moles(GAS_O2, normal_oxygen)
	miner.atmos_wake()
	original_area.contents.Add(floor)
