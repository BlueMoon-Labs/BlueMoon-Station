/datum/antagonist/gang/unit_test_alpha
	name = "Unit Test Family Alpha"
	gang_name = "Unit Test Family Alpha"
	gang_team_type = /datum/team/gang/unit_test_alpha

/datum/team/gang/unit_test_alpha

/datum/antagonist/gang/unit_test_beta
	name = "Unit Test Family Beta"
	gang_name = "Unit Test Family Beta"
	gang_team_type = /datum/team/gang/unit_test_beta

/datum/team/gang/unit_test_beta

/datum/gang_theme/unit_test_distribution
	involved_gangs = list(
		/datum/antagonist/gang/unit_test_alpha,
		/datum/antagonist/gang/unit_test_beta,
	)
	starting_gangsters = 3

/// Families is allowed to start with three candidates, so those candidates must create
/// both competing families instead of filling the first family with all three players.
/datum/unit_test/families_minimum_two_teams

/datum/unit_test/families_minimum_two_teams/Run()
	var/datum/gang_handler/handler = allocate(/datum/gang_handler, list(), list())
	handler.current_theme = new /datum/gang_theme/unit_test_distribution
	allocated += handler.current_theme
	var/list/gangster_minds = list()

	for(var/index in 1 to 3)
		var/datum/mind/gangster_mind = allocate(/datum/mind, "unit_test_family_[index]")
		var/mob/living/carbon/human/gangster = allocate(/mob/living/carbon/human)
		gangster_mind.current = gangster
		gangster.mind = gangster_mind
		handler.gangbangers += gangster_mind
		gangster_minds += gangster_mind

	handler.post_setup_analogue()
	var/generated_families = length(handler.gangs)
	for(var/datum/mind/gangster_mind as anything in gangster_minds)
		gangster_mind.remove_antag_datum(/datum/antagonist/gang)
		gangster_mind.antag_datums = list()

	TEST_ASSERT_EQUAL(generated_families, 2, "Three eligible starters must populate both families in a two-family theme")

/// Every family member, including recruits, must be able to induct more people.
/datum/unit_test/families_recruits_can_recruit

/datum/unit_test/families_recruits_can_recruit/Run()
	var/datum/gang_handler/handler = allocate(/datum/gang_handler, list(), list())
	handler.current_theme = new /datum/gang_theme/unit_test_distribution
	allocated += handler.current_theme
	var/datum/mind/recruit_mind = allocate(/datum/mind, "unit_test_family_recruit")
	var/mob/living/carbon/human/recruit = allocate(/mob/living/carbon/human)
	recruit_mind.current = recruit
	recruit.mind = recruit_mind
	var/datum/antagonist/gang/recruit_antag = new /datum/antagonist/gang/unit_test_alpha
	recruit_antag.handler = handler
	recruit_mind.add_antag_datum(recruit_antag)
	var/datum/action/cooldown/spawn_induction_package/induction_action = recruit_antag.package_spawner

	TEST_ASSERT(induction_action in recruit.actions, "A recruited family member must receive the induction action")

	recruit_mind.remove_antag_datum(/datum/antagonist/gang)
	TEST_ASSERT(!(induction_action in recruit.actions), "The induction action must be removed with the family antagonist datum")
	TEST_ASSERT(QDELETED(induction_action), "The induction action must be deleted with the family antagonist datum")

/// Families deliberately opt every otherwise eligible player into their role-specific preference.
/datum/unit_test/families_force_antag_preference

/datum/unit_test/families_force_antag_preference/Run()
	var/datum/game_mode/gang/classic_families = new
	var/datum/dynamic_ruleset/roundstart/families/roundstart_families = new
	var/datum/dynamic_ruleset/midround/families/midround_families = new
	allocated += classic_families
	allocated += roundstart_families
	allocated += midround_families

	TEST_ASSERT(classic_families.force_antag_preference, "The Families game mode must force its antagonist preference")
	TEST_ASSERT(roundstart_families.has_required_antag_preference(null), "Roundstart Families must force its antagonist preference")
	TEST_ASSERT(midround_families.has_required_antag_preference(null), "Midround Families must force its antagonist preference")
