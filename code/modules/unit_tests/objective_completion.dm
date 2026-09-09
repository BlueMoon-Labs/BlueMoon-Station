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

/datum/unit_test/assassinate_brain_on_centcom/Run()
	var/datum/mind/target_mind = new("unit_test_brain_target")
	var/mob/living/carbon/human/target_body = allocate(/mob/living/carbon/human)
	var/datum/objective/assassinate/objective = new
	target_mind.set_current(target_body)
	target_body.mind = target_mind
	objective.target = target_mind

	target_body.set_stat(DEAD)
	TEST_ASSERT(objective.check_completion(), "Мёртвое тело на станции должно засчитывать цель уничтожения")

	var/obj/item/organ/brain/target_brain = target_body.getorganslot(ORGAN_SLOT_BRAIN)
	TEST_ASSERT(target_brain, "У тестового человека должен быть мозг")
	target_brain.Remove(special = TRUE)
	TEST_ASSERT(isbrain(target_mind.current), "После извлечения цель должна быть brainmob")

	var/turf/centcom_turf
	for(var/turf/open/floor/bluespace/T in world)
		if(is_centcom_level(T.z))
			centcom_turf = T
			break
	if(centcom_turf)
		target_brain.forceMove(centcom_turf)
		TEST_ASSERT(!objective.check_completion(), "Мозг на ЦК не должен засчитывать цель уничтожения")

	qdel(objective)
	qdel(target_mind)

/datum/unit_test/assassinate_no_duplicate_target/Run()
	// Антаг-датум по контракту требует mind с телом: on_gain() крашит на
	// голом mind (antag_datum.dm), а finalize_traitor лезет в owner.current.
	var/datum/mind/traitor_mind = new("unit_test_traitor")
	var/mob/living/carbon/human/traitor_body = allocate(/mob/living/carbon/human)
	traitor_mind.set_current(traitor_body)
	traitor_body.mind = traitor_mind

	var/datum/mind/target_mind = new("unit_test_victim")
	var/mob/living/carbon/human/target_body = allocate(/mob/living/carbon/human)
	target_mind.set_current(target_body)
	target_body.mind = target_mind

	var/datum/antagonist/traitor/antag = new
	antag.silent = TRUE
	antag.give_objectives = FALSE
	antag.should_equip = FALSE
	traitor_mind.add_antag_datum(antag)

	var/datum/objective/assassinate/destroy_objective = new
	destroy_objective.owner = traitor_mind
	destroy_objective.target = target_mind
	antag.objectives += destroy_objective

	var/datum/objective/assassinate/once/kill_objective = new
	kill_objective.owner = traitor_mind
	TEST_ASSERT(!kill_objective.is_unique_objective(target_mind), "Убийство не должно совпадать с уже выданным уничтожением")

	antag.objectives = list(kill_objective)
	kill_objective.target = target_mind
	var/datum/objective/assassinate/another_destroy = new
	another_destroy.owner = traitor_mind
	TEST_ASSERT(!another_destroy.is_unique_objective(target_mind), "Уничтожение не должно совпадать с уже выданным убийством")

	qdel(another_destroy)
	qdel(kill_objective)
	antag.objectives = null
	//owner остаётся на месте: Destroy() антага сам зовёт do_remove_antag_datum,
	//а ручное обнуление владельца било по stack_trace "no owner" и красило CI
	qdel(antag)
	qdel(target_mind)
	qdel(traitor_mind)
