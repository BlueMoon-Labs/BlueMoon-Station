/// Бин мусоропровода набирает начальный воздух, не отнимая его у своего тайла.
/datum/unit_test/disposal_bin_keeps_turf_air

/datum/unit_test/disposal_bin_keeps_turf_air/Run()
	var/turf/open/bin_turf = run_loc_floor_bottom_left
	var/datum/gas_mixture/turf_air = bin_turf.air
	turf_air.set_moles(GAS_N2, ONE_ATMOSPHERE * turf_air.return_volume() / (R_IDEAL_GAS_EQUATION * T20C))
	turf_air.set_temperature(T20C)
	var/moles_before = turf_air.total_moles()

	var/obj/machinery/disposal/bin/bin = allocate(/obj/machinery/disposal/bin, bin_turf)

	TEST_ASSERT(bin.air_contents.total_moles() > 0, "Бин не набрал воздух")
	TEST_ASSERT_EQUAL(round(bin_turf.air.total_moles(), 0.01), round(moles_before, 0.01), "Бин отнял воздух у своего тайла")
