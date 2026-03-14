/proc/create_gas_mixture_for_unit_test(datum/unit_test/test)
	var/datum/gas_mixture/mix = new
	test.allocated += mix
	return mix

/proc/setup_gas_mixture_reuse_test_mix(datum/gas_mixture/mix)
	mix.clear()
	mix.set_moles(GAS_O2, 10)
	mix.set_moles(GAS_N2, 20)
	mix.set_moles(GAS_CO2, 5)
	mix.set_temperature(350)

/proc/setup_breathable_gas_mixture_for_unit_test(datum/gas_mixture/mix)
	mix.clear()
	mix.set_moles(GAS_O2, MOLES_O2STANDARD)
	mix.set_moles(GAS_N2, MOLES_N2STANDARD)
	mix.set_temperature(T20C)

/proc/clear_gas_mixture_for_unit_test(datum/gas_mixture/mix)
	mix.clear()
	mix.set_temperature(T20C)

/datum/unit_test/gas_mixture_remove_into_matches_remove/Run()
	var/datum/gas_mixture/expected_source = create_gas_mixture_for_unit_test(src)
	var/datum/gas_mixture/actual_source = create_gas_mixture_for_unit_test(src)
	var/datum/gas_mixture/expected_removed
	var/datum/gas_mixture/actual_removed = create_gas_mixture_for_unit_test(src)

	setup_gas_mixture_reuse_test_mix(expected_source)
	setup_gas_mixture_reuse_test_mix(actual_source)
	actual_removed.set_moles(GAS_PLASMA, 99)
	actual_removed.set_temperature(900)

	expected_removed = expected_source.remove(17.5)
	TEST_ASSERT_NOTNULL(expected_removed, "remove() unexpectedly returned null during test setup")
	allocated += expected_removed

	TEST_ASSERT(actual_source.remove_into(actual_removed, 17.5), "remove_into() should move gas for a positive amount")
	TEST_ASSERT_EQUAL(actual_removed.compare(expected_removed), 0, "remove_into() produced a different removed mixture")
	TEST_ASSERT_EQUAL(actual_source.compare(expected_source), 0, "remove_into() mutated the source differently than remove()")

/datum/unit_test/gas_mixture_remove_ratio_into_matches_remove_ratio/Run()
	var/datum/gas_mixture/expected_source = create_gas_mixture_for_unit_test(src)
	var/datum/gas_mixture/actual_source = create_gas_mixture_for_unit_test(src)
	var/datum/gas_mixture/expected_removed
	var/datum/gas_mixture/actual_removed = create_gas_mixture_for_unit_test(src)

	setup_gas_mixture_reuse_test_mix(expected_source)
	setup_gas_mixture_reuse_test_mix(actual_source)
	actual_removed.set_moles(GAS_TRITIUM, 42)
	actual_removed.set_temperature(1200)

	expected_removed = expected_source.remove_ratio(0.35)
	TEST_ASSERT_NOTNULL(expected_removed, "remove_ratio() unexpectedly returned null during test setup")
	allocated += expected_removed

	TEST_ASSERT(actual_source.remove_ratio_into(actual_removed, 0.35), "remove_ratio_into() should move gas for a positive ratio")
	TEST_ASSERT_EQUAL(actual_removed.compare(expected_removed), 0, "remove_ratio_into() produced a different removed mixture")
	TEST_ASSERT_EQUAL(actual_source.compare(expected_source), 0, "remove_ratio_into() mutated the source differently than remove_ratio()")

/datum/unit_test/gas_mixture_remove_into_false_clears_buffer/Run()
	var/datum/gas_mixture/source = create_gas_mixture_for_unit_test(src)
	var/datum/gas_mixture/buffer = create_gas_mixture_for_unit_test(src)

	buffer.set_moles(GAS_PLASMA, 5)
	buffer.set_temperature(700)

	TEST_ASSERT(!source.remove_into(buffer, 5), "remove_into() should fail when the source is empty")
	TEST_ASSERT_EQUAL(buffer.total_moles(), 0, "remove_into() left stale gas in the caller-owned buffer")
	TEST_ASSERT_EQUAL(buffer.get_moles(GAS_PLASMA), 0, "remove_into() failed to clear stale gases on failure")

/datum/unit_test/gas_mixture_remove_ratio_into_false_clears_buffer/Run()
	var/datum/gas_mixture/source = create_gas_mixture_for_unit_test(src)
	var/datum/gas_mixture/buffer = create_gas_mixture_for_unit_test(src)

	buffer.set_moles(GAS_BZ, 3)
	buffer.set_temperature(500)

	TEST_ASSERT(!source.remove_ratio_into(buffer, 0.25), "remove_ratio_into() should fail when the source is empty")
	TEST_ASSERT_EQUAL(buffer.total_moles(), 0, "remove_ratio_into() left stale gas in the caller-owned buffer")
	TEST_ASSERT_EQUAL(buffer.get_moles(GAS_BZ), 0, "remove_ratio_into() failed to clear stale gases on failure")

