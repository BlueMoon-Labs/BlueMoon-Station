/obj/machinery/vitals_reader/redraw_probe
	var/redraws = 0

/obj/machinery/vitals_reader/redraw_probe/update_overlays()
	redraws++
	return ..()

/// Монитор перерисовывается только когда меняется то, что он показывает.
/datum/unit_test/vitals_reader_skips_unchanged_redraw

/datum/unit_test/vitals_reader_skips_unchanged_redraw/Run()
	var/obj/machinery/vitals_reader/redraw_probe/reader = allocate(/obj/machinery/vitals_reader/redraw_probe)
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
	reader.set_patient(patient)
	reader.redraws = 0

	patient.updatehealth()
	patient.updatehealth()
	patient.updatehealth()
	TEST_ASSERT_EQUAL(reader.redraws, 0, "монитор перерисовался без изменений у пациента")

	patient.adjustBruteLoss(60)
	TEST_ASSERT(reader.redraws >= 1, "монитор не перерисовался после ранения пациента")

	reader.set_patient(null)
