/datum/objective_item/unit_test_selection
	var/available = TRUE
	var/check_calls = 0

/datum/objective_item/unit_test_selection/ExtraCheck()
	check_calls++
	return available

/// Выбор прекращает дорогие проверки после успеха, сохраняя ограничения владельцев и свободную задачу.
/datum/unit_test/theft_target_selection
	var/list/saved_possible_items

/datum/unit_test/theft_target_selection/Destroy()
	if(!isnull(saved_possible_items))
		GLOB.possible_items = saved_possible_items
		saved_possible_items = null
	return ..()

/datum/unit_test/theft_target_selection/Run()
	var/mob/living/carbon/human/captain = allocate(/mob/living/carbon/human)
	captain.mind_initialize()
	captain.mind.assigned_role = "Captain"
	var/datum/objective/steal/objective = allocate(/datum/objective/steal)
	objective.owner = captain.mind
	saved_possible_items = GLOB.possible_items
	GLOB.possible_items = list()
	for(var/candidate_index in 1 to 4)
		GLOB.possible_items += allocate(/datum/objective_item/unit_test_selection)
	var/list/original_candidates = GLOB.possible_items.Copy()
	objective.find_target()
	TEST_ASSERT(objective.targetinfo in original_candidates, "Нужно выбрать доступную цель")
	var/total_checks = 0
	for(var/datum/objective_item/unit_test_selection/candidate as anything in original_candidates)
		total_checks += candidate.check_calls
	TEST_ASSERT_EQUAL(total_checks, 1, "После первого успеха остальные дорогие проверки не нужны")
	TEST_ASSERT_EQUAL(length(GLOB.possible_items), length(original_candidates), "Выбор не должен удалять общие варианты")
	for(var/candidate_index in 1 to length(original_candidates))
		TEST_ASSERT_EQUAL(GLOB.possible_items[candidate_index], original_candidates[candidate_index], "Выбор не должен переставлять общий список")

	for(var/datum/objective_item/unit_test_selection/candidate as anything in original_candidates)
		candidate.available = FALSE
		candidate.check_calls = 0
	objective = allocate(/datum/objective/steal)
	objective.owner = captain.mind
	TEST_ASSERT_NULL(objective.find_target(), "Без доступных предметов нужна свободная задача")
	TEST_ASSERT_NULL(objective.targetinfo, "Недоступная цель не должна назначаться")
	TEST_ASSERT_EQUAL(objective.explanation_text, "Свободная Задача", "Нужно сохранить описание свободной задачи")
	for(var/datum/objective_item/unit_test_selection/candidate as anything in original_candidates)
		TEST_ASSERT_EQUAL(candidate.check_calls, 1, "При неудаче каждый вариант нужно проверить ровно один раз")
		candidate.check_calls = 0

	var/datum/objective_item/unit_test_selection/available_candidate = original_candidates[4]
	available_candidate.available = TRUE
	objective = allocate(/datum/objective/steal)
	objective.owner = captain.mind
	objective.find_target()
	TEST_ASSERT_EQUAL(objective.targetinfo, available_candidate, "Единственный доступный вариант должен быть найден")
	TEST_ASSERT_EQUAL(available_candidate.check_calls, 1, "Выбранный вариант нужно проверить ровно один раз")
	for(var/datum/objective_item/unit_test_selection/candidate as anything in original_candidates)
		TEST_ASSERT(candidate.check_calls <= 1, "Недоступные варианты нельзя проверять повторно")
		candidate.available = TRUE
		candidate.check_calls = 0

	var/mob/living/carbon/human/engineer = allocate(/mob/living/carbon/human)
	engineer.mind_initialize()
	engineer.mind.assigned_role = "Station Engineer"
	var/datum/team/team = allocate(/datum/team, list(engineer.mind))
	var/datum/antagonist/antagonist = allocate(/datum/antagonist)
	antagonist.owner = engineer.mind
	engineer.mind.antag_datums = list(antagonist)
	var/datum/objective/steal/duplicate = allocate(/datum/objective/steal)
	duplicate.owner = engineer.mind
	duplicate.steal_target = /obj/item/bikehorn
	antagonist.objectives += duplicate
	var/datum/objective_item/unit_test_selection/duplicate_candidate = original_candidates[1]
	duplicate_candidate.targetitem = /obj/item/bikehorn
	var/datum/objective_item/unit_test_selection/captain_candidate = original_candidates[2]
	captain_candidate.targetitem = /obj/item/wrench
	captain_candidate.excludefromjob = list("Captain")
	var/datum/objective_item/unit_test_selection/engineer_candidate = original_candidates[3]
	engineer_candidate.targetitem = /obj/item/crowbar
	engineer_candidate.excludefromjob = list("Station Engineer")
	available_candidate.targetitem = /obj/item/screwdriver
	objective = allocate(/datum/objective/steal)
	objective.owner = captain.mind
	objective.team = team
	TEST_ASSERT_EQUAL(objective.find_target(), available_candidate.targetitem, "Нужно учесть профессии владельца и команды, а также уже выданные цели команды")
	TEST_ASSERT_EQUAL(duplicate_candidate.check_calls, 0, "Дубликат нужно отсеять до дорогой проверки")
	TEST_ASSERT_EQUAL(captain_candidate.check_calls, 0, "Запрет профессии владельца нужно проверить до ExtraCheck")
	TEST_ASSERT_EQUAL(engineer_candidate.check_calls, 0, "Запрет профессии участника команды нужно проверить до ExtraCheck")
	TEST_ASSERT_EQUAL(available_candidate.check_calls, 1, "Допустимому варианту нужна проверка наличия")

	objective = allocate(/datum/objective/steal)
	objective.owner = captain.mind
	GLOB.possible_items.Cut()
	TEST_ASSERT_NULL(objective.find_target(), "Пустой список должен давать свободную задачу")
	TEST_ASSERT_EQUAL(objective.explanation_text, "Свободная Задача", "Пустой список не должен оставлять исходное описание")
