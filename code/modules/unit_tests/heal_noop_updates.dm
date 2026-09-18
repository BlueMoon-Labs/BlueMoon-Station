/// Лечение целого моба не должно пересчитывать здоровье.
/datum/unit_test/heal_on_undamaged_skips_updatehealth

/datum/unit_test/heal_on_undamaged_skips_updatehealth/Run()
	var/mob/living/carbon/human/cascade_probe/patient = allocate(/mob/living/carbon/human/cascade_probe)
	patient.updatehealth()
	patient.reset_counters()

	patient.adjustBruteLoss(-5)
	patient.adjustFireLoss(-5)
	patient.adjustToxLoss(-5)
	patient.adjustStaminaLoss(-5)

	TEST_ASSERT_EQUAL(patient.health_updates, 0, "лечение без урона пересчитало здоровье")

/// Лечение раненого моба по-прежнему пересчитывает здоровье.
/datum/unit_test/heal_on_damaged_updates_health

/datum/unit_test/heal_on_damaged_updates_health/Run()
	var/mob/living/carbon/human/cascade_probe/patient = allocate(/mob/living/carbon/human/cascade_probe)
	patient.adjustBruteLoss(10)
	patient.adjustToxLoss(10)
	var/health_before = patient.health
	patient.reset_counters()

	patient.adjustBruteLoss(-4)
	patient.adjustToxLoss(-4)

	TEST_ASSERT_EQUAL(patient.health_updates, 2, "лечение урона обязано пересчитать здоровье")
	TEST_ASSERT(patient.health > health_before, "здоровье не выросло после лечения")

/// Тик сна у здорового моба не трогает здоровье, у раненого пересчитывает его ровно раз.
/datum/unit_test/sleeping_tick_batches_healing

/datum/unit_test/sleeping_tick_batches_healing/Run()
	var/mob/living/carbon/human/cascade_probe/sleeper = allocate(/mob/living/carbon/human/cascade_probe)
	sleeper.Sleeping(100)
	var/datum/status_effect/incapacitating/sleeping/sleep_effect = sleeper.IsSleeping()
	TEST_ASSERT_NOTNULL(sleep_effect, "моб не уснул")
	sleeper.dreaming = TRUE
	sleeper.reset_counters()

	sleep_effect.tick()
	TEST_ASSERT_EQUAL(sleeper.health_updates, 0, "сон здорового моба пересчитал здоровье")

	sleeper.adjustBruteLoss(5)
	sleeper.adjustFireLoss(5)
	sleeper.reset_counters()
	var/brute_before = sleeper.getBruteLoss()

	sleep_effect.tick()
	TEST_ASSERT_EQUAL(sleeper.health_updates, 1, "тик сна раненого моба обязан пересчитать здоровье ровно раз")
	TEST_ASSERT(sleeper.getBruteLoss() < brute_before, "сон не лечит")
