// Checks that the confusion symptom correctly gives, and removes, confusion
/datum/unit_test/confusion_symptom/Run()
	var/mob/living/carbon/human/H = allocate(/mob/living/carbon/human)
	var/datum/disease/advance/confusion/disease = allocate(/datum/disease/advance/confusion)
	var/datum/symptom/confusion/confusion = disease.symptoms[1]
	disease.processing = TRUE
	disease.update_stage(5)
	disease.infect(H, make_copy = FALSE)
	confusion.Activate(disease)
	TEST_ASSERT(H.get_confusion() > 0, "Human is not confused after getting symptom.")
	disease.cure()
	TEST_ASSERT_EQUAL(H.get_confusion(), 0, "Human is still confused after curing confusion.")

/datum/unit_test/adjust_confused/Run()
	var/mob/living/carbon/human/H = allocate(/mob/living/carbon/human)
	TEST_ASSERT_EQUAL(H.get_confusion(), 0, "Human starts confused.")
	H.AdjustConfused(10 SECONDS, 5, 20)
	TEST_ASSERT_EQUAL(H.get_confusion(), 10, "AdjustConfused did not set expected strength.")
	TEST_ASSERT(H.get_confusion_movement_level() >= 5, "Confusion status effect did not affect movement level.")
	H.AdjustConfused(20 SECONDS, 5, 20)
	TEST_ASSERT_EQUAL(H.get_confusion(), 20, "AdjustConfused did not respect upper bound.")
	H.SetConfused(0)
	TEST_ASSERT_EQUAL(H.get_confusion(), 0, "SetConfused(0) did not clear confusion.")

/datum/disease/advance/confusion/New()
	symptoms += new /datum/symptom/confusion
	Refresh()
