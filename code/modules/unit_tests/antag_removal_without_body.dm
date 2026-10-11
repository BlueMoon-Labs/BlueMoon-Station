/// Снятие антага админом с разума, чьё тело удалено (крио), проходит без рантаймов и удаляет датум.
/datum/unit_test/antag_removal_without_body/Run()
	var/mob/living/carbon/human/admin = allocate(/mob/living/carbon/human)

	var/datum/antagonist/traitor/traitor = new
	traitor.give_objectives = FALSE
	traitor.should_equip = FALSE
	check_bodyless_removal(traitor, admin)

	var/datum/antagonist/changeling/changeling = new
	changeling.give_objectives = FALSE
	check_bodyless_removal(changeling, admin)

/datum/unit_test/antag_removal_without_body/proc/check_bodyless_removal(datum/antagonist/antag, mob/admin)
	antag.silent = TRUE
	var/datum/mind/antag_mind = new("antag_removal_test")
	allocated += antag_mind
	var/mob/living/carbon/human/body = allocate(/mob/living/carbon/human)
	antag_mind.set_current(body)
	body.mind = antag_mind
	antag_mind.add_antag_datum(antag)
	var/antag_type = antag.type

	qdel(body)
	TEST_ASSERT_NULL(antag_mind.current, "[antag_type]: удалённое тело должно отвязаться от разума")

	antag.admin_remove(admin)
	TEST_ASSERT(QDELETED(antag), "[antag_type]: снятие должно дойти до удаления датума")
	TEST_ASSERT(!LAZYLEN(antag_mind.antag_datums), "[antag_type]: датум должен уйти из разума")
