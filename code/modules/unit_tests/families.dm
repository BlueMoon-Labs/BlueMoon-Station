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
