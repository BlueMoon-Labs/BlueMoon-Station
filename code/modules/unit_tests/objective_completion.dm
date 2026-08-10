/// Assassination must remain complete after gibbing deletes the target's body.
/datum/unit_test/assassinate_deleted_target_body/Run()
	var/datum/mind/target_mind = new("unit_test_assassination_target")
	var/mob/living/carbon/human/target_body = allocate(/mob/living/carbon/human)
	var/datum/objective/assassinate/objective = new
	target_mind.set_current(target_body)
	target_body.mind = target_mind
	objective.target = target_mind

	TEST_ASSERT(!objective.check_completion(), "Живая цель ошибочно засчитана уничтоженной")
	target_body.set_stat(DEAD)
	TEST_ASSERT(objective.check_completion(), "Мёртвая цель не засчитана уничтоженной")

	qdel(target_body)
	TEST_ASSERT_NULL(target_mind.current, "Удалённое гибом тело осталось current у mind")
	TEST_ASSERT(objective.check_completion(), "После удаления тела гибом цель перестала считаться уничтоженной")

	qdel(objective)
	qdel(target_mind)
