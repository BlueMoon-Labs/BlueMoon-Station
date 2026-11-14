/datum/unit_test/proc/cryo_reselect_antag(datum/mind/owner)
	var/datum/antagonist/antag = new
	allocated += antag
	antag.owner = owner
	LAZYADD(owner.antag_datums, antag)
	return antag

/datum/unit_test/proc/cryo_reselect_messages(datum/mind/recipient, text)
	. = 0
	for(var/list/entry as anything in GLOB.unit_test_chat_capture)
		if(entry[1] == recipient.current && findtext(entry[2], text))
			.++

/// Крио перевыбирает цель уничтожения: задание остаётся у владельца с новой целью и новым текстом.
/datum/unit_test/cryo_objective_reselect

/datum/unit_test/cryo_objective_reselect/Run()
	var/datum/antag_opt_in_test_world/world_state = allocate(/datum/antag_opt_in_test_world)
	var/datum/mind/owner = antag_opt_in_crew(ANTAG_OPT_IN_ROUND_REMOVE)
	var/datum/mind/departing = antag_opt_in_crew(ANTAG_OPT_IN_ROUND_REMOVE)
	var/datum/mind/candidate = antag_opt_in_crew(ANTAG_OPT_IN_ROUND_REMOVE)
	var/datum/antagonist/antag = cryo_reselect_antag(owner)
	var/datum/objective/assassinate/objective = antag_opt_in_objective(/datum/objective/assassinate, owner)
	objective.target = departing
	objective.update_explanation_text()
	antag.objectives += objective
	world_state.set_crew(list(owner, candidate))

	GLOB.unit_test_chat_capture = list()
	cryo_handle_objectives(departing.current)
	var/updated_messages = cryo_reselect_messages(owner, "Objectives updated!")
	var/removed_messages = cryo_reselect_messages(owner, "Objective removed!")
	GLOB.unit_test_chat_capture = null

	TEST_ASSERT(!QDELETED(objective), "Задание с найденной новой целью не должно удаляться")
	TEST_ASSERT(objective in antag.objectives, "Задание с новой целью осталось у владельца")
	TEST_ASSERT(objective.target == candidate, "Новая цель - оставшийся кандидат")
	TEST_ASSERT(findtext(objective.explanation_text, candidate.name), "Текст задания называет новую цель: [objective.explanation_text]")
	TEST_ASSERT_EQUAL(updated_messages, 1, "Владелец получил одно сообщение об обновлении")
	TEST_ASSERT_EQUAL(removed_messages, 0, "Сообщения об удалении нет")

/// Без кандидата задание снимается и удаляется, обход продолжается к следующим заданиям на ту же цель.
/datum/unit_test/cryo_objective_reselect_none

/datum/unit_test/cryo_objective_reselect_none/Run()
	var/datum/antag_opt_in_test_world/world_state = allocate(/datum/antag_opt_in_test_world)
	var/datum/mind/killer = antag_opt_in_crew(ANTAG_OPT_IN_KILL)
	var/datum/mind/guard = antag_opt_in_crew(ANTAG_OPT_IN_KILL)
	var/datum/mind/departing = antag_opt_in_crew(ANTAG_OPT_IN_ROUND_REMOVE)
	var/datum/antagonist/killer_antag = cryo_reselect_antag(killer)
	var/datum/antagonist/guard_antag = cryo_reselect_antag(guard)
	var/datum/objective/assassinate/assassinate = antag_opt_in_objective(/datum/objective/assassinate, killer)
	assassinate.target = departing
	assassinate.update_explanation_text()
	killer_antag.objectives += assassinate
	var/datum/objective/protect/protect = antag_opt_in_objective(/datum/objective/protect, guard)
	protect.target = departing
	protect.update_explanation_text()
	guard_antag.objectives += protect
	world_state.set_crew(list(killer, guard))

	GLOB.unit_test_chat_capture = list()
	cryo_handle_objectives(departing.current)
	var/updated_messages = cryo_reselect_messages(killer, "Objectives updated!")
	var/removed_messages = cryo_reselect_messages(killer, "Objective removed!")
	GLOB.unit_test_chat_capture = null

	TEST_ASSERT(!(assassinate in killer_antag.objectives), "Задание без новой цели снято с владельца")
	TEST_ASSERT(QDELETED(assassinate), "Задание без новой цели удалено")
	TEST_ASSERT_EQUAL(removed_messages, 1, "Владелец получил одно сообщение о снятии")
	TEST_ASSERT_EQUAL(updated_messages, 0, "Сообщения об обновлении снятого задания нет")
	TEST_ASSERT(!QDELETED(protect), "Следующее задание на ту же цель обработано, а не удалено")
	TEST_ASSERT(protect.target == killer, "Защита перевыбрала цель после снятого задания")

/// Командное задание: с кандидатом остаётся у команды и её членов, без кандидата снимается отовсюду.
/datum/unit_test/cryo_objective_reselect_team

/datum/unit_test/cryo_objective_reselect_team/Run()
	var/datum/antag_opt_in_test_world/world_state = allocate(/datum/antag_opt_in_test_world)
	var/datum/mind/first_member = antag_opt_in_crew(ANTAG_OPT_IN_ROUND_REMOVE)
	var/datum/mind/second_member = antag_opt_in_crew(ANTAG_OPT_IN_ROUND_REMOVE)
	var/datum/mind/departing = antag_opt_in_crew(ANTAG_OPT_IN_ROUND_REMOVE)
	var/datum/mind/candidate = antag_opt_in_crew(ANTAG_OPT_IN_ROUND_REMOVE)
	var/datum/team/team = allocate(/datum/team, list(first_member, second_member))
	var/datum/antagonist/first_antag = cryo_reselect_antag(first_member)
	var/datum/antagonist/second_antag = cryo_reselect_antag(second_member)
	var/datum/objective/assassinate/objective = antag_opt_in_objective(/datum/objective/assassinate, null)
	objective.team = team
	objective.target = departing
	objective.update_explanation_text()
	team.objectives += objective
	first_antag.objectives += objective
	second_antag.objectives += objective
	world_state.set_crew(list(first_member, second_member, candidate))

	GLOB.unit_test_chat_capture = list()
	cryo_handle_objectives(departing.current)
	var/updated_messages = cryo_reselect_messages(second_member, "Objectives updated!")
	GLOB.unit_test_chat_capture = null

	TEST_ASSERT(!QDELETED(objective), "Командное задание с новой целью не удаляется")
	TEST_ASSERT(objective.target == candidate, "Командное задание перевыбрало цель")
	TEST_ASSERT(objective in team.objectives, "Задание осталось у команды")
	TEST_ASSERT((objective in first_antag.objectives) && (objective in second_antag.objectives), "Задание осталось у обоих членов команды")
	TEST_ASSERT_EQUAL(updated_messages, 1, "Член команды получил одно сообщение об обновлении")

	world_state.set_crew(list(first_member, second_member))
	cryo_handle_objectives(candidate.current)

	TEST_ASSERT(QDELETED(objective), "Командное задание без новой цели удалено")
	TEST_ASSERT(!(objective in team.objectives), "Задание снято с команды")
	TEST_ASSERT(!(objective in first_antag.objectives) && !(objective in second_antag.objectives), "Задание снято с членов команды")