/datum/unit_test/gas_mixture_remove_into_zero_amount_clears_buffer/Run()
	var/datum/gas_mixture/source = create_gas_mixture_for_unit_test(src)
	var/datum/gas_mixture/buffer = create_gas_mixture_for_unit_test(src)

	setup_gas_mixture_reuse_test_mix(source)
	buffer.set_moles(GAS_TRITIUM, 8)
	buffer.set_temperature(650)

	TEST_ASSERT(!source.remove_into(buffer, 0), "remove_into() should fail when asked to remove zero moles")
	TEST_ASSERT_EQUAL(buffer.total_moles(), 0, "remove_into() left stale gas in the caller-owned buffer on a zero-mole request")
	TEST_ASSERT_EQUAL(buffer.get_moles(GAS_TRITIUM), 0, "remove_into() failed to clear stale gases on a zero-mole request")

/datum/unit_test/gas_mixture_remove_ratio_into_zero_ratio_clears_buffer/Run()
	var/datum/gas_mixture/source = create_gas_mixture_for_unit_test(src)
	var/datum/gas_mixture/buffer = create_gas_mixture_for_unit_test(src)

	setup_gas_mixture_reuse_test_mix(source)
	buffer.set_moles(GAS_PLASMA, 6)
	buffer.set_temperature(425)

	TEST_ASSERT(!source.remove_ratio_into(buffer, 0), "remove_ratio_into() should fail when asked to remove a zero ratio")
	TEST_ASSERT_EQUAL(buffer.total_moles(), 0, "remove_ratio_into() left stale gas in the caller-owned buffer on a zero-ratio request")
	TEST_ASSERT_EQUAL(buffer.get_moles(GAS_PLASMA), 0, "remove_ratio_into() failed to clear stale gases on a zero-ratio request")

