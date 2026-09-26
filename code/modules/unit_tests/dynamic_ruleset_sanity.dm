/// Verifies that roundstart dynamic rulesets are setup properly without external configuration.
/datum/unit_test/dynamic_roundstart_ruleset_sanity

/datum/unit_test/dynamic_roundstart_ruleset_sanity/Run()
	for (var/_ruleset in subtypesof(/datum/dynamic_ruleset/roundstart))
		var/datum/dynamic_ruleset/roundstart/ruleset = _ruleset

		var/has_scaling_cost = initial(ruleset.scaling_cost)
		var/is_lone = initial(ruleset.flags) & (LONE_RULESET | HIGH_IMPACT_RULESET)

		if (has_scaling_cost && is_lone)
			TEST_FAIL("[ruleset] has a scaling_cost, but is also a lone/highlander ruleset.")
		else if (!has_scaling_cost && !is_lone)
			TEST_FAIL("[ruleset] has no scaling cost, but is also not a lone/highlander ruleset.")

/// Verifies that dynamic rulesets have unique antag_flag.
/datum/unit_test/dynamic_unique_antag_flags

/datum/unit_test/dynamic_unique_antag_flags/Run()
	var/list/known_antag_flags = list()

	for (var/datum/dynamic_ruleset/ruleset as anything in subtypesof(/datum/dynamic_ruleset))
		if (isnull(initial(ruleset.antag_datum)))
			continue

		var/antag_flag = initial(ruleset.antag_flag)

		if (isnull(antag_flag))
			TEST_FAIL("[ruleset] has a null antag_flag!")
			continue

		// Подтип, унаследовавший флаг от родительского правила (клоун-опы от ядерщиков),
		// намеренно берёт кандидатов из того же пула предпочтений и конкурентом ему не является.
		var/datum/dynamic_ruleset/parent_ruleset = type2parent(ruleset)
		if (ispath(parent_ruleset, /datum/dynamic_ruleset) && initial(parent_ruleset.antag_flag) == antag_flag)
			continue

		if (antag_flag in known_antag_flags)
			TEST_FAIL("[ruleset] has a non-unique antag_flag [antag_flag] (used by [known_antag_flags[antag_flag]])!")
			continue

		known_antag_flags[antag_flag] = ruleset

/// Проверяет выдачу нескольких еретиков с учётом кандидатов, бюджета и нормы одного на двадцать игроков.
/datum/unit_test/dynamic_heretics_scaling/Run()
	var/datum/game_mode/dynamic/test_mode = allocate(/datum/game_mode/dynamic)
	var/list/cases = list(list(20, 1, 1), list(20, 8, 1), list(60, 3, 3), list(60, 8, 3))
	for(var/list/test_case as anything in cases)
		test_mode.roundstart_pop_ready = test_case[1]
		var/candidate_count = test_case[2]
		var/datum/dynamic_ruleset/roundstart/heretics/rule = allocate(/datum/dynamic_ruleset/roundstart/heretics)
		rule.mode = test_mode
		for(var/candidate_index in 1 to candidate_count)
			var/mob/living/carbon/human/candidate = allocate(/mob/living/carbon/human)
			candidate.mind_initialize()
			rule.candidates += candidate

		var/expected_count = test_case[3]
		var/scaling_cost = rule.scale_up(test_mode.roundstart_pop_ready, candidate_count)
		TEST_ASSERT_EQUAL(rule.scaled_times, expected_count - 1, "Онлайн [test_case[1]], кандидатов [candidate_count]: масштабирование учитывает кандидатов и норму на онлайн")
		TEST_ASSERT_EQUAL(scaling_cost, (expected_count - 1) * rule.scaling_cost, "Бюджет должен списываться только за доступные дополнительные роли")
		TEST_ASSERT(rule.pre_execute(test_mode.roundstart_pop_ready), "Выдача ролей должна завершиться успешно")
		TEST_ASSERT_EQUAL(length(rule.assigned), expected_count, "Должно выдаваться ожидаемое число еретиков")
		for(var/datum/mind/assigned_mind as anything in rule.assigned)
			TEST_ASSERT_EQUAL(assigned_mind.special_role, ROLE_HERETIC, "Каждый выбранный кандидат должен получить роль еретика")
