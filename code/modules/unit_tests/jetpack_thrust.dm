// Regression test: jetpack thrust must actually drain the tank. allow_thrust() used to call
// assume_air_moles() on the jetpack itself, transferring the mixture into itself - a no-op
// that made every jetpack fly forever on a full tank.

#define JETPACK_THRUST_MOLES 0.01
#define JETPACK_MOLE_TOLERANCE 0.0001

/datum/unit_test/jetpack_gas_consumption/Run()
	var/obj/item/tank/jetpack/oxygen/pack = allocate(/obj/item/tank/jetpack/oxygen)
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/turf/open/ground = get_turf(user)
	TEST_ASSERT(istype(ground), "the test human must stand on an open turf")

	var/tank_before = pack.air_contents.total_moles()
	TEST_ASSERT(tank_before > JETPACK_THRUST_MOLES, "a factory oxygen jetpack must spawn with gas in it")
	var/turf_before = ground.return_air().total_moles()

	pack.on = TRUE // bypass turn_on(): ion trail and move signals are irrelevant here
	TEST_ASSERT(pack.allow_thrust(JETPACK_THRUST_MOLES, user), "allow_thrust() must succeed on a full jetpack")

	var/tank_delta = tank_before - pack.air_contents.total_moles()
	TEST_ASSERT(abs(tank_delta - JETPACK_THRUST_MOLES) < JETPACK_MOLE_TOLERANCE,
		"thrust must drain the tank by the thrust amount (drained [tank_delta] instead of [JETPACK_THRUST_MOLES])")

	var/turf_delta = ground.return_air().total_moles() - turf_before
	TEST_ASSERT(abs(turf_delta - JETPACK_THRUST_MOLES) < JETPACK_MOLE_TOLERANCE,
		"the exhaust must end up in the turf under the user (gained [turf_delta] instead of [JETPACK_THRUST_MOLES])")

#undef JETPACK_THRUST_MOLES
#undef JETPACK_MOLE_TOLERANCE
