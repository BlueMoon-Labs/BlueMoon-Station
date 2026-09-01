/// Хилиум лечил тем быстрее, чем больше его было в крови (clamp(3 + volume * 1.2, 3, 18)
/// за тик), и не имел передоза - запас реагента напрямую превращался в скорость лечения.
/// Тест закрепляет обе половины нерфа: фиксированную ставку и наличие порога передоза.
/datum/unit_test/healium_nerf

/datum/unit_test/healium_nerf/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)

	var/small_dose_heal = healium_tick_heal(patient, 5)
	var/large_dose_heal = healium_tick_heal(patient, 25)

	TEST_ASSERT(small_dose_heal > 0, "Хилиум не вылечил ничего за тик - сравнивать доза-к-дозе нечего")
	TEST_ASSERT_EQUAL(large_dose_heal, small_dose_heal, "Лечение хилиума за тик всё ещё зависит от объёма реагента")

	patient.reagents.clear_reagents()
	patient.reagents.add_reagent(/datum/reagent/healium, 1)
	var/datum/reagent/healium/dose = patient.reagents.get_reagent(/datum/reagent/healium)
	TEST_ASSERT_NOTNULL(dose, "Хилиум не попал в кровь тестового пациента")
	TEST_ASSERT(dose.overdose_threshold > 0, "У хилиума нет порога передоза - объём в крови снова ничем не наказан")

/// Обнуляет урон и реагенты пациента, вливает dose_volume хилиума и возвращает,
/// сколько суммарного урона снял ровно один тик метаболизма.
/datum/unit_test/healium_nerf/proc/healium_tick_heal(mob/living/carbon/human/patient, dose_volume)
	patient.reagents.clear_reagents()
	patient.heal_overall_damage(1000, 1000, 1000, updating_health = FALSE)
	patient.setToxLoss(0, FALSE)
	patient.take_overall_damage(25, 25, 0, FALSE)
	patient.adjustToxLoss(25, FALSE)
	patient.updatehealth()

	patient.reagents.add_reagent(/datum/reagent/healium, dose_volume)
	var/datum/reagent/healium/dose = patient.reagents.get_reagent(/datum/reagent/healium)
	if(isnull(dose))
		TEST_FAIL("Хилиум не попал в кровь тестового пациента")
		return 0

	var/damage_before = patient.getBruteLoss() + patient.getFireLoss() + patient.getToxLoss()
	dose.on_mob_life(patient)
	return damage_before - (patient.getBruteLoss() + patient.getFireLoss() + patient.getToxLoss())
