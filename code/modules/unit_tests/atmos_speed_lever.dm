// The atmos speed knob was a placebo: ATMOS_SPEED_MULTIPLIER wrote
// share_max_steps, excited_group_pressure_goal and equalize_turf_limit, and
// nothing in the subsystem ever read any of them - so the config, the lag
// throttle and the Atmospheric Flux round event all did nothing at all. This
// atmos has no share-step loop to scale, so the honest lever is the fire
// cadence: these tests pin it.

/datum/unit_test/atmos_speed_lever/Run()
	var/saved_speed = SSair.atmos_speed
	var/saved_lag_scale = SSair.lag_scale
	var/saved_wait = SSair.wait
	var/base_wait = initial(SSair.wait)

	// Задыхающийся CI-раннер честно взводит лаг-клапан ДО теста (реальная
	// дилатация SStime_track), и каденция при speed 1 читается уже придушенной -
	// festive стабильно краснел именно так. Пороги клапана проверяются ниже
	// через apply_lag_valve, здесь его состояние обязано быть нейтральным.
	SSair.lag_scale = 1

	SSair.set_atmos_speed(1)
	TEST_ASSERT_EQUAL(SSair.wait, base_wait, "speed 1 must leave the compiled cadence alone")

	SSair.set_atmos_speed(2)
	TEST_ASSERT_EQUAL(SSair.wait, base_wait / 2, "speed 2 must halve the fire interval")

	// An operator typo may not stop the subsystem: wait 0 would fire it in an
	// endless loop, and a negative wait is worse.
	SSair.set_atmos_speed(100000)
	TEST_ASSERT(SSair.wait >= world.tick_lag, "an absurd multiplier drove the cadence below one tick ([SSair.wait])")

	// The lag valve slows atmos down instead of pretending to throttle a knob
	// nobody reads.
	SSair.set_atmos_speed(1)
	SSair.apply_lag_valve(0)
	TEST_ASSERT_EQUAL(SSair.wait, base_wait, "a calm server must run at the compiled cadence")
	SSair.apply_lag_valve(ATMOS_LAG_VALVE_SEVERE_DILATION + 10)
	TEST_ASSERT(SSair.wait > base_wait, "severe time dilation did not slow the fire cadence ([SSair.wait])")
	var/severe_wait = SSair.wait
	SSair.apply_lag_valve(0)
	TEST_ASSERT_EQUAL(SSair.wait, base_wait, "the cadence did not recover once dilation cleared")

	// Lever and valve compose: a server told to run atmos twice as fast, while
	// lagging hard, lands back on the compiled cadence rather than on either
	// extreme.
	SSair.set_atmos_speed(2)
	SSair.apply_lag_valve(ATMOS_LAG_VALVE_SEVERE_DILATION + 10)
	TEST_ASSERT_EQUAL(SSair.wait, severe_wait / 2, "the lag valve and the speed lever did not compose")
	SSair.apply_lag_valve(0)

	// The round event must hand the operator's setting back, not a hardcoded 1.
	// Built inert (my_processing = FALSE) so the director cannot tick it while
	// the test drives its lifecycle by hand.
	var/datum/round_event/atmos_flux/flux = new(FALSE)
	flux.start()
	TEST_ASSERT_NOTEQUAL(SSair.atmos_speed, 2, "the atmos flux event did not move the speed lever")
	TEST_ASSERT(SSair.wait > 0, "the atmos flux event drove the cadence to zero")
	flux.end()
	TEST_ASSERT_EQUAL(SSair.atmos_speed, 2, "the atmos flux event did not restore the configured speed")
	flux.kill() // drops it from SSdirector.running
	qdel(flux)

	SSair.atmos_speed = saved_speed
	SSair.lag_scale = saved_lag_scale
	SSair.wait = saved_wait
