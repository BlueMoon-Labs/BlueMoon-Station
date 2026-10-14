/// Крюк поднимает на пол у края дыры над головой, спускает через дыру рядом и не пускает на занятый пол.
/datum/unit_test/climbing_hook_through_hole

/datum/unit_test/climbing_hook_through_hole/Run()
	var/list/levels = multiz_gravity_test_levels()
	var/turf/below = multiz_gravity_test_turf(40, 40, levels[1], /turf/open/floor/plating)
	multiz_gravity_test_turf(40, 40, levels[2], /turf/open/openspace)
	var/turf/ledge = multiz_gravity_test_turf(41, 40, levels[2], /turf/open/floor/plating)
	var/turf/far_ledge = multiz_gravity_test_turf(43, 40, levels[2], /turf/open/floor/plating)

	var/mob/living/carbon/human/climber = allocate(/mob/living/carbon/human, below)
	var/obj/item/climbing_hook/hook = allocate(/obj/item/climbing_hook, below)
	hook.climb_time = 0
	climber.put_in_active_hand(hook)

	hook.climb(climber, far_ledge)
	TEST_ASSERT_EQUAL(climber.loc, below, "Крюк дотянулся до пола в трёх клетках от дыры")

	var/obj/structure/girder/blocker = allocate(/obj/structure/girder, ledge)
	hook.climb(climber, ledge)
	TEST_ASSERT_EQUAL(climber.loc, below, "Крюк вытащил на пол, занятый плотной структурой")
	qdel(blocker)

	hook.climb(climber, ledge)
	TEST_ASSERT_EQUAL(climber.loc, ledge, "Крюк не поднял на пол у края дыры над головой")

	hook.climb(climber, below)
	TEST_ASSERT_EQUAL(climber.loc, below, "Крюк не спустил через дыру рядом")

/// На картах с крюками он лежит в коробке выживания экипажа, а у заключённого его нет.
/datum/unit_test/survival_box_climbing_hook
	requires_full_map = TRUE

/datum/unit_test/survival_box_climbing_hook/Run()
	if(!SSmapping.config.give_players_hooks)
		return
	var/obj/item/storage/box/survival/crew_box = allocate(/obj/item/storage/box/survival)
	TEST_ASSERT_NOTNULL(locate(/obj/item/climbing_hook/emergency) in crew_box, "В коробке выживания нет аварийного крюка")
	var/obj/item/storage/box/survival/prisoner/prisoner_box = allocate(/obj/item/storage/box/survival/prisoner)
	TEST_ASSERT_NULL(locate(/obj/item/climbing_hook/emergency) in prisoner_box, "Заключённому выдан крюк")