/datum/unit_test/turf_remove_air_ratio_into_matches_remove_air_ratio/Run()
	var/turf/open/expected_turf = run_loc_floor_bottom_left
	var/turf/open/actual_turf = locate(run_loc_floor_bottom_left.x + 1, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/datum/gas_mixture/expected_removed
	var/datum/gas_mixture/actual_removed = create_gas_mixture_for_unit_test(src)

	TEST_ASSERT(istype(expected_turf), "Expected turf test location was not open turf")
	TEST_ASSERT(istype(actual_turf), "Actual turf test location was not open turf")

	setup_gas_mixture_reuse_test_mix(expected_turf.return_air())
	setup_gas_mixture_reuse_test_mix(actual_turf.return_air())
	actual_removed.set_moles(GAS_TRITIUM, 11)
	actual_removed.set_temperature(800)

	expected_removed = expected_turf.remove_air_ratio(0.2)
	TEST_ASSERT_NOTNULL(expected_removed, "remove_air_ratio() unexpectedly returned null during turf test setup")
	allocated += expected_removed

	TEST_ASSERT(actual_turf.remove_air_ratio_into(actual_removed, 0.2), "remove_air_ratio_into() should remove air from an open turf")
	TEST_ASSERT_EQUAL(actual_removed.compare(expected_removed), 0, "remove_air_ratio_into() produced a different removed mixture than remove_air_ratio() on turf")
	TEST_ASSERT_EQUAL(actual_turf.return_air().compare(expected_turf.return_air()), 0, "remove_air_ratio_into() mutated turf air differently than remove_air_ratio()")

/datum/unit_test/tank_remove_air_into_matches_remove_air/Run()
	var/obj/item/tank/expected_tank = allocate(/obj/item/tank)
	var/obj/item/tank/actual_tank = allocate(/obj/item/tank)
	var/datum/gas_mixture/expected_removed
	var/datum/gas_mixture/actual_removed = create_gas_mixture_for_unit_test(src)

	setup_gas_mixture_reuse_test_mix(expected_tank.return_air())
	setup_gas_mixture_reuse_test_mix(actual_tank.return_air())
	actual_removed.set_moles(GAS_BZ, 4)
	actual_removed.set_temperature(600)

	expected_removed = expected_tank.remove_air(12.5)
	TEST_ASSERT_NOTNULL(expected_removed, "remove_air() unexpectedly returned null during tank test setup")
	allocated += expected_removed

	TEST_ASSERT(actual_tank.remove_air_into(actual_removed, 12.5), "remove_air_into() should remove gas from a tank")
	TEST_ASSERT_EQUAL(actual_removed.compare(expected_removed), 0, "remove_air_into() produced a different removed mixture than remove_air() on tanks")
	var/datum/gas_mixture/actual_tank_air = actual_tank.return_air()
	var/datum/gas_mixture/expected_tank_air = expected_tank.return_air()
	TEST_ASSERT_EQUAL(actual_tank_air.compare(expected_tank_air), 0, "remove_air_into() mutated tank air differently than remove_air()")

/datum/unit_test/tank_remove_air_volume_into_matches_remove_air_volume/Run()
	var/obj/item/tank/expected_tank = allocate(/obj/item/tank)
	var/obj/item/tank/actual_tank = allocate(/obj/item/tank)
	var/datum/gas_mixture/expected_removed
	var/datum/gas_mixture/actual_removed = create_gas_mixture_for_unit_test(src)

	setup_gas_mixture_reuse_test_mix(expected_tank.return_air())
	setup_gas_mixture_reuse_test_mix(actual_tank.return_air())
	actual_removed.set_moles(GAS_NITROUS, 7)
	actual_removed.set_temperature(450)

	expected_removed = expected_tank.remove_air_volume(10)
	TEST_ASSERT_NOTNULL(expected_removed, "remove_air_volume() unexpectedly returned null during tank-volume test setup")
	allocated += expected_removed

	TEST_ASSERT(actual_tank.remove_air_volume_into(actual_removed, 10), "remove_air_volume_into() should remove gas from a tank")
	TEST_ASSERT_EQUAL(actual_removed.compare(expected_removed), 0, "remove_air_volume_into() produced a different removed mixture than remove_air_volume()")
	var/datum/gas_mixture/actual_tank_air = actual_tank.return_air()
	var/datum/gas_mixture/expected_tank_air = expected_tank.return_air()
	TEST_ASSERT_EQUAL(actual_tank_air.compare(expected_tank_air), 0, "remove_air_volume_into() mutated tank air differently than remove_air_volume()")

/datum/unit_test/carbon_breathe_reuses_breath_buffer/Run()
	var/turf/open/test_turf = run_loc_floor_bottom_left
	var/mob/living/carbon/human/test_human = allocate(/mob/living/carbon/human, test_turf)

	TEST_ASSERT(istype(test_turf), "Breathing test location was not open turf")
	setup_breathable_gas_mixture_for_unit_test(test_turf.return_air())

	var/datum/gas_mixture/buffer = test_human.get_breath_buffer()
	buffer.set_moles(GAS_PLASMA, 3)
	buffer.set_temperature(900)

	test_human.breathe()

	TEST_ASSERT_EQUAL(test_human.breath_buffer, buffer, "breathe() replaced the persistent breath buffer instead of reusing it")
	TEST_ASSERT_EQUAL(buffer.total_moles(), 0, "breathe() left gas in the reusable breath buffer after returning it")
	TEST_ASSERT_EQUAL(buffer.get_moles(GAS_PLASMA), 0, "breathe() failed to clear stale gases from the reusable breath buffer")
	TEST_ASSERT_EQUAL(buffer.return_temperature(), TCMB, "breathe() failed to reset the reusable breath buffer temperature after use")

	test_human.breathe()

	TEST_ASSERT_EQUAL(test_human.breath_buffer, buffer, "Repeated breaths did not reuse the same persistent breath buffer")
	TEST_ASSERT_EQUAL(buffer.total_moles(), 0, "Repeated breaths left gas in the reusable breath buffer")

/datum/unit_test/carbon_internal_breath_returns_exhaust_to_environment/Run()
	var/turf/open/test_turf = run_loc_floor_bottom_left
	var/mob/living/carbon/human/test_human = allocate(/mob/living/carbon/human, test_turf)
	var/obj/item/clothing/mask/breath/mask = allocate(/obj/item/clothing/mask/breath, test_human)
	var/obj/item/tank/internals/oxygen/tank = allocate(/obj/item/tank/internals/oxygen, test_human)

	TEST_ASSERT(test_human.equip_to_slot_if_possible(mask, ITEM_SLOT_MASK), "Couldn't equip a breath mask for the internal-air breathing test")
	TEST_ASSERT(test_human.equip_to_slot_if_possible(tank, ITEM_SLOT_BACK), "Couldn't equip an oxygen tank for the internal-air breathing test")
	test_human.internal = tank

	clear_gas_mixture_for_unit_test(test_turf.return_air())
	var/datum/gas_mixture/tank_air = tank.return_air()
	var/initial_tank_o2 = tank_air.get_moles(GAS_O2)

	test_human.breathe()

	TEST_ASSERT(tank_air.get_moles(GAS_O2) < initial_tank_o2, "Internal breathing did not consume gas from the equipped tank")
	TEST_ASSERT(test_turf.return_air().total_moles() > 0, "Internal breathing did not return exhaust to the surrounding environment")
	TEST_ASSERT(test_turf.return_air().get_moles(GAS_CO2) > 0, "Internal breathing did not exhale CO2 into the environment")
	TEST_ASSERT_EQUAL(test_human.breath_buffer.total_moles(), 0, "Internal breathing left gas in the reusable breath buffer")

/datum/unit_test/miner_spawn_buffer_self_heals/Run()
	var/turf/open/test_turf = run_loc_floor_bottom_left
	var/obj/machinery/atmospherics/miner/oxygen/test_miner = allocate(/obj/machinery/atmospherics/miner/oxygen, test_turf)

	clear_gas_mixture_for_unit_test(test_turf.return_air())
	test_miner.spawn_buffer = null

	test_miner.mine_gas()

	TEST_ASSERT_NOTNULL(test_miner.spawn_buffer, "Gas miner failed to lazily recreate its reusable spawn buffer")
	TEST_ASSERT(test_turf.return_air().get_moles(GAS_O2) > 0, "Gas miner failed to emit gas after recreating its reusable spawn buffer")

/datum/unit_test/pet_carrier_remove_air_ratio_into_uses_holder_turf/Run()
	var/turf/open/test_turf = run_loc_floor_bottom_left
	var/mob/living/carbon/human/holder = allocate(/mob/living/carbon/human, test_turf)
	var/obj/item/pet_carrier/carrier = allocate(/obj/item/pet_carrier, holder)
	var/datum/gas_mixture/expected_environment = create_gas_mixture_for_unit_test(src)
	var/datum/gas_mixture/expected_removed
	var/datum/gas_mixture/actual_removed = create_gas_mixture_for_unit_test(src)

	TEST_ASSERT(istype(test_turf), "Pet carrier test location was not open turf")
	setup_gas_mixture_reuse_test_mix(test_turf.return_air())
	expected_environment.copy_from(test_turf.return_air())
	actual_removed.set_moles(GAS_BZ, 2)
	actual_removed.set_temperature(600)

	expected_removed = expected_environment.remove_ratio(0.15)
	TEST_ASSERT_NOTNULL(expected_removed, "Pet carrier test setup failed to create the expected removed mixture")
	allocated += expected_removed

	TEST_ASSERT(carrier.remove_air_ratio_into(actual_removed, 0.15), "Held pet carrier failed to delegate remove_air_ratio_into() to the holder's turf")
	TEST_ASSERT_EQUAL(actual_removed.compare(expected_removed), 0, "Held pet carrier remove_air_ratio_into() produced a different breath sample than the holder turf")
	TEST_ASSERT_EQUAL(test_turf.return_air().compare(expected_environment), 0, "Held pet carrier remove_air_ratio_into() mutated the holder turf atmosphere differently than a direct turf removal")

/datum/unit_test/mecha_gas_thruster_reuses_buffer/Run()
	var/turf/open/test_turf = run_loc_floor_bottom_left
	var/obj/vehicle/sealed/mecha/working/ripley/mkii/test_mecha = allocate(/obj/vehicle/sealed/mecha/working/ripley/mkii, test_turf)
	var/obj/item/mecha_parts/mecha_equipment/thrusters/gas/thruster = allocate(/obj/item/mecha_parts/mecha_equipment/thrusters/gas)

	TEST_ASSERT_NOTNULL(test_mecha.internal_tank, "Enclosed mecha did not create an internal tank")

	thruster.attach(test_mecha)

	var/datum/gas_mixture/tank_air = test_mecha.internal_tank.air_contents
	var/initial_moles = tank_air.total_moles()
	TEST_ASSERT(initial_moles > thruster.move_cost, "Mecha internal tank does not have enough gas to test thruster consumption")

	TEST_ASSERT(thruster.thrust(NORTH), "Gas thruster failed to fire with sufficient tank gas")
	TEST_ASSERT_NOTNULL(thruster.thrust_buffer, "Gas thruster did not lazily create its reusable thrust buffer")

	var/moles_after = tank_air.total_moles()
	var/consumed = initial_moles - moles_after
	TEST_ASSERT(abs(consumed - thruster.move_cost) < 0.01, "Gas thruster consumed [consumed] moles instead of [thruster.move_cost]")
	TEST_ASSERT_EQUAL(thruster.thrust_buffer.total_moles(), 0, "Gas thruster left gas in the reusable thrust buffer after firing")
