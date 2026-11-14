/// Без клиента ключ не создаёт разум, поэтому спавнер для теста создаёт его сам, как Login() в игре.
/obj/effect/mob_spawn/human/ghostcafe/unit_test

/obj/effect/mob_spawn/human/ghostcafe/unit_test/equip(mob/living/carbon/human/visitor, load_character)
	. = ..()
	visitor.mind_initialize()

/// Удалённый разум посетителя кафе уходит из команды спавнера, а пустая команда удаляется вместе со спавнером.
/datum/unit_test/ghost_role_team_releases_mind/Run()
	var/obj/effect/mob_spawn/human/ghostcafe/unit_test/spawner = allocate(/obj/effect/mob_spawn/human/ghostcafe/unit_test, run_loc_floor_top_right)
	var/mob/living/carbon/human/visitor = spawner.create("unit_test_team_visitor")
	TEST_ASSERT_NOTNULL(visitor, "Спавнер кафе создаёт посетителя.")
	allocated += visitor
	var/datum/mind/visitor_mind = visitor.mind
	var/datum/team/ghost_role/team = spawner.ghost_team
	TEST_ASSERT(visitor_mind?.has_antag_datum(/datum/antagonist/ghost_role/ghost_cafe), "Посетитель получает роль кафе.")
	TEST_ASSERT(visitor_mind in team.members, "Посетитель входит в команду спавнера.")
	visitor.key = null
	qdel(visitor_mind)
	TEST_ASSERT(!(visitor_mind in team.members), "Удалённый разум не остаётся в команде спавнера.")
	qdel(spawner)
	TEST_ASSERT(QDELETED(team) && !(team in GLOB.antagonist_teams), "Пустая команда удаляется вместе со спавнером.")
