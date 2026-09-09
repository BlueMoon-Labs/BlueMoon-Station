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

/**
 * Топливо тратится только на изменение скорости.
 *
 * Раньше расход шёл и на каждый `Moved()` (включая шаги самого дрейфа), и по второму разу из
 * `Process_Spacemove` - два-три списания за шаг, и всё это на скорости, которая сама была
 * втрое завышена. Отсюда и жалоба "быстро съела батарейку" из того же баг-репорта.
 */
/datum/unit_test/jetpack_thrust_accounting/Run()
	var/obj/item/tank/jetpack/oxygen/pack = allocate(/obj/item/tank/jetpack/oxygen)
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	pack.on = TRUE // bypass turn_on(): ion trail and move signals are irrelevant here

	// Вопрос "потянем ли" не должен трогать бак: накат по курсу двигателю ничего не стоит,
	// но шагать он всё равно разрешает.
	var/before_check = pack.air_contents.total_moles()
	TEST_ASSERT(pack.allow_thrust(JETPACK_THRUST_MOLES, user, consume = FALSE), "проверка тяги без списания должна отвечать да")
	TEST_ASSERT_EQUAL(pack.air_contents.total_moles(), before_check, "проверка без списания не должна трогать бак")

	// За один тик платим один раз: Process_Spacemove зовут и с ручного пути, и с тика дрейфа.
	TEST_ASSERT(pack.allow_thrust(JETPACK_THRUST_MOLES, user), "первое списание в тике должно пройти")
	var/after_first = pack.air_contents.total_moles()
	TEST_ASSERT(after_first < before_check, "первое списание обязано опустошать бак")
	TEST_ASSERT(pack.allow_thrust(JETPACK_THRUST_MOLES, user), "повторный вызов в том же тике всё равно разрешает тягу")
	TEST_ASSERT_EQUAL(pack.air_contents.total_moles(), after_first, "второе списание в тот же тик должно быть бесплатным")

/// Мёртвый не тянет рычаги: двигатель не работает и топливо не жжёт.
/datum/unit_test/jetpack_dead_user_no_thrust/Run()
	var/obj/item/tank/jetpack/oxygen/pack = allocate(/obj/item/tank/jetpack/oxygen)
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	pack.on = TRUE
	user.death()
	var/before = pack.air_contents.total_moles()
	TEST_ASSERT(!pack.allow_thrust(JETPACK_THRUST_MOLES, user), "труп не должен получать тягу")
	TEST_ASSERT_EQUAL(pack.air_contents.total_moles(), before, "отказ в тяге не должен тратить топливо")

#undef JETPACK_THRUST_MOLES
#undef JETPACK_MOLE_TOLERANCE
